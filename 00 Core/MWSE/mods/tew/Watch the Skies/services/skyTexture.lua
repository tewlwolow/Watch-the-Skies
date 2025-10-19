local skyTexture = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local config = require("tew.Watch the Skies.config")
local WtSdir = "Data Files\\Textures\\tew\\Watch the Skies"
local WtC = tes3.worldController.weatherController

--------------------------------------------------------------------------------------

local weathers = {}

weathers.vanillaWeathers = {
	[0] = "tx_sky_clear",
	[1] = "tx_sky_cloudy",
	[2] = "tx_sky_foggy",
	[3] = "tx_sky_overcast",
	[4] = "tx_sky_rainy",
	[5] = "tx_sky_thunder",
	[6] = "tx_sky_ashstorm",
	[7] = "tx_sky_blight",
	[8] = "tx_bm_sky_snow",
	[9] = "tx_bm_sky_blizzard",
}

weathers.customWeathers = {}
for i = 0, 9 do
	weathers.customWeathers[i] = {}
end

local extensions = {
	[1] = "dds",
	[2] = "tga",
	[3] = "bmp",
}

--------------------------------------------------------------------------------------

local defaultSkyTextures = {}

local function addVanilla(index, sky)
	for _, extension in ipairs(extensions) do
		local texturePath = string.format("Data Files\\Textures\\%s.%s", sky, extension)
		if lfs.fileexists(texturePath) then
			table.insert(weathers.customWeathers[index], texturePath)
			debugLog("File added: " .. texturePath)
			break
		end
	end
end

--------------------------------------------------------------------------------------

local function updateController()
	if not WtC then return end

	if (WtC.nextWeather) then
		local t = WtC.transitionScalar
		WtC:switchTransition(WtC.nextWeather.index)
		WtC.transitionScalar = t
	else
		WtC:switchImmediate(WtC.currentWeather.index)
	end

	if tes3.player then
		WtC:updateVisuals()
	end
end

function skyTexture.storeDefaults()
	if not table.empty(defaultSkyTextures) then return end

	for i, w in pairs(WtC.weathers) do
		defaultSkyTextures[i] = w.cloudTexture
	end
	debugLog("Default sky textures stored.")
end

function skyTexture.restoreDefaults()
	for i, w in pairs(WtC.weathers) do
		if defaultSkyTextures[i] then
			w.cloudTexture = defaultSkyTextures[i]
			debugLog("Restored default texture for weather: " .. w.name)
		end
	end

	updateController()

	debugLog("All sky textures restored to defaults.")
end

function skyTexture.randomise(immediate)
	local weatherNow
	if WtC then
		weatherNow = WtC.currentWeather
	end
	if (WtC.nextWeather) then return end

	debugLog("Starting cloud texture randomisation.")
	for index, weather in ipairs(WtC.weathers) do
		if (weatherNow) and (weatherNow.index == index) and not (immediate) then goto continue end
		local textureList = weathers.customWeathers[index - 1]
		if #textureList > 0 then
			local i = math.random(#textureList)
			local texturePath = textureList[i]
			weather.cloudTexture = texturePath
			debugLog("Cloud texture path set: " .. weather.name .. " >> " .. weather.cloudTexture)
		end
		::continue::
	end

	if immediate then
		updateController()
	end
end

function skyTexture.init(params)
	local immediate = params and params.immediate or false
	-- Populate data tables with cloud textures --
	for name, index in pairs(tes3.weather) do
		local weatherPath = WtSdir .. "\\" .. name
		for sky in lfs.dir(weatherPath) do
			if sky ~= ".." and sky ~= "." then
				local texturePath = weatherPath .. "\\" .. sky
				if string.endswith(sky, ".dds") or string.endswith(sky, ".tga") then
					table.insert(weathers.customWeathers[index], texturePath)
					debugLog("File added: " .. texturePath)
				end
			end
		end
	end

	-- Also pull vanilla textures if needed --
	if config.useVanillaSkyTextures then
		for index, sky in pairs(weathers.vanillaWeathers) do
			addVanilla(index, sky)
		end
	end

	skyTexture.storeDefaults()
	skyTexture.randomise(immediate)
end

function skyTexture.startTimer()
	skyTexture.randomise()
	timer.start {
		duration = common.centralTimerDuration,
		callback = skyTexture.randomise,
		iterations = -1,
		type = timer.game,
	}
end

--------------------------------------------------------------------------------------

return skyTexture
