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
		[36] = false;
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
			["gatheraddsbuff"] = "757";
			["gpstart"] = 600;
			["id"] = 301;
			["name"] = "Impulsive Appraisal II";
			["prio"] = 1;
		};
		[2] = {
			["collweareq"] = 10;
			["gatheraddsbuff"] = "760";
			["gatheraddsmark"] = "ideal";
			["gpbuff"] = "757";
			["gpstart"] = 600;
			["id"] = 4084;
			["name"] = "Single Mind";
			["prio"] = 2;
			["pskillg"] = "301,302";
			["singleuseonly"] = false;
		};
		[3] = {
			["collweareq"] = 10;
			["gatheraddsbuff"] = "758";
			["gatherrequiresmark"] = "ideal";
			["gpbuff"] = "760";
			["gpnbuff"] = "758";
			["gpstart"] = 600;
			["id"] = 4079;
			["name"] = "Utmost Caution";
			["prio"] = 3;
			["pskillg"] = "4098,4084";
			["singleuseonly"] = false;
		};
		[4] = {
			["collweareq"] = 10;
			["gatherrequiresmark"] = "ideal";
			["gpbuff"] = "758";
			["gpstart"] = 600;
			["id"] = 4075;
			["name"] = "Methodical Appraisal";
			["prio"] = 4;
			["pskillg"] = "4093,4079";
			["singleuseonly"] = false;
		};
		[5] = {
			["collweareq"] = 10;
			["gatheraddsbuff"] = "757";
			["gatherrequiresmark"] = "ideal";
			["gpstart"] = 600;
			["id"] = 301;
			["name"] = "Impulsive Appraisal II";
			["prio"] = 5;
			["pskillg"] = "4075,4089";
			["singleuseonly"] = false;
		};
		[6] = {
			["collweareq"] = 20;
			["gatheraddsbuff"] = "760";
			["gatherrequiresmark"] = "ideal";
			["gpbuff"] = "757";
			["gpstart"] = 600;
			["id"] = 4084;
			["name"] = "Single Mind";
			["prio"] = 6;
			["pskillg"] = "301,302";
			["singleuseonly"] = false;
		};
		[7] = {
			["collweareq"] = 20;
			["gatheraddsbuff"] = "757";
			["gatherrequiresmark"] = "ideal";
			["gpnbuff"] = "757";
			["gpstart"] = 600;
			["id"] = 4078;
			["name"] = "Discerning Eye";
			["prio"] = 7;
			["pskillg"] = "301,302";
			["singleuseonly"] = false;
		};
		[8] = {
			["collweareq"] = 20;
			["gatherrequiresmark"] = "ideal";
			["gpstart"] = 600;
			["id"] = 4075;
			["name"] = "Methodical Appraisal";
			["prio"] = 8;
			["pskillg"] = "4098,4084,4092,4078";
			["singleuseonly"] = false;
		};
		[9] = {
			["collweareq"] = 10;
			["gatheraddsbuff"] = "757";
			["gatheraddsmark"] = "backup";
			["gpnbuff"] = "757";
			["gpstart"] = 600;
			["id"] = 301;
			["name"] = "Impulsive Appraisal II";
			["prio"] = 9;
			["pskillg"] = "301,302";
			["singleuseonly"] = false;
		};
		[10] = {
			["collweareq"] = 20;
			["gatherrequiresmark"] = "backup";
			["gpnbuff"] = "757";
			["gpstart"] = 600;
			["id"] = 4075;
			["name"] = "Methodical Appraisal";
			["prio"] = 10;
			["pskillg"] = "301,302";
			["singleuseonly"] = false;
		};
		[11] = {
			["collweareq"] = 20;
			["gatheraddsbuff"] = "760";
			["gatherrequiresmark"] = "backup";
			["gpbuff"] = "757";
			["gpstart"] = 600;
			["id"] = 4084;
			["name"] = "Single Mind";
			["prio"] = 11;
			["pskillg"] = "301,302";
			["singleuseonly"] = false;
		};
		[12] = {
			["gatheraddsbuff"] = "758";
			["gatherrequiresmark"] = "backup";
			["gpstart"] = 600;
			["id"] = 4079;
			["name"] = "Utmost Caution";
			["prio"] = 12;
			["pskillg"] = "4098,4084";
			["singleuseonly"] = false;
		};
		[13] = {
			["collweareq"] = 20;
			["gatherrequiresmark"] = "backup";
			["gpbuff"] = "758";
			["gpstart"] = 600;
			["id"] = 4075;
			["name"] = "Methodical Appraisal";
			["prio"] = 13;
			["pskillg"] = "4093,4079";
			["singleuseonly"] = false;
		};
		[14] = {
			["collweareq"] = 20;
			["gatherrequiresmark"] = "backup";
			["gpstart"] = 600;
			["id"] = 4075;
			["name"] = "Methodical Appraisal";
			["prio"] = 14;
			["pskillg"] = "4089,4075";
			["singleuseonly"] = false;
		};
		[15] = {
			["collweareq"] = 20;
			["id"] = 4075;
			["name"] = "Methodical Appraisal";
			["prio"] = 15;
		};
		[16] = {
			["collwearlt"] = 10;
			["id"] = 301;
			["name"] = "Impulsive Appraisal II";
			["prio"] = 16;
			["singleuseonly"] = false;
		};
	};
	["version"] = 3;
}
return obj1
