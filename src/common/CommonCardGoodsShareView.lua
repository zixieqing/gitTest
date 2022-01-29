--[[
通用分享层 -> 适用道具类型 卡牌 皮肤 堕神
@params table {
	goodsId int 道具id
	confirmCallback function 确认按钮回调
}
--]]
local GameScene = require('Frame.GameScene')
local CommonCardGoodsShareView = class('CommonCardGoodsShareView', GameScene)

------------ import ------------
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function CommonCardGoodsShareView:ctor( ... )
	local args = unpack({...})

	self.goodsId = checkint(args.goodsId)
	self.confirmCallback = args.confirmCallback

	self:InitUI()
	self:RegisterSignal()

end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化界面
--]]
function CommonCardGoodsShareView:InitUI()
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
			local cardDrawNode = require('common.CardSkinDrawNode').new({
				skinId = skinId,
				coordinateType = COORDINATE_TYPE_CAPSULE
			})
			self:addChild(cardDrawNode, 1)
		end

		------------ 道具信息 ------------
		local titleBg = display.newNSprite(_res('ui/share/shop_skin_have_title_light.png'), 0, 0)
		display.commonUIParams(titleBg, {po = cc.p(
			display.SAFE_R - 275,
			display.SAFE_T - 100
		)})
		self:addChild(titleBg)

		local titleLabel = display.newLabel(0, 0,
			{text = string.format(__('获得%s'), tostring(goodsTypeConfig.type)), fontSize = 40, color = '#fff4c3',
			ttf = true, font = TTF_GAME_FONT, outline = '#7c3f12', outlineSize = 2})
		display.commonUIParams(titleLabel, {po = utils.getLocalCenter(titleBg)})
		titleBg:addChild(titleLabel)

		local goodsNameBg = display.newNSprite(_res('ui/home/capsule/draw_card_bg_name.png'), 0, 0)
		display.commonUIParams(goodsNameBg, {po = cc.p(
			titleBg:getPositionX() + 20,
			titleBg:getPositionY() - titleBg:getContentSize().height * 0.5 - goodsNameBg:getContentSize().height * 0.5 + 15
		)})
		self:addChild(goodsNameBg)

		local goodsNameStr = self:GetFixedGoodsName(self.goodsId)
		local goodsNameLabel = display.newLabel(0, 0,
			fontWithColor('14', {text = goodsNameStr, color = '#ffcb2b'}))
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
		self:addChild(spineAvatar)

		spineAvatar:update(0)
		spineAvatar:setAnimation(0, 'idle', true)

		------------ 底部按钮 ------------
		local confirmBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.ConfirmBtnClickHandler)})
		display.commonUIParams(confirmBtn, {po = cc.p(
			titleBg:getPositionX() + 95,
			display.SAFE_B + confirmBtn:getContentSize().height * 0.5 + 35
		)})
		display.commonLabelParams(confirmBtn, fontWithColor('14', {text = __('确定')}))
		self:addChild(confirmBtn, 10)

		local shareBtn = require('common.CommonShareButton').new({clickCallback = handler(self, self.ShareBtnClickHandler)})
		display.commonUIParams(shareBtn, {po = cc.p(
			titleBg:getPositionX() - 95,
			confirmBtn:getPositionY()
		)})
		self:addChild(shareBtn, 10)

		return {
			shareView = nil,
			confirmBtn = confirmBtn,
			shareBtn = shareBtn,
			titleBg = titleBg,
			goodsNameBg = goodsNameBg
		}

	end

	xTry(function()
		self.viewData = CreateView()
	end, __G__TRACKBACK__)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
显示分享界面
--]]
function CommonCardGoodsShareView:ShowShareView()
	if nil == self.viewData.shareView then
		-- 添加分享通用框架
		local node = require('common.ShareNode').new({visitNode = self})
		node:setName('ShareNode')
		display.commonUIParams(node, {po = utils.getLocalCenter(self)})
		self:addChild(node, 999)

		-- 添加道具名称模块
		local goodsNameBg = display.newNSprite(_res('ui/home/capsule/draw_card_bg_name.png'), 0, 0)
		display.commonUIParams(goodsNameBg, {po = cc.p(
			node.viewData.logoImage:getPositionX(),
			node.viewData.logoImage:getPositionY() - node.viewData.logoImage:getContentSize().height * 0.5 - 35
		)})
		node:addChild(goodsNameBg)

		local goodsNameStr = self:GetFixedGoodsName(self.goodsId)
		local goodsNameLabel = display.newLabel(0, 0,
			fontWithColor('14', {text = goodsNameStr, color = '#ffcb2b'}))
		display.commonUIParams(goodsNameLabel, {po = cc.p(
			utils.getLocalCenter(goodsNameBg).x - 35,
			utils.getLocalCenter(goodsNameBg).y - 5
		)})
		goodsNameBg:addChild(goodsNameLabel)

		self.viewData.shareView = node
	else
		self.viewData.shareView:setVisible(true)
	end

	-- 隐藏其他按钮
	self.viewData.shareBtn:setVisible(false)
	self.viewData.confirmBtn:setVisible(false)

	-- 隐藏道具信息
	self.viewData.titleBg:setVisible(false)
	self.viewData.goodsNameBg:setVisible(false)

	-- 隐藏一些全局ui
	AppFacade.GetInstance():DispatchObservers('RAID_SHOW_CHAT_PANEL', {show = false})
end
--[[
隐藏分享界面
--]]
function CommonCardGoodsShareView:HideShareView()
	-- 显示其他按钮
	self.viewData.shareBtn:setVisible(true)
	self.viewData.confirmBtn:setVisible(true)

	-- 显示道具信息
	self.viewData.titleBg:setVisible(true)
	self.viewData.goodsNameBg:setVisible(true)

	-- 显示一些全局ui
	AppFacade.GetInstance():DispatchObservers('RAID_SHOW_CHAT_PANEL', {show = true})

	-- 移除分享界面
	if nil ~= self.viewData.shareView then
		self.viewData.shareView:setVisible(false)
		self.viewData.shareView:runAction(cc.RemoveSelf:create())

		self.viewData.shareView = nil
	end
end
--[[
注册信号
--]]
function CommonCardGoodsShareView:RegisterSignal()

	------------ 分享返回按钮 ------------
	AppFacade.GetInstance():RegistObserver('SHARE_BUTTON_BACK_EVENT', mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:HideShareView()
	end, self))
	------------ 分享返回按钮 ------------

end
--[[
销毁信号
--]]
function CommonCardGoodsShareView:UnRegistSignal()
	AppFacade.GetInstance():UnRegistObserver('SHARE_BUTTON_BACK_EVENT', self)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
确认按钮回调
--]]
function CommonCardGoodsShareView:ConfirmBtnClickHandler(sender)
	PlayAudioByClickNormal()
	if nil ~= self.confirmCallback then
		self.confirmCallback(sender)
	end
end
--[[
分享按钮回调
--]]
function CommonCardGoodsShareView:ShareBtnClickHandler(sender)
	PlayAudioByClickNormal()
	-- 显示分享界面
	self:ShowShareView()
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
function CommonCardGoodsShareView:GetFixedSkinIdByGoodsId(goodsId)
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
function CommonCardGoodsShareView:GetFixedGoodsName(goodsId)
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
function CommonCardGoodsShareView:onCleanup()
	-- 注销信号
	self:UnRegistSignal()
end

return CommonCardGoodsShareView
