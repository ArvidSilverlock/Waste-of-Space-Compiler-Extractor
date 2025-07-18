local cache = {}

local CACHE_DIRECTORY = "cache/"

local fs = require("@lune/fs")

local function addCacheDirectory()
	if not fs.isDir(CACHE_DIRECTORY) then
		fs.writeDir(CACHE_DIRECTORY)
	end
end

local function isValidKey(key: string): (boolean, string?)
	if key:find("/") then
		return false, "there cannot be a forward slash in a cache key"
	else
		return true, nil
	end
end

function cache.set(key: string?, value: string)
	if key then
		assert(isValidKey(key))

		addCacheDirectory()
		fs.writeFile(CACHE_DIRECTORY .. key, value)
	end
end

function cache.get(key: string?): string?
	if not key then
		return nil
	end

	assert(isValidKey(key))

	local path = CACHE_DIRECTORY .. key
	if fs.isFile(path) then
		return fs.readFile(path)
	else
		return nil
	end
end

function cache.clear() end

return cache
