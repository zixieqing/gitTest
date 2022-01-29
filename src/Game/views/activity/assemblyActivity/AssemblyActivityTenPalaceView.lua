--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 十宫格View
--]]
local AssemblyActivityTenPalaceView = class('AssemblyActivityTenPalaceView', function ()
    local node = CLayout:create(display.size)
    node.name = 'AssemblyActivityTenPalaceView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
	BTN_COMMON_NORMAL 		= 'ui/common/common_btn_orange_big.png',
	BTN_COMMON_DISABLE 		= 'ui/common/common_btn_big_orange_disabled_2.png',
	BTN_WHITE_NORMAL 		= 'ui/common/common_btn_white_default.png',
	BTN_WHITE_DISABLE 		= 'ui/common/common_btn_orange_disable.png',
	BG                      = _res('ui/home/activity/assemblyActivity/tenPalace/summon_nine_ball_1.jpg'),
	COMMON_TITLE            = _res('ui/common/common_title.png'),
    COMMON_TIPS             = _res('ui/common/common_btn_tips.png'),
	COMMON_BTN_BACK         = _res('ui/common/common_btn_back.png'),
	DRAW_CELL_PREVIEW_BTN   = _res('ui/home/capsuleNew/home/summon_btn_preview.png'),
}

local PalaceCellWidth = 202
local PalaceCellHeight = 174
local PalaceBigCellWidth = 404

-- 格子行列配置
local CellRowColConfig = {
	[1] = {row = 1, col = 1.5},
	[2] = {row = 1, col = 3},
	[3] = {row = 1, col = 4},
	[4] = {row = 2, col = 4},
	[5] = {row = 3, col = 4},
	[6] = {row = 3, col = 3},
	[7] = {row = 3, col = 2},
	[8] = {row = 3, col = 1},
	[9] = {row = 2, col = 1}
}

-- 老虎机转圈的保底圈数
local BanditJumpRound = 5

function AssemblyActivityTenPalaceView:ctor(...)
	local args = unpack({...})
	self.activityId = args.activityId

	self.rewardsFixedIndex = {}
	self.rewardsData = nil
	self.hasRewards = true
	self.hasDrawnBigReward = true
	self.selectedCellIndex = nil
	self.rewardSpineAni = nil

	self:InitUI()
end
--[[
初始化ui
--]]
function AssemblyActivityTenPalaceView:InitUI()
	local size = display.size
	display.commonUIParams(self, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, size.height * 0.5)})

	local function CreateView()

		local bgMaskSize = cc.size(816, 530)
		local bg = display.newImageView(RES_DICT.BG, display.cx, display.cy)
		self:addChild(bg, -1)
		-- 返回按钮
		local backBtn = display.newButton(display.SAFE_L + 15, display.height - 55,
        {
            ap = display.LEFT_CENTER,
            n = RES_DICT.COMMON_BTN_BACK,
            scale9 = true, size = cc.size(90, 70),
            enable = true,
        })
        self:addChild(backBtn, 10)
        -- 标题板
        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE, enable = true,ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('返场狂欢会'), fontSize = 30, color = '#473227',offset = cc.p(0,-10)})
		self:addChild(tabNameLabel, 20)
		-- 提示按钮 
        local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 29)
		tabNameLabel:addChild(tabtitleTips, 1)
		-- CommonMoneyBar
	    local moneyBar = require("common.CommonMoneyBar").new({isEnableGain = true})
		self:addChild(moneyBar, 20)
		-- 预览按钮
		local previewBtn  = display.newButton(display.SAFE_R - 0, size.height - 60, {n = RES_DICT.DRAW_CELL_PREVIEW_BTN, ap = display.RIGHT_TOP})
		local previewSize = previewBtn:getContentSize()
		display.commonLabelParams(previewBtn, fontWithColor(19, {text = __('内容一览'), ap = display.RIGHT_CENTER, offset = cc.p(previewSize.width/2 - 100, 0)}))
		previewBtn:addChild(display.newImageView(RES_DICT.COMMON_TIPS, previewSize.width - 60, previewSize.height/2))
		self:addChild(previewBtn, 10)
		-- 九宫格背景层
		local goodsBgLayer = display.newLayer(0, 0, {size = bgMaskSize})
		self:addChild(goodsBgLayer, 5)

		-- 下一轮按钮
		local nextRoundBg = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg_next_turn.png'), 0, 0)
		self:addChild(nextRoundBg)

		local nextRoundButton = display.newButton(0, 0, {
			n = _res(RES_DICT.BTN_WHITE_NORMAL),
			cb = handler(self, self.NextRoundClickHandler)
		})
		self:addChild(nextRoundButton)
		display.commonLabelParams(nextRoundButton, fontWithColor('4', {text = __('下一轮')}))

		local nextRoundIcon = display.newNSprite(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_ico_arrow.png'), 0, 0)
		self:addChild(nextRoundIcon)

		------------ 九宫格内部 ------------
		-- 九宫格透明底
		local goodsBgMask = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg.png'), 0, 0, {size = bgMaskSize, scale9 = true})
		display.commonUIParams(goodsBgMask, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(goodsBgLayer)})
		goodsBgLayer:addChild(goodsBgMask)

		-- 中间抽奖底
		local centerDrawBg = display.newNSprite(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg_operate.png'), 0, 0)
		display.commonUIParams(centerDrawBg, {po = utils.getLocalCenter(goodsBgLayer)})
		goodsBgLayer:addChild(centerDrawBg, 5)

		-- 按钮
		local drawButton = display.newButton(0, 0, {
			n = _res(RES_DICT.BTN_COMMON_NORMAL),
			cb = handler(self, self.DrawOneClickHandler)
		})
		display.commonUIParams(drawButton, {po = cc.p(centerDrawBg:getPositionX(), centerDrawBg:getPositionY() - 5)})
		goodsBgLayer:addChild(drawButton, 10)

		local drawBtnLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('抽 奖')}))
		display.commonUIParams(drawBtnLabel, {ap = cc.p(0.5, 0), po = cc.p(
			drawButton:getContentSize().width * 0.5,
			drawButton:getContentSize().height * 0.5 - 2
		)})
		drawButton:addChild(drawBtnLabel)

		local drawBtnTimeLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('x1次')}))
		display.commonUIParams(drawBtnTimeLabel, {ap = cc.p(0.5, 1), po = cc.p(
			drawButton:getContentSize().width * 0.5,
			drawButton:getContentSize().height * 0.5 - 4
		)})
		drawButton:addChild(drawBtnTimeLabel)

		-- 按钮标题
		local drawTitleBg = display.newImageView(_res('ui/common/common_title_5.png'), 0, 0, {scale9 = true})
		display.commonUIParams(drawTitleBg, {po = cc.p(
			drawButton:getPositionX(),
			centerDrawBg:getPositionY() + centerDrawBg:getContentSize().height * 0.5 - drawTitleBg:getContentSize().height * 0.5 - 10
		)})
		goodsBgLayer:addChild(drawTitleBg, 10)

		local drawTitleLabel = display.newLabel(0, 0, fontWithColor('4'))
		display.commonUIParams(drawTitleLabel, {ap = cc.p(0.5, 0.5), po = cc.p(
			drawTitleBg:getContentSize().width * 0.5,
			drawTitleBg:getContentSize().height * 0.5
		)})
		drawTitleBg:addChild(drawTitleLabel)

		-- 消耗
		local costLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('消耗')}))
		goodsBgLayer:addChild(costLabel, 10)

		local costGoodsLabel = display.newLabel(0, 0, fontWithColor('14', {text = ''}))
		goodsBgLayer:addChild(costGoodsLabel, 10)

		local iconScale = 0.2
		local costGoodsIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 0, 0)
		costGoodsIcon:setScale(iconScale)
		goodsBgLayer:addChild(costGoodsIcon, 10)
		------------ 九宫格内部 ------------

		return {
			goodsBgLayer = goodsBgLayer,
			bgMaskSize = bgMaskSize,
			nextRoundBg = nextRoundBg,
			nextRoundButton = nextRoundButton,
			nextRoundIcon = nextRoundIcon,
			centerDrawBg = centerDrawBg,
			drawButton = drawButton,
			drawTitleBg = drawTitleBg,
			drawTitleLabel = drawTitleLabel,
			costLabel = costLabel,
			costGoodsLabel = costGoodsLabel,
			costGoodsIcon = costGoodsIcon,
			palaceCells = {},
			backBtn             = backBtn,
			tabNameLabel        = tabNameLabel,
			previewBtn          = previewBtn,
			moneyBar   	 	    = moneyBar,
		}
	end
    -- eaterLayer
	local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 0), enable = true})
	self:addChild(eaterLayer, -1)
	self.eaterLayer = eaterLayer
	xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

	self:RefreshDrawRoundLabel(1)
	self:RefreshCostInfo(DIAMOND_ID, 20)
	self:InitNinePalaceCells()
end
--[[
初始化货币栏
--]]
function AssemblyActivityTenPalaceView:InitMoneyBar( moneyIdMap )
	local moneyIdList = table.keys(moneyIdMap)
    self.viewData.moneyBar:reloadMoneyBar(moneyIdList)
end
--[[
初始化九宫格cell
--]]
function AssemblyActivityTenPalaceView:InitNinePalaceCells()
	local parentNode = self.viewData.goodsBgLayer

	local cellAmount = 9

	for i = 1, cellAmount do

		local cellData = nil

		if 1 == i then
			-- 第一格是大奖
			cellData = self:GetABigNinePalaceCell()
		else
			-- 其他是小奖
			cellData = self:GetANormalNinePalaceCell()
		end

		local pos = self:GetCellPositionByCellIndex(i)

		local cellNode = cellData.cellBgLayer
		display.commonUIParams(cellNode, {ap = cc.p(0.5, 0.5), po = pos})
		parentNode:addChild(cellNode, 15)

		local cellBg = cellData.cellBg
		display.commonUIParams(cellBg, {ap = cc.p(0.5, 0.5), po = pos})
		parentNode:addChild(cellBg, 14)

		-- local testNum = display.newLabel(0, 0, fontWithColor('14', {text = i}))
		-- display.commonUIParams(testNum, {po = utils.getLocalCenter(cellNode)})
		-- cellNode:addChild(testNum, 999)

		table.insert(self.viewData.palaceCells, cellData)
	end
end
--[[
获取一个普通的奖品九宫格预览
--]]
function AssemblyActivityTenPalaceView:GetANormalNinePalaceCell()
	local cellBgLayer = display.newLayer(0, 0, {size = cc.size(PalaceCellWidth, PalaceCellHeight)})

	-- 格子背景
	local cellBg = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg_other.png'), 0, 0)

	-- 格子背景层
	local cellBgView = display.newLayer(0, 0, {size = cellBg:getContentSize()})
	display.commonUIParams(cellBgView, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(cellBgLayer)})
	cellBgLayer:addChild(cellBgView)

	-- 格子底
	local cellBgShadow = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg_shardow.png'), 0, 0)
	display.commonUIParams(cellBgShadow, {po = utils.getLocalCenter(cellBg)})
	cellBg:addChild(cellBgShadow, -1)

	-- 获得背景
	local cellMask = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg_mask.png'), 0, 0)
	display.commonUIParams(cellMask, {po = cc.p(cellBgView:getPositionX(), cellBgView:getPositionY())})
	cellBgLayer:addChild(cellMask, 20)
	cellMask:setVisible(false)

	-- 获得提示
	local cellHintBg = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg_text_get.png'), 0, 0)
	display.commonUIParams(cellHintBg, {po = utils.getLocalCenter(cellMask)})
	cellMask:addChild(cellHintBg)

	local cellHintLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('已获得')}))
	display.commonUIParams(cellHintLabel, {po = utils.getLocalCenter(cellHintBg)})
	cellHintBg:addChild(cellHintLabel)
	
	-- 选中框
	local cellSelectedMark = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_ico_wheel.png'), 0, 0)
	display.commonUIParams(cellSelectedMark, {po = cc.p(
		cellBgView:getPositionX(),
		cellBgView:getPositionY()
	)})
	cellBgLayer:addChild(cellSelectedMark, 30)
	cellSelectedMark:setVisible(false)

	local cellData = {
		cellBgLayer 			= cellBgLayer,
		cellBg 					= cellBg,
		cellBgView 				= cellBgView,
		cellMask 				= cellMask,
		cellSelectedMark 		= cellSelectedMark,
		goodsIcon 				= nil,
		goodsNameLabel 			= nil,
		ShowGetRewards 			= function (self, show)
			-- 刷新获得猪状态
			self.cellMask:setVisible(show)
		end,
		RefreshGoodsIcon 		= function (self, goodsId, goodsAmount, viewComponent)
			-- 刷新道具图标
			local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId)
			local goodsIcon = self.goodsIcon
			local goodsNameLabel = self.goodsNameLabel

			local goodsNameStr = string.format('%sx%d', goodsConfig.name, goodsAmount)

			if nil == goodsIcon then

				goodsIcon = require('common.GoodNode').new({
					goodsId = goodsId,
					callBack = function (sender)
						local goodsId_ = sender:getTag()
						AppFacade.GetInstance():DispatchObservers('SHOW_GOODS_DETAIL', viewComponent:GetSignalParams({targetNode = sender, goodsId = goodsId_}))
					end
				})
				display.commonUIParams(goodsIcon, {ap = cc.p(0.5, 0.5), po = cc.p(
					self.cellBgLayer:getContentSize().width * 0.5,
					self.cellBgLayer:getContentSize().height * 0.5 + 10
				)})
				self.cellBgLayer:addChild(goodsIcon, 5)

				goodsNameLabel = display.newLabel(0, 0, fontWithColor('16', {text = goodsNameStr}))
				display.commonUIParams(goodsNameLabel, {ap = cc.p(0.5, 1), po = cc.p(
					goodsIcon:getPositionX(),
					goodsIcon:getPositionY() - goodsIcon:getContentSize().height * 0.5 - 5
				)})
				self.cellBgLayer:addChild(goodsNameLabel, 5)

				local goodsIconBg = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_goods_botton.png'), 0, 0)
				display.commonUIParams(goodsIconBg, {po = cc.p(goodsIcon:getPositionX(), goodsIcon:getPositionY())})
				self.cellBgLayer:addChild(goodsIconBg)

				self.goodsIcon = goodsIcon
				self.goodsNameLabel = goodsNameLabel

			else

				goodsIcon:RefreshSelf({goodsId = goodsId})
				goodsNameLabel:setString(goodsNameStr)

			end

			goodsIcon:setTag(checkint(goodsId))
		end,
		ShowSeletedMark 		= function (self, show)
			-- 不再显示选中状态
			self.cellSelectedMark:setVisible(false)
		end
	}

	return cellData
end
--[[
获取一个大奖的奖品九宫格预览
--]]
function AssemblyActivityTenPalaceView:GetABigNinePalaceCell()
	local cellBgLayer = display.newLayer(0, 0, {size = cc.size(PalaceBigCellWidth, PalaceCellHeight)})

	-- 格子背景
	local cellBg = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg_star.png'), 0, 0)

	local cellBgView = display.newLayer(0, 0, {size = cellBg:getContentSize()})
	display.commonUIParams(cellBgView, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(cellBgLayer)})
	cellBgLayer:addChild(cellBgView)

	-- 格子底
	local cellBgShadow = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg_shardow.png'), 0, 0,
		{scale9 = true, size = cellBg:getContentSize()})
	display.commonUIParams(cellBgShadow, {po = utils.getLocalCenter(cellBg)})
	cellBg:addChild(cellBgShadow, -1)

	-- 大奖提示
	local paddingX = 15
	local bigLabelBg = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg_star_this.png'), 0, 0, {scale9 = true})
	display.commonUIParams(bigLabelBg, {ap = cc.p(0, 0.5), po = cc.p(0, cellBgView:getContentSize().height * 0.5)})
	cellBgView:addChild(bigLabelBg)

	local bigLabel = display.newLabel(0, 0, fontWithColor('5', {text = __('大奖'), color = '#ce3d20'}))
	-- 文字自适应
	local labelContentSize = display.getLabelContentSize(bigLabel)
	if labelContentSize.width > bigLabelBg:getContentSize().width - paddingX * 2 then
		local fixedWidth = labelContentSize.width + paddingX * 2
		bigLabelBg:setContentSize(cc.size(fixedWidth, bigLabelBg:getContentSize().height))
	end
	display.commonUIParams(bigLabel, {ap = cc.p(0.5, 0.5), po = cc.p(
		bigLabelBg:getContentSize().width * 0.5 - 10,
		bigLabelBg:getContentSize().height * 0.5
	)})
	bigLabelBg:addChild(bigLabel)

	-- 获得背景
	local maskSize = cc.size(cellBgView:getContentSize().width, cellBgView:getContentSize().height)
	local cellMask = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg_mask.png'), 0, 0, {scale9 = true, size = maskSize})
	display.commonUIParams(cellMask, {po = cc.p(cellBgView:getPositionX(), cellBgView:getPositionY())})
	cellBgLayer:addChild(cellMask, 20)
	cellMask:setVisible(false)

	-- 获得提示
	local cellHintBg = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_bg_text_get.png'), 0, 0, {scale9 = true})
	cellHintBg:setContentSize(cc.size(cellMask:getContentSize().width, cellHintBg:getContentSize().height))
	display.commonUIParams(cellHintBg, {po = utils.getLocalCenter(cellMask)})
	cellMask:addChild(cellHintBg)

	local cellHintLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('已获得')}))
	display.commonUIParams(cellHintLabel, {po = utils.getLocalCenter(cellHintBg)})
	cellHintBg:addChild(cellHintLabel)

	-- 选中框
	local cellSelectedMark = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_ico_wheel.png'), 0, 0,
		{scale9 = true, size = cc.size(cellBgView:getContentSize().width, cellBgView:getContentSize().height)}
	)
	display.commonUIParams(cellSelectedMark, {po = cc.p(
		cellBgView:getPositionX(),
		cellBgView:getPositionY()
	)})
	cellBgLayer:addChild(cellSelectedMark, 30)
	cellSelectedMark:setVisible(false)

	local cellData = {
		cellBgLayer 			= cellBgLayer,
		cellBg 					= cellBg,
		cellBgView 				= cellBgView,
		cellMask 				= cellMask,
		cellSelectedMark		= cellSelectedMark,
		ShowGetRewards 			= function (self, show)
			-- 刷新获得猪状态
			self.cellMask:setVisible(show)
		end,
		RefreshGoodsIcon 		= function (self, goodsId, goodsAmount, viewComponent)
			-- 刷新道具图标
			local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId)
			local goodsIcon = self.goodsIcon
			local goodsNameLabel = self.goodsNameLabel

			local goodsNameStr = string.format('%sx%d', goodsConfig.name, goodsAmount)

			if nil == goodsIcon then

				goodsIcon = require('common.GoodNode').new({
					goodsId = goodsId,
					callBack = function (sender)
						local goodsId_ = sender:getTag()
						AppFacade.GetInstance():DispatchObservers('SHOW_GOODS_DETAIL', viewComponent:GetSignalParams({targetNode = sender, goodsId = goodsId_}))
					end
				})
				display.commonUIParams(goodsIcon, {ap = cc.p(0.5, 0.5), po = cc.p(
					self.cellBgLayer:getContentSize().width * 0.5,
					self.cellBgLayer:getContentSize().height * 0.5 + 10
				)})
				self.cellBgLayer:addChild(goodsIcon, 5)

				goodsNameLabel = display.newLabel(0, 0, fontWithColor('16', {text = goodsNameStr}))
				display.commonUIParams(goodsNameLabel, {ap = cc.p(0.5, 1), po = cc.p(
					goodsIcon:getPositionX(),
					goodsIcon:getPositionY() - goodsIcon:getContentSize().height * 0.5 - 5
				)})
				self.cellBgLayer:addChild(goodsNameLabel, 5)

				local goodsIconBg = display.newImageView(_res('ui/home/capsuleNew/ninePalace/summon_nine_ball_goods_botton.png'), 0, 0)
				display.commonUIParams(goodsIconBg, {po = cc.p(goodsIcon:getPositionX(), goodsIcon:getPositionY())})
				self.cellBgLayer:addChild(goodsIconBg)

				self.goodsIcon = goodsIcon
				self.goodsNameLabel = goodsNameLabel

			else

				goodsIcon:RefreshSelf({goodsId = goodsId})
				goodsNameLabel:setString(goodsNameStr)

			end

			-- 抖一抖
			local shakeActionTag = 33
			local preShakeAction = goodsIcon:getActionByTag(shakeActionTag)
			if nil ~= preShakeAction then
				goodsIcon:stopAction(preShakeAction)

				-- 重置位置
				display.commonUIParams(goodsIcon, {ap = cc.p(0.5, 0.5), po = cc.p(
					self.cellBgLayer:getContentSize().width * 0.5,
					self.cellBgLayer:getContentSize().height * 0.5 + 10
				)})
			end

			local actionSeq = cc.RepeatForever:create(cc.Sequence:create(
				cc.DelayTime:create(2),
				ShakeAction:create(0.2, 5, 2),
				cc.DelayTime:create(3)
			))
			actionSeq:setTag(shakeActionTag)
			goodsIcon:runAction(actionSeq)

			goodsIcon:setTag(checkint(goodsId))
		end,
		ShowSeletedMark 		= function (self, show)
			self.cellSelectedMark:setVisible(show)
		end
	}

	return cellData
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷一次中间的content位置
--]]
function AssemblyActivityTenPalaceView:FixContentPosition()
	local size = self:getContentSize()
	local bgMaskSize = self.viewData.bgMaskSize

	-- 修正九宫格背景层
	local fixedPos = self:convertToNodeSpace(
		display.getRunningScene():convertToWorldSpace(cc.p(display.width * 0.525, display.height * 0.41))
	)
	display.commonUIParams(self.viewData.goodsBgLayer, {
		ap = cc.p(0.5, 0.5), po = cc.p(fixedPos.x, fixedPos.y)
	})

	local goodsMaskBgPos = cc.p(
		self.viewData.goodsBgLayer:getPositionX(),
		self.viewData.goodsBgLayer:getPositionY()
	)

	-- 修正下一轮按钮位置
	fixedPos = self:convertToNodeSpace(
		display.getRunningScene():convertToWorldSpace(cc.p(display.SAFE_R + 60, 0))
	)
	display.commonUIParams(self.viewData.nextRoundBg, {ap = cc.p(0.5, 0.5), po = cc.p(
		fixedPos.x - self.viewData.nextRoundBg:getContentSize().width * 0.5 + 35,
		self.viewData.goodsBgLayer:getPositionY() - self.viewData.goodsBgLayer:getContentSize().height * 0.5 + self.viewData.nextRoundBg:getContentSize().height * 0.5
	)})
	display.commonUIParams(self.viewData.nextRoundButton, {ap = cc.p(0.5, 0.5), po = cc.p(
		self.viewData.nextRoundBg:getPositionX() - 50,
		self.viewData.nextRoundBg:getPositionY()
	)})
	display.commonUIParams(self.viewData.nextRoundIcon, {ap = cc.p(0.5, 0.5), po = cc.p(
		self.viewData.nextRoundButton:getPositionX() + self.viewData.nextRoundButton:getContentSize().width * 0.5 + 5 + self.viewData.nextRoundIcon:getContentSize().width * 0.5,
		self.viewData.nextRoundButton:getPositionY()
	)})
end
--[[
刷新界面
@params currentRound int 当前第几轮
@params rewards list 奖品
@params costGoodsId int 转一次消耗道具id
@params costGoodsAmount int 转一次消耗道具数量
--]]
function AssemblyActivityTenPalaceView:RefreshUI(currentRound, totalRound, rewards, costGoodsId, costGoodsAmount)
	-- 刷新当前奖品数据
	self:RefreshRewardsData(rewards)
	-- 刷新当前轮数
	self:RefreshDrawRoundLabel(currentRound)
	-- 刷新奖品cell
	self:RefreshRewardsPalaceCells(rewards)
	-- 刷新消耗信息
	self:RefreshCostInfo(costGoodsId, costGoodsAmount)
	-- 刷新下一轮按钮状态
	self:RefreshNextState(self:CanEnterNextRound(), currentRound, totalRound)
	-- 刷新抽奖按钮状态
	self:RefreshDrawState(self:HasRewards())
	-- 清空获奖spine节点
	self:ClearRewardSpineNode()
end
--[[
刷新奖品数据
@params rewards list 奖品
--]]
function AssemblyActivityTenPalaceView:RefreshRewardsData(rewards)
	-- 刷新缓存的奖品数据
	self.rewardsData = rewards
	-- 重置一次index映射
	self.rewardsFixedIndex = {}

	local hasRewards = false
	local hasDrawnBigReward = false

	for i,v in ipairs(rewards) do
		-- 大奖插到头
		if 1 == checkint(v.big) then
			table.insert(self.rewardsFixedIndex, 1, i)
			if 1 == checkint(v.hasDrawn) then
				-- 刷新一次是否领取过大奖
				hasDrawnBigReward = true
			end
		else
			table.insert(self.rewardsFixedIndex, i)
		end

		if 0 == checkint(v.hasDrawn) then
			-- 刷新一次是否还有能抽的奖品
			hasRewards = true
		end
	end
	self:SetHasRewards(hasRewards)
	self:SetHasDrawnBigReward(hasDrawnBigReward)

	-- 刷新一次当前选中框的index
	if self:HasRewards() then
		-- 存在奖励 显示高亮
		local currentSelectedCellIndex = self:GetCurrentSelectedIndex()
		if nil == currentSelectedCellIndex then
			-- 如果没有初始化过这个index 默认找到最开始的能抽的index
			for cellIndex, index in ipairs(self.rewardsFixedIndex) do

				local rewardData = self:GetRewardDataByIndex(index)

				if 0 == checkint(rewardData.hasDrawn) then
					-- 刷新一次选中状态
					self:RefreshCellSelectedMark(cellIndex)
					break
				end
				
			end

		else

			local cellAmount = #CellRowColConfig

			for i = currentSelectedCellIndex, currentSelectedCellIndex + cellAmount, 1 do
				local fixedCellIndex = (i - 1) % cellAmount + 1
				local rewardData = self:GetRewardDataByCellIndex(fixedCellIndex)
				if 0 == checkint(rewardData.hasDrawn) then
					-- 刷新一次选中状态
					self:RefreshCellSelectedMark(fixedCellIndex)
					break
				end
			end

		end
	else
		-- 不存在奖励 不显示高亮
		self:SetCurrentSelectedIndex(nil)
	end
	
end
--[[
根据cellIndex 刷新选中状态
@params cellIndex int 格子的index
--]]
function AssemblyActivityTenPalaceView:RefreshCellSelectedMark(index)
	if nil ~= self:GetCurrentSelectedIndex() then
		local preCellData = self:GetCellDataByCellIndex(self:GetCurrentSelectedIndex())
		if nil ~= preCellData then
			preCellData:ShowSeletedMark(false)
		end
	end

	local currentCellData = self:GetCellDataByCellIndex(index)
	if nil ~= currentCellData then
		currentCellData:ShowSeletedMark(true)
	end

	self:SetCurrentSelectedIndex(index)
end
--[[
刷新奖品cell
@params rewards list {
	goodsId: int, 道具ID.
	num: int, 道具数量.
	big: int, 1:大奖 0:小奖
	hasDrawn: int, 1:已领取 0:未领取
}
--]]
function AssemblyActivityTenPalaceView:RefreshRewardsPalaceCells(rewards)
	local rewardData = nil
	local cellData = nil
	local hasRewards = false

	for cellIndex, index in ipairs(self.rewardsFixedIndex) do
		rewardData = rewards[index]
		cellData = self:GetCellDataByCellIndex(cellIndex)
		-- 刷新道具图标
		cellData:RefreshGoodsIcon(rewardData.goodsId, rewardData.num, self)
		-- 刷新道具获得状态
		cellData:ShowGetRewards(1 == checkint(rewardData.hasDrawn))
		-- 刷新默认的选中状态
		cellData:ShowSeletedMark(cellIndex == self:GetCurrentSelectedIndex())
		-- 重置zorder
		cellData.cellBgLayer:setLocalZOrder(15)
	end
end
--[[
刷新轮次标题
@params currentRound int 轮次
@params totalRound int 总轮次
--]]
function AssemblyActivityTenPalaceView:RefreshDrawRoundLabel(currentRound)
	local str = string.format(__('第%d轮'), currentRound)
	self.viewData.drawTitleLabel:setString(str)

	------------ 标题背景自适应 ------------
	local paddingX = 30
	local labelContentSize = display.getLabelContentSize(self.viewData.drawTitleLabel)
	local labelBgContentSize = self.viewData.drawTitleBg:getContentSize()

	if labelContentSize.width > labelBgContentSize.width - paddingX * 2 then
		local fixedWidth = labelContentSize.width + paddingX * 2
		self.viewData.drawTitleBg:setContentSize(cc.size(fixedWidth, labelBgContentSize.height))
		self.viewData.drawTitleLabel:setPositionX(fixedWidth * 0.5)
	end
	------------ 标题背景自适应 ------------
end
--[[
刷新消耗
@params goodsId int 道具id
@params amount int 数量
--]]
function AssemblyActivityTenPalaceView:RefreshCostInfo(goodsId, amount)
	self.viewData.costGoodsLabel:setString(string.format('%d', checknumber(amount)))
	self.viewData.costGoodsIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(goodsId)))

	display.setNodesToNodeOnCenter(
		self.viewData.drawButton,
		{self.viewData.costLabel, self.viewData.costGoodsLabel, self.viewData.costGoodsIcon},
		{spaceW = 2, y = self.viewData.drawButton:getContentSize().height * 0.5 - self.viewData.centerDrawBg:getContentSize().height * 0.5 + 25}
	)
end
--[[
刷新下一轮按钮状态
@params canEnterNextRound bool 是否能进入下一轮
@params currentRound int 当前轮
@params totalRound int 总轮数
--]]
function AssemblyActivityTenPalaceView:RefreshNextState(canEnterNextRound, currentRound, totalRound)
	if not canEnterNextRound or (totalRound <= currentRound) then
		-- self.viewData.nextRoundButton:setEnabled(false)
		self.viewData.nextRoundButton:getNormalImage():setTexture(_res(RES_DICT.BTN_WHITE_DISABLE))
		self.viewData.nextRoundButton:getSelectedImage():setTexture(_res(RES_DICT.BTN_WHITE_DISABLE))
	else
		-- self.viewData.nextRoundButton:setEnabled(true)
		self.viewData.nextRoundButton:getNormalImage():setTexture(_res(RES_DICT.BTN_WHITE_NORMAL))
		self.viewData.nextRoundButton:getSelectedImage():setTexture(_res(RES_DICT.BTN_WHITE_NORMAL))
	end

	if (totalRound <= currentRound) then
		self.viewData.nextRoundIcon:setVisible(false)
	else
		self.viewData.nextRoundIcon:setVisible(true)
	end
end
--[[
刷新抽奖按钮状态
@params hasRewards bool 是否还有能抽的奖品
--]]
function AssemblyActivityTenPalaceView:RefreshDrawState(hasRewards)
	if hasRewards then
		self.viewData.drawButton:getNormalImage():setTexture(_res(RES_DICT.BTN_COMMON_NORMAL))
		self.viewData.drawButton:getSelectedImage():setTexture(_res(RES_DICT.BTN_COMMON_NORMAL))
	else
		self.viewData.drawButton:getNormalImage():setTexture(_res(RES_DICT.BTN_COMMON_DISABLE))
		self.viewData.drawButton:getSelectedImage():setTexture(_res(RES_DICT.BTN_COMMON_DISABLE))
	end
end
--[[
抽卡动画
@params squaredId int 道具唯一id
--]]
function AssemblyActivityTenPalaceView:DoDrawOneTime(squaredId)
	local targetCellIndex = self:GetCellIndexBySquaredId(squaredId)
	self:DoDrawOneTimeByTargetCellIndex(targetCellIndex)
end
--[[
根据cellIndex进行抽卡动画
@params targetCellIndex int 目标格子序号
--]]
function AssemblyActivityTenPalaceView:DoDrawOneTimeByTargetCellIndex(targetCellIndex)
	-- 刷一遍格子 取出还未领取的格子序号
	local enableCellIndex = {}
	for cellIndex, index in ipairs(self.rewardsFixedIndex) do
		local rewardData = self:GetRewardDataByIndex(index)
		if 0 == checkint(rewardData.hasDrawn) then
			table.insert(enableCellIndex, cellIndex)
		end
	end

	local jumpList = self:GetJumpListByEnableCellIndex(enableCellIndex, self:GetCurrentSelectedIndex(), targetCellIndex)
	self:StartBanditAnimation(jumpList, enableCellIndex, targetCellIndex)
end
--[[
起老虎机动画
@params jumpList list 跳转的序列
@params enableCellIndex 可用格子的cellIndex
@params targetCellIndex int 目标格子序号
--]]
function AssemblyActivityTenPalaceView:StartBanditAnimation(jumpList, enableCellIndex, targetCellIndex)
	-- 动画暂时不需要了
	-- self:OverBanditAnimation(targetCellIndex)
	local rewardData = self:GetRewardDataByCellIndex(targetCellIndex)
	AppFacade.GetInstance():DispatchObservers('BANDIT_ANIMATION_OVER', self:GetSignalParams({squaredId = checkint(rewardData.squaredId)}))
end
--[[
老虎机动画结束
@params targetCellIndex int 目标格子序号
--]]
function AssemblyActivityTenPalaceView:OverBanditAnimation(targetCellIndex)
	local rewardData = self:GetRewardDataByCellIndex(targetCellIndex)
	local cellData = self:GetCellDataByCellIndex(targetCellIndex)

	local parentNode = nil
	local zorder = nil
	local animationName = nil
	local scaleX = 1
	local scaleY = 1

	if 1 == checkint(rewardData.big) then
		parentNode = cellData.cellBgLayer
		zorder = 1
		animationName = 'attack2'
	else
		scaleX = 0.76
		parentNode = cellData.cellBgLayer
		zorder = 30
		animationName = 'attack1'
	end

	-- 创建spine动画
	local rewardSpineAni = sp.SkeletonAnimation:create(
		'ui/home/capsuleNew/ninePalace/effect/zhaohuan_laohuji.json',
		'ui/home/capsuleNew/ninePalace/effect/zhaohuan_laohuji.atlas',
		1
	)
	parentNode:addChild(rewardSpineAni, zorder)
	rewardSpineAni:setVisible(false)
	rewardSpineAni:setPosition(utils.getLocalCenter(parentNode))
	rewardSpineAni:setScaleX(scaleX)
	rewardSpineAni:setScaleY(scaleY)
	self:SetRewardSpineNode(rewardSpineAni)

	cellData.cellBgLayer:setLocalZOrder(99)

	local actionSeq = cc.Sequence:create(
		cc.DelayTime:create(0.5),
		cc.CallFunc:create(function ()
			rewardSpineAni:setVisible(true)
			rewardSpineAni:setAnimation(0, animationName, true)
		end),
		cc.DelayTime:create(1.5),
		cc.CallFunc:create(function ()
			-- 动画结束 通知mdt处理后续内容
			AppFacade.GetInstance():DispatchObservers('BANDIT_ANIMATION_OVER', self:GetSignalParams({squaredId = checkint(rewardData.squaredId)}))
		end)
	)
	self:runAction(actionSeq)
end
--[[
开始刷新下一波
--]]
function AssemblyActivityTenPalaceView:DoEnterNextRound()
	-- 清除获奖spine
	self:ClearRewardSpineNode()
	-- 清除选中框状态
	self:SetCurrentSelectedIndex(nil)

	local centerPos = cc.p(
		self.viewData.centerDrawBg:getPositionX(),
		self.viewData.centerDrawBg:getPositionY()
	)

	local cellData = nil
	local cellAmount = #self.viewData.palaceCells

	for i = cellAmount, 1, -1 do
		cellData = self:GetCellDataByCellIndex(i)

		-- 刷一次zorder
		cellData.cellBgLayer:setLocalZOrder(15)

		local pos = cc.p(cellData.cellBgLayer:getPositionX(), cellData.cellBgLayer:getPositionY())
		local delayTime = 0.1 * (cellAmount - i)
		local bezierConfig = {
			pos,
			self:GetFixedBezierPos(pos, centerPos, 75),
			centerPos
		}

		local actionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime),
			cc.Spawn:create(
				cc.BezierTo:create(0.3, bezierConfig),
				cc.ScaleTo:create(0.3, 0.5)
			),
			cc.Hide:create()
		)
		cellData.cellBg:runAction(actionSeq:clone())

		if 1 == i then
			local actionSeq_ = cc.Sequence:create(
				cc.DelayTime:create(delayTime),
				cc.Spawn:create(
					cc.BezierTo:create(0.3, bezierConfig),
					cc.ScaleTo:create(0.3, 0.5)
				),
				cc.Hide:create(),
				cc.CallFunc:create(function ()
					self:OverEnterNextRound()
				end)
			)
			cellData.cellBgLayer:runAction(actionSeq_)
		else
			cellData.cellBgLayer:runAction(actionSeq:clone())
		end
		
	end
end
--[[
转结束 开始散开
--]]
function AssemblyActivityTenPalaceView:OverEnterNextRound()
	local centerPos = cc.p(
		self.viewData.centerDrawBg:getPositionX(),
		self.viewData.centerDrawBg:getPositionY()
	)
	local centerRow = 2
	local centerCol = 2.5

	-- 创建一次升星spine
	local upSpine = sp.SkeletonAnimation:create(
		'effects/pet/shengxing.json',
		'effects/pet/shengxing.atlas',
		1
	)
	local upSpineAnimationName = 'play2'
	local upSpineAnimationTime = upSpine:getAnimationsData()[upSpineAnimationName].duration
	upSpine:setPosition(centerPos)
	self.viewData.centerDrawBg:getParent():addChild(upSpine, 99)

	upSpine:setAnimation(0, upSpineAnimationName, false)

	local cellData = nil
	local cellAmount = #self.viewData.palaceCells

	for i = cellAmount, 1, -1 do
		cellData = self:GetCellDataByCellIndex(i)

		-- 刷一次zorder
		cellData.cellBgLayer:setLocalZOrder(15)

		local rowcolInfo = CellRowColConfig[i]
		local pos = cc.p(
			centerPos.x + (rowcolInfo.col - centerCol) * PalaceCellWidth,
			centerPos.y + (centerRow - rowcolInfo.row) * PalaceCellHeight
		)
		local delayTime = upSpineAnimationTime * 0.45 + 0.1 * (i - 1)
		local bezierConfig = {
			centerPos,
			self:GetFixedBezierPos(centerPos, pos, 75),
			pos
		}

		local actionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime),
			cc.Show:create(),
			cc.Spawn:create(
				cc.BezierTo:create(0.3, bezierConfig),
				cc.ScaleTo:create(0.3, 1)
			)
		)
		cellData.cellBg:runAction(actionSeq:clone())

		if 1 == i then
			local actionSeq_ = cc.Sequence:create(
				cc.DelayTime:create(delayTime),
				cc.CallFunc:create(function ()
					-- 刷新界面
					AppFacade.GetInstance():DispatchObservers('NEXT_ROUND_ANIMATION_REFRESH', self:GetSignalParams())
				end),
				cc.Show:create(),
				cc.Spawn:create(
					cc.BezierTo:create(0.3, bezierConfig),
					cc.ScaleTo:create(0.3, 1)
				)
			)
			cellData.cellBgLayer:runAction(actionSeq_)
		elseif 9 == i then
			local actionSeq_ = cc.Sequence:create(
				cc.DelayTime:create(delayTime),
				cc.Show:create(),
				cc.Spawn:create(
					cc.BezierTo:create(0.3, bezierConfig),
					cc.ScaleTo:create(0.3, 1)
				),
				cc.CallFunc:create(function ()
					-- 移除spine动画
					upSpine:setVisible(false)
					upSpine:runAction(cc.RemoveSelf:create())
					-- 恢复触摸
					AppFacade.GetInstance():DispatchObservers('NEXT_ROUND_ANIMATION_OVER', self:GetSignalParams())
				end)
			)
			cellData.cellBgLayer:runAction(actionSeq_)
		else
			cellData.cellBgLayer:runAction(actionSeq:clone())
		end
		
	end
end
function AssemblyActivityTenPalaceView:GetFixedBezierPos(p1, p2, len)
	-- p1起点 p2终点
	local p = cc.p(0, 0)
	local dp1p2 = cc.pGetDistance(p1, p2)
	local p_ = cc.pSub(p2, p1)

	local pCenter = cc.p(
		(p1.x + p2.x) * 0.5,
		(p1.y + p2.y) * 0.5
	)

	p.x = pCenter.x + len * p_.x / dp1p2
	p.y = pCenter.y + len * p_.y / dp1p2

	return p
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
抽奖按钮回调
--]]
function AssemblyActivityTenPalaceView:DrawOneClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('NINE_PALACE_DRAW_CARD', self:GetSignalParams())
end
--[[
下一波按钮回调
--]]
function AssemblyActivityTenPalaceView:NextRoundClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('NINE_PALACE_NEXT_ROUND', self:GetSignalParams())
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据界面内序号 获取cell的信息
@params cellIndex int cell的index
@return _ cellData
--]]
function AssemblyActivityTenPalaceView:GetCellDataByCellIndex(cellIndex)
	return self.viewData.palaceCells[cellIndex]
end
--[[
根据cellIndex获取index
@params cellIndex int cell index
@return _ int index
--]]
function AssemblyActivityTenPalaceView:GetIndexByCellIndex(cellIndex)
	return self.rewardsFixedIndex[cellIndex]
end
--[[
是否还有能抽的奖品
--]]
function AssemblyActivityTenPalaceView:HasRewards()
	return self.hasRewards
end
function AssemblyActivityTenPalaceView:SetHasRewards(has)
	self.hasRewards = has
end
--[[
根据序号获取reward信息
@params index int 序号
@return _ map
--]]
function AssemblyActivityTenPalaceView:GetRewardDataByIndex(index)
	return self.rewardsData[index]
end
--[[
根据cell序号获取reward信息
@params cellIndex int cell序号
@return _ map
--]]
function AssemblyActivityTenPalaceView:GetRewardDataByCellIndex(cellIndex)
	local index = self:GetIndexByCellIndex(cellIndex)
	if nil ~= index then
		return self:GetRewardDataByIndex(index)
	else
		return nil
	end
end
--[[
根据道具唯一id获取cellIndex
@params squaredId int 唯一id
@return _ int cell index
--]]
function AssemblyActivityTenPalaceView:GetCellIndexBySquaredId(squaredId)
	local rewardData = nil
	for cellIndex, index in ipairs(self.rewardsFixedIndex) do
		rewardData = self:GetRewardDataByIndex(index)
		if nil ~= rewardData and squaredId == checkint(rewardData.squaredId) then
			return cellIndex
		end
	end
end
--[[
获取当前选中框停留的index
--]]
function AssemblyActivityTenPalaceView:GetCurrentSelectedIndex()
	return self.selectedCellIndex
end
function AssemblyActivityTenPalaceView:SetCurrentSelectedIndex(index)
	self.selectedCellIndex = index
end
--[[
获取是否抽到过大奖
--]]
function AssemblyActivityTenPalaceView:HasDrawnBigReward()
	return self.hasDrawnBigReward
end
function AssemblyActivityTenPalaceView:SetHasDrawnBigReward(has)
	self.hasDrawnBigReward = has
end
--[[
获取当前逻辑上是否满足能进入下一轮
--]]
function AssemblyActivityTenPalaceView:CanEnterNextRound()
	print('check fuck ', self:HasDrawnBigReward(), self:HasRewards())
	return (self:HasDrawnBigReward()) or (not self:HasRewards())
end
--[[
获取得奖的spine
--]]
function AssemblyActivityTenPalaceView:GetRewardSpineNode()
	return self.rewardSpineAni
end
function AssemblyActivityTenPalaceView:SetRewardSpineNode(spineNode)
	self.rewardSpineAni = spineNode
end
function AssemblyActivityTenPalaceView:ClearRewardSpineNode()
	local spineNode = self:GetRewardSpineNode()
	if nil ~= spineNode then
		spineNode:setVisible(false)
		spineNode:clearTracks()
		spineNode:runAction(cc.RemoveSelf:create())
		self:SetRewardSpineNode(nil)
	end
end
--[[
根据cellIndex获取坐标
@params cellIndex cell序号
@return _ cc.p坐标
--]]
function AssemblyActivityTenPalaceView:GetCellPositionByCellIndex(cellIndex)
	local centerPos =  cc.p(
		self.viewData.centerDrawBg:getPositionX(),
		self.viewData.centerDrawBg:getPositionY()
	)
	local centerRow = 2
	local centerCol = 2.5

	local rowcolInfo = CellRowColConfig[cellIndex]
	local x = centerPos.x + (rowcolInfo.col - centerCol) * PalaceCellWidth
	local y = centerPos.y + (centerRow - rowcolInfo.row) * PalaceCellHeight

	return cc.p(x, y)
end
--[[
根据当前可用格子的cellIndex的序列生成一个jump动画的格子序列
@params enableCellIndex 可用格子的cellIndex
@params startCellIndex int 开始的格子序号
@params overCellIndex int 结束的格子序号
@return jumpList list
--]]
function AssemblyActivityTenPalaceView:GetJumpListByEnableCellIndex(enableCellIndex, startCellIndex, overCellIndex)
	local jumpList = {}
	if 1 == #enableCellIndex then
		-- 如果只剩一个奖品 不做动画，直接弹出
		return jumpList
	else
		-- 转三圈 最后一圈做停
		local sameMark = 0
		local itor = nil
		local breakAll = false

		for round = 1, BanditJumpRound + 2 do

			for _, cellIndex_ in ipairs(enableCellIndex) do
				if nil == itor and startCellIndex == cellIndex_ then
					-- 第一次找到起始格子开始插入
					itor = 0
				end

				if nil ~= itor then
					-- 迭代mark不为0时开始插
					table.insert(jumpList, 1, cellIndex_)
					itor = itor + 1

					if itor == BanditJumpRound * #enableCellIndex then
						-- 如果已经完成了指定圈数的记录 开始做最后一圈的插入
						if startCellIndex == overCellIndex then
							-- 如果开始index和结束index相同 随机一次下一格到位或者再转一圈到位
							sameMark = math.round(math.random(600) / 1000)
							-- print('here check fuck stop sameMark<<<<<', sameMark)
						end
					end

					-- print('here check fuck list data<<<<<<,', itor, cellIndex_)

					if itor > (BanditJumpRound * #enableCellIndex + sameMark) then
						if overCellIndex == cellIndex_ then
							breakAll = true
							break
						end
					end
				end
			end

			if breakAll then
				break
			end
		end

		return jumpList
	end
end
--[[
获取当前活动id
--]]
function AssemblyActivityTenPalaceView:GetActivityId()
	return self.activityId
end
function AssemblyActivityTenPalaceView:SetActivityId(activityId)
	self.activityId = activityId
end
--[[
封装一次传参
@params params table 参数
--]]
function AssemblyActivityTenPalaceView:GetSignalParams(params)
	if nil == params then
		params = {}
	end
	params.activityId = self:GetActivityId()
	return params
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- cocos2dx --
---------------------------------------------------
function AssemblyActivityTenPalaceView:onEnter()
	-- self:FixContentPosition()
end
---------------------------------------------------
-- cocos2dx --
---------------------------------------------------
return AssemblyActivityTenPalaceView