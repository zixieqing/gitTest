local Parser = require( 'Game.Datas.Parser' )

local KitchenConfigParser = class('KitchenConfigParser', Parser)

KitchenConfigParser.NAME = "KitchenConfigParser"

function KitchenConfigParser:ctor()
	self.super.ctor(self,{'recipe', 'stove','stoveLevelUp','stoveQueue','stoveQueueUnlockType','recipeStudy','recipeStudyDialog','recipeStudyDialogSituation','recipeStudyStory'})
end


return KitchenConfigParser
