--[[
 * author : kaishiqi
 * descpt : 配表 - 相关定义
]]
---@class ConfProxy
local ConfProxy = {}


function ConfProxy:GetModuleName()
    return checkstr(self.module)
end
function ConfProxy:GetFileName()
    return checkstr(self.file)
end
function ConfProxy:GetFilePath()
    return checkstr(self.path)
end


function ConfProxy:IsEmpty()
    return next(self:GetAll()) == nil
end
function ConfProxy:IsExist()
    return getRealConfigIsExistent(self:GetFilePath())
end
function ConfProxy:IsValid()
    return (self:IsEmpty() == false) and (self:IsExist() ==  true)
end


-- 获取 全部配表
function ConfProxy:GetAll()
    return CommonUtils.GetConfigAllMess(self:GetFileName(), self:GetModuleName()) or {}
end


-- 获取 指定id段配表
function ConfProxy:GetValue(id)
    return CommonUtils.GetConfig(self:GetModuleName(), self:GetFileName(), id) or {}
end


-- 获取 配表数据长度
function ConfProxy:GetLength()
    return table.nums(self:GetAll())
end


-- 获取 配表的全部id（无序）
function ConfProxy:GetIdList()
    local allConf = self:GetAll()
    return table.keys(allConf)
end

-- 获取 配表的全部id（升序，从小到大）
-- Ps:测试发现，遍历排序好的表，比 orderedPairs 遍历要快
function ConfProxy:GetIdListUp()
    local idList = self:GetIdList()
    table.sort(idList, function(a, b)
        return checkint(a) < checkint(b)
    end)
    return idList
end

-- 获取 配表的全部id（降序，从大到小）
function ConfProxy:GetIdListDown()
    local idList = self:GetIdList()
    table.sort(idList, function(a, b)
        return checkint(a) > checkint(b)
    end)
    return idList
end


--[[
    配表数据体
    @param moduleName 模块名字（文件夹）
    @param fileName 文件名字
]]
---@return ConfProxy
local ConfData = function(moduleName, fileName)
    ---@type ConfProxy
    local cData = {
        module = checkstr(moduleName),
        file   = checkstr(fileName),
    }
    if string.len(cData.module) > 0 then
        cData.path = string.format('conf/%s/%s/%s.json', tostring(i18n.getLang()), cData.module, cData.file)
    else
        cData.path = string.format('conf/%s/%s.json', tostring(i18n.getLang()), cData.file)
    end
    setmetatable(cData, {__index = ConfProxy})
    return cData
end


------------------------------------------------------------------------------
-- conf defines
------------------------------------------------------------------------------
CONF = {
    -------------------------------------------------
    -- base
    BASE = {
        MODULE_DEFINE = ConfData(nil, 'module'),        -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/基础表/功能表.xlsx
        MODULE_DESCR  = ConfData(nil, 'moduleExplain'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/基础表/功能规则说明.xlsx
        UNLOCK_TYPE   = ConfData(nil, 'unlockType'),    -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/基础表/解锁条件表.xlsx
        SHARE         = ConfData(nil, 'share'),         -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/基础表/功能分享表.xlsx
    },


    -------------------------------------------------
    -- common
    COMMON = {
        TRIALS_ENTRANCE = ConfData('common', 'speciallyEntrance'),  -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/特定入口表.xlsx
    },


    -------------------------------------------------
    -- avatar
    AVATAR = {
        OFFICIAL     = ConfData('restaurant', 'show'),             -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/餐厅/顶级餐厅avatar信息表.xlsx
        INITIAL      = ConfData('restaurant', 'init'),             -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/餐厅/初始餐厅avatar信息表.xlsx
        DEFINE       = ConfData('restaurant', 'avatar'),           -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/餐厅/餐厅avatar信息表.xlsx
        LOCATION     = ConfData('restaurant', 'avatarLocation'),   -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/餐厅/餐厅avatar位置表.xlsx
        ANIMATION    = ConfData('restaurant', 'avatarAnimation'),  -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/餐厅/餐厅avatar动画表.xlsx
        THEME_DEFINE = ConfData('restaurant', 'avatarTheme'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/餐厅/餐厅avatar主题表.xlsx
        THEME_PARTS  = ConfData('restaurant', 'avatarThemeParts'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/餐厅/餐厅avatar主题信息表.xlsx
        CUSTOMER     = ConfData('restaurant', 'customer'),         -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/餐厅/餐厅顾客表.xlsx
    },

    -------------------------------------------------
    -- business
    BUSINESS = {
        PARMS    = ConfData('business', 'parameter'),     -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/经营参数总表.xlsx
        ENTRANCE = ConfData('business', 'homeEntrance'),  -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/家园入口图标表.xlsx
    },


    -------------------------------------------------
    -- tower
    TOWER = {
        UNIT           = ConfData('tower', 'towerUnit'),             -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/爬塔/爬塔单元表.xlsx
        ENEMY          = ConfData('tower', 'towerEnemy'),            -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/爬塔/爬塔阵容表.xlsx
        CONTRACT       = ConfData('tower', 'towerContract'),         -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/爬塔/爬塔契约条件表.xlsx
        BASE_REWARD    = ConfData('tower', 'towerBaseReward'),       -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/爬塔/爬塔单层基础奖励表.xlsx
        REVIVE_CONSUME = ConfData('tower', 'towerBuyLiveConsume'),   -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/爬塔/爬塔买活表.xlsx
        LEVEL_ATTR     = ConfData('tower', 'towerLevelCoefficient'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/爬塔/爬塔层数难度系数表.xlsx
        GLOBAL_BUFF    = ConfData('tower', 'globalBuff'),            -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/爬塔/全局buff表.xlsx
        RANK_REWARD    = ConfData('tower', 'towerRankReward'),       -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/爬塔/爬塔排行榜名次奖励表.xlsx
        SWEEP          = ConfData('tower', 'towerSweep'),            -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/爬塔/爬塔扫荡层数表.xlsx
    },


    -------------------------------------------------
    -- ttgame
    TTGAME = {
        CARD_INIT   = ConfData('battleCard', 'init'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/初始卡牌及卡组表.xlsx
        CARD_PACK   = ConfData('battleCard', 'cardPack'),  -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/卡包概率信息表.xlsx
        CARD_CAMP   = ConfData('battleCard', 'camp'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/战牌同盟类型表.xlsx
        CARD_DEFINE = ConfData('battleCard', 'card'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/提尔拉战牌基本表.xlsx
        DECK_LIMIT  = ConfData('battleCard', 'teamLimit'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/卡组等级表.xlsx
        CARD_ALBUM  = ConfData('battleCard', 'collect'),   -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/收集手册表.xlsx
        NPC_DEFINE  = ConfData('battleCard', 'npc'),       -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/NPC关卡表.xlsx
        RULE_DEFINE = ConfData('battleCard', 'rule'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/流行规则表.xlsx
        RULE_TYPE   = ConfData('battleCard', 'ruleType'),  -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/流行规则类型表.xlsx
        CHAT_MOOD   = ConfData('battleCard', 'message'),   -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/定型文表.xlsx
        SCHEDULE    = ConfData('battleCard', 'schedule'),  -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/活动排期与内容表.xlsx
        ACTIVITY    = ConfData('battleCard', 'summary'),   -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/提尔拉战牌/战牌活动总表.xlsx
    },


    -------------------------------------------------
    -- activity quest
    ACTIVITY_QUEST = {
        CARD_WORDS = ConfData('activityQuest', 'cardWords'), -- Ps: 目前最大表（已经分表处理了）
    },


    -------------------------------------------------
    -- activity : food vote
    FOOD_VOTE = {
        LOTTERY_POOL  = ConfData('activity', 'foodVoteLottery'),   -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/新飨灵比拼/刮刮乐奖池表.xlsx
        LOTTERY_STAMP = ConfData('activity', 'foodVoteStamp'),     -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/新飨灵比拼/刮刮乐奖池超得表.xlsx
        MAIL          = ConfData('activity', 'foodVoteMail'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/新飨灵比拼/决赛奖励邮件表.xlsx
        MESSAGE       = ConfData('activity', 'foodVoteMsg'),       -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/新飨灵比拼/应援文字显示表.xlsx
        TASK          = ConfData('activity', 'foodVoteTask'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/新飨灵比拼/活动应援任务.xlsx
        PARMS         = ConfData('activity', 'foodVoteParameter'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/新飨灵比拼/决赛活动配置总表.xlsx
        SELECT        = ConfData('activity', 'foodVotePool'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/新飨灵比拼/海选活动配置表.xlsx
    },


    -------------------------------------------------
    -- card
    CARD = {
        PARAMETER      = ConfData('card', 'parameter'),                 -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/卡牌基础设定/卡牌参数总表.xlsx
        TRIGGER_NPC    = ConfData('card', 'npcTrigger'),                -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/卡牌基础设定/卡牌npc开关表.xlsx
        TRIGGER_RES    = ConfData('card', 'onlineResourceTrigger'),     -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/卡牌基础设定/卡牌资源上线开关表.xlsx
        CARD_INFO      = ConfData('card', 'card'),                      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/卡牌基础设定/卡牌基本表.xlsx
        CARD_COMPOSE   = ConfData('card', 'cardConversion'),            -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/卡牌基础设定/卡牌合成分解.xlsx
        CARD_SKIN      = ConfData('goods', 'cardSkin'),                 -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/基础表/道具表/25卡牌皮肤表.xlsx
        SKIN_COLL_INFO = ConfData('cardSkinCollection', 'skin'),        -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/皮肤收藏/皮肤分类表.xlsx
        SKIN_COLL_TYPE = ConfData('cardSkinCollection', 'skinType'),    -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/皮肤收藏/皮肤类别表.xlsx
        SKIN_COLL_TASK = ConfData('cardSkinCollection', 'skinRewards'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/皮肤收藏/皮肤累积奖励表.xlsx
        CARD_COLL_BOOK = ConfData('cardCollection', 'book'),            -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/飨灵收藏册/飨灵收藏册总表.xlsx
        CARD_COLL_TASK = ConfData('cardCollection', 'bookTask'),        -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/飨灵收藏册/飨灵收藏册任务表.xlsx
        CARD_COLL_BUFF = ConfData('cardCollection', 'bookBuff'),        -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/飨灵收藏册/飨灵收藏册buff表.xlsx
    },


    -------------------------------------------------
    -- bar
    BAR = {
        LEVEL_UP                  = ConfData('bar', 'levelUp'),                 -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/酒吧/酒吧等级升级表.xlsx
        DRINK                     = ConfData('bar', 'drink'),                   -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/酒吧/酒吧饮品表.xlsx
        FORMULA                   = ConfData('bar', 'formula'),                 -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/酒吧/配方表.xlsx
        MATERIAL                  = ConfData('bar', 'material'),                -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/酒吧/酒吧食材表.xlsx
        CUSTOMER                  = ConfData('bar', 'customer'),                -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/酒吧/顾客信息表.xlsx
        CUSTOMER_STORY            = ConfData('bar', 'customerStory'),           -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/酒吧/顾客剧情表.xlsx
        CUSTOMER_FREQUENCY_POINT  = ConfData('bar', 'customerFrequencyPoint'),  -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/酒吧/顾客熟客值奖励表.xlsx
        CUSTOMER_STORY_COLLECTION = ConfData('bar', 'customerStoryCollection'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/经营/酒吧/顾客剧情收录表.xlsx
    },


    -------------------------------------------------
    -- springActivity20
    SPRING_ACTIVITY_20 = {
        PARAM                    = ConfData('springActivity2020', 'param'),
        BAN                      = ConfData('springActivity2020', 'ban'),
        CARD_ADDITION            = ConfData('springActivity2020', 'cardAddition'),
        CARD_SKILL               = ConfData('springActivity2020', 'cardSkill'),
        LOTTERY                  = ConfData('springActivity2020', 'lottery'),
        LOTTERY_LOOP             = ConfData('springActivity2020', 'lotteryLoop'),
        LOTTERY_RATE             = ConfData('springActivity2020', 'lotteryRate'),
        POINT_REWARD             = ConfData('springActivity2020', 'pointReward'),
        POINT_STORY              = ConfData('springActivity2020', 'pointStory'),
        QUEST                    = ConfData('springActivity2020', 'quest'),
        QUEST_BOSS               = ConfData('springActivity2020', 'questBoss'),
        QUEST_BOSS_INFO          = ConfData('springActivity2020', 'questBossInfo'),
        QUEST_COMMON             = ConfData('springActivity2020', 'questCommon'),
        QUEST_SEQ                = ConfData('springActivity2020', 'questSeq'),
        QUEST_TYPE               = ConfData('springActivity2020', 'questType'),
        RANK_REWARD              = ConfData('springActivity2020', 'rankReward'),
        STORY                    = ConfData('springActivity2020', 'story'),
        STORY_COLLECT            = ConfData('springActivity2020', 'storyCollect'),
    },


    -------------------------------------------------
    -- goods
    GOODS = {
        CR_BOX = ConfData('goods', 'crBox'),
        HIDDEN = ConfData('goods', 'hide'),
    },


    -------------------------------------------------
    -- championship
    CHAMPIONSHIP = {
        AUDITION_QUEST  = ConfData('championship', 'auditionQuest'),         -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/武道会/武道会海选关卡表.xlsx
        AUDITION_REWARD = ConfData('championship', 'auditionRankReward'),    -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/武道会/武道会海选排行榜奖励表.xlsx
        KNOCKOUT_REWARD = ConfData('championship', 'eliminationRankReward'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/武道会/武道会正赛排行榜奖励表.xlsx
        GUESSING_PARAMS = ConfData('championship', 'guessParam'),            -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/武道会/武道会参数表.xlsx
        GUESSING_REWARD = ConfData('championship', 'guessMail'),             -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/武道会/武道会竞猜奖励表.xlsx
        SCHEDULE        = ConfData('championship', 'schedule'),              -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/武道会/武道会排期表.xlsx
        TIMELINE        = ConfData('championship', 'timeLine'),              -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/武道会/武道会流程表.xlsx
    },


    -------------------------------------------------
    -- activity pop&pipi
    ACTIVITY_POP = {
        FARM             = ConfData('activity' , 'farm'),
        FARM_LAND        = ConfData('activity' , 'farmLand'),
        FARM_QUEST       = ConfData('activity' , 'farmQuest'),
        FARM_QUEST_CHEST = ConfData('activity' , 'farmQuestChest'),
        FARM_QUEST_TYPE  = ConfData('activity' , 'farmQuestType'),
        FARM_SEED        = ConfData('activity' , 'farmSeed'),
        FARM_STORY       = ConfData('activity' , 'farmStory'),
        FARM_ZONE        = ConfData('activity' , 'farmZone'),
        FARM_BOSS        = ConfData('activity' , 'farmBoss'),
        FARM_BOSS_LIMIT  = ConfData('activity' , 'farmBossLimit'),
    },

    
    -- 葵花宝典
    SUN_FLOWR = {
        STRONGER      = ConfData('common', 'stronger'),
        STRONGER_JUMP = ConfData('common', 'strongerJump'),
        STRONGER_TYPE = ConfData('common', 'strongerType'),
    },


    -------------------------------------------------
    -- anniversary 2020
    ANNIV2020 = {
        BASE_PARMS             = ConfData('anniversary2020', 'parameter'),           -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆参数总表.xlsx
        MALL_GOODS             = ConfData('anniversary2020', 'mall'),                -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆商店表.xlsx
        MALL_LEVEL             = ConfData('anniversary2020', 'mallLevel'),           -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆商店等级表.xlsx
        STORY_CONTENT          = ConfData('anniversary2020', 'story'),               -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆剧情表.xlsx
        STORY_COLLECTION       = ConfData('anniversary2020', 'storyCollection'),     -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆剧情收录表.xlsx
        HANG_REWARDS           = ConfData('anniversary2020', 'hangRewards'),         -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆挂机奖励表.xlsx
        HANG_FORMULA           = ConfData('anniversary2020', 'hangFormula'),         -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆挂机配方表.xlsx
        HANG_MATERIAL_TYPE     = ConfData('anniversary2020', 'hangMaterialType'),    -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆挂机道具类型表.xlsx
        PUZZLE_GAME            = ConfData('anniversary2020', 'puzzle'),              -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年拼图表.xlsx
        PUZZLE_SKILL_UNLOCK    = ConfData('anniversary2020', 'puzzleSkill'),         -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年拼图技能表.xlsx
        PUZZLE_SKILL_DETAIL    = ConfData('anniversary2020', 'cardSkill'),           -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆卡牌技能表.xlsx
        EXPLORE_ENTRANCE       = ConfData('anniversary2020', 'explore'),             -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆爬塔/20周年庆爬塔总表.xlsx
        EXPLORE_QUEST          = ConfData('anniversary2020', 'quest'),               -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆关卡表.xlsx
        EXPLORE_SWEEP          = ConfData('anniversary2020', 'exploreSweep'),        -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆爬塔/20周年庆爬塔扫荡表.xlsx
        EXPLORE_BUFF           = ConfData('anniversary2020', 'exploreBuff'),         -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆爬塔/20周年庆BUFF关.xlsx
        EXPLORE_MONSTER_BOSS   = ConfData('anniversary2020', 'exploreBoss'),         -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆爬塔/20周年庆BOSS关.xlsx
        EXPLORE_MONSTER_NORMAL = ConfData('anniversary2020', 'exploreMonster'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆爬塔/20周年庆小怪关.xlsx
        EXPLORE_MONSTER_ELITE  = ConfData('anniversary2020', 'exploreEliteMonster'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆爬塔/20周年庆精英关.xlsx
        EXPLORE_CHEST          = ConfData('anniversary2020', 'exploreChest'),        -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆爬塔/20周年庆宝箱关.xlsx
        EXPLORE_OPTION         = ConfData('anniversary2020', 'exploreOption'),       -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆爬塔/20周年庆答题关.xlsx
        EXPLORE_RATE           = ConfData('anniversary2020', 'exploreRate'),         -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/活动配表/20周年庆/20周年庆爬塔/20周年庆爬塔概率表.xlsx
    },


    -------------------------------------------------
    -- cat house
    CAT_HOUSE = {
        BASE_PARMS        = ConfData('house', 'parameter'),            -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/御屋参数总表.xlsx
        MALL_INFO         = ConfData('house', 'mall'),                 -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/御屋商店表.xlsx
        LEVEL_INFO        = ConfData('house', 'levelUp'),              -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/御屋等级升级表.xlsx
        EVENT_TYPE        = ConfData('house', 'eventType'),            -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/御屋事件表.xlsx
        TROPHY_INFO       = ConfData('house', 'trophy'),               -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/御屋收藏柜表.xlsx
        AVATAR_ANIMATE    = ConfData('house', 'avatarAnimation'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/御屋avatar动画表.xlsx
        AVATAR_INFO       = ConfData('house', 'avatar'),               -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/御屋avatar信息表.xlsx
        AVATAR_INIT       = ConfData('house', 'avatarInit'),           -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/初始御屋avatar信息表.xlsx
        AVATAR_LOCATION   = ConfData('house', 'avatarLocation'),       -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/御屋avatar位置表.xlsx
        AVATAR_THEME      = ConfData('house', 'avatarTheme'),          -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/御屋avatar主题信息表.xlsx
        AVATAR_THEME_BUFF = ConfData('house', 'avatarThemeBuff'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/御屋avatar主题信息表.xlsx
        CAT_ABILITY       = ConfData('house', 'catAbility'),           -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪能力表.xlsx
        CAT_ACHV          = ConfData('house', 'catAchievement'),       -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪终身成就表.xlsx
        CAT_AGE           = ConfData('house', 'catAge'),               -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪年龄表.xlsx
        CAT_ATTR          = ConfData('house', 'catAttr'),              -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪属性表.xlsx
        CAT_BIRTH         = ConfData('house', 'catBirth'),             -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪生育表.xlsx
        CAT_CAREER_INFO   = ConfData('house', 'catCareer'),            -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪职业表.xlsx
        CAT_CAREER_LEVEL  = ConfData('house', 'catCareerLevel'),       -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪工作职业等级表.xlsx
        CAT_EFFECT        = ConfData('house', 'catEffect'),            -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪效果表.xlsx
        CAT_LIKE_LEVEL    = ConfData('house', 'catFavorabilityLevel'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪好感度经验表.xlsx
        CAT_GENE          = ConfData('house', 'catGene'),              -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪基因表.xlsx
        CAT_GOODS_INFO    = ConfData('house', 'catGoods'),             -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪道具表.xlsx
        CAT_GOODS_GROUP   = ConfData('house', 'catGoodsGroup'),        -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪奖励道具组表.xlsx
        CAT_INIT          = ConfData('house', 'catInit'),              -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪初始表.xlsx
        CAT_PARMS         = ConfData('house', 'catParameter'),         -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪参数表.xlsx
        CAT_RACE          = ConfData('house', 'catRace'),              -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪种族表.xlsx
        CAT_NAME_LIB      = ConfData('house', 'catRandomName'),        -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪随机名字库.xlsx
        CAT_STATUS        = ConfData('house', 'catStatus'),            -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪状态表.xlsx
        CAT_STORY         = ConfData('house', 'catStory'),             -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪剧情文案.xlsx
        CAT_STUDY         = ConfData('house', 'catStudy'),             -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪学习表.xlsx
        CAT_TRIGGER_INFO  = ConfData('house', 'catTrigger'),           -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/触发条件表.xlsx
        CAT_TRIGGER_EVENT = ConfData('house', 'catTriggerEvent'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪触发对应事件表.xlsx
        CAT_WORK          = ConfData('house', 'catWork'),              -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪工作任务表.xlsx
        CAT_JOURNAL       = ConfData('house', 'catJournal'),           -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/御侍之屋/猫咪相关/猫咪日记表.xlsx
    },

    -------------------------------------------------
    -- pet
    PET = {
        PARMS             = ConfData('pet', 'parameter'),              -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/宠物/堕神参数表.xlsx
    },

    -------------------------------------------------
    -- newKofArena
    NEW_KOF = {
        BASE_PARMS = ConfData('newKofArena', 'parameter'),        -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/新天城演武/新天城演武总表.xlsx
        SEGMENT    = ConfData('newKofArena', 'segment'),          -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/新天城演武/新天城演武段位表.xlsx
        REWARDS    = ConfData('newKofArena', 'rewards'),          -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/新天城演武/新天城演武奖励表.xlsx
        CHALLENGE  = ConfData('newKofArena', 'challengeRewards'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/新天城演武/新天城演武周常表.xlsx
    },

    -------------------------------------------------
    -- derivative
    DERIVATIVE = {
        BASE_PARMS = ConfData('derivative', 'parameter'),      -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/实体奖励发放/实物奖励参数表.xlsx
        SUMMARY    = ConfData('derivative', 'summary'),        -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/实体奖励发放/实物奖励总表.xlsx
        REWARDS    = ConfData('derivative', 'rewards'),        -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/实体奖励发放/实物奖励礼包表.xlsx
        EXPRESS    = ConfData('derivative', 'expressService'), -- http://fantang.f3322.net/doc/eater-doc/-/blob/master/数值表/实体奖励发放/快递公司表.xlsx
    },

}
