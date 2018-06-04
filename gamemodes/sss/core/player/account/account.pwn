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

#define MAX_ID_LEN (25)


static
	NewPlayer[MAX_PLAYERS],
	HasAccount[MAX_PLAYERS],
	Map:AccountLoadRequests;


forward OnPlayerLoadAccount(playerid);
forward OnPlayerAccountLoaded(playerid, loadresult);


LoadAccount(playerid) {
	if(CallLocalFunction("OnPlayerLoadAccount", "d", playerid)) {
		return;
	}

	defer LoadAccountDelay(playerid);
}
timer LoadAccountDelay[1000](playerid) {
	if(gServerInitialising || GetTickCountDifference(GetTickCount(), gServerInitialiseTick) < 5000) {
		defer LoadAccountDelay(playerid);
		return;
	}

	if(!IsPlayerConnected(playerid)) {
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
		"onAccountLoad"
	);
	MAP_insert_val_val(AccountLoadRequests, playerid, _:id);

	return;
}
forward onAccountLoad(Request:id, E_HTTP_STATUS:status, Node:node);
public onAccountLoad(Request:id, E_HTTP_STATUS:status, Node:node) {
	new playerid = MAP_get_val_val(AccountLoadRequests, _:id);

	new
		bool:success,
		message[256],
		Error:ret,
		result;
	ret = ParseStatus(node, success, message);
	if(ret) {
		err("failed to parse status");
		result = ACCOUNT_LOAD_RESULT_ERROR;
		Handled(ret);
	} else {
		if(success) {
			result = ACCOUNT_LOAD_RESULT_NO_EXIST;
		} else {
			ret = SetPlayerDataFromJSON(playerid, node);
			if(ret) {
				result = ACCOUNT_LOAD_RESULT_ERROR;
			} else {
				HasAccount[playerid] = true;
				result = ACCOUNT_LOAD_RESULT_EXIST;
			}
		}
	}

	CallLocalFunction("OnPlayerAccountLoaded", "dd", playerid, result);
}
Error:SetPlayerDataFromJSON(playerid, Node:node) {
	new bool:archived;
	JsonGetBool(node, FIELD_PLAYER_ARCHIVED, archived);
	if(archived) {
		return 0;
	}

	new
		id[MAX_ID_LEN],
		passHash[MAX_PASSWORD_LEN],
		bool:aliveState,
		regDateString[22],
		logDateString[22],
		Timestamp:regTimestamp,
		Timestamp:logTimestamp,
		totalSpawns,
		warnings;

	JsonGetString(node, FIELD_PLAYER_ID, id);
	JsonGetString(node, FIELD_PLAYER_PASS, passHash);
	JsonGetBool(node, FIELD_PLAYER_ALIVE, aliveState);
	JsonGetString(node, FIELD_PLAYER_REGDATE, regDateString);
	JsonGetString(node, FIELD_PLAYER_LASTLOG, logDateString);
	JsonGetInt(node, FIELD_PLAYER_TOTALSPAWNS, totalSpawns);
	JsonGetInt(node, FIELD_PLAYER_WARNINGS, warnings);

	TimeParse(regDateString, ISO6801_FULL_UTC, regTimestamp);
	TimeParse(logDateString, ISO6801_FULL_UTC, logTimestamp);

	SetPlayerID(playerid, id);
	SetPlayerPassHash(playerid, passHash);
	SetPlayerAliveState(playerid, aliveState);
	SetPlayerRegTimestamp(playerid, regTimestamp);
	SetPlayerLastLogin(playerid, logTimestamp);
	SetPlayerTotalSpawns(playerid, totalSpawns);
	SetPlayerWarnings(playerid, warnings);

	return 0;
}
