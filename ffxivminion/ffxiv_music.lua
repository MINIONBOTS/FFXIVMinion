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
	
	tracks = {
		[1] = {
			extension = false,
			octave = 0,
			tempo = 100,
			notelength = 4,
			position = 1,
			delay = 0,
			mml = "",
		},
	},
	
	last_wrap = 0,
	
	--[[
	mml = "",
	octave = 0,
	tempo = 100,
	notelength = 4,
	volume = 10,
	position = 1,
	delay = 0,
	--]]
	last_note = -1,
	is_playing = false,
	
	actions = {
		["b#"] = 1, ["c"] = 1, 
		["c#"] = 2, ["d-"] = 2, 
		["d"] = 3, 
		["d#"] = 4, ["e-"] = 4, 
		["e"] = 5, ["f-"] = 5, 
		["e#"] = 6, ["f"] = 6, 
		["f#"] = 7, ["g-"] = 7,
		["g"] = 8, 
		["g#"] = 9, ["a-"] = 9, 
		["a"] = 10, 
		["a#"] = 11, ["b-"] = 11, 
		["b"] = 12, ["c-"] = 12, 
	},
	
	replay = {},
	
	GUI = {
		open = false,
		visible = true,
	}, 
	
	fileNames = {},
	files = {},
	filePath = GetStartupPath() .. [[\LuaMods\ffxivminion\MMLFiles\]],
}

function ffxiv_music.Reset()
	ffxiv_music.extension = false
	ffxiv_music.octave = 0
	ffxiv_music.tempo = 100
	ffxiv_music.notelength = 4
	ffxiv_music.volume = 10
	ffxiv_music.position = 1
	
	ffxiv_music.CreateTrack(1)
end

function ffxiv_music.SetTempo()
	local tracks = ffxiv_music.tracks
	if (table.valid(tracks)) then
		local track = tracks[1]
		if (track) then
		
			local temp = deepcopy(track)
			local tempo = temp.tempo
			
			local pos = 1
			local tempoFound = false
		
			repeat
				local pos = temp.position
				local str = temp.mml
				
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

				if c then 
					temp.position = pos + (newpos - 1)
					
					if c == "t" then -- Set tempo
						if (tonumber(args) ~= nil) then
							tempo = tonumber(args)
							tempoFound = true
						end
					elseif c == "r" or c == "p" then -- Rest
						tempoFound = true
					elseif c == "l" then -- Set note length
						if (tonumber(args) ~= nil) then
							--ffxiv_music.notelength = tonumber(args)
							temp.notelength = tonumber(args)
						end
					elseif c == ">" then -- Increase octave
						tempoFound = true
					elseif c == "<" then
						tempoFound = true
					elseif c:find("[a-g]") then
						tempoFound = true
					end
				end
				
				if (newpos == 0) then
					tempoFound = true
				end	
				
			until (tempoFound == true)
			
			d("setting tempo to ["..tostring(tempo).."]")
			
			for i,track in pairs(tracks) do
				if (i > 1) then
					track.tempo = tempo
				end
			end		
		end
	end
end

function ffxiv_music.CreateTrack(i, mml)
	local mml = IsNull(mml,"")
	ffxiv_music.tracks[i] = {
		playing = false,
		extension = false,
		octave = 0,
		tempo = 100,
		notelength = 4,
		position = 1,
		delay = 0,
		mml = mml,
	}
end

function ffxiv_music.StopPlayback()
	if (table.valid(ffxiv_music.tracks)) then
		for i,track in pairs(ffxiv_music.tracks) do
			track.playing = false
		end
	end
	ffxiv_music.is_playing = false
end

function ffxiv_music.StartPlayback()
	if (table.valid(ffxiv_music.tracks)) then
		for i,track in pairs(ffxiv_music.tracks) do
			track.playing = true
		end
	end
	ffxiv_music.SetTempo()
	ffxiv_music.last_note = -1
	ffxiv_music.is_playing = true
end

function ffxiv_music.Init()
	ffxiv_music.UpdateFiles()
	
	gMusicTrack = ffxivminion.GetSetting("gMusicTrack",1)
	gMusicText = ffxivminion.GetSetting("gMusicText","")
	gMusicMML = ffxivminion.GetSetting("gMusicMML",GetString("None"))
	gMusicMMLIndex = GetKeyByValue(gMusicMML,ffxiv_music.files) or 1
	if (ffxiv_music.files[gMusicMMLIndex] ~= gMusicMML) then
		gMusicMML = ffxiv_music.files[gMusicMMLIndex] or GetString("None")
	end
	
	if (gMusicMML ~= GetString("None")) then
		ffxiv_music.LoadMML(gMusicMML)
	end

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
		gMusicText = content
	end
end

--local test = wrapText("asfbererasdfawerawefasdfawefe",50)

function wrapText(str,width)
	local str = IsNull(str,"")
	local width = IsNull(width,0)
	if (width > 0) then
		local newstr = ""
		
		if (str and str ~= "") then
			for line in string.split(str,"\n") do
				local newline = line
				local textlen = string.len(newline)
				local i = 1
				
				local fulltextx = GUI:CalcTextSize(string.sub(newline,1))
				--d("fulltextx:"..tostring(fulltextx)..",textx:"..tostring(textx))
				if (fulltextx >= (width - 40)) then
				
					while i <= textlen do
						local section = string.sub(newline,1,i)
						local textx = GUI:CalcTextSize(string.sub(section,1,i))
						
						if (textx >= (width - 40)) then
							newstr = newstr..section.."\n"
							newline = string.sub(newline,i+1)
							textlen = string.len(newline)
				
							i = 1
						else
							i = i + 1
							if (i > textlen) then
								newstr = newstr..section.."\n"
							end
						end
					end
				else
					newstr = newstr..newline.."\n"
				end
			end
		end
		str = newstr
	end
	return str
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
				
				GUI:PushItemWidth(80)
				GUI_DrawIntMinMax("Track to Play","gMusicTrack",0,0)
				GUI:PopItemWidth()
				
				GUI:Spacing(); GUI:Spacing()
				
				local availableWidth = GUI:GetContentRegionAvailWidth()
				
				--last_wrap
				if (TimeSince(ffxiv_music.last_wrap) > 1500) then
					gMusicText = wrapText(gMusicText,availableWidth)
					ffxiv_music.last_wrap = Now()
				end
				gMusicText,changed = GUI:InputTextMultiline("##reaction-code-add", gMusicText, availableWidth, 250)
				if (changed) then
					local newText = wrapText(gMusicText,availableWidth)
					gMusicText = newText
					Settings.FFXIVMINION.gMusicText = gMusicText
				end
				if (ffxiv_music.is_playing) then
					if (GUI:Button("Stop Playing")) then
						ffxiv_music.StopPlayback()
					end
				else
					if (GUI:Button("Resume Playing")) then
						ffxiv_music.StartPlayback()
					end
					GUI:SameLine(0,10)
					if (GUI:Button("Play From Beginning")) then
						ffxiv_music.Reset()
						
						local i = 1
						for track in string.split(gMusicText,",") do
							if (string.valid(track)) then
								ffxiv_music.CreateTrack(i, string.gsub(track,"\n",""))
								d("create track:"..tostring(i)..","..tostring(track))
							end
							i = i + 1
						end
						ffxiv_music.StartPlayback()
					end
				end
			end
			GUI:End()
		end
	end
end

function ffxiv_music.OnUpdate( event, tickcount )
	local gamestate = MGetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxiv_music.is_playing) then
		
			if (not ml_global_information.IsYielding()) then
				local tracks = ffxiv_music.tracks
				if (table.valid(tracks)) then
					local isPlaying = false
					if (table.size(tracks) >= gMusicTrack) then
						local track = tracks[gMusicTrack]
						if (track and track.playing) then
							isPlaying = true
							ffxiv_music.currentTrack = gMusicTrack
							ffxiv_music.ParseMML(track)
						end
					elseif (tracks[1]) then
						if (tracks[1].playing) then
							isPlaying = true
							ffxiv_music.currentTrack = 1
							ffxiv_music.ParseMML(tracks[1])
						end
					end
					if (not isPlaying) then
						ffxiv_music.is_playing = false
						KeyUp(16)
						KeyUp(17)
					end				
				end
			end
		end
	end
end

function ffxiv_music.ShiftOctave(octave)
	if (octave < 0) then
		KeyUp(16)
		KeyDown(17)
		ml_global_information.Await(10, function () return (GUI:IsKeyDown(17) and not GUI:IsKeyDown(16)) end)
	elseif (octave == 0) then
		KeyUp(16)
		KeyUp(17)
		ml_global_information.Await(10, function () return (not GUI:IsKeyDown(16) and not GUI:IsKeyDown(16)) end)
	elseif (octave > 0) then
		KeyUp(17)
		KeyDown(16)
		ml_global_information.Await(10, function () return (GUI:IsKeyDown(16) and not GUI:IsKeyDown(17)) end)
	end
end

-- See http://www.phy.mtu.edu/~suits/NoteFreqCalcs.html
-- for information on calculating note frequencies.
function ffxiv_music.DoAction(note, octave)	
	d("play note ["..tostring(note).."],["..tostring(octave).."]")
	
	local actions = ffxiv_music.actions
	local control = GetControl("PerformanceMode")
	if (control) then
		if (note == "c" and octave > 1) then
			control:PushButton(23,12)
			ffxiv_music.last_note = 12
		else
			local noteid = actions[note]
			if (noteid) then
				control:PushButton(23,noteid-1)
				ffxiv_music.last_note = (noteid-1)
			end
		end
	end
	
	return nil
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
	return ((240/notefrac) / bpm * 1000)
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

function ffxiv_music.ParseMML(track)
	local str = IsNull(track.mml,"")
	
	if (Now() < track.delay) then
		if (Now() + 10 >= track.delay and ffxiv_music.last_note ~= -1 and not track.extension) then
			local control = GetControl("PerformanceMode")
			if (control) then
				control:PushButton(24,ffxiv_music.last_note)
				ffxiv_music.last_note = -1
			end
		end
		return false		
	end
	
	local playedNote = false
	
	repeat
		local octave = track.octave
		local tempo = track.tempo
		local notelength = track.notelength
		local volume = track.volume
		local pos = track.position
			
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

		if c then 
			track.position = pos + (newpos - 1)			
			--d("moving track ["..tostring(ffxiv_music.currentTrack).."] to position ["..tostring(track.position).."] c ["..tostring(c).."] args ["..tostring(args).."]")
			--ffxiv_music.position = pos + (newpos - 1)
			--d("new position"..tostring(ffxiv_music.position))

			if c == "o" then -- Set octave
				if (tonumber(args) ~= nil) then
					local oct = tonumber(args)
					if (oct > 2) then
						d("cannot reach octave ["..tostring(oct).."], too high")
						--ffxiv_music.octave = 2
						track.octave = 2
					elseif (oct < -1) then
						d("cannot reach octave ["..tostring(oct).."], too low")
						--ffxiv_music.octave = -1
						track.octave = -1
					else
						--ffxiv_music.octave = oct
						track.octave = oct
					end
				end
			elseif c == "t" then -- Set tempo
				if (tonumber(args) ~= nil) then
					--ffxiv_music.tempo = tonumber(args)
					track.tempo = tonumber(args)
				end
			elseif c == "v" then -- Set volume (doesn't really do anything on ffxiv)
				ffxiv_music.volume = tonumber(args)
			elseif c == "r" or c == "p" then -- Rest
				local delay
				if (tonumber(args) ~= nil) then
					--d("r delay args ["..tostring(tonumber(length)).."] @ pos ["..tostring(newpos).."]")
					delay = ffxiv_music.CalculateNoteTime(tonumber(args),tempo)
				else
					--d("r delay ["..tostring(notelength).."] @ pos ["..tostring(newpos).."]")
					delay = ffxiv_music.CalculateNoteTime(notelength, tempo)
				end
				
				--d("delay (ms):"..tostring(delay))
				--ffxiv_music.delay = Now() + delay
				track.delay = Now() + delay
				--coroutine.yield(nil, delay, nil)
				playedNote = true
			elseif c == "l" then -- Set note length
				if (tonumber(args) ~= nil) then
					--ffxiv_music.notelength = tonumber(args)
					track.notelength = tonumber(args)
				else
					d("args @ ["..tostring(newpos).."] for length was invalid ["..tostring(args).."]")
				end
			elseif c == ">" then -- Increase octave
				if (track.octave < 2) then
					track.octave = octave + 1
					d("shifting octave up")
					ffxiv_music.ShiftOctave(track.octave)
					return true
				end
			elseif c == "<" then -- Decrease octave
				if (track.octave > -1) then
					track.octave = octave - 1
					d("shifting octave up")
					ffxiv_music.ShiftOctave(track.octave)
					return true
				end
			elseif c:find("[a-g]") then -- Play note
				if (not track.extension) then
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
				end
				
				local notetime
				local length = string.match(args, "%d+")
				if (tonumber(length) ~= nil) then
					length = math.abs(length)
					--d("length ["..tostring(tonumber(length)).."] @ pos ["..tostring(newpos).."]")
					notetime = ffxiv_music.CalculateNoteTime(tonumber(length), tempo)
				else
					--d("notelength ["..tostring(notelength).."] @ pos ["..tostring(newpos).."]")
					notetime = ffxiv_music.CalculateNoteTime(notelength, tempo)
				end

				-- Dotted notes
				if string.find(args, "%.") then
					notetime = notetime * 1.5
				end
				
				track.delay = Now() + notetime
				
				local extend = string.match(args,"[&]")
				if (extend ~= nil) then
					track.extension = true
				else
					track.extension = false
				end
				
				playedNote = true
			end
		else
			playedNote = true
		end
		
		if (newpos == 0) then
			track.playing = false
			local control = GetControl("PerformanceMode")
			if (control) then
				control:PushButton(24,ffxiv_music.last_note)
				ffxiv_music.last_note = -1
			end
		end	
	
	until (playedNote == true)
end

function ffxiv_music.ToggleMenu()
	ffxiv_music.GUI.open = not ffxiv_music.GUI.open
end

RegisterEventHandler("Module.Initalize",ffxiv_music.Init)
RegisterEventHandler("Gameloop.Update",ffxiv_music.OnUpdate)
RegisterEventHandler("Gameloop.Draw", ffxiv_music.DrawCall)
RegisterEventHandler("Music.toggle", ffxiv_music.ToggleMenu)