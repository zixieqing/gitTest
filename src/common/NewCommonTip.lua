local GameScene    = require("Frame.GameScene")
---@class NewCommonTip
local NewCommonTip = class('NewCommonTip', GameScene)

function NewCommonTip:ctor(...)
	local arg = unpack({ ... })
	self.args = arg
	self:init()
end

function setBtnContentSize(btn, data)
	if tolua.type(btn) == 'ccw.CButton' then
		if not btn:isScale9Enabled() then
			return
		end
		local label     = btn:getLabel()
		local btnSize   = btn:getContentSize()
		local width     = data.width or btnSize.width
		local height    = data.height or btnSize.height
		local text      = label:getString() or ""
		local labelSize = display.getLabelContentSize(label)
		if labelSize.width > width + 50 then
			display.commonLabelParams(label, { text = text, w = width - 10, hAlign = display.TAC, reqH = height })
		else
			display.commonLabelParams(label, { text = text, hAlign = display.TAC, reqW = width - 10 })
		end
		btn:setContentSize(cc.size(width, height))
	end
end

function NewCommonTip:init()
	self.text             = self.args.text
	self.textOffset       = self.args.textOffset or cc.p(0, 0)
	self.extra            = self.args.extra
	self.richText         = self.args.richtext
	self.richTextW        = self.args.richTextW
	self.callback         = self.args.callback
	self.cancelBack       = self.args.cancelBack
	self.closeBgCB        = self.args.closeBgCB
	self.isOnlyOK         = self.args.isOnlyOK == true
	self.from             = self.args.from or ''
	self.isForced_        = self.args.isForced == true
	self.costDesr         = self.args.costDesr
	self.cost             = self.args.cost
	self.delayTime        = self.args.delayTime or 0

	self.noNeedRemove     = self.args.noNeedRemove
	self.diamondText      = self.args.diamondText
	self.levelText        = self.args.levelText
	self.useDiaCallback   = self.args.useDiaCallback
	self.useLevelCallback = self.args.useLevelCallback
	self.btnTextL         = self.args.btnTextL or __('取消')
	self.btnTextR         = self.args.btnTextR or __('确定')
	self.btnTextRTTF      = (self.args.btnTextRTTF == nil and true ) or self.args.btnTextRTTF
	print("self.btnTextRTTF = " , self.btnTextRTTF)
	self.isClose          = false
	-- local commonBg = require('common.CloseBagNode').new(
	--     {callback = function ()
	--         self:runAction(cc.RemoveSelf:create())
	--     end})
	-- commonBg:setPosition(utils.getLocalCenter(self))
	-- self:addChild(commonBg)

	local commonBG        = require('common.CloseBagNode').new({ callback = function()
		-- self:runAction(cc.RemoveSelf:create())
		if not self.isForced_ then
			PlayAudioByClickClose()
			if self.closeBgCB then
				self.closeBgCB()
			end
			self:removeFromParent()
		end
	end, showLabel                                                        = not self.isForced_ })
	commonBG:setName('CLOSE_BAG')
	commonBG:setPosition(utils.getLocalCenter(self))
	self:addChild(commonBG)


	--view
	local view = CLayout:create()
	view:setName('view')
	view:setPosition(display.cx, display.cy)
	view:setAnchorPoint(display.CENTER)
	self.view     = view


	-- --bg
	-- local frameBg = display.newImageView(_res('ui/activity/oneYuan/oneyuan_bg.png'))

	-- frameBg:setAnchorPoint(display.LEFT_BOTTOM)
	-- view:addChild(frameBg)
	-- view:setContentSize(size)

	local outline = display.newImageView(_res('ui/common/common_bg_8.png'), {
		enable = true, scale9 = true, size = cc.size(display.width * 0.4, 350), capInsets = cc.rect(50, 50, 1, 1)
	})
	local size    = outline:getContentSize()
	outline:setAnchorPoint(display.LEFT_BOTTOM)
	view:addChild(outline)
	view:setContentSize(size)
	self.size = size
	commonBG:addContentView(view)

	-- bg mask
	-- local transparentBg = display.newImageView(_res('ui/common/common_bg_mask.png'), display.cx, display.cy, {
	--     scale9 = true, enable = true, size = display.size
	-- })
	-- self:addChild(transparentBg)


	-- back img
	-- local outline = display.newImageView(_res('ui/common/common_bg_a.png'),{
	--     scale9 = true, enable = true, size = cc.size(display.size.width/3,display.size.height/3)
	-- })
	-- outline:setAnchorPoint(cc.p(0.5, 0.5))
	-- outline:setPosition(cc.p(display.width/2,display.height /2 + outline:getContentSize().height/2))
	-- self:addChild(outline)


	-- local desBg = display.newImageView(_res('ui/common/common_bg_describe.png'),{
	--     scale9 = true, enable = false, size = cc.size(display.size.width/3 - 20,(display.size.height/3) * 0.6 - 6)
	-- })
	-- desBg:setAnchorPoint(cc.p(0.5, 1))
	-- desBg:setPosition(cc.p(outline:getContentSize().width/2,outline:getContentSize().height - 8))
	-- view:addChild(desBg)


	--    local dialog_title = CImageView:create(_res('jigsaw/tips/dialog_title.png'))
	--    dialog_title:setPosition(cc.p(outline:getPositionX(),outline:getPositionY() + outline:getContentSize().height*0.5))
	--    self.window:addChild(dialog_title)

	-- cancel button
	local cancelBtn = display.newButton(size.width / 2 - 120, 50, {
		n           = _res('ui/common/common_btn_white_default.png'),
		cb          = function(sender)
			PlayAudioByClickClose()
			if self.cancelBack then
				self.cancelBack()
			end
			self:removeFromParent()
			-- self:runAction(cc.RemoveSelf:create())
		end, scale9 = true
	})
	display.commonLabelParams(cancelBtn, fontWithColor(14, { text = self.btnTextL, ttf = false, color = '6c6c6c' }))

	local lwidth = display.getLabelContentSize(cancelBtn:getLabel()).width
	if lwidth < 124 then
		lwidth = 124
	end
	if lwidth > 124 then
		lwidth = lwidth + 20
	end
	view:addChild(cancelBtn)

	-- entry button
	local noNeedRemove = self.noNeedRemove
	local entryBtn     = display.newButton(size.width / 2 + 120, 50, {
		n           = _res('ui/common/common_btn_orange.png'),
		cb          = function(sender)
			PlayAudioByClickNormal()
			if not self.isClose then
				if self.callback then
					self:runAction(
						cc.Sequence:create(
							cc.DelayTime:create(self.delayTime),
							cc.CallFunc:create(function()
								self.callback()
								if noNeedRemove == true then
								else
									self:removeFromParent()
								end
							end)
						)
					)
				else
					if noNeedRemove == true then
					else
						self:removeFromParent()
					end
				end
				self.isClose = true
			end
		end, scale9 = true
	})
	entryBtn:setName('entryBtn')
	if self.btnTextRTTF then
		display.commonLabelParams(entryBtn, fontWithColor(14, { text = __(self.btnTextR) }))
	else
		display.commonLabelParams(entryBtn, fontWithColor(14, { text = __(self.btnTextR) , ttf = self.btnTextRTTF }))
	end

	view:addChild(entryBtn)
	--

	local rwidth = display.getLabelContentSize(entryBtn:getLabel()).width
	if rwidth < 124 then
		rwidth = 124
	end
	if rwidth > 124 then
		rwidth = lwidth + 20
	end
	local twidth = math.max(lwidth, rwidth)
	twidth       = twidth > 150 and 150 or twidth
	entryBtn:setContentSize(cc.size(twidth, 62))
	cancelBtn:setContentSize(cc.size(twidth, 62))



	-- tips label
	local tip = display.newLabel(size.width / 2 + self.textOffset.x, size.height * 0.5 + self.textOffset.y, fontWithColor('4', { w = 400 }))
	tip:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
	tip:setString(self.text)
	view:addChild(tip)
	self.tip = tip

	if self.richText then
		local richLabel = display.newRichLabel(size.width / 2, size.height * 0.6,
				{ display.LEFT_BOTTOM, w = self.richTextW or 30, r = true, sp = 5, c = self.richText })
		view:addChild(richLabel)
		self.richLabel = richLabel
	end

	if self.costDesr then
		local costDesrLabel = display.newLabel(size.width / 2, size.height * 0.66, fontWithColor('4', { w = 400, h = 130, text = self.costDesr }))
		costDesrLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
		view:addChild(costDesrLabel)
	end

	if self.cost then
		local costLabel = display.newLabel(size.width / 2, size.height * 0.68, fontWithColor('15', { text = __('消耗') }))
		view:addChild(costLabel)

		local goodsNode = require('common.GoodNode').new({ id = self.cost.goodsId, amount = self.cost.num, showAmount = true })
		goodsNode:setPosition(cc.p(size.width / 2, size.height * 0.5 - 10))
		goodsNode:setScale(0.9)
		view:addChild(goodsNode)
	end

	if self.extra then
		if not self.richtext and not self.costDesr and not self.cost then
			display.commonUIParams(tip, { ap = display.CENTER_TOP, po = cc.p(size.width * 0.5, size.height * 0.7) })
		end
		local offsetY = tip:getPositionY() - display.getLabelContentSize(tip).height - 20
		if tolua.type(self.extra) == 'string' then
			local extra = display.newLabel(size.width / 2, offsetY, fontWithColor('6', { w = size.width - 100, ap = display.CENTER_TOP }))
			extra:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
			extra:setString(self.extra)
			view:addChild(extra)
			self.extra = extra
		elseif tolua.type(self.extra) == 'table' then
			local extra = display.newRichLabel(size.width / 2, offsetY,
					{ display.LEFT_BOTTOM, w = 32, r = true, sp = 5, c = self.extra, ap = display.CENTER_TOP })
			view:addChild(extra)
			self.extra = extra
		end
	end
	if self.isOnlyOK then
		cancelBtn:setVisible(false)
		entryBtn:setPositionX(size.width / 2)
	end
	setBtnContentSize(entryBtn, { w = 170, height = 70 })
	setBtnContentSize(cancelBtn, { w = 170, height = 70 })
end

return NewCommonTip
