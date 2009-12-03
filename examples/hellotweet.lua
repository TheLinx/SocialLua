local tw = require"social.twitter"

io.write"Username: "
username = assert(io.read("*l"), "You must specify a username!")
io.write"Password: "
password = assert(io.read("*l"), "You must specify a password!")

print((tw.tweet("Hello World from SocialLua!", username, password) and "Tweeted!") or "Failed!")
