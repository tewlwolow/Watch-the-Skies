local customSkyColour = {}

--------------------------------------------------------------------------------------

local WtC = tes3.worldController.weatherController

--------------------------------------------------------------------------------------

function customSkyColour.calculate()
	mge.weather.setFarScattering{far = WtC.currentSkyColor, mix = 0.9}
end

function customSkyColour.startTimer()
	timer.start {
		duration = 0.001,
		callback = customSkyColour.calculate,
		type = timer.game,
		iterations = -1
	}
end

--------------------------------------------------------------------------------------

return customSkyColour