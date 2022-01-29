--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）主界面Scene
--]]
local GameScene = require('Frame.GameScene')
---@class ActivityChestScene:GameScene
local ActivityChestScene = class('ActivityChestScene', GameScene)
local RES_DICT={
	BOX_HOME_BG                              = _res("ui/home/activity/chest/box_home_bg.jpg"),
	COMMON_BTN_BACK                          = _res("ui/common/common_btn_back.png"),
	COMMON_TITLE                             = _res('ui/common/common_title.png'),
	COMMON_BTN_TIPS                          = _res('ui/common/common_btn_tips.png'),
	STARPLAN_MAIN_ICON_LIGHT                 = _res('ui/common/starplan_main_icon_light.png'),
	BOX_HOME_BG_BIG_BOTTOM                   = _res("ui/home/activity/chest/box_home_bg_big_bottom.png"),
	BOX_HOME_BG_TIME_TOP                     = _res("ui/home/activity/chest/box_home_bg_time_top.png"),
	BOX_HOME_BG_BIG_LINE                     = _res("ui/home/activity/chest/box_home_bg_big_line.png"),
	BOX_HOME_BG_BIG_LIGHT                    = _res("ui/home/activity/chest/box_home_bg_big_light.png"),
	BOX_HOME_LINE_PLAN                       = _res("ui/home/activity/chest/box_home_line_plan.png"),
	BOX_HOME_LINE_PLAN_TOP                   = _res("ui/home/activity/chest/box_home_line_plan_top.png"),
	BOX_HOME_BG_BAG                          = _res("ui/home/activity/chest/box_home_bg_bag.png"),
	BOX_HOME_BG_BAG_CASE                     = _res("ui/home/activity/chest/box_home_bg_bag_case.png"),
	BOX_HOME_BG_BAG_TIME                     = _res("ui/home/activity/chest/box_home_bg_bag_time.png"),
	BOX_HOME_BTN_BAG_AIR                     = _res("ui/home/activity/chest/box_home_btn_bag_air.png"),
	BOX_HOME_BG_BAG_DI                       = _res("ui/home/activity/chest/box_home_bg_bag_di.png"),
	BOX_HOME_BG_BAG_TITLE                    = _res("ui/home/activity/chest/box_home_bg_bag_title.png"),
	BOX_GOOD_ICO                             = _res("ui/home/activity/chest/box_good_ico.png"),
	BOX_HOME_BG_BAG_CASE_LIGNT               = _res("ui/home/activity/chest/box_home_bg_bag_case_lignt.png"),
	BOX_HOME_BG_BAG_TIME_LIGHT               = _res("ui/home/activity/chest/box_home_bg_bag_time_light.png"),
	WAIMAI_IDLE_0                            = _res("ui/home/activity/chest/waimai_idle_0.png"),
	HOME_BOX_1                               = _spn("ui/home/activity/chest/animate/home_box_1"),
	HOME_BOX_2                               = _spn("ui/home/activity/chest/animate/home_box_2"),
	HOME_BOX_3                               = _spn("ui/home/activity/chest/animate/home_box_3"),
	HOME_BOX_4                               = _spn("ui/home/activity/chest/animate/home_box_4"),
	HOME_BOX_5                               = _spn("ui/home/activity/chest/animate/home_box_5"),
	BOX_HOME_BG_BIG_BOX                      = _spn("ui/home/activity/chest/animate/box_home_bg_big_box"),
}
local CHEST_STATUS = {
	NOT_OPEN     = 1,  --未打开
	DO_OPENING   = 2,  --打开中
	ALREADY_OPEN = 3,  --已打开
}
function ActivityChestScene:ctor( ... )
	self.super.ctor(self, 'views.activity.murder.ActivityChestScene')
	local args = unpack({...})
	self:InitUI()
end
--[[
初始化ui
--]]
function ActivityChestScene:InitUI()
	local swallowLayer = display.newButton(display.cx, display.cy ,{
		ap = display.CENTER,
		size = display.size,
		enable = true
	})
	self:addChild(swallowLayer)


	local bgImage = display.newImageView( RES_DICT.BOX_HOME_BG ,display.cx + 0, display.cy  + 0,{ap = display.CENTER})
	self:addChild(bgImage)

	local roleImage = display.newImageView()
	self:addChild(roleImage)
	roleImage:setAnchorPoint(display.LEFT_BOTTOM)
	roleImage:setPosition(7,2)
	-- 返回按钮
	local backBtn = display.newButton(display.SAFE_L + 12, display.cy + 320 , {
		n = RES_DICT.COMMON_BTN_BACK,
		ap = display.LEFT_CENTER,
		scale9 = true,size = cc.size(90,70)
	})
	self:addChild(backBtn)

	local tabNameLabel = display.newButton(97, 744, {
		ap = display.LEFT_TOP ,
		n = RES_DICT.COMMON_TITLE,
		scale9 = true,
		size = cc.size(303, 78)
	})
	display.commonLabelParams(tabNameLabel, {text = "" , fontSize = 14, color = '#414146'})
	tabNameLabel:setPosition(display.SAFE_L + 130, display.size.height)
	self:addChild(tabNameLabel ,101)

	local tipButton = display.newNSprite(RES_DICT.COMMON_BTN_TIPS, 237, 30,
			{ ap = display.CENTER, tag = 72 })
	tipButton:setScale(1, 1)
	tabNameLabel:addChild(tipButton)
	local tabNameLabelPos = cc.p(tabNameLabel:getPosition())
	tabNameLabel:setPositionY(display.height + 100)

	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
	tabNameLabel:runAction( action )
	local moduleName = display.newLabel(138, 30, fontWithColor('14' , {
		outline = false ,
		ap = display.CENTER,
		color = '#5b3c25',
		text =  "",
		fontSize = 30, tag = 71
	}))
	tabNameLabel:addChild(moduleName)

	local doubleBtn = display.newButton(display.SAFE_R -80 , display.height -160 , { n = RES_DICT.STARPLAN_MAIN_ICON_LIGHT }   )
	local doubleBtnSize = doubleBtn:getContentSize()
	local doubleImage = display.newImageView(RES_DICT.BOX_GOOD_ICO ,doubleBtnSize.width/2 , doubleBtnSize.height/2)
	doubleBtn:addChild(doubleImage)
	display.commonLabelParams(doubleBtn , fontWithColor(14, {offset = cc.p(0, -50 ) ,  text = ""}))
	self:addChild(doubleBtn)

	local bottomBgImage = display.newImageView( RES_DICT.BOX_HOME_BG_BIG_BOTTOM ,display.cx + 0, -1,{ap = display.CENTER_BOTTOM})
	self:addChild(bottomBgImage)
	local leftTimeImage = display.newImageView( RES_DICT.BOX_HOME_BG_TIME_TOP ,display.SAFE_R + 55, display.height+ 2,{ap = display.RIGHT_TOP})
	self:addChild(leftTimeImage)
	local leftTimeDescr = display.newLabel(218.5, 40 , {fontSize = 24,text = __('活动倒计时'),color = '#4a1e1c',reqW = 180,hAlign = display.TAC,ap = display.CENTER_BOTTOM})
	leftTimeImage:addChild(leftTimeDescr)
	local leftTimeLabel = display.newLabel(218.5, 5 ,fontWithColor(14 , {fontSize = 22,text = "",color = '#E0CCBB',hAlign = display.TAC,ap = display.CENTER_BOTTOM}))
	leftTimeImage:addChild(leftTimeLabel)
	local leftBottomLayout = display.newButton(display.SAFE_L + -2, -2,{enable = true , ap = display.LEFT_BOTTOM,size = cc.size(400,300)})
	self:addChild(leftBottomLayout)
	local chestBgName = display.newImageView( RES_DICT.BOX_HOME_BG_BIG_LINE ,142, 38,{ap = display.CENTER})
	leftBottomLayout:addChild(chestBgName)
	local lightImage = display.newImageView( RES_DICT.BOX_HOME_BG_BIG_LIGHT ,158, 154,{ap = display.CENTER})
	leftBottomLayout:addChild(lightImage)
	local chestName = display.newLabel(156, 60,fontWithColor(14 , {fontSize = 24,text = "",ouline = '#4d1e1c',ap = display.CENTER}))
	leftBottomLayout:addChild(chestName,20)
	local chestSpine = sp.SkeletonAnimation:create(RES_DICT.BOX_HOME_BG_BIG_BOX.json ,RES_DICT.BOX_HOME_BG_BIG_BOX.atlas ,1)
	chestSpine:setAnimation(0, 'idle' , true)
	chestSpine:setPosition(158, 60)
	leftBottomLayout:addChild(chestSpine)

	local prograssBar = CProgressBar:create(RES_DICT.BOX_HOME_LINE_PLAN_TOP)
	prograssBar:setBackgroundImage(RES_DICT.BOX_HOME_LINE_PLAN)
	prograssBar:setAnchorPoint(display.CENTER)
	prograssBar:setMaxValue(100)
	prograssBar:setValue(0)
	prograssBar:setPosition(cc.p(147 , 37))
	leftBottomLayout:addChild(prograssBar)
	local prograssLabel = display.newLabel(114.5, 10 , {fontSize = 20 ,  text = '',ap = display.CENTER})
	prograssBar:addChild(prograssLabel,20 )
	local rightBottomLayout = display.newLayer(display.SAFE_R + 50, 15 ,{ap = display.RIGHT_BOTTOM,size = cc.size(1084,281)})
	self:addChild(rightBottomLayout)
	local rightBottomImage = display.newImageView( RES_DICT.BOX_HOME_BG_BAG ,572, 140.5,{ap = display.CENTER})
	rightBottomLayout:addChild(rightBottomImage)
	local cellLayoutDatas = {}
	for i  = 1 , 4 do
		local cellLayout = display.newLayer(930 - (i-1)* 205.7, 116.4 ,{ap = display.CENTER,size = cc.size(207.7,233)})
		rightBottomLayout:addChild(cellLayout)
		local clickLayer = display.newLayer(103.85, 116.5 ,{ap = display.CENTER,size = cc.size(207.7,233),color = cc.c4b(0,0,0,0),enable = true})
		cellLayout:addChild(clickLayer)
		clickLayer:setTag(5-i)
		local statusImage = display.newImageView( RES_DICT.BOX_HOME_BG_BAG_CASE ,102.85, 140.5,{ap = display.CENTER})
		cellLayout:addChild(statusImage)
		local statusBtn = display.newButton(100.85, 35.5 , {n = RES_DICT.BOX_HOME_BG_BAG_TIME,ap = display.CENTER,scale9 = true,size = cc.size(192,62)})
		cellLayout:addChild(statusBtn,-1)
		display.commonLabelParams(statusBtn ,{fontSize = 22,text = '',color = '#ffffff',paddingW  = 20,safeW = 152})
		local addImage = display.newImageView( RES_DICT.BOX_HOME_BTN_BAG_AIR ,102.85, 140.5,{ap = display.CENTER})
		cellLayout:addChild(addImage)
		local diImage = display.newImageView( RES_DICT.BOX_HOME_BG_BAG_DI ,102.85, 70,{ap = display.CENTER})
		cellLayout:addChild(diImage)
		table.insert(cellLayoutDatas , 1,{
			cellLayout = cellLayout,
			clickLayer = clickLayer,
			statusBtn  = statusBtn,
			statusImage  = statusImage,
			addImage   = addImage,
			diImage    = diImage,
		})
	end
	local moduleNameTitle = display.newButton(842, 287.5 , {n = RES_DICT.BOX_HOME_BG_BAG_TITLE,enable = false ,  ap = display.CENTER,scale9 = true,size = cc.size(470,72)})
	rightBottomLayout:addChild(moduleNameTitle)

	local moduleImage = display.newImageView(RES_DICT.WAIMAI_IDLE_0 ,642,287.5)
	rightBottomLayout:addChild(moduleImage ,10 )
	
	display.commonLabelParams(moduleNameTitle ,fontWithColor(14 , {fontSize = 24,text ='',color = '#4A1E1C',reqW = 330,hAlign = display.TAC,offset = cc.p(23 , 0),paddingW  = 20,safeW = 430}))
	self.viewData = {
		bgImage                   = bgImage,
		backBtn                   = backBtn,
		bottomBgImage             = bottomBgImage,
		leftTimeImage             = leftTimeImage,
		leftTimeDescr             = leftTimeDescr,
		leftTimeLabel             = leftTimeLabel,
		leftBottomLayout          = leftBottomLayout,
		chestBgName               = chestBgName,
		lightImage                = lightImage,
		tabNameLabel              = tabNameLabel,
		chestName                 = chestName,
		chestSpine                = chestSpine,
		prograssBar               = prograssBar,
		prograssLabel             = prograssLabel,
		rightBottomLayout         = rightBottomLayout,
		rightBottomImage          = rightBottomImage,
		cellLayoutDatas           = cellLayoutDatas ,
		doubleBtn           	  = doubleBtn ,
		moduleImage           	  = moduleImage ,
		roleImage           	  = roleImage ,
		moduleNameTitle           = moduleNameTitle
	}
end
function ActivityChestScene:UpdateTitleName(name)
	display.commonLabelParams(self.viewData.tabNameLabel , fontWithColor(14, {
		fontSize = 30 ,color = '473227',
		offset = cc.p(0,-8),
		outline = false ,  text = name
	}))
end

function ActivityChestScene:UpdateTimeLabel(time)
	display.commonLabelParams(self.viewData.leftTimeLabel , fontWithColor(14, { reqW = 200 , text = time}))
end

function ActivityChestScene:ChestUpdateBoxTimeLabel(index , text , color , outline  )
	color = color or "#E7E5CD"
	outline = outline or "#4D1E1C"
	local cellLayoutDatas = self.viewData.cellLayoutDatas[checkint(index)]
	local statusBtn = cellLayoutDatas.statusBtn
	display.commonLabelParams(statusBtn , fontWithColor(14 , {text = text , color = color }))
end


function ActivityChestScene:RunSpineAnimation(index , callfunc )
	local cellLayoutDatas = self.viewData.cellLayoutDatas[checkint(index)]
	local cellLayout = cellLayoutDatas.cellLayout
	local spine = cellLayout:getChildByName("spine")
	spine:setAnimation(0 , "play4" , false)
	spine:runAction(cc.Sequence:create(
		cc.DelayTime:create(1) ,
		cc.CallFunc:create(function()
			self:ChestUpdateBoxByIndex(index , {status = CHEST_STATUS.ALREADY_OPEN})
			if callfunc then
				callfunc()
			end
		end)
	))
end

function ActivityChestScene:ChestUpdateBoxByIndex(index , data , unlock)
	local cellLayoutDatas = self.viewData.cellLayoutDatas[checkint(index)]
	local status = data.status
	local cellLayout = cellLayoutDatas.cellLayout
	local spine = cellLayout:getChildByName("spine")
	local crBoxConf = CONF.GOODS.CR_BOX:GetValue(data.goodsId)
	cellLayoutDatas.statusImage:setTexture(RES_DICT.BOX_HOME_BG_BAG_CASE)
	cellLayoutDatas.statusBtn:setNormalImage(RES_DICT.BOX_HOME_BG_BAG_TIME)
	cellLayoutDatas.statusBtn:setSelectedImage(RES_DICT.BOX_HOME_BG_BAG_TIME)
	local celSize = cellLayout:getContentSize()
	if  status == CHEST_STATUS.DO_OPENING  then
		cellLayoutDatas.addImage:setVisible(false)
		local photoId = string.upper(crBoxConf.photoId)
		local spinRes = RES_DICT[photoId]
		if not spine then
			spine = sp.SkeletonAnimation:create(spinRes.json , spinRes.atlas , 1)
			spine:setName("spine")
			spine:setPosition(celSize.width/2 - 5, celSize.height/2+30)
			cellLayout:addChild(spine)
		end
		if data.openLeftSeconds == 0  then
			self:ChestUpdateBoxTimeLabel(index , __('已解锁') , "#FFFFFF" , "#734441")
			--spine:setAnimation(0, "play3" , true)
			cellLayoutDatas.statusImage:setTexture(RES_DICT.BOX_HOME_BG_BAG_CASE_LIGNT)
			cellLayoutDatas.statusBtn:setNormalImage(RES_DICT.BOX_HOME_BG_BAG_TIME_LIGHT)
			cellLayoutDatas.statusBtn:setSelectedImage(RES_DICT.BOX_HOME_BG_BAG_TIME_LIGHT)
		else
			spine:setAnimation(0, "play2" , true)
		end
	elseif status == CHEST_STATUS.NOT_OPEN then
		if checkint(data.goodsId) == 0 then
			cellLayoutDatas.addImage:setVisible(true)
			local spine = cellLayout:getChildByName("spine")
			if spine and (not tolua.isnull(spine)) then
				spine:setToSetupPose()
				spine:runAction(cc.RemoveSelf:create())
			end
			self:ChestUpdateBoxTimeLabel(index ,"")
		else
			cellLayoutDatas.addImage:setVisible(false)
			local photoId = string.upper(crBoxConf.photoId)
			local spinRes = RES_DICT[photoId]
			if not spine then
				spine = sp.SkeletonAnimation:create(spinRes.json , spinRes.atlas , 1)
				spine:setName("spine")
				spine:setPosition(celSize.width/2 - 5 , celSize.height/2+30)
				cellLayout:addChild(spine)
			end
			self:ChestUpdateBoxTimeLabel(index ,CommonUtils.getTimeFormatByType(crBoxConf.openTime , 1) )
			if unlock then
				spine:setAnimation(0, "play3" , true)
			else
				spine:setAnimation(0, "play1" , false)
			end

		end
	end
end

function ActivityChestScene:UpdateModuleUI(jumpData , productName)
	local viewData = self.viewData
	display.commonLabelParams(viewData.moduleNameTitle , fontWithColor(14 , {
		fontSize = 24,text = jumpData.text ,
		outline = false ,
		color = '#4A1E1C',reqW = 310,hAlign = display.TAC,
		offset = cc.p(23 , -15),
		paddingW  = 20,safeW = 430
	}))
	viewData.moduleImage:setTexture(_res(string.format("ui/home/activity/chest/%s" , jumpData.image)) )
	viewData.moduleImage:setVisible(jumpData.imageIsShow)
	display.commonLabelParams(viewData.doubleBtn , { text = productName , w = 150 ,hAlign = display.TAC })
	viewData.doubleBtn:setText(productName)
end

function ActivityChestScene:UpateChestName(chestName)
	display.commonLabelParams(self.viewData.chestName , fontWithColor(14 , {fontSize = 24,text = chestName ,ouline = '#4d1e1c',ap = display.CENTER}))
end
function ActivityChestScene:UpdatePrograss(prograss , total)
	prograss          = checkint(prograss)
	total             = checkint(total)
	local prograssBar = self.viewData.prograssBar
	local prograssLabel = self.viewData.prograssLabel
	prograssBar:setMaxValue(total)
	prograssBar:setValue(prograss >= total and total or prograss)
	prograssLabel:setString(prograss .. '/'  .. total )
end
function ActivityChestScene:LoadImage(imagePath)
	imagePath = string.format('ui/home/capsule/activityCapsule/%s.png', imagePath)
	display.loadImage( imagePath, function()
		local viewData = self.viewData
		viewData.roleImage:setOpacity(0)
		viewData.roleImage:setTexture(imagePath)
		viewData.roleImage:runAction(
				cc.FadeIn:create(0.5)
		)
	end)
end
return ActivityChestScene
