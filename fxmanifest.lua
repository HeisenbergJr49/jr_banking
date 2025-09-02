fx_version 'cerulean'
game 'gta5'

name 'jr_Banking'
version '1.0.0'
description 'Modern Banking System for FiveM'
author 'HeisenbergJr49'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/server.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
    'nui/assets/**/*'
}

dependencies {
    'mysql-async',
    'es_extended'
}