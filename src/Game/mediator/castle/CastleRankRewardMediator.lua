--[[
奖励mediator
--]]
local Mediator = mvc.Mediator
---@class CastleRankRewardMediator :Mediator
local CastleRankRewardMediator = class("CastleRankRewardMediator", Mediator)
local NAME = "Game.mediator.castle.CastleRankRewardMediator"
CastleRankRewardMediator.NAME = NAME


function CastleRankRewardMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method
function CastleRankRewardMediator:Initial(key)
    self.super.Initial(self, key)

    self.datas = {}
    self.isControllable_ = true

    -- create view
    local viewComponent = require('Game.views.castle.CastleRankRewardView').new({mediatorName = NAME})
    self.viewData_      = viewComponent:GetViewData()
    self:SetViewComponent(viewComponent)
    self:InitOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:GetOwnerScene():AddDialog(viewComponent)

    -- init view
    self:InitView_()
    
end

function CastleRankRewardMediator:InitData_(serDatas)
    self.datas    = {}
    local myRank = serDatas.myRank or {}
    local rank = checkint(myRank.rank)
    local damageRankRewardsConf = CommonUtils.GetConfigAllMess('damageRankRewards', 'springActivity') or {}

    if next(damageRankRewardsConf) ~= nil then
        for i, damageRankReward in orderedPairs(damageRankRewardsConf) do
            local upperLimit = checkint(damageRankReward.upperLimit)
            local lowerLimit = checkint(damageRankReward.lowerLimit)
            
            table.insert(self.datas, {
                confData    = damageRankReward,
                isCurRank   = upperLimit <= rank and lowerLimit >= rank,
            })
        end
    end
end

function CastleRankRewardMediator:InitView_()
    local viewData = self:GetViewData()
    viewData.tableView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAdapter))
    -- viewData.tableView:setCountOfCell(10)
    -- viewData.tableView:reloadData()
 
    display.commonUIParams(viewData.rankBtn, {cb = handler(self, self.OnClickRankBtnAction)})
end

function CastleRankRewardMediator:InitOwnerScene_()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
end

function CastleRankRewardMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function CastleRankRewardMediator:OnRegist()
    regPost(POST.SPRING_ACTIVITY_RANK)
    self:EnterLayer()
end
function CastleRankRewardMediator:OnUnRegist()
    unregPost(POST.SPRING_ACTIVITY_RANK)
    self:cleanupView()
end


function CastleRankRewardMediator:InterestSignals()
    return {
        POST.SPRING_ACTIVITY_RANK.sglName
    }
end

function CastleRankRewardMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == POST.SPRING_ACTIVITY_RANK.sglName then
        self.serDatas = body
        self:InitData_(body)
        self:RefreshUI()
    end
end

-------------------------------------------------
-- get / set

function CastleRankRewardMediator:GetViewData()
    return self.viewData_
end

function CastleRankRewardMediator:GetOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function CastleRankRewardMediator:EnterLayer()
    self:SendSignal(POST.SPRING_ACTIVITY_RANK.cmdName)
end

function CastleRankRewardMediator:RefreshUI()
    local myRank = self.serDatas.myRank or {}

    local viewComponent = self:GetViewComponent()
   viewComponent:UpdateRankLabel(myRank.rank)
   viewComponent:UpdateDotLabel(myRank.score)

   viewComponent:UpdateTableView(self.datas)
end


-------------------------------------------------
-- private method
function CastleRankRewardMediator:OnDataSourceAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    
    local viewComponent = self:GetViewComponent()
    if pCell == nil then
        local tableView = self:GetViewData().tableView
        pCell = viewComponent:CreateCell(tableView:getSizeOfCell())
    end

    xTry(function()

        viewComponent:UpdateCell(pCell.viewData, self.datas[index] or {})

    end,__G__TRACKBACK__)
    return pCell
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function CastleRankRewardMediator:OnClickRankBtnAction(sender)
    local mediator = require('Game.mediator.castle.CastleRankMediator').new({datas = self.serDatas})
    app:RegistMediator(mediator)
end


return CastleRankRewardMediator
