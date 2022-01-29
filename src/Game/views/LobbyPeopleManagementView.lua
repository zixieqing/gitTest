local GameScene = require('Frame.GameScene')
local LobbyPeopleManagementView = class('LobbyPeopleManagementView', GameScene)


function LobbyPeopleManagementView:ctor( ... )
	self.args = unpack({...}) or {}
	local size = cc.size(936,642)
	self.viewData = nil

    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 140))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)


	local view = CLayout:create(display.size)
	view:setAnchorPoint(display.CENTER)
	view:setPosition(cc.p(display.cx, display.cy))
	view:setName('view')
	self:addChild(view)
	-- view.viewData.view:setPositionX(display.cx+ 211)
	local function CreateView()
		local size = cc.size(860,644)
		local cview = CLayout:create(size)
		display.commonUIParams(cview, {ap = cc.p(1,0.5), po = cc.p(display.SAFE_R + 4,display.cy)})
		view:addChild(cview,10)
		cview:setName('cview')
		-- view:AddContentView(cview)
	    -- cview:setBackgroundColor(cc.c4b(23, 67, 128, 128))
	    --滑动层背景图
		-- local bg = display.newImageView(_res("ui/home/lobby/peopleManage/restaurant_manage_bg.png"), 44, size.height - 60,--
		-- {ap = cc.p(0, 1)})	--630, size.height - 20
		-- cview:addChild(bg)

		local bgImg = display.newImageView(_res("ui/common/common_bg_4.png"), size.width * 0.5, size.height * 0.5,--
		{ap = cc.p(0.5, 0.5),scale9 = true, size = size})	--630, size.height - 20
		cview:addChild(bgImg)

		local tabNameLabel = display.newButton(display.SAFE_L + 120, display.height ,{n = _res('ui/common/common_title.png'),enable = false,ap = cc.p(0, 1.0)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('办公室'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		view:addChild(tabNameLabel,10)

		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
		display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30,display.size.height - 18 - backBtn:getContentSize().height * 0.5)})
		view:addChild(backBtn, 5)
		backBtn:setName('backBtn')
		local tag = 1
	    --主管
		local supervisorView = CLayout:create(cc.size(460,642))
		view:addChild(supervisorView)
		supervisorView:setAnchorPoint(cc.p(0,0.5))
		-- supervisorView:setPosition(cc.p(display.SAFE_L + 8,display.height - TOP_HEIGHT))
		supervisorView:setPosition(cc.p(display.SAFE_L + 8,display.cy))
        -- supervisorView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
		supervisorView:setName('supervisorView')
		local chooseSupervisorBtn = display.newButton(supervisorView:getContentSize().width * 0.5,  supervisorView:getContentSize().height * 0.5, {n = _res('ui/home/lobby/peopleManage/restaurant_manage_btn_add_people.png')})
		supervisorView:addChild(chooseSupervisorBtn,1)
		chooseSupervisorBtn:setTag(tag)
		chooseSupervisorBtn:setName('chooseSupervisorBtn')

		local supervisorImg = require( "common.CardSkinDrawNode" ).new({confId = 200024, coordinateType = COORDINATE_TYPE_HOME})
		supervisorView:addChild(supervisorImg,1)
		supervisorImg:GetAvatar():setScale(0.8)
		supervisorImg:setVisible(false)
        local y = supervisorImg:getPositionY()
        local offsetY = display.cy - 321
        supervisorImg:setPositionY(y - offsetY)
		supervisorImg:GetAvatar():setTag(tag)
		-- supervisorImg:setBackgroundColor(cc.c4b(23, 67, 128, 128))

		local supervisorLight = sp.SkeletonAnimation:create('effects/restaurantLight/restaurant_manage_ico_light.json', 'effects/restaurantLight/restaurant_manage_ico_light.atlas',1)
	    supervisorLight:update(0)
	    supervisorLight:setAnimation(0, 'idle', true)
	    supervisorLight:setPosition(cc.p(supervisorView:getContentSize().width * 0.5,supervisorView:getContentSize().height - 100))
	    supervisorView:addChild(supervisorLight,2)
	    supervisorLight:setVisible(false)

		tag = tag + 1
		local tempImg = display.newImageView(_res("ui/home/lobby/peopleManage/restaurant_manage_bg_skill.png"), supervisorView:getContentSize().width * 0.5, 2,--
		{ap = cc.p(0.5, 0)})	--630, size.height - 20



		local skillLayout = CLayout:create(tempImg:getContentSize())
		supervisorView:addChild(skillLayout,3)
		skillLayout:setAnchorPoint(cc.p(0.5,0))
		skillLayout:setPosition(cc.p(supervisorView:getContentSize().width * 0.5,2))
		skillLayout:addChild(tempImg)

		local desLabel = display.newLabel(supervisorView:getContentSize().width * 0.5,160,
			{ttf = true, font = TTF_GAME_FONT, text = __('主管'), fontSize = 24, color = 'ffffff', ap = cc.p(0.5, 1)})--2b2017
		skillLayout:addChild(desLabel,1)


		local skillImg  = {}
		for i=1,4 do

			local skillBg = display.newImageView(_res('ui/cards/skillNew/card_skill_bg_skill.png'),90 + 100*(i-1),80 )
			skillBg:setAnchorPoint(cc.p(0,0.5))
			skillLayout:addChild(skillBg,1)
			skillBg:setScale(0.8)
			skillBg:setVisible(false)

			local skillImg1 = display.newImageView(_res("ui/common/team_lead_skill_frame_l.png"),skillBg:getContentSize().width*0.5, skillBg:getContentSize().height*0.5,--
			{ap = cc.p(0.5, 0.5)})	--630, size.height - 20
			skillBg:addChild(skillImg1,2)
			skillImg1:setScale(0.7)
			-- skillImg:setVisible(false)
			skillImg1:setTag(1)

			local skillLvLabel = display.newLabel(64,-35,
				{ttf = true, font = TTF_GAME_FONT, text = (' '), fontSize = 24, color = 'ffffff', ap = cc.p(0.5, 0)})--2b2017
			skillBg:addChild(skillLvLabel,1)
			-- skillLvLabel:setScale(1.2)
			skillLvLabel:setTag(2)

			table.insert(skillImg,skillBg)
		end


		local tipsLabel = display.newLabel(211,80,
			{ttf = true, font = TTF_GAME_FONT, text = __('无主管经营技能'), fontSize = 24, color = 'ffffff', ap = cc.p(0.5, 0.5)})--2b2017
		skillLayout:addChild(tipsLabel,1)
		tipsLabel:setVisible(false)

	    --主厨和副厨
		local cookerView = CLayout:create(cc.size(846,365))
		cview:addChild(cookerView)
		cookerView:setAnchorPoint(cc.p(0,1))
		cookerView:setPosition(cc.p(6,size.height-6))
		-- cookerView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
		cookerView:setName('cookerView')
		local bgImg = display.newImageView(_res("ui/home/lobby/peopleManage/restaurant_manage_bg_frame.png"), cookerView:getContentSize().width * 0.5 , cookerView:getContentSize().height * 0.5,--
		{ap = cc.p(0.5, 0.5)})	--630, size.height - 20
		cookerView:addChild(bgImg,4)


		local config1 = {__('主厨'),__('副厨')}
		local cookerAllCellTab = {}
		for i=1,2 do
			local tempTab = {}
			local tempView = CLayout:create(cc.size(361,299))
			tempView:setName("cellView_"..i)
			cookerView:addChild(tempView,i)
			tempView:setPosition(cc.p(34+tempView:getContentSize().width * 0.5 + 400* (i-1),cookerView:getContentSize().height * 0.5))
			-- tempView:setBackgroundColor(cc.c4b(23, 67, 128, 128))

			local bgImg = display.newImageView(_res("ui/home/lobby/peopleManage/restaurant_manage_bg_chefroom.png"), tempView:getContentSize().width * 0.5, tempView:getContentSize().height * 0.5,--
			{ap = cc.p(0.5, 0.5)})	--630, size.height - 20
			tempView:addChild(bgImg)


			local doorImg = display.newImageView(_res("ui/home/lobby/peopleManage/restaurant_manage_bg_door.png"), tempView:getContentSize().width + 8, tempView:getContentSize().height * 0.5 - 4,--
			{ap = cc.p(1, 0.5)})	--630, size.height - 20
			tempView:addChild(doorImg,7)
			-- doorImg:setVisible(false)


	        local progressBG = display.newImageView(_res('avatar/ui/recovery_bg.png'), {
	            scale9 = true, size = cc.size(170,28)
	        })
	        display.commonUIParams(progressBG, {po = cc.p(tempView:getContentSize().width * 0.5 , 25)})
	        tempView:addChild(progressBG,2)
	        progressBG:setVisible(false)
		    local operaProgressBar = CProgressBar:create(_res('ui/home/teamformation/newCell/team_img_leaf_green.png'))
		    operaProgressBar:setBackgroundImage(_res('ui/home/teamformation/newCell/team_img_leaf_grey.png'))
		    operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
		    operaProgressBar:setAnchorPoint(cc.p(0.5, 0.5))
		    operaProgressBar:setMaxValue(100)
		    operaProgressBar:setValue(0)
		    operaProgressBar:setPosition(cc.p(tempView:getContentSize().width * 0.5 - 15 , 25))
		    tempView:addChild(operaProgressBar,2)
		    operaProgressBar:setVisible(false)
		    local vigourProgressBarTop =  display.newImageView(_res('ui/home/teamformation/newCell/team_img_leaf_free.png'),0,0,{as = false})
		    vigourProgressBarTop:setAnchorPoint(cc.p(0.5,0.5))
		    vigourProgressBarTop:setPosition(cc.p(tempView:getContentSize().width * 0.5 - 15 ,25))
		    tempView:addChild(vigourProgressBarTop,3)
		    vigourProgressBarTop:setVisible(false)

	        local vigourLabel = display.newLabel( operaProgressBar:getPositionX() + operaProgressBar:getContentSize().width * 0.5 + 4, operaProgressBar:getPositionY(),{
	            ap = display.LEFT_CENTER, fontSize = 18, color = 'ffffff', text = " "
	        })
	        tempView:addChild(vigourLabel, 3)


	        local baseBG = display.newImageView(_res('ui/home/lobby/peopleManage/restaurant_manage_label_chef.png'))
	        display.commonUIParams(baseBG, {po = cc.p(tempView:getContentSize().width * 0.5 , 45)})
	        tempView:addChild(baseBG,1)


			local nameLabel = display.newLabel(tempView:getContentSize().width * 0.5 , 50,
				{ttf = true, font = TTF_GAME_FONT, text = ' ', fontSize = 22, color = 'ffffff', ap = cc.p(0.5, 0.5)})--2b2017
			nameLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			tempView:addChild(nameLabel,3)
			local nameLabelParams = {font = TTF_GAME_FONT, outline = cc.c4b(0, 0, 0, 255), fontSize = 22, color = 'ffffff', fontSizeN = 22, colorN = 'ffffff'}


	        -- local lightImg = display.newImageView(_res('ui/home/lobby/peopleManage/restaurant_manage_ico_light.png'))
	        -- display.commonUIParams(lightImg, {ap = cc.p(0.5,0),po = cc.p(tempView:getContentSize().width * 0.5 , 50)})
	        -- tempView:addChild(lightImg)


    		local dialogue_tips = display.newButton(0, 0, {n = _res('ui/common/common_title_5.png'), scale9 = true })
			display.commonUIParams(dialogue_tips, {ap = cc.p(0.5,1),po = cc.p(34+tempView:getContentSize().width * 0.5 + 423* (i-1),345)})
			display.commonLabelParams(dialogue_tips,{text = config1[i], fontSize = 20, color = '#4c4c4c', paddingW = 30 })
	        cookerView:addChild(dialogue_tips,5)


			local desLabel = display.newLabel(tempView:getContentSize().width * 0.5 , tempView:getContentSize().height - 30,
				{h = 50,w= 120,text = ' ', fontSize = 20, color = '4c4c4c', ap = cc.p(0.5, 1)})--2b2017
			tempView:addChild(desLabel,2)

    		local chooseCookerBtn = display.newButton(0, 0, {n = _res('ui/home/lobby/peopleManage/restaurant_manage_bg_people_state.png')})
			display.commonUIParams(chooseCookerBtn, {ap = cc.p(0.5,0.5),po = cc.p(tempView:getContentSize().width * 0.5,tempView:getContentSize().height * 0.6)})
	        tempView:addChild(chooseCookerBtn, 8)
	        chooseCookerBtn:setTag(tag)
	        chooseCookerBtn:setName("chooseCookerBtn_"..i)

    		local addImg = display.newImageView(_res('ui/common/maps_fight_btn_pet_add.png'), 0, 0)
			display.commonUIParams(addImg, {ap = cc.p(0.5, 0.5), po = cc.p(chooseCookerBtn:getContentSize().width * 0.5,chooseCookerBtn:getContentSize().height * 0.5)})
			chooseCookerBtn:addChild(addImg,5)
			addImg:setVisible(false)

    		local lockImg = display.newImageView(_res('ui/common/common_ico_lock.png'), 0, 0)
			display.commonUIParams(lockImg, {ap = cc.p(0.5, 0.5), po = cc.p(chooseCookerBtn:getContentSize().width * 0.5,chooseCookerBtn:getContentSize().height * 0.5)})
			chooseCookerBtn:addChild(lockImg,5)
			lockImg:setVisible(false)

    		local qBg = display.newImageView(_res('ui/common/comon_bg_frame_gey.png'), 0, 0, {scale9 = true, size = chooseCookerBtn:getContentSize()})
			display.commonUIParams(qBg, {ap = cc.p(0.5, 0), po = cc.p(tempView:getContentSize().width * 0.5,70)})
			tempView:addChild(qBg)
			qBg:setOpacity(0)
			qBg:setCascadeOpacityEnabled(true)
			qBg:setTag(tag)

    		local trashImg1 = display.newImageView(_res('ui/home/lobby/peopleManage/restaurant_manage_bg_trash1.png'), 0, 0)
			display.commonUIParams(trashImg1, {ap = cc.p(0, 0), po = cc.p(0,0)})
			tempView:addChild(trashImg1,9)
			trashImg1:setVisible(false)

    		local trashImg2 = display.newImageView(_res('ui/home/lobby/peopleManage/restaurant_manage_bg_trash2.png'), 0, 0)
			display.commonUIParams(trashImg2, {ap = cc.p(1, 0), po = cc.p(tempView:getContentSize().width,0)})
			tempView:addChild(trashImg2,9)
			trashImg2:setVisible(false)

	        tempTab.view = tempView
	        tempTab.trashImg1 = trashImg1
	        tempTab.trashImg2 = trashImg2
	        tempTab.doorImg = doorImg
    	    tempTab.progressBG = progressBG
	        tempTab.vigourProgressBarTop = vigourProgressBarTop
	        tempTab.operaProgressBar = operaProgressBar
	        tempTab.vigourLabel = vigourLabel
	        tempTab.nameLabel = nameLabel
	        tempTab.nameLabelParams = nameLabelParams
	        tempTab.desLabel = desLabel
	        tempTab.chooseCookerBtn = chooseCookerBtn
	        tempTab.addImg = addImg
	        tempTab.lockImg = lockImg
	        tempTab.qBg = qBg
	        -- table.insert(cookerAllCellTab ,tempTab)
	        cookerAllCellTab[tostring(tag)] = tempTab
	        tag = tag + 1
		end


	    --服务员layout
		local waiterView = CLayout:create(cc.size(845,278))
		cview:addChild(waiterView)
		waiterView:setAnchorPoint(cc.p(0,0))
		waiterView:setPosition(cc.p(4,0))
		-- waiterView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
		waiterView:setName('waiterView')

		local bgImg = display.newImageView(_res("ui/home/lobby/peopleManage/restaurant_manage_bg_waiters.png"), waiterView:getContentSize().width * 0.5, waiterView:getContentSize().height * 0.5,--
		{ap = cc.p(0.5, 0.5)})	--630, size.height - 20
		waiterView:addChild(bgImg)


		local dialogue_tips = display.newButton(0, 0, {n = _res('ui/common/common_title_5.png')})
		display.commonUIParams(dialogue_tips, {ap = cc.p(0.5,1),po = cc.p(waiterView:getContentSize().width * 0.5,waiterView:getContentSize().height)})
		display.commonLabelParams(dialogue_tips,{text = __('服务员'), fontSize = 20, color = '#4c4c4c'})
	    waiterView:addChild(dialogue_tips)


		local waiterAllCellTab = {}
		for i=1,4 do
			local tempTab = {}
			local tempView = CLayout:create(cc.size(200,240))
			waiterView:addChild(tempView)
			tempView:setPosition(cc.p(tempView:getContentSize().width * 0.5 + 20 + 200* (i-1),waiterView:getContentSize().height * 0.5))
			-- tempView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
			tempView:setName("cellView_"..i)

	        local progressBG = display.newImageView(_res('avatar/ui/recovery_bg.png'), {
	            scale9 = true, size = cc.size(170,28)
	        })
	        display.commonUIParams(progressBG, {po = cc.p(tempView:getContentSize().width * 0.5 , 25)})
	        tempView:addChild(progressBG)
	        progressBG:setVisible(false)
		    local operaProgressBar = CProgressBar:create(_res('ui/home/teamformation/newCell/team_img_leaf_green.png'))
		    operaProgressBar:setBackgroundImage(_res('ui/home/teamformation/newCell/team_img_leaf_grey.png'))
		    operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
		    operaProgressBar:setAnchorPoint(cc.p(0.5, 0.5))
		    operaProgressBar:setMaxValue(100)
		    operaProgressBar:setValue(44)
		    operaProgressBar:setPosition(cc.p(tempView:getContentSize().width * 0.5 - 15 , 25))
		    tempView:addChild(operaProgressBar,1)
		    operaProgressBar:setVisible(false)
		    local vigourProgressBarTop =  display.newImageView(_res('ui/home/teamformation/newCell/team_img_leaf_free.png'),0,0,{as = false})
		    vigourProgressBarTop:setAnchorPoint(cc.p(0.5,0.5))
		    vigourProgressBarTop:setPosition(cc.p(tempView:getContentSize().width * 0.5 - 15 ,25))
		    tempView:addChild(vigourProgressBarTop,2)
		    vigourProgressBarTop:setVisible(false)

	        local vigourLabel = display.newLabel( operaProgressBar:getPositionX() + operaProgressBar:getContentSize().width * 0.5 + 4, operaProgressBar:getPositionY(),{
	            ap = display.LEFT_CENTER, fontSize = 18, color = 'ffffff', text = " "
	        })
	        tempView:addChild(vigourLabel, 2)


	        local baseBG = display.newImageView(_res('ui/home/lobby/peopleManage/restaurant_manage_bg_people_base.png'))
	        display.commonUIParams(baseBG, {po = cc.p(tempView:getContentSize().width * 0.5 , 66)})
	        tempView:addChild(baseBG)


			local nameLabel = display.newLabel(tempView:getContentSize().width * 0.5 , 50,
				{ttf = true, font = TTF_GAME_FONT, text = ' ', fontSize = 22, color = 'ffffff', ap = cc.p(0.5, 0.5)})--2b2017
			nameLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			tempView:addChild(nameLabel,2)
			local nameLabelParams = {font = TTF_GAME_FONT, outline = cc.c4b(0, 0, 0, 255), fontSize = 22, color = 'ffffff', fontSizeN = 22, colorN = 'ffffff'}


	        -- local lightImg = display.newImageView(_res('ui/home/lobby/peopleManage/restaurant_manage_ico_light.png'))
	        -- display.commonUIParams(lightImg, {ap = cc.p(0.5,0),po = cc.p(tempView:getContentSize().width * 0.5 , 50)})
	        -- tempView:addChild(lightImg,-1)


			local switchDesLabel = display.newLabel(tempView:getContentSize().width * 0.5 , tempView:getContentSize().height - 20 ,
				{text = ' ', fontSize = 20, color = '4c4c4c', ap = cc.p(0.5, 1)})--2b2017
			tempView:addChild(switchDesLabel,2)

    		local chooseWaiterBtn = display.newButton(0, 0, {n = _res('ui/home/lobby/peopleManage/restaurant_manage_bg_people_state.png')})
			display.commonUIParams(chooseWaiterBtn, {ap = cc.p(0.5,0),po = cc.p(tempView:getContentSize().width * 0.5,90)})
	        tempView:addChild(chooseWaiterBtn, 6)
	        chooseWaiterBtn:setTag(tag)
	        chooseWaiterBtn:setName("chooseWaiterBtn_"..i)

    		local addImg = display.newImageView(_res('ui/common/maps_fight_btn_pet_add.png'), 0, 0)
			display.commonUIParams(addImg, {ap = cc.p(0.5, 0.5), po = cc.p(chooseWaiterBtn:getContentSize().width * 0.5,chooseWaiterBtn:getContentSize().height * 0.5)})
			chooseWaiterBtn:addChild(addImg,5)
			addImg:setVisible(false)

    		local lockImg = display.newImageView(_res('ui/common/common_ico_lock.png'), 0, 0)
			display.commonUIParams(lockImg, {ap = cc.p(0.5, 0.5), po = cc.p(chooseWaiterBtn:getContentSize().width * 0.5,chooseWaiterBtn:getContentSize().height * 0.5)})
			chooseWaiterBtn:addChild(lockImg,5)
			lockImg:setVisible(false)

    		local qBg = display.newImageView(_res('ui/common/comon_bg_frame_gey.png'), 0, 0, {scale9 = true, size = chooseWaiterBtn:getContentSize()})
			display.commonUIParams(qBg, {ap = cc.p(0.5, 0), po = cc.p(tempView:getContentSize().width * 0.5,90)})
			tempView:addChild(qBg,5)
			qBg:setOpacity(0)
			qBg:setCascadeOpacityEnabled(true)
			qBg:setTag(tag)

	        tempTab.view = tempView
	        tempTab.progressBG = progressBG
	        tempTab.vigourProgressBarTop = vigourProgressBarTop
	        tempTab.operaProgressBar = operaProgressBar
	        tempTab.vigourLabel = vigourLabel
	        tempTab.nameLabel = nameLabel
	        tempTab.nameLabelParams = nameLabelParams
	        -- tempTab.desLabel = desLabel

	    	tempTab.switchDesLabel= switchDesLabel

	        tempTab.chooseWaiterBtn = chooseWaiterBtn
	        tempTab.addImg = addImg
	        tempTab.lockImg = lockImg
	        tempTab.qBg = qBg

	        -- table.insert(waiterAllCellTab ,tempTab)

	        waiterAllCellTab[tostring(tag)] = tempTab
	        tag = tag + 1
		end


		return {
			view 		= view,
			cview 		= cview,
			tipsLabel = tipsLabel,
			skillImg = skillImg,
			-- skillBg = skillBg,
			chooseSupervisorBtn	= chooseSupervisorBtn,
			cookerAllCellTab = cookerAllCellTab,
			waiterAllCellTab = waiterAllCellTab,
			tabNameLabel = tabNameLabel,
			tabNameLabelPos = cc.p(tabNameLabel:getPosition()),
			supervisorView = supervisorView,
			supervisorImg = supervisorImg,
			particleSpine = nil,
			supervisorLight = supervisorLight,
			backBtn = backBtn,
		}
	end

	xTry(function ( )
		self.viewData = CreateView()

		self.viewData.tabNameLabel:setPositionY(display.height + 100)
		local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
		self.viewData.tabNameLabel:runAction( action )
	end, __G__TRACKBACK__)
end

return LobbyPeopleManagementView
