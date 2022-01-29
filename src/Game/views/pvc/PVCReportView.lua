--[[
竞技场记录页面
@params {
	reportData list 战报信息
	winTimes int 战胜次数
	loseTimes int 战败次数
	viewType   int 视图类型
	headDefaultCallback 控制是否开启头像点击回调 (对手数据中 要有玩家id)
	enableCellCallback  控制是否启用cell 点击回调
}
--]]
local CommonDialog = require('common.CommonDialog')
local PVCReportView = class('PVCReportView', CommonDialog)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
override
initui
--]]
function PVCReportView:InitialUI()
	self.winTimes = self.args.winTimes
	self.loseTimes = self.args.loseTimes
	self.reportData = self.args.reportData
	self.viewType  = checkint(self.args.viewType)
	self.headDefaultCallback = checkbool(self.args.headDefaultCallback)
	self.enableCellCallback = checkbool(self.args.enableCellCallback)
	-- dump(self.reportData, '22reportDatareportData')
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
			{text = string.format(__('总场次: %d'), checkint(self.winTimes + self.loseTimes)), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
		display.commonUIParams(totalBattleTimesLabel, {po = cc.p(
			10,
			battleRecordBg:getContentSize().height * 0.5
		)})
		battleRecordBg:addChild(totalBattleTimesLabel)

		local totalBattleLoseTimesLabel = display.newLabel(0, 0,
			{text = string.format(__('胜率: %d%%'), checkint(self.winRate)), fontSize = 22, color = '#ffffff', reqW = 150, ap = cc.p(0, 0.5)})
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
		display.commonLabelParams(rankBtn, fontWithColor('14', {text = __('排行榜') , reqW = 115}))

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

		-- listView:setBackgroundColor(cc.c4b(255, 128, 128, 100))

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
function PVCReportView:ReportListViewDataAdapter(c, i)
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
function PVCReportView:InitAReportCellByReportData(reportData)
	local cellSize = self.viewData.listView:getSizeOfCell()
	local cell = CTableViewCell:new()
	cell:setContentSize(cellSize)

	-- 背景
	local bgPath = 'ui/pvc/rob_record_bg_victory_list.png'
	local winIconPath = 'ui/pvc/pvp_report_ico_victory.png'
	local typeLabelColor = '#5570a7'
	if 0 == checkint(reportData.isPassed) then
		bgPath = 'ui/pvc/rob_record_bg_defeat_list.png'
		winIconPath = 'ui/pvc/pvp_report_ico_defeat.png'
		typeLabelColor = '#ba5c5c'
	end

	local bg = display.newImageView(_res(bgPath), 0, 0)
	display.commonUIParams(bg, {po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5)})
	cell:addChild(bg)

	local touchView = display.newLayer(0, 0, {size = bg:getContentSize(), enable = self.enableCellCallback, color = cc.c4b(0, 0, 0, 0)})
	display.commonUIParams(touchView, {po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5), ap = display.CENTER, cb = handler(self, self.onCellClickHandler)})
	cell:addChild(touchView)

	local splitLine = display.newNSprite(_res('ui/pvc/pvp_report_ico_line.png'), 0, 0)
	display.commonUIParams(splitLine, {po = cc.p(80, cellSize.height * 0.5)})
	cell:addChild(splitLine)

	local resultX = splitLine:getPositionX() - 35
	local winIcon = display.newNSprite(_res(winIconPath), 0, 0)
	display.commonUIParams(winIcon, {po = cc.p(
		resultX,
		cellSize.height * 0.5 - 10
	)})
	cell:addChild(winIcon)

	local typeStr = __('进攻')
	if 2 == checkint(reportData.type) then
		typeStr = __('防守')
	end
	local typeLabel = display.newLabel(0, 0, {text = typeStr, fontSize = 22, color = typeLabelColor })
	display.commonUIParams(typeLabel, {po = cc.p(
		resultX,
		cellSize.height - 25
	) ,reqW = 70 } )
	cell:addChild(typeLabel)

	local playerHeadScale = 0.65
	local playerHeadNode = require('common.PlayerHeadNode').new({
		avatar = reportData.opponent.avatar,
		avatarFrame = reportData.opponent.avatarFrame,
		showLevel = true,
		playerLevel = reportData.opponent.level,
		playerId = reportData.opponent.playerId or reportData.opponent.id,
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

	if BATTLE_SCRIPT_TYPE.TAG_MATCH ~= self.viewType then
		local goodsInfo = {
			{goodsIconPath = 'ui/pvc/pvp_ico_point.png', amount = checkint(reportData.integral), tag = 33},
			{goodsIconPath = CommonUtils.GetGoodsIconPathById(PVC_MEDAL_ID), amount = checkint(reportData.medal), tag = 55}
		}
	
		for i,v in ipairs(goodsInfo) do
			local goodsBg = display.newImageView(_res('ui/pvc/pvp_report_bg_prize.png'), 0, 0)
			display.commonUIParams(goodsBg, {po = cc.p(
				cellSize.width - 20 - goodsBg:getContentSize().width * 0.5,
				cellSize.height * 0.5 + ((i - 0.5) - #goodsInfo * 0.5) * (goodsBg:getContentSize().height + 5)
			)})
			cell:addChild(goodsBg)
			goodsBg:setTag(v.tag)
	
			local goodsIconScale = 0.2
			local goodsIcon = display.newImageView(v.goodsIconPath, 0, 0)
			display.commonUIParams(goodsIcon, {ap = cc.p(1, 0.5), po = cc.p(
				goodsBg:getContentSize().width,
				goodsBg:getContentSize().height * 0.5
			)})
			goodsIcon:setScale(goodsIconScale)
			goodsBg:addChild(goodsIcon)
	
			local goodsAmountLabel = display.newLabel(0, 0, fontWithColor('14', {text = tostring(v.amount)}))
			display.commonUIParams(goodsAmountLabel, {ap = cc.p(1, 0.5), po = cc.p(
				goodsIcon:getPositionX() - goodsIcon:getContentSize().width * goodsIconScale,
				goodsIcon:getPositionY()
			)})
			goodsBg:addChild(goodsAmountLabel)
			goodsAmountLabel:setTag(3)
		end
	end

	bg:setTag(3)
	winIcon:setTag(5)
	typeLabel:setTag(7)
	playerHeadNode:setTag(9)
	playerNameLabel:setTag(11)
	battleTimeLabel:setTag(13)

	return cell
end
--[[
刷新一个cell
--]]
function PVCReportView:RefreshAReportCell(cell, index)
	local reportData = self.reportData[index]

	local bgPath = 'ui/pvc/rob_record_bg_victory_list.png'
	local winIconPath = 'ui/pvc/pvp_report_ico_victory.png'
	local typeLabelColor = '#5570a7'
	if 0 == checkint(reportData.isPassed) then
		bgPath = 'ui/pvc/rob_record_bg_defeat_list.png'
		winIconPath = 'ui/pvc/pvp_report_ico_defeat.png'
		typeLabelColor = '#ba5c5c'
	end

	local typeStr = __('进攻')
	if 2 == checkint(reportData.type) then
		typeStr = __('防守')
	end

	local bg = cell:getChildByTag(3)
	if bg then
		bg:setTexture(_res(bgPath))
	end

	local winIcon = cell:getChildByTag(5)
	if winIcon then
		winIcon:setTexture(_res(winIconPath))
	end

	local typeLabel = cell:getChildByTag(7)
	if typeLabel then
		typeLabel:setString(typeStr)
		typeLabel:setColor(ccc4FromInt(typeLabelColor))
	end

	local playerHeadNode = cell:getChildByTag(9)
	if playerHeadNode then
		playerHeadNode:RefreshUI({
			playerId = reportData.opponent.playerId or reportData.opponent.id,
			avatar = reportData.opponent.avatar,
			avatarFrame = reportData.opponent.avatarFrame,
			playerLevel = reportData.opponent.level,
			defaultCallback = self.headDefaultCallback,
		})
	end

	local playerNameLabel = cell:getChildByTag(11)
	if playerNameLabel then
		playerNameLabel:setString(tostring(reportData.opponent.name))
	end

	local battleTimeLabel = cell:getChildByTag(13)
	if battleTimeLabel then
		battleTimeLabel:setString(self:GetFixedTimeStr(reportData.createTime))
	end

	if BATTLE_SCRIPT_TYPE.TAG_MATCH ~= self.viewType then
		local goodsInfo = {
			{goodsIconPath = 'ui/pvc/pvp_ico_point.png', amount = checkint(reportData.integral), tag = 33},
			{goodsIconPath = CommonUtils.GetGoodsIconPathById(PVC_MEDAL_ID), amount = checkint(reportData.medal), tag = 55}
		}
	
		for i,v in ipairs(goodsInfo) do
			local goodsBg = cell:getChildByTag(v.tag)
			if goodsBg and goodsBg:getChildByTag(3) then
				goodsBg:getChildByTag(3):setString(v.amount)
			end
		end
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
function PVCReportView:GetFixedTimeStr(time)
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
		str = string.format(__('%d分钟前'), m)
	elseif 3600 <= deltaTime and 3600 * 24 > deltaTime then
		local h = math.floor(deltaTime / 3600)
		str = string.format(__('%d小时前'), h)
	elseif 3600 * 24 <= deltaTime then
		local d = math.floor(deltaTime / (3600 * 24))
		str = string.format(__('%d天前'), d)
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
function PVCReportView:RankingClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('SHOW_PVC_RANK')
end

function PVCReportView:onCellClickHandler(sender)
	PlayAudioByClickNormal()
	local cell = sender:getParent()
	local index = cell:getTag()
	local reportData = self.reportData[index]
	AppFacade.GetInstance():DispatchObservers('CLICK_PVC_REPORT_VIEW_CELL', {data = reportData, cell = cell})
end
---------------------------------------------------
-- btn click handler end --
---------------------------------------------------

return PVCReportView
