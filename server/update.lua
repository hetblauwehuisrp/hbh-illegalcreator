HBH = HBH or {}
HBH.Update = HBH.Update or {}

local resourceName = GetCurrentResourceName()
local state = {
    checked = false,
    blocked = false,
    checking = false,
    updating = false,
    latest = nil,
    current = nil,
    message = nil,
    failed = false
}

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

local function getCurrentVersion()
    local fileVersion = trim(LoadResourceFile(resourceName, 'version.txt') or '')
    local metaVersion = trim(GetResourceMetadata(resourceName, 'version', 0) or '')
    local configVersion = trim(Config.Version or '')

    if fileVersion ~= '' then return cleanVersion(fileVersion) end
    if metaVersion ~= '' then return cleanVersion(metaVersion) end
    if configVersion ~= '' then return cleanVersion(configVersion) end

    return '0.0.0'
end

local function printUpdate(current, latest)
    print(('^3[hbh-illegalcreator] er is een update %s -> %s gebruik updateall voor een update.^7'):format(current, latest))
end

local function printBlocked()
    print('^1[hbh-illegalcreator] resource NIET gestart omdat er eerst een update moet worden uitgevoerd.^7')
    print('^1[hbh-illegalcreator] gebruik console command: updateall^7')
end

local function setChecked(latest, manual, failed)
    latest = cleanVersion(latest)
    state.current = getCurrentVersion()
    state.latest = latest
    state.checked = true
    state.checking = false
    state.failed = failed == true

    if latest == '' then
        state.blocked = false
        state.message = nil
        if manual or Config.Debug then
            print('^1[hbh-illegalcreator] Update check mislukt: geen versie gevonden op GitHub. Resource wordt niet geblokkeerd.^7')
        end
        return
    end

    if compareVersions(state.current, latest) > 0 then
        state.blocked = (Config.UpdateChecker and Config.UpdateChecker.RequireLatest) == true
        state.message = ('Update nodig: %s -> %s. Gebruik updateall in de console.'):format(state.current, latest)
        printUpdate(state.current, latest)
        if state.blocked then printBlocked() end
    else
        state.blocked = false
        state.message = nil
        if manual or Config.Debug then
            print(('^2[hbh-illegalcreator] Je gebruikt de nieuwste versie (%s).^7'):format(state.current))
        end
    end
end

local function httpGet(url, headers, cb)
    PerformHttpRequest(url, function(status, body, responseHeaders)
        cb(tonumber(status) or 0, body or '', responseHeaders or {})
    end, 'GET', '', headers or { ['User-Agent'] = 'hbh-illegalcreator' })
end

local function parseLatestFromRelease(body)
    local ok, decoded = pcall(json.decode, body or '')
    if ok and decoded then
        return cleanVersion(decoded.tag_name or decoded.name or '')
    end
    return ''
end

function HBH.Update.Check(manual, cb)
    if not Config.UpdateChecker or Config.UpdateChecker.Enabled == false then
        state.checked = true
        state.blocked = false
        if cb then cb(false) end
        return
    end

    if state.checking then
        if cb then
            CreateThread(function()
                local waited = 0
                while state.checking and waited < 15000 do
                    Wait(250)
                    waited = waited + 250
                end
                cb(state.blocked, state.latest)
            end)
        end
        return
    end

    state.checking = true
    state.checked = false

    local versionUrl = Config.UpdateChecker.VersionUrl
    local releaseApi = Config.UpdateChecker.ReleaseApi

    local function finish(latest, failed)
        setChecked(latest, manual, failed)
        if cb then cb(state.blocked, latest) end
    end

    local function fallbackRelease()
        if not releaseApi or releaseApi == '' then
            finish('', true)
            return
        end

        httpGet(releaseApi, {
            ['User-Agent'] = 'hbh-illegalcreator-updatechecker',
            ['Accept'] = 'application/vnd.github+json'
        }, function(status, body)
            if status ~= 200 or not body or body == '' then
                if manual or Config.Debug then
                    print(('^1[hbh-illegalcreator] Update check mislukt via GitHub releases. Status: %s^7'):format(status or 'onbekend'))
                end
                finish('', true)
                return
            end
            finish(parseLatestFromRelease(body), false)
        end)
    end

    if versionUrl and versionUrl ~= '' then
        httpGet(versionUrl, { ['User-Agent'] = 'hbh-illegalcreator-updatechecker' }, function(status, body)
            if status == 200 and body and trim(body) ~= '' then
                finish(body, false)
            else
                fallbackRelease()
            end
        end)
    else
        fallbackRelease()
    end
end

local function urlEncodePath(path)
    path = tostring(path or '')
    return path:gsub('([^%w%-%._~/])', function(c)
        return string.format('%%%02X', string.byte(c))
    end)
end

local function extensionOf(path)
    return tostring(path or ''):match('(%.[^%.%/]+)$') or ''
end

local function isAllowedFile(path)
    if not path or path == '' then return false end
    path = tostring(path):gsub('\\', '/')
    if path:find('^/') or path:find('^%a:') then return false end
    if path:find('%.%./', 1, true) or path:find('/%.%.', 1, true) or path == '..' then return false end
    if path:find('^%.git') or path:find('^%.github/') then return false end
    if path:find('%.git/') or path:find('%.github/') then return false end

    local skip = Config.UpdateChecker.SkipPaths or {}
    for skipPath, enabled in pairs(skip) do
        if enabled == true then
            skipPath = tostring(skipPath or ''):gsub('\\', '/')
            if skipPath ~= '' and (path == skipPath or path:find('^' .. skipPath:gsub('([^%w])', '%%%1') .. '/')) then
                return false
            end
        end
    end

    if path:find('%.zip$') or path:find('%.rar$') or path:find('%.7z$') then return false end

    local allowed = Config.UpdateChecker.AllowedExtensions or {}
    local ext = extensionOf(path):lower()
    if #allowed == 0 then return true end

    for _, item in ipairs(allowed) do
        if ext == tostring(item):lower() then return true end
    end
    return false
end

local function rawBaseUrl()
    local owner = Config.UpdateChecker.Owner or 'hetblauwehuisrp'
    local repo = Config.UpdateChecker.Repo or 'hbh-illegalcreator'
    local branch = Config.UpdateChecker.Branch or 'main'
    return ('https://raw.githubusercontent.com/%s/%s/%s/'):format(owner, repo, branch)
end

local function treeUrl()
    local owner = Config.UpdateChecker.Owner or 'hetblauwehuisrp'
    local repo = Config.UpdateChecker.Repo or 'hbh-illegalcreator'
    local branch = Config.UpdateChecker.Branch or 'main'
    return ('https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1'):format(owner, repo, branch)
end

local function normalizeRepoPath(path)
    path = tostring(path or ''):gsub('\\', '/')
    path = path:gsub('/+', '/')
    path = path:gsub('^/+', '')
    return path
end

local function isSafeRepoPath(path)
    path = normalizeRepoPath(path)
    if path == '' then return false end
    if path:find('%.%./', 1, true) or path:find('/%.%.', 1, true) or path:find('^%.%.$') then return false end
    if path:find('^/') or path:find('^%a:') then return false end
    return true
end

local function pathSeparator()
    if package and package.config then
        return package.config:sub(1, 1)
    end
    return '/'
end

local function shellQuote(value)
    value = tostring(value or '')
    if pathSeparator() == '\\' then
        return '"' .. value:gsub('"', '\\"') .. '"'
    end
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function ensureDirectoryForFile(path)
    path = normalizeRepoPath(path)
    local dir = path:match('^(.+)/[^/]+$')
    if not dir or dir == '' then return true end

    local root = GetResourcePath(resourceName)
    if not root or root == '' then return false end

    local sep = pathSeparator()
    local target = root .. sep .. dir:gsub('/', sep)
    local commands

    if sep == '\\' then
        commands = {
            'mkdir ' .. shellQuote(target) .. ' >nul 2>nul',
            'powershell -NoProfile -ExecutionPolicy Bypass -Command "New-Item -ItemType Directory -Force -Path ' .. target:gsub('"', '\"') .. ' | Out-Null"'
        }
    else
        commands = {
            'mkdir -p ' .. shellQuote(target) .. ' >/dev/null 2>&1'
        }
    end

    for _, command in ipairs(commands) do
        pcall(function() os.execute(command) end)
    end

    -- Controleer niet hard op bestaan; sommige hosts geven geen betrouwbare returncode terug.
    return true
end

local function saveDownloadedFile(path, body)
    path = normalizeRepoPath(path)
    if not isSafeRepoPath(path) then return false, 'unsafe_path' end
    if not ensureDirectoryForFile(path) then return false, 'mkdir_failed' end

    local ok = SaveResourceFile(resourceName, path, body, #body)
    if ok then return true end

    -- Fallback voor hosts waar SaveResourceFile moeilijk doet met nieuwe mappen/binaire bestanden.
    local resourcePath = GetResourcePath(resourceName)
    if not resourcePath or resourcePath == '' then return false, 'no_resource_path' end

    local sep = pathSeparator()
    local fullPath = resourcePath .. sep .. path:gsub('/', sep)
    local file, err = io.open(fullPath, 'wb')
    if not file then return false, err or 'io_open_failed' end

    file:write(body)
    file:close()
    return true
end

local function downloadFiles(files, index, done, failed)
    if index > #files then
        done(failed)
        return
    end

    local file = files[index]
    file.path = normalizeRepoPath(file.path)
    local rawUrl = rawBaseUrl() .. urlEncodePath(file.path) .. ('?cache=%s'):format(os.time())

    httpGet(rawUrl, { ['User-Agent'] = 'hbh-illegalcreator-updater' }, function(status, body)
        if status == 200 and body ~= nil then
            local ok, saveErr = saveDownloadedFile(file.path, body)

            if not ok then
                print(('^1[hbh-illegalcreator] Kon bestand niet opslaan: %s (%s)^7'):format(file.path, tostring(saveErr or 'onbekend')))
                failed = true
            elseif Config.Debug then
                print(('^2[hbh-illegalcreator] Geüpdatet: %s^7'):format(file.path))
            end
        else
            print(('^1[hbh-illegalcreator] Download mislukt voor bestand: %s status: %s^7'):format(file.path, status))
            failed = true
        end

        SetTimeout(50, function()
            downloadFiles(files, index + 1, done, failed)
        end)
    end)
end

function HBH.Update.Run(src)
    if not Config.UpdateChecker or Config.UpdateChecker.Enabled == false then
        print('^3[hbh-illegalcreator] Update systeem staat uit in Config.UpdateChecker.Enabled.^7')
        return
    end
    if Config.UpdateChecker.AllowCommand == false then
        print('^3[hbh-illegalcreator] updateall staat uit in Config.UpdateChecker.AllowCommand.^7')
        return
    end
    if Config.UpdateChecker.AutoDownload == false then
        print('^3[hbh-illegalcreator] Automatisch downloaden staat uit in Config.UpdateChecker.AutoDownload.^7')
        return
    end

    if state.updating then
        print('^3[hbh-illegalcreator] Update is al bezig.^7')
        return
    end

    state.updating = true
    print('^5[hbh-illegalcreator] updateall gestart. Bestanden worden automatisch gedownload...^7')

    HBH.Update.Check(true, function()
        if not state.latest or state.latest == '' then
            print('^1[hbh-illegalcreator] Update gestopt: nieuwste versie kon niet worden opgehaald.^7')
            state.updating = false
            return
        end

        if compareVersions(getCurrentVersion(), state.latest) <= 0 then
            print('^2[hbh-illegalcreator] Geen update nodig.^7')
            state.updating = false
            return
        end

        httpGet(treeUrl(), {
            ['User-Agent'] = 'hbh-illegalcreator-updater',
            ['Accept'] = 'application/vnd.github+json'
        }, function(status, body)
            if status ~= 200 or not body or body == '' then
                print(('^1[hbh-illegalcreator] Update mislukt: kon GitHub bestandslijst niet ophalen. Status: %s^7'):format(status or 'onbekend'))
                state.updating = false
                return
            end

            local ok, decoded = pcall(json.decode, body)
            if not ok or not decoded or not decoded.tree then
                print('^1[hbh-illegalcreator] Update mislukt: GitHub bestandslijst is ongeldig.^7')
                state.updating = false
                return
            end

            local files = {}
            for _, entry in ipairs(decoded.tree) do
                local entryPath = normalizeRepoPath(entry.path)
                if entry.type == 'blob' and isSafeRepoPath(entryPath) and isAllowedFile(entryPath) then
                    files[#files + 1] = { path = entryPath }
                end
            end

            if #files == 0 then
                print('^1[hbh-illegalcreator] Update mislukt: geen geldige bestanden gevonden in GitHub repo.^7')
                state.updating = false
                return
            end

            print(('^5[hbh-illegalcreator] %s bestanden gevonden. Downloaden...^7'):format(#files))
            downloadFiles(files, 1, function(failed)
                state.updating = false
                if failed then
                    print('^1[hbh-illegalcreator] Update klaar met fouten. Controleer de console en voer updateall opnieuw uit.^7')
                    return
                end

                state.blocked = false
                state.current = state.latest
                print(('^2[hbh-illegalcreator] Update afgerond naar versie %s.^7'):format(state.latest))
                if Config.UpdateChecker.AutoRestartAfterUpdate ~= false then
                    print('^5[hbh-illegalcreator] Resource wordt opnieuw gestart...^7')
                    SetTimeout(1500, function()
                        ExecuteCommand(('restart %s'):format(resourceName))
                    end)
                else
                    print('^3[hbh-illegalcreator] Restart de resource om de update actief te maken.^7')
                end
            end, false)
        end)
    end)
end

function _G.HBHIllegalCreatorUpdateIsReady()
    return Config.UpdateChecker == nil or Config.UpdateChecker.Enabled == false or state.checked == true
end

function _G.HBHIllegalCreatorIsUpdateBlocked()
    return state.blocked == true
end

function _G.HBHIllegalCreatorUpdateMessage()
    return state.message or 'Deze resource is geblokkeerd totdat updateall is uitgevoerd.'
end

CreateThread(function()
    if not Config.UpdateChecker or Config.UpdateChecker.Enabled == false then
        state.checked = true
        return
    end

    Wait(tonumber(Config.UpdateChecker.CheckDelay or 1000) or 1000)
    HBH.Update.Check(false)
end)

RegisterCommand('updateall', function(src)
    if src ~= 0 then
        if not HBH or not HBH.Security or not HBH.Security.IsAdmin(src) then return end
        HBH.Security.Notify(src, Config.Notify.AdminTitle, 'Update gestart. Kijk in de server console.', 'info')
    end

    HBH.Update.Run(src)
end, false)
