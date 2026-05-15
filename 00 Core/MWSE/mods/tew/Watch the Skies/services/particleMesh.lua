local particleMesh     = {}

--------------------------------------------------------------------------------------

local common           = require("tew.Watch the Skies.components.common")
local util             = require("tew.Watch the Skies.util")
local debugLog         = common.debugLog
local WtC              = tes3.worldController.weatherController
local newParticleMesh
local particleNode
local swapQueue        = nil
local swapIndex        = 1
local particlesPath    = "Data Files\\Meshes\\tew\\Watch the Skies\\particles"
local meshRoot         = "tew\\Watch the Skies\\particles"

--------------------------------------------------------------------------------------

local SNOW_POINT       = 0.2
local RAIN_POINT       = 0.1

local particles        = {
	["rain"] = {},
	["snow"] = {},
}

local weatherChecklist = {
	["Rain"] = "rain",
	["Thunderstorm"] = "rain",
	["Snow"] = "snow",
}

--------------------------------------------------------------------------------------

function particleMesh.init()
	for particleTypeFolder in lfs.dir(particlesPath) do
		if particleTypeFolder and particleTypeFolder ~= ".." and particleTypeFolder ~= "." then
			for particle in lfs.dir(particlesPath .. "\\" .. particleTypeFolder) do
				if particle and particle ~= ".." and particle ~= "." and string.endswith(particle:lower(), ".nif") then
					particleMesh = tes3.loadMesh(
						meshRoot
						.. "\\"
						.. particleTypeFolder
						.. "\\"
						.. particle
					)
					table.insert(particles[particleTypeFolder], particleMesh)
				end
			end
		end
	end
end

local function getBleachedColour(comp, point)
	return math.clamp(math.lerp(comp, 1.0, point), 0.03, 0.88)
end

local function getModifiedColour(weatherColour)
	local colours
	if (WtC.currentWeather.name) == "Snow" or (WtC.nextWeather and WtC.nextWeather.name == "Snow") then
		colours = {
			r = getBleachedColour(weatherColour.r, SNOW_POINT),
			g = getBleachedColour(weatherColour.g, SNOW_POINT),
			b = getBleachedColour(weatherColour.b, SNOW_POINT),
		}
	else
		colours = {
			r = getBleachedColour(weatherColour.r, RAIN_POINT),
			g = getBleachedColour(weatherColour.g, RAIN_POINT),
			b = getBleachedColour(weatherColour.b, RAIN_POINT),
		}
	end
	return colours
end

local function isValidWeather()
	local current = WtC.currentWeather.name
	local nextW = WtC.nextWeather and WtC.nextWeather.name

	return
		(current == "Rain"
			or current == "Thunderstorm"
			or current == "Snow")
		and
		((not nextW)
			or nextW == "Rain"
			or nextW == "Thunderstorm"
			or nextW == "Snow")
end

-- Change particle mesh colours in real-time --
local frameCounter = 0

local lastColours = {
	r = -1,
	g = -1,
	b = -1,
}

function particleMesh.reColourParticleMesh()
	frameCounter = frameCounter + 1

	if frameCounter < 4 then
		return
	end

	frameCounter = 0

	if not isValidWeather()
		or not newParticleMesh
	then
		return
	end

	local weatherColour = WtC.currentFogColor
	local colours = getModifiedColour(weatherColour)

	if math.abs(colours.r - lastColours.r) < 0.005
		and math.abs(colours.g - lastColours.g) < 0.005
		and math.abs(colours.b - lastColours.b) < 0.005
	then
		return
	end

	lastColours.r = colours.r
	lastColours.g = colours.g
	lastColours.b = colours.b

	if not particleNode then
		particleNode = newParticleMesh:getObjectByName("tew_particle")
	end

	if particleNode then
		local materialProperty = particleNode.materialProperty

		if materialProperty then
			materialProperty.emissive = colours
			materialProperty.specular = colours
			materialProperty.diffuse = colours
			materialProperty.ambient = colours
		end
	end
end

local function swapNode(particle)
	local old = particle.object
	particle.rainRoot:detachChild(old)

	local new = newParticleMesh:clone()
	particle.rainRoot:attachChild(new)
	new.appCulled = old.appCulled

	particle.object = new
end

--------------------------------------------------------------------------------------

local BATCH_SIZE = 20

local function processSwapQueue()
	if not swapQueue then
		event.unregister(tes3.event.enterFrame, processSwapQueue)
		return
	end

	local processed = 0

	while processed < BATCH_SIZE
		and swapIndex <= #swapQueue
	do
		swapNode(swapQueue[swapIndex])

		swapIndex = swapIndex + 1
		processed = processed + 1
	end

	-- Queue finished
	if swapIndex > #swapQueue then
		if WtC.sceneRainRoot then
			WtC.sceneRainRoot:updateEffects()
		end

		event.unregister(tes3.event.enterFrame, processSwapQueue)

		swapQueue = nil
		swapIndex = 1
	end
end

local function changeParticleMesh(particleType)
	event.unregister(tes3.event.enterFrame, processSwapQueue)

	local particleList = particles[particleType]

	if not particleList or #particleList == 0 then
		debugLog(
			"No particle meshes found for "
			.. tostring(particleType)
		)

		return
	end

	local randomParticleMesh = table.choice(particles[particleType])
	newParticleMesh = randomParticleMesh:clone()

	particleNode = nil
	lastColours.r = -1
	lastColours.g = -1
	lastColours.b = -1

	swapQueue = {}
	swapIndex = 1

	local particleTables = {
		WtC.particlesActive,
		WtC.particlesInactive,
	}

	for _, particleTable in pairs(particleTables) do
		for _, particle in pairs(particleTable) do
			table.insert(swapQueue, particle)
		end
	end

	event.register(tes3.event.enterFrame, processSwapQueue)

	util.updateController()
	WtC.sceneRainRoot:updateEffects()

	debugLog(
		"Rain mesh changed."
		.. " (batched swap, "
		.. #swapQueue
		.. " particles)"
	)
end

-- Check if we have the weather that warrants particle change --
function particleMesh.particleMeshChecker()
	local weatherNow = WtC.nextWeather and WtC.nextWeather or WtC.currentWeather
	local particleWeatherType = weatherChecklist[weatherNow.name]
	if particleWeatherType ~= nil then
		changeParticleMesh(particleWeatherType)
	end
end

--------------------------------------------------------------------------------------

return particleMesh
