--[[
游戏数据管理模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class DataManager
local DataManager = class('DataManager',ManagerBase)
local isRecordRedLog = false

DataManager.instances = {}

----------------------------------
-- config data

TOTAL_DAY_NUMS 		= 7 --新手活动总天数

CARD_BREAK_MAX 		= 5 --突破的最大等级
CARD_LEVEL_MAX 		= 100 --卡牌最大等级
ORGANIZE_MAX        = 6  --编队的最大数量只会有4组

CARD_FILTER_TYPE_ALL        = 99 --过滤卡牌类型
CARD_FILTER_TYPE_DEF        = CardUtils.CAREER_TYPE.DEFEND --防守(肉盾)
CARD_FILTER_TYPE_NEAR_ATK   = CardUtils.CAREER_TYPE.ATTACK --近战
CARD_FILTER_TYPE_REMOTE_ATK = CardUtils.CAREER_TYPE.ARROW --远程攻击
CARD_FILTER_TYPE_DOCTOR     = CardUtils.CAREER_TYPE.HEART --治疗
CARD_FILTER_TYPE_SUIPIAN    = 5 --碎片
CARD_FILTER_TYPE_ARTIACT    = 6 --神器

MONSTER_SMALL = 1 --小怪
MONSTER_ELITE = 2 --精英怪
MONSTER_BOSS = 3 --boss怪

USE_ITEM_TYPE_DIAMOND 	= '0' --道具使用类型为幻晶石类
USE_ITEM_TYPE_GOLD 		= '1' --道具使用类型为金币类
USE_ITEM_TYPE_HP 		= '2' --道具使用类型为体力类
USE_ITEM_TYPE_EXP       = '5' --使用主角经验道具
USE_ITEM_TYPE_MEMBER    = '7' --道具使用类型为月卡类

--堕神增加基础属性type
PET_BASEATTR_TYPE_ATK 		= '1'
PET_BASEATTR_TYPE_DEF		= '2'
PET_BASEATTR_TYPE_HP		= '3'
PET_BASEATTR_TYPE_CRITRATE	= '4'
PET_BASEATTR_TYPE_CRITDAMAGE= '5'
PET_BASEATTR_TYPE_ATKSPEED	= '6'

PTM_RATIO = 32.0 --物理世界比率

TOP_HEIGHT = 66 --最上方的距离

-- 编队最大人数
MAX_TEAM_MEMBER_AMOUNT = 5
-- 车轮战默认的最大队伍数量
MAX_TAG_MATCH_TEAM_AMOUNT = 3

-- pvc
-- pvc活跃度单条满值
PVC_ACTIVE_POINT_MAX = 500

COORDINATE_TYPE_HOME           = 1 --主界面对应的 坐标类别信息
COORDINATE_TYPE_TEAM           = 2 --编队中对应的 坐标类别信息
COORDINATE_TYPE_HEAD           = 3 --头像对应的 坐标类别信息
COORDINATE_TYPE_CAPSULE        = 4 --抽卡对应的 坐标类别信息
COORDINATE_TYPE_LIVE2D_HOME    = 5 --l2d主界面对应的 坐标类别信息
COORDINATE_TYPE_LIVE2D_CAPSULE = 6 --l2d抽卡对应的 坐标类别信息

QUEST_TYPE_NORMAL 		= 1 -- 主线关卡类型 普通
QUEST_TYPE_ELITE 		= 2 -- 主线关卡类型 精英
QUEST_TYPE_BOSS 		= 3 -- 主线关卡类型 boss
QUEST_TYPE_TREASURE 	= 4 -- 主线关卡类型 宝箱

QUEST_DIFF_NORMAL 		= 1 -- 地图关卡难度 普通
QUEST_DIFF_HARD 		= 2 -- 地图关卡难度 困难
QUEST_DIFF_HISTORY 		= 3 -- 地图关卡难度 史诗

-- 1烹饪,2大堂,3外卖,4料理副本

LOBBY_SUPERVISOR 	= '1' -- 大堂主管
LOBBY_CHEF			= '2' -- 大堂厨师
LOBBY_WAITER		= '3' -- 大堂服务员
TASTING_TOUR_ASSISTANT = '4'


-- 所属功能,1烹饪,2大堂,3外卖,4料理副本,5包厢
CARD_BUSINESS_SKILL_MODEL_ALL			= 0
CARD_BUSINESS_SKILL_MODEL_COOK  		= 1
CARD_BUSINESS_SKILL_MODEL_LOBBY			= 2
CARD_BUSINESS_SKILL_MODEL_TAKEWAY		= 3
CARD_BUSINESS_SKILL_MODEL_COOKCHAPTER	= 4
CARD_BUSINESS_SKILL_MODEL_PRIVATEROOM	= 5


-- 充值类型
PAY_TYPE = {
	PT_ORDINARY             = 1,      -- 普通充值
	PT_MEMBER               = 2,      -- 月卡
	PT_GIFT                 = 3,      -- 礼包
	PT_LV_GIFT              = 4,      -- 等级礼包
	PT_TIME_LIMIT_GIFT      = 5,      -- 限时礼包
	PT_LEVEL_ADVANCE_CHEST  = 6,      -- 进阶等级礼包
	PT_PASS_TICKET          = 7,      -- pass卡
	PT_GROWTH_FUND          = 8,      -- 成长基金
	PT_PAY_LOGIN_REWARD     = 9,      -- 付费签到
	PT_LUCK_NUMBER          = 10,     -- 幸运数字
	PT_NEW_LEVEL_REWARD     = 12,     -- 新等级礼包
	ASSEMBLY_ACTIVITY_GIFT  = 13,     -- 组合活动礼包
	NOVICE_WELFARE_GIFT     = 14,     -- 新手福利礼包
}

-- 外卖车的最大限制数量
DINING_CAR_LIMITE_NUM = 3
-- 是否可以复刷
QuestRechallenge = {
	QR_BASE 			= 0, -- 默认值
	QR_CAN 				= 1, -- 可以复刷 拥有三星
	QR_CANNOT 			= 2  -- 不能复刷 没有三星
}
-- 剩余复刷次数
QuestRechallengeTime = {
	QRT_INFINITE 		= -1, -- 剩余复刷次数无限
	QRT_NONE 			= 0, -- 剩余复刷次数0
	QRT_CAN 			= 1  -- 剩余复刷次数有效
}

InitalAvatarFrame = "500077"
-- 成就奖励获取type类型
CHANGE_TYPE = {
	CHANGE_THROPHY   = 1 ,  -- 更换奖杯
	CHANGE_HEAD = 2 ,  -- 更换头像
	CHANGE_HEAD_FRAME = 3  ,-- 更换外框
	CHANGE_UNION_HEAD = 4 , --更换工会头像
}

UNION_ROOM_MEMBERS = 10  -- 工会房间人数

-- 工会派对步骤
UNION_PARTY_STEPS = {
	UNOPEN          = 0,  -- 未开放
	FORESEE         = 1,  -- 预告阶段
	PREPARING       = 2,  -- 备菜阶段
	CLEARING        = 3,  -- 备菜结算
	OPENING         = 4,  -- 派对开场
	R1_DROP_FOOD_1  = 5,  -- 第1回合：首次掉菜
	R1_BOSS_QUEST   = 6,  -- 第1回合：堕神任务
	R1_BOSS_RESULT  = 7,  -- 第1回合：堕神结算
	R1_ROLL_REWARDS = 8,  -- 第1回合：抽取奖励
	R1_ROLL_RESULT  = 9,  -- 第1回合：抽奖结算
	R1_DROP_FOOD_2  = 10, -- 第1回合：最终掉菜
	R2_READY_START  = 11, -- 第2回合：准备开始
	R2_DROP_FOOD_1  = 12, -- 第2回合：首次掉菜
	R2_BOSS_QUEST   = 13, -- 第2回合：堕神任务
	R2_BOSS_RESULT  = 14, -- 第2回合：堕神结算
	R2_ROLL_REWARDS = 15, -- 第2回合：抽取奖励
	R2_ROLL_RESULT  = 16, -- 第2回合：抽奖结算
	R2_DROP_FOOD_2  = 17, -- 第2回合：最终掉菜
	R3_READY_START  = 18, -- 第3回合：准备开始
	R3_DROP_FOOD_1  = 19, -- 第3回合：首次掉菜
	R3_BOSS_QUEST   = 20, -- 第3回合：堕神任务
	R3_BOSS_RESULT  = 21, -- 第3回合：堕神结算
	R3_ROLL_REWARDS = 22, -- 第3回合：抽取奖励
	R3_ROLL_RESULT  = 23, -- 第3回合：抽奖结算
	R3_DROP_FOOD_2  = 24, -- 第3回合：最终掉菜
	ENDING          = 25, -- 派对结束
}

-- 工会战 步骤定义
---@see warsTime.json {"type"}
UNION_WARS_STEPS = {
	UNOPEN   = 0, -- 未开放
	READY    = 1, -- 准备阶段（成员编防）
	APPLY    = 2, -- 报名阶段（会长报名）
	MATCH    = 3, -- 匹配阶段（公会匹配）
	FIGHTING = 4, -- 战斗阶段（比赛时间）
	BREAK    = 5, -- 休赛阶段（等待下场）
}


-- 禁用editbox tag 值
DISABLE_EDITBOX_MEDIATOR ={
	PERSON_DETAIL_TAG = 11001 , -- 个人主页详情的tag  这样是为了明确的去判断禁用掉那个界面的tag值
	CHAT_INPUT_TAG    = 11002 , -- 聊天输入框tag

}
PLAY_VOICE_TYPE = {
	JAPANESE = 1 ,
	CHINESE  = 2 ,


}
-- 定点每天推送
PUSH_LOCAL_TIME_NOTICE  = {
	LOVE_FOOD_RECOVER_TYPE = {
		['1'] = {
			titleFunc   = function() return  __('爱心便当') end,
			name        = 110001,
			time        = 12,
			messageFunc = function() return __('热腾腾的爱心便当做好啦，不回来一起品尝嘛？') end,
			isRepeat    = true
		} ,
		['2'] = {
			titleFunc   = function() return __('爱心便当') end,
			name        = 110002,
			messageFunc = function() return __('热腾腾的爱心便当做好啦，不回来一起品尝嘛？') end,
			time        = 18,
			isRepeat    = true
		} ,
		['3'] = {
			titleFunc   = function() return __('爱心便当') end,
			name        = 110003,
			time        = 21,
			messageFunc = function() return __('热腾腾的爱心便当做好啦，不回来一起品尝嘛？') end,
			isRepeat    = true
		} ,
	},
	PUBLISH_ORDER_RECOVER_TYPE = {
		['1'] = {
			titleFunc   = function() return __('公有订单刷新') end,
			name        = 110004,
			time        = 11,
			messageFunc = function() return __('公有订单刷新了，御侍大人快来大赚一笔吧！') end,
			isRepeat    = true
		} ,
		['2'] = {
			titleFunc   = function() return __('公有订单刷新') end,
			name        = 110005,
			time        = 16,
			messageFunc = function() return __('公有订单刷新了，御侍大人快来大赚一笔吧！') end,
			isRepeat    = true
		} ,
		['3'] = {
			titleFunc   = function() return __('公有订单刷新') end,
			name        = 110006,
			time        = 20,
			messageFunc = function() return __('公有订单刷新了，御侍大人快来大赚一笔吧！') end,
			isRepeat    = true
		} ,
	} ,
	HP_RECOVER_TYPE = {
		['1'] = {
			titleFunc   = function() return __('体力回满') end,
			name        = 110007,
			isRepeat    = false,
			messageFunc = function() return __('御侍大人您的体力恢复满啦，一起继续冒险吧~') end,
		}
	},
	AIR_LIFT_RECOVER_TYPE = {
		['1'] = {
			titleFunc   = function() return __('空运恢复') end,
			name        = 110008,
			isRepeat    = false,
			messageFunc = function() return __('空运飞艇进港了，回来装载货物吧。') end,

		}
	},
	RESTAURANT_RECOVER_TYPE = {
		['1'] = {
			titleFunc   = function() return __('餐厅刷新') end,
			name        = 110009,
			isRepeat    = false,
			messageFunc = function() return __('哎呀餐厅停业啦，快回来看看情况吧！') end,
		}
	},
	WORLD_BOSS_PUSH_TYPE = {
		['1'] = {
			titleFunc   = function() return __('世界Boss') end,
			name        = 110010,
			isRepeat    = true,
			time        = 19,
			messageFunc = function() return __('集合了！灾祸正在入侵缇尔菈大陆，御侍大人们一起挑战！') end,
		}
	}
}
---- 由name   到 type
PUSH_LOCAL_NOTICE_NAME_TYPE   = {
	HP_RECOVER_TYPE            = 1,
	LOVE_FOOD_RECOVER_TYPE     = 2,
	RESTAURANT_RECOVER_TYPE    = 3,
	PUBLISH_ORDER_RECOVER_TYPE = 4,
	AIR_LIFT_RECOVER_TYPE      = 5,
	WORLD_BOSS_PUSH_TYPE       = 6,
}
---- 由type  有映射到推送设置的name
PUSH_LOCAL_NOTICE_TYPE_NAME = {
	["1"] = "HP_RECOVER_TYPE",
	['2'] = "LOVE_FOOD_RECOVER_TYPE",
	['3'] = "RESTAURANT_RECOVER_TYPE",
	['4'] = "PUBLISH_ORDER_RECOVER_TYPE",
	['5'] = "AIR_LIFT_RECOVER_TYPE",
	['6'] = "WORLD_BOSS_PUSH_TYPE",
}
IS_OPEN = {
	CLOSE = 0 ,
	OPEN =  1

}
-- 语言路劲
VOICE_DATA = {
	VOICE_PATH = string.format('%ssounds/%s/', RES_ABSOLUTE_PATH, i18n.getLang()) ,
	VOICE_RES_SUB_PATH = string.format('%ssounds/%s/', RES_SUB_ABSOLUTE_PATH, i18n.getLang()) ,
	VOICE_LACAL_FILE = 'soundsOne.txt' ,
	VOICE_ROMOTE_FILE = 'soundsTwo.txt',
}
if isElexSdk() then
	VOICE_DATA.VOICE_PATH = string.format('%ssounds/%s/', RES_ABSOLUTE_PATH, 'jp-jp')
	VOICE_DATA.VOICE_RES_SUB_PATH = string.format('%ssounds/%s/', RES_SUB_ABSOLUTE_PATH, 'jp-jp')
end
-- 排行榜类型
RankTypes = {
	RESTAURANT                      = 1, -- 餐厅知名度
	RESTAURANT_COMPREHENSIVENESS    = 2, -- 餐厅综合排名
	RESTAURANT_REVENUE              = 3, -- 餐厅营收榜
	TOWER                           = 4, -- 爬塔排行榜
	TOWER_WEEKLY                    = 5, -- 爬塔周榜
	TOWER_HISTORY                   = 6, -- 爬塔历史排行榜
	PVC_WEEKLY					    = 7, -- 竞技场周榜
	AIRSHIP                         = 8, -- 飞艇排行榜
	UNION   	 	 	 	 	    = 9, -- 工会排行榜
	UNION_CONTRIBUTIONPOINT         = 10, -- 工会捐献值排行榜
	UNION_CONTRIBUTIONPOINT_HISTORY = 11, -- 工会捐献值历史排行榜
	UNION_GODBEAST  	 	 	 	= 12, -- 工会神兽战力排行榜
	BOSS 							= 13, -- 世界BOSS
	BOSS_PERSON 					= 14, -- 世界BOSS个人榜
	BOSS_UNION						= 15, -- 世界BOSS工会榜
	SAIMOE							= 16, -- 燃战工会榜
	UNION_WARS                      = 17, -- 工会竞赛排行榜
}

-- 工会排行榜类型
UnionRankTypes = {
	CONTRIBUTION         = -1,   -- 贡献度
	CONTRIBUTION_DAILY   = -2,   -- 每日贡献度
	CONTRIBUTION_WEEKLY  = -3,   -- 每周贡献度
	BUILD_TIMES          = -10,  -- 建造
	BUILD_TIMES_DAILY    = -11,  -- 每日建造
	BUILD_TIMES_WEEKLY   = -12,  -- 每周建造
	FEED_TIMES           = -20,  -- 喂食
	FEED_TIMES_DAILY     = -21,  -- 每日喂食
	FEED_TIMES_WEEKLY    = -22,  -- 每周喂食
	GODBEAST_DAMAGE      = -30,  -- 伤害
	BOSS_DAMAGE	 		 = -40,  -- 灾祸
}
-- 头像弹窗类型
HeadPopupType = {
	FRIEND                    = '1',  -- 好友
	STRANGER                  = '2',  -- 陌生人
	RECENT_CONTACTS           = '3',  -- 最近联系人
	BLACKLIST                 = '4',  -- 黑名单
	RESTAURANT_FRIEND         = '5',  -- 餐厅好友
	STRANGER_WORLD            = '6',  -- 世界聊天陌生人
	UNION_PRESIDENT           = '7',  -- 会长进入
	UNION_VICE_PRESIDENT      = '9',  -- 副会长进入
	UNION_MEMBER              = '10', -- 成员进入
	CAT_HOUSE_MINE            = '11', -- 猫屋进入
	CAT_HOUSE_FRIEND_STRANGER = '12', -- 好友猫屋，陌生人
	CAT_HOUSE_FRIEND_FRIEND   = '13', -- 好友猫屋，好友
}
-- 好友页面页签类型
FriendTabType = {
	FRIENDLIST = 1001,
	DONATION   = 1002,
	FRIEND_BATTLE = 1003,
}
-- 获取玩家数据类型
PlayerInfoType = {
	CHAT_ALL = 1,
	CHAT_ONE = 2,
	HELP_ALL = 3,
	HELP_ONE = 4,
	HEADPOPUP = 5,

}
-- 通知页面页签类型
NoticeType = {
	MAIL         = 1,
	ANNOUNCEMENT = 2,
	COLLECTION   = 3
}
-- 召回页面页签类型
RecallType = {
	RECALL         	= 1,
	RECALLED 		= 2,
	INVITED_CODE	= 3,
}
-- 好友列表页面页签类型
FriendListViewType = {
	RECENT_CONTACTS = 1, -- 最近联系人
	MY_FRIENDS      = 2, -- 我的好友
	ADD_FRIENDS     = 3  -- 添加好友
}
-- 天赋类型
TalentType = {
	DAMAGE   = 1, -- 伤害系
	SUPPORT  = 2, -- 辅助系
	CONTROL  = 3, -- 控制系
	BUSINESS = 4  -- 经营系
}

--  工会的职位
UNION_JOB_TYPE = {
	PRESIDENT      = 1, -- 会长
	VICE_PRESIDENT = 2, -- 副会长
	COMMON         = 3, -- 成员
}
-- 组队本类型
RaidQuestType = {
	TWO_PLAYERS_THREE_CARDS 		= 1
}


-- 商城道具上架活动 子类型
ACTIVITY_MALL_TYPE = {
	CHEST      = 1,  -- 礼包商城
	GOODS      = 2,  -- 道具商城
	CARD_SKIN  = 3,  -- 皮肤商城
	RESTAURANT = 4,  -- 小费商城
	ARENA      = 5,  -- PVP商城
	AVATAR     = 6,  -- avatar商城
	KOF_ARENA  = 7,  -- kof竞技场商城
}




-- 游戏商店类型
GAME_STORE_TYPE = {
	DIAMOND       = 1,   -- 幻晶石 商店
	MONTH         = 2,   -- 月卡 商店
	GIFTS         = 3,   -- 礼包 商店
	PROPS         = 4,   -- 道具 商店
	CARD_SKIN     = 5,   -- 外观 商店
	GROCERY       = 6,   -- 杂货铺
	SEARCH_PROP   = 7,   -- 搜索 道具
	RESTAURANT    = 101, -- 小费商城
	PVP_ARENA     = 102, -- PVP商城
	KOF_ARENA     = 103, -- KOF商城
	UNION         = 104, -- 公会商城
	UNION_WARS    = 105, -- 工会战商城
	WATER_BAR     = 107, -- 水吧商城
	MEMORY        = 108, -- 记忆商城
	CHAMPIONSHIP  = 109, -- 勋章商城
	NEW_KOF_ARENA = 110, --新KOF商城
}

-- 游戏商店 商品图标名字 定义
GAME_STORE_GOODS_ICON_NAME_FUNC_MAP = {
	['shop_tag_iconid_1'] = function() return __('推荐') end,
	['shop_tag_iconid_2'] = function() return __('热卖') end,
	['shop_tag_iconid_3'] = function() return __('超值') end,
	['shop_tag_iconid_4'] = function() return __('特惠') end,
	['shop_tag_iconid_5'] = function() return __('限购一次') end,
	['shop_tag_iconid_6'] = function() return __('每日限购') end,
}

-- 游戏商店 购买弹窗 tag
GAME_STORE_PURCHASE_DIALOG_TAG = 5001

-- 3v3 匹配战 状态
MATCH_BATTLE_3V3_TYPE = {
	CLOSE  = -1, -- 关闭3v3
	UNOPEN = 0,  -- 未开始
	APPLY  = 1,  -- 报名中
	READY  = 2,  -- 备战中
	BATTLE = 3,  -- 进行中
}

--新 3v3 匹配战 状态
NEW_MATCH_BATTLE_3V3_TYPE = {
	OPEN = 1, --开启中
	UNOPEN = 2 --结算中
}
----------------------------------
-- user data
UnlockTypes = {
	PLAYER                         = 1,  --角色等级
	GOLD                           = 2,  --金币等级
	DIAMOND                        = 3,  --幻晶石等级
	GOODS                          = 4,  --道具等级
	AS_LEVEL                       = 5,  --餐厅等级等级
	TASK_QUEST                     = 6,  --主线完成
	TASK_BRANCH                    = 7,  --支线完成解锁
	FAVORABILITY_LEVEL             = 8,  --好感度等级
	AREA                           = 10, --区域解锁
	UNION_PLAYER_CONTRIBUTIONPOINT = 11, -- 工会贡献值
	UNION_LEVEL                    = 12, -- 工会等级
}

Types = {
    TYPE_TAKEAWAY_PRIVATE = 1, -- 外卖
    TYPE_TAKEAWAY_PUBLIC  = 2, -- 外卖公有
    TYPE_ARMY             = 3, -- 远征点
    TYPE_QUEST            = 4, -- 章节地图的点
    TYPE_STORY            = 5, -- 主线剧情点
    TYPE_BRANCH           = 6, -- 支线剧情点
    TYPE_QUEST_HARD       = 7, -- 困难本的点
    TYPE_ROBBERY          = 8, -- 打劫
}

CARDPLACE = {
    PLACE_ASSISTANT = 1, --大堂厨房 外卖助手
    PLACE_TEAM = 2,--编队
    PLACE_ICE_ROOM = 3, --冰场
    PLACE_FIGHT = 4, --战斗
    PLACE_TAKEAWAY = 5, --处卖中
    PLACE_EXPLORATION = 6, --探索中
    PLACE_EXPLORE_SYSTEM = 7, --新探索
	PLACE_FISH_PLACE = 8 , -- 玩家钓场内
}

-- key is area id, value is location id
HOME_MAP_LOCATION_MAP = {
	['0'] = {
		26,21,16,11,06,01,
		27,22,17,12,07,02,
		28,23,18,13,08,03,
		29,24,19,14,09,04,
		30,25,20,15,10,05,
	},
	['1'] = { -- 格瑞洛

		   22,17,12,
		28,      13,
		29,      14,
		30,
	},
	['2'] = { -- 耀之州

		27,22,
		28,23,18,13,08,
		29,      14,
		         15,
	},
	['3'] = { -- 奈芙拉斯特

		27,22,         02,
		28,            03,
		29,
		30,25,20,15,
	},
	['4'] = { -- 樱之岛

		27,22,17,      02,
		   23,   13,08,03,

		         15,
	},
	['5'] = { -- 帕拉塔

		27,
		28,      13,
		29,24,19,14,
		30,25,20,15,
	},
	['6'] = { -- 西帕拉塔

		27,
		28,
		29,24,19,14,
		30,25,20,15,
	},
	['7'] = { -- 索尔萨维斯
		
		      17,
		28,23,18,
		29,24,19,
		30,25,20,15,
	},
}


ASSISTANT_TYPES = {
    VIGOUR_TYPE = 6, --新鲜度的类型
}

CARDID_TANGHULU = 200013

--数字键盘输入和显示
NumboardModel = {
	keyModel = 1,
	freeModel = 2,
}

CHATCHANNEL = {
    WORLD = 1, 		--世界聊天频道
   	GUILD  = 2,		--公会聊天频道
   	PRIVATE  = 5, 	--私聊聊天频道
   	SYSTEM  = 3, 	--系统聊天频道
  	TEAM   = 4, 	--最对聊天频道
}

VoiceType = {
    RealTime    = 0,
    Messages    = 1,
}

StateType        = {
    State_JoinRoom     = 'joinRoom',
    State_RoomStatus   = 'roomStatus',
    State_MemberVoice  = 'memberVoice',
    State_Upload       = 'uploadFile',
    State_Download     = 'downloadFile',
    State_ApplyMessage = 'applyMessage',
    State_RecordFile   = 'recordedFile',
}

CodeType                        = {
    GV_ON_JOINROOM_SUCC               = 1,
    GV_ON_JOINROOM_TIMEOUT            = 2,
    GV_ON_JOINROOM_SVR_ERR            = 3,
    GV_ON_JOINROOM_UNKNOWN            = 4,
    GV_ON_NET_ERR                     = 5,
    GV_ON_QUITROOM_SUCC               = 6,
    GV_ON_MESSAGE_KEY_APPLIED_SUCC    = 7,
    GV_ON_MESSAGE_KEY_APPLIED_TIMEOUT = 8,
    GV_ON_MESSAGE_KEY_APPLIED_SVR_ERR = 9,
    GV_ON_MESSAGE_KEY_APPLIED_UNKNOWN = 10,
    GV_ON_UPLOAD_RECORD_DONE          = 11,
    GV_ON_UPLOAD_RECORD_ERROR         = 12,
    GV_ON_DOWNLOAD_RECORD_DONE        = 13,
    GV_ON_DOWNLOAD_RECORD_ERROR       = 14,
    GV_ON_PLAYFILE_DONE               = 18,
    GV_ON_ROOM_OFFLINE                = 19,
    GV_ON_UNKNOWN                     = 20,
}

RestaurantSkill = {
	SKILL_TYPE_RESTAURANT_CUSTOMER_COME = 1;--提高_target_id_顾客到店几率_target_num_%
	SKILL_TYPE_RESTAURANT_TARGET_GOLD_PERCENT = 2;--提高_target_id_顾客结账时额外获得_target_num_%金币
	SKILL_TYPE_RESTAURANT_TARGET_GOLD_CONSTANT = 3;--提高_target_id_顾客结账时额外获得_target_num_金币奖励
	SKILL_TYPE_RESTAURANT_TARGET_EVENT_DURATION_TIME_INCREASE = 4;--特殊事件_target_id_持续时间增加_target_num_秒
	SKILL_TYPE_RESTAURANT_EVERY_TIMES_VIGOUR_DECREASE = 5;--每次服务顾客消耗的新鲜度降低_target_num_点
	SKILL_TYPE_RESTAURANT_VIGOUR_MAX_INCREASE = 6;--在餐厅中工作的新鲜度提高_target_num_点

	SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_CONSTANT = 7;--减少送外卖往返时间_target_num_秒
	SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_PERCENT = 8;--减少送外卖往返时间_target_num_%秒
	SKILL_TYPE_TAKEAWAY_COOKING_POINT_PERCENT = 9;--每次送外卖成功后获得额外_target_num_%厨力
	SKILL_TYPE_TAKEAWAY_COOKING_POINT_CONSTANT = 10;--每次送外卖成功后获得额外_target_num_点厨力
	SKILL_TYPE_TAKEAWAY_ROBBERY_DECREASE = 11;--减少外卖车被抢劫的概率_target_num_%
	SKILL_TYPE_TAKEAWAY_PRIVATE_ORDER_CHEST_ADDITION = 12;--外送成功有_target_num_%额外获得一个宝箱

	SKILL_TYPE_RESTAURANT_TARGET_POPULARITY_CONSTANT = 13;--提高_target_id_顾客用餐后额外获得_target_num_点知名度奖励
	SKILL_TYPE_RESTAURANT_WAITER_SWITCH_CD = 14;--作为服务员的准备时间降低_target_num_秒
	SKILL_TYPE_RESTAURANT_WAITER_SERVE_CD = 15;--作为服务员时每次服务顾客的休息时间降低_target_num_秒
	SKILL_TYPE_RESTAURANT_SPECIAL_CUSTOMER_POPULARITY_PERCENT = 16;--招待特殊顾客时额外获得_target_num_%的知名度
	SKILL_TYPE_RESTAURANT_SPECIAL_CUSTOMER_GOLD_PERCENT = 17;--招待特殊顾客时额外获得_target_num_%的金币
	SKILL_TYPE_RESTAURANT_WAITER_NO_REST = 18;--_target_num_%概率不用休息即可再次服务一个顾客
	SKILL_TYPE_RESTAURANT_TARGET_EAT_EXTRA = 19;--_target_id_顾客有_target_num_%几率额外吃_target_num_份饭
	SKILL_TYPE_RESTAURANT_TARGET_GOLD_ADDITION_RATE = 20;--_target_id_顾客有_target_num_%几率结账时额外付_target_num_金币的小费
	SKILL_TYPE_RESTAURANT_COOKING_STYLE_POPULARITY = 21;--_target_id_菜系中的菜出售后可额外获得_target_num_知名度奖励
	SKILL_TYPE_RESTAURANT_COOKING_STYLE_GOLD = 22;--_target_id_菜系中的菜出售后可额外获得_target_num_金币奖励
	SKILL_TYPE_RESTAURANT_COOKING_STYLE_MAKING_LIMIT_INCREASE = 23;--飨灵在厨房使用_target_id_菜系中的食谱单次制作数量上限提高_target_num_个
	SKILL_TYPE_RESTAURANT_COOKING_STYLE_MAKING_TIME_DECREASE = 24;--飨灵在厨房使用_target_id_菜系中的食谱制作时间降低_target_num_%
	SKILL_TYPE_RESTAURANT_MAKING_LIMIT_INCREASE = 25;--飨灵在厨房中制作食物时,单次制作数量上限提高_target_num_个
	SKILL_TYPE_RESTAURANT_MAKING_TIME_DECREASE = 26;--飨灵在厨房中制作食物时,制作时间降低_target_num_%
	SKILL_TYPE_RESTAURANT_SHOP_WINDOW_MAX_INCREASE = 27;--餐厅的橱窗出售食物数量上限提高_target_num_个

	SKILL_TYPE_COOKING_ATTR_INCREASE_SEASONING = 34;--每次制作有_target_num_%几率使得佐料的效果属性增加_target_num_点。
	SKILL_TYPE_COOKING_ATTR_INCREASE_MUSE_FEEL = 35;--每次制作有_target_num_%几率额外获得_target_num_点口感属性。
	SKILL_TYPE_COOKING_ATTR_INCREASE_FRAGRANCE = 36;--每次制作有_target_num_%几率额外获得_target_num_点香味属性。
	SKILL_TYPE_COOKING_ATTR_INCREASE_EXTERIOR = 37;--每次制作有_target_num_%几率额外获得_target_num_点外观属性。
	SKILL_TYPE_COOKING_ATTR_INCREASE_TASTE = 38;--每次制作有_target_num_%几率额外获得_target_num_点味道属性。
	SKILL_TYPE_COOKING_DELICATE_FOOD_RATE = 39;--“精致的菜”的掉落率增加_target_num_%。
	SKILL_TYPE_COOKING_DELICATE_FOOD_EXTRA = 40;--掉落“精致的菜”时，有_target_num_%几率额外获得_target_num_个“精致的菜”。

	SKILL_TYPE_RESTAURANT_TRAFFIC = 41;--提高餐厅客流量_target_num_/小时
	SKILL_TYPE_RESTAURANT_ALL_GOLD_PERCENT = 42;--顾客结账时额外获得_target_num_%金币
	SKILL_TYPE_RESTAURANT_ALL_GOLD_CONSTANT = 43;--顾客结账时额外获得_target_num_金币奖励
	SKILL_TYPE_RESTAURANT_ALL_EVENT_DURATION_TIME_INCREASE = 44;--所有特殊事件持续时间增加_target_num_秒
	SKILL_TYPE_RESTAURANT_ALL_POPULARITY_CONSTANT = 45;--顾客用餐后额外获得_target_num_点知名度奖励
	SKILL_TYPE_RESTAURANT_ALL_EAT_EXTRA = 46;--顾客有_target_num_%几率额外吃_target_num_份饭
	SKILL_TYPE_RESTAURANT_ALL_GOLD_ADDITION_RATE = 47;--顾客有_target_num_%几率结账时额外付_target_num_金币的小费

	--SKILL_TYPE_TASTING_TOUR_ADD_ATTR_EFFECT    = 50;  --增加料理副本所有参与餐品_target_id_属性_target_num_点
	SKILL_TYPE_TASTING_TOUR_ADD_JUDGE_MOOD_EFFECT    = 54;  --增加料理副本评委初始心情_target_num_点

	--SKILL_TYPE_TASTING_TOUR_REDUCE_COOLING_TIME    =  54 ;  --减少料理副本再挑战时间_target_num_点



}

-- 模块开关（@see common/functionsCut.json）
MODULE_SWITCH = {
    ACHIEVEMENT 			= '1', 	-- 成就
	WORLD 					= '2', 	-- 世界地图
	NORMAL_MAP 				= '3',  -- 主线关卡(普通)
	DIFFICULTY_MAP 			= '4', 	-- 主线关卡(困难)
	TAKEWAY 				= '5', 	-- 外卖(私有订单)
	PUBLIC_ORDER			= '6', 	-- 公众订单
	CAPSULE     			= '7', 	-- 召唤
    CARDS             		= '8', 	-- 飨灵（飨灵升级、飨灵升星、契约、技能、外观）
	CARDSFRAGMENTCOMPOSE 	= '9',	-- 碎片合成
	MATERIALCOMPOSE 		= '10',	-- 材料合成
	TALENT_BUSSINSS 		= '11',	-- 料理天赋(伤害天赋、辅助天赋、控制天赋)
	SHOP 					= '12',	-- 商店（幻晶石商店、礼包商店、道具商店、外观商店）
	DAILYTASK 				= '13', -- 每日任务（成就）
	FRIEND               	= '14', -- 好友（好友求助）
	MAIL               		= '15', -- 邮箱
    ANNOUNCE          		= '16', -- 公告
	RESTAURANT 				= '17', -- 餐厅（餐厅升级、装修、小费商店）
	RESEARCH				= '18', -- 研究（制作、开发、专精、魔法料理）
	MARKET 					= '19',	-- 市场
	ICEROOM 				= '20',	-- 冰场（喂食）
	HANDBOOK				= '21',	-- 图鉴（大陆概述、堕神物语、冒险经历、角色介绍、飨灵百科）
	CHAT					= '22',	-- 聊天
	PERISH_BUG				= '23', -- 捉鬼
	PET 					= '24',	-- 堕神（堕神培养、孵化灵体）
	TEAMS 					= '25',	-- 编队（解锁第二编队、解锁第三编队）
	PAY 					= '26',	-- 充值
	MONEYTREE 				= '27',	-- 摇钱树
	ORDER 					= '28',	-- 订单
	MODELSELECT 			= '29',	-- 历练
	RANKING 				= '30',	-- 排行榜
	EXPLORATIN 				= '31', -- 探索
	AIR_TRANSPORTATION      = '32',	-- 空运
	GUILD					= '33',	-- 工会(工会商店、工会信息、工会派对)
    UNION_HUNT     			= '34', -- 工会狩猎
	WORLD_BOSS       		= '35',	-- 灾祸（灾祸手册）
	MATERIAL				= '36', -- 学院补给
	PVC_ROYAL_BATTLE        = '37',	-- 皇家对决（勋章商店）
	TOWER 					= '38',	-- 邪神遗迹
	MATERIAL_SCRIPT         = '39',	-- 协力作战
	CARD_GATHER             = '40',	-- 飨灵收集
	MANAGER					= '41',	-- 代理店长
	TASTING_TOUR            = '42', -- 品鉴
	PET_EVOL          		= '43',	-- 堕神异化（熔炼）
	TAG_MATCH               = '44',	-- 天城演武（通宝商店）
	--MAP_PARATA				= '45',	-- 主线地图（帕拉塔）
	ARTIFACT            	= '46',	-- 神器（宝石）
	MARRY 					= '47',	-- 结婚
	EXPLORE_SYSTEM          = '48', -- 新探索
	HOMELAND          		= '49', -- 家园
	UNION_TASK              = '50', -- 工会任务
	UNION_ACTIVITY          = '51', -- 工会活动
	CG_COLLECT              = '52', -- cg收集
	LEVEL_REWARD            = '53', -- 等级奖励
	ALL_ROUND               = '54', -- 全能王
	UNION_WARS              = '56', -- 工会竞赛
	CONTINUOUS_ACTIVE       = '57', -- 连续活跃活动
	BLACK_GOLD              = '58', -- 黑市商店
	LUNA_TOWER              = '59', -- luna塔
}

--模块ID（@see module.json）
JUMP_MODULE_DATA = {
	NORMAL_MAP           = '1',    -- 主线关卡(普通)
	DIFFICULTY_MAP       = '2',    -- 主线关卡(困难)
	TEAM_MAP             = '3',    -- 主线关卡(组队)
	RESEARCH             = '4',    -- 研究
	RESTAURANT           = '5',    -- 餐厅
	TAKEWAY              = '6',    -- 外卖
	EXPLORATIN           = '7',    -- 探索
	DAILYTASK            = '8',    -- 每日任务
	CAPSULE              = '9',    -- 召唤
	ACTIVITY             = '10',   -- 活动
	GUILD                = '11',   -- 公会
	SHOP                 = '12',   -- 商城
	ARENA                = '13',   -- 竞技场
	PAY                  = '14',   -- 充值
	MONEYTREE            = '15',   -- 摇钱树
	ICEROOM              = '16',   -- 冰场
	TALENT_BUSSINSS      = '17',   -- 料理天赋
	TALENT_DAMAGE        = '18',   -- 伤害天赋
	TALENT_ASSIT         = '19',   -- 辅助天赋
	TALENT_CONTROL       = '20',   -- 控制天赋
	HANDBOOK             = '21',   -- 图鉴
	CARDLEVELUP          = '22',   -- 飨灵升级
	CARDBREAKLVUP        = '23',   -- 飨灵升星
	MARKET               = '24',   -- 市场
	CARBARN              = '25',   -- 车库
	MATERIALCOMPOSE      = '26',   -- 材料合成
	CARDSFRAGMENTCOMPOSE = '27',   -- 碎片合成
	STORYMESSION         = '28',   -- 剧情任务
	UNLOCK_SEC_CAR       = '29',   -- 解锁第二编队
	UNLOCK_TRE_CAR       = '30',   -- 解锁第三编队
	TOWER                = '31',   -- 邪神遗迹
	PET                  = '32',   -- 堕神
	WORLD                = '33',   -- 世界地图
	AVATAR               = '34',   -- 餐厅装修
	AVATAR_UPGRADE       = '35',   -- 餐厅升级
	RECIPE_MAKE          = '36',   -- 研究制作
	RECIPE_STUDY         = '37',   -- 研究开发
	RECIPE_MASTER        = '38',   -- 研究专精
	MARRY                = '39',   -- 结婚
	SHOP_TIPS            = '40',   -- 小费商城
	AIR_TRANSPORTATION   = '41',   -- 空运
	PVC_ROYAL_BATTLE     = '42',   -- 皇家对决
	ACHIEVEMENT          = '43',   -- 成就的跳转
	PERISH_BUG           = '44',   -- 捉鬼
	PUBLIC_ORDER         = '45',   -- 公众订单
	TEAM_BATTLE_SCRIPT   = '46',   -- 协力作战
	MATERIAL_SCRIPT      = '47',   -- 学院补给
	PROMOTERS            = '48',   -- 推广员
	SKINSHOP             = '49',   -- 外观商城
	UNION_SHOP           = '50',   -- 工会商店
	GUILD_INFO           = '51',   -- 工会信息
	UNION_PARTY          = '52',   -- 工会派对
	UNION_HUNT           = '53',   -- 工会狩猎
	MANAGER              = '54',   -- 代理店长
	DIAMOND_SHOP         = '55',   -- 幻晶石商店
	GIFT_SHOP            = '56',   -- 礼包商店
	GOODS_SHOP           = '57',   -- 道具商店
	MEDAL_SHOP           = '58',   -- 勋章商店
	TASTING_TOUR         = '59',   -- 品鉴
	WORLD_BOSS           = '60',   -- 灾祸
	CARD_GATHER          = '61',   -- 飨灵收集
	SMELTING_PET         = '62',   -- 熔炼
	TAG_MATCH            = '63',   -- 天城演武
	ARTIFACT_TAG         = '64',   -- 神器
	TAG_JEWEL_EVOL       = '66',   -- 宝石
	WORLD_BOSS_MANUAL    = '67',   -- 灾祸手册
	MODELSELECT          = '68',   -- 历练
	TEAMS                = '69',   -- 编队
	CARDS                = '70',   -- 飨灵
	BOX                  = '71',   -- 包厢
	FISHING_GROUND		 = '72',   -- 钓场
	EXPLORE_SYSTEM       = '73',   -- 新探索
	HOME_LAND            = '75',   -- 家园
	FISHING_SHOP         = '76',   -- 钓场商店
	UNION_TASK           = '77',   -- 任务
	CG_COLLECT           = '78',   -- CG 收集
	SUMMER_ACTIVITY      = '79',   -- 夏活
	FISHING_SHOP_ONE     = '80',   -- 钓场商店
	FISHING_SHOP_TWO     = '81',   -- 钓场商店
	FISHING_SHOP_THREE   = '82',   -- 钓场商店
	ALL_ROUND            = '83',   -- 全能王
	RETURN_WELFARE		 = '86',   -- 回归福利
	UNION_WARS           = '87',   -- 工会竞赛
	UNION_IMPEACHMENT    = '88',   -- 工会弹劾
	PLOT_COLLECT         = '89',   -- 主线剧情收录
	MURDER 	 	 	     = '91',   -- 杀人案（19夏活）
	CONTINUOUS_ACTIVE    = '92',   -- 连续活跃活动
	ULTIMATE_BATTLE      = '94',   -- 巅峰对决
	ANNIVERSARY18        = '96',   -- 18年周年庆
	WATER_BAR	     	 = '98',   -- 水吧
	FRIEND               = '99',   -- 好友求助
	LUNA_TOWER 			 = '100',  -- luna塔
	WOODEN_DUMMY 		 = '104',  -- 木人桩
	PRESET_TEAM_WB       = '107',  -- 预设编队（普通）
	PRESET_TEAM_TOWER    = '108',  -- 预设编队（爬塔）
	PRESET_TEAM_TAGMATCH = '109',  -- 预设编队（3V3）
	WATER_BAR_MARKET     = '110',  -- 水吧杂货铺
	WATER_BAR_SHOP       = '111',  -- 水吧杂商店
	MEMORY_STORE         = '112',  -- 记忆商店
	CHAMPIONSHIP         = '113',  -- 武道会
	CAT_HOUSE	     	 = '114',  -- 猫屋
	NEW_TAG_MATCH        = '118',  -- 新天成演武
	CHAT                 = '991',  -- 聊天
	RECALL               = '1000', -- 老玩家召回
	RECALLH5             = '1001', -- 老玩家召回H5
	RECALLEDMASTER       = '1002', -- 老玩家召回回归
}

INTRODUCE_MODULE_ID = {
	SAIMOE_MAIN              = -7,  -- 燃战主规则
	SAIMOE_BOSS              = -8,  -- 燃战boss关规则
	DRAW_NEWBIE_INFO         = -18, -- 活动：新手抽卡规则
	JEWEL_EVOL               = -19, -- 宝石合成
	JEWEL_IMBED              = -20, -- 宝石镶嵌
	SKIN_CARNIVAL            = -45, -- 皮肤嘉年华
	SKIN_CARNIVAL_FLASH_SALE = -46, -- 皮肤嘉年华秒杀类型
	SKIN_CARNIVAL_TASK       = -47, -- 皮肤嘉年华任务类型
	SKIN_CARNIVAL_LOTTERY    = -48, -- 皮肤嘉年华抽奖类型
	SKIN_CARNIVAL_CHALLENGE  = -49, -- 皮肤嘉年华挑战类型
	NOVICE_WELFARE           = -73, -- 新手福利
	NOVICE_WELFARE_WAIT      = -74, -- 新手福利等待页面规则
	BASIC_SKIN_CAPSULE       = -79, -- 常驻皮肤卡池
	FREE_NEWBIE_CAPSULE      = -82, -- 免费新手卡池
	CARD_ALBUM               = 115, -- 飨灵收集册
}

-- key (@see RemindTag) = value (@see JUMP_MODULE_DATA)
MODULE_DATA = {
    SERVER_DECLARE                              = -1,                 -- 服务器运营申明
    [tostring(RemindTag.CARDS)]                 = 70,                 -- 卡牌
    [tostring(RemindTag.CAPSULE)]               = 9,                  -- 抽卡
    [tostring(RemindTag.PET)]                   = RemindTag.PET,      -- 堕神
    [tostring(RemindTag.SHOP)]                  = 12,                 -- 商城
    [tostring(RemindTag.MAIL)]                  = RemindTag.MAIL,     -- 邮件
    [tostring(RemindTag.ACTIVITY)]              = 10,                 -- 活动
    [tostring(RemindTag.TASK)]                  = 8,                  -- 日常
    [tostring(RemindTag.HANDBOOK)]              = 21,                 -- 图鉴
    [tostring(RemindTag.CARDLEVELUP)]           = 22,                 -- 卡牌升级按钮
    [tostring(RemindTag.CARDBREAKLVUP)]         = 23,                 -- 卡牌升星按钮
    [tostring(RemindTag.SET)]                   = RemindTag.SET,      -- 设置
    [tostring(RemindTag.MAP)]                   = 1,                  -- 地图
    [tostring(RemindTag.MANAGER)]               = 5,                  -- 经营
    [tostring(RemindTag.TEAMS)]                 = 69,                 -- 编队
    [tostring(RemindTag.BACKPACK)]              = RemindTag.BACKPACK, -- 背包
    [tostring(RemindTag.ICEROOM)]               = 16,                 -- 冰场
    [tostring(RemindTag.TALENT)]                = 17,                 -- 天赋
    [tostring(RemindTag.ORDER)]                 = 6,                  -- 外卖定单
    [tostring(RemindTag.ROBBERY)]               = 6,                  -- 打劫
    [tostring(RemindTag.STORY)]                 = RemindTag.STORY,    -- 剧情
    [tostring(RemindTag.WORLDMAP)]              = 33,                 -- 世界地图
    [tostring(RemindTag.QUEST_ARMY)]            = 7,                  -- 探索
    [tostring(RemindTag.DIFFICULT_MAP)]         = 2,                  -- 困难本
    [tostring(RemindTag.MARKET)]                = 24,                 -- 市场
    [tostring(RemindTag.DISCOVER)]              = 4,                  -- 研究
    [tostring(RemindTag.CARVIEW)]               = 25,                 -- 车库
    [tostring(RemindTag.LOBBY_TASK)]            = 5,                  -- 餐厅任务
    [tostring(RemindTag.BTN_AVATAR_DECORATE)]   = 34,                 -- 餐厅装修
    [tostring(RemindTag.BTN_AVATAR_UPGRADE)]    = 35,                 -- 餐厅升级
    [tostring(RemindTag.TOWER)]                 = 31,                 -- 爬塔
    [tostring(RemindTag.PET)]                   = 32,                 -- 堕神
    [tostring(RemindTag.UNION)]                 = 11,                 -- 工会
    [tostring(RemindTag.LEVEL)]                 = -2,                 -- 等级礼包
    [tostring(RemindTag.RESEARCH)]              = 37,                 -- 菜谱研发
    [tostring(RemindTag.AIRSHIP)]               = 41,                 -- 空艇
    [tostring(RemindTag.PUBLIC_ORDER)]          = 45,                 -- 公有订单
    [tostring(RemindTag.PVC)]                   = 42,                 -- PVP
    [JUMP_MODULE_DATA.MATERIALCOMPOSE]          = 26,                 -- 材料合成
    [JUMP_MODULE_DATA.CARDSFRAGMENTCOMPOSE]     = 27,                 -- 碎片合成
    [tostring(RemindTag.STORY_TASK)]            = 28,                 -- 主线任务
    [tostring(RemindTag.THREETWORAID)]          = 46,                 -- 组队
    [tostring(RemindTag.UNION_HUNT)]            = 53,                 -- 工会狩猎
    [tostring(RemindTag.LOBBY_AGENT_SHOPOWNER)] = 54,                 -- 代理店长
    [tostring(RemindTag.TASTINGTOUR)]           = 59,                 -- 料理副本
    [tostring(RemindTag.WORLD_BOSS)]            = 60,                 -- 世界BOSS
    [tostring(RemindTag.TAG_MATCH)]             = 63,                 -- 3v3 pvp
    [tostring(RemindTag.TAG_JEWEL_EVOL)]        = 66,                 -- 宝石合成
    [tostring(RemindTag.ARTIFACT_TAG)]          = 64,                 -- 神器
    [tostring(RemindTag.WORLD_BOSS_MANUAL)]     = 67,                 -- 世界BOSS手册
    [tostring(RemindTag.MODELSELECT)]           = 68,                 -- 历练
    [tostring(RemindTag.MATERIAL)]              = 47,                 -- 学园补给
    [tostring(RemindTag.TAKE_HOUSE)]            = 66,                 -- 塔可屋
    [tostring(RemindTag.UNION_PARTY)]           = 52,                 -- 工会派对
    [tostring(RemindTag.BOX_MODULE)]            = 71,                 -- 包厢功能
    [tostring(RemindTag.FISH_GROUP)]            = 72,                 -- 钓场功能
    [tostring(RemindTag.EXPLORE_SYSTEM)]        = 73,                 -- 新探索
    [tostring(RemindTag.RECALL)]                = 74,                 -- 老玩家召回
    [tostring(RemindTag.UNION_TASK)]            = 77,                 -- 工会任务
    [tostring(RemindTag.ALL_ROUND)]             = 83,                 -- 全能王
    [tostring(RemindTag.ALL_ROUND)]             = 83,                 -- 全能王
    [JUMP_MODULE_DATA.RETURN_WELFARE]           = 86,                 -- 回归福利
    [tostring(RemindTag.UNION_WARS)]            = 87,                 -- 工会竞赛
    [tostring(RemindTag.UNION_IMPEACHMENT)]     = 88,                 -- 工会弹劾
    [JUMP_MODULE_DATA.PLOT_COLLECT]             = 89,                 -- 主线剧情收录
    [tostring(RemindTag.BLACK_GOLD)]            = 90,                 -- 黑市商店
    [JUMP_MODULE_DATA.CONTINUOUS_ACTIVE]        = 92,                 -- 连续活跃活动
    [tostring(RemindTag.TTGAME)]                = 93,                 -- 3x3打牌
    [tostring(RemindTag.WATER_BAR)]             = 98,                 -- 水吧功能
    TTGAME_SHOP                                 = -53,                -- 3x3打牌 牌店
    TTGAME_ALBUM                                = -54,                -- 3x3打牌 牌册
    TTGAME_PVE                                  = -55,                -- 3x3打牌 pve
    [JUMP_MODULE_DATA.LUNA_TOWER]               = 100,                -- luna塔
    [tostring(RemindTag.PLOT_COLLECT)]          = 105,                -- 剧情收录
    [JUMP_MODULE_DATA.PRESET_TEAM_WB]           = 107,                -- 预设编队（普通）
    [JUMP_MODULE_DATA.PRESET_TEAM_TOWER]        = 108,                -- 预设编队（爬塔）
    [JUMP_MODULE_DATA.PRESET_TEAM_TAGMATCH]     = 109,                -- 预设编队（3V3）
	[tostring(RemindTag.CHAMPIONSHIP)]          = 113,                -- 武道会
    [tostring(RemindTag.CAT_HOUSE)]             = 114,                -- 猫屋功能
    [tostring(RemindTag.NEW_TAG_MATCH)]         = 118,                -- 新天城演武（3v3 pvp）
	ANNIVERSARY                                 = -9,                 -- 周年庆2018
	ANNIVERSARY19                               = -44,                -- 周年庆2019
	ANNIVERSARY20                               = -68,                -- 周年庆2020
    ANNIV20_HANG                                = -75,                -- 周年庆2020挂机
    ANNIV20_PUZZLE                              = -76,                -- 周年庆2020拼图
    ANNIV20_EXPLORE                             = -77,                -- 周年庆2020爬塔
}


-- 模块映射
MODULE_REFLECT = {
	[JUMP_MODULE_DATA.NORMAL_MAP] 						= MODULE_SWITCH.NORMAL_MAP, 			-- 主线关卡(普通)
	[JUMP_MODULE_DATA.DIFFICULTY_MAP] 					= MODULE_SWITCH.DIFFICULTY_MAP, 		-- 主线关卡(困难)
	[JUMP_MODULE_DATA.TEAM_MAP] 						= MODULE_SWITCH.MATERIAL_SCRIPT, 		-- 主线关卡(组队)
	[JUMP_MODULE_DATA.RESEARCH]							= MODULE_SWITCH.RESEARCH, 				-- 研究
	[JUMP_MODULE_DATA.RESTAURANT] 						= MODULE_SWITCH.RESTAURANT, 			-- 餐厅
	[JUMP_MODULE_DATA.TAKEWAY] 							= MODULE_SWITCH.ORDER, 					-- 外卖
	[JUMP_MODULE_DATA.EXPLORATIN] 						= MODULE_SWITCH.EXPLORATIN, 			-- 探索
	[JUMP_MODULE_DATA.DAILYTASK]						= MODULE_SWITCH.DAILYTASK, 				-- 每日任务
	[JUMP_MODULE_DATA.CAPSULE]     						= MODULE_SWITCH.CAPSULE, 				-- 召唤
	-- [JUMP_MODULE_DATA.ACTIVITY] 							= MODULE_SWITCH., -- 活动
	[JUMP_MODULE_DATA.GUILD]							= MODULE_SWITCH.GUILD, 					-- 公会
	[JUMP_MODULE_DATA.SHOP]								= MODULE_SWITCH.SHOP, 					-- 商城
	[JUMP_MODULE_DATA.ARENA]   							= MODULE_SWITCH.PVC_ROYAL_BATTLE, 		-- 竞技场
	[JUMP_MODULE_DATA.PAY] 								= MODULE_SWITCH.PAY, 					-- 充值
	[JUMP_MODULE_DATA.MONEYTREE]						= MODULE_SWITCH.MONEYTREE, 				-- 摇钱树
	[JUMP_MODULE_DATA.ICEROOM] 							= MODULE_SWITCH.ICEROOM, 				-- 冰场
	[JUMP_MODULE_DATA.TALENT_BUSSINSS] 					= MODULE_SWITCH.TALENT_BUSSINSS, 		-- 料理天赋
	[JUMP_MODULE_DATA.TALENT_DAMAGE]					= MODULE_SWITCH.TALENT_BUSSINSS, 		-- 伤害天赋
	[JUMP_MODULE_DATA.TALENT_ASSIT]						= MODULE_SWITCH.TALENT_BUSSINSS, 		-- 辅助天赋
	[JUMP_MODULE_DATA.TALENT_CONTROL] 					= MODULE_SWITCH.TALENT_BUSSINSS, 		-- 控制天赋
	[JUMP_MODULE_DATA.HANDBOOK]							= MODULE_SWITCH.HANDBOOK, 				-- 图鉴
	[JUMP_MODULE_DATA.MARKET] 							= MODULE_SWITCH.MARKET, 				-- 市场
	[JUMP_MODULE_DATA.CARBARN] 							= MODULE_SWITCH.ORDER, 					-- 车库
	[JUMP_MODULE_DATA.MATERIALCOMPOSE] 					= MODULE_SWITCH.MATERIALCOMPOSE, 		-- 材料合成
	[JUMP_MODULE_DATA.CARDSFRAGMENTCOMPOSE]				= MODULE_SWITCH.CARDSFRAGMENTCOMPOSE, 	-- 碎片合成
	-- [JUMP_MODULE_DATA.STORYMESSION] 						= MODULE_SWITCH., -- 剧情任务
	[JUMP_MODULE_DATA.TOWER]							= MODULE_SWITCH.TOWER, 					-- 邪神遗迹
	[JUMP_MODULE_DATA.PET] 								= MODULE_SWITCH.PET, 					-- 堕神
	[JUMP_MODULE_DATA.WORLD]							= MODULE_SWITCH.WORLD, 					-- 世界地图
	[JUMP_MODULE_DATA.AVATAR] 							= MODULE_SWITCH.RESTAURANT, 			-- 餐厅装修
	[JUMP_MODULE_DATA.RECIPE_MAKE] 						= MODULE_SWITCH.RESEARCH, 				-- 研究制作
	[JUMP_MODULE_DATA.RECIPE_STUDY]						= MODULE_SWITCH.RESEARCH, 				-- 研究开发
	[JUMP_MODULE_DATA.RECIPE_MASTER]					= MODULE_SWITCH.RESEARCH, 				-- 研究专精
	[JUMP_MODULE_DATA.SHOP_TIPS]						= MODULE_SWITCH.RESTAURANT, 			-- 小费商城
	[JUMP_MODULE_DATA.AIR_TRANSPORTATION]      			= MODULE_SWITCH.AIR_TRANSPORTATION, 	-- 空运
	[JUMP_MODULE_DATA.PVC_ROYAL_BATTLE]        			= MODULE_SWITCH.PVC_ROYAL_BATTLE, 		-- 皇家对决
	[JUMP_MODULE_DATA.ACHIEVEMENT]             			= MODULE_SWITCH.ACHIEVEMENT, 			-- 成就
	[JUMP_MODULE_DATA.TEAM_BATTLE_SCRIPT]      			= MODULE_SWITCH.MATERIAL_SCRIPT, 		-- 协力作战
	[JUMP_MODULE_DATA.MATERIAL_SCRIPT]         			= MODULE_SWITCH.MATERIAL, 				-- 学院补给
	-- [JUMP_MODULE_DATA.PROMOTERS]							= MODULE_SWITCH., -- 推广员
	[JUMP_MODULE_DATA.SKINSHOP]                			= MODULE_SWITCH.SHOP, 					-- 外观商城
	[JUMP_MODULE_DATA.UNION_SHOP]              			= MODULE_SWITCH.GUILD, 					-- 工会商店
	[JUMP_MODULE_DATA.UNION_PARTY]             			= MODULE_SWITCH.GUILD, 					-- 工会派对
	[JUMP_MODULE_DATA.DIAMOND_SHOP]            			= MODULE_SWITCH.SHOP, 					-- 幻晶石商店
	[JUMP_MODULE_DATA.GIFT_SHOP]               			= MODULE_SWITCH.SHOP, 					-- 礼包商店
	[JUMP_MODULE_DATA.GOODS_SHOP]              			= MODULE_SWITCH.SHOP, 					-- 道具商店
	[JUMP_MODULE_DATA.MEDAL_SHOP]             			= MODULE_SWITCH.PVC_ROYAL_BATTLE, 		-- 勋章商店
	[JUMP_MODULE_DATA.TASTING_TOUR]            			= MODULE_SWITCH.TASTING_TOUR, 			-- 品鉴
	[JUMP_MODULE_DATA.CARD_GATHER]             			= MODULE_SWITCH.CARD_GATHER, 			-- 飨灵收集
	[JUMP_MODULE_DATA.SMELTING_PET]            			= MODULE_SWITCH.PET_EVOL, 				-- 熔炼
	[JUMP_MODULE_DATA.TAG_MATCH]               			= MODULE_SWITCH.TAG_MATCH, 				-- 天城演武
	[JUMP_MODULE_DATA.ARTIFACT_TAG]            			= MODULE_SWITCH.ARTIFACT, 				-- 神器
	[JUMP_MODULE_DATA.TAG_JEWEL_EVOL]          			= MODULE_SWITCH.ARTIFACT, 				-- 宝石
	[JUMP_MODULE_DATA.WORLD_BOSS_MANUAL]       			= MODULE_SWITCH.WORLD_BOSS, 			-- 灾祸手册
	[JUMP_MODULE_DATA.MODELSELECT]             			= MODULE_SWITCH.MODELSELECT, 			-- 历练
	[JUMP_MODULE_DATA.EXPLORE_SYSTEM]             		= MODULE_SWITCH.EXPLORE_SYSTEM, 		-- 新探索
	[JUMP_MODULE_DATA.FISHING_GROUND]             		= MODULE_SWITCH.HOMELAND, 				-- 家园
	[JUMP_MODULE_DATA.FISHING_SHOP]             		= MODULE_SWITCH.HOMELAND, 				-- 钓场商店
	[JUMP_MODULE_DATA.FISHING_SHOP_ONE]             	= MODULE_SWITCH.HOMELAND, 				-- 钓场商店
	[JUMP_MODULE_DATA.FISHING_SHOP_TWO]             	= MODULE_SWITCH.HOMELAND, 				-- 钓场商店
	[JUMP_MODULE_DATA.FISHING_SHOP_THREE]             	= MODULE_SWITCH.HOMELAND, 				-- 钓场商店

	[JUMP_MODULE_DATA.CARDLEVELUP]				    	= MODULE_SWITCH.CARDS,					-- 飨灵升级
	[JUMP_MODULE_DATA.CARDBREAKLVUP]					= MODULE_SWITCH.CARDS, 					-- 飨灵升星
	[JUMP_MODULE_DATA.UNLOCK_SEC_CAR]					= MODULE_SWITCH.ORDER, 					-- 解锁第二编队
	[JUMP_MODULE_DATA.UNLOCK_TRE_CAR]					= MODULE_SWITCH.ORDER,					-- 解锁第三编队
	[JUMP_MODULE_DATA.AVATAR_UPGRADE]					= MODULE_SWITCH.RESTAURANT, 			-- 餐厅升级
	[JUMP_MODULE_DATA.MARRY] 							= MODULE_SWITCH.MARRY,					-- 结婚
	[JUMP_MODULE_DATA.PERISH_BUG]						= MODULE_SWITCH.PERISH_BUG,				-- 捉鬼
	[JUMP_MODULE_DATA.PUBLIC_ORDER]						= MODULE_SWITCH.PUBLIC_ORDER,			-- 公众订单
	[JUMP_MODULE_DATA.GUILD_INFO]						= MODULE_SWITCH.GUILD,					-- 工会信息
	[JUMP_MODULE_DATA.UNION_HUNT]						= MODULE_SWITCH.UNION_HUNT,				-- 工会狩猎
	[JUMP_MODULE_DATA.MANAGER]							= MODULE_SWITCH.MANAGER,				-- 代理店长
	[JUMP_MODULE_DATA.WORLD_BOSS]						= MODULE_SWITCH.WORLD_BOSS,				-- 灾祸
	[JUMP_MODULE_DATA.TEAMS]							= MODULE_SWITCH.TEAMS,					-- 编队
	[JUMP_MODULE_DATA.CARDS]							= MODULE_SWITCH.CARDS,					-- 飨灵
	[JUMP_MODULE_DATA.FRIEND]							= MODULE_SWITCH.FRIEND,					-- 好友求助
	[JUMP_MODULE_DATA.CHAT]								= MODULE_SWITCH.CHAT,					-- 聊天
}

--- 预设编队类型
---@class PRESET_TEAM_TYPE
PRESET_TEAM_TYPE = {
	FIVE_DEFAULT = MODULE_DATA[JUMP_MODULE_DATA.PRESET_TEAM_WB],       ---  5人默认编队
	TEN_DEFAULT  = MODULE_DATA[JUMP_MODULE_DATA.PRESET_TEAM_TOWER],    ---  10人默认编队
	TAG_MATCH    = MODULE_DATA[JUMP_MODULE_DATA.PRESET_TEAM_TAGMATCH], ---  天城演武编队
}

PRESET_TEAM_DEFINES = {
    [PRESET_TEAM_TYPE.FIVE_DEFAULT] = {
        ---@field type PRESET_TEAM_TYPE
        type         = PRESET_TEAM_TYPE.FIVE_DEFAULT,   --- 预设编队类型
		saveCount    = 10,                              --- 保存数量
		cardCount    = 5,                               --- 卡牌个数
        minCardCount = 1,                               --- 最小卡牌个数
        maxTeamCount = 1,                               --- 最大团队个数
        serverType   = 1,                               --- 对应服务端队伍类型 1：世界boss 2：爬塔
		moduleType   = JUMP_MODULE_DATA.PRESET_TEAM_WB, --- 模块类型
    },
    [PRESET_TEAM_TYPE.TEN_DEFAULT] = {
		type         = PRESET_TEAM_TYPE.TEN_DEFAULT,
		saveCount    = 10,
        cardCount    = 10,
        minCardCount = 5,
        maxTeamCount = 1,
        serverType   = 2,
		moduleType   = JUMP_MODULE_DATA.PRESET_TEAM_TOWER,
    },
    [PRESET_TEAM_TYPE.TAG_MATCH] = {
		type         = PRESET_TEAM_TYPE.TAG_MATCH,
		saveCount    = 10,
        cardCount    = 5,
        minCardCount = 15,
		maxTeamCount = 3,
        serverType   = 3,
		moduleType   = JUMP_MODULE_DATA.PRESET_TEAM_TAGMATCH,
    },
}

REMIND_TAG_MAP = {}
for k, v in pairs(MODULE_DATA) do
	REMIND_TAG_MAP[tostring(v)] = checkint(k)
end


-- 主界面功能解锁定义
HOME_FUNC_FROM_MAP = {
	[MODULE_DATA[tostring(RemindTag.STORY_TASK)]]    = 'HOME_SCENE',  -- 主线任务
	[MODULE_DATA[tostring(RemindTag.MAP)]]           = 'HOME_MAP',    -- 主线关卡（普通）
	[MODULE_DATA[tostring(RemindTag.DIFFICULT_MAP)]] = 'HOME_MAP',    -- 主线关卡（困难）
	[MODULE_DATA[tostring(RemindTag.QUEST_ARMY)]]    = 'HOME_MAP',    -- 探索
	[MODULE_DATA[tostring(RemindTag.AIRSHIP)]]       = 'HOME_MAP',    -- 空运
	[MODULE_DATA[tostring(RemindTag.ACTIVITY)]]      = 'FUNC_BAR',    -- 活动
	[MODULE_DATA[tostring(RemindTag.SHOP)]]          = 'FUNC_BAR',    -- 商店
	[MODULE_DATA[tostring(RemindTag.TASK)]]          = 'HOME_SCENE',  -- 日常
	[MODULE_DATA[tostring(RemindTag.CAPSULE)]]       = 'FUNC_SLIDER', -- 召唤
	[MODULE_DATA[tostring(RemindTag.CARDS)]]         = 'FUNC_SLIDER', -- 飨灵
	[MODULE_DATA[tostring(RemindTag.TEAMS)]]         = 'FUNC_SLIDER', -- 编队
	[MODULE_DATA[tostring(RemindTag.TALENT)]]        = 'FUNC_SLIDER', -- 天赋
	[MODULE_DATA[tostring(RemindTag.PET)]]           = 'FUNC_SLIDER', -- 堕神
	[MODULE_DATA[tostring(RemindTag.UNION)]]         = 'FUNC_SLIDER', -- 工会
	[MODULE_DATA[tostring(RemindTag.TAKE_HOUSE)]]    = 'FUNC_SLIDER', -- 塔可屋
	[MODULE_DATA[tostring(RemindTag.WORLDMAP)]]      = 'FUNC_SLIDER', -- 地图
	[MODULE_DATA[tostring(RemindTag.ORDER)]]         = 'FUNC_SLIDER', -- 外卖订单 TODO
	[MODULE_DATA[tostring(RemindTag.MODELSELECT)]]   = 'FUNC_SLIDER', -- 历练
	[MODULE_DATA[tostring(RemindTag.HANDBOOK)]]      = 'EXTRA_PANEL', -- 图鉴
	[MODULE_DATA[tostring(RemindTag.MANAGER)]]       = 'EXTRA_PANEL', -- 餐厅
	[MODULE_DATA[tostring(RemindTag.DISCOVER)]]      = 'EXTRA_PANEL', -- 研究
	[MODULE_DATA[tostring(RemindTag.ICEROOM)]]       = 'EXTRA_PANEL', -- 冰场
	[MODULE_DATA[tostring(RemindTag.MARKET)]]        = 'EXTRA_PANEL', -- 市场
	[MODULE_DATA[tostring(RemindTag.TASTINGTOUR)]]   = 'EXTRA_PANEL', -- 品鉴
	[MODULE_DATA[tostring(RemindTag.TOWER)]]         = 'FUNC_SLIDER', -- 历练:邪神遗迹
	[MODULE_DATA[tostring(RemindTag.PVC)]]           = 'FUNC_SLIDER', -- 历练:皇家对决
	[MODULE_DATA[tostring(RemindTag.THREETWORAID)]]  = 'FUNC_SLIDER', -- 历练:协力作战
	[MODULE_DATA[tostring(RemindTag.MATERIAL)]]      = 'FUNC_SLIDER', -- 历练:学院补给
	[MODULE_DATA[tostring(RemindTag.ALL_ROUND)]]     = 'FUNC_SLIDER', -- 全能王
}

-- 任务类型定义
COMMON_TASK_TYPE = {
	USE_TARGET_NUM_CASH_COW_TASKS                = 1, -- 使用_target_num_次摇钱树
	SUMMON_TARGET_NUM_TIME_CARD_TASKS            = 2, -- 召唤_target_num_次卡牌
	UPGRADE_PET_NUM_TASKS                        = 6, -- 升级任意堕神_target_num_次
	RESTAURANTS_GUSET_NUM_TASKS                  = 7, -- 餐厅招待_target_num_个客人
	COMPLETE_TAKEAWAY_ORDER_TASKS                = 8, -- 完成外卖订单_target_num_次
	COMPLETE_EXPLORE_TASKS                       = 9, -- 完成_target_num_次探索
	PLAYER_LEVEL_TASKS                           = 12, -- 主角等级达到_target_num_
	COLLOECT_PET_NUM_TASKS                       = 13, -- 收集_target_num_个堕灵
	COMPLETE_NORMAL_QUEST_TASKS                  = 14, -- 通关普通关卡_target_num_（关卡ID）
	USE_ANY_EXP_WATER_TASKS                      = 16, -- 使用任意经验药水_target_num_次
	COMPLETE_HARD_QUEST_TASKS                    = 20, -- 通关困难关卡_target_num_（关卡ID）
	IMPROVE_RESTAURANTS_LEVEL_TASKS              = 25, -- 提升餐厅规模至_target_num_
	IMPROVE_RECIPE_NUM_TASKS                     = 26, -- 改良任意菜品_target_num_道
	COLLECT_PET_EGGS_NUM_TASKS                   = 28, -- 收集_target_num_个灵体
	PURIFICATION_PET_EGG_NUM_TASKS               = 29, -- 净化_target_num_个灵体
	COMPLETE_TOWER_NUM_TASKS                     = 31, -- 通关第_target_num_层邪神遗迹
	TO_OVERCOME_OVERLORD_MEAL_NUM_TASKS          = 34, -- 餐厅中战胜_target_num_个吃霸王餐的顾客
	RESTAURANTS_COMPLETE_NUM_TASKS               = 35, -- 餐厅中完成_target_num_个任务
	CUMULATIVE_CUSTOMS_CLEARANCE_TOWER_NUM_TASKS = 41, -- 累计通关邪神遗迹_target_num_层
	COMPLETE_AIRS_NUM_TASKS                      = 47, -- 完成空运_target_num_次
	GOD_TARGET_ID_PET_IMPROVED_LEVEL_TASKS       = 48, -- 将_target_id_个堕神升至_target_num_级
	AREANA_BATTLE_NUMS_TASKS                     = 50, -- 竞技场战斗_target_num_次
	AREANA_BATTLE_WIN_NUMS_TASKS                 = 51, -- 竞技场获胜_target_num_次
	UPGRADE_CARD_STAR							 = 64, -- 将_target_id_（飨灵id）的卡牌星级提升到_target_num_
	COMPLETE_MATERIAL_COPY_NUM_TASKS             = 87, -- 完成_target_num_次学院补给
	LOGIN_NUM_TASKS                              = 114, -- 累计登陆_target_num_次
	USE_DIAMOND_TASKS                            = 115, -- 累计使用_target_num_个钻石
	COMPLETE_DAILY_TASKS                         = 116, -- 累计完成_target_num_次日常任务
	SWEEP_TOWER_TASKS                            = 117, -- 累计扫荡_target_num_层邪神遗迹
	SERVE_PRIVATE_ROOM_GUEST_TASKS               = 118, -- 包厢招待_target_num_名客人
	FISH_REWARDS_NUM_TASKS                       = 119, -- 钓鱼场收货_target_num_次
	RESTAURANTS_SELL_RECIPE_NUM_TASKS            = 120, -- 餐厅出售_target_num_份食物
	WATERING_PET_EGGS_NUM_TASKS                  = 121, -- 浇灌_target_num_次灵体
	STRENGTHENING_PET_NUM_TASKS                  = 122, -- 累计强化堕神_target_num_次
	EVOLUTION_PET_NUM_TASKS                      = 123, -- 异化堕神_target_num_次
	ADD_UP_BIRTH_PET_NUM_TASKS                   = 124, -- 累计再生堕神_target_num_次
	ACTIVATE_ARTIFACT                            = 129, -- 激活_target_id_的神器
	UPGRADE_RECIPE_TO_S                          = 136, -- 将菜品_target_id_的评价升级为S
	UPGRADE_RECIPE_TO_A                          = 137, -- 将菜品_target_id_的评价升级为A
	UPGRADE_RECIPE_TO_B                          = 138, -- 将菜品_target_id_的评价升级为B
	UPGRADE_RECIPE_TO_C                          = 139, -- 将菜品_target_id_的评价升级为C
	ACQUIRE_CARD								 = 140, -- 获得飨灵：_target_id_
	UPGRADE_CARD_SKILL_LEVEL                     = 141, -- 升级飨灵_target_id_的技能_target_num_次
	UPGRADE_CARD_LEVEL                           = 142, -- 将_target_id_（飨灵id）的卡牌等级提升到_target_num_
}

local GLOBALPARSER = 'GLOBALPARSER' --用于存储没有parser的数据存储

function DataManager:ctor( key )
	self.super.ctor(self)
	if DataManager.instances[key] ~= nil then
		funLog(Logger.INFO, "注册相关的facade类型" )
		return
	end
	self.targetKey = key
	self.dataLoaded = {} --已加载的配表记录
	self.parsers = {} --所有的解析器集合
	self.cacheDatas = {GLOBALPARSER = {datas = {}}}
	self.confCacheMap_ = {}
	self.configs = {}
	DataManager.instances[key] = self
end

--[[
开始异步加载数据
@params callback 异步加载的回调
@params configs 所要加载的配表
@params handleDataRead 是否存在自己的数据处理逻辑函数
@customerResources 自定义的其他加载任务的逻辑
--]]
function DataManager:InitialDatasAsync(callback, configs, handleDataRead, customerResources)
	if not configs then
		-- configs = {"goods","quest"}
		configs = {'cards', 'monster', 'pet', 'common', 'artifact'}  -- 没有必须的情况就别追加了
	end

	if SKIP_UPDATE then
		callback({event="done"})
		return
	end

    local needLoadConfigs = {}
    for key,name in pairs(configs) do
		local storeName = self.GetParserName(name)
		if not self.parsers[storeName] then
			table.insert(needLoadConfigs, storeName)
		end
	end
	
    if next(needLoadConfigs) ~= nil then
		-- dump(needLoadConfigs)
		local loader = CCResourceLoader:getInstance()
		loader:registerScriptHandler(function ( event )
			callback(event) --回调加载的进步以及是否完成的逻辑
		end)

		for k, name in pairs( needLoadConfigs ) do
			local parser  = require(string.format('Game.Datas.Parser.%s', name)).new()
			local files   = checktable(parser:GetConfigFiles())
			local fcount  = table.nums(files)
			local fnumber = 0
			for tableName, path in pairs( files ) do
				loader:addCustomTask(cc.CallFunc:create(function()
					if handleDataRead then
						handleDataRead(parser)
					else
						-- parser:Load(self)
						parser:ParserSpecifyConfigFile(tableName, path)
						fnumber = fnumber + 1
						if fcount == fnumber then
							self.parsers[name] = parser
						end
					end
				end), DEBUG_SCENE_NAME and 0 or 0.01)
			end
		end

        if type(customerResources) == 'table' then
            for name,val in pairs(customerResources) do
                loader:addCustomTask(val)
            end
        end
		loader:run()
		
	else
		callback({event="done"})
	end
end
--[[
得到指定模块的parser解析器
@params name 指定模块的名字【good,quest,task]
--]]
function DataManager:GetParserByName( name )
	local storeName = self.GetParserName(name)
	if not self.parsers[tostring( storeName )] then
		--如果是未解析的配表
		if utils.isExistent( string.format('Game/Datas/Parser/%s.lua' ,storeName ) ) then
			local parser = require( string.format('Game.Datas.Parser.%s', storeName)).new()
			-- parser:Load(self)
			self.parsers[storeName] = parser
		else
			return nil
		end
	end
	return self.parsers[storeName]
end


function DataManager.GetInstance(key)
	key = (key or "DataManager")
	if DataManager.instances[key] == nil then
		DataManager.instances[key] = DataManager.new(key)
	end
	return DataManager.instances[key]
end


function DataManager.Destroy( key )
	key = (key or "DataManager")
	if DataManager.instances[key] == nil then
		return
	end
    local instance = DataManager.instances[key]
    instance.dataLoaded = {} --已加载的配表记录
    instance.parsers = {} --所有的解析器集合
	instance.cacheDatas = {GLOBALPARSER = {datas = {}}}
	instance.confCacheMap_ = {}
    instance.configs = {}
	--清除配表数据
	DataManager.instances[key] = nil
end


--[[
获取解析器文件名
@params name string 模块名
@return _ string 解析器文件名
--]]
function DataManager.GetParserName( name )
	return string.ucfirst(name) .. "ConfigParser"
end


--[[
	==============================================
	-----------------数据操作的相关逻辑--------------
	----------------------------------------------
]]
--[[
根据json文件名取得具体的配表数据
@params jsonFileName string 具体的某一个json文件的数据
@params moduleName string 可以为空，为空时解析指定文件
@return table json文件的lua数据
--]]
function DataManager:GetConfigDataByFileName( jsonFileName_, moduleName_)
	local jsonFileName = tostring(jsonFileName_)
	local moduleName   = checkstr(moduleName_)
	local confCacheMap = self.confCacheMap_
	if confCacheMap[moduleName] == nil then
		confCacheMap[moduleName] = {}
	end
	if confCacheMap[moduleName][jsonFileName] == nil then
		confCacheMap[moduleName][jsonFileName] = self:GetConfigDataByFileName_(checkstr(jsonFileName_), moduleName_) or {}
	end
	return confCacheMap[moduleName][jsonFileName]
end
function DataManager:GetConfigDataByFileName_( jsonFileName, moduleName)
	local realFileName = jsonFileName
    local moduleDir = string.len(checkstr(moduleName)) > 0 and moduleName or nil
	if not string.find( realFileName, '.json') then
		realFileName = realFileName .. '.json'
	else
		local pos = string.find( jsonFileName, '.json')
		jsonFileName = string.sub( jsonFileName, 0, pos - 1 )
	end
	local parser = nil
    if moduleName then
		if nil == string.find(moduleName, 'ConfigParser') then
			moduleName = string.ucfirst(moduleName) .. 'ConfigParser'
		end
        parser = self.parsers[moduleName]
		if parser == nil then
			local parserPath = 'Game/Datas/Parser/' .. moduleName .. '.lua'
			if utils.isExistent(parserPath) then
				parser = self:GetParserByName(moduleDir)
			end
		end
	else
		if not isChinaSdk() then
			for k,v in pairs(self.parsers) do
				if v.configFiles_ == nil then
					v.configFiles_ = v:GetConfigFiles()
				end
				local files = v.configFiles_
				if files[jsonFileName] then
					parser = v
					break
				end
			end
        end
	end
	if parser then
        if not parser.datas[tostring(jsonFileName)] then
            --可能存在未添加到解析列表的情况
            local parsername = parser.NAME
            local pos = string.find(parsername, "ConfigParser")
			local path = "conf/" .. i18n.getLang() .. '/' .. string.dcfirst(string.sub(parsername,0, pos -1 )) .. '/' .. realFileName
            parser:ParserSpecifyConfigFile(jsonFileName,path)
        end
		return parser.datas[tostring(jsonFileName)]
	else
        local path = "conf/" .. i18n.getLang() .. "/" .. realFileName
        if moduleDir then
            path = "conf/" .. i18n.getLang() .. "/" .. moduleDir .. "/" .. realFileName
        end
        if not self.cacheDatas[GLOBALPARSER].datas[tostring(path)] then
            local t = getRealConfigData(path, stripextension(basename(path)))
            self.cacheDatas[GLOBALPARSER].datas[tostring(path)] = t
        end
        return self.cacheDatas[GLOBALPARSER].datas[tostring(path)]
	end
end

--[[
-- ==========================================================
--服务端通知管理的本地逻辑
--通知的数据表格式
-- {
--	id integer 数据库id
--  name text unique  name 惟一值
--  atype text  类别
--  number intege 收到通知后的数量
--}
-- playerId : {
--	name_atype = {}
--}
--]]
local shareUserDefault = cc.UserDefault:getInstance()
local TABLE_NAME_NOTIFY = "notifications"

local DB_NAME = 'res/notification'

function DataManager:GetAllRedDotNoficationData()
	local playerId = checkint(self:GetGameManager().userInfo.playerId)
	local data = shareUserDefault:getStringForKey(TABLE_NAME_NOTIFY)
	local allRed = {}
	if playerId > 0 and data then
		data = crypto.decodeBase64(data)
		allRed = (json.decode(data) or {}) --解析出来表
	end
	if allRed[tostring(playerId)] == nil then
		allRed[tostring(playerId)] = {}
	end
	return allRed
end

function DataManager:GetPlayerRedDotNoficationData()
	if self.allRedData_ == nil then
		self.allRedData_ = self:GetAllRedDotNoficationData()
	end

	local playerId = checkint(self:GetGameManager().userInfo.playerId)
	return self.allRedData_[tostring(playerId)]
end

function DataManager:SaveAllRedDotNoficationData()
	local ret = json.encode(self.allRedData_)
	shareUserDefault:setStringForKey(TABLE_NAME_NOTIFY, crypto.encodeBase64(ret))
	shareUserDefault:flush()
end

function DataManager:GetRedDotNoficationItemId( name, atype)
	return string.format( "%s_%s",name, atype )
end

function DataManager:AddRedDotNofication( name, atype, source, autoSave)
	if self.playerRedData_ == nil then
		self.playerRedData_ = self:GetPlayerRedDotNoficationData()
	end
	--添加一个小红点数据,如果分服后要添加服务器的id对应
		--写入文件的操作功能
	local playerId = checkint(self:GetGameManager().userInfo.playerId)
    -- local userId = checkint(self:GetGameManager().userInfo.userId)
    -- local dbPath = cc.FileUtils:getInstance():fullPathForFilename(DB_NAME)
    -- if not source then source = tostring(name) end
	if playerId > 0 then
		-- shareUserDefault:deleteValueForKey(TABLE_NAME_NOTIFY)
		-- local data = shareUserDefault:getStringForKey(TABLE_NAME_NOTIFY)
		local item_id = self:GetRedDotNoficationItemId(name, atype )
		-- if data then
			-- data = crypto.decodeBase64(data)
			-- local t = (json.decode(data) or {}) --解析出来表
			-- local items = t[tostring(playerId)]
			local items = self.playerRedData_
			if items and table.nums(items) > 0 then
				-- dump(items[item_id])
				if items[item_id] then
					--这里是否需要直接数量变成1的逻辑功能
					-- items[item_id].number = items[item_id].number + 1
					items[item_id].number = 1 --始终将其至1吧先
				else
					items[item_id] = {id = playerId, name = name, atype = atype, number = 1}
				end
			else
				self.allRedData_[tostring(playerId)] = {[tostring(item_id)] = {id = playerId, name = name, atype = atype, number = 1}}
				self.playerRedData_ = self.allRedData_[tostring(playerId)]
			end
			-- local ret = json.encode(self.allRedData_)
			-- shareUserDefault:setStringForKey(TABLE_NAME_NOTIFY, crypto.encodeBase64(ret))
			-- shareUserDefault:flush()
			if autoSave == nil or autoSave == true then
				self:SaveAllRedDotNoficationData()
			end
		-- else
		-- 	local t = {}
		-- 	t[tostring(playerId)] = {[tostring(item_id)] = {id = playerId, name = name, atype = atype, number = 1}}
		-- 	local ret = json.encode(t)
		-- 	shareUserDefault:setStringForKey(TABLE_NAME_NOTIFY, crypto.encodeBase64(ret))
		-- 	shareUserDefault:flush()
		-- end
        if checkint(name) == RemindTag.BACKPACK then
            --更新盘子上的小红点的显示
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.BACKPACK})
		end
		-- if isRecordRedLog then
		-- 	local sqlite3 = require('lsqlite3')
		-- 	local db = sqlite3.open(dbPath)
		-- 	if db and db:isopen() then
		-- 		--向日志表中插入数据
		-- 		local pstmt = db:prepare("insert into notification_log(name, tagId, source, userId, playerId, logTime) values(?,?,?,?,?,?);")
		-- 		db:exec('begin;')
		-- 		pstmt:bind(1, tostring(name))
		-- 		pstmt:bind(2, tostring(atype))
		-- 		pstmt:bind(3, string.format("added from [%s] ", tostring(source)))
		-- 		pstmt:bind(4, userId)
		-- 		pstmt:bind(5, playerId)
		-- 		pstmt:bind(6, os.time())
		-- 		pstmt:step()
		-- 		pstmt:reset()
		-- 		db:exec('commit;')
		-- 		pstmt:finalize()
		-- 		db:close()
		-- 	end
		-- end
    end
end

function DataManager:GetRedDotNofication( name, atype, source)
	if self.playerRedData_ == nil then
		self.playerRedData_ = self:GetPlayerRedDotNoficationData()
	end
	--添加一个小红点数据,如果分服后要添加服务器的id对应
		--写入文件的操作功能
    -- if not source then source = tostring(name) end
	local playerId = checkint(self:GetGameManager().userInfo.playerId)
    -- local userId = checkint(self:GetGameManager().userInfo.userId)
    -- local dbPath = cc.FileUtils:getInstance():fullPathForFilename(DB_NAME)
	local no = 0
	if playerId > 0 then
		-- shareUserDefault:deleteValueForKey(TABLE_NAME_NOTIFY)
		-- local data = shareUserDefault:getStringForKey(TABLE_NAME_NOTIFY)
		local item_id = self:GetRedDotNoficationItemId(name, atype )
		-- if data then
		-- 	data = crypto.decodeBase64(data)
		-- 	local t = (json.decode(data) or {}) --解析出来表
			-- local items = t[tostring(playerId)]
			local items = self.playerRedData_
			if items and table.nums(items) > 0 then
				if items[item_id] then
					no = items[item_id].number
				end
			end
			-- local ret = json.encode(t)
			-- shareUserDefault:setStringForKey(TABLE_NAME_NOTIFY, crypto.encodeBase64(ret))
			-- shareUserDefault:flush()
			-- self:SaveAllRedDotNoficationData()
		-- end
	-- end
	-- if isRecordRedLog then
	-- 	local sqlite3 = require('lsqlite3')
	-- 	local db = sqlite3.open(dbPath)
	-- 	if db and db:isopen() then
	-- 		--向日志表中插入数据
	-- 		local pstmt = db:prepare("insert into notification_log(name, tagId, source, userId, playerId, logTime) values(?,?,?,?,?,?);")
	-- 		db:exec('begin;')
	-- 		pstmt:bind(1, tostring(name))
	-- 		pstmt:bind(2, tostring(atype))
	-- 		pstmt:bind(3, string.format("get from [%s] ", tostring(source)))
	-- 		pstmt:bind(4, userId)
	-- 		pstmt:bind(5, playerId)
	-- 		pstmt:bind(6, os.time())
	-- 		pstmt:step()
	-- 		pstmt:reset()
	-- 		db:exec('commit;')
	-- 		pstmt:finalize()
	-- 		db:close()
	-- 	end
	end
	return no
end

-- function DataManager:UpdateRedDotNofication( name, type )
-- 	--添加更新一个小红点数据
-- 	local playerId = checkint(self:GetGameManager().userInfo.playerId)
-- 	local data = shareUserDefault:getStringForKey(TABLE_NAME_NOTIFY)
-- 	if data then
-- 		data = crypto.decodeBase64(data)
-- 		local t = (json.decode(data) or {}) --解析出来表
-- 		local item = t[tostring(playerId)]
-- 		if not item then
-- 			item = {id = playerId, name = name, type = type, number = 0}
-- 			t[tostring(playerId)] = {item}
-- 		end
-- 		item.number = item.number + 1
-- 		local ret = json.encode(t)
-- 		shareUserDefault:setStringForKey(TABLE_NAME_NOTIFY, crypto.encodeBase64(ret))
-- 		shareUserDefault:flush()
-- 	end
-- end

function DataManager:ClearRedDotNofication( name, atype, source)
	if self.playerRedData_ == nil then
		self.playerRedData_ = self:GetPlayerRedDotNoficationData()
	end
	--添加清除某一类型的小红点数据
    -- if not source then source = tostring(name) end
	local playerId = checkint(self:GetGameManager().userInfo.playerId)
    -- local userId = checkint(self:GetGameManager().userInfo.userId)
    -- local dbPath = cc.FileUtils:getInstance():fullPathForFilename(DB_NAME)

	if playerId > 0 then
		local item_id = self:GetRedDotNoficationItemId(name, atype )
		-- local data = shareUserDefault:getStringForKey(TABLE_NAME_NOTIFY)
		-- if data then
			-- data = crypto.decodeBase64(data)
			-- local t = (json.decode(data) or {}) --解析出来表
			-- local targetDatas = t[tostring(playerId)]
			local targetDatas = self.playerRedData_
			if targetDatas then
				local itemData = targetDatas[tostring(item_id)]
				if itemData then
					targetDatas[tostring(item_id)] = nil
				end
			else
				self.allRedData_[tostring(playerId)] = {}
				self.playerRedData_ = {}
			end
			-- local ret = json.encode(self.allRedData_)
			-- shareUserDefault:setStringForKey(TABLE_NAME_NOTIFY, crypto.encodeBase64(ret))
			-- shareUserDefault:flush()
			self:SaveAllRedDotNoficationData()
		-- end
	-- 	if isRecordRedLog then
	-- 		local sqlite3 = require('lsqlite3')
	-- 		local db = sqlite3.open(dbPath)
	-- 		if db and db:isopen() then
	-- 			--向日志表中插入数据
	-- 			local pstmt = db:prepare("insert into notification_log(name, tagId, source, userId, playerId, logTime) values(?,?,?,?,?,?);")
	-- 			db:exec('begin;')
	-- 			pstmt:bind(1, tostring(name))
	-- 			pstmt:bind(2, tostring(atype))
	-- 			pstmt:bind(3, string.format("delete from [%s] ", tostring(source)))
	-- 			pstmt:bind(4, userId)
	-- 			pstmt:bind(5, playerId)
	-- 			pstmt:bind(6, os.time())
	-- 			pstmt:step()
	-- 			pstmt:reset()
	-- 			db:exec('commit;')
	-- 			pstmt:finalize()
	-- 			db:close()
	-- 		end
	-- 	end
	end
end
return DataManager
