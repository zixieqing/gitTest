local GameScene = require('Frame.GameScene')
local ChooseLobbyPeopleView = class('ChooseLobbyPeopleView', GameScene)
--

function ChooseLobbyPeopleView:ctor( ... )
	self.args = unpack({...}) or {}
	local  cb  =  self.args.cb  or  function()
		PlayAudioByClickClose()
		AppFacade.GetInstance():UnRegsitMediator("ChooseLobbyPeopleMediator")
	end
	local hideSkill = self.args.hideSkill
	local size = cc.size(936,642)
	self.viewData = nil
	-- self:setName('Game.views.ChooseLobbyPeopleView')
	local view = require("common.TitlePanelBg").new({ title = __('飨灵之家'), type = 5, cb = cb, isGuide = GuideUtils.IsGuiding(), offsetY = 4})
    view:setName('TitlePanelBg')
    view.viewData.view:setName('viewDataView')
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	display.commonUIParams(view.viewData.view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	display.commonUIParams(view.viewData.tempLayer, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(view)
	local function CreateView() 
		local size = cc.size(1132,640)
		local cview = CLayout:create(size)
		view:AddContentView(cview)
	    -- cview:setBackgroundColor(cc.c4b(23, 67, 128, 128))
	    cview:setName('cview')

		--滑动层背景图 
		local ListBg = display.newImageView(_res("ui/common/common_bg_goods.png"), size.width - 26, 20,--
		{scale9 = true, size = cc.size(690, 560),ap = cc.p(1, 0)})	--630, size.height - 20
		cview:addChild(ListBg)
		local ListBgFrameSize = ListBg:getContentSize()
		--添加列表功能
		local taskListSize = cc.size(ListBgFrameSize.width - 2, ListBgFrameSize.height - 4)
		local taskListCellSize = cc.size(taskListSize.width/5 , 140)

		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(5)
		cview:addChild(gridView)
		gridView:setAnchorPoint(cc.p(1, 0))
		gridView:setPosition(cc.p(ListBg:getPositionX() , ListBg:getPositionY() ))
		-- gridView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
		gridView:setName('gridView')

		local clickCardNode = require('common.CardHeadNode').new({
			cardData = {cardId = 200022,level  = 66,breakLevel = 5}
			})
		clickCardNode:setScale(0.73)
		clickCardNode:setPosition(cc.p(210,size.height -  136))
		-- display.commonUIParams(clickCardNode, {animate = false, cb = handler(self, self.HeadCallback)})
		cview:addChild(clickCardNode)
		clickCardNode:setName('clickCardNode')

        local nameLabel = display.newLabel(210, size.height - 218,{
            ap = display.CENTER, fontSize = 22, color = '5c5c5c', text = " "
        })
        cview:addChild(nameLabel, 2)


 		local progressBG = display.newImageView(_res('ui/home/teamformation/newCell/refresh_bg_tired_2.png'), {
            scale9 = true, size = cc.size(170,28)
        })
        display.commonUIParams(progressBG, {po = cc.p(210, size.height -  246)})
        cview:addChild(progressBG)

	    local operaProgressBar = CProgressBar:create(_res('ui/home/teamformation/newCell/team_img_leaf_green.png'))
	    operaProgressBar:setBackgroundImage(_res('ui/home/teamformation/newCell/team_img_leaf_grey.png'))
	    operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
	    operaProgressBar:setAnchorPoint(cc.p(0.5, 0.5))
	    operaProgressBar:setMaxValue(100)
	    operaProgressBar:setValue(48)
	    operaProgressBar:setPosition(cc.p(195 , size.height -  246))
	    cview:addChild(operaProgressBar,1)
	    local vigourProgressBarTop =  display.newImageView(_res('ui/home/teamformation/newCell/team_img_leaf_free.png'),0,0,{as = false})
	    vigourProgressBarTop:setAnchorPoint(cc.p(0.5,0.5))
	    vigourProgressBarTop:setPosition(cc.p(195,size.height -  246))
	    cview:addChild(vigourProgressBarTop,2)

        local vigourLabel = display.newLabel( operaProgressBar:getPositionX() + operaProgressBar:getContentSize().width * 0.5 + 4, operaProgressBar:getPositionY(),{
            ap = display.LEFT_CENTER, fontSize = 18, color = 'ffffff', text = "100"
        })
        cview:addChild(vigourLabel, 2)


		local dialogue_tips = display.newButton(0, 0, {n = _res('ui/common/common_bg_tips_s.png')})
		display.commonUIParams(dialogue_tips, {ap = cc.p(0.5,0),po = cc.p(210,248)})
		display.commonLabelParams(dialogue_tips,{text = __('无经营技能'), fontSize = 24, color = '#ffffff'})
        cview:addChild(dialogue_tips, 6)

		local buttons = {}
		local skillDesView, desLabel, typeLabel, img, bg
		if not hideSkill then
			for i=1,4 do
				local tabButton = display.newCheckBox(0,0,
					{n = _res('ui/home/lobby/peopleManage/restaurant_recharge_btn_skill_default.png'),
					s = _res('ui/home/lobby/peopleManage/restaurant_recharge_btn_skill_selected.png')})
				local buttonSize = tabButton:getContentSize()		
				
				display.commonUIParams(
					tabButton, 
					{
						ap = cc.p(0.5, 0),
						po = cc.p(230  ,
								304 - (i-1)*(buttonSize.height+2))
					})
				cview:addChild(tabButton)
				tabButton:setTag(i)
				table.insert(buttons,tabButton)
	
				local tabNameLabel1 = display.newLabel(78,50,
					{text = '名字', fontSize = 22, color = 'b1613a', ap = cc.p(0, 0.5)})--2b2017
				tabButton:addChild(tabNameLabel1)
				tabNameLabel1:setTag(5)
	
	
				local tabNameLabel2 = display.newLabel(78,25,
					{text = __('未解锁'), fontSize = 22, color = 'b1613a', ap = cc.p(0, 0.5)})--2b2017
				tabButton:addChild(tabNameLabel2)
				tabNameLabel2:setTag(8)
	
	
				local tabLvLabel1 = display.newLabel(78 ,25,
					{ text = '等级：1', fontSize = 22, color = '5c5c5c', ap = cc.p(0, 0.5)})--2b2017
				tabButton:addChild(tabLvLabel1)
				tabLvLabel1:setTag(6)
	
	
				local skillBg = FilteredSpriteWithOne:create()
				skillBg:setAnchorPoint(cc.p(0,0.5))
				skillBg:setScale(0.5)
				skillBg:setPosition(cc.p(10, buttonSize.height * 0.5))
				skillBg:setTexture(_res('ui/cards/skillNew/card_skill_bg_skill.png'))
				tabButton:addChild(skillBg,1)
	
	
				local skillImg = FilteredSpriteWithOne:create()
				skillImg:setAnchorPoint(cc.p(0,0.5))
				skillImg:setScale(0.35)
				skillImg:setPosition(cc.p(13, buttonSize.height * 0.5))
				skillImg:setTexture(_res(CommonUtils.GetSkillIconPath(9999)))
				tabButton:addChild(skillImg,2)
				skillImg:setTag(7)
	
				-- local skillBg = display.newImageView(_res('ui/cards/skillNew/card_skill_bg_skill.png'),10, buttonSize.height * 0.5 )
				-- skillBg:setAnchorPoint(cc.p(0,0.5))
				-- tabButton:addChild(skillBg,1)
				-- skillBg:setScale(0.5)
				
				-- local skillImg = display.newImageView(_res(CommonUtils.GetSkillIconPath(9999)),13, buttonSize.height * 0.5 )
				-- skillImg:setAnchorPoint(cc.p(0,0.5))
				-- skillImg:setScale(0.35)
				-- tabButton:addChild(skillImg,2)
				-- skillImg:setTag(7)
	
	
				for j=1,4 do
					-- local typeImg = display.newImageView(_res('ui/home/lobby/peopleManage/restaurant_manage_ico_manager.png'),buttonSize.width - 60 + 30 * (j-1), buttonSize.height * 0.5 )
					-- typeImg:setAnchorPoint(cc.p(1,0.5))
					-- typeImg:setScale(0.2)
					-- tabButton:addChild(typeImg,2)
					-- typeImg:setTag(j+10)
	
	
					local typeImg = FilteredSpriteWithOne:create()
					typeImg:setAnchorPoint(cc.p(1,0.5))
					typeImg:setScale(0.2)
					typeImg:setPosition(cc.p(buttonSize.width - 60 + 30 * (j-1), buttonSize.height * 0.5))
					typeImg:setTexture(_res('ui/home/lobby/peopleManage/restaurant_manage_ico_manager.png'))
					tabButton:addChild(typeImg,2)
					typeImg:setTag(j+10)
	
				end
	
			end

			skillDesView = CLayout:create(cc.size(380,194))
			skillDesView:setAnchorPoint(cc.p(0, 0.5))
			skillDesView:setPosition(cc.p(buttons[1]:getPositionX()+175,buttons[1]:getPositionY()+40))
			cview:addChild(skillDesView,10)
			-- skillDesView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
			skillDesView:setVisible(false)
			desLabel = display.newLabel(190, 92,{
				w = 300,h = 150,ap = display.CENTER, fontSize = 22, color = '5c5c5c', text = " "
			})
			skillDesView:addChild(desLabel, 2)
	
			typeLabel = display.newLabel(190, 20,{
			   ap = display.CENTER, fontSize = 22, color = '5c5c5c', text = " "
			})
			skillDesView:addChild(typeLabel, 2)
	
			img = display.newImageView(_res('ui/home/lobby/peopleManage/common_bg_tips_horn.png'))
			display.commonUIParams(img, {ap = cc.p(0, 0.5),po = cc.p(10,92)})
			img:setRotation(90)
			skillDesView:addChild(img,1)
	
			bg = display.newImageView(_res('ui/common/common_bg_tips.png'))
			display.commonUIParams(bg, {ap = cc.p(0, 0),po = cc.p(10,0)})
			skillDesView:addChild(bg)
		end

		local chooseCardBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonUIParams(chooseCardBtn, {ap = cc.p(0.5,0),po = cc.p(210,16)})
		display.commonLabelParams(chooseCardBtn, fontWithColor(14,{text = __('替换'),fontSize = 24, color = 'ffffff'}))
        cview:addChild(chooseCardBtn)
        chooseCardBtn:setName('chooseCardBtn')
		return {
			view 		= view,
			cview 		= cview,
			gridView	= gridView,
			clickCardNode = clickCardNode,

			nameLabel = nameLabel,
			operaProgressBar = operaProgressBar,
			vigourLabel = vigourLabel,
			chooseCardBtn = chooseCardBtn,
			buttons = buttons,
			dialogue_tips = dialogue_tips,


			skillDesView = skillDesView,
			desLabel = desLabel,
			typeLabel = typeLabel,
		} 
	end
	xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)


end

return ChooseLobbyPeopleView
