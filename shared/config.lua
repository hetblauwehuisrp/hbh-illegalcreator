Config = {}

Config.Version = '1.1.5'

Config.Debug = false

Config.Command = 'illegalcreator'


Config.UpdateChecker = {
    Enabled = true,
    RequireLatest = true,
    AutoRestartAfterUpdate = true,
    Github = 'https://github.com/hetblauwehuisrp/hbh-illegalcreator',
    Owner = 'hetblauwehuisrp',
    Repo = 'hbh-illegalcreator',
    Branch = 'main',
    VersionUrl = 'https://raw.githubusercontent.com/hetblauwehuisrp/hbh-illegalcreator/main/version.txt',
    ReleaseApi = 'https://api.github.com/repos/hetblauwehuisrp/hbh-illegalcreator/releases/latest',
    CheckDelay = 1000,
    AllowedExtensions = {
        '.lua', '.html', '.css', '.js', '.json', '.sql', '.md', '.txt',
        '.png', '.jpg', '.jpeg', '.webp', '.svg'
    }
}

Config.UseAcePermission = false
Config.AcePermission = 'hbh.illegalcreator'
Config.AdminGroups = {
    owner = true,
    superadmin = true,
    admin = true,
    mod = true
}

Config.PoliceJobs = {
    police = true,
    sheriff = true,
    kmar = true,
    recherche = true
}

Config.PoliceRanks = {
    -- Zet hier job grades die minimaal mogen meetellen.
    -- Leeg/nil betekent: elke grade telt mee.
    police = 0,
    sheriff = 0,
    kmar = 0,
    recherche = 0
}

Config.Database = {
    AutoCreate = true,
    Table = 'hbh_illegal_activities'
}

Config.Notify = {
    Duration = 5000,
    AdminTitle = 'HBH Illegal Creator',
    Sound = true
}

Config.Defaults = {
    Cooldown = 900,
    Duration = 7500,
    MinPolice = 0,
    MinPoliceGrade = 0,
    TargetRadius = 1.8,
    MaxDistance = 3.0,
    PoliceBlipTime = 60,
    AlertChance = 100,
    Enabled = true,
    Progressbar = true,
    Minigame = false,
    MinigameDifficulty = 'normal',
    Marker = true,
    Blip = false
}

Config.Security = {
    AntiSpamMs = 1200,
    AdminAntiSpamMs = 650,
    MaxStartDistance = 12.0,
    MaxStepDistance = 7.0,
    MaxRewardAmount = 250000,
    MaxRequiredAmount = 250000,
    MaxActionPoints = 50,
    MaxPayloadBytes = 45000,
    MaxAdminPayloadBytes = 250000,
    SessionTimeout = 60 * 45,
    DoorRelockMinDelay = 1000,
    DoorRelockMaxDelay = 1000 * 60 * 30,
    MaxWashAmount = 10000000,
    Exploit = {
        MaxStrikes = 5,
        DropPlayer = false,
        PrintConsole = true
    }
}

Config.Target = {
    DefaultIcon = 'fa-solid fa-user-secret',
    DefaultRadius = 1.8,
    Distance = 2.5,
    LabelPrefix = 'Start'
}

Config.Marker = {
    Type = 2,
    Size = { x = 0.28, y = 0.28, z = 0.28 },
    Color = { r = 50, g = 140, b = 255, a = 160 },
    DrawDistance = 25.0,
    InteractDistance = 2.0
}

Config.Blip = {
    Sprite = 514,
    Color = 27,
    Scale = 0.72,
    ShortRange = true
}

Config.PoliceAlert = {
    Text = 'Verdachte illegale activiteit gemeld in de buurt.',
    BlipSprite = 161,
    BlipColor = 1,
    BlipScale = 1.2,
    BlipRadius = 75.0,
    BlipAlpha = 160
}

Config.Minigame = {
    Difficulty = {
        easy = { 'easy', 'easy' },
        normal = { 'easy', 'medium', 'easy' },
        hard = { 'medium', 'hard', 'medium' },
        expert = { 'hard', 'hard', 'medium', 'hard' }
    },
    Inputs = { 'w', 'a', 's', 'd' }
}

Config.Waypoint = {
    EnabledByDefault = true,
    StepBlipSprite = 1,
    StepBlipColor = 27,
    StepBlipScale = 0.8
}

Config.Categories = {
    { value = 'witwassen', label = 'Witwassen' },
    { value = 'drugs_plukken', label = 'Drugs plukken' },
    { value = 'drugs_verwerken', label = 'Drugs verwerken' },
    { value = 'drugs_verpakken', label = 'Drugs verpakken' },
    { value = 'drugs_verkopen', label = 'Drugs verkopen' },
    { value = 'illegale_crafting', label = 'Illegale crafting' },
    { value = 'illegaal_transport', label = 'Illegaal transport' },
    { value = 'lab_activiteit', label = 'Lab activiteit' },
    { value = 'dropoff', label = 'Dropoff' },
    { value = 'custom', label = 'Custom' }
}

Config.ActionTypes = {
    { value = 'collect', label = 'Item verzamelen' },
    { value = 'process', label = 'Item verwerken' },
    { value = 'package', label = 'Item verpakken' },
    { value = 'wash_start', label = 'Witwassen starten' },
    { value = 'money_convert', label = 'Geld omzetten' },
    { value = 'wash_route_stop', label = 'Witwas routepunt' },
    { value = 'npc_sell', label = 'NPC verkoop' },
    { value = 'craft', label = 'Craften' },
    { value = 'deliver', label = 'Inleveren' },
    { value = 'pickup', label = 'Ophalen' },
    { value = 'dropoff', label = 'Dropoff' },
    { value = 'hack', label = 'Hacken' },
    { value = 'lockpick', label = 'Lockpicken' },
    { value = 'force_door', label = 'Deur forceren' },
    { value = 'custom', label = 'Custom actie' }
}

Config.QuickItems = {
    { type = 'account', name = 'money', label = 'Contant geld' },
    { type = 'account', name = 'black_money', label = 'Zwart geld' },
    { type = 'account', name = 'bank', label = 'Bank' },
    { type = 'item', name = 'lockpick', label = 'Lockpick' },
    { type = 'item', name = 'thermiet', label = 'Thermiet' },
    { type = 'item', name = 'hacking_device', label = 'Hacking device' },
    { type = 'item', name = 'coke_leaf', label = 'Drugs item' },
    { type = 'item', name = 'custom', label = 'Custom' }
}

Config.AnimationPresets = {
    none = {
        label = 'Geen animatie'
    },
    thermite = {
        label = 'Lassen / thermite',
        dict = 'anim@heists@ornate_bank@thermal_charge',
        clip = 'thermal_charge',
        flag = 49
    },
    phone_hack = {
        label = 'Telefoon / hacken',
        scenario = 'WORLD_HUMAN_STAND_MOBILE'
    },
    clipboard = {
        label = 'Clipboard',
        scenario = 'WORLD_HUMAN_CLIPBOARD'
    },
    search_kneel = {
        label = 'Knielen zoeken',
        dict = 'amb@medic@standing@kneel@base',
        clip = 'base',
        flag = 1
    },
    grab_money = {
        label = 'Geld pakken',
        dict = 'anim@heists@ornate_bank@grab_cash',
        clip = 'grab',
        flag = 49
    },
    drug_pick = {
        label = 'Drugs plukken',
        scenario = 'WORLD_HUMAN_GARDENER_PLANT'
    },
    drug_process = {
        label = 'Drugs verwerken',
        dict = 'mini@repair',
        clip = 'fixing_a_ped',
        flag = 49
    },
    drug_package = {
        label = 'Drugs verpakken',
        dict = 'anim@amb@business@coc@coc_unpack_cut_left@',
        clip = 'coke_cut_v1_coccutter',
        flag = 49
    },
    knock = {
        label = 'Klop animatie',
        dict = 'timetable@jimmy@doorknock@',
        clip = 'knockdoor_idle',
        flag = 49
    },
    smash = {
        label = 'Smash animatie',
        dict = 'missheist_jewel',
        clip = 'smash_case',
        flag = 49
    },
    force_door = {
        label = 'Deur forceren',
        dict = 'missheistfbi3b_ig7',
        clip = 'lift_fibagent_loop',
        flag = 49
    },
    custom = {
        label = 'Custom'
    }
}

Config.Doorlock = {
    Enabled = true,
    DefaultLocked = true,
    DefaultRelockDelay = 60000,
    SearchRadius = 3.0,
    NativeState = {
        unlocked = 0,
        locked = 1
    }
}

Config.WitwasRoute = {
    EnabledByDefault = true,
    PedModel = 's_m_m_highsec_01',
    PedScenario = 'WORLD_HUMAN_CLIPBOARD',
    VehicleModel = 'speedo',
    VehicleSpawnDistance = 5.0,
    OwnVehicleUpgradeEnabled = true,
    OwnVehicleUpgradePrice = 200000,
    OwnVehicleUpgradeAccount = 'bank',
    InputAccount = 'black_money',
    OutputAccount = 'money',
    DefaultPercentage = 50,
    MaxPercentage = 50,
    MinAmount = 10000,
    MaxAmount = 100000,
    MinStops = 2,
    MaxStops = 4,
    DefaultStopDuration = 10000,
    RandomDuration = true,
    RandomDurationMin = 8000,
    RandomDurationMax = 18000,
    KnockAnimation = { preset = 'knock' },
    JobPercentages = {
        -- Voorbeeld: ballas = 65, cartel = 70
    }
}
