--[[
:::	General Task Parameters
"condition" - Table parameter listing various extra conditions required to perform this task, can be used to evaluate lua code.
"complete" - Table parameter listing various extra conditions that will cause this task to complete, can be used to evaluate lua code.
"lowpriority","normalpriority","highpriority" - affects task evaluations (advanced).
"weatherlast","weathernow","weathernext" - used to evaluate weather conditions for the "mapid" tag listed for the task.
"eorzeaminhour","eorzeamaxhour" - used to evaluate the eorzea time ranges a task is valid.
"lastshiftmin" - used to evaluate a minimun amount of time (in seconds) since last weather shift
"lastshiftmax" - used to evaluate a maximum amount of time (in seconds) since last weather shift
"nextshiftmin" - used to evaluate a minimun amount of time (in seconds) until next weather shift
"nextshiftmax" - used to evaluate a maximum amount of time (in seconds) until next weather shift
"maxtime" - used to evaluate the maximum amount of time spent at low priority nodes (works like marker timers)
"timeout" - used to move onto other tasks for team-like marker setups, time in milliseconds  - ex: ["timeout"] = 2000; 

::: Gathering-Specific Task Parameters
* gathermaps - variant - default: false, indicates which, if any special map items should be gathered
* gathergardening - variant - default: false, indicates which, if any gardening items should be gathered
* gatherrares - variant - default: false, indicates which, if any rare items should be gathered, rare items are ones which do not always appear, but can be gathered multiple times on the nodes in which they appear
* gatherspecialrares - variant - default: false, indicates which, if any special rare items should be gathered, special rares are items which disappear after a single collection
* "gatherchocofood" - variant - default: false, indicates which, if any chocobo items should be gathered

Variants above support the following example inputs:
["gathermaps"] = true;  (gather any map)
["gathermaps"] = false; (gather no map)
["gathermaps"] = "12243"; (gather only dragonskin map) (singular contentid of an item)
["gathermaps"] = "12243,6692"; (gather dragonskin or peisteskin maps) (multiple comma-separated contentid's of items)

* "item1" - string - default: "" - singular item name with 1st priority on the given set of nodes - ex: ["item1"] = "Cotton Boll";
* "item2" - string - default: "" - singular item name with 2nd priority on the given set of nodes - ex: ["item2"] = "Wind Crystal";
* "usestealth" - boolean - default: false - should stealth be used for this task - ex: ["usestealth"] = true; 
* "dangerousarea" - boolean - default: false - should extra stealth precaution be taken in this area - ex: ["dangerousarea"] = true; 
* "resetdaily" - boolean - default: false - should task only be valid for one node per day, much like unspoiled (note that unspoiled contentid's 5-8 are already handled in this manner) - ["resetdaily"] = true;
* "skillprofile" - string - default: "" - specifies the name of the skill profile to be used - ex: ["skillprofile"] = "Botanist";
* "mingp" - integer - default: 0 - specifies a minimum GP before node is undertaken - ex: ["mingp"] = 550;
* "usecordials" - boolean - default: follows Use Cordials GUI option - specifies to use cordials to help regain GP faster - ex: ["usecordials"] = true;
* "type" - string - default: "" - specifies the type of task, if job needs to be switched. if job needs to be switched, please make sure the Miner Gearset and Botanist Gearset is setup correctly - valid options are "botany" or "mining".
* "whitelist" - string - default: "" - specifies contentids of valid node types - ex: ["whitelist"] = "3;4";   ["whitelist"] = "4";
* "radius" - integer - default: 500 - specifies the search range of nodes - ex: ["radius"] = 50; (note: the entitylist can generally only scan up to about 120, so anything past this is basically unnecessary.
* "nodeminlevel" - integer - default: 1 - specifies the min level of nodes for this task - ex: ["nodeminlevel"] = 5;
* "nodemaxlevel" - integer - default: 60 - specifies the max level of nodes for this task - ex: ["nodemaxlevel"] = 10;
* "unspoiled" - boolean - default: nil - performs automatic whitelisting/blacklisting of nodes - ex: ["unspoiled"] = true; would whitelist only unspoiled nodes, whereas ["unspoiled"] = false; would blacklist them and find only regular nodes.


::: Further
using the weather or eorzea time tags automatically configure a task as high priority.
high priority tasks with lower indexes will take priority if multiple high priority tasks are viable.
task indexes do not necessarily need to be perfectly in order.
--]]
local obj1 = {
	["setup"] = {
		["gearsetmining"] = 2;
		["gearsetbotany"] = 3;
	};
	["tasks"] = {
		[1] = {
			["minlevel"] = 1;
			["maxlevel"] = 60;
			["mapid"] = 148;
			["pos"] = {
				["x"] = 16.26;
				["y"] = -8;
				["z"] = 82.03;
				["h"] = -1.52;
			};
			["type"] = "botany";
			["whitelist"] = "4";
			["gathergardening"] = true;
			["item1"] = "Wind Crystal";
			["item2"] = "Cotton Boll";	
			-- Task will only start if we have less than 2000 wind shards (item id 4).
			["condition"] = {
				["ItemCount(4) < 2000"] = true;
			};
			-- Task will end once we have 2000 wind shards (item id 4).
			["complete"] = {
				["GetInventoryItemGains(4) >= 2000"] = true;
			};
		};
		[2] = {
			["minlevel"] = 50;
			["maxlevel"] = 60;
			["mapid"] = 156;
			["pos"] = {
				["x"] = 269.61639404297;
				["y"] = -4.9172973632813;
				["z"] = -534.17919921875;
				["h"] = 2.7272355556488;
			};
			["type"] = "mining";
			["gathergardening"] = true;
			["item1"] = "Fire Cluster";
			["eorzeaminhour"] = 17;
			["eorzeamaxhour"] = 20;
		};
		[3] = {
			["minlevel"] = 50;
			["maxlevel"] = 60;
			["mapid"] = 156;
			["pos"] = {
				["x"] = 269.61639404297;
				["y"] = -4.9172973632813;
				["z"] = -534.17919921875;
				["h"] = 2.7272355556488;
			};
			["type"] = "mining";
			["gathergardening"] = true;
			["item1"] = "Wind Cluster";
			["eorzeaminhour"] = 21;
			["eorzeamaxhour"] = 0;
		};
	};
}
return obj1