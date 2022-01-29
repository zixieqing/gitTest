--[[
飨灵投票初赛入口view
--]]
local VIEW_SIZE = cc.size(1035, 637)
local ActivityCardMatchPageView = class('ActivitCardMatchPageView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'Game.views.activity.luckNumber.ActivitCardMatchPageView'
    node:enableNodeEvents()
    return node
end)

local CreateView     = nil
local CreateNumCell  = nil
local CreateGoodNode = nil

local display = display

local RES_DICT = {
    COMMON_BTN_ORANGE        = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_DRAWN         = _res('ui/common/activity_mifan_by_ico.png'),
    COMMON_TITLE_3           = _res("ui/common/common_title_3.png"),
    COMMON_BTN_WHITE_DEFAULT = _res('ui/common/common_btn_white_default.png'),
    CARDMATCH_TICKET_BG      = _res('ui/home/activity/cardMatch/cardmatch_ticket_bg.png'),
    CARDMATCH_RECEIVE_BG     = _res('ui/home/activity/cardMatch/cardmatch_receive_bg.png'),
}

function ActivityCardMatchPageView:ctor( ... )
    self.args = unpack({...}) or {}

    self:InitUI()
end
--[[
init ui
--]]
function ActivityCardMatchPageView:InitUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE, self.args)
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
    
end

---UpdateCountDown
---更新倒计时
---@param leftSeconds number 剩余时间
---@param timeDesc string    时间描述
function ActivityCardMatchPageView:UpdateCountDown(leftSeconds, timeDesc)
    local viewData          = self:GetViewData()
    local baseLayer         = viewData.baseLayer
    
    baseLayer.viewData_.timeLabel:setString(CommonUtils.getTimeFormatByType(leftSeconds))
end

---UpdateGoodNode
---@param viewData table 视图数据
---@param data table 选票信息
function ActivityCardMatchPageView:UpdateGoodNode(viewData, data)
    local goodNode = viewData.goodNode
    goodNode:setVisible(true)
    goodNode:RefreshSelf({
        goodsId = data.voteGoodsId,
        amount = data.voteDailyGet,
    })
end

---UpdateReceiveBtn
---更新领取按钮
---@param viewData table 视图数据
---@param data table 选票信息
function ActivityCardMatchPageView:UpdateReceiveBtn(viewData, data)
    local receiveBtn = viewData.receiveBtn
    local receivedLabel = viewData.receivedLabel
    local isReceive = checkint(data.hasPicked) > 0
    receiveBtn:setVisible(true)
    receivedLabel:setVisible(isReceive)
    receiveBtn:getLabel():setVisible(not isReceive)
    local img = isReceive and RES_DICT.COMMON_BTN_DRAWN or RES_DICT.COMMON_BTN_WHITE_DEFAULT
    receiveBtn:setNormalImage(img)
    receiveBtn:setSelectedImage(img)
end

CreateView = function (size, data)
    local view = CLayout:create(size)
    view:setAnchorPoint(cc.p(0,0))
    view:setPosition(cc.p(0,0))
    
    local baseLayer = require("Game.views.ActivityCommonView").new({
        showBtn = false,
        bgImageURL = data.backgroundImage[i18n.getLang()],
		timeText = CommonUtils.getTimeFormatByType(data.leftSeconds),
        ruleText = data.detail[i18n.getLang()]
    })
    display.commonUIParams(baseLayer, {po = cc.p(0,0), ap = display.LEFT_BOTTOM})
    view:addChild(baseLayer)
    
    local receiveLayerSize = cc.size(307, 270)
    local middleX, middleY = receiveLayerSize.width * 0.5, receiveLayerSize.height * 0.5
    local receiveLayer = display.newLayer(size.width - 150, size.height - 100, {size = receiveLayerSize, ap = display.RIGHT_TOP})
    view:addChild(receiveLayer)

    local receiveBg = display.newNSprite(RES_DICT.CARDMATCH_RECEIVE_BG, middleX, middleY)
    receiveLayer:addChild(receiveBg)

    local receiveTip = display.newButton(middleX, receiveLayerSize.height - 30, {n = RES_DICT.COMMON_TITLE_3, animate = false, enable = false})
    display.commonLabelParams(receiveTip, {fontSize = 20, color = '#5b3c25', text = __('领取投票券')})
    receiveLayer:addChild(receiveTip)

    local goodsBg = display.newNSprite(RES_DICT.CARDMATCH_TICKET_BG, middleX, middleY + 10)
    receiveLayer:addChild(goodsBg)
    
    local goodNode = require('common.GoodNode').new({
        showAmount = true,
        --highlight = 1,
        callBack = function (sender)
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        end
    })
    -- goodNode:setScale(0.9)
    display.commonUIParams(goodNode, {ap = display.CENTER, po = cc.p(goodsBg:getPositionX(), goodsBg:getPositionY() + 1)})
    receiveLayer:addChild(goodNode)
    goodNode:setVisible(false)

    -- 领取按钮
    local receiveBtn = display.newButton(middleX, 40, {n = RES_DICT.COMMON_BTN_WHITE_DEFAULT, ap = display.CENTER})
    display.commonLabelParams(receiveBtn, fontWithColor(14, {text = __('领取')}))
    receiveLayer:addChild(receiveBtn)
    receiveBtn:setVisible(false)

    local receivedLabel = display.newLabel(0, 0, fontWithColor(7, {fontSize = 24, text = __('已领取')}))
    display.commonUIParams(receivedLabel, {po = utils.getLocalCenter(receiveBtn), ap = display.CENTER})
    receiveBtn:addChild(receivedLabel, 5)
    receivedLabel:setVisible(false)

    local enterBtn = display.newButton(size.width - 90, 210, {n = RES_DICT.COMMON_BTN_ORANGE})
    display.commonLabelParams(enterBtn, fontWithColor('14', {text = __('去投票')}))
    view:addChild(enterBtn)

    return {
        view          = view,
        baseLayer     = baseLayer,
        goodNode      = goodNode,
        receiveBtn    = receiveBtn,
        receivedLabel = receivedLabel,
        enterBtn      = enterBtn,
    }
end

function ActivityCardMatchPageView:GetViewData()
    return self.viewData_
end

return ActivityCardMatchPageView