//native files
#using scripts\shared\array_shared;
#using scripts\shared\hud_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\math_shared;
#using scripts\shared\util_shared;
#using scripts\shared\weapons_shared;

#using scripts\mp\_util;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\abilities\_ability_util.gsh;

//custom files
#using scripts\shared\mod_util;

#using scripts\mp\gametypes\quarantine_chaos;
#using scripts\mp\gametypes\quarantine_chaos_loadout;
#using scripts\mp\gametypes\quarantine_chaos_shop;
#using scripts\mp\gametypes\quarantine_chaos_shop_hud;

#namespace shop;

/* -------------------------------------------------------------------------------------

	Section:		Shop Item Functions
	Description:	The magic that makes the shop work

------------------------------------------------------------------------------------- */

function PurchaseWeapon( team, cost, element, state, weapon )
{
	if( !util::isValidWeapon( weapon ) )
	{
		return;
	}

	weapon_name_localized = util::GetLocalizedWeaponName( weapon );

	if( self HasWeapon( weapon ) )
	{
		self IPrintLn( Highlight( weapon_name_localized ) + " already purchased");

		return;
	}

	//build the struct so it can be properly added to the starting loadout 
	weapon_struct = SpawnStruct();
	weapon_struct.name = weapon_name_localized;
	weapon_struct.reference = weapon.name;
	weapon_struct.type = util::getWeaponClass( weapon );
	weapon_struct.weapon = weapon;

	self GiveWeapon( weapon );

	if( weapons::is_primary_weapon( weapon ) || weapons::is_side_arm( weapon ) )
	{
		//can't swap the weapons because it's being added on
		self GiveMaxAmmo( weapon );
		self SwitchToWeapon( weapon );
		self SetSpawnWeapon( weapon );

		loadout::AddLoadoutItem( team, "guns", weapon_struct );
	}
	else if( weapons::is_grenade( weapon ) || weapons::is_inventory( weapon ) )
	{
		//give the alpha zombie 2, everyone else gets one
		weapon_struct.clip_size = ( self.is_alpha_zombie ? 2 : 1 );
		self SetWeaponAmmoClip( weapon, weapon_struct.clip_size );

		loadout::AddLoadoutItem( team, "equipment", weapon_struct );
	}
	else if( weapon.isheroweapon || weapon.gadget_type == GADGET_TYPE_HERO_WEAPON )
	{
		self GadgetPowerChange( 0, 100 );

		loadout::AddLoadoutItem( team, "gadget", weapon_struct );
	}
	else
	{
		return;
	}

	//update the hsop
	element.bought = true;
	element.available = false;
	[[ self.shop_system[ team ] ]]->SetOption( element.parent, element.index_parent, element.index_option, element );

	[[ self.shop_system[ team ] ]]->Callback( "shop_weapon_purchased" );

	RefreshShop_Safe_Single( team, element, state );

	PurchaseSuccess( Highlight( weapon_name_localized ) + " purchased", cost );
}

function PurchasePerk( team, cost, element, state, perks )
{
	foreach( perk in perks.references )
	{
		self SetPerk( perk );
	}

	//update the option so it cannot be bought again
	element.bought = true;
	[[ self.shop_system[ team ] ]]->SetOption( element.parent, element.index_parent, element.index_option, element );

	RefreshShop_Safe_Single( team, element, state );

	PurchaseSuccess( Highlight( perk.name ) + " purchased", cost );
}

function PurchaseMaxHealth( team, cost, element, state, increment )
{
	if( !util::isValidInt( increment ) || increment < 0 )
	{
		return;
	}

	max_health = quarantine_chaos::GetMaxHealth();
	max_health_limit = quarantine_chaos::GetMaxHealthLimit( team );

	if( max_health >= max_health_limit )
	{
		alias = quarantine_chaos::GetTeamAlias( team );

		PurchaseFail( "Maximum health for " + Highlight( alias ) + " is " + Highlight( max_health_limit ) );

		return;
	}

	//in case the increment puts the max health over the limit
	increase = Int( Min( increment, max_health_limit - self.maxhealth ) );

	max_health += increase;
	quarantine_chaos::SetMaxHealth( max_health );

	self.maxhealth = max_health;
	self.health = max_health;

	PurchaseSuccess( "Max health increased to " + Highlight( max_health ), cost );

	if( max_health >= max_health_limit )
	{
		element.available = false;
		[[ self.shop_system[ team ] ]]->SetOption( element.parent, element.index_parent, element.index_option, element );

		RefreshShop_Safe_Single( team, element, state );
	}
}

function PurchaseGadgetPower( team, cost, element, state )
{
	//player doesn't have a gadget or hero weapon
	if( !self util::HasHeroWeapon() )
	{
		self IPrintLn( "No " + Highlight( "hero weapon" ) + " to give power to" );

		return;
	}

	weapon_hero = util::GetHeroWeapon();
	weapon_hero_name_localized = util::GetLocalizedWeaponName( weapon_hero );

	slot = 0;

	//gadget already has max power
	if( self GadgetPowerGet( slot ) == 100 )
	{
		self IPrintLn( Highlight( weapon_hero_name_localized ) + " already has maximum power" ) ;

		return;
	}

	self GadgetPowerChange( slot, 100 );

	PurchaseSuccess( Highlight( weapon_hero_name_localized ) + " power purchased", cost );

	//option handling handled entirely by the call back in this case
	[[ self.shop_system[ team ] ]]->Callback( "shop_power_purchased" );
}

function PurchaseUpgrade( team, cost, element, state, type_starter, type_upgrade )
{
	_type_upgrade = loadout::GetUpgradeType( team, type_starter );

	if( !util::CompareStrings( _type_upgrade, type_upgrade ) )
	{
		return;
	}

	weapon_current = self GetCurrentWeapon();
	weapon_current_name_localized = util::GetLocalizedWeaponName( weapon_current );

	//make sure the current weapon matches the starter type
	if( !util::CompareStrings( util::getWeaponClass( weapon_current ), type_starter ) )
	{
		return;
	}

	available_upgrades = loadout::GetAvailableWeapons( team )[ "upgrade" ][ type_upgrade ];

	//check to see there are any upgrades available
	if( !util::isValidArray( available_upgrades ) || util::GetArraySize( available_upgrades ) == 0 )
	{
		return;
	}

	weapon_upgrade_struct = array::random( available_upgrades );

	//add the attachments for the gun to the menu so they can be bought
	parent = "attach";
	foreach( attachment in weapon_upgrade_struct.attachments )
	{
		display_purchase = "Purchase " + attachment.name;
		display_bought = attachment.name + " already purchased";
		display_unavailable = attachment.name + " unavailable";
		display_swap = "Swap current optic for " +  attachment.name;

		[[ self.shop_system[ team ] ]]->AddOption_GunDependent( parent, weapon_upgrade_struct.weapon, &PurchaseAttachment, 500, weapon_upgrade_struct.reference, attachment );	
		[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, display_purchase, display_bought, display_unavailable, display_swap );
		[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_weapon_change_complete", &ShopCallback_AttachmentUpgrade, self );		
	}

	self util::SwapWeaponsHeld( weapon_current, weapon_upgrade_struct.weapon, true );
	self loadout::SwapLoadoutWeapon( weapon_current, weapon_upgrade_struct );

	//update the option now so another weapon cannot be bought when switching weapons
	element.bought = true;
	[[ self.shop_system[ team ] ]]->SetOption( element.parent, element.index_parent, element.index_option, element );

	PurchaseSuccess( Highlight( weapon_current_name_localized ) + " upgraded to " + Highlight( weapon_upgrade_struct.name ), cost );

	RefreshShop_Safe_Single( team, element, state );
}

function PurchaseAttachment( team, cost, element, state, reference, attachment )
{
	weapon_current = self GetCurrentWeapon();
	weapon_current_base = util::GetBaseWeapon( weapon_current );
	weapon_current_base_name_localized = util::GetLocalizedWeaponName( weapon_current_base );

	//player was not holding the right weapon base weapon
	if( !util::CompareStrings( weapon_current_base.name, reference ) )
	{
		return;
	}

	attachments = weapon_current.attachments;

	//used for checks and option updating
	optic_current_reference = self util::GetOpticOnWeapon( weapon_current );
	optic_purchased_reference = ( util::CompareStrings( attachment.group, "optic" ) ? attachment.reference : optic_current_reference );
	optic_swapped_name = "";

	attachments_held = util::GetArraySize( attachments );
	max_attachments_allowed = quarantine_chaos::GetMaxAttachmentsAllowed();

	//if the attachment is an optic and ther gun already has an optic, swap it out 
	if( util::CompareStrings( attachment.group, "optic", true ) && util::isValidString( optic_current_reference ) )
	{		
		optic_swapped_name = util::GetLocalizedAttachmentName( optic_current_reference );

		ArrayRemoveValue( attachments, optic_current_reference );		
	}
	//no optic is present, the gun already has the max allowed attachments
	else if( attachments_held >= max_attachments_allowed )
	{
		PurchaseFail( "Maximum attachments for " + Highlight( weapon_current_base_name_localized ) + " already purchased" );

		return;
	}	

	ARRAY_ADD( attachments, attachment.reference );

	weapon_give = GetWeapon( weapon_current_base.name, attachments );

	self util::SwapWeaponsHeld( weapon_current, weapon_give, true );
	self loadout::EditLoadoutWeapon( weapon_give );	

	element.bought = true;	
	element.available = false;

	if( util::CompareStrings( attachment.group, "optic" ) )
	{
		element.swappable = true;
	}

	//upate the option now so the attachment isn't double purchase by accident
	[[ self.shop_system[ team ] ]]->SetOption( element.parent, element.index_parent, element.index_option, element );

	if( util::isValidString( optic_swapped_name ) )
	{
		PurchaseSuccess( Highlight( optic_swapped_name ) + " swapped for " + Highlight( attachment.name ) );
	}
	
	//get the new array size in case an optic wasn't swapped
	attachments_held = util::GetArraySize( attachments );
	PurchaseSuccess( "(" + attachments_held + "/" + max_attachments_allowed + ") " + Highlight( attachment.name ) + " purchased for " + Highlight( weapon_current_base_name_localized ), cost );

	RefreshShop_Safe_Single( team, element, state );
}

function PurchaseMaxAmmo( team, cost, element, state, weapon = undefined, all_weapons = false )
{
	if( !util::isValidWeapon( weapon ) )
	{
		weapon = self GetCurrentWeapon();
	}

	if( !util::isValidWeapon( weapon ) )
	{
		return;
	}

	weapon_name_localized = util::GetLocalizedWeaponName( weapon );

	if( util::HasMaxAmmo( weapon ) )
	{
		PurchaseFail( Highlight( weapon_name_localized ) + " already has max ammo" );

		return;
	}

	//also set the clip in case the gun was completely empty 
	self GiveMaxAmmo( weapon );
	self SetWeaponAmmoClip( weapon, weapon.clipSize );

	PurchaseSuccess( "Ammo for " + Highlight( weapon_name_localized ) + " purchased", cost );

	//dont' spam the callbac if it's for all weapons
	if( !all_weapons )
	{
		[[ self.shop_system[ team ] ]]->Callback( "shop_ammo_purchased" );
	}
}

function PurchaseMaxAmmo_AllWeapons( team, cost, element, state )
{
	weapons = self GetWeaponsListPrimaries();

	if( util::GetArraySize( weapons ) < 1 )
	{
		PurchaseFail( "There are no " + Highlight( "primary weapons" ) +" to give ammo to" );
	}

	ammo_given = false;

	foreach( weapon in weapons )
	{
		if( !util::HasMaxAmmo( weapon ) )
		{
			PurchaseMaxAmmo( team, undefined, element, state, weapon, true );

			ammo_given = true;
		}
	}

	if( ammo_given )
	{
		PurchaseSuccess( "Ammo for all " + Highlight( "primary weapons" ) + " purchased", cost );

		[[ self.shop_system[ team ] ]]->Callback( "shop_ammo_purchased" );
	}
	else
	{
		PurchaseFail( "All " + Highlight( "primary weapons" ) + " already have max ammo" );
	}
}

/* -------------------------------------------------------------------------------------

	Section:		Purchase Prints
	Description:	Prints success/failure text and also adjusts self.cash.spent

------------------------------------------------------------------------------------- */

function PurchaseSuccess( str, cost = undefined )
{
	if( util::isValidInt( cost ) )
	{
		self.cash.spent += cost;
		self RefreshCash();
	}

	if( util::isValidString( str ) )
	{
		if( util::isValidInt( cost ) )
		{
			self IPrintLn( str + " ^7for ^2$^7" + cost );			
		}
		else
		{
			self IPrintLn( str );	
		}
	}
}

function PurchaseFail( str )
{
	if( util::isValidString( str ) )
	{
		self IPrintLn(  str );
	}
}

function Highlight( str )
{
	return "^5" + str + "^7";
}