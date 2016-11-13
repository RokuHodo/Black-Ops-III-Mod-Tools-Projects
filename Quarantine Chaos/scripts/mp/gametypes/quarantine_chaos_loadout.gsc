//native files
#using scripts\shared\array_shared;
#using scripts\shared\math_shared;
#using scripts\shared\util_shared;

#using scripts\mp\_util;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\statstable_shared.gsh;

//custom files
#using scripts\shared\mod_util;

#namespace loadout;

/* -------------------------------------------------------------------------------------

	Section:		Weapon Building
	Description:	Builds the weapons that can be used by humans and zombies.			

------------------------------------------------------------------------------------- */

function BuildWeapons()
{
	//if everything is already built, don't do again
	if( util::isValidArray( level.weapons_available ) )
	{
		return;
	}	

	SetUpgradePath( "axis", "weapon_knife", "none" );

	SetUpgradePath( "allies", "weapon_pistol", "weapon_sniper" );
	SetUpgradePath( "allies", "weapon_smg", "weapon_lmg" );
	SetUpgradePath( "allies", "weapon_cqb", "weapon_assault" );

	BuildBlackList_Weapons();
	BuildBlackList_Attachments();

	level.weapons_available = [];
	level.weapons_available[ "axis" ] = [];
	level.weapons_available[ "allies" ] = [];

	weapons = [];

	for( index = 0; index < STATS_TABLE_MAX_ITEMS; index++ )
	{
		row = TableLookupRowNum( level.statsTableID, STATS_TABLE_COL_NUMBERING, index );
		
		if ( row < 0 )
		{
			continue;
		}

		weapon_type = TableLookupColumnForRow( level.statsTableID, row, STATS_TABLE_COL_GROUP );
		
		//only care about actual weapons
		if ( util::StartsWith( weapon_type, "weapon_" ) || util::StartsWith( weapon_type, "hero" ) )
		{
			reference = TableLookupColumnForRow( level.statsTableID, row, STATS_TABLE_COL_REFERENCE );				

			//check to see if it's a valid weapon
			if( !util::isValidString( reference ) )
			{
				continue;
			}

			weapon = GetWeapon( reference );

			if( !util::isValidWeapon( weapon ) )
			{
				continue;
			}

			//if the weapon type hasn't been found yet, create a new array
			if( !util::isValidArray( weapons[ weapon_type ] ) )
			{
				weapons[ weapon_type ] = [];			
			}

			weapon_index = weapons[ weapon_type ].size;

			//get the name and reference to the gun
			weapons[ weapon_type ][ weapon_index ] = SpawnStruct();
			weapons[ weapon_type ][ weapon_index ].name = MakeLocalizedString( TableLookupColumnForRow( level.statsTableID, row, STATS_TABLE_COL_NAME ) );
			weapons[ weapon_type ][ weapon_index ].reference = reference;
			weapons[ weapon_type ][ weapon_index ].type = weapon_type;
			weapons[ weapon_type ][ weapon_index ].weapon = weapon;

			attachments = util::StringToarray( TableLookupColumnForRow( level.statsTableID, row, STATS_TABLE_COL_ATTACHMENTS ), " " );

			//get all possible attachments for the gun
			weapons[ weapon_type ][ weapon_index ].attachments = [];
			weapons[ weapon_type ][ weapon_index ].attachments = BuildAttachmentData( attachments );
		}
	}	

	level.weapons_available[ "axis" ] = BuildWeaponsForTeam( "axis", weapons );
	level.weapons_available[ "allies" ] = BuildWeaponsForTeam( "allies", weapons );	
}

function BuildAttachmentData( attachments )
{
	data = [];

	if( !util::isValidArray( attachments ) )
	{
		return data;
	}

	foreach( attachment in attachments )
	{
		temp = SpawnStruct();
		temp.reference = attachment;
		temp.name = util::GetLocalizedAttachmentName( attachment );
		temp.group = util::GetAttachmentGroup( attachment );

		ARRAY_ADD( data, temp );
	}

	return data;
}

function BuildBlackList_Weapons()
{
	level.blacklist_weapons = [];	

	//blacklisted weapons for zombies
	level.blacklist_weapons[ "axis" ] = [];
	level.blacklist_weapons[ "axis" ][ "weapon_knife" ] = Array( "bowie_knife" );	//i don't know why this is in mp, but it is, and it breaks shit
	level.blacklist_weapons[ "axis" ][ "hero" ] = Array( "hero_minigun", "hero_lightninggun", "hero_gravityspikes", "hero_annihilator", "hero_pineapplegun", "hero_bowlauncher", "hero_chemicalgelgun", "hero_flamethrower" );

	//blacklisted weapons for humans
	level.blacklist_weapons[ "allies" ] = [];
	level.blacklist_weapons[ "allies" ][ "weapon_pistol" ] = Array( "pistol_standard_dw", "pistol_fullauto_dw", "pistol_burst_dw", "pistol_shotgun_dw", "pistol_energy", "weapon_null" );
	level.blacklist_weapons[ "allies" ][ "weapon_smg" ] = Array( "" );
	level.blacklist_weapons[ "allies" ][ "weapon_cqb" ] = Array( "shotgun_energy" );	
}

function GetBlackList_Weapons( team )
{
	blacklist = [];

	if( !util::isValidTeam( team ) )
	{
		return blacklist;
	}

	if( !util::isValidArray( level.blacklist_weapons[ team ] ) )
	{
		return blacklist;
	}

	blacklist = level.blacklist_weapons[ team ];

	return blacklist;
}

function BuildBlackList_Attachments()
{
	level.blacklist_attachments = [];	

	level.blacklist_attachments = ARRAY( "dw", "gmod0", "gmod1", "gmod2", "gmod3", "gmod4", "gmod5", "gmod6", "gmod7", "dualclip", "dynzoom", "gl", "is", "mms", "notracer", "stackfire" );
}

function GetBlackList_Attachments()
{
	blacklist = [];

	if( !util::isValidArray( level.blacklist_attachments ) )
	{
		return blacklist;
	}

	blacklist = level.blacklist_attachments;

	return blacklist;
}

function BuildWeaponsForTeam( team, weapons_master )
{
	weapons = [];
	weapons[ "starter" ] = [];
	weapons[ "upgrade" ] = [];

	if( !util::isValidTeam( team ) )
	{
		return weapons;
	}

	if( !util::isValidArray( weapons_master ) )
	{
		return weapons;
	}

	blacklist_weapons = [];	
	blacklist_weapons = GetBlackList_Weapons( team );

	types_starter = GetStarterTypes( team );

	foreach( type_starter in types_starter )
	{
		//starter weapons
		if( !util::isValidArray( weapons[ "starter" ][ type_starter ] ) )
		{
			weapons[ "starter" ][ type_starter ] = [];	
		}


		if( !util::isValidArray( weapons_master[ type_starter ] ) )
		{
			continue;
		}		

		weapons[ "starter" ][ type_starter ] = AddWeapons( team, type_starter, weapons_master, blacklist_weapons[ type_starter ] );

		//upgrade weapons
		type_upgrade = GetUpgradeType( team, type_starter );

		if( !util::isValidArray( weapons[ "upgrade" ][ type_upgrade ] ) )
		{
			weapons[ "upgrade" ][ type_upgrade ] = [];	
		}

		if( !util::isValidArray( weapons_master[ type_upgrade ] ) )
		{
			continue;
		}

		weapons[ "upgrade" ][ type_upgrade ] = AddWeapons( team, type_upgrade, weapons_master, blacklist_weapons[ type_upgrade ] );
	}

	return weapons;
}

function AddWeapons( team, type, weapons_master, blacklist_weapons )
{	
	weapons = [];

	if( !util::isValidTeam( team ) )
	{
		return weapons;
	}

	if( !util::isValidString( type ) )
	{
		return weapons;
	}

	if( !util::isValidArray( weapons_master ) || !util::isValidArray( weapons_master[ type ] ) )
	{
		return weapons;
	}

	foreach( weapon in weapons_master[ type ] )
	{
		//check to see if the weapon exists in the weapons blacklist
		if( util::isValidArray( blacklist_weapons ) )
		{
			if( array::contains( blacklist_weapons, weapon.reference ) )
			{
				continue;
			}
		}	

		weapon.attachments = FilterAttachments( weapon.attachments );

		ARRAY_ADD( weapons, weapon );
	}

	return weapons;
}

function FilterAttachments( attachments )
{
	attachments_valid = [];

	attachments_blacklisted = GetBlackList_Attachments();

	foreach( attachment in attachments )
	{
		if( array::contains( attachments_blacklisted, attachment.reference ) )
		{
			continue;
		}

		ARRAY_ADD( attachments_valid, attachment );
	}

	return attachments_valid;
}

function GetAvailableWeapons( team )
{
	weapons_available = [];

	if( !util::isValidTeam( team ) )
	{
		return weapons_available;
	}

	if( !util::isValidArray( level.weapons_available ) || !util::isValidArray( level.weapons_available[ team ] ) )
	{
		return weapons_available;
	}

	weapons_available = level.weapons_available[ team ];

	return weapons_available;
}

function SetUpgradePath( team, type_starter, type_upgrade )
{
	if( !util::isValidTeam( team ) )
	{
		return;
	}

	//make sure none of the parameters are empty
	if( !util::isValidString( type_starter ) || !util::isValidString( type_upgrade ) )
	{
		return;
	}

	//make sure the starter and upgrade types are not the same
	if( util::CompareStrings( type_starter, type_upgrade, true ) )
	{
		return;
	}

	if( !util::isValidArray( level.upgrade_path ) )
	{
		level.upgrade_path = [];
	}

	if( !util::isValidArray( level.upgrade_path[ team ] ) )
	{
		level.upgrade_path[ team ] = [];
	}

	//an upgrade type has already been defined, don't overwrite it
	if( util::isValidArray( level.upgrade_path[ team ][ type_starter ] ) )
	{
		return;
	}

	level.upgrade_path[ team ][ type_starter ] = type_upgrade;	
}

function GetStarterTypes( team )
{
	types_starter = [];

	if( !util::isValidTeam( team ) )
	{
		return types_starter;
	}

	if( !util::isValidArray( level.upgrade_path ) || !util::isValidArray( level.upgrade_path[ team ] ) )
	{
		return types_starter;
	}

	types_starter = GetArrayKeys( level.upgrade_path[ team ] );

	return types_starter;
}

function isStarterType( team, type )
{
	result = false;

	if( !util::isValidTeam( team ) )
	{
		return result;
	}

	if( !util::isValidString( type ) )
	{
		return result;
	}

	types_starter = GetStarterTypes( team );

	foreach( type_starter in types_starter )
	{
		if( util::CompareStrings( type_starter, type, true ) )
		{
			result = true;

			return result;
		}
	}

	return result;
}

function GetUpgradeType( team, type_starter )
{
	type_upgrade = "";

	if( !util::isValidTeam( team ) )
	{
		return type_upgrade;
	}
	
	if( !isStarterType( team, type_starter ) )
	{
		return type_upgrade;
	}

	if( !util::isValidArray( level.upgrade_path ) || !util::isValidArray( level.upgrade_path[ team ] ) )
	{
		return type_upgrade;
	}

	if( !util::isValidString( level.upgrade_path[ team ][ type_starter ] ) )
	{
		return type_upgrade;
	}

	type_upgrade = level.upgrade_path[ team ][ type_starter ];

	return type_upgrade;
}


/* -------------------------------------------------------------------------------------

	Section:		Perk Building
	Description:	Build the perks that can be used by humans and zombies.

------------------------------------------------------------------------------------- */

function BuildPerks()
{
	//if everything is already built, don't do again (round switching)
	if( util::isValidArray( level.perks_available ) )
	{
		return;
	}

	BuildBlackList_Perks();

	level.perks_available = [];
	level.perks_available[ "axis" ] = [];
	level.perks_available[ "allies" ] = [];

	perks = [];

	for( index = 0; index < STATS_TABLE_MAX_ITEMS; index++ )
	{
		row = TableLookupRowNum( level.statsTableID, STATS_TABLE_COL_NUMBERING, index );
		
		if ( row < 0 )
		{
			continue;
		}

		group = TableLookupColumnForRow( level.statsTableID, row, STATS_TABLE_COL_GROUP );

		if ( util::CompareStrings( group, "specialty", true ) )
		{
			reference = TableLookupColumnForRow( level.statsTableID, row, STATS_TABLE_COL_REFERENCE );				

			//check to see if it's a valid perk
			if( !util::isValidString( reference ) )
			{
				continue;
			}
			
			perk_index = util::GetArraySize( perks );

			//get the name and reference to the gun
			perks[ perk_index ] = SpawnStruct();
			perks[ perk_index ].name = MakeLocalizedString( TableLookupColumnForRow( level.statsTableID, row, STATS_TABLE_COL_NAME ) );
			perks[ perk_index ].references = util::StringToarray( reference, "|" );
			perks[ perk_index ].icon = TableLookupColumnForRow( level.statsTableID, row, STATS_TABLE_COL_IMAGE );
		}
	}	

	level.perks_available[ "axis" ] = BuildPerksForTeam( "axis", perks );
	level.perks_available[ "allies" ] = BuildPerksForTeam( "allies", perks );
}

function BuildBlackList_Perks()
{
	level.blacklist_perks = [];

	//use localized perk names because some perks have multiple references attached to them
	level.blacklist_perks[ "axis" ] = Array( "None", "Flack Jacket", "Hardline", "Ghost", "Scavenger", "Fast Hands", "Ante Up", "Engineer", "Sixth Sense", "Gung-Ho", "None" );
	level.blacklist_perks[ "allies" ] = Array( "Flak Jacket", "Blind Eye", "Hardline", "Ghost", "Lightweight", "Overclock", "Hard Wired", "Cold Blooded", "Toughness", "Tracker", "Ante Up", "Engineer", "Dead Silence", "Tactical Mask", "Sixth Sense", "Extreme Conditioning", "None" );
}

function GetBlackList_Perks( team )
{
	blacklist = [];

	if( !util::isValidTeam( team ) )
	{
		return blacklist;
	}

	if( !util::isValidArray( level.blacklist_perks[ team ] ) )
	{
		return blacklist;
	}

	blacklist = level.blacklist_perks[ team ];

	return blacklist;
}

function BuildPerksForTeam( team, perks_master )
{
	perks = [];

	if( !util::isValidArray( perks_master ) )
	{
		return perks;
	}

	blacklist_perks = GetBlackList_Perks( team );

	foreach( perk in perks_master )
	{
		//check to see if the weapon exists in the blacklist
		if( util::isValidArray( blacklist_perks ) )
		{
			//black list by name for perks because multiple perks have multiple sub-perk references
			if( array::contains( blacklist_perks, perk.name ) )
			{				
				continue;
			}
		}

		ARRAY_ADD( perks, perk );
	}

	return perks;
}

function GetAvailablePerks( team )
{
	perks_available = [];

	if( !util::isValidTeam( team ) )
	{
		return perks_available;
	}

	if( !util::isValidArray( level.perks_available ) || !util::isValidArray( level.perks_available[ team ] ) )
	{
		return perks_available;
	}

	perks_available = level.perks_available[ team ];

	return perks_available;
}

/* -------------------------------------------------------------------------------------

	Section:		Loadouts
	Description:	Functions that handle starting loadouts for zombies and humans.					

------------------------------------------------------------------------------------- */

function AddLoadoutItem( team, key, item )
{
	if( !util::isValidTeam( team ) )
	{
		return;
	}

	if( !util::isValidString( key ) )
	{
		return;
	}

	if( !isdefined( item ) )
	{
		return;
	}

	if( !util::isValidArray( self.loadout_starting ) )
	{
		self.loadout_starting = [];
	}

	if( !util::isValidTeam( team ) )
	{
		return;
	}

	if( !util::isValidArray( self.loadout_starting[ team ] ) )
	{
		self.loadout_starting[ team ] = [];	
	}

	if( !util::isValidArray( self.loadout_starting[ team ][ key ] ) )
	{
		self.loadout_starting[ team ][ key ] = [];	
	}

	ARRAY_ADD( self.loadout_starting[ team ][ key ], item );
}

function EditLoadoutItem( team, key, index, item )
{
	if( !util::isValidTeam( team ) )
	{
		return;
	}

	if( !util::isValidString( key ) )
	{
		return;
	}

	if( !util::isValidArray( self.loadout_starting ) || !util::isValidArray( self.loadout_starting[ team ] ) || !util::isValidArray( self.loadout_starting[ team ][ key ] ) )
	{
		return;
	}

	if( !util::isValidInt( index ) || index < 0 || index > util::GetArraySize( self.loadout_starting[ team ][ key ] ) )
	{
		return;
	}

	self.loadout_starting[ team ][ key ][ index ] = item;
}

function GenerateStartingLoadout( team )
{
	if( !util::isValidTeam( team ) )
	{
		return;
	}

	weapons = [];
	weapons = GetAvailableWeapons( team )[ "starter" ];
	
	types = GetArrayKeys( weapons );

	foreach( type in types )
	{
		weapon_struct = array::random( weapons[ type ] );

		AddLoadoutItem( team, "guns", weapon_struct );		
	}
}

function GetStartingLoadout( team )
{
	loadout_starting = [];

	if( !util::isValidTeam( team ) )
	{
		return loadout_starting;
	}

	if( !util::isValidArray( self.loadout_starting ) || !util::isValidArray( self.loadout_starting[ team ] ) )
	{
		return loadout_starting;
	}

	loadout_starting = self.loadout_starting[ team ];

	return loadout_starting;
}

//this will need to be modified for zombies if they buy things like hatchets, the ripper, etc
function GiveStartingLoadout()
{
	team = self.pers[ "team" ];

	loadout = GetStartingLoadout( team );

	keys = GetArrayKeys( loadout );

	//set up the structure to add perks, hatches, specialists, etc
	foreach( key in keys )
	{
		self thread GiveLoadoutItem( key, loadout[ key ] );
	}	
}

function GiveLoadoutItem( key, loadout )
{
	switch( key )
	{
		case "guns":
		{
			foreach( weapon_struct in loadout )
			{
				self GiveWeapon( weapon_struct.weapon );
				self GiveMaxAmmo( weapon_struct.weapon );
			}

			weapon_spawn = loadout[ util::GetArraySize( loadout ) - 1 ].weapon;
			self SetSpawnWeapon( weapon_spawn );
		}
		break;

		case "equipment":
		{
			foreach( equipment in loadout )
			{
				self GiveWeapon( equipment.weapon );

				clip_size = ( isdefined( equipment.clip_size ) && util::isValidInt( equipment.clip_size ) && equipment.clip_size > 0 ? equipment.clip_size : equipment.weapon.clipSize );
				self SetWeaponAmmoClip( equipment.weapon, clip_size );				
			}
		}
		break;

		case "gadget":
		{
			foreach( gadget in loadout )
			{
				self GiveWeapon( gadget.weapon );				
				self GadgetPowerChange( 0, 100 );				
			}
		}
		break;

		default:
		{
			
		}
		break;
	}	
}

function EditLoadoutWeapon( weapon )
{
	if( !util::isValidWeapon( weapon ) )
	{
		return;
	}

	key = "guns";
	team = self.pers[ "team" ];

	loadout = GetStartingLoadout( team )[ key ];
	reference = util::GetBaseWeapon( weapon ).name;

	for( index = 0; index < util::GetArraySize( loadout ); index++ )
	{
		item = loadout[ index ];

		if( util::CompareStrings( item.reference, reference ) )
		{
			item.name = util::GetLocalizedWeaponName( weapon.displayname );
			item.weapon = weapon;

			EditLoadoutItem( team, key, index, item );

			self SetSpawnWeapon( weapon );
		}
	}
}

function SwapLoadoutWeapon( weapon_old, weapon_struct_new )
{
	if( !util::isValidWeapon( weapon_old ) || !util::isValidWeapon( weapon_struct_new.weapon ))
	{
		return;	
	}

	key = "guns";
	team = self.pers[ "team" ];

	loadout = GetStartingLoadout( team )[ key ];
	reference = util::GetBaseWeapon( weapon_old ).name;

	for( index = 0; index < util::GetArraySize( loadout ); index++ )
	{
		if( util::CompareStrings( loadout[ index ].reference, reference ) )
		{
			EditLoadoutItem( team, key, index, weapon_struct_new );

			self SetSpawnWeapon( weapon_struct_new.weapon );
		}
	}
}