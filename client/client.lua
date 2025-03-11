ESX = exports['es_extended']:getSharedObject()
local gateUnlocked = false 
local heistStarted = false
local spawnedCars = {} 



local gateModels = {
    -349730013, 
    -1918480350  
}


local gateCoords = {
    {x = -1529.9958, y = -41.0218, z = 56.9445, heading = 14.32},
    {x = -1532.4138, y = -42.1018, z = 56.9789, heading = 14.32}
}

local gateData = {
    {x = -1534.18, y = -42.26, z = 57.48}, 
    {x = -1528.88, y = -40.91, z = 57.47}
}

--=========================================================================MULTIPLAYER=====================================================================================================

ESX = exports['es_extended']:getSharedObject()

local partyLeader = nil
local partyMembers = {}
local partyLocked = false

-- ✅ Create or Join a Party When Starting a Heist
RegisterNetEvent('heist:startHeist')
AddEventHandler('heist:startHeist', function()
    local playerId = GetPlayerServerId(PlayerId())

    if partyLeader == nil then
        partyLeader = playerId -- ✅ Player becomes party leader
        partyMembers = {playerId} -- ✅ Add leader to party
        partyLocked = false -- ✅ Open party for invites
        ESX.ShowNotification("🎭 Heist party created! Invite players using /invite [ID]")
        print("🔹 Party Created by " .. playerId)
    else
        ESX.ShowNotification("❌ A heist is already in progress!")
    end
end)

RegisterCommand("invite", function(source, args)
    if not partyLeader or partyLocked then
        ESX.ShowNotification("❌ You cannot invite players right now!")
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        ESX.ShowNotification("⚠️ Usage: /invite [playerID]")
        return
    end

    if targetId == GetPlayerServerId(PlayerId()) then
        ESX.ShowNotification("❌ You cannot invite yourself!")
        return
    end

    for _, member in ipairs(partyMembers) do
        if member == targetId then
            ESX.ShowNotification("❌ Player is already in your party!")
            return
        end
    end

    TriggerServerEvent('heist:sendInvite', targetId, partyLeader)
end, false)

-- ✅ Accept Party Invite
RegisterNetEvent('heist:receiveInvite')
AddEventHandler('heist:receiveInvite', function(leaderId)
    ESX.ShowNotification("📩 You have been invited to join a heist! Type /join to accept.")
    RegisterCommand("join", function()
        if partyLeader and partyLeader == leaderId and not partyLocked then
            local playerId = GetPlayerServerId(PlayerId())
            table.insert(partyMembers, playerId)
            ESX.ShowNotification("✅ You have joined the heist party!")
            print("🔹 Player " .. playerId .. " joined the party.")
        else
            ESX.ShowNotification("❌ No active invite or heist has already started!")
        end
    end, false)
end)


RegisterNetEvent('heist:lockParty')
AddEventHandler('heist:lockParty', function()
    if partyLeader then
        partyLocked = true 
        ESX.ShowNotification("🔒 Heist started! No more players can join.")
        print("🔹 Party locked with " .. #partyMembers .. " members.")
    end
end)

-- ✅ Disband Party After Heist Ends
RegisterNetEvent('heist:endHeist')
AddEventHandler('heist:endHeist', function()
    if partyLeader then
        partyLeader = nil
        partyMembers = {}
        partyLocked = false
        ESX.ShowNotification("🏁 Heist complete! Party disbanded.")
        print("🔹 Party disbanded.")
    end
end)


















--=========================================================================MULTIPLAYER=====================================================================================================




-- ==========================  NPC SPAWN & START OF HEIST  ==========================

CreateThread(function()
    local model = `s_m_m_security_01`
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end

    local npc = CreatePed(4, model, Config.HeistNPC.x, Config.HeistNPC.y, Config.HeistNPC.z - 1.0, Config.HeistNPC.w, false, true)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    exports.ox_target:addLocalEntity(npc, {
        {
            label = "Start Heist",
            icon = "fas fa-user-secret",
            distance = 2.0,
            onSelect = function()
                TriggerEvent('heist:startHeist')
            end
        }
    })
end)


 RegisterNetEvent('heist:startHeist', function()
    heistStarted = true
    ESX.ShowNotification('Heist started.. Go to the location.')
    print("gates locked again.")
    SetNewWaypoint(gateCoords[1].x, gateCoords[1].y)
end) 
 




-- ==========================   HACKING OF THE GATE  ==========================

CreateThread(function()
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())

        
        local markerCoords = vector3(-1534.8473, -38.9665, 57.4163)
        local markerHeading = 148.6888
        local dist = #(playerCoords - markerCoords)

        
        if dist < 2.0 and heistStarted and not gateUnlocked then
            DrawMarker(1, markerCoords.x, markerCoords.y, markerCoords.z - 1.0, 
                0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 255, 0, 0, 200, false, true, 2, nil, nil, false)

        
            ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to hack the gate")

            if IsControlJustReleased(0, 38) then 
                TriggerEvent('heist:startHacking')
            end
        end
    end
end)
RegisterNetEvent('heist:unlockGate', function()
    gateUnlocked = true
    heistStarted = true
    UnlockGates()

    if #spawnedCars == 0 then 
        print("Spawning Cars")
        SpawnLockedCars()
    else
        print("Cars already spawned")
    end
    print("Spawning cars")
    TriggerEvent("heist:alertPolice")
    ESX.ShowNotification('Gate Hacked! POLICE NOTIFIED (NOW OPEN..)')
end)

-- ==========================  🚪 RETURNING THE GATE TO ORIGINAL FUNCTION (REPLAYABILITY)  ==========================

local originalGateStates = {}


function CaptureOriginalGateState()
    for i, coord in ipairs(gateCoords) do
        for _, model in ipairs(gateModels) do
            local gate = GetClosestObjectOfType(coord.x, coord.y, coord.z, 10.0, model, false, false, false)

            if gate and DoesEntityExist(gate) then
                originalGateStates[i] = {
                    entity = gate,
                    pos = GetEntityCoords(gate),
                    heading = GetEntityHeading(gate)
                }
                print("✅ Captured Original Gate State at " .. coord.x .. ", " .. coord.y)
            end
        end
    end
end

RegisterNetEvent('heist:startHacking', function()
    if hackCooldown then
        ESX.ShowNotification("❌ Wait before trying again!")
        return
    end

    exports['ps-ui']:Scrambler(function(success)
        if success then
            TriggerServerEvent('heist:unlockGate')
            gateUnlocked = true
        else
            ESX.ShowNotification('❌ Hacking failed! The gates remain locked.')
            hackCooldown = true
            SetTimeout(3000, function()
                hackCooldown = false
            end)
        end
    end, numeric, 30, false)
end)

function ResetAndLockGates()
    for i, state in ipairs(originalGateStates) do
        if state.entity and DoesEntityExist(state.entity) then
            SetEntityCoords(state.entity, state.pos.x, state.pos.y, state.pos.z, false, false, false, true)
            SetEntityHeading(state.entity, state.heading) 
            FreezeEntityPosition(state.entity, true) 
            print("🔒 Gate Reset & Locked at " .. state.pos.x .. ", " .. state.pos.y)
        end
    end
end


CreateThread(function()
    Wait(500) 
    CaptureOriginalGateState()
end)

CreateThread(function()
    while not gateUnlocked do -- 🔄 Run loop until gates are unlocked
        local playerCoords = GetEntityCoords(PlayerPedId())
        for i, coord in ipairs(gateCoords) do
            local dist = #(playerCoords - vector3(coord.x, coord.y, coord.z))

            if dist < 100.0 then -- ✅ Player is near gates
                local model = gateModels[i] -- Get corresponding model
                if model then
                    local gate = GetClosestObjectOfType(coord.x, coord.y, coord.z, 100.0, model, false, false, false)
                    
                    if gate and DoesEntityExist(gate) then
                        FreezeEntityPosition(gate, true) -- 🔒 Lock the gate
                        print("✅ Locked gate at [" .. coord.x .. ", " .. coord.y .. "]")
                    else
                        print("❌ ERROR: Could not find gate at [" .. coord.x .. ", " .. coord.y .. "]")
                    end
                end
            end
        end

        Wait(4000) -- ✅ Check every 5 seconds to avoid performance issues
    end

    print("🔓 Gates Unlocked! Stopping LockGates Loop.")
end)


function LockGates()
    for _, coord in pairs(gateCoords) do
        for _, model in pairs(gateModels) do
            local gate = GetClosestObjectOfType(coord.x, coord.y, coord.z, 1000.0, model, false, false, false)
            
            if gate and gate ~= 0 and DoesEntityExist(gate) then
                FreezeEntityPosition(gate, true)
                print("✅ Gate at [" .. coord.x .. ", " .. coord.y .. "] locked!")
            else
                print("❌ ERROR: No valid gate found at [" .. coord.x .. ", " .. coord.y .. "] with model: " .. model)
            end
        end
    end
end 


function UnlockGates()
    for _, coord in pairs(gateCoords) do
        for _, model in pairs(gateModels) do
            local gate = GetClosestObjectOfType(coord.x, coord.y, coord.z, 15.0, model, false, false, false)

            if gate and gate ~= 0 and DoesEntityExist(gate) then
                FreezeEntityPosition(gate, false)
                print("✅ Gate at [" .. coord.x .. ", " .. coord.y .. "] unlocked!")
            else
                print("❌ ERROR: No valid gate found at [" .. coord.x .. ", " .. coord.y .. "] with model: " .. model)
            end
        end
    end
end


CreateThread(function()
    Wait(1000) 
LockGates()
end)


-- ==========================  SPAWNING CARS/ SETTING SCENE ==========================



local spawnedCars = {}
local carModels = { "t20", "zentorno" } 

local carCoords = { 
    vector4(-1578.5795, -86.0474, 54.1344, 275.8380), 
    vector4(-1578.9629, -79.6769, 54.1344, 265.9749) 
}


function SpawnLockedCars()
    if #spawnedCars > 0 then
        print("❌ Cars already spawned! Skipping duplicate spawn.")
        return
    end

    print("🚗 Attempting to spawn cars...")

    for i, pos in ipairs(carCoords) do
        local model = GetHashKey(carModels[i])
        print("📦 Requesting model: " .. carModels[i] .. " (" .. model .. ")")

        RequestModel(model)
        local timeWaited = 0
        while not HasModelLoaded(model) do
            Wait(100)
            timeWaited = timeWaited + 100
            if timeWaited > 10000 then  
                print("❌ ERROR: Vehicle model " .. carModels[i] .. " failed to load!")
                return
            end
        end

        print("✅ Model Loaded: " .. carModels[i])

        -- ✅ Ensure vehicles spawn next to each other instead of stacking
      --  local spawnOffset = i * 3.5  -- ✅ Adjust distance between cars
        local vehicle = CreateVehicle(model, pos.x, pos.y, pos.z, pos.w, true, false)
        
        if DoesEntityExist(vehicle) then
            SetEntityAsMissionEntity(vehicle, true, true) 
            SetVehicleDoorsLocked(vehicle, 2) 
            SetVehicleDoorsLockedForAllPlayers(vehicle, true)
            SetVehicleOnGroundProperly(vehicle)

            table.insert(spawnedCars, vehicle)

            print("✅ Vehicle spawned at: " .. (pos.x +  pos.y))
        else
            print("❌ ERROR: Vehicle failed to spawn at " .. pos.x .. ", " .. pos.y)
        end
    end
end


--======================================= DRAWING MARKER ON VEHICLES =================================
CreateThread(function()
    while true do
        Wait(0) 

        for _, vehicle in ipairs(spawnedCars) do
            if DoesEntityExist(vehicle) then
                local carCoords = GetEntityCoords(vehicle)

  
                DrawMarker(2, carCoords.x, carCoords.y, carCoords.z + 1.5, 0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0, 1.0, 1.0, 1.0,
                    255, 128, 120, 150, true, true, 2, nil, nil, false)
            end
        end
    end
end)

-- ====================================== HACKING INTO THE CARS ========================================

function GetClosestSpawnedCar()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestVehicle = nil
    local closestDist = 5.0 

    for _, vehicle in ipairs(spawnedCars) do
        if DoesEntityExist(vehicle) then
            local vehicleCoords = GetEntityCoords(vehicle)
            local dist = #(playerCoords - vehicleCoords)

            if dist < closestDist then
                closestDist = dist
                closestVehicle = vehicle
            end
        end
    end

    return closestVehicle
end


CreateThread(function()
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())

        for i, pos in ipairs(carCoords) do
            local dist = #(playerCoords - vector3(pos.x, pos.y, pos.z))
            if dist < 2.5 and heistStarted then
                DrawMarker(1, pos.x, pos.y, pos.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 0, 255, 0, 200, false, true, 2, nil, nil, false)
                ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to hack the car")

                if IsControlJustReleased(0, 38) then 
                    TriggerEvent('heist:unlockCar', i)
                end
            end
        end
    end
end)


RegisterNetEvent('heist:unlockCar', function()
    if hackCooldown then
        ESX.ShowNotification("❌ You must wait before trying again!")
        return
    end

    local vehicle = GetClosestSpawnedCar()

    if vehicle and DoesEntityExist(vehicle) then
        print("🚗 Attempting to hack the nearest car!")

        PlayBreakingInAnimation()

        Wait(3000)

    
        exports['ps-ui']:VarHack(function(success)
            if success then
                SetVehicleDoorsLocked(vehicle, 1)
                SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                ESX.ShowNotification("🔓 Vehicle unlocked! You can now drive it.")
            else
                ESX.ShowNotification("❌ Hacking failed! Wait 3 seconds before trying again.")
                hackCooldown = true
                Citizen.SetTimeout(3000, function()
                    hackCooldown = false
                    ESX.ShowNotification("✅ You can try hacking again.")
                end)
            end
        end, 4, 15)
    else
        print("❌ ERROR: No spawned cars detected near the player!")
    end
end)


function PlayBreakingInAnimation()
    local playerPed = PlayerPedId()


    RequestAnimDict("veh@break_in@0h@p_m_one@")
    while not HasAnimDictLoaded("veh@break_in@0h@p_m_one@") do
        Wait(10)
    end

  
    TaskPlayAnim(playerPed, "veh@break_in@0h@p_m_one@", "low_force_entry_ds", 8.0, -8.0, 3000, 49, 0, false, false, false)

   
    FreezeEntityPosition(playerPed, true)

   SetTimeout(3000, function()
        FreezeEntityPosition(playerPed, false)
    end)
end


--=================================SETTING WAYPOINT AFTER VEHICLE STOLEN ===================================




-- ==========================  💰 SELLING SYSTEM  ==========================
local dropoffLocation = vector4(-901.4602, -2283.8357, 6.2859, 242.2333) 
local spawnedBuyer = nil
local payoutAmount = 50000 
local sellingInProgress = false 

function SetWaypointToDropoff()
    SetNewWaypoint(dropoffLocation.x, dropoffLocation.y)
    ESX.ShowNotification("📍 Deliver the vehicle to the buyer at the marked location!")
end


CreateThread(function()
    while true do
       Wait(1000) 

        local playerPed = PlayerPedId()
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)

  
        for _, vehicle in ipairs(spawnedCars) do
            if playerVehicle == vehicle and DoesEntityExist(vehicle) then
                SetWaypointToDropoff()
                return 
            end
        end
    end
end)

local notified = false
local isSelling = false 

CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local dist = #(playerCoords - vector3(dropoffLocation.x, dropoffLocation.y, dropoffLocation.z))

        if dist < 5.0 then
            DrawMarker(29, dropoffLocation.x, dropoffLocation.y, dropoffLocation.z + 1.5, 
                0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.5, 0, 255, 0, 200, false, true, 2, nil, nil, false)

            ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to sell the car")

            if IsControlJustReleased(0, 38) and not isSelling then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                
                if vehicle and DoesEntityExist(vehicle) then
                    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
                    StartVehicleSale(vehicleNetId) 
                else
                    if not notified then
                        ESX.ShowNotification("❌ You must be inside a stolen vehicle!")
                        notified = true  
                        Wait(3000) 
                        notified = false
                    end
                end
            end
        end
    end
end)

function StartVehicleSale(vehicleNetId)
    isSelling = true -- Prevent multiple sales

    print("🚗 Vehicle Net ID being sent to the server: ", vehicleNetId) -- Debugging

    -- ✅ Use ox_lib progress bar
    if exports["ox_lib"] then
        exports['ox_lib']:progressBar({
            duration = 10000, 
            label = "Selling Vehicle...",
            useWhileDead = false,
            canCancel = false,
            disableMovement = true, 
            disableCarMovement = true, 
            disableMouse = false,
            disableCombat = true
        })
    else
        local time = 10000 
        local startTime = GetGameTimer()
        while (GetGameTimer() - startTime) < time do
            Citizen.Wait(0)
        end
    end

    -- ✅ Send request to server
    TriggerServerEvent("heist:confirmSale", vehicleNetId)
end




--[[ function SellHackedCar()
    if sellingInProgress then
        ESX.ShowNotification("❌ Someone is already selling a vehicle! Wait for them to finish.")
        return
    end

    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    for i, vehicle in ipairs(spawnedCars) do
        if playerVehicle == vehicle and DoesEntityExist(vehicle) then
            ESX.ShowNotification("⌛ Selling vehicle... stay inside!")

            sellingInProgress = true 

            
            if exports["ox_lib"] then
                exports['ox_lib']:progressBar({
                    duration = 10000, 
                    label = "Selling Vehicle...",
                    useWhileDead = false,
                    canCancel = false,
                    disableMovement = true, 
                    disableCarMovement = true, 
                    disableMouse = false,
                    disableCombat = true
                })
            else
                
                local time = 10000 
                local startTime = GetGameTimer()
                
                while (GetGameTimer() - startTime) < time do
                    Citizen.Wait(0)

            
                    local newPedVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if newPedVehicle ~= vehicle then
                        ESX.ShowNotification("❌ Sale cancelled! You left the vehicle.")
                        sellingInProgress = false
                        return
                    end

                    
                    local progress = math.floor(((GetGameTimer() - startTime) / time) * 100)
                    DrawText3D(dropoffLocation.x, dropoffLocation.y, dropoffLocation.z + 1.5, "🚗 Selling... " .. progress .. "%", 1.0)
                end
            end

          
            local finalVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if finalVehicle ~= vehicle then
                ESX.ShowNotification("❌ Sale failed! You left the vehicle.")
                sellingInProgress = false
                return
            end

          
            ESX.ShowNotification("💰 Vehicle sold! You received $" .. payoutAmount)
            TriggerServerEvent('heist:giveMoney', payoutAmount)

           
            DeleteEntity(vehicle)
            table.remove(spawnedCars, i)

            
            SetWaypointOff()

            sellingInProgress = false 
            return
        end
    end

    ESX.ShowNotification("❌ You are not inside a hacked vehicle!")
end
 ]]

-- ==========================  TEST INTERACTION  =========================================================

RegisterCommand('testspawn', function()
    SpawnLockedCars()
end, false)

RegisterCommand('clearped', function()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)

    
    for _, pos in ipairs(carCoords) do
        ClearAreaOfPeds(pos.x, pos.y, pos.z, 100.0, false, false, false, false, false)
        ClearAreaOfVehicles(pos.x, pos.y, pos.z, 100.0, false, false, false, false, false)
    end

    print("✅ Peds and Vehicles cleared!")
end)

RegisterCommand("spawnonme", function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed) 

    SpawnLockedCars(playerCoords, heading) 
end, false)












--============================================ WORKING FOR SERVER===========================================


--[[ local lastHeistTime = {}
local heistCooldown = 30 * 60 * 1000 -- 30 minutes

RegisterNetEvent('heist:startHeist')
AddEventHandler('heist:startHeist', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local currentTime = GetGameTimer()
    if lastHeistTime[xPlayer.identifier] and (currentTime - lastHeistTime[xPlayer.identifier]) < heistCooldown then
        local remainingTime = math.ceil((heistCooldown - (currentTime - lastHeistTime[xPlayer.identifier])) / 1000)
        TriggerClientEvent('esx:showNotification', source, "⏳ You must wait " .. remainingTime .. " seconds before starting another heist!")
        return
    end

    lastHeistTime[xPlayer.identifier] = currentTime
    TriggerClientEvent('heist:startHeist', source)
end)
 ]]