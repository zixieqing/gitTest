--[[
奖励预览弹窗
@params table {
	rewards table 奖励道具id集
	viewType int  视图类型
	listTipText table 列表提示文字
}
--]]
local CommonDialog = require('common.CommonDialog')
local RewardDetailPopup = class('RewardDetailPopup', CommonDialog)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local VIEW_TYPE = {
	QUEST_TYPE         = 1,
	TASTING_TOUR_TYPE  = 2,
}

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
override
initui
--]]
function RewardDetailPopup:InitialUI()

	
	local data = self:InitData()
	local size = data.size
	self.rewards = self.args.rewards
	self.cellScale = data.cellScale
	local function CreateView()

		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_8.png'), 0, 0, {scale9 = true, size = size})
		
		-- view
		local view = display.newLayer(0, 0, {size = size, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = utils.getLocalCenter(bg)})
		view:addChild(bg, 1)

		local gridViewSize = cc.size(size.width - 80, size.height - 27)
		local gridViewPosY = nil
		if data.viewType == VIEW_TYPE.TASTING_TOUR_TYPE then
			local listTipText = data.listTipText
			-- local listTip = display.newLabel(40, size.height - 30, fontWithColor(4, {fontSize = 18, ap = display.LEFT_TOP, text = listTipText, w = 18 * 13 + 5}))
			-- view:addChild(listTip, 1)

			local listTip = display.newRichLabel(size.width / 2, size.height - 30, {ap = display.CENTER_TOP, r = true, c = listTipText})
			view:addChild(listTip, 1)
			local listTipSize = display.getLabelContentSize(listTip)

			gridViewSize = cc.size(size.width - 80, listTip:getPositionY() - listTipSize.height - 20)
			gridViewPosY = listTip:getPositionY() - listTipSize.height - 5
			local listBg = display.newImageView(_res('ui/common/commcon_bg_text.png'), size.width / 2, listTip:getPositionY() - listTipSize.height - 5, {ap = display.CENTER_TOP, scale9 = true, size = gridViewSize})
			view:addChild(listBg, 1)
		end

		-- gridView
		local rewardsAmount = table.nums(self.rewards)
		local cellPerLine = data.cellPerLine
		local cellSize = cc.size(gridViewSize.width / cellPerLine, 95)
		local gridView = CGridView:create(gridViewSize)
		gridView:setAnchorPoint(cc.p(0.5, 1))
		gridView:setPosition(cc.p(size.width * 0.5, gridViewPosY or gridViewSize.height))
		view:addChild(gridView, 10)
		-- gridView:setBackgroundColor(cc.c4b(255, 128, 0, 128))

		gridView:setCountOfCell(rewardsAmount)
		gridView:setSizeOfCell(cellSize)
		gridView:setColumns(cellPerLine)
		gridView:setAutoRelocate(false)
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataAdapter))
		gridView:setDragable(data.isDragable)

		return {
			view = view,
			gridView = gridView
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	self.viewData.gridView:reloadData()

end

function RewardDetailPopup:InitData()
	local data = {}
	local viewType = self.args.viewType or VIEW_TYPE.QUEST_TYPE
	data.rewards = self.args.rewards
	data.viewType = viewType
	if viewType == VIEW_TYPE.TASTING_TOUR_TYPE then
		data.cellScale = 0.66
		data.listTipText = self.args.listTipText
		data.size = cc.size(435, 308)
		data.cellPerLine = 4
		data.isDragable = table.nums(data.rewards) > 3
	elseif viewType == VIEW_TYPE.QUEST_TYPE then
		data.cellScale = 0.75
		data.size = cc.size(435, 308)
		data.cellPerLine = 4
		data.isDragable = table.nums(data.rewards) > data.cellPerLine * 3
	end
	return data
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
function RewardDetailPopup:GridViewDataAdapter(c, i)
	local cell = c
	local index = i + 1
	local rewardData = self.rewards[index]

	local goodNode = nil
	if nil == cell then
		cell = CGridViewCell:new()
		cell:setContentSize(self.viewData.gridView:getSizeOfCell())

		goodNode = require('common.GoodNode').new({
			id = rewardData.goodsId,
			amount = rewardData.num,
			showAmount = (rewardData.num and checkint(rewardData.num) > 0),
			callBack = function (sender)
				local index_ = sender:getParent():getTag()
				uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = self.rewards[index_].goodsId, type = 1})
			end
		})
		goodNode:setScale(self.cellScale or 0.75)
		display.commonUIParams(goodNode, {po = utils.getLocalCenter(cell)})
		cell:addChild(goodNode)
		goodNode:setTag(3)
	else
		cell:getChildByTag(3):RefreshSelf({
			id = rewardData.goodsId,
			amount = rewardData.num,
			showAmount = (rewardData.num and checkint(rewardData.num) > 0)})
	end

	cell:setTag(index)

	return cell
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

return RewardDetailPopup
