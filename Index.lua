World.SpawnDefaultSun()

ScoreboardToggled = false
PressToChange = false
IsHider = false
-- Prop hunt data
PropHunt = {
    remaining_time = 0,
    match_state = 0,
    current_spectating_index
}

Events.Subscribe("setTeam", function(hider)
    if(hider == ROLES.HIDER) then
        IsHider = true
    else
        IsHider = false 
    end
end)


------------- UI HANDLING ----------------
Events.Subscribe("UpdateMatchState", function(new_state,remaining_time)
    PropHunt.remaining_time = remaining_time - 1
    PropHunt.match_state = new_state

    if(new_state == MATCH_STATES.IN_PROGRESS) then
        -- Load Spectator UI
    elseif(new_state == MATCH_STATES.WAITING_PLAYERS) then
        -- Load Waiting Players UI
    elseif(new_state == MATCH_STATES.POST_TIME) then
        -- Load scoreboard
    elseif(new_state == MATCH_STATES.WARM_UP) then
        if(Client.GetLocalPlayer():GetValue("Role") == ROLES.HIDERS) then
            -- Load Hiders UI
        else
            -- Load Seekers UI
        end
    end
end)

--- END MATCH UI
Events.Subscribe("HidersWins", function()
	HUD:CallEvent("SetLabelBig", "HIDERS WIN!")

	if (IsHIder) then
		Sound(Vector(), "halloween-city-park::A_Announcer_Victory", true)
	else
		Sound(Vector(), "halloween-city-park::A_Announcer_Defeat", true)
	end
end)

Events.Subscribe("SeekersWins", function()
	HUD:CallEvent("SetLabelBig", "SEEKERS WIN!")

	if (IsHider == false) then
		Sound(Vector(), "halloween-city-park::A_Announcer_Victory", true)
	else
		Sound(Vector(), "halloween-city-park::A_Announcer_Defeat", true)
	end
end)

------------- UI HANDLING ----------------

----------------------- SPECTATOR FUNCTIONS -----------------------
Input.Register("SpectatePrev", "Left")
Input.Register("SpectateNext", "Right")

Input.Bind("SpectatePrev", InputEvent.Pressed, function()
	SpectateNext(-1)
end)

Input.Bind("SpectateNext", InputEvent.Pressed, function()
	SpectateNext(1)
end)

-- Spectate function
function SpectateNext(index_increment)
	if (Client.GetLocalPlayer():GetControlledCharacter()) then -- Cannot spectate if still alive right?
        return 
    end

	PropHunt.current_spectating_index = PropHunt.current_spectating_index + index_increment

	local players = {}
	for k, v in pairs(Player.GetPairs()) do
		if (v ~= Client.GetLocalPlayer() and v:GetControlledCharacter() ~= nil and v:GetValue("Role") == Client.GetLocalPlayer():GetValue("Role")) then
			table.insert(players, v)
		end
	end

	if (#players == 0) then return end -- No players to spectate

	if (not players[PropHunt.current_spectating_index]) then
		if (index_increment > 0) then
			PropHunt.current_spectating_index = 1
		else
			PropHunt.current_spectating_index = #players
		end
	end

	Client.Spectate(players[PropHunt.current_spectating_index])
end
----------------------- SPECTATOR FUNCTIONS -----------------------







----------------------- CHANGING TO PROP STUFF -----------------------
Client.Subscribe("KeyDown", function(key_name)
    if(key_name == "E" and IsHider) then 
        PressToChange = true 
    end
end)

Client.Subscribe("KeyUp", function(key_name)
    if(key_name == "E") then 
        PressToChange = false
    end
end)

Character.Subscribe("Highlight", function(self, is_highlighted, object)
    if(PressToChange and is_highlighted) then
        Events.CallRemote("ChangeToProp",object:GetAssetName(),object:GetBounds(),object:GetScale():Size(),object:GetLocation().Z)
    end
end)
----------------------- CHANGING TO PROP STUFF -----------------------