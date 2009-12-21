local social = require"social"
--------------------------------
local mime = require"mime" -- luarocks install luasocket
local url = require"socket.url" --             luasocket
local json = require"json" --                  json4lua

local string = string
local setmetatable,tonumber,type,tonumber,assert = setmetatable,tonumber,type,tonumber,assert

--- SocialLua - Last.FM module.
-- @author Linus Sjögren (thelinxswe@gmail.com)
module("social.lastfm")

local function check(s,d,h,c)
    if not s then return false,d end
    local t = json.decode(d)
    if c ~= 200 then
        return false,t.error
    else
        return true,t
    end
end

client = {}
local cl_mt = { __index = client }

--- Creates a new Last.FM client.
function client.new(apikey)
    return setmetatable({authed = false,apikey = assert(apikey, "you need an api key!")}, cl_mt)
end

function cl_mt:__tostring()
    if self.authed then
        return "Last.FM client, authed as "..self.username.." ("..self.auth..")"
    else
        return "Last.FM client, not authed"
    end
end

function client:get(url, data, auth)
    data.format = "json"
    data.api_key = self.apikey
    return social.get(url, data, auth)
end

function client:userInfo(user)
    local s,d,h,c = self:get("http://ws.audioscrobbler.com/2.0/", {user = user, method = "user.getinfo"})
    return check(s,d,h,c)
end
