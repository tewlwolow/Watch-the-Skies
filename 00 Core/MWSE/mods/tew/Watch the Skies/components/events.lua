local config = require("tew.Watch the Skies.config")

local services = {
	particleMesh = {
		init = function()
			local particleMesh = require("tew.Watch the Skies.services.particleMesh")
			particleMesh.init()
			event.register(tes3.event.weatherTransitionStarted, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.weatherTransitionFinished, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.weatherChangedImmediate, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.loaded, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.enterFrame, particleMesh.reColourParticleMesh)
			particleMesh.particleMeshChecker()
		end,
		stop = function()
			local particleMesh = require("tew.Watch the Skies.services.particleMesh")
			event.unregister(tes3.event.weatherTransitionStarted, particleMesh.particleMeshChecker, { priority = -250 })
			event.unregister(tes3.event.weatherTransitionFinished, particleMesh.particleMeshChecker, { priority = -250 })
			event.unregister(tes3.event.weatherChangedImmediate, particleMesh.particleMeshChecker, { priority = -250 })
			event.unregister(tes3.event.loaded, particleMesh.particleMeshChecker, { priority = -250 })
			event.unregister(tes3.event.enterFrame, particleMesh.reColourParticleMesh)
		end,
	},

	skyTexture = {
		init = function()
			local skyTexture = require("tew.Watch the Skies.services.skyTexture")
			skyTexture.init()
			event.register(tes3.event.loaded, skyTexture.startTimer)
			skyTexture.init({ immediate = true })
		end,
		stop = function()
			local skyTexture = require("tew.Watch the Skies.services.skyTexture")
			event.unregister(tes3.event.loaded, skyTexture.startTimer)
			skyTexture.restoreDefaults()
		end,
	},

	dynamicWeatherChanges = {
		init = function()
			local dynamicWeatherChanges = require("tew.Watch the Skies.services.dynamicWeatherChanges")
			dynamicWeatherChanges.init()
			event.register(tes3.event.loaded, dynamicWeatherChanges.startTimer)
			dynamicWeatherChanges.init()
		end,
		stop = function()
			local dynamicWeatherChanges = require("tew.Watch the Skies.services.dynamicWeatherChanges")
			event.unregister(tes3.event.loaded, dynamicWeatherChanges.startTimer)
			dynamicWeatherChanges.restoreDefaults()
		end,
	},

	particleAmount = {
		init = function()
			local particleAmount = require("tew.Watch the Skies.services.particleAmount")
			particleAmount.init()
			event.register(tes3.event.loaded, particleAmount.startTimer)
			particleAmount.init()
		end,
		stop = function()
			local particleAmount = require("tew.Watch the Skies.services.particleAmount")
			event.unregister(tes3.event.loaded, particleAmount.startTimer)
			particleAmount.restoreDefaults()
		end,
	},

	cloudSpeed = {
		init = function()
			local cloudSpeed = require("tew.Watch the Skies.services.cloudSpeed")
			event.register(tes3.event.loaded, cloudSpeed.startTimer)
			cloudSpeed.init()
		end,
		stop = function()
			local cloudSpeed = require("tew.Watch the Skies.services.cloudSpeed")
			event.unregister(tes3.event.loaded, cloudSpeed.startTimer)
			cloudSpeed.restoreDefaults()
		end,
	},

	seasonalWeather = {
		init = function()
			local seasonalWeather = require("tew.Watch the Skies.services.seasonalWeather")
			event.register(tes3.event.loaded, seasonalWeather.startTimer)
			seasonalWeather.init()
		end,
		stop = function()
			local seasonalWeather = require("tew.Watch the Skies.services.seasonalWeather")
			event.unregister(tes3.event.loaded, seasonalWeather.startTimer)
			seasonalWeather.restoreDefaults()
		end,
	},

	seasonalDaytime = {
		init = function()
			local seasonalDaytime = require("tew.Watch the Skies.services.seasonalDaytime")
			event.register(tes3.event.loaded, seasonalDaytime.startTimer)
			seasonalDaytime.init()
		end,
		stop = function()
			local seasonalDaytime = require("tew.Watch the Skies.services.seasonalDaytime")
			event.unregister(tes3.event.loaded, seasonalDaytime.startTimer)
			seasonalDaytime.restoreDefaults()
		end,
	},

	interiorTransitions = {
		init = function()
			local interiorTransitions = require("tew.Watch the Skies.services.interiorTransitions")
			event.register(tes3.event.cellChanged, interiorTransitions.onCellChanged, { priority = -150 })
			interiorTransitions.onCellChanged()
		end,
		stop = function()
			local interiorTransitions = require("tew.Watch the Skies.services.interiorTransitions")
			event.unregister(tes3.event.cellChanged, interiorTransitions.onCellChanged, { priority = -150 })
		end,
	},
}

for serviceName, service in pairs(services) do
	if config.modEnabled then
		if config[serviceName] then
			service.stop()
			service.init()
		else
			service.stop()
		end
	else
		service.stop()
	end
end
