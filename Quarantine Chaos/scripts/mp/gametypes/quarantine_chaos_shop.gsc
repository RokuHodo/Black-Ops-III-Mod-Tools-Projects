//native files
#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\hud_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\math_shared;
#using scripts\shared\util_shared;

#using scripts\mp\_util;

#insert scripts\shared\shared.gsh;

//custom files
#using scripts\shared\mod_util;

#using scripts\mp\gametypes\quarantine_chaos;
#using scripts\mp\gametypes\quarantine_chaos_loadout;
#using scripts\mp\gametypes\quarantine_chaos_shop_hud;
#using scripts\mp\gametypes\quarantine_chaos_shop_items;

#namespace shop;

/* -------------------------------------------------------------------------------------

	Section:		Building Shops
	Description:	Build the shop using the Shop() class for humans and zombies

------------------------------------------------------------------------------------- */

function BuildShops()
{
	self.shop_system = [];

	// ============================
	//			Zombie Shop			
	// ============================

	team = "axis";
	self.shop_system[ team ] = new Shop();
	[[ self.shop_system[ team ] ]]->SetShopOwner( team );

	//WEAPONS MENU
	parent = "weapons";
	[[ self.shop_system[ team ] ]]->AddParent( parent );

	//combat axe
	weapon = GetWeapon( "hatchet" );
	weapon_name_localized = util::GetLocalizedWeaponName( weapon );

	display_purchase = "Purchase " + weapon_name_localized;
	display_bought = weapon_name_localized + " already purchased";
	[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchaseWeapon, 750, weapon );
	[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, display_purchase, display_bought );

	//ripper
	weapon = GetWeapon( "hero_armblade" );
	weapon_name_localized = util::GetLocalizedWeaponName( weapon );

	display_purchase = "Purchase " + weapon_name_localized;
	display_bought = weapon_name_localized + " already purchased";
	[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchaseWeapon, 750, weapon );
	[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, display_purchase, display_bought );

	//PERK MENU
	parent = "perks";
	[[ self.shop_system[ team ] ]]->AddParent( parent );

	perks = loadout::GetAvailablePerks( team );
	foreach( perk in perks )
	{
		display_purchase = "Purchase " + perk.name;
		display_bought = perk.name + " already purchased";

		[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchasePerk, 250, perk );
		[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, display_purchase, display_bought );
	}

	//MISC MENU
	parent = "misc";
	[[ self.shop_system[ team ] ]]->AddParent( parent );

	[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchaseMaxHealth, 600, 25 );
	[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, "Increase max health", undefined, "Max health limit reached" );

	[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchaseGadgetPower, 500 );
	[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, "Purchase gadget power", "Gadget already has max power", "No gadget held" );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_weapon_purchased", &ShopCallback_PowerPurchased, self );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_power_purchased", &ShopCallback_PowerPurchased, self );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_gadget_activated", &ShopCallback_PowerPurchased, self );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_gadget_deactivated", &ShopCallback_PowerPurchased, self );

	// ============================ 
	//			Human Shop			
	// ============================

	team = "allies";
	self.shop_system[ team ] = new Shop();
	[[ self.shop_system[ team ] ]]->SetShopOwner( team );

	//WEAPON UPGRADE MENU
	if( quarantine_chaos::WeaponUpgradesAllowed() )
	{
		parent = "guns";
		[[ self.shop_system[ team ] ]]->AddParent( parent, true, true );

		//default option
		[[ self.shop_system[ team ] ]]->AddOption( parent, &util::blank, 0, undefined, undefined, undefined, true );
		[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, "Current weapon cannot be exchanged" );

		foreach( weapon_struct in loadout::GetStartingLoadout( team )[ "guns" ] )
		{
			type_starter = weapon_struct.type;
			type_upgrade = loadout::GetUpgradeType( team, type_starter );
			type_upgrade_name = util::GetWeaponClassName( type_upgrade );

			preposition = ( util::StartsWithVowel( type_upgrade_name ) ? "an" : "a" );

			display_purchase = "Exchange your weapon for " + preposition + " " + type_upgrade_name;
			display_bought = "Current weapon cannot be exchanged";
			display_unavailable = "Current weapon cannot be exchanged";

			[[ self.shop_system[ team ] ]]->AddOption_GunDependent( parent, weapon_struct.weapon, &PurchaseUpgrade, 750, type_starter, type_upgrade );
			[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, display_purchase, display_bought, display_unavailable );
		}
	}
	
	//WEAPON ATTACHMENT MENU
	if( quarantine_chaos::AttachmentUpgradesAllowed() )
	{
		parent = "attach";
		[[ self.shop_system[ team ] ]]->AddParent( parent, true, false );

		//default option
		[[ self.shop_system[ team ] ]]->AddOption( parent, &util::blank, 0, undefined, undefined, undefined, true );
		[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, "No attachment upgrades available" );

		foreach( weapon_struct in loadout::GetStartingLoadout( team )[ "guns" ] )
		{
			foreach( attachment in weapon_struct.attachments )
			{
				display_purchase = "Purchase " + attachment.name;
				display_bought = attachment.name + " already purchased";
				display_unavailable = attachment.name + " unavailable";
				display_swap = "Swap current optic for " +  attachment.name;

				[[ self.shop_system[ team ] ]]->AddOption_GunDependent( parent, weapon_struct.weapon, &PurchaseAttachment, 500, weapon_struct.reference, attachment );
				[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, display_purchase, display_bought, display_unavailable, display_swap );
				[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_weapon_change_complete", &ShopCallback_AttachmentUpgrade, self );
			}
		}
	}

	//PERK MENU
	parent = "perks";
	[[ self.shop_system[ team ] ]]->AddParent( parent );

	perks = loadout::GetAvailablePerks( team );
	foreach( perk in perks )
	{
		display_purchase = "Purchase " + perk.name;
		display_bought = perk.name + " already purchased";

		[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchasePerk, 250, perk );
		[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, display_purchase, display_bought );
	}

	//MISC MENU
	parent = "misc";
	[[ self.shop_system[ team ] ]]->AddParent( parent );

	[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchaseMaxAmmo, 750 );
	[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, "Purchase max ammo for current weapon", undefined, "Current weapon already has max ammmo" );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_ammo_purchased", &ShopCallback_MaxAmmo, self );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_weapon_fired", &ShopCallback_MaxAmmo, self );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_weapon_change_complete", &ShopCallback_MaxAmmo, self );

	[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchaseMaxAmmo_AllWeapons, 1500 );
	[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, "Purchase max ammo for all weapons", undefined, "All weapons have max ammo" );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_ammo_purchased", &ShopCallback_MaxAmmoAllWeapons, self );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_weapon_fired", &ShopCallback_MaxAmmoAllWeapons, self );	
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_weapon_change_complete", &ShopCallback_MaxAmmoAllWeapons, self );

	[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchaseMaxHealth, 750, 25 );
	[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, "Increase max health", undefined, "Max health limit reached" );
}

class Shop
{
	var data;					//used to store menu data while builind the menu
	var menu;					//data structure that hold all the information
	var callbacks;

	var index_top_menu;			//used to determine which menu to start drawing from 

	var team;					//set what team can run the shop items (fail safe)

	constructor()
	{
		data = [];
		menu = [];
		callbacks = [];

		index_top_menu = 0;

		team = "";
	}

	destructor()
	{

	}

	/* *************************************************************************************

		Susection:		Ownership
		Description:	Sets which team can use the shop.

	************************************************************************************* */

	function SetShopOwner( _team )
	{
		if( !util::isValidTeam( _team ) )
		{
			return;
		}

		team = _team;
	}

	function GetShopOwner()
	{
		return team;
	}

	/* *************************************************************************************

		Susection:		Building
		Description:	Build the parents, options, and callbacks

	************************************************************************************* */

	function AddParent( parent, is_gun_dependent = false, manual_scroll_lock = false )
	{
		if( !util::isValidString( parent ) )
		{
			return;
		}

		//don't add duplicates of the same parent
		if( isValidParent( parent ) )
		{
			return;
		}

		data[ parent ] = SpawnStruct();

		data[ parent ].index = util::GetArraySize( menu );
		data[ parent ].scroll = 0;
		data[ parent ].scroll_sub = [];								//only used with gun dependent options
		data[ parent ].manual_scroll_lock = manual_scroll_lock;		//prevent the user from manually scrolling
		data[ parent ].is_gun_dependent = is_gun_dependent;
	}

	function AddOption_GunDependent( parent, weapon, func, cost = 0, parameter_1 = undefined, parameter_2 = undefined, parameter_3 = undefined, is_default = false )
	{
		if( !isParentGunDependent( parent ) )
		{
			return;
		}

		if( !util::isValidWeapon( weapon ) )
		{
			return;
		}

		if( !util::isValidFunction( func ) )
		{
			return;
		}

		index_parent = GetParentIndex( parent );
		index_option = util::GetArraySize( menu[ index_parent ] );

		reference = util::GetBaseWeapon( weapon ).name;

		menu[ index_parent ][ index_option ] = SetProperties( parent, index_parent, index_option, func, cost, parameter_1, parameter_2, parameter_3, is_default );
		menu[ index_parent ][ index_option ].reference = reference;

		if( !util::isValidArray( data[ parent ].scroll_sub[ reference ] ) )
		{
			SetParentScroll_Sub( parent, reference, index_option );
		}
	}

	function AddOption( parent, func, cost = 0, parameter_1 = undefined, parameter_2 = undefined, parameter_3 = undefined, is_default = false )
	{
		if( !isValidParent( parent ) )
		{
			return;
		}

		if( !util::isValidFunction( func ) )
		{
			return;
		}

		index_parent = GetParentIndex( parent );
		index_option = util::GetArraySize( menu[ index_parent ] );

		menu[ index_parent ][ index_option ] = SetProperties( parent, index_parent, index_option, func, cost, parameter_1, parameter_2, parameter_3, is_default );
	}

	function private SetProperties( parent, index_parent, index_option, func, cost, parameter_1, parameter_2, parameter_3, is_default )
	{
		element = SpawnStruct();

		element.option = SpawnStruct();

		element.option.display = "";			//auto-generated
		element.option.purchase = "";			//mandatory
		element.option.bought = "";				//optional
		element.option.unavailable = "";		//optional
		element.option.swap = "";				//optional

		element.callbacks = [];					//optional

		element.cost = cost;					//optional

		element.bought = false;					//mandatory
		element.available = true;				//mandatory
		element.swappable = false;				//mandatory
		element.is_default = is_default;		//optional

		element.parent = parent;				//mandatory
		element.index_parent = index_parent;	//auto-generated
		element.index_option = index_option;	//auto-generated

		element.func = func;					//mandatory

		element.parameter_1 = parameter_1;		//optional
		element.parameter_2 = parameter_2;		//optional
		element.parameter_3 = parameter_3;		//optional
		
		element.reference = "";					//optional

		return element;
	}

	function AddDisplayChoices( parent, display_purchase, display_bought = "", display_unavailable = "", display_swap = "" )
	{
		if( !isValidParent( parent ) )
		{
			return;
		}

		if( !util::isValidString( display_purchase ) )
		{
			return;
		}

		index_parent = GetParentIndex( parent );
		index_option = util::GetArraySize( menu[ index_parent ] ) - 1;

		//this was called before AddOption
		if( index_option < 0 )
		{
			return;
		}

		menu[ index_parent ][ index_option ].option.display = display_purchase;
		menu[ index_parent ][ index_option ].option.purchase = display_purchase;
		menu[ index_parent ][ index_option ].option.bought = display_bought;
		menu[ index_parent ][ index_option ].option.unavailable = display_unavailable;
		menu[ index_parent ][ index_option ].option.swap = display_swap;
	}

	function private GetDisplayChoice( index_parent, index_option )
	{
		option = "";

		element = menu[ index_parent ][ index_option ];

		if( element.bought )
		{
			option = element.option.bought;
		}
		else if( !element.available )
		{
			if( element.swappable )
			{
				option = element.option.swap;
			}
			else if( util::isValidString( element.option.unavailable ) )
			{
				option = element.option.unavailable;
			}
			else
			{
				option = element.option.bought;
			}
		}
		else
		{
			option = element.option.purchase;
		}

		return option;
	}

	function AddCallback( parent, event, func, obj = undefined )
	{
		if( !isValidParent( parent ) )
		{
			return;
		}

		if( !util::isValidString( event ) )
		{
			return;
		}

		if( !util::isValidFunction( func ) )
		{
			return;
		}

		index_parent = GetParentIndex( parent );
		index_option = util::GetArraySize( menu[ index_parent ] ) - 1;

		//this was called before AddOption
		if( index_option < 0 )
		{
			return;
		}

		if( !util::isValidArray( callbacks[ event ] ) )
		{
			callbacks[ event ] = [];
		}

		element = menu[ index_parent ][ index_option ];

		callback = SpawnStruct();

		callback.obj = obj;
		callback.func = func;
		callback.index_parent = element.index_parent;
		callback.index_option = element.index_option;

		if( !array::contains( callbacks[ event ], callback ) )
		{
			ARRAY_ADD( callbacks[ event ], callback );
		}
	}

	/* *************************************************************************************

		Subsection:		Parent Data
		Description:	Gets/Sets the meta-data information for each parent

	************************************************************************************* */

	function private GetParents()
	{
		return GetArrayKeys( data );
	}

	function private GetParentIndex( parent )
	{
		index = 0;

		if( !isValidParent( parent ) )
		{
			return index;
		}

		index = data[ parent ].index;

		return index;
	}

	function private GetParentFromIndex( index_parent )
	{
		_parent = "";

		if( !util::isValidInt( index_parent ) || index_parent < 0 )
		{
			return _parent;
		}

		parents = GetParents();

		foreach( parent in parents )
		{
			if( data[ parent ].index == index_parent )
			{
				_parent = parent;

				return _parent;
			}
		}

		return _parent;
	}

	function private GetParentScroll( parent )
	{
		scroll = 0;

		if( !isValidParent( parent ) )
		{
			return scroll;
		}

		scroll = data[ parent ].scroll;

		return scroll;
	}

	function private SetParentScroll( parent, scroll )
	{
		if( !isValidParent( parent ) )
		{
			return;
		}

		index_parent = GetParentIndex( parent );

		if( !util::isValidInt( scroll ) || scroll < 0 || scroll > util::GetArraySize( menu[ index_parent ] ) - 1 )
		{
			return;
		}

		data[ parent ].scroll = scroll;
	}

	function private GetParentScroll_Sub( parent, reference )
	{
		scroll = 0;

		if( !util::isValidString( reference ) )
		{
			return scroll;
		}

		if( !util::isValidInt( data[ parent ].scroll_sub[ reference ] ) )
		{
			return scroll;
		}

		scroll = data[ parent ].scroll_sub[ reference ];

		return scroll;
	}

	function SetParentScroll_Sub( parent, reference, scroll )
	{
		index_parent = GetParentIndex( parent );

		if( !util::isValidInt( scroll ) || scroll < 0 || scroll > util::GetArraySize( menu[ index_parent ] ) - 1 )
		{
			return;
		}

		data[ parent ].scroll_sub[ reference ] = Int( scroll );
	}

	/* *************************************************************************************

		Sub Section:	Parent Data Checks
		Description:	Bollean checks when handling any of the menus

	************************************************************************************* */	

	function private isValidParent( parent )
	{
		result = false;

		if( !util::isValidString( parent ) )
		{
			return result;
		}

		result = isdefined( data[ parent ] );

		return result;
	}

	function private isParentGunDependent( parent )
	{
		result = false;

		if( !isValidParent( parent ) )
		{
			return result;
		}

		result = data[ parent ].is_gun_dependent;

		return result;
	}

	function private isParentScrollLocked( parent )
	{
		result = false;

		if( !isValidParent( parent ) )
		{
			return result;
		}

		result = data[ parent ].manual_scroll_lock;

		return result;
	}

	/* *************************************************************************************

		Sub Section:	Top Menu
		Description:	Gets/Sets which menu should be drawn first.
						Automatically set with the scrolling logic.

	************************************************************************************* */

	function GetTopMenuIndex()
	{
		index = 0;

		if( !util::isValidInt( index_top_menu ) )
		{
			return index;
		}

		index = index_top_menu;

		return index;
	}

	function private SetTopMenu( index )
	{
		if( !util::isValidInt( index ) || index < 0 )
		{
			return;
		}

		index_top_menu = index;
	}

	/* *************************************************************************************

		Sub Section:	Option Updating
		Description:	Handles the options and return menu elements

	************************************************************************************* */

	function GetOption( index_selected, weapon )
	{
		option = undefined;

		if( !util::isValidInt( index_selected ) )
		{
			return option;
		}

		weapon_base_reference = util::GetBaseWeapon( weapon ).name;

		index = GetTopMenuIndex() + index_selected;
		parent = GetParentFromIndex( index );

		if( !isValidParent( parent ) )
		{
			return option;
		}

		scroll = ( isParentGunDependent( parent ) ? GetParentScroll_Sub( parent, weapon_base_reference ) : GetParentScroll( parent ) );

		menu[ index ][ scroll ].option.display = GetDisplayChoice( index, scroll );

		return menu[ index ][ scroll ];
	}

	function SetOption( parent, index_parent, index_option, element )
	{
		if( !isValidParent( parent ) )
		{
			return;
		}

		menu[ index_parent ][ index_option ] = element;
	}

	function GetOptionState( element )
	{
		state = SpawnStruct();

		state.bought = element.bought;
		state.swappable = element.swappable;
		state.available = element.available;

		return state;
	}

	function OptionStateChanged( element, state )
	{
		if( element.bought != state.bought )
		{
			return true;
		}

		if( element.swappable != state.swappable )
		{
			return true;
		}

		if( element.available != state.available )
		{
			return true;
		}

		return false;
	}

	function isOptionDrawn( element, menu_display_limit, weapon )
	{
		range_min = GetTopMenuIndex();
		range_max = range_min + menu_display_limit - 1;

		//parent is out of the range that is drawn
		if( element.index_parent < range_min || element.index_parent > range_max )
		{
			return false;
		}

		weapon_base_reference = util::GetBaseWeapon( weapon ).name;
		scroll = ( isParentGunDependent( element.parent ) ? GetParentScroll_Sub( element.parent, weapon_base_reference ) : GetParentScroll( element.parent ) );

		//the element being checked is not he one that is currently drawn
		if( element.index_option != scroll )
		{
			return false;
		}

		return true;
	}

	/* *************************************************************************************

		Sub Section:	Running
		Description:	Executes the functions and callbacks for each parent element.

	************************************************************************************* */

	function RunOption_Wrapper( obj, index_selected, weapon, player )
	{
		owner = GetShopOwner();

		element = GetOption( index_selected, weapon );

		if( !isdefined( element ) )
		{
			return;
		}

		if( element.bought )
		{
			return;
		}

		if( !element.available && !element.swappable )
		{
			return;
		}

		//check if the player has enough money
		if( player.cash.available.current < element.cost )
		{
			return;
		}

		state = GetOptionState( element );

		if( isdefined( element.parameter_3 ) )
		{
			obj [[ element.func ]]( owner, element.cost, element, state, element.parameter_1, element.parameter_2, element.parameter_3 );
		}
		else if( isdefined( element.parameter_2 ) )
		{
			obj [[ element.func ]]( owner, element.cost, element, state, element.parameter_1, element.parameter_2 );
		}
		else if( isdefined( element.parameter_1 ) )
		{
			obj [[ element.func ]]( owner, element.cost, element, state, element.parameter_1 );
		}
		else
		{
			obj [[ element.func ]]( owner, element.cost, element, state );
		}
	}

	function Callback( event )
	{
		if( !util::isValidString( event ) )
		{
			return;
		}

		owner = GetShopOwner();
		events = GetArrayKeys( callbacks );

		foreach( callback in callbacks[ event ] )
		{
			//get the element again just in case the element was updated somewhere
			element = menu[ callback.index_parent ][ callback.index_option ];
			state = GetOptionState( element );

			if( isdefined( callback.obj ) )
			{
				callback.obj thread [[ callback.func ]]( owner, element, state );
			}
			else
			{
				self thread [[ callback.func ]]( owner, element, state );
			}
		}
	}

	/* *************************************************************************************

		Sub Section:	Scrolling
		Description:	Handles the scroll logic for both the shop and the shop hud

	************************************************************************************* */

	function Scroll_Vertical( index_selected, increment, menu_display_limit )
	{
		index = 0;

		if( !util::isValidInt( index_selected ) || !util::isValidInt( increment ) || !util::isValidInt( menu_display_limit ) )
		{
			return index;
		}

		index_selected += increment;
		index_selected = CheckScrollBounds_Vertical( index_selected, menu_display_limit );

		index = index_selected;

		return index;
	}

	function private CheckScrollBounds_Vertical( index_selected, menu_display_limit )
	{
		top_menu = GetTopMenuIndex();

		if( index_selected < 0 )
		{
			if( top_menu > 0 )
			{
				index_selected = 0;

				top_menu--;
				SetTopMenu( top_menu );
			}
			else
			{
				index_selected = menu_display_limit - 1;
				
				top_menu = menu.size - menu_display_limit;
				SetTopMenu( top_menu );
			}
		}
		else if( index_selected > menu_display_limit - 1 )
		{
			if( top_menu + menu_display_limit > menu.size - 1 )
			{
				index_selected = 0;
				SetTopMenu( index_selected );
			}
			else
			{
				index_selected = menu_display_limit - 1;

				top_menu++;
				SetTopMenu( top_menu );
			}
		}

		return index_selected;
	}

	function Scroll_Horizontal( index_selected, increment, weapon = undefined, manual_scroll = true )
	{
		if( !util::isValidInt( index_selected ) || !util::isValidInt( increment ) )
		{
			return;
		}

		index_parent = GetTopMenuIndex() + index_selected;
		parent = GetParentFromIndex( index_parent );

		if( !isValidParent( parent ) )
		{
			return;
		}

		if( manual_scroll && isParentScrollLocked( parent ) )
		{
			return;
		}

		if( isParentGunDependent( parent ) )
		{
			if( !util::isValidWeapon( weapon ) )
			{
				return;
			}

			reference = util::GetBaseWeapon( weapon ).name;

			cycling = true;


			do
			{
				scroll = GetParentScroll_Sub( parent, reference ) + increment;
				scroll = CheckScrollBounds_Horizontal( index_parent, scroll );
				SetParentScroll_Sub( parent, reference, scroll );				

				IPrintLn( scroll );

				if( util::CompareStrings( menu[ index_parent ][ scroll ].reference, reference ) )
				{
					cycling = false;
				}				
			}
			while( cycling );
		}
		else
		{
			scroll = GetParentScroll( parent ) + increment;
			scroll = CheckScrollBounds_Horizontal( index_parent, scroll );

			SetParentScroll( parent, scroll );
		}
	}	

	function private CheckScrollBounds_Horizontal( index_parent, scroll )
	{
		if( scroll < 0 )
		{
			scroll = menu[ index_parent ].size - 1;
		}
		else if( scroll > menu[ index_parent ].size - 1 )
		{
			scroll = 0;
		}

		return scroll;
	}
}

/* -------------------------------------------------------------------------------------

	Section:		Shop Callbacks
	Description:	These call backs function the same as native callbacks in the game, but tailored for the shop.
					When a callback is added, the latest element of the specified parent is associated with that call.					
					All of the fields associated with the element are available to use.

	Parameters:		1) team
					2) element
					3) state (bought, available, and swappable)

	Usage:			Typically these callbacks are used to update the shop when multiple different events can occur instead of just when a shop function is called.

	Example:		The "Buy Max Ammo" option needs to checked/updated whenever a player switches weapons, buys ammo, buys a new gun, or when the weapon is fired.
					"PurchaseMaxAmmo()" will only update the option when ammo is bought, but it still needs to updated for the other cases listed above.
					The callback "ShopCallback_MaxAmmo()" is called whenever a weapon is fired, max ammo for all weapons is bought, or when a weapon is switched to keep the otion up to date.
					If an option can only be affected through the normal shop function, no callback is required. (Ex: Buying Perks)

------------------------------------------------------------------------------------- */

function ShopCallback_PowerPurchased( team, element, state )
{
	bought = element.bought;
	available = element.available;

	//player doesn't have a gadget weapon 
	if( !self util::HasHeroWeapon() )
	{
		element.bought = false;
		element.available = false;
	}
	else
	{
		//the player has a gadget, check to see if it have max power
		slot = 0;
		if( self GadgetPowerGet( slot ) == 100 )
		{
			element.bought = true;
			element.available = false;
		}
		else
		{
			element.bought = false;
			element.available = true;
		}
	}	

	[[ self.shop_system[ team ] ]]->SetOption( element.parent, element.index_parent, element.index_option, element );

	RefreshShop_Safe_Single( team, element, state );
}

function ShopCallback_AttachmentUpgrade( team, element, state )
{
	weapon_current = self GetCurrentWeapon();
	weapon_current_base = util::GetBaseWeapon( weapon_current );
	weapon_current_base_reference = weapon_current_base.name;

	attachments = weapon_current.attachments;
	optic_reference = self util::GetOpticOnWeapon( weapon_current );

	if( !util::CompareStrings( element.reference, weapon_current_base_reference ) )
	{
		return;
	}

	attachment = element.parameter_2;

	//optics can still be swapped even if the max attachments are on the gun as long as an optic is already on the gun
	if( util::isValidString( optic_reference ) && util::CompareStrings( attachment.group, "optic" ) )
	{
		if( !util::CompareStrings( attachment.reference, optic_reference ) )
		{
			element.bought = false;
			element.swappable = true;
			element.available = false;
		}
	}
	//the gun has max amount of attachments and none can be swapped
	else if( util::GetArraySize( attachments ) >= quarantine_chaos::GetMaxAttachmentsAllowed() )
	{
		element.swappable = false;
		element.available = false;
	}

	[[ self.shop_system[ team ] ]]->SetOption( element.parent, element.index_parent, element.index_option, element );
}

function ShopCallback_MaxAmmo( team, element, state )
{
	weapon_current = self GetCurrentWeapon();

	element.available = ( util::HasMaxAmmo( weapon_current ) ? false : true );
	[[ self.shop_system[ team ] ]]->SetOption( element.parent, element.index_parent, element.index_option, element );

	RefreshShop_Safe_Single( team, element, state );
}

function ShopCallback_MaxAmmoAllWeapons( team, element, state ) 
{
	weapons = self GetWeaponsListPrimaries();

	available = false;

	foreach( weapon in weapons )
	{
		if( !util::HasMaxAmmo( weapon ) )
		{
			available = true;
		}
	}	
	
	element.available = available;
	[[ self.shop_system[ team ] ]]->SetOption( element.parent, element.index_parent, element.index_option, element );

	RefreshShop_Safe_Single( team, element, state );
}

/* -------------------------------------------------------------------------------------

	Section:		Cash
	Description:	Handles the cash that the player has available for them to spend.

------------------------------------------------------------------------------------- */

function ResetChash()
{
	self.cash = SpawnStruct();

	self.cash.start = ( self quarantine_chaos::isZombie() ? 300 : 100 );
	self.cash.spent = 0;

	self.cash.available = SpawnStruct();
	self.cash.available.current = self.cash.start - self.cash.spent;
	self.cash.available.old = self.cash.start - self.cash.spent;

	self.pers[ "score" ] = 0;
	self.pers[ "kills" ] = 0;
	self.pers[ "deaths" ] = 0;
	self.pers[ "assists" ] = 0;
	self.pers[ "kdratio" ] = 0;	
}