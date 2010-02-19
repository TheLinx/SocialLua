local social = require"social"
--------------------------------
local mime = require"mime" -- luarocks install luasocket
local url = require"socket.url" --             luasocket
local json = require"json" --                  json4lua

local string = string
local setmetatable,tonumber,type,tonumber = setmetatable,tonumber,type,tonumber

--- SocialLua - Twitter module.
-- @author Linus Sjögren (thelinxswe@gmail.com)
module("social.twitter")
-- TODO: Change return order.
-- TODO: Search API functions.

host = "twitter.com"

local function full(p, ...)
    local s = "api"
    if not tonumber(p:sub(1,1)) then
        s = "search"
    end
    return (string.format("http://%s.%s/1/%s.json", s, host, string.format(p, ...)))
end

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

--[[---------- TIMELINE METHODS ------------]]--

--- Receives Twitter's public timeline
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-public_timeline
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
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-home_timeline
-- @param arg (optional) A table containing the arguments for the request
-- @return boolean Success or not
-- @return unsigned If success, the statuses, if fail, the error message.
function client:homeTimeline(arg)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("statuses/home_timeline"), arg, self.auth)
    return check(s,d,h,c)
end

--- Receives the user's friends timeline.
-- You must be logged in to do this.
-- The function will use an argument table if supplied, but remember, you 
-- can also supply the arguments in the call: friendsTimeline{since_id = 412}
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-friends_timeline
-- @param arg (optional) A table containing the arguments for the request
-- @return boolean Success or not
-- @return unsigned If success, the statuses, if fail, the error message.
function client:friendsTimeline(arg)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("statuses/friends_timeline"), arg, self.auth)
    return check(s,d,h,c)
end

--- Receives a user's timeline.
-- The function will use an argument table if supplied, but remember, you 
-- can also supply the arguments in the call: userTimeline(id, {since_id = 412})
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-user_timeline
-- @param arg (optional) A table containing the arguments for the request
-- @return boolean Success or not
-- @return unsigned If success, the statuses, if fail, the error message.
function client:userTimeline(id, arg)
    local s,d,h,c = social.get(full("statuses/user_timeline/%s", id), arg, self.auth)
    return check(s,d,h,c)
end

--- Receive tweets where the user was mentioned.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-mentions
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the mentions, if fail, the error message.
function client:mentions(arg)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("statuses/mentions"), arg, self.auth)
    return check(s,d,h,c)
end

--- Receive retweets by the user.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweeted_by_me
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the statuses, if fail, the error message.
function client:retweetedByMe(arg)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("statuses/retweeted_by_me"), arg, self.auth)
    return check(s,d,h,c)
end

--- Receive retweets to the user.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweeted_to_me
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the statuses, if fail, the error message.
function client:retweetedToMe(arg)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("statuses/retweeted_to_me"), arg, self.auth)
    return check(s,d,h,c)
end

--- Receive retweets of the user.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweets_of_me
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the statuses, if fail, the error message.
function client:retweetsOfMe(arg)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("statuses/retweets_of_me"), arg, self.auth)
    return check(s,d,h,c)
end

--[[---------- STATUS METHODS ------------]]--

--- Shows a tweet.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0show
-- @param id ID
-- @return boolean Success or not
-- @return unsigned If success, the tweet, if fail, the error message.
function client:showStatus(id)
    local s,d,h,c = social.get(full("statuses/show/%s", id), nil, self.auth)
    return check(s,d,h,c)
end

--- Tweets.
-- Note that you must be logged in to tweet.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0update
-- @param status Message to tweet.
-- @return boolean Success or not
-- @return unsigned If success, the new user info. If fail, the error message.
-- @see tweet
function client:tweet(status)
    if not self.authed then return false,"You must be logged in to tweet!" end
    local s,d,h,c = social.post(full("statuses/update"), {status = status}, self.auth)
    return check(s,d,h,c)
end

--- Removes a tweet.
-- You must be logged in to remove tweets.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0destroy
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
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweet
-- @param id ID
-- @return boolean Success or not
-- @return unsigned If success, the resulting tweet, if fail, the error message.
function client:retweetStatus(id)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("statuses/retweet/%s", id), nil, self.auth)
    return check(s,d,h,c)
end

--- Lists retweets of a status.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweets
-- @param id Status ID
-- @return boolean Success or not
-- @return unsigned If success, the retweets, if fail, the error message.
function client:retweets(id)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("statuses/retweets/%s", id), nil, self.auth)
    return check(s,d,h,c)
end

--[[---------- USER METHODS ------------]]--

--- Shows information about a user
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-users%C2%A0show
-- @param id User ID or username (defaults to currently authenticated user)
-- @return boolean Success or not
-- @return unsigned If success, the user, if fail, the error message.
function client:showUser(id)
    local s,d,h,c = social.get(full("users/show/%s", (id or self.username)), nil, self.auth)
    return check(s,d,h,c)
end

--- Searches for a user.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-users-search
-- @param query Search query.
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the results, if fail, the error message.
function client:searchUser(query, arg)
    if not self.authed then return false,"You must be logged in to do this!" end
    local arg = arg or {}
    arg.q = query
    local s,d,h,c = social.get(full("users/search"), arg, self.auth)
    return check(s,d,h,c)
end

--- Receive a user's friends.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0friends
-- @param id User ID or username (defaults to currently authenticated user)
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the users, if fail, the error message.
function client:friends(id, arg)
    local s,d,h,c = social.get(full("statuses/friends/%s", (id or self.username)), arg, self.auth)
    return check(s,d,h,c)
end

--- Receive a user's followers.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0followers
-- @param id User ID or username (defaults to currently authenticated user)
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the users, if fail, the error message.
function client:followers(id, arg)
    local s,d,h,c = social.get(full("statuses/followers/%s", (id or self.username)), arg, self.auth)
    return check(s,d,h,c)
end

--[[---------- LIST METHODS ------------]]--

--- Creates a list.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-lists
-- @param name Name of the list.
-- @param mode (optional) Public or private -- it's public by default
-- @param description (optional) Description
-- @return boolean Success or not.
-- @return unsigned If success, the new list, if fail, the error message.
function client:createList(name, mode, description)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("%s/lists", self.username), {name = name, mode = mode, description = description}, self.auth)
    return check(s,d,h,c)
end

--- Edits a list.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-lists-id
-- @param name Name of the list to be edited.
-- @param new Table with the new information.
-- @return boolean Success or not.
-- @return unsigned If success, the new list, if fail, the error message.
function client:editList(name, new)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("%s/lists/%s", self.username, name), new, self.auth)
    return check(s,d,h,c)
end

--- Receives a user's lists.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-lists
-- @param user Username (defaults to currently authed user)
-- @param cursor (optional) for pagination
-- @return boolean Success or not.
-- @return unsigned If success, the lists, if fail, the error message.
function client:userLists(user, cursor)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("%s/lists", user or self.username), {cursor = cursor}, self.auth)
    return check(s,d,h,c)
end

--- Receives a list.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-id
-- @param user Owner of the list.
-- @param name Name of the list.
-- @return boolean Success or not.
-- @return unsigned If success, the list, if fail, the error message.
function client:list(user, name)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("%s/lists/%s", user, name), nil, self.auth)
    return check(s,d,h,c)
end

--- Deletes a list.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-DELETE-list-id
-- @param name Name of the list.
-- @return boolean Success or not.
-- @return unsigned If success, the list, if fail, the error message.
function client:deleteList(name)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.delete(full("%s/lists/%s", self.username, name), nil, self.auth)
    return check(s,d,h,c)
end

--- Receives tweets from a list.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-statuses
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the statuses, if fail, the error message.
function client:listTweets(name, user, arg)
    local s,d,h,c = social.get(full("%s/lists/%s/statuses", user or self.username, name), arg, self.auth)
    return check(s,d,h,c)
end

--- Checks what lists a user is in.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-memberships
-- @param user Target user. Defaults to the currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the lists, if fail, the error message.
function client:userInLists(user, cursor)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("%s/lists/memberships", user or self.username), {cursor = cursor}, self.auth)
    return check(s,d,h,c)
end

--- Checks what lists a user is following.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-subscriptions
-- @param user Target user. Defaults to the currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, lists, if fail, the error message.
function client:userFollowingLists(user, cursor)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("%s/lists/subscriptions", user or self.username), {cursor = cursor}, self.auth)
    return check(s,d,h,c)
end

--[[---------- LIST MEMBERS METHODS ------------]]--

--- Receives users in a list.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-members
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the users, if fail, the error message.
function client:usersInList(name, user, cursor)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("%s/%s/members", user or self.username, name), {cursor = cursor}, self.auth)
    return check(s,d,h,c)
end

--- Adds a user to a list.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-list-members
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
    local s,d,h,c = social.post(full("%s/%s/members", user or self.username, name), {id = id}, self.auth)
    return check(s,d,h,c)
end

--- Removes a user from a list.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-DELETE-list-members
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
    local s,d,h,c = social.delete(full("%s/%s/members", user or self.username, name), {id = id}, self.auth)
    return check(s,d,h,c)
end

--- Checks if a user is in a list.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-members-id
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
    local s,d,h,c = social.get(full("%s/%s/members/%s", user or self.username, name, id), nil, self.auth)
    return check(s,d,h,c)
end

--[[---------- LIST SUBSCRIBERS METHODS ------------]]--

--- Receives subscribers of a list.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-subscribers
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the users, if fail, the error message.
function client:usersFollowingList(name, user, cursor)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("%s/%s/subscribers", user or self.username, name), {cursor = cursor}, self.auth)
    return check(s,d,h,c)
end

--- Subscribes to a list.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-list-subscribers
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @return boolean Success or not.
-- @return unsigned If success, the list, if fail, the error message.
function client:followList(name, user)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("%s/%s/subscribers", user or self.username, name), nil, self.auth)
    return check(s,d,h,c)
end

--- Unsubscribes from a list.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-list-subscribers
-- @param name Name of the list.
-- @param user Owner of the list. Defaults to the currently authed user.
-- @return boolean Success or not.
-- @return unsigned If success, the list, if fail, the error message.
function client:unfollowList(name, user)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.delete(full("%s/%s/subscribers", user or self.username, name), nil, self.auth)
    return check(s,d,h,c)
end

--- Checks if a user is subscribing to a list.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-subscribers-id
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
    local s,d,h,c = social.get(full("%s/%s/subscribers/%s", user or self.username, name, id), nil, self.auth)
    return check(s,d,h,c)
end

--[[---------- DIRECT MESSAGE METHODS ------------]]--

--- Retrieves a list of direct messages to the authed user.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages
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
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages%C2%A0sent
-- @param arg (optional) arguments
-- @return boolean Success or not.
-- @return unsigned If success, the messages, if fail, the error message.
function client:sentDirectMessages(arg)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("direct_messages/sent"), arg, self.auth)
    return check(s,d,h,c)
end

--- Sends a direct message to the target user.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages%C2%A0new
-- @param user Target user.
-- @param msg Message text.
-- @return boolean Success or not.
-- @return unsigned If success, the message, if fail, the error message.
function client:sendDirectMessage(user, msg)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("direct_messages/new"), {user = user, text = msg}, self.auth)
    return check(s,d,h,c)
end

--- Deletes a direct message.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages%C2%A0destroy
-- @param id Message ID.
-- @return boolean Success or not.
-- @return unsigned If success, the messages, if fail, the error message.
function client:deleteDirectMessage(id)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("direct_messages/destroy/%s", id), nil, self.auth)
    return check(s,d,h,c)
end

--[[---------- FRIENDSHIP METHODS ------------]]--

--- Follows a user.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships%C2%A0create
-- @param user User ID or username.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:follow(user)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("friendships/create/%s", user), nil, self.auth)
    return check(s,d,h,c)
end

--- Unfollows a user.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships%C2%A0destroy
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
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships-exists
-- @param usera Is this user...
-- @param userb ...following this user?
-- @return boolean Success or not.
-- @return unsigned If success, a boolean, if fail, the error message.
function client:isFollowing(usera, userb)
    local s,d,h,c = social.get(full("friendships/exists"), {user_a = usera, user_b = userb}, self.auth)
    return check(s,d,h,c)
end

--- Receives information about a friendship.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships-show
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

--[[---------- SOCIAL GRAPH METHODS ------------]]--

--- Receives a list of IDs that a user is following.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friends%C2%A0ids
-- @param user User ID or username. Defaults to currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the ids, if fail, the error message.
function client:following(user, cursor)
    local s,d,h,c = social.get(full("friends/ids/%s", user or self.username), {cursor = cursor}, self.auth)
    return check(s,d,h,c)
end

--- Receives a list of IDs that is following the user.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-followers%C2%A0ids
-- @param user User ID or username. Defaults to currently authed user.
-- @param cursor Used for pagination.
-- @return boolean Success or not.
-- @return unsigned If success, the ids, if fail, the error message.
function client:followers(user, cursor)
    local s,d,h,c = social.get(full("followers/ids/%s", user or self.username), {cursor = cursor}, self.auth)
    return check(s,d,h,c)
end

--[[---------- ACCOUNT METHODS ------------]]--
-- TODO: rate_limit_status
-- TODO: end_session
-- TODO: update_delivery_device
-- TODO: update_profile_image
-- TODO: update_profile_background_image

--- Attempts authentication with Twitter.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0verify_credentials
-- @param username Username to login with
-- @param password Password of the user
-- @return boolean Success or not
-- @return unsigned If success, the signed in user. If fail, the error message.
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

--- Flushes account info from client.
function client:logout()
    self.authed = false
    self.auth = nil
    self.username = nil
    self.user = nil
end

--- Changes colors on the user's profile.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_profile_colors
-- @param new New info.
-- @return boolean Success or not.
-- @return unsigned If success, the new profile, if fail, the error message.
function client:updateProfileColors(new)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("account/update_profile_colors"), new, self.auth)
    return check(s,d,h,c)
end

--- Changes fields on the user's profile.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_profile
-- @param new New info.
-- @return boolean Success or not.
-- @return unsigned If success, the new profile, if fail, the error message.
function client:updateProfile(new)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("account/update_profile"), new, self.auth)
    return check(s,d,h,c)
end

--[[---------- FAVORITE METHODS ------------]]--

--- Receives a list of that user's favorite tweets.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-favorites
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
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-favorites%C2%A0create
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
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-favorites%C2%A0destroy
-- @param id Status ID.
-- @return boolean Success or not.
-- @return unsigned If success, the status, if fail, the error message.
function client:removeFavorite(id)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("favorites/destroy/%s", id), nil, self.auth)
    return check(s,d,h,c)
end

--[[---------- NOTIFICATION METHODS ------------]]--

--- Enables notifications for a user.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-notifications%C2%A0follow
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
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-notifications%C2%A0leave
-- @param user User ID or username.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:unfollowDevice(user)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("notifications/leave/%s", user), nil, self.auth)
    return check(s,d,h,c)
end

--[[---------- BLOCK METHODS ------------]]--

--- Blocks a user.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-blocks%C2%A0create
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
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-blocks%C2%A0destroy
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
-- http://apiwiki.twitter.com/Twitter+REST+API+Method%3A-blocks-exists
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
-- http://apiwiki.twitter.com/Twitter+REST+API+Method%3A-blocks-blocking
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
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-blocks-blocking-ids
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:blockingIds()
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("blocks/blocking/ids"), nil, self.auth)
    return check(s,d,h,c)
end

--[[---------- SPAM REPORTING METHODS ------------]]--

--- Blocks a user and reports as a spammer.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-report_spam
-- @param user User ID or username.
-- @return boolean Success or not.
-- @return unsigned If success, the user, if fail, the error message.
function client:reportSpam(user)
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.post(full("report_spam"), {id = user}, self.auth)
    return check(s,d,h,c)
end

--[[---------- SAVED SEARCHES METHODS ------------]]--

--- Receives a list of a user's saved searches.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches
-- @return boolean Success or not.
-- @return unsigned If success, the searches, if fail, the error message.
function client:savedSearches()
    if not self.authed then return false,"You must be logged in to do this!" end
    local s,d,h,c = social.get(full("saved_searches"), nil, self.auth)
    return check(s,d,h,c)
end

--- Receives info about a user's saved search.
-- You must be logged in to do this.
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches-show
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
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches-create
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
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches-destroy
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

--- A simple function to receive a user's home timeline.
-- @param username Username to login as.
-- @param password Password of the user.
-- @return boolean Success or not
-- @return unsigned If fail, the error message. If success, the timeline.
-- @see client:homeTimeline
function homeTimeline(username, password)
    local cl = client:new()
    local s,m = cl:login(username, password)
    if not s then return false,m end
    local s,m = cl:homeTimeline()
    return s,m
end
