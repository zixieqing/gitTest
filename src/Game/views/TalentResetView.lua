--[[
天赋重置界面
@params table {
	mediatorName string parent mediator name
	tag int self tag
}
--]]
local CommonPopup = require('common.CommonDialog')
local TalentResetView = class('TalentResetView', CommonPopup)

function TalentResetView:InitialUI(params)
	params = self.args.params or {}
	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_4.png'), 0, 0,{scale9 = true, size = cc.size(770, 478)})
		local bgSize = bg:getContentSize()
		local colorView = CColorView:create(cc.c4b(0, 0, 0, 0))
		colorView:setContentSize(bgSize)
		colorView:setTouchEnabled(true)
		colorView:setPosition(bgSize.width/2, bgSize.height/2)
		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)
		view:addChild(colorView, -1)
		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_3.png'), animation = false})
		display.commonUIParams(titleBg, {ap = cc.p(0.5, 0), po = cc.p(bgSize.width * 0.5, 410)})
		local  titleText = params.titleText  or __('重置天赋')
		display.commonLabelParams(titleBg,
			fontWithColor(4,{text = titleText,ttf = true, font = TTF_GAME_FONT,offset = cc.p(0, -2)}))
		bg:addChild(titleBg)
		-- descr
		local descrLabel = display.newRichLabel(180, 388,
 			{ap = cc.p(0, 1), w = 100, sp = 15}
		)
		view:addChild(descrLabel,20)
		-- line
		local line = display.newImageView(_res('ui/common/kitchen_tool_split_line.png'), bgSize.width/2, 284, {ap = cc.p(0.5, 0)})
		view:addChild(line, 10)
		-- role
		local role = display.newImageView(_res('ui/guide/guide_ico_pet.png'), 18, 261, {ap = cc.p(0, 0)})
		view:addChild(role, 10)
		role:setScale(0.5)
		role:setFlippedX(true)
		-- 普通重置
		local freeResetBtn = display.newButton(56, 38,
			{n = _res('ui/home/talent/talent_tips_btn_1.png'), ap = cc.p(0, 0)}
		)
		freeResetBtn:setTag(8101)
		view:addChild(freeResetBtn, 10)
		local freeDescrLabel = display.newRichLabel(34, 190,
 			{ap = cc.p(0, 1), w = 30, sp = 10}
		)
		freeResetBtn:addChild(freeDescrLabel)
		local  freeText  = params.freeText  or __('普通重置')
		display.commonLabelParams(freeResetBtn, {text = freeText, fontSize = 28, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, offset = cc.p(0, - 65)})
		-- 无损重置

		local diamondResetBtn = display.newButton(392, 38,
			{n = _res('ui/home/talent/talent_tips_btn_2.png'), ap = cc.p(0, 0)}
		)
		diamondResetBtn:setTag(8102)
		view:addChild(diamondResetBtn, 10)
		local diamondDescrLabel = display.newRichLabel(34, 190,
 			{ap = cc.p(0, 1), w = 30, sp = 10}
		)
		diamondResetBtn:addChild(diamondDescrLabel)
		local  cosetText  = params.cosetText  or __('幻晶石重置')
		display.commonLabelParams(diamondResetBtn, {text = cosetText, fontSize = 28, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, offset = cc.p(0, - 65)})


		return {
			view              = view,
			freeDescrLabel    = freeDescrLabel,
			freeResetBtn      = freeResetBtn,
			diamondDescrLabel = diamondDescrLabel,
			diamondResetBtn   = diamondResetBtn,
			descrLabel        = descrLabel

		}
	end

	self.viewData = CreateView()

end

return TalentResetView
