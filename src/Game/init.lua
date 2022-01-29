---------------------------------------------------------------
---启用id 不能是2200000 因为菜谱红点在这个区域
---红点的添加按照大小位置添加以防止错乱影响
---------------------------------------------------------------
RemindTag    = {
    CARDS                           = 901, -- 卡牌
    CAPSULE                         = 902, -- 抽卡
    PET                             = 903, -- 堕神
    SHOP                            = 904, -- 商城
    MAIL                            = 905, -- 邮件
    TASK                            = 906, -- 任务
    HANDBOOK                        = 907, -- 图鉴
    SET                             = 908, -- 设置
    MAP                             = 909, -- 地图 冒险
    MANAGER                         = 910, -- 经营
    TEAMS                           = 911, -- 编队
    BACKPACK                        = 912, -- 背包
    ANNOUNCE                        = 913, -- 公告 暂时
    ICEROOM                         = 914, -- 冰场
    TALENT                          = 915, -- 天赋
    ORDER                           = 916, -- 定单
    STORY                           = 917, -- 剧情
    FRIENDS                         = 918, -- 好友
    WORLDMAP                        = 919, -- 世界地图
    STORYBTN                        = 920, -- 主线剧情
    REGIONALBTN                     = 921, -- 支线剧情
    ROBBERY                         = 922, -- 打劫按钮的刷新
    MARKET                          = 923, -- 市场
    RAIDBTN                         = 926, -- 组队副本入口
    DISCOVER                        = 927, -- 研究
    CARVIEW                         = 928, -- 车库
    STAR_REWARD                     = 929, -- 满星奖励
    QUEST_ARMY                      = 930, -- 探索
    RESEARCH                        = 931, -- 菜谱研发
    RANK                            = 932, -- 排行榜
    TOWER                           = 934, -- 爬塔
    SEVENDAY                        = 935, -- 新手七天任务
    AIRSHIP                         = 936, -- 飞艇
    MODELSELECT                     = 937, -- 模块列表
    PVC                             = 938, -- 离线竞技场
    ACTIVITY                        = 939, -- 活动
    STORY_TASK                      = 940, -- 主线任务
    UNION                           = 941, -- 工会
    THREETWORAID                    = 942, -- 组队
    LEVEL                           = 943, -- 等级礼包
    WORLD_BOSS                      = 944, -- 世界boss
    TASTINGTOUR                     = 945, -- 料理副本
    PERSISTENCE_PAY                 = 946, -- 永久充值
    TAG_MATCH                       = 947, -- 天城演武
    TAG_JEWEL_EVOL                  = 948, -- 宝石合成
    ARTIFACT_TAG                    = 949, -- 神器
    WORLD_BOSS_MANUAL               = 950, -- 世界boss手册
    TAKE_HOUSE                      = 951, -- 塔可屋
    UNION_PARTY                     = 952, -- 工会派对
    EXPLORE_SYSTEM                  = 953, -- 新探索
    SUMMER_ACTIVITY                 = 954, -- 夏活
    HOME_LAND                       = 955, -- 家园
    FISH_GROUP                      = 956, -- 钓场
    BOX_MODULE                      = 957, -- 包厢
    MATERIAL                        = 958, -- 材料副本
    SAIMOE                          = 959, -- 燃战
    SAIMOE_CLOSE                    = 960, -- 燃战关闭
    ALL_ROUND                       = 961, -- 谁是全能王
    PTDUNGEON                       = 964, -- pt本
    MURDER                          = 965, -- 杀人案
    BLACK_GOLD                      = 966, -- 黑市
    TTGAME                          = 967, -- 3x3打牌
    TIME_LIMIT_UPGRADE_TASK         = 968, -- 限时升级活动
    PLOT_COLLECT                    = 969, -- 剧情收集
    WATER_BAR                       = 970, -- 水吧
    ARTIFACT_GUIDE                  = 971, -- 神器指引
    FIRST_PAY                       = 972, -- 首充
    CHAMPIONSHIP                    = 973, -- 武道会
    CHANGE_STRONGER                 = 974, -- 我要变强
    NOVICE_WELFARE                  = 975, -- 新手福利
    CARD_ALBUM                      = 976, -- 飨灵收集册
    CAT_HOUSE                       = 977, -- 猫屋
    NEW_TAG_MATCH                   = 978, -- 新天城演武

    LOBBY_TASK                      = 1100, --餐厅任务
    LOBBY_DISH                      = 1101, --备菜
    LOBBY_MEMBER                    = 1102, --备菜
    LOBBY_INFORMATION               = 1103, --备菜
    DIFFICULT_MAP                   = 1104, --困难本
    LOBBY_SHOP                      = 1105, --餐厅小费商城
    LOBBY_FRIEND                    = 1106, --餐厅好友
    PUBLIC_ORDER                    = 1107, --公有订单
    LOBBY_FESTIVAL_ACTIVITY         = 1108, --餐厅活动
    LOBBY_FESTIVAL_ACTIVITY_PREVIEW = 1109, --餐厅活动 预览
    LOBBY_AGENT_SHOPOWNER           = 1110, --餐厅代理店长

    SKIN_COLL_TASK                  = 1202, -- 外观收集任务
    ---------------------------------------------------------------
    ---启用id 不能是1300-1400 因为卡牌收集红点在这个区域
    ---
    ---------------------------------------------------------------

    UNION_INFO                      = 3001, -- 工会信息
    UNION_TASK                      = 3002, -- 工会任务
    UNION_MONSTER                   = 3003, -- 工会神兽
    UNION_BUILD                     = 3004, -- 工会建设
    UNION_ACTIVITY                  = 3005, -- 工会活动
    UNION_BATTLE                    = 3006, -- 工会战斗
    UNION_SHOP                      = 3007, -- 工会商店
    UNION_HUNT                      = 3008, -- 工会狩猎
    TASTINGTOUR_ZONE_REWARD         = 3009, -- 料理副本区域领取奖励
    UNION_WARS                      = 3010, -- 工会竞赛
    UNION_IMPEACHMENT               = 3011, -- 工会弹劾

    SAIMOE_COMPOSABLE               = 3300, -- 燃战碎片可合成

    FRESH_TAKEOUT_TIME              = 10004, --外卖下次刷新的时间的逻辑

    BTN_AVATAR_DECORATE             = 11001, --餐厅装修的tag值
    BTN_AVATAR_UPGRADE              = 11002, --餐厅装修的tag值
    CARDLEVELUP                     = 11003, -- 卡牌升级按钮
    CARDBREAKLVUP                   = 11004, -- 卡牌升星按钮
    LEVEL_CHEST                     = 11005, -- 等级礼包按钮
    RECALL                          = 11006, -- 老玩家召回按钮
    RECALLH5                        = 11007, -- 老玩家召回H5按钮
    RECALLEDMASTER                  = 11008, -- 召回的玩家按钮
    BTN_FISH_UPGRADE                = 11109, --钓鱼升级
    SP_ACTIVITY                     = 11110, -- 特殊活动入口
    ANNIVERSARY_EXTRA_REWARD_TIP    = 11111, -- 周年庆特殊奖励红点
    RETURNWELFARE                   = 11112, -- 回归福利红点

    WORLD_AREA_1                    = 12001, --地图红点
    WORLD_AREA_2                    = 12002,
    WORLD_AREA_3                    = 12003,
    WORLD_AREA_4                    = 12004,
    WORLD_AREA_5                    = 12005,
    WORLD_AREA_6                    = 12006,
    WORLD_AREA_7                    = 12007,

    NEW_FRIENDS                     = 20001, -- 好友请求红点
    BINDING_TELL                    = 100000, -- 绑定手机号的倒计时
    TAKEAWAY_TIMER                  = 100001, --外卖计时器的功能逻辑
    PRE_AREA                        = 100002,
    NEXT_AREA                       = 100003,


    BACKPACK_PLATE                  = 2000001, --餐盘的地方显示小红点
    HOME_FACEBOOK                   = 2000002, --主界面fb
    ---------------------------------------------------------------
    ---启用id 不能是2200000 因为菜谱红点在这个区域
    ---
    ---------------------------------------------------------------

    ---------------------------------------------------------------
    ---启用id 不能是2300000 因为区域红点在这个区域
    ---启用id 不能是2400000 因为关卡剧情红点在这个区域
    ---
    ---------------------------------------------------------------

    Limite_Time_GIFT_BG             = 100000001, -- 限时礼包的识别ID
    MYSELF_INFOR                    = 100000002, -- 个人信息查看

    ---------------------------------------------------------------
    WARTER_BAR_FRE_POINT_REWARD    = 100000003
}

DOWNLOAD_DEFINE = {
    HEADER_IMG = {event = 'HEADER_IMG_DOWNLOAD'},                                                                      -- 头像、打脸页
    LOAD_IMAGE = {event = 'LOADIMAGE_DOWNLOAD_EVENT'},                                                                 -- LoadImage 控件
    CARD_SPINE = {event = 'CARDSPINE_DOWNLOAD_EVENT'},                                                                 -- CardSpine 控件
    AVATAR_RES = {event = 'RESTAURANT_DOWNLOAD_EVENT'},                                                                -- 餐厅avatar 资源
    RES_JSON   = {event = 'RES_JSON_DOWNLOAD', url = string.fmt('http://%1/update/res/res_%2.zip', Platform.serverHost, FTUtils:getAppVersion())}, -- 小包配置文件
    VOICE_JSON = {event = 'VOICE_JSON_DOWNLOAD', url = string.fmt('http://%1/img/voice.txt', Platform.serverHost)},    -- 语音配置文件
    VOICE_ACB  = {event = 'VOICE_ACB_DOWNLOAD'},                                                                       -- 语音音效文件
    RES_POPUP  = {event = 'RES_POPUP_DOWNLOAD', progress = 'RES_POPUP_PROGRESS'},                                      -- 下载资源弹窗
}
-- 港台 & 日本 & 韩国
if isEfunSdk() or isJapanSdk() or isKoreanSdk() then
    DOWNLOAD_DEFINE.VOICE_JSON.url = string.fmt('http://%1/img/tw/voice.txt', Platform.serverHost)
elseif isNewUSSdk() then
    DOWNLOAD_DEFINE.VOICE_JSON.url = string.fmt('http://%1/img/hw/voice.txt', Platform.serverHost)
elseif isElexSdk()  then
    DOWNLOAD_DEFINE.VOICE_JSON.url = string.fmt('http://%1/img/zm/voice.txt', Platform.serverHost)
end

VOICE_MSG_TYPE = 2 --语音消息类别

-- 游戏换皮兼容 one-湖边小筑  two-歌舞伎町
GAME_MOUDLE_EXCHANGE_SKIN = {
    CASTLE_SKIN = 'three', -- 古堡活动
    ANNIVERSARY = "one",   -- 周年庆2018
    ANNIV2019   = "one",     -- 周年庆2019
    ANNIV2020   = nil,     -- 周年庆2020
    SPRING_2020 = "one",     -- 春活2020
    MURDER      = nil,     
    MURDER      = nil,  -- 杀人案
    SUMMER_ACT  = nil,    -- 老夏活（走表的，不在这里控制：conf/summerActivity/param.json） @see app.summerActMgr:InitCarnieTheme()
}


-- 游戏功能开关
GAME_MODULE_OPEN = {
    CLEAN_CACHE        = true ,  -- 清除缓存
    NEW_CAPSULE        = true,   -- 新抽卡
    DUAL_DIAMOND       = false,  -- 双重钻石（有偿/无常）
    GROWTH_FUND        = true,   -- 成长基金
    NEW_STORE          = true,   -- 新商城
    UNION_WARS         = true,   -- 工会战
    PAY_LOGIN_REWARD   = true,   -- 付费签到
    PERSON_EXP_DESCR   = true,   -- 个人经验追赶说明
    NEW_CREATE_ROLE    = false,  -- 新创角
    NEW_PLOT           = false,   -- 新剧情
    MAIL_COLLECTION    = false,  -- 邮件收藏
    CARD_LIVE2D        = true ,  -- 卡牌live2d
    WOODEN_DUMMY       = true, -- 木桩人
    BATTLE_SKADA       = true, -- 战斗伤害统计
	RE_ANNIVERSARY     = true, -- 周年庆重置
	FRIEND_REMARK      = false, -- 好友备注
    FRIEND_BATTLE      = false, -- 好友切磋
    WATER_BAR          = true,  -- 水吧
    ARTIFACT_GUIDE     = false, -- 神器指引
    PRESET_TEAM        = false, -- 预设编队
    DOT_EVENT_LOG      = false, -- 打点事件(国内专用)
    CARD_SKIN_SIGN     = false, -- 卡牌皮肤标记
    MEMORY_STORE       = false, -- 记忆商店
    NEWER_ADD_EXP      = false, -- 新手加奖励的开关
    ACT_POSTER_JUMP    = false, -- 活动打脸页前往跳转
    NEW_LEVEL_REWARD   = false, -- 新版等级礼包（成长的守候）
    NEW_NOVICE_ACC_PAY = false, -- 新手单笔充值替换为新手累计充值（新手福利集结）
    CHANGE_STRONGER    = false,  -- 我要变强功能
    SKIN_COLLECTION    = false, -- 卡牌皮肤收集
    ACCOUNT_MIGRAT     = false, -- 账号迁移功能 --此功能目前只在韩服使用
    BASIC_SKIN_CAPSULE = false, -- 常驻皮肤卡池
    CARD_ALBUM         = false, -- 飨灵收集册
    CAT_HOUSE          = false, -- 猫屋
    LEVEL_GIFT         = false,  -- 等级礼包
    CARD_LIST_FIND     = false,  -- 卡牌列表搜索
    NEW_TAG_MATCH      = false,  -- 新天城演武（打开，意味着会关闭旧天城演武）
    COMMUNITY          = false,  -- 社区入口
    CARD_LIST_NEW      = false,  -- 卡牌列表新版本
    ENTITY_REWARDS     = false,  -- 实体奖励（有实物的奖励，目前就国服用）
    GVOICE_SERVER      = false, -- GVoice语音服务（其实控制不了开关，只能提示用）
}


--该表用于控制游戏设置是否开放
CONTROL_GAME = {
    CONRROL_MUSIC = "CONRROL_MUSIC" , -- 控制音乐
    GAME_MUSIC_EFFECT = "GAME_MUSIC_EFFECT" , -- 控制音效
    TELIPHONE_VIBRATE = "TELIPHONE_VIBRATE" , -- 控制振动
    GAME_VOICE  = "GAME_VOICE" , -- 游戏语音
    MARQUEE_PUSH = "MARQUEE_PUSH",
    CHAT_PUSH = "CHAT_PUSH",
    WORLD_CHANNEL_PUSH = "WORLD_CHANNEL_PUSH",


    ONELY_WIFI_OPEN = "ONELY_WIFI_OPEN" ,   -- 这些仅在wift 下开启
    WORLD_VOICE_AUTO_PLAY = "WORLD_VOICE_AUTO_PLAY" , --世界语音自动播放
    GUILD_VOICE_AUTO_PLAY = "GUILD_VOICE_AUTO_PLAY" , --公会语音自动播放
    FORM_TEAM_VOICE_AUTO_PLAY = 'GUILD_VOICE_AUTO_PLAY' , --组队语音控制
    PRIVATE_CHAT_VOICE_AUTO_PLAY = "PRIVATE_CHAT_VOICE_AUTO_PLAY" , -- 私聊语音自动播放
    PUSH_PHYSICAL_FULL_VALUE = "PUSH_PHYSICAL_FULL_VALUE" , -- 体力满值的推送
    PUSH_LUNCH_DINNER = "PUSH_LUNCH_DINNER" , --午饭和晚饭推送
    PUSH_OVERLOAD_MEAL = "PUSH_OVERLOAD_MEAL" ,--霸王餐
    PUSH_WORLD_ORDER = "PUSH_WORLD_ORDER" ,  --世界订单的推送

}
--该表用于控制游戏设置属性的大小
CONTROL_GAME_VLUE = {
    CONTREL_MUSIC_BIGORLITTLE = "CONTREL_MUSIC_BIGORLITTLE" ,  --控制音乐大小
    CONTREL_GAME_EFFECT_BIGORLITTLE = "CONTREL_GAME_EFFECT_BIGORLITTLE" ,  --控制音乐大小
    CONTREL_TEL_VIBRATE_BIGORLITTLE = "CONTREL_TEL_VIBRATE_BIGORLITTLE" ,  --控制手机振动
    CONTREL_GAME_VOICE_BIGORLITTLE = "CONTREL_GAME_VOICE_BIGORLITTLE" ,  --控制游戏声音大小
}
States              = {
    ID_IDLE         = 1,
    ID_RUN          = 2,
    ID_ATTACK       = 3,
    ID_WIN          = 4,
    ID_DIE          = 5,
    EID_COMPELETE = 100
}

CARD_FEED_TYPES     = {
    FEED_HOLE_ONE = 1,
    FEED_HOLE_TWO = 2, -- 第二个
    FEED_HOLE_MEMEBER = 3, --月卡的更新的逻辑
}
-- 道具类型
GoodsType 				= {
    TYPE_AVATAR               = '10', --avatar
    TYPE_DIAMOND              = '11', --幻晶石
    TYPE_GOLD                 = '12', --金币
    TYPE_EXP_ITEM             = '13', --经验道具
    TYPE_CARD_FRAGMENT        = '14', --卡牌碎片
    TYPE_FOOD                 = '15', --食物
    TYPE_FOOD_MATERIAL        = '16', --食材
    TYPE_UPGRADE_ITEM         = '17', --升级用消耗材料
    TYPE_MAGIC_FOOD           = '18', --魔法食物
    TYPE_GOODS_CHEST          = '19', --道具礼包
    TYPE_CARD                 = '20', --卡牌
    TYPE_PET                  = '21', -- 堕神
    TYPE_RECIPE               = '22', -- 食谱
    TYPE_SEASONING            = '23', -- 调料
    TYPE_PET_EGG              = '24', -- 堕神灵体
    TYPE_CARD_SKIN            = '25', -- 卡牌皮肤
    TYPE_UN_STABLE            = '26', -- 不稳定道具
    TYPE_THEME                = '27', -- 主题
    TYPE_GEM                  = '28', -- 宝石
    TYPE_ARTIFACR             = '29', -- 神器碎片
    TYPE_BAIT                 = '32', -- 钓场钓饵
    TYPE_PRIVATEROOM_THEME    = '33', -- 包厢主题
    TYPE_PRIVATEROOM_SOUVENIR = '34', -- 包厢纪念品
    TYPE_CRYSTAL              = '35', -- 转换CG 碎片的水晶
    TYPE_CG_FRAGMENT          = '36', -- CG的碎片
    TYPE_APPOINT_PET          = '37', -- 指定堕神
    TYPE_EXP                  = '38', -- 经验加成道具
    TYPE_TTGAME_CARD          = '39', -- ttGame卡牌
    TYPE_TTGAME_PACK          = '40', -- ttGame卡包
    TYPE_ARCHIVE_REWARD       = '50', -- 成就
    TYPE_ACTIVITY             = '88', -- 活动类别
    TYPE_OTHER                = '89', -- 其他(券)
    TYPE_MONEY                = '90', -- 通用货币
    TYPE_OPTIONAL_CHEST       = '98', -- 可选礼包
}

SoundType = {
    TYPE_GET_CARD         = 1,  --卡牌获得
    TYPE_HOME_CARD_CHANGE = 2,  --主界面更换人物时说话
    TYPE_TOUCH            = 3,  --主界面立绘、经营主管、图鉴鉴赏触摸台词
    TYPE_JIEHUN           = 4,  --结婚后添加至触摸类型3的台词库
    TYPE_ICEROOM_TOUCH    = 5,  --冰场中进行触摸互动时播放
    TYPE_SKILL2           = 6,  --技能2释放
    TYPE_UPGRADE_STAR     = 7,  --卡牌升星时
    TYPE_CAN_NOT_BATTLE   = 8,  --疲劳值不满足出战需求时
    TYPE_ICEROOM_RANDOM   = 9,  --被配置在冰场中的角色，不被触摸的情况下每8~15秒随机播放
    TYPE_TEAM             = 10, --配置到编队中
    TYPE_TEAM_CAPTAIN     = 11, --设置为队长时
    TYPE_BATTLE_DIE       = 12, --死亡时
    TYPE_QI_YUE           = 13, --缔结契约时
    TYPE_COOKED           = 14, --有菜品完成
    TYPE_KAN_BAN          = 15, --设置为功能看板娘时，在5秒~10秒无操作时，随机播放
    TYPE_HOME             = 16, --设置为主界面时，在10秒~15秒无操作时，随机播放
    TYPE_BATTLE_SUCCESS   = 17, --战斗胜利并弹出结算画面时
    TYPE_BATTLE_FAIL      = 18, --战斗失败并弹出结算画面时
    TYPE_CARD_EAT_FOOD    = 19, --在喂食界面点击喂食之后播放
}

SoundChannel = {
    HOME_SCENE         = 1, -- 主界面
    CARD_MANUAL        = 2, -- 卡牌详情
    ICE_ROOM_CLICK     = 3, -- 冰场点击
    LOBBY_VIGOUR       = 4, -- 餐厅新鲜度不足
    CARD_FEED          = 5, -- 卡牌喂食
    AVATAR_QUEST       = 6, -- 餐厅打霸王餐
    FAST_COOKING       = 7, -- 餐厅加速秒备菜
    EXPLORATION_REWARD = 8, -- 探索奖励
    BATTLE_RESULT      = 9, -- 战斗结算
}

NpcImagType 	= {
	TYPE_HEAD 			= 2, --头像
	TYPE_HALF_BODY  	= 3, --半身立绘
}

AVATAR_FRIEND_MESSAGE_TYPE = {
    TYPE_PERISH_RESTAURANT_QUEST_EVENT = 1,       -- 消灭霸王餐
    TYPE_PERISH_RESTAURANT_BUG         = 2,       -- 消灭小鬼
    TYPE_NORMAL                        = 3,       -- 到此一游
}

PROMOTERS_VIEW_TAG = {
    AGENT = 100,                 -- 推广员
    REDEEMCODE = 101,            -- 兑换码
}

MODULE_CLOSE_ERROR = {
    TAG_MATCH = 199,    -- 关闭天城演武
}

UI_AUDIO_TYPE = {
    UI2 = 1,
}

NAV_BAR_HEIGHT = 88

CARD_DRTAIL_VIEW_TAG_FOR_CARDLISTVIEW = 100001
CARD_DRTAIL_VIEW_TAG_FOR_TEAMFORMATIONVIEW = 100002
-- 全部菜谱的系列
ALL_RECIPE_STYLE = "0"
-- 节日菜谱
FESTIVAL_RECIPE_STYLE = "-1"
RECIPE_STYLE = {
    ALL_RECIPE_STYLE = 0 , -- 全部的菜系考察
    GE_RUI_LUO = 1 ,     -- 格瑞洛
    YAO_ZHI_ZHOU =2 ,    -- 耀之州菜系
    YIN_ZHI_DAO = 3 ,    -- 樱之岛菜系
    MO_LIAO_LI = 4 ,     -- 魔法料理
    SHI_LUO_CAI_XI = 5,   -- 失落的菜系
    ACTIVITY_RECIPE_STYLE = 6   -- 活动菜系
}
BATTLE_SCRIPT_TYPE  = {  -- 副本的战斗类型
    MATERIAL_TYPE = 1 , -- 材料本初始为一
    TAG_MATCH     = 2,  -- 天城演武
}

SHARE_TEXT_TYPE = {
    RECALL   = 1,        -- 召回
    DEFAULT  = 2,        -- 默认
    RESERVE  = 3,        -- 新服预约
}

FLAG_MIN_HEAD_ID = 500058     -- 最小头像id
FLAG_MAX_HEAD_ID = 500066     -- 最大头像id


HEADER_PATH           = 'duobaogameCachDir/'
HEADER_ABSOLUTE_PATH  = device.writablePath .. HEADER_PATH

RES_PATH              = 'res/'
RES_ABSOLUTE_PATH     = device.writablePath .. RES_PATH

RES_SUB_PATH          = 'res_sub/'
RES_SUB_ABSOLUTE_PATH = device.writablePath .. RES_SUB_PATH

RES_VERIFY_DB_NAME    = 'resVerify.db'
RES_VERIFY_DB_PATH    = RES_ABSOLUTE_PATH .. RES_VERIFY_DB_NAME

RES_JSON_ZIP_NAME     = 'res.zip'
RES_JSON_ZIP_PATH     = device.writablePath .. RES_JSON_ZIP_NAME

AUDIO_PATH            = 'Audio/'
AUDIO_ABSOLUTE_PATH   = device.writablePath .. AUDIO_PATH

CHAT_DB_NAME          = 'Qmsg_v1.4.db'
CHAT_DB_PATH          = AUDIO_ABSOLUTE_PATH .. CHAT_DB_NAME

AUDIO_RECORD_NAME     = 'wdata.dat'
AUDIO_RECORD_PATH     = AUDIO_ABSOLUTE_PATH .. AUDIO_RECORD_NAME

CV_SHARE_ACTIVITY_KEY = 'IS_CV_SHARE_ACTIVIAY'

--[[
--定义的一些色彩值字号的key值
-- @ 功能标题 px表示字号
-- @param 其他参数
-- @ 可能是组合色彩值
--]]
function fontWithColor( key ,params)

	local keys = {
		------------ old keys ------------
		BPX    = {name = "功能标题字", fontSize = 36},
		M1PX   = {name = "中号字1",   fontSize = 24},
		M2PX   = {name = "中号字2",   fontSize = 28},
		SPX    = {name = "小号字体",   fontSize = 20},
		BC1    = {name = "标题1颜色",  color = "f3f3f3"},
		FC1    = {name = "副表题1颜色", color = "976f64"},
		TC1    = {name = "正文颜色1",   color = '4c4c4c'},
		TC2    = {name = "正文颜色2",   color = '6c6c6c'},
		NC1    = {name = "数量1",      color = 'de5b3d'},
		NC2    = {name = "数量2颜色",   color = 'ba5c5c'},
		BC     = {name = "按钮颜色",    color = 'ffffff'},
		LC     = {name = "列表标题颜色", color = '80675b'},
		GC     = {name = "绿色",        color = 'abce4f'},
		------------ old keys ------------
		['1' ] = { fontSize = 28, color = '#493328', font = TTF_GAME_FONT, ttf = true                                      }, -- 大标题01
		['2' ] = { fontSize = 26, color = '#2b2017', font = TTF_GAME_FONT, ttf = true                                      }, -- 侧页签按钮文字01
		['3' ] = { fontSize = 24, color = '#ffffff'                                                                        }, -- 大标题02
		['4' ] = { fontSize = 24, color = '#76553b'                                                                        }, -- 副标题01
		['5' ] = { fontSize = 22, color = '#7e6454'                                                                        }, -- 副标题02
		['6' ] = { fontSize = 22, color = '#5c5c5c'                                                                        }, -- 正文01
		['7' ] = { fontSize = 28, color = '#ffffff', font = TTF_GAME_FONT, ttf = true                                      }, -- 侧页签按钮文字02
		['8' ] = { fontSize = 20, color = '#78564b'                                                                        }, -- 通用数字01
		['9' ] = { fontSize = 20, color = '#ffffff'                                                                        }, -- 通用数字02
		['10'] = { fontSize = 20, color = '#d23d3d'                                                                        }, -- 强调的数字
		['11'] = { fontSize = 22, color = '#b1613a'                                                                        }, -- 道具标题
		['12'] = { fontSize = 20, color = '#ffffff'                                                                        }, -- 上页签按钮选中
		['13'] = { fontSize = 20, color = '#826d5e'                                                                        }, -- 上页签按钮未选中
		['14'] = { fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#734441'                 }, -- 按钮01
		['15'] = { fontSize = 20, color = '#7c7c7c'                                                                        }, -- tips
		['16'] = { fontSize = 22, color = '#5b3c25'                                                                        }, -- 类型
		['17'] = { fontSize = 22, color = '#e0491a'                                                                        }, -- 侧页签按钮3
		['18'] = { fontSize = 22, color = '#ffffff'                                                                        }, -- 通用描述类文字
		['19'] = { fontSize = 28, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#311717'                 }, -- 大标题03
		['20'] = { fontSize = 50, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#4e2e1e', outlineSize = 2}, -- 大按钮
	}
    -----sadsa
	if nil ~= tonumber(key) then
		if not keys[tostring(key)] then
			print( "############## 未找到编号#" .. key .. "#的版式 ##############" )
		else
            local t = keys[tostring(key)]
            if params then
                table.merge(t,params)
            end
            return t
			-- return keys[key]
		end
	elseif string.find( tostring(key), "#" ) then
		--两种颜色的组合
		local t = string.split(tostring(key), "#")
		local font, color = t[1], t[2]
		if not keys[font] or (not keys[color]) then
			print( "############## 色彩和字号必需在列表之中定义 ##############" )
			print( font, color )
			print(tableToString(keys))
			print( "############## 色彩和字号必需在列表之中定义 ##############" )
		else
			return keys[font].c, keys[color].c
		end
	else
		if not keys[ tostring(key)] then
			print( "############## 色彩和字号必需在列表之中定义 ##############" )
			print(tableToString(keys))
			print( "############## 色彩和字号必需在列表之中定义 ##############" )
		else
            local t = keys[tostring(key)]
            if params then
                table.merge(t,params)
            end
            return t
			-- return keys[key].c
		end
	end
end


--[[
    播放 背景音乐
    @param cueKey : str    音频key（可选，默认是播放当前所在地区的bgm）
]]
function PlayBGMusic(cueKey)
    if app.audioMgr:IsOpenMusic() then
        local cueDefine = {}
        if cueKey == nil then
            cueDefine = BGM_CUE_MAP[app.gameMgr:GetAreaId()] or BGM_CUE_MAP[1]
            app.audioMgr:checkCueSheetByCueKey(cueDefine.cueKey)
        else
            cueDefine.cueName = app.audioMgr:checkCueSheetByCueKey(cueKey)
            cueDefine.cueKey  = cueKey
        end
        if cueDefine.cueName then
            app.audioMgr:PlayBGMusic(cueDefine.cueName, cueDefine.cueKey)
        end
    end
end


--[[
    停止 背景音乐
    @param cueName : str    cue名字（可选，默认是停止播放中的bgm）
]]
function StopBGMusic(cueName)
    app.audioMgr:StopBGMusic(cueName)
end


--[[
    播放 音乐音效
    @param cueKey       : str     音频key
    @param hasPlayback  : bool    是否要返回控制对象（可选，默认false）
]]
function PlayAudioClip(cueKey, hasPlayback)
    if app.audioMgr:IsOpenAudio() then
        local cueName = app.audioMgr:checkCueSheetByCueKey(cueKey)
        if cueName then
            return app.audioMgr:PlayAudioClip(cueName, cueKey, hasPlayback)
        end
    end
end


--[[
    停止 指定音效片段
	@param cueName               : str     cue名字
	@param isIgnoresReleaseTime  : bool    是否立刻停止，忽略ReleaseTime（可选，默认false）
]]
function StopAudioClip(cueKey, isIgnoresReleaseTime)
    app.audioMgr:StopAudioClip(cueKey)
end


-- 播放 通用点击音效
function PlayAudioByClickNormal()
    PlayAudioClip(AUDIOS.UI.ui_click_normal.id)
end
-- 播放 通用关闭音效
function PlayAudioByClickClose()
    PlayAudioClip(AUDIOS.UI.ui_click_close.id)
end


--[[
    播放 战斗音效（因为战斗音效是预加载的，所以不用checkCueSheetByCueKey方法检测。而且战斗音效没规则，也无法检测）
]]
function PlayBattleEffects(cueKey)
    local cueName = app.audioMgr:findCueSheetByCueKey(cueKey)
    if cueName then
        app.audioMgr:PlayAudioClip(cueName, cueKey)
    end
end


-- AUDIOS 的键值必须全部统一大写 ， 这样方便剧情动态匹配
---@class AUDIOS
AUDIOS = {
    ACF = 'music/FoodsSoundEngine.acf',
    -------------------------------------------------
    -- BMG音乐
    BGM = { name = 'BGM', acb = 'music/BGM/BGM.acb', awb = 'music/BGM/BGM.awb', pattern = {'food_', 'bgm_'},  -- 后续再增加请保持bgm_这个规则
        Food_lobby   = { id = 'food_lobby_refectory', descr = '主界面,背景音乐' },
        Food_Battle  = { id = 'food_battle',          descr = '普通战斗音乐' },
        Food_Boss    = { id = 'food_boss',            descr = 'pv音乐吗?' },
        Food_Vow     = { id = 'food_vow',             descr = '飨灵誓约专属BGM' },
        Food_explore = { id = 'food_explore',         descr = '探索专属BGM' },
        Restaurant   = { id = 'bgm_restaurant',       descr = '餐厅' },
        City_2       = { id = 'bgm_zone_2',           descr = '区域2' },
        City_3       = { id = 'food_lobby',           descr = '区域3' },
        City_4       = { id = 'bgm_zone_4',           descr = '区域4' },
        City_5       = { id = 'food_parata',          descr = '区域5' },
    },
    BGM2 = { name = 'BGM2', acb = 'music/BGM/BGM2.acb', awb = 'music/BGM/BGM2.awb', pattern = {'food_', 'bgm_'},  -- 后续再增加请保持bgm_这个规则
        Food_Fishing    = { id = 'food_fishing',    descr = '钓场BGM' },
        Food_Dining     = { id = 'food_dining',     descr = '包厢BGM' },
        Food_Battle3    = { id = 'food_battle3',    descr = '' },
        Food_Ocean      = { id = 'food_ocean',      descr = '' },
        Food_akb_battle = { id = 'food_akb_battle', descr = 'akb角色战斗专属BGM' },
    },
    GHOST = {name = 'GHOST', acb = 'music/BGM/GHOST.acb', awb = 'music/BGM/GHOST.awb', pattern = 'food_ghost_',
        Food_ghost_dancing = { id = 'food_ghost_dancing', descr = '古堡活动背景音乐' },
    },
    WYS = { name = 'WYS', acb = 'music/BGM/WYS.acb', awb = 'music/BGM/WYS.awb', pattern = 'food_wys_',
        FOOD_WYS_GUILINGGAO_HAPPY      = { id = 'food_wys_guilinggao_happy',      descr = '忘忧舍活动剧情bgm' },
        FOOD_WYS_GUILINGGAO_SAD        = { id = 'food_wys_guilinggao_sad',        descr = '忘忧舍活动剧情bgm' },
        FOOD_WYS_XIHUCUYU_DIZI         = { id = 'food_wys_xihucuyu_dizi',         descr = '忘忧舍活动剧情bgm' },
        FOOD_WYS_XIHUCUYU_VOICE        = { id = 'food_wys_xihucuyu_voice',        descr = '忘忧舍活动剧情bgm' },
        STOP_FOOD_WYS_GUILINGGAO_HAPPY = { id = 'stop_food_wys_guilinggao_happy', descr = '' },
        STOP_FOOD_WYS_GUILINGGAO_SAD   = { id = 'stop_food_wys_guilinggao_sad',   descr = '' },
        STOP_FOOD_WYS_XIHUCUYU_DIZI    = { id = 'stop_food_wys_xihucuyu_dizi',    descr = '' },
        STOP_FOOD_WYS_XIHUCUYU_VOICE   = { id = 'stop_food_wys_xihucuyu_voice',   descr = '' },
    },
    YLY = { name = 'YLY', acb = 'music/BGM/YLY.acb', awb = 'music/BGM/YLY.awb', pattern = 'food_yly_',
        FOOD_YLY_STRANGE       = { id = 'food_yly_strange',       descr = '诡异的游乐园背景音乐' },
        FOOD_YLY_MUSICBOX      = { id = 'food_yly_musicbox',      descr = '飨灵誓约专属BGM' },
        FOOD_YLY_SAD           = { id = 'food_yly_sad',           descr = '' },
        FOOD_YLY_HAPPY         = { id = 'food_yly_happy',         descr = '' },
        STOP_FOOD_YLY_STRANGE  = { id = 'stop_food_yly_strange',  descr = '' },
        STOP_FOOD_YLY_MUSICBOX = { id = 'stop_food_yly_musicbox', descr = '' },
        STOP_FOOD_YLY_SAD      = { id = 'stop_food_yly_sad',      descr = '' },
        STOP_FOOD_YLY_HAPPY    = { id = 'stop_food_yly_happy',    descr = '' },
    },
    XNH = { name = 'XNH', acb = 'music/BGM/XNH.acb', awb = 'music/BGM/XNH.awb', pattern = 'food_xnh_',
        FOOD_XNH_HAISHENJI = {id = 'food_xnh_haishenji', descr = '春节活动剧情bgm【海神祭】'},
        FOOD_XNH_JIEDAO    = {id = 'food_xnh_jiedao',    descr = '春节活动剧情bgm【春节氛围的集市街道】'},
    },
    ZNQ = { name = 'ZNQ', acb = 'music/BGM/ZNQ.acb', awb = 'music/BGM/ZNQ.awb', pattern = 'food_znq_',
        Food_Znq_Sakura   = { id = 'food_znq_sakura',   descr = '周年庆套圈' },
        Food_Znq_Western  = { id = 'food_znq_western',  descr = '周年剧情使用' },
        Food_Znq_Firework = { id = 'food_znq_firework', descr = '周年剧情使用' },
        Food_Znq_China    = { id = 'food_znq_china',    descr = '周年庆主界面背景音乐' },
    },
    ALICE = { name = 'ALICE', acb = 'music/BGM/Alice.acb', awb = 'music/BGM/Alice.awb', pattern = 'food_alice_',
        Food_alice_dream   = { id = 'food_alice_dream',   descr = '19周年庆背景音乐' },
        Food_alice_dance   = { id = 'food_alice_dance',   descr = '19周年庆背景音乐' },
    },
    SZG = { name = 'SZG', acb = 'music/BGM/SZG.acb', awb = 'music/BGM/SZG.awb', pattern = 'food_szg_',
        FOOD_SZG_OPERA = {id = 'food_szg_opera', descr = '时钟活动主题bgm'},
        FOOD_SZG_SOUL  = {id = 'food_szg_soul',  descr = '时钟活动主题bgm（前半段）'},
    },
    HZJ = { name = 'HZJ', acb = 'music/BGM/HZJ.acb', awb = 'music/BGM/HZJ.awb', pattern = 'food_hzj_',
        FOOD_HZJ_HUAZHAO = {id = 'food_hzj_huazhao', descr = '花朝节bgm'},
        FOOD_HZJ_JITAN   = {id = 'food_hzj_jitan',   descr = '祭坛bgm'},
    },
    BWY = { name = 'BWY', acb = 'music/BGM/BWY.acb', awb = 'music/BGM/BWY.awb', pattern = 'food_bwy_',
        FOOD_BWY_HUAZHAO = {id = 'food_bwy_yexing', descr = '百鬼夜行bgm'},
        FOOD_BWY_JITAN   = {id = 'food_bwy_jidian', descr = '祭奠bgm'},
    },
    PT = { name = 'PT', acb = 'music/BGM/PT.acb', awb = 'music/BGM/PT.awb', pattern = 'food_pt_',
        FOOD_PT_BGM         = {id = 'food_pt_bgm', descr = 'pt本bgm'},
        FOOD_PT_EVERLASTING = {id = 'food_pt_everlasting', descr = 'pt本主题曲'},
    },
    STORY = { name = 'Story', acb = 'music/BGM/Story.acb', awb = 'music/BGM/Story.awb', pattern = 'food_story_',
        FOOD_STORY_DOOM            = { id = 'food_story_doom',            descr = '' },
        FOOD_STORY_SAD             = { id = 'food_story_sad',             descr = '' },
        FOOD_STORY_STRANGE         = { id = 'food_story_strange',         descr = '' },
        FOOD_STORY_DROIYAN         = { id = 'food_story_droiyan',         descr = '' },
        FOOD_STORY_FATE            = { id = 'food_story_fate',            descr = '' },
        FOOD_STORY_URGENT          = { id = 'food_story_urgent',          descr = '' },
        FOOD_STORY_PASSIONATE      = { id = 'food_story_passionate',      descr = '' },
        FOOD_STORY_TERROR          = { id = 'food_story_terror',          descr = '' },
        FOOD_STORY_FUNNY           = { id = 'food_story_funny',           descr = '' },
        FOOD_STORY_DAWN            = { id = 'food_story_dawn',            descr = '' },
        FOOD_STORY_PARATA          = { id = 'food_story_parata',          descr = '' },
        STOP_FOOD_STORY_DOOM       = { id = 'stop_food_story_doom',       descr = '' },
        STOP_FOOD_STORY_SAD        = { id = 'stop_food_story_sad',        descr = '' },
        STOP_FOOD_STORY_STRANGE    = { id = 'stop_food_story_strange',    descr = '' },
        STOP_FOOD_STORY_DROIYAN    = { id = 'stop_food_story_droiyan',    descr = '' },
        STOP_FOOD_STORY_FATE       = { id = 'stop_food_story_fate',       descr = '' },
        STOP_FOOD_STORY_URGENT     = { id = 'stop_food_story_urgent',     descr = '' },
        STOP_FOOD_STORY_PASSIONATE = { id = 'stop_food_story_passionate', descr = '' },
        STOP_FOOD_STORY_TERROR     = { id = 'stop_food_story_terror',     descr = '' },
        STOP_FOOD_STORY_FUNNY      = { id = 'stop_food_story_funny',      descr = '' },
        STOP_FOOD_STORY_DAWN       = { id = 'stop_food_story_dawn',       descr = '' },
        STOP_FOOD_STORY_PARATA     = { id = 'stop_food_story_parata',     descr = '' },
    },
    SSG = { name = 'SSG', acb = 'music/BGM/SSG.acb', awb = 'music/BGM/SSG.awb', pattern = 'food_ssg_',
        FOOD_SSG_SUSHISHU = { id = 'food_ssg_sushishu', descr = '' },
    },
    -------------------------------------------------
    -- UI音效
    UI = { name = 'UI', acb = 'music/Sound/UI.acb', awb = '', pattern = {'ui_', 'ty_8'},
        ui_logo                 = { id = 'ui_logo',                 descr = 'logo展示' },
        ui_click_normal         = { id = 'ui_click_normal',         descr = '通用点击' },
        ui_click_close          = { id = 'ui_click_close',          descr = '通用关闭' },
        ui_click_confirm        = { id = 'ui_click_confirm',        descr = '选中' },
        ui_use                  = { id = 'ui_use',                  descr = '使用' },
        ui_window_show          = { id = 'ui_window_show',          descr = '展开羊皮纸' },
        ui_window_open          = { id = 'ui_window_open',          descr = '弹出窗口类界面' },
        ui_card_open            = { id = 'ui_card_open',            descr = '弹出显示卡牌' },
        ui_ice                  = { id = 'ui_ice',                  descr = '冰场' },
        ui_talent               = { id = 'ui_talent',               descr = '天赋' },
        ui_chest_open           = { id = 'ui_chest_open',           descr = '宝箱打开' },
        ui_change               = { id = 'ui_change',               descr = '大型界面切换' },
        ui_gold_smash           = { id = 'ui_gold_smash',           descr = '顶部金币兑换/金币砸蛋' },
        --- backpack背包
        ui_depot_tabchange      = { id = 'ui_depot_tabchange',      descr = '页签切换/清脆的击打瓷器' },
        ui_package_open         = { id = 'ui_package_open',         descr = '使用礼包/包裹打开' },
        ui_coin                 = { id = 'ui_coin',                 descr = '金币包使用/金币撞击声' },
        ui_diamond              = { id = 'ui_diamond',              descr = '幻晶石包使用/幻晶石撞击声' },
        ---任包
        ui_dailymission         = { id = 'ui_dailymission',         descr = '日常任务完成/奖励获取篮子弹出' },
        ui_mission              = { id = 'ui_mission',              descr = '任务完成/奖励获得（筷子）' },
        --抽卡
        ui_await                = { id = 'ui_await',                descr = '待机状态/背景循环音效' },
        ui_additive             = { id = 'ui_additive',             descr = '加入添加物/播放动作' },
        ui_flame                = { id = 'ui_flame',                descr = '火焰变大' },
        ui_card_movie           = { id = 'ui_card_movie',           descr = '抽卡动画' },
        ui_card_slide           = { id = 'ui_card_slide',           descr = '卡牌弹出' },
        --卡牌养成
        ui_star                 = { id = 'ui_star',                 descr = '升星/配合动画效果' },
        ui_levelup              = { id = 'ui_levelup',              descr = '升级/配合动画效果' },
        --誓约界面
        ui_vow_start            = { id = 'ui_vow_start',            descr = '誓约开始音效' },
        ui_vow_idle             = { id = 'ui_vow_idle',             descr = '誓约待机音效' },
        ui_vow_longpress        = { id = 'ui_vow_longpress',        descr = '誓约长按音效' },
        stop_ui_vow_idle        = { id = 'stop_ui_vow_idle',        descr = '停止idle的同时开始longpress' },
        ui_vow_end              = { id = 'ui_vow_end',              descr = '誓约结束音效' },
        ui_vow_settlement       = { id = 'ui_vow_settlement',       descr = '誓约过渡音效' },
        ui_vow_interim          = { id = 'ui_vow_interim',          descr = '誓约对话框音效' },
        --关卡
        ui_light                = { id = 'ui_light',                descr = '过关结算/点亮火焰' },
        ui_experience           = { id = 'ui_experience',           descr = '过关结算/经验增加' },
        ui_gift                 = { id = 'ui_gift',                 descr = '过关结算/奖励掉落' },
        --经营
        ui_building             = { id = 'ui_building',             descr = '建造中/锯木声' },
        ui_tab_change           = { id = 'ui_tab_change',           descr = '页签切换/瓷器相互碰撞声' },
        --外卖
        ui_moto                 = { id = 'ui_moto',                 descr = '摩托车启动声' },
        --厨房
        ui_select               = { id = 'ui_select',               descr = '选中操作台/飞出放大' },
        ui_menu_open            = { id = 'ui_menu_open',            descr = '菜谱展开' },
        ui_cook_saute           = { id = 'ui_cook_saute',           descr = '操作台工作-炒/配合动画' },
        ui_cook_steam           = { id = 'ui_cook_steam',           descr = '操作台工作-蒸/配合动画' },
        ui_cook_roast           = { id = 'ui_cook_roast',           descr = '操作台工作-烤/配合动画' },
        ui_cook_ice             = { id = 'ui_cook_ice',             descr = '操作台工作-冰/配合动画' },
        ui_cook_sweet           = { id = 'ui_cook_sweet',           descr = '操作台工作-甜/配合动画' },
        --编队
        ui_duiwu_sz             = { id = 'ui_duiwu_sz',             descr = '编队/上阵卡牌' },
        -- 结算
        ui_war_win              = { id = 'ui_war_win',              descr = '胜利结果' },
        ui_war_lose             = { id = 'ui_war_lose',             descr = '失败结果' },
        ui_war_assess           = { id = 'ui_war_assess',           descr = '胜利后星级评价' },
        -- 餐厅
        ui_restaurant_enter     = { id = 'ui_restaurant_enter',     descr = '进入好友餐厅音效' },
        ui_restaurant_levelup   = { id = 'ui_restaurant_levelup',   descr = '餐厅升级的动画音效' },
        -- 空艇
        ui_transport_prediction = { id = 'ui_transport_prediction', descr = '空艇装载预告' },
        ui_transport_down       = { id = 'ui_transport_down',       descr = '巨钳蟹货船下落停靠' },
        ui_transport_cut        = { id = 'ui_transport_cut',        descr = '点击道具后切换进入装箱界面' },
        ui_transport_depart     = { id = 'ui_transport_depart',     descr = '开船货船上升' },
        -- 餐厅打虫
        ui_lubi_appear          = { id = 'ui_lubi_appear',          descr = '露比出现声' },
        ui_lubi_disappear       = { id = 'ui_lubi_disappear',       descr = '露比被击杀的声音' },
        -- 爬塔
        ui_relic_appear         = { id = 'ui_relic_appear',         descr = '宝箱上升的音效、以及宝箱落地' },
        ui_relic_cut            = { id = 'ui_relic_cut',            descr = '人物转换的音效' },
        ui_relic_levelup        = { id = 'ui_relic_levelup',        descr = '宝箱契约升级' },
        -- 工会
        ui_union_change         = { id = 'ui_union_change',         descr = '切换飨灵外观动画' },
        -- 工会狩猎
        ui_shoutun_idle         = { id = 'ui_shoutun_idle',         descr = '兽吞待机画面' },
        ui_shoutun_sleep        = { id = 'ui_shoutun_sleep',        descr = '兽吞沉睡画面' },
        ui_shoutuanzi_run       = { id = 'ui_shoutuanzi_run',       descr = '在兽吞被击败一次远古堕神功能开启后，兽团子在战斗结束后出现的动画。【幼兽和角兽也尽量接近兽团子的跑动音效】' },
        ui_shouyao_run          = { id = 'ui_shouyao_run',          descr = '在兽吞被击败一次远古堕神功能开启后，兽咬在战斗结束后出现的动画。' },
        ui_shoutuanzi_energy    = { id = 'ui_shoutuanzi_energy',    descr = '在兽吞被击败一次远古堕神功能开启后，兽团子在战斗结束后吞噬能量的动画。' },
        ui_shoutuanzi_win       = { id = 'ui_shoutuanzi_win',       descr = '在兽吞被击败一次远古堕神功能开启后，兽团子在吸收了能量后的动画。' },
        ui_shoutuanzi_reaction  = { id = 'ui_shoutuanzi_reaction',  descr = '在兽吞被击败一次远古堕神功能开启后，兽团子在吸收了能量后的动画。' },
        -- 虚盒
        ui_irrigate_bubble      = { id = 'ui_irrigate_bubble',      descr = '水泡出现' },
        ui_irrigate_splash      = { id = 'ui_irrigate_splash',      descr = '有种水泡翻腾了一下的感觉' },
        ui_evolution_speedup    = { id = 'ui_evolution_speedup',    descr = '灵体使用幻晶石加速净化' },
        ui_strengthen_success   = { id = 'ui_strengthen_success',   descr = '强化成功的音效' },
        ui_strengthen_failure   = { id = 'ui_strengthen_failure',   descr = '强化失败的音效' },
        ui_regenerate_loop      = { id = 'ui_regenerate_loop',      descr = '堕神再生转轮的声音' },
        ui_regenerate_end       = { id = 'ui_regenerate_end',       descr = '转轮放慢速度' },
        ui_regenerate_result    = { id = 'ui_regenerate_result',    descr = '再生结果' },
        -- 协力作战
        ui_teamwork_appear      = { id = 'ui_teamwork_appear',      descr = '组队翻牌4张卡出现的动画' },
        ui_teamwork_reverse     = { id = 'ui_teamwork_reverse',     descr = '翻单张卡' },
        ui_teamwork_turn        = { id = 'ui_teamwork_turn',        descr = '其他卡翻过来' },
        -- 活动
        ui_activity_wheel       = { id = 'ui_activity_wheel',       descr = '转盘音效' },
        -- 探索
        ui_explore_treasure     = { id = 'ui_explore_treasure',     descr = '探索结束后得到宝箱，点击宝箱后宝箱开启的音效' },
        -- 夏活
        ui_cutin_boss           = { id = 'ui_cutin_boss',           descr = '玩家遭遇BOSS时会切入cut in' },
        ui_cutin_story          = { id = 'ui_cutin_story',          descr = '玩家遭遇剧情彩蛋时会切入cut in，需要一种悦耳的提示音。' },
        ui_light_boss           = { id = 'ui_light_boss',           descr = '火焰燃烧和熄灭的声音。' },
        ui_machine_one          = { id = 'ui_machine_one',          descr = '玩家消耗一枚游戏币，一枚游戏币被投入扭蛋机内，小丑摇头晃脑后从嘴里吐出扭蛋' },
        ui_machine_ten          = { id = 'ui_machine_ten',          descr = '玩家消耗10枚游戏币，10枚游戏币被投入扭蛋机内，小丑摇头晃脑后伸长（弹出）脖子，从空中掉落扭蛋' },
        ui_egg_one              = { id = 'ui_egg_one',              descr = '一枚扭蛋被打开的声音' },
        ui_egg_ten              = { id = 'ui_egg_ten',              descr = '十枚扭蛋被打开的声音，除了扭蛋扭出来的声音外加一些别的变化，不用太繁琐' },
        -- 钓场
        ui_fishing_pole         = { id = 'ui_fishing_pole',         descr = '飨灵垂钓开始时，挥动钓竿的声音' },
        -- 包厢
        ui_dining_ring          = { id = 'ui_dining_ring',          descr = '西餐厅呼叫服务员的铃声' },
        --招财猫界面
        ui_cat_start            = { id = 'ui_cat_start',            descr = '招财猫开始' },
        ui_cat_end              = { id = 'ui_cat_end',              descr = '招财猫结束' },
        -- 皮肤卡池动画
        ui_skin_start           = { id = 'ui_skin_start',           descr = '转盘指针开始快速转动后的音效' },
        ui_skin_loop            = { id = 'ui_skin_loop',            descr = '转盘状态音效' },
        ui_skin_pointer         = { id = 'ui_skin_pointer',         descr = '转盘指针音效' },
        ui_skin_end             = { id = 'ui_skin_end',             descr = '金币弹出音效' },
        ui_skin_result          = { id = 'ui_skin_result',          descr = '金币翻转音效' },
    },
    UI2 = { name = 'UI2',acb = 'music/Sound/UI2.acb', awb = '', pattern = 'ui_',
        UI_CARD_POOL = { id = 'ui_cardpool', descr = '选卡卡池' },
        UI_PIG_ONE   = { id = 'ui_pig_one',  descr = '19春活单抽' },
        UI_PIG_TEN   = { id = 'ui_pig_ten',  descr = '19春活十连抽' },
    },
    -------------------------------------------------
    -- 战斗音效
    BATTLE = { name = 'battle', acb = 'music/Sound/Battle.acb', awb = '',
        ty_attack_nengliang = {id = 'ty_attack_nengliang', descr = '普攻-能量攻击'},
        ty_attack_qiaoji    = {id = 'ty_attack_qiaoji',    descr = '普攻-近战敲击'},
        ty_attack_sheji     = {id = 'ty_attack_sheji',     descr = '普攻-枪械射击'},
        ty_attack_tuci      = {id = 'ty_attack_tuci',      descr = '普攻-近战突刺'},
        ty_attack_zhanji    = {id = 'ty_attack_zhanji',    descr = '普攻-刀剑斩击'},
        ty_attack_zhiliao   = {id = 'ty_attack_zhiliao',   descr = '普攻-治疗效果'},
        ty_attack_zhongji   = {id = 'ty_attack_zhongji',   descr = '普攻-钝器重击'},
        ty_beattack_baozha  = {id = 'ty_beattack_baozha',  descr = '爆击-爆炸打击'},
        ty_beattack_wuli    = {id = 'ty_beattack_wuli',    descr = '背击-物理打击'},
        ty_battle_baoqi     = {id = 'ty_battle_baoqi',     descr = '技能-爆气'},
        ty_beattack_binlie  = {id = 'ty_beattack_binlie',  descr = '冰裂'},
        ty_beattack_tanfei  = {id = 'ty_beattack_tanfei',  descr = '弹飞'}
    },
    -------------------------------------------------
    -- 战斗音效2
    BATTLE2 = { name = 'battle2', acb = 'music/Sound/Battle2.acb', awb = ''
    },
    -------------------------------------------------
    -- avatar餐厅部件
    AVATAR = { name = 'avatar', acb = 'music/Sound/Avatar.acb', awb = '', pattern = 'avatar_',
        AVATAR_CHRISTMAS_BELL      = { id = 'avatar_christmas_bell',      descr = '圣诞节-铃声' },
        AVATAR_CHRISTMAS_CAT       = { id = 'avatar_christmas_cat',       descr = '圣诞节-两只猫咪' },
        AVATAR_CHRISTMAS_DOG       = { id = 'avatar_christmas_dog',       descr = '圣诞节-打喷嚏的狗' },
        AVATAR_CHRISTMAS_GIFTS_1   = { id = 'avatar_christmas_gifts_1',   descr = '圣诞节-礼物盒1' },
        AVATAR_CHRISTMAS_GIFTS_2   = { id = 'avatar_christmas_gifts_2',   descr = '圣诞节-礼物盒2' },
        AVATAR_CHRISTMAS_GIFTS_3   = { id = 'avatar_christmas_gifts_3',   descr = '圣诞节-礼物盒3' },
        AVATAR_CHRISTMAS_GIFTS_4   = { id = 'avatar_christmas_gifts_4',   descr = '圣诞节-礼物盒4' },
        AVATAR_CHRISTMAS_GIFTS_5   = { id = 'avatar_christmas_gifts_5',   descr = '圣诞节-礼物盒5' },
        AVATAR_CHRISTMAS_GIFTS_6   = { id = 'avatar_christmas_gifts_6',   descr = '圣诞节-礼物盒6' },
        AVATAR_CHRISTMAS_LETTERS   = { id = 'avatar_christmas_letters',   descr = '圣诞节-圣诞节日' },
        AVATAR_CHRISTMAS_REINDEER  = { id = 'avatar_christmas_reindeer',  descr = '圣诞节-小鹿' },
        AVATAR_CHRISTMAS_SNOWMAN_1 = { id = 'avatar_christmas_snowman_1', descr = '圣诞节-雪人1' },
        AVATAR_CHRISTMAS_SNOWMAN_2 = { id = 'avatar_christmas_snowman_2', descr = '圣诞节-雪人2' },
        AVATAR_CHRISTMAS_SNOWMAN_3 = { id = 'avatar_christmas_snowman_3', descr = '圣诞节-雪人3' },
        AVATAR_WEDDING_PIANO       = { id = 'avatar_wedding_piano',       descr = '海洋-海带舞曲' },
        FOOD_AVATAR_SEA_DANCE      = { id = 'food_avatar_sea_dance',      descr = '？？？' },
    },
    -------------------------------------------------
    -- 对话音效
    AMB = { name = 'AMB', acb = 'music/Sound/Amb.acb', awb = '', pattern = 'ty_',
        Ty_gaogenxie = { id = 'ty_gaogenxie', descr = '古堡活动音效' },
        Ty_diji      = { id = 'ty_diji',      descr = '' },
        Ty_gaoji     = { id = 'ty_gaoji',     descr = '' },
        Ty_posui     = { id = 'ty_posui',     descr = '古堡活动音效' },
    },
    AMB2 = { name = 'AMB2', acb = 'music/Sound/Amb2.acb', awb = '', pattern = 'ty_',
        Ty_b52za   = { id = 'ty_b52za',   descr = 'B52式突然砸下' },
        Ty_bore    = { id = 'ty_bore',    descr = '堕神般若发出的声音' },
        Ty_jingbao = { id = 'ty_jingbao', descr = '魔导学园的空中警报声' },
        Ty_jingxia = { id = 'ty_jingxia', descr = '惊吓音效' },
        Ty_jiqiren = { id = 'ty_jiqiren', descr = '机器人的机器声' },
        Ty_lang    = { id = 'ty_lang',    descr = '海浪拍打礁石的声音' },
        Ty_strom   = { id = 'ty_strom',   descr = '海上暴风雨' },
        Ty_wuya    = { id = 'ty_wuya',    descr = '乌鸦叫声' },
        Ty_zhentan = { id = 'ty_zhentan', descr = '柯南必备音效' },
        Ty_zhong   = { id = 'ty_zhong',   descr = '钟声音效' },
    },
}
-- 各大区域bgm定义
BGM_CUE_MAP = {
    [1] = {cueName = AUDIOS.BGM.name, cueKey = AUDIOS.BGM.Food_lobby.id},
    [2] = {cueName = AUDIOS.BGM.name, cueKey = AUDIOS.BGM.City_2.id},
    [3] = {cueName = AUDIOS.BGM.name, cueKey = AUDIOS.BGM.City_3.id},
    [4] = {cueName = AUDIOS.BGM.name, cueKey = AUDIOS.BGM.City_4.id},
    [5] = {cueName = AUDIOS.BGM.name, cueKey = AUDIOS.BGM.City_5.id},
    [6] = {cueName = AUDIOS.BGM.name, cueKey = AUDIOS.BGM.City_5.id},
}
-- CriAtom 播放器状态
CRIATOM_PLAYER_STATUS = {
    STOP  = 0,
    PREP  = 1,
    PLAY  = 2,
    ENDED = 3,
    ERROR = 4,
}


---------------------------------------------------
-- spine animation cache begin --
---------------------------------------------------
-- spine缓存池
SpineCacheName = {
    BATTLE           = 'battle',
    GLOBAL           = 'global',
    COMMON           = 'common',
    TOWER            = 'tower',
    UNION            = 'union',
    ARTIFACT         = 'artifact',
    FISHING          = 'fishing',
    ANNIVERSARY      = 'anniversary',
    ANNIVERSARY_2019 = 'anniversary2019',
    ANNIVERSARY_2020 = 'anniversary2020',
    BLACK_GOLD       = 'blackGold',
    TTGAME           = 'ttGame',
    CAT_HOUSE        = 'catHouse',
    MURDER           = 'murder' , 
}

--[[
根据key name获取spine缓存池实例
@params name SpineCacheName cache key name
@return _ sp.SpineAnimationCache spine animation cache
--]]
function SpineCache(name)
    return sp.SpineAnimationCache:getInstance(name)
end


---------------------------------------------------
-- spine animation cache end --
---------------------------------------------------


RES_TYPE = {
    FILE     = 'file',     -- 单一文件
    SPINE    = 'spine',    -- spine文件
    PARTICLE = 'particle', -- 粒子文件
}

NomalResMeta = {
    __tostring = function(obj)
        return obj.path
    end
}

-- 粒子资源
function _ptl(path)
    local data = {
        type  = RES_TYPE.PARTICLE,
        path  = path,
    }
    setmetatable(data, NomalResMeta)
    return data
end

-- spine资源
function _spn(path)
    local data = {
        type  = RES_TYPE.SPINE,
        path  = path,
        json  = path .. '.json',
        atlas = path .. '.atlas',
    }
    setmetatable(data, NomalResMeta)
    return data
end

-- spine资源 扩展方法
-- 可以在原始路径 path 后面追加主题路径 theme
-- e.g. path/theme/xxxx.xxx
function _spnEx(path, theme)
    local spinePath = tostring(path)
    if theme and (string.len(theme) > 0) then
        local lastPos = 0
        for st, sp in function() return string.find(spinePath, '/', lastPos, true) end do
            lastPos = sp + 1
        end
        local path = string.sub(spinePath, 1, lastPos - 1)
        local name = string.sub(spinePath, lastPos)
        local file = string.format('%s%s/%s', path, theme, name)
        if FTUtils:isPathExistent(file .. '.json') then
            spinePath = file
        end
    end
    return _spn(spinePath)
end

-- 资源路径 扩展方法
-- 可以在原始路径 path 后面追加主题路径 theme
-- e.g. path/theme/xxxx.xxx
function _resEx(path, notImg , theme)
    local resPath = tostring(path)
    local getFileName = function(name)
        return (utils and not notImg) and utils.getFileName(name) or name
    end
    if theme and (string.len(theme) > 0) then
        local lastPos = 0
        for st, sp in function() return string.find(resPath, '/', lastPos, true) end do
            lastPos = sp + 1
        end
        local path = string.sub(resPath, 1, lastPos - 1)
        local name = string.sub(resPath, lastPos)
        local file = _res(string.format('%s%s/%s', path, theme, name), notImg)
        if FTUtils:isPathExistent(file) then
            return file
        else
            _res(resPath, notImg)
        end
    end
    return _res(resPath, notImg)
end


--[[
    增加一个预移除前，让根级脱离交互的方法。一般用在执行 action 前先预处理一下，然后安静等待 action 执行完毕。
    防止自身在 removeSelf 执行时，被 touchBegen 捕捉记录，touchEnded 时就会报空指针的闪退问题。
]]
function preremove(owner)
    if owner and not tolua.isnull(owner) then
        for index, node in ipairs(owner:getChildren()) do
            node:setVisible(false)
            if node.setEnabled then
                node:setEnabled(false)
            end
            if node.setTouchEnabled then
                node:setTouchEnabled(false)
            end
            if node.setOnClickScriptHandler then
                node:stopAllActions()
                node:setOnClickScriptHandler(nil)
            end
            -- if node.setOnTouchBeganScriptHandler then
            --     node:setOnTouchBeganScriptHandler(function(sender, touch) sender:retain() return true end)
            -- end
            -- if node.setOnTouchMovedScriptHandler then
            --     node:setOnTouchMovedScriptHandler(function(sender, touch) return true end)
            -- end
            -- if node.setOnTouchEndedScriptHandler then
            --     node:setOnTouchEndedScriptHandler(function(sender, touch) sender:release() return true end)
            -- end
            preremove(node)
        end
    end
end


--[[
    安全移除动作。推荐代码中 cc.RemoveSelf:create() 改为 cc.SafeRemoveSelf:create()
    原理为顶部显示一个交互格挡层，防止对象在remove过程中被touch事件捕捉到。
]]
local BLOCK_CLICK_LAYER_TAG = 99999
cc.SafeRemoveSelf = {
    create = function(_, owner)
        local blockClickLayer = sceneWorld:getChildByTag(BLOCK_CLICK_LAYER_TAG)
        if not blockClickLayer or tolua.isnull(blockClickLayer) then
            blockClickLayer = display.newButton(0, 0, {size = display.size})
            blockClickLayer:setTag(BLOCK_CLICK_LAYER_TAG)
            blockClickLayer:setAnchorPoint(display.LEFT_BOTTOM)
            sceneWorld:addChild(blockClickLayer, BLOCK_CLICK_LAYER_TAG)
        end

        return cc.Sequence:create(
            cc.CallFunc:create(function()
                preremove(owner)
                blockClickLayer:stopAllActions()
                blockClickLayer:runAction(cc.Sequence:create(
                    cc.Show:create(),
                    cc.DelayTime:create(0.2), -- 目的：让目标执行完动作
                    cc.Hide:create()
                ))
            end),
            cc.Hide:create(),
            cc.DelayTime:create(0.1), -- 目的：让拥有 animate 的按钮动作执行完毕
            cc.RemoveSelf:create()
        )
    end
}
