local social = require"social"
--------------------------------
local mime = require"mime" -- luarocks install luasocket
local url = require"socket.url" --             luasocket
local json = require"json" --                  json4lua

local string = string
local setmetatable,tonumber,type,tonumber = setmetatable,tonumber,type,tonumber

--- SocialLua - Twitter module.
-- @author Linus Sjögren (thelinxswe@gmail.com)
module("social.twitter", package.seeall)
-- TODO: Search API functions.
-- TODO: OAuth

resources = {
-- Timeline resources
	publicTimeline = {"get", "statuses/public_timeline"},
	homeTimeline = {"get", "statuses/home_timeline"},
	friendsTimeline = {"get", "statuses/friends_timeline"},
	userTimeline = {"get", "statuses/user_timeline"},
	mentions = {"get", "statuses/mentions"},
	retweetedByMe = {"get", "statuses/retweeted_by_me"},
	retweetedToMe = {"get", "statuses/retweeted_to_me"},
-- Tweets resources
	retweetsOfMe = {"get", "statuses/retweets_of_me"},
	showStatus = {"get", "statuses/show"},
	updateStatus = {"post", "statuses/update"},
	destroyStatus = {"post", "statuses/destroy"},
	retweetStatus = {"post", "statuses/retweet/:id"},
	retweets = {"get", "statuses/retweets"},
	retweetedBy = {"get", "statuses/:id/retweeted_by"},
	retweetedByIds = {"get", "statuses/:id/retweeted_by/ids"},
-- User resources
	showUser = {"get", "users/show"},
	lookupUsers = {"get", "users/lookup"},
	searchUsers = {"get", "users/search"},
	suggestedUserGroups = {"get", "users/suggestions"},
	suggestedUsers = {"get", "users/suggestions/:slug"},
	profileImage = {"get", "users/profile_image/:screen_name"},
	friends = {"get", "statuses/friends"},
	followers  = {"get", "statuses/followers"},
-- Trends resources
	trends = {"get", "trends"},
	currentTrends = {"get", "trends/current"},
	dailyTrends = {"get", "trends/daily"},
	weeklyTrends = {"get", "trends/weekly"},
-- List resources
	newList = {"post", ":user/lists"},
	updateList = {"post", ":user/lists/:id"},
	userLists = {"get", ":user/lists"},
	showList = {"get", ":user/lists/:id"},
	deleteList = {"delete", ":user/lists/:id"},
	listTimeline = {"get", ":user/lists/:id/statuses"},
	listMemberships = {"get", ":user/lists/memberships"},
	listSubscriptions = {"get", ":user/lists/subscriptions"},
-- List Members resources
	getListMembers = {"get", ":user/:list_id/members"},
	addListMember = {"post", ":user/:list_id/members"},
	delListMember = {"delete", ":user/:list_id/members"},
	chkListMember = {"get", ":user/:list_id/members/:id"},
-- List Subscribers resources
	getListSubscribers = {"get", ":user/:list_id/subscribers"},
	addListSubscriber = {"post", ":user/:list_id/subscribers"},
	delListSubscriber = {"delete", ":user/:list_id/subscribers"},
	chkListSubscriber = {"get", ":user/:list_id/subscribers/:id"},
-- Direct Messages resources
	listMessages = {"get", "direct_messages"},
	sentMessages = {"get", "direct_messages/sent"},
	sendMessage = {"post", "direct_messages/new"},
	removeMessage = {"post", "direct_messages/destroy"},
-- Friendship resources
	follow = {"post", "friendships/create/:id"},
	unfollow = {"post", "friendships/destroy/:id"},
	isFollowing = {"get", "friendships/exists"},
	showRelation = {"get", "friendships/show"},
	inFriendships = {"get", "friendships/incoming"},
	outFriendships = {"get", "friendships/outgoing"},
-- Friends and Followers resources
	following = {"get", "friends/ids"},
	followers = {"get", "followers/ids"},
-- Account resources
	rateLimitStatus = {"get", "account/rate_limit_status"},
	updateDeliveryDevice = {"post", "account/update_delivery_device"},
	updateProfileColors = {"post", "account/update_profile_colors"},
	updateProfileImage = {"post", "account/update_profile_image"},
	-- holy shit take a look at that --> / <-- perfect line!!!
	updateProfileBackground = {"post", "account/update_profile_background"},
	updateProfile = {"post", "account/update_profile"},
-- Favorites resources
	favorites = {"get", "favorites"},
	addFavorite = {"post", "favorites/:id/create"},
	delFavorite = {"post", "favorites/destroy"},
-- Notifications resources
	enableNotifications = {"post", "notifications/follow"},
	disableNotifications = {"post", "notifications/unfollow"},
-- Block resources
	addBlock = {"post", "blocks/create"},
	delBlock = {"post", "blocks/destroy"},
	chkBlock = {"get", "blocks/exists"},
	blocking = {"get", "blocks/blocking"},
	blockingIds = {"get", "blocks/blocking/ids"},
-- Spam Reporting resources
	reportSpam = {"post", "report_spam"},
-- Saved Searches resources
	savedSearches = {"get", "saved_searches"},
	doSavedSearch = {"get", "saved_searches/show"},
	addSavedSearch = {"post", "saved_searches/create"},
	delSavedSearch = {"post", "saved_searches/destroy"},
-- Local Trends resources
	availableLocations = {"get", "trends/available"},
	locationTrends = {"get", "trends/locations/:woeid"},
-- Geo resources
	reverseGeocode = {"get", "geo/reverse_geocode"},
	placeInfo = {"get", "geo/id/:place_id"}
}

host = "api.twitter.com"

local function full(p, ...)
    return (string.format("http://%s/1/%s.json", host, string.format(p, ...)))
end

local function check(s,d,h,c)
    if not s then return false,d end
    local t = json.decode(d)
    if c ~= 200 then
        return nil,t.error
    else
        return t
    end
end

client = {}
local cl_mt = { __index = client }

--- Creates a new Twitter client.
-- @param key (Optional) OAuth Consumer Key
-- @param secret (Optional) OAuth Consomer Secret
function client:new(key, secret)
    return setmetatable({authed = false, ckey = key, csecret = secret}, cl_mt)
end

function cl_mt:__tostring()
    if self.authed then
        return "Twitter client, authed as "..self.username.." ("..self.auth..")"
    else
        return "Twitter client, not authed"
    end
end

for name,info in pairs(resources) do
	local info = info
	client[name] = function(self, arg)
		local url = info[2]:gsub(":([%w_-]+)", arg)
		return check(social[info[1]](full(url), arg, self.auth))
	end
end

function client:requestToken()
	local auth = social.authoauth{
		url = "https://api.twitter.com/oauth/request_token",
		method = "post",
		consumerKey = self.ckey,
		consumerSecret = self.csecret
	}
	return social.post("https://api.twitter.com/oauth/request_token", {}, auth)
end

function client:flushAuth()
	self.auth = nil
end