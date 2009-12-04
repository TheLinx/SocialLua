local tw = require"social.twitter"

io.write"Username: "
username = assert(io.read("*l"), "You must specify a username!")
io.write"Password: "
password = assert(io.read("*l"), "You must specify a password!")
io.write"Status: "
status = assert(io.read("*l"), "You must specify the status!")

io.write"Tweeting... " io.flush()
local s,m = tw.tweet(status, username, password)
if s == true then
	return print"success!"
else
	return print("failed! "..m)
end
