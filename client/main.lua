local ESX = exports['es_extended']:getSharedObject()

local Activities = {}
local TargetZones = {}
local TargetPeds = {}
local ActivityBlips = {}
local StepBlip = nil
local Current = nil
local DoorObjects = {}
local RouteVehicle = nil
local TextUiVisible = false

local function showStepText(text)
    if not TextUiVisible then
        lib.showTextUI(text)
        TextUiVisible = true
    end
end

local function hideStepText()
    if TextUiVisible then
        lib.hideTextUI()
        TextUiVisible = false
    end
end

local function dbg(...)
    if Config.Debug then
        print('[hbh-illegalcreator]', ...)
    end
end

local function notify(title, message, nType, duration)
    TriggerEvent('okokNotify:Alert', title or Config.Notify.AdminTitle, message or '', duration or Config.Notify.Duration, nType or 'info', Config.Notify.Sound)
end

local function toVec3(coords)
    coords = coords or {}
    return vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 7000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function isWashRouteActivity(activity)
    if not activity or activity.category ~= 'witwassen' then return false end
    local wash = activity.settings and activity.settings.wash or {}
    local route = wash.route or {}
    local enabled = route.enabled
    if enabled == nil then enabled = Config.WitwasRoute.EnabledByDefault end
    return enabled == true or enabled == 1 or enabled == '1' or enabled == 'true'
end


local function visualBuilderBlocks(activity)
    local settings = activity and activity.settings or {}
    local builder = settings.visual_builder or settings.visualBuilder or {}
    if builder.enabled ~= true then return nil end
    return builder.blocks or {}
end

local function visualBuilderApplies(activity, step)
    local blocks = visualBuilderBlocks(activity)
    if not blocks or #blocks == 0 then return false, nil end
    local actionType = step and (step.action_type or step.actionType) or ''
    if actionType == 'process' or actionType == 'package' or actionType == 'craft' or actionType == 'custom' then
        return true, blocks
    end
    return false, blocks
end

local function visualBuilderBlock(activity, step, blockType)
    local applies, blocks = visualBuilderApplies(activity, step)
    if not applies then return nil end
    for _, block in ipairs(blocks or {}) do
        if block.type == blockType then return block end
    end
    return nil
end

local function visualBuilderAnimation(activity, step)
    local block = visualBuilderBlock(activity, step, 'animation')
    if block and block.preset and block.preset ~= '' then
        return { preset = block.preset }
    end
    return nil
end

local function removeStepBlip()
    if StepBlip and DoesBlipExist(StepBlip) then
        RemoveBlip(StepBlip)
    end
    StepBlip = nil
end

local function setStepBlip(step)
    removeStepBlip()
    if not step or not step.coords then return end
    local enabled = Config.Waypoint.EnabledByDefault
    if Current and Current.activity and Current.activity.settings and Current.activity.settings.waypoint ~= nil then
        enabled = Current.activity.settings.waypoint == true
    end
    if not enabled then return end

    local coords = step.coords
    StepBlip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    SetBlipSprite(StepBlip, Config.Waypoint.StepBlipSprite)
    SetBlipColour(StepBlip, Config.Waypoint.StepBlipColor)
    SetBlipScale(StepBlip, Config.Waypoint.StepBlipScale)
    SetBlipRoute(StepBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(step.label or 'Volgende stap')
    EndTextCommandSetBlipName(StepBlip)
end

local function clearTargets()
    for _, zoneName in pairs(TargetZones) do
        pcall(function() exports.ox_target:removeZone(zoneName) end)
    end
    TargetZones = {}

    for _, ped in pairs(TargetPeds) do
        if DoesEntityExist(ped) then
            pcall(function() exports.ox_target:removeLocalEntity(ped) end)
            DeleteEntity(ped)
        end
    end
    TargetPeds = {}
end

local function clearActivityBlips()
    for _, blip in pairs(ActivityBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    ActivityBlips = {}
end

local function getAnimation(anim)
    if not anim then return nil end
    local presetName = anim.preset or anim.name
    local preset = Config.AnimationPresets[presetName or 'none'] or {}

    local scenario = anim.scenario or preset.scenario
    local dict = anim.dict or preset.dict
    local clip = anim.clip or preset.clip
    local flag = anim.flag or preset.flag or 49

    if scenario and scenario ~= '' then
        return { scenario = scenario }
    end
    if dict and dict ~= '' and clip and clip ~= '' then
        return { dict = dict, clip = clip, flag = flag }
    end
    return nil
end

function HBHPlayAnimation(anim, duration)
    local ped = PlayerPedId()
    local data = getAnimation(anim)
    if not data then return end

    ClearPedTasks(ped)
    if data.scenario then
        TaskStartScenarioInPlace(ped, data.scenario, 0, true)
        if duration and duration > 0 then
            SetTimeout(duration, function()
                if DoesEntityExist(ped) then ClearPedTasks(ped) end
            end)
        end
        return
    end

    RequestAnimDict(data.dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(data.dict) and GetGameTimer() < timeout do Wait(10) end
    if HasAnimDictLoaded(data.dict) then
        TaskPlayAnim(ped, data.dict, data.clip, 8.0, -8.0, duration or -1, data.flag or 49, 0.0, false, false, false)
        if duration and duration > 0 then
            SetTimeout(duration, function()
                if DoesEntityExist(ped) then ClearPedTasks(ped) end
            end)
        end
    end
end

local function playProgress(activity, step)
    local progressBlock = visualBuilderBlock(activity, step, 'progress')
    local duration = tonumber((progressBlock and progressBlock.duration) or step.duration or activity.duration or Config.Defaults.Duration) or Config.Defaults.Duration
    local useProgress = step.progressbar
    if useProgress == nil then useProgress = activity.progressbar end
    if useProgress == nil then useProgress = Config.Defaults.Progressbar end

    local anim = getAnimation(visualBuilderAnimation(activity, step) or step.animation or activity.animation)
    local label = (progressBlock and progressBlock.label) or step.label or activity.name
    if (step.action_type or step.actionType) == 'wash_route_stop' then
        label = ('Aankloppen bij %s'):format(step.label or 'adres')
    end

    if not useProgress then
        HBHPlayAnimation(visualBuilderAnimation(activity, step) or step.animation or activity.animation, duration)
        Wait(duration)
        ClearPedTasks(PlayerPedId())
        return true
    end

    local ok = lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = anim
    })

    ClearPedTasks(PlayerPedId())
    return ok == true
end

local function playMinigame(activity, step)
    local builderMini = visualBuilderBlock(activity, step, 'minigame')
    local enabled = builderMini and builderMini.enabled or step.minigame
    if enabled == nil then enabled = activity.minigame end
    if enabled == nil then enabled = false end
    if not enabled then return true end

    local difficulty = (builderMini and builderMini.difficulty) or step.minigame_difficulty or activity.minigame_difficulty or Config.Defaults.MinigameDifficulty
    local checks = Config.Minigame.Difficulty[difficulty] or Config.Minigame.Difficulty.normal
    return lib.skillCheck(checks, Config.Minigame.Inputs) == true
end

local function askWashAmount(activity, step)
    local actionType = step.action_type or step.actionType
    if actionType ~= 'money_convert' and actionType ~= 'wash_start' then return nil end

    local wash = step.wash or (activity.settings and activity.settings.wash) or {}
    local min = tonumber(wash.minAmount or 1) or 1
    local max = tonumber(wash.maxAmount or Config.Security.MaxWashAmount) or Config.Security.MaxWashAmount
    local input = lib.inputDialog(activity.name, {
        { type = 'number', label = 'Bedrag', description = ('Minimaal %s / maximaal %s'):format(min, max), required = true, min = min, max = max }
    })
    if not input then return false end
    return { amount = tonumber(input[1]) or 0 }
end

local function askWashRouteStart(activity)
    local wash = activity.settings and activity.settings.wash or {}
    local route = wash.route or {}
    local min = tonumber(wash.minAmount or Config.WitwasRoute.MinAmount) or Config.WitwasRoute.MinAmount
    local max = tonumber(wash.maxAmount or Config.WitwasRoute.MaxAmount) or Config.WitwasRoute.MaxAmount
    local upgradeEnabled = route.ownVehicleUpgradeEnabled
    if upgradeEnabled == nil then upgradeEnabled = Config.WitwasRoute.OwnVehicleUpgradeEnabled end
    local price = tonumber(route.ownVehicleUpgradePrice or Config.WitwasRoute.OwnVehicleUpgradePrice) or Config.WitwasRoute.OwnVehicleUpgradePrice

    local fields = {
        { type = 'number', label = 'Witwas bedrag', description = ('Minimaal %s / maximaal %s'):format(min, max), required = true, min = min, max = max }
    }

    if upgradeEnabled then
        fields[#fields + 1] = { type = 'checkbox', label = ('Eigen voertuig gebruiken upgrade, eenmalig %s'):format(price) }
    end

    local input = lib.inputDialog(activity.name, fields)
    if not input then return false end

    local useOwn = input[2] == true
    if useOwn and not IsPedInAnyVehicle(PlayerPedId(), false) then
        notify(activity.name, 'Je moet in je eigen voertuig zitten om deze optie te gebruiken.', 'error')
        return false
    end

    return { amount = tonumber(input[1]) or 0, useOwnVehicle = useOwn }
end

local function spawnRouteVehicle(activity, data)
    if not data or not data.spawn then return end
    local ped = PlayerPedId()
    local model = data.model or Config.WitwasRoute.VehicleModel
    local hash = loadModel(model)
    if not hash then
        notify(activity.name, 'Busje kon niet worden gespawned.', 'error')
        return
    end

    local c = data.coords or data.spawnCoords
    local coords
    local heading = GetEntityHeading(ped)

    if c and tonumber(c.x) and tonumber(c.y) and tonumber(c.z) and not (tonumber(c.x) == 0 and tonumber(c.y) == 0 and tonumber(c.z) == 0) then
        coords = vector3(tonumber(c.x) + 0.0, tonumber(c.y) + 0.0, tonumber(c.z) + 0.0)
        heading = tonumber(c.h or c.heading or heading) or heading
    else
        coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, Config.WitwasRoute.VehicleSpawnDistance or 5.0, 0.0)
    end

    if RouteVehicle and DoesEntityExist(RouteVehicle) then DeleteEntity(RouteVehicle) end
    RouteVehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleOnGroundProperly(RouteVehicle)
    SetVehicleEngineOn(RouteVehicle, true, true, false)
    SetPedIntoVehicle(ped, RouteVehicle, -1)
    SetModelAsNoLongerNeeded(hash)
end

local function nextStep()
    if not Current then return end
    local step = Current.activity.action_points[Current.step]
    if step then
        setStepBlip(step)
        notify(Current.activity.name, ('Ga naar: %s'):format(step.label or 'volgende locatie'), 'info')
    end
end

local attempting = false
local function attemptCurrentStep()
    if attempting or not Current then return end
    attempting = true

    local activity = Current.activity
    local step = activity.action_points[Current.step]
    if not step then attempting = false return end

    local distance = #(GetEntityCoords(PlayerPedId()) - toVec3(step.coords))
    local maxDistance = tonumber(step.max_distance or activity.max_distance or Config.Defaults.MaxDistance) or Config.Defaults.MaxDistance
    if distance > maxDistance then
        notify(activity.name, _L('too_far'), 'error')
        attempting = false
        return
    end

    local payload = askWashAmount(activity, step)
    if payload == false then
        attempting = false
        return
    end

    local pre = lib.callback.await('hbh-illegalcreator:server:preCheckStep', false, activity.id, Current.step, Current.token, payload or {})
    if not pre or not pre.ok then
        notify(pre and pre.title or activity.name, pre and pre.message or _L('admin_error'), 'error')
        attempting = false
        return
    end

    local minigameOk = playMinigame(activity, step)
    if not minigameOk then
        notify(activity.name, _L('step_failed'), 'error')
        attempting = false
        return
    end

    local progressOk = playProgress(activity, step)
    if not progressOk then
        notify(activity.name, _L('step_cancelled'), 'warning')
        attempting = false
        return
    end

    local res = lib.callback.await('hbh-illegalcreator:server:completeStep', false, activity.id, Current.step, Current.token, payload or {})
    if not res or not res.ok then
        notify(res and res.title or activity.name, res and res.message or _L('admin_error'), 'error')
        attempting = false
        return
    end

    if res.done then
        removeStepBlip()
        hideStepText()
        Current = nil
    else
        Current.step = res.nextStep
        nextStep()
    end

    attempting = false
end

local function startActivity(id)
    if Current then
        notify(Config.Notify.AdminTitle, _L('already_busy'), 'error')
        return
    end

    local activity = Activities[tonumber(id)]
    local payload = {}
    if isWashRouteActivity(activity) then
        payload = askWashRouteStart(activity)
        if payload == false then return end
    end

    local res = lib.callback.await('hbh-illegalcreator:server:startActivity', false, id, payload)
    if not res or not res.ok then
        notify(res and res.title or Config.Notify.AdminTitle, res and res.message or _L('admin_error'), 'error')
        return
    end

    if res.done then return end

    if res.vehicle then
        spawnRouteVehicle(res.activity or activity, res.vehicle)
    end

    Current = {
        token = res.token,
        activity = res.activity,
        step = res.step or 1
    }
    hideStepText()

    notify(res.activity.name, res.message or _L('activity_started'), 'success')
    nextStep()
end

local function spawnStartPed(activity)
    local wash = activity.settings and activity.settings.wash or {}
    local route = wash.route or {}
    local model = route.pedModel or Config.WitwasRoute.PedModel
    local hash = loadModel(model)
    if not hash then return false end

    local c = activity.coords or {}
    local ped = CreatePed(4, hash, c.x + 0.0, c.y + 0.0, c.z - 1.0, c.h or c.heading or 0.0, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    local scenario = route.pedScenario or Config.WitwasRoute.PedScenario
    if scenario and scenario ~= '' then TaskStartScenarioInPlace(ped, scenario, 0, true) end

    TargetPeds[#TargetPeds + 1] = ped
    exports.ox_target:addLocalEntity(ped, {
        {
            name = ('hbh_illegal_wash_ped_%s'):format(activity.id),
            icon = Config.Target.DefaultIcon,
            label = ('Start %s'):format(activity.name),
            distance = Config.Target.Distance,
            onSelect = function()
                startActivity(activity.id)
            end
        }
    })
    SetModelAsNoLongerNeeded(hash)
    return true
end

local function createTargets()
    clearTargets()
    clearActivityBlips()

    for id, activity in pairs(Activities) do
        if activity.enabled and activity.coords then
            if isWashRouteActivity(activity) then
                spawnStartPed(activity)
            else
                local zoneName = ('hbh_illegal_start_%s'):format(id)
                TargetZones[#TargetZones + 1] = zoneName
                exports.ox_target:addSphereZone({
                    name = zoneName,
                    coords = toVec3(activity.coords),
                    radius = tonumber(activity.target_radius or Config.Target.DefaultRadius) or Config.Target.DefaultRadius,
                    debug = Config.Debug,
                    options = {
                        {
                            name = zoneName,
                            icon = Config.Target.DefaultIcon,
                            label = ('%s %s'):format(Config.Target.LabelPrefix, activity.name),
                            distance = Config.Target.Distance,
                            onSelect = function()
                                startActivity(activity.id)
                            end
                        }
                    }
                })
            end

            if activity.blip then
                local b = AddBlipForCoord(activity.coords.x + 0.0, activity.coords.y + 0.0, activity.coords.z + 0.0)
                SetBlipSprite(b, (activity.settings and activity.settings.blipSprite) or Config.Blip.Sprite)
                SetBlipColour(b, (activity.settings and activity.settings.blipColor) or Config.Blip.Color)
                SetBlipScale(b, (activity.settings and activity.settings.blipScale) or Config.Blip.Scale)
                SetBlipAsShortRange(b, Config.Blip.ShortRange)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(activity.name)
                EndTextCommandSetBlipName(b)
                ActivityBlips[#ActivityBlips + 1] = b
            end
        end
    end
end

RegisterNetEvent('hbh-illegalcreator:client:syncActivities', function(serverActivities)
    Activities = {}
    for id, activity in pairs(serverActivities or {}) do
        Activities[tonumber(id)] = activity
    end
    createTargets()
    Wait(500)
    TriggerEvent('hbh-illegalcreator:client:refreshDoors')
end)

RegisterNetEvent('hbh-illegalcreator:client:policeAlert', function(data)
    notify(data.title, data.text, 'warning', 7000)

    if data.blip and data.coords then
        local radius = AddBlipForRadius(data.coords.x + 0.0, data.coords.y + 0.0, data.coords.z + 0.0, data.radius or Config.PoliceAlert.BlipRadius)
        SetBlipColour(radius, data.color or Config.PoliceAlert.BlipColor)
        SetBlipAlpha(radius, Config.PoliceAlert.BlipAlpha)

        local blip = AddBlipForCoord(data.coords.x + 0.0, data.coords.y + 0.0, data.coords.z + 0.0)
        SetBlipSprite(blip, data.sprite or Config.PoliceAlert.BlipSprite)
        SetBlipColour(blip, data.color or Config.PoliceAlert.BlipColor)
        SetBlipScale(blip, data.scale or Config.PoliceAlert.BlipScale)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(data.title or 'Melding')
        EndTextCommandSetBlipName(blip)

        SetTimeout((tonumber(data.blipTime or Config.Defaults.PoliceBlipTime) or 60) * 1000, function()
            if DoesBlipExist(radius) then RemoveBlip(radius) end
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end)
    end
end)

local function doorHash(door)
    local id = door.id or door.door_id or ('hbh_illegal_%s_%s_%s'):format(door.model or 'door', math.floor((door.coords and door.coords.x or 0) * 100), math.floor((door.coords and door.coords.y or 0) * 100))
    return GetHashKey(tostring(id))
end

local function ensureDoor(door)
    if not door or not door.coords or not door.model then return nil end
    local hash = doorHash(door)
    local coords = door.coords
    local model = tonumber(door.model)
    if not IsDoorRegisteredWithSystem(hash) then
        AddDoorToSystem(hash, model, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false)
    end
    DoorObjects[hash] = door
    return hash
end

local function applyDoorState(door, action)
    local hash = ensureDoor(door)
    if not hash then return end
    local current = DoorSystemGetDoorState(hash)
    local state = current

    if action == 'lock' then state = Config.Doorlock.NativeState.locked end
    if action == 'unlock' then state = Config.Doorlock.NativeState.unlocked end
    if action == 'toggle' then
        if current == Config.Doorlock.NativeState.locked then
            state = Config.Doorlock.NativeState.unlocked
        else
            state = Config.Doorlock.NativeState.locked
        end
    end

    DoorSystemSetDoorState(hash, state, false, false)
end

RegisterNetEvent('hbh-illegalcreator:client:setDoorState', function(door, action)
    applyDoorState(door, action)

    local relock = tonumber(door and door.relockDelay or 0) or 0
    if action == 'unlock' and relock > 0 then
        SetTimeout(relock, function()
            applyDoorState(door, 'lock')
        end)
    end
end)

RegisterNetEvent('hbh-illegalcreator:client:refreshDoors', function()
    for _, activity in pairs(Activities) do
        for _, step in ipairs(activity.action_points or {}) do
            local door = step.door
            if door and door.model and door.coords then
                ensureDoor(door)
                if door.defaultLocked then
                    applyDoorState(door, 'lock')
                else
                    applyDoorState(door, 'unlock')
                end
            end
        end
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('hbh-illegalcreator:server:requestSync')
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if Current then
            sleep = 600
            local step = Current.activity.action_points[Current.step]
            if step and step.coords then
                local ped = PlayerPedId()
                local p = GetEntityCoords(ped)
                local c = toVec3(step.coords)
                local dist = #(p - c)
                local drawDistance = tonumber(Config.Marker.DrawDistance or 25.0) or 25.0
                local interactDistance = tonumber(step.interact_distance or Config.Marker.InteractDistance) or Config.Marker.InteractDistance
                local markerEnabled = Current.activity.marker ~= false and step.marker ~= false

                if dist < drawDistance then
                    sleep = markerEnabled and 0 or 250
                    if markerEnabled then
                        DrawMarker(Config.Marker.Type, c.x, c.y, c.z + 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.Size.x, Config.Marker.Size.y, Config.Marker.Size.z, Config.Marker.Color.r, Config.Marker.Color.g, Config.Marker.Color.b, Config.Marker.Color.a, false, true, 2, false, nil, nil, false)
                    end

                    if dist < interactDistance then
                        sleep = 0
                        showStepText(('[E] %s'):format(step.label or 'Actie uitvoeren'))
                        if IsControlJustReleased(0, 38) then
                            hideStepText()
                            attemptCurrentStep()
                        end
                    else
                        hideStepText()
                    end
                else
                    hideStepText()
                    if dist > (tonumber(step.cancel_distance or 120.0) or 120.0) then
                        TriggerServerEvent('hbh-illegalcreator:server:cancelActivity', Current.activity.id, Current.token, _L('too_far'))
                        removeStepBlip()
                        Current = nil
                    end
                end
            else
                hideStepText()
            end
        else
            hideStepText()
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearTargets()
    clearActivityBlips()
    removeStepBlip()
    lib.hideTextUI()
    if RouteVehicle and DoesEntityExist(RouteVehicle) then DeleteEntity(RouteVehicle) end
end)
