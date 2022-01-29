--[[
每日任务系统UI
--]]
local VIEW_SIZE = cc.size(1230, 641)

local DailyTaskNewView = class('DailyTaskNewView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.task.DailyTaskNewView'
	node:enableNodeEvents()
	return node
end)

local CreateView      = nil

local RES_DIR = {
    BG_ONEKEY	        = _res("ui/home/task/task_bg_onekey.png"),
	BTN_ONEKEY	        = _res("ui/home/task/task_btn_onekey.png"),
    BTN_ORANGE_DISABLE  = _res('ui/common/common_btn_orange_disable.png'),
    LIST_BG             = _res('ui/home/task/task_bg_frame_gray_2.png'),
    CARTON              = _res('ui/home/task/task_img_bingtanghulu.png'),
    LIVENESS_NUM_BG     = _res('ui/home/task/task_img_blue_flag.png'),
    PROSSBAR_BG         = _res('ui/home/task/task_bar_bg.png'),
    PROSSBAR            = _res('ui/home/task/task_bar.png'),

    SPINE_BOX           = _spn('effects/xiaobaoxiang/box_2'),
}

function DailyTaskNewView:ctor( ... )
    self.args = unpack({...})
    self:initialUI()
end

function DailyTaskNewView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self:getViewData().view)
	end, __G__TRACKBACK__)
end

--==============================--
--desc: 更新任务列表相关UI
--time:2018-01-05 03:23:38
--@return 
--==============================-- 
function DailyTaskNewView:updateListUI(taskDatas)
    local viewData = self:getViewData()
	local listView = viewData.taskListView
	listView:setCountOfCell(table.nums(taskDatas))
	listView:reloadData()
end

--==============================--
--desc: 更新活跃度相关UI
--time:2018-01-05 03:23:38
--@return 
--==============================-- 
function DailyTaskNewView:updateLivenessUI(dailyActivenessDatas)
    local viewData = self:getViewData()
    local livenessNum = viewData.livenessNum
    local progressBar = viewData.progressBar
    
    local dailyActivenessCount = 0
    local dailyActivenessList = dailyActivenessDatas.list or {}

    local dataLen = #dailyActivenessList
    local maxActivePoint = checktable(dailyActivenessList[dataLen]).activePoint or 100
    if checkint(dailyActivenessDatas.activePoint) > maxActivePoint then
        dailyActivenessDatas.activePoint = maxActivePoint
    end
    local curActivePoint = checkint(dailyActivenessDatas.activePoint)
    progressBar:setMaxValue(maxActivePoint)
    progressBar:setValue(curActivePoint)

    display.commonLabelParams(livenessNum, {text = curActivePoint})

    local progressBarBg = viewData.progressBarBg
    local progressBarBgSize = progressBarBg:getContentSize()
    local startX = progressBarBg:getPositionX()
    for k, box in pairs(viewData.boxs) do
        box:setVisible(true)

        local data = dailyActivenessList[k]
        local activePoint = checkint(data.activePoint)
        display.commonUIParams(box, {po = cc.p(startX + activePoint / maxActivePoint * progressBarBgSize.width, box:getPositionY())})

        local label = box:getChildByName('label')
        if label then
            local text = string.fmt(__('__num__活跃'),{__num__ = checkint(data.activePoint)})
            display.commonLabelParams(label, {text = text})
        end

        local spBox       = box:getChildByName('spBox')
        local hasDrawn    = data.hasDrawn
        local activePoint = data.activePoint
        if hasDrawn == 0 and curActivePoint >= activePoint then
            dailyActivenessCount = dailyActivenessCount + 1
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
            if hasDrawn == 1 then
                spBox:setAnimation(0, 'play', true)
                spBox:setColor(cc.c3b(100, 100, 100))
            end
        end
    end

    return dailyActivenessCount
end

CreateView = function ()
    local view = display.newLayer(VIEW_SIZE.width / 2, VIEW_SIZE.height / 2, {ap = display.CENTER, size = VIEW_SIZE})

    -- one key receive
    local oneKeyTaskBgSize = cc.size(140, 79)
    local oneKeyTaskBgLayer = display.newLayer(VIEW_SIZE.width - 183, 52, {ap = display.LEFT_CENTER, size = oneKeyTaskBgSize})
    view:addChild(oneKeyTaskBgLayer)

    oneKeyTaskBgLayer:addChild(display.newLayer(0,0,{size = oneKeyTaskBgSize, ap = display.LEFT_BOTTOM, color = cc.c4b(0,0,0,0), enable = true}))
    
    oneKeyTaskBgLayer:addChild(display.newImageView(RES_DIR.BG_ONEKEY, 0, oneKeyTaskBgSize.height / 2, {ap = display.LEFT_CENTER}))
    local oneKeyReceiveBtn = display.newButton(oneKeyTaskBgSize.width / 2, oneKeyTaskBgSize.height / 2, {ap = display.CENTER, n = RES_DIR.BTN_ONEKEY})
    display.commonLabelParams(oneKeyReceiveBtn, fontWithColor(14, {text = __('一键领取') , w = 120 ,reqH = 60, hAlign= display.TAC}))
    oneKeyTaskBgLayer:addChild(oneKeyReceiveBtn)

    local size = cc.size(1082, 641)
    local contentLayer = display.newLayer(543, VIEW_SIZE.height / 2, {ap = display.CENTER, size = size})
    view:addChild(contentLayer)

    local topLayerSize = cc.size(994, 120)
    local topLayer = display.newLayer(size.width / 2, size.height - 15 - 28 - 20, {ap = display.CENTER_TOP, size = topLayerSize})
    contentLayer:addChild(topLayer)
    
    local cartonImg = display.newImageView(RES_DIR.CARTON, 55, topLayerSize.height / 2 + 35, {ap = display.CENTER})
    cartonImg:setScale(0.85)
    topLayer:addChild(cartonImg, 1)

    local livenessNum = display.newButton(0, 0, {n = RES_DIR.LIVENESS_NUM_BG, animate = false, enable = false})
    local livenessNumSize = livenessNum:getContentSize()
    display.commonLabelParams(livenessNum, {fontSize = 24, color = '#ffffff', offset = cc.p(-20,-2)})
    livenessNum:setPosition(cc.p(105, 40))
    topLayer:addChild(livenessNum)

    local livenessLabel = display.newLabel(livenessNumSize.width * 0.5 - 20, 0, fontWithColor(8, {text = __('活跃度'), ap = display.CENTER_TOP}))
    livenessNum:addChild(livenessLabel)

    local progressBarBg = display.newImageView(RES_DIR.PROSSBAR_BG, livenessNum:getPositionX() + livenessNumSize.width / 2, topLayerSize.height * 0.3, {ap = display.LEFT_CENTER})
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
    for i=1, 5 do
        local x = progressBarBg:getPositionX() + i * (progressBarBgSize.width / 6 + 15) -- (i-1) * progressBarBgSize.width/5 + progressBarBg:getPositionX() - progressBarBgSize.width/4 - 35 - 40
        local y = progressBarBgSize.height + progressBarBg:getPositionY() + 20 - 53
        
        local layout = display.newLayer(x, y, {ap = display.CENTER_BOTTOM, color = cc.c4b(0, 0, 0, 0), size = boxSize, enable = true})
        layout:setTag(i)
        topLayer:addChild(layout)
        layout:setVisible(false)
        boxs[i] = layout

        local spBox = sp.SkeletonAnimation:create(RES_DIR.SPINE_BOX.json, RES_DIR.SPINE_BOX.atlas, 0.6 + 0.03 * (i-1))
        -- spBox:setToSetupPose()
        spBox:setAnimation(0, 'stop', true)
        spBox:setPosition(cc.p(boxSize.width /2, 60))
        layout:addChild(spBox,1)
        spBox:setName('spBox')

        local label = display.newLabel(boxSize.width /2, boxSize.height/2 - 66, fontWithColor(8,{ap = display.CENTER}))
        layout:addChild(label)
        label:setName('label')

    end

    ------------------------------------------
    -- list 
    local listBgSize = cc.size(950, 428)
    local listBg = display.newImageView(_res(RES_DIR.LIST_BG), size.width * 0.5 , 20,
		{scale9 = true, size = listBgSize, ap = display.CENTER_BOTTOM})	--435
    contentLayer:addChild(listBg)
    
    local taskListSize = cc.size(listBgSize.width - 5, listBgSize.height - 10)
    local taskListCellSize = cc.size(taskListSize.width, 160)

    local taskListView = CGridView:create(taskListSize)
    taskListView:setSizeOfCell(taskListCellSize)
    taskListView:setColumns(1)
    taskListView:setAutoRelocate(true)
    contentLayer:addChild(taskListView)
    taskListView:setAnchorPoint(display.CENTER_BOTTOM)
    taskListView:setPosition(cc.p(listBg:getPositionX(), listBg:getPositionY()  + 2))

    return {
        view              = view,
        livenessNum       = livenessNum,
        progressBarBg     = progressBarBg,
        progressBar       = progressBar,
        boxs              = boxs,
        taskListView      = taskListView,
        oneKeyTaskBgLayer = oneKeyTaskBgLayer,
        oneKeyReceiveBtn  = oneKeyReceiveBtn,
    }
end

function DailyTaskNewView:getViewData()
	return self.viewData_
end

return DailyTaskNewView