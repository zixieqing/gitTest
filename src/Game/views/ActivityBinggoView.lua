--[[
	binggo 页面
--]]
local VIEW_SIZE = display.size
local ActivityBinggoView = class('ActivityBinggoView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityBinggoView'
	node:enableNodeEvents()
	return node
end)

local CreateView       = nil
local CreateListCell_ = nil
local CreatePuzzleView = nil
local CreateTaskList   = nil
local CreateUnlockCoverLayer = nil

local RES_DIR = {
	BTN_BG                       = _res('ui/common/activity_mifan_by_ico'),
	BTN_ORANGE                   = _res('ui/common/common_btn_big_orange.png'),
	BG                           = _res('ui/home/activity/puzzle/puzzlePop/activity_puzzle_bg.png'),
	TIME_BG                      = _res('ui/home/activity/puzzle/puzzlePop/activity_puzzle_time_bg.png'),

	-- puzzle
	PUZZLE_CELL_LIGHT            = _res('ui/home/activity/puzzle/puzzlePop/activity_puzzle_light.png'),
	PUZZLE_CELL_GREEN_BTN        = _res('ui/home/activity/puzzle/puzzlePop/activity_puzzle_btn_zuan.png'),
	PUZZLE_CELL_GRAY_BTN         = _res('ui/home/activity/puzzle/puzzlePop/activity_puzzle_btn_zuan_unlock.png'),
	
	-- puzzle task
	PUZZLE_TASK_TITLE            = _res('ui/home/activity/puzzle/puzzlePop/activity_puzzle_title.png'),
	PUZZLE_TASK_BG               = _res('ui/home/activity/puzzle/puzzlePop/activity_puzzle_task_bg.png'),

	-- puzzle task cell
	TASK_BG_TITLE                = _res('ui/home/task/task_bg_title.png'),
	PUZZLE_TASK_CELL_BG          = _res('ui/home/activity/puzzle/puzzlePop/activity_puzzle_task_frame_default.png'),
	PUZZLE_TASK_CELL_BG_COMPLETE = _res('ui/home/activity/puzzle/puzzlePop/activity_puzzle_task_frame_completed.png'),

	BTN_TIPS                     = _res('ui/common/common_btn_tips.png'),
	
}

local getPuzzleCover = nil

function ActivityBinggoView:ctor( ... )
	local args = unpack({...})

	self.viewData_ = CreateView()

	self:addChild(self:getViewData().view)
	-- self:getViewData().view:setPosition(utils.getLocalCenter(self))
end

function ActivityBinggoView:showClickCoverAction(coverLayer, index)
	if coverLayer == nil or tolua.isnull(coverLayer) then return end
	index = index or 1

	coverLayer:setLocalZOrder(100 + 9 - index)
	local coverLight = coverLayer:getChildByName('coverLight')
	local cover = coverLayer:getChildByName('cover')
	local openLabel = coverLayer:getChildByName('openLabel')
	local touchView = coverLayer:getChildByName('touchView')

	touchView:setVisible(true)
	coverLight:setVisible(true)
	openLabel:setVisible(true)
	local action = cc.Sequence:create({
		cc.DelayTime:create(0.2 * index),
		cc.CallFunc:create(function ()
			local seq2 = cc.RepeatForever:create(
				cc.Sequence:create({
					cc.FadeTo:create(0.37, 130),
					cc.FadeTo:create(0.37, 255),
					cc.FadeTo:create(0.37, 130),
					cc.FadeTo:create(0.37, 255)
				})
			)
			local seq = cc.RepeatForever:create(cc.RotateBy:create(5, 360))
			coverLight:runAction(seq2)

			local seq1 = cc.RepeatForever:create(
				cc.Sequence:create({
					cc.RotateTo:create(0.1, -3),
					cc.RotateTo:create(0.1, 3),
					cc.RotateTo:create(0.1, -3),
					cc.RotateTo:create(0.07, 1),
					cc.RotateTo:create(0.03, 3),
					cc.RotateTo:create(0.1, 0),
					cc.DelayTime:create(1),
				})
			)
			cover:runAction(seq1)

			local seq2 = cc.RepeatForever:create(
				cc.Sequence:create({
					cc.FadeTo:create(0.37, 130),
					cc.FadeTo:create(0.37, 255),
					cc.FadeTo:create(0.37, 130),
					cc.FadeTo:create(0.37, 255)
				})
			)
			openLabel:runAction(seq2)
			-- cover
		end),
		-- cc.TargetedAction:create(cover, cc.RotateBy:create(0.1, -6)),
	})

	self:runAction(action)
end

function ActivityBinggoView:showCoverAction(cover, index, cb)
	if cover == nil or tolua.isnull(cover) then return end
	index = index or 1
	cover:setLocalZOrder(120 + 9 - index)

	cover:stopAllActions()

	local coverLight = cover:getChildByName('coverLight')
	local openLabel = cover:getChildByName('openLabel')
	local touchView = cover:getChildByName('touchView')
	coverLight:setVisible(false)
	openLabel:setVisible(false)
	touchView:setVisible(false)

	local couverX, couverY = cover:getPosition()
	local coverSize = cover:getContentSize()
	local action = cc.Sequence:create({
		cc.DelayTime:create(0.2 * index),
		cc.TargetedAction:create(cover, cc.RotateBy:create(0.1, -6)),
		cc.Spawn:create({
			cc.TargetedAction:create(cover, cc.MoveTo:create(0.14, cc.p(couverX + coverSize.width * 0.2, couverY + coverSize.height))),
			cc.TargetedAction:create(cover, cc.RotateBy:create(0.14, 96)),
		}),
		cc.Spawn:create({
			cc.TargetedAction:create(cover, cc.MoveTo:create(0.14, cc.p(couverX + coverSize.width * 0.2, couverY + coverSize.height * 1.5))),
			cc.TargetedAction:create(cover, cc.RotateBy:create(0.14, 90)),
		}),
		cc.TargetedAction:create(cover, cc.RotateBy:create(0.1, 90)),
		cc.Spawn:create({
			cc.TargetedAction:create(cover, cc.MoveTo:create(0.14, cc.p(couverX + coverSize.width * 0.2, couverY + coverSize.height * 0.8))),
			cc.TargetedAction:create(cover, cc.RotateBy:create(0.14, 90)),
		}),
		cc.Spawn:create({
			cc.TargetedAction:create(cover, cc.MoveTo:create(0.14, cc.p(couverX + coverSize.width * 0.2, couverY - coverSize.height * 0.2))),
			cc.TargetedAction:create(cover, cc.RotateBy:create(0.14, 90)),
		}),
		cc.Spawn:create({
			cc.TargetedAction:create(cover, cc.MoveTo:create(0.14, cc.p(couverX + coverSize.width * 0.5, couverY - coverSize.height * 1.8))),
			cc.TargetedAction:create(cover, cc.RotateBy:create(0.14, 90)),
		}),
		cc.Spawn:create({
			cc.TargetedAction:create(cover, cc.MoveTo:create(0.14, cc.p(couverX + coverSize.width * 0.5, couverY - coverSize.height * 4))),
			cc.TargetedAction:create(cover, cc.RotateBy:create(0.14, 90)),
		}),
		cc.CallFunc:create(function ()
			if cb then
				cb()
			end
		end),
	})
	self:runAction(action)
end

function ActivityBinggoView:updateCellBg(bg, isComplete)
	bg:setTexture(isComplete and RES_DIR.PUZZLE_TASK_CELL_BG_COMPLETE or RES_DIR.PUZZLE_TASK_CELL_BG)
end

function ActivityBinggoView:updateUnlockCoverImg(unlockCoverImg, isConsumeDiamondUnlock)
	unlockCoverImg:setTexture(isConsumeDiamondUnlock and RES_DIR.PUZZLE_CELL_GREEN_BTN or RES_DIR.PUZZLE_CELL_GRAY_BTN)
end

function ActivityBinggoView:getViewData()
	return self.viewData_
end

function ActivityBinggoView:CreateListCell(size)
	return CreateListCell_(size)
end

CreateView = function ()
    local view = display.newLayer(0, 0,{ap = display.LEFT_BOTTOM, size = VIEW_SIZE})
	local closeView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 130), enable = true, size = VIEW_SIZE, ap = display.LEFT_BOTTOM})
	view:addChild(closeView)

	local bg = display.newImageView(RES_DIR.BG, 0, 0, {ap = display.LEFT_BOTTOM})
	local bgSize = bg:getContentSize()
	local bgLayer = display.newLayer(VIEW_SIZE.width / 2, VIEW_SIZE.height / 2, {ap = display.CENTER, size = bgSize})
	bgLayer:addChild(bg)
	view:addChild(bgLayer)

	local swallLayer = display.newLayer(bgSize.width/2, bgSize.height/2, {ap = display.CENTER, size = bgSize, enable = true, color = cc.c4b(0,0,0,0)})
	bgLayer:addChild(swallLayer)
	
	-- (当活动开启4天后，玩家可点击拼图直接用幻晶石完成相对应的任务)
	local tipLabel = display.newLabel(15, bgSize.height - 15, fontWithColor(16, {fontSize = 18, ap = display.LEFT_TOP, text = __('解开所有拼图获得神秘奖励')}))
	local tipLabelSize = display.getLabelContentSize(tipLabel)
	bgLayer:addChild(tipLabel)

	local tipBtn = display.newButton(tipLabel:getPositionX() + tipLabelSize.width + 5, bgSize.height - 26, {ap = display.LEFT_CENTER, n = RES_DIR.BTN_TIPS, animate = false})
	tipBtn:setScale(0.8)
    bgLayer:addChild(tipBtn, 1)

	local timeBg = display.newImageView(RES_DIR.TIME_BG, bgSize.width, bgSize.height - 10, {ap = display.RIGHT_TOP})
	local timeBgSize = timeBg:getContentSize()
	bgLayer:addChild(timeBg)
	local timeTitleLabel = display.newLabel(timeBgSize.width - 10, timeBgSize.height / 2, {fontSize = 20, color = '#ffba00', ap = display.RIGHT_CENTER})
	timeBg:addChild(timeTitleLabel)
	
	local puzzleViewData = CreatePuzzleView()
	display.commonUIParams(puzzleViewData.view, {po = cc.p(tipLabel:getPositionX(), tipLabel:getPositionY() - tipLabelSize.height - 5)})
	bgLayer:addChild(puzzleViewData.view, 1)

	local taskListViewData = CreateTaskList()
	display.commonUIParams(taskListViewData.view, {po = cc.p(bgSize.width - 12, puzzleViewData.view:getPositionY())})
	bgLayer:addChild(taskListViewData.view)

	return {
		view 	           = view,
		tipBtn             = tipBtn,
		closeView          = closeView,
		timeTitleLabel     = timeTitleLabel,
		puzzleViewData     = puzzleViewData,
		taskListViewData   = taskListViewData,
	}
end

CreatePuzzleView = function ()
	local puzzleBgSize = cc.size(600, 603)
	local puzzleBg = display.newImageView('', 0, 0, {ap = display.LEFT_BOTTOM})
	local view     = display.newLayer(0, 0, {ap = display.LEFT_TOP, size = puzzleBgSize})
	view:addChild(puzzleBg)

	local curRow = 1
	local covers = {}
	local offsetX, offsetY = puzzleBgSize.width / 3, puzzleBgSize.height / 3
	local coverSize = cc.size(200, 204)
	for i = 1, 9 do
		local curCol = (i % 3 == 0) and 3 or i % 3

		local x = offsetX / 2 + (curCol - 1) * offsetX
		local y = puzzleBgSize.height - 5 - (offsetY / 2 + (curRow - 1) * (offsetY - 3))

		local coverLayer = display.newLayer(x, y, {ap = display.CENTER, size = coverSize})
		view:addChild(coverLayer, 9 - i)

		local touchView = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, color = cc.c4b(0,0,0,0), size = coverSize, enable = true})
		coverLayer:addChild(touchView, 10)
		touchView:setName('touchView')
		touchView:setVisible(false)
		touchView:setTag(i)

		local coverLight = display.newImageView(RES_DIR.PUZZLE_CELL_LIGHT, coverSize.width / 2, coverSize.height / 2, {ap = display.CENTER})
		coverLayer:addChild(coverLight)
		coverLight:setName('coverLight')
		coverLight:setVisible(false)

		local cover = display.newImageView(getPuzzleCover(i), coverSize.width / 2, coverSize.height / 2, {ap = display.CENTER})
		coverLayer:addChild(cover, 1)
		-- cover:setVisible(false)
		cover:setName('cover')

		local unlockCoverLayer = CreateUnlockCoverLayer()
		unlockCoverLayer:setName('unlockCoverLayer')
		display.commonUIParams(unlockCoverLayer, {po = cc.p(coverSize.width / 2, 11), ap = display.CENTER_BOTTOM})
		coverLayer:addChild(unlockCoverLayer, 2)

		local openLabel = display.newLabel(coverSize.width / 2, coverSize.height / 2, {fontSize = 24, text = __('点击打开'), font = TTF_GAME_FONT, ttf = true, color = '#ffffff', ap = display.CENTER, outline = '#5b3c25', outlineSize = 1})
		coverLayer:addChild(openLabel, 2)
		openLabel:setVisible(false)
		openLabel:setName('openLabel')

		table.insert(covers, coverLayer)

		curRow = (i % 3 == 0) and (curRow + 1) or curRow
	end

	local rewardBtn = display.newButton(puzzleBgSize.width / 2, puzzleBgSize.height / 6, {ap = display.CENTER, n = RES_DIR.BTN_ORANGE})
	display.commonLabelParams(rewardBtn, {fontSize = 24, text = __('领取奖励'), color = '#ffffff'})
	view:addChild(rewardBtn)
	rewardBtn:setVisible(false)

	return {
		view      = view,
		puzzleBg  = puzzleBg,
		covers    = covers,
		rewardBtn = rewardBtn,
	}
end

CreateUnlockCoverLayer = function ()
	local unlockCoverLayerSize = cc.size(186, 32)
	local unlockCoverLayer = display.newLayer(0, 0, {size = unlockCoverLayerSize})

	-- local unlockCoverBtn = display.newButton(unlockCoverLayerSize.width / 2, unlockCoverLayerSize.height / 2, {ap = display.CENTER_BOTTOM, n = RES_DIR.PUZZLE_CELL_GREEN_BTN})
	-- unlockCoverLayer:addChild(unlockCoverBtn)
	-- unlockCoverBtn:setOpacity(255 * 0.4)

	local unlockCoverTouchLayer = display.newLayer(0, 0, {size = unlockCoverLayerSize, ap = display.LEFT_BOTTOM, enable = true, color = cc.c4b(0)})
	unlockCoverLayer:addChild(unlockCoverTouchLayer)

	local unlockCoverImgSize = cc.size(186, 32)
	local unlockCoverImg = display.newImageView(RES_DIR.PUZZLE_CELL_GREEN_BTN, unlockCoverLayerSize.width / 2, unlockCoverLayerSize.height / 2, {scale9 = true, size = unlockCoverImgSizeZ, ap = display.CENTER})
	unlockCoverLayer:addChild(unlockCoverImg, 2)

	local unlockCoverTip = display.newRichLabel(93, 16, {ap = display.CENTER})
	unlockCoverImg:addChild(unlockCoverTip)

	unlockCoverLayer.viewData = {
		unlockCoverTouchLayer = unlockCoverTouchLayer,
		unlockCoverImg = unlockCoverImg,
		unlockCoverTip = unlockCoverTip,
	}

	return unlockCoverLayer
end

CreateTaskList   = function ()

	local size = cc.size(479, 603)
	local view = display.newLayer(0, 0, {ap = display.RIGHT_TOP, size = size})

	local taskListTitle = display.newImageView(RES_DIR.PUZZLE_TASK_TITLE, size.width / 2, size.height, {ap = display.CENTER_TOP})
	local taskListTitleSize = taskListTitle:getContentSize()
	view:addChild(taskListTitle)

	local tipLabel = display.newLabel(10, taskListTitleSize.height / 2, fontWithColor(18, {fontSize = 20, w = 300, ap = display.LEFT_CENTER, text = __('完成任务解锁拼图')}))
	taskListTitle:addChild(tipLabel)

	local progressLabel = display.newLabel(taskListTitleSize.width, taskListTitleSize.height / 2, fontWithColor(18, {fontSize = 20, w = 160, ap = display.RIGHT_CENTER}))
	taskListTitle:addChild(progressLabel)

	local taskBgSize = cc.size(size.width, size.height - taskListTitleSize.height)
	local taskBg  = display.newImageView(RES_DIR.PUZZLE_TASK_BG, size.width / 2, taskBgSize.height, {ap = display.CENTER_TOP, scale9 = true, size = taskBgSize})
	view:addChild(taskBg)

	local gridViewCellSize = cc.size(taskBgSize.width, 126)
    local gridView = CGridView:create(taskBgSize)
    gridView:setPosition(cc.p(taskBg:getPositionX(), taskBg:getPositionY()))
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    gridView:setAnchorPoint(display.CENTER_TOP)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(1)
    view:addChild(gridView)

	return {
		view          = view,
		progressLabel = progressLabel,
		gridView      = gridView,
	}
end

CreateListCell_ = function (size)
	local cell = CGridViewCell:new()
	cell:setContentSize(size)
	-- dump(cell:getContentSize(), 'getContentSizegetContentSize')
	local bg = display.newImageView(RES_DIR.PUZZLE_TASK_CELL_BG, 0, 0, {ap = display.LEFT_BOTTOM})
	local bgSize = bg:getContentSize()
	local bgLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = bgSize})
	bgLayer:addChild(bg)
	cell:addChild(bgLayer)

	local taskTitleBg = display.newImageView(RES_DIR.TASK_BG_TITLE, 0, bgSize.height - 10, {ap = display.LEFT_TOP})
	local taskTitleBgSize = taskTitleBg:getContentSize()
	bgLayer:addChild(taskTitleBg)

	local taskTitle = display.newLabel(13, taskTitleBgSize.height / 2, {text = __('解密任务: '), fontSize = 24, color = '#5b3c25', ap = display.LEFT_CENTER})
	local taskTitleSize = display.getLabelContentSize(taskTitle)
	taskTitleBg:addChild(taskTitle)

	local puzzleLabel = display.newLabel(taskTitle:getPositionX() + taskTitleSize.width + 3, taskTitle:getPositionY(), {fontSize = 24, color = '#a22222', ap = display.LEFT_CENTER})
	taskTitleBg:addChild(puzzleLabel)

	local descLabel = display.newLabel(13, bgSize.height / 2 + 5, fontWithColor(6, {fontSize = 20, ap = display.LEFT_TOP, w = 360}))
	bgLayer:addChild(descLabel)
	
	local progressLabel = display.newLabel(bgSize.width - 18, bgSize.height / 2, fontWithColor(6, {ap = display.RIGHT_TOP}))
	bgLayer:addChild(progressLabel)
	progressLabel:setVisible(false)

	local commplete = display.newButton(bgSize.width - 5, bgSize.height / 2, {ap = display.RIGHT_CENTER, n = RES_DIR.BTN_BG, enable = false})
	display.commonLabelParams(commplete, {text = __('已完成'), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true})
	commplete:setScale(0.7)
	bgLayer:addChild(commplete)
	commplete:setVisible(false)

	cell.viewData = {
		bg            = bg,
		puzzleLabel   = puzzleLabel,
		descLabel     = descLabel,
		progressLabel = progressLabel,
		commplete     = commplete,
	}

	return cell
end

getPuzzleCover = function (index)
	local path = _res(string.format('ui/home/activity/puzzle/puzzlePop/activity_puzzle_%s.png', index))
	if not utils.isExistent(path) then
		path = _res('ui/home/activity/puzzle/puzzlePop/activity_puzzle_1.png')
	end
	return path
end

return ActivityBinggoView
