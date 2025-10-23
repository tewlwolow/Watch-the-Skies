local weatherTransitions = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog

--------------------------------------------------------------------------------------

local allowed = {
    [0] = { 1, 2 },
    [1] = { 0, 3, 4 },
    [2] = { 0, 3 },
    [3] = { 1, 4, 5 },
    [4] = { 3, 5, 0, 2 },
    [5] = { 4, 3, 2 },
    [6] = { 7, 3, 0 },
    [7] = { 6, 1, 0 },
    [8] = { 9, 3 },
    [9] = { 8, 3 },
}

--------------------------------------------------------------------------------------

local transitionLock = false

local function canTransition(from, to)
    if to == 7 then return true end -- blight always allowed
    for _, next in ipairs(allowed[from] or {}) do
        if next == to then return true end
    end
    return false
end

local function pickIntermediate(from, to)
    if from == 6 or from == 7 then return 0 end -- ash & blight → clear
    local list = allowed[from]
    for _, candidate in ipairs(list) do
        if candidate ~= to then return candidate end
    end
    return list[1]
end

local function isAllowedByRegion(to)
    local regionNow = tes3.getRegion(true)
    if not regionNow then return true end
    local chances = {
        [0] = regionNow.weatherChanceClear,
        [1] = regionNow.weatherChanceCloudy,
        [2] = regionNow.weatherChanceFoggy,
        [3] = regionNow.weatherChanceOvercast,
        [4] = regionNow.weatherChanceRain,
        [5] = regionNow.weatherChanceThunder,
        [6] = regionNow.weatherChanceAsh,
        [7] = regionNow.weatherChanceBlight,
        [8] = regionNow.weatherChanceSnow,
        [9] = regionNow.weatherChanceBlizzard,
    }
    return (chances[to] or 0) > 0
end

--------------------------------------------------------------------------------------

function weatherTransitions.handleTransition(e)
    if transitionLock then
        debugLog("Transition skipped, another transition in progress.")
        return
    end

    local WtC = tes3.worldController.weatherController
    local from = e.from and e.from.index or WtC.currentWeather.index
    local to = e.to.index

    -- Only intervene if the transition is invalid according to allowed weather flow
    if not canTransition(from, to) then
        local intermediate = pickIntermediate(from, to)

        -- Skip if intermediate is blocked by region
        if not isAllowedByRegion(intermediate) then
            debugLog(string.format("Intermediate %d → %d blocked by region, skipping reroute", from, to))
            return
        end

        debugLog(string.format("Invalid transition %d → %d, redirecting via intermediate %d", from, to, intermediate))

        transitionLock = true
        WtC:switchTransition(intermediate)

        timer.start {
            duration = 0.6,
            callback = function()
                local intermediateNow = WtC.currentWeather.index
                debugLog(string.format("Completing transition: intermediate %d → final %d", intermediateNow, to))
                if isAllowedByRegion(to) then
                    WtC:switchTransition(to)
                else
                    debugLog(string.format("Final transition %d → %d blocked by region, aborting", intermediateNow, to))
                end
                transitionLock = false
            end,
            iterations = 1,
            type = timer.game,
        }
    else
        debugLog(string.format("Valid transition %d → %d", from, to))
    end
end

--------------------------------------------------------------------------------------

event.register(tes3.event.loaded, function()
    transitionLock = false
    debugLog("Transition lock cleared on game load.")
end)

--------------------------------------------------------------------------------------

return weatherTransitions
