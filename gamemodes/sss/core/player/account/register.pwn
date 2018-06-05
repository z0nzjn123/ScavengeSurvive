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


static Map:AccountCreateRequests;


forward OnAccountCreate(Request:id, E_HTTP_STATUS:status, Node:node);
forward OnPlayerRegister(playerid);


forward Error:CreateAccount(playerid, pass[]);
DisplayRegisterPrompt(playerid) {
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
Dialog:RegisterPrompt(playerid, response, listitem, inputtext[]) {
	dbg("player", "player responded to register dialog",
		_i("playerid", playerid),
		_i("response", response));

	if(response) {
		if(!(4 <= strlen(inputtext) <= 32)) {
			ChatMsgLang(playerid, YELLOW, "PASSWORDREQ");
			DisplayRegisterPrompt(playerid);
			return 0;
		}

		new buffer[MAX_PASSWORD_LEN];
		WP_Hash(buffer, MAX_PASSWORD_LEN, inputtext);
		new Error:e = CreateAccount(playerid, buffer);
		if(IsError(e)) {
			ShowErrorDialog(playerid);
			Handled();
		}
	} else {
		ChatMsgAll(GREY, " >  %p left the server without registering.", playerid);
		Kick(playerid);
	}

	return 0;
}
Error:CreateAccount(playerid, pass[]) {
	new
		name[MAX_PLAYER_NAME],
		ipv4[16],
		nowString[21],
		hash[MAX_GPCI_LEN];

	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	GetPlayerIp(playerid, ipv4, 16);
	gpci(playerid, hash, MAX_GPCI_LEN);

	TimeFormat(Now(), ISO6801_FULL_UTC, nowString);

	new Request:id = RequestJSON(
		Store,
		"/store/playerCreate",
		HTTP_METHOD_POST,
		"OnAccountCreate",
		JsonObject(
			FIELD_PLAYER_NAME, JsonString(name),
			FIELD_PLAYER_PASS, JsonString(pass),
			FIELD_PLAYER_IPV4, JsonString(ipv4),
			FIELD_PLAYER_ALIVE, JsonBool(true),
			FIELD_PLAYER_REGDATE, JsonString(nowString),
			FIELD_PLAYER_LASTLOG, JsonString(nowString),
			FIELD_PLAYER_TOTALSPAWNS, JsonInt(0),
			FIELD_PLAYER_WARNINGS, JsonInt(0),
			FIELD_PLAYER_GPCI, JsonString(hash),
			FIELD_PLAYER_ARCHIVED, JsonBool(false)
		)
	);
	if(id == Request:-1) {
		return Error(1, "failed to send create account request");
	}

	MAP_insert_val_val(AccountCreateRequests, playerid, _:id);

	return NoError();
}
public OnAccountCreate(Request:id, E_HTTP_STATUS:status, Node:node) {
	new playerid = MAP_get_val_val(AccountCreateRequests, _:id);
	if(!IsPlayerConnected(playerid)) {
		dbg("player", "ignoring response for non-connected player",
			_i("playerid", playerid));
		return;
	}

	new
		bool:success,
		Node:result,
		message[256],
		Error:e;
	e = ParseStatus(node, success, result, message);
	if(IsError(e)) {
		err("failed to parse status",
			_i("playerid", playerid));
		ShowErrorDialog(playerid);
		return;
	}

	if(!success) {
		err("failed to create account",
			_s("message", message),
			_i("playerid", playerid));
		KickPlayer(playerid, "Account creation failed");
		return;
	}

	Login(playerid);

	// TODO: reintegrate/move to events
	// SetPlayerToolTips(playerid, true);

	ShowWelcomeMessage(playerid, 10);
	CallLocalFunction("OnPlayerRegister", "d", playerid);
}
