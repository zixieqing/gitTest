--[[
 * descpt : 夏活 第一级 地图 中介者
]]
local NAME = 'summerActivity.SummerActivityFirstMapMediator'
local SummerActivityFirstMapMediator = class(NAME, mvc.Mediator)

local uiMgr    = app.uiMgr    or AppFacade.GetInstance():GetManager('UIManager')
local gameMgr  = app.gameMgr  or AppFacade.GetInstance():GetManager("GameManager")
local timerMgr = app.timerMgr or AppFacade.GetInstance():GetManager("TimerManager")
local summerActMgr = AppFacade.GetInstance():GetManager("SummerActivityManager")
-- local SA_CHAPTER = CommonUtils.GetConfigAllMess('chapter', 'summerActivity')

local BUTTON_TAG = {
    BACK   = 100,
    RULE   = 101,
}

local NODE_TYPES = {
    UNOPEN   = 0,   -- 未开启
    PLOT     = 1,   -- 剧情
    MONSTER  = 2,   -- 怪物
    BOSS     = 3,   -- BOSS
}

function SummerActivityFirstMapMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    
end

-------------------------------------------------
-- inheritance method
function SummerActivityFirstMapMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true

    -- create view
    local viewComponent = require('Game.views.summerActivity.SummerActivityFirstMapView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- -- add layer
    -- self:initOwnerScene_()
    -- display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    -- self:getOwnerScene():AddGameLayer(viewComponent)

    -- init view
    self:initView_()
    
end

function SummerActivityFirstMapMediator:initOwnerScene_()
    self.ownerScene_ = uiMgr:GetCurrentScene()
end

function SummerActivityFirstMapMediator:initView_()
    local viewData = self:getViewData()
    local actionBtns = viewData.actionBtns
    
    for tag, btn in pairs(actionBtns) do
        display.commonUIParams(btn, {cb = handler(self, self.onBtnAction)})
        btn:setTag(checkint(tag))
    end

    local facilitiesCells = viewData.facilitiesCells
    for chapterId, facilitiesCell in pairs(facilitiesCells) do
        display.commonUIParams(facilitiesCell.viewData.bgLayer, {cb = handler(self, self.onFacilitiesCellAction)})
        facilitiesCell.viewData.bgLayer:setTag(checkint(chapterId))
        facilitiesCell:setTag(checkint(chapterId))
    end

    local lotteryCell = viewData.lotteryCell
    display.commonUIParams(lotteryCell.viewData.bgLayer, {cb = handler(self, self.onLotteryCellAction)})

    self:CheckHideStoryIsOpen()
end

function SummerActivityFirstMapMediator:CleanupView()
    
end

function SummerActivityFirstMapMediator:OnRegist()
    
end
function SummerActivityFirstMapMediator:OnUnRegist()
    
end


function SummerActivityFirstMapMediator:InterestSignals()
    return {
        COUNT_DOWN_ACTION,
        "CHECK_HIDE_STORY_IS_OPEN",        -- 检查隐藏剧情是否开启

        POST.SUMMER_ACTIVITY_CHAPTER.sglName,
    }
end

function SummerActivityFirstMapMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    local errcode = checkint(body.errcode)
    if errcode ~= 0 then return end

    if name == POST.SUMMER_ACTIVITY_CHAPTER.sglName then

        local chapter = body.chapter
        local chapterDatas, maxRemainUnlockTime, nextChapterId = summerActMgr:InitChapterData(chapter)
        self.chapterDatas = chapterDatas
        self.maxRemainUnlockTime = maxRemainUnlockTime
        self.nextChapterId = nextChapterId

        summerActMgr:StartSummerActivityCountdown(maxRemainUnlockTime)

        local passChapterId = nil
        if self.isFirstPassBoss then
            passChapterId = self.passChapterId
        end
        
        self:GetViewComponent():refreshUI(self.chapterDatas, self.nextChapterId, passChapterId)

    elseif name == "CHECK_HIDE_STORY_IS_OPEN" then
        
        self:CheckHideStoryIsOpen()

    elseif name == COUNT_DOWN_ACTION then
        local timerName = body.timerName
        if timerName == 'COUNT_DOWN_TAG_SUMMER_ACTIVITY' and self.chapterDatas then
            local countdown = body.countdown
            if countdown < 0 then
                self:enterLayer()
            else
                
                local deltaTime = checkint(self.maxRemainUnlockTime) - countdown
                self.maxRemainUnlockTime = countdown
                for chapterId, chapterData in pairs(self.chapterDatas) do
                    if chapterData.remainUnlockTime > 0 then
                        chapterData.remainUnlockTime = chapterData.remainUnlockTime - deltaTime
                        
                        if chapterData.remainUnlockTime <= 0 then
                            summerActMgr:StopSummerActivityCountdown()
                            self:updateCountdownLabel_(chapterId, 0)
                            self:enterLayer()
                            break
                        elseif  tostring(chapterId) ~= summerActMgr.CHAPTER_FLAG.MAZE and 
                                checkint(self.nextChapterId) == checkint(chapterId)  then
                                
                            self:updateCountdownLabel_(chapterId, chapterData.remainUnlockTime)
                        end
                    end
                end
                
            end
        end
        
    end
end

-------------------------------------------------
-- get / set

function SummerActivityFirstMapMediator:getViewData()
    return self.viewData_
end

function SummerActivityFirstMapMediator:getOwnerScene()
    return self.ownerScene_
end

function SummerActivityFirstMapMediator:getAppRouter()
    return AppFacade.GetInstance():RetrieveMediator('Router')
end

-------------------------------------------------
-- public method
function SummerActivityFirstMapMediator:enterLayer()
    self:SendSignal(POST.SUMMER_ACTIVITY_CHAPTER.cmdName)
end

function SummerActivityFirstMapMediator:updateUI(chapterId, isFirstPassChapter, nodeType)
    self.passChapterId = chapterId
    self.isFirstPassBoss = isFirstPassChapter == true and nodeType == NODE_TYPES.BOSS
    self:enterLayer()

    local firstMapAudio = summerActMgr:getFirstMapAudioConf()
    PlayBGMusic(firstMapAudio.cueName)
end

function SummerActivityFirstMapMediator:updateCountdownLabel_(chapterId, remainUnlockTime)
    local viewData = self:getViewData()
    local facilitiesCells = viewData.facilitiesCells
    local cell = facilitiesCells[tostring(chapterId)]
    if cell then
        self:GetViewComponent():updateTimeLable(cell.viewData, remainUnlockTime)
        if remainUnlockTime <= 0 then
            self:GetViewComponent():CreateYlySpine(cell, true)
        end
    end
end

-------------------------------------------------
-- private method

-------------------------------------------------
-- check

function SummerActivityFirstMapMediator:CheckHideStoryIsOpen()
    local mainStoryCount = table.nums(summerActMgr:GetMainStory())
    local branchStoryCount = 0
    local branchStory = summerActMgr:GetBranchStory()
    for chapterId, branchStoryData in pairs(branchStory) do
        branchStoryCount = branchStoryCount + table.nums(branchStoryData)
    end

    if (mainStoryCount + branchStoryCount) >= (summerActMgr:GetTotalStoryCount() - 1) and summerActMgr:GetHideStoryId() > 0 then
        self:GetViewComponent():CreateHideStoryCell()
    end
end

-------------------------------------------------
-- handler
function SummerActivityFirstMapMediator:onBtnAction(sender)
    local tag = sender:getTag()
    
end

function SummerActivityFirstMapMediator:onFacilitiesCellAction(sender)
    if app.summerActMgr:isClosed() then
        app.uiMgr:ShowInformationTips(__("活动已结束"))
        return
    end
    -- 检查是否活动时间已过
    if summerActMgr:ShowBackToHomeUI() then return end

    local chapterId = checkint(sender:getTag())
    
    local isOpen, errTip = summerActMgr:CheckIsOpenChapter(self.chapterDatas, chapterId)
    if isOpen then
        local storyId = summerActMgr:GetClickChapterIconStoryByChapterId(tostring(chapterId))
        local callback = nil
        local bgMusicType = nil
        if chapterId == 5 then
            bgMusicType = 1
            callback = function ()
                self:SendSignal(POST.SUMMER_ACTIVITY_ADDITION.cmdName, {mediatorName = NAME, chapterId = chapterId})
            end
        else
            bgMusicType = 2
            callback = function ()
                self:GetFacade():DispatchObservers('SUMMER_ACTIVITY_SWITCH_MAP', {chapterId = chapterId})
            end
        end

        summerActMgr:ShowMainStory(storyId, callback, function ()
            self:SendSignal(POST.SUMMER_ACTIVITY_STORY_UNLOCK.cmdName, {storyId = storyId, storyTag = 0})
        end, bgMusicType)
       
    else

        if errTip then
            uiMgr:ShowInformationTips(errTip)
        end

    end
end

function SummerActivityFirstMapMediator:onLotteryCellAction(sender)
    -- 检查是否活动时间已过
    if summerActMgr:ShowBackToHomeUI() then return end

    self:getAppRouter():Dispatch({name = 'summerActivity.SummerActivityFirstMapMediator'}, {name = 'summerActivity.carnie.CarnieCapsuleMediator'})
end

return SummerActivityFirstMapMediator
