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
		[1] = "";
		[2] = "";
		[3] = "";
		[4] = "";
		[5] = "";
	};
	["skills"] = {
		[1] = {
			["gauge1eq"] = 2;
			["id"] = 7400;
			["levelmin"] = 60;
			["maxRange"] = 15;
			["name"] = "Nastrond";
			["prio"] = 1;
			["tarange"] = 15;
			["terange"] = 15;
		};
		[2] = {
			["gauge1or"] = "0,0";
			["id"] = 3553;
			["levelmin"] = 54;
			["maxRange"] = 0;
			["name"] = "Blood of the Dragon";
			["prio"] = 2;
			["trg"] = "Player";
		};
		[3] = {
			["alias"] = "GK - 2 Eye";
			["gauge1or"] = "0,1";
			["gauge2gt"] = 2;
			["id"] = 3555;
			["levelmin"] = 60;
			["maxRange"] = 15;
			["name"] = "Geirskogul";
			["prio"] = 3;
			["tarange"] = 15;
			["terange"] = 15;
		};
		[4] = {
			["alias"] = "GK - 1 Eye";
			["gauge1or"] = "0,1";
			["gauge2lt"] = 1;
			["id"] = 3555;
			["levelmin"] = 60;
			["maxRange"] = 15;
			["name"] = "Geirskogul";
			["pnbuff"] = "1243";
			["prio"] = 4;
			["skncdtimemin"] = 10;
			["sknoffcd"] = "92";
			["tarange"] = 15;
			["terange"] = 15;
		};
		[5] = {
			["gcd"] = "True";
			["id"] = 7399;
			["levelmin"] = 68;
			["maxRange"] = 20;
			["name"] = "Mirage Dive";
			["prio"] = 5;
		};
		[6] = {
			["id"] = 3554;
			["levelmin"] = 56;
			["maxRange"] = 3;
			["name"] = "Fang and Claw";
			["prio"] = 6;
		};
		[7] = {
			["id"] = 3556;
			["levelmin"] = 58;
			["maxRange"] = 3;
			["name"] = "Wheeling Thrust";
			["prio"] = 7;
		};
		[8] = {
			["frontalconeaoe"] = true;
			["id"] = 16477;
			["levelmin"] = 72;
			["maxRange"] = 10;
			["name"] = "Coerthan Torment";
			["pcskill"] = "7397";
			["prio"] = 8;
			["tarange"] = 10;
			["tecount"] = 3;
			["terange"] = 10;
		};
		[9] = {
			["frontalconeaoe"] = true;
			["id"] = 7397;
			["levelmin"] = 62;
			["maxRange"] = 10;
			["name"] = "Sonic Thrust";
			["pcskill"] = "86";
			["prio"] = 9;
			["tarange"] = 10;
			["tecount"] = 3;
			["terange"] = 10;
		};
		[10] = {
			["frontalconeaoe"] = true;
			["id"] = 86;
			["levelmin"] = 40;
			["maxRange"] = 10;
			["name"] = "Doom Spike";
			["prio"] = 10;
			["tarange"] = 10;
			["tecount"] = 3;
			["terange"] = 10;
		};
		[11] = {
			["id"] = 88;
			["levelmin"] = 50;
			["maxRange"] = 3;
			["name"] = "Chaos Thrust";
			["pcskill"] = "87";
			["prio"] = 11;
		};
		[12] = {
			["id"] = 87;
			["levelmin"] = 18;
			["maxRange"] = 3;
			["name"] = "Disembowel";
			["pcskill"] = "75";
			["pnbuff"] = "1914";
			["pnbuffdura"] = 11;
			["prio"] = 12;
		};
		[13] = {
			["id"] = 84;
			["levelmin"] = 26;
			["maxRange"] = 3;
			["name"] = "Full Thrust";
			["pcskill"] = "78";
			["prio"] = 13;
		};
		[14] = {
			["id"] = 78;
			["levelmin"] = 4;
			["maxRange"] = 3;
			["name"] = "Vorpal Thrust";
			["pcskill"] = "75";
			["prio"] = 14;
		};
		[15] = {
			["id"] = 75;
			["levelmin"] = 1;
			["maxRange"] = 3;
			["name"] = "True Thrust";
			["prio"] = 15;
		};
		[16] = {
			["frontalconeaoe"] = true;
			["id"] = 90;
			["levelmin"] = 15;
			["maxRange"] = 15;
			["name"] = "Piercing Talon";
			["prio"] = 16;
			["tecount"] = 3;
		};
		[17] = {
			["id"] = 83;
			["levelmin"] = 6;
			["maxRange"] = 0;
			["name"] = "Life Surge";
			["pcskill"] = "78";
			["prio"] = 21;
			["trg"] = "Player";
		};
		[18] = {
			["id"] = 85;
			["levelmin"] = 30;
			["maxRange"] = 0;
			["name"] = "Lance Charge";
			["prio"] = 17;
			["trg"] = "Player";
		};
		[19] = {
			["id"] = 7398;
			["levelmin"] = 66;
			["maxRange"] = 12;
			["name"] = "Dragon Sight";
			["prio"] = 18;
			["trg"] = "Player";
		};
		[20] = {
			["id"] = 3557;
			["levelmin"] = 52;
			["maxRange"] = 0;
			["name"] = "Battle Litany";
			["prio"] = 19;
			["tarange"] = 15;
			["terange"] = 15;
			["trg"] = "Player";
		};
		[21] = {
			["id"] = 92;
			["levelmin"] = 30;
			["maxRange"] = 20;
			["name"] = "High Jump";
			["prio"] = 20;
		};
		[22] = {
			["id"] = 95;
			["levelmin"] = 45;
			["maxRange"] = 20;
			["name"] = "Spineshatter Dive";
			["prio"] = 22;
		};
		[23] = {
			["id"] = 96;
			["levelmin"] = 50;
			["maxRange"] = 20;
			["name"] = "Dragonfire Dive";
			["prio"] = 23;
			["tarange"] = 5;
			["terange"] = 5;
		};
	};
	["version"] = 3;
}
return obj1
