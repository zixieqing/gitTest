--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 拼图游戏 视图
]]
local Anniversary20PuzzleView = class('Anniversary20PuzzleView', function()
    return ui.layer({name = 'Game.views.anniversary.Anniversary20PuzzleView', enableEvent = true})
end)

local RES_DICT = {
    --                      = top
    BACK_BTN                = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR           = _res('ui/common/common_title.png'),
    COM_TIPS_ICON           = _res('ui/common/common_btn_tips.png'),
    --                      = center
    BG_IMAGE                = _res('ui/anniversary20/puzzle/wonderland_puzzle_bg.jpg'),
    BTN_CONFIRM             = _res('ui/common/common_btn_orange.png'),
    PUZZLE_FRAME            = _res('ui/anniversary20/puzzle/wonderland_puzzle_pic_photo.png'),
    PUZZLE_LINE             = _res('ui/anniversary20/puzzle/wonderland_puzzle_pic_photo_line.png'),
    PUZZLE_IMG              = _res('ui/anniversary20/puzzle/wonderland_puzzle_pic_photo_img.jpg'),
    PUZZLE_CELL_SPINE       = _spn("ui/anniversary20/puzzle/effects/wonderland_puzzle_photo"),
    PUZZLE_COLLECT_SPINE    = _spn('ui/anniversary20/puzzle/effects/wonderland_puzzle_btn_sweet'),
    PUZZLE_BUFF_SPINE       = _spn('ui/anniversary20/puzzle/effects/wonderland_puzzle_btn_buff'),
    PUZZLE_CELL_LIGHT_SPINE = _spn('ui/anniversary20/puzzle/effects/wonderland_puzzle_photo_light'),
    PUZZLE_BG               = _spn('ui/anniversary20/puzzle/effects/wonderland_puzzle'),
    --                      = puzzleLoding
    PUZ_PROGRESS_IMG        = _res('ui/anniversary20/puzzle/wonderland_puzzle_sweet_line_bg_up.png'),
    PUZ_PROGRESS_BG_IMG     = _res('ui/anniversary20/puzzle/wonderland_puzzle_sweet_line_bg.png'),
    PUZ_PROGRESS_TXT_BG     = _res('ui/anniversary20/puzzle/wonderland_puzzle_bg_word.png'),
    --                      = donatelayer
    DETAIL_BG_IMG           = _res('ui/anniversary20/puzzle/wonderland_puzzle_sweet_bg.png'),
    ADD_IMG                 = _res('ui/anniversary20/puzzle/market_sold_btn_plus.png'),
    DEL_IMG                 = _res('ui/anniversary20/puzzle/market_sold_btn_sub.png'),
    TXT_BG                  = _res('ui/anniversary20/puzzle/wonderland_puzzle_sweet_word_bg.png'),
    CUR_NUM_BG              = _res('ui/anniversary20/puzzle/wonderland_puzzle_sweet_number.png'),
    LINE_IMG                = _res("ui/anniversary20/puzzle/wonderland_puzzle_sweet_line.png"),
    --                      = bufflayer
    BUFF_BG_IMG             = _res('ui/anniversary20/puzzle/wonderland_puzzle_buff_bg.png'),
    BUFF_SELF_BG_IMG        = _res('ui/anniversary20/puzzle/wonderland_puzzle_buff_bg_leve.png'),
    BUFF_ARROW              = _res('ui/anniversary20/puzzle/wonderland_puzzle_buff_pic_arrow.png'),
}

Anniversary20PuzzleView.DONATE_INPUT_MAX = 999


function Anniversary20PuzzleView:ctor(args)
    -- create view
    self.viewData_ = Anniversary20PuzzleView.CreateView()
    self:addChild(self.viewData_.view)
end


function Anniversary20PuzzleView:getViewData()
    return self.viewData_
end


function Anniversary20PuzzleView:getDonateViewData()
    return self.donateViewData_
end


function Anniversary20PuzzleView:getBuffViewData()
    return self.buffViewData_
end


function Anniversary20PuzzleView:showUI(endCB)
    local viewData = self:getViewData()
    viewData.topLayer:setPosition(viewData.topLayerHidePos)
    viewData.titleBtn:setPosition(viewData.titleBtnHidePos)
    viewData.titleBtn:runAction(cc.EaseBounceOut:create(cc.MoveTo:create(1, viewData.titleBtnShowPos)))
    
    local actTime = 0.2
    self:runAction(cc.Sequence:create({
        cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(actTime, viewData.topLayerShowPos)),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    }))
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function Anniversary20PuzzleView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- bgImg / block layer
    local backGroundGroup = view:addList({
        ui.image({img = RES_DICT.BG_IMAGE, p = cpos}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer, 2)

    -- back button
    local backBtn = ui.button({n = RES_DICT.BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 30, offsetY = -15})

    -- title button
    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('魔镜城堡'), offset = cc.p(0,-10)})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})

    titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -15, offsetY = -10})

    -- money bar
    local moneyBar = require('common.CommonMoneyBar').new({})
    moneyBar:reloadMoneyBar({ app.anniv2020Mgr:getPuzzleGoodsId() }, false, {
        [app.anniv2020Mgr:getPuzzleGoodsId()] = {hidePlus = true, disable = true},
    })
    topLayer:add(moneyBar)


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer, 1)

    local GRID_COLS   = 6
    local GRID_ROWS   = 4
    local GRID_SIZE   = cc.size(162, 150)
    local PUZZLE_SIZE = cc.size(GRID_SIZE.width * GRID_COLS, GRID_SIZE.height * GRID_ROWS)
    
    -- puzzle group [ img, cellsLayer, line, frame, selectLayer ]
    local puzzleGroup = centerLayer:addList({
        ui.image({img = RES_DICT.PUZZLE_IMG}),
        ui.layer({size = PUZZLE_SIZE, mr = 2, scaleX = 0.97, scaleY = 0.9}),
        ui.image({img = RES_DICT.PUZZLE_LINE, scaleX = 0.97, scaleY = 0.9}),
        ui.image({img = RES_DICT.PUZZLE_FRAME, mb = 90}),
        ui.layer({size = PUZZLE_SIZE, mr = 2, scaleX = 0.97, scaleY = 0.9})
    })
    ui.flowLayout(cc.rep(display.center, -100, -50), puzzleGroup, {type = ui.flowC, ap = ui.cc})

    -- puzzle cells
    local gridLayer   = puzzleGroup[2]
    local puzzleCells = {}
    for _, puzzleConf in pairs(CONF.ANNIV2020.PUZZLE_GAME:GetAll()) do
        local posConf    = string.split2(puzzleConf.location, ',')
        local puzzleId   = checkint(puzzleConf.id)
        local puzzleRow  = checkint(posConf[1])
        local puzzleCol  = checkint(posConf[2])
        local puzzleCell = Anniversary20PuzzleView.CreatePuzzleCell(GRID_SIZE)
        puzzleCell:setPosition((puzzleCol - 1) * GRID_SIZE.width, (GRID_ROWS - puzzleRow) * GRID_SIZE.height)
        puzzleCell:setTag(puzzleId)
        gridLayer:add(puzzleCell)
        puzzleCells[puzzleId] = puzzleCell
    end

    local puzzleBgEffect = ui.spine({path = RES_DICT.PUZZLE_BG, init = "idle"})
    centerLayer:addList(puzzleBgEffect):alignTo(nil, ui.cb, {offsetY = 500})

    ------------------------------------------------ puzzleInfoLayer
    local puzzleInfoLayer = puzzleGroup[5]
    
    -- puzzleDetailLayer
    local puzzleDetailLayer = ui.layer({size = GRID_SIZE})
    puzzleInfoLayer:addChild(puzzleDetailLayer)
    puzzleDetailLayer:setVisible(false)

    -- puzzleDetail [ statueLabel | progressLabel ]
    local puzzleDetailGroup = puzzleDetailLayer:addList({
        ui.label({fnt = FONT.D3, color = "#a49b81", fontSize = 24, mb = 20}),
        ui.image({img = RES_DICT.PUZ_PROGRESS_TXT_BG, mt = 20}),
        ui.label({fnt = FONT.D2, color = "#edd8a0", fontSize = 24, mt = 20}),
    })
    ui.flowLayout(cc.sizep(puzzleDetailLayer, ui.cc), puzzleDetailGroup, {type = ui.flowC, ap = ui.cc})

    -- puzzleProgressLayer
    local puzzleProgressLayer = ui.layer({size = GRID_SIZE})
    puzzleInfoLayer:addChild(puzzleProgressLayer)
    puzzleProgressLayer:setVisible(false)

    local puzzleProgressGroup = puzzleProgressLayer:addList({
        ui.rLabel({mb = 20, c = {}}),
        ui.pBar({mt = 20, img = RES_DICT.PUZ_PROGRESS_IMG, bg = RES_DICT.PUZ_PROGRESS_BG_IMG, value = 0}),
    })
    ui.flowLayout(cc.sizep(puzzleProgressLayer, ui.cc), puzzleProgressGroup, {type = ui.flowC, ap = ui.cc})

    -- puzzleLightLayer
    local puzzleCellLightLayer = puzzleInfoLayer:addList(ui.layer({size = GRID_SIZE}))
    puzzleCellLightLayer:add(ui.spine({path = RES_DICT.PUZZLE_CELL_LIGHT_SPINE, init = "idle", cache = SpineCacheName.ANNIVERSARY_2020, p = cc.sizep(GRID_SIZE, ui.cc)}))
    puzzleCellLightLayer:setVisible(false)

    ------------------------------------------------ puzzle collet
    local puzzleCollectNode = ui.layer({size = cc.size(200, 150), color = cc.r4b(0), ap = ui.rc, enable = true})
    centerLayer:addList(puzzleCollectNode):alignTo(nil, ui.rb, {offsetX = -display.SAFE_L - 25, offsetY = 60})

    local puzzleCollectGroup = puzzleCollectNode:addList({
        ui.spine({path = RES_DICT.PUZZLE_COLLECT_SPINE, cache = SpineCacheName.ANNIVERSARY_2020, init = 'idle', ml = 10}),
        ui.label({fnt = FONT.D20, fontSize = 24, outline = '#833131', text = __('收集'), mt = 20}),
    })
    ui.flowLayout(cc.sizep(puzzleCollectNode, ui.cc), puzzleCollectGroup, {type = ui.flowC, ap = ui.cc})
    
    ---------------------------------------------------- puzzle buff
    local puzzleBuffNode = ui.layer({size = cc.size(120, 150), color = cc.r4b(0), ap = ui.rc, enable = true})
    centerLayer:addList(puzzleBuffNode):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L - 10, offsetY = -100})

    local puzzleBuffGroup = puzzleBuffNode:addList({
        ui.spine({path = RES_DICT.PUZZLE_BUFF_SPINE, cache = SpineCacheName.ANNIVERSARY_2020, init = 'play1', ml = 5}),
        ui.label({fnt = FONT.D2, color = '#1b2225', fontSize = 24}),
    })
    ui.flowLayout(cc.sizep(puzzleBuffNode, ui.cc), puzzleBuffGroup, {type = ui.flowC, ap = ui.cc})


    return {
        view                 = view,
        --                   = top
        topLayer             = topLayer,
        topLayerHidePos      = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos      = cc.p(topLayer:getPosition()),
        titleBtn             = titleBtn,
        titleBtnHidePos      = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos      = cc.p(titleBtn:getPosition()),
        backBtn              = backBtn,
        --                   = center
        cellLayer            = puzzleGroup[2],
        puzzleLayer          = puzzleGroup[5],
        puzzleCells          = puzzleCells,
        GRID_SIZE            = GRID_SIZE,
        --                   = spine
        puzzleCollectNode    = puzzleCollectNode,
        puzzleBuffNode       = puzzleBuffNode,
        buffValueTxt         = puzzleBuffGroup[2],
        centerLayer          = centerLayer,
        --                   = puzzleCellInfoDetail
        puzzleDetailLayer    = puzzleDetailLayer,
        puzzleDetailTitle    = puzzleDetailGroup[1],
        puzzleDetailProgress = puzzleDetailGroup[3],
        --                   = puzzleCellInfoProgress
        puzzleProgressLayer  = puzzleProgressLayer,
        puzzleProgressBar    = puzzleProgressGroup[2],
        puzzleRichText       = puzzleProgressGroup[1],
        --                   = puzzleCellLightSpineLayer
        puzzleCellLightLayer = puzzleCellLightLayer,
    }
end


-------------------------------------------------------------------------------
-- puzzle cells
-------------------------------------------------------------------------------

function Anniversary20PuzzleView.CreatePuzzleCell(cellSize, spineInit, loop)
    spineInit = spineInit or "stop"
    loop = loop ~= false or false
    local cellNode = ui.layer({color = cc.r4b(0), size = cellSize, enable = true})

    local cellSpine = ui.spine({path = RES_DICT.PUZZLE_CELL_SPINE, init = spineInit, cache = SpineCacheName.ANNIVERSARY_2020, p = cc.p(cellSize.width/2 , cellSize.height/2), loop = loop})
    cellNode:addChild(cellSpine)
    cellNode.cellSpine = cellSpine

    return cellNode
end


function Anniversary20PuzzleView:updateProgressValue(currentProgress, totalProgress)
    local currentValue = checkint(currentProgress)
    local totalValue   = math.max(currentValue, checkint(totalProgress))
    local progress     = math.floor(currentValue / totalValue * 100)

    -- update unlockingCell progress
    self.viewData_.puzzleProgressBar:setValue(progress)
    self.viewData_.puzzleRichText:reload({
        {color = "#ffb142", fontSize = 24, text = currentValue},
        {color = "#ffffff", fontSize = 24, text = "/" .. totalValue}
    })

    -- update unlockingCell detail
    local progressText = progress >= 100 and __("已完成") or __("进行中")
    self.viewData_.puzzleDetailTitle:setString(progressText)
    self.viewData_.puzzleDetailProgress:setString(progress .. "%")
end


function Anniversary20PuzzleView:updateProgressNodePosition()
    local progressIndex = app.anniv2020Mgr:getPuzzlesUnlockNum() + 1
    local puzzleCell = self.viewData_.puzzleCells[progressIndex]
    if puzzleCell then
        self.viewData_.puzzleDetailLayer:alignTo(puzzleCell, ui.cc)
        self.viewData_.puzzleProgressLayer:alignTo(puzzleCell, ui.cc)
    end
    self:refreshPuzzleCellInfoStatue()
end


function Anniversary20PuzzleView:refreshPuzzleCellInfoStatue()
    local progressIndex = app.anniv2020Mgr:getPuzzlesUnlockNum() + 1
    local allUnlock = progressIndex > #self.viewData_.puzzleCells
    local isDonateVisible = self:getDonateViewData() and self:getDonateViewData().view:isVisible()
    self.viewData_.puzzleDetailLayer:setVisible(not isDonateVisible and not allUnlock)
    self.viewData_.puzzleProgressLayer:setVisible(isDonateVisible and not allUnlock)
end


function Anniversary20PuzzleView:refreshUnlockStorySpinePos(puzzleIndex)
    local cellNode = self.viewData_.puzzleCells[checkint(puzzleIndex)]
    if cellNode then
        self.viewData_.puzzleCellLightLayer:setVisible(true)
        self.viewData_.puzzleCellLightLayer:alignTo(cellNode, ui.cc)
    else
        self.viewData_.puzzleCellLightLayer:setVisible(false)
    end
end


function Anniversary20PuzzleView:addPuzzleUnlockingAnimation(cb)
    local spineNode = Anniversary20PuzzleView.CreatePuzzleCell(self.viewData_.GRID_SIZE, 'idle', false)
    spineNode.cellSpine:registerSpineEventHandler(function(event)
        spineNode:runAction(cc.RemoveSelf:create())
        if cb then cb() end
    end, sp.EventType.ANIMATION_COMPLETE)
    self.viewData_.puzzleLayer:addChild(spineNode, 5)
    spineNode:alignTo(nil, ui.cc)
end


function Anniversary20PuzzleView:removePuzzleCellCardSpine(puzzleCell)
    if puzzleCell.cellSpine then
        puzzleCell.cellSpine:removeFromParent()
        puzzleCell.cellSpine = nil
    end
end


-------------------------------------------------------------------------------
-- donate define
-------------------------------------------------------------------------------

function Anniversary20PuzzleView.CreateDonateLayer_(alignParent)
    local view = ui.layer()

    -- addClickLayer to clickClose
    local clickLayer = ui.layer({color = cc.c4b(0, 0, 0, 0), enable = true})
    view:addChild(clickLayer)

    local alignParentRightX = alignParent:getPositionX() + alignParent:getBoundingBox().width
    local bgSize = cc.size(math.min(display.width - alignParentRightX, 350), 680)
    local bgView = ui.layer({size = bgSize, ap = cc.p(1, 0), enable = true})
    view:addList(bgView):alignTo(alignParent, ui.rc, {offsetY = 20})
    bgView:addList(ui.image({img = RES_DICT.DETAIL_BG_IMG, enable = true})):alignTo(nil, ui.lc, {offsetX = -20})

    -- createGoodInfo------------------------------------------------
    -- 获取到商品的信息
    local goodConf = GoodsUtils.GetGoodsConfById(app.anniv2020Mgr:getPuzzleGoodsId())
    local goodNode = ui.goodsNode({goodsId = app.anniv2020Mgr:getPuzzleGoodsId(), defaultCB = true})
    bgView:addList(goodNode):alignTo(nil, ui.ct, {offsetY = -38})

    -- createGoodText
    local goodName = ui.label({fnt = FONT.D20, fontSize = 24, outline = "#2d1b1a", text = tostring(goodConf.name)})
    bgView:addList(goodName):alignTo(nil, ui.ct, {offsetY = -155})

    -- createGoodDesc
    local goodScrollView = ui.scrollView({size = cc.size(280, 85), dir = display.SDIR_V})
    bgView:addList(goodScrollView):alignTo(nil, ui.ct, {offsetY = -200})

    local goodDesc = ui.label({fnt = FONT.D5, color = "#6c4a31", text = tostring(goodConf.descr), w = 260})
    goodScrollView:setContainerSize(cc.resize(display.getLabelContentSize(goodDesc), 20, 0))
    goodScrollView:getContainer():addList(goodDesc):alignTo(nil, ui.ct)
    goodScrollView:setContentOffsetToTop()

    -- createLine----------------------------------------------------------
    bgView:addList(ui.image({img = RES_DICT.LINE_IMG})):alignTo(nil, ui.ct, {offsetY = -287})

    -- createText--------------------------------------------------------
    bgView:addChild(Anniversary20PuzzleView.CreateTipNode_(cc.p(20, 370), __('可获得奖励：')))
    bgView:addChild(Anniversary20PuzzleView.CreateTipNode_(cc.p(20, 250), __('放入数量：')))
    
    local tipsStr = string.fmt(__('单次上限：_num_'), {_num_=Anniversary20PuzzleView.DONATE_INPUT_MAX})
    local tipText = ui.label({fnt = FONT.D9, text = tipsStr, color = "#c7ad9e"})
    bgView:addList(tipText):alignTo(nil, ui.cb, {offsetY = 115})

    -- createGoodLayer---------------------------------------------------
    local rewardLayer = ui.layer({size = cc.size(260, 90)})
    bgView:addList(rewardLayer):alignTo(nil, ui.cb, {offsetY = 250})

    -- createButton------------------------------------------------------------
    -- createButtonAddNum
    local buttonAddNumGroup = bgView:addList({
        ui.button({n = RES_DICT.DEL_IMG, enable = true}), 
        ui.button({n = RES_DICT.CUR_NUM_BG, mb = 4, enable = true}):updateLabel({text = '0', fontSize = 22, color = "#833131"}),
        ui.button({n = RES_DICT.ADD_IMG, enable = true}), 
    }, 10)
    buttonAddNumGroup[2]:setLocalZOrder(9)
    ui.flowLayout(cc.rep(cc.sizep(bgView:getContentSize(), ui.cb), 0, 150), buttonAddNumGroup, {ap = ui.cb, gapW = -20})

    -- createButtonConfirm
    local btnInput = ui.button({n = RES_DICT.BTN_CONFIRM, scale9 = true}):updateLabel({fnt = FONT.D14, text = __('放入'), paddingW = 30})
    bgView:addList(btnInput):alignTo(nil, ui.cb, {offsetY = 40})

    return {
        view       = view,
        blockLayer = clickLayer,
        rewardView = rewardLayer,
        addBtn     = buttonAddNumGroup[3],
        delBtn     = buttonAddNumGroup[1],
        inputBtn   = buttonAddNumGroup[2],
        confirmBtn = btnInput,
    }
end


function Anniversary20PuzzleView:updateDonateLayerVisible(visible, initCallback)
    if not self:getDonateViewData() then
        self.donateViewData_ = Anniversary20PuzzleView.CreateDonateLayer_(self:getViewData().puzzleLayer)
        self:addChild(self:getDonateViewData().view)
        if initCallback then initCallback(self:getDonateViewData()) end
    end
    
    self:getDonateViewData().view:setVisible(visible)
    self:refreshPuzzleCellInfoStatue()
end


function Anniversary20PuzzleView:refreshDonateLayerGoodNum(toolNum)
    self:getDonateViewData().inputBtn:setText(toolNum)
    self:refreshDonateLayerRewardsNum_(toolNum)
end


function Anniversary20PuzzleView:refreshDonateLayerRewardsNum_(toolNum)
    -- 没有奖励就去创建
    if not self:getDonateViewData().mapRewardInfos then
        local mapRewardInfos = {}
        local rewardConfs = app.anniv2020Mgr:getPuzzleRewards()
        for key, rewardConf in pairs(rewardConfs) do
            local goodNode = ui.goodsNode({goodsId = rewardConf.goodsId, num = rewardConf.num * toolNum, showAmount = true, type = rewardConf.type, defaultCB = true})
            local scale = 0.7
            goodNode:setScale(scale)
            self:getDonateViewData().rewardView:addChild(goodNode)

            local size = goodNode:getContentSize()
            local curIndex = checkint(key)
            goodNode:setPosition(cc.p((size.width * scale + 10) * (curIndex - 0.5), size.height * scale * 0.5 + 10))

            table.insert(mapRewardInfos, {node = goodNode, num = rewardConf.num})
        end
        self:getDonateViewData().mapRewardInfos = mapRewardInfos
    else
        -- 刷新数量
        for _, rewardInfo in ipairs(self:getDonateViewData().mapRewardInfos) do
            rewardInfo.node:setGoodAmount(rewardInfo.num * toolNum)
        end
    end
end

-------------------------------------------------------------------------------
-- buff define
-------------------------------------------------------------------------------

function Anniversary20PuzzleView:updateBuffDetailLayerVisible(visible, initCallBack)
    if not self:getBuffViewData() then
        self.buffViewData_ = self:createBuffDetailLayer_()
        self:addChild(self.buffViewData_.view)
        if initCallBack then initCallBack(self:getBuffViewData()) end
    end

    self:getBuffViewData().view:setVisible(visible)
    if visible then
        self:refreshBuffDetailLayerState()
    end
end


function Anniversary20PuzzleView:createBuffDetailLayer_()
    local view = ui.layer()
    --- add click close Layer
    local clickLayer = ui.layer({color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(clickLayer)

    local bgView = ui.layer({size = cc.size(590, 280), color = cc.r4b(0), ap = ui.cc, enable = true})
    view:addList(bgView):alignTo(nil, ui.cc)

    local centerPos = cc.sizep(bgView:getContentSize(), ui.cc)
    local buffViewBg = bgView:addList(ui.image({img = RES_DICT.BUFF_BG_IMG, scale9 = true})):alignTo(nil, ui.cc)
    local buffViewSubBg = buffViewBg:addList(ui.image({img = RES_DICT.BUFF_SELF_BG_IMG, ap = ui.cb, scale9 = true})):alignTo(nil, ui.cb)

    local buffLayerNodes = bgView:addList({
        --------------- create text
        display.newRichLabel(centerPos.x, centerPos.y + 100, {}),
        display.newLabel(centerPos.x, centerPos.y + 50, {text = '', color = "#593721", fontSize = 24, w = 540, hAlign = cc.TEXT_ALIGNMENT_CENTER}),
        --------------- create button
        ui.button({n = RES_DICT.BUFF_ARROW, p = centerPos}),
        display.newLabel(centerPos.x, centerPos.y - 40, {text = __("当前BUFF效果"), color = "#593721", fontSize = 24}),
        display.newLabel(centerPos.x, centerPos.y - 90, {text = '', color = "#593721", fontSize = 24, w = 500, hAlign = cc.TEXT_ALIGNMENT_CENTER}), 
    })

    return {
        view           = view,
        buffClickView  = clickLayer,
        buffLayer      = bgView,
        buffViewBg     = buffViewBg,
        buffViewSubBg  = buffViewSubBg,
        arrowBtn       = buffLayerNodes[3],
        nextTitleTxt   = buffLayerNodes[1],
        nextBuffTxt    = buffLayerNodes[2],
        curBuffTxt     = buffLayerNodes[5],
        buffLayerNodes = buffLayerNodes,
    }
end

function Anniversary20PuzzleView:getPuzzleNextUnlockSkillConf()
    local puzzleUnlockSkillIdList = CONF.ANNIV2020.PUZZLE_SKILL_UNLOCK:GetIdListUp()
    local lastUnlockSkillConf     = CONF.ANNIV2020.PUZZLE_SKILL_UNLOCK:GetValue(puzzleUnlockSkillIdList[#puzzleUnlockSkillIdList])

    -- 查找下一级效果
    for _, unlockId in ipairs(puzzleUnlockSkillIdList) do
        local unlockConf = CONF.ANNIV2020.PUZZLE_SKILL_UNLOCK:GetValue(unlockId)
        if app.anniv2020Mgr:getPuzzlesUnlockNum() < checkint(unlockConf.unlockNeedNum) then
            return unlockConf
        end
    end

    -- 达到满级，下一级为满级
    return lastUnlockSkillConf
end


function Anniversary20PuzzleView:refreshBuffDetailLayerState()
    -- next skill title
    local nextSkillUnlockConf = self:getPuzzleNextUnlockSkillConf()
    display.reloadRichLabel(self:getBuffViewData().nextTitleTxt, {r = true, c = {
        {text = __("全服解锁区域："), color = "#593721", fontSize = 24},
        {text = app.anniv2020Mgr:getPuzzlesUnlockNum(), color = "#c81212", fontSize = 24},
        {text = " / " .. nextSkillUnlockConf.unlockNeedNum, color = "#593721", fontSize = 24}
    }})

    -- next skill desc
    local pluzzSkillConf = app.anniv2020Mgr:getPuzzleSkillConf(nextSkillUnlockConf.id)
    local nextSkillDesc  = app.cardMgr.GetSkillDescr(checkint(pluzzSkillConf.skillId))
    self:getBuffViewData().nextBuffTxt:setString(nextSkillDesc)
    
    -- cur skill desc
    local curSkillDesc = __("无")
    local pluzzSkillConf = app.anniv2020Mgr:getPuzzleSkillConf(app.anniv2020Mgr:getPuzzleSkillIndex())
    local curSkillId = checkint(pluzzSkillConf.skillId)
    if curSkillId ~= 0 then
        curSkillDesc = app.cardMgr.GetSkillDescr(checkint(curSkillId))
    end
    self:getBuffViewData().curBuffTxt:setString(curSkillDesc)

    -- resize bgImg / buffFrame / blockLayer
    local nextBuffTxtSizeH = display.getLabelContentSize(self:getBuffViewData().nextBuffTxt).height
    local curBuffTxtSizeH = display.getLabelContentSize(self:getBuffViewData().curBuffTxt).height
    self:getBuffViewData().buffViewSubBg:setContentSize(cc.size(self:getBuffViewData().buffViewSubBg:getContentSize().width, curBuffTxtSizeH + 100))
    self:getBuffViewData().buffViewBg:setContentSize(cc.size(self:getBuffViewData().buffViewBg:getContentSize().width, curBuffTxtSizeH + nextBuffTxtSizeH + 190))
    self:getBuffViewData().buffLayer:setContentSize(cc.size(self:getBuffViewData().buffLayer:getContentSize().width, curBuffTxtSizeH + nextBuffTxtSizeH + 190))
    
    -- re-flow
    self:getBuffViewData().buffViewBg:alignTo(nil, ui.cc)
    self:getBuffViewData().buffViewSubBg:alignTo(nil, ui.cb)
    ui.flowLayout(cc.rep(cc.sizep(self:getBuffViewData().buffViewBg, ui.cc), 0, 0), self:getBuffViewData().buffLayerNodes, {type = ui.flowV, ap = ui.cc, gapH = 10})
end


function Anniversary20PuzzleView:updateBuffButtonValue()
    local curUsedSkillIndex = app.anniv2020Mgr:getPuzzleSkillIndex()
    local skillValue = __("无")
    if curUsedSkillIndex > 0 then
        local puzzleSkillConf = CONF.ANNIV2020.PUZZLE_SKILL_UNLOCK:GetValue(curUsedSkillIndex)
        skillValue = tostring(puzzleSkillConf.descr)
    end
    self.viewData_.buffValueTxt:setString(skillValue)
end

-------------------------------------------------------------------------------
-- normal define
-------------------------------------------------------------------------------

function Anniversary20PuzzleView.CreateTipNode_(pos, text)
    local title = ui.title({p = pos, img = RES_DICT.TXT_BG, ap = ui.lt})
    title:updateLabel({ap = ui.lc, offset = cc.p(-80,0), fnt = FONT.D5, color = '#6c4a31', text = text})
    return title
end


function Anniversary20PuzzleView.CreateGoodNode_(info)
    local goodNode = require('common.GoodNode').new(info)
    display.commonUIParams(goodNode, {animate = false, cb = function (sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = info.goodsId, type = 1})
    end})
    return goodNode
end


return Anniversary20PuzzleView
