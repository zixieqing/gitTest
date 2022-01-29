--[[
购买剩余挑战次数
@params stageId int 关卡id
--]]
local CommonDialog = require('common.CommonDialog')
local BuyChallengeTimePopup = class('BuyChallengeTimePopup', CommonDialog)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
--[[
override
initui
--]]
function BuyChallengeTimePopup:InitialUI()

	local stageId = self.args.stageId
	print('here check stageId >>>>>>>>>>>>>>>', stageId)

	local function CreateView()

		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_8.png'), 0, 0)
		local bgSize = bg:getContentSize()

		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)

		-- descr label
		local buyCostAmount, buyCostGoodsId = CommonUtils.GetBuyChallengeTimeCostByStageId(stageId)
		local costLabel1 = display.newLabel(0, 0,
			{text = string.format(__('是否消耗%d'), buyCostAmount), fontSize = fontWithColor('8').fontSize, color = fontWithColor('8').color})
		bg:addChild(costLabel1)

		local costIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(buyCostGoodsId)), 0, 0)
		costIcon:setScale(0.2)
		bg:addChild(costIcon)

		local costLabel2 = display.newLabel(0, 0,
			{text = __('购买一次挑战次数'), fontSize = fontWithColor('8').fontSize, color = fontWithColor('8').color})
		bg:addChild(costLabel2)
		display.setNodesToNodeOnCenter(bg, {costLabel1, costIcon, costLabel2}, {y = bgSize.height * 0.5 + 15})

		-- hint label
		local hintLabel = display.newLabel(bgSize.width * 0.5, bgSize.height * 0.5 - 15,
			{text = __('(挑战次数每日0:00重置)'), fontSize = fontWithColor('6').fontSize, color = fontWithColor('6').color})
		bg:addChild(hintLabel)

		-- cancel btn
		local cancelBtn = display.newButton(0, 0,
			{n = _res('ui/common/common_btn_white_default.png'), cb = function (sender)
				self:CloseHandler()
			end})
		display.commonUIParams(cancelBtn, {po = cc.p(bgSize.width * 0.5 - 90, cancelBtn:getContentSize().height * 0.5 + 20)})

		display.commonLabelParams(cancelBtn, fontWithColor(14, {text = __('取消')}))
		view:addChild(cancelBtn, 5)

		-- confirm btn
		local confirmBtn = display.newButton(0, 0,
			{n = _res('ui/common/common_btn_orange.png'), cb = function (sender)
				AppFacade.GetInstance():DispatchObservers("BUY_CHALLENGE_TIME", {questId = stageId, num = 1})
			end})
		display.commonUIParams(confirmBtn, {po = cc.p(bgSize.width * 0.5 + 90, cancelBtn:getPositionY())})
		display.commonLabelParams(confirmBtn, fontWithColor(14, {text = __('确认')}))
		view:addChild(confirmBtn, 5)

		return {
			view = view
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end



return BuyChallengeTimePopup
