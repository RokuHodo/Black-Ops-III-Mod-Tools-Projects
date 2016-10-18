#using scripts\codescripts\struct;

#using scripts\shared\math_shared;
#using scripts\shared\util_shared;
#using scripts\shared\array_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\system_shared;

#using scripts\mp\_util;

#insert scripts\shared\shared.gsh;

#namespace quarantine_chaos;

/* -------------------------------------------------------------------------------------

	Section:		Team
	Description:	Functions that aid in anything team based.					

------------------------------------------------------------------------------------- */

function isValidTeam( _team )
{
	valid = false;

	if( !isValidString( _team ) )
	{
		return valid;
	}

	foreach( team in level.teams )
	{
		if( CompareStrings( _team, team, true ) )
		{
			valid = true;
		}
	}

	return valid;
}

/* -------------------------------------------------------------------------------------

	Section:		Sound
	Description:	Functions that amake working with sounds a bit easier.					

------------------------------------------------------------------------------------- */

function PlaySoundOnHost( alias )
{
	players  = GetPlayers();

	foreach( player in players )
	{
		if( player IsHost() )
		{
			player PlaySound( alias );

			break;
		}
	}
}

/* -------------------------------------------------------------------------------------

	Section:		Text
	Description:	Functions the manipulate and handle strings.

------------------------------------------------------------------------------------- */

function TextAfter( str, point )
{
	result = "";

	if( !isValidString( str ) || !isValidString( point ) )
	{
		return result;
	}

	index = IndexOf( str, point );

	if( index != -1 )
	{
		index += point.size;

		result = GetSubStr( str, index );
	}

	return result; 
}

function TextBefore( str, point )
{
	result = "";

	if( !isValidString( str ) || !isValidString( point ) )
	{
		return result;
	}

	index = IndexOf( str, point );

	if( index != -1 )
	{
		result = GetSubStr( str, 0, index );
	}

	return result; 
}

function IndexOf( str, sub_str, start = 0 )
{
	_index = -1;

	//ony or both of the strings are null
	if( !isValidString( str ) || !isValidString( sub_str ) )
	{
		IPrintLn( "^1The string and/or sub string is null" );

		return _index;
	}

	//sub string doesn't exist in the string
	if( !SearchString( str, sub_str, true ) )
	{
		IPrintLn( "^1The sub string (" + sub_str + ") does not exist in the string (" + str + ")" );

		return _index;
	}

	if( start > str.size - 1 )
	{
		IPrintLn( "^1The starting index (" + start + ") is larger than the number of indices in the string (" + ( str.size - 1 ) + ")" );

		return _index;
	}

	if( start + sub_str.size - 1 > str.size - 1 )
	{
		IPrintLn( "^1The ending index of the first sub string search (" + ( start + sub_str.size - 1 ) + ") would be out of bounds of the last index of the string (" + ( str.size - 1 ) + ")" );

		return _index;
	}	

	//the sub string is really a char, easy mode
	if( sub_str.size == 1 )
	{
		for( index = start; index < str.size; index++ )
		{
			if( CompareStrings( str[ index ], sub_str ) )
			{
				IPrintLn( "^2The character (" + sub_str + ") was found at index (" + index + ")" );

				return index;
			}				
		}
	}
	else
	{
		index_to_match = 0;
		last_match_index = -1;

		for( index = start; index < str.size; index++ )
		{
			if( CompareStrings( str[ index ], sub_str[ index_to_match ] ) )
			{
				//first time the match was found, or the very next character was also a match
				if( last_match_index == -1 || index - last_match_index == 1 )
				{
					index_to_match++;
					last_match_index = index;
				}
			}
			else
			{
				//index compared did not match, reset
				index_to_match = 0;
				last_match_index = -1;
			}

			//all characters in the sub string were found, return the index
			if( index_to_match == sub_str.size )
			{
				index -= ( sub_str.size - 1 );

				IPrintLn( "^2The sub string (" + sub_str + ") was found at index (" + index + ")" );

				return index;
			}
		}
	}

	IPrintLn( "^1Nothing was found" );

	return _index;
}

/* -------------------------------------------------------------------------------------

	Section:		Huds
	Description:	Functions that create / delete / manipulate all types of huds.		

------------------------------------------------------------------------------------- */

function IPrintLnOnTeam( team, str )
{
	if( !isValidTeam( team ) || !isValidString( str ) )
	{
		return;
	}

	players = GetPlayers( "team" );

	foreach( player in players )
	{
		player IPrintLn( str );
	}
}

function IPrintLnBoldOnTeam( team, str )
{
	if( !isValidTeam( team ) || !isValidString( str ) )
	{
		return;
	}

	players = GetPlayers( "team" );

	foreach( player in players )
	{
		player IPrintLnBold( str );
	}
}

function CreateString( alpha, fontscale, point, relative, x, y, text )
{
	hud_string = hud::createFontString( "default", fontscale );
	hud_string hud::setPoint( point, relative, x, y );
	hud_string.sort = level.sort.string;
	hud_string.alpha = alpha;

	if( isValidString( text ) )
	{
		hud_string SetText( text );	
	}	

	return hud_string;
}

function CreateServerTimer( alpha, font_scale, point, relative, x, y, time, label = "" )
{
	timer = hud::createServerTimer( "default", font_scale );
	timer hud::setPoint( point, relative, x, y );
	timer.sort = level.sort.timer;
	timer.alpha = alpha;
	timer.label = label;

	if( isValidFloat( time ) || isValidInt( time ) )
	{
		timer SetTimer( time );	
	}

	return timer;
}

function CreateServerShader( alpha, shader, width, height, align, relative, x, y, color, team = undefined )
{
	server_shader = _CreateShader( "server",  alpha, shader, width, height, align, relative, x, y, color, team );

	return server_shader;
}

function CreateShader( alpha, shader, width, height, align, relative, x, y, color )
{	
	client_shader = _CreateShader( "client", alpha, shader, width, height, align, relative, x, y, color );

	return client_shader;
}

function _CreateShader( shader_type, alpha, shader, width, height, align, relative, x, y, color, team )
{

	if( CompareStrings( shader_type, "server", true ) )
	{
		if( isValidTeam( team ) )
		{
			_shader = NewTeamHudElem( team );
		}
		else
		{
			_shader = NewHudElem();
		}
	}
	else
	{
		_shader = NewClientHudElem( self );
	}

	_shader.elemType = "bar";

	if ( !level.splitScreen )
	{
		_shader.x = -2;
		_shader.y = -2;
	}

	_shader.hidden = false;

	_shader.color = color;
	_shader.alpha = alpha;
	_shader.sort = level.sort.shader;

	//make sure everything is an int because shaders hate floats for some reason
	x = Int( x );
	y = Int( y );
	width = Int( width );
	height = Int( height );	

	_shader.width = width;
	_shader.height = height;
	
	_shader.xOffset = 0;
	_shader.yOffset = 0;

	_shader.x = x;
	_shader.y = y;
	_shader.align = align;
	_shader.relative = relative;
	_shader hud::setPoint( align, relative, x, y );

	_shader.children = [];	
	_shader hud::setParent( level.uiParent );
	
	_shader setShader( shader, width, height );	

	return _shader;	
}

class PausableTimer
{
	var started;				//used as a check to see if MonitorTimerDestroy() should be threaded
	var running;				//used as a check to see if the time is paused or is going and while re-drawing huds

	var time_data;				//hold the upper time left in the timer, when the timer was started, and when it was paused
	var hud_offset;				//the padding around the timer label
	var background_widths;		//two bg widths, one while paused and one while it's running in case the strings are different sizes

	var properties;				//all of the propery data for the timer and the background

	var timer;					//timer object
	var background;				//bg shader object

	var time_left;

	constructor()
	{
		//initialize everything
		started = false;
		running = false;

		time_data = SpawnStruct();
		time_data.left = 0;
		time_data.stop = 0;
		time_data.start = 0;

		time_left = 0;

		hud_offset = SpawnStruct();
		background_widths = SpawnStruct();

		properties = [];
		properties[ "timer" ] = SpawnStruct();
		properties[ "background" ] = SpawnStruct();
	}

	destructor()
	{

	}

	function SetHudOffSet( x, y )
	{
		hud_offset.x = x;
		hud_offset.y = y;
	}

	//save all the properties of the huds to accurately update/re-draw them later
	function SetTimerProperties( alpha, font_scale, point, relative, x, y, _time, label_paused, label_running )
	{
		properties[ "timer" ].alpha = alpha;
		properties[ "timer" ].font_scale = font_scale;

		properties[ "timer" ].height = int( level.fontHeight * font_scale );
		properties[ "timer" ].point = point;
		properties[ "timer" ].relative = relative;
		properties[ "timer" ].x = x;
		properties[ "timer" ].y = y;

		properties[ "timer" ].time = _time;

		properties[ "timer" ].label_paused = label_paused;
		properties[ "timer" ].label_running = label_running;

		time_data.left = properties[ "timer" ].time;
	}

	function SetBackgroundProperties( alpha, shader, width_paused, width_running, color )
	{
		properties[ "background" ].alpha = alpha;		
		properties[ "background" ].color = color;

		properties[ "background" ].shader = shader;
		properties[ "background" ].height = properties[ "timer" ].height;
		properties[ "background" ].width_paused = width_paused;
		properties[ "background" ].width_running = width_running;

		properties[ "background" ].point = properties[ "timer" ].point;
		properties[ "background" ].relative = properties[ "timer" ].relative;
		properties[ "background" ].x = properties[ "timer" ].x + hud_offset.x;
		properties[ "background" ].y = properties[ "timer" ].y + hud_offset.y;
	}

	function CreateTimer()
	{
		self notify( "destroy_pausable_timer" );

		prop = properties[ "timer" ];

		timer = quarantine_chaos::CreateServerTimer( prop.alpha, prop.font_scale, prop.point, prop.relative, prop.x, prop.y, undefined, GetLabel() );

		//bg can be destroyed either when it "refreshes" or time expires
		self thread quarantine_chaos::DestroyOnNotify( timer, "destroy_pausable_all" );
		self thread quarantine_chaos::DestroyOnNotify( timer, "destroy_pausable_timer" );
	}

	function CreateBackground()
	{
		prop = properties[ "background" ];

		background = quarantine_chaos::CreateServerShader( prop.alpha, prop.shader, GetBackgroundWidth(), prop.height, prop.point, prop.relative, prop.x, prop.y, prop.color );

		//bg can be destroyed either manualls with "destroy_pausable_background" or when time expires
		self thread quarantine_chaos::DestroyOnNotify( background, "destroy_pausable_all" );
		self thread quarantine_chaos::DestroyOnNotify( background, "destroy_pausable_background" );	
	}

	function private GetLabel()
	{
		return ( running ? properties[ "timer" ].label_running : properties[ "timer" ].label_paused );		
	}

	function private GetBackgroundWidth()
	{
		return ( running ? properties[ "background" ].width_running : properties[ "background" ].width_paused );		
	}

	function Start()
	{
		if( running )
		{
			return;
		}

		if( !started )
		{
			self thread MonitorTimerDestroy();
		}

		running = true;

		//get the time the timer was started again
		time_data.start = GetTime();

		//set the new label
		//no need to re-draw the hud since there is no time currently set
		timer.label = GetLabel();
		timer SetTimer( time_data.left );

		//update the bg width to match the new label
		background SetShader( properties[ "background" ].shader, GetBackgroundWidth(), properties[ "background" ].height );
	}

	function Pause()
	{
		if( !running )
		{
			return;
		}

		running = false;

		//calculate the time to set the timer to when it is started again
		time_data.stop = GetTime();
		time_data.left -= Abs( time_data.stop - time_data.start ) / 1000;

		//update the bg width to match the new label
		background SetShader( properties[ "background" ].shader, GetBackgroundWidth(), properties[ "background" ].height );

		//"refresh" the hud
		//needs to be re-drawn because only setting the label leaves the actual timer portion on screen
		self CreateTimer();
	}	

	function private MonitorTimerDestroy()
	{
		time_left = time_data.left;

		do
		{
			if( !running )
			{
				//the timer is paused, time_data.left is already calculated and is remaining
				time_left = time_data.left;
			}
			else
			{
				//get how much time has passed since the timer was last started
				time_left = time_data.left - ( Abs( GetTime() - time_data.start ) / 1000 );
			}

			WAIT_SERVER_FRAME;
		}
		while( time_left > 0 );

		started = false;
		running = false;

		wait( 1 );

		//destroy the entire timer
		self notify( "destroy_pausable_all" );

		level notify( "countdown_complete" );
	}
}

function DestroyOnNotify_Array( huds, notification, keys_ignore )
{
	if( !isdefined( huds ) || !isValidString( notification ) )
	{
		return;
	}

	ignore = [];

	if( isValidString( keys_ignore ) )
	{
		ignore = StringToArray( keys_ignore, "|" );
	}

	keys = GetArrayKeys ( huds );

	if( !isValidArray( keys ) )
	{
		return;
	}

	self waittill( notification );	

	foreach( key in keys )
	{
		if( array::contains( ignore, key ) )
		{
			continue;
		}

		huds[ key ] Destroy();
	}
}

function DestroyOnNotify( hud, notification )
{
	if( !isdefined( hud ) || !isValidString( notification ) )
	{
		return;
	}

	self waittill( notification );

	hud Destroy();
}

/* -------------------------------------------------------------------------------------

	Section:		Universal / Miscellaneous 
	Description:	These are "true" utility functions that can be applied to nearly anything.

	Sub Sections:	1) Boolean Checks
					2) Arrays

------------------------------------------------------------------------------------- */


/* *************************************************************************************

	Sub Section:	Boolean Checks
	Description:	Perform comparison / validation checks.

************************************************************************************* */

function isValidInt( number )
{
	if( !isdefined( number ) )
	{
		return false;
	}

	if( !IsInt( number ) )
	{
		return false;
	}

	return true;
}

function isValidFloat( number )
{
	if( !isdefined( number ) )
	{
		return false;
	}

	if( !IsFloat( number ) )
	{
		return false;
	}

	return true;
}

function isValidString( str )
{
	if( !isdefined( str ) )
	{
		return false;
	}

	if( !IsString( str ) )
	{
		return false;
	}

	if( str == "" )
	{
		return false;
	}

	return true;
}

function isValidArray( array )
{
	if( !isdefined( array ) )
	{
		return false;
	}

	if( !IsArray( array ) )
	{
		return false;
	}

	return true;
}

function SearchString( str, sub_str, ignore_case )
{
	valid = false;

	if( !isdefined( ignore_case ) )
	{
		ignore_case = false;
	}

	if( !isValidString( str ) || !isValidString( sub_str ) )
	{
		return valid;
	}	

	if( ignore_case )
	{
		valid = IsSubStr( ToLower( str ), ToLower( sub_str ) );
	}
	else
	{
		valid = IsSubStr( str, sub_str );
	}

	return valid;
}

function CompareStrings( string_1, string_2, ignore_case )
{
	valid = false;

	if( !isdefined( ignore_case ) )
	{
		ignore_case = false;
	}

	if( !isValidString( string_1 ) || !isValidString( string_2 ) )
	{
		return valid;
	}

	if( ignore_case )
	{
		valid = ToLower( string_1 ) == ToLower( string_2 );		
	}
	else
	{
		valid = string_1 == string_2;
	}

	return valid;
}

/* *************************************************************************************

	Sub Section:	Arrays
	Description:	Perform comparison / validation checks.

************************************************************************************* */

function StringToarray( array, token )
{
	if( !isdefined( array ) || !IsArray( array ) )
	{
		return;
	}

	if( !isValidString( token ) )
	{
		return;
	}

	return StrTok( array, token );
}

function GetArraySize( array )
{
	if( !isValidArray( array ) )
	{
		return 0;
	}

	return array.size;
}