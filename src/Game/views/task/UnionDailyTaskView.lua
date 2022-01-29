--[[
工会任务系统UI
--]]
local VIEW_SIZE = cc.size(1230, 641)
local UnionDailyTaskView = class('UnionDailyTaskView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.task.UnionDailyTaskView'
	node:enableNodeEvents()
	return node
end)

local CreateView       = nil
local CreateUnionContributionBox = nil

local RES_DIR = {
    BG_ONEKEY	    = _res("ui/home/task/task_bg_onekey.png"),
	BTN_ONEKEY	    = _res("ui/home/task/task_btn_onekey.png"),
    BTN_BG          = _res('ui/common/activity_mifan_by_ico.png'),
    LIST_BG         = _res('ui/home/task/task_bg_frame_gray_2.png'),
    LIVENESS_NUM_BG = _res('ui/home/task/task_img_blue_flag.png'),
    PROSSBAR_BG     = _res('ui/home/task/task_bar_bg.png'),
    PROSSBAR        = _res('ui/home/task/task_bar.png'),
    BG_GUILDTASK    = _res("ui/union/unionTask/guild_task_bg_guildtask.png"),
    CARTON          = _res("ui/union/unionTask/guild_task_qban.png"),
    BOX_IMG         = _res('arts/goods/goods_icon_190003.png'),

    SPINE_BOX       = _spn('effects/xiaobaoxiang/box_2'),
}

function UnionDailyTaskView:ctor( ... )
    self.args = unpack({...})
    self:initialUI()
end

function UnionDailyTaskView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)
	end, __G__TRACKBACK__)
end

function UnionDailyTaskView:refreshView(taskDatas)
    -- update task list
    self:updateList(taskDatas)

    -- update personal contribution
    self:updatePersonalContribution(taskDatas)
    
    -- update union contribution
    self:updateUnionContribution(taskDatas)
end

--==============================--
--desc: 更新个人工会任务列表
--@params taskDatas table 任务数据
--==============================--
function UnionDailyTaskView:updateList(taskDatas)
    local tasks = taskDatas.tasks
    local viewData = self:getViewData()
    local taskListView = viewData.taskListView
    taskListView:setCountOfCell(#tasks)
	taskListView:reloadData()
end

--==============================--
--desc: 更新个人工会任务cell
--@params cell userdata 
--@params data table    任务数据 
--==============================--
function UnionDailyTaskView:updateTaskCell(cell, data)
    
    if cell then
        local pButton = cell:getChildByName('pButton')
        pButton:refreshUI(data)

        local viewData = pButton.viewData
        local expBtn = viewData.expBtn
        expBtn:setVisible(true)
        
        local expLabel = viewData.expLabel
        display.commonLabelParams(expLabel, {text = tostring(data.contributionPoint)})
        local expTipLabel = viewData.expTipLabel
        expTipLabel:setVisible(true)
        display.commonLabelParams(expTipLabel, {text = __('贡献值')})
    end
end

--==============================--
--desc: 更新个人工会贡献
--@params taskDatas table 任务数据
--==============================--
function UnionDailyTaskView:updatePersonalContribution(taskDatas)
    local viewData      = self:getViewData()
    local progressBarBg = viewData.progressBarBg
    local progressBarBgSize = progressBarBg:getContentSize()
    -- update personal contribution
    local personalContributionPoint = checkint(taskDatas.personalContributionPoint)
    self:updatePersonalContributionPoint(viewData, personalContributionPoint)
    
    local boxs           = viewData.boxs
    local personalContributionPointRewards = taskDatas.personalContributionPointRewards or {}
    local maxProgressNum = checkint(personalContributionPointRewards[#personalContributionPointRewards].contributionPoint)
    local startX = progressBarBg:getPositionX()
    for i, box in ipairs(boxs) do
        box:setVisible(true)
        local data = personalContributionPointRewards[i]
        if data then
            local contributionPoint = checkint(data.contributionPoint)
            display.commonUIParams(box, {po = cc.p(startX + contributionPoint / maxProgressNum * progressBarBgSize.width, box:getPositionY())})
            -- logInfo.add(5, 'logStr')
            -- maxProgressNum = math.max(maxProgressNum, contributionPoint)
            self:updateBox(box, data, personalContributionPoint)
        end
    end

    if personalContributionPoint > maxProgressNum then
        personalContributionPoint = maxProgressNum
    end
    self:updateProgressBar(personalContributionPoint, maxProgressNum)
end

--==============================--
--desc: 更新个人工会贡献点
--@params viewData table 视图数据
--@params personalContributionPoint int 个人工会贡献点
--==============================--
function UnionDailyTaskView:updatePersonalContributionPoint(viewData, personalContributionPoint)
    local personalContribution = viewData.personalContribution
    display.commonLabelParams(personalContribution, {text = personalContributionPoint})
end

--==============================--
--desc: 更新个人工会贡献宝箱
--@params box useerdata 视图数据
--@params data table 数据
--@params personalContributionPoint table 视图数据
--@params personalContributionPoint int 个人工会贡献点
--==============================--
function UnionDailyTaskView:updateBox(box, data, personalContributionPoint)
    local contributionPoint = checkint(data.contributionPoint)

    local label = box:getChildByName('label')
    if label then
        display.commonLabelParams(label, {text = contributionPoint})
    end

    local spBox = box:getChildByName('spBox')
    if data.hasDrawn == 0 and personalContributionPoint >= contributionPoint then
        spBox:setAnimation(0, 'idle', true)
        if box:getChildByName('particle') then
            box:getChildByName('particle'):removeFromParent()
        end
        local particle = cc.ParticleSystemQuad:create('effects/baoxiang.plist')
        particle:setAutoRemoveOnFinish(true)
        particle:setPosition(cc.p(box:getContentSize().width /2, 60))
        box:addChild(particle)
        particle:setName('particle')
    else
        if data.hasDrawn == 1 then
            spBox:setAnimation(0, 'play', true)
            spBox:setColor(cc.c3b(100, 100, 100))
        end
    end
end

--==============================--
--desc: 更新个人工会贡献进度
--@params personalContributionPoint int 个人工会贡献点
--@params maxProgressNum int 最大个人工会贡献点
--==============================--
function UnionDailyTaskView:updateProgressBar(personalContributionPoint, maxProgressNum)
    local viewData = self:getViewData()
    local progressBar = viewData.progressBar

    if maxProgressNum then
        progressBar:setMaxValue(maxProgressNum)
    end

    if personalContributionPoint then
        progressBar:setValue(personalContributionPoint)
    end
end

--==============================--
--desc: 更新个人工会贡献 box cell
--@params index int cell下标
--@params data  table  个人工会贡献奖励数据
--@params personalContributionPoint int 个人工会贡献点
--==============================--
function UnionDailyTaskView:updatePersonalContributtonCell(index, data, personalContributionPoint)
    local viewData = self:getViewData()
    local boxs     = viewData.boxs
    local box      = boxs[index]
    local contributionPoint = checkint(data.contributionPoint)

    self:updateBox(box, data, personalContributionPoint)

end

--==============================--
--desc: 更新工会贡献
--@params taskDatas table 任务数据
--==============================--
function UnionDailyTaskView:updateUnionContribution(taskDatas)
    
    local viewData               = self:getViewData()
    local unionContributionPoint = checkint(taskDatas.unionContributionPoint)
    self:updateUnionContributionPoint(viewData, unionContributionPoint)

    local unionContributionPointRewards = taskDatas.unionContributionPointRewards or {}
    self:updateUnionContributionBoxs(viewData, unionContributionPointRewards, unionContributionPoint)
    
end

--==============================--
--desc: 更新工会贡献点
--@params viewData table 视图数据
--@params unionContributionPoint int 工会贡献点
--==============================--
function UnionDailyTaskView:updateUnionContributionPoint(viewData, unionContributionPoint)
    local unionContributionNum   = viewData.unionContributionNum
    unionContributionNum:setString(unionContributionPoint)
end

--==============================--
--desc: 更新工会贡献宝箱
--@params viewData table 视图数据
--@params unionContributionPointRewards table 工会贡献奖励数据
--@params unionContributionPoint int 工会贡献点
--==============================--
function UnionDailyTaskView:updateUnionContributionBoxs(viewData, unionContributionPointRewards, unionContributionPoint)
    local unionContributionBoxs = viewData.unionContributionBoxs
    for i, unionContributionBox in ipairs(unionContributionBoxs) do
        local data = unionContributionPointRewards[i]
        if data then
            local boxViewData = unionContributionBox.viewData
            local contributionNum = boxViewData.contributionNum
            local contributionPoint = checkint(data.contributionPoint)
            display.commonLabelParams(contributionNum, {text = contributionPoint})

            local receiveBgLayer  = boxViewData.receiveBgLayer
            receiveBgLayer:setVisible(unionContributionPoint >= contributionPoint)
        end

    end
end


CreateView = function (size)
    local view = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})

    -- one key receive
    local oneKeyTaskBgSize = cc.size(140, 79)
    local oneKeyTaskBgLayer = display.newLayer(VIEW_SIZE.width - 183, 52, {ap = display.LEFT_CENTER, size = oneKeyTaskBgSize})
    view:addChild(oneKeyTaskBgLayer)

    oneKeyTaskBgLayer:addChild(display.newLayer(0,0,{size = oneKeyTaskBgSize, ap = display.LEFT_BOTTOM, color = cc.c4b(0,0,0,0), enable = true}))
    
    oneKeyTaskBgLayer:addChild(display.newImageView(RES_DIR.BG_ONEKEY, 0, oneKeyTaskBgSize.height / 2, {ap = display.LEFT_CENTER}))
    local oneKeyReceiveBtn = display.newButton(oneKeyTaskBgSize.width / 2, oneKeyTaskBgSize.height / 2, {ap = display.CENTER, n = RES_DIR.BTN_ONEKEY})
    display.commonLabelParams(oneKeyReceiveBtn, fontWithColor(14, {text = __('一键领取')}))
    oneKeyTaskBgLayer:addChild(oneKeyReceiveBtn)

    local contentSize = cc.size(1082, 641)
    local contentLayout = display.newLayer(543, VIEW_SIZE.height / 2, {ap = display.CENTER, size = contentSize})
    view:addChild(contentLayout)

    local topLayerSize = cc.size(994, 120)
    local topLayer = display.newLayer(contentSize.width / 2, contentSize.height - 60, {ap = display.CENTER_TOP, size = topLayerSize})
    contentLayout:addChild(topLayer)
    
    local cartonImg = display.newImageView(RES_DIR.CARTON, 80, topLayerSize.height / 2 + 18, {ap = display.CENTER})
    topLayer:addChild(cartonImg)

    -- personal contribution
    local personalContribution = display.newButton(105, 30, {n = RES_DIR.LIVENESS_NUM_BG, animate = false, enable = false})
    local personalContributionSize = personalContribution:getContentSize()
    display.commonLabelParams(personalContribution, {fontSize = 24, color = '#ffffff', offset = cc.p(-20,-2)})
    topLayer:addChild(personalContribution)

    personalContribution:addChild(display.newLabel(personalContributionSize.width * 0.5 - 20, 0, fontWithColor(8, {text = __('贡献值'), ap = display.CENTER_TOP})))

    local progressBarBg = display.newImageView(RES_DIR.PROSSBAR_BG, personalContribution:getPositionX() + personalContributionSize.width / 2, 30, {ap = display.LEFT_CENTER})
    local progressBarBgSize = progressBarBg:getContentSize()
    topLayer:addChild(progressBarBg)

    local progressBar = CProgressBar:create(RES_DIR.PROSSBAR)
    progressBar:setDirection(eProgressBarDirectionLeftToRight)
    progressBar:setAnchorPoint(display.LEFT_CENTER)
    progressBar:setMaxValue(100)
    progressBar:setValue(0)
    progressBar:setPosition(cc.p(1, progressBarBgSize.height / 2))
    progressBarBg:addChild(progressBar)

    local boxs = {}
    local boxSize = cc.size(95,110)
    for i = 1, 5 do
        local y = progressBarBgSize.height + progressBarBg:getPositionY() + 20 - 53
        
        local layout = display.newLayer(0, y, {ap = display.CENTER_BOTTOM, color = cc.c4b(0, 0, 0, 0), size = boxSize, enable = true})
        layout:setTag(i)
        topLayer:addChild(layout)
        table.insert(boxs, layout)

        local spBox = sp.SkeletonAnimation:create(RES_DIR.SPINE_BOX.json, RES_DIR.SPINE_BOX.atlas, 0.6 + 0.03 * (i-1))
        spBox:setAnimation(0, 'stop', true)
        spBox:setPosition(cc.p(boxSize.width /2, 60))
        layout:addChild(spBox,1)
        spBox:setName('spBox')

        local label = display.newLabel(boxSize.width /2, boxSize.height/2 - 66, fontWithColor(8,{ap = display.CENTER}))
        layout:addChild(label)
        label:setName('label')

        layout:setVisible(false)
    end

    -- task list
    local listBgSize = cc.size(979, 310)
    local listBg = display.newImageView(RES_DIR.LIST_BG, contentSize.width * 0.5, contentSize.height - 356,
		{scale9 = true, size = listBgSize, ap = display.CENTER})
    contentLayout:addChild(listBg)
    
    local taskListSize = cc.size(listBgSize.width - 8, listBgSize.height - 8)
    local taskListCellSize = cc.size(taskListSize.width, 120)
    local taskListView = CGridView:create(taskListSize)
    display.commonUIParams(taskListView, {ap = display.CENTER, po = cc.p(listBg:getPositionX(), listBg:getPositionY())})
    -- taskListView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    taskListView:setSizeOfCell(taskListCellSize)
    taskListView:setColumns(1)
    view:addChild(taskListView)

    -- union contribution
    local unionContributionBgSize = cc.size(979, 114)
    local unionContributionBgLayer = display.newLayer(contentSize.width / 2, 10, {size = unionContributionBgSize, scale9 = true, ap = display.CENTER_BOTTOM})
    view:addChild(unionContributionBgLayer)
    unionContributionBgLayer:addChild(display.newImageView(RES_DIR.BG_GUILDTASK, unionContributionBgSize.width / 2, unionContributionBgSize.height / 2, {size = unionContributionBgSize, scale9 = true, ap = display.CENTER}))

    unionContributionBgLayer:addChild(display.newLabel(150, unionContributionBgSize.height / 2, fontWithColor(16, {hAlign = display.TAC, w = 300, ap = display.CENTER_BOTTOM, text = __('今日工会任务累计贡献值')})))

    local unionContributionNum = cc.Label:createWithBMFont('font/common_num_1.fnt', 0)
    unionContributionNum:setAnchorPoint(display.CENTER_TOP)
    unionContributionNum:setHorizontalAlignment(display.TAR)
    unionContributionNum:setPosition(150, unionContributionBgSize.height / 2)
    unionContributionBgLayer:addChild(unionContributionNum)

    local unionContributionBoxSize = cc.size(330, unionContributionBgSize.height)
    local unionContributionBoxs = {}
    for i = 1, 2 do
        local unionContributionBox = CreateUnionContributionBox(unionContributionBoxSize)
        display.commonUIParams(unionContributionBox, {po = cc.p(unionContributionBgSize.width / 2 - 10 + (i - 1) * unionContributionBoxSize.width, unionContributionBgSize.height / 2), ap = display.CENTER})
        unionContributionBgLayer:addChild(unionContributionBox)
        table.insert(unionContributionBoxs, unionContributionBox)
    end

    return {
        view                    = view,
        personalContribution    = personalContribution,
        progressBarBg           = progressBarBg,
        progressBar             = progressBar,
        boxs                    = boxs,
        unionContributionNum    = unionContributionNum,
        unionContributionBoxs   = unionContributionBoxs,
        taskListView            = taskListView,
        oneKeyTaskBgLayer       = oneKeyTaskBgLayer,
        oneKeyReceiveBtn        = oneKeyReceiveBtn,
    }
end

CreateUnionContributionBox = function (size)
    local unionContributionBox = display.newLayer(0, 0, {ap = display.CENTER, size = size})

    local canReceiveLabel = display.newLabel(size.width / 2 + 50, size.height / 2, fontWithColor(16, {text = __('可领取'), ap = display.RIGHT_CENTER}))
    unionContributionBox:addChild(canReceiveLabel)

    local canReceiveLabelSize = display.getLabelContentSize(canReceiveLabel)
    local contributionNum = display.newLabel(canReceiveLabel:getPositionX() - 5 - canReceiveLabelSize.width, size.height / 2, fontWithColor(10, {ap = display.RIGHT_CENTER}))
    unionContributionBox:addChild(contributionNum)

    -- 
    local boxImg = display.newImageView(RES_DIR.BOX_IMG, size.width - 60, size.height / 2, {ap = display.CENTER})
    boxImg:setScale(0.6)
    unionContributionBox:addChild(boxImg)

    local boxTouchLayerSize = cc.size(100, 100)
    local boxTouchLayer = display.newLayer(size.width - 60, size.height / 2, {color = cc.c4b(0,0,0,0), enable = true, ap = display.CENTER, size = boxTouchLayerSize})
    unionContributionBox:addChild(boxTouchLayer)

    local receiveBgLayer = display.newLayer(boxTouchLayerSize.width / 2, boxTouchLayerSize.height / 2, {size = boxTouchLayerSize, ap = display.CENTER})
    boxTouchLayer:addChild(receiveBgLayer)

    local receiveBg = display.newImageView(RES_DIR.BTN_BG, boxTouchLayerSize.width / 2, boxTouchLayerSize.height / 2, {ap = display.CENTER})
    receiveBg:setScale(0.6)
    receiveBgLayer:addChild(receiveBg)

    local receiveLabel = display.newLabel(receiveBg:getPositionX(), receiveBg:getPositionY(), 
        fontWithColor(9, {text = __('已领取')}))
    receiveBgLayer:addChild(receiveLabel)
    receiveBgLayer:setVisible(false)

    unionContributionBox.viewData = {
        contributionNum = contributionNum,
        boxTouchLayer   = boxTouchLayer,
        receiveBgLayer  = receiveBgLayer,
    }
    return unionContributionBox
end

function UnionDailyTaskView:getViewData()
	return self.viewData_
end

return UnionDailyTaskView