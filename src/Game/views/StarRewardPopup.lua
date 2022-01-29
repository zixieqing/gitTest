--[[
满星奖励弹窗
@params starRewardsData table 星级奖励信息
@params star int 当前星星数
@params serverRewardsData table 服务器返回的星级奖励数据
@params chapterId int 章节
@params diffType DifficultyLevel 难度
--]]
local CommonDialog = require('common.CommonDialog')
local StarRewardPopup = class('StarRewardPopup', CommonDialog)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

--[[
override
initui
--]]
function StarRewardPopup:InitialUI()

	local function CreateView()

		local rewardsData = self.args.starRewardsData
		local serverRewardsData = self.args.serverRewardsData
		local star = self.args.star
		local diffType = self.args.diffType

		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_3.png'), 0, 0)
		local bgSize = bg:getContentSize()

		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)

		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg,
			{ttf = true, font = TTF_GAME_FONT,text = __('满星奖励'),
			fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color,
			offset = cc.p(0, -2)})
		bg:addChild(titleBg)

		-- -- close btn
		-- local closeBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_quit.png'), animaion = false, cb = handler(self, self.CloseHandler)})
		-- display.commonUIParams(closeBtn, {po = cc.p(bgSize.width - 10 + closeBtn:getContentSize().width * 0.5, bgSize.height - closeBtn:getContentSize().height * 0.5 - 3)})
		-- view:addChild(closeBtn, 4)

		-- list
		local listSize = cc.size(bgSize.width - 35, bgSize.height - 52)
		local rewardList = CListView:create(listSize)
		rewardList:setDirection(eScrollViewDirectionVertical)
		rewardList:setAnchorPoint(cc.p(0.5, 0))
		rewardList:setPosition(bgSize.width * 0.5, 9)
		view:addChild(rewardList, 10)

		local cellSize = cc.size(listSize.width, 120)
		------------ 本地星级奖励逻辑 ------------

		------------ 服务器星级奖励逻辑 ------------
		local drawBtns = {}
		local drawLabels = {}
		for i,v in ipairs(serverRewardsData) do
			if checkint(v.difficulty) == diffType then
				local rewardConf = CommonUtils.GetConfig('quest', 'cityReward', v.id)
				local cell = display.newLayer(0, 0, {size = cellSize})

				local rewardBg = display.newImageView(_res('ui/common/common_bg_list.png'), cellSize.width * 0.5, cellSize.height * 0.5,
					{scale9 = true, size = cc.size(500, 115)})
				cell:addChild(rewardBg)

				local goodsIconBg = display.newButton(0, 0, {n = _res('ui/common/common_frame_goods_5.png'), cb = handler(self, self.ShowRewardDetailCallback)})
				goodsIconBg:setScale(0.75)
				display.commonUIParams(goodsIconBg, {po = cc.p(65, cellSize.height * 0.5)})
				cell:addChild(goodsIconBg, 5)
				goodsIconBg:setTag(checkint(v.id))

				local rewardIcon = display.newImageView(_res('ui/map/map_ico_star_cup.png'), utils.getLocalCenter(goodsIconBg).x, utils.getLocalCenter(goodsIconBg).y)
				rewardIcon:setScale(0.75)
				goodsIconBg:addChild(rewardIcon)

				local descrLabel = display.newLabel(120, cellSize.height * 0.5,
					fontWithColor(8,{text = self:GetRewardDescr(v.id, star),ap = cc.p(0, 0.5), w = 250, h = 80}))
				cell:addChild(descrLabel, 5)

				-- 更新状态按钮
				local drawBtn = display.newButton(0, 0, {
					n = _res('ui/common/common_btn_orange.png'),
					d = _res('ui/common/common_btn_orange_disable.png'),
					cb = handler(self, self.DrawRewardCallback), scale9 = true, size = cc.size(124, 62)
				})
				display.commonUIParams(drawBtn, {po = cc.p(cellSize.width - 85, cellSize.height * 0.5)})
				cell:addChild(drawBtn, 10)
				drawBtn:setTag(checkint(v.id))
				drawBtns[tostring(v.id)] = drawBtn

				-- 状态文字
				local drawLabel = display.newLabel(drawBtn:getPositionX(), drawBtn:getPositionY(),
					fontWithColor(14,{text = __('领取')}))
				cell:addChild(drawLabel, 15)
				drawLabels[tostring(v.id)] = drawLabel

				if 0 == v.status then
					drawBtn:setEnabled(false)
					drawLabel:setString(__('未完成'))
				end

				if 1 == v.hasDrawn then
					drawBtn:setVisible(false)
					display.commonLabelParams(drawLabel,
						fontWithColor(10,{text = __('已领取')}))
				end
                local lwidth = display.getLabelContentSize(drawLabel).width
				lwidth = 124
				display.commonLabelParams(drawLabel , {reqH = 45, w = 130,hAlign = display.TAC})
                drawBtn:setContentSize(cc.size(lwidth + 16, 62))

				rewardList:insertNodeAtLast(cell)
			end
		end
		------------ 服务器星级奖励逻辑 ------------

		rewardList:reloadData()

		return {
			view = view,
			drawBtns = drawBtns,
			drawLabels = drawLabels,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end
--[[
领取奖励按钮回调
--]]
function StarRewardPopup:DrawRewardCallback(sender)
	local rewardId = sender:getTag()
	local requestData = {
		cityId = self.args.chapterId,
		cityRewardId = rewardId
	}
	AppFacade.GetInstance():DispatchObservers("DRAW_CITY_STAR_REWARD", {requestData = requestData, callback = function ()
		if self.viewData then
			if self.viewData.drawBtns and self.viewData.drawBtns[tostring(rewardId)] then
				self.viewData.drawBtns[tostring(rewardId)]:setVisible(false)
			end
			if self.viewData.drawLabels and self.viewData.drawLabels[tostring(rewardId)] then 
				display.commonLabelParams(self.viewData.drawLabels[tostring(rewardId)], fontWithColor(10,{text = __('已领取')}))
			end
		end
	end})
end
--[[
获取满星奖励说明
@params rewardId int 星级奖励id
@params progress int 完成度
@return str string 说明string
--]]
function StarRewardPopup:GetRewardDescr(rewardId, progress)
	local rewardConf = CommonUtils.GetConfig('quest', 'cityReward', rewardId)
	local diffStr = {
		['1'] = __('普通'),
		['2'] = __('史诗'),
		['3'] = __('团本')
	}
	local str = string.fmt(__('_difficulty_第_num_章获得_pro_/_count_枚星星'), {_difficulty_ = diffStr[rewardConf.difficulty],
        _num_ = rewardConf.cityId, _pro_ = progress, _count_ = rewardConf.starNum})
	return str
end
--[[
显示奖励详情
--]]
function StarRewardPopup:ShowRewardDetailCallback(sender)
	local tag = sender:getTag()
	local rewardConf = CommonUtils.GetConfig('quest', 'cityReward', tag)
	AppFacade.GetInstance():DispatchObservers("SHOW_CITY_STAR_REWARD_DETAIL", {
		rewards = rewardConf.rewards
	})
end


return StarRewardPopup
