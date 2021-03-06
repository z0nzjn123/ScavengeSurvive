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


/*==============================================================================

	Setup

==============================================================================*/


#define MAX_MACHINE_TYPE (4)
#define MAX_MACHINE_FUEL (100.0)
#define MACHINE_FUEL_USAGE (3.5)
#define MAX_MACHINE_ITEMS (12)


enum e_MACHINE_DATA
{
	E_MACHINE_CONTAINER_ID,
	Float:E_MACHINE_FUEL,
	bool:E_MACHINE_COOKING,
	E_MACHINE_START_TICK,
	E_MACHINE_COOK_DURATION_MS,
	E_MACHINE_SMOKE_PARTICLE,
}

static
			mach_Total,
			mach_ItemTypeMachine[ITM_MAX_TYPES] = {-1, ...},

			mach_ContainerSize[MAX_MACHINE_TYPE] = {0, ...},
			mach_ContainerMachineItem[CNT_MAX] = {INVALID_ITEM_ID, ...},
			mach_CurrentMachine[MAX_PLAYERS],
			mach_MachineInteractTick[MAX_PLAYERS],
Timer:		mach_HoldTimer[MAX_PLAYERS];


forward OnPlayerUseMachine(playerid, itemid, interactiontype);
forward OnMachineFinish(itemid, containerid);


/*==============================================================================

	Zeroing

==============================================================================*/


hook OnPlayerConnect(playerid)
{
	mach_CurrentMachine[playerid] = INVALID_ITEM_ID;
}


/*==============================================================================

	Core Functions

==============================================================================*/


stock DefineMachineType(ItemType:itemtype, containersize)
{
	SetItemTypeMaxArrayData(itemtype, _:e_MACHINE_DATA);

	mach_ItemTypeMachine[itemtype] = mach_Total;
	mach_ContainerSize[mach_Total] = containersize;

	return mach_Total++;
}


/*==============================================================================

	Internal Functions and Hooks

==============================================================================*/


hook OnItemCreate(itemid)
{
	new machinetype = mach_ItemTypeMachine[GetItemType(itemid)];
	if(machinetype == -1)
		return Y_HOOKS_CONTINUE_RETURN_0;

	new name[ITM_MAX_NAME];

	GetItemName(itemid, name);

	new data[e_MACHINE_DATA];

	data[E_MACHINE_CONTAINER_ID] = CreateContainer(name, mach_ContainerSize[machinetype]);
	data[E_MACHINE_FUEL] = 0.0;
	data[E_MACHINE_COOKING] = false;
	data[E_MACHINE_START_TICK] = 0;
	data[E_MACHINE_COOK_DURATION_MS] = 0;
	data[E_MACHINE_SMOKE_PARTICLE] = INVALID_OBJECT_ID;

	SetItemArrayData(itemid, data, _:e_MACHINE_DATA);
	mach_ContainerMachineItem[data[E_MACHINE_CONTAINER_ID]] = itemid;

	return Y_HOOKS_CONTINUE_RETURN_0;
}

hook OnItemCreateInWorld(itemid)
{
	if(mach_ItemTypeMachine[GetItemType(itemid)] == -1)
		return Y_HOOKS_CONTINUE_RETURN_0;

	SetButtonText(GetItemButtonID(itemid), "Press "KEYTEXT_INTERACT" to access machine~n~Hold "KEYTEXT_INTERACT" to open menu~n~Use Petrol Can to add fuel");

	return Y_HOOKS_CONTINUE_RETURN_0;
}

hook OnPlayerPickUpItem(playerid, itemid)
{
	if(mach_ItemTypeMachine[GetItemType(itemid)] != -1)
	{
		_mach_PlayerUseMachine(playerid, itemid);
		return Y_HOOKS_BREAK_RETURN_1;
	}

	return Y_HOOKS_CONTINUE_RETURN_0;
}

hook OnPlayerUseItemWithItem(playerid, itemid, withitemid)
{
	if(mach_ItemTypeMachine[GetItemType(withitemid)] != -1)
	{
		_mach_PlayerUseMachine(playerid, withitemid);
		return Y_HOOKS_BREAK_RETURN_1;
	}

	return Y_HOOKS_CONTINUE_RETURN_0;
}

_mach_PlayerUseMachine(playerid, itemid)
{
	if(GetItemArrayDataAtCell(itemid, E_MACHINE_COOKING))
	{
		ShowActionText(playerid,
			sprintf(
				ls(playerid, "MACHPROCESS", true),
				MsToString(
					GetItemArrayDataAtCell(itemid, E_MACHINE_COOK_DURATION_MS) -
					GetTickCountDifference(
						GetTickCount(),
						GetItemArrayDataAtCell(itemid, E_MACHINE_START_TICK)
					),
				"%m minutes %s seconds")),
			8000
		);
		return 1;
	}

	mach_CurrentMachine[playerid] = itemid;
	mach_MachineInteractTick[playerid] = GetTickCount();

	mach_HoldTimer[playerid] = defer _mach_HoldInteract(playerid);

	return 0;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(RELEASED(16))
	{
		if(mach_CurrentMachine[playerid] != INVALID_ITEM_ID)
		{
			if(GetTickCountDifference(GetTickCount(), mach_MachineInteractTick[playerid]) < 250)
			{
				stop mach_HoldTimer[playerid];
				_mach_TapInteract(playerid);
			}
		}
	}

	return 1;
}

_mach_TapInteract(playerid)
{
	if(mach_CurrentMachine[playerid] == INVALID_ITEM_ID)
		return;

	if(GetItemArrayDataAtCell(mach_CurrentMachine[playerid], E_MACHINE_COOKING))
		return;

	Logger_Dbg("machine", "machine interact tap",
		Logger_I("id", mach_CurrentMachine[playerid]),
		Logger_I("containerid", GetItemArrayDataAtCell(mach_CurrentMachine[playerid], E_MACHINE_CONTAINER_ID)),
		Logger_I("playerid", playerid));

	// return 1 on OnPlayerUseMachine to cancel display of container inventory.
	new ret = CallLocalFunction("OnPlayerUseMachine", "ddd", playerid, mach_CurrentMachine[playerid], 0);
	if(!ret)
	{
		// TODO: Crowbar to deconstruct machine.
		// if(GetItemType(itemid) != item_Crowbar)
		DisplayContainerInventory(
			playerid,
			GetItemArrayDataAtCell(mach_CurrentMachine[playerid], E_MACHINE_CONTAINER_ID)
		);
	}

	mach_CurrentMachine[playerid] = INVALID_ITEM_ID;
}

timer _mach_HoldInteract[250](playerid)
{
	if(mach_CurrentMachine[playerid] == INVALID_ITEM_ID)
		return;

	if(GetItemArrayDataAtCell(mach_CurrentMachine[playerid], E_MACHINE_COOKING))
		return;

	Logger_Dbg("machine", "machine interact hold",
		Logger_I("id", mach_CurrentMachine[playerid]),
		Logger_I("containerid", GetItemArrayDataAtCell(mach_CurrentMachine[playerid], 0)),
		Logger_I("playerid", playerid));

	// if zero return, do refuel or show menu.
	new ret = CallLocalFunction("OnPlayerUseMachine", "ddd", playerid, mach_CurrentMachine[playerid], 1);
	if(!ret)
	{
		new ItemType:itemtype = GetItemType(GetPlayerItem(playerid));

		if(GetItemTypeLiquidContainerType(itemtype) != -1)
		{
			if(GetLiquidItemLiquidType(GetPlayerItem(playerid)) == liquid_Petrol)
			{
				new Float:fuel = Float:GetItemArrayDataAtCell(mach_CurrentMachine[playerid], E_MACHINE_FUEL);
				StartHoldAction(
					playerid,
					floatround(MAX_MACHINE_FUEL * 100),
					floatround(fuel * 100));
				return;
			}
		}

		inline Response(pid, dialogid, response, listitem, string:inputtext[])
		{
			#pragma unused pid, dialogid, listitem, inputtext

			if(response)
			{
				ret = _machine_StartCooking(mach_CurrentMachine[playerid]);

				if(ret == 0)
					ShowActionText(playerid, ls(playerid, "MACHNOITEMS", true), 5000);

				else if(ret == -1)
					ShowActionText(playerid, ls(playerid, "MACHRESTART", true), 6000);

				else if(ret == -2)
					ShowActionText(playerid, sprintf(
						ls(playerid, "MACHNOTFUEL", true),
						MACHINE_FUEL_USAGE
					), 6000);

				else
					ShowActionText(playerid, sprintf(ls(playerid, "MACHCOOKTIM", true), MsToString(ret, "%m minutes %s seconds")), 6000);

				mach_CurrentMachine[playerid] = INVALID_ITEM_ID;
			}
		}
		Dialog_ShowCallback(playerid, using inline Response, DIALOG_STYLE_MSGBOX, "Scrap Machine", sprintf(
			"Press 'Start' to activate the scrap machine and convert certain types of items into scrap.\n\
			Items that cannot be turned into scrap metal will be destroyed.\n\n\
			"C_GREEN"Fuel amount: "C_WHITE"%.1f",
			Float:GetItemArrayDataAtCell(mach_CurrentMachine[playerid], E_MACHINE_FUEL)), "Start", "Cancel");
	}
}

hook OnHoldActionUpdate(playerid, progress)
{
	if(mach_CurrentMachine[playerid] != -1)
	{
		new itemid = GetPlayerItem(playerid);
		if(GetItemTypeLiquidContainerType(GetItemType(itemid)) != -1)
		{
			if(GetLiquidItemLiquidType(itemid) != liquid_Petrol)
			{
				StopHoldAction(playerid);
				mach_CurrentMachine[playerid] = -1;
				return Y_HOOKS_BREAK_RETURN_1;
			}
		}

		new Float:fuel = GetLiquidItemLiquidAmount(itemid);
		if(fuel <= 0.0)
		{
			StopHoldAction(playerid);
			mach_CurrentMachine[playerid] = -1;
			HideActionText(playerid);
		}
		else
		{
			new
				Float:transfer = (fuel - 1.1 < 0.0) ? fuel : 1.1,
				Float:machinefuel = Float:GetItemArrayDataAtCell(mach_CurrentMachine[playerid], E_MACHINE_FUEL);

			SetLiquidItemLiquidAmount(itemid, fuel - transfer);
			SetItemArrayDataAtCell(mach_CurrentMachine[playerid], _:(machinefuel + transfer), E_MACHINE_FUEL);
			ShowActionText(playerid, ls(playerid, "REFUELLING", true));
		}
	}

	return Y_HOOKS_CONTINUE_RETURN_0;
}

_machine_StartCooking(itemid) {
	new data[e_MACHINE_DATA];
	GetItemArrayData(itemid, data);

	new itemcount = GetContainerItemCount(data[E_MACHINE_CONTAINER_ID]);

	if(itemcount == 0)
		return 0;

	// cook time = 90 seconds per item plus random 30 seconds
	new cooktime = (itemcount * 90) + random(30);

	// if there's not enough time left, don't allow a new cook to start.
	if(gServerUptime >= gServerMaxUptime - (cooktime * 1.5))
		return -1;

	if(data[E_MACHINE_FUEL] < MACHINE_FUEL_USAGE * itemcount)
		return -2;

	new
		Float:x,
		Float:y,
		Float:z;

	GetItemPos(itemid, x, y, z);

	cooktime *= 1000;

	data[E_MACHINE_COOKING] = true;
	DestroyDynamicObject(data[E_MACHINE_SMOKE_PARTICLE]);
	data[E_MACHINE_SMOKE_PARTICLE] = CreateDynamicObject(18726, x, y, z - 1.0, 0.0, 0.0, 0.0);
	data[E_MACHINE_COOK_DURATION_MS] = cooktime;
	data[E_MACHINE_START_TICK] = GetTickCount();

	SetItemArrayData(itemid, data, _:e_MACHINE_DATA);

	defer _machine_FinishCooking(itemid, cooktime);

	return cooktime;
}

timer _machine_FinishCooking[cooktime](itemid, cooktime)
{
#pragma unused cooktime
	new data[e_MACHINE_DATA];
	GetItemArrayData(itemid, data);

	DestroyDynamicObject(data[E_MACHINE_SMOKE_PARTICLE]);

	data[E_MACHINE_FUEL] -= GetContainerItemCount(data[E_MACHINE_CONTAINER_ID]) * MACHINE_FUEL_USAGE;
	data[E_MACHINE_COOKING] = false;
	data[E_MACHINE_SMOKE_PARTICLE] = INVALID_OBJECT_ID;
	SetItemArrayData(itemid, data, _:e_MACHINE_DATA);

	CallLocalFunction("OnMachineFinish", "dd", itemid, data[E_MACHINE_CONTAINER_ID]);
}


/*==============================================================================

	Interface Functions

==============================================================================*/


// mach_ItemTypeMachine
stock GetItemTypeMachineType(ItemType:itemtype)
{
	if(!IsValidItemType(itemtype))
		return -1;

	return mach_ItemTypeMachine[itemtype];
}

// mach_ContainerSize
stock GetMachineTypeContainerSize(machinetype)
{
	if(!(0 <= machinetype < mach_Total))
		return 0;

	return mach_ContainerSize[machinetype];
}

// mach_ContainerMachineItem
stock GetContainerMachineItem(containerid)
{
	if(!IsValidContainer(containerid))
		return -1;

	return mach_ContainerMachineItem[containerid];
}

// mach_CurrentMachine
stock GetPlayerCurrentMachine(playerid)
{
	if(!IsPlayerConnected(playerid))
		return -1;

	return mach_CurrentMachine[playerid];
}
