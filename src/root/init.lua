---------------------------------------
-- CONSTANTS
---@type cc.size
SizeZero  = readOnly(cc.size(0, 0))
---@type cc.rect
RectZero  = readOnly(cc.rect(0, 0, 0, 0))
---@type cc.p
PointZero = readOnly(cc.p(0, 0))
scheduler = require('cocos.framework.scheduler')

---@return cc.c3b
cc.r3b = function()
    return cc.c3b(math.random(255), math.random(255), math.random(255))
end

---@return cc.c4b
cc.r4b = function(alpha)
    return cc.c4b(math.random(255), math.random(255), math.random(255), alpha or math.random(255))
end

touch_info = {
  touch_x = 0,
  touch_y = 0,
  touch_t = 0
}

profileTimestamp = 0
---------------------------------------

COUNT_DOWN_ACTION = 'COUNT_DOWN_ACTION'
COUNT_DOWN_ACTION_UI = 'COUNT_DOWN_ACTION_UI'
COUNT_DOWN_TAG_AIR_SHIP = 'COUNT_DOWN_TAG_AIR_SHIP'
COUNT_DOWN_TAG_LOBBY_FESTIVAL_ACTIVITY = 'COUNT_DOWN_TAG_LOBBY_FESTIVAL_ACTIVITY'
COUNT_DOWN_TAG_LOBBY_FESTIVAL_PREVIEW_ACTIVITY = 'COUNT_DOWN_TAG_LOBBY_FESTIVAL_PREVIEW_ACTIVITY'
COUNT_DOWN_TAG_UNION_TASK = 'COUNT_DOWN_TAG_UNION_TASK'  -- 标志 工会倒计时
COUNT_DOWN_TAG_WORLD_BOSS = 'COUNT_DOWN_TAG_WORLD_BOSS'
COUNT_DOWN_TAG_3V3_MATCH_BATTLE = 'COUNT_DOWN_TAG_3V3_MATCH_BATTLE'
COUNT_DOWN_TAG_TASTING_TOUR_QUEST = 'COUNT_DOWN_TAG_TASTING_TOUR_QUEST' -- 品鉴之旅 倒计时
COUNT_DOWN_ACTION_UI_ACTION_TASTING_TOUR_QUEST = 'COUNT_DOWN_ACTION_UI_ACTION_TASTING_TOUR_QUEST'  -- 刷新 品鉴之旅 倒计时UI
COUNT_DOWN_TAG_EXPLORE_SYSTEM = 'COUNT_DOWN_TAG_EXPLORE_SYSTEM'
COUNT_DOWN_BACK = 'COUNT_DOWN_BACK' -- 回归福利 倒计时

CARD_LIVE2D_NODE_INIT_ENV  = 'CARD_LIVE2D_NODE_INIT_ENV'
CARD_LIVE2D_NODE_CLEAN_ENV = 'CARD_LIVE2D_NODE_CLEAN_ENV'

FRIEND_ASSISTANCELIST = "FRIEND_ASSISTANCELIST"
FRIEND_REQUEST_ASSISTANCE = "FRIEND_REQUEST_ASSISTANCE"
MARKET_GOODSSALE = 'MARKET_GOODSSALE'
RESTAURANT_TESK_PROGRESS = 'RESTAURANT_TESK_PROGRESS'

FRESH_TAKEAWAY_POINTS = 'FRESH_TAKEAWAY_POINTS'
FRESH_TAKEAWAY_ORDER_POINTS = 'FRESH_TAKEAWAY_ORDER_POINTS'

WIFI_POINTS = 'WIFI_POINTS'

EVENT_GOODS_COUNT_UPDATE = 'EVENT_GOODS_COUNT_UPDATE'
EVENT_APP_STORE_PRODUCTS = 'APP_STORE_PRODUCTS'

GUIDE_STEP_EVENT_SYSTEM = 'GUIDE_STEP_EVENT_SYSTEM'
GUIDE_HANDLE_SYSTEM = 'GUIDE_HANDLE_SYSTEM'
REFRESH_AVATAR_HEAD_EVENT = "REFRESH_AVATAR_HEAD_EVENT"
REFRESH_PLAYERNAME_EVENT =   "REFRESH_PLAYERNAME_EVENT"
REFRESH_MESSAGE_BOARD_EVENT = "REFRESH_MESSAGE_BOARD_EVENT"
REFRESH_FULL_SERVER_EVENT = "REFRESH_FULL_SERVER_EVENT"
REFRESH_ACCUMULATIVE_RECHARGE_EVENT = "REFRESH_ACCUMULATIVE_RECHARGE_EVENT"
REFRESH_ACCUMULATIVE_CONSUME_EVENT = "REFRESH_ACCUMULATIVE_CONSUME_EVENT"
ALREADY_RECEIVE_NEW_YEAR_POINT_EVENT = "ALREADY_RECEIVE_NEW_YEAR_POINT_EVENT"

RELEASE_PRIVACY_POLICY = "RELEASE_PRIVACY_POLICY"

HomeScene_ChangeCenterContainer = 'HomeScene_ChangeCenterContainer'
HomeScene_ChangeCenterContainer_TeamFormation = 'HomeScene_ChangeCenterContainer_TeamFormation'
AvatarScene_ChangeCenterContainer = 'AvatarScene_ChangeCenterContainer'
Event_Story_Missions_Jump = 'Event_Story_Missions_Jump'
EVENT_SHOW_BOSS_DETAIL_VIEW = "EVENT_SHOW_BOSS_DETAIL_VIEW"
EVENT_CHOOSE_A_GOODS_BY_TYPE = 'EVENT_CHOOSE_A_GOODS_BY_TYPE'
EVENT_UPGRADE_PET = 'EVENT_UPGRADE_PET' -- 调出堕神3页签界面
EVENT_UPGRADE_LEVEL = 'EVENT_UPGRADE_LEVEL' -- 堕神升级成功信号
EVENT_UPGRADE_BREAK = 'EVENT_UPGRADE_BREAK' -- 堕神强化成功信号
EVENT_UPGRADE_PROP = 'EVENT_UPGRADE_PROP' -- 堕神洗炼成功信号
EVENT_UPGRADE_EVOLUTION = 'EVENT_UPGRADE_EVOLUTION' -- 堕神洗炼成功信号
-- 抽卡
CAPSULE_CHOOSE_CARDPOOL      = 'CAPSULE_CHOOSE_CARDPOOL'      -- 抽卡卡池选择
CAPSULE_SHOW_CAPSULE_UI      = 'CAPSULE_SHOW_CAPSULE_UI'      -- 显示抽卡UI
CAPSULE_CARDVIEW_BACK        = 'CAPSULE_CARDVIEW_BACK'        -- 卡牌展示页面返回
CAPSULE_ANIMATION_SKIP       = 'CAPSULE_ANIMATION_SKIP'       -- 抽卡动画跳过
CAPSULE_SKIN_COIN_CLICK      = 'CAPSULE_SKIN_COIN_CLICK'      -- 皮肤卡池十连硬币点击信号
CAPSULE_LUCKY_BAG_CARD_CLICK = 'CAPSULE_LUCKY_BAG_CARD_CLICK' -- 福袋卡池卡牌头像点击信号
CAPSULE_LUCKY_BAG_SWITCH_END = 'CAPSULE_LUCKY_BAG_SWITCH_END' -- 福袋卡池切换至选卡页面动作结束信号
CAPSULE_LUCKY_BAG_REPLACE_END = 'CAPSULE_LUCKY_BAG_REPLACE_END' -- 福袋卡池替换卡牌动画结束信号
CAPSULE_LUCKY_BAG_DRAW_END   = 'CAPSULE_LUCKY_BAG_DRAW_END'   -- 福袋卡池抽卡完成信号
CAPSULE_RANDOM_POOL_PREVIEW  = 'CAPSULE_RANDOM_POOL_PREVIEW'  -- 铸池卡池已抽取卡池预览信号
CAPSULE_RANDOM_POOL_REFRESH  = 'CAPSULE_RANDOM_POOL_REFRESH'  -- 铸池卡池刷新信号
CAPSULE_RANDOM_POOL_DRAW     = 'CAPSULE_RANDOM_POOL_DRAW'     -- 铸池卡池兑换奖励信号
CAPSULE_BINARY_CHOICE_CONFIRM    = 'CAPSULE_BINARY_CHOICE_CONFIRM'    -- 双抉卡池选择卡牌信号
CAPSULE_BINARY_CHOICE_ACTION_END = 'CAPSULE_BINARY_CHOICE_ACTION_END' -- 双抉卡池动画结束信号

-- 好友系统
FRIEND_POPUP_DEL_BLACKLIST = "FRIEND_POPUP_DEL_BLACKLIST" -- 移除黑名单
FRIEND_POPUP_ADD_BLACKLIST = "FRIEND_POPUP_ADD_BLACKLIST" -- 添加至黑名单
FRIEND_REFRESH_EDITBOX     = 'FRIEND_REFRESH_EDITBOX'     -- 更新输入框状态
FRIEND_REMARK_UPDATE       = 'FRIEND_REMARK_UPDATE'       -- 好友备注更新
FRIEND_BATTLE_CHOOSE_ENEMY = 'FRIEND_BATTLE_CHOOSE_ENEMY' -- 好友切磋选择对手
-- 永久累充
CUMULATIVE_RECHARGE_CHOICE_REWARD = "CUMULATIVE_RECHARGE_CHOICE_REWARD" -- 选择奖励
-- 世界聊天
CHAT_AUDIO_PLAY = "CHAT_AUDIO_PLAY" -- 语音播放
CHAT_AUDIO_END = "CHAT_AUDIO_END" -- 语音结束
-- 好友餐厅
UPDATE_LOBBY_FRIEND_BUG_STATE = 'UPDATE_LOBBY_FRIEND_BUG_STATE'      -- 更新好友 虫子 和 霸王餐状态
UPDATE_LOBBY_FRIEND_LIST_SELECT_STATE = 'UPDATE_LOBBY_FRIEND_LIST_SELECT_STATE'    -- 更新好友 列表选中状态
FRIEND_UPDATE_LOBBY_FRIEND_BTN_STATE     = 'FRIEND_UPDATE_LOBBY_FRIEND_BTN_STATE' -- 更新 餐厅好友按钮 显示状态
-- 活动副本
ACTIVITY_QUEST_BATTLE_EVENT = 'ACTIVITY_QUEST_BATTLE_EVENT' -- 活动副本进入战斗信号
ACTIVITY_QUEST_STORY_EVENT = 'ACTIVITY_QUEST_STORY_EVENT' -- 活动副本进入剧情信号
ACTIVITY_QUEST_RESET_STORY_EVENT = 'ACTIVITY_QUEST_RESET_STORY_EVENT' -- 活动副本重置剧情信号
ACTIVITY_QUEST_CHEST_DRAW_EVENT = 'ACTIVITY_QUEST_CHEST_DRAW_EVENT' -- 活动副本宝箱信号
ACTIVITY_QUEST_BUY_HP = 'ACTIVITY_QUEST_BUY_HP' -- 活动副本购买体力信号
-- 联动本
POP_TEAM_QUEST_BATTLE_EVENT = 'POP_TEAM_QUEST_BATTLE_EVENT' -- 联动本战斗关卡点击信号
POP_TEAM_QUEST_STORY_EVENT  = 'POP_TEAM_QUEST_STORY_EVENT'  -- 联动本剧情关卡点击信号
POP_TEAM_QUEST_CHEST_EVENT  = 'POP_TEAM_QUEST_CHEST_EVENT'  -- 联动本战斗关卡点击信号
-- 活动
ACTIVITY_WHEEL_EXCHANGE_CLEAR = 'ACTIVITY_WHEEL_EXCHANGE_CLEAR' -- 转盘活动兑换完成信号
ACTIVITY_TAB_CLICK            = 'ACTIVITY_TAB_CLICK'            -- 活动页签点击信号
ACTIVITY_PROP_EXCHANGE_EXIT   = 'ACTIVITY_PROP_EXCHANGE_EXIT'   -- 兑换活动页退出
ACTIVITY_CONTINUOUS_ACTIVE_SUPPLEMENT = 'ACTIVITY_CONTINUOUS_ACTIVE_SUPPLEMENT' -- 连续活跃活动补签信号
ACTIVITY_SKIN_CARNIVAL_FLASH_SALE_CHOOSE_REWRARD = 'ACTIVITY_SKIN_CARNIVAL_FLASH_SALE_CHOOSE_REWRARD' -- 皮肤嘉年华秒杀类型奖励选择信号
ACTIVITY_SKIN_CARNIVAL_ENTER_ACTION_END = 'ACTIVITY_SKIN_CARNIVAL_ENTER_ACTION_END' -- 皮肤嘉年华入口进入动画结束信号
ACTIVITY_SKIN_CARNIVAL_BACK_HOME = 'ACTIVITY_SKIN_CARNIVAL_BACK_HOME' -- 皮肤嘉年华返回入口信号
ACTIVITY_SKIN_CARNIVAL_REFRESH_REMIND_ICON = 'ACTIVITY_SKIN_CARNIVAL_REFRESH_REMIND_ICON' -- 皮肤嘉年华刷新活动主页小红点
--sdk登录成功的逻辑
EVENT_SDK_LOGIN = 'EVENT_SDK_LOGIN'
EVENT_SDK_LOGIN_CANCEL = 'EVENT_SDK_LOGIN_CANCEL'
EVENT_SDK_PAY = 'EVENT_SDK_PAY'

EVENT_CARD_MARRY = 'EVENT_CARD_MARRY' -- 飨灵结婚
--充值成功
EVENT_PAY_MONEY_SUCCESS = 'EVENT_PAY_MONEY_SUCCESS'
EVENT_PAY_MONEY_SUCCESS_UI = 'EVENT_PAY_MONEY_SUCCESS_UI'
-- 商城购买
EVENT_PAY_SKIN_SUCCESS = 'EVENT_SKIN_PAY_SUCCESS'
-- 组队战斗
EVENT_RAID_BATTLE_OVER = 'EVENT_RAID_BATTLE_OVER' -- 组队战斗结束的信号
EVENT_RAID_BATTLE_RESULT = 'EVENT_RAID_BATTLE_RESULT' -- 组队战斗结果的信号
EVENT_RAID_BATTLE_EXIT_TO_TEAM = 'EVENT_RAID_BATTLE_EXIT_TO_TEAM' -- 组队战斗退回组队界面
EVENT_RAID_BATTLE_GAME_RESULT = 'EVENT_RAID_BATTLE_GAME_RESULT' -- 战斗结算成功
EVENT_RAID_UPDATE_PLAYER_LEFT_CHALLENGE_TIMES = 'EVENT_RAID_UPDATE_PLAYER_LEFT_CHALLENGE_TIMES' -- 刷新玩家剩余挑战次数
EVENT_RAID_MEMBER_GET_REWARDS = 'EVENT_RAID_MEMBER_GET_REWARDS' -- 其他玩家结算成功 获得奖励
EVENT_RAID_BATTLE_SCENE_LOADING_OVER = 'EVENT_RAID_BATTLE_SCENE_LOADING_OVER' -- 战斗场景加载完毕
EVENT_RAID_ALL_MEMBER_READY_START_FIGHT = 'EVENT_RAID_ALL_MEMBER_READY_START_FIGHT' -- 全员加载完成 开始战斗
EVENT_RAID_TEAM_DISSOLVE = 'EVENT_RAID_TEAM_DISSOLVE' -- 组队队伍被解散
EVENT_RAID_BATTLE_OVER_AND_WAIT_TEAMMATE = 'EVENT_RAID_BATTLE_OVER_AND_WAIT_TEAMMATE' -- 组队战斗结束并且等待队友
EVENT_RAID_BATTLE_ALL_MEMBER_OVER = 'EVENT_RAID_BATTLE_ALL_MEMBER_OVER' -- 组队战斗全员结束
EVENT_RAID_BATTLE_OVER_FOR_RESULT = 'EVENT_RAID_BATTLE_OVER_FOR_RESULT' -- 组队战斗开始请求结算

-- 同步玩家数据
UPDATE_PLAYER_DATA_REQUEST = 'UPDATE_PLAYER_DATA_REQUEST'    -- 发送同步请求
UPDATE_PLAYER_DATA_RESPONSE = 'UPDATE_PLAYER_DATA_RESPONSE'  -- 接受 同步响应

-- 餐厅活动结束事件
LOBBY_FESTIVAL_ACTIVITY_END                 = 'LOBBY_FESTIVAL_ACTIVITY_END'
-- 更新餐厅活动预览
UPDATE_LOBBY_FESTIVAL_ACTIVITY_PREVIEW_UI   = 'UPDATE_LOBBY_FESTIVAL_ACTIVITY_PREVIEW_UI'
-- 餐厅活动预览结束事件
LOBBY_FESTIVAL_ACTIVITY_PREVIEW_END         = 'LOBBY_FESTIVAL_ACTIVITY_PREVIEW_END'
-- 第一次起演示战斗的本地key
ENTERED_FIRST_P_BATTLE_KEY = 'enteredfirstpbattle'
-- 循环任务活动购买任务点
CYCLICTASKS_BUY_SUCCESS = 'CYCLICTASKS_BUY_SUCCESS'
------------------------------------------------------
------- CommonBuyView
-- 进入
COMMON_BUY_VIEW_ENTER         = 'COMMON_BUY_VIEW_ENTER'
-- 退出
COMMON_BUY_VIEW_EXIT          = 'COMMON_BUY_VIEW_EXIT'
-- 快速完成
COMMON_BUY_VIEW_FAST_COMPLETE = 'COMMON_BUY_VIEW_FAST_COMPLETE'
-- 缴费
COMMON_BUY_VIEW_PAY           = 'COMMON_BUY_VIEW_PAY'
------------------------------------------------------

------------ battle ------------
BATTLE_COMPLETE_RESULT                   = 'BATTLE_COMPLETE_RESULT'
BATTLE_FORCE_BREAK                       = 'BATTLE_FORCE_BREAK'
------------ battle ------------


-------------------------------------------------
-- 老玩家召回
EVENT_REQUEST_RECALLED_H5                = 'EVENT_REQUEST_RECALLED_H5'
RECALL_REWARD_DRAW_UI                    = 'RECALL_REWARD_DRAW_UI'
RECALLED_TASK_DRAW_UI                    = 'RECALLED_TASK_DRAW_UI'
RECALL_MAIN_TIME_UPDATE_EVENT            = 'RECALL_MAIN_TIME_UPDATE_EVENT'
RECALLED_TASK_TIME_UPDATE_EVENT          = 'RECALLED_TASK_TIME_UPDATE_EVENT'
-- 等级提升
EVENT_LEVEL_UP = 'EVENT_LEVEL_UP'


-------------------------------------------------
-- 钓场
FISHERMAN_SWITCH_EVENT                  = 'FISHERMAN_SWITCH_EVENT'  -- 点击钓位上的气泡 点击更换或遣返按钮
FISHERMAN_CLICK_EVENT                   = 'FISHERMAN_CLICK_EVENT'   -- 点击钓手
FISHERMAN_VIGOUR_RECOVER_EVENT          = 'FISHERMAN_VIGOUR_RECOVER_EVENT'  -- 飨灵喂食成功
FISHING_BAIT_APPEND_EVENT               = 'FISHING_BAIT_APPEND_EVENT'   -- 在好友钓场的好友钓位添加钓饵
FISHERMAN_SENT_TO_FRIEND_EVENT          = 'FISHERMAN_SENT_TO_FRIEND_EVENT'  -- 派遣钓手到好友钓场
FISHERMAN_SINGLE_FISHING_END_EVENT      = 'FISHERMAN_SINGLE_FISHING_END_EVENT'  -- 钓手一次钓鱼结束
FISH_FRIEND_CARD_UNLOAD_AND_LOAD_EVENT  = "FISH_FRIEND_CARD_UNLOAD_AND_LOAD_EVENT" -- 卡牌在好友钓场卸下和好友钓场上卡牌
FISH_FRIEND_ADD_CARD_EVENT              = "FISH_FRIEND_ADD_CARD_EVENT"  -- 好友在玩家钓场添加卡牌
FISHERMAN_ALTER_IN_FRIEND_EVENT         = 'FISHERMAN_ALTER_IN_FRIEND_EVENT' --好友钓场的钓手被遣返或者自然下场
FISH_LEVEL_UP_EVENT                     = 'FISH_LEVEL_UP_EVENT' --好友钓场的钓手被遣返或者自然下场
FISHERMAN_SENT_TO_ICEROOM_EVENT         = 'FISHERMAN_SENT_TO_ICEROOM_EVENT' --把钓手送入冰场
FISHING_GROUND_WEATHER_ALTER_EVENT      = 'FISHING_GROUND_WEATHER_ALTER_EVENT' --钓场天气变化
FISH_SYN_BAIT_NUM                       = "FISH_SYN_BAIT_NUM" -- 同步钓饵的数据
FISH_FRIEND_CARD_UNLOAD_EVENT           = "FISH_FRIEND_CARD_UNLOAD_EVENT" -- 同步钓饵的数据
FISHING_BAIT_UNLOAD_EVENT               = "FISHING_BAIT_UNLOAD_EVENT"   -- 卸下钓饵
FISHERMAN_RECALL_EVENT                  = "FISHERMAN_RECALL_EVENT"   -- 召回派遣到好友钓场的钓手

-------------------------------------------------
-- 燃战
SUPPORT_ITEM_SELECTED_EVENT             = 'SUPPORT_ITEM_SELECTED_EVENT'  -- 选择应援道具
SAIMOE_CHANGE_TEAM_MEMBER_EVENT         = 'SAIMOE_CHANGE_TEAM_MEMBER_EVENT'  -- 燃战编辑队伍
SAIMOE_SWEEP_POPUP_SHOWUP_EVENT         = 'SAIMOE_SWEEP_POPUP_SHOWUP_EVENT' -- 显示燃战扫荡界面


-------------------------------------------------
-- 神器之路
ARTIFACT_ROAD_MAP_STAGE_CLICK_EVENT     = 'ARTIFACT_ROAD_MAP_STAGE_CLICK_EVENT' -- 点击神器之路关卡

------------------------------------------------------
-- 工会相关
UNION_JOIN_SUCCESS              = 'UNION_JOIN_SUCCESS'  -- 加入工会成功
CHNAGE_UNION_HEAD_EVENT         = "CHNAGE_UNION_HEAD_EVENT"
CLOSE_PLAYER_HEAD_POPUP_EVENT   = "CLOSE_PLAYER_HEAD_POPUP_EVENT"
UNION_APPLY_EVENT               = "UNION_APPLY_EVENT"  -- 职位变更的通知
UNION_INSIDE_APPLY_EVENT        = "UNION_INSIDE_APPLY_EVENT"  -- 职位变更的通知
UNION_KICK_OUT_EVENT            = "UNION_KICK_OUT_EVENT" -- 踢出工会的通知
CLOSE_PLAYER_HEAD_POPUP_EVENT   = "CLOSE_PLAYER_HEAD_POPUP_EVENT"
UNION_TASK_FINISH_EVENT         = "UNION_TASK_FINISH_EVENT"    -- 工会任务完成
UNION_TASK_REFRESH_EVENT        = "UNION_TASK_REFRESH_EVENT"   -- 刷新工会任务
-- 工会相关
-----------------------------------------------------
-- 包厢
PRIVATEROOM_UPDATE_WALL = 'PRIVATEROOM_UPDATE_WALL'         -- 更新陈列墙状态
PRIVATEROOM_ARRIVAL_ACT_END = 'PRIVATEROOM_ARRIVAL_ACT_END' -- 客人到达动画执行完毕
PRIVATEROOM_LEAVE_ACT_END = 'PRIVATEROOM_LEAVE_ACT_END'     -- 客人离开动画执行完毕
PRIVATEROOM_SERVE_EVENT = 'PRIVATEROOM_SERVE_EVENT'         -- 招待客人
PRIVATEROOM_SERVE_EVENT_END = 'PRIVATEROOM_SERVE_EVENT_END' -- 招待结束
PRIVATEROOM_SERVE_CANCEL = 'PRIVATEROOM_SERVE_CANCEL'       -- 放弃客人
PRIVATEROOM_SWITCH_THEME = 'PRIVATEROOM_SWITCH_THEME'       -- 切换主题
PRIVATEROOM_WAIT_DIALOGUE_END = 'PRIVATEROOM_WAIT_DIALOGUE_END' --  等待对话播放结束
-----------------------------------------------------
---------------------语音下载相关的---------------------
VOICE_DOWNLOAD_EVENT = "VOICE_DOWNLOAD_EVENT" -- 语音下载的事件

---------------------活动红点的内部刷新------------------
ACTIVITY_RED_REGRESH_EVENT = "ACTIVITY_RED_REGRESH_EVENT"

---------------------聊天框的显示------------------
CHAT_PANEL_VISIBLE              = 'CHAT_PANEL_VISIBLE'  -- 设置聊天框的显示
-----------------------周年庆---------------------------
ANNIVERSARY_CHOOSE_RECIPE_EVENT = "ANNIVERSARY_CHOOSE_RECIPE_EVENT"
ANNIVERSARY_CHOOSE_CARD_EVENT   = "ANNIVERSARY_CHOOSE_CARD_EVENT"
ANNIVERSARY_CHANGE_BRANCH_CHAPTERID_EVENT   = "ANNIVERSARY_CHANGE_BRANCH_CHAPTERID_EVENT" -- 刷新支线章节
ANNIVERSARY_CLOSE_PICTH_RECIPE_View_EVENT   = "ANNIVERSARY_CLOSE_PICTH_RECIPE_View_EVENT"
ANNIVERSARY_BGM_EVENT   = "ANNIVERSARY_BGM_EVENT"
---------------------特殊活动---------------------------
SP_ACTIVITY_LOGIN_REWARD_CLICK = 'SP_ACTIVITY_LOGIN_REWARD_CLICK' -- 登录送活动点击回调

---------------------全能王---------------------------
ALL_DRAW_TASK_REWARD_EVENT = "ALL_DRAW_TASK_REWARD_EVENT"


-----------------------商店---------------------------
SHOP_EXIT_SHOP = "SHOP_EXIT_SHOP" -- 退出商城
---------------------钻石商店-------------------------
SHOP_BUY_DIAMOND_EVENT = "SHOP_BUY_DIAMOND_EVENT"  --购买钻石的通知
SHOP_BUY_ACTICITY_DIAMOND_EVENT = "SHOP_BUY_ACTICITY_DIAMOND_EVENT"  --购买钻石的通知
------------------------------------------------------

----------------------古堡活动事件------------------------------
CASTLE_END_EVENT =  "CASTLE_END_EVENT"
----------------------杀人案（新夏活）------------------------------
MURDER_UPGRADE_EVENT = "MURDER_UPGRADE_EVENT"
MURDER_SWEEP_POPUP_SHOWUP_EVENT = "MURDER_SWEEP_POPUP_SHOWUP_EVENT"
MURDER_CLUE_DRAW_EVENT = "MURDER_CLUE_DRAW_EVENT"
MURDER_BOSS_COUNTDOWN_UPDATE = "MURDER_BOSS_COUNTDOWN_UPDATE"
MURDER_PROGRESSBAR_REMINDICON_REFRESH = "MURDER_PROGRESSBAR_REMINDICON_REFRESH"

----------------------------2019 年周年庆-----------------------------------
ANNIVERSARY19_EXPLORE_RESULT_EVENT = "ANNIVERSARY_EXPLORE_RESULT_EVENT"

----------------------------2020 年周年庆-----------------------------------
ANNIVERSARY20_EXPLORE_RESULT_EVENT = "ANNIVERSARY20_EXPLORE_RESULT_EVENT"

---------------------------- 背包 -----------------------------------
BACKPACK_OPTIONAL_OPTIONAL_CHEST_DRAW = 'BACKPACK_OPTIONAL_OPTIONAL_CHEST_DRAW'

ACTIVITY_CHEST_REWARD_EVENT = "ACTIVITY_CHEST_REWARD_EVENT"


-----------------------------------------------------------------

SIGNALNAMES = {
    REFRESH_MAIN_CARD               = HomeScene_ChangeCenterContainer_TeamFormation,
    REFRESH_TAKEAWAY_POINTS         = FRESH_TAKEAWAY_POINTS,
    NEXT_TIME_DATE                  = 'NEXT_TIME_DATE',
    SYNC_ACTIVITY_HOME              = 'SYNC_ACTIVITY_HOME',
    SYNC_PARTY_BASE_TIME            = 'SYNC_PARTY_BASE_TIME',
    SYNC_ACTIVITY_HOME_ICON         = 'SYNC_ACTIVITY_HOME_ICON',
    SYNC_FREE_NEWBIE_CAPSULE_DATA   = 'SYNC_FREE_NEWBIE_CAPSULE_DATA',
    SYNC_DAILY_TASK_CACHE_DATA      = 'SYNC_DAILY_TASK_CACHE_DATA',
    FRESH_DAILY_TASK_VIEW           = 'FRESH_DAILY_TASK_VIEW',
    SYNC_ACHIEVEMENT_CACHE_DATA     = 'SYNC_ACHIEVEMENT_CACHE_DATA',
    FRESH_ACHIEVEMENT_VIEW          = 'FRESH_ACHIEVEMENT_VIEW',
    SYNC_UNION_TASK_CACHE_DATA      = 'SYNC_UNION_TASK_CACHE_DATA',
    FRESH_UNION_TASK_VIEW           = 'FRESH_UNION_TASK_VIEW',
    SYNC_ACTIVITY_PASS_TICKET       = 'SYNC_ACTIVITY_PASS_TICKET',
    SYNC_ACTIVITY_GROWTH_FUND       = 'SYNC_ACTIVITY_GROWTH_FUND',

    FRESH_HOME_ACTIVITY_ICON        = 'FRESH_HOME_ACTIVITY_ICON',
    SYNC_WORLD_BOSS_LIST            = 'SYNC_WORLD_BOSS_LIST',
    FRESH_WORLD_BOSS_MAP_DATA       = 'FRESH_WORLD_BOSS_MAP_DATA',
    FRESH_FREE_NEWBIE_CAPSULE_DATA  = 'FRESH_FREE_NEWBIE_CAPSULE_DATA',
    SYNC_3V3_MATCH_BATTLE_DATA      = 'SYNC_3V3_MATCH_BATTLE_DATA',
    FRESH_3V3_MATCH_BATTLE_DATA     = 'FRESH_3V3_MATCH_BATTLE_DATA',
    CLOSE_3V3_MATCH                 = 'CLOSE_3V3_MATCH',
    REFRESH_HOMEMAP_STORY_LAYER     = 'REFRESH_HOMEMAP_STORY_LAYER',
    SWITCH_HOMEMAP_STATUS           = 'SWITCH_HOMEMAP_STATUS',
    REFRESH_NOT_CLOSE_GOODS_EVENT   = 'REFRESH_NOT_CLOSE_GOODS_EVENT',
    REFRES_LEVEL_CHEST_ICON         = 'REFRES_LEVEL_CHEST_ICON',
    REFRES_SEVENDAY_ICON            = 'REFRES_SEVENDAY_ICON',
    REFRES_LIMIT_GIFT_ICON          = 'REFRES_LIMIT_GIFT_ICON',
    REFRES_ARTIFACT_GUIDE_ICON      = 'REFRES_ARTIFACT_GUIDE_ICON',
    REFRES_HOME_UNLOCK_MODULE       = 'REFRES_HOME_UNLOCK_MODULE',
    REFRES_SUMMER_ACTIVITY_ICON     = 'REFRES_SUMMER_ACTIVITY_ICON',
    REFRES_FIRST_PAY_ICON           = 'REFRES_FIRST_PAY_ICON',
    REFRESH_TIME_LIMIT_UPGRADE_ICON = 'REFRESH_TIME_LIMIT_UPGRADE_ICON',
    BREAK_TO_HOME_MEDIATOR          = 'BREAK_TO_HOME_MEDIATOR',
    ANNIV2020_SHOP_UPGRADE          = 'ANNIV2020_SHOP_UPGRADE',
    
    PlayerLevelUpExchange           = 'PlayerLevelUpExchange',
    Login_Callback                  = "Login_Callback",
    CheckPlay_Callback              = "CheckPlay_Callback",
    Channel_Login_Callback          = 'Channel_Login_Callback',
    Checkin_Callback                = "Checkin_Callback",
    European_Agreement_Callback     = "European_Agreement_Callback",
    GetUserByUdid_Callback          = "GetUserByUdid_Callback",
    Regist_Callback                 = "Regist_Callback",
    CreateRole_Callback             = "CreateRole_Callback",
    RandomRoleName_Callback         = "RandomRoleName_Callback",
    SERVER_APPOINT_Callback         = "SERVER_APPOINT_Callback",
    DailyTask_Message_Callback      = "DailyTask_Message_Callback",
    DailyTask_Get_Callback          = "DailyTask_Get_Callback",
    DailyTask_ActiveGet_Callback    = "DailyTask_ActiveGet_Callback",
    MainTask_Message_Callback       = "MainTask_Message_Callback",
    MainTask_Get_Callback           = "MainTask_Get_Callback",
    BackPack_Name_Callback          = "BackPack_Name_Callback",
    BackPack_SaleGoods_Callback     = "BackPack_SaleGoods_Callback",
    BackPack_UseGoods_Callback      = "BackPack_UseGoods_Callback",
    Updata_BackPack_Callback        = "Updata_BackPack_Callback",
    BACKPACK_GOODS_REFRESH          = "BACKPACK_GOODS_REFRESH",
    TeamFormation_Name_Callback     = "TeamFormation_Name_Callback",
    TeamFormation_UnLock_Callback   = "TeamFormation_UnLock_Callback",
    TeamFormation_switchTeam_Callback= "TeamFormation_switchTeam_Callback",
    Mail_Name_Callback              = "Mail_Name_Callback",
    Mail_Get_Callback               = "Mail_Get_Callback",
    Mail_Delete_Callback            = "Mail_Delete_Callback",
    Announcement_Name_Callback      = "Announcement_Name_Callback",
    DeskDetail_Make_Callback        = "DeskDetail_Make_Callback",
    DeskDetail_Cancel_Callback      = "DeskDetail_Cancel_Callback",
    DeskDetail_Done_Callback        = "DeskDetail_Done_Callback",
    DeskDetail_CancelWait_Callback  = "DeskDetail_CancelWait_Callback",
    DeskDetail_Unlock_Callback      = "DeskDetail_Unlock_Callback",
    DeskDetail_Reward_Callback      = "DeskDetail_Reward_Callback",
    DeskDetail_Learn_Callback       = "DeskDetail_Learn_Callback",
    Assist_Share_Callback           = "Assist_Share_Callback",
    Assist_Assistance_Callback      = "Assist_Assistance_Callback",
    Assist_OrdinarySubmit_Callback  = "Assist_OrdinarySubmit_Callback",
    Assist_HugeSubmit_Callback      = "Assist_HugeSubmit_Callback",
    Assist_Refresh_Callback         = "Assist_Refresh_Callback",
    HANDLER_UPGRADE_LEVEL_POP       = "HANDLER_UPGRADE_LEVEL_POP",

    -- 日本相关
    Japan_Get_User_By_UDID_Callback = "Japan_Get_User_By_UDID_Callback",
    Japan_Login_Callback            = "Japan_Login_Callback",
    Japan_Forget_Code_Callback      = "Japan_Forget_Code_Callback",
    Japan_Forget_Verify_Callback    = "Japan_Forget_Verify_Callback",
    Japan_Forget_Commit_Callback    = "Japan_Forget_Commit_Callback",

    Friend_List_Callback            = "Friend_List_Callback",
    Friend_MessageList_Callback     = "Friend_MessageList_Callback",
    Friend_SendMessage_Callback     = "Friend_SendMessage_Callback",
    Friend_FriendRequest_Callback   = "Friend_FriendRequest_Callback",
    Friend_AddFriend_Callback       = "Friend_AddFriend_Callback",
    Friend_HandleAddFriend_Callback = "Friend_HandleAddFriend_Callback",
    Friend_DelFriend_Callback       = "Friend_DelFriend_Callback",
    Friend_FindFriend_Callback      = "Friend_FindFriend_Callback",
    Friend_AssistanceList_Callback  = "Friend_AssistanceList_Callback",
    Friend_RequestAssistance_Callback = "Friend_RequestAssistance_Callback",
    Friend_Assistance_Callback      = "Friend_Assistance_Callback",
    Friend_RefreshRecmmend_Callback = "Friend_RefreshRecmmend_Callback",
    Friend_EmptyRequest_Callback    = "Friend_EmptyRequest_Callback",
    Friend_PlayerInfo_Callback      = "Friend_PlayerInfo_Callback",
    Friend_PopupAddFriend_Callback  = "Friend_PopupAddFriend_Callback",
    Friend_AddBlacklist_Callback    = "Friend_AddBlacklist_Callback",
    Friend_DelBlacklist_Callback    = "Friend_DelBlacklist_Callback",
    Friend_REMOVE_BUGAT_Callback    = "Friend_REMOVE_BUGAT_Callback",

    Market_Market_Callback            = "Market_Market_CallBack",
    Market_MyMarket_Callback          = "Market_MyMarket_Callback",
    Market_Consignment_Callback       = "Market_Consignment_Callback",
    Market_ConsignmentAgain_Callback  = "Market_ConsignmentAgain_Callback",
    Market_Purchase_Callback          = "Market_Purchase_Callback",
    Market_Draw_Callback              = "Market_Draw_Callback",
    Market_Refresh_Callback           = "Market_Refresh_Callback",
    Market_CancelConSignment_Callback = "Market_CancelConSignment_Callback",
    Market_GetGoodsBack_Callback      = "Market_GetGoodsBack_Callback",
    Market_Close_Callback             = "Market_Close_Callback",

    Exploration_Home_Callback              = "Exploration_Home_Callback",
    Exploration_Enter_Callback             = "Exploration_Enter_Callback",
    Exploration_EnterNextFloor_Callback    = "Exploration_EnterNextFloor_Callback",
    Exploration_Explore_Callback           = "Exploration_Explore_Callback",
    Exploration_Continue_Callback          = "Exploration_Continue_Callback",
    Exploration_DrawBaseReward_Callback    = "Exploration_DrawBaseReward_Callback",
    Exploration_DrawChestReward_Callback   = "Exploration_DrawChestReward_Callback",
    Exploration_ExitExplore_Callback       = "Exploration_ExitExplore_Callback",
    Exploration_ChooseExitExplore_Callback = "Exploration_ChooseExitExplore_Callback",
    Exploration_DiamondRecover_Callback    = "Exploration_DiamondRecover_Callback",
    Exploration_BossDraw_Callback          = "Exploration_BossDraw_Callback",
    Exploration_GetRecord_Callback         = "Exploration_GetRecord_Callback",
    Exploration_BuyBossFightNum_Callback   = "Exploration_BuyBossFightNum_Callback",
    Exploration_AddVigour_Callback         = "Exploration_AddVigour_Callback",

    Rank_Restaurant_Callback                = "Rank_Restaurant_Callback",
    Rank_RestaurantRevenue_Callback         = "Rank_RestaurantRevenue_Callback",
    Rank_Tower_Callback                     = "Rank_Tower_Callback",
    Rank_TowerHistory_Callback              = "Rank_TowerHistory_Callback",
    Rank_ArenaRank_Callback                 = "Rank_ArenaRank_Callback",
    Rank_Airship_Callback                   = "Rank_Airship_Callback",
    Rank_Union_Contribution_Callback        = "Rank_Union_Contribution_Callback",
    Rank_Union_ContributionHistory_Callback = "Rank_Union_ContributionHistory_Callback",
    Rank_Union_GodBeast_Callback            = "Rank_Union_GodBeast_Callback",
    Rank_BOSS_Person_Callback               = "Rank_BOSS_Person_Callback",
    Rank_BOSS_Union_Callback                = "Rank_BOSS_Union_Callback",

    GO_TO_SMELTING_EVENT                     = "GO_TO_SMELTING_EVENT",
    Restaurant_LevelUp_Callback              = "Restaurant_LevelUp_Callback",
    Restaurant_ChooseRestaurantTask_Callback = "Restaurant_ChooseRestaurantTask_Callback",
    Restaurant_drawRestaurantTast_Callback   = "Restaurant_drawRestaurantTast_Callback",
    Restaurant_CancelRestaurantTask_Callback = "Restaurant_CancelRestaurantTask_Callback",
    RESTAURANT_PREVIEW_SUIT                  = "RESTAURANT_PREVIEW_SUIT",
    RESTAURANT_APPLY_SUIT_RESULT             = "RESTAURANT_APPLY_SUIT_RESULT",

    Lobby_Home_Callback             = "Lobby_Home_Callback",
    Lobby_Unlock_Callback           = "Lobby_Unlock_Callback",
    Lobby_LvUp_Callback             = "Lobby_LvUp_Callback",
    Lobby_Draw_Callback             = "Lobby_Draw_Callback",
    Lobby_Quick_Callback            = "Lobby_Quick_Callback",
    Lobby_Cancel_Callback           = "Lobby_Cancel_Callback",
    Lobby_GetOrder_Callback         = "Lobby_GetOrder_Callback",
    Lobby_Submit_Callback           = "Lobby_Submit_Callback",
    Lobby_Eventcancel_Callback      = "Lobby_Eventcancel_Callback",
    Lobby_EventDraw_Callback        = "Lobby_EventDraw_Callback",

    Talent_Talents_Callback         = "Talent_Talents_Callback",
    Talent_LightTalent_Callback     = "Talent_LightTalent_Callback",
    Talent_LevelUp_Callback         = "Talent_LevelUp_Callback",
    Talent_Reset_Callback           = "Talent_Reset_Callback",

    Activity_Home_Callback                     = "Activity_Home_Callback",
    Activity_Newbie15Day_Callback              = "Activity_Newbie15Day_Callback",
    Activity_Draw_Newbie15Day_Callback         = "Activity_Draw_Newbie15Day_Callback",
    Activity_MonthlyLogin_Callback             = "Activity_MonthlyLogin_Callback",
    Activity_Draw_MonthlyLogin_Callback        = "Activity_Draw_MonthlyLogin_Callback",
    Activity_MonthlyLoginWheel_Callback        = "Activity_MonthlyLoginWheel_Callback",
    Activity_Draw_MonthlyLoginWheel_Callback   = "Activity_Draw_MonthlyLoginWheel_Callback",
    Activity_Draw_ExchangeList_Callback        = "Activity_Draw_ExchangeList_Callback",        -- 道具兑换列表
    Activity_Draw_Exchange_Callback            = "Activity_Draw_Exchange_Callback",            -- 兑换道具
    Activity_Draw_SuperPool_Callback           = "Activity_Draw_SuperPool_Callback",           -- 超得卡池
    Activity_Draw_BuySuperPool_Callback        = "Activity_Draw_BuySuperPool_Callback",        -- 购买超得卡池
    Activity_Draw_LoveBento_Callback           = "Activity_Draw_LoveBento_Callback",           -- 领取爱心便当
    Activity_Draw_serverTask_Callback          = "Activity_Draw_serverTask_Callback",          -- 全服任务)
    Activity_Draw_drawServerTask_Callback      = "Activity_Draw_drawServerTask_Callback",      -- 领取全服活动奖励)
    Activity_ChargeWheel_Callback              = "Activity_Charge_Wheel_Callback",             -- 收费转盘
    Activity_Draw_ChargeWheel_Callback         = "Activity_Draw_ChargeWheel_Callback",         -- 收费转盘抽奖
    Activity_Draw_Wheel_Timesrewards_Callback  = "Activity_Draw_Wheel_Timesrewards_Callback",  -- 收费转盘次数领奖
    Activity_CyclicTasks_Callback              = "Activity_CyclicTasks_Callback",              -- 循环任务
    Activity_Buy_CyclicTasks_Callback          = "Activity_Buy_CyclicTasks_Callback",          -- 循环任务购买次数
    Activity_Draw_CyclicTasks_Callback         = "Activity_Draw_CyclicTasks_Callback",         -- 循环任务领奖
    Activity_TakeawayPoint_Callback            = "Activity_TakeawayPoint_Callback",            -- 外卖点活动
    Activity_TaskBinggoList_Callback           = "Activity_TaskBinggoList_Callback",           -- binggo任务
    Activity_DrawBinggoTask_Callback           = "Activity_DrawBinggoTask_Callback",           -- 领取binggo任务奖励
    Activity_BinggoOpen_Callback               = "Activity_BinggoOpen_Callback",               -- 翻开拼图
    Activity_Chest_ExchangeList_Callback       = "Activity_Chest_ExchangeList_Callback",       -- 宝箱兑换活动
    Activity_Chest_Exchange_Callback           = "Activity_Chest_Exchange_Callback",           -- 宝箱兑换活动兑换
    Activity_Login_Reward_Callback             = "Activity_Login_Reward_Callback",             -- 登录礼包活动
    Activity_Draw_Login_Reward_Callback        = "Activity_Draw_Login_Reward_Callback",        -- 登录礼包活动领奖
    Activity_AccumulativePay_Callback          = "Activity_AccumulativePay_Callback",          -- 累充活动
    Activity_AccumulativePay_Home_Callback     = "Activity_AccumulativePay_Home_Callback",     -- 累充活动活动页面home
    Activity_Draw_AccumulativePay_Callback     = "Activity_Draw_AccumulativePay_Callback",     -- 累充活动领奖
    Activity_Quest_Home_Callback               = "Activity_Quest_Home_Callback",               -- 活动副本home
    Activity_Quest_Exchange_Callback           = "Activity_Quest_Exchange_Callback",           -- 活动副本兑换
    Activity_AccumulativeConsume_Callback      = "Activity_AccumulativeConsume_Callback",      -- 累充活动home
    Activity_Draw_AccumulativeConsume_Callback = "Activity_Draw_AccumulativeConsume_Callback", -- 累充活动领奖
    Activity_Questionnaire_Callback            = "Activity_Questionnaire_Callback",            -- 问卷活动home
    Activity_Balloon_Home_Callback             = "Activity_Balloon_Home_Callback",             -- 打气球活动home
    Activity_SinglePay_Home_Callback           = "Activity_SinglePay_Home_Callback",           -- 单笔充值活动home
    Activity_Permanent_Single_Pay_Callback     = "Activity_Permanent_Single_Pay_Callback",     -- 常驻单笔充值home
    Activity_Web_Home_Callback                 = "Activity_Web_Home_Callback",                 -- web跳转活动home


    Collection_CardStoryUnlock_Callback = "Collection_CardStoryUnlock_Callback",
    Collection_CardVoiceUnlock_Callback = "Collection_CardVoiceUnlock_Callback",

    Hero_Compose_Callback           = "Hero_Compose_Callback",
    Hero_LevelUp_Callback           = "Hero_LevelUp_Callback",
    Hero_BusinessSkillUp_Callback   = "Hero_BusinessSkillUp_Callback",
    Hero_OneKeyLevelUp_Callback     = "Hero_OneKeyLevelUp_Callback", -- 一键升级
    Hero_Break_Callback             = "Hero_Break_Callback",
    Hero_SkillUp_Callback           = "Hero_SkillUp_Callback",
    Hero_EquipPet_Callback          = "Hero_EquipPet_Callback",
    Hero_AddVigour_Callback         = "Hero_AddVigour_Callback",
    Hero_EatFood_Callback           = 'Hero_EatFood_Callback',--卡牌喂食精致食物。提升好感度
    Hero_MARRIAGE_CALLBACK          = 'Hero_MARRIAGE_CALLBACK',--卡牌结婚
    Hero_ChooseSkin_Callback        = 'Hero_ChooseSkin_Callback',--卡牌使用皮肤
    Hero_SetSignboard_Callback      = 'Hero_SetSignboard_Callback',--卡牌设置看板娘
    CACHE_MAGIC_INK_UPDATE          = 'CACHE_MAGIC_INK_UPDATE',--购买魔法墨水

    CACHE_MONEY                     = "CACHE_MONEY", --本地缓存信息相关的信息
    CACHE_MONEY_UPDATE_UI           = "CACHE_MONEY_UPDATE_UI", --更新界面的逻辑功能
    CACHE_VIP_LEVEL_UPDATE_UI       = "CACHE_VIP_LEVEL_UPDATE_UI", --更新与vip挂钩的界面更新 (例：有个界面 需要显示 体力的最大购买次数)

    Business_StoveUnlock_Callback   = "Business_StoveUnlock_Callback",
    Business_Message_Callback       = "Business_Message_Callback",
    Business_AssistantSwitch_Callback = "Business_AssistantSwitch_Callback",
    Business_drawRewards_Callback   = "Business_drawRewards_Callback",
    Business_LevelUp_Callback       = "Business_LevelUp_Callback",


    Quest_SwitchCity_Callback       = "Quest_SwitchCity_Callback",
    Quest_SwitchPlayerSkill_Callback= "Quest_SwitchPlayerSkill_Callback",
    Quest_GetCityReward_Callback    = "Quest_GetCityReward_Callback",
    Quest_DrawCityReward_Callback   = "Quest_DrawCityReward_Callback",
    Quest_Sweep_Callback            = "Quest_Sweep_Callback",
    Quest_PurchaseQuestChallengeTime_Callback = "Quest_PurchaseQuestChallengeTime_Callback",
    QUEST_CHALLENGE_TIME_UPDATE     = "QUEST_CHALLENGE_TIME_UPDATE",
    --------------- battle ---------------
    Battle_Quest_At_Callback                        = "Battle_Quest_At_Callback",
    Battle_Quest_Grade_Callback                     = "Battle_Quest_Grade_Callback",
    Battle_Quest_CatchPet_Callback                  = "Battle_Quest_CatchPet_Callback",
    Battle_Lobby_QuestAt_Callback                   = "Battle_Lobby_QuestAt_Callback",
    Battle_Lobby_QuestGrade_Callback                = "Battle_Lobby_QuestGrade_Callback",
    Battle_Restaurant_QuestAt_Callback              = "Battle_Restaurant_QuestAt_Callback",
    Battle_Restaurant_QuestGrade_Callback           = "Battle_Restaurant_QuestGrade_Callback",
    Battle_PlotTask_QuestAt_Callback                = "Battle_PlotTask_QuestAt_Callback",
    Battle_PlotTask_QuestGrade_Callback             = "Battle_PlotTask_QuestGrade_Callback",
    Battle_Branch_QuestAt_Callback                  = "Battle_Branch_QuestGrade_Callback",
    Battle_Branch_QuestGrade_Callback               = "Battle_Branch_QuestGrade_Callback",
    Battle_Takeaway_Robbery_Callback                = "Battle_Takeaway_Robbery_Callback",
    Battle_Takeaway_RobberyResult_Callback          = "Battle_Takeaway_RobberyResult_Callback",
    Battle_Takeaway_RobberyRidicule_Callback        = "Battle_Takeaway_RobberyRidicule_Callback",
    Battle_Exploration_QuestAt_Callback             = "Battle_Exploration_QuestGrade_Callback",
    Battle_Exploration_QuestGrade_Callback          = "Battle_Exploration_QuestGrade_Callback",
    -- local
    Battle_UI_Create_Battle_Ready                   = "Battle_UI_Create_Battle_Ready",
    Battle_UI_Destroy_Battle_Ready                  = "Battle_UI_Destroy_Battle_Ready",
    Battle_Enter                                    = "Battle_Enter",
    Battle_Raid_Enter                               = "Battle_Raid_Enter",
    --------------- battle ---------------
    --icePlace ---
    --
    IcePlace_Home_Callback         = "IcePlace_Home_Callback",
    IcePlace_Unlock_Callback       = "IcePlace_Unlock_Callback",
    IcePlace_AddCard_Callback      = "IcePlace_AddCard_Callback",
    IcePlace_RemoveCardOut_Callback = "IcePlace_RemoveCardOut_Callback",
    ICEROOM_MOVE_EVENT             = "ICEROOM_MOVE_EVENT",
    ICEPLACE_Rewards               = "ICEPLACE_Rewards",
    ICEPLACE_UnLockPosition               = "ICEPLACE_UnLockPosition",
    ICEPLACE_UnLoad               = "ICEPLACE_UnLoad",
    ICEPLACE_ADD_MULTI_CARD = "ICEPLACE_ADD_MULTI_CARD",
    ----   checkpoint comment             -----
    QuestComment_Discuss = "QuestComment_Discuss_Callback",
    QuestComment_DiscussList = "QuestComment_DiscussList_Callback" ,
    QuestComment_DiscussAct  = "QuestComment_DiscussAct_Callback",
    QuestComment_CommentView = "QuestComment_CommentView",
    ---外卖相关--
    SIGNALNAMES_TAKEAWAY_HOME = 'SIGNALNAMES_TAKEAWAY_HOME',
    SIGNALNAMES_TAKEAWAY_UPGRADE_CAR = 'SIGNALNAMES_TAKEAWAY_UPGRADE_CAR',
    SIGNALNAMES_TAKEAWAY_UNLOCK_CAR = 'SIGNALNAMES_TAKEAWAY_UNLOCK_CAR',

    -- 订单奖励领取  --
    LargeAndOrdinary_TakeAwayReward = "LargeAndOrdinary_TakeAwayReward",
    StartDeliveryOrder_Dlivery = "StartDeliveryOrder_Dlivery",
    StartDeliveryOrder_Cancel = "StartDeliveryOrder_Cancel",


    -- 主线剧情任务 --
    Updata_StoryMissions_Mess = 'Updata_StoryMissions_Mess',
    StoryMissions_ChangeCenterContainer = 'StoryMissions_ChangeCenterContainer',
    StoryMissions_List_Callback  = "StoryMissions_List_Callback",
    Story_DrawReward_Callback  = "Story_DrawReward_Callback",
    Story_AcceptMissions_Callback = "Story_AcceptMissions_Callback",
    RegionalMissions_List_Callback  = "RegionalMissions_List_Callback",
    -- Regional_AcceptMissions_Callback = "Regional_AcceptMissions_Callback",
    Story_SubmitMissions_Callback         = "Story_SubmitMissions_Callback",
    Regional_SubmitMissions_Callback      = "Regional_SubmitMissions_Callback",
    RecipeRearch_RecipeStudy = "RecipeRearch_RecipeStudy",
    RecipeRearch_RecipeStudyHome = "RecipeRearch_RecipeStudyHome",

    RobberyView_Name_Callback    = "RobberyView_Name_Callback",
    RobberyResult_Name_Callback  = "RobberyResult_Name_Callback",
    LargeAndOrdinary_TakeAwayOrder = "LargeAndOrdinary_TakeAwayOrder",

    --收到聊天消息
    Chat_GetMessage_Callback = "Chat_GetMessage_Callback",
    Chat_SendMessage_Callback = "Chat_SendMessage_Callback",
    -- 收到私信
    Chat_SendPrivateMessage_Callback = 'Chat_SendPrivateMessage_Callback',
    Chat_GetPrivateMessage_Callback = "Chat_GetPrivateMessage_Callback",
    -- 获取玩家信息
    Chat_GetPlayerInfo_Callback = "Chat_GetPlayerInfo_Callback",
    Chat_Assistance_Callback = "Chat_Assistance_Callback",
    Chat_Report_Callback = "Chat_Report_Callback",
    StartDeliveryOrder_Refuse = "StartDeliveryOrder_Refuse" ,
    RobberyDetailView_Name_Callback = "RobberyDetailView_Name_Callback",
    ---

    RaidDetail_Bulid_Callback  = "RaidDetail_Bulid_Callback",
    RaidDetail_AutoMatching_Callback = "RaidDetail_AutoMatching_Callback",
    RaidDetail_SearchTeam_Callback = "RaidDetail_SearchTeam_Callback",
    RaidMain_BuyAttendTimes_Callback = "RaidMain_BuyAttendTimes_Callback",

    WORLDMAP_UNLOCK_SIGNALS = 'WORLDMAP_UNLOCK_SIGNALS',

    -- 菜谱研发和制作相关的
    RecipeCooking_Study_Callback = "RecipeCooking_Study_Callback" ,  --菜谱开发
    RecipeCooking_Study_Cancel_Callback = "RecipeCooking_Study_Cancel_Callback" , -- 取消菜谱开发
    RecipeCooking_Study_Accelertate_Callback = "RecipeCooking_Study_Accelertate_Callback" , --菜谱开发立即完成
    RecipeCooking_Study_Draw_Callback = "RecipeCooking_Study_Draw_Callback" , --菜谱开发领取奖励
    RecipeCooking_Cooking_Style_Callback = "RecipeCooking_Cooking_Style_Callback" , --烹饪专精解锁
    RecipeCooking_Making_Callback = "RecipeCooking_Making_Callback" , -- 菜谱制作
    RecipeCooking_GradeLevelUp_Callback = "RecipeCooking_GradeLevelUp_Callback" , -- 菜谱升级
    RecipeCooking_Assistant_Switch_Callback = "RecipeCooking_Assistant_Switch_Callback" , --烹饪助手的切换
    RecipeCooking_Home_Callback  = "RecipeCooking_Home_Callback" ,
    RecipeCooking_Magic_Make_Callback = "RecipeCooking_Magic_Make_Callback" ,

    --大堂人员管理
    Lobby_EmployeeSwitch_Callback  = "Lobby_EmployeeSwitch_Callback" ,--主管,初始,服务员更换
    Lobby_EmployeeUnlock_Callback  = "Lobby_EmployeeUnlock_Callback" ,--主管,初始,服务员解锁

    --大堂做菜
    Lobby_RecipeCooking_Callback  = "Lobby_RecipeCooking_Callback" ,--做菜
    Lobby_AccelerateRecipeCooking_Callback  = "Lobby_AccelerateRecipeCooking_Callback" ,--加速做菜
    Lobby_CancelRecipeCooking_Callback  = "Lobby_CancelRecipeCooking_Callback" ,--取消做菜
    Lobby_EmptyRecipe_Callback  = "Lobby_EmptyRecipe_Callback" ,--清空菜谱
    Lobby_RecipeCookingDone_Callback = "Lobby_RecipeCookingDone_Callback",--做菜完成

    --avatar unlock --
    SIGNALNAME_HOME_AVATAR            = 'SIGNALNAME_HOME_AVATAR',
    SIGNALNAME_BUY_AVATAR             = 'SIGNALNAME_BUY_AVATAR',
    SIGNALNAME_UNLOCK_AVATAR          = 'SIGNALNAME_UNLOCK_AVATAR',
    SIGNALNAME_CANCEL_AVATAR_QUEST    = 'SIGNALNAME_CANCEL_AVATAR_QUEST',
    SIGNALNAME_GET_TASK               = 'SIGNALNAME_GET_TASK',
    SIGNALNAME_DRAW_TASK              = 'SIGNALNAME_DRAW_TASK',
    SIGNALNAME_Home_RecipeCookingDone = 'SIGNALNAME_Home_RecipeCookingDone',
    SIGNALNAME_FRIEND_MESSAGEBOOK     = 'SIGNALNAME_FRIEND_MESSAGEBOOK',
    SIGNALNAME_FRIEND_AVATAR_STATE    = 'SIGNALNAME_FRIEND_AVATAR_STATE',
    SIGNALNAME_6001                   = 'SIGNALNAME_6001',
    SIGNALNAME_6002                   = 'SIGNALNAME_6002',
    SIGNALNAME_6003                   = 'SIGNALNAME_6003',
    SIGNALNAME_6004                   = 'SIGNALNAME_6004',
    SIGNALNAME_6005                   = 'SIGNALNAME_6005',
    SIGNALNAME_6006                   = 'SIGNALNAME_6006',
    SIGNALNAME_6007                   = 'SIGNALNAME_6007',
    SIGNALNAME_6008                   = 'SIGNALNAME_6008',
    SIGNALNAME_2027                   = 'SIGNALNAME_2027',
    SIGNALNAME_CLEAN_ALL_AVATAR       = 'SIGNALNAME_CLEAN_ALL_AVATAR',


    --卡牌碎片融合
    CardsFragment_Compose_Callback = 'CardsFragment_Compose_Callback',
    CardsFragment_MultiCompose_Callback = 'CardsFragment_MultiCompose_Callback',

    Material_Compose_Callback = 'Material_Compose_Callback',
    --------------- pet ---------------
    Pet_Develop_Pet_Home_Callback               = 'Pet_Develop_Pet_Home_Callback',
    Pet_Develop_Pet_Pond_Unlock_Callback        = 'Pet_Develop_Pet_Pond_Unlock_Callback',
    Pet_Develop_Pet_Pet_Awaken                  = 'Pet_Develop_Pet_Pet_Awaken',
    Pet_Develop_Pet_Pet_Egg_Into_Pond           = 'Pet_Develop_Pet_Pet_Egg_Into_Pond',
    Pet_Develop_Pet_Pet_Clean                   = 'Pet_Develop_Pet_Pet_Clean',
    Pet_Develop_Pet_Pet_Clean_All               = 'Pet_Develop_Pet_Pet_Clean_All',
    Pet_Develop_Pet_Pet_Egg_Watering            = 'Pet_Develop_Pet_Pet_Egg_Watering',
    Pet_Develop_Pet_AddMagicFoodPond            = 'Pet_Develop_Pet_AddMagicFoodPond',
    Pet_Develop_Pet_Accelerate_Pet_Clean        = 'Pet_Develop_Pet_Accelerate_Pet_Clean',
    Pet_Develop_Pet_PetLock                     = 'Pet_Develop_Pet_PetLock',
    Pet_Develop_Pet_PetUnlock                   = 'Pet_Develop_Pet_PetUnlock',
    Pet_Develop_Pet_PetRelease                  = 'Pet_Develop_Pet_PetRelease',
    Pet_Develop_Pet_PetLevelUp                  = 'Pet_Develop_Pet_PetLevelUp',
    Pet_Develop_Pet_PetBreakUp                  = 'Pet_Develop_Pet_PetBreakUp',
    Pet_Develop_Pet_PetAttributeReset           = 'Pet_Develop_Pet_PetAttributeReset',
    --------------- pet ---------------

    ----------- 飨灵收集奖励 ------------
    CARD_GATHER_AREA_REWARD_CALLBACK            = 'CARD_GATHER_AREA_REWARD_CALLBACK',
    CARD_GATHER_CP_REWARD_CALLBACK              = 'CARD_GATHER_CP_REWARD_CALLBACK',
    ----------- 飨灵收集奖励 ------------
    --------------- pvc ---------------
    PVC_OfflineArena_Home_Callback              = 'PVC_OfflineArena_Home_Callback',
    PVC_OfflineArena_SetDefenseTeam_Callback    = 'PVC_OfflineArena_SetDefenseTeam_Callback',
    PVC_OfflineArena_SetFightTeam_Callback      = 'PVC_OfflineArena_SetFightTeam_Callback',
    PVC_OfflineArena_MatchOpponent_Callback     = 'PVC_OfflineArena_MatchOpponent_Callback',
    PVC_OfflineArena_QuestAt_Callback           = 'PVC_OfflineArena_QuestAt_Callback',
    PVC_OfflineArena_QuestGrade_Callback        = 'PVC_OfflineArena_QuestGrade_Callback',
    PVC_OfflineArena_FirstWinReward_Callback    = 'PVC_OfflineArena_FirstWinReward_Callback',
    PVC_OfflineArena_BuyArenaQuestTimes_Callback= 'PVC_OfflineArena_BuyArenaQuestTimes_Callback',
    PVC_OfflineArena_ArenaRecord                = 'PVC_OfflineArena_ArenaRecord',
    --------------- pvc ---------------

    -------------------------------------------------
    -- 餐厅商城
    Restaurant_Shop_Home_Callback = 'Restaurant_Shop_Home_Callback',
    All_Shop_Buy_Callback = 'All_Shop_Buy_Callback',
    Restaurant_Shop_Refresh_Callback = 'Restaurant_Shop_Refresh_Callback',
    Restaurant_Shop_GetPayOrder_Callback = 'Restaurant_Shop_GetPayOrder_Callback',
    PVC_Shop_Refresh_Callback = 'PVC_Shop_Refresh_Callback',
    PVC_Shop_Home_Callback = 'PVC_Shop_Home_Callback',

    --拳皇商城
    KOF_Shop_Refresh_Callback = 'KOF_Shop_Refresh_Callback',

    -- 家具商场
    SHOP_AVATAR_CALLBACK = 'SHOP_AVATAR_CALLBACK',
    SHOP_AVATAR_BUYAVATAR_CALLBACK = 'SHOP_AVATAR_BUYAVATAR_CALLBACK',
    -------------------------------------------------
    -- 爬塔
    TOWER_QUEST_SET_CARD_TEAM                  = 'TOWER_QUEST_SET_CARD_TEAM',
    TOWER_QUEST_SET_CARD_LIBRARY               = 'TOWER_QUEST_SET_CARD_LIBRARY',
    TOWER_QUEST_SET_BATTLE_RESULT              = 'TOWER_QUEST_SET_BATTLE_RESULT',
    TOWER_QUEST_SELECT_CONTRACT                = 'TOWER_QUEST_SELECT_CONTRACT',
    TOWER_QUEST_MODEL_HISTORY_MAX_FLOOR_CHANGE = 'TOWER_QUEST_MODEL_HISTORY_MAX_FLOOR_CHANGE',
    TOWER_QUEST_MODEL_CURRENT_FLOOR_CHANGE     = 'TOWER_QUEST_MODEL_CURRENT_FLOOR_CHANGE',
    TOWER_QUEST_MODEL_CARD_LIBRARY_CHANGE      = 'TOWER_QUEST_MODEL_CARD_LIBRARY_CHANGE',
    TOWER_QUEST_MODEL_ENTER_LEFT_TIMES_CHANGE  = 'TOWER_QUEST_MODEL_ENTER_LEFT_TIMES_CHANGE',
    TOWER_QUEST_MODEL_TOWER_ENTERED_CHANGE     = 'TOWER_QUEST_MODEL_TOWER_ENTERED_CHANGE',
    TOWER_QUEST_MODEL_UNIT_READIED_CHANGE      = 'TOWER_QUEST_MODEL_UNIT_READIED_CHANGE',
    TOWER_QUEST_MODEL_UNIT_PASSED_CHANGE       = 'TOWER_QUEST_MODEL_UNIT_PASSED_CHANGE',
    TOWER_QUEST_MODEL_UNIT_DEFINE_CHANGE       = 'TOWER_QUEST_MODEL_UNIT_DEFINE_CHANGE',
    TOWER_QUEST_MODEL_UNIT_CONFIG_CHANGE       = 'TOWER_QUEST_MODEL_UNIT_CONFIG_CHANGE',

    -------------------------------------------------
    -- 组队副本
    TEAM_BOSS_SOCKET_CONNECT              = 'TEAM_BOSS_SOCKET_CONNECT',
    TEAM_BOSS_SOCKET_CONNECTED            = 'TEAM_BOSS_SOCKET_CONNECTED',
    TEAM_BOSS_SOCKET_UNEXPECTED           = 'TEAM_BOSS_SOCKET_UNEXPECTED',
    TEAM_BOSS_SOCKET_JOIN_TEAM            = 'TEAM_BOSS_SOCKET_JOIN_TEAM',
    TEAM_BOSS_SOCKET_MEMBER_NOTICE        = 'TEAM_BOSS_SOCKET_MEMBER_NOTICE',
    TEAM_BOSS_SOCKET_CARD_CHANGE          = 'TEAM_BOSS_SOCKET_CARD_CHANGE',
    TEAM_BOSS_SOCKET_CARD_NOTICE          = 'TEAM_BOSS_SOCKET_CARD_NOTICE',
    TEAM_BOSS_SOCKET_CSKILL_CHANGE        = 'TEAM_BOSS_SOCKET_CSKILL_CHANGE',
    TEAM_BOSS_SOCKET_CSKILL_NOTICE        = 'TEAM_BOSS_SOCKET_CSKILL_NOTICE',
    TEAM_BOSS_SOCKET_READY_CHANGE         = 'TEAM_BOSS_SOCKET_READY_CHANGE',
    TEAM_BOSS_SOCKET_READY_NOTICE         = 'TEAM_BOSS_SOCKET_READY_NOTICE',
    TEAM_BOSS_SOCKET_ENTER_BATTLE         = 'TEAM_BOSS_SOCKET_ENTER_BATTLE',
    TEAM_BOSS_SOCKET_ENTER_NOTICE         = 'TEAM_BOSS_SOCKET_ENTER_NOTICE',
    TEAM_BOSS_SOCKET_KICK_MEMBER          = 'TEAM_BOSS_SOCKET_KICK_MEMBER',
    TEAM_BOSS_SOCKET_KICK_NOTICE          = 'TEAM_BOSS_SOCKET_KICK_NOTICE',
    TEAM_BOSS_SOCKET_BATTLE_RESULT        = 'TEAM_BOSS_SOCKET_BATTLE_RESULT',
    TEAM_BOSS_SOCKET_BATTLE_RESULT_NOTICE = 'TEAM_BOSS_SOCKET_BATTLE_RESULT_NOTICE',
    TEAM_BOSS_SOCKET_BOSS_CHANGE          = 'TEAM_BOSS_SOCKET_BOSS_CHANGE',
    TEAM_BOSS_SOCKET_BOSS_NOTICE          = 'TEAM_BOSS_SOCKET_BOSS_NOTICE',
    TEAM_BOSS_SOCKET_EXIT_CHANGE          = 'TEAM_BOSS_SOCKET_EXIT_CHANGE',
    TEAM_BOSS_SOCKET_EXIT_NOTICE          = 'TEAM_BOSS_SOCKET_EXIT_NOTICE',
    TEAM_BOSS_SOCKET_CAPTAIN_CHANGE       = 'TEAM_BOSS_SOCKET_CAPTAIN_CHANGE',
    TEAM_BOSS_SOCKET_CAPTAIN_NOTICE       = 'TEAM_BOSS_SOCKET_CAPTAIN_NOTICE',
    TEAM_BOSS_SOCKET_LOADING_OVER         = 'TEAM_BOSS_SOCKET_LOADING_OVER',
    TEAM_BOSS_SOCKET_LOADING_OVER_NOTICE  = 'TEAM_BOSS_SOCKET_LOADING_OVER_NOTICE',
    TEAM_BOSS_SOCKET_PASSWORD_CHANGE      = 'TEAM_BOSS_SOCKET_PASSWORD_CHANGE',
    TEAM_BOSS_SOCKET_PASSWORD_NOTICE      = 'TEAM_BOSS_SOCKET_PASSWORD_NOTICE',
    TEAM_BOSS_SOCKET_ATTEND_TIMES_BUY     = 'TEAM_BOSS_SOCKET_ATTEND_TIMES_BUY',
    TEAM_BOSS_SOCKET_ATTEND_TIMES_BOUGHT  = 'TEAM_BOSS_SOCKET_ATTEND_TIMES_BOUGHT',
    TEAM_BOSS_SOCKET_TEAM_DISSOLVED       = 'TEAM_BOSS_SOCKET_TEAM_DISSOLVED',
    TEAM_BOSS_SOCKET_TEAM_RECOVER         = 'TEAM_BOSS_SOCKET_TEAM_RECOVER',
    TEAM_BOSS_SOCKET_BATTLE_OVER          = 'TEAM_BOSS_SOCKET_BATTLE_OVER',
    TEAM_BOSS_SOCKET_BATTLE_OVER_NOTICE   = 'TEAM_BOSS_SOCKET_BATTLE_OVER_NOTICE',
    TEAM_BOSS_SOCKET_CHOOSE_REWARD        = 'TEAM_BOSS_SOCKET_CHOOSE_REWARD',
    TEAM_BOSS_SOCKET_CHOOSE_REWARD_NOTICE = 'TEAM_BOSS_SOCKET_CHOOSE_REWARD_NOTICE',
    TEAM_BOSS_MODEL_PASSWORD_CHANGE       = 'TEAM_BOSS_MODEL_PASSWORD_CHANGE',
    TEAM_BOSS_MODEL_CAPTAIN_CHANGE        = 'TEAM_BOSS_MODEL_CAPTAIN_CHANGE',
    TEAM_BOSS_MODEL_BOSS_CHANGE           = 'TEAM_BOSS_MODEL_BOSS_CHANGE',
    TEAM_BOSS_MODEL_CAPTAIN_SKILL_CHANGE  = 'TEAM_BOSS_MODEL_CAPTAIN_SKILL_CHANGE',
    TEAM_BOSS_MODEL_PLAYER_ADD_CHANGE     = 'TEAM_BOSS_MODEL_PLAYER_ADD_CHANGE',
    TEAM_BOSS_MODEL_PLAYER_REMOVE_CHANGE  = 'TEAM_BOSS_MODEL_PLAYER_REMOVE_CHANGE',
    TEAM_BOSS_MODEL_PLAYER_RELEASE_CHANGE = 'TEAM_BOSS_MODEL_PLAYER_RELEASE_CHANGE',
    TEAM_BOSS_MODEL_PLAYER_STATUS_CHANGE  = 'TEAM_BOSS_MODEL_PLAYER_STATUS_CHANGE',
    TEAM_BOSS_MODEL_PLAYER_ATTEND_CHANGE  = 'TEAM_BOSS_MODEL_PLAYER_ATTEND_CHANGE',
    TEAM_BOSS_MODEL_PLAYER_CARD_CHANGE    = 'TEAM_BOSS_MODEL_PLAYER_CARD_CHANGE',

    RobberyOneDetailView_Name_Callback    = "RobberyOneDetailView_Name_Callback" ,
    -- 材料合成
    MaterialCompose_Callback = 'MaterialCompose_Callback',
    RecipeCookingMaking_Callback = 'RecipeCookingMaking_Callback',
    RecipeUnlock_Callback = 'RecipeUnlock_Callback',                                -- 解锁了新菜谱
    -- 工会相关
    UNION_CURRENT_ROOM_MEMBER_ENTER          = 'UNION_CURRENT_ROOM_MEMBER_ENTER',
    UNION_CURRENT_ROOM_MEMBER_LEAVE          = 'UNION_CURRENT_ROOM_MEMBER_LEAVE',
    UNION_OTHER_ROOM_MEMBERS_CHANGE          = 'UNION_OTHER_ROOM_MEMBERS_CHANGE',
    UNION_AVATAR_LOBBY_STATUS_CHANGE         = 'UNION_AVATAR_LOBBY_STATUS_CHANGE',
    UNION_LOBBY_AVATAR_MOVE_SEND             = 'UNION_LOBBY_AVATAR_MOVE_SEND',
    UNION_LOBBY_AVATAR_MOVE_TAKE             = 'UNION_LOBBY_AVATAR_MOVE_TAKE',
    UNION_LOBBY_AVATAR_CHANGE                = 'UNION_LOBBY_AVATAR_CHANGE',
    CAPTCHA_SUCCESS                          = 'CAPTCHA_SUCCESS',
    UNION_IMPEACHMENT_TIMES_RESULT_UPDATE    = 'UNION_IMPEACHMENT_TIMES_RESULT_UPDATE',
    --------------------每次做菜就刷新界面------------------------------


    -----------------料理副本的相关事件-------------------------
    SWITCH_ASSIATANT_EVENT               = 'SWITCH_ASSIATANT_EVENT',
    SUBMIT_THE_DISHES_EVENT              = 'SUBMIT_THE_DISHES_EVENT',              -- 上菜的事件
    SEND_QUEST_COMMENT_EVENT             = 'SEND_QUEST_COMMENT_EVENT',             -- 发送关卡评论的事件
    SEND_KEEP_ON_QUEST_EVENT             = 'SEND_KEEP_ON_QUEST_EVENT',             -- 关卡继续的按钮
    SEND_CURRENT_QUEST_INFO_EVENT        = 'SEND_CURRENT_QUEST_INFO_EVENT',        -- 发送当前的闯关信息
    LOOK_CUISINE_SECRET_EVENT            = 'LOOK_CUISINE_SECRET_EVENT',            -- 发送查看关卡的信息
    SEND_NEXT_SERVING_RECIPE_EVENT       = 'SEND_NEXT_SERVING_RECIPE_EVENT',       -- 发送上下道菜的事件
    TASTING_TOUR_ZONE_REWARD_LAYER_EVENT = 'TASTING_TOUR_ZONE_REWARD_LAYER_EVENT', -- 领取料理副本区域奖励

    -------------------------------------------------
    -- 工会派对
    UNION_PARTY_PREPARE_FOOD_CHANGE          = 'UNION_PARTY_PREPARE_FOOD_CHANGE',
    UNION_PARTY_PREPARE_REFRESH_UI           = 'UNION_PARTY_PREPARE_REFRESH_UI',
    UNION_PARTY_STEP_CHANGE                  = 'UNION_PARTY_STEP_CHANGE',
    UNION_PARTY_PRE_OPENING                  = 'UNION_PARTY_PRE_OPENING',
    UNION_PARTY_BOSS_RESULT_UPDATE           = 'UNION_PARTY_BOSS_RESULT_UPDATE',
    UNION_PARTY_ROLL_RESULT_UPDATE           = 'UNION_PARTY_ROLL_RESULT_UPDATE',
    UNION_PARTY_MODEL_FOOD_SCORE_CHANGE      = 'UNION_PARTY_MODEL_FOOD_SCORE_CHANGE',
    UNION_PARTY_MODEL_GOLD_SCORE_CHANGE      = 'UNION_PARTY_MODEL_GOLD_SCORE_CHANGE',
    UNION_PARTY_MODEL_BOSS_KILL_CHANGE       = 'UNION_PARTY_MODEL_BOSS_KILL_CHANGE',
    UNION_PARTY_MODEL_SELF_PASSED_CHANGE     = 'UNION_PARTY_MODEL_SELF_PASSED_CHANGE',
    UNION_PARTY_MODEL_FOOD_GRADE_SYNC_CHANGE = 'UNION_PARTY_MODEL_FOOD_GRADE_SYNC_CHANGE',

    -------------------------------------------------
    -- 工会战
    UNION_WARS_CLOSE                   = 'UNION_WARS_CLOSE',
    UNION_WARS_COUNTDOWN_UPDATE        = 'UNION_WARS_COUNTDOWN_UPDATE',
    UNION_WARS_TIME_LINE_INDEX_CHANGE  = 'UNION_WARS_TIME_LINE_INDEX_CHANGE',
    UNION_WARS_WATCH_MAP_CAMP_CHANGE   = 'UNION_WARS_WATCH_MAP_CAMP_CHANGE',
    UNION_WARS_WATCH_MAP_PAGE_CHANGE   = 'UNION_WARS_WATCH_MAP_PAGE_CHANGE',
    UNION_WARS_UNION_MAP_MODEL_CHANGE  = 'UNION_WARS_UNION_MAP_MODEL_CHANGE',
    UNION_WARS_ENEMY_MAP_MODEL_CHANGE  = 'UNION_WARS_ENEMY_MAP_MODEL_CHANGE',
    UNION_WARS_EDIT_DEFEND_TEAM_CHANGE = 'UNION_WARS_EDIT_DEFEND_TEAM_CHANGE',
    UNION_WARS_UNION_APPALY_SUCCEED    = 'UNION_WARS_UNION_APPALY_SUCCEED',
    UNION_WARS_ATTACK_START_NOTICE     = 'UNION_WARS_ATTACK_START_NOTICE',
    UNION_WARS_DEFEND_START_NOTICE     = 'UNION_WARS_DEFEND_START_NOTICE',
    UNION_WARS_ATTACK_ENDED_NOTICE     = 'UNION_WARS_ATTACK_ENDED_NOTICE',
    UNION_WARS_DEFEND_ENDED_NOTICE     = 'UNION_WARS_DEFEND_ENDED_NOTICE',

    -------------------------------------------------
    -- 天城演武
    TAG_MATCH_SGL_PLAYER_RANK_CHANGE         = 'TAG_MATCH_SGL_PLAYER_RANK_CHANGE',
    TAG_MATCH_SGL_PLAYER_SHIELD_POINT_CHANGE = 'TAG_MATCH_SGL_PLAYER_SHIELD_POINT_CHANGE',

    -- 钓场
    TAG_FRIEND_FISHERMAN_RECALL_EVENT        = 'TAG_FRIEND_FISHERMAN_RECALL_EVENT',

    -- 生日设置完成
    BIRTHDAY_SET_COMMPLETE                    = 'BIRTHDAY_SET_COMMPLETE',
    FRESH_BLACK_GOLD_COUNT_DOWN_EVENT         = 'FRESH_BLACK_GOLD_COUNT_DOWN_EVENT',


    -------------------------------------------------
    -- 打牌游戏
    TTGAME_BATTLE_CARD_ADD              = 'TTGAME_BATTLE_CARD_ADD',
    TTGAME_SOCKET_CONNECTED             = 'TTGAME_SOCKET_CONNECTED',
    TTGAME_SOCKET_UNEXPECTED            = 'TTGAME_SOCKET_UNEXPECTED',
    TTGAME_SOCKET_NET_LINK              = 'TTGAME_SOCKET_NET_LINK',
    TTGAME_SOCKET_NET_SYNC              = 'TTGAME_SOCKET_NET_SYNC',
    TTGAME_BATTLE_CONNECTED             = 'TTGAME_BATTLE_CONNECTED',
    TTGAME_BATTLE_UNEXPECTED            = 'TTGAME_BATTLE_UNEXPECTED',
    TTGAME_BATTLE_INVALID               = 'TTGAME_BATTLE_INVALID',
    TTGAME_SOCKET_GAME_MATCHED_NOTICE   = 'TTGAME_SOCKET_GAME_MATCHED_NOTICE',
    TTGAME_SOCKET_GAME_ABANDON          = 'TTGAME_SOCKET_GAME_ABANDON',
    TTGAME_SOCKET_GAME_RESULT_NOTICE    = 'TTGAME_SOCKET_GAME_RESULT_NOTICE',
    TTGAME_SOCKET_GAME_PLAY_CARD        = 'TTGAME_SOCKET_GAME_PLAY_CARD',
    TTGAME_SOCKET_GAME_PLAY_CARD_NOTICE = 'TTGAME_SOCKET_GAME_PLAY_CARD_NOTICE',
    TTGAME_SOCKET_PVE_ENTER             = 'TTGAME_SOCKET_PVE_ENTER',
    TTGAME_SOCKET_PVP_MATCH             = 'TTGAME_SOCKET_PVP_MATCH',
    TTGAME_SOCKET_ROOM_ENTER_NOTICE     = 'TTGAME_SOCKET_ROOM_ENTER_NOTICE',
    TTGAME_SOCKET_ROOM_ENTER            = 'TTGAME_SOCKET_ROOM_ENTER',
    TTGAME_SOCKET_ROOM_CREATE           = 'TTGAME_SOCKET_ROOM_CREATE',
    TTGAME_SOCKET_ROOM_READY            = 'TTGAME_SOCKET_ROOM_READY',
    TTGAME_SOCKET_ROOM_READY_NOTICE     = 'TTGAME_SOCKET_ROOM_READY_NOTICE',
    TTGAME_SOCKET_ROOM_LEAVE            = 'TTGAME_SOCKET_ROOM_LEAVE',
    TTGAME_SOCKET_ROOM_LEAVE_NOTICE     = 'TTGAME_SOCKET_ROOM_LEAVE_NOTICE',
    TTGAME_SOCKET_ROOM_MOOD             = 'TTGAME_SOCKET_ROOM_MOOD',
    TTGAME_SOCKET_ROOM_MOOD_NOTICE      = 'TTGAME_SOCKET_ROOM_MOOD_NOTICE',

    -------------------------------------------------
    --- 预设编队
    PRESET_TEAM_SELECT_CARDS            = "PRESET_TEAM_SELECT_CARDS",

    -------------------隐私协议的webview界面事件---------

    PRIVACY_POLICY_WEBVIW_SHOW_EVENT = "PRIVACY_POLICY_WEBVIW_SHOW_EVENT",
    -------------------------------------------------
    --- 红点刷新
    CARD_COLL_RED_DATA_UPDATE           = "UPDATE_CARD_COLL_RED_DATA",
    CARD_COLL_GET_REWARD_HANDLER        = "CARD_COLL_GET_REWARD_HANDLER",
    SKIN_COLL_RED_DATA_UPDATE           = "UPDATE_SKIN_COLL_RED_DATA",
    CARD_SKIN_NEW_GET                   = "CARD_SKIN_NEW_GET",

    --------------------------------------------------
    --- 猫屋事件
    CAT_HOUSE_CHECK_UNLOCKED            = "CAT_HOUSE_CHECK_UNLOCKED",
    CAT_HOUSE_CLICK_MEMBER              = "CAT_HOUSE_CLICK_MEMBER",
    CAT_HOUSE_CLICK_REPAIR_AVATAR       = "CAT_HOUSE_CLICK_REPAIR_AVATAR",        -- 修复家具
    CAT_HOUSE_CLICK_TRIGGER_NODE        = "CAT_HOUSE_CLICK_TRIGGER_NODE",         -- 点击小屋猫咪事件节点
    CAT_HOUSE_CLICK_AVATAR_HANDLR       = "CAT_HOUSE_CLICK_AVATAR_HANDLR",
    CAT_HOUSE_CHANGE_AVATAR_STATUE      = "CAT_HOUSE_CHANGE_AVATAR_STATUE",
    CAT_HOUSE_GET_FRIEND_AVATAR_DATA    = "CAT_HOUSE_GET_FRIEND_AVATAR_DATA",
    CAT_HOUSE_FRIEND_UPDATE_OWNER       = "CAT_HOUSE_FRIEND_UPDATE_OWNER",
    CAT_HOUSE_PREVIEW_SUIT              = "CAT_HOUSE_PREVIEW_SUIT",
    CAT_HOUSE_AVATAR_APPEND             = "CAT_HOUSE_AVATAR_APPEND",              -- 11001 猫屋 添置avatar
    CAT_HOUSE_AVATAR_REMOVE             = "CAT_HOUSE_AVATAR_REMOVE",              -- 11002 猫屋 撤下avatar
    CAT_HOUSE_AVATAR_MOVED              = "CAT_HOUSE_AVATAR_MOVED",               -- 11003 猫屋 移动avatar
    CAT_HOUSE_AVATAR_CLEAR              = "CAT_HOUSE_AVATAR_CLEAR",               -- 11004 猫屋 清空avatar
    CAT_HOUSE_AVATAR_NOTICE             = "CAT_HOUSE_AVATAR_NOTICE",              -- 11007 猫屋 变更avatar
    CAT_HOUSE_MEMBER_LIST               = "CAT_HOUSE_MEMBER_LIST",                -- 11005 猫屋 访客列表
    CAT_HOUSE_MEMBER_VISIT              = "CAT_HOUSE_MEMBER_VISIT",               -- 11006 猫屋 访客来访
    CAT_HOUSE_MEMBER_LEAVE              = "CAT_HOUSE_MEMBER_LEAVE",               -- 11008 猫屋 访客离开
    CAT_HOUSE_MEMBER_HEAD               = "CAT_HOUSE_MEMBER_HEAD",                -- 11011 猫屋 访客改头像
    CAT_HOUSE_MEMBER_BUBBLE             = "CAT_HOUSE_MEMBER_BUBBLE",              -- 11012 猫屋 访客改气泡
    CAT_HOUSE_MEMBER_WALK               = "CAT_HOUSE_MEMBER_WALK",                -- 11010 猫屋 访客移动
    CAT_HOUSE_MEMBER_IDENTITY           = "CAT_HOUSE_MEMBER_IDENTITY",            -- 11013 猫屋 访客改身份
    CAT_HOUSE_INVITE_NOTICE             = "CAT_HOUSE_INVITE_NOTICE",              -- 11014 猫屋 邀请通知
    CAT_HOUSE_SELF_WALK_SEND            = "CAT_HOUSE_SELF_WALK_SEND",             -- 11009 猫屋 移动通知
    CAT_HOUSE_CAT_STATUS_NOTICE         = "CAT_HOUSE_CAT_STATUS_NOTICE",          -- 11015 猫屋 猫咪状态变更
    CAT_HOUSE_ACCEPT_BREED_INVITE       = "CAT_HOUSE_ACCEPT_BREED_INVITE",        -- 11016 猫屋 好友接受生育邀请
    CAT_HOUSE_FAVORIBILITY_NOTICE       = 'CAT_HOUSE_FAVORIBILITY_NOTICE',        -- 11017 猫屋 猫咪好感度变化通知
    CAT_HOUSE_SET_SELECTED_AVATARID     = "CAT_HOUSE_SET_SELECTED_AVATARID",      -- 猫屋设置当前选中的装饰
    CAT_HOUSE_UPDATE_AVATAR_USE_NUM     = "CAT_HOUSE_UPDATE_AVATAR_USE_NUM",      -- 猫屋更新装饰的使用数量
    CAT_HOUSE_ON_UPDATE_EVENT_DATA      = "CAT_HOUSE_ON_UPDATE_EVENT_DATA",       -- 猫屋更新事件列表
    CAT_HOUSE_HOUSE_LEFT_SECONDS_ZERO   = "CAT_HOUSE_HOUSE_LEFT_SECONDS_ZERO",    -- 猫屋生育小屋倒计时结束
    --------------------------------------------------
    --- 猫模块事件
    CAT_MODULE_CAT_MATING_ANSWER     = 'CAT_MODULE_CAT_MATING_ANSWER',     -- 回应配对邀请
    CAT_MODULE_CAT_INTERACTION       = 'CAT_MODULE_CAT_INTERACTION',       -- 好友猫咪交互
    CAT_MODULE_CAT_REFRESH_UPDATE    = 'CAT_MODULE_CAT_REFRESH_UPDATE',    -- 猫咪数据刷新
    CAT_MODULE_CAT_LIFE_ACTION_START = 'CAT_MODULE_CAT_LIFE_ACTION_START', -- 猫咪生活 交互开始
    CAT_MODULE_CAT_LIFE_ACTION_END   = 'CAT_MODULE_CAT_LIFE_ACTION_END',   -- 猫咪生活 交互结束
    CAT_MODULE_CAT_PLAY_REFUSE_ANIM  = 'CAT_MODULE_CAT_PLAY_REFUSE_ANIM',  -- 猫咪生活 拒绝动画
    CAT_MODEL_UPDATE_OUT_COUNT_NUM   = 'CAT_MODEL_UPDATE_OUT_COUNT_NUM',   -- 猫咪更新 外出次数
    CAT_MODEL_UPDATE_OUT_TIMESTAMP   = 'CAT_MODEL_UPDATE_OUT_TIMESTAMP',   -- 猫咪更新 外出时间戳
    CAT_MODEL_UPDATE_AGE             = 'CAT_MODEL_UPDATE_AGE',             -- 猫咪更新 年龄
    CAT_MODEL_UPDATE_GENE            = 'CAT_MODEL_UPDATE_GENE',            -- 猫咪更新 基因
    CAT_MODEL_UPDATE_STUDY_ID        = 'CAT_MODEL_UPDATE_STUDY_ID',        -- 猫咪更新 学习id
    CAT_MODEL_UPDATE_WORK_ID         = 'CAT_MODEL_UPDATE_WORK_ID',         -- 猫咪更新 工作id
    CAT_MODEL_UPDATE_SLEEP_ID        = 'CAT_MODEL_UPDATE_SLEEP_ID',        -- 猫咪更新 睡觉id
    CAT_MODEL_UPDATE_TOILET_ID       = 'CAT_MODEL_UPDATE_TOILET_ID',       -- 猫咪更新 厕所id
    CAT_MODEL_UPDATE_ABILITY_NUM     = 'CAT_MODEL_UPDATE_ABILITY_NUM',     -- 猫咪更新 猫咪能力
    CAT_MODEL_UPDATE_ATTR_NUM        = 'CAT_MODEL_UPDATE_ATTR_NUM',        -- 猫咪更新 猫咪属性
    CAT_MODEL_APPEND_STATE           = 'CAT_MODEL_APPEND_STATE',           -- 猫咪更新 新增状态
    CAT_MODEL_REMOVE_STATE           = 'CAT_MODEL_REMOVE_STATE',           -- 猫咪更新 移除状态
    CAT_MODEL_CLEAN_STATE            = 'CAT_MODEL_CLEAN_STATE',            -- 猫咪更新 清空状态
    CAT_MODEL_UPDATE_ALIVE           = 'CAT_MODEL_UPDATE_ALIVE',           -- 猫咪更新 存活标识
    CAT_MODEL_SWITCH_FACADE          = 'CAT_MODEL_SWITCH_FACADE',          -- 猫咪切换 外观
    CAT_MODEL_CAT_INFO_VIEW_CLOSE    = 'CAT_MODEL_CAT_INFO_VIEW_CLOSE',    -- 猫咪详情页面关闭信号
    --- 猫模块生育事件
    CAT_HOUSE_BREED_LIST_SELECTED         = 'CAT_HOUSE_BREED_LIST_SELECTED',          -- 生育列表选中
    CAT_HOUSE_BREED_LIST_INVITEE_SELECTED = 'CAT_HOUSE_BREED_LIST_INVITEE_SELECTED',  -- 生育列表受邀者选中
    CAT_HOUSE_BREED_PAIRING_CANCEL        = 'CAT_HOUSE_BREED_PAIRING_CANCEL',         -- 生育配对取消
    CAT_HOUSE_BREED_INVITE_SUCCESS        = 'CAT_HOUSE_BREED_INVITE_SUCCESS',         -- 生育邀请成功
    CAT_HOUSE_BREED_REFRESH_CHOICE_VIEW   = 'CAT_HOUSE_BREED_REFRESH_CHOICE_VIEW'     -- 刷新生育选择页面
}

COMMANDS = {
    COMMAND_START_UP_SOCKET         = "COMMAND_START_UP_SOCKET",
    COMMAND_Login                   = "COMMAND_Login",
    COMMAND_Checkin                 = "COMMAND_Checkin",
    COMMAND_European_Agreement      = "COMMAND_European_Agreement",
    COMMAND_CheckPlay               = "COMMAND_CheckPlay",
    COMMAND_SDK_LOGIN               = "COMMAND_SDK_LOGIN",
    COMMAND_GetUserByUdid           = "COMMAND_GetUserByUdid",
    COMMAND_Regist                  = "COMMAND_Regist",
    COMMAND_CreateRole              = "COMMAND_CreateRole",
    COMMAND_RandomRoleName          = "COMMAND_RandomRoleName",
    COMMAND_SERVER_APPOINT          = "COMMAND_SERVER_APPOINT",
    COMMAND_DailyTask               = "COMMAND_DailyTask" ,
    COMMAND_DailyTask_Get           = "COMMAND_DailyTask_Get" ,
    COMMAND_DailyTask_ActiveGet     = "COMMAND_DailyTask_ActiveGet" ,
    COMMAND_MainTask                = "COMMAND_MainTask" ,
    COMMAND_MainTask_Get            = "COMMAND_MainTask_Get" ,
    COMMAND_BackPack                = "COMMAND_BackPack",
    COMMAND_BackPack_Sale           = "COMMAND_BackPack_Sale",
    COMMAND_BackPack_Use            = "COMMAND_BackPack_Use",
    COMMAND_TeamFormation           = "COMMAND_TeamFormation",
    COMMAND_TeamFormation_UnLock    = "COMMAND_TeamFormation_UnLock",
    COMMAND_TeamFormation_switchTeam= "COMMAND_TeamFormation_switchTeam",
    COMMAND_Mail                    = "COMMAND_Mail",
    COMMAND_Mail_Draw               = "COMMAND_Mail_Draw",
    COMMAND_Mail_Delete             = "COMMAND_Mail_Delete",
    COMMAND_Announcement            = "COMMAND_Announcement",
    COMMAND_DeskDetail_Make         = "COMMAND_DeskDetail_Make",
    COMMAND_DeskDetail_Cancel       = "COMMAND_DeskDetail_Cancel",
    COMMAND_DeskDetail_Cancel_Wait  = "COMMAND_DeskDetail_Cancel_Wait",
    COMMAND_DeskDetail_Done         = "COMMAND_DeskDetail_Done",
    COMMAND_DeskDetail_Unlock       = "COMMAND_DeskDetail_Unlock",
    COMMAND_DeskDetail_Reward       = "COMMAND_DeskDetail_Reward",
    COMMAND_DeskDetail_Learn        = "COMMAND_DeskDetail_Learn",
    COMMAND_Assist_Share            = "COMMAND_Assist_Share",
    COMMAND_Assist_OrdinarySubmit   = "COMMAND_Assist_OrdinarySubmit",
    COMMAND_Assist_HugeSubmit       = "COMMAND_Assist_HugeSubmit",
    COMMAND_Assist_assistance       = "COMMAND_Assist_assistance",
    COMMAND_Assist_Refresh          = "COMMAND_Assist_Refresh",

    -- 日本相关
    COMMAND_Japan_Get_User_By_UDID  = "COMMAND_Japan_Get_User_By_UDID",
    COMMAND_Japan_Login             = "COMMAND_Japan_Login",
    COMMAND_Japan_Forget_Code       = "COMMAND_Japan_Forget_Code",
    COMMAND_Japan_Forget_Verify     = "COMMAND_Japan_Forget_Verify",
    COMMAND_Japan_Forget_Commit     = "COMMAND_Japan_Forget_Commit",

    COMMAND_Friend_List             = "COMMAND_Friend_List",
    COMMAND_Friend_MessageList      = "COMMAND_Friend_MessageList",
    COMMAND_Friend_SendMessage      = "COMMAND_Friend_SendMessage",
    COMMAND_Friend_FriendRequest    = "COMMAND_Friend_FriendRequest",
    COMMAND_Friend_AddFriend        = "COMMAND_Friend_AddFriend",
    COMMAND_Friend_HandleAddFriend  = "COMMAND_Friend_HandleAddFriend",
    COMMAND_Friend_DelFriend        = "COMMAND_Friend_DelFriend",
    COMMAND_Friend_FindFriend       = "COMMAND_Friend_FindFriend",
    COMMAND_Friend_AssistanceList   = "COMMAND_Friend_AssistanceList",
    COMMAND_Friend_RequestAssistance = "COMMAND_Friend_RequestAssistance",
    COMMAND_Friend_Assistance       = "COMMAND_Friend_Assistance",
    COMMAND_Friend_RefreshRecmmend  = "COMMAND_Friend_RefreshRecmmend",
    COMMAND_Friend_EmptyRequest     = "COMMAND_Friend_EmptyRequest",
    COMMAND_Friend_PlayerInfo       = "COMMAND_Friend_PlayerInfo",
    COMMAND_Friend_NewPlayerInfo    = "COMMAND_Friend_NewPlayerInfo",
    COMMAND_Friend_PopupAddFriend   = "COMMAND_Friend_PopupAddFriend",
    COMMAND_Friend_AddBlacklist     = "COMMAND_Friend_AddBlacklist",
    COMMAND_Friend_DelBlacklist     = "COMMAND_Friend_DelBlacklist",

    -- 聊天
    COMMAND_Chat_GetPlayInfo = "COMMAND_Chat_GetPlayInfo",
    COMMAND_Chat_Assistance  = "COMMAND_Chat_Assistance",
    COMMAND_Chat_Report      = "COMMAND_Chat_Report",
    COMMAND_Restaurant_LevelUp              = "COMMAND_Restaurant_LevelUp",
    COMMAND_Restaurant_ChooseRestaurantTask = "COMMAND_Restaurant_ChooseRestaurantTask",
    COMMAND_Restaurant_DrawRestaurantTask   = "COMMAND_Restaurant_DrawRestaurantTask",
    COMMAND_Restaurant_CancelRestaurantTask = "COMMAND_Restaurant_CancelRestaurantTask",

    COMMAND_Lobby_Home              = "COMMAND_Lobby_Home",
    COMMAND_Lobby_Unlock            = "COMMAND_Lobby_Unlock",
    COMMAND_Lobby_LvUp              = "COMMAND_Lobby_LvUp",
    COMMAND_Lobby_Draw              = "COMMAND_Lobby_Draw",
    COMMAND_Lobby_Quick             = "COMMAND_Lobby_Quick",
    COMMAND_Lobby_Cancel            = "COMMAND_Lobby_Cancel",
    COMMAND_Lobby_GetOrder          = "COMMAND_Lobby_GetOrder",
    COMMAND_Lobby_Submit            = "COMMAND_Lobby_Submit",
    COMMAND_Lobby_Eventcancel       = "COMMAND_Lobby_Eventcancel",
    COMMAND_Lobby_EventDraw         = "COMMAND_Lobby_EventDraw",

    COMMAND_Market_Market           = "COMMAND_Market_Market",
    COMMAND_Market_MyMarket         = "COMMAND_Market_MyMarket",
    COMMAND_Market_Consignment      = "COMMAND_Market_Consignment",
    COMMAND_Market_ConsignmentAgain = "COMMAND_Market_ConsignmentAgain",
    COMMAND_Market_Purchase         = "COMMAND_Market_Purchase",
    COMMAND_Market_Draw             = "COMMAND_Market_Draw",
    COMMAND_Market_Refresh          = "COMMAND_Market_Refresh",
    COMMAND_Market_Cancel           = "COMMAND_Market_Cancel",
    COMMAND_Market_GetGoodsBack     = "COMMAND_Market_GetGoodsBack",
    COMMAND_Market_Close            = "COMMAND_Market_Close",

    COMMAND_Exploration_Home              = "COMMAND_Exploration_Home",
    COMMAND_Exploration_Enter             = "COMMAND_Exploration_Enter",
    COMMAND_Exploration_EnterNextFloor    = "COMMAND_Exploration_EnterNextFloor",
    COMMAND_Exploration_Explore           = "COMMAND_Exploration_Explore",
    COMMAND_Exploration_Continue          = "COMMAND_Exploration_Continue",
    COMMAND_Exploration_DrawBaseReward    = "COMMAND_Exploration_DrawBaseReward",
    COMMAND_Exploration_DrawChestReward   = "COMMAND_Exploration_DrawChestReward",
    COMMAND_Exploration_ExitExplore       = "COMMAND_Exploration_ExitExplore",
    COMMAND_Exploration_ChooseExitExplore = "COMMAND_Exploration_ChooseExitExplore",
    COMMAND_Exploration_DiamondRecover    = "COMMAND_Exploration_DiamondRecover",
    COMMAND_Exploration_BossDraw          = "COMMAND_Exploration_BossDraw",
    COMMAND_Exploration_GetRecord         = "COMMAND_Exploration_GetRecord",
    COMMAND_Exploration_BuyBossFightNum   = "COMMAND_Exploration_BuyBossFightNum",

    COMMAND_Rank_Restaurant                = "COMMAND_Rank_Restaurant",
    COMMAND_Rank_RestaurantRevenue         = "COMMAND_Rank_RestaurantRevenue",
    COMMAND_Rank_Tower                     = "COMMAND_Rank_Tower",
    COMMAND_Rank_TowerHistory              = "COMMAND_Rank_TowerHistory",
    COMMAND_Rank_ArenaRank                 = "COMMAND_Rank_ArenaRank",
    COMMAND_Rank_Airship                   = "COMMAND_Rank_Airship",
    COMMAND_Rank_Union_Contribution        = "COMMAND_Rank_Union_Contribution",
    COMMAND_Rank_Union_ContributionHistory = "COMMAND_Rank_Union_ContributionHistory",
    COMMAND_Rank_Union_GodBeast            = "COMMAND_Rank_Union_GodBeast",
    COMMAND_Rank_BOSS_Person               = "COMMAND_Rank_BOSS_Person",
    COMMAND_Rank_BOSS_Union                = "COMMAND_Rank_BOSS_Union",



    COMMAND_Talent_Talents          = "COMMAND_Talent_Talents",
    COMMAND_Talent_LightTalent      = "COMMAND_Talent_LightTalent",
    COMMAND_Talent_LevelUp          = "COMMAND_Talent_LevelUp",
    COMMAND_Talent_Reset            = "COMMAND_Talent_Reset",

    COMMAND_Activity_Home                     = "COMMAND_Activity_Home",
    COMMAND_Activity_Newbie15Day              = "COMMAND_Activity_Newbie15Day",
    COMMAND_Activity_Draw_Newbie15Day         = "COMMAND_Activity_Draw_Newbie15Day",
    COMMAND_Activity_monthlyLogin             = "COMMAND_Activity_monthlyLogin",
    COMMAND_Activity_Draw_monthlyLogin        = "COMMAND_Activity_Draw_monthlyLogin",
    COMMAND_Activity_monthlyLoginWheel        = "COMMAND_Activity_monthlyLoginWheel",
    COMMAND_Activity_Draw_monthlyLoginWheel   = "COMMAND_Activity_Draw_monthlyLoginWheel",
    COMMAND_Activity_Draw_exchangeList        = "COMMAND_Activity_Draw_exchangeList",        -- 请求道具兑换列表
    COMMAND_Activity_Draw_exchange            = "COMMAND_Activity_Draw_exchange",            -- 请求兑换道具
    COMMAND_Activity_Draw_superPool           = "COMMAND_Activity_Draw_superPool",           -- 请求超得卡池
    COMMAND_Activity_Draw_buySuperPool        = "COMMAND_Activity_Draw_buySuperPool",        -- 请求购买超得卡池
    COMMAND_Activity_Draw_loveBento           = "COMMAND_Activity_Draw_loveBento",           -- 领取爱心便当
    COMMAND_Activity_Draw_serverTask          = "COMMAND_Activity_Draw_serverTask",          -- 请求全服任务列表
    COMMAND_Activity_Draw_drawServerTask      = "COMMAND_Activity_Draw_drawServerTask",      -- 领取全服活动奖励
    COMMAND_Activity_ChargeWheel              = "COMMAND_Activity_ChargeWheel",              -- 收费转盘
    COMMAND_Activity_Draw_ChargeWheel         = "COMMAND_Activity_Draw_ChargeWheel",         -- 收费转盘抽奖
    COMMAND_Activity_Draw_Wheel_TimesRewards  = "COMMAND_Activity_Draw_Wheel_TimesRewards",  -- 收费转盘次数领奖
    COMMAND_Activity_CyclicTasks              = "COMMAND_Activity_CyclicTasks",              -- 循环任务
    COMMAND_Activity_Buy_CyclicTasks          = "COMMAND_Activity_Buy_CyclicTasks",          -- 循环任务购买次数
    COMMAND_Activity_Draw_CyclicTasks         = "COMMAND_Activity_Draw_CyclicTasks",         -- 循环任务抽奖
    COMMAND_Activity_TakeawayPoint            = "COMMAND_Activity_TakeawayPoint",            -- 外卖点活动
    COMMAND_Activity_TaskBinggoList           = "COMMAND_Activity_TaskBinggoList",           -- binggo任务
    COMMAND_Activity_Draw_BinggoTask          = "COMMAND_Activity_Draw_BinggoTask",          -- 领取binggo任务奖励
    COMMAND_Activity_BinggoOpen               = "COMMAND_Activity_BinggoOpen",               -- 翻开拼图
    COMMAND_Activity_ChestExchangeList        = "COMMAND_Activity_ChestExchangeList",        -- 宝箱兑换活动列表
    COMMAND_Activity_ChestExchange            = "COMMAND_Activity_ChestExchange",            -- 宝箱兑换活动兑换
    COMMAND_Activity_LoginReward              = "COMMAND_Activity_LoginReward",              -- 登录礼包活动
    COMMAND_Activity_Draw_LoginReward         = "COMMAND_Activity_Draw_LoginReward",         -- 登录礼包活动领奖
    COMMAND_Activity_AccumulativePay          = "COMMAND_Activity_AccumulativePay",          -- 累充活动
    COMMAND_Activity_AccumulativePay_Home     = "COMMAND_Activity_AccumulativePay_Home",     -- 累充活动活动页面home
    COMMAND_Activity_Draw_AccumulativePay     = "COMMAND_Activity_Draw_AccumulativePay",     -- 累充活动领奖
    COMMAND_Activity_Quest_Home               = "COMMAND_Activity_Quest_Home",               -- 活动副本home
    COMMAND_Activity_Quest_Exchange           = "COMMAND_Activity_Quest_Exchange",           -- 活动副本兑换
    COMMAND_Activity_AccumulativeConsume      = "COMMAND_Activity_AccumulativeConsume",      -- 累消活动活动页面home
    COMMAND_Activity_AccumulativeConsume_Draw = "COMMAND_Activity_AccumulativeConsume_Draw", -- 累消活动领奖
    COMMAND_Activity_Questionnaire            = "COMMAND_Activity_Questionnaire",            -- 问卷活动home
    COMMAND_Activity_Balloon_Home             = "COMMAND_Activity_Balloon_Home",             -- 打气球活动home
    COMMAND_Activity_SinglePay_Home           = "COMMAND_Activity_SinglePay_Home",           -- 单笔充值活动home
    COMMAND_Activity_Permanent_Single_Pay     = "COMMAND_Activity_Permanent_Single_Pay",     -- 常驻单笔充值home
    COMMAND_Activity_Web_Home                 = "COMMAND_Activity_Web_Home",                 -- web跳转活动home


    COMMAND_Collection_CardVoiceUnlock = "COMMAND_Collection_CardVoiceUnlock",
    COMMAND_Collection_CardStoryUnlock = "COMMAND_Collection_CardStoryUnlock",


    COMMAND_Hero_Compose_Callback   = "COMMAND_Hero_Compose_Callback",
    COMMAND_Hero_LevelUp_Callback   = "COMMAND_Hero_LevelUp_Callback",
    COMMAND_Hero_Break_Callback     = "COMMAND_Hero_Break_Callback",
    COMMAND_Hero_SkillUp_Callback   = "COMMAND_Hero_SkillUp_Callback",
    COMMAND_Hero_EquipPet_Callback   = "COMMAND_Hero_EquipPet_Callback",
    COMMAND_Hero_EatFood             = 'COMMAND_Hero_EatFood',--卡牌喂食精致食物。提升好感度
    COMMAND_HERO_MARRIAGE           = "COMMAND_HERO_MARRIAGE",   --卡牌结婚
    COMMAND_Hero_SetSignboard        = 'COMMAND_Hero_SetSignboard',--设置主页面看板娘
    COMMAND_CACHE_MONEY             = "COMMAND_CACHE_MONEY",


    COMMAND_Business_StoveUnlock    = "COMMAND_Business_StoveUnlock",
    COMMAND_Business_Message        = "COMMAND_Business_Message",
    COMMAND_Business_AssistantSwitch= "COMMAND_Business_AssistantSwitch",
    COMMAND_Business_drawRewards    = "COMMAND_Business_drawRewards",
    COMMAND_Business_LevelUp        = "COMMAND_Business_LevelUp",


    COMMAND_TakeAway_AssistantSwitch = 'COMMAND_TakeAway_AssistantSwitch',
    COMMAND_Lobby_AssistantSwitch   = 'COMMAND_Lobby_AssistantSwitch',

    COMMAND_Quest_SwitchCity        = "COMMAND_Quest_SwitchCity",
    COMMAND_Quest_SwitchPlayerSkill = "COMMAND_Quest_SwitchPlayerSkill",
    COMMAND_Quest_Get_City_Reward   = "COMMAND_Get_City_Reward",
    COMMAND_Quest_Draw_City_Reward  = "COMMAND_Quest_Draw_City_Reward",
    COMMAND_Quest_Sweep             = "COMMAND_Quest_Sweep",
    COMMAND_Quest_PurchaseQuestChallengeTime = "COMMAND_Quest_PurchaseQuestChallengeTime",
    --------------- battle ---------------
    COMMANDS_Battle_Quest_At                            = "COMMANDS_Battle_Quest_At",
    COMMANDS_Battle_Quest_Grade                         = "COMMANDS_Battle_Quest_Grade",
    COMMANDS_Battle_Quest_CatchPet                      = "COMMANDS_Battle_Quest_CatchPet",
    COMMANDS_Battle_Lobby_QuestAt                       = "COMMANDS_Battle_QuestAt",
    COMMANDS_Battle_Lobby_QuestGrade                    = "COMMANDS_Battle_Lobby_QuestGrade",
    COMMANDS_Battle_Restaurant_QuestAt                  = "COMMANDS_Battle_Restaurant_QuestAt",
    COMMANDS_Battle_Restaurant_QuestGrade               = "COMMANDS_Battle_Restaurant_QuestGrade",
    COMMANDS_Battle_PlotTask_QuestAt                    = "COMMANDS_Battle_PlotTask_QuestAt",
    COMMANDS_Battle_PlotTask_QuestGrade                 = "COMMANDS_Battle_PlotTask_QuestGrade",
    COMMANDS_Battle_Branch_QuestAt                      = "COMMANDS_Battle_Branch_QuestAt",
    COMMANDS_Battle_Branch_QuestGrade                   = "COMMANDS_Battle_Branch_QuestGrade",
    COMMANDS_Battle_Takeaway_Robbery                    = "COMMANDS_Battle_Takeaway_Robbery",
    COMMANDS_Battle_Takeaway_RobberyResult              = "COMMANDS_Battle_Takeaway_RobberyResult",
    COMMANDS_Battle_Takeaway_RobberyRidicule            = "COMMANDS_Battle_Takeaway_RobberyRidicule",
    COMMANDS_Battle_Exploration_QuestAt                 = "COMMANDS_Battle_Exploration_QuestAt",
    COMMANDS_Battle_Exploration_QuestGrade              = "COMMANDS_Battle_Exploration_QuestGrade",
    COMMANDS_Battle_Start_Socket                        = "COMMANDS_Battle_Start_Socket",
    --------------- battle ---------------
    --icePlace --
    COMMANDS_ICEPLACE = "COMMANDS_ICEPLACE",
    COMMANDS_ICEPLACE_HOME = "COMMANDS_ICEPLACE_HOME",
    COMMANDS_TAKEAWAY = "COMMANDS_TAKEAWAY",

    ----   checkpoint comment             -----
    COMMANDS_QuestComment_Disscuss = "COMMANDS_QuestComment_Disscuss",
    COMMANDS_QuestComment_DisscussList = "COMMANDS_QuestComment_DisscussList",
    COMMANDS_QuestComment_DisscussAct  = "COMMANDS_QuestComment_DisscussAct",

    -- 外面订单的领取
    COMMANDS_LargeAndOrdinary_TakeAwayReward = "COMMANDS_LargeAndOrdinary_TakeAwayReward",
    COMMANDS_StartDeliveryOrder_Dlivery = "COMMANDS_StartDeliveryOrder_Dlivery",
    COMMANDS_StartDeliveryOrder_Cancel  = "COMMANDS_StartDeliveryOrder_Cancel",

    COMMAND_StoryMissions_List           = "COMMAND_StoryMissions_List",
    COMMAND_Story_AcceptMissions         = "COMMAND_Story_AcceptMissions",
    COMMAND_Story_DrawReward             = "COMMAND_Story_DrawReward",
    COMMAND_Regional_DrawReward          = "COMMAND_Regional_DrawReward",
    COMMAND_RegionalMissions_List        = "COMMAND_RegionalMissions_List",
    COMMAND_Regional_AcceptMissions      = "COMMAND_Regional_AcceptMissions",
    COMMAND_Story_SubmitMissions         = "COMMAND_Story_SubmitMissions",
    COMMAND_Regional_SubmitMissions      = "COMMAND_Regional_SubmitMissions",
    COMMANDS_RecipeRearch_RecipeStudy    = "COMMANDS_RecipeRearch_RecipeStudy",
    COMMANDS_RecipeRearch_RecipeStudyHome = "COMMANDS_RecipeRearch_RecipeStudyHome",

    COMMAND_RobberyView_Name_Callback    = "COMMAND_RobberyView_Name_Callback",
    COMMAND_RobberyResult_Name_Callback  = "COMMAND_RobberyResult_Name_Callback",
    COMMANDS_LargeAndOrdinary_TakeAwayOrder = "COMMANDS_LargeAndOrdinary_TakeAwayOrder",
    COMMANDS_StartDeliveryOrder_Refuse  = "COMMANDS_StartDeliveryOrder_Refuse" ,
    COMMAND_RobberyDetailView_Name_Callback = "COMMAND_RobberyDetailView_Name_Callback",

    COMMAND_RaidDetail_Bulid   = "COMMAND_RaidDetail_Bulid",
    COMMAND_RaidDetail_AutoMatching = "COMMAND_RaidDetail_AutoMatching",
    COMMAND_RaidDetail_SearchTeam = "COMMAND_RaidDetail_SearchTeam",
    COMMAND_RaidMain_BuyAttendTimes = "COMMAND_RaidMain_BuyAttendTimes",

    COMMAND_WOLDMAP_UNLOCK = 'COMMAND_WOLDMAP_UNLOCK',

        -- 菜谱研发和制作相关的
    COMMANDS_RecipeCooking_Study_Callback = "COMMANDS_RecipeCooking_Study_Callback" ,  --菜谱开发
    COMMANDS_RecipeCooking_Study_Cancel_Callback = "COMMANDS_RecipeCooking_Study_Cancel_Callback" , -- 取消菜谱开发
    COMMANDS_RecipeCooking_Study_Accelertate_Callback = "COMMANDS_RecipeCooking_Study_Accelertate_Callback" , --菜谱开发立即完成
    COMMANDS_RecipeCooking_Study_Draw_Callback = "COMMANDS_RecipeCooking_Study_Draw_Callback" , --菜谱开发领取奖励
    COMMANDS_RecipeCooking_Cooking_Style_Callback = "COMMANDS_RecipeCooking_Cooking_Style_Callback" , --烹饪专精解锁
    COMMANDS_RecipeCooking_Making_Callback = "COMMANDS_RecipeCooking_Making_Callback" , -- 菜谱制作
    COMMANDS_RecipeCooking_GradeLevelUp_Callback = "COMMANDS_RecipeCooking_GradeLevelUp_Callback" , -- 菜谱升级
    COMMANDS_RecipeCooking_Assistant_Switch_Callback = "COMMANDS_RecipeCooking_Assistant_Switch_Callback" , --烹饪助手的切换
    COMMANDS_RecipeCooking_Home_Callback = "COMMANDS_RecipeCooking_Home_Callback",
    COMMANDS_RecipeCooking_Magic_Make_Callback = "COMMANDS_RecipeCooking_Magic_Make_Callback",

    COMMANDS_Lobby_EmployeeSwitch  = "COMMANDS_Lobby_EmployeeSwitch",
    COMMANDS_Lobby_EmployeeUnlock  = "COMMANDS_Lobby_EmployeeUnlock" ,--主管,初始,服务员解锁

    COMMANDS_Lobby_RecipeCooking  = "COMMANDS_Lobby_RecipeCooking" ,--做菜
    COMMANDS_Lobby_AccelerateRecipeCooking  = "COMMANDS_Lobby_AccelerateRecipeCooking" ,--加速做菜
    COMMANDS_Lobby_CancelRecipeCooking  = "COMMANDS_Lobby_CancelRecipeCooking" ,--取消做菜
    COMMANDS_Lobby_EmptyRecipe  = "COMMANDS_Lobby_EmptyRecipe" ,--清空菜谱
    COMMANDS_Lobby_RecipeCookingDone = "COMMANDS_Lobby_RecipeCookingDone",--(做菜完成

    COMMAND_WOLDMAP_UNLOCK = 'COMMAND_WOLDMAP_UNLOCK',
    --添加餐厅的请求的逻辑
    COMMAND_HOME_AVATAR = 'COMMAND_HOME_AVATAR',
    COMMAND_BUY_AVATAR = 'COMMAND_BUY_AVATAR',
    COMMAND_GET_TASK = 'COMMAND_GET_TASK',
    COMMAND_DRAW_TASK = 'COMMAND_DRAW_TASK',
    COMMAND_UNLOCK_AVATAR = 'COMMAND_UNLOCK_AVATAR',
    COMMAND_FEED_AVATAR = 'COMMAND_FEED_AVATAR',
    COMMAND_CANCEL_QUEST = 'COMMAND_CANCEL_QUEST',
    COMMANDS_Home_RecipeCookingDone = 'COMMANDS_Home_RecipeCookingDone',
    COMMANDS_FRIEND_MESSAGEBOOK = 'COMMANDS_FRIEND_MESSAGEBOOK',


    COMMANDS_CardsFragment_Compose = 'COMMANDS_CardsFragment_Compose',
    COMMANDS_CardsFragment_MultiCompose = 'COMMANDS_CardsFragment_MultiCompose',

    COMMANDS_Material_Compose = 'COMMANDS_Material_Compose',
    --------------- pet ---------------
    COMMANDS_Pet_Develop_Pet_Home                   = 'COMMANDS_Pet_Develop_Pet_Home',
    COMMANDS_Pet_Develop_Pet_Pond_Unlock            = 'COMMANDS_Pet_Develop_Pet_Pond_Unlock',
    COMMANDS_Pet_Develop_Pet_Pet_Awaken             = 'COMMANDS_Pet_Develop_Pet_Pet_Awaken',
    COMMANDS_Pet_Develop_Pet_Pet_EggIntoPond        = 'COMMANDS_Pet_Develop_Pet_Pet_EggIntoPond',
    COMMANDS_Pet_Develop_Pet_Pet_Clean              = 'COMMANDS_Pet_Develop_Pet_Pet_Clean',
    COMMANDS_Pet_Develop_Pet_Pet_Clean_All          = 'COMMANDS_Pet_Develop_Pet_Pet_Clean_All',
    COMMANDS_Pet_Develop_Pet_PetEggWatering         = 'COMMANDS_Pet_Develop_Pet_PetEggWatering',
    COMMANDS_Pet_Develop_Pet_AddMagicFoodPond       = 'COMMANDS_Pet_Develop_Pet_AddMagicFoodPond',
    COMMANDS_Pet_Develop_AcceleratePetClean         = 'COMMANDS_Pet_Develop_AcceleratePetClean',
    COMMANDS_Pet_Develop_Pet_PetLock                = 'COMMANDS_Pet_Develop_Pet_PetLock',
    COMMANDS_Pet_Develop_Pet_PetUnlock              = 'COMMANDS_Pet_Develop_Pet_PetUnlock',
    COMMANDS_Pet_Develop_Pet_PetRelease             = 'COMMANDS_Pet_Develop_Pet_PetRelease',
    COMMANDS_Pet_Develop_Pet_PetLevelUp             = 'COMMANDS_Pet_Develop_Pet_PetLevelUp',
    COMMANDS_Pet_Develop_Pet_PetBreakUp             = 'COMMANDS_Pet_Develop_Pet_PetBreakUp',
    COMMANDS_Pet_Develop_Pet_PetAttributeReset      = 'COMMANDS_Pet_Develop_Pet_PetAttributeReset',
    --------------- pet ---------------

    ----------- 飨灵收集奖励 ------------
    COMMANDS_CARD_GATHER_AREA_REWARD                = 'COMMANDS_CARD_GATHER_AREA_REWARD',
    COMMANDS_CARD_GATHER_CP_REWARD                  = 'COMMANDS_CARD_GATHER_CP_REWARD',
    ----------- 飨灵收集奖励 ------------

    --------------- pvc ---------------
    COMMANDS_PVC_OfflineArena_Home                  = 'COMMANDS_PVC_OfflineArena_Home',
    COMMANDS_PVC_OfflineArena_SetDefenseTeam        = 'COMMANDS_PVC_OfflineArena_SetDefenseTeam',
    COMMANDS_PVC_OfflineArena_SetFightTeam          = 'COMMANDS_PVC_OfflineArena_SetFightTeam',
    COMMANDS_PVC_OfflineArena_MatchOpponent         = 'COMMANDS_PVC_OfflineArena_MatchOpponent',
    COMMANDS_PVC_OfflineArena_QuestAt               = 'COMMANDS_PVC_OfflineArena_QuestAt',
    COMMANDS_PVC_OfflineArena_QuestGrade            = 'COMMANDS_PVC_OfflineArena_QuestGrade',
    COMMANDS_PVC_OfflineArena_FirstWinReward        = 'COMMANDS_PVC_OfflineArena_FirstWinReward',
    COMMANDS_PVC_OfflineArena_BuyArenaQuestTimes    = 'COMMANDS_PVC_OfflineArena_BuyArenaQuestTimes',
    COMMANDS_PVC_OfflineArena_ArenaRecord           = 'COMMANDS_PVC_OfflineArena_ArenaRecord',
    --------------- pvc ---------------


    --餐厅商城
    COMMANDS_Restaurant_Shop_Home = 'COMMANDS_Restaurant_Shop_Home',
    COMMANDS_All_Shop_Buy = 'COMMANDS_All_Shop_Buy',
    COMMANDS_Restaurant_Shop_Refresh = 'COMMANDS_Restaurant_Shop_Refresh',
    COMMANDS_All_Shop_GetPayOrder = 'COMMANDS_All_Shop_GetPayOrder',
    COMMANDS_PVC_Shop_Refresh = 'COMMANDS_PVC_Shop_Refresh',
    COMMANDS_PVC_Shop_Home = 'COMMANDS_PVC_Shop_Home',

    --拳皇商城
    COMMANDS_KOF_Shop_Refresh = 'COMMANDS_KOF_Shop_Refresh',

    -- 家具商店
    COMMANDS_SHOP_AVATAR = 'COMMANDS_SHOP_AVATAR',
    COMMANDS_SHOP_AVATAR_BUYAVATAR = 'COMMANDS_SHOP_AVATAR_BUYAVATAR',


    --卡牌喂食精致食物。提升好感度
    COMMAND_CardEatFood = 'COMMAND_CardEatFood',
    COMMAND_RobberyOneDetaiView_Name_Callback = "COMMAND_RobberyOneDetaiView_Name_Callback"
}

require('Frame.PostCmd')
require('Frame.ConfCmd')
require('Frame.LocalData')

-- short define
COMMANDS    = Enum(COMMANDS)
SIGNALNAMES = Enum(SIGNALNAMES)
POST        = Enum(POST)
CMD         = COMMANDS
SGL         = SIGNALNAMES
regPost     = registSinglePostCommand
unregPost   = unregistSinglePostCommand

VoProxy = require('Frame.VoProxy')

function regVoProxy(proxyName, voStract)
    local voProxy = VoProxy.new(proxyName, voStract)
    app:RegistProxy(voProxy)
    return voProxy
end

function unregVoProxy(proxyName)
    app:UnRegistProxy(proxyName)
end


xTryCatchGetErrorInfo = function()
    print(debug.traceback());
end
--[[
-- 模拟try
-- catch操作
--]]
function xTry(try, catch)
    if not catch then catch = xTryCatchGetErrorInfo end
    local ret, errorMessage = xpcall( try, catch )
    -- print("ret:" .. (ret and "true" or "false" )  .. " \nerrMessage:" .. (errMessage or "null"));
end

function GetMoneyFormat(num)
    if num == nil or type(num) ~= 'number' then
        return num
    end
    if num < 10000000 then
        return num
    elseif num >= 10000000  then
        return string.fmt( __("_num_万"), {_num_ = math.floor(num / 10000 )})
    -- else
        -- return string.format( "%d千万", math.floor(num / 10000 ))
    end
end
--[[ local function initEnv() ]]
    -- ---设置搜索路径
    -- local writablePath = cc.FileUtils:getInstance():getWritablePath()--最终写入目录 /Documents/res/lua ui
    -- cc.FileUtils:getInstance():addSearchPath(writablePath .. 'publish')
    -- cc.FileUtils:getInstance():addSearchPath(writablePath.. 'res',true)
-- end
-- initEnv()
function lrequire(path)
    local start = os.clock()
    local tt = require(path)
    if DEBUG and DEBUG > 0 then
        funLog(Logger.INFO,path)
        local crashLog = "\n"
        crashLog = crashLog .. ("----------------------------------------\n")
        crashLog = crashLog .. ("cost time " .. tostring(os.clock() - start) .. '\n')
        crashLog = crashLog .. ("----------------------------------------\n")
        funLog(Logger.INFO,crashLog)
    end
    return tt
end

function measureWidth(text,fontSize,deltaWidth)
    local width = 110
    deltaWidth = deltaWidth or 0
    width = fontSize * string.utf8len(text) + deltaWidth
    if i18n.getLang() == 'en-us' then
        width = fontSize * string.utf8len(text) * 0.5 + deltaWidth
    end
    return width
end
--[[--
分隔字符串#分隔
--]]
function split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos = 0
    -- for each divider found
    local arr = {}
        for st,sp in function() return string.find(input, delimiter, pos, false) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

--[[
Ordered table iterator, allow to iterate on the natural order of the keys of a
table.

Example:
]]

local function cmp_multitype(op1, op2)
    local type1, type2 = type(op1), type(op2)
    if type1 ~= type2 then --cmp by type
        return type1 < type2
    elseif type1 == "number" and type2 == "number"
        or type1 == "string" and type2 == "string" then
        return checkint(op1) < checkint(op2) --comp by default
    elseif type1 == "boolean" and type2 == "boolean" then
        return op1 == true
    else
        return tostring(op1) < tostring(op2) --cmp by address
    end
end

function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex, cmp_multitype)
    return orderedIndex
end

function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.
    if t == nil then return nil, nil end

    local key = nil
    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end
    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

---[[--
--defines remove to here
----]]
APP_ENTER_BACKGROUND = 'APP_ENTER_BACKGROUND'
APP_ENTER_FOREGROUND = 'APP_ENTER_FOREGROUND'
APP_WINDOW_RESIZE    = 'APP_WINDOW_RESIZE'
APP_WINDOW_CLOSE     = 'APP_WINDOW_CLOSE'


--[[--
常量的一些配置
--]]
--
-- start cocos widget constants
--
eProgressBarDirectionLeftToRight = 0
eProgressBarDirectionRightToLeft = 1
eProgressBarDirectionBottomToTop = 2
eProgressBarDirectionTopToBottom = 3

eScrollViewDirectionHorizontal = 0
eScrollViewDirectionVertical = 1
eScrollViewDirectionBoth = 2

function getLinBreaks(s)
    local t = {}      -- 存放回车符的位置
    local i = 0
    while true do
        i = string.find(s, "\n", i+1)  -- 查找下一行
        if i == nil then break end
        table.insert(t, i)
    end
    return #t
end

function relativeScale(container, child)
    local scale = 1.0
    if container:getContentSize().height < child:getContentSize().height or container:getContentSize().width < child:getContentSize().width then
        local scaleX = container:getContentSize().width / child:getContentSize().width
        local scaleY = container:getContentSize().height / child:getContentSize().height
        scale = math.min(scaleX,scaleY)
    end
    return scale
end

--根据大小缩放
function relativeScaleSize(p, c)
    local scale = 1.0
    if p.height < c.height or p.width < c.width then
        local scaleX = p.width / c.width
        local scaleY = p.height / c.height
        scale = math.min(scaleX,scaleY)
    end
    return scale
end

---[[--
--对表进行排序，是不否是降序
--
----]]
function sortByKey(t, asc)
    local temp = {}
    for key,_ in pairs(t) do table.insert(temp,key) end
    if asc then
        table.sort(temp,function(a,b) return checkint(a) > checkint(b) end)
    else
        table.sort(temp,function(a,b) return checkint(a) < checkint(b) end)
    end
    return temp
end

--[[--
以某一元素对数组排充
@param t table
@param memberName 字段名
@param asc 是否为升序
--]]
function sortByMember(t,memberName,asc)
    if asc == nil then asc = true end
    local memberSort = function(a, b,memeberName,asc)
        if type(a) ~= 'table' then return not asc end
        if type(a) ~= 'table' then return asc end
        if not a[memberName]  then return not asc end
        if not b[memberName] then return asc end
        if type(a[memberName]) == "string"  then
            if string.match(a[memberName], '^%d+$') then --number
                if asc  then
                    return checkint(a[memberName]) < checkint(b[memberName])
                else
                    return checkint(a[memberName]) > checkint(b[memberName])
                end
            else
                if asc  then
                    return a[memberName]:lower() < b[memberName]:lower()
                else
                    return a[memberName]:lower() > b[memberName]:lower()
                end
                if asc  then
                    return a[memberName] < b[memberName]
                else
                    return a[memberName] > b[memberName]
                end
            end
        elseif type(a[memberName]) == 'number' then
            if asc  then
                return checkint(a[memberName]) < checkint(b[memberName])
            else
                return checkint(a[memberName]) > checkint(b[memberName])
            end
        elseif type(a[memberName]) == 'nil' then
            if asc  then
                return checkint(a[memberName]) < checkint(b[memberName])
            else
                return checkint(a[memberName]) > checkint(b[memberName])
            end
        end
    end
    table.sort(t, function(a, b) return memberSort(a, b, memberName, asc) end)
end

--[[-----------------------------------------------------------------
Name: formattedTime( TimeInSeconds, Format )
Desc: Given a time in seconds, returns formatted time
If 'Format' is not specified the function returns a table
conatining values for hours, mins, secs, ms
Examples: string.formattedTime( 123.456, "%02i:%02i:%02i")  ==> "02:03:45"
string.formattedTime( 123.456, "%02i:%02i")       ==> "02:03"
string.formattedTime( 123.456, "%2i:%02i")        ==> " 2:03"
string.formattedTime( 123.456 )                ==> {h = 0, m = 2, s = 3, ms = 45}
-------------------------------------------------------------------]]
function string.formattedTime( seconds, Format )
    if not seconds then seconds = 0 end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds / 60) % 60)
    local millisecs = ( seconds - math.floor( seconds ) ) * 100
    seconds = math.floor(seconds % 60)

    if Format then
        -- return string.format( Format, minutes, seconds, millisecs )
        return string.format( Format, hours, minutes, seconds)
    else
        return { h=hours, m=minutes, s=seconds, ms=millisecs }
    end
end

--[[---------------------------------------------------------
Name: Old time functions
-----------------------------------------------------------]]

function string.toMinutesSecondsMilliseconds( TimeInSeconds )   return string.formattedTime( TimeInSeconds, "%02i:%02i:%02i")   end
function string.toMinutesSeconds( TimeInSeconds )       return string.formattedTime( TimeInSeconds, "%02i:%02i")    end


-- 传入DrawNode对象，画圆角矩形
function drawNodeRoundRect(drawNode, rect, borderWidth, radius, color, fillColor)
    -- segments表示圆角的精细度，值越大越精细
    local segments    = 150
    local origin      = cc.p(rect.x, rect.y)
    local destination = cc.p(rect.width, rect.height)
    local points      = {}

    -- 算出1/4圆
    local coef     = math.pi / 2 / segments
    local vertices = {}

    for i=0, segments do
        local rads = (segments - i) * coef
        local x    = radius * math.sin(rads)
        local y    = radius * math.cos(rads)

        table.insert(vertices, cc.p(x, y))
    end

    local tagCenter      = cc.p(0, 0)
    local minX           = math.min(origin.x, destination.x)
    local maxX           = math.max(origin.x, destination.x)
    local minY           = math.min(origin.y, destination.y)
    local maxY           = math.max(origin.y, destination.y)
    local dwPolygonPtMax = (segments + 1) * 4
    local pPolygonPtArr  = {}

    -- 左上角
    tagCenter.x = minX + radius;
    tagCenter.y = maxY - radius;

    for i=0, segments do
        local x = tagCenter.x - vertices[i + 1].x
        local y = tagCenter.y + vertices[i + 1].y

        table.insert(pPolygonPtArr, cc.p(x, y))
    end

    -- 右上角
    tagCenter.x = maxX - radius;
    tagCenter.y = maxY - radius;

    for i=0, segments do
        local x = tagCenter.x + vertices[#vertices - i].x
        local y = tagCenter.y + vertices[#vertices - i].y

        table.insert(pPolygonPtArr, cc.p(x, y))
    end
    -- 右下角
    tagCenter.x = maxX - radius;
    tagCenter.y = minY + radius;

    for i=0, segments do
        local x = tagCenter.x + vertices[i + 1].x
        local y = tagCenter.y - vertices[i + 1].y

        table.insert(pPolygonPtArr, cc.p(x, y))
    end
    -- 左下角
    tagCenter.x = minX + radius;
    tagCenter.y = minY + radius;

    for i=0, segments do
        local x = tagCenter.x - vertices[#vertices - i].x
        local y = tagCenter.y - vertices[#vertices - i].y

        table.insert(pPolygonPtArr, cc.p(x, y))
    end

    if fillColor == nil then
        fillColor = cc.c4f(0, 0, 0, 0)
    end
    drawNode:drawPolygon(pPolygonPtArr, #pPolygonPtArr, fillColor, borderWidth, color)
end

--[[--
将table转为string
--]]
local function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

local function dump_key_(v)
    if type(v) == "number" then
        v = "[" .. v .. "]"
    elseif type(v) == "string" then
        v = "['" .. v .. "']"
    end
    return tostring(v)
end

function tableToString(value, desciption, nesting)
    if DEBUG and DEBUG == 0 then return "" end
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    -- local traceback = string.split(debug.traceback("", 2), "\n")
    -- print("dump from: " .. string.trim(traceback[3]))

    local function dump_(value, desciption, indent, nest, keylen)
        desciption = desciption or "var"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_key_(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s,", indent, dump_key_(desciption), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = '*REF*',", indent, dump_key_(desciption), spc)
        else
            lookupTable[tostring(value)] = true  -- 用来记录已解析过的table，防止相互引用导致死循环
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = '*MAX NESTING*',", indent, dump_key_(desciption))
            else
                if next(value) == nil then
                    result[#result +1 ] = string.format("%s%s%s = {}%s", indent, nest == 1 and desciption or dump_key_(desciption), spc, nest == 1 and '' or ',')
                else
                    result[#result +1 ] = string.format("%s%s%s = {", indent, nest == 1 and desciption or dump_key_(desciption), spc)
                    local indent2 = indent.."    "
                    local keys = {}
                    local keylen = 0
                    local values = {}
                    for k, v in pairs(value) do
                        keys[#keys + 1] = k
                        local vk = dump_key_(k)
                        local vkl = string.len(vk)
                        if vkl > keylen then keylen = vkl end
                        values[k] = v
                    end
                    table.sort(keys, function(a, b)
                        if type(a) == "number" and type(b) == "number" then
                            return a < b
                        else
                            return tostring(a) < tostring(b)
                        end
                    end)
                    for i, k in ipairs(keys) do
                        dump_(values[k], k, indent2, nest + 1, keylen)
                    end
                    result[#result +1] = string.format("%s}%s", indent, nest == 1 and '' or ',')
                end
            end
        end
    end
    dump_(value, desciption, "", 1)
    return table.concat(result,' \n')
end

function dumpTree(absolutePath, level, count)
    local lfs = require("lfs")
    local maxLevel   = level or 5
    local maxCount   = count or 10
    local rootPath   = absolutePath
    local dumpResult = {}

    local function dumpTree_(path, level, indent)
        if level <= 0 then return end
        local fileLength   = 0
        local fileResult   = {}
        local folderResult = {}

        for file in lfs.dir(path) do
            if file ~= '.' and file ~= '..' then
                local filePath = path .. '/' .. file
                local fileAttr = lfs.attributes(filePath)
                if fileAttr then

                    if fileAttr.mode == 'directory' then
                        table.insert(folderResult, file)
                    else
                        if fileLength <= maxCount then
                            table.insert(fileResult, file)
                        end
                        fileLength = fileLength + 1
                    end

                end
            end
        end

        table.sort(fileResult, function(a, b)
            return a < b
        end)
        table.sort(folderResult)
        for _, v in ipairs(fileResult) do
            if level == maxLevel then
                table.insert(dumpResult, v)
            else
                table.insert(dumpResult, '    ' .. v)
            end
        end
        for _, v in ipairs(folderResult) do
            table.insert(dumpResult, indent .. v .. '/')
            local filePath = path .. '/' .. v
            dumpTree_(filePath, level - 1, indent .. v .. '/')
        end
    end
    dumpTree_(rootPath, maxLevel, '')
    return dumpResult--table.concat(dumpResult, '\n')
end

function inCirclePos(center, radiusW, radiusH, angle)
    local radians = math.pi / 180 * angle
    return cc.p(center.x + radiusW * math.sin(radians), center.y + radiusH * math.cos(radians))
end

function _res2(resPath)
    return utils and utils.getFileName(resPath) or resPath
end
_res = _res or _res2

--产生一个范围的id
function rangeId( id, max )
    if id == nil then id = 1 end
    if type(id) == "string" then id = checkint(id) end
    if id <= 0 then id = 1 end
    if not max then max = id end
    if id > max then id = max end
    return id
end

--[[
--判断某个模块是否开始
--]]
function isGuideOpened(tmodule)
    local shareUserDefault = cc.UserDefault:getInstance()
    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
    local playerId = gameMgr:GetUserInfo().playerId
    local moduleKey = string.format('%s_%d', tmodule, checkint(playerId))
    local isFirstGuide = shareUserDefault:getBoolForKey(moduleKey, true)
    return isFirstGuide
end

-------------------------------------------------
---- time
-- 登录时的服务器时间（无时区, GMT+0 秒数）
function getLoginServerTime()
    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
    return checkint(gameMgr.userInfo.serverTime)
end

-- 登录时的客户端时间（无时区, GMT+0 秒数）
function getLoginClientTime()
    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
    return checkint(gameMgr.userInfo.loginClientTime)
end

-- 当前服务器时间（无时区, GMT+0 秒数）
function getServerTime()
    return getLoginServerTime() + (os.time() - getLoginClientTime())
end

-- 服务器时区（秒数，例：GMT+8 = 8*60*60 = 28800）
function getServerTimezone()
    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
    return checkint(gameMgr.userInfo.serverTimeOffset)
end

-- 客户端时区（秒数，例如：GMT+8 = 8*60*60 = 28800）
function getClientTimezone()
    local nowTime  = os.time(os.date("*t"))
    local pureTime = os.time(os.date("!*t", nowTime))
    if os.date("*t", os.time()).isdst then
        nowTime = nowTime + 3600
    end
    return os.difftime(nowTime, pureTime)
end

-- @timestamp string 服务器时间戳（有时区），例：2017-12-11 12:42:26 或者 2017-12-11
function timestampToSecond(timestamp)
    local tf = string.gsub(tostring(timestamp or ''), '[- :]', '|')
    local tl = string.split(tf, '|')
    local tt = {
        year  = math.max(1970, checkint(tl[1])),
        month = math.max(1, checkint(tl[2])),
        day   = math.max(1, checkint(tl[3])),
        hour  = checkint(tl[4]),
        min   = checkint(tl[5]),
        sec   = checkint(tl[6]) + getClientTimezone()  -- os.time 是计算 目标时间 和 本地时区的差值，会自带扣除，所以再加上本地时区，就是一个无损转换。
    }
    return os.time(tt)
end

-- 将服务器时间 本地化后的 时间格式（服务器时间戳 - 服务器时区 = 纯净时间，再 + 客户端时区 = 当前时间）
function l10nTimeData(timestamp, timeFormat)
    local format = tostring(timeFormat or '!%Y-%m-%d %H:%M:%S')
    return os.date(format, timestampToSecond(timestamp) - getServerTimezone() + getClientTimezone())
end

-- 用于小时等级的时间转换，例如（服务器12点刷新 => 当前时区的几点刷新）
function l10nHours(hours, minute, second)
    local hours, minute, second = checkint(hours), checkint(minute), checkint(second)
    local time = hours * 3600 + minute * 60 + second
    return require('cocos.framework.date')(time - getServerTimezone() + getClientTimezone())
end
--[[
获取elex渠道绑定时区
--]]
function getElexBentoTimezone()
    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
    return gameMgr:GetUserInfo().timezone
end
--[[
elex爱心便当领取时间转换为本地时间
--]]
function elexBentoTimeChange(hours, minute, second)
    local hours, minute, second = checkint(hours), checkint(minute), checkint(second)
    local time = hours * 3600 + minute * 60 + second
    return require('cocos.framework.date')(time + getClientTimezone() - getElexBentoTimezone())
end
--[[
elex爱心便当领取时间转换为服务器时间
--]]
function elexBentoServerTimeChange(hours, minute, second)
    local hours, minute, second = checkint(hours), checkint(minute), checkint(second)
    local time = hours * 3600 + minute * 60 + second
    return require('cocos.framework.date')(time - getElexBentoTimezone() + getServerTimezone())
end
--[[
--判断是否是quick渠道
--]]
function isQuickSdk()
    local platformId = checkint(Platform.id)
    local isQuick = false
    if (platformId < 888 and platformId ~= YSSDKChannel) or platformId == QuickVirtualChannel then
        isQuick = true
    end
    return isQuick
end

--[[
--是否是官方sdk的平台
--]]
function isFuntoySdk()
    local platformId = checkint(Platform.id)
    local isQuick = false
    if platformId == Fondant or platformId == AppStore
    or platformId == BetaIos or platformId == BetaAndroid
    or platformId == PreIos  or platformId == PreAndroid
    or platformId == XipuAndroid or platformId == InviteCodeChannel
    or platformId == XipuNewAndroid
    or platformId == TapTap then
        isQuick = true
    end
    return isQuick
end

function isEfunSdk()
    local platformId = checkint(Platform.id)
    local isQuick = false
    if platformId == EfunAndroid or platformId == EfunIos then
        isQuick = true
    end
    return isQuick
end

function isKoreanSdk()
    local platformId = checkint(Platform.id)
    local isQuick = false
    if platformId == KoreanAndroid or platformId == KoreanIos then
        isQuick = true
    end
    return isQuick
end
--[[
--是否是官方的扩展出来的sdk的包
--
--]]
function isFuntoyExtraSdk()
    local platformId = checkint(Platform.id)
    local isQuick = false
    if platformId >= 2101 and platformId < 2199 then
        isQuick = true
    elseif platformId == 2010 or platformId == 2011 then
        isQuick = true
    end
    return isQuick
end
--[[
--是否是elex
--]]
function isElexSdk()
    local platformId = checkint(Platform.id)
    local isQuick = false
    if platformId == NewUsAndroid or platformId == NewUsIos
    or platformId == ElexIos or platformId == ElexAndroid
    or platformId == ElexAmazon or platformId == ElexThirdPay then
        isQuick = true
    end
    return isQuick
end
--[[
--是否是NewUS
--]]
function isNewUSSdk()
    local platformId = checkint(Platform.id)
    local isQuick = false
    if platformId == NewUsAndroid or platformId == NewUsIos  then
        isQuick = true
    end
    return isQuick
end
--[[
--是否是国内
--]]
function isChinaSdk()
    local platformId = checkint(Platform.id)
    local isChina = true
    if platformId >=  4001 and platformId <= 4999 then
        isChina = false
    end
    return isChina
end
--[[
--是否是Japan
--]]
function isJapanSdk()
    local platformId = checkint(Platform.id)
    local isQuick = false
    if platformId == JapanAndroid or platformId == JapanIos or platformId == JapanAmazonAndroid then
        isQuick = true
    end
    return isQuick
end
--[[
--是否是korean
--]]
function isKoreanSdk()
    local platformId = checkint(Platform.id)
    local isQuick = false
    if platformId == KoreanAndroid or
    platformId == KoreanIos or
    platformId == KoreanNewAndroid or
    platformId == KoreanNewIos then
        isQuick = true
    end
    return isQuick
end

--[[
--新的韩国渠道 ， 我们自己的
--]]
function isNewKoreanSdk()
    local platformId = checkint(Platform.id)
    local isQuick = false
    if platformId == KoreanNewAndroid or platformId == KoreanNewIos then
        isQuick = true
    end
    return isQuick
end

--[[
--是否使用obb下载
--]]
function isUseObbDownload()
    return isKoreanSdk() or isEfunSdk()
end

--是否是korean
--]]
function isEliteSDK()
    local platformId = checkint(Platform.id)
    local isElite = false
    if platformId == EliteOneAndorid or platformId == EliteTwoAndorid then
        isElite = true
    end
    return isElite
end
--[[
--清除模块
--]]
function unrequire(m)
    package.loaded[m] = nil
    package.preload[m] = nil
    _G[m] = nil
end


--[[
--字符由几个字节组成
--[0, 0xc0) 表示这个字符仅由1个字节构成
--[0xc0, 0xe0) 表示这个字符由2个字节构成
--[0xe0, 0xf0) 表示这个字符由3个字节构成
--[0xf0, 0xff) 表示这个字符由4个字节构成
--]]
function BytesOfCharacter(theByte)
    local seperate = {0, 0xc0, 0xe0, 0xf0}
    for i = #seperate, 1, -1 do
        if theByte >= seperate[i] then return i end
    end
    return 1
end

function UTF8len(utf8Str,aChineseCharBytes)
    aChineseCharBytes = aChineseCharBytes or 2
    local i = 1
    local characterSum = 0
    while (i <= #utf8Str) do      -- 编码的关系
        local bytes4Character = BytesOfCharacter(string.byte(utf8Str, i))
        characterSum = characterSum + (bytes4Character > aChineseCharBytes and aChineseCharBytes or bytes4Character)
        i = i + bytes4Character
    end
    return characterSum
end


function fullScreenFixScale(node)
    if node then
        node:setScale(display.width / node:getContentSize().width)
        if node:getScale() * node:getContentSize().height < display.height then
            node:setScale(display.height / node:getContentSize().height)
        end
    end
end


function dirname(path)
    return string.match(path, "(.+)/[^/]*%.%w+$") --*nix system
end

function basename(path)
    return string.match(path, ".+/([^/]*%.%w+)$")
end

function stripextension(filename)
    local idx = filename:match(".+()%.%w+$")
    if(idx) then
        return filename:sub(1, idx-1)
    else
        return filename
    end
end

--获取扩展名
function getextension(filename)
    return filename:match(".+%.(%w+)$")
end


function getRealConfigPath(jsonFilePath)
    local fileUtils = cc.FileUtils:getInstance()
    if FTUtils:getTargetAPIVersion() >= 11 then
        local zipPath = string.gsub(jsonFilePath, '.json', '.zip')
        zipPath = fileUtils:fullPathForFilename(zipPath)
        if utils.isExistent(zipPath) then
            return zipPath
        else
            local jsonPath = fileUtils:fullPathForFilename(jsonFilePath)
            return jsonFilePath
        end
    else
        local jsonPath = fileUtils:fullPathForFilename(jsonFilePath)
        return jsonFilePath
    end
end

--[[
--得到真实的配表路径的逻辑
--]]
function getRealConfigData(jsonFilePath, tname)
    local t = {}
    local fileUtils = cc.FileUtils:getInstance()
    -- jsonFilePath = cc.FileUtils:getInstance():fullPathForFilename(jsonFilePath)
    if FTUtils:getTargetAPIVersion() >= 11 then
        local zipPath = string.gsub(jsonFilePath, '.json', '.zip')
        zipPath = fileUtils:fullPathForFilename(zipPath)
        if utils.isExistent(zipPath) then
            local content = FTUtils:getFileDataFromZip(zipPath, string.format('%s.json', tname))
            t = json.decode(content)
            if not t then t = {} end
        elseif utils.isExistent(fileUtils:fullPathForFilename(jsonFilePath)) then
            local content = FTUtils:getFileData(fileUtils:fullPathForFilename(jsonFilePath))
            t = json.decode(content)
            if not t then t = {} end
        end
    elseif utils.isExistent(fileUtils:fullPathForFilename(jsonFilePath)) then
        local content = FTUtils:getFileData(fileUtils:fullPathForFilename(jsonFilePath))
        t = json.decode(content)
        if not t then t = {} end
    end
    return t
end


function getRealConfigIsExistent(jsonFilePath)
    local fileUtils = cc.FileUtils:getInstance()
    if FTUtils:getTargetAPIVersion() >= 11 then
        local zipPath = string.gsub(jsonFilePath, '.json', '.zip')
        zipPath = fileUtils:fullPathForFilename(zipPath)
        if utils.isExistent(zipPath) then
            return true

        elseif utils.isExistent(fileUtils:fullPathForFilename(jsonFilePath)) then
            return true
        end

    elseif utils.isExistent(fileUtils:fullPathForFilename(jsonFilePath)) then
        return true
    end
    return false
end


-- local filePath = cc.FileUtils:getInstance():fullPathForFilename('res/keywords.txt')
-- local str = io.readfile(filePath)
-- local keywords = string.split(str, '|')

local MsgParser = require("root.MsgParser")
--[[
--敏感词过滤的逻辑函数
--@content 输入的文件内容
--@onlyKnowHas 是否只返回替换后的字符串
--]]
function nativeSensitiveWords( content, onlyKnowHas )
    if content == nil or content == '' then
        return ''
    end
    return MsgParser:getString(content)
    --[[
    local contentArray = string.gmatch(content, ".[\128-\191]*")
    local tempContent = ''
    for w in contentArray do
        if string.byte(w) ~= 10 then --表示回车（换行）
            tempContent = tempContent .. w
        end
    end

    -- local function filterKey(msg)
        -- local tArray = string.gmatch(msg, ".[\128-\191]*")
        -- local contentArray = {}
        -- for w in tArray do
            -- table.insert(contentArray,w)
        -- end
        -- local result = ''
        -- for idx,val in ipairs(contentArray) do
            -- result = result .. val
        -- end
        -- return result
    -- end
    -- local keywords = {}
    -- local str = io.readfile('res/keywords.txt')
    -- keywords = string.split(str, '\r\n')
    local starChar = '*'
    local function filter( message, onlyKnowHas)
        local star = ''
        local key
        local len = 0
        local star
        for name,val in pairs(keywords) do
            if string.len(val) > 0 then
                key = string.trim(val)
                -- key = filterKey(key)
                len = #(string.gsub(key, "[\128-\191]", ""))
                star = ''
                for i=1,len do
                    star = star..starChar
                end
                local startPos, endPos = string.find(message, key)
                if startPos and endPos then
                    -- cclog('----------------->>', startPos, endPos, string.len(message))
                    if startPos < endPos then
                        message = string.gsub(message, key , star )
                        -- break
                    end
                end
            end
        end
        return message
    end
    if keywords and table.nums(keywords) > 0 then
        return filter(tempContent)
    else
        return content
    end
    --]]
end

function ssl_encrypt( str )
    if str then
        local codec   = require('codec')
        local apisalt = FTUtils:generateKey(SIGN_KEY)
        local encryptedData,iv = codec.aes_cbc_encrypt(str, apisalt)
        if encryptedData and iv then
            --进行加密
            local base64Iv = codec.base64_encode(iv)
            encryptedData = codec.base64_encode(encryptedData)
            local hashMac  = codec.hmac_sha1_encode(string.format('%s%s',base64Iv, encryptedData), apisalt)
            local cjson = require("cjson")
            local status, result = pcall(cjson.encode, {iv = base64Iv, mac = hashMac, value = encryptedData})
            if status then
                return codec.base64_encode(result)
                -- return result
            else
                return str
            end
        else
            return str
        end
    end
end
