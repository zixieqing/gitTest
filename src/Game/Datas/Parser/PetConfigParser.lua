local Parser = require( 'Game.Datas.Parser' )

local PetConfigParser = class('PetConfigParser', Parser)

PetConfigParser.NAME = "PetConfigParser"

function PetConfigParser:ctor()
	self.super.ctor(self,{
		'pet',
		'baitRateAddition',
		'questPet',
		'petEgg',
		'petPond',
		'petMagicFoodUnlock',
		'petCharacter',
		'level',
		'petBreak',
		'fusion',
		'petWaterCrit'
	})
end


return PetConfigParser
