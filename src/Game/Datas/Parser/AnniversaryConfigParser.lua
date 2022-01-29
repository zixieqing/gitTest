--[[
活动副本配表解析器
--]]
local AbstractBaseParser      = require('Game.Datas.Parser')
---@class AnniversaryConfigParser  :  Parser
local AnniversaryConfigParser = class('AnniversaryConfigParser', AbstractBaseParser)

AnniversaryConfigParser.NAME  = 'AnniversaryConfigParser'

AnniversaryConfigParser.TYPE  = {
    ANNIVERSARY_STORY       = 'anniversaryStory',
    ASSISTANT               = 'assistant',
    ASSISTANT_SKILL         = 'assistantSkill',
    BLACK_MARKET            = 'blackMarket',
    BLACK_RECIPE_MARKET     = 'blackRecipeMarket',
    CHALLENGE_POINT_REWARDS = 'challengePointRewards',
    CHALLENGE_RANK_REWARDS  = 'challengeRankRewards',
    CHAPTER_MAP             = 'chapterMap',
    CHAPTER                 = 'chapter',
    CHAPTER_SORT            = 'chapterSort',
    DAILY_RANK_REWARDS      = 'dailyRankRewards',
    FOOD_LEVEL              = 'recipeLevel',
    FOOD_ATTR               = 'recipeAttr',
    GUARANTEED_REWARDS      = 'guaranteedRewards',
    LUCKY_REWARDS           = 'luckyRewards',
    MAP_GRID                = 'mapGrid',
    PARAMETER               = 'parameter',
    QUEST                   = 'quest',
    RECIPE_PRICE            = 'recipePrice',
    QUEST_NODE_TYPE         = 'questNodeType',
    REFRESH_CONSUME         = 'refreshConsume',
    STORY_COLLECTION        = 'storyCollection',
    STORY_REWARDS           = 'storyRewards',
    TOTAL_RANK_REWARDS      = 'totalRankRewards',
    ASSISTANT_BUFF_TYPE     = 'assistantBuffType',
    SCHEDULE_OPEN           = 'scheduleOpen',
    STORY_COLLECTION_GROUP  = 'storyCollectionGroup'
}

function AnniversaryConfigParser:ctor()
    self.super.ctor(self, table.values(AnniversaryConfigParser.TYPE) )
end
--[[
获取vo路径
@params name 配表名字
--]]
function AnniversaryConfigParser:GetVoPath(name)
    local path = nil
    name = string.ucfirst(name)
    if not utils.isExistent(path) and name ~= 'Quest' then
        path = 'Game.Datas.Vo'
    else
        path = 'Game.Datas.vo.' .. name .. 'Vo'
    end
    return path
end


return AnniversaryConfigParser