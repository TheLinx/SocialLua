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

function client:login(username, token)
    local auth = {login = username, token = token}
    local s,d,h,c = social.get(full("user/show/%s", username), auth)
    if not s then return false,d end
    local t = json.decode(d)
    if c ~= 200 then
        return false,t.error[1].error
    else
        self.authed = true
        self.auth = auth
        self.username = username
        return true,t
    end
end
