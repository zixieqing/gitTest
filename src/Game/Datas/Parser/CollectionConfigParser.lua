local Parser = require( 'Game.Datas.Parser' )

local CollectionConfigParser = class('CollectionConfigParser', Parser)

CollectionConfigParser.NAME = "CollectionConfigParser"

function CollectionConfigParser:ctor()
	self.super.ctor(self, {
		'cardOrder', 
		'cardStoryOrder', 
		'CardVoiceOrder', 
		'monster', 
		'pet', 
		'questMonster', 
		'role', 
		'world', 
		'worldOrder',
		'cg',
		'cgFragmentRate',
	})
end

return CollectionConfigParser