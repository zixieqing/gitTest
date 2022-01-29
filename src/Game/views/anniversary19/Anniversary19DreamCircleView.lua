
---@class Anniversary19DreamCircleView
local Anniversary19DreamCircleView = class('Anniversary19DreamCircleView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.anniversary19.Anniversary19DreamCircleView'
	node:setName('Anniversary19DreamCircleView')
	node:enableNodeEvents()
	return node
end)
local anniversary2019Mgr = app.anniversary2019Mgr
local newImageView = display.newImageView
local newLabel = display.newLabel
local newButton = display.newButton
local newLayer = display.newLayer
---@type Anniversary2019Manager
local RES_DICT = {
	WONDERLAND_EXPLORE_PAN_SLOT_BOSS        = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_slot_boss.png'),
	COMMON_BTN_BIG_ORANGE                   = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_big_orange.png'),
	WONDERLAND_EXPLORE_BG_COMMON            = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_bg_common.png'),
	WONDERLAND_EXPLORE_PAN_LABEL_DOUBLE     = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_label_double.png'),
	WONDERLAND_EXPLORE_PAN_LABEL_UNDOUBLE   = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_label_undouble.png'),
	WONDERLAND_EXPLORE_PAN_SLOT_ACTIVE      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_slot_active.png'),
	WONDERLAND_EXPLORE_PAN_ICO_1            = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_ico_1.png'),
	WONDERLAND_EXPLORE_PAN_SLOT_DEFAULT     = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_slot_default.png'),
	WONDERLAND_EXPLORE_PAN_BG_RING          = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_bg_ring.png'),
	WONDERLAND_EXPLORE_PAN_LABEL_DETAIL     = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_label_detail.png'),
	WONDERLAND_EXPLORE_PAN_ICO_3            = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_ico_3.png'),
	WONDERLAND_EXPLORE_PAN_SLOT_BOSS_ACTIVE = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_slot_boss_active.png'),
	RAID_ROOM_ICO_READY                     = app.anniversary2019Mgr:GetResPath('ui/common/raid_room_ico_ready.png'),
	WONDERLAND_EXPLORE_MAIN_ICO_BOSS_1      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_ico_boss_1.png'),
	WONDERLAND_EXPLORE_MAIN_ICO_BOSS_2      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_ico_boss_2.png'),
	WONDERLAND_EXPLORE_MAIN_ICO_BOSS_3      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_ico_boss_3.png'),
	WONDERLAND_EXPLORE_MAIN_LABEL_LEVEL      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_label_level.png'),

	WONDERLAND_EXPLORE_PAN_BG_1                = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_bg_1.png'),
	WONDERLAND_EXPLORE_PAN_BG_2                = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_bg_2.png'),
	WONDERLAND_EXPLORE_PAN_BG_3                = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_bg_3.png'),
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
function Anniversary19DreamCircleView:ctor( ... )
	self:InitUI()
end

function Anniversary19DreamCircleView:InitUI()
	local blackView =  newLayer(display.cx , display.cy , {
		ap = display.CENTER , size = display.size , color = cc.c4b(0,0,0,175) , enable = true
	})
	self:addChild(blackView)
	local closeView = newButton(display.cx , display.cy , {
		ap = display.CENTER , size = display.size
	})
	self:addChild(closeView)
	closeView:setEnabled(false)
	local circleLayout = newLayer(663, 364,
			{ ap = display.CENTER,  size = cc.size(768, 768) })
	circleLayout:setPosition(display.cx + -4, display.cy + -11)
	self:addChild(circleLayout)
	circleLayout:setVisible(false)
	local circleSwallowLayout = newButton(768/2, 768/2 , { size = cc.size(768, 768) })
	circleLayout:addChild(circleSwallowLayout)
	circleSwallowLayout:setEnabled(false)
	local circleImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_PAN_BG_RING, 384, 384,
			{ ap = display.CENTER, tag = 56})
	circleLayout:addChild(circleImage)
	local iconBossImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_PAN_BG_1, 384, 384,
			{ ap = display.CENTER, tag = 56 })
	circleLayout:addChild(iconBossImage)
	--iconBossImage:setVisible(false)
	local finallyLayoutSize = cc.size(140, 140)
	local finallyLayout = newLayer(379, 686,
			{ ap = display.CENTER,  size = finallyLayoutSize, enable = true })
	circleLayout:addChild(finallyLayout)

	local finallyImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_PAN_SLOT_BOSS, finallyLayoutSize.width/2 , finallyLayoutSize.height/2,
			{ ap = display.CENTER, tag = 58, enable = false })
	finallyLayout:addChild(finallyImage)

	local finallyActiveImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_PAN_SLOT_BOSS_ACTIVE, finallyLayoutSize.width/2 , finallyLayoutSize.height/2,
			{ ap = display.CENTER, tag = 59, enable = false })
	finallyLayout:addChild(finallyActiveImage)
	finallyActiveImage:setVisible(false)
	local levelLayoutSize = cc.size(41,41)
	local levelLayout = newLayer(70 , 18 , {ap = display.CENTER ,size = levelLayoutSize })
	finallyLayout:addChild(levelLayout)
	local levelBgImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_MAIN_LABEL_LEVEL ,levelLayoutSize.width/2 , levelLayoutSize.height/2)
	levelLayout:addChild(levelBgImage)
	local levelText = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	levelText:setAnchorPoint(display.RIGHT_CENTER)
	levelText:setPosition(levelLayoutSize.width/2+ 2,levelLayoutSize.height/2)
	levelLayout:addChild(levelText)
	local completeImage = newImageView(RES_DICT.RAID_ROOM_ICO_READY  ,finallyLayoutSize.width/2 , finallyLayoutSize.height/2)
	finallyLayout:addChild(completeImage)
	completeImage:setVisible(false)

	local dreamCircleNodes = {}
	for i = 1, #CIRCLR_NODE_POS_TABLE do
		local viewData = self:CreateDreamCircleNode()
		dreamCircleNodes[#dreamCircleNodes+1] = viewData
		circleLayout:addChild(viewData.commonStepsLayout,2)
		viewData.commonStepsLayout:setPosition(CIRCLR_NODE_POS_TABLE[i])
	end
	self.viewData =  {
		circleLayout          = circleLayout,
		closeView             = closeView,
		blackView             = blackView,
		finallyLayout         = finallyLayout,
		finallyImage          = finallyImage,
		finallyActiveImage    = finallyActiveImage,
		levelText             = levelText ,
		completeImage         = completeImage  ,
		dreamCircleNodes      = dreamCircleNodes,
		iconBossImage         = iconBossImage,
		circleSwallowLayout         = circleSwallowLayout,
		rewardEffectNodes     = {},
		rewardLayoutData      = nil,
		battleCardEffectNodes = {}
	}
end

function Anniversary19DreamCircleView:CreateDreamRewardEffectNode()
	local resultScView =  CScrollView:create(cc.size(210,76) )
	resultScView:setDirection(eScrollViewDirectionHorizontal)
	resultScView:setContainerSize( cc.size(210,66))
	resultScView:setAnchorPoint( display.LEFT_BOTTOM)
	local resultLayout = newLayer(0, 10,
			{ ap = display.LEFT_BOTTOM, size = cc.size(190, 70), enable = true })
	resultScView:addChild(resultLayout)

	local completeImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_PAN_LABEL_DETAIL, 95, 30,
			{ ap = display.CENTER, tag = 93, enable = false, scale9 = true,  size = cc.size(190, 66) })
	resultLayout:addChild(completeImage)

	local resultText = newLabel(165, 50,
			{ ap = display.RIGHT_CENTER, color = '#ffffff', text = "", fontSize = 20, tag = 94 })
	resultLayout:addChild(resultText)

	local resultNumText = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	resultNumText:setAnchorPoint(display.RIGHT_CENTER)
	resultNumText:setPosition(85+30, 20)
	resultLayout:addChild(resultNumText)

	local resultIcon = newImageView(RES_DICT.WONDERLAND_EXPLORE_PAN_ICO_3, 107 + 30 , 20,
			{ ap = display.CENTER, tag = 96, enable = false })
	resultLayout:addChild(resultIcon)
	resultIcon:setScale(0.2)
	return {
		resultScView  = resultScView,
		resultLayout  = resultLayout,
		completeImage = completeImage,
		resultNumText = resultNumText,
		resultText    = resultText,
		resultIcon    = resultIcon,
	}
end

function Anniversary19DreamCircleView:DreamNodeIsEnabled(viewData , isEnabled)
	viewData.commonStepsLayout:setEnabled(isEnabled)
end
function Anniversary19DreamCircleView:CreateDreamCircleNode()
	local commonStepsLayout = newButton(0, 0,
			{ ap = display.CENTER, color = cc.r4b(0), size = cc.size(94, 94), enable = true })
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

function Anniversary19DreamCircleView:CreateRewardLayout()
	local resultStepsLayout = newLayer(768/2, 768/2,
			{ ap = display.CENTER,  size = cc.size(400, 500) })

	local complateLabel = newLabel(203, 456,
			fontWithColor(14 , {  ap = display.CENTER, color = '#61ce5c', outline = '2e3807' ,  text = app.anniversary2019Mgr:GetPoText(__('探索完成！')), fontSize = 40, tag = 101 }))
	resultStepsLayout:addChild(complateLabel)

	local bossLayout = newLayer(200, 432,
			{ ap = display.CENTER_TOP, color = cc.r4b(0), size = cc.size(400, 200), enable = true })
	resultStepsLayout:addChild(bossLayout)

	local bossBgImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_BG_COMMON, 200, 102,
			{ ap = display.CENTER, tag = 103, enable = false, scale9 = true, size = cc.size(442, 200) })
	bossLayout:addChild(bossBgImage)

	local titleLabel = newLabel(190, 182,
			{ ap = display.CENTER, color = '#ffbf5c', text = app.anniversary2019Mgr:GetPoText(__('发现目标')), fontSize = 20, tag = 104 })
	bossLayout:addChild(titleLabel)

	local bossNameLabel = newLabel(147, 143,
			{ ap = display.LEFT_CENTER, color = '#ffffff', text = app.anniversary2019Mgr:GetPoText(__('发现目标')), fontSize = 26, tag = 105 })
	bossLayout:addChild(bossNameLabel)

	local bossLevelLabel = newLabel(148, 113,
			{ ap = display.LEFT_CENTER, color = '#ffaa6e', text = "", fontSize = 22, tag = 106 })
	bossLayout:addChild(bossLevelLabel)

	local bossDescrLabel = newLabel(148, 90,
			{ color = '#eeddb9', text = "", w = 260 , hAlign = display.TAL ,  ap = display.LEFT_TOP ,  fontSize = 20, tag = 107 })
	bossLayout:addChild(bossDescrLabel)
	
	local bossImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_MAIN_ICO_BOSS_3 , 15,25 , {ap = display.LEFT_BOTTOM})
	bossLayout:addChild(bossImage)
	bossImage:setScale(0.8)

	local bossResultLayout = newLayer(200, 234,
			{ ap = display.CENTER_TOP, size = cc.size(400, 160) })
	resultStepsLayout:addChild(bossResultLayout)

	local bossResultBgImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_BG_COMMON, 200, 81,
			{ ap = display.CENTER, tag = 109, enable = false, scale9 = true, size = cc.size(442, 160) })
	bossResultLayout:addChild(bossResultBgImage)

	local titleBossResultLabel = newLabel(189, 141,
			{ ap = display.CENTER, color = '#ffbf5c', text = app.anniversary2019Mgr:GetPoText(__('发现目标')), fontSize = 20, tag = 110 })
	bossResultLayout:addChild(titleBossResultLabel)
	---@type GoodNode
	local goodNode = require('common.GoodNode').new({
		goodsId =  DIAMOND_ID  , num = 0  , showAmount = true
	})
	bossResultLayout:addChild(goodNode)
	goodNode:setScale(0.8)

	goodNode:setPosition(200, 60 )
	local rewardsBtn = newButton(196, 35, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_BIG_ORANGE, d = RES_DICT.COMMON_BTN_BIG_ORANGE, s = RES_DICT.COMMON_BTN_BIG_ORANGE, scale9 = true, size = cc.size(148, 71), tag = 116 })
	display.commonLabelParams(rewardsBtn, {text = app.anniversary2019Mgr:GetPoText(__('领取')), fontSize = 28, color = '#ffffff'})
	resultStepsLayout:addChild(rewardsBtn)
	rewardsBtn:setScale(0.9)
	return {
		resultStepsLayout    = resultStepsLayout,
		complateLabel        = complateLabel,
		bossLayout           = bossLayout,
		bossBgImage          = bossBgImage,
		titleLabel           = titleLabel,
		bossNameLabel        = bossNameLabel,
		bossLevelLabel       = bossLevelLabel,
		bossDescrLabel       = bossDescrLabel,
		bossResultLayout     = bossResultLayout,
		bossResultBgImage    = bossResultBgImage,
		titleBossResultLabel = titleBossResultLabel,
		goodNode             = goodNode,
		bossImage            = bossImage,
		rewardsBtn           = rewardsBtn
	}
end

function Anniversary19DreamCircleView:CreateBattleCardEffectNode()
	local battleCardSize = cc.size(129, 31)
	local battleCardLayout = newLayer(0,0, {ap = display.CENTER_TOP  , size = battleCardSize })
	local battleCardBtn = display.newButton(battleCardSize.width/2 , battleCardSize.height/2 , {
		n = RES_DICT.WONDERLAND_EXPLORE_PAN_LABEL_DOUBLE
	})
	battleCardLayout:addChild(battleCardBtn)

	local winLabel = display.newLabel(battleCardSize.width/2 , battleCardSize.height/2 ,{
		ttf = true , font = TTF_GAME_FONT , fontSize = 22 , text = "" , color = '#a8a8a8'
	})
	winLabel:setVisible(false)
	battleCardLayout:addChild(winLabel)

	local failureLabel = display.newLabel(battleCardSize.width/2 , battleCardSize.height/2 ,fontWithColor(14, {
		ttf = true , font = TTF_GAME_FONT , fontSize = 22 , text = "" , color = "#410808"
	}))
	failureLabel:setVisible(false)
	battleCardLayout:addChild(failureLabel)
	return {
		battleCardBtn    = battleCardBtn,
		battleCardLayout = battleCardLayout,
		winLabel         = winLabel,
		failureLabel     = failureLabel,
	}
end

function Anniversary19DreamCircleView:UpdateFinallyLayout(exploreModuleId , isFinally )
	local viewData = self.viewData
	local exploreHomeData  =  anniversary2019Mgr:GetHomeExploreData()
	local exploreOneData = exploreHomeData[tostring(exploreModuleId)]
	local bossLevel = exploreOneData.bossLevel
	viewData.levelText:setString(tostring(bossLevel))
	if isFinally then
		viewData.finallyActiveImage:setVisible(true)
		viewData.completeImage:setVisible(true)
	else
		viewData.finallyActiveImage:setVisible(false)
		viewData.completeImage:setVisible(false)
	end
end

function Anniversary19DreamCircleView:UpdateDreamCircleNode(viewData , isActive , dreamType , isVisible)
	isVisible = isVisible ~= false and true or false
	viewData.commonActiveStepImage:setVisible(isActive)
	viewData.commonStepIcon:setTexture(app.anniversary2019Mgr:GetResPath(string.fmt('ui/anniversary19/DreamCycle/wonderland_explore_pan_ico__num_' , {_num_ = dreamType })) )
	viewData.commonStepIcon:setVisible(isVisible)
end
function Anniversary19DreamCircleView:StepRewardAnimation(outputGoodsId ,progress )
	local posTab = {
		cc.p(0,60),
		cc.p(-20,30),
		cc.p(25,30),
		cc.p(-30,-30),
		cc.p(30,-30),
		cc.p(math.random(10),math.random(90)),
		cc.p(math.random(30),math.random(70)),
		cc.p(math.random(50),math.random(50)),
		cc.p(math.random(70),math.random(30)),
		cc.p(math.random(90),math.random(10))
	}
	local spawnTable  = {}
	local iconPath = CommonUtils.GetGoodsIconPathById(outputGoodsId)

	local initPos =CIRCLR_NODE_POS_TABLE[progress]
	local rewardsBtnPos = cc.p(self.viewData.rewardLayoutData.rewardsBtn:getPosition())
	local rewardsWordPos = self.viewData.rewardLayoutData.bossResultLayout:convertToWorldSpace(rewardsBtnPos)
	local endPos = self.viewData.circleLayout:convertToNodeSpace(rewardsWordPos)
	local scale = 0.4
	for i=1,table.nums(posTab) do
		local img= newImageView(iconPath,0,0,{as = false})
		img:setPosition(initPos)
		img:setTag(555)
		img:setVisible(false)
		self.viewData.circleLayout:addChild(img,10)
		spawnTable[#spawnTable+1] =  cc.TargetedAction:create(img ,
			cc.Sequence:create(
				cc.Show:create(),
				cc.Spawn:create(
					cc.ScaleTo:create(0.2, scale),
					cc.MoveBy:create(0.3,posTab[i])
				),
				cc.MoveBy:create(0.1+i*0.11,cc.p(math.random(15),math.random(15))),
				cc.DelayTime:create(i*0.01),
				cc.Spawn:create(
						cc.MoveTo:create(0.4, endPos),
						cc.ScaleTo:create(0.4, 0.2)
				),
				cc.RemoveSelf:create()
			)
		)
	end
	spawnTable[#spawnTable+1] =  cc.TargetedAction:create(self.viewData.rewardLayoutData.goodNode.infoLabel,
		cc.Sequence:create(
			cc.DelayTime:create(0.4),
			CountAction:create(0.4, checkint(self.viewData.rewardLayoutData.goodNode.infoLabel:getString()), anniversary2019Mgr:GetAccumulativeRewardNum())
		)
	)
	self.viewData.circleLayout:runAction(
		cc.Sequence:create(
			cc.DelayTime:create(1),
			cc.Spawn:create(spawnTable)  ,
			cc.CallFunc:create(function()
				AppFacade.GetInstance():DispatchObservers("STEP_REWARD_ANIMATION_EVENT" , {})
			end)
		)
	)
end
----=======================----
--@author : xingweihao
--@date : 2019/10/23 11:03 AM
--@Description
--@params viewData  userdate ,  result 1 胜利 2 失败
--@return
---=======================----
function Anniversary19DreamCircleView:UpdateBattleCardEffectNode(viewData ,result )
	if result == 1 then
		viewData.battleCardBtn:setNormalImage(RES_DICT.WONDERLAND_EXPLORE_PAN_LABEL_DOUBLE )
		viewData.battleCardBtn:setSelectedImage(RES_DICT.WONDERLAND_EXPLORE_PAN_LABEL_DOUBLE)
		viewData.winLabel:setVisible(true)
		viewData.failureLabel:setVisible(false)
		display.commonLabelParams(viewData.winLabel , { text = app.anniversary2019Mgr:GetPoText(__('翻倍')) , color = '#9bff39' , outline = "#410808" ,  outlineSize = 2  })
	elseif result == 2 or result == 0  then
		viewData.battleCardBtn:setNormalImage(RES_DICT.WONDERLAND_EXPLORE_PAN_LABEL_UNDOUBLE )
		viewData.battleCardBtn:setSelectedImage(RES_DICT.WONDERLAND_EXPLORE_PAN_LABEL_UNDOUBLE)
		viewData.failureLabel:setVisible(true)
		viewData.winLabel:setVisible(false)
		display.commonLabelParams(viewData.failureLabel , { text = app.anniversary2019Mgr:GetPoText(__('未翻倍')) , color = '#a8a8a8' })
	end
end

function Anniversary19DreamCircleView:UpdateRewardEffectNode(viewData ,  text  ,  rewardData)
	local num =  checkint(rewardData.num)
	local color = nil
	if num > 0  then
		-- 胜利
		color = "#a3e763"
		viewData.resultNumText:setString("+" .. rewardData.num )
	else
		-- 失败
		color = "#ff6750"
		viewData.resultNumText:setString( rewardData.num )
	end
	viewData.resultIcon:setTexture(CommonUtils.GetGoodsIconPathById(rewardData.goodsId))
	display.commonLabelParams(viewData.resultText  , {text = text , color = color})
end


function Anniversary19DreamCircleView:UpdateRewardLayout( viewData ,isFinally ,exploreModuleId )
	viewData.complateLabel:setVisible(false)
	viewData.bossResultLayout:setVisible(true)
	display.commonLabelParams(viewData.titleBossResultLabel , {color = "#ffffff" , text = app.anniversary2019Mgr:GetPoText(__('收获小计'))})
	local rewardData = {
		goodsId = anniversary2019Mgr:GetRewardGoodsId(exploreModuleId) ,
		num = anniversary2019Mgr:GetAccumulativeRewardNum()
	}
	viewData.goodNode:RefreshSelf(rewardData)
	display.commonUIParams(viewData.goodNode , { animate = false ,  cb = function(sender)
		local goodId =  sender.goodId
		app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodId, type = 1})
	end})
	display.commonLabelParams(viewData.rewardsBtn , fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('继续'))}))
	viewData.rewardsBtn:setVisible(false)
	viewData.bossLayout:setVisible(false)
	if isFinally then
		viewData.complateLabel:setVisible(true)
		viewData.rewardsBtn:setVisible(true)
		viewData.bossLayout:setVisible(true)
		local parseConf = anniversary2019Mgr:GetConfigParse()
		local chapterConf = anniversary2019Mgr:GetConfigDataByName(parseConf.TYPE.CHAPTER)
		local exploreHomeData = anniversary2019Mgr:GetHomeExploreData()
		local chapterOneConf = chapterConf[tostring(exploreModuleId)]
		local bossName = chapterOneConf.bossName
		local dialogue = chapterOneConf.dialogue
		local bossLevel = exploreHomeData[tostring(exploreModuleId)].bossLevel
		display.commonLabelParams(viewData.rewardsBtn , fontWithColor(14 , {text = app.anniversary2019Mgr:GetPoText(__('领取'))}))
		display.commonLabelParams(viewData.titleLabel , {color = "#ffbf5c" , text = app.anniversary2019Mgr:GetPoText(__('发现目标'))})
		display.commonLabelParams(viewData.bossNameLabel , { text = bossName})
		display.commonLabelParams(viewData.bossLevelLabel , { text = string.fmt(app.anniversary2019Mgr:GetPoText(__('等级_level_')) , {_level_ = bossLevel}) })
		display.commonLabelParams(viewData.bossDescrLabel , { text = dialogue})
		display.commonLabelParams(viewData.titleBossResultLabel , {color = "#ffbf5c" , text = app.anniversary2019Mgr:GetPoText(__('结算材料'))})
		local path = RES_DICT ["WONDERLAND_EXPLORE_MAIN_ICO_BOSS_" .. exploreModuleId]
		viewData.bossImage:setTexture(path)
		local spinePathBoss = anniversary2019Mgr.spineTable.WONDERLAND_EXPLORE_BOSS
		anniversary2019Mgr:AddSpineCacheByPath(spinePathBoss)
	end
end

function Anniversary19DreamCircleView:ScrollViewAction(viewData)
	viewData.resultLayout:setPosition(-190 , 0 )
	viewData.resultLayout:stopAllActions()
	viewData.resultLayout:runAction(
			cc.EaseSineInOut:create(cc.MoveTo:create(1, cc.p(0 , 5 )))
	)
end

function Anniversary19DreamCircleView:GetDreamTypeText(dreamType , result ,  exploreModuleId , exploreId )
	dreamType =  checkint(dreamType)
	local dreamQuestType =anniversary2019Mgr.dreamQuestType
	local parseConf = anniversary2019Mgr :GetConfigParse()
	local exploreConf = anniversary2019Mgr:GetConfigDataByName(parseConf.TYPE.EXPLORE)
	local rewardGoodsId = exploreConf[tostring(exploreModuleId)].rewardGoodsId
	if dreamType ==  dreamQuestType.ELITE_SHUT or dreamType == dreamQuestType.LITTLE_MONSTER  then
		if result == 1 then
			return app.anniversary2019Mgr:GetPoText(__('战斗胜利！')) ,  anniversary2019Mgr:GetDreamTypeReward(exploreModuleId , dreamType ,exploreId )
		else
			return app.anniversary2019Mgr:GetPoText(__('放弃战斗')) , {goodsId = rewardGoodsId , num = 0  }
		end
	elseif dreamType == dreamQuestType.CHEST_SHUT then
		return app.anniversary2019Mgr:GetPoText(__('发现宝箱！')) ,  anniversary2019Mgr:GetDreamTypeReward(exploreModuleId , dreamType ,exploreId )
	elseif   dreamType == dreamQuestType.ANSWER_SHUT then
		if result == 1 then
			return app.anniversary2019Mgr:GetPoText(__('回答正确！'))  , anniversary2019Mgr:GetDreamTypeReward(exploreModuleId , dreamType ,exploreId )
		else
			return app.anniversary2019Mgr:GetPoText(__('回答错误')) , {goodsId = rewardGoodsId , num = 0  }
		end
	elseif   dreamType == dreamQuestType.GUAN_PLOT then
		return app.anniversary2019Mgr:GetPoText(__('观看剧情！')) ,  anniversary2019Mgr:GetDreamTypeReward(exploreModuleId , dreamType ,exploreId )
	elseif   dreamType == dreamQuestType.CARDS_SHUT then
		if result == 1 then
			return app.anniversary2019Mgr:GetPoText(__('打牌胜利！')) ,  anniversary2019Mgr:GetDreamTypeReward(exploreModuleId , dreamType ,exploreId )
		else
			return app.anniversary2019Mgr:GetPoText(__('打牌失败')) , {goodsId = rewardGoodsId , num = 0 }
		end
	end
end
--- 播放领奖动画
function Anniversary19DreamCircleView:DreamNodeRunRewardAnimation()
	local spinePathOne = anniversary2019Mgr.spineTable.WONDERLAND_EXPLORE_LIGHT
	local spinePathBoss = anniversary2019Mgr.spineTable.WONDERLAND_EXPLORE_BOSS
	anniversary2019Mgr:AddSpineCacheByPath(spinePathOne)
	anniversary2019Mgr:AddSpineCacheByPath(spinePathBoss)
	local seqTable = {}
	local delayTime = 0.2
	for i =1, #self.viewData.dreamCircleNodes do
		local dreamCircleData = self.viewData.dreamCircleNodes[i]
		seqTable[#seqTable+1] = cc.TargetedAction:create(dreamCircleData.commonStepsLayout ,
			cc.Sequence:create(
			 cc.CallFunc:create(
				function()
					local nodeSpine =  SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(spinePathOne)
					dreamCircleData.commonStepsLayout:addChild(nodeSpine,10)
					nodeSpine:setAnimation(0,'light1' ,  false)
					nodeSpine:setPosition(47,47)
					nodeSpine:setScale(1.5)
				end
			), cc.DelayTime:create(delayTime )
		)  )
	end
	for index , dreamViewData in pairs(self.viewData.rewardEffectNodes) do
		dreamViewData.resultScView:setVisible(false)
	end
	self.viewData.rewardLayoutData.resultStepsLayout:setVisible(false)
	seqTable[#seqTable+1] =  cc.TargetedAction:create(self.viewData.finallyLayout , cc.Sequence:create(
	 cc.CallFunc:create(
		function()
			local nodeSpine =  SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(spinePathOne)
			self.viewData.finallyLayout:addChild(nodeSpine ,10 )
			nodeSpine:setAnimation(0,'light2' ,  false)
			nodeSpine:setPosition(70,70)
			nodeSpine:setScale(1.5)
		end
		),
		cc.DelayTime:create(delayTime)  ,
		cc.CallFunc:create(function()
			local spineCallback = function()
				AppFacade.GetInstance():DispatchObservers(	"RUN_ENTER_ACTION_EVENT" , { })
				self.viewData.rewardLayoutData.resultStepsLayout:setVisible(true)
				local nodeSpine = self.viewData.circleLayout:getChildByName("nodeSpine")
				if nodeSpine and (not tolua.isnull(nodeSpine)) then
					nodeSpine:setVisible(false)
				end
			end
			self:UpdateFinallyLayout(anniversary2019Mgr:GetCurrentExploreModuleId() , true)
			local nodeSpine =  SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(spinePathBoss)
			self.viewData.circleLayout:addChild(nodeSpine)
			nodeSpine:setName("nodeSpine")
			nodeSpine:setAnimation(0,'play'  .. anniversary2019Mgr:GetCurrentExploreModuleId() ,  false)
			nodeSpine:setPosition(384,384)
			nodeSpine:registerSpineEventHandler(spineCallback, sp.EventType.ANIMATION_COMPLETE)
		end)
		)
	)
	self.viewData.circleLayout:runAction(
		cc.Sequence:create(seqTable)
	)
end

function Anniversary19DreamCircleView:DrawNodeTrapShutRewardAction()
	local spinePathBoss = anniversary2019Mgr.spineTable.WONDERLAND_EXPLORE_BOSS
	anniversary2019Mgr:AddSpineCacheByPath(spinePathBoss)
	for index , dreamViewData in pairs(self.viewData.rewardEffectNodes) do
		dreamViewData.resultScView:setVisible(false)
	end
	self.viewData.rewardLayoutData.resultStepsLayout:setVisible(false)
	local spineCallback = function()
		AppFacade.GetInstance():DispatchObservers(	"RUN_ENTER_ACTION_EVENT" , { })
		self.viewData.rewardLayoutData.resultStepsLayout:setVisible(true)
		local nodeSpine = self.viewData.circleLayout:getChildByName("nodeSpine")
		if nodeSpine and (not tolua.isnull(nodeSpine)) then
			nodeSpine:setVisible(false)
		end
	end

	self:UpdateFinallyLayout(anniversary2019Mgr:GetCurrentExploreModuleId() , true)
	local nodeSpine =  SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(spinePathBoss)
	self.viewData.circleLayout:addChild(nodeSpine)
	nodeSpine:setName("nodeSpine")
	nodeSpine:setAnimation(0,'play'  .. anniversary2019Mgr:GetCurrentExploreModuleId() ,  false)
	nodeSpine:setPosition(384,384)
	nodeSpine:registerSpineEventHandler(spineCallback, sp.EventType.ANIMATION_COMPLETE)
end
--- 播放结束动画
function Anniversary19DreamCircleView:RunEndAnimation()
	local spineCallback = function()
		self:runAction(
			cc.Sequence:create(
				cc.DelayTime:create(0.1) ,
				cc.CallFunc:create(function()
					AppFacade.GetInstance():DispatchObservers(	"CLOSE_DREAM_CIRCLE_VIEW_EVENT" , { })
				end)
			)
		)
	end
	local viewData = self.viewData
	local spinePath = anniversary2019Mgr.spineTable.WONDERLAND_MAIN_TREE
	anniversary2019Mgr:AddSpineCacheByPath(spinePath)
	local  endTreeSpine = SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(spinePath)
	endTreeSpine:setPosition( 384, 384)
	endTreeSpine:setName("readySpine")
	viewData.circleLayout:addChild(endTreeSpine , 2)
	endTreeSpine:setAnimation(0,'play' .. anniversary2019Mgr:GetCurrentExploreModuleId()  , false)
	endTreeSpine:registerSpineEventHandler(spineCallback, sp.EventType.ANIMATION_COMPLETE)
end
function Anniversary19DreamCircleView:EnterAction()
	local circleLayout = self.viewData.circleLayout
    local circleLayoutPos = cc.p(circleLayout:getPosition())
	local circleSize = circleLayout:getContentSize()
	circleLayout:setPosition(display.width/2 , - circleSize.height/2 )
	circleLayout:setScale(0.6)
	--circleLayout:setOpacity(125)
	app:DispatchObservers("SHOW_SWALLOW_TOP_LAYER" , {})
	circleLayout:runAction(
		cc.Sequence:create(
			cc.Show:create(),
			cc.Spawn:create(
				cc.FadeIn:create(0.8),
				cc.EaseBackOut:create(cc.MoveTo:create(0.8,circleLayoutPos )) ,
				cc.Sequence:create(
					cc.DelayTime:create(0.2) ,
					cc.CallFunc:create(function()
						AppFacade.GetInstance():DispatchObservers("DREAM_VIEW_ENTER_ACTION_EVENT")
					end),
					cc.DelayTime:create(0.6)
				)
			) ,
			cc.ScaleTo:create(0.5, 1) ,
			cc.CallFunc:create(function()
				AppFacade.GetInstance():DispatchObservers("DREAM_VIEW_ENTER_ACTION_END_EVENT")
				app:DispatchObservers("HIDE_SWALLOW_TOP_LAYER" , {})
			end)
		)
	)
end
function Anniversary19DreamCircleView:UpdateRunActionIconBoss()
	local viewData = self.viewData
	local iconBossImage  = viewData.iconBossImage
	local exploreModuleId =anniversary2019Mgr:GetCurrentExploreModuleId()
	local path = RES_DICT["WONDERLAND_EXPLORE_PAN_BG_" ..exploreModuleId ]
	--iconBossImage:setVisible(true)
	iconBossImage:setTexture(path)
	iconBossImage:runAction(
			cc.RepeatForever:create(cc.RotateBy:create(3, 15))
	)
end
return Anniversary19DreamCircleView
