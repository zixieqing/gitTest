--[[
 * author : liuzhipeng
 * descpt : 活动 20春活 主界面Mediator
]]
---@class SpringActivity20HomeMediator : Mediator
local SpringActivity20HomeMediator = class('SpringActivity20HomeMediator', mvc.Mediator)
local NAME = "springActivity20.SpringActivity20HomeMediator"
function SpringActivity20HomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.showAnimation = checktable(params.requestData).animation and true or false -- 是否显示入场动画
end
local TOP_BTN_TAG = {
    RANK    = 1, 
    REWARD  = 2,
    STROY   = 3,
}
-------------------------------------------------
------------------ inheritance ------------------
function SpringActivity20HomeMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.springActivity20.SpringActivity20HomeScene', {animation = self.showAnimation})
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.lotteryBtn:setOnClickScriptHandler(handler(self, self.LotteryButtonCallback))
    viewData.bossBtn:setOnClickScriptHandler(handler(self, self.BossButtonCallback))
    viewData.stageBtn:setOnClickScriptHandler(handler(self, self.StageButtonCallback))
    viewData.buffBtn:setOnClickScriptHandler(handler(self, self.BuffButtonCallback))
    for i, v in ipairs(viewData.topBtnComponentList) do
        v.btn:setOnClickScriptHandler(handler(self, self.TopButtonCallback))
    end
    if self.payload then
        app.springActivity20Mgr:SetHomeData(self.payload)
        self:InitView()
    end
end

function SpringActivity20HomeMediator:InterestSignals()
    local signals = {
	}
	return signals
end
function SpringActivity20HomeMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.SPRING_ACTIVITY_20_UNLOCK_STORY.sglName then -- 剧情解锁
        local storyId = body.requestData.storyId
        app.SpringActivity20Mgr:UpdateUnlockStoryMap(storyId)
    end
end

function SpringActivity20HomeMediator:OnRegist()
    -- 播放音乐
    regPost(POST.SPRING_ACTIVITY_20_UNLOCK_STORY)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end
function SpringActivity20HomeMediator:OnUnRegist()
    unregPost(POST.SPRING_ACTIVITY_20_UNLOCK_STORY)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
提示按钮点击回调
--]]
function SpringActivity20HomeMediator:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-57'})
end
--[[
返回主界面
--]]
function SpringActivity20HomeMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    self:GetFacade():BackHomeMediator()
end
--[[
抽奖按钮点击回调
--]]
function SpringActivity20HomeMediator:LotteryButtonCallback( sender )
    PlayAudioByClickNormal()
    local mediator = require('Game.mediator.springActivity20.SpringActivity20LotteryMediator').new()
    app:RegistMediator(mediator)
end
--[[
Boss按钮点击回调
--]]
function SpringActivity20HomeMediator:BossButtonCallback( sender )
    PlayAudioByClickNormal()
    if self:CheckBossModuleIsUnlock() then
        app:RetrieveMediator("Router"):Dispatch({name = 'SpringActivity20HomeMediator'}, {name = 'springActivity20.SpringActivity20BossMediator'})
    else
        app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('请先通关普通难度的剧情关卡')))
    end
end
--[[
关卡按钮点击回调
--]]
function SpringActivity20HomeMediator:StageButtonCallback( sender )
    PlayAudioByClickNormal()
    app:RetrieveMediator("Router"):Dispatch({name = 'SpringActivity20HomeMediator'}, {name = 'springActivity20.SpringActivity20StageMediator'})

end
--[[
buff按钮点击回调
--]]
function SpringActivity20HomeMediator:BuffButtonCallback( sender )
    PlayAudioByClickNormal()
    app.springActivity20Mgr:ShowBuffInformationBoard(sender)
end
--[[
顶部按钮点击回调
--]]
function SpringActivity20HomeMediator:TopButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == TOP_BTN_TAG.RANK then
        self:RankButtonCallback(sender)
    elseif tag == TOP_BTN_TAG.REWARD then
        self:RewardButtonCallback(sender)
    elseif tag == TOP_BTN_TAG.STROY then
        self:StoryButtonCallback(sender)
    end
end
--[[
排行榜按钮点击回调
--]]
function SpringActivity20HomeMediator:RankButtonCallback( sender )
    PlayAudioByClickNormal()
    local mediator = require('Game.mediator.springActivity20.SpringActivity20RankMediator').new()
    app:RegistMediator(mediator)
end
--[[
奖励按钮点击回调
--]]
function SpringActivity20HomeMediator:RewardButtonCallback( sender )
    PlayAudioByClickNormal() 
    local mediator = require("Game.mediator.springActivity20.SpringActivity20PointRewardsMediator").new()
    app:RegistMediator(mediator)
end
--[[
故事按钮点击回调
--]]
function SpringActivity20HomeMediator:StoryButtonCallback( sender )
    PlayAudioByClickNormal()
    local mediator = require("Game.mediator.springActivity20.SpringActivity20StoryMediator").new()
    app:RegistMediator(mediator)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function SpringActivity20HomeMediator:InitView()
    local viewComponent = self:GetViewComponent()
    -- 更新顶部道具栏
    local hpGoodsId = app.springActivity20Mgr:GetHPGoodsId()
    local moneyIdMap = {hpGoodsId}
    viewComponent:InitMoneyBar(moneyIdMap)
    -- 刷新buff效果
    self:RefreshBuff()
    -- 刷新boss按钮状态
    self:RefreshBossSpineState()
    -- 判断开始剧情是否播放
    local paramConfig = CommonUtils.GetConfigAllMess('param', 'springActivity2020')
    app.springActivity20Mgr:CheckStoryIsUnlocked(paramConfig.story1)
end
--[[
刷新boss按钮spine状态
--]]
function SpringActivity20HomeMediator:RefreshBossSpineState()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshBossSpineState(self:CheckBossModuleIsUnlock())
end
--[[
检测boss模块是否锁定
--]]
function SpringActivity20HomeMediator:CheckBossModuleIsUnlock()
    local homeData = app.springActivity20Mgr:GetHomeData()
    local stageConfig = CommonUtils.GetConfigAllMess('questCommon', 'springActivity2020')
    local keysList = {}
    for i, v in pairs(stageConfig) do
        if v.questType == 1 then
            table.insert(keysList, v.questId)
        end
    end
    table.sort(keysList, function (a, b)
        return checkint(a) > checkint(b)
    end)
    local passedQuestMap = app.springActivity20Mgr:GetPassedQuestMap()
    local keyStageId = keysList[1]
    return passedQuestMap[tostring(keyStageId)] and true or false
end
--[[
刷新buff效果
--]]
function SpringActivity20HomeMediator:RefreshBuff()
    local viewComponent = self:GetViewComponent()
    local buff = app.springActivity20Mgr:GetGlobalBuff()
    viewComponent:RefreshBuff(buff)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function SpringActivity20HomeMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function SpringActivity20HomeMediator:GetHomeData()
    return self.homeData
end
------------------- get / set -------------------
-------------------------------------------------
return SpringActivity20HomeMediator
