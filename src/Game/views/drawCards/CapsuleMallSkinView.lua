--[[
    抽卡皮肤商店 view
--]]
local VIEW_SIZE = cc.size(838, 570)
---@class CapsuleMallSkinView
local CapsuleMallSkinView = class('CapsuleMallSkinView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'drawCards.CapsuleMallSkinView'
    node:enableNodeEvents()
    return node
end)

local cardMgr = app.cardMgr

local RES_DICT = {
    COMMON_BG_GOODS = _res('ui/common/common_bg_goods.png')
}

local CreateView = nil

function CapsuleMallSkinView:ctor( ... )
	local args = unpack({...}) or {}
    self:InitUI()
end

function CapsuleMallSkinView:updateGridView(datas)
    local gridView = self:getViewData().gridView
    gridView:setCountOfCell(#datas)
    gridView:reloadData()
end

function CapsuleMallSkinView:updateCell(cell, data)
    if data == nil then return end
    local skinId    = checkint(data.goodsId)
    local skinConf  = CardUtils.GetCardSkinConfig(skinId) or {}
    local cardConf  = CardUtils.GetCardConfig(skinConf.cardId) or {}
    self:updateImgHero(cell, skinId, skinConf, cardConf)

    cell.skinNameLabel:setString(tostring(skinConf.name))
    display.commonLabelParams(cell.skinNameLabel, {text = tostring(skinConf.name) ,w = 180 , reqH = 55 , hAlign = display.TAC})
    cell.cardNameLabel:setString(tostring(cardConf.name))

    self:updatePriceRichLabel(cell, data)

    local height = cell.bottomSize.height -20
    local bottonHeight = 20
    cell.isHasLabel:setVisible(false)
    cell.isHasImg:setVisible(false)
    if cardMgr.IsHaveCardSkin(skinId) then
        cell.priceRichLabel:setVisible(false)
        cell.isHasImg:setVisible(true)
        cell.isHasLabel:setVisible(true)
        cell.cardNameLabel:setPositionY(height / 2 + bottonHeight)
        cell.skinNameLabel:setPositionY(height / 3 * 2.5 + bottonHeight)
        cell.isHasLabel:setPositionY(height / 3 * 0.5 + bottonHeight)
    elseif checkint(data.discount) < 100 and checkint(data.discount) > 0 then
        cell.cardNameLabel:setPositionY(cell.bottomSize.height / 4 * 2.5 )
        cell.skinNameLabel:setPositionY(cell.bottomSize.height / 4 * 3.5 )
        cell.priceRichLabel:setPositionY(cell.bottomSize.height / 4 * 0.5 )
        cell.discountLayout:setPositionY(cell.bottomSize.height / 4 * 1.5)
        cell.discountLayout:setVisible(true)
        cell.priceRichLabel:setVisible(true)
    else
        cell.cardNameLabel:setPositionY(cell.bottomSize.height / 2 )
        cell.skinNameLabel:setPositionY(cell.bottomSize.height / 3 * 2.5 )
        cell.priceRichLabel:setPositionY(cell.bottomSize.height / 3 * 0.5 )
        cell.priceRichLabel:setVisible(true)
    end
end

function CapsuleMallSkinView:updateImgHero(cell, skinId, skinConf, cardConf)
    local imgHero = cell.imgHero
    local imgBg   = cell.imgBg
    local drawPath = CardUtils.GetCardDrawPathBySkinId(skinId)
    imgHero:setTexture(drawPath)
    
    local cardDrawName = ""
    if skinConf then
        cardDrawName = skinConf.photoId
    end
    local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardDrawName)
    if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
        print('\n**************\n', '立绘坐标信息未找到', cardDrawName, '\n**************\n')
        locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
    else
        locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
    end
    imgHero:setScale(locationInfo.scale/100)
    imgHero:setRotation((locationInfo.rotate))
    imgHero:setPosition(cc.p(locationInfo.x ,(-1)*(locationInfo.y-540) - 148))
    
    local qualityId = cardConf.qualityId
    imgBg:setTexture(CardUtils.GetCardTeamBgPathBySkinId(skinId))
end

function CapsuleMallSkinView:updatePriceRichLabel(cell, data)
    local currency = data.currency
    local price    = data.price
    local cData    = {}
    
    if price then
        table.insert(cData, fontWithColor('14' , {text = price, fontSize = 22}))
    end
    if currency then
        table.insert(cData, {img = CommonUtils.GetGoodsIconPathById(currency), scale = 0.2})
    end
    local priceRichLabel = cell.priceRichLabel
    if next(cData)  then
        display.reloadRichLabel(priceRichLabel, {
            c = cData
        })
    end

    local rect = priceRichLabel:getBoundingBox()
    local contentSize = priceRichLabel:getContentSize()
    local standerWidth = 180
    if rect.width  > standerWidth then
        priceRichLabel:setScale(standerWidth/contentSize.width)
    end

    CommonUtils.AddRichLabelTraceEffect(priceRichLabel)
end

function CapsuleMallSkinView:InitUI()
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        display.commonUIParams(self.viewData.view, {ap = display.CENTER, po = utils.getLocalCenter(self)})
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end

CreateView = function (size)
    local view = display.newLayer(0,0,{size = size})

    local listBgSize = cc.size(832, 560)
    local listBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, size.width / 2, size.height / 2,
		{scale9 = true, size = listBgSize, ap = display.CENTER}
    )
    view:addChild(listBg)

    local taskListCellSize = cc.size(206, 420)
    local gridView = CGridView:create(listBgSize)
    gridView:setPosition(cc.p(size.width/2 , size.height / 2))
    gridView:setSizeOfCell(taskListCellSize)
    gridView:setAnchorPoint(display.CENTER)
    gridView:setColumns(4)
    --gridView:setAutoRelocate(true)
    view:addChild(gridView,2)

    return {
        view     = view,
        gridView = gridView,
    }
end

function CapsuleMallSkinView:getViewData()
    return self.viewData
end

return CapsuleMallSkinView
