--[[
新天成演武-战报

--]]
local CommonDialog = require('common.CommonDialog')
local NewKofArenaReportView = class('NewKofArenaReportView', CommonDialog)

local CellInfo = {
	Win = {
		bgPath = 'ui/pvc/rob_record_bg_defeat_list.png',
		winIconPath = 'ui/pvc/settlement_bg_words_1.png',
		scoreBgPath = 'ui/pvc/3v3_report_bg_light.png',
		typeLabelColor = '#ba5c5c',
		scoreTitle = __('获得'),
		scoreTitleColor = '#d86e24',
		arithmeticStr = '+',
	},
	Lose = {
		bgPath = 'ui/pvc/rob_record_bg_victory_list.png',
		winIconPath = 'ui/pvc/settlement_bg_words_fail_2.png',
		scoreBgPath = 'ui/pvc/3v3_report_bg_grey.png',
		typeLabelColor = '#5570a7',
		scoreTitle = __('失去'),
		scoreTitleColor = '#7d7c7c',
		arithmeticStr = '-',
	}
}

--[[
override
initui
--]]
function NewKofArenaReportView:InitialUI()
	self.winTimes = self.args.winTimes
	self.loseTimes = self.args.loseTimes
	self.reportData = self.args.reportData
	self.viewType  = checkint(self.args.viewType)
	self.headDefaultCallback = checkbool(self.args.headDefaultCallback)
	self.enableCellCallback = checkbool(self.args.enableCellCallback)
	self.winRate = 0
	if self.winTimes + self.loseTimes > 0 then
		self.winRate = math.floor(self.winTimes / (self.winTimes + self.loseTimes) * 100)
	end

	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_3.png'), 0, 0)
		local size = bg:getContentSize()

		-- base view
		local view = display.newLayer(0, 0, {size = size, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		view:addChild(bg, 1)

		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(size.width * 0.5, size.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg, fontWithColor('14', {text = __('战报'), offset = cc.p(0, -2)}))
        titleBg:setEnabled(false)
		bg:addChild(titleBg)

		-- 战斗背景
		local battleRecordBg = display.newImageView(_res('ui/pvc/friends_bg_message_visitor_number.png'), 0, 0)
		view:addChild(battleRecordBg, 5)

		local totalBattleTimesLabel = display.newLabel(0, 0,
			{text = string.fmt(__('总场次: _num_'), {_num_ = checkint(self.winTimes + self.loseTimes)}), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
		display.commonUIParams(totalBattleTimesLabel, {po = cc.p(
			10,
			battleRecordBg:getContentSize().height * 0.5
		)})
		battleRecordBg:addChild(totalBattleTimesLabel)

		local totalBattleLoseTimesLabel = display.newLabel(0, 0,
			{text = string.fmt(__('胜率: _num_%'), {_num_ = checkint(self.winRate)}), fontSize = 22, color = '#ffffff', reqW = 150, ap = cc.p(0, 0.5)})
		display.commonUIParams(totalBattleLoseTimesLabel, {po = cc.p(
			battleRecordBg:getContentSize().width * 0.6,
			battleRecordBg:getContentSize().height * 0.5
		)})
		battleRecordBg:addChild(totalBattleLoseTimesLabel)

		-- 排行榜按钮
		local rankBtn = display.newButton(0, 0, {
			n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
			cb = handler(self, self.RankingClickHandler)
		})
		view:addChild(rankBtn, 5)
		display.commonLabelParams(rankBtn, fontWithColor('14', {text = __('排行榜')}))

		display.setNodesToNodeOnCenter(view, {battleRecordBg, rankBtn}, {spaceW = 10, y = view:getContentSize().height - 75})

		local listViewSize = cc.size(size.width - 40, size.height - 110)
		local cellSize = cc.size(listViewSize.width, 125)

		local listView = CTableView:create(listViewSize)
		display.commonUIParams(listView, {ap = cc.p(0.5, 1), po = cc.p(
			size.width * 0.5,
			battleRecordBg:getPositionY() - battleRecordBg:getContentSize().height * 0.5 - 5
		)})
		view:addChild(listView, 10)

		listView:setSizeOfCell(cellSize)
		listView:setCountOfCell(#self.reportData)
		listView:setDirection(eScrollViewDirectionVertical)
		listView:setDataSourceAdapterScriptHandler(handler(self, self.ReportListViewDataAdapter))

		-- 空状态
		local emptyGodScale = 0.75
		local petEggEmptyGod = AssetsUtils.GetCartoonNode(3, size.width * 0.5, size.height * 0.45)
		petEggEmptyGod:setScale(emptyGodScale)
		bg:addChild(petEggEmptyGod)

		local petEggEmptyLabel = display.newLabel(
			petEggEmptyGod:getPositionX(),
			petEggEmptyGod:getPositionY() - 424 * 0.5 * emptyGodScale - 40,
			fontWithColor('14', {text = __('还没有战报')}))
		bg:addChild(petEggEmptyLabel)

		petEggEmptyGod:setVisible(0 == #self.reportData)
		petEggEmptyLabel:setVisible(0 == #self.reportData)

		return {
			view = view,
			listView = listView
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	self.viewData.listView:reloadData()
end
---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
data adapter
--]]
function NewKofArenaReportView:ReportListViewDataAdapter(c, i)
	local cell = c
	local index = i + 1
	local reportData = self.reportData[index]

	xTry(function()
		if nil == cell then
			cell = self:InitAReportCellByReportData(reportData)
		else
			self:RefreshAReportCell(cell, index)
		end
	end, function()
		__G__TRACKBACK__(debug.traceback())
		if nil == cell then
			cell = CTableViewCell:new()
			cell:setContentSize(self.viewData.listView:getSizeOfCell())
		end
	end)

	cell:setTag(index)

	return cell
end
--[[
根据战报信息创建一个cell
@params reportData table 单条战报信息
--]]
function NewKofArenaReportView:InitAReportCellByReportData(reportData)
	local cellSize = self.viewData.listView:getSizeOfCell()
	local cell = CTableViewCell:new()
	cell:setContentSize(cellSize)

	local cellInfo = CellInfo['Lose']
	if 1 == checkint(reportData.isPassed) then
		cellInfo = CellInfo['Win']
	end

	if checkint(reportData.integral) == 0 then 
		cellInfo.arithmeticStr = ''
	end

	local bg = display.newImageView(_res(cellInfo.bgPath), 0, 0)
	display.commonUIParams(bg, {po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5)})
	cell:addChild(bg)

	local touchView = display.newLayer(0, 0, {size = bg:getContentSize(), enable = self.enableCellCallback, color = cc.c4b(0, 0, 0, 0)})
	display.commonUIParams(touchView, {po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5), ap = display.CENTER, cb = handler(self, self.onCellClickHandler)})
	cell:addChild(touchView)

	local splitLine = display.newNSprite(_res('ui/pvc/pvp_report_ico_line.png'), 0, 0)
	display.commonUIParams(splitLine, {po = cc.p(80, cellSize.height * 0.5)})
	cell:addChild(splitLine)

	local resultX = splitLine:getPositionX() - 35
	local winIcon = display.newNSprite(_res(cellInfo.winIconPath), 0, 0)
	display.commonUIParams(winIcon, {po = cc.p(
		resultX,
		cellSize.height * 0.5 - 10
	)})
	cell:addChild(winIcon)


    local scoreBg = display.newImageView(_res(cellInfo.scoreBgPath), 0, 0,{ap = display.RIGHT_CENTER})
	display.commonUIParams(scoreBg, {po = cc.p(cellSize.width -20, cellSize.height * 0.5)})
	cell:addChild(scoreBg)

    local scoreTitleLabel = display.newLabel(0, 0, {text = cellInfo.scoreTitle, fontSize = 24, color = cellInfo.scoreTitleColor,ap = display.CENTER})
	display.commonUIParams(scoreTitleLabel, {po = cc.p(
		cellSize.width - 100,
		cellSize.height/2 + 24
	)})
	cell:addChild(scoreTitleLabel)

    local score = string.fmt(__("_symbol__num_ 积分"),{_symbol_ = cellInfo.arithmeticStr, _num_ = reportData.integral})
    local params = {text = score, ap = display.CENTER, fontSize = 24, color = '#873b12', font = TTF_TEXT_FONT, ttf = true}
    local scoreLabel = display.newLabel(0, 0, params)
	display.commonUIParams(scoreLabel, {po = cc.p(
		cellSize.width - 100,
		cellSize.height/2 - 24
	)})
	cell:addChild(scoreLabel)
    
	local typeStr = __('进攻')
	if 2 == checkint(reportData.type) then
		typeStr = __('防守')
	end
	local typeLabel = display.newLabel(0, 0, {text = typeStr, fontSize = 22, color = cellInfo.typeLabelColor})
	display.commonUIParams(typeLabel, {po = cc.p(
		resultX,
		cellSize.height - 25
	)})
	cell:addChild(typeLabel)

	local playerHeadScale = 0.65
	local playerHeadNode = require('common.PlayerHeadNode').new({
		avatar = reportData.opponent.avatar,
		avatarFrame = reportData.opponent.avatarFrame,
		showLevel = true,
		playerLevel = reportData.opponent.level,
		id = reportData.opponent.id,
		defaultCallback = self.headDefaultCallback,
	})
	playerHeadNode:setScale(playerHeadScale)
	playerHeadNode:setPosition(cc.p(
		splitLine:getPositionX() + 10 + playerHeadNode:getPositionX() + playerHeadNode:getContentSize().width * 0.5 * playerHeadScale,
		cellSize.height * 0.5
	))
	cell:addChild(playerHeadNode)

	local playerNameLabel = display.newLabel(0, 0, fontWithColor('11', {text = tostring(reportData.opponent.name)}))
	display.commonUIParams(playerNameLabel, {ap = cc.p(0, 0), po = cc.p(
		playerHeadNode:getPositionX() + playerHeadNode:getContentSize().width * 0.5 * playerHeadScale + 2,
		cellSize.height - 45
	)})
	cell:addChild(playerNameLabel)

	local battleTimeLabel = display.newLabel(0, 0, fontWithColor('15', {text = self:GetFixedTimeStr(reportData.createTime)}))
	display.commonUIParams(battleTimeLabel, {ap = cc.p(0, 1), po = cc.p(
		playerNameLabel:getPositionX(),
		playerNameLabel:getPositionY() - 2
	)})
	cell:addChild(battleTimeLabel)


	--- 需要刷新的组件
	self.refreshComponent = {
		bg              = bg,
		winIcon         = winIcon,  
		scoreBg         = scoreBg,
		scoreTitleLabel = scoreTitleLabel,
		scoreLabel      = scoreLabel,
		typeLabel       = typeLabel,
		playerHeadNode  = playerHeadNode,
		playerNameLabel = playerNameLabel,
		battleTimeLabel = battleTimeLabel,
	}

	for k, v in pairs(self.refreshComponent) do
		v:setName(k)
	end
	return cell
end


--[[
刷新一个cell
--]]
function NewKofArenaReportView:RefreshAReportCell(cell, index)
	local reportData = self.reportData[index]

	local cellInfo = CellInfo['Lose']
	if 1 == checkint(reportData.isPassed) then
		cellInfo = CellInfo['Win']
	end

	local bg = cell:getChildByName('bg')
	if bg then
		bg:setTexture(_res(cellInfo.bgPath))
	end
	
	local winIcon = cell:getChildByName('winIcon')
	if winIcon then
		winIcon:setTexture(_res(cellInfo.winIconPath))
	end

	local scoreBg = cell:getChildByName('scoreBg')
	if scoreBg then
		scoreBg:setTexture(_res(cellInfo.scoreBgPath))
	end

	local scoreTitleLabel = cell:getChildByName('scoreTitleLabel')
	if scoreTitleLabel then
		display.commonLabelParams(scoreTitleLabel, {text = cellInfo.scoreTitle})
	end
	if checkint(reportData.integral) == 0 then 
		cellInfo.arithmeticStr = ''
	end

	local scoreLabel = cell:getChildByName('scoreLabel')
	if scoreLabel then
		local score = string.format(__("%s%s 积分"),cellInfo.arithmeticStr,reportData.integral)
		display.commonLabelParams(scoreLabel, {text = score})
	end

	local typeStr = __('进攻')
	if 2 == checkint(reportData.type) then
		typeStr = __('防守')
	end
	local typeLabel = cell:getChildByName('typeLabel')
	if typeLabel then
		typeLabel:setString(typeStr)
		typeLabel:setColor(ccc4FromInt(cellInfo.typeLabelColor))
	end

	local playerHeadNode = cell:getChildByName('playerHeadNode')
	if playerHeadNode then
		playerHeadNode:RefreshUI({
			id = reportData.opponent.id,
			avatar = reportData.opponent.avatar,
			avatarFrame = reportData.opponent.avatarFrame,
			playerLevel = reportData.opponent.level,
			defaultCallback = self.headDefaultCallback,
		})
	end

	local playerNameLabel = cell:getChildByName("playerNameLabel")
	if playerNameLabel then
		playerNameLabel:setString(tostring(reportData.opponent.name))
	end

	local battleTimeLabel = cell:getChildByName("battleTimeLabel")
	if battleTimeLabel then
		battleTimeLabel:setString(self:GetFixedTimeStr(reportData.createTime))
	end

end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据时间获取修正时间
@params time string 时间 2017-10-10 16:26:03
@return str string 时间字符串
--]]
function NewKofArenaReportView:GetFixedTimeStr(time)
	local str = ''
	local ymd = string.split(string.split(time, ' ')[1], '-')
	local hms = string.split(string.split(time, ' ')[2], ':')
	local currentTimeStamp = os.time()
	local targetTimeStamp = os.time({
		year = ymd[1],
		month = ymd[2],
		day = ymd[3],
		hour = hms[1],
		min = hms[2],
		sec = hms[3]
	})

	local deltaTime = math.max(0, currentTimeStamp - targetTimeStamp)

	if 60 > deltaTime then
		str = __('刚刚')
	elseif 3600 > deltaTime then
		local m = math.floor(deltaTime / 60)
		str = string.fmt(__('_num_分钟前'), {_num_ = checkint(m)})
	elseif 3600 <= deltaTime and 3600 * 24 > deltaTime then
		local h = math.floor(deltaTime / 3600)
		str = string.fmt(__('_num_小时前'), {_num_ = checkint(h)})
	elseif 3600 * 24 <= deltaTime then
		local d = math.floor(deltaTime / (3600 * 24))
		str = string.fmt(__('_num_天前'), {_num_ = checkint(d)})
	end
	return str
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- btn click handler begin --
---------------------------------------------------
--[[
排行榜按钮回调
--]]
function NewKofArenaReportView:RankingClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('SHOW_PVC_RANK')
end

function NewKofArenaReportView:onCellClickHandler(sender)
	PlayAudioByClickNormal()
	local cell = sender:getParent()
	local index = cell:getTag()
	local reportData = self.reportData[index]
	AppFacade.GetInstance():DispatchObservers('CLICK_PVC_REPORT_VIEW_CELL', {data = reportData, cell = cell})
end
---------------------------------------------------
-- btn click handler end --
---------------------------------------------------

return NewKofArenaReportView
