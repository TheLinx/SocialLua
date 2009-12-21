local social = require"social"
--------------------------------
local mime = require"mime" -- luarocks install luasocket
local url = require"socket.url" --             luasocket
local json = require"json" --                  json4lua

--- SocialLua - GitHub module.
-- This module does not work at all as of yet.
-- @author Linus Sjögren (thelinx@unreliablepollution.net)
module("social.github", package.seeall) -- seeall for now

function full(page, ...)
    return "https://github.com/api/v2/json/"..string.format(page, ...)
end

client = {}
local cl_mt = { __index = client }

--- Creates a new GitHub client
function client:new()
    return setmetatable({authed = false}, cl_mt)
end

function cl_mt:__tostring()
    if self.authed then
        return "GitHub client, authed as "..self.username.." ("..self.token..")"
    else
        return "GitHub client, not authed"
    end
end

--- Flushes account data from client.
function client:logout()
    self.authed = false
    self.auth = nil
    self.username = nil
    self.token = nil
    self.user = t
end

--- Attempts authetication with GitHub.
-- @param username Username
-- @param token API token
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the user.
function client:login(username, token)
    local auth = {login = username, token = token}
    local s,d,h,c = social.get(full("user/show/%s", username), auth)
    if not s then return false,d end
    local t = json.decode(d)
    if c ~= 200 then
        self:logout()
        return false,t.error[1].error
    elseif t.user.plan then -- only returned if correctly authed
        self.authed = true
        self.auth = auth
        self.username = username
        self.token = token
        self.user = t
        return true,t
    else
        self:logout()
        return false,"failed to authorize"
    end
end
