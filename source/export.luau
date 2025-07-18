local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

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

local function splitPath(string: string): (string, string, string)
	local path, fileName, extension = string:match("^(.-)([^/]-)(%.[^/%.]+)$")
	return path :: string, fileName :: string, extension :: string
end

local function readAllPaths(basePath, fileMap: { [string]: string }, relativePath: string?)
	local currentPath = if relativePath then `{basePath}/{relativePath}` else basePath

	if fs.isFile(currentPath) then
		fileMap[currentPath] = fs.readFile(currentPath)
	elseif fs.isDir(currentPath) then
		for _, entry in fs.readDir(currentPath) do
			local relPath = if relativePath then `{relativePath}/{entry}` else entry
			local fullPath = `{basePath}/{relPath}`

			if fs.isFile(fullPath) then
				fileMap[relPath] = fs.readFile(fullPath)
			elseif fs.isDir(fullPath) then
				readAllPaths(basePath, fileMap, relPath)
			end
		end
	end
end

function export.getPath(object: roblox.Instance, nameReplacement: string?)
	local extension = if #object:GetChildren() == 0 then getExtension(object) else ""
	local name = nameReplacement or object.Name

	return if extension then name .. extension else name
end

function export.saveToPath(object: roblox.Instance, filePath: string)
	local children = object:GetChildren()
	local extension = getExtension(object)

	if extension then
		if #children > 0 then
			fs.writeDir(filePath)
			for _, child in children do
				export.saveToPath(child, `{filePath}/{child.Name}`)
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

function export.compare(pathA, pathB)
	if fs.isFile(pathA) and fs.isFile(pathB) then
		return fs.readFile(pathA) == fs.readFile(pathB)
	elseif fs.isFile(pathA) ~= fs.isFile(pathB) then
		return false
	elseif fs.isDir(pathA) ~= fs.isDir(pathB) then
		return false
	end

	local mapA, mapB, allPaths = {}, {}, {}

	readAllPaths(pathA, mapA)
	readAllPaths(pathB, mapB)

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
