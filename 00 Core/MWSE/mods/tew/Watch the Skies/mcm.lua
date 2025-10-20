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
local mainPage = template:createPage { label = "Main Settings", noScroll = true }
mainPage:createCategory {
    label = metadata.package.name .. " " .. metadata.package.version .. " by tewlwolow.\n" ..
        metadata.package.description .. "\n\nSettings:",
}

-- create buttons
local settings = {
    { label = "Enable Watch the Skies?",                                                                          id = "modEnabled" },
    { label = "Enable debug mode?",                                                                               id = "debugLogOn",           restartRequired = true },
    { label = "Enable randomised cloud textures?",                                                                id = "skyTexture" },
    { label = "Use vanilla sky textures? They need to be in your Data Files/Textures folder, BSA will not work.", id = "useVanillaSkyTextures" },
    { label = "Enable randomised hours between weather changes?",                                                 id = "dynamicWeatherChanges" },
    { label = "Enable weather changes in interiors?",                                                             id = "interiorTransitions" },
    { label = "Enable seasonal weather?",                                                                         id = "seasonalWeather" },
    { label = "Enable seasonal daytime hours?",                                                                   id = "seasonalDaytime" },
    { label = "Randomise max particles?",                                                                         id = "particleAmount" },
    { label = "Randomise clouds speed?",                                                                          id = "cloudSpeed" },
    { label = "Randomise rain and snow particle meshes?",                                                         id = "particleMesh",         restartRequired = true },
}

for _, setting in ipairs(settings) do
    mainPage:createYesNoButton {
        label = setting.label,
        variable = registerVariable(setting.id),
        restartRequired = setting.restartRequired,
    }
end

-- cloud speed dropdown
mainPage:createDropdown {
    label = "Cloud speed mode:",
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
