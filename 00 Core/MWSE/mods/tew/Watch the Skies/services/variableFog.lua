local variableFog = {}

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
    defaults = {}
    defaultCloudSpeeds = {}

    local WtC = tes3.worldController.weatherController
    for i, w in pairs(WtC.weathers) do
        local fog = mge.weather.getDistantFog(i)
        defaults[i] = {
            distance = fog.distance,
            offset = fog.offset,
        }
        defaultCloudSpeeds[i] = w.cloudsSpeed or 100
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
    local orgFog = defaults[weatherIndex] or mge.weather.getDistantFog(weatherIndex)
    local orgDistance = orgFog.distance
    local orgOffset = orgFog.offset

    -- base oscillation speed from cloudSpeed
    local cloudSpeed = defaultCloudSpeeds[weatherIndex] or 100
    local baseSpeed = 0.082 + (cloudSpeed / 1000)

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
    local amplitudeBase = orgDistance * 0.12                                    -- smaller base amplitude
    local noise = smoothNoise(time * 0.1 + noiseSeed) * 0.5                     -- reduce noise effect
    local amplitude = amplitudeBase * (1 + gustAmplitude + noise)
    local phaseJitter = 0.5 + 0.25 * smoothNoise(time * 0.05 + noiseSeed + 500) -- less speed jitter
    local sine = math.sin(time * baseSpeed * phaseJitter)

    local newDistance = orgDistance + sine * amplitude
    local distanceDelta = newDistance - orgDistance
    local newOffset = orgOffset + distanceDelta * 0.02
    if math.abs(orgOffset) < 0.0001 then
        newOffset = orgOffset
    end

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
