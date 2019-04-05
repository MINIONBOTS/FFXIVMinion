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
		[8] = true;
		[9] = true;
		[10] = true;
		[11] = true;
		[12] = true;
		[13] = true;
		[14] = true;
		[15] = true;
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
		[31] = false;
		[32] = false;
		[33] = false;
		[34] = false;
		[35] = false;
		[36] = false;
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
			["condition"] = "Good";
			["cpmax"] = 72;
			["cpnbuff"] = "254";
			["durabmax"] = 11;
			["id"] = 100098;
			["name"] = "Tricks of the Trade";
			["prio"] = 1;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[2] = {
			["condition"] = "Excellent";
			["cpbuff"] = "262";
			["durabmin"] = 15;
			["id"] = 100126;
			["iqstack"] = 6;
			["name"] = "Byregot's Brow";
			["prio"] = 2;
			["type"] = 9;
		};
		[3] = {
			["condition"] = "Good";
			["cpbuff"] = "262";
			["durabmin"] = 15;
			["id"] = 100125;
			["iqstack"] = 8;
			["name"] = "Byregot's Brow";
			["prio"] = 3;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[4] = {
			["condition"] = "Excellent";
			["cpbuff"] = "262";
			["durabmin"] = 15;
			["id"] = 100009;
			["iqstack"] = 6;
			["name"] = "Byregot's Blessing";
			["prio"] = 4;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[5] = {
			["condition"] = "Good";
			["cpbuff"] = "262";
			["durabmin"] = 15;
			["id"] = 100009;
			["iqstack"] = 8;
			["name"] = "Byregot's Blessing";
			["prio"] = 5;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[6] = {
			["cpnbuff"] = "254+262+256";
			["durabmin"] = 11;
			["id"] = 100098;
			["name"] = "Tricks of the Trade";
			["prio"] = 6;
			["qualitymaxper"] = 100;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[7] = {
			["cpnbuff"] = "254";
			["durabmax"] = 11;
			["id"] = 100098;
			["name"] = "Tricks of the Trade";
			["prio"] = 7;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[8] = {
			["cpbuff"] = "251";
			["cpmax"] = 116;
			["cpmin"] = 56;
			["cpnbuff"] = "254";
			["durabmax"] = 21;
			["durabmin"] = 15;
			["id"] = 261;
			["name"] = "Great Strides";
			["playerlevelmin"] = 21;
			["prio"] = 8;
		};
		[9] = {
			["durabmax"] = 11;
			["id"] = 100017;
			["name"] = "Master's Mend";
			["prio"] = 9;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[10] = {
			["cpnbuff"] = "254";
			["durabmax"] = 16;
			["durabmin"] = 15;
			["id"] = 100121;
			["name"] = "Byregot's Brow";
			["prio"] = 10;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[11] = {
			["cpbuff"] = "254";
			["id"] = 100121;
			["name"] = "Byregot's Brow";
			["prio"] = 11;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[12] = {
			["cpbuff"] = "254";
			["id"] = 100009;
			["name"] = "Byregot's Blessing";
			["prio"] = 12;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[13] = {
			["cpmax"] = 56;
			["cpnbuff"] = "254";
			["durabmax"] = 21;
			["durabmin"] = 15;
			["id"] = 100009;
			["name"] = "Byregot's Blessing";
			["prio"] = 13;
			["type"] = 9;
		};
		[14] = {
			["cpnbuff"] = "261";
			["id"] = 286;
			["name"] = "Comfort Zone";
			["playerlevelmin"] = 50;
			["prio"] = 14;
			["stepmax"] = 15;
		};
		[15] = {
			["cpnbuff"] = "251";
			["id"] = 253;
			["name"] = "Inner Quiet";
			["playerlevelmin"] = 11;
			["prio"] = 15;
			["stepmax"] = 4;
		};
		[16] = {
			["cpbuff"] = "251";
			["cpnbuff"] = "256";
			["id"] = 283;
			["name"] = "Ingenuity II";
			["playerlevelmin"] = 50;
			["prio"] = 16;
		};
		[17] = {
			["alias"] = "CS3 High Quality";
			["id"] = 100204;
			["name"] = "Careful Synthesis III";
			["prio"] = 17;
			["qualityminper"] = 100;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[18] = {
			["alias"] = "CS2 High Quality";
			["id"] = 100069;
			["name"] = "Careful Synthesis II";
			["playerlevelmax"] = 62;
			["prio"] = 18;
			["qualityminper"] = 100;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[19] = {
			["cpbuff"] = "251";
			["cpnbuff"] = "262";
			["durabmin"] = 15;
			["id"] = 281;
			["name"] = "Steady Hand II";
			["playerlevelmin"] = 37;
			["prio"] = 19;
		};
		[20] = {
			["cpmin"] = 134;
			["durabmin"] = 15;
			["id"] = 100129;
			["name"] = "Precise Touch";
			["prio"] = 20;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[21] = {
			["cpbuff"] = "262";
			["durabmin"] = 15;
			["id"] = 100196;
			["name"] = "Hasty Touch II";
			["prio"] = 21;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[22] = {
			["cpmin"] = 121;
			["durabmin"] = 15;
			["id"] = 100196;
			["name"] = "Hasty Touch II";
			["prio"] = 22;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[23] = {
			["cpmin"] = 134;
			["durabmin"] = 15;
			["id"] = 100016;
			["name"] = "Basic Touch";
			["prio"] = 23;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[24] = {
			["durabmin"] = 15;
			["id"] = 100108;
			["name"] = "Hasty Touch";
			["prio"] = 24;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[25] = {
			["id"] = 100204;
			["name"] = "Careful Synthesis III";
			["prio"] = 25;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[26] = {
			["id"] = 100069;
			["name"] = "Careful Synthesis II";
			["playerlevelmax"] = 62;
			["prio"] = 26;
			["singleuseonly"] = false;
			["type"] = 9;
		};
		[27] = {
			["id"] = 100063;
			["name"] = "Careful Synthesis";
			["prio"] = 27;
			["type"] = 9;
		};
		[28] = {
			["id"] = 100090;
			["name"] = "Basic Synthesis";
			["prio"] = 28;
			["type"] = 9;
		};
	};
	["version"] = 3;
}
return obj1
