local CommonDialog = require('common.CommonDialog')
local CommonBuyView = class('common.CommonBuyView', CommonDialog)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local PARTY_FOOD_REWARD_CONF    = CommonUtils.GetConfigAllMess('partyFoodReward', 'union')

local CreateView = nil
local CreateExchange = nil
local CreatePartyView = nil

local CreateNumChoiceView = nil
local CreateFoodRewardById = nil

local getFoodGradeDataByGrade = nil

local VIEW_TAG = {
    EXCHANGE = 1,
    PARTY    = 2,
}

local BUTTON_TAG = {
    PURCHASE_NUM_BG = 1000,  -- 弹出键盘
    MINUS           = 1001,  -- 减
    ADD             = 1002,  -- 加
    PAY             = 1003,  -- 兑换
    MAX             = 1004,  -- 最大
    FAST_COMPLETE   = 1005,  -- 快速完成
    PURCHASE        = 1006,  -- 快速完成
}

local RES_DIR = {
    BG               = _res('ui/common/common_bg_7.png'),
    TITLE_1          = _res('ui/common/common_bg_title_2.png'),
    PURCHASE_NUM_BG  = _res('ui/home/market/market_buy_bg_info.png'),
    SUB              = _res('ui/home/market/market_sold_btn_sub.png'),
    PLUS             = _res('ui/home/market/market_sold_btn_plus.png'),
    TITLE_2          = _res('ui/common/common_title_5.png'),
    BTN_ORANGE       = _res('ui/common/common_btn_orange.png'),
    BTN_GREEN        = _res('ui/common/common_btn_green.png'),
    BTN_ORANGE_DISABLE = _res('ui/common/common_btn_orange_disable.png'),
    NUM_BG           = _res('ui/home/commonShop/market_sold_bg_goods_info.png'),
    REWARD_BG        = _res('ui/home/takeaway/takeout_bg_reward_number.png'),
    BTN_MAX_BG       = _res('ui/home/market/market_sold_btn_zuida.png'),
    EXHIBITION_BG    = _res("ui/union/party/prepare/guild_party_preparation_bg.png"),
    FOOD_BG          = _res("ui/airship/ship_ico_label_goods_tag.png"),
}

function CommonBuyView:InitialUI()
    self:initData()

    self.viewData = CreateView()
    self.childViewData = nil

    AppFacade.GetInstance():DispatchObservers(COMMON_BUY_VIEW_ENTER)

end

function CommonBuyView:initData()
    self.selectNum = 1
    self.maxNum    = 1
    self.curData   = {}

    self.materialMeet = true

    self.isClose = checkbool(self.args.isClose)

    self.unitPrice = 0

end

function CommonBuyView:initViewClickAction(tag)

    if tag == VIEW_TAG.EXCHANGE then
        local purchaseNumBg    = self.childViewData.purchaseNumBg
        local btn_minus        = self.childViewData.btn_minus
        local btn_add          = self.childViewData.btn_add
        local purchaseBtn      = self.childViewData.purchaseBtn

        display.commonUIParams(purchaseNumBg, {cb = handler(self, self.OnButtonAction)})
        display.commonUIParams(btn_minus, {cb = handler(self, self.OnButtonAction)})
        display.commonUIParams(btn_add, {cb = handler(self, self.OnButtonAction)})
        display.commonUIParams(purchaseBtn, {cb = handler(self, self.OnButtonAction)})
    elseif tag == VIEW_TAG.PARTY then

    end

end

function CommonBuyView:OnButtonAction(sender)
    local tag = sender:getTag()

    if tag == BUTTON_TAG.PURCHASE_NUM_BG then
        self:SetNumBtnCallback(sender)
    elseif tag == BUTTON_TAG.ADD then
        self:AddNumBtnCallback(sender)
    elseif tag == BUTTON_TAG.MINUS then
        self:MinusNumBtnCallback(sender)
    elseif tag == BUTTON_TAG.PAY then
        self:PayBtnCallback(sender)
    elseif tag == BUTTON_TAG.MAX then
        self:MaxNumBtnCallback(sender)
    elseif tag == BUTTON_TAG.FAST_COMPLETE then
        self:FastCompleteBtnCallback(sender)
    end
end

--==============================--
--desc: 设置数字
--time:2018-02-02 11:16:00
--@sender:
--@return
--==============================--
function CommonBuyView:SetNumBtnCallback( sender )
	local tempData = {}
	tempData.callback = handler(self, self.numkeyboardCallBack)
	tempData.titleText = self.curViewTag == VIEW_TAG.EXCHANGE and __('请输入需要兑换的数量') or __('请输入需要提交的数量')
	tempData.nums = 3
	tempData.model = NumboardModel.freeModel

	local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' ) 
	local mediator = NumKeyboardMediator.new(tempData)
	AppFacade.GetInstance():RegistMediator(mediator)

end

--==============================--
--desc:处理数字键盘回调
--time:2018-02-02 11:16:17
--@data:
--@return
--==============================---
function CommonBuyView:numkeyboardCallBack(data)
	if data then
		if data == '' then
			data = 1
		end
		if checkint(data) <= 0 then
			data = 1
        end
        if checkint(data) > self.maxNum then
            data = self.maxNum
        end
        if self.selectNum == data then
            return
        end

        self:updatePurchaseNum(checkint(data))

        self:updateAppointView()

	end
end

--==============================--
--desc:添加数字回调
--time:2018-02-02 11:16:39
--@sender:
--@return
--==============================--
function CommonBuyView:AddNumBtnCallback(sender)
    self.selectNum = self.selectNum + 1
    if self.selectNum > self.maxNum then
        self.selectNum = self.maxNum
    end

    self:updatePurchaseNum()
    self:updateAppointView()
end

--==============================--
--desc:减去数字回调
--time:2018-02-02 11:17:00
--@sender:
--@return
--==============================--
function CommonBuyView:MinusNumBtnCallback(sender)

    self.selectNum = self.selectNum - 1
    if self.selectNum <= 0 then
        self.selectNum = 1
    end

    self:updatePurchaseNum()
    self:updateAppointView()

end

function CommonBuyView:MaxNumBtnCallback(sender)
    self:updatePurchaseNum(self.maxNum)
    self:updateAppointView()
end

function CommonBuyView:PayBtnCallback(sender)
    AppFacade.GetInstance():DispatchObservers(COMMON_BUY_VIEW_PAY, {selectNum = self.selectNum, data = self.curData, materialMeet = self.materialMeet})
    if self.isClose then
        self:CloseHandler()
    end
end

function CommonBuyView:FastCompleteBtnCallback(sender)
    AppFacade.GetInstance():DispatchObservers(COMMON_BUY_VIEW_FAST_COMPLETE, {maxNum = self.maxNum, selectNum = self.selectNum, unitPrice = self.unitPrice, data = self.curData})
end

function CommonBuyView:updateMaterialLbs()
    if self.materialLbs == nil then return end
    self.materialMeet = true
    for i,v in ipairs(self.materialLbs) do
        local lb, amount, goodsId = v.lb, checkint(v.amount), checkint(v.goodsId)
        amount = amount * self.selectNum
        local ownAmount = gameMgr:GetAmountByGoodId(goodsId)
        local fontNum = ownAmount >= amount and 16 or 10

        local leftColor = ownAmount >= amount and fontWithColor('16').color or fontWithColor('10').color
        display.reloadRichLabel(lb, {c = {
            {text = ownAmount, fontSize = fontWithColor('16').fontSize, color = leftColor},
            {text = '/' .. amount, fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color},
        }})

        self.materialMeet = self.materialMeet and (ownAmount >= amount)
    end
end

function CommonBuyView:updateData(tag, data)
    self.curViewTag = tag
    self.curData    = data
    if tag == VIEW_TAG.EXCHANGE then
        self:updateExchangeView(data)
    elseif tag == VIEW_TAG.PARTY then
        self:updatePartyView(data)
    end
end

function CommonBuyView:updateExchangeView(data)
    if self.childViewData == nil then
        self.childViewData = CreateExchange(self.viewData.view, self.viewData.bgSize)
        self:initViewClickAction(VIEW_TAG.EXCHANGE)
    end
    local rewardLayer      = self.childViewData.goodLayer
    local numTipLabel      = self.childViewData.numTipLabel
    local purchaseNumBg    = self.childViewData.purchaseNumBg
    local purchaseNum      = self.childViewData.purchaseNum
    local btn_minus        = self.childViewData.btn_minus
    local btn_add          = self.childViewData.btn_add
    local titleBg2         = self.childViewData.titleBg2
    local materialLayer    = self.childViewData.materialLayer
    local purchaseBtn      = self.childViewData.purchaseBtn

    local require = data.require or {}
    local rewards = data.rewards or {}
    self.maxNum = data.leftExchangeTimes

    local rewardLayerSize = rewardLayer:getContentSize()
    local params = {parent = rewardLayer, midPointX = rewardLayerSize.width / 2, midPointY = rewardLayerSize.height / 2, maxCol= 2, scale = 0.9, rewards = rewards, hideCustomizeLabel = true}
    CommonUtils.createPropList(params)

    local function callBack(sender)
        local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
        uiMgr:AddDialog("common.GainPopup", {goodId = sender.goodId})
    end
    local materialLayerSize = materialLayer:getContentSize()
    local params1 = {parent = materialLayer, midPointX = materialLayerSize.width / 2, midPointY = materialLayerSize.height / 2, maxCol= 5, scale = 0.7, rewards = require, hideAmount = true, callBack = callBack}
    local goodNodes, materialLbs = CommonUtils.createPropList(params1)  
    
    for i,v in ipairs(materialLbs) do
        local lb, amount, goodsId = v.lb, checkint(v.amount), checkint(v.goodsId)
        local ownAmount = gameMgr:GetAmountByGoodId(goodsId)

        local leftColor = ownAmount >= amount and fontWithColor('16').color or fontWithColor('10').color
        display.reloadRichLabel(lb, {c = {
            {text = ownAmount, fontSize = fontWithColor('16').fontSize, color = leftColor},
            {text = '/' .. amount, fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color},
        }})

        lb:setPosition(cc.p(lb:getPositionX(), lb:getPositionY() - 8))

        self.materialMeet = self.materialMeet and (ownAmount >= amount)
    end

    self.materialLbs = materialLbs
end

function CommonBuyView:updatePartyView(data)
    if self.childViewData == nil then
        self.childViewData = CreatePartyView(self.viewData.view, self.viewData.bgSize)
        display.commonLabelParams(self.viewData.titleBg, {text = __('筹备')})

        for tag,btn in pairs(self.childViewData.actionBtns) do
            display.commonUIParams(btn, {cb = handler(self, self.OnButtonAction)})
        end
    end

    local goodsId          = data.foodId
    local goodNode         = self.childViewData.goodNode
    goodNode:RefreshSelf({goodsId = goodsId})

    local grade            = checkint(data.grade)
    local gradeImg         = self.childViewData.gradeImg
    gradeImg:setTexture(app.cookingMgr:getCookingGradeImg(grade))

    local nameLabel        = self.childViewData.nameLabel
    display.commonLabelParams(nameLabel, {text = tostring(goodNode.goodData.name)})

    local targetNum        = checkint(data.targetNum)
    local submittedNum     = checkint(data.submittedNum)
    local progress         = self.childViewData.progress
    display.commonLabelParams(progress, {text = string.format("%s/%s", submittedNum, targetNum)})

    local gradeData = getFoodGradeDataByGrade(grade)
    local ownNum, isAppointLv, state = app.cookingMgr:GetFoodNumByGrade(goodsId, grade)
    local ownLabel         = self.childViewData.ownLabel
    local ownNumLabel      = self.childViewData.ownNumLabel
    local errorTip         = self.childViewData.errorTip
    local fastPreparation  = self.childViewData.fastPreparation

    ownNumLabel:setVisible(isAppointLv)
    ownLabel:setVisible(isAppointLv)
    errorTip:setVisible(not isAppointLv)

    -- 最大能提交量
    local maxCanSubmitNum = checkint(targetNum - submittedNum)
    self.maxNum            = maxCanSubmitNum
    -- self.ownNum            = ownNum
    if isAppointLv then
        display.commonLabelParams(ownNumLabel, {text = ownNum})
        if maxCanSubmitNum == 0 then
            self:updateButtonState(1)
        else
            if ownNum == 0 then
                self:updateButtonState(1)
            else
                self:updateButtonState(2)
            end
        end
    else
        -- 1 未解锁菜系 2 未解锁菜谱 3 不满足菜谱等级
        local text = ''
        if state == 1 then
            text = __('您还未解锁该菜品所属菜系')
        elseif state == 2 then
            text = __('您还未学会该菜谱')
        elseif state == 3 then
            text = __('该菜谱尚未达到需求品级')
        end
        display.commonLabelParams(errorTip, {text = text})
        self:updateButtonState(1)
    end

    if self.childViewData.rewardBgs and next(self.childViewData.rewardBgs) ~= nil then
        self:updateAppointView()
    else
        local rewardLayer      = self.childViewData.rewardLayer
        local rewardLayerSize  = rewardLayer:getContentSize()
        local reward = {{id = UNION_POINT_ID, num = gradeData.unionPoint}, {id = UNION_CONTRIBUTION_POINT_ID, num = gradeData.contributionPoint}}
        local rewardBgs = {}
        for i,v in ipairs(reward) do
            local rewardBg = CreateFoodRewardById(v.id, v.num)
            local rewardBgSize = rewardBg:getContentSize()
            display.commonUIParams(rewardBg, {po = cc.p(0 + (i - 1) * rewardBgSize.width, rewardLayerSize.height / 2), ap = display.LEFT_CENTER})
            rewardLayer:addChild(rewardBg)

            table.insert(rewardBgs, {bg = rewardBg, data = v})
        end
        self.childViewData.rewardBgs = rewardBgs

    end

    local factor = tonumber(gradeData.diamondFactor)
    local price = app.cookingMgr:GetPartyFoodPriceByFactor(goodsId, factor)
    local preparationNum   = self.childViewData.preparationNum
    display.reloadRichLabel(preparationNum, {c = {
        fontWithColor('14',{text = self.selectNum * price}),
        {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.15}
    }})
    self.unitPrice = price

    local purchaseNum      = self.childViewData.purchaseNum
    purchaseNum:setString(self.selectNum)

end

--==============================--
--desc: 更新按钮状态  party: state 1 (没有该菜谱或有该菜谱但是未满足条件) state 2 (满足菜谱条件但是没有菜) state 3 (即满足菜谱条件又有菜)
--time:2018-01-30 11:58:37
--@state:
--@return
--==============================---
function CommonBuyView:updateButtonState(state)
    if self.curViewTag == VIEW_TAG.PARTY then
        local actionBtns      = self.childViewData.actionBtns
        local greenBtn        = actionBtns[tostring(BUTTON_TAG.FAST_COMPLETE)]
        local greenBtnLayer = self.childViewData.greenBtnLayer
        local orangeBtn       = actionBtns[tostring(BUTTON_TAG.PAY)]

        local isDisable = state == 1
        self:updateButtonImg(orangeBtn, isDisable)

    end
end

function CommonBuyView:updateButtonImg(btn, isDisable)
    btn:setNormalImage(isDisable and RES_DIR.BTN_ORANGE_DISABLE or RES_DIR.BTN_ORANGE)
    btn:setSelectedImage(isDisable and RES_DIR.BTN_ORANGE_DISABLE or RES_DIR.BTN_ORANGE)
end

function CommonBuyView:updatePurchaseNum(num)
    if num then
        self.selectNum = num
    end

    local purchaseNum      = self.childViewData.purchaseNum
    display.commonLabelParams(purchaseNum, {text = self.selectNum})
end

function CommonBuyView:updateAppointView()
    if self.curViewTag == VIEW_TAG.EXCHANGE then
        self:updateMaterialLbs()
    elseif self.curViewTag == VIEW_TAG.PARTY then
        for i,v in ipairs(self.childViewData.rewardBgs) do
            local bg, data = v.bg, v.data
            local rewardNum = bg:getChildByName('rewardNum')
            display.commonLabelParams(rewardNum, {text = data.num * self.selectNum})
        end

        local greenBtnLayer = self.childViewData.greenBtnLayer
        if greenBtnLayer:isVisible() then
            local preparationNum = self.childViewData.preparationNum
            display.reloadRichLabel(preparationNum, {c = {
                fontWithColor('14', {text = self.selectNum * self.unitPrice}),
                {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.15}
            }})
        end

    end
end

function CommonBuyView:CloseHandler()

	local currentScene = uiMgr:GetCurrentScene()
	if currentScene then
        currentScene:RemoveDialogByTag(self.args.tag)
    end
    AppFacade.GetInstance():DispatchObservers(COMMON_BUY_VIEW_EXIT)
end

CreateView = function ()
    local bg = display.newImageView(RES_DIR.BG, 0, 0)
    local bgSize = bg:getContentSize()

    local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
    display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
    view:addChild(bg)

    local titleBg = display.newButton(0, 0, {n = RES_DIR.TITLE_1, animation = false})
    display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
    display.commonLabelParams(titleBg, fontWithColor(14, {text = __('兑换'), offset = cc.p(0, -2)}))
    bg:addChild(titleBg)

    return {
        view             = view,
        titleBg          = titleBg,

        bgSize           = bgSize,
    }
end

CreateExchange = function (parent, bgSize)
    local goodLayerSize = cc.size(bgSize.width - 60, 100)
    local goodLayer = display.newLayer(bgSize.width / 2, bgSize.height - 70, {ap = display.CENTER_TOP, size = goodLayerSize})
    parent:addChild(goodLayer)

    local numTipLabel = display.newLabel(160, goodLayer:getPositionY() - goodLayerSize.height - 50, {ap = display.RIGHT_CENTER, text = __('兑换数量'), hAlign  = display.TAC , w = 150 ,   fontSize = fontWithColor('16').fontSize, color = fontWithColor('16').color})
    parent:addChild(numTipLabel)

    local purchaseNumBgSize = cc.size(100, 49)
    local purchaseNumBg = display.newButton(bgSize.width / 2, numTipLabel:getPositionY(), {scale9 = true, n = RES_DIR.PURCHASE_NUM_BG, size = purchaseNumBgSize, ap = cc.p(0.5, 0.5)})
    purchaseNumBg:setTag(BUTTON_TAG.PURCHASE_NUM_BG)
    parent:addChild(purchaseNumBg)

    local purchaseNum = cc.Label:createWithBMFont('font/common_num_1.fnt', 1)
    purchaseNum:setAnchorPoint(cc.p(0.5, 0.5))
    purchaseNum:setHorizontalAlignment(display.TAR)
    purchaseNum:setPosition(purchaseNumBgSize.width / 2, purchaseNumBgSize.height / 2)
    purchaseNumBg:addChild(purchaseNum)

    --减号btn
    local btn_minus = display.newButton(0, 0, {n = RES_DIR.SUB})
    display.commonUIParams(btn_minus, {po = cc.p(purchaseNumBg:getPositionX() - purchaseNumBgSize.width / 2 + 3, purchaseNumBg:getPositionY()), ap = display.RIGHT_CENTER})
    parent:addChild(btn_minus)
    btn_minus:setTag(BUTTON_TAG.MINUS)

    --加号btn
    local btn_add = display.newButton(0, 0, {n = RES_DIR.PLUS})
    display.commonUIParams(btn_add, {po = cc.p(purchaseNumBg:getPositionX() + purchaseNumBgSize.width / 2 - 3, purchaseNumBg:getPositionY()), ap = display.LEFT_CENTER})
    parent:addChild(btn_add)
    btn_add:setTag(BUTTON_TAG.ADD)

    local titleBg2 = display.newButton(0, 0, {n = RES_DIR.TITLE_2, animation = false ,scale9 = true })
    display.commonUIParams(titleBg2, {po = cc.p(bgSize.width * 0.5, bgSize.height / 2 - 40)})
    display.commonLabelParams(titleBg2,
        {text = __('消耗材料'), fontSize = 22, color = '#5b3c25', paddingW = 30
    })
    parent:addChild(titleBg2)

    local materialLayer = display.newLayer(bgSize.width / 2, titleBg2:getPositionY() - 30, {ap = display.CENTER_TOP, size = goodLayerSize})
    parent:addChild(materialLayer)

    local purchaseBtn = display.newButton(bgSize.width/2, 70, {ap = display.CENTER_TOP, tag = btnTag, n = RES_DIR.BTN_ORANGE})
    display.commonLabelParams(purchaseBtn, fontWithColor(14,{text = __('兑换')}))
    parent:addChild(purchaseBtn)
    purchaseBtn:setTag(BUTTON_TAG.PAY)

    return {
        goodLayer        = goodLayer,
        numTipLabel      = numTipLabel,
        purchaseNumBg    = purchaseNumBg,
        purchaseNum      = purchaseNum,
        btn_minus        = btn_minus,
        btn_add          = btn_add,
        titleBg2         = titleBg2,
        materialLayer    = materialLayer,
        purchaseBtn      = purchaseBtn,
    }
end

CreatePartyView = function (parent, bgSize)
    local actionBtns = {}

    local exhibitionBg = display.newLayer(bgSize.width / 2, bgSize.height - 44, {bg = RES_DIR.EXHIBITION_BG, ap = display.CENTER_TOP})
    local exhibitionBgSize = exhibitionBg:getContentSize()
    parent:addChild(exhibitionBg)
     -- 道具
    local goodBg = display.newImageView(RES_DIR.FOOD_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local goodBgSize = goodBg:getContentSize()
    local goodLayer = display.newLayer(exhibitionBgSize.width / 2, exhibitionBgSize.height - 10, {ap = display.CENTER_TOP, size = goodBgSize})
    goodLayer:addChild(goodBg)
    exhibitionBg:addChild(goodLayer)
    goodLayer:setScale(0.9)

    local goodNode = require('common.GoodNode').new({id = 150061, showAmount = false, callBack = function (sender)
		uiMgr:AddDialog("common.GainPopup", {goodId = sender.goodId})
    end})
    display.commonUIParams(goodNode,{po = cc.p(goodBgSize.width / 2, goodBgSize.height / 2), ap = display.CENTER})
    goodNode.fragmentImg:setVisible(false)
    goodNode.bg:setVisible(false)
    goodLayer:addChild(goodNode)

    local gradeImg = display.newImageView(app.cookingMgr:getCookingGradeImg(1), 15, goodBgSize.height + 5, {ap = display.CENTER_TOP})
    goodLayer:addChild(gradeImg)

    local nameLabel = display.newLabel(goodBgSize.width / 2, 0, fontWithColor(16, {ap = display.CENTER_TOP, text = goodNode.goodData.name}))
    goodLayer:addChild(nameLabel)

    -- 筹备进度
    local progressBg = display.newImageView(RES_DIR.PURCHASE_NUM_BG, exhibitionBgSize.width / 2 + 10, 135, {ap = display.CENTER})
    exhibitionBg:addChild(progressBg)

    local progressBgSize = progressBg:getContentSize()
    local progress = display.newLabel(progressBgSize.width / 2, progressBgSize.height / 2, {text = '1/2', fontSize = 26, color = '#8e5b35', font = TTF_GAME_FONT, ttf = true, ap = display.CENTER})
    progressBg:addChild(progress)

    local progressLabel = display.newLabel(145, progressBg:getPositionY(), fontWithColor(16, {text = __('筹备进度'), ap = display.RIGHT_CENTER}))
    exhibitionBg:addChild(progressLabel)

    -- 筹备数量
    local numTipLabel = display.newLabel(145, progressBg:getPositionY() - 60, fontWithColor(16, {text = __('筹备进度'), ap = display.RIGHT_CENTER}))
    exhibitionBg:addChild(numTipLabel)

    local purchaseNumBgSize = cc.size(118, 49)
    local purchaseNumBg = display.newButton(exhibitionBgSize.width / 2 + 10, numTipLabel:getPositionY(), {scale9 = true, n = RES_DIR.PURCHASE_NUM_BG, size = purchaseNumBgSize, ap = cc.p(0.5, 0.5)})
    purchaseNumBg:setTag(BUTTON_TAG.PURCHASE_NUM_BG)
    exhibitionBg:addChild(purchaseNumBg)
    actionBtns[tostring(BUTTON_TAG.PURCHASE_NUM_BG)] = purchaseNumBg

    local purchaseNum = cc.Label:createWithBMFont('font/common_num_1.fnt', 1)
    purchaseNum:setAnchorPoint(cc.p(0.5, 0.5))
    purchaseNum:setHorizontalAlignment(display.TAR)
    purchaseNum:setPosition(purchaseNumBgSize.width / 2, purchaseNumBgSize.height / 2)
    purchaseNumBg:addChild(purchaseNum)

    --减号btn
    local btn_minus = display.newButton(0, 0, {n = RES_DIR.SUB})
    display.commonUIParams(btn_minus, {po = cc.p(purchaseNumBg:getPositionX() - purchaseNumBgSize.width / 2 + 6, purchaseNumBg:getPositionY()), ap = display.RIGHT_CENTER})
    exhibitionBg:addChild(btn_minus)
    btn_minus:setTag(BUTTON_TAG.MINUS)
    actionBtns[tostring(BUTTON_TAG.MINUS)] = btn_minus

    --加号btn
    local btn_add = display.newButton(0, 0, {n = RES_DIR.PLUS})
    display.commonUIParams(btn_add, {po = cc.p(purchaseNumBg:getPositionX() + purchaseNumBgSize.width / 2 - 6, purchaseNumBg:getPositionY()), ap = display.LEFT_CENTER})
    exhibitionBg:addChild(btn_add)
    btn_add:setTag(BUTTON_TAG.ADD)
    actionBtns[tostring(BUTTON_TAG.ADD)] = btn_add

    local maxBtn = display.newButton(purchaseNumBg:getPositionX() + 115, purchaseNumBg:getPositionY(), {ap = display.LEFT_CENTER, n = RES_DIR.BTN_MAX_BG})
    display.commonLabelParams(maxBtn, fontWithColor(14, {text = __('最大')}))
    maxBtn:setTag(BUTTON_TAG.MAX)
    exhibitionBg:addChild(maxBtn)
    actionBtns[tostring(BUTTON_TAG.MAX)] = maxBtn

    local ownLabel = display.newLabel(exhibitionBgSize.width / 2, 25, {ap = display.RIGHT_CENTER, fontSize = 26, color = '#8b7666', text = __('拥有:')})
    exhibitionBg:addChild(ownLabel)

    local ownNumLabel = display.newLabel(exhibitionBgSize.width / 2, ownLabel:getPositionY(), {ap = display.LEFT_CENTER, fontSize = 26, color = '#BB4F07', text = 100})
    exhibitionBg:addChild(ownNumLabel)

    -- error tip
    local errorTip = display.newLabel(exhibitionBgSize.width / 2, ownLabel:getPositionY(), {ap = display.CENTER, fontSize = 26, color = '#BB4F07', text = 100})
    exhibitionBg:addChild(errorTip)
    errorTip:setVisible(false)

    -- 奖励预览
    local rewardPreviewLabel = display.newLabel(170, 150, fontWithColor(16, {text = __('奖励预览'), ap = display.RIGHT_CENTER}))
    parent:addChild(rewardPreviewLabel)

    local rewardLayer = display.newLayer(180, rewardPreviewLabel:getPositionY(), {ap = display.LEFT_CENTER, size = cc.size(bgSize.width - 200, 37)})
    parent:addChild(rewardLayer)

    local greenBtnLayerSize = cc.size(123, 109)
    local greenBtnLayer = display.newLayer(bgSize.width / 2 - 110, 109, {ap = display.CENTER_TOP, size = greenBtnLayerSize})
    parent:addChild(greenBtnLayer)

    local greenBtn = display.newButton(greenBtnLayerSize.width / 2, greenBtnLayerSize.height, {ap = display.CENTER_TOP, n = RES_DIR.BTN_GREEN})
    local greenBtnSize = greenBtn:getContentSize()
    greenBtn:setTag(BUTTON_TAG.FAST_COMPLETE)
    greenBtnLayer:addChild(greenBtn)
    actionBtns[tostring(BUTTON_TAG.FAST_COMPLETE)] = greenBtn

    local preparationNum = display.newRichLabel(greenBtnSize.width / 2, greenBtnSize.height / 2, {ap = display.CENTER, r = true, c= {
        fontWithColor('14',{text = "1"}) ,
        {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.15}
    }})
    greenBtn:addChild(preparationNum)

    local fastPreparation = display.newLabel(greenBtn:getPositionX(), greenBtnLayerSize.height - 80, fontWithColor(16, {ap = display.CENTER, text = __('快速筹备')}))
    greenBtnLayer:addChild(fastPreparation)

    local orangeBtn = display.newButton(bgSize.width / 2 + 110, 80, {ap = display.CENTER, n = RES_DIR.BTN_ORANGE})
    display.commonLabelParams(orangeBtn, fontWithColor(14, {text = __('筹备')}))
    orangeBtn:setTag(BUTTON_TAG.PAY)
    parent:addChild(orangeBtn)
    actionBtns[tostring(BUTTON_TAG.PAY)] = orangeBtn

    return {
        goodNode         = goodNode,
        gradeImg         = gradeImg,
        nameLabel        = nameLabel,
        progress         = progress,
        purchaseNum      = purchaseNum,
        ownLabel         = ownLabel,
        ownNumLabel      = ownNumLabel,
        errorTip         = errorTip,
        rewardLayer      = rewardLayer,
        preparationNum   = preparationNum,
        greenBtnLayer    = greenBtnLayer,
        fastPreparation  = fastPreparation,
        actionBtns       = actionBtns,

        bgSize           = bgSize,
    }
end

CreateFoodRewardById = function (goodsId, num)
    local bg = display.newImageView(RES_DIR.REWARD_BG, 0, 0)
    bg:setScale(0.9)

    local bgSize = bg:getContentSize()
    local reward = display.newImageView(CommonUtils.GetGoodsIconPathById(goodsId), 20, bgSize.height / 2, {ap = display.LEFT_CENTER})
    reward:setScale(0.2)
    bg:addChild(reward)

    local rewardSize = reward:getContentSize()
    local rewardNum = display.newLabel(reward:getPositionX() + rewardSize.width * 0.22, reward:getPositionY(), {fontSize = 22, color = '#bb4f07', text = checkint(num), ap = display.LEFT_CENTER})
    rewardNum:setName('rewardNum')
    bg:addChild(rewardNum)

    return bg
end

getFoodGradeDataByGrade = function (grade)
    grade = checkint(grade)
    local gradeData = {}
    for i,data in pairs(PARTY_FOOD_REWARD_CONF) do
        if checkint(data.grade) == grade then
            gradeData = data
            break
        end
    end
    return gradeData
end

function CommonBuyView:getCurData()
    return self.curData
end

return  CommonBuyView
