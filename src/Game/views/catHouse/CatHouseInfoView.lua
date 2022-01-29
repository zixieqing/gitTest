--[[
 * author : weihao
 * descpt : 猫屋 - 信息 界面
]]
---@class CatHouseInfoView
local CatHouseInfoView = class('CatHouseInfoView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseInfoView', enableEvent = true})
end)

local RES_DICT={
    RESTAURANT_INFO_BG_BASIC_1               = _res("ui/home/lobby/information/restaurant_info_bg_basic_1.png"),
    RESTAURANT_INFO_BG_BASIC_2               = _res("ui/home/lobby/information/restaurant_info_bg_basic_2.png"),
    CAT_ICO_LEVEL_UP                         = _res("ui/catHouse/catHouseInfo/cat_ico_level_up.png"),
    RESTAURANT_INFO_BG_ICCOME                = _res("ui/home/lobby/information/restaurant_info_bg_iccome.png"),
    COMMON_BTN_TIPS_2                        = _res("ui/common/common_btn_tips_2.png"),
    COMMON_TITLE_5                           = _res("ui/common/common_title_5.png"),
    COMMCON_BG_TEXT1                         = _res("ui/common/commcon_bg_text1.png"),
    COMMCON_BG_TEXT_1                        = _res("ui/common/commcon_bg_text_1.png"),
    SETUP_BTN_TAB_DEFAULT                    = _res("ui/home/infor/setup_btn_tab_default.png"),
    SETUP_BTN_TAB_SELECT                     = _res("ui/home/infor/setup_btn_tab_select.png"),
    COMMON_BG_13                             = _res("ui/common/common_bg_13.png"),
    COMMON_BG_TITLE_2                        = _res("ui/common/common_bg_title_2.png"),
    COMMON_BTN_ORANGE                        = _res("ui/home/activity/common_btn_orange.png")
}
local BUTTON_TAGS = {
    CAT_INFO  = 1001 ,
    CAT_LEVEL = 1002
}

function CatHouseInfoView:ctor(args)
    -- create view
    self.viewData_ = self:CreateView()
end


function CatHouseInfoView:getViewData()
    return self.viewData_
end
-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseInfoView:CreateView()
    local inforLayer = display.newLayer(display.cx, display.cy ,{ap = display.CENTER,size = display.size})
    self:addChild(inforLayer,0)
    local closeLayer = display.newLayer(display.cx, display.cy ,{ap = display.CENTER,size = display.size,color = cc.c4b(0,0,0,175),enable = true})
    inforLayer:addChild(closeLayer,0)
    local centerLayer = display.newLayer(display.cx + 0, display.cy  + 4 ,{ap = display.CENTER,size = cc.size(1082,641)})
    inforLayer:addChild(centerLayer,0)
    local swallowLayer = display.newLayer(541, 320.5 ,{ap = display.CENTER,size = cc.size(1082,641),color = cc.c4b(0,0,0,0),  enable = true})
    centerLayer:addChild(swallowLayer,0)
    local bgImage = display.newImageView( RES_DICT.COMMON_BG_13 ,541, 320.5,{ap = display.CENTER})
    centerLayer:addChild(bgImage,0)
    -- 猫屋信息标题
    local catTitleBtn = display.newButton(544, 615.5 , {n = RES_DICT.COMMON_BG_TITLE_2,ap = display.CENTER,scale9 = true,size = cc.size(256,36)})
    centerLayer:addChild(catTitleBtn,0)
    display.commonLabelParams(catTitleBtn ,{fontSize = 24,text = __('猫屋信息'),color = '#FFF1C5',paddingW  = 20,safeW = 216})
    local rightBottomBgImage = display.newImageView( RES_DICT.COMMCON_BG_TEXT1 ,653, 298.5,{ap = display.CENTER,scale9 = true,size = cc.size(755 , 547)})
    centerLayer:addChild(rightBottomBgImage,0)


    -- 猫屋信息按钮
    local catInfoBtn = display.newButton(162, 533.5 , {n = RES_DICT.SETUP_BTN_TAB_DEFAULT, d =RES_DICT.SETUP_BTN_TAB_SELECT , ap = display.CENTER,scale9 = true,size = cc.size(215,82)})
    centerLayer:addChild(catInfoBtn,0)
    catInfoBtn:setTag(BUTTON_TAGS.CAT_INFO)


    display.commonLabelParams(catInfoBtn ,{fontSize = 24,text = __('猫屋信息'),color = '#FFFFFF',paddingW  = 20,safeW = 175})
    local catLevelBtn = display.newButton(162, 444.5 , {n = RES_DICT.SETUP_BTN_TAB_DEFAULT, d =RES_DICT.SETUP_BTN_TAB_SELECT ,ap = display.CENTER,scale9 = true,size = cc.size(215,82)})
    centerLayer:addChild(catLevelBtn,0)
    catLevelBtn:setTag(BUTTON_TAGS.CAT_LEVEL)
    display.commonLabelParams(catLevelBtn ,{fontSize = 24,text = __('猫屋等级'),color = '#FFFFFF',paddingW  = 20,safeW = 175})
    catLevelBtn:setVisible(false)
    local buttons = {
        [tostring(BUTTON_TAGS.CAT_INFO)] = catInfoBtn ,
        [tostring(BUTTON_TAGS.CAT_LEVEL)] = catLevelBtn ,
    }
    local layers = {}
    return {
        inforLayer                = inforLayer,
        closeLayer                = closeLayer,
        centerLayer               = centerLayer,
        swallowLayer              = swallowLayer,
        layers                    = layers ,
        bgImage                   = bgImage,
        catTitleBtn               = catTitleBtn,
        rightBottomBgImage        = rightBottomBgImage,
        catInfoBtn                = catInfoBtn,
        buttons                   = buttons, 
        catLevelBtn               = catLevelBtn
    }
end

--[[
    等级信息显示
--]]
function CatHouseInfoView:CreateLevelLayout()
    local view = display.newLayer(655, 297.5 ,{ap = display.CENTER,size = cc.size(755,547)})
    local rightTopBgImage = display.newImageView( RES_DICT.COMMCON_BG_TEXT_1 ,375.5, -10,{ap = display.CENTER_BOTTOM,scale9 = true,size = cc.size(755 , 445.6)})
    view:addChild(rightTopBgImage,0)
    self.viewData_.centerLayer:addChild(view)
    -- local tipBtn = display.newImageView( RES_DICT.COMMON_BTN_TIPS_2 ,28.5, 521.5,{ap = display.CENTER})
    -- view:addChild(tipBtn,0)
    local upgradeBtn = display.newButton(372.5, 75.5 , {n = RES_DICT.COMMON_BTN_ORANGE,ap = display.CENTER,scale9 = true,size = cc.size(123,62)})
    view:addChild(upgradeBtn,0)
    display.commonLabelParams(upgradeBtn ,fontWithColor(14 , {fontSize = 24,text = __('升级'),color = '#FFFFFF',paddingW  = 20,safeW = 83}))
    display.commonUIParams(upgradeBtn , { cb = function ()
                       app:DispatchObservers("CAT_HOUSE_UPGRADE_LEVEL_EVENT"  , {})
    end})
    local upgradeLayout = display.newLayer(372, 353.675 ,{ap = display.CENTER,size = cc.size(744,160.4)})
    view:addChild(upgradeLayout,0)
    local rewardBtn = display.newButton(358, 146.2 , {n = RES_DICT.COMMON_TITLE_5,ap = display.CENTER,scale9 = true,size = cc.size(186,31)})
    upgradeLayout:addChild(rewardBtn,0)
    display.commonLabelParams(rewardBtn ,{fontSize = 20,text = __('升级奖励'),color = '#323232',paddingW  = 20,safeW = 146})
    local catLevelTextLabel = display.newLabel(153.5, 521.5 , fontWithColor(6,{text =  __('猫屋等级:'),ap = display.RIGHT_CENTER}))
    view:addChild(catLevelTextLabel,0)
    local catLevelLabel = display.newLabel(167.5, 521.5 , fontWithColor(10, { fontSize = 26 ,text = "",ap = display.LEFT_CENTER}))
    view:addChild(catLevelLabel,0)

    local comfortTextLabel = display.newLabel(167.5 , 476.5 , fontWithColor(10,{fontSize = 26 ,text ="" , ap = display.LEFT_CENTER}))
    view:addChild(comfortTextLabel,0)
    local comfortLabel = display.newLabel(130.5, 476.5 , fontWithColor(6, {text = __('舒适度:'),ap = display.RIGHT_CENTER}))
    view:addChild(comfortLabel,0)
    local scrollView = CGridView:create(cc.size(752.6, 280.9))
    scrollView:setSizeOfCell(cc.size(375 , 40 ))
    scrollView:setColumns(2)
    scrollView:setAutoRelocate(true)
    scrollView:setAnchorPoint(display.CENTER)
    scrollView:setPosition(378, 260)
    view:addChild(scrollView,0)
    local upgradeBtnPos = cc.p(upgradeBtn:getPosition())
    local needGoodLabel = display.newRichLabel(upgradeBtnPos.x -20, upgradeBtnPos.y - 45 , {c = {
        fontWithColor(10 , {text = ""})
    }})
    view:addChild(needGoodLabel)
    self.rightLevelData = {
        view                      = view,
        -- tipBtn                    = tipBtn,
        upgradeBtn                = upgradeBtn,
        upgradeLayout             = upgradeLayout,
        rewardBtn                 = rewardBtn,
        catLevelTextLabel         = catLevelTextLabel,
        catLevelLabel             = catLevelLabel,
        comfortTextLabel          = comfortTextLabel,
        comfortLabel              = comfortLabel,
        needGoodLabel             = needGoodLabel,
        scrollView                = scrollView
    }
    self.viewData_.layers[tostring(BUTTON_TAGS.CAT_LEVEL)] = self.rightLevelData.view
end
--[[
    创建猫屋信息提交
--]]
function CatHouseInfoView:CreateInfoLayout()
    local view = display.newLayer(655, 297.5 ,{ap = display.CENTER,size = cc.size(755,547)})
    self.viewData_.centerLayer:addChild(view)
    local rightTopBgImage = display.newImageView( RES_DICT.COMMCON_BG_TEXT_1 ,375.5, -1.5,{ap = display.CENTER_BOTTOM,scale9 = true,size = cc.size(755 , 490)})
    view:addChild(rightTopBgImage)

    local oneCellLayout = display.newLayer(187.5, 467.9 ,{ap = display.CENTER,size = cc.size(372,38.2)})
    view:addChild(oneCellLayout,0)
    local cellBgImage = display.newImageView( RES_DICT.RESTAURANT_INFO_BG_BASIC_1 ,186, 19.1,{  ap = display.CENTER,scale9 = true,size = cc.size(371 , 38.2)})
    oneCellLayout:addChild(cellBgImage,0)
    -- local oneTipImage = display.newImageView( RES_DICT.COMMON_BTN_TIPS_2 ,28, 19.1,{ap = display.CENTER})
    -- oneCellLayout:addChild(oneTipImage,0)
    local catLevelText = display.newLabel(50, 19.1 , {fontSize = 20,text = __('猫屋等级:'),color = '#323232',ap = display.LEFT_CENTER})
    oneCellLayout:addChild(catLevelText,0)
    local catNumText = display.newLabel(174, 19.1 , {fontSize = 22,text = "",color = '#B15354',ap = display.LEFT_CENTER})
    oneCellLayout:addChild(catNumText,0)

    local twoCellLayout = display.newLayer(565, 467.9 ,{ap = display.CENTER,size = cc.size(372,38.2)})
    view:addChild(twoCellLayout,0)
    local twoCellBgImage = display.newImageView( RES_DICT.RESTAURANT_INFO_BG_BASIC_1 ,186, 19.1,{ap = display.CENTER,scale9 = true,size = cc.size(371 , 38.2)})
    twoCellLayout:addChild(twoCellBgImage,0)
    local comforTableLabel = display.newLabel(50, 19.1 , {fontSize = 20,text = __('舒适度:'),color = '#323232',ap = display.LEFT_CENTER})
    twoCellLayout:addChild(comforTableLabel,0)
    local comforTableNum = display.newLabel(174, 19.1 , {fontSize = 22,text = '',color = '#B15354',ap = display.LEFT_CENTER})
    twoCellLayout:addChild(comforTableNum,0)

    local threeCellLayout = display.newLayer(187.5, 423.5 ,{ap = display.CENTER,size = cc.size(372,38.2)})
    view:addChild(threeCellLayout,0)
    local cellBgImage = display.newImageView( RES_DICT.RESTAURANT_INFO_BG_BASIC_1 ,186, 19.1,{ap = display.CENTER,scale9 = true,size = cc.size(371 , 38.2)})
    threeCellLayout:addChild(cellBgImage,0)
    local playerLabelText = display.newLabel(50, 19.1 , {fontSize = 20,text = __('玩家上限:'),color = '#323232',ap = display.LEFT_CENTER})
    threeCellLayout:addChild(playerLabelText,0)
    local playerNumText = display.newLabel(174, 19.1 , {fontSize = 22,text = '',color = '#B15354',ap = display.LEFT_CENTER})
    threeCellLayout:addChild(playerNumText,0)
    local fourCellLayout = display.newLayer(565, 423.5 ,{ap = display.CENTER,size = cc.size(372,38.2)})
    view:addChild(fourCellLayout,0)

    local fourCellBgImage = display.newImageView( RES_DICT.RESTAURANT_INFO_BG_BASIC_1 ,186, 19.1,{ap = display.CENTER,scale9 = true,size = cc.size(371 , 38.2)})
    fourCellLayout:addChild(fourCellBgImage,0)
    local catTextLabel = display.newLabel(50, 19.1 , {fontSize = 20,text = __('猫咪上限:'),color = '#323232',ap = display.LEFT_CENTER})
    fourCellLayout:addChild(catTextLabel,0)
    local catNumLabel = display.newLabel(174, 19.1 , {fontSize = 22,text = '',color = '#B15354',ap = display.LEFT_CENTER})
    fourCellLayout:addChild(catNumLabel,0)
    local comfortTitle = display.newButton(377.5, 380.5 , {n = RES_DICT.COMMON_TITLE_5,ap = display.CENTER,scale9 = true,size = cc.size(186,31)})
    view:addChild(comfortTitle,0)
    display.commonLabelParams(comfortTitle ,{fontSize = 24,text = __('舒适度'),color = '#5b3c25',paddingW  = 20,safeW = 146})

    local scrollView = CGridView:create(cc.size(752.6, 360))
    scrollView:setSizeOfCell(cc.size(375 , 40 ))
    scrollView:setColumns(2)
    scrollView:setAutoRelocate(true)
    scrollView:setAnchorPoint(display.CENTER_TOP)
    scrollView:setPosition(378 , 363)
    view:addChild(scrollView,0)

    local avatarTipLayer = ui.layer({size = scrollView:getContentSize(), ap = ui.ct, p = cc.p(378, 363)})
    view:addChild(avatarTipLayer)
    local avatarTipGroup = avatarTipLayer:addList({
        ui.label({fnt = FONT.D7, color = "#e0491a", text = __("暂无家具，请前往商店购买"), reqW = 400}),
        AssetsUtils.GetCartoonNode(3, 0, 0, {scale = 0.6}),
    })
    ui.flowLayout(cc.sizep(avatarTipLayer, ui.cc), avatarTipGroup, {type = ui.flowH, ap = ui.cc, gapW = 10})
    
    self.rightInfoViewData = {
        view                      = view,
        oneCellLayout             = oneCellLayout,
        cellBgImage               = cellBgImage,
        -- oneTipImage               = oneTipImage,
        catLevelText              = catLevelText,
        catNumText                = catNumText,
        twoCellLayout             = twoCellLayout,
        twoCellBgImage            = twoCellBgImage,
        comforTableLabel          = comforTableLabel,
        comforTableNum            = comforTableNum,
        threeCellLayout           = threeCellLayout,
        playerLabelText           = playerLabelText,
        playerNumText             = playerNumText,
        fourCellLayout            = fourCellLayout,
        fourCellBgImage           = fourCellBgImage,
        catTextLabel              = catTextLabel,
        catNumLabel               = catNumLabel,
        scrollView                = scrollView,
        comfortTitle              = comfortTitle,
        avatarTipLayer            = avatarTipLayer,
    }
    self.viewData_.layers[tostring(BUTTON_TAGS.CAT_INFO)] = self.rightInfoViewData.view
end

--[[
    提升等级所用的cell
--]]
function CatHouseInfoView:CreateUpgradeLevelCell()
    local cell =  CGridViewCell:new()
    local cellSize = cc.size(372,38.2)
    cell:setContentSize(cellSize)
    local cellLayout = display.newLayer(cellSize.width/2 , cellSize.height/2,{ap = display.CENTER,size = cc.size(372,38.2)})
    cell:addChild(cellLayout)
    local fourCellBgImage = display.newImageView( RES_DICT.RESTAURANT_INFO_BG_BASIC_1 ,186, 19.1,{ap = display.CENTER,scale9 = true,size = cc.size(371 , 38.2)})
    cellLayout:addChild(fourCellBgImage,0)
    local nameLabel = display.newLabel(30, 19.1 , {fontSize = 20,text = '',color = '#323232',ap = display.LEFT_CENTER})
    cellLayout:addChild(nameLabel,0)
    local upGradeImage = display.newImageView( RES_DICT.CAT_ICO_LEVEL_UP ,222, 19.1,{ap = display.CENTER})
    cellLayout:addChild(upGradeImage,0)
    upGradeImage:setVisible(false)
    local nowNum = display.newLabel(169, 19.1 , {fontSize = 22,text = "",color = '#5b3c25',ap = display.LEFT_CENTER})
    cellLayout:addChild(nowNum,0)
    local addNum = display.newLabel(255, 19.1 , {fontSize = 22,text = "",color = '#5b3c25',ap = display.LEFT_CENTER})
    cellLayout:addChild(addNum,0)
    addNum:setVisible(false)
    cell.viewData = {
        cellLayout                = cellLayout,
        fourCellBgImage           = fourCellBgImage,
        nameLabel                 = nameLabel,
        upGradeImage              = upGradeImage,
        nowNum                    = nowNum,
        addNum                    = addNum
    }
    return cell
end

--[[
舒适度加成cell
--]]
function CatHouseInfoView:CreateComfortCell()
    local cell =  CGridViewCell:new()
    local cellSize = cc.size(372,38.2)
    cell:setContentSize(cellSize)
    local cellLayout = display.newLayer(cellSize.width/2 , cellSize.height / 2 ,{ap = display.CENTER,size = cc.size(372,38.2)})
    cell:addChild(cellLayout)
    local cellBgImage = display.newImageView( RES_DICT.RESTAURANT_INFO_BG_BASIC_1 ,186, 19.1,{ap = display.CENTER})
    cellLayout:addChild(cellBgImage,0)
    local addName = display.newLabel(39, 19.1 , {fontSize = 20,text = '' , color = '#5b3c25',ap = display.LEFT_CENTER})
    cellLayout:addChild(addName,0)
    local addNum = display.newLabel(288, 19.1 , {fontSize = 22,text = '' , color = '#5b3c25',ap = display.LEFT_CENTER})
    cellLayout:addChild(addNum,0)
    cell.viewData = {
        cellLayout                = cellLayout,
        cellBgImage               = cellBgImage,
        addName                   = addName,
        addNum                    = addNum
    }
    return cell
end
--[[
    更新等级显示
--]]
function CatHouseInfoView:UpdateLevelLayout(houseDatas)
    if not self.rightLevelData then
        self:CreateLevelLayout()
    end
    local catHouseMgr = app.catHouseMgr
    local houseLevel = catHouseMgr:getHouseLevelByFriendId(houseDatas.friendId)
    local houseData = houseDatas.houseData
    local location = houseData.location or {}
    local catTriggerEvent = houseData.catTriggerEvent or {}
    local rightLevelData = self.rightLevelData
    local nextHouseLevel = houseLevel + 1
    local avatarConf = CONF.CAT_HOUSE.LEVEL_INFO:GetAll()
    local nextConf = avatarConf[tostring(nextHouseLevel)]
    local currentConf = avatarConf[tostring(houseLevel)] or {}
    --- 舒适度总值
    local comfortCount = 0
    for i, v in pairs(location) do
        comfortCount = comfortCount + CatHouseUtils.GetComfortValueByGoodsId(v.goodsId)
    end
    for _, eventData in ipairs(catTriggerEvent) do
        local eventId   = checkint(eventData.eventId)
        local eventConf = CONF.CAT_HOUSE.CAT_TRIGGER_EVENT:GetValue(eventId)
        local discount  = checkint(eventConf.eventParameter)
        comfortCount = comfortCount * ((100 - discount) / 100)
        break
    end
    local isMaxLevel = not nextConf or next(nextConf) == nil
    if isMaxLevel then
        rightLevelData.upgradeBtn:setVisible(false)
        nextHouseLevel = nextHouseLevel
        nextConf = avatarConf[tostring(nextHouseLevel)] or {}
        rightLevelData.needGoodLabel:setVisible(false)
    else
        rightLevelData.upgradeBtn:setVisible(true)
        rightLevelData.needGoodLabel:setVisible(true)
    end

    display.commonLabelParams(rightLevelData.catLevelLabel , {
        text = string.fmt(__('_level_级') ,  { _level_ = houseLevel })
    })
    display.commonLabelParams(rightLevelData.comfortTextLabel , {
        text = table.concat({comfortCount , isMaxLevel and checkint(currentConf.comfort) or checkint(nextConf.comfort)} , "/")
    })
    local consume = checktable(nextConf.consume)[1] or {}
    local numLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt','')
    numLabel:setHorizontalAlignment(display.TAL)
    numLabel:setString(tostring(consume.num))
    local numLabelSize = display.getLabelContentSize(numLabel)
    numLabel:setPosition(0, numLabelSize.height/2)
    numLabel:setAnchorPoint(display.LEFT_CENTER)
    local node = display.newLayer(0,0,{size = numLabelSize , ap = display.LEFT_BOTTOM })
    node:addChild(numLabel)

    display.reloadRichLabel(rightLevelData.needGoodLabel , {
        c = {
            { node =  node , ap = display.LEFT_BOTTOM} ,
            { img = CommonUtils.GetGoodsIconPathById(consume.goodsId) , ap = cc.p(-1.2,0.2) , scale = 0.25}
        }
    })
    local upgradeDatas = {
        {
            key = "avatarLimit" ,
            text  = __('放置数量:') ,
            currentNum = checkint(currentConf.avatarLimit) ,
            addValue = checkint(nextConf.avatarLimit) - checkint(currentConf.avatarLimit)
        },
        {
            key = "catLimit" ,
            text  = __('猫咪在屋数量:') ,
            currentNum = checkint(currentConf.catLimit) ,
            addValue = checkint(nextConf.catLimit) - checkint(currentConf.catLimit)
        },
        {
            key = "guestLimit" ,
            text  = __('玩家在屋数量:') ,
            currentNum = checkint(currentConf.guestLimit) ,
            addValue = checkint(nextConf.guestLimit) - checkint(currentConf.guestLimit)
        }
    }
    local scrollView = rightLevelData.scrollView
    scrollView:setDataSourceAdapterScriptHandler(function(p_convertview,idx)
        local index = idx + 1
        local cell = p_convertview
        local upgradeData = upgradeDatas[index]
        local text = upgradeData.text
        local currentNum = upgradeData.currentNum
        local addValue = upgradeData.addValue
        xTry(function()
            if not cell then
                cell = self:CreateUpgradeLevelCell()
            end
            local viewData = cell.viewData
            display.commonLabelParams(viewData.nameLabel , {text =text})
            display.commonLabelParams(viewData.nowNum , {text = currentNum})
            if checkint(addValue) > 0 then
                viewData.addNum:setVisible(true)
                viewData.upGradeImage:setVisible(true)
                display.commonLabelParams(viewData.addNum , {text = addValue})
            else
                viewData.addNum:setVisible(false)
                viewData.upGradeImage:setVisible(false)
            end
        end,__G__TRACKBACK__)
        return cell
    end)
    scrollView:setCountOfCell(#upgradeDatas)
    scrollView:reloadData()
end

function CatHouseInfoView:UpdateView(tag , houseData)
    local buttons = self.viewData_.buttons
    for i, v in pairs(buttons) do
        local text = v:getLabel():getString()
        if checkint(i) == tag then
            v:setEnabled(false)
            display.commonLabelParams(v , {text = text , color = "#5b3c25"})
        else
            display.commonLabelParams(v , {text = text , color = "#ffffff"})
            v:setEnabled(true)
        end
    end

    for i, v in pairs(buttons) do
        if checkint(i) == tag then
            if tag == BUTTON_TAGS.CAT_INFO then
                self:UpdateInfoLayout(houseData)
            elseif tag == BUTTON_TAGS.CAT_LEVEL then
                self:UpdateLevelLayout(houseData)
            end
            self.viewData_.layers[tostring(i)]:setVisible(true)
        else
            if self.viewData_.layers[tostring(i)] then
                self.viewData_.layers[tostring(i)]:setVisible(false)
            end
        end
    end

end
--[[
   更新信息界面
--]]
function CatHouseInfoView:UpdateInfoLayout(houseDatas)
    if not self.rightInfoViewData then
        self:CreateInfoLayout()
    end
    local catHouseMgr = app.catHouseMgr
    local houseLevel = catHouseMgr:getHouseLevelByFriendId(houseDatas.friendId)
    local rightInfoViewData = self.rightInfoViewData
    local houseData = houseDatas.houseData
    local location = houseData.location or {}
    local catTriggerEvent = houseData.catTriggerEvent or {}
    local levelConf = CONF.CAT_HOUSE.LEVEL_INFO:GetValue(houseLevel)
    local catLimit = levelConf.catLimit
    local guestLimit = levelConf.guestLimit
    display.commonLabelParams(rightInfoViewData.catNumText , {text = string.fmt(__('_level_级') ,  { _level_ = houseLevel})})
    --- 舒适度总值
    local comfortCount = 0
    local avatarList = {}
    for i, v in pairs(location) do
        local goodsId = v.goodsId
        avatarList[#avatarList+1] = v
        comfortCount = comfortCount + CatHouseUtils.GetComfortValueByGoodsId(goodsId)
    end
    for _, eventData in ipairs(catTriggerEvent) do
        local eventId   = checkint(eventData.eventId)
        local eventConf = CONF.CAT_HOUSE.CAT_TRIGGER_EVENT:GetValue(eventId)
        local discount  = checkint(eventConf.eventParameter)
        comfortCount = string.fmt('%1 (-%2%)', comfortCount, discount)
        break
    end
    display.commonLabelParams(rightInfoViewData.comforTableNum , {text = comfortCount})
    display.commonLabelParams(rightInfoViewData.playerNumText , {text = guestLimit})
    display.commonLabelParams(rightInfoViewData.catNumLabel , {text = catLimit})
    rightInfoViewData.avatarTipLayer:setVisible(#avatarList <= 0)
    local scrollView = rightInfoViewData.scrollView
    scrollView:setCountOfCell(#avatarList)
    scrollView:setDragable(#avatarList > 18)
    scrollView:setDataSourceAdapterScriptHandler(function(p_convertview,idx)
        local index = idx + 1
        local cell = p_convertview
        xTry(function()
            if not cell then
                cell = self:CreateComfortCell()
            end
            local viewData = cell.viewData
            local mod =  math.fmod(index , 4)
            local cellBgImage = viewData.cellBgImage
            if mod == 1 or mod == 2 then
                cellBgImage:setTexture(RES_DICT.RESTAURANT_INFO_BG_BASIC_1)
            else
                cellBgImage:setTexture(RES_DICT.RESTAURANT_INFO_BG_BASIC_2)
            end
            local avatarConf = CONF.CAT_HOUSE.AVATAR_INFO:GetValue(avatarList[index].goodsId)
            display.commonLabelParams(viewData.addName , {text = avatarConf.name})
            display.commonLabelParams(viewData.addNum , {text = avatarConf.comfort})
        end,__G__TRACKBACK__)
        return cell
    end)
    scrollView:reloadData()
end
return CatHouseInfoView
