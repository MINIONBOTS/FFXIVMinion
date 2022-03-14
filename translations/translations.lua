local table = _G["table"]
local math = _G["math"]
local string = _G["string"]
local sqlite3 = _G["sqlite3"]
local json = _G["json"]

local translations = {}
--translations = {}
translations.game = GetGameLanguage == nil and "gw2" or "ffxiv"
translations.dbpath = GetLuaModsPath() .. "\\translations\\translations.db"
translations.texturepath = GetLuaModsPath() .. "\\translations"
translations.open = false
translations.currenttranslation = ""
translations.searchresult = {}
function translations.Init()
	if(gCurrentLanguage == "us" ) then gCurrentLanguage = "en" end
	translations.dbversion = translations.GetVersion()
	translations.LoadTranslations()
end
RegisterEventHandler("Module.Initalize",translations.Init,"translations.Init")

function translations.OnDraw( event, tick )
	if ( translations.open ) then
		GUI:SetNextWindowPosCenter(GUI.SetCond_FirstUseEver)
		GUI:SetNextWindowSize(900,400,GUI.SetCond_Appearing) --set the next window size, only on first ever

		translations.unfolded, translations.open = GUI:Begin(GetString("Translator"), translations.open)
		if(translations.open == false)then
			translations.lasttick = 0 -- force upload on window close
		end
		if ( translations.unfolded ) then
			GUI:Spacing()
			local l_headertxtw = GUI:CalcTextSize(GetString("HelpTranslate"))
			local l_width = GUI:GetContentRegionAvailWidth()
			local l_txth = GUI:GetTextLineHeightWithSpacing()
			GUI:Dummy(l_width / 2 - l_headertxtw / 2, l_txth)
			GUI:SameLine()
			GUI:Text(GetString("HelpTranslate"))
			GUI:Separator()
			GUI:Spacing()
			GUI:Spacing()

			GUI:Columns(2, "##split")
			GUI:SetColumnWidth(0, 250)
			-- String Search Left
			local searchtbl = { [1]="key", [2] ="en", [3] ="de", [4] ="kr", [5] ="cn", [6] ="jp", [7] ="fr", [8] ="ru", [9] ="es"}
			local updatelist = false
			local changed = false
			if(translations.searchtype == nil) then translations.searchtype = 1 end
			GUI:PushItemWidth(50)
			translations.searchtype, changed = GUI:Combo("##tsearchtype", translations.searchtype, searchtbl)
			if(changed) then updatelist = true end
			GUI:PopItemWidth()
			GUI:SameLine();
			GUI:PushItemWidth(100)
			translations.search,changed = GUI:InputText( "##tsearch", translations.search or "")
			translations.search = string.lower(translations.search)
			GUI:PopItemWidth()
			if(changed) then updatelist = true end
			if(updatelist)then
				translations.searchresult = {}
				if(string.len(translations.search) > 1 ) then
					if(translations.searchtype == 1) then
						for key,k in pairs(ml_miniondbstrings) do
							if(string.contains(string.lower(key), translations.search))then
								translations.searchresult[key] = k
							end
						end
					else
						local lang = searchtbl[translations.searchtype]
						for key,k in pairs(ml_miniondbstrings) do
							if(k[lang]) then
								if(string.contains(string.lower(k[lang]), translations.search))then
									translations.searchresult[key] = k
								end
							end
						end
					end
				end
			end

			-- Render List
			local l_width, l_height = GUI:GetContentRegionAvail()
			GUI:PushItemWidth(l_width)
			GUI:ListBoxHeader("##searchlist", #translations.searchresult, l_height / l_txth )
			for key,k in pairs(translations.searchresult) do
				if(translations.searchtype == 1) then
					if(GUI:Selectable(key, false)) then
						translations.currentkey = key
						translations.currenttranslation = ""
						if(k[gCurrentLanguage]) then
							translations.currenttranslation = k[gCurrentLanguage]
						end
					end
				else
					local lang = searchtbl[translations.searchtype]
					if(GUI:Selectable(k[lang].."##"..key, false)) then
						translations.currentkey = key
						translations.currenttranslation = ""
						if(k[gCurrentLanguage]) then
							translations.currenttranslation = k[gCurrentLanguage]
						end
					end
				end
			end
			GUI:ListBoxFooter()
			GUI:PopItemWidth()

			-- Right side
			GUI:NextColumn()
			if( translations.currentkey ~= nil ) then
				GUI:Dummy(10,10)
				GUI:SameLine()
				GUI:BeginGroup()
				local l_width = GUI:GetContentRegionAvailWidth()
				GUI:BulletText(GetString("FromEnglish"))
				GUI:SameLine()
				GUI:PushStyleColor(GUI.Col_Button,0,0,0,0)
				GUI:PushStyleColor(GUI.Col_ButtonHovered,0,0,0,0)
				GUI:PushStyleColor(GUI.Col_ButtonActive,0,0,0,0)
				GUI:ImageButton( "##toflag", translations.texturepath.."\\us.png", 25, 13)
				GUI:PopStyleColor(3)
				GUI:SameLine()
				GUI:ImageButton( "##key", translations.texturepath.."\\questionmark.png", 10, 10)
				if ( GUI:IsItemHovered() ) then GUI:SetTooltip("ID: "..tostring(ml_miniondbstrings[translations.currentkey].id) .. "\nKey: "..translations.currentkey) end
				if(not ml_miniondbstrings[translations.currentkey].en)then
					ml_miniondbstrings[translations.currentkey].en = translations.currentkey
				end
				GUI:InputTextMultiline( "##translF", ml_miniondbstrings[translations.currentkey].en, l_width-50, 75)
				GUI:SameLine()
				if(GUI:ImageButton( "##translatorcopy", translations.texturepath.."\\copy.png", 35, 35))then
					GUI:SetClipboardText(ml_miniondbstrings[translations.currentkey].en)
				end
				if ( GUI:IsItemHovered() ) then GUI:SetTooltip(GetString("Copy to Clipboard")) end
				GUI:EndGroup()


				GUI:Spacing()
				GUI:Dummy(10,10)
				GUI:SameLine()
				GUI:BeginGroup()
				GUI:PushStyleColor(GUI.Col_Button,0,0,0,0)
				GUI:PushStyleColor(GUI.Col_ButtonHovered,0,0,0,0)
				GUI:PushStyleColor(GUI.Col_ButtonActive,0,0,0,0)
				if (gCurrentLanguage == "en") then
					GUI:BulletText(GetString("ToEnglish"))
					GUI:SameLine()
					GUI:ImageButton( "##toflag", translations.texturepath.."\\us.png", 25, 13)
				elseif (gCurrentLanguage == "jp") then
					GUI:BulletText(GetString("ToJapanese"))
					GUI:SameLine()
					GUI:ImageButton( "##toflag", translations.texturepath.."\\jp.png", 25, 13)
				elseif (gCurrentLanguage == "cn") then
					GUI:BulletText(GetString("ToChinese"))
					GUI:SameLine()
					GUI:ImageButton( "##toflag", translations.texturepath.."\\cn.png", 25, 13)
				elseif (gCurrentLanguage == "de") then
					GUI:BulletText(GetString("ToGerman"))
					GUI:SameLine()
					GUI:ImageButton( "##toflag", translations.texturepath.."\\de.png", 25, 13)
				elseif (gCurrentLanguage == "fr") then
					GUI:BulletText(GetString("ToFrench"))
					GUI:SameLine()
					GUI:ImageButton( "##toflag", translations.texturepath.."\\fr.png", 25, 13)
				elseif (gCurrentLanguage == "ru") then
					GUI:BulletText(GetString("ToRussian"))
					GUI:SameLine()
					GUI:ImageButton( "##toflag", translations.texturepath.."\\ru.png", 25, 13)
				elseif (gCurrentLanguage == "kr") then
					GUI:BulletText(GetString("ToKorean"))
					GUI:SameLine()
					GUI:ImageButton( "##toflag", translations.texturepath.."\\kr.png", 25, 13)
				elseif (gCurrentLanguage == "es") then
					GUI:BulletText(GetString("ToSpanish"))
					GUI:SameLine()
					GUI:ImageButton( "##toflag", translations.texturepath.."\\es.png", 25, 13)
				end
				GUI:PopStyleColor(3)
				if(not ml_miniondbstrings[translations.currentkey].en)then
					ml_miniondbstrings[translations.currentkey].en = translations.currentkey
				end
				if (gCurrentLanguage == "en" and translations.currenttranslation == "") then
					translations.currenttranslation = ml_miniondbstrings[translations.currentkey].en
				end
				translations.currenttranslation = GUI:InputTextMultiline( "##translTo", translations.currenttranslation, l_width-50, 75)

				GUI:SameLine()
				if(GUI:ImageButton( "##translatorpaste", translations.texturepath.."\\paste.png", 35, 35))then
					translations.currenttranslation = GUI:GetClipboardText()
				end
				if ( GUI:IsItemHovered() ) then GUI:SetTooltip(GetString("Paste From Clipboard")) end
				GUI:Text(GetString("TryToGetSameWidth"))
				GUI:EndGroup()
				GUI:Dummy(15,15)

				local width,wy = GUI:GetContentRegionAvail()
				GUI:Dummy(1,wy-60)
				GUI:Dummy(10,10)
				GUI:SameLine((width/4)-50)
				if ( GUI:Button(GetString("Cancel"),110,30) ) then
					translations.currenttranslation = ""
					translations.currentkey = nil
					translations.open = false
					translations.lasttick = 0 -- force upload on window close
				end

				GUI:SameLine((width/4*2)-15)
				GUI:Dummy(25, 25)
				if (string.valid(translations.currenttranslation) and not string.empty(translations.currenttranslation)) then
					if (gCurrentLanguage ~= "en" or translations.currenttranslation ~= ml_miniondbstrings[translations.currentkey].en) then
						GUI:SameLine((width/4*3)-50)
						if (GUI:Button(GetString("Submit"),110,30) ) then
							ml_miniondbstrings[translations.currentkey][gCurrentLanguage] = translations.currenttranslation
							ml_miniondbstrings[translations.currentkey].lastupdate = Now()
							-- Save in local db
							local db = sqlite3.open(translations.dbpath)
							if ( db ) then
								db:exec("PRAGMA journal_mode=WAL")
								local stmt							
								if(ml_miniondbstrings[translations.currentkey].id ~= nil) then
									stmt = db:prepare("update "..translations.game.." set lastupdate = ?, key = ?, en = ?, "..gCurrentLanguage.." = ? WHERE id = ?")
								else
									stmt = db:prepare("insert into "..translations.game.." (lastupdate, key, en, "..gCurrentLanguage..") values (?,?,?,?)")
								end
								
								if ( stmt ) then
									stmt:bind(1,ml_miniondbstrings[translations.currentkey].lastupdate)
									stmt:bind(2,translations.currentkey)
									stmt:bind(3,ml_miniondbstrings[translations.currentkey].en)
									stmt:bind(4,translations.currenttranslation)
									if(ml_miniondbstrings[translations.currentkey].id ~= nil) then
										stmt:bind(5,ml_miniondbstrings[translations.currentkey].id)
									end
									stmt:step()
									stmt:reset()
									stmt:finalize()
								end
								d("[Translator] - Updated translation: "..translations.currenttranslation)
								translations.currentkey = nil
								translations.currenttranslation = ""
								_G["ml_memoizedstrings"] = {} -- reset
								db:close()

								-- Update db version
								if(not translations.dbversionupdated) then
									translations.dbversionupdated = true
									translations.SetVersion(translations.dbversion + 1)
								end
							end
						end
					end
				end
			end
			GUI:Columns(1)
		end
		GUI:End()
	end
end
RegisterEventHandler("Gameloop.Draw",translations.OnDraw,"translations.OnDraw")

function translations.LoadTranslations()
	_G["ml_memoizedstrings"] = {} -- reset
	if( fileexist(translations.dbpath) ) then
		local db = sqlite3.open(translations.dbpath)
		if ( db ) then
			local count = 0
			local tick = os.time(os.date("!*t"))
			local sql = "SELECT * FROM "..translations.game

			db:exec("PRAGMA journal_mode=WAL")
			db:exec("PRAGMA synchronous=0")
			db:exec("BEGIN TRANSACTION")

			for id, lastupdate, key, en,de,kr,cn,jp,fr,ru,es in db:urows(sql) do
				if(ml_miniondbstrings[key] == nil) then
					ml_miniondbstrings[key] = {}
				end
				ml_miniondbstrings[key]["id"] = id
				ml_miniondbstrings[key]["lastupdate"] = lastupdate
				if(en and en ~= "" and en ~= " ")then ml_miniondbstrings[key]["en"] = en count = count + 1 end
				if(de and de ~= "" and de ~= " ")then ml_miniondbstrings[key]["de"] = de count = count + 1 end
				if(kr and kr ~= "" and kr ~= " ")then ml_miniondbstrings[key]["kr"] = kr count = count + 1 end
				if(cn and cn ~= "" and cn ~= " ")then ml_miniondbstrings[key]["cn"] = cn count = count + 1 end
				if(jp and jp ~= "" and jp ~= " ")then ml_miniondbstrings[key]["jp"] = jp count = count + 1 end
				if(fr and fr ~= "" and fr ~= " ")then ml_miniondbstrings[key]["fr"] = fr count = count + 1 end
				if(ru and ru ~= "" and ru ~= " ")then ml_miniondbstrings[key]["ru"] = ru count = count + 1 end
				if(es and es ~= "" and es ~= " ")then ml_miniondbstrings[key]["es"] = es count = count + 1 end
			end

			db:exec("END TRANSACTION")
			d("[Translator] - Loaded "..tostring(count).." Translations in "..tostring(os.time(os.date("!*t"))-tick).." seconds.")
			db:close()
			_G["ml_memoizedstrings"] = {} -- reset
		end
	end
end

function translations.GetVersion()
	if( fileexist(translations.dbpath) ) then
		local dbVersion
		local db = sqlite3.open(translations.dbpath)
		if ( db ) then
			local sql = "SELECT version FROM version"
			for version in db:urows(sql) do
				dbVersion = version
				break
			end
			db:close()
			d("[Translator]: DB Version: "..tostring(dbVersion))			
			return dbVersion
		end
	end
end

function translations.SetVersion(version)
	if( fileexist(translations.dbpath) ) then
		local db = sqlite3.open(translations.dbpath)
		local stmt = db:prepare("update version set version = ? WHERE id = 1")
		if ( stmt ) then
			stmt:bind(1,version)
			stmt:step()
			stmt:reset()
			stmt:finalize()
		end
		d("[Translator]: Updated DB Version to: "..tostring(version))
		db:close()
	end
end

--_G["translations"] = translations

local Translator = {}
function Translator.ShowMenu()
	translations.open = true
end
function Translator.Reload()
	translations.LoadTranslations()
end
_G["Translator"] = Translator