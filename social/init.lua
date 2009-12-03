local socket = require"socket" -- luarocks install luasocket

--- SocialLua
-- @author Bart van Strien (bart.bes@gmail.com)
-- @author Linus Sjögren (thelinxswe@gmail.com)
module("social", package.seeall) -- seeall for now

headers = {
	get = {
		anon = [[
GET %s HTTP/1.0
Host: %s

]],
		authb = [[
GET %s HTTP/1.0
Host: %s
Authorization: Basic %s

]],
	},
	post = {
		anon = [[
POST %s HTTP/1.0
Host: %s
Content-type: application/x-www-form-urlencoded
Content-length: %d

%s
]],
		authb = [[
POST %s HTTP/1.0
Host: %s
Authorization: Basic %s
Content-type: application/x-www-form-urlencoded
Content-length: %d

%s
]],
	},
}

--- Makes a request.
-- This functions formats a given string with given arguments and 
-- sends the data via the given socket. This is a back-end function.
-- @see get
-- @see post
-- @param soc Target socket.
-- @param header String (header) to format.
-- @param ... Extra arguments are passed to the format of the header.
-- @return The return values of the socket's receiving function.
function request(soc, header, ...)
    local d = string.format(header, ...)
    assert(soc:send(d))
    return soc:receive("*all")
end

--- Makes a GET request.
-- Automatically makes a GET request with the given data.
-- @see post
-- @param soc Target socket.
-- @param host Target hostname.
-- @param page Page/file to get.
-- @param auth (optional) a string that's passed to a basic authorization.
-- @return The return values of the socket's receiving function.
function get(soc, host, page, auth)
	if not auth then
		return request(soc, headers.get.anon, page, host)
	else
		return request(soc, headers.get.authb, page, host, auth)
	end
end

--- Makes a POST request.
-- Automatically makes a POST request with the given data.
-- @see get
-- @param soc Target socket.
-- @param host Target hostname.
-- @param page Page/file to post to.
-- @param data Data to send.
-- @param auth (optional) a string that's passed to a basic authorization.
-- @return The return values of the socket's receiving function.
function post(soc, host, page, data, auth)
	if not auth then
		return request(soc, headers.post.anon, page, host, #data, data)
	else
		return request(soc, headers.post.authb, page, host, auth, #data, data)
	end
end

--- Opens a connection to a website.
-- @param host Hostname of the website (without protocol!)
-- @param port (optional) assumes 80
function newconnection(host, port)
	local ip = assert(socket.dns.toip(host))
	local soc = assert(socket.tcp())
	assert(soc:connect(ip, port or 80))
	soc:settimeout(5)
	return soc
end

--- Removes the headers from received data.
-- @param data Data to format.
-- @return The formatted data.
function removeheaders(data)
	return data:match(".-\r\n\r\n(.*)")
end
