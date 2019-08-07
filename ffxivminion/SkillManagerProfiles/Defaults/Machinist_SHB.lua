-- Persistent Data
local multiRefObjects = {

} -- multiRefObjects
local obj1 = {
	["classes"] = {
		[1] = false;
		[2] = false;
		[3] = false;
		[4] = false;
		[5] = false;
		[6] = false;
		[7] = false;
		[8] = false;
		[9] = false;
		[10] = false;
		[11] = false;
		[12] = false;
		[13] = false;
		[14] = false;
		[15] = false;
		[16] = false;
		[17] = false;
		[18] = false;
		[19] = false;
		[20] = false;
		[21] = false;
		[22] = false;
		[23] = false;
		[24] = false;
		[25] = false;
		[26] = false;
		[27] = false;
		[28] = false;
		[29] = false;
		[30] = false;
		[31] = true;
		[32] = false;
		[33] = false;
		[34] = false;
		[35] = false;
		[36] = false;
		[37] = false;
		[38] = false;
	};
	["filters"] = {
		[1] = "Gause On/Off";
		[2] = "AOE On/Off";
		[3] = "Opener Disable";
		[4] = "";
		[5] = "";
	};
	["skills"] = {
		[1] = {
			["alias"] = "----- AOE -----";
			["gcdtime"] = 0.5;
			["id"] = 225;
			["prio"] = 1;
		};
		[2] = {
			["filtertwo"] = "Off";
			["id"] = 16497;
			["levelmin"] = 52;
			["maxRange"] = 12;
			["name"] = "Auto Crossbow";
			["prio"] = 2;
			["tarange"] = 12;
			["terange"] = 12;
		};
		[3] = {
			["alias"] = "Spread Shot - AOE";
			["filtertwo"] = "Off";
			["gcdtime"] = 0.5;
			["id"] = 2870;
			["ignoremoving"] = true;
			["levelmin"] = 18;
			["maxRange"] = 12;
			["name"] = "Spread Shot";
			["playerlevelmin"] = 18;
			["prio"] = 3;
			["tarange"] = 8;
			["tecount"] = 3;
			["terange"] = 8;
		};
		[4] = {
			["alias"] = "----- Single Target -----";
			["gcdtime"] = 0.5;
			["maxRange"] = 25;
			["prio"] = 4;
		};
		[5] = {
			["gcd"] = "True";
			["gcdtime"] = 0.5;
			["id"] = 16498;
			["ignoremoving"] = true;
			["levelmin"] = 58;
			["maxRange"] = 25;
			["name"] = "Drill";
			["prio"] = 5;
		};
		[6] = {
			["gcd"] = "True";
			["gcdtime"] = 0.5;
			["id"] = 2872;
			["ignoremoving"] = true;
			["levelmin"] = 4;
			["maxRange"] = 25;
			["name"] = "Hot Shot";
			["prio"] = 6;
		};
		[7] = {
			["id"] = 7413;
			["ignoremoving"] = true;
			["maxRange"] = 25;
			["name"] = "Heated Clean Shot";
			["pcskill"] = "7412,2868";
			["prio"] = 7;
		};
		[8] = {
			["gcdtime"] = 0.5;
			["id"] = 2873;
			["ignoremoving"] = true;
			["levelmin"] = 35;
			["maxRange"] = 25;
			["name"] = "Clean Shot";
			["pcskill"] = "7412,2868";
			["playerlevelmin"] = 35;
			["prio"] = 8;
		};
		[9] = {
			["gcd"] = "False";
			["id"] = 7412;
			["ignoremoving"] = true;
			["levelmin"] = 60;
			["maxRange"] = 25;
			["name"] = "Heated Slug Shot";
			["pcskill"] = "7411,2866";
			["prio"] = 9;
		};
		[10] = {
			["gcdtime"] = 0.5;
			["id"] = 2868;
			["ignoremoving"] = true;
			["levelmin"] = 2;
			["maxRange"] = 25;
			["name"] = "Slug Shot";
			["pcskill"] = "7411,2866";
			["playerlevelmin"] = 2;
			["prio"] = 10;
		};
		[11] = {
			["id"] = 7411;
			["ignoremoving"] = true;
			["levelmin"] = 54;
			["maxRange"] = 25;
			["name"] = "Heated Split Shot";
			["prio"] = 11;
		};
		[12] = {
			["gcdtime"] = 0.5;
			["id"] = 2866;
			["ignoremoving"] = true;
			["levelmin"] = 1;
			["maxRange"] = 25;
			["name"] = "Split Shot";
			["playerlevelmin"] = 1;
			["prio"] = 12;
		};
		[13] = {
			["alias"] = "----- oGCD -----";
			["gcdtime"] = 0.5;
			["maxRange"] = 25;
			["prio"] = 13;
		};
		[14] = {
			["id"] = 7541;
			["ignoremoving"] = true;
			["levelmin"] = 8;
			["maxRange"] = 0;
			["name"] = "Second Wind";
			["phpb"] = 50;
			["playerlevelmin"] = 8;
			["prio"] = 14;
			["trg"] = "Player";
		};
		[15] = {
			["gauge1gt"] = 50;
			["id"] = 17209;
			["levelmin"] = 30;
			["maxRange"] = 0;
			["name"] = "Hypercharge";
			["prio"] = 15;
			["trg"] = "Player";
		};
		[16] = {
			["gcd"] = "True";
			["gcdtime"] = 0.5;
			["id"] = 2876;
			["ignoremoving"] = true;
			["levelmin"] = 10;
			["maxRange"] = 0;
			["name"] = "Reassemble";
			["playerlevelmin"] = 10;
			["prio"] = 16;
			["trg"] = "Player";
		};
		[17] = {
			["gcdtime"] = 0.5;
			["id"] = 2890;
			["ignoremoving"] = true;
			["levelmin"] = 60;
			["maxRange"] = 25;
			["name"] = "Ricochet";
			["playerlevelmin"] = 60;
			["prio"] = 17;
			["tarange"] = 5;
			["terange"] = 5;
		};
		[18] = {
			["gcdtime"] = 0.5;
			["id"] = 2874;
			["ignoremoving"] = true;
			["levelmin"] = 54;
			["maxRange"] = 25;
			["name"] = "Gauss Round";
			["playerlevelmin"] = 54;
			["prio"] = 18;
		};
		[19] = {
			["gauge2gt"] = 95;
			["gcd"] = "True";
			["gcdtime"] = 0.5;
			["id"] = 2864;
			["ignoremoving"] = true;
			["levelmin"] = 40;
			["maxRange"] = 0;
			["name"] = "Rook Autoturret";
			["prio"] = 19;
			["trg"] = "Player";
		};
	};
	["version"] = 3;
}
return obj1
