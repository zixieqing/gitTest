--[[
包厢功能 贵宾信息详情 view
--]]
local VIEW_SIZE = display.size
local PrivateRoomGuestInfoDescView = class('PrivateRoomGuestInfoDescView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.privateRoom.PrivateRoomGuestInfoDescView'
	node:enableNodeEvents()
	return node
end)


local CreateView     = nil
local CreateRoleInfo = nil
local CreatGuestPlot = nil
local CreateCell_    = nil

local RES_DIR = {
    ARROW            = _res('ui/home/recharge/recharge_btn_arrow.png'),
    CARD_BG_NAME     = _res('ui/home/handbook/pokedex_card_bg_name.png'),
    ENTERTAIN_BG     = _res('ui/privateRoom/guestInfo/viphandbook_rumber.png'),
    BG_KERENXINXI    = _res('ui/privateRoom/guestInfo/viphandbook_bg_kerenxinxi.png'),
    JVQING_BG_UNLOCK = _res('ui/privateRoom/guestInfo/viphandbook_jvqing_bg_unlock.png'),
    JVQING_BG        = _res('ui/privateRoom/guestInfo/viphandbook_jvqing_bg.png'),
    JVQING_PROGRESS  = _res('ui/privateRoom/guestInfo/viphandbool_jvqing_jindu.png'),
    PROGRESS_BG_1    = _res('ui/privateRoom/guestInfo/vip_handbook_line_1.png'),
    PROGRESS_BG_2    = _res('ui/privateRoom/guestInfo/viphandbook_bar_1.png'),
    STAR_WHITE_BLANK = _res('ui/common/kapai_star_white_blank.png'),
    STAR_L_ICO       = _res('ui/common/common_star_l_ico.png'),
    PLOT_LIST_BG     = _res('ui/common/common_bg_goods.png'),
    LOCK_IMG         = _res('ui/common/common_ico_lock.png'),
    RED_IMG          = _res('ui/common/common_ico_red_point.png'),

}

function PrivateRoomGuestInfoDescView:ctor( ... ) 
    
    self.args = unpack({...})
    self:initialUI()
end

function PrivateRoomGuestInfoDescView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

--==============================--
--desc: 更新UI
--@params data table 数据
--==============================--
function PrivateRoomGuestInfoDescView:refreshUI(data)
    local viewData = self:getViewData()
    self:updateRoleInfo(data)
    self:updateGuestPlot(data)
end

--==============================--
--desc: 更新任务信息
--@params data table 数据
--==============================--
function PrivateRoomGuestInfoDescView:updateRoleInfo(data)
    local viewData              = self:getViewData()
    local roleInfoLayer         = viewData.roleInfoLayer
    local roleInfoLayerViewData = roleInfoLayer.viewData

    local spineLayer     = roleInfoLayerViewData.spineLayer
    local guestConf       = data.guestConf or {}
    self:updateSpine(spineLayer, guestConf.id)

    local nameLabelBg = roleInfoLayerViewData.nameLabelBg

    display.commonLabelParams(nameLabelBg, {text = tostring(guestConf.name)})

    local guestsData  = data.guestsData or {}
    local serveTimes  = checkint(guestsData.serveTimes)
    local entertainBg = roleInfoLayerViewData.entertainBg
    display.commonLabelParams(entertainBg, {text = string.format(__('招待次数: %s'), serveTimes)})
end

--==============================--
--desc: 更新贵宾剧情
--@params data table 数据
--==============================--
function PrivateRoomGuestInfoDescView:updateGuestPlot(data)
    local viewData              = self:getViewData()
    local guestPlotLayer         = viewData.guestPlotLayer
    local guestPlotLayerViewData = guestPlotLayer.viewData

    local guestsData  = data.guestsData or {}
    local stars       = guestPlotLayerViewData.stars
    local grade = checkint(guestsData.grade or 1)
    for i, star in ipairs(stars) do
        star:setTexture((i <= (grade - 1)) and RES_DIR.STAR_L_ICO or RES_DIR.STAR_WHITE_BLANK)
    end

    local upgradeStarTip = guestPlotLayerViewData.upgradeStarTip
    local starConf = app.privateRoomMgr:GetGuestGradeConf(grade + 1)
    local isShowUpgradeStarTip = next(starConf) ~= nil
    if isShowUpgradeStarTip then
        local serveTimes = checkint(guestsData.serveTimes)
        display.commonLabelParams(upgradeStarTip, {text = string.format(__('升至下一星需再招待次数: %s'), checkint(starConf.serveTimes) - serveTimes)})
    end
    upgradeStarTip:setVisible(isShowUpgradeStarTip)

    local progressBar    = guestPlotLayerViewData.progressBar
    local storyCount      = checkint(data.storyCount)
    local dialogues = guestsData.dialogues or {}
    local value = table.nums(dialogues)
    progressBar:setMaxValue(storyCount)
    progressBar:setValue(value)
    display.commonLabelParams(progressBar:getLabel(), {text = string.format(__('剧情进度 %s/%s'), value, storyCount)})

    local guestConf     = data.guestConf or {}
    local icon          = guestPlotLayerViewData.icon
    icon:setTexture(CommonUtils.GetGoodsIconPathById(guestConf.giftId or 340001))
    local isSatisfyProgress = value >= storyCount
    if isSatisfyProgress then
        icon:clearFilter()
    else
        icon:setFilter(GrayFilter:create())
    end
    
    local iconTouchView = guestPlotLayerViewData.iconTouchView
    local isDrawn = checkint(guestsData.hasDrawn) > 0

    local storyDatas  = data.storyDatas or {}
    local count      = #storyDatas
    local gridView   = guestPlotLayerViewData.gridView
    gridView:setCountOfCell(count)
	gridView:reloadData()
end

--==============================--
--desc: 更新spine
--@params parent userdata 父控件
--@params spineId int     spine id
--==============================--
function PrivateRoomGuestInfoDescView:updateSpine(parent, spineId)
    if parent:getChildrenCount() then
        parent:removeAllChildren()
    end
    local spineLayrSize = parent:getContentSize()
    local pathPrefix = string.format("avatar/visitors/%s", spineId)
    local spine = sp.SkeletonAnimation:create(string.format("%s.json", pathPrefix),string.format('%s.atlas', pathPrefix), 1)
    spine:setToSetupPose()
    spine:setPosition(cc.p(spineLayrSize.width / 2 + 5,  5))
    spine:setAnimation(0, 'run', true)
    parent:addChild(spine)
end


--==============================--
--desc: 更新spine
--@params viewData table 控件数据
--@params storyData table 剧情数据
--@params curGuestGrade int 当前贵宾星级
--==============================--
function PrivateRoomGuestInfoDescView:updateCell(viewData, storyData, curGuestGrade)
    local lock          = viewData.lock
    local unlockBg      = viewData.unlockBg
    -- local redPointImg   = viewData.redPointImg
    local plotNameLabel = viewData.plotNameLabel
    
    local dialogueConf = storyData.dialogueConf or {}
    local dialogue = storyData.dialogue

    local guestGrade = checkint(dialogueConf.guestGrade)

    local isSatisfyGrade = curGuestGrade >= guestGrade
    if not isSatisfyGrade then
        unlockBg:setVisible(true)
        display.commonLabelParams(plotNameLabel, {text = '???'})
    else
        if dialogue then
            unlockBg:setVisible(false)
            display.commonLabelParams(plotNameLabel, {text = tostring(dialogueConf.name)})
        else
            unlockBg:setVisible(true)
            display.commonLabelParams(plotNameLabel, {text = '???'})
        end
    end
    lock:setVisible(not isSatisfyGrade)

end

--==============================--
--desc: 更新切换按钮显示状态
--@params isShowLeft bool 是否显示左侧切换按钮
--@params isShowRight bool 是否显示右侧切换按钮
--==============================--
function PrivateRoomGuestInfoDescView:updateSwiBtnShowState(isShowLeft, isShowRight)
    local viewData              = self:getViewData()
    local roleInfoLayer         = viewData.roleInfoLayer
    local roleInfoLayerViewData = roleInfoLayer.viewData
    local leftSwitchBtn         = roleInfoLayerViewData.leftSwitchBtn
    local rightSwitchBtn        = roleInfoLayerViewData.rightSwitchBtn
    
    leftSwitchBtn:setVisible(isShowLeft)
    rightSwitchBtn:setVisible(isShowRight)
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local roleInfoLayer = CreateRoleInfo()
    display.commonUIParams(roleInfoLayer, {po = cc.p(size.width / 2 - 40, 0), ap = display.RIGHT_BOTTOM})
    view:addChild(roleInfoLayer)

    local guestPlotLayer = CreatGuestPlot()
    display.commonUIParams(guestPlotLayer, {po = cc.p(size.width / 2 + 70, 0)})
    view:addChild(guestPlotLayer)

    return {
        view           = view,
        roleInfoLayer  = roleInfoLayer,
        guestPlotLayer = guestPlotLayer,
    }
end

CreateRoleInfo = function ()
    local roleInfoLayerSize = cc.size(600, display.height)
    local roleInfoLayer = display.newLayer(0, 0, {size = roleInfoLayerSize})

    -- switch btn
    local leftSwitchBtn = display.newButton(30, roleInfoLayerSize.height / 2 - 80, {n = RES_DIR.ARROW})
    leftSwitchBtn:setScaleX(-1)
    roleInfoLayer:addChild(leftSwitchBtn)

    local rightSwitchBtn = display.newButton(570, leftSwitchBtn:getPositionY(), {n = RES_DIR.ARROW})
    roleInfoLayer:addChild(rightSwitchBtn)

    local spineLayer = display.newLayer(roleInfoLayerSize.width / 2, roleInfoLayerSize.height / 2 - 150, { ap = display.CENTER_BOTTOM, size = cc.size(256, 400)})
    roleInfoLayer:addChild(spineLayer)

    -- name label
    local nameLabelBg = display.newButton(roleInfoLayerSize.width / 2, leftSwitchBtn:getPositionY() - 180, {scale9 = true, n = RES_DIR.CARD_BG_NAME, enable = false, ap = display.CENTER_BOTTOM})
    roleInfoLayer:addChild(nameLabelBg)
    display.commonLabelParams(nameLabelBg, {fontSize = 26, color = '#671919'})

    -- entertain times
    local entertainBg = display.newButton(nameLabelBg:getPositionX(), leftSwitchBtn:getPositionY() - 220, {scale9 = true, n = RES_DIR.ENTERTAIN_BG, enable = false, ap = display.CENTER_BOTTOM})
    roleInfoLayer:addChild(entertainBg)
    display.commonLabelParams(entertainBg, fontWithColor(18))

    roleInfoLayer.viewData = {
        leftSwitchBtn   = leftSwitchBtn,
        rightSwitchBtn  = rightSwitchBtn,
        spineLayer      = spineLayer,
        nameLabelBg     = nameLabelBg,
        entertainBg     = entertainBg,
    }
    return roleInfoLayer
end

CreatGuestPlot = function ()
    local guestPlotLayerSize = cc.size(600, display.height)
    local guestPlotLayer =  display.newLayer(0,0, {size = guestPlotLayerSize})

    local bgSize = cc.size(542, 595)
    local bgLayer = display.newLayer(0, guestPlotLayerSize.height / 2 - 35, {size = bgSize, ap = display.LEFT_CENTER})
    guestPlotLayer:addChild(bgLayer)
    bgLayer:addChild(display.newImageView(RES_DIR.BG_KERENXINXI, bgSize.width / 2, bgSize.height / 2, {ap = display.CENTER}))

    local guestStarTip = display.newLabel(50, bgSize.height - 50, fontWithColor(2, {text = __('客人星级'), ap = display.LEFT_CENTER, fontSize = 24, color = '#9f663c'}))
    bgLayer:addChild(guestStarTip)

    local stratX = guestStarTip:getPositionX() + display.getLabelContentSize(guestStarTip).width + 20
    local stars = {}
    for i = 1, 5 do
        local star = display.newImageView(RES_DIR.STAR_WHITE_BLANK, stratX + 48 * (i - 1), bgSize.height - 50, {ap = display.LEFT_CENTER})
        bgLayer:addChild(star)
        table.insert(stars, star)
    end

    local upgradeStarTip = display.newLabel(50, bgSize.height - 80, fontWithColor(5, {w = bgSize.width - 100, ap = display.LEFT_TOP, color = '#a18c7c'}))
    bgLayer:addChild(upgradeStarTip)

    local plotProgressBgSize = cc.size(520, 55)
    local plotProgressBgLayer = display.newLayer(bgSize.width / 2, bgSize.height - 190, {ap = display.CENTER_BOTTOM, size = plotProgressBgSize})
    bgLayer:addChild(plotProgressBgLayer, 1)
    plotProgressBgLayer:addChild(display.newImageView(RES_DIR.JVQING_PROGRESS, plotProgressBgSize.width / 2, plotProgressBgSize.height  / 2, {ap = display.CENTER}))
    
    local progressBarBg = display.newImageView(RES_DIR.PROGRESS_BG_1, plotProgressBgSize.width / 2, plotProgressBgSize.height / 2, {size = cc.size(491, 28), scale9 = true, ap = display.CENTER})
    plotProgressBgLayer:addChild(progressBarBg)
    local progressBar = CProgressBar:create(RES_DIR.PROGRESS_BG_2)
    display.commonUIParams(progressBar, {ap = display.CENTER, po = cc.p(plotProgressBgSize.width / 2, plotProgressBgSize.height / 2)})
    progressBar:setDirection(eProgressBarDirectionLeftToRight)
    progressBar:setValue(100)
    progressBar:setShowValueLabel(true)
    plotProgressBgLayer:addChild(progressBar)
    display.commonLabelParams(progressBar:getLabel(), fontWithColor(18))

    -- icon touch view
    local iconTouchViewSize = cc.size(60, 60)
    local iconTouchView = display.newLayer(plotProgressBgSize.width - 38, plotProgressBgSize.height / 2, {enable = true, color = cc.c4b(0,0,0,0), ap = display.CENTER, size = iconTouchViewSize})
    plotProgressBgLayer:addChild(iconTouchView)

    local icon = FilteredSpriteWithOne:create()
    display.commonUIParams(icon, {po = cc.p(iconTouchView:getPositionX(), iconTouchView:getPositionY()), ap = display.CENTER})
    icon:setScale(0.4)
    plotProgressBgLayer:addChild(icon, 1)

    local plotListBgSize = cc.size(516, bgSize.height - 210)
    local plotListBgLayer = display.newLayer(bgSize.width / 2, bgSize.height - 186, {ap = display.CENTER_TOP, size = plotListBgSize})
    bgLayer:addChild(plotListBgLayer)
    plotListBgLayer:addChild(display.newImageView(RES_DIR.PLOT_LIST_BG, plotListBgSize.width / 2, plotListBgSize.height  / 2, {scale9 = true, ap = display.CENTER, size = plotListBgSize}))

    local gridViewCellSize = cc.size(plotListBgSize.width, 102)
    local gridView = CGridView:create(cc.size(plotListBgSize.width, plotListBgSize.height - 14))
    display.commonUIParams(gridView, {ap = display.CENTER, po = cc.p(plotListBgSize.width / 2, plotListBgSize.height / 2)})
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(1)
    plotListBgLayer:addChild(gridView)

    guestPlotLayer.viewData = {
        guestStarTip   = guestStarTip,
        stars          = stars,
        upgradeStarTip = upgradeStarTip,
        progressBar    = progressBar,
        iconTouchView  = iconTouchView,
        icon           = icon,
        gridView       = gridView,
    }
    return guestPlotLayer
end

CreateCell_  = function (cellSize)
    local cell = CGridViewCell:new()

    local bgSize = cc.size(499, 91)
    local layer = display.newLayer(cellSize.width / 2, cellSize.height / 2, {size = bgSize, ap = display.CENTER})
    cell:addChild(layer)
    
    local touchView = display.newLayer(bgSize.width / 2, bgSize.height / 2, {enable = true, color = cc.c4b(0,0,0,0), size = bgSize, ap = display.CENTER})
    layer:addChild(touchView)

    layer:addChild(display.newImageView(RES_DIR.JVQING_BG, bgSize.width / 2, bgSize.height / 2, {ap = display.CENTER}))

    local unlockBg = display.newImageView(RES_DIR.JVQING_BG_UNLOCK, bgSize.width / 2, bgSize.height / 2 + 1, {ap = display.CENTER})
    layer:addChild(unlockBg)

    local plotNameLabel = display.newLabel(12, bgSize.height / 2, 
        fontWithColor(6, {color = '#936441', w = 400, ap = display.LEFT_CENTER, hAlign = display.TAL, text = '???'}))
    layer:addChild(plotNameLabel)

    local lock = display.newNSprite(RES_DIR.LOCK_IMG, bgSize.width - 50, bgSize.height / 2)
    layer:addChild(lock)

    -- local redPointImg = display.newImageView(RES_DIR.RED_IMG, bgSize.width - 10, bgSize.height - 12)
    -- redPointImg:setVisible(false)
    -- layer:addChild(redPointImg)

    cell.viewData = {
        lock          = lock,
        unlockBg      = unlockBg,
        touchView     = touchView,
        -- redPointImg   = redPointImg,
        plotNameLabel = plotNameLabel,
    }

    return cell
end

function PrivateRoomGuestInfoDescView:CreateCell(cellSize)
    return CreateCell_(cellSize)
end

function PrivateRoomGuestInfoDescView:getViewData()
	return self.viewData_
end

return PrivateRoomGuestInfoDescView