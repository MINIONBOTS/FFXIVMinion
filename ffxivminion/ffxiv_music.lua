-- https://github.com/mirrexagon/lua-mml/blob/master/mml.lua
ffxiv_music = {
	ref_freq = 440, -- A4
	ref_octave = 4,
	root_multi = 2^(1/12), -- A constant: the twelfth root of two.
	steps = {
		a = 0,
		b = 2,
		c = -9,
		d = -7,
		e = -5,
		f = -4,
		g = -2
	},
	
	mml = "",
	
	octave = 0,
	tempo = 60,
	notelength = 4,
	volume = 10,
	position = 1,
	is_playing = false,
	delay = 0,
	
	actions = {
		[-1] = {
			["c"] = 1, ["c#"] = 2, ["d"] = 3, ["e-"] = 4, ["e"] = 5, ["f"] = 6, ["f#"] = 7, ["g"] = 8, ["g#"] = 9, ["a"] = 10, ["b-"] = 11, ["b"] = 12,
		},
		[0] = {
			["c"] = 13, ["c#"] = 14, ["d"] = 15, ["e-"] = 16, ["e"] = 17, ["f"] = 18, ["f#"] = 19, ["g"] = 20, ["g#"] = 21, ["a"] = 22, ["b-"] = 23, ["b"] = 24,
		},
		[1] = {
			["c"] = 25, ["c#"] = 26, ["d"] = 27, ["e-"] = 28, ["e"] = 29, ["f"] = 30, ["f#"] = 31, ["g"] = 32, ["g#"] = 33, ["a"] = 34, ["b-"] = 35, ["b"] = 36,
		},
		[2] = {
			["c"] = 37, --["c#"] = 39, ["d"] = 3, ["e-"] = 4, ["e"] = 5, ["f"] = 6, ["f#"] = 7, ["g"] = 8, ["g#"] = 9, ["a"] = 10, ["b-"] = 11, ["b"] = 12,
		},
	},
	
	GUI = {
		open = false,
		visible = true,
	}, 
	
	fileNames = {},
	files = {},
	filePath = GetStartupPath() .. [[\LuaMods\ffxivminion\MMLFiles\]],
}

function ffxiv_music.Reset()
	ffxiv_music.octave = 0
	ffxiv_music.tempo = 60
	ffxiv_music.notelength = 4
	ffxiv_music.volume = 10
	ffxiv_music.position = 1
end

function ffxiv_music.Init()
	ffxiv_music.UpdateFiles()
	
	gMusicMML = ffxivminion.GetSetting("gMusicMML",GetString("None"))
	gMusicMMLIndex = GetKeyByValue(gMusicMMLIndex,ffxiv_music.files) or 1
	if (ffxiv_music.files[gMusicMMLIndex] ~= gMusicMML) then
		gMusicMML = ffxiv_music.files[gMusicMMLIndex] or GetString("None")
	end
	
	if (gMusicMML ~= GetString("None")) then
		ffxiv_music.LoadMML(gMusicMML)
	end
	
	gMusicText = ffxivminion.GetSetting("gMusicText","")
	ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_Music", name = "Music", onClick = function() ffxiv_music.GUI.open = not ffxiv_music.GUI.open end, tooltip = "Open the Music editor."},"FFXIVMINION##MENU_HEADER")
end

function ffxiv_music.UpdateFiles()
	ffxiv_music.files = {GetString("None")}
	if (FolderExists(ffxiv_music.filePath)) then
		local fileList = FolderList(ffxiv_music.filePath,[[(.*)mml$]])
		if (table.valid(fileList)) then		
			for i,profile in pairs(fileList) do
				profileName = string.gsub(profile, ".mml", "")
				table.insert(ffxiv_music.files,profileName)
			end	
		end
	end
end

function ffxiv_music.LoadMML(filename)
	local fullpath = ffxiv_music.filePath..filename..".mml"

	if (FileExists(fullpath)) then
		local file = io.open(fullpath, "r") -- r read mode and b binary mode
		if not file then 
			d("file could not be read")
			return nil 
		end
		local content = file:read "*a"
		file:close()
		--d("content type:"..tostring(type(content)))
		--d("content:"..tostring(content))
		gMusicText = content
	end
end

function ffxiv_music.DrawCall(event, ticks )
	local gamestate = GetGameState()
	if ( gamestate == FFXIV.GAMESTATE.INGAME ) then 
		if ( ffxiv_music.GUI.open  ) then 
			GUI:SetNextWindowSize(580,300,GUI.SetCond_FirstUseEver) --SetCond_FirstUseEver
			ffxiv_music.GUI.visible, ffxiv_music.GUI.open = GUI:Begin("FFXIV Performance Music", ffxiv_music.GUI.open)
			if ( ffxiv_music.GUI.visible ) then
				
				GUI:PushItemWidth(200)
				local changed = GUI_Combo("MML File", "gMusicMMLIndex", "gMusicMML", ffxiv_music.files)
				if (changed) then
					Settings.FFXIVMINION.gMusicMML = gMusicMML
					ffxiv_music.LoadMML(gMusicMML)
				end
				GUI:PopItemWidth()
				
				GUI:Spacing(); GUI:Spacing()
				
				local availableWidth = GUI:GetContentRegionAvailWidth()
				gMusicText,changed = GUI:InputTextMultiline("##reaction-code-add", gMusicText, availableWidth, 250)
				if (changed) then
					Settings.FFXIVMINION.gMusicText = gMusicText
				end
				if (ffxiv_music.is_playing) then
					if (GUI:Button("Stop Playing")) then
						ffxiv_music.is_playing = false
					end
				else
					if (GUI:Button("Play Song")) then
						ffxiv_music.mml = gMusicText
						ffxiv_music.Reset()
						ffxiv_music.is_playing = true
					end
				end
			end
			GUI:End()
		end
	end
end

function ffxiv_music.OnUpdate( event, tickcount )
	local gamestate = GetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxiv_music.is_playing) then
			ffxiv_music.ParseMML(str)
		end
	end
end

-- See http://www.phy.mtu.edu/~suits/NoteFreqCalcs.html
-- for information on calculating note frequencies.
function ffxiv_music.DoAction(note, octave)
	local actions = ffxiv_music.actions
	if (table.valid(actions[octave])) then
		if (actions[octave][note]) then
			--d("Playing designated note [" .. note .. "], octave ["..tostring(octave).."]")
			local action = ActionList:Get(28, actions[octave][note])
			if (action and not action.isoncd) then
				--action:Cast(Player.id)
				action:Cast()
				return true
			end
		end
	else
		--d("couldn't find octave ["..tostring(octave).."]")
		if (octave > -1) then
			for i = octave, -1, -1 do
				if (actions[i] and actions[i][note]) then
					local action = ActionList:Get(28, actions[i][note])
					if (action and not action.isoncd) then
						--d("Playing altered note [" .. note .. "], desired-octave ["..tostring(octave).."], played-octave ["..tostring(i).."]")
						--action:Cast(Player.id)
						action:Cast()
						return true
					end
				end
			end
		else
			for i = octave, 2 do
				if (actions[i] and actions[i][note]) then
					local action = ActionList:Get(28, actions[i][note])
					if (action and not action.isoncd) then
						--d("Playing altered note [" .. note .. "], desired-octave ["..tostring(octave).."], played-octave ["..tostring(i).."]")
						--action:Cast(Player.id)
						action:Cast()
						return true
					end
				end
			end
		end
	end
end

function ffxiv_music.CalculateNoteFrequency(n)
	return ffxiv_music.ref_freq * (ffxiv_music.root_multi ^ n)
end

function ffxiv_music.CalculateNoteSteps(str)
	local note, sharp, octave = string.match(str, "(%a)(#?)(%d)")
	return (octave - ffxiv_music.ref_octave)*12 + steps[note] + (sharp == "" and 0 or 1)
end

-- Calculates how long a note is in seconds given a note fraction
-- (quarter note = 4, half note = 2, etc.) and a tempo (in beats per minute).
function ffxiv_music.CalculateNoteTime(notefrac, bpm)
	return (240/notefrac) / bpm
end

function ffxiv_music.CalculateNote(note, outputType)
	local steps = ffxiv_music.CalculateNoteSteps(note)
	if outputType == "frequency" then
		return ffxiv_music.CalculateNoteFrequency(steps)
	elseif outputType == "steps" then
		return steps
	elseif outputType == "multiplier" then
		return ffxiv_music.root_multi ^ steps
	end
end

function ffxiv_music.ParseMML(str)
	local str = IsNull(str,ffxiv_music.mml)
	
	if (Now() < ffxiv_music.delay) then
		--d("delaying playback")
		return false
	end
	
	local octave = ffxiv_music.octave
	local tempo = ffxiv_music.tempo
	local notelength = ffxiv_music.notelength
	local volume = ffxiv_music.volume

	local pos = ffxiv_music.position
		
	local c, args, newpos = string.match(
		string.sub(str, pos),
		"^([%a<>])(%A-)%s-()[%a<>]"
	)

	if not c then -- Might be the last command in the string.
		c, args = string.match(
			string.sub(str, pos),
			"^([%a<>])(%A-)"
		)
		newpos = 0
	end

	if not c then -- Probably bad syntax.
		error("Malformed MML")
	end

	ffxiv_music.position = pos + (newpos - 1)
	--d("new position"..tostring(ffxiv_music.position))

	if c == "o" then -- Set octave
		ffxiv_music.octave = tonumber(args)

	elseif c == "t" then -- Set tempo
		ffxiv_music.tempo = tonumber(args)

	elseif c == "v" then -- Set volume (doesn't really do anything on ffxiv)
		ffxiv_music.volume = tonumber(args)

	elseif c == "r" or c == "p" then -- Rest
		local delay
		if args ~= "" then
			delay = ffxiv_music.CalculateNoteTime( tonumber(args), tempo )
		else
			delay = ffxiv_music.CalculateNoteTime(notelength, tempo)
		end
		
		delay = (delay * 1000)
		
		--d("delay (ms):"..tostring(delay))
		ffxiv_music.delay = Now() + delay
		--coroutine.yield(nil, delay, nil)

	elseif c == "l" then -- Set note length
		ffxiv_music.notelength = tonumber(args)

	elseif c == ">" then -- Increase octave
		if (ffxiv_music.octave < 2) then
			ffxiv_music.octave = octave + 1
		end

	elseif c == "<" then -- Decrease octave
		if (ffxiv_music.octave > -1) then
			ffxiv_music.octave = octave - 1
		end
	elseif c:find("[a-g]") then -- Play note
		local note
		local mod = string.match(args, "[+#-]")
		if mod then
			if mod == "#" or mod == "+" then
				note = c .. "#"
			elseif mod == "-" then
				note = c .. "-"
			end
		else
			note = c
		end
		
		ffxiv_music.DoAction(note, octave)

		local notetime
		local len = string.match(args, "%d+")
		if len then
			notetime = ffxiv_music.CalculateNoteTime(tonumber(len), tempo)
		else
			notetime = ffxiv_music.CalculateNoteTime(notelength, tempo)
		end

		-- Dotted notes
		if string.find(args, "%.") then
			notetime = notetime * 1.5
		end
		notetime = notetime * 1000
		
		--d("notetime (ms):"..tostring(notetime))
		ffxiv_music.delay = Now() + notetime
	end
	
	if (newpos == 0) then
		ffxiv_music.is_playing = false
	end	
end

function ffxiv_music.ToggleMenu()
	ffxiv_music.GUI.open = not ffxiv_music.GUI.open
end

RegisterEventHandler("Module.Initalize",ffxiv_music.Init)
RegisterEventHandler("Gameloop.Update",ffxiv_music.OnUpdate)
RegisterEventHandler("Gameloop.Draw", ffxiv_music.DrawCall)
RegisterEventHandler("Music.toggle", ffxiv_music.ToggleMenu)