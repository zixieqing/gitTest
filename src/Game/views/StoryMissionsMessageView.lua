--[[
剧情任务详情弹窗
--]]
local StoryMissionsMessageView = class('StoryMissionsMessageView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.StoryMissionsMessageView'
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")


--[[

--]]
-- function StoryMissionsMessageView:InitialUI()
function StoryMissionsMessageView:ctor( ... )
	self.args = unpack({...}) or {}
	local size = cc.size(590,550)
	self.viewData = nil
	self:setContentSize(size)
	-- self:setBackgroundColor(cc.c4b(100, 100, 100, 255))
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    self.eaterLayer:setVisible(false)

	local function CreateView()
		--滑动层背景图 
		local view = CLayout:create(size)
		view:setPosition(cc.p(0,0))
		view:setAnchorPoint(cc.p(0,0))
		self:addChild(view)
		view:setVisible(false)

		local bg = display.newImageView(_res('ui/common/commcon_bg_text1.png'), 0, 0,
		{ap = cc.p(0, 0)})	--scale9 = true, size = cc.size(610,550 ),
		view:addChild(bg)

		local desbg = display.newImageView(_res('ui/home/story/gut_task_bg_task_details.png'), size.width - 6, size.height - 20,
		{ap = cc.p(1, 1)})
		view:addChild(desbg)


		local desLabel = display.newLabel(desbg:getContentSize().width * 0.5,desbg:getContentSize().height - 10,
			fontWithColor(6,{text = '', ap = cc.p(0.5, 1),w = desbg:getContentSize().width - 30,h = desbg:getContentSize().height - 80}))
		desbg:addChild(desLabel, 6)

		local tempLabel = display.newLabel(15,58,
			fontWithColor(6,{text = __('任务目标：'), ap = cc.p(0, 0)}))
		desbg:addChild(tempLabel, 6)

		local targetLabel = display.newLabel(15,32,
			fontWithColor(10,{text = '', ap = cc.p(0, 0)}))
		desbg:addChild(targetLabel, 6)

		local progressLabel = display.newLabel(targetLabel:getBoundingBox().width + 4,32,
			fontWithColor(10,{text = '', ap = cc.p(0, 0)}))
		desbg:addChild(progressLabel, 6)


		local npcImg = display.newImageView(_res(CommonUtils.GetNpcIconPathById('role_1',3)), 4, size.height - 10,
		{ap = cc.p(0, 1)})
		view:addChild(npcImg)

		local nameBg = display.newImageView(_res('ui/home/story/gut_task_bg_name.png'),npcImg:getContentSize().width * 0.5,-22,
		{ap = cc.p(0.5, 0)})
		npcImg:addChild(nameBg,5)



		local npcNameLabel = display.newLabel(npcImg:getContentSize().width * 0.5,-20,
			fontWithColor(6,{text = '', color = 'ffffff', ap = cc.p(0.5, 0)}))
		npcImg:addChild(npcNameLabel, 6)

		local tempBtn = display.newButton(0, 0, {n = _res('ui/common/common_title_3.png')})
		display.commonUIParams(tempBtn, {ap = cc.p(0.5,0.5), po = cc.p(320,211)})
		display.commonLabelParams(tempBtn, fontWithColor(6,{text = __('奖励')}))
		view:addChild(tempBtn)

		local rewardsLayout = CLayout:create()--cc.size(320,100)
		rewardsLayout:setAnchorPoint(cc.p(0.5,0))
		rewardsLayout:setContentSize(cc.size(320,100))
		rewardsLayout:setPosition(cc.p(bg:getContentSize().width * 0.5,87))
		view:addChild(rewardsLayout)

		local goBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonUIParams(goBtn, {ap = cc.p(0.5,0), po = cc.p(bg:getContentSize().width * 0.5,10)})
		display.commonLabelParams(goBtn, fontWithColor(14,{text = __('前往')}))
		view:addChild(goBtn)

		local mainExpLabel = display.newLabel(420,211,
			fontWithColor(6,{text = '', color = 'cb4c49', ap = cc.p(0, 0.5)}))
		view:addChild(mainExpLabel, 6)


        -- 中间小人
	    local tipsCardQ = AssetsUtils.GetCartoonNode(3, size.width * 0.5, size.height * 0.5)
	    self:addChild(tipsCardQ, 6)
	    tipsCardQ:setScale(0.7)
	    tipsCardQ:setVisible(false)

		local tipsLabel = display.newLabel(470*0.5,-40,
			{text = __('任务全部完成'), fontSize = 28, color = '6c6c6c', ap = cc.p(0.5, 0)})
		tipsCardQ:addChild(tipsLabel, 6)

		return {
			view = view,
			bg = bg,
			npcNameLabel  = npcNameLabel,
			rewardsLayout = rewardsLayout,
			goBtn 		= goBtn,
			desLabel 	= desLabel,
			targetLabel = targetLabel,
			npcImg = npcImg,
			mainExpLabel 	= mainExpLabel,
			tipsCardQ = tipsCardQ,
			progressLabel = progressLabel,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end



return StoryMissionsMessageView
