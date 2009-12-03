local social = require"social"
--------------------------------
local mime = require"mime" -- luarocks install luasocket
local url = require"socket.url" --             luasocket
local json = require"json" --                  json4lua

--- SocialLua - Twitter module
-- @author Bart van Strien (bart.bes@gmail.com)
-- @author Linus Sjögren (thelinxswe@gmail.com)
module("social.twitter", package.seeall) -- seeall for now

host = "www.twitter.com"

function full(p)
	return "http://"..host.."/"..p..".json"
end

client = {}
local cl_mt = { __index = client }

function client:new()
	return setmetatable({authed = false}, cl_mt)
end

function cl_mt:__tostring()
	if self.authed then
		return "Twitter client, authed as "..self.username.." ("..self.auth..")"
	else
		return "Twitter client, not authed"
	end
end
function client:login(username, password)
	local auth = social.authbasic(username, password)
	local d,h,c = assert(social.get(full("account/verify_credentials"), auth))
	local t = json.decode(d)
	if c == 401 then
		self:logout()
		return false,t.error,h
	elseif c == 200 then
		self.authed = true
		self.auth = auth
		self.username = username
		self.user = t
		return true,t
	else
		error("Unexpected response (got code "..c..", expected 200 or 401")
	end
end

function client:logout()
	self.authed = false
	self.auth = nil
	self.username = nil
	self.user = nil
end

function client:tweet(status)
	assert(self.authed, "You must be logged in to tweet!")
	local d = assert(social.post(full("statuses/update"), "status="..url.escape(status), self.auth))
	local t = json.decode(d)
	if t.error then
		return false,t.error
	else
		return true,t
	end
end

-- simple functions

function tweet(status, username, password)
	local cl = client:new()
	if not cl:login(username, password) then return false end
	if not cl:tweet(status) then return false end
	return true
end
