--[[
战斗买活界面
@params table {
	stageId int 关卡id
	questBattleType QuestBattleType 关卡类型
	buyRevivalTime int 当前买活次数
	buyRevivalTimeMax int 最大买活次数
}
--]]
local BattleBuyRevivalView = class('BattleBuyRevivalView', function ()
	local node = CLayout:create(display.size)
	node.name = 'battle.view.BattleBuyRevivalView'
	node:enableNodeEvents()
	print('BattleBuyRevivalView', ID(node))
	return node
end)

------------ import ------------

------------ import ------------

--[[
constructor
--]]
function BattleBuyRevivalView:ctor( ... )
	local args = unpack({...})

	self.actionButtons = {}

	self.stageId = args.stageId
	self.questBattleType = args.questBattleType
	self.buyRevivalTime = args.buyRevivalTime
	self.buyRevivalTimeMax = args.buyRevivalTimeMax

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function BattleBuyRevivalView:InitUI()
	local layerSize = self:getContentSize()

	local costGoodsId, costGoodsAmount = self:GetCostConfig()
	local costGoodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId)

	-- 遮罩
	local bgMask = display.newImageView(_res('ui/common/common_bg_mask_2.png'), utils.getLocalCenter(self).x, utils.getLocalCenter(self).y,
		{enable = true, animate = false, scale9 = true, size = layerSize,
	cb = function (sender)
		
	end})
	self:addChild(bgMask)

	-- 中间底
	local centerBg = display.newImageView(_res('ui/battle/battleresult/result_bg_black.png'), 0, 0)
	display.commonUIParams(centerBg, {po = cc.p(
		display.cx, display.cy
	)})
	self:addChild(centerBg, 10)

	-- hint label
	local hintLabel = display.newLabel(0, 0, fontWithColor('9', {text = string.format(__('是否消耗%s复活所有的飨灵继续战斗'), costGoodsConfig.name)}))
	display.commonUIParams(hintLabel, {ap = cc.p(0.5, 1), po = cc.p(
		centerBg:getContentSize().width * 0.5,
		centerBg:getContentSize().height - 5
	)})
	centerBg:addChild(hintLabel, 5)

	-- icon
	local revivalIcon = display.newImageView(_res('ui/tower/ready/result_bg_fail_revive.png'), 0, 0)
	display.commonUIParams(revivalIcon, {po = cc.p(
		centerBg:getContentSize().width * 0.5,
		centerBg:getContentSize().height * 0.525
	)})
	centerBg:addChild(revivalIcon, 5)

	-- left time
	local leftTimeLabel = display.newLabel(0, 0, fontWithColor('9', {text = string.format(__('剩余购买次数:%d'), math.max(0, self.buyRevivalTimeMax - self.buyRevivalTime))}))
	display.commonUIParams(leftTimeLabel, {po = cc.p(
		centerBg:getContentSize().width * 0.5,
		revivalIcon:getPositionY() - revivalIcon:getContentSize().height * 0.5 - 15
	)})
	centerBg:addChild(leftTimeLabel, 5)

	-- title 
	local titleLabel = display.newNSprite(_res('ui/battle/result_fail_title.png'), 0, 0)
	display.commonUIParams(titleLabel, {po = cc.p(
		centerBg:getPositionX(),
		centerBg:getPositionY() + centerBg:getContentSize().height * 0.5 + titleLabel:getContentSize().height * 0.5 + 30
	)})
	self:addChild(titleLabel, 10)

	-- 按钮
	local quitBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png')})
	display.commonUIParams(quitBtn, {po = cc.p(
		centerBg:getPositionX() - 180,
		centerBg:getPositionY() - centerBg:getContentSize().height * 0.5 - 65
	)})
	display.commonLabelParams(quitBtn, fontWithColor('14', {text = __('放弃')}))
	self:addChild(quitBtn, 10)
	
	local quitBtnTag = 1008	
	quitBtn:setTag(quitBtnTag)
	self.actionButtons[tostring(quitBtnTag)] = quitBtn

	local confirmBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_green.png')})
	display.commonUIParams(confirmBtn, {po = cc.p(
		centerBg:getPositionX() + 180,
		quitBtn:getPositionY()
	)})
	self:addChild(confirmBtn, 10)

	local confirmBtnTag = 1009
	confirmBtn:setTag(confirmBtnTag)
	self.actionButtons[tostring(confirmBtnTag)] = confirmBtn

	-- 消耗信息
	local costLabel = display.newLabel(0, 0, fontWithColor('14', {text = tostring(costGoodsAmount)}))
	confirmBtn:addChild(costLabel)

	local costIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(costGoodsId)), 0, 0)
	costIcon:setScale(0.2)
	confirmBtn:addChild(costIcon)

	display.setNodesToNodeOnCenter(confirmBtn, {costLabel, costIcon})
	if BattleConfigUtils:UseJapanLocalize() then
		display.setNodesToNodeOnCenter(confirmBtn, {costIcon, costLabel})
	end

	if 0 >= costGoodsAmount then
		costIcon:setVisible(false)
		costLabel:setString(__('免费'))
		costLabel:setPositionX(utils.getLocalCenter(confirmBtn).x)
	end

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
移除自己
--]]
function BattleBuyRevivalView:RemoveSelfForce()
	self:runAction(cc.RemoveSelf:create())
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取当前买活需要的消耗配置
@params return costGoodsId, costGoodsAmount int, int 消耗的道具id, 消耗的道具数量
--]]
function BattleBuyRevivalView:GetCostConfig()
	local costConsumeConfig = CommonUtils.GetBattleBuyReviveCostConfig(self.stageId, self.questBattleType, math.min(self.buyRevivalTimeMax, self.buyRevivalTime + 1))

	local costGoodsId = checkint(costConsumeConfig.consume)
	local costGoodsAmount = checkint(costConsumeConfig.consumeNum)

	if BMediator:GetBData():canBuyRevivalFree() then
		-- 可以免费买活
		costGoodsAmount = 0
	end

	return costGoodsId, costGoodsAmount
end
---------------------------------------------------
-- get set end --
---------------------------------------------------


return BattleBuyRevivalView
