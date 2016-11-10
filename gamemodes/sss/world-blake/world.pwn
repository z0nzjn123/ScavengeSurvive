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


#include "sss/world-blake/spawn.pwn"
#include "sss/world-blake/map/blake.pwn"


#include <YSI\y_hooks>


static
	MapName[32] = "Blake Island",
	ItemCounts[ITM_MAX_TYPES];

#include <YSI\y_hooks>


hook OnGameModeInit()
{
	defer LoadWorld();
}

timer LoadWorld[10]()
{
	gServerInitialising = true;

	// store this to a list and compare after
	for(new ItemType:i; i < ITM_MAX_TYPES; i++)
	{
		if(!IsValidItemType(i))
			break;

		if(GetItemTypeCount(i) == 0)
			continue;

		ItemCounts[i] = GetItemTypeCount(i);
	}

	defer _LOadMap();
}

defer _LoadMap[500]()
{
	LoadMap();
	defer _Finalise();
}

timer _Finalise[500]()
{
	new itemtypename[ITM_MAX_NAME];

	// compare with previous list and print differences
	for(new ItemType:i; i < ITM_MAX_TYPES; i++)
	{
		if(!IsValidItemType(i))
			break;

		if(GetItemTypeCount(i) == 0)
			continue;

		GetItemTypeUniqueName(i, itemtypename);

		printf("[%03d] Loaded:%04d, Spawned:%04d, Total:%04d, '%s'", _:i, ItemCounts[i], GetItemTypeCount(i) - ItemCounts[i], GetItemTypeCount(i), itemtypename);
	}

	gServerInitialising = false;
}

stock GetMapName()
{
	return MapName;
}

