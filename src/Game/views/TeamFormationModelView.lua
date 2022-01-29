--[[

--]]
local TeamFormationModelView = class('TeamFormationModelView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.TeamFormationModelView'
	node:enableNodeEvents()
	return node
end)
function TeamFormationModelView:ctor( ... )
	self.args = unpack({...}) or {}
	-- dump(self.args )



	local tablePosition = cc.p(checkint(self.args.pos.x),checkint(self.args.pos.y)) or cc.p(display.width * 0.5,display.height * 0.5)
	

	self.sceneClipNode = cc.ClippingNode:create()
	self.sceneClipNode:setContentSize(display.size)
	self.sceneClipNode:setPosition(cc.p(display.cx, display.cy))
	self.sceneClipNode:setAnchorPoint(cc.p(0.5, 0.5))
	self:addChild(self.sceneClipNode)
	local clipBg = CColorView:create(cc.c4b(0, 0, 0, 178.5))
	clipBg:setContentSize(display.size)
	clipBg:setAnchorPoint(cc.p(0.5, 0.5))
	clipBg:setPosition(cc.p(display.cx, display.cy))
	self.sceneClipNode:addChild(clipBg)
	self.stencilLayer = display.newImageView(_res('ui/common/common_bg_mask_light.png'), tablePosition.x, tablePosition.y)
	self.sceneClipNode:setAlphaThreshold(0)
	self.sceneClipNode:setInverted(true)
	self.sceneClipNode:setStencil(self.stencilLayer)

	local bg = display.newImageView(_res('ui/common/common_bg_mask_light.png'), 0, 0)
	local bgSize = bg:getContentSize()
	bg:setPosition(cc.p(bgSize.height / 2, bgSize.height / 2))
	local view = display.newLayer()
	view:setAnchorPoint(cc.p(0.5,0.5))
	view:setContentSize(bgSize)
	view:addChild(bg, -1)
	self:addChild(view,1)
	view:setPosition(tablePosition)
	-- view:setBackgroundColor(cc.c4b(128, 0, 0, 100))
	
	local itemsTab = {}
	local function CloseSelf()
		AppFacade.GetInstance():RetrieveMediator('TeamFormationMediator'):ModelCallback()
		for i,v in ipairs(itemsTab) do
			v:setOpacity(255)
	        v:runAction(cc.Sequence:create(
	        	cc.DelayTime:create(0.025*i),
	        	cc.Spawn:create(cc.FadeOut:create(0.1),
	        	cc.MoveTo:create(0.1,cc.p(bgSize.height / 2, bgSize.height / 2)))
				))
	        if i == table.nums(itemsTab) then
	        	self:runAction(cc.Sequence:create(
	        	cc.DelayTime:create(0.2),
				cc.RemoveSelf:create()))
	        end
		end
	end

	self.eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	self.eaterLayer:setTouchEnabled(true)
	self.eaterLayer:setContentSize(display.size)
	self.eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	self.eaterLayer:setPosition(cc.p(display.cx, display.height))
	self:addChild(self.eaterLayer, -1)
	self.eaterLayer:setOnClickScriptHandler(CloseSelf)


	local posTab = {
		{
			cc.p(116, 277),
			cc.p(200, 353),
			cc.p(284, 277),
			-- cc.p(40, 233),
		},
		{
			cc.p(146, 327),
			cc.p(250, 393),
			cc.p(354,327),
			-- cc.p(401, 293),
		},
	}

	local desTab = {
		{des = __('详情'),path = _res("ui/home/nmain/main_ico_detail.png")},
		{des = __('强化'),path = _res("ui/home/nmain/main_ico_card.png")},
		{des = __('冰箱'),path = _res("ui/home/nmain/main_ico_ice_ground.png")},
	}
	local usePosTab = {}
	if self.args.tag == 1 then
		usePosTab = posTab[1]
	else
		usePosTab = posTab[2]
	end

	
	for i=1,table.nums(desTab) do
		local layout = CLayout:create(cc.size(80, 110))
		local modelBtn = display.newButton(0, 0, {n = _res('ui/home/teamformation/newCell/team_frame_gongneng.png')})
		display.commonLabelParams(modelBtn, {ap = cc.p(0.5,0.5),text = desTab[i].des,ttf = true, font = TTF_GAME_FONT ,reqW = 85 ,fontSize = 24, color = 'ffffff',offset = cc.p(0,-40)})
		modelBtn:getLabel():enableOutline(cc.c4b(0, 0, 0, 255), 1)
		display.commonUIParams(modelBtn, {po = cc.p(40, 50)})

		layout:addChild(modelBtn)
		modelBtn:setOnClickScriptHandler(function (sender) 
			CloseSelf()
			AppFacade.GetInstance():RetrieveMediator('TeamFormationMediator'):ModelCallback({ tag = sender:getTag() })
		end)
		modelBtn:setTag(i)

		if desTab[i].path then
			local img = display.newImageView(desTab[i].path, 0, 0)
			img:setPosition(cc.p(modelBtn:getContentSize().width*0.5,modelBtn:getContentSize().height*0.5))
			modelBtn:addChild(img)
			img:setScale(0.8)
		else
			modelBtn:getLabel():setPositionY(40)
		end

		layout:setPosition(cc.p(bgSize.height / 2, bgSize.height / 2))
		view:addChild(layout)

		layout:setOpacity(0)
        layout:runAction(cc.Sequence:create(
        	cc.DelayTime:create(0.05*i),
        	cc.Spawn:create(cc.FadeIn:create(0.15),
        	cc.MoveTo:create(0.1,usePosTab[i]))
			))
        table.insert(itemsTab,layout)
	end

end

return TeamFormationModelView
