local configPath = "Watch the Skies"
local config = require("tew.Watch the Skies.config")
local metadata = toml.loadMetadata("Watch the Skies")
local events = require("tew.Watch the Skies.components.events") -- contains services table
local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog

-- helper to register variables
local function registerVariable(id)
    return mwse.mcm.createTableVariable {
        id = id,
        table = config,
    }
end

-- create template
local template = mwse.mcm.createTemplate {
    name = metadata.package.name,
    headerImagePath = "\\Textures\\tew\\Watch the Skies\\WtS_logo.tga",
}

-- main page
local mainPage = template:createSideBarPage { label = "Main Settings",
    description = [[
Watch the Skies, Outlander!

MWSE Lua-based weather overhaul for Morrowind. Makes weather more dynamic and immersive.

Features:
- Enable weather changes indoors. In vanilla there is no change unless you enter when transition is already under way.
- Randomised cloud textures for varied skies. No more copy-pasted clouds all over Tamriel!
- Dynamic weather timing with shortened and randomized intervals. Less predictability and more natural transitions.
- Randomised rain and snow particle amounts and cloud speed. Best paired with AURA variable rain sounds and Vapourmist clouds.
- Seasonal weather with Blight scaling mechanics for the main quest. Each month will feel different across all regions.
- Dynamic daylight hours that vary by in-game season and latitude. Bring a torch to Dagon Fel!

Extras:
- Cloud and sunshaft shaders for improved visuals.
- 16 raindrop meshes using 5 textures, and 10 unique snow meshes for more varied weather effects.
- Optional Weather Adjuster preset inspired by the good old Red Skies mod and Morrowind concept art.
- Texture packs for clouds (1k resolution with 20+ variations per weather). Compatible with custom textures placed in Textures/tew/Watch the Skies - you can add and remove sky textures to your heart's content.

Notes:
- If using Weather Adjuster, enable the WA cloud setting for full compatibility.
- XE Sky Variations.esp from MGE XE is not needed when using Weather Adjuster - best to disable.
- There are two version of textures included - for vanilla and skies .iv mesh. Choose accordingly.
]],
}

mainPage:createCategory {
    label = metadata.package.name .. " " .. metadata.package.version .. " by tewlwolow.\n" ..
        metadata.package.description .. "\n\nSettings:",
}

-- create buttons
local settings = {
    {
        label = "Enable Watch the Skies?",
        id = "modEnabled",
        description =
        "Turns the 'Watch the Skies' mod on or off. Disabling will revert to default game weather and sky behavior.",
    },
    {
        label = "Enable debug mode?",
        id = "debugLogOn",
        restartRequired = true,
        description =
        "Activates detailed logging for troubleshooting. Not recommended for regular gameplay as it may impact performance and generate large log files. Intended for modders or bug reporting. Requires restart.",
    },
    {
        label = "Enable randomised cloud textures?",
        id = "skyTexture",
        description =
        "Randomises cloud textures for a more varied and dynamic sky appearance.",
    },
    {
        label = "Use vanilla sky textures?",
        id = "useVanillaSkyTextures",
        description =
        "Additionally use vanilla textures for more variation and an occasional full-blown nostalgic experience. Textures must be unpacked in the Data Files\\Textures folder. BSA archives are not supported.",
    },
    {
        label = "Enable randomised hours between weather changes?",
        id = "dynamicWeatherChanges",
        description =
        "Makes weather changes occur at random intervals instead of fixed times, creating a more unpredictable environment.",
    },
    {
        label = "Enable weather changes in interiors?",
        id = "interiorTransitions",
        description =
        "Allows interior areas to process weather changes. Best paired with AURA, so you can hear the weather change outside too.",
    },
    {
        label = "Enable seasonal weather?",
        id = "seasonalWeather",
        description =
        "Adjusts weather patterns (chances) according to the in-game season (month). Simulates rainy season and an occasional ashstorm or snowfall even in the beloved Balmora.",
    },
    {
        label = "Enable seasonal daytime hours?",
        id = "seasonalDaytime",
        description =
        "Changes the length of day/night to match the in-game season and latitude.",
    },
    {
        label = "Enable randomised max particles?",
        id = "particleAmount",
        description =
        "Randomises the maximum number of weather particles for more natural effects. Built-in compatibility with MCP particle occlusion.",
    },
    {
        label = "Enable randomised clouds speed?",
        id = "cloudSpeed",
        description =
        "Varies the speed at which clouds move across the sky. Interops with AURA for varied wind sound effects.",
    },
    {
        label = "Enable randomised rain and snow particle meshes?",
        id = "particleMesh",
        restartRequired = true,
        description =
        "Randomises the shapes of rain and snow particles for visual variety. Requires restart.",
    },
    {
        label = "Enable variable fog?",
        id = "variableFog",
        description =
        "Dynamically adjusts fog distance and offset for more realistic environments. Overall more foggy, more vanilla-like feeling.",
    },
}


for _, setting in ipairs(settings) do
    mainPage:createYesNoButton {
        label = setting.label,
        description = setting.description,
        variable = registerVariable(setting.id),
        restartRequired = setting.restartRequired,
    }
end

-- cloud speed dropdown
mainPage:createDropdown {
    label = "Cloud speed mode:",
    description = "Select the cloud speed mode. 'Vanilla' keeps standard speed, 'Skies .iv' is faster and works with Skies .iv meshes.",
    options = {
        { label = "Vanilla",   value = 100 },
        { label = "Skies .iv", value = 500 },
    },
    variable = registerVariable("cloudSpeedMode"),
}


-- onClose: start/stop only changed services + handle vanilla textures
template.onClose = function()
    local oldConfig = mwse.loadConfig(configPath) or {}

    mwse.saveConfig(configPath, config)

    -- Handle overall mod disable
    if not config.modEnabled then
        debugLog("Mod disabled — stopping all services.")
        for _, service in pairs(events.services) do
            service.stop()
        end
        return
    end

    -- Handle mod re-enabled
    if not oldConfig.modEnabled and config.modEnabled then
        debugLog("Mod enabled — starting enabled services.")
        for serviceName, service in pairs(events.services) do
            if config[serviceName] then
                debugLog(string.format("Starting service: %s", serviceName))
                service.init()
            end
        end
        return
    end

    -- Handle individual service toggles
    for serviceName, service in pairs(events.services) do
        local oldEnabled = oldConfig[serviceName]
        local newEnabled = config[serviceName]

        if oldEnabled ~= newEnabled then
            if newEnabled then
                debugLog(string.format("Enabling service: %s", serviceName))
                service.init()
            else
                debugLog(string.format("Disabling service: %s", serviceName))
                service.stop()
            end
        end
    end

    -- Handle vanilla sky textures toggle dynamically
    if oldConfig.useVanillaSkyTextures ~= config.useVanillaSkyTextures then
        local skyTexture = require("tew.Watch the Skies.services.skyTexture")
        if config.useVanillaSkyTextures then
            debugLog("Vanilla sky textures enabled — adding to texture table.")
            skyTexture.addVanillaTextures()
        else
            debugLog("Vanilla sky textures disabled — removing from texture table.")
            skyTexture.removeVanillaTextures()
        end
    end

    -- Handle cloud speed toggle dynamically
    if oldConfig.cloudSpeedMode ~= config.cloudSpeedMode then
        local cloudSpeed = require("tew.Watch the Skies.services.cloudSpeed")
        if config.cloudSpeed then
            cloudSpeed.restoreDefaults()
            cloudSpeed.init()
            debugLog("Cloud speed changed to " .. config.cloudSpeedMode)
        end
    end
end

mwse.mcm.register(template)
