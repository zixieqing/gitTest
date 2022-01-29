---@class BlackGoldUpgradeView
local BlackGoldUpgradeView = class('BlackGoldUpgradeView', function()
	local layout = CLayout:create(display.size)
	return layout
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newNSprite = display.newNSprite
local newButton = display.newButton
local newLayer = display.newLayer

---@type CommerceConfigParser
local CommerceConfigParser = require("Game.Datas.Parser.CommerceConfigParser")

local RES_DICT = {
	COMMON_BG_LIST_UNSELECTED     = _res('ui/common/common_bg_list_unselected.png'),
	GOODS_ICON_890010             = _res('arts/goods/goods_icon_890010.png'),
	COMMON_BG_1                   = _res('ui/common/common_bg_1.png'),
	GOLD_HOME_UP_KUANG            = _res('ui/home/blackShop/gold_home_up_kuang.png'),
	KITCHEN_TOOL_SPLIT_LINE       = _res('ui/home/blackShop/kitchen_tool_split_line.png'),
	COMMON_BTN_ORANGE             = _res('ui/common/common_btn_orange.png'),
	GOLD_HOME_UP_JIAN             = _res('ui/home/blackShop/gold_home_up_jian.png'),
	GOLD_HOME_UP_NAME_BG          = _res('ui/home/blackShop/gold_home_up_name_bg.png'),
	COMMON_BG_TITLE_2             = _res('ui/common/common_bg_title_2.png'),
	COMMON_TITLE_5                = _res('ui/common/common_title_5.png'),
}
function BlackGoldUpgradeView:ctor(params )
	self:InitUI()
	self:RegistObserver()
end

function BlackGoldUpgradeView:ProcessSignal( signal )
	local name = signal:GetName()
	if name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
		self:UpdateViewByLevel(app.blackGoldMgr:GetTitleGrade())
	end
end

function BlackGoldUpgradeView:InitUI(  )
	local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})
	local contentLayer = newLayer(display.cx , display.cy  ,
			{ ap = display.CENTER, size = cc.size(626, 674) })
	view:addChild(contentLayer)
	self:addChild(view)

	local closeBtn = display.newLayer(display.cx , display.cy , { ap = display.CENTER , color = cc.c4b(0,0,0,175), size = display.size , enable = true  , cb = function()
		self:OnUnRegist()
	end})
	self:addChild(closeBtn,-1)


	local gbgImage = newImageView(RES_DICT.COMMON_BG_1, 313, 674/2,
			{ ap = display.CENTER, tag = 72, enable = false })
	contentLayer:addChild(gbgImage)

	local swallowLayer = display.newLayer(0,0 , { color = cc.c4b(0,0,0,0) ,  enable = true ,size = cc.size(626, 773)} )
	contentLayer:addChild(swallowLayer)
	local titleBtn = newButton(315, 634, { ap = display.CENTER ,  n = RES_DICT.COMMON_BG_TITLE_2, d = RES_DICT.COMMON_BG_TITLE_2, s = RES_DICT.COMMON_BG_TITLE_2, scale9 = true, size = cc.size(256, 36), tag = 325 })
	display.commonLabelParams(titleBtn, fontWithColor(14,{text = __('称号升级'), fontSize = 24, color = '#ffffff'}))
	contentLayer:addChild(titleBtn)

	local upgradeTitleLayout = newLayer(313, 516,
			{ ap = display.CENTER,  size = cc.size(594, 116) })
	contentLayer:addChild(upgradeTitleLayout)

	local titleBgImage = newImageView(RES_DICT.GOLD_HOME_UP_NAME_BG, 0, 0,
			{ ap = display.LEFT_BOTTOM, tag = 327, enable = false })
	upgradeTitleLayout:addChild(titleBgImage)

	local currentTitle = newLabel(260 , 71,
			fontWithColor(14,{ ap = display.RIGHT_CENTER, color = '#ffffff', text = "", fontSize = 30, tag = 329 }))
	upgradeTitleLayout:addChild(currentTitle)

	local nextTitle = newLabel(335, 71,
			fontWithColor(14,{ ap = display.LEFT_CENTER, color = '#ffc868',outline = "#362c22", text = "", fontSize = 30, tag = 330 }))
	upgradeTitleLayout:addChild(nextTitle)

	local currentEffect = newLabel(260, 31,
			{ ap = display.RIGHT_CENTER, color = '#ffffff', w = 220,  hAlign = display.TAR ,  text = "", fontSize = 18, tag = 332 })
	upgradeTitleLayout:addChild(currentEffect)

	local nextEffect = newLabel(339, 31,
			{ ap = display.LEFT_CENTER, color = '#ffc868',w = 220, text = "", fontSize = 18, tag = 333 })
	upgradeTitleLayout:addChild(nextEffect)

	local upgradeImage = newImageView(RES_DICT.GOLD_HOME_UP_JIAN, 296, 71,
			{ ap = display.CENTER, tag = 331, enable = false })
	upgradeTitleLayout:addChild(upgradeImage)

	local lineImage = newImageView(RES_DICT.KITCHEN_TOOL_SPLIT_LINE, 295, -24,
			{ ap = display.CENTER, tag = 334, enable = false })
	upgradeTitleLayout:addChild(lineImage)

	local upgradeLayout = newLayer(313, 300,
			{ ap = display.CENTER, size = cc.size(520, 255)})
	contentLayer:addChild(upgradeLayout)

	local unselectImage = newImageView(RES_DICT.COMMON_BG_LIST_UNSELECTED, 260, 127,
			{ ap = display.CENTER, tag = 336, enable = false, scale9 = true, size = cc.size(525, 255) })
	upgradeLayout:addChild(unselectImage)

	local upgradeMaterial = newButton(263, 224, { ap = display.CENTER ,  n = RES_DICT.COMMON_TITLE_5, d = RES_DICT.COMMON_TITLE_5, s = RES_DICT.COMMON_TITLE_5, scale9 = true, size = cc.size(186, 31), tag = 337 })
	display.commonLabelParams(upgradeMaterial, {text = __('升级材料'), fontSize = 20, color = '#414146'})
	upgradeLayout:addChild(upgradeMaterial)

	local goldBgImage = newNSprite(RES_DICT.GOLD_HOME_UP_KUANG, 114, 40,
			{ ap = display.CENTER, tag = 338 })
	goldBgImage:setScale(1, 1)
	upgradeLayout:addChild(goldBgImage)

	local goldImage = newNSprite(RES_DICT.GOODS_ICON_890010, 1, 20,
			{ ap = display.CENTER, tag = 339 })
	goldImage:setScale(0.25, 0.25)
	goldBgImage:addChild(goldImage)

	local goldNum = newLabel(180, 17,
			fontWithColor(14,{ ap = display.RIGHT_CENTER, color = '#ffffff', text = "",  tag = 340 }))
	goldBgImage:addChild(goldNum)

	local fameBgImage = newNSprite(RES_DICT.GOLD_HOME_UP_KUANG, 410, 40,
			{ ap = display.CENTER, tag = 341 })
	fameBgImage:setScale(1, 1)
	upgradeLayout:addChild(fameBgImage)

	local fameImage = newNSprite(RES_DICT.GOODS_ICON_890010, 1, 20,
			{ ap = display.CENTER, tag = 342 })
	fameImage:setScale(0.25, 0.25)
	fameBgImage:addChild(fameImage)

	local fameNum = newLabel(180, 17,
			fontWithColor(14,{ ap = display.RIGHT_CENTER, color = '#ffffff', text = "", fontSize = 20, tag = 343 }))
	fameBgImage:addChild(fameNum)

	local upgradeBtn = newButton(313, 113, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_ORANGE, d = RES_DICT.COMMON_BTN_ORANGE, s = RES_DICT.COMMON_BTN_ORANGE, scale9 = true, size = cc.size(123, 62), tag = 344 })
	display.commonLabelParams(upgradeBtn, fontWithColor(14,{text = __('升级'), fontSize = 24, color = '#ffffff'}))
	contentLayer:addChild(upgradeBtn)
	display.commonUIParams(upgradeBtn , { cb = handler(self, self.UpgradeClick)})
	local goodNodes = {}
	self.viewData =  {
		contentLayer            = contentLayer,
		gbgImage                = gbgImage,
		titleBtn                = titleBtn,
		upgradeTitleLayout      = upgradeTitleLayout,
		titleBgImage            = titleBgImage,
		currentTitle            = currentTitle,
		nextTitle               = nextTitle,
		currentEffect           = currentEffect,
		nextEffect              = nextEffect,
		upgradeImage            = upgradeImage,
		lineImage               = lineImage,
		upgradeLayout           = upgradeLayout,
		unselectImage           = unselectImage,
		upgradeMaterial         = upgradeMaterial,
		goldBgImage             = goldBgImage,
		goldImage               = goldImage,
		goldNum                 = goldNum,
		fameBgImage             = fameBgImage,
		fameImage               = fameImage,
		fameNum                 = fameNum,
		upgradeBtn              = upgradeBtn,
		goodNodes               = goodNodes,
	}
end

function BlackGoldUpgradeView:UpdateViewByLevel(level)
	self.currentLevel = level
	local viewData = self.viewData
	local titleConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.TITLE , 'commerce')
	local count = table.nums(titleConf)
	local nextLevel = level + 1
	if checkint(level)  == count then -- 到达最大等级
		AppFacade.GetInstance():UnRegistObserver(POST.COMMERCE_TITLE_UPGRADE.sglName, self)
		self:runAction(cc.RemoveSelf:create())
	else
		local currentName    = titleConf[tostring(level)].name
		local currentDescr   = titleConf[tostring(level)].descr
		local nextName     = titleConf[tostring(nextLevel)].name
		local nextLevelDescr = titleConf[tostring(nextLevel)].descr
		display.commonLabelParams(viewData.currentTitle, {text = currentName})
		display.commonLabelParams(viewData.nextTitle, {text = nextName})
		display.commonLabelParams(viewData.currentEffect, {text = currentDescr})
		display.commonLabelParams(viewData.nextEffect, {text = nextLevelDescr})
		-- 删除旧的goodNode
		for i = 1, #viewData.goodNodes do
			viewData.goodNodes[i]:removeFromParent()
		end
		local consume = titleConf[tostring(nextLevel)].consume
		local consumeData = {}
		for i, v in pairs(consume) do
			consumeData[#consumeData+1] = {goodsId = i , num = v }
		end
		local width = 125
		local equinoctial = (#consumeData)/2
		for i = 1, #consumeData do
			local goodNode = require("common.GoodNode").new(consumeData[i])
			goodNode:setPosition(260 + ((i - 0.5 ) -equinoctial) * width , 135)
			viewData.upgradeLayout:addChild(goodNode,20)
			display.commonUIParams(goodNode , {cb = function(sender)
				app.uiMgr:AddDialog("common.GainPopup", {goodId =consumeData[i].goodsId})
			end})

			local ownerNum = CommonUtils.GetCacheProductNum(consumeData[i].goodsId)
			local needNum = consumeData[i].num
			local data = {}
			if checkint(needNum )> checkint(ownerNum)  then
				data = {
					fontWithColor(14 , { outline = false , text = ownerNum ,  color = "#ffc868" ,fontSize = 20  })    ,
					fontWithColor(	14 , { outline = false , text = "/" ..  needNum , color = "#FFFFFF" ,fontSize = 20  })
				}
			else
				data = {
					fontWithColor(	14 ,{ text = ownerNum .. "/" ..  needNum , color = "#FFFFFF" , fontSize = 20   })
				}
			end
			local richLabel = display.newRichLabel(55 , 20, { c = data  , r = true })
			goodNode:addChild(richLabel ,20 )
		end

		local goldPath = CommonUtils.GetGoodsIconPathById(GOLD_ID)
		--local goldNum  = CommonUtils.GetCacheProductNum(GOLD_ID)

		local reputationPath = CommonUtils.GetGoodsIconPathById(REPUTATION_ID)
		local reputationNum  = CommonUtils.GetCacheProductNum(REPUTATION_ID)
		viewData.goldImage:setTexture(goldPath)
		viewData.fameImage:setTexture(reputationPath)
		display.commonLabelParams(viewData.fameNum , fontWithColor(14, {text = reputationNum  .. "/" .. titleConf[tostring(nextLevel)].reputation }))
		display.commonLabelParams(viewData.goldNum , fontWithColor(14, {text = titleConf[tostring(nextLevel)].gold }))
	end
end

function BlackGoldUpgradeView:UpgradeClick()
	local nextLevel = self.currentLevel +1
	local titleConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.TITLE , 'commerce')
	local goldNum = CommonUtils.GetCacheProductNum(GOLD_ID)
	local upgradeTitleConf  = titleConf[tostring(nextLevel)]
	if checkint(goldNum)  <  checkint(upgradeTitleConf.gold) then
		app.uiMgr:ShowInformationTips(__('金币不足!!!'))
		return
	end
	local reputationNum = CommonUtils.GetCacheProductNum(REPUTATION_ID)
	if checkint(reputationNum)  <  checkint(upgradeTitleConf.reputation) then
		app.uiMgr:ShowInformationTips(__('商团声望不足'))
		return
	end

	for i, v in pairs(upgradeTitleConf.consume) do
		local num = CommonUtils.GetCacheProductNum(i)
		if checkint(num) < checkint(v) then
			app.uiMgr:ShowInformationTips(__('材料不足'))
			return
		end
	end
	AppFacade.GetInstance():DispatchSignal(POST.COMMERCE_TITLE_UPGRADE.cmdName , {titleGrade = nextLevel })
	self:OnUnRegist()
end

function BlackGoldUpgradeView:RegistObserver()
	AppFacade.GetInstance():RegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, mvc.Observer.new(self.ProcessSignal , self) )
end

function BlackGoldUpgradeView:OnUnRegist()
	AppFacade.GetInstance():UnRegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT , self)
	self:stopAllActions()
	self:removeFromParent()
end
function BlackGoldUpgradeView:onClean()


end
return BlackGoldUpgradeView
