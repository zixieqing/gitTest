--[[
餐厅商城 Mediator
--]]
local Mediator = mvc.Mediator
local AvatarShopMediator = class("AvatarShopMediator", Mediator)
local NAME = "AvatarShopMediator"

local VIEW_TAG = 777120

local avatarMallCof = CommonUtils.GetConfigAllMess('avatar', 'mall')
local avatarActivityMallCof = CommonUtils.GetConfigAllMess('activity', 'mall')
local avatarRestaurantConf = CommonUtils.GetConfigAllMess('avatar', 'restaurant')
local avatarThemeRestaurantConf = CommonUtils.GetConfigAllMess('avatarTheme', 'restaurant')
local avatarThemeGoodConf = CommonUtils.GetConfigAllMess('avatarTheme', 'goods')
local avatarThemePartsConf = CommonUtils.GetConfigAllMess('avatarThemeParts', 'restaurant')

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local TAB_INFOS = {
    {id = RESTAURANT_AVATAR_TYPE.THEME,      name = __('主题'), image = _res('avatar/ui/decorate_ico_theme')},
    {id = RESTAURANT_AVATAR_TYPE.CHAIR,      name = __('桌椅'), image = _res('avatar/ui/decorate_ico_table')},
    {id = RESTAURANT_AVATAR_TYPE.DECORATION, name = __('装饰'), image = _res('avatar/ui/decorate_ico_flower')},
    {id = RESTAURANT_AVATAR_TYPE.WALL,       name = __('墙纸'), image = _res('avatar/ui/decorate_ico_wall')},
    {id = RESTAURANT_AVATAR_TYPE.FLOOR,      name = __('地板'), image = _res('avatar/ui/decorate_ico_floor')},
    {id = RESTAURANT_AVATAR_TYPE.CEILING,    name = __('吊饰'), image = _res('avatar/ui/decorate_ico_hang')},
}

local CELL_TYPE = {
    TAB = 1,
    SHOP_GOOD = 2,
    SHOP_THEME = 3,
}

local BTN_TAG = {
    PREVIEW_BUY_GOOD_NUM    = 3000,   --
    PREVIEW_BUY_GOOD_SUB    = 3001,   -- 减号
    PREVIEW_BUY_GOOD_PLUS   = 3002,   -- 加号
    PREVIEW_BUY_GOOD        = 3003,   -- 购买道具
    PREVIEW_THEME           = 3004,   -- 预览主题
    PREVIEW_BUY_THEME       = 3005,   -- 预览主题
}

local getTabIndexByType = nil
local getCurrencyByPayType = nil

local WHOLE_THEME_DISCOUNT = 80

function AvatarShopMediator:ctor(params, viewComponent)
    self.super:ctor(NAME,viewComponent)
    self.args = checktable(params)
    -- 当前 mall type
    self.currentAvatarType_ = self.args.avatarType or TAB_INFOS[1].id
    -- print(self.currentAvatarType_, 'currentAvatarType_')

    -- 当前 mall 数据
    self.currentMallData_  = {}
    self.isFirstInitTheme_ = true
    self.isFirstInitGood_  = true

    self.goodCellIndex = 1

    -- 初始值  为 -1  当用户查看主题散件时  将他 改变 为 1    退出 查看主题散件时 将他改变为-1
    self.themeGoodCellIndex = -1

    self.selectNum = 1

    self.isControllable_ = true

end

function AvatarShopMediator:InterestSignals()
	local signals = {
        SIGNALNAMES.SHOP_AVATAR_CALLBACK,
        SIGNALNAMES.SHOP_AVATAR_BUYAVATAR_CALLBACK,
        RESTAURANT_EVENTS.EVENT_AVATAR_SHOP_THEME_VISIBLE_UNREGIST,
	}

	return signals
end

function AvatarShopMediator:ProcessSignal( signal )
    local name = signal:GetName()
	-- print(name)
    local body = signal:GetBody()

    if name == SIGNALNAMES.SHOP_AVATAR_CALLBACK then
        local serDatas = body.avatar
        self:InitAvatarMallData(serDatas)

        self:updateShopListLayer()

        self:updateShopGoodPreview()

    elseif name == SIGNALNAMES.SHOP_AVATAR_BUYAVATAR_CALLBACK then
        -- dump(body)
        uiMgr:ShowInformationTips(__('购买成功~~'))
        local requestData = checktable(body.requestData)

        local currencyId = requestData.currencyId
        local deltaGoodsId = requestData.deltaGoodsId
        local deltaPrice = requestData.deltaPrice
        -- local realDiscontRate = requestData.realDiscontRate
        local showThemeParts = requestData.showThemeParts
        local themeId = requestData.themeId
        local listIndex = requestData.listIndex
        local themeListIndex = requestData.themeListIndex
        local num = requestData.num
        local productId = requestData.productId

        -- 检查 是否拥有主题
        local function checkIsOwnTheme(unmetPartCount)
            return unmetPartCount == 0
        end

        -- 检查 主题清单要显示的个数 是否为0
        local function checkShowGoodNum(showGoodNum)
            return showGoodNum == 0
        end

        local function updateThemeOwnState(unmetPartCount, themeIndex, isUpdateThemeList, themeParts_)

            local themeInventoryPreviewViewData = self.themeInventoryPreviewViewData
            local isOwnTheme = unmetPartCount == 0
            -- 更新 主题清单
            if themeInventoryPreviewViewData and isOwnTheme then
                local gridView = themeInventoryPreviewViewData.gridView
                local partCount = #themeParts_
                gridView:setCountOfCell(partCount)
                gridView:reloadData()

                self:updateThemeInventoryPreview(themeIndex)
            end

            local themeDescViewData = self.viewData.themeDescViewData
            -- 刷新主题详情
            local themeCellViewData = themeDescViewData.themeCellViewData
            local ownBg = themeCellViewData.ownBg
            ownBg:setVisible(isOwnTheme)

            if isUpdateThemeList == nil  or checkbool(isUpdateThemeList) then
                -- 刷新主题列表
                local shopThemeViewData = self.viewData.shopThemeViewData
                local shopThemeListView = shopThemeViewData.gridView
                local cell = shopThemeListView:cellAtIndex(themeIndex - 1)
                if cell then
                    local cellViewData = cell.viewData
                    local themeListOwnBg = cellViewData.ownBg
                    themeListOwnBg:setVisible(isOwnTheme)
                end
            end
        end

        local function updateThemeData(themeGoodInventory, themePart, deltaPrice, num)
            local isUpdateThemeOwnState = false
            if themeGoodInventory == nil or themePart == nil then
                return isUpdateThemeOwnState
            end
            -- 1.检查 是否拥有主题
            if not checkIsOwnTheme(themeGoodInventory.unmetPartCount) then
                -- 2. 计算物品单价
                local propUnitPrice = deltaPrice / num * -1

                -- 3. 检查当前道具数 是否满足 主题构成主题条件
                if not checkShowGoodNum(themePart.showGoodNum) then
                    -- 3.1 列表中显示的 道具拥有数
                    local tempNum = themePart.showGoodNum - num
                    -- 3.2 计算主题总价
                    if tempNum < 0 then
                        themeGoodInventory.themeTotalPrice = themeGoodInventory.themeTotalPrice + propUnitPrice * themePart.showGoodNum * -1
                    else
                        themeGoodInventory.themeTotalPrice = themeGoodInventory.themeTotalPrice + deltaPrice
                    end
                    themePart.showGoodNum = (themePart.showGoodNum < 0 or tempNum < 0) and 0 or tempNum
                    -- 3.3 检查 是否更新 unmetPartCount
                    if checkShowGoodNum(themePart.showGoodNum) then
                        themeGoodInventory.unmetPartCount = themeGoodInventory.unmetPartCount - 1
                        isUpdateThemeOwnState = true
                    end
                end

            end

            return isUpdateThemeOwnState
        end

        -- warn: 主题散件 和 普通道具购买是一样的
        local isTheme = themeId ~= nil
        if isTheme then
            local themeGoodInventory = self:GetThemeGoodInventory(themeId)
            local themeParts         = themeGoodInventory.themeParts
            local themeDescViewData = self.viewData.themeDescViewData

            if showThemeParts == 1 then
                local needUpdateData = {
                    -- 支付货币 增量
                    {goodsId = currencyId, num = deltaPrice},
                    -- 道具 增量
                    {goodsId = deltaGoodsId, num = num},
                }
                CommonUtils.DrawRewards(needUpdateData)

                local themePart = themeParts[listIndex]

                local isUpdateThemeOwnState = updateThemeData(themeGoodInventory, themePart, deltaPrice, num)
                if isUpdateThemeOwnState then
                    updateThemeOwnState(themeGoodInventory.unmetPartCount, themeListIndex)
                end
                local gridView          = themeDescViewData.gridView
                local cell = gridView:cellAtIndex(listIndex - 1)
                if cell then
                    self:updateShopGoodCell(cell.viewData, themePart, listIndex == self.goodCellIndex)
                end
            else
                local needUpdateData = {
                    -- 支付货币 增量
                    {goodsId = currencyId, num = deltaPrice},
                }
                for i, themePart in ipairs(themeParts) do
                    local goodsId           = themePart.goodsId
                    local showGoodNum       = themePart.showGoodNum
                    table.insert(needUpdateData, {goodsId = goodsId, num = showGoodNum})

                    themePart.showGoodNum = 0
                end
                CommonUtils.DrawRewards(needUpdateData)

                themeGoodInventory.unmetPartCount = 0
                themeGoodInventory.themeTotalPrice = 0

                updateThemeOwnState(themeGoodInventory.unmetPartCount, listIndex, nil, themeGoodInventory.themeParts)

                -- self:updateShopGoodPreview()
            end
        else
            local needUpdateData = {
                -- 道具 增量
                {goodsId = deltaGoodsId, num = num},
                -- 支付货币 增量
                {goodsId = currencyId, num = deltaPrice},
            }
            CommonUtils.DrawRewards(needUpdateData)

            local shopGoodListView = self.viewData.shopGoodViewData.gridView
            local data = self.currentMallData_[listIndex]
            local cell = shopGoodListView:cellAtIndex(listIndex - 1)
            if cell then
                self:updateShopGoodCell(cell.viewData, data, listIndex == self.goodCellIndex)
            end

            local goodPreviewViewData = self.viewData.goodPreviewViewData
            local ownNumLabel = goodPreviewViewData.ownNumLabel
            display.commonLabelParams(ownNumLabel, {text = string.fmt(__('已有:_num_'),{_num_ = gameMgr:GetAmountByGoodId(deltaGoodsId)})})

            -- 检查 该分类是否为 主题散件
            local themeId = data.avatarConf.theme
            if themeId ~= '' then
                local themeGoodInventory = self:GetThemeGoodInventory(themeId)
                local themeParts         = themeGoodInventory.themeParts

                local function getThemePartByGoodsId (themeParts, goodsId)
                    for i,v in ipairs(themeParts) do
                        if checkint(v.goodsId) == checkint(goodsId) then
                            return v
                        end
                    end

                end

                -- 纯更新数据
                local themePart          = getThemePartByGoodsId(themeParts, deltaGoodsId)

                updateThemeData(themeGoodInventory, themePart, deltaPrice, num)
            end
        end

        self:updateShopGoodPreview()

    elseif name == RESTAURANT_EVENTS.EVENT_AVATAR_SHOP_THEME_VISIBLE_UNREGIST then

        if self.themeInventoryPreviewViewData then
            local layer = self.themeInventoryPreviewViewData.layer
            if layer:isVisible() then
                layer:setVisible(false)
            else
                self:GetFacade():UnRegsitMediator(NAME)
            end
        else
            self:GetFacade():UnRegsitMediator(NAME)
        end
    end
end

function AvatarShopMediator:Initial( key )
	self.super.Initial(self,key)

    local viewParams = {tag = VIEW_TAG, mediatorName = NAME}
    local viewComponent  = require('Game.views.AvatarShopView').new(viewParams)
	viewComponent:setTag(VIEW_TAG)
	viewComponent:setPosition(display.center)
	self:SetViewComponent(viewComponent)

    -- local scene = uiMgr:GetCurrentScene()
    -- scene:AddDialog(viewComponent)
    self.avatarMdt_      = self:GetFacade():RetrieveMediator('AvatarMediator')
    self.avatarScene_    = self.avatarMdt_:GetViewComponent()
    self.avatarScene_:AddGameLayer(viewComponent)

    self.viewData = viewComponent.viewData
    self:initUi(viewComponent)

    -- dump(avatarThemePartsConf, 'avatarThemePartsConfavatarThemePartsConf')
end

function AvatarShopMediator:initUi(viewComponent)
    local shopTabViewData = self.viewData.shopTabViewData
    local shopGoodViewData = self.viewData.shopGoodViewData
    local shopThemeViewData = self.viewData.shopThemeViewData
    local goodPreviewViewData = self.viewData.goodPreviewViewData

    --------------------------------- 添加列表数据源  ---------------------------------
    local shopTabListView = shopTabViewData.gridView
    shopTabListView:setDataSourceAdapterScriptHandler(handler(self,self.OnShopTabDataSource))
    shopTabListView:setCountOfCell(#TAB_INFOS)
    shopTabListView:setBounceable(#TAB_INFOS > 7)
    shopTabListView:reloadData()

    local shopGoodListView = shopGoodViewData.gridView
    shopGoodListView:setDataSourceAdapterScriptHandler(handler(self,self.OnShopGoodDataSource))
    -- shopGoodListView:setBounceable(#TAB_INFOS > 7)

    local shopThemeListView = shopThemeViewData.gridView
    shopThemeListView:setDataSourceAdapterScriptHandler(handler(self,self.OnShopThemeDataSource))

    local themeDescViewData = self.viewData.themeDescViewData
    local themeCellViewData = themeDescViewData.themeCellViewData
    local themeDescListView = themeDescViewData.gridView
    themeDescListView:setDataSourceAdapterScriptHandler(handler(self,self.OnShopThemeDescDataSource))


    --------------------------------- 添加按钮 action  ---------------------------------
    local btnNum = goodPreviewViewData.btnNum
    local btnSub = goodPreviewViewData.btnSub
    local btnPlus = goodPreviewViewData.btnPlus
    local buyBtn = goodPreviewViewData.buyBtn
    local previewBtn = goodPreviewViewData.previewBtn

    btnNum:setTag(BTN_TAG.PREVIEW_BUY_GOOD_NUM)
    btnSub:setTag(BTN_TAG.PREVIEW_BUY_GOOD_SUB)
    btnPlus:setTag(BTN_TAG.PREVIEW_BUY_GOOD_PLUS)
    buyBtn:setTag(BTN_TAG.PREVIEW_BUY_GOOD)
    previewBtn:setTag(BTN_TAG.PREVIEW_THEME)

    display.commonUIParams(btnSub, {cb = handler(self, self.OnBtnAction)})
    display.commonUIParams(btnPlus, {cb = handler(self, self.OnBtnAction)})
    display.commonUIParams(buyBtn, {cb = handler(self, self.OnBtnAction)})
    display.commonUIParams(previewBtn, {cb = handler(self, self.OnBtnAction)})

end

function AvatarShopMediator:ShowShopThemeDesc()
    local shopThemeViewData = self.viewData.shopThemeViewData
    local shopThemeLayer = shopThemeViewData.layer
    shopThemeLayer:setVisible(false)

    local themeDescViewData = self.viewData.themeDescViewData
    local shopThemeDescLayer = themeDescViewData.layer
    local themeCellViewData = themeDescViewData.themeCellViewData
    local gridView = themeDescViewData.gridView
    local touchView = themeCellViewData.touchView

    self.themeGoodCellIndex = 1
    display.commonUIParams(touchView, {cb = function ()
        self.themeGoodCellIndex = -1
        -- print('HIDE ShowShopThemeDesc')
        shopThemeLayer:setVisible(true)
        shopThemeDescLayer:setVisible(false)
        self:updateShopGoodPreview(true)
    end})

    shopThemeDescLayer:setVisible(true)

    local data = self.currentMallData_[self.goodCellIndex]

    local arrow = themeCellViewData.arrow
    arrow:setVisible(true)
    self:updateThemeCell(themeCellViewData, data, true)

    local themeConf = checktable(data.themeConf)
    local themeId = checkint(themeConf.id)

    local themeGoodInventory = self:GetThemeGoodInventory(themeId)
    local themeParts         = themeGoodInventory.themeParts

    local count = #themeParts
    gridView:setBounceable(count > 3)
    gridView:setCountOfCell(count)
    gridView:reloadData()

    -- if self.themeGoodInventorys_[tostring(themeId)] == nil then
    --     self.themeGoodInventorys_[tostring(themeId)] = self:CreateThemeGoodInventory(themeId)
    -- end
    -- local themeGoodInventory = self:AddThemeGoodInventorys_(themeId)

    -- local avatarThemeParts = avatarThemePartsConf[tostring(themeId)]

        -- local avatarThemePartList = {}
        -- for i,v in pairs(avatarThemeParts) do
        --     table.insert( avatarThemePartList,{goodsId = i, num = v})
        -- end
        -- self.avatarThemePartList = avatarThemePartList
        -- local partLen = #self.avatarThemePartList

        -- print(partLen, 'partLenpartLen')

    -- gridView:setColumns(3)
end

--==============================--
--desc: 商店 TAB 数据源
--time:2017-10-17 01:45:06
--@p_convertview:
--@idx:
--@return
--==============================--
function AvatarShopMediator:OnShopTabDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateShopTabCell()
        local touchView = pCell.viewData.touchView
        display.commonUIParams(touchView, {cb = handler(self, self.OnTabAction)})
    end

    xTry(function()
        local tabData = TAB_INFOS[index]
        local avatarType = tabData.id
        pCell:setTag(index)

        local viewData = pCell.viewData
        local isSelect = self.currentAvatarType_ == avatarType
        self:updateCellSelectState(pCell.viewData, isSelect, CELL_TYPE.TAB)

        local selectImg = viewData.selectImg
        local selectLabel = viewData.selectLabel
        -- local normalImg = viewData.normalImg
        local normalLabel = viewData.normalLabel

        local redPointIcon = viewData.redPointIcon
        local avatarCacheRestaurantNew = gameMgr:GetUserInfo().avatarCacheRestaurantNews[tostring(avatarType)]
        -- print('avatarCacheRestaurantNew', avatarCacheRestaurantNew ~= nil)
        redPointIcon:setVisible(avatarCacheRestaurantNew ~= nil)

        selectImg:setTexture(tabData.image)
        -- normalImg:setTexture(tabData.image)

        display.commonLabelParams(selectLabel, {text = tabData.name})
        display.commonLabelParams(normalLabel, {text = tabData.name})

	end,__G__TRACKBACK__)
    return pCell
end

--==============================--
--desc: 商店道具 数据源
--time:2017-10-17 05:21:31
--@p_convertview:
--@idx:
--@return
--==============================--
function AvatarShopMediator:OnShopGoodDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateShopGoodCell()
        local bg = pCell.viewData.bg
        display.commonUIParams(bg, {cb = handler(self, self.OnShopGoodCellAction)})
    end

    xTry(function()
        pCell:setTag(index)
        local viewData    = pCell.viewData
        local data = self.currentMallData_[index]
        local isSelect = self.goodCellIndex == index

        self:updateShopGoodCell(viewData, data, isSelect)

        if self.isFirstInitGood_ then
            self.isControllable_ = false
            viewData.layer:setPosition(cc.p(self.viewData.view:getContentSize().width, -self.viewData.view:getContentSize().height))
            viewData.layer:runAction(cc.Sequence:create({
                cc.DelayTime:create(index * 0.05),
                cc.MoveTo:create(0.2, viewData.layerPos),
            }))
        else
            viewData.layer:stopAllActions()
            viewData.layer:setPosition(viewData.layerPos)
        end

	end,__G__TRACKBACK__)
    return pCell
end

function AvatarShopMediator:OnShopThemeDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateShopThemeCell()
        local touchView = pCell.viewData.touchView
        display.commonUIParams(touchView, {cb = handler(self, self.OnShopGoodCellAction)})
    end

    xTry(function()
        pCell:setTag(index)
        local viewData    = pCell.viewData
        local data = self.currentMallData_[index]
        local isSelect = self.goodCellIndex == index

        self:updateThemeCell(viewData, data, isSelect)

        if self.isFirstInitTheme_ then
            self.isControllable_ = false
            local originalPos = cc.p(viewData.layer:getPosition())
            viewData.layer:setPositionY(-self.viewData.view:getContentSize().height)
            viewData.layer:runAction(cc.Sequence:create({
                cc.DelayTime:create(index * 0.1),
                cc.MoveTo:create(0.2, viewData.layerPos)
            }))
        else
            viewData.layer:stopAllActions()
            viewData.layer:setPosition(viewData.layerPos)
        end

	end,__G__TRACKBACK__)
    return pCell
end

function AvatarShopMediator:OnShopThemeDescDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateShopGoodCell(self.currentAvatarType_)
        local bg = pCell.viewData.bg
        display.commonUIParams(bg, {cb = handler(self, self.OnShopGoodCellAction)})
    end

    xTry(function()
        pCell:setTag(index)
        local viewData    = pCell.viewData
        -- local data = self.currentMallData_[self.goodCellIndex]
        local isSelect = self.themeGoodCellIndex == index

        -- local avatarData = self:getThemeDescGoodData(data, index)
        -- -- dump(avatarData)
        local themeGoodInventory = self:GetThemeGoodInventory()
        local themeParts         = themeGoodInventory.themeParts
        local themeGoodData      = themeParts[index] or {}
        self:updateShopGoodCell(viewData, themeGoodData, isSelect)

	end,__G__TRACKBACK__)
    return pCell
end

function AvatarShopMediator:OnThemeInventoryDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateShopThemeInventoryCell()
    end

    xTry(function()
        local themeGoodInventory = self:GetThemeGoodInventory()
        local themeParts         = themeGoodInventory.themeParts
        local data               = themeParts[index]

        local showGoodNum = data.showGoodNum
        local avatarConf = data.avatarConf

        local viewData = pCell.viewData
        local goodNameLabel = viewData.goodNameLabel
        local goodNumLabel = viewData.goodNumLabel

        display.commonLabelParams(goodNameLabel, {text = tostring(avatarConf.name) ,reqW  = 150})
        local text = showGoodNum == 0 and __('已满足') or string.format("x%s", tostring(showGoodNum))
        display.commonLabelParams(goodNumLabel, {text = text , reqW = 80 })
	end,__G__TRACKBACK__)
    return pCell
end


function AvatarShopMediator:OnBtnAction(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local tag = sender:getTag()
    -- print('tag = ', tag)
    -- 减道具数
    if tag == BTN_TAG.PREVIEW_BUY_GOOD_SUB then
        if self.selectNum <= 1 then
            return
        end
        self.selectNum = self.selectNum - 1
        self:updatePreviewPrice()
    -- 加道具数
    elseif tag == BTN_TAG.PREVIEW_BUY_GOOD_PLUS then
        -- 1. 获取拥有的道具个数
        local goodsId = nil
        local maxOwnNum = 0
        local data = self.currentMallData_[self.goodCellIndex]
        local name = ''
        if self.currentAvatarType_ == RESTAURANT_AVATAR_TYPE.THEME then
            local mallConf = data.mallConf
            goodsId = mallConf.id
            if self:CheckIsShowThemeDesc() then
                local themeDescGoodData = self:getThemeDescGoodData(data, self.themeGoodCellIndex)
                maxOwnNum = checkint(themeDescGoodData.max)
            else
                local avatarThemeGood = avatarThemeGoodConf[tostring(goodsId)] or {}
                maxOwnNum = checkint(avatarThemeGood.max)
            end
        else
            local avatarConf = data.avatarConf
            goodsId = checkint(avatarConf.id)
            maxOwnNum = checkint(avatarConf.max)
            name = tostring(avatarConf.name)
        end
        -- 2. 检查是否达到 最大拥有个数
        local ownNum = checkint(gameMgr:GetAmountByGoodId(goodsId))
        local isMax = self:CheckIsMaxNum(goodsId, maxOwnNum, name)
        -- 3. 计算 能购买的最大个数
        if not isMax then
            local maxBuyCount = maxOwnNum - ownNum
            if self.selectNum >= maxBuyCount then
                uiMgr:ShowInformationTips(string.fmt(__('_name_最多购买_num_个'),{_name_ = name, _num_ = maxBuyCount}))
                return
            end
            self.selectNum = self.selectNum + 1
            self:updatePreviewPrice()
        end
    -- 购买道具
    elseif  tag == BTN_TAG.PREVIEW_BUY_GOOD
         or tag == BTN_TAG.PREVIEW_BUY_THEME then

        local data = self.currentMallData_[self.goodCellIndex]
        local productId = data.productId
        local discontData = data.discontData
        -- 1. 是否为 购买主题
        local isShowThemeDesc = self:CheckIsShowThemeDesc()
        local isTheme = self.currentAvatarType_ == RESTAURANT_AVATAR_TYPE.THEME
        local currencyId = nil
        local totalPrice = nil
        local buyData    = nil
        local goodsId    = nil
        local themeId    = nil
        local themeListIndex = nil
        local realDiscontRate = nil
        local listIndex = nil
        local name = ''
        if isTheme then
            -- 1. 购买主题
            -- print('buy theme', productId)
            -- dump(data)

            local themeConf          = data.themeConf
            themeId                  = themeConf.id
            local themeGoodInventory = self:GetThemeGoodInventory(themeId)
            -- 检查是否是购买主题散件
            if isShowThemeDesc then
                -- print('buy theme part')
                local themeParts         = themeGoodInventory.themeParts
                local themePart          = themeParts[self.themeGoodCellIndex]
                listIndex          = self.themeGoodCellIndex

                local avatarConf         = themePart.avatarConf
                local mallConf           = themePart.mallConf
                productId                = themePart.productId

                local maxOwnNum         = checkint(avatarConf.max)
                name                    = tostring(avatarConf.name)
                goodsId                 = checkint(avatarConf.id)

                -- 检查是否达到道具最大拥有数
                if self:IsGoodMaxOwnCount(goodsId, maxOwnNum, name) then return end

                local payPrice          = checkint(mallConf.price)
                currencyId              = checkint(mallConf.currency)
                totalPrice              = payPrice * self.selectNum
                themeListIndex          = self.goodCellIndex
            else
                -- 购买全套主题
                if discontData then
                    realDiscontRate = checkint(discontData.discount)
                elseif isTheme then
                    realDiscontRate = (themeConf.themeDiscount * 100) or WHOLE_THEME_DISCOUNT
                end
                listIndex = self.goodCellIndex
                local unmetPartCount     = checkint(themeGoodInventory.unmetPartCount)
                if unmetPartCount == 0 then
                    uiMgr:ShowInformationTips(__('已拥有该主题'))
                    return
                end
                -- dump(themeGoodInventory)
                goodsId            = themeId
                currencyId         = checkint(themeGoodInventory.currency)
                totalPrice         = checkint(themeGoodInventory.themeTotalPrice) * realDiscontRate / 100
                name = tostring(themeConf.name)
            end

        else
        -- 2. 购买分类道具
            local avatarConf  = data.avatarConf
            local mallConf    = data.mallConf
            listIndex         = self.goodCellIndex

            goodsId                 = checkint(avatarConf.id)
            local maxOwnNum         = checkint(avatarConf.max)
            name                    = tostring(avatarConf.name)
            local payPrice          = checkint(mallConf.price)
            currencyId              = checkint(mallConf.currency)

            -- 检查是否达到道具最大拥有数
            if self:IsGoodMaxOwnCount(goodsId, maxOwnNum, name) then return end

            totalPrice = payPrice * self.selectNum

        end
        -- 3. 检查货币是否满足
        if GAME_MODULE_OPEN.NEW_STORE and currencyId == DIAMOND_ID then
            if app.uiMgr:showDiamonTips(totalPrice) then return end
        else
            if self:IsCurrencyAdequate(currencyId, totalPrice) then return end
        end

        local showThemeParts = isShowThemeDesc and 1 or 0
        buyData = {
            productId = productId,
            num = self.selectNum,
            currencyId = currencyId,
            deltaGoodsId = goodsId,
            deltaPrice = -totalPrice,
            realDiscontRate = realDiscontRate,
            listIndex = listIndex,
            themeListIndex = themeListIndex,
            themeId = themeId,
            showThemeParts = showThemeParts
        }
        
        -- 请求购买道具
        local buyCallBack = function ()
            self:SendSignal(COMMANDS.COMMANDS_SHOP_AVATAR_BUYAVATAR, buyData)
        end

        if checkint(currencyId) == DIAMOND_ID then
            local CommonTip  = require( 'common.NewCommonTip' ).new({text = string.fmt(__('是否花费_num1_幻晶石购买_name__num2_个'), {['_num1_'] = totalPrice, ['_name_'] = name, ['_num2_'] = self.selectNum}),
            isOnlyOK = false, callback = buyCallBack})
            CommonTip:setPosition(display.center)
            local scene = uiMgr:GetCurrentScene()
            scene:AddDialog(CommonTip)
        else
            buyCallBack()
        end
        
        -- self:GetFacade():DispatchObservers(SIGNALNAMES.SHOP_AVATAR_BUYAVATAR_CALLBACK, {requestData = buyData})

    elseif tag == BTN_TAG.PREVIEW_THEME then
        local layer = nil

        local data = self.currentMallData_[self.goodCellIndex]
        local themeConf = checktable(data.themeConf)
        local themeId = checkint(themeConf.id)
        -- self:AddThemeGoodInventorys_(themeId)

        if self.themeInventoryPreviewViewData then
            layer = self.themeInventoryPreviewViewData.layer
            layer:setVisible(true)
            self:updateThemeInventoryPreview()
            return
        end

        local viewComponent = self:GetViewComponent()

        local themeInventoryPreviewViewData = viewComponent:CreateShopThemeInventoryPreviewLayer()
        layer = themeInventoryPreviewViewData.layer
        display.commonUIParams(layer, {po = utils.getLocalCenter(viewComponent)})
        viewComponent:addChild(layer)

        local gridView = themeInventoryPreviewViewData.gridView
        gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnThemeInventoryDataSource))
        -- gridView:setCountOfCell(5)
        -- gridView:setBounceable(false)
        -- gridView:reloadData()

        local buyBtn = themeInventoryPreviewViewData.buyBtn
        buyBtn:setTag(BTN_TAG.PREVIEW_BUY_THEME)
        display.commonUIParams(buyBtn, {cb = handler(self, self.OnBtnAction)})
        self.themeInventoryPreviewViewData = themeInventoryPreviewViewData
        self:updateThemeInventoryPreview()
    -- elseif tag == BTN_TAG.PREVIEW_BUY_THEME then

    end
end

function AvatarShopMediator:updateCellSelectState(viewData, isSelect, cellType)
    if cellType == CELL_TYPE.TAB then
        local normalLayer = viewData.normalLayer
        local selectLayer = viewData.selectLayer
        normalLayer:setVisible(not isSelect)
        selectLayer:setVisible(isSelect)
    elseif cellType == CELL_TYPE.SHOP_GOOD then
        local goodFrame = viewData.goodFrame
        goodFrame:setVisible(isSelect)
    elseif cellType == CELL_TYPE.SHOP_THEME then
        local themeFrame = viewData.themeFrame
        themeFrame:setVisible(isSelect)
    end
end

function AvatarShopMediator:updateShopListLayer()

    -- 1. 第一次进入 根据 avatarType 判断 add  数据源
    -- 2. 不是第一次进入
    --    2.1 上一个选择的标签 如果是主题的话 或 这次要选择 主题的话 则 改变 数据源
    --    2.2  否则 只是 reload

    local shopGoodViewData = self.viewData.shopGoodViewData
    local shopThemeViewData = self.viewData.shopThemeViewData
    local shopGoodLayer = shopGoodViewData.layer
    local shopThemeLayer = shopThemeViewData.layer
    local gridView = nil
    local isBounceable = nil

    local isTheme = self.currentAvatarType_ == RESTAURANT_AVATAR_TYPE.THEME

    shopGoodLayer:setVisible(not isTheme)
    shopThemeLayer:setVisible(isTheme)

    if isTheme then
        local data = self.currentMallData_[self.goodCellIndex]
        local themeConf = checktable(data.themeConf)
        local themeId = checkint(themeConf.id)
        -- print(themeId)
        -- self:AddThemeGoodInventorys_(themeId)

        -- print('Refresh theme data source')
        gridView = shopThemeViewData.gridView
        isBounceable = #self.currentMallData_ > 3
    else
        -- print('Refresh good data source')
        gridView = shopGoodViewData.gridView
        isBounceable = #self.currentMallData_ > 6
    end

    gridView:setBounceable(isBounceable)
    gridView:setCountOfCell(#self.currentMallData_)
    gridView:reloadData()

    if self.isFirstInitTheme_ then
        self.isControllable_ = true
        self.isFirstInitTheme_ = false
    end

    if self.isFirstInitGood_ then
        self.isControllable_ = true
        self.isFirstInitGood_ = false
    end
end

function AvatarShopMediator:updateShopGoodPreview(showDesc)
    local goodPreviewViewData = self.viewData.goodPreviewViewData
    local descLabel = goodPreviewViewData.descLabel
    local previewBgLayer = goodPreviewViewData.previewBgLayer
    local previewAttibute = goodPreviewViewData.previewAttibute
    local soldLayer = goodPreviewViewData.soldLayer
    local titleLabel = goodPreviewViewData.titleLabel
    local buyBtn = goodPreviewViewData.buyBtn
    local previewThemeBgLayer = goodPreviewViewData.previewThemeBgLayer

    local saleNumBg = goodPreviewViewData.saleNumBg
    local discountPriceLayer = goodPreviewViewData.discountPriceLayer
    local originalPriceLayer = goodPreviewViewData.originalPriceLayer

    local presentPriceBgLayer = goodPreviewViewData.presentPriceBgLayer
    local discountPriceBgLayer = goodPreviewViewData.discountPriceBgLayer
    -- local totalPriceLabel = goodPreviewViewData.totalPriceLabel
    -- local totalPriceNum = goodPreviewViewData.totalPriceNum
    -- local castIcon = goodPreviewViewData.castIcon

    -- local saleNumBgSize = goodPreviewViewData.saleNumBgSize

    -- presentPriceBgLayer:setVisible(false)
    -- discountPriceBgLayer:setVisible(false)
    local data = self.currentMallData_[self.goodCellIndex]
    local mallConf = data.mallConf           -- 常住道具 相关配置
    local activityConf = data.activityConf   -- 限时道具 相关配置
    local discontData = data.discontData
    local name = nil
    local unitPrice = 0   -- 单价
    local currencyId = 900001

    if mallConf then
        unitPrice = checkint(mallConf.price)
        currencyId = mallConf.currency
    elseif activityConf then
        unitPrice = checkint(activityConf.price)
        currencyId = activityConf.currency
    end

    local showThemeDesc = self:CheckIsShowThemeDesc()
    local isTheme = self.currentAvatarType_ == RESTAURANT_AVATAR_TYPE.THEME and not showThemeDesc or checkbool(showDesc)
    previewThemeBgLayer:setVisible(isTheme)
    previewBgLayer:setVisible(not isTheme)
    soldLayer:setVisible(not isTheme)

    local isDiscont = isTheme or discontData ~= nil  -- 用于判断是否是折扣


    if isTheme then
        local themeConf = checktable(data.themeConf)
        local desc = themeConf.descr
        local themeId = checkint(themeConf.id)
        name = themeConf.name
        self:updateThemeDesc(goodPreviewViewData, desc)

        display.commonLabelParams(buyBtn, {text = __('全套购买')})

        local themeGoodInventory = self:GetThemeGoodInventory(themeId)

        -- 购买主题
        unitPrice = themeGoodInventory.themeTotalPrice
        currencyId = themeGoodInventory.currency
    else
        display.commonLabelParams(buyBtn, {text = __('购买')})
        local goodsId = nil
        local buffType = {}
        if showThemeDesc then
            -- dump(mallConf, 'mallConf')
            -- local data = self.currentMallData_[self.goodCellIndex]
            -- dump(data, self.goodCellIndex)
            -- local avatarConf = checktable(self:getThemeDescGoodData(data, self.themeGoodCellIndex))
            local themeConf = checktable(data.themeConf)
            -- dump(data)
            local themeId = checkint(themeConf.id)
            local themeGoodInventory = self:GetThemeGoodInventory(themeId)
            local themeParts         = themeGoodInventory.themeParts
            local themeGoodData      = themeParts[self.themeGoodCellIndex] or {}

            local avatarConf = themeGoodData.avatarConf or {}
            local mallConf = themeGoodData.mallConf

            goodsId = checkint(avatarConf.id)
            name = avatarConf.name

            unitPrice = checkint(mallConf.price)
            currencyId = mallConf.currency
            buffType = avatarConf.buffType
        else
            local avatarConf = data.avatarConf
            goodsId = checkint(avatarConf.id)
            name = avatarConf.name
            buffType = avatarConf.buffType
        end
        
        local buffDesc = RestaurantUtils.GetBuffDescByAvatarId(goodsId)
        display.commonLabelParams(previewAttibute, fontWithColor(5, {text = buffDesc, w = 280, hAlign = display.TAC}))
        local buffDescSize = display.getLabelContentSize(previewAttibute:getLabel())
        previewAttibute:setContentSize(cc.size(previewAttibute:getContentSize().width, buffDescSize.height + 6))
        -- previewAttibute
        local goodIconLayer = goodPreviewViewData.goodIconLayer
        -- print(goodsId, 'goodsIdgoodsIdgoodsId')
        self:GetViewComponent():CreateGoodIcon(goodIconLayer, goodsId)

        local ownNumLabel = goodPreviewViewData.ownNumLabel
        display.commonLabelParams(ownNumLabel, {text = string.fmt(__('已有:_num_'),{_num_ = gameMgr:GetAmountByGoodId(goodsId)})})
        local ownNumBg = goodPreviewViewData.ownNumBg
        local ownNumLabelSize = display.getLabelContentSize(ownNumLabel)
        ownNumBg:setContentSize(ownNumLabelSize)
        ownNumLabel:setPosition(ownNumLabelSize.width/2 , ownNumLabelSize.height/2)
    end

    saleNumBg:setVisible(not isTheme)
    originalPriceLayer:setVisible(not isTheme)
    presentPriceBgLayer:setVisible(isTheme and unitPrice ~= 0)
    -- discountPriceBgLayer:setVisible(isTheme and )
    if unitPrice == 0 then
        display.commonLabelParams(buyBtn, {text = __('已拥有')})
    end

    display.commonLabelParams(titleLabel, {text = tostring(name ) , reqW = 300 })

    local realDiscontRate = nil
    if discontData then
        realDiscontRate = checkint(discontData.discount)
    elseif isTheme then
        local themeConf = checktable(data.themeConf)
        realDiscontRate = (themeConf.themeDiscount * 100) or WHOLE_THEME_DISCOUNT
    end
    self:updatePreviewPrice(unitPrice, currencyId, isTheme, realDiscontRate)

    -- display.commonLabelParams(totalPriceNum, {text = tostring(unitPrice)})
    -- castIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(checkint(currencyId))))

    -- local totalPriceNumSize = totalPriceNum:getContentSize()
    -- totalPriceLabel:setPosition(cc.p(saleNumBgSize.width / 2 - totalPriceNumSize.width / 2, saleNumBgSize.height / 2))
    -- totalPriceNum:setPosition(cc.p(saleNumBgSize.width / 2, saleNumBgSize.height / 2))
    -- castIcon:setPosition(cc.p(saleNumBgSize.width / 2 + totalPriceNumSize.width / 2, saleNumBgSize.height / 2))


end

function AvatarShopMediator:updateCurrentMallData(avatarType)
    if avatarType then
        self.currentAvatarType_ = avatarType
    end

    if self.currentAvatarType_ == RESTAURANT_AVATAR_TYPE.THEME then
        self.currentMallData_ = self.avatarMallThemeData_ or {}
    else
        self.currentMallData_  = self.avatarMallDataMap_[tostring(self.currentAvatarType_)] or {}
    end

end

function AvatarShopMediator:updatePreviewPrice(unitPrice, currencyId, isTheme, realDiscontRate)
    if unitPrice then
        self.unitPrice_ = unitPrice
    end

    local goodPreviewViewData = self.viewData.goodPreviewViewData

    if realDiscontRate ~= nil then
        -- local originalPriceNumLabel = goodPreviewViewData.originalPriceNumLabel
        -- local discountLine = goodPreviewViewData.discountLine
        -- local discountCastIcon = goodPreviewViewData.discountCastIcon
        -- local presentPriceNumLabel = goodPreviewViewData.presentPriceNumLabel
        -- local presentCastIcon = goodPreviewViewData.presentCastIcon

        -- display.commonLabelParams(originalPriceNumLabel, {text = tostring(self.unitPrice_)})

        -- local originalPriceNumLabelSize = display.getLabelContentSize(originalPriceNumLabel)
        -- local discountLineSize = cc.size(originalPriceNumLabelSize.width + 2, 2)
        -- discountLine:setContentSize(discountLineSize)
        -- discountLine:setPositionX(originalPriceNumLabel:getPositionX() + originalPriceNumLabelSize.width / 2)

        -- presentPriceNumLabel:setString(realDiscontRate / 100 * self.unitPrice_)
        -- local presentPriceNumLabelSize = presentPriceNumLabel:getContentSize()

        -- if currencyId then
        --     discountCastIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(checkint(currencyId))))
        --     discountCastIcon:setPositionX(originalPriceNumLabel:getPositionX() + discountLineSize.width)

        --     presentCastIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(checkint(currencyId))))
        --     presentCastIcon:setPositionX(presentPriceNumLabel:getPositionX() +  presentPriceNumLabelSize.width + 2)
        -- end

        local discountPriceNum = goodPreviewViewData.discountPriceNum
        local discountCastIcon = goodPreviewViewData.discountCastIcon
        local discountLine = goodPreviewViewData.discountLine
        local presentPriceNum = goodPreviewViewData.presentPriceNum
        local presentCastIcon = goodPreviewViewData.presentCastIcon

        display.commonLabelParams(discountPriceNum, {text = tostring(self.unitPrice_)})
        discountCastIcon:setTexture(CommonUtils.GetGoodsIconPathById(currencyId))

        local discountPriceNumSize = display.getLabelContentSize(discountPriceNum)
        local discountCastIconSize = discountCastIcon:getContentSize()
        local discountLineSize = cc.size(discountPriceNumSize.width + 2, 2)
        discountLine:setContentSize(discountLineSize)

        -- discountPriceNum:setPositionX(discountPriceBgSize.width / 2 - discountCastIconSize.width / 2 * 0.2 - 2)
        discountCastIcon:setPositionX(discountPriceNum:getPositionX() + discountPriceNumSize.width + 2)
        discountLine:setPosition(discountPriceNum:getPositionX() + discountPriceNumSize.width / 2, discountPriceNum:getPositionY() + discountPriceNumSize.height / 2)

        presentPriceNum:setString(realDiscontRate / 100 * self.unitPrice_)
        presentCastIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(checkint(currencyId))))

        presentCastIcon:setPositionX(presentPriceNum:getPositionX() + presentPriceNum:getContentSize().width + 2)

    else
        local btnNum = goodPreviewViewData.btnNum
        local castIcon = goodPreviewViewData.castIcon
        local totalPriceNum = goodPreviewViewData.totalPriceNum
        local totalPriceLabel = goodPreviewViewData.totalPriceLabel

        local saleNumBgSize = goodPreviewViewData.saleNumBgSize

        display.commonLabelParams(btnNum, {text = tostring(self.selectNum)})

        local totalPrice = self.unitPrice_ * checkint(self.selectNum)

        display.commonLabelParams(totalPriceNum, {text = tostring(totalPrice)})
        if currencyId then
            castIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(checkint(currencyId))))
        end

        local totalPriceNumSize = totalPriceNum:getContentSize()
        totalPriceLabel:setPosition(cc.p(saleNumBgSize.width / 2 - totalPriceNumSize.width / 2, saleNumBgSize.height / 2))
        totalPriceNum:setPosition(cc.p(saleNumBgSize.width / 2, saleNumBgSize.height / 2))
        castIcon:setPosition(cc.p(saleNumBgSize.width / 2 + totalPriceNumSize.width / 2, saleNumBgSize.height / 2))
    end
end

function AvatarShopMediator:updateThemeCell(viewData, data, isSelect)

    local titleLabel = viewData.titleLabel
    local titleBg = viewData.titleBg
    local lockBg = viewData.lockBg
    local themeImg = viewData.themeImg
    local ownBg = viewData.ownBg
    local discountRateLabel = viewData.discountRateLabel
    local discountRateBg = viewData.discountRateBg

    local themeConf = checktable(data.themeConf)
    local openRestaurantLevel = checkint(themeConf.openRestaurantLevel)
    local name = tostring(themeConf.name)

    themeImg:setTexture(CommonUtils.GetGoodsIconPathById(themeConf.id))

    self:updateCellSelectState(viewData, isSelect, CELL_TYPE.SHOP_THEME)

    if self:CheckAvatarLockLevel(themeConf.openRestaurantLevel) then
        local lockLabel = viewData.lockLabel
        lockBg:setVisible(true)
        display.commonLabelParams(lockLabel, {text = string.fmt(__('餐厅_num_级解锁'),{_num_ = openRestaurantLevel})})
    else
        lockBg:setVisible(false)
    end

    local themeId = checkint(themeConf.id)
    local themeGoodInventory = self:GetThemeGoodInventory(themeId)

    local unmetPartCount = themeGoodInventory.unmetPartCount
    ownBg:setVisible(unmetPartCount == 0)

    display.commonLabelParams(titleLabel, {text = name})
    local tWidth = display.getLabelContentSize(titleLabel).width
    titleBg:setContentSize(cc.size(tWidth + 60, 38))

    local discontData = data.discontData
    local discontRate = (themeConf.themeDiscount * 100) or WHOLE_THEME_DISCOUNT
    if discontData then
        discontRate = discontData.discount
    end
    discountRateBg:setVisible(discontRate ~= 100)
    display.commonLabelParams(discountRateLabel, {text = string.fmt(__('_num_折'),{_num_ = CommonUtils.GetDiscountOffFromCN(discontRate)})})
    local discountRateLabelSize = display.getLabelContentSize(discountRateLabel)
    local discountRateBgSize  = discountRateBg:getContentSize()
    if discountRateLabelSize.width +20 > discountRateBgSize.width then
        discountRateBg:setContentSize(cc.size(discountRateLabelSize.width +20 , discountRateBgSize.height))
    end

end

-- gameMgr:GetUserInfo().avatarCacheRestaurantNews
function AvatarShopMediator:updateShopGoodCell(viewData, data, isSelect)
    local bg          = viewData.bg
    local ownNumLabel = viewData.ownNumLabel
    local goodIcon    = viewData.goodIcon
    local goodName    = viewData.goodName
    local priceNum    = viewData.priceNum
    local castIcon    = viewData.castIcon

    local priceLayer  = viewData.priceLayer
    local lockIcon    = viewData.lockIcon

    local newIcon     = viewData.newIcon

    local bgSize      = viewData.bgSize

    -- local isTheme = themeGoodData ~= nil
    local avatarInfo = checktable(data.avatarConf)
    local goodsId = checkint(avatarInfo.id)
    local openRestaurantLevel = checkint(avatarInfo.openRestaurantLevel)

    -- self:updateNewState(viewData, isTheme)
    local avatarCacheRestaurantNew = gameMgr:GetUserInfo().avatarCacheRestaurantNews[tostring(self.currentAvatarType_)]
    if avatarCacheRestaurantNew then
        newIcon:setVisible(checkbool(avatarCacheRestaurantNew[tostring(data.productId)]))
    end

    -- goodIcon
    local ownNum = checkint(gameMgr:GetAmountByGoodId(goodsId))
    ownNumLabel:setVisible(ownNum > 0)
    if ownNum > 0 then
        display.commonLabelParams(ownNumLabel, {text = string.format(__('拥有:%s'), ownNum)})
    end

    goodIcon:setVisible(true)
    goodIcon:setTexture(AssetsUtils.GetRestaurantSmallAvatarPath(goodsId))

    display.commonLabelParams(goodName, {text = tostring(avatarInfo.name) ,w = 175 , hAlign = display.TAC})

    -- 限时道具
    if data.activityConf then

    else
        local mallConf = data.mallConf
        display.commonLabelParams(priceNum, {text = tostring(mallConf.price)})
        castIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(checkint(mallConf.currency))))
    end
    local priceNumSize = priceNum:getContentSize()
    local castIconSize = castIcon:getContentSize()
    priceNum:setPosition(cc.p(bgSize.width / 2 - castIconSize.width / 2 * 0.2, bgSize.height * 0.1))
    castIcon:setPosition(cc.p(bgSize.width / 2 + priceNumSize.width / 2, bgSize.height * 0.1))

    if self:CheckAvatarLockLevel(openRestaurantLevel) then
        bg:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))
        bg:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_sellout.png'))
        goodIcon:setOpacity(100)
        priceLayer:setVisible(false)
        lockIcon:setVisible(true)
        self:updateCellSelectState(viewData, false, CELL_TYPE.SHOP_GOOD)
    else
        bg:setNormalImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
        bg:setSelectedImage(_res('ui/home/commonShop/shop_btn_goods_default.png'))
        goodIcon:setOpacity(255)
        priceLayer:setVisible(true)
        lockIcon:setVisible(false)
        self:updateCellSelectState(viewData, isSelect, CELL_TYPE.SHOP_GOOD)
    end
end

function AvatarShopMediator:updateNewState(viewData, index)
    local newIcon                  = viewData.newIcon
    local avatarCacheRestaurantNew = gameMgr:GetUserInfo().avatarCacheRestaurantNews[tostring(self.currentAvatarType_)]
    -- print('OnShopGoodCellAction', self.currentAvatarType_)
    -- dump(avatarCacheRestaurantNew)
    if avatarCacheRestaurantNew then

        local data = self.currentMallData_[index]
        local productId = tostring(data.productId)
        avatarCacheRestaurantNew[productId] = nil
        if table.nums(avatarCacheRestaurantNew) <= 0 then
            gameMgr:GetUserInfo().avatarCacheRestaurantNews[tostring(self.currentAvatarType_)] = nil

            -- 更新 Tab 状态
            local gridView = self.viewData.shopTabViewData.gridView
            local tabIndex = getTabIndexByType(self.currentAvatarType_)
            local tabCell = gridView:cellAtIndex(tabIndex - 1)
            if tabCell then
                local redPointIcon = tabCell.viewData.redPointIcon
                if redPointIcon then
                    redPointIcon:setVisible(false)
                end
            end
        end
        -- dump(gameMgr:GetUserInfo().avatarCacheRestaurantNews[tostring(self.currentAvatarType_)])
        newIcon:setVisible(false)
    end
end

function AvatarShopMediator:updateThemeDesc(goodPreviewViewData, desc)
    local descLabel = goodPreviewViewData.descLabel
    display.commonLabelParams(descLabel, {text = tostring(desc)})

    local descrContainer = goodPreviewViewData.descrContainer
    local descrScrollTop = descrContainer:getViewSize().height - display.getLabelContentSize(descLabel).height
	descrContainer:setContentOffset(cc.p(0, descrScrollTop))
end

function AvatarShopMediator:updateThemeInventoryPreview(themeIndex)
    local themeInventoryPreviewViewData = self.themeInventoryPreviewViewData
    local themeImg = themeInventoryPreviewViewData.themeImg
    local themeName = themeInventoryPreviewViewData.themeName

    local data = self.currentMallData_[themeIndex or self.goodCellIndex] or {}
    local themeConf = data.themeConf or {}
    local themeId = themeConf.id
    themeImg:setTexture(CommonUtils.GetGoodsIconPathById(themeId, true))
    display.commonLabelParams(themeName, {text = tostring(themeConf.name)})

    -- local themeGoodInventory = self:CreateThemeGoodInventory(themeId)

    -- local x = self:GetThemeGoodInventory()
    -- dump(data)
    local gridView = themeInventoryPreviewViewData.gridView
    local themeGoodInventory = self:GetThemeGoodInventory(themeId)
    local partCount = #themeGoodInventory.themeParts
    gridView:setCountOfCell(partCount)
    gridView:setBounceable(partCount > 8)
    gridView:reloadData()

    local discontData = data.discontData
    local discontRate = (themeConf.themeDiscount * 100) or WHOLE_THEME_DISCOUNT
    if discontData then
        discontRate = checkint(discontData.discont)
    end
    local isDiscont = discontRate ~= nil
    -- local totalPriceNum = themeInventoryPreviewViewData.totalPriceNum
    -- local castIcon = themeInventoryPreviewViewData.castIcon

    local themePrice = checkint(themeGoodInventory.themeTotalPrice)
    local themeCurrencyId = checkint(themeGoodInventory.currency)
    local unmetPartCount = themeGoodInventory.unmetPartCount

    local isOwnTheme = unmetPartCount == 0

    local buyBtn = themeInventoryPreviewViewData.buyBtn

    local discountPriceBgLayer = themeInventoryPreviewViewData.discountPriceBgLayer
    local presentPriceBgLayer = themeInventoryPreviewViewData.presentPriceBgLayer

    local presentPriceNum = themeInventoryPreviewViewData.presentPriceNum
    local presentCastIcon = themeInventoryPreviewViewData.presentCastIcon

    local presentPriceBgSize = themeInventoryPreviewViewData.presentPriceBgSize
    local discountPriceBgSize = themeInventoryPreviewViewData.discountPriceBgSize

    discountPriceBgLayer:setVisible(isDiscont)
    presentPriceBgLayer:setVisible(not isOwnTheme)

    local btnTipText = isOwnTheme and __('已拥有') or __('购买')
    display.commonLabelParams(buyBtn, {text = btnTipText})

    local realThemePrice = themePrice
    if isDiscont then
        local discountPriceNum     = themeInventoryPreviewViewData.discountPriceNum
        local discountCastIcon     = themeInventoryPreviewViewData.discountCastIcon
        local discountLine         = themeInventoryPreviewViewData.discountLine

        local discountPriceBgSize  = themeInventoryPreviewViewData.discountPriceBgSize

        display.commonLabelParams(discountPriceNum, {text = themePrice})
        discountCastIcon:setTexture(CommonUtils.GetGoodsIconPathById(themeCurrencyId))

        local discountPriceNumSize = display.getLabelContentSize(discountPriceNum)
        local discountCastIconSize = discountCastIcon:getContentSize()
        local discountLineSize = cc.size(discountPriceNumSize.width + 2, 2)
        discountLine:setContentSize(discountLineSize)

        -- discountPriceNum:setPositionX(discountPriceBgSize.width / 2 - discountCastIconSize.width / 2 * 0.2 - 2)
        discountCastIcon:setPositionX(discountPriceNum:getPositionX() + discountPriceNumSize.width + 2)
        discountLine:setPosition(discountPriceNum:getPositionX() + discountPriceNumSize.width / 2, discountPriceNum:getPositionY() + discountPriceNumSize.height / 2)

        realThemePrice = realThemePrice * discontRate / 100
    end

    display.commonLabelParams(presentPriceNum, {text = realThemePrice})
    presentCastIcon:setTexture(CommonUtils.GetGoodsIconPathById(themeCurrencyId))

    local presentPriceNumSize = presentPriceNum:getContentSize()
    local presentCastIconSize = presentCastIcon:getContentSize()

    -- presentPriceNum:setPositionX()
    presentCastIcon:setPositionX(presentPriceNum:getPositionX() + presentPriceNumSize.width)

end

function AvatarShopMediator:EnterLayer()
    self:SendSignal(COMMANDS.COMMANDS_SHOP_AVATAR)
end

function AvatarShopMediator:OnTabAction(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local cell = sender:getParent():getParent()
    local index = cell:getTag()
    local avatarType = checkint(TAB_INFOS[index].id)
    if self.currentAvatarType_ == avatarType then return end

    if self.viewData.themeDescViewData.layer:isVisible() then
        -- local themeDescViewData = self.viewData.themeDescViewData
        -- local shopThemeDescLayer = themeDescViewData.layer
        -- local themeCellViewData = themeDescViewData.themeCellViewData
        -- shopThemeLayer:setVisible(false)
        self.themeGoodCellIndex = -1

        local shopThemeViewData = self.viewData.shopThemeViewData
        local shopThemeLayer = shopThemeViewData.layer
        shopThemeLayer:setVisible(false)

        local themeDescViewData = self.viewData.themeDescViewData
        local shopThemeDescLayer = themeDescViewData.layer
        -- local themeCellViewData = themeDescViewData.themeCellViewData
        shopThemeDescLayer:setVisible(false)

    end

    local gridView = self.viewData.shopTabViewData.gridView
    local oldIndex = getTabIndexByType(self.currentAvatarType_)
    local oldCell = gridView:cellAtIndex(oldIndex - 1)
    if oldCell then
        self:updateCellSelectState(oldCell.viewData, false, CELL_TYPE.TAB)
    end

    self.goodCellIndex = 1

    self.selectNum = 1

    self:updateCurrentMallData(avatarType)

    self:updateCellSelectState(cell.viewData, true, CELL_TYPE.TAB)

    self:updateShopListLayer()

    self:updateShopGoodPreview()

end

function AvatarShopMediator:OnShopGoodCellAction(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local cell = sender:getParent():getParent()
    local index = cell:getTag()
    -- print('OnShopGoodCellAction', self.goodCellIndex)
    local isTheme = self.currentAvatarType_ == RESTAURANT_AVATAR_TYPE.THEME
    -- print('OnShopGoodCellAction', index)
    self:updateNewState(cell.viewData, index)
    if not isTheme and self.goodCellIndex == index then return end

    if not isTheme then
        local data = self.currentMallData_[index]
        local avatarConf = checktable(data.avatarConf)
        local openRestaurantLevel = checkint(avatarConf.openRestaurantLevel)
        if self:CheckAvatarLockLevel(openRestaurantLevel) then
            uiMgr:ShowInformationTips(string.format(__('%s级餐厅等级解锁'), openRestaurantLevel))
            return
        end
    end

    self.selectNum = 1
    -- self:updatePreviewPrice()
    local cellType = CELL_TYPE.SHOP_GOOD
    local gridView = nil

    local function setSelectState(gridView)
        local oldCellIndex = self:CheckIsShowThemeDesc() and (self.themeGoodCellIndex - 1) or (self.goodCellIndex - 1)
        local oldCell = gridView:cellAtIndex(oldCellIndex)
        if oldCell then
            self:updateCellSelectState(oldCell.viewData, false, cellType)
        end

        if self:CheckIsShowThemeDesc() then
            self.themeGoodCellIndex = index
        else
            self.goodCellIndex = index
        end


        self:updateCellSelectState(cell.viewData, true, cellType)
    end

    if isTheme then
        -- print('DESC')
        if self:CheckIsShowThemeDesc() then
            local themeDescViewData = self.viewData.themeDescViewData
            local gridView = themeDescViewData.gridView
            setSelectState(gridView)
        else
            cellType = CELL_TYPE.SHOP_THEME
            local shopThemeViewData = self.viewData.shopThemeViewData
            gridView = shopThemeViewData.gridView

            local isEnterDesc = self.goodCellIndex == index
            setSelectState(gridView)
            local data = self.currentMallData_[self.goodCellIndex]
            local themeConf = checktable(data.themeConf)
            local themeId = checkint(themeConf.id)
            -- self:AddThemeGoodInventorys_(themeId)
            if isEnterDesc then
                -- TODO 进入 主题详情界面
                self:ShowShopThemeDesc()
            end
        end
    else
        local shopGoodViewData = self.viewData.shopGoodViewData
        gridView = shopGoodViewData.gridView
        setSelectState(gridView)
        -- local data = self.currentMallData_[index]
        -- local productId = tostring(data.productId)


        -- if gameMgr:GetUserInfo().avatarCacheRestaurantNews[productId] then
        --     local viewData = cell.viewData
        --     local newIcon = viewData.newIcon

        --     if newIcon then
        --         newIcon:setVisible(false)
        --         gameMgr:GetUserInfo().avatarCacheRestaurantNews[productId] = nil
        --     end
        -- end
    end

    self:updateShopGoodPreview()
end



function AvatarShopMediator:InitAvatarMallData(serDatas)

    -- 1. 遍历 常住商店表 (mall/avatar.json)
    --    1.1 检查是否为主题
    --        1.1.1 是, 填充 avatarMallDataMap_ (warn: discontData ~= nil 则表示为折扣主题)
    --        1.1.2 否, 填充 localMallDataMap_  (warn: discontData ~= nil 则表示为折扣道具)
    --    1.2 根据 productId 移除 serverMallDataMap 中的 保存的数据

    -- 现在没有 限时道具
    -- 2. 遍历 serverMallDataMap (warn: 在1.2 中进行了 移除操作，剩下的数据则表示为 限时道具)
    --    2.1 检查是否为主题
    --        2.1.1 是, 填充 avatarMallDataMap_ (warn: discontData ~= nil 则表示为限时主题)
    --        2.1.2 否, 填充 localMallDataMap_  (warn: discontData ~= nil 则表示为限时道具)

    -- local avatarProductData = {
    --     avatarConf,
    --     -- activityConf, -- [o] has, is limit avatar mall    限时道具 已被移除
    --     mallConf, -- [o] has, is local avatar mall
    --     productId,
    --     discontData, -- not nil, has discont
    -- }
    -------------------------------------------------------------------
    -- server get
    local avatarConfs          = avatarRestaurantConf or {} -- restaurant/avatar.json
    local avatarThemeConfs     = avatarThemeRestaurantConf or {} -- restaurant/avatarTheme.json
    local avatarMallConfs      = avatarMallCof or {} -- mall/avatar.json
    local avatarActivityConfs  = avatarActivityMallCof or {} -- mall/activity.json
    local serverMallDataMap    = serDatas or {} -- TODO server data

    local avatarCacheRestaurantLevels = gameMgr:GetUserInfo().avatarCacheRestaurantLevels

    self.avatarMallDataMap_   = {}     -- 普通商店数据
    self.avatarMallThemeData_ = {}     -- 主题商店数据
    self.themeGoodInventorys_ = {}     -- 主题道具清单   warn: 只有在用户点击 预览 或 查看主题散件 时  根据 主题id 判断缓存中是否包含此 主题清单

    local addNews = function (openRestaurantLevel, productId, avatarType)
        local lv = avatarCacheRestaurantLevels[tostring(openRestaurantLevel)]
        local isNew = lv ~= nil
        if isNew then
            gameMgr:GetUserInfo().avatarCacheRestaurantNews[avatarType] = gameMgr:GetUserInfo().avatarCacheRestaurantNews[avatarType] or {}
            gameMgr:GetUserInfo().avatarCacheRestaurantNews[avatarType][tostring(productId)] = isNew
        end
    end

    -- each local mall
    for productId, productConf in pairs(avatarMallConfs) do
        local goodsId = checkint(productConf.goodsId)
        local isTheme = avatarThemeConfs[tostring(goodsId)] ~= nil
        if isTheme then

            local themeConf   = avatarThemeConfs[tostring(goodsId)] or {}
            local discontData = serverMallDataMap[tostring(productId)]
            local openRestaurantLevel = checkint(themeConf.openRestaurantLevel)
            local productData = {
                themeConf           = themeConf,
                mallConf            = productConf,              -- 控制 道具的价格 和 道具的货币
                productId           = productId,
                discontData         = discontData,              -- not nil, has discont
                openRestaurantLevel = openRestaurantLevel,
            }

            addNews(openRestaurantLevel, productId, tostring(RESTAURANT_AVATAR_TYPE.THEME))
            self:AddThemeGoodInventorys_(goodsId)
            table.insert(self.avatarMallThemeData_, productData)
        else
            local avatarConf  = avatarConfs[tostring(goodsId)] or {}
            local sellType = avatarConf.sellType
            --  1. 配表没配 sellType 字段 或 配表内配了 sellType 并且 是avatar shop 类型 才插入数据
            if sellType == nil or (sellType and sellType[tostring(RESTAURAN_AVATAR_SELL_TYPE.AVATAR_SHOP)]) then
                avatarConf.openRestaurantLevel = checkint(avatarConf.openRestaurantLevel)
                local avatarType  = tostring(checkint(avatarConf.mainType))
                local discontData = serverMallDataMap[tostring(productId)]
                local openRestaurantLevel = checkint(avatarConf.openRestaurantLevel)
                local productData = {
                    avatarConf          = avatarConf,
                    mallConf            = productConf,              -- 控制 道具的价格 和 道具的货币
                    productId           = productId,
                    discontData         = discontData,              -- not nil, has discont
                    openRestaurantLevel = openRestaurantLevel,
                }
    
                addNews(openRestaurantLevel, productId, avatarType)
    
                self.avatarMallDataMap_[avatarType] = self.avatarMallDataMap_[avatarType] or {}
                table.insert(self.avatarMallDataMap_[avatarType], productData)
            end
        end
        serverMallDataMap[tostring(productId)] = nil
    end

    -- dump(serverMallDataMap)
    -- each activity mall
    -- for productId, discontData in pairs(serverMallDataMap) do
    --     local activityConf = avatarActivityConfs[productId]
    --     local goodsId      = checkint(activityConf.goodsId)
    --     local isTheme      = avatarThemeConfs[tostring(goodsId)] ~= nil
    --     local mallConf     = avatarMallConfs[tostring(goodsId)]
    --     if isTheme then
    --         local themeConf   = avatarThemeConfs[tostring(goodsId)] or {}
    --         local openRestaurantLevel = checkint(themeConf.openRestaurantLevel)
    --         local productData = {
    --             themeConf           = themeConf,
    --             activityConf        = activityConf,
    --             productId           = productId,
    --             discontData         = discontData,      -- not nil, has discont
    --             mallConf            = mallConf,
    --             openRestaurantLevel = openRestaurantLevel,
    --         }

    --         addNews(openRestaurantLevel, productId, tostring(RESTAURANT_AVATAR_TYPE.THEME))

    --         table.insert(self.avatarMallThemeData_, productData)
    --     else
    --         local avatarConf  = avatarConfs[tostring(goodsId)] or {}
    --         local avatarType  = tostring(checkint(avatarConf.mainType))
    --         local openRestaurantLevel = checkint(avatarConf.openRestaurantLevel)
    --         local productData = {
    --             avatarConf          = avatarConf,
    --             activityConf        = activityConf,
    --             productId           = productId,
    --             discontData         = discontData,      -- not nil, has discont
    --             mallConf            = mallConf,
    --             openRestaurantLevel = openRestaurantLevel,
    --         }

    --         addNews(openRestaurantLevel, productId, avatarType)

    --         self.avatarMallDataMap_[avatarType] = self.avatarMallDataMap_[avatarType] or {}
    --         table.insert(self.avatarMallDataMap_[avatarType], productData)
    --     end
    -- end
    -- dump(self.themeGoodInventorys_)
    local getGoodsId = function (tData)
        local mallConf = tData.mallConf
        local goodsId = checkint(mallConf.goodsId)
        return goodsId
    end

    local getUnmetPartCount = function (goodsId)
        local themeGoodInventory = self:GetThemeGoodInventory(goodsId)
        return themeGoodInventory.unmetPartCount, goodsId
    end

    local sortThemeFunc = function (a, b)
        if a == nil then
            return true
        end
        if b == nil then
            return false
        end
        local aThemeConf = a.themeConf or {}
        local bThemeConf = b.themeConf or {}

        local aCompositor = checkint(aThemeConf.compositor)
        local bCompositor = checkint(bThemeConf.compositor)

        local aGoodsId = getGoodsId(a)
        local bGoodsId = getGoodsId(b)
        local aCount = getUnmetPartCount(aGoodsId)
        local bCount = getUnmetPartCount(bGoodsId)

        local sortParams1 = aCount == 0 and -1 or aCompositor
        local sortParams2 = bCount == 0 and -1 or bCompositor
        if sortParams1 == sortParams2 then
            return checkint(aGoodsId) < checkint(bGoodsId)
        end
        return sortParams1 > sortParams2
    end
    table.sort(self.avatarMallThemeData_, sortThemeFunc)

    local sortFunc = function (a, b)
        if a == nil then
            return true
        end
        if b == nil then
            return false
        end
        local aGoodsId = getGoodsId(a)
        local bGoodsId = getGoodsId(a)
        if a.openRestaurantLevel == b.openRestaurantLevel then
            return checkint(aGoodsId) < checkint(bGoodsId)
        end

        return a.openRestaurantLevel < b.openRestaurantLevel
     end

    for i,v in pairs(self.avatarMallDataMap_) do
        table.sort(v, sortFunc)
    end

    if table.nums(gameMgr:GetUserInfo().avatarCacheRestaurantNews) == 0 then
        self.avatarMdt_:UpdateAvatarRenovationRemind(table.nums(gameMgr:GetUserInfo().avatarCacheRestaurantNews) > 0)
    end
    -- dump(gameMgr:GetUserInfo().avatarCacheRestaurantLevels)
    gameMgr:GetUserInfo().avatarCacheRestaurantLevels = {}

    ------------------
    -- 切换type
    self:updateCurrentMallData()

    -- dump(self.currentMallData_[1])

    -- dump( gameMgr:GetUserInfo().avatarCacheRestaurantNews, 'avatarCacheRestaurantNews')
    -- if gameMgr:GetUserInfo().avatarCacheRestaurantNews['0'] then
    --     for productId, isNew in pairs(gameMgr:GetUserInfo().avatarCacheRestaurantNews['0']) do
    --         print(string.format("productId =  %s 未发现 mianType", productId))
    --     end
    -- end
    -- if self.avatarMallDataMap_['0'] then
    --     dump(self.avatarMallDataMap_['0'])
    -- end

end

function AvatarShopMediator:AddThemeGoodInventorys_(themeId)
    if self.themeGoodInventorys_[tostring(themeId)] == nil then
        self.themeGoodInventorys_[tostring(themeId)] = self:CreateThemeGoodInventory(themeId)
        -- dump(self.themeGoodInventorys_[tostring(themeId)])
    end
    return self.themeGoodInventorys_[tostring(themeId)]
end

function AvatarShopMediator:GetThemeGoodInventory(curThemeId)
    local themeId = nil
    if curThemeId then
        themeId = curThemeId
    else
        local data = self.currentMallData_[self.goodCellIndex]
        local themeConf = checktable(data.themeConf)
        themeId = checkint(themeConf.id)
    end

    local themeGoodInventory = self:AddThemeGoodInventorys_(themeId) --self.themeGoodInventorys_[tostring(themeId)]
    return themeGoodInventory
end

function AvatarShopMediator:UpdateThemeGoodInventorys_(themeId, goodsId, showGoodNum)
    if self.themeGoodInventorys_[tostring(themeId)] then
        for index, themeGoodData in pairs(self.themeGoodInventorys_[tostring(themeId)]) do
            if themeGoodId.goodsId == goodsId then
                themeGoodData.showGoodNum = showGoodNum
                break
            end
        end
    end
end


function AvatarShopMediator:CheckAvatarLockLevel(openRestaurantLevel)
    return checkint(gameMgr:GetUserInfo().restaurantLevel) < checkint(openRestaurantLevel)
end


--==============================--
--desc: 检查道具最大拥有数
--time:2017-11-13 10:12:44
--@goodsId:
--@maxOwnNum:
--@name:
--@return
--==============================--
function AvatarShopMediator:CheckIsMaxNum(goodsId, maxOwnNum, name)
    local ownGoodNum = checkint(gameMgr:GetAmountByGoodId(goodsId))
    local isMax = ownGoodNum >= maxOwnNum
    if isMax then
        uiMgr:ShowInformationTips(string.fmt(__('_name_最多拥有_num_'),{_name_ = tostring(name), _num_ = maxOwnNum}))
    end
    return isMax
end

--==============================--
--desc: 检查是否显示 主题详情
--time:2017-10-21 03:59:12
--@return
--==============================--
function AvatarShopMediator:CheckIsShowThemeDesc()
    return self.themeGoodCellIndex ~= -1
end

--==============================--
--desc: 检查 是否达到 道具最大拥有数
--time:2017-11-02 11:46:45
--@goodsId: 道具id
--@maxOwnNum: 道具最大拥有数
--@name: 道具名称
--@return
--==============================--
function AvatarShopMediator:IsGoodMaxOwnCount(goodsId, maxOwnNum, name)
    local ownGoodNum = checkint(gameMgr:GetAmountByGoodId(goodsId))
    local isSatisfy  = ownGoodNum >= maxOwnNum
    if isSatisfy then
        uiMgr:ShowInformationTips(string.fmt(__('_name_最多拥有_num_个'),{_name_ = name, _num_ = maxOwnNum}))
    end
    return isSatisfy
end

--==============================--
--desc: 检查货币是否满足
--time:2017-11-02 11:56:49
--@args:
--@return
--==============================--
function AvatarShopMediator:IsCurrencyAdequate(currencyId, totalPrice)
    local ownCurrencyCount   = gameMgr:GetAmountByIdForce(currencyId)
    local isNotAdequate = totalPrice > ownCurrencyCount
    if isNotAdequate then
        if GAME_MODULE_OPEN.NEW_STORE and checkint(currencyId) == DIAMOND_ID then
            app.uiMgr:showDiamonTips()
        else
            uiMgr:ShowInformationTips(string.fmt(__('_name_不足'),{_name_ = tostring(CommonUtils.GetCacheProductName(currencyId))}))
        end
    end
    return isNotAdequate
end

--==============================--
--desc: 获取 主题详情 中 某个 散件 的相关数据
--time:2017-10-21 02:43:53
--@themeData:
--@return
--==============================--
function AvatarShopMediator:getThemeDescGoodData(themeData, index)

    local themeConf = themeData.themeConf
    local themeId = themeConf.id

    local themeGoodInventory = self:GetThemeGoodInventory(themeId)
    local themeParts         = themeGoodInventory.themeParts

    local themeGoodData      = themeParts[index] or {}
    -- dump(themeGoodData)
    local avatarConf         = themeGoodData.avatarConf or {}

    return avatarConf
end

--==============================--
--desc: 获取 未拥有的所有 主题散件
--time:2017-10-21 02:43:53
--@themeData:
--@return
--==============================--
function AvatarShopMediator:CreateThemeGoodInventory(themeId)
    local avatarThemeParts = avatarThemePartsConf[tostring(themeId)] or {}
    local themeGoodInventory = {
        unmetPartCount       =  0,  -- 未满足 主题构成 的散件数
        themeTotalPrice      =  0,  -- 主题 总价
        currency             =  '',
        themeParts           =  {}, -- 主题散件列表
    }

    for goodsId, num in pairs(avatarThemeParts) do

        local productId, mallConf = self:GetMallConfByGoodsId(tostring(goodsId))
        if themeGoodInventory.currency == '' then
            themeGoodInventory.currency = mallConf.currency
        end

        local ownNum = gameMgr:GetAmountByGoodId(goodsId)
        local themePartMaxNum = checkint(num)

        local avatarConf  = avatarRestaurantConf[tostring(goodsId)] or {}

        local showGoodNum = 0
        if ownNum < themePartMaxNum then
            showGoodNum = themePartMaxNum - ownNum
            themeGoodInventory.unmetPartCount = themeGoodInventory.unmetPartCount + 1    -- 记录下 未满足条件的散件数
            local goodPrice = checkint(mallConf.price)
            themeGoodInventory.themeTotalPrice = goodPrice * showGoodNum + themeGoodInventory.themeTotalPrice
        end

        table.insert(themeGoodInventory.themeParts, {
            goodsId           = goodsId,                          -- 主题散件  id
            productId         = productId,                        -- 商品     id
            showGoodNum       = showGoodNum,                      -- 主题清单中要显示的个数
            themePartMaxNum   = themePartMaxNum,                  -- 主题散件 最多拥有的个数
            avatarConf        = avatarConf,                       -- 主题散件 数据
            mallConf          = mallConf,
        })
    end

    local sortfunction = function (a, b)
        if a == nil then
            return true
        end
        if b == nil then
            return false
        end
        local aGoodsId  = a.goodsId
        local bGoodsId  = b.goodsId
        local aShowGoodNum = a.showGoodNum == 0 and 10000 or a.showGoodNum
        local bShowGoodNum = b.showGoodNum == 0 and 10000 or b.showGoodNum
        if aShowGoodNum == bShowGoodNum then
            return checkint(aGoodsId) < checkint(bGoodsId)
        end
        return aShowGoodNum < bShowGoodNum
    end

    table.sort(themeGoodInventory.themeParts, sortfunction )
    return themeGoodInventory

end

function AvatarShopMediator:GetMallConfByGoodsId(goodsId)

    for productId, mallConf in pairs(avatarMallCof) do
        if mallConf.goodsId == goodsId then
            return productId, mallConf
        end
    end

    return 0, {}
end

getCurrencyByPayType = function (payType)
    local currencyId = GOLD_ID
    if payType == 1 then
        currencyId = GOLD_ID
    elseif payType == 2 then
        currencyId = DIAMOND_ID
    else
        print(string.format('未知 payType = %s', tostring(payType)))
    end
    return currencyId
end

getTabIndexByType = function (type)
    for i,v in ipairs(TAB_INFOS) do
        if v.id == type then
            return i
        end
    end
    return 1
end

function AvatarShopMediator:OnRegist(  )
    local ShopCommand = require( 'Game.command.ShopCommand')
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_SHOP_AVATAR, ShopCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_SHOP_AVATAR_BUYAVATAR, ShopCommand)

    self:EnterLayer()
end

function AvatarShopMediator:CleanupView()
    if self.avatarScene_ then
        self.avatarScene_:RemoveGameLayer(self:GetViewComponent())
        self.avatarScene_ = nil
    end
end

function AvatarShopMediator:OnUnRegist(  )
    -- 发送退出 家具商店事件
    self:GetFacade():DispatchObservers(RESTAURANT_EVENTS.EVENT_AVATAR_SHOP_SIGN_OUT)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_SHOP_AVATAR)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_SHOP_AVATAR_BUYAVATAR)

end

return AvatarShopMediator
