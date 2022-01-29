--[[
邮箱界面
--]]
local MailCollectView = class('MailCollectView', function ()
	local node = CLayout:create(cc.size(890,586))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.MailCollectView'
	node:enableNodeEvents()
	return node
end)

function MailCollectView:ctor(...)
	local function CreateView()
		local size = cc.size(890,586)
		local view = CLayout:create(size)
		view:setAnchorPoint(0, 0)
		local emptySize = cc.size(890,586)
		--空白的内容区域的页面视图
		local emptyView = CLayout:create(emptySize)
		display.commonUIParams(emptyView, {ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
		view:addChild(emptyView)
		local dialogue_tips = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/common_bg_dialogue_tips.png')})
		display.commonUIParams(dialogue_tips, {ap = cc.p(0,0.5),po = cc.p(80,emptySize.height * 0.5)})
		display.commonLabelParams(dialogue_tips,{text = __('暂无收藏邮件'), fontSize = 24, color = '#4c4c4c'})
		emptyView:addChild(dialogue_tips, 6)
		-- 中间小人
		local loadingCardQ = AssetsUtils.GetCartoonNode(3, dialogue_tips:getContentSize().width + 230, size.height * 0.5)
		emptyView:addChild(loadingCardQ, 6)
		loadingCardQ:setScale(0.7)
		emptyView:setVisible(false)
		---正式的内容页面
		local cview = CLayout:create(emptySize)
		cview:setPosition(size.width/2 - 18 , size.height/2 - 15)

		-- 滑动层背景图
		local ListBg = display.newImageView(_res('ui/common/kitchen_bg_need_food.png'), 42, 100,
				{scale9 = true, size = cc.size(306, 480), ap = cc.p(0, 0)})
		cview:addChild(ListBg)
		local ListBgFrameSize = ListBg:getContentSize()
		-- 添加列表功能
		local mailListSize = ListBg:getContentSize()
		local mailListCellSize = cc.size(mailListSize.width, 106)
		local mailListGridView = CGridView:create(mailListSize)
		mailListGridView:setSizeOfCell(mailListCellSize)
		mailListGridView:setColumns(1)
		mailListGridView:setAutoRelocate(true)
		display.commonUIParams(mailListGridView, {ap = cc.p(0, 1), po = cc.p(42, size.height - 5)})
		cview:addChild(mailListGridView, 10)

		-- 列表按钮 --
		local btnLayoutSize = cc.size(308, 80)
		local btnLayout = CLayout:create(btnLayoutSize)
		display.commonUIParams(btnLayout, {ap = cc.p(0, 0), po = cc.p(43, 30)})
		cview:addChild(btnLayout, 10)
		local btnLyoutBg = display.newImageView(_res('ui/mail/mail_list_bg_btn.png'), btnLayoutSize.width/2, 0, {ap = cc.p(0.5, 0)})
		btnLayout:addChild(btnLyoutBg)
		-- 删除已读
		--local deleteAllBtn = display.newButton(btnLayoutSize.width/2 - 76, 35, {n = _res('ui/common/common_btn_white_default.png')})
		--btnLayout:addChild(deleteAllBtn, 3)
		--display.commonLabelParams(deleteAllBtn, fontWithColor(14, {text = __('删除已读')}))
		-- 领取全部
		--local drawAllBtn = display.newButton(btnLayoutSize.width/2 + 76, 35, {n = _res('ui/common/common_btn_orange.png')})
		--btnLayout:addChild(drawAllBtn, 3)
		--display.commonLabelParams(drawAllBtn, fontWithColor(14, {text = __('一键领取')}))

		-- right view layout
		local rsize = cc.size(538,552)
		local rightView = CLayout:create(rsize)
		display.commonUIParams(rightView, {ap = display.RIGHT_BOTTOM, po = cc.p(emptySize.width, 30)})
		cview:addChild(rightView, 2)
		-- scrollView
		local scrollView = CScrollView:create(cc.size(526,280))
		scrollView:setDirection(eScrollViewDirectionVertical)
		display.commonUIParams(scrollView, {ap = display.CENTER_TOP, po = cc.p(rsize.width * 0.5, rsize.height - 50)})
		rightView:addChild(scrollView)
		local titleBg = display.newImageView(_res('ui/mail/mail_title_bg.png'), rsize.width/2, rsize.height, {ap = cc.p(0.5, 1)})
		rightView:addChild(titleBg)
		local titleLabel = display.newLabel(10, rsize.height + 5,
				{text = '', ap = cc.p(0, 1), fontSize = 28, color = '#ba5c5c'})
		rightView:addChild(titleLabel)
		local descrLabel = display.newLabel(10, 0,
				{ap = display.LEFT_BOTTOM, w = 526})
		scrollView:getContainer():addChild(descrLabel)
		--
		--local deadlineTag = display.newLabel(rsize.width, rsize.height - 20,
		--		{text = __('有效期：'), fontSize = 20, color = '#7c7c7c', ap = cc.p(1.0, 0)})
		--rightView:addChild(deadlineTag)

		local awardBg = display.newImageView(_res('ui/common/commcon_bg_text.png'), rsize.width * 0.5, 74,
				{scale9 = true, size = cc.size(rsize.width - 8, 146), ap = cc.p(0.5, 0)})
		awardBg:setTag(112)
		rightView:addChild(awardBg)
		local lsize = awardBg:getContentSize()
		local tableView = CTableView:create(cc.size(lsize.width - 10, 106))
		tableView:setSizeOfCell(cc.size(lsize.width / 5, 106))
		tableView:setAutoRelocate(true)
		tableView:setDirection(eScrollViewDirectionHorizontal)
		tableView:setCountOfCell(0)
		rightView:addChild(tableView, 10)
		tableView:setPosition(cc.p(rsize.width * 0.5, 86))
		tableView:setAnchorPoint(cc.p(0.5,0))
		local prizeBg = display.newImageView('ui/common/common_title_2.png', awardBg:getContentSize().width/2, awardBg:getContentSize().height-25,
				{ap = cc.p(0.5, 0.5)} )
		awardBg:addChild(prizeBg)

		local awardLabel = display.newLabel(awardBg:getContentSize().width/2, awardBg:getContentSize().height-25,
				fontWithColor(4,{text = __('奖励'), fontSize = 20, ap = cc.p(0.5,0.5)}))
		awardBg:addChild(awardLabel,1)

		-- 领取按钮
		local delColBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png')})
		display.commonUIParams(delColBtn, {po = cc.p(rsize.width * 0.5, 30)})
		display.commonLabelParams(delColBtn, fontWithColor(14,{text = __('删除')}))
		rightView:addChild(delColBtn)

		view:addChild(cview)
		cview:setVisible(false)

		return {
			view             = view,
			emptyView        = emptyView,
			cview            = cview,
			ListBg           = ListBg,
			rightView        = rightView,
			titleLabel       = titleLabel,
			awardBg          = awardBg,
			delColBtn        = delColBtn,
			descrLabel       = descrLabel,
			tableView        = tableView,
			mailListGridView = mailListGridView,
			scrollView       = scrollView,


		}
	end
	xTry(function ()
		-- create view
		self.viewData = CreateView()
		self.viewData.view:setPosition(cc.p(0, 0))
		self:addChild(self.viewData.view,1)
	end, __G__TRACKBACK__)
end


return MailCollectView
