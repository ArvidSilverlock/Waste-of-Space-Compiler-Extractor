local RETRIEVE_ASSET_LINK = "https://apis.roblox.com/asset-delivery-api/v1/assetId/%d"
local RETRIEVE_VERSIONED_ASSET_LINK = "https://apis.roblox.com/asset-delivery-api/v1/assetId/%d/version/%d"
local RETRIEVE_ASSET_DATA = "https://apis.roblox.com/assets/v1/assets/%d"

local net = require("@lune/net")
local serde = require("@lune/serde")

local cache = require("./cache")

local apiKeyHeader
local assetNameMap = {}

local function getCacheKey(assetId: number, version: number?): string?
	return if version
		then if assetNameMap[assetId]
			then `{assetNameMap[assetId]}-v{version}.rbxmx`
			else `asset-{assetId}-v{version}.rbxmx`
		else nil
end

local request = {}

function request.setAssetCacheName(assetId: number, name: string?)
	assetNameMap[assetId] = name
end

function request.setApiKey(newApiKey: string)
	apiKeyHeader = { ["x-api-key"] = newApiKey }
end

function request.request(url: string, method: net.HttpMethod)
	assert(apiKeyHeader, "no api key set")

	return net.request({
		url = url,
		method = method,
		headers = apiKeyHeader,
	})
end

function request.retrieveRobloxModelSource(assetId: number, version: number?): (boolean, string, boolean)
	local cacheKey = getCacheKey(assetId, version)

	local cached = cache.get(cacheKey)
	if cached then
		return true, cached, true
	end

	local initialRequest = if version
		then request.request(RETRIEVE_VERSIONED_ASSET_LINK:format(assetId, version), "GET")
		else request.request(RETRIEVE_ASSET_LINK:format(assetId), "GET")
	local decodedResponse = serde.decode("json", initialRequest.body)

	if decodedResponse.errors and #decodedResponse.errors > 0 then
		return false, decodedResponse.errors[1].message, false
	end

	local modelString = net.request({
		url = decodedResponse.location,
		method = "GET",
	}).body

	cache.set(cacheKey, modelString)

	return true, modelString, false
end

function request.getLatestAssetVersion(assetId: number): number
	local assetDataResponse = request.request(RETRIEVE_ASSET_DATA:format(assetId), "GET")
	local assetDataBody = serde.decode("json", assetDataResponse.body)

	return assetDataBody.revisionId
end

return request
