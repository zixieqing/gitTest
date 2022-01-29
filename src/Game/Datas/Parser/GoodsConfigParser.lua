local Parser = require( 'Game.Datas.Parser' )

local GoodsConfigParser = class('GoodsConfigParser', Parser)

GoodsConfigParser.NAME = "GoodsConfigParser"

function GoodsConfigParser:ctor()
	self.super.ctor(self, {
		'goods', 'money', 'type', 'consumeProp', 'cardFragment', 'food', 'foodMaterial', 'upgradeProp', 'seasoning', 'petEgg', 
		'recipe', 'cardSkin', 'magicFood', 'other', 'gemstone', 'artifactFragment', 'fishBait', 'avatar', 'privateRoomGift', 
		'privateRoomAvatarTheme', 'expBuff', 'battleCardPack', 'optionalChest',
	})
    -- local t = {"card", "cardFragment", "chest", "consumeProp", "energy", "food", "foodMaterial", "goods", "money", "type", "upgradeProp"}
	-- self.super.ctor(self,t)
end


return GoodsConfigParser
