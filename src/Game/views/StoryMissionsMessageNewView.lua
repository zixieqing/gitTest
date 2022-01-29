--[[
剧情任务详情弹窗
--]]
local StoryMissionsMessageNewView = class('StoryMissionsMessageNewView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.StoryMissionsMessageNewView'
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")


--[[

--]]
-- function StoryMissionsMessageNewView:InitialUI()
function StoryMissionsMessageNewView:ctor( ... )
	self.args = unpack({...}) or {}
	local size = cc.size(444,550)
	self.viewData = nil
	self:setContentSize(size)
	-- self:setBackgroundColor(cc.c4b(100, 100, 100, 255))

	local function CreateView()
		--滑动层背景图
		local view = CLayout:create(size)
        view:setName('ContentView')
		view:setPosition(cc.p(0,0))
		view:setAnchorPoint(cc.p(0,0))
		self:addChild(view)
		view:setVisible(false)

		local desbg = display.newImageView(_res('ui/home/story/gut_task_bg_task_details.png'), size.width - 5, size.height ,
		{ap = cc.p(1, 1)})
		view:addChild(desbg)



		local tempLabel = display.newLabel(15,desbg:getContentSize().height - 40,
			fontWithColor(4,{text = __('任务描述'), ap = cc.p(0, 0)}))
		desbg:addChild(tempLabel, 6)

        local descrViewSize  = cc.size(desbg:getContentSize().width - 20, desbg:getContentSize().height - 50)
        local descrContainer = cc.ScrollView:create()
        descrContainer:setPosition(cc.p(10, 10))
        descrContainer:setDirection(eScrollViewDirectionVertical)
        descrContainer:setViewSize(descrViewSize)
        desbg:addChild(descrContainer, 10)

		local desLabel = display.newLabel(0, 0,
			fontWithColor(6,{text = '', w = desbg:getContentSize().width - 20}))
        descrContainer:setContainer(desLabel)
		-- desbg:addChild(desLabel, 6)


		local reReadBtn = display.newButton(0, 0, {n = _res('ui/home/story/task_btn_playback.png')})
		display.commonUIParams(reReadBtn, {ap = cc.p(1,0), po = cc.p(size.width ,size.height - desbg:getContentSize().height - 10)})
		view:addChild(reReadBtn)


		local desbg1 = display.newImageView(_res('ui/home/story/gut_task_bg_task_details.png'), size.width - 5, size.height - desbg:getContentSize().height - 4,
		{ap = cc.p(1, 1)})
		view:addChild(desbg1)

		local tempLabel = display.newLabel(15,desbg1:getContentSize().height - 40,
			fontWithColor(4,{text = __('任务目标'), ap = cc.p(0, 0)}))
		desbg1:addChild(tempLabel, 6)

		local targetLabel = display.newLabel(15,desbg1:getContentSize().height - 40,
			fontWithColor(10,{text = '', ap = cc.p(0, 1),w = desbg1:getContentSize().width - 30,h = desbg1:getContentSize().height - 80}))
		desbg1:addChild(targetLabel, 6)

        local lwidth = display.getLabelContentSize(tempLabel).width
		local progressLabel = display.newLabel(lwidth + 10,desbg1:getContentSize().height - 38,
			fontWithColor(10,{text = '', ap = cc.p(0, 0)}))
		desbg1:addChild(progressLabel, 6)

		local bgSpine = sp.SkeletonAnimation:create('effects/storyAnimate/juqing.json', 'effects/storyAnimate/juqing.atlas', 1)
		bgSpine:update(0)
		bgSpine:setAnimation(0, 'idle', true)--shengxing1 shengji
		desbg1:addChild(bgSpine,100)
		bgSpine:setPosition(cc.p(desbg1:getContentSize().width* 0.5,desbg1:getContentSize().height* 0.5))



		local targetDesLabel = display.newLabel(desbg1:getContentSize().width* 0.5,desbg1:getContentSize().height* 0.5,
			fontWithColor(14,{text = __('点击接受任务，查看任务目标'), ap = cc.p(0.5, 0.5), w = 370, h = 100}))
		desbg1:addChild(targetDesLabel, 106)

		local tempBtn = display.newButton(0, 0, {n = _res('ui/home/story/task_bg_font_name.png')})
		display.commonUIParams(tempBtn, {ap = cc.p(0.5,0.5), po = cc.p(222,226)})
		display.commonLabelParams(tempBtn, fontWithColor(4,{text = __('任务奖励')}))
		view:addChild(tempBtn)
		tempBtn:setName('rewardLabel')

		local rewardsLayout = CLayout:create()--cc.size(320,100)
		rewardsLayout:setAnchorPoint(cc.p(0.5,0))
		rewardsLayout:setContentSize(cc.size(320,100))
		rewardsLayout:setPosition(cc.p(size.width * 0.5,77))
		view:addChild(rewardsLayout)

		local goBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'), scale9 = true, size = cc.size(144, 62)})
		display.commonUIParams(goBtn, {ap = cc.p(0.5,0), po = cc.p(size.width * 0.5,10)})
        goBtn:setName('GotoBtn')
		display.commonLabelParams(goBtn, fontWithColor(14,{text = __('前往')}))
		view:addChild(goBtn)

		local tempLabel = display.newLabel(224,192,
			fontWithColor(6,{text = __('主角经验'),reqW =220,   ap = cc.p(1.0, 0.5)}))
		view:addChild(tempLabel, 6)



		local expImg = display.newImageView(_res('ui/common/common_ico_exp.png'),230,192)
		expImg:setAnchorPoint(cc.p(0,0.5))
		expImg:setScale(0.2)
		view:addChild(expImg)


		local mainExpLabel = display.newLabel(270,192,
			fontWithColor(10,{text = '', color = 'cb4c49', ap = cc.p(0, 0.5)}))
		view:addChild(mainExpLabel, 6)


        -- 中间小人
	    local tipsCardQ = AssetsUtils.GetCartoonNode(3, size.width * 0.50, size.height * 0.58)
	    self:addChild(tipsCardQ, 6)
	    tipsCardQ:setScale(0.7)
	    tipsCardQ:setVisible(false)

		local tipsLabel = display.newLabel(470*0.5,-40,
			{text = __('任务已完成'), fontSize = 28, color = '6c6c6c', ap = cc.p(0.5, 0)})
		tipsCardQ:addChild(tipsLabel, 6)

		return {
			view = view,
			-- npcNameLabel  = npcNameLabel,
			rewardsLayout = rewardsLayout,
			goBtn 		= goBtn,
            descrContainer = descrContainer,
			desLabel 	= desLabel,
			targetLabel = targetLabel,
			-- npcImg = npcImg,
			mainExpLabel 	= mainExpLabel,
			tipsCardQ = tipsCardQ,
			progressLabel = progressLabel,
			reReadBtn = reReadBtn,
			bgSpine = bgSpine,
			targetDesLabel = targetDesLabel,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end



return StoryMissionsMessageNewView
