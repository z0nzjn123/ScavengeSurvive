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


Logout(playerid, docombatlogcheck = 1) {
	if(!IsPlayerLoggedIn(playerid)) {
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


SavePlayerData(playerid) {
	dbg("player", "saving player data",
		_i("playerid", playerid));

	if(!IsPlayerLoggedIn(playerid)) {
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
