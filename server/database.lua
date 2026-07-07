HBH = HBH or {}
HBH.Database = {}

local tableName = Config.Database.Table

local function encode(value)
    return json.encode(value or {})
end

local function decode(value, fallback)
    if not value or value == '' then return fallback or {} end
    local ok, result = pcall(json.decode, value)
    if ok and result then return result end
    return fallback or {}
end

local function bool(v, default)
    if v == nil then return default == true end
    if type(v) == 'boolean' then return v end
    return tonumber(v) == 1 or v == '1' or v == 'true'
end

local function number(v, default)
    local n = tonumber(v)
    if n == nil then return default end
    return n
end

function HBH.Database.Normalize(data)
    data = data or {}
    local coords = data.coords or {}
    local settings = data.settings or {}

    local normalized = {
        id = tonumber(data.id),
        name = tostring(data.name or 'Nieuwe activiteit'),
        category = tostring(data.category or 'custom'),
        coords = {
            x = number(coords.x, 0.0),
            y = number(coords.y, 0.0),
            z = number(coords.z, 0.0),
            h = number(coords.h or coords.heading, 0.0)
        },
        target_radius = number(data.target_radius, Config.Defaults.TargetRadius),
        max_distance = number(data.max_distance, Config.Defaults.MaxDistance),
        required_items = data.required_items or {},
        rewards = data.rewards or {},
        action_points = data.action_points or {},
        animation = data.animation or {},
        min_police = number(data.min_police, Config.Defaults.MinPolice),
        min_police_grade = number(data.min_police_grade, Config.Defaults.MinPoliceGrade),
        cooldown = number(data.cooldown, Config.Defaults.Cooldown),
        duration = number(data.duration, Config.Defaults.Duration),
        police_blip_time = number(data.police_blip_time, Config.Defaults.PoliceBlipTime),
        enabled = bool(data.enabled, Config.Defaults.Enabled),
        alert_police = bool(data.alert_police, false),
        police_blip = bool(data.police_blip, false),
        progressbar = bool(data.progressbar, Config.Defaults.Progressbar),
        minigame = bool(data.minigame, Config.Defaults.Minigame),
        minigame_difficulty = tostring(data.minigame_difficulty or Config.Defaults.MinigameDifficulty),
        blip = bool(data.blip, Config.Defaults.Blip),
        marker = bool(data.marker, Config.Defaults.Marker),
        settings = settings,
        created_by = tostring(data.created_by or ''),
        updated_by = tostring(data.updated_by or '')
    }

    if #normalized.action_points > Config.Security.MaxActionPoints then
        local limited = {}
        for i = 1, Config.Security.MaxActionPoints do limited[i] = normalized.action_points[i] end
        normalized.action_points = limited
    end

    return normalized
end

function HBH.Database.FromRow(row)
    if not row then return nil end
    return HBH.Database.Normalize({
        id = row.id,
        name = row.name,
        category = row.category,
        coords = decode(row.coords, {}),
        target_radius = row.target_radius,
        max_distance = row.max_distance,
        required_items = decode(row.required_items, {}),
        rewards = decode(row.rewards, {}),
        action_points = decode(row.action_points, {}),
        animation = decode(row.animation, {}),
        min_police = row.min_police,
        min_police_grade = row.min_police_grade,
        cooldown = row.cooldown,
        duration = row.duration,
        police_blip_time = row.police_blip_time,
        enabled = row.enabled,
        alert_police = row.alert_police,
        police_blip = row.police_blip,
        progressbar = row.progressbar,
        minigame = row.minigame,
        minigame_difficulty = row.minigame_difficulty,
        blip = row.blip,
        marker = row.marker,
        settings = decode(row.settings, {}),
        created_by = row.created_by,
        updated_by = row.updated_by
    })
end

function HBH.Database.Ensure()
    if not Config.Database.AutoCreate then return end

    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(100) NOT NULL,
            `category` VARCHAR(80) NOT NULL DEFAULT 'custom',
            `coords` LONGTEXT NULL,
            `target_radius` FLOAT NOT NULL DEFAULT 1.8,
            `max_distance` FLOAT NOT NULL DEFAULT 3.0,
            `required_items` LONGTEXT NULL,
            `rewards` LONGTEXT NULL,
            `action_points` LONGTEXT NULL,
            `animation` LONGTEXT NULL,
            `min_police` INT NOT NULL DEFAULT 0,
            `min_police_grade` INT NOT NULL DEFAULT 0,
            `cooldown` INT NOT NULL DEFAULT 900,
            `duration` INT NOT NULL DEFAULT 7500,
            `police_blip_time` INT NOT NULL DEFAULT 60,
            `enabled` TINYINT(1) NOT NULL DEFAULT 1,
            `alert_police` TINYINT(1) NOT NULL DEFAULT 0,
            `police_blip` TINYINT(1) NOT NULL DEFAULT 0,
            `progressbar` TINYINT(1) NOT NULL DEFAULT 1,
            `minigame` TINYINT(1) NOT NULL DEFAULT 0,
            `minigame_difficulty` VARCHAR(20) NOT NULL DEFAULT 'normal',
            `blip` TINYINT(1) NOT NULL DEFAULT 0,
            `marker` TINYINT(1) NOT NULL DEFAULT 1,
            `settings` LONGTEXT NULL,
            `created_by` VARCHAR(80) NULL,
            `updated_by` VARCHAR(80) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_enabled` (`enabled`),
            INDEX `idx_category` (`category`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]):format(tableName))

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `hbh_illegal_wash_upgrades` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(80) NOT NULL,
            `activity_id` INT NOT NULL,
            `purchased_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uniq_identifier_activity` (`identifier`, `activity_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end

function HBH.Database.LoadAll()
    local rows = MySQL.query.await(('SELECT * FROM `%s` ORDER BY id DESC'):format(tableName)) or {}
    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = HBH.Database.FromRow(row)
    end
    return list
end

function HBH.Database.Insert(data, identifier)
    local a = HBH.Database.Normalize(data)
    a.created_by = identifier or a.created_by or ''
    a.updated_by = identifier or a.updated_by or ''

    local id = MySQL.insert.await(([[
        INSERT INTO `%s`
        (`name`, `category`, `coords`, `target_radius`, `max_distance`, `required_items`, `rewards`, `action_points`, `animation`, `min_police`, `min_police_grade`, `cooldown`, `duration`, `police_blip_time`, `enabled`, `alert_police`, `police_blip`, `progressbar`, `minigame`, `minigame_difficulty`, `blip`, `marker`, `settings`, `created_by`, `updated_by`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]):format(tableName), {
        a.name, a.category, encode(a.coords), a.target_radius, a.max_distance, encode(a.required_items), encode(a.rewards), encode(a.action_points), encode(a.animation), a.min_police, a.min_police_grade, a.cooldown, a.duration, a.police_blip_time, a.enabled and 1 or 0, a.alert_police and 1 or 0, a.police_blip and 1 or 0, a.progressbar and 1 or 0, a.minigame and 1 or 0, a.minigame_difficulty, a.blip and 1 or 0, a.marker and 1 or 0, encode(a.settings), a.created_by, a.updated_by
    })

    a.id = id
    return a
end

function HBH.Database.Update(id, data, identifier)
    local a = HBH.Database.Normalize(data)
    a.id = tonumber(id)
    a.updated_by = identifier or a.updated_by or ''

    MySQL.update.await(([[
        UPDATE `%s` SET
            `name` = ?, `category` = ?, `coords` = ?, `target_radius` = ?, `max_distance` = ?,
            `required_items` = ?, `rewards` = ?, `action_points` = ?, `animation` = ?,
            `min_police` = ?, `min_police_grade` = ?, `cooldown` = ?, `duration` = ?, `police_blip_time` = ?,
            `enabled` = ?, `alert_police` = ?, `police_blip` = ?, `progressbar` = ?, `minigame` = ?,
            `minigame_difficulty` = ?, `blip` = ?, `marker` = ?, `settings` = ?, `updated_by` = ?
        WHERE `id` = ?
    ]]):format(tableName), {
        a.name, a.category, encode(a.coords), a.target_radius, a.max_distance,
        encode(a.required_items), encode(a.rewards), encode(a.action_points), encode(a.animation),
        a.min_police, a.min_police_grade, a.cooldown, a.duration, a.police_blip_time,
        a.enabled and 1 or 0, a.alert_police and 1 or 0, a.police_blip and 1 or 0, a.progressbar and 1 or 0, a.minigame and 1 or 0,
        a.minigame_difficulty, a.blip and 1 or 0, a.marker and 1 or 0, encode(a.settings), a.updated_by,
        a.id
    })

    return a
end

function HBH.Database.Delete(id)
    return MySQL.update.await(('DELETE FROM `%s` WHERE `id` = ?'):format(tableName), { tonumber(id) })
end


function HBH.Database.HasWashUpgrade(identifier, activityId)
    if not identifier or identifier == '' or not activityId then return false end
    local row = MySQL.single.await('SELECT id FROM `hbh_illegal_wash_upgrades` WHERE `identifier` = ? AND `activity_id` = ? LIMIT 1', { identifier, tonumber(activityId) })
    return row ~= nil
end

function HBH.Database.AddWashUpgrade(identifier, activityId)
    if not identifier or identifier == '' or not activityId then return false end
    MySQL.insert.await('INSERT IGNORE INTO `hbh_illegal_wash_upgrades` (`identifier`, `activity_id`) VALUES (?, ?)', { identifier, tonumber(activityId) })
    return true
end
