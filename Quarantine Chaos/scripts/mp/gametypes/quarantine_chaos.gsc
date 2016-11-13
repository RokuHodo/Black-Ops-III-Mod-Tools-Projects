//native files
#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\gameobjects_shared;
#using scripts\shared\hud_message_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\math_shared;
#using scripts\shared\util_shared;

#using scripts\shared\bots\_bot;

#using scripts\mp\_teamops;
#using scripts\mp\_util;
#using scripts\mp\gametypes\_globallogic;
#using scripts\mp\gametypes\_globallogic_audio;
#using scripts\mp\gametypes\_globallogic_score;
#using scripts\mp\gametypes\_globallogic_spawn;
#using scripts\mp\gametypes\_loadout;
#using scripts\mp\gametypes\_spawning;
#using scripts\mp\gametypes\_spawnlogic;
#using scripts\mp\killstreaks\_killstreaks;
#using scripts\mp\teams\_teams;

#insert scripts\shared\shared.gsh;

//custom files
#using scripts\shared\mod_util;

#using scripts\mp\gametypes\quarantine_chaos_dev;
#using scripts\mp\gametypes\quarantine_chaos_loadout;
#using scripts\mp\gametypes\quarantine_chaos_shop;
#using scripts\mp\gametypes\quarantine_chaos_shop_hud;

//start menu
#precache( "menu", MENU_START_MENU );

//team names
#precache( "string", "QC_HUMAN" );
#precache( "string", "QC_ZOMBIE" );
#precache( "string", "QC_TEAM_HUMANS" );
#precache( "string", "QC_TEAM_ZOMBIES" );

//objective text
#precache( "string", "QC_OBJECTIVES" );
#precache( "string", "QC_OBJECTIVES_SCORE" );
#precache( "string", "QC_OBJECTIVES_HINT_HUMANS" );
#precache( "string", "QC_OBJECTIVES_HINT_ZOMBIES" );

//round end and game over text text
#precache( "string", "QC_HUMANS_ELIMINATED" );
#precache( "string", "QC_ZOMBIES_ELIMINATED" );
#precache( "string", "QC_HUMANS_DESTROYED" );
#precache( "string", "QC_ZOMBIES_DESTROYED" );

//timer strings
#precache( "string", "QC_WAITING_FOR_MORE_HUMANS" );
#precache( "string", "QC_ALPHA_ZOMBIE_COUNTDOWN" );

//last human alive
#precache( "material", "compass_waypoint_target" );

function main()
{
	globallogic::init();

	util::registerRoundSwitch( 0, 9 );
	util::registerTimeLimit( 0, 1440 );
	util::registerscoreLimit( 0, 50000 );
	util::registerRoundLimit( 0, 10 );
	util::registerRoundWinLimit( 0, 10 );
	util::registerNumLives( 0, 100 );	

	globallogic::registerFriendlyFireDelay( level.gameType, 15, 0, 1440 );

	level.teamBased = true;
	level.overrideTeamScore = true;

	level.onStartGameType = &Callback_onStartGameType;
	level.onSpawnPlayer = &Callback_onPlayerSpawn;
	level.onRoundEndGame = &Callback_onRoundEndGame;
	level.onRoundSwitch = &Callback_onRoundSwitch;
	level.onPlayerKilled = &Callback_onPlayerKilled;

	level.giveCustomLoadout = &loadout::GiveStartingLoadout;

	callback::on_connect( &Callback_onPlayerConnect );
	callback::on_disconnect( &Callback_onPlayerDisconnect);

	gameobjects::register_allowed_gameobject( level.gameType );

	globallogic_audio::set_leader_gametype_dialog( "", "", "gameBoost", "gameBoost" );
	globallogic::setvisiblescoreboardcolumns( "score", "kills", "deaths", "assists", "kdratio" );
}

/* -------------------------------------------------------------------------------------

	Section:		Settings
	Description:	Global settings used to change how the game can be played.

	Subsections:	1)	Game Settings
					2) 	Player Settings
					3)	Hud Settings

------------------------------------------------------------------------------------- */

/* *************************************************************************************

	Subsection:		Game Settings
	Description:	Settings at the server level that affect every player.

************************************************************************************* */

function GameSettings()
{
	level.last_human_announced = false;
	level.alpha_zombie_picked = false;

	//determined by the game, not me
	level.max_gun_attachments = 8;

	//minimum amount of humans needed to start the game
	minimum_humans_required = GetDvarInt( "minimum_humans_required" );
	level.min_humans_required = ( util::isValidInt( minimum_humans_required ) && minimum_humans_required > 0 ? minimum_humans_required : 4 );
	
	//time until alpha zombie is picked after the pre-match period
	alpha_countdown_time = GetDvarInt( "alpha_countdown_time" );
	level.alpha_countdown_time = ( util::isValidInt( alpha_countdown_time ) && alpha_countdown_time > 0 ? alpha_countdown_time : 60 );

	//time after the alpha countdown starts to start the map transition, must be <= alpha_countdown_time
	map_transition_time = GetDvarInt( "map_transition_time" );
	level.map_transition_time = ( util::isValidInt( map_transition_time ) && map_transition_time > 0 && map_transition_time <= GetAlphaCountdownTime() ? map_transition_time : GetAlphaCountdownTime() );

	//the duration that the map transition effects take to complete, must be <= alpha_countdown_time - map_transition_time
	map_transition_duration = GetDvarInt( "map_transition_duration" );
	difference = GetAlphaCountdownTime() - GetMapTransitionTime();
	level.map_transition_duration = ( util::isValidInt( map_transition_duration ) && map_transition_duration > 0 && map_transition_duration <= difference ? map_transition_duration : difference );

	level.max_health_limit = [];

	//max health for zombies
	map_health = GetDvarInt( "max_health_limit_zombies" );
	level.max_health_limit[ "axis" ] = ( util::isValidInt( map_health ) && map_health > 0 ? map_health : GetGametypeSetting( "playerMaxHealth" ) );

	//max health for humans
	map_health = GetDvarInt( "max_health_limit_humans" );
	level.max_health_limit[ "allies" ] = ( util::isValidInt( map_health ) && map_health > 0 ? map_health : GetGametypeSetting( "playerMaxHealth" ) );

	//allow weapon upgrades?
	allow_weapon_upgrade = GetDvarInt( "allow_weapon_upgrade" );
	level.allow_weapon_upgrade = ( util::isValidInt( allow_weapon_upgrade ) && allow_weapon_upgrade == 1 ? true : false );

	//allow attachment upgrades?
	allow_attachment_upgrade = GetDvarInt( "allow_attachment_upgrade" );
	level.allow_attachment_upgrade = ( util::isValidInt( allow_attachment_upgrade ) && allow_attachment_upgrade == 1 ? true : false );

	//allow power slide, double jump, jetpack, and wall running
	allow_enhanced_movement = GetDvarInt( "allow_enhanced_movement" );
	level.allow_enhanced_movement = ( util::isValidInt( allow_enhanced_movement ) && allow_enhanced_movement == 1 ? true : false );	

	level.momentum_team = "allies";
}

function GetMaxAttachmentsAllowed()
{
	return level.max_gun_attachments;
}

function GetHumansRequired()
{
	return level.min_humans_required;
}

function GetAlphaCountdownTime()
{
	return level.alpha_countdown_time;
}

//TODO: implement the map transition effects
function GetMapTransitionTime()
{
	return level.map_transition_time;
}

function GetMapTransitionDuration()
{
	return level.map_transition_duration;
}

function GetMaxHealthLimit( team )
{
	if( !util::isValidteam( team ) )
	{
		return GetGametypeSetting( "playerMaxHealth" );
	}

	return level.max_health_limit[ team ];
}

function WeaponUpgradesAllowed()
{
	return level.allow_weapon_upgrade;
}

function AttachmentUpgradesAllowed()
{
	return level.allow_weapon_upgrade;
}

function EnhancedMovementAllowed()
{
	return level.allow_enhanced_movement;
}

/* *************************************************************************************

	Subsection:		Player Settings
	Description:	Settings that are player specific and get reset at the begining of each round.

************************************************************************************* */

function PlayerSettings()
{
	self.hud_system = [];
	self.loadout_starting = [];
	
	self.just_connected = true;
	self.play_spawn_message = true;	
	self.is_alpha_zombie = false;

	self.maxhealth_override = GetGametypeSetting( "playerMaxHealth" );
	self.maxhealth = self.maxhealth_override;
	self.health = self.maxhealth;

	self shop::ResetChash();
}

function GetMaxHealth()
{
	return Int( self.maxhealth_override );
}

function SetMaxHealth( value )
{
	self.maxhealth_override = Int( value );
	self.maxhealth = self.maxhealth_override;
	self.health = self.maxhealth;
}

/* *************************************************************************************

	Subsection:		Hud Settings
	Description:	Settings to ensure that the huds are drawn in the proper order.

************************************************************************************* */

function HudSettings()
{
	//so huds are drawn properly
	level.sort = SpawnStruct();
	level.sort.timer = 3;
	level.sort.string = 2;
	level.sort.shader = 1;
}

/* -------------------------------------------------------------------------------------

	Section:		Callbacks
	Description:	Callbacks used to manage the game mode and the game logic.
					Sorted in the order they would be called from the start of the game.

------------------------------------------------------------------------------------- */

function Callback_onStartGameType()
{
	SetDvar( "ui_gametype", "Quarantine Chaos");

	SetClientNameMode( "auto_change" );

	if ( !isdefined( game[ "switchedsides" ] ) )
	{		
		game[ "switchedsides" ] = false;
	}

	if ( game[ "switchedsides" ] )
	{
		attackers_old = game[ "attackers" ];
		defenders_old = game[ "defenders" ];

		game[ "attackers" ] = defenders_old;
		game[ "defenders" ] = attackers_old;
	}
	
	level.displayRoundEndText = false;

	spawning::create_map_placed_influencers();
	
	level.spawnMins = ( 0, 0, 0 );	
	level.spawnMaxs = ( 0, 0, 0 );

	//handled manually for now with custom text
	util::setObjectiveHintText( "axis", &"QC_OBJECTIVES_HINT_ZOMBIES" );
	util::setObjectiveHintText( "allies", &"QC_OBJECTIVES_HINT_HUMANS" );

	foreach( team in level.teams )
	{
		util::setObjectiveText( team, &"QC_OBJECTIVES" );
		util::setObjectiveScoreText( team, &"QC_OBJECTIVES_SCORE" );
		
		spawnlogic::add_spawn_points( team, "mp_tdm_spawn" );		
		spawnlogic::place_spawn_points( spawning::getTDMStartSpawnName( team ) );
	}

	spawning::updateAllSpawnPoints();
	
	level.spawn_start = [];
	
	foreach( team in level.teams )
	{
		level.spawn_start[ team ] =  spawnlogic::get_spawnpoint_array( spawning::getTDMStartSpawnName(team) );
	}

	level.mapCenter = math::find_box_center( level.spawnMins, level.spawnMaxs );
	SetMapCenter( level.mapCenter );

	spawnpoint = spawnlogic::get_random_intermission_point();
	SetDemoIntermissionPoint( spawnpoint.origin, spawnpoint.angles );

	level thread Callback_onScoreCloseMusic();

	if ( !util::isOneRound() )
	{
		level.displayRoundEndText = true;
		
		if( level.scoreRoundWinBased )
		{
			globallogic_score::resetTeamScores();
		}
	}
	
	level GameSettings();
	level HudSettings();

	level thread loadout::BuildPerks();
	level thread loadout::BuildWeapons();

	level thread StartCountdown();
}

function Callback_onPlayerConnect()
{
	if( !EnhancedMovementAllowed() )
	{
		self AllowSlide( false );
		self AllowWallRun( false );
		self AllowDoubleJump( false );
	}

	self PlayerSettings();

	//generate what guns the player will get
	self loadout::GenerateStartingLoadout( "axis" );
	self loadout::GenerateStartingLoadout( "allies" );

	//must be called after generating the loadouts
	self shop::BuildShops();

	team = ( level.alpha_zombie_picked ? "axis" : "allies" );
	ChangeTeam( team, false );

	if( level.alpha_zombie_picked )
	{
		self CheckMomentumShift();
	}
	else if( level.countdown_timer.started )
	{
		if( !level.countdown_timer.running && GetPlayers( "allies" ).size >= level.min_humans_required )
		{
			[[ level.countdown_timer ]]->Start();
		}
	}
}

function Callback_onPlayerDisconnect()
{
	if( level.alpha_zombie_picked )
	{
		self CheckMomentumShift();

		level CheckEndGameCondition();
	}
	else if( level.countdown_timer.started )
	{
		//GetPlayers() doesn't work here, gives a different size than count_players for some reason
		if( level.countdown_timer.running && teams::count_players()[ "allies" ] < level.min_humans_required )
		{
			[[ level.countdown_timer ]]->Pause();
		}
	}	
}

function Callback_onPlayerSpawn( predicted_spawn )
{
	self.usingObj = undefined;

	if ( level.useStartSpawns && !level.inGracePeriod && !level.playerQueuedRespawn )
	{
		level.useStartSpawns = false;
	}

	self thread shop::DrawHuds();	
	self thread dev::WatchBotButtons();

	max_health = GetMaxHealth();
	SetMaxHealth( max_health );

	//TODO: spawn message icons
	if( self.play_spawn_message )
	{
		sound = "qc_zombie_laugh";

		if( self isZombie() )
		{
			if( util:: )
			title = ( self.just_connected ? &"QC_TEAM_ZOMBIES" : &"QC_ZOMBIE" );			
			util::PlayMessage( title, &"QC_OBJECTIVES_HINT_ZOMBIES", undefined, undefined, undefined, 5, "qc_zombie_laugh" );
		}
		else
		{
			title = ( self.just_connected ? &"QC_TEAM_HUMANS" : &"QC_HUMAN" );
			sub_title = ( self.just_connected ? undefined : &"QC_OBJECTIVES_HINT_HUMANS" );
			util::PlayMessage( title, sub_title, undefined, undefined, undefined, 5, "qc_intro_laugh" );			
		}
		
		self.play_spawn_message = false;
	}

	self.just_connected = false;

	spawning::onSpawnPlayer( predicted_spawn );	
}

function Callback_onRoundSwitch()
{
	game[ "switchedsides" ] = !game[ "switchedsides" ];

	index = RandomInt( 2 );
	level thread util::PlaySoundOnHost( "qc_round_over_" + index );

	//give the players a new loadout every round to keep things interesting
	players = GetPlayers();
	foreach( player in players )
	{
		player PlayerSettings();

		player loadout::GenerateStartingLoadout( "axis" );
		player loadout::GenerateStartingLoadout( "allies" );

		player shop::BuildShops();
	}

	foreach( team in level.teams )
	{
		[[ level._setTeamScore ]]( team, game[ "roundswon" ][ team ] );
	}
}

function Callback_onRoundEndGame( roundWinner )
{
	foreach( team in level.teams )
	{
		[[ level._setTeamScore ]]( team, game[ "roundswon" ][ team ] );
	}

	//get the winner of the entire game
	winner = [[ level.determineWinner ]]();

	//override the end game sub text
	level.endReasonText = GetEndReasonText( winner );

	index = RandomInt( 4 );
	level thread util::PlaySoundOnHost( "qc_game_over_" + index );

	return winner;
}

function Callback_onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	//doesn't matter if the player dies before the game starts
	if( !level.alpha_zombie_picked )
	{
		return;	
	}

	if( !self isZombie() && level.alpha_zombie_picked )
	{
		self ChangeTeam( "axis" );	
	}

	players = GetPlayers();
	array::thread_all( players, &shop::RefreshCash, attacker );

	self CheckMomentumShift();

	level CheckEndGameCondition();
}

function Callback_onScoreCloseMusic()
{
	teamScores = [];

	while( !level.gameEnded )
	{
		score_limit = level.scoreLimit;

		top_score = 0;
		runner_up_score = 0;

		foreach( team in level.teams )
		{
			score = [[ level._getTeamScore ]]( team );

			if ( score > top_score )
			{
				runner_up_score = top_score;
				top_score = score;
			}
			else if ( score > runner_up_score )
			{
				runner_up_score = score;
			}
		}

		if( top_score >= score_limit * 0.5 )
		{
			level notify( "sndMusicHalfway" );

			return;
		}

		wait( 1 );
	}
}

/* -------------------------------------------------------------------------------------

	Section:		Game Logic
	Description:	The functions that add in game logic in addition to the callbacks.

------------------------------------------------------------------------------------- */

function StartCountdown()
{
	time = GetAlphaCountdownTime();

	level.countdown_timer = new PausableTimer();	

	//timer 
	[[ level.countdown_timer ]]->SetTimerProperties(	1,								//slpha
														1.5,							//font scale
														"LEFT",							//align point
														"LEFT",							//align relative
														10,								//x
														0,								//y
														time,							//time
														&"QC_WAITING_FOR_MORE_HUMANS",	//label - paused
														&"QC_ALPHA_ZOMBIE_COUNTDOWN" );	//label - running

	//offsets between the timer and the shader
	[[ level.countdown_timer ]]->SetHudOffset( 	-5,										//x offset
												 0 );									//y offset

	//background shader
	[[ level.countdown_timer ]]->SetBackgroundProperties(	0.5,						//alpha
															"white",					//shader
															170,						//width - paused
															160,						//width - running
															( 0, 0, 0 ) );				//color

	[[ level.countdown_timer ]]->AddNotify( "play_alpha_pick_sound", 5, level );
	level thread util::PlaySoundOnNotify( "qc_lottery_laugh", "play_alpha_pick_sound" );

	level waittill( "prematch_over" );

	[[ level.countdown_timer ]]->CreateTimer();
	[[ level.countdown_timer ]]->CreateBackground();

	//wait to start the timer until a certain number of poeople are in the game
	while( GetPlayers( "allies" ).size < level.min_humans_required )
	{
		WAIT_SERVER_FRAME;
	}
	
	[[ level.countdown_timer ]]->Start();
	level.countdown_timer.started = true;

	level waittill( "countdown_complete" );

	//TODO: r_lightTweakSunLight no longer exists, need to find another way to change the map lighting 
	//level thread util::ChangeDvarOverTime( "r_lightTweakSunLight", 0, GetMapTransitionDuration() );

	level thread PickAlphaZombie();
}

function PickAlphaZombie()
{
	players = GetPlayers();
	zombie = players[ 0 ];// array::random( players );
	zombie ChangeTeam( "axis", true );

	level.alpha_zombie_picked = true;
}

function ChangeTeam( team, is_alpha_zombie = false )
{
	if( !util::isValidTeam( team ) )
	{
		return;
	}

	//changing to the same team, do nothing
	if( util::CompareStrings( self.pers[ "team" ], team ) )
	{
		return;
	}

	self teams::change( team );

	self.play_spawn_message = true;
	self.is_alpha_zombie = is_alpha_zombie;

	//only valid on connecting
	if( self.just_connected )
	{
		self [[ level.teamMenu ]]( team );
	}

	if( util::CompareStrings( team, "axis" ) )
	{
		self PlaySound( "qc_human_died" );

		self shop::DestroyShop();
		self shop::ResetChash();
	}

	self ClearPerks();

	//force close the menus
	self CloseMenu( MENU_START_MENU );
	self CloseMenu( MENU_CHANGE_CLASS );
}

function isZombie()
{
	team = self.pers[ "team" ];

	if( !util::isValidTeam( team ) )
	{
		return false;
	}

	return util::CompareStrings( team, "axis", true );
}

function CheckMomentumShift()
{
	players_left = teams::count_players();

	if( players_left[ "allies" ] == players_left[ "axis" ] )
	{
		return;
	}

	momentum_team = ( players_left[ "allies" ] > players_left[ "axis" ] ? "allies" : "axis" );

	if( !util::CompareStrings( level.momentum_team, momentum_team, true ) )
	{
		level.momentum_team = momentum_team;

		self PlaySoundToTeam( "qc_blitz_cheer", momentum_team );
	}
}

function CheckEndGameCondition()
{
	players_left = teams::count_players();

	winner = "";
	reason = "";	

	//end game conditions 
	if( players_left[ "allies" ] == 0 )
	{
		reason = &"QC_HUMANS_ELIMINATED";
		winner = teams::getEnemyTeam( "allies" );
	}
	else if( players_left[ "axis" ] == 0 )
	{
		winner = teams::getEnemyTeam( "axis" );
		reason = &"QC_ZOMBIES_ELIMINATED";
	}
	else if( players_left[ "allies" ] == 1 )
	{
		if( level.last_human_announced )
		{
			return;
		}

		foreach( player in level.players )
		{
			if( util::CompareStrings( player.pers[ "team" ], "allies" ) )
			{
				level.last_human_announced = true;

				level.last_human_alive = new ServerWaypoint();
				[[ level.last_human_alive ]]->SetIcon( "compass_waypoint_target" );
				[[ level.last_human_alive ]]->SetVisibleTeam( "axis" );
				[[ level.last_human_alive ]]->DrawWaypoint( player.origin + ( 0, 0, 70 ) );
				[[ level.last_human_alive ]]->FollowEntity( player );				

				break;
			}
		}		
	}

	if( util::isValidString( winner ) )
	{
		level thread shop::DestroyShop_AllPlayers();
		level thread globallogic::endGame( winner, reason );
	}
}

function GetEndReasonText( winner )
{
	reason = undefined;

	//only the score limit should ever be reached, but cover all the bases 
	if ( util::hitRoundLimit() || util::hitRoundWinLimit() || util::hitScoreLimit() ||util::hitRoundScoreLimit() )
	{
		switch( winner )
		{
			case "axis":
			{
				reason = &"QC_HUMANS_DESTROYED";
			}
			break;
			case "allies":
			{
				reason = &"QC_ZOMBIES_DESTROYED";
			}
			break;
			default:
			{

			}
			break;
		}
	}

	return reason;
}

/* -------------------------------------------------------------------------------------

	Section:		Utility Functions
	Description:	Utility functions that are specific to the game mode.
					Not enough yet to make a file on it's own.

------------------------------------------------------------------------------------- */

function GetTeamAlias( team )
{
	alias = team;

	if( !util::isValidTeam( team ) )
	{
		return alias;
	}

	switch( team )
	{
		case "allies":
		{
			alias = "humans";
		}
		break;

		case "axis":
		{
			alias = "zombies";
		}
		break;

		default:
		{

		}
		break;
	}

	return alias;
}

