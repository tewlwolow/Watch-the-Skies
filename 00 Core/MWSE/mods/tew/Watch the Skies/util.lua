local util = {}

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog

local defaultGlare = 0.0

-- master rain data
local rainTypes = {
	{ threshold = 2000, type = "light",  glare = 1.0 },
	{ threshold = 2600, type = "medium", glare = 0.7 },
	{ threshold = 5000, type = "heavy",  glare = defaultGlare },
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

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function lerpColor(c1, c2, t)
	return tes3vector3.new(
		lerp(c1.r, c2.r, t),
		lerp(c1.g, c2.g, t),
		lerp(c1.b, c2.b, t)
	)
end

function util.adjustColours(rainType)
	debugLog("Adjusting colours for rainType '" .. rainType .. "'")

	local WtC      = tes3.worldController.weatherController
	local srcIndex = (rainType == "light") and 2 or 5
	local src      = WtC.weathers[srcIndex]
	local dst      = WtC.weathers[5]

	local glare    = rainLookup[rainType].glare or defaultGlare

	-- small helper: boost saturation in RGB
	local function boostSaturation(color, factor)
		local avg = (color.r + color.g + color.b) / 3
		color.r = avg + (color.r - avg) * (1 + factor)
		color.g = avg + (color.g - avg) * (1 + factor)
		color.b = avg + (color.b - avg) * (1 + factor)
		-- clamp
		color.r = math.min(1, math.max(0, color.r))
		color.g = math.min(1, math.max(0, color.g))
		color.b = math.min(1, math.max(0, color.b))
		return color
	end

	local satBoost = 0.1 -- adjust this for desired saturation increase

	for _, key in ipairs({
		"sunSunriseColor", "sunDayColor", "sunSunsetColor",
		"skySunriseColor", "skyDayColor", "skySunsetColor",
		"fogSunriseColor", "fogDayColor", "fogSunsetColor",
	}) do
		local c = src[key]:copy()
		dst[key] = boostSaturation(c, satBoost)
		debugLog(string.format("%s | pre-boost = %.3f %.3f %.3f | post-boost = %.3f %.3f %.3f",
			key, src[key].r, src[key].g, src[key].b, dst[key].r, dst[key].g, dst[key].b))
	end

	dst.glareView = glare

	debugLog(string.format("Applied %s rain colours from weather[%d], glare=%.2f", rainType, srcIndex, glare))
	util.updateController()
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
