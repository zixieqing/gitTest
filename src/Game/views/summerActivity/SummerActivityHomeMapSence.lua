--[[
活动副本地图的界面
@params table {
}
--]]
local GameScene = require('Frame.GameScene')
local SummerActivityHomeMapSence = class('SummerActivityHomeMapSence', GameScene)
local GoodPurchaseNode = require('common.GoodPurchaseNode')

local CreateView           = nil

local summerActMgr = app.summerActMgr

local RES_DIR = {
    BTN_BACK        = _res('ui/common/common_btn_back.png'),
    TITLE_BAR       = _res('ui/common/common_title_new.png'),
    BTN_TIPS        = _res('ui/common/common_btn_tips.png'),
}

local BUTTON_TAG = {
    BACK   = 100,
    RULE   = 101,
}

function SummerActivityHomeMapSence:ctor( )
	self.viewData_ = nil
	self:initUI()
end

function SummerActivityHomeMapSence:initUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
        
        self:CreateTopLayout()

        self:CreateMoneyNodeLayout()
	end, __G__TRACKBACK__)
end

--更新顶部货币数量
function SummerActivityHomeMapSence:UpdateCountUI()
    local viewData  = self:getViewData()
    local moneyNods = viewData.moneyNods
	if moneyNods then
		for id, v in pairs(moneyNods) do
			v:updataUi(checkint(id)) --刷新每一个货币数量
		end
	end
end

function SummerActivityHomeMapSence:CreateTopLayout()
    local size = cc.size(display.width, 80)
    local topLayer = display.newLayer(display.cx, display.height, {ap = display.CENTER_TOP, size = size})
    self:addChild(topLayer, GameSceneTag.Dialog_GameSceneTag)

    local actionBtns = self.viewData_.actionBtns

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DIR.TITLE_BAR, ap = display.LEFT_TOP, enable = true, scale9 = true, capInsets = cc.rect(100, 70, 80, 1)})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = summerActMgr:getThemeTextByText(__('恐怖游乐园')), reqW = 180, offset = cc.p(-10, -10), ttf = false}))
    actionBtns[tostring(BUTTON_TAG.RULE)] = titleBtn
    topLayer:addChild(titleBtn)

    local titleSize = titleBtn:getContentSize()
    local tipsIcon  = display.newImageView(_res(RES_DIR.BTN_TIPS), titleSize.width - 50, titleSize.height/2 - 10)
    titleBtn:addChild(tipsIcon)

end

function SummerActivityHomeMapSence:CreateMoneyNodeLayout(parent)
    -- 重写顶部状态条
    local topLayoutSize = cc.size(display.width, 80)
    local moneyNodeLayout = CLayout:create(topLayoutSize)
    moneyNodeLayout:setName('TOP_LAYOUT')
    display.commonUIParams(moneyNodeLayout, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
    self:addChild(moneyNodeLayout, GameSceneTag.Dialog_GameSceneTag)

    -- top icon
    local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),0, 0, {enable = false,
    scale9 = true, size = cc.size(680 + (display.width - display.SAFE_R), 54)})
    display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
    moneyNodeLayout:addChild(imageImage)

    local moneyNods = {}
    local iconData = {app.summerActMgr:getTicketId(), GOLD_ID, DIAMOND_ID}
    for i,v in ipairs(iconData) do
        local purchaseNode = GoodPurchaseNode.new({id = v})
        display.commonUIParams(purchaseNode,
        {ap = cc.p(1, 0.5), po = cc.p(topLayoutSize.width - 30 - (( 3 - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
        moneyNodeLayout:addChild(purchaseNode, 5)
        purchaseNode:setName('purchaseNode' .. i)
        purchaseNode.viewData.touchBg:setTag(checkint(v))
        moneyNods[tostring( v )] = purchaseNode
    end

    self.viewData_.moneyNods = moneyNods
    return moneyNods
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    local actionBtns      = {}
    -------------------------------------------------
    -- top layer
    local topLayer = display.newLayer()
    view:addChild(topLayer, 1)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DIR.BTN_BACK})
    actionBtns[tostring(BUTTON_TAG.BACK)] = backBtn
    topLayer:addChild(backBtn)

    

    

    local contentLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER})
    view:addChild(contentLayer)
    
    return {
        view            = view,
        actionBtns      = actionBtns,
        contentLayer    = contentLayer,
    }
end


function SummerActivityHomeMapSence:getViewData()
    return self.viewData_
end

return SummerActivityHomeMapSence