--[[
奖励mediator
--]]
local Mediator = mvc.Mediator
---@class CastleMainMediator :Mediator
local CastleMainMediator = class("CastleMainMediator", Mediator)
local NAME = "Game.mediator.castle.CastleMainMediator"
CastleMainMediator.NAME = NAME
---@type TimerManager
local timerMgr = app.timerMgr
function CastleMainMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.homeData =  nil
    self.parseConfig = nil  -- 配表的解析
end


function CastleMainMediator:InterestSignals()
    return {
        POST.SPRING_ACTIVITY_HOME.sglName,
        POST.SPRING_ACTIVITY_UNLOCK_STORY.sglName,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
        CASTLE_END_EVENT
    }
end

function CastleMainMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    if name == POST.SPRING_ACTIVITY_HOME.sglName then
        self.homeData = body
        self:PlayStoryPlot(1)
        self:UpdateUI()
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT  then
        local viewComponent = self:GetViewComponent()
        if viewComponent and ( not tolua.isnull(viewComponent)) then
            self:CheckMemoriesLightRed()
            self:CheckMemoriesLockRed()
            viewComponent:UpdatePrograss()
        end
    elseif name == POST.SPRING_ACTIVITY_UNLOCK_STORY.sglName then
        local requestData = body.requestData
        self.homeData.story = self.homeData.story or {}
        self.homeData.story[#self.homeData.story+1] = requestData.storyId
    elseif name == CASTLE_END_EVENT  then
        app.activityMgr:ShowBackToHomeUI()
    end
end
function CastleMainMediator:PlayStoryPlot(storyId , callFunc)
    local isPlay = true
    for k, v in pairs(self.homeData.story) do
        if  checkint(v) == storyId  then
            isPlay = false
            break
        end
    end
    if isPlay then
        local storyStage = require('Frame.Opera.OperaStage').new({id = storyId, path = string.format("conf/%s/springActivity/story.json",i18n.getLang()), guide = true, cb = function(sender)
            -- play bg music
            PlayBGMusic(AUDIOS.WYS.FOOD_WYS_GUILINGGAO_SAD.id)

            self:SendSignal(POST.SPRING_ACTIVITY_UNLOCK_STORY.cmdName , {
                storyId = storyId
            })
            if callFunc then
                callFunc()
            end
        end})
        storyStage:setPosition(display.center)
        sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
    else
        if callFunc then
            callFunc()
        end
    end
end
-------------------------------------------------
-- inheritance method
function CastleMainMediator:Initial(key)
    self.super.Initial(self, key)
    local viewComponent = require("Game.views.castle.CastleMainView").new()
    app.uiMgr:SwitchToScene(viewComponent)
    self:SetViewComponent(viewComponent)

    local viewData = viewComponent.viewData
    -- 进入主界面的回调事件
    viewData.enterBtn:setOnClickScriptHandler(handler(self, self.EnterBattleMapClick))
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackHomeMediator))
    -- 记忆之宿回调事件
    display.commonUIParams(viewData.leftBottomLayout , {cb = handler(self, self.MermoryChainClick)})
    -- 记忆枷锁回调事件
    display.commonUIParams(viewData.rightBottomLayout , {cb = handler(self, self.MermoryNightClick)})
    -- 领取排行回调事件
    display.commonUIParams(viewData.RankBtn , {cb = handler(self, self.RewardsRankClick)})
    -- 领取钥匙回调事件
    display.commonUIParams(viewData.rewardBtn , {cb = handler(self, self.RewardsKeysClick)})
    -- 返回按钮
    --display.commonUIParams(viewData.backBtn , {animate = false ,  cb = handler(self, self.BackHomeMediator)})
    -- 功能说明
    display.commonUIParams(viewData.tabNameLabel , {cb = handler(self, self.TipModuleExplain)})
    viewComponent:EnterMainAction()
end
---@return SpringActivityConfigParser
function CastleMainMediator:GetConfigParse()
    if not self.parseConfig then
        ---@type DataManager
        local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
        self.parseConfig = dataMgr:GetParserByName('springActivity')
    end
    return self.parseConfig
end
function CastleMainMediator:GetHomeData()
    return  self.homeData
end
function CastleMainMediator:isClosed()
    return not self:GetHomeData() and true or checkint(self:GetHomeData().isEnd) == 1
end
function CastleMainMediator:SetUIIsVisible()
    ---@type CastleMainView
    local viewComponent = self:GetViewComponent()
    viewComponent:SetUIIsVisible(true)
end
--==============================--
---@Description: 解析配表
---@author : xingweihao
---@date : 2018/10/16 11:37 AM
--==============================--
function  CastleMainMediator:GetConfigDataByName(name  )
    local parseConfig = self:GetConfigParse()
    local configData  = parseConfig:GetVoById(name)
    return configData
end
function CastleMainMediator:UpdateUI()
    self:SetUIIsVisible()
    self:CheckRewarkKeysRed()
    self:UpdatePrograss()
    self:CheckMemoriesLightRed()
    self:CheckMemoriesLockRed()

end
--==============================--
---@Description: 检测领取钥匙的红点判断
---@author : xingweihao 
---@date : 2019/3/4 7:38 PM 
--==============================--
function CastleMainMediator:CheckRewarkKeysRed()
    local homeData = self:GetHomeData()
    local ticketReceive = homeData.ticketReceive
    local index  =  0
    local currentTime = getServerTime()
    print("currentTime = " , currentTime)

    if self:isClosed() then
        local rewardBtn = self:GetViewComponent().viewData.rewardBtn
        rewardBtn:stopAllActions()
        rewardBtn:getChildByName('redIcon'):setVisible(false)
    else
        for i, timeData in pairs(ticketReceive) do
            -- 检测是否转化
            local timeDatas = timeData
            if  checkint(timeDatas.hasDrawn) == 0   then
                -- 将字符串时间转化为时间戳时间
                timeDatas.startTimeS =  timerMgr:GetTimeSeverTime(timeDatas.startTime)
                timeDatas.endTimeS =  timerMgr:GetTimeSeverTime(timeDatas.endTime)
                if currentTime >=  timeDatas.startTimeS  and currentTime < timeDatas.endTimeS  then
                    timeDatas.distance = timeDatas.endTimeS - currentTime
                    timeDatas.hasDrawn = 2
                    index = i
                end
            end
        end
        if index > 0 and index <=3   then
            local viewComponent = self:GetViewComponent()
            local rewardBtn = viewComponent.viewData.rewardBtn
            local redIcon = rewardBtn:getChildByName("redIcon")
            ---@type CastleMainView
            local viewComponent = self:GetViewComponent()
            local viewData = viewComponent.viewData
            viewData.rewardBtn:stopAllActions()
            viewData.rewardBtn:runAction(
                cc.RepeatForever:create(
                    cc.Sequence:create(
                        cc.CallFunc:create(
                            function()
                                local isHave = false
                                for index , timeDatas in pairs(ticketReceive) do
                                    if ticketReceive[index].hasDrawn ~= 1  then
                                        if currentTime >=  timeDatas.startTimeS  and currentTime < timeDatas.endTimeS  then
                                            timeDatas.distance = timeDatas.endTimeS - currentTime
                                            timeDatas.hasDrawn = 2
                                            isHave = true
                                        else
                                            if  checkint(timeDatas.hasDrawn) ~= 1 then
                                                timeDatas.hasDrawn = 0
                                            end
                                        end
                                    end
                                end
                                redIcon:setVisible(isHave)
                            end
                        ),
                        cc.DelayTime:create(1)
                    )
                )
            )
        end
    end
end
--==============================--
---@Description: 检测记忆之宿的红点情况
---@author : xingweihao
---@date : 2019/4/2 2:19 PM
--==============================--

function CastleMainMediator:CheckMemoriesLightRed()
    local luckyConsumeConfig = CommonUtils.GetConfigAllMess('luckyConsume',  'springActivity' )or {}
    local consumeData = luckyConsumeConfig['1'].consume
    local isRed = true
    for index , goodsData in pairs( consumeData) do
        local ownerNum = CommonUtils.GetCacheProductNum(goodsData.goodsId)
        local needNum = checkint(goodsData.num )
        if ownerNum  < needNum then
            isRed = false
            break
        end
    end
    ---@type CastleMainView
    local viewComponent  = self:GetViewComponent()
    viewComponent:SetMemoriesLightVisible(isRed)
end
function CastleMainMediator:CheckMemoriesLockRed()
    local plotPointRewardsConfig = CommonUtils.GetConfigAllMess('plotPointRewards',  'springActivity' )or {}
    local homeData = self:GetHomeData()
    local plotPointRewards = homeData.plotPointRewards
    local isRed = false
    local  plotPointRewardsTable = {}
    for i, v in pairs(plotPointRewards) do
        plotPointRewardsTable[tostring(v)] = v
    end
    for i = 1, table.nums(plotPointRewardsConfig) do
        local plotPointRewardsOnrConfig = plotPointRewardsConfig[tostring(i)]or {}
        if not  plotPointRewardsTable[tostring(plotPointRewardsOnrConfig.id)] then
            local isNeed = true 
            for i, goodsData  in pairs(plotPointRewardsOnrConfig.consume or {}) do
                local ownerNum = CommonUtils.GetCacheProductNum(goodsData.goodsId)
                local needNum = checkint(goodsData.num )
                if ownerNum  < needNum then
                    isNeed = false
                    break
                end
            end
            isRed = isNeed
            break
        end
    end
    ---@type CastleMainView
    local viewComponent = self:GetViewComponent()
    viewComponent:SetMemoriesLockVisible(isRed)
end
--==============================--
---@Description: 更新进度
---@author : xingweihao
---@date : 2019/3/4 7:36 PM
--==============================--
function CastleMainMediator:UpdatePrograss()
    ---@type CastleMainView
    local viewComponent = self:GetViewComponent()
    --TODO  获取进度
    viewComponent:UpdatePrograss()
end
---==============================--
---@Description: 进入主界面的回调事件
---@author : xingweihao
---@date : 2019/3/1 5:59 PM
--==============================--
function CastleMainMediator:EnterBattleMapClick(sender)
    if self:isClosed() then
        app.uiMgr:ShowInformationTips(__('当前活动已结束'))
    else
        local viewData = self:GetViewComponent().viewData
        viewData.backBtn:setEnabled(false)
        sender:setEnabled(false)
        local calfunc = function()
            ---@type CastleMainView
            local viewComponent = self:GetViewComponent()
            local viewData = viewComponent.viewData
            viewData.mainDoor:setToSetupPose()
            viewData.mainDoor:setAnimation(0, 'play', false )
            local getTargetAction = function(node)
                 local targetedAction =  cc.TargetedAction:create(
                         node ,cc.Sequence:create(
                             cc.EaseSineOut:create(cc.MoveBy:create(0.55 , cc.p(0, -250 )))
                             ,
                             cc.DelayTime:create(0.35)
                         )
                 )
                return targetedAction
            end
            local bgView =display.newButton(display.cx , display.cy  , { n =app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_bg.png') })
            bgView:setEnabled(false)
            --display.newImageView(app.activityMgr:CastleResEx('ui/castle/battleMaps/castle_map_bg.png'),display.cx , display.cy  ,{ap = display.CENTER})
            bgView:setVisible(false)
            sceneWorld:addChild(bgView , 1000)
            viewData.mainDoor:runAction(
                cc.Sequence:create(
                    cc.Spawn:create(
                            cc.DelayTime:create(0.9),
                            getTargetAction(viewData.rightBottomLayout),
                            getTargetAction(viewData.leftBottomLayout),
                            getTargetAction(viewData.prograssLayout),
                            getTargetAction(viewData.enterBtn)
                    ),
                    cc.CallFunc:create(function()
    
                        --bgView:setOpacity(0)
                        viewData.mainDoor:setToSetupPose()
                        viewData.mainDoor:stopAllActions()
                        bgView:runAction(
                            cc.Sequence:create(
                                cc.Show:create(),
                                cc.CallFunc:create(
                                    function()
                                        local router =  app:RetrieveMediator("Router")
                                        router:Dispatch({name  = "castle.CastleMainMediator"} , {name ="castle.CastleBattleMapMediator", params = {
                                            homeData = self.homeData
                                        } })
                                    end
                               ),
                                cc.Spawn:create(
                                        cc.FadeOut:create(0.6),
                                        cc.ScaleTo:create(0.6,1.2)
                                ),
                                cc.RemoveSelf:create()
                            )
                        )
                    end)
                )
            )
            --viewData.mainDoor:registerSpineEventHandler(handler(self, self.EnterSpineCallBack), sp.EventType.ANIMATION_COMPLETE)
        end
        self:PlayStoryPlot(2 , calfunc)
    end
end
---==============================--
---@Description: 进入主界面的回调事件
---@author : xingweihao
---@date : 2019/3/1 5:59 PM
--==============================--
function CastleMainMediator:EnterSpineCallBack()
end
---==============================--
---@Description: 领取钥匙回调事件
---@author : xingweihao
---@date : 2019/3/1 5:59 PM
--==============================--

function CastleMainMediator:RewardsKeysClick()
    if self:isClosed() then
        app.uiMgr:ShowInformationTips(__('当前活动已结束'))
    else
        local mediator = require('Game.mediator.castle.CastleRewardKeysMediator').new({ homeData = self:GetHomeData()})
        app:RegistMediator(mediator)
    end
end
---==============================--
---@Description: 领取排行回调事件
---@author : xingweihao
---@date : 2019/3/1 5:59 PM
--==============================--

function CastleMainMediator:RewardsRankClick()
    local mediator = require('Game.mediator.castle.CastleRankRewardMediator').new()
    app:RegistMediator(mediator)
end

---==============================--
---@Description:记忆之宿回调事件
---@author : xingweihao
---@date : 2019/3/1 5:59 PM
--==============================--

function CastleMainMediator:MermoryNightClick()
    local mediator = require('Game.mediator.castle.CastleCapsuleMediator').new({ homeData = self:GetHomeData()})
    app:RegistMediator(mediator)
end

---==============================--
---@Description:记忆枷锁回调事件
---@author : xingweihao
---@date : 2019/3/1 5:59 PM
--==============================--

function CastleMainMediator:MermoryChainClick()
    local mediator = require('Game.mediator.castle.CastlePlotRewardMediator').new({ homeData = self:GetHomeData()})
    app:RegistMediator(mediator)
end
---==============================--
---@Description:获取古堡活动的活动说明
---@author : xingweihao
---@date : 2019/3/1 5:59 PM
--==============================--
function CastleMainMediator:TipModuleExplain()
    app.uiMgr:ShowIntroPopup({moduleId = -28})
end
---==============================--
---@Description:回到主界面
---@author : xingweihao
---@date : 2019/3/1 5:59 PM
--==============================--

function CastleMainMediator:BackHomeMediator()
    local viewData = self:GetViewComponent().viewData
    viewData.backBtn:setEnabled(false)
    app:BackHomeMediator()
end
---==============================--
---@Description: 进入界面请求
---@author : xingweihao
---@date : 2019/3/5 2:34 PM
--==============================--

function CastleMainMediator:EnterLayer()
    self:SendSignal(POST.SPRING_ACTIVITY_HOME.cmdName , {})
end
function CastleMainMediator:cleanupView()

end


function CastleMainMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")

    -- play bg music
    PlayBGMusic(AUDIOS.WYS.FOOD_WYS_GUILINGGAO_SAD.id)

    regPost(POST.SPRING_ACTIVITY_HOME)
    regPost(POST.SPRING_ACTIVITY_UNLOCK_STORY)
    
    self:EnterLayer()
end
function CastleMainMediator:OnUnRegist()
    unregPost(POST.SPRING_ACTIVITY_HOME)
    local mediator = app:RetrieveMediator("CastleBattleMapMediator")
    if mediator then

    else
        unregPost(POST.SPRING_ACTIVITY_UNLOCK_STORY)
    end
    PlayBGMusic()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
end
return CastleMainMediator
