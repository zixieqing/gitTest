--[[
 * author : kaishiqi
 * descpt : 餐厅 - 装修家具视图
]]
local DecorateView = class('DecorateView', function()
    return display.newLayer(0, 0, {name = 'DecorateView', enableEvent = true})
end)

local RES_DICT = {
    BOTTOM_BAR    = 'avatar/ui/decorate_bg_down.png',
    SHOP_FRAME    = 'avatar/ui/restaurant_main_bg_bottom.png',
    BTN_SHOP      = 'avatar/ui/restaurant_main_btn_shop.png',
    LABEL_BAR     = 'avatar/ui/card_bar_bg.png',
    BTN_ARROW_R   = 'avatar/ui/common_btn_switch.png',
    ARROW_FRAME   = 'avatar/ui/common_bg_switch.png',
    BTN_TYPE_N    = 'avatar/ui/restaurant_bg_banner_default.png',
    BTN_TYPE_S    = 'avatar/ui/restaurant_bg_banner_selected.png',
    ICON_HEART    = 'ui/common/common_hint_circle_red_ico.png',
    CELL_FRAME_D  = 'avatar/ui/avator_bg_goods_disabled.png',
    CELL_FRAME_N  = 'avatar/ui/avator_bg_goods_dsfault.png',
    CELL_FRAME_S  = 'avatar/ui/avator_bg_goods_selected.png',
    ICON_DOWN     = 'avatar/ui/restaurant_ico_avator_pull_down.png',
    BTN_DOWN      = 'avatar/ui/restaurant_btn_avator_tab.png',
    COM_TIP_FRAME = 'ui/common/common_bg_tips.png',
    COM_TIP_BORN  = 'ui/common/common_bg_tips_horn.png',
    THEME_NAME    = 'avatar/ui/avatarShop/avator_goods_bg_title_name.png',
    BTN_CLEAN_ALL = 'avatar/ui/decorate_btn_clear_all.png',
}

local THEME_CELL_W   = 338
local AVATAR_CELL_W  = 100
local AVATAR_CONFS   = CommonUtils.GetConfigAllMess('avatar', 'restaurant') or {}
local THEME_CONFS    = CommonUtils.GetConfigAllMess('avatarTheme', 'restaurant') or {}

local TYPE_ALL_INDEX = 1
local TYPE_LIST      = {
    {name = __('全部'), icon = 'avatar/ui/decorate_ico_ornament.png', id = RESTAURANT_AVATAR_TYPE.ALL},
    {name = __('桌椅'), icon = 'avatar/ui/decorate_ico_table.png',    id = RESTAURANT_AVATAR_TYPE.CHAIR},
    {name = __('装饰'), icon = 'avatar/ui/decorate_ico_flower.png',   id = RESTAURANT_AVATAR_TYPE.DECORATION},
    {name = __('墙纸'), icon = 'avatar/ui/decorate_ico_wall.png',     id = RESTAURANT_AVATAR_TYPE.WALL},
    {name = __('地板'), icon = 'avatar/ui/decorate_ico_floor.png',    id = RESTAURANT_AVATAR_TYPE.FLOOR},
    {name = __('吊饰'), icon = 'avatar/ui/decorate_ico_hang.png',     id = RESTAURANT_AVATAR_TYPE.CEILING},
    {name = __('主题'), icon = 'avatar/ui/decorate_ico_theme.png',    id = RESTAURANT_AVATAR_TYPE.THEME},
}

local CreateView       = nil
local CreateTypeView   = nil
local CreateTipsView   = nil
local CreateAvatarCell = nil


-------------------------------------------------
-- life cycle

function DecorateView:ctor(...)
    self.typeHeartDict_   = {}
    self.avatarCellDict_  = {}
    self.avatarDataList_  = {}
    self.themeDataList_   = {}
    self.themeDataDict_   = {}
    self.isControllable_  = true

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- init view
    sceneWorld:setOnTouchEndedAfterLongClickScriptHandler(handler(self, self.onLangTouchEndedHandler_))
    display.commonUIParams(self.viewData_.downBtn, {cb = handler(self, self.onClickDownButtonHandler_)})
    display.commonUIParams(self.viewData_.shopButton, {cb = handler(self, self.onClickShopButtonHandler_)})
    display.commonUIParams(self.viewData_.cleanAllBtn, {cb = handler(self, self.onClickCleanAllButtonHandler_)})
    display.commonUIParams(self.viewData_.nextPageBtn, {cb = handler(self, self.onClickNextPageButtonHandler_)})
    display.commonUIParams(self.viewData_.prevPageBtn, {cb = handler(self, self.onClickPrevPageButtonHandler_)})
    self.viewData_.avatarPageView:setDataSourceAdapterScriptHandler(handler(self, self.onAvatarGridDataAdapterHandler_))

    for i, typeViewData in ipairs(self.viewData_.typeBtnList) do
        display.commonUIParams(typeViewData.view, {cb = handler(self, self.onClickTypeButtonHandler_)})
    end

    -- set default type
    self:setTypeIndex(TYPE_ALL_INDEX)

    self.viewData_.view:setPositionY(-200)
end


CreateView = function()
    local size = cc.size(display.width, 150)
    local view = display.newLayer(0, 0, {size = size})

    -- typeBar layer
    local typeBarLayer = display.newLayer(display.SAFE_L, 100)
    view:addChild(typeBarLayer)

    local typeBtnList = {}
    for i, typeData in ipairs(TYPE_LIST) do
        local typeViewData = CreateTypeView(typeData)
        typeViewData.view:setPositionX(195 + (i-1) * 120)
        typeViewData.view:setTag(i)
        typeBarLayer:addChild(typeViewData.view)
        typeBtnList[i] = typeViewData
    end

    -- down button
    local downBtn = display.newButton(display.SAFE_L + 125, typeBarLayer:getPositionY() - 15, {n = _res(RES_DICT.BTN_DOWN), ap = display.CENTER_BOTTOM})
    view:addChild(downBtn)

    local downSize = downBtn:getContentSize()
    local downIcon = display.newImageView(_res(RES_DICT.ICON_DOWN), downSize.width/2, downSize.height/2 + 3)
    downBtn:addChild(downIcon)

    -- bottom bar
    view:addChild(display.newImageView(_res(RES_DICT.BOTTOM_BAR), size.width/2, 0, {ap = display.CENTER_BOTTOM, scale9 = true, size = cc.size(display.width, 110)}))
    view:addChild(display.newImageView(_res(RES_DICT.SHOP_FRAME), display.SAFE_R + 60, 0, {ap = display.RIGHT_BOTTOM}))

    -- cleanAll btn
    local cleanAllBtn = display.newButton(display.SAFE_L + 10, 0, {n = _res(RES_DICT.BTN_CLEAN_ALL), ap = display.LEFT_BOTTOM})
    display.commonLabelParams(cleanAllBtn, fontWithColor(16, {text = __('清除全部'), offset = cc.p(-5, -30)}))
    view:addChild(cleanAllBtn)

    -- shop button
    local shopButton = display.newButton(display.SAFE_R - 80, 0, {n = _res(RES_DICT.BTN_SHOP), ap = display.CENTER_BOTTOM})
    local shopButtonSize = shopButton:getContentSize()
    view:addChild(shopButton)
    local redPointIcon = display.newImageView(_res(RES_DICT.ICON_HEART), shopButtonSize.width - 10, shopButtonSize.height - 10)
    redPointIcon:setVisible(false)
    redPointIcon:setName('redPointIcon')
    shopButton:addChild(redPointIcon)

    local shopNameBar = display.newButton(shopButton:getContentSize().width +20, 20, {n = _res(RES_DICT.LABEL_BAR),  ap = display.RIGHT_CENTER ,  enable = false,
        scale9 = true, size = cc.size(120, 30)})
    display.commonLabelParams(shopNameBar, fontWithColor(14, {text = __('家具商店'), ap = display.RIGHT_CENTER,  color = 'ffffff',paddingW = 30  }))
    shopButton:addChild(shopNameBar)
    local  lwidth  = shopNameBar:getContentSize().width
    shopNameBar:getLabel():setPosition(cc.p((lwidth -20) , 15))
    -- avatar pageView
    local avatarPageSize = cc.size(display.SAFE_RECT.width - 215 - 125, 100)
    local avatarPageView = CPageView:create(avatarPageSize)
    avatarPageView:setDirection(eScrollViewDirectionHorizontal)
    avatarPageView:setSizeOfCell(cc.size(AVATAR_CELL_W, avatarPageSize.height))
    avatarPageView:setAnchorPoint(display.LEFT_BOTTOM)
    avatarPageView:setPosition(cc.p(display.SAFE_L + 5 + 125, 0))
    -- avatarPageView:setBackgroundColor(cc.c4b(0,0,0,150))
    view:addChild(avatarPageView)

    -- next page layer
    local nextPageLayer = display.newLayer()
    view:addChild(nextPageLayer)

    local nextPageInfoPos = cc.p(display.SAFE_R - 235, 48)
    nextPageLayer:addChild(display.newImageView(_res(RES_DICT.ARROW_FRAME), nextPageInfoPos.x, nextPageInfoPos.y))

    local nextPageBtn = display.newButton(nextPageInfoPos.x + 5, nextPageInfoPos.y, {n = _res(RES_DICT.BTN_ARROW_R)})
    nextPageLayer:addChild(nextPageBtn)

    -- prev page layer
    local prevPageLayer = display.newLayer()
    view:addChild(prevPageLayer)

    local prevPageInfoPos = cc.p(display.SAFE_L + 35, nextPageInfoPos.y)
    prevPageLayer:addChild(display.newImageView(_res(RES_DICT.ARROW_FRAME), prevPageInfoPos.x, prevPageInfoPos.y, {scaleX = -1}))

    local prevPageBtn = display.newButton(prevPageInfoPos.x - 5, prevPageInfoPos.y, {n = _res(RES_DICT.BTN_ARROW_R), isFlipX = true})
    prevPageLayer:addChild(prevPageBtn)

    nextPageLayer:setVisible(false)
    prevPageLayer:setVisible(false)
    return {
        view           = view,
        downBtn        = downBtn,
        downIcon       = downIcon,
        viewFlodPos    = cc.p(view:getPositionX(), view:getPositionY() - 100),
        viewUnflodPos  = cc.p(view:getPosition()),
        typeBarLayer   = typeBarLayer,
        shopButton     = shopButton,
        cleanAllBtn    = cleanAllBtn,
        nextPageBtn    = nextPageBtn,
        prevPageBtn    = prevPageBtn,
        typeBtnList    = typeBtnList,
        avatarPageView = avatarPageView,
    }
end


CreateTypeView = function(typeData)
    local data = checktable(typeData)
    local size = cc.size(120, 45)
    local view = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})

    local typeDefImg = display.newImageView(_res(RES_DICT.BTN_TYPE_N), size.width/2, 0, {ap = display.CENTER_BOTTOM})
    local typeSltImg = display.newImageView(_res(RES_DICT.BTN_TYPE_S), size.width/2, -5, {ap = display.CENTER_BOTTOM})
    view:addChild(typeDefImg)
    view:addChild(typeSltImg)

    local typeIcoImg = display.newImageView(_res(data.icon), size.width/2, 5, {ap = display.CENTER_BOTTOM})
    view:addChild(typeIcoImg)

    local nameLabel = display.newLabel(size.width/2, 5, fontWithColor(6, {text = tostring(data.name),reqW = 93, ap = display.CENTER_BOTTOM}))
    view:addChild(nameLabel)

    local heartIcon = display.newImageView(_res(RES_DICT.ICON_HEART), size.width - 10, size.height - 10)
    view:addChild(heartIcon)

    return {
        view       = view,
        typeDefImg = typeDefImg,
        typeSltImg = typeSltImg,
        typeIcoImg = typeIcoImg,
        nameLabel  = nameLabel,
        heartIcon  = heartIcon,
    }
end


CreateAvatarCell = function(size)
    local view = CPageViewCell:new()
    view:setContentSize(size)

    local cellDisImg = display.newImageView(_res(RES_DICT.CELL_FRAME_D), 0, size.height/2, {scale9 = true, capInsets = cc.rect(8, 8, 78, 78)})
    local cellDefImg = display.newImageView(_res(RES_DICT.CELL_FRAME_N), 0, size.height/2, {scale9 = true, capInsets = cc.rect(8, 8, 78, 78)})
    local cellSltImg = display.newImageView(_res(RES_DICT.CELL_FRAME_S), 0, size.height/2, {scale9 = true, capInsets = cc.rect(8, 8, 80, 80)})
    view:addChild(cellDisImg)
    view:addChild(cellDefImg)
    view:addChild(cellSltImg)

    local imageLayer = display.newLayer(0, size.height/2 + 5)
    view:addChild(imageLayer)

    local countLabel = display.newLabel(0, 4, fontWithColor(19, {ap = display.CENTER_BOTTOM}))
    view:addChild(countLabel)

    local themeLayer = display.newLayer(0, 0)
    view:addChild(themeLayer)

    local themeImageLayer = display.newLayer(0, size.height/2)
    themeLayer:addChild(themeImageLayer)
    
    local themeNameLabel = display.newButton(0, 8, {n = _res(RES_DICT.THEME_NAME), ap = display.LEFT_BOTTOM})
    display.commonLabelParams(themeNameLabel, fontWithColor(18, {ap = display.LEFT_CENTER, offset = cc.p(-themeNameLabel:getContentSize().width/2 + 4, 0)}))
    themeLayer:addChild(themeNameLabel)

    local heartIcon = display.newImageView(_res(RES_DICT.ICON_HEART), 0, size.height, {ap = display.RIGHT_TOP})
    view:addChild(heartIcon)

    local clickArea = display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(clickArea)

    local resetSizeFunc = function(cellSize)
        view:setContentSize(cellSize)
        clickArea:setContentSize(cellSize)
        local cellImgSize = cc.size(cellSize.width - 8, cellSize.height - 12)
        cellDisImg:setContentSize(cellImgSize)
        cellDefImg:setContentSize(cellImgSize)
        cellSltImg:setContentSize(cc.size(cellImgSize.width + 4, cellImgSize.height + 4))

        themeNameLabel:setPositionX(cellSize.width/2 - cellImgSize.width/2 + 2)
        themeImageLayer:setPositionX(cellSize.width/2)
        cellDisImg:setPositionX(cellSize.width/2)
        cellDefImg:setPositionX(cellSize.width/2)
        cellSltImg:setPositionX(cellSize.width/2)
        imageLayer:setPositionX(cellSize.width/2)
        countLabel:setPositionX(cellSize.width/2)
        heartIcon:setPositionX(cellSize.width)
    end
    resetSizeFunc(size)

    return {
        view            = view,
        cellDisImg      = cellDisImg,
        cellDefImg      = cellDefImg,
        cellSltImg      = cellSltImg,
        imageLayer      = imageLayer,
        countLabel      = countLabel,
        clickArea       = clickArea,
        heartIcon       = heartIcon,
        resetSizeFunc   = resetSizeFunc,
        themeLayer      = themeLayer,
        themeImageLayer = themeImageLayer,
        themeNameLabel  = themeNameLabel,
    }
end


CreateTipsView = function()
    local size = cc.size(364, 190)
    local view = display.newLayer(0, 0, {bg = _res(RES_DICT.COM_TIP_FRAME), ap = display.CENTER_BOTTOM, enable = true, scale9 = true, size = size})

    local horn = display.newImageView(_res(RES_DICT.COM_TIP_BORN), size.width/2, 2, {scaleY = -1})
    view:addChild(horn)

    local nameLabel = display.newLabel(14, size.height - 20, fontWithColor(1, {ap = display.LEFT_TOP}))
    view:addChild(nameLabel)

    local descrLabel = display.newLabel(14, size.height - 58, fontWithColor(11, {ap = display.LEFT_TOP, w = size.width - 28, h = 100}))
    view:addChild(descrLabel)

    return {
        view       = view,
        horn       = horn,
        nameLabel  = nameLabel,
        descrLabel = descrLabel,
    }
end


-------------------------------------------------
-- get / set

function DecorateView:isFlodAvatar()
    return self.isFlodAvatar_ == true
end
function DecorateView:setFlodAvatar(isFlod)
    self.isFlodAvatar_ = isFlod == true
    if self.isFlodAvatar_ then
        self:toFoldAvatar_()
    else
        self:toUnfoldAvatar_()
    end
end


function DecorateView:getTypeIndex()
    return self.typeIndex_
end
function DecorateView:setTypeIndex(index)
    self.typeIndex_ = checkint(index)
    self:reloadAvatarList()
end


function DecorateView:getSelectedAvatarId()
    return checkint(self.selectedAvatarId_)
end
function DecorateView:setSelectedAvatarId(avatarId)
    local oldSelectedAvatarId = self:getSelectedAvatarId()
    local newSelectedAvatarId = checkint(avatarId)
    self.selectedAvatarId_    = newSelectedAvatarId

    for _, cellViewData in pairs(self.avatarCellDict_) do
        local cellIndex  = cellViewData.clickArea:getTag()
        local avatarData = self.avatarDataList_[cellIndex] or {}
        local avatarId   = checkint(avatarData.avatarId)
        if oldSelectedAvatarId == avatarId or newSelectedAvatarId == avatarId then
            self:updateAvatarCellStatus_(cellIndex, cellViewData)
        end
    end
end


function DecorateView:getSelectedThemeId()
    return checkint(self.selectedThemeId_)
end
function DecorateView:setSelectedThemeId(themeId)
    self.selectedThemeId_ = checkint(themeId)

    if self.selectedThemeId_ > 0 then
        self.avatarDataList_ = self.themeDataDict_[tostring(self:getSelectedThemeId())]
    else
        self.avatarDataList_ = self.themeDataList_
    end

    -- reload avatarPageView
    local avatarPageView  = self.viewData_.avatarPageView
    local avatarPageCellW = self:getSelectedThemeId() > 0 and AVATAR_CELL_W or THEME_CELL_W
    local avatarPageCellH = avatarPageView:getContentSize().height
    avatarPageView:setSizeOfCell(cc.size(avatarPageCellW, avatarPageCellH))
    avatarPageView:setCountOfCell(#self.avatarDataList_)
    avatarPageView:reloadData()
    self:freshAvatarList()
end


-------------------------------------------------
-- public method

function DecorateView:reloadAvatarList()
    local gameManager    = AppFacade.GetInstance():GetManager('GameManager')
    local avatarTypeData = TYPE_LIST[self:getTypeIndex()] or {}
    local avatarTypeId   = checkint(avatarTypeData.id)
    local isSeeAllAvatar = avatarTypeId == RESTAURANT_AVATAR_TYPE.ALL
    local isSeeThemeTab  = avatarTypeId == RESTAURANT_AVATAR_TYPE.THEME

    self.typeHeartDict_   = {}
    self.themeDataDict_   = {}
    self.themeDataList_   = {}
    self.avatarDataList_  = {}
    for _, backpackData in ipairs(gameManager:GetUserInfo().backpack or {}) do
        local totalNum   = checkint(backpackData.amount)
        local goodsId    = checkint(backpackData.goodsId)
        local goodsIsNew = checkint(backpackData.IsNew) == 1
        local goodsType  = CommonUtils.GetGoodTypeById(goodsId)
        
        if goodsType == GoodsType.TYPE_AVATAR and totalNum > 0 then
            local avatarConf  = AVATAR_CONFS[tostring(goodsId)] or {}
            local avatarType  = self:getAvatarType_(goodsId)
            local avatarTheme = checkint(avatarConf.theme)
            local avatarData  = {avatarId = goodsId, totalNum = totalNum, usedNum = 0}

            -- record avatar data
            if isSeeAllAvatar then
                table.insert(self.avatarDataList_, avatarData)
            elseif isSeeThemeTab then
            else
                if avatarType == avatarTypeId then
                    table.insert(self.avatarDataList_, avatarData)
                end
            end

            -- record heart data
            if goodsIsNew then
                self.typeHeartDict_[tostring(avatarType)] = self.typeHeartDict_[tostring(avatarType)] or {}
                self.typeHeartDict_[tostring(avatarType)][tostring(goodsId)] = true
            end
            
            -- record theme data
            if avatarTheme > 0 then
                self.themeDataDict_[tostring(avatarTheme)] = self.themeDataDict_[tostring(avatarTheme)] or {}
                table.insert(self.themeDataDict_[tostring(avatarTheme)], avatarData)
            end
        end
    end

    -- 唉，不优化了，切一次tab就全部重新生成一次数据吧，不然还要动结构。
    for i, avatarTheme in ipairs(table.keys(self.themeDataDict_)) do
        table.insert(self.themeDataList_, {themeId = avatarTheme, themeName = self:getThemeName_(avatarTheme)})
    end

    if isSeeThemeTab then
        local isSeeAllTheme  = self:getSelectedThemeId() == 0
        self.avatarDataList_ = isSeeAllTheme and self.themeDataList_ or self.themeDataDict_[tostring(self:getSelectedThemeId())]
    end

    -- reload avatarPageView
    local avatarPageView  = self.viewData_.avatarPageView
    local avatarPageCellW = (isSeeThemeTab and self:getSelectedThemeId() == 0) and THEME_CELL_W or AVATAR_CELL_W
    local avatarPageCellH = avatarPageView:getContentSize().height
    avatarPageView:setSizeOfCell(cc.size(avatarPageCellW, avatarPageCellH))
    avatarPageView:setCountOfCell(#self.avatarDataList_)
    avatarPageView:reloadData()
    self:freshAvatarList()
    
    self:updateTypeBar_()
end
function DecorateView:freshAvatarList()
    local gameManager = AppFacade.GetInstance():GetManager('GameManager')
    local usedAvatars = checktable(gameManager:GetUserInfo().avatarCacheData).location or {}
    local usedNumMap  = {}
    for _, locationData in pairs(usedAvatars) do
        local avatarId = checkint(locationData.goodsId)
        usedNumMap[tostring(avatarId)] = checkint(usedNumMap[tostring(avatarId)]) + 1
    end

    -- fresh all usedNum
    for i, avatarData in ipairs(self.avatarDataList_) do
        avatarData.usedNum = checkint(usedNumMap[tostring(avatarData.avatarId)])
    end

    -- fresh all cell
    for _, cellViewData in pairs(self.avatarCellDict_) do
        local index = cellViewData.clickArea:getTag()
        self:updateAvatarCellStatus_(index, cellViewData)
    end
end

function DecorateView:updateShopButtonTip(showRemind)
    local shopButton = self.viewData_.shopButton
    local redPointIcon = shopButton:getChildByName('redPointIcon')

    if redPointIcon then
        local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
        redPointIcon:setVisible(showRemind)
    end
end

-------------------------------------------------
-- private method

function DecorateView:getAvatarType_(avatarId)
    local avatarConf = AVATAR_CONFS[tostring(avatarId)] or {}
    return checkint(avatarConf.mainType)
end


function DecorateView:getThemeName_(themeId)
    local themeConf = THEME_CONFS[tostring(themeId)] or {}
    return tostring(themeConf.name)
end


function DecorateView:toFoldAvatar_()
    local actionTime     = 0.15
    self.isControllable_ = false

    self:stopAllActions()
    self:runAction(cc.Sequence:create(
        cc.TargetedAction:create(self.viewData_.view, cc.MoveTo:create(actionTime, self.viewData_.viewFlodPos)),
        cc.CallFunc:create(function()
            self.viewData_.downIcon:setScaleY(-1)
            self.isControllable_ = true
        end)
    ))
end
function DecorateView:toUnfoldAvatar_()
    local actionTime     = 0.15
    self.isControllable_ = false

    self:stopAllActions()
    self:runAction(cc.Sequence:create(
        cc.TargetedAction:create(self.viewData_.view, cc.MoveTo:create(actionTime, self.viewData_.viewUnflodPos)),
        cc.CallFunc:create(function()
            self.viewData_.downIcon:setScaleY(1)
            self.isControllable_ = true
        end)
    ))
end


function DecorateView:showTipsView_(touchPoint)
    self:hideTipsView_()

    self.tipsViewData_ = CreateTipsView()
    self.tipsViewData_.view:setPositionY(touchPoint.y + 20)

    local tipsViewSize = self.tipsViewData_.view:getContentSize()
    self.tipsViewData_.view:setPositionX(math.min(math.max(tipsViewSize.width/2, touchPoint.x), display.width - tipsViewSize.width/2))

    local hornOffsetX  = self.tipsViewData_.view:getPositionX() - touchPoint.x
    local tipsHornSize = self.tipsViewData_.horn:getContentSize()
    self.tipsViewData_.horn:setPositionX(math.min(math.max(tipsHornSize.width/2 + 2, tipsViewSize.width/2 - hornOffsetX), tipsViewSize.width - tipsHornSize.width/2 - 2))

    local uiManager    = AppFacade.GetInstance():GetManager('UIManager')
    local currentScene = uiManager:GetCurrentScene()
    currentScene:addChild(self.tipsViewData_.view, 999999)
end
function DecorateView:hideTipsView_()
    if self.tipsViewData_ then
        self.tipsViewData_.view:stopAllActions()
        self.tipsViewData_.view:runAction(cc.RemoveSelf:create())
        self.tipsViewData_ = nil
    end
end


function DecorateView:updateTypeBar_()
    for i, typeViewData in ipairs(self.viewData_.typeBtnList) do
        local isSelected = self:getTypeIndex() == i
        typeViewData.typeDefImg:setVisible(not isSelected)
        typeViewData.typeSltImg:setVisible(isSelected)
        typeViewData.typeIcoImg:setVisible(isSelected)
        typeViewData.nameLabel:setVisible(not isSelected)

        if i == TYPE_ALL_INDEX then
            local hasHeart = false
            for k, typeHeartMap in pairs(self.typeHeartDict_) do
                hasHeart = table.nums(typeHeartMap) > 0
                if hasHeart then break end
            end
            typeViewData.heartIcon:setVisible(hasHeart)
        else
            local avatarTypeData = TYPE_LIST[i] or {}
            local typeHeartMap = self.typeHeartDict_[tostring(avatarTypeData.id)] or {}
            typeViewData.heartIcon:setVisible(table.nums(typeHeartMap) > 0)
        end
    end
end


function DecorateView:updateAvatarCellStatus_(index, cellViewData)
    local avatarPageView = self.viewData_.avatarPageView
    local avatarViewData = cellViewData or avatarPageView:cellAtIndex(index - 1)

    local avatarData = self.avatarDataList_[index] or {}
    if avatarViewData then
        local totalNum = checkint(avatarData.totalNum)
        local usedNum  = checkint(avatarData.usedNum)
        display.commonLabelParams(cellViewData.countLabel, {text = string.fmt('%1/%2', usedNum, totalNum)})

        local isEmpty = usedNum >= totalNum
        cellViewData.cellDisImg:setVisible(isEmpty)
        cellViewData.cellDefImg:setVisible(not isEmpty)
        cellViewData.imageLayer:setColor(isEmpty and cc.c3b(180,180,180) or cc.c3b(255,255,255))
        cellViewData.cellSltImg:setVisible(self:getSelectedAvatarId() == avatarData.avatarId)

        local avatarType = self:getAvatarType_(avatarData.avatarId)
        cellViewData.heartIcon:setVisible(checktable(self.typeHeartDict_[tostring(avatarType)])[tostring(avatarData.avatarId)])
    end
end

-------------------------------------------------
-- handler

function DecorateView:onEnter()
    local actionTime     = 0.2
    self.isControllable_ = false
    self:runAction(cc.Sequence:create(
        cc.TargetedAction:create(self.viewData_.view, cc.EaseOut:create(cc.MoveTo:create(actionTime, PointZero), 0.2)),
        cc.CallFunc:create(function()
            self.isControllable_ = true
            GuideUtils.DispatchStepEvent()
        end)
    ))
end
function DecorateView:onExit()
    self:hideTipsView_()
end
function DecorateView:onCleanup()
    sceneWorld:removeOnTouchEndedAfterLongClickScriptHandler()
end


function DecorateView:onLangTouchEndedHandler_()
    self:hideTipsView_()
end


function DecorateView:onClickDownButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:setFlodAvatar(not self:isFlodAvatar())
end


function DecorateView:onClickShopButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    
    AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_AVATAR_SHOP)
end


function DecorateView:onClickCleanAllButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    
    -- to clean all
    app.uiMgr:AddCommonTipDialog({
        descr    = __("是否清除全部家具？"),
        callback = function()
            app.socketMgr:SendPacket(NetCmd.RestuarantCleanAll) -- 6012 清空
        end
    })
end


function DecorateView:onClickTypeButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local typeIndex = checkint(sender:getTag())
    if self:getTypeIndex() == typeIndex then
        local avatarTypeData = TYPE_LIST[typeIndex] or {}
        if avatarTypeData.id == RESTAURANT_AVATAR_TYPE.THEME then
            self:setSelectedThemeId(nil)
        end
        
    else
        self:setTypeIndex(typeIndex)

        if self:isFlodAvatar() then
            self:setFlodAvatar(false)
        else
            self.isControllable_ = false
            transition.execute(self, nil, {delay = 0.3, complete = function()
                self.isControllable_ = true
            end})
        end
    end
end


function DecorateView:onAvatarGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    local avatarPageView = self.viewData_.avatarPageView
    local avatarCellSize = avatarPageView:getSizeOfCell()

    -- create cell
    if pCell == nil then
        local cellViewData = CreateAvatarCell(avatarCellSize)
        display.commonUIParams(cellViewData.clickArea, {cb = handler(self, self.onClickAvatarCellHandler_)})
        cellViewData.clickArea:setOnLongClickScriptHandler(handler(self, self.onLangClickAvatarCellHandler_))

        pCell = cellViewData.view
        self.avatarCellDict_[pCell] = cellViewData
    end

    -- init cell
    local cellViewData = self.avatarCellDict_[pCell]
    local avatarData   = self.avatarDataList_[index]
    cellViewData.clickArea:setTag(index)
    cellViewData.imageLayer:removeAllChildren()
    cellViewData.themeLayer:setVisible(false)
    cellViewData.themeImageLayer:removeAllChildren()
    cellViewData.resetSizeFunc(avatarCellSize)

    if avatarData then
        if avatarData.themeId then
            local themeImgNode = display.newImageView(CommonUtils.GetGoodsIconPathById(avatarData.themeId))
            themeImgNode:setScale(0.5)
            cellViewData.themeImageLayer:addChild(themeImgNode)
            display.commonLabelParams(cellViewData.themeNameLabel, {text = checkstr(avatarData.themeName)})
            cellViewData.themeLayer:setVisible(true)
            
        else
            local avatarImgNode = AssetsUtils.GetRestaurantSmallAvatarNode(avatarData.avatarId)
            avatarImgNode:setScale(0.45)
            cellViewData.imageLayer:addChild(avatarImgNode)
        end
    end

    -- update cell
    self:updateAvatarCellStatus_(index, cellViewData)
    return pCell
end


function DecorateView:onLangClickAvatarCellHandler_(sender, touch)
    local cellIndex  = sender:getTag()
    local avatarData = self.avatarDataList_[cellIndex] or {}
    local themeId = checkint(avatarData.themeId)
    if themeId > 0 then
        return true
    end
    
    self:showTipsView_(touch:getLocation())

    if self.tipsViewData_ then
        local buffDesc, name = RestaurantUtils.GetBuffDescByAvatarId(avatarData.avatarId)
        display.commonLabelParams(self.tipsViewData_.nameLabel, {text = tostring(name)})
        display.commonLabelParams(self.tipsViewData_.descrLabel, {text = tostring(buffDesc)})
    end
    return true
end
function DecorateView:onClickAvatarCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local avatarMediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
    local socketManager  = AppFacade.GetInstance():GetManager('SocketManager')
    local gameManager    = AppFacade.GetInstance():GetManager('GameManager')
    local uiManager      = AppFacade.GetInstance():GetManager('UIManager')
    local cellIndex      = sender:getTag()
    local avatarData     = self.avatarDataList_[cellIndex] or {}
    
    -- check select theme
    local avatarTypeData = TYPE_LIST[self:getTypeIndex()] or {}
    local avatarTypeId   = checkint(avatarTypeData.id)
    if avatarTypeData.id == RESTAURANT_AVATAR_TYPE.THEME and self:getSelectedThemeId() == 0 then
        local themeId = checkint(avatarData.themeId)
        self:setSelectedThemeId(themeId)

    else
        local avatarId    = checkint(avatarData.avatarId)
        local avatarType  = self:getAvatarType_(avatarId)
        local hasFree     = checkint(avatarData.totalNum) > checkint(avatarData.usedNum)
        local usedAvatars = checktable(gameManager:GetUserInfo().avatarCacheData).location or {}

        -------------------------------------------------
        -- the onlyone count
        if avatarType == RESTAURANT_AVATAR_TYPE.WALL or avatarType == RESTAURANT_AVATAR_TYPE.FLOOR or avatarType == RESTAURANT_AVATAR_TYPE.CEILING then
            local usedAvatarData = nil
            for _, locationData in pairs(usedAvatars) do
                if self:getAvatarType_(checkint(locationData.goodsId)) == avatarType then
                    usedAvatarData = locationData
                    break
                end
            end

            -- check is same avatar
            if usedAvatarData and avatarId == checkint(usedAvatarData.goodsId) then
                if avatarType == RESTAURANT_AVATAR_TYPE.CEILING then
                    -- to remove
                    avatarMediator.handleData = {fix = true, goodsId = avatarId, id = usedAvatarData.id}
                    socketManager:SendPacket(NetCmd.RestuarantRemoveGoods, {goodsId = avatarId, goodsUuid = usedAvatarData.id}) -- 6005 删除
                else
                    uiManager:ShowInformationTips(__('当前正在使用中'))
                end
            else
                -- to replace
                avatarMediator.handleData = {fix = true, goodsId = avatarId, type = avatarType}
                socketManager:SendPacket(NetCmd.RestuarantPutNewGoods, {goodsId = avatarId}) -- 6004 添加
            end

        -------------------------------------------------
        -- the multiple count
        elseif avatarType == RESTAURANT_AVATAR_TYPE.DECORATION then
            if hasFree then
                if avatarMediator.curNode and checkint(avatarMediator.curNode.avatarId) == avatarId then
                    uiManager:ShowInformationTips(__('请先确认当前的编辑状态'))
                else
                    avatarMediator.handleData = {fix = false, goodsId = avatarId, type = avatarType}
                    socketManager:SendPacket(NetCmd.RestuarantPutNewGoods, {goodsId = avatarId}) -- 6004 添加
                end
            else
                uiManager:ShowInformationTips(__('当前家具已经用光'))
            end

        -------------------------------------------------
        -- the limit count
        elseif avatarType == RESTAURANT_AVATAR_TYPE.CHAIR then
            if hasFree then
                local restaurantLevel = checkint(gameManager:GetUserInfo().restaurantLevel)
                local restaurantConf  = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', restaurantLevel) or {}
                local limitSeatCount  = checkint(restaurantConf.seatNum)
                local usedSeatCount   = 0
                for _, locationData in pairs(usedAvatars) do
                    if self:getAvatarType_(checkint(locationData.goodsId)) == RESTAURANT_AVATAR_TYPE.CHAIR then
                        local avatarLocationConf = CommonUtils.GetConfigNoParser("restaurant", 'avatarLocation', locationData.goodsId) or {}
                        usedSeatCount = usedSeatCount + checkint(avatarLocationConf.additionNum)
                    end
                end

                -- check limit count
                local appendLocationConf = CommonUtils.GetConfigNoParser("restaurant", 'avatarLocation', avatarId) or {}
                local appendSeatCount    = checkint(appendLocationConf.additionNum)
                if usedSeatCount + appendSeatCount > limitSeatCount then
                    local tipsText = string.fmt(__('不可超出当前餐厅座位上限\n当前餐厅的座位数为 _cur_/_max_'), {_cur_ = usedSeatCount, _max_ = limitSeatCount})
                    uiManager:ShowInformationTips(tipsText)
                else
                    if avatarMediator.curNode and checkint(avatarMediator.curNode.avatarId) == avatarId then
                        uiManager:ShowInformationTips(__('请先确认当前的编辑状态'))
                    else
                        avatarMediator.handleData = {fix = false, goodsId = avatarId, type = avatarType}
                        socketManager:SendPacket(NetCmd.RestuarantPutNewGoods, {goodsId = avatarId}) -- 6004 添加
                    end
                end
            else
                uiManager:ShowInformationTips(__('当前家具已经用光'))
            end
        end
        
        -- update heart cache
        if checktable(self.typeHeartDict_[tostring(avatarType)])[tostring(avatarId)] then
            self.typeHeartDict_[tostring(avatarType)][tostring(avatarId)] = nil
            gameManager:UpdateBackpackNewStatuByGoodId(avatarId)
            self:updateTypeBar_()
        end
    end

    -- block control
    self.isControllable_ = false
    transition.execute(self, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})
end


function DecorateView:onClickNextPageButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
end
function DecorateView:onClickPrevPageButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
end


return DecorateView
