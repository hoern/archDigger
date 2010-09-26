local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local f = CreateFrame("Frame", "adFrame")
local debug_me = false
local survey_counter = 0
local jigger = false

if archDB == nil then 
	archDB = {
		total = 0,
		waypoints = {}
	}
end

function debug(...)
	if debug_me then
		print(...)
	end
end

local aDdO = ldb:NewDataObject("archDigger", {
      type = "data source",
      icon = "Interface\\Icons\\trade_archaeology",
      text = "archDigger",
      label = "aD",
      version = "1.0",
      align = "right",
      ["X-Category"] = "Information"
});

f:RegisterEvent("SKILL_LINES_CHANGED")
f:RegisterEvent("PLAYER_ALIVE")
f:RegisterEvent("ARTIFACT_HISTORY_READY")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
f:RegisterEvent("CHAT_MSG_LOOT")
f:RegisterEvent("ARTIFACT_HISTORY_READY")

f:SetScript("OnEvent", function(self, event, ...)

	if event == "SKILL_LINES_CHANGED" and IsAddOnLoaded('Blizzard_ArchaeologyUI') then
		debug("SKILL_LINES_CHANGED fired")
		if jigger == true then
			updatearchDigger()
		end

	elseif event == "PLAYER_ALIVE" then
		debug("PLAYER_ALIVE fired")
		ArchaeologyFrame_LoadUI()
		
	elseif event == "ARTIFACT_HISTORY_READY" then
		RequestArtifactCompletionHistory()
		jigger = true
		debug("ARTIFACT_HISTORY_READY fired")
	
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		unit, spell, _, _ = ...
		if unit == "player" and spell == "Survey" then
			survey_counter = survey_counter + 1
			debug("Survey Number " .. survey_counter .. " launched")
		elseif unit == "player" and spell == "Searching for Artifacts" then
			finalcount = survey_counter
			archDB.total = archDB.total + finalcount
			survey_counter = 0
		end
	
	elseif event == "CHAT_MSG_LOOT" then
  --[[ You receive currency: Fossil Archaeology Fragment x4.]]
		msg = ...
		atype, amount = strmatch(msg, "You receive currency: (.+) Archaeology Fragment x(%d+)")
		if atype then
			local zone = GetZoneText()
			local subzone = GetSubZoneText()
			debug("Picked up " .. amount .. " of " .. atype .. " in " .. subzone .. "(" .. zone .. ")" .. " after " .. finalcount .. "tries.")
			tinsert(archDB.waypoints, { amount, atype, zone, subzone, finalcount })
		end
	end
end)

--[[ function aDdO:OnEnter()
   end]]

function format_line(amount, atype, zone, subzone, finalcount)
	local x = format(" Found |cFF00FF00%s|r fragments of |cFF00FF00%s|r origin in |cFFFF0000%s (%s)|r after |cFFFFFFFF%s|r tries", amount, atype, zone, subzone, finalcount)
	return x
end

function aDdO:OnTooltipShow()
	updatearchDigger()
	GameTooltip:AddLine("|TInterface\\Icons\\trade_archaeology:16|t archDigger", 1, 0, 0)
	GameTooltip:AddDoubleLine("Total Surveys Done:", archDB.total )
	if digs then
		for k,v in pairs(digs) do
			GameTooltip:AddDoubleLine(v[1], v[2])
		end
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("|cFFFF0000Latest Discoveries:|r")

	entries = #(archDB.waypoints)

	if entries > 20 then
		for z = (entries - 20), entries do
			v = select(1, archDB.waypoints[z])
			GameTooltip:AddLine(format_line(v[1], v[2], v[3], v[4] or v[3], v[5]))
		end
	else
		for z = 1, entries do
			v = select(1, archDB.waypoints[z])
			GameTooltip:AddLine(format_line(v[1], v[2], v[3], v[4] or v[3], v[5]))
		end
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Click to open Artifact Frame")
end

function aDdO:OnClick()
	if(not IsAddOnLoaded('Blizzard_ArchaeologyUI')) then
		ArchaeologyFrame_LoadUI()
		debug("Loaded ArchaeologyFrame")
	end
	updatearchDigger()
	if IsShiftKeyDown() then
		ShowUIPanel(ArchaeologyFrame)
	else
		ShowUIPanel(ArchaeologyFrame)
  --[[ TODO: stats frame]]
	end
end

function updatearchDigger()
	digs = {}
	local _, _, arch = GetProfessions();
	if arch then
		name, texture, rank, maxRank = GetProfessionInfo(arch);
		ad_progressiontext = format("%s/%s", rank, maxRank);
		local numRaces = GetNumArchaeologyRaces();
		
		for i = 1, 10 do --[[ GetNumArchaeologyRaces() do]]
			if GetNumArtifactsByRace(i) > 0 then
				local name, currency, texture, itemID =  GetArchaeologyRaceInfo(i);
				SetSelectedArtifact(i)
				local base, adjust, totalCost = GetArtifactProgress()
				local count = base + adjust
				if count > totalCost then
					colorstring = "|cFF00FF00"
				elseif tonumber(count) > tonumber(totalCost) / 2 then
					colorstring = "|cFFFFFF00"
				else 
					colorstring = "|cFFFF0000"
				end
				digs[name] = { format("|T%s:0|t %s:", texture, name), format("%s%s/%s|r", colorstring, count, totalCost) }
			end
		end
		aDdO.text = ad_progressiontext
	else
		aDdO.text = "Learn Archaeology!"
		digs["none"] = "Find a trainer in a major city!"
	end
end