local Mediator = mvc.Mediator
---@class ReturnWelfareBingoMediator:Mediator
local ReturnWelfareBingoMediator = class("ReturnWelfareBingoMediator", Mediator)

local NAME = "ReturnWelfareBingoMediator"
local app = app
local uiMgr = app.uiMgr
local qualityDefine = {
	['1'] = __('白色'),
	['2'] = __('绿色'),
	['3'] = __('蓝色'),
	['4'] = __('紫色'),
	['5'] = __('橙色'),
	['6'] = __('彩色'),
}
local line = {
	['1'] = {1, 4, 5},
	['2'] = {4},
	['3'] = {4},
	['4'] = {3, 4},
	['5'] = {1},
	['9'] = {1},
	['13'] = {1}
}
local MODULE_MEDIATOR = {
    [tostring(JUMP_MODULE_DATA.TOWER)]              = { jumpView = "TowerQuestHomeMediator" },
	[tostring(JUMP_MODULE_DATA.PVC_ROYAL_BATTLE)]   = { jumpView = "PVCMediator" },
	[tostring(JUMP_MODULE_DATA.TAG_MATCH)]     		= { jumpView = "ActivityMediator", params = {activityId = ACTIVITY_ID.TAG_MATCH} },
    [tostring(JUMP_MODULE_DATA.RESTAURANT)]         = { jumpView = "AvatarMediator" },
	[tostring(JUMP_MODULE_DATA.TEAM_BATTLE_SCRIPT)] = { jumpView = "RaidHallMediator" },
	[tostring(JUMP_MODULE_DATA.PET)]                = { jumpView = "PetDevelopMediator" },
    [tostring(JUMP_MODULE_DATA.EXPLORE_SYSTEM)]     = { jumpView = "exploreSystem.ExploreSystemMediator" }
}

local RES_DICT          = {
    COMMON_LIGHT                    = _res('ui/common/common_light.png'),
    RED_IMG                         = _res('ui/common/common_ico_red_point.png'),
    FUNCTION_16                 	= _res('ui/home/levelupgrade/unlockmodule/function_16.png'),
    PRINTING_TASK_BG                = _res('ui/home/returnWelfare/printing_task_bg.png'),
    PRINTING_TASK_BG_COMPLETE       = _res('ui/home/returnWelfare/printing_task_bg_complete.png'),
    PRINTING_TASK_BG_BLACK          = _res('ui/home/returnWelfare/printing_task_bg_black.png'),
    PRINTING_ICON_FLOWER_2          = _res('ui/home/returnWelfare/printing_icon_flower_2'),
    PRINTING_BOX_NAME               = _res('ui/home/returnWelfare/printing_box_name.png'),
    PRINTING_BOX_NAME_COMPLETE      = _res('ui/home/returnWelfare/printing_box_name_complete.png'),
    PRINTING_LINE_1      			= _res('ui/home/returnWelfare/printing_line_1.png'),
    PRINTING_LINE_2      			= _res('ui/home/returnWelfare/printing_line_2.png'),
}

function ReturnWelfareBingoMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.datas = checktable(params) or {}
	local flowerAction = {}
	for i=1,16 do
		flowerAction[i] = false
	end
	self.flowerAction = flowerAction
	self.flowerEndAction = clone(flowerAction)
	self.lines = {}
	self.arrowActions = 0
	self.arrows = {} -- 连线image
end

function ReturnWelfareBingoMediator:InterestSignals()
	local signals = { 
		POST.BACK_DRAW_BINGO_TASK.sglName,
		POST.BACK_DRAW_BINGO_REWARDS.sglName,
		POST.BACK_REFRESH_BINGO_POSITION.sglName,
		'RETURN_WELFARE_BINGO_COUNT_DOWN'
	}

	return signals
end

function ReturnWelfareBingoMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
	-- 完成一个任务
	if name == POST.BACK_DRAW_BINGO_TASK.sglName then
		local data = self.datas.data
		local tag = 1
		for k,v in pairs(data.bingoTasks) do
			if tonumber(body.requestData.taskId) == tonumber(v.taskId) then
				tag = tonumber(k)
				v.hasDrawn = 1
				break
			end
		end
		local viewData = self.viewComponent.viewData
		local scrollView = viewData.scrollView
		local container = scrollView:getContainer()
		local reflect = tonumber(body.bingoPositionId)
		local flowerBingo = viewData.flowerBingo[reflect]
		local sender = viewData.flowers[tag]
		self.flowerAction[reflect] = true
		sender:setVisible(false)
		viewData.lights[tag]:setVisible(false)
		viewData.redPointImgs[tag]:setVisible(false)
		viewData.bgDarks[tag]:setVisible(true)
		flowerBingo:setVisible(true)
		local desposx, desposy = flowerBingo:getPosition()
		local frompos = viewData.view:convertToNodeSpace(container:convertToWorldSpace(cc.p(sender:getPosition())))
		flowerBingo:setPosition(frompos)
		flowerBingo:runAction(cc.Spawn:create(
			cc.RotateBy:create(2/3, 360),
			cc.Sequence:create(
				cc.ScaleTo:create(1/3, 2),
				cc.ScaleTo:create(1/3, 1),
				cc.CallFunc:create(handler(self, self.FlowerActionEnd))
			),
			cc.MoveBy:create(2/3, cc.p(desposx - frompos.x, desposy - frompos.y))
		))
	-- 领取连线宝箱
	elseif name == POST.BACK_DRAW_BINGO_REWARDS.sglName then
		uiMgr:AddDialog('common.RewardPopup', body)
		for k,v in pairs(self.datas.data.bingoRewards) do
			if tonumber(body.requestData.bingoRewardId) == tonumber(v.bingoRewardId) then
				v.hasDrawn = 1
			end
		end 
		self:CheckBoxAvailable()
	-- 刷新bingo位置
	elseif name == POST.BACK_REFRESH_BINGO_POSITION.sglName then
        CommonUtils.RefreshDiamond(body)
		local data = self.datas.data
		-- data.bingoPositions = body.bingoPositions
		self.delaybingoPositions = body.bingoPositions
		data.bingoPositions = {}
		self.position = {}
		-- for k,v in pairs(data.bingoPositions) do
		-- 	self.position[tostring(v)] = true
		-- end

		local viewData = self.viewComponent.viewData
		local flowerBingo = viewData.flowerBingo
		self.arrowActions = 0
		self:CheckBoxAvailable()
		for i=1,#self.flowerAction do
			self.flowerAction[i] = false
		end
		for i=1,#self.flowerEndAction do
			self.flowerEndAction[i] = false
		end
		for k,v in pairs(self.arrows) do
			v:runAction(cc.Sequence:create(
				cc.FadeOut:create(1/5),
				cc.RemoveSelf:create()
			))
		end
		self.arrows = {}
		local step = {
			{1},
			{2, 5},
			{3, 6, 9},
			{4, 7, 10, 13},
			{8, 11, 14},
			{12, 15},
			{16}
		}
		local line = 0
		for i,v in ipairs(step) do
			local exist = false
			for k,v2 in pairs(v) do
				if flowerBingo[v2]:isVisible() then
					exist = true
					break
				end
			end
			if exist then
				for k,v2 in pairs(v) do
					if flowerBingo[v2]:isVisible() then
						self.flowerEndAction[v2] = true
						flowerBingo[v2]:runAction(cc.Sequence:create(
							cc.DelayTime:create(line/10),
							cc.FadeOut:create(1/5),
							cc.Hide:create(),
							cc.CallFunc:create(handler(self, self.FlowerFadeOutActionEnd))
						))
					end
				end
				line = line + 1
			end
		end
	elseif name == 'RETURN_WELFARE_BINGO_COUNT_DOWN' then
		local viewData = self.viewComponent.viewData
		local data = self.datas.data
		viewData.time:setString(self:FormatTime(data.bingoRoundLeftSeconds))
    end
end

function ReturnWelfareBingoMediator:Initial( key )
	self.super.Initial(self, key)
	-- local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.returnWelfare.ReturnWelfareBingoView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
    -- scene:AddDialog(viewComponent)
    self.datas.parent:addChild(viewComponent)
	
	self.position = {}
    self:InitUI()
    self:RefreshUI()
	local viewData = viewComponent.viewData
    viewData.boxLayer1:setOnClickScriptHandler(handler(self, self.BoxBtnClickHandler))
    viewData.boxLayer2:setOnClickScriptHandler(handler(self, self.BoxBtnClickHandler))
    viewData.boxLayer3:setOnClickScriptHandler(handler(self, self.BoxBtnClickHandler))
    viewData.suppleBtn:setOnClickScriptHandler(handler(self, self.SuppleBtnClickHandler))
end

function ReturnWelfareBingoMediator:InitUI(  )
    local viewData = self.viewComponent.viewData
	local scrollView = viewData.scrollView
	local container = scrollView:getContainer()
	local height = 91

	local data = self.datas.data
	for k,v in pairs(data.bingoTasks) do
		v.descr = string.gsub(v.descr, '_target_num_', '|_target_num_|')
		v.descr = string.gsub(v.descr, '_target_id_', '|_target_id_|')
	end
	local num = table.nums(data.bingoTasks)
	scrollView:setContainerSize(cc.size(440, height * num))
	scrollView:setContentOffsetToTop()
	local bgs = {}
	for i=1,num do
		local bg = display.newNSprite(RES_DICT.PRINTING_TASK_BG, 220, (num-i) * height,
		{
			ap = display.CENTER_BOTTOM,
		})
		container:addChild(bg)
		bgs[i] = bg
	end
	local bgDarks = {}
	for i=1,num do
		local bgDark = display.newNSprite(RES_DICT.PRINTING_TASK_BG_BLACK, 220, (num-i) * height,
		{
			ap = display.CENTER_BOTTOM,
		})
		container:addChild(bgDark)
		bgDarks[i] = bgDark
	end
	local lights = {}
	for i=1,num do
		local light = display.newNSprite(RES_DICT.COMMON_LIGHT, 374, (num-i) * height + 62,
		{
			ap = display.CENTER,
		})
		light:setScale(0.14)
		container:addChild(light)
		lights[i] = light
	end
	local flowers = {}
	for i=1,num do
		local flower = display.newButton(374, (num-i) * height + 62,
		{
			ap = display.CENTER,
			n = RES_DICT.PRINTING_ICON_FLOWER_2,
		})
		container:addChild(flower)
		flower:setOnClickScriptHandler(handler(self, self.DrawBtnClickHandler))
		flowers[i] = flower
	end
	local greyflowers = {}
	local grayFilter = GrayFilter:create()
	for i=1,num do
		local greyflower = FilteredSpriteWithOne:create()
		greyflower:setTexture(RES_DICT.PRINTING_ICON_FLOWER_2)
		greyflower:setPosition(cc.p(374, (num-i) * height + 62))
		greyflower:setFilter(grayFilter)
		greyflower:setOpacity(130)
		container:addChild(greyflower)
		greyflower:setVisible(false)
		greyflowers[i] = greyflower
	end
	local progressLabels = {}
	local taskLabels = {}
	for i=1,num do
		local progressLabel = display.newLabel(374, (num-i) * height + 20,
		{
			text = '',
			ap = display.CENTER,
			fontSize = 22,
			color = '#ec2929',
		})
		container:addChild(progressLabel)
		progressLabels[i] = progressLabel

		local taskLabel = display.newLabel(32, (num-i) * height + 43,
		{
			fontSize = 20 ,
			color = "#5c5c5c",
			ap = display.LEFT_CENTER,
		})
		container:addChild(taskLabel)
		taskLabels[i] = taskLabel
	end
	local redPointImgs = {}
	for i=1,num do
        local redPointImg = display.newImageView(RES_DICT.RED_IMG, 420, (num-i) * height + 70)
        redPointImg:setVisible(false)
        container:addChild(redPointImg)
		redPointImgs[i] = redPointImg
	end
	viewData.bgs = bgs
	viewData.bgDarks = bgDarks
	viewData.lights = lights
	viewData.flowers = flowers
	viewData.greyflowers = greyflowers
	viewData.progressLabels = progressLabels
	viewData.taskLabels = taskLabels
	viewData.redPointImgs = redPointImgs

	local functionLayer = viewData.functionLayer
	local functionId = string.split(CommonUtils.GetConfigAllMess('rule', 'back').functionId, ';')
	local moduleConfig = CommonUtils.GetConfigAllMess('module')
	local count = 1
	for k,v in ipairs(functionId) do
		local moduleOneConfig = moduleConfig[v]
		if moduleOneConfig then
			local name  = moduleOneConfig.name
			local iconId = moduleOneConfig.iconID
			local functionLayout = self:CreateFunctionLayout()
			local viewData = functionLayout.viewData
			viewData.functionImage:setTexture(_res( string.format('ui/home/levelupgrade/unlockmodule/%s', iconId) ))
			display.commonUIParams(viewData.functionImage , { animate = false,cb = handler(self, self.ModuleCallBack)})
			viewData.functionImage:setTag(checkint(v))
			viewData.functionImage:setScale(0.8)
			display.commonLabelParams(viewData.functionLabel, {text = name})
			functionLayer:insertNodeAtLast(functionLayout)
			count = count + 1
		end
	end
	functionLayer:reloadData()
	self.lines = self:CheckBoxComplete()
end

function ReturnWelfareBingoMediator:CreateFunctionLayout()
    local functionLayout = display.newLayer(4, 198,
                                    { ap = display.CENTER , size = cc.size(160, 140)})
    local functionImage = display.newImageView(RES_DICT.FUNCTION_16, 76, 74,
                                     { ap = display.CENTER, tag = 882 , enable = true  })
    functionImage:setScale(1, 1)
    functionLayout:addChild(functionImage)

    local functionLabel = display.newLabel(75, 18,
                                   fontWithColor('14', { ap = display.CENTER, outline = '#222323', ttf = true, font = TTF_GAME_FONT, color = '#ffffff', w = 150 , hAlign = display.TAC ,  fontSize = 24, text = "", tag = 883 }))
    functionLayout:addChild(functionLabel)
    functionLayout.viewData = {
        functionLayout = functionLayout,
        functionImage  = functionImage,
        functionLabel  = functionLabel
    }
    return functionLayout
end

function ReturnWelfareBingoMediator:RefreshUI(  )
	local viewData = self.viewComponent.viewData
	local scrollView = viewData.scrollView
	local flowerBingo = viewData.flowerBingo

	local data = self.datas.data
	viewData.time:setString(self:FormatTime(data.bingoRoundLeftSeconds))
	
	for k,v in pairs(self.arrows) do
		v:stopProgress()
		v:removeFromParent()
	end
	for k,v in pairs(flowerBingo) do
		v:stopAllActions()
		v:setOpacity(255)
		v:setScale(1)
		v:setVisible(false)
	end
	for i=1,#self.flowerAction do
		self.flowerAction[i] = false
	end
	for i=1,#self.flowerEndAction do
		self.flowerEndAction[i] = false
	end
	self.arrows = {}
	self.position = {}
	for k,v in pairs(data.bingoPositions) do
		self.position[tostring(v)] = true
	end
	self.arrowActions = 0
	self:SortTask()
	for i,v in ipairs(data.bingoTasks) do
		viewData.flowers[i]:setTag(checkint(v.taskId))
		local descr = string.split(v.descr, '|')
		local textRich = {}
		for k,value in pairs(descr) do
			if '_target_num_' == value then
				table.insert( textRich, v.targetNum)
			elseif '_target_id_' == value then
				table.insert( textRich,  qualityDefine[tostring(v.targetId)])
			elseif '' ~= value then
				table.insert( textRich, value)
			end
		end
		display.commonLabelParams(viewData.taskLabels[i], {text  = table.concat(textRich , "") , w = 280})
		local progress = checkint(v.progress)
		if checkint(v.progress) > checkint(v.targetNum) then
			progress = checkint(v.targetNum)
		end
		if 2 ~= v.state then
			display.commonLabelParams(viewData.progressLabels[i], {text = string.format(__('(%d/%d)'), progress, v.targetNum), fontSize = 22, color = '#7e2b1a'})
		else
			display.commonLabelParams(viewData.progressLabels[i], {text = string.format(__('(%d/%d)'), progress, v.targetNum), fontSize = 22, color = '#ec2929'})
		end
		if 2 == v.state then
			viewData.lights[i]:setVisible(true)
			viewData.flowers[i]:setVisible(true)
			viewData.bgs[i]:setTexture(RES_DICT.PRINTING_TASK_BG_COMPLETE)
			viewData.redPointImgs[i]:setVisible(true)
		else
			viewData.lights[i]:setVisible(false)
			viewData.flowers[i]:setVisible(false)
			viewData.bgs[i]:setTexture(RES_DICT.PRINTING_TASK_BG)
			viewData.redPointImgs[i]:setVisible(false)
		end
		if 1 == v.state then
			viewData.greyflowers[i]:setVisible(true)
		else
			viewData.greyflowers[i]:setVisible(false)
		end
		if 0 == v.state then
			viewData.bgDarks[i]:setVisible(true)
		else
			viewData.bgDarks[i]:setVisible(false)
		end
	end
	for k,v in pairs(data.bingoPositions) do
		flowerBingo[tonumber(v)]:setVisible(true)
	end

	viewData.costLabel:setString(data.bingoRefreshConsumeNum)
	display.setNodesToNodeOnCenter(viewData.suppleBtn, {viewData.costLabel, viewData.costIcon})

	self:CheckBoxAvailable()
	self:ShowArrowAni({}, self:CheckBoxComplete())
end

function ReturnWelfareBingoMediator:SetSuppleVisible()
	local data = self.datas.data
	local viewData = self.viewComponent.viewData
	local count = 0
	for i,v in ipairs(data.bingoTasks) do
		if 1 == checkint(v.hasDrawn) and checkint(v.progress) >= checkint(v.targetNum) then
			count = count + 1
		end
	end
	if 10 > count then
		viewData.suppleLabel:setVisible(false)
		viewData.suppleBtn:setVisible(false)
		viewData.tipsLabel:setVisible(true)
	else
		viewData.suppleLabel:setVisible(true)
		viewData.suppleBtn:setVisible(true)
		viewData.tipsLabel:setVisible(false)
	end
	app:DispatchObservers('EVENT_HOME_RED_POINT')
end

function ReturnWelfareBingoMediator:ResetMdt( data )
    self.datas.data = checktable(data) or {}
	for k,v in pairs(data.bingoTasks) do
		v.descr = string.gsub(v.descr, '_target_num_', '|_target_num_|')
		v.descr = string.gsub(v.descr, '_target_id_', '|_target_id_|')
	end
    self:RefreshUI()
end

function ReturnWelfareBingoMediator:CheckBoxComplete(  )
	local lines = {}
	local position = self.position
	for k,v in pairs(line) do
		if position[tostring(k)] then
			for _,child in pairs(v) do
				if position[tostring(k + child)] and position[tostring(k + child * 2)] and position[tostring(k + child * 3)] then
					table.insert( lines, {k, child} )
				end
			end
		end
	end
	return lines
end

function ReturnWelfareBingoMediator:SortTask(  )
	local data = self.datas.data
	local bingoTasks = data.bingoTasks
	for k,v in pairs(bingoTasks) do
		v.state = 1 -- 未完成
		if checkint(v.progress) >= checkint(v.targetNum) then
			v.state = 2 -- 可领取
		end
		if 1 == checkint(v.hasDrawn) then
			v.state = 0 -- 已完成
		end
		if not CommonUtils.UnLockModule(v.functionId, false) then
			v.state = 0 -- 不可完成
		end
	end
	table.sort(bingoTasks, function ( a, b )
        if a.state ~= b.state then
            return a.state > b.state
        end
        return checkint(a.taskId) < checkint(b.taskId)
	end)
end

function ReturnWelfareBingoMediator:DrawBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	self:SendSignal(POST.BACK_DRAW_BINGO_TASK.cmdName, {taskId = tag})
end

function ReturnWelfareBingoMediator:FlowerActionEnd( sender )
	local pos = sender:getTag()
	if not self.flowerAction[pos] then
		return
	end
	local lines = self:CheckBoxComplete()
	self.flowerAction[pos] = false
	table.insert(self.datas.data.bingoPositions, pos)
	self.position[tostring(pos)] = true
	local lines2 = self:CheckBoxComplete()
	self:ShowArrowAni(lines, lines2)
end

function ReturnWelfareBingoMediator:ShowArrowAni(lines, lines2)
	local newLines = {}
	if table.nums(lines) < table.nums(lines2) then
		for _,v in pairs(lines2) do
			local isExist = false
			for _,pv in pairs(lines) do
				if v[1] == pv[1] and v[2] == pv[2] then
					isExist = true
					break
				end
			end
			if not isExist then
				table.insert( newLines, v )
			end
		end
	end
	for k,v in pairs(newLines) do
		local arrow
		local viewData = self.viewComponent.viewData
		local posx, posy = viewData.flowerBingo[tonumber(v[1])]:getPosition()
		if tonumber(v[2]) == 1 then
			arrow = CProgressBar:create(RES_DICT.PRINTING_LINE_1)
			arrow:setDirection(eProgressBarDirectionTopToBottom)
			arrow:setRotation(-90)
			arrow:setAnchorPoint(cc.p(0.5, 1))
		elseif tonumber(v[2]) == 4 then
			arrow = CProgressBar:create(RES_DICT.PRINTING_LINE_1)
			arrow:setDirection(eProgressBarDirectionTopToBottom)
			arrow:setAnchorPoint(cc.p(0.5, 1))
		elseif tonumber(v[2]) == 3 then
			arrow = CProgressBar:create(RES_DICT.PRINTING_LINE_2)
			arrow:setDirection(eProgressBarDirectionTopToBottom)
			arrow:setAnchorPoint(cc.p(1, 1))
		elseif tonumber(v[2]) == 5 then
			arrow = CProgressBar:create(RES_DICT.PRINTING_LINE_2)
			arrow:setDirection(eProgressBarDirectionTopToBottom)
			arrow:setRotation(-90)
			arrow:setAnchorPoint(cc.p(1, 1))
		end
		if arrow then
			self.arrowActions = self.arrowActions + 1
			table.insert( self.arrows, arrow )
			arrow:setMaxValue(100)
			arrow:setValue(0)
			arrow:setPosition(posx, posy)
			viewData.view:addChild(arrow, 5)
			arrow:startProgress(100, 1/10)
			arrow:setOnProgressEndedScriptHandler(handler(self, self.CheckBoxAvailable))
		end
	end
	if 0 == table.nums(newLines) then
		self:SetSuppleVisible()
	end
end

function ReturnWelfareBingoMediator:CheckBoxAvailable( sender )
	if sender then
		self.arrowActions = self.arrowActions - 1
	end
	local viewData = self.viewComponent.viewData
	local data = self.datas.data
	local lines = self:CheckBoxComplete()
	for i,v in ipairs(data.bingoRewards) do
		if 1 == checkint(v.hasDrawn) then
			viewData.box[i]:setFilter(GrayFilter:create())
			viewData.complete[i]:setVisible(true)
		else
			viewData.box[i]:clearFilter()
			viewData.complete[i]:setVisible(false)
		end
		if 0 == checkint(v.hasDrawn) and i <= table.nums(lines) then
			viewData.boxLight[i]:setVisible(true)
			viewData.boxDesr[i]:setNormalImage(RES_DICT.PRINTING_BOX_NAME_COMPLETE)
			display.commonLabelParams(viewData.boxDesr[i], fontWithColor(10, {text = string.format( __('%d条线'), i )}))
			viewData.box[i].redPointImg:setVisible(true)
		else
			viewData.boxLight[i]:setVisible(false)
			viewData.boxDesr[i]:setNormalImage(RES_DICT.PRINTING_BOX_NAME)
			display.commonLabelParams(viewData.boxDesr[i], {text = string.format( __('%d条线'), i ), fontSize = 20, color = '#ffffff'})
			viewData.box[i].redPointImg:setVisible(false)
		end
	end
	self:SetSuppleVisible()
end

function ReturnWelfareBingoMediator:CheckInAni(  )
	for k,v in pairs(self.flowerAction) do
		if v then
			return true
		end
	end
	for k,v in pairs(self.flowerEndAction) do
		if v then
			return true
		end
	end
	return self.arrowActions > 0
end

function ReturnWelfareBingoMediator:SuppleBtnClickHandler(sender)
	PlayAudioByClickNormal()
	if self:CheckInAni() then
		return
	end
	local tag = sender:getTag()
	local data = self.datas.data
	if 0 == table.nums(data.bingoPositions) then
		uiMgr:ShowInformationTips(__('尚未添加印花'))
	elseif CommonUtils.GetCacheProductNum(DIAMOND_ID) < checkint(data.bingoRefreshConsumeNum) then
		uiMgr:ShowInformationTips(__('幻晶石不足'))
	else
		self:SendSignal(POST.BACK_REFRESH_BINGO_POSITION.cmdName)
	end
end

function ReturnWelfareBingoMediator:FlowerFadeOutActionEnd( sender )
	local pos = sender:getTag()
	self.flowerEndAction[pos] = false
	local viewData = self.viewComponent.viewData
	local flowerBingo = viewData.flowerBingo
	local allEnd = true
	for k,v in pairs(self.flowerEndAction) do
		if v then
			allEnd = false
			break
		end
	end
	if allEnd then
		local bingoPositions = self.delaybingoPositions
		table.sort(bingoPositions)
		for i,v in ipairs(bingoPositions) do
			self.flowerAction[v] = true
			flowerBingo[v]:setOpacity(0)
			flowerBingo[v]:setScale(0.5)
			flowerBingo[v]:runAction(cc.Sequence:create(
				cc.DelayTime:create((i-1)/10),
				cc.Show:create(),
				cc.Spawn:create(
					cc.FadeIn:create(1/5),
					cc.ScaleTo:create(1/5, 1.5)
				),
				cc.ScaleTo:create(1/10, 1),
				cc.CallFunc:create(handler(self, self.FlowerActionEnd))
			))
		end
		for k,v in pairs(self.flowerAction) do
			if not v then
				flowerBingo[k]:setOpacity(255)
			end
		end
	end
end

function ReturnWelfareBingoMediator:BoxBtnClickHandler(sender)
	PlayAudioByClickNormal()
	if self:CheckInAni() then
		return
	end
	local tag = sender:getTag()

	local data = self.datas.data
	local bingoRewards = data.bingoRewards[tag]
	local lines = self:CheckBoxComplete()
	if tag <= table.nums(lines) and 0 == checkint(bingoRewards.hasDrawn) then
		self:SendSignal(POST.BACK_DRAW_BINGO_REWARDS.cmdName, {bingoRewardId = bingoRewards.bingoRewardId})
	else
		local layer = require('common.RewardDetailPopup').new({tag = 5001, rewards = bingoRewards.rewards})
		display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		layer:setTag(5001)
		uiMgr:GetCurrentScene():AddDialog(layer)
	end
end

function ReturnWelfareBingoMediator:ModuleCallBack(sender )
    if self.isGoto then
        return
    end
    local openType = sender:getTag()
    if CommonUtils.UnLockModule(openType,true) then
        local jumpView = MODULE_MEDIATOR[tostring(openType)].jumpView
        local params = MODULE_MEDIATOR[tostring(openType)].params or {}
        if jumpView then
            sceneWorld:runAction(
                    cc.Sequence:create(
                        cc.CallFunc:create(function()
                                self.isGoto = true
                        end),
                        cc.DelayTime:create(2) ,
                        cc.CallFunc:create(function()
                            self.isGoto = false
                        end)
                    )
            )
            if jumpView == "HomeMediator" then
                app:BackHomeMediator()
            elseif jumpView == "MapMediator" then
                self:ShowEnterStageView(taskConfigData.targetId)
            elseif jumpView == "RecipeResearchAndMakingMediator" then
                app:BackHomeMediator()
                local router = app:RetrieveMediator('Router')
                router:Dispatch({}, {name = jumpView})
            else
                ---@type Router
                local router = app:RetrieveMediator('Router')
                router:Dispatch({}, {name = jumpView , params = params } )
            end
        end
    end
end

function ReturnWelfareBingoMediator:FormatTime(countdown)
    if checkint(countdown) <= 0 then
        return __('已结束')
    else
        if checkint(countdown) <= 86400 then
            return string.formattedTime(checkint(countdown), '%02i:%02i:%02i')
        else
            local day  = math.floor(checkint(countdown) / 86400)
            local hour = math.floor((countdown - day * 86400) / 3600)
            return string.fmt(__('_day_天_hour_小时'), { _day_ = day, _hour_ = hour })
        end
    end
end

function ReturnWelfareBingoMediator:OnRegist(  )
	regPost(POST.BACK_DRAW_BINGO_TASK)
	regPost(POST.BACK_DRAW_BINGO_REWARDS)
	regPost(POST.BACK_REFRESH_BINGO_POSITION)
end

function ReturnWelfareBingoMediator:OnUnRegist(  )
	unregPost(POST.BACK_DRAW_BINGO_TASK)
	unregPost(POST.BACK_DRAW_BINGO_REWARDS)
	unregPost(POST.BACK_REFRESH_BINGO_POSITION)
	-- local scene = uiMgr:GetCurrentScene()
	-- scene:RemoveGameLayer(self.viewComponent)
end

return ReturnWelfareBingoMediator