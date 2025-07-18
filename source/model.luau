local roblox = require("@lune/roblox")

local output = require("./output")

local model = {}

function model.getRobloxModel(source: string): roblox.Instance?
	local modelSource = assert(source, "model request failed")
	local deserialisedModel = roblox.deserializeModel(modelSource)

	if #deserialisedModel == 0 then
		output.error("ZERO_INSTANCES")
	elseif #deserialisedModel > 1 then
		return nil
	end

	return deserialisedModel[1]
end

function model.getCompilers(pluginModel: roblox.Instance): { roblox.Instance }?
	local compilersFolder = pluginModel:FindFirstChild("Compilers")
	if not compilersFolder then
		return nil
	end

	local compilers = (compilersFolder :: roblox.Instance):GetChildren()
	if not compilers then
		output.error("NO_COMPILERS")
	end

	return compilers
end

function model.getCompilersFromSource(source: string): { roblox.Instance }?
	local modelRootInstance = model.getRobloxModel(source)
	if not modelRootInstance then
		return nil
	end

	return model.getCompilers(modelRootInstance)
end

return model
