--[[
公告Mediator
--]]
local Mediator = mvc.Mediator

local AppMediator = class("AppMediator", Mediator)

local NAME = "AppMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
-- @type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local httpMgr = AppFacade.GetInstance():GetManager("HttpManager")
local AppCommand = require( 'Game.command.AppCommand')


local scheduler = require('cocos.framework.scheduler')

local CAPTCHA_VIEW_ORDER = 20000

-- 需要检查等级提升的mediator
local NEED_CHECK_LEVEL_UP_MEDIATOR = {
    'StoryMissionsMediator',
    'ExploreSystemMediator',
}

function AppMediator:ctor( viewComponent )
	self.super:ctor(NAME, viewComponent)
    self.nextRoundStart = true --是否开始一天的计时器

    self.tmpCaptchaCallback = nil
end


function AppMediator:InterestSignals()
	local signals = {
        HomeScene_ChangeCenterContainer,
        HomeScene_ChangeCenterContainer_TeamFormation,
        SIGNALNAMES.PlayerLevelUpExchange,
		SIGNALNAMES.CACHE_MONEY,
        POST.LEVEL_GIFT_CHEST.sglName,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI, --更新界面的逻辑
		SIGNALNAMES.Friend_AssistanceList_Callback,
		SIGNALNAMES.Friend_RequestAssistance_Callback,
        --------------- friend ---------------
        SIGNALNAMES.Friend_DelFriend_Callback,
        SIGNALNAMES.Friend_PopupAddFriend_Callback,
        SIGNALNAMES.Friend_AddBlacklist_Callback,
        SIGNALNAMES.Friend_DelBlacklist_Callback,
        SIGNALNAMES.Friend_REMOVE_BUGAT_Callback,
        SIGNALNAMES.SIGNALNAME_FRIEND_AVATAR_STATE,
        --------------- friend ---------------
        --------------- chat ---------------
        SIGNALNAMES.Chat_GetPlayerInfo_Callback,
        SIGNALNAMES.Chat_Assistance_Callback,
        SIGNALNAMES.Chat_Report_Callback,
        --------------- chat ---------------
		--------------- battle ---------------
		SIGNALNAMES.Battle_UI_Create_Battle_Ready,
		SIGNALNAMES.Battle_UI_Destroy_Battle_Ready,
        SIGNALNAMES.QuestComment_CommentView,
        REFRESH_AVATAR_HEAD_EVENT,
        POST.ACTIVITY_DRAW_FIRSTPAY.sglName,
        -- 战斗结束
        BATTLE_COMPLETE_RESULT,
        -- 战斗结束后带服务器交互的数据刷新信号
        'BATTLE_GAME_OVER_WITH_RESPONSE_DATA',
        'BATTLE_REPLAY_OVER',
        'BATTLE_GAME_OVER',
        --------------- battle ---------------
        --------------- task cache data ---------------
        SGL.SYNC_DAILY_TASK_CACHE_DATA,
        SGL.SYNC_ACHIEVEMENT_CACHE_DATA,
        SGL.SYNC_UNION_TASK_CACHE_DATA,
        --------------- task cache data ---------------
        --------------- growth fund cache data ---------------
        SGL.SYNC_ACTIVITY_GROWTH_FUND,
        --------------- growth fund cache data ---------------

        ---------------bossDetail ------------
        EVENT_SHOW_BOSS_DETAIL_VIEW ,
        --story--
        Event_Story_Missions_Jump,--剧情任务跳转
    	EVENT_CHOOSE_A_GOODS_BY_TYPE, -- 显示选择一类道具的弹窗
    	GUIDE_HANDLE_SYSTEM,
        REFRESH_PLAYERNAME_EVENT ,
        SGL.NEXT_TIME_DATE,
        SGL.SYNC_ACTIVITY_HOME,
        SGL.SYNC_ACTIVITY_HOME_ICON,
        SGL.SYNC_FREE_NEWBIE_CAPSULE_DATA,
        SGL.SYNC_WORLD_BOSS_LIST,
        SGL.SYNC_PARTY_BASE_TIME,
        SGL.SYNC_3V3_MATCH_BATTLE_DATA,
        SGL.SYNC_ACTIVITY_PASS_TICKET,
        COUNT_DOWN_ACTION, --用来更新冰场计时器数据的逻辑
        "PHOME_FIRST_LOCK_EVENT_REFRESH"  ,  --第一次绑定任务的刷新
        "SHARE_REQUEST_RESPONSE",
        "REMOVE_CHAT_VIEW",
        UNION_APPLY_EVENT ,
        POST.USER_ACCOUNT_BIND_REAL_AUTH.sglName , -- 实名认证
        POST.USER_QUERY_ACCOUNT_REAL_AUTH.sglName , -- 查询是否是实名认证
        EVENT_UPGRADE_PET, -- 显示堕神升级强化炼化3tab
        SIGNALNAMES.Chat_GetMessage_Callback, --收到系统消息的处理
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
        UPDATE_PLAYER_DATA_REQUEST,    -- 发送 player/syncData 请求
        UPDATE_PLAYER_DATA_RESPONSE,   -- 响应 player/syncData
        EVENT_PAY_MONEY_SUCCESS,         -- 监听 充值成功 如果是 月卡 是补单来的话 要更新 缓存中 member
        POST.CAPTCHA_HOME.sglName,
        POST.SAIMOE_HOME.sglName,
        POST.CAPTCHA_ANSWER.sglName,
        'SHOW_CAPTCHA_VIEW', -- 显示验证码界面,
        POST.ACTIVITY_LUCKY_CAT_DRAW.sglName, --领取招财猫的
        POST.FRIEND_REMARK.sglName, --好友备注
        POST.FOOD_COMPARE_HOME.sglName,
        POST.PLAYER_CLIENT_DATA.sglName,
        POST.ACTIVITY_TIME_LIMIT_LV_UPGRADE_HOME.sglName,
        ---------------处理升级弹窗 ------------
        SGL.HANDLER_UPGRADE_LEVEL_POP,
        ---------------处理升级弹窗 ------------
        ---------------处理宝箱活动获得-----------------
        ACTIVITY_CHEST_REWARD_EVENT,
	}
	return signals
end


function AppMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = checktable(checktable(signal:GetBody()))
	-- dump(body)
    if name == SIGNALNAMES.PlayerLevelUpExchange then
        -- 刷新顶部等级经验
        self.viewComponent:RefreshLevelAndExp()

        -- check is levelUp
        local body = signal:GetBody()
        if app.gameMgr:GetUserInfo().isCardCallOpen == 0  then
            if CommonUtils.UnLockModule(RemindTag.ALL_ROUND) and (checkint(body.oldLevel) < 30 and checkint(body.oldLevel) > 0 ) and checkint(body.newLevel) >= 30   then
                local mainInterfaceFunctionConfig = CommonUtils.GetConfigAllMess('mainInterfaceFunction','common')
                if mainInterfaceFunctionConfig[tostring(MODULE_DATA[tostring(RemindTag.ALL_ROUND)])] then
                    app.gameMgr:GetUserInfo().isCardCallOpen = 1
                end
            end
        end
        if body.isLevel then
            -- 更新主界面的锁定的状态
            local homeMediator = AppFacade.GetInstance():RetrieveMediator('HomeMediator')
            if homeMediator then
                homeMediator:refreshUnlockStatus()
            end

            -- 刷新订单数据
            if CommonUtils.UnLockModule(RemindTag.CARVIEW) then
                -- check enable mainUnlock
                local mainFuncConfs = CommonUtils.GetConfigAllMess('mainInterfaceFunction', 'common') or {}
                if checkint(body.newLevel) == CommonUtils.GetModuleOpenLevel(RemindTag.CARVIEW) and next(mainFuncConfs) ~= nil then
                    -- first mark, set data after post
                    self:setUpgradeUnlockOrderData({})
                end

                local instance = AppFacade.GetInstance():GetManager('TakeawayManager')
                instance:FreshData()
            end

            --如果是在剧情任务界面升级发信号刷新界面
            -- if AppFacade.GetInstance():RetrieveMediator('StoryMissionsMediator') then
            --     AppFacade.GetInstance():DispatchObservers(EVENT_LEVEL_UP)
            -- end
            -- 如果存在此mediator 则升级发送信号刷新界面
            if self:CheckMediatorIsExistsByConf(NEED_CHECK_LEVEL_UP_MEDIATOR) then
                AppFacade.GetInstance():DispatchObservers(EVENT_LEVEL_UP, {newLevel = body.newLevel , oldLevel = body.oldLevel})
            end

            -- 高级米饭心意开启的情况下 添加活动红点
            if checkint(gameMgr:GetUserInfo().levelAdvanceChest) == 1 then
                local levelAdvanceChestConf = CommonUtils.GetConfigAllMess('levelAdvanceChestOpen', 'activity') or {}
                if levelAdvanceChestConf[tostring(body.newLevel)] then
                    -- 添加活动红点
                    gameMgr:GetUserInfo().tips.levelAdvanceChest = 1
                end
            end

            if CommonUtils.GetModuleAvailable(MODULE_SWITCH.LEVEL_REWARD) and gameMgr:GetUserInfo().levelReward == 1 then
                local levelRewardConf = CommonUtils.GetConfigAllMess('levelReward', 'activity') or {}
                for i, v in pairs(levelRewardConf) do
                    local targetNum = checkint(v.targetNum)
                    if body.oldLevel < targetNum and body.newLevel >= targetNum then
                        gameMgr:GetUserInfo().tips.levelReward = 1
                        break
                    end
                end
            end
            -- 神器解锁时，神器指引
            if CommonUtils.UnLockModule(JUMP_MODULE_DATA.ARTIFACT_TAG) and checkint(gameMgr:GetUserInfo().artifactGuide) == 0 then
                gameMgr:GetUserInfo().artifactGuide = 1
                app:DispatchObservers(SGL.REFRES_ARTIFACT_GUIDE_ICON, { countdown = 0, tag = RemindTag.ARTIFACT_GUIDE })
            end
            ------------ 判断区域解锁添加一个小红点 ------------
            -- TODO --
            if (20 == body.newLevel and 20 > body.oldLevel) or
                (40 == body.newLevel and 40 > body.oldLevel) or
                (60 == body.newLevel and 60 > body.oldLevel) then
                local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
                dataMgr:AddRedDotNofication(tostring(RemindTag.WORLDMAP), RemindTag.WORLDMAP)
            end

            -- 获取任务模块开放等级
            local openLevel = checkint(CommonUtils.GetModuleOpenLevel(RemindTag.TASK))
            if body.oldLevel < openLevel and body.newLevel >= openLevel then
                local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
                dataMgr:AddRedDotNofication(tostring(RemindTag.TASK),RemindTag.TASK, "[升级]-upgradeLevel")
                AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.TASK})
            end
            -- TODO --
            ------------ 判断区域解锁添加一个小红点 ------------

            -- 领取升级奖励
            local rewardData  = {}
            local startLevel  = checkint(body.oldLevel) + 1
            local rewardConfs = CommonUtils.GetConfigAllMess('levelReward', 'player') or {}
            for level = startLevel, checkint(body.newLevel)  do
                for _, rewardDataConf in ipairs(checktable(rewardConfs[tostring(level)]).rewards or {}) do
                    table.insert(rewardData, rewardDataConf)
                end
            end
            CommonUtils.DrawRewards(rewardData)

            -- 记录解锁功能模块
            local unlockList = gameMgr:checkOpenHomeModuleList(body.oldLevel, body.newLevel)
            self:appendUpgradeUnlockModuleList_(unlockList)

            -- 显示升级界面
            if checkint(body.newLevel) > CONDITION_LEVELS.ACCEPT_STORY_TASK then
                --升级奖励的逻辑
                if #rewardConfs[tostring(body.newLevel)].rewards > 0  then
                    local UpgradeLevelMediator = require('Game.mediator.UpgradeLevelMediator')
                    local mediator = UpgradeLevelMediator.new({oldLevel = body.oldLevel})
                    self:GetFacade():RegistMediator(mediator)
                end
            end

            -- SDK about
            if isQuickSdk() then
                local AppSDK = require('root.AppSDK')
                AppSDK.GetInstance():AndroidRoleUpload({isFirst = false}) --上传角色信息的逻辑
            end
            if checkint(Platform.id) == XipuAndroid or checkint(Platform.id) == YSSDKChannel then
                local AppSDK = require('root.AppSDK')
                AppSDK.GetInstance():AndroidRoleUpload({type = 'upgrade'}) --上传角色信息的逻辑
            end

            --升级了美区平台需要添加appflyer信息记录
            if isElexSdk() then
                if checkint(body.newLevel) % 5 == 0 then
                    local level_key = string.format('level_%s', tostring(body.newLevel))
                    local AppSDK = require('root.AppSDK')
                    AppSDK.GetInstance():AppFlyerEventTrack(level_key,{af_level = tostring(body.newLevel)})
                elseif checkint(body.newLevel) == 13 then
                    local AppSDK = require('root.AppSDK')
                    AppSDK.GetInstance():AppFlyerEventTrack("level_13",{af_level = "level_13"})
                end
            end

        else
            app.passTicketMgr:ShowUppgradeLevelView()
        end
    elseif name == POST.PLAYER_CLIENT_DATA.sglName then
        local requestData = body.requestData
        app.gameMgr:SetClientData(requestData)
    elseif name == 'SHARE_REQUEST_RESPONSE' then
        if body.rewards then
            gameMgr:GetUserInfo().shareData.shareNum = 1
            CommonUtils.DrawRewards(checktable(body.rewards))
            uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(body.rewards), addBackpack = false})
        else
            local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
            uiMgr:ShowInformationTips(__("恭喜分享成功~~"))
        end
    elseif name == REFRESH_AVATAR_HEAD_EVENT then
        local uiLayer = sceneWorld:getChildByTag(GameSceneTag.UI_GameSceneTag)
        if uiLayer then
            ---@type  HomeTopLayer
            local viewComponent = uiLayer:getChildByTag(GameSceneTag.UI_GameSceneTag)
            viewComponent:RefreshHeadAvatar()

        end

    elseif name == HomeScene_ChangeCenterContainer then
        --更新数据的事件
        local body = signal:GetBody()
        if body == "show" then
            self.viewComponent:ChangeState("show")
        elseif body == 'hide' then
            self.viewComponent:ChangeState("hide")
        elseif body == 'allhide' then
            self.viewComponent:ChangeState("allhide")
        elseif body == 'rightHide' then
            self.viewComponent:ChangeState('rightHide')
        elseif body == 'rightShow' then
            self.viewComponent:ChangeState('rightShow')
        elseif body == 'GONE' then
            self.viewComponent:ChangeState('GONE')
        elseif body == 'OPEN' then
            self.viewComponent:ChangeState('OPEN')
        elseif body == 'shopAllhide' then
            self.viewComponent:ChangeState("allhide")
        end
        if body ~= 'shopAllhide' then
            gameMgr:GetUserInfo().topUIShowType = body
        end
    elseif name ==  REFRESH_PLAYERNAME_EVENT then
        local uiLayer = sceneWorld:getChildByTag(GameSceneTag.UI_GameSceneTag)
        if uiLayer then
            ---@type  HomeTopLayer
            local viewComponent = uiLayer:getChildByTag(GameSceneTag.UI_GameSceneTag)
            viewComponent:RefreshPlayerName()

        end
    elseif name ==  "PHOME_FIRST_LOCK_EVENT_REFRESH" then
        local uiLayer = sceneWorld:getChildByTag(GameSceneTag.UI_GameSceneTag)
        if uiLayer then
            ---@type  HomeTopLayer
            local viewComponent = uiLayer:getChildByTag(GameSceneTag.UI_GameSceneTag)
            viewComponent:RefreshBindingPhoneRed()

        end
        --self.viewComponent:RefreshBindingPhoneRed()

    elseif name == HomeScene_ChangeCenterContainer_TeamFormation then
        --编队相关的信息的逻辑
        self:GetFacade():UnRegsitMediator("TeamFormationMediator")
        -- 刷新头像图标（暂时和主界面立绘一样）
        self:GetViewComponent():updateImageView()
    elseif name == SIGNALNAMES.CACHE_MONEY then
        local originGold = nil
		if body.gold then
			--更新本地缓存数据
            local pGold = checkint(body.gold)
            if pGold < 0 then pGold = 0 end
            originGold = {originGold = gameMgr:GetUserInfo().gold}
            gameMgr:GetUserInfo().gold = pGold
			if body.requestData and checkint(body.requestData.id) == GOLD_ID then
                local leftFreeNum = 0
                for k,v in pairs(gameMgr:GetUserInfo().freeGoldLeftTimes) do
                    leftFreeNum = leftFreeNum + checkint(v)
                end
                if leftFreeNum > 0 then
                    gameMgr:GetUserInfo().freeGoldLeftTimes = checktable(signal:GetBody()).freeGoldLeftTimes
                else
                    local buyGoldRestTimes = checkint(gameMgr:GetUserInfo().buyGoldRestTimes)
    				if buyGoldRestTimes > 0 then
                        buyGoldRestTimes = math.max(0,buyGoldRestTimes - 1)
    					gameMgr:GetUserInfo().buyGoldRestTimes = buyGoldRestTimes
    				end
                end
                PlayAudioClip(AUDIOS.UI.ui_gold_smash.id)
			end
		end
		if body.diamond then
            local pDiamond = checkint(checktable(signal:GetBody()).diamond)
            if pDiamond < 0 then pDiamond = 0 end
			gameMgr:GetUserInfo().diamond = pDiamond
        end
        if body.cookingPoint then
            local pCookPoint = checkint(checktable(signal:GetBody()).cookingPoint)
            if pCookPoint < 0 then pCookPoint = 0 end
			gameMgr:GetUserInfo().cookingPoint = pCookPoint
        end
		if body.hp then
            local pHp = checkint(checktable(signal:GetBody()).hp)
            if pHp < 0 then pHp = 0 end
			-- gameMgr:GetUserInfo().hp = pHp
            gameMgr:UpdateHp(pHp)
			if body.requestData and checkint(body.requestData.id) == HP_ID then
				--体力次数限制
				local str = ''
				str = string.fmt(__('恭喜获得 _value_ 体力'),{_value_ = 60})
				uiMgr:ShowInformationTips(str)
				if gameMgr:GetUserInfo().buyHpRestTimes > 0 then
					gameMgr:GetUserInfo().buyHpRestTimes = gameMgr:GetUserInfo().buyHpRestTimes - 1
				end
			end
		end

        if body.tip then
            local tip = checkint(checktable(signal:GetBody()).tip)
            if tip < 0 then tip = 0 end
            gameMgr:GetUserInfo().tip = tip
        end
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, originGold ) --更新界面相关的ui的逻辑

    elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        --更新界面的逻辑
        local sceneWorld = uiMgr:Scene()
        --添加用户信息相关的状态页面
        local uiLayer = sceneWorld:getChildByTag(GameSceneTag.UI_GameSceneTag)
        local viewComponent = uiLayer:getChildByTag(GameSceneTag.UI_GameSceneTag)
        if viewComponent then
            viewComponent:UpdateCountUI(body)
        end
	elseif name == SIGNALNAMES.Friend_AssistanceList_Callback then
		self:GetFacade():DispatchObservers(FRIEND_ASSISTANCELIST, {data = body})
	elseif name == SIGNALNAMES.Friend_RequestAssistance_Callback then
        self:GetFacade():DispatchObservers(FRIEND_REQUEST_ASSISTANCE, {data = body})

	elseif name == SIGNALNAMES.Battle_UI_Create_Battle_Ready then
		-- 创建战斗准备界面
		self:CreateBattleReadyPopup(body)
    elseif name == SIGNALNAMES.Battle_UI_Destroy_Battle_Ready then
        self:DestroyBattleReadyPopup()

    elseif name == Event_Story_Missions_Jump then
        -- dump(signal:GetBody())
        self:StoryGoModelLayer(signal:GetBody())
    elseif name == EVENT_SHOW_BOSS_DETAIL_VIEW then
        -- 显示boss 详情界面 数据格式是{questId = number }
        local questData =   CommonUtils.GetQuestConf(body.questId or 1) --因为这个里面已经做了关卡的区分 所有不用处理type 的类型
        if questData.monsterInfo and  #questData.monsterInfo  > 0  then
            local BossDetailMediator = require("Game.mediator.BossDetailMediator")
            local mediator = BossDetailMediator.new(body)
            AppFacade.GetInstance():RegistMediator(mediator)
        else
            uiMgr:ShowInformationTips(__('该关卡不存在boss'))
        end

    elseif name == BATTLE_COMPLETE_RESULT then

        -- 战斗结束 处理一些数据
        self:HandleDataAfterBattle(body)

    elseif name == 'BATTLE_GAME_OVER_WITH_RESPONSE_DATA' then
        
        -- 战斗结束 处理一些服务器交互的数据
        self:HandleResponseDataAfterBattle(body)

    elseif name == 'BATTLE_REPLAY_OVER' or name == 'BATTLE_GAME_OVER' then

        -- 调试调用
        local isPassed   = checkint(body.isPassed)
        local resultData = checktable(body.commonParams)
        require('battle_new.util.BattleReportUtils')
        logs('--== isPassed ==--', isPassed)
        if resultData.skadaResult then
            logt(json.decode(resultData.skadaResult), '--== skadaResult ==--', 10)
        end
        if resultData.fightData then
            logt(BattleReportUtils.decodeReport(resultData.fightData), '--== fightData ==--')
        end

    elseif name == EVENT_CHOOSE_A_GOODS_BY_TYPE then

        -- 显示通用弹窗 从一类道具中选择一个添加到外部逻辑
        self:ShowChooseAGoodsByType(body)

    elseif name == EVENT_UPGRADE_PET then

        -- 显示通用场景 堕神升级强化炼化 3tab
        self:ShowPetUpgradeScene(body)

    elseif name == GUIDE_HANDLE_SYSTEM then
        self:HandleGuideSystem()

    elseif name == SGL.NEXT_TIME_DATE then
        --重置时间
        gameMgr:UpdatePlayer(body)
        self.nextRoundStart = true

    elseif name == SGL.SYNC_ACTIVITY_HOME then
        --更新缓存数据刷新主界面活动页面
        app.activityMgr:UpdateActivity(body)

    elseif name == SGL.SYNC_ACTIVITY_HOME_ICON then
        app.activityMgr:UpdateHomeActivityIcon(body)

    elseif name == SGL.SYNC_FREE_NEWBIE_CAPSULE_DATA then
        gameMgr:checkFreeNewbieCapsuleData(body)

    elseif name == SGL.SYNC_WORLD_BOSS_LIST then
        gameMgr:setWorldBossMapData(body.bossList)

    elseif name == SGL.SYNC_3V3_MATCH_BATTLE_DATA then
        local errcode = checkint(body.errcode)
        if errcode == MODULE_CLOSE_ERROR.TAG_MATCH or (body.section and checkint(body.section) == MATCH_BATTLE_3V3_TYPE.CLOSE) then
            gameMgr:set3v3MatchBattleData()
        else
            gameMgr:set3v3MatchBattleData(body)
        end
    elseif name == SGL.SYNC_ACTIVITY_PASS_TICKET then
        local errcode = checkint(body.errcode)
        if errcode == 0 then
            app.passTicketMgr:InitData(body)
        end
    elseif name == SGL.SYNC_PARTY_BASE_TIME then
        unionMgr:setPartyBaseTime(body.partyBaseTime)

    elseif name == POST.LEVEL_GIFT_CHEST.sglName then -- 等级礼包
        --levelChest
        app.activityMgr:UpdateLevelChestData(body.chests)
        -- 添加小红点
        app.badgeMgr:AddChestLevelDataRed()

    elseif name == COUNT_DOWN_ACTION then
        --更新冰场的数据刷新卡牌的新鲜度的逻辑
        local tag = checkint(body.tag)
        local name = body.timerName or ''
        local extraDatas = body.datas or {}
        local activityId   = extraDatas.activityId
        local activityType = extraDatas.activityType

        if tag == RemindTag.ICEROOM then
            xTry(function()
                local iceVigourRecoverSeconds = gameMgr:GetUserInfo().iceVigourRecoverSeconds
                local timerName = tostring(body.timerName)
                local splitNames = string.split(timerName, '_')
                if #splitNames > 0 then
                    local id = checkint(splitNames[2])
                    if iceVigourRecoverSeconds > 0 and id > 0 then
                        local recoverNo = math.floor(checkint(body.timeNum) - checkint(body.countdown)) % iceVigourRecoverSeconds
                        if recoverNo == 0 then
                            local cardInfo = gameMgr:GetCardDataById(id)
                            local vigour = checkint(cardInfo.vigour)
                            local targetVigour = vigour + 1
                            local maxVigour = app.restaurantMgr:GetMaxCardVigourById(id)
                            if targetVigour > maxVigour then
                                targetVigour = maxVigour
                            end
                            gameMgr:UpdateCardDataById(id, {vigour = targetVigour})
                        end
                    end
                end
            end, __G__TRACKBACK__)
        elseif tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY then
            local seconds = checkint(body.countdown)
            -- 倒计时 结束 和 活动结束事件分离
            if seconds <= 0 then

                -- 1. 移除 餐厅活动 倒计时
                timerMgr:RemoveTimer(COUNT_DOWN_TAG_LOBBY_FESTIVAL_ACTIVITY)
                -- 2. 移除 餐厅活动相关数据
                app.activityMgr:RemoveLobbyActivityData()
                -- 3. 分发活动结束
                self:GetFacade():DispatchObservers(LOBBY_FESTIVAL_ACTIVITY_END)
            end
        elseif tag == RemindTag.LOBBY_FESTIVAL_ACTIVITY_PREVIEW then
            local seconds = checkint(body.countdown)
            -- 倒计时 结束 和 活动结束事件分离
            if seconds <= 0 then
                gameMgr:GetUserInfo().restaurantActivityPreview = {}
                timerMgr:RemoveTimer(COUNT_DOWN_TAG_LOBBY_FESTIVAL_PREVIEW_ACTIVITY)
                self:GetFacade():DispatchObservers(LOBBY_FESTIVAL_ACTIVITY_PREVIEW_END)
            end
        elseif name == COUNT_DOWN_TAG_UNION_TASK then
            local seconds = checkint(body.countdown)

            if seconds <= 0 then
                local timerMgr = AppFacade.GetInstance():GetManager('TimerManager')
                local oneDaySenconds = 86400
                local timerInfo = timerMgr:RetriveTimer(COUNT_DOWN_TAG_UNION_TASK)
                if timerInfo then
                    -- 重置倒计时时间
                    gameMgr:GetUserInfo().unionTaskRemainSeconds = oneDaySenconds + 5
                    timerInfo.countdown = oneDaySenconds
                    timerMgr:ResumeTimer(COUNT_DOWN_TAG_UNION_TASK)
                else
                    -- 重新开启倒计时
                    app.unionMgr:AddUnionTaskCountDown(oneDaySenconds)
                end

                gameMgr:GetUserInfo().unionTaskCacheData_ = {}

                app.badgeMgr:CheckUnionRed()
                app.badgeMgr:CheckTaskHomeRed()
                -- 发送 刷新工会任务事件
                self:GetFacade():DispatchObservers(UNION_TASK_REFRESH_EVENT)
            end
        elseif name == app.activityMgr:GetHomeActivityIconTimerName(activityId , activityType) then
            local seconds = checkint(body.countdown)
            if seconds <= 0 then
                if tostring(activityType) == ACTIVITY_TYPE.PASS_TICKET then
                    app.passTicketMgr:SetTimeEndState(true)
                    app.passTicketMgr:SetUpgradeData()
                elseif tostring(activityType) == ACTIVITY_TYPE.CASTLE_ACTIVITY then
                    app:DispatchObservers(CASTLE_END_EVENT, {})
                end
            end
        elseif name == 'BTN_LEVEL_TASK' then
            local seconds = checkint(body.countdown)
            if seconds <= 0 then
                app.gameMgr:GetUserInfo().isShowTimeLimitUpgradeTask = false
                app:DispatchObservers(SGL.REFRESH_TIME_LIMIT_UPGRADE_ICON)
            end
        elseif name == "World_Clock_Time" then
            --更新界面的逻辑
            local sceneWorld = uiMgr:Scene()
            --添加用户信息相关的状态页面
            local uiLayer = sceneWorld:getChildByTag(GameSceneTag.UI_GameSceneTag)
            local viewComponent = uiLayer:getChildByTag(GameSceneTag.UI_GameSceneTag)
            if viewComponent then
                viewComponent:UpdateUTCTime()
            end

            local nameLayer = uiMgr:GetCurrentScene():GetDialogByName("Game.views.WorldClockView")
            if nameLayer and (not tolua.isnull(nameLayer)) then
                nameLayer:UpdateUTCTime()
            end
        end

    elseif name == SIGNALNAMES.Friend_DelFriend_Callback then
        -- 删除好友
        uiMgr:ShowInformationTips(__('删除成功'))
        local mediator = AppFacade.GetInstance():RetrieveMediator('FriendListMediator')
        if mediator then
            mediator:DeleteFriend(body.requestData.friendId)
        else
            local friendIdList = string.split(checkstr(body.requestData.friendId), ',')
            local delFriendIdMap = {}
            for _, friendId in ipairs(friendIdList) do
                delFriendIdMap[tostring(friendId)] = true
            end
            for index = #gameMgr:GetUserInfo().friendList, 1, -1 do
                local friendData = gameMgr:GetUserInfo().friendList[index]
                if delFriendIdMap[tostring(friendData.friendId)] then
                    table.remove(gameMgr:GetUserInfo().friendList, index)
                end
            end
        end
    elseif name == SIGNALNAMES.Friend_PopupAddFriend_Callback then
        -- 添加好友
        uiMgr:ShowInformationTips(__('成功发送请求'))
    elseif name == SIGNALNAMES.Friend_AddBlacklist_Callback then
        -- 加到黑名单
        local temp = {
            avatar = body.avatar,
            level  = checkint(body.level),
            name   = body.name,
            restaurantLevel = checkint(body.restaurantLevel),
            playerId = body.requestData.blacklistId
        }
        local mediator = AppFacade.GetInstance():RetrieveMediator('FriendListMediator')
        if mediator then
            self:GetFacade():DispatchObservers(FRIEND_POPUP_ADD_BLACKLIST, temp)
        else
            if CommonUtils.IsInBlacklist(temp.playerId) then
                uiMgr:ShowInformationTips(__('对方已经在你的黑名单中了'))
            else
                uiMgr:ShowInformationTips(__('添加成功'))
                table.insert(gameMgr:GetUserInfo().blacklist, temp)
                for i,v in ipairs(gameMgr:GetUserInfo().friendList) do
                    if checkint(v.friendId) == checkint(temp.playerId) then
                        table.remove(gameMgr:GetUserInfo().friendList, i)
                    end
                end
            end
        end
    elseif name == SIGNALNAMES.Friend_DelBlacklist_Callback then
        -- 移除黑名单
        uiMgr:ShowInformationTips(__('从黑名单移除'))
        local mediator = AppFacade.GetInstance():RetrieveMediator('FriendListMediator')
        if mediator then
            self:GetFacade():DispatchObservers(FRIEND_POPUP_DEL_BLACKLIST, {blacklistId = body.requestData.blacklistId})
        else
            for i,v in ipairs(gameMgr:GetUserInfo().blacklist) do
                if checkint(v.playerId) == checkint(body.requestData.blacklistId) then
                    table.remove(gameMgr:GetUserInfo().blacklist, i)
                    break
                end
            end
        end
    elseif name == SIGNALNAMES.SIGNALNAME_FRIEND_AVATAR_STATE then

        local friendId    = checkint(body.friendId)
        local cmd         = checkint(body.cmd)
        local commandData = checktable(body.cmdData)
        local bugId       = checkint(commandData.bugId)

        if friendId == checkint(gameMgr:GetUserInfo().playerId) then
            -- 好友帮忙清除了虫子
            if cmd == NetCmd.RequestRestaurantBugClear then
                self:GetFacade():DispatchObservers(SIGNALNAMES.Friend_REMOVE_BUGAT_Callback, {bugId = commandData.bugId})
            end
        end

        for i,v in ipairs(gameMgr:GetUserInfo().friendList) do
            if v.friendId == friendId then
                local isCanUpdate = true
                if cmd == NetCmd.RequestRestaurantBugClear then
                    if bugId == 0 then
                        gameMgr:GetUserInfo().friendList[i].restaurantBug = 1
                        self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                    end
                    break
                elseif cmd == NetCmd.RequestRestaurantBugAppear then
                    gameMgr:GetUserInfo().friendList[i].restaurantBug = 2
                    self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                    break
                elseif cmd == NetCmd.RequestRestaurantBugHelp then
                    gameMgr:GetUserInfo().friendList[i].restaurantBug = 3
                    self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                    break
                elseif cmd == NetCmd.Request2027 then
                    gameMgr:GetUserInfo().friendList[i].restaurantQuestEvent = 1
                    self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                    break
                elseif cmd == NetCmd.RequestRestaurantQuestEventHelp then
                    gameMgr:GetUserInfo().friendList[i].restaurantQuestEvent = 2
                    self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                    break
                elseif cmd == NetCmd.RequestRestaurantQuestEventFighting then
                    gameMgr:GetUserInfo().friendList[i].restaurantQuestEvent = 3
                    self:GetFacade():DispatchObservers(UPDATE_LOBBY_FRIEND_BUG_STATE, {cmd = cmd, friendId = friendId})
                    break
                end
            end
        end
    elseif name == SIGNALNAMES.Chat_GetMessage_Callback then
        --收到系统消息
        local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag) or sceneWorld:getChildByTag(GameSceneTag.Top_Chat_GameSceneTag)
        if chatView and chatView.isAction == false then
            chatView:ReceiveMessage(body)
        end
    elseif name == SIGNALNAMES.Chat_GetPlayerInfo_Callback then
        local datas = signal:GetBody()
        local scene = uiMgr:GetCurrentScene()
        if checkint(datas.requestData.type) == PlayerInfoType.HEADPOPUP then
            if scene:GetDialogByName('common.PlayerHeadPopup') then
                scene:GetDialogByName('common.PlayerHeadPopup'):InitData(datas)
            end
        else
            -- 获取玩家基本信息
            local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
            if chatView and chatView.isAction == false then
                chatView:GetPlayerInfoCallback(datas)
            end
        end
    elseif name == SIGNALNAMES.Chat_Assistance_Callback then
        local data = checktable(signal:GetBody())
        uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(data.rewards), mainExp = checkint(data.mainExp)})
    elseif name == SIGNALNAMES.Chat_Report_Callback then
        local data = checktable(signal:GetBody())
        uiMgr:ShowInformationTips(__('您的举报已经收到，会尽快核实，感谢您的反馈'))
    elseif name == 'REMOVE_CHAT_VIEW' then
        local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
        if chatView and chatView.isAction == false then
            chatView:RemoveChatView()
        end
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        if chatView and chatView.isAction == false then
            chatView:UpdateHelpList()
        end
    elseif name == UPDATE_PLAYER_DATA_REQUEST then

        httpMgr:Post('player/syncData','UPDATE_PLAYER_DATA_RESPONSE',{}, function()
        end, true)
    elseif name == UPDATE_PLAYER_DATA_RESPONSE then
        gameMgr:UpdatePlayer(body, true)
    elseif name == EVENT_PAY_MONEY_SUCCESS then
        local payType = checkint(body.type)
        local retry  = checkint(body.retry)
        if checkint(body.firstPay) == 1 then
            --如果是首充
            self:SendSignal(POST.ACTIVITY_DRAW_FIRSTPAY.cmdName)
        end

        -- 刷新钻石
        local diamondNum
        if payType == PAY_TYPE.PT_ORDINARY then
            diamondNum  = checkint(body.diamond) - checkint(gameMgr:GetUserInfo().diamond)
        end
        CommonUtils.RefreshDiamond(body)

        if  payType == PAY_TYPE.PT_ORDINARY then
            local data = { goodsId = checktable(GAME_MODULE_OPEN).DUAL_DIAMOND and PAID_DIAMOND_ID or DIAMOND_ID , num = diamondNum }
            local rewards = checktable(body.rewards)
            table.insert(rewards, data)
            if table.nums(rewards) > 0 then
                -- if retry == 0 then
                --     CommonUtils.DrawRewards(rewards)
                -- end
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
            end
        elseif payType == PAY_TYPE.PT_MEMBER then
            -- 1. 更新会员
            gameMgr:UpdateMember(body.member)
            -- 2. 更新奖励数据
            local rewards = checktable(body.rewards)
            if table.nums(rewards) > 0 then
                if retry == 0 then
                    -- 2.1 处理奖励
                    CommonUtils.DrawRewards(rewards)
                end
            end
            -- if body.diamond then
            --     -- 处理幻晶石
            --     CommonUtils.DrawRewards({{goodsId = DIAMOND_ID , num = checkint(body.diamond) - checkint(gameMgr:GetUserInfo().diamond)}})
            -- end
            -- 3. 处理奖励弹窗
            -- local showTotalDiamond = 0
            -- local vipConfig = CommonUtils.GetConfigAllMess('vip','player')
            -- for memberId,v in pairs(body.member) do
            --     for i,v in pairs(vipConfig) do
            --         if checkint(v.vipLevel) == checkint(memberId) then
            --             showTotalDiamond = showTotalDiamond + checkint(v.diamond)
            --         end
            --     end
            -- end
            -- if showTotalDiamond ~= 0 then
            --     local diamondNum  = showTotalDiamond
            --     local data = { goodsId = DIAMOND_ID , num = diamondNum }
            --     table.insert(rewards, data)
            -- end
            local diamondNum = checkint(body.diamondNum)
            if diamondNum ~= 0 then
                local data = { goodsId = DIAMOND_ID , num = diamondNum }
                table.insert(rewards, data)
            end
            if table.nums(rewards) > 0 then
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
            end
        elseif payType == PAY_TYPE.PT_TIME_LIMIT_GIFT then
            --限时礼包的逻辑
            local rewards = checktable(body.rewards)
            local productId = checkint(body.productId)
            for i, v in pairs(gameMgr:GetUserInfo().triggerChest or {}) do
                if productId > 0 and productId == checkint(v.productId) then
                    local eventOneName =  string.format("Limit_Gift_%d_%d_%d" ,  checkint(v.productId) ,  checkint(v.iconId) , checkint(v.uiTplId))
                    ---@type TimerManager
                    local timerManager = AppFacade.GetInstance():GetManager("TimerManager")
                    local timeInfo =  timerManager:RetriveTimer(eventOneName)
                    if timeInfo then
                        timeInfo.countdown = 1
                    end
                    break
                end
            end
            if table.nums(rewards) > 0 then
                if retry == 0 then
                    CommonUtils.DrawRewards(rewards)
                end
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards,addBackpack = false})
            end
        elseif payType == PAY_TYPE.PT_GIFT then
            -- if body.diamond then
            --     gameMgr:GetUserInfo().diamond = checkint(body.diamond)
            --     self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = (gameMgr:GetUserInfo().diamond)})
            -- end
            local rewards = checktable(body.rewards)
            if table.nums(rewards) > 0 then
                if retry == 0 then
                    CommonUtils.DrawRewards(rewards)
                end
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards,addBackpack = false})
            end
        elseif payType == PAY_TYPE.PT_LV_GIFT then
			self:SendSignal(POST.LEVEL_GIFT_CHEST.cmdName,{})
            local rewards = checktable(body.rewards)
            if table.nums(rewards) > 0 then
                if retry == 0 then
                    CommonUtils.DrawRewards(rewards)
                end
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards,addBackpack = false})
            end
        elseif payType == PAY_TYPE.PT_LEVEL_ADVANCE_CHEST then
            local rewards = checktable(body.rewards)
            if table.nums(rewards) > 0 then
                if retry == 0 then
                    CommonUtils.DrawRewards(rewards)
                end
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
            end
        elseif payType == PAY_TYPE.PT_PASS_TICKET then
            local rewards = checktable(body.rewards)
            if table.nums(rewards) > 0 then
                if retry == 0 then
                    CommonUtils.DrawRewards(rewards)
                end
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
            end
            -- update pass ticket member
            if app.passTicketMgr and app.passTicketMgr.SetHasPurchasePassTicket then
                app.passTicketMgr:SetHasPurchasePassTicket(1)
            end
        elseif payType == PAY_TYPE.PT_GROWTH_FUND or
               payType == PAY_TYPE.PT_LUCK_NUMBER then
                
            local rewards = checktable(body.rewards)
            if table.nums(rewards) > 0 then
                if retry == 0 then
                    CommonUtils.DrawRewards(rewards)
                end
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
            end
        elseif payType == PAY_TYPE.PT_NEW_LEVEL_REWARD then
            local rewards = checktable(body.rewards)
            if table.nums(rewards) > 0 then
                if retry == 0 then
                    CommonUtils.DrawRewards(rewards)
                end
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
            end
        elseif payType == PAY_TYPE.ASSEMBLY_ACTIVITY_GIFT then
            local rewards = checktable(body.rewards)
            if table.nums(rewards) > 0 then
                if retry == 0 then
                    CommonUtils.DrawRewards(rewards)
                end
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
            end
        elseif payType == PAY_TYPE.NOVICE_WELFARE_GIFT then
            local rewards = checktable(body.rewards)
            if table.nums(rewards) > 0 then
                if retry == 0 then
                    CommonUtils.DrawRewards(rewards)
                end
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
            end
        end
        self:GetFacade():DispatchObservers(EVENT_PAY_MONEY_SUCCESS_UI, body)

    elseif POST.ACTIVITY_DRAW_FIRSTPAY.sglName == name then
        local body = signal:GetBody()
        if gameMgr:GetUserInfo().firstPay == 1 then
            gameMgr:GetUserInfo().firstPay = 3

            -- 首冲完成后开启付费签到
            if gameMgr:GetUserInfo().accumulativePayTwo == 0 and gameMgr:GetUserInfo().isPayLoginRewardsOpen == 0 then
                gameMgr:GetUserInfo().isPayLoginRewardsOpen = 1
            end
            uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards, msg = __('恭喜获得首充奖励')})
            -- 领取后刷新主界面icon
            app:DispatchObservers(SGL.REFRES_FIRST_PAY_ICON)
        end
    elseif SIGNALNAMES.QuestComment_CommentView == name then

        -- 显示关卡评论界面
        self:ShowStageCommentView(body)
    elseif UNION_APPLY_EVENT == name then
        app.badgeMgr:CheckUnionRed()
    elseif POST.USER_ACCOUNT_BIND_REAL_AUTH.sglName == name then -- 绑定
        --EVENTLOG.Log(EVENTLOG.EVENTS.realNameAuth)
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.IDENTIFY)
        local rewards = body.rewards
        local payData  =  body.requestData.payData
        local userInfo = gameMgr:GetUserInfo()
        userInfo.is_guest = 0
        userInfo.has_realauth = 1
        if rewards and table.nums(rewards) > 0 then
            uiMgr:AddDialog('common.RewardPopup',{ rewards = rewards})
        end
        local mediator =   self:GetFacade():RetrieveMediator("RealNameAuthenicationMediator")
        -- 如果mediator存在 删除mediator
        if mediator then
            self:GetFacade():UnRegsitMediator("RealNameAuthenicationMediator")
        end
        if payData and  type(payData) == "table" and table.nums(payData) > 0 then
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():InvokePay(payData)
        end
    elseif POST.USER_QUERY_ACCOUNT_REAL_AUTH.sglName == name then -- 查询是否绑定
        local realAuth = body.realAuth
        local payData  =  body.requestData.payData
        local userInfo = gameMgr:GetUserInfo()
        if realAuth  and checkint(realAuth) == 0 then
            userInfo.is_guest = 1
            userInfo.has_realauth = 0
            local mediator = require("Game.mediator.RealNameAuthenicationMediator").new({payData  =  payData})
            self:GetFacade():RegistMediator(mediator)
        else
            userInfo.is_guest = 0
            userInfo.has_realauth = 1
            if payData and  type(payData) == "table" and table.nums(payData) > 0 then
                local AppSDK = require('root.AppSDK')
                AppSDK.GetInstance():InvokePay(payData)
            end
        end
    elseif POST.CAPTCHA_HOME.sglName == name then
        --获取验证码
        if body and checktable(body).question then
            --有值的时候才处理
            local captchaView = sceneWorld:getChildByName('CaptchaView')
            if not captchaView then
                local arg = {}
                local callback = self.tmpCaptchaCallback
                -- 置空中间量
                self.tmpCaptchaCallback = nil
                arg.cb = callback

                captchaView = require('Game.views.CaptchaView').new(arg)
                display.commonUIParams(captchaView,{po = display.center})
                captchaView:setName("CaptchaView")
                sceneWorld:addChild(captchaView,20000)
            end
            captchaView:ReloadData(body)
        else
            local captchaView = sceneWorld:getChildByName('CaptchaView')
            if nil ~= captchaView then
                -- 如果存在验证码界面 阻塞
            else
                if nil ~= self.tmpCaptchaCallback then
                    -- 如果不存在验证码界面 执行回调
                    self.tmpCaptchaCallback()
                    -- 置空回调
                    self.tmpCaptchaCallback = nil
                end
            end
        end
    elseif POST.SAIMOE_HOME.sglName == name then
        if body.supportGroupId then
            local SaiMoeSupportMediator = require( 'Game.mediator.saimoe.SaiMoeSupportMediator')
            local mediator = SaiMoeSupportMediator.new(body)
            self:GetFacade():RegistMediator(mediator)
        else
            local SaiMoePlatformMediator = require( 'Game.mediator.saimoe.SaiMoePlatformMediator')
            local mediator = SaiMoePlatformMediator.new(body)
            self:GetFacade():RegistMediator(mediator)
        end
    elseif POST.FOOD_COMPARE_HOME.sglName == name then
        local function timecallback( countdown, ...)
            AppFacade.GetInstance():DispatchObservers("SCRATCHER_COUNT_DOWN", { countdown = countdown })
        end
        local timerMgr = AppFacade.GetInstance():GetManager('TimerManager')
        timerMgr:RemoveTimer('scratcher')
        timerMgr:AddTimer({name = 'scratcher', countdown = checkint(body.countDown), callback = timecallback, autoDelete = true} )
        if 0 == body.myChoice then
            local mediator = require( 'Game.mediator.scratcher.ScratcherPlatformMediator').new(body)
            self:GetFacade():RegistMediator(mediator)
        else
            local mediator = require( 'Game.mediator.scratcher.ScratcherTaskMediator').new(body)
            self:GetFacade():RegistMediator(mediator)
        end
    elseif POST.CAPTCHA_ANSWER.sglName == name then
        --获取签题结果
        if checkint(body.result) == 1 then
            --表示回答正确的逻辑
            local captchaView = sceneWorld:getChildByName('CaptchaView')
            if captchaView then
                if captchaView.cb then
                    captchaView.cb() --成功的回调
                else
                    AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CAPTCHA_SUCCESS)
                end
                captchaView:runAction(cc.RemoveSelf:create())
            end
        else
            AppFacade.GetInstance():DispatchSignal(POST.CAPTCHA_HOME.cmdName)
        end
    elseif 'SHOW_CAPTCHA_VIEW' == name then
        -- 显示验证码界面
        self:ShowCaptchaView(body)

    elseif name == SGL.SYNC_DAILY_TASK_CACHE_DATA then
        app.badgeMgr:refreshDailyTaskCacheData(body)
        app:DispatchObservers(SGL.FRESH_DAILY_TASK_VIEW, body)
    elseif name == SGL.SYNC_ACHIEVEMENT_CACHE_DATA then
        app.badgeMgr:initAchievementCacheData(body)
        app:DispatchObservers(SGL.FRESH_ACHIEVEMENT_VIEW, body)
    elseif name == SGL.SYNC_UNION_TASK_CACHE_DATA then
        app.badgeMgr:initUnionTaskCacheData(body)
        app:DispatchObservers(SGL.FRESH_UNION_TASK_VIEW, body)
    elseif name == POST.ACTIVITY_LUCKY_CAT_DRAW.sglName then
        --领取招财猫的
        local requestData = body.requestData
        if requestData then
            CommonUtils.DrawRewards({{goodsId = requestData.currency, num = -checkint(requestData.price)}})
            app:DispatchObservers("LUCK_DRAW_START_ANIMATION", {rewards = body.rewards})
        end
    elseif name == SGL.SYNC_ACTIVITY_GROWTH_FUND then
        app.badgeMgr:initGrowthFundCacheData(body)
    elseif name == POST.FRIEND_REMARK.sglName then
        -- 好友备注
        app.uiMgr:ShowInformationTips(__('备注成功'))
        app:DispatchObservers(FRIEND_REMARK_UPDATE)
    elseif name == POST.ACTIVITY_TIME_LIMIT_LV_UPGRADE_HOME.sglName then
        -- logInfo.add(5, 'ACTIVITY_TIME_LIMIT_LV_UPGRADE_HOMEv----')
        -- local errcode = checkint(body.errcode)
        local time = checkint(body.time)
        app.gameMgr:GetUserInfo().isShowTimeLimitUpgradeTask = time > 0
        app.activityMgr:createCountdownTemplate(time, 'BTN_LEVEL_TASK')
        app:DispatchObservers(SGL.REFRESH_TIME_LIMIT_UPGRADE_ICON)

    elseif name == ACTIVITY_CHEST_REWARD_EVENT then
        app.uiMgr:AddDialog('common.CommonActivityChestView',body)
    elseif name == SGL.HANDLER_UPGRADE_LEVEL_POP then
        -- 引导中：则忽略弹窗，直接标记为提示过了
        if GuideUtils.IsGuiding() then
            if app.activityMgr:IsCanPopTimeLimitUpgradeTaskView() then
                local curKey = app.activityMgr:GetTimeLimitUpgradeConfKey()
                if curKey > 0 then
                    local key = app.activityMgr:GetTimeLimitUpgradeTaskLocalKey(curKey)
                    cc.UserDefault:getInstance():setBoolForKey(key, true)
                    cc.UserDefault:getInstance():flush()
                end
            end
            return 
        end

        local popViewData   = nil
        local isFromHomeMdt = checkint(body.isFromHomeMdt)
        if app.activityMgr:IsCanPopTimeLimitUpgradeTaskView() then
            popViewData = {path = 'home.TimeLimitUpgradeTaskView', params = {isFromHomeMdt = isFromHomeMdt}}
        elseif app.passTicketMgr:IsCanPopPassTicketView(isFromHomeMdt > 0) then
            popViewData = {path = 'Game.views.passTicket.PassTicketUpgradeLevelPopup', params = {isFromHomeMdt = isFromHomeMdt}}
        end

        if popViewData then
            -- 主界面：交给主界面自己走流程弹窗
            if checkint(isFromHomeMdt) > 0 then

                local homeMdt = app:RetrieveMediator('HomeMediator')
                if homeMdt then
                    homeMdt:setCustomPopupData(popViewData)
                end
            -- 非主界面：直接弹窗
            else
                app.uiMgr:AddDialog(popViewData.path, popViewData.params)
            end
        end


        -- 协程实现方式
        -- local co = coroutine.create(function (isFromHomeMdt)
        --     app.activityMgr:ShowTimeLimitUpgradeTaskView()
        --     coroutine.yield()
        --     app.passTicketMgr:ShowUppgradeLevelView(isFromHomeMdt > 0)
        --     coroutine.yield()
            
        -- end)
        -- coroutine.resume(co)
    end
end

--[[
显示验证码界面回调
@params data {
    callback function 验证码正确通过后的回调
}
--]]
function AppMediator:ShowCaptchaView(data)
    self.tmpCaptchaCallback = data.callback
    AppFacade.GetInstance():DispatchSignal(POST.CAPTCHA_HOME.cmdName)
end

function AppMediator:HandleGuideSystem()
    local shareFacade = AppFacade.GetInstance()
    if shareFacade:RetrieveMediator('HomeMediator') then
        shareFacade:BackMediator()
    else
        shareFacade:BackHomeMediator()
    end
    GuideUtils.DispatchStepEvent()
end

-- newbieTaskRemainTime
function AppMediator:CheckNewbieTaskRemainTime()
    timerMgr:RemoveTimer( 'Newbie_Task_Remain_Time' )
    if gameMgr and gameMgr:GetUserInfo().newbieTaskRemainTime > 0 then
        local function timecallback( countdown, remindTag, timeNum, datas)
            if gameMgr and gameMgr:GetUserInfo().newbieTaskRemainTime then
                gameMgr:GetUserInfo().newbieTaskRemainTime = countdown
            end
            if countdown <= 0 then
                AppFacade.GetInstance():DispatchObservers(SGL.REFRES_SEVENDAY_ICON, { countdown = 0, tag = RemindTag.SEVENDAY })
            end
        end
        timerMgr:AddTimer({name = 'Newbie_Task_Remain_Time', countdown = checkint(gameMgr:GetUserInfo().newbieTaskRemainTime), callback = timecallback} )
    end
end


function AppMediator:CheckExploreSystemRemainTime()
    timerMgr:RemoveTimer('EXPLORE_SYSTEM_REMAIN_TIME')
    if gameMgr and gameMgr:GetUserInfo().exploreSystemLeftSeconds > 0 then
        local function timecallback( countdown, remindTag, timeNum, datas)
            if gameMgr and gameMgr:GetUserInfo().exploreSystemLeftSeconds then
                gameMgr:GetUserInfo().exploreSystemLeftSeconds = countdown
            end
            if countdown <= 0 then
                gameMgr:SetExploreSystemRedPoint(1)
            end
        end
        timerMgr:AddTimer({name = 'EXPLORE_SYSTEM_REMAIN_TIME', countdown = checkint(gameMgr:GetUserInfo().exploreSystemLeftSeconds), callback = timecallback} )
    end
end

function AppMediator:CheckExpBuffRemainTime()
    self.buffUpdateHandler = scheduler.scheduleGlobal(handler(self,self.onExpBuffTimerScheduler), 1)
end

function AppMediator:onExpBuffTimerScheduler( dt )
    local expBuff = gameMgr:GetUserInfo().expBuff
    for k,v in pairs(expBuff) do
        if checkint(v) >= 0 then
            expBuff[k] = checkint(v) - 1
        end
    end
    app:DispatchObservers('EXP_BUFF_REMAIN_TIME', expBuff)
end

--[[
对应任务跳转对应页面
@params taskType 任务类型
--]]
function AppMediator:StoryGoModelLayer( taskData  )
    -- dump(taskData)
    if not taskData  then
        return
    end
    if next(taskData) == nil then
        return
    end
    local taskType = checkint(taskData.taskType)
    if taskType == 1 then
        -- 在大堂招待_target_num_位客人
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"}, {name = "AvatarMediator"})
    elseif taskType == 2 then

    elseif taskType == 3 then
        --完成_target_id_地区的_target_num_个外卖订单
    elseif taskType == 4 then
        --通过关卡_target_id_
    elseif taskType == 5 then
        --完成_target_num_个公众外卖订单
    elseif taskType == 6 then
        --消灭在_target_id_中盘踞着的_target_id_
    elseif taskType == 7 then
    elseif taskType == 8 then
        --与_target_id_的_target_id_对话
    elseif taskType == 9 then
    elseif taskType == 10 then
        --在周围打探一下消息
    elseif taskType == 11 then
        --帮助_target_id_完成心愿
    elseif taskType == 12 then
        --收集_target_num_个_target_id_
        -- AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'MapMediator'  })
    elseif taskType == 13 then
        --击败_target_id_
    elseif taskType == 14 then
        --挑战_target_id_
    elseif taskType == 15 then
        --制作_target_num_道料理
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'RecipeResearchAndMakingMediator' })
    elseif taskType == 16 then
        --制作_target_num_道_target_id_
        if taskData.target then
            local foodTable = CommonUtils.GetConfigAllMess('food' ,'goods')
            local targetData =  taskData.target.targetId or {}
            if table.nums(targetData) == 1 then
                local recipeId = foodTable[tostring(targetData[1])].recipeId
                local recipeData = CommonUtils.GetConfigAllMess('recipe', 'cooking')
                local recipeOneData = recipeData[tostring(recipeId)] or {}
                local cookingStyleId = recipeOneData.cookingStyleId
                if cookingStyleId then
                    local ownRecipeData = gameMgr:GetUserInfo().cookingStyles[tostring(cookingStyleId)]
                    local data = {}
                    if ownRecipeData then
                        local isHave = false
                        for k , v in pairs (ownRecipeData) do
                            if checkint(v.recipeId) == checkint(recipeId)  then
                                isHave = true
                                data = v
                                break
                            end
                        end
                        if isHave then
                            data.type = 1
                            AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'RecipeDetailMediator' , params = data})
                            return
                        end
                    end
                end
            end
        end
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'RecipeResearchAndMakingMediator' })
    elseif taskType == 17 then
        --将_target_id_的等级提升至_target_num_级
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'CardsListMediatorNew'})
    elseif taskType == 18 then
        --将_target_id_的阶位提升至_target_num_星
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'CardsListMediatorNew'})
    elseif taskType == 19 then
        --激活技能_target_id_
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'TalentMediator'})
    elseif taskType == 20 then
        --装备技能_target_id_进行战斗
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'MapMediator' })
    elseif taskType == 21 then
        --强化任意天赋技能_target_num_次
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'TalentMediator'})
    elseif taskType == 22 then
        --"完成_target_num_次打劫"
    elseif taskType == 23 then
        --研发_target_num_个新的菜谱
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'RecipeResearchAndMakingMediator' })
    elseif taskType == 24 then
        --"将任意菜谱改良至_target_num_星
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'RecipeResearchAndMakingMediator' })
    elseif taskType == 25 then
        --在冰场内放入任意_target_num_张卡牌
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'IceRoomMediator' })
    elseif taskType == 26 then
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'task.TaskHomeMediator' })
    elseif taskType == 27 then
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'MapMediator' })
    elseif taskType == 28 then
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'MapMediator' })
    -- elseif taskType == 29 then
    elseif taskType == 30 then
    elseif taskType == 31 then
        --  前往_target_id_远征

        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"}, {name = "ExplorationMediator", params = {id = checkint(taskData.target.targetId[1])}})
    elseif taskType == 32 then

        -- 前往_target_id_寻找_target_id_
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"}, {name = "ExplorationMediator", params = {id = checkint(taskData.target.targetId[1])}})
    elseif taskType == 33 then

        -- 前往_target_id_击败_target_id_
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"}, {name = "ExplorationMediator", params = {id = checkint(taskData.target.targetId[1])}})
    elseif taskType == 34 then
        -- 在餐厅招待_target_num_位特需客人
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"}, {name = "AvatarMediator"})
    elseif taskType == 35 then
        -- 提升餐厅规模至_target_id_
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"},{name = "AvatarMediator"})
    elseif taskType == 36 then
        -- 改良_target_num_次任意菜品
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'RecipeResearchAndMakingMediator' })
    elseif taskType == 37 then

    elseif taskType == 38 then
        -- 升级_target_id_的任意战斗技能_target_num_次
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'CardsListMediatorNew'})
    elseif taskType == 39 then
        -- 研究菜谱_target_num_次
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'RecipeResearchAndMakingMediator' })
    elseif taskType == 40 then
        -- 提升_target_id_或_target_id_或_target_id_的评价至_target_id_级
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'RecipeResearchAndMakingMediator' })
    elseif taskType == 41 then
        -- 购买_target_num_个_target_id_
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"}, {name = "MarketMediator"})
    elseif taskType == 42 then
        -- 装饰餐厅时放置_target_num_个_target_id_
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"},{name = "AvatarMediator"})
    elseif taskType == 43 then
        --开发_target_id_的_target_num_道菜谱
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'RecipeResearchAndMakingMediator' })
    elseif taskType == 44 then
        -- 在餐厅中进行_target_num_次备菜
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"},{name = "AvatarMediator"})
    elseif taskType == 45 then
        -- 在餐厅中打败_target_num_次霸王餐食客
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"},{name = "AvatarMediator"})

    elseif taskType == 46 then
        --将_target_num_个飨灵升级至等级_target_id_

        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'CardsListMediatorNew'})
    elseif taskType == 47 then
        --将_target_num_个飨灵阶位提升至_target_id_星

        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'CardsListMediatorNew'})
    elseif taskType == 48 then
        --将_target_num_个飨灵任意战斗技能提升至等级_target_id
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'CardsListMediatorNew'})

    elseif taskType == 49 then
        --将_target_num_个飨灵任意经营技能提升至等级_target_id
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'CardsListMediatorNew'})

    elseif taskType == 50 then
        --收集_target_num_个_target_id_级别的卡牌


    elseif taskType == 51 then
        --拥有_target_num_个好友
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'FriendMediator'})

    elseif taskType == 52 then
        --竞技场战斗_target_num_次
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'PVCMediator'})

    elseif taskType == 53 then
        --竞技场获胜_target_num_次
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'PVCMediator'})

    elseif taskType == 54 then
        --通关邪神遗迹第_target_num_层
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'TowerQuestHomeMediator'})
    elseif taskType == 55 then
        --拥有_target_num_个好友
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'PetDevelopMediator'})

    elseif taskType == 56 then
        --竞技场战斗_target_num_次
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'PetDevelopMediator'})
    elseif taskType == 57 then
        --竞技场获胜_target_num_次
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'PetDevelopMediator'})
    elseif taskType == 58 then
        --通关邪神遗迹第_target_num_层
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'CardsListMediatorNew'})
    else
    end
    -- if AppFacade.GetInstance():RetrieveMediator("StoryMissionsMessageMediator") then
    --  AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMessageMediator")
    -- end
    -- self:GetFacade():UnRegsitMediator("StoryMissionsMediator")
end

--[[
创建战斗准备界面
@params t BattleReadyConstructorStruct 传参
--]]
function AppMediator:CreateBattleReadyPopup(t)
	local battleReadyPopup = require('Game.views.BattleReadyView').new(t)
	battleReadyPopup:setPosition(cc.p(display.cx,display.cy))
    uiMgr:GetCurrentScene():AddDialog(battleReadyPopup)
end
function AppMediator:DestroyBattleReadyPopup()
    local battleReadyPopup = uiMgr:GetCurrentScene():GetDialogByName('BattleReadyView')
    if battleReadyPopup then
        battleReadyPopup:destory()
        uiMgr:GetCurrentScene():RemoveDialog(battleReadyPopup)
    end
end
--[[
显示通用道具弹窗 选择一个添加到外部逻辑
@params t table {
    goodsType GoodsType 道具类型
    callbackSignalName string 选择完后的回调信号
    except list id list 不需要显示的道具id集合
}
--]]
function AppMediator:ShowChooseAGoodsByType(t)
    local tag = 891
    local data = {
        goodsType = t.goodsType,
        callbackSignalName = t.callbackSignalName,
        parameter = t.parameter,
        except = t.except,
        sticky = t.sticky,
        showWaring = t.showWaring,
        waringText = t.waringText,
        noThingText = t.noThingText,
        showStarCondition = t.showStarCondition, -- map
        tag = tag,
        cardId = t.cardId
    }
    local layer = require('common.ChooseAGoodsByGoodsTypePopup').new(data)
    display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.cx, display.cy)})
    layer:setTag(tag)
    uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
显示通用场景 堕神升级强化炼化 3tab
@params t table {
    id int pet id not config id
}
--]]
function AppMediator:ShowPetUpgradeScene(t)
    if nil == t or nil == t.id then
        uiMgr:ShowInformationTips(__('没有选择堕神!!!'))
        return
    end
    -- 初始化管理器
    local petUpgradeMediator = AppFacade.GetInstance():RetrieveMediator('PetUpgradeMediator')
    if not petUpgradeMediator then
        petUpgradeMediator = require('Game.mediator.PetUpgradeMediator').new({mainId = checkint(t.id)})
        AppFacade.GetInstance():RegistMediator(petUpgradeMediator)
    end
end
--[[
战斗结束 处理一些数据
@params data table {
    questId int 关卡id
    questBattleType QuestBattleType 战斗类型
    battleResult PassedBattle 是否通过了战斗
}
--]]
function AppMediator:HandleDataAfterBattle(data)
    local questId = checkint(data.questId)
    local questBattleType = checkint(data.questBattleType)
    local battleResult = checkint(data.battleResult)

    if QuestBattleType.MAP == questBattleType then

        if GUIDE_QUEST_SUCCESS_WORLD_MAP == questId and app.gameMgr:JudgePassedStageByStageId(questId) then

            -- 通过该关卡触发一次清除引导标志位的逻辑
            -- /***********************************************************************************************************************************\
            --  * 此处每次打完这一关都会清除引导标识 暂时认为该关卡不能重复挑战 否则会出现重复引导的问题
            -- \***********************************************************************************************************************************/
            GuideUtils.ClearModuleData(GUIDE_MODULES.MODULE_WORLDMAP)

        end
    elseif QuestBattleType.MURDER == questBattleType and battleResult == PassedBattle.SUCCESS then
        -- 杀人案活动首次击杀boss播放对应剧情
        local bossId = app.murderMgr:GetUnlockBossId()
        if bossId > 0 then
            local questIdList = app.murderMgr:GetQuestIdByBossId(bossId)
            if questIdList[tostring(questId)] then
                local storyId = app.murderMgr:GetBossPassedStoryId()
                local backHomeMediator = false -- 剧情播放完毕是否回到主界面
                local currentBossId = app.murderMgr:GetCurrentBossId()
                if bossId ~= currentBossId then
                    backHomeMediator = true
                end
                app.murderMgr:ShowActivityStory(
                    {
                        storyId          = storyId,
                        backHomeMediator = true,
                    }
                )
            end
        end
    end
end
--[[
战斗结束 处理数据 该数据为和服务器交互的数据
@params data map {
    questBattleType QuestBattleType 战斗类型
    responseData map 服务器请求的数据
}
--]]
function AppMediator:HandleResponseDataAfterBattle(data)
    local questBattleType = data.questBattleType
    local responseData = data.responseData

    if QuestBattleType.LUNA_TOWER == questBattleType then
        self:RefreshDataAfterLunaTowerBattle(responseData)
    end
end
--[[
战斗后刷新luna塔里的数据
@params responseData map 服务器请求的数据
--]]
function AppMediator:RefreshDataAfterLunaTowerBattle(responseData)
    local requestData = responseData.requestData
    if nil ~= requestData then
        local fightResultStr = requestData.fightResult
        if nil ~= fightResultStr then
            local fightResult = json.decode(fightResultStr)
            if nil ~= fightResult then

                -- 刷新luna塔卡牌的状态
                local cardData = nil
                local isPassed = requestData.isPassed
                local passedHpPercent = PassedBattle.FAIL == isPassed and 0 or nil
                local passedErgPercent = PassedBattle.FAIL == isPassed and 0 or nil

                for cardId, statusData in pairs(fightResult) do

                    cardData = app.gameMgr:GetCardDataByCardId(checkint(cardId))
                    if nil ~= cardData then
                        app.gameMgr:UpdateCardDataById(
                            checkint(cardData.id),
                            {
                                lunaTowerHp = checknumber(passedHpPercent or statusData.hp),
                                lunaTowerEnergy = checknumber(passedErgPercent or statusData.energy)
                            }
                        )
                    end

                end

            end
        end
    end
end


function AppMediator:OnRegist(  )
    if isEliteSDK() then
        local eliteLayer = display.newLayer(display.cx , display.cy , { ap = display.CENTER,  size = display.size})
        sceneWorld:addChild(eliteLayer,1000)
        local playerLabel = display.newLabel(display.SAFE_R -10 , 15 , fontWithColor(14,{fontSize = 20 ,  ap = display.RIGHT_CENTER  , text = ""}))
        eliteLayer:addChild(playerLabel)
        playerLabel:setString( "UID : " .. app.gameMgr:GetUserInfo().playerId)
    end
    local sceneWorld = uiMgr:Scene()
    --添加用户信息相关的状态页面
    local uiLayer = sceneWorld:getChildByTag(GameSceneTag.UI_GameSceneTag)
    if uiLayer then
        local viewComponent = uiLayer:getChildByTag(GameSceneTag.UI_GameSceneTag)
        if not viewComponent then
            viewComponent = require('home.HomeTopLayer').new()
            display.commonUIParams(viewComponent, {ap = cc.p(0.5, 1), po = cc.p(display.width * 0.5, display.height)})
            uiLayer:addChild(viewComponent,GameSceneTag.UI_GameSceneTag, GameSceneTag.UI_GameSceneTag)
        else
            viewComponent:UpdateCountUI()
        end
        uiMgr:UpdatePurchageNodeState(false)
        viewComponent:setName('home.HomeTopLayer')
        self:SetViewComponent(viewComponent)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_Story_SubmitMissions,AppCommand)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_Regional_SubmitMissions,AppCommand)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_AssistanceList,AppCommand)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_RequestAssistance,AppCommand)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_WOLDMAP_UNLOCK,AppCommand)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_DelFriend,AppCommand)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_PopupAddFriend,AppCommand)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_AddBlacklist,AppCommand)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_DelBlacklist,AppCommand)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_Chat_GetPlayInfo,AppCommand)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_Chat_Assistance,AppCommand)
        self:GetFacade():RegistSignal(COMMANDS.COMMAND_Chat_Report,AppCommand)

        -- 注册请求订单信息的信号
        local ShopCommand = require( 'Game.command.ShopCommand')
        self:GetFacade():RegistSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder, ShopCommand)

        regPost(POST.ACTIVITY_DRAW_FIRSTPAY)
        regPost(POST.USER_QUERY_ACCOUNT_REAL_AUTH)
        regPost(POST.LEVEL_GIFT_CHEST)
        regPost(POST.CAPTCHA_HOME)
        regPost(POST.SAIMOE_HOME)
        regPost(POST.CAPTCHA_ANSWER)
        regPost(POST.ACTIVITY_LUCKY_CAT)
        regPost(POST.ACTIVITY_LUCKY_CAT_DRAW)
        regPost(POST.FRIEND_REMARK)
        regPost(POST.FOOD_COMPARE_HOME)
        regPost(POST.PLAYER_CLIENT_DATA)
        regPost(POST.ACTIVITY_TIME_LIMIT_LV_UPGRADE_HOME, true)

        viewComponent.viewData.navBackButton:setOnClickScriptHandler(function(sender)
            -- print('------------',uiMgr:GetCurrentScene().contextName)
            PlayAudioByClickNormal()
            GuideUtils.DispatchStepEvent()
            
            local shareFacade = self:GetFacade()
            if shareFacade:RetrieveMediator( 'TeamFormationMediator' ) then
                shareFacade:DispatchObservers(TeamFormationScene_ChangeCenterContainer)
                return
            end

            -- uiMgr:PopGameScene()
            local shareRouter = self:GetFacade():RetrieveMediator("Router")
            -- shareRouter:ClearMediators(
            -- {"HomeMediator","TeamFormationMediator"}
            -- )
            if shareFacade:RetrieveMediator('CardsListMediatorNew') then
                --卡牌页面的回退逻辑
                local mediatorCards = shareFacade:RetrieveMediator("CardsListMediatorNew")
                mediatorCards:BackAction()
            elseif shareFacade:RetrieveMediator('BossStoryMediator')  then
                if GAME_MODULE_OPEN.SKIN_COLLECTION then
                    app.router:Dispatch({name = 'BossStoryMediator'}, {name = "collection.roleIntroduction.RoleIntroductionMainMediator"})
                else
                    local mediatorCards = shareFacade:RetrieveMediator("BossStoryMediator")
                    mediatorCards:BackAction()
                end    
            elseif shareFacade:RetrieveMediator('CardGatherRewardMediator')  then
                local mediatorCardsReward = shareFacade:RetrieveMediator("CardGatherRewardMediator")
                mediatorCardsReward:BackAction()
            elseif shareFacade:RetrieveMediator('NPCManualHomeMediator') then
                if GAME_MODULE_OPEN.SKIN_COLLECTION then
                    app.router:Dispatch({name = 'NPCManualHomeMediator'}, {name = "collection.roleIntroduction.RoleIntroductionMainMediator"})
                else
                    AppFacade.GetInstance():BackHomeMediator({showHandbook = true})
                end
            elseif shareFacade:RetrieveMediator('ExplorationMediator') then
                app.badgeMgr:CheckOrderRed()

                AppFacade.GetInstance():UnRegsitMediator("ExplorationMediator")
                local mediator = shareFacade:RetrieveMediator("CardEncyclopediaMediator")
                if mediator then
                    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "GONE")
                end
                -- shareFacade:BackMediator()
                return
            elseif shareFacade:RetrieveMediator('ActivityPropExchangeMediator') then
                local mediatorCards = shareFacade:RetrieveMediator("ActivityPropExchangeMediator")
                mediatorCards:BackAction()
            elseif shareFacade:RetrieveMediator('ActivityExchangeLargeMediator') then
                local mediatorCards = shareFacade:RetrieveMediator("ActivityExchangeLargeMediator")
                mediatorCards:BackAction()
                return
            elseif shareFacade:RetrieveMediator('MaterialTranScriptMediator') then
                local mediator = shareFacade:RetrieveMediator("MaterialTranScriptMediator")
                mediator:BackMediatorSaveData()
            elseif  shareFacade:RetrieveMediator('SeasonLiveMediator') then
                local mediator = shareFacade:RetrieveMediator("SeasonLiveMediator")
                mediator:BackMediatorSaveData()
            elseif shareFacade:RetrieveMediator('summerActivity.carnie.CarnieCapsuleMediator') then
                self:GetFacade():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},
                {name = 'summerActivity.SummerActivityHomeMapMediator', params = {}})
                return
            elseif shareFacade:RetrieveMediator('FishingGroundMediator') then
                local mediator = shareFacade:RetrieveMediator("FishingGroundMediator")
                mediator:BackAction()
                return
            elseif shareFacade:RetrieveMediator('privateRoom.PrivateRoomThemeMediator') then
                local mediatorCards = shareFacade:RetrieveMediator("privateRoom.PrivateRoomThemeMediator")
                mediatorCards:BackAction()
                return
            elseif shareFacade:RetrieveMediator('PrivateRoomFriendMediator') then
                local mediatorCards = shareFacade:RetrieveMediator("PrivateRoomFriendMediator")
                mediatorCards:BackAction()
                return
            elseif shareFacade:RetrieveMediator('privateRoom.PrivateRoomHomeMediator') then
                self:GetFacade():RetrieveMediator("Router"):Dispatch({name =  'HomeMediator'} , {name =  "HomelandMediator" })
                return
            elseif shareFacade:RetrieveMediator('activity.ArtifactRoad.ArtifactRoadMediator') then
                shareRouter:RegistBackMediators(true)
                return
            elseif shareFacade:RetrieveMediator('ptDungeon.PTDungeonHomeMediator') then
                shareRouter:RegistBackMediators(true)
                return
            elseif shareFacade:RetrieveMediator('exploreSystem.ExploreSystemMediator') then
                shareRouter:RegistBackMediators(true)
                return
            else
                shareFacade:BackMediator()
            end
            shareRouter:RegistBackMediators()
        end)
    end

    local remainTime = checkint(gameMgr:GetUserInfo().tomorrowLeftSeconds)
    self.updateHandler = scheduler.scheduleGlobal(function()
        --用来判断当前时间到达了24点是否
        if self.nextRoundStart then
            local startTime = getLoginServerTime()
            local remainTime = checkint(gameMgr:GetUserInfo().tomorrowLeftSeconds)
            if remainTime > 0 then
                local curTime = getServerTime()
                local diff = (curTime - startTime)
                if diff > 0 then
                    local countdown = remainTime - diff
                    if countdown <= 0 then
                        self.nextRoundStart = false
                        gameMgr:GetUserInfo().tomorrowLeftSeconds = 0
                        xTry(function()
                            httpMgr:Post('player/syncData', SGL.NEXT_TIME_DATE, {}, function() end, true)
                            self:clearDailyCacheData()
                            self:syncHomeActivityhomeData()
                            self:syncHomeActivityhomeIconData()
                        end,__G__TRACKBACK__)
                    end
                end
            end
        end
    end,60)
    app.badgeMgr:CheckPetPurgeLeftSeconds()
    self:CheckNewbieTaskRemainTime()
    self:CheckExploreSystemRemainTime()
    self:CheckExpBuffRemainTime()
    --- 下面是启动菜谱的相对模块
    app.badgeMgr:GetUpgradeRecipeLevelRed()
    app.badgeMgr:AddRecipeTimeInfoRed()
    app.exploresMgr:AddGetFirstExporeTimer()
    app.badgeMgr:AddChestLevelDataRed()
    app.badgeMgr:CheckHomeInforRed()
    app.activityMgr:AddSummerActivityTimer()
    app.unionMgr:AddUnionTaskCountDown()
    app.activityMgr:AddSaiMoeTimer()
    app.activityMgr:AddSaiMoeCloseTimer()

    self:syncGrowthFundData()

    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PUBLIC_ORDER) then
        CommonUtils.SetPushLocalOneTypeNoticeByType(PUSH_LOCAL_NOTICE_NAME_TYPE.PUBLISH_ORDER_RECOVER_TYPE)
    end
    CommonUtils.SetPushLocalOneTypeNoticeByType(PUSH_LOCAL_NOTICE_NAME_TYPE.LOVE_FOOD_RECOVER_TYPE)
end
function AppMediator:OnUnRegist(  )
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_CACHE_MONEY)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Story_SubmitMissions)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Regional_SubmitMissions)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_AssistanceList)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_RequestAssistance)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_DelFriend)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_PopupAddFriend)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_AddBlacklist)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_DelBlacklist)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Chat_GetPlayInfo)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Chat_Assistance)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Chat_Report)
    -- 解除请求订单信息的信号
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder)

    unregPost(POST.USER_QUERY_ACCOUNT_REAL_AUTH  )
    unregPost(POST.ACTIVITY_DRAW_FIRSTPAY)
    unregPost(POST.LEVEL_GIFT_CHEST)
    unregPost(POST.CAPTCHA_HOME)
    unregPost(POST.SAIMOE_HOME)
    unregPost(POST.CAPTCHA_ANSWER)
    unregPost(POST.ACTIVITY_LUCKY_CAT)
    unregPost(POST.ACTIVITY_LUCKY_CAT_DRAW)
    unregPost(POST.FRIEND_REMARK)
    unregPost(POST.FOOD_COMPARE_HOME)
    unregPost(POST.PLAYER_CLIENT_DATA)
    unregPost(POST.ACTIVITY_TIME_LIMIT_LV_UPGRADE_HOME)

    uiMgr:UpdatePurchageNodeState(false)
    if self.updateHandler then
        scheduler.unscheduleGlobal(self.updateHandler)
    end
    if self.buffUpdateHandler then
        scheduler.unscheduleGlobal(self.buffUpdateHandler)
        self.buffUpdateHandler = nil
    end
end

function AppMediator:CheckIceroomLeftSeconds()
    --冰场的逻辑
    if gameMgr:GetUserInfo().iceroomLeftSeconds > 0 then
        local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
        timerMgr:RemoveTimer('ICEROOM_ENTRY_RED_HERT') --移除旧的计时器，活加新计时器
        timerMgr:AddTimer({name = 'ICEROOM_ENTRY_RED_HERT',countdown = checkint(gameMgr:GetUserInfo().iceroomLeftSeconds), tag = RemindTag.ICEROOM, isDelete = true} )
    end
end

function AppMediator:CheckMediatorIsExistsByConf(conf)
    local isExists = false
    local AppFacadeIns = AppFacade.GetInstance()
    for i, mediatorName in ipairs(conf) do
        if AppFacadeIns:RetrieveMediator(mediatorName) then
            isExists = true
            break
        end
    end
    return isExists
end

--[[
显示关卡评论界面
@params data table {
    stageId int 关卡id
    stageTitleText string 关卡评论标题
}
--]]
function AppMediator:ShowStageCommentView(data)
    local stageId = checkint(data.stageId)
    local stageTitleText = tostring(data.stageTitleText)

    local passed = true
    if QuestBattleType.MAP == CommonUtils.GetQuestBattleByQuestId(stageId) then
        passed = gameMgr:JudgePassedStageByStageId(stageId)
    end

    local questCommentMediator = require('Game.mediator.QuestCommentMediator').new({
        stageId = stageId,
        stageTitleText = stageTitleText,
        lock = (not passed)
    })
    self:GetFacade():RegistMediator(questCommentMediator)
end



--[[
获取顶部层大小
--]]
function AppMediator:GetTopLayerSize()
    if self:GetViewComponent() then
        return self:GetViewComponent():getContentSize()
    else
        return cc.size(0, 0)
    end
end


function AppMediator:syncHomeActivityhomeData()
    httpMgr:Post('Activity/home/appMediator', SGL.SYNC_ACTIVITY_HOME, {}, true)
end
function AppMediator:syncHomeActivityhomeIconData()
    httpMgr:Post('Activity/homeIcon', SGL.SYNC_ACTIVITY_HOME_ICON, {}, true)
end
function AppMediator:syncFreeNewbieCapsuleData()
    if GAME_MODULE_OPEN.FREE_NEWBIE_CAPSULE then
        httpMgr:Post('Gambling/freeNewbie/appMediator', SGL.SYNC_FREE_NEWBIE_CAPSULE_DATA, {}, true)
    end
end

function AppMediator:sync3v3MatchBattleData()
    httpMgr:Post('Activity/kofArena/appMediator', SGL.SYNC_3V3_MATCH_BATTLE_DATA, {}, true)
end

function AppMediator:syncWorldBossListData()
    httpMgr:Post('worldBossQuest/bossList', SGL.SYNC_WORLD_BOSS_LIST, {}, true)
end

function AppMediator:syncPartyBaseTime()
    httpMgr:Post('Union/partySyncBaseTime', SGL.SYNC_PARTY_BASE_TIME, {}, true)
end

function AppMediator:syncGrowthFundData()
    local growthFundCacheData_ = app.gameMgr:GetUserInfo().growthFundCacheData_
    -- 没有进入日常界面才会请求
    if GAME_MODULE_OPEN.GROWTH_FUND and checkint(app.gameMgr:GetUserInfo().payLevelRewardOpened) > 0 and growthFundCacheData_.isReques ~= true then
        growthFundCacheData_.isReques = true
        httpMgr:Post('Activity/payLevelReward/appMediator', SGL.SYNC_ACTIVITY_GROWTH_FUND, {}, true)
    end
end

function AppMediator:syncDailyTaskCacheData()
    local dailyTaskCacheData_ = app.gameMgr:GetUserInfo().dailyTaskCacheData_
    -- 没有进入日常界面才会请求
    if dailyTaskCacheData_.isRequestDailyTask ~= true then
        dailyTaskCacheData_.isRequestDailyTask = true
        httpMgr:Post('dailyTask/home/appMediator', SGL.SYNC_DAILY_TASK_CACHE_DATA, {}, true)
    end
    -- -- 只有在没有可领取日常任务奖励时才会请求
    -- if dailyTaskCacheData_ and (checkint(dailyTaskCacheData_.daily) < 0 or checkint(dailyTaskCacheData_.activePoint) < 0) then
    --     httpMgr:Post('dailyTask/home/appMediator', SGL.SYNC_DAILY_TASK_CACHE_DATA, {}, true)
    -- end
end

function AppMediator:syncAchievementCacheData(args)
    -- 初始时只会有 canReceiveCount
    local achievementCacheData_ = gameMgr:GetUserInfo().achievementCacheData_
    if achievementCacheData_ and achievementCacheData_.unreceivedTaskList then
        app.badgeMgr:refreshAchievementCacheData(args)
    else
        httpMgr:Post('task/taskList/appMediator', SGL.SYNC_ACHIEVEMENT_CACHE_DATA, {}, true)
    end
end

function AppMediator:syncUnionTaskCacheData(args)
    local unionTaskCacheData_ = gameMgr:GetUserInfo().unionTaskCacheData_
    if unionTaskCacheData_ and unionTaskCacheData_.unreceivedTaskList then
        app.badgeMgr:refreshUnionTaskCacheData(args)
    else
        httpMgr:Post('Union/task/appMediator', SGL.SYNC_UNION_TASK_CACHE_DATA, {}, true)
    end
end

function AppMediator:clearDailyCacheData()
    gameMgr:GetUserInfo().dailyTaskCacheData_ = {}
    app.badgeMgr:CheckTaskHomeRed()
end

-- about unlock function module
function AppMediator:getUpgradeUnlockModuleKey_()
    local gameManager = AppFacade.GetInstance():GetManager('GameManager')
    return string.fmt('UPGRADE_LEVEL_UNLOCK_MODULE_%1', gameManager:GetUserInfo().playerId)
end
function AppMediator:getUpgradeUnlockModuleList()
    local upgradeUnlockModuleStr = cc.UserDefault:getInstance():getStringForKey(self:getUpgradeUnlockModuleKey_(), '')
    return string.split2(upgradeUnlockModuleStr, ',')
end
function AppMediator:setUpgradeUnlockModuleList(unlockList)
    cc.UserDefault:getInstance():setStringForKey(self:getUpgradeUnlockModuleKey_(), table.concat(unlockList or {}, ','))
    cc.UserDefault:getInstance():flush()
end
function AppMediator:appendUpgradeUnlockModuleList_(unlockList)
    if table.nums(unlockList or {}) < 1 then return end

    -- merge unlockList
    local upgradeUnlockModuleMap  = {}
    local upgradeUnlockModuleList = self:getUpgradeUnlockModuleList()
    table.insertto(upgradeUnlockModuleList, unlockList or {})

    -- remove duplicates
    local moduleConfs = CommonUtils.GetConfigAllMess('module') or {}
    for _, moduleId in ipairs(upgradeUnlockModuleList) do
        local moduleConf = moduleConfs[tostring(moduleId)] or {}
        local openLevel  = checkint(moduleConf.openLevel)
        upgradeUnlockModuleMap[tostring(moduleId)] = {id = checkint(moduleId), level = openLevel}
    end

    -- re-sort
    local upgradeUnlockModuleData = table.values(upgradeUnlockModuleMap)
    table.sort(upgradeUnlockModuleData, function(a, b)
        return checkint(a.level) < checkint(b.level)
    end)

    -- save
    upgradeUnlockModuleList = table.valuesAt(upgradeUnlockModuleData, 'id')
    self:setUpgradeUnlockModuleList(upgradeUnlockModuleList)
end


-- about unlock order function
function AppMediator:getUpgradeUnlockOrderKey_()
    local gameManager = AppFacade.GetInstance():GetManager('GameManager')
    return string.fmt('UPGRADE_LEVEL_UNLOCK_ORDER_%1', gameManager:GetUserInfo().playerId)
end
function AppMediator:getUpgradeUnlockOrderData()
    local upgradeUnlockOrderStr = cc.UserDefault:getInstance():getStringForKey(self:getUpgradeUnlockOrderKey_(), '')
    if string.len(upgradeUnlockOrderStr) <= 0 then
        return nil
    else
        return json.decode(upgradeUnlockOrderStr)
    end
end
function AppMediator:setUpgradeUnlockOrderData(tableData)
    if tableData then
        cc.UserDefault:getInstance():setStringForKey(self:getUpgradeUnlockOrderKey_(), json.encode(tableData))
    else
        cc.UserDefault:getInstance():setStringForKey(self:getUpgradeUnlockOrderKey_(), '')
        cc.UserDefault:getInstance():deleteValueForKey(self:getUpgradeUnlockOrderKey_())
    end
    cc.UserDefault:getInstance():flush()
end


return AppMediator
