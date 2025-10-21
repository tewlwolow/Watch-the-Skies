local variableFog = {}

--------------------------------------------------------------------------------------
-- Internal state
-- 'time' accumulates elapsed time for the fog oscillation cycle.
-- 'defaults' stores the original fog settings for each weather type (0–9)
-- so they can be safely restored when needed.
--------------------------------------------------------------------------------------
local time = 0
local defaults = {}

--------------------------------------------------------------------------------------
-- Store the default fog values for all weather types (0–9).
-- Only runs once per session if defaults have not been stored yet.
--------------------------------------------------------------------------------------
function variableFog.storeDefaults()
    if not table.empty(defaults) then return end
    defaults = {}
    for i = 0, 9 do -- Morrowind defines 10 weather types
        local fog = mge.weather.getDistantFog(i)
        defaults[i] = { distance = fog.distance, offset = fog.offset }
    end
end

--------------------------------------------------------------------------------------
-- Restore the previously stored fog defaults for all weather types.
-- Can be called at any time (e.g., on mod disable, reload, or cleanup)
-- to return all distant fog settings to their original state.
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
-- Applies a subtle time-based oscillation to the current weather’s fog settings.
-- This produces a slow, natural “shifting fog” effect that keeps fog layers dynamic
-- without appearing animated or artificial.
--
-- Parameters:
--   dt (number): Delta time in seconds since the last frame or update tick.
--                Typically passed as e.delta from the 'simulate' event.
--------------------------------------------------------------------------------------
function variableFog.oscillate(dt)
    -- Update internal timer
    time = time + (dt or 0.1)

    -- Determine which weather is currently active (or transitioning)
    local WtC = tes3.worldController.weatherController
    local weatherIndex = WtC.nextWeather and WtC.nextWeather.index or WtC.currentWeather.index

    -- Retrieve the original fog settings for this weather
    local orgFog = defaults[weatherIndex] or mge.weather.getDistantFog(weatherIndex)
    local orgDistance = orgFog.distance
    local orgOffset = orgFog.offset

    ----------------------------------------------------------------------------------
    -- Oscillation parameters
    -- amplitudeDist: amount of fog distance variation around its baseline value.
    -- baseSpeed:     controls how fast the oscillation progresses (lower = slower).
    ----------------------------------------------------------------------------------
    local amplitudeDist = orgDistance * 0.05
    local baseSpeed = 0.12

    -- Add gentle speed modulation to prevent the movement from feeling mechanical
    local speedVariation = 0.01 * math.sin(time * 0.01)
    local speed = baseSpeed + speedVariation

    -- Compute oscillation phase
    local sine = math.sin(time * speed)

    -- Calculate new fog distance
    local newDistance = orgDistance + sine * amplitudeDist

    -- Slightly adjust offset based on distance change for smoother visuals
    local distanceDelta = newDistance - orgDistance
    local newOffset = orgOffset + distanceDelta * 0.02 -- ~2% of distance delta

    -- Keep offset stable for flat fog types
    if math.abs(orgOffset) < 0.0001 then
        newOffset = orgOffset
    end

    -- Apply the updated fog settings
    mge.weather.setDistantFog({
        weather = weatherIndex,
        distance = newDistance,
        offset = newOffset,
    })
end

--------------------------------------------------------------------------------------
return variableFog
