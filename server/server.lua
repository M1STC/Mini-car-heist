ESX = exports['es_extended']:getSharedObject()


RegisterServerEvent('heist:unlockGate')
AddEventHandler('heist:unlockGate', function()
    TriggerClientEvent('heist:unlockGate', -1)
end)

RegisterServerEvent('heist:alertPolice')
AddEventHandler('heist:alertPolice', function()
    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        local player = ESX.GetPlayerFromId(playerId)
        if player.job.name == 'police' then
            TriggerClientEvent('esx:showNotification', playerId, 'Heist alarm triggered!')
        end
    end
end)

ESX = exports['es_extended']:getSharedObject()




RegisterServerEvent('heist:unlockGate')
AddEventHandler('heist:unlockGate', function()

    TriggerClientEvent('heist:unlockGate', -1)
end)

RegisterNetEvent('heist:giveMoney')
AddEventHandler('heist:giveMoney', function(amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and amount > 0 then
        xPlayer.addMoney(math.floor(amount)) 
        print("💰 Player received $" .. amount)
    else
        print("❌ ERROR: Invalid transaction for player " .. source)
    end
end)

RegisterServerEvent('heist:processSale')
AddEventHandler('heist:processSale', function(vehicleNetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end


    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then
        print("❌ ERROR: Invalid vehicle sale attempt by player " .. source)
        return
    end


    if not IsVehicleInSpawnedList(vehicle) then
        print("🚨 ALERT: Player " .. source .. " tried to sell a non-heist car!")
        return
    end

    DeleteEntity(vehicle)
    xPlayer.addMoney(50000)
    print("💰 Player " .. source .. " sold a vehicle and received $50,000")
end)


RegisterNetEvent('heist:syncParty')
AddEventHandler('heist:syncParty', function(members)
    partyMembers = members
end)

RegisterNetEvent('heist:joinParty')
AddEventHandler('heist:joinParty', function(playerId)
    if partyLeader and not partyLocked then
        table.insert(partyMembers, playerId)
        TriggerClientEvent('heist:syncParty', -1, partyMembers) 
        ESX.ShowNotification("✅ Player " .. playerId .. " joined the heist party!")
    end
end)


local spawnedHeistVehicles = {} -- Keep track of heist vehicles

-- ✅ Register when cars are spawned (Modify this function in client.lua)
RegisterServerEvent("heist:registerSpawnedVehicle")
AddEventHandler("heist:registerSpawnedVehicle", function(vehicleNetId)
    if not spawnedHeistVehicles[vehicleNetId] then
        spawnedHeistVehicles[vehicleNetId] = true
        print("✅ Heist vehicle registered: NetID " .. vehicleNetId)
    end
end)

-- ✅ Check if the vehicle is a heist car before selling
RegisterServerEvent('heist:confirmSale')
AddEventHandler('heist:confirmSale', function(vehicleNetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    print("📡 Server received vehicleNetId: ", vehicleNetId) -- Debugging

    -- Ensure vehicle exists
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then
        print("❌ ERROR: Vehicle does not exist or NetID is incorrect!")
        TriggerClientEvent('esx:showNotification', source, "❌ Error: Vehicle no longer exists.")
        return
    end

    -- 🚨 Prevent selling non-heist vehicles
    if not spawnedHeistVehicles[vehicleNetId] then
        print("🚨 ALERT: Player " .. source .. " tried to sell a non-heist car!")
        TriggerClientEvent('esx:showNotification', source, "❌ This is not a heist vehicle!")
        return
    end

    -- ✅ Remove from spawned list to prevent re-selling exploits
    spawnedHeistVehicles[vehicleNetId] = nil 

    -- 🚗 Securely delete vehicle
    DeleteEntity(vehicle)
    Wait(500)

    -- 💰 Give money to player
    xPlayer.addMoney(50000)
    TriggerClientEvent('esx:showNotification', source, "💰 You sold the vehicle and received $50,000")

    print("✅ Vehicle sold successfully!")
end)


