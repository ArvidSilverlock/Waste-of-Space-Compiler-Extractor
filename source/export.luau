local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local EXTENSIONS = {
	client = ".client.luau",
	server = ".server.luau",
	other = ".luau",
}

local export = {}

local function isLuauSourceContainer(object: roblox.Instance)
	return object.ClassName == "ModuleScript" or object.ClassName == "Script" or object.ClassName == "LocalScript"
end

local function getExtension(object: roblox.Instance): string?
	if not isLuauSourceContainer(object) then
		return nil
	end

	return if object:IsA("LocalScript")
		then EXTENSIONS.client
		elseif object:IsA("Script") then EXTENSIONS.server
		else EXTENSIONS.other
end

local function readAllPathsInDirectory(basePath, fileMap: { [string]: string }, relativePath: string)
	local currentPath = `{basePath}/{relativePath}`

	for _, entry in (fs.readDir(currentPath)) do
		local relPath = `{relativePath}/{entry}`
		local fullPath = `{basePath}/{relPath}`

		if fs.isFile(fullPath) then
			fileMap[relPath] = fs.readFile(fullPath)
		elseif fs.isDir(fullPath) then
			readAllPathsInDirectory(basePath, fileMap, relPath)
		end
	end
end

function export.saveToPath(object: roblox.Instance, filePath: string)
	local children = object:GetChildren()
	local extension = getExtension(object)

	if extension then
		if #children > 0 then
			fs.writeDir(filePath)
			for _, child in children do
				export.saveToPath(child, `{filePath}/{child}`)
			end

			filePath ..= `/init{extension}`
		else
			filePath ..= extension
		end

		fs.writeFile(filePath, (object :: any).Source)
	elseif object:IsA("Folder") or object:IsA("Configuration") then
		fs.writeDir(filePath)
		for _, child in children do
			export.saveToPath(child, `{filePath}/{child}`)
		end
	else
		local serialisedModel = roblox.serializeModel({ object })
		fs.writeFile(`{filePath}.rbxmx`, serialisedModel)
	end
end

function export.compareDirectories(directoryA, directoryB)
	local mapA, mapB, allPaths = {}, {}, {}

	readAllPathsInDirectory(directoryA, mapA, "")
	readAllPathsInDirectory(directoryB, mapB, "")

	for path in mapA do
		allPaths[path] = true
	end
	for path in mapB do
		allPaths[path] = true
	end

	for path in allPaths do
		if mapA[path] ~= mapB[path] then
			return false
		end
	end

	return true
end

return export
