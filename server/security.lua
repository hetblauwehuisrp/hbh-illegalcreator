HBH = HBH or {}
HBH.Security = {}

local ESX = exports['es_extended']:getSharedObject()
local rateLimits = {}

local function dbg(...)
    if Config.Debug then
        print('[hbh-illegalcreator]', ...)
    end
end

function HBH.Security.Debug(...)
    dbg(...)
end

function HBH.Security.Notify(src, title, message, nType, duration)
    TriggerClientEvent('okokNotify:Alert', src, title or Config.Notify.AdminTitle, message or '', duration or Config.Notify.Duration, nType or 'info', Config.Notify.Sound)
end

function HBH.Security.IsAdmin(src)
    if src == 0 then return true end

    if Config.UseAcePermission and IsPlayerAceAllowed(src, Config.AcePermission) then
        if Config.Debug then dbg(('ACE admin allowed for %s'):format(src)) end
        return true
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    local group = 'user'
    if xPlayer.getGroup then
        group = xPlayer.getGroup() or 'user'
    elseif xPlayer.group then
        group = xPlayer.group
    end

    if Config.Debug then
        dbg(('Speler %s ESX group: %s'):format(src, tostring(group)))
    end

    return Config.AdminGroups[tostring(group)] == true
end

function HBH.Security.RateLimit(src, key, ms)
    if src == 0 then return false end
    local now = GetGameTimer()
    rateLimits[src] = rateLimits[src] or {}
    local last = rateLimits[src][key] or 0
    if now - last < (ms or Config.Security.AntiSpamMs) then
        return true
    end
    rateLimits[src][key] = now
    return false
end

function HBH.Security.Distance(src, coords)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return 999999.0 end
    local p = GetEntityCoords(ped)
    return #(p - vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0))
end

function HBH.Security.GetPoliceCount(minGrade)
    local count = 0
    minGrade = tonumber(minGrade or 0) or 0

    for _, playerId in pairs(ESX.GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer and xPlayer.job and Config.PoliceJobs[xPlayer.job.name] then
            local grade = tonumber(xPlayer.job.grade or 0) or 0
            local jobMin = Config.PoliceRanks[xPlayer.job.name]
            local requiredGrade = tonumber(minGrade or jobMin or 0) or 0
            if grade >= requiredGrade then
                count = count + 1
            end
        end
    end

    return count
end

local function normalizeEntry(entry)
    entry = entry or {}
    local name = tostring(entry.name or '')
    local amount = tonumber(entry.amount or entry.count or 1) or 1
    local eType = entry.type or ((name == 'money' or name == 'bank' or name == 'black_money') and 'account' or 'item')
    amount = math.floor(amount)
    if amount < 1 then amount = 1 end
    return {
        type = eType,
        name = name,
        label = entry.label or name,
        amount = amount,
        remove = entry.remove == true or entry.shouldRemove == true,
        chance = tonumber(entry.chance or 100) or 100,
        min = tonumber(entry.min or amount) or amount,
        max = tonumber(entry.max or amount) or amount,
        guaranteed = entry.guaranteed ~= false
    }
end

local function getAccountAmount(xPlayer, account)
    if account == 'money' then
        return xPlayer.getMoney and xPlayer.getMoney() or 0
    end
    local acc = xPlayer.getAccount and xPlayer.getAccount(account)
    return acc and (acc.money or 0) or 0
end

local function removeAccount(xPlayer, account, amount)
    if account == 'money' and xPlayer.removeMoney then
        xPlayer.removeMoney(amount)
        return true
    end
    if xPlayer.removeAccountMoney then
        xPlayer.removeAccountMoney(account, amount)
        return true
    end
    return false
end

local function addAccount(xPlayer, account, amount)
    if account == 'money' and xPlayer.addMoney then
        xPlayer.addMoney(amount)
        return true
    end
    if xPlayer.addAccountMoney then
        xPlayer.addAccountMoney(account, amount)
        return true
    end
    return false
end

function HBH.Security.GetAccountAmount(src, account)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return 0 end
    return getAccountAmount(xPlayer, account)
end

function HBH.Security.RemoveAccount(src, account, amount)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    amount = math.floor(tonumber(amount or 0) or 0)
    if amount <= 0 then return false end
    return removeAccount(xPlayer, account, amount)
end

function HBH.Security.AddAccount(src, account, amount)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    amount = math.floor(tonumber(amount or 0) or 0)
    if amount <= 0 then return false end
    return addAccount(xPlayer, account, amount)
end

function HBH.Security.GetPlayerJob(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job then return 'unemployed', 0 end
    return tostring(xPlayer.job.name or 'unemployed'), tonumber(xPlayer.job.grade or 0) or 0
end

function HBH.Security.HasRequirements(src, requirements)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false, 'Speler niet gevonden.' end

    for _, raw in ipairs(requirements or {}) do
        local req = normalizeEntry(raw)
        if req.name ~= '' then
            local amount = math.min(req.amount, Config.Security.MaxRequiredAmount)
            if req.type == 'account' then
                local has = getAccountAmount(xPlayer, req.name)
                if has < amount then
                    return false, _L('missing_money', amount, req.name)
                end
            else
                local has = exports.ox_inventory:GetItemCount(src, req.name) or 0
                if has < amount then
                    return false, _L('missing_item', amount, req.label or req.name)
                end
            end
        end
    end

    return true
end

function HBH.Security.RemoveRequirements(src, requirements)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    for _, raw in ipairs(requirements or {}) do
        local req = normalizeEntry(raw)
        if req.name ~= '' and req.remove then
            local amount = math.min(req.amount, Config.Security.MaxRequiredAmount)
            if req.type == 'account' then
                removeAccount(xPlayer, req.name, amount)
            else
                exports.ox_inventory:RemoveItem(src, req.name, amount)
            end
        end
    end

    return true
end

function HBH.Security.GiveRewards(src, rewards)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    local given = {}

    for _, raw in ipairs(rewards or {}) do
        local reward = normalizeEntry(raw)
        if reward.name ~= '' then
            local chance = math.max(0, math.min(100, reward.chance or 100))
            local rollOk = reward.guaranteed or math.random(1, 100) <= chance
            if rollOk then
                local min = math.max(1, math.floor(reward.min or reward.amount or 1))
                local max = math.max(min, math.floor(reward.max or reward.amount or min))
                local amount = math.random(min, max)
                amount = math.min(amount, Config.Security.MaxRewardAmount)

                if reward.type == 'account' then
                    addAccount(xPlayer, reward.name, amount)
                else
                    exports.ox_inventory:AddItem(src, reward.name, amount)
                end

                given[#given + 1] = { name = reward.name, label = reward.label or reward.name, amount = amount, type = reward.type }
            end
        end
    end

    return true, given
end

function HBH.Security.WashMoney(src, activity, step, payload)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false, 'Speler niet gevonden.' end

    local settings = activity.settings or {}
    local wash = step.wash or settings.wash or {}
    local input = wash.input or settings.input or 'black_money'
    local output = wash.output or settings.output or 'money'
    local percentage = tonumber(wash.percentage or settings.percentage or 80) or 80
    local fee = tonumber(wash.fee or settings.fee or 0) or 0
    local minAmount = tonumber(wash.minAmount or settings.minAmount or 1) or 1
    local maxAmount = tonumber(wash.maxAmount or settings.maxAmount or Config.Security.MaxWashAmount) or Config.Security.MaxWashAmount
    local amount = tonumber(payload and payload.amount or 0) or 0

    percentage = math.max(1, math.min(100, percentage))
    fee = math.max(0, math.min(100, fee))
    amount = math.floor(amount)
    maxAmount = math.min(maxAmount, Config.Security.MaxWashAmount)

    if amount < minAmount or amount > maxAmount then
        return false, ('Bedrag moet tussen %s en %s liggen.'):format(minAmount, maxAmount)
    end

    local current = getAccountAmount(xPlayer, input)
    if current < amount then
        return false, _L('missing_money', amount, input)
    end

    local outputAmount = math.floor(amount * (percentage / 100.0))
    if fee > 0 then
        outputAmount = math.floor(outputAmount - (outputAmount * (fee / 100.0)))
    end
    outputAmount = math.max(0, outputAmount)

    removeAccount(xPlayer, input, amount)
    addAccount(xPlayer, output, outputAmount)

    return true, ('Je hebt %s %s omgezet naar %s %s.'):format(amount, input, outputAmount, output)
end

AddEventHandler('playerDropped', function()
    rateLimits[source] = nil
end)


function HBH.Security.GetWashSettings(src, activity)
    local settings = activity.settings or {}
    local wash = settings.wash or {}
    local route = wash.route or {}
    local jobName = HBH.Security.GetPlayerJob(src)
    local jobPercentages = wash.jobs or Config.WitwasRoute.JobPercentages or {}
    local basePercentage = tonumber(wash.percentage or Config.WitwasRoute.DefaultPercentage) or Config.WitwasRoute.DefaultPercentage
    local maxPercentage = tonumber(wash.maxPercentage or Config.WitwasRoute.MaxPercentage) or Config.WitwasRoute.MaxPercentage
    local jobPercentage = nil

    if type(jobPercentages) == 'table' then
        if jobPercentages[jobName] then
            jobPercentage = tonumber(jobPercentages[jobName])
        else
            for _, row in ipairs(jobPercentages) do
                if row.job == jobName then
                    jobPercentage = tonumber(row.percentage)
                    break
                end
            end
        end
    end

    local percentage = jobPercentage or basePercentage
    percentage = math.max(1, math.min(100, percentage))
    if not jobPercentage then
        percentage = math.min(percentage, maxPercentage)
    end

    return {
        input = wash.input or Config.WitwasRoute.InputAccount,
        output = wash.output or Config.WitwasRoute.OutputAccount,
        percentage = percentage,
        minAmount = tonumber(wash.minAmount or Config.WitwasRoute.MinAmount) or Config.WitwasRoute.MinAmount,
        maxAmount = math.min(tonumber(wash.maxAmount or Config.WitwasRoute.MaxAmount) or Config.WitwasRoute.MaxAmount, Config.Security.MaxWashAmount),
        fee = tonumber(wash.fee or 0) or 0,
        route = route,
        jobName = jobName
    }
end

function HBH.Security.CalculateWashOutput(amount, washData)
    amount = math.floor(tonumber(amount or 0) or 0)
    local percentage = tonumber(washData.percentage or Config.WitwasRoute.DefaultPercentage) or Config.WitwasRoute.DefaultPercentage
    local fee = tonumber(washData.fee or 0) or 0
    local outputAmount = math.floor(amount * (percentage / 100.0))
    if fee > 0 then outputAmount = math.floor(outputAmount - (outputAmount * (fee / 100.0))) end
    return math.max(0, outputAmount)
end
