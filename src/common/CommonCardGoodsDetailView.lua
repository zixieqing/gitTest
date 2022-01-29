--[[
卡牌道具详情界面 适用道具类型 卡牌 皮肤 堕神
@params table {
	goodsId int 道具id
	consumeConfig table 购买消耗配置 {
		goodsId int 道具id
		amount int 消耗数量
	}
	discountGoodsData table 折扣道具数据
	confirmCallback function 确认按钮回调
	cancelCallback function 取消按钮回调
}
--]]
local GameScene = require('Frame.GameScene')
local CommonCardGoodsDetailView = class('CommonCardGoodsDetailView', GameScene)

------------ import ------------
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function CommonCardGoodsDetailView:ctor( ... )
	local args = unpack({...})

	self.goodsId = checkint(args.goodsId)
	self.confirmCallback = args.confirmCallback
	self.consumeConfig = args.consumeConfig
	self.discountGoodsData = args.discountGoodsData
	

	self.confirmCallback = args.confirmCallback
	self.cancelCallback = args.cancelCallback

	self:InitUI()

end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化界面
--]]
function CommonCardGoodsDetailView:InitUI()
	-- 吃触摸层
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(self:getContentSize())
	eaterLayer:setPosition(utils.getLocalCenter(self))
	self:addChild(eaterLayer)

	local goodsType = CommonUtils.GetGoodTypeById(self.goodsId)
	local goodsTypeConfig = CommonUtils.GetConfig('goods', 'type', goodsType)
	-- dump(goodsTypeConfig)
	local goodsConfig = CommonUtils.GetConfig('goods', 'goods', self.goodsId)

	local CreateView = function ()
		local size = self:getContentSize()

		------------ 背景 ------------
		local bg = display.newImageView(_res('ui/home/capsule/draw_card_bg.png'), 0, 0)
		display.commonUIParams(bg, {po = utils.getLocalCenter(self)})
		self:addChild(bg)

		local shine = display.newImageView(_res('ui/share/share_bg_pet_light.png'), 0, 0)
		display.commonUIParams(shine, {po = utils.getLocalCenter(self)})
		self:addChild(shine)

		------------ 道具立绘 ------------
		local skinId = self:GetFixedSkinIdByGoodsId(self.goodsId)
		if nil ~= skinId then
			if CardUtils.IsShowCardLive2d(skinId) then
				local l2dDrawNode = require('common.CardSkinL2dNode').new({
					skinId = skinId,
					clickCB = function() end,
				})
				l2dDrawNode:setPositionX(display.SAFE_L + 150)
				self:addChild(l2dDrawNode)
			else
				local cardDrawNode = require('common.CardSkinDrawNode').new({
					skinId = skinId,
					coordinateType = COORDINATE_TYPE_CAPSULE
				})
				cardDrawNode:setPositionX(display.SAFE_L + 150)
				self:addChild(cardDrawNode)
			end
		end

		------------ 道具信息 ------------
		local titleBg = display.newNSprite(_res('ui/share/shop_skin_have_title_light.png'), 0, 0)
		display.commonUIParams(titleBg, {po = cc.p(
			display.SAFE_R - 275,
			display.SAFE_T - 100
		)})
		self:addChild(titleBg)

		local titleLabel = display.newLabel(0, 0,
			{text = string.format('%s', tostring(goodsTypeConfig.type)), fontSize = 40, color = '#fff4c3',
			ttf = true, font = TTF_GAME_FONT, outline = '#7c3f12', reqW = 500 , outlineSize = 2})
		display.commonUIParams(titleLabel, {po = utils.getLocalCenter(titleBg)})
		titleBg:addChild(titleLabel)
		local goodsNameBg = display.newNSprite(_res('ui/home/capsule/draw_card_bg_name.png'), 0, 0,{scale9 = true })
		display.commonUIParams(goodsNameBg, {po = cc.p(
			titleBg:getPositionX() + 20,
			titleBg:getPositionY() - titleBg:getContentSize().height * 0.5 - goodsNameBg:getContentSize().height * 0.5 + 15
		)})
		self:addChild(goodsNameBg)
		local goodsNameBgSize = goodsNameBg:getContentSize()

		local goodsNameStr = self:GetFixedGoodsName(self.goodsId)
		local goodsNameLabel = display.newLabel(0, 0,
			fontWithColor('14', {text = goodsNameStr, color = '#ffcb2b' , reqW = 550}))
		local goodsNameLabelSize = display.getLabelContentSize(goodsNameLabel)
		if goodsNameLabelSize.width + 100 > goodsNameBgSize.width then

			goodsNameBg:setContentSize(cc.size(goodsNameLabelSize.width + 100 ,goodsNameBgSize.height ))
		end
		display.commonUIParams(goodsNameLabel, {po = cc.p(
			utils.getLocalCenter(goodsNameBg).x - 35,
			utils.getLocalCenter(goodsNameBg).y - 5
		)})

		goodsNameBg:addChild(goodsNameLabel)


		-- spine小人
		local spineAvatar = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.5})
		spineAvatar:setPosition(cc.p(
			titleBg:getPositionX(),
			size.height * 0.5 - 150
		))
		self:addChild(spineAvatar, 2)
		spineAvatar:setTag(1)
		spineAvatar:update(0)
		spineAvatar:setAnimation(0, 'idle', true)

		local qAvatarLayerSize = cc.size(140, 260)
		local qAvatarLayer = display.newLayer(spineAvatar:getPositionX(), spineAvatar:getPositionY(), 
			{ap = display.CENTER_BOTTOM, size = qAvatarLayerSize, color = cc.c4b(0,0,0,0), enable = true, cb = handler(self, self.QAvatarClickHandler)})
		self:addChild(qAvatarLayer, 2)

		if nil ~= self.consumeConfig then
			local buySize = cc.size(450, 70)
			local buyLayout = display.newLayer(titleBg:getPositionX() , display.SAFE_B + 35 ,{ap = display.CENTER_BOTTOM ,  size = buySize  } )
			self:addChild(buyLayout,30)
			local index = 0
			local count = table.nums(self.consumeConfig.priceTable or {})
			for i, v in pairs(self.consumeConfig.priceTable or {}) do
				index = index +1
				local button = display.newButton(buySize.width / count* (index - 0.5) , buySize.height/2 , { n  = _res('ui/common/common_btn_orange.png') } )
				buyLayout:addChild(button)
				button:setTag(checkint(i))
				display.commonUIParams(button ,{cb = handler(self, self.ConfirmBtnClickHandler)})
				local buttonSize = button:getContentSize()
				local richLabel = display.newRichLabel(buttonSize.width /2 , buttonSize.height/2 ,{ r = true ,  c = {
					fontWithColor(14, {text  = v}) ,
					{img = CommonUtils.GetGoodsIconPathById(i) , scale = 0.2 }
				}} )
				button:addChild(richLabel)
				CommonUtils.AddRichLabelTraceEffect(richLabel)
			end
		end

		if nil ~= self.discountGoodsData then
			local goodsConfig = CommonUtils.GetConfig('goods', 'goods', self.discountGoodsData.discountGoods) or {}
			local discount = 100 - self.discountGoodsData.discount * 100
			local discountGoodsUseHint = display.newLabel(display.SAFE_R - 144, display.SAFE_B + 12, 
				fontWithColor(18, {fontSize = 20, ap = display.RIGHT_BOTTOM, text = string.fmt(__('拥有_goodsName_, 购买该外观可享受_discount_%折扣'), {_goodsName_ = tostring(goodsConfig.name), _discount_ = discount})})) 
			self:addChild(discountGoodsUseHint,30)
		end

		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png") , cb = handler(self, self.CancelBtnClickHandler)})
		display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
		self:addChild(backBtn, 5)
		return {
			titleBg = titleBg,
			goodsNameBg = goodsNameBg,
			spineAvatar = spineAvatar,
		}
	end

	xTry(function()
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

	-- 隐藏商城的返回按钮
	AppFacade.GetInstance():DispatchObservers("SHOP_HIDDEN_BACK", {isShow = false})
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------

---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
确认按钮回调
--]]
function CommonCardGoodsDetailView:ConfirmBtnClickHandler(sender)
	PlayAudioByClickNormal()
	if nil ~= self.confirmCallback then
		self.confirmCallback(sender)
	end
end
--[[
回退按钮回调
--]]
function CommonCardGoodsDetailView:CancelBtnClickHandler(sender)
	PlayAudioByClickNormal()
	-- 关闭本界面
	self:setVisible(false)
	self:runAction(cc.Sequence:create(
		cc.RemoveSelf:create(),
		cc.CallFunc:create(function ()
			if nil ~= self.cancelCallback then
				self.cancelCallback(sender)
			end
		end)
	))
end
--[[
avatar回调
--]]
function CommonCardGoodsDetailView:QAvatarClickHandler(sender)
	PlayAudioByClickNormal()
	local actionList = {
        'idle',
        'run',
        'attack',
        'skill1',
        'skill2'
    }

	local qAvatar = self.viewData.spineAvatar
    local tag = checkint(qAvatar:getTag())
    if tag == 5 then
        tag = 1
	end
    tag = tag + 1
    qAvatar:update(0)
    qAvatar:setToSetupPose()
    qAvatar:setAnimation(0, actionList[tag], true)
    qAvatar:setTag(tag)
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据道具id获取道具对应的皮肤id
@params goodsId int 道具id
@return skinId int 皮肤id
--]]
function CommonCardGoodsDetailView:GetFixedSkinIdByGoodsId(goodsId)
	local skinId = nil
	local goodsType = CommonUtils.GetGoodTypeById(goodsId)
	if GoodsType.TYPE_CARD == goodsType then
		skinId = CardUtils.GetCardSkinId(goodsId)
	elseif GoodsType.TYPE_CARD_SKIN == goodsType then
		skinId = goodsId
	elseif GoodsType.TYPE_PET == goodsType then
		local petConfig = petMgr.GetPetConfig(goodsId)
		if nil ~= petConfig then
			local drawId = checkint(petConfig.drawId)
			local monsterConfig = CardUtils.GetCardConfig(drawId)
			if nil ~= monsterConfig then
				skinId = checkint(monsterConfig.skinId)
			end
		end
	end
	return skinId
end
--[[
获取道具名称
@params goodsId int 道具id
@return nameStr string 道具名称
--]]
function CommonCardGoodsDetailView:GetFixedGoodsName(goodsId)
	local goodsType = CommonUtils.GetGoodTypeById(goodsId)
	local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
	local nameStr = ''
	if GoodsType.TYPE_CARD_SKIN == goodsType then
		-- 皮肤加上卡牌名字
		local cardId = checkint(goodsConfig.cardId)
		local cardConfig = CardUtils.GetCardConfig(cardId)
		nameStr = string.format('%s:%s', tostring(cardConfig.name), tostring(goodsConfig.name))
	else
		nameStr = tostring(goodsConfig.name)
	end
	return nameStr
end
---------------------------------------------------
-- get set end --
---------------------------------------------------
function CommonCardGoodsDetailView:onCleanup()
	AppFacade.GetInstance():DispatchObservers("SHOP_HIDDEN_BACK", {isShow = true})
end

return CommonCardGoodsDetailView
