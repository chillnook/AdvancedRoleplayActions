local discordAvatarCache = {}
local discordAvatarFetchedAt = {}
local discordMemberCache = {}
local discordMemberFetchedAt = {}

local FRAMEWORK = 'none'
local ESXObj = nil
local QBCoreObj = nil

pcall(function()
    if GetResourceState and GetResourceState('qb-core') == 'started' then
        FRAMEWORK = 'qbcore'
    elseif GetResourceState and GetResourceState('es_extended') == 'started' then
        FRAMEWORK = 'esx'
    end
end)

if FRAMEWORK == 'none' then
    pcall(function()
        if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
            FRAMEWORK = 'qbcore'
        end
    end)
end
if FRAMEWORK == 'none' then
    pcall(function()
        TriggerEvent('esx:getSharedObject', function(obj) if obj then FRAMEWORK = 'esx' end end)
    end)
end

local cfgFramework = (Config.GLOBAL and Config.GLOBAL.nui and Config.GLOBAL.nui.framework) or 'none'
if cfgFramework and cfgFramework ~= '' and cfgFramework ~= 'none' then
    FRAMEWORK = cfgFramework
end

if FRAMEWORK == 'esx' then
    pcall(function()
        TriggerEvent('esx:getSharedObject', function(obj) ESXObj = obj end)
    end)
elseif FRAMEWORK == 'qbcore' then
    pcall(function()
        if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
            QBCoreObj = exports['qb-core']:GetCoreObject()
        elseif _G and _G.QBCore then
            QBCoreObj = _G.QBCore
        end
    end)
end

print(('ActionText: framework detected/using = %s'):format(FRAMEWORK))

local function getCharacterName(src)
    local name = nil
    if FRAMEWORK == 'esx' and ESXObj then
        local ok, xPlayer = pcall(function() return ESXObj.GetPlayerFromId(src) end)
        if ok and xPlayer then
            if xPlayer.getName then
                pcall(function() name = xPlayer.getName() end)
            end
        end
    elseif FRAMEWORK == 'qbcore' and QBCoreObj then
        local ok, ply = pcall(function() return QBCoreObj.Functions.GetPlayer(src) end)
        if ok and ply and ply.PlayerData then
            local pd = ply.PlayerData
            if pd.charinfo then
                local fn = pd.charinfo.firstname or ''
                local ln = pd.charinfo.lastname or ''
                name = (fn .. ' ' .. ln):gsub('%s+', ' '):match('^%s*(.-)%s*$')
            elseif pd.name then
                name = pd.name
            end
        end
    end
    if not name or name == '' then
        name = GetPlayerName(src) or ('Player' .. tostring(src))
    end
    return name
end

local function getDiscordIdentifier(src)
    local ids = GetPlayerIdentifiers(src) or {}
    for _, id in ipairs(ids) do
        if type(id) == 'string' and id:sub(1,8) == 'discord:' then
            return id:sub(9)
        end
    end
    return nil
end

local function fetchAndCacheDiscordAvatar(src)
    if not (Config.GLOBAL and Config.GLOBAL.nui and Config.GLOBAL.nui.discord and Config.GLOBAL.nui.discord.enabled) then
        return
    end
    local botToken = (Config.GLOBAL.nui.discord.botToken)
    if not botToken or botToken == '' then return end

    local discordId = getDiscordIdentifier(src)
    if not discordId then return end

    local now = (os.time() * 1000)
    local last = discordAvatarFetchedAt[discordId] or 0
    local refresh = (Config.GLOBAL.nui.discord.refreshMs) or (60 * 60 * 1000)
    if discordAvatarCache[discordId] and (now - last) < refresh then
        return
    end

    local url = ('https://discord.com/api/v10/users/%s'):format(discordId)
    PerformHttpRequest(url, function(status, text, headers)
        if status == 200 and text then
            local ok, data = pcall(function() return json.decode(text) end)
            if ok and data and data.avatar then
                local avatarUrl = ('https://cdn.discordapp.com/avatars/%s/%s.png?size=128'):format(discordId, data.avatar)
                discordAvatarCache[discordId] = avatarUrl
                discordAvatarFetchedAt[discordId] = (os.time() * 1000)

                local showOnlyIfMember = (Config.GLOBAL.nui.discord.membershipCheck == true)
                if showOnlyIfMember and Config.GLOBAL.nui.discord.guildId then
                    local gUrl = ('https://discord.com/api/v10/guilds/%s/members/%s'):format(Config.GLOBAL.nui.discord.guildId, discordId)
                    PerformHttpRequest(gUrl, function(gStatus, gBody, gHeaders)
                        local isMember = (gStatus == 200)
                        discordMemberCache[discordId] = isMember
                        discordMemberFetchedAt[discordId] = (os.time() * 1000)
                        if isMember then
                            TriggerClientEvent('actiontext:avatarUpdate', -1, src, avatarUrl)
                        end
                    end, 'GET', '', { ['Authorization'] = ('Bot %s'):format(botToken) })
                else
                    TriggerClientEvent('actiontext:avatarUpdate', -1, src, avatarUrl)
                end
                return
            end
        end
        discordAvatarCache[discordId] = nil
        discordAvatarFetchedAt[discordId] = (os.time() * 1000)
    end, 'GET', '', { ['Authorization'] = ('Bot %s'):format(botToken), ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('actiontext:send')
AddEventHandler('actiontext:send', function(actionType, text)
    local src = source
    local playerName = GetPlayerName(src) or ('Player' .. tostring(src))

    local lang = (Config.GLOBAL and Config.GLOBAL.lang) or {}

    if not global_spam_tracker then global_spam_tracker = {} end
    local now = (os.time() * 1000)
    local spamCfg = (Config.GLOBAL and Config.GLOBAL.spam) or { cooldownMs = 1000, burstLimit = 3, burstWindowMs = 10000 }
    local s = global_spam_tracker[src]
    if not s then
        s = { times = {} }
        global_spam_tracker[src] = s
    end

    local newTimes = {}
    for _, t in ipairs(s.times) do
        if now - t <= spamCfg.burstWindowMs then table.insert(newTimes, t) end
    end
    s.times = newTimes

    local isAdmin = false
    if spamCfg and spamCfg.allowAdminBypass and spamCfg.adminAcePermission then
        pcall(function()
            isAdmin = IsPlayerAceAllowed(src, spamCfg.adminAcePermission)
        end)
    end

    if not isAdmin and #s.times >= spamCfg.burstLimit then
        if spamCfg.notify ~= false then
            local prefix = (spamCfg and spamCfg.spamPrefix) or lang.spamPrefix or 'SPAM'
            local msg = (spamCfg and spamCfg.spamMessage) or lang.spamMessage or 'You are sending actions too quickly. Please slow down.'
            TriggerClientEvent('chat:addMessage', src, { color = { 255, 100, 100 }, args = { prefix, msg } })
        end
        return
    end

    if not isAdmin and #s.times > 0 then
        local last = s.times[#s.times]
        if now - last < spamCfg.cooldownMs then
            if spamCfg.notify ~= false then
                local prefix = (spamCfg and spamCfg.spamPrefix) or lang.spamPrefix or 'SPAM'
                local msg = (spamCfg and spamCfg.spamMessage) or lang.spamMessage or 'Please wait before sending another action.'
                TriggerClientEvent('chat:addMessage', src, { color = { 255, 100, 100 }, args = { prefix, msg } })
            end
            return
        end
    end

    table.insert(s.times, now)

    if Config.GLOBAL and Config.GLOBAL.serverLogging then
        print(('[ActionText] /%s from %s (id=%s): %s'):format(actionType, playerName, tostring(src), text))
    end

    do
        local nuiCfg = (Config.GLOBAL and Config.GLOBAL.nui) or {}
        local maxLen = nuiCfg.maxTextLength or 0
        if type(text) == 'string' and maxLen > 0 and #text > maxLen then
            text = text:sub(1, maxLen) .. '…'
        end
    end

    pcall(function() fetchAndCacheDiscordAvatar(src) end)

    local avatarUrl = nil
    local discordId = getDiscordIdentifier(src)
    if discordId and discordAvatarCache[discordId] then
        local allow = true
        if (Config.GLOBAL.nui.discord and Config.GLOBAL.nui.discord.membershipCheck) and Config.GLOBAL.nui.discord.guildId then
            allow = (discordMemberCache[discordId] == true)
        end
        if allow then avatarUrl = discordAvatarCache[discordId] end
    end

    local displayName = pcall(function() return getCharacterName(src) end) and getCharacterName(src) or GetPlayerName(src)
    TriggerClientEvent('actiontext:display', -1, src, actionType, text, avatarUrl, displayName)

    local postChat = false
    local chatColor = { 255, 183, 0 }
    local formatted = ('%s %s'):format(playerName, text)

    if actionType == 'me' and Config.ME and Config.ME.chat then
        postChat = true
        chatColor = (Config.ME.chatColor or chatColor)

        formatted = (Config.ME.chatFormat or '%s %s'):format(playerName, text)
        if Config.ME.useChatPrefix and Config.ME.chatPrefix then
            local pf = (Config.ME.chatPrefixFormat or '^*%s^*^7 ')
            formatted = (pf:format(Config.ME.chatPrefix) or '') .. formatted
        else
            formatted = '^7' .. formatted
        end
    elseif actionType == 'do' and Config.DO and Config.DO.chat then
        postChat = true
        chatColor = (Config.DO.chatColor or chatColor)

        formatted = (Config.DO.chatFormat or '%s %s'):format(playerName, text)
        if Config.DO.useChatPrefix and Config.DO.chatPrefix then
            local pf = (Config.DO.chatPrefixFormat or '^*%s^*^7 ')
            formatted = (pf:format(Config.DO.chatPrefix) or '') .. formatted
        else
            formatted = '^7' .. formatted
        end
    end
    if postChat then
        TriggerClientEvent('chat:addMessage', -1, {
            color = chatColor,
            multiline = true,
            args = { formatted }
        })
    end
end)


AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Citizen.CreateThread(function()
        Wait(1000)
        local players = GetPlayers()
        for _, pid in ipairs(players) do
            local n = tonumber(pid)
            if n then
                pcall(function() fetchAndCacheDiscordAvatar(n) end)
            end
        end
    end)
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    SetTimeout(1500, function()
        pcall(function() fetchAndCacheDiscordAvatar(src) end)
    end)
end)