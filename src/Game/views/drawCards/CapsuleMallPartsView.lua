--[[
    抽卡Avatar部件 商店 view
--]]
local VIEW_SIZE = cc.size(838, 570)
local CapsuleMallPartsView = class('CapsuleMallPartsView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'drawCards.CapsuleMallPartsView'
    node:enableNodeEvents()
    return node
end)

local gameMgr = app.gameMgr
local AVATAR_RESTAURANT_CONF  = CommonUtils.GetConfigAllMess('avatar', 'restaurant') or {}
local AVATAR_ANIMATION_CONF = CommonUtils.GetConfigAllMess('avatarAnimation', 'restaurant') or {}
local AVATAR_LOCATION_CONF = CommonUtils.GetConfigAllMess('avatarLocation', 'restaurant') or {}

local RES_DICT = {
    SHOP_BTN_GOODS_DEFAULT = _res('ui/home/commonShop/shop_btn_goods_default.png'),
    SHOP_BTN_GOODS_SELLOUT = _res('ui/home/commonShop/shop_btn_goods_sellout.png'),
    COMMON_BG_GOODS        = _res('ui/common/common_bg_goods.png')
}

local CreateView = nil

function CapsuleMallPartsView:ctor( ... )
	local args = unpack({...}) or {}
    self:InitUI()
end
 
function CapsuleMallPartsView:InitUI()
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        display.commonUIParams(self.viewData.view, {ap = display.CENTER, po = utils.getLocalCenter(self)})
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end

function CapsuleMallPartsView:updateGridView(datas)
    local gridView = self:getViewData().gridView
    gridView:setCountOfCell(#datas)
    gridView:reloadData()
end

function CapsuleMallPartsView:updateCell(cell, data)
    local layer = cell:getChildByName('layer')
    if layer == nil then return end

    local goodsId     = data.goodsId

    local bg          = layer.bg
    local priceNum    = layer.priceNum
    local castIcon    = layer.castIcon
    local priceLayer  = layer.priceLayer
    local alreadyOwnedLabel = layer.alreadyOwnedLabel

    local restaurantLevel = checkint(gameMgr:GetUserInfo().restaurantLevel)
    local conf = AVATAR_RESTAURANT_CONF[tostring(goodsId)] or {}
    local openRestaurantLevel = checkint(conf.openRestaurantLevel)
    local isUnLock       = restaurantLevel >= openRestaurantLevel
    local ownNum         = gameMgr:GetAmountByIdForce(goodsId)
    local stock          = checkint(data.stock)
    --                     拥有数小于库存数 并且 （有剩余购买次数 或者 能无限购买）
    local isCanPurchase  = (ownNum < stock) and (checkint(data.leftPurchaseNum) > 0 or checkint(data.leftPurchaseNum) == -1)

    local isShowUnlockState = isUnLock and isCanPurchase
    priceLayer:setVisible(isShowUnlockState)

    local alreadyOwnedText = nil
    if not isUnLock then
        alreadyOwnedText = string.fmt(__('餐厅_num_级解锁'),{_num_ = openRestaurantLevel})
    else
        alreadyOwnedText = __('已拥有')
    end
    display.commonLabelParams(alreadyOwnedLabel, {text = alreadyOwnedText})
    alreadyOwnedLabel:setVisible(not isUnLock or not isCanPurchase)

    local bgImg = isShowUnlockState and RES_DICT.SHOP_BTN_GOODS_DEFAULT or RES_DICT.SHOP_BTN_GOODS_SELLOUT
    bg:setTexture(bgImg)

    local centerPosX  = layer.centerPosX
    local centerPosY  = layer.centerPosY
    if isShowUnlockState then
        local price       = checknumber(data.price)
        priceNum:setString(price)
        priceNum:setVisible(true)
    
        local currency    = data.currency
        castIcon:setTexture(CommonUtils.GetGoodsIconPathById(currency))
        castIcon:setVisible(true)
        
        local priceNumSize = priceNum:getContentSize()
        local castIconSize = castIcon:getContentSize()
        priceNum:setPositionX(centerPosX - castIcon:getScale() * castIconSize.width / 2 - 2)
        castIcon:setPositionX(centerPosX + priceNumSize.width / 2 - 2)
    end
    
    local goodsImg = layer.goodsImg
    goodsImg:setVisible(true)
    goodsImg:setTexture(AssetsUtils.GetRestaurantSmallAvatarPath(goodsId))

    local locationConf = AVATAR_LOCATION_CONF[tostring(goodsId)] or {}
    layer.dynamicAvatarTipIcon:setVisible(AVATAR_ANIMATION_CONF[tostring(goodsId)] ~= nil or string.len(checkstr(locationConf.particle)) > 0)
end

CreateView = function (size)
    local view = display.newLayer(0,0,{size = size})

    local listBgSize = cc.size(832, 560)
    local listBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, size.width / 2, size.height / 2,
		{scale9 = true, size = listBgSize, ap = display.CENTER}
    )
    view:addChild(listBg)

    local cellSize = cc.size(208, 300)
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

function CapsuleMallPartsView:getViewData()
    return self.viewData
end

return CapsuleMallPartsView
