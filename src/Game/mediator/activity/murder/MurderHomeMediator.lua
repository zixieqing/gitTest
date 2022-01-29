--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）主界面Mediator
]]
local MurderHomeMediator = class('MurderHomeMediator', mvc.Mediator)

function MurderHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'MurderHomeMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
    self.homeData = nil
end
-------------------------------------------------
-- inheritance method

function MurderHomeMediator:Initial(key)
    self.super.Initial(self, key)
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.activity.murder.MurderHomeScene')
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TabTipsButtonCallback))
    viewData.advanceBtn:setOnClickScriptHandler(handler(self, self.AdvanceButtonCallback))
    viewData.rewardsBtn:setOnClickScriptHandler(handler(self, self.RewardsButtonCallback))
    viewData.storyBtn:setOnClickScriptHandler(handler(self, self.StoryButtonCallback))
    viewData.collectedBtn:setOnClickScriptHandler(handler(self, self.CollectedButtonCallback))
    viewData.exchangeBtn:setOnClickScriptHandler(handler(self, self.ExchangeButtonCallback))
    viewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
    viewData.pointProgressBtn:setOnClickScriptHandler(handler(self, self.PointProgressButtonCallback))
    viewData.clueBtn:setOnClickScriptHandler(handler(self, self.ClueButtonCallback))
    viewData.clueSpine:registerSpineEventHandler(handler(self, self.ClueSpineEndHandler), sp.EventType.ANIMATION_END)
    viewData.clockSpine:registerSpineEventHandler(handler(self, self.ClockSpineEndHandler), sp.EventType.ANIMATION_END)

    -- app.murderMgr:SetHomeData(self.ctorArgs_)
    -- -- 刷新界面
    -- self:InitView()
end

function MurderHomeMediator:InterestSignals()
    local signals = {
        POST.MURDER_HOME.sglName,
        POST.MURDER_RECEIVE_BOSS_REWARDS.sglName,
        POST.MURDER_STORY_UNLOCK.sglName,
        MURDER_UPGRADE_EVENT,
        MURDER_BOSS_COUNTDOWN_UPDATE,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
        MURDER_PROGRESSBAR_REMINDICON_REFRESH,
        NEXT_TIME_DATE,
	}
	return signals
end
function MurderHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.MURDER_HOME.sglName then -- home
        app.murderMgr:SetHomeData(checktable(body))
        app.murderMgr:StartBOSSCountdown()
        -- 刷新界面
        self:InitView()
        -- self:GetViewComponent():DrawBossRewardsAnimation() 
    elseif name == POST.MURDER_STORY_UNLOCK.sglName then -- 刷新顶部状态栏
        local requestData = body.requestData
        local mediatorName = requestData.mediatorName
        if mediatorName and mediatorName == "MurderHomeMediator" then
            app.murderMgr:UnlockStory(requestData.storyId)
        end
    elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then -- 刷新顶部状态栏
        self:GetViewComponent():UpdateGoodsNum()
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:GetViewComponent():UpdateGoodsNum()
    elseif name == MURDER_UPGRADE_EVENT then -- 时钟升级
        self:GetViewComponent():ClockUpgradeAnimation(body.newClockLevel)
    elseif name == POST.MURDER_RECEIVE_BOSS_REWARDS.sglName then -- 领取boss奖励
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
        app.murderMgr:DrawBossRewards(body.requestData.bossId)
        if app.murderMgr:GetCurrentBossId() == 0 then
            self:UpdateClockState()
        else
            self:GetViewComponent():DrawBossRewardsAnimation()
        end
    elseif name == MURDER_BOSS_COUNTDOWN_UPDATE then -- 更新boss倒计时
        self:GetViewComponent():UpdateBossCountdown(body.countdown)
    elseif name == MURDER_PROGRESSBAR_REMINDICON_REFRESH then
        self:UpdateRemindIconState()
    elseif name == NEXT_TIME_DATE then
        self:UpdateHomeData()
    end
end

function MurderHomeMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    regPost(POST.MURDER_HOME)
    regPost(POST.MURDER_RECEIVE_BOSS_REWARDS)
    regPost(POST.MURDER_STORY_UNLOCK)
    PlayBGMusic(app.murderMgr:GetBgMusic(AUDIOS.GHOST.Food_ghost_dancing.id))
    self:SendSignal(POST.MURDER_HOME.cmdName)
end
function MurderHomeMediator:OnUnRegist()
    AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    PlayBGMusic()
    unregPost(POST.MURDER_HOME)
    unregPost(POST.MURDER_STORY_UNLOCK)
    unregPost(POST.MURDER_RECEIVE_BOSS_REWARDS)
end
-------------------------------------------------
-- handler method
--[[
提示按钮点击回调
--]]
function MurderHomeMediator:TabTipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-34'})
end
--[[
推进按钮点击回调
--]]
function MurderHomeMediator:AdvanceButtonCallback( sender )
    PlayAudioByClickNormal()
    local state = app.murderMgr:GetClockState()
    if state == MURDER_CLOCK_STATE.UPGRADE then -- 升级
        app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderAdvanceMediator'})
    elseif state == MURDER_CLOCK_STATE.BOSS then -- boss
        if app.murderMgr:isClosed() then
            app.uiMgr:ShowInformationTips(__('当前活动已结束'))
            return
        end
        app:RetrieveMediator('Router'):Dispatch({name = 'activity.murder.MurderHomeMediator'}, {name = 'activity.murder.MurderInvestigationMediator'}, {isBack = true})
    elseif state == MURDER_CLOCK_STATE.REWARD then -- 领奖
        self:SendSignal(POST.MURDER_RECEIVE_BOSS_REWARDS.cmdName, {bossId = app.murderMgr:GetUnlockBossId()})
    elseif state == MURDER_CLOCK_STATE.FINAL then -- 回顾
        local skinMode = app.murderMgr.skinMode
        if not skinMode then
            -- 播放pv剧情
            local config = CommonUtils.GetConfigAllMess('building', 'newSummerActivity')
            local storyId = config[tostring(table.nums(config))].storyId2
            if storyId then
                local storyPath  = string.format('conf/%s/newSummerActivity/story.json', i18n.getLang())
                local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(storyId), path = storyPath, guide = false, cb = function () end, isHideBackBtn = true})
                storyStage:setPosition(display.center)
                sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
            end                   
            return 
        end
                   

        if skinMode and  skinMode == "one" then
            -- 第一次换皮 改为播放story3
            local paramConfig = CommonUtils.GetConfigAllMess('param' , 'newSummerActivity')
            local storyId = paramConfig["1"].story3
            if storyId then
                local storyPath  = string.format('conf/%s/newSummerActivity/story.json', i18n.getLang())
                local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(storyId), path = storyPath, guide = true, cb = function(sender)
                    local unlockStoryInfo = app.murderMgr:GetHomeData()
                    local isUnlock = false
                    for i, v in pairs(unlockStoryInfo) do
                        if checkint(v) == storyId then
                            isUnlock = true
                            break
                        end
                    end

                    if not isUnlock then
                        self:SendSignal(POST.MURDER_STORY_UNLOCK.cmdName , {storyId = storyId , mediatorName = "MurderHomeMediator"})
                    end
                end})
                storyStage:setPosition(display.center)
                sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
            end
        end
    end
end
--[[
奖励预览按钮点击回调
--]]
function MurderHomeMediator:RewardsButtonCallback( sender )
    PlayAudioByClickNormal()
    app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderRewardPreviewMediator'})
end
--[[
剧情收录按钮点击回调
--]]
function MurderHomeMediator:StoryButtonCallback( sender )
    PlayAudioByClickNormal()
    app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderStoryMediator'})
end
--[[
收集材料按钮点击回调
--]]
function MurderHomeMediator:CollectedButtonCallback( sender )
    PlayAudioByClickNormal()
    if app.murderMgr:isClosed() then
        app.uiMgr:ShowInformationTips(__('当前活动已结束'))
        return
    end
    app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderChessboardMediator'})
end
--[[
交换按钮点击回调
--]]
function MurderHomeMediator:ExchangeButtonCallback( sender )
    PlayAudioByClickNormal()
    app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderStoreMediator'})
end
--[[
抽奖按钮点击回调
--]]
function MurderHomeMediator:DrawButtonCallback( sender )
    PlayAudioByClickNormal()
    app:RetrieveMediator('Router'):Dispatch({name = 'activity.murder.MurderHomeMediator'}, {name = 'activity.murder.MurderMirrorMediator'}, {isBack = true})
end
--[[
点数奖励按钮点击回调
--]]
function MurderHomeMediator:PointProgressButtonCallback( sender )
    PlayAudioByClickNormal()
    app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderPointRewardsMediator', params = {homeData = app.murderMgr:GetHomeData()}})
end
--[[
线索按钮点击回调
--]]
function MurderHomeMediator:ClueButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    local viewComponent = self:GetViewComponent()
    viewComponent:RunClueAnimation()
end
--[[
线索spine结束事件
--]]
function MurderHomeMediator:ClueSpineEndHandler( event )
    if event.animation == 'play' then
        local skinMode = app.murderMgr.skinMode
        if not skinMode then
            local clueMediator = require('Game.mediator.activity.murder.MurderClueMediator').new()
            AppFacade.GetInstance():RegistMediator(clueMediator)
            return 
        end

        if skinMode == "one" then
            local point = app.murderMgr:GetPointNum()
            local storyDamagePointConf = CommonUtils.GetConfigAllMess('storyDamagePoint' , 'newSummerActivity')
            local totalCount = table.nums(storyDamagePointConf)
            local maxCount = checkint(storyDamagePointConf[tostring(totalCount)].targetNum)
            -- 支线剧情全部可以解锁 可以播放story4
            if point >= maxCount then
                local paramConfig = CommonUtils.GetConfigAllMess('param' , 'newSummerActivity')
                local storyId = paramConfig["1"].story4
                if storyId then
                    local storyPath  = string.format('conf/%s/newSummerActivity/story.json', i18n.getLang())
                    local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(storyId), path = storyPath, guide = true, cb = function(sender)
                        local unlockStoryInfo = app.murderMgr:GetHomeData()
                        local isUnlock = false
                        for i, v in pairs(unlockStoryInfo) do
                            if checkint(v) == storyId then
                                isUnlock = true
                                break
                            end
                        end
                        if not isUnlock then
                            self:SendSignal(POST.MURDER_STORY_UNLOCK.cmdName , {storyId = storyId , mediatorName = "MurderHomeMediator"})
                        end
                    end})
                    storyStage:setPosition(display.center)
                    sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
                end
            else
                if app.murderMgr.skinMode == "one" then
                    app.uiMgr:ShowInformationTips(__('神秘的彩蛋'))
                else
                    local goodsId = app.murderMgr:GetPointGoodsId()
                    local goodConf = CommonUtils.GetConfig('goods' , 'goods' , goodsId)
                    local name = goodConf.name
                    app.uiMgr:ShowInformationTips(app.murderMgr:GetPoText( string.fmt(
                            __('_name_ 不足') , {_name_ = name}
                    )))
                end
            end
            app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
        end
       
	end
end
--[[
时钟spine结束事件
--]]
function MurderHomeMediator:ClockSpineEndHandler( event )
    if string.find(event.animation, 'play') then -- 判断是否是play系列动作
        local clockLevel = app.murderMgr:GetClockLevel()
        local config = CommonUtils.GetConfig('newSummerActivity', 'building', clockLevel)
        local storyId = config.storyId1
        -- 播放剧情
        app.murderMgr:ShowActivityStory(
            {
                storyId = storyId,
            }
        )
        -- 刷新界面
        self:UpdateModuleState()
    end
end
-------------------------------------------------
-- get /set

-------------------------------------------------
-- private method
--[[
初始化页面
--]]
function MurderHomeMediator:InitView()
    local view = self:GetViewComponent()
    local moneyIdMap = {}
    moneyIdMap[tostring(app.murderMgr:GetMurderHpId())] = app.murderMgr:GetMurderHpId()
    view:ReloadMoneyBar(moneyIdMap, false)
    local homeData = app.murderMgr:GetHomeData()
    -- 判断是否需要领取信件
    if checkint(homeData.isDrawMailRewards) == 0 then
        self:DrawnMailRewards()
        -- 显示初始剧情
        self:ShowPrologueStory()
    end
    self:UpdateModuleState()
    self:UpdateClockState()
    self:UpdatePointProgressBar()
    self:UpdateRemindIconState()
    
end
--[[
刷新模块状态
--]]
function MurderHomeMediator:UpdateModuleState()
    local viewComponent = self:GetViewComponent()
    local clockLevel = app.murderMgr:GetClockLevel()
    -- 获取已经解锁的模块
    local moduleConfig = CommonUtils.GetConfigAllMess('moduleUnlock', 'newSummerActivity')
    local unlockMap = {}
    for i, v in pairs(moduleConfig) do
        if checkint(v.grade) <= clockLevel then
            unlockMap[tostring(v.type)] = true
        end
    end
    viewComponent:UpdateCollectedLockState(unlockMap[MURDER_MOUDLE_TYPE.QUEST] == nil and true or false)
    viewComponent:UpdateStoreLockState(unlockMap[MURDER_MOUDLE_TYPE.STORE] == nil and true or false)
    viewComponent:UpdateCapsuleLockState(unlockMap[MURDER_MOUDLE_TYPE.CAPSULE] == nil and true or false)
    viewComponent:UpdatePointRewardsLockState(unlockMap[MURDER_MOUDLE_TYPE.CAPSULE] == nil and true or false)
    viewComponent:UpdateClueLockState(unlockMap[MURDER_MOUDLE_TYPE.CAPSULE] == nil and true or false)
end
--[[
刷新时间状态
--]]
function MurderHomeMediator:UpdateClockState()
    local viewComponent = self:GetViewComponent()
    local state = app.murderMgr:GetClockState()
    viewComponent:UpdateClockState(state)
end
--[[
刷新点数进度条
--]]
function MurderHomeMediator:UpdatePointProgressBar()
    local viewComponent = self:GetViewComponent()
    local config = CommonUtils.GetConfigAllMess('damageAccumulative', 'newSummerActivity')
    local sortKeys = sortByKey(config)
    local targetNum = config[sortKeys[#sortKeys]].num
    local point = app.murderMgr:GetPointNum()
    viewComponent:UpdatePointProgressBar(point, checkint(targetNum))
end
--[[
刷新红点状态
--]]
function MurderHomeMediator:UpdateRemindIconState()
    local mainRemindIconState = false
    mainRemindIconState = self:UpdatePointRemindIcon() or mainRemindIconState
    mainRemindIconState = self:UpdateClockRewardsRemindIcon() or mainRemindIconState
    if mainRemindIconState then
        app.dataMgr:AddRedDotNofication(tostring(RemindTag.MURDER),RemindTag.MURDER)
    else
        app.dataMgr:ClearRedDotNofication(tostring(RemindTag.MURDER),RemindTag.MURDER)
    end
end
--[[
刷新点数进度条红点
--]]
function MurderHomeMediator:UpdatePointRemindIcon()
    local viewComponent = self:GetViewComponent()
    local rewardsData = app.murderMgr:GetHomeData().hasDrawnDamagePointRewards
    local point = app.murderMgr:GetPointNum()
    local config = CommonUtils.GetConfigAllMess('damageAccumulative', 'newSummerActivity')
    for k, v in pairs(config) do
        if checkint(v.num) <= point then
            local isDraw = false
            for _, value in ipairs(rewardsData) do
                if checkint(k) == checkint(value) then
                    isDraw = true
                    break
                end
            end
            if not isDraw then
                viewComponent:UpdatePointRemindIcon(true)
                return true
            end
        end
    end
    viewComponent:UpdatePointRemindIcon(false)
    return false
end
--[[
刷新时钟升级奖励红点
--]]
function MurderHomeMediator:UpdateClockRewardsRemindIcon()
    local homeData = app.murderMgr:GetHomeData()
    local viewComponent = self:GetViewComponent()
    if checkint(homeData.hasClockOverTimesDrawn) == 0 then
        local config = CommonUtils.GetConfig('newSummerActivity', 'overTimeReward', 1)
        local clockLevel = app.murderMgr:GetClockLevel()
        if clockLevel >= checkint(config.gradeId) then
            viewComponent:UpdateClockRewardsRemindIcon(true)
            return true
        end
    end
    viewComponent:UpdateClockRewardsRemindIcon(false)
    return false
end
--[[
领取初始信件奖励
--]]
function MurderHomeMediator:DrawnMailRewards()
    app:RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'activity.murder.MurderMailMediator'})
end
--[[
显示序章剧情
--]]
function MurderHomeMediator:ShowPrologueStory()
    local config = CommonUtils.GetConfig('newSummerActivity', 'param', 1)
    app.murderMgr:ShowActivityStory(
        {
            storyId = checkint(config.story1),
        }
    )
end
--[[
更新home数据
--]]
function MurderHomeMediator:UpdateHomeData()
    self:SendSignal(POST.MURDER_HOME.cmdName)
end
-------------------------------------------------
-- public method


return MurderHomeMediator
