--[[
 * author : panmeng
 * descpt : 猫屋好友详情
]]

local CatModuleFriendDetailView = class('CatModuleFriendDetailView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleFriendDetailView', enableEvent = true})
end)

local RES_DICT = {
    LIST_FRAME   = _res('ui/catHouse/breed/grow_birth_list_details_bg_list.png'),
    COM_TITLE    = _res('ui/common/common_title_5.png'),
    DETAIL_FRAME = _res('ui/catModule/catRecord/grow_cat_record_love_bg_message.png'),
    CAT_FRAME    = _res('ui/catModule/catRecord/grow_cat_record_love_bg_photo.png'),
    TITLE_BG     = _res('ui/catModule/catRecord/grow_cat_record_love_bg_nwes.png'),
    LINE_BG      = _res('ui/catModule/catRecord/grow_cat_record_love_line_message.png'),
    CAT_BG       = _res('ui/catModule/catList/grow_main_list_bg_cat_back.png'),
    GIRL_ICON    = _res('ui/catModule/catList/grow_main_list_ico_f.png'),
    BOY_ICON     = _res('ui/catModule/catList/grow_main_list_ico_m.png'),
    FILTER_BG    = _res('ui/home/cardslistNew/tujian_selection_frame_1.png'),
    PROG_BG      = _res('ui/catModule/catRecord/grow_cat_record_love_line_friend_back.png'),
    PROG_IMG     = _res('ui/catModule/catRecord/grow_cat_record_love_line_friend_front.png'),
    ICON_IMG     = _res('ui/catModule/catRecord/grow_cat_record_love_ico_lv.png'),
    GENE_TITLE   = _res("ui/catModule/catRecord/grow_cat_record_news_bg_head.png"),
}


function CatModuleFriendDetailView:ctor(args)
    -- create view
    self.viewData_ = CatModuleFriendDetailView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatModuleFriendDetailView:getViewData()
    return self.viewData_
end


---@param catModel HouseCatModel
function CatModuleFriendDetailView:updatePageView(friendCatData, catModel)
    if not friendCatData or next(friendCatData) == nil then
        return
    end
    local viewData = self:getViewData()

    -- update friendName
    local friendData = CommonUtils.GetFriendData(friendCatData.friendId)
    viewData.friendNameLabel:updateLabel({text = friendData.name})

    -- update cat data
    viewData.sexIcon:setChecked(checkint(friendCatData.sex) == CatHouseUtils.CAT_SEX_TYPE.GIRL)
    viewData.catNameLabel:setString(friendCatData.name)
    viewData.algebraLabel:setString(friendCatData.generation)
    local ageConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(friendCatData.age)
    if next(ageConf) ~= nil then
        viewData.ageLabel:setString(ageConf.name)
    end
    viewData.rebirthNumLabel:setString(friendCatData.rebirth == 1 and __("是") or __("否"))
    viewData.lvlTitle:updateLabel({text = catModel:getLikeFriendCatLevel(friendCatData.friendCatUuid)})
    viewData.geneGridView:resetCellCount(#friendCatData.gene)

    local geneNum = friendCatData.gene and #friendCatData.gene or 0
    viewData.geneGridView:resetCellCount(geneNum)

    -- update catSpine
    viewData.catNodeLayer:removeAllChildren()
    local catSpineNode = CatHouseUtils.GetCatSpineNode({catData = {gene = friendCatData.gene, catId = friendCatData.catId, age = friendCatData.age}, scale = 0.7})
    viewData.catNodeLayer:addList(catSpineNode):alignTo(nil, ui.cc, {offsetY = 20})

    -- update like
    local likeLevel    = catModel:getLikeFriendCatLevel(friendCatData.friendCatUuid)
    local maxLevel     = CONF.CAT_HOUSE.CAT_LIKE_LEVEL:GetLength()
    local nextLikeConf = CONF.CAT_HOUSE.CAT_LIKE_LEVEL:GetValue(likeLevel + 1)
    if next(nextLikeConf) == nil then
        viewData.progress:setValue(100)
        viewData.proLabel:setString("MAX")
    else
        local likeExp     = catModel:getLikeFriendCatExp(friendCatData.friendCatUuid) - checkint(nextLikeConf.totalExp) + checkint(nextLikeConf.exp)
        viewData.progress:setValue(math.floor(likeExp / checkint(nextLikeConf.exp) * 100))
        viewData.proLabel:setString(string.fmt("_num1_/_num2_", {_num1_ = likeExp, _num2_ = nextLikeConf.exp}))
    end

    -- update cat descr
    local descr = __("这是一只_descr__name_")
    local geneDescr = ""
    for index, geneId in ipairs(friendCatData.gene) do
        local geneConf = CONF.CAT_HOUSE.CAT_GENE:GetValue(geneId)
        geneDescr = geneDescr .. tostring(geneConf.descr2)
    end
    local raceConf = CONF.CAT_HOUSE.CAT_RACE:GetValue(friendCatData.catId)
    local raceDescr = tostring(raceConf.name)
    viewData.descrLabel:setString(string.fmt(descr, {_descr_ = geneDescr, _name_ = raceDescr}))
    local descrSize      = display.getLabelContentSize(viewData.descrLabel)
    local scrollViewSize = viewData.descrScrollView:getContentSize()
    local containerH     = math.max(scrollViewSize.height, descrSize.height + 10)
    viewData.descrScrollView:setContainerSize(cc.size(scrollViewSize.width, math.max(containerH, scrollViewSize.height)))
    viewData.descrLabel:setPosition(cc.p(10, containerH - 5))
end
-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleFriendDetailView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150), enable = true}),
        ui.layer(),
    })
    local centerLayer = backGroundGroup[2]

    -------------------------------------------------------------- catListView
    local catListLayer = ui.layer({bg = RES_DICT.LIST_FRAME})
    local catListSize  = catListLayer:getContentSize()
    local catListGroup = centerLayer:addList({
        ui.layer({size = catListSize, color = cc.r4b(0), enable = true}),
        catListLayer,
    })
    ui.flowLayout(cc.p(display.SAFE_R, display.height / 2), catListGroup, {type = ui.flowC, ap = ui.rc})

    local catTableView = ui.tableView({size = cc.resize(catListLayer:getContentSize(), -30, -70), csizeH = 210, dir = display.SDIR_V})
    catListLayer:addList(catTableView):alignTo(nil, ui.cc, {offsetY = -10})
    catTableView:setCellCreateClass(require("Game.views.catModule.cat.CatHeadNode"), {size = cc.size(240, 200)})

    local titleBar = ui.title({img = RES_DICT.COM_TITLE}):updateLabel({fnt = FONT.D4, fontSize = 18, text = __('猫猫列表'), paddingW = 20, safeW = 120})
    catListLayer:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -13})

    -------------------------------------------------------------- catDetailPopup
    local catDetailViewData = CatModuleFriendDetailView.CreateCatDetailLayer()
    local catDetailView     = catDetailViewData.catDetailBg
    local catDetailSize     = cc.resize(catDetailView:getContentSize(), -60, -80)
    local catDetailGroup = centerLayer:addList({
        ui.layer({size = catDetailSize, color = cc.r4b(0), enable = true, mt = 10}),
        catDetailView,
    })
    local offsetX = display.SAFE_RECT.width * 0.5 - catListSize.width - catDetailSize.width * 0.5
    ui.flowLayout(cc.rep(cpos, math.min(offsetX, 0), 0), catDetailGroup, {type = ui.flowC, ap = ui.cc})

    return {
        view            = view,
        blackLayer      = backGroundGroup[1],
        catDetailBg     = catDetailView,
        scrollView      = catDetailViewData.scrollView,
        sexIcon         = catDetailViewData.sexIcon,
        catNodeLayer    = catDetailViewData.catNodeLayer,
        catNameLabel    = catDetailViewData.catNameLabel,
        algebraLabel    = catDetailViewData.algebraLabel,
        ageLabel        = catDetailViewData.ageLabel,
        rebirthNumLabel = catDetailViewData.rebirthNumLabel,
        descrLabel      = catDetailViewData.descrLabel,
        geneGridView    = catDetailViewData.geneGridView,
        progress        = catDetailViewData.progress,
        lvlTitle        = catDetailViewData.lvlTitle,
        proLabel        = catDetailViewData.proLabel,
        descrScrollView = catDetailViewData.descrScrollView,
        friendNameLabel = catDetailViewData.friendNameLabel,
        detailView      = catListLayer,
        catTableView    = catTableView,
    }
end


function CatModuleFriendDetailView.CreateCatDetailLayer()
    local catDetailBg    = ui.layer({size = size, bg = RES_DICT.DETAIL_FRAME, scale9 = true})

    local title = ui.label({fnt = FONT.D14, color = "#f6cc83", outline = "#955510", text = __('好友详情')})
    catDetailBg:addList(title):alignTo(nil, ui.ct, {offsetY = -40, offsetX = -30})

    local frameGroup = catDetailBg:addList({
        ui.layer({size = cc.size(850, 340)}),
        ui.image({img = RES_DICT.LINE_BG, ml = -40}),
        ui.title({n = RES_DICT.GENE_TITLE}):updateLabel({fnt = FONT.D4, color = "#65513d", text = __("携带基因")}),
        ui.gridView({size = cc.size(850, 140), cols = 3, csizeH = 80, dir = display.SDIR_V}),
    })
    ui.flowLayout(cc.rep(cc.sizep(catDetailBg, ui.lt), 80, -100), frameGroup, {type = ui.flowV, ap = ui.lb})

    local infoLayer = frameGroup[1]
    local infoGroup = infoLayer:addList({
        ui.layer({size = cc.size(285, 330)}),
        ui.layer({size = cc.size(500, 330)}),
    })
    ui.flowLayout(cc.sizep(infoLayer, ui.cc), infoGroup, {type = ui.flowH, ap = ui.cc, gapW = 30})

    -- catDetailLayer
    local catLayer = infoGroup[1]
    local catNodeGroup = catLayer:addList({
        ui.image({img = RES_DICT.CAT_BG, mt = -20}),
        ui.layer({size = catLayer:getContentSize()}),
        ui.tButton({n = RES_DICT.BOY_ICON, s = RES_DICT.GIRL_ICON, ml = 85, mt = 25}),
        ui.image({img = RES_DICT.CAT_FRAME}),
        ui.label({fnt = FONT.D14, outline = "#532922", text = "--", mt = 130}),
        ui.pBar({bg = RES_DICT.PROG_BG, img = RES_DICT.PROG_IMG, mt = 60, ml = 12}),
    })
    ui.flowLayout(cc.sizep(catLayer, ui.cc), catNodeGroup, {type = ui.flowC, ap = ui.cc})

    -- like level
    local progress = catNodeGroup[6]
    local lvlTitle = ui.title({n = RES_DICT.ICON_IMG}):updateLabel({fnt = FONT.D14, outline = "#a92626", text = "--", offset = cc.p(0, 5)})
    progress:addList(lvlTitle, 4):alignTo(nil, ui.lc, {offsetX = -45, offsetY = -3})

    -- like exp
    local proLabel = ui.label({fnt = FONT.D6, color = "#cdb78f", text = "--"})
    progress:addList(proLabel, 4):alignTo(nil, ui.cc)

    -- catInfoLayer
    local catInfoLayer = infoGroup[2]
    local catInfoGroup = catInfoLayer:addList({
        ui.label({fnt = FONT.D4, color = "#9a8261", text = __("主人名字")}),
        ui.title({n = RES_DICT.TITLE_BG}):updateLabel({fnt = FONT.D4, color = "#532922", text = "--", ap = ui.lc, offset = cc.p(-245, 0)}),
        ui.label({fnt = FONT.D4, color = "#9a8261", text = __("信息"), mt = 10}),
        ui.title({n = RES_DICT.TITLE_BG}):updateLabel({fnt = FONT.D4, color = "#532922", text = __("代数"), ap = ui.lc, offset = cc.p(-245, 0)}),
        ui.title({n = RES_DICT.TITLE_BG}):updateLabel({fnt = FONT.D4, color = "#532922", text = __("时期"), ap = ui.lc, offset = cc.p(-245, 0)}),
        ui.title({n = RES_DICT.TITLE_BG}):updateLabel({fnt = FONT.D4, color = "#532922", text = __("是否归回"), ap = ui.lc, offset = cc.p(-245, 0)}),
        ui.label({fnt = FONT.D4, color = "#9a8261", text = __("猫猫详情"), mt = 10}),
        ui.layer({size = cc.size(500, 100), bg = RES_DICT.FILTER_BG, scale9 = true, cut = cc.dir(10, 10, 10, 10)}),
       
    })
    ui.flowLayout(cc.sizep(catInfoLayer, ui.lc), catInfoGroup, {type = ui.flowV, ap = ui.lc, gapH = 1})

    -- descr
    local scrollLayer = catInfoGroup[8]
    local descrScrollView =  ui.scrollView({size = cc.resize(scrollLayer:getContentSize(), 0, -10), dir = display.SDIR_V})
    scrollLayer:addList(descrScrollView):alignTo(nil, ui.cc)

    local descrLabel = ui.label({fnt = FONT.D9, color = "#70645b", text = "--", w = descrScrollView:getContentSize().width - 20, ap = ui.lt, p = cc.p(10, 10)})
    descrScrollView:getContainer():add(descrLabel)

    --- info
    local algebraTitle = catInfoGroup[4]
    local algebraLabel = ui.label({fnt = FONT.D4, color = "#cfc6ba", text = "--", ap = ui.rc})
    algebraTitle:addList(algebraLabel):alignTo(nil, ui.rc, {offsetX = -5})

    local ageTitle = catInfoGroup[5]
    local ageLabel = ui.label({fnt = FONT.D4, color = "#cfc6ba", text = "--", ap = ui.rc})
    ageTitle:addList(ageLabel):alignTo(nil, ui.rc, {offsetX = -5})

    local rebirthNumTitle = catInfoGroup[6]
    local rebirthNumLabel = ui.label({fnt = FONT.D4, color = "#cfc6ba", text = "--", ap = ui.rc})
    rebirthNumTitle:addList(rebirthNumLabel):alignTo(nil, ui.rc, {offsetX = -5})

    -- genu list
    local geneGridView = frameGroup[4]
    geneGridView:setCellCreateClass(require('Game.views.catModule.cat.CatGeneNode'), {defaultCB = true})

    local sexIcon = catNodeGroup[3]
    sexIcon:setTouchEnabled(false)

    return {
        catDetailBg     = catDetailBg,
        scrollView      = frameGroup[4],
        sexIcon         = sexIcon,
        catNodeLayer    = catNodeGroup[2],
        catNameLabel    = catNodeGroup[5],
        algebraLabel    = algebraLabel,
        ageLabel        = ageLabel,
        rebirthNumLabel = rebirthNumLabel,
        descrLabel      = descrLabel,
        geneGridView    = geneGridView,
        progress        = progress,
        lvlTitle        = lvlTitle,
        proLabel        = proLabel,
        descrScrollView = descrScrollView,
        friendNameLabel = catInfoGroup[2],
    }
end

return CatModuleFriendDetailView
