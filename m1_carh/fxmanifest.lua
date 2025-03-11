fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Luxury Car Heist for ESX '
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', 
    'server/server.lua'
}

dependencies {
    'es_extended',
    'ox_target',
    'ps-ui'
}

ui_page 'html/ui.html'

files {
    'html/ui.html'
}
exports {
    'startUI' 
}
