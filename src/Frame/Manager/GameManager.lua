--[[
游戏管理模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class GameManager : ManagerBase
local GameManager = class('GameManager',ManagerBase)
GameManager.instances = {}

------------ define ------------
local ChatChannelNums = 5
local BATTLE_ACCELERATE_KEY = 'battleaccelerate'
local CheckinCardData = require('Frame.CheckinCardData')
------------ define ------------

function GameManager:ctor( key )
	self.super.ctor(self)
	if GameManager.instances[key] ~= nil then
		funLog(Logger.INFO, "注册相关的facade类型" )
		return
	end
	self.isLoadingShowing = false
	self.isNetworkWeakShowing_ = false
	self.userInfo = {} --用户信息存的位置
	self.storeAccounts = {} --本地保存的帐号信息
    self.downCountHandlers = {} --用于保存倒计时
    self.downCountUiHandler = {} -- 用于维护 需要更新ui的回调
    self.dStores = {} --优化用
	GameManager.instances[key] = self
end

function GameManager.GetInstance(key)
	key = (key or "GameManager")
	if GameManager.instances[key] == nil then
		GameManager.instances[key] = GameManager.new(key)
	end
	return GameManager.instances[key]
end

function GameManager:release()
    self:stopPreDownloadCheckinCardAssets_()
end

function GameManager:RestorePlayerData()
    table.merge(self.userInfo,
    {
        playerId                = 0,
        playerName              = '',
        encryptPlayerId         = '',
        mainExp                 = 0,
        avatar                  = '',
        taskId                  = 0,
        newAchieveList          = {},
        newestHardQuestId       = 0,  -- 困难副本关卡最新id
        newestInsaneQuestId     = 0,  -- 史诗副本关卡最新id
        newestQuestId           = 0,  -- 普通副本关卡最新id
        questStory              = {}, -- 解锁过的关卡剧情id
        iceVigourRecoverSeconds = 0,  --冰场多久恢复一点新鲜度
        hp                      = 0,
        gold                    = 0,
        diamond                 = 0, -- 总钻石
        freeDiamond             = 0, -- 免费钻石
        paidDiamond             = 0, -- 有偿钻石
        ftPoint                 = 0,
		popularity 				= 0, -- 知名度数量
        tip                     = 0, -- 小费
        medal                   = 0, -- 竞技场勋章
        unionPoint              = 0, -- 工会勋章
        kofPoint                = 0, -- kof竞技场代币
        newKofPoint             = 0, -- newkof竞技场代币
		highestPopularity       = 0, -- 最高知名度
        activityQuestHp         = 0, -- 活动副本行动力
        restaurantLevel         = 1, --餐厅等级
        petCoin 				= 0,  -- 堕神币
        level 					= 0,  -- 玩家等级
        backpack                = {}, -- 背包数据
        cards 					= {}, -- 卡牌数据
        cardSkins               = {}, -- 所有卡牌皮肤数据
        mission 				= {}, -- 任务数据
        teamFormation 			= {}, -- 实际参加战斗编队数据
        operationTeamFormation  = {}, -- 编队页面操作数据
        unlockTeamNeed  		= {}, -- 解锁编队所需要条件
        kitchenAssistantId 		= 0, --厨房看板娘id
        takeAwayAssistantId 	= 0, --外卖看板娘id
        lobbyAssistantId 		= 0, --大堂看板娘id
        skill 					= {},-- 主角技
        allSkill 				= {},-- 所有激活的战斗主角技
        pets 					= {},-- 堕神数据
        gems                    = {},-- 装备的宝石
        buyGoldRestTimes 		= 0,-- 金币的剩余购买次数
        freeGoldLeftTimes       = {},-- 免费金币剩余次数 key为会员ID, value为剩余次数
        buyHpRestTimes 			= 0,-- 体力的剩余购买次数
        questGrades 			= {}, -- 关卡星级信息
        allQuestChallengeTimes  = {}, -- 关卡剩余挑战次数
        cookingPoint            = 0, -- 料理点数
        newestAreaId = 1, --区域id值
		cookingStyles           = {} , --菜谱数据
        friendList              = {}, -- 好友列表
        signboardId             = nil, -- 主界面看板娘 卡牌数据库id
        nextHpSeconds           = 0,  -- 下一点体力恢复所需秒数
        hpRecoverSeconds        = 0,  -- 一点体力恢复所需秒数
        totalHpSeconds          = 0,  -- 记录全部体力恢复所需的秒数
        -- minMemberLeftSeconds    = 0,  -- 保存一份月卡最小剩余时间
        hpCountDownStartSeconds = 0,  -- 记录 体力倒计时开始的时间
        feedTimes               = 0, --最大的格子喂食次数
        member                  = {},  -- 会员相关数据： key: memberId    leftSeconds: 会员结束秒数
        cityRewardNotDrawn      = {[QUEST_DIFF_NORMAL] = {}, [QUEST_DIFF_HARD] = {}}, -- 章节满星奖励
        tips                    = {}, -- 活动红点提示
        serverTask              = {}, -- 活动 全服任务
        accumulativePay         = {}, -- 活动 累充
        accumulativePayTwo      = 0,  -- 活动 累充
        binggoTask              = {}, -- 活动 binggo任务
        login                   = {}, -- 活动 登录送
        cvShare                 = {}, -- 活动 cv分享
        blacklist               = {}, -- 黑名单
        worldBossTestReward     = 0,  -- 有未领取的世界boss试炼奖励
        exploreSystemRedPoint   = 0,  -- 是(1)否(0)有未领取奖励的新探索任务
        appoinitData            = {}, -- 新服预约数据
        --------------------------------------------------------
        -- 活动相关
        newbie15Day             = 0, -- 新手15天开启
        firstPay                = 1, -- 首冲
        permanentSinglePay      = 0, -- 常驻单笔充值活动
        levelAdvanceChest       = 0, -- 进阶等级礼包活动
        levelReward             = 0, -- 等级奖励
        firstPayRewards         = {}, -- 首冲奖励
        loveBentoData           = {}, -- 爱心便当数据
        isShowNewbie15Day       = false, -- 是否显示新手15天打脸
        isShowMonthlyLogin      = false, -- 是否显示月签打脸
        isShowPoster            = false,  -- 是否显示活动广告页
        activityHomeIconData    = {activity = {}},
        activityHomeData        = {activity = {{activityId = -1, image = {[tostring(i18n.getLang())] = ''}, type = -1}}},
        activityAd              = {},  -- 活动广告页
        restaurantActivity         = {},  -- 餐厅活动
        restaurantActivityMenuData = {},  -- 餐厅活动 菜谱数据
        restaurantActivityPreview  = {},  -- 餐厅活动预览
        channelProducts            = {},  -- 商品列表
        summerActivity             = -1, -- 夏活剩余时间，-1为关闭
        comparisonActivity         = -1, -- 燃战剩余时间，-1为关闭
        comparisonActivityTime     = -1, -- 燃战活动进行剩余时间，-1为关闭
        PTDungeonTimerActivityTime = 0,  -- pt本活动剩余时间
        isOpenedAnniversary        = 0,  -- 是否开启周年庆活动，1为开启
        isOpenedAnniversaryPV      = 0,  -- 是否开启周年庆动画，1为开启
        payLevelRewardOpened       = 0,  -- 是否开启成长基金
        isPayLoginRewardsOpen      = 0,  -- 是否开启付费签到
        newbie14TaskRemainTime     = 0,  -- 新手福利剩余时间, 0为关闭
        isOpenTransfer             = 0,  -- 账号迁移功能, 0为关闭, 1为开启
        --------------------------------------------------------
        --------------------------------------------------------
        -- 服务器无关 缓存数据
        localCurrentQuestId 			= 0, -- 服务器无关 当前关卡id
        localCurrentEquipedMagicFoodId  = 0, -- 服务器无关 上一次选择的魔法诱饵id
        localCurrentBattleTeamId 		= 0, -- 服务器无关 上一次选择的编队
        localBattleAccelerate 			= self:GetLocalBattleAccelerate(), -- 服务器无关 上一次战斗加速设置
        avatarCacheData = {}, --记录当前餐厅avatar的位置信息列表
        topUIShowType = '', -- 记录左上角ui显示情况
        avatarCacheRestaurantLevels     = {},
        avatarCacheRestaurantNews       = {},

        showRedPointForMissions = {['daily'] = false, ['activePoint'] = false, ['main'] = false},--记录是否显示主界面任务入口红点 daily:日常 activePoint:活跃度,main：成长
        showRedPointForPetPurge = false,--记录是否显示主界面堕神入口红点
        petPurgeLeftSeconds = 0,--记录堕神灵体净化剩余时间
        showRedPointForRestaurantRecipeNum = false, --餐厅无制作好的菜品了
        showRedPointForNewbieTask = false, --新手七天任务总奖励

        exploreSystemLeftSeconds   = 0,  -- 记录新探索 探索阶段剩余时间

        dailyTaskCacheData_   = {},     --日常任务缓存数据
        achievementCacheData_ = {},     --成就任务缓存数据
        unionTaskCacheData_   = {},     --工会任务缓存数据
        
        activityEntryDataRequestStates = {}, -- 活动入口请求数据状态 {['activityId'] = (0 or 1)} 1 表示请求过

        growthFundCacheData_ = {},      -- 成长基金缓存数据

        plotRemindDatas      = {} ,     -- 剧情提示数据
        plotQuestConfDatas   = {} ,     -- 剧情关卡配表数据
        isShowTimeLimitUpgradeTask = false , --是否开启限时升级任务
        isPopTimeLimitUpgradeTask = false , --是否弹出限时升级任务
        --------------------------------------------------------
        --剧情任务相关的逻辑
        ------------------------
        isFirstGuide            = false,
        storyTasks = {}, --
		kitchenStoves = {}, -- 记录早台数据表
        places = {}, --记录卡牌所处模块位置的信息缓存数据
        iceroomLeftSeconds = 0, --冰场的剩余时间
        loginClientTime = os.time(),
        phone          = "" , -- 绑定的手机号
        isFirstPhoneLock =  0 , -- 是否是第一次绑定手机号
        employee = {}, --餐厅中的信息
        supervisor  = {},   --主管
        chef        = {},   --厨师
        waiter      = {},   --服务
		playerSign = playerSign , -- 玩家的签名
        -------------------图鉴相关-----------------------
        cardStory = {}, -- 已解锁的卡牌剧情id
        cardVoice = {}, -- 已解锁的卡牌配音id
        -------------------图鉴相关-----------------------
        clock = {},
        recipeUpgradeRed = {} ,-- 菜谱升级的图表
        recipeNewRed = {} , ---储存新的菜谱
        recipeStylesRed = {} ,
        isCardRed = false , -- 车库的小红点记录
        exploreAreasRedData = {} , -- 记录探索点的倒计时
        openCodeModule = nil , --  控制兑换码功能
        isRecommendOpen = 0,  -- 推广员是否开放 ： 1 是 0 否
        newbieTaskRemainTime = 0, --新手七天任务剩余时间
        restaurantCleaningLeftTimes      = 0,  -- 餐厅帮好友打扫虫子剩余次数
        restaurantEventHelpLeftTimes     = 0,  -- 餐厅帮好友打霸王餐剩余次数
        restaurantEventNeedHelpLeftTimes = 0,  -- 餐厅需要好友打霸王餐剩余次数

        nextAirshipArrivalLeftSeconds    = 0,  -- 下一艘飞艇到达剩余秒数
        levelChestData = nil , -- 等级礼包数据

        achieveExp      = 0,    --成就点
        achieveLevel    = 0,    --成就等级
        shareData       = {},   --分享相关信息

        -------------------推广员相关-----------------------
        qrCodeImgLink  = '',     -- 二维码 链接
        qrCodeImgMd5  = '',      -- 二维码 md5
        -------------------留言板-----------------------
        personalMessage                  = 0,  -- 是否有最新的留言
        isLockPhone                      = 0 , -- 是否开放手机号绑定
        -------------------聊天-----------------------
        worldChannelMaxRoom = 100, -- 世界聊天房间数量
        -------------------工会-----------------------
        unionId                = nil,     -- 工会id
        unionName              = nil,     -- 工会名称
        unionHomeData          = {},      -- 工会主页数据
        unionPoint             = 0,       -- 工会勋章
        unionTaskRemainSeconds = 0,       -- 工会任务剩余秒数
        unionPet               = {},      -- 工会幼崽信息
        -------------------老玩家召回------------------
        recall                 = 0,       -- 老玩家召回 1:打开 0:关闭
        isRecalled             = 0,       -- 是否回归老玩家 1:是 0:否
        isVeteran              = 0,       -- 是否老玩家 1:是 0:否
        recallPlayerName       = '',      -- 召回人名称
        recallPlayerServerId   = 0,       -- 召回人区服
        recallCode             = '',      -- 召回码
        recallLeaveDayNum      = 0,       -- 离开多少天
        recallPresent          = {},      -- 回归老玩家奖励
        showRedPointForRecallTask       = false,   -- 老玩家召回任务小红点显示
        showRedPointForMasterRecalled   = false,   -- 成功召回其他人小红点显示
        showRedPointForRecallH5         = false,   -- 老玩家H5界面可以领奖小红点显示

        -------------------日本-----------------------
        jpAge                  = 0,       -- 日本服年龄 0:未设置 1:16- 2:16-19 3:19+
        jpAgePaymentLimitLeft  = -1,      -- 日本服年龄充值剩余额度 -1:无限制

        returnRewards          = {},      -- 流失玩家邮件奖励
        ---------------钓场相关字段添加--------------------------
        fishPopularity              = 0 ,       -- 人气度
        fishPlaceLevel              = 0 ,       -- 钓场等级
        -- 周年庆的相关字段
        voucherNum                  = 0  ,
        expBuff                     = {},
        backOpenLeftSeconds         = 0 ,       -- 回归福利倒计时
        showRedPointForBack         = false ,   -- 回归福利小红点显示
        birthday                    = '',
        foodCompareResultAck        = 1,
        battleCardPoint             = 0, -- 打牌货币
        clientData                  = {}, -- 客户端数据
        cardFragmentM               = 0, -- M卡牌碎片数量
        cardFragmentSP              = 0, -- SP卡牌碎片数量
        championshipPoint           = 0, -- 武道会货币
        cardCollectionBookMap       = {}, -- 卡牌收藏册，KEY: 收藏册ID, VALUE:已完成的任务ID list
        ---------------猫屋相关货币添加--------------------------
        houseCatCopperPoint         = 0, -- 猫铜币
        houseCatSilverPoint         = 0, -- 猫银币
        houseCatGoldPoint           = 0, -- 猫金币
        houseCatStudyPoint          = 0, -- 猫学习币
        equippedHouseCat            = {}, -- 装备的猫咪
        equippedHouseCatTimeStamp   = 0, 
        ----------------------自定义卡牌分组---------------------
        cardCustomGroup             = {}, -- 自定义卡牌分组
    })
end

--[[
--@id 根据id得到服务员所在的位置id
--]]
function GameManager:GetWaiterLocateId(id)
    if self.userInfo.waiter then
        local tIdx = 1
        for idx,val in pairs(self.userInfo.waiter) do
            if checkint(val) == checkint(id) then
                tIdx = checkint(idx)
                break
            end
        end
        if tIdx > 1 then
            tIdx = tIdx - 3
        end
        return tIdx
    end
end

--[[
初始化一下缓存数据的逻辑
--]]
function GameManager:InitialUserInfo( )
	self.userInfo         = {
		userId              = 0,
		uname               = '',
		upass               = '',
		userSdkId           = 0,
        has_realauth        = 1,
        access_token        = '',
        app_id              = '',
        idNo                = "",
        is_guest            = 0,
		accessToken         = '',
		isDefault           = 0,
		sessionId           = '',
		isGuest             = 1,
		servers             = {},
		serverId            = 0,
		lastLoginServerId   = 0,
		roleCtime           = 0,
		tomorrowLeftSeconds = 0,
		serverTime          = 0,  -- 服务器时间(无时区，GMT+0 秒数)
        serverTimeOffset    = 0,  -- 服务器时区(秒数，例如: GMT+8 = 8*60*60 = 28800)
		loginClientTime     = os.time(),
        fbId                = 0,
        headUrl             = '',
        nickname            = '',
	}
    self:RestorePlayerData()
end


--[[
初始化用户信息集
@param playerInfo 用户信息
--]]
function GameManager:UpdatePlayer( playerInfo, isSync )
    local t = checktable(playerInfo)
    if t.serverTime then
        self.userInfo.serverTime = checkint(t.serverTime)
        self.userInfo.loginClientTime = os.time()
        profileTimestamp = checkint(t.serverTime)
    end
    if t.createTime then
        self.userInfo.roleCtime = checkint(t.createTime)
    end
    if t.tomorrowLeftSeconds then
        self.userInfo.tomorrowLeftSeconds = checkint(t.tomorrowLeftSeconds)
    end
    if t.serverTimeOffset then
        self.userInfo.serverTimeOffset = checkint(t.serverTimeOffset)
    end
    if t.playerId then
        self.userInfo.playerId = checkint(t.playerId) or 0
    end
    
    if t.encryptPlayerId then
        self.userInfo.encryptPlayerId = string.urlencode(t.encryptPlayerId)
    end

    if t.newestAreaId then
        self.userInfo.newestAreaId = checkint(t.newestAreaId)
    end

    if t.tip then
        self.userInfo.tip = checkint(t.tip)
    end
    if t.medal then
        self.userInfo.medal = checkint(t.medal)
    end
    if t.kofPoint then
        self.userInfo.kofPoint = checkint(t.kofPoint)
    end
    if t.newKofPoint then
        self.userInfo.newKofPoint = checkint(t.newKofPoint)
    end
    if t.gold then
        self.userInfo.gold = checkint(t.gold)
    end
    if t.voucherNum then
        self.userInfo.voucherNum = checkint(t.voucherNum)
    end
    if t.unionPoint then
        self.userInfo.unionPoint = checkint(t.unionPoint)
    end
    if t.commerceReputation then
        self.userInfo.commerceReputation = checkint(t.commerceReputation)
    end
    if t.isChangeName then
        self.userInfo.isChangeName = checkint(t.isChangeName)
    end
    if t.diamond then
        self.userInfo.diamond = checkint(t.diamond) or 0
    end
    if t.freeDiamond then
        self.userInfo.freeDiamond = checkint(t.freeDiamond) or 0
    end
    if t.paidDiamond then
        self.userInfo.paidDiamond = checkint(t.paidDiamond) or 0
    end
    if t.ftMemberPointOpened  then
        self.userInfo.ftMemberPointOpened  = checkint(t.ftMemberPointOpened ) or 0
    end
    if t.petCoin then
        self.userInfo.petCoin = checkint(t.petCoin or 0)
    end
    if t.playerName then
        self.userInfo.playerName = t.playerName
    end
    if t.popularity then
        self.userInfo.popularity = t.popularity
    end
    if t.highestPopularity then
        self.userInfo.highestPopularity = t.highestPopularity
    end
    if t.mainExp then
        self.userInfo.mainExp = checkint(t.mainExp)
    end
    if t.avatar then
        self.userInfo.avatar = t.avatar
    end
    if t.playerSign then
        self.userInfo.playerSign = t.playerSign
    end
    if t.avatarFrame then
        self.userInfo.avatarFrame =  CommonUtils.GetAvatarFrame( t.avatarFrame)
    end
    if t.guide then
        --guide modules
        self.userInfo.guide = checktable(t.guide)
    end
    if t.isLockPhone then
        self.userInfo.isLockPhone = checkint(t.isLockPhone)
    end
    if t.artifactQuest then
        self.userInfo.artifactQuest = t.artifactQuest
    end
    --居情任务
    if t.newestPlotTask then
        --主线点
        self.userInfo.newestPlotTask = t.newestPlotTask
        if checkint(t.newestPlotTask.status) == 2 then
            if CommonUtils.GetConfig('quest', 'questPlot', t.newestPlotTask.taskId) then
                local tempTab = CommonUtils.GetConfig('quest', 'questPlot', t.newestPlotTask.taskId)
                if  checkint(tempTab.taskType) == 8 or checkint(tempTab.taskType) == 9 then
                    self.userInfo.storyTasks[string.format('%d_%d',Types.TYPE_STORY, checkint(t.newestPlotTask.taskId))] = {id = checkint(t.newestPlotTask.taskId), type = Types.TYPE_STORY}
                end
            end
        end
    end
    if t.branchList then
        --支线点
        self.userInfo.branchList = t.branchList
        for id,val in pairs(t.branchList) do
            if checkint(val.status) == 2 then
                if CommonUtils.GetConfig('quest', 'branch', id) then
                    local tempTab = CommonUtils.GetConfig('quest', 'branch',id)
                    if  checkint(tempTab.taskType) == 8 or checkint(tempTab.taskType) == 9 then
                        self.userInfo.storyTasks[string.format('%d_%d',Types.TYPE_BRANCH, checkint(id))] = {id = id, type = Types.TYPE_BRANCH, status = checkint(val.status), hasDrawn = checkint(val.hasDrawn)}
                    end
                end
            end
        end
    end
    if t.tcp then
        local hostsInfos = string.split(t.tcp, ':')
        Platform.TCPHost = hostsInfos[1]--将tcpip加上
        Platform.TCPPort = checkint(hostsInfos[2])--将tcpip加上
    end
    if t.chatRoomTcp then
        local hostsInfos = string.split(t.chatRoomTcp, ':')
        Platform.ChatTCPHost = hostsInfos[1]--将tcpip加上
        Platform.ChatTCPPort = checkint(hostsInfos[2])--将tcpip加上
    end
    if t.battleCardTcp then
        local hostsInfos = string.split(t.battleCardTcp, ':')
        Platform.TTGameTCPHost = hostsInfos[1]--将tcpip加上
        Platform.TTGameTCPPort = checkint(hostsInfos[2])--将tcpip加上
    end
    if t.backpack then
        -- self.userInfo.backpack = checktable(t.backpack)
        for k,v in pairs(checktable(t.backpack)) do
            local temp_tab = {}
            temp_tab.goodsId = checkint(k) or 0
            temp_tab.amount = checkint(v) or 0
            temp_tab.IsNew = 0
            table.insert(self.userInfo.backpack,temp_tab)
        end
    end
    if t.cards then
        for k,v in pairs(t.cards) do
            v.isNew = 1
        end
        self.preDownloadCardConfIdList_ = {}
        self.userInfo.cards = checktable(t.cards)
        local cardConf = CommonUtils.GetConfigAllMess('card' , 'card')
        --调整记录位置信息的逻辑
        for name,val in pairs(self.userInfo.cards) do
            if not cardConf[tostring(val.cardId) ] then
                self.userInfo.cards[tostring(val.id)] = nil
            end
            if val.place and table.nums(val.place) > 0 then
                local t = {}
                for _,placeId in pairs(val.place) do
                    t[tostring(placeId)] = placeId
                end
                self.userInfo.places[tostring(val.id)] = t
            end
            table.insert(self.preDownloadCardConfIdList_, val.cardId)
        end
        self:SetGemData()
        if DYNAMIC_LOAD_MODE then
            self:startPreDownloadCheckinCardAssets_()
        end
    end
    if t.feedLeftTimes then
        --12点同步数据的时候同步所卡牌的数据剩余次数
        for id,data in pairs(t.feedLeftTimes) do
            if self.userInfo.cards[tostring(id)] then
                self.userInfo.cards[tostring(id)].feedLeftTimes = checktable(data)
            end
        end
    end
    if t.feedTimes then
        self.userInfo.feedTimes = checkint(t.feedTimes)
    end
    if t.cardSkins then
        self.userInfo.cardSkins = t.cardSkins
    end
    -- 点券购买
    if t.ftPoint then
        self.userInfo.ftPoint =  checkint(t.ftPoint)
    end

    if t.mission then
        self.userInfo.mission = checktable(t.mission)
    end
    if t.allTeams then
        self.userInfo.teamFormation = checktable(t.allTeams)
        self.userInfo.operationTeamFormation = clone(self.userInfo.teamFormation )
    end
    if t.unlockTeamNeed then
        self.userInfo.unlockTeamNeed = checktable(t.unlockTeamNeed)
    end
    if t.newestHardQuestId then
        self.userInfo.newestHardQuestId = checkint(t.newestHardQuestId)
    end
    if t.newestInsaneQuestId then
        self.userInfo.newestInsaneQuestId = checkint(t.newestInsaneQuestId)
    end
    if t.level then
        self.userInfo.level = checkint(t.level)
        self:UpdatePlayerNewestQuestId()
    end
    if t.restaurantLevel then
        local level = checkint(t.restaurantLevel)
        self.userInfo.restaurantLevel = level
    end
    if t.kitchenAssistantId then
        self.userInfo.kitchenAssistantId = checkint(t.kitchenAssistantId)
    end
    if t.takeawayAssistantId then
        self.userInfo.takeAwayAssistantId = checkint(t.takeawayAssistantId)
    end
    if t.lobbyAssistantId then
        self.userInfo.lobbyAssistantId = checkint(t.lobbyAssistantId)
    end
    if t.questStory then
        self.userInfo.questStory = t.questStory
        -- init plot remind data
        self:InitPlotQuestConfDatas()
    end
    if t.newestQuestId then
        self.userInfo.newestQuestId = checkint(t.newestQuestId)
        -- newestQuestId change reload plot remind data
        app.badgeMgr:InitPlotRemindData()
    end

    if t.skill then
        self.userInfo.skill = t.skill
    end
    if t.allSkill then
        self.userInfo.allSkill = t.allSkill
    end
    if t.pets then
        self.userInfo.pets = t.pets
    end
    if t.buyGoldRestTimes then
        self.userInfo.buyGoldRestTimes = t.buyGoldRestTimes
    end
    if t.freeGoldLeftTimes then
        self.userInfo.freeGoldLeftTimes = t.freeGoldLeftTimes
    end
    if t.buyHpRestTimes then
        self.userInfo.buyHpRestTimes = t.buyHpRestTimes
    end
    if t.allGrades then
        self.userInfo.questGrades = t.allGrades
    end
    if t.allQuestChallengeTimes then
        self.userInfo.allQuestChallengeTimes = t.allQuestChallengeTimes
    end
    if t.cookingPoint then
        self.userInfo.cookingPoint = checkint(t.cookingPoint) or 0
    end
    if t.kitchenStoves  then
        self.userInfo.kitchenStoves = t.kitchenStoves
    end
    if t.friendList then
        self.userInfo.friendList = t.friendList
    end
    if t.nextHpSeconds then
        self.userInfo.nextHpSeconds = t.nextHpSeconds
    end
    if t.hpRecoverSeconds then
        self.userInfo.hpRecoverSeconds = t.hpRecoverSeconds
    end
    if t.blacklist then
        self.userInfo.blacklist = checktable(t.blacklist)
    end
    if t.artifactGuide then
        -- 0:未开启 1：奖励未领取 2：奖励已领取
        self.userInfo.artifactGuide = checkint(t.artifactGuide)
    end
    if t.cardFragmentM then
        self.userInfo.cardFragmentM = checkint(t.cardFragmentM)
    end
    if t.cardFragmentSP then
        self.userInfo.cardFragmentSP = checkint(t.cardFragmentSP)
    end
    if t.cardCollectionBook then
        self.userInfo.cardCollectionBookMap = {}
        for groupId, taskIdList in pairs(checktable(t.cardCollectionBook)) do
            self.userInfo.cardCollectionBookMap[checkint(groupId)] = {}
            for _, taskId in ipairs(taskIdList) do
                self.userInfo.cardCollectionBookMap[checkint(groupId)][checkint(taskId)] = true
            end
        end
    end
    -------------------------------------------
    -- 活动相关
    if t.newbie15Day then
        self.userInfo.newbie15Day = t.newbie15Day
    end
    if t.permanentSinglePay then
        self.userInfo.permanentSinglePay = checkint(t.permanentSinglePay)
    end
    if t.levelAdvanceChest then
        self.userInfo.levelAdvanceChest = checkint(t.levelAdvanceChest)
    end
    if t.levelReward then
        self.userInfo.levelReward = checkint(t.levelReward)
    end
    if t.firstPay then
        self.userInfo.firstPay = checkint(t.firstPay)
    end
    if t.accumulativePay then
        self.userInfo.accumulativePayTwo = checkint(t.accumulativePay)
    end
    if t.firstPayRewards then
        self.userInfo.firstPayRewards = t.firstPayRewards
    end
    if t.timezone then
        self.userInfo.timezone = -checkint(t.timezone) * 3600
    end
    if t.loveBentoConf then -- 爱心便当活动数据
        self.userInfo.loveBentoData = t.loveBentoConf
        for i, v in pairs(self.userInfo.loveBentoData) do
            local startTimeData = string.split(v.startTime, ':')
            local startTime = l10nHours(startTimeData[1], startTimeData[2]):fmt('%H')
            local originalTime = v.startTime
            if isElexSdk() then
                startTime = elexBentoTimeChange(startTimeData[1], startTimeData[2]):fmt('%H')
                originalTime = elexBentoServerTimeChange(startTimeData[1], startTimeData[2]):fmt('%H')
            end
            PUSH_LOCAL_TIME_NOTICE.LOVE_FOOD_RECOVER_TYPE[tostring(i)].time = checkint(startTime)
            PUSH_LOCAL_TIME_NOTICE.LOVE_FOOD_RECOVER_TYPE[tostring(i)].originalTime = originalTime
            PUSH_LOCAL_TIME_NOTICE.LOVE_FOOD_RECOVER_TYPE[tostring(i)].startTime =  v.startTime
            PUSH_LOCAL_TIME_NOTICE.LOVE_FOOD_RECOVER_TYPE[tostring(i)].title = v.name

        end
    end
    if t.publicOrderRefreshTime and type(t.publicOrderRefreshTime) == 'table' then
        for i, v in pairs(t.publicOrderRefreshTime ) do
            local startTimeData = string.split(v, ':')
            local startTime = l10nHours(startTimeData[1], startTimeData[2]):fmt('%H')
            PUSH_LOCAL_TIME_NOTICE.PUBLISH_ORDER_RECOVER_TYPE[tostring(i)].time = checkint(startTime)
            PUSH_LOCAL_TIME_NOTICE.PUBLISH_ORDER_RECOVER_TYPE[tostring(i)].originalTime = v
        end
    end
    if t.activityAd then
        self.userInfo.activityAd   = checktable(t.activityAd)
        self.userInfo.isShowPoster = table.nums(self.userInfo.activityAd) > 0
    end
    if t.restaurantActivity then

        self.userInfo.restaurantActivity = checktable(t.restaurantActivity)

        if app.activityMgr:isOpenLobbyFestivalActivity() then
            local activityRecipes = self.userInfo.restaurantActivity.content.recipes
            if activityRecipes then
                for i,v in pairs(activityRecipes) do
                    self.userInfo.restaurantActivityMenuData[tostring(v.recipe)] = v
                end
            end
            app.activityMgr:startLobbyFestivalActivity()
            -- 如果是同步数据来的  则 重新初始化 菜谱数据
            if isSync then
                app.activityMgr:AddLobbyActivityData()
                -- app.cookingMgr:InitialRecipeAllStyles()
            end
            AppFacade.GetInstance():DispatchObservers(POST.Activity_Draw_restaurant.sglName, self.userInfo.restaurantActivity)
        end
    end
    if t.restaurantActivityPreview then
        self.userInfo.restaurantActivityPreview = checktable(t.restaurantActivityPreview)
        -- self.userInfo.restaurantActivityPreview.leftSeconds = 30
        if app.activityMgr:isOpenLobbyFestivalPreviewActivity() then
            app.activityMgr:startLobbyFestivalPreviewActivity()
            AppFacade.GetInstance():DispatchObservers(UPDATE_LOBBY_FESTIVAL_ACTIVITY_PREVIEW_UI, self.userInfo.restaurantActivityPreview)
        end
    end
    if t.channelProducts then
        self.userInfo.channelProducts = checktable(t.channelProducts)
    end
    if t.summerActivity then
        self.userInfo.summerActivity = checkint(t.summerActivity)
    end
    if t.comparisonActivity then
        self.userInfo.comparisonActivity = checkint(t.comparisonActivity)
    end
    if t.comparisonActivityTime then
        self.userInfo.comparisonActivityTime = checkint(t.comparisonActivityTime)
    end
    if t.isOpenedAnniversary then
        self.userInfo.isOpenedAnniversary = checkint(t.isOpenedAnniversary)
    end
    if t.isOpenedAnniversaryPV then
        self.userInfo.isOpenedAnniversaryPV = checkint(t.isOpenedAnniversaryPV)
    end
    if t.isOpenedAnniversary2019PV then
        self.userInfo.isOpenedAnniversary2019PV = checkint(t.isOpenedAnniversary2019PV)
    end
    if t.isOpenedAnniversary2020PV then
        self.userInfo.isOpenedAnniversary2020PV = checkint(t.isOpenedAnniversary2020PV)
    end
    if t.payLevelRewardOpened then
        self.userInfo.payLevelRewardOpened = checkint(t.payLevelRewardOpened)
    end
    if t.isPayLoginRewardsOpen then
        self.userInfo.isPayLoginRewardsOpen = checkint(t.isPayLoginRewardsOpen)
    end
    if t.isUltimateBattleOpen then
        self.userInfo.isUltimateBattleOpen = checkint(t.isUltimateBattleOpen)
    end
    if t.newbieAccumulativePay then
        self.userInfo.newbieAccumulativePay = checkint(t.newbieAccumulativePay)
    end
    if t.newbie14TaskRemainTime then
        self.userInfo.newbie14TaskRemainTime = checkint(t.newbie14TaskRemainTime)
    end
    if t.isOpenTransfer then
        self.userInfo.isOpenTransfer = checkint(t.isOpenTransfer)
    end
    -------------------------------------------
    -- 聊天
    if t.worldChannelMaxRoom then -- 世界聊天房间数量
        self.userInfo.worldChannelMaxRoom = checkint(t.worldChannelMaxRoom)
    end

    --小红点判断-----
    if t.tips then
        local dataMgr = self:GetDataManager()
        --冰场
        if t.tips.clock and checkint(t.tips.clock[JUMP_MODULE_DATA.ICEROOM]) > 0 then
            self.userInfo.iceroomLeftSeconds = checkint(t.tips.clock[JUMP_MODULE_DATA.ICEROOM])
        end
        -- 老玩家召回任务小红点显示
        if t.tips.clock and t.tips.clock[JUMP_MODULE_DATA.RECALL] then
            self.userInfo.showRedPointForRecallTask = true
        end
        -- 老玩家H5界面可以领奖小红点显示
        if t.tips.clock and t.tips.clock[JUMP_MODULE_DATA.RECALLH5] then
            self.userInfo.showRedPointForRecallH5 = true
        end
        -- 老玩家受邀请回归小红点显示
        if t.tips.clock and t.tips.clock[JUMP_MODULE_DATA.RECALLEDMASTER] then
            self.userInfo.showRedPointForMasterRecalled = true
        end

        if t.tips.clock and t.tips.clock[JUMP_MODULE_DATA.EXPLORE_SYSTEM] then
            self.userInfo.exploreSystemLeftSeconds = checkint(t.tips.clock[JUMP_MODULE_DATA.EXPLORE_SYSTEM])
            if self.userInfo.exploreSystemLeftSeconds <= 0 then
                self:SetExploreSystemRedPoint(1)
            end
        end
        --堕神灵体净化时间完成时
        if t.tips.clock and t.tips.clock[JUMP_MODULE_DATA.PET] then
            self.userInfo.petPurgeLeftSeconds = checkint(t.tips.clock[JUMP_MODULE_DATA.PET])
            if self.userInfo.petPurgeLeftSeconds <= 0 then
                self.userInfo.showRedPointForPetPurge = true
                dataMgr:AddRedDotNofication(tostring(RemindTag.PET),RemindTag.PET, "[堕神进入游戏]-UpdatePlayer")
                AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.PET})
            end
        end
        if t.tips.personalMessage then
            self.userInfo.personalMessage = t.tips.personalMessage
        end
        if t.tips.newbieTask then
            if t.tips.newbieTask == 0 then
                self.userInfo.showRedPointForNewbieTask = false
            else
                self.userInfo.showRedPointForNewbieTask = true
            end
        end
        if t.tips.back then
            if t.tips.back == 0 then
                self.userInfo.showRedPointForBack = false
            else
                self.userInfo.showRedPointForBack = true
            end
        end
        if t.tips.levelChest then
            self.userInfo.tips.levelChest = checkint(t.tips.levelChest)
        end
        if t.tips.seasonActivity  then
            self.userInfo.tips.seasonActivity = checkint(t.tips.seasonActivity)

            if t.tips.seasonActivityTickets  then
                self.userInfo.seasonActivityTickets = t.tips.seasonActivityTickets
            end
            self.userInfo.seasonTicketData = app.activityMgr:GetTicketReciveData()
        end
        if t.triggerChest then
            self.userInfo.triggerChest = t.triggerChest
            for _, v in ipairs(self.userInfo.triggerChest) do
                app.activityMgr:AddLimiteGiftTimer(v)
            end
        end
        --[[
		local dataMgr = self:GetDataManager()
		if t.tips.recoverCard then
			local no = 0
			for id,v in pairs(t.tips.recoverCard) do
				no = no + checkint(v)
			end
			if no > 0 then
				dataMgr:AddRedDotNofication(tostring(RemindTag.ICEROOM),RemindTag.ICEROOM)
			else
				dataMgr:ClearRedDotNofication(tostring(RemindTag.ICEROOM),RemindTag.ICEROOM)
			end
		else
			dataMgr:ClearRedDotNofication(tostring(RemindTag.ICEROOM),RemindTag.ICEROOM)
		end
        --]]
        --灶台

        if t.tips.finishFoods then
            --已完成的灶台列表
            local no = 0
            for id,v in pairs(t.tips.finishFoods) do
                no = no + checkint(v)
            end
            if no > 0 then
                dataMgr:AddRedDotNofication(tostring(RemindTag.MANAGER),RemindTag.MANAGER,"GameManager:UpdatePlayer")
            else
                dataMgr:ClearRedDotNofication(tostring(RemindTag.MANAGER),RemindTag.MANAGER,"GameManager:UpdatePlayer")
            end
        else
            dataMgr:ClearRedDotNofication(tostring(RemindTag.MANAGER),RemindTag.MANAGER,"GameManager:UpdatePlayer")
        end
        -- 邮箱
        if t.tips.prize then
            if checkint(t.tips.prize) == 0 then
                dataMgr:ClearRedDotNofication(tostring(RemindTag.MAIL),RemindTag.MAIL)
            else
                dataMgr:AddRedDotNofication(tostring(RemindTag.MAIL),RemindTag.MAIL)
            end
        end
        if t.tips.clock then
            self.userInfo.clock =  t.tips.clock
        end
        if t.tips.newbie15Day then
            self.userInfo.tips.newbie15Day  = t.tips.newbie15Day
            self.userInfo.isShowNewbie15Day = checkint(self.userInfo.newbie15Day) == 1 and checkint(self.userInfo.tips.newbie15Day) == 1
        end
        if t.tips.monthlyLogin then
            self.userInfo.tips.monthlyLogin  = t.tips.monthlyLogin
            self.userInfo.isShowMonthlyLogin = checkint(self.userInfo.tips.monthlyLogin) == 1
        end
        if t.tips.mainTask then
            self.userInfo.achievementCacheData_.canReceiveCount = checkint(t.tips.mainTask)
        end
        if t.tips.serverTask then
            for i,v in ipairs(t.tips.serverTask) do
                self.userInfo.serverTask[tostring(v)] = 1
            end
        end
        if t.tips.accumulativePay then
            for i,v in ipairs(t.tips.accumulativePay) do
                self.userInfo.accumulativePay[tostring(v)] = 1
            end
        end
        if t.tips.permanentSinglePay then
            self.userInfo.tips.permanentSinglePay = checkint(t.tips.permanentSinglePay)
        end
        if t.tips.login then
            for i,v in ipairs(t.tips.login) do
                self.userInfo.login[tostring(v)] = 1
            end
        end
        if t.tips.cvShare then
            for i,v in ipairs(t.tips.cvShare) do
                self.userInfo.cvShare[tostring(v)] = 1
            end
        end
        if t.tips.unionTask then
            self.userInfo.unionTaskCacheData_.canReceiveCount = checkint(t.tips.unionTask)
        end
        if t.tips.binggoTask then
            -- dump(t.tips.binggoTask, 'dnnnnnnnnnnnwnnkwahefknak')
            self.userInfo.binggoTask = checktable(t.tips.binggoTask)
        end
        if t.tips.zoneCuisine then
            self.userInfo.zoneCuisine =  checkint(t.tips.zoneCuisine)
            if checkint(self.userInfo.zoneCuisine) == 0 then
                dataMgr:ClearRedDotNofication(tostring(RemindTag.TASTINGTOUR),RemindTag.TASTINGTOUR)
            else
                dataMgr:AddRedDotNofication(tostring(RemindTag.TASTINGTOUR),RemindTag.TASTINGTOUR)
            end
        end
        if t.tips.worldBossTestReward then
            self.userInfo.worldBossTestReward = checkint(t.tips.worldBossTestReward)
        end
        if t.tips.levelReward then
            self.userInfo.tips.levelReward = checkint(t.tips.levelReward)
        end
        if t.tips.newbieAccumulatePay then
            self.userInfo.tips.newbieAccumulatePay = checkint(t.tips.newbieAccumulatePay)
        end
        if t.tips.newSummerActivity then -- 杀人案（19夏活）点数奖励可领取
            self.userInfo.tips.newSummerActivity = checkint(t.tips.newSummerActivity)
            if checkint(t.tips.newSummerActivity) == 0 then
                dataMgr:ClearRedDotNofication(tostring(RemindTag.MURDER),RemindTag.MURDER)
            else
                dataMgr:AddRedDotNofication(tostring(RemindTag.MURDER),RemindTag.MURDER)
            end
        end
        if t.tips.continuousActive then -- 连续活跃活动奖励可领取
            self.userInfo.tips.continuousActive = checkint(t.tips.continuousActive)
        end
        if t.tips.artifactGuide and checkint(t.tips.artifactGuide) == 1 then -- 神器引导
            dataMgr:AddRedDotNofication(tostring(RemindTag.ARTIFACT_GUIDE),RemindTag.ARTIFACT_GUIDE)
        end
        if t.tips.newbie14Task then -- 新手福利
            self.userInfo.tips.newbie14Task = checkint(t.tips.newbie14Task)
        end

        -- 武道会是否开启(1是 0否)
        self.userInfo.tips.championship = checkint(t.tips.championship)
    end
    if t.isBindAccountDrawn then
        self.userInfo.isBindAccountDrawn = checkint(t.isBindAccountDrawn)
    end
    --------------------------------------------------------
    -- 服务器无关 缓存数据
    if t.localCurrentQuestId then
        self.userInfo.localCurrentQuestId = checkint(t.localCurrentQuestId)
    end
    if t.localCurrentEquipedMagicFoodId then
        self.userInfo.localCurrentEquipedMagicFoodId = checkint(t.localCurrentEquipedMagicFoodId)
    end
    if t.localCurrentBattleTeamId then
        self.userInfo.localCurrentBattleTeamId = checkint(t.localCurrentBattleTeamId)
    end
    if t.localBattleAccelerate then
        self.userInfo.localBattleAccelerate = checkint(t.localBattleAccelerate)
        -- 写一次本地文件
        self:SetLocalBattleAccelerate(self.userInfo.localBattleAccelerate)
    end
    if  t.serverTime then
        self.userInfo.serverTime =  t.serverTime  or 0
    end
    if  t.cookingStyles then
        self.userInfo.cookingStyles =  t.cookingStyles  or {}
        app.cookingMgr:InitialRecipeAllStyles()
    end
    if t.isFirstPhoneLock then
        self.userInfo.isFirstPhoneLock = checkint( t.isFirstPhoneLock )
    end
    if t.phone and t.phone ~= '' then
        self.userInfo.phone =  t.phone
    end
    if t.openCodeModule then
        self.userInfo.openCodeModule  =  checkint(t.openCodeModule) == 1 and  true or false
    end
    if t.isRecommendOpen then
        self.userInfo.isRecommendOpen  =  checkint(t.isRecommendOpen) == 1 and  true or false
    end
    if t.employee then
        self.userInfo.employee = checktable(t.employee)
        for k,v in pairs(t.employee) do
            local typee =  CommonUtils.GetConfigNoParser('restaurant','employee',k).type
            if typee == LOBBY_SUPERVISOR then
                self.userInfo.supervisor[k] = v
            elseif typee == LOBBY_CHEF then
                self.userInfo.chef[k] = v
            elseif typee == LOBBY_WAITER then
                self.userInfo.waiter[k] = v
            end
        end
    end

    if t.restaurantLevel then
        local level = checkint(t.restaurantLevel)
        self.userInfo.restaurantLevel = level
    end

    if t.cardStory then
        self.userInfo.cardStory = t.cardStory
    end
    if t.cardVoice then
        self.userInfo.cardVoice = t.cardVoice
    end
    if t.monster then
        self.userInfo.monster =  t.monster
    end
    if t.defaultCardId then
        self.userInfo.signboardId =  t.defaultCardId
    end
    if t.hp then
        self:UpdateHp(t.hp)
    end
    if t.member then
        self.userInfo.member = t.member
        self:memberDownCount()
    end

    if t.newbieTaskRemainTime then
        self.userInfo.newbieTaskRemainTime = checkint(t.newbieTaskRemainTime)
    end

    --------------------------------------------------------
    if t.restaurantCleaningLeftTimes then
        self.userInfo.restaurantCleaningLeftTimes = checkint(t.restaurantCleaningLeftTimes)
    end
    if t.restaurantEventHelpLeftTimes then
        self.userInfo.restaurantEventHelpLeftTimes = checkint(t.restaurantEventHelpLeftTimes)
    end
    if t.restaurantEventNeedHelpLeftTimes then
        self.userInfo.restaurantEventNeedHelpLeftTimes = checkint(t.restaurantEventNeedHelpLeftTimes)
    end

    if t.nextAirshipArrivalLeftSeconds then
        self.userInfo.nextAirshipArrivalLeftSeconds = checkint(t.nextAirshipArrivalLeftSeconds)
        if CommonUtils.GetModuleAvailable(MODULE_SWITCH.AIR_TRANSPORTATION) then self:startAirShipCountDown() end
    end
    if t.levelChest then
        if checkint(t.levelChest) == 0   then
            self.userInfo.levelChest = false
        elseif checkint(t.levelChest) == 1   then
            self.userInfo.levelChest = true
        end
    end
    if t.achieveExp then
        self.userInfo.achieveExp = checkint(t.achieveExp)
    end
    if t.achieveLevel then
        self.userInfo.achieveLevel = checkint(t.achieveLevel)
    end
    if t.shareData then
        self.userInfo.shareData = checktable(t.shareData)
    end
    if t.qrCodeImgLink then
        self.userInfo.qrCodeImgLink = t.qrCodeImgLink
    end
    if t.qrCodeImgMd5 then
        self.userInfo.qrCodeImgMd5 = t.qrCodeImgMd5
    end
    -- about union
    if t.union and checkint(t.union.id) > 0 then
        
        if t.union.id then
            self.userInfo.unionId = checkint(t.union.id)
        end

        if t.union.unionPet then
            self.userInfo.unionPet = checktable(t.union.unionPet)
        end

        if t.union.taskRemainSeconds then
            self.userInfo.unionTaskRemainSeconds = checkint(t.union.taskRemainSeconds)
        end

        app.unionMgr:setUnionData({
            name  = tostring(t.union.name),
            level = checkint(t.union.level),
        })

        if t.union.partyLevel then
            app.unionMgr:setPartyLevel(t.union.partyLevel)
        end

        if t.union.partyBaseTime then
            app.unionMgr:setPartyBaseTime(t.union.partyBaseTime)
        end
    end

    if t.recall then
        self.userInfo.recall = t.recall
    end
    if t.isRecalled then
        self.userInfo.isRecalled = t.isRecalled
    end
    if t.isVeteran then
        self.userInfo.isVeteran = t.isVeteran
    end
    if t.recallPlayerName then
        self.userInfo.recallPlayerName = t.recallPlayerName
    end
    if t.recallPlayerServerId then
        self.userInfo.recallPlayerServerId = t.recallPlayerServerId
    end
    if t.recallCode then
        self.userInfo.recallCode = t.recallCode
    end
    if t.recallLeaveDayNum then
        self.userInfo.recallLeaveDayNum = t.recallLeaveDayNum
    end
    if t.recallPresent then
        self.userInfo.recallPresent = t.recallPresent
    end
    if t.fishPopularity then
        self.userInfo.fishPopularity = t.fishPopularity
    end
    if t.fishPlaceLevel then
        self.userInfo.fishPlaceLevel = checkint(t.fishPlaceLevel)
    end
    if t.returnRewards then
        self.userInfo.returnRewards = checktable(t.returnRewards)
    end
    if t.isCardCallOpen then
        self.userInfo.isCardCallOpen = checkint(t.isCardCallOpen)
    end
    if t.backOpenLeftSeconds then
        self.userInfo.backOpenLeftSeconds = checkint(t.backOpenLeftSeconds)
        if self:CheckIsBackOpen() then
            self:StartBackCountDown(self.userInfo.backOpenLeftSeconds)
        end
    end
    if t.expBuff then
        self.userInfo.expBuff = checktable(t.expBuff)
    end
    if t.birthday then
        self.userInfo.birthday = t.birthday
    end
    if t.foodCompareResultAck then
        self.userInfo.foodCompareResultAck = t.foodCompareResultAck
    end
    if t.battleCardPoint then
        self.userInfo.battleCardPoint = checkint(t.battleCardPoint)
    end

    if t.openLive2D and GAME_MODULE_OPEN.CARD_LIVE2D then
        GAME_MODULE_OPEN.CARD_LIVE2D = checkint(t.openLive2D) == 1
    end

    if t.equippedHouseCat then
        self.userInfo.equippedHouseCat = checktable(t.equippedHouseCat)
        self.userInfo.equippedHouseCatTimeStamp = os.time()
    end

    -- about: water bar
    do
        if t.barLevel then
            app.waterBarMgr:setBarLevel(t.barLevel)
        end
        if t.barPoint then
            app.waterBarMgr:setBarPoint(t.barPoint)
        end
        if t.barPopularity then
            app.waterBarMgr:setBarPopularity(t.barPopularity)
        end
    end

    -- about: cat house
    do
        if t.houseLevel then
            app.catHouseMgr:setHouseLevel(t.houseLevel)
        end
        if t.houseCatCopperPoint then
            self.userInfo.houseCatCopperPoint = checkint(t.houseCatCopperPoint)
        end
        if t.houseCatSilverPoint then
            self.userInfo.houseCatSilverPoint = checkint(t.houseCatSilverPoint)
        end
        if t.houseCatGoldPoint then
            self.userInfo.houseCatGoldPoint = checkint(t.houseCatGoldPoint)
        end
        if t.houseCatStudyPoint then
            self.userInfo.houseCatStudyPoint = checkint(t.houseCatStudyPoint)
        end
    end

    -- clientData
    do
        if t.clientData then
            self.userInfo.clientData = t.clientData
        end
    end

    -- championship
    do
        if t.championshipPoint then
            self.userInfo.championshipPoint = checkint(t.championshipPoint)
        end
    end

    -- card list group
    do
        if t.cardCustomGroup then
            self.userInfo.cardCustomGroup = {}
            for _, groupInfo in pairs(t.cardCustomGroup) do
                self.userInfo.cardCustomGroup[checkint(groupInfo.groupId)]= groupInfo
            end
        end
    end

end
function GameManager:SetIdNo(idNo)
    if idNo and (string.len(idNo) > 0) then
        self.userInfo.idNo = idNo
        self.userInfo.has_realauth = 1
        self.userInfo.is_guest = 0
    end
end

function GameManager:GetGusetDisable()
    return checkint(self.userInfo.guestDisable)
end

function GameManager:GetIdNo()
    return self.userInfo.idNo
end

-- 更新等级礼包的数据
function GameManager:UpdateAchieveExp(increaseAchieveExp)
    if increaseAchieveExp then
        self.userInfo.achieveExp = self.userInfo.achieveExp + increaseAchieveExp
    end
end

--[[
--@id --卡牌的id
--@boxId --格子id某个格的的次数,
--如果格子id不提供时得到所有的格式信息数据
--]]
function GameManager:GetRemainLoveFeedTimes(id, boxId)
    local leftTimes = 0
    if self.userInfo.cards[tostring(id)] then
        if table.nums(checktable(self.userInfo.cards[tostring(id)].feedLeftTimes)) > 0 then
            ---已存在的id

            if checktable(self.userInfo.cards[tostring(id)].feedLeftTimes)[tostring(boxId)] then
                leftTimes = checkint(checktable(self.userInfo.cards[tostring(id)].feedLeftTimes)[tostring(boxId)])
            else
                leftTimes = self.userInfo.feedTimes
                checktable(self.userInfo.cards[tostring(id)].feedLeftTimes)[tostring(boxId)] = leftTimes
            end
        else
            leftTimes = self.userInfo.feedTimes
            self.userInfo.cards[tostring(id)].feedLeftTimes = {[tostring(boxId)] = leftTimes}
        end
    end
    return leftTimes
end

--[[
--@id --卡牌id
--]]
function GameManager:UpdateRemainLoveFeedTimes(id, boxId, remainTimes)
    --新获得的卡牌，需要添加喂食的次数的逻辑
    if self.userInfo.cards[tostring(id)] then
        if table.nums(checktable(self.userInfo.cards[tostring(id)].feedLeftTimes)) > 0 then
            --表示是一个已存在的卡牌
            if remainTimes < 0 then remainTimes = 0 end
            self.userInfo.cards[tostring(id)].feedLeftTimes[tostring(boxId)] = remainTimes
        end
    end
end


function GameManager:IsOpenMapPlot()
    return GAME_MODULE_OPEN.NEW_PLOT and CommonUtils.UnLockModule(RemindTag.PLOT_COLLECT)
end


--==============================--
--desc: 创建一个倒计时
--time:2017-08-31 08:43:01
--@return
--==============================
function GameManager:CeateCountDown_(callback)
    return scheduler.scheduleGlobal(callback, 1)
end

--==============================--
--desc: 通过key 保存 或 获取 需要更新视图回调
--time:2017-08-31 08:43:01
--@return
--==============================
function GameManager:downCountUi(key, callback)
    if self.downCountUiHandler[key] then
        return self.downCountUiHandler[key]
    end
    self.downCountUiHandler[key] = callback
end


--==============================--
--desc: 通过key 移除 需要更新视图回调
--time:2017-08-31 08:43:01
--@return
--==============================
function GameManager:removeDownCountUi(key)
    self.downCountUiHandler[key] = nil
end

--==============================--
--desc: 通过key 更新与倒计时关联的ui
--time:2017-08-31 08:43:01
--@return
--==============================
function GameManager:updateDownCountUi(key, field1, field2)
    local updateCallBack = self:downCountUi(key)
    if updateCallBack then
        updateCallBack(field1, field2)
    end
end

--==============================--
--desc: 清理体力倒计时
--time:2017-08-31 08:43:01
--@return
--==============================
function GameManager:clearHpCountDown_(key)
    self:GetUserInfo().nextHpSeconds = 0
    self:GetUserInfo().totalHpSeconds = 0
    self:GetUserInfo().hpCountDownLeftSeconds = 0
    self:GetUserInfo().hpCountDownStartSeconds = 0
    self:clearSpecifyCountDown(key)
    -- local updateCallBack = self:downCountUi(key)
    -- if updateCallBack then
    --     updateCallBack()
    -- end
    self:updateDownCountUi(key)
end

--==============================--
--desc: 通过key 开启体力相关的倒计时
--time:2017-08-31 08:43:01
--@return
--==============================
function GameManager:hpCountDown_()
    local key = CommonUtils.getCurrencyRestoreKeyByGoodsId(HP_ID)
    -- 1. 当 体力达到最大值时 不创建 如果有 倒计时 直接移除 倒计时 并更新UI
    if self:isHpMax() then
        self:clearHpCountDown_(key)
        return
    end
    -- 2. 如果 体力倒计时为初始状态 则 记录 开始倒计时的时间
    if self:GetUserInfo().hpCountDownStartSeconds == 0 then
        self:GetUserInfo().hpCountDownStartSeconds = os.time()
    end

    -- local isChange = false -- 标识是否改变过hp
    -- 3. 为空 则创建 downCountHandler
    if self.downCountHandlers[key] == nil then
        -- 4. 计算 最大体力恢复时间 (计算的前提 条件  体力未达到最大值)
        local hpRecoverSeconds = checkint(self:GetUserInfo().hpRecoverSeconds) -- 一点体力恢复时间为 恒定值
        self:GetUserInfo().nextHpSeconds = (checkint(self:GetUserInfo().nextHpSeconds) <= 0 ) and hpRecoverSeconds or checkint(self:GetUserInfo().nextHpSeconds)
        local hpMaxLimit = self:GetHpMaxLimit()
        local curHp = checkint(self:GetUserInfo().hp)
        local nextHp = curHp + 1
        -- print("XXXXXXXXXXXXXXX")
        -- print(hpMaxLimit, curHp, self:GetUserInfo().nextHpSeconds)
        self:GetUserInfo().totalHpSeconds = self:GetUserInfo().nextHpSeconds + (hpMaxLimit - nextHp) * hpRecoverSeconds
        -- print(self:GetUserInfo().totalHpSeconds)
        self:GetUserInfo().hpCountDownLeftSeconds = self:GetUserInfo().totalHpSeconds
        local func = function (dt)
            -- 4.1.2 当体力改变是 重新计算  hpMaxLimit curHp
            local newHpMaxLimit = self:GetHpMaxLimit()
            if self:GetUserInfo().hp ~= curHp or newHpMaxLimit ~= hpMaxLimit then
                self:GetUserInfo().hpCountDownStartSeconds = os.time()
                hpMaxLimit = newHpMaxLimit
                curHp = self:GetUserInfo().hp
                nextHp = curHp + 1
                self:GetUserInfo().nextHpSeconds = (checkint(self:GetUserInfo().nextHpSeconds) <= 0 ) and hpRecoverSeconds or checkint(self:GetUserInfo().nextHpSeconds)
                self:GetUserInfo().totalHpSeconds = self:GetUserInfo().nextHpSeconds + (hpMaxLimit - nextHp) * hpRecoverSeconds
                -- isChange = false
                -- isChange = not self:IsUpdateHpByServer()
                -- self:IsUpdateHpByServer(false)
            end
            local timeScale = cc.Director:getInstance():getScheduler():getTimeScale()
            if timeScale <= 0 then timeScale = 1 end --防止加速后计时器变化
            -- 4.1.1 获取每次调用 该方法的 等待的时间
            local deltaTime = math.abs(os.time() - self:GetUserInfo().hpCountDownStartSeconds)
            -- print('deltaTimedeltaTime')
            -- print(deltaTime, dt, timeScale)
            -- 4.1.3 获取最大体力恢复时间
            local totalHpSeconds = self:GetUserInfo().totalHpSeconds - deltaTime
            -- print('totalHpSeconds', totalHpSeconds)
            if totalHpSeconds < 0 then
                totalHpSeconds = 0
            end
            self:GetUserInfo().hpCountDownLeftSeconds = totalHpSeconds

            -- 4.1.4 体力已达到最大值
            if curHp >= hpMaxLimit then
                self:clearHpCountDown_(key)
                return
            end

            -- 4.1.5 计算 下点体力恢复时间
            -- nextHp = curHp + 1
            self:GetUserInfo().nextHpSeconds = totalHpSeconds - (hpMaxLimit - curHp - 1) * hpRecoverSeconds
            -- print('nextHpSeconds',self:GetUserInfo().nextHpSeconds)
            -- 4.1.6 第一种情况 self:GetUserInfo().nextHpSeconds 正好为 0
            if self:GetUserInfo().nextHpSeconds <= 0 then
                -- 4.1.6.1 nextHpSeconds < 0 最少加 1  则 向下取整 在加 1
                local needAddHp = math.floor(math.abs(self:GetUserInfo().nextHpSeconds) / hpRecoverSeconds) + 1
                -- 4.1.6.2 计算 下点体力恢复时间
                self:GetUserInfo().nextHpSeconds = needAddHp * hpRecoverSeconds + self:GetUserInfo().nextHpSeconds
                -- 4.1.6.3 能修改体力
                self:GetUserInfo().hp = self:GetUserInfo().hp + needAddHp
                -- if not isChange then
                    AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{hp = self:GetUserInfo().hp})
                -- end

            end
            -- 4.1.7 更新 倒计时相关的ui
            self:updateDownCountUi(key, self:GetUserInfo().nextHpSeconds, totalHpSeconds)
            -- isChange = false
        end

        -- 4.1 创建倒计时
        local downCountHandler = self:CeateCountDown_(func)
        -- 4.2 保存倒计时 实例
        self.downCountHandlers[key] = downCountHandler
    end

end

--==============================--
--desc: 会员倒计时
--warn: 只有会员(1 或 2) 剩余时间还剩下3天是 才会 开启会员剩余倒计时
--time:2017-08-31 08:43:01
--return
--==============================--
function GameManager:memberDownCount()
    local member = nil
    local isStartDownCount = nil
    local day3 =  3 * 24 * 60 * 60
    local minLeftSeconds = 0
    local memberId = nil
    local startTime = nil
    -- if next(self:GetUserInfo().member) then
    --     self:GetUserInfo().member['1'].leftSeconds = 20
    --     self:GetUserInfo().member['2'].leftSeconds = 40
    -- end
    member = self:GetUserInfo().member
    isStartDownCount = false
    memberId = ''


    local function initDownCountData()
        minLeftSeconds = 0
         -- 1. 获取最小的月卡剩余时间
        for i,v in pairs(member) do
            if minLeftSeconds == 0 then minLeftSeconds = checkint(v.leftSeconds) end
            minLeftSeconds = math.min(minLeftSeconds, checkint(v.leftSeconds))
            if minLeftSeconds == v.leftSeconds then
                memberId = tostring(i)
            end
        end

        -- 最小倒计时 下于等于 0
        if minLeftSeconds <= 0 then isStartDownCount = false return end
        -- 获取最小月卡剩余时间时 每次都会进行 最小值比较
        -- for i,val in pairs(member) do
        --     if checkint(val.leftSeconds) == minLeftSeconds then
        --         memberId = tostring(i)
        --         break
        --     end
        -- end
        -- 2. 比较最小月卡剩余时间 是否小于 3天
        isStartDownCount = minLeftSeconds <= day3

        startTime = os.time()
    end

    initDownCountData()
    -- print('XXXXXXXXXXXXXXXXXXXXXXXX')
    -- print(memberId, minLeftSeconds)
    -- 3. 不满足倒计时开启条件 直接返回
    if not isStartDownCount then return end
    -- 4. 开启倒计时
    local key = 'memberDownCount'
    if self.downCountHandlers[key] == nil then
        local downCountHandler = self:CeateCountDown_(function ()
            -- 4.1 计算延迟时间
            local deltaTime = math.floor(os.time() - startTime)
            -- 4.2 计算会员剩余时间
            local leftSeconds = self:GetUserInfo().member[memberId].leftSeconds - deltaTime
            -- 4.3 会员到期
            if leftSeconds <= 0 then
                -- 4.3.1 记录到期会员的剩余时间
                local oldMemberTime = self:GetUserInfo().member[memberId].leftSeconds
                -- 4.3.2 移除 旧的会员
                self:GetUserInfo().member[memberId] = nil
                --维护砸金蛋免费次数
                if self:GetUserInfo().freeGoldLeftTimes[memberId] then
                    self:GetUserInfo().freeGoldLeftTimes[memberId] = nil
                end
                -- 4.3.3 倒计时为0  更新UI
                self:updateDownCountUi(key, memberId)
                -- 4.3.4 检查 self:GetUserInfo().member 是否还有 月卡
                initDownCountData()
                -- 4.3.5 有的话 重复 1 2 3步
                AppFacade.GetInstance():DispatchObservers('UPDATE_PLAYER_DATA_REQUEST')
                if isStartDownCount then
                    self:GetUserInfo().member[memberId].leftSeconds = self:GetUserInfo().member[memberId].leftSeconds - oldMemberTime
                else
                -- 4.3.6 不满足 第三步则 或 self:GetUserInfo().member 为空表 则 直接移除 倒计时
                    self:clearSpecifyCountDown(key)
                end
            end
        end)
        self.downCountHandlers[key] = downCountHandler
    end
end
--==============================--
---@Description: 根据productId 获取到相关的数据
---@param :
---@return :
---@author : xingweihao
---@date : 2019/4/13 10:47 PM
--==============================--

function GameManager:GetProductDataByProductId(id)
    local channelProducts =self:GetUserInfo().channelProducts or {}
    id = checkint(id)
    for i, v in pairs(channelProducts) do
        if checkint(v.id) == id  then
            return v
        end
    end
end
--==============================--
--desc: 清理指定的倒计时
--time:2017-08-31 08:43:01
--return
--==============================--
function GameManager:clearSpecifyCountDown(key)
    if self.downCountHandlers and self.downCountHandlers[key] then
        scheduler.unscheduleGlobal(self.downCountHandlers[key])
        self.downCountHandlers[key] = nil
    end
end

--==============================--
--desc: 清理所有的倒计时
--time:2017-08-31 08:43:01
--return
--==============================--
function GameManager:clearAllCountDown()
    if self.downCountHandlers then
        for i,v in pairs(self.downCountHandlers) do
            self:clearSpecifyCountDown(i)
        end
        self.downCountHandlers = nil
    end
end

--==============================--
--desc: 开启 分摊倒计时
--time:2017-12-18 03:48:24
--@seconds:
--@return
--==============================--
function GameManager:startAirShipCountDown(seconds)
    if seconds ~= nil then
        self.userInfo.nextAirshipArrivalLeftSeconds = checkint(seconds)
    end

    local leftTime = checkint(self.userInfo.nextAirshipArrivalLeftSeconds)

    if app.timerMgr:RetriveTimer(COUNT_DOWN_TAG_AIR_SHIP) then
        app.timerMgr:RemoveTimer(COUNT_DOWN_TAG_AIR_SHIP)
    end

    if leftTime > 0 then
        app.timerMgr:AddTimer({name = COUNT_DOWN_TAG_AIR_SHIP, countdown = leftTime, tag = RemindTag.AIRSHIP})
    elseif AppFacade.GetInstance():RetrieveMediator('AirShipHomeMediator') == nil then
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.AIRSHIP})
    end
    CommonUtils.SetPushLocalOneTypeNoticeByType(PUSH_LOCAL_NOTICE_NAME_TYPE.AIR_LIFT_RECOVER_TYPE)
end


--==============================--
--desc: 这个方法用于更新最新的最高知名度
--time:2017-04-24 11:27:57
--return
--==============================--
function GameManager:UpdateHighestPopularity(highestAmount)
	-- body
	if checkint(highestAmount) > checkint(self.userInfo.highestPopularity)  then
		self.userInfo.highestPopularity = highestAmount
	end
end

-- -- 用于记录 是否是来自服务端 推送的体力更新
-- function GameManager:IsUpdateHpByServer(isUpdateHp)
--     if isUpdateHp ~= nil then
--         self.isUpdateHp = isUpdateHp
--     end
--     self.isUpdateHp = false
--     return checkbool(self.isUpdateHp)
-- end

--[[
--更新体力
--]]
function GameManager:UpdateHp(hp)
    self.userInfo.hp = checkint(hp) or 0
    -- self:nextHpDownCount()
    -- self:totalHpDownCount()

    CommonUtils.SetPushLocalOneTypeNoticeByType(PUSH_LOCAL_NOTICE_NAME_TYPE.HP_RECOVER_TYPE)
    self:hpCountDown_()
end

--[[
--更新会员
--]]
function GameManager:UpdateMember(member)

    if member ~= nil then
        if table.nums(self:GetUserInfo().member) > 0 then
            for vipId,v in pairs(member) do
                self:GetUserInfo().member[vipId] = v
            end
        else
            self:GetUserInfo().member = member
        end
        AppFacade.GetInstance():DispatchObservers('UPDATE_PLAYER_DATA_REQUEST')
    end

end

--[[
--获取当前的区域id位置
--]]
function GameManager:GetAreaId()
    local RetriveAreaKey = string.format("AreaRetriveKey_%d",checkint(self.userInfo.playerId))
    local shareUserDefault = cc.UserDefault:getInstance()
    local sAreaId = shareUserDefault:getStringForKey(RetriveAreaKey,'1')
    local areaId = checkint(sAreaId)
    if areaId <= 0 then areaId = 1 end
    return areaId
end

--==============================--
--desc: 是否是体力最大值
--time:2017-08-31 08:43:01
--return
--==============================--
function GameManager:isHpMax()
    local hpMaxLimit = self:GetHpMaxLimit()
    local curHp = self:GetUserInfo().hp
    return checkint(curHp) >= checkint(hpMaxLimit)
end

--[[
编队是否在外卖中
n    ]]
function GameManager:isInDeliveryTeam(teamId)
	local isIn = false
    teamId = checkint(teamId)
	local  v = self.userInfo.teamFormation[teamId]
	for _, vv in pairs (v.cards) do
		local places = self:GetCardPlace(vv)
		if places[tostring(CARDPLACE.PLACE_TAKEAWAY)] then
			isIn = true
			break
		end
	end
	return isIn
end

--[[
编队状态
teamId 编队id
CardPlace  CARDPLACE状态：外卖。探索
n    ]]
function GameManager:CheckTeamState(teamId,CardPlace)
    local isIn = false
    local  v = self.userInfo.teamFormation[teamId]
    for _, vv in pairs (v.cards) do
        local places = self:GetCardPlace(vv)
        if places[tostring(CardPlace)] then
            isIn = true
            break
        end
    end
    return isIn
end
--[[
    根据队伍的id 获取到队伍的总战力
--]]
function GameManager:GetTeamTotalBattlePointByTeamId( teamId)
    ---@type CardManager
    local battlePoint = 0
    local teamData = self:getTeamCardsInfo(teamId)
    for  k , v in pairs(teamData) do
        if v.id then
            battlePoint =  battlePoint + app.cardMgr.GetCardStaticBattlePointById(checkint(v.id))
        end
    end
    return battlePoint
end

--[[
--修改编队的信息
--@param cardInfo --根据外卖车信息修改外卖队伍信息
--]]
--删除无用数据
-- function GameManager:setDeliveryTeam(carInfo)
--     local tData = {}
--     if cardInfo then
--         for k, v in pairs (carInfo) do
--             if  v.teamId and v.status ~=1  then
--                 for k,team in ipairs(self.userInfo.teamFormation) do
--                     --判断编队信息中的数据
--                     if checkint(team.teamId) == checkint(v.teamId) then
--                         table.insert(tData, team) --更新编队信息
--                     end
--                 end
--             end
--         end
--     end
--     self.userInfo.deliveryTeam = tData
-- end

function GameManager:getCustomGroupInfoByGroupId(groupId)
    local groupInfo = checktable(checktable(self.userInfo).cardCustomGroup)[checkint(groupId)]
    if not groupInfo or next(groupInfo) == nil then
        groupInfo = {groupId = groupId, name = string.fmt(__("自定义分组_num_"), {_num_ = groupId}), playerCardIds = {}}
    end
    return groupInfo
end

function GameManager:saveCustomGroupInfo(groupInfo)
    self.userInfo.cardCustomGroup[checkint(groupInfo.groupId)] = groupInfo
end
--[[
--切换区域的位置
--]]
function GameManager:SwitchAreaId(areaId)
    local oldAreaId = self:GetAreaId()
    local RetriveAreaKey = string.format("AreaRetriveKey_%d",checkint(self.userInfo.playerId))
    local shareUserDefault = cc.UserDefault:getInstance()
    shareUserDefault:setStringForKey(RetriveAreaKey, tostring(areaId))
    shareUserDefault:flush()
    if oldAreaId ~= areaId then
        PlayBGMusic()
    end
    return checkint(areaId)
end

--[[
更新背包数据
--]]

--[[
初始化用户信息集 用户身份信息
@param playerInfo 用户信息
--]]
function GameManager:UpdateAuthorInfo(playerInfo)
	local t = checktable(playerInfo)
	if t.userId then
		self.userInfo.userId = t.userId
	end
	if t.uname then
		self.userInfo.uname = tostring(t.uname)
	end
	if t.upass then
		self.userInfo.upass = tostring(t.upass)
	end
	if t.isDefault then
		self.userInfo.isDefault = checkint(t.isDefault)
	end
	if t.isGuest then
		self.userInfo.isGuest = checkint(t.isGuest)
	end
	if t.jpUdid then
		self.userInfo.jpUdid = tostring(t.jpUdid)
	end
	if t.sessionId then
		self.userInfo.sessionId = t.sessionId or ''
	end
	if t.serverId then
		self.userInfo.serverId = t.serverId or ''
	end
    if t.playerId then
		self.userInfo.playerId = t.playerId
    end
    if t.encryptPlayerId then
        self.userInfo.encryptPlayerId = string.urlencode(t.encryptPlayerId)
    end
    if t.playerName then
        self.userInfo.playerName = t.playerName
    end
    if t.servers then
        self.userInfo.servers = t.servers
    end
    if t.lastLoginServerId then
        self.userInfo.lastLoginServerId = t.lastLoginServerId
    end
    if t.bindChannel then
        local channels = {}
        for _,val in pairs(t.bindChannel) do
            print(val.loginWay)
            channels[tostring(val.loginWay)] = val
        end
        self.userInfo.bindChannels = channels
    end
    if t.idNo and (string.len(t.idNo) > 0) then
        self:SetIdNo(t.idNo)
    end
    if t.guestDisable then
        self.userInfo.guestDisable = checkint(t.guestDisable)
    end
end


--[[
--获得当前等级最大的体力上限
--]]
function GameManager:GetHpMaxLimit()
    local playerLevel = checkint(self.userInfo.level)
    local rewardsData = CommonUtils.GetConfigAllMess('levelReward','player')
    --得到奖励数据
    local level = 1 --第一级的最大限制
    if rewardsData then
        local keys = sortByKey(rewardsData)
        local maxLevel = checkint(keys[#keys])
        for i=1,maxLevel do
            local expData = rewardsData[tostring(i)] or {}
            if playerLevel < checkint(expData.level) then
                level = (i - 1)
                break
            elseif i == maxLevel and playerLevel >= checkint(expData.level) then
                level = maxLevel
                break
            end
        end
        return checkint(checktable(rewardsData[tostring(level)]).hpUpperLimit)
    end
end

--[[
根据玩家总经验更新玩家等级和经验值
@params deltaExp int 变化的经验值
--]]
function GameManager:UpdateExpAndLevel(deltaExp)
    local deltaExp = checkint(deltaExp)
    local totalExp = checkint(self.userInfo.mainExp) + deltaExp

	local oldLv = self.userInfo.level
	local level = self.userInfo.level
    local expDatas = CommonUtils.GetConfigAllMess('level', 'player')
    if expDatas then
        local keys = sortByKey(expDatas)
        local maxLevel = checkint(keys[#keys])
        for i=1,maxLevel do
            local expData = expDatas[tostring(i)]
            if totalExp < checkint(expData.totalExp) then
                level = (i - 1)
                break
            elseif i == maxLevel and totalExp >= checkint(expData.totalExp) then
                level = maxLevel
                break
            end
        end
    end
	-- 刷新玩家等级经验信息
	self.userInfo.level = level
	self.userInfo.mainExp = totalExp
    -- 刷新解锁关卡
    self:UpdatePlayerNewestQuestId()
	if oldLv < level then
		return true , oldLv , level
	else
		return false, oldLv, level
	end
end

---[[
--获取下一级别的数据
--]]
function GameManager:GetPlayerNextLevelExpData()
	local level = checkint(self.userInfo.level)
    local nextlevel = level + 1
    local expDatas = CommonUtils.GetConfigAllMess('level', 'player')
    if expDatas then
        local keys = sortByKey(expDatas)
        local maxLevel = checkint(keys[#keys])
        if nextlevel > maxLevel then nextlevel = maxLevel end
        return expDatas[tostring(level)], expDatas[tostring(nextlevel)]
    end
end


--[[
    FIXME 已弃用，现在纯跳转
--]]
function GameManager:GetAllGoodsDataByGoodsType(goodsType)
    return app.goodsMgr:GetAllGoodsDataByGoodsType(goodsType)
end
--[[
    FIXME 已弃用，现在纯跳转
--]]
function GameManager:GetAmountByIdForce(id)
    return app.goodsMgr:GetGoodsAmountByGoodsId(id)
end
--[[
    FIXME 已弃用，现在纯跳转
--]]
function GameManager:GetAmountByGoodId(id)
	return app.goodsMgr:GetGoodsAmountByGoodsId(id)
end
--[[
    FIXME 已弃用，现在纯跳转
--]]
function GameManager:GetBackPackArrayToMap()
    return app.goodsMgr:GetBackPackArrayToMap()
end
--[[
    FIXME 已弃用，现在纯跳转
]]
function GameManager:UpdateBackpackNewStatuByGoodId(id)
    app.goodsMgr:CleanBackpackNewStatuByGoodsId(id)
end
--[[
    FIXME 已弃用，现在纯跳转
--]]
function GameManager:UpdateBackpackByGoodIdCoverNum(id, amount, autoRemove)
    app.goodsMgr:SetBackpackAmountByGoodsId(id, amount, autoRemove)
end
--[[
    FIXME 已弃用，现在纯跳转
--]]
function GameManager:UpdateBackpackByGoodId(id, amount, autoRemove)
    app.goodsMgr:UpdateBackpackAmountByGoodsId(id, amount, autoRemove)
end


--[[
--更新本地缓存的avatar位置信息
--]]
function GameManager:UpdateAvatarLocalLocations(locationInfo)
    local locations = checktable(self.userInfo.avatarCacheData.location)
    local tLocation = locations[tostring(locationInfo.id)]
    if tLocation then
    else
        tLocation = {}
    end
    table.merge(tLocation, {id = locationInfo.id, goodsId = locationInfo.goodsId, location = {x = locationInfo.x, y = locationInfo.y}})
    locations[tostring(locationInfo.id)] = tLocation
end

function GameManager:DeleteAvatarLocalLocation(id)
    local locations = checktable(self.userInfo.avatarCacheData.location)
    locations[tostring(id)] = nil
end

--[[
获取拥有的堕神信息 id
@params id int 卡牌唯一id 不是配表中的cardId
@return petData table 卡牌信息
--]]
function GameManager:GetPetDataById(id)
    return self:GetUserInfo().pets[tostring(id)]
end

function GameManager:SetGemData()
    local cards =  self:GetUserInfo().cards
    local gems = self:GetUserInfo().gems
    for i, v in pairs(cards) do
        if v.artifactTalent then
            for ii, vv in pairs(v.artifactTalent) do
                if checkint(vv.gemstoneId)  > 0 then
                    if  not  gems[tostring(vv.gemstoneId)] then
                        gems[tostring(vv.gemstoneId)] = {}
                    end
                    if  not  gems[tostring(vv.gemstoneId)][tostring(v.id)] then
                        gems[tostring(vv.gemstoneId)][tostring(v.id)] = {}
                    end
                    gems[tostring(vv.gemstoneId)][tostring(v.id)][#gems[tostring(vv.gemstoneId)][tostring(v.id)]+1] = ii
                end
            end
        end
    end
end


--[[
获取拥有的堕神信息 petId
@params petId int petId
@return petData table 卡牌信息
--]]
function GameManager:GetPetDataByPetId(petId)
	print('######################## ! warning ! ########################\n!!! pet may be multiple, here only return then first pet in local data\n######################## ! waring ! ########################')
	local petData = nil
	for i,v in pairs(self.userInfo.pets) do
		if checkint(v.petId) == checkint(petId) then
			petData = v
			break
		end
	end
	return petData
end
--[[
更新堕神信息
@params id int pet id not config id
@params data table pet data
--]]
function GameManager:UpdatePetDataById(id, data)
    if nil == self:GetUserInfo().pets[tostring(id)] then
        -- 为空 插入一条新数据
        self.userInfo.pets[tostring(id)] = data
    else
        -- 不为空 更新堕神数据
        for k,v in pairs(data) do
            self.userInfo.pets[tostring(id)][k] = v
        end
    end
end
--[[
删除一个堕神
@params id int pet id not config id
--]]
function GameManager:DeleteAPetById(id)
    if nil == self:GetUserInfo().pets[tostring(id)] then
        print('here find logic error!!!!!!!!!!????????????????\n\n\n\n ********** you delete a pet which not exist')
    end
    self.userInfo.pets[tostring(id)] = nil
end
--[[
获取拥有的卡牌信息 id
@params id int 卡牌唯一id 不是配表中的cardId
@return cardData table 卡牌信息
--]]
function GameManager:GetCardDataById(id)
	--local cardData = {}
	--for i,v in pairs(self.userInfo.cards) do
	--	if checkint(v.id) == checkint(id) then
	--		cardData = v
	--		break
	--	end
    --end
    local cardData = self.userInfo.cards[tostring(id)]
    if cardData then
        cardData.bookLevel = app.cardMgr.GetBookDataByCardId(cardData.cardId)
        cardData.equippedHouseCatGene = CatHouseUtils.GetEquippedCatGene()
    end
	return cardData or {}
end

function GameManager:GetCardDataListByIdList(idList)
    local cardDataList = {}
    for index, uuid in ipairs(idList or {}) do
        cardDataList[index] = self:GetCardDataById(uuid)
    end
    return cardDataList
end


--[[
获取拥有的卡牌信息 id
@params cardId int cardId
@return cardData table 卡牌信息
--]]
function GameManager:GetCardDataByCardId(cardId)
	local cardData = nil
	if self.userInfo.cards then
		for i,v in pairs(self.userInfo.cards) do
			if checkint(v.cardId) == checkint(cardId) then
				cardData = v
				break
			end
		end
	end
	return cardData
end
--[[
    更新宝石天赋数据
    ---@param  data  修改宝石天赋的基本数据
    ---@param  operation 0 、 删除 1、添加
--]]
function GameManager:UpdateGemsTalentData(data , operation)
    local gems = self.userInfo.gems
    if gems then
        if operation == 1  then
           if  gems[tostring(data.gemstoneId)]  then
               if gems[tostring(data.gemstoneId)][tostring(data.playerCardId)] then
                   local talents = gems[tostring(data.gemstoneId)][tostring(data.playerCardId)]
                   local isHave = false 
                   for i = 1, #talents do
                       if checkint(talents[i]) == checkint(data.talentId) then
                           isHave = true
                           break
                       end
                   end
                   if not isHave  then
                       talents[#talents+1] = checkint(data.talentId)
                   end
               else
                   gems[tostring(data.gemstoneId)][tostring(data.playerCardId)] = {checkint(data.talentId)}
               end
           else
               gems[tostring(data.gemstoneId)] = {
                   [tostring(data.playerCardId)] = {  checkint(data.talentId)}
               }

           end
        elseif operation == 0 then
            if  gems[tostring(data.gemstoneId)]  then
                if gems[tostring(data.gemstoneId)][tostring(data.playerCardId)] then
                    local talents = gems[tostring(data.gemstoneId)][tostring(data.playerCardId)]
                    for i = 1, #talents do
                        if checkint(talents[i]) == checkint(data.talentId) then
                            table.remove(talents , i )
                            break
                        end
                    end
                    if #talents == 0 then
                        gems[tostring(data.gemstoneId)][tostring(data.playerCardId)] = nil
                    end
                    if next( gems[tostring(data.gemstoneId)] ) == nil  then
                        gems[tostring(data.gemstoneId)] = nil
                    end
                end
            end
        end
    end
end
--[[
    根据goodsId 计算出装备的宝石数量
--]]
function GameManager:GetEquipGemNumByGoodsId(goodsId)
    local gems = self.userInfo.gems
    local data = gems[tostring(goodsId)]
    if not  data then
        return 0
    end
    local num = 0
    for i, v in pairs( data ) do
        num = #v + num
    end
    return num
end


--[[
根据卡牌唯一id更新卡牌数据
@params id int 卡牌唯一id 不是配表中的cardId
@param data table 卡牌数据
--]]
function GameManager:UpdateCardDataById(id, data)
    local cardData = self:GetCardDataById(id)
    if nil == cardData or nil == next(cardData) then
        -- 新卡
        self:AcquireOneCard(checkint(id), data)
    else
        -- 老卡
        self:UpdateCardData(checkint(id), data)
    end
end

--[[
根据卡牌配表id更新卡牌数据 -> 玩家不存在两张卡牌配表id相同的卡 否则该方法会出问题
@params id int 卡牌唯一id 不是配表中的cardId
@param data table 卡牌数据
--]]
function GameManager:UpdateCardDataByCardId(cardId, data)
    local cardData = self:GetCardDataByCardId(cardId)
    if nil == cardData or nil == next(cardData) then
        -- 新卡
        self:AcquireOneCard(checkint(data.id), data)
    else
        -- 老卡
        self:UpdateCardData(checkint(cardData.id), data)
    end
end


--[[
更新卡牌信息
@param id int 卡牌数据库id
@param data table 卡牌数据
--]]
function GameManager:UpdateCardData(id, data)
    -- 不允许更新不存在的卡牌数据
    local currentCardData = self:GetCardDataById(id)
    if nil == currentCardData or nil == next(currentCardData) then
        return
    end

    -- 更新数据
    for key, value in pairs(data) do

        local fixedVal = CheckinCardData.CommonUpdateCardData(
            key,
            value, currentCardData[key]
        )
        if nil ~= fixedVal then
            currentCardData[key] = fixedVal
        end

    end
end


--[[
获得一张新卡
@param id int 卡牌数据库id
@param data table 卡牌数据
--]]
function GameManager:AcquireOneCard(id, data)
    -- 检查是否合法
    if nil == id or 0 == checkint(id) then
        -- id不合法
        assert(false, 'error u want to add a new card to local game data but the database id is invalid')
        return
    end

    local cardData = self:GetCardDataById(id)
    if nil ~= cardData and nil ~= next(cardData) then
        -- 数据不合法
        assert(false, 'error u want to add a new card to local game data but the database id is already exist id -> ' .. id .. ' cardId -> ' .. cardData.cardId)
        return
    end

    -- fix new card data
    cardData = CheckinCardData.CommonCreateCardData(id, data)

    -- 处理一些临时数据
    cardData.isNew = 2

    -- add to userInfo
    self.userInfo.cards[tostring(id)] = cardData

    local cardId = checkint(data.cardId)

    ------------ 更新经营技能 ------------
    if CommonUtils.GetBusinessSkillByCardId(cardId) then
        for i,v in ipairs(CommonUtils.GetBusinessSkillByCardId(cardId)) do
            if v.unlock == 1 then
                local tempTab = {level = 1}
                self.userInfo.cards[tostring(data.id)].businessSkill[v.skillId] = tempTab
            end
        end
    end
    ------------ 更新经营技能 ------------

    ------------ 皮肤 ------------
    -- 将卡牌自带的默认皮肤插入用户数据
    self:UpdateCardSkinsBySkinId(cardData.defaultSkinId)
    ------------ 皮肤 ------------

    ------------ 新卡小红点 ------------
    app.dataMgr:AddRedDotNofication(tostring(RemindTag.CARDS), RemindTag.CARDS)
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.CARDS})
    ------------ 新卡小红点 ------------

    ------------ 飨灵收集小红点 ---------
    self:GetFacade():DispatchObservers(SGL.CARD_COLL_RED_DATA_UPDATE, {cardId = cardId, taskType = CardUtils.CARD_COLL_TASK_TYPE.COLL_NUM, addNum = 1})
end


--[[
重置卡牌的一些属性
@params fieldName string 字段名
@params value var 重置的值
@params id int 卡牌数据库id
--]]
function GameManager:ResetCardStatus(fieldName, value, id)
    if nil == id then
        -- 不传id 重置所有卡牌
        for id_, cardData_ in pairs(self:GetUserInfo().cards) do
            if nil ~= cardData_[fieldName] then
                cardData_[fieldName] = value
            end
        end
    else
        -- 传id 重置单卡
        local cardData = self:GetCardDataById(id)
        if nil ~= cardData and 0 ~= checkint(cardData.cardId) and nil ~= cardData[fieldName] then
            cardData[fieldName] = value
        end
    end
end

function GameManager:startPreDownloadCheckinCardAssets_()
    if self.checkinCardAssetsDownloadedHandler_ then return end
    self.checkinCardAssetsDownloadedHandler_ = scheduler.scheduleGlobal(function()
        if self.preDownloadCardConfIdList_ and #self.preDownloadCardConfIdList_ > 0 then
            local cardConfId = table.remove(self.preDownloadCardConfIdList_, 1)
            self:preDownloadCardAssets(cardConfId)
        else
            self:stopPreDownloadCheckinCardAssets_()
        end
    end, 0.5)
end
function GameManager:stopPreDownloadCheckinCardAssets_()
    if self.checkinCardAssetsDownloadedHandler_ then
        scheduler.unscheduleGlobal(self.checkinCardAssetsDownloadedHandler_)
        self.checkinCardAssetsDownloadedHandler_ = nil
    end
end
function GameManager:preDownloadCardAssets(cardConfId)
    local imageMap = {}
    local spineMap = {}
    local cardConf = CardUtils.GetCardConfig(cardConfId) or {}
    for _, skinIdMap in pairs(cardConf.skin or {}) do
        for _, skinId in pairs(skinIdMap) do
            -- 卡牌 立绘 / 背景 / 前景
            imageMap[CardUtils.GetCardDrawPathBySkinId(skinId)] = true
            imageMap[CardUtils.GetCardDrawBgPathBySkinId(skinId)] = true
            imageMap[CardUtils.GetCardDrawFgPathBySkinId(skinId)] = true
            
            -- 形象 spine
            spineMap[CardUtils.GetCardSpinePathBySkinId(skinId)] = true

            local effectConf = CardUtils.GetCardEffectConfigBySkinId(cardConfId, skinId) or {}
            for skillId, skillConf in pairs(effectConf) do
                
                -- 技能 spine
                spineMap[AssetsUtils.GetCardSkillSpinePath(skillConf.effectId)] = true

                -- buff spine
                for buffType, buffConf in pairs(skillConf.effect or {}) do
                    if 0 ~= checkint(buffConf.hitEffect) then
                        spineMap[AssetsUtils.GetCardBuffSpinePath(buffConf.hitEffect)] = true
                    end
                    if 0 ~= checkint(buffConf.addEffect) then
                        spineMap[AssetsUtils.GetCardBuffSpinePath(buffConf.addEffect)] = true
                    end
                end
            end
            
        end
    end

    for imgPath, _ in pairs(imageMap) do
        local isVerify, remoteDefine = app.gameResMgr:verifyRes(imgPath)
        if not isVerify and remoteDefine then
            app.downloadMgr:addResLazyTask(imgPath)
        end
    end
    
    for spnPath, _ in pairs(spineMap) do
        local isVerify, verifyMap = app.gameResMgr:verifySpine(spnPath)
        if not isVerify and verifyMap and verifyMap['atlas'] and verifyMap['atlas'].remoteDefine then
            app.downloadMgr:addResLazyTask(_spn(spnPath))
        end
    end
end


--更新卡牌皮肤数据
function GameManager:UpdateCardSkinsBySkinId(skinId)

    table.insert(self.userInfo.cardSkins,skinId)

    -- local skinData = CommonUtils.GetConfig('goods','cardSkin',skinId)
    -- dump(skinData)
    -- if skinData then
    --     for i,v in pairs(self.userInfo.cards) do
    --         if checkint(v.cardId) ==  checkint(skinData.cardId) then
    --             table.insert(v.skin,skinId)
    --             break
    --         end
    --     end
    -- end
end
--更新主界面看板娘数据
function GameManager:UpdateSignboardByPlayCardId(PlayCardId)
    self.userInfo.signboardId = PlayCardId
end

--[[
获取当前用户信息
--]]
function GameManager:GetUserInfo()
	return self.userInfo
end
--[[
    获取怪物的基本信息
]]

function GameManager:GetMonsterData()
    return self.userInfo.monster
end
--互想排斥的位置
local mutexPlaces = {
    [tostring(CARDPLACE.PLACE_ASSISTANT)] = {CARDPLACE.PLACE_ASSISTANT, CARDPLACE.PLACE_TEAM, CARDPLACE.PLACE_ICE_ROOM ,CARDPLACE.PLACE_FISH_PLACE},
    [tostring(CARDPLACE.PLACE_TEAM)] = {CARDPLACE.PLACE_ASSISTANT, CARDPLACE.PLACE_TEAM , CARDPLACE.PLACE_FISH_PLACE},
    [tostring(CARDPLACE.PLACE_ICE_ROOM)] = {CARDPLACE.PLACE_ICE_ROOM, CARDPLACE.PLACE_ASSISTANT,CARDPLACE.PLACE_FISH_PLACE},
    [tostring(CARDPLACE.PLACE_FIGHT)] = {CARDPLACE.PLACE_ICE_ROOM},
    [tostring(CARDPLACE.PLACE_TAKEAWAY)] = {CARDPLACE.PLACE_ICE_ROOM}, --外卖与冰场
    [tostring(CARDPLACE.PLACE_EXPLORATION)] = {},
    [tostring(CARDPLACE.PLACE_EXPLORE_SYSTEM)] = {},
    [tostring(CARDPLACE.PLACE_FISH_PLACE)] = {CARDPLACE.PLACE_ASSISTANT, CARDPLACE.PLACE_TEAM, CARDPLACE.PLACE_ICE_ROOM ,CARDPLACE.PLACE_ASSISTANT},
}
--禁止更换的位置
local disablePlaces = {
    [tostring(CARDPLACE.PLACE_ASSISTANT)] = {CARDPLACE.PLACE_ASSISTANT, CARDPLACE.PLACE_TAKEAWAY,CARDPLACE.PLACE_FISH_PLACE},
    [tostring(CARDPLACE.PLACE_ICE_ROOM)] = {CARDPLACE.PLACE_ASSISTANT, CARDPLACE.PLACE_TAKEAWAY ,CARDPLACE.PLACE_FISH_PLACE},
    [tostring(CARDPLACE.PLACE_FIGHT)] = {CARDPLACE.PLACE_ASSISTANT, CARDPLACE.PLACE_TAKEAWAY,CARDPLACE.PLACE_FISH_PLACE},
    [tostring(CARDPLACE.PLACE_TAKEAWAY)] = {CARDPLACE.PLACE_ASSISTANT, CARDPLACE.PLACE_TAKEAWAY,CARDPLACE.PLACE_FISH_PLACE},
    [tostring(CARDPLACE.PLACE_EXPLORATION)] = {CARDPLACE.PLACE_EXPLORATION, CARDPLACE.PLACE_EXPLORE_SYSTEM},
    [tostring(CARDPLACE.PLACE_EXPLORE_SYSTEM)] = {CARDPLACE.PLACE_EXPLORATION, CARDPLACE.PLACE_EXPLORE_SYSTEM},
    [tostring(CARDPLACE.PLACE_TEAM)] = {CARDPLACE.PLACE_ASSISTANT, CARDPLACE.PLACE_TAKEAWAY,CARDPLACE.PLACE_FISH_PLACE},
    [tostring(CARDPLACE.PLACE_FISH_PLACE)] = {CARDPLACE.PLACE_ASSISTANT, CARDPLACE.PLACE_TAKEAWAY ,CARDPLACE.PLACE_FISH_PLACE}
}
--[[
--检测英雄是否可变更的逻辑
--@param idInfo 用于判断的卡牌的id列表 {id = 323} --数据库id或者cardId
--@param placeId --卡牌位置的类别id
--@return canSwitch, oldPlaceId
--]]
function GameManager:CanSwitchCardStatus(idInfo, placeId)
    if not disablePlaces[tostring(placeId)] then return true end --没有禁用的位置，可以更换
    local canSwitch = true
    local oldPlaceId = nil
    local cardInfo = nil
    if idInfo.id then
        --根据数据库id来判断的状态的逻辑
        cardInfo = self:GetCardDataById(checkint(idInfo.id))
    else
        --根据cardId来判断的逻辑
        cardInfo = self:GetCardDataByCardId(checkint(idInfo.cardId))
    end
    if cardInfo then
        --存在历史位置
        local oldPlaces = self:GetCardPlace({id = cardInfo.id})
        if oldPlaces then
            for idx,val in pairs(oldPlaces) do
                if disablePlaces[tostring(placeId)] then
                    --当存卡牌位置信息中存在禁止更换的逻辑
                    if table.keyof(disablePlaces[tostring(placeId)], val) then
                        canSwitch = false
                        oldPlaceId = val
                        break
                    end
                end
            end
        end
    end
    return canSwitch, oldPlaceId
end

--[[
--清除某一位置上所有卡牌的状态
--@param cards 卡牌列表
--@param placeId 位置类别id
--]]
function GameManager:DeleteCardPlace(cards, placeId)
    if not cards then cards = {} end
    for name,cInfo in pairs(cards) do
        local cardInfo = nil
        if cInfo.id then
            --根据数据库id来判断的状态的逻辑
            cardInfo = self:GetCardDataById(checkint(cInfo.id))
        else
            --根据cardId来判断的逻辑
            cardInfo = self:GetCardDataByCardId(checkint(cInfo.cardId))
        end
        if cardInfo then
            print("cardInfo = " , cardInfo)
            local oldPlaces = self.userInfo.places[tostring(cardInfo.id)]
            if oldPlaces then
                if placeId == CARDPLACE.PLACE_ICE_ROOM then
                    --将此卡牌的新鲜度计时器删除
                    -- app.uiMgr:ShowInformationTips(string.format('ICEROOM_%d',checkint(cardInfo.id)))
                    app.timerMgr:RemoveTimer(string.format('ICEROOM_%d',checkint(cardInfo.id)))
                end
                oldPlaces[tostring(placeId)] = nil
                self.userInfo.places[tostring(cardInfo.id)] = oldPlaces
            end
        end
    end
end
--[[
--获取当前卡牌所在位置的信息
--idInfo --需要得到信息的卡牌列表
--]]
function GameManager:GetCardPlace(idInfo)
    local cardInfo = nil
    local places = {}
    if idInfo.id then
        --根据数据库id来判断的状态的逻辑
        cardInfo = self:GetCardDataById(checkint(idInfo.id))
    else
        --根据cardId来判断的逻辑
        cardInfo = self:GetCardDataByCardId(checkint(idInfo.cardId))
    end
    if cardInfo then
        --存在历史位置
        if self.userInfo.places[tostring(cardInfo.id)] then
            places = self.userInfo.places[tostring(cardInfo.id)]
        end
    end
    return places --得到当前卡牌所处位置列表
end


--删除卡牌某个具体的状态places
--gameMgr:DelCardOnePlace(data.id,CARDPLACE.PLACE_ICE_ROOM)
--cardPlayerId  卡牌数据库自增id
--place         希望删除的状态 CARDPLACE.PLACE_ICE_ROOM
function GameManager:DelCardOnePlace(cardPlayerId,place)
    local nowPlaces = self.userInfo.places[tostring(cardPlayerId)]
    if nowPlaces and table.nums(nowPlaces) > 0 then
        if nowPlaces[tostring(place)] then
            nowPlaces[tostring(place)] = nil
        end
    end
end

--[[
--将旧卡从一个位置转到新的位置
--@oldCards --旧的卡牌列表
--@newCards --新的卡牌列表
--@placeId --位置id
--]]
function GameManager:SetCardPlace(oldCards, newCards , placeId)
    --先从旧的位置上删除，然后再添加到新的位置状态
    --刷新下所有本地卡牌的状态信息
    if oldCards then
        self:DeleteCardPlace(oldCards, placeId)
    end
    --添加新位置的状态
    if newCards then
        for name,oldIdInfo in pairs(newCards) do
            local cardInfo = nil
            if oldIdInfo.id then
                --根据数据库id来判断的状态的逻辑
                cardInfo = self:GetCardDataById(checkint(oldIdInfo.id))
            else
                --根据cardId来判断的逻辑
                cardInfo = self:GetCardDataByCardId(checkint(oldIdInfo.cardId))
            end
            if cardInfo then
                local oldPlaces = self.userInfo.places[tostring(cardInfo.id)]
                if not oldPlaces then
                    oldPlaces = {}
                end
                --处理互斥的逻辑
                if oldPlaces and table.nums(oldPlaces) > 0 then
                    for idx,val in ipairs(mutexPlaces[tostring(placeId)]) do
                        --所有的互斥模块的逻辑
                        oldPlaces[tostring(val)] = nil
                        if checkint(val) == CARDPLACE.PLACE_ICE_ROOM then
                            --将此卡牌的新鲜度计时器删除
                            -- app.uiMgr:ShowInformationTips(string.format('ICEROOM_%d',checkint(cardInfo.id)))
                            app.timerMgr:RemoveTimer(string.format('ICEROOM_%d',checkint(cardInfo.id)))
                        end
                    end
                end
                oldPlaces[tostring(placeId)] = placeId
                self.userInfo.places[tostring(cardInfo.id)] = oldPlaces
            end
        end
    end
end
--[[
根据卡牌id判断是否可以操作堕神
@params id int 卡牌id
@return _ bool 是否可以操作堕神
--]]
function GameManager:CanOperatePetById(id)
    local cardPlace = self:GetCardPlace({id = id})
    return self:CanOperatePetByCardPlace(cardPlace)
end
--[[
根据卡牌状态判断是否可以操作堕神
@params cardPlace CardPlace 卡牌状态
@return _ bool 是否可以操作堕神
--]]
function GameManager:CanOperatePetByCardPlace(cardPlace)
    if nil == cardPlace then return false end
    local tempBool = true
    for k,v in pairs(cardPlace) do
        if  CARDPLACE.PLACE_ASSISTANT == checkint(v) or
            CARDPLACE.PLACE_TAKEAWAY == checkint(v) or
            -- CARDPLACE.PLACE_EXPLORATION == checkint(v) or
            -- CARDPLACE.PLACE_EXPLORE_SYSTEM == checkint(v) or
            CARDPLACE.PLACE_FISH_PLACE == checkint(v) then
            tempBool = false
            break
        end
    end
    return tempBool
end

--[[
--更新卡牌的编队信息
--@idInfo {id = or cardId = }
--@teamId 目标编队信息
--@heroIdx 目标英雄的位置
--]]
function GameManager:UpdateTeamInfo(idInfo, teamId, heroIdx, isForRealTeamData)
    --添加新位置的状态
    if isForRealTeamData == nil then isForRealTeamData = false end
    local cardInfo = nil
    if idInfo.id then
        --根据数据库id来判断的状态的逻辑
        cardInfo = self:GetCardDataById(checkint(idInfo.id))
    else
        --根据cardId来判断的逻辑
        cardInfo = self:GetCardDataByCardId(checkint(idInfo.cardId))
    end
    if cardInfo then
        --清除编队信息
        if isForRealTeamData then
            if self.userInfo.teamFormation then --是否在编队中
                for k,v in ipairs(self.userInfo.teamFormation) do
                    if checkint(v.teamId) == teamId then
                        for i,vv in ipairs(v.cards) do
                            --添加入编队中去
                            if checkint(vv.id) == checkint(cardInfo.id) then
                                v.cards[i] = {id = nil}
                                break
                            end
                        end
                        for i,vv in ipairs(v.cards) do
                            if i == heroIdx then
                                v.cards[i] = {id = cardInfo.id}
                                break
                            end
                        end
                        break
                    end
                end
            end
        else
            if self.userInfo.operationTeamFormation then --是否在临时数据编队中
                for k,v in ipairs(self.userInfo.operationTeamFormation) do
                    if checkint(v.teamId) == teamId then
                        for i,vv in ipairs(v.cards) do
                            --添加入编队中去
                            if checkint(vv.id) == checkint(cardInfo.id) then
                                v.cards[i] = {id = nil}
                                self:DeleteCardPlace({{id = vv.id}}, CARDPLACE.PLACE_TEAM)
                                break
                            end
                        end
                        for i,vv in ipairs(v.cards) do
                            if i == heroIdx then
                                v.cards[i] = {id = cardInfo.id}
                                --设置新的位置信息
                                self:SetCardPlace({}, {{id = cardInfo.id}}, CARDPLACE.PLACE_TEAM)
                                break
                            end
                        end
                        break
                    end
                end
            end
        end
    end
end
--[[
--删除临时编队缓存数据
--]]
function GameManager:DeleteTempFormationDataById(id)
    if self.userInfo.operationTeamFormation then --是否在临时数据编队中
        for k,v in ipairs(self.userInfo.operationTeamFormation) do
            for i,vv in ipairs(v.cards) do
                if checkint(vv.id) == checkint(id) then
                    v.cards[i] = {id = nil}
                    self:DeleteCardPlace({{id = vv.id}}, CARDPLACE.PLACE_TEAM)
                    break
                end
            end
        end
    end
end
--[[
--根据模块来得到描述名称
--]]
function GameManager:GetModuleName(placeId)
    local name = nil
    local state = nil
    local desc = nil
    placeId = checkint(placeId)
    if placeId == CARDPLACE.PLACE_ASSISTANT then
        state = 'working'
        name = __('餐厅经营中')
        desc = ''
    elseif placeId == CARDPLACE.PLACE_TEAM then
        name = __('编队中')
        desc = __('该飨灵已经在其他编队中，是否将其移至当前编队。')
    elseif placeId == CARDPLACE.PLACE_TAKEAWAY then
        name = __('外卖中')
        desc = ''
    elseif placeId == CARDPLACE.PLACE_ICE_ROOM then
        state = 'ice'
        name = __('冰场休息中')
        desc = __('该飨灵正在冰场中休息，该操作会停止回复新鲜度')
    -- elseif placeId == CARDPLACE.PLACE_EXPLORATION then
    --     state = 'exploration'
    --     name = __('探索中')
    --     desc = ''
    -- elseif placeId == CARDPLACE.PLACE_EXPLORE_SYSTEM then
    --     state = 'exploration'
    --     name = __('探索中')
    --     desc = ''
    elseif placeId == CARDPLACE.PLACE_FISH_PLACE then
        state = 'fishing'
        name = __('钓场中')
        desc =""
    end
    return name,state,desc
end
--[[
--获取到当前卡牌对应的编队信息
--@idInfo {id = xxx or cardId = xxx}
--]]
function GameManager:GetTeamInfo(idInfo,isForRealTeamData)
    local cardInfo = nil
    if idInfo.id then
        cardInfo = self:GetCardDataById(idInfo.id)
    else
        cardInfo = self:GetCardDataByCardId(idInfo.cardId)
    end
    local teamInfo = nil
    if cardInfo then
        if isForRealTeamData then
            if self.userInfo.teamFormation then
                --如果这个卡已在编队中
                --否则再查找一下缓存数据
                for name,teamData in pairs(self.userInfo.teamFormation) do
                    for name,val in pairs(teamData.cards) do
                        if checkint(val.id) == checkint(cardInfo.id) then
                            teamInfo = teamData
                            break
                        end
                    end
                end
            end
            if not teamInfo then
                if self.userInfo.operationTeamFormation then
                    --当前正在操作的队列的数据
                    for name,teamData in pairs(self.userInfo.operationTeamFormation) do
                        for name,val in pairs(teamData.cards) do
                            if checkint(val.id) == checkint(cardInfo.id) then
                                teamInfo = teamData
                                break
                            end
                        end
                    end
                end
            end
        else
            if self.userInfo.operationTeamFormation then
                --当前正在操作的队列的数据
                for name,teamData in pairs(self.userInfo.operationTeamFormation) do
                    for name,val in pairs(teamData.cards) do
                        if checkint(val.id) == checkint(cardInfo.id) then
                            teamInfo = teamData
                            break
                        end
                    end
                end
            end
        end
    end
    return teamInfo
end
--==============================--
--desc: 在现有的编队中选择战力最高的队伍
--1.队伍在空闲状态  2. 队伍的战力最高
--time:2017-06-30 06:26:52
--@return
--==============================--
function GameManager:GetMaxBattlePowerFreeTeam()
    local teamFormation = self:GetUserInfo().teamFormation
    local teamId = 1
    local maxBattlePoint = 0
    for k , v in pairs(teamFormation) do
        local places = nil
        for kk ,vv  in pairs(v.cards or {}) do
            vv = vv or {}
            if vv.id then
                places = self:GetCardPlace({id = vv.id})
                break
            end

        end
        if places then
            if (not  places[tostring(CARDPLACE.PLACE_EXPLORATION)] ) and (not  places[tostring(CARDPLACE.PLACE_EXPLORE_SYSTEM)]) and ( not places[tostring(CARDPLACE.PLACE_TAKEAWAY)]) then
                local battlePoint = self:GetTeamTotalBattlePointByTeamId(checkint(v.teamId))
                if checkint(battlePoint) > maxBattlePoint then
                    teamId = checkint(v.teamId)
                    maxBattlePoint = battlePoint
                end

            end
        end
    end
    return teamId
end
--[[
--添加取得指定编队的队长的卡牌信息
--@teamId 编队id
--@return 卡牌信息
--]]
function GameManager:GetCaptainCardInfoByTeamId(teamId)
	local teamData = self.userInfo.teamFormation[checkint(teamId)]
	local cardInfo = nil
	if teamData and teamData.captainId and teamData.captainId ~= '' and checkint(teamData.captainId) > 0 then
		cardInfo = self:GetCardDataById(teamData.captainId)
	end
	return cardInfo
end
-- --[[
-- 	团队间的相互转换  placeId he placeId2 表示直接从一状态转化为二状态
--  	团队信息先重置为空
-- --]]
function GameManager:setMutualTakeAwayToTeam(teamId,placeId,placeId2)
	local data = self:getTeamCardsInfo(teamId)
	local data2 = clone(data)
	self:SetCardPlace(data,{},placeId)
	self:SetCardPlace({},data2,placeId2)
end


--[[
-- 设置生日
--]]
function GameManager:SetBirthday(birthday)
   self.userInfo.birthday = birthday
end

--[[
--加工团队信息 , 直接返回团队的所有信息
--]]
function GameManager:getTeamAllCards(teamData)
    if not teamData then teamData = self.userInfo.teamFormation end
	local teamCards = {}
	for k, v in pairs(teamData) do
		if v.cards then
			for name , cardinfo in pairs  (v.cards) do
				table.insert(teamCards,#teamCards+1 ,cardinfo)
			end
		end
	end
	return  teamCards
end
--[[
--获取制定编队的所有卡牌的信息
--@teamId  编队的id
]]
function GameManager:getTeamCardsInfo(teamId)
	-- body
	local tData = self.userInfo.teamFormation[checkint(teamId)]
	local teamData = {}
	if  tData then
		teamData = tData.cards
	end
    return teamData
end

--[[
初始化本地用户信息
--]]
function GameManager:CheckLocalPlayer()
	local userInfo = cc.UserDefault:getInstance():getStringForKey(STORE_ACCOUNT_KEY,'')
	if string.len(userInfo) > 0 then
        --如果长度大于0，表示有账户信息
        self.storeAccounts = json.decode(userInfo)
        -- dump(self.storeAccounts)
        for _, account in ipairs(checktable(self.storeAccounts)) do
        	if checkint(account.isDefault) == 1 then
        		local playerInfo = {
	        		uname = account.uname,
	        		upass = account.password or account.upass,
	        		isGuest = account.isGuest,
                    channel = Platform.channel,
                    game = STORE_ACCOUNT_NAME,
	        		isDefault = 1
		        }
		        self:UpdateAuthorInfo(playerInfo)
		        break
        	end
        end
    end
end

--[[
将多个帐号信息加入本地
@params accounts table
--]]
function GameManager:StoreAccountInfos(accounts)
	if accounts then
		for i,account in ipairs(accounts) do
			if account then
				if 1 == i then
					-- 如果是第一个帐号 作为默认帐号
					account.isDefault = 1
					local userInfo = {uname = account.uname, upass = account.password, isGuest = checkint(account.isGuest), channel = Platform.channel, game = STORE_ACCOUNT_NAME}
					self:UpdateAuthorInfo(userInfo)
				else
					account.isDefault = 0
				end
				if self:HasAccount(account.uname) == 0 then
					-- 本地不存在 加入
					local accountInfo = {uname = account.uname, upass = account.password, isGuest = checkint(account.isGuest), isDefault = checkint(account.isDefault), channel = Platform.channel, game = STORE_ACCOUNT_NAME}
					table.insert(self.storeAccounts, accountInfo)
				end
			end
		end
		if table.nums(self.storeAccounts) > 0 then
			-- 如果处理后结果数量大于0 存入本地文件
            self:SaveAllAccountInfo()
		end
	end
end

--[[
将单个帐号信息存入本地
@params account table
--]]
function GameManager:StoreAnAccountInfo(account)
	if account then
		if self:HasAccount(account.uname) == 0 then
			-- 本地不存在 加入
			local accountInfo = {uname = account.uname, upass = account.password, isGuest = checkint(account.isGuest), isDefault = checkint(account.isDefault), channel = Platform.channel, game = STORE_ACCOUNT_NAME}
			table.insert(self.storeAccounts, accountInfo)
		end
		-- 新输入的帐号设为默认 其他设为非默认
		for _, a in ipairs(self.storeAccounts) do
			if a then
				if a.uname == account.uname then
					a.isDefault = 1
					a.uname = account.uname
					a.upass = account.password
					a.isGuest = checkint(account.isGuest)
                    a.channel = Platform.channel
                    a.game = STORE_ACCOUNT_NAME
					local userInfo = {uname = a.uname, upass = a.upass, isDefault = a.isDefault, isGuest = a.isGuest, channel = a.channel, game = a.game}
					self:UpdateAuthorInfo(userInfo)
				else
					a.isDefault = 0
				end
			end
		end
		if table.nums(self.storeAccounts) > 0 then
			-- 如果处理后结果数量大于0 存入本地文件
            self:SaveAllAccountInfo()
		end
	end
end

--[[
    删除一个账号
]]
function GameManager:RemoveAnAccountInfo(account)
    if account then
        if self:HasAccount(account.uname) == 1 then
            for index = #self.storeAccounts, 1, -1 do
                local accData = self.storeAccounts[index]
                if accData.uname == account.uname and checkint(account.channel) == checkint(Platform.channel) and tostring(account.game) == STORE_ACCOUNT_NAME then
                    table.remove(self.storeAccounts, index)
                    break
                end
            end
            self:SaveAllAccountInfo()
        end
    end
end

--[[
    存储全部账号数据
]]
function GameManager:SaveAllAccountInfo()
    local localAccounts = json.encode(self.storeAccounts)
    cc.UserDefault:getInstance():setStringForKey(STORE_ACCOUNT_KEY, localAccounts)
    cc.UserDefault:getInstance():flush()
end


--[[
本地帐号中是否存在目标帐号
@params name string
@return has number 0 不存在 1 存在
--]]
function GameManager:HasAccount(name)
	local has = 0
	if table.nums(self.storeAccounts) > 0 then
		for _, v in ipairs(self.storeAccounts) do
			if name == v.uname then
				has = 1
				break
			end
		end
	end
	return has
end

--[[
--获取角色配表中的人物信息
--]]
function GameManager:GetRoleInfo(roleId)
    local allRoles = self.dStores["roles"]
    if not allRoles then
        -- local path = getRealConfigPath("conf/" .. i18n.getLang() .."/quest/role.json")
        -- allRoles = getRealConfigData(path, 'role')
        -- self.dStores["roles"] = allRoles
        allRoles = CommonUtils.GetConfigAllMess('role', 'quest')
        self.dStores["roles"] = allRoles
    end
    return checktable(allRoles[tostring(roleId)])
end

--[[
显示退出游戏界面的逻辑
--]]
function GameManager:ShowExitGameView( text, isOnlyOK , callfunc)
    local uiMgr = self:GetUIManager() --长时间不在游戏时重新进入游戏
    local node = uiMgr:Scene():getChildByTag(GameSceneTag.ExitGameView_GameSceneTag)
    if not node then
        if not text then text = __('当前长时间不在游戏中需要退出游戏重新进入') end
        if isOnlyOK == nil then isOnlyOK = true end
        if GuideUtils.GetDirector() and GuideUtils.GetDirector().stage then
            GuideUtils.GetDirector().stage:RemoveTouchEvent()
        end
        -- app.badgeMgr:clearAllTaskRedPointCacheData()
        local CommonTip  = require( 'common.NewCommonTip' ).new({text = text, callback = function()
            -- 中断正在进行的战斗
            AppFacade.GetInstance():DispatchObservers('BATTLE_FORCE_BREAK')
            -- 清理所有任务红点缓存数据
            local AppSDK = require('root.AppSDK').GetInstance()
            if AppSDK.TrackSDKEvent then
                AppSDK:TrackSDKEvent("setCurrentUserUniqueID",{
                    isLogin = 0
                } )
            end
            if checkint(Platform.id) == 32 then --应用宝
                local AppSDK = require('root.AppSDK')
                AppSDK.GetInstance():QuickLogout()
            elseif isElexSdk() then
                --elex平台时
                local AppSDK = require('root.AppSDK')
                AppSDK.GetInstance():QuickLogout()
            else
                if isEfunSdk() then
                    -- ios是有回调的  安卓平台是没有回调的 这里特殊处理一下
                    AppSDK.GetInstance():EfuncLogout()
                    if device.platform == 'android' then
                        app.audioMgr:stopAndClean()
                        uiMgr:PopAllScene()
                        sceneWorld:getEventDispatcher():dispatchEvent(cc.EventCustom:new('APP_EXIT'))
                    end
                else
                    app.audioMgr:stopAndClean()
                    uiMgr:PopAllScene()
                    sceneWorld:getEventDispatcher():dispatchEvent(cc.EventCustom:new('APP_EXIT'))
                end
            end
            if callfunc then
                callfunc()
            end
        end, isForced = true, isOnlyOK = isOnlyOK})
        CommonTip.tip:setPosition(cc.p(CommonTip.size.width/2,CommonTip.size.height -120))
        CommonTip:setPosition(display.center)
        uiMgr:Scene():addChild(CommonTip, GameSceneTag.BootLoader_GameSceneTag, GameSceneTag.ExitGameView_GameSceneTag)
    end
end
--[[
加载加载进就条
--]]
function GameManager:ShowLoadingView()
	if not self.isLoadingShowing then
		self.isLoadingShowing = true
		--显示加度逻辑
		local uiMgr = self:GetUIManager()
		local target = uiMgr:ShowLoadingScene()
	end
	-- funLog(Logger.INFO, "ShowLoadingView " .. tostring(self.isLoadingShowing ))
end

function GameManager:RemoveLoadingView( )
	-- funLog(Logger.INFO, "RemoveLoadingView " ..  tostring(self.isLoadingShowing ))
	if self.isLoadingShowing then
		self.isLoadingShowing = false
		local uiMgr = self:GetUIManager()
		uiMgr:RemoveLoadingScene()
	end
end

--[[
网络信号弱提示
--]]
function GameManager:ShowNetworkWeakView()
	if not self.isNetworkWeakShowing_ then
		self.isNetworkWeakShowing_ = true
		self:GetUIManager():ShowNetworkWeakScene()
	end
	-- funLog(Logger.INFO, "ShowNetworkWeakView " .. tostring(self.isNetworkWeakShowing_ ))
end

function GameManager:RemoveNetworkWeakView( )
	-- funLog(Logger.INFO, "RemoveNetworkWeakView " ..  tostring(self.isNetworkWeakShowing_ ))
	if self.isNetworkWeakShowing_ then
		self.isNetworkWeakShowing_ = false
		self:GetUIManager():RemoveNetworkWeakScene()
	end
end


--[[
显示游戏警告窗口，不允许点击空白关闭
@params 参考 common.NewCommonTip 参数，不用传isForced参数
]]
function GameManager:ShowGameAlertView(params)
	self:RemoveLoadingView() --移除跑进度的包子，然后显示异常信息

	params.isForced = true
	local CommonTip = require('common.NewCommonTip').new(params)
    CommonTip:setPosition(display.center)

    app.uiMgr:Scene():addChild(CommonTip, GameSceneTag.Loading_GameSceneTag, params.sceneTag)
end


--[[
* state 当前的状态
- 处理网络重试的请求状态
--]]
function GameManager:ShowRetryNetworkView( path, params, state )
	--添加网络重试的接口逻辑
    local text = __('当前网络请求出现异常，请重试')
    if state == 'parse' then
        text = __('当前网络请求出现异常，请重试>_<')
    end
    if GuideUtils.GetDirector() then
        GuideUtils.GetDirector():TouchDisable(true)
    end
	self:ShowGameAlertView({sceneTag = GameSceneTag.Loading_GameSceneTag, text = text, isOnlyOK = true, callback = function()
        if GuideUtils.GetDirector() then
            GuideUtils.GetDirector():TouchDisable(false)
        end
        if params.method == 'GET' then
            app.httpMgr:Get( path, signalName)
        else
            app.httpMgr:Post( path, params.signalName, params.data, params.handleError, params.async)
        end
    end})
end

function GameManager.Destroy( key )
	key = (key or "GameManager")
	if GameManager.instances[key] == nil then
		return
	end

    --清除配表数据
    GameManager.instances[key]:release()
	GameManager.instances[key] = nil
end

--[[
根据关卡id获取当前关卡的星级
@params questId int 关卡id
@return grade int 星级
--]]
function GameManager:GetQuestGradeByQuestId(questId)
	-- 目前只有主线关卡存在星级
	local questConf = CommonUtils.GetConfig('quest', 'quest', questId)

	-- config error check --
	if nil == questConf then
		print('-----\n    cannot find quest conf #questId# when search the quest grade -> ' .. questId .. '\n-----')
		return nil
	end
	-- config error check --

	if nil == self:GetUserInfo().questGrades[tostring(questConf.cityId)] then
		return nil
	end

	local grade = self:GetUserInfo().questGrades[tostring(questConf.cityId)].grades[tostring(questId)]
	if nil ~= grade then
		grade = checkint(grade)
	end
	return grade
end
--[[
根据关卡id更新关卡最高星级信息
@params questId int 关卡id
@params grade int 星级
--]]
function GameManager:UpdateQuestGradeByQuestId(questId, grade)
	if (nil == questId) or (nil == grade) then return end

	-- 目前只有主线关卡存在星级
	local questConf = CommonUtils.GetConfig('quest', 'quest', questId)

	-- config error check --
	if nil == questConf then
		print('-----\n    cannot find quest conf #questId# when search the quest grade -> ' .. questId .. '\n-----')
		return
	end
	-- config error check --

	if nil == self:GetUserInfo().questGrades[tostring(questConf.cityId)] then
		-- 如果章节整个不存在星级信息 初始化章节信息
		local chapterGradesData = {grades = {}}
		self:GetUserInfo().questGrades[tostring(questConf.cityId)] = chapterGradesData
		-- 直接插入 不做判断
		self:GetUserInfo().questGrades[tostring(questConf.cityId)].grades[tostring(questId)] = tostring(grade)
	else
		-- 如果章节星级信息存在 则判断是否需要更新星级 仅在星级更高时更新星级
		local curGrade = checkint(self:GetUserInfo().questGrades[tostring(questConf.cityId)].grades[tostring(questId)])
		if (checkint(grade) > curGrade) or (nil == curGrade) then
			self:GetUserInfo().questGrades[tostring(questConf.cityId)].grades[tostring(questId)] = tostring(grade)
		end
	end
end
--[[
根据关卡id判断星级方面是否满足扫荡条件
@params questId int 关卡id
@return _ bool 是否可以扫荡
--]]
function GameManager:CanSweepQuestByQuestGrade(questId)
    local maxStarAmount = 3
    local questGrade = self:GetQuestGradeByQuestId(questId)
    if nil ~= questGrade and maxStarAmount <= checkint(questGrade) then
        return true
    end
    return false
end
--[[
根据关卡id判断玩家是否通过了某一关
@params stageId int 关卡id
@return result bool 是否解锁了某一关
--]]
function GameManager:JudgePassedStageByStageId(stageId)
    local stageConf = CommonUtils.GetConfig('quest', 'quest', stageId)
    local diffType = checkint(stageConf.difficulty)
    -- 判断最新关卡
    local newestStageId = 0
    if QUEST_DIFF_NORMAL == diffType then
        newestStageId = self:GetUserInfo().newestQuestId
    elseif QUEST_DIFF_HARD == diffType then
        newestStageId = self:GetUserInfo().newestHardQuestId
    elseif QUEST_DIFF_HISTORY == diffType then
        newestStageId = self:GetUserInfo().newestInsaneQuestId
    end
    if newestStageId > stageId then
        return true
    end
    return false
end
--[[
判断玩家是否能进入指定章节的指定难度
@params chapterId int 章节id
@params diffType DifficultyLevel 难度
--]]
function GameManager:JudgeCanEnterChapterAndDiff(chapterId, diffType)
	local result = true
	local cityConf = CommonUtils.GetConfig('quest', 'city', chapterId)
	if nil == cityConf then
		string.format(__('章节%d数据不存在'), chapterId)
		return false
	end
	local unlockLimitConf = cityConf.unlock[tostring(diffType)]
	if unlockLimitConf then
		-- 角色等级限制
		local playerLevelLimitConf = unlockLimitConf[1]
		if playerLevelLimitConf then
			if checkint(playerLevelLimitConf) > self:GetUserInfo().level then
				result = false
			end
		end

		-- 关卡限制
		local stageLimitConf = unlockLimitConf[2]
		if stageLimitConf then
			local stageLimitConf_ = checkint(stageLimitConf)
			if not (self:GetUserInfo().newestQuestId > stageLimitConf_ or
				self:GetUserInfo().newestHardQuestId > stageLimitConf_ or
				self:GetUserInfo().newestInsaneQuestId > stageLimitConf_) then

				result = false
			end
		end
	else
		return true
	end
end
--[[
经验增加时刷新一次解锁关卡情况
--]]
function GameManager:UpdatePlayerNewestQuestId()
	local playerLevel = self:GetUserInfo().level
	local questsInfo = {
		['1'] = {diffType = 1, questIdName = 'newestQuestId'},
		['2'] = {diffType = 2, questIdName = 'newestHardQuestId'},
		['3'] = {diffType = 3, questIdName = 'newestInsaneQuestId'}
	}
	local cityConf = CommonUtils.GetConfig('quest', 'city', 1)
	local unlockLimitConf = nil
	local playerLevelLimitConf = nil
	local stageLimitConf = nil
	for k,v in pairs(questsInfo) do
		-- 刷新第一次能进入高难度章节的数据
		if 0 == self:GetUserInfo()[v.questIdName] then
			-- 取该难度第一章配表信息
			if nil ~= cityConf then
				unlockLimitConf = cityConf.unlock[tostring(v.diffType)]
				if nil ~= unlockLimitConf then
					playerLevelLimitConf = unlockLimitConf[1]
					stageLimitConf = unlockLimitConf[2]
					-- 等级限制
					if nil ~= playerLevelLimitConf then
						if playerLevel >= checkint(playerLevelLimitConf) then
							if nil ~= stageLimitConf then
								-- 双限制
								if (self:GetUserInfo().newestQuestId >= checkint(stageLimitConf) or
									self:GetUserInfo().newestHardQuestId >= checkint(stageLimitConf) or
									self:GetUserInfo().newestInsaneQuestId >= checkint(stageLimitConf)) then
									-- 满足条件
									local updateInfo = {[v.questIdName] = checkint(checktable(cityConf.quests[tostring(v.diffType)])[1])}
									self:UpdatePlayer(updateInfo)
								end
							else
								-- 只有等级限制并且满足
								local updateInfo = {[v.questIdName] = checkint(checktable(cityConf.quests[tostring(v.diffType)])[1])}
								self:UpdatePlayer(updateInfo)
							end
						end
					else
						-- 没有限制
						local updateInfo = {[v.questIdName] = checkint(checktable(cityConf.quests[tostring(v.diffType)])[1])}
						self:UpdatePlayer(updateInfo)
					end
				end
			end
		end
	end
end
--[[
    更新神器能量战斗关卡的数据
--]]
function GameManager:UpdateArtifactQuest(data)

    if not self:GetUserInfo().artifactQuest  then
        self:GetUserInfo().artifactQuest = {}
    end
    local artifactQuest = self:GetUserInfo().artifactQuest
    data = data or {}
    if data.id  then
        local artifactOneQuest = artifactQuest[tostring(data.id)]
        if not artifactOneQuest then
            artifactQuest[tostring(data.id)] = data
        else
            if checkint(artifactOneQuest.grade) <= checkint(data.grade)   then
                artifactQuest[tostring(data.id)] = data
            end
        end
    end
end

--[[
    更新神器能量战斗关卡的数据
--]]
function GameManager:GetArtifactQuestByQuestId(questId)
    local artifactQuest = self:GetUserInfo().artifactQuest
    if not self:GetUserInfo().artifactQuest  then
        return {}
    end
    return  artifactQuest[tostring(questId)] or {}
end


--[[
根据难度获取当前最新关卡
@params difficulty int 难度
@return newestQuestId int 难度对应的最新关卡
--]]
function GameManager:GetNewestQuestIdByDifficulty(difficulty)
    if QUEST_DIFF_NORMAL == difficulty then
        return self:GetUserInfo().newestQuestId
    elseif QUEST_DIFF_HARD == difficulty then
        return self:GetUserInfo().newestHardQuestId
    elseif QUEST_DIFF_HISTORY == difficulty then
        return self:GetUserInfo().newestInsaneQuestId
    end
    return 1
end

function GameManager:InitPlotQuestConfDatas()
    local plotQuestConfDatas = {}
    local storyRewardConfs    = CommonUtils.GetConfigAllMess("storyReward", "plot") or {}

    for _, storyRewardConf in pairs(storyRewardConfs) do
        local questId = tostring(storyRewardConf.unlock)
        plotQuestConfDatas[tostring(questId)] = plotQuestConfDatas[tostring(questId)] or {}
        table.insert(plotQuestConfDatas[tostring(questId)], storyRewardConf)
    end
    
    self.userInfo.plotQuestConfDatas = plotQuestConfDatas
end

--[[
是否加入公会
@return result bool 是否加入公会
--]]
function GameManager:IsJoinUnion()
    if checkint(self.userInfo.unionId) > 0 then
        return true
    else
        return false
    end
end
--[[
更新剩余挑战次数
@params stageId int 关卡id
@params challengeTime int 剩余挑战次数
--]]
function GameManager:UpdateChallengeTimeByStageId(stageId, challengeTime)
    if nil == stageId then
        print('cause error when update challenge time>>>>>>>>>>>>>>>>>>>>>>>.', stageId)
        return
    end
    self:GetUserInfo().allQuestChallengeTimes[tostring(stageId)] = challengeTime
end
--[[
根据关卡id获取剩余挑战次数
@params stageId int 关卡id
@return _ int 剩余挑战次数
--]]
function GameManager:GetChallengeTimeByStageId(stageId)
    return self:GetUserInfo().allQuestChallengeTimes[tostring(stageId)]
end
--[[
刷新满星奖励
@params data table {
    chapterId = leftNotDrawnNum
}
@params diffType int 难度
--]]
function GameManager:RefreshCityRewardNotDrawnData(data, diffType)
    for chapterId, leftTimes in pairs(data) do

        self.userInfo.cityRewardNotDrawn[diffType][tostring(chapterId)] = checkint(leftTimes)

    end
end
--[[
根据章节id和delta掉的次数刷新满星奖励数据
@params chapterId int 章节id
@params diffType int 难度
@params delta int 变化的次数
--]]
function GameManager:RefreshCityRewardNotDrawnDataByChapterId(chapterId, diffType, delta)
    if 0 ~= self:GetCityRewardNotDrawnAmount(chapterId, diffType) then
        self.userInfo.cityRewardNotDrawn[diffType][tostring(chapterId)] = self.userInfo.cityRewardNotDrawn[diffType][tostring(chapterId)] + delta
    end
end
--[[
根据章节id获取当前未领取的满星奖励数据
@params chapterId int 章节id
@params diffType int 难度
@return _ int 次数
--]]
function GameManager:GetCityRewardNotDrawnAmount(chapterId, diffType)
    if nil == self:GetUserInfo().cityRewardNotDrawn then
        return 0
    end
    return checkint(self:GetUserInfo().cityRewardNotDrawn[diffType][tostring(chapterId)])
end
--[[
获取本地保存的竞技场对手id
@return id int 竞技场对手id
--]]
function GameManager:GetLoaclPVCRivalPlayerId()
    local pvpKey = string.format('%s_%d',PVC_LOCAL_RIVAL_ID_KEY, checkint(self:GetUserInfo().playerId))
    local id = checkint(cc.UserDefault:getInstance():getStringForKey(pvpKey, '0'))
    return id
end
--[[
向本地存入竞技场对手id
@params playerId int 竞技场对手id
--]]
function GameManager:SetLocalPVCRivalPlayerId(playerId)
    local pvpKey = string.format('%s_%d',PVC_LOCAL_RIVAL_ID_KEY, checkint(self:GetUserInfo().playerId))
    cc.UserDefault:getInstance():setStringForKey(pvpKey, tostring(playerId))
    cc.UserDefault:getInstance():flush()
end
--[[
获取缓存的游戏加速记录
@return _ int 加速倍数
--]]
function GameManager:GetLocalBattleAccelerate()
    local accKey = string.format('%s_%d',BATTLE_ACCELERATE_KEY, checkint(self:GetUserInfo().playerId))
    local a = checknumber(cc.UserDefault:getInstance():getStringForKey(accKey, '1'))
    return a
end
--[[
向本地存入游戏加速记录
@params a number 加速倍数
--]]
function GameManager:SetLocalBattleAccelerate(a)
    local accKey = string.format('%s_%d',BATTLE_ACCELERATE_KEY, checkint(self:GetUserInfo().playerId))
    cc.UserDefault:getInstance():setStringForKey(accKey, a)
    cc.UserDefault:getInstance():flush()
end


function GameManager:isShowHomeRobberyMap()
    return false -- 老接口调用兼容用，其实已经没这个功能了
end


-- today poster userDefault
function GameManager:getPosterTodayKey()
    return string.fmt('IS_IGNORE_POSTER_DAYE_%1', self:GetUserInfo().playerId)
end
function GameManager:getPosterTodayValue()
    return os.date('%Y-%m-%d', getServerTime())
end
function GameManager:isIgnoreTodayPoster()
    local ignoreDayValue = cc.UserDefault:getInstance():getStringForKey(self:getPosterTodayKey(), '')
    return self:getPosterTodayValue() == ignoreDayValue
end


-- today worldBoss userDefault
function GameManager:getWorldBossTodayKey()
    return string.fmt('IS_IGNORE_WORLD_BOSS_DAYE_%1', self:GetUserInfo().playerId)
end
function GameManager:getWorldBossTodayValue()
    return os.date('%Y-%m-%d', getServerTime())
end
function GameManager:isIgnoreTodayWorldBoss()
    local ignoreDayValue = cc.UserDefault:getInstance():getStringForKey(self:getWorldBossTodayKey(), '')
    return self:getWorldBossTodayValue() == ignoreDayValue
end


-- today 3v3MatchBattle userDefault
function GameManager:get3v3MatchBattleTodayKey(matchType)
    return string.fmt('IS_IGNORE_3V3_MATCH_BATTLE_DAYE_%1_%2', self:GetUserInfo().playerId, tostring(matchType))
end

function GameManager:get3v3MatchBattleTodayValue()
    return os.date('%Y-%m-%d', getServerTime())
end
function GameManager:isIgnoreToday3v3MatchBattle(matchType)
    local ignoreDayValue = cc.UserDefault:getInstance():getStringForKey(self:get3v3MatchBattleTodayKey(matchType), '')
    return self:get3v3MatchBattleTodayValue() == ignoreDayValue
end

function GameManager:get3v3MatchBattleTodayKey(matchType)
    return string.fmt('IS_IGNORE_3V3_MATCH_BATTLE_DAYE_%1_%2', self:GetUserInfo().playerId, tostring(matchType))
end


-- today blackGold userDefault
function GameManager:getBlackGoldTodayValue()
    return os.date('%Y-%m-%d', getServerTime())
end
function GameManager:getBlackGoldTodayKey(matchType)
    return string.fmt('IS_IGNORE_BLACK_GOLD_%1_%2', self:GetUserInfo().playerId , matchType)
end
function GameManager:isIgnoreTodayBlackGold(matchType)
    local ignoreDayValue = cc.UserDefault:getInstance():getStringForKey(self:getBlackGoldTodayKey(matchType), '')
    return self:getBlackGoldTodayValue() == ignoreDayValue
end


-- today freeNewbie userDefault
function GameManager:getFreeNewbieTodayValue()
    return os.date('%Y-%m-%d', getServerTime())
end
function GameManager:getFreeNewbieTodayKey()
    return string.fmt('IS_IGNORE_FREE_NEWBIE_%1', self:GetUserInfo().playerId)
end
function GameManager:isIgnoreTodayFreeNewbie()
    local ignoreDayValue = cc.UserDefault:getInstance():getStringForKey(self:getFreeNewbieTodayKey(), '')
    return self:getFreeNewbieTodayValue() == ignoreDayValue
end


function GameManager:getAppoinitData()
    return self:GetUserInfo().appoinitData
end
function GameManager:setAppoinitData(appoinitData)
    self:GetUserInfo().appoinitData = appoinitData
end

function GameManager:getIsDisableAppointShare()
    return self:GetUserInfo().isDisableAppointShare
end
function GameManager:setIsDisableAppointShare(isDisableAppointShare)
    self:GetUserInfo().isDisableAppointShare = checkbool(isDisableAppointShare)
end


--[[
    是否加入工会
--]]
function GameManager:hasUnion()
    return checkint(self:GetUserInfo().unionId)  > 0
end
function GameManager:setUnionId(unionId)
    self:GetUserInfo().unionId = checkint(unionId)
end

--[[
    公会主界面数据
]]
function GameManager:getUnionData()
    return self:GetUserInfo().unionHomeData
end
function GameManager:setUnionData(unionHomeData)
    self:GetUserInfo().unionHomeData = unionHomeData
end
--[[
刷新工会缓存的信息
@params newData table
--]]
function GameManager:updateUnionData(newData)
    for k,v in pairs(newData) do
        if nil ~= self:GetUserInfo().unionHomeData[k] then
            self:GetUserInfo().unionHomeData[k] = v
        end
    end
end
--[[
工会神兽幼崽信息
--]]
function GameManager:GetUnionPetsData()
    return self:GetUserInfo().unionPet
end
function GameManager:SetUnionPetsData(data)
    self:GetUserInfo().unionPet = checktable(data)
end
function GameManager:GetUnionPetDataByPetId(petId)
    return self:GetUnionPetsData()[tostring(petId)]
end
function GameManager:SetUnionPetDataByPetId(petId, data)
    self:GetUnionPetsData()[tostring(petId)] = data
end
--[[
根据工会id删除工会神兽幼崽
@params unionId int 工会id
--]]
function GameManager:ClearUnionPetsByUnionId(unionId)
    for k,v in pairs(self:GetUnionPetsData()) do
        if checkint(unionId) == checkint(v.unionId) then
            self:SetUnionPetDataByPetId(checkint(v.petId), nil)
        end
    end
end
--[[
更新工会神兽幼崽信息
@params petId int 幼崽id
@params data table 信息
--]]
function GameManager:UpdateUnionPetData(petId, data)
    if nil ~= self:GetUnionPetDataByPetId(petId) then
        if data.energyLevel then
            if checkint(data.energyLevel) >= checkint(self:GetUserInfo().unionPet[tostring(petId)].energyLevel) then
                self:GetUserInfo().unionPet[tostring(petId)].energyLevel = checkint(data.energyLevel)
            end
        end

        if data.satietyLevel then
            if checkint(data.satietyLevel) >= checkint(self:GetUserInfo().unionPet[tostring(petId)].satietyLevel) then
                self:GetUserInfo().unionPet[tostring(petId)].satietyLevel = checkint(data.satietyLevel)
            end
        end
    end
end

--[[
设置天城演武防守阵容
@params defendData table 防守阵容
--]]
function GameManager:SetTagMatchDefendData(defendData)
    defendData = defendData or {}
    self.tagMatchDefendData = defendData
end
--[[
获得天城演武防守阵容
@return defendData table 防守阵容
--]]
function GameManager:GetTagMatchDefendData(defendData)
    return self.tagMatchDefendData or {}
end

--[[
设置天城演武防守阵容
@params defendData table 防守阵容
--]]
function GameManager:SetTagMatchSwordPoint(swordPoint)
    self.tagMatchSwordPoint = swordPoint
end
--[[
获得天城演武战斗生命
@return swordPoint int 战斗生命
--]]
function GameManager:GetTagMatchSwordPoint()
    return self.tagMatchSwordPoint
end

--[[
获得 是(1)否(0)有未领取的世界boss试炼奖励
@return worldBossTestReward int 是(1)否(0)
--]]
function GameManager:GetWorldBossTestReward()
    return self.userInfo.worldBossTestReward
end
--[[
设置 是(1)否(0)有未领取的世界boss试炼奖励
@params worldBossTestReward int 是(1)否(0)
--]]
function GameManager:SetWorldBossTestReward(worldBossTestReward)
    self.userInfo.worldBossTestReward = worldBossTestReward
    app.badgeMgr:CheckWorldMapRedPoint()
end

--[[
获得 是(1)否(0)有未领取的新探索奖励
@return worldBossTestReward int 是(1)否(0)
--]]
function GameManager:GetExploreSystemRedPoint()
    return self.userInfo.exploreSystemRedPoint
end
--[[
设置 是(1)否(0)有未领取的新探索奖励
@params exploreSystemRedPoint int 是(1)否(0)
--]]
function GameManager:SetExploreSystemRedPoint(exploreSystemRedPoint)
    self.userInfo.exploreSystemRedPoint = exploreSystemRedPoint
    app.badgeMgr:CheckWorldMapRedPoint()
end


-------------------------------------------------
-- about freeNewbie capsuleData
function GameManager:hasFreeNewbieCapsule()
    return self.hasFreeNewbieCapsule_
end
function GameManager:checkFreeNewbieCapsuleData(capsuleData)
    self.hasFreeNewbieCapsule_  = false
    local freeNewbieCapsuleData = checktable(capsuleData)
    if next(freeNewbieCapsuleData) ~= nil then
        -- 最终大奖 是否 未领取
        if checkint(freeNewbieCapsuleData.finalRewardsHasDrawn) == 0 then
            self.hasFreeNewbieCapsule_ = true
        end
        -- 次数奖励 是否 有未领取的
        if not self.hasFreeNewbieCapsule_ then
            for _, rewardData in ipairs(freeNewbieCapsuleData.timesRewards or {}) do
                if checkint(rewardData.hasDrawn) == 0 then
                    self.hasFreeNewbieCapsule_ = true
                    break
                end
            end
        end
    end
    AppFacade.GetInstance():DispatchObservers(SGL.FRESH_FREE_NEWBIE_CAPSULE_DATA)
end


-------------------------------------------------
-- about worldBoss mapData
function GameManager:getWorldBossMapData()
    return self.userInfo.worldBossMapData_ or {}
end
function GameManager:setWorldBossMapData(mapData)
    -- update worldBoss data
    self.userInfo.worldBossMapData_ = checktable(mapData)
    AppFacade.GetInstance():DispatchObservers(SGL.FRESH_WORLD_BOSS_MAP_DATA)

    -- check min remainSeconds
    local minRemainSeconds = 0
    for _, bossData in pairs(mapData or {}) do
        local curData = os.date("*t" ,bossData.startTime)
        PUSH_LOCAL_TIME_NOTICE.WORLD_BOSS_PUSH_TYPE["1"].time = curData.hour
        local bossEndTime   = checkint(bossData.endTime)
        local remainSeconds = bossEndTime - getServerTime()
        if minRemainSeconds == 0 then
            minRemainSeconds = remainSeconds
        else
            minRemainSeconds = math.min(remainSeconds, minRemainSeconds)
        end
    end

    -- start refresh countdown
    if next(self.userInfo.worldBossMapData_) then
        self:startWorldBossRefreshCountdown_(minRemainSeconds)
    else
        self:stopWorldBossRefreshCountdown_()
    end
end

function GameManager:stopWorldBossRefreshCountdown_()
    if app.timerMgr:RetriveTimer(COUNT_DOWN_TAG_WORLD_BOSS) then
        app.timerMgr:RemoveTimer(COUNT_DOWN_TAG_WORLD_BOSS)
    end
end
function GameManager:startWorldBossRefreshCountdown_(remainSeconds)
    self:stopWorldBossRefreshCountdown_()

    local countTime = math.max(2, checkint(remainSeconds))
    app.timerMgr:AddTimer({name = COUNT_DOWN_TAG_WORLD_BOSS, countdown = countTime, callback = function(countdown)
        if checkint(countdown) <= 0 then
            local appMediator = AppFacade.GetInstance():RetrieveMediator('AppMediator')
            appMediator:syncWorldBossListData()
        end
    end})

    CommonUtils.SetPushLocalOneTypeNoticeByType(PUSH_LOCAL_NOTICE_NAME_TYPE.WORLD_BOSS_PUSH_TYPE)
end


-------------------------------------------------
-- about 3v3 matchBattle
function GameManager:get3v3MatchBattleData()
    return self.userInfo.matchBattle3v3Data_ or {}
end
function GameManager:set3v3MatchBattleData(matchData)
    if matchData then
        -- update 3v3 matchBattle data
        self.userInfo.matchBattle3v3Data_ = checktable(matchData)

        local leftSeconds = checkint(self.userInfo.matchBattle3v3Data_.leftSeconds) + 2
        self.userInfo.matchBattle3v3Data_.endTime = getServerTime() + leftSeconds
        AppFacade.GetInstance():DispatchObservers(SGL.FRESH_3V3_MATCH_BATTLE_DATA)

        -- start refresh countdown
        if next(self.userInfo.matchBattle3v3Data_) then
            self:start3v3MatchBattleRefreshCountdown_(leftSeconds)
        else
            self:stop3v3MatchBattleRefreshCountdown_()
        end
    else
        self.userInfo.matchBattle3v3Data_ = {}
        -- 1.停止倒计时
        self:stop3v3MatchBattleRefreshCountdown_()
        -- 2.发送
        AppFacade.GetInstance():DispatchObservers(SGL.CLOSE_3V3_MATCH)
    end

end

function GameManager:stop3v3MatchBattleRefreshCountdown_()
    if app.timerMgr:RetriveTimer(COUNT_DOWN_TAG_3V3_MATCH_BATTLE) then
        app.timerMgr:RemoveTimer(COUNT_DOWN_TAG_3V3_MATCH_BATTLE)
    end
end
function GameManager:start3v3MatchBattleRefreshCountdown_(remainSeconds)
    self:stop3v3MatchBattleRefreshCountdown_()

    local countTime = math.max(2, checkint(remainSeconds))
    app.timerMgr:AddTimer({name = COUNT_DOWN_TAG_3V3_MATCH_BATTLE, countdown = countTime, callback = function(countdown)
        if checkint(countdown) <= 0 then
            local appMediator = AppFacade.GetInstance():RetrieveMediator('AppMediator')
            appMediator:sync3v3MatchBattleData()
        end
    end})
end



function GameManager:checkOpenHomeModuleList(minLevel, maxLevel)
    local unlockList    = {}
    local moduleConfs   = CommonUtils.GetConfigAllMess('module') or {}
    local mainFuncConfs = CommonUtils.GetConfigAllMess('mainInterfaceFunction', 'common') or {}
    for _, mainFuncConf in pairs(mainFuncConfs) do
        local moduleId   = checkint(mainFuncConf.id)
        local isPrefab   = checkint(mainFuncConf.display) == 1
        local moduleConf = moduleConfs[tostring(moduleId)] or {}
        local openLevel  = checkint(moduleConf.openLevel)
        if not isPrefab and openLevel > checkint(minLevel) then
            if maxLevel then
                if openLevel <= checkint(maxLevel) and CommonUtils.GetModuleAvailable(MODULE_REFLECT[tostring(moduleId)]) then
                    table.insert(unlockList, moduleId)
                end
            else
                if CommonUtils.GetModuleAvailable(MODULE_REFLECT[tostring(moduleId)]) then
                    table.insert(unlockList, moduleId)
                end
            end
        end
    end
    return unlockList
end


--[[
    矫正本地引导数据。防止手动做了引导，再次进入游戏要求重新走引导的卡住问题。
]]
function GameManager:fixLocalGuideData()
    local playerLevel   = checkint(self:GetUserInfo().level)
    local guideDataMap  = checktable(self:GetUserInfo().guide)
    local guideConfs    = CommonUtils.GetConfigAllMess('step', 'guide') or {}
    local guideInfoFunc = function(moduleId)
        local guideInfoData      = {}
        guideInfoData.moduleId   = checkint(moduleId)
        guideInfoData.moduleConf = checktable(guideConfs[tostring(moduleId)])
        guideInfoData.nowStepId  = checkint(guideDataMap[tostring(moduleId)])
        guideInfoData.endStepId  = 0
        for stepId, _ in pairs(guideInfoData.moduleConf) do
            guideInfoData.endStepId = math.max(guideInfoData.endStepId, checkint(stepId))
        end
        guideInfoData.isFinish   = guideInfoData.nowStepId >= guideInfoData.endStepId
        guideInfoData.isBegain   = guideInfoData.nowStepId > 0
        guideInfoData.printLog   = function()
            logInfo.add(5, string.fmt('[ guide module %1 ] nowId: %2, endId: %3, isBegain: %4, isFinish: %5',
                moduleId,
                guideInfoData.nowStepId,
                guideInfoData.endStepId,
                guideInfoData.isBegain,
                guideInfoData.isFinish
            ))
        end
        return guideInfoData
    end

    -------------------------------------------------
    -- get current guide status data
    local guideInfoList = {}
    local moduleIdList  = {
        GUIDE_MODULES.MODULE_LOBBY,        -- 1
        GUIDE_MODULES.MODULE_DRAWCARD,     -- 2
        GUIDE_MODULES.MODULE_TEAM,         -- 3
        GUIDE_MODULES.MODULE_ACCEPT_STORY, -- 100
        GUIDE_MODULES.MODULE_FINISH_STORY, -- 101
        GUIDE_MODULES.MODULE_DISCOVERY,    -- 102
        GUIDE_MODULES.MODULE_PET,          -- 103
    }
    -- logInfo.add(5, '-------------------------------- checkin')
    for i, moduleId in ipairs(moduleIdList) do
        guideInfoList[i] = guideInfoFunc(moduleId)
        -- guideInfoList[i].printLog()
        if i > 1 then
            guideInfoList[i-1].nextGuideInfo = guideInfoList[i]
        end
    end

    -------------------------------------------------
    -- fixed unfinished module
    for _, guideInfo in ipairs(guideInfoList) do
        if guideInfo.nextGuideInfo and guideInfo.nextGuideInfo.isBegain and not guideInfo.isFinish then
            guideInfo.nowStepId = guideInfo.endStepId
            guideInfo.isFinish  = true
        end
    end

    -------------------------------------------------
    -- fixed module stepId
    local lobbyGuideInfo   = guideInfoList[1]
    local cardGuideInfo    = guideInfoList[2]
    local teamGuideInfo    = guideInfoList[3]
    local upgradeGuideInfo = guideInfoList[4]
    local taskGuideInfo    = guideInfoList[5]
    local studyGuideInfo   = guideInfoList[6]
    local petGuideInfo     = guideInfoList[7]
    -- TODO 每个模块的 当前具体步骤矫正 后面再补
    if playerLevel > 1 then
        if not lobbyGuideInfo.isFinish then
            lobbyGuideInfo.nowStepId = lobbyGuideInfo.endStepId
            lobbyGuideInfo.isFinish  = true
            lobbyGuideInfo.isBegain  = true
        end
        if not cardGuideInfo.isFinish then
            cardGuideInfo.nowStepId = cardGuideInfo.endStepId
            cardGuideInfo.isFinish  = true
            cardGuideInfo.isBegain  = true
        end
        if not teamGuideInfo.isFinish then
            teamGuideInfo.nowStepId = teamGuideInfo.endStepId
            teamGuideInfo.isFinish  = true
            teamGuideInfo.isBegain  = true
        end
    end

    -------------------------------------------------
    -- fixed guide stepId
    -- logInfo.add(5, '-------------------------------- fixed')
    for _, guideInfo in ipairs(guideInfoList) do
        if guideInfo.isBegain then
            guideDataMap[tostring(guideInfo.moduleId)] = guideInfo.nowStepId
        end
        -- guideInfo.printLog()
    end
end


-- 判断玩家是否是老玩家
function GameManager:CheckIsVeteran(  )
    if 1 == checkint(self.userInfo.isVeteran) then
        return true
    end
    return false
end

-- 判断玩家是否是回归老玩家
function GameManager:CheckIsRecalled(  )
    if 1 == checkint(self.userInfo.isRecalled) then
        return true
    end
    return false
end

-- 判断回归福利是否开启
function GameManager:CheckIsBackOpen(  )
    return 0 < checkint(self.userInfo.backOpenLeftSeconds)
end

function GameManager:StopBackCountDown()
    if app.timerMgr:RetriveTimer(COUNT_DOWN_BACK) then
        app.timerMgr:RemoveTimer(COUNT_DOWN_BACK)
    end
end

function GameManager:StartBackCountDown(remainSeconds)
    self:StopBackCountDown()

    local countTime = math.max(2, checkint(remainSeconds))
    app.timerMgr:AddTimer({name = COUNT_DOWN_BACK, countdown = countTime, autoDelete = true, callback = function(countdown)
        self.userInfo.backOpenLeftSeconds = countdown
        if checkint(countdown) <= 0 then
            app.dataMgr:ClearRedDotNofication(tostring(RemindTag.RETURNWELFARE), RemindTag.RETURNWELFARE, "[回归福利]-GameManager:StartBackCountDown")
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RETURNWELFARE})
        end
    end})
end


function GameManager:GetNewPlotWatchStatusKey()
    return string.format('NEW_PLOT_WATCH_%d',checkint(self.userInfo.playerId))
end
function GameManager:GetNewPlotWatchStatus()
    return cc.UserDefault:getInstance():getBoolForKey(self:GetNewPlotWatchStatusKey(), false)
end
function GameManager:SetNewPlotWatchStatus(isWatched)
    cc.UserDefault:getInstance():setBoolForKey(self:GetNewPlotWatchStatusKey(), isWatched == true)
    cc.UserDefault:getInstance():flush()
end

-- 获取 当前玩家id
function GameManager:GetPlayerId()
    return checkint(self:GetUserInfo().playerId)
end

-- 是否 为玩家本人
function GameManager:IsPlayerSelf(playerId)
    return self:GetPlayerId() == checkint(playerId)
end

function GameManager:SetClientData(data)
    self.userInfo.clientData = self.userInfo.clientData or {}
    local clientData = json.decode(data.clientData or "{}")
    for key, value in pairs(clientData) do
        self.userInfo.clientData[key] = value
    end
end

function GameManager:GetClientDataByKey(key)
    self.userInfo.clientData = self.userInfo.clientData or {}
    return self.userInfo.clientData[key]
end
return GameManager
