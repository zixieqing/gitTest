--[[
    燃战黑店界面
--]]
local GameScene = require( "Frame.GameScene" )
---@class SaiMoeShopView :GameScene
local SaiMoeShopView = class("SaiMoeShopView", GameScene)
local shareFacade = AppFacade.GetInstance()
local gameMgr = app.gameMgr
local uiMgr = app.uiMgr
local GoodNode = require('common.GoodNode')

local RES_DICT          = {
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_WHITE_DEFAULT        = _res('ui/common/common_btn_white_default.png'),
    MAIN_BG_MONEY                   = _res('ui/home/nmain/main_bg_money'),
    STARPLAN_SHOP_BG_BELOW          = _res('ui/home/activity/saimoe/starplan_shop_bg_below.png'),
    STARPLAN_SHOP_BG_DESK           = _res('ui/home/activity/saimoe/starplan_shop_bg_desk.png'),
    STARPLAN_SHOP_LABEL_BOSSTALK    = _res('ui/home/activity/saimoe/starplan_shop_label_bosstalk.png'),
    STARPLAN_SHOP_LABEL_SHOPNAME    = _res('ui/home/activity/saimoe/starplan_shop_label_shopname.png'),
}

function SaiMoeShopView:ctor( ... )
	GameScene.ctor(self, 'Game.views.saimoe.SaiMoeShopView')
	self.datas = unpack({...}) or {}

	self:InitUI()
end

function SaiMoeShopView:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 180))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    
	local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        view:setName('SaiMoeShopView')
        self:addChild(view)

        local drawNode = require('common.CardSkinDrawNode').new({
            confId = 301218,
            coordinateType = COORDINATE_TYPE_CAPSULE
        })
        drawNode:setPosition(display.cx, display.cy)
        view:addChild(drawNode)

        local rockImg = display.newImageView(RES_DICT.STARPLAN_SHOP_BG_DESK, display.cx - 7, 113,
        {
            ap = display.CENTER,
        })
        view:addChild(rockImg)

        local tableImg = display.newImageView(RES_DICT.STARPLAN_SHOP_BG_BELOW, display.cx - -1, 71,
        {
            ap = display.CENTER,
        })
        view:addChild(tableImg)

        local temporaryLeaveBtn = display.newButton(display.cx - 161, 38,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_WHITE_DEFAULT,
            enable = true,scale9 = true
        })
        display.commonLabelParams(temporaryLeaveBtn, fontWithColor(14, {text = __('暂时离开'), paddingW = 20 , fontSize = 24, color = '#ffffff'}))
        view:addChild(temporaryLeaveBtn)

        local permanentLeaveBtn = display.newButton(display.cx - -167, 37,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,scale9 = true
        })
        display.commonLabelParams(permanentLeaveBtn, fontWithColor(14, {text = __('不买了'), paddingW = 20,  fontSize = 24, color = '#ffffff'}))
        view:addChild(permanentLeaveBtn)

        local shopContent = CommonUtils.GetConfigAllMess('shopContent', 'cardComparison')
        local nameLabel = display.newButton(display.cx - -5, 102,
        {
            ap = display.CENTER,
            n = RES_DICT.STARPLAN_SHOP_LABEL_SHOPNAME,
            enable = false,
        })
        display.commonLabelParams(nameLabel, fontWithColor(14, {text = shopContent['1'].name, fontSize = 28, color = '#ffc254'}))
        view:addChild(nameLabel)

        local desrLabel = display.newButton(display.cx - -14, 151,
        {
            ap = display.CENTER,
            n = RES_DICT.STARPLAN_SHOP_LABEL_BOSSTALK,
            enable = true,
        })
        display.commonLabelParams(desrLabel, {text = shopContent['1'].message, fontSize = 22, color = '#ffffff'})
        view:addChild(desrLabel)

        local GoodPurchaseNode = require('common.GoodPurchaseNode')
        -- top icon
        local currencyBG = display.newImageView(RES_DICT.MAIN_BG_MONEY,0,0,{enable = false, scale9 = true, size = cc.size(480 + (display.width - display.SAFE_R),54)})
        display.commonUIParams(currencyBG,{ap = cc.p(1.0,1.0), po = cc.p(display.width, display.height)})
        view:addChild(currencyBG)

        local currency = { GOLD_ID, DIAMOND_ID }
        local moneyNodes = {}
        for i,v in ipairs(currency) do
            local purchaseNode = GoodPurchaseNode.new({id = v, animate = false, datas = self.datas})
            purchaseNode:updataUi(checkint(v))
            display.commonUIParams(purchaseNode,
                    {ap = cc.p(1, 0.5), po = cc.p(display.SAFE_R - 20 - (( #currency - i) * (purchaseNode:getContentSize().width + 16)), currencyBG:getPositionY()- 26)})
            view:addChild(purchaseNode, 5)
            purchaseNode:setName('purchaseNode' .. i)
            purchaseNode.viewData.touchBg:setTag(checkint(v))
            moneyNodes[tostring( v )] = purchaseNode
        end

		return {
            view                    = view,
            drawNode                = drawNode,
            rockImg                 = rockImg,
            tableImg                = tableImg,
            temporaryLeaveBtn       = temporaryLeaveBtn,
            permanentLeaveBtn       = permanentLeaveBtn,
            nameLabel               = nameLabel,
            desrLabel               = desrLabel,
            moneyNodes              = moneyNodes,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
    
	end, __G__TRACKBACK__)
end

return SaiMoeShopView