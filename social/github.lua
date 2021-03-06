local social = require"social"
--------------------------------
local mime = require"mime" -- luarocks install luasocket
local url = require"socket.url" --             luasocket
local json = require"json" --                  json4lua

--- SocialLua - GitHub module.
-- This module is alpha quality, and behaviour may change without prior notice.
-- @author Linus Sjögren (thelinx@unreliablepollution.net)
module("social.github", package.seeall) -- seeall for now

function full(page, ...)
    return "https://github.com/api/v2/json/"..string.format(page, ...)
end

local function check(s,d,h,c)
    if not s then return false,d end
    local t = json.decode(d)
    if c ~= 200 then
        return false,t.error[1].error
    else
        return true,t
    end
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
        self.user = t.user
        return true,t.user
    else
        self:logout()
        return false,"failed to authorize"
    end
end

--- Searches for a GitHub user.
-- @param query Search query.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the results.
function client:userSearch(query)
    local s,d,h,c = social.get(full("user/search/%s", query))
    return check(s,d,h,c)
end

--- Shows information about a user.
-- @param username Target user.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the user.
function client:userShow(username)
    local s,d,h,c = social.get(full("user/show/%s", username), self.auth)
    return check(s,d,h,c)
end

--- Edits a user's information.
-- You must be logged in to do this.
-- Username is set to the currently authed user, no matter what.
-- @param values See http://develop.github.com/p/users.html#authenticated_user_management
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new user info.
function client:userEdit(values)
    local arg = assert(self.auth, "You must be logged in to do this!")
    for k,v in pairs(values) do
        arg["values["..k.."]"] = v
    end
    local s,d,h,c = social.post(full("user/show/%s", self.username), arg)
    if s then
        self.user = d.user
    end
    return check(s,d,h,c)
end

--- Returns a list of users the specified user is following.
-- @param username Target user. Defaults to currently authed user.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the users.
function client:userFollowing(username)
    local s,d,h,c = social.get(full("user/show/%s/following", username or self.username))
    return check(s,d,h,c)
end

--- Returns a list of users following the specified user.
-- @param username Target user. Defaults to currently authed user.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the users.
function client:userFollowers(username)
    local s,d,h,c = social.get(full("user/show/%s/followers", username or self.username))
    return check(s,d,h,c)
end

--- Follows the specified user.
-- You must be logged in to do this.
-- @param username User to follow.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new following list.
function client:userFollow(username)
    local s,d,h,c = social.post(full("user/follow/%s", username), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Unfollows the specified user.
-- You must be logged in to do this.
-- @param username User to unfollow.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new following list.
function client:userUnfollow(username)
    local s,d,h,c = social.post(full("user/unfollow/%s", username), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Returns a list of repos a user is following.
-- @param username Target user. Defaults to currently authed user.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the repos.
function client:reposWatched(username)
    local s,d,h,c = social.get(full("repos/watched/%s", username or self.username))
    return check(s,d,h,c)
end

--- Returns a list of the user's ssh keys.
-- You must be logged in to do this.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the keys.
function client:userKeys()
    local s,d,h,c = social.get(full("user/keys"), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Assigns a ssh key to the user.
-- You must be logged in to do this.
-- @param key Key data.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new list of keys.
function client:userKeyAdd(key)
    local arg = assert(self.auth, "You must be logged in to do this!")
    arg.key = key
    local s,d,h,c = social.post(full("user/key/add"), arg)
    return check(s,d,h,c)
end

--- Removes a ssh key from the user.
-- You must be logged in to do this.
-- @param id Key ID.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new list of keys.
function client:userKeyRemove(id)
    local arg = assert(self.auth, "You must be logged in to do this!")
    arg.id = id
    local s,d,h,c = social.post(full("user/key/remove"), arg)
    return check(s,d,h,c)
end

--- Returns a list of the user's email addresses.
-- You must be logged in to do this.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the addresses.
function client:userEmails()
    local s,d,h,c = social.get(full("user/emails"), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Assigns an email address to the user.
-- You must be logged in to do this.
-- @param email Email address
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new list of addresses.
function client:userEmailAdd(email)
    local arg = assert(self.auth, "You must be logged in to do this!")
    arg.email = email
    local s,d,h,c = social.post(full("user/email/add"), arg)
    return check(s,d,h,c)
end

--- Removes an email address from the user.
-- You must be logged in to do this.
-- @param email Email address
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new list of addresses.
function client:userEmailRemove(email)
    local arg = assert(self.auth, "You must be logged in to do this!")
    arg.email = email
    local s,d,h,c = social.post(full("user/email/remove"), arg)
    return check(s,d,h,c)
end

--- Searches for issues in a repository.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @param state Issue states.
-- @param query Search query.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the issues.
function client:issuesSearch(user, repo, state, query)
    local s,d,h,c = social.get(full("issues/search/%s/%s/%s/%s", user, repo, state, query))
    return check(s,d,h,c)
end

--- Returns a list of issues in a repository.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @param state Issue states.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the issues.
function client:issuesList(user, repo, state)
    local s,d,h,c = social.get(full("issues/list/%s/%s/%s", user, repo, state))
    return check(s,d,h,c)
end

--- Shows information about an issue in a repository.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @param id Issue ID.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the issue.
function client:issuesShow(user, repo, id)
    local s,d,h,c = social.get(full("issues/show/%s/%s/%s", user, repo, id))
    return check(s,d,h,c)
end

--- Opens an issue on a repository.
-- You must be logged in to do this.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @param title Issue title.
-- @param body Descriptive text.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the issue.
function client:issuesOpen(user, repo, title, body)
    local arg = assert(self.auth, "You must be logged in to do this!")
    arg.title = title
    arg.body = body
    local s,d,h,c = social.post(full("issues/open/%s/%s", user, repo), arg)
    return check(s,d,h,c)
end

--- Closes an issue on a repository.
-- You must be logged in to do this.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @param id Issue ID.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the issue.
function client:issuesClose(user, repo, id)
    local s,d,h,c = social.post(full("issues/close/%s/%s/%d", user, repo, id), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Reopens an issue on a repository.
-- You must be logged in to do this.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @param id Issue ID.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the issue.
function client:issuesReopen(user, repo, id)
    local s,d,h,c = social.post(full("issues/reopen/%s/%s/%d", user, repo, id), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Edits an issue on a repository.
-- You must be logged in to do this.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @param id Issue ID.
-- @param new New info. See http://develop.github.com/p/issues.html#edit_existing_issues for details.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the issue.
function client:issuesEdit(user, repo, id, new)
    local arg = assert(self.auth, "You must be logged in to do this!")
    for k,v in pairs(new) do
        arg[k] = v
    end
    local s,d,h,c = social.post(full("issues/edit/%s/%s/%s", user, repo, id), arg)
    return check(s,d,h,c)
end

--- Lists issue labels in a repository.
-- You must be logged in to do this.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the labels.
function client:issuesLabels(user, repo)
    local s,d,h,c = social.get(full("issues/labels/%s/%s", user, repo), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Labels an issue.
-- You must be logged in to do this.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @param label Label name.
-- @param id Issue ID.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new list of labels for target issue.
function client:issuesLabelAdd(user, repo, label, id)
    local s,d,h,c = social.post(full("issues/label/add/%s/%s/%s/%s", user, repo, label, id), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Unlabels an issue.
-- You must be logged in to do this.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @param label Label name.
-- @param id Issue ID.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new list of labels for target issue.
function client:issuesLabelRemove(user, repo, label, id)
    local s,d,h,c = social.post(full("issues/label/remove/%s/%s/%s/%s", user, repo, label, id), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Comments an issue.
-- You must be logged in to do this.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @param id Issue ID.
-- @param comment Comment text.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the comment.
function client:issuesComment(user, repo, id, comment)
    local arg = assert(self.auth, "You must be logged in to do this!")
    arg.comment = comment
    local s,d,h,c = social.post(full("issues/comment/%s/%s/%s", user, repo, id), arg)
    return check(s,d,h,c)
end

--- Returns information about a repository's network.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the info.
function client:networkMeta(user, repo)
    local s,d,h,c = social.get("http://github.com/"..user.."/"..repo.."/network_meta", self.auth)
    return check(s,d,h,c)
end

--- Returns network information about a repository.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @param nethash See http://develop.github.com/p/network.html#network_data
-- @param s See http://develop.github.com/p/network.html#network_data
-- @param e See http://develop.github.com/p/network.html#network_data
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the info.
function client:networkDataChunk(user, repo, nethash, s, e)
    local arg = self.auth or {}
    arg.nethash = nethash
    arg.start = s
    arg["end"] = e
    local s,d,h,c = social.get("http://github.com/"..user.."/"..repo.."/network_data_chunk", arg)
    return check(s,d,h,c)
end

--- Searches for repositories.
-- @param query Search query.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the results.
function client:reposSearch(query)
    local s,d,h,c = social.get(full("repos/search/%s", query))
    return check(s,d,h,c)
end

--- Returns information about a repository.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the info.
function client:reposShow(user, repo)
    local s,d,h,c = social.get(full("repos/show/%s/%s", user, repo), self.auth)
    return check(s,d,h,c)
end

--- Follows a repository for updates.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the repository info.
function client:reposWatch(user, repo)
    local s,d,h,c = social.get(full("repos/watch/%s/%s", user, repo), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Unfollows a repository.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the repository info.
function client:reposUnwatch(user, repo)
    local s,d,h,c = social.get(full("repos/unwatch/%s/%s", user, repo), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Forks a repository.
-- @param user Owner of the repo.
-- @param repo Repository name.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new repository info.
function client:reposFork(user, repo)
    local s,d,h,c = social.get(full("repos/fork/%s/%s", user, repo), assert(self.auth, "You must be logged in to do this!"))
    return check(s,d,h,c)
end

--- Creates a repository.
-- @param name Name of the new repo.
-- @param desc (optional) Description.
-- @param url (optional) Homepage URL.
-- @param pub (optional) Whether the repo is public or not. Defaults to public.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the new repository info.
function client:reposCreate(name, desc, url, pub)
    local arg = assert(self.auth, "You must be logged in to do this!")
    arg.name = name
    arg.description = description
    arg.homepage = url
    if pub == false then
        arg.public = 0
    else
        arg.public = (pub and tonumber(pub))
    end
    local s,d,h,c = social.get(full("repos/create"), arg)
    return check(s,d,h,c)
end

--- Deletes a repository.
-- @param name Name of the repo.
-- @param token Confirmation token.
-- @return boolean Success or not.
-- @return unsigned If fail, the error message. If success, the deletion info.
function client:reposDelete(name, token)
    local arg = assert(self.auth, "You must be logged in to do this!")
    arg.delete_token = token
    local s,d,h,c = social.get(full("repos/delete/%s", name), arg)
    return check(s,d,h,c)
end
