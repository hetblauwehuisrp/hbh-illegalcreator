fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'HetBlauweHuisRP'
version '1.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locales.lua'
}

client_scripts {
    'client/main.lua',
    'client/admin.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/security.lua',
    'server/database.lua',
    'server/update.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/*',
    'html/assets/drugs/*',
    'fotos/drugs/*',
    'version.txt'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'okokNotify'
}
