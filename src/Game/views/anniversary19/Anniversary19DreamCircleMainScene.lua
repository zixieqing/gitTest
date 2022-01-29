
local GameScene = require( 'Frame.GameScene' )
---@class Anniversary19DreamCircleMainScene :GameScene
local Anniversary19DreamCircleMainScene = class('Anniversary19DreamCircleMainScene' , GameScene)
local newImageView = display.newImageView

local newButton = display.newButton
local newLayer = display.newLayer
local RES_DICT = {
	WONDERLAND_EXPLORE_PAN_SLOT_BOSS        = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_slot_boss.png'),
	WONDERLAND_EXPLORE_GO_FG_1L             = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_fg_1l.png'),
	WONDERLAND_EXPLORE_GO_BG                = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_bg.jpg'),
	WONDERLAND_EXPLORE_GO_FG_1R             = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_fg_1r.png'),
	WONDERLAND_EXPLORE_GO_FG_CLOUD          = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_fg_cloud.png'),
	WONDERLAND_EXPLORE_GO_LABEL_NUM         = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_label_num.png'),
	WONDERLAND_EXPLORE_PAN_SLOT_ACTIVE      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_slot_active.png'),
	WONDERLAND_EXPLORE_PAN_ICO_1            = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_ico_1.png'),
	WONDERLAND_EXPLORE_PAN_SLOT_DEFAULT     = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_slot_default.png'),
	WONDERLAND_EXPLORE_PAN_BG_RING          = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_bg_ring.png'),
	WONDERLAND_EXPLORE_PAN_LABEL_DETAIL     = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_label_detail.png'),
	WONDERLAND_EXPLORE_PAN_ICO_3            = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_ico_3.png'),
	WONDERLAND_EXPLORE_PAN_SLOT_BOSS_ACTIVE = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_slot_boss_active.png'),
	WONDERLAND_EXPLORE_GO_BG_TEXT           = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_go_bg_text.png'),
	COMMON_BTN_BACK                         = app.anniversary2019Mgr:GetResPath("ui/common/common_btn_back.png"),
	COMMON_TITLE                            = app.anniversary2019Mgr:GetResPath('ui/common/common_title.png'),
	COMMON_BTN_TIPS                         = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_tips.png'),
	WONDERLAND_EXPLORE_MAIN_LABEL_LEVEL     = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_label_level.png'),
}
local CIRCLR_NODE_POS_TABLE = {
	cc.p(609, 601),
	cc.p(699, 369),
	cc.p(610, 163),
	cc.p(373, 70),
	cc.p(159, 166),
	cc.p(70, 393),
	cc.p(175, 613),
	--cc.p(379, 686),
}
---@type Anniversary2019Manager
local anniversary2019Mgr = app.anniversary2019Mgr
function Anniversary19DreamCircleMainScene:ctor( ... )
	self.super.ctor(self, 'Game.views.anniversary2.Anniversary19DreamCircleMainScene')
	self:InitUI()
end

function Anniversary19DreamCircleMainScene:InitUI()
	local view = newButton(display.cx, display.cy,{ap = display.CENTER, enable = true ,  size = display.size})
	local bgImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_BG, 665, 376,
			{ ap = display.CENTER, tag = 118, enable = false })
	bgImage:setPosition(display.center)
	view:addChild(bgImage)
	self:addChild(view)
	local centerLayout = newLayer(display.cx , display.cy , {ap = display.CENTER ,  size = display.size})
	self:addChild(centerLayout)
	local leftImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_FG_1L, 0, 375,
			{ ap = display.LEFT_CENTER, tag = 119, enable = false })
	leftImage:setPosition(-30, display.cy + 0)
	leftImage:setVisible(false)
	centerLayout:addChild(leftImage , 11 )

	local rightImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_FG_1R, 1334, 375,
			{ ap = display.RIGHT_CENTER, tag = 120, enable = false })
	rightImage:setPosition(display.width+30 , display.cy + 0)
	rightImage:setVisible(false)
	centerLayout:addChild(rightImage, 11 )

	local cloudImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_FG_CLOUD, 667, 0,
			{ ap = display.CENTER_BOTTOM, tag = 122, enable = false })
	cloudImage:setPosition(display.cx + 0, 0)
	cloudImage:setScale(2)
	centerLayout:addChild(cloudImage , 10 )

	local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height,{ ap = display.LEFT_TOP ,  n = RES_DICT.COMMON_TITLE, d = RES_DICT.COMMON_TITLE, s = RES_DICT.COMMON_TITLE, scale9 = true, size = cc.size(303, 78) })
	display.commonLabelParams(tabNameLabel, { ttf = true, font = TTF_GAME_FONT, text = "", fontSize = 30, color = '#473227', offset = cc.p(0, -10)})
	self:addChild(tabNameLabel ,101)
	local titleSize = tabNameLabel:getContentSize()
	local tipsIcon  = display.newImageView(RES_DICT.COMMON_BTN_TIPS, titleSize.width - 50, titleSize.height/2 - 10)
	tabNameLabel:addChild(tipsIcon)

	local backBtn = display.newButton(0, 0, {n = RES_DICT.COMMON_BTN_BACK})
	backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
	backBtn:setName('NAV_BACK')
	self:addChild(backBtn, 101)
	---------圆形区域----------
	local circleExternalSize =  cc.size(768 * 0.6 , 768* 0.6 )
	local circleExternalPos = cc.p(display.width/2, -110 )
	local circleExternal = newLayer(display.width/2, -110 ,{ap = display.CENTER ,  display.CENTER ,size =  circleExternalSize } )
	circleExternal:setVisible(false)
	local circleSize = cc.size(768, 768)
	local circleLayout = newButton(circleExternalSize.width/2  , circleExternalSize.height/2 ,
			{ ap = display.CENTER,  size = circleSize , enable = true })
	circleExternal:addChild(circleLayout)
	circleLayout:setScale(0.6)

	local circleImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_PAN_BG_RING, 384, 384,
			{ ap = display.CENTER, tag = 56, enable = false })
	circleLayout:addChild(circleImage)

	local finallyLayout = newLayer(379, 686,
			{ ap = display.CENTER, color = cc.r4b(0), size = cc.size(140, 140), enable = true })
	circleLayout:addChild(finallyLayout)

	local finallyImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_PAN_SLOT_BOSS, 70, 70,
			{ ap = display.CENTER, tag = 58, enable = false })
	finallyLayout:addChild(finallyImage)
	local levelLayoutSize = cc.size(41,41)
	local levelLayout = newLayer(70 , 18 , {ap = display.CENTER ,size = levelLayoutSize })
	finallyLayout:addChild(levelLayout)
	local levelBgImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_MAIN_LABEL_LEVEL ,levelLayoutSize.width/2 , levelLayoutSize.height/2)
	levelLayout:addChild(levelBgImage)
	local levelText = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	levelText:setAnchorPoint(display.RIGHT_CENTER)
	levelText:setPosition(levelLayoutSize.width/2+ 2,levelLayoutSize.height/2)
	levelLayout:addChild(levelText)

	local labelNumberImage = display.newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_LABEL_NUM , circleExternalSize.width/2 , circleExternalSize.height * 3/4 + 20   )
	circleExternal:addChild(labelNumberImage)
	local labelNumberImageSize = labelNumberImage:getContentSize()
	local goodsIdImage = display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID) , 0,0 , { ap = display.LEFT_BOTTOM  , scale = 0.3 } )
	labelNumberImage:addChild(goodsIdImage)

	local accumulativeRewardNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	accumulativeRewardNumLabel:setAnchorPoint(display.RIGHT_CENTER)
	accumulativeRewardNumLabel:setPosition(labelNumberImageSize.width -10  , labelNumberImageSize.height/2)
	labelNumberImage:addChild(accumulativeRewardNumLabel)

	local dreamCircleNodes = {}
	for i = 1, #CIRCLR_NODE_POS_TABLE do
		local viewData = self:CreateDreamCircleNode()
		dreamCircleNodes[#dreamCircleNodes+1] = viewData
		circleLayout:addChild(viewData.commonStepsLayout,2)
		viewData.commonStepsLayout:setPosition(CIRCLR_NODE_POS_TABLE[i])
	end
	self:addChild(circleExternal ,101)
	local tabNameLabelPos = cc.p(tabNameLabel:getPosition())
	tabNameLabel:setPositionY(display.height + 100)
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
	tabNameLabel:runAction( action )
	--local topSwallowLayer = newButton(display.cx , display.cy , { enabel = true,  size = display.size })
	--sceneWorld:addChild(topSwallowLayer , 1000)
	--topSwallowLayer:setEnabled(true)
	--topSwallowLayer:setName("topSwallowLayer")


	self.viewData = {
		leftImage                  = leftImage,
		rightImage                 = rightImage,
		view                       = view,
		centerLayout               = centerLayout,
		cloudImage                 = cloudImage,
		backBtn                    = backBtn,
		tabNameLabel               = tabNameLabel ,
		--topSwallowLayer            = topSwallowLayer ,
		--------------------下面的圆形----------------------
		circleLayout               = circleLayout,
		finallyLayout              = finallyLayout,
		finallyImage               = finallyImage,
		labelNumberImage           = labelNumberImage,
		goodsIdImage               = goodsIdImage,
		accumulativeRewardNumLabel = accumulativeRewardNumLabel,
		levelText                  = levelText,
		circleExternal             = circleExternal,
		circleExternalPos          = circleExternalPos,
		dreamCircleNodes           = dreamCircleNodes
	}
end

function Anniversary19DreamCircleMainScene:EnterSceneAction()
	local leftImage = self.viewData.leftImage
	local rightImage = self.viewData.rightImage
	local cloudImage = self.viewData.cloudImage
	local leftEndPos = cc.p(leftImage:getPosition())
	local rightEndPos = cc.p(rightImage:getPosition())
	leftImage:setOpacity(0)
	rightImage:setOpacity(0)
	cloudImage:setOpacity(0)
	leftImage:setVisible(true)
	rightImage:setVisible(true)
	cloudImage:setVisible(true)
	local leftStartPos = cc.p(leftEndPos.x - 200 , leftEndPos.y )
	local rightStartPos = cc.p(rightEndPos.x + 200 , rightEndPos.y )
	leftImage:setPosition(leftStartPos)
	rightImage:setPosition(rightStartPos)
	local actionTime = 0.5
	leftImage:runAction(
		cc.Sequence:create(
			cc.CallFunc:create(
				function()
					local parseConf = anniversary2019Mgr:GetConfigParse()
					local exploreConf = anniversary2019Mgr:GetConfigDataByName(parseConf.TYPE.EXPLORE)
					local exploreModuleId = anniversary2019Mgr:GetCurrentExploreModuleId()
					local name = exploreConf[tostring(exploreModuleId)].name
					display.commonLabelParams(self.viewData.tabNameLabel , {text = name})
				end
			)	,
			cc.Spawn:create(
				cc.FadeIn:create(actionTime) ,
				cc.EaseSineOut:create(cc.MoveTo:create(actionTime ,leftEndPos  )),
				cc.TargetedAction:create(rightImage ,
					cc.Spawn:create(
						cc.FadeIn:create(actionTime) ,
						cc.EaseSineOut:create(cc.MoveTo:create(actionTime ,rightEndPos))
					)
				),
				cc.TargetedAction:create(cloudImage ,cc.FadeIn:create(actionTime) )
			),
			cc.CallFunc:create(function()
				app:DispatchObservers("HIDE_SWALLOW_TOP_LAYER")
			end)
		)
	)
end

function Anniversary19DreamCircleMainScene:UpdateLeftAndRightImage(exploreModuleId)
	exploreModuleId = checkint(exploreModuleId)
	local leftPath = app.anniversary2019Mgr:GetResPath(string.format('ui/anniversary19/DreamCycle/wonderland_explore_go_fg_%dl' ,exploreModuleId ))
	local rightPath = app.anniversary2019Mgr:GetResPath(string.format('ui/anniversary19/DreamCycle/wonderland_explore_go_fg_%dr' ,exploreModuleId ))
	local viewData = self.viewData
	viewData.leftImage:setTexture(leftPath)
	viewData.rightImage:setTexture(rightPath)
end

function Anniversary19DreamCircleMainScene:AddDoorSpine()
	local viewData = self.viewData
	local centerLayout = viewData.centerLayout
	local spineLayer = display.newLayer(display.cx, display.cy , { size = display.size  , ap = display.CENTER})
	centerLayout:addChild(spineLayer, 2)
	local leftLayout = newButton(display.cx - 70  , display.cy+70  , {ap = display.RIGHT_CENTER , size = cc.size(500 , 600  ) , color = cc.r4b()})
	spineLayer:addChild(leftLayout, 20)
	local leftTextImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_BG_TEXT , 250 , 360 )
	leftLayout:addChild(leftTextImage)
	leftTextImage:setOpacity(0)
	local leftTextImageSize = cc.size(385, 410)
	local leftLabel = display.newLabel(leftTextImageSize.width/2  , leftTextImageSize.height/2  , {text = "" , color = "#aeca7e" , fontSize = 24 ,  w = 300 ,hAlign = display.TAC  })
	leftTextImage:addChild(leftLabel)
	local rightLayout = newButton(display.cx + 70  , display.cy  + 70  , {ap = display.LEFT_CENTER , size = cc.size(500 , 600  ) , color = cc.r4b()})
	spineLayer:addChild(rightLayout, 20)

	local rightTextImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_BG_TEXT , 250 , 360 )
	rightLayout:addChild(rightTextImage)
	local rightLabel = display.newLabel(leftTextImageSize.width/2  , leftTextImageSize.height/2   , {text = "" , color = "#aeca7e" , fontSize = 24 , w = 300 , hAlign = display.TAC  })
	rightTextImage:addChild(rightLabel)
	rightTextImage:setOpacity(0)
	local doorSpinePath = anniversary2019Mgr.spineTable.WONDERLAND_EXPLORE_DOOR
	anniversary2019Mgr:AddSpineCacheByPath(doorSpinePath)
	local  doorSpine =   SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(doorSpinePath)
	doorSpine:setPosition(0,0)
	doorSpine:setAnimation(0, "drop" , false )
	doorSpine:setPosition(display.center)
	spineLayer:addChild(doorSpine)
	leftLayout:setEnabled(false)
	rightLayout:setEnabled(false)
	self.viewData.leftLayout     = leftLayout
	self.viewData.rightLayout    = rightLayout
	self.viewData.leftLabel      = leftLabel
	self.viewData.rightLabel     = rightLabel
	self.viewData.leftTextImage  = leftTextImage
	self.viewData.rightTextImage = rightTextImage
	self.viewData.doorSpine      = doorSpine
	self.viewData.spineLayer     = spineLayer
end

function Anniversary19DreamCircleMainScene:CreateDreamCircleNode()
	local commonStepsLayout = newButton(0, 0,
			{ ap = display.CENTER , size = cc.size(94, 94), enable = true })
	local commonStepImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_PAN_SLOT_DEFAULT, 47, 47,
			{ ap = display.CENTER, tag = 61, enable = false })
	commonStepsLayout:addChild(commonStepImage)

	local commonActiveStepImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_PAN_SLOT_ACTIVE, 47, 47,
			{ ap = display.CENTER, tag = 62, enable = false })
	commonStepsLayout:addChild(commonActiveStepImage)
	local commonStepIcon = newImageView(RES_DICT.WONDERLAND_EXPLORE_PAN_ICO_1, 47, 47,
			{ ap = display.CENTER, tag = 83, enable = false })
	commonStepsLayout:addChild(commonStepIcon)
	return {
		commonStepsLayout = commonStepsLayout ,
		commonStepImage = commonStepImage ,
		commonActiveStepImage = commonActiveStepImage ,
		commonStepIcon = commonStepIcon ,
	}
end

function Anniversary19DreamCircleMainScene:UpdateCircleNodeRotation(prograss)
	local viewData  = self.viewData
	local dreamCircleNodes = viewData.dreamCircleNodes
	for i = 1 , 7 do
		local commonStepsLayout = dreamCircleNodes[i].commonStepsLayout
		commonStepsLayout:setRotation(prograss * 45)
	end
	local finallyLayout = viewData.finallyLayout
	finallyLayout:setRotation(prograss * 45)
end


function Anniversary19DreamCircleMainScene:UpdateCircleLayoutRotation( prograss )
	local viewData  = self.viewData
	local circleLayout = viewData.circleLayout
	circleLayout:setRotation( (prograss-1) * -45)
end

function Anniversary19DreamCircleMainScene:RunCircleAction(time , prograss )
	time = time or 1
	local viewData  = self.viewData
	local circleLayout = viewData.circleLayout

	circleLayout:runAction(
		cc.Sequence:create(
			cc.RotateTo:create(time  , prograss * -45 ),
			cc.TargetedAction:create(
				self.viewData.dreamCircleNodes[prograss].commonStepsLayout ,
				cc.Sequence:create(
					cc.CallFunc:create(
						function()
							self.viewData.dreamCircleNodes[prograss].commonStepsLayout:setAnchorPoint(cc.p(0.5 , 0.35))
						end
					),
					cc.ScaleTo:create(0.4 , 1.5)
				)
			)
		)
	)
end

function Anniversary19DreamCircleMainScene:UpdateDreamCircleNode(viewData , isActive , dreamType , isVisible )
	isVisible = isVisible ~=false and true or false
	viewData.commonActiveStepImage:setVisible(isActive)
	viewData.commonStepIcon:setTexture(app.anniversary2019Mgr:GetResPath(string.fmt('ui/anniversary19/DreamCycle/wonderland_explore_pan_ico__num_' , {_num_ =dreamType })) )
	viewData.commonStepIcon:setVisible(isVisible)
end

function Anniversary19DreamCircleMainScene:UpdateAccumulativeRewardNum()
	local exploreModuleId = anniversary2019Mgr:GetCurrentExploreModuleId()
	local parseConf       = anniversary2019Mgr:GetConfigParse()
	local exploreConf     = anniversary2019Mgr:GetConfigDataByName(parseConf.TYPE.EXPLORE)
	local rewardGoodsId   = exploreConf[tostring(exploreModuleId)].rewardGoodsId
	local path = CommonUtils.GetGoodsIconPathById(rewardGoodsId)
	local accumulativeRewardNum =  anniversary2019Mgr:GetAccumulativeRewardNum()
	local viewData = self.viewData
	local goodsIdImage = viewData.goodsIdImage
	goodsIdImage:setTexture(path)
	viewData.accumulativeRewardNumLabel:setString(accumulativeRewardNum)
end

function Anniversary19DreamCircleMainScene:HideCircleExtrenal()
	local viewData = self.viewData
	viewData.circleLayout:setEnabled(false)
	viewData.circleExternal:stopAllActions()
	viewData.circleExternal:runAction(
			cc.EaseBackIn:create(cc.MoveTo:create( 0.2 , cc.p(display.width/2 , -500)))
	)
end

function Anniversary19DreamCircleMainScene:ShowCircleExtrenal(callfunc)
	local viewData = self.viewData
	viewData.circleExternal:setPosition(display.width/2 , -500 )
	viewData.circleExternal:stopAllActions()
	viewData.circleExternal:runAction(
		cc.Sequence:create(
			cc.Show:create() ,
			cc.JumpTo:create(0.7 ,self.viewData.circleExternalPos , 50 , 1  ) ,
			cc.CallFunc:create(
				function ()
					if callfunc then
						callfunc()
					end
					viewData.circleLayout:setEnabled(true)
				end
			)
		)
	)
end

function Anniversary19DreamCircleMainScene:UpdateFinallyLayout(exploreModuleId)
	local viewData = self.viewData
	local exploreHomeData  =  anniversary2019Mgr:GetHomeExploreData()
	local exploreOneData = exploreHomeData[tostring(exploreModuleId)]
	local bossLevel = exploreOneData.bossLevel
	viewData.levelText:setString(tostring(bossLevel))
end

return Anniversary19DreamCircleMainScene
