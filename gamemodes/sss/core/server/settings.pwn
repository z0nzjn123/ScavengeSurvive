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


LoadSettings()
{
	if(!fexist(SETTINGS_FILE))
	{
		err("Settings file '"SETTINGS_FILE"' not found. Creating and using default values.");

		fclose(fopen(SETTINGS_FILE, io_write));
	}

	GetSettingString(SETTINGS_FILE, "server/motd", "Please update the 'server/motd' string in "SETTINGS_FILE"", gMessageOfTheDay);
	GetSettingString(SETTINGS_FILE, "server/website", "southclawjk.wordpress.com", gWebsiteURL);
	GetSettingInt(SETTINGS_FILE, "server/crash-on-exit", true, gCrashOnExit);

	GetSettingStringArray(SETTINGS_FILE, "server/rules", "Please update the 'server/rules' array in '"SETTINGS_FILE"'.", gRuleList, gTotalRules, 128, MAX_RULE, MAX_RULE_LEN);
	GetSettingStringArray(SETTINGS_FILE, "server/staff", "StaffName", gStaffList, gTotalStaff, 32, MAX_STAFF, MAX_STAFF_LEN);

	GetSettingInt(SETTINGS_FILE, "server/max-uptime", 18000, gServerMaxUptime);
	GetSettingInt(SETTINGS_FILE, "player/allow-pause-map", 0, gPauseMap);
	GetSettingInt(SETTINGS_FILE, "player/interior-entry", 0, gInteriorEntry);
	GetSettingInt(SETTINGS_FILE, "player/vehicle-surfing", 0, gVehicleSurfing);
	GetSettingFloat(SETTINGS_FILE, "player/nametag-distance", 3.0, gNameTagDistance);
	GetSettingInt(SETTINGS_FILE, "player/combat-log-window", 30, gCombatLogWindow);
	GetSettingInt(SETTINGS_FILE, "player/login-freeze-time", 8, gLoginFreezeTime);
	GetSettingInt(SETTINGS_FILE, "player/max-tab-out-time", 60, gMaxTaboutTime);
	GetSettingInt(SETTINGS_FILE, "player/ping-limit", 400, gPingLimit);

	// I'd appreciate if you left my credit and the proper gamemode name intact!
	// Failure to do this will result in being blacklisted from the server list.
	// And I'll be less inclined to help you with issues.
	// Unless you have a decent reason to change the gamemode name (heavy mod)
	// I'd still like to be credited for my work. Many servers have claimed
	// they are the sole creator of the mode and this makes me sad and very
	// hesitant to release my work completely free of charge.
	SetGameModeText("Scavenge Survive by Southclaw");
}

