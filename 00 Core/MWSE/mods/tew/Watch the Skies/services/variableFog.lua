local variableFog = {}

--------------------------------------------------------------------------------------
-- Require common for logging
--------------------------------------------------------------------------------------
local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog

--------------------------------------------------------------------------------------
-- Internal state
--------------------------------------------------------------------------------------
local time = 0
local defaults = {}
local defaultCloudSpeeds = {}

local gustTimer = 0
local gustDuration = 0
local gustAmplitude = 0

-- random seed for noise
local noiseSeed = math.random() * 1000

-- smooth pseudo-noise function
local function smoothNoise(x)
    local i = math.floor(x)
    local f = x - i
    local v1 = math.sin(i * 12.9898 + 78.233) * 43758.5453
    local v2 = math.sin((i + 1) * 12.9898 + 78.233) * 43758.5453
    local blend = f * f * (3 - 2 * f)
    return (v1 * (1 - blend) + v2 * blend) / 10000
end

--------------------------------------------------------------------------------------
-- Store defaults and cloud speeds
--------------------------------------------------------------------------------------
function variableFog.storeDefaults()
    if not table.empty(defaults) then return end

    local WtC = tes3.worldController.weatherController
    for i, _ in pairs(WtC.weathers) do
        local fog = mge.weather.getDistantFog(i)
        if fog then
            defaults[i - 1] = {
                distance = fog.distance,
                offset = fog.offset,
            }
            debugLog(("[variableFog] Stored default for weather %d: distance=%.3f, offset=%.3f")
                :format(i - 1, fog.distance, fog.offset))
        end
    end
end

--------------------------------------------------------------------------------------
-- Restore defaults
--------------------------------------------------------------------------------------
function variableFog.restoreDefaults()
    for i = 0, 9 do
        local def = defaults[i]
        if def then
            mge.weather.setDistantFog({
                weather = i,
                distance = def.distance,
                offset = def.offset,
            })
            debugLog(string.format("Restored fog for weather %d: distance=%.3f, offset=%.3f", i, def.distance, def
                .offset))
        end
    end
end

--------------------------------------------------------------------------------------
-- Oscillate with natural, broken wave
--------------------------------------------------------------------------------------
function variableFog.oscillate(dt)
    dt = dt or 0.1
    time = time + dt

    local WtC = tes3.worldController.weatherController
    local weatherIndex = WtC.nextWeather and WtC.nextWeather.index or WtC.currentWeather.index

    -- Safely get original fog values
    local orgFog = (defaults[weatherIndex] and {
        distance = defaults[weatherIndex].distance,
        offset = defaults[weatherIndex].offset,
    }) or mge.weather.getDistantFog(weatherIndex) or { distance = 0, offset = 0 }

    local orgDistance = orgFog.distance or 0
    local orgOffset = orgFog.offset or 0

    -- base oscillation speed from cloudSpeed
    local cloudSpeed = defaultCloudSpeeds[weatherIndex] or 100
    local baseSpeed = 0.042 + (cloudSpeed / 1000)

    ----------------------------------------------------------------------------------
    -- Gust logic (subtle)
    ----------------------------------------------------------------------------------
    if gustTimer <= 0 then
        if math.random() < 0.01 then
            gustDuration = 0.5 + math.random() * 1.5    -- shorter gusts
            gustAmplitude = 0.05 + math.random() * 0.15 -- smaller spike
            gustTimer = gustDuration
        end
    else
        gustTimer = gustTimer - dt
        if gustTimer <= 0 then
            gustAmplitude = 0
        end
    end

    ----------------------------------------------------------------------------------
    -- Broken wave calculation, closer to center
    ----------------------------------------------------------------------------------
    local amplitudeBase = orgDistance * 0.12
    local noise = smoothNoise(time * 0.1 + noiseSeed) * 0.5
    local amplitude = amplitudeBase * (1 + gustAmplitude + noise)
    local phaseJitter = 0.5 + 0.25 * smoothNoise(time * 0.05 + noiseSeed + 500)
    local sine = math.sin(time * baseSpeed * phaseJitter)

    local newDistance = orgDistance + sine * amplitude
    local distanceDelta = newDistance - orgDistance
    local newOffset = orgOffset + distanceDelta * 0.02
    if math.abs(orgOffset) < 0.0001 then
        newOffset = orgOffset
    end

    ----------------------------------------------------------------------------------
    -- Debug logging
    ----------------------------------------------------------------------------------
    debugLog(("[variableFog] oscillate tick: weather=%d, orgDistance=%.3f, newDistance=%.3f, orgOffset=%.3f, newOffset=%.3f, sine=%.3f, amplitude=%.3f")
        :format(weatherIndex, orgDistance, newDistance, orgOffset, newOffset, sine, amplitude))

    ----------------------------------------------------------------------------------
    -- Apply updated fog
    ----------------------------------------------------------------------------------
    mge.weather.setDistantFog({
        weather = weatherIndex,
        distance = newDistance,
        offset = newOffset,
    })
end

--------------------------------------------------------------------------------------
return variableFog
