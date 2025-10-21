local events = {}

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog

events.services = {
	particleMesh = {
		init = function()
			debugLog("Initializing particleMesh service...")
			local particleMesh = require("tew.Watch the Skies.services.particleMesh")
			particleMesh.init()
			event.register(tes3.event.weatherTransitionStarted, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.weatherTransitionFinished, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.weatherChangedImmediate, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.loaded, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.enterFrame, particleMesh.reColourParticleMesh)
			particleMesh.particleMeshChecker()
			debugLog("particleMesh service initialized.")
		end,
		stop = function()
			debugLog("Stopping particleMesh service...")
			local particleMesh = require("tew.Watch the Skies.services.particleMesh")
			event.unregister(tes3.event.weatherTransitionStarted, particleMesh.particleMeshChecker, { priority = -250 })
			event.unregister(tes3.event.weatherTransitionFinished, particleMesh.particleMeshChecker, { priority = -250 })
			event.unregister(tes3.event.weatherChangedImmediate, particleMesh.particleMeshChecker, { priority = -250 })
			event.unregister(tes3.event.loaded, particleMesh.particleMeshChecker, { priority = -250 })
			event.unregister(tes3.event.enterFrame, particleMesh.reColourParticleMesh)
			debugLog("particleMesh service stopped.")
		end,
	},

	skyTexture = {
		init = function()
			debugLog("Initializing skyTexture service...")
			local skyTexture = require("tew.Watch the Skies.services.skyTexture")
			event.register(tes3.event.loaded, skyTexture.startTimer)
			skyTexture.init({ immediate = true })
			debugLog("skyTexture service initialized.")
		end,
		stop = function()
			debugLog("Stopping skyTexture service...")
			local skyTexture = require("tew.Watch the Skies.services.skyTexture")
			event.unregister(tes3.event.loaded, skyTexture.startTimer)
			skyTexture.restoreDefaults()
			debugLog("skyTexture service stopped.")
		end,
	},

	dynamicWeatherChanges = {
		init = function()
			debugLog("Initializing dynamicWeatherChanges service...")
			local dynamicWeatherChanges = require("tew.Watch the Skies.services.dynamicWeatherChanges")
			dynamicWeatherChanges.init()
			event.register(tes3.event.loaded, dynamicWeatherChanges.startTimer)
			dynamicWeatherChanges.init()
			debugLog("dynamicWeatherChanges service initialized.")
		end,
		stop = function()
			debugLog("Stopping dynamicWeatherChanges service...")
			local dynamicWeatherChanges = require("tew.Watch the Skies.services.dynamicWeatherChanges")
			event.unregister(tes3.event.loaded, dynamicWeatherChanges.startTimer)
			dynamicWeatherChanges.restoreDefaults()
			debugLog("dynamicWeatherChanges service stopped.")
		end,
	},

	particleAmount = {
		init = function()
			debugLog("Initializing particleAmount service...")
			local particleAmount = require("tew.Watch the Skies.services.particleAmount")
			particleAmount.init()
			event.register(tes3.event.loaded, particleAmount.startTimer)
			particleAmount.init()
			debugLog("particleAmount service initialized.")
		end,
		stop = function()
			debugLog("Stopping particleAmount service...")
			local particleAmount = require("tew.Watch the Skies.services.particleAmount")
			event.unregister(tes3.event.loaded, particleAmount.startTimer)
			particleAmount.restoreDefaults()
			debugLog("particleAmount service stopped.")
		end,
	},

	cloudSpeed = {
		init = function()
			debugLog("Initializing cloudSpeed service...")
			local cloudSpeed = require("tew.Watch the Skies.services.cloudSpeed")
			event.register(tes3.event.loaded, cloudSpeed.startTimer)
			cloudSpeed.init()
			debugLog("cloudSpeed service initialized.")
		end,
		stop = function()
			debugLog("Stopping cloudSpeed service...")
			local cloudSpeed = require("tew.Watch the Skies.services.cloudSpeed")
			event.unregister(tes3.event.loaded, cloudSpeed.startTimer)
			cloudSpeed.restoreDefaults()
			debugLog("cloudSpeed service stopped.")
		end,
	},

	seasonalWeather = {
		init = function()
			debugLog("Initializing seasonalWeather service...")
			local seasonalWeather = require("tew.Watch the Skies.services.seasonalWeather")
			event.register(tes3.event.loaded, seasonalWeather.startTimer)
			seasonalWeather.init()
			debugLog("seasonalWeather service initialized.")
		end,
		stop = function()
			debugLog("Stopping seasonalWeather service...")
			local seasonalWeather = require("tew.Watch the Skies.services.seasonalWeather")
			event.unregister(tes3.event.loaded, seasonalWeather.startTimer)
			seasonalWeather.restoreDefaults()
			debugLog("seasonalWeather service stopped.")
		end,
	},

	seasonalDaytime = {
		init = function()
			debugLog("Initializing seasonalDaytime service...")
			local seasonalDaytime = require("tew.Watch the Skies.services.seasonalDaytime")
			event.register(tes3.event.loaded, seasonalDaytime.startTimer)
			seasonalDaytime.init()
			debugLog("seasonalDaytime service initialized.")
		end,
		stop = function()
			debugLog("Stopping seasonalDaytime service...")
			local seasonalDaytime = require("tew.Watch the Skies.services.seasonalDaytime")
			event.unregister(tes3.event.loaded, seasonalDaytime.startTimer)
			seasonalDaytime.restoreDefaults()
			debugLog("seasonalDaytime service stopped.")
		end,
	},

	interiorTransitions = {
		init = function()
			debugLog("Initializing interiorTransitions service...")
			local interiorTransitions = require("tew.Watch the Skies.services.interiorTransitions")
			event.register(tes3.event.cellChanged, interiorTransitions.onCellChanged, { priority = -150 })
			interiorTransitions.onCellChanged()
			debugLog("interiorTransitions service initialized.")
		end,
		stop = function()
			debugLog("Stopping interiorTransitions service...")
			local interiorTransitions = require("tew.Watch the Skies.services.interiorTransitions")
			event.unregister(tes3.event.cellChanged, interiorTransitions.onCellChanged, { priority = -150 })
			debugLog("interiorTransitions service stopped.")
		end,
	},

	skyShaderController = {
		init = function()
			debugLog("Initializing skyShaderController service...")
			local skyShaderController = require("tew.Watch the Skies.services.skyShaderController")
			event.register(tes3.event.cellChanged, skyShaderController.switch)
			event.register(tes3.event.weatherTransitionStarted, skyShaderController.switch)
			event.register(tes3.event.weatherTransitionFinished, skyShaderController.switch)
			event.register(tes3.event.weatherChangedImmediate, skyShaderController.switch)
			event.register(tes3.event.loaded, skyShaderController.modShaderOn)
			skyShaderController.switch()
			debugLog("skyShaderController service initialized.")
		end,
		stop = function()
			debugLog("Stopping skyShaderController service...")
			local skyShaderController = require("tew.Watch the Skies.services.skyShaderController")
			event.unregister(tes3.event.cellChanged, skyShaderController.switch)
			event.unregister(tes3.event.weatherTransitionStarted, skyShaderController.switch)
			event.unregister(tes3.event.weatherTransitionFinished, skyShaderController.switch)
			event.unregister(tes3.event.weatherChangedImmediate, skyShaderController.switch)
			event.unregister(tes3.event.loaded, skyShaderController.modShaderOn)
			skyShaderController.modShaderOn()
			debugLog("skyShaderController service stopped.")
		end,
	},

	variableFog = {
		init = function()
			debugLog("Initializing variableFog service...")
			local variableFog = require("tew.Watch the Skies.services.variableFog")
			variableFog.storeDefaults()
			event.register(tes3.event.simulate, function(e) variableFog.oscillate(e.delta) end)
			debugLog("variableFog service initialized.")
		end,
		stop = function()
			debugLog("Stopping variableFog service...")
			local variableFog = require("tew.Watch the Skies.services.variableFog")
			event.unregister(tes3.event.simulate, function(e) variableFog.oscillate(e.delta) end)
			variableFog.restoreDefaults()
			debugLog("variableFog service stopped.")
		end,
	},
}

return events
