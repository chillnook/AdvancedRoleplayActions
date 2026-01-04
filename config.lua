-- ============================================================================
-- ADVANCED /ME /DO (ESX & QB Supported) - Configuration
-- ============================================================================
--
-- QUICK TUNING (most common tweaks):
--   displayTime (sec)       - how long bubbles remain visible
--   radius (meters)         - max render distance
--   nui.bubbleSizePx (px)   - bubble width
--   nui.minSendIntervalMs   - NUI update throttle (ms)
--   nui.posThreshold        - screen jitter tolerance (0.01-0.05)
-- ============================================================================

Config = {}

-- ============================================================================
-- GLOBAL SETTINGS
-- ============================================================================
Config.GLOBAL = {
    locale = 'en',                       -- two-letter locale code
    displayTime = 8,                     -- seconds overhead bubble is shown
    textScale = 0.5,                     -- bubble text scale (larger = bigger text)
    textColor = { 255, 230, 100 },       -- fallback RGB text color
    radius = 20.0,                       -- max render distance (meters)
    baseHeight = 1.2,                    -- vertical offset from player origin (meters)
    serverLogging = true,                -- log usage events on server

    textShadow = {
        enabled = true,
        distance = 2,
        color = { 0, 0, 0, 255 },
    },
    textOutline = false,

    -- NUI (browser) visual and performance settings
    nui = {
        -- Visual sizing and positioning
        bubbleSizePx = 460,              -- bubble width in pixels
        headOffset = 0.25,               -- meters above head bone
        forwardAnchor = 0.18,            -- meters toward camera
        verticalOffsetPx = 98,           -- extra vertical px offset
        badgeSizePx = 56,                -- avatar badge size (px)
        horizontalOffsetPx = 0,          -- horizontal correction (px)

        framework = 'none',              -- 'none' | 'esx' | 'qbcore' (auto-detected, override here if needed)

        indicator = {
            enabled = true,
            style = 'glow',              -- 'glow' | 'border' | 'none' (glow = nicer but slightly more GPU)
            meColor = { 29, 155, 240 },
            doColor = { 255, 159, 67 },
            intensity = 0.36,            -- 0.0..1.0 glow/border intensity
        },

        -- Discord avatar fetching (server-side)
        discord = {
            enabled = false,
            botToken = '',
            guildId = nil,               -- optional: restrict to specific guild
            membershipCheck = false,
            refreshMs = 60 * 60 * 1000,  -- cache refresh interval (ms)
        },

        -- Performance tuning (trade accuracy for CPU). DO NOT TOUCH UNLESS YOU KNOW WHAT YOU ARE DOING.
        minSendIntervalMs = 33,          -- min NUI update interval (ms)
        posThreshold = 0.02,             -- screen threshold to ignore tiny jitter
        maxProjectionsPerFrame = 8,      -- max head projections per frame
        maxTextLength = 25,
        sendImmediateWithProjection = true,  -- compute immediate projection to avoid jump
        disableAvatars = false,          -- disable avatars to save work
        minimalMode = false,             -- disable glow/avatars for low-end systems
    },

    -- Anti-spam / rate limiting
    spam = {
        cooldownMs = 1000,               -- cooldown between actions (ms)
        burstLimit = 3,                  -- max actions in burst window
        burstWindowMs = 10000,           -- burst window duration (ms)
        spamPrefix = nil,                -- optional prefix for spam warnings (nil = use lang table)
        spamMessage = nil,               -- optional custom spam message (nil = use lang table)
        allowAdminBypass = true,         -- allow admins to bypass spam limits
        adminAcePermission = 'actiontext.bypass',
        notify = false,                  -- notify player of spam limit
    },
}

-- ============================================================================
-- /ME (emote) SETTINGS
-- ============================================================================
Config.ME = {
    color = { 100, 230, 255 },       -- text color (RGB)
    bgColor = { 33, 33, 33 },        -- bubble background (RGB)
    chat = false,                    -- forward to in-game chat
    chatColor = { 100, 230, 255 },
    chatPrefix = '[ME]: ',
    useChatPrefix = true,
    chatPrefixFormat = '^*%s^*^7 ',
    chatFormat = '%s - ^*%s^*',
    overheadFormat = '* %s *',       -- bubble text format (Lua format string)
    suggestion = nil,                -- chat suggestion text (nil = use lang table)
}

-- ============================================================================
-- /DO (scene/description) SETTINGS
-- ============================================================================
Config.DO = {
    color = { 255, 230, 120 },       -- text color (RGB)
    bgColor = { 33, 33, 33 },        -- bubble background (RGB)
    chat = true,                     -- forward to in-game chat
    chatColor = { 255, 200, 80 },
    chatPrefix = '[DO]: ',
    useChatPrefix = true,
    chatPrefixFormat = '^*%s^*^7 ',
    chatFormat = '%s - ^*%s^*',
    overheadFormat = '* %s',         -- bubble text format
    suggestion = nil,                -- chat suggestion text (nil = use lang table)
}