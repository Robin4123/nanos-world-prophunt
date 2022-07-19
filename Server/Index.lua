Package.RequirePackage("nanos-world-weapons")

DefaultWeapons = {
	NanosWorldWeapons.AK47,
	NanosWorldWeapons.M1911,
	NanosWorldWeapons.Rem870,
	NanosWorldWeapons.AWP,
	NanosWorldWeapons.SMG11,
}

-- Change back when done testing
PropHuntSettings = {
	prep_time = 5,--60, -- 1 minute to hide
    match_time = 10,--600, -- 10 minutes to search
    post_time = 5, -- 5 seconds after match is finished
	players_to_start = 3,
    spawn_location = Server.GetMapSpawnPoints()
}

PropHunt = {
    remaining_time = 0,
    match_state = MATCH_STATES.WAITING_PLAYERS,
    num_hiders = 0,
    num_seekers = 0
}

-- Random props to try stuff
prop_table = Prop(Vector(200, 0, 0), Rotator(0, 0, 0), "nanos-world::SM_WoodenTable")
prop_chair = Prop(Vector(400, 200, 0), Rotator(0, 0, 0), "nanos-world::SM_WoodenChair")
prop_tire = Prop(Vector(600, 0, 0), Rotator(0, 0, 0), "nanos-world::SM_TireLarge")

-- Handles player connection
function connectionHandler(player)
    UpdatePlayerMatchState()
    if(PropHunt.match_state == MATCH_STATES.IN_PROGRESS) then
        --becomeSpectator(player, ROLES.SEEKER)
    elseif(PropHunt.match_state == MATCH_STATES.WAITING_PLAYERS) then

        Server.BroadcastChatMessage("<green>" .. player:GetName() .. "</> has joined the server (" .. Player.GetCount() .. "/" .. PropHuntSettings.players_to_start .. ")!")
		Server.SendChatMessage(player, "<grey>Welcome to the Server! Waiting players to start the match! Feel free to explore the map!</>")

        if(Player:GetCount() >=  1--[[PropHuntSettings.players_to_start]]) then
            assignTeam(player)
            UpdateMatchState(MATCH_STATES.WARM_UP)
        end
        -- Becomes floating camera
    elseif(PropHunt.match_state == MATCH_STATES.POST_TIME) then
        -- Becomes floating camera
    elseif(PropHunt.match_state == MATCH_STATES.WARM_UP) then
        assignTeam(player)
        spawnCharacter(player)
    end
end

Player.Subscribe("Spawn", connectionHandler)
-----------------------------------

-- Handles player leaving the game, delete all player related stuff
Player.Subscribe("Destroy", function(player)
    local character = player:GetControlledCharacter()
    if(character) then
        weapon = character:GetPicked()
        if(weapon) then
            weapon:Destroy()
        end
        character:Destroy()
    end
end)
--------------------------------------

-- Spawn player according to team
function spawnCharacter(player)
    local new_character = Character(Vector(0, 0, 0), Rotator(),"nanos-world::SK_Mannequin")

    if(player:GetValue("Role") == ROLES.SEEKER) then -- Seeker
        new_character:SetTeam(1) -- Disables seeker can damage each other
        new_character:SetCanGrabProps(false)
        new_character:SetMovementEnabled(false)
        new_character:SetCanPunch(false)
        new_character:SetCameraMode(1) -- First person only
    else -- Hider
        new_character:SetTeam(2)
        new_character:SetCanPunch(false)
		new_character:SetCanCrouch(false)
		new_character:SetCanPickupPickables(false)
		new_character:SetCanAim(false)
		new_character:SetCameraMode(2) -- Third person only
    end

    player:SetValue("IsAlive", true, true)
    player:Possess(new_character)
end
----------------------------------

-------------------------- Change to prop --------------------------
-- FIX FLOATING BUG
function changeToProp(player,propName,objectBounds,objectScale,objectLocationZ)

	character  = player:GetControlledCharacter()

	local new_prop_char = Character(Vector(character:GetLocation().X,character:GetLocation().Y,objectLocationZ), character:GetRotation(),"nanos-world::SK_None")
	--Server.BroadcastChatMessage(objectBounds["SphereRadius"].. "-" .. objectBounds["BoxExtent"]:Size())
	new_prop_char:SetCapsuleSize(32,64)

	--Server.BroadcastChatMessage(character:GetCapsuleSize()["Radius"].. "-RAIDUS-" .. new_prop_char:GetCapsuleSize()["Radius"])
	--Server.BroadcastChatMessage(character:GetCapsuleSize()["HalfHeight"].. "-HALF HEIGHT-" .. new_prop_char:GetCapsuleSize()["HalfHeight"])
	new_prop_char:AddStaticMeshAttached("prop", propName) -- Changes to selected prop

	new_prop_char:SetCanPickupPickables(false)
	new_prop_char:SetCanGrabProps(true) -- Allow to change to other props
	new_prop_char:SetCanCrouch(false)
	new_prop_char:SetCameraMode(2) -- Allows only Third Person
	new_prop_char:SetCanCrouch(false)
	new_prop_char:SetCanAim(false)

    -- Destroy previous character
	player:UnPossess()
	character:Destroy()

	player:Possess(new_prop_char)
end

Events.Subscribe("ChangeToProp", function(player,objectName,objectBounds,objectScale,objectLocationZ)
	changeToProp(player,objectName,objectBounds,objectScale,objectLocationZ)
end)
-------------------------- Change to prop --------------------------

-- Assigns the player to a team
function assignTeam(player)
    if(PropHunt.num_seekers == 0--[[PropHunt.num_hiders]]) then -- Hider
        PropHunt.num_hiders = PropHunt.num_hiders + 1
        player:SetValue("Role", ROLES.HIDER)
        Events.CallRemote("setTeam", player,ROLES.HIDER, true) -- Enables hider UI in clients end
    else -- Seeker
        PropHunt.num_seekers = PropHunt.num_seekers + 1
        player:SetValue("Role", ROLES.SEEKER)
        Events.CallRemote("setTeam", player, ROLES.SEEKER, true) -- Enables seeker UI in clients end
    end
end
----------------------------------

function giveWeapon(character)
    character:PickUp(DefaultWeapons[1]())
    character:GetPlayer():SetValue("Weapon", DefaultWeapons[1]())
end

------------------------------- MATCH STATE HANDLER -----------------------
function UpdateMatchState(new_state)
    PropHunt.match_state = new_state

    local player_count = Player.GetCount()
	local player_list = {}

	for k, player in pairs(Player.GetPairs()) do
		table.insert(player_list,player)
	end
    if(new_state == MATCH_STATES.WARM_UP) then
        PropHunt.remaining_time = PropHuntSettings.prep_time
        Server.BroadcastChatMessage("<grey>Warm up! Hiders go hide! Seekers don't you dare open your eyes!</>")
        for k, player in ipairs(player_list) do
            spawnCharacter(player)
            if(player:GetValue("Role") == ROLES.HIDER) then
                player:GetControlledCharacter():SetMovementEnabled(true)
            else
                giveWeapon(player:GetControlledCharacter())
            end
        end

	elseif (new_state == MATCH_STATES.IN_PROGRESS)then
		PropHunt.remaining_time = PropHuntSettings.match_time
		Server.BroadcastChatMessage("<grey>Round Started!</>")

		for k, character in pairs(Character.GetPairs()) do
			if(character:GetPlayer():GetValue("Role") == ROLES.SEEKER) then -- Enable movement to seekers
				character:SetMovementEnabled(true)
                character:SetCanAim(true) -- Can aim weapons and shoot
			end
		end

	elseif (new_state == MATCH_STATES.POST_TIME) then

		PropHunt.remaining_time = PropHuntSettings.post_time

	elseif(new_state == MATCH_STATES.WAITING_PLAYERS) then
		Server.BroadcastChatMessage("<grey>Waiting for players (" .. Player.GetCount() .. "/" .. PropHuntSettings.players_to_start .. ").</>")

        ClearServer()
	end
	
	UpdatePlayerMatchState()
end

-- Updates the match state client side
function UpdatePlayerMatchState(player)
	if (player) then
		Events.CallRemote("UpdateMatchState", player, PropHunt.match_state, PropHunt.remaining_time)
	else
		Events.BroadcastRemote("UpdateMatchState", PropHunt.match_state, PropHunt.remaining_time)
	end
end
------------------------------- MATCH STATE HANDLER -----------------------
function ClearServer()
	PropHunt.num_hiders = 0
    PropHunt.num_seekers = 0

	for k, e in pairs(Character.GetAll()) do e:Destroy() end
	for k, e in pairs(Weapon.GetAll()) do e:Destroy() end
end
------------------------------- CHARACTER EVENTS -----------------------
Character.Subscribe("TakeDamage", function(character, old_state, new_state)
end)

Character.Subscribe("Death", function(character)
    local player = character:GetPlayer()

    player:SetValue("IsAlive", false, true)
    if(player:GetValue("Role") == ROLES.SEEKER) then
	    player:GetValue("Weapon"):Destroy()
    end

    Server.SendChatMessage(player, "You are <red>dead</>! You can spectate other players by switching <bold>Left</> or <bold>Right</> keys!")

	-- Unpossess the Character after 2 seconds
	Timer.Bind(
		Timer.SetTimeout(function(p)
			p:UnPossess()
		end, 2000, player),
		player
	)

    VerifyWinners()
end)
------------------------------- CHARACTER EVENTS -----------------------

-- Check if a team has won
function VerifyWinners()
    local alive_players_count = 0
    local hiders_count = 0
	local seekers_count = 0

    -- Check how many is still alive, and how many is Knight
	for k, player in pairs(Player.GetPairs()) do
		if (player:GetValue("IsAlive")) then
			alive_players_count = alive_players_count + 1

			if (player:GetValue("Role") == ROLES.SEEKER) then
				seekers_count = seekers_count + 1
            else
                hiders_count = hiders_count + 1
            end
		end
	end

	-- If all Seekers were killed
	if (seekers_count == 0) then
		FinishRound(ROLES.HIDER)
    elseif(hiders_count == 0) then
        FinishRound(ROLES.SEEKER)
    end
end


function FinishRound(role_winner)
    if (role_winner == ROLES.HIDER) then
		Package.Log("[PropHunt] Round finished! Hiders win!")
		Server.BroadcastChatMessage("Round finished! <blue>Hiders</> Win!")
		Events.BroadcastRemote("HidersWin")
	else
		Package.Log("[Halloween] Round finished! Seekers win!")
		Server.BroadcastChatMessage("Round finished! <red>Seekers</> Win!")
		Events.BroadcastRemote("SeekersWin")
	end

    ClearServer()
	UpdateMatchState(MATCH_STATES.POST_TIME)
end



------------------------------------------------------- TIMER ----------------------------------------------
-- Decrease time, function gets called each second
function DecreaseRemainingTime()
	PropHunt.remaining_time = PropHunt.remaining_time - 1
	return (PropHunt.remaining_time <= 0)
end

-- Timer, calls DecreaseRemainingTime function each second
Timer.SetInterval(function()
	if (PropHunt.match_state == MATCH_STATES.WARM_UP) then
		if (DecreaseRemainingTime()) then
			UpdateMatchState(MATCH_STATES.IN_PROGRESS)
		end
	elseif (PropHunt.match_state == MATCH_STATES.IN_PROGRESS) then
		if (DecreaseRemainingTime()) then
			FinishRound(ROLES.HIDER) -- Match is over, hiders win
		else
			AnnounceCountdown()
		end
	elseif (PropHunt.match_state == MATCH_STATES.POST_TIME) then
		if (DecreaseRemainingTime()) then
            if(Player.GetCount() < PropHuntSettings.players_to_start) then
                UpdateMatchState(MATCH_STATES.WAITING_PLAYERS) -- Not enough players to start another round
            else
			    UpdateMatchState(MATCH_STATES.WARM_UP)
            end
		end
	end
end, 1000)

function AnnounceCountdown()
	if (PropHunt.remaining_time == 300) then Server.BroadcastChatMessage("<red>5 Minutes left!</>") return end
	if (PropHunt.remaining_time == 180) then Server.BroadcastChatMessage("<red>3 Minutes left!</>") return end
	if (PropHunt.remaining_time == 60) then Server.BroadcastChatMessage("<red>1 Minute left!</>") return end
	if (PropHunt.remaining_time == 30) then Server.BroadcastChatMessage("<red>30 Seconds left!</>") return end
	if (PropHunt.remaining_time == 10) then Server.BroadcastChatMessage("<red>10 Seconds left!</>") return end
	if (PropHunt.remaining_time == 9) then Server.BroadcastChatMessage("<red>9 Seconds left!</>") return end
	if (PropHunt.remaining_time == 8) then Server.BroadcastChatMessage("<red>8 Seconds left!</>") return end
	if (PropHunt.remaining_time == 7) then Server.BroadcastChatMessage("<red>7 Seconds left!</>") return end
	if (PropHunt.remaining_time == 6) then Server.BroadcastChatMessage("<red>6 Seconds left!</>") return end
	if (PropHunt.remaining_time == 5) then Server.BroadcastChatMessage("<red>5 Seconds left!</>") return end
	if (PropHunt.remaining_time == 4) then Server.BroadcastChatMessage("<red>4 Seconds left!</>") return end
	if (PropHunt.remaining_time == 3) then Server.BroadcastChatMessage("<red>3 Seconds left!</>") return end
	if (PropHunt.remaining_time == 2) then Server.BroadcastChatMessage("<red>2 Seconds left!</>") return end
	if (PropHunt.remaining_time == 1) then Server.BroadcastChatMessage("<red>1 Seconds left!</>") return end
end
------------------------------------------------------- TIMER ----------------------------------------------