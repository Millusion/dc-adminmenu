-- Variables
QBCore = exports['qb-core']:GetCoreObject()
local Sounds = {}
local IsFrozen = {}

--- Checks what permission the source has and what their ranking is in the permission hierachy.
--- @param source number - The player's ID
--- @return number - Ranking of the player in the permission hierachy
local function PermOrder(source)
    for i = 1, #PermissionOrder do
        if not OldPermissionSystem then
            if IsPlayerAceAllowed(source, PermissionOrder[i]) then
                return i
            end
        else
            if QBCore.Functions.GetPermission(source, PermissionOrder[i]) then
                return i
            end
        end
    end
    return #PermissionOrder + 1
end

--- Checks if the source is inside of the target's routingbucket
--- if not set the source's routingbucket to the target's
--- @param source number - The player's ID
--- @param target number - The player's ID
local function CheckRoutingbucket(source, target)
    local sourceBucket = GetPlayerRoutingBucket(source)
    local targetBucket = GetPlayerRoutingBucket(target)
    if sourceBucket ~= targetBucket then SetPlayerRoutingBucket(source, tonumber(targetBucket)) end
end

--- Credits https://github.com/prefech/JD_Perms
local function UpdatePermission(source, permission)
    local license = QBCore.Functions.GetIdentifier(source, 'license')
    if permission == 'user' then
        OldFile = io.open('resources/[qb]/dc-adminmenu/permissions.cfg', 'r')
        OldText = OldFile:read('*a')
        OldFile:close()
        NewText = OldText:gsub('\nadd_principal identifier.'..license..' [^\n]*', '')
        NewFile = io.open('resources/[qb]/dc-adminmenu/permissions.cfg', 'w+')
        NewFile:write(NewText)
        NewFile:close()
        ExecuteCommand("remove_principal identifier."..license.." AdminmenuAdmin")
        ExecuteCommand("remove_principal identifier."..license.." AdminmenuGod")
    else
        file = io.open('resources/[qb]/dc-adminmenu/permissions.cfg', 'a')
        io.output(file)
        local data = "\nadd_principal identifier."..license.." "..permission.. "  # ".. GetPlayerName(source)
        io.write(data)
        io.close(file)
        ExecuteCommand("add_principal identifier."..license.." "..permission.."")
    end
end

RegisterNetEvent('qb-admin:server:GetPlayersForBlips', function()
    local src = source
    local players = {}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local targetped = GetPlayerPed(v)
        local ped = QBCore.Functions.GetPlayer(v)
        players[#players+1] = {
            name = ped.PlayerData.charinfo.firstname .. ' ' .. ped.PlayerData.charinfo.lastname .. ' | ' .. GetPlayerName(v),
            id = v,
            coords = GetEntityCoords(targetped),
            cid = ped.PlayerData.charinfo.firstname .. ' ' .. ped.PlayerData.charinfo.lastname,
            citizenid = ped.PlayerData.citizenid,
            sources = GetPlayerPed(ped.PlayerData.source),
            sourceplayer = ped.PlayerData.source
        }
    end
    TriggerClientEvent('qb-admin:client:Show', src, players)
end)

RegisterNetEvent('qb-admin:server:kill', function(player)
    local src = source
    local target = player.id

    if not (QBCore.Functions.HasPermission(src, permissions['kill'])) then return end
    if PermOrder(src) > PermOrder(target) then return end

    TriggerClientEvent('hospital:client:KillPlayer', target)
end)

RegisterNetEvent('qb-admin:server:revive', function(player)
    local src = source

    if not (QBCore.Functions.HasPermission(src, permissions['revive'])) then return end
    
    TriggerClientEvent('hospital:client:Revive', player.id)
end)

RegisterNetEvent('qb-admin:server:freeze', function(player)
    local src = source
    local target = GetPlayerPed(player.id)
    
    if not (QBCore.Functions.HasPermission(src, permissions['freeze'])) then return end
    if PermOrder(src) > PermOrder(player.id) then return end
    if IsFrozen[target] == nil then IsFrozen[target] = false end

    if IsFrozen[target] then
        FreezeEntityPosition(target, false)
        IsFrozen[target] = false
    else
        FreezeEntityPosition(target, true)
        IsFrozen[target] = true
    end
end)

RegisterNetEvent('qb-admin:server:spectate', function(player)
    local src = source
    local targetped = GetPlayerPed(player.id)
    local coords = GetEntityCoords(targetped)

    if not (QBCore.Functions.HasPermission(src, permissions['spectate'])) then return end
    
    TriggerClientEvent('qb-admin:client:spectate', src, player.id, coords)
end)

RegisterNetEvent('qb-admin:server:goto', function(player)
    local src = source
    local admin = GetPlayerPed(src)
    local coords = GetEntityCoords(GetPlayerPed(player.id))
    
    if not (QBCore.Functions.HasPermission(src, permissions['goto'])) then return end

    CheckRoutingbucket(src, player.id)
    SetEntityCoords(admin, coords)
end)

RegisterNetEvent('qb-admin:server:bring', function(player)
    local src = source
    local admin = GetPlayerPed(src)
    local coords = GetEntityCoords(admin)
    local target = GetPlayerPed(player.id)
    
    if not (QBCore.Functions.HasPermission(src, permissions['bring'])) then return end

    CheckRoutingbucket(player.id, src)
    SetEntityCoords(target, coords)
end)

RegisterNetEvent('qb-admin:server:intovehicle', function(player)
    local src = source
    local admin = GetPlayerPed(src)
    local targetPed = GetPlayerPed(player.id)
    local vehicle = GetVehiclePedIsIn(targetPed, false)
    local seat = -1
    
    if not (QBCore.Functions.HasPermission(src, permissions['intovehicle'])) then return end
    if vehicle == 0 then TriggerClientEvent('QBCore:Notify', src, Lang:t("error.player_no_vehicle"), 'error', 4000) return end
    for i = 0, 8, 1 do if GetPedInVehicleSeat(vehicle, i) == 0 then seat = i break end end
    if seat == -1 then TriggerClientEvent('QBCore:Notify', src, Lang:t("error.no_free_seats"), 'error', 4000) return end
    
    SetPedIntoVehicle(admin, vehicle, seat)
    TriggerClientEvent('QBCore:Notify', src, Lang:t("success.entered_vehicle"), 'success', 5000)
end)

RegisterNetEvent('qb-admin:server:routingbucket', function(player, bucket)
    local src = source

    if not (QBCore.Functions.HasPermission(src, permissions['routingbucket'])) then return end
    if GetPlayerRoutingBucket(player.id) == tonumber(bucket) then return end

    SetPlayerRoutingBucket(player.id, tonumber(bucket))
end)

RegisterNetEvent('qb-admin:server:kick', function(player, reason)
    local src = source
    local target = player.id
    
    if not (QBCore.Functions.HasPermission(src, permissions['kick'])) then return end
    if PermOrder(src) > PermOrder(target) then return end
    
    TriggerEvent('qb-log:server:CreateLog', 'bans', 'Player Kicked', 'red', string.format('%s was kicked by %s for %s', GetPlayerName(target), GetPlayerName(src), reason), true)
    DropPlayer(target, Lang:t("info.kicked_server") .. ':\n' .. reason .. '\n\n' .. Lang:t("info.check_discord") .. QBCore.Config.Server.discord)
end)

RegisterNetEvent('qb-admin:server:ban', function(player, time, reason)
    local src = source
    local target = player.id
    local banTime = tonumber(os.time() + tonumber(time))
    if banTime > 2147483647 then banTime = 2147483647 end
    local timeTable = os.date('*t', banTime)
    
    if not (QBCore.Functions.HasPermission(src, permissions['ban'])) then return end
    if PermOrder(src) > PermOrder(target) then return end

    MySQL.Async.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(target),
        QBCore.Functions.GetIdentifier(target, 'license'),
        QBCore.Functions.GetIdentifier(target, 'discord'),
        QBCore.Functions.GetIdentifier(target, 'ip'),
        reason,
        banTime,
        GetPlayerName(src)
    })
    TriggerClientEvent('chat:addMessage', -1, {
        template = "<div class=chat-message server'><strong>ANNOUNCEMENT | {0} has been banned:</strong> {1}</div>",
        args = {GetPlayerName(target), reason}
    })
    TriggerEvent('qb-log:server:CreateLog', 'bans', 'Player Banned', 'red', string.format('%s was banned by %s for %s', GetPlayerName(target), GetPlayerName(src), reason), true)
    if banTime >= 2147483647 then
        DropPlayer(target, Lang:t("info.banned") .. '\n' .. reason .. Lang:t("info.ban_perm") .. QBCore.Config.Server.discord)
    else
        DropPlayer(target, Lang:t("info.banned") .. '\n' .. reason .. Lang:t("info.ban_expires") .. timeTable['day'] .. '/' .. timeTable['month'] .. '/' .. timeTable['year'] .. ' ' .. timeTable['hour'] .. ':' .. timeTable['min'] .. '\n🔸 Check our Discord for more information: ' .. QBCore.Config.Server.discord)
    end
end)

RegisterNetEvent('qb-admin:server:setPermissions', function(targetId, group)
    local src = source

    if not (QBCore.Functions.HasPermission(src, permissions['setPermissions'])) then return end

    TriggerClientEvent('QBCore:Notify', targetId, Lang:t("info.rank_level")..group[1].label)
    TriggerClientEvent('QBCore:Notify', src, Lang:t("success.changed_perm")..' : '..group[1].label)
    UpdatePermission(targetId, group[1].rank)
end)

RegisterNetEvent('qb-admin:server:cloth', function(player)
    local src = source

    if not (QBCore.Functions.HasPermission(src, permissions['cloth'])) then return end

    TriggerClientEvent('qb-clothing:client:openMenu', player.id)
end)

RegisterNetEvent('qb-admin:server:spawnVehicle', function(model)
    local src = source
    local hash = GetHashKey(model)
    local player = GetPlayerPed(src)
    local coords = GetEntityCoords(player)
    local heading = GetEntityHeading(player)
    local vehicle = GetVehiclePedIsIn(player, false)

    if not (QBCore.Functions.HasPermission(src, permissions['spawnVehicle'])) then return end
    if vehicle ~= 0 then DeleteEntity(vehicle) end

    local vehicle = CreateVehicle(hash, coords, true, true)
    while not DoesEntityExist(vehicle) do
        Wait(100)
    end
    SetEntityHeading(vehicle, heading)
    TaskWarpPedIntoVehicle(player, vehicle, -1)
    TriggerClientEvent('vehiclekeys:client:SetOwner', src, GetVehicleNumberPlateText(vehicle))
end)

RegisterNetEvent('qb-admin:server:SaveCar', function(mods, vehicle, hash, plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local result = MySQL.Sync.fetchAll('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    
    if result[1] ~= nil then TriggerClientEvent('QBCore:Notify', src, Lang:t("error.failed_vehicle_owner"), 'error', 3000) return end
    if not (QBCore.Functions.HasPermission(src, permissions['savecar'])) then return end
    
    MySQL.Async.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        Player.PlayerData.license,
        Player.PlayerData.citizenid,
        vehicle.model,
        vehicle.hash,
        json.encode(mods),
        plate,
        0
    })
    TriggerClientEvent('QBCore:Notify', src, Lang:t("success.success_vehicle_owner"), 'success', 5000)
end)

RegisterNetEvent('qb-admin:server:getsounds', function()
    local src = source

    if not (QBCore.Functions.HasPermission(src, permissions['playsound'])) then return end

    TriggerClientEvent('qb-admin:client:getsounds', src, Sounds)
end)

AddEventHandler('qb-admin:server:SendReport', function(name, targetSrc, msg)
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        if QBCore.Functions.HasPermission(v, 'adminmenu.admin') then
            TriggerClientEvent('chat:addMessage', v, {
                color = {255, 0, 0},
                multiline = true,
                args = {Lang:t("info.admin_report")..name..' ('..targetSrc..')', msg}
            })
        end
	end
end)

AddEventHandler('qb-admin:server:Staffchat:addMessage', function(name, msg)
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        if QBCore.Functions.HasPermission(v, 'adminmenu.admin') then
            TriggerClientEvent('chat:addMessage', v, {
                color = {255, 0, 0},
                multiline = true,
                args = {Lang:t("info.staffchat")..name, msg}
            })
        end
	end
end)

RegisterNetEvent('qb-admin:server:playsound', function(target, soundname, soundvolume, soundradius)
    local src = source

    if not (QBCore.Functions.HasPermission(src, permissions['playsound'])) then return end

    TriggerClientEvent('qb-admin:client:playsound', target, soundname, soundvolume, soundradius)
end)

RegisterNetEvent('qb-admin:server:getradiolist', function(channel)
    local src = source
    local list = exports['pma-voice']:getPlayersInRadioChannel(tonumber(channel))
    local Players = { id, name }

    if not (QBCore.Functions.HasPermission(src, permissions['getradiolist'])) then return end

    for targetSource, isTalking in pairs(list) do -- cheers Knight who shall not be named
        local Player = QBCore.Functions.GetPlayer(targetSource)
        Players[#Players + 1] = {
            id = targetSource,
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' | (' .. GetPlayerName(targetSource) .. ')'
        }
    end
    TriggerClientEvent('qb-admin:client:getradiolist', src, Players, channel)
end)

RegisterNetEvent('qb-admin:server:check', function()
    local src = source

    if QBCore.Functions.HasPermission(src, permissions['usemenu']) then return end

    DropPlayer(src, Lang:t("info.dropped"))
end)

QBCore.Functions.CreateCallback('qb-adminmenu:callback:getdealers', function(source, cb)
    cb(exports['qb-drugs']:GetDealers())
end)

QBCore.Functions.CreateCallback('qb-adminmenu:callback:getplayers', function(source, cb)
    if not QBCore.Functions.HasPermission(source, permissions['usemenu']) then return end

    local players = {}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local targetped = GetPlayerPed(v)
        local ped = QBCore.Functions.GetPlayer(v)
        players[#players+1] = {
            id = v,
            name = ped.PlayerData.charinfo.firstname .. ' ' .. ped.PlayerData.charinfo.lastname .. ' | (' .. GetPlayerName(v) .. ')',
            food = ped.PlayerData.metadata['hunger'],
            water = ped.PlayerData.metadata['thirst'],
            stress = ped.PlayerData.metadata['stress'],
            armor = ped.PlayerData.metadata['armor'],
            phone = ped.PlayerData.charinfo.phone,
            craftingrep = ped.PlayerData.metadata['craftingrep'],
            dealerrep = ped.PlayerData.metadata['dealerrep'],
            cash = ped.PlayerData.money['cash'],
            bank = ped.PlayerData.money['bank'],
            job = ped.PlayerData.job.label .. ' | ' .. ped.PlayerData.job.grade.level,
            gang = ped.PlayerData.gang.label,
        }
    end
        -- Sort players list by source ID (1,2,3,4,5, etc) --
        table.sort(players, function(a, b)
            return a.id < b.id
        end)
        ------
    cb(players)
end)

CreateThread(function()
    local path = GetResourcePath(SoundScriptName)
    local directory = path:gsub('//', '/')..SoundPath
    for filename in io.popen('dir "'..directory..'" /b'):lines() do
        Sounds[#Sounds + 1] = filename:match("(.+)%..+$")
    end
end)
