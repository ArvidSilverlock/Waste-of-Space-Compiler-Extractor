local MB_TOOLS_PLUGIN_ID = 6724254977
local OLDEST_SUPPORTED_VERSION = 0 -- oldest model version with `Compilers` folder
local OUTPUT_DIRECTORY = "output"

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local export = require("./export")
local model = require("./model")
local output = require("./output")
local request = require("./request")

local function applyIndexToName(name: string, index)
	local newCompilerName, replacementCount = name:gsub("(%.%d+)([^%d]-)$", `%1.{index}%2`)
	if replacementCount == 0 then
		return `{name}-{index}`
	else
		return newCompilerName
	end
end

local function removeFile(path: string)
	if fs.isFile(path) then
		fs.removeFile(path)
	else
		fs.readDir(path)
	end
end

local apiKey = if #process.args > 0 then process.args[1] else stdio.prompt("text", "Roblox API key")

request.setApiKey(apiKey)
request.setAssetCacheName(MB_TOOLS_PLUGIN_ID, "mbtools")

local latestAssetVersion = request.getLatestAssetVersion(MB_TOOLS_PLUGIN_ID)

local duplicatedCompilerIndexes = {}

local overallStartTime = os.clock()

if fs.isDir(OUTPUT_DIRECTORY) then
	local outputRemoveStartTime = os.clock()
	removeFile(OUTPUT_DIRECTORY)
	local outputRemoveEndTime = os.clock()

	output
		.checkmark("It took ")
		.time(outputRemoveEndTime - outputRemoveStartTime)
		.write(" to ")
		.wrap("purple", "remove")
		.write(" existing output.\n\n")
else
	fs.writeDir(OUTPUT_DIRECTORY)
end

for index = OLDEST_SUPPORTED_VERSION, latestAssetVersion do
	local versionText = stdio.color("yellow") .. stdio.style("bold") .. "v" .. index .. stdio.style("reset")

	local modelRetrieveStartTime = os.clock()
	local modelSuccess, modelSource, didCache = request.retrieveRobloxModelSource(MB_TOOLS_PLUGIN_ID, index)
	local modelRetrieveEndTime = os.clock()

	if modelSuccess then
		output
			.checkmark("It took ")
			.time(modelRetrieveEndTime - modelRetrieveStartTime)
			.write(" to ")
			.wrap("cyan", "retrieve")
			.write(" model ", versionText, " from the ")
			.wrap("bold", if didCache then "cache" else "web")
			.write(".\n")
	else
		output
			.cross("Failed to retrieve model: ", versionText, ": ")
			.wrap("red", (modelSource:gsub("^%l+", string.lower)))
			.write(".\n\n")
		continue
	end

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
		output.cross("There are no easily accessible compilers for this version.\n\n")
		continue
	end

	for _, compiler in compilers do
		local compilerName = compiler.Name
		local outputPath

		local compilerNames = duplicatedCompilerIndexes[compilerName]
		if compilerNames then
			local newCompilerName = applyIndexToName(compilerName, #compilerNames)
			table.insert(compilerNames, { Object = compiler, Name = newCompilerName })
			outputPath = `{OUTPUT_DIRECTORY}/{newCompilerName}`
		else
			duplicatedCompilerIndexes[compilerName] = { { Object = compiler, Name = compilerName } }
			outputPath = `{OUTPUT_DIRECTORY}/{compilerName}`
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
			.wrap("bold", compiler.Name)
			.write(".\n")
	end

	output.write("\n")
end

local deduplicateStartTime = os.clock()
for compilerName, compilerGroup in duplicatedCompilerIndexes do
	local renamingOffset = 0

	local firstCompiler = compilerGroup[1]
	local directory = `{OUTPUT_DIRECTORY}/{export.getPath(firstCompiler.Object, firstCompiler.Name)}`

	for index = 2, #compilerGroup do
		local otherCompiler = compilerGroup[index]
		local otherCompilerObject = otherCompiler.Object
		local otherDirectory = `{OUTPUT_DIRECTORY}/{export.getPath(otherCompilerObject, otherCompiler.Name)}`

		if export.compare(directory, otherDirectory) then
			removeFile(otherDirectory)
			renamingOffset += 1
		elseif renamingOffset > 0 then
			local offsettedName = applyIndexToName(compilerName, index - renamingOffset)
			local targetDirectory = `{OUTPUT_DIRECTORY}/{export.getPath(otherCompilerObject, offsettedName)}`

			if not fs.isDir(targetDirectory) and not fs.isFile(targetDirectory) then
				fs.move(otherDirectory, targetDirectory)
				directory = targetDirectory
			else
				directory = otherDirectory
			end
		else
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
