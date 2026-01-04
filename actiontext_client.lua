local activeTexts = {}

Citizen.CreateThread(function()
    SetNuiFocus(false, false)
    Wait(500)
    SendNUIMessage({ type = 'actiontext:update', items = {} })
end)

local function rgbToHex(tbl)
    if type(tbl) ~= 'table' then return nil end
    local r = math.floor((tbl[1] or 0))
    local g = math.floor((tbl[2] or 0))
    local b = math.floor((tbl[3] or 0))
    return ('#%02x%02x%02x'):format(r, g, b)
end

local function getBubbleScale()
    local baseScale = 0.5
    local configured = (Config.GLOBAL and Config.GLOBAL.textScale) or baseScale
    if baseScale == 0 then return 1.0 end
    return configured / baseScale
end

local function getBubbleSizePx()
    local nuiCfg = (Config.GLOBAL and Config.GLOBAL.nui) or nil
    if nuiCfg and nuiCfg.bubbleSizePx then
        return nuiCfg.bubbleSizePx
    end
    return 180
end

local cachedNuiOptions = nil
local function getNuiOptions()
    if cachedNuiOptions then return cachedNuiOptions end
    local nuiOptions = {}
    local nuiCfg = (Config.GLOBAL and Config.GLOBAL.nui) or {}
    if nuiCfg and nuiCfg.indicator then
        nuiOptions.indicatorEnabled = nuiCfg.indicator.enabled
        nuiOptions.indicatorStyle = nuiCfg.indicator.style
        nuiOptions.indicatorMeColor = (Config.ME and Config.ME.color) or nuiCfg.indicator.meColor
        nuiOptions.indicatorDoColor = (Config.DO and Config.DO.color) or nuiCfg.indicator.doColor
        nuiOptions.indicatorIntensity = nuiCfg.indicator.intensity
    end
    cachedNuiOptions = nuiOptions
    return nuiOptions
end

local function addText(serverId, actionType, text, avatarUrl, displayName)
    local player = GetPlayerFromServerId(serverId)
    if player == -1 then return end
    local ped = GetPlayerPed(player)
    if not DoesEntityExist(ped) then return end

    local color = (Config.GLOBAL and Config.GLOBAL.textColor) or {255,255,255}
    local bgHex = nil

    if actionType == 'me' then
        if Config.ME and Config.ME.color then color = Config.ME.color end
        bgHex = rgbToHex((Config.ME and Config.ME.bgColor) or Config.ME.color)
    elseif actionType == 'do' then
        if Config.DO and Config.DO.color then color = Config.DO.color end
        bgHex = rgbToHex((Config.DO and Config.DO.bgColor) or Config.DO.color)
    end

    local fmt = '%s'
    if actionType == 'me' and Config.ME and Config.ME.overheadFormat then
        fmt = Config.ME.overheadFormat
    elseif actionType == 'do' and Config.DO and Config.DO.overheadFormat then
        fmt = Config.DO.overheadFormat
    end
    text = string.format(fmt, text)

    do
        local nuiCfg = (Config.GLOBAL and Config.GLOBAL.nui) or {}
        local maxLen = nuiCfg.maxTextLength or 0
        if type(text) == 'string' and maxLen > 0 and #text > maxLen then
            text = text:sub(1, maxLen) .. '…'
        end
    end

    activeTexts[serverId] = {
        serverId = serverId,
        actionType = actionType,
        text = text,
        avatar = avatarUrl,
        displayName = displayName,
        color = color,
        bgHex = bgHex,
        expireAt = GetGameTimer() + ((Config.GLOBAL and Config.GLOBAL.displayTime or 6) * 1000)
    }
    lastSentItems = nil
    lastSentTime = 0
    local pname = displayName or GetPlayerName(GetPlayerFromServerId(serverId)) or ('Player' .. tostring(serverId))
    local immediateX, immediateY = 0.5, 0.5
    if (Config.GLOBAL and Config.GLOBAL.nui and Config.GLOBAL.nui.sendImmediateWithProjection) then
        local p = GetPlayerFromServerId(serverId)
        if p ~= -1 then
            local ped = GetPlayerPed(p)
            if DoesEntityExist(ped) then
                local head = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
                local cam = GetGameplayCamCoords()
                local dirx = head.x - cam.x
                local diry = head.y - cam.y
                local dirz = head.z - cam.z
                local dist = math.sqrt(dirx * dirx + diry * diry + dirz * dirz)
                if dist == 0 then dist = 0.0001 end
                dirx = dirx / dist
                diry = diry / dist
                dirz = dirz / dist

                local nuiCfg = (Config.GLOBAL and Config.GLOBAL.nui) or {}
                local baseForward = nuiCfg.forwardAnchor or 0.18
                local baseHead = nuiCfg.headOffset or 0.14
                local adapt = math.max(0, -dirz)
                local forwardDist = baseForward + (adapt * 0.25)
                local upOffset = baseHead + (adapt * 0.12)

                local anchorX = head.x - dirx * forwardDist
                local anchorY = head.y - diry * forwardDist
                local anchorZ = head.z + upOffset

                local onScreenA, asx, asy = World3dToScreen2d(anchorX, anchorY, anchorZ)
                local onScreenH, hsx, hsy = World3dToScreen2d(head.x, head.y, head.z)
                if onScreenH and hsx and hsy then
                    immediateX, immediateY = math.floor(hsx * 1000 + 0.5) / 1000, math.floor(hsy * 1000 + 0.5) / 1000
                elseif onScreenA and asx and asy then
                    immediateX, immediateY = math.floor(asx * 1000 + 0.5) / 1000, math.floor(asy * 1000 + 0.5) / 1000
                end
            end
        end
    end

    local items = {{
        id = serverId,
        x = immediateX,
        y = immediateY,
        text = text,
        playerName = pname,
        color = color,
        bg = bgHex,
        actionType = actionType,
        avatar = avatarUrl,
        scale = getBubbleScale(),
        sizePx = getBubbleSizePx(),
    }}
    SendNUIMessage({ type = 'actiontext:update', items = items, options = getNuiOptions() })
end


lastSentItems = nil
lastSentTime = 0
local minSendInterval = 33 -- ms
local posThreshold = 0.02 

local function itemsChanged(a, b, threshold)
    if not a and not b then return false end
    if (not a) ~= (not b) then return true end
    if #a ~= #b then return true end
    for i=1,#a do
        local ai = a[i]
        local bi = b[i]
        if not bi then return true end
        if ai.id ~= bi.id then return true end
        if ai.text ~= bi.text then return true end
        if ai.avatar ~= bi.avatar then return true end
        if ai.playerName ~= bi.playerName then return true end
        if ai.color ~= bi.color then return true end
        if ai.bg ~= bi.bg then return true end
        if ai.actionType ~= bi.actionType then return true end
        local th = threshold or posThreshold
        local dx = math.abs((ai.x or 0) - (bi.x or 0))
        local dy = math.abs((ai.y or 0) - (bi.y or 0))
        if dx > th or dy > th then return true end
    end
    return false
end

Citizen.CreateThread(function()
    local lastActive = false
    while true do
        local now = GetGameTimer()
        local items = {}
        local hasActive = false

        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)
        local radius = ((Config.GLOBAL and Config.GLOBAL.radius) or 20.0)
        local bubbleScale = getBubbleScale()
        local bubbleSizePx = getBubbleSizePx()
        local hOffset = ((Config.GLOBAL and Config.GLOBAL.nui and Config.GLOBAL.nui.horizontalOffsetPx) or 0)
        local vOffsetPx = ((Config.GLOBAL and Config.GLOBAL.nui and Config.GLOBAL.nui.verticalOffsetPx) or 10)
        local badgeSize = ((Config.GLOBAL and Config.GLOBAL.nui and Config.GLOBAL.nui.badgeSizePx) or 56)
        local nuiCfg = (Config.GLOBAL and Config.GLOBAL.nui) or {}
        local minSendIntervalLocal = nuiCfg.minSendIntervalMs or 33
        local posThresholdLocal = nuiCfg.posThreshold or 0.02
        local maxProjections = nuiCfg.maxProjectionsPerFrame or 16

        local candidates = {}
        for id, item in pairs(activeTexts) do
            if item.expireAt <= now then
                activeTexts[id] = nil
            else
                hasActive = true
                local player = GetPlayerFromServerId(item.serverId)
                if player ~= -1 then
                    local ped = GetPlayerPed(player)
                    if DoesEntityExist(ped) then
                        local coords = GetEntityCoords(ped)
                        local distance = #(myCoords - coords)
                        if distance <= radius then
                            table.insert(candidates, { id = id, item = item, distance = distance, player = player, ped = ped })
                        end
                    end
                end
            end
        end

        table.sort(candidates, function(a,b) return a.distance < b.distance end)
        for i=1, math.min(#candidates, maxProjections) do
            local c = candidates[i]
            local item = c.item
            local player = c.player
            local ped = c.ped
            local headBone = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
            local onScreen, sx, sy = World3dToScreen2d(headBone.x, headBone.y, headBone.z)
            if onScreen then
                if not item.cachedName then
                    item.cachedName = item.displayName or GetPlayerName(player) or ('Player' .. tostring(item.serverId))
                end
                local qsx = math.floor((sx or 0) * 1000 + 0.5) / 1000
                local qsy = math.floor((sy or 0) * 1000 + 0.5) / 1000
                table.insert(items, {
                    id = item.serverId,
                    x = qsx,
                    y = qsy,
                    text = item.text,
                    playerName = item.cachedName,
                    color = item.color,
                    bg = item.bgHex,
                    actionType = item.actionType,
                    headOffsetX = hOffset,
                    verticalOffsetPx = vOffsetPx,
                    avatar = (nuiCfg.disableAvatars and nil) or item.avatar,
                    badgeSizePx = badgeSize,
                    scale = bubbleScale,
                    sizePx = bubbleSizePx,
                })
            end
        end

        if hasActive then
            local nowTime = GetGameTimer()
            local shouldSend = itemsChanged(items, lastSentItems, posThresholdLocal)
            if shouldSend and (nowTime - lastSentTime) >= minSendIntervalLocal then
                SendNUIMessage({ type = 'actiontext:update', items = items, options = getNuiOptions() })
                lastSentItems = items
                lastSentTime = nowTime
            end
            lastActive = true
            Wait(0)
        else
            if lastActive then
                SendNUIMessage({ type = 'actiontext:update', items = {}, options = getNuiOptions() })
                lastSentItems = nil
                lastSentTime = GetGameTimer()
                lastActive = false
            end
            Wait(500)
        end
    end
end)

local function sendAction(actionType, text)
    if not text or text == '' then
        local title = (Config.GLOBAL and Config.GLOBAL.lang and Config.GLOBAL.lang.usageTitle) or '^1Actions'
        local fmt = (Config.GLOBAL and Config.GLOBAL.lang and Config.GLOBAL.lang.usageFormat) or 'Usage: /%s <message>'
        TriggerEvent('chat:addMessage', { args = { title, string.format(fmt, actionType) } })
        return
    end

    TriggerServerEvent('actiontext:send', actionType, text)
end

RegisterCommand('me', function(source, args)
    local text = table.concat(args, ' ')
    sendAction('me', text)
end, false)

RegisterCommand('do', function(source, args)
    local text = table.concat(args, ' ')
    sendAction('do', text)
end, false)

Citizen.CreateThread(function()
    local lang = (Config.GLOBAL and Config.GLOBAL.lang) or {}
    TriggerEvent('chat:addSuggestion', '/me', (Config.ME and Config.ME.suggestion) or lang.suggestionMe or 'Perform a roleplay emote', {{ name = 'message', help = lang.suggestionHelpMe or 'Describe your action' }})
    TriggerEvent('chat:addSuggestion', '/do', (Config.DO and Config.DO.suggestion) or lang.suggestionDo or 'Describe the environment or state', {{ name = 'message', help = lang.suggestionHelpDo or 'Describe scene/state' }})
end)

RegisterNetEvent('actiontext:display')
AddEventHandler('actiontext:display', function(serverId, actionType, text, avatarUrl, displayName)
    addText(serverId, actionType, text, avatarUrl, displayName)
end)

RegisterNetEvent('actiontext:avatarUpdate')
AddEventHandler('actiontext:avatarUpdate', function(serverId, avatarUrl)
    local s = activeTexts[serverId]
    if s then
        s.avatar = avatarUrl
        local items = {}
        for _, item in pairs(activeTexts) do
            if item then
                if not item.cachedName then
                    local p = GetPlayerFromServerId(item.serverId)
                    if p ~= -1 then
                        item.cachedName = item.displayName or GetPlayerName(p) or ('Player' .. tostring(item.serverId))
                    end
                end

                table.insert(items, {
                    id = item.serverId,
                    x = 0.5, y = 0.5,
                    text = item.text,
                    playerName = item.cachedName or 'Player',
                    color = item.color,
                    actionType = item.actionType,
                    avatar = item.avatar,
                    scale = getBubbleScale(),
                    sizePx = getBubbleSizePx(),
                })
            end
        end
        lastSentItems = nil
        SendNUIMessage({ type = 'actiontext:update', items = items, options = getNuiOptions() })
    end
end)