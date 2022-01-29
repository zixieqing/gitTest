--[[
--网络相关的命令集合
--]]
NetCmd = {
	-------------------------------------------------
	-- game base
	Empty               = 1000, --空命令 用来保持连接alive
	Error               = 1100, --错误发生
	Disconnect          = 1002, --断开连接
	RequestID           = 1004, --用来发送连接后的第一个数据验证包
	Request_1005        = 1005, --用来发送连接后的第一个数据验证包
	RequestPlayerInfoID = 1001, --请求一次playerinfo的数据（常用于同步金币幻晶石）
	RequestPing         = 1999, --ping命令
	ExecuteScript       = 9999, --执行脚本（后门接口，debug下开放）

	-------------------------------------------------
	-- game info
	RequestDailyTask        = 2001, --日常任务通知
	RequestMainTask        	= 2002, --主线任务通知
	RequestBonus            = 2003, --满星奖励
	RequestPrize            = 2004, --新的奖励的通知
	RequestFriendMsg        = 2006, --好友私信通知
	RequestNewFriend        = 2007, --好友请求通知
	Request2008 			= 2008, --踢人的操作
	RequestStoryUnlock      = 2009, --剧情任务解锁
	RequestStoryComplete    = 2010, --剧情任务完成
	RequestRegionalUnlock   = 2011, --支线任务解锁
	RequestRegionalComplete = 2012, --支线任务完成
	RequestMarketSale       = 2013, --市场中道具已出售
	RequestTeskProgress     = 2014, --餐厅任务进度
	RequestWaiterDied 		= 2015, --餐厅服务员新鲜度耗尽
	RequestSpecialCustomer  = 2016, --餐厅特殊客人
	-- RequestAnnouce          = 2019, --新公告通知
	RequestPayMoneySuccess  		    = 2019, -- 充值成功
    RequestRestaurantSaleRecipe         = 2020, -- 餐厅出售完菜
	RequestNewbieTaskRemain             = 2021, -- 新手任务完成通知
	RequestRestaurantBugAppear   	    = 2022, -- 餐厅虫子出现
	RequestRestaurantBugHelp     	    = 2023, -- 餐厅虫子求助
	RequestRestaurantBugClear    	    = 2024, -- 餐厅虫子清除
	RequestRestaurantQuestEventHelp     = 2025, -- 餐厅霸王餐求助
	RequestRestaurantQuestEventFighting = 2026, -- 餐厅霸王餐战斗
    Request2027                         = 2027, -- 霸王餐胜利的逻辑
    RequestBonusHard 			        = 2028, -- 困难本满星奖励
	RequestLimitGiftBag 		        = 2029, -- 限时礼包刷线
	RequestMessageBoard 		        = 2030, -- 个人留言板
	RequestRequestAssistant             = 2031, -- 好友请求捐助
	RequestAssistant                    = 2032, -- 好友发送捐助
	RequestFullServer                   = 2033, -- 全服活动任务
	GAME_NOTICE                         = 2034, -- 全服游戏公告
	RequestBinggoTaskDone               = 2035, -- binggo活动 完成 
	RequestAccumulativePay		        = 2036, -- 累充活动红点
	RequestAccumulativeConsume          = 2037, -- 累消活动红点
	RequestRecallTaskComplete	        = 2038, -- 老玩家任务进度
	RequestMasterRecalled		        = 2039, -- 老玩家成功召回其他人
	RequestRecallRewardAvailable        = 2040, -- 老玩家H5界面可以领奖
	FISH_FRIEND_CARD_UNLOAD_EVENT       = 2041, -- 飨灵在好友钓场卸下通知
	FISH_FRIEND_CARD_LOAD_EVENT         = 2042, -- 好友在玩家钓场添加飨灵
	FRIEND_RECALL_FISHERMAN_EVENT       = 2043, -- 好友召回钓手
	RETURNWELFARE_BINGO_TASK_FINISH     = 2045, -- 回归福利任务完成通知
	REQUEST_CONTINUOUS_ACTIVE 	 	 	= 2047, -- 连续活跃活动红点
	REQUEST_ANTI_ADDICTION 	 	 	    = 2049, -- 防沉迷T人:
	ARTIFACT_GUIDE_REMIND_ICON  	    = 2050, -- 神器指引红点
	ALLROUND_PROGRESS_NOTICE  	        = 2051, -- 全能王路线任务 进度通知
	NEWBIE14_PROGRESS_NOTICE  	        = 2052, -- 新手14天任务 进度通知
	CATHOUSE_PROGRESS_NOTICE  	        = 2053, -- 猫屋 任务进度通知
    RequestKickOut                      = 2998, -- 长连接下的踢人操作的合令号
	-------------------------------------------------
	-- game chat
	RequestJoinChatroom            = 5001, -- 进入聊天室
	RequestChatroomSendMessage     = 5002, -- 聊天室发送消息
	RequestChatroomGetMessage      = 5003, -- 聊天室收到消息
	RequestOutChatroom             = 5004, -- 退出聊天室
	RequestPrivateSendMessage      = 5006, -- 发送私信
	RequestPrivateGetMessage       = 5007, -- 收到私信
	RequestSurePrivateGetMessage   = 5008, -- 确认收到私信
	RequestSystemMessage           = 5009, -- 系统消息
	RequestWorldRoomsMessage       = 5010, -- 世界聊天人数
	RequestRegisterChatRoomMessage = 5011, -- 聊天室注册数据

	-------------------------------------------------
	-- team boss
	TEAM_BOSS_JOIN_TEAM            = 4001, -- 参与组队
	TEAM_BOSS_MEMBER_NOTICE        = 4002, -- 成员变动
	TEAM_BOSS_CARD_CHANGE          = 4003, -- 卡牌变更
	TEAM_BOSS_CARD_NOTICE          = 4004, -- 卡牌通知
	TEAM_BOSS_CSKILL_CHANGE        = 4005, -- 主角技变更
	TEAM_BOSS_CSKILL_NOTICE        = 4006, -- 主角技通知
	TEAM_BOSS_READY_CHANGE         = 4007, -- 准备变更
	TEAM_BOSS_READY_NOTICE         = 4008, -- 准备通知
	TEAM_BOSS_ENTER_BATTLE         = 4009, -- 进入战斗
	TEAM_BOSS_ENTER_NOTICE         = 4010, -- 进入通知
	TEAM_BOSS_KICK_MEMBER          = 4011, -- 踢出成员
	TEAM_BOSS_KICK_NOTICE          = 4012, -- 踢人通知
	TEAM_BOSS_BATTLE_RESULT 	   = 4018, -- 战斗结束
	TEAM_BOSS_BATTLE_RESULT_NOTICE = 4019, -- 战斗结束通知
	TEAM_BOSS_BOSS_CHANGE          = 4022, -- BOSS变更
	TEAM_BOSS_BOSS_NOTICE          = 4023, -- BOSS通知
	TEAM_BOSS_EXIT_CHANGE          = 4024, -- 退出组队
	TEAM_BOSS_EXIT_NOTICE          = 4025, -- 退出通知
	TEAM_BOSS_CAPTAIN_CHANGE       = 4026, -- 队长变更
	TEAM_BOSS_CAPTAIN_NOTICE       = 4027, -- 队长通知
	TEAM_BOSS_LOADING_OVER 		   = 4029, -- 加载结束
	TEAM_BOSS_LOADING_OVER_NOTICE  = 4030, -- 全员加载结束广播
	TEAM_BOSS_PASSWORD_CHANGE      = 4031, -- 密码变更
	TEAM_BOSS_PASSWORD_NOTICE      = 4032, -- 密码通知
	TEAM_BOSS_ATTEND_TIMES_BUY     = 4033, -- 参与次数购买
	TEAM_BOSS_ATTEND_TIMES_BOUGHT  = 4034, -- 次数购买成功
	TEAM_BOSS_TEAM_DISSOLVED 	   = 4035, -- 队伍被解散
	TEAM_BOSS_TEAM_RECOVER 		   = 4036, -- 房间取消解散
	TEAM_BOSS_BATTLE_OVER 		   = 4037, -- 组队战斗结束
	TEAM_BOSS_BATTLE_OVER_NOTICE   = 4038, -- 组队战斗结束通知
	TEAM_BOSS_CHOOSE_REWARD 	   = 4039, -- 战斗结束选择奖励
	TEAM_BOSS_CHOOSE_REWARD_NOTICE = 4040, -- 战斗结束选择奖励通知
	--------------- battle ---------------
	RaidRequestSendLogicFrameData = 4013, -- 上传帧数据
	RaidRequestGetLogicFrameData  = 4014, -- 下发帧数据
	--------------- battle ---------------

    ---------restuarant------------------
    CustomerArrival       = 6001, -- 客人到达餐厅
    CustomerLeave         = 6002, -- 客人离开
    RestuarantRewards     = 6003, -- 奖励
    RestuarantPutNewGoods = 6004, -- 添加新的道具
    RestuarantRemoveGoods = 6005, -- 删除道具
    RestuarantMoveGoods   = 6006, -- 移动道具后确定的逻辑
    RestuarantService     = 6007, -- 服务客人
    Request_6008          = 6008, -- 获取桌子信息
    RequestEmploySwich    = 6009, -- 主管, 初始, 服务员更换
    RequestEmployUnlock   = 6010, -- 主管, 初始, 服务员解锁
	FRIEND_RESTUARANT_LOG = 6011, -- 餐厅消息上传
	RestuarantCleanAll    = 6012, -- 清空餐厅布局
	---------restuarant------------------
	
	-------------------------------------------------
	-- union
	APPLY_UNION_RESULT             = 7001, -- 申请工会结果
	UNION_ROOM_APPEND              = 7002, -- 工会加入房间
	UNION_ROOM_MEMBER              = 7003, -- 工会房间人数
	UNION_JOIN_APPLY               = 7004, -- 工会入会申请
	UNION_KICK_MEMBER              = 7005, -- 工会踢人通知
	UNION_JOB_CHANGE               = 7006, -- 工会职位变更
	UNION_ROOM_QUIT                = 7007, -- 工会退出房间
	UNION_TASK_FINISH              = 7008, -- 工会任务完成
	UNION_AVATAR_MOVE_SEND         = 7009, -- 工会角色移动发送
	UNION_AVATAR_MOVE_TAKE         = 7010, -- 工会角色移动通知
	UNION_PARTY_FOOD_NUM_CHANGE    = 7011, -- 工会菜品数量变化
	UNION_PET_LEVEL_CHANGE         = 7012, -- 工会堕神等级改变
	UNION_AVATAR_CHANGE            = 7013, -- 工会大厅形象改变
	UNION_PARTY_BOSS_RESULT        = 7014, -- 工会派对堕神结果
	UNION_PARTY_ROLL_NOTICE        = 7015, -- 工会派对roll点通知
	UNION_AVATAR_LOBBY_CHANGE      = 7016, -- 工会角色进出大厅
	UNION_WARS_UNION_APPLY         = 7017, -- 工会战 报名成功通知
	UNION_WARS_ATTACK_START        = 7018, -- 工会战 进攻敌方 开始
	UNION_WARS_DEFEND_START        = 7019, -- 工会战 被敌方攻击 开始
	UNION_WARS_ATTACK_ENDED        = 7020, -- 工会战 进攻敌方 结束
	UNION_WARS_DEFEND_ENDED        = 7021, -- 工会战 被敌方进攻 结束
	UNION_IMPEACHMENT_TIMES_NOTICE = 7022, -- 工会弹劾 当前投票人数
	UNION_PRESIDENT_ONLINE_NOTICE  = 7023, -- 工会弹劾 会长上线

	-------------------------------------------------
	-- tag match
	TAG_MATCH_PLAYER_RANK_CHANGE         = 8001,  -- 天城演武玩家排名变化
	TAG_MATCH_PLAYER_SHIELD_POINT_CHANGE = 8002,  -- 天城演武防守生命值变化

	-------------------------------------------------
	-- ttGame
	TTGAME_NET_LINK              = 10999, -- 打牌游戏 网络握手
	TTGAME_NET_SYNC              = 10021, -- 打牌游戏 网络同步
	TTGAME_PVE_ENTER             = 10001, -- 打牌游戏 pve匹配
	TTGAME_PVP_MATCH             = 10007, -- 打牌游戏 pvp匹配
	TTGAME_ROOM_CREATE           = 10002, -- 打牌游戏 房间创建
	TTGAME_ROOM_ENTER            = 10003, -- 打牌游戏 房间进入
	TTGAME_ROOM_ENTER_NOTICE     = 10004, -- 打牌游戏 房间进入通知
	TTGAME_ROOM_LEAVE            = 10019, -- 打牌游戏 房间离开
	TTGAME_ROOM_LEAVE_NOTICE     = 10020, -- 打牌游戏 房间离开通知
	TTGAME_ROOM_READY            = 10005, -- 打牌游戏 房间准备
	TTGAME_ROOM_READY_NOTICE     = 10006, -- 打牌游戏 房间准备通知
	TTGAME_ROOM_MOOD             = 10009, -- 打牌游戏 房间发送心情
	TTGAME_ROOM_MOOD_NOTICE      = 10010, -- 打牌游戏 房间心情通知
	TTGAME_GAME_MATCHED_NOTICE   = 10008, -- 打牌游戏 匹配通知
	TTGAME_GAME_ABANDON          = 10017, -- 打牌游戏 主动认输
	TTGAME_GAME_RESULT_NOTICE    = 10016, -- 打牌游戏 结果通知
	TTGAME_GAME_PLAY_CARD        = 10014, -- 打牌游戏 出牌操作
	TTGAME_GAME_PLAY_CARD_NOTICE = 10015, -- 打牌游戏 出牌通知

	-------------------------------------------------
	-- cat house
	HOUSE_AVATAR_APPEND           = 11001, -- 猫屋 添置avatar
	HOUSE_AVATAR_REMOVE           = 11002, -- 猫屋 撤下avatar
	HOUSE_AVATAR_MOVED            = 11003, -- 猫屋 移动avatar
	HOUSE_AVATAR_CLEAR            = 11004, -- 猫屋 清空avatar
	HOUSE_AVATAR_NOTICE           = 11007, -- 猫屋 变更avatar
	HOUSE_MEMBER_LIST             = 11005, -- 猫屋 访客列表
	HOUSE_MEMBER_VISIT            = 11006, -- 猫屋 访客来访
	HOUSE_MEMBER_LEAVE            = 11008, -- 猫屋 访客离开
	HOUSE_MEMBER_HEAD             = 11011, -- 猫屋 访客改头像
	HOUSE_MEMBER_BUBBLE           = 11012, -- 猫屋 访客改气泡
	HOUSE_MEMBER_WALK             = 11010, -- 猫屋 访客移动
	HOUSE_MEMBER_IDENTITY         = 11013, -- 猫屋 访客改身份
	HOUSE_INVITE_NOTICE           = 11014, -- 猫屋 邀请通知
	HOUSE_SELF_WALK_SEND          = 11009, -- 猫屋 自己移动
	HOUSE_CAT_STATUS_NOTICE       = 11015, -- 猫屋 猫咪状态变更
	HOUSE_CAT_ACCEPT_BREED_INVITE = 11016, -- 猫屋 好友接受生育邀请
	HOUSE_CAT_FAVORIBILITY_NOTICE = 11017, -- 猫屋 猫咪好感度变化通知
	
}