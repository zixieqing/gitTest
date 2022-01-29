--[[
排行榜Mediator
--]]
local Mediator = mvc.Mediator

local UnionRankMediator = class("UnionRankMediator", Mediator)

local NAME = "UnionRankMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")
local scheduler = require('cocos.framework.scheduler')
local RankCell = require('home.RankCell')
local RankPopularityCell = require('home.UnionRankCell')
-- 
local RANK = {
	{name = __('贡献值排行榜'), rankTypes = UnionRankTypes.CONTRIBUTION, child = {
		{name = __('每日'), rankTypes = UnionRankTypes.CONTRIBUTION_DAILY, title = __('每日贡献值排行榜'), scoreName = __('今日贡献值'), fieldName = 'todayContributionPoint', isShowAllMember = true},
		{name = __('每周'), rankTypes = UnionRankTypes.CONTRIBUTION_WEEKLY, title = __('每周贡献值排行榜'), scoreName = __('贡献值'), fieldName = 'contributionPoint', isShowAllMember = true}
	}},
	{name = __('建造排行榜'), rankTypes = UnionRankTypes.BUILD_TIMES, child = {
		{name = __('每日'), rankTypes = UnionRankTypes.BUILD_TIMES_DAILY, title = __('每日建造排行榜'), scoreName = __('总建造次数'), extra = __('低阶/中阶/高阶次数'), fieldName = 'dailyBuildTimesNum'},
		{name = __('每周'), rankTypes = UnionRankTypes.BUILD_TIMES_WEEKLY, title = __('每周建造排行榜'), scoreName = __('总建造次数'), fieldName = 'buildTimes'}
	}},
	{name = __('喂食排行榜'), rankTypes = UnionRankTypes.FEED_TIMES, child = {
		{name = __('每日'), rankTypes = UnionRankTypes.FEED_TIMES_DAILY, title = __('每日喂食排行榜'), scoreName = __('喂食次数'), extra = __('获得饱食度'), fieldName = 'dailyFeedPetTimes'},
		{name = __('每周'), rankTypes = UnionRankTypes.FEED_TIMES_WEEKLY, title = __('每周喂食排行榜'), scoreName = __('喂食次数'), fieldName = 'feedPetTimes'}
	}},
	{name = __('伤害排行榜'), rankTypes = UnionRankTypes.GODBEAST_DAMAGE, title = __('伤害排行榜'), scoreName = __('本周伤害'), extra = __('当日伤害'), fieldName = 'godBeastDamage', child = {}},
	{name = __('灾祸伤害榜'), rankTypes = UnionRankTypes.BOSS_DAMAGE, title = __("灾祸伤害榜"), scoreName = __('伤害'), fieldName = 'worldBossDailyDamage'}
}
local PROLONG_TIME = 2
function UnionRankMediator:ctor( params, viewComponent )
	local datas = params or {}
	self.super:ctor(NAME,viewComponent)
	self.selectedRank = datas.unionRankTypes or UnionRankTypes.CONTRIBUTION_DAILY
	self.unionRankDatas = {}
end

function UnionRankMediator:InterestSignals()
	local signals = {
		POST.UNION_RANK.sglName,
	}
	return signals
end

function UnionRankMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	if name == POST.UNION_RANK.sglName then
		local datas = signal:GetBody()
		self.unionRankDatas = datas.member
		-- 计算每日建造次数
		for i,v in ipairs(self.unionRankDatas) do
			local dailyBuildTimesNum = 0
			for i, times in pairs(checktable(v.dailyBuildTimes)) do
				dailyBuildTimesNum = dailyBuildTimesNum + checkint(times)
			end
			self.unionRankDatas[i].dailyBuildTimesNum = dailyBuildTimesNum
		end
		self:TabButtonCallback(self.selectedRank)
	end
end

function UnionRankMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent = require( 'Game.views.UnionRankView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	viewComponent.viewData_.rankGridView:setDataSourceAdapterScriptHandler(handler(self, self.RankDataSource))
    viewComponent.viewData_.tipsIcon:setOnClickScriptHandler(handler(self, self.TipsIconCallback))
    self:InitRankDatas()

end
--[[
初始化排行榜页签数据
--]]
function UnionRankMediator:InitRankDatas()
	local godBeastIndex = self:GetIndexByUnionRankTypes(UnionRankTypes.GODBEAST_DAMAGE)
	if godBeastIndex then
		RANK[godBeastIndex].child = {}
		local godBeastDatas = CommonUtils.GetConfigAllMess('godBeast', 'union')
		for k,v in orderedPairs(godBeastDatas) do
			local temp = {
				name = v.name,
				rankTypes = checkint(v.id),
				title = RANK[godBeastIndex].title,
				scoreName = RANK[godBeastIndex].scoreName,
				extra = RANK[godBeastIndex].extra
			}
			table.insert(RANK[godBeastIndex].child, temp)
		end
		if next(RANK[godBeastIndex].child) == nil then -- 如果没有神兽则隐藏此排行榜
			RANK[godBeastIndex] = nil 
		end
	end
end
--[[
刷新Ui
--]]
function UnionRankMediator:refreshUi()
	local viewData = self:GetViewComponent().viewData_
	viewData.listView:removeAllNodes()
	for i,v in ipairs(RANK) do
		local cSize = cc.size(212, 90)
		local cell = RankCell.new(cSize)
		cell.button:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
		cell.button:setUserTag(v.rankTypes)
		--cell.nameLabel:setString(v.name)
		display.commonLabelParams( cell.nameLabel ,{text = v.name ,w = 180  ,hAlign = display.TAC })
		-- 判断是否被选中
		if self.selectedRank == v.rankTypes then
			cell.button:setNormalImage(_res('ui/home/rank/rank_btn_tab_select.png'))
			cell.button:setSelectedImage(_res('ui/home/rank/rank_btn_tab_select.png'))
			if v.child then
				self.selectedRank = v.child[1].rankTypes
			end
		end
		-- 判断是否有子页签
		if v.child then
			cell.arrowIcon:setVisible(true)
			-- 判断子页签是否被选中
			for _, child in ipairs(v.child) do
				if child.rankTypes == self.selectedRank then
					cell.arrowIcon:setRotation(0)
					cell.button:setNormalImage(_res('ui/home/rank/rank_btn_tab_select.png'))
					cell.button:setSelectedImage(_res('ui/home/rank/rank_btn_tab_select.png'))
					self:AddChildNode(cell, v.child)
				end
			end
		end
		viewData.listView:insertNodeAtLast(cell)
	end
	viewData.listView:reloadData()
	self:RefreshRankingList(self.selectedRank)
end
--[[
添加子页签
--]]
function UnionRankMediator:AddChildNode( cell, childData )
	local size = cell:getContentSize()
	cell:setContentSize(cc.size(size.width, size.height + 64 * #childData))
	cell.buttonLayout:setPosition(cc.p(size.width/2, cell:getContentSize().height - 50))
	local layout = CLayout:create(cc.size(size.width, 20 + 64 * #childData))
	layout:setPosition(cc.p(size.width/2, -15))
	layout:setAnchorPoint(cc.p(0.5, 0))
	cell:addChild(layout, 5)
	cell.childNode = layout
	local bg = display.newImageView(_res('ui/home/rank/rank_tab_bg_2.png'), layout:getContentSize().width/2, layout:getContentSize().height/2, {scale9 = true, size = cc.size(180, layout:getContentSize().height), capInsets = cc.rect(5, 5, 170, 165)})
	layout:addChild(bg)
	-- 子页签按钮
	for i,v in ipairs(childData) do
		local img = nil
		if self.selectedRank == v.rankTypes then
			img = _res('ui/home/rank/rank_btn_2_select.png')
		else
			img = _res('ui/home/rank/rank_btn_2_default.png')
		end
		local button = display.newButton(layout:getContentSize().width/2, layout:getContentSize().height - 40 - 64 * (i-1), {n = img})
		layout:addChild(button, 10)
		button:setUserTag(v.rankTypes)
		button:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
		local nameLabel = display.newLabel(	button:getContentSize().width/2, button:getContentSize().height/2, fontWithColor(14, {reqW = 145, text = v.name}))
		button:addChild(nameLabel)
	end
end
--[[
刷新排行榜页面
@params int unionRankTypes 排行榜类型
--]]
function UnionRankMediator:RefreshRankingList( unionRankTypes )
	if unionRankTypes then
		unionRankTypes = checkint(unionRankTypes)
	else
		return
	end
	-- 更新顶部信息栏
	local rankDatas = self:GetRankDatasByRankTypes(unionRankTypes)
	self:UpdateTopLayer(rankDatas)
	-- 根据排行榜类型对数据进行排序
	self:SortUnionRankDatas(unionRankTypes)
	local viewData = self:GetViewComponent().viewData_
    viewData.rankGridView:setCountOfCell(self:GetValidMemberNum(rankDatas.isShowAllMember))
    viewData.rankGridView:reloadData()	
end
--[[
更新排行榜顶部信息
@params table {
	title string 排行榜名称
	scoreName string 积分名称
	extra string 特殊积分名称
}
--]]
function UnionRankMediator:UpdateTopLayer( datas )
	local viewData = self:GetViewComponent().viewData_
	viewData.titleLabel:setString(datas.title or '')
	display.commonLabelParams(viewData.scoreLabel , fontWithColor(6, { fontSize = 20 , text = datas.scoreName or __('积分') , w   = 180 , hAlign  = display.TAC , hAlign = display.TAC }))
	display.commonLabelParams(viewData.extraLabel , {  text = datas.extra or '' ,w  =350 , hAlign = display.TAC  })
	viewData.scoreLabel:setString(datas.scoreName or __('积分'))

end
--[[
排行榜数据排序
@params unionRankTypes string 字段名
--]]
function UnionRankMediator:SortUnionRankDatas( unionRankTypes )
	if checkint(unionRankTypes) > 0 then
		-- 神兽排行榜
		for i,v in ipairs(self.unionRankDatas) do
			local godBeastIndex = self:GetIndexByUnionRankTypes(UnionRankTypes.GODBEAST_DAMAGE)
			local godBeastDatas = RANK[godBeastIndex]
			if v[godBeastDatas.fieldName] and type(v[godBeastDatas.fieldName]) == 'table' then
				v.score = checkint(v[godBeastDatas.fieldName][tostring(unionRankTypes)])
			else
				v.score = 0
			end
		end
	else
		local rankDatas = self:GetRankDatasByRankTypes(unionRankTypes)
		for i, playerDatas in ipairs(self.unionRankDatas) do
			playerDatas.score = checkint(playerDatas[rankDatas.fieldName])
		end
	end
	
	table.sort(self.unionRankDatas, function (a, b)
		local scoreA = a.score
		local scoreB = b.score
		if scoreA > scoreB then
			return true
		end
	end)
end
--[[
改变时间格式
@params seconds int 剩余秒数
--]]
function UnionRankMediator:ChangeTimeFormat( seconds )
	local time = nil
	local showDays = nil
	if seconds >= 86400 then
		time = math.floor(seconds/86400)
		showDays = true
	else
		local hour   = math.floor(seconds / 3600)
		local minute = math.floor((seconds - hour*3600) / 60)
		local sec    = (seconds - hour*3600 - minute*60)
		time = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
		showDays = false
	end
	return time, showDays
end
--[[
左侧页签点击回调
--]]
function UnionRankMediator:TabButtonCallback( sender )
    if tolua.type(sender) == 'ccw.CButton' then
        PlayAudioByClickNormal()
    end
	local rankTypes = nil
	if type(sender) == 'number' then
		rankTypes = sender
	else
		rankTypes = sender:getUserTag()
		if rankTypes == self.selectedRank then return end
	end

	-- 判断此页签有没有子页签
	for i, v in ipairs(RANK) do
		if v.rankTypes == rankTypes then
			if v.child then
				rankTypes = v.child[1].rankTypes
			end
		end
	end
	self.selectedRank = rankTypes
	self:refreshUi()
end
--[[
获取参与成员数目
-- @param isShowAllMember 是否显示所有成员
--]]
function UnionRankMediator:GetValidMemberNum(isShowAllMember)
	if next(self.unionRankDatas) ~= nil then
		if not isShowAllMember then
			for i,v in ipairs(self.unionRankDatas) do
				if checkint(v.score) <= 0 then
					return i - 1
				end
			end
		end
		return table.nums(self.unionRankDatas)
	else
		return 0
	end
end

function UnionRankMediator:RankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(862, 112)

    if pCell == nil then
        pCell = RankPopularityCell.new(cSize)
    end
	xTry(function()
		local datas = self.unionRankDatas[index]
		pCell.avatarIcon:RefreshSelf({level = datas.playerLevel, avatar = datas.playerAvatar, avatarFrame = datas.playerAvatarFrame})
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			if checkint(gameMgr:GetUserInfo().playerId) ~=  checkint(datas.playerId) then
				uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = datas.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(datas.playerId)})
			end
		end)
		pCell.nameLabel:setString(datas.playerName)
		pCell.scoreNum:setString(datas.score)
		pCell.rankNum:setString(index)
		if pCell.scoreNum:getContentSize().width >= 130 then
			local scale = 130/pCell.scoreNum:getContentSize().width
			pCell.scoreNum:setScale(scale)
		end

		if checkint(index) >= 1 and checkint(index) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(index) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end
		-- 额外字段

		if checkint(self.selectedRank) > 0 then
			-- 神兽排行榜
			if datas.godBeastDailyDamage and type(datas.godBeastDailyDamage) == 'table' then
				pCell.extraLabel:setString(tostring(checkint(datas.godBeastDailyDamage[tostring(self.selectedRank)])))
			else
				pCell.extraLabel:setString('0')
			end
		elseif checkint(self.selectedRank) == UnionRankTypes.BUILD_TIMES_DAILY then
			-- 每日建造榜
			local extraStr = ''
			for i=1, 3 do
				if i ~= 3 then
					extraStr = extraStr .. tostring(datas.dailyBuildTimes[tostring(i)] or 0) .. '/'
				else
					extraStr = extraStr .. tostring(datas.dailyBuildTimes[tostring(i)] or 0)
				end
			end
			pCell.extraLabel:setString(extraStr)
		elseif checkint(self.selectedRank) == UnionRankTypes.FEED_TIMES_DAILY then
			-- 每日喂食榜
			pCell.extraLabel:setString(datas.dailyFeedPetSatiety)
		else
			pCell.extraLabel:setString('')
		end
	end,__G__TRACKBACK__)
    return pCell
end
--[[
提示按钮回调
--]]
function UnionRankMediator:TipsIconCallback( sender )
	
end
--[[
根据排行榜类型获取index
--]]
function UnionRankMediator:GetIndexByUnionRankTypes( unionRankTypes )
	local index = nil
	for i,v in ipairs(RANK) do
		if checkint(v.rankTypes) == checkint(unionRankTypes) then
			index = i
		end
	end
	return index
end
--[[
根据排行榜类型获取排行榜信息
--]]
function UnionRankMediator:GetRankDatasByRankTypes( unionRankTypes )
	dump(RANK)
	for i,v in ipairs(RANK) do
		if v.child and next(v.child) ~= nil then
			-- 存在子页签
			for _, childDatas in ipairs(v.child) do
				if checkint(childDatas.rankTypes) == checkint(unionRankTypes) then
					return childDatas
				end
			end
		else
			-- 不存在子页签
			if checkint(v.rankTypes) == checkint(unionRankTypes) then
				return v
			end
		end
	end
end
function UnionRankMediator:EnterLayer()
 	self:SendSignal(POST.UNION_RANK.cmdName)
end
function UnionRankMediator:OnRegist(  )
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	regPost(POST.UNION_RANK)
	self:EnterLayer()
end

function UnionRankMediator:OnUnRegist(  )
	print( "OnUnRegist" )
	local scene = uiMgr:GetCurrentScene()
	if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
		scene:RemoveDialog(self:GetViewComponent())
	end
	unregPost(POST.UNION_RANK)
end
return UnionRankMediator
