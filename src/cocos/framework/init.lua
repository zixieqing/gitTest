--[[
]]

if type(DEBUG) ~= "number" then DEBUG = 0 end

-- load framework
printInfo("")
printInfo("# DEBUG                        = " .. DEBUG)
printInfo("#")

json      = require('cocos.framework.json')
device     = require("cocos.framework.device")
display    = require("cocos.framework.display")
transition = require("cocos.framework.transition")
filter     = require("cocos.framework.filter")
network    = require("cocos.framework.network")
crypto     = require("cocos.framework.crypto")
utils      = require('cocos.framework.utils')

require("cocos.framework.extends.NodeEx")
require("cocos.framework.extends.SpriteEx")
require("cocos.framework.extends.LayerEx")


if device.platform == 'ios' or device.platform == 'mac' then
    luaoc = require('cocos.framework.luaoc')
elseif device.platform == 'android' then
    luaj = require('cocos.framework.luaj')
end
