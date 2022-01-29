--[[
编队系统UI
---- TODO ----
@params table {
	isCommon bool 是否是通用调用
}
---- TODO ----
--]]
local GameScene = require( "Frame.GameScene" )

local TeamFormationView = class('TeamFormationView', GameScene)


local function CreateTaskView( ... )

	local view = CLayout:create()
	view:setName('bgLayout')
	-- view:setBackgroundColor(cc.c4b(0, 128, 0, 100))
    view:setPosition(display.cx, display.cy)
    view:setAnchorPoint(display.CENTER)

    local frameSize   = display.size
    view:setContentSize(frameSize)


	local tabNameLabel = display.newButton(
		display.SAFE_L + 130, display.size.height,
		{n = _res('ui/common/common_title_new.png'),enable = false,ap =  display.LEFT_TOP })
	display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('编队系统'), fontSize = 30,reqW = 250,  color = '473227',offset = cc.p(0,-8)})
	view:addChild(tabNameLabel)

	---- TODO ----
	-- 返回按钮
	local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png"), cb = function (sender)
        PlayAudioByClickClose()
		AppFacade.GetInstance():DispatchObservers("CLOSE_TEAM_FORMATION")
	end})
	display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + 59, display.height + -55)})
	view:addChild(backBtn, 21)
	---- TODO ----


	local fightBg = display.newImageView(_res('ui/home/teamformation/newCell/team_bg_font_red.png'), display.SAFE_R - (1334-760) , frameSize.height/2 +260,
	{ap = cc.p(0, 0.5)})	--scale9 = true, size = cc.size(frameSize.width*0.8 , frameSize.height*0.6 ),
	view:addChild(fightBg)
	--
	-- local fight_team = display.newImageView(_res('ui/home/teamformation/newCell/team_font_zhandouli.png'),820, frameSize.height - 90,
	local fight_team = display.newImageView(_res('ui/common/transtory_tranparent_bg'),820, frameSize.height - 90,
	{ap = cc.p(0, 0.5), scale9 = true, size = cc.size(144,30)})	--scale9 = true, size = cc.size(frameSize.width*0.8 , frameSize.height*0.6 ),
    local fightLabel = display.newLabel(144* 1.2, 15,fontWithColor(14,{ap = display.RIGHT_CENTER ,  fontSize = 28,color = 'ffdf6e',text = __('編隊總靈力'),outline = '432323', outlineSize = 1}))
    fight_team:addChild(fightLabel)
	view:addChild(fight_team,1)


	local fireSpine = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
	fireSpine:update(0)
	fireSpine:setAnimation(0, 'huo', true)--shengxing1 shengji
	view:addChild(fireSpine)
	fireSpine:setPosition(cc.p(display.SAFE_R - (1334-1040),frameSize.height/2 + 264))


	local fight_num = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '')
	fight_num:setAnchorPoint(cc.p(0.5, 0.5))
	fight_num:setHorizontalAlignment(display.TAR)
	fight_num:setPosition(display.SAFE_R - (1334-1040),frameSize.height/2 +280)
	view:addChild(fight_num,1)
	fight_num:setScale(0.7)

	local listSize = cc.size(172, 597)
	local ListBg = display.newImageView(_res('ui/home/teamformation/newCell/team_bg_liebiao.png'), display.SAFE_R  ,display.cy-60 ,--
		{scale9 = true, size = cc.size(172, 597),ap = display.RIGHT_CENTER})
	view:addChild(ListBg)
	--添加列表功能
	-- local taskListSize = cc.size(ListBgFrameSize.width - 2, ListBgFrameSize.height - 4)
	-- local taskListCellSize = cc.size(taskListSize.width/4  , 115)

	local cellSize = cc.size(listSize.width , listSize.height / 4.5)
	local containerSize = cc.size(cellSize.width , cellSize.height * 2)
	local listView = CScrollView:create(listSize)
	listView:setName('listView')
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setAnchorPoint(display.RIGHT_CENTER)
	listView:setPosition(cc.p(display.SAFE_R , display.cy - 60))
	view:addChild(listView)
	-- listView:setBackgroundColor(cc.c4b(0, 128, 0, 100))

 	local lineUp = display.newImageView(_res('ui/home/teamformation/newCell/team_img_up.png'), display.SAFE_R- 3 , ListBg:getPositionY() + 300,
	{ap = cc.p(1, 1)})
	view:addChild(lineUp,30)

 	local lineDown = display.newImageView(_res('ui/home/teamformation/newCell/team_img_down.png'), display.SAFE_R- 4, ListBg:getPositionY() -300,
	{ap = cc.p(1, 0)})
	view:addChild(lineDown,30)


	local lookMessBtn = display.newCheckBox(0, 0,
		{n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'), s = _res('ui/home/teamformation/choosehero/team_btn_selection_choosed.png')})
	display.commonUIParams(lookMessBtn, {po = cc.p(display.SAFE_R - 3, ListBg:getPositionY() + 350),ap = cc.p(1,1)})
	view:addChild(lookMessBtn, 1)


	local lookMessLabel = display.newLabel(utils.getLocalCenter(lookMessBtn).x, utils.getLocalCenter(lookMessBtn).y,
		fontWithColor(5,{text = __('查看属性'), color = 'ffffff'}))
	lookMessBtn:addChild(lookMessLabel)


	local takeWayView = CLayout:create()
	takeWayView:setVisible(false)
	-- takeWayView:setBackgroundColor(cc.c4b(0, 128, 0, 100))
    takeWayView:setPosition(22, display.size.height * 0.5)
    takeWayView:setAnchorPoint(cc.p(0,0.5))
    view:addChild(takeWayView,100)
    local frameSize   = cc.size(1145,195 )
    takeWayView:setContentSize(frameSize)

 	local takeWayBg = display.newImageView(_res('ui/home/teamformation/team_mask_teamlock.png'),0, 0 ,
	{ap = cc.p(0, 0)})
	takeWayView:addChild(takeWayBg)

 	local takeWayQimg = display.newImageView(_res('ui/home/teamformation/team_ico_takeout.png'),316, frameSize.height * 0.5 ,
	{ap = cc.p(0, 0.5)})
	takeWayView:addChild(takeWayQimg)

	local takeWayLabel = display.newButton( 486, 84,{n = _res('ui/home/teamformation/team_bg_take_out.png'),enable = false,ap = cc.p(0, 0)})
	display.commonLabelParams(takeWayLabel, {ttf = true, font = TTF_GAME_FONT, text = __('该队伍正在配送外卖中'), fontSize = 28, color = 'd9954d'})
	takeWayLabel:getLabel():enableOutline(cc.c4b(0, 0, 0, 255), 1)
	takeWayView:addChild(takeWayLabel,1)




	return {
		view 			= view,
		fight_num 		= fight_num,
		listView 		= listView,
		lineUp   		= lineUp,
		lineDown 		= lineDown,
		ListBg 			= ListBg,
		tabNameLabel 	= tabNameLabel,
		backBtn 		= backBtn,
		takeWayLabel 	= takeWayLabel,
		takeWayView		= takeWayView,
		takeWayQimg 	= takeWayQimg,
		lookMessBtn 	= lookMessBtn,
		lookMessLabel	= lookMessLabel,
	}
end

function TeamFormationView:ctor( ... )
	local bg = display.newImageView(_res('ui/bg/common_loading_bg.png'), 0, 0 , {isFull = true})
	self:addChild(bg,-3)
	bg:setAnchorPoint(cc.p(0, 0))
	-- bg:setPosition(cc.p(display.cx, display.height))

	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 179))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))
	self:addChild(eaterLayer, -2)


	local below = display.newImageView(_res('ui/home/teamformation/team_bg_below.png'),display.width * 0.5, display.cy - 210,
	{ap = display.CENTER_TOP})	--scale9 = true, size = cc.size(frameSize.width*0.8 , frameSize.height*0.6 ),
	self:addChild(below,-1)
	self.belowBg = below
	below:setScale((display.SAFE_RECT.width-200)/ 5 /(1334/6))

	self.viewData_ = CreateTaskView()
	display.commonUIParams(self.viewData_.view, {po = display.center})
	self:addChild(self.viewData_.view,1)

	self.isCommon = checktable(unpack({...})).isCommon or false
	self.viewData_.backBtn:setVisible(self.isCommon)
	local tabNameLabel = self.viewData_.tabNameLabel
	local tabNameLabelPos = cc.p(tabNameLabel:getPosition())
    tabNameLabel:setPositionY(display.height + 100)
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
	self.viewData_.tabNameLabel:runAction( action )

	-- self.viewData_.listView:runAction( cc.MoveBy:create(0.5,cc.p(-150, 0)) )
	-- self.viewData_.ListBg:runAction( cc.MoveBy:create(0.5,cc.p(-150 , 0)) )

	-- self.viewData_.lineUp:runAction( cc.MoveBy:create(0.5,cc.p(-150 , 0)) )
	-- self.viewData_.lineDown:runAction( cc.MoveBy:create(0.5,cc.p(-150, 0)) )
end


return TeamFormationView
