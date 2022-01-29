--[[
剧情任务图鉴会看Mediator
--]]
local Mediator = mvc.Mediator
---@class PlotCollectManualMediator :Mediator
local PlotCollectManualMediator = class("PlotCollectManualMediator", Mediator)

local NAME = "plotCollect.PlotCollectManualMediator"

---@type UIManager
local uiMgr   = app.uiMgr
---@type GameManager
local gameMgr = app.gameMgr

local AREA_ID_DEFINE = {
    PROLOGUE           = -1, -- 序章
    STORY_RECALL       = -2, -- 主线追忆
    ACTIVITY_MAP_STORY = -3, -- 活动剧情
}

local COLLECT_COORDINATE = CommonUtils.GetConfigAllMess('collectCoordinate', 'plot') or {}

function PlotCollectManualMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    
    local args = params or {}
    self.datas = args.manualDatas
    self.background = args.background
    -- logInfo.add(5, tableToString(params))
end

function PlotCollectManualMediator:InterestSignals()
	return {
        
    }
end
function PlotCollectManualMediator:ProcessSignal(signal )
	local name = signal:GetName() 
end

function PlotCollectManualMediator:Initial( key )
    self.super.Initial(self,key)
    
	local scene = uiMgr:GetCurrentScene()
    local viewComponent = require('Game.views.plotCollect.PlotCollectManualView').new({background = self.background})
    self.viewData_ = viewComponent:GetViewData()
    self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
    scene:AddDialog(viewComponent)
    
    self:InitData()
    self:InitView()
end

function PlotCollectManualMediator:InitData()
    
    
end

function PlotCollectManualMediator:InitView()
    local viewData = self:GetViewData()
    display.commonUIParams(viewData.titleBtn,  {cb = handler(self, self.OnClickTitleBtnAction)})

    display.commonUIParams(viewData.backBtn,  {cb = handler(self, self.OnClickBackBtnAction), animate = false})
    
    display.commonUIParams(viewData.recallBtn,  {cb = handler(self, self.OnClickRecallBtnAction), animate = false})

    viewData.plotList:setDataSourceAdapterScriptHandler(handler(self, self.OnPlotListDataAdapter))
    self:GetViewComponent():UpdatePlotList(self.datas)

    if next(self.datas) then
        self:UpdateRightUI(1)
    end
end

function PlotCollectManualMediator:OnRegist()
end
function PlotCollectManualMediator:OnUnRegist()
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end

function PlotCollectManualMediator:UpdateRightUI(index)
    local data     = self.datas[index] or {}
    local cgIds    = data.cgId or {}
    local viewType = next(cgIds) and 1 or 0
    self:GetViewComponent():RefreshRightUI(viewType, data)
end

function PlotCollectManualMediator:OnPlotListDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local plotList = self:GetViewData().plotList
        pCell = self:GetViewComponent():CreateCell(plotList:getSizeOfCell())

        display.commonUIParams(pCell.viewData.bg, {cb = handler(self, self.OnClickPlotAction), animate = false})
    end

    xTry(function()
        local viewData = pCell.viewData
        self:GetViewComponent():UpdateCell(viewData, self.datas[index])

        viewData.bg:setTag(index)
        
    end,__G__TRACKBACK__)

    return pCell
end

function PlotCollectManualMediator:OnClickTitleBtnAction()
    -- todo 规则说明
    PlayAudioByClickNormal()
end

function PlotCollectManualMediator:OnClickPlotAction(sender)
    PlayAudioByClickNormal()
    local index    = sender:getTag()
    self:UpdateRightUI(index)
end

function PlotCollectManualMediator:OnClickRecallBtnAction(sender)
    PlayAudioByClickNormal()
    
    local areaId = checkint(sender:getUserTag())
    local path
    if AREA_ID_DEFINE.PROLOGUE == areaId then
        path = string.format("conf/%s/plot/story%d.json", i18n.getLang(), 0)    
    elseif areaId > 0 then
        path = string.format("conf/%s/plot/story%d.json", i18n.getLang(), areaId)    
    elseif areaId == AREA_ID_DEFINE.STORY_RECALL then  

    elseif areaId == AREA_ID_DEFINE.ACTIVITY_MAP_STORY then

    end

    local areaId = checkint(sender:getUserTag()) < 0 and 0 or checkint(sender:getUserTag())
    local stage = require( "Frame.Opera.OperaStage" ).new({id = sender:getTag(), isReview = true, path = path, guide = false, isHideBackBtn = true, cb = function ()
        -- body
    end})
    stage:setPosition(cc.p(display.cx,display.cy))
    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
end

function PlotCollectManualMediator:OnClickTitleBtnAction(sender)
    PlayAudioByClickNormal()
    local id = sender:getTag()
    uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[JUMP_MODULE_DATA.PLOT_COLLECT]})
end

function PlotCollectManualMediator:OnClickBackBtnAction()
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end

function PlotCollectManualMediator:OnClickPlotNodeAction(sender)
    PlayAudioByClickNormal()
    local id = sender:getTag()
    
end

function PlotCollectManualMediator:GetViewData()
    return self.viewData_
end

return PlotCollectManualMediator
