--[[
公告界面
--]]

local AnnouncementMediator = class('AnnouncementMediator', function ()
	local node = CLayout:create(cc.size(890,586))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.AnnouncementMediator'
	node:enableNodeEvents()
	return node
end)


function AnnouncementMediator:ctor( ... )
	self.args = unpack({...}) or {}
	self.viewData = nil
	local function CreateView()
		local bgSize = cc.size(886, 586)
		local view = CLayout:create(bgSize)
		view:setAnchorPoint(0, 0)
		local cView = CLayout:create(bgSize)
		--空白的内容区域的页面视图
		local emptyView = CLayout:create(bgSize)
		display.commonUIParams(emptyView, {ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
		view:addChild(emptyView)
		local dialogue_tips = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/common_bg_dialogue_tips.png')})
		display.commonUIParams(dialogue_tips, {ap = cc.p(0,0.5),po = cc.p(80,bgSize.height * 0.5)})
		display.commonLabelParams(dialogue_tips,{text = __('还没有收到公告哦'), fontSize = 24, color = '#4c4c4c', w = 300, hAlign = cc.TEXT_ALIGNMENT_CENTER})
        emptyView:addChild(dialogue_tips, 6)
        -- 中间小人
	    local loadingCardQ = AssetsUtils.GetCartoonNode(3, dialogue_tips:getContentSize().width + 230, bgSize.height * 0.5)
	    emptyView:addChild(loadingCardQ, 6)
	    loadingCardQ:setScale(0.7)

	    emptyView:setVisible(false)

		---正式的内容页面
		local cView = CLayout:create(bgSize)
		cView:setPosition(bgSize.width/2 - 18 , bgSize.height/2 - 15)
		-- 添加列表背景
		local listBg = display.newImageView(_res('ui/common/common_bg_goods.png'), 46, 26, {ap = cc.p(0, 0), scale9 = true, size = cc.size(306, 546), capInsets = cc.rect(10, 10, 487, 113)})
		cView:addChild(listBg)
		-- 添加列表功能
		local annoListSize = cc.size(306, 546)
		local annoListCellSize = cc.size(annoListSize.width, 104)
		local gridView = CGridView:create(annoListSize)
		gridView:setSizeOfCell(annoListCellSize)
		gridView:setColumns(1)
		gridView:setAutoRelocate(true)
		cView:addChild(gridView)
		gridView:setAnchorPoint(cc.p(0, 1))
		gridView:setPosition(cc.p(44, bgSize.height - 15))
		-- gridView:setBackgroundColor(ccc3FromInt("009999"))
		-- 正文背景
		-- local textBg = display.newImageView(_res('ui/common/commcon_bg_text.png'), bgSize.width - 85, 84 ,
		-- 	{ap = cc.p(1, 0), scale9 = true, size = cc.size(460, 500)})--scale9 = true, size = cc.size(bgSize.width * 0.67, bgSize.height * 0.68),
		-- -- bgData.view:addChild(textBg)
		-- cView:addChild(textBg)
		-- scrollView
		local scrollView = cc.ScrollView:create()
		scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
		scrollView:setViewSize(cc.size(500,500))
		scrollView:setPosition(cc.p(bgSize.width * 0.43 - 4,26))
		-- bgData.view:addChild(scrollView)
		cView:addChild(scrollView)

		scrollView:setColor(ccc3FromInt("449999"))

		local lineImage = display.newImageView(_res('ui/common/gonggao_img_fengexian.png'), 371, 532, {ap = cc.p(0, 0)})
		cView:addChild(lineImage)

		-- 标题

		local titleLabel = display.newLabel(620, 555,
			{text = ' ', fontSize = 26, color = '#5b3c25', ap = cc.p(0.5, 0.5)})
		cView:addChild(titleLabel)
		-- 正文
		local bodyLabel = display.newRichLabel(16, bgSize.height*0.85,
			{display.LEFT_BOTTOM, w = 50, sp = 5,noScale = true,ttf = true, font = TTF_TEXT_FONT })
		scrollView:setContainer(bodyLabel)
		-- 按钮
		-- local knowBtn = display.newButton(bgSize.width/2, 20,{n = _res('ui/common/common_btn_orange.png'), ap = cc.p(0.5, 0)})
		-- display.commonLabelParams(knowBtn, {text = __('知道了'), fontSize = 24, color = '#5c5c5c'})
		-- -- bgData.view:addChild(knowBtn)
		-- cView:addChild(knowBtn)
		display.commonUIParams(cView, {ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
		view:addChild(cView)
		cView:setVisible(false)
		return {
			view       = view,
			cView      = cView,
			emptyView  = emptyView,
			gridView   = gridView,
			titleLabel = titleLabel,
			bodyLabel  = bodyLabel,
			-- textBg     = textBg,
			-- knowBtn    = knowBtn,
			scrollView = scrollView
		}
	end
	xTry(function ()
		-- create view
		self.viewData = CreateView()
		self.viewData.view:setPosition(cc.p(0, 0))
		self:addChild(self.viewData.view,1)
 	end, __G__TRACKBACK__)
end
function AnnouncementMediator:CloseHandler()
	if self.args.mediatorName and self.args.tag then
		local mediator = AppFacade.GetInstance():RetrieveMediator(self.args.mediatorName)
		if mediator then
			mediator:GetViewComponent():RemoveDialogByTag(self.args.tag)
		end
	end
	AppFacade.GetInstance():UnRegsitMediator("AnnouncementMediator")
end
return AnnouncementMediator

