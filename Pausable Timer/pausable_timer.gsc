#using scripts\shared\util_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\system_shared;
#using scripts\shared\math_shared;
#using scripts\shared\array_shared;

#using scripts\mp\_util;
#using scripts\mp\teams\_teams;

#insert scripts\shared\shared.gsh;

#namespace quarantine_chaos;

#precache( "string", "MOD_ALPHA_ZOMBIE_RELEASED_COUNTDOWN" );
#precache( "string", "MOD_WAITING_FOR_MORE_HUMANS" );

//example use case
function StartCountdown()
{	
	level.countdown_timer = new PausableTimer();

	//must be called before anything is drawn
	//set up everything before hand so things just need to be drawn 
	[[ level.countdown_timer ]]->SetHudOffset( -5, 0 );													
	[[ level.countdown_timer ]]->SetTimerProperties( 1, 1.5, "LEFT", "LEFT", 10, 0, 5, &"QC_WAITING_FOR_MORE_HUMANS", &"QC_ALPHA_ZOMBIE_COUNTDOWN" );
	[[ level.countdown_timer ]]->SetBackgroundProperties( 0.5, "white", 170, 160, ( 0, 0, 0 ) );

	level waittill( "prematch_over" );

	[[ level.countdown_timer ]]->CreateTimer();
	[[ level.countdown_timer ]]->CreateBackground();

	while( GetPlayers( "allies" ).size < level.min_humans_required )
	{
		WAIT_SERVER_FRAME;
	}
	
	[[ level.countdown_timer ]]->Start();
	level.countdown_timer.started = true;

	level waittill( "countdown_complete" );

	level thread PickAlphaZombie();
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