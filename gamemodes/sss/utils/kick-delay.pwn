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


static bool:kicked[MAX_PLAYERS];

forward OnPlayerTimedOut(playerid);
forward OnPlayerKicked(playerid);


TimeoutPlayer(playerid, reason[]) {
	if(!IsPlayerConnected(playerid)) {
		return 1;
	}

	if(kicked[playerid]) {
		return 2;
	}

	new ip[16];

	GetPlayerIp(playerid, ip, sizeof(ip));

	BlockIpAddress(ip, 11500);
	kicked[playerid] = true;

	CallLocalFunction("OnPlayerTimedOut", "d", playerid);

	log("player timed out",
		_i("playerid", playerid),
		_s("reason", reason));

	return 0;
}

KickPlayer(playerid, reason[], bool:tellplayer = true) {
	if(!IsPlayerConnected(playerid)) {
		return 1;
	}

	if(kicked[playerid]) {
		return 2;
	}

	defer KickPlayerDelay(playerid);
	kicked[playerid] = true;

	if(tellplayer) {
		ChatMsgLang(playerid, GREY, "KICKMESSAGE", reason);
	}

	CallLocalFunction("OnPlayerKicked", "d", playerid);

	log("player kicked",
		_i("playerid", playerid),
		_s("reason", reason));

	return 0;
}

timer KickPlayerDelay[1000](playerid) {
	Kick(playerid);
	kicked[playerid] = false;
}
