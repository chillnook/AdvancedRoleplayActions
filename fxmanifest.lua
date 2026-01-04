fx_version 'cerulean'
game 'gta5'

author 'Nook & Co.'
description '/me & /do Roleplay Display Script'
version '1.0.0'

shared_scripts {
	'config.lua',
	'lang/en.lua',
	'lang/es.lua',
	'lang/lang.lua'
}

ui_page 'html/index.html'

files {
	'html/index.html',
	'html/style.css',
	'html/script.js',
}

client_script 'actiontext_client.lua'
server_script 'actiontext_server.lua'