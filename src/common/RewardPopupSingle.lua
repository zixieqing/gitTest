--[[
单个奖励弹窗
@params table {
	viewType int 弹窗类型
	goodsId int 道具id
	bonusInfo table {
		------------ pattern 1 >viewType = 1< ------------
		petCharacterId int 堕神性格id
		------------ pattern 1 >viewType = 1< ------------
	}
}
--]]
local RewardPopupSingle = class('RewardPopupSingle', function ()
	local node = CLayout:create()
	node.name = 'common.RewardPopupSingle'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

--[[
constructor
--]]
function RewardPopupSingle:ctor( ... )
	local args = unpack({...})

	self.viewType = args.viewType
	self.goodsId = args.goodsId
	self.bonusInfo = args.bonusInfo

	self.canTouch = false

	self:InitUI()

end
---------------------------------------------------
-- init view begin --
---------------------------------------------------
function RewardPopupSingle:InitUI()

	local size = display.size
	self:setContentSize(size)

	local goodsConfig = CommonUtils.GetConfig('goods', 'goods', self.goodsId)

	local function CreateView()
		-- mask
		local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 200))
		eaterLayer:setTouchEnabled(true)
		eaterLayer:setContentSize(size)
		eaterLayer:setAnchorPoint(cc.p(0, 0))
		eaterLayer:setPosition(cc.p(0, 0))
		self:addChild(eaterLayer)

		-- title
		-- local title = display.newImageView(_res('ui/common/common_words_congratulations.png'), 0, 0)
		-- display.commonUIParams(title, {po = cc.p(
		-- 	display.cx,
		-- 	display.cy + 285
		-- )})
		-- self:addChild(title, 10)

		-- reward light
		local lightScale = 1.75
		local light = display.newImageView(_res('ui/common/common_reward_light.png'), 0, 0)
		display.commonUIParams(light, {po = cc.p(
			display.SAFE_RECT.width * 0.45,
			display.SAFE_RECT.height * 0.5
		)})
		light:setScale(lightScale)
		self:addChild(light, 5)

		-- goodsIcon
		local goodsIcon = nil
		local goodsType = CommonUtils.GetGoodTypeById(self.goodsId)
		if GoodsType.TYPE_PET == goodsType then
			goodsIcon = petMgr.GetPetDrawNodeByPetId(self.goodsId)
		else
			local goodPath = CommonUtils.GetGoodsIconPathById(self.goodsId)
			goodsIcon = display.newImageView(_res(goodsImgPath), 0, 0)
		end
		local iconScale = (light:getContentSize().width * lightScale) / goodsIcon:getContentSize().width * 0.75
		display.commonUIParams(goodsIcon, {po = cc.p(
			light:getPositionX(),
			light:getPositionY()
		)})
		goodsIcon:setScale(iconScale)
		self:addChild(goodsIcon, 6)

		-- goods name label
		local nameLabelBg = display.newImageView(_res('ui/home/capsule/draw_card_bg_name.png'), 0, 0)
		display.commonUIParams(nameLabelBg, {po = cc.p(
			display.SAFE_RECT.width - 20 - nameLabelBg:getContentSize().width * 0.5,
			display.SAFE_RECT.height * 0.8
		)})
		self:addChild(nameLabelBg, 7)

		local nameLabel = display.newLabel(0, 0, fontWithColor('19', {text = goodsConfig.name}))
		display.commonUIParams(nameLabel, {ap = cc.p(0, 0.5), po = cc.p(
			nameLabelBg:getPositionX() - nameLabelBg:getContentSize().width * 0.375,
			nameLabelBg:getPositionY()
		)})
		self:addChild(nameLabel, 7)

		-- confirm btn
		local confirmBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		confirmBtn:setName('confirmBtn')
		display.commonUIParams(confirmBtn, {
			po = cc.p(
				nameLabelBg:getPositionX() - 25 + (10 + confirmBtn:getContentSize().width * 0.5),
				40 + confirmBtn:getContentSize().height * 0.5
			),
			cb = function (sender)
				if self.canTouch then
					self:runAction(cc.RemoveSelf:create())
				end
				GuideUtils.DispatchStepEvent()
			end})
		display.commonLabelParams(confirmBtn, fontWithColor('14', {text = __('确定')}))
		self:addChild(confirmBtn, 10)

		-- share btn
		local shareBtn = require('common.CommonShareButton').new({clickCallback = handler(self, self.ShareBtnClickHandler)})
		display.commonUIParams(shareBtn, {po = cc.p(
			nameLabelBg:getPositionX() - 25 - (10 + shareBtn:getContentSize().width * 0.5),
			confirmBtn:getPositionY()
		)})
		self:addChild(shareBtn, 10)

		------------ 初始化动画状态 ------------
		-- title:setVisible(false)
		-- title:setOpacity(0)
		-- title:setPositionY(display.height + 95)

		nameLabelBg:setVisible(false)
		nameLabelBg:setOpacity(0)
		nameLabel:setVisible(false)
		nameLabel:setOpacity(0)

		light:setScale(0.519 * lightScale)
		light:setVisible(false)
		light:setRotation(-0.8)

		goodsIcon:setVisible(false)
		goodsIcon:setScale(iconScale * 0.14)

		confirmBtn:setVisible(false)
		confirmBtn:setOpacity(0)
		shareBtn:setVisible(false)
		shareBtn:setOpacity(0)
		-- confirmBtn:setPositionY(confirmBtn:getPositionY() - 60)
		------------ 初始化动画状态 ------------

		local ShowSelf = function ()
			------------ 标题动画 ------------
			-- local titleActionSeq = cc.Sequence:create(
			-- 	cc.DelayTime:create(0.2),
			-- 	cc.Show:create(),
			-- 	cc.Spawn:create(
			-- 		cc.FadeTo:create(0.2, 255),
			-- 		cc.MoveTo:create(0.2, cc.p(display.cx, display.cy + 300 - 25.5))
			-- 	),
			-- 	cc.MoveTo:create(0.1, cc.p(display.cx, display.cy + 300 + 24)),
			-- 	cc.MoveTo:create(0.1, cc.p(display.cx, display.cy + 300 - 15)),
			-- 	cc.MoveTo:create(0.1, cc.p(display.cx, display.cy + 285))
			-- )
			-- title:runAction(titleActionSeq)
			------------ 标题动画 ------------

			------------ 道具名字动画 ------------
			local nameActionSeq = cc.Sequence:create(
				cc.DelayTime:create(0.2),
				cc.Show:create(),
				cc.FadeTo:create(0.2, 255)
			)
			nameLabelBg:runAction(nameActionSeq:clone())
			nameLabel:runAction(nameActionSeq:clone())
			------------ 道具名字动画 ------------

			------------ 光动画 ------------
			local lightActionSeq = cc.Sequence:create(
				cc.DelayTime:create(0.1),
				cc.Show:create(),
				cc.Spawn:create(cc.ScaleTo:create(0.1, 0.96 * lightScale) ,cc.RotateTo:create(0.1, 10)),
	            cc.Spawn:create(cc.ScaleTo:create(1.8, 1 * lightScale) ,cc.RotateTo:create(1.8, 78)),
	            cc.CallFunc:create(function ()
	            	-- 循环转圈
	            	local loopRotateAction = cc.RepeatForever:create(
	            		cc.RotateBy:create(4.9, 180)
	            	)
	            	light:runAction(loopRotateAction)
	            end)
			)
			light:runAction(lightActionSeq)
			------------ 光动画 ------------

			------------ icon 动画 ------------
			local goodsIconActionSeq = cc.Sequence:create(
				cc.Show:create(),
				cc.ScaleTo:create(0.2, iconScale * 1.12),
				cc.ScaleTo:create(0.1, iconScale)
			)
			goodsIcon:runAction(goodsIconActionSeq)
			------------ icon 动画 ------------

			------------ 按钮动画 ------------
			-- local confirmBtnActionSeq = cc.Sequence:create(
			-- 	cc.DelayTime:create(25 / 30),
			-- 	cc.Show:create(),
			-- 	cc.Spawn:create(
			-- 		cc.MoveBy:create(7 / 30, cc.p(0, 60)),
			-- 		cc.FadeTo:create(7 / 30, 255)
			-- 	),
			-- 	cc.CallFunc:create(function ()
			-- 		-- 设置可以关闭
			-- 		self.canTouch = true
			-- 	end)
			-- )
			-- confirmBtn:runAction(confirmBtnActionSeq)

			local confirmBtnActionSeq = cc.Sequence:create(
				cc.DelayTime:create(0.25),
				cc.Show:create(),
				cc.FadeTo:create(7 / 30, 255),
				cc.CallFunc:create(function ()
					-- 设置可以关闭
					self.canTouch = true
				end)
			)
			confirmBtn:runAction(confirmBtnActionSeq)

			local shareBtnActionSeq = cc.Sequence:create(
				cc.DelayTime:create(0.25),
				cc.Show:create(),
				cc.FadeTo:create(7 / 30, 255)
			)
            shareBtn:runAction(shareBtnActionSeq)
			------------ 按钮动画 ------------
		end

		return {
			-- title = title,
			light = light,
			goodsIcon = goodsIcon,
			nameLabelBg = nameLabelBg,
			nameLabel = nameLabel,
			confirmBtn = confirmBtn,
			layer = {ShowSelf = ShowSelf}
		}

	end

	xTry(function ()
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

	self.mainLayer = self.viewData.layer
	self.bonusLayer = self:AddBonusContent()
    -- dump(self.bonusLayer)
end
--[[
添加额外内容
--]]
function RewardPopupSingle:AddBonusContent()
	if 1 == self.viewType then
		return self:AddPetCharacterInfo(self.bonusInfo.petCharacterId)
	end
end
--[[
添加堕神性格
@params petCharacterId int 堕神性格id
@return layer table layer结构
--]]
function RewardPopupSingle:AddPetCharacterInfo(petCharacterId)
	-- character
	local characterConfig = CommonUtils.GetConfig('pet', 'petCharacter', petCharacterId)
	local characterStr = string.format(__('性格:%s'), characterConfig.name)
	local characterLabel = display.newLabel(0, 0, fontWithColor('18', {text = characterStr}))
	display.commonUIParams(characterLabel, {ap = cc.p(0, 1), po = cc.p(
		self.viewData.nameLabel:getPositionX(),
		self.viewData.nameLabelBg:getPositionY() - 5 - self.viewData.nameLabelBg:getContentSize().height * 0.5
	)})
	self:addChild(characterLabel, 9)

	------------ 初始化动画状态 ------------
	characterLabel:setVisible(false)
	characterLabel:setOpacity(0)
	------------ 初始化动画状态 ------------

	local ShowSelf = function ()
		------------ 性格名称动画 ------------
		local characterLabelActionSeq = cc.Sequence:create(
			cc.DelayTime:create(0.2),
			cc.Show:create(),
			cc.FadeTo:create(0.2, 255)
		)
		characterLabel:runAction(characterLabelActionSeq)
		------------ 性格名称动画 ------------

	end

	local HideSelf = function ()

	end

	local layer = {ShowSelf = ShowSelf, HideSelf = HideSelf}
	return layer
end
---------------------------------------------------
-- init view end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
分享按钮回调
--]]
function RewardPopupSingle:ShareBtnClickHandler(sender)
	local shareLayer = require('Game.views.share.GetNewPetShareLayer').new({
		petId = self.goodsId,
		petCharacterId = self.bonusInfo.petCharacterId
	})
	shareLayer:setTag(5361)
	shareLayer:setAnchorPoint(cc.p(0.5, 0.5))
	shareLayer:setPosition(cc.p(display.cx, display.cy))
	uiMgr:GetCurrentScene():AddDialog(shareLayer)
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

--[[
cocos2dx event handler
--]]
function RewardPopupSingle:onEnter()
	self.mainLayer.ShowSelf()
	if nil ~= self.bonusLayer and nil ~= self.bonusLayer.ShowSelf then
		self.bonusLayer.ShowSelf()
	end
end
function RewardPopupSingle:onExit()

end
function RewardPopupSingle:onCleanup()

end

return RewardPopupSingle
