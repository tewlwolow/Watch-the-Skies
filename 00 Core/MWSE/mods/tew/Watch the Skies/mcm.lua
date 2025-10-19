local configPath = "Watch the Skies"
local config = require("tew.Watch the Skies.config")
local metadata = toml.loadMetadata("Watch the Skies")

local function registerVariable(id)
    return mwse.mcm.createTableVariable {
        id = id,
        table = config,
    }
end

local template = mwse.mcm.createTemplate {
    name = metadata.package.name,
    headerImagePath = "\\Textures\\tew\\Watch the Skies\\WtS_logo.tga",
}

local mainPage = template:createPage { label = "Main Settings", noScroll = true }
mainPage:createCategory {
    label = metadata.package.name .. " " .. metadata.package.version .. " by tewlwolow.\n" .. metadata.package.description .. "\n\nSettings:",
}

mainPage:createYesNoButton {
    label = "Enable Watch the Skies?",
    description = "Enable Watch the Skies?\n\nDefault: On\n\n",
    variable = registerVariable("modEnabled"),
}
mainPage:createYesNoButton {
    label = "Enable debug mode?",
    variable = registerVariable("debugLogOn"),
    restartRequired = true,
}
mainPage:createYesNoButton {
    label = "Enable randomised cloud textures?",
    variable = registerVariable("skyTexture"),
}
mainPage:createYesNoButton {
    label = "Use vanilla sky textures as well? Note that these need to be in your Data Files/Textures folder, BSA will not work.",
    variable = registerVariable("useVanillaSkyTextures"),
}
mainPage:createYesNoButton {
    label = "Enable randomised hours between weather changes?",
    variable = registerVariable("dynamicWeatherChanges"),
}
mainPage:createYesNoButton {
    label = "Enable weather changes in interiors?",
    variable = registerVariable("interiorTransitions"),
}
mainPage:createYesNoButton {
    label = "Enable seasonal weather?",
    variable = registerVariable("seasonalWeather"),
}
mainPage:createYesNoButton {
    label = "Enable seasonal daytime hours?",
    variable = registerVariable("seasonalDaytime"),
}
mainPage:createYesNoButton {
    label = "Randomise max particles?",
    variable = registerVariable("particleAmount"),
}
mainPage:createYesNoButton {
    label = "Randomise clouds speed?",
    variable = registerVariable("cloudSpeed"),
}
mainPage:createYesNoButton {
    label = "Randomise rain and snow particle meshes?",
    variable = registerVariable("particleMesh"),
    restartRequired = true,
}

mainPage:createDropdown {
    label = "Cloud speed mode:",
    options = {
        { label = "Vanilla",   value = 100 },
        { label = "Skies .iv", value = 500 },
    },
    variable = registerVariable("cloudSpeedMode"),
}

template.onClose = function()
    mwse.saveConfig(configPath, config)
    dofile("Data Files\\MWSE\\mods\\tew\\Watch the Skies\\components\\events.lua")
end

mwse.mcm.register(template)
