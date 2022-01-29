--[[
餐厅信息知名度排行榜view
--]]
local LobbyPopularityRankingView = class('LobbyPopularityRankingView', function ()
	local node = CLayout:create(cc.size(753, 556))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.LobbyPopularityRankingView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
	local size = cc.size(753, 556)
	local view = CLayout:create(size)
	local bg = display.newImageView(_res('ui/common/commcon_bg_text.png'), 0, 8, {ap = cc.p(0, 0), scale9 = true, size = cc.size(753, 546)})
	view:addChild(bg)
	local tipsIcon = display.newButton(25, 526, {n = _res('ui/common/common_btn_tips.png')})
	view:addChild(tipsIcon, 10)
	local nameLabel = display.newLabel(50, 526, fontWithColor(6, {text = __('当前餐厅规模：'), ap = cc.p(0, 0.5)}))
	view:addChild(nameLabel, 10)

	local rankLabel = display.newLabel(200, 526, fontWithColor(11, {text = string.fmt(__('_num_级餐厅'), {['_num_'] = gameMgr:GetUserInfo().restaurantLevel}), ap = cc.p(0, 0.5)}))
	view:addChild(rankLabel, 10)
	local titleBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_rank_title.png'), size.width/2, 440)
	view:addChild(titleBg, 5)
	local titleLabel = display.newButton(size.width/2, 474, {n = _res('ui/common/common_title_6.png')})
	view:addChild(titleLabel, 10)
	display.commonLabelParams(titleLabel, {text = __('本周知名度排行榜'), fontSize = 22, color = '#ffffff'})
	local endLabel = display.newLabel(size.width/2, 437, fontWithColor(6, {text = __('离结束还有')}))
	view:addChild(endLabel, 10)
	local timeLabel = display.newRichLabel(size.width/2, 405)
	view:addChild(timeLabel, 10)
	local lastWeekRankBtn = display.newButton(size.width - 5, 472, {tag = 3001, ap = cc.p(1, 0.5), n = _res('ui/common/common_btn_white_default_s.png')})
	view:addChild(lastWeekRankBtn, 10)
	display.commonLabelParams(lastWeekRankBtn, fontWithColor(16, {text = __('上周排行榜')}))
	local rewardBtn = display.newButton(size.width - 5, 415, {tag = 3002, ap = cc.p(1, 0.5), n = _res('ui/common/common_btn_orange.png')})
	view:addChild(rewardBtn, 10)
	display.commonLabelParams(rewardBtn, fontWithColor(14, {text = __('查看奖励')}))
	local gridViewSize = cc.size(size.width, 325)
	local gridViewCellSize = cc.size(size.width, 50)
	local gridView = CGridView:create(gridViewSize)
	gridView:setSizeOfCell(gridViewCellSize)
	gridView:setColumns(1)
	gridView:setAutoRelocate(true)
	view:addChild(gridView, 5)
	gridView:setPosition(cc.p(size.width/2, 220))
	local playerRankBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_rank_mine.png'), size.width/2, 33)
	view:addChild(playerRankBg, 5)
	local playerRankNumBg = display.newImageView('ui/home/lobby/information/restaurant_info_bg_rank_num1.png', 50, 33)
	view:addChild(playerRankNumBg, 7)
	local playerRankNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '1')
	playerRankNum:setHorizontalAlignment(display.TAR)
	playerRankNum:setPosition(50, 30)
	playerRankNum:setScale(0.7)
	view:addChild(playerRankNum, 10)
	local playerRankLabel = display.newLabel(50, 33, {text = __('未入榜'), fontSize = 22, color = '#ba5c5c'})
	view:addChild(playerRankLabel, 10)
	local playerName = display.newLabel(100, 33, {ap = cc.p(0, 0.5), text = '', fontSize = 22, color = '#a87543'})
	view:addChild(playerName, 10)

	local scoreBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_rank_awareness.png'), 650, 33)
	view:addChild(scoreBg, 5)
	local scoreIcon = display.newImageView(_res('ui/home/lobby/information/restaurant_ico_info.png'), 700, 33)
	view:addChild(scoreIcon, 10)
	scoreIcon:setScale(0.5)
	local scoreNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	scoreNum:setHorizontalAlignment(display.TAR)
	scoreNum:setPosition(680, 33)
	scoreNum:setAnchorPoint(cc.p(1, 0.5))
	view:addChild(scoreNum, 10)
	scoreNum:setScale(0.6)
	return {
		view 			 = view,
		gridView 		 = gridView,
		lastWeekRankBtn  = lastWeekRankBtn,
		rewardBtn	     = rewardBtn,
		timeLabel        = timeLabel,
		playerRankNum	 = playerRankNum,
		playerRankLabel  = playerRankLabel,
		playerRankBg     = playerRankBg,
		playerRankNumBg  = playerRankNumBg,
		playerName		 = playerName,
		scoreNum		 = scoreNum
	}
end

function LobbyPopularityRankingView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end

return LobbyPopularityRankingView