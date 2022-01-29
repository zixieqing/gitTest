--[[
 * descpt : 夏活首页 中介者
]]
local NAME = 'summerActivity.SummerActivityHomeMediator'
local SummerActivityHomeMediator = class(NAME, mvc.Mediator)

local appIns   = AppFacade.GetInstance()
local uiMgr             = appIns:GetManager('UIManager')
local gameMgr           = appIns:GetManager("GameManager")
local timerMgr          = appIns:GetManager("TimerManager")
local summerActMgr      = appIns:GetManager("SummerActivityManager")

local BUTTON_TAG = {
    BACK                 = 100,   -- 返回
    RULE                 = 101,   -- 规则
    PLOT                 = 102,   -- 剧情
    REWARD_PREVIEW_ENTER = 103,   -- 排行榜奖励
    CARNIE_ENTER         = 104,   -- 游乐场
    RANK                 = 105,   -- 排行榜
}

local DIALOG_TAG = {
    RANK_REWARD = 1000,
}

function SummerActivityHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    -- logInfo.add(5, tableToString(self.ctorArgs_))
    app.summerActMgr:SetBackData(self.ctorArgs_.fromMediator, self.ctorArgs_.activityId)
end

-------------------------------------------------
-- inheritance method
function SummerActivityHomeMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    -- create view
    local viewComponent = require('Game.views.summerActivity.SummerActivityHomeView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self:initOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:getOwnerScene():AddDialog(viewComponent)

    -- init view
    self:initView_()
    
end

function SummerActivityHomeMediator:initOwnerScene_()
    self.ownerScene_ = uiMgr:GetCurrentScene()
end

function SummerActivityHomeMediator:initView_()
    local viewData = self:getViewData()

    local actionBtns = viewData.actionBtns
    for tag, btn in pairs(actionBtns) do
        display.commonUIParams(btn, {cb = handler(self, self.onBtnAction)})
        btn:setTag(checkint(tag))
    end

    local pointIcon = viewData.pointIcon
    display.commonUIParams(pointIcon, {animate = false, cb = function (sender)
        uiMgr:ShowInformationTipsBoard({targetNode = sender, type = 5, title = summerActMgr:getThemeTextByText(__('游乐园点数')),
        descr = summerActMgr:getThemeTextByText(__('在游乐园中战斗可获得的点数。击退小丑时，根据造成的伤害可以获得更多的点数哦。'))})
    end})

    self:GetViewComponent():showAction()
end

function SummerActivityHomeMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function SummerActivityHomeMediator:OnRegist()
    regPost(POST.SUMMER_ACTIVITY_HOME, true)
    regPost(POST.SUMMER_ACTIVITY_STORY_UNLOCK, true)
    
    PlayBGMusic()
    self:enterLayer()

    
end
function SummerActivityHomeMediator:OnUnRegist()
    unregPost(POST.SUMMER_ACTIVITY_HOME)
    unregPost(POST.SUMMER_ACTIVITY_STORY_UNLOCK)
end


function SummerActivityHomeMediator:InterestSignals()
    return {
        POST.SUMMER_ACTIVITY_HOME.sglName,
        POST.SUMMER_ACTIVITY_STORY_UNLOCK.sglName,

        -- SGL.REFRES_SUMMER_ACTIVITY_ICON
    }
end

function SummerActivityHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    local errcode = checkint(body.errcode)
    if errcode ~= 0 then return end

    if name == POST.SUMMER_ACTIVITY_HOME.sglName then
        -- logInfo.add(5, tableToString(body))
        self.datas = body
        app.summerActMgr:setIsClosed(checkint(self.datas.isEnd) == 1)
        local mainStory = {}
        for i, storyId in pairs(self.datas.mainStory) do
            mainStory[tostring(storyId)] = storyId
        end
        local branchStory = {}
        for chapterId, chapterDatas in pairs(self.datas.branchStory) do
            branchStory[tostring(chapterId)] = {}
            for k, storyId in pairs(chapterDatas) do
                branchStory[tostring(chapterId)][tostring(storyId)] = storyId
            end
        end
        self.datas.mainStory   = mainStory
        self.datas.branchStory = branchStory
        summerActMgr:SetMainStory(mainStory)
        summerActMgr:SetBranchStory(branchStory)
        
        self:GetViewComponent():refreshUI(body)

        if summerActMgr:CheckMainStoryIsUnlock(summerActMgr.STORY_FLAG.SA_ICON) == nil then
            self:SendSignal(POST.SUMMER_ACTIVITY_STORY_UNLOCK.cmdName, {storyId = summerActMgr.STORY_FLAG.SA_ICON, storyTag = 0})
        end
        
    elseif name == POST.SUMMER_ACTIVITY_STORY_UNLOCK.sglName then
        local requestData = body.requestData
        local storyId     = requestData.storyId
        local chapterId   = checkint(requestData.chapterId)
        local storyTag    = checkint(requestData.storyTag)

        if storyTag == 0 then
            summerActMgr:AddMainStoryId(storyId)
        else
            summerActMgr:AddBranchStoryId(chapterId, storyId)
        end

    elseif name == SGL.REFRES_SUMMER_ACTIVITY_ICON then
        summerActMgr:ShowBackToHomeUI()
    end
end

-------------------------------------------------
-- get / set

function SummerActivityHomeMediator:getViewData()
    return self.viewData_
end

function SummerActivityHomeMediator:getOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function SummerActivityHomeMediator:enterLayer()
    self:SendSignal(POST.SUMMER_ACTIVITY_HOME.cmdName)
end

-------------------------------------------------
-- private method

-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function SummerActivityHomeMediator:onBtnAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.BACK then
        PlayAudioByClickClose()
        self:GetFacade():UnRegsitMediator(NAME)
    else

        PlayAudioByClickNormal()

        -- 检查是否活动时间已过
        if summerActMgr:ShowBackToHomeUI() then return end

        if tag == BUTTON_TAG.RULE then
            uiMgr:ShowIntroPopup({moduleId = '-3'})
        elseif tag == BUTTON_TAG.PLOT then
            local mediator = require("Game.mediator.summerActivity.SummerActivityStoryMediator").new(self.datas)
            self:GetFacade():RegistMediator(mediator)
        elseif tag == BUTTON_TAG.REWARD_PREVIEW_ENTER then
            
            local mediator = require("Game.mediator.summerActivity.SummerActivityRankRewardMediator").new(self.datas)
            self:GetFacade():RegistMediator(mediator)

        elseif tag == BUTTON_TAG.CARNIE_ENTER then
            summerActMgr:ShowMainStory(summerActMgr.STORY_FLAG.SA_MAP_ICON, function ()
                self:GetFacade():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, 
                    {name = 'summerActivity.SummerActivityHomeMapMediator', params = {fromMediator = self.ctorArgs_.fromMediator, activityId = self.ctorArgs_.activityId, chapter = self.ctorArgs_.chapter}})
            end, function ()
                self:SendSignal(POST.SUMMER_ACTIVITY_STORY_UNLOCK.cmdName, {storyId = summerActMgr.STORY_FLAG.SA_MAP_ICON, storyTag = 0})
            end)
            
        elseif tag == BUTTON_TAG.RANK then
            AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'summerActivity.SummerActivityHomeMediator'}, {name = 'summerActivity.carnie.CarnieRankMediator'})
        end
    end
end

return SummerActivityHomeMediator
