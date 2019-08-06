-- Persistent Data
local multiRefObjects = {

} -- multiRefObjects
local obj1 = {
	["classes"] = {
		[1] = false;
		[2] = false;
		[3] = false;
		[4] = true;
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
		[22] = true;
		[23] = false;
		[24] = false;
		[25] = false;
		[26] = false;
		[27] = false;
		[28] = false;
		[29] = false;
		[30] = false;
		[31] = false;
		[32] = false;
		[33] = false;
		[34] = false;
		[35] = false;
		[36] = false;
		[37] = false;
		[38] = false;
	};
	["filters"] = {
		[1] = "Jumps Off";
		[2] = "Aoe Off";
		[3] = "Stuns Off";
		[4] = "Buffs Off";
		[5] = "Battle Litany Off";
	};
	["skills"] = {
		[1] = {
			["id"] = 16158;
			["levelmin"] = 70;
			["maxRange"] = 0;
			["name"] = "Continuation";
			["prio"] = 1;
		};
		[2] = {
			["id"] = 16157;
			["levelmin"] = 70;
			["maxRange"] = 0;
			["name"] = "Continuation";
			["prio"] = 2;
		};
		[3] = {
			["id"] = 16156;
			["levelmin"] = 70;
			["maxRange"] = 0;
			["name"] = "Continuation";
			["prio"] = 3;
		};
		[4] = {
			["id"] = 16149;
			["levelmin"] = 40;
			["maxRange"] = 0;
			["name"] = "Demon Slaughter";
			["pcskill"] = "16141";
			["prio"] = 4;
			["tarange"] = 5;
			["tecount"] = 3;
			["terange"] = 5;
			["trg"] = "Player";
		};
		[5] = {
			["id"] = 16141;
			["levelmin"] = 10;
			["maxRange"] = 0;
			["name"] = "Demon Slice";
			["prio"] = 5;
			["tarange"] = 5;
			["tecount"] = 3;
			["terange"] = 5;
			["trg"] = "Player";
		};
		[6] = {
			["id"] = 16150;
			["levelmin"] = 60;
			["maxRange"] = 3;
			["name"] = "Wicked Talon";
			["prio"] = 6;
		};
		[7] = {
			["id"] = 16147;
			["levelmin"] = 60;
			["maxRange"] = 3;
			["name"] = "Savage Claw";
			["prio"] = 7;
		};
		[8] = {
			["gcd"] = "False";
			["id"] = 16146;
			["levelmin"] = 60;
			["maxRange"] = 3;
			["name"] = "Gnashing Fang";
			["prio"] = 8;
		};
		[9] = {
			["gauge1gt"] = 1;
			["id"] = 16162;
			["levelmin"] = 30;
			["maxRange"] = 3;
			["name"] = "Burst Strike";
			["prio"] = 9;
			["skncdtimemin"] = 10;
			["sknoffcd"] = "16146";
		};
		[10] = {
			["id"] = 16153;
			["levelmin"] = 54;
			["maxRange"] = 3;
			["name"] = "Sonic Break";
			["prio"] = 10;
			["ptrg"] = "Enemy";
			["skncdtimemin"] = 10;
			["sknoffcd"] = "16138";
		};
		[11] = {
			["id"] = 16145;
			["levelmin"] = 26;
			["maxRange"] = 3;
			["name"] = "Solid Barrel";
			["pcskill"] = "16139";
			["prio"] = 11;
		};
		[12] = {
			["id"] = 16139;
			["levelmin"] = 4;
			["maxRange"] = 3;
			["name"] = "Brutal Shell";
			["pcskill"] = "16137";
			["prio"] = 12;
		};
		[13] = {
			["id"] = 16137;
			["levelmin"] = 1;
			["maxRange"] = 3;
			["name"] = "Keen Edge";
			["prio"] = 13;
		};
		[14] = {
			["id"] = 16143;
			["levelmin"] = 15;
			["maxRange"] = 15;
			["name"] = "Lightning Shot";
			["prio"] = 20;
		};
		[15] = {
			["gauge1gt"] = 1;
			["gcd"] = "True";
			["gcdtime"] = 1;
			["id"] = 16138;
			["levelmin"] = 2;
			["maxRange"] = 0;
			["name"] = "No Mercy";
			["prio"] = 14;
			["trg"] = "Player";
		};
		[16] = {
			["id"] = 16159;
			["levelmin"] = 62;
			["maxRange"] = 0;
			["name"] = "Bow Shock";
			["prio"] = 15;
			["skncdtimemin"] = 10;
			["sknoffcd"] = "16138";
			["tarange"] = 5;
			["terange"] = 5;
			["trg"] = "Player";
		};
		[17] = {
			["id"] = 16144;
			["levelmin"] = 18;
			["maxRange"] = 3;
			["name"] = "Blasting Zone";
			["prio"] = 16;
			["skncdtimemin"] = 10;
			["sknoffcd"] = "16138";
		};
		[18] = {
			["id"] = 16165;
			["levelmin"] = 80;
			["maxRange"] = 3;
			["name"] = "Blasting Zone";
			["prio"] = 17;
			["skncdtimemin"] = 10;
			["sknoffcd"] = "16138";
		};
		[19] = {
			["gauge1or"] = "0,0";
			["gcdtime"] = 1;
			["id"] = 16164;
			["levelmin"] = 76;
			["maxRange"] = 25;
			["name"] = "Bloodfest";
			["prio"] = 18;
		};
		[20] = {
			["gcd"] = "False";
			["id"] = 16154;
			["levelmin"] = 56;
			["maxRange"] = 15;
			["name"] = "Rough Divide";
			["prio"] = 19;
		};
	};
	["version"] = 3;
}
return obj1
