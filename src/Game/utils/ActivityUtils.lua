--[[
 * author : liuzhipeng
 * descpt : 活动工具类
]]
ActivityUtils = {}

------------ import ------------

------------ import ------------

------------ define ------------

-- activity id
ACTIVITY_ID = {
	TAG_MATCH              = '-6',  -- 天城演武
	LEVEL_ADVANCE_CHEST    = '-8',  -- 进阶等级礼包
	LEVEL_REWARD           = '-9',  -- 等级奖励	
	GROWTH_FUND            = '-12', -- 成长基金
	PAY_LOGIN_REWARD       = '-13', -- 付费签到
	CONTINUOUS_ACTIVE      = '-14', -- 连续活跃活动
	ULTIMATE_BATTLE        = '-15', -- 巅峰对决
    NEW_TAG_MATCH          = '-19', -- 新天城演武
}
-- activity type
ACTIVITY_TYPE = {
	DAILY_BONUS             = '-1',  -- 每日签到
	NOVICE_BONUS            = '-2',  -- 新手15天签到
	FIRST_PAYMENT           = '-3',  -- 首冲礼包
	LEVEL_GIFT              = '-4',  -- 等级礼包
	HONEY_BENTO             = '-5',  -- 爱心便当
	TAG_MATCH               = '-6',  -- 天城演武
	PERMANENT_SINGLE_PAY    = '-7',  -- 新手单笔充值活动
	LEVEL_ADVANCE_CHEST     = '-8',  -- 进阶等级礼包
	LEVEL_REWARD            = '-9',  -- 等级奖励
	DRAW_BASIC_GET          = '-10', -- 基础抽卡
	DRAW_NEWBIE_GET         = '-11', -- 新手抽卡
	GROWTH_FUND             = '-12', -- 成长基金
	PAY_LOGIN_REWARD        = '-13', -- 付费签到
	CONTINUOUS_ACTIVE       = '-14', -- 连续活跃活动
    ULTIMATE_BATTLE         = '-15', -- 巅峰对决
    NOVICE_ACCUMULATIVE_PAY = '-16', -- 新手累计充值
    NOVICE_WELFARE          = '-17', -- 新手福利
    BASIC_SKIN_CAPSULE      = '-18', -- 常驻皮肤卡池
    NEW_TAG_MATCH           = '-19', -- 新天城演武
    FREE_NEWBIE_CAPSULE     = '-20', -- 免费新手抽卡
	LUCKY_WHEEL             = '1',   -- 幸运大转盘
	STORE_OTHER_LIMIT       = '2',   -- 其他商城 限时上架
	STORE_GIFTS_MONEY       = '3',   -- 礼包商城 金钱礼包
	CAPSULE_PROBABILITY_UP  = '4',   -- 召唤概率UP
	SPECIAL_CAPSULE         = '5',   -- 超得（旧）
	ITEMS_EXCHANGE          = '6',   -- 物品兑换
	CYCLIC_TASKS            = '7',   -- 循环任务
	FULL_SERVER             = '9',   -- 全服活动
	COMMON_ACTIVITY         = '10',  -- 通用活动页
	LOBBY_ACTIVITY          = '11',  -- 餐厅节日活动
	LOBBY_ACTIVITY_PREVIEW  = '12',  -- 餐厅节日活动预览
	CHARGE_WHEEL            = '13',  -- 活动转盘
	TAKEAWAY_POINT          = '14',  -- 外卖点活动
	BINGGO                  = '15',  -- 拼图活动
	CHEST_EXCHANGE          = '17',  -- 宝箱兑换活动
	SEASONG_LIVE            = '18',  -- 季活兑换活动
	LOGIN_REWARD            = '19',  -- 登录礼包活动
	CUMULATIVE_RECHARGE     = '21',  -- 累充活动
	CUMULATIVE_CONSUME      = '22',  -- 累消活动
	CV_SHARE                = '23',  -- cv分享活动
	ACTIVITY_QUEST          = '30',  -- 活动副本
	QUESTIONNAIRE           = '31',  -- 调查问卷
	BALLOON                 = '32',  -- 打气球活动
	SINGLE_PAY              = '33',  -- 单笔充值活动
	WEB_ACTIVITY            = '34',  -- 跳转网页活动
	SUMMER_ACTIVITY         = '35',  -- 夏活
	SAIMOE                  = '37',  -- 燃战
	ANNIVERSARY             = '38',  -- 周年庆
	DRAW_TEN_TIMES          = '39',  -- 10连抽卡
	DRAW_SUPER_GET          = '40',  -- 超得抽卡
	DRAW_NINE_GRID          = '41',  -- 九宫抽卡
	LIMIT_AIRSHIP           = '42',  -- 限时空运
	DRAW_EXTRA_DROP         = '44',  -- 10连掉落道具抽卡
	DRAW_LIMIT              = '45',  -- 限次抽卡
	STORE_DIAMOND_LIMIT     = '46',  -- 钻石商城 限时上架
	DRAW_SKIN_POOL          = '47',  -- 皮肤卡池
	DRAW_CARD_CHOOSE        = '48',  -- 选卡卡池
	ACTIVITY_PREVIEW        = '49',  -- 活动预告
	SP_ACTIVITY             = '50',  -- 特殊活动入口
	TEAM_QUEST_ACTIVITY     = '51',  -- 组队本活动
	DOUNBLE_EXP_NORMAL      = '52',  -- 普通本双倍经验活动
	DOUNBLE_EXP_HARD        = '53',  -- 困难本双倍经验活动
	FORTUNE_CAT             = '54',  -- 招财猫
	ARTIFACT_ROAD           = '55',  -- 神器之路
	PT_DUNGEON              = '56',  -- pt本
	ANNIVERSARY_PV          = '58',  -- 周年庆pv
	PASS_TICKET             = '59',  -- pass卡
	DRAW_LUCKY_BAG          = '60',  -- 福袋抽卡
	STEP_SUMMON             = '61',  -- 进阶卡池
	STORE_MEMBER_PACK       = '62',  -- 月卡商城 月卡打包
	DRAW_RANDOM_POOL        = '63',  -- 铸池抽卡
	CASTLE_ACTIVITY         = '64',  -- 古堡迷踪
	EXCHANGE_CARD           = '65',  -- 碎片兑换活动
	KFC_ACTIVITY            = '66',  -- KFC签到活动
	MURDER                  = '67',  -- 杀人案(19夏活)
	UP_PROBABILITY_UP       = '68',  -- UR概率UP
	WISH_TREE               = '69',  -- 祈愿树
	SKIN_CARNIVAL           = '70',  -- 皮肤嘉年华
	BINARY_CHOICE           = '72',  -- 双抉卡池
	ANNIVERSARY19           = '73',  -- 周年庆19
	CARD_VOTE               = '74',  -- 飨灵对决之飨灵投票
	SCRATCHER               = '75',  -- 飨灵刮刮乐
	CV_SHARE2               = '76',  -- cv 分享2
	LUCK_NUMBER             = '77',  -- 幸运数字
	ANNIVERSARY_PV2         = '79',  -- 周年庆pv2
	TIME_LIMIT_UPGRADE_TASK = '80',  -- 限时升级任务
	JUMP_JEWEL              = '81',  -- 塔可跳转活动
	BAR_VISITOR             = '82',  -- 酒吧活动客人
	BAR_FORMULA             = '83',  -- 酒吧活动饮品
	SPRING_ACTIVITY_20      = '84',  -- 20春活
	CHEST_ACTIVITY          = '85',  -- 活动宝箱
	LINK_POP_ACTIVITY       = '86',  -- Pop 联动活动
	-- ALL_ROUND            = '87',  -- 全能活动
	ASSEMBLY_ACTIVITY       = '88',  -- 组合活动
    ANNIVERSARY_20          = '89',  -- 20周年庆
    BATTLE_CARD             = '90',  -- 战牌
    ANNIVERSARY_PV3         = '91',  -- 周年庆pv3
}
-- 嘉年华主题
SKIN_CASRNIVAL_THEME = {
	FAIRY_TALE = 1, -- 童话
	SKIN_20_1  = 2, -- 皮肤嘉年华20_1
	SKIN_20_2  = 3, -- 皮肤嘉年华20_2
	SKIN_21_1  = 4, -- 皮肤嘉年华21_1
}
-- 主题spine路径
THEME_SPINE_PATH = {
	[tostring(SKIN_CASRNIVAL_THEME.FAIRY_TALE)] = 'fairyTale',
	[tostring(SKIN_CASRNIVAL_THEME.SKIN_20_1)] = 'skin_20_1',
	[tostring(SKIN_CASRNIVAL_THEME.SKIN_20_2)] = 'skin_20_2',
	[tostring(SKIN_CASRNIVAL_THEME.SKIN_21_1)] = 'skin_21_1',
}
ActivityQuestType = {
	BATTLE = 1,
	STORY  = 2,
	CHEST  = 3,
	PURE_STORY = 4
}
-- 跳转至活动页面
local JUMP_ACTIVITY_TYPE = {
    [ACTIVITY_TYPE.SUMMER_ACTIVITY]        = true,
    [ACTIVITY_TYPE.ANNIVERSARY]            = true,
    [ACTIVITY_TYPE.CASTLE_ACTIVITY]        = true,
    [ACTIVITY_TYPE.MURDER]                 = true,
    [ACTIVITY_TYPE.ANNIVERSARY19]          = true,
    [ACTIVITY_TYPE.SPRING_ACTIVITY_20]     = true,
    [ACTIVITY_TYPE.SKIN_CARNIVAL]          = true,
    [ACTIVITY_TYPE.PT_DUNGEON]             = true,
    [ACTIVITY_TYPE.LUCK_NUMBER]            = true,
    [ACTIVITY_TYPE.SEASONG_LIVE]           = true,
    [ACTIVITY_TYPE.SAIMOE]                 = true,
    [ACTIVITY_TYPE.FORTUNE_CAT]            = true,
    [ACTIVITY_TYPE.CYCLIC_TASKS]           = true,
    [ACTIVITY_TYPE.BINGGO]                 = true,
    [ACTIVITY_TYPE.LOGIN_REWARD]           = true,
    [ACTIVITY_TYPE.CV_SHARE]               = true,
    [ACTIVITY_TYPE.BALLOON]                = true,
    [ACTIVITY_TYPE.SCRATCHER]              = true,
    [ACTIVITY_TYPE.CV_SHARE2]              = true,
    [ACTIVITY_TYPE.CUMULATIVE_CONSUME]     = true,
    [ACTIVITY_TYPE.JUMP_JEWEL]             = true,
    [ACTIVITY_TYPE.ITEMS_EXCHANGE]         = true,
    [ACTIVITY_TYPE.CHARGE_WHEEL]           = true,
    [ACTIVITY_TYPE.ACTIVITY_QUEST]         = true,
    [ACTIVITY_TYPE.ASSEMBLY_ACTIVITY]      = true,
    [ACTIVITY_TYPE.ANNIVERSARY_20]         = true,
    [ACTIVITY_TYPE.BATTLE_CARD]            = true,
}
-- 跳转至卡池页面
local JUMP_CAPSULE_TYPE = {
    [ACTIVITY_TYPE.DRAW_SUPER_GET]    = true,
    [ACTIVITY_TYPE.DRAW_SKIN_POOL]    = true,
    [ACTIVITY_TYPE.DRAW_CARD_CHOOSE]  = true,
    [ACTIVITY_TYPE.DRAW_LUCKY_BAG]    = true,
    [ACTIVITY_TYPE.UP_PROBABILITY_UP] = true,
    [ACTIVITY_TYPE.BINARY_CHOICE]     = true,
    [ACTIVITY_TYPE.DRAW_RANDOM_POOL]  = true,
    [ACTIVITY_TYPE.DRAW_TEN_TIMES]    = true,
    [ACTIVITY_TYPE.DRAW_EXTRA_DROP]   = true,
    [ACTIVITY_TYPE.DRAW_LIMIT]        = true,
    [ACTIVITY_TYPE.STEP_SUMMON]       = true,
}
-- 跳转至商城页面
local JUMP_STORE_TYPE = {
    [ACTIVITY_TYPE.STORE_GIFTS_MONEY]      = true,
    [ACTIVITY_TYPE.STORE_DIAMOND_LIMIT]    = true,
    [ACTIVITY_TYPE.STORE_MEMBER_PACK]      = true,
}
-- 自定义跳转页面
local JUMP_VIEW_TYPE = {
    [ACTIVITY_TYPE.SUMMER_ACTIVITY]        = true,
    [ACTIVITY_TYPE.ANNIVERSARY]            = true,
    [ACTIVITY_TYPE.CASTLE_ACTIVITY]        = true,
    [ACTIVITY_TYPE.MURDER]                 = true,
    [ACTIVITY_TYPE.ANNIVERSARY19]          = true,
    [ACTIVITY_TYPE.SPRING_ACTIVITY_20]     = true,
    [ACTIVITY_TYPE.SKIN_CARNIVAL]          = true,
    [ACTIVITY_TYPE.ANNIVERSARY_PV]         = true,
    [ACTIVITY_TYPE.ANNIVERSARY_PV2]        = true,
    [ACTIVITY_TYPE.ANNIVERSARY_PV3]        = true,
    [ACTIVITY_TYPE.JUMP_JEWEL]             = true,
    [ACTIVITY_TYPE.ASSEMBLY_ACTIVITY]      = true,
    [ACTIVITY_TYPE.ANNIVERSARY_20]         = true,
    [ACTIVITY_TYPE.BATTLE_CARD]            = true,
}
------------ define ------------

--------------------------------
-- basic method
--------------------------------
--[[
判断活动是否可以跳转
@params activityType string 活动类型
--]]
function ActivityUtils.CanJump( activityType )
    local type = tostring(activityType)
    local canJump = JUMP_ACTIVITY_TYPE[type] or JUMP_CAPSULE_TYPE[type] or JUMP_STORE_TYPE[type]
    return canJump
end
--[[
活动跳转
@params activityData map{
    type         string 活动类型 
    activityId   int    活动id
    fromTime     int    活动开启时间
} 
@params showView     bool   是否直接跳转至该活动主页（仅部分活动支持）
--]]
function ActivityUtils.ActivityJump( activityData, showView )
	app:DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "1008-01" , addition = table.concat({activityData.type , activityData.activityId} , "-")})
    local type = tostring(activityData.type)
    local activityId = checkint(activityData.activityId)
    local fromTime = checkint(activityData.fromTime)
    if showView and JUMP_VIEW_TYPE[type] then
        if type == ACTIVITY_TYPE.SUMMER_ACTIVITY then
            app.summerActMgr:ShowSAHomeUI()
        elseif type == ACTIVITY_TYPE.ANNIVERSARY then
            app.anniversaryMgr:EnterAnniversary()
        elseif type == ACTIVITY_TYPE.CASTLE_ACTIVITY then
            local extraParams = {activityId = activityId, activityType = ACTIVITY_TYPE.CASTLE_ACTIVITY}
            app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'castle.CastleMainMediator', params = extraParams})
        elseif type == ACTIVITY_TYPE.MURDER then
            app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderHomeMediator'})
        elseif type == ACTIVITY_TYPE.ANNIVERSARY19 then
            app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'anniversary19.Anniversary19HomeMediator', params = {activityId = activityId}})
        elseif type == ACTIVITY_TYPE.SPRING_ACTIVITY_20 then
            AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'springActivity20.SpringActivity20HomeMediator', params = {animation = 1}})
        elseif type == ACTIVITY_TYPE.SKIN_CARNIVAL then
            app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'activity.skinCarnival.ActivitySkinCarnivalMediator', params = {activityId = activityId, backMediatorName = 'HomeMediator'}})
        elseif type == ACTIVITY_TYPE.JUMP_JEWEL then
            app:RetrieveMediator("Router"):Dispatch({} , { name ="artifact.JewelCatcherPoolMediator" })
        elseif type == ACTIVITY_TYPE.ASSEMBLY_ACTIVITY then
			DotGameEvent.SendEvent(DotGameEvent.EVENTS.RETURN_BANNER)
            app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'activity.assemblyActivity.AssemblyActivityMediator', params = {activityId = activityId}})
        elseif type == ACTIVITY_TYPE.ANNIVERSARY_20 then
            app.router:Dispatch({name = 'specialActivity.SpActivityMediator'}, {name = 'anniversary20.Anniversary20HomeMediator'})
        elseif type == ACTIVITY_TYPE.BATTLE_CARD then
            app.router:Dispatch({name = "specialActivity.SpActivityMediator"}, {name = "ttGame.TripleTriadGameHomeMediator"})
        end
    elseif JUMP_ACTIVITY_TYPE[type] then
        if ActivityUtils.ACTIVITY_TYPE_DEFINE_ == nil then
            ActivityUtils.ACTIVITY_TYPE_DEFINE_ = require('Game.mediator.specialActivity.SpActivityMediator').ACTIVITY_TYPE_DEFINE
        end
        local spActivityOpenTime = app.gameMgr:GetUserInfo().activityHomeData.spActivityOpenTime
        if ActivityUtils.ACTIVITY_TYPE_DEFINE_[type] and fromTime ~= 0 and spActivityOpenTime and fromTime >= spActivityOpenTime then
            -- 跳转特殊活动
            app:RetrieveMediator("Router"):Dispatch(
                {name = 'HomeMediator'},
                {name = 'specialActivity.SpActivityMediator', params = {activityId = activityId}}
            )
        else
            -- 跳转通用活动
            app:RetrieveMediator('Router'):Dispatch(
                {name = "HomeMediator"},
                {name = "ActivityMediator",params = {activityId = activityId}}
            )
        end
    elseif JUMP_CAPSULE_TYPE[type] then
        app:RetrieveMediator('Router'):Dispatch(
            {name = "HomeMediator"},
            {name = "drawCards.CapsuleNewMediator",params = {activityId = activityId}}
        )
    elseif JUMP_STORE_TYPE[type] then
        local storeType = GAME_STORE_TYPE.DIAMOND
        if type == ACTIVITY_TYPE.STORE_GIFTS_MONEY then
            storeType = GAME_STORE_TYPE.MONTH
        elseif type == ACTIVITY_TYPE.STORE_DIAMOND_LIMIT then
            storeType = GAME_STORE_TYPE.DIAMOND
        elseif type == ACTIVITY_TYPE.STORE_MEMBER_PACK then
            storeType = GAME_STORE_TYPE.GIFTS
        end
        app.uiMgr:showGameStores({storeType = storeType})
    end
end
