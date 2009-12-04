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

--- Creates a new Twitter client.
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

--- Flushes account info from client.
function client:logout()
	self.authed = false
	self.auth = nil
	self.username = nil
	self.user = nil
end

--- Attempts authentication with Twitter.
-- @param username Username to login with
-- @param password Password of the user
-- @return boolean Success or not
-- @return unsigned If success, the signed in user. If fail, the error message.
function client:login(username, password)
	local auth = social.authbasic(username, password)
	local s,d,h,c = social.get(full("account/verify_credentials"), auth)
	if not s then return false,d end
	local t = json.decode(d)
	if c ~= 200 then
		self:logout()
		return false,t.error
	else
		self.authed = true
		self.auth = auth
		self.username = username
		self.user = t
		return true,t
	end
end

--- Tweets.
-- Note that you must be logged in to tweet.
-- @param status Message to tweet.
-- @return boolean Success or not
-- @return unsigned If success, the new user info. If fail, the error message.
function client:tweet(status)
	if not self.authed then return false,"You must be logged in to tweet!" end
	local s,d,h,c = social.post(full("statuses/update"), "status="..url.escape(status), self.auth)
	if not s then return false,d end
	local t = json.decode(d)
	if c ~= 200 then
		return false,t.error
	else
		self.user = t
		return true,t
	end
end

--[[------------ simple functions --------------]]--

--- A simple function to tweet.
-- @param status Message to tweet.
-- @param username Username to tweet as.
-- @param password Password of the user.
-- @return boolean Success or not
function tweet(status, username, password)
	local cl = client:new()
	local s,m = cl:login(username, password)
	if not s then return false,m end
	local s,m = cl:tweet(status)
	if not s then return false,m end
	return true
end
