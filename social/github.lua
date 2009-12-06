local social = require"social"
--------------------------------
local mime = require"mime" -- luarocks install luasocket
local url = require"socket.url" --             luasocket
local json = require"json" --                  json4lua

--- SocialLua - GitHub module.
-- This module does not work at all as of yet.
-- @author Linus Sjögren (thelinx@unreliablepollution.net)
module("social.github", package.seeall) -- seeall for now

function full(page)
	return "https://github.com/api/v2/json/"..page
end

client = {}
local cl_mt = { __index = client }

--- Creates a new GitHub client
function client:new()
	return setmetatable({authed = false}, cl_mt)
end

function client:login(username, token)
	self.authed = true
	self.auth = {login = username, token = token}
	self.username = username
end
