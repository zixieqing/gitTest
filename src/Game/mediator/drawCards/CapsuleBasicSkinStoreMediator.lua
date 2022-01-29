--[[
 * descpt : 抽卡商店
 * mallDatas = {
     [MALL_TYPE.xxxx] = {
         {
            productId : int, 商品ID.               
            type : int, 1皮肤 2 avatar 3 包厢装扮.
            goodsId : int, 道具ID.
            currency : int, 货币.
            price : int, 价格.
            stock : int, 库存.
            leftPurchaseNum : int, 剩余可购买次数.
            iconId : int, 图标ID.
            iconTitle : string, 图标标题.
         }
     }
 }

 * warn: 这里不更新主题价格 一律在获取主题数据(self:getMdtDataByMallType(MALL_TYPE.THEME))时更新主题价格
]]
local NAME = 'drawCards.CapsuleBasicSkinStoreMediator'
local CapsuleBasicSkinStoreMediator = class(NAME, mvc.Mediator)

local CapsuleMallView = require('Game.views.drawCards.CapsuleMallView')
local avatarThemePartsConf = CommonUtils.GetConfigAllMess('avatarThemeParts', 'restaurant') or {}
local avatarMallCof = CommonUtils.GetConfigAllMess('avatar', 'mall') or {}

local uiMgr = app.uiMgr
local gameMgr = app.gameMgr

local MALL_TYPE = {
    SKIN     = 1,     -- 皮肤 
    AVATAR   = 2,     -- avatar 
        THEME    = -201,   -- 主题  客户端自定义类型
        PARTS    = -200,   -- 部件  客户端自定义类型
    ORNAMENT = 3,     -- 包厢装扮
}

local MALL_TYPE_DEFINE = {
    [MALL_TYPE.SKIN]     = {name = __('飨灵外观'), mallType = MALL_TYPE.SKIN,    mdtName = 'drawCards.CapsuleMallSkinMediator'},
    [MALL_TYPE.AVATAR]   = {name = __('餐厅装扮'), mallType = MALL_TYPE.AVATAR},
    [MALL_TYPE.THEME]    = {name = __('主题'),    mallType = MALL_TYPE.THEME,    mdtName = 'drawCards.CapsuleMallThemeMediator'},
    [MALL_TYPE.PARTS]    = {name = __('部件'),    mallType = MALL_TYPE.PARTS,    mdtName = 'drawCards.CapsuleMallPartsMediator'},
    [MALL_TYPE.ORNAMENT] = {name = __('纪念品'),  mallType = MALL_TYPE.ORNAMENT,  mdtName = 'drawCards.CapsuleMallOrnamentMediator'},
}

local CHILD_MALL_TYPE_CONFIG = {
    [MALL_TYPE.AVATAR] = {
        [GoodsType.TYPE_THEME]  = MALL_TYPE.THEME,
        [GoodsType.TYPE_AVATAR] = MALL_TYPE.PARTS,
    }
}

function CapsuleBasicSkinStoreMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method

function CapsuleBasicSkinStoreMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self:initValue()

    -- create view
    local viewComponent = CapsuleMallView.new()
    self.viewData_      = viewComponent:getViewData()
    self.ownerScene_    = app.uiMgr:GetCurrentScene()
    self.ownerScene_:AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)

    self:initView()
    
end

function CapsuleBasicSkinStoreMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function CapsuleBasicSkinStoreMediator:OnRegist()
    -- app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    regPost(POST.GAMBLING_BASE_CARDSKIN_MALL)
    regPost(POST.GAMBLING_BASE_CARDSKIN_MALL_BUY)
    self:EnterLayer()
end


function CapsuleBasicSkinStoreMediator:OnUnRegist()
    -- app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')
    unregPost(POST.GAMBLING_BASE_CARDSKIN_MALL)
    unregPost(POST.GAMBLING_BASE_CARDSKIN_MALL_BUY)
    self:cleanupView()
end


function CapsuleBasicSkinStoreMediator:InterestSignals()
    local signalList = {
        POST.GAMBLING_BASE_CARDSKIN_MALL.sglName,
        POST.GAMBLING_BASE_CARDSKIN_MALL_BUY.sglName,
        SGL.CACHE_MONEY_UPDATE_UI,
        'CAPSULE_MALL_GOOD_BUY',
    }
    return signalList
end
function CapsuleBasicSkinStoreMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody() or {}
    if name == POST.GAMBLING_BASE_CARDSKIN_MALL.sglName then

        self:initData(data)
        self:initExpandableListView()
        self:refreshUI()

    elseif name == POST.GAMBLING_BASE_CARDSKIN_MALL_BUY.sglName then
        local requsetData = data.requestData or {}
        if self.buyData == nil then return end
        self.ownerScene_:AddViewForNoTouch()

        local productIndex = self:updateMallDataByMallType(self.selectedMallType, self.buyData)

        local currency    = checkint(self.buyData.currency)
        if currency > 0 then
            local productNum  = checkint(self.buyData.productNum)
            local price       = checknumber(self.buyData.price)
    
            CommonUtils.DrawRewards({{goodsId = currency, num = -productNum * price}})
        end

        app:DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI)

        local rewards = data.rewards or {}
        if next(rewards) ~= nil then
            local tempRewardData = nil
            if self.selectedMallType == MALL_TYPE.SKIN then
                CommonUtils.DrawRewards(rewards)
            elseif self.selectedMallType == MALL_TYPE.THEME then
                -- 1.获取该主题的所有散件
                local themeId = self.buyData.goodsId
                
                local avatarThemeParts = avatarThemePartsConf[tostring(themeId)]
                -- 2.获取map格式的背包数据
                local backpackMap = gameMgr:GetBackPackArrayToMap()
                -- 3.添加需要更新奖励数据
                local needUpdateData = {}
                local mdtData      = self:getMdtDataByMallType(MALL_TYPE.PARTS)
                local mdtDataMap   = {}
                for i, v in ipairs(mdtData) do
                    mdtDataMap[tostring(v.goodsId)] = i
                end

                if avatarThemeParts then
                    for avatarId, num in pairs(avatarThemeParts) do
                        local tempData   = backpackMap[tostring(avatarId)] or {}
                        local ownNum = checkint(tempData.amount)
                        local deltaNum = checkint(num) - ownNum
                        if deltaNum > 0 then
                            local listIndex = mdtDataMap[tostring(avatarId)]
                            if listIndex and mdtData[listIndex] then
                                local leftPurchaseNum = checkint(mdtData[listIndex].leftPurchaseNum)
                                if leftPurchaseNum ~= -1 then
                                    mdtData[listIndex].leftPurchaseNum = math.max(checkint(leftPurchaseNum - deltaNum), 0)
                                end
                            end
                            table.insert(needUpdateData, {goodsId = avatarId, num = deltaNum})
                        end
                    end
                end
                tempRewardData = needUpdateData
            elseif self.selectedMallType == MALL_TYPE.PARTS then
                -- warn: 这里不更新主题价格 一律在获取主题数据(self:getMdtDataByMallType(MALL_TYPE.THEME))时更新主题价格
                tempRewardData = rewards
            else
                tempRewardData = rewards
            end
            if tempRewardData then
                uiMgr:AddDialog('common.RewardPopup', {rewards = tempRewardData})
            end
        end

        local drawHomeMdt = self:GetFacade():RetrieveMediator(self.contentMdtName)
        if drawHomeMdt and drawHomeMdt.updateData then
            drawHomeMdt:updateData({productIndex = productIndex, buyData = self.buyData, mdtData = self:getMdtDataByMallType(self.selectedMallType)})
        end

        self.buyData = nil
        self.ownerScene_:RemoveViewForNoTouch()
    elseif name == SGL.CACHE_MONEY_UPDATE_UI then
        self:GetViewComponent():updateMoneyBarGoodNum()
    elseif name == 'CAPSULE_MALL_GOOD_BUY' then
        self.buyData = data
        local params = {productId = data.productId, productNum = data.productNum, goodsId = data.goodsId}
        -- app:DispatchObservers(POST.GAMBLING_BASE_CARDSKIN_MALL_BUY.sglName, {requestData = params, rewards = {{goodsId = data.goodsId, num = data.productNum}}})
        self:SendSignal(POST.GAMBLING_BASE_CARDSKIN_MALL_BUY.cmdName, params)
    end

end

-------------------------------------------------
-- init
function CapsuleBasicSkinStoreMediator:initValue()
    self.isControllable_  = true
    self.contentMdtName   = nil
    self.selectedMallType = nil
end

function CapsuleBasicSkinStoreMediator:initData(datas)
    local mallDatas = {}
    local tabList = {}
    local tempMallTypeMap = {}
    local products = datas.products or {}

    for i, product in ipairs(products) do
        local type = checkint(product.type)
        local goodTypeConf = CHILD_MALL_TYPE_CONFIG[type]

        if tempMallTypeMap[type] == nil then
            tempMallTypeMap[type] = 1
            table.insert(tabList, {mallType = type})
        end

        if goodTypeConf then
            local goodsId = product.goodsId
            if type == MALL_TYPE.AVATAR then
                product.leftPurchaseNum = product.stock - gameMgr:GetAmountByIdForce(goodsId)
            end
            local childMallType = self:getMallTypeByGoodsId(goodTypeConf, goodsId)
            if childMallType then
                if mallDatas[childMallType] == nil then
                    mallDatas[childMallType] = {}

                    for i, v in ipairs(tabList) do
                        if v.mallType == type then
                            v.childTabTypes = v.childTabTypes or {}
                            table.insert(v.childTabTypes, {mallType = childMallType})
                            break
                        end
                    end
                end
                table.insert(mallDatas[childMallType], product)
            end
        else
            mallDatas[type] =  mallDatas[type] or {}
            table.insert(mallDatas[type], product)
        end
    end

    self.mallDataSortState = {}
    self.mallDatas = mallDatas
    self.tabList = tabList

    local tabSortFunc = function (a, b)
        return checkint(a.mallType) < checkint(b.mallType)
    end
    table.sort(self.tabList, tabSortFunc)

    for i, v in ipairs(self.tabList) do
        if v.childTabTypes and next(v.childTabTypes) ~= nil then
            table.sort(v.childTabTypes, tabSortFunc)
        end
    end

end

function CapsuleBasicSkinStoreMediator:initView()
    local viewData = self:getViewData()
    local backBtn  = viewData.backBtn
    display.commonUIParams(backBtn, {cb = handler(self, self.onClickBackBtnAction)})
end

function CapsuleBasicSkinStoreMediator:initExpandableListView()
    local viewData           = self:getViewData()
    local expandableListView = viewData.expandableListView
    local viewComponent      = self:GetViewComponent()
    local commonLabelParams  = display.commonLabelParams
    local commonUIParams     = display.commonUIParams

    local cellSize = cc.size(expandableListView:getContentSize().width, 86)
    local itemSize = cc.size(160, 50)
    
    for _, tabData in ipairs(self.tabList) do
        local mallType = tabData.mallType
        local mallTypeConf = MALL_TYPE_DEFINE[mallType] or {}
        
        local cell = viewComponent:CreateCell(cellSize)
        cell:setTag(mallType)
        local btn = cell:getChildByName('btn')
        if btn then
            commonLabelParams(btn, {text = tostring(mallTypeConf.name)})
            commonUIParams(btn, {cb = handler(self, self.onClickCellAction)})
            btn:setUserTag(mallType)
        end
        expandableListView:insertExpandableNodeAtLast(cell)

        if self.selectedMallType == nil then
            self.selectedMallType = mallType
        end

        local childTabTypes = tabData.childTabTypes
        if childTabTypes and next(childTabTypes) ~= nil then
            for i, childTabTypeData in ipairs(childTabTypes) do
                local childMallType = childTabTypeData.mallType
                local childMallTypeConf = MALL_TYPE_DEFINE[childMallType] or {}
                local item = viewComponent:CreateItem(itemSize)
                item:setTag(childMallType)
                local itemBtn = item:getChildByName('btn')
                if itemBtn then
                    commonLabelParams(itemBtn, {text = tostring(childMallTypeConf.name)})
                    commonUIParams(itemBtn, {cb = handler(self, self.onClickItemAction)})
                    
                    itemBtn:setUserTag(childMallType)
                end
                cell:insertItemNodeAtLast(item)
            end
        end
    end
    
    expandableListView:reloadData()
end

-------------------------------------------------
-- get / set

function CapsuleBasicSkinStoreMediator:getViewData()
    return self.viewData_
end

function CapsuleBasicSkinStoreMediator:getOwnerScene()
    return self.ownerScene_
end

function CapsuleBasicSkinStoreMediator:getMallTypeByGoodsId(goodTypeConf, goodsId)
    return goodTypeConf[CommonUtils.GetGoodTypeById(goodsId)]
end

function CapsuleBasicSkinStoreMediator:getMdtConfByMallType(mallType)
    return MALL_TYPE_DEFINE[mallType]
end

function CapsuleBasicSkinStoreMediator:getMdtDataByMallType(mallType)
    local mallData = self.mallDatas[mallType] or {}
    -- 延迟排序
    if self.mallDataSortState[mallType] == nil then
        self.mallDataSortState[mallType] = mallType
        app.capsuleMgr:SortProductDatas(mallData)
    end

    -- 只要是主题数据 就根据散件初始化一下价格
    if mallType == MALL_TYPE.THEME then
        local partsMallData = self.mallDatas[MALL_TYPE.PARTS]
        if partsMallData then
            -- 获取map格式的背包数据
            local backpackMap = gameMgr:GetBackPackArrayToMap()

            local partsMdtDataMap   = {}
            for i, v in ipairs(partsMallData) do
                partsMdtDataMap[tostring(v.goodsId)] = v
            end

            for i, v in ipairs(mallData) do
                local themeId = v.goodsId
                -- 获取所有主题散件配置
                local avatarThemeParts = avatarThemePartsConf[tostring(v.goodsId)] or {}
                local themePrice = 0
                local totalThemePrice = 0
                for avatarId, num in pairs(avatarThemeParts) do
                    -- 如果没配 则 去 家具商店中查找 商品价格
                    local partData = partsMdtDataMap[tostring(avatarId)] or avatarMallCof[tostring(avatarId)]
                    if partData then
                        -- 散件单价
                        local price    = checkint(partData.price)
                        local tempData = backpackMap[tostring(avatarId)] or {}
                        local ownNum   = checkint(tempData.amount)
                        local deltaNum = checkint(num) - ownNum
                        totalThemePrice = price * checkint(num) + totalThemePrice
                        if deltaNum > 0 then
                            themePrice = themePrice + price * deltaNum
                        end
                    end
                end
                -- logInfo.add(5, 'v.price = ' .. tostring(v.price))
                -- logInfo.add(5, 'totalThemePrice = ' .. tostring(totalThemePrice))
                v.price = themePrice
            end
        end
    end

    return mallData
end
-------------------------------------------------
-- public method

function CapsuleBasicSkinStoreMediator:EnterLayer()
    self:SendSignal(POST.GAMBLING_BASE_CARDSKIN_MALL.cmdName)
end

function CapsuleBasicSkinStoreMediator:updateMallDataByMallType(mallType, params)
    local productId    = params.productId
    local productNum   = checkint(params.productNum)
    local mdtData      = self:getMdtDataByMallType(mallType)
    local productIndex = 0
    for i, productData in ipairs(mdtData) do
        if productData.productId == productId then
            local leftPurchaseNum = productData.leftPurchaseNum
            if leftPurchaseNum and checkint(leftPurchaseNum) ~= -1 then
                productData.leftPurchaseNum = checkint(productData.leftPurchaseNum) - productNum
            end
            productIndex = i
            break
        end
    end
    return productIndex
end

-------------------------------------------------
-- private method

function CapsuleBasicSkinStoreMediator:refreshUI()
    self:refreshExpandableListView()
    self:refreshChildMediaor()
end

function CapsuleBasicSkinStoreMediator:refreshExpandableListView()
    local viewData = self:getViewData()
    local expandableListView = viewData.expandableListView
    local viewComponent = self:GetViewComponent()
    for i, tabData in ipairs(self.tabList) do
        local expandableNode = expandableListView:getExpandableNodeAtIndex(i - 1)
        if expandableNode then
            
            -- 判断是否被选中
            viewComponent:updateCellSelectState(expandableNode, self.selectedMallType == tabData.mallType)
            -- 判断是否有子页签
            local childTabTypes = tabData.childTabTypes
            if childTabTypes and next(childTabTypes) ~= nil then
                local isSelected = false
                for index, childTabTypeData in ipairs(childTabTypes) do
                    local childMallType = childTabTypeData.mallType
                    
                    local item = expandableNode:getItemNodeAtIndex(index - 1)
                    local isSelectItem = self.selectedMallType == childMallType
                    viewComponent:updateItemSelectState(item, isSelectItem)

                    if isSelectItem then
                        isSelected = true
                    end
                end

                expandableNode:setExpanded(isSelected)
                if isSelected then
                    viewComponent:updateCellSelectState(expandableNode, isSelected)
                end
            end
        end
    end

    expandableListView:reloadData()
end

function CapsuleBasicSkinStoreMediator:refreshChildMediaor()
    local selectedMallType = self.selectedMallType
    local conf = self:getMdtConfByMallType(selectedMallType) or {}
    local mdtName = conf.mdtName
    if mdtName == nil or self.contentMdtName == mdtName then return end
    
    -- un-regist old contentMdt
    app:UnRegsitMediator(self.contentMdtName)

    local mdtData = self:getMdtDataByMallType(selectedMallType)
    -- regist new contentMdt
    xTry(function()
        local contentMdtClass  = require(string.fmt('Game.mediator.%1', mdtName))
        local contentMdtObject = contentMdtClass.new({mdtData = mdtData})
        -- contentMdtObject.mediatorName = drawMdtName
        app:RegistMediator(contentMdtObject)

        local contentMdtView = contentMdtObject:GetViewComponent()
        local childUILayer = self:getViewData().childUILayer
        contentMdtView:setPosition(utils.getLocalCenter(childUILayer))
        childUILayer:addChild(contentMdtView)

        local tempData = mdtData[1] or {}
        local currency = checkint(tempData.currency)
        local args = {}
        if currency > 0 then
            args.moneyIdMap = {}
            args.moneyIdMap[tostring(currency)] = currency
        end
        
        self:GetViewComponent():updateMoneyBarGoodList(args)

        if contentMdtObject.refreshUI then
            contentMdtObject:refreshUI()
        else
            logInfo.add(5, "not find refreshUI func")
        end

    end, __G__TRACKBACK__)

    self.contentMdtName = mdtName
end

-------------------------------------------------
-- handler
function CapsuleBasicSkinStoreMediator:onClickCellAction(sender)
    PlayAudioByClickNormal()
    local mallType = sender:getUserTag()
    if self.selectedMallType == mallType then return end

    local childMallTypes = self.tabList[mallType].childTabTypes
    if childMallTypes then
        local item = sender:getParent():getItemNodeAtIndex(0)
        mallType = item:getTag()
    end
    
    self.selectedMallType = mallType
    self:refreshUI()
    
end
function CapsuleBasicSkinStoreMediator:onClickItemAction(sender)
    PlayAudioByClickNormal()
    local mallType = sender:getUserTag()
    if self.selectedMallType == mallType then return end

    self.selectedMallType = mallType
    self:refreshUI()
end

function CapsuleBasicSkinStoreMediator:onClickBackBtnAction(sender)
    app:UnRegsitMediator(self.contentMdtName)
    app:UnRegsitMediator(NAME)
end

return CapsuleBasicSkinStoreMediator
