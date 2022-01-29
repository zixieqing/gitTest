--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
local CapsuleCardChooseMediator = class("CapsuleCardChooseMediator", Mediator)
local NAME = "CapsuleCardChooseMediator"

local uiMgr    = app.uiMgr
local gameMgr  = app.gameMgr
local cardMgr  = app.cardMgr

local RewardsAnimateMediator  = require('Game.mediator.drawCards.CapsuleAnimateMediator')
local CapsuleCardChooseView   = require("Game.views.drawCards.CapsuleCardChooseView")
local NewPlayerRewardCell     = require("Game.views.drawCards.NewPlayerRewardCell")

function CapsuleCardChooseMediator:ctor( params, viewComponent )
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.selectIndex = nil
end

function CapsuleCardChooseMediator:InterestSignals()
	local signals = {
        POST.GAMBLING_CARD_CHOOSE.sglName,           -- 选卡卡池
        POST.GAMBLING_CARD_CHOOSE_ENTER.sglName,     -- 选卡卡池选择
        POST.GAMBLING_CARD_CHOOSE_LUCKY.sglName,     -- 选卡卡池抽卡
        POST.GAMBLING_CARD_CHOOSE_QUIT.sglName,      -- 选卡卡池退出
	}
	return signals
end

function CapsuleCardChooseMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = signal:GetBody()
    -- dump(body, name)
    if name == POST.GAMBLING_CARD_CHOOSE.sglName then
        self:updateUIShowState()
    elseif name == POST.GAMBLING_CARD_CHOOSE_ENTER.sglName then
        local requestData = body.requestData or {}
        local consumeId   = requestData.consumeId
        local consumeNum  = requestData.consumeNum
        -- 扣除消耗的道具
        CommonUtils.DrawRewards({{goodsId = consumeId, num = -consumeNum}})
        -- 更新当前选择的卡牌i
        self.datas.currentCardId = requestData.cardId

        local option = self.datas.option or {}
        local data   = option[self.selectIndex] or {}

        self:showCardDrawView()
    elseif name == POST.GAMBLING_CARD_CHOOSE_LUCKY.sglName then
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "1004-M1-01"})
        local requestData = body.requestData
        local consumeId   = requestData.consumeId
        local consumeNum  = requestData.consumeNum

        -- 扣除消耗的道具
        CommonUtils.DrawRewards({{goodsId = consumeId, num = -consumeNum}})

        local dType = checkint(body.requestData.type)
        local option = self.datas.option or {}
        local data   = option[self.selectIndex] or {}
        if dType == 2 then
            data.hasGamblingTimes = checkint(data.hasGamblingTimes) + 10
        else
            data.hasGamblingTimes = checkint(data.hasGamblingTimes) + 1
        end
        -- local diamond = body.diamond
        CommonUtils.RefreshDiamond(body)

        self:GetViewComponent():updateDrawCardUI(self.datas)
        -- show rewards animate
        local cardRewards = {}
        for i, goodsData in ipairs(body.rewards or {}) do
            local goodsType = CommonUtils.GetGoodTypeById(goodsData.goodsId)
            if goodsType == GoodsType.TYPE_CARD or goodsType == GoodsType.TYPE_CARD_FRAGMENT then
                table.insert(cardRewards, goodsData)
            end
        end
        self:GetFacade():RegistMediator(RewardsAnimateMediator.new({rewards = cardRewards, activityRewards = body.activityRewards}))

    elseif name == POST.GAMBLING_CARD_CHOOSE_QUIT.sglName then
        -- self.datas.currentCardId = nil
        self.selectIndex = nil
        self:SendSignal(POST.GAMBLING_CARD_CHOOSE.cmdName, {activityId = self.activityId})
    end
end

function CapsuleCardChooseMediator:Initial( key )
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    if self.ownerNode_ then
        -- create shadow layer
        self.shadowLayer_ = display.newLayer(-self.ownerNode_:getPositionX(), -self.ownerNode_:getPositionY(), {size = display.size, color = cc.c4b(0,0,0,150)})
        self.shadowLayer_:setVisible(false)
        self.ownerNode_:addChild(self.shadowLayer_)

        -- create view
        local size = self.ownerNode_:getContentSize()
        local view = CapsuleCardChooseView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view)
        self:SetViewComponent(view)

        self.viewData_ = view:getViewData()

        self:initView()
    end
end

function CapsuleCardChooseMediator:initView()
    local viewData       = self:getViewData()
    local selectCardView = viewData.selectCardView
    local selectCardViewData = selectCardView:getViewData()
    selectCardViewData.gridView:setDataSourceAdapterScriptHandler(handler(self,self.onDataSourceAdapter))

    display.commonUIParams(selectCardViewData.selectButton, {cb = handler(self, self.onClickSelectBtnAction)})

    local drawCardView     = viewData.drawCardView
    local drawCardViewData = drawCardView:getViewData()
    display.commonUIParams(drawCardViewData.quitBtn,     {cb = handler(self, self.onClickQuitBtnAction)})
    display.commonUIParams(drawCardViewData.drawOnceBtn, {cb = handler(self, self.onClickDrawOnceBtnAction)})
    display.commonUIParams(drawCardViewData.drawMuchBtn, {cb = handler(self, self.onClickDrawMuchBtnAction)})
end

-------------------------------------------------
-- public method

function CapsuleCardChooseMediator:resetHomeData(homeData, activityId)
    self.datas = homeData or {}
    self.activityId = activityId
    
    local viewComponent = self:GetViewComponent()
    if viewComponent == nil then return end
    local option = self.datas.option or {}
    -- self.datas.currentCardId = option[1].cardId

    local currentCardId = checkint(self.datas.currentCardId)
    
    local dataIndex          = nil
    for i, v in ipairs(option) do
        if checkint(v.cardId) == currentCardId then
            dataIndex = i
            break
        end
    end
    self.selectIndex = dataIndex

    self:updateUIShowState()
end

--[[
--正常的抽卡状态下更新相关界面显示
--]]
function CapsuleCardChooseMediator:FreshUI()

end

--==============================--
--desc: 更新ui显示状态
--==============================--
function CapsuleCardChooseMediator:updateUIShowState()
    local isSelect = checkint(self.datas.currentCardId) > 0
    local CapsuleNewMediator = app:RetrieveMediator("CapsuleNewMediator")
    if CapsuleNewMediator then
        CapsuleNewMediator:updatePreviewBtnShowState(isSelect)
        if isSelect then
            local name = CardUtils.GetCardConfig(self.datas.currentCardId).name
            CapsuleNewMediator:updatePreviewBtnName(string.fmt(__("__name__卡池一览"), {__name__ = tostring(name)}))
        end
    end
    self.shadowLayer_:setVisible(not isSelect)

    self:GetViewComponent():updateUIShowState(self.datas)
end

--==============================--
--desc: 显示抽卡视图
--==============================--
function CapsuleCardChooseMediator:showCardDrawView()
    local currentCardId = checkint(self.datas.currentCardId)
    local isSelect = currentCardId > 0

    local viewComponent = self:GetViewComponent()
    viewComponent:hideUI()
    viewComponent:updateDrawCardUI(self.datas)
    -- viewComponent:showDrawCardUI(self.datas, true)

    viewComponent:showUIAction(currentCardId, function ()
        self.shadowLayer_:runAction(cc.Hide:create())
        -- local CapsuleNewMediator = app:RetrieveMediator("CapsuleNewMediator")
        -- if CapsuleNewMediator then
        --     CapsuleNewMediator:updatePreviewBtnShowState(isSelect, true)
        -- end
        -- self.datas.currentCardId = self.datas.option[1].cardId
        -- viewComponent:showDrawCardUI(self.datas)
    end)
end

-------------------------------------------------
-- private method

function CapsuleCardChooseMediator:onDataSourceAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    local sizee = cc.size(230 , 560)
    if pCell == nil then
        pCell = NewPlayerRewardCell.new(sizee)
        display.commonUIParams(pCell.viewData.toggleView, {animate = false, cb = handler(self, self.onCellButtonAction)})
    end

    xTry(function()
        local option = self.datas.option or {}
        local data   = option[index] or {}
        local cardId = data.cardId

        local viewComponent = self:GetViewComponent()
        viewComponent:updateCell(pCell, data)
        viewComponent:updateCellSelectState(pCell, self.selectIndex == index)

        pCell.viewData.toggleView:setTag(index)
        pCell.viewData.toggleView:setUserTag(cardId)
        pCell:setTag(index)
    end,function()
        pCell = CGridViewCell:new()
    end)

    return pCell
end

--==============================--
--desc: 请求抽卡
--@params drawType   int 抽卡类型
--@params drawTimes  int 抽卡次数  (1, 10)
--@params consumeId  int 消耗道具ID
--@params consumeNum int 消耗数量
--==============================--
function CapsuleCardChooseMediator:requestDrawCard(drawType, drawTimes, consumeId, consumeNum)
    local errTip = self:checkDrawCardCondition(drawTimes, consumeId, consumeNum)
    if errTip then
        uiMgr:ShowInformationTips(errTip)
        return
    end

    self:SendSignal(POST.GAMBLING_CARD_CHOOSE_LUCKY.cmdName, {activityId = self.activityId, type = drawType, consumeId = consumeId, consumeNum = consumeNum})
end

-------------------------------------------------
-- handler

--==============================--
--desc: cell按钮点击事件
--@params sender  userdata 按钮
--==============================--
function CapsuleCardChooseMediator:onCellButtonAction(sender)
    local index = sender:getTag()
    if self.selectIndex == index then return end
    self.selectIndex = index

    local option = self.datas.option or {}
    local data   = option[index] or {}

    local selectCardView = self:getViewData().selectCardView
    local selectCardViewData = selectCardView:getViewData()
    local gridView = selectCardViewData.gridView
    local cells = gridView:getCells()
    local viewComponent = self:GetViewComponent()
    if cells and next(cells) ~= nil then
        for i, cell in ipairs(cells) do
            viewComponent:updateCellSelectState(cell, self.selectIndex == checkint(cell:getTag()))
        end
    end

    local CapsuleNewMediator = app:RetrieveMediator("CapsuleNewMediator")
    if CapsuleNewMediator then
        CapsuleNewMediator:updatePreviewBtnShowState(true)
        local name = CardUtils.GetCardConfig(data.cardId).name
        CapsuleNewMediator:updatePreviewBtnName(string.fmt(__("__name__卡池一览"), {__name__ = tostring(name)}))
    end

    viewComponent:updateSelectCardUIShowState(true, data)
end

--==============================--
--desc: 选择按钮点击事件
--@params sender  userdata 按钮
--==============================--
function CapsuleCardChooseMediator:onClickSelectBtnAction(sender)
    PlayAudioByClickNormal()
    
    local currentCardId = checkint(self.datas.currentCardId)
    --如果当前选择的皮肤已选择过
    if currentCardId > 0 and checkint(self.datas.leftGamblingTimes) == 0 then
        --表示当前选择的卡池不能再选择去抽了
        uiMgr:ShowInformationTips(__('如果当前选择的卡池已抽完，请选择其他'))
        return
    end

    --请求选择卡
    local option = self.datas.option or {}
    local data   = option[self.selectIndex] or {}
    local consumeData = CommonUtils.GetCapsuleConsume(data.consume or {})
    local consumeId =  consumeData.goodsId
    local consumeNum =  consumeData.num
    local errTip = self:checkGoodIsSatisfy(consumeId, consumeNum)
    if errTip then
        uiMgr:ShowInformationTips(errTip)
        return
    end

     --出一个提示判断的逻辑
     local commonTip = require( 'common.CommonTip' ).new({ text = __('是否选择此飨灵进入卡池?'),
     descr = __('确认后直到抽到该卡前，不能替换重置该卡池'), callback = function()
            self:SendSignal(POST.GAMBLING_CARD_CHOOSE_ENTER.cmdName, {activityId = self.activityId, cardId = data.cardId, consumeId = consumeId, consumeNum = consumeNum,})
            -- self:showCardDrawView()
        end})
    commonTip:setPosition(display.center)
    commonTip:setTag(5555)
    uiMgr:GetCurrentScene():AddDialog(commonTip, 10)
end

--==============================--
--desc: 退出按钮点击事件
--@params sender  userdata 按钮
--==============================--
function CapsuleCardChooseMediator:onClickQuitBtnAction(sender)
    local commonTip = require( 'common.CommonTip' ).new({ text = __('确认是否退出当前卡池?'),
     descr = __('退出后当前卡池即不存在，需重新选择飨灵开始召唤'), callback = function()
            self:SendSignal(POST.GAMBLING_CARD_CHOOSE_QUIT.cmdName, {activityId = self.activityId})
        end})
    commonTip:setPosition(display.center)
    commonTip:setTag(5555)
    uiMgr:GetCurrentScene():AddDialog(commonTip, 10)
end

--==============================--
--desc: 单抽按钮点击事件
--@params sender  userdata 按钮
--==============================--
function CapsuleCardChooseMediator:onClickDrawOnceBtnAction(sender)
    local goodsId = checkint(sender:getTag())
    local num     = checkint(sender:getUserTag())
    self:requestDrawCard(1, 1, goodsId, num)
end

--==============================--
--desc: 多抽按钮点击事件
--@params sender  userdata 按钮
--==============================--
function CapsuleCardChooseMediator:onClickDrawMuchBtnAction(sender)
    local goodsId = checkint(sender:getTag())
    local num     = checkint(sender:getUserTag())
    self:requestDrawCard(2, 10, goodsId, num)
end

-------------------------------------------------
-- get/set
function CapsuleCardChooseMediator:getViewData()
    return self.viewData_
end

--==============================--
--desc: 获得选择卡牌下标
--@return selectIndex index  选择卡牌下标
--==============================--
function CapsuleCardChooseMediator:getSelectIndex()
    return self.selectIndex
end

--==============================--
--desc: 检查道具是否满足条件
--@params drawTimes  int 抽卡次数  (1, 10)
--@params consumeId  int 消耗道具ID
--@params consumeNum int 消耗数量
--@return errorMsg   string  错误提示
--==============================--
function CapsuleCardChooseMediator:checkDrawCardCondition(drawTimes, consumeId, consumeNum)
    local option            = self.datas.option or {}
    local data              = option[self.selectIndex] or {}
    local maxGamblingTimes  = checkint(data.maxGamblingTimes)
    local hasGamblingTimes  = checkint(data.hasGamblingTimes)
    local leftGamblingTimes = maxGamblingTimes - hasGamblingTimes
    
    local errorMsg = nil
    if leftGamblingTimes < drawTimes then
        errorMsg = __("抽奖次数不足")
    else
        errorMsg = self:checkGoodIsSatisfy(consumeId, consumeNum)
    end

    return errorMsg
end

--==============================--
--desc: 检查道具是否满足条件
--@params consumeId  int 消耗道具ID
--@params consumeNum int 消耗数量
--@return errorMsg   string  错误提示
--==============================--
function CapsuleCardChooseMediator:checkGoodIsSatisfy(consumeId, consumeNum)
    local errorMsg = nil
    if gameMgr:GetAmountByGoodId(consumeId) < consumeNum then
        local data = CommonUtils.GetConfig('goods', 'goods', consumeId) or {}
        errorMsg = string.fmt(__("_name_数量不足"), {_name_ = tostring(data.name)})
    end
    return errorMsg
end

function CapsuleCardChooseMediator:OnRegist()
    regPost(POST.GAMBLING_CARD_CHOOSE_ENTER)
    regPost(POST.GAMBLING_CARD_CHOOSE)
    regPost(POST.GAMBLING_CARD_CHOOSE_LUCKY)
    regPost(POST.GAMBLING_CARD_CHOOSE_QUIT)
end

function CapsuleCardChooseMediator:OnUnRegist()
    unregPost(POST.GAMBLING_CARD_CHOOSE_ENTER)
    unregPost(POST.GAMBLING_CARD_CHOOSE)
    unregPost(POST.GAMBLING_CARD_CHOOSE_LUCKY)
    unregPost(POST.GAMBLING_CARD_CHOOSE_QUIT)
end

function CapsuleCardChooseMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.shadowLayer_:runAction(cc.RemoveSelf:create())
            self.shadowLayer_ = nil
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end

return CapsuleCardChooseMediator
