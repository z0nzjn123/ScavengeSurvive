/*==============================================================================


	Southclaw's Scavenge and Survive

		Copyright (C) 2016 Barnaby "Southclaw" Keene

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


#include <YSI_Coding\y_hooks>


#define MAX_TENT			(2048)
#define MAX_TENT_ITEMS		(16)
#define INVALID_TENT_ID		(-1)
#define DIRECTORY_TENT		DIRECTORY_MAIN"tent/"


enum E_TENT_DATA
{
			tnt_itemId,
			tnt_containerId
}

enum E_TENT_OBJECT_DATA
{
			tnt_objSideR1,
			tnt_objSideR2,
			tnt_objSideL1,
			tnt_objSideL2,
			tnt_objPoleF,
			tnt_objPoleB
}

static
			tnt_Data[MAX_TENT][E_TENT_DATA],
			tnt_ObjData[MAX_TENT][E_TENT_OBJECT_DATA],
			tnt_ContainerTent[CNT_MAX] = {INVALID_ITEM_ID, ...},
			tnt_CurrentTentItem[MAX_PLAYERS];

new
   Iterator:tnt_Index<MAX_TENT>;


forward OnTentCreate(tentid);
forward OnTentDestroy(tentid);
forward _tent_onLoad(itemid, active, geid[], data[], length);


/*==============================================================================

	Zeroing

==============================================================================*/


hook OnScriptInit()
{
	DirectoryCheck(DIRECTORY_SCRIPTFILES DIRECTORY_TENT);
}

hook OnGameModeInit()
{
	LoadItems(DIRECTORY_TENT, "_tent_onLoad");
}

hook OnPlayerConnect(playerid)
{
	tnt_CurrentTentItem[playerid] = INVALID_ITEM_ID;
}

hook OnItemTypeDefined(uname[])
{
	if(!strcmp(uname, "TentPack"))
		SetItemTypeMaxArrayData(GetItemTypeFromUniqueName("TentPack"), 1);
}

hook OnItemCreated(itemid)
{
	if(GetItemType(itemid) == item_TentPack)
	{
		SetItemExtraData(itemid, INVALID_TENT_ID);
	}
}


/*==============================================================================

	Core

==============================================================================*/


stock CreateTentFromItem(itemid)
{
	if(GetItemType(itemid) != item_TentPack)
	{
		err("Attempted to create tent from non-tentpack item %d type: %d", itemid, _:GetItemType(itemid));
		return -1;
	}

	new id = Iter_Free(tnt_Index);

	if(id == -1)
	{
		err("MAX_TENT limit reached.");
		return -1;
	}

	Iter_Add(tnt_Index, id);

	new
		Float:x,
		Float:y,
		Float:z,
		Float:rz,
		worldid = GetItemWorld(itemid),
		interiorid = GetItemInterior(itemid);

	GetItemPos(itemid, x, y, z);
	GetItemRot(itemid, rz, rz, rz);

	z += 0.4;
	rz += 90.0;

	tnt_Data[id][tnt_itemId] = itemid;
	tnt_Data[id][tnt_containerId] = CreateContainer("Tent", MAX_TENT_ITEMS);
	tnt_ContainerTent[tnt_Data[id][tnt_containerId]] = id;

	SetItemExtraData(itemid, id);

	tnt_ObjData[id][tnt_objSideR1] = CreateDynamicObject(19477,
		x + (0.49 * floatsin(-rz + 270.0, degrees)),
		y + (0.49 * floatcos(-rz + 270.0, degrees)),
		z,
		0.0, 45.0, rz, worldid, interiorid, .streamdistance = 100.0);

	tnt_ObjData[id][tnt_objSideR2] = CreateDynamicObject(19477,
		x + (0.48 * floatsin(-rz + 270.0, degrees)),
		y + (0.48 * floatcos(-rz + 270.0, degrees)),
		z,
		0.0, 45.0, rz, worldid, interiorid, .streamdistance = 20.0);

	tnt_ObjData[id][tnt_objSideL1] = CreateDynamicObject(19477,
		x + (0.49 * floatsin(-rz + 90.0, degrees)),
		y + (0.49 * floatcos(-rz + 90.0, degrees)),
		z,
		0.0, -45.0, rz, worldid, interiorid, .streamdistance = 100.0);

	tnt_ObjData[id][tnt_objSideL2] = CreateDynamicObject(19477,
		x + (0.48 * floatsin(-rz + 90.0, degrees)),
		y + (0.48 * floatcos(-rz + 90.0, degrees)),
		z,
		0.0, -45.0, rz, worldid, interiorid, .streamdistance = 20.0);

	tnt_ObjData[id][tnt_objPoleF] = CreateDynamicObject(19087,
		x + (1.3 * floatsin(-rz, degrees)),
		y + (1.3 * floatcos(-rz, degrees)),
		z + 0.48,
		0.0, 0.0, rz, worldid, interiorid, .streamdistance = 10.0);

	tnt_ObjData[id][tnt_objPoleB] = CreateDynamicObject(19087,
		x - (1.3 * floatsin(-rz, degrees)),
		y - (1.3 * floatcos(-rz, degrees)),
		z + 0.48,
		0.0, 0.0, rz, worldid, interiorid, .streamdistance = 10.0);

	SetDynamicObjectMaterial(tnt_ObjData[id][tnt_objSideR1], 0, 2068, "cj_ammo_net", "CJ_cammonet", 0);
	SetDynamicObjectMaterial(tnt_ObjData[id][tnt_objSideR2], 0, 3095, "a51jdrx", "sam_camo", 0);
	SetDynamicObjectMaterial(tnt_ObjData[id][tnt_objSideL1], 0, 2068, "cj_ammo_net", "CJ_cammonet", 0);
	SetDynamicObjectMaterial(tnt_ObjData[id][tnt_objSideL2], 0, 3095, "a51jdrx", "sam_camo", 0);
	SetDynamicObjectMaterial(tnt_ObjData[id][tnt_objPoleF], 0, 1270, "signs", "lamppost", 0);
	SetDynamicObjectMaterial(tnt_ObjData[id][tnt_objPoleB], 0, 1270, "signs", "lamppost", 0);

	CallLocalFunction("OnTentCreate", "d", id);

	return id;
}

stock DestroyTent(tentid)
{
	if(!Iter_Contains(tnt_Index, tentid))
		return 0;

	CallLocalFunction("OnTentDestroy", "d", tentid);
	_tent_Remove(tentid);

	SetItemExtraData(tnt_Data[tentid][tnt_itemId], INVALID_TENT_ID);
	DestroyContainer(tnt_Data[tentid][tnt_containerId]);

	DestroyDynamicObject(tnt_ObjData[tentid][tnt_objSideR1]);
	DestroyDynamicObject(tnt_ObjData[tentid][tnt_objSideR2]);
	DestroyDynamicObject(tnt_ObjData[tentid][tnt_objSideL1]);
	DestroyDynamicObject(tnt_ObjData[tentid][tnt_objSideL2]);
	DestroyDynamicObject(tnt_ObjData[tentid][tnt_objPoleF]);
	DestroyDynamicObject(tnt_ObjData[tentid][tnt_objPoleB]);
	tnt_ObjData[tentid][tnt_objSideR1] = INVALID_OBJECT_ID;
	tnt_ObjData[tentid][tnt_objSideR2] = INVALID_OBJECT_ID;
	tnt_ObjData[tentid][tnt_objSideL1] = INVALID_OBJECT_ID;
	tnt_ObjData[tentid][tnt_objSideL2] = INVALID_OBJECT_ID;
	tnt_ObjData[tentid][tnt_objPoleF] = INVALID_OBJECT_ID;
	tnt_ObjData[tentid][tnt_objPoleB] = INVALID_OBJECT_ID;

	Iter_SafeRemove(tnt_Index, tentid, tentid);

	return tentid;
}

SaveTent(tentid, bool:active = true)
{
	dbg("gamemodes/sss/extensions/tent-io.pwn", 1, "[SaveTent] %d %d", tentid, active);

	if(!Iter_Contains(tnt_Index, tentid))
	{
		dbg("gamemodes/sss/extensions/tent-io.pwn", 2, "[SaveTent] ERROR: Attempted to save tent ID %d active: %d that was not found in index.", tentid, active);
		return 1;
	}

	new
		itemid = GetTentItem(tentid),
		containerid = GetTentContainer(tentid);

	if(IsContainerEmpty(containerid))
	{
		dbg("gamemodes/sss/extensions/tent-io.pwn", 1, "[SaveTent] Empty, removing");
		RemoveSavedItem(itemid, DIRECTORY_TENT);
		return 2;
	}

	new geid[GEID_LEN];

	GetItemGEID(itemid, geid);

	if(!IsValidContainer(containerid))
	{
		err("Can't save tent %d (%s): Not valid container (%d).", itemid, geid, containerid);
		return 3;
	}

	new
		items[MAX_TENT_ITEMS],
		itemcount = GetContainerItemCount(containerid);

	for(new i; i < itemcount; i++)
		items[i] = GetContainerSlotItem(containerid, i);

	if(!SerialiseItems(items, itemcount))
	{
		SaveWorldItem(itemid, DIRECTORY_TENT, active, false, itm_arr_Serialized, GetSerialisedSize());
		ClearSerializer();
	}

	return 0;
}

public _tent_onLoad(itemid, active, geid[], data[], length)
{
	new
		tentid,
		containerid,
		ItemType:itemtype,
		subitem;

	tentid = CreateTentFromItem(itemid);
	containerid = GetTentContainer(tentid);

	if(!DeserialiseItems(data, length))
	{
		for(new i, j = GetStoredItemCount(); i < j; i++)
		{
			itemtype = GetStoredItemType(i);

			if(length == 0)
				break;

			if(itemtype == INVALID_ITEM_TYPE)
				break;

			if(itemtype == ItemType:0)
				break;

			subitem = CreateItem(itemtype);

			if(!IsItemTypeSafebox(itemtype) && !IsItemTypeBag(itemtype))
				SetItemArrayDataFromStored(subitem, i);

			AddItemToContainer(containerid, subitem);
		}

		ClearSerializer();
	}

	return 1;
}


/*==============================================================================

	Internal functions and hooks

==============================================================================*/


_tent_Remove(tentid)
{
	RemoveSavedItem(GetTentItem(tentid), DIRECTORY_TENT);
}

hook OnItemAddedToContainer(containerid, itemid, playerid)
{
	if(gServerInitialising)
		return Y_HOOKS_CONTINUE_RETURN_0;

	SaveTent(GetContainerTent(containerid));

	return Y_HOOKS_CONTINUE_RETURN_0;
}

hook OnItemRemovedFromCnt(containerid, slotid, playerid)
{
	if(gServerInitialising)
		return Y_HOOKS_CONTINUE_RETURN_0;

	SaveTent(GetContainerTent(containerid));

	return Y_HOOKS_CONTINUE_RETURN_0;
}

hook OnPlayerPickUpItem(playerid, itemid)
{
	if(GetItemType(itemid) == item_TentPack)
	{
		new tentid = GetItemExtraData(itemid);

		if(IsValidTent(tentid))
		{
			DisplayContainerInventory(playerid, tnt_Data[tentid][tnt_containerId]);
			return Y_HOOKS_BREAK_RETURN_1;
		}
	}

	return Y_HOOKS_CONTINUE_RETURN_0;
}

hook OnPlayerUseItemWithItem(playerid, itemid, withitemid)
{
	if(GetItemType(withitemid) == item_TentPack)
	{
		new tentid = GetItemArrayDataAtCell(withitemid, 0);

		if(!IsValidTent(tentid))
		{
			if(GetItemType(itemid) == item_Hammer)
			{
				StartBuildingTent(playerid, withitemid);
				return Y_HOOKS_BREAK_RETURN_1;
			}
		}
		else
		{
			if(GetItemType(itemid) == item_Crowbar)
			{
				StartRemovingTent(playerid, withitemid);
				return Y_HOOKS_BREAK_RETURN_1;
			}
			else
			{
				DisplayContainerInventory(playerid, tnt_Data[tentid][tnt_containerId]);
				return Y_HOOKS_BREAK_RETURN_1;
			}
		}
	}

	return Y_HOOKS_CONTINUE_RETURN_0;
}

StartBuildingTent(playerid, itemid)
{
	StartHoldAction(playerid, 10000);
	ApplyAnimation(playerid, "BOMBER", "BOM_Plant_Loop", 4.0, 1, 0, 0, 0, 0);
	ShowActionText(playerid, ls(playerid, "TENTBUILD", true));
	tnt_CurrentTentItem[playerid] = itemid;
}

StopBuildingTent(playerid)
{
	if(tnt_CurrentTentItem[playerid] == INVALID_ITEM_ID)
		return;

	StopHoldAction(playerid);
	ClearAnimations(playerid);
	HideActionText(playerid);
	tnt_CurrentTentItem[playerid] = INVALID_ITEM_ID;

	return;
}

StartRemovingTent(playerid, itemid)
{
	StartHoldAction(playerid, 15000);
	ApplyAnimation(playerid, "BOMBER", "BOM_Plant_Loop", 4.0, 1, 0, 0, 0, 0);
	ShowActionText(playerid, ls(playerid, "TENTREMOVE"));
	tnt_CurrentTentItem[playerid] = itemid;
}

StopRemovingTent(playerid)
{
	if(tnt_CurrentTentItem[playerid] == INVALID_ITEM_ID)
		return;

	StopHoldAction(playerid);
	ClearAnimations(playerid);
	HideActionText(playerid);
	tnt_CurrentTentItem[playerid] = INVALID_ITEM_ID;

	return;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(oldkeys & 16)
	{
		if(tnt_CurrentTentItem[playerid] != INVALID_ITEM_ID)
		{
			new ItemType:itemtype = GetItemType(GetPlayerItem(playerid));

			if(itemtype == item_Hammer)
			{
				StopBuildingTent(playerid);
			}
			else if(itemtype == item_Crowbar)
			{
				StopRemovingTent(playerid);
			}
		}
	}

	return 1;
}

hook OnHoldActionFinish(playerid)
{
	if(tnt_CurrentTentItem[playerid] != INVALID_ITEM_ID)
	{
		if(GetItemType(GetPlayerItem(playerid)) == item_Hammer)
		{
			CreateTentFromItem(tnt_CurrentTentItem[playerid]);
			StopBuildingTent(playerid);
		}

		if(GetItemType(GetPlayerItem(playerid)) == item_Crowbar)
		{
			new
				Float:x,
				Float:y,
				Float:z,
				tentid = GetItemExtraData(tnt_CurrentTentItem[playerid]);

			if(!IsValidTent(tentid))
			{
				err("Player %d attempted to destroy invalid tent %d from item %d", playerid, tentid, tnt_CurrentTentItem[playerid]);
				return Y_HOOKS_CONTINUE_RETURN_0;
			}

			GetItemPos(tnt_CurrentTentItem[playerid], x, y, z);

			for(new i = GetContainerItemCount(tnt_Data[tentid][tnt_containerId]); i >= 0; i--)
				CreateItemInWorld(GetContainerSlotItem(tnt_Data[tentid][tnt_containerId], i), x, y, z, 0.0, 0.0, frandom(360.0));

			DestroyTent(tentid);
			StopRemovingTent(playerid);
		}
	}

	return Y_HOOKS_CONTINUE_RETURN_0;
}


/*==============================================================================

	Interface

==============================================================================*/


stock IsValidTent(tentid)
{
	if(!Iter_Contains(tnt_Index, tentid))
		return 0;

	return 1;
}

// tnt_itemId
stock GetTentItem(tentid)
{
	if(!Iter_Contains(tnt_Index, tentid))
		return 0;

	return tnt_Data[tentid][tnt_itemId];
}

// tnt_containerId
stock GetTentContainer(tentid)
{
	if(!Iter_Contains(tnt_Index, tentid))
		return 0;

	return tnt_Data[tentid][tnt_containerId];
}

stock GetContainerTent(containerid)
{
	if(!IsValidContainer(containerid))
		return INVALID_TENT_ID;

	return tnt_ContainerTent[containerid];
}

stock GetTentPos(tentid, &Float:x, &Float:y, &Float:z)
{
	if(!Iter_Contains(tnt_Index, tentid))
		return 0;

	return GetItemPos(tnt_Data[tentid][tnt_itemId], x, y, z);
}