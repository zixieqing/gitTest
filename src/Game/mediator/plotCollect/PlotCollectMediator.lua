--[[
剧情任务图鉴会看Mediator
--]]
local Mediator = mvc.Mediator
---@class PlotCollectMediator :Mediator
local PlotCollectMediator = class("PlotCollectMediator", Mediator)

local NAME = "plotCollect.PlotCollectMediator"

---@type UIManager
local uiMgr   = app.uiMgr
---@type GameManager
local gameMgr = app.gameMgr

local AREA_ID_DEFINE = {
    PROLOGUE           = -1, -- 序章
    STORY_RECALL       = -2, -- 主线追忆
    ACTIVITY_STORY     = -3, -- 活动剧情
    WATER_BAR          = -4, -- 水吧趣闻
}

local STORY_REWARD       = CommonUtils.GetConfigAllMess('storyReward', 'plot') or {}
local COLLECT_COORDINATE = CommonUtils.GetConfigAllMess('collectCoordinate', 'plot') or {}

function PlotCollectMediator:ctor( viewComponent )
    self.super:ctor(NAME, viewComponent)
    
    self.zoneDatas = {}
    
end

function PlotCollectMediator:InterestSignals()
	return {
        
    }
end
function PlotCollectMediator:ProcessSignal(signal )
	local name = signal:GetName() 
end

function PlotCollectMediator:Initial( key )
    self.super.Initial(self,key)
    
	local scene = uiMgr:GetCurrentScene()
    local viewComponent = require('Game.views.plotCollect.PlotCollectView').new()
    self.viewData_ = viewComponent:GetViewData()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)
    
    self:InitData()
    self:InitView()
end

function PlotCollectMediator:InitData()
    self.currentAreaId = app.gameMgr:GetUserInfo().newestAreaId
    local questStory = gameMgr:GetUserInfo().questStory
    for key, value in pairs(STORY_REWARD) do
        local tempAreaId =  checkint(value.areaId)
        if tempAreaId == AREA_ID_DEFINE.PROLOGUE or questStory[tostring(value.id)] then
            self.zoneDatas[tempAreaId] = self.zoneDatas[tempAreaId] or {}
            table.insert(self.zoneDatas[tempAreaId], value)
        end
    end
    
    for index, datas in pairs(self.zoneDatas) do
        table.sort(datas, function (a, b)
            return checkint(a.id) < checkint(b.id)
        end)
    end
end

function PlotCollectMediator:InitView()
    local viewData = self:GetViewData()
    display.commonUIParams(viewData.backBtn,  {cb = handler(self, self.OnClickBackBtnAction), animated = false})
    display.commonUIParams(viewData.titleBtn, {cb = handler(self, self.OnClickTitleBtnAction), animated = false})
    
    local plotNodes = viewData.plotNodes
    
    for index, plotNode in ipairs(plotNodes) do
        local coordinate = COLLECT_COORDINATE[tostring(plotNode:getTag())] or {}
        local areaId = checkint(coordinate.areaId)

        -- areaId > 0 表示为 世界地图的 areaId 则要判断解锁条件
        local nodeViewData = plotNode.viewData
        local name = nodeViewData.name
        if areaId > 0 and areaId > self.currentAreaId then
            name:setVisible(false)
        else
            if areaId == AREA_ID_DEFINE.WATER_BAR then
                name:setVisible(CommonUtils.UnLockModule(JUMP_MODULE_DATA.WATER_BAR))
            else
                name:setVisible(true)
            end
        end
        -- plotNode:setUserTag(areaId)
        display.commonUIParams(plotNode, {cb = handler(self, self.OnClickPlotNodeAction)})
    end
end

function PlotCollectMediator:OnRegist()
end
function PlotCollectMediator:OnUnRegist()
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end

function PlotCollectMediator:OnClickTitleBtnAction()
    PlayAudioByClickNormal()
    uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[JUMP_MODULE_DATA.PLOT_COLLECT]})
end

function PlotCollectMediator:OnClickBackBtnAction()
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end

function PlotCollectMediator:OnClickPlotNodeAction(sender)
    local id = sender:getTag()
    local coordinate = COLLECT_COORDINATE[tostring(id)] or {}
    local areaId = checkint(coordinate.areaId)
    local descr = coordinate.descr
    if areaId > self.currentAreaId and descr and descr ~=  "" then
        uiMgr:ShowInformationTips(descr)
        return
    else
        PlayAudioByClickNormal()
        if areaId > 0 or areaId == AREA_ID_DEFINE.PROLOGUE then
            local datas = self.zoneDatas[areaId] or {}
            local mediator = require("Game.mediator.plotCollect.PlotCollectManualMediator").new({manualDatas = datas, background = coordinate.background})
            self:GetFacade():RegistMediator(mediator)

        elseif areaId == AREA_ID_DEFINE.STORY_RECALL then 
            local mediator = require("Game.mediator.StoryMissionsCollectionMediator").new({subPopup = true})
            self:GetFacade():RegistMediator(mediator)
            
        elseif areaId == AREA_ID_DEFINE.ACTIVITY_STORY then
            local mediator = require("Game.mediator.plotCollect.PlotCollectActivityStoryMediator").new()
            self:GetFacade():RegistMediator(mediator)

        elseif areaId == AREA_ID_DEFINE.WATER_BAR then
            local mediator = require("Game.mediator.plotCollect.PlotCollectWaterBarStoryMediator").new()
            self:GetFacade():RegistMediator(mediator)
        end
    end
    
end

function PlotCollectMediator:GetViewData()
    return self.viewData_
end

return PlotCollectMediator
