

--- SocialLua
-- @author Bart van Strien (bart.bes@gmail.com)
-- @author Linus Sjögren (thelinxswe@gmail.com)
module("social", package.seeall) -- seeall for now

function request(header, host, page, ...)
    local d = string.format(header, host, page, ...)
    -- send d
    return
end
