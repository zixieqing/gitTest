--[[
查看奖励列表UI
@params showTips         是否显示提示
@params showConfDefName  是否使用配表默认名称
--]]
local CommonDialog = require('common.CommonDialog')
local LobbyRewardListView = class('LobbyRewardListView', CommonDialog)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function LobbyRewardListView:InitialUI()
	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_4.png'), 0, 0, {scale9 = true, size = cc.size(458,469)})
		local bgSize = bg:getContentSize()
		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)
		-- title 
		local titleStr = self.args.title or __('本周排行榜奖励')
    	local title = display.newButton(bgSize.width/2, bgSize.height - 4, {n = _res('ui/common/common_bg_title_2.png'), enable = false,scale9 = true })
    	display.commonUIParams(title, {ap = display.CENTER_TOP})
    	display.commonLabelParams(title, fontWithColor(1,{fontSize = 24, text = titleStr, color = 'ffffff',offset = cc.p(0, -2) , paddingW = 20}))
    	view:addChild(title, 5)
    	-- tips
    	local tipsLabel = display.newLabel(bgSize.width/2, bgSize.height - 54, fontWithColor(15, {text = __('(奖励通过邮件发放)')}))
    	view:addChild(tipsLabel, 10)
    	tipsLabel:setVisible(false)
    	local gridViewHeight = 416
    	if self.args.showTips then
    		tipsLabel:setVisible(true)
    		gridViewHeight = gridViewHeight - 18
    	end
    	if self.args.msg then
    		local msgLabel = display.newLabel(bgSize.width/2, bgSize.height - 76, fontWithColor(15, {text = self.args.msg ,reqW =430 }))
    		view:addChild(msgLabel, 10)
    		gridViewHeight = gridViewHeight - 22
    	end
		local gridViewSize = cc.size(bgSize.width, gridViewHeight)
		local gridViewCellSize = cc.size(bgSize.width, 94)
		local gridView = CGridView:create(gridViewSize)
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setColumns(1)
		view:addChild(gridView, 5)
		gridView:setAnchorPoint(cc.p(0.5, 0))
		gridView:setPosition(cc.p(bgSize.width/2, 5))
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.RewardListDataSource))
		local rewardDatas = self.args.rewardsDatas
		gridView:setCountOfCell(table.nums(rewardDatas))
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
function LobbyRewardListView:RewardListDataSource( p_convertview,idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(458, 94)
    if pCell == nil then
        pCell = require('home.LobbyRewardListCell').new(cSize)
    end
	xTry(function()
		local rewardDatas = self.args.rewardsDatas[tostring(index)] or self.args.rewardsDatas[index]
		local placeDescr = self:GetRankRewardDescrByConfig(rewardDatas)
		pCell.numLabel:setString(placeDescr)

		if pCell.eventNode:getChildByTag(4545) then
			pCell.eventNode:getChildByTag(4545):removeFromParent()
		end
		local layout = CLayout:create(cc.size(458, 94))
		layout:setTag(4545)
		layout:setPosition(utils.getLocalCenter(pCell.eventNode))
		pCell.eventNode:addChild(layout, 10)
		for i,v in ipairs(rewardDatas.rewards or rewardDatas.reward) do
			local function callBack(sender)
				AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end
			local goodsNode = require('common.GoodNode').new({id = v.goodsId, showAmount = true, callBack = callBack, num = v.num})
			goodsNode:setPosition(cc.p(160 + (i-1)*82, 47))
			goodsNode:setScale(0.7)
			layout:addChild(goodsNode, 10)
		end
	end,__G__TRACKBACK__)
    return pCell
end
--[[
根据排行榜奖励配置获取名次描述
@params rewardConfig 排行榜奖励配置
@return str string 名次描述
--]]
function LobbyRewardListView:GetRankRewardDescrByConfig(rewardConfig)
	local str = '???'
	
	if nil == rewardConfig then return str end
	
	if self.args.showConfDefName then
		return rewardConfig.name or rewardConfig.title or str
	end

	local upperLimit = checkint(rewardConfig.upperLimit)
	local lowerLimit = checkint(rewardConfig.lowerLimit)

	if upperLimit == lowerLimit then
		-- 前三名
		str = string.fmt(__('第_num_名'), {['_num_'] = upperLimit})
	elseif -1 == lowerLimit then
		-- 上限-1代表无穷大
		-- str = string.fmt(__('_num_以后'), {['_num_'] = upperLimit})
		str = __('其他')
	else
		-- 正常区间
		str = tostring(upperLimit) .. '~' .. tostring(lowerLimit)
	end

	return str
end
return LobbyRewardListView
