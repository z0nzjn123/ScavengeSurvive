/*==============================================================================


	Southclaws' Scavenge and Survive

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


#include <YSI\y_hooks>


#define FIELD_PLAYER_ID					"_id"
#define FIELD_PLAYER_NAME				"name"
#define FIELD_PLAYER_PASS				"pass"
#define FIELD_PLAYER_IPV4				"ipv4"
#define FIELD_PLAYER_ALIVE				"alive"
#define FIELD_PLAYER_REGDATE			"regdate"
#define FIELD_PLAYER_LASTLOG			"lastlog"
#define FIELD_PLAYER_SPAWNTIME			"spawntime"
#define FIELD_PLAYER_TOTALSPAWNS		"spawns"
#define FIELD_PLAYER_WARNINGS			"warnings"
#define FIELD_PLAYER_GPCI				"gpci"
#define FIELD_PLAYER_ARCHIVED			"archived"

#define ACCOUNT_LOAD_RESULT_EXIST		(0) // Account does exist, prompt login
#define ACCOUNT_LOAD_RESULT_EXIST_AL	(1) // Account does exist, auto login
#define ACCOUNT_LOAD_RESULT_EXIST_WL	(2) // Account does exist, but not in whitelist
#define ACCOUNT_LOAD_RESULT_EXIST_DA	(3) // Account does exist, but is disabled
#define ACCOUNT_LOAD_RESULT_NO_EXIST	(4) // Account does not exist
#define ACCOUNT_LOAD_RESULT_ERROR		(5) // LoadAccount aborted, kick player.


static
	LoginAttempts[MAX_PLAYERS],
	NewPlayer[MAX_PLAYERS],
	HasAccount[MAX_PLAYERS],
	LoggedIn[MAX_PLAYERS];


forward OnPlayerLoadAccount(playerid);
forward OnPlayerLoadedAccount(playerid, loadresult);
forward OnPlayerRegister(playerid);
forward OnPlayerLogin(playerid);


hook OnPlayerConnect(playerid)
{
	LoginAttempts[playerid] = 0;
	NewPlayer[playerid] = false;
	HasAccount[playerid] = false;
	LoggedIn[playerid] = false;
}


/*==============================================================================

	Loads database data into memory and applies it to the player.

==============================================================================*/


static Map:AccountLoadRequests;
forward OnAccountLoad(Request:id, E_HTTP_STATUS:status, Node:node);
LoadAccount(playerid)
{
	if(CallLocalFunction("OnPlayerLoadAccount", "d", playerid)) {
		return;
	}

	defer LoadAccountDelay(playerid);
}
timer LoadAccountDelay[1000](playerid)
{
	if(gServerInitialising || GetTickCountDifference(GetTickCount(), gServerInitialiseTick) < 5000)
	{
		defer LoadAccountDelay(playerid);
		return;
	}

	if(!IsPlayerConnected(playerid))
	{
		dbg("player", "player not connected any more.",
			_i("playerid", playerid));
		return;
	}

	new
		name[MAX_PLAYER_NAME],
		url[128];

	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	format(url, sizeof(url), "/store/playerGet?name=%s", name);

	new Request:id = RequestJSON(
		Store,
		url,
		HTTP_METHOD_GET,
		"OnAccountLoad"
	);
	MAP_insert_val_val(AccountLoadRequests, playerid, _:id);

	return;
}
public OnAccountLoad(Request:id, E_HTTP_STATUS:status, Node:node) {
	new playerid = MAP_get_val_val(AccountLoadRequests, _:id);

	// TODO: unmarshal response and check success field
	// if(loadresult == ACCOUNT_LOAD_RESULT_NO_EXIST) {
	// 	HasAccount[playerid] = false;
	// } else {
	// 	HasAccount[playerid] = true;
	// }

	HasAccount[playerid] = true;
	NewPlayer[playerid] = false;

	CallLocalFunction("OnPlayerLoadedAccount", "dd", playerid, ACCOUNT_LOAD_RESULT_NO_EXIST);
}


/*==============================================================================

	Creates a new account for a player with the specified password hash.

==============================================================================*/


DisplayRegisterPrompt(playerid)
{
	new str[150];
	format(str, 150, @L(playerid, "ACCREGIBODY"), playerid);

	dbg("player", "player is registering",
		_i("playerid", playerid));

	Dialog_Open(
		playerid,
		"RegisterPrompt",
		DIALOG_STYLE_PASSWORD,
		@L(playerid, "ACCREGITITL"),
		str,
		"Accept",
		"Leave"
	);

	return 1;
}
Dialog:RegisterPrompt(playerid, response, listitem, inputtext[])
{
	dbg("player", "player responded to register dialog",
		_i("playerid", playerid),
		_i("response", response));

	if(response)
	{
		if(!(4 <= strlen(inputtext) <= 32))
		{
			ChatMsgLang(playerid, YELLOW, "PASSWORDREQ");
			DisplayRegisterPrompt(playerid);
			return 0;
		}

		new buffer[MAX_PASSWORD_LEN];

		WP_Hash(buffer, MAX_PASSWORD_LEN, inputtext);

		CreateAccount(playerid, buffer);
	}
	else
	{
		ChatMsgAll(GREY, " >  %p left the server without registering.", playerid);
		Kick(playerid);
	}

	return 0;
}

DisplayLoginPrompt(playerid, badpass = 0)
{
	new str[128];

	if(badpass) {
		format(str, 128, @L(playerid, "ACCLOGWROPW"), LoginAttempts[playerid]);
	} else {
		format(str, 128, @L(playerid, "ACCLOGIBODY"), playerid);
	}

	dbg("player", "player logging in",
		_i("playerid", playerid));

	Dialog_Open(
		playerid,
		"LoginPrompt",
		DIALOG_STYLE_PASSWORD,
		@L(playerid, "ACCLOGITITL"),
		str,
		"Accept",
		"Leave"
	);

	return 1;
}

Dialog:LoginPrompt(playerid, response, listitem, inputtext[])
{
	dbg("player", "player responded to login dialog",
		_i("playerid", playerid),
		_i("response", response));

	if(response)
	{
		if(strlen(inputtext) < 4)
		{
			LoginAttempts[playerid]++;

			if(LoginAttempts[playerid] < 5)
			{
				DisplayLoginPrompt(playerid, 1);
			}
			else
			{
				ChatMsgAll(GREY, " >  %p left the server without logging in.", playerid);
				Kick(playerid);
			}

			return 1;
		}

		new
			inputhash[MAX_PASSWORD_LEN],
			storedhash[MAX_PASSWORD_LEN];

		WP_Hash(inputhash, MAX_PASSWORD_LEN, inputtext);
		GetPlayerPassHash(playerid, storedhash);

		if(!strcmp(inputhash, storedhash))
		{
			Login(playerid);
		}
		else
		{
			LoginAttempts[playerid]++;

			if(LoginAttempts[playerid] < 5)
			{
				DisplayLoginPrompt(playerid, 1);
			}
			else
			{
				ChatMsgAll(GREY, " >  %p left the server without logging in.", playerid);
				Kick(playerid);
			}

			return 1;
		}
	}
	else
	{
		ChatMsgAll(GREY, " >  %p left the server without logging in.", playerid);
		Kick(playerid);
	}

	return 0;
}


/*==============================================================================

	Loads a player's account, updates some data and spawns them.

==============================================================================*/


static Map:AccountCreateRequests;
forward OnAccountCreate(Request:id, E_HTTP_STATUS:status, Node:node);
CreateAccount(playerid, pass[])
{
	new
		name[MAX_PLAYER_NAME],
		ipv4[16],
		regdate,
		lastlog,
		hash[MAX_GPCI_LEN],
		ret;

	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	regdate = lastlog = gettime();
	GetPlayerIp(playerid, ipv4, 16);
	gpci(playerid, hash, MAX_GPCI_LEN);


	new Request:id = RequestJSON(
		Store,
		"/store/playerCreate",
		HTTP_METHOD_POST,
		"OnAccountCreate",
		JsonObject(
			FIELD_PLAYER_PASS, JsonString(pass),
			FIELD_PLAYER_IPV4, JsonString(ipv4),
			FIELD_PLAYER_ALIVE, JsonBool(true),
			FIELD_PLAYER_REGDATE, JsonInt(regdate),
			FIELD_PLAYER_LASTLOG, JsonInt(lastlog),
			FIELD_PLAYER_TOTALSPAWNS, JsonInt(0),
			FIELD_PLAYER_WARNINGS, JsonInt(0),
			FIELD_PLAYER_GPCI, JsonString(hash),
			FIELD_PLAYER_ARCHIVED, JsonBool(false)
		)
	);
	if(id == Request:-1) {
		err("failed to create account for player",
			_i("playerid", playerid),
			_s("name", name));
		return ret;
	}

	MAP_insert_val_val(AccountCreateRequests, playerid, _:id);

	return 0;
}
public OnAccountCreate(Request:id, E_HTTP_STATUS:status, Node:node) {
	new playerid = MAP_get_val_val(AccountCreateRequests, _:id);
	if(!IsPlayerConnected(playerid)) {
		dbg("player", "ignoring response for non-connected player",
			_i("playerid", playerid));
		return;
	}

	NewPlayer[playerid] = true;
	HasAccount[playerid] = true;

	// TODO: reintegrate
	// SetPlayerToolTips(playerid, true);

	// TODO: unmarshal response and use success to branch on:
	{
		Login(playerid);
		// TODO: reintegrate
		// ShowWelcomeMessage(playerid, 10);
	}// else {
	// 	KickPlayer(playerid, "Account creation failed");
	// }

	CallLocalFunction("OnPlayerRegister", "d", playerid);
}


/*==============================================================================

	Logs the player in, applying loaded data to the character

==============================================================================*/


Login(playerid)
{
	new
		name[MAX_PLAYER_NAME],
		hash[MAX_GPCI_LEN],
		ipv4[16];

	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	gpci(playerid, hash, MAX_GPCI_LEN);
	GetPlayerIp(playerid, ipv4, 16);

	dbg("player", "player logged in",
		_i("playerid", playerid),
		_i("alive", IsPlayerAlive(playerid)));

	// TODO: update account with IP, GPCI and LastLogin time
	// SetAccountIP(name, ipv4);
	// SetAccountGPCI(name, hash);
	// SetAccountLastLogin(name, gettime());

	// TODO: reintegrate
	// SetPlayerAdminLevel(playerid, adminLevel);
	// if(adminLevel > 0) {
	// 	new reports = GetUnreadReports();
	// 	ChatMsg(playerid, BLUE, " >  Your admin level: %d", adminLevel);
	// 	if(reports > 0) {
	// 		ChatMsg(playerid, YELLOW, " >  %d unread reports, type "C_BLUE"/reports "C_YELLOW"to view.", reports);
	// 	}
	// }

	LoggedIn[playerid] = true;
	LoginAttempts[playerid] = 0;

	SetPlayerRadioFrequency(playerid, 107.0);
	// TODO: reintegrate or use kristoisberg/screen-colour-fader
	// SetPlayerBrightness(playerid, 255);

	CallLocalFunction("OnPlayerLogin", "d", playerid);
}


/*==============================================================================

	Logs the player out, saving their data and deleting their items.

==============================================================================*/


Logout(playerid, docombatlogcheck = 1)
{
	if(!LoggedIn[playerid])
	{
		dbg("player", "player logged out who was not logged in",
			_i("playerid", playerid));
		return 0;
	}

	new
		Float:x,
		Float:y,
		Float:z,
		Float:r;

	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, r);

	log("player logged out",
		_i("playerid", playerid),
		_f("x", x),
		_f("y", y),
		_f("z", z),
		_f("r", r),
		_i("alive", IsPlayerAlive(playerid)));

	// TODO: reintegrate
	// if(IsPlayerOnAdminDuty(playerid))
	// {
	// 	return 0;
	// }

	// TODO: reintegrate
	// if(docombatlogcheck) {
	// 	if(gServerMaxUptime - gServerUptime > 30) {
	// 		new
	// 			lastattacker,
	// 			lastweapon;

	// 		if(IsPlayerCombatLogging(playerid, lastattacker, lastweapon)) {
	// 			log("[LOGOUT] Player '%p' combat logged!", playerid);
	// 			ChatMsgAll(YELLOW, " >  %p combat logged!", playerid);
	// 			OnPlayerDeath(playerid, lastattacker, lastweapon);
	// 		}
	// 	}
	// }

	new
		itemid,
		ItemType:itemtype;

	itemid = GetPlayerItem(playerid);
	itemtype = GetItemType(itemid);

	// TODO: reintegrate
	// if(IsItemTypeSafebox(itemtype))
	// {
	// 	dbg("accounts", 1, "[LOGOUT] Player is holding a box.");
	// 	if(!IsContainerEmpty(GetItemExtraData(itemid)))
	// 	{
	// 		dbg("accounts", 1, "[LOGOUT] Player is holding an unempty box, dropping in world.");
	// 		CreateItemInWorld(itemid, x + floatsin(-r, degrees), y + floatcos(-r, degrees), z - FLOOR_OFFSET);
	// 		itemid = INVALID_ITEM_ID;
	// 		itemtype = INVALID_ITEM_TYPE;
	// 	}
	// }

	if(IsItemTypeBag(itemtype))
	{
		dbg("player", "player holding bag",
			_i("playerid", playerid));

		// TODO: reintegrate
		// if(!IsContainerEmpty(GetItemArrayDataAtCell(itemid, 1)))
		// {
		// 	if(IsValidItem(GetPlayerBagItem(playerid)))
		// 	{
		// 		dbg("accounts", 1, "[LOGOUT] Player is holding an unempty bag and is wearing one, dropping in world.");
		// 		CreateItemInWorld(itemid, x + floatsin(-r, degrees), y + floatcos(-r, degrees), z - FLOOR_OFFSET);
		// 		itemid = INVALID_ITEM_ID;
		// 		itemtype = INVALID_ITEM_TYPE;
		// 	}
		// 	else
		// 	{
		// 		dbg("accounts", 1, "[LOGOUT] Player is holding an unempty bag but is not wearing one, calling GivePlayerBag.");
		// 		GivePlayerBag(playerid, itemid);
		// 		itemid = INVALID_ITEM_ID;
		// 		itemtype = INVALID_ITEM_TYPE;
		// 	}
		// }
	}

	SavePlayerData(playerid);

	if(IsPlayerAlive(playerid))
	{
		DestroyItem(itemid);
		// DestroyItem(GetPlayerHolsterItem(playerid));
		DestroyPlayerBag(playerid);
		// RemovePlayerHolsterItem(playerid);
		// RemovePlayerWeapon(playerid);

		// TODO: update
		// for(new i; i < INV_MAX_SLOTS; i++) {
		// 	DestroyItem(GetInventorySlotItem(playerid, 0));
		// }
		// if(IsValidItem(GetPlayerHatItem(playerid))) {
		// 	RemovePlayerHatItem(playerid);
		// }

		// if(IsValidItem(GetPlayerMaskItem(playerid))) {
		// 	RemovePlayerMaskItem(playerid);
		// }

		// if(IsPlayerInAnyVehicle(playerid))
		// {
		// 	new
		// 		vehicleid = GetPlayerLastVehicle(playerid),
		// 		Float:health;

		// 	GetVehicleHealth(vehicleid, health);

		// 	if(IsVehicleUpsideDown(vehicleid) || health < 300.0)
		// 	{
		// 		DestroyVehicle(vehicleid);
		// 	}
		// 	else
		// 	{
		// 		if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
		// 			SetVehicleExternalLock(vehicleid, E_LOCK_STATE_OPEN);
		// 	}

		// 	UpdatePlayerVehicle(playerid, vehicleid);
		// }
	}

	return 1;
}


/*==============================================================================

	Updates the database and calls the binary save functions if required.

==============================================================================*/


SavePlayerData(playerid)
{
	dbg("player", "saving player data",
		_i("playerid", playerid));

	if(!LoggedIn[playerid])
	{
		dbg("player", "player is not logged in",
			_i("playerid", playerid));
		return 0;
	}

	// if(IsPlayerOnAdminDuty(playerid))
	// {
	// 	return 0;
	// }

	new
		Float:x,
		Float:y,
		Float:z,
		Float:r;

	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, r);

	// TODO: reintegrate
	// if(IsAtConnectionPos(x, y, z))
	// {
	// 	dbg("accounts", 1, "[SavePlayerData] ERROR: At connection pos");
	// 	return 0;
	// }
	// SaveBlockAreaCheck(x, y, z);

	if(IsPlayerInAnyVehicle(playerid)) {
		x += 1.5;
	}

	// if(IsPlayerAlive(playerid) && !IsPlayerInTutorial(playerid))
	// {
	// 	dbg("accounts", 2, "[SavePlayerData] Player is alive");
	// 	if(IsAtDefaultPos(x, y, z))
	// 	{
	// 		dbg("accounts", 2, "[SavePlayerData] ERROR: Player at default position");
	// 		return 0;
	// 	}

	// 	if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
	// 	{
	// 		dbg("accounts", 2, "[SavePlayerData] Player is spectating");
	// 		if(!gServerRestarting)
	// 		{
	// 			dbg("accounts", 2, "[SavePlayerData] Server is not restarting, aborting save");
	// 			return 0;
	// 		}
	// 	}

	// 	dbg("accounts", 2, "[SavePlayerData] Saving character data");
	// 	SavePlayerChar(playerid);
	// }
	// else
	// {
	// 	dbg("accounts", 2, "[SavePlayerData] Player is dead");
	// }

	return 1;
}


/*==============================================================================

	Interface functions

==============================================================================*/


// NewPlayer
stock bool:IsNewPlayer(playerid) {
	if(!IsPlayerConnected(playerid)) {
		return false;
	}

	return NewPlayer[playerid];
}

// HasAccount
stock bool:_IsPlayerRegistered(playerid) {
	if(!IsPlayerConnected(playerid)) {
		return false;
	}

	return HasAccount[playerid];
}

// LoggedIn
stock bool:IsPlayerLoggedIn(playerid) {
	if(!IsPlayerConnected(playerid)) {
		return false;
	}

	return LoggedIn[playerid];
}
