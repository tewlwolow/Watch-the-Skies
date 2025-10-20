local skyTexture = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local config = require("tew.Watch the Skies.config")
local WtSdir = "Data Files\\Textures\\tew\\Watch the Skies"
local WtC = tes3.worldController.weatherController

--------------------------------------------------------------------------------------

local skyTextures = {}
for i = 1, 10 do
	skyTextures[i] = {}
end

local defaultSkyTextures = {}
for i = 1, 10 do
	defaultSkyTextures[i] = ""
end

--------------------------------------------------------------------------------------

local function updateController()
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
end

--------------------------------------------------------------------------------------

function skyTexture.storeDefaults()
	for i, w in ipairs(WtC.weathers) do
		if defaultSkyTextures[i] == "" then
			defaultSkyTextures[i] = w.cloudTexture
		end
	end
	debugLog("Default sky textures stored.")
end

function skyTexture.restoreDefaults()
	skyTexture.storeDefaults()
	for i, w in ipairs(WtC.weathers) do
		if defaultSkyTextures[i] then
			w.cloudTexture = defaultSkyTextures[i]
			debugLog("Restored default texture for weather: " .. w.name .. " - " .. defaultSkyTextures[i])
		end
	end
	updateController()
	debugLog("All sky textures restored to defaults.")
end

function skyTexture.addVanillaTextures()
	for index, texturePath in ipairs(defaultSkyTextures) do
		local list = skyTextures[index]
		for i = #list, 1, -1 do
			if list[i] == texturePath then
				table.remove(list, i)
			end
		end
		table.insert(list, texturePath)
		debugLog("Vanilla texture added: " .. texturePath)
	end
end

function skyTexture.removeVanillaTextures()
	for index, texturePath in ipairs(defaultSkyTextures) do
		local list = skyTextures[index]
		for i = #list, 1, -1 do
			if list[i] == texturePath then
				table.remove(list, i)
				debugLog("Vanilla texture removed: " .. texturePath)
			end
		end
	end
end

--------------------------------------------------------------------------------------

function skyTexture.randomise(immediate)
	local weatherNow
	if WtC then
		weatherNow = WtC.currentWeather
	end
	if WtC.nextWeather then return end

	debugLog("Starting cloud texture randomisation.")
	for index, weather in ipairs(WtC.weathers) do
		if weatherNow and weatherNow.index == index and not immediate then goto continue end
		local textureList = skyTextures[index]
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

--------------------------------------------------------------------------------------

function skyTexture.init(params)
	skyTexture.storeDefaults()

	local immediate = params and params.immediate or false

	-- Populate texture tables
	if table.empty(skyTextures, true) then
		for name, index in pairs(tes3.weather) do
			local weatherPath = WtSdir .. "\\" .. name
			for sky in lfs.dir(weatherPath) do
				if sky ~= ".." and sky ~= "." then
					local texturePath = weatherPath .. "\\" .. sky
					if string.endswith(sky, ".dds") or string.endswith(sky, ".tga") then
						table.insert(skyTextures[index + 1], texturePath)
						debugLog("File added: " .. texturePath)
					end
				end
			end
		end
	end

	-- Handle vanilla textures according to config
	if config.useVanillaSkyTextures then
		skyTexture.addVanillaTextures()
	else
		skyTexture.removeVanillaTextures()
	end

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
