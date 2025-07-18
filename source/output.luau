local process = require("@lune/process")
local stdio = require("@lune/stdio")

local CHECK_MARK = stdio.color("green") .. "✔" .. stdio.color("reset")
local CROSS = stdio.color("red") .. "✗" .. stdio.color("reset")

local MICROSECOND_FORMAT =
	string.format("%s%%.2f %sµs%s", stdio.color("green"), stdio.style("dim"), stdio.color("reset"))
local MILLISECOND_FORMAT =
	string.format("%s%%.2f %sms%s", stdio.color("green"), stdio.style("dim"), stdio.color("reset"))
local SECOND_FORMAT = string.format("%s%%.2f %ss%s", stdio.color("yellow"), stdio.style("dim"), stdio.color("reset"))
local MINUTE_FORMAT = string.format(
	"%s%%d %smin%s %s%%.2f %ss%s",
	stdio.color("red"),
	stdio.style("dim"),
	stdio.style("reset"),
	stdio.color("red"),
	stdio.style("dim"),
	stdio.color("reset")
)

local ERROR_MESSAGES = {
	STRUCTURE_CHANGED = "The structure of MBTools seems to have changed, this tool does not support this new format.\n",
	ZERO_INSTANCES = "The retrieved roblox model file has no instances.\n",
	NO_COMPILERS = "There are no compilers in this version of MBTools\n",
}

-- export type Error = keyof<typeof(ERROR_MESSAGES)>
export type Error = "STRUCTURE_CHANGED" | "ZERO_INSTANCES" | "NO_COMPILERS"

local output = {}

function output.write(...: any)
	for index = 1, select("#", ...) do
		local text = tostring(select(index, ...))
		stdio.write(text)
	end
	return output
end

function output.wrap(format: stdio.Color | stdio.Style, ...: any)
	local escapeCode = if format == "bold" or format == "dim" then stdio.style(format) else stdio.color(format)
	output.write(escapeCode, ...)
	output.write(stdio.color("reset"))
	return output
end

function output.error(errorType: Error): never
	stdio.ewrite(stdio.color("red") .. ERROR_MESSAGES[errorType] .. stdio.color("reset"))
	process.exit()

	error("") -- this never runs, but it makes luau happy
end

function output.checkmark(...: any)
	output.write(CHECK_MARK, " ", ...)
	return output
end

function output.cross(...: any)
	output.write(CROSS, " ", ...)
	return output
end

function output.time(seconds: number)
	stdio.write(
		if seconds < 0.001
			then string.format(MICROSECOND_FORMAT, seconds * 1e6)
			elseif seconds < 1 then string.format(MILLISECOND_FORMAT, seconds * 1e3)
			elseif seconds < 60 then string.format(SECOND_FORMAT, seconds)
			else string.format(MINUTE_FORMAT, seconds // 60, seconds % 60)
	)
	return output
end

return output
