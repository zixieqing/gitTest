--[[
包厢配表解析器
--]]
local AbstractBaseParser = require('Game.Datas.Parser')
---@class PrivateRoomConfigParser
local PrivateRoomConfigParser  = class('PrivateRoomConfigParser', AbstractBaseParser)

PrivateRoomConfigParser.NAME = 'PrivateRoomConfigParser'

PrivateRoomConfigParser.TYPE = {
    AVATAR_THEHE    = 'avatarTheme',
    GIFT_POSITION   = 'giftPosition',
    GUEST_GIFT      = 'guestGift',
    BUFF            = 'buff',
    AVATAR_LOCATION = 'avatarLocation', 
    AVATAR_THEME_INIT = 'avatarThemeinit',
    AVATAR_THEME_TOP = 'avatarThemeTop',
    GUEST            = 'guest',
}

function PrivateRoomConfigParser:ctor()
	self.super.ctor(self, table.values(PrivateRoomConfigParser.TYPE))
end

return PrivateRoomConfigParser