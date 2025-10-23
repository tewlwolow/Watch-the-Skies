local events = {}

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog

events.services = {}

-- Helper function for registering/unregistering events with proper references
local function registerEvents(target, list)
	target._registeredEvents = {}
	for _, info in ipairs(list) do
		event.register(info.event, info.func, info.opts)
		table.insert(target._registeredEvents, info)
	end
end

local function unregisterEvents(target)
	if not target._registeredEvents then return end
	for _, info in ipairs(target._registeredEvents) do
		event.unregister(info.event, info.func, info.opts)
	end
	target._registeredEvents = nil
end

-- particleMesh
events.services.particleMesh = {
	init = function()
		debugLog("Initialising particleMesh service...")
		local particleMesh = require("tew.Watch the Skies.services.particleMesh")
		particleMesh.init()
		registerEvents(events.services.particleMesh, {
			{ event = tes3.event.weatherTransitionStarted,  func = particleMesh.particleMeshChecker, opts = { priority = -250 } },
			{ event = tes3.event.weatherTransitionFinished, func = particleMesh.particleMeshChecker, opts = { priority = -250 } },
			{ event = tes3.event.weatherChangedImmediate,   func = particleMesh.particleMeshChecker, opts = { priority = -250 } },
			{ event = tes3.event.loaded,                    func = particleMesh.particleMeshChecker, opts = { priority = -250 } },
			{ event = tes3.event.enterFrame,                func = particleMesh.reColourParticleMesh },
		})
		particleMesh.particleMeshChecker()
		debugLog("particleMesh service initialized.")
	end,
	stop = function()
		debugLog("Stopping particleMesh service...")
		unregisterEvents(events.services.particleMesh)
		debugLog("particleMesh service stopped.")
	end,
}

-- skyTexture
events.services.skyTexture = {
	init = function()
		debugLog("Initialising skyTexture service...")
		local skyTexture = require("tew.Watch the Skies.services.skyTexture")
		registerEvents(events.services.skyTexture, {
			{ event = tes3.event.loaded, func = skyTexture.startTimer },
		})
		skyTexture.init({ immediate = true })
		debugLog("skyTexture service initialized.")
	end,
	stop = function()
		debugLog("Stopping skyTexture service...")
		local skyTexture = require("tew.Watch the Skies.services.skyTexture")
		unregisterEvents(events.services.skyTexture)
		skyTexture.restoreDefaults()
		debugLog("skyTexture service stopped.")
	end,
}

-- dynamicWeatherChanges
events.services.dynamicWeatherChanges = {
	init = function()
		debugLog("Initialising dynamicWeatherChanges service...")
		local svc = require("tew.Watch the Skies.services.dynamicWeatherChanges")
		svc.init()
		registerEvents(events.services.dynamicWeatherChanges, {
			{ event = tes3.event.loaded, func = svc.startTimer },
		})
		debugLog("dynamicWeatherChanges service initialized.")
	end,
	stop = function()
		debugLog("Stopping dynamicWeatherChanges service...")
		local svc = require("tew.Watch the Skies.services.dynamicWeatherChanges")
		unregisterEvents(events.services.dynamicWeatherChanges)
		svc.restoreDefaults()
		debugLog("dynamicWeatherChanges service stopped.")
	end,
}

-- particleAmount
events.services.particleAmount = {
	init = function()
		debugLog("Initialising particleAmount service...")
		local svc = require("tew.Watch the Skies.services.particleAmount")
		svc.init()
		registerEvents(events.services.particleAmount, {
			{ event = tes3.event.loaded, func = svc.startTimer },
		})
		debugLog("particleAmount service initialized.")
	end,
	stop = function()
		debugLog("Stopping particleAmount service...")
		local svc = require("tew.Watch the Skies.services.particleAmount")
		unregisterEvents(events.services.particleAmount)
		svc.restoreDefaults()
		debugLog("particleAmount service stopped.")
	end,
}

-- cloudSpeed
events.services.cloudSpeed = {
	init = function()
		debugLog("Initialising cloudSpeed service...")
		local svc = require("tew.Watch the Skies.services.cloudSpeed")
		registerEvents(events.services.cloudSpeed, {
			{ event = tes3.event.loaded, func = svc.startTimer },
		})
		svc.init()
		debugLog("cloudSpeed service initialized.")
	end,
	stop = function()
		debugLog("Stopping cloudSpeed service...")
		local svc = require("tew.Watch the Skies.services.cloudSpeed")
		unregisterEvents(events.services.cloudSpeed)
		svc.restoreDefaults()
		debugLog("cloudSpeed service stopped.")
	end,
}

-- seasonalWeather
events.services.seasonalWeather = {
	init = function()
		debugLog("Initialising seasonalWeather service...")
		local svc = require("tew.Watch the Skies.services.seasonalWeather")
		registerEvents(events.services.seasonalWeather, {
			{ event = tes3.event.loaded, func = svc.startTimer },
		})
		svc.init()
		debugLog("seasonalWeather service initialized.")
	end,
	stop = function()
		debugLog("Stopping seasonalWeather service...")
		local svc = require("tew.Watch the Skies.services.seasonalWeather")
		unregisterEvents(events.services.seasonalWeather)
		svc.restoreDefaults()
		debugLog("seasonalWeather service stopped.")
	end,
}

-- seasonalDaytime
events.services.seasonalDaytime = {
	init = function()
		debugLog("Initialising seasonalDaytime service...")
		local svc = require("tew.Watch the Skies.services.seasonalDaytime")
		registerEvents(events.services.seasonalDaytime, {
			{ event = tes3.event.loaded, func = svc.startTimer },
		})
		svc.init()
		debugLog("seasonalDaytime service initialized.")
	end,
	stop = function()
		debugLog("Stopping seasonalDaytime service...")
		local svc = require("tew.Watch the Skies.services.seasonalDaytime")
		unregisterEvents(events.services.seasonalDaytime)
		svc.restoreDefaults()
		debugLog("seasonalDaytime service stopped.")
	end,
}

-- interiorTransitions
events.services.interiorTransitions = {
	init = function()
		debugLog("Initialising interiorTransitions service...")
		local svc = require("tew.Watch the Skies.services.interiorTransitions")
		registerEvents(events.services.interiorTransitions, {
			{ event = tes3.event.cellChanged, func = svc.onCellChanged, opts = { priority = -150 } },
		})
		svc.onCellChanged()
		debugLog("interiorTransitions service initialized.")
	end,
	stop = function()
		debugLog("Stopping interiorTransitions service...")
		local svc = require("tew.Watch the Skies.services.interiorTransitions")
		unregisterEvents(events.services.interiorTransitions)
		debugLog("interiorTransitions service stopped.")
	end,
}

-- variableFog
events.services.variableFog = {
	init = function()
		debugLog("Initialising variableFog service...")
		local svc = require("tew.Watch the Skies.services.variableFog")
		svc.restoreDefaults()
		registerEvents(events.services.variableFog, {
			{ event = tes3.event.weatherTransitionStarted,  func = svc.applyFogOnWeatherChange },
			{ event = tes3.event.weatherTransitionFinished, func = svc.applyFogOnWeatherChange },
			{ event = tes3.event.weatherChangedImmediate,   func = svc.applyFogOnWeatherChange },
		})
		debugLog("variableFog service initialized.")
	end,
	stop = function()
		debugLog("Stopping variableFog service...")
		local svc = require("tew.Watch the Skies.services.variableFog")
		unregisterEvents(events.services.variableFog)
		svc.restoreDefaults()
		debugLog("variableFog service stopped.")
	end,
}

-- weatherFlow
events.services.weatherFlow = {
	init = function()
		debugLog("Initialising weatherFlow service...")
		local wf = require("tew.Watch the Skies.services.weatherFlow")
		registerEvents(events.services.weatherFlow, {
			{ event = tes3.event.weatherTransitionStarted, func = wf.handleTransition,                     opts = { priority = -250 } },
			{ event = tes3.event.loaded,                   func = function() wf.transitionLock = false end },
		})
		debugLog("weatherFlow service initialized.")
	end,
	stop = function()
		debugLog("Stopping weatherFlow service...")
		unregisterEvents(events.services.weatherFlow)
		debugLog("weatherFlow service stopped.")
	end,
}

return events
