---@class BlackGoldUpgradeBackpackView
local BlackGoldUpgradeBackpackView = class('BlackGoldUpgradeBackpackView', function()
	local layout = CLayout:create(display.size)
	return layout
end)
local newImageView                 = display.newImageView
local newLabel                     = display.newLabel
local newNSprite                   = display.newNSprite
local newButton                    = display.newButton
local newLayer                     = display.newLayer

---@type CommerceConfigParser
local CommerceConfigParser         = require("Game.Datas.Parser.CommerceConfigParser")
local RES_DICT                     = {
	GOODS_ICON_890010         = _res('arts/goods/goods_icon_890010.png'),
	COMMON_BG_1               = _res('ui/common/common_bg_7.png'),
	GOLD_HOME_UP_KUANG        = _res('ui/home/blackShop/gold_home_up_kuang.png'),
	KITCHEN_TOOL_SPLIT_LINE   = _res('ui/home/blackShop/kitchen_tool_split_line.png'),
	COMMON_BTN_ORANGE         = _res('ui/common/common_btn_orange.png'),
	GOLD_HOME_UP_JIAN         = _res('ui/home/blackShop/gold_home_up_jian.png'),
	COMMON_BG_LIST_UNSELECTED = _res('ui/common/common_bg_list_unselected.png'),
	GOLD_HOME_UP_NAME_BG      = _res('ui/home/blackShop/gold_home_up_name_bg.png'),
	COMMON_BG_TITLE_2         = _res('ui/common/common_bg_title_2.png'),
	COMMON_TITLE_5            = _res('ui/common/common_title_5.png'),
}
function BlackGoldUpgradeBackpackView:ctor(params)
	self:InitUI()
	self:RegistObserver()
	self:UpdateViewByLevel(app.blackGoldMgr:GetWarehouseGrade())
end
function BlackGoldUpgradeBackpackView:ProcessSignal( signal )
	local name = signal:GetName()
	if name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
		self:UpdateViewByLevel(app.blackGoldMgr:GetWarehouseGrade())
	end
end
function BlackGoldUpgradeBackpackView:InitUI()
	local contentSize  = cc.size(558, 539)
	local view         = newLayer(display.cx, display.cy, { ap = display.CENTER, size = display.size })
	local contentLayer = newLayer(display.cx, display.cy + 40,
			{ ap = display.CENTER, size = contentSize })
	view:addChild(contentLayer)
	self:addChild(view)

	local closeBtn = display.newLayer(display.cx, display.cy, { ap = display.CENTER, color = cc.c4b(0, 0, 0, 175), size = display.size, enable = true, cb = function()
		self:OnUnRegist()
	end })
	self:addChild(closeBtn, -1)

	local gbgImage = newImageView(RES_DICT.COMMON_BG_1, contentSize.width / 2, contentSize.height / 2,
			{ ap = display.CENTER, tag = 72, enable = false })
	contentLayer:addChild(gbgImage)

	local swallowLayer = display.newLayer(0, 0, { color = cc.c4b(0, 0, 0, 0), enable = true, size = cc.size(626, 773) })
	contentLayer:addChild(swallowLayer)
	local titleBtn = newButton(contentSize.width / 2, contentSize.height - 2, { ap = display.CENTER_TOP, n = RES_DICT.COMMON_BG_TITLE_2, d = RES_DICT.COMMON_BG_TITLE_2, s = RES_DICT.COMMON_BG_TITLE_2, scale9 = true, size = cc.size(256, 36), tag = 325 })
	display.commonLabelParams(titleBtn, { text = __('仓储扩充'), fontSize = 24, color = '#ffffff' })
	contentLayer:addChild(titleBtn)

	local upgradeLayoutSize = cc.size(520, 255)
	local upgradeLayout     = newLayer(contentSize.width / 2, contentSize.height / 2 + 25,
			{ ap = display.CENTER, size = upgradeLayoutSize })
	contentLayer:addChild(upgradeLayout)

	local unselectImage = newImageView(RES_DICT.COMMON_BG_LIST_UNSELECTED, upgradeLayoutSize.width / 2, 127,
			{ ap = display.CENTER, tag = 336, enable = false, scale9 = true, size = cc.size(500, 255) })
	upgradeLayout:addChild(unselectImage)

	local upgradeMaterial = newButton(upgradeLayoutSize.width / 2, 224, { ap = display.CENTER, n = RES_DICT.COMMON_TITLE_5, d = RES_DICT.COMMON_TITLE_5, s = RES_DICT.COMMON_TITLE_5, scale9 = true, size = cc.size(186, 31), tag = 337 })
	display.commonLabelParams(upgradeMaterial, { text = __('升级材料'), fontSize = 20, color = '#6c4a31' })
	upgradeLayout:addChild(upgradeMaterial)

	local fameBgImage = newNSprite(RES_DICT.GOLD_HOME_UP_KUANG, 250, 40,
			{ ap = display.CENTER, tag = 341 })
	fameBgImage:setScale(1, 1)
	upgradeLayout:addChild(fameBgImage)

	local fameImage = newNSprite(RES_DICT.GOODS_ICON_890010, 1, 20,
			{ ap = display.CENTER, tag = 342 })
	fameImage:setScale(0.25, 0.25)
	fameBgImage:addChild(fameImage)
	local fameNum = cc.Label:createWithBMFont('font/common_text_num.fnt', '')--
	fameNum:setAnchorPoint(display.RIGHT_CENTER)
	fameNum:setPosition(cc.p(180, 15))
	fameBgImage:addChild(fameNum)
	fameNum:setScale(0.55)

	local upgradeBtn = newButton(contentSize.width / 2, 50, { ap = display.CENTER, n = RES_DICT.COMMON_BTN_ORANGE, d = RES_DICT.COMMON_BTN_ORANGE, s = RES_DICT.COMMON_BTN_ORANGE, scale9 = true, size = cc.size(123, 62), tag = 344 })
	display.commonLabelParams(upgradeBtn, fontWithColor(14, { text = __('升级'), fontSize = 24, color = '#ffffff' }))
	contentLayer:addChild(upgradeBtn)
	display.commonUIParams(upgradeBtn, { cb = handler(self, self.UpgradeClick) })

	local expandLabel = newLabel(contentSize.width / 2, 135, { ap = display.CENTER, color = '#6c4a31', text = __('仓库扩充等级'), fontSize = 24, tag = 343 })
	contentLayer:addChild(expandLabel)

	local expandNum = newLabel(contentSize.width / 2, contentSize.height - 75, { ap = display.CENTER, color = '#5A5A5A', text = __('仓库扩充等级'), fontSize = 24, tag = 343 })
	contentLayer:addChild(expandNum)

	local expandTimeLabel = display.newRichLabel(contentSize.width/2, 105,
			{
				c = { { ap = display.CENTER, color = '#414146', text = "", fontSize = 24, tag = 343 } }
			})
	contentLayer:addChild(expandTimeLabel)
	local goodNodes = {}
	self.viewData   = {
		contentLayer    = contentLayer,
		gbgImage        = gbgImage,
		titleBtn        = titleBtn,
		upgradeLayout   = upgradeLayout,
		unselectImage   = unselectImage,
		upgradeMaterial = upgradeMaterial,
		fameBgImage     = fameBgImage,
		fameImage       = fameImage,
		expandLabel     = expandLabel,
		expandNum       = expandNum,
		expandTimeLabel = expandTimeLabel,
		fameNum         = fameNum,
		upgradeBtn      = upgradeBtn,
		goodNodes       = goodNodes,
	}
end

function BlackGoldUpgradeBackpackView:UpdateViewByLevel(level)
	self.currentLevel   = level
	local viewData      = self.viewData
	local wareHouseConf = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.WAREHOUSE, 'commerce')
	local count         = table.nums(wareHouseConf)
	local nextLevel     = level + 1
	if checkint(level) == count then
		-- 到达最大等级
		self:OnUnRegist()
	else
		-- 删除旧的goodNode
		for i = 1, #viewData.goodNodes do
			viewData.goodNodes[i]:removeFromParent()
		end
		local consume     = wareHouseConf[tostring(nextLevel)].consume
		local capacity     = wareHouseConf[tostring(nextLevel)].capacity
		local consumeData = {}
		for i, v in pairs(consume) do
			consumeData[#consumeData + 1] = { goodsId = i, num = v }
		end
		local width       = 125
		local equinoctial = (#consumeData) / 2
		for i = 1, #consumeData do
			local goodNode = require("common.GoodNode").new(consumeData[i])
			goodNode:setPosition(260 + ((i - 0.5) - equinoctial) * width, 135)
			viewData.upgradeLayout:addChild(goodNode, 20)
			display.commonUIParams(goodNode, { cb = function(sender)
				app.uiMgr:AddDialog("common.GainPopup", { goodId = consumeData[i].goodsId })
			end })

			local ownerNum = CommonUtils.GetCacheProductNum(consumeData[i].goodsId)
			local needNum  = consumeData[i].num
			local data     = {}
			local scale = 0.25
			if device.platform == 'android' then
				scale = 0.5
			end
			if checkint(needNum) > checkint(ownerNum) then
				local num1 = cc.Label:createWithBMFont('font/common_text_num.fnt', '')--
				num1:setAnchorPoint(display.RIGHT_CENTER)
				num1:setPosition(cc.p(180, 15))
				num1:setColor(ccc3FromInt( "#ffc868"))
				num1:setString(ownerNum)
				local num2 = cc.Label:createWithBMFont('font/common_text_num.fnt', '')--
				num2:setAnchorPoint(display.RIGHT_CENTER)
				num2:setPosition(cc.p(180, 15))
				num2:setColor(ccc3FromInt( "#FFFFFF"))
				num2:setString("/" .. needNum)
				data = {
					{node = num1 , scale = scale},
					{node = num2 , scale = scale}
				}
			else
				local num1 = cc.Label:createWithBMFont('font/common_text_num.fnt', '')--
				num1:setAnchorPoint(display.RIGHT_CENTER)
				num1:setPosition(cc.p(180, 15))
				num1:setColor(ccc3FromInt( "#FFFFFF"))
				num1:setString( ownerNum .. "/" .. needNum)
				data = {
					{node = num1 ,  scale = scale }
				}
			end
			local richLabel = display.newRichLabel(55, 20, { c = data, r = true })
			goodNode:addChild(richLabel, 20)
		end
		local reputationPath = CommonUtils.GetGoodsIconPathById(REPUTATION_ID)
		local reputationNum  = CommonUtils.GetCacheProductNum(REPUTATION_ID)
		viewData.fameImage:setTexture(reputationPath)
		display.reloadRichLabel(viewData.expandTimeLabel , {c = {
			fontWithColor(10 , {text = level , fontSize = 24 }) ,
			fontWithColor(10 , {text = "/" .. count - 1 ,color = "#6c4a31" , fontSize = 24  })
		}})
		display.commonLabelParams(viewData.expandNum , { hAlign = display.TAC  , w = 350 , text = string.fmt(__('本次可扩充至_num_的仓储容量') , { _num_ = capacity })})
		viewData.fameNum:setString(reputationNum .. "/" .. wareHouseConf[tostring(nextLevel)].reputation)
	end
end

function BlackGoldUpgradeBackpackView:UpgradeClick()
	local nextLevel            = self.currentLevel + 1
	local wareHouseConf        = CommonUtils.GetConfigAllMess(CommerceConfigParser.TYPE.WAREHOUSE, 'commerce')
	local count = table.nums(wareHouseConf)
	if nextLevel >  count  then
		app.uiMgr:ShowInformationTips(__('仓库已满级,不能扩容了'))
		return
	end
	local upgradewareHouseConf = wareHouseConf[tostring(nextLevel)]
	local reputationNum        = CommonUtils.GetCacheProductNum(REPUTATION_ID)
	if checkint(reputationNum) < checkint(upgradewareHouseConf.reputation) then
		app.uiMgr:ShowInformationTips(__('商团声望不足'))
		return
	end
	for i, v in pairs(upgradewareHouseConf.consume) do
		local num = CommonUtils.GetCacheProductNum(i)
		if checkint(num) < checkint(v) then
			app.uiMgr:ShowInformationTips(__('材料不足'))
			return
		end
	end
	AppFacade.GetInstance():DispatchSignal(POST.COMMERCE_WARE_HOUSE_EXTEND.cmdName, { warehouseGrade = nextLevel })
	--self:OnUnRegist()
end
function BlackGoldUpgradeBackpackView:RegistObserver()
	AppFacade.GetInstance():RegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, mvc.Observer.new(self.ProcessSignal , self) )
end

function BlackGoldUpgradeBackpackView:OnUnRegist()
	AppFacade.GetInstance():UnRegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT , self)
	self:stopAllActions()
	self:removeFromParent()
end
function BlackGoldUpgradeBackpackView:onClean()


end
return BlackGoldUpgradeBackpackView
