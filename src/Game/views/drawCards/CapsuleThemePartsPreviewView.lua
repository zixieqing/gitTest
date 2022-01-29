--[[
    抽卡主题预览 view
--]]
local VIEW_SIZE = display.size
local CapsuleThemePartsPreviewView = class('CapsuleThemePartsPreviewView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'drawCards.CapsuleThemePartsPreviewView'
    node:enableNodeEvents()
    return node
end)

local RES_DICT = {
    COMMON_BG_4                     = _res('ui/common/common_bg_4.png'),
    COMMON_TITLE_5                  = _res('ui/common/common_title_5.png'),
    SUMMON_SHOP_PREVIEW_BG_GOODS    = _res('ui/home/capsuleNew/skinCapsule/shop/summon_shop_preview_bg_goods.png'),
}

local BUTTON_TAG = {
    PARTS_PREVIEW   = 100,
    RIGHT           = 101,
    LEFT            = 102,
    BUY             = 103,
}

local AVATAR_RESTAURANT_CONF  = CommonUtils.GetConfigAllMess('avatar', 'restaurant') or {}
local AVATAR_THEME_PARTS_CONF = CommonUtils.GetConfigAllMess('avatarThemeParts', 'restaurant') or {}

local CreateView = nil
local CreateCell = nil

function CapsuleThemePartsPreviewView:ctor( ... )
	local args = unpack({...}) or {}
    self:InitUI()
    self:RereshUI(args)
end
 
function CapsuleThemePartsPreviewView:InitUI()
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        display.commonUIParams(self.viewData.view, {ap = display.CENTER, po = utils.getLocalCenter(self)})
        self:addChild(self.viewData.view, 1)
        self:InitView()
	end, __G__TRACKBACK__)
end

function CapsuleThemePartsPreviewView:InitView()
    local viewData = self:GetViewData()

    display.commonUIParams(viewData.shadowLayer, {cb = handler(self, self.onClickShadowAction), animate = false})

    viewData.gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnListDataAdapter))
end

function CapsuleThemePartsPreviewView:InitDataByThemeId(themeId)
    local datas = {}
    local avatarThemeParts = AVATAR_THEME_PARTS_CONF[tostring(themeId)] or {}
    -- 获取map格式的背包数据
    local backpackMap = app.gameMgr:GetBackPackArrayToMap()

    for avatarId, avatarNum in pairs(avatarThemeParts) do
        local avatarConf = AVATAR_RESTAURANT_CONF[tostring(avatarId)] or {}
        local tempData = backpackMap[tostring(avatarId)] or {}
        local ownNum   = checkint(tempData.amount)
        local deltaNum = checkint(avatarNum) - ownNum
        table.insert(datas, {
            avatarId   = avatarId,
            avatarNum  = avatarNum,
            isOwn      = deltaNum <= 0
        })
    end
    return datas
end

function CapsuleThemePartsPreviewView:RereshUI(args)
    self.datas = {}
    self.datas = self:InitDataByThemeId(args.themeId)

    local viewData = self:GetViewData()
    local gridView = viewData.gridView
    gridView:setCountOfCell(#self.datas)
    gridView:reloadData()
    
end

function CapsuleThemePartsPreviewView:OnListDataAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local gridView = self:GetViewData().gridView
        pCell = CreateCell(gridView:getSizeOfCell())
    end

    xTry(function()
        local viewData = pCell.viewData
        
        local data = self.datas[index] or {}
        local avatarId = data.avatarId
        if avatarId then
            viewData.themePart:setTexture(AssetsUtils.GetRestaurantSmallAvatarPath(avatarId))
        end

        local avatarNum = data.avatarNum
        if avatarNum then
            display.commonLabelParams(viewData.numLabel, {text = string.format("x%d", avatarNum)})
        end

        local isOwn = data.isOwn
        local alreadyOwnedLabel = viewData.alreadyOwnedLabel
        alreadyOwnedLabel:setVisible(isOwn)

        local cellBg = viewData.cellBg
        if isOwn then
            cellBg:setFilter(filter.newFilter('GRAY'))
        else
            cellBg:clearFilter()
        end

    end,__G__TRACKBACK__)
    return pCell
end

function CapsuleThemePartsPreviewView:onClickShadowAction()
    self:setVisible(false)
    self:runAction(cc.RemoveSelf:create())
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})
    
    local shadowLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,130), enable = true})
    view:addChild(shadowLayer)

    local bgLayerSize = cc.size(682, 376)
    local bgLayer = display.newLayer(display.cx - 24, display.cy - 14,
    {
        ap = display.CENTER,
        size = bgLayerSize,
    })
    view:addChild(bgLayer)

    bgLayer:addChild(display.newLayer(0,0,{size = bgLayerSize, color = cc.c4b(0,0,0,0), enable = true}))

    local bg = display.newImageView(RES_DICT.COMMON_BG_4, 0, 0,
    {
        ap = display.LEFT_BOTTOM,
        scale9 = true, size = cc.size(682, 376),
    })
    bgLayer:addChild(bg)

    local title = display.newButton(347, 349,
    {
        ap = display.CENTER,
        n = RES_DICT.COMMON_TITLE_5,
        scale9 = true, size = cc.size(186, 31),
        enable = false,
    })
    display.commonLabelParams(title, {text = __('预览'), fontSize = 22, color = '#5b3c25'})
    bgLayer:addChild(title)

    local gridView = CGridView:create(cc.size(660, 325))
    gridView:setSizeOfCell(cc.size(110, 100))
    gridView:setColumns(6)
    gridView:setPosition(cc.p(344, 334))
    gridView:setAnchorPoint(display.CENTER_TOP)
    gridView:setDirection(eScrollViewDirectionVertical)
    bgLayer:addChild(gridView)
    
    return {
        view            = view,
        shadowLayer     = shadowLayer,
        gridView        = gridView,
    }
end

CreateCell = function (size)
    local cell = CGridViewCell:new()
    cell:setContentSize(size)

    local bgLayer = display.newLayer(size.width / 2, size.height / 2,
    {
        ap = display.CENTER,
        -- color = cc.c4b(0,0,0,130),
        size = cc.size(90, 90),
    })
    cell:addChild(bgLayer)

    local cellBg = FilteredSpriteWithOne:create(RES_DICT.SUMMON_SHOP_PREVIEW_BG_GOODS)
    display.commonUIParams(cellBg, {ap = display.CENTER, po = cc.p(45, 45)})
    -- cellBg:setFilter(filter.newFilter('GRAY'))
    bgLayer:addChild(cellBg)
    
    local themePart = display.newNSprite('', 44, 48,
    {
        ap = display.CENTER,
    })
    themePart:setScale(0.42)
    bgLayer:addChild(themePart)

    local numLabel = display.newLabel(86, 86, fontWithColor(14, {ap = display.RIGHT_TOP, fontSize = 20}))
    -- numLabel:setVisible(false)
    bgLayer:addChild(numLabel)

    local alreadyOwnedLabel = display.newLabel(45, 3, fontWithColor(14,{ap = display.CENTER_BOTTOM, fontSize = 18, text = __('已拥有'),color = '#ffcb2b',outline = '#361e11',outlineSize = 1}))
    bgLayer:addChild(alreadyOwnedLabel)
    alreadyOwnedLabel:setVisible(false)

    cell.viewData = {
        cellBg = cellBg,
        themePart = themePart,
        numLabel  = numLabel,
        alreadyOwnedLabel = alreadyOwnedLabel
    }
    return cell
end

function CapsuleThemePartsPreviewView:GetViewData()
    return self.viewData
end

return CapsuleThemePartsPreviewView
