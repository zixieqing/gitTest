--[[
NPC图鉴主页面Scene
--]]
local GameScene = require( "Frame.GameScene" )
---@class BlackGoldHomeScene
local BlackGoldHomeScene = class('BlackGoldHomeScene', GameScene)
---@type GoodPurchaseNode
local GoodPurchaseNode = require('common.GoodPurchaseNode')
---@type CommerceConfigParser
local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")
local BUTTON_TAG = {
	BACK_BTN         = 1003, -- 返回按钮
	INVESTMENT       = 1004, -- 投资营收
	PORT_TRADE       = 1005, -- 港口贸易
	THIS_GOODS       = 1006, -- 本期货物
	BUSINESS_EFFECT  = 1007, --商团声望
	UPGRADE_BUSINESS = 1008, --商团升级
	BLACK_GOLD_RULE  = 1009, --锦安商会规则
}
local newImageView = display.newImageView
local newLabel = display.newLabel
local newButton = display.newButton
local newLayer = display.newLayer
local RES_DICT = {
	GOLD_HOME_BTN_TOUZI           = _res('ui/home/blackShop/gold_home_btn_touzi.png'),
	COMMON_BG_TIPS_HORN           = _res('ui/common/common_bg_tips_horn'),
	GOLD_HOME_BG_BOAT             = _res('ui/home/blackShop/gold_home_bg_boat.png'),
    GOLD_HOME_FG_BOAT             = _res('ui/home/blackShop/gold_home_fg_boat.png'),
	GOLD_HOME_ICO_TOUZI           = _res('ui/home/blackShop/gold_home_ico_touzi.png'),
	GOLD_HOME_BTN_MAOYI_GREY      = _res('ui/home/blackShop/gold_home_btn_maoyi_grey.png'),
    GOLD_HOME_ICO_MAOYI           = _res('ui/home/blackShop/gold_home_ico_maoyi.png'),
    GOLD_HOME_ICO_CARGO           = _res('ui/home/blackShop/gold_home_ico_cargo.png'),
	GOLD_HOME_WAIT_TIME_BG        = _res('ui/home/blackShop/gold_home_wait_time_bg.png'),
	GOLD_HOME_BG_NAME_LIST_LEVEL  = _res('ui/home/blackShop/gold_home_bg_name_list_level.png'),
	GOLD_HOME_BTN_MAX             = _res('ui/home/blackShop/gold_home_btn_max.png'),
	GOLD_HOME_BTN_LEVEL           = _res('ui/home/blackShop/gold_home_btn_level.png'),
	GOLD_HOME_ICO_NAME_LIST_LEVEL = _res('ui/home/blackShop/gold_home_ico_name_list_level.png'),
	GOLD_HOME_BG                  = _res('ui/home/blackShop/gold_home_bg.png'),
	GOLD_HOME_BG_NAME_LIST        = _res('ui/home/blackShop/gold_home_bg_name_list.png'),
	GOLD_HOME_BTN_SHENW_DOWN      = _res('ui/home/blackShop/gold_home_btn_shenw_down.png'),
	GOLD_HOME_WAIT_TIME           = _res('ui/home/blackShop/gold_home_wait_time.png'),
	GOLD_HOME_BG_LEAVE           = _res('ui/home/blackShop/gold_home_bg_leave.png'),
	GOLD_HOME_LINE_NAME_LIST_LEVEL= _res('ui/home/blackShop/gold_home_line_name_list_level.png'),
	GOLD_HOME_BG_NAME             = _res('ui/home/blackShop/gold_home_bg_name.png'),
	GOLD_HOME_BG_NAME_SHEN        = _res('ui/home/blackShop/gold_home_bg_name_shen.png'),
	GOLD_HOME_BG_NAME_QI3         = _res('ui/home/blackShop/gold_home_bg_name_qi3.png'),
}

function BlackGoldHomeScene:ctor(...)
    self.super.ctor(self,'views.BlackGoldHomeScene')
    self.viewData = nil
    local function CreateView()

        local view = display.newLayer(display.cx , display.cy ,{ ap = display.CENTER , size = display.size})
        self:addChild(view)
        view:setPosition(display.center)
		local bgPath = app.blackGoldMgr:GetIsTrade() and RES_DICT.GOLD_HOME_BG or RES_DICT.GOLD_HOME_BG_LEAVE
  		local bgImage = newImageView(bgPath, 667, 375,
				{ ap = display.CENTER, tag = 42, enable = false })
		bgImage:setPosition(display.cx + 0, display.cy + 0)
		view:addChild(bgImage)
		bgImage:setVisible(false)

		local bgGoodImage = display.newImageView(RES_DICT.GOLD_HOME_BG_BOAT , display.cx + 0, 156)
		view:addChild(bgGoodImage)
		bgGoodImage:setVisible(app.blackGoldMgr:GetIsTrade())

		local bottomImage = newImageView(RES_DICT.GOLD_HOME_FG_BOAT, 667, 156,
				{ ap = display.CENTER, tag = 43, enable = false })
		bottomImage:setPosition(display.cx + 0, 100)
		view:addChild(bottomImage,2)
		bottomImage:setVisible(false)

        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height,{n = _res('ui/common/common_title_new.png'),enable = true,tag = BUTTON_TAG.TIPS_TAG , ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('景安商会'), fontSize = 30, color = '#473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)
		tabNameLabel:setTag(BUTTON_TAG.BLACK_GOLD_RULE)
        local tipsBtn = display.newButton(tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10, {n = _res('ui/common/common_btn_tips.png')})
        tabNameLabel:addChild(tipsBtn, 10)

		-- back btn
        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
        backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
        view:addChild(backBtn, 20)
        backBtn:setTag(BUTTON_TAG.BACK_BTN)


        local moduleBtns = {}
        local moudleInfo = {
            { bgPath = RES_DICT.GOLD_HOME_ICO_TOUZI , titlePath = RES_DICT.GOLD_HOME_BTN_TOUZI , tag = BUTTON_TAG.INVESTMENT , text = __('投资计划') , pos = cc.p(display.SAFE_R - 343 - 200 , 37)  },
            { bgPath = RES_DICT.GOLD_HOME_ICO_MAOYI , titlePath = RES_DICT.GOLD_HOME_BTN_TOUZI , tag = BUTTON_TAG.PORT_TRADE, text = __('港口贸易')  , pos = cc.p(display.SAFE_R - 343  ,37 ) },
            { bgPath = RES_DICT.GOLD_HOME_ICO_CARGO , titlePath = RES_DICT.GOLD_HOME_BTN_TOUZI , tag = BUTTON_TAG.THIS_GOODS , text = __('本期货物') , pos = cc.p(display.SAFE_R - 343+200  ,37 ) },

        }

        local iconData = { REPUTATION_ID , GOLD_ID, DIAMOND_ID}
        local cellSize = cc.size(190,40)
    
        local len = #iconData
        local  topSize = cc.size(cellSize.width * len + 20 ,cellSize.height)
        local topLayout = display.newLayer( display.SAFE_R,display.height, { ap = display.RIGHT_TOP , size =  topSize})
        view:addChild(topLayout,20)
        local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),topSize.width/2,topSize.height/2,{enable = false,
                                          scale9 = true, size = cc.size(topSize.width + 60, 54)})
        topLayout:addChild(imageImage)
    
        local purchaseNodes = {}
        for k ,v  in pairs(iconData) do
			local isShowHpTips = (v == REPUTATION_ID and true) or false
            local purchaseNode = GoodPurchaseNode.new({id = v , disable = isShowHpTips})
            purchaseNode:updataUi(checkint(v))
            purchaseNode:setPosition(cc.p(cellSize.width * (k -0.5) , cellSize.height/2 ))
            topLayout:addChild(purchaseNode,10)
            purchaseNode.viewData.touchBg:setTag(checkint(v))
            purchaseNodes[tostring(v)] = purchaseNode
        end

        for i = 1 , #moudleInfo do
            local moduleBtn = newButton(721, 37,
                    { ap = display.CENTER_BOTTOM, color = cc.c4b(0, 0,0,0), size = cc.size(170, 170), enable = true })
            view:addChild(moduleBtn ,2)

            local iconImage = newImageView(moudleInfo[i].bgPath, 85, 106,
                    { ap = display.CENTER, tag = 30, enable = false })
            moduleBtn:addChild(iconImage)
            iconImage:setTag(1)

            local titleImage = newImageView( moudleInfo[i].titlePath, 85, 29,
                    { ap = display.CENTER, tag = 31, enable = false })
            moduleBtn:addChild(titleImage)
			titleImage:setName("titleImage")
            titleImage:setTag(2)
            local titleLabel = newLabel(85, 27,
                    fontWithColor(14,{ ap = display.CENTER, color = '#ffffff', text = moudleInfo[i].text, fontSize = 24, tag = 32 }))
            moduleBtn:addChild(titleLabel)
            titleLabel:setTag(3)
            moduleBtn:setTag(moudleInfo[i].tag)
            moduleBtn:setPosition(moudleInfo[i].pos)
            moduleBtns[tostring(moudleInfo[i].tag)] = moduleBtn
        end
        
        local leftTimeDecr = newLabel(display.SAFE_L + 44, 108,
            fontWithColor(14,{ ap = display.LEFT_CENTER, color = '#ffffff', text = __('本期贸易剩余：'), fontSize = 24, tag = 352 }))
        view:addChild(leftTimeDecr,2)

		local waitTimeLayout = display.newLayer(display.SAFE_L + 44, 68 , {ap = display.LEFT_CENTER,  color = cc.r4b() ,size = cc.size(268, 44)})
		view:addChild(waitTimeLayout,2)

		local waitImage = display.newImageView(RES_DICT.GOLD_HOME_WAIT_TIME_BG , 134, 22)
		waitTimeLayout:addChild(waitImage)
		local posTable ={
			cc.p(10 + (1 - 0.5 ) * 30  ,22),
			cc.p(10 + (2 - 0.5 ) * 30  ,22),
			cc.p(10 + (3- 0.5 ) * 30  ,22),
			cc.p(10 + (5- 0.5 ) * 30-6  ,22),
			cc.p(10 + (6- 0.5 ) * 30-4  ,22),
			cc.p(10 + (8- 0.5 ) * 30-10  ,22),
			cc.p(10 + (9- 0.5 ) * 30-9 ,22 )
		}
		local imageTable = {}
		for i = 1 , 7 do
			local image = display.newImageView( RES_DICT.GOLD_HOME_WAIT_TIME ,  posTable[i].x-5 , posTable[i].y )
			waitTimeLayout:addChild(image)
			imageTable[#imageTable+1] = image
		end
		for i = 1 , 7 do
			local image = imageTable[i]
			local pointNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
			pointNum:setHorizontalAlignment(display.TAC)
			pointNum:setAnchorPoint(display.CENTER)
			pointNum:setPosition(11 , 17)
			pointNum:setScale(1.2)
			pointNum:setString(i)
			pointNum:setTag(1)
			image:addChild(pointNum)
		end


		local string1 = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
		string1:setPosition(cc.p( (4- 0.5 ) * 30  ,22))
		string1:setHorizontalAlignment(display.TAC)
		string1:setAnchorPoint(display.CENTER)
		waitTimeLayout:addChild(string1)
		string1:setString(":")

		local string2 = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
		string2:setPosition(cc.p( (7- 0.5 ) * 30-3  ,22))
		string2:setHorizontalAlignment(display.TAC)
		string2:setAnchorPoint(display.CENTER)
		waitTimeLayout:addChild(string2)
		string2:setString(":")
		string2:setScale(1.2)
		
        local nameLayout = newLayer(991, 767,
            { ap = display.CENTER_TOP,size = cc.size(444, 536), enable = true })
        nameLayout:setPosition(display.SAFE_R - 343, display.height + 17)
        view:addChild(nameLayout,2)
		nameLayout:setVisible(false)
        local nameImage = newImageView(RES_DICT.GOLD_HOME_BG_NAME_QI3, 0, 0,
            { ap = display.LEFT_BOTTOM, tag = 354, enable = false })
        nameLayout:addChild(nameImage,-2)

		local upgradeBtnLayout = display.newLayer(219, 131 ,{ap = display.CENTER ,size = cc.size(165, 165) } )
		nameLayout:addChild(upgradeBtnLayout)
        local upgradeBtn = newLayer(82.5, 82.5,
            { ap = display.CENTER, color = cc.r4b(0), size = cc.size(165, 165), enable = true })
		upgradeBtnLayout:addChild(upgradeBtn)
		upgradeBtn:setTag(BUTTON_TAG.UPGRADE_BUSINESS)
        
        local levelBgImage = newImageView(RES_DICT.GOLD_HOME_BTN_LEVEL, 82, 82,
            { ap = display.CENTER, tag = 356, enable = false })
		upgradeBtnLayout:addChild(levelBgImage)
        
        local levelLabel = newLabel(82, 82,
            fontWithColor(14,{ ap = display.CENTER, color = '#ffffff', text = __("升级"), fontSize = 24, tag = 357 }))
		upgradeBtnLayout:addChild(levelLabel)
        
        local Image_20 = newImageView(RES_DICT.GOLD_HOME_BG_NAME_SHEN, 472, 550,
            { ap = display.CENTER_TOP, tag = 358, enable = false })
        nameLayout:addChild(Image_20)
        
        local lineImage = newImageView(RES_DICT.GOLD_HOME_LINE_NAME_LIST_LEVEL, 63, 383,
            { ap = display.LEFT_BOTTOM, tag = 360, enable = false })
        nameLayout:addChild(lineImage)

		local theirBusiness = display.newButton(210 ,400,{ size = cc.size(150, 50 )})
		display.commonLabelParams(theirBusiness , fontWithColor(8 , {fontSize = 24,  color = "#7A502B" , text = __('商团称号')}))
		nameLayout:addChild(theirBusiness)
		theirBusiness:setTag(BUTTON_TAG.BUSINESS_EFFECT)

		local dowmImage = display.newImageView(RES_DICT.GOLD_HOME_BTN_SHENW_DOWN ,150 , 25 )
		theirBusiness:addChild(dowmImage)

        local nameLabel = newButton(220, 294, { ap = display.CENTER ,  n = RES_DICT.GOLD_HOME_BG_NAME, d = RES_DICT.GOLD_HOME_BG_NAME, s = RES_DICT.GOLD_HOME_BG_NAME, scale9 = true, size = cc.size(350, 120), tag = 359 })
        display.commonLabelParams(nameLabel, fontWithColor(14,{text = '', fontSize = 40, color = '#ffffff'}))
        nameLayout:addChild(nameLabel)
        return {
			view            = view ,
			bgImage         = bgImage,
			bottomImage     = bottomImage,
			leftTimeDecr    = leftTimeDecr,
			nameLayout      = nameLayout,
			nameImage       = nameImage,
			upgradeBtn      = upgradeBtn,
			levelBgImage    = levelBgImage,
			levelLabel      = levelLabel,
			Image_20        = Image_20,
			theirBusiness   = theirBusiness,
			lineImage       = lineImage,
			moduleBtns      = moduleBtns,
			nameLabel       = nameLabel,
			topLayout       = topLayout,
			backBtn         = backBtn,
			purchaseNodes   = purchaseNodes,
			imageTable      = imageTable,
			bgGoodImage     = bgGoodImage,
			tabNameLabelPos = cc.p(tabNameLabel:getPosition()),
			tabNameLabel    = tabNameLabel
        }
    end
    local colorLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    colorLayer:setTouchEnabled(true)
    colorLayer:setContentSize(display.size)
    colorLayer:setAnchorPoint(cc.p(0.5, 0.5))
    colorLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(colorLayer, -10)
    self.viewData = CreateView()
    self.viewData.tabNameLabel:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
    self.viewData.tabNameLabel:runAction( action )
end
function BlackGoldHomeScene:CreateAvatorSkinId()
	if app.blackGoldMgr:GetIsTrade() then
		if not self.viewData.skinId then
			local skinNode =  require('common.CardSkinDrawNode').new({skinId = "251390", coordinateType = COORDINATE_TYPE_HOME})
			skinNode:setAnchorPoint(display.LEFT_CENTER)
			skinNode:setPosition(-350, display.cy-120)
			self.viewData.view:addChild(skinNode)
			skinNode:setScale(1.5)
		end
	end
end

function BlackGoldHomeScene:CreateBusinessEffectView(sender , currentLevel)
	local pos = cc.p(sender:getPosition())
	local parentNode = sender:getParent()
	-- 左边转化
	local worldPos =  parentNode:convertToWorldSpace(pos)
	local nodePos = self:convertToNodeSpace(worldPos)
	local listLayoutSize = cc.size(368, 504)
	local listLayout = display.newLayer(nodePos.x +10, nodePos.y - 35 , { size  = listLayoutSize , ap = display.CENTER_TOP  })
	local view = display.newLayer(display.cx , display.cy , {size = display.size , ap = display.CENTER })
	local hornTip = display.newImageView(RES_DICT.COMMON_BG_TIPS_HORN ,listLayoutSize.width /2, listLayoutSize.height-13 , {ap = display.CENTER_BOTTOM} )
	listLayout:addChild(hornTip,2)
	listLayout:setScaleY(0)
	self:addChild(view , 10 )

	local closeLayer = display.newButton(display.cx , display.cy , {size = display.size , enable = true })
	view:addChild(closeLayer)

	local listBgImage = display.newImageView(RES_DICT.GOLD_HOME_BG_NAME_LIST ,listLayoutSize.width/2 ,listLayoutSize.height/2 )
	listLayout:addChild(listBgImage)
	view:addChild(listLayout)

	local listSize = cc.size(348 ,480 )
	local listView = CListView:create(listSize)
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setAnchorPoint(display.CENTER)
	listView:setPosition(listLayoutSize.width/2 ,listLayoutSize.height/2)
	listLayout:addChild(listView)
	local listCellSize = cc.size(348 ,80 )
	local titleConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.TITLE , 'commerce')
	local count = table.nums(titleConf)
	for i =1 , count do
		local conf =  titleConf[tostring(i)]
		local name = conf.name
		local descr = conf.descr
		local layout = CLayout:create(listCellSize)
		local color1 = "#9c9791"
		local color2 = "#9c9791"
		local color3 = "#9c9791"
		if currentLevel == i  then
			color1 = "#FFFFFFF"
			color2 = "#64422b"
			color3 = "#b58564"
			local listLevelImage = display.newImageView(RES_DICT.GOLD_HOME_BG_NAME_LIST_LEVEL , listCellSize.width/2 ,listCellSize.height/2)
			layout:addChild(listLevelImage)
			local icoNameImage = display.newImageView(RES_DICT.GOLD_HOME_ICO_NAME_LIST_LEVEL , 40 ,listCellSize.height/2 )
			layout:addChild(icoNameImage)
		end
		local lineImage = display.newImageView(RES_DICT.GOLD_HOME_LINE_NAME_LIST_LEVEL , listCellSize.width/2  , 2, {scale9 = true, size = cc.size(313, 2)})
		layout:addChild(lineImage)
		local levelLabel = display.newLabel(40 ,listCellSize.height/2  , fontWithColor(14, {fontSize = 22 , color = color1, outline =false ,   text = i }))
		layout:addChild(levelLabel)
		local titleLabel = display.newLabel(listCellSize.width/2 , listCellSize.height/2 + 15 , {fontSize = 22 , color = color2, text = name})
		layout:addChild(titleLabel)
		local effectLabel = display.newLabel(listCellSize.width/2 , listCellSize.height/2 - 15 , {w = 310 , hAlign =  display.TAC,  fontSize = 20 , color = color3, text = descr})
		layout:addChild(effectLabel)
		listView:insertNodeAtLast(layout)
	end
	listView:reloadData()
	if count >6  then
		listView:setBounceable(true)
	else
		listView:setBounceable(false)
	end
	listView:setCascadeOpacityEnabled(true)
	listLayout:setOpacity(0)
	listLayout:runAction(
		cc.Sequence:create(
			cc.Spawn:create(
				cc.FadeIn:create(0.4),
				cc.Sequence:create(
					cc.ScaleTo:create(0.2, 1,1.02),
					cc.ScaleTo:create(0.1, 1,0.98),
					cc.ScaleTo:create(0.1, 1,1)
				)
			),
			cc.CallFunc:create(function()
				display.commonUIParams(closeLayer , { cb = function()
					view:stopAllActions()
					view:removeFromParent()
				end})
			end)
		)
	)
end

function BlackGoldHomeScene:UpdateNum(times)
	local imageTable =  self.viewData.imageTable
	for i = 1 , #times do
		local image = imageTable[i]
		local timeLabel = image:getChildByTag(1)
		timeLabel:setString(times[i])
	end
end

function BlackGoldHomeScene:EnterAction()
	local viewData = self.viewData
	viewData.bgImage:setVisible(true)
	viewData.bgImage:setOpacity(0)
	viewData.bottomImage:setOpacity(0)
	viewData.bottomImage:setVisible(true)
	viewData.nameLayout:setVisible(true)
	viewData.nameLayout:setOpacity(0)
	local nameLayout = viewData.nameLayout
	local spineTable = {
		cc.FadeIn:create(0.3),
		cc.TargetedAction:create(viewData.bottomImage , cc.FadeIn:create(0.3)  )
	}
	if app.blackGoldMgr:GetIsTrade() then
		spineTable[#spineTable+1] = cc.TargetedAction:create(viewData.bgGoodImage , cc.FadeIn:create(0.3)  )
	end
	viewData.bgImage:runAction(
		cc.Spawn:create(
			cc.Sequence:create(
				cc.Spawn:create(
						spineTable
				),
				cc.DelayTime:create(0.5),
				cc.CallFunc:create(
					function()
						self:CreateAvatorSkinId()
					end
				)
			),
			cc.TargetedAction:create(nameLayout ,
				cc.Sequence:create(
					cc.DelayTime:create(0.3),
					cc.Spawn:create(
						cc.FadeIn:create(0.5)
					)
				)
			)
		)
	)
	self:ShenIdleAction()
end

function BlackGoldHomeScene:ShenIdleAction()
	local image = self.viewData.Image_20
	image:runAction(
		cc.RepeatForever:create(
			cc.Sequence:create(
				cc.EaseSineOut:create(
					cc.RotateTo:create(2, -2.5)),
				cc.EaseSineIn:create(
					cc.RotateTo:create(2, 0)
				),
				cc.EaseSineOut:create(
					cc.RotateTo:create(2, 2.5)
				),
				cc.EaseSineIn:create(
					cc.RotateTo:create(2, 0)
				)
			)
		)
	)
end
function BlackGoldHomeScene:UpgradeLevelAction()
	local image = self.viewData.Image_20
	if app.blackGoldMgr:GetTitleGrade() % 2 ~= 0  then
		return
	end

	image:stopAllActions()
	image:setRotation(0)
	local flag2 = self.viewData.nameLayout:getChildByTag(10001)
	local index =  math.floor( app.blackGoldMgr:GetTitleGrade()/2)
	index = index > 0 and index or 1
	local path = _res(string.format('ui/home/blackShop/gold_home_bg_name_qi%d.png', index ) )

	if not  flag2 then
		flag2 = display.newImageView(path , 0 , 500 , {ap = display.LEFT_BOTTOM})
		self.viewData.nameLayout:addChild(flag2,2)
	end
	flag2:setOpacity(0)
	flag2:setPosition(0 , 313 )
	image:runAction(
		cc.Spawn:create(
			cc.Sequence:create(
				cc.EaseSineOut:create(
					cc.MoveTo:create(0.5, cc.p(472,  480))
				) ,
				cc.DelayTime:create(0.1),
				cc.EaseSineIn:create(
					cc.MoveTo:create(0.5, cc.p(472, 550))
				)
			),
			cc.TargetedAction:create(
				flag2 ,
				cc.Sequence:create(
					cc.DelayTime:create((13+7)/30),
					cc.Sequence:create(
						cc.Spawn:create(
							cc.Sequence:create(
								cc.FadeIn:create(10/30) ,
								cc.DelayTime:create(7/30)
							),
							cc.Sequence:create(
								cc.EaseSineIn:create(cc.MoveTo:create(12/30 , cc.p(0,0))),
								cc.EaseSineOut:create(cc.MoveTo:create(3/30 , cc.p(0,10))),
								cc.EaseSineIn:create(cc.MoveTo:create(2/30 , cc.p(0,0))),
								cc.CallFunc:create(
									function()
										flag2:setOpacity(0)
										self.viewData.nameImage:setTexture(path)
										self:ShenIdleAction()
									end
								)
							)
						)
					)
				)
			)
		)
	)
end

function BlackGoldHomeScene:AddMaxLevelSpine()
	local shareSpineCache = SpineCache(SpineCacheName.BLACK_GOLD)
	local rudder = shareSpineCache:createWithName(app.blackGoldMgr.spineTable.GOLD_HOME_RUDDER)
	rudder:setName("tradeParper")
	self.viewData.levelBgImage:addChild(rudder)
	rudder:setAnchorPoint(display.LEFT_BOTTOM)
	rudder:setPosition(90,100)
	rudder:setAnimation(0, 'idle1' , true )

	local shareSpineCache = SpineCache(SpineCacheName.BLACK_GOLD)
	local rudder = shareSpineCache:createWithName(app.blackGoldMgr.spineTable.GOLD_HOME_RUDDER)
	rudder:setName("tradeParper")
	self.viewData.nameLabel:addChild(rudder)
	rudder:setAnchorPoint(display.LEFT_BOTTOM)
	rudder:setPosition(170,70)
	rudder:setAnimation(0, 'idle2' , true )
end
function BlackGoldHomeScene:UpdateModuleBtnPos()
	local tagTable = {
		1004, -- 投资营收
		1005, -- 港口贸易
		1006, -- 本期货物
	}
	local moduleBtns = self.viewData.moduleBtns
	if app.blackGoldMgr:GetIsTrade() then
		local posTable = {
			cc.p(display.SAFE_R - 343 - 200 , 37),
			cc.p(display.SAFE_R - 343  ,37),
			cc.p(display.SAFE_R - 343+200  ,37)
		}
		for i = 1, table.nums(moduleBtns) do
			moduleBtns[tostring(tagTable[i]) ]:setPosition(posTable[i].x , posTable[i].y)
		end
	else
		local posTable = {
			cc.p(display.SAFE_R - 343 - 100 , 37),
			cc.p(display.SAFE_R - 343 + 100  ,37 ),
			cc.p(display.SAFE_R - 343+200  ,37 )
		}
		for i = 1, table.nums(moduleBtns) do
			moduleBtns[tostring(tagTable[i])]:setPosition(posTable[i].x , posTable[i].y)
		end
		moduleBtns[tostring(tagTable[3])]:setVisible(false)
	end
end

function BlackGoldHomeScene:NameLayoutEnterAction()
	self:runAction(
			cc.TargetedAction:create(
					self.viewData.nameLayout ,
					cc.Spawn:create(
					--cc.JumpTo:create(0.4 , cc.p(display.SAFE_R - 343, display.height + 400) , 20 ,1 ),
							cc.FadeIn:create(0.4)
					)
			)
	)
end
function BlackGoldHomeScene:NameLayoutEnterOut()
	self:runAction(
		cc.TargetedAction:create(
			self.viewData.nameLayout ,
			cc.Spawn:create(
				--cc.JumpTo:create(0.4 , cc.p(display.SAFE_R - 343, display.height + 400) , 20 ,1 ),
				cc.FadeOut:create(0.4)
			)
		)
	)
end
function BlackGoldHomeScene:ModuleBtnEnterAction()
	local moduleBtns = self.viewData.moduleBtns
	local posTable = {}
	self.viewData.bgImage:stopAllActions()
	local tagTable = {
		 1004, -- 投资营收
		 1005, -- 港口贸易
		 1006, -- 本期货物
	}
	if app.blackGoldMgr:GetIsTrade() then
		posTable = {
			cc.p(display.SAFE_R - 343 - 200 , 37),
			cc.p(display.SAFE_R - 343  ,37 ),
			cc.p(display.SAFE_R - 343+200  ,37 ),
		}
		local SpawnTable = {}
		for i = 1, table.nums(moduleBtns) do
			--moduleBtns[tostring(tagTable[i]) ]:setPosition(posTable[i].x , posTable[i].y - 200)
			moduleBtns[tostring(tagTable[i])]:setOpacity(0)
			SpawnTable[#SpawnTable+1] = cc.TargetedAction:create(
				moduleBtns[tostring(tagTable[i])] ,
				cc.Spawn:create(
					cc.JumpTo:create(0.4, posTable[i] , 10, 1) ,
					cc.FadeIn:create(0.4)
				)
			)
		end
		self.viewData.bgImage:runAction(cc.Spawn:create(SpawnTable))
	else
		posTable = {
			cc.p(display.SAFE_R - 343 - 100 , 37),
			cc.p(display.SAFE_R - 343 + 100  ,37 ),
			cc.p(display.SAFE_R - 343+200  ,37 ),
		}
		local SpawnTable = {}
		for i = 1, table.nums(moduleBtns) do
			moduleBtns[tostring(tagTable[i])]:setPosition(posTable[i].x , posTable[i].y )
			SpawnTable[#SpawnTable+1] = cc.TargetedAction:create(
				moduleBtns[tostring(tagTable[i])] ,
				cc.Spawn:create(

					--cc.JumpTo:create(0.4, posTable[i] , -20, 1) ,
					cc.FadeIn:create(0.4)
				)
			)

		end
		moduleBtns[tostring(tagTable[3])]:setVisible(false)
		self.viewData.bgImage:runAction(cc.Spawn:create(SpawnTable))
	end
end

function BlackGoldHomeScene:ModuleBtnOutAction()
	local moduleBtns = self.viewData.moduleBtns
	local posTable = {}
	self.viewData.bgImage:stopAllActions()
	local tagTable = {
		 1004, -- 投资营收
		 1005, -- 港口贸易
		 1006, -- 本期货物
	}
	if app.blackGoldMgr:GetIsTrade() then
		posTable = {
			cc.p(display.SAFE_R - 343 - 200 , -37),
			cc.p(display.SAFE_R - 343  ,-37 ),
			cc.p(display.SAFE_R - 343+200  ,-37 ),
		}
		local SpawnTable = {}

		for i = 1,table.nums(moduleBtns) do
			moduleBtns[tostring(tagTable[i])]:setOpacity(0)
			SpawnTable[#SpawnTable+1] = cc.TargetedAction:create(
					moduleBtns[tostring(tagTable[i])] ,
					cc.Spawn:create(
							--cc.JumpTo:create(1, posTable[i] , -20, 1) ,
							cc.FadeOut:create(0.4)
					)
			)
		end
		self.viewData.bgImage:runAction(cc.Spawn:create(SpawnTable))
	else
		posTable = {
			cc.p(display.SAFE_R - 343 - 100 , -137),
			cc.p(display.SAFE_R - 343 + 100  ,-137 ),
			cc.p(display.SAFE_R - 343+200  ,-137 )
		}
		local spawnTable = {}
		for i = 1, table.nums(moduleBtns) do
			spawnTable[#spawnTable+1] = cc.TargetedAction:create(
					moduleBtns[tostring(tagTable[i])] ,
					cc.Spawn:create(
						--cc.JumpTo:create(0.4, posTable[i] , -20, 1),
						--cc.MoveTo:create(1, cc.p(50,50)),
						cc.FadeOut:create(0.4)
					)
			)
		end
		moduleBtns[tostring(tagTable[3])]:setVisible(false)
		local spawnAction = cc.Spawn:create(spawnTable)
		self.viewData.bgImage:runAction(spawnAction)
	end
end
function BlackGoldHomeScene:CheckTradeUnlock()
	local grade = app.blackGoldMgr:GetTitleGrade()
	local titleConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.TITLE , 'commerce')
	local unlock = (checkint(titleConf[tostring(grade)].unlockMarket) > 0 and true ) or false
	local moduleBtn = self.viewData.moduleBtns[tostring(BUTTON_TAG.PORT_TRADE)]
	local titleImage = moduleBtn:getChildByName("titleImage")
	if unlock then
		titleImage:setTexture(RES_DICT.GOLD_HOME_BTN_TOUZI)
	else
		titleImage:setTexture(RES_DICT.GOLD_HOME_BTN_MAOYI_GREY)
	end
end
function BlackGoldHomeScene:UpdateBuissnessTitle(name)
	local nameLabel = self.viewData.nameLabel
	display.commonLabelParams(nameLabel , {text = name })
end
function BlackGoldHomeScene:UpdateFlagImage()
	local nameImage = self.viewData.nameImage
	local index =  math.floor( app.blackGoldMgr:GetTitleGrade()/2)
	index = index > 0 and index or 1
	nameImage:setTexture(_res(string.format('ui/home/blackShop/gold_home_bg_name_qi%d.png',index ) ))
end
function BlackGoldHomeScene:UpdateBgImage()
	local bgPath = app.blackGoldMgr:GetIsTrade() and RES_DICT.GOLD_HOME_BG or RES_DICT.GOLD_HOME_BG_LEAVE
	self.viewData.bgImage:setTexture(bgPath)
	self.viewData.bottomImage:setVisible(app.blackGoldMgr:GetIsTrade())
end

function BlackGoldHomeScene:UpdateBlackStatus()
	if app.blackGoldMgr:GetIsTrade() then
		display.commonLabelParams(self.viewData.leftTimeDecr , {text = __('离港倒计时:')})
	else
		display.commonLabelParams(self.viewData.leftTimeDecr , {text = __('返港倒计时')})
	end
end
function BlackGoldHomeScene:UpdateBuissnessLevel(name)
	local levelLabel = self.viewData.levelLabel
	local levelBgImage = self.viewData.levelBgImage
	display.commonLabelParams(levelLabel , {text = name })
	if name == "MAX" then
		levelBgImage:setTexture(RES_DICT.GOLD_HOME_BTN_MAX)
	end
end

function BlackGoldHomeScene:onCleanup()

end

return BlackGoldHomeScene