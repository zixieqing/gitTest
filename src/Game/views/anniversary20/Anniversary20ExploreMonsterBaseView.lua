---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2019/10/17 10:40 AM
---

---@class Anniversary20ExploreMonsterBaseView
local Anniversary20ExploreMonsterBaseView = class('Anniversary20ExploreMonsterBaseView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.anniversary19.Anniversary20ExploreMonsterBaseView'
	node:setName('Anniversary20ExploreMonsterBaseView')
	node:enableNodeEvents()
	return node
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newButton = display.newButton
local newLayer = display.newLayer
local RES_DICT = {
	COMMON_BTN_WHITE_DEFAULT         = _res('ui/common/common_btn_white_default.png'),
	COMMON_BTN_ORANGE                = _res('ui/common/common_btn_orange.png'),
	COM_BACK_BTN                     = _res('ui/common/common_btn_back.png'),
	WONDERLAND_TOWER_TEA_BOX         = _spn('ui/anniversary20/explore/effects/wonderland_tower_tea_box'),
	WONDERLAND_EXPLORE_BG_COMMON     = _res('ui/anniversary20/explore/exploreStep/wonderland_tower_bg_cut.png'),
	WONDERLAND_EXPLORE_GO_LINE_PANEL = _res('ui/anniversary20/explore/exploreStep/wonderland_explore_go_line_panel.png'),
	WONDERLAND_TOWER_CUT_HEAD        = _res('ui/anniversary20/explore/exploreStep/wonderland_tower_cut_head.png'),
	WONDERLAND_TOWER_CUT_BUFF_BG_1   = _res('ui/anniversary20/explore/exploreStep/wonderland_tower_cut_buff_bg_1.png'),
	WONDERLAND_TOWER_CUT_BUFF_BG_2   = _res('ui/anniversary20/explore/exploreStep/wonderland_tower_cut_buff_bg_2.png'),
}
function Anniversary20ExploreMonsterBaseView:ctor( ... )
	self:InitUI()
end


function Anniversary20ExploreMonsterBaseView:InitUI()

	local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})
	self:addChild(view,1)

	local swallowLayer = display.newLayer(display.cx , display.cy , { color = cc.c4b(0,0,0,175) , ap = display.CENTER ,  size = display.size , enable = true})
	self:addChild(swallowLayer)

	local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN , cb = function()
		app:DispatchObservers("ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT")
	end})
	view:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 35, offsetY = -15  })
	local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN , cb = function()
		app:DispatchObservers("ANNIVERSARY_2020_EXPLORE_STEP_CLOSE_EVENT")
	end})
	view:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 35, offsetY = -15  })


	local centerLayout = newLayer(643, 365,
								  { ap = display.CENTER,size = cc.size(600, 500) })
	centerLayout:setPosition(display.cx + -24, display.cy + -10)
	view:addChild(centerLayout)

	local centerBottomLayout = newLayer(326, 72,
										{ ap = display.CENTER, size = cc.size(700, 200) })
	centerLayout:addChild(centerBottomLayout)

	local centerBottomImage = display.newPathSpine(RES_DICT.WONDERLAND_TOWER_TEA_BOX)
	centerBottomImage:setAnimation(0,"idle" , true)
	self:addChild(centerBottomImage)
	centerBottomImage:setPosition(display.center)
	--centerBottomLayout:addChild(centerBottomImage)

	local centerTopLayout = newLayer(303, 100,
									 { ap = display.CENTER, size = cc.size(400, 400) })
	centerLayout:addChild(centerTopLayout)

	local rightSize = cc.size(440, 690)
	local rightLayout = newLayer(display.SAFE_R +40, display.height/2,
								 { ap = display.RIGHT_CENTER,  size = rightSize })
	view:addChild(rightLayout)

	local rightBgImage = newImageView(RES_DICT.WONDERLAND_EXPLORE_BG_COMMON, 220, rightSize.height/2 -17 ,
									  { ap = display.CENTER, tag = 55, enable = false, scale9 = true, size = rightSize })
	rightLayout:addChild(rightBgImage)

	--local titleBgImage = display.newImageView(RES_DICT.WONDERLAND_TOWER_CUT_HEAD ,220, 510 )
	--rightLayout:addChild(titleBgImage)
	local titleBtn = newButton(210, rightSize.height - 55, { ap = display.CENTER ,  n = RES_DICT.WONDERLAND_TOWER_CUT_HEAD, d = RES_DICT.WONDERLAND_TOWER_CUT_HEAD, s = RES_DICT.WONDERLAND_TOWER_CUT_HEAD, scale9 = true, tag = 56 })
	display.commonLabelParams(titleBtn, {text = "",  offset = cc.p(0 , 5) , fontSize = 24, color = '#e5b156'})
	rightLayout:addChild(titleBtn)

	local descrLabel = newLabel(210, rightSize.height - 95,
								{ ap = display.CENTER_TOP, color = '#fbe6c6', text = "", fontSize = 24, tag = 57 , w = 280, hAlign = display.TAL })
	rightLayout:addChild(descrLabel)

	local rightCenterLayout = newLayer(210, 320,
									   { ap = display.CENTER,  size = cc.size(250, 200)})
	rightLayout:addChild(rightCenterLayout)

	local resultLabel = newLabel(125, 165,
								 { ap = display.CENTER, color = '#ff976b', text = "", fontSize = 22, tag = 59 })
	rightCenterLayout:addChild(resultLabel)

	local oneline = newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_LINE_PANEL, 125, 191,
								 { ap = display.CENTER, tag = 60, enable = false })
	rightCenterLayout:addChild(oneline)

	local twoline = newImageView(RES_DICT.WONDERLAND_EXPLORE_GO_LINE_PANEL, 125, 12,
								 { ap = display.CENTER, tag = 61, enable = false })
	rightCenterLayout:addChild(twoline)

	--local goodNode = GoodNode.new({goodsId = DIAMOND_ID , showAmount = true  })
	--rightCenterLayout:addChild(goodNode)
	--goodNode:setPosition(125, 93)
	--goodNode:setOnClickScriptHandler(handler(self, self.ShowRewardsGoodsEffect))
	local goodNodesLayout = display.newLayer(125, 93 ,{
		size = cc.size(130,130) , ap = display.CENTER
	} )
	rightCenterLayout:addChild(goodNodesLayout)
	local leftButton = newButton(120, 45, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_WHITE_DEFAULT, d = RES_DICT.COMMON_BTN_WHITE_DEFAULT, s = RES_DICT.COMMON_BTN_WHITE_DEFAULT, scale9 = true, size = cc.size(122, 62), tag = 63 })
	display.commonLabelParams(leftButton, {text = "", fontSize = 24, color = '#414146'})
	rightLayout:addChild(leftButton)

	local rightButton = newButton(320, 45, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_ORANGE, d = RES_DICT.COMMON_BTN_ORANGE, s = RES_DICT.COMMON_BTN_ORANGE, scale9 = true, size = cc.size(123, 62), tag = 64 })
	display.commonLabelParams(rightButton, {text = "", fontSize = 24, color = '#414146'})
	rightLayout:addChild(rightButton)
	self:setOpacity(0)
	self:runAction(cc.FadeIn:create(0.5))
	local buffSize = cc.size(390 , 120)
	local buffLayout = display.newLayer(rightSize.width/2 -10 , 95 , {ap = display.CENTER_BOTTOM , size = buffSize})
	rightLayout:addChild(buffLayout)
	buffLayout:setVisible(false)
	local buffEffectLabel = display.newLabel( 25 , buffSize.height -0 , {ap = display.LEFT_TOP , text =__('BUFF??????') , color = "#fbe6c6", fontSize = 24  })
	buffLayout:addChild(buffEffectLabel)
	local imageOne = display.newImageView(RES_DICT.WONDERLAND_TOWER_CUT_BUFF_BG_1 , 10 , buffSize.height - 48 ,  { ap = display.LEFT_CENTER})
	buffLayout:addChild(imageOne)
	imageOne:setVisible(false)
	local imageOneSize = imageOne:getContentSize()
	local oneBuffLabel = display.newLabel(15 , imageOneSize.height/2 , fontWithColor(8, {color = "#422f2b",fontSize = 18,  hAlign = display.TAL ,w =360, ap = display.LEFT_CENTER ,  text = ""}))
	imageOne:addChild(oneBuffLabel)
	local imageTwo = display.newImageView(RES_DICT.WONDERLAND_TOWER_CUT_BUFF_BG_1, 10 , buffSize.height - 60 -40 ,  {  ap = display.LEFT_CENTER})
	buffLayout:addChild(imageTwo)
	imageTwo:setVisible(false)
	local twoBuffLabel = display.newLabel(15 , imageOneSize.height/2 , fontWithColor(8, {color = "#422f2b",fontSize = 18,  hAlign = display.TAL ,w =360,ap = display.LEFT_CENTER ,  text = ""}))
	imageTwo:addChild(twoBuffLabel)
	local noBuffLabel = display.newLabel(buffSize.width/2 , buffSize.height/2 , {
		text =__('??????BUFF') , color = "#fbe6c6", fontSize = 24
	})
	noBuffLabel:setVisible(false)
	local buffViewData = {
		{
			image = imageOne ,
			label = oneBuffLabel
		},
		{
			image = imageTwo ,
			label = twoBuffLabel
		}
	}

	self.viewData = {
		centerLayout            = centerLayout,
		centerBottomLayout      = centerBottomLayout,
		centerBottomImage       = centerBottomImage,
		centerTopLayout         = centerTopLayout,
		rightLayout             = rightLayout,
		rightBgImage            = rightBgImage,
		titleBtn                = titleBtn,
		descrLabel              = descrLabel,
		rightCenterLayout       = rightCenterLayout,
		resultLabel             = resultLabel,
		oneline                 = oneline,
		swallowLayer            = swallowLayer ,
		twoline                 = twoline,
		leftButton              = leftButton,
		goodNodesLayout         = goodNodesLayout,
		rightButton             = rightButton,
		buffLayout              = buffLayout ,
		noBuffLabel             = noBuffLabel ,
		buffViewData            = buffViewData
	}
end


function Anniversary20ExploreMonsterBaseView:SetOnlyOneBtn()
	local viewData = self.viewData
	viewData.leftButton:setVisible(false)
	viewData.rightButton:setPositionX(220)
	viewData.rightButton:setVisible(true)
end
function Anniversary20ExploreMonsterBaseView:SetOnlyLeftOneBtn()
	local viewData = self.viewData
	viewData.leftButton:setVisible(true)
	viewData.leftButton:setPositionX(220)
	viewData.rightButton:setVisible(false)
end
function Anniversary20ExploreMonsterBaseView:SetTwoBtn()
	local viewData = self.viewData
	viewData.leftButton:setVisible(true)
	viewData.rightButton:setVisible(true)
end

function Anniversary20ExploreMonsterBaseView:SetRightCenterLayoutVisible(isVisble)
	local viewData = self.viewData
	viewData.rightCenterLayout:setVisible(isVisble)
end

function Anniversary20ExploreMonsterBaseView:ShowRewardsGoodsEffect(sender)
	local goodId =  sender.goodId
	app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodId, type = 1})
end

function Anniversary20ExploreMonsterBaseView:AddGoodNodes(rewardData)
	local viewData = self.viewData
	viewData.goodNodesLayout:removeAllChildren()
	local nums = #rewardData
	local width = 130
	local layoutSize = cc.size(width*nums , width)
	viewData.goodNodesLayout:setContentSize(layoutSize)
	local GoodNode = require("common.GoodNode")
	for i = 1 , nums do
		local data =  clone(rewardData[i])
		data.showAmount = true
		local goodNode = GoodNode.new(data)
		goodNode:setPosition((i-0.5)*width , width/2)
		goodNode:setTag(rewardData[i].goodsId)
		ui.bindClick(goodNode , handler(self, self.ShowRewardsGoodsEffect))
		viewData.goodNodesLayout:addChild(goodNode)
	end
end
function Anniversary20ExploreMonsterBaseView:UpdateBuffView()
	local pluzzSkillConf = app.anniv2020Mgr:getPuzzleSkillConf(app.anniv2020Mgr:getPuzzleSkillIndex())
	local pluzzBuffId    = checkint(pluzzSkillConf.skillId)
	local buffDescrData = {}
	if pluzzBuffId > 0  then
		local descr = app.cardMgr.GetSkillDescr(pluzzBuffId)
		buffDescrData[#buffDescrData+1] = {
			descr = descr ,
			type = 1
		}
	end
	local exploreBuffs = app.anniv2020Mgr:getExploreingBuffs()
	local exploreBuffConf = CONF.ANNIV2020.EXPLORE_BUFF:GetAll()
	for index,buffId  in pairs(exploreBuffs) do
		local oneConf = exploreBuffConf[tostring(buffId)]
		local buffType = oneConf.type
		if checkint(buffType) == 1 then
			buffDescrData[#buffDescrData+1] = {
				descr = oneConf.descr ,
				type = 2
			}
		end
	end

	if #buffDescrData > 0 then
		self.viewData.buffLayout:setVisible(true)
		for index, buffData in pairs(buffDescrData) do
			local buffViewData = self.viewData.buffViewData[index]
			if buffViewData then
				local image = buffViewData.image
				local imagePath = checkint(buffData.type) == 1 and RES_DICT.WONDERLAND_TOWER_CUT_BUFF_BG_1 or RES_DICT.WONDERLAND_TOWER_CUT_BUFF_BG_2
				image:setVisible(true)
				image:setTexture(imagePath)
				display.commonLabelParams(buffViewData.label , {text = buffData.descr})
			end
		end
	else
		self.viewData.noBuffLabel:setVisible(true)
	end

end


return Anniversary20ExploreMonsterBaseView

