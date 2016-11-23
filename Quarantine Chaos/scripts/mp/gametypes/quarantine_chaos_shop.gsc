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

	//WEAPONS MENU
	parent = "weapons";
	[[ self.shop_system[ team ] ]]->AddParent( parent );

	//combat axe
	weapon = GetWeapon( "hatchet" );
	weapon_name_localized = util::GetLocalizedWeaponName( weapon );

	display_purchase = "Purchase " + weapon_name_localized;
	display_bought = weapon_name_localized + " already purchased";
	[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchaseWeapon, 500, weapon );
	[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, display_purchase, display_bought );

	//ripper
	weapon = GetWeapon( "hero_armblade" );
	weapon_name_localized = util::GetLocalizedWeaponName( weapon );

	display_purchase = "Purchase " + weapon_name_localized;
	display_bought = weapon_name_localized + " already purchased";
	[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchaseWeapon, 400, weapon );
	[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, display_purchase, display_bought );

	//PERK MENU
	parent = "perks";
	[[ self.shop_system[ team ] ]]->AddParent( parent );

	perks = loadout::GetAvailablePerks( team );
	foreach( perk in perks )
	{
		display_purchase = "Purchase " + perk.name;
		display_bought = perk.name + " already purchased";

		[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchasePerk, 200, perk );
		[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, display_purchase, display_bought );
	}

	//MISC MENU
	parent = "misc";
	[[ self.shop_system[ team ] ]]->AddParent( parent );

	[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchaseMaxHealth, 500, 25 );
	[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, "Increase max health", undefined, "Max health limit reached" );

	[[ self.shop_system[ team ] ]]->AddOption( parent, &PurchaseGadgetPower, 500 );
	[[ self.shop_system[ team ] ]]->AddDisplayChoices( parent, "Purchase gadget power", "Gadget already has max power", "No gadget held" );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_power_purchased", &ShopCallback_PowerPurchased, self );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_weapon_purchased", &ShopCallback_PowerPurchased, self );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_gadget_activated", &ShopCallback_PowerPurchased, self );
	[[ self.shop_system[ team ] ]]->AddCallback( parent, "shop_gadget_deactivated", &ShopCallback_PowerPurchased, self );

	// ============================ 
	//			Human Shop			
	// ============================

	team = "allies";
	self.shop_system[ team ] = new Shop();

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
		data[ parent ].manual_scroll_lock = manual_scroll_lock;		//prevent the user from manually scrolling
		data[ parent ].is_gun_dependent = is_gun_dependent;

		data[ parent ].scroll = 0;
		data[ parent ].scroll_gun = [];
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

		index_parent = GetParentData( parent ).index;
		index_option = util::GetArraySize( menu[ index_parent ] );

		weapon_base_reference = util::GetBaseWeapon( weapon ).name;

		menu[ index_parent ][ index_option ] = SetOptionFields( parent, index_parent, index_option, func, cost, parameter_1, parameter_2, parameter_3, is_default );
		menu[ index_parent ][ index_option ].weapon_base_reference = weapon_base_reference;

		if( !util::isValidArray( GetParentData( parent ).scroll_gun[ weapon_base_reference ] ) )
		{
			SetParentScroll( parent, weapon_base_reference, index_option );
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

		index_parent = GetParentData( parent ).index;
		index_option = util::GetArraySize( menu[ index_parent ] );

		menu[ index_parent ][ index_option ] = SetOptionFields( parent, index_parent, index_option, func, cost, parameter_1, parameter_2, parameter_3, is_default );
	}

	function private SetOptionFields( parent, index_parent, index_option, func, cost, parameter_1, parameter_2, parameter_3, is_default )
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
		
		element.weapon_base_reference = "";		//optional

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

		index_parent = GetParentData( parent ).index;
		index_option = util::GetArraySize( menu[ index_parent ] ) - 1;

		//this was called before AddOption()
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

		index_parent = GetParentData( parent ).index;
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

		if( array::contains( callbacks[ event ], callback ) )
		{
			return;
		}

		ARRAY_ADD( callbacks[ event ], callback );
	}

	/* *************************************************************************************

		Subsection:		Parent Data
		Description:	Gets/Sets the meta-data information for each parent

	************************************************************************************* */

	function private GetMenu()
	{
		return menu;
	}

	function private GetParents()
	{
		return GetArrayKeys( data );
	}

	function private GetParentData( parent )
	{
		return data[ parent ];
	}

	function private GetParentMenu( parameter )
	{
		parent_menu = undefined;

		//really gheto way of doing overloading because GSC doesn't support it
		if( util::isValidInt( parameter ) )
		{
			parent_menu = menu[ parameter ];
		}
		else if( util::isValidString( parameter ) )
		{
			index_parent = GetParentData( parameter ).index;

			parent_menu = menu[ index_parent ];
		}		

		return parent_menu;
	}

	function private GetParentScroll( parent, weapon_base_reference )
	{
		parent_data = GetParentData( parent );
		parent_menu = GetParentMenu( parent );

		scroll = ( isParentGunDependent( parent ) ? parent_data.scroll_gun[ weapon_base_reference ] : parent_data.scroll );

		if( !util::isValidInt( scroll ) )
		{
			scroll = 0;
		}

		scroll = util::ClampValue_Inclusive( scroll, 0, util::GetArraySize( parent_menu ) - 1, 0 );

		return scroll;
	}

	function private SetParentScroll( parent, weapon_base_reference, scroll = 0 )
	{
		parent_menu = GetParentMenu( parent );

		if( !util::isValidInt( scroll ) || scroll < 0 || scroll > util::GetArraySize( parent_menu ) - 1 )
		{
			return;
		}

		if( isParentGunDependent( parent ) )
		{
			data[ parent ].scroll_gun[ weapon_base_reference ] = scroll;
		}
		else
		{
			data[ parent ].scroll = scroll;	
		}				
	}

	function private GetParentFromIndex( index_parent )
	{
		parent = "";

		if( !util::isValidInt( index_parent ) || index_parent < 0 )
		{
			return parent;
		}

		parents = GetParents();

		foreach( element in parents )
		{
			if( data[ element ].index == index_parent )
			{
				parent = element;

				return parent;
			}
		}

		return parent;
	}

	/* *************************************************************************************

		Sub Section:	Parent / Callback Checks
		Description:	Bollean checks when handling any of the menus and callbacks

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
		return data[ parent ].is_gun_dependent;
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

	function isValidCallbackEvent( event )
	{
		result = false;

		if( !util::isValidString( event ) )
		{
			return result;
		}

		result = isdefined( callbacks[ event ] );

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

	function private SetTopMenuIndex( index )
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

		scroll = GetParentScroll( parent, weapon_base_reference );

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

	/* *************************************************************************************

		Sub Section:	Option Boolean Checks
		Description:	Various checks used when updating / handling options.

	************************************************************************************* */

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
		result = false;

		range_min = GetTopMenuIndex();
		range_max = range_min + menu_display_limit - 1;

		//parent is out of the range that is drawn
		if( element.index_parent < range_min || element.index_parent > range_max )
		{
			return result;
		}

		weapon_base_reference = util::GetBaseWeapon( weapon ).name;

		scroll = GetParentScroll( element.parent, weapon_base_reference );

		//the element being checked is not he one that is currently drawn
		if( element.index_option != scroll )
		{
			return result;
		}

		result = true;

		return result;
	}

	/* *************************************************************************************

		Sub Section:	Running
		Description:	Executes the functions and callbacks for each parent element.

	************************************************************************************* */

	function RunOption_Wrapper( player, index_selected, weapon )
	{
		element = GetOption( index_selected, weapon );

		if( !isdefined( element ) )
		{
			return;
		}

		//has the option already been bought?
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

		player thread util::FunctionWrapper_VariableParameters( player, element.func, player.pers[ "team" ], element.cost, element, state, element.parameter_1, element.parameter_2, element.parameter_3 );
	}

	function Callback( event, player )
	{
		if( !isValidCallbackEvent( event ) )
		{
			return;
		}

		foreach( callback in callbacks[ event ] )
		{
			//get the element again just in case the element was updated somewhere
			element = GetParentMenu( callback.index_parent )[ callback.index_option ];
			state = GetOptionState( element );

			if( isdefined( callback.obj ) )
			{
				callback.obj thread [[ callback.func ]]( player.pers[ "team" ], element, state );
			}
			else
			{
				self thread [[ callback.func ]]( player.pers[ "team" ], element, state );
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

		menu_size = util::GetArraySize( GetMenu() );

		if( index_selected < 0 )
		{
			if( top_menu > 0 )
			{
				index_selected = 0;

				top_menu--;
				SetTopMenuIndex( top_menu );
			}
			else
			{
				index_selected = menu_display_limit - 1;
				
				top_menu = menu_size - menu_display_limit;
				SetTopMenuIndex( top_menu );
			}
		}
		else if( index_selected > menu_display_limit - 1 )
		{
			if( top_menu + menu_display_limit > menu_size - 1 )
			{
				index_selected = 0;
				SetTopMenuIndex( index_selected );
			}
			else
			{
				index_selected = menu_display_limit - 1;

				top_menu++;
				SetTopMenuIndex( top_menu );
			}
		}

		return index_selected;
	}

	function Scroll_Horizontal( index_selected, increment, weapon, manual_scroll = true )
	{
		if( !util::isValidInt( index_selected ) || !util::isValidInt( increment ) )
		{
			return;
		}

		index_parent = GetTopMenuIndex() + index_selected;
		parent = GetParentFromIndex( index_parent );
		parent_menu_size = util::GetArraySize( GetParentMenu( index_parent ) );

		if( !isValidParent( parent ) )
		{
			return;
		}

		if( manual_scroll && isParentScrollLocked( parent ) )
		{
			return;
		}

		weapon_base_reference = util::GetBaseWeapon( weapon ).name;		

		if( isParentGunDependent( parent ) )
		{
			if( !util::isValidWeapon( weapon ) )
			{
				return;
			}

			cycling = true;

			do
			{				
				scroll = GetParentScroll( parent, weapon_base_reference ) + increment;
				scroll = CheckScrollBounds_Horizontal( parent_menu_size, scroll );
				SetParentScroll( parent, weapon_base_reference, scroll );				

				if( util::CompareStrings( menu[ index_parent ][ scroll ].weapon_base_reference, weapon_base_reference ) )
				{
					cycling = false;
				}
			}
			while( cycling );
		}
		else
		{
			scroll = GetParentScroll( parent, weapon_base_reference ) + increment;
			scroll = CheckScrollBounds_Horizontal( parent_menu_size, scroll );
			SetParentScroll( parent, weapon_base_reference, scroll );
		}
	}	

	function private CheckScrollBounds_Horizontal( parent_menu_size, scroll )
	{
		if( scroll < 0 )
		{
			scroll = parent_menu_size - 1;
		}
		else if( scroll > parent_menu_size - 1 )
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

	Notes:			Each callback is passed the following parameters in this order:

						1) team 	- the player's team
						2) element	- the complete option struct from the shop assiciated with the callback
						3) state 	- whether the option is bought, available, or swappable

	Usage:			Typically these callbacks are used to update the shop when events can update an option other than when the option function is called.
					See below for the following example use cases:

					1) When a Callback is needed - Purchasing ripper power

						By default, the option to buy ripper power is in the shop even though a zombie does not have it when they are first turned.
						Whether or not power can be purchased can be affected by any of the following:

							A) Does the ripper already have max power?
							B) Does the player have the wepaon?
							C) Is the ripper currently active?

						Purchasing power would set the "bought" state to "true" and change the option text accordingly through the option's function, initially satisfying condition (A).
						However, conditions (B) and (C) are not handled by purchaing power. In order to further handle condition (B) and ssatisfy condition (C), a Callback is needed.
						The following events are used to call "ShopCallback_PowerPurchased" and ensure the option is handled properly outside outisde of purchaing power:

							i)		"shop_gadget_activated"		- when the ripper is activated
							ii)		"shop_gadget_deactivated"	- when the ripper is deactivated
							iii)	"shop_weapon_purchased" 	- when the weapon is purchased
							iv)		"shop_weapon_purchased" 	- cleanup for when power is purchased

						See the actual callback bellow for implimentation.

					2) When a Callback is not needed - Purchasing a perk

						Unlike purchaing power or ammo, only one event can affect the status of purchasing a perk, actually purchasing the perk.
						Updating the option's status is within the actual shop function.


					TLDR:	Use a Callback when more than one event can affect the state of an option.

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
		//the player has a gadget, check to see if it has max power or if it's in use
		slot = 0;
		if( self GadgetPowerGet( slot ) == 100 || self GadgetIsActive( slot ) || self GadgetIsReady( slot ) || self GadgetIsPrimed( slot ) )
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

	if( !util::CompareStrings( element.weapon_base_reference, weapon_current_base_reference ) )
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