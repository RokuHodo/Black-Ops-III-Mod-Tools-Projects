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
#using scripts\mp\gametypes\quarantine_chaos_shop;

#namespace shop;

#precache( "string", "QC_HEALTH" );
#precache( "string", "QC_CASH_AVAILABLE" );
#precache( "string", "QC_SHOP_INSTRUCTIONS" );

/* -------------------------------------------------------------------------------------

	Section:		Drawing
	Description:	Draw the shops, player information, and instructions.

------------------------------------------------------------------------------------- */

function DrawHuds()
{
	team = self.pers[ "team" ];

	font_scale = 1.5;
	text_height = util::GetTextHeight( font_scale );

	SetMenuDisplayLimit( self.shop_system[ team ].menu.size );
	menu_display_limit = GetMenuDisplayLimit();

	//no items to draw, destroy the shop
	if( menu_display_limit < 0 )
	{
		self DestroyShop();

		return;
	}

	if( !util::CompareStrings( team, [[ self.shop_system[ team ] ]]->GetShopOwner() ) )
	{
		self DestroyShop();

		return;
	}

	[[ self.shop_system[ team ] ]]->Callback( "shop_power_purchased" );

	//first time the menu is drawn, need to set the index_selected
	if( GetIndexSelected() < 0 )
	{
		SetIndexSelected( [[ self.shop_system[ team ] ]]->GetTopMenuIndex() );		
	}

	index_selected = GetIndexSelected();

	DrawShop( team, font_scale, text_height, menu_display_limit, index_selected );
	DrawPlayerInfo( font_scale, text_height );
	DrawInstructions( font_scale, menu_display_limit );	

	self thread RunShopActions( team, index_selected, menu_display_limit );
}

function DrawShop( team, font_scale, text_height, menu_display_limit, index_selected )
{
	if( util::isValidArray( self.hud_system[ "shop" ] ) )
	{
		return;
	}

	self.hud_system[ "shop" ] = [];	
	self.hud_system[ "shop" ][ "menu" ] = [];

	shader_height = text_height * menu_display_limit;
	offset = ( -1 * text_height * menu_display_limit ) / 2;	

	for( index = 0; index < menu_display_limit; index++ )
	{
		self.hud_system[ "shop" ][ "menu" ][ index ] = util::CreateDisplay(	1,
																			font_scale,
																			"BOTTOM RIGHT",
																			"BOTTOM RIGHT",
																			-10,
																			GetVerticalPosition( index, menu_display_limit, font_scale, offset ) );

		self thread util::DestroyOnNotify( self.hud_system[ "shop" ][ "menu" ][ index ], "destroy_shop" );
	}

	width = ( self quarantine_chaos::isZombie() ? 200 : 275 );

	self.hud_system[ "shop" ][ "shader" ] = util::CreateShader(	0.5,
																"white",
																width,
																shader_height,
																"BOTTOM RIGHT",
																"BOTTOM RIGHT",
																self.hud_system[ "shop" ][ "menu" ][ 0 ].x + 5,
																GetVerticalPosition( self.hud_system[ "shop" ][ "menu" ].size - 1, menu_display_limit, font_scale, offset ),
																( 0, 0, 0 ) );

	self thread util::DestroyOnNotify_Array( self.hud_system[ "shop" ], "destroy_shop" );
	
	//can't use the notify here because the button monitoring hasn't started yet
	RefreshShop();
}

function DrawPlayerInfo( font_scale, text_height )
{
	if( util::isValidArray( self.hud_system[ "player" ] ) )
	{
		return;
	}

	self.hud_system[ "player" ] = [];
	self.hud_system[ "player" ][ "cash" ] = util::CreateDisplay(	1,
																	font_scale,
																	"BOTTOM RIGHT",
																	"BOTTOM RIGHT",
																	self.hud_system[ "shop" ][ "menu" ][ 0 ].x,
																	self.hud_system[ "shop" ][ "menu" ][ 0 ].y - text_height - 5,
																	self.cash.available.current,
																	&"QC_CASH_AVAILABLE" );

	self thread util::DestroyOnNotify( self.hud_system[ "player" ][ "cash" ], "destroy_cash_hud" );

	self.hud_system[ "player" ][ "health" ] = util::CreateDisplay(	1,
																	font_scale,
																	"BOTTOM RIGHT",
																	"BOTTOM RIGHT",
																	self.hud_system[ "player" ][ "cash" ].x,
																	self.hud_system[ "player" ][ "cash" ].y - text_height,
																	self.health,
																	&"QC_HEALTH" );

	self thread MonitorHealth();
	self thread util::DestroyOnNotify( self.hud_system[ "player" ][ "health" ], "destroy_health_hud" );

	shader_width = 133;
	shader_height = text_height * 2;
	self.hud_system[ "player" ][ "shader" ] = util::CreateShader(	0.5,
																	"white",
																	shader_width,
																	shader_height,
																	"BOTTOM RIGHT",
																	"BOTTOM RIGHT",
																	self.hud_system[ "player" ][ "cash" ].x + 5,
																	self.hud_system[ "player" ][ "cash" ].y,
																	( 0, 0, 0 ) );

	self thread util::DestroyOnNotify_Array( self.hud_system[ "player" ], "destroy_player_info" );
}

function DrawInstructions( font_scale, menu_display_limit )
{
	if( util::isValidArray( self.hud_system[ "instructions" ] ) )
	{
		return;
	}

	shader_height = util::GetTextHeight( font_scale ) * 3;
	offset = ( shader_height * ( 3 - 1 ) ) / 3;

	self.hud_system[ "instructions" ] = [];
	self.hud_system[ "instructions" ][ "text" ] = util::CreateDisplay( 	1,																	//alpha
																		font_scale,															//fontscale
																		"BOTTOM LEFT",														//align point
																		"BOTTOM LEFT",														//align relative
																		10,																	//x
																		shader_height * -1,													//y
																		&"QC_SHOP_INSTRUCTIONS" );											//text

	self.hud_system[ "instructions" ][ "shader" ] = util::CreateShader(	0.5,																//alpha
																		"white",															//shader
																		150,																//width
																		shader_height,														//height
																		"BOTTOM LEFT",														//align point
																		"BOTTOM LEFT",														//align relative
																		self.hud_system[ "instructions" ][ "text" ].x - 5,					//x
																		self.hud_system[ "instructions" ][ "text" ].y + offset,				//y
																		( 0, 0, 0 ) );														//color

	self thread util::DestroyOnNotify_Array( self.hud_system[ "instructions" ], "destroy_instructions" );
}

/* -------------------------------------------------------------------------------------

	Section:		Refreshing
	Description:	Refreshes the shops, player information, and instructions.

------------------------------------------------------------------------------------- */

function RefreshShop()
{
	team = self.pers[ "team" ];

	index_selected = GetIndexSelected();
	menu_display_limit = GetMenuDisplayLimit();

	if( !util::isValidTeam( team ) )
	{
		return;
	}

	if( !util::isValidInt( index_selected ) || index_selected < 0 )
	{
		return;
	}

	if( !util::isValidInt( menu_display_limit ) || menu_display_limit < 0 )
	{
		self DestroyShop();

		return;
	}

	if( !util::isValidArray( self.hud_system[ "shop" ][ "menu" ] ) )
	{
		self DestroyShop();

		return;
	}

	WAIT_SERVER_FRAME;

	for( index = 0; index < menu_display_limit; index++ )
	{
		element = [[ self.shop_system[ team ] ]]->GetOption( index, self GetCurrentWeapon() );

		color = GetShopColor( index_selected, index, element );
		display_text = color.option + element.option.display;

		if( !element.bought && !element.is_default )		
		{
			if( element.available || element.swappable )
			{
				display_text += " ^7[" + color.cost + "$^7" + element.cost + "]";
			}
		}

		self.hud_system[ "shop" ][ "menu" ][ index ] SetText( display_text );
	}

	self IPrintLn( "shop refreshed" );
}

function RefreshShop_Safe_Single( team, element, state )
{
	menu_display_limit = GetMenuDisplayLimit();
	weapon_current = self GetCurrentWeapon();

	//only refresh the shop if the option being updated is drawn
	if( [[ self.shop_system[ team ] ]]->isOptionDrawn( element, menu_display_limit, weapon_current ) && [[ self.shop_system[ team ] ]]->OptionStateChanged( element, state ) )
	{
		RefreshShop();
	}
}

function RefreshCash( attacker = self )
{

	WAIT_SERVER_FRAME;

	//assists are awarded by the game on a different frame, need to wait one more
	if( self != attacker )
	{
		WAIT_SERVER_FRAME;
	}

	if( !util::isValidArray( self.hud_system[ "player" ] ) || !isdefined( self.hud_system[ "player" ][ "cash" ] ) )
	{
		self notify( "destroy_cash_hud" );

		return;
	}

	self.cash.available.current = self.cash.start + self.pers[ "score" ] - self.cash.spent;

	if( self.cash.available.current != self.cash.available.old )
	{
		self.hud_system[ "player" ][ "cash" ] SetValue( self.cash.available.current );
		self.cash.available.old = self.cash.available.current;

		self IPrintLn( "cash refreshed" );

		RefreshShop();	
	}
}

function MonitorHealth()
{
	self endon( "disconnect" );
	self endon( "destroy_health_hud" );

	level endon( "game_ended" );

	while( true )
	{
		health_old = self.health;

		WAIT_SERVER_FRAME;

		if( self.health != health_old )
		{
			self RefreshHealth();
		}
	}
}

//keep this separate to keep the same structure as the cash hud
function RefreshHealth()
{
	if( !util::isValidArray( self.hud_system[ "player" ] ) || !isdefined( self.hud_system[ "player" ][ "health" ] ) )
	{
		self notify( "destroy_health_hud" );

		return false;
	}

	self.hud_system[ "player" ][ "health" ] SetValue( self.health );

	self IPrintLn( "health refreshed" );
}

/* -------------------------------------------------------------------------------------

	Section:		Destroys
	Description:	Destroys the shop, player info, and instructions.

------------------------------------------------------------------------------------- */

function DestroyShop()
{
	self notify( "destroy_shop" );
	self notify( "destroy_instructions" );
	self notify( "destroy_player_info" );

	self notify( "shop_actions_end" );
	
	self.hud_system[ "shop" ] = undefined;
	self.hud_system[ "player" ] = undefined;
	self.hud_system[ "instructions" ] = undefined;
}

function DestroyShop_AllPlayers()
{
	players = GetPlayers();

	array::thread_all( players, &DestroyShop );
}

/* -------------------------------------------------------------------------------------

	Section:		Get/Sets
	Description:	Get and set the information used to draw the shop and player info.

------------------------------------------------------------------------------------- */

function GetIndexSelected()
{
	index_selected = -1;

	if( util::isValidInt( self.index_selected ) && self.index_selected > -1 )
	{
		index_selected = self.index_selected;
	}

	menu_display_limit = GetMenuDisplayLimit();

	//in case the menu size was changed somehow between refreshes
	if( index_selected < menu_display_limit - 1 || index_selected > menu_display_limit - 1 || menu_display_limit == -1 )
	{
		index_selected = 0;
	}

	return index_selected;
}

function SetIndexSelected( _index_selected )
{
	index_selected = -1;

	if( util::isValidInt( _index_selected ) && _index_selected > -1 )
	{
		index_selected = _index_selected;
	}

	self.index_selected = index_selected;

	self IPrintLn( "index selected set to " + self.index_selected );
}

function GetMenuDisplayLimit()
{
	menu_display_limit = -1;

	if( util::isValidInt( self.menu_display_limit ) && self.menu_display_limit > 0 )
	{
		menu_display_limit = self.menu_display_limit;
	}

	return Int( menu_display_limit );
}

function SetMenuDisplayLimit( _menu_display_limit )
{
	menu_display_limit = -1;

	if( util::isValidInt( _menu_display_limit ) && _menu_display_limit > 0 )
	{
		menu_display_limit = _menu_display_limit;
	}

	self.menu_display_limit = Int( Min( menu_display_limit, 3 ) );
}

function GetVerticalPosition( index, display_size, font_scale, offset = 0 )
{
	position = 0;

	if( !util::isValidInt( index ) || !util::isValidInt( display_size ) || !util::isValidFloat( font_scale ) )
	{
		return position;
	}

	text_height = level.fontHeight * font_scale;
	elem_height = text_height * display_size;

	position = ( index * text_height ) - ( elem_height / 2 ) + offset;

	return position;
}

/* -------------------------------------------------------------------------------------

	Section:		Color
	Description:	Build the color information for the shop text.

------------------------------------------------------------------------------------- */

function GetShopColor( index_selected, index, menu_element )
{
	color = SpawnStruct();
	color.option = "^7";
	color.cost = "^2";
	color.cash = "^2";

	if( index_selected == index )
	{
		color.option = "^3";
	}

	if( menu_element.cost > self.cash.available.current )
	{
		color.cost = "^1";
	}

	return color;
}

/* -------------------------------------------------------------------------------------

	Section:		Shop Buttons
	Description:	Navigate through the various shop menus and items and purchase them

------------------------------------------------------------------------------------- */

function RunShopActions( team, index_selected, menu_display_limit )
{
	self notify( "shop_actions_end" );

	if( !util::isValidInt( menu_display_limit ) || menu_display_limit == 0 )
	{
		return;
	}

	self endon( "death" );
	self endon( "disconnect" );

	self endon( "shop_actions_end" );

	notifies = Array( "scroll_up", "scroll_down", "scroll_left", "scroll_right", "purchase", "weapon_change_complete", "weapon_fired", "hero_gadget_activated", "heroAbility_off" );

	self thread MonitorShopActions();

	while( 1 )
	{
		button = self util::waittill_any_array_return( notifies );

		switch( button )
		{
			case "purchase":				
			{
				[[ self.shop_system[ team ] ]]->RunOption_Wrapper( self, index_selected, self GetCurrentWeapon(), self );
			}
			break;

			case "scroll_up":
			case "scroll_down":
			{
				increment = ( util::CompareStrings( button, "scroll_up" ) ? -1 : 1 );
				index_selected = [[ self.shop_system[ team ] ]]->Scroll_Vertical( index_selected, increment, menu_display_limit );
				SetIndexSelected( index_selected );

				RefreshShop();
			}
			break;

			case "scroll_left":
			case "scroll_right":
			{
				increment = ( util::CompareStrings( button, "scroll_left" ) ? -1 : 1 );				
				[[ self.shop_system[ team ] ]]->Scroll_Horizontal( index_selected, increment, self GetCurrentWeapon() );

				RefreshShop();
			}
			break;

			case "weapon_fired":
			{
				[[ self.shop_system[ team ] ]]->Callback( "shop_weapon_fired" );
			}
			break;
			
			case "weapon_change_complete":
			{
				[[ self.shop_system[ team ] ]]->Callback( "shop_weapon_change_complete" );

				RefreshShop();
			}
			break;

			case "hero_gadget_activated":
			{
				[[ self.shop_system[ team ] ]]->Callback( "shop_gadget_activated" );
			}
			break;

			case "heroAbility_off":
			{
				[[ self.shop_system[ team ] ]]->Callback( "shop_gadget_deactivated" );
			}
			break;

			default:
			{

			}
			break;
		}		
	}
}

function MonitorShopActions()
{
	self endon( "death" );
	self endon( "disconnect" );

	self endon( "shop_actions_end" );

	response = "";
	held_start = 0;

	while( 1 )
	{
		if( self util::isButtonPressed( "+actionslot 1" ) )
		{
			response = "scroll_up";
		}		
		else if( self util::isButtonPressed( "+actionslot 2" ) )
		{
			response = "scroll_down";
		}		
		else if( self util::isButtonPressed( "+actionslot 3" ) )
		{
			response = "scroll_right";			
		}
		else if( self util::isButtonPressed( "+actionslot 4" ) )
		{
			response = "scroll_left";
		}		
		else if( self util::isButtonPressed( "+activate" ) )
		{
			selected = false;
			held_start = GetTime();

			while( self util::isButtonPressed( "+activate" ) && ! selected)
			{
				if( GetTime() - held_start >= 500 )
				{
					response = "purchase";

					selected = true;

					break;
				}

				WAIT_SERVER_FRAME;
			}
		}

		if( util::isValidString( response ) )
		{
			self notify( response );

			wait( 0.15 );
		}

		response = "";
		held_start = 0;		

		WAIT_SERVER_FRAME;
	}
}