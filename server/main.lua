local ESX = exports['es_extended']:getSharedObject()

local Activities = {}
local Sessions = {}
local Cooldowns = {}
local BusyActivities = {}
local Started = false

local function isUpdateBlocked()
    return _G.HBHIllegalCreatorIsUpdateBlocked and _G.HBHIllegalCreatorIsUpdateBlocked() == true
end

local function updateBlockedMessage()
    if _G.HBHIllegalCreatorUpdateMessage then return _G.HBHIllegalCreatorUpdateMessage() end
    return 'Deze resource is geblokkeerd totdat updateall is uitgevoerd.'
end

local function blockedResponse(title)
    return { ok = false, title = title or Config.Notify.AdminTitle, message = updateBlockedMessage() }
end

local function notReadyResponse(title)
    return { ok = false, title = title or Config.Notify.AdminTitle, message = 'Resource is nog aan het opstarten, probeer het opnieuw.' }
end

local function identifier(src)
    if src == 0 then return 'console' end
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer and xPlayer.identifier then return xPlayer.identifier end
    return ('source:%s'):format(src)
end

local function notify(src, activity, message, nType)
    local title = activity and activity.name or Config.Notify.AdminTitle
    HBH.Security.Notify(src, title, message, nType or 'info')
end

local function adminNotify(src, message, nType)
    HBH.Security.Notify(src, Config.Notify.AdminTitle, message, nType or 'info')
end

local function broadcastSync()
    TriggerClientEvent('hbh-illegalcreator:client:syncActivities', -1, Activities)
end

local function rebuildCache(list)
    Activities = {}
    for _, activity in ipairs(list or {}) do
        Activities[tonumber(activity.id)] = activity
    end
end

local function clone(value)
    return json.decode(json.encode(value or {})) or {}
end

local function activityList(includeDisabled)
    local list = {}
    for _, activity in pairs(Activities) do
        if includeDisabled or activity.enabled then
            list[#list + 1] = activity
        end
    end
    table.sort(list, function(a, b) return (a.id or 0) > (b.id or 0) end)
    return list
end

local function getActivity(id)
    return Activities[tonumber(id)]
end

local function randomToken()
    local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local token = ''
    for i = 1, 32 do
        local r = math.random(1, #chars)
        token = token .. chars:sub(r, r)
    end
    return token
end

local function stepCoords(step)
    local c = step and step.coords or {}
    return { x = c.x or 0.0, y = c.y or 0.0, z = c.z or 0.0, h = c.h or c.heading or 0.0 }
end

local function getSessionStep(session, activity, stepIndex)
    if session and session.routePoints then
        return session.routePoints[tonumber(stepIndex or 1)]
    end
    local points = activity.action_points or {}
    return points[tonumber(stepIndex or 1)]
end

local function getSessionStepCount(session, activity)
    if session and session.routePoints then return #(session.routePoints or {}) end
    return #(activity.action_points or {})
end


local function visualBuilder(activity)
    local settings = activity and activity.settings or {}
    local builder = settings.visual_builder or settings.visualBuilder or {}
    if builder.enabled ~= true then return nil end
    return builder.blocks or {}
end

local function visualBuilderApplies(activity, step)
    local blocks = visualBuilder(activity)
    if not blocks or #blocks == 0 then return false, nil end
    local actionType = step and (step.action_type or step.actionType) or ''
    if actionType == 'process' or actionType == 'package' or actionType == 'craft' or actionType == 'custom' then
        return true, blocks
    end
    return false, blocks
end

local function addBuilderRequirements(list, activity, step)
    local applies, blocks = visualBuilderApplies(activity, step)
    if not applies then return end
    for _, block in ipairs(blocks or {}) do
        if block.type == 'required_item' and block.name and block.name ~= '' then
            list[#list + 1] = { type = 'item', name = block.name, amount = tonumber(block.amount or 1) or 1, remove = block.remove == true }
        elseif block.type == 'remove_item' and block.name and block.name ~= '' then
            list[#list + 1] = { type = 'item', name = block.name, amount = tonumber(block.amount or 1) or 1, remove = true }
        end
    end
end

local function addBuilderRewards(list, activity, step)
    local applies, blocks = visualBuilderApplies(activity, step)
    if not applies then return end
    for _, block in ipairs(blocks or {}) do
        if block.type == 'reward_item' and block.name and block.name ~= '' then
            list[#list + 1] = {
                type = 'item',
                name = block.name,
                min = tonumber(block.min or 1) or 1,
                max = tonumber(block.max or block.min or 1) or 1,
                chance = tonumber(block.chance or 100) or 100,
                guaranteed = block.guaranteed ~= false
            }
        elseif block.type == 'reward_money' then
            local account = block.account or 'black_money'
            list[#list + 1] = {
                type = 'account',
                name = account,
                min = tonumber(block.min or 1) or 1,
                max = tonumber(block.max or block.min or 1) or 1,
                chance = tonumber(block.chance or 100) or 100,
                guaranteed = block.guaranteed ~= false
            }
        end
    end
end

local function shouldBuilderAlert(activity, step)
    local applies, blocks = visualBuilderApplies(activity, step)
    if not applies then return false end
    for _, block in ipairs(blocks or {}) do
        if block.type == 'police' and block.enabled == true then
            local chance = tonumber(block.chance or 100) or 100
            if math.random(1, 100) <= math.max(0, math.min(100, chance)) then
                return true
            end
        end
    end
    return false
end

local function mergedRequirements(activity, step)
    local list = {}
    for _, entry in ipairs(step and step.required_items or {}) do list[#list + 1] = entry end
    if step and step.required_item and step.required_item ~= '' then
        list[#list + 1] = { type = 'item', name = step.required_item, amount = tonumber(step.required_amount or 1) or 1, remove = step.remove_required == true }
    end
    addBuilderRequirements(list, activity, step)
    return list
end

local function mergedRewards(activity, step)
    local list = {}
    for _, entry in ipairs(step and step.rewards or {}) do list[#list + 1] = entry end
    if #list == 0 and step and step.reward and step.reward ~= '' then
        list[#list + 1] = { name = step.reward, amount = tonumber(step.reward_amount or 1) or 1, min = tonumber(step.reward_min or step.reward_amount or 1) or 1, max = tonumber(step.reward_max or step.reward_amount or 1) or 1, chance = tonumber(step.reward_chance or 100) or 100, type = step.reward_type or 'item', guaranteed = step.reward_guaranteed ~= false }
    end
    if step and step.give_activity_rewards then
        for _, entry in ipairs(activity.rewards or {}) do list[#list + 1] = entry end
    end
    addBuilderRewards(list, activity, step)
    return list
end

local function isFinalStep(session, activity, stepIndex)
    return tonumber(stepIndex) >= getSessionStepCount(session, activity)
end

local function secondsRemaining(timestamp)
    local remaining = (timestamp or 0) - os.time()
    if remaining < 0 then remaining = 0 end
    return remaining
end

local function settingBool(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end
    return value == 1 or value == '1' or value == 'true'
end

local function triggerPoliceAlert(activity, coords, force)
    if not force and not activity.alert_police then return end

    local settings = activity.settings or {}
    local police = settings.police or {}
    local chance = tonumber(police.chance or settings.alertChance or Config.Defaults.AlertChance) or Config.Defaults.AlertChance
    if math.random(1, 100) > chance then return end

    for _, playerId in pairs(ESX.GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer and xPlayer.job and Config.PoliceJobs[xPlayer.job.name] then
            TriggerClientEvent('hbh-illegalcreator:client:policeAlert', playerId, {
                title = activity.name,
                text = police.text or Config.PoliceAlert.Text,
                coords = coords or activity.coords,
                blip = activity.police_blip,
                blipTime = activity.police_blip_time or Config.Defaults.PoliceBlipTime,
                radius = tonumber(police.radius or Config.PoliceAlert.BlipRadius) or Config.PoliceAlert.BlipRadius,
                sprite = tonumber(police.sprite or Config.PoliceAlert.BlipSprite) or Config.PoliceAlert.BlipSprite,
                color = tonumber(police.color or Config.PoliceAlert.BlipColor) or Config.PoliceAlert.BlipColor,
                scale = tonumber(police.scale or Config.PoliceAlert.BlipScale) or Config.PoliceAlert.BlipScale
            })
        end
    end
end

local function finishSession(src, activity)
    Sessions[src] = nil
    BusyActivities[activity.id] = nil
    Cooldowns[activity.id] = os.time() + (tonumber(activity.cooldown) or Config.Defaults.Cooldown)
end

local function isWashRouteActivity(activity)
    if not activity then return false end
    local wash = activity.settings and activity.settings.wash or {}
    local route = wash.route or {}
    local enabled = route.enabled
    if enabled == nil then enabled = Config.WitwasRoute.EnabledByDefault end
    return activity.category == 'witwassen' and settingBool(enabled, true)
end

local function shuffledRoutePoints(points)
    local list = clone(points or {})
    for i = #list, 2, -1 do
        local j = math.random(1, i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

local function buildWashRoute(activity)
    local wash = activity.settings and activity.settings.wash or {}
    local route = wash.route or {}
    local all = shuffledRoutePoints(activity.action_points or {})
    if #all == 0 then return nil, 'Voeg eerst route locaties toe bij Actiepunten.' end

    local minStops = tonumber(route.minStops or Config.WitwasRoute.MinStops) or Config.WitwasRoute.MinStops
    local maxStops = tonumber(route.maxStops or Config.WitwasRoute.MaxStops) or Config.WitwasRoute.MaxStops
    minStops = math.max(1, math.min(minStops, #all))
    maxStops = math.max(minStops, math.min(maxStops, #all))
    local stopCount = math.random(minStops, maxStops)

    local randomDuration = settingBool(route.randomDuration, Config.WitwasRoute.RandomDuration)
    local minDuration = tonumber(route.randomDurationMin or Config.WitwasRoute.RandomDurationMin) or Config.WitwasRoute.RandomDurationMin
    local maxDuration = tonumber(route.randomDurationMax or Config.WitwasRoute.RandomDurationMax) or Config.WitwasRoute.RandomDurationMax
    if maxDuration < minDuration then maxDuration = minDuration end
    local defaultDuration = tonumber(route.duration or Config.WitwasRoute.DefaultStopDuration) or Config.WitwasRoute.DefaultStopDuration

    local selected = {}
    for i = 1, stopCount do
        local p = all[i]
        local duration = tonumber(p.duration or 0) or 0
        if duration <= 0 then
            duration = randomDuration and math.random(minDuration, maxDuration) or defaultDuration
        end
        selected[#selected + 1] = {
            label = p.label or ('Witwas adres %s'):format(i),
            coords = p.coords,
            action_type = 'wash_route_stop',
            duration = duration,
            progressbar = p.progressbar,
            minigame = p.minigame,
            minigame_difficulty = p.minigame_difficulty or activity.minigame_difficulty,
            animation = p.animation or Config.WitwasRoute.KnockAnimation,
            required_item = p.required_item,
            required_amount = p.required_amount,
            remove_required = p.remove_required,
            door = p.door or {},
            marker = p.marker,
            max_distance = p.max_distance,
            interact_distance = p.interact_distance,
            cancel_distance = p.cancel_distance
        }
        if not selected[#selected].animation or not selected[#selected].animation.preset or selected[#selected].animation.preset == 'none' then
            selected[#selected].animation = Config.WitwasRoute.KnockAnimation
        end
    end

    return selected
end

local function validateSession(src, activityId, stepIndex, token)
    local activity = getActivity(activityId)
    if not activity then
        HBH.Security.Flag(src, 'ongeldige activiteit id', activityId)
        return false, nil, _L('invalid_activity')
    end
    if not activity.enabled then return false, activity, _L('activity_disabled') end

    local session = Sessions[src]
    if not session or session.token ~= token or tonumber(session.activityId) ~= tonumber(activityId) then
        HBH.Security.Flag(src, 'ongeldige sessie/token', activity.name)
        return false, activity, _L('exploit')
    end

    if os.time() - session.startedAt > Config.Security.SessionTimeout then
        Sessions[src] = nil
        BusyActivities[activity.id] = nil
        return false, activity, 'Sessie verlopen.'
    end

    stepIndex = tonumber(stepIndex)
    if stepIndex ~= session.step then
        HBH.Security.Flag(src, ('verkeerde stap %s verwacht %s'):format(tostring(stepIndex), tostring(session.step)), activity.name)
        return false, activity, _L('exploit')
    end

    if session.completed[stepIndex] then
        HBH.Security.Flag(src, ('dubbele stap afronden %s'):format(tostring(stepIndex)), activity.name)
        return false, activity, _L('exploit')
    end

    local step = getSessionStep(session, activity, stepIndex)
    if not step then
        HBH.Security.Flag(src, 'stap bestaat niet', activity.name)
        return false, activity, _L('exploit')
    end

    local maxDistance = tonumber(step.max_distance or activity.max_distance or Config.Defaults.MaxDistance) or Config.Defaults.MaxDistance
    maxDistance = math.min(maxDistance + 2.0, Config.Security.MaxStepDistance)
    if HBH.Security.Distance(src, stepCoords(step)) > maxDistance then
        HBH.Security.Flag(src, 'afstand check mislukt', activity.name)
        return false, activity, _L('too_far')
    end

    return true, activity, step
end

local function startWashRoute(src, activity, payload)
    payload = payload or {}
    local washData = HBH.Security.GetWashSettings(src, activity)
    local amount = math.floor(tonumber(payload.amount or 0) or 0)

    if amount < washData.minAmount or amount > washData.maxAmount then
        return { ok = false, title = activity.name, message = ('Bedrag moet tussen %s en %s liggen.'):format(washData.minAmount, washData.maxAmount) }
    end

    local hasMoney = HBH.Security.GetAccountAmount(src, washData.input)
    if hasMoney < amount then
        return { ok = false, title = activity.name, message = _L('missing_money', amount, washData.input) }
    end

    local wash = activity.settings and activity.settings.wash or {}
    local route = wash.route or {}
    local useOwnVehicle = payload.useOwnVehicle == true
    local upgradeBought = false

    local routePoints, routeErr = buildWashRoute(activity)
    if not routePoints then
        return { ok = false, title = activity.name, message = routeErr }
    end

    if useOwnVehicle then
        local upgradeEnabled = settingBool(route.ownVehicleUpgradeEnabled, Config.WitwasRoute.OwnVehicleUpgradeEnabled)
        if not upgradeEnabled then
            return { ok = false, title = activity.name, message = 'Eigen voertuig gebruiken staat uit voor deze witwas route.' }
        end

        local id = identifier(src)
        if not HBH.Database.HasWashUpgrade(id, activity.id) then
            local price = tonumber(route.ownVehicleUpgradePrice or Config.WitwasRoute.OwnVehicleUpgradePrice) or Config.WitwasRoute.OwnVehicleUpgradePrice
            local account = route.ownVehicleUpgradeAccount or Config.WitwasRoute.OwnVehicleUpgradeAccount
            if HBH.Security.GetAccountAmount(src, account) < price then
                return { ok = false, title = activity.name, message = ('Je mist %s %s voor de eigen-voertuig upgrade.'):format(price, account) }
            end
            HBH.Security.RemoveAccount(src, account, price)
            HBH.Database.AddWashUpgrade(id, activity.id)
            upgradeBought = true
        end
    end

    local outputAmount = HBH.Security.CalculateWashOutput(amount, washData)
    HBH.Security.RemoveAccount(src, washData.input, amount)

    local token = randomToken()
    local clientActivity = clone(activity)
    clientActivity.action_points = routePoints
    clientActivity.settings = clientActivity.settings or {}
    clientActivity.settings.washRouteActive = true

    Sessions[src] = {
        token = token,
        activityId = tonumber(activity.id),
        step = 1,
        startedAt = os.time(),
        completed = {},
        routePoints = routePoints,
        washRoute = {
            amount = amount,
            outputAmount = outputAmount,
            input = washData.input,
            output = washData.output,
            percentage = washData.percentage,
            useOwnVehicle = useOwnVehicle,
            upgradeBought = upgradeBought
        }
    }

    if (activity.settings or {}).onePlayerOnly == true then BusyActivities[activity.id] = src end

    local vehicle = nil
    if not useOwnVehicle then
        vehicle = {
            spawn = true,
            model = route.vehicleModel or Config.WitwasRoute.VehicleModel,
            coords = route.vehicleSpawn or route.spawnCoords or route.vehicle_spawn,
            warp = true
        }
    end

    local message = 'Route gestart. Rijd naar het eerste adres.'
    if upgradeBought then message = 'Eigen-voertuig upgrade gekocht. Route gestart.' end

    return { ok = true, token = token, activity = clientActivity, step = 1, message = message, washRoute = true, vehicle = vehicle }
end

local function sanitizeAdminActivity(data)
    data = data or {}
    if HBH.Security.PayloadTooLarge(data, true) then
        return false, 'Data is te groot. Verwijder onnodige velden/locaties.'
    end

    data.action_points = data.action_points or {}
    data.required_items = data.required_items or {}
    data.rewards = data.rewards or {}
    data.settings = data.settings or {}

    if #(data.action_points or {}) > Config.Security.MaxActionPoints then
        return false, ('Maximaal %s actiepunten toegestaan.'):format(Config.Security.MaxActionPoints)
    end

    return true
end

CreateThread(function()
    math.randomseed(os.time())

    local waited = 0
    while _G.HBHIllegalCreatorUpdateIsReady and not _G.HBHIllegalCreatorUpdateIsReady() do
        Wait(250)
        waited = waited + 250
        if waited >= 20000 then
            print('^3[hbh-illegalcreator] Update check duurde te lang. Resource start door, tenzij later blijkt dat er een update nodig is.^7')
            break
        end
    end

    if isUpdateBlocked() then
        Started = false
        return
    end

    HBH.Database.Ensure()
    rebuildCache(HBH.Database.LoadAll())
    Started = true
    print(('[hbh-illegalcreator] %s activiteiten geladen.'):format(#activityList(true)))
end)

lib.callback.register('hbh-illegalcreator:server:isAdmin', function(src)
    return HBH.Security.IsAdmin(src)
end)

lib.callback.register('hbh-illegalcreator:server:getActivities', function(src)
    if isUpdateBlocked() or not Started then return {} end
    return activityList(false)
end)

lib.callback.register('hbh-illegalcreator:server:adminGetData', function(src)
    if isUpdateBlocked() then return blockedResponse() end
    if not Started then return notReadyResponse() end
    if not HBH.Security.IsAdmin(src) then return { ok = false, message = _L('no_permission') } end
    return {
        ok = true,
        activities = activityList(true),
        config = {
            categories = Config.Categories,
            actionTypes = Config.ActionTypes,
            animationPresets = Config.AnimationPresets,
            quickItems = Config.QuickItems,
            drugTypes = Config.DrugTypes,
            defaults = Config.Defaults,
            minigame = Config.Minigame,
            witwasRoute = Config.WitwasRoute
        }
    }
end)

lib.callback.register('hbh-illegalcreator:server:adminSaveActivity', function(src, data)
    if isUpdateBlocked() then return blockedResponse() end
    if not Started then return notReadyResponse() end
    if not HBH.Security.IsAdmin(src) then return { ok = false, message = _L('no_permission') } end
    if HBH.Security.RateLimit(src, 'adminSave', Config.Security.AdminAntiSpamMs) then return { ok = false, message = 'Rustig aan.' } end

    data = data or {}
    local safe, safeMessage = sanitizeAdminActivity(data)
    if not safe then return { ok = false, message = safeMessage } end
    if not data.name or tostring(data.name) == '' then return { ok = false, message = 'Naam is verplicht.' } end

    local ok, result = pcall(function()
        local saved
        if data.id and tonumber(data.id) and tonumber(data.id) > 0 then
            saved = HBH.Database.Update(tonumber(data.id), data, identifier(src))
        else
            saved = HBH.Database.Insert(data, identifier(src))
        end
        Activities[tonumber(saved.id)] = saved
        broadcastSync()
        return saved
    end)

    if not ok then
        print('[hbh-illegalcreator] Save error:', result)
        return { ok = false, message = _L('admin_error') }
    end

    adminNotify(src, _L('admin_saved'), 'success')
    return { ok = true, activity = result }
end)

lib.callback.register('hbh-illegalcreator:server:adminDeleteActivity', function(src, id)
    if isUpdateBlocked() then return blockedResponse() end
    if not Started then return notReadyResponse() end
    if not HBH.Security.IsAdmin(src) then return { ok = false, message = _L('no_permission') } end
    if HBH.Security.RateLimit(src, 'adminDelete', Config.Security.AdminAntiSpamMs) then return { ok = false, message = 'Rustig aan.' } end

    id = tonumber(id)
    if not id then return { ok = false, message = 'Ongeldig ID.' } end

    HBH.Database.Delete(id)
    Activities[id] = nil
    Cooldowns[id] = nil
    BusyActivities[id] = nil
    broadcastSync()
    adminNotify(src, _L('admin_deleted'), 'success')
    return { ok = true }
end)

lib.callback.register('hbh-illegalcreator:server:startActivity', function(src, id, payload)
    if isUpdateBlocked() then return blockedResponse() end
    if not Started then return notReadyResponse() end
    if HBH.Security.PayloadTooLarge(payload, false) then
        HBH.Security.Flag(src, 'payload te groot bij start', 'onbekend')
        return { ok = false, message = _L('exploit') }
    end
    if HBH.Security.RateLimit(src, 'start', Config.Security.AntiSpamMs) then return { ok = false, message = 'Rustig aan.' } end

    local activity = getActivity(id)
    if not activity then return { ok = false, message = _L('invalid_activity') } end
    if not activity.enabled then return { ok = false, title = activity.name, message = _L('activity_disabled') } end
    if Sessions[src] then return { ok = false, title = activity.name, message = _L('already_busy') } end

    local remaining = secondsRemaining(Cooldowns[activity.id])
    if remaining > 0 then
        return { ok = false, title = activity.name, message = ('Deze activiteit is nog %s seconden niet beschikbaar.'):format(remaining) }
    end

    local settings = activity.settings or {}
    if settings.onePlayerOnly == true and BusyActivities[activity.id] then
        return { ok = false, title = activity.name, message = 'Iemand anders is al bezig met deze activiteit.' }
    end

    local maxDistance = math.min((tonumber(activity.max_distance) or Config.Defaults.MaxDistance) + 4.0, Config.Security.MaxStartDistance)
    if HBH.Security.Distance(src, activity.coords) > maxDistance then
        return { ok = false, title = activity.name, message = _L('too_far') }
    end

    local police = HBH.Security.GetPoliceCount(activity.min_police_grade)
    if police < (tonumber(activity.min_police) or 0) then
        return { ok = false, title = activity.name, message = _L('not_enough_police') }
    end

    local okReq, reqMessage = HBH.Security.HasRequirements(src, activity.required_items)
    if not okReq then
        return { ok = false, title = activity.name, message = reqMessage }
    end

    local alertOn = settings.alertOn or 'start'

    if isWashRouteActivity(activity) then
        local started = startWashRoute(src, activity, payload or {})
        if started and started.ok and alertOn == 'start' then triggerPoliceAlert(activity, activity.coords) end
        return started
    end

    if alertOn == 'start' then triggerPoliceAlert(activity, activity.coords) end

    local token = randomToken()
    Sessions[src] = {
        token = token,
        activityId = tonumber(activity.id),
        step = 1,
        startedAt = os.time(),
        completed = {}
    }
    if settings.onePlayerOnly == true then BusyActivities[activity.id] = src end

    if #(activity.action_points or {}) == 0 then
        HBH.Security.RemoveRequirements(src, activity.required_items)
        HBH.Security.GiveRewards(src, activity.rewards)
        finishSession(src, activity)
        notify(src, activity, _L('activity_completed'), 'success')
        return { ok = true, done = true, title = activity.name, message = _L('activity_completed') }
    end

    return { ok = true, token = token, activity = activity, step = 1, message = _L('activity_started') }
end)


lib.callback.register('hbh-illegalcreator:server:preCheckStep', function(src, activityId, stepIndex, token, payload)
    if isUpdateBlocked() then return blockedResponse() end
    if not Started then return notReadyResponse() end
    if HBH.Security.PayloadTooLarge(payload, false) then
        HBH.Security.Flag(src, 'payload te groot bij precheck', activityId)
        return { ok = false, message = _L('exploit') }
    end
    local valid, activity, stepOrMessage = validateSession(src, activityId, stepIndex, token)
    if not valid then
        return { ok = false, title = activity and activity.name or Config.Notify.AdminTitle, message = stepOrMessage }
    end

    local step = stepOrMessage
    local session = Sessions[src]
    local requirements = mergedRequirements(activity, step)
    local okReq, reqMessage = HBH.Security.HasRequirements(src, requirements)
    if not okReq then
        return { ok = false, title = activity.name, message = reqMessage }
    end

    local finalStep = isFinalStep(session, activity, stepIndex)
    if finalStep and not session.washRoute then
        local okFinalReq, finalReqMessage = HBH.Security.HasRequirements(src, activity.required_items)
        if not okFinalReq then
            return { ok = false, title = activity.name, message = finalReqMessage }
        end
    end

    local actionType = step.action_type or step.actionType or 'custom'
    if actionType == 'money_convert' or actionType == 'wash_start' then
        payload = payload or {}
        local amount = math.floor(tonumber(payload.amount or 0) or 0)
        if amount > 0 then
            local washData = HBH.Security.GetWashSettings(src, activity)
            if amount < washData.minAmount or amount > washData.maxAmount then
                return { ok = false, title = activity.name, message = ('Bedrag moet tussen %s en %s liggen.'):format(washData.minAmount, washData.maxAmount) }
            end
            if HBH.Security.GetAccountAmount(src, washData.input) < amount then
                return { ok = false, title = activity.name, message = _L('missing_money', amount, washData.input) }
            end
        end
    end

    return { ok = true, title = activity.name }
end)

lib.callback.register('hbh-illegalcreator:server:completeStep', function(src, activityId, stepIndex, token, payload)
    if isUpdateBlocked() then return blockedResponse() end
    if not Started then return notReadyResponse() end
    if HBH.Security.PayloadTooLarge(payload, false) then
        HBH.Security.Flag(src, 'payload te groot bij completeStep', activityId)
        return { ok = false, message = _L('exploit') }
    end
    if HBH.Security.RateLimit(src, 'completeStep', Config.Security.AntiSpamMs) then return { ok = false, message = 'Rustig aan.' } end

    local valid, activity, stepOrMessage = validateSession(src, activityId, stepIndex, token)
    if not valid then
        if activity then notify(src, activity, stepOrMessage, 'error') end
        return { ok = false, title = activity and activity.name or Config.Notify.AdminTitle, message = stepOrMessage }
    end

    local step = stepOrMessage
    local session = Sessions[src]
    local requirements = mergedRequirements(activity, step)
    local okReq, reqMessage = HBH.Security.HasRequirements(src, requirements)
    if not okReq then
        return { ok = false, title = activity.name, message = reqMessage }
    end

    local finalStep = isFinalStep(session, activity, stepIndex)
    if finalStep and not session.washRoute then
        local okFinalReq, finalReqMessage = HBH.Security.HasRequirements(src, activity.required_items)
        if not okFinalReq then
            return { ok = false, title = activity.name, message = finalReqMessage }
        end
    end

    local settings = activity.settings or {}
    local alertOn = settings.alertOn or 'start'
    if alertOn == 'step' and (not settings.alertStep or tonumber(settings.alertStep) == tonumber(stepIndex)) then
        triggerPoliceAlert(activity, stepCoords(step))
    end
    if shouldBuilderAlert(activity, step) then
        triggerPoliceAlert(activity, stepCoords(step), true)
    end

    HBH.Security.RemoveRequirements(src, requirements)
    if finalStep and not session.washRoute then
        HBH.Security.RemoveRequirements(src, activity.required_items)
    end

    local actionType = step.action_type or step.actionType or 'custom'
    if session.washRoute then
        -- Bij witwas-routes worden black_money en de payout alleen server-side verwerkt.
    elseif actionType == 'money_convert' or actionType == 'wash_start' then
        local okWash, washMessage = HBH.Security.WashMoney(src, activity, step, payload or {})
        if not okWash then
            return { ok = false, title = activity.name, message = washMessage }
        end
        notify(src, activity, washMessage, 'success')
    else
        local okReward, given = HBH.Security.GiveRewards(src, mergedRewards(activity, step))
        if okReward and given and #given > 0 and Config.Debug then
            HBH.Security.Debug(('Rewards gegeven aan %s voor %s stap %s: %s'):format(src, activity.name, stepIndex, json.encode(given)))
        end
    end

    local door = step.door or {}
    if door.afterAction and door.afterAction ~= 'none' then
        TriggerClientEvent('hbh-illegalcreator:client:setDoorState', -1, door, door.afterAction)
    end

    session.completed[stepIndex] = true

    if finalStep then
        if session.washRoute then
            HBH.Security.AddAccount(src, session.washRoute.output, session.washRoute.outputAmount)
            notify(src, activity, ('Route voltooid. Je hebt %s %s ontvangen.'):format(session.washRoute.outputAmount, session.washRoute.output), 'success')
        else
            if #(activity.rewards or {}) > 0 and not step.give_activity_rewards then
                HBH.Security.GiveRewards(src, activity.rewards)
            end
            notify(src, activity, _L('activity_completed'), 'success')
        end
        finishSession(src, activity)
        return { ok = true, done = true, title = activity.name, message = _L('activity_completed') }
    end

    session.step = session.step + 1
    return { ok = true, done = false, nextStep = session.step, title = activity.name, message = 'Stap voltooid.' }
end)

RegisterNetEvent('hbh-illegalcreator:server:cancelActivity', function(activityId, token, reason)
    local src = source
    local session = Sessions[src]
    if not session or session.token ~= token then return end
    local activity = getActivity(activityId)
    if activity then
        BusyActivities[activity.id] = nil
        notify(src, activity, reason or 'Activiteit geannuleerd.', 'warning')
    end
    Sessions[src] = nil
end)

RegisterNetEvent('hbh-illegalcreator:server:requestSync', function()
    if isUpdateBlocked() or not Started then
        TriggerClientEvent('hbh-illegalcreator:client:syncActivities', source, {})
        return
    end
    TriggerClientEvent('hbh-illegalcreator:client:syncActivities', source, Activities)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local session = Sessions[src]
    if session then
        BusyActivities[session.activityId] = nil
        Sessions[src] = nil
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(1500)
    if not isUpdateBlocked() and Started then broadcastSync() end
end)
