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


#define DEFAULT_POS_X (10000.0)
#define DEFAULT_POS_Y (10000.0)
#define DEFAULT_POS_Z (1.0)


enum E_PLAYER_DATA {
			// Database Account Data
			ply_ID[MAX_ID_LEN],
			ply_Password[MAX_PASSWORD_LEN],
			ply_IP,
Timestamp:	ply_RegisterTimestamp,
Timestamp:	ply_LastLogin,
			ply_TotalSpawns,
			ply_Warnings,

			// Character Data
bool:		ply_Alive,
Float:		ply_HitPoints,
Float:		ply_ArmourPoints,
Float:		ply_FoodPoints,
			ply_Clothes,
			ply_Gender,
Float:		ply_Velocity,
			ply_CreationTimestamp,

			// Internal Data
			// TODO: move this elsewhere
			ply_ShowHUD,
			ply_PingLimitStrikes,
			ply_stance,
			ply_JoinTick,
			ply_SpawnTick
}

static
	NewPlayer[MAX_PLAYERS],
	HasAccount[MAX_PLAYERS],
	LoggedIn[MAX_PLAYERS],
	PlayerData[MAX_PLAYERS][E_PLAYER_DATA];


forward OnPlayerScriptUpdate(playerid);
forward OnPlayerDisconnected(playerid);
forward OnDeath(playerid, killerid, reason);


// -
// Connect
// -


public OnPlayerConnect(playerid)
{
	log("player connected",
		_i("playerid", playerid));

	SetPlayerColor(playerid, 0xB8B8B800);

	if(IsPlayerNPC(playerid)) {
		return 1;
	}

	ResetVariables(playerid);

	PlayerData[playerid][ply_JoinTick] = GetTickCount();

	new
		ipstring[16],
		ipbyte[4];

	GetPlayerIp(playerid, ipstring, 16);

	sscanf(ipstring, "p<.>a<d>[4]", ipbyte);
	PlayerData[playerid][ply_IP] = ((ipbyte[0] << 24) | (ipbyte[1] << 16) | (ipbyte[2] << 8) | ipbyte[3]);

	TogglePlayerControllable(playerid, false);
	Streamer_ToggleIdleUpdate(playerid, true);
	SetSpawnInfo(playerid, NO_TEAM, 0, DEFAULT_POS_X, DEFAULT_POS_Y, DEFAULT_POS_Z, 0.0, 0, 0, 0, 0, 0, 0);
	SpawnPlayer(playerid);

	/*
	If you have any respect for me or my work that I do completely free:
	DO NOT REMOVE THIS MESSAGE.
	It's just one line of text that appears when a player joins.
	Feel free to add your own message UNDER this one with information regarding
	your own modifications you've made to the code but DO NOT REMOVE THIS!

	Thank you :)
	*/
	ChatMsg(playerid, ORANGE, "Scavenge and Survive "C_BLUE"(Copyright (C) 2017 Barnaby \"Southclaw\" Keene)");
	ChatMsgAll(WHITE, " >  %P (%d)"C_WHITE" has joined", playerid, playerid);
	ChatMsg(playerid, YELLOW, " >  MoTD: "C_BLUE"%s", gMessageOfTheDay);

	PlayerData[playerid][ply_ShowHUD] = true;

	LoadAccount(playerid); // OnPlayerAccountLoaded

	return 1;
}

public OnPlayerAccountLoaded(playerid, loadresult)
{
	dbg("player", "player account loaded",
		_i("playerid", playerid),
		_i("loadresult", loadresult));

	// LoadAccount aborted, kick player.
	if(loadresult == ACCOUNT_LOAD_RESULT_ERROR) {
		// TODO: reintegrate
		// KickPlayer(playerid, "Account load failed");
		Kick(playerid);
		return;
	}

	// Account does not exist
	if(loadresult == ACCOUNT_LOAD_RESULT_NO_EXIST) {
		HasAccount[playerid] = true;
		NewPlayer[playerid] = true;
		DisplayRegisterPrompt(playerid);
	}

	// Account does exist, prompt login
	if(loadresult == ACCOUNT_LOAD_RESULT_EXIST) {
		DisplayLoginPrompt(playerid);
	}

	// Account does exist, auto login
	if(loadresult == ACCOUNT_LOAD_RESULT_EXIST_AL) {
		Login(playerid);
	}

	// Account does exist, but not in whitelist
	if(loadresult == ACCOUNT_LOAD_RESULT_EXIST_WL) {
		// TODO: reintegrate
		// WhitelistKick(playerid);
		Kick(playerid);
	}

	// Account does exists, but is disabled
	if(loadresult == ACCOUNT_LOAD_RESULT_EXIST_DA) {
		// TODO: reintegrate
		// KickPlayer(playerid, "Account inactive");
		Kick(playerid);
	}

	return;
}

hook OnPlayerRegister(playerid) {
	return 0;
}

hook OnPlayerLoggedIn(playerid) {
	LoggedIn[playerid] = true;
}


// -
// Disconnect
// -


public OnPlayerDisconnect(playerid, reason) {
	if(gServerRestarting) {
		return 0;
	}

	Logout(playerid);

	switch(reason) {
		case 0: {
			ChatMsgAll(GREY, " >  %p lost connection.", playerid);
			log("player lost connection",
				_i("playerid", playerid));
		} case 1: {
			ChatMsgAll(GREY, " >  %p left the server.", playerid);
			log("player quit",
				_i("playerid", playerid));
		}
	}

	SetTimerEx("OnPlayerDisconnected", 100, false, "dd", playerid, reason);

	return 1;
}

hook OnPlayerDisconnected(playerid) {
	ResetVariables(playerid);
}

ResetVariables(playerid) {
	PlayerData[playerid][ply_Password][0]			= EOS;
	PlayerData[playerid][ply_IP]					= 0;
	PlayerData[playerid][ply_Warnings]			= 0;

	PlayerData[playerid][ply_Alive]				= false;
	PlayerData[playerid][ply_HitPoints]			= 100.0;
	PlayerData[playerid][ply_ArmourPoints]		= 0.0;
	PlayerData[playerid][ply_FoodPoints]			= 80.0;
	PlayerData[playerid][ply_Clothes]				= 0;
	PlayerData[playerid][ply_Gender]				= 0;
	PlayerData[playerid][ply_Velocity]			= 0.0;

	PlayerData[playerid][ply_PingLimitStrikes]	= 0;
	PlayerData[playerid][ply_stance]				= 0;
	PlayerData[playerid][ply_JoinTick]			= 0;
	PlayerData[playerid][ply_SpawnTick]			= 0;

	SetPlayerSkillLevel(playerid, WEAPONSKILL_PISTOL,			100);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN,	100);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_MICRO_UZI,		100);

	for(new i; i < 10; i++) {
		RemovePlayerAttachedObject(playerid, i);
	}
}

ptask PlayerUpdateFast[100](playerid)
{
	new pinglimit = (Iter_Count(Player) > 10) ? (gPingLimit) : (gPingLimit + 100);

	if(GetPlayerPing(playerid) > pinglimit)
	{
		if(GetTickCountDifference(GetTickCount(), PlayerData[playerid][ply_JoinTick]) > 10000)
		{
			PlayerData[playerid][ply_PingLimitStrikes]++;

			if(PlayerData[playerid][ply_PingLimitStrikes] == 30)
			{
				// TODO: reintegrate
				// KickPlayer(playerid, sprintf("Having a ping of: %d limit: %d.", GetPlayerPing(playerid), pinglimit));
				Kick(playerid);

				PlayerData[playerid][ply_PingLimitStrikes] = 0;

				return;
			}
		}
	}
	else
	{
		PlayerData[playerid][ply_PingLimitStrikes] = 0;
	}

	// TODO: update
	// if(NetStats_MessagesRecvPerSecond(playerid) > 200)
	// {
	// 	ChatMsgAdmins(3, YELLOW, " >  %p sending %d messages per second.", playerid, NetStats_MessagesRecvPerSecond(playerid));
	// 	return;
	// }

	// TODO: reintegrate
	// if(!IsPlayerSpawned(playerid))
	// 	return;

	// TODO: reintegrate
	// if(IsPlayerInAnyVehicle(playerid))
	// {
	// 	PlayerVehicleUpdate(playerid);
	// }
	// else
	// {
	// 	if(!gVehicleSurfing)
	// 		VehicleSurfingCheck(playerid);
	// }

	// TODO: reintegrate
	// PlayerBagUpdate(playerid);

	// TODO: reintegrate
	// new
	// 	hour,
	// 	minute;

	// // Get player's own time data
	// GetTimeForPlayer(playerid, hour, minute);

	// // If it's -1, just use the default instead.
	// if(hour == -1 || minute == -1)
	// 	gettime(hour, minute);

	// SetPlayerTime(playerid, hour, minute);

	return;
}

ptask PlayerUpdateSlow[1000](playerid)
{
	CallLocalFunction("OnPlayerScriptUpdate", "d", playerid);
}

public OnPlayerRequestClass(playerid, classid)
{
	if(IsPlayerNPC(playerid))return 1;

	SetSpawnInfo(playerid, NO_TEAM, 0, DEFAULT_POS_X, DEFAULT_POS_Y, DEFAULT_POS_Z, 0.0, 0, 0, 0, 0, 0, 0);

	return 0;
}

public OnPlayerRequestSpawn(playerid)
{
	if(IsPlayerNPC(playerid))return 1;

	SetSpawnInfo(playerid, NO_TEAM, 0, DEFAULT_POS_X, DEFAULT_POS_Y, DEFAULT_POS_Z, 0.0, 0, 0, 0, 0, 0, 0);

	return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
	if(clickedid == Text:65535)
	{
		// TODO: reintegrate
		// if(IsPlayerDead(playerid))
		// {
		// 	SelectTextDraw(playerid, 0xFFFFFF88);
		// }
		// else
		// {
		// 	// TODO: reintegrate
		// 	// ShowWatch(playerid);
		// }
	}

	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(IsPlayerNPC(playerid))
		return 1;

	// TODO: reintegrate
	// if(IsPlayerOnAdminDuty(playerid))
	// {
	// 	SetPlayerPos(playerid, 0.0, 0.0, 3.0);
	// 	return 1;
	// }

	PlayerData[playerid][ply_SpawnTick] = GetTickCount();

	SetAllWeaponSkills(playerid, 500);
	SetPlayerTeam(playerid, 0);
	ResetPlayerMoney(playerid);

	PlayerPlaySound(playerid, 1186, 0.0, 0.0, 0.0);
	PreloadPlayerAnims(playerid);
	SetAllWeaponSkills(playerid, 500);
	Streamer_Update(playerid);

	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(IsPlayerInAnyVehicle(playerid))
	{
		// TODO: reintegrate
		// static
		// 	str[8],
		// 	Float:vx,
		// 	Float:vy,
		// 	Float:vz;

		// GetVehicleVelocity(GetPlayerLastVehicle(playerid), vx, vy, vz);
		// PlayerData[playerid][ply_Velocity] = floatsqroot( (vx*vx)+(vy*vy)+(vz*vz) ) * 150.0;
		// format(str, 32, "%.0fkm/h", PlayerData[playerid][ply_Velocity]);
		// SetPlayerVehicleSpeedUI(playerid, str);
	}
	else
	{
		static
			Float:vx,
			Float:vy,
			Float:vz;

		GetPlayerVelocity(playerid, vx, vy, vz);
		PlayerData[playerid][ply_Velocity] = floatsqroot( (vx*vx)+(vy*vy)+(vz*vz) ) * 150.0;
	}

	if(PlayerData[playerid][ply_Alive])
	{
		// TODO: reintegrate
		// if(IsPlayerOnAdminDuty(playerid))
		// 	PlayerData[playerid][ply_HitPoints] = 250.0;

		SetPlayerHealth(playerid, PlayerData[playerid][ply_HitPoints]);
		SetPlayerArmour(playerid, PlayerData[playerid][ply_ArmourPoints]);
	}
	else
	{
		SetPlayerHealth(playerid, 100.0);		
	}

	return 1;
}

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER)
	{
		ShowPlayerDialog(playerid, -1, DIALOG_STYLE_MSGBOX, " ", " ", " ", " ");
		// TODO: reintegrate
		// HidePlayerGear(playerid);
	}

	return 1;
}

hook OnPlayerEnterVehicle(playerid, vehicleid, ispassenger) {
	// TODO: reintegrate
	// if(IsPlayerKnockedOut(playerid))
	// 	return 0;

	if(GetPlayerSurfingVehicleID(playerid) == vehicleid) {
		CancelPlayerMovement(playerid);
	}

	if(ispassenger) {
		new driverid = -1;

		foreach(new i : Player) {
			if(IsPlayerInVehicle(i, vehicleid)) {
				if(GetPlayerState(i) == PLAYER_STATE_DRIVER) {
					driverid = i;
				}
			}
		}

		if(driverid == -1) {
			CancelPlayerMovement(playerid);
		}
	}

	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	// TODO: reintegrate
	// if(IsPlayerKnockedOut(playerid))
	// 	return 0;

	if(!IsPlayerInAnyVehicle(playerid))
	{
		// TODO: reintegrate
		// new weaponid = GetItemTypeWeaponBaseWeapon(GetItemType(GetPlayerItem(playerid)));

		// if(weaponid == 34 || weaponid == 35 || weaponid == 43)
		// {
		// 	if(newkeys & 128)
		// 	{
		// 		TogglePlayerHatItemVisibility(playerid, false);
		// 		TogglePlayerMaskItemVisibility(playerid, false);
		// 	}
		// 	if(oldkeys & 128)
		// 	{
		// 		TogglePlayerHatItemVisibility(playerid, true);
		// 		TogglePlayerMaskItemVisibility(playerid, true);
		// 	}
		// }
	}

	return 1;
}

KillPlayer(playerid, killerid, deathreason)
{
	CallLocalFunction("OnDeath", "ddd", playerid, killerid, deathreason);
}

// ply_ID
stock GetPlayerID(playerid, id[MAX_ID_LEN])
{
	if(!IsPlayerConnected(playerid))
		return 0;

	string[0] = EOS;
	strcat(id, PlayerData[playerid][ply_ID]);

	return 1;

}

stock SetPlayerID(playerid, id[MAX_ID_LEN])
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_ID] = id;

	return 1;
}


// ply_Password
stock GetPlayerPassHash(playerid, string[MAX_PASSWORD_LEN])
{
	if(!IsPlayerConnected(playerid))
		return 0;

	string[0] = EOS;
	strcat(string, PlayerData[playerid][ply_Password]);

	return 1;
}

stock SetPlayerPassHash(playerid, string[MAX_PASSWORD_LEN])
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_Password] = string;

	return 1;
}

// ply_IP
stock GetPlayerIpAsInt(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_IP];
}

// ply_RegisterTimestamp
stock Timestamp:GetPlayerRegTimestamp(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_RegisterTimestamp];
}

stock SetPlayerRegTimestamp(playerid, Timestamp:timestamp)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_RegisterTimestamp] = timestamp;

	return 1;
}

// ply_LastLogin
stock Timestamp:GetPlayerLastLogin(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_LastLogin];
}

stock SetPlayerLastLogin(playerid, Timestamp:timestamp)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_LastLogin] = timestamp;

	return 1;
}

// ply_TotalSpawns
stock GetPlayerTotalSpawns(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_TotalSpawns];
}

stock SetPlayerTotalSpawns(playerid, amount)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_TotalSpawns] = amount;

	return 1;
}

// ply_Warnings
stock GetPlayerWarnings(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_Warnings];
}

stock SetPlayerWarnings(playerid, timestamp)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_Warnings] = timestamp;

	return 1;
}

// ply_Alive
stock IsPlayerAlive(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_Alive];
}

stock SetPlayerAliveState(playerid, bool:st)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_Alive] = st;

	return 1;
}

// ply_ShowHUD
stock IsPlayerHudOn(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_ShowHUD];
}

stock TogglePlayerHUD(playerid, bool:st)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_ShowHUD] = st;

	return 1;
}

// ply_HitPoints
forward Float:GetPlayerHP(playerid);
stock Float:GetPlayerHP(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0.0;

	return PlayerData[playerid][ply_HitPoints];
}

stock SetPlayerHP(playerid, Float:hp)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	if(hp > 100.0)
		hp = 100.0;

	PlayerData[playerid][ply_HitPoints] = hp;

	return 1;
}

// ply_ArmourPoints
forward Float:GetPlayerAP(playerid);
stock Float:GetPlayerAP(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0.0;

	return PlayerData[playerid][ply_ArmourPoints];
}

stock SetPlayerAP(playerid, Float:amount)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_ArmourPoints] = amount;

	return 1;
}

// ply_FoodPoints
forward Float:GetPlayerFP(playerid);
stock Float:GetPlayerFP(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0.0;

	return PlayerData[playerid][ply_FoodPoints];
}

stock SetPlayerFP(playerid, Float:food)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_FoodPoints] = food;

	return 1;
}

// ply_Clothes
stock GetPlayerClothesID(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_Clothes];
}

stock SetPlayerClothesID(playerid, id)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_Clothes] = id;

	return 1;
}

// ply_Gender
stock GetPlayerGender(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_Gender];
}

stock SetPlayerGender(playerid, gender)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_Gender] = gender;

	return 1;
}

// ply_Velocity
forward Float:GetPlayerTotalVelocity(playerid);
Float:GetPlayerTotalVelocity(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0.0;

	return PlayerData[playerid][ply_Velocity];
}

// ply_CreationTimestamp
stock GetPlayerCreationTimestamp(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_CreationTimestamp];
}

stock SetPlayerCreationTimestamp(playerid, timestamp)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_CreationTimestamp] = timestamp;

	return 1;
}

// ply_PingLimitStrikes
// ply_stance
stock GetPlayerStance(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_stance];
}

stock SetPlayerStance(playerid, stance)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	PlayerData[playerid][ply_stance] = stance;

	return 1;
}

// ply_JoinTick
stock GetPlayerServerJoinTick(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_JoinTick];
}

// ply_SpawnTick
stock GetPlayerSpawnTick(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	return PlayerData[playerid][ply_SpawnTick];
}

// LoggedIn
IsPlayerLoggedIn(playerid) {
	if(!IsPlayerConnected(playerid)) {
		return false;
	}

	return LoggedIn[playerid];
}

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
