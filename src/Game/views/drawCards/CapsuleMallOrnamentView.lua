--[[
    抽卡Avatar部件 商店 view
--]]
local VIEW_SIZE = cc.size(838, 570)
local CapsuleMallOrnamentView = class('CapsuleMallOrnamentView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'drawCards.CapsuleMallOrnamentView'
    node:enableNodeEvents()
    return node
end)

local gameMgr = app.gameMgr
local AVATAR_RESTAURANT_CONF  = CommonUtils.GetConfigAllMess('avatar', 'restaurant') or {}

local RES_DICT = {
    SHOP_BTN_GOODS_DEFAULT = _res('ui/home/commonShop/shop_btn_goods_default.png'),
    SHOP_BTN_GOODS_SELLOUT = _res('ui/home/commonShop/shop_btn_goods_sellout.png'),
    COMMON_BG_GOODS        = _res('ui/common/common_bg_goods.png')
}

local CreateView = nil

function CapsuleMallOrnamentView:ctor( ... )
	local args = unpack({...}) or {}
    self:InitUI()
end
 
function CapsuleMallOrnamentView:InitUI()
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        display.commonUIParams(self.viewData.view, {ap = display.CENTER, po = utils.getLocalCenter(self)})
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end

function CapsuleMallOrnamentView:updateGridView(datas)
    local gridView = self:getViewData().gridView
    gridView:setCountOfCell(#datas)
    gridView:reloadData()
end

function CapsuleMallOrnamentView:updateCell(cell, data)
    

    cell.goodNode:RefreshSelf({goodsId = data.goodsId, amount = 1})

    local stockLabel = cell.stockLabel
    local numLabel = cell.numLabel
    local castIcon = cell.castIcon
    local ownNum         = gameMgr:GetAmountByIdForce(goodsId)
    local stock          = checkint(data.stock)
    local isLimitless   = checkint(data.leftPurchaseNum) == -1 or checkint(data.stock) == -1
    local isCanPurchase = (ownNum < stock) and (checkint(data.leftPurchaseNum) > 0 or isLimitless)
    -- 如果是无限制购买
    local bgImg = nil
    
    if isCanPurchase then
        bgImg = RES_DICT.SHOP_BTN_GOODS_DEFAULT
        display.commonLabelParams(numLabel, {text = data.price})
        castIcon:setTexture(CommonUtils.GetGoodsIconPathById(data.currency))
        castIcon:setPositionX(numLabel:getPositionX()+numLabel:getBoundingBox().width*0.5 + 4)
    else
        bgImg = RES_DICT.SHOP_BTN_GOODS_SELLOUT
    end

    numLabel:setVisible(isCanPurchase)
    castIcon:setVisible(isCanPurchase)
    cell.ownLabel:setVisible(not isCanPurchase)

    local toggleView = cell.toggleView
    toggleView:setNormalImage(bgImg)
    toggleView:setSelectedImage(bgImg)
end

CreateView = function (size)
    local view = display.newLayer(0,0,{size = size})

    local listBgSize = cc.size(832, 560)
    local listBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, size.width / 2, size.height / 2,
		{scale9 = true, size = listBgSize, ap = display.CENTER}
    )
    view:addChild(listBg)

    local cellSize = cc.size(208, 260)
    local gridView = CGridView:create(listBgSize)
    gridView:setPosition(cc.p(size.width/2 , size.height / 2))
    gridView:setSizeOfCell(cellSize)
    gridView:setAnchorPoint(display.CENTER)
    gridView:setColumns(4)
    view:addChild(gridView,2)

    return {
        view     = view,
        gridView = gridView,

    }
end

function CapsuleMallOrnamentView:getViewData()
    return self.viewData
end

return CapsuleMallOrnamentView
