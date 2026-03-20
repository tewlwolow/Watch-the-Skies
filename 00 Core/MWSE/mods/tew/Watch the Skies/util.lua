local util = {}

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog

local defaultGlare = 0.0

-- master rain data
local rainTypes = {
	{ threshold = 2000, type = "light",  glare = 1.0,          colourSource = 2 },
	{ threshold = 2600, type = "medium", glare = 0.7,          colourSource = 3 },
	{ threshold = 5000, type = "heavy",  glare = defaultGlare, colourSource = 5 },
}

function util.updateController()
	local WtC = tes3.worldController.weatherController
	if not WtC then return end

	if WtC.nextWeather then
		local t = WtC.transitionScalar
		WtC:switchTransition(WtC.nextWeather.index)
		WtC.transitionScalar = t
	else
		WtC:switchImmediate(WtC.currentWeather.index)
	end

	if tes3.player then
		WtC:updateVisuals()
	end
	debugLog("Weather controller updated.")
end

-- quick lookup by name
local rainLookup = {}
for _, v in ipairs(rainTypes) do
	rainLookup[v.type] = v
end

local defaultColors = nil

function util.metadataMissing()
	local msg = "Error! Watch the Skies-metadata.toml file is missing. Please install."
	tes3.messageBox { message = msg }
	error(msg)
end

function util.getRainType(particleAmount)
	debugLog("Checking rain type for particleAmount = " .. tostring(particleAmount))
	for i = #rainTypes, 1, -1 do
		local r = rainTypes[i]
		if particleAmount >= r.threshold then
			debugLog(string.format("Selected rain type: '%s' (glare: %.2f, threshold: %d)", r.type, r.glare, r.threshold))
			return r.type, r.glare
		end
	end
	local fallback = rainLookup.light
	debugLog(string.format("Fallback to 'light' rain type (glare: %.2f)", fallback.glare))
	return fallback.type, fallback.glare
end

function util.adjustColours(rainType)
	debugLog("Adjusting colours for rainType '" .. rainType .. "'")

	local WtC      = tes3.worldController.weatherController
	local srcIndex = rainLookup[rainType].colourSource or 5
	local src      = WtC.weathers[srcIndex]
	local dst      = WtC.weathers[5]

	local glare    = rainLookup[rainType].glare or defaultGlare

	for _, key in ipairs({
		"sunSunriseColor", "sunDayColor", "sunSunsetColor",
		"skySunriseColor", "skyDayColor", "skySunsetColor",
		"fogSunriseColor", "fogDayColor", "fogSunsetColor",
	}) do
		local s, d = src[key]:copy(), dst[key]:copy()

		dst[key].r = math.lerp(s.r, d.r, 0.8)
		dst[key].g = math.lerp(s.g, d.g, 0.78)
		dst[key].b = math.lerp(s.b, d.b, 0.83)

		debugLog(string.format(
			"%s | pre = %.3f %.3f %.3f | post = %.3f %.3f %.3f",
			key,
			src[key].r, src[key].g, src[key].b,
			dst[key].r, dst[key].g, dst[key].b
		))
	end

	dst.glareView = glare

	debugLog(string.format(
		"Applied %s rain colours from weather[%d], glare=%.2f",
		rainType, srcIndex, glare
	))

	util.updateController()
end

function util.getRegionWeatherChances()
	local seasonalChances = require("tew.Watch the Skies.components.seasonalChances")

	for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
		if not seasonalChances[region.id] then
			local values = string.format(
				"{ %d, %d, %d, %d, %d, %d, %d, %d, %d, %d }",
				region.weatherChanceClear,
				region.weatherChanceCloudy,
				region.weatherChanceFoggy,
				region.weatherChanceOvercast,
				region.weatherChanceRain,
				region.weatherChanceThunder,
				region.weatherChanceAsh,
				region.weatherChanceBlight,
				region.weatherChanceSnow,
				region.weatherChanceBlizzard
			)

			mwse.log(string.format([[
			["%s"] = {
				[1] = %s,
				[2] = %s,
				[3] = %s,
				[4] = %s,
				[5] = %s,
				[6] = %s,
				[7] = %s,
				[8] = %s,
				[9] = %s,
				[10] = %s,
				[11] = %s,
				[12] = %s,
			},
			]],
				region.name,
				values, values, values, values,
				values, values, values, values,
				values, values, values, values
			))
		end
	end
end

function util.restoreDefaultRainColours()
	local WtC = tes3.worldController.weatherController
	local rainWeather = WtC.weathers[5]
	if not defaultColors then
		debugLog("No default colors saved; nothing to restore")
		return
	end

	debugLog("Restoring default sun, sky, and fog colors")
	for name, col in pairs(defaultColors) do
		rainWeather[name] = col
	end
	rainWeather.glareView = defaultGlare

	util.updateController()
end

return util
