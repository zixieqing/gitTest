--[[
 * author : panmeng
 * descpt : 猫屋猫咪生活界面
]]

local CatModuleCatLifeView = class('CatModuleCatLifeView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleCatLifeView', enableEvent = true})
end)

CatModuleCatLifeView.CAT_LIVE_TYPE = {
    OTHER  = 0, -- 其他
    FEED   = 1, -- 喂食
    BATH   = 2, -- 洗澡
    PLAY   = 3, -- 玩耍
    SLEEP  = 4, -- 睡眠
    TOILET = 5, -- 如厕
}

CatModuleCatLifeView.FEED_GOOD_TYPE = {
    FOOD    = 1, -- 食品
    DRUG    = 2, -- 药品
}

local ACTION_DEFINE = {
    [CatModuleCatLifeView.CAT_LIVE_TYPE.FEED]   = {title = __("喂食"), img = _res("ui/catModule/catInfo/life/grow_cat_life_ico_food.png"),   attrId = 102},
    [CatModuleCatLifeView.CAT_LIVE_TYPE.BATH]   = {title = __("洗澡"), img = _res("ui/catModule/catInfo/life/grow_cat_life_ico_shower.png"), attrId = 105},
    [CatModuleCatLifeView.CAT_LIVE_TYPE.PLAY]   = {title = __("玩耍"), img = _res("ui/catModule/catInfo/life/grow_cat_life_ico_play.png"),   attrId = 104},
    [CatModuleCatLifeView.CAT_LIVE_TYPE.SLEEP]  = {title = __("睡觉"), img = _res("ui/catModule/catInfo/life/grow_cat_life_ico_sleep.png"),  attrId = 103},
    [CatModuleCatLifeView.CAT_LIVE_TYPE.TOILET] = {title = __("如厕"), img = _res("ui/catModule/catInfo/life/grow_cat_life_ico_toilet.png"), attrId = 101},
}

local GOOD_TYPE_DEFINE = {
    [CatModuleCatLifeView.FEED_GOOD_TYPE.FOOD] = { title = __("食物"), scale = 1},
    [CatModuleCatLifeView.FEED_GOOD_TYPE.DRUG] = { title = __("药品"), scale = -1},
}

local RES_DICT = {
    FRAME_DETAIL  = _res('ui/catModule/catInfo/life/grow_cat_life_bg_wood_use.png'),
    BG_GOODS      = _res('ui/catModule/catInfo/life/grow_cat_life_bg_wood_top.png'),
    FRAME_GOODS   = _res('ui/catModule/catInfo/life/grow_cat_life_bg_wood.png'),
    BG_DETAIL     = _res('ui/catModule/catInfo/life/grow_cat_life_bg_wood_use_goods.png'),
    BTN_TITLE_S   = _res('ui/catModule/catInfo/life/grow_cat_life_btn_class_light.png'),
    BTN_TITLE_N   = _res('ui/catModule/catInfo/life/grow_cat_life_btn_class_drak.png'),
    BTN_TITLE_BG  = _res('ui/catModule/catInfo/life/grow_cat_life_bg_wood_small.png'),
    BTN_ACTION_L  = _res('ui/catModule/catInfo/life/grow_cat_life_btn_module_light.png'),
    BTN_ACTION_N  = _res('ui/catModule/catInfo/life/grow_cat_life_btn_module.png'),
    BTN_ACTION_S  = _res('ui/catModule/catInfo/life/grow_cat_life_btn_module_choose.png'),
    IMG_ENPTY     = _res('ui/catModule/catInfo/life/grow_cat_life_pic_empty.png'),
    BG_ILLNESS    = _res('ui/catModule/catInfo/life/grow_cat_life_bg_wood_tips_illness.png'),
    TITLE_ILLNESS = _res('ui/catModule/catInfo/life/grow_cat_life_bg_wood_tips_illness_small.png'),
    POWER_TIP     = _res('ui/catModule/catInfo/life/grow_cat_life_bg_wood_tips.png'),
    BG_DESCR      = _res('ui/common/commcon_bg_text.png'),
    BTN_CONFIRM   = _res('ui/common/common_btn_orange.png'),
    DRUG_SICK_IMG = _res('ui/catModule/catInfo/life/grow_cat_life_bg_class_light.png'),
    FEED_SICK_IMG = _res('ui/catModule/catInfo/life/grow_cat_life_bg_module_choose_light.png'),
}


function CatModuleCatLifeView:ctor(args)
    -- create view
    self.viewData_ = CatModuleCatLifeView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatModuleCatLifeView:getViewData()
    return self.viewData_
end

function CatModuleCatLifeView:getDisplayAttrId(catLiveType)
    return ACTION_DEFINE[catLiveType] and ACTION_DEFINE[catLiveType].attrId or 0
end

---------------------------------------------------------------------------------
-- public
---@param catModel HouseCatModel
function CatModuleCatLifeView:refreshGoodDetailView(goodsId, catLiveType, catModel)
    local isGoodExist = goodsId > 0
    self:getViewData().goodDetailView:setVisible(isGoodExist)
    if isGoodExist then
        self:getViewData().goodsNode:RefreshSelf({goodsId = goodsId})
        local isAvatar = catLiveType == self.CAT_LIVE_TYPE.TOILET or catLiveType == self.CAT_LIVE_TYPE.SLEEP
        local goodConf = isAvatar and CONF.CAT_HOUSE.AVATAR_INFO:GetValue(goodsId) or CONF.CAT_HOUSE.CAT_GOODS_INFO:GetValue(goodsId)
        self:getViewData().goodDescr:setString(goodConf.descr)

        local scrollSize = self:getViewData().descrScroll:getContentSize()
        local descrStrH  = display.getLabelContentSize(self:getViewData().goodDescr).height
        self:getViewData().descrScroll:setContainerSize(cc.size(scrollSize.width, math.max(scrollSize.height, descrStrH + 10)))
        self:getViewData().goodDescr:alignTo(nil, ui.ct, {offsetY = -5})
        self:getViewData().descrScroll:setContentOffsetToTop()

        display.commonLabelParams(self:getViewData().goodNameLabel, {text = goodConf.name, hAlign = display.TAC})

        local isDrug = not isAvatar and checkint(goodConf.type) == CatHouseUtils.CAT_GOODS_TYPE.DRUG
        self:getViewData().illnessLayer:setVisible(isDrug)
        self:getViewData().stateLayer:setVisible(not isDrug)
        if not isDrug then
            local attrId = ACTION_DEFINE[catLiveType].attrId
            self:updateAttrNum(catModel, attrId)
        end
    end
end


---@param catModel HouseCatModel
function CatModuleCatLifeView:updateAttrNum(catModel, attrId)
    local attrConf  = CONF.CAT_HOUSE.CAT_ATTR:GetValue(attrId)
    local curNum    = catModel:getAttrNum(attrId)
    local maxNum    = catModel:getAttrMax(attrId)
    self:getViewData().stateName:updateLabel({text = string.fmt(__("当前_name_"), {_name_ = tostring(attrConf.name)}), reqW = 340})
    self:getViewData().stateValue:setString(string.fmt("_num1_/_num2_", {_num1_ = math.min(curNum, maxNum), _num2_ = maxNum}))
end


-- update life btn statue
function CatModuleCatLifeView:updateGoodLifeBtnStatue(oldLifeIndex, newLifeIndex)
    if oldLifeIndex > 0 then
        self:getViewData().lifeBtnGroup[oldLifeIndex].setSelectedState(false)
    end
    self:getViewData().lifeBtnGroup[newLifeIndex].setSelectedState(true)
end


-- resize good grid view 
function CatModuleCatLifeView:reSizeGoodsPage(oldLifeIndex, newLifeIndex)
    if (oldLifeIndex ~= CatModuleCatLifeView.CAT_LIVE_TYPE.FEED and newLifeIndex ~= CatModuleCatLifeView.CAT_LIVE_TYPE.FEED) or oldLifeIndex <= 0 then
        return
    end
    self:getViewData().goodsTypeLayer:setVisible(newLifeIndex == CatModuleCatLifeView.CAT_LIVE_TYPE.FEED)
    if newLifeIndex == CatModuleCatLifeView.CAT_LIVE_TYPE.FEED then
        self:getViewData().goodsBgLayer:setContentSize(cc.size(367, 550))
        self:getViewData().goodsBgLayer.bg:setContentSize(cc.size(367, 550))
        self:getViewData().goodsGridView:setContentSize(cc.size(367, 550))
    else
        self:getViewData().goodsBgLayer:setContentSize(cc.size(367, 620))
        self:getViewData().goodsBgLayer.bg:setContentSize(cc.size(367, 620))
        self:getViewData().goodsGridView:setContentSize(cc.size(367, 620))
    end
end


---@param catModel HouseCatModel
function CatModuleCatLifeView:updateSickView(catModel)
    self:getViewData().illTableView:resetCellCount(table.nums(catModel:getSickIdMap()))
    self:getViewData().drugSickImg:setVisible(catModel:isSicked())
    self:getViewData().feedSickImg:setVisible(catModel:isSicked())
end
-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------
function CatModuleCatLifeView.CreateDetailView(width)
    local view = ui.layer()
    view:setVisible(false)

    local DETAIl_SIZE = cc.size(401, 658)

    -- [blockLayer]  | [detail layer]
    local bgLayerGroup = view:addList({
        ui.layer({size = DETAIl_SIZE, enable = true, color = cc.r4b(0)}),
        ui.layer({bg = RES_DICT.FRAME_DETAIL, size = DETAIl_SIZE, scale9 = true}),
    })
    ui.flowLayout(cc.rep(cc.sizep(view, ui.rc), -display.SAFE_L - width + 5, 0), bgLayerGroup, {type = ui.flowC, ap = ui.rc})

    -- [goodInfoLayer] | [illness info layer] | [button]
    local detailLayer = bgLayerGroup[2]
    local frameGroup = detailLayer:addList({
        ui.layer({bg = RES_DICT.BG_DETAIL, size = cc.size(394, 194), scale9 = true}),
        ui.layer({bg = RES_DICT.BG_ILLNESS}),
        ui.button({n = RES_DICT.BTN_CONFIRM, mt = 20}):updateLabel({fnt = FONT.D14, text = __("使用"), reqW = 110}),
    })
    ui.flowLayout(cc.rep(cc.sizep(detailLayer, ui.ct), 3, -15), frameGroup, {type = ui.flowV, ap = ui.cb, gapH = 20})

    -- goodsInfoLayer
    local goodDetailLayer = frameGroup[1]
    local goodDetailGroup = goodDetailLayer:addList({
        ui.goodsNode(),
        ui.layer({bg = RES_DICT.BG_DESCR, scale9 = true, size = cc.size(242, 162)}),
    })
    ui.flowLayout(cc.rep(cc.sizep(goodDetailLayer, ui.ct), 0, -15), goodDetailGroup, {type = ui.flowH, ap = ui.ct, gapW = 10})

    local goodNameLabel = ui.label({fnt = FONT.D4, color = "#6b5959", w = 130, fontSize = 20, ap = ui.ct})
    goodDetailLayer:addList(goodNameLabel):alignTo(goodDetailGroup[1], ui.cb, {offsetY = -5})

    local descrBg     = goodDetailGroup[2]
    local descrScroll = ui.scrollView({size = descrBg:getContentSize(), dir = display.SDIR_V})
    descrBg:addList(descrScroll):alignTo(nil, ui.cc, {offsetY = 1})

    local descrLabel  = ui.label({fnt = FONT.D9, color = "#70645b", w = 230, ap = ui.lt, text = "--"})
    descrScroll:getContainer():addList(descrLabel):alignTo(nil, ui.ct, {offsetY = -5})

    -- illnessLayer
    local illnessLayer = frameGroup[2]
    illnessLayer:addList(ui.label({fnt = FONT.D6, color = "#5c3a26", text = __("当前疾病"), reqW = 340})):alignTo(nil, ui.ct, {offsetY = -12})
    local illnessTableView = ui.tableView({dir = display.SDIR_V, csizeH = 38, size = cc.size(365, 245)})
    illnessLayer:addList(illnessTableView):alignTo(nil, ui.cb)
    illnessTableView:setCellCreateHandler(function(cellParent)
        local bg = ui.image({img = RES_DICT.TITLE_ILLNESS})
        cellParent:addList(bg):alignTo(nil, ui.cc)

        local descr = ui.label({fnt = FONT.D6, color = "#c02b13", text = "--"})
        cellParent:addList(descr):alignTo(nil, ui.cc)
        
        return{
            bg    = bg,
            descr = descr,
        }
    end)

    -- catState Layer
    local stateLayer = ui.layer({bg = RES_DICT.POWER_TIP})
    detailLayer:addList(stateLayer):alignTo(illnessLayer, ui.ct, {offsetY = -100})

    local stateInfoGroup = stateLayer:addList({
        ui.label({fnt = FONT.D6, color = "#5c3a26", text = "--"}),
        ui.label({fnt = FONT.D6, color = "#c02b13", text = "--"}),
    })
    ui.flowLayout(cc.sizep(stateLayer, ui.cc), stateInfoGroup, {type = ui.flowV, ap = ui.cc, gapH = 15})

    return {
        view          = view,
        goodsNode     = goodDetailGroup[1],
        goodDescr     = descrLabel,
        descrScroll   = descrScroll,
        illnessLayer  = illnessLayer,
        illTableView  = illnessTableView,
        stateLayer    = stateLayer,
        stateValue    = stateInfoGroup[2],
        stateName     = stateInfoGroup[1],
        btnUse        = frameGroup[3],
        goodNameLabel = goodNameLabel,
    }
end

function CatModuleCatLifeView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- block layer | center layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150), enable = true}),
        ui.layer(),
    })

    local centerLayer = backGroundGroup[2]

    --------------------------------------------------[goods layer]
    local GOOD_SIZE = cc.size(402, 744)
    local goodsFrameGroup = centerLayer:addList({
        ui.layer({size = GOOD_SIZE, enable = true, color = cc.r4b(0)}),
        ui.layer({bg = RES_DICT.FRAME_GOODS, size = GOOD_SIZE, scale9 = true}),
    })
    ui.flowLayout(cc.rep(cc.sizep(centerLayer, ui.rc), -display.SAFE_L, 0), goodsFrameGroup, {type = ui.flowC, ap = ui.rc})

    local goodsLayer = goodsFrameGroup[2]
    local goodsUiGroup = goodsLayer:addList({
        ui.label({fnt = FONT.D4, color = "#562f1a", text = __("选择道具"), mt = 30}),
        ui.layer({bg = RES_DICT.BTN_TITLE_BG, mt = 30}),
        ui.layer({bg = RES_DICT.BG_GOODS, scale9 = true, size = cc.size(367, 550), offset = cc.p(0, -275)}),
    })
    ui.flowLayout(cc.rep(cc.sizep(goodsLayer, ui.ct), 0, -20), goodsUiGroup, {type = ui.flowV, ap = ui.cb})


    -- feed type btn
    local titleLayer = goodsUiGroup[2]
    local titleBtnGroup = {}
    for btnTag, btnDefine in ipairs(GOOD_TYPE_DEFINE) do
        local titleBtn = CatModuleCatLifeView.CreateFeedBtn(btnDefine, btnTag)
        table.insert(titleBtnGroup, titleBtn)
    end
    titleLayer:addList(titleBtnGroup)
    ui.flowLayout(cc.sizep(titleLayer, ui.cc), titleBtnGroup, {type = ui.flowH, ap = ui.cc, gapW = -10})

    -- drug sick btn
    local drugBtn = titleBtnGroup[2]
    local drugSickImg = ui.image({img = RES_DICT.DRUG_SICK_IMG})
    drugBtn:addList(drugSickImg):alignTo(nil, ui.cc)
    drugSickImg:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5), cc.FadeOut:create(0.5))))


    -- good grid view
    local goodsNodeLayer = goodsUiGroup[3]
    goodsNodeLayer.bg:setAnchorPoint(ui.cb)
    local goodsGridView = ui.gridView({cols = 3, csizeH = 120, size = cc.size(367, 550), dir = display.SDIR_V, ap = ui.cb})
    goodsNodeLayer:addList(goodsGridView):alignTo(nil, ui.cb)
    goodsGridView:setCellCreateClass(require('common.GoodNode'), {showAmount = true})

    --------------------------------------------------[goods empty layer]
    local emptyLayer     = ui.layer({size = goodsNodeLayer:getContentSize()})
    goodsNodeLayer:addList(emptyLayer)

    local emptyViewGroup = emptyLayer:addList({
        ui.label({fnt = FONT.D4, color = "#957b64", text = __("暂无道具，请前往商店购买"), reqW = 350}),
        ui.image({img = RES_DICT.IMG_ENPTY}),
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("前 往"), reqW = 110}),
    })
    ui.flowLayout(cc.sizep(emptyLayer, ui.cc), emptyViewGroup, {type = ui.flowV, ap = ui.cc})

     --------------------------------------------------[goods detail layer]
    local detailViewData = CatModuleCatLifeView.CreateDetailView(goodsLayer:getContentSize().width)
    centerLayer:add(detailViewData.view)

    --------------------------------------------------[lift btns]
    local LIFE_BTN_SIZE = cc.size(120, 130 * #ACTION_DEFINE - 10)
    local lifeFrameGroup = centerLayer:addList({
        ui.layer({size = LIFE_BTN_SIZE, enable = true, color = cc.r4b(0)}),
        ui.layer({size = LIFE_BTN_SIZE}),
    })
    ui.flowLayout(cc.rep(cc.sizep(centerLayer, ui.lc), display.SAFE_L, 0), lifeFrameGroup, {type = ui.flowC, ap = ui.lc})

    local lifeBtnLayer = lifeFrameGroup[2]
    local lifeBtnGroup = {}
    local lifeBtnMap   = {}
    for btnTag, btnDefine in ipairs(ACTION_DEFINE) do
        local lifeBtn = CatModuleCatLifeView.CreateLifeBtn(btnDefine, btnTag)
        table.insert(lifeBtnGroup, lifeBtn)
        lifeBtnMap[btnTag] = lifeBtn
    end
    lifeBtnLayer:addList(lifeBtnGroup)
    ui.flowLayout(cc.sizep(lifeBtnLayer, ui.cc), lifeBtnGroup, {type = ui.flowV, ap = ui.cc, gapH = 10})

    -- feed sick img
    local feedSickBtn = lifeBtnGroup[1]
    local feedSickImg = ui.image({img = RES_DICT.FEED_SICK_IMG})
    feedSickBtn:addList(feedSickImg):alignTo(nil, ui.cc)
    feedSickImg:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5), cc.FadeOut:create(0.5))))
    
    return {
        view           = view,
        blockLayer     = backGroundGroup[1],
        goodsBgLayer   = goodsNodeLayer,
        goodsTypeLayer = titleLayer,
        goodsTypeBtns  = titleBtnGroup,
        emptyLayer     = emptyLayer,
        goodsNode      = detailViewData.goodsNode,
        goodDescr      = detailViewData.goodDescr,
        descrScroll    = detailViewData.descrScroll,
        illnessLayer   = detailViewData.illnessLayer,
        illTableView   = detailViewData.illTableView,
        stateLayer     = detailViewData.stateLayer,
        stateValue     = detailViewData.stateValue,
        stateName      = detailViewData.stateName,
        useBtn         = detailViewData.btnUse,
        goodNameLabel  = detailViewData.goodNameLabel,
        lifeBtnGroup   = lifeBtnMap,
        shopBtn        = emptyViewGroup[3],
        emptyTip       = emptyViewGroup[1],
        goodDetailView = detailViewData.view,
        goodsGridView  = goodsGridView,
        feedSickImg    = feedSickImg,
        drugSickImg    = drugSickImg,
    }
end


function CatModuleCatLifeView.CreateLifeBtn(btnDefine, btnTag)
    local lifeBtn = ui.tButton({n = RES_DICT.BTN_ACTION_N, s = RES_DICT.BTN_ACTION_S})
    lifeBtn:setTag(btnTag)
        
    -- selected img
    local selectedImg = ui.image({img = RES_DICT.BTN_ACTION_L})
    selectedImg:setVisible(false)
    lifeBtn:addList(selectedImg):alignTo(nil, ui.cc)

    -- icon
    local icon = ui.image({img = btnDefine.img, scale = 0.8})
    lifeBtn:addList(icon):alignTo(nil, ui.cc)

    -- title
    local btnDesc = ui.label({fnt = FONT.D14, outline = "#50262b", text = btnDefine.title, reqW = 120})
    lifeBtn:addList(btnDesc):alignTo(nil, ui.cb, {offsetY = 10})

    lifeBtn.setSelectedState = function(visible)
        selectedImg:setVisible(visible)
        lifeBtn:setChecked(visible)
    end

    return lifeBtn
end


function CatModuleCatLifeView.CreateFeedBtn(btnDefine, btnTag)
    local scale    = btnDefine.scale or 1
    local titleBtn = ui.tButton({n = RES_DICT.BTN_TITLE_N, s = RES_DICT.BTN_TITLE_S, scale = btnDefine.scale})
    titleBtn:setTag(btnTag)

    local selectedLabel = ui.label({fnt = FONT.D4, color = "#b05905", text = btnDefine.title, reqW = 160})
    selectedLabel:setScale(selectedLabel:getScale() * scale)
    titleBtn:getSelectedImage():addList(selectedLabel):alignTo(nil, ui.cc)

    local normalLabel = ui.label({fnt = FONT.D4, color = "#633d1e", text = btnDefine.title, reqW = 160})
    normalLabel:setScale(normalLabel:getScale() * scale)
    titleBtn:getNormalImage():addList(normalLabel):alignTo(nil, ui.cc)

    return titleBtn
end


return CatModuleCatLifeView
    