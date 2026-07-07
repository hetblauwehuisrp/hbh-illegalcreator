local lastLatestVersion = nil
local lastDownloadUrl = nil

local function trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function cleanVersion(value)
    value = trim(value)
    value = value:gsub('^v', ''):gsub('^V', '')
    value = value:match('([%d%.]+)') or value
    return trim(value)
end

local function splitVersion(value)
    local out = {}
    value = cleanVersion(value)
    for part in value:gmatch('(%d+)') do
        out[#out + 1] = tonumber(part) or 0
    end
    return out
end

local function compareVersions(current, latest)
    local a = splitVersion(current)
    local b = splitVersion(latest)
    local len = math.max(#a, #b, 1)
    for i = 1, len do
        local av = a[i] or 0
        local bv = b[i] or 0
        if bv > av then return 1 end
        if bv < av then return -1 end
    end
    return 0
end

local function printUpdate(current, latest)
    print(('^3[hbh-illegalcreator] er is een update %s -> %s gebruik updateall voor een update.^7'):format(current, latest))
end

local function printUpToDate(current, manual)
    if manual or Config.Debug then
        print(('^2[hbh-illegalcreator] Je gebruikt de nieuwste versie (%s).^7'):format(current))
    end
end

local function parseLatestFromRelease(body)
    local ok, decoded = pcall(json.decode, body or '')
    if ok and decoded then
        lastDownloadUrl = decoded.html_url or decoded.zipball_url or lastDownloadUrl
        return cleanVersion(decoded.tag_name or decoded.name or '')
    end
    return ''
end

local function handleLatest(latest, manual)
    latest = cleanVersion(latest)
    if latest == '' then
        if manual or Config.Debug then
            print('^1[hbh-illegalcreator] Update check mislukt: geen versie gevonden op GitHub.^7')
        end
        return
    end

    local current = cleanVersion(Config.Version or GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '0.0.0')
    lastLatestVersion = latest

    if compareVersions(current, latest) > 0 then
        printUpdate(current, latest)
    else
        printUpToDate(current, manual)
    end
end

function HBHCheckIllegalCreatorUpdate(manual)
    if not Config.UpdateChecker or Config.UpdateChecker.Enabled == false then return end

    local versionUrl = Config.UpdateChecker.VersionUrl
    local releaseApi = Config.UpdateChecker.ReleaseApi

    local function fallbackRelease()
        if not releaseApi or releaseApi == '' then
            if manual or Config.Debug then print('^1[hbh-illegalcreator] Update check mislukt: ReleaseApi ontbreekt.^7') end
            return
        end

        PerformHttpRequest(releaseApi, function(status, body)
            if status ~= 200 or not body then
                if manual or Config.Debug then
                    print(('^1[hbh-illegalcreator] Update check mislukt via GitHub releases. Status: %s^7'):format(status or 'onbekend'))
                end
                return
            end
            handleLatest(parseLatestFromRelease(body), manual)
        end, 'GET', '', {
            ['User-Agent'] = 'hbh-illegalcreator-updatechecker',
            ['Accept'] = 'application/vnd.github+json'
        })
    end

    if versionUrl and versionUrl ~= '' then
        PerformHttpRequest(versionUrl, function(status, body)
            if status == 200 and body and trim(body) ~= '' then
                lastDownloadUrl = Config.UpdateChecker.Github
                handleLatest(body, manual)
            else
                fallbackRelease()
            end
        end, 'GET', '', { ['User-Agent'] = 'hbh-illegalcreator-updatechecker' })
    else
        fallbackRelease()
    end
end

CreateThread(function()
    if not Config.UpdateChecker or Config.UpdateChecker.Enabled == false then return end
    Wait(tonumber(Config.UpdateChecker.CheckDelay or 5000) or 5000)
    HBHCheckIllegalCreatorUpdate(false)
end)

RegisterCommand('updateall', function(src)
    if src ~= 0 then
        if not HBH or not HBH.Security or not HBH.Security.IsAdmin(src) then return end
        HBH.Security.Notify(src, Config.Notify.AdminTitle, 'Update check gestart. Kijk in de server console.', 'info')
    end

    HBHCheckIllegalCreatorUpdate(true)

    local url = lastDownloadUrl or (Config.UpdateChecker and Config.UpdateChecker.Github) or 'GitHub'
    print(('^5[hbh-illegalcreator] Download/plaats de nieuwste versie vanaf: %s^7'):format(url))
end, false)
