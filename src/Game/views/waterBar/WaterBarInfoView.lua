--[[
 * author : kaishiqi
 * descpt : 水吧 - 信息视图
]]
local CommonGoodsNode  = require('common.GoodNode')
local WaterBarInfoView = class('WaterBarInfoView', function()
    return ui.layer({name = 'Game.views.waterBar.WaterBarInfoView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME     = _res('ui/common/common_bg_13.png'),
    TITLE_BAR      = _res('ui/common/common_bg_title_2.png'),
    TAB_BTN_N      = _res('ui/home/lobby/information/setup_btn_tab_default.png'),
    TAB_BTN_S      = _res('ui/home/lobby/information/setup_btn_tab_select.png'),
    CONTENT_BG     = _res('ui/common/commcon_bg_text2.png'),
    --             = upgrade
    TIPS_ICON      = _res('ui/common/common_btn_tips_2.png'),
    INFO_FRAME     = _res('ui/home/lobby/information/restaurant_info_bg_awareness.png'),
    INFO_TITLE     = _res('ui/common/common_title_5.png'),
    INFO_PBAR_IMG  = _res('ui/home/lobby/information/restaurant_bar_exp_1.png'),
    INFO_PBAR_BG   = _res('ui/home/lobby/information/setup_bar_exp_2.png'),
    CONFIRM_BTN_N  = _res('ui/common/common_btn_orange.png'),
    --             = expire
    GOODS_FRAME    = _res('ui/common/common_bg_goods.png'),
    --             = bill
    BILL_TITLE     = _res('ui/home/lobby/information/restaurant_info_bar_title.png'),
    BILL_INFO_LINE = _res('ui/home/union/guild_shop_lock_wrod.png'),
    BILL_CELL_BG   = _res('ui/home/friend/friends_bg_brown.png'),
    BILL_DRINK_BG  = _res('ui/common/common_bg_list.png'),
}

local WATER_BAR_DEFINE   = FOOD.WATER_BAR.DEFINE
local INFO_PROXY_NAME    = FOOD.WATER_BAR.INFO.PROXY_NAME
local INFO_PROXY_STRUCT  = FOOD.WATER_BAR.INFO.PROXY_STRUCT
local INFO_TAB_FUNC_ENUM = FOOD.WATER_BAR.INFO.TAB_FUNC_ENUM

local TAB_FUNC_DEFINES = {
    [INFO_TAB_FUNC_ENUM.UPGRADE] = {name = __('水吧升级'),    keywords = 'Upgrade'},
    [INFO_TAB_FUNC_ENUM.BILL]    = {name = __('昨日营业账目'), keywords = 'Bill'},
    [INFO_TAB_FUNC_ENUM.EXPIRE]  = {name = __('昨日过期清单'), keywords = 'Expire'},
}


function WaterBarInfoView:ctor(args)
    -- init vars
    self.contentVDMap_ = {}

    -- create view
    self.viewData_ = WaterBarInfoView.CreateView()
    self:add(self.viewData_.view)

    -- bind model
    self.infoProxy_   = app:RetrieveProxy(INFO_PROXY_NAME)
    self.viewBindMap_ = {
        [INFO_PROXY_STRUCT.SELECT_TAB_INDEX]     = self.onUpdateTabFuncSelected_,
        [INFO_PROXY_STRUCT.WATER_BAR_LEVEL]      = {self.onUpdateUpgradeView_, self.onUpdateExpireView_},
        [INFO_PROXY_STRUCT.WATER_BAR_POPULARITY] = self.onUpdateUpgradeView_,
    }
    
    -- update view
    local handlerList = VoProxy.EventBind(INFO_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
end


function WaterBarInfoView:onCleanup()
    VoProxy.EventUnbind(INFO_PROXY_NAME, self.viewBindMap_, self)
end


function WaterBarInfoView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- handle

function WaterBarInfoView:onUpdateTabFuncSelected_(signal)
    local oldSelectIndex = signal and signal:GetBody().oldValue or 0
    local newSelectIndex = signal and signal:GetBody().newValue or 0

    -- update tabFuncBtn
    local oldTabFuncBtn = self:getViewData().tabBtnList[oldSelectIndex]
    local newTabFuncBtn = self:getViewData().tabBtnList[newSelectIndex]
    if oldTabFuncBtn then oldTabFuncBtn:setChecked(false) end
    if newTabFuncBtn then newTabFuncBtn:setChecked(true) end

    -- update contentView
    local oldContentVD = self.contentVDMap_[tostring(oldSelectIndex)]
    local newContentVD = self.contentVDMap_[tostring(newSelectIndex)]
    if oldContentVD then oldContentVD.view:setVisible(false) end
    if newContentVD then newContentVD.view:setVisible(true) end

    if newContentVD == nil and TAB_FUNC_DEFINES[newSelectIndex] then
        local functionKeywords = TAB_FUNC_DEFINES[newSelectIndex].keywords
        local createMethodName = string.fmt('Create%1View', functionKeywords)
        local initCallbackName = string.fmt('init%1Callback', functionKeywords)
        local onUpdateFuncName = string.fmt('onUpdate%1View_', functionKeywords)
        local onInitFuncName   = string.fmt('onInit%1View_', functionKeywords)
        -- create view
        local contentViewData  = WaterBarInfoView[createMethodName](self:getViewData().contentViewSize)
        contentViewData.view:setPosition(self:getViewData().contentOffsetPos)
        self:getViewData().contentFrameNode:add(contentViewData.view)
        self.contentVDMap_[tostring(newSelectIndex)] = contentViewData
        -- init callback
        if self[initCallbackName] then self[initCallbackName](contentViewData) end
        -- init view
        if self[onInitFuncName] then self[onInitFuncName](self) end
        -- update view
        if self[onUpdateFuncName] then self[onUpdateFuncName](self) end
    end
end


-------------------------------------------------
-- upgrade view

function WaterBarInfoView:onUpdateUpgradeView_(signal)
    local changedVoDefine = signal and signal:GetBody().voDefine or nil
    local contentViewData = self.contentVDMap_[tostring(INFO_TAB_FUNC_ENUM.UPGRADE)]
    if contentViewData == nil then return end

    local currentLevel = self.infoProxy_:get(INFO_PROXY_STRUCT.WATER_BAR_LEVEL)
    local maxBarLevel  = CONF.BAR.LEVEL_UP:GetLength()
    local nextBarLevel = math.min(currentLevel + 1, maxBarLevel)
    local nextBarConf  = CONF.BAR.LEVEL_UP:GetValue(nextBarLevel)

    -------------------------------------------------
    -- update barLevel
    if changedVoDefine == nil or changedVoDefine == INFO_PROXY_STRUCT.WATER_BAR_LEVEL then
        -- update currentLevel
        contentViewData.levelLabel:updateLabel({text = string.fmt(__('_num_级'), {_num_ = currentLevel})})
        
        -- reset costGoods / costGold
        contentViewData.costGoodsLayer:removeAllChildren()
        contentViewData.costGoldRLabel:reload()
        
        if currentLevel < maxBarLevel then
            local goodsNodeList = {}
            for i, goodsData in ipairs(nextBarConf.consumeGoods or {}) do
                local costGoodsNum  = checkint(goodsData.num)
                local haveGoodsNum  = CommonUtils.GetCacheProductNum(goodsData.goodsId)
                local isEnoughGoods = haveGoodsNum >= costGoodsNum

                -- update costGold
                if checkint(goodsData.goodsId) == GOLD_ID then
                    contentViewData.costGoldRLabel:reload({
                        {fnt = FONT.D3, color = isEnoughGoods and '#7c7c7c' or '#d23d3d', text = tostring(goodsData.num)},
                        {img = CommonUtils.GetGoodsIconPathById(GOLD_ID), scale = 0.18}
                    })

                -- create goodsNode
                else
                    local costGoodsNode = ui.goodsNode({id = goodsData.goodsId, scale = 0.9, gainCB = true, from = 'WaterBarHomeMediator'})
                    local goodsNodeSize = cc.size(costGoodsNode:getBoundingBox().width, costGoodsNode:getBoundingBox().height)
                    
                    -- goodsLayer
                    local goodsLayerNode = ui.layer({size = goodsNodeSize})
                    contentViewData.costGoodsLayer:add(goodsLayerNode)
                    table.insert(goodsNodeList, goodsLayerNode)

                    -- goodsNode
                    goodsLayerNode:addList(costGoodsNode):alignTo(nil, ui.cc)

                    -- goodsNum
                    local numLabelList = {}
                    if isEnoughGoods then
                        numLabelList = {
                            ui.bmfLabel({path = FONT.BMF_TEXT_W, text = string.fmt('%1/%2', haveGoodsNum, costGoodsNum)})
                        }
                    else
                        numLabelList = {
                            ui.bmfLabel({path = FONT.BMF_TEXT_U, text = haveGoodsNum, mr = 2}),
                            ui.bmfLabel({path = FONT.BMF_TEXT_W, text = '/' .. costGoodsNum})
                        }
                    end
                    ui.flowLayout(cc.p(goodsNodeSize.width - 6, 0), numLabelList, {ap = ui.rb})
                    goodsLayerNode:addList(numLabelList)
                end
            end
            ui.flowLayout(cc.sizep(contentViewData.costGoodsLayer, ui.cc), goodsNodeList, {ap = ui.cc, gapW = 40})
        end
    end

    -------------------------------------------------
    -- update popularity
    if changedVoDefine == nil or changedVoDefine == INFO_PROXY_STRUCT.WATER_BAR_POPULARITY then
        local popularityNow = self.infoProxy_:get(INFO_PROXY_STRUCT.WATER_BAR_POPULARITY)
        local popularityMax = checkint(nextBarConf.barPopularity)
        contentViewData.popularityPBar:setMaxValue(popularityMax)
        contentViewData.popularityPBar:setNowValue(popularityNow)
    end
end


-------------------------------------------------
-- bill view

function WaterBarInfoView:onInitBillView_()
    local contentViewData = self.contentVDMap_[tostring(INFO_TAB_FUNC_ENUM.BILL)]
    if contentViewData == nil then return end

    contentViewData.billTableView:setCellUpdateHandler(handler(self, self.onUpdateBillInfoCellHandler_))
end


function WaterBarInfoView:onUpdateBillView_(signal)
    local changedVoDefine = signal and signal:GetBody().voDefine or nil
    local contentViewData = self.contentVDMap_[tostring(INFO_TAB_FUNC_ENUM.BILL)]
    if contentViewData == nil then return end
    
    -- update expireGoods
    if changedVoDefine == nil then
        local billInfoCount = self.infoProxy_:size(INFO_PROXY_STRUCT.YESTERDAY_BILL_LIST)
        contentViewData.billTableView:resetCellCount(billInfoCount)
    end
end


function WaterBarInfoView:onUpdateBillInfoCellHandler_(cellIndex, cellViewData, changedVoDefine)
    if cellViewData == nil then return end

    local CELL_STRUCT = INFO_PROXY_STRUCT.YESTERDAY_BILL_LIST.BILL_DATA
    local cellVoProxy = self.infoProxy_:get(CELL_STRUCT, cellIndex)
    
    -- update customer
    local customerId   = cellVoProxy:get(CELL_STRUCT.CUSTOMER_ID)
    local customerConf = CONF.BAR.CUSTOMER:GetValue(customerId)
    cellViewData.customerHead:RefreshUI({cardData = {cardId = customerConf.cardId}})

    -- update consumrs
    local consumesDataSize = cellVoProxy:size(CELL_STRUCT.CONSUMES)
    local CONSUMRS_STRUCT  = CELL_STRUCT.CONSUMES.GOODS_DATA
    for index = 1, #cellViewData.consumrsGoodsList do
        local cellBgImg = cellViewData.consumrsBgList[index]
        local goodsNode = cellViewData.consumrsGoodsList[index]
        if index <= consumesDataSize then
            local consumrsVoProxy  = cellVoProxy:get(CONSUMRS_STRUCT, index)
            local consumrsGoodsId  = consumrsVoProxy:get(CONSUMRS_STRUCT.GOODS_ID)
            local consumrsGoodsNum = consumrsVoProxy:get(CONSUMRS_STRUCT.GOODS_NUM)
            cellBgImg:setVisible(false)
            goodsNode:setVisible(true)
            goodsNode:RefreshSelf({
                goodsId = consumrsGoodsId,
                amount  = consumrsGoodsNum,
            })
        else
            cellBgImg:setVisible(true)
            goodsNode:setVisible(false)
        end
    end

    -- update rewards
    local rewardsDataSize = cellVoProxy:size(CELL_STRUCT.REWARDS)
    local REWARDS_STRUCT  = CELL_STRUCT.REWARDS.GOODS_DATA
    for index, goodsNode in ipairs(cellViewData.rewardGoodsList) do
        if index <= rewardsDataSize then
            local rewardVoProxy  = cellVoProxy:get(REWARDS_STRUCT, index)
            local rewardGoodsId  = rewardVoProxy:get(REWARDS_STRUCT.GOODS_ID)
            local rewardGoodsNum = rewardVoProxy:get(REWARDS_STRUCT.GOODS_NUM)
            goodsNode:setVisible(true)
            goodsNode:RefreshSelf({
                goodsId = rewardGoodsId,
                amount  = rewardGoodsNum,
            })
        else
            goodsNode:setVisible(false)
        end
    end
end


-------------------------------------------------
-- expire view

function WaterBarInfoView:onInitExpireView_()
    local contentViewData = self.contentVDMap_[tostring(INFO_TAB_FUNC_ENUM.EXPIRE)]
    if contentViewData == nil then return end

    contentViewData.goodsGridView:setCellUpdateHandler(handler(self, self.onUpdateExpireGoodsCellHandler_))
end


function WaterBarInfoView:onUpdateExpireView_(signal)
    local changedVoDefine = signal and signal:GetBody().voDefine or nil
    local contentViewData = self.contentVDMap_[tostring(INFO_TAB_FUNC_ENUM.EXPIRE)]
    if contentViewData == nil then return end
    
    -- update barLevel
    if changedVoDefine == nil or changedVoDefine == INFO_PROXY_STRUCT.WATER_BAR_LEVEL then
        -- update currentLevel
        local currentLevel = self.infoProxy_:get(INFO_PROXY_STRUCT.WATER_BAR_LEVEL)
        contentViewData.levelLabel:updateLabel({text = string.fmt(__('_num_级'), {_num_ = currentLevel})})
    end

    -- update expireGoods
    if changedVoDefine == nil then
        local goodsCount = self.infoProxy_:size(INFO_PROXY_STRUCT.YESTERDAY_EXPIRE_LIST)
        contentViewData.goodsGridView:resetCellCount(goodsCount)
    end
end


function WaterBarInfoView:onUpdateExpireGoodsCellHandler_(cellIndex, cellViewData, changedVoDefine)
    if cellViewData == nil then return end

    local CELL_STRUCT = INFO_PROXY_STRUCT.YESTERDAY_EXPIRE_LIST.GOODS_DATA
    local cellVoProxy = self.infoProxy_:get(CELL_STRUCT, cellIndex)

    -- update goodsNode
    local goodsId  = cellVoProxy:get(CELL_STRUCT.GOODS_ID)
    local goodsNum = cellVoProxy:get(CELL_STRUCT.GOODS_NUM)
    cellViewData.goodsNode:RefreshSelf({goodsId = goodsId, num = goodsNum})
end


-------------------------------------------------------------------------------
-- view struct
-------------------------------------------------------------------------------

function WaterBarInfoView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black layer
    view:add(ui.layer({color = cc.c4b(0,0,0,150)}))
    
    -- block layer
    local blockLayer = ui.layer({color = cc.r4b(0), enable = true})
    view:add(blockLayer)


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)


    -- title bar
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.TEXT24, color = '#FFEECF', text = __('水吧信息'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    viewFrameNode:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -11})

    -- tab funcList
    local tabBtnList = {}
    for index, define in pairs(TAB_FUNC_DEFINES) do
        local tabFuncBtn    = ui.tButton({n = RES_DICT.TAB_BTN_N, s = RES_DICT.TAB_BTN_S, tag = index})
        local tabFuncSLabel = ui.label({fnt = FONT.TEXT24, color = '#76553b', text = define.name}):alignTo(tabFuncBtn, ui.cc, {parent = true})
        local tabFuncNLabel = ui.label({fnt = FONT.TEXT24, color = '#FFFFFF', text = define.name}):alignTo(tabFuncBtn, ui.cc, {parent = true})
        tabFuncBtn:getSelectedImage():add(tabFuncNLabel)
        tabFuncBtn:getNormalImage():add(tabFuncSLabel)
        tabBtnList[index] = tabFuncBtn
    end
    ui.flowLayout(cc.p(52, viewFrameSize.height - 70), tabBtnList, {type = ui.flowV, ap = ui.lb, gapH = 10})
    viewFrameNode:addList(tabBtnList)
    
    -- content frameNode
    local contentFrameNode = ui.layer({bg = RES_DICT.CONTENT_BG, scale9 = true, size = cc.size(755, 550)})
    viewFrameNode:addList(contentFrameNode):alignTo(nil, ui.rc, {offsetX = -53, offsetY = -22})

    
    local contentOffsetPos = cc.p(2, 2)
    local contentViewSize  = cc.resize(contentFrameNode:getContentSize(), -contentOffsetPos.x*2, -contentOffsetPos.y*2)
    return {
        view             = view,
        blackLayer       = blackLayer,
        blockLayer       = blockLayer,
        --               = center
        tabBtnList       = tabBtnList,
        updateBtn        = tabBtnList[1],
        billBtn          = tabBtnList[2],
        expireBtn        = tabBtnList[3],
        contentFrameNode = contentFrameNode,
        contentOffsetPos = contentOffsetPos,
        contentViewSize  = contentViewSize,
    }
end


function WaterBarInfoView.CreateUpgradeView(size)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    -- level info
    local levelInfoGroup = view:addList({
        ui.image({img = RES_DICT.TIPS_ICON, mr = 10}),
        ui.label({fnt = FONT.D6, text = __('当前水吧规模：')}),
        ui.label({fnt = FONT.D11, ap = ui.lc}),
    })
    ui.flowLayout(cc.p(10, size.height - 25), levelInfoGroup, {ap = ui.lc})

    
    -------------------------------------------------
    -- popularity layer
    local popularitySize  = cc.size(size.width, 120)
    local popularityLayer = ui.layer({y = size.height-170, bg = RES_DICT.INFO_FRAME, size = popularitySize, cut = cc.dir(5,5,5,5)})
    view:add(popularityLayer)

    -- popularity title
    local popularityTitle = ui.title({img = RES_DICT.INFO_TITLE}):updateLabel({fnt = FONT.D4, text = __('知名度'), paddingW = 50})
    popularityLayer:addList(popularityTitle):alignTo(nil, ui.ct, {offsetY = -10})

    -- popularity info
    local popularityInfoGroup = popularityLayer:addList({
        ui.goodsImg({goodsId = FOOD.GOODS.DEFINE.WATER_BAR_POPULARITY_ID, scale = 0.25, ml = 25, mr = 5}),
        ui.label({fnt = FONT.D4, text = CommonUtils.GetCacheProductName(FOOD.GOODS.DEFINE.WATER_BAR_POPULARITY_ID), mr = 15}),
        ui.pBar({img = RES_DICT.INFO_PBAR_IMG, bg = RES_DICT.INFO_PBAR_BG, ap = ui.lc, label = true}):updateLabel({fnt = FONT.D19, fontSize = 24}),
    })
    ui.flowLayout(cc.p(0, popularitySize.height/2 - 15), popularityInfoGroup, {ap = ui.lc})

    -- popularity bar
    local popularityPBar = popularityInfoGroup[3]
    popularityPBar:setWidth(popularitySize.width - popularityPBar:getPositionX() - 50)


    -------------------------------------------------
    -- update iinfo
    local updateInfoGroup = view:addList({
        ui.title({img = RES_DICT.INFO_TITLE}):updateLabel({fnt = FONT.D4, text = __('升级材料'), paddingW = 50}),
        ui.layer({size = cc.size(size.width, 180)}),
        ui.button({n = RES_DICT.CONFIRM_BTN_N}):updateLabel({fnt = FONT.D14, text = __('升级')}),
        ui.rLabel({h = 24}),
    })
    ui.flowLayout(cc.p(size.width/2, 30), updateInfoGroup, {ap = ui.ct, type = ui.flowV, gapH = 10})

    return {
        view           = view,
        levelLabel     = levelInfoGroup[3],
        popularityPBar = popularityPBar,
        costGoodsLayer = updateInfoGroup[2],
        upateLevelBtn  = updateInfoGroup[3],
        costGoldRLabel = updateInfoGroup[4],
    }
end


function WaterBarInfoView.CreateBillView(size)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)
    
    -- expireGoods title
    local billTitle = ui.title({img = RES_DICT.INFO_TITLE}):updateLabel({fnt = FONT.D4, text = __('昨日营业账目'), paddingW = 50})
    view:addList(billTitle):alignTo(nil, ui.ct, {offsetY = -10})
    
    -- bill title list
    local titleBorder    = 3
    local titleGapW      = 2
    local titleHeight    = 34
    local customerSize   = cc.size(90, titleHeight)
    local drinksSize     = cc.size(405, titleHeight)
    local rewardsSize    = cc.size(size.width - customerSize.width - drinksSize.width - titleBorder*2 - titleGapW*2, titleHeight)
    local listTitleGroup = view:addList({
        ui.title({img = RES_DICT.BILL_TITLE, cut = cc.dir(1,1,1,1), size = customerSize}):updateLabel({fnt = FONT.D18, text = __('客人')}),
        ui.title({img = RES_DICT.BILL_TITLE, cut = cc.dir(1,1,1,1), size = drinksSize}):updateLabel({fnt = FONT.D18, text = __('饮品')}),
        ui.title({img = RES_DICT.BILL_TITLE, cut = cc.dir(1,1,1,1), size = rewardsSize}):updateLabel({fnt = FONT.D18, text = __('奖励')}),
    })
    ui.flowLayout(cc.rep(billTitle, 0, -40), listTitleGroup, {ap = ui.cc, gapW = titleGapW})

    -- bill gridView
    local billTableGap  = titleBorder
    local billTableSize = cc.resize(size, -billTableGap*2 + 4, -billTableGap*2 - 80)
    local billTableView = ui.tableView({size = billTableSize, csizeH = 85, dir = display.SDIR_V})
    billTableView:setCellCreateHandler(WaterBarInfoView.CreateBillInfoCell, {
        infoGapW  = titleGapW,
        customerW = customerSize.width,
        drinksW   = drinksSize.width,
        rewardsW  = rewardsSize.width
    })
    view:addList(billTableView):alignTo(nil, ui.lb, {offsetX = billTableGap, offsetY = billTableGap})

    return {
        view          = view,
        billTableView = billTableView,
    }
end


function WaterBarInfoView.CreateBillInfoCell(cellParent, createArgs)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- bg img
    view:addChild(ui.image({p = cc.rep(cpos, -2, -1), img = RES_DICT.BILL_CELL_BG, size = cc.resize(size, -6, -3), cut = cc.dir(8,8,8,8)}))


    -- info layer
    local infoLayerGroup = view:addList({
        ui.layer({size = cc.size(createArgs.customerW, size.height)}),
        ui.layer({size = cc.size(createArgs.drinksW, size.height)}),
        ui.layer({size = cc.size(createArgs.rewardsW, size.height)}),
    })
    ui.flowLayout(cc.p(0,0), infoLayerGroup, {ap = ui.lb, gapW = createArgs.infoGapW})

    -- cut line
    local infoLineGroup = view:addList({
        ui.image({img = RES_DICT.BILL_INFO_LINE, rotation = 90, scaleX = 0.5, scaleY = 0.1, alpha = 50, ml = createArgs.customerW-2}),
        ui.image({img = RES_DICT.BILL_INFO_LINE, rotation = 90, scaleX = 0.5, scaleY = 0.1, alpha = 50, ml = createArgs.drinksW-2}),
    })
    ui.flowLayout(cc.p(0,2), infoLineGroup, {ap = ui.lb, gapW = createArgs.infoGapW})


    -- customer head
    local customerLayer = infoLayerGroup[1]
    local customerHead  = ui.cardHeadNode({p = cc.sizep(customerLayer, ui.cc), scale = 0.40})
    customerLayer:add(customerHead)


    -- update consumrs
    local CONSUMRS_CELL_MAX = 5
    local drinksLayer       = infoLayerGroup[2]
    local consumrsBgList    = {}
    local consumrsGoodsList = {}
    local drinksCellBasePos = cc.rep(cc.sizep(drinksLayer, ui.lc), 7, 0)
    for index = 1, CONSUMRS_CELL_MAX do
        consumrsBgList[index]    = ui.image({img = RES_DICT.BILL_DRINK_BG, size = cc.size(74,74), cut = cc.dir(5,5,5,5)})
        consumrsGoodsList[index] = ui.goodsNode({scale = 0.68, defaultCB = true})
    end
    drinksLayer:addList(consumrsBgList)
    drinksLayer:addList(consumrsGoodsList)
    ui.flowLayout(drinksCellBasePos, consumrsBgList, {ap = ui.lc, gapW = 5})
    ui.flowLayout(drinksCellBasePos, consumrsGoodsList, {ap = ui.lc, gapW = 5})
    
    
    -- update rewards
    local REWARDS_CELL_MAX = 3
    local rewardsLayer     = infoLayerGroup[3]
    local rewardGoodsList  = {}
    for index = 1, REWARDS_CELL_MAX do
        rewardGoodsList[index] = ui.goodsNode({scale = 0.68, showAmount = true, defaultCB = true})
    end
    rewardsLayer:addList(rewardGoodsList)
    ui.flowLayout(cc.rep(cc.sizep(rewardsLayer, ui.lc), 8, 0), rewardGoodsList, {ap = ui.lc, gapW = 5})

    return {
        view              = view,
        customerHead      = customerHead,
        consumrsBgList    = consumrsBgList,
        consumrsGoodsList = consumrsGoodsList,
        rewardGoodsList   = rewardGoodsList,
    }
end


function WaterBarInfoView.CreateExpireView(size)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    -- level info
    local levelInfoGroup = view:addList({
        ui.image({img = RES_DICT.TIPS_ICON, mr = 10}),
        ui.label({fnt = FONT.D6, text = __('当前水吧规模：')}),
        ui.label({fnt = FONT.D11, ap = ui.lc}),
    })
    ui.flowLayout(cc.p(10, size.height - 25), levelInfoGroup, {ap = ui.lc})


    -- expireGoods layer
    local expireGoodsSize  = cc.resize(size, 0, -50)
    local expireGoodsLayer = ui.layer({bg = RES_DICT.INFO_FRAME, size = expireGoodsSize, cut = cc.dir(5,5,5,5)})
    view:add(expireGoodsLayer)

    -- expireGoods title
    local expireGoodsTitle = ui.title({img = RES_DICT.INFO_TITLE}):updateLabel({fnt = FONT.D4, text = __('昨日过期清单'), paddingW = 50})
    expireGoodsLayer:addList(expireGoodsTitle):alignTo(nil, ui.ct, {offsetY = -15})

    -- goods grid
    local goodsGridSize  = cc.resize(expireGoodsSize, -46, -76)
    local goodsGridGroup = expireGoodsLayer:addList({
        ui.image({img = RES_DICT.GOODS_FRAME, scale9 = true, size = cc.resize(goodsGridSize, 22, 6)}),
        ui.gridView({cols = 5, size = goodsGridSize, csizeAdd = cc.size(0,15), dir = display.SDIR_V, mb = 1}):setCellCreateHandler(WaterBarInfoView.CreateExpireGoodsCell),
    })
    ui.flowLayout(cc.rep(cc.sizep(expireGoodsSize, ui.cc), 0, -25), goodsGridGroup, {type = ui.flowC, ap = ui.cc})


    return {
        view          = view,
        levelLabel    = levelInfoGroup[3],
        goodsGridView = goodsGridGroup[2],
    }
end


function WaterBarInfoView.CreateExpireGoodsCell(cellParent)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local goodsNode = ui.goodsNode({p = cpos, showAmount = true, defaultCB = true, from = 'WaterBarHomeMediator'})
    view:add(goodsNode)

    return {
        view      = view,
        goodsNode = goodsNode,
    }
end


return WaterBarInfoView
