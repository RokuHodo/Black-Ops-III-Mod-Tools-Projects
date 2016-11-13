//native files
#using scripts\shared\util_shared;

#using scripts\shared\bots\_bot;

#using scripts\mp\_teamops;
#using scripts\mp\_util;

#insert scripts\shared\shared.gsh;

//custom files
#using scripts\shared\mod_util;

#namespace dev;

/* -------------------------------------------------------------------------------------

	Section:		Developer Functions
	Description:	These are functions used to aid in the development/testing process.
					Anything found here won't be active in the publshed release on the workshop.

------------------------------------------------------------------------------------- */

function WatchBotButtons()
{
	if( self istestclient() )
	{
		return;
	}

	self notify( "bot_button_watch_reset" );	

	self endon( "death" );
	self endon( "disconnect" );
	self endon( "bot_button_watch_reset" );

	level endon( "game_ended" );

	while( true )
	{
		if( self util::isButtonPressed( "+activate" ) && self util::isButtonPressed( "+speed_throw" ) )
		{
			bot::add_bots( 1, "allies" );

			wait( 0.5 );
		}
		else if( self util::isButtonPressed( "+activate" ) && self util::isButtonPressed( "+melee" ) )
		{
			bot::remove_bots( 1, "allies" );

			wait( 0.5 );
		}
		
		WAIT_SERVER_FRAME;
	}	
}