local social = require"social"
--------------------------------
local url = require"socket.url" -- luarocks install luasocket

local string = string
local assert,type = assert,type

--- SocialLua - u.nu module.
-- @author Linus Sjögren (thelinxswe@gmail.com)
module("social.unu")

--- Shortens a URL with the u.nu service.
-- @param u Input URL
function shorten(u)
	assert(type(u) == "string", "bad argument #1 to 'shorten' (string expected, got "..type(u)..")")
	local s,d = social.get("http://u.nu/unu-api-simple", {url = u})
	if not s then return false,d end
	d = d:gsub("\n", "")
	if d:find("|") then
		return nil,d:sub(d:find("|")+1)
	end
	return d
end
