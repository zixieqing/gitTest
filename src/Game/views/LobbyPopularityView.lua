--[[
餐厅信息知名度view
--]]
local LobbyPopularityView = class('LobbyPopularityView', function ()
	local node = CLayout:create(cc.size(753, 556))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.LobbyPopularityView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
	local size = cc.size(753, 556)
	local view = CLayout:create(size)
	local bg = display.newImageView(_res('ui/common/commcon_bg_text.png'), 0, 8, {ap = cc.p(0, 0), scale9 = true, size = cc.size(753, 546)})
	view:addChild(bg)
	--local tipsIcon = display.newButton(25, 526, {n = _res('ui/common/common_btn_tips.png')})
	--view:addChild(tipsIcon, 10)
	local nameLabel = display.newLabel(50, 526, fontWithColor(6, {text = __('当前餐厅规模：'), ap = cc.p(0, 0.5)}))
	view:addChild(nameLabel, 10)
	local rankLabel = display.newLabel(50 + display.getLabelContentSize(nameLabel).width, 526, fontWithColor(11, {text = '', ap = cc.p(0, 0.5)}))
	view:addChild(rankLabel, 10)
	local function CreateBg( x, y, title )
		local layout = CLayout:create(cc.size(753, 186))
		layout:setPosition(cc.p(x, y))
		local bg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_awareness.png'), 0, 0, {ap = cc.p(0, 0), scale9 = true, size = cc.size(753, 186)})
		layout:addChild(bg)
		local titleBg = display.newButton(layout:getContentSize().width/2, 158, {n = _res('ui/common/common_title_5.png'), enable = false , scale9 = true })
		layout:addChild(titleBg)
		display.commonLabelParams(titleBg, fontWithColor(4, {text = title , paddingW = 30 }))
		return layout
	end
	-- 知名度
	local popularityBg = CreateBg(size.width/2, 406, __('知名度'))
	view:addChild(popularityBg, 5)
	local tipsLabel = display.newLabel(size.width/2, 108, fontWithColor(6, {text = __('tips：提升餐厅规模可解锁获得更多餐厅功能，提高更多buff，增加更多餐厅收益。'), w = 700}))
	popularityBg:addChild(tipsLabel, 5)
	local popularityLabel = display.newLabel(60, 50, fontWithColor(4, {ap =display.LEFT_CENTER, text = __('知名度') , w = 120 ,reqW = 120, hAlign = display.TAC }))
	popularityBg:addChild(popularityLabel)
    local expProgressBar = CProgressBar:create(_res('ui/home/lobby/information/restaurant_bar_exp_1.png'))
    expProgressBar:setBackgroundImage(_res('ui/home/lobby/information/setup_bar_exp_2.png'))
    expProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    expProgressBar:setAnchorPoint(display.LEFT_CENTER)
    -- expProgressBar:setMaxValue(tonumber(upgradeDatas.popularity))
    -- expProgressBar:setValue(gameMgr:GetUserInfo().popularity)
    expProgressBar:setPosition(cc.p(60 + 120, 50))
    popularityBg:addChild(expProgressBar, 10)
    local expLabel = display.newLabel(popularityBg:getContentSize().width/2 + 40, 50, fontWithColor(9, {text = ''}))
    popularityBg:addChild(expLabel, 10)
    local popularityIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(POPULARITY_ID)), 15, 50, {ap = cc.p(0, 0.5)})
    popularityBg:addChild(popularityIcon, 10)
    popularityIcon:setScale(0.25)
    -- 升级材料
	local materialBg = CreateBg(size.width/2, 218, __('升级材料'))
	view:addChild(materialBg, 5)
	-- 升级按钮
	local upgradeBtn = display.newButton(size.width/2, 70, {n = _res('ui/common/common_btn_orange.png')})
    upgradeBtn:setTag(RemindTag.BTN_AVATAR_UPGRADE)
	view:addChild(upgradeBtn, 10)
	display.commonLabelParams(upgradeBtn, fontWithColor(14, {text = __('升级')}))
	local costLabel = display.newRichLabel(size.width/2, 10,
		{ap = cc.p(0.5, 0)})
	view:addChild(costLabel, 10)
	return {
		view 			 = view,
		upgradeBtn       = upgradeBtn,
		rankLabel		 = rankLabel,
		expProgressBar	 = expProgressBar,
		materialBg	     = materialBg,
		expLabel		 = expLabel,
		costLabel		 = costLabel,
		popularityIcon   = popularityIcon,
		popularityBg     = popularityBg
	}
end

function LobbyPopularityView:ctor( ... )
	self.canUpgrade = true
	self.goldEnough = true
	self.materialEnough = true
	self.popularityEnough = true
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
	self:UpdateUI()
end
function LobbyPopularityView:UpdateUI()
	self.canUpgrade = true
	self.goldEnough = true
	self.materialEnough = true
	self.popularityEnough = true
	-- 升级信息
    local nextLevel = checkint(gameMgr:GetUserInfo().restaurantLevel)
    local levelConfigs = CommonUtils.GetConfigAllMess('levelUp', 'restaurant')
    if (nextLevel + 1) > table.nums(levelConfigs) then
        nextLevel = nextLevel
    else
        nextLevel = nextLevel + 1
    end

	local upgradeDatas = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', nextLevel)
	self.viewData_.rankLabel:setString(string.fmt(__('_num_级餐厅'), {['_num_'] = gameMgr:GetUserInfo().restaurantLevel}))
	self.viewData_.expProgressBar:setMaxValue(tonumber(upgradeDatas.popularity))
	self.viewData_.expProgressBar:setValue(checkint(gameMgr:GetUserInfo().popularity))
	if self.viewData_.materialBg:getChildByTag(2222) then
		self.viewData_.materialBg:getChildByTag(2222):removeFromParent()
	end
	if checkint(gameMgr:GetUserInfo().popularity) < checkint(upgradeDatas.popularity) then
		self.canUpgrade = false
		self.popularityEnough = false
	end
	self.viewData_.expLabel:setString(tostring(gameMgr:GetUserInfo().popularity) .. '/' .. upgradeDatas.popularity)
	if nextLevel > table.nums(levelConfigs)  then
		self:CreateUpgradeStatus()
		return
	end
	-- self.viewData_.popularityIcon:setPositionX(self.viewData_.popularityBg:getContentSize().width/2 +  display.getLabelContentSize(self.viewData_.expLabel).width/2 + 20)
	local materialLayout = CLayout:create(cc.size(90 + (#upgradeDatas.consumeGoods-2)*120, 100))
	materialLayout:setTag(2222)
	materialLayout:setPosition(cc.p(self.viewData_.materialBg:getContentSize().width/2, 90))
	self.viewData_.materialBg:addChild(materialLayout)
	for i,v in ipairs(upgradeDatas.consumeGoods) do
		if v.goodsId == GOLD_ID then
			if gameMgr:GetUserInfo().gold < v.num then
				self.canUpgrade = false
				self.goldEnough = false
			end
			display.reloadRichLabel(self.viewData_.costLabel, {c = {
				{text = tostring(v.num), fontSize = 24, color = '#78564b'},
				{img = _res('arts/goods/goods_icon_' .. GOLD_ID .. '.png'), scale = 0.18},
			}})
		else
			local function callBack(sender)
				uiMgr:AddDialog("common.GainPopup", {goodId = v.goodsId, isFrom = 'AvatarMediator'})
			end
			local materialNode = require('common.GoodNode').new({id = v.goodsId, showAmount = false, callBack = callBack})
			materialNode:setPosition(cc.p(45 + (i-1)*120, 45))
			materialNode:setScale(0.8)
			materialLayout:addChild(materialNode, 10)
			local hasNum = gameMgr:GetAmountByGoodId(v.goodsId)
			local showEnough = true
			if checkint(hasNum) < checkint(v.num) then
				self.canUpgrade = false
				self.materialEnough = false
				showEnough = false
			end
			if showEnough then
				local materialNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
				display.commonUIParams(materialNumLabel, {ap = cc.p(1, 0)})
				materialNumLabel:setPosition(cc.p(86 + (i-1)*120, 2))
				-- materialNumLabel:setPosition(cc.p(materialNode:getContentSize().width - 5, 2))
				materialNumLabel:setString(tostring(hasNum) .. '/' .. v.num)
				-- materialNumLabel:setScale(0.6)
				-- materialNode:addChild(materialNumLabel,10)
				materialLayout:addChild(materialNumLabel,10)
			else
				local materialNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
				display.commonUIParams(materialNumLabel, {ap = cc.p(1, 0)})
				-- materialNumLabel:setPosition(cc.p(materialNode:getContentSize().width - 5, 2))
				materialNumLabel:setPosition(cc.p(86 + (i-1)*120, 2))
				materialNumLabel:setString('/' .. v.num)
				-- materialNumLabel:setScale(0.6)
				-- materialNode:addChild(materialNumLabel,10)
				materialLayout:addChild(materialNumLabel,10)
				local hasNumLabel = cc.Label:createWithBMFont('font/small/common_num_unused.fnt', '')
				display.commonUIParams(hasNumLabel, {ap = cc.p(1, 0)})
				-- hasNumLabel:setPosition(cc.p(materialNode:getContentSize().width - 5 - materialNumLabel:getContentSize().width*0.6, 5))
				hasNumLabel:setPosition(cc.p(86 + (i-1)*120 - materialNumLabel:getContentSize().width, 2))
				hasNumLabel:setString(tostring(hasNum))
				-- hasNumLabel:setScale(0.6)
				-- materialNode:addChild(hasNumLabel,10)
				materialLayout:addChild(hasNumLabel,10)
			end
		end
	end
end
function LobbyPopularityView:CreateUpgradeStatus()
	local viewData_ =  self.viewData_
	local fullLevelImage = display.newImageView(_res('ui/common/common_tips_no_pet.png'))
	local view = viewData_.view
	fullLevelImage:setScale(0.8)
	local viewSize = view:getContentSize()
	fullLevelImage:setPosition(viewSize.width /2 , 180)
	view:addChild(fullLevelImage,10)
	viewData_.materialBg:setVisible(false)
	viewData_.costLabel:setVisible(false)
	viewData_.upgradeBtn:setVisible(false)
	local fullLevelLabel = display.newLabel(viewSize.width /2 +70, 130,
			fontWithColor(8 , {ap = display.CENTER , hAlign = display.TAC, fontSize = 24 ,w = 280,  text =   __('餐厅已达到最高等级') }))
	view:addChild(fullLevelLabel,10)
end
return LobbyPopularityView
