local open = false

local function notify(message, nType)
    TriggerEvent('okokNotify:Alert', Config.Notify.AdminTitle, message or '', Config.Notify.Duration, nType or 'info', Config.Notify.Sound)
end

local function vecToTable(coords, heading)
    return {
        x = tonumber(string.format('%.4f', coords.x)),
        y = tonumber(string.format('%.4f', coords.y)),
        z = tonumber(string.format('%.4f', coords.z)),
        h = tonumber(string.format('%.4f', heading or 0.0))
    }
end

local function openCreator()
    local isAdmin = lib.callback.await('hbh-illegalcreator:server:isAdmin', false)
    if not isAdmin then
        notify(_L('no_permission'), 'error')
        return
    end

    local data = lib.callback.await('hbh-illegalcreator:server:adminGetData', false)
    if not data or not data.ok then
        notify(data and data.message or _L('admin_error'), 'error')
        return
    end

    open = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', payload = data })
end

RegisterCommand(Config.Command, function()
    openCreator()
end, false)

RegisterNUICallback('close', function(_, cb)
    open = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('getData', function(_, cb)
    local data = lib.callback.await('hbh-illegalcreator:server:adminGetData', false)
    cb(data or { ok = false, message = _L('admin_error') })
end)

RegisterNUICallback('saveActivity', function(data, cb)
    local res = lib.callback.await('hbh-illegalcreator:server:adminSaveActivity', false, data and data.activity or {})
    cb(res or { ok = false, message = _L('admin_error') })
end)

RegisterNUICallback('deleteActivity', function(data, cb)
    local res = lib.callback.await('hbh-illegalcreator:server:adminDeleteActivity', false, data and data.id)
    cb(res or { ok = false, message = _L('admin_error') })
end)

RegisterNUICallback('getCurrentCoords', function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    cb({ ok = true, coords = vecToTable(coords, heading) })
end)

RegisterNUICallback('previewAnimation', function(data, cb)
    if data and data.animation then
        HBHPlayAnimation(data.animation, tonumber(data.duration or 4000) or 4000)
    end
    cb({ ok = true })
end)

local function closestDoor()
    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)
    local objects = GetGamePool('CObject')
    local best, bestDist

    for _, entity in ipairs(objects) do
        if DoesEntityExist(entity) then
            local c = GetEntityCoords(entity)
            local dist = #(p - c)
            if dist <= Config.Doorlock.SearchRadius and (not bestDist or dist < bestDist) then
                best = entity
                bestDist = dist
            end
        end
    end

    if not best then return nil end

    local c = GetEntityCoords(best)
    local model = GetEntityModel(best)
    local heading = GetEntityHeading(best)
    local id = ('door_%s_%s_%s'):format(model, math.floor(c.x * 100), math.floor(c.y * 100))

    return {
        id = id,
        model = model,
        coords = vecToTable(c, heading),
        heading = heading,
        defaultLocked = Config.Doorlock.DefaultLocked,
        afterAction = 'unlock',
        relockDelay = Config.Doorlock.DefaultRelockDelay
    }
end

RegisterNUICallback('captureDoor', function(_, cb)
    local door = closestDoor()
    if not door then
        cb({ ok = false, message = 'Geen deur/object dichtbij gevonden.' })
        return
    end
    cb({ ok = true, door = door })
end)

RegisterNUICallback('adminNotify', function(data, cb)
    notify(data and data.message or '', data and data.type or 'info')
    cb({ ok = true })
end)

RegisterNetEvent('hbh-illegalcreator:client:syncActivities', function()
    if open then
        SetTimeout(350, function()
            local data = lib.callback.await('hbh-illegalcreator:server:adminGetData', false)
            SendNUIMessage({ action = 'refresh', payload = data })
        end)
    end
end)

CreateThread(function()
    while true do
        if open and IsControlJustReleased(0, 322) then
            open = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'forceClose' })
        end
        Wait(open and 0 or 700)
    end
end)
