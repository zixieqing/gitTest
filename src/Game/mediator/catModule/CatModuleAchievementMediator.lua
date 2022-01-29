--[[
 * author : panmeng
 * descpt : 猫咪成就
]]

local CatModuleAchievementView     = require('Game.views.catModule.CatModuleAchievementView')
local CatModuleAchievementMediator = class('CatModuleAchievementMediator', mvc.Mediator)

function CatModuleAchievementMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleAchievementMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function CatModuleAchievementMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true
    self.hasDraw_        = self.ctorArgs_.hasDraw or false

    -- create view
    self.viewNode_ = CatModuleAchievementView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().receiveBtn, handler(self, self.onClickDrawnBtnHandler_))
    ui.bindClick(self:getViewData().refreshBtn, handler(self, self.onClickRefreshBtnHandler_))

    self:getViewData().taskTableView:setCellUpdateHandler(handler(self, self.onRefreshTaskCellHandler_))
    self:getViewData().goodTabView:setCellUpdateHandler(function(cellIndex, cellNode)
        cellNode:alignTo(nil, ui.cc)

        local achieveConf = CONF.CAT_HOUSE.CAT_ACHV:GetValue(self:getAchieveId())
        local goodData    = achieveConf.rewards[cellIndex]
        cellNode:RefreshSelf(goodData)
    end)

    
    self:setCatUuId(self.ctorArgs_.catUuid)
    self:setAchieveData(self.ctorArgs_.achieveId, self.ctorArgs_.hasDraw)
end


function CatModuleAchievementMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatModuleAchievementMediator:OnRegist()
    regPost(POST.HOUSE_CAT_RESET_ACHIEVE)
    regPost(POST.HOUSE_CAT_DRAW_ACHIEVE)
end


function CatModuleAchievementMediator:OnUnRegist()
    unregPost(POST.HOUSE_CAT_RESET_ACHIEVE)
    unregPost(POST.HOUSE_CAT_DRAW_ACHIEVE)
end


function CatModuleAchievementMediator:InterestSignals()
    return {
        POST.HOUSE_CAT_RESET_ACHIEVE.sglName,
        POST.HOUSE_CAT_DRAW_ACHIEVE.sglName,
    }
end
function CatModuleAchievementMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -- 重置成就
    if name == POST.HOUSE_CAT_RESET_ACHIEVE.sglName then
        -- update goods
        app.goodsMgr:DrawRewards(GoodsUtils.GetMultipCostList(CatHouseUtils.CAT_PARAM_FUNCS.ACHV_RESET_CONSUME()))

        -- update data
        self:getCatModel():setAchievementId(data.achievementId)

        -- update view
        self:setAchieveData(data.achievementId, false)
        app.uiMgr:ShowInformationTips(__("重置成功"))

    -- 领取成就奖励
    elseif name == POST.HOUSE_CAT_DRAW_ACHIEVE.sglName then
        -- draw reward
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards})

        -- update data
        self:getCatModel():setAchievementDrawn(true)

        -- update view
        self:getViewNode():updateRewardState(true)


    end
end


-------------------------------------------------
-- get / set

function CatModuleAchievementMediator:getViewNode()
    return  self.viewNode_
end
function CatModuleAchievementMediator:getViewData()
    return self:getViewNode():getViewData()
end

function CatModuleAchievementMediator:setAchieveData(achieveId, hasDraw)
    self.achieveId_   = achieveId or 1
    self.hasDraw_     = checkbool(hasDraw)
    self.achieveConf_ = CONF.CAT_HOUSE.CAT_ACHV:GetValue(self:getAchieveId())
    if next(self.achieveConf_) == nil then
        return
    end
    self.taskType_    = checkint(self.achieveConf_.taskType)
    self:getViewNode():updatePageView(self.achieveConf_, self:isHasDrawn(), self:getCatModel())
    self:getViewData().taskTableView:resetCellCount(#self.achieveConf_.targets)
    self:getViewData().goodTabView:resetCellCount(#self.achieveConf_.rewards)
end
function CatModuleAchievementMediator:getAchieveId()
    return checkint(self.achieveId_)
end
function CatModuleAchievementMediator:isHasDrawn()
    return checkbool(self.hasDraw_)
end
function CatModuleAchievementMediator:getTaskType()
    return checkint(self.taskType_)
end



function CatModuleAchievementMediator:getAchieveConf()
    return checktable(self.achieveConf_)
end
function CatModuleAchievementMediator:setTaskData(taskType, taskCondition)
    self.taskConfs = string.split(taskCondition, ";")
    
end


function CatModuleAchievementMediator:setCatUuId(catUuid)
    self.catUuid_  = catUuid
    self.catModel_ = app.catHouseMgr:getCatModel(self:getCatUuid())
end
function CatModuleAchievementMediator:getCatUuid()
    return self.catUuid_
end
---@return HouseCatModel
function CatModuleAchievementMediator:getCatModel()
    return self.catModel_
end
function CatModuleAchievementMediator:getPlayerCatId()
    return self:getCatModel():getPlayerCatId()
end

-------------------------------------------------
-- public

function CatModuleAchievementMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

-------------------------------------------------
-- handler

function CatModuleAchievementMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CatModuleAchievementMediator:onClickDrawnBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:SendSignal(POST.HOUSE_CAT_DRAW_ACHIEVE.cmdName, {playerCatId = self:getPlayerCatId()})
end


function CatModuleAchievementMediator:onClickRefreshBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local refreshConsumes = CatHouseUtils.CAT_PARAM_FUNCS.ACHV_RESET_CONSUME()
    local callback = function()
        if GoodsUtils.CheckMultipCosts(refreshConsumes, true) then
            self:SendSignal(POST.HOUSE_CAT_RESET_ACHIEVE.cmdName, {playerCatId = self:getPlayerCatId()})
        end
    end
    
    app.uiMgr:AddCommonTipDialog({
        text     = string.fmt(__("是否花费_goodsInfo_重置成就？"), {_goodsInfo_ = GoodsUtils.GetMultipleConsumeStr(refreshConsumes)}),
        descr    = __("消耗道具重置成就"),
        callback = callback,
    })
end


function CatModuleAchievementMediator:onRefreshTaskCellHandler_(cellIndex, cellViewData)
    self:getViewNode():updateCellView(cellIndex, cellViewData, self:getAchieveConf(), self:getCatModel())
end


return CatModuleAchievementMediator
