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


static LoginAttempts[MAX_PLAYERS];


forward OnPlayerLogin(playerid);


hook OnPlayerConnect(playerid) {
	LoginAttempts[playerid] = 0;
}


DisplayLoginPrompt(playerid, badpass = 0) {
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
Dialog:LoginPrompt(playerid, response, listitem, inputtext[]) {
	dbg("player", "player responded to login dialog",
		_i("playerid", playerid),
		_i("response", response));

	if(!response) {
		ChatMsgAll(GREY, " >  %p left the server without logging in.", playerid);
		Kick(playerid);
	}

	if(strlen(inputtext) < 4) {
		LoginAttempts[playerid]++;

		if(LoginAttempts[playerid] < 5) {
			DisplayLoginPrompt(playerid, 1);
		} else {
			ChatMsgAll(GREY, " >  %p left the server without logging in.", playerid);
			Kick(playerid);
		}

		return;
	}

	new
		inputhash[MAX_PASSWORD_LEN],
		storedhash[MAX_PASSWORD_LEN];

	WP_Hash(inputhash, MAX_PASSWORD_LEN, inputtext);
	GetPlayerPassHash(playerid, storedhash);

	if(!strcmp(inputhash, storedhash)) {
		Login(playerid);
	}
	else {
		LoginAttempts[playerid]++;

		if(LoginAttempts[playerid] < 5) {
			DisplayLoginPrompt(playerid, 1);
		}
		else {
			ChatMsgAll(GREY, " >  %p left the server without logging in.", playerid);
			Kick(playerid);
		}

		return;
	}

	return;
}

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
		_i("playerid", playerid));

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

	LoginAttempts[playerid] = 0;

	SetPlayerRadioFrequency(playerid, 107.0);
	// TODO: reintegrate or use kristoisberg/screen-colour-fader
	// SetPlayerBrightness(playerid, 255);

	CallLocalFunction("OnPlayerLogin", "d", playerid);
}
