--[[
 * author : kaishiqi
 * descpt : 短链接 - 相关命令定义
]]
---@class PostData
---@field public postUrl string
---@field public cmdName string
---@field public sglName string
---@return PostData
local PostData = function(url)
    local postUrl = tostring(url)
    local urlName = string.gsub(postUrl, '/', '_')
    local pData = readOnly({
        postUrl = postUrl,
        cmdName = string.format('REQUEST_%s', urlName),
        sglName = string.format('RECEIVE_%s', urlName),
    })
    return pData
end


-- regist single post command
registSinglePostCommand = function(postData, isListenError)
    local SinglePostCommand     = class('SinglePostCommand', mvc.SimpleCommand)
    SinglePostCommand.super     = mvc.SimpleCommand.super
    SinglePostCommand.postUrl_  = postData.postUrl
    SinglePostCommand.cmdName_  = postData.cmdName
    SinglePostCommand.sglName_  = postData.sglName
    SinglePostCommand.isLisErr_ = isListenError == true

    function SinglePostCommand:Execute(signal)
        if signal:GetName() == SinglePostCommand.cmdName_ then
            app.httpMgr:Post(SinglePostCommand.postUrl_, SinglePostCommand.sglName_, signal:GetBody(), SinglePostCommand.isLisErr_)
        end
    end

    AppFacade.GetInstance():RegistSignal(SinglePostCommand.cmdName_, SinglePostCommand)
end

-- unregist single post command
unregistSinglePostCommand = function(postData)
    AppFacade.GetInstance():UnRegsitSignal(postData.cmdName)
end


-- post data defines
POST = {
    -------------------------------------------------
    -- user
    USER_EUROPEAN_AGREEMENT = PostData('user/zmEuropeanAgreement'), -- 智明欧盟协议请求通过)
    -------------------------------------------------
    -- tower
    TOWER_HOME                  = PostData('tower/home'),                     -- 爬塔首页
    TOWER_SET_CARD_LIBRARY      = PostData('tower/setClimbTeam'),             -- 设置爬塔卡牌库
    TOWER_SET_PAST_CARD_LIBRARY = PostData('tower/setClimbTeam/appMediator'), -- 设置之前的爬塔卡牌库
    TOWER_ENTER                 = PostData('tower/enterTower'),               -- 进入爬塔
    TOWER_EXIT                  = PostData('tower/exitTower'),                -- 退出爬塔
    TOWER_UNIT_SET_CONFIG       = PostData('tower/setUnitConfig'),            -- 单元配置设置
    TOWER_UNIT_DRAW_REWARD      = PostData('tower/draw'),                     -- 单元奖励领取

    -------------------------------------------------
    -- activity
    ACTIVITY_DRAW_FIRSTPAY                    = PostData('Activity/drawFirstPay/'),            -- 首充奖励领取
    ACTIVITY_DRAW_FIRSTPAY_HOME               = PostData('Activity/drawFirstPay'),             -- 首充奖励领取
    ACTIVITY_DRAW_NEWPLAYER_SEVEN_DAY         = PostData('Activity/drawNewbieTaskBaseReward'), --(新手任务领取)
    ACTIVITY_DRAW_FINAL_NEWPLAYER_SEVEN_DAY   = PostData('Activity/drawNewbieTask'),           --(完成新手所有任务领取奖励)
    ACTIVITY_CVSHARE                          = PostData('Activity/cvShare'),                  -- CV分享活动
    ACTIVITY_CVSHARE_GAMBLING                 = PostData('Activity/cvShareGambling'),          -- CV分享活动抽取
    ACTIVITY_CVSHARE_SHARE_SUCCESS            = PostData('Activity/cvShareClick'),             -- CV分享活动分享成功
    ACTIVITY_DRAW_CVSHARE                     = PostData('Activity/drawCvShareCollect'),       -- CV分享活动收集领取
    Activity_Draw_restaurant                  = PostData('Activity/restaurant'),               -- 餐厅活动
    CUMULATIVE_RECHARGE_HOME                  = PostData('Activity/persistencePayRewards'),    -- 永久累充
    CUMULATIVE_RECHARGE_DRAW                  = PostData('Activity/drawPersistencePayReward'), -- 永久累充领奖
    LEVEL_GIFT_CHEST                          = PostData("Activity/levelChest"),
    ACTIVITY_BALLOON_HOME                     = PostData('Activity/ranBubbleList'),            -- 打气球活动Home
    ACTIVITY_BALLOON_GET_BREAK_GOODS          = PostData('Activity/getBreakBubble'),           -- 获取打气球道具
    ACTIVITY_BALLOON_BREAK                    = PostData('Activity/bubbleBreak'),              -- 打气球
    ACTIVITY_BALLOON_EXCHANGE                 = PostData('Activity/bubbleExchange'),           -- 打气球活动兑换
    ACTIVITY_KOFARENA                         = PostData('Activity/kofArena'),                 -- kof竞技场活动页
    ACTIVITY_SINGLE_PAY_HOME                  = PostData('Activity/singlePay'),                -- 单笔充值活动home
    ACTIVITY_SINGLE_PAY_DRAW                  = PostData('Activity/singlePayExchange'),        -- 单笔充值活动领取
    ACTIVITY_PERMANENT_SINGLE_PAY_HOME        = PostData('Activity/permanentSinglePay'),       -- 常驻单笔充值活动home
    ACTIVITY_PERMANENT_SINGLE_PAY_DRAW        = PostData('Activity/permanentSinglePayExchange'), -- 常驻单笔充值活动领取
    ACTIVITY_LEVEL_ADVANCE_CHEST              = PostData('Activity/levelAdvanceChest'),        -- 进阶等级礼包
    ACTIVITY_LEVEL_REWARD                     = PostData('Activity/levelReward'),              -- 等级奖励
    ACTIVITY_DRAW_LEVEL_REWARD                = PostData('Activity/drawLevelReward'),          -- 领取等级奖励
    ACTIVITY_GAMBLING_LUCKY                   = PostData('Activity/gamblingLucky'),            -- 活动卡池抽卡
    ACTIVITY_PAY_LOGIN_REWARD                 = PostData('Activity/payLoginReward'),           -- 付费签到
    ACTIVITY_DRAW_PAY_LOGIN_REWARD            = PostData('Activity/drawPayLoginReward'),       -- 领取付费签到奖励
    ACTIVITY_DRAW_CUMULATIVE_PAY_LOGIN_REWARD = PostData('Activity/drawCumulativePayLoginReward'),  -- 领取累计付费签到奖励
    ACTIVITY_FOOD_COMPARE_RESULT              = PostData('Activity/foodCompareResult'),        -- 飨灵比拼结果
    ACTIVITY_FOOD_COMPARE_RESULT_ACK          = PostData('Activity/foodCompareResultAck'),     -- 飨灵比拼结果领取告知
    -- 持续活跃活动
    ACTIVITY_CONTINUOUS_ACTIVE_HOME              = PostData('ContinuousActive/home'),             -- 持续活跃活动home
    ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_DRAW       = PostData('ContinuousActive/weeklyDraw'),       -- 持续活跃活动周奖励领取
    ACTIVITY_CONTINUOUS_ACTIVE_WEEKLY_SUPPLEMENT = PostData('ContinuousActive/weeklySupplement'), -- 持续活跃活动周活跃补签
    ACTIVITY_CONTINUOUS_ACTIVE_YEAR_DRAW         = PostData('ContinuousActive/yearDraw'),         -- 持续活跃活动天天奖励领取
    ACTIVITY_CONTINUOUS_ACTIVE_YEAR_SUPPLEMENT   = PostData('ContinuousActive/yearSupplement'),-- 持续活跃活动天天奖励补签

    -- 巅峰对决
    ACTIVITY_ULTIMATE_BATTLE_HOME             = PostData('UltimateBattle/home'),             -- 巅峰对决home
    ACTIVITY_ULTIMATE_BATTLE_DRAW             = PostData('UltimateBattle/draw'),             -- 巅峰对决领取奖励
    ACTIVITY_ULTIMATE_BATTLE_BUY_ATTEND_TIMES = PostData('UltimateBattle/buyAttendTimes'),   -- 巅峰对决购买次数
    ACTIVITY_ULTIMATE_BATTLE_QUEST_RANK       = PostData('Rank/ultimateBattle'),             -- 巅峰对决排行榜

    -- pass卡
    ACTIVITY_PASS_TICKET                    = PostData('Activity/passTicket'),               -- pass卡
    ACTIVITY_DRAW_PASS_TICKET               = PostData('Activity/drawPassTicket'),           -- 领取pass卡奖励
    ACTIVITY_SKIP_PASS_TICKET               = PostData('Activity/skipPassTicket'),           -- pass卡跳级
    ACTIVITY_DRAW_PASS_TICKET_OVERFLOW      = PostData('Activity/drawPassTicketOverflow'),   -- 领取pass卡溢出奖励

    -- 成长基金
    ACTIVITY_PAY_LEVEL_REWARD               = PostData('Activity/payLevelReward'),           -- 成长基金
    ACTIVITY_DRAW_PAY_LEVEL_REWARD          = PostData('Activity/drawPayLevelReward'),       -- 领取成长基金奖励
    -- 新等级礼包
    ACTIVITY_NEW_LEVEL_REWARD               = PostData('Activity2/newLevelReward'),          -- 新等级礼包
    ACTIVITY_DRAW_NEW_LEVEL_REWARD          = PostData('Activity2/drawNewLevelReward'),      -- 领取新等级礼包
    -- 新手超值福利
    ACTIVITY_NOVICE_ACC_PAY_HOME            = PostData('Activity/newbieAccumulativePay'),    -- 新手超值福利home
    ACTIVITY_NOVICE_ACC_PAY_DRAW            = PostData('Activity/drawNewbieAccumulativePay'),-- 新手超值福利领奖
    -------------------------------------------------
    -- 好友
    FRIEND_REMARK                           = PostData('friend/noteName'),                   -- 好友备注
    FRIEND_BATTLE_TEAM                      = PostData('friend/studyTeam'),                  -- 好友切磋阵容
    FRIEND_BATTLE_LIST                      = PostData('friend/studyList'),                  -- 好友切磋列表
    FRIEND_SAVE_BATTLE_TEAM                 = PostData('friend/saveStudyTeam'),              -- 保存好友切磋己方阵容
    FRIEND_BATTLE_HISTORY                   = PostData('friend/studyHistory'),               -- 好友切磋历史记录
    FRIEND_HOME                             = PostData('friend/home'),                       -- 好友home
    FRIEND_SET_TOP                          = PostData('friend/top'),                        -- 好友置顶
    FRIEND_SET_TOP_CANCEL                   = PostData('friend/down'),                       -- 好友取消置顶
    -------------------------------------------------
    -- 神器之路
    ACTIVITY_ARTIFACT_ROAD                  = PostData('Activity/artifact'),                 -- 神器之路
    ACTIVITY_ARTIFACT_ROAD_SWEEP            = PostData('Activity/artifactQuestSweep'),       -- (神器之路战斗扫荡)

    -------------------------------------------------
    -- activityQuest
    ACTIVITYQUEST_HOME                      = PostData('ActivityQuest/home'),                -- 活动副本home
    ACTIVITYQUEST_STORY_SWEEP               = PostData('ActivityQuest/sweep'),               -- 活动副本扫荡
    ACTIVITYQUEST_STORY_QUEST               = PostData('ActivityQuest/storyQuest'),          -- 活动副本剧情关卡
    ACTIVITYQUEST_DRAW_CHEST                = PostData('ActivityQuest/chestQuest'),          -- 活动副本宝箱领奖
    ACTIVITYQUEST_RESET_STORY_QUEST         = PostData('ActivityQuest/resetQuestStory'),     -- 活动副本重置剧情关卡
    ACTIVITYQUEST_RESET_ALL_STORY           = PostData('ActivityQuest/resetStory'),          -- 活动副本重置全部剧情
    ACTIVITYQUEST_RESET_EXCHANGE            = PostData('ActivityQuest/exchange'),            -- 活动副本兑换
    ACTIVITYQUEST_BUY_QUESTHP               = PostData('ActivityQuest/buyQuestHp'),          -- 活动副本购买副本体力
    -------------------------------------------------
    ACTIVITY_EXCHANGE_CARD_FRAGMENT_INFO    = PostData("Activity/exchangeCardFragmentInfo"), -- 卡牌兑换的基本信息
    ACTIVITY_EXCHANGE_CARD_FRAGMENT         = PostData("Activity/exchangeCardFragment"),     -- 卡牌兑换

    ACTIVITY_PRAY       = PostData("activity/pray"),      -- 祈愿树
    ACTIVITY_PRAY_FRUIT = PostData("activity/prayFruit"), -- 卡牌兑换
    ACTIVITY_PRAY_DRAW  = PostData("activity/prayDraw"),  -- 卡牌兑换

    -------------------------------------------------
    -- cooking
    COOKING_RECIPE_LIKE = PostData('Cooking/recipeLike'), -- 菜谱标记 喜欢/不喜欢

    -------------------------------------------------
    -- mall
    MALL_BUY_MULTI = PostData('mall/buyMulti'),  -- 商城一键购买

    -- carnie
    CARNIE_CAPSULE_HOME                     = PostData('summerActivity/lotteryHome'),        -- 游乐园（夏活）扭蛋home
    CARNIE_CAPSULE_DRAW                     = PostData('summerActivity/lottery'),            -- 游乐园（夏活）扭蛋抽奖
    CARNIE_CAPSULE_ACC_DRAW                 = PostData('summerActivity/drawOverTimeReward'), -- 游乐园（夏活）次数累计奖励领取
    CARNIE_RANK_HOME                        = PostData('summerActivity/rank'),               -- 游乐园（夏活）排行榜
    -------------------------------------------------
    -- restaurant
    RESTAURANT_VISIT_FRIEND           = PostData('Restaurant/friend'),          -- 好友餐厅
    RESTAURANT_BUG_HELP               = PostData('Restaurant/bugHelp'),         -- 求助打虫
    RESTAURANT_BUG_CLEAN              = PostData('Restaurant/bugClean'),        -- 餐厅打虫
    RESTAURANT_QUEST_HELP             = PostData('Restaurant/eventHelp'),       -- 求助霸王餐
    RESTAURANT_AGENT_SHOPOWNER        = PostData('Restaurant/manager'),         -- 代理店长
    RESTAURANT_CANCEL_AGENT_SHOPOWNER = PostData('Restaurant/cancelManager'),   -- 取消代理代理店长
    RESTAURANT_APPLY_SUIT             = PostData('Restaurant/applyCustomSuit'), -- 餐厅设置自定义套装
    RESTAURANT_SAVE_SUIT              = PostData('Restaurant/saveCustomSuit'),  -- 餐厅保存自定义套装

    -------------------------------------------------
    CARD_VIGOUR_DIAMOND_RECOVER = PostData('card/vigourDiamondRecover'),

    BUSINESS_ORDER = PostData("Business/order") ,             -- 探索和订单同意
    DELIVERY_ONE_KEY_DRAW           = PostData('Takeaway/drawAll'),             -- 一键领取外卖奖励

    TASK_ACHIEVE_LEVEL_UP = PostData("task/achieveLevelUp") ,        --(成就等级升级)

    -------------------------------------------------
    -- 飞艇
    AIRSHIP_HOME            = PostData('airship/home'),           -- 飞艇首页
    AIRSHIP_PACK            = PostData('airship/pack'),           -- 飞艇装箱
    AIRSHIP_LADE            = PostData('airship/lade'),           -- 飞艇装船
    AIRSHIP_ACCELERATE_LADE = PostData('airship/accelerateLade'), -- 飞艇加速

    -------------------------------------------------
    -- 个人主页
    PRESENT_CODE                   = PostData('player/presentCode'),               -- 兑换码
    CHANGE_PLAYER_SIGN             = PostData('player/changeSign'),                -- 修改签名
    CHANGE_PLAYER_NAME             = PostData('player/changeName'),                -- 修改姓名
    PLAYER_GET_LOCK_VERIFICATION   = PostData('player/getLockVerificationCode'),   -- 获取手机号绑定验证码
    PLAYER_GET_UNLOCK_VERIFICATION = PostData('player/getUnlockVerificationCode'), -- 获取手机号解绑验证码
    PLAYER_LOCK_PHONE              = PostData('player/lockPhone'),                 -- 手机绑定号
    PLAYER_UNLOCK_PHONE            = PostData('player/unlockPhone'),               -- 手机绑定解绑
    PLAYER_ZM_BIND_ACCOUNT         = PostData('player/zmBindAccount'),             -- 智明账户绑定
    PLAYER_ACTIVITY_TRIGGERCHEST   = PostData('player/buyTriggerChest'),           -- 限时礼包的购买
    PLAYER_CLIENT_DATA             = PostData('player/clientData'),                -- 客户端数据

    PLAYER_PERSON_INFO             = PostData('Personal/playerPersonal'),          -- 手机绑定解绑
    PLAYER_PERSON_INFO_MESSAGE             = PostData('Personal/playerPersonal/Message'),          -- 手机绑定解绑
    PERSON_LEAVE_MESSAGE           = PostData('Personal/leaveMessage'),            -- 留言
    PERSON_DELETE_MESSAGE          = PostData('Personal/delMessage'),              --删除留言
    PERSON_CHANGE_HOUSE_CARD       = PostData('Personal/changeHouseCard'),         -- 更换飨灵
    PERSON_CHANGE_TROPHY           = PostData('Personal/changeTrophy'),            -- 更换奖杯
    PERSON_CHANGE_AVATAR           = PostData('Personal/changeAvatar'),            -- 更换更换头像框
    PERSON_CHANGE_AVATAR_FRAME     = PostData('Personal/changeAvatarFrame'),       -- 更换更换头像框
    PERSON_THUMBUP                 = PostData('Personal/thumbUp'),                 -- 点赞
    PERSON_BIRTHDAY                = PostData('Personal/birthday'),                -- 设置生日

    GIFT_ADDRESS                   = PostData('other/address'),                    -- 礼包保存收货信息
    GOODS_ADDRESS                  = PostData('other/goodsAddress'),               -- 道具保存信息

    -- 日本相关
    JAPAN_LOGIN                    = PostData('user/jpLogin'),                     -- 日本账号登录
    JAPAN_REGISTER                 = PostData('user/jpRegister'),                  -- 日本账号注册
    JAPAN_CHANGE_PASSWORD          = PostData('user/jpChangePassword'),            -- 日本账号修改密码
    JAPAN_AGE_COMMIT               = PostData('user/jpAge'),                       -- 日本设置年龄
    Japan_Forget_Code              = PostData('user/jpForgetPasswordCode'),        -- 日本忘记密码发送验证码
    Japan_Forget_Verify            = PostData('user/jpForgetPasswordVerify'),      -- 日本忘记密码验证
    Japan_Forget_Commit            = PostData('user/jpForgetPasswordCommit'),      -- 日本忘记密码提交
    Japan_Init                     = PostData('user/jpInit'),                      -- 日本账号初始化


    -------------------------------------------------
    -- 飨灵
    ALTER_CARD_NICKNAME            = PostData('card/changeCardName'),              -- 修改卡牌名称
    -- 飨灵皮肤
    CARD_SKIN_COLLECT_COMPLETED_TASK = PostData('cardCollection/cardSkinRewards'),     -- 已领取的皮肤收集奖励
    CARD_SKIN_COLLECT_DRAW_TASK      = PostData('cardCollection/drawCardSkinRewards'), -- 领取皮肤收集奖励

    -------------------------------------------------
    -- 推广员
    RECOMMEN_HOME            = PostData("Recommend/home"),                       -- 推广员数据)
    RECOMMEN_GETPRESENT      = PostData("Recommend/getRecommendPresent"),        -- 补单发送奖励
    -- PRESENT_CODE             = PostData("player/presentCode"),                  -- 礼包兑换码

    -------------------------------------------------
    -- 料理副本的接口请求
    MATERIAL_QUEST_HOME             = PostData("materialQuest/home"),           -- 进入材料副本的首页
    MATERIAL_QUEST_SET_QUEST_CONFIG = PostData("materialQuest/setQuestConfig"), -- 设置阵容与天赋
    -- MATERIAL_QUEST_SET_QUEST_CONFIG = PostData("materialQuest/test"),           -- 设置阵容与天赋

    --------------------------------季活的接口--------------------------------------------------
    SEASON_ACTIVITY_HOME                    = PostData("seasonActivity/home"),                -- 季活首页
    SEASON_ACTIVITY_RECEIVESCOER_REWARD     = PostData("seasonActivity/receiveScoreReward"),  -- 领取积分奖励
    SEASON_ACTIVITY_GET_QUEST_CONFIG        = PostData("seasonActivity/getQuestConfig"),      -- 获取关卡的配置
    SEASON_ACTIVITY_SET_QUEST_CONFIG        = PostData("seasonActivity/setQuestConfig"),      -- 设置关卡的配置
    SEASON_ACTIVITY_LOTTERY_HOME            = PostData("seasonActivity/lotteryHome"),         -- 抽奖界面的首页
    SEASON_ACTIVITY_LOTTERY                 = PostData("seasonActivity/lottery"),             -- 抽奖
    SEASON_ACTIVITY_RESET_REWARD_POOL       = PostData("seasonActivity/resetRewardPool"),     -- 抽奖池
    SEASON_ACTIVITY_RECEIVE_TICKET          = PostData("seasonActivity/receiveTicket"),       -- 领取门票

    -------------------------工会----------------------------
    UNION_HOME                      = PostData("Union/home"),                   -- 工会主页
    UNION_CREATE                    = PostData("Union/create"),                 -- 创建工会
    UNION_CHANGEINFO                = PostData("Union/changeInfo"),             -- 修改工会信息
    UNION_CHANGE_AVATAR             = PostData("Union/changeAvatar"),           -- 修改大厅形象
    UNION_SEARCH                    = PostData("Union/search"),                 -- 查找工会
    UNION_APPLY                     = PostData("Union/apply"),                  -- 申请加入工会
    UNION_APPLYAGREE                = PostData("Union/applyAgree"),             -- 申请加入工会同意
    UNION_APPLYREJECT               = PostData("Union/applyReject"),            -- 申请加入工会拒绝
    UNION_BUILD                     = PostData("Union/build"),                  -- 工会捐献
    UNION_BUILDLOG                  = PostData("Union/buildLog"),               -- 工会捐献日志
    UNION_TASK                      = PostData("Union/task"),                   -- 工会任务
    UNION_DRAWTASK                  = PostData("Union/drawTask"),               -- 工会任务领取 (废弃待移除)
    UNION_DRAW_CONTRIBUTION_POINT   = PostData("Union/drawContributionPoint"),  -- 工会任务领取贡献度奖励
    UNION_MEMBER                    = PostData("Union/member"),                 -- 工会人员列表
    UNION_APPLYLIST                 = PostData("Union/applyList"),              -- 工会申请列表
    UNION_MALL                      = PostData("Union/mall"),                   -- 工会商城
    UNION_MALL_BUY                  = PostData("Union/mallBuy"),                -- 工会商城购买
    UNION_MALL_BUY_MULTI            = PostData("Union/mallBuyMulti"),           -- 工会商城一键购买
    UNION_MALL_REFRESH              = PostData("Union/mallRefresh"),            -- 工会商城刷新
    UNION_ASSIGNJOB                 = PostData("Union/assignJob"),              -- 任命职位
    UNION_QUIT                      = PostData("Union/quit"),                   -- 退会
    UNION_QUIT_HOME                 = PostData("Union/quitHome"),               -- 离开大厅
    UNION_APPLYCLEAR                = PostData("Union/applyClear"),             -- 清除申请
    UNION_KICKOUT                   = PostData("Union/kickOut"),                -- 工会T人
    UNION_RANK                      = PostData("Union/rank"),                   -- 工会内排行榜
    UNION_SWITCH_ROOM               = PostData('Union/switchRoom'),             -- 切换房间
    UNION_HUNTING                   = PostData('Union/hunting'),                -- 工会狩猎活动
    UNION_HUNTING_ACCELERATE        = PostData('Union/huntingAccelerate'),      -- 狩猎加速恢复
    UNION_PET                       = PostData('Union/pet'),                    -- 工会堕神
    UNION_FEEDPET                   = PostData('Union/feedPet'),                -- 工会喂养堕神
    UNION_FEEDPETLOG                = PostData('Union/feedPetLog'),             -- 工会喂养堕神日志
    UNION_PARTY                     = PostData('Union/party'),                  -- 工会派对 获取状态
    UNION_PARTY_SUBMIT_FOOD         = PostData('Union/partySubmitFood'),        -- 工会派对 提交菜品
    UNION_PARTY_SUBMIT_FOOD_DIAMOND = PostData('Union/partySubmitFoodDiamond'), -- 工会派对 幻晶石提交菜品
    UNION_PARTY_SUBMIT_FOOD_ENTER   = PostData('Union/partySubmitFoodEnter'),   -- 工会派对 提菜界面进入
    UNION_PARTY_SUBMIT_FOOD_CLOSE   = PostData('Union/partySubmitFoodClose'),   -- 工会派对 提菜界面关闭
    UNION_PARTY_CHOP                = PostData('Union/partyChop'),              -- 工会派对 进行状态
    UNION_PARTY_DROP_FOOD_AT        = PostData('Union/partyChopFoodAt'),        -- 工会派对 掉菜请求
    UNION_PARTY_DROP_FOOD_GRADE     = PostData('Union/partyChopFoodGrade'),     -- 工会派对 掉菜结算
    UNION_PARTY_BOSS_QUEST_RESULT   = PostData('Union/partyChopQuestResult'),   -- 工会派对 堕神战果
    UNION_PARTY_CHOP_ROLL_HOME      = PostData('Union/partyChopRollHome'),      -- 工会派对 ROLL首页
    UNION_PARTY_CHOP_ROLL_AT        = PostData('Union/partyChopRoll'),          -- 工会派对 ROLL奖励
    UNION_PARTY_CHOP_ROLL_RESULT    = PostData('Union/partyChopRollResult'),    -- 工会派对 ROLL的奖励排名
    UNION_PARTY_SUBMIT_FOOD_LOG     = PostData('Union/partySubmitFoodLog'),     -- 工会派对 备菜日志

    -- 工会战
    UNION_WARS_HOME                   = PostData('Union/warsHome'),                -- 工会战首页
    UNION_WARS_HOME_SYNC              = PostData('Union/warsHome/appMediator'),    -- 工会战首页 同步
    UNION_WARS_UNION_MAP              = PostData('Union/warsUnionMap'),            -- 工会战公会地图
    UNION_WARS_ENEMY_MAP              = PostData('Union/warsEnemyMap'),            -- 工会战敌方地图
    UNION_WARS_DEFEND_TEAM            = PostData('Union/setWarsDefendTeam'),       -- 设置工会战防御队伍
    UNION_WARS_APPLY_MEMBERS          = PostData('Union/warsApplyMembers'),        -- 查看工会战报名成员
    UNION_WARS_APPLY_WARS             = PostData('Union/applyWars'),               -- 报名工会战 (广播7017)
    UNION_WARS_REPORT                 = PostData('Union/warsReport'),              -- 工会战战报
    UNION_WARS_MALL                   = PostData('Union/warsMall'),                -- 工会战商城 (格式和 Union/mall 一样)
    UNION_WARS_MALL_BUY               = PostData('Union/warsMallBuy'),             -- 工会战商城 (格式和 Union/mallBuy 一样)
    UNION_WARS_MALL_BUY_MULTI         = PostData('Union/warsMallBuyMulti'),        -- 工会战商城 (格式和 Union/mallBuyMulti 一样)
    UNION_WARS_MALL_REFRESH           = PostData('Union/warsMallRefresh'),         -- 工会战商城 (格式和 Union/mallRefresh 一样)
    UNION_WARS_ENEMY_QUEST_AT         = PostData('Union/warsEnemyQuestAt'),        -- 工会战攻击敌人 (发送 7018、7019)
    UNION_WARS_ENEMY_QUEST_GRADE      = PostData('Union/warsEnemyQuestGrade'),     -- 工会战攻击敌人结算 (发送 7020、7021)
    UNION_WARS_BOSS_QUEST_AT          = PostData('Union/warsBossQuestAt'),         -- 工会战攻击boss
    UNION_WARS_BOSS_QUEST_GRADE       = PostData('Union/warsBossQuestGrade'),      -- 工会战攻击boss结算
    UNION_WARS_WIN_BUILD_GET_CURRENCY = PostData('Union/warsWinBuildGetCurrency'), -- 获取据点胜利可得的货币数量

    UNION_IMPEACHMENT                = PostData('Union/impeachment'),           -- (工会弹劾)

    --------------------------------------认证--------------------------
    USER_QUERY_ACCOUNT_REAL_AUTH =  PostData('user/queryAccountRealAuth'), -- 查询账号是否是实名认证
    USER_ACCOUNT_BIND_REAL_AUTH  =  PostData('user/accountBindRealAuth'),  -- 进行实名认证

    ------------------------facebook分享----------------------------
    FACEBOOK_REWARD_HOME      = PostData('Recommend/inviteRewardList'), --facebook奖励列表
    FACEBOOK_INVITE_FRIENDS   = PostData('Recommend/invitingFaceBookFriends'), --facebook奖励列表
    FACEBOOK_DRAW_REWARDS     = PostData('Recommend/drawInviteRewards'), --facebook奖励列表
    USER_ACCOUNT_BIND_REAL_AUTH  =  PostData('user/accountBindRealAuth'),           -- 进行实名认证

    ------------------------验证码-----------------------------
    CAPTCHA_HOME              =  PostData('player/captcha'),
    CAPTCHA_ANSWER            =  PostData('player/captchaAnswer'),
    ACCOUNT_BIND              = PostData("user/bind"),
    ACCOUNT_UNBIND              = PostData("user/unbind"),
    ELEX_USER_BY_UDID              = PostData("user/zmGetUserByUdid"),
    ELEX_USER_CHANNEL_LOGIN              = PostData("user/zmChannelLogin"),
    
    ------------------------韩服迁移-----------------------------
    TRANSFER_VERIFY_EMAIL = PostData('player/verifyEmail'),
    TRANSFER_TO_EMAIL     = PostData('player/emailTransferCode'),
    TRANSFER_GET_CODE     = PostData('player/transferCode'),

    ------------------------品鉴-----------------------------
    CUISINE_HOME                 = PostData("Cuisine/home"),               --- 料理本主页
    CUISINE_GETCUISINEDATA       = PostData("Cuisine/getCuisineData"),     --- 获取对应菜系数据
    CUISINE_ASSISTANTSWITCH      = PostData("Cuisine/assistantSwitch"),    --- 上菜助手切换
    CUISINE_GRADE                = PostData("Cuisine/grade"),              --- 评分
    CUISINE_DRAWGROUPREWARD      = PostData("Cuisine/drawGroupReward"),    --- 领取阶段星级奖励
    CUISINE_DRAWTOTALREWARD      = PostData("Cuisine/drawTotalReward"),    --- 领取总星级奖励
    CUISINE_QUESTSECRET          = PostData("Cuisine/questSecret"),        --- 关卡秘籍
    CUISINE_ACCELERATERATER      = PostData("Cuisine/accelerateRater"),    --- 加速评委cd
    CUISINE_GET_GROUP_REWARDS    = PostData("Cuisine/getGroupRewards"),    --- 获取阶段奖励的数据
    CUISINE_UNLOCK_CUISINE_GROUP = PostData("Cuisine/unlockCuisineGroup"), --- 解锁料理本阶段关卡

    -------------------------世界boss----------------------------
    WORLD_BOSS_HOME              = PostData('worldBossQuest/home'),          -- 世界boss home
    WORLD_BOSS_BUY_BUFF          = PostData('worldBossQuest/buyBuff'),       -- 世界boss 购买buff
    WORLD_BOSS_DAMAGE_HISTORY    = PostData('worldBossQuest/damageHistory'), -- 世界boss 伤害历史
    WORLD_BOSS_DAMAGE_MANUAL     = PostData('worldBossQuest/manual'),        -- 世界boss 手册
    WORLD_BOSS_DAMAGE_TESTREWARD = PostData('worldBossQuest/testReward'),    -- 世界boss 试炼奖励

    -------------------------堕神熔炼----------------------------------------
    PET_FUSION = PostData('pet/fusion'),       -- 熔炼
    PET_EVOLUTION = PostData('pet/evolution'), -- 堕神异化

    -------------------------天城演武----------------------------
    TAG_MATCH_SIGN_UP          = PostData('kofArena/signUp'),              -- 天城演武 竞技场报名
    TAG_MATCH_HOME             = PostData('kofArena/home'),                -- 天城演武 竞技场首页
    TAG_MATCH_REFRESH_ENEMY    = PostData('kofArena/refreshEnemy'),        -- 天城演武 刷新对手
    TAG_MATCH_SET_ATTACK_CARDS = PostData('kofArena/setAttackCards'),      -- 天城演武 设置进攻阵容，可以只设置一个编队
    TAG_MATCH_GET_ENEMY_INFO   = PostData('kofArena/getEnemyInfo'),        -- 天城演武 获取敌人信息
    TAG_MATCH_ARENA_RECORD     = PostData('kofArena/arenaRecord'),         -- 天城演武 战报
    RANK_KOF_ARE_NARANK        = PostData('Rank/kofArenaRank'),            -- 天城演武 排行
    -------------------------------------------------------
    ARTIFACT_UNLOCK            = PostData("Artifact/unlock"), -- 神器解锁
    ARTIFACT_TALENT_LEVEL      = PostData("Artifact/talentLevel"), -- 神器天赋升级
    ARTIFACT_RESET_TALENT      = PostData("Artifact/resetTalent"), -- 重置天赋
    ARTIFACT_EQUIPGEM          = PostData("Artifact/gemstoneEquip"), -- 装备卸载宝石
    ARTIFACT_GEM_FUSION        = PostData("Artifact/gemstoneFusion"), -- 宝石融合
    ARTIFACT_GEM_LUCKY         = PostData("Artifact/gemstoneLucky"), -- 抽宝石
    ARTIFACT_GEM_LUCKY_CONSUME = PostData("Artifact/gemstoneLuckyConsume"), -- 抽宝石消耗
    ARTIFACT_SWEEP             = PostData("Artifact/sweep"),     -- 神器扫荡

    -------------------------新天城演武----------------------------
    NEW_TAG_MATCH_ACTIVITY               = PostData('newKofArena/home'),                 -- 新天城演武 入口
    NEW_TAG_MATCH_HOME                   = PostData('newKofArena/enter'),                -- 新天城演武 首页
    NEW_TAG_MATCH_REFRESH_ENEMY          = PostData('newKofArena/refreshOpponent'),      -- 新天城演武 刷新对手
    NEW_TAG_MATCH_SAVE_TEAM              = PostData('newKofArena/saveTeam'),             -- 新天城演武 保存编队
    NEW_TAG_MATCH_BUY_ATTACK_TIMES       = PostData('newKofArena/buyAttackTimes'),       -- 新天城演武 购买进攻次数
    NEW_TAG_MATCH_DRAW_CHALLENGE_REWARDS = PostData('newKofArena/drawChallengeRewards'), -- 新天城演武 领取挑战奖励
    NEW_TAG_MATCH_MALL                   = PostData('newKofArena/mall'),                 -- 新天城演武 商城首页
    NEW_TAG_MATCH_BUY                    = PostData('newKofArena/mallBuy'),              -- 新天城演武 商城购买
    NEW_TAG_MATCH_MALL_BUY_MULTI         = PostData('newKofArena/mallBuyMulti'),         -- 新天城演武 商城一键购买
    NEW_TAG_MATCH_ARENA_RECORD           = PostData('newKofArena/arenaRecord'),          -- 新天城演武 战报
    NEW_TAG_MATCH_QUEST_AT               = PostData('newKofArena/questAt'),              -- 新天城演武 进入战斗
    NEW_TAG_MATCH_QUEST_GRADE            = PostData('newKofArena/questGrade'),           -- 新天城演武 战斗结算
    NEW_RANK_KOF_ARE_NARANK              = PostData('Rank/newKofArenaRank'),             -- 新天城演武 排行


    -------------------------老玩家召回----------------------------
    RECALL_HOME                = PostData("Recall/home"),                   -- 召回主页
    RECALL_REWARD_DRAW         = PostData("Recall/recallRewardDraw"),       -- 召回奖励领取
    RECALLED_REWARD_DRAW       = PostData("Recall/veteranLoginRewardDraw"), -- 老玩家登录奖励领取
    RECALLED_TASK_DRAW         = PostData("Recall/veteranTaskDraw"),        -- 老玩家任务领取
    RECALLED_FINAL_REWARD_DRAW = PostData("Recall/veteranTaskFinalDraw"),   -- 老玩家任务最终奖励领取
    RECALLED_CHEST_BUY         = PostData("Recall/veteranChestBuy"),        -- 老玩家礼包购买
    RECALLED_COMMIT            = PostData("Recall/recalledCommit"),         -- 回归召回码
    RECALL_CODE_QUERY          = PostData("Recall/recallCodeQuery"),        -- 回归码查询玩家昵称
    -------------------------回归福利------------------------------
    BACK_HOME                       = PostData("Back/home"),                    -- 回归福利主页
    BACK_DRAW_TREASURE              = PostData("Back/drawTreasure"),            -- 回归福利鲷鱼秘宝领取
    BACK_DRAW_ACCUMULATIVE_LOGIN    = PostData("Back/drawAccumulativeLogin"),   -- 回归福利累计登陆领取
    BACK_DRAW_WEEKLY_LOGIN          = PostData("Back/drawWeeklyLogin"),         -- 回归福利每周奖励领取
    BACK_DRAW_BINGO_TASK            = PostData("Back/drawBingoTask"),           -- 回归福利bingo任务领取
    BACK_DRAW_BINGO_REWARDS         = PostData("Back/drawBingoRewards"),        -- 回归福利bingo奖励领取
    BACK_REFRESH_BINGO_POSITION     = PostData("Back/refreshBingoPosition"),    -- 回归福利bingo连线刷新
    -------------------------探索----------------------------
    EXPLORE_SYSTEM_HOME             = PostData('ExploreSystem/home'),            -- 探索主页
    EXPLORE_SYSTEM_QUEST_START      = PostData('ExploreSystem/questStart'),      -- 探索开始
    EXPLORE_SYSTEM_QUEST_RETREAT    = PostData('ExploreSystem/questRetreat'),    -- 探索撤退
    EXPLORE_SYSTEM_QUEST_COMPLETE   = PostData('ExploreSystem/questComplete'),   -- 探索完成领取奖励
    EXPLORE_SYSTEM_QUEST_ACCELERATE = PostData('ExploreSystem/questAccelerate'), -- 探索加速
    -------------------------夏活----------------------------
    SUMMER_ACTIVITY_HOME             = PostData('summerActivity/home'),            -- 夏活主页
    SUMMER_ACTIVITY_CHAPTER          = PostData('summerActivity/chapter'),         -- 章节
    SUMMER_ACTIVITY_CHAPTER_HOME     = PostData('summerActivity/chapterHome'),     -- 章节主页
    SUMMER_ACTIVITY_OPEN_NODE        = PostData('summerActivity/openNode'),        -- 打开节点
    SUMMER_ACTIVITY_SEARCH_NODE      = PostData('summerActivity/searchNode'),      -- 寻找boss节点
    SUMMER_ACTIVITY_ADDITION         = PostData('summerActivity/addition'),        -- 加成信息
    SUMMER_ACTIVITY_STORY            = PostData('summerActivity/story'),           -- 剧情回顾
    SUMMER_ACTIVITY_STORY_UNLOCK     = PostData('summerActivity/storyUnlock'),     -- 剧情解锁
    SUMMER_ACTIVITY_BUY_ACTION_POINT = PostData('summerActivity/buyActionPoint'),  -- 购买行动力
    SUMMER_ACTIVITY_QUEST_REWARD_DRAW = PostData('summerActivity/drawQuestOverTimeReward'),  -- 领取关卡超得奖励
    SUMMER_ACTIVITY_DRAW_QUEST_TIMES_REWARDS = PostData('summerActivity/drawQuestTimesRewards'),  -- 领取关卡次数奖励

    -------------------------扫一扫--------------------------
    FRIEND_QRCODE                   = PostData('friend/refreshFriendQrCode'),        -- 刷新添加好友的二维码
    FRIEND_QRCODE_SCAN              = PostData('friend/scanQrCodeAddFriend'),        -- 扫二维码后请求添加好友
    FRIEND_QRCODE_LOG               = PostData('friend/qrCodeFriendLog'),            -- 二维码添加好友的日志

    ---------------------杀人案（19夏活）----------------------
    MURDER_HOME                      = PostData('newSummerActivity/home'),                      -- 杀人案主页
    MURDER_DRAW_MAIL_REWARDS         = PostData('newSummerActivity/drawMailRewards'),           -- 领取初始信件
    MURDER_UPGRADE                   = PostData('newSummerActivity/upgrade'),                   -- 提升时钟等级
    MURDER_RECEIVE_BOSS_REWARDS      = PostData('newSummerActivity/receiveBossRewards'),        -- 领取boss奖励
    MURDER_CLOCK_REWARDS             = PostData('newSummerActivity/drawClockOverTimesRewards'), -- 时钟奖励
    MURDER_MALL_BUY                  = PostData('newSummerActivity/mallBuy'),                   -- 商店购买
    MURDER_BUY_HP                    = PostData('newSummerActivity/buyHp'),                     -- 购买活动体力
    MURDER_DRAW_DAMAGE_POINT_REWARDS = PostData('newSummerActivity/drawDamagePointRewards'),    -- 领取伤害积分奖励
    MURDER_LOTTERY                   = PostData('newSummerActivity/lottery'),                   -- 抽奖
    MURDER_LOTTERY_HOME              = PostData('newSummerActivity/lotteryHome'),               -- 抽奖home
    MURDER_RANK                      = PostData('newSummerActivity/rank'),                      -- 排行榜
    MURDER_SWEEP                     = PostData('newSummerActivity/sweep'),                     -- 扫荡
    MURDER_STORY_UNLOCK              = PostData('newSummerActivity/storyUnlock'),               -- 解锁剧情
    MURDER_DRAW_PUZZLE_REWARDS       = PostData('newSummerActivity/drawPuzzleRewards'),         -- 领取解密奖励
    --------------------- 皮肤嘉年华 ----------------------
    SKIN_CARNIVAL_HOME                  = PostData('SkinCarnival/home'),               -- 皮肤嘉年华home
    SKIN_CARNIVAL_DRAW_COLLECT          = PostData('SkinCarnival/drawCollect'),        -- 皮肤嘉年华领取收集奖励
    SKIN_CARNIVAL_FLASH_SALE            = PostData('SkinCarnival/flashSale'),          -- 皮肤嘉年华秒杀类型
    SKIN_CARNIVAL_FLASH_SALE_RUSH       = PostData('SkinCarnival/flashSaleRush'),      -- 皮肤嘉年华秒杀抢购
    SKIN_CARNIVAL_FLASH_SALE_BUY        = PostData('SkinCarnival/flashSaleBuy'),       -- 皮肤嘉年华秒杀购买
    SKIN_CARNIVAL_FLASH_SALE_DRAW       = PostData('SkinCarnival/drawFlashSaleOptionReward'), -- 皮肤嘉年华秒杀二选一奖励
    SKIN_CARNIVAL_TASK                  = PostData('SkinCarnival/task'),               -- 皮肤嘉年华任务类型
    SKIN_CARNIVAL_TASK_REWARD_DRAW      = PostData('SkinCarnival/drawTaskReward'),     -- 皮肤嘉年华任务奖励领取
    SKIN_CARNIVAL_LOTTERY               = PostData('SkinCarnival/lottery'),            -- 皮肤嘉年华抽奖类型
    SKIN_CARNIVAL_LOTTERY_GRAB          = PostData('SkinCarnival/lotteryGrab'),        -- 皮肤嘉年华抽奖
    SKIN_CARNIVAL_LOTTERY_REWARD_DRAW   = PostData('SkinCarnival/drawLotteryReward'),  -- 皮肤嘉年华抽奖奖励领取
    SKIN_CARNIVAL_CHALLENGE             = PostData('SkinCarnival/challenge'),          -- 皮肤嘉年华挑战类型
    SKIN_CARNIVAL_CHALLENGE_REWARD_DRAW = PostData('SkinCarnival/drawChallengeReward'),-- 皮肤嘉年华挑战奖励领取

    ------------------------- 钓鱼 ----------------------------
    FISHPLACE_HOME                  = PostData('fishPlace/home'),                   -- (查看钓场)
    FISHPLACE_SETFISHING_CARD       = PostData('fishPlace/setFishingCard'),         -- （设置钓鱼队伍）
    FISHPLACE_SETFISHING_BAIT       = PostData('fishPlace/setFishingBait'),         -- (领取钓鱼奖励)
    FISHPLACE_DRAW_FISHINGR_EWARDS  = PostData('fishPlace/drawFishingRewards'),     -- (领取钓鱼奖励)
    FISHPLACE_QUERY_FISHINGR_EWARDS = PostData('fishPlace/queryFishingRewards'),    -- (查看钓鱼奖励)
    FISHPLACE_SET_FRIEND_FISH       = PostData('fishPlace/setFriendFish'),          -- 在好友钓场添加钓鱼卡牌
    FISHPLACE_KICK_FRIEND_FISH_CARD = PostData('fishPlace/kickFriendFishCard'),     -- 踢走好友在钓场添加的卡牌
    FISHPLACE_PRAY                  = PostData('fishPlace/pray'),                   -- 祈愿（购买钓场buff）
    FISHPLACE_LEVEL_UP              = PostData('fishPlace/levelUp'),                -- 钓场升级
    FISHPLACE_MALL_BUY              = PostData('fishPlace/mallBuy'),                -- 渔场商城购买
    FISHPLACE_CLEAR_BAIT            = PostData('fishPlace/clearBait'),              -- 渔场清除钓饵
    FISHPLACE_SYN_DATA              = PostData('fishPlace/queryFishCards'),         -- 同步钓场卡牌和钓饵的数据
    FISHPLACE_FRIENDS_FISH_LOG      = PostData('fishPlace/friendsFishLog'),         -- 同步钓场卡牌和钓饵的数据
    FISHPLACE_CALLBACK              = PostData('fishPlace/callBack'),               -- 好友钓场召回

    --------------------------- 包厢 ------------------------------
    PRIVATE_ROOM_HOME                    = PostData('PrivateRoom/home'),                 -- 包厢主页
    PRIVATE_ROOM_GUEST_ARRIVAL           = PostData('PrivateRoom/guestArrival'),         -- 客人到达
    PRIVATE_ROOM_GUEST_SERVE             = PostData('PrivateRoom/guestServe'),           -- 客人招待
    PRIVATE_ROOM_GUEST_CANCEL            = PostData('PrivateRoom/guestCancel'),          -- 客人放弃招待
    PRIVATE_ROOM_ASSISSTANT_SWITCH       = PostData('PrivateRoom/assistantSwitch'),      -- 更换服务员
    PRIVATE_ROOM_THEME_SWITCH            = PostData('PrivateRoom/themeSwitch'),          -- 更换主题
    PRIVATE_ROOM_GUESTS                  = PostData('PrivateRoom/guests'),               -- 贵宾列表
    PRIVATE_ROOM_THEME                   = PostData('PrivateRoom/theme'),                -- 主题列表
    PRIVATE_ROOM_THEME_BUY               = PostData('PrivateRoom/themeBuy'),             -- 购买主题
    PRIVATE_ROOM_DECORATION_SWITCH       = PostData('PrivateRoom/wallDecorationSwitch'), -- 更换墙面装饰
    PRIVATE_ROOM_SERVE_TIMES_BUY         = PostData('PrivateRoom/serveTimesBuy'),        -- 招待次数购买
    PRIVATE_ROOM_GUEST_DIALOGUE_DRAW     = PostData('PrivateRoom/guestDialogueDraw'),    -- 客人逸闻奖励领取

    --------------------------- 水吧 ------------------------------
    WATER_BAR_HOME           = PostData('Bar/home'),                       -- 酒吧主页
    WATER_BAR_MARKET_HOME    = PostData('Bar/market'),                     -- 酒吧市场 主页
    WATER_BAR_MARKET_BUY     = PostData('Bar/marketBuy'),                  -- 酒吧市场 购买
    WATER_BAR_MARKET_REFRESH = PostData('Bar/marketRefresh'),              -- 酒吧市场 刷新
    WATER_BAR_CUSTOMER_DRAW  = PostData('Bar/drawCustomerFrequencyPoint'), -- 酒吧熟客 领取奖励
    WATER_BAR_BARTEND        = PostData('Bar/bartend'),                    -- 酒吧调酒
    WATER_BAR_MAKE           = PostData('Bar/make'),                       -- 酒吧做酒
    WATER_BAR_FORMULA        = PostData('Bar/formula'),                    -- 酒吧配方
    WATER_BAR_LEVELUP        = PostData('Bar/levelUp'),                    -- 酒吧升级
    WATER_BAR_FORMULA_LIKE   = PostData('Bar/formulaLike'),                -- 酒吧配方 喜爱/不喜爱
    WATER_BAR_SHELF_ON       = PostData('Bar/onShelfDrink'),               -- 酒吧上架饮品
    WATER_BAR_SHELF_OFF      = PostData('Bar/offShelfDrink'),              -- 酒吧下架饮品
    WATER_BAR_SHOP_HOME      = PostData('Bar/mall'),                       -- 酒吧商店 主页
    WATER_BAR_SHOP_BUY       = PostData('Bar/mallBuy'),                    -- 酒吧商店 购买
    WATER_BAR_SHOP_MULTI_BUY = PostData('Bar/mallBuyMulti'),               -- 酒吧商店 批量购买
    WATER_BAR_CUSTOMER_STORY = PostData('Bar/customerUnlockStoryList'),    -- 酒吧客人 解锁的故事

    --------------------------- 燃战 ------------------------------
    SAIMOE_HOME                     = PostData('comparisonActivity/home'),                   -- (查看比拼数据)
    SAIMOE_SUPPORT                  = PostData('comparisonActivity/support'),                -- (选择支持飨灵)
    SAIMOE_DONATION                 = PostData('comparisonActivity/donation'),               -- (捐赠数据)
    SAIMOE_GAMBLE                   = PostData('comparisonActivity/gamble'),                 -- (比拼投注)
    SAIMOE_DRAW_POINT_REWARD        = PostData('comparisonActivity/drawPointRewards'),       -- (领取点数奖励)
    SAIMOE_BOSS_MAP                 = PostData('comparisonActivity/bossMap'),                -- (boss拼图)
    SAIMOE_SHOPPING                 = PostData('comparisonActivity/shopping'),               -- (黑店商城购买)
    SAIMOE_CLOSE_SHOP               = PostData('comparisonActivity/closeShop'),              -- (关闭黑店)
    SAIMOE_SWEEP                    = PostData('comparisonActivity/sweep'),                  -- (扫荡)
    SAIMOE_BUY_HP                   = PostData('comparisonActivity/buyHp'),                  -- (购买应援力)
    SAIMOE_SET_BOSS_TEAM            = PostData('comparisonActivity/setBossTeam'),            -- (设置boss战斗队伍)

    --------------------------- 抽卡 ------------------------------
    GAMBLING_ENTER                   = PostData('Gambling/enter'),                         -- 进入基础抽卡
    GAMBLING_LUCKY                   = PostData('Gambling/lucky'),                         -- 开始基础抽卡
    GAMBLING_HOME                    = PostData('Gambling/home'),                          -- 新抽卡入口
    GAMBLING_TEN_ENTER               = PostData('Gambling/tenTimes'),                      -- 进入10连抽卡
    GAMBLING_TEN_LUCKY               = PostData('Gambling/tenTimesLucky'),                 -- 开始10连抽卡
    GAMBLING_TEN_STEP_DRAW           = PostData('Gambling/tenTimesDrawStep'),              -- 领取10连抽卡 阶段奖励
    GAMBLING_SUPER_ENTER             = PostData('Gambling/super'),                         -- 进入超得抽卡
    GAMBLING_SUPER_LUCKY             = PostData('Gambling/superLucky'),                    -- 开始超得抽卡
    GAMBLING_SQUARE_ENTER            = PostData('Gambling/squared'),                       -- 进入九宫抽卡
    GAMBLING_SQUARE_LUCKY            = PostData('Gambling/squaredLucky'),                  -- 开始九宫抽卡
    GAMBLING_SQUARE_ROUND_NEXT       = PostData('Gambling/squaredNextRound'),              -- 刷新九宫抽卡 下一轮
    GAMBLING_NEWBIE_ENTER            = PostData('Gambling/newbie'),                        -- 进入新手抽卡
    GAMBLING_NEWBIE_LUCKY            = PostData('Gambling/newbieLucky'),                   -- 开始新手抽卡
    GAMBLING_NEWBIE_FINAL_DRAW       = PostData('Gambling/newbieFinalDraw'),               -- 领取新手抽卡 最终奖励
    GAMBLING_EXTRA_DROP_ENTER        = PostData('Gambling/extraDrop'),                     -- 进出10连送道具抽卡
    GAMBLING_EXTRA_DROP_LUCKY        = PostData('Gambling/extraDropLucky'),                -- 开始10连送道具抽卡
    GAMBLING_LIMIT_ENTER             = PostData('Gambling/limit'),                         -- 进入限购抽卡
    GAMBLING_LIMIT_LUCKY             = PostData('Gambling/limitLucky'),                    -- 开始限购抽卡
    GAMBLING_SKIN_ENTER              = PostData('Gambling/cardSkin'),                      -- 皮肤卡池入口
    GAMBLING_SKIN_CHOOSE             = PostData('Gambling/cardSkinChoose'),                -- 皮肤卡池选择
    GAMBLING_SKIN_DRAW               = PostData('Gambling/cardSkinLucky'),                 -- 皮肤卡池抽卡
    GAMBLING_SKIN_MALL               = PostData('Gambling/cardSkinMall'),                  -- 皮肤抽卡商城
    GAMBLING_SKIN_MALL_BUY           = PostData('Gambling/cardSkinMallBuy'),               -- 皮肤抽卡商城购买
    GAMBLING_CARD_CHOOSE             = PostData('Gambling/cardChoose'),                    -- 选卡卡池
    GAMBLING_CARD_CHOOSE_ENTER       = PostData('Gambling/cardChooseEnter'),               -- 选卡卡池选择
    GAMBLING_CARD_CHOOSE_LUCKY       = PostData('Gambling/cardChooseLucky'),               -- 选卡卡池抽卡
    GAMBLING_CARD_CHOOSE_QUIT        = PostData('Gambling/cardChooseQuit'),                -- 选卡卡池退出
    GAMBLING_SETP                    = PostData('Gambling/step'),                          -- 多段式卡池
    GAMBLING_SETP_LUCKY              = PostData('Gambling/stepLucky'),                     -- 多段式卡池抽卡
    GAMBLING_LUCKY_BAG_HOME          = PostData('Gambling/fukubukuro'),                    -- 福袋卡池入口
    GAMBLING_LUCKY_BAG_LUCKY         = PostData('Gambling/fukubukuroLucky'),               -- 福袋卡池抽卡
    GAMBLING_LUCKY_BAG_PREVIEW       = PostData('Gambling/fukubukuroLuckyPreview'),        -- 福袋抽卡结果
    GAMBLING_LUCKY_BAG_REFRESH       = PostData('Gambling/fukubukuroLuckyReplaceRefresh'), -- 福袋卡池抽卡替换刷新
    GAMBLING_LUCKY_BAG_CHOOSE        = PostData('Gambling/fukubukuroLuckyReplaceChoose'),  -- 福袋卡池抽卡替换选择
    GAMBLING_RANDOM_POOL_ENTER       = PostData('Gambling/randBuff'),                      -- 铸池抽卡入口
    GAMBLING_RANDOM_POOL_REFRESH     = PostData('Gambling/randBuffRefresh'),               -- 铸池抽卡卡池刷新
    GAMBLING_RANDOM_POOL_LUCKY       = PostData('Gambling/randBuffLucky'),                 -- 铸池抽卡抽卡
    GAMBLING_RANDOM_POOL_RESET       = PostData('Gambling/randBuffReset'),                 -- 铸池抽卡重置
    GAMBLING_PROBABILITY_UP          = PostData('Gambling/probabilityUp'),                 -- 概率提升
    GAMBLING_PROBABILITY_UP_LUCKY    = PostData('Gambling/probabilityUpLucky'),            -- 概率提升抽卡
    GAMBLING_PROBABILITY_UP_EXCHANGE = PostData('Gambling/probabilityUpExchange'),         -- 概率提升兑换
    GAMBLING_BINARY_CHOICE_HOME      = PostData('Gambling/doubleChoose'),                  -- 双抉卡池
    GAMBLING_BINARY_CHOICE_ENTER     = PostData('Gambling/doubleChooseEnter'),             -- 双抉卡池选择卡
    GAMBLING_BINARY_CHOICE_LUCKY     = PostData('Gambling/doubleChooseLucky'),             -- 双抉卡池选抽卡
    GAMBLING_BINARY_CHOICE_DRAW      = PostData('Gambling/doubleChooseDraw'),              -- 双抉卡池领奖
    GAMBLING_BINARY_CHOICE_RESET     = PostData('Gambling/doubleChooseReset'),             -- 双抉卡池重置
    GAMBLING_BASE_CARDSKIN_LUCKY     = PostData('Gambling/baseCardSkinLucky'),             -- 常驻皮肤卡池抽卡
    GAMBLING_BASE_CARDSKIN_MALL      = PostData('Gambling/basecardSkinMall'),              -- 常驻皮肤卡池商城
    GAMBLING_BASE_CARDSKIN_MALL_BUY  = PostData('Gambling/baseCardSkinMallBuy'),           -- 常驻皮肤卡池商城购买
    GAMBLING_FREE_NEWBIE_HOME        = PostData('Gambling/freeNewbie'),                    -- 免费新手卡池 主页
    GAMBLING_FREE_NEWBIE_LUCKY       = PostData('Gambling/freeNewbieLucky'),               -- 免费新手卡池 抽卡
    GAMBLING_FREE_NEWBIE_DRAW_FINAL  = PostData('Gambling/freeNewbieFinalDraw'),           -- 免费新手卡池 最终领奖
    GAMBLING_FREE_NEWBIE_DRAW_TASK   = PostData('Gambling/freeNewbieRewards'),             -- 免费新手卡池 次数领奖


    ---------------------------周年庆接口设置------------------------------
    ANNIVERSARY_HOME                         = PostData('anniversary/home'),                         --  (入口数据)
    ANNIVERSARY_SET_CONFIG                   = PostData('anniversary/setQuestConfig'),                    -- （设置编队 && 天赋技能）
    ANNIVERSARY_MYSTERIOUS_CIRCLE            = PostData('anniversary/mysteriousCircle'),             -- （神秘套圈）
    ANNIVERSARY_MYSTERIOUS_SUPER_REWARDS     = PostData('anniversary/mysteriousSuperRewards'),       -- （神秘套圈超得奖励）
    ANNIVERSARY_BLACK_HEART_RECIPE_SHOP      = PostData('anniversary/blackHeartRecipeShop'),         -- （食谱商店）
    ANNIVERSARY_BLACK_HEART_SHOP             = PostData('anniversary/blackHeartShop'),               -- （黑市商店）
    ANNIVERSARY_RAND_STEP_NUM                = PostData('anniversary/randStepNum'),                  -- （随机前进步数）
    ANNIVERSARY_SET_SHOP_CONFIG              = PostData('anniversary/setShopConfig'),                -- （设置食谱商店）
    ANNIVERSARY_DRAW_CHALLENGE_POINT_REWARDS = PostData('anniversary/drawChallengePointRewards'),    -- （领取挑战积分奖励）
    ANNIVERSARY_DRAW_PLOT_REWARDS            = PostData('anniversary/drawPlotRewards'),              -- （领取剧情奖励）
    ANNIVERSARY_DRAW_RANK_REWARDS            = PostData('anniversary/drawRankRewards'),              -- （领取剧情奖励）
    ANNIVERSARY_GET_SHOP_CONFIG              = PostData('anniversary/getShopConfig'),                -- （获取食谱商店）
    ANNIVERSARY_RANK                         = PostData('anniversary/rank'),                         --  排行数据
    ANNIVERSARY_MY_RANK                      = PostData('anniversary/myRank'),                       --  排行数据
    ANNIVERSARY_GET_QUSET_CONFIG             = PostData('anniversary/getQusetConfig'),               -- （获取到周年庆的编队设置）
    ANNIVERSARY_SET_BRANCH_CHAPTER           = PostData('anniversary/setBranchChapter'),             -- （设置支线章节Id）
    ANNIVERSARY_SET_MAIN_CHAPTER             = PostData('anniversary/setMainChapter'),               -- （初始进入主线章节）
    ANNIVERSARY_REFRESH_BRANCH               = PostData('anniversary/refreshBranch'),                -- （刷新支线）
    ANNIVERSARY_REFRESH_BRANCH_TYPE          = PostData('anniversary/refreshBranchType'),            -- （刷新支线剧情类型）
    ANNIVERSARY_QUIT_CHAPTER                 = PostData('anniversary/quitChapter'),                  --  (放弃章节)
    ANNIVERSARY_DRAW_CHAPTER_REWARDS         = PostData('anniversary/drawChapterRewards'),           --  （领取章节奖励）
    ANNIVERSARY_GET_SHOP_LOG                 = PostData('anniversary/getShopLog'),                   --  获取shop 日志
    ANNIVERSARY_GET_RECIPE_ATTR              = PostData('anniversary/getRecipeAttr'),                --  获取推荐菜谱解锁信息
    ANNIVERSARY_DRAW_SHOP_REWARDS            = PostData('anniversary/drawShopRewards'),              --  （领取章节奖励）
    ANNIVERSARY_SWEEP_BRANCH_CHAPTER         = PostData('anniversary/sweepBranchChapter'),           --  （扫荡支线章节）
    --------------------------- 活动 ------------------------------
    ACTIVITY_LOGIN_REWARD_HOME     = PostData('Activity/loginReward'),              -- 登录礼包活动home
    ACTIVITY_LOGIN_REWARD_DRAW     = PostData('Activity/drawLoginReward'),          -- 登录礼包活动领奖
    ACTIVITY_EXCHANGE_HOME         = PostData('Activity/exchangeList'),             -- 道具兑换活动home
    ACTIVITY_WHEEL_HOME            = PostData('Activity/bigWheel'),                 -- 转盘活动home
    ACTIVITY_WHEEL_DRAW            = PostData('Activity/drawBigWheel'),             -- 转盘活动抽奖
    ACTIVITY_ACCUMULATIVE_PAY_HOME = PostData('Activity/accumulativePay'),          -- 累充活动home
    ACTIVITY_QUEST_HOME            = PostData('ActivityQuest/home'),                -- 活动副本home
    ACTIVITY_QUEST_EXCHANGE        = PostData('ActivityQuest/exchange'),            -- 活动副本兑换成功
    ACTIVITY_BINGGO_HOME           = PostData('Activity/taskBinggoList'),           -- 拼图活动home
    ACTIVITY_BINGGO_DRAW_TASK      = PostData('Activity/drawBinggoTask'),           -- 拼图活动领取任务
    ACTIVITY_BINGGO_OPEN           = PostData('Activity/binggoOpen'),               -- 拼图活动翻开拼图
    ACTIVITY_PREVIEW_HOME          = PostData('Activity/anniversaryPreviewInfo'),   -- 特殊活动预览home
    ACTIVITY_GEO_HOME              = PostData('Activity/geo'),                      -- KFC签到活动home
    ACTIVITY_GEO_DRAW              = PostData('Activity/geoDraw'),                  -- KFC签到活动领奖

    ---招财猫-----
    ACTIVITY_LUCKY_CAT = PostData('activity/luckyCat'), ---招财猫的入口
    ACTIVITY_LUCKY_CAT_DRAW = PostData('activity/drawLuckyCat'), --领取招财猫的逻辑


    --------------------------- PT副本 ------------------------------
    PT_HOME              = PostData('PT/home'),
    PT_DRAW_SECTION      = PostData('PT/drawSection'),
    PT_RANK              = PostData('PT/rank'),
    PT_BUY_HP            = PostData('PT/buyHp'),

    --------------------- 唤灵手--------------------------------
    CARD_CALL_HOME                             = PostData('CardCall/home'), -- 唤灵手册首页
    CARD_CALL_DRAW_TASK_REWARD                 = PostData('CardCall/drawTaskReward'), -- 领取任务奖励
    CARD_CALL_DRAW_ROUTE_REWARD                = PostData('CardCall/drawRouteReward'), -- 领取路线奖励
    CARD_CALL_DRAW_FINAL_REWARD                = PostData('CardCall/drawFinalReward'), -- 领取最终奖励

    ------------------------ 商城 ------------------------
    GAME_STORE_HOME    = PostData('mall/home'),         -- 游戏商城首页
    GAME_STORE_BUY     = PostData('mall/buy'),          -- 游戏商城购买
    GAME_STORE_DIAMOND = PostData('mall/home/diamond'), -- 游戏钻石首页
    MALL_BUY_MULTI     = PostData('mall/buyMulti'),     -- 商城一键购买
    MEMORY_STORE_HOME  = PostData('Card/fragmentMall'), -- 记忆商城home
    MEMORY_STORE_BUY   = PostData('Card/fragmentMallBuy'), -- 记忆商城购买
    MEMORY_STORE_BUY_MULTI = PostData('Card/fragmentMallBuyMulti'), -- 记忆商城一键购买
    MEMORY_STORE_FUSION = PostData('Card/fragmentConvert'), -- 记忆商城碎片融合

    ------------------------ 古堡迷踪 ------------------------
    SPRING_ACTIVITY_HOME                    = PostData('springActivity/home'),                  -- 春活首页
    SPRING_ACTIVITY_BATTLE_HOME             = PostData('springActivity/home'),                  -- 春活首页
    SPRING_ACTIVITY_SETQUESTCONFIG          = PostData('springActivity/setQuestConfig'),        -- 设置关卡配置
    SPRING_ACTIVITY_DRAWTICKET              = PostData('springActivity/drawTicket'),            -- 领取钥匙
    SPRING_ACTIVITY_DRAW_PLOT_POINT_REWARDS = PostData('springActivity/drawPlotPointRewards'),  -- 领取剧情奖励
    SPRING_ACTIVITY_LOTTERY                 = PostData('springActivity/lottery'),               -- 抽奖
    SPRING_ACTIVITY_RANK                    = PostData('springActivity/rank'),                  -- 排行数据
    SPRING_ACTIVITY_SWEEP                   = PostData('springActivity/sweep'),                 -- 扫荡
    SPRING_ACTIVITY_UNLOCK_STORY            = PostData('springActivity/unlockStory'),           -- 故事解锁

    -------------------------战斗短连接----------------------------
    -- 地图战斗
    QUEST_AT                            = PostData('quest/at'),
    QUEST_GRADE                         = PostData('quest/grade'),
    QUEST_PURCHASE_CHALLENGE_TIME       = PostData('quest/purchaseQuestChallengeTime'), -- 购买挑战次数
    QUEST_SWEEP                         = PostData('quest/sweep'), -- 关卡扫荡
    -- 霸王餐
    RESTAURANT_QUEST_AT                 = PostData('Restaurant/questAt'),
    RESTAURANT_QUEST_GRADE              = PostData('Restaurant/questGrade'),
    -- 帮打霸王餐
    RESTAURANT_HELP_QUEST_AT            = PostData('Restaurant/helpQuestAt'),
    RESTAURANT_HELP_QUEST_GRADE         = PostData('Restaurant/helpQuestGrade'),
    -- 主线剧情任务战斗
    PLOT_TASK_QUEST_AT                  = PostData('plotTask/questAt'),
    PLOT_TASK_QUEST_GRADE               = PostData('plotTask/questGrade'),
    -- 支线剧情任务战斗
    BRANCH_QUEST_AT                     = PostData('branch/questAt'),
    BRANCH_QUEST_GRADE                  = PostData('branch/questGrade'),
    -- 外卖打劫
    TAKEAWAY_ROBBERY_QUEST_AT           = PostData('Takeaway/robbery'),
    TAKEAWAY_ROBBERY_QUEST_GRADE        = PostData('Takeaway/robberyResult'),
    TAKEAWAY_ROBBERY_RIDICULE           = PostData('Takeaway/robberyRidicule'), -- 外卖打劫留言
    -- 探索
    EXPLORATION_QUEST_AT                = PostData('Explore/questAt'),
    EXPLORATION_QUEST_GRADE             = PostData('Explore/questGrade'),
    -- 爬塔
    TOWER_QUEST_AT                      = PostData('tower/questAt'),
    TOWER_QUEST_GRADE                   = PostData('tower/questGrade'),
    TOWER_QUEST_BUY_LIVE                = PostData('tower/buyTowerLive'),  -- 爬塔战斗买活
    -- 竞技场
    PVC_QUEST_AT                        = PostData('offlineArena/questAt'),
    PVC_QUEST_GRADE                     = PostData('offlineArena/questGrade'),
    -- 材料副本
    MATERIAL_QUEST_AT                   = PostData("materialQuest/questAt"),
    MATERIAL_QUEST_GRADE                = PostData("materialQuest/questGrade"),
    -- 季活
        -- 老的
    SEASON_ACTIVITY_QUEST_AT            = PostData("seasonActivity/questAt"),
    SEASON_ACTIVITY_QUEST_GRADE         = PostData("seasonActivity/questGrade"),
        -- 春活
    SPRING_ACTIVITY_QUEST_AT            = PostData('springActivity/questAt'),
    SPRING_ACTIVITY_QUEST_GRADE         = PostData('springActivity/questGrade'),
        -- 夏活
    SUMMER_ACTIVITY_QUESTAT             = PostData('summerActivity/questAt'),
    SUMMER_ACTIVITY_QUESTGRADE          = PostData('summerActivity/questGrade'),
    -- 周年庆
    ANNIVERSARY_QUEST_AT                = PostData('anniversary/questAt'),
    ANNIVERSARY_QUEST_GRADE             = PostData('anniversary/questGrade'),
    -- 神器
    ARTIFACT_QUESTAT                    = PostData("Artifact/questAt"),
    ARTIFACT_QUESTGRADE                 = PostData("Artifact/questGrade"),
    -- 工会狩猎神兽
    UNION_HUNTING_QUEST_AT              = PostData('Union/huntingQuestAt'),
    UNION_HUNTING_QUEST_GRADE           = PostData('Union/huntingQuestGrade'),
    UNION_HUNTING_BUY_LIVE              = PostData('Union/huntingBuyLive'), -- 工会狩猎战斗买活
    -- 工会派对打堕神
    UNION_PARTY_BOSS_QUEST_AT           = PostData('Union/partyChopQuestAt'),
    UNION_PARTY_BOSS_QUEST_GRADE        = PostData('Union/partyChopQuestGrade'),
    -- 世界boss战
    WORLD_BOSS_QUESTAT                  = PostData('worldBossQuest/questAt'),
    WORLD_BOSS_QUESTGRADE               = PostData('worldBossQuest/questGrade'),
    WORLD_BOSS_BUYLIVE                  = PostData('worldBossQuest/buyLive'), -- 世界boss 买活
    -- 活动副本
    ACTIVITY_QUEST_QUESTAT              = PostData('ActivityQuest/questAt'),
    ACTIVITY_QUEST_QUESTGRADE           = PostData('ActivityQuest/questGrade'),
    -- 天城演武
    TAG_MATCH_QUEST_AT                  = PostData('kofArena/questAt'),
    TAG_MATCH_QUEST_GRADE               = PostData('kofArena/questGrade'),
    -- 燃战
        -- 普通关卡
    SAIMOE_QUEST_AT                     = PostData('comparisonActivity/questAt'),
    SAIMOE_QUEST_GRADE                  = PostData('comparisonActivity/questGrade'),
        -- boss关卡
    SAIMOE_BOSS_QUEST_AT                = PostData('comparisonActivity/bossQuestAt'),
    SAIMOE_BOSS_QUEST_GRADE             = PostData('comparisonActivity/bossQuestGrade'),
    -- 神器之路
    ACTIVITY_ARTIFACT_ROAD_QUEST_AT     = PostData('Activity/artifactQuestAt'),
    ACTIVITY_ARTIFACT_ROAD_QUEST_GRADE  = PostData('Activity/artifactQuestGrade'),
    -- pt本
    PT_QUEST_AT                         = PostData('PT/questAt'),
    PT_QUEST_GRADE                      = PostData('PT/questGrade'),
    PT_BUY_LIVE                         = PostData('PT/buyLive'), -- pt本买活
    -- 杀人案（19夏活）
    MURDER_QUEST_AT                     = PostData('newSummerActivity/questAt'),            
    MURDER_QUEST_GRADE                  = PostData('newSummerActivity/questGrade'),    
    -- 巅峰对决                         
    ACTIVITY_ULTIMATE_BATTLE_QUEST_AT    = PostData('UltimateBattle/questAt'), -- 巅峰对决进入战斗
    ACTIVITY_ULTIMATE_BATTLE_QUEST_GRADE = PostData('UltimateBattle/questGrade'), -- 巅峰对决战斗结束
    -- 皮肤嘉年华
    SKIN_CARNIVAL_CHALLENGE_QUEST_AT     = PostData('SkinCarnival/questAt'),    -- 皮肤嘉年华进入战斗
    SKIN_CARNIVAL_CHALLENGE_QUEST_GRADE  = PostData('SkinCarnival/questGrade'), -- 皮肤嘉年华战斗结束
    -- luna塔
    LUNA_TOWER_QUEST_AT                  = PostData('LunaTower/questAt'),
    LUNA_TOWER_QUEST_GRADE               = PostData('LunaTower/questGrade'),
    -- 好友切磋
    FRIEND_BATTLE_QUEST_AT               = PostData('friend/studyQuestAt'),     -- 好友切磋进入战斗
    FRIEND_BATTLE_QUEST_GRADE            = PostData('friend/studyQuestGrade'),  -- 好友切磋战斗结束
    -- 神器指引
    ARTIFACT_GUIDE_HOME                  = PostData('Artifact/guide'),                -- 神器指引home
    ARTIFACT_GUIDE_REWARD_DRAW           = PostData('Artifact/drawGuideReward'),      -- 神器指引领奖
    ARTIFACT_GUIDE_FINAL_REWARD_DRAW     = PostData('Artifact/drawGuideFinalReward'), -- 神器指引最终奖励领取
    -------------------------排行榜----------------------------

    RANK_UNION_WARS                       = PostData('Rank/unionWars'), -- 工会战排行榜


    -------------------------主线剧情----------------------------
    QUEST_STORY                           = PostData('quest/story'),

    -------------------------收藏邮件----------------------------
    PRIZE_ENTER_COLLECT                   = PostData('Prize/enterCollect'),
    PRIZE_COLLECT                         = PostData('Prize/collect'),
    PRIZE_DELETE_COLLECT                  = PostData('Prize/deleteCollect'),

    -------------------------木人桩战斗----------------------------
    PLAYER_DUMMY          = PostData('player/dummy'),
    PLAYER_DUMMYLIST      = PostData('player/dummyList'),
    PLAYER_TEAM_DUMMYLIST = PostData('player/dummyTeamList'),
    PLAYER_DUMMY_QUEST_AT = PostData('player/dummyQuestAt'),

    -------------------------黑金商店--------------------------
    COMMERCE_HOME                  = PostData("Commerce/home"),                -- (商会主页)
    COMMERCE_WARE_HOUSE_EXTEND     = PostData("Commerce/warehouseExtend"),     -- (商会仓库扩容)
    COMMERCE_WARE_HOUSE            = PostData("Commerce/warehouse"),           -- (商会仓库)
    COMMERCE_FUTURES_BUY           = PostData("Commerce/futuresBuy"),          -- (商会期货买入)
    COMMERCE_FUTURES_SELL          = PostData("Commerce/futuresSell"),         -- (商会期货卖出)
    COMMERCE_MALL                  = PostData("Commerce/mall"),                -- (商会货物)
    COMMERCE_MALL_BUY              = PostData("Commerce/mallBuy"),             -- (商会货物购买)
    COMMERCE_PRECIOUS_MALL_BUY     = PostData("Commerce/preciousMallBuy"),     -- (商会珍贵货物购买)
    COMMERCE_PRECIOUS_LOTTERY      = PostData("Commerce/preciousLottery"),     -- (商会珍贵货物预约)
    COMMERCE_PRECIOUS_LOTTERY_LIST = PostData("Commerce/preciousLotteryList"), -- (商会珍贵货物预约奖励名单)
    COMMERCE_INVESTMENTLIST        = PostData("Commerce/investmentList"),      -- (商会投资列表)
    COMMERCE_INVESTMENT            = PostData("Commerce/investment"),           -- (商会投资)
    COMMERCE_INVESTMENT_DRAW       = PostData("Commerce/investmentDraw"),      -- (商会投资领取)
    COMMERCE_TITLE_UPGRADE         = PostData("Commerce/titleUpgrade"),        -- (商会称号升级)


    ------------------------周年庆2019年----------------------------
    ANNIVERSARY2_HOME                                = PostData("Anniversary2/home"),                            -- (周年庆主页)
    ANNIVERSARY2_MALL_BUY                            = PostData("Anniversary2/mallBuy"),                         -- (商店购买)
    ANNIVERSARY2_LOTTERY_HOME                        = PostData("Anniversary2/lotteryHome"),                     -- (抽奖)
    ANNIVERSARY2_LOTTERY                             = PostData("Anniversary2/lottery"),                         -- (抽奖)
    ANNIVERSARY2_AUGURY                              = PostData("Anniversary2/augury"),                          -- (占卜)
    ANNIVERSARY2_STORY_UNLOCK                        = PostData("Anniversary2/storyUnlock"),                     -- (解锁剧情)
    ANNIVERSARY2_CONSIGNMENT                         = PostData("Anniversary2/consignation"),                    -- (委托升级)
    ANNIVERSARY2_CONSIGNMENT_FINAL_REWARD_DRAW       = PostData("Anniversary2/consignationFinalRewardDraw"),     -- (委托最终奖励领取)
    ANNIVERSARY2_POINT_REWARD_DRAW                   = PostData("Anniversary2/pointRewardDraw"),                 -- (积分奖励领取)
    ANNIVERSARY2_BOSS                                = PostData("Anniversary2/boss"),                            -- (讨伐列表)
    ANNIVERSARY2_BOSS_QUEST_AT                       = PostData("Anniversary2/bossQuestAt"),                     -- (讨伐进入战斗)
    ANNIVERSARY2_BOSS_QUEST_GRADE                    = PostData("Anniversary2/bossQuestGrade"),                  -- (讨伐战斗结束)
    ANNIVERSARY2_BOSS_FOR_HELP                       = PostData("Anniversary2/bossForHelp"),                     -- (讨伐发起救援)
    ANNIVERSARY2_BOSS_REWARD_DRAW                    = PostData("Anniversary2/bossRewardDraw"),                  -- 讨伐奖励领取
    ANNIVERSARY2_EXPLORE                             = PostData("Anniversary2/explore"),                         -- (进入探索)
    ANNIVERSARY2_EXPLORE_WALK                        = PostData("Anniversary2/exploreWalk"),                     -- (探索下一轮)
    ANNIVERSARY2_EXPLORE_SECTION_CHEST               = PostData("Anniversary2/exploreSectionChest"),             -- (探索宝箱)
    ANNIVERSARY2_EXPLORE_SECTION_OPTION              = PostData("Anniversary2/exploreSectionOption"),            -- (探索答题)
    ANNIVERSARY2_EXPLORE_SECTION_TRAP                = PostData("Anniversary2/exploreSectionTrap"),              -- (探索打牌)
    ANNIVERSARY2_EXPLORE_SECTION_BATTLE_CARD         = PostData("Anniversary2/exploreSectionBattleCard"),        -- (探索打牌)
    EXPLORE_SECTION_STORY                            = PostData("Anniversary2/exploreSectionStory"),             -- (探索剧情)
    ANNIVERSARY2_EXPLORE_SECTION_BOSS_QUEST_AT       = PostData("Anniversary2/exploreSectionBossQuestAt"),       -- (探索精英进入战斗)
    ANNIVERSARY2_EXPLORE_SECTION_BOSS_QUEST_GRADE    = PostData("Anniversary2/exploreSectionBossQuestGrade"),    -- (探索精英战斗结束)
    ANNIVERSARY2_EXPLORE_SECTION_MONSTER_QUEST_AT    = PostData("Anniversary2/exploreSectionMonsterQuestAt"),    -- (探索小怪进入战斗)
    ANNIVERSARY2_EXPLORE_SECTION_MONSTER_QUEST_GRADE = PostData("Anniversary2/exploreSectionMonsterQuestGrade"), -- (探索小怪战斗结束)
    ANNIVERSARY2_EXPLORE_SECTION_GIVE_UP             = PostData("Anniversary2/exploreSectionGiveUp"),            -- (探索放弃)
    ANNIVERSARY2_EXPLORE_SECTION_DRAW                = PostData("Anniversary2/exploreSectionDraw"),              -- (探索最终奖励领取)
    ANNIVERSARY2_EXPLORE_ENTER                       = PostData("Anniversary2/exploreEnter"),                    -- (进入探索小关)
    ANNIVERSARY2_BUY_HP                              = PostData("Anniversary2/buyHp"),                           -- (购买活动体力)
    ANNIVERSARY2_RANK                                = PostData("Anniversary2/rank"),                            -- (排行榜)
    ANNIVERSARY2_BOSS_HP                             = PostData("Anniversary2/bossHp"),                          -- (获取BOSS血量)

    -------------------------luna塔----------------------------
    LUNA_TOWER_RESURRECTION                          = PostData("LunaTower/resurrection"),                       -- luna塔刷状态
    
    -------------------------打牌游戏--------------------------
    TTGAME_HOME         = PostData('BattleCard/home'),            -- 打牌游戏 主页
    TTGAME_REPORT       = PostData('BattleCard/report'),          -- 打牌游戏 战报
    TTGAME_SHOP_PACK    = PostData('BattleCard/cardPackMall'),    -- 打牌游戏 牌店
    TTGAME_BUY_PACK     = PostData('BattleCard/cardPackMallBuy'), -- 打牌游戏 买卡包
    TTGAME_BUY_CARD     = PostData('BattleCard/compose'),         -- 打牌游戏 买卡牌
    TTGAME_BUY_TIMES    = PostData('BattleCard/buyRewardTimes'),  -- 打牌游戏 买次数
    TTGAME_DECK_SAVE    = PostData('BattleCard/saveDeck'),        -- 打牌游戏 存卡组
    TTGAME_DRAW_COLLECT = PostData('BattleCard/drawCollect'),     -- 打牌游戏 收集奖励
    

    -------------------------飨灵对决初赛----------------------------
    FOOD_VOTE_INFO                                   = PostData("FoodVote/info"),                                -- 获取选票信息
    FOOD_VOTE_PICK                                   = PostData("FoodVote/pick"),                                -- 领选票
    FOOD_VOTE_VOTE                                   = PostData("FoodVote/vote"),                                -- 投票
    FOOD_VOTE_RANK                                   = PostData("FoodVote/rank"),                                -- 投票排行榜

    -------------------------幸运数字----------------------------
    ACTIVITY_LUCKY_NUM_HOME                          = PostData("Activity/luckyNumHome"),                        -- 幸运数字秒杀活动 首页
    ACTIVITY_LUCKY_NUM_PRIZE_HOME                    = PostData("Activity/luckyNumPrizeHome"),                   -- 幸运数字秒杀活动 兑换奖励首页
    ACTIVITY_LUCKY_NUM_PRIZE                         = PostData("Activity/luckyNumPrize"),                       -- 幸运数字秒杀活动 兑换奖励

    -------------------------飨灵刮刮乐----------------------------
    FOOD_COMPARE_HOME                               = PostData("FoodCompare/home"),                             -- 活动首页
    FOOD_COMPARE_VOTE                               = PostData("FoodCompare/vote"),                             -- 2选1
    FOOD_COMPARE_SELECT_POOL                        = PostData("FoodCompare/selectPool"),                       -- 选择卡池
    FOOD_COMPARE_STAMP_HOME                         = PostData("FoodCompare/stampHome"),                        -- 邮票首页
    FOOD_COMPARE_RESET_POOL                         = PostData("FoodCompare/resetPool"),                        -- 重置卡池
    FOOD_COMPARE_LOTTERY_HOME                       = PostData("FoodCompare/lotteryHome"),                      -- 刮刮乐首页
    FOOD_COMPARE_LOTTERY                            = PostData("FoodCompare/lottery"),                          -- 刮奖
    FOOD_COMPARE_DRAW_TASK_REWARD                   = PostData("FoodCompare/drawTaskReward"),                   -- 任务完成领奖
    FOOD_COMPARE_COMPARE_INFO                       = PostData("FoodCompare/compareInfo"),                      -- 对决信息
    FOOD_COMPARE_HAS_RARE_ACK                       = PostData("FoodCompare/hasRareAck"),                       -- 卡池稀有道具抽光通知回调


	-------------------------新CV分享----------------------------
    ACTIVITY_NEW_SHARE               = PostData("Activity/newShare"),                                  -- (新CV分享)
    ACTIVITY_DRAW_NEW_SHARE_COLLECT  = PostData("Activity/drawNewShareCollect"),                       -- (新CV分享收集领取)
    ACTIVITY_DRAW_NEW_SHARE_CV       = PostData("Activity/drawNewShareCv"),                            -- (新CV分享CV领取)
    ACTIVITY_NEW_SHARE_COMPOUND      = PostData("Activity/newShareCompound"),                          -- (新CV分享收集合成)
    ACTIVITY_NEW_SHARE_CV_SHARE      = PostData("Activity/newShareCvShare"),                           -- (新CV分享分享CV)
    ACTIVITY_NEW_SHARE_COLLECT_SHARE = PostData("Activity/newShareCollectShare"),                      -- (新CV分享分享收集)
    
    -------------------------限时升级活动----------------------------
    ACTIVITY_TIME_LIMIT_LV_UPGRADE_HOME = PostData("Activity/timeLimitLvUpgradeHome"),                      -- (限时升级活动)

    -------------------------预设编队----------------------------
    PRESET_TEAM_GET_TEAM_CUSTOM_LIST   = PostData("card/getTeamCustomList"),                                  -- 获取自定义编队列表
    PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL = PostData("card/getTeamCustomDetail"),                                -- 获取自定义编队某个信息
    PRESET_TEAM_SET_TEAM_CUSTOM        = PostData("card/setTeamCustom"),                                      -- 设置自定义编队信息
    SAVE_CARD_CUSTOM_GROUP             = PostData("Card/saveCustomGroup"),                                    -- 保存自定义分组
    
    -------------------------20春活----------------------------
    SPRING_ACTIVITY_20_HOME               = PostData("SpringActivity2020/home"),                             -- 20春活主页home
    SPRING_ACTIVITY_20_BUY_HP             = PostData("SpringActivity2020/buyHp"),                            -- 20春活购买活动体力
    SPRING_ACTIVITY_20_DRAW_POINT_REWARDS = PostData("SpringActivity2020/drawPointRewards"),                 -- 20春活积分奖励领取
    SPRING_ACTIVITY_20_LOTTERY_HOME       = PostData("SpringActivity2020/lotteryHome"),                      -- 20春活抽奖home
    SPRING_ACTIVITY_20_LOTTERY            = PostData("SpringActivity2020/lottery"),                          -- 20春活抽奖
    SPRING_ACTIVITY_20_QUEST_AT           = PostData("SpringActivity2020/questAt"),                          -- 20春活进入战斗
    SPRING_ACTIVITY_20_QUEST_GUADE        = PostData("SpringActivity2020/questGrade"),                       -- 20春活战斗结算
    SPRING_ACTIVITY_20_SWEEP              = PostData("SpringActivity2020/sweep"),                            -- 20春活扫荡
    SPRING_ACTIVITY_20_RANK               = PostData("SpringActivity2020/rank"),                             -- 20春活排行榜
    SPRING_ACTIVITY_20_UNLOCK_STORY       = PostData("SpringActivity2020/unLockStory"),                      -- 20春活解锁剧情
    SPRING_ACTIVITY_20_SET_BOSS_TEAM      = PostData("SpringActivity2020/setBossTeam"),                      -- 20春活设置boss战斗队伍

    -------------------------宝箱活动-----------------------------
    ACTIVITY2_CR_BOX                    = PostData("Activity2/crBox"),                 -- (延迟宝箱)
    ACTIVITY2_CR_BOX_DRAW_FINAL_REWARDS = PostData("Activity2/crBoxDrawFinalRewards"), -- (延迟宝箱领取最终奖励)
    ACTIVITY2_CR_BOX_DRAW_BOX           = PostData("Activity2/crBoxDrawBox"),          -- (延迟宝箱领取宝箱)
    ACTIVITY2_CR_BOX_OPEN_BOX           = PostData("Activity2/crBoxOpenBox"),          -- (延迟宝箱正常打开宝箱)
    
    -------------------------全能活动-----------------------------
    ACTIVITY_ALLROUND_HOME              = PostData("Activity2/pathTask"),              -- 全能活动home
    ACTIVITY_ALLROUND_TASK_DRAW         = PostData("Activity2/pathTaskDraw"),          -- 全能活动任务奖励领取
    ACTIVITY_ALLROUND_PATH_DRAW         = PostData("Activity2/pathTaskPathDraw"),      -- 全能活动路线奖励领取

    --------------------------联动本------------------------------
    POP_TEAM_HOME                       = PostData("Activity2/farm"),                  -- 联动本home
    POP_FARM_LAND_UNLOCK                = PostData("Activity2/farmLandUnlock"),        -- 种菜土地解锁
    POP_FARM_PLANT                      = PostData("Activity2/farmPlant"),             -- 种菜种植
    POP_FARM_MATURE                     = PostData("Activity2/farmMature"),            -- 种菜成熟
    POP_FARM_MALL                       = PostData("Activity2/farmMall"),              -- 种菜商店
    POP_FARM_MALL_BUY                   = PostData("Activity2/farmMallBuy"),           -- 种菜商店购买
    POP_FARM_ZONE_UNLOCK                = PostData("Activity2/farmZoneUnlock"),        -- 种菜副本解锁
    POP_TEAM_QUEST_AT                   = PostData("Activity2/farmQuestAt"),           -- 联动本进入战斗
    POP_TEAM_QUEST_GRADE                = PostData("Activity2/farmQuestGrade"),        -- 联动本战斗结算
    POP_TEAM_STORY_QUEST                = PostData("Activity2/farmStoryQuest"),        -- 联动本剧情关
    POP_TEAM_CHEST_QUEST                = PostData("Activity2/farmChestQuest"),        -- 联动本宝箱领取
    POP_FARM_BOSS                       = PostData("Activity2/farmBoss"),              -- 种菜副本BOSS
    POP_FARM_BOSS_QUEST_AT              = PostData("Activity2/farmBossQuestAt"),       -- 种菜BOSS本
    POP_FARM_BOSS_QUEST_GRADE           = PostData("Activity2/farmBossQuestGrade"),    -- 种菜BOSS本结算
    FARM_BOSS_BUY_TIMES                 = PostData("Activity2/farmBossBuyTimes"),      -- 种菜BOSS本购买次数

    ------------------------- 武道会 ----------------------------
    CHAMPIONSHIP_HOME            = PostData('Championship/home'),          -- 武道会 首页
    CHAMPIONSHIP_TICKET          = PostData('Championship/ticket'),        -- 武道会 海选塞-购买挑战次数
    CHAMPIONSHIP_AUDITION        = PostData('Championship/audition'),      -- 武道会 海选赛-提交队伍
    CHAMPIONSHIP_RANK            = PostData('Championship/rank'),          -- 武道会 海选赛-排名32位
    CHAMPIONSHIP_QUEST_AT        = PostData('Championship/questAt'),       -- 武道会 海选赛-进入战斗
    CHAMPIONSHIP_QUEST_GRADE     = PostData('Championship/questGrade'),    -- 武道会 海选赛-战斗结算
    CHAMPIONSHIP_APPLY           = PostData('Championship/apply'),         -- 武道会 晋级赛-提交队伍
    CHAMPIONSHIP_GUESS           = PostData('Championship/guess'),         -- 武道会 竞猜下注
    CHAMPIONSHIP_OPPONENT_DETAIL = PostData('Championship/detail'),        -- 武道会 对手队伍详情
    CHAMPIONSHIP_PLAYER_DETAIL   = PostData('Championship/detail/player'), -- 武道会 选手队伍详情
    CHAMPIONSHIP_CHAMPION_DETAIL = PostData('Championship/detail/final'),  -- 武道会 冠军队伍详情
    CHAMPIONSHIP_REPLAY_RESULT   = PostData('Championship/replayOverall'), -- 武道会 战斗回放-战斗结果
    CHAMPIONSHIP_REPLAY_DETAIL   = PostData('Championship/replayDetail'),  -- 武道会 战斗回放-战斗详情
    CHAMPIONSHIP_HISTORY         = PostData('Championship/history'),       -- 武道会 获取历届冠军
    CHAMPIONSHIP_SHOP_HOME       = PostData('mall/home/championship'),     -- 武道会 商店-主页
    CHAMPIONSHIP_SHOP_BUY        = PostData('mall/buy/championship'),      -- 武道会 商店-购买
    CHAMPIONSHIP_SHOP_MULTI_BUY  = PostData('mall/buyMulti/championship'), -- 武道会 商店-批量买
    CHAMPIONSHIP_SHOP_REFRESH    = PostData('mall/championshipRefresh'),   -- 武道会 商店-刷新

    ------------------------- 组合活动 ----------------------------
    ASSEMBLY_ACTIVITY_HOME                = PostData("AssemblyActivity/home"),                     -- 组合互动home 
    ASSEMBLY_ACTIVITY_LOTTERY_HOME        = PostData("AssemblyActivity/lotteryHome"),              -- 组合活动 抽奖home
    ASSEMBLY_ACTIVITY_LOTTERY_DRAW        = PostData("AssemblyActivity/lottery"),                  -- 组合活动 抽奖抽奖
    ASSEMBLY_ACTIVITY_CIRCLE_TASK_HOME    = PostData("AssemblyActivity/circleTask"),               -- 组合活动 循环任务home
    ASSEMBLY_ACTIVITY_CIRCLE_TASK_DRAW    = PostData("AssemblyActivity/drawCircleTask"),           -- 组合活动 循环任务领奖
    ASSEMBLY_ACTIVITY_MALL_HOME           = PostData("AssemblyActivity/mall"),                     -- 组合活动 商城home
    ASSEMBLY_ACTIVITY_MALL_BUY            = PostData("AssemblyActivity/buy"),                      -- 组合活动 商城购买
    ASSEMBLY_ACTIVITY_RANK_HOME           = PostData("AssemblyActivity/rank"),                     -- 组合活动 排行榜home
    ASSEMBLY_ACTIVITY_SQUARED_HOME        = PostData("AssemblyActivity/squared"),                  -- 组合活动 九宫格home
    ASSEMBLY_ACTIVITY_SQUARED_LUCKY       = PostData("AssemblyActivity/squaredLucky"),             -- 组合活动 九宫格抽奖
    ASSEMBLY_ACTIVITY_SQUARED_NEXT_ROUND  = PostData("AssemblyActivity/squaredNextRound"),         -- 组合活动 九宫格下一轮
    ASSEMBLY_ACTIVITY_BIGWHEEL_HOME       = PostData("AssemblyActivity/bigWheel"),                 -- 组合活动 转盘home
    ASSEMBLY_ACTIVITY_BIGWHEEL_DRAW       = PostData("AssemblyActivity/drawBigWheel"),             -- 组合活动 转盘抽奖
    ASSEMBLY_ACTIVITY_BIGWHEEL_TIMES_DRAW = PostData("AssemblyActivity/drawBigWheelTimesRewards"), -- 组合活动 转盘次数奖励领取
    ASSEMBLY_ACTIVITY_EXCHANGE_HOME       = PostData("AssemblyActivity/exchangeList"),             -- 组合活动 兑换home
    ASSEMBLY_ACTIVITY_EXCHANGE            = PostData("AssemblyActivity/exchange"),                 -- 组合活动 兑换
    ------------------------- 新手福利 ----------------------------
    NOVICE_WELFARE_HOME          = PostData('Activity2/newbie14Task'),             -- 新手福利home
    NOVICE_WELFARE_TASK_DRAW     = PostData('Activity2/drawNewbie14Task'),         -- 新手福利任务奖励
    NOVICE_WELFARE_POINT_DRAW    = PostData('Activity2/drawNewbie14ActivePoint'),  -- 新手福利活动

    ------------------------周年庆2020年----------------------------
    ANNIV2020_MAIN_HOME           = PostData('Anniversary2020/home'),              -- 周年庆2020 主界面
    ANNIV2020_STORY_UNLOCK        = PostData('Anniversary2020/unlockStory'),       -- 周年庆2020 故事 解锁
    ANNIV2020_SHOP_HOME           = PostData('Anniversary2020/mall'),              -- 周年庆2020 商店 主页
    ANNIV2020_SHOP_BUY            = PostData('Anniversary2020/mallBuy'),           -- 周年庆2020 商店 购买
    ANNIV2020_HANG_HOME           = PostData('Anniversary2020/hangHome'),          -- 周年庆2020 挂机游戏 首页
    ANNIV2020_HANG_HANGING        = PostData('Anniversary2020/hang'),              -- 周年庆2020 挂机游戏 挂机
    ANNIV2020_HANG_DRAW_FINISH    = PostData('Anniversary2020/hangFinish'),        -- 周年庆2020 挂机游戏 领取完成奖励
    ANNIV2020_HANG_DRAW_COLLECT   = PostData('Anniversary2020/hangDrawReward'),    -- 周年庆2020 挂机游戏 领取收集奖励
    ANNIV2020_PUZZLE_HOME         = PostData('Anniversary2020/puzzle'),            -- 周年庆2020 拼图游戏 首页
    ANNIV2020_PUZZLE_COMMIT       = PostData('Anniversary2020/puzzleCommit'),      -- 周年庆2020 拼图游戏 提交
    ANNIV2020_EXPLORE_HOME        = PostData('Anniversary2020/explore'),           -- 周年庆2020 探索游戏 首页
    ANNIV2020_EXPLORE_ENTER       = PostData('Anniversary2020/exploreEnter'),      -- 周年庆2020 探索游戏 进入
    ANNIV2020_EXPLORE_SWEEP       = PostData('Anniversary2020/exploreSweep'),      -- 周年庆2020 探索游戏 扫荡
    ANNIV2020_EXPLORE_DRAW_HP     = PostData('Anniversary2020/drawJumpGridHp'),    -- 周年庆2020 探索游戏 领体力
    ANNIV2020_EXPLORE_GIVE_UP     = PostData('Anniversary2020/exploreGiveUp'),     -- 周年庆2020 探索游戏 放弃
    ANNIV2020_EXPLORE_NEXT_FLOOR  = PostData('Anniversary2020/exploreNextFloor'),  -- 周年庆2020 探索游戏 下一层
    ANNIV2020_EXPLORE_DRAW_FLOOR  = PostData('Anniversary2020/exploreDraw'),       -- 周年庆2020 探索游戏 领取本层奖励
    ANNIV2020_EXPLORE_CHEST       = PostData('Anniversary2020/exploreChest'),      -- 周年庆2020 探索游戏 箱子格子
    ANNIV2020_EXPLORE_OPTION      = PostData('Anniversary2020/exploreOption'),     -- 周年庆2020 探索游戏 选项格子
    ANNIV2020_EXPLORE_QUEST_AT    = PostData('Anniversary2020/exploreQuestAt'),    -- 周年庆2020 探索游戏 战斗开始
    ANNIV2020_EXPLORE_QUEST_GRADE = PostData('Anniversary2020/exploreQuestGrade'), -- 周年庆2020 探索游戏 战斗结算
    ANNIV2020_EXPLORE_NONE        = PostData('Anniversary2020/exploreNone'),       -- 周年庆2020 探索游戏 空白格子
    ANNIV2020_EXPLORE_BUFF        = PostData('Anniversary2020/exploreBuff'),       -- 周年庆2020 探索游戏 buff格子
    ------------------------- 飨灵收集册 ----------------------------
    CARD_ALBUM_TASK_DRAW          = PostData('cardCollection/drawCardCollectionBookTask'), -- 飨灵收集册 任务领奖

    ------------------------ 猫屋 ----------------------------
    HOUSE_HOME_ENTER         = PostData('House/home'),                  -- 猫屋 小屋进入
    HOUSE_HOME_QUITE         = PostData('House/quitHome'),              -- 猫屋 小屋离开
    HOUSE_LEVEL_UPGRADE      = PostData('House/levelUp'),               -- 猫屋 小屋升级
    HOUSE_EVENT_FINISH       = PostData('House/finishEvent'),           -- 猫屋 完成事件
    HOUSE_CHANGE_HEAD        = PostData('House/changeHead'),            -- 猫屋 更改头像
    HOUSE_CHANGE_BUBBLE      = PostData('House/changeBubble'),          -- 猫屋 更改气泡
    HOUSE_CHANGE_IDENTITY    = PostData('House/changeBusinessCard'),    -- 猫屋 更改身份
    HOUSE_TROPHY_ENTER       = PostData('House/trophy'),                -- 猫屋 小屋奖杯
    HOUSE_TROPHY_DRAW        = PostData('House/drawTrophy'),            -- 猫屋 领取奖杯
    HOUSE_AVATAR_BUY         = PostData('House/buyAvatar'),             -- 猫屋 购买家具
    HOUSE_MALL_BUY           = PostData('House/mallBuy'),               -- 猫屋 购买道具
    HOUSE_FRIEND_VISIT       = PostData('House/friend'),                -- 猫屋 好友小屋
    HOUSE_FRIEND_INVITE      = PostData('House/invite'),                -- 猫屋 好友邀请
    HOUSE_KICKOUT            = PostData('House/kickOut'),               -- 猫屋 踢出小屋
    HOUSE_SUIT_SAVE          = PostData('House/saveCustomSuit'),        -- 猫屋 保存套装
    HOUSE_SUIT_APPLY         = PostData('House/applyCustomSuit'),       -- 猫屋 应用套装
    HOUSE_PLACE_CATS         = PostData('House/placeCats'),             -- 猫屋 放置猫咪
    HOUSE_CLEAN_TRIGGER      = PostData('House/clean'),                 -- 猫屋 清理触发
    HOUSE_REPAIR_AVATAR      = PostData('House/repair'),                -- 猫屋 修理家具
    HOUSE_CAT_HOME           = PostData('HouseCat/home'),               -- 猫屋-猫咪 主页
    HOUSE_CAT_INIT           = PostData('HouseCat/init'),               -- 猫屋-猫咪 初始选择
    HOUSE_CAT_EXTEND         = PostData('HouseCat/extend'),             -- 猫屋-猫咪 仓库扩容
    HOUSE_CAT_MALL_HOME      = PostData('HouseCat/mall'),               -- 猫屋-猫咪 商城主页
    HOUSE_CAT_MALL_BUY       = PostData('HouseCat/mallBuy'),            -- 猫屋-猫咪 商城购买
    HOUSE_CAT_MALL_BATCH_BUY = PostData('HouseCat/mallBuyMulti'),       -- 猫屋-猫咪 商城一键购买
    HOUSE_CAT_STUDY_BEGAN    = PostData('HouseCat/study'),              -- 猫屋-猫咪 学习开始
    HOUSE_CAT_STUDY_GIVEUP   = PostData('HouseCat/studyGiveUp'),        -- 猫屋-猫咪 学习放弃
    HOUSE_CAT_STUDY_DONE     = PostData('HouseCat/studyDone'),          -- 猫屋-猫咪 学习结束
    HOUSE_CAT_WORK_BEGAN     = PostData('HouseCat/work'),               -- 猫屋-猫咪 工作开始
    HOUSE_CAT_WORK_GIVEUP    = PostData('HouseCat/workGiveUp'),         -- 猫屋-猫咪 工作放弃
    HOUSE_CAT_WORK_DONE      = PostData('HouseCat/workDone'),           -- 猫屋-猫咪 工作结束
    HOUSE_CAT_CAREER_UP      = PostData('HouseCat/careerLevelUp'),      -- 猫屋-猫咪 职业升级
    HOUSE_CAT_ACT_FEED       = PostData('HouseCat/feed'),               -- 猫屋-猫咪 喂食
    HOUSE_CAT_ACT_PLAY       = PostData('HouseCat/play'),               -- 猫屋-猫咪 玩耍
    HOUSE_CAT_ACT_SLEEP      = PostData('HouseCat/sleep'),              -- 猫屋-猫咪 睡觉
    HOUSE_CAT_ACT_TOILET     = PostData('HouseCat/toilet'),             -- 猫屋-猫咪 如厕
    HOUSE_CAT_ACT_SHOWER     = PostData('HouseCat/shower'),             -- 猫屋-猫咪 洗澡
    HOUSE_CAT_ACT_OUTING     = PostData('HouseCat/out'),                -- 猫屋-猫咪 外出
    HOUSE_CAT_FRIEND_PLAY    = PostData('HouseCat/friendPlay'),         -- 猫屋-猫咪 好友玩耍
    HOUSE_CAT_FRIEND_AWAY    = PostData('HouseCat/friendDisperse'),     -- 猫屋-猫咪 好友驱逐
    HOUSE_CAT_MATING         = PostData('HouseCat/mating'),             -- 猫屋-猫咪 交配状态变动
    HOUSE_CAT_MATING_HOUSE   = PostData('HouseCat/matingHouse'),        -- 猫屋-猫咪 交配开房
    HOUSE_CAT_MATING_CANCEL  = PostData('HouseCat/matingHouseCancel'),  -- 猫屋-猫咪 交配取消
    HOUSE_CAT_MATING_INVITE  = PostData('HouseCat/matingCall'),         -- 猫屋-猫咪 交配邀请
    HOUSE_CAT_MATING_ANSWER  = PostData('HouseCat/matingAnswer'),       -- 猫屋-猫咪 交配应答
    HOUSE_CAT_MATING_END_TO  = PostData('HouseCat/matingEnd'),          -- 猫屋-猫咪 交配结束（发出方）
    HOUSE_CAT_MATING_END_BE  = PostData('HouseCat/beInvitedMatingEnd'), -- 猫屋-猫咪 交配结束（被邀方）
    HOUSE_CAT_RENAME         = PostData('HouseCat/rename'),             -- 猫屋-猫咪 改名
    HOUSE_CAT_FREE           = PostData('HouseCat/free'),               -- 猫屋-猫咪 放生
    HOUSE_CAT_REBIRTH        = PostData('HouseCat/rebirth'),            -- 猫屋-猫咪 回归
    HOUSE_CAT_REBORN         = PostData('HouseCat/reborn'),             -- 猫屋-猫咪 重生
    HOUSE_CAT_SYNC           = PostData('HouseCat/cat'),                -- 猫屋-猫咪 同步
    HOUSE_CAT_RESET_ACHIEVE  = PostData('HouseCat/resetAchievement'),   -- 猫屋-猫咪 成就刷新
    HOUSE_CAT_DRAW_ACHIEVE   = PostData('HouseCat/drawAchievement'),    -- 猫屋-猫咪 成就领取
    HOUSE_CAT_EQUIP_CAT      = PostData('HouseCat/equip'),              -- 猫屋-猫咪 装备猫咪
    
    ------------------------ 满级奖励 ----------------------------
    DERIVATIVE_HOME    = PostData('Derivative/home'),                -- 实物奖励 主页
    DERIVATIVE_DRAW    = PostData('Derivative/drawMaxLevelRewards'), -- 实物奖励 领取奖励
    DERIVATIVE_ADDRESS = PostData('Derivative/address'),             -- 实物奖励 填写信息

}
