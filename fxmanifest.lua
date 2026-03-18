fx_version 'cerulean'
game 'gta5'

author 'Bryan Walker'
description 'Force all players into bucket 0 after FiniAC and Qbox load'
version '1.4.0'

lua54 'yes'

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

dependency 'ox_lib'
