-- name_restrictions mod by ShadowNinja
-- License: WTFPL

---------------------
-- Simple matching --
---------------------

local disallowed = {
	["^guest[0-9]+"] = "Guest accounts are disallowed on this server.  "..
	                   "Please choose a proper username and try again.",
	["adm[1il]n"]    = "Misleading nickname.",
	["[0o]wn[e3]r"]  = "Misleading nickname.",
	["^[0-9]+$"]     = "All-numeric usernames are disallowed on this server.",
}

minetest.register_on_prejoinplayer(function(name, ip)
	local lname = name:lower()
	for re, reason in pairs(disallowed) do
		if lname:find(re) then
			return reason
		end
	end
end)


------------------------
-- Case-insensitivity --
------------------------

minetest.register_on_prejoinplayer(function(name, ip)
	local lname = name:lower()
	for iname, data in pairs(minetest.auth_table) do
		if iname:lower() == lname and iname ~= name then
			return "Sorry, someone else is already using this"
				.." name.  Please pick another name."
				.."  Annother posibility is that you used the"
				.." wrong case for your name."
		end
	end
end)

-- Compatability, for old servers with conflicting players
minetest.register_chatcommand("choosecase", {
	description = "Choose the casing that a player name should have.",
	params = "<name>",
	privs = {server=true},
	func = function(name, params)
		local lname = params:lower()
		local worldpath = minetest.get_worldpath()
		for iname, data in pairs(minetest.auth_table) do
			if iname:lower() == lname and iname ~= params then
				minetest.auth_table[iname] = nil
				assert(not iname:find("[/\\]"))
				os.remove(worldpath.."/players/"..iname)
			end
		end
		return true, "Done."
	end,
})


------------------------
-- Anti-impersonation --
------------------------
-- Prevents names that are too similar to annother player's name.

local similar_chars = {
	-- Only A-Z, a-z, 1-9, dash, and underscore are allowed in playernames
	"A4",
	"B8"
	"COco0",
	"Ee3",
	"Gg69",
	"ILil1",
	"S5",
	"Tt7",
	"Zz2",
}

-- Map of characters to a regex of similar characters
local char_map = {}
for _, str in pairs(similar_chars) do
	for c in str:gmatch(".") do
		if not char_map[c] then
			char_map[c] = str
		else
			char_map[c] = char_map[c] .. str
		end
	end
end

for c, str in pairs(char_map) do
	char_map[c] = "[" .. char_map[c] .."]"
end

-- Characters to match for, containing all characters
local all_chars = "["
for _, str in pairs(similar_chars) do
	all_chars = all_chars .. str
end
all_chars = all_chars .. "]"


minetest.register_on_prejoinplayer(function(name, ip)
	local re = name:gsub(all_chars, char_map)
	re = "^[_-]*" .. re .. "[_-]*$"
	for authName, _ in pairs(minetest.auth_table) do
		if authName ~= name and authName:match(re) then
			return "Your name is too similar to annother player's name."
		end
	end
end)


