/*==============================================================================


	Southclaws' Scavenge and Survive

		Big thanks to Onfire559/Adam for the initial concept and developing
		the idea a lot long ago with some very productive discussions!
		Recently influenced by Minecraft and DayZ, credits to the creators of
		those games and their fundamental mechanics and concepts.

		Copyright (C) 2017 Barnaby "Southclaws" Keene

		This program is free software: you can redistribute it and/or modify it
		under the terms of the GNU General Public License as published by the
		Free Software Foundation, either version 3 of the License, or (at your
		option) any later version.

		This program is distributed in the hope that it will be useful, but
		WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
		See the GNU General Public License for more details.

		You should have received a copy of the GNU General Public License along
		with this program.  If not, see <http://www.gnu.org/licenses/>.


==============================================================================*/


#include <a_samp>

// Redefines MAX_PLAYERS constant before usage
#undef MAX_PLAYERS
#define MAX_PLAYERS	(32)

#include <logger>

native IsValidVehicle(vehicleid); // undefined native
native gpci(playerid, serial[], len); // undefined native
native WP_Hash(buffer[], len, const str[]); // Southclaws/samp-whirlpool

#define _DEBUG							0 // YSI
#define ITER_NONE						(cellmin) // Temporary fix for https://github.com/Misiur/YSI-Includes/issues/109
#define STRLIB_RETURN_SIZE				(256) // strlib
#define MODIO_DEBUG						(0) // modio
#define MODIO_FILE_STRUCTURE_VERSION	(20) // modio
#define MODIO_SCRIPT_EXIT_FIX			(1) // modio
#define BTN_TELEPORT_FREEZE_TIME		(3000) // SIF/Button
#define INV_MAX_SLOTS					(6) // SIF/Inventory
#define ITM_ARR_ARRAY_SIZE_PROTECT		(false) // SIF/extensions/ItemArrayData
#define ITM_MAX_TYPES					(ItemType:300) // SIF/Item
#define ITM_MAX_NAME					(20) // SIF/Item
#define ITM_MAX_TEXT					(64) // SIF/Item
#define ITM_DROP_ON_DEATH				(false) // SIF/Item

#if defined BUILD_MINIMAL

#define MAX_BUTTON						(4096) // SIF/Button
#define MAX_ITEM						(4096) // SIF/Item
#define MAX_CONTAINER_SLOTS				(100)
#define MAX_MODIO_STACK_SIZE			(1024)
#define MAX_MODIO_SESSION				(2)

#else

#define MAX_BUTTON						(32768) // SIF/Button
#define MAX_ITEM						(32768) // SIF/Item
#define MAX_CONTAINER_SLOTS				(100)
#define MAX_MODIO_SESSION				(2048) // modio

#endif

/*==============================================================================

	Guaranteed first call

	Note: This is not tested in YSI 4.x or 5.x branches! As a result, the below
	claim may not be true any more!

	-

	OnGameModeInit_Setup is called before ANYTHING else, the purpose of this is
	to prepare various internal and external systems that may need to be ready
	for other modules to use their functionality. This function isn't hooked.

	OnScriptInit (from YSI) is then called through modules which is used to
	prepare dependencies such as databases, folders and register debuggers.

	OnGameModeInit is then finally called throughout modules and starts inside
	the "Server/Init.pwn" module (very important) so itemtypes and other object
	types can be defined. This callback is used throughout other scripts as a
	means for declaring entities with relevant data.

==============================================================================*/

// Must include y_utils before this hook (not quite a "guaranteed" first call any more!)
// due to https://github.com/Misiur/YSI-Includes/issues/196
#include <YSI\y_utils>

public OnGameModeInit()
{
	print("[OnGameModeInit] Initialising 'Main'...");

	OnGameModeInit_Setup();

	#if defined main_OnGameModeInit
		return main_OnGameModeInit();
	#else
		return 1;
	#endif
}
#if defined _ALS_OnGameModeInit
	#undef OnGameModeInit
#else
	#define _ALS_OnGameModeInit
#endif
#define OnGameModeInit main_OnGameModeInit
#if defined main_OnGameModeInit
	forward main_OnGameModeInit();
#endif

#include "sss\core\server\hooks.pwn" // preload library for hooking functions before they are used in external libraries.

#include <crashdetect>   // Zeex/samp-plugin-crashdetect
#include <sscanf2>       // maddinat0r/sscanf
#include <YSI\y_colours> // pawn-lang/YSI-Includes
#include <YSI\y_va>      // pawn-lang/YSI-Includes
#include <YSI\y_timers>  // pawn-lang/YSI-Includes
#include <YSI\y_iterate> // pawn-lang/YSI-Includes
#include <YSI\y_ini>     // pawn-lang/YSI-Includes
#include <streamer>      // samp-incognito/samp-streamer-plugin
#include <formatex>      // Southclaws/formatex
#include <strlib>        // oscar-broman/strlib
#include <easyDialog>    // Awsomedude/easyDialog

#include <ctime>         // Southclaws/samp-ctime
#include <progress2>     // Southclaws/progress2
#include <mapandreas>    // Southclaws/samp-plugin-mapandreas
#include <ini>           // Southclaws/samp-ini
#include <modio>         // Southclaws/modio
#include <fsutil>        // Southclaws/fsutil

#include <mathutil> // ScavengeSurvive/mathutil
#include <settings> // ScavengeSurvive/settings
#include <language> // ScavengeSurvive/language
#include <chat>     // ScavengeSurvive/chat
#include <item>     // ScavengeSurvive/item

// must re-initialise y_hooks after the above packages
#include <YSI\y_hooks> // pawn-lang/YSI-Includes


// -
// Definitions
// -


// Colours
#define SS_YELLOW     (0xFFFF00FF)
#define SS_RED        (0xE85454FF)
#define SS_GREEN      (0x33AA33FF)
#define SS_BLUE       (0x33CCFFFF)
#define SS_ORANGE     (0xFFAA00FF)
#define SS_GREY       (0xAFAFAFFF)
#define SS_PINK       (0xFFC0CBFF)
#define SS_NAVY       (0x000080FF)
#define SS_GOLD       (0xB8860BFF)
#define SS_LGREEN     (0x00FD4DFF)
#define SS_TEAL       (0x008080FF)
#define SS_BROWN      (0xA52A2AFF)
#define SS_AQUA       (0xF0F8FFFF)
#define SS_BLACK      (0x000000FF)
#define SS_WHITE      (0xFFFFFFFF)
#define SS_CHAT_LOCAL (0xADABD1FF)
#define SS_CHAT_RADIO (0xCFD1ABFF)

// Limits
#define MAX_MOTD_LEN     (128)
#define MAX_WEBSITE_NAME (64)
#define MAX_RULE         (24)
#define MAX_RULE_LEN     (128)
#define MAX_STAFF        (24)
#define MAX_STAFF_LEN    (24)
#define MAX_PLAYER_FILE  (MAX_PLAYER_NAME+16)
#define MAX_ADMIN        (48)
#define MAX_PASSWORD_LEN (129)
#define MAX_GPCI_LEN     (41)
#define MAX_HOST_LEN     (256)

// Files etc
#define DIRECTORY_SCRIPTFILES "./scriptfiles/"
#define DIRECTORY_MAIN        "data/"
#define SETTINGS_FILE         DIRECTORY_MAIN"settings.ini"

// Helper Macros
#define HOLDING(%0) ((newkeys & (%0)) == (%0))
#define RELEASED(%0) (((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))
#define PRESSED(%0) (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define IsValidPlayerID(%0) (0<=%0<MAX_PLAYERS)


new
		gBuildNumber,
bool:	gServerInitialising = true,
		gServerInitialiseTick,
bool:	gServerRestarting = false,
		gServerMaxUptime,
		gServerUptime;

// settings.ini variables
new
		gMessageOfTheDay[MAX_MOTD_LEN],
		gWebsiteURL[MAX_WEBSITE_NAME],
		gRuleList[MAX_RULE][MAX_RULE_LEN],
		gTotalRules,
		gStaffList[MAX_STAFF][MAX_STAFF_LEN],
		gTotalStaff,
bool:	gPauseMap,
bool:	gInteriorEntry,
bool:	gVehicleSurfing,
Float:	gNameTagDistance,
		gCombatLogWindow,
		gLoginFreezeTime,
		gMaxTaboutTime,
		gPingLimit,
		gCrashOnExit;


// -
// Modules
// -


// API Pre
// #tryinclude "sss/extensions/ext_pre.pwn"

// UTILITIES
// #include "sss/utils/misc.pwn"
// #include "sss/utils/camera.pwn"
// #include "sss/utils/vehicle.pwn"
// #include "sss/utils/vehicle-data.pwn"
// #include "sss/utils/vehicle-parts.pwn"
// #include "sss/utils/zones.pwn"
// #include "sss/utils/player.pwn"
// #include "sss/utils/object.pwn"
// #include "sss/utils/string.pwn"
// #include "sss/utils/dialog-pages.pwn"
// #include "sss/utils/item.pwn"
// #include "sss/utils/headoffsets.pwn"

// SERVER CORE
// #include "sss/core/server/weather.pwn"
// #include "sss/core/server/save-block.pwn"
// #include "sss/core/server/info-message.pwn"
// #include "sss/core/player/language.pwn"

/*
	PARENT SYSTEMS
	Modules that declare setup functions and constants used throughout.
*/
// #include "sss/core/player/accounts-io.pwn"
// #include "sss/core/vehicle/vehicle-type.pwn"
// #include "sss/core/vehicle/lock.pwn"
// #include "sss/core/vehicle/core.pwn"
// #include "sss/core/player/core.pwn"
// #include "sss/core/player/save-load.pwn"
// #include "sss/core/admin/core.pwn"
// #include "sss/core/ui/hold-action.pwn"
// #include "sss/core/item/liquid.pwn"
// #include "sss/core/item/liquid-container.pwn"
// #include "sss/core/world/tree.pwn"
// #include "sss/core/world/explosive.pwn"
// #include "sss/core/world/craft-construct.pwn"
// #include "sss/core/world/loot-loader.pwn"

/*
	MODULE INITIALISATION CALLS
	Calls module constructors to set up entity types.
*/
// #include "sss/core/server/init.pwn"

/*
	CHILD SYSTEMS
	Modules that do not declare anything globally accessible besides interfaces.
*/

// VEHICLE
// #include "sss/core/vehicle/player-vehicle.pwn"
// #include "sss/core/vehicle/loot-vehicle.pwn"
// #include "sss/core/vehicle/spawn.pwn"
// #include "sss/core/vehicle/interact.pwn"
// #include "sss/core/vehicle/trunk.pwn"
// #include "sss/core/vehicle/repair.pwn"
// #include "sss/core/vehicle/lock-break.pwn"
// #include "sss/core/vehicle/locksmith.pwn"
// #include "sss/core/vehicle/carmour.pwn"
// #include "sss/core/vehicle/anti-ninja.pwn"
// #include "sss/core/vehicle/bike-collision.pwn"
// #include "sss/core/vehicle/trailer.pwn"

// PLAYER INTERNAL SCRIPTS
// #include "sss/core/player/accounts.pwn"
// // #include "sss/core/player/aliases.pwn"
// // #include "sss/core/player/ipv4-log.pwn"
// // #include "sss/core/player/gpci-log.pwn"
// #include "sss/core/player/brightness.pwn"
// #include "sss/core/player/spawn.pwn"
// #include "sss/core/player/clothes.pwn"
// #include "sss/core/player/death.pwn"
// #include "sss/core/player/tutorial.pwn"
// #include "sss/core/player/welcome-message.pwn"
// #include "sss/core/player/cmd-process.pwn"
// #include "sss/core/player/commands.pwn"
// #include "sss/core/player/alt-tab-check.pwn"
// #include "sss/core/player/disallow-actions.pwn"
// #include "sss/core/player/whitelist.pwn"
// #include "sss/core/player/country.pwn"
// #include "sss/core/player/recipes.pwn"

// UI
// #include "sss/core/ui/radio.pwn"
// #include "sss/core/ui/tool-tip.pwn"
// #include "sss/core/ui/key-actions.pwn"
// #include "sss/core/ui/watch.pwn"
// #include "sss/core/ui/keypad.pwn"
// #include "sss/core/ui/body-preview.pwn"
// #include "sss/core/ui/status.pwn"

// WORLD ENTITIES
// #include "sss/core/world/fuel.pwn"
// #include "sss/core/world/barbecue.pwn"
// #include "sss/core/world/defences.pwn"
// #include "sss/core/world/gravestone.pwn"
// #include "sss/core/world/safebox.pwn"
// #include "sss/core/world/tent.pwn"
// #include "sss/core/world/campfire.pwn"
// #include "sss/core/world/emp.pwn"
// #include "sss/core/world/sign.pwn"
// #include "sss/core/world/supply-crate.pwn"
// #include "sss/core/world/weapons-cache.pwn"
// #include "sss/core/world/loot.pwn"
// #include "sss/core/world/workbench.pwn"
// #include "sss/core/world/machine.pwn"
// #include "sss/core/world/scrap-machine.pwn"
// #include "sss/core/world/refine-machine.pwn"
// #include "sss/core/world/tree-loader.pwn"
// // #include "sss/core/world/water-purifier.pwn"
// #include "sss/core/world/plot-pole.pwn"
// #include "sss/core/world/item-tweak.pwn"
// #include "sss/core/world/furniture.pwn"

// ADMINISTRATION TOOLS
// #include "sss/core/admin/report.pwn"
// #include "sss/core/admin/report-io.pwn"
// #include "sss/core/admin/report-cmds.pwn"
// #include "sss/core/admin/hack-detect.pwn"
// #include "sss/core/admin/hack-trap.pwn"
// #include "sss/core/admin/ban.pwn"
// #include "sss/core/admin/ban-io.pwn"
// #include "sss/core/admin/ban-command.pwn"
// #include "sss/core/admin/ban-list.pwn"
// #include "sss/core/admin/spectate.pwn"
// #include "sss/core/admin/level1.pwn"
// #include "sss/core/admin/level2.pwn"
// #include "sss/core/admin/level3.pwn"
// #include "sss/core/admin/level4.pwn"
// #include "sss/core/admin/level5.pwn"
// #include "sss/core/admin/bug-report.pwn"
// // #include "sss/core/admin/detfield.pwn"
// // #include "sss/core/admin/detfield-io.pwn"
// // #include "sss/core/admin/detfield-cmds.pwn"
// // #include "sss/core/admin/detfield-draw.pwn"
// #include "sss/core/admin/rcon.pwn"
// #include "sss/core/admin/freeze.pwn"
// #include "sss/core/admin/name-tags.pwn"
// #include "sss/core/admin/player-list.pwn"

// ITEMS
// #include "sss/core/item/food.pwn"
// #include "sss/core/item/firework.pwn"
// #include "sss/core/item/shield.pwn"
// #include "sss/core/item/handcuffs.pwn"
// #include "sss/core/item/wheel.pwn"
// #include "sss/core/item/headlight.pwn"
// #include "sss/core/item/pills.pwn"
// #include "sss/core/item/dice.pwn"
// #include "sss/core/item/armour.pwn"
// #include "sss/core/item/injector.pwn"
// #include "sss/core/item/parachute.pwn"
// #include "sss/core/item/molotov.pwn"
// #include "sss/core/item/screwdriver.pwn"
// #include "sss/core/item/torso.pwn"
// #include "sss/core/item/ammotin.pwn"
// #include "sss/core/item/campfire.pwn"
// #include "sss/core/item/herpderp.pwn"
// #include "sss/core/item/stungun.pwn"
// #include "sss/core/item/note.pwn"
// #include "sss/core/item/seedbag.pwn"
// #include "sss/core/item/plantpot.pwn"
// #include "sss/core/item/heartshapedbox.pwn"
// #include "sss/core/item/fishingrod.pwn"
// #include "sss/core/item/chainsaw.pwn"
// #include "sss/core/item/locator.pwn"
// #include "sss/core/item/locker.pwn"

// ITEMS (HATS/MASKS)
// #include "sss/core/item/armyhelm.pwn"
// #include "sss/core/item/cowboyhat.pwn"
// #include "sss/core/item/truckcap.pwn"
// #include "sss/core/item/boaterhat.pwn"
// #include "sss/core/item/bowlerhat.pwn"
// #include "sss/core/item/policecap.pwn"
// #include "sss/core/item/tophat.pwn"
// #include "sss/core/item/bandana.pwn"
// #include "sss/core/item/xmashat.pwn"
// #include "sss/core/item/witcheshat.pwn"
// #include "sss/core/item/policehelm.pwn"

// #include "sss/core/item/zorromask.pwn"
// #include "sss/core/item/gasmask.pwn"
// #include "sss/core/item/hockeymask.pwn"

// POST-CODE

// #include "sss/core/server/auto-save.pwn"
// #tryinclude "sss/extensions/ext_post.pwn"

// WORLD

// #if defined BUILD_MINIMAL
// #include "sss/world-bs/world.pwn"
// #else
// #include "sss/world/world.pwn"
// #endif

// #if !defined GetMapName
// 	#error World script MUST have a "GetMapName" function!
// #endif

// #if !defined GenerateSpawnPoint
// 	#error World script MUST have a "GenerateSpawnPoint" function!
// #endif


main() {
	log("================================================================================");
	log("    Southclaws' Scavenge and Survive");
	log("        Copyright (C) 2016 Barnaby \"Southclaws\" Keene");
	log("        This program comes with ABSOLUTELY NO WARRANTY; This is free software,");
	log("        and you are welcome to redistribute it under certain conditions.");
	log("        Please see <http://www.gnu.org/copyleft/gpl.html> for details.");
	log("================================================================================");

	gServerInitialising = false;
	gServerInitialiseTick = GetTickCount();
}

static Text:RestartCount = Text:INVALID_TEXT_DRAW;

OnGameModeInit_Setup() {
	// todo: fsutil ReadFile impl
	// new buildstring[12];
	// ReadFile("BUILD_NUMBER", buildstring);
	// gBuildNumber = strval(buildstring);
	// if(gBuildNumber < 1000) {
	// 	fatal("build number < 1000",
	// 		_i("build", gBuildNumber));
	// }
	log("initialising Scavenge and Survive",
		_i("build", gBuildNumber));

	Streamer_ToggleErrorCallback(true);
	MapAndreas_Init(MAP_ANDREAS_MODE_FULL);
	UsePlayerPedAnims();

	CreateDirIfNotExists(DIRECTORY_SCRIPTFILES);
	CreateDirIfNotExists(DIRECTORY_SCRIPTFILES DIRECTORY_MAIN);

	GetSettingString(SETTINGS_FILE, "server/motd", "Please update the 'server/motd' string in "SETTINGS_FILE"", gMessageOfTheDay);
	GetSettingString(SETTINGS_FILE, "server/website", "southclawjk.wordpress.com", gWebsiteURL);
	GetSettingInt(SETTINGS_FILE, "server/crash-on-exit", true, gCrashOnExit);
	GetSettingStringArray(SETTINGS_FILE, "server/rules", "Please update the 'server/rules' array in '"SETTINGS_FILE"'.", gRuleList, gTotalRules, 128, MAX_RULE, MAX_RULE_LEN);
	GetSettingStringArray(SETTINGS_FILE, "server/staff", "StaffName", gStaffList, gTotalStaff, 32, MAX_STAFF, MAX_STAFF_LEN);
	GetSettingInt(SETTINGS_FILE, "server/max-uptime", 18000, gServerMaxUptime);
	GetSettingInt(SETTINGS_FILE, "player/allow-pause-map", 0, gPauseMap);
	GetSettingInt(SETTINGS_FILE, "player/interior-entry", 0, gInteriorEntry);
	GetSettingInt(SETTINGS_FILE, "player/vehicle-surfing", 0, gVehicleSurfing);
	GetSettingFloat(SETTINGS_FILE, "player/nametag-distance", 3.0, gNameTagDistance);
	GetSettingInt(SETTINGS_FILE, "player/combat-log-window", 30, gCombatLogWindow);
	GetSettingInt(SETTINGS_FILE, "player/login-freeze-time", 8, gLoginFreezeTime);
	GetSettingInt(SETTINGS_FILE, "player/max-tab-out-time", 60, gMaxTaboutTime);
	GetSettingInt(SETTINGS_FILE, "player/ping-limit", 400, gPingLimit);

	// I'd appreciate if you left my credit and the proper gamemode name intact!
	// Failure to do this will result in being blacklisted from the server list.
	// And I'll be less inclined to help you with issues.
	// Unless you have a decent reason to change the gamemode name (heavy mod)
	// I'd still like to be credited for my work. Many servers have claimed
	// they are the sole creator of the mode and this makes me sad and very
	// hesitant to release my work completely free of charge.
	SetGameModeText("Scavenge Survive by Southclaw");

	// SETTINGS
	// if(!gPauseMap) {
	// 	MiniMapOverlay = GangZoneCreate(-6000, -6000, 6000, 6000);
	// }

	if(!gInteriorEntry) {
		DisableInteriorEnterExits();
	}

	SetNameTagDrawDistance(gNameTagDistance);

	EnableStuntBonusForAll(false);
	ManualVehicleEngineAndLights();
	AllowInteriorWeapons(true);

	// todo: GetMapName impl
	// SendRconCommand(sprintf("mapname %s", GetMapName()));

	RestartCount				=TextDrawCreate(430.000000, 10.000000, "Server Restart In:~n~00:00");
	TextDrawAlignment			(RestartCount, 2);
	TextDrawBackgroundColor		(RestartCount, 255);
	TextDrawFont				(RestartCount, 1);
	TextDrawLetterSize			(RestartCount, 0.400000, 2.000000);
	TextDrawColor				(RestartCount, -1);
	TextDrawSetOutline			(RestartCount, 1);
	TextDrawSetProportional		(RestartCount, 1);
}

public OnGameModeExit() {
	if(gCrashOnExit) {
		fatal("gamemode exiting with forced crash");
	} else {
		log("gamemode exiting");
	}

	return 1;
}

public OnScriptExit() {
	log("script exiting");
	return 0;
}

forward SetRestart(seconds);
public SetRestart(seconds) {
	log("server restart triggered",
		_i("seconds", seconds));

	gServerUptime = gServerMaxUptime - seconds;
}

RestartGamemode() {
	log("gamemode restarting");

	gServerRestarting = true;

	// foreach(new i : Player) {
	// 	SavePlayerData(i);
	// 	ResetVariables(i);
	// }

	SendRconCommand("gmx");

	ChatMsgAll(Y_BLUE, " ");
	ChatMsgAll(Y_ORANGE, "Scavenge and Survive");
	ChatMsgAll(Y_BLUE, "    Copyright (C) 2016 Barnaby \"Southclaws\" Keene");
	ChatMsgAll(Y_BLUE, "    This program comes with ABSOLUTELY NO WARRANTY; This is free software,");
	ChatMsgAll(Y_BLUE, "    and you are welcome to redistribute it under certain conditions.");
	ChatMsgAll(Y_BLUE, "    Please see <http://www.gnu.org/copyleft/gpl.html> for details.");
	ChatMsgAll(Y_BLUE, " ");
	ChatMsgAll(Y_BLUE, " ");
	ChatMsgAll(Y_BLUE, "-------------------------------------------------------------------------------------------------------------------------");
	ChatMsgAll(Y_YELLOW, " >  The Server Is Restarting, Please Wait...");
	ChatMsgAll(Y_BLUE, "-------------------------------------------------------------------------------------------------------------------------");
}

task RestartUpdate[1000]() {
	if(gServerMaxUptime > 0) {
		if(gServerUptime >= gServerMaxUptime) {
			RestartGamemode();
		}

		if(gServerUptime >= gServerMaxUptime - 3600) {
			new str[36];
			format(str, 36, "Server Restarting In:~n~%02d:%02d", (gServerMaxUptime - gServerUptime) / 60, (gServerMaxUptime - gServerUptime) % 60);
			TextDrawSetString(RestartCount, str);

			foreach(new i : Player) {
				TextDrawShowForPlayer(i, RestartCount);
				// if(IsPlayerHudOn(i)) {
				// } else {
				// 	TextDrawHideForPlayer(i, RestartCount);
				// }
			}
		}

		gServerUptime++;
	}
}

CreateDirIfNotExists(directory[]) {
	if(!Exists(directory)) {
		log("creating default directory",
			_s("path", directory));

		CreateDir(directory);
	}
}

public Streamer_OnPluginError(const error[]) {
	new tmp[256];
	strcat(tmp, error, 256);
	err(tmp);
}
