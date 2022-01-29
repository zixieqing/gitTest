--[[
 * author : kaishiqi
 * descpt : 爬塔相关 - 配表解析器
]]

local AbstractBaseParser = require('Game.Datas.Parser')
---@class ArtifactConfigParser
local ArtifactConfigParser  = class('ArtifactConfigParser', AbstractBaseParser)

ArtifactConfigParser.NAME = 'ArtifactConfigParser'

ArtifactConfigParser.TYPE = {
	ASSISTANT_COORDINATE    = 'assistantCoordinate',
	COORDINATE_MELEEDPS     = 'coordinateMeleeDps',
	COORDINATE_REMOTEDPS    = 'coordinateRemoteDps',
	DAMAGE_COORDINATE       = 'defenseCoordinate',
	GEM_STONE               = 'gemstone',
	GEM_STONE_COLOR         = 'gemstoneColor',
	GEM_STONE_CONSUME       = 'gemstoneTalentConsume',
	GEM_STONE_LUCKY_CONSUME = 'gemstoneLuckyConsume',
	GEM_STONE_SKILL_GROUP   = "gemstoneSkillGroup",
	LOWER_BASE_PRIZE_POOL   = "lowerBasePrizePool",
	LOWER_PRIZE_POOL        = "lowerPrizePool",
	MIDDLE_BASE_PRIZE_POOL  = "middleBasePrizePool",
	MIDDLE_PRIZE_POOL       = "middlePrizePool",
	SENIOR_BASE_PRIZE_POOL  = "seniorBasePrizeool",
	SENIOR_PRIZE_POOL       = "seniorPrizePool",
	SPECIAL_BASE_PRIZE_POOL = "specialBasePrizePool",
	SPECIAL_PRIZE_POOL      = "specialPrizePool",
	TALENT_CONSUME          = 'talentConsume',
	QUEST                   = 'quest',
	TALENT_POINT            = 'talentPoint',
	TALENT_SKILL            = 'talentSkill',
	GEM_STONE_COLOR         = 'gemstoneColor',
	GEM_STONE_SKILL_GROUP   = 'gemstoneSkillGroup',
	GEM_STONE_RATE          = 'gemstoneRate',
	CARD_GEMSTONE_SKILL_INDEX = 'cardArtifactGemstoneSkill',
	GUIDE 					= 'guide',
	GUIDE_PRIZE 		    = 'guidePrize'
}

------------ define ------------
-- /***********************************************************************************************************************************\
--  * 分表的逻辑
--  * 需要被分表的源表 额外拥有一个索引关系的表 该表中处理源表中的id和分表文件的对应关系
--  * 实现分表只需要配置 [IndexConfig 源表对应哪个索引表] [IndexHandler 处理分表表名逻辑]
--  * 分表索引表请提前加载
--  * !!! warning !!! 使用 Parser:GetVoById() 或 CommonUtils.GetConfigAllMess() 方法时请注意 获取整张表数据时和分表本身的逻辑有冲突
-- \***********************************************************************************************************************************/
-- 分表逻辑的索引表
local IndexConfig = {
	['gemstoneSkill'] = 'cardArtifactGemstoneSkill'
}
-- 分表逻辑的分表表名处理
local IndexHandler = {
	--[[
	@params tname string 源表名
	@params id int id
	@params indexvalue value 索引表中对应的值
	@return _ string 修正后的表名
	--]]
	['gemstoneSkill'] = function (tname, id, indexvalue)
		return tname .. tostring(indexvalue)
	end
}
------------ define ------------


function ArtifactConfigParser:ctor()
	self.super.ctor(self, table.values(ArtifactConfigParser.TYPE))
end
--[[
@override
修正分表的表名 拼接表名的逻辑
@params tname string 源表名
@params id int id
@params indexvalue value 索引表中对应的值
@return fixedtname string 修正后的表名
--]]
function ArtifactConfigParser:FixJsonName(tname, id, indexvalue)
	if nil ~= IndexHandler[tname] then
		return IndexHandler[tname](tname, id, indexvalue)
	end
	return tname
end

--[[
@override
根据表名获取分表索引信息
@params tname string 源表名
@return indextname string 索引表名
--]]
function ArtifactConfigParser:GetIndexByJsonName(tname)
	return IndexConfig[tname]
end


--[[
获取分表数据
@params name string 配表名字
@params id int vo id
--]]
function ArtifactConfigParser:gemstoneSkill(tname , id)
	local realId   = self:GetVo(self:GetIndexByJsonName(tname), id)
	local realName = self:FixJsonName(tname, id, realId)
	return self:GetVo(realName , id)
end

return ArtifactConfigParser