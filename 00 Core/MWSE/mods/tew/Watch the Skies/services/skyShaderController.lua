local skyShaderController = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog

local suffix = ".backup"
local shaderPath = "Data Files\\shaders\\core-mods\\XE Mod Sky.fx"
local shaderPathBackup = string.format("%s%s", shaderPath, suffix)

local stateSwitch = {
    ["On"] = "Off",
    ["Off"] = "On",
}

--------------------------------------------------------------------------------------

local function reloadScattering()
    debugLog("Reloading atmospheric scattering...")
    local scatteringStateOriginal = mge.render["atmosphericScattering"]
    debugLog("Original atmospheric scattering state: " .. tostring(scatteringStateOriginal))

    mge.render["atmosphericScattering"] = stateSwitch[scatteringStateOriginal]
    debugLog("Temporarily set atmosphericScattering to: " .. tostring(mge.render["atmosphericScattering"]))
    mge.reloadDistantLand()
    debugLog("Reloaded distant land (first pass).")

    mge.render["atmosphericScattering"] = scatteringStateOriginal
    debugLog("Restored atmosphericScattering to: " .. tostring(scatteringStateOriginal))
    mge.reloadDistantLand()
    debugLog("Reloaded distant land (second pass).")
end

--------------------------------------------------------------------------------------

function skyShaderController.modShaderOn()
    debugLog("Attempting to enable mod shader...")

    if lfs.fileexists(shaderPathBackup) then
        debugLog("Backup shader found at: " .. shaderPathBackup)
        local success, err = os.rename(shaderPathBackup, shaderPath)
        if success then
            debugLog("Renamed " .. shaderPathBackup .. " -> " .. shaderPath)
            reloadScattering()
            debugLog("Mod shader successfully enabled.")
        else
            debugLog("Error renaming shader file: " .. tostring(err))
        end
    else
        debugLog("No backup shader found. Shader is already active?")
    end
end

function skyShaderController.modShaderOff()
    debugLog("Attempting to disable mod shader...")

    if lfs.fileexists(shaderPath) then
        debugLog("Shader found at: " .. shaderPath)
        local success, err = os.rename(shaderPath, shaderPathBackup)
        if success then
            debugLog("Renamed " .. shaderPath .. " -> " .. shaderPathBackup)
            reloadScattering()
            debugLog("Mod shader successfully disabled.")
        else
            debugLog("Error renaming shader file: " .. tostring(err))
        end
    else
        debugLog("Shader file not found. Shader may already be disabled?")
    end
end

function skyShaderController.switch()
    debugLog("Switching shader state based on weather...")

    local WtC = tes3.worldController.weatherController
    local weatherName = WtC.nextWeather and WtC.nextWeather.name or WtC.currentWeather.name
    debugLog("Detected weather: " .. tostring(weatherName))

    if weatherName == "Foggy" then
        debugLog("Weather is Foggy — disabling shader.")
        skyShaderController.modShaderOff()
    else
        debugLog("Weather is not Foggy (" .. tostring(weatherName) .. ") — enabling shader.")
        skyShaderController.modShaderOn()
    end
end

--------------------------------------------------------------------------------------

return skyShaderController
