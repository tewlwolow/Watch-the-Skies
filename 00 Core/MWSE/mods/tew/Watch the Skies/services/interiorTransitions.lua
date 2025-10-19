local interiorTransitions = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local WtC = tes3.worldController.weatherController
local intWeatherTimer

--------------------------------------------------------------------------------------

-- Main function controlling weather changes in interiors --
function interiorTransitions.progress()
	if WtC.nextWeather then return end

	local currentWeather = WtC.currentWeather.index -- 0-indexed
	local newWeather = nil
	debugLog("Weather before randomisation: " .. currentWeather)

	-- Get the current region
	local region = tes3.getRegion({ useDoors = true })
	if not region then return end
	local regionChances = region.weatherChances -- 1-indexed

	-- Build a list of available weathers excluding the current one
	local availableWeathers = {}
	local onlyCurrentHasChance = true

	for weather1, chance in pairs(regionChances) do
		local weather0 = weather1 - 1 -- convert to 0-index
		if weather0 ~= currentWeather then
			table.insert(availableWeathers, { weather = weather0, chance = chance })
			if chance > 0 then
				onlyCurrentHasChance = false
			end
		elseif chance < 100 then
			-- There are other weathers with chance < 100, so not forced to stay
			onlyCurrentHasChance = false
		end
	end

	-- If current weather is the only possible one, just keep it
	if onlyCurrentHasChance or #availableWeathers == 0 then
		newWeather = currentWeather
	else
		-- Weighted random selection
		local totalChance = 0
		for _, w in ipairs(availableWeathers) do
			totalChance = totalChance + w.chance
		end

		local roll = math.random() * totalChance
		local cumulative = 0
		for _, w in ipairs(availableWeathers) do
			cumulative = cumulative + w.chance
			if roll <= cumulative then
				newWeather = w.weather
				break
			end
		end
	end

	-- Switch to the new weather
	if newWeather ~= currentWeather then
		WtC:switchTransition(newWeather)
		debugLog("Weather randomised. New weather: " .. WtC.nextWeather.index)
	else
		debugLog("Weather remains the same: " .. currentWeather)
	end
end

--------------------------------------------------------------------------------------

function interiorTransitions.onCellChanged(e)
	if not e then return end
	local cell = e.cell
	if not cell then return end

	if cell.isOrBehavesAsExterior then
		if intWeatherTimer then
			intWeatherTimer:pause()
			debugLog("Player in exterior. Pausing interior timer.")
		end
	else
		if intWeatherTimer then
			intWeatherTimer:pause()
			intWeatherTimer:cancel()
			intWeatherTimer = nil
		end

		intWeatherTimer = timer.start {
			duration = WtC.hoursBetweenWeatherChanges,
			callback = interiorTransitions.progress,
			type = timer.game,
			iterations = -1,
		}

		debugLog("Player in interior. Resuming interior timer. Hours to weather change: " ..
			WtC.hoursBetweenWeatherChanges)
	end
end

--------------------------------------------------------------------------------------

return interiorTransitions
