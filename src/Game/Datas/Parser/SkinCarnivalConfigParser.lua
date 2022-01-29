--[[
 * descpt :巅峰对决 - 配表解析器
]]
local AbstractBaseParser = require('Game.Datas.Parser')
local SkinCarnivalConfigParser  = class('SkinCarnivalConfigParser', AbstractBaseParser)

SkinCarnivalConfigParser.NAME = 'SkinCarnivalConfigParser'
SkinCarnivalConfigParser.TYPE = {
    FLASH_SALE = 'flashSale',
    FLASH_SALE_REWARD = 'flashSaleReward',
    QUEST = 'quest',
    QUEST_BAN = 'questBan',
    QUEST_DISCOUNT = 'questDiscount',
    SKIN = 'skin',
    SKIN_STORY = 'skinStory',
    SUMMARY = 'summary',
    TASK = 'task',
    TASK_TARGET_NUM = 'taskTargetNum',
}

function SkinCarnivalConfigParser:ctor()
	self.super.ctor(self, table.values(SkinCarnivalConfigParser.TYPE))
end


return SkinCarnivalConfigParser
