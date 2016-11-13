//native files
#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\hud_message_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\math_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#using scripts\mp\_util;
#insert scripts\shared\abilities\_ability_util.gsh;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\statstable_shared.gsh;

#namespace util;

#define ATTACHMENT_TABLE "gamedata/weapons/common/attachmentTable.csv"

/* -------------------------------------------------------------------------------------

	Section:		Threading
	Description:	Functions that aid in anything team based.					

------------------------------------------------------------------------------------- */

function ThreadOnNotify( flag, func, parameter_1 = undefined,  parameter_2 = undefined, parameter_2 = undefined, parameter_3 = undefined, parameter_4 = undefined, parameter_5 = undefined, parameter_6 = undefined, parameter_7 = undefined, parameter_8 = undefined, parameter_9 = undefined,  parameter_10 = undefined )
{
	if( !isValidString( flag ) )	
	{
		return;
	}

	if( !isValidFunction( func ) )
	{
		return;
	}

	self waittill( flag );

	if( isdefined( parameter_10 ) )
	{
		self thread [[ func ]]( parameter_1,  parameter_2, parameter_2, parameter_3, parameter_4, parameter_5, parameter_6, parameter_7, parameter_8, parameter_9,  parameter_10 );
	}
	else if( isdefined( parameter_9 ) )
	{
		self thread [[ func ]]( parameter_1,  parameter_2, parameter_2, parameter_3, parameter_4, parameter_5, parameter_6, parameter_7, parameter_8, parameter_9 );
	}
	else if( isdefined( parameter_8 ) )
	{
		self thread [[ func ]]( parameter_1,  parameter_2, parameter_2, parameter_3, parameter_4, parameter_5, parameter_6, parameter_7, parameter_8 );
	}
	else if( isdefined( parameter_7 ) )
	{
		self thread [[ func ]]( parameter_1,  parameter_2, parameter_2, parameter_3, parameter_4, parameter_5, parameter_6, parameter_7 );
	}
	else if( isdefined( parameter_6 ) )
	{
		self thread [[ func ]]( parameter_1,  parameter_2, parameter_2, parameter_3, parameter_4, parameter_5, parameter_6 );
	}
	else if( isdefined( parameter_5 ) )
	{
		self thread [[ func ]]( parameter_1,  parameter_2, parameter_2, parameter_3, parameter_4, parameter_5 );
	}
	else if( isdefined( parameter_4 ) )
	{
		self thread [[ func ]]( parameter_1,  parameter_2, parameter_2, parameter_3, parameter_4 );
	}
	else if( isdefined( parameter_3 ) )
	{
		self thread [[ func ]]( parameter_1,  parameter_2, parameter_2, parameter_3);	
	}
	else if( isdefined( parameter_2 ) )
	{
		self thread [[ func ]]( parameter_1,  parameter_2, parameter_2 );
	}
	else if( isdefined( parameter_1 ) )
	{
		self thread [[ func ]]( parameter_1,  parameter_2 );
	}
	else
	{
		self thread [[ func ]]();
	}
}

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

			return valid;
		}
	}

	return valid;
}

/* -------------------------------------------------------------------------------------

	Section:		Dvars 
	Description:	Wrappers that add more flexibility to Dvars

------------------------------------------------------------------------------------- */

function ChangeDvarOverTime( dvar, value, time )
{
	if( !isValidString( dvar ) )
	{
		return;
	}

	if( !StrIsNumber( value ) || !StrIsNumber( time ) )
	{
		return;
	}

	value_current = GetDvarFloat( dvar );

	//update once per server frame
	cycles = Int( time / 0.05 );
	increment = ( value - value_current ) / cycles;

	for( index = 0; index < cycles; index++ )
	{
		value_current += increment;
		SetDvar( dvar, value_current );

		IPrintLn( dvar + " set to  " + GetDvarFloat( dvar ) );

		WAIT_SERVER_FRAME;
	}

	if( GetDvarFloat( dvar ) != value )
	{
		SetDvar( dvar, value );
	}

	IPrintLn( dvar + " set to  " + GetDvarFloat( dvar ) );
}

/* -------------------------------------------------------------------------------------

	Section:		Sound
	Description:	Functions that amake working with sounds a bit easier.					

------------------------------------------------------------------------------------- */

function PlaySoundOnHost( alias )
{
	if( !isValidString( alias ) )
	{
		return;
	}

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

function PlaySoundOnNotify( alias, flag )
{
	if( !isValidString( alias ) || !isValidString( flag ) )
	{
		return;
	}

	self waittill( flag );

	PlaySoundOnHost( alias );
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

function StartsWith( str, sub_str, ignore_case = false )
{
	result = false;

	if( !isValidString( str ) || !isValidString( sub_str ) )
	{
		return result;
	}

	if( sub_str.size > str.size )
	{
		return result;
	}

	result = CompareStrings( GetSubStr( str, 0, sub_str.size ), sub_str, ignore_case );

	return result;
}

function StartsWithVowel( str )
{
	result = false;

	if( !isValidString( str ) )
	{
		return result;
	}

	vowels = [];

	ARRAY_ADD( vowels, "a" );
	ARRAY_ADD( vowels, "e" );
	ARRAY_ADD( vowels, "i" );
	ARRAY_ADD( vowels, "o" );
	ARRAY_ADD( vowels, "u" );

	foreach( vowel in vowels )
	{
		if( StartsWith( str, vowel, true ) )
		{
			result = true;

			return result;
		}
	}

	return result;
}

function IndexOf( str, sub_str, start = 0 )
{
	_index = -1;

	//ony or both of the strings are null
	if( !isValidString( str ) || !isValidString( sub_str ) )
	{
		//IPrintLn( "^1The string and/or sub string is null" );

		return _index;
	}

	//sub string doesn't exist in the string
	if( !SearchString( str, sub_str, true ) )
	{
		//IPrintLn( "^1The sub string (" + sub_str + ") does not exist in the string (" + str + ")" );

		return _index;
	}

	if( start > str.size - 1 )
	{
		//IPrintLn( "^1The starting index (" + start + ") is larger than the number of indices in the string (" + ( str.size - 1 ) + ")" );

		return _index;
	}

	if( start + sub_str.size - 1 > str.size - 1 )
	{
		//IPrintLn( "^1The ending index of the first sub string search (" + ( start + sub_str.size - 1 ) + ") would be out of bounds of the last index of the string (" + ( str.size - 1 ) + ")" );

		return _index;
	}	

	//the sub string is really a char, easy mode
	if( sub_str.size == 1 )
	{
		for( index = start; index < str.size; index++ )
		{
			if( CompareStrings( str[ index ], sub_str ) )
			{
				//IPrintLn( "^2The character (" + sub_str + ") was found at index (" + index + ")" );

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

				//IPrintLn( "^2The sub string (" + sub_str + ") was found at index (" + index + ")" );

				return index;
			}
		}
	}

	//IPrintLn( "^1Nothing was found" );

	return _index;
}

/* -------------------------------------------------------------------------------------

	Section:		Huds
	Description:	Functions that draw, delete, manipulatem and return data on huds.

	Subsections		1) Drawing
					2) Deleting
					3) Get/Sets

------------------------------------------------------------------------------------- */

/* *************************************************************************************

	Subsection:		Drawing
	Description:	Draws various different types of huds

************************************************************************************* */

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

function PlayServerMessage( team = undefined, title, sub_text_1 = undefined, sub_text_2 = undefined, icon = undefined, glow_color = undefined, duration = 7, sound = undefined )
{
	players = GetPlayers();

	foreach( player in players )
	{
		if( !isValidTeam( team ) || ( isValidTeam( team ) && CompareStrings( player.pers[ "team" ], team ) ) )
		{
			player thread PlayMessage( title, sub_text_1, sub_text_2, icon, glow_color, duration, sound );
		}
	}
}

function PlayMessage( title, sub_text_1 = undefined, sub_text_2 = undefined, icon = undefined, glow_color = undefined, duration = 7, sound = undefined )
{ 
	message = SpawnStruct();

	message.titleText = title;
	message.notifyText = sub_text_1;
	message.notifyText2 = sub_text_2;
	message.iconName = icon;
	message.glowColor = glow_color;
	message.duration = duration;
	message.sound = sound;

	hud_message::notifyMessage( message );
}

function CreateDisplay( alpha = 1.0, fontscale = 1.0, point = "CENTER", relative = "CENTER", x = 0, y = 0, value = undefined, label = "" )
{
	display = hud::createFontString( "default", fontscale );
	display hud::setPoint( point, relative, x, y );
	display.sort = level.sort.string;
	display.alpha = alpha;
	display.label = label;

	if( isValidInt( value ) || isValidFloat( value ) )
	{
		display SetValue( value );
	}
	else if( isValidString( MakeLocalizedString( value ) ) )
	{
		display SetText( value );
	}	

	return display;
}

function CreateServerTimer( alpha = 0, font_scale = 1.0, point = "CENTER", relative = "CENTER", x = 0, y = 0, time = 0.0, label = "" )
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

class ServerWaypoint
{
	var icon;
	var team;

	var waypoint;

	constructor()
	{
		icon = "";
		team = "";

		waypoint = undefined;
	}	

	destructor()
	{

	}

	function SetIcon( _icon )
	{
		icon = _icon;
	}

	function SetVisibleTeam( _team )
	{
		team = _team;
	}

	function DrawWaypoint( origin )
	{
		if( !util::isValidString( icon ) )
		{
			return;
		}

		waypoint = undefined;

		if( util::isValidTeam( team ) )
		{
			waypoint = NewTeamHudElem( team );
		}
		else
		{
			waypoint = NewHudElem();	
		}

		waypoint.x = origin[ 0 ];
		waypoint.y = origin[ 1 ];
		waypoint.z = origin[ 2 ];

		waypoint SetShader( icon );
		waypoint SetWayPoint( true, icon );

		level thread util::DestroyOnNotify( waypoint, "game_ended" );
	}

	function FollowEntity( ent )
	{
		level endon( "game_ended" );

		if( !isdefined( waypoint ) || !IsEntity( ent ) )
		{
			return;
		}

		//doesn't work :(
		//point = Spawn( "script_origin", ent.origin );
		//point EnableLinkTo();

		//waypoint LinkTo( point );

		while( true )
		{
			//doesn't seem to do anything
			//waypoint MoveOverTime( 0.05 );

			waypoint.x = ent.origin[ 0 ];
			waypoint.y = ent.origin[ 1 ];
			waypoint.z = ent.origin[ 2 ] + 70;

			WAIT_CLIENT_FRAME;
		}
	}
}



function CreateServerShader( alpha = 1.0, shader = "white", width = 0, height = 0, align = "CENTER", relative = "CENTER", x = 0, y = 0, color = ( 1, 1, 1 ), team = "" )
{
	server_shader = _CreateShader( "server",  alpha, shader, width, height, align, relative, x, y, color, team );

	return server_shader;
}

function CreateShader( alpha = 1.0, shader = "white", width = 0, height = 0, align = "CENTER", relative = "CENTER", x = 0, y = 0, color = ( 1, 1, 1 ) )
{	
	client_shader = _CreateShader( "client", alpha, shader, width, height, align, relative, x, y, color );

	return client_shader;
}

function _CreateShader( shader_type, alpha, shader, width, height, align, relative, x, y, color, team )
{
	_shader = undefined;

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

	var notifies;

	constructor()
	{
		//initialize everything
		started = false;
		running = false;

		notifies = [];

		time_data = SpawnStruct();
		time_data.left = 0;
		time_data.stop = 0;
		time_data.start = 0;

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

		timer = util::CreateServerTimer( prop.alpha, prop.font_scale, prop.point, prop.relative, prop.x, prop.y, undefined, GetLabel() );

		//bg can be destroyed either when it "refreshes" or time expires
		self thread util::DestroyOnNotify( timer, "destroy_pausable_all" );
		self thread util::DestroyOnNotify( timer, "destroy_pausable_timer" );
	}

	function AddNotify( flag, time, obj = undefined )
	{
		if( !util::isValidString( flag ) )
		{
			return;
		}

		if( !StrIsNumber( time ) )
		{
			return;
		}

		element = SpawnStruct();
		element.time = time;
		element.flag = flag;
		element.obj = obj;

		if( !array::contains( notifies, element ) )
		{
			ARRAY_ADD( notifies, element );			
		}
	}

	function CreateBackground()
	{
		prop = properties[ "background" ];

		background = util::CreateServerShader( prop.alpha, prop.shader, GetBackgroundWidth(), prop.height, prop.point, prop.relative, prop.x, prop.y, prop.color );

		//bg can be destroyed either manualls with "destroy_pausable_background" or when time expires
		self thread util::DestroyOnNotify( background, "destroy_pausable_all" );
		self thread util::DestroyOnNotify( background, "destroy_pausable_background" );	
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

			thread RunNotifies( time_left );

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

	function RunNotifies( time )
	{
		if( util::GetArraySize( notifies ) == 0 )
		{
			return;
		}

		foreach( index, element in notifies )
		{
			//<= just in case if it's a server frame or two off 
			if( time <= element.time )
			{
				if( isdefined( element.obj ) )
				{
					element.obj notify( element.flag );
				}
				else
				{
					self notify( element.flag );
				}

				ArrayRemoveValue( notifies, element );
			}	
		}
	}
}

/* *************************************************************************************

	Subsection:		Destroys
	Description:	Handles destroying the huds.

************************************************************************************* */

function DestroyOnNotify_Array( huds, notification, keys_ignore = undefined )
{
	self endon( "disconnect" );

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

/* *************************************************************************************

	Subsection:		Get/Sets
	Description:	Gets or sets hud properties 

************************************************************************************* */

function GetFontHeight()
{
	return level.fontHeight;
}

function GetTextHeight( font_scale = 1.0 )
{
	font_height = GetFontHeight();

	if( isValidFloat( font_scale ) )
	{
		return font_scale * font_height;
	}

	return font_height;
}

/* -------------------------------------------------------------------------------------

	Section:		Buttons 
	Description:	Wrappers for button logic

------------------------------------------------------------------------------------- */

function isButtonPressed( button )
{
	pressed = false;

	switch( button )
	{
		case "+frag":
		{
			pressed = self FragButtonPressed();
		}
		break;

		case "+melee":
		{
			pressed = self MeleeButtonPressed();
		}
		break;

		case "+attack":
		{
			pressed = self AttackButtonPressed();
		}
		break;

		case "+use":
		case "+activate":		
		{
			pressed = self UseButtonPressed();
		}
		break;

		case "+speed_throw":
		{
			pressed = self AdsButtonPressed();
		}
		break;

		case "+smoke":
		{
			pressed = self SecondaryOffhandButtonPressed();
		}
		break;

		case "+actionslot 1":
		{
			pressed = self ActionSlotOneButtonPressed();
		}
		break;

		case "+actionslot 2":
		{
			pressed = self ActionSlotTwoButtonPressed();
		}
		break;

		case "+actionslot 3":
		{
			pressed = self ActionSlotThreeButtonPressed();
		}
		break;

		case "+actionslot 4":
		{
			pressed = self ActionSlotFourButtonPressed();
		}
		break;

		default:
		{

		}
		break;
	}

	return pressed;
}

/* -------------------------------------------------------------------------------------

	Section:		Weapons
	Description:	Wrappers and other useful functions for getting weapon information

	Subsections:	1) Boolean Checks
					2) Weapon handling
					3) Get/Sets

------------------------------------------------------------------------------------- */

/* *************************************************************************************

	Subsection:		Boolean Checks
	Description:	Various weapon checks.

************************************************************************************* */

function isValidWeapon( weapon )
{
	if( !isdefined( weapon ) )
	{
		return false;
	}

	if( weapon == level.weaponNone )
	{
		return false;
	}

	if( !weapon.isValid )
	{
		return false;
	}

	if( CompareStrings( weapon.name, "weapon_none", true ) )
	{
		return false;
	}

	return true;
}

function HasMaxAmmo( weapon )
{
	result = false;

	if( !isValidWeapon( weapon ) )
	{
		return result;
	}

	//need to aslo check the ammo clip because GetFractionMaxcAmmo doesn't update until you reload
	if( self GetFractionMaxAmmo( weapon ) == 1 && self GetWeaponAmmoClip( weapon ) == weapon.clipSize )
	{
		result = true;
	}

	return result;
}

function HasHeroWeapon()
{
	weapons = self GetWeaponsList( true );

	foreach( weapon in weapons )
	{
		if( weapon.isheroweapon || weapon.gadget_type == GADGET_TYPE_HERO_WEAPON )
		{
			return true;
		}
	}

	return false;
}

function GetHeroWeapon()
{
	hero_weapon = level.weaponNone;

	weapons = self GetWeaponsList( true );

	foreach( weapon in weapons )
	{
		if( weapon.isheroweapon || weapon.gadget_type == GADGET_TYPE_HERO_WEAPON )
		{
			hero_weapon = weapon;

			return hero_weapon;
		}
	}

	return hero_weapon;
}

/* *************************************************************************************

	Subsection:		Weapon handling
	Description:	Change and handle a players weapon lists.

************************************************************************************* */

function SwapWeaponsHeld( weapon_take, weapon_give, give_ammo = false )
{
	if( !isValidWeapon( weapon_take ) || !isValidWeapon( weapon_give ) )
	{
		return;
	}

	if( !self HasWeapon( weapon_take ) )
	{
		return;
	}

	self TakeWeapon( weapon_take );
	self GiveWeapon( weapon_give );

	if( give_ammo )
	{
		self GiveMaxAmmo( weapon_give );
	}
}

/* *************************************************************************************

	Subsection:		Get / Sets
	Description:	Returns various weapon data information.

************************************************************************************* */

function GetBaseWeapon( weapon )
{
	weapon_base = "";

	if( !isValidWeapon( weapon ) )
	{
		return weapon_base;
	}

	weapon_base = [[ level.get_base_weapon_param ]]( weapon );

	return weapon_base;
}

//i realize there is a GetWeaponOptic() function but I can't get it to work
function GetOpticOnWeapon( weapon )
{
	optic = "";

	if( !isValidWeapon( weapon ) )
	{
		return optic;
	}

	attachments = weapon.attachments;

	foreach( attachment in attachments )
	{
		group = GetAttachmentGroup( attachment );

		if( util::CompareStrings( group, "optic", true ) )
		{
			optic = attachment;

			return optic;
		}
	}

	return optic;
}

function GetAttachmentGroup( attachment )
{
	group = "";

	if( !isValidString( attachment ) )
	{
		return group;
	}

	row = TableLookupRowNum( ATTACHMENT_TABLE, STATS_TABLE_COL_REFERENCE, attachment );

	group = TableLookupColumnForRow( ATTACHMENT_TABLE, row, STATS_TABLE_COL_GROUP );

	return group;
}

function GetLocalizedWeaponName( weapon )
{
	name = "";

	if( !isValidWeapon( weapon ) )
	{
		return;
	}

	name = MakeLocalizedString( weapon.displayname );

	return name;
}

function GetLocalizedAttachmentName( attachment )
{
	name = "";

	if( !isValidString( attachment ) )
	{
		return name;
	}

	row = TableLookupRowNum( ATTACHMENT_TABLE, STATS_TABLE_COL_REFERENCE, attachment );
	
	name = MakeLocalizedString( TableLookupColumnForRow( ATTACHMENT_TABLE, row, STATS_TABLE_COL_NAME ) );

	return name;
}

//TODO: find a way to get the names of weapon classes by using tables
function GetWeaponClassName( weapon_class )
{
	name = "";

	if( !isValidString( weapon_class ) )
	{
		return name;
	}

	switch( weapon_class )
	{
		case "weapon_smg":
		{
			name = "submachine gun";
		}
		break;

		case "weapon_cqb":
		{
			name = "shotgun";
		}
		break;

		case "weapon_assault":
		{
			name = "assault rifle";
		}
		break;

		case "weapon_lmg":
		{
			name = "light machine gun";
		}
		break;

		case "weapon_special":
		{
			name = "special weapon";
		}
		break;

		case "weapon_knife":
		case "weapon_pistol":
		case "weapon_sniper":
		case "weapon_grenade":
		case "weapon_shotgun":
		case "weapon_launcher":
		case "weapon_explosive":
		{
			name = TextAfter( weapon_class, "_" );
		}
		break;

		default:
		{
			name = "another weapon";
		}
		break;
	}

	return name;
}

/* -------------------------------------------------------------------------------------

	Section:		Universal / Miscellaneous 
	Description:	These are "true" utility functions that can be applied to nearly anything.

	Sub Sections:	1) Boolean Checks
					2) Arrays
					3) Misc

------------------------------------------------------------------------------------- */


/* *************************************************************************************

	Sub Section:	Boolean Checks
	Description:	Perform comparison / validation checks.

************************************************************************************* */

function isValidFunction( func )
{
	if( !isdefined( func ) )
	{
		return false;
	}

	if( !IsFunctionPtr( func ) )
	{
		return false;
	}

	return true;
}

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

function SearchString( str, sub_str, ignore_case = false )
{
	valid = false;

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

function CompareStrings( string_1, string_2, ignore_case = false )
{
	valid = false;

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

function StringToarray( str, token )
{
	if( !isValidString( str ) || !isValidString( token ) )
	{
		return;
	}

	return StrTok( str, token );
}

function GetArraySize( array )
{
	if( !isValidArray( array ) )
	{
		return 0;
	}

	return array.size;
}

/* *************************************************************************************

	Subsection:		Misc
	Description:	Everything else that doesn't have a home.

************************************************************************************* */

function blank( parameter_1, parameter_2, parameter_3, parameter_4, parameter_5, parameter_6, parameter_7, parameter_8, parameter_9, parameter_10 )
{

}