local tw = require"social.twitter"

io.write"Username: "
username = assert(io.read("*l"), "You must specify a username!")
io.write"Password: "
password = assert(io.read("*l"), "You must specify a password!")
io.write"Status: "
status = assert(io.read("*l"), "You must specify the status!")

io.write"Tweeting... "
print((tw.tweet(status, username, password) and "success!") or "failed!")
