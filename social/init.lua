local http = require"socket.http" -- luarocks install luasocket
local mime = require"mime" --                         luasocket
local url = require"socket.url" --                    luasocket
local ltn12 = require"ltn12" --                       luasocket

local table = table

--- SocialLua
-- @author Bart van Strien (bart.bes@gmail.com)
-- @author Linus Sjögren (thelinxswe@gmail.com)
module("social")

--- Makes a request.
-- This is a back-end function.
-- @see get
-- @see post
function request(method, url, auth, data)
	local out = {}
    local r,c,h = http.request{
		url = url,
		method = method:upper(),
		headers = { authorization = (auth and "Basic "..auth), ["content-type"] = (data and "application/x-www-form-urlencoded"), ["content-length"] = (data and #data) },
		source = ltn12.source.string(data),
		sink = ltn12.sink.table(out)
	}
	if c == 301 or c == 302 then
		return request(method, h.location, headers, data)
	end
	return ((r and true) or false),table.concat(out),h,c
end

--- Makes a GET request.
-- Automatically makes a GET request with the given data.
-- @see post
function get(url, auth)
	local r,d,h,c = request("get", url, auth)
	if not r then
		return false,h.status
	end
	return true,d,h,c
end

--- Makes a POST request.
-- Automatically makes a POST request with the given data.
-- @see get
function post(url, data, auth)
	local r,d,h,c = request("post", url, auth, data)
	if not r then
		return false,h.status
	end
	return true,d,h,c
end

--- Generates a Basic authentication string.
-- @param username Username
-- @param password Password
-- @return The Basic authentication string.
function authbasic(username, password)
	return mime.b64(username..":"..password)
end
