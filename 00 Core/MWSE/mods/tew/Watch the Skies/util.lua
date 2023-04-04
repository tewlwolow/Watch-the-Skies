local util = {}

function util.metadataMissing()
	tes3.messageBox{
		message = "Watch the Skies-metadata.toml file is missing. Please install."
	}
end

return util