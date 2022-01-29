--[[
伤害统计页
--]]
local SkadaView = class('SkadaView', function ()
	local node = CLayout:create(display.size)
	node.name = 'battle.view.SkadaView'
	node:enableNodeEvents()
	print('SkadaView', ID(node))
	return node
end)

------------ import ------------
------------ import ------------

------------ define ------------
local RES_DICT = {
	CELL_BG_NORMAL 		= _res('ui/battle/skada/battle_data_bg_role.png'),
	CELL_BG_MVP 		= _res('ui/battle/skada/battle_data_bg_role_mvp.png'),
	BAR_BG 				= _res('ui/battle/skada/battle_data_bg_progress.png'),
	BAR_CON_DAMAGE 		= _res('ui/battle/skada/battle_data_img_progress_1.png'),
	BAR_CON_HEAL 		= _res('ui/battle/skada/battle_data_img_progress_2.png'),
	BAR_CON_GOT_DAMAGE 	= _res('ui/battle/skada/battle_data_img_progress_3.png')
}

local CellSize = cc.size(222, 622)
local CellPerRow = MAX_TEAM_MEMBER_AMOUNT

local SkadaInfoConfig = {
	{skadaType = SkadaType.DAMAGE, 		descr = __('伤害量'), 		barPath = RES_DICT.BAR_CON_DAMAGE, 		tagInCell = 101},
	{skadaType = SkadaType.HEAl, 		descr = __('治疗量/护盾量'), 	barPath = RES_DICT.BAR_CON_HEAL, 		tagInCell = 201},
	{skadaType = SkadaType.GOT_DAMAGE, 	descr = __('承受伤害量'), 	barPath = RES_DICT.BAR_CON_GOT_DAMAGE, 	tagInCell = 301}
}
------------ define ------------

--[[
constructor
--]]
function SkadaView:ctor( ... )

	local args = unpack({...})

	-- 当前选择的队伍
	self.currentTeamIndex = nil

	-- 队伍信息
	self.teamsData = nil
	-- 伤害统计信息
	self.skadaData = nil
	-- tag映射
	self.tagInfo = nil
	-- extra 伤害统计信息
	self.extraSkadaData = {}

	-- 初始化ui
	self:InitUI()

	-- 刷新数据
	self:RefreshUI(args.teamsData, args.skadaData, args.tagInfo)

end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function SkadaView:InitUI()

	local selfCenter = cc.p(display.cx, display.cy)

	-- 初始化通用ui
	local function CreateView()

		-- 背景底
		local bg = display.newImageView(_res('ui/battle/skada/battle_data_bg.jpg'), selfCenter.x, selfCenter.y, {isFull = true})
		self:addChild(bg)

		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height + 100,{n = _res('ui/common/common_title_new.png'),ap = cc.p(0, 0)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('战斗统计'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		self:addChild(tabNameLabel, 99)

		-- 返回
		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png"), cb = function (sender)
			PlayAudioByClickClose()
			
			if nil ~= self.viewData.shareView and self.viewData.shareView:isVisible() then
				self:HideShareView()
			else
				self:setVisible(false)
			end

		end})
		display.commonUIParams(backBtn, {po = cc.p(
			display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30,
	    	display.size.height - 18 - backBtn:getContentSize().height * 0.5
		)})
		self:addChild(backBtn, 5)

		-- 分享按钮
		local shareBtn = require('common.CommonShareButton').new({clickCallback = handler(self, self.ShareBtnClickHandler)})
		display.commonUIParams(shareBtn, {po = cc.p(
			display.SAFE_R - shareBtn:getContentSize().width * 0.5 - 20,
			display.SAFE_T - shareBtn:getContentSize().height * 0.5 - 15
		)})
		self:addChild(shareBtn, 99)
		shareBtn:setVisible(false)

		-- 主列表
		local cellSize = CellSize
		local listViewSize = cc.size(cellSize.width * CellPerRow, cellSize.height)

		local listView = CTableView:create(listViewSize)
		display.commonUIParams(listView, {ap = cc.p(0.5, 0.5), po = cc.p(
			display.cx + 75,
			display.cy - 40
		)})
		self:addChild(listView, 5)

		-- listView:setBackgroundColor(cc.c4b(255, 255, 100, 100))

		listView:setSizeOfCell(cellSize)
		listView:setCountOfCell(0)
		listView:setDirection(eScrollViewDirectionHorizontal)
		listView:setDataSourceAdapterScriptHandler(handler(self, self.SkadaViewDataAdapter))

		-- 列表顶部队伍按钮
		local teamNodesLine = display.newSprite(_res('ui/battle/skada/batte_data_3v3_bg_tab.png'))
		display.commonUIParams(teamNodesLine, {ap = cc.p(0.5, 0.5), po = cc.p(
			listView:getPositionX() + 25,
			listView:getPositionY() + listViewSize.height * 0.5 + 10
		)})
		self:addChild(teamNodesLine, 5)

		-- 左侧文字
		local skadaInfoNodes = {}
		for i, skadaInfo in ipairs(SkadaInfoConfig) do
			-- 描述文字
			local descrLabel = display.newLabel(0, 0, fontWithColor('4', {text = skadaInfo.descr, w = 175,  color = '#cfcecd' , hAlign = display.TAR}))
			display.commonUIParams(descrLabel, {ap = cc.p(1, 0.5), po = cc.p(
				listView:getPositionX() - listViewSize.width * 0.5 - 5,
				listView:getPositionY() + listViewSize.height * 0.5 - 310 - (i - 1) * 94
			)})
			self:addChild(descrLabel, 5)

			-- 数值文字
			local valueLabel = display.newLabel(0, 0, fontWithColor('18', {text = '0', hAlign = display.TAR}))
			display.commonUIParams(valueLabel, {ap = cc.p(1, 0), po = cc.p(
				descrLabel:getPositionX(),
				descrLabel:getPositionY() + display.getLabelContentSize(descrLabel).height * 0.5 -5
			)})
			self:addChild(valueLabel, 5)

			if (0 ~= i % 2) then
				-- 创建分隔底
				local skadaInfoBg = display.newImageView(_res('ui/battle/skada/battle_data_bg_data.png'), 0, 0)
				display.commonUIParams(skadaInfoBg, {ap = cc.p(0, 0.5), po = cc.p(
					listView:getPositionX() - listViewSize.width * 0.5,
					descrLabel:getPositionY()
				)})
				self:addChild(skadaInfoBg, 1)
			end

			skadaInfoNodes[skadaInfo.skadaType] = {descrLabel = descrLabel, valueLabel = valueLabel}
		end

		return {
			tabNameLabel = tabNameLabel,
			listView = listView,
			teamNodes = {},
			teamNodesLine = teamNodesLine,
			skadaInfoNodes = skadaInfoNodes,
			shareView = nil,
			shareBtn = shareBtn
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	-- 弹出标题班
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1,cc.p(display.SAFE_L + 130, display.height - 80)))
	self.viewData.tabNameLabel:runAction(action)

	self.viewData.tabNameLabel:setOnClickScriptHandler(function( sender )
		PlayAudioByClickClose()
		-- app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.PET)]})
	end)
	
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- ui logic begin --
---------------------------------------------------
--[[
根据skada数据刷新界面
@params teamsData 队伍信息
@params skadaData 伤害统计数据
@params tagInfo 物体tag映射关系
--]]
function SkadaView:RefreshUI(teamsData, skadaData, tagInfo)
	self.teamsData = teamsData
	self.skadaData = skadaData
	self.tagInfo = tagInfo

	self:CalcExtraSkadaData()

	-- 刷新顶部标签按钮
	self:RefreshTeamAmount(#self.teamsData)
	self:RefreshSkadaViewByTeamIndex(1)
end
--[[
刷新顶部队伍标签
@params teamAmount int 队伍数量
--]]
function SkadaView:RefreshTeamAmount(teamAmount)
	-- 移除老的按钮
	for i,v in ipairs(self.viewData.teamNodes) do
		v:removeFromParent()
	end

	local showTeamTab = 1 < teamAmount

	-- 创建新的按钮
	for i = 1, teamAmount do
		-- 按钮
		local teamTabBtn = display.newCheckBox(0, 0, {
			n = _res('ui/battle/skada/batte_data_3v3_tab_normal.png'),
			s = _res('ui/battle/skada/batte_data_3v3_tab_selected.png')
		})
		display.commonUIParams(teamTabBtn, {ap = cc.p(0.5, 0), po = cc.p(
			self.viewData.teamNodesLine:getPositionX() + ((teamTabBtn:getContentSize().width + 10) * (i - (teamAmount / 2 + 0.5))),
			self.viewData.teamNodesLine:getPositionY() - 2
		)})
		teamTabBtn:setOnClickScriptHandler(handler(self, self.TeamTabBtnClickHandler))
		teamTabBtn:setTag(i)
		self.viewData.teamNodesLine:getParent():addChild(teamTabBtn, self.viewData.teamNodesLine:getLocalZOrder() - 1)

		local teamTabLabel = display.newLabel(0, 0, fontWithColor('18', {fontSize = 28, color = '#392416', text = string.format(__('队伍%d'), i)}))
		display.commonUIParams(teamTabLabel, {ap = cc.p(0.5, 0.5), po = cc.p(
			utils.getLocalCenter(teamTabBtn).x,
			utils.getLocalCenter(teamTabBtn).y
		)})
		teamTabBtn:addChild(teamTabLabel)
		teamTabLabel:setTag(3)

		table.insert(self.viewData.teamNodes, teamTabBtn)

		teamTabBtn:setVisible(showTeamTab)
	end

	self.viewData.teamNodesLine:setVisible(showTeamTab)
end
--[[
data adapter
--]]
function SkadaView:SkadaViewDataAdapter(c, i)
	local cell = c
	local index = i + 1

	if nil == cell then
		-- 创建一个新的cell
		cell = self:CreateASkadaCell(self:GetCurrentTeamIndex(), index)
	else
		-- 刷新老的cell
		self:RefreshSkadaCell(cell, self:GetCurrentTeamIndex(), index)
	end

	cell:setTag(index)

	return cell
end
--[[
创建一个新的cell
@params teamIndex int 队伍序号
@params memberIndex int 队伍中的序号
--]]
function SkadaView:CreateASkadaCell(teamIndex, memberIndex)
	-- 卡牌信息
	local cardInfo = self:GetCardInfo(teamIndex, memberIndex)
	local cardId = checkint(cardInfo.cardId)
	local cardConfig = CardUtils.GetCardConfig(cardId)

	local objectTag = self:GetSkadaObjectTag(teamIndex, memberIndex)
	local cardSkadaData = self:GetExtraSkadaDataByTag(objectTag)
	local isMvp = cardSkadaData.isMvp

	local cellSize = self.viewData.listView:getSizeOfCell()

	local cell = CTableViewCell:new()
	cell:setContentSize(cellSize)

	------------ 底框 ------------
	-- 底图
	local bgPath = true == isMvp and RES_DICT.CELL_BG_MVP or RES_DICT.CELL_BG_NORMAL
	local bg = display.newImageView(bgPath, 0, 0)
	display.commonUIParams(bg, {ap = cc.p(0.5, 1), po = cc.p(
		cellSize.width * 0.5,
		cellSize.height
	)})
	cell:addChild(bg)
	bg:setTag(3)

	-- 底图边线
	local bgLine = display.newSprite(_res('ui/battle/skada/battle_data_img_line.png'))
	display.commonUIParams(bgLine, {ap = cc.p(0, 0.5), po = cc.p(
		0, bg:getContentSize().height * 0.5
	)})
	bg:addChild(bgLine, 10)

	-- 底图下的卡牌品质线
	local bgBottomPath = string.format('ui/battle/skada/battle_data_img_line_%d.png', checkint(cardConfig.qualityId))
	local bgBottom = display.newSprite(_res(bgBottomPath))
	display.commonUIParams(bgBottom, {ap = cc.p(0.5, 1), po = cc.p(
		cellSize.width * 0.5, bg:getPositionY() - bg:getContentSize().height
	)})
	cell:addChild(bgBottom, 5)
	bgBottom:setTag(5)
	------------ 底框 ------------

	------------ 卡牌信息 ------------
	-- 卡牌头像
	local cardHeadNode = require('common.CardHeadNode').new({
		cardData = {
			cardId = cardId,
			level = cardInfo.level,
			breakLevel = cardInfo.breakLevel,
			skinId = cardInfo.skinId,
			favorabilityLevel = cardInfo.favorLevel
		},
		showBaseState = true,
		showActionState = false,
		showVigourState = false
	})
	display.commonUIParams(cardHeadNode, {ap = cc.p(0.5, 0.5), po = cc.p(
		cellSize.width * 0.5,
		cellSize.height - cardHeadNode:getContentSize().height * 0.5 - 5
	)})
	cell:addChild(cardHeadNode)
	cardHeadNode:setTag(7)

	-- 卡牌名字
	local cardName = display.newLabel(0, 0,
		fontWithColor('19', {text = cardConfig.name, outline = '#bc4618', reqW = 210 , outlineSize = 3}))
	display.commonUIParams(cardName, {ap = cc.p(0.5, 1), po = cc.p(
		cardHeadNode:getPositionX(),
		cardHeadNode:getPositionY() - cardHeadNode:getContentSize().height * 0.5 - 10
	)})
	cell:addChild(cardName)
	cardName:setTag(9)

	-- mvp mark
	local mvpMark = display.newSprite(_res('ui/battle/skada/battle_data_img_mvp.png'))
	display.commonUIParams(mvpMark, {ap = cc.p(1, 1), po = cc.p(
		cardHeadNode:getPositionX() + cardHeadNode:getContentSize().width * 0.5 + 5,
		cardHeadNode:getPositionY() + cardHeadNode:getContentSize().height * 0.5
	)})
	cell:addChild(mvpMark, 99)
	mvpMark:setVisible(isMvp)
	mvpMark:setTag(11)
	------------ 卡牌信息 ------------

	------------ 伤害统计 ------------
	local skadaType = nil
	local valuePercent = nil
	local sum = nil

	for _, skadaInfo in ipairs(SkadaInfoConfig) do

		skadaType = skadaInfo.skadaType
		valuePercent = nil ~= cardSkadaData[skadaType] and cardSkadaData[skadaType].valuePercent or 0
		sum = nil ~= cardSkadaData[skadaType] and cardSkadaData[skadaType].sum or 0

		local nodes = self.viewData.skadaInfoNodes[skadaInfo.skadaType]
		local fixedPos = self.viewData.listView:convertToNodeSpace(nodes.descrLabel:getParent():convertToWorldSpace(cc.p(
			nodes.descrLabel:getPositionX(), nodes.descrLabel:getPositionY()
		)))

		-- 进度条
		local barBg = display.newImageView(RES_DICT.BAR_BG, 0, 0)
		display.commonUIParams(barBg, {ap = cc.p(0.5, 0.5), po = cc.p(
			cardHeadNode:getPositionX(),
			fixedPos.y
		)})
		cell:addChild(barBg)
		barBg:setTag(skadaInfo.tagInCell)

		-- 进度条内容
		local bar = cc.ProgressTimer:create(cc.Sprite:create(skadaInfo.barPath))
		bar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
		bar:setMidpoint(cc.p(0, 0))
		bar:setBarChangeRate(cc.p(1, 0))
		bar:setPercentage(valuePercent)
		bar:setPosition(utils.getLocalCenter(barBg))
		barBg:addChild(bar)
		bar:setTag(3)
		bar:stopAllActions()
		bar:runAction(cc.ProgressTo:create(0.2, valuePercent * 100))

		-- 百分比数字
		local percentStr = string.format('%s%%', tostring(math.round(valuePercent * 10000) * 0.01))
		local percentLabel = display.newLabel(0, 0, fontWithColor('3', {text = percentStr, color = '#f3ea9c'}))
		display.commonUIParams(percentLabel, {ap = cc.p(1, 0.5), po = cc.p(
			barBg:getPositionX() + barBg:getContentSize().width * 0.5 - 5,
			barBg:getPositionY()
		)})
		cell:addChild(percentLabel)
		percentLabel:setTag(skadaInfo.tagInCell + 3)

		-- 值数字
		local valueStr = tostring(math.round(sum))
		local valueLabel = display.newLabel(0, 0, fontWithColor('18', {text = valueStr, color = '#dcad93'}))
		display.commonUIParams(valueLabel, {ap = cc.p(0, 0), po = cc.p(
			barBg:getPositionX() - barBg:getContentSize().width * 0.5 + 5,
			barBg:getPositionY() + barBg:getContentSize().height * 0.5
		)})
		cell:addChild(valueLabel)
		valueLabel:setTag(skadaInfo.tagInCell + 5)

	end
	------------ 伤害统计 ------------

	return cell
end
--[[
刷新老的cell
@params teamIndex int 队伍序号
@params memberIndex int 队伍中的序号
--]]
function SkadaView:RefreshSkadaCell(cell, teamIndex, memberIndex)
	-- 卡牌信息
	local cardInfo = self:GetCardInfo(teamIndex, memberIndex)
	local cardId = checkint(cardInfo.cardId)
	local cardConfig = CardUtils.GetCardConfig(cardId)

	local objectTag = self:GetSkadaObjectTag(teamIndex, memberIndex)
	local cardSkadaData = self:GetExtraSkadaDataByTag(objectTag)
	local isMvp = cardSkadaData.isMvp

	------------ 底框 ------------
	-- 底图
	local bgPath = true == isMvp and RES_DICT.CELL_BG_MVP or RES_DICT.CELL_BG_NORMAL
	cell:getChildByTag(3):setTexture(bgPath)

	-- 底图下的卡牌品质线
	local bgBottomPath = string.format('ui/battle/skada/battle_data_img_line_%d.png', checkint(cardConfig.qualityId))
	cell:getChildByTag(5):setTexture(bgBottomPath)
	------------ 底框 ------------

	------------ 卡牌信息 ------------
	-- 卡牌头像
	cell:getChildByTag(7):RefreshUI({
		cardData = {
			cardId = cardId,
			level = cardInfo.level,
			breakLevel = cardInfo.breakLevel,
			skinId = cardInfo.skinId,
			favorabilityLevel = cardInfo.favorLevel
		},
		showBaseState = true
	})

	-- 卡牌名字
	cell:getChildByTag(9):setString(cardConfig.name)

	-- mvp mark
	cell:getChildByTag(11):setVisible(isMvp)
	------------ 卡牌信息 ------------

	------------ 伤害统计 ------------
	local skadaType = nil
	local valuePercent = nil
	local sum = nil

	for _, skadaInfo in ipairs(SkadaInfoConfig) do

		skadaType = skadaInfo.skadaType
		valuePercent = nil ~= cardSkadaData[skadaType] and cardSkadaData[skadaType].valuePercent or 0
		sum = nil ~= cardSkadaData[skadaType] and cardSkadaData[skadaType].sum or 0

		-- 进度条
		local barBg = cell:getChildByTag(skadaInfo.tagInCell)
		local bar = barBg:getChildByTag(3)
		bar:setPercentage(valuePercent)
		bar:stopAllActions()
		bar:runAction(cc.ProgressTo:create(0.2, valuePercent * 100))

		-- 百分比数字
		local percentStr = string.format('%s%%', tostring(math.floor(valuePercent * 10000) * 0.01))
		cell:getChildByTag(skadaInfo.tagInCell + 3):setString(percentStr)

		-- 值数字
		local valueStr = tostring(math.floor(sum))
		cell:getChildByTag(skadaInfo.tagInCell + 5):setString(valueStr)		
	end
	------------ 伤害统计 ------------
end
--[[
根据队伍序号刷新伤害统计页
@params teamIndex int 队伍序号
@params force bool 是否强制刷新
--]]
function SkadaView:RefreshSkadaViewByTeamIndex(teamIndex, force)
	-- 刷新当前按钮状态
	if nil ~= teamIndex then
		local currentTabBtn = self.viewData.teamNodes[teamIndex]		
		if nil ~= currentTabBtn then
			currentTabBtn:setChecked(true)
			display.commonLabelParams(currentTabBtn:getChildByTag(3), {color = '#a72e04'})
		end 
	end

	if teamIndex == self:GetCurrentTeamIndex() and not force then return end

	-- 刷新之前的按钮状态
	if nil ~= self:GetCurrentTeamIndex() then
		local preTabBtn = self.viewData.teamNodes[self:GetCurrentTeamIndex()]
		if nil ~= preTabBtn then
			preTabBtn:setChecked(false)
			display.commonLabelParams(preTabBtn:getChildByTag(3), {color = '#392416'})
		end
	end

	self:SetCurrentTeamIndex(teamIndex)

	-- 刷新伤害统计内容
	self:RefreshSkada()

end
--[[
刷新伤害统计内容
--]]
function SkadaView:RefreshSkada()
	-- 计算修正的伤害统计
	self:CalcExtraSkadaData()

	-- 刷新侧边总值
	self:RefreshSkadaTotal()

	-- 刷新列表
	self:RefreshListView()
end
--[[
刷新侧边总值
--]]
function SkadaView:RefreshSkadaTotal()
	local currentTeamIndex = self:GetCurrentTeamIndex()
	local skadaType = nil
	local teamSkadaData = nil
	local nodes = nil

	for _, skadaInfo in ipairs(SkadaInfoConfig) do
		skadaType = skadaInfo.skadaType
		teamSkadaData = self:GetSkadaDataByTeamIndex(currentTeamIndex)
		nodes = self.viewData.skadaInfoNodes[skadaType]

		if nil ~= teamSkadaData then

			local skadaData = teamSkadaData[skadaType]

			nodes.valueLabel:setString(tostring(math.round(skadaData.sum)))

		else

			nodes.valueLabel:setString('0')

		end
	end
end
--[[
刷新列表
--]]
function SkadaView:RefreshListView()
	local teamData = self:GetCurrentTeamData()
	local memberAmount = #teamData
	self.viewData.listView:setCountOfCell(memberAmount)
	self.viewData.listView:setDragable(memberAmount > CellPerRow)
	self.viewData.listView:reloadData()
end
--[[
显示分享内容
--]]
function SkadaView:ShowShareView()
	if nil == self.viewData.shareView then
		local node = require('common.ShareNode').new({visitNode = self})
		node:setName('ShareNode')
		display.commonUIParams(node, {po = utils.getLocalCenter(self)})
		self:addChild(node, 999)

		self.viewData.shareView = node
	else
		self.viewData.shareView:setVisible(true)
	end

	-- 隐藏其他按钮
	self.viewData.shareBtn:setVisible(false)
end
--[[
隐藏分享内容
--]]
function SkadaView:HideShareView()
	if nil ~= self.viewData.shareView then
		self.viewData.shareView:setVisible(false)
	end

	-- 显示其他按钮
	self.viewData.shareBtn:setVisible(false)
end
---------------------------------------------------
-- ui logic end --
---------------------------------------------------

---------------------------------------------------
-- btn handler begin --
---------------------------------------------------
--[[
顶部队伍页签按钮回调
--]]
function SkadaView:TeamTabBtnClickHandler(sender)
	PlayAudioByClickNormal()

	local teamIndex = sender:getTag()
	self:RefreshSkadaViewByTeamIndex(teamIndex)
end
--[[
分享按钮回调
--]]
function SkadaView:ShareBtnClickHandler(sender)
	PlayAudioByClickNormal()
	self:ShowShareView()
end
---------------------------------------------------
-- btn handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
计算一些修正的伤害统计值
--]]
function SkadaView:CalcExtraSkadaData() 
	local priorityConfig = {
		SkadaType.DAMAGE,
		SkadaType.GOT_DAMAGE,
		SkadaType.HEAl,
	}

	for teamIndex, teamTotalData in pairs(self.skadaData) do

		local mvpTag = nil
		local mvpValue = nil
		local mvpType = nil

		for _, skadaType in ipairs(priorityConfig) do
			
			local teamSkada = teamTotalData[skadaType]

			if nil ~= teamSkada then
				for objectTag, objectSkada in pairs(teamSkada.memberSkada) do

					local valuePercent = 0
					if nil ~= tonumber(teamSkada.sum) and 0 < teamSkada.sum then
						valuePercent = objectSkada.sum / teamSkada.sum
					end
					local data = {valuePercent = valuePercent, sum = objectSkada.sum}
					if nil == self.extraSkadaData[objectTag] then
						self.extraSkadaData[objectTag] = {isMvp = false}
					end
					if nil == self.extraSkadaData[objectTag][skadaType] then
						self.extraSkadaData[objectTag][skadaType] = {}
					end

					self.extraSkadaData[objectTag][skadaType] = data

					------------ mvp ------------
					-- 判断依据
					-- 1 伤害最高的卡牌
					-- 2 上面一条无效的时候承受伤害最高的卡牌
					-- 3 上面一条无效的时候治疗量护盾最高的卡牌
					if SkadaType.DAMAGE == skadaType then

						if 0 < objectSkada.sum then

							if nil == mvpValue then
								mvpValue = objectSkada.sum
								mvpTag = objectTag
								mvpType = skadaType
							elseif mvpValue < objectSkada.sum then
								mvpValue = objectSkada.sum
								mvpTag = objectTag
								mvpType = skadaType
							end

						end

					elseif (SkadaType.GOT_DAMAGE == skadaType or SkadaType.HEAl == skadaType) and nil == mvpType then

						if 0 < objectSkada.sum then

							if nil == mvpValue then
								mvpValue = objectSkada.sum
								mvpTag = objectTag
								mvpType = skadaType
							elseif mvpValue < objectSkada.sum then
								mvpValue = objectSkada.sum
								mvpTag = objectTag
								mvpType = skadaType
							end

						end

					end
					------------ mvp ------------

				end
			end

		end

		if nil ~= mvpTag then
			self.extraSkadaData[mvpTag].isMvp = true
		end

	end
end
--[[
当前选择的队伍序号
--]]
function SkadaView:GetCurrentTeamIndex()
	return self.currentTeamIndex
end
function SkadaView:SetCurrentTeamIndex(teamIndex)
	self.currentTeamIndex = teamIndex
end
--[[
获取当前队伍信息
--]]
function SkadaView:GetCurrentTeamData()
	return self.teamsData[self:GetCurrentTeamIndex()]
end
--[[
根据队伍序号 队伍中序号获取物体tag
@params teamIndex int 队伍序号
@params memberIndex int 队伍中序号
--]]
function SkadaView:GetSkadaObjectTag(teamIndex, memberIndex)
	return self.tagInfo[teamIndex] and self.tagInfo[teamIndex][memberIndex] or nil
end
--[[
根据队伍序号 队伍中序号获取卡牌信息
@params teamIndex int 队伍序号
@params memberIndex int 队伍中序号
--]]
function SkadaView:GetCardInfo(teamIndex, memberIndex)
	return self.teamsData[teamIndex] and self.teamsData[teamIndex][memberIndex] or nil
end
--[[
根据tag判断是否是mvp
@params skadaTag int object tag
--]]
function SkadaView:IsMvpByTag(skadaTag)
	return self.extraSkadaData[skadaTag].isMvp
end
--[[
根据队伍index获取伤害统计总的信息
@params teamIndex int 队伍index
@return _ {
	[skadaType] = {sum = 0, memberSkada = {}},
	[skadaType] = {sum = 0, memberSkada = {}},
	[skadaType] = {sum = 0, memberSkada = {}},
	...
}
--]]
function SkadaView:GetSkadaDataByTeamIndex(teamIndex)
	return self.skadaData[teamIndex]
end
--[[
根据tag获取单人的skada数据
@params skadaTag int 伤害统计tag
@return _ {
	[skadaType] = {
		valuePercent = 0,
		sum = 0
	},
	...
	isMvp = false
}
--]]
function SkadaView:GetExtraSkadaDataByTag(skadaTag)
	return self.extraSkadaData[skadaTag] or {isMvp = false}
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return SkadaView
