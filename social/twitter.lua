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

host = "twitter.com"

function full(p, ...)
	local s = "www"
	if p:sub(1,1) == "1" then
		s = "api"
	end
	return (string.format("http://%s.%s/%s.json", s, host, string.format(p, ...)))
end

function check(s,d,h,c)
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
	local s,d,h,c = social.get(full("account/verify_credentials"), nil, auth)
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
	local s,d,h,c = social.post(full("statuses/update"), {status = status}, self.auth)
end

--- Shows a tweet.
-- @param id ID
-- @return boolean Success or not
-- @return unsigned If success, the tweet, if fail, the error message.
function client:showStatus(id)
	local s,d,h,c = social.get(full("statuses/show/%s", id), nil, self.auth)
	return check(s,d,h,c)
end

--- Removes a tweet.
-- You must be logged in to remove tweets.
-- @param id ID
-- @return boolean Success or not
-- @return unsigned If success, the tweet, if fail, the error message.
function client:removeStatus(id)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("statuses/destroy/%s", id), nil, self.auth)
	return check(s,d,h,c)
end

--- Retweets a tweet.
-- You must be logged in to retweet.
-- @param id ID
-- @return boolean Success or not
-- @return unsigned If success, the resulting tweet, if fail, the error message.
function client:retweetStatus(id)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("1/statuses/retweet/%s", id), nil, self.auth)
	return check(s,d,h,c)
end

--- Lists retweets of a status.
-- You must be logged in to do this.
-- @param id Status ID
-- @return boolean Success or not
-- @return unsigned If success, the retweets, if fail, the error message.
function client:retweets(id)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/statuses/retweets/%s", id), nil, self.auth)
	return check(s,d,h,c)
end

--- Receives Twitter's public timeline
-- @return boolean Success or not
-- @return unsigned If success, the statuses, if fail, the error message.
function client:publicTimeline()
	local s,d,h,c = social.get(full("statuses/public_timeline"), nil, self.auth)
	return check(s,d,h,c)
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
	local s,d,h,c = social.get(full("1/statuses/home_timeline"), arg, self.auth)
	return check(s,d,h,c)
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
	local s,d,h,c = social.get(full("statuses/user_timeline/%s", id), arg, self.auth)
	return check(s,d,h,c)
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
	local s,d,h,c = social.get(full("statuses/friends_timeline"), arg, self.auth)
	return check(s,d,h,c)
end

--- Shows information about a user
-- @param id User ID or username (defaults to currently authenticated user)
-- @return boolean Success or not
-- @return unsigned If success, the user, if fail, the error message.
function client:showUser(id)
	local s,d,h,c = social.get(full("users/show/%s", (id or self.username)), nil, self.auth)
	return check(s,d,h,c)
end

--- Searches for a user.
-- You must be logged in to do this.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-users-search
-- @param query Search query.
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the results, if fail, the error message.
function client:searchUser(query, arg)
	if not self.authed then return false,"You must be logged in to do this!" end
	local arg = arg or {}
	arg.q = query
	local s,d,h,c = social.get(full("1/users/search"), arg, self.auth)
	return check(s,d,h,c)
end

--- Receive tweets where the user was mentioned.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-statuses-mentions
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the mentions, if fail, the error message.
function client:mentions(arg)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("statuses/mentions"), arg, self.auth)
	return check(s,d,h,c)
end

--- Receive retweets by the user.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-statuses-retweeted_by_me
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the statuses, if fail, the error message.
function client:retweetedByMe(arg)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/statuses/retweeted_by_me"), arg, self.auth)
	return check(s,d,h,c)
end

--- Receive retweets to the user.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-statuses-retweeted_to_me
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the statuses, if fail, the error message.
function client:retweetedToMe(arg)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/statuses/retweeted_to_me"), arg, self.auth)
	return check(s,d,h,c)
end

--- Receive retweets of the user.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-statuses-retweets_of_me
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the statuses, if fail, the error message.
function client:retweetsOfMe(arg)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/statuses/retweets_of_me"), arg, self.auth)
	return check(s,d,h,c)
end

--- Receive a user's friends.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-statuses friends
-- @param id User ID or username (defaults to currently authenticated user)
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the users, if fail, the error message.
function client:friends(id, arg)
	local s,d,h,c = social.get(full("statuses/friends/%s", (id or self.username)), arg, self.auth)
	return check(s,d,h,c)
end

--- Receive a user's followers.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-statuses followers
-- @param id User ID or username (defaults to currently authenticated user)
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the users, if fail, the error message.
function client:followers(id, arg)
	local s,d,h,c = social.get(full("statuses/followers/%s", (id or self.username)), arg, self.auth)
	return check(s,d,h,c)
end

--- Creates a list.
-- @param name Name of the list.
-- @param mode (optional) Public or private -- it's public by default
-- @param description (optional) Description
-- @return boolean Success or not.
-- @return unsigned If success, the new list, if fail, the error message.
function client:createList(name, mode, description)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("1/%s/lists", self.username), {name = name, mode = mode, description = description}, self.auth)
	return check(s,d,h,c)
end

--- Edits a list.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-POST-lists-id
-- @param name Name of the list to be edited.
-- @param new Table with the new information.
-- @return boolean Success or not.
-- @return unsigned If success, the new list, if fail, the error message.
function client:editList(name, new)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("1/%s/lists/%s", self.username, name), new, self.auth)
	return check(s,d,h,c)
end

--- Receives a user's lists.
-- @param user Username (defaults to currently authed user)
-- @param cursor (optional) for pagination
-- @return boolean Success or not.
-- @return unsigned If success, the lists, if fail, the error message.
function client:userLists(user, cursor)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/%s/lists", user or self.username), {cursor = cursor}, self.auth)
	return check(s,d,h,c)
end

--- Receives a list.
-- @param user Owner of the list.
-- @param name Name of the list.
-- @return boolean Success or not.
-- @return unsigned If success, the list, if fail, the error message.
function client:list(user, name)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/%s/lists/%s", user, name), nil, self.auth)
	return check(s,d,h,c)
end

--- Deletes a list.
-- @param name Name of the list.
-- @return boolean Success or not.
-- @return unsigned If success, the list, if fail, the error message.
function client:deleteList(name)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.delete(full("1/%s/lists/%s", self.username, name), nil, self.auth)
	return check(s,d,h,c)
end

--- Receives tweets from a list.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-GET-list-statuses
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the statuses, if fail, the error message.
function client:listTweets(name, user, arg)
	local s,d,h,c = social.get(full("1/%s/lists/%s/statuses", user or self.username, name), arg, self.auth)
	return check(s,d,h,c)
end

--- Checks what lists a user is in.
-- You must be logged in to do this.
-- @param user Target user. Defaults to the currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the lists, if fail, the error message.
function client:userInLists(user, cursor)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/%s/lists/memberships", user or self.username), {cursor = cursor}, self.auth)
	return check(s,d,h,c)
end

--- Checks what lists a user is following.
-- You must be logged in to do this.
-- @param user Target user. Defaults to the currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, lists, if fail, the error message.
function client:userFollowingLists(user, cursor)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/%s/lists/subscriptions", user or self.username), {cursor = cursor}, self.auth)
	return check(s,d,h,c)
end

--- Receives users in a list.
-- You must be logged in to do this.
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the users, if fail, the error message.
function client:usersInList(name, user, cursor)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/%s/%s/members", user or self.username, name), {cursor = cursor}, self.auth)
	return check(s,d,h,c)
end

--- Adds a user to a list.
-- You must be logged in to do this.
-- @param id User ID or username.
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @return boolean Success or not.
-- @return unsigned If success, the list, if fail, the error message.
function client:addUserToList(id, name, user)
	if not self.authed then return false,"You must be logged in to do this!" end
	if type(id) == "string" then
		local _,t = self:showUser(id)
		id = t.id
	end
	local s,d,h,c = social.post(full("1/%s/%s/members", user or self.username, name), {id = id}, self.auth)
	return check(s,d,h,c)
end

--- Removes a user from a list.
-- You must be logged in to do this.
-- @param id User ID or username.
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @return boolean Success or not.
-- @return unsigned If success, the list, if fail, the error message.
function client:removeUserFromList(id, name, user)
	if not self.authed then return false,"You must be logged in to do this!" end
	if type(id) == "string" then
		local _,t = self:showUser(id)
		id = t.id
	end
	local s,d,h,c = social.delete(full("1/%s/%s/members", user or self.username, name), {id = id}, self.auth)
	return check(s,d,h,c)
end

--- Checks if a user is in a list.
-- You must be logged in to do this.
-- @param id User ID or username.
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @return boolean Success or not.
-- @return unsigned If success, the users, if fail, the error message.
function client:userInList(id, name, user)
	if not self.authed then return false,"You must be logged in to do this!" end
	if type(id) == "string" then
		local b,t = self:showUser(id)
		if not b then return false,t end
		id = t.id
	end
	local s,d,h,c = social.get(full("1/%s/%s/members/%s", user or self.username, name, id), nil, self.auth)
	return check(s,d,h,c)
end

--- Receives subscribers of a list.
-- You must be logged in to do this.
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the users, if fail, the error message.
function client:usersFollowingList(name, user, cursor)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("1/%s/%s/subscribers", user or self.username, name), {cursor = cursor}, self.auth)
	return check(s,d,h,c)
end

--- Subscribes to a list.
-- You must be logged in to do this.
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @return boolean Success or not.
-- @return unsigned If success, the list, if fail, the error message.
function client:followList(name, user)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("1/%s/%s/subscribers", user or self.username, name), nil, self.auth)
	return check(s,d,h,c)
end

--- Unsubscribes from a list.
-- You must be logged in to do this.
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @return boolean Success or not.
-- @return unsigned If success, the list, if fail, the error message.
function client:unfollowList(name, user)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.delete(full("1/%s/%s/subscribers", user or self.username, name), nil, self.auth)
	return check(s,d,h,c)
end

--- Checks if a user is subscribing to a list.
-- You must be logged in to do this.
-- @param id User ID or username.
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:userFollowingList(id, name, user)
	if not self.authed then return false,"You must be logged in to do this!" end
	if type(id) == "string" then
		local b,t = self:showUser(id)
		if not b then return false,t end
		id = t.id
	end
	local s,d,h,c = social.get(full("1/%s/%s/subscribers/%s", user or self.username, name, id), nil, self.auth)
	return check(s,d,h,c)
end

--- Retrieves a list of direct messages to the authed user.
-- You must be logged in to do this.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-direct_messages
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the messages, if fail, the error message.
function client:directMessages(arg)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("direct_messages"), arg, self.auth)
	return check(s,d,h,c)
end

--- Retrieves a list of direct messages from the authed user.
-- You must be logged in to do this.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-direct_messages sent
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the messages, if fail, the error message.
function client:sentDirectMessages(arg)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("direct_messages/sent"), arg, self.auth)
	return check(s,d,h,c)
end

--- Deletes a direct message.
-- You must be logged in to do this.
-- @param id Message ID.
-- @return boolean Success or not.
-- @return unsigned If success, the messages, if fail, the error message.
function client:deleteDirectMessage(id)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("direct_messages/destroy/%s", id), nil, self.auth)
	return check(s,d,h,c)
end

--- Unfollows a user.
-- You must be logged in to do this.
-- @param user User ID or username.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:unfollow(user)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("friendships/destroy/%s", user), nil, self.auth)
	return check(s,d,h,c)
end

--- Checks if a user is following another user.
-- @param usera Is this user...
-- @param userb ...following this user?
-- @return boolean Success or not.
-- @return unsigned If success, a boolean, if fail, the error message.
function client:isFollowing(usera, userb)
	local s,d,h,c = social.get(full("friendships/exists"), {user_a = usera, user_b = userb}, self.auth)
	return check(s,d,h,c)
end

--- Receives information about a friendship.
-- @param target User ID or username.
-- @param source User ID or username. Defaults to authed user.
-- @return boolean Success or not.
-- @return unsigned If success, the info, if fail, the error message.
function client:showFriendship(target, source)
	local arg = {}
	if tonumber(target) then
		arg.target_id = target
	else
		arg.target_screen_name = target
	end
	if tonumber(source) then
		arg.source_id = source
	elseif source then
		arg.source_screen_name = source
	end
	local s,d,h,c = social.get(full("friendships/show"), arg, self.auth)
	return check(s,d,h,c)
end

--- Receives a list of IDs that a user is following.
-- @param user User ID or username. Defaults to currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the ids, if fail, the error message.
function client:following(user, cursor)
	local s,d,h,c = social.get(full("friends/ids/%s", user or self.username), {cursor = cursor}, self.auth)
	return check(s,d,h,c)
end

--- Receives a list of IDs that is following the user.
-- @param user User ID or username. Defaults to currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the ids, if fail, the error message.
function client:followers(user, cursor)
	local s,d,h,c = social.get(full("followers/ids/%s", user or self.username), {cursor = cursor}, self.auth)
	return check(s,d,h,c)
end

--- Changes fields on the user's profile.
-- You must be logged in to do this.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-account update_profile
-- @param new New info.
-- @return boolean Success or not.
-- @return unsigned If success, the new profile, if fail, the error message.
function client:updateProfile(new)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("account/update_profile"), new, self.auth)
	return check(s,d,h,c)
end

--- Changes colors on the user's profile.
-- You must be logged in to do this.
-- For information on what arguments you can use: http://apiwiki.twitter.com/Twitter-REST-API-Method:-account update_profile_colors
-- @param new New info.
-- @return boolean Success or not.
-- @return unsigned If success, the new profile, if fail, the error message.
function client:updateProfileColors(new)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("account/update_profile_colors"), new, self.auth)
	return check(s,d,h,c)
end

--- Receives a list of that user's favorite tweets.
-- You must be logged in to do this.
-- @param user User ID or username. Defaults to currently authed user.
-- @param page Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the ids, if fail, the error message.
function client:favorites(user, page)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("favorites/%s", user or self.username), {page = page}, self.auth)
	return check(s,d,h,c)
end

--- Favorites a tweet.
-- You must be logged in to do this.
-- @param id Status ID.
-- @return boolean Success or not.
-- @return unsigned If success, the status, if fail, the error message.
function client:addFavorite(id)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("favorites/create/%s", id), nil, self.auth)
	return check(s,d,h,c)
end

--- Removes a favorite tweet.
-- You must be logged in to do this.
-- @param id Status ID.
-- @return boolean Success or not.
-- @return unsigned If success, the status, if fail, the error message.
function client:removeFavorite(id)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("favorites/destroy/%s", id), nil, self.auth)
	return check(s,d,h,c)
end

--- Enables notifications for a user.
-- You must be logged in to do this.
-- @param user User ID or username.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:followDevice(user)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("notifications/follow/%s", user), nil, self.auth)
	return check(s,d,h,c)
end

--- Disables notifications for a user.
-- You must be logged in to do this.
-- @param user User ID or username.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:unfollowDevice(user)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("notifications/leave/%s", user), nil, self.auth)
	return check(s,d,h,c)
end

--- Blocks a user.
-- You must be logged in to do this.
-- @param user User ID or username.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:block(user)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("blocks/create/%s", user), nil, self.auth)
	return check(s,d,h,c)
end

--- Unblocks a user.
-- You must be logged in to do this.
-- @param user User ID or username.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:unblock(user)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("blocks/destroy/%s", user), nil, self.auth)
	return check(s,d,h,c)
end

--- Checks if the authed user is blocking another user.
-- You must be logged in to do this.
-- @param user User ID or username.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:isBlocking(user)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("blocks/exists/%s", user), nil, self.auth)
	return check(s,d,h,c)
end

--- Receives a list of users that the authed user is blocking.
-- You must be logged in to do this.
-- @param page Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:blocking(page)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("blocks/blocking"), {page = page}, self.auth)
	return check(s,d,h,c)
end

--- Receives a list of ids that the authed user is blocking.
-- You must be logged in to do this.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:blockingIds()
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("blocks/blocking/ids"), nil, self.auth)
	return check(s,d,h,c)
end

--- Blocks a user and reports as a spammer.
-- You must be logged in to do this.
-- @param user User ID or username.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:reportSpam(user)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("report_spam"), {id = user}, self.auth)
	return check(s,d,h,c)
end

--- Receives a list of a user's saved searches.
-- You must be logged in to do this.
-- @return boolean Success or not.
-- @return unsigned If success, the searches, if fail, the error message.
function client:savedSearches()
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("saved_searches"), nil, self.auth)
	return check(s,d,h,c)
end

--- Receives info about a user's saved search.
-- You must be logged in to do this.
-- @param id ID of the saved search.
-- @return boolean Success or not.
-- @return unsigned If success, the search, if fail, the error message.
function client:savedSearch(id)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.get(full("saved_searches/show/%s", id), nil, self.auth)
	return check(s,d,h,c)
end

--- Saves a search.
-- You must be logged in to do this.
-- @param query Search query to save.
-- @return boolean Success or not.
-- @return unsigned If success, the search, if fail, the error message.
function client:addSavedSearch(query)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("saved_searches/create"), {query = query}, self.auth)
	return check(s,d,h,c)
end

--- Removes a saved search.
-- You must be logged in to do this.
-- @param id ID of the saved search.
-- @return boolean Success or not.
-- @return unsigned If success, the search, if fail, the error message.
function client:deleteSavedSearch(id)
	if not self.authed then return false,"You must be logged in to do this!" end
	local s,d,h,c = social.post(full("saved_searches/destroy/%s", id), nil, self.auth)
	return check(s,d,h,c)
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

--- A simple function to follow a user.
-- @param user Username to follow.
-- @param username Username to login as.
-- @param password Password of the user.
-- @return boolean Success or not
-- @return unsigned If fail, the error message. If success, nil.
-- @see client:follow
function follow(user, username, password)
	local cl = client:new()
	local s,m = cl:login(username, password)
	if not s then return false,m end
	local s,m = cl:follow(user)
	if not s then return false,m end
	return true
end

--- A simple function to unfollow a user.
-- @param user Username to unfollow.
-- @param username Username to login as.
-- @param password Password of the user.
-- @return boolean Success or not
-- @return unsigned If fail, the error message. If success, nil.
-- @see client:unfollow
function unfollow(user, username, password)
	local cl = client:new()
	local s,m = cl:login(username, password)
	if not s then return false,m end
	local s,m = cl:unfollow(user)
	if not s then return false,m end
	return true
end
