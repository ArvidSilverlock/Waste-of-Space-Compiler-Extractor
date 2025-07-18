local MB_TOOLS_PLUGIN_ID = 6724254977
local OLDEST_SUPPORTED_VERSION = 36 -- oldest model version with `Compilers` folder
local OUTPUT_DIRECTORY = "output"

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local export = require("./export")
local model = require("./model")
local output = require("./output")
local request = require("./request")

local apiKey = if #process.args > 0 then process.args[1] else stdio.prompt("text", "Roblox API key")

request.setApiKey(apiKey)
request.setAssetCacheName(MB_TOOLS_PLUGIN_ID, "mbtools")

local latestAssetVersion = request.getLatestAssetVersion(MB_TOOLS_PLUGIN_ID)

local duplicatedCompilerIndexes = {}

local function applyIndexToName(name: string, index)
	local newCompilerName, replacementCount = name:gsub("(%.%d+)([^%d]-)$", `%1.{index}%2`)
	if replacementCount == 0 then
		return `{name}-{index}`
	else
		return newCompilerName
	end
end

local overallStartTime = os.clock()

if fs.isDir(OUTPUT_DIRECTORY) then
	local outputRemoveStartTime = os.clock()
	fs.removeDir(OUTPUT_DIRECTORY)
	local outputRemoveEndTime = os.clock()

	output
		.checkmark("It took ")
		.time(outputRemoveEndTime - outputRemoveStartTime)
		.write(" to ")
		.wrap("purple", "remove")
		.write(" existing output.\n\n")
end

for index = OLDEST_SUPPORTED_VERSION, latestAssetVersion do
	local versionText = stdio.color("yellow") .. stdio.style("bold") .. "v" .. index .. stdio.style("reset")

	local modelRetrieveStartTime = os.clock()
	local modelSource, didCache = request.retrieveRobloxModelSource(MB_TOOLS_PLUGIN_ID, index)
	local modelRetrieveEndTime = os.clock()

	output
		.checkmark("It took ")
		.time(modelRetrieveEndTime - modelRetrieveStartTime)
		.write(" to ")
		.wrap("cyan", "retrieve")
		.write(" model ", versionText, " from the ")
		.wrap("bold", if didCache then "cache" else "web")
		.write(".\n")

	local compilerRetrieveStartTime = os.clock()
	local compilers = model.getCompilersFromSource(modelSource)
	local compilerRetrieveEndTime = os.clock()

	output
		.checkmark("It took ")
		.time(compilerRetrieveEndTime - compilerRetrieveStartTime)
		.write(" to ")
		.wrap("red", "deserialise")
		.write(" model.\n")

	if not compilers then
		output.write("\n")
		continue
	end

	for _, compiler in compilers do
		local outputPath

		local compilerNames = duplicatedCompilerIndexes[compiler.Name]
		if compilerNames then
			local newCompilerName = applyIndexToName(compiler.Name, #compilerNames + 1)
			table.insert(compilerNames, newCompilerName)
			outputPath = `{OUTPUT_DIRECTORY}/{newCompilerName}`
		else
			duplicatedCompilerIndexes[compiler.Name] = {}
			outputPath = `{OUTPUT_DIRECTORY}/{compiler.Name}`
		end

		local compilerSaveStartTime = os.clock()
		export.saveToPath(compiler, outputPath)
		local compilerSaveEndTime = os.clock()

		output
			.checkmark("It took ")
			.time(compilerSaveEndTime - compilerSaveStartTime)
			.write(" to ")
			.wrap("green", "save")
			.write(" compiler ")
			.wrap("bold", "v", compiler.Name)
			.write(".\n")
	end

	output.write("\n")
end

local deduplicateStartTime = os.clock()
for compilerName, compilerGroup in duplicatedCompilerIndexes do
	local directory = `{OUTPUT_DIRECTORY}/{compilerName}`
	local offset = 0

	for index = 1, #compilerGroup do
		local otherDirectory = `{OUTPUT_DIRECTORY}/{compilerGroup[index]}`

		if export.compareDirectories(directory, otherDirectory) then
			fs.removeDir(otherDirectory)
			offset += 1
		else
			if offset > 0 then
				local offsettedName = applyIndexToName(compilerName, index - offset)
				local targetDirectory = `{OUTPUT_DIRECTORY}/{offsettedName}`

				if fs.isDir(targetDirectory) then
					fs.move(otherDirectory, targetDirectory)
				end
			end

			directory = otherDirectory
		end
	end
end
local deduplicateEndTime = os.clock()

output
	.checkmark("It took ")
	.time(deduplicateEndTime - deduplicateStartTime)
	.write(" to ")
	.wrap("purple", "deduplicate")
	.write(" compilers.\n\n")
	.wrap("green", "Process completed in ")
	.time(deduplicateEndTime - overallStartTime)
	.wrap("green", ".\n")
