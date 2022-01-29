local Parser = require( 'Game.Datas.Parser' )

local LobbyConfigParser = class('LobbyConfigParser', Parser)

LobbyConfigParser.NAME = "LobbyConfigParser"

function LobbyConfigParser:ctor()
	self.super.ctor(self,{'diningRoomLevel', 'diningTableLevel', 'foodGroup', 'order', 'orderReward', 'lobbyQuest', 'lobbyDinnersPicture'})
    -- self.super.ctor(self,{'diningRoomLevel'})
end
return LobbyConfigParser