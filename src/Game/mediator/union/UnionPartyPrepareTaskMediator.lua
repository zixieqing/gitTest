--[[
 * descpt : 工会party 提交菜品 中介者
]]
local NAME = 'UnionPartyPrepareTaskMediator'
local UnionPartyPrepareTaskMediator = class(NAME, mvc.Mediator)

local uiMgr    = AppFacade.GetInstance():GetManager('UIManager')
local gameMgr  = AppFacade.GetInstance():GetManager("GameManager")
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")

local SUBMIT_FOOD_TYPE = {
    NORMAL = 1,
    FAST   = 2,
}

local COMMON_BUY_VIEW_TAG = 5556

function UnionPartyPrepareTaskMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    
    self.datas = self.ctorArgs_.data or {}

    -- 保存 上次选择 tab 标识
    self.preChoiceTag = nil

    -- 总菜品数
    self.submitTotalFoodCount = 0
end

-------------------------------------------------
-- inheritance method
function UnionPartyPrepareTaskMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    -- create view
    local view = require('Game.views.union.UnionPartyPrepareTaskView').new()
    self.viewData_   = view:getViewData()
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self:SetViewComponent(view)

    local UnionPartyPrepareHomeMediator = self:GetFacade():RetrieveMediator('UnionPartyPrepareHomeMediator')
    self.ownerScene_ = UnionPartyPrepareHomeMediator:getOwnerScene()

    -- init data
    self:initData()
    -- init view
    self:initView()
end

function UnionPartyPrepareTaskMediator:initData(datas)
    if datas then
        self.datas = datas
    end
    self.submittedFoods = self.datas.submittedFoods or {}

    local getDataPriority = function (data)
        local targetNum = checkint(data.targetNum)
        local submittedNum = checkint(data.submittedNum)

        local priority = submittedNum >= targetNum and 1 or 0

        return priority
    end

    local sortfunction = function (a, b)
        if a == nil then return true end
        if b == nil then return false end

        local aPriority = getDataPriority(a)
        local bPriority = getDataPriority(b)
        
        if aPriority == bPriority then
            local aFoodId = checkint(a.foodId)
            local bFoodId = checkint(b.foodId)
            return aFoodId < bFoodId
        end

        return aPriority < bPriority
    end

    table.sort( self.submittedFoods, sortfunction )

    for i,food in ipairs(self.submittedFoods) do
        self.submitTotalFoodCount = self.submitTotalFoodCount + food.submittedNum
    end
end

function UnionPartyPrepareTaskMediator:initView()
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))

    -- local chestLayers = viewData.chestLayers
    -- for i,chestLayer in ipairs(chestLayers) do
    --     display.commonUIParams(chestLayer, {cb = })
    -- end

    self:GetViewComponent():refreshUI(self.submittedFoods, self.submitTotalFoodCount, self.datas.unionLevel)
end

function UnionPartyPrepareTaskMediator:CleanupView()
    
end

function UnionPartyPrepareTaskMediator:OnRegist()
    regPost(POST.UNION_PARTY_SUBMIT_FOOD)
    regPost(POST.UNION_PARTY_SUBMIT_FOOD_DIAMOND)
    regPost(POST.UNION_PARTY_SUBMIT_FOOD_ENTER)
    regPost(POST.UNION_PARTY_SUBMIT_FOOD_CLOSE)

    self:SendSignal(POST.UNION_PARTY_SUBMIT_FOOD_ENTER.cmdName)
end
function UnionPartyPrepareTaskMediator:OnUnRegist()
    unregPost(POST.UNION_PARTY_SUBMIT_FOOD)
    unregPost(POST.UNION_PARTY_SUBMIT_FOOD_DIAMOND)
    unregPost(POST.UNION_PARTY_SUBMIT_FOOD_ENTER)
    unregPost(POST.UNION_PARTY_SUBMIT_FOOD_CLOSE)

    self:SendSignal(POST.UNION_PARTY_SUBMIT_FOOD_CLOSE.cmdName)

    if self.commonBuyView then
        uiMgr:GetCurrentScene():RemoveDialogByTag(COMMON_BUY_VIEW_TAG)
    end
end

function UnionPartyPrepareTaskMediator:InterestSignals()
    return {
        POST.UNION_PARTY.sglName,
        POST.UNION_PARTY_SUBMIT_FOOD.sglName,
        POST.UNION_PARTY_SUBMIT_FOOD_DIAMOND.sglName,
        SGL.UNION_PARTY_PREPARE_FOOD_CHANGE,

        -- COMMON_BUY_VIEW_ENTER,    -- 进入提交菜品界面
        COMMON_BUY_VIEW_EXIT,     -- 退出提交菜品界面
        COMMON_BUY_VIEW_PAY,      -- 点击交菜按钮
        COMMON_BUY_VIEW_FAST_COMPLETE, -- 点击秒菜按钮

        'REFRESH_NOT_CLOSE_GOODS_EVENT', -- 道具变更
    }
end

function UnionPartyPrepareTaskMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()

    -- 注 所有的 派对筹备数据 请求在 UnionPartyPrepareHomeMediator 这里只做接收
    if POST.UNION_PARTY.sglName == name then
        local section = checkint(body.section)
        -- 只处理 交菜阶段
        if section ~= 2 then return end
        self.isControllable_ = false
        self:initData(body)
        self:GetViewComponent():refreshUI(self.submittedFoods, self.submitTotalFoodCount, self.datas.unionLevel)
        self.isControllable_ = true
    elseif SGL.UNION_PARTY_PREPARE_FOOD_CHANGE == name then
        local playerId = checkint(body.playerId)
        -- 不处理自己提交的菜
        -- dump(body,' dasefwaefaw')
        -- if playerId == checkint(gameMgr:GetUserInfo().playerId) then return end
        local foodId = checkint(body.foodId)
        local num    = checkint(body.num)

        local index  = self:updateSubmittedFoods(true, num, foodId)
        self:updateUi(foodId, index)
        
    elseif POST.UNION_PARTY_SUBMIT_FOOD.sglName == name then
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "52-01"})
        local requestData = body.requestData
        local foodId      = checkint(requestData.foodId)
        local num         = checkint(requestData.num)
        local unionPoint  = checkint(body.unionPoint)
        local contributionPoint = checkint(body.contributionPoint)
        local realSubmitFoodNum = checkint(body.realSubmitFoodNum)

        -- 1. 更新数据
        local index = self:updateSubmitRewardData(SUBMIT_FOOD_TYPE.NORMAL, body)

        -- 2. 更新UI
        -- 是否全部提交成功 (如果全部提交 则 正常更新ui  如果没有全部提交 则表示全部提交完了)
        self:updateUi(foodId, index)

        -- 3.提交成功后 提交界面 的选中数量 置为1
        if self.commonBuyView then
            self.commonBuyView:updatePurchaseNum(1)
            self.commonBuyView:updateAppointView()
        end
    elseif POST.UNION_PARTY_SUBMIT_FOOD_DIAMOND.sglName == name then
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "52-01"})
        local requestData = body.requestData
        local foodId      = requestData.foodId
        local unionPoint = body.unionPoint
        local contributionPoint = body.contributionPoint
        local realSubmitFoodNum = body.realSubmitFoodNum

        -- 1. 更新数据
        local index = self:updateSubmitRewardData(SUBMIT_FOOD_TYPE.FAST, body)
        -- 2. 更新UI
        -- 是否全部提交成功 (如果全部提交 则 正常更新ui  如果没有全部提交 则表示全部提交完了)
        self:updateUi(foodId, index)

        -- 3.提交成功后 提交界面 的选中数量 置为1
        if self.commonBuyView then
            self.commonBuyView:updatePurchaseNum(1)
            self.commonBuyView:updateAppointView()
        end
    elseif COMMON_BUY_VIEW_ENTER == name then
        -- 发送 进入工会派对提交菜品界面
        -- print('xxxxxxxxxxxx UNION_PARTYSUBMITFOODENTER')
        -- self:SendSignal(POST.UNION_PARTY_SUBMIT_FOOD_ENTER.cmdName)
    elseif COMMON_BUY_VIEW_EXIT == name then
        -- print('xxxxxxxxxxxx UNION_PARTYSUBMITFOODCLOSE')
        -- 发送 关闭工会派对提交菜品界面
        -- self:SendSignal(POST.UNION_PARTY_SUBMIT_FOOD_CLOSE.cmdName)
        -- 关闭界面 置空 交菜界面
        self.commonBuyView = nil
    elseif COMMON_BUY_VIEW_PAY == name then
        logInfo.add(4, 'COMMON_BUY_VIEW_PAY22')
        
        local selectNum = checkint(body.selectNum)
        local data      = body.data or {}
        local foodId    = data.foodId
        local grade     = data.grade
        local targetNum = checkint(data.targetNum)
        local submittedNum = checkint(data.submittedNum)
        local ownNum, isAppointLv, state = app.cookingMgr:GetFoodNumByGrade(foodId, grade)
        
        local maxCanSubmitNum = checkint(targetNum - submittedNum)
        if isAppointLv then
            if maxCanSubmitNum == 0 then
                uiMgr:ShowInformationTips(__('您上交的菜品大于需求数量')) 
            else
                if ownNum == 0 then
                    uiMgr:ShowInformationTips(__('数量不足'))
                else
                    self:SendSignal(POST.UNION_PARTY_SUBMIT_FOOD.cmdName, {foodId = foodId, num = selectNum})
                end   
            end
        else
            local text = ''
            if state == 1 then
                text = __('您还未解锁该菜品所属菜系')
            elseif state == 2 then
                text = __('您还未学会该菜谱')
            elseif state == 3 then
                text = __('该菜谱尚未达到需求品级')
            end
            uiMgr:ShowInformationTips(text)
        end

    elseif COMMON_BUY_VIEW_FAST_COMPLETE == name then
        -- logInfo.add(4, 'COMMON_BUY_VIEW_FAST_COMPLETE2')
        local unitPrice = checkint(body.unitPrice)
        local data      = body.data or {}
        local targetNum        = checkint(data.targetNum)
        local submittedNum     = checkint(data.submittedNum)
        local leftNum          = checkint(body.selectNum)

        local needCurrency = leftNum * unitPrice
        local ownDiamond = checkint(CommonUtils.GetCacheProductNum(DIAMOND_ID))
        local isFastComplete = ownDiamond >= needCurrency

        if isFastComplete then
            local commonTip = require( 'common.CommonTip' ).new({ text = __('是否要快速筹备?'), descr = string.format(__('是否要消耗%s幻晶石来补充上交菜品？'), needCurrency), callback = function()
                PlayAudioByClickNormal()
                local foodId = data.foodId
                self:SendSignal(POST.UNION_PARTY_SUBMIT_FOOD_DIAMOND.cmdName, {foodId = foodId, num = leftNum})
            end })
            commonTip:setPosition(display.center)
            commonTip:setTag(5555)
            local scene = uiMgr:GetCurrentScene()
            scene:AddDialog(commonTip, 10)
        else
            if GAME_MODULE_OPEN.NEW_STORE then
                app.uiMgr:showDiamonTips()
            else
                uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {_name_ = CommonUtils.GetCacheProductName(DIAMOND_ID)}))
            end
        end
    elseif 'REFRESH_NOT_CLOSE_GOODS_EVENT' == name then
        self.isControllable_ = false
        self:reloadList_()
        self:reloadCommonBuyView_()
        self.isControllable_ = true
    end

end

-------------------------------------------------
-- get / set

function UnionPartyPrepareTaskMediator:getCtorArgs()
    return self.ctorArgs_
end

function UnionPartyPrepareTaskMediator:getViewData()
    return self.viewData_
end

function UnionPartyPrepareTaskMediator:getOwnerScene()
    return self.ownerScene_
end

function UnionPartyPrepareTaskMediator:getAppRouter()
    return AppFacade.GetInstance():RetrieveMediator('Router')
end

-------------------------------------------------
-- public method

--==============================--
--desc: 更新提交菜品相关数据
--time:2018-02-22 11:16:11
--@submitType:
--@data:
--@return 
--==============================-- 
function UnionPartyPrepareTaskMediator:updateSubmitRewardData(submitType, data)
    local requestData = data.requestData
    local foodId      = checkint(requestData.foodId)
    local submitNum  = checkint(requestData.num)
    local unionPoint  = checkint(data.unionPoint)
    local contributionPoint = checkint(data.contributionPoint)
    local realSubmitFoodNum = checkint(data.realSubmitFoodNum)
    -- 未更新前的玩家最终的公会币
    local oldUnionPoint = gameMgr:GetAmountByIdForce(UNION_POINT_ID)
    local oldUnionContributionPoint = gameMgr:GetAmountByIdForce(UNION_CONTRIBUTION_POINT_ID) 
    
    -- 弹奖励， 但不更新背包
    local reward = {{goodsId = UNION_POINT_ID, num = unionPoint - oldUnionPoint}, 
        {goodsId = UNION_CONTRIBUTION_POINT_ID, num = contributionPoint - oldUnionContributionPoint}}

    local consumePartyGood = {
        
    }
    -- 更新背包奖励
    local backpackReward = {
        {goodsId = UNION_POINT_ID, num = unionPoint - oldUnionPoint},
    }
    if submitType == SUBMIT_FOOD_TYPE.FAST then
        local num = checkint(data.diamond) - checkint(CommonUtils.GetCacheProductNum(DIAMOND_ID))
        table.insert(backpackReward, {goodsId = DIAMOND_ID, num = num})
        table.insert(consumePartyGood, {goodsId = DIAMOND_ID, num = num < 0 and num * -1 or num})
    else
        table.insert(backpackReward, {goodsId = foodId, num = -realSubmitFoodNum})
        table.insert(consumePartyGood, {goodsId = foodId, num = realSubmitFoodNum})
    end

    uiMgr:AddDialog('common.RewardPopup', {rewards = reward, consumePartyGood = consumePartyGood, addBackpack = false})

    -- 更新玩家最终的公会捐献
    unionMgr:updateUnionData({playerContributionPoint = contributionPoint})
    
    CommonUtils.DrawRewards(backpackReward, true)
    
    logInfo.add(4, string.format("%s atm %s", submitNum, realSubmitFoodNum))
    local isWholeSubmitSuccess = submitNum == realSubmitFoodNum
    local index = self:updateSubmittedFoods(isWholeSubmitSuccess, realSubmitFoodNum, foodId)

    return index
end

--==============================--
--desc: 更新提价菜品数
--time:2018-02-22 11:18:43
--@isWholeSubmitSuccess:
--@realSubmitFoodNum:
--@foodId:
--@return 
--==============================-- 
function UnionPartyPrepareTaskMediator:updateSubmittedFoods(isWholeSubmitSuccess, realSubmitFoodNum, foodId)
    local index = 0
    
    for i,v in ipairs(self.submittedFoods) do
        if checkint(v.foodId) == foodId then
            index = i
            local targetNum = checkint(v.targetNum)
            if isWholeSubmitSuccess then
                v.submittedNum = (checkint(v.submittedNum) + realSubmitFoodNum)
                
                v.submittedNum = (v.submittedNum > targetNum) and targetNum or v.submittedNum
                
            else
                v.submittedNum = targetNum
            end
        end
    end
    self.submitTotalFoodCount = self.submitTotalFoodCount + realSubmitFoodNum
    return index
end

--==============================--
--desc: 更新UI
--time:2018-02-02 04:37:33
--@foodId:
--@return 
--==============================-- 
function UnionPartyPrepareTaskMediator:updateUi(foodId, index)
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    local cell = gridView:cellAtIndex(index - 1)
    local data = self.submittedFoods[index]
    if cell then
        local viewData = cell.viewData
        logInfo.add(4, tableToString(data))
        self:updateCellView(viewData, data)
    end

    self:GetViewComponent():updatePrepareState(self.submitTotalFoodCount, self.datas.unionLevel)

    if self.commonBuyView then
        local curData = self.commonBuyView:getCurData()
        if curData.foodId == data.foodId then
            self.commonBuyView:updateData(2, data)
        end
    end
end

--==============================--
--desc:更新Cell视图
--time:2018-02-22 11:24:19
--@viewData:
--@data:
--@return 
--==============================-- 
function UnionPartyPrepareTaskMediator:updateCellView(viewData, data)
    local goodsId   = data.foodId
    local goodNode  = viewData.goodNode
    goodNode:RefreshSelf({goodsId = goodsId})

    local grade            = checkint(data.grade)
    local gradeImg         = viewData.gradeImg
    gradeImg:setTexture(app.cookingMgr:getCookingGradeImg(grade))

    local targetNum        = checkint(data.targetNum)
    local submittedNum     = checkint(data.submittedNum)
    local isComplete       = submittedNum >= targetNum

    local prepareDescLayer = viewData.prepareDescLayer
    local blackCover       = viewData.blackCover
    local touchView        = viewData.touchView

    prepareDescLayer:setVisible(not isComplete)
    touchView:setVisible(not isComplete)
    blackCover:setVisible(isComplete)
    if not isComplete then
        local progressLabel    = viewData.progressLabel
        progressLabel:setString(string.format("%s/%s", submittedNum, targetNum))

        local ownNum, isAppointLv, state = app.cookingMgr:GetFoodNumByGrade(goodsId, grade)
        local ownLabel         = viewData.ownLabel
        local ownCountLabel    = viewData.ownCountLabel
        ownLabel:setVisible(isAppointLv)
        ownCountLabel:setVisible(isAppointLv)
        
        local tipLabel = viewData.tipLabel
        tipLabel:setVisible(not isAppointLv)
        if isAppointLv then
            display.commonLabelParams(ownCountLabel, {text = checkint(ownNum)})
        else
            if state == 1 or state == 2 then
                display.commonLabelParams(tipLabel, {text = __('暂未学会')})
            elseif state == 3 then
                display.commonLabelParams(tipLabel, {text = __('品级不足')})
            end
        end

        local cellBg = viewData.cellBg
        cellBg:setTexture(isAppointLv and _res("ui/union/party/prepare/guild_party_bg_foods_2.png") or _res("ui/union/party/prepare/guild_party_bg_foods.png"))
    end
end

-------------------------------------------------
-- private method

function UnionPartyPrepareTaskMediator:reloadList_()
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    gridView:setCountOfCell(#self.submittedFoods)
    gridView:reloadData()
end

function UnionPartyPrepareTaskMediator:reloadCommonBuyView_()
    if self.commonBuyView then
        local curData = self.commonBuyView:getCurData()
        self.commonBuyView:updateData(2, curData)
    end
end

-------------------------------------------------
-- handler

function UnionPartyPrepareTaskMediator:onDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateCell()
        local touchView = pCell.viewData.touchView
        display.commonUIParams(touchView, {cb = handler(self, self.onSubmitFood)})
    end

    xTry(function()
        local data = self.submittedFoods[index]
        
        local viewData = pCell.viewData
        
        self:updateCellView(viewData, data)

        pCell:setTag(index)
	end,__G__TRACKBACK__)
    return pCell
end

function UnionPartyPrepareTaskMediator:onSubmitFood(sender)
    if not self.isControllable_ then return end
    PlayAudioByClickNormal()
    
    local index = sender:getParent():getTag()
    local data  = self.submittedFoods[index]
    local targetNum = checkint(data.targetNum)
    local submittedNum = checkint(data.submittedNum)
    if submittedNum >= targetNum then return end
    
    local commonBuyView = require("common.CommonBuyView").new({tag = 5556, mediatorName = "UnionPartyPrepareTaskMediator", endCallback = function (selectNum, materialMeet)
        
    end})
    display.commonUIParams(commonBuyView, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
    commonBuyView:setTag(COMMON_BUY_VIEW_TAG)
    local currentScene = uiMgr:GetCurrentScene()
    currentScene:AddDialog(commonBuyView)
    
    commonBuyView:updateData(2, data)

    self.commonBuyView = commonBuyView
end

return UnionPartyPrepareTaskMediator
