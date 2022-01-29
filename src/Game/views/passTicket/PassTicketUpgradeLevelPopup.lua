--[[
 * descpt : pass ticket 购买弹窗 界面
]]
local VIEW_SIZE = display.size
---@class PassTicketUpgradeLevelPopup :CLayout
local PassTicketUpgradeLevelPopup = class("PassTicketUpgradeLevelPopup", function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'passTicket.PassTicketUpgradeLevelPopup'
	node:enableNodeEvents()
	return node
end)

local CreateView = nil

local RES_DICT = {
    COMMON_BTN_ORANGE          = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_WHITE_DEFAULT   = _res('ui/common/common_btn_white_default.png'),
    LEVEL_UP_TEXT              = _res('ui/home/lobby/information/restaurant_ico_level_up.png'),
    COOKING_LEVEL_UP_ICO_ARROW = _res('ui/home/kitchen/cooking_level_up_ico_arrow.png'),
    COMMON_LIGHT               = _res('ui/common/common_light.png')
}

function PassTicketUpgradeLevelPopup:ctor( ... ) 
    self.args = app.passTicketMgr:GetUpgradeData()
    self:initialUI()
end

function PassTicketUpgradeLevelPopup:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)

        self:initView()
	end, __G__TRACKBACK__)
end

function PassTicketUpgradeLevelPopup:initView()
    local viewData = self:getViewData()
    display.commonUIParams(viewData.quitBtn, {cb = handler(self, self.onClickQuitAction)})
    display.commonUIParams(viewData.goBtn, {cb = handler(self, self.onClickGoAction)})

    local newLevel = checkint(self.args.newLevel)
    local oldLvLabel  = viewData.oldLvLabel
    display.commonLabelParams(viewData.oldLvLabel, {text = string.fmt(__('lv._num_'), {_num_ = checkint(self.args.oldLevel) - 1})})
    local newLvLabel  = viewData.newLvLabel
    local newLevelText = newLevel == 0 and 'max' or (newLevel - 1)
    display.commonLabelParams(viewData.newLvLabel, {text = string.fmt(__('lv._num_'), {_num_ = newLevelText})})
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local centerPosX, centerPosY = size.width / 2, size.height / 2

    local shadowLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(shadowLayer)

    local levelUpTextImage = display.newNSprite(RES_DICT.LEVEL_UP_TEXT, centerPosX, centerPosY + 200)
    view:addChild(levelUpTextImage, 1)

    local lightImg = display.newNSprite(RES_DICT.COMMON_LIGHT,centerPosX, centerPosY + 50)
    lightImg:setScale(0.5)
    view:addChild(lightImg)

    local goodsIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(900024), centerPosX, centerPosY + 50)
    view:addChild(goodsIcon)

    local oldLvLabel = display.newLabel(centerPosX - 50, centerPosY - 70, fontWithColor(12, {fontSize = 30, ap = display.RIGHT_CENTER}))
    view:addChild(oldLvLabel)

    local maxCount = 4
    for i = 1, maxCount do
        local pos = CommonUtils.getGoodPos({index = i, goodNodeSize = cc.size(15, 21), midPointX = centerPosX, midPointY = oldLvLabel:getPositionY(), col = maxCount, maxCol = maxCount, goodGap = 0})
        local arrowImg = display.newNSprite(RES_DICT.COOKING_LEVEL_UP_ICO_ARROW, pos.x, pos.y, {ap = display.CENTER})
        view:addChild(arrowImg)
    end

    local newLvLabel = display.newLabel(centerPosX + 50, centerPosY - 70, fontWithColor(12, {fontSize = 30, ap = display.LEFT_CENTER}))
    view:addChild(newLvLabel)

    local quitBtn = display.newButton(centerPosX - 110, centerPosY - 170, {n = RES_DICT.COMMON_BTN_WHITE_DEFAULT})
	display.commonLabelParams(quitBtn, fontWithColor('14', {text = __('等会再说')}))
	view:addChild(quitBtn)
    
    local goBtn = display.newButton(centerPosX + 110, centerPosY - 170, {n = RES_DICT.COMMON_BTN_ORANGE})
	display.commonLabelParams(goBtn, fontWithColor('14', {text = __('前往领奖')}))
	view:addChild(goBtn)

   return {
        view        = view,
        shadowLayer = shadowLayer,
        quitBtn     = quitBtn,
        goBtn       = goBtn,
        oldLvLabel  = oldLvLabel,
        newLvLabel  = newLvLabel,
   }
end

function PassTicketUpgradeLevelPopup:onClickQuitAction(sender)
    self:closeView()
end

function PassTicketUpgradeLevelPopup:onClickGoAction(sender)
    local mediator = require("Game.mediator.passTicket.PassTicketMediator").new({activityId = checktable(app.passTicketMgr:GetHomeData().requestData).activityId})
	app:RegistMediator(mediator)
    self:closeView()
end

function PassTicketUpgradeLevelPopup:closeView()
    -- clear UpgradeData 
    app.passTicketMgr:SetUpgradeData()
    self:setVisible(false)
    self:runAction(cc.RemoveSelf:create())
end

function PassTicketUpgradeLevelPopup:getViewData()
	return self.viewData_
end

return PassTicketUpgradeLevelPopup