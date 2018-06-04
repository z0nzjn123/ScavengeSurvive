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
#include <chrono>        // Southclaws/pawn-chrono
#include <progress2>     // Southclaws/progress2
#include <mapandreas>    // Southclaws/samp-plugin-mapandreas
#include <ini>           // Southclaws/samp-ini
#include <modio>         // Southclaws/modio
#include <fsutil>        // Southclaws/pawn-fsutil
#include <requests>      // Southclaws/pawn-requests

#include <mathutil>  // ScavengeSurvive/mathutil
#include <settings>  // ScavengeSurvive/settings
#include <language>  // ScavengeSurvive/language
#include <chat>      // ScavengeSurvive/chat
#include <item>      // ScavengeSurvive/item
#include <container> // ScavengeSurvive/container
#include <bag>       // ScavengeSurvive/bag
#include <inventory> // ScavengeSurvive/inventory

// must re-initialise y_hooks after the above packages
#include <YSI\y_hooks> // pawn-lang/YSI-Includes


// -
// Definitions
// -


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


new stock
		gBuildNumber = 