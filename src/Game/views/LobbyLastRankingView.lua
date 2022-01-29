--[[
上周排行榜页面UI
--]]
local CommonDialog = require('common.CommonDialog')
local LobbyLastRankingView = class('LobbyLastRankingView', CommonDialog)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function LobbyLastRankingView:InitialUI()
	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_4.png'), 0, 0, {scale9 = true, size = cc.size(458,469)})
		local bgSize = bg:getContentSize()
		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)
		-- title 
    	local title = display.newButton(bgSize.width/2, bgSize.height - 4, {n = _res('ui/common/common_bg_title_2.png'), scale9 = true ,  enable = false})
    	display.commonUIParams(title, {ap = display.CENTER_TOP})
    	display.commonLabelParams(title, fontWithColor(1,{fontSize = 24, text = self.args.title or __('上周排行榜'), paddingW = 20,  color = 'ffffff',offset = cc.p(0, -2)}))
    	view:addChild(title, 5)
		local gridViewSize = cc.size(bgSize.width, 410)
		local gridViewCellSize = cc.size(bgSize.width, 52)
		local gridView = CGridView:create(gridViewSize)
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setColumns(1)
		view:addChild(gridView, 5)
		gridView:setAnchorPoint(cc.p(0.5, 0))
		gridView:setPosition(cc.p(bgSize.width/2, 6))
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.LastRankingDataSource))
		gridView:setCountOfCell(table.nums(self.args.lastRank))
		gridView:reloadData()
		return {
			view        = view, 
			gridView    = gridView,
			bgSize		= bgSize
		}
	end
	xTry(function ( )
		self.viewData = CreateView( )

	end, __G__TRACKBACK__)
end
function LobbyLastRankingView:LastRankingDataSource( p_convertview,idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(458, 52)
    if pCell == nil then
        pCell = require('home.LobbyLastRankingCell').new(cSize)
    end
	xTry(function()
		local datas = self.args.lastRank[index]
		if self.args.iconPath then
			pCell.scoreIcon:setTexture(self.args.iconPath)
			pCell.scoreIcon:setVisible(true)
		else
			pCell.scoreIcon:setVisible(false)
		end
		if self.args.iconStr then
			pCell.iconLabel:setString(tostring(self.args.iconStr))
			pCell.iconLabel:setVisible(true)
		else
			pCell.iconLabel:setVisible(false)
		end
		if not self.args.iconPath and not self.args.iconStr then
			pCell.scoreNum:setPositionX(430)
		end
		pCell.nameLabel:setString(datas.playerName)
		pCell.rankNum:setString(datas.rank)
		if checkint(datas.rank) >= 1 and checkint(datas.rank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/lobby/information/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end
		if checkint(datas.score) < 100000 then
			pCell.scoreNum:setString(checkint(datas.score))
		else
			pCell.scoreNum:setString(string.fmt(__('_num_万'), {['_num_'] = CommonUtils.GetPreciseDecimal(checkint(datas.score)/10000, 1)}))
		end
	end,__G__TRACKBACK__)
    return pCell
end
return LobbyLastRankingView
