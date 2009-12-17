package = "SocialLua"
version = "1.0-1"
description = {
    summary = "Library for interfacing with many sites and services",
    detailed = [[
        SocialLua is a set of modules that aims to provide simple Lua
        function wrappers for many internet sites and service APIs.
    ]],
    license = "Public Domain",
    homepage = "http://github.com/TheLinx/SocialLua",
    maintainer = "Linus Sjögren <thelinx@unreliablepollution.net>"
}
dependencies = {
    "lua >= 5.1",
    "luasocket >= 2.0.2",
    "json4lua >= 0.9.3"
}
source = {
    url = "http://github.com/TheLinx/SocialLua/tarball/SR1",
    file = "TheLinx-SocialLua-09396ba.tar.gz",
}
build = {
    type = "builtin",
    modules = {
        social = "social/init.lua",
        ["social.twitter"] = "social/twitter.lua",
        ["social.unu"] = "social/unu.lua"
    }
}
