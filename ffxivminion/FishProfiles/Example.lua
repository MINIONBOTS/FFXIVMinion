--[[
:::	Valid Task Parameters
"condition" - Table parameter listing various extra conditions required to perform this task, can be used to evaluate lua code.
"complete" - Table parameter listing various extra conditions that will cause this task to complete, can be used to evaluate lua code.
"lowpriority","normalpriority","highpriority" - affects task evaluations (advanced).
"weatherlast","weathernow","weathernext" - used to evaluate weather conditions for the "mapid" tag listed for the task.
"eorzeaminhour","eorzeamaxhour" - used to evaluate the eorzea time ranges a task is valid.
"lastshiftmin" - used to evaluate a minimun amount of time (in seconds) since last weather shift
"lastshiftmax" - used to evaluate a maximum amount of time (in seconds) since last weather shift
"nextshiftmin" - used to evaluate a minimun amount of time (in seconds) until next weather shift
"nextshiftmax" - used to evaluate a maximum amount of time (in seconds) until next weather shift
"maxtime" - used to evaluate the maximum amount of time spent at low priority nodes (works like marker timers).

:::: Fish Specific Parameters

["usemooch"] = true/false;
["usepatience"] = true/false;
["usepatience2"] = true/false;
["usechum"] = true/false;
["usefisheyes"] = true/false;
["usesnagging"] = true/false;
["usecollect"] = true/false;
["usedoublehook"] = true/false;
["baitname"] = "Bloodworm,Butterworm";	

["whitelist"] = "Some Fish,Someother Fish";
["whitelisthq"] = "Some Fish,Someother Fish";
["blacklist"] = "Some Fish,Someother Fish";
["blacklisthq"] = "Some Fish,Someother Fish,Andthis Fishtoo";
["moochables"] = "Some Fish,Someother Fish";

-- Rebuy bait of a particular ID in a certain quantity.
["rebuy"] = {
	[2585] = 99;
};

:::: General Parameters
["usestealth"] - boolean - default: false - should stealth be used for this task - ex: ["usestealth"] = true; 
["dangerousarea"] - boolean - default: false - should extra stealth precaution be taken in this area - ex: ["dangerousarea"] = true; 

::: Further
using the weather or eorzea time tags automatically configure a task as high priority.
high priority tasks with lower indexes will take priority if multiple high priority tasks are viable.
task indexes do not necessarily need to be perfectly in order.
--]]
local obj1 = {
	["tasks"] = {
		[1] = {
			["minlevel"] = 1;
			["maxlevel"] = 60;
			["mapid"] = 145;
			["pos"] = {
				["x"] = -205.67;
				["y"] = -37.25;
				["z"] = 153.8;
				["h"] = -0.619;
			};
			["usemooch"] = true;
			["usepatience"] = false;
			["usepatience2"] = false;
			["usechum"] = true;
			["baitname"] = "Bloodworm,Butterworm";		
			--["maxtime"] = 30000;
			["rebuy"] = {
				--["Bloodworm"] = 99;
				["Butterworm"] = 99;
			};
		};
		[2] = {
			["minlevel"] = 1;
			["maxlevel"] = 60;
			["mapid"] = 145;
			["pos"] = {
				["x"] = -384.48;
				["y"] = -21.39;
				["z"] = -38.98;
				["h"] = -1.843;
			};
			["usemooch"] = true;
			["usepatience"] = false;
			["usepatience2"] = false;
			["usechum"] = true;
			["baitname"] = "Bloodworm,Butterworm";	
			--["maxtime"] = 30000;
			["rebuy"] = {
				--["Bloodworm"] = 99;
				["Butterworm"] = 99;
			};
		};
				--[[
		[3] = {
			["minlevel"] = 1;
			["maxlevel"] = 60;
			["mapid"] = 156;
			["pos"] = {
				["x"] = 458.55;
				["y"] = -4.55;
				["z"] = -747.7;
				["h"] = 0.639;
			};
			["usemooch"] = true;
			["usepatience"] = false;
			["usepatience2"] = false;
			["usechum"] = true;
			["baitname"] = "Caddisfly Larva";
			["maxtime"] = 30000;
			["usestealth"] = true;
		}
		--]]
	};
}
return obj1