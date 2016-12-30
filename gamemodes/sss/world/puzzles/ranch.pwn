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


#include <YSI\y_hooks>


#define RANCH_STUFF_VIRTUALW	(1)


new
	RanchPcButton,
	RanchHdd,
	RanchPcState,
	RanchPcObj,
	RanchPcPlayerViewing[MAX_PLAYERS],

	QuarryDoor,
	QuarryDoorKey,
	QuarryDoorState,

	CaveDoor,
	CaveLift,
	CaveLiftButtonT,
	CaveLiftButtonB,
	LiftPos;


hook OnGameModeInit()
{
	console("\n[OnGameModeInit] Initialising 'Ranch'...");

	_Ranch_LoadObjects();

	new buttonid[2];

	// Ranch

	RanchPcButton = CreateButton(-691.1692, 942.1066, 13.6328, "Press "KEYTEXT_INTERACT" to use");
	RanchHdd = CreateItem(item_HardDrive, -693.1787, 942.0, 15.93, 90.0, 0.0, 37.5);


	// Quarry

	QuarryDoor = CreateButton(495.451873, 780.096191, -21.747426, "Press "KEYTEXT_INTERACT" to enter"); // quarry
	CaveDoor = CreateButton(-2702.358398, 3801.477050, 52.652801, "Press "KEYTEXT_INTERACT" to enter", RANCH_STUFF_VIRTUALW); // cave 1


	// Shack

	CreateDynamicObject(2574, -2811.88, -1530.59, 139.84, 0.00, 0.00, 180.00);
	QuarryDoorKey = CreateItem(item_Key, -2813.96, -1530.55, 140.97, 0.36, -85.14, 25.00);


	// Cave 1

	CaveLift = CreateDynamicObject(7246, -2759.4704, 3756.8691, 6.9, 270, 180, 340.9154, RANCH_STUFF_VIRTUALW);

	buttonid[0] = CreateButton(-2796.933349, 3682.779785, 02.515481, "Press "KEYTEXT_INTERACT" to enter", RANCH_STUFF_VIRTUALW); // cave 1
	buttonid[1] = CreateButton(-1445.01, 3673.77, 4.08, "Press "KEYTEXT_INTERACT" to enter", RANCH_STUFF_VIRTUALW); // cave 2
	LinkTP(buttonid[0], buttonid[1]);

	// Cave 2
	buttonid[0] = CreateButton(-1618.94, 3648.38, 6.90, "Press "KEYTEXT_INTERACT" to enter", RANCH_STUFF_VIRTUALW); // cave 2
	buttonid[1] = CreateButton(-785.9272, 3727.1111, 0.5293, "Press "KEYTEXT_INTERACT" to enter", RANCH_STUFF_VIRTUALW); // cave 3
	LinkTP(buttonid[0], buttonid[1]);


	// Subway/Metro

	buttonid[0] = CreateButton(-1007.395263, 5782.741210, 42.951477, "Press "KEYTEXT_INTERACT" to climb up the ladder", RANCH_STUFF_VIRTUALW);
	buttonid[1] = CreateButton(2526.719482, -1648.620605, 14.471982, "Press "KEYTEXT_INTERACT" to climb down the ladder");
	LinkTP(buttonid[0], buttonid[1]);

	buttonid[0] = CreateButton(250.599380, -154.643936, -50.768798, "Press "KEYTEXT_INTERACT" to enter", RANCH_STUFF_VIRTUALW);
	buttonid[1] = CreateButton(247.878799, -154.444061, 02.399550, "Press "KEYTEXT_INTERACT" to enter");
	LinkTP(buttonid[0], buttonid[1]);

	buttonid[0] = CreateButton(-2276.608642, 5324.488281, 41.677970, "Press "KEYTEXT_INTERACT" to enter", RANCH_STUFF_VIRTUALW);
	buttonid[1] = CreateButton(-734.773986, 3861.994628, 12.482711, "Press "KEYTEXT_INTERACT" to enter", RANCH_STUFF_VIRTUALW); // cave
	LinkTP(buttonid[0], buttonid[1]);


	// Fort Claw underground

	buttonid[0]=CreateButton(246.698684, -178.849655, -50.199367, "Press "KEYTEXT_INTERACT" to enter", RANCH_STUFF_VIRTUALW); // underground
	buttonid[1]=CreateButton(-952.559326, 5137.799804, 46.183383, "Press "KEYTEXT_INTERACT" to enter", RANCH_STUFF_VIRTUALW); // metro station
	LinkTP(buttonid[0], buttonid[1]);

	CreateButton(-972.153869, 4303.185058, 48.666248, "~r~Locked", RANCH_STUFF_VIRTUALW);


	// Lift Sequence

	CaveLiftButtonT=CreateButton(-2764.0332, 3757.0466, 46.8343, "Press "KEYTEXT_INTERACT" to use the lift", RANCH_STUFF_VIRTUALW);
	CaveLiftButtonB=CreateButton(-2764.3410, 3755.5153, 8.2390, "Press "KEYTEXT_INTERACT" to use the lift", RANCH_STUFF_VIRTUALW);
	LiftPos=0;


	// Fort Claw Door

	buttonid[0] = CreateButton(264.316284, -171.135223, -50.206447, "Press "KEYTEXT_INTERACT" to activate", RANCH_STUFF_VIRTUALW);
	buttonid[1] = CreateButton(265.862182, -170.113632, -50.204307, "Press "KEYTEXT_INTERACT" to activate", RANCH_STUFF_VIRTUALW);
	CreateDoor(5779, buttonid,
		265.0330, -168.9362, -49.9792, 0.0, 0.0, 0.0,
		265.0322, -168.9355, -46.8575, 0.0, 0.0, 0.0, .worldid = RANCH_STUFF_VIRTUALW);
}

hook OnButtonPress(playerid, buttonid)
{
	dbg("global", CORE, "[OnButtonPress] in /gamemodes/sss/world/puzzles/ranch.pwn");

	if(buttonid==RanchPcButton)
	{
	    if(RanchPcState == 0)Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "Computer", "You try to turn on the computer but the hard disk is missing.\nYou wonder where it could be and think it's mighty suspicious.\nThere is nothing useful nearby.", "Close", "");
	    if(RanchPcState == 1)
	    {
			if(RanchPcPlayerViewing[playerid])
			{
			    SetCameraBehindPlayer(playerid);
			    TogglePlayerControllable(playerid, true);
			    RanchPcPlayerViewing[playerid] = false;
			}
			else
			{
			    SetPlayerCameraPos(playerid, -691.141845, 942.489868, 13.759174);
			    SetPlayerCameraLookAt(playerid, -689.749084, 946.223693, 14.104162);
			    RanchPcPlayerViewing[playerid] = true;
			}
	    }

	}

	if(buttonid == QuarryDoor)
	{
	    if(QuarryDoorState == 0)
	    {
	    	Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "Door", "You pull on the door but it won't budge, the lock seems sturdy.\nThere's no way you can get through here without a key.\nPerhaps you should search the shed?", "Close", "");
	    }
	    else
	    {
			SetPlayerVirtualWorld(playerid, RANCH_STUFF_VIRTUALW);
			SetPlayerPos(playerid, -2702.358398, 3801.477050, 52.652801);
			FreezePlayer(playerid, 1000);
	    }
	}
	if(buttonid == CaveDoor)
	{
		SetPlayerVirtualWorld(playerid, 0);
		SetPlayerPos(playerid, 495.451873, 780.096191, -21.747426);
		FreezePlayer(playerid, 1000);
	}
	if(buttonid==CaveLiftButtonT)
	{
		if(LiftPos)
		{
		    MoveDynamicObject(CaveLift, -2759.4704, 3756.8691, 6.9, 2.0, 270, 180, 340.9);
		    LiftPos=0;
		}
		else
		{
		    MoveDynamicObject(CaveLift, -2759.4704, 3756.8691, 45.4, 2.0, 270, 180, 340.9);
		    LiftPos=1;
		}
	}
	if(buttonid==CaveLiftButtonB)
	{
		if(LiftPos)
		{
		    MoveDynamicObject(CaveLift, -2759.4704, 3756.8691, 45.4, 2.0, 270, 180, 340.9);
		    LiftPos=0;
		}
		else
		{
		    MoveDynamicObject(CaveLift, -2759.4704, 3756.8691, 6.9, 2.0, 270, 180, 340.9);
		    LiftPos=1;
		}
	}

	return Y_HOOKS_CONTINUE_RETURN_0;
}

hook OnPlayerUseItemWithBtn(playerid, buttonid, itemid)
{
	dbg("global", CORE, "[OnPlayerUseItemWithBtn] in /gamemodes/sss/world/puzzles/ranch.pwn");

	if(buttonid == RanchPcButton && itemid == RanchHdd)
	{
	    Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "Computer", "You begin reattaching the hard drive to the computer.", "Close", "");
		ApplyAnimation(playerid, "BOMBER", "BOM_PLANT_IN", 5.0, 0, 0, 0, 1, 450);
		defer AttachRanchHdd(playerid);
	}
	if(QuarryDoorState == 0 && buttonid == QuarryDoor && itemid == QuarryDoorKey)
	{
	    Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "Door", "You have unlocked the mystery door!", "Close", "");
	    QuarryDoorState = 1;
	}

	return Y_HOOKS_CONTINUE_RETURN_0;
}

timer AttachRanchHdd[2500](playerid)
{
	DestroyItem(RanchHdd);
	Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "Computer", "You successfully install the hard drive without electricuting yourself, well done!", "Close", "");
    ApplyAnimation(playerid, "BOMBER", "BOM_PLANT_2IDLE", 4.0, 0, 0, 0, 0, 0);
    RanchPcState = 1;

	RanchPcObj = CreateDynamicObject(19475, -690.966735, 942.852416, 13.642812, 0.000000, 0.000000, -110.324981),
	SetDynamicObjectMaterialText(RanchPcObj, 0,
		"system:\n\
		  >login terminal\\root\\user\\steve\n\
		  >open diary\\entry\\recent\n\
		   I have left the ranch, they are after me\n\
		   whoever finds this, I decided to go to a friends\n\
		   place on chilliad, he was dead when I got there\n\
		   I've hidden the key there, they won't find it\n\
		   I dont know how long it will be before they find me",
		OBJECT_MATERIAL_SIZE_512x512, "Courier New", 16, 1, -1, 0, 0);
}


_Ranch_LoadObjects()
{
	// Quarry (by Southclaw)

	CreateDynamicObject(3865, 494.74981689453, 775.16119384766, -21.255405426025, 0.00000000000, 0.00000000000, 352.05993652344, RANCH_STUFF_VIRTUALW, 0);
	CreateDynamicObject(16637, 495.3046875, 779.7001953125, -21.165279388428, 2.61474609375, 0.1153564453125, 261.54602050781, RANCH_STUFF_VIRTUALW, 0);
	CreateDynamicObject(13360, 495.40121459961, 779.74963378906, -21.559215545654, 359.90521240234, 3.7300109863281, 171.87194824219, RANCH_STUFF_VIRTUALW, 0);
	CreateDynamicObject(3415, 490.01550292969, 785.73364257813, -23.1126537323, 0.00000000000, 0.00000000000, 123.15985107422, RANCH_STUFF_VIRTUALW, 0);
	CreateDynamicObject(2205, 493.17575073242, 782.67260742188, -23.052221298218, 0.00000000000, 0.00000000000, 212.65997314453, RANCH_STUFF_VIRTUALW, 0);
	CreateDynamicObject(2066, 491.1979675293, 781.45190429688, -22.986045837402, 0.00000000000, 0.00000000000, 23.929992675781, RANCH_STUFF_VIRTUALW, 0);
	CreateDynamicObject(1811, 492.2619934082, 782.98455810547, -22.448837280273, 0.00000000000, 0.00000000000, 107.23001098633, RANCH_STUFF_VIRTUALW, 0);
	CreateDynamicObject(2894, 492.50750732422, 782.41870117188, -22.115758895874, 0.00000000000, 0.00000000000, 25.804992675781, RANCH_STUFF_VIRTUALW, 0);
	CreateDynamicObject(11631, 489.69369506836, 783.94360351563, -21.818862915039, 0.00000000000, 0.00000000000, 122.06997680664, RANCH_STUFF_VIRTUALW, 0);
	CreateDynamicObject(1811, 490.11706542969, 784.48461914063, -22.448837280273, 0.00000000000, 0.00000000000, 23.631530761719, RANCH_STUFF_VIRTUALW, 0);


	// LS entrance (by Dogmeat)

	CreateDynamicObject(12986, 2526.416015625, -1649.09375, 13.893012046814, 9.920654296875, 5.9490966796875, 210.89904785156, RANCH_STUFF_VIRTUALW, 0);


	// Metro (by Dogmeat)

	CreateDynamicObject(5772, -965.83154296875, 5142.5971679688, 51.17557144165, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6248, -969.96325683594, 5029.7153320313, 47.297080993652, 0.000000000000, 0.000000000000, 318.31506347656, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6248, -971.69714355469, 4906.447265625, 48.307739257813, 0.000000000000, 0.000000000000, 318.31237792969, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6250, -973.77319335938, 4780.4677734375, 47.683826446533, 0.000000000000, 0.000000000000, 268.68994140625, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6252, -975.04309082031, 4674.8037109375, 48.17306137085, 0.000000000000, 0.000000000000, 268.68994140625, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6252, -976.23187255859, 4589.3002929688, 47.918346405029, 0.000000000000, 0.000000000000, 268.68713378906, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6252, -978.01635742188, 4502.8359375, 47.69437789917, 0.000000000000, 0.000000000000, 267.93713378906, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(5679, -981.03491210938, 4348.0200195313, 51.126182556152, 0.000000000000, 0.000000000000, 178.75000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3753, -979.978515625, 4448.4072265625, 75.253028869629, 0.000000000000, 0.000000000000, 357.98950195313, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16305, -977.93609619141, 4254.3076171875, 51.115516662598, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16304, -985.18096923828, 4246.859375, 52.194675445557, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16302, -977.19683837891, 4245.5551757813, 52.077003479004, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3753, -974.478515625, 4230.4516601563, 65.503028869629, 0.000000000000, 0.000000000000, 357.99499511719, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16367, -972.31719970703, 5190.1904296875, 45.149360656738, 0.000000000000, 0.000000000000, 270.67498779297, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -966.21978759766, 5191.9921875, 45.661231994629, 0.000000000000, 0.000000000000, 256.77996826172, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18451, -967.25256347656, 5091.9038085938, 44.601943969727, 0.000000000000, 0.000000000000, 179.3649597168, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(13647, -967.17236328125, 5091.6196289063, 39.685207366943, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3633, -963.22583007813, 5154.5537109375, 45.61678314209, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3633, -963.2255859375, 5152.6533203125, 45.61678314209, 0.000000000000, 0.000000000000, 278.61499023438, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3633, -960.2255859375, 5152.6533203125, 45.61678314209, 0.000000000000, 0.000000000000, 316.32998657227, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3633, -960.2255859375, 5159.1533203125, 45.61678314209, 0.000000000000, 0.000000000000, 276.62475585938, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3632, -962.84741210938, 5157.7138671875, 45.658187866211, 0.000000000000, 0.000000000000, 328.23999023438, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3632, -960.8466796875, 5154.2138671875, 45.658187866211, 0.000000000000, 0.000000000000, 199.21411132813, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3632, -960.8466796875, 5156.9638671875, 45.658187866211, 0.000000000000, 0.000000000000, 230.96960449219, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3632, -961.5966796875, 5155.7138671875, 45.658187866211, 0.000000000000, 0.000000000000, 191.26556396484, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3632, -961.5966796875, 5151.4638671875, 45.326950073242, 0.000000000000, 95.280029296875, 262.72094726563, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3632, -960.0966796875, 5150.9638671875, 45.658187866211, 0.000000000000, 0.000000000000, 167.44958496094, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6248, -973.96905517578, 5255.1977539063, 46.326034545898, 0.000000000000, 0.000000000000, 322.28503417969, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6248, -1044.6572265625, 5319.9912109375, 46.326034545898, 0.000000000000, 0.000000000000, 230.97106933594, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6248, -910.62084960938, 5324.56640625, 45.401329040527, 0.000000000000, 0.000000000000, 230.97106933594, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6248, -981.30078125, 5389.3525390625, 46.312232971191, 0.000000000000, 0.000000000000, 142.41104125977, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(5184, -971.82202148438, 5328.1015625, 61.766502380371, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(5184, -932.0810546875, 5365.77734375, 72.60245513916, 0.000000000000, 0.000000000000, 277.21997070313, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(5184, -971.8212890625, 5328.1015625, 29.787715911865, 0.000000000000, 179.99450683594, 13.894989013672, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6248, -1167.7608642578, 5315.9907226563, 47.326034545898, 0.000000000000, 0.000000000000, 230.97106933594, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6248, -1290.7214355469, 5311.9926757813, 48.327606201172, 0.000000000000, 0.000000000000, 230.97106933594, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6251, -1416.6053466797, 5308.9384765625, 46.682838439941, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6250, -1545.9069824219, 5310.0249023438, 45.565509796143, 0.000000000000, 0.000000000000, 358.0299987793, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6250, -1673.9250488281, 5313.8247070313, 44.421207427979, 0.000000000000, 0.000000000000, 357.77795410156, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6250, -1801.9791259766, 5317.8930664063, 43.310794830322, 0.000000000000, 0.000000000000, 357.77526855469, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6250, -1929.6431884766, 5321.94921875, 42.211040496826, 0.000000000000, 0.000000000000, 357.77526855469, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6250, -2057.24609375, 5325.9985351563, 41.088397979736, 0.000000000000, 0.000000000000, 357.77526855469, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(5679, -2231.4653320313, 5332.5385742188, 44.136745452881, 0.000000000000, 0.000000000000, 87.340026855469, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(5176, -2338.7470703125, 5332.6181640625, 57.353706359863, 0.000000000000, 0.000000000000, 357.5299987793, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(9586, -2122.8227539063, 5328.0849609375, 60.543296813965, 91.310028076172, 0.000000000000, 266.70498657227, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6250, -989.5000000000, 5514.828125, 44.544467926025, 0.000000000000, 0.000000000000, 273.62548828125, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6250, -998.50415039063, 5642.5473632813, 43.492404937744, 0.000000000000, 0.000000000000, 273.62548828125, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(5398, -1003.8936767578, 5722.673828125, 46.256164550781, 0.000000000000, 0.000000000000, 3.750000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3753, -1003.5192871094, 5697.376953125, 70.865585327148, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(5398, -1005.9763183594, 5754.400390625, 46.256164550781, 0.000000000000, 0.000000000000, 3.746337890625, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(5398, -1008.0738525391, 5786.185546875, 46.256164550781, 0.000000000000, 0.000000000000, 3.746337890625, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16302, -1012.4772338867, 5806.3588867188, 47.982501983643, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16305, -1006.369140625, 5794.7177734375, 44.631191253662, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16317, -1005.2208251953, 5802.7299804688, 43.146167755127, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16317, -1011.470703125, 5795.9794921875, 40.396167755127, 0.000000000000, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16317, -1005.220703125, 5802.7294921875, 47.896167755127, 45.654998779297, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3865, -1007.6205444336, 5781.8359375, 52.885398864746, 89.325012207031, 0.000000000000, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1437, -1007.4923706055, 5783.2900390625, 44.701477050781, 11.910003662109, 358.01501464844, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1437, -1007.4923706055, 5783.2900390625, 44.701477050781, 11.910003662109, 358.01501464844, 0.000000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1508, -951.70983886719, 5137.6645507813, 46.841693878174, 0.000000000000, 0.000000000000, 1.250000000000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1966, -951.69128417969, 5137.4526367188, 50.718822479248, 0.000000000000, 0.000000000000, 91.252227783203, RANCH_STUFF_VIRTUALW);

	// Cave 1 (by Southclaw)

	CreateDynamicObject(4898, -2775.58032, 3697.31665, 2.62368, 4.29720, 359.14059, 11.25000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -2793.81396, 3757.43286, 9.34636, 0.00000, 0.00000, 131.76004, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2818.26978, 3696.38794, 14.34393, 0.00000, 0.00000, 146.25000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2743.23584, 3688.52759, 12.43752, 0.00000, 0.00000, 328.90570, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -2738.68457, 3732.84180, 14.84344, 0.00000, 0.00000, 327.03003, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17034, -2769.00806, 3774.34399, 4.94718, 0.00000, 0.00000, 0.00000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2787.87378, 3646.24487, 11.25337, 0.00000, 0.00000, 258.75000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(13360, -2797.71509, 3682.30469, 2.55816, 0.00000, 0.00000, 107.34340, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3458, -2761.78809, 3757.80957, 25.86462, 181.07666, 90.41199, 250.85083, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3458, -2759.22705, 3753.60962, 25.96746, 181.07820, 90.41270, 160.85159, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3458, -2766.50854, 3755.40674, 25.87443, 181.07820, 90.41270, 340.85159, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3458, -2764.14746, 3751.45215, 35.03610, 180.00000, 88.90686, 68.26904, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3458, -2766.63696, 3755.67480, 54.97256, 181.07820, 90.41270, 340.85159, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3458, -2758.88672, 3753.91699, 56.67659, 181.07820, 90.41270, 160.85159, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3458, -2755.53857, 3775.55908, 44.58445, 0.00000, 0.00000, 250.85159, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17026, -2771.19507, 3731.13794, 42.38379, 0.00000, 176.18460, 11.25000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2751.81787, 3671.09961, 44.64037, 154.69870, 39.53410, 164.21190, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2804.60571, 3678.85132, 55.58272, 154.69870, 39.53410, 164.21190, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2806.13892, 3656.46704, 41.83880, 154.69870, 39.53410, 265.46191, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2786.07568, 3730.27612, 47.33148, 154.69870, 39.53410, 29.21200, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(896, -2770.71851, 3759.40845, 16.96833, 0.00000, 19.76700, 121.95380, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(896, -2771.03833, 3758.49512, 7.68891, 344.53009, 6.87550, 125.39160, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(896, -2756.49365, 3749.77368, 8.35694, 354.84341, 6.87550, 99.60850, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(896, -2755.98242, 3751.12769, 19.79977, 354.84341, 6.87550, 99.60850, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(896, -2757.97827, 3748.27661, 30.05367, 354.84341, 11.17270, 101.32740, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(896, -2770.19287, 3757.81030, 25.81741, 0.00000, 19.76700, 279.45380, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(896, -2772.21997, 3753.48535, 32.54557, 0.00000, 3.43770, 267.42181, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(896, -2765.42627, 3745.87598, 23.79174, 354.84341, 6.87550, 203.59129, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(4898, -2707.31299, 3817.15576, 51.98201, 4.29720, 359.14059, 314.37259, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2784.28809, 3782.80542, 79.58510, 154.69870, 69.61430, 16.24320, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2746.08301, 3783.59204, 86.53472, 154.69870, 39.53410, 197.96210, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2719.30029, 3764.14063, 80.42982, 154.69870, 39.53410, 276.71201, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2715.78076, 3776.11816, 48.75498, 0.00000, 0.00000, 251.09261, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2797.45190, 3783.94702, 40.01738, 0.00000, 353.12451, 183.59261, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2753.15894, 3815.42358, 48.57870, 347.10840, 17.18870, 286.48401, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2672.97876, 3816.64429, 48.36674, 347.10840, 17.18870, 106.48400, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2700.79761, 3837.64697, 57.10764, 344.53009, 17.18870, 61.48400, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2692.32324, 3814.26904, 86.48518, 154.69870, 39.53410, 262.65149, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(13360, -2701.64111, 3801.77808, 52.75574, 0.48000, -0.06000, 89.38950, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(896, -2771.75342, 3755.32935, 52.62378, 0.00000, 0.00000, 264.84341, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(896, -2772.13989, 3756.91626, 49.89507, 12.03210, 8.59440, 84.13860, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(2886, -2765.76074, 3752.76196, 8.07203, 0.00000, 0.00000, 0.00000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(2886, -2764.41357, 3757.42578, 47.54563, 0.00000, 0.00000, 69.97498, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -2738.29639, 3826.45874, 98.39668, 162.91869, 8.99409, 84.75157, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(3458, -2756.90601, 3757.25098, 35.03610, 180.00000, 88.90686, 153.28900, RANCH_STUFF_VIRTUALW);


	// Cave 2 (by Southclaw)

	CreateDynamicObject(4898, -1478.027832, 3679.792725, 7.065671, 353.1245, 0.0000, 270.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(4898, -1636.890747, 3657.150635, 4.292534, 351.4056, 355.7028, 98.9040, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1577.290771, 3695.325195, 19.113111, 0.0000, 334.2169, 90.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1609.058472, 3623.474365, 19.802559, 0.0000, 322.1848, 247.4999, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18227, -1604.911377, 3678.525391, 13.446358, 359.1406, 0.0000, 64.6897, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18225, -1652.109619, 3632.380127, 29.228739, 0.0000, 0.0000, 150.7017, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1558.455566, 3643.735840, 7.973587, 0.0000, 343.6707, 269.9999, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17034, -1533.387451, 3699.431396, 10.408533, 0.0000, 6.0161, 22.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(13360, -1619.293945, 3648.239746, 6.837439, 358.3241, 0.1289, 280.9405, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1443.961670, 3697.512939, 1.662173, 0.0000, 341.9518, 45.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17034, -1495.796753, 3662.483643, 4.806009, 0.0000, 6.0161, 349.6868, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17034, -1446.550903, 3664.563477, 1.222446, 0.0000, 6.0161, 203.3595, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(13360, -1444.667114, 3673.733643, 3.957656, 0.0000, 0.0000, 85.7028, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1611.648682, 3660.876221, 46.825768, 3.4377, 163.1888, 315.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1570.786255, 3656.556396, 44.471134, 0.0000, 164.9076, 315.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1533.446289, 3703.555420, 46.427925, 3.4377, 163.1888, 315.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1546.283447, 3679.387939, 60.666298, 3.4377, 163.1888, 315.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1461.184082, 3698.941406, 45.034325, 3.4377, 163.1888, 269.9999, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1492.540894, 3687.028564, 49.736332, 11.1727, 185.5343, 315.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1499.715088, 3673.565186, 36.379166, 11.1727, 185.5343, 315.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -1486.303101, 3664.326660, 35.203533, 11.1727, 185.5343, 315.0000, RANCH_STUFF_VIRTUALW);


	// Cave 3 (by Southclaw)

	CreateDynamicObject(4898, -757.886658, 3781.770752, 0.578399, 7.7349, 0.0000, 0.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(6234, -776.257385, 3760.870117, 2.495516, 0.0000, 0.0000, 337.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16139, -751.450378, 3845.472168, 3.631547, 330.7792, 17.1887, 237.9689, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(13360, -734.670044, 3862.333008, 12.600233, 0.0000, 0.0000, 337.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -735.585327, 3862.888916, 12.976830, 0.8594, 61.0199, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -731.827576, 3861.269775, 12.871898, 0.8594, 61.0199, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -733.648987, 3861.962891, 16.402004, 0.8594, 61.0199, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -731.347290, 3861.108643, 13.285748, 0.8594, 61.0199, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -733.992676, 3862.016113, 17.542192, 0.8594, 61.0199, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17029, -726.646729, 3848.574707, 4.996742, 2.5783, 6.0161, 298.4387, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17029, -738.310974, 3807.602051, -0.987077, 0.0000, 0.0000, 264.6888, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16139, -766.505371, 3809.684082, -1.148952, 330.7792, 17.1887, 237.9689, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17031, -758.524902, 3757.649170, -4.285746, 0.0000, 0.0000, 337.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17031, -791.155334, 3771.417725, -0.971771, 0.0000, 0.0000, 157.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17032, -803.841980, 3728.006836, -8.152155, 14.6104, 6.8755, 45.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17034, -762.112244, 3725.988525, -4.841251, 0.0000, 0.0000, 225.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -783.442810, 3722.254150, 1.646538, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -786.732056, 3723.620605, 1.575446, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -789.387207, 3724.755615, 1.879175, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -787.302002, 3723.915283, 3.689284, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -784.722107, 3722.842773, 3.651711, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -781.870605, 3721.661621, 3.602202, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -790.180542, 3725.142822, 3.713566, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -789.895508, 3725.083496, 5.497257, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -787.122131, 3723.899414, 5.527874, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -784.298462, 3722.726074, 5.548768, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -781.837585, 3721.706543, 5.597544, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -789.816772, 3724.907471, -1.050371, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -786.687195, 3723.604736, -0.906264, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(16637, -783.263245, 3722.175537, -0.104369, 0.0000, 0.0000, 247.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(13360, -786.565125, 3723.611084, 0.624090, 0.0000, 0.0000, 337.7149, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -740.228271, 3864.598145, 26.155117, 346.2490, 82.5059, 326.2500, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -711.738770, 3828.931885, 22.721575, 341.0924, 107.4295, 166.0944, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -771.278809, 3819.213623, 23.885227, 341.0924, 107.4295, 357.3445, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -808.080444, 3748.372070, 20.258636, 341.0924, 107.4295, 346.0945, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -748.271423, 3765.502686, 19.973875, 335.0763, 107.4295, 177.3444, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(18226, -795.041016, 3701.518799, 16.003687, 335.0763, 107.4295, 76.0944, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -778.587952, 3752.150635, 22.182844, 163.2931, 330.7792, 60.7881, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -777.598999, 3749.040039, 22.269999, 171.8875, 335.0763, 60.7881, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -776.070862, 3747.392822, 22.447201, 171.8875, 335.0763, 60.7881, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -776.044067, 3756.744141, 22.526243, 171.8875, 335.0763, 60.7881, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -775.167419, 3752.234375, 22.776619, 171.8875, 335.0763, 60.7881, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -775.334473, 3754.052979, 22.811550, 171.8875, 335.0763, 60.7881, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -773.981506, 3756.507324, 23.015657, 171.8875, 335.0763, 60.7881, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -775.682861, 3759.548340, 22.631231, 171.8875, 335.0763, 60.7881, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(1245, -778.729614, 3755.129150, 22.108097, 171.8875, 335.0763, 60.7881, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17033, -780.141846, 3789.583008, 2.756541, 0.0000, 0.0000, 0.0000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17033, -744.587341, 3781.114502, 3.250612, 0.0000, 0.0000, 157.5000, RANCH_STUFF_VIRTUALW);
	CreateDynamicObject(17033, -742.912659, 3777.167236, 4.750612, 0.0000, 0.0000, 157.5000, RANCH_STUFF_VIRTUALW);

}
