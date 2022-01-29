--[[
仙境梦游-探索主界面 mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19ExploreTaskMediator :Mediator
local Anniversary19ExploreTaskMediator = class("Anniversary19ExploreTaskMediator", Mediator)
local NAME = "anniversary19.Anniversary19ExploreTaskMediator"
Anniversary19ExploreTaskMediator.NAME = NAME

local app = app

function Anniversary19ExploreTaskMediator:ctor(params)
    self.super.ctor(self, NAME)
    self.ctorArgs_ = checktable(params)

end

-------------------------------------------------
-- inheritance method
function Anniversary19ExploreTaskMediator:Initial(key)
    self.super.Initial(self, key)

    self.datas = {}
    self.isControllable_ = true

    -- create view
    local viewComponent = require('Game.views.anniversary19.Anniversary19ExploreTaskView').new({mediatorName = NAME})
    self.viewData_      = viewComponent:GetViewData()
    self:SetViewComponent(viewComponent)
    self:InitOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:GetOwnerScene():AddGameLayer(viewComponent)

    -- init data
    self:InitData_()

    -- init view
    self:InitView_()
    
end

function Anniversary19ExploreTaskMediator:InitData_()
    local mgr                = app.anniversary2019Mgr
    local homeData           = mgr:GetHomeData()
    local explore            = homeData.explore or {}
    
    -- 委托状态
    local consignationStates = {}
    local exploreModuleIds = {}
    local drawBtnState = 1

    local isCompleteAll = true
    for exploreModuleId, value in pairs(explore) do
        local maxLevel = self:GetConsignationMaxLevel(exploreModuleId)
        local consignationLevel = checkint(value.consignationLevel)
        local isCompleteConsignation = consignationLevel >= maxLevel
        
        consignationStates[tostring(exploreModuleId)] = {
            exploreModuleId = exploreModuleId, 
            maxLevel = maxLevel, 
            currentLevel = consignationLevel, 
            isCompleteConsignation = isCompleteConsignation
        }

        isCompleteAll = isCompleteAll and isCompleteConsignation

        table.insert(exploreModuleIds, exploreModuleId)
    end

    if checkint(homeData.hasConsignationFinalRewardDrawn) > 0 then
        drawBtnState = 3
    elseif isCompleteAll then
        drawBtnState = 2
    end

    self.exploreModuleIds = exploreModuleIds
    self.consignationStates = consignationStates
    self.drawBtnState = drawBtnState
    
    local consignationConf   = CommonUtils.GetConfigAllMess('consignation', 'anniversary2') or {}
    local moneyIdMap = {} 
    for key, exploreConsignationConf in pairs(consignationConf) do
        for key, value in pairs(exploreConsignationConf) do
            local consume = value.consume or {}
            for index, consumeData in ipairs(consume) do
                local goodsId = consumeData.goodsId
                moneyIdMap[tostring(goodsId)] = checkint(goodsId)
            end
        end
    end
    local moneyIdList = table.values(moneyIdMap)
    table.sort(moneyIdList)
    -- 应小瑜的要求调整位置
    table.insert(moneyIdList, 2, moneyIdList[3])
    table.remove(moneyIdList)
    app:DispatchObservers('UPDATA_MONEY_BAR', {moneyData = {moneyIdList = moneyIdList, isEnableGain = false, hideDefault = true}})
end 

function Anniversary19ExploreTaskMediator:InitView_()
    local viewData = self:GetViewData()

    local parameterConf = CommonUtils.GetConfigAllMess('parameter', 'anniversary2') or {}
    local consignationRewards = parameterConf.consignationRewards or {}

    -- 获取卡牌预览id
    local confId
    for index, reward in ipairs(consignationRewards) do
        local goodsId = reward.goodsId
        local rewardType = CommonUtils.GetGoodTypeById(goodsId)
        if rewardType == GoodsType.TYPE_CARD then
            confId = goodsId
            break
        end
    end
    local viewComponent = self:GetViewComponent()
    if confId then
        viewComponent:UpdateCardPreviewBtn(viewData, confId)
    end

    viewComponent:UpdateRewardLayer(viewData, consignationRewards)

    viewData.drawBtn:SetCallback(handler(self, self.OnClickDrawBtnAction))
    viewData.tableView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAdapter))

    viewComponent:UpdateTableView(viewData, self.exploreModuleIds)
    viewComponent:UpdateDrawBtn(viewData, self.drawBtnState)

end

function Anniversary19ExploreTaskMediator:InitOwnerScene_()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
end

function Anniversary19ExploreTaskMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    self:SetViewComponent(nil)
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:setVisible(false)
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end


function Anniversary19ExploreTaskMediator:OnRegist()
    regPost(POST.ANNIVERSARY2_CONSIGNMENT)
    regPost(POST.ANNIVERSARY2_CONSIGNMENT_FINAL_REWARD_DRAW)
    -- self:EnterLayer()

    --self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
end
function Anniversary19ExploreTaskMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY2_CONSIGNMENT)
    unregPost(POST.ANNIVERSARY2_CONSIGNMENT_FINAL_REWARD_DRAW)
    app:DispatchObservers('UPDATA_MONEY_BAR')
    --self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
end

function Anniversary19ExploreTaskMediator:InterestSignals()
    return {
        POST.ANNIVERSARY2_CONSIGNMENT.sglName,
        POST.ANNIVERSARY2_CONSIGNMENT_FINAL_REWARD_DRAW.sglName,
        POST.ANNIVERSARY2_STORY_UNLOCK.sglName,
    }
end

function Anniversary19ExploreTaskMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if POST.ANNIVERSARY2_CONSIGNMENT.sglName == name then
        local requestData = body.requestData or {}
        local exploreModuleId = checkint(requestData.exploreModuleId)
        local oldLevel = self.consignationStates[tostring(exploreModuleId)].currentLevel
        local currentLevel = oldLevel + 1
        local maxLevel = self:GetConsignationMaxLevel(exploreModuleId)

        self.consignationStates[tostring(exploreModuleId)].currentLevel = currentLevel
        self.consignationStates[tostring(exploreModuleId)].isCompleteConsignation = currentLevel >= maxLevel
        
        -- 完成所有委托则改变状态 否则维持初始状态
        local isCompleteAll = true
        for key, value in pairs(self.consignationStates) do
            isCompleteAll = isCompleteAll and value.isCompleteConsignation
        end
        if isCompleteAll then
            self.drawBtnState = 2
        end

        -- 更新委托消耗道具
        local consignationConf = CommonUtils.GetConfig('anniversary2', 'consignation', exploreModuleId) or {}
        local conf = consignationConf[tostring(oldLevel + 1)] or {}
        local consume = conf.consume or {}
        local consumeDatas = {}
        for index, value in ipairs(consume) do
            table.insert(consumeDatas, {goodsId = value.goodsId, type = value.type, num = -checkint(value.num)})
        end
        CommonUtils.DrawRewards(consumeDatas)

        -- 更新home data委托等级
        local mgr                = app.anniversary2019Mgr
        local homeData           = mgr:GetHomeData()
        local explore            = homeData.explore or {}
        explore[tostring(exploreModuleId)].consignationLevel = currentLevel

        local viewComponent      = self:GetViewComponent()
        viewComponent:UpdateDrawBtn(self:GetViewData(), self.drawBtnState)

        for index, value in ipairs(self.exploreModuleIds) do
            if checkint(value) == exploreModuleId then
                local viewData = self:GetViewData()
                local cell = viewData.tableView:cellAtIndex(index - 1)
                if cell then
                    viewComponent:UpdateCell(cell.viewData, self.consignationStates[tostring(exploreModuleId)])
                end
                break
            end
        end


        
        -- 更新委托奖励
        local rewards = body.rewards or {}
        CommonUtils.DrawRewards(rewards)
        if next(conf) then
            app.anniversary2019Mgr:CheckStoryIsUnlocked(conf.storyId1, function ()
                app.uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
            end)
        end

    elseif POST.ANNIVERSARY2_CONSIGNMENT_FINAL_REWARD_DRAW.sglName == name then
        
        local rewards = body.rewards or {}
        CommonUtils.DrawRewards(rewards)

        -- 更新home data 委托最终奖励是否领取
        local mgr                = app.anniversary2019Mgr
        local homeData           = mgr:GetHomeData()
        homeData.hasConsignationFinalRewardDrawn = 1

        self.drawBtnState = 3
        self:GetViewComponent():UpdateDrawBtn(self:GetViewData(), self.drawBtnState)
        
        local parameterConf = CommonUtils.GetConfigAllMess('parameter', 'anniversary2') or {}
        app.anniversary2019Mgr:CheckStoryIsUnlocked(parameterConf.endStory, function ()
            app.uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, addBackpack = false})
        end)
    end
end

-------------------------------------------------
-- get / set

function Anniversary19ExploreTaskMediator:GetViewData()
    return self.viewData_
end

function Anniversary19ExploreTaskMediator:GetOwnerScene()
    return self.ownerScene_
end

---GetConsignationMaxLevel
---获得探索委托任务最大等级
---@param exploreModuleId number 探索模块id
function Anniversary19ExploreTaskMediator:GetConsignationMaxLevel(exploreModuleId)
    local conf = CommonUtils.GetConfig('anniversary2', 'consignation', exploreModuleId) or {}
    local maxLevel = 1
    for key, value in pairs(conf) do
        maxLevel = math.max(maxLevel, checkint(value.level))
    end
    return maxLevel
end

-------------------------------------------------
-- public method
function Anniversary19ExploreTaskMediator:EnterLayer()
end

-------------------------------------------------
-- private method

function Anniversary19ExploreTaskMediator:OnDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

	local viewComponent = self:GetViewComponent()

	if pCell == nil then
		local tableView = self:GetViewData().tableView
        pCell = viewComponent:CreateCell(tableView:getSizeOfCell())
        
        display.commonUIParams(pCell.viewData.submitBtn, {cb = handler(self, self.OnClickSubmitBtnAction)})
    end
    
    local exploreModuleId = self.exploreModuleIds[index]
    local data            = self.consignationStates[tostring(exploreModuleId)]
    viewComponent:UpdateCell(pCell.viewData, data)
    
    pCell.viewData.submitBtn:setTag(checkint(exploreModuleId))
	return pCell
end


-------------------------------------------------
-- check

-------------------------------------------------
-- handler

---OnClickDrawBtnAction
---领取按钮点击事件
---@param sender userdata 领取按钮
function Anniversary19ExploreTaskMediator:OnClickDrawBtnAction(sender)
    PlayAudioByClickNormal()

    local drawBtnState = self.drawBtnState
    if drawBtnState == 1 then
        app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('未完成全部委托')))
        return
    elseif drawBtnState == 3 then
        app.uiMgr:ShowInformationTips(app.anniversary2019Mgr:GetPoText(__('已领取奖励')))
        return
    end
    
    self:SendSignal(POST.ANNIVERSARY2_CONSIGNMENT_FINAL_REWARD_DRAW.cmdName)
end

---OnClickSubmitBtnAction
---交纳按钮点击事件
---@param sender userdata 交纳按钮
function Anniversary19ExploreTaskMediator:OnClickSubmitBtnAction(sender)
    PlayAudioByClickNormal()
    
    local exploreModuleId = sender:getTag()
    local data            = self.consignationStates[tostring(exploreModuleId)]

    local currentLevel = data.currentLevel
    local consignationConf = CommonUtils.GetConfig('anniversary2', 'consignation', exploreModuleId) or {}
    local conf = consignationConf[tostring(currentLevel + 1)] or {}

    local consume     = conf.consume or {}
    if next(consume) == nil then return end

    local isCanSubmit = true
    for index, consumeData in ipairs(consume) do
        local goodsId = consumeData.goodsId
        local num = consumeData.num
        local ownNum = CommonUtils.GetCacheProductNum(goodsId)
        isCanSubmit = isCanSubmit and ownNum >= num
        if not isCanSubmit then
            local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
            app.uiMgr:ShowInformationTips(string.format(app.anniversary2019Mgr:GetPoText(__('%s不足')), tostring(goodsConfig.name)))
            return
        end
    end

    self:SendSignal(POST.ANNIVERSARY2_CONSIGNMENT.cmdName, {exploreModuleId = exploreModuleId})

end

return Anniversary19ExploreTaskMediator
