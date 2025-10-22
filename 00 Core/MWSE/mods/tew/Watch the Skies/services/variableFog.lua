local variableFog    = {}

--------------------------------------------------------------------------------------
-- Require common for logging
--------------------------------------------------------------------------------------
local common         = require("tew.Watch the Skies.components.common")
local debugLog       = common.debugLog

--------------------------------------------------------------------------------------
-- Internal state
--------------------------------------------------------------------------------------
local defaultFog     = {
    [0] = { distance = 1.0, offset = 0 },    -- clear
    [1] = { distance = 0.9, offset = 0 },    -- cloudy
    [2] = { distance = 0.2, offset = 30 },   -- foggy
    [3] = { distance = 0.7, offset = 0 },    -- overcast
    [4] = { distance = 0.5, offset = 10 },   -- rain
    [5] = { distance = 0.5, offset = 20 },   -- thunder
    [6] = { distance = 0.25, offset = 45 },  -- ash
    [7] = { distance = 0.25, offset = 50 },  -- blight
    [8] = { distance = 0.5, offset = 40 },   -- snow
    [9] = { distance = 0.16, offset = 100 }, -- blizzard
}

local currentWeather = nil
local nextWeather    = nil

--------------------------------------------------------------------------------------
-- Utility: regional fog factor
--------------------------------------------------------------------------------------
local function computeFogFactorForRegion(region)
    if not region then return 0 end
    local fogScore = (region.weatherChanceFoggy or 0)
        + (region.weatherChanceAsh or 0)
        + (region.weatherChanceBlight or 0)
    return math.min(fogScore / 300, 1.0)
end

--------------------------------------------------------------------------------------
-- Utility: random variation with 50% chance to skip
--------------------------------------------------------------------------------------
local function applyRandomVariation(value, variationPercent)
    if math.random() < 0.5 then
        -- Use default value 50% of the time
        return value
    end
    local variation = value * variationPercent
    return value + (math.random() * 2 - 1) * variation
end

--------------------------------------------------------------------------------------
-- Log to message box
--------------------------------------------------------------------------------------
function variableFog.logFogValues(weatherIndex, distance, offset, region, fogFactor)
    local msg = ("Fog Debug:\nWeather=%d\nDistance=%.3f\nOffset=%.3f\nRegion=%s\nFogFactor=%.2f")
        :format(weatherIndex, distance, offset,
            region and region.id or "unknown",
            fogFactor)
    tes3.messageBox(msg)
end

--------------------------------------------------------------------------------------
-- Apply fog to a single weather preset
--------------------------------------------------------------------------------------
local function applyFogToWeather(weatherIndex, region)
    local preset = defaultFog[weatherIndex]
    if not preset then return end

    local fogFactor  = computeFogFactorForRegion(region)

    -- Base distance & offset
    local distance   = applyRandomVariation(preset.distance, 0.10)
    local offset     = preset.offset

    -- Distance–offset compensation
    local baseOffset = preset.offset + (1 - distance) * 234.57
    baseOffset       = applyRandomVariation(baseOffset, 0.20)

    if weatherIndex == 0 or weatherIndex == 1 then
        baseOffset = math.min(baseOffset, 40)
    elseif weatherIndex == 2 then
        baseOffset = math.min(baseOffset, 750 * distance)
    else
        baseOffset = math.min(baseOffset, 190)
    end

    local finalDistance = math.max(math.min(distance, 1.2), 0.05)
    local finalOffset   = math.max(math.min(baseOffset + 50 * fogFactor, 750 * distance), 0)

    -- Apply fog
    mge.weather.setDistantFog({
        weather  = weatherIndex,
        distance = finalDistance,
        offset   = finalOffset,
    })

    -- Log
    variableFog.logFogValues(weatherIndex, finalDistance, finalOffset, region, fogFactor)

    debugLog(("Applied fog: weather=%d, distance=%.3f, offset=%.3f, region=%s")
        :format(weatherIndex, finalDistance, finalOffset,
            region and region.id or "unknown"))
end

--------------------------------------------------------------------------------------
-- Apply fog on weather change
-- All weather presets except current and next
--------------------------------------------------------------------------------------
function variableFog.applyFogOnWeatherChange(current, next)
    currentWeather = current
    nextWeather    = next

    local region   = tes3.getRegion(true)

    for weatherIndex, _ in pairs(defaultFog) do
        if weatherIndex ~= currentWeather and weatherIndex ~= nextWeather then
            applyFogToWeather(weatherIndex, region)
        end
    end
end

--------------------------------------------------------------------------------------
-- Restore all fog settings to defaults
--------------------------------------------------------------------------------------
function variableFog.restoreDefaults()
    for weatherIndex, preset in pairs(defaultFog) do
        if preset then
            mge.weather.setDistantFog({
                weather = weatherIndex,
                distance = preset.distance,
                offset = preset.offset,
            })
            debugLog(("Restored default fog for weather=%d (distance=%.3f, offset=%.3f)")
                :format(weatherIndex, preset.distance, preset.offset))
        end
    end
    currentWeather = nil
    nextWeather    = nil
    debugLog("All fog presets restored to default values.")
end

--------------------------------------------------------------------------------------
return variableFog
