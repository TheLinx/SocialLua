local social = require"social"
--------------------------------
local mime = require"mime" -- luarocks install luasocket
local url = require"socket.url" --             luasocket
local json = require"json" --                  json4lua

--- SocialLua - Twitter module.
-- Note: This module is in alpha and functions may change name without prior notice.
-- @author Bart van Strien (bart.bes@gmail.com)
-- @author Linus Sjögren (thelinxswe@gmail.com)
module("social.twitter", package.seeall) -- seeall for now

host = ".twitter.com"

function full(p,s,a)
	return "http://"..(s or "www")..host.."/"..p..".json"..social.tabletoget(a or {})
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
-- @see client:login
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
-- @see client:logout
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
-- @see tweet
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

--- Shows a tweet.
-- @param id ID
-- @return boolean Success or not
-- @return unsigned If success, the tweet, if fail, the error message.
function client:showStatus(id)
	local s,d,h,c = social.get(full("statuses/show/"..id), self.auth)
	if not s then return false,d end
	local t = json.decode(d)
	if c ~= 200 then
		return false,t.error
	else
		return true,t
	end
end

--- Removes a tweet.
-- You must be logged in to remove tweets.
-- @param id ID
-- @return boolean Success or not
-- @return unsigned If success, the tweet, if fail, the error message.
function client:removeStatus(id)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("statuses/destroy/"..id), "", self.auth)
	if not s then return false,d end
	local t = json.decode(d)
	if c ~= 200 then
		return false,t.error
	else
		return true,t
	end
end

--- Retweets a tweet.
-- You must be logged in to retweet.
-- @param id ID
-- @return boolean Success or not
-- @return unsigned If success, the resulting tweet, if fail, the error message.
function client:retweetStatus(id)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("1/statuses/retweet/"..id, "api"), "", self.auth)
	if not s then return false,d end
	local t = json.decode(d)
	if c ~= 200 then
		return false,t.error
	else
		return true,t
	end
end

--- Lists retweets of the status.
-- You must be logged in to do this.
-- @param id ID
-- @return boolean Success or not
-- @return unsigned If success, the retweets, if fail, the error message.
function client:retweets(id)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/statuses/retweets/"..id, "api"), self.auth)
	if not s then return false,d end
	local t = json.decode(d)
	if c ~= 200 then
		return false,t.error
	else
		return true,t
	end
end

--- Receives Twitter's public timeline
-- @return boolean Success or not
-- @return unsigned If success, the statuses, if fail, the error message.
function client:publicTimeline()
	local s,d,h,c = social.get(full("statuses/public_timeline"), self.auth)
	if not s then return false,d end
	local t = json.decode(d)
	if c ~= 200 then
		return false,t.error
	else
		return true,t
	end
end

--- Receives the user's home timeline.
-- You must be logged in to do this.
-- The function will use an argument table if supplied, but remember, you 
-- can also supply the arguments in the call: homeTimeline{since_id = 412}
-- For more info on what arguments there are, visit
-- http://apiwiki.twitter.com/Twitter-REST-API-Method:-statuses-home_timeline
-- @param arg (optional) A table containing the arguments for the request
-- @return boolean Success or not
-- @return unsigned If success, the statuses, if fail, the error message.
function client:homeTimeline(arg)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/statuses/home_timeline", "api", arg or {}), self.auth)
	if not s then return false,d end
	local t = json.decode(d)
	if c ~= 200 then
		return false,t.error
	else
		return true,t
	end
end

--- Receives a user's timeline.
-- The function will use an argument table if supplied, but remember, you 
-- can also supply the arguments in the call: userTimeline{since_id = 412}
-- For more info on what arguments there are, visit
-- http://apiwiki.twitter.com/Twitter-REST-API-Method:-statuses-user_timeline
-- @param arg (optional) A table containing the arguments for the request
-- @return boolean Success or not
-- @return unsigned If success, the statuses, if fail, the error message.
function client:userTimeline(id, arg)
	local s,d,h,c = social.get(full("statuses/user_timeline/"..id, nil, arg or {}), self.auth)
	if not s then return false,d end
	local t = json.decode(d)
	if c ~= 200 then
		return false,t.error
	else
		return true,t
	end
end

--- Receives the user's friends timeline.
-- You must be logged in to do this.
-- The function will use an argument table if supplied, but remember, you 
-- can also supply the arguments in the call: friendsTimeline{since_id = 412}
-- For more info on what arguments there are, visit
-- http://apiwiki.twitter.com/Twitter-REST-API-Method:-statuses-friends_timeline
-- @param arg (optional) A table containing the arguments for the request
-- @return boolean Success or not
-- @return unsigned If success, the statuses, if fail, the error message.
function client:friendsTimeline(arg)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("statuses/friends_timeline", nil, arg or {}), self.auth)
	if not s then return false,d end
	local t = json.decode(d)
	if c ~= 200 then
		return false,t.error
	else
		return true,t
	end
end

--[[------------ simple functions --------------]]--

--- A simple function to tweet.
-- @param status Message to tweet.
-- @param username Username to tweet as.
-- @param password Password of the user.
-- @return boolean Success or not
-- @see client:tweet
function tweet(status, username, password)
	local cl = client:new()
	local s,m = cl:login(username, password)
	if not s then return false,m end
	local s,m = cl:tweet(status)
	if not s then return false,m end
	return true
end