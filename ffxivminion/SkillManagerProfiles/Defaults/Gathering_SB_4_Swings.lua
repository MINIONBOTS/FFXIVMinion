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
		[16] = true;
		[17] = true;
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
	};
	["filters"] = {
		[1] = "";
		[2] = "";
		[3] = "";
		[4] = "";
		[5] = "";
	};
	["mingp"] = 600;
	["skills"] = {
		[1] = {
			["alias"] = "Folk Buffed UC (MIN)";
			["collwearlt"] = 20;
			["gpbuff"] = "999";
			["gpnbuff"] = "758";
			["id"] = 4079;
			["name"] = "Utmost Caution";
			["prio"] = 1;
		};
		[2] = {
			["alias"] = "Folk Buffed UC (BOT)";
			["collwearlt"] = 20;
			["gpbuff"] = "999";
			["gpnbuff"] = "758";
			["id"] = 4093;
			["name"] = "Utmost Caution";
			["prio"] = 2;
		};
		[3] = {
			["alias"] = "3rd skill UC (MIN)";
			["collweareq"] = 20;
			["gpnbuff"] = "758";
			["id"] = 4079;
			["name"] = "Utmost Caution";
			["prio"] = 3;
		};
		[4] = {
			["alias"] = "3rd Skill UC (BOT)";
			["collweareq"] = 20;
			["gpnbuff"] = "758";
			["id"] = 4093;
			["name"] = "Utmost Caution";
			["prio"] = 4;
		};
		[5] = {
			["alias"] = "Single Mind 3 (MIN)";
			["collraritygt"] = 350;
			["collweareq"] = 20;
			["gpnbuff"] = "760";
			["id"] = 4084;
			["name"] = "Single Mind";
			["prio"] = 5;
			["singleuseonly"] = false;
		};
		[6] = {
			["alias"] = "Single Mind 3 (BOT)";
			["collraritygt"] = 350;
			["collweareq"] = 20;
			["gpnbuff"] = "760";
			["id"] = 4098;
			["name"] = "Single Mind";
			["prio"] = 6;
			["singleuseonly"] = false;
		};
		[7] = {
			["alias"] = "First Swing IA2 (MIN)";
			["collwearlt"] = 1;
			["id"] = 301;
			["name"] = "Impulsive Appraisal II";
			["prio"] = 7;
			["singleuseonly"] = false;
		};
		[8] = {
			["alias"] = "First Swing IA2 (BOT)";
			["collwearlt"] = 1;
			["id"] = 302;
			["name"] = "Impulsive Appraisal II";
			["prio"] = 8;
			["singleuseonly"] = false;
		};
		[9] = {
			["alias"] = "First Swing IA (MIN)";
			["collwearlt"] = 1;
			["id"] = 4077;
			["name"] = "Impulsive Appraisal";
			["prio"] = 9;
			["singleuseonly"] = false;
		};
		[10] = {
			["alias"] = "First Swing IA (BOT)";
			["collwearlt"] = 1;
			["id"] = 4091;
			["name"] = "Impulsive Appraisal";
			["prio"] = 10;
			["singleuseonly"] = false;
		};
		[11] = {
			["alias"] = "DE (BOT)";
			["collraritylt"] = 330;
			["collweargt"] = 10;
			["collwearlt"] = 20;
			["gpnbuff"] = "757";
			["id"] = 4078;
			["name"] = "Discerning Eye";
			["prio"] = 11;
			["singleuseonly"] = false;
		};
		[12] = {
			["alias"] = "DE (MIN)";
			["collraritylt"] = 330;
			["collweargt"] = 10;
			["collwearlt"] = 20;
			["gpnbuff"] = "757";
			["id"] = 4092;
			["name"] = "Discerning Eye";
			["prio"] = 12;
			["singleuseonly"] = false;
		};
		[13] = {
			["alias"] = "Swing 2 IA2 (MIN)";
			["collraritygt"] = 103;
			["collweareq"] = 10;
			["id"] = 301;
			["name"] = "Impulsive Appraisal II";
			["prio"] = 13;
			["singleuseonly"] = false;
		};
		[14] = {
			["alias"] = "Swing 2 IA2 (BOT)";
			["collraritygt"] = 103;
			["collweareq"] = 10;
			["id"] = 302;
			["name"] = "Impulsive Appraisal II";
			["prio"] = 14;
			["singleuseonly"] = false;
		};
		[15] = {
			["alias"] = "Swing 2 IA (MIN)";
			["collraritygt"] = 103;
			["collweareq"] = 10;
			["id"] = 4077;
			["name"] = "Impulsive Appraisal";
			["prio"] = 15;
			["singleuseonly"] = false;
		};
		[16] = {
			["alias"] = "Swing 2 IA (BOT)";
			["collraritygt"] = 103;
			["collweareq"] = 10;
			["id"] = 4091;
			["name"] = "Impulsive Appraisal";
			["prio"] = 16;
			["singleuseonly"] = false;
		};
		[17] = {
			["alias"] = "Normal MA (MIN)";
			["collwearlt"] = 20;
			["id"] = 4075;
			["name"] = "Methodical Appraisal";
			["prio"] = 17;
			["singleuseonly"] = false;
		};
		[18] = {
			["alias"] = "Normal MA (BOT)";
			["collwearlt"] = 20;
			["id"] = 4089;
			["name"] = "Methodical Appraisal";
			["prio"] = 18;
			["singleuseonly"] = false;
		};
	};
	["version"] = 3;
}
return obj1
