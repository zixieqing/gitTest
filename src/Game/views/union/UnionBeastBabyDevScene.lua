--[[
工会神兽养成主场景
--]]
local GameScene = require( "Frame.GameScene" )
local UnionBeastBabyDevScene = class("UnionBeastBabyDevScene", GameScene)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager('UIManager')
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local unionMgr = AppFacade.GetInstance():GetManager('UnionManager')

local UnionConfigParser  = require('Game.Datas.Parser.UnionConfigParser')
------------ import ------------

------------ define ------------
local PropsInfo = {
	{p = ObjP.ATTACK, 		pname = __('攻击力'), 			icon = 'ui/common/role_main_att_ico.png'},
	{p = ObjP.DEFENCE, 		pname = __('防御力'), 			icon = 'ui/common/role_main_def_ico.png'},
	{p = ObjP.HP, 			pname = __('生命值'), 			icon = 'ui/common/role_main_hp_ico.png'},
	{p = ObjP.CRITRATE, 	pname = __('暴击率'), 			icon = 'ui/common/role_main_baoji_ico.png'},
	{p = ObjP.CRITDAMAGE, 	pname = __('暴击伤害'), 			icon = 'ui/common/role_main_baoshangi_ico.png'},
	{p = ObjP.ATTACKRATE, 	pname = __('攻击速度'), 			icon = 'ui/common/role_main_speed_ico.png'}
}

local FeedSatietyViewTag = 3901
------------ define ------------

--[[
constructor
--]]
function UnionBeastBabyDevScene:ctor(...)
	local args = unpack({...})

	GameScene.ctor(self, 'Game.views.union.UnionBeastBabyDevScene')

	self.beastBabiesConfig = nil
	self.beastBabiesData = nil
	self.unionLevel = nil

	self.selectedBeastBabyIndex = nil

	self:InitUI()
	self:SetCanTouch(true)

	self:RegistHandler()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function UnionBeastBabyDevScene:InitUI()

	local function CreateView()
		local size = self:getContentSize()

		local coverBtn = display.newButton(0, 0, {size = size, animate = false})
		display.commonUIParams(coverBtn, {po = cc.p(
			size.width * 0.5,
			size.height * 0.5
		)})
		self:addChild(coverBtn, 99)

		local eaterLayer = display.newLayer(0, 0, {size = size, color = cc.c4b(0, 0, 0, 100), animate = false, enable = true, cb = function (sender)
			PlayAudioByClickClose()
			AppFacade.GetInstance():DispatchObservers('CLOSE_UNION_BEASTBABYDEV')
		end})
		display.commonUIParams(eaterLayer, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(eaterLayer)

		local bg = display.newImageView(_res('ui/common/common_bg_5.png'), 0, 0)
		local bgSize = bg:getContentSize()
		local view = display.newLayer(0, 0, {size = bgSize})
		display.commonUIParams(view, {ap = cc.p(0.5, 0.5), po = cc.p(
			size.width * 0.5,
			size.height * 0.5
		)})
		self:addChild(view)

		display.commonUIParams(bg, {po = cc.p(
			bgSize.width * 0.5,
			bgSize.height * 0.5
		)})
		view:addChild(bg)

		local eaterBtn = display.newButton(0, 0, {size = cc.size(bgSize.width, bgSize.height), animate = false, cb = function (sender)
			PlayAudioClip(AUDIOS.UI.ui_shoutuanzi_reaction.id)
			-- 动作
			self:BabyAction()
			-- 讲话
			self:BabySpeak(UnionPetVoiceType.IDLE)
		end})
		display.commonUIParams(eaterBtn, {po = cc.p(
			bgSize.width * 0.5,
			bgSize.height * 0.5
		)})
		view:addChild(eaterBtn)

		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg, fontWithColor('14', {text = __('远古堕神'), offset = cc.p(0, -2)}))
        titleBg:setEnabled(false)
		bg:addChild(titleBg, 20)

		-- 背景底图
		local bgInBg = display.newImageView(_res('ui/union/beastbaby/guild_pet_bg.png'), 0, 0)
		display.commonUIParams(bgInBg, {po = cc.p(
			bgSize.width * 0.5,
			bgSize.height * 0.5 - 18
		)})
		bg:addChild(bgInBg)

		local innerbgpo = cc.p(bgInBg:getPositionX(), bgInBg:getPositionY())
		local innerbgsize = bgInBg:getContentSize()

		local emptyLayer = display.newLayer(0, 0, {size = bgSize})
		display.commonUIParams(emptyLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
			bgSize.width * 0.5,
			bgSize.height * 0.5
		)})
		view:addChild(emptyLayer)

		-- 空状态小人
		local emptyAvatar = display.newImageView(_res('ui/common/common_tips_no_pet.png'), 0, 0)
		display.commonUIParams(emptyAvatar, {po = cc.p(
			bgSize.width * 0.5,
			bgSize.height * 0.5 + 20
		)})
		emptyLayer:addChild(emptyAvatar)

		local emptyLabel = display.newLabel(0, 0, fontWithColor('4', {text = __('未获得远古堕神，快去工会狩猎吧！')}))
		display.commonUIParams(emptyLabel, {po = cc.p(
			emptyAvatar:getContentSize().width * 0.5 + 65,
			emptyAvatar:getContentSize().height * 0.5 - 65
		)})
		emptyAvatar:addChild(emptyLabel)

		-- 中间层
		local centerLayer = display.newLayer(0, 0, {size = bgSize})
		display.commonUIParams(centerLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
			bgSize.width * 0.5,
			bgSize.height * 0.5
		)})
		view:addChild(centerLayer)
		-- centerLayer:setBackgroundColor(cc.c4b(55, 128, 255, 100))

		-- 切换按钮
		local nextBtn = display.newButton(0, 0, {n = _res('ui/iceroom/common_btn_direct_s.png'), cb = handler(self, self.NextPrevBtnClickHandler)})
		display.commonUIParams(nextBtn, {po = cc.p(
			view:getPositionX() + bgSize.width * 0.5 - 10,
			view:getPositionY()
		)})
		self:addChild(nextBtn, 30)
		nextBtn:setTag(3)

		-- local nextBtnBg = display.newNSprite(_res('ui/common/common_bg_direct_s.png'), 0, 0)
		-- display.commonUIParams(nextBtnBg, {po = utils.getLocalCenter(nextBtn)})
		-- nextBtn:addChild(nextBtnBg, -1)

		local prevBtn = display.newButton(0, 0, {n = _res('ui/iceroom/common_btn_direct_s.png'), cb = handler(self, self.NextPrevBtnClickHandler)})
		display.commonUIParams(prevBtn, {po = cc.p(
			view:getPositionX() - bgSize.width * 0.5 + 10,
			view:getPositionY()
		)})
		prevBtn:getNormalImage():setFlippedX(true)
		prevBtn:getSelectedImage():setFlippedX(true)
		self:addChild(prevBtn, 30)
		prevBtn:setTag(5)

		return {
			------------ data ------------
			coverBtn = coverBtn,
			view = view,
			emptyAvatar = emptyAvatar,
			centerLayer = centerLayer,
			bgInBg = bgInBg,
			nextBtn = nextBtn,
			prevBtn = prevBtn,
			innerbgpo = innerbgpo,
			innerbgsize = innerbgsize,
			amountNodes = {},
			amountNodesY = innerbgpo.y - innerbgsize.height * 0.5 + 145,
			beastBabySpine = nil,
			propertyView = nil,
			------------ handler ------------
			ShowNoBaby = function (no)
				emptyLayer:setVisible(no)

				nextBtn:setVisible(not no)
				prevBtn:setVisible(not no)
				centerLayer:setVisible(not no)
			end
		}
	end

	xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

	self:InitCenterLayer()
end
--[[
初始化中间ui
--]]
function UnionBeastBabyDevScene:InitCenterLayer()
	local centerLayer = self.viewData.centerLayer
	local innerbgpo = self.viewData.innerbgpo
	local innerbgsize = self.viewData.innerbgsize

	-- 顶部战力信息
	local battlePointBg = display.newButton(0, 0, {n = _res('ui/union/beastbaby/guild_pet_bg_battle_number.png'), cb = handler(self, self.BattlePointBtnClickHandler)})
	display.commonUIParams(battlePointBg, {po = cc.p(
		innerbgpo.x,
		innerbgpo.y + innerbgsize.height * 0.5 - battlePointBg:getContentSize().height * 0.5
	)})
	centerLayer:addChild(battlePointBg, 10)

	local battlePointHintBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_tips.png')})
	display.commonUIParams(battlePointHintBtn, {po = cc.p(
		battlePointBg:getContentSize().width * 0.2,
		battlePointBg:getContentSize().height * 0.5
	)})
	battlePointBg:addChild(battlePointHintBtn)

	local battlePointNameLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('战斗力:'), fontSize = 26}))
	display.commonUIParams(battlePointNameLabel, {ap = cc.p(0, 0.5), po = cc.p(
		battlePointHintBtn:getPositionX() + battlePointHintBtn:getContentSize().width * 0.5 - 5,
		battlePointBg:getContentSize().height * 0.5
	)})
	battlePointBg:addChild(battlePointNameLabel)

	local battlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '8888888')
	battlePointLabel:setScale(0.7)
	battlePointLabel:setAnchorPoint(cc.p(0.5, 0.5))
	battlePointLabel:setPosition(cc.p(
		battlePointBg:getContentSize().width * 0.65,
		battlePointBg:getContentSize().height * 0.5 - 5
	))
	battlePointBg:addChild(battlePointLabel)

	-- 养育记录按钮
	local devLogBtn = display.newButton(0, 0,
		{n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'), cb = handler(self, self.DevLogBtnClickHandler)})
	display.commonUIParams(devLogBtn, {po = cc.p(
		innerbgpo.x + innerbgsize.width * 0.5 - devLogBtn:getContentSize().width * 0.5 - 10,
		innerbgpo.y + innerbgsize.height * 0.5 - devLogBtn:getContentSize().height * 0.5 - 10
	)})
	display.commonLabelParams(devLogBtn, fontWithColor('9', {text = __('养育记录')}))
	centerLayer:addChild(devLogBtn, 10)

	-- 幼崽名字
	local beastBabyNameLabel = display.newLabel(0, 0, fontWithColor('19', {text = '测试神兽幼崽', fontSize = 40}))
	display.commonUIParams(beastBabyNameLabel, {ap = cc.p(0, 1), po = cc.p(
		innerbgpo.x - innerbgsize.width * 0.5 + 5,
		innerbgpo.y + innerbgsize.height * 0.5 - 5
	)})
	centerLayer:addChild(beastBabyNameLabel, 10)

	-- 点击提示
	local beastBabyAttrHintLabel = display.newLabel(0, 0, fontWithColor('5', {text = __('(点击查看属性)')}))
	display.commonUIParams(beastBabyAttrHintLabel, {ap = cc.p(0, 1), po = cc.p(
		beastBabyNameLabel:getPositionX(),
		beastBabyNameLabel:getPositionY() - display.getLabelContentSize(beastBabyNameLabel).height
	)})
	centerLayer:addChild(beastBabyAttrHintLabel, 10)

	-- 显示属性按钮
	local attrBtn = display.newButton(0, 0, {size = cc.size(250, 100), cb = handler(self, self.AttrBtnClickHandler)})
	display.commonUIParams(attrBtn, {po = cc.p(
		innerbgpo.x - innerbgsize.width * 0.5 + attrBtn:getContentSize().width * 0.5,
		innerbgpo.y + innerbgsize.height * 0.5 - attrBtn:getContentSize().height * 0.5
	)})
	centerLayer:addChild(attrBtn, 10)

	-- 底部信息
	------------ energy ------------
	local energyInfoBg = display.newImageView(_res('ui/union/beastbaby/guild_pet_bg_level.png'), 0, 0)
	local energyInfoBgSize = energyInfoBg:getContentSize()

	local energyInfoLayer = display.newLayer(0, 0, {size = energyInfoBgSize})
	display.commonUIParams(energyInfoLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
		innerbgpo.x - innerbgsize.width * 0.5 + energyInfoBgSize.width * 0.5 - 5,
		innerbgpo.y - innerbgsize.height * 0.5 + energyInfoBgSize.height * 0.5
	)})
	centerLayer:addChild(energyInfoLayer, 10)

	display.commonUIParams(energyInfoBg, {po = utils.getLocalCenter(energyInfoLayer)})
	energyInfoLayer:addChild(energyInfoBg)

	local energyNameLabel = display.newLabel(0, 0,
		{text = __('能量'), fontSize = 24, color = '#ffdd41', ttf = true, font = TTF_GAME_FONT, outline = '#311717'})
	display.commonUIParams(energyNameLabel, {po = cc.p(
		energyInfoBgSize.width * 0.5,
		energyInfoBgSize.height - 25
	)})
	energyInfoLayer:addChild(energyNameLabel, 11)

	local energyHintBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_tips.png'), cb = handler(self, self.EnergyHintBtnClickHandler)})
	display.commonUIParams(energyHintBtn, {po = cc.p(
		energyNameLabel:getPositionX() - display.getLabelContentSize(energyNameLabel).width * 0.5 - energyHintBtn:getContentSize().width * 0.5,
		energyNameLabel:getPositionY()
	)})
	energyInfoLayer:addChild(energyHintBtn, 11)

	local energyBar = CProgressBar:create(_res('ui/union/beastbaby/guild_hunt_bg_loading_energy.png'))
	energyBar:setBackgroundImage(_res('ui/union/beastbaby/guild_hunt_bg_blood.png'))
	energyBar:setDirection(eProgressBarDirectionLeftToRight)
	energyBar:setPosition(cc.p(
		energyInfoBgSize.width * 0.5 - 25,
		energyInfoBgSize.height * 0.5 - 5
	))
	energyInfoLayer:addChild(energyBar, 11)

	local energyLabel = display.newLabel(0, 0, fontWithColor('14', {text = '8888/8888', fontSize = 26}))
	display.commonUIParams(energyLabel, {po = utils.getLocalCenter(energyBar)})
	energyBar:addChild(energyLabel, 99)

	local energyLevelLabel = display.newLabel(0, 0, fontWithColor('18', {text = '等级:88'}))
	display.commonUIParams(energyLevelLabel, {ap = cc.p(1, 0.5), po = cc.p(
		energyBar:getPositionX() - energyBar:getContentSize().width * 0.5 - 5,
		energyBar:getPositionY()
	)})
	energyInfoLayer:addChild(energyLevelLabel, 11)

	local energyBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.EnergyBtnClickHandler)})
	display.commonUIParams(energyBtn, {po = cc.p(
		energyBar:getPositionX() + energyBar:getContentSize().width * 0.5 + energyBtn:getContentSize().width * 0.5 + 5,
		energyBar:getPositionY()
	)})
	display.commonLabelParams(energyBtn, fontWithColor('14', {text = __('获取能量')}))
	energyInfoLayer:addChild(energyBtn, 11)
	------------ energy ------------

	------------ satiety ------------
	local satietyInfoBg = display.newImageView(_res('ui/union/beastbaby/guild_pet_bg_level.png'), 0, 0)
	local satietyInfoBgSize = satietyInfoBg:getContentSize()

	local satietyInfoLayer = display.newLayer(0, 0, {size = satietyInfoBgSize})
	display.commonUIParams(satietyInfoLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
		innerbgpo.x + innerbgsize.width * 0.5 - satietyInfoBgSize.width * 0.5 + 5,
		innerbgpo.y - innerbgsize.height * 0.5 + satietyInfoBgSize.height * 0.5
	)})
	centerLayer:addChild(satietyInfoLayer, 10)

	display.commonUIParams(satietyInfoBg, {po = utils.getLocalCenter(satietyInfoLayer)})
	satietyInfoLayer:addChild(satietyInfoBg, 10)

	local satietyNameLabel = display.newLabel(0, 0,
		{text = __('饱食度'), fontSize = 24, color = '#ff903e', ttf = true, font = TTF_GAME_FONT, outline = '#311717'})
	display.commonUIParams(satietyNameLabel, {po = cc.p(
		satietyInfoBgSize.width * 0.5,
		satietyInfoBgSize.height - 25
	)})
	satietyInfoLayer:addChild(satietyNameLabel, 11)

	local satietyHintBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_tips.png'), cb = handler(self, self.SatietyHintBtnClickHandler)})
	display.commonUIParams(satietyHintBtn, {po = cc.p(
		satietyNameLabel:getPositionX() - display.getLabelContentSize(satietyNameLabel).width * 0.5 - satietyHintBtn:getContentSize().width * 0.5,
		satietyNameLabel:getPositionY()
	)})
	satietyInfoLayer:addChild(satietyHintBtn, 11)

	local satietyBar = CProgressBar:create(_res('ui/union/beastbaby/guild_hunt_bg_loading_blood.png'))
	satietyBar:setBackgroundImage(_res('ui/union/beastbaby/guild_hunt_bg_blood.png'))
	satietyBar:setDirection(eProgressBarDirectionLeftToRight)
	satietyBar:setPosition(cc.p(
		satietyInfoBgSize.width * 0.5 - 25,
		satietyInfoBgSize.height * 0.5 - 5
	))
	satietyInfoLayer:addChild(satietyBar, 11)

	local satietyLabel = display.newLabel(0, 0, fontWithColor('14', {text = '8888/8888', fontSize = 26}))
	display.commonUIParams(satietyLabel, {po = utils.getLocalCenter(satietyBar)})
	satietyBar:addChild(satietyLabel, 99)

	local satietyLevelLabel = display.newLabel(0, 0, fontWithColor('18', {text = '等级:88'}))
	display.commonUIParams(satietyLevelLabel, {ap = cc.p(1, 0.5), po = cc.p(
		satietyBar:getPositionX() - satietyBar:getContentSize().width * 0.5 - 5,
		satietyBar:getPositionY()
	)})
	satietyInfoLayer:addChild(satietyLevelLabel, 11)

	local satietyBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.SatietyBtnClickHandler)})
	display.commonUIParams(satietyBtn, {po = cc.p(
		satietyBar:getPositionX() + satietyBar:getContentSize().width * 0.5 + satietyBtn:getContentSize().width * 0.5 + 5,
		satietyBar:getPositionY()
	)})
	display.commonLabelParams(satietyBtn, fontWithColor('14', {text = __('去投食')}))
	satietyInfoLayer:addChild(satietyBtn, 11)

	-- 喂食次数
	local feedAmountLabel = display.newLabel(0, 0, fontWithColor('14', {text = '88/88'}))
	display.commonUIParams(feedAmountLabel, {ap = cc.p(1, 1), po = cc.p(
		satietyBtn:getPositionX() + satietyBtn:getContentSize().width * 0.5,
		satietyBtn:getPositionY() - satietyBtn:getContentSize().height * 0.5 + 2
	)})
	satietyInfoLayer:addChild(feedAmountLabel, 20)

	local feedLabel = display.newLabel(0, 0, fontWithColor('5', {text = __('今日剩余投食数量:')}))
	display.commonUIParams(feedLabel, {ap = cc.p(1, 1), po = cc.p(
		feedAmountLabel:getPositionX() - 50,
		feedAmountLabel:getPositionY() - 2
	)})
	satietyInfoLayer:addChild(feedLabel, 20)
	------------ satiety ------------

	-- 神兽avatar阴影
	local avatarShadow = display.newNSprite(_res('ui/battle/battle_role_shadow.png'), 0, 0)
	display.commonUIParams(avatarShadow, {po = cc.p(
		innerbgpo.x,
		self.viewData.amountNodesY + avatarShadow:getContentSize().height * 0.5 + 20
	)})
	centerLayer:addChild(avatarShadow, 1)

	-- 未解锁阴影
	local lockShadow = display.newImageView(_res('cards/beastbabyicon/guild_pet_ico_lock_300061.png'), 0, 0)
	display.commonUIParams(lockShadow, {ap = cc.p(0.5, 0), po = cc.p(
		avatarShadow:getPositionX(),
		avatarShadow:getPositionY()
	)})
	centerLayer:addChild(lockShadow, 2)

	local lockIcon = display.newNSprite(_res('arts/goods/goods_icon_error.png'), 0, 0)
	display.commonUIParams(lockIcon, {po = utils.getLocalCenter(lockShadow)})
	lockShadow:addChild(lockIcon)

	local getLabel = display.newLabel(0, 0, fontWithColor('14', {text = ''}))
	display.commonUIParams(getLabel, {po = cc.p(
		innerbgpo.x,
		self.viewData.amountNodesY - 50
	)})
	centerLayer:addChild(getLabel, 10)

	self.viewData.battlePointBg = battlePointBg
	self.viewData.battlePointLabel = battlePointLabel
	self.viewData.devLogBtn = devLogBtn
	self.viewData.beastBabyNameLabel = beastBabyNameLabel
	self.viewData.beastBabyAttrHintLabel = beastBabyAttrHintLabel

	self.viewData.energyInfoLayer = energyInfoLayer
	self.viewData.energyBar = energyBar
	self.viewData.energyLabel = energyLabel
	self.viewData.energyLevelLabel = energyLevelLabel

	self.viewData.satietyInfoLayer = satietyInfoLayer
	self.viewData.satietyBar = satietyBar
	self.viewData.satietyLabel = satietyLabel
	self.viewData.satietyLevelLabel = satietyLevelLabel
	self.viewData.feedLabel = feedLabel
	self.viewData.feedAmountLabel = feedAmountLabel

	self.viewData.avatarShadow = avatarShadow
	self.viewData.lockShadow = lockShadow
	self.viewData.lockIcon = lockIcon
	self.viewData.getLabel = getLabel

	local ShowBeastBabyDetail = function (unlock)
		self.viewData.battlePointBg:setVisible(unlock)
		self.viewData.devLogBtn:setVisible(unlock)
		self.viewData.beastBabyNameLabel:setVisible(unlock)
		self.viewData.beastBabyAttrHintLabel:setVisible(unlock)
		self.viewData.energyInfoLayer:setVisible(unlock)
		self.viewData.satietyInfoLayer:setVisible(unlock)
		if nil ~= self.viewData.beastBabySpine then
			self.viewData.beastBabySpine:setVisible(unlock)
		end

		self.viewData.lockShadow:setVisible(not unlock)
		self.viewData.getLabel:setVisible(not unlock)
	end

	self.viewData.ShowBeastBabyDetail = ShowBeastBabyDetail
end
--[[
初始化属性页
--]]
function UnionBeastBabyDevScene:InitPropertyView()
	local centerLayer = self.viewData.centerLayer
	local innerbgpo = self.viewData.innerbgpo
	local innerbgsize = self.viewData.innerbgsize

	local propertyView = display.newLayer(0, 0, {size = cc.size(centerLayer:getContentSize().width, centerLayer:getContentSize().height)})
	display.commonUIParams(propertyView, {ap = cc.p(0.5, 0.5), po = cc.p(
		centerLayer:getPositionX(),
		centerLayer:getPositionY()
	)})
	self.viewData.view:addChild(propertyView, 20)
	-- propertyView:setBackgroundColor(cc.c4b(0, 128, 128, 100))

	local eaterBtn = display.newButton(0, 0, {size = propertyView:getContentSize(), animate = false, cb = function (sender)
		PlayAudioByClickNormal()
		self:HidePropertyView()
	end})
	display.commonUIParams(eaterBtn, {ap = cc.p(0.5, 0.5), po = cc.p(
		propertyView:getContentSize().width * 0.5,
		propertyView:getContentSize().height * 0.5
	)})
	propertyView:addChild(eaterBtn, 30)
	------------ 属性 ------------
	local propBg = display.newImageView(_res('ui/union/beastbaby/guild_pet_attribute.png'), 0, 0)
	display.commonUIParams(propBg, {po = cc.p(
		innerbgpo.x - innerbgsize.width * 0.5 + propBg:getContentSize().width * 0.5 + 30,
		innerbgpo.y + innerbgsize.height * 0.5 - propBg:getContentSize().height * 0.5 + 10
	)})
	propertyView:addChild(propBg)

	local propTitleBg = display.newImageView(_res('ui/common/common_title_5.png'), 0, 0)
	display.commonUIParams(propTitleBg, {po = cc.p(
		propBg:getContentSize().width * 0.5,
		propBg:getContentSize().height - propTitleBg:getContentSize().height * 0.5 - 10
	)})
	propBg:addChild(propTitleBg)

	local propTitleLabel = display.newLabel(0, 0, fontWithColor('4', {text = __('属性')}))
	display.commonUIParams(propTitleLabel, {po = cc.p(
		utils.getLocalCenter(propTitleBg).x,
		utils.getLocalCenter(propTitleBg).y
	)})
	propTitleBg:addChild(propTitleLabel)

	local propHintLabel = display.newLabel(0, 0, fontWithColor('6', {text = __('(提升能量等级可提升以下属性)')}))
	display.commonUIParams(propHintLabel, {po = cc.p(
		propTitleBg:getPositionX(),
		propTitleBg:getPositionY() - propTitleBg:getContentSize().height * 0.5 - 15
	)})
	propBg:addChild(propHintLabel)

	-- 创建属性预览
	local propertyViewPNodes = {}
	for i,v in ipairs(PropsInfo) do
		local pbgpath = 'ui/union/beastbaby/guild_pet_bg_attribute_list_1.png'
		if i % 2 == 0 then
			pbgpath = 'ui/union/beastbaby/guild_pet_bg_attribute_list_2.png'
		end
		local pbg = display.newImageView(_res(pbgpath), 0, 0)
		display.commonUIParams(pbg, {po = cc.p(
			propTitleBg:getPositionX(),
			propTitleBg:getPositionY() - 85 - (i - 1) * pbg:getContentSize().height
		)})
		propBg:addChild(pbg)

		local picon = display.newNSprite(_res(v.icon), 0, 0)
		display.commonUIParams(picon, {po = cc.p(
			10 + picon:getContentSize().width * 0.5,
			pbg:getContentSize().height * 0.5
		)})
		pbg:addChild(picon)

		local pnamelabel = display.newLabel(0, 0, fontWithColor('5', {text = v.pname}))
		display.commonUIParams(pnamelabel, {ap = cc.p(0, 0.5), po = cc.p(
			picon:getPositionX() + picon:getContentSize().width * 0.5 + 10,
			picon:getPositionY()
		)})
		pbg:addChild(pnamelabel)

		local pvaluelabel = display.newLabel(0, 0, fontWithColor('5', {text = '8888'}))
		display.commonUIParams(pvaluelabel, {ap = cc.p(1, 0.5), po = cc.p(
			pbg:getContentSize().width - 35,
			pnamelabel:getPositionY()
		)})
		pbg:addChild(pvaluelabel)

		table.insert(propertyViewPNodes, {icon = picon, nameLabel = pnamelabel, valueLabel = pvaluelabel})
	end
	------------ 属性 ------------

	------------ 技能 ------------
	local skillBg = display.newImageView(_res('ui/union/beastbaby/guild_pet_attribute.png'), 0, 0)
	display.commonUIParams(skillBg, {po = cc.p(
		innerbgpo.x + innerbgsize.width * 0.5 - skillBg:getContentSize().width * 0.5 - 30,
		innerbgpo.y + innerbgsize.height * 0.5 - skillBg:getContentSize().height * 0.5 + 10
	)})
	propertyView:addChild(skillBg)

	local skillTitleBg = display.newImageView(_res('ui/common/common_title_5.png'), 0, 0)
	display.commonUIParams(skillTitleBg, {po = cc.p(
		skillBg:getContentSize().width * 0.5,
		skillBg:getContentSize().height - skillTitleBg:getContentSize().height * 0.5 - 10
	)})
	skillBg:addChild(skillTitleBg)

	local skillTitleLabel = display.newLabel(0, 0, fontWithColor('4', {text = __('技能')}))
	display.commonUIParams(skillTitleLabel, {po = cc.p(
		utils.getLocalCenter(skillTitleBg).x,
		utils.getLocalCenter(skillTitleBg).y
	)})
	skillTitleBg:addChild(skillTitleLabel)

	local skillHintLabel = display.newLabel(0, 0, fontWithColor('6', {text = __('(提升饱食度等级可提升技能强度)')}))
	display.commonUIParams(skillHintLabel, {po = cc.p(
		skillTitleBg:getPositionX(),
		skillTitleBg:getPositionY() - skillTitleBg:getContentSize().height * 0.5 - 15
	)})
	skillBg:addChild(skillHintLabel)

	local listViewSize = cc.size(skillBg:getContentSize().width, skillBg:getContentSize().height - 90)
	local listView = CListView:create(listViewSize)
	listView:setBounceable(false)
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setPosition(cc.p(
		skillBg:getPositionX(),
		skillBg:getPositionY() + skillBg:getContentSize().height * 0.5 - listViewSize.height * 0.5 - 75
	))
	propertyView:addChild(listView)
	-- listView:setDragable(false)
	-- listView:setBackgroundColor(cc.c4b(255, 128, 64, 100))
	------------ 技能 ------------

	self.viewData.propertyView = propertyView
	self.viewData.propertyViewPNodes = propertyViewPNodes
	self.viewData.skillListView = listView
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新界面
@params beastBabiesConfig 神兽幼崽配置
@params beastBabiesData 神兽幼崽信息
@params unionLevel int 工会等级
--]]
function UnionBeastBabyDevScene:RefreshUI(beastBabiesConfig, beastBabiesData, unionLevel)
	self.viewData.ShowNoBaby(0 >= #beastBabiesData)

	self.beastBabiesConfig = beastBabiesConfig
	self.beastBabiesData = beastBabiesData
	self.unionLevel = unionLevel

	-- 根据神兽幼崽数量刷新一些界面信息
	self:RefreshUIByBeastBabiesAmount(#beastBabiesConfig)

	self:RefreshUIByIndex(1)
end
--[[
根据神兽幼崽数量刷新中间界面
@params amount int 神兽幼崽数量
--]]
function UnionBeastBabyDevScene:RefreshUIByBeastBabiesAmount(amount)
	-- 移除老节点
	for i,v in ipairs(self.viewData.amountNodes) do
		v:removeFromParent()
	end
	self.viewData.amountNodes = {}

	for i = 1, amount do
		local amountNode = display.newNSprite(_res('ui/common/maps_fight_ico_round_default.png'), 0, 0)
		display.commonUIParams(amountNode, {po = cc.p(
			self.viewData.innerbgpo.x + (i - 0.5 - amount * 0.5) * (amountNode:getContentSize().width + 10),
			self.viewData.amountNodesY
		)})
		self.viewData.centerLayer:addChild(amountNode, 10)

		self.viewData.amountNodes[i] = amountNode
	end
end
--[[
根据序号刷新神兽信息
@params index int 神兽序号
--]]
function UnionBeastBabyDevScene:RefreshUIByIndex(index)
	if index == self.selectedBeastBabyIndex then return end

	if nil ~= self.selectedBeastBabyIndex then
		-- 刷新老节点
		local preAmountNode = self.viewData.amountNodes[self.selectedBeastBabyIndex]
		if nil ~= preAmountNode then
			preAmountNode:setTexture(_res('ui/common/maps_fight_ico_round_default.png'))
		end
	end

	if nil ~= index then
		local curAmountNode = self.viewData.amountNodes[index]
		if nil ~= curAmountNode then
			curAmountNode:setTexture(_res('ui/common/maps_fight_ico_round_select.png'))
		end
	end

	self.selectedBeastBabyIndex = index

	local beastBabyConfig = self:GetBeastBabyConfig(index)
	self:RefreshUIByBeastBabyId(checkint(beastBabyConfig.id))

	self:RefreshNextPrevBtn()
end
--[[
根据id刷新中间神兽幼崽信息
@params id int 神兽幼崽信息
--]]
function UnionBeastBabyDevScene:RefreshUIByBeastBabyId(id)
	local beastBabyData = self:GetBeastBabyDataById(id)
	local beastBabyConfig = CommonUtils.GetConfig('union', UnionConfigParser.TYPE.GODBEASTATTR, id)
	local beastBabyFormConfig = nil
	if nil == beastBabyData then
		beastBabyFormConfig = cardMgr.GetBeastBabyFormConfig(
			id,
			1,
			1
		)
	else
		beastBabyFormConfig = cardMgr.GetBeastBabyFormConfig(
			id,
			checkint(beastBabyData.energyLevel),
			checkint(beastBabyData.satietyLevel)
		)
	end

	local beastBabySkinId = checkint(beastBabyFormConfig.skinId)

	if nil == beastBabyData then
		-- 没有神兽信息 显示未获得状态
		self:RefreshBeastBabyShadowBySkinId(beastBabySkinId)
		self:HidePropertyView()
	else
		------------ 基本信息 ------------
		self.viewData.beastBabyNameLabel:setString(tostring(beastBabyFormConfig.name))
		self.viewData.battlePointLabel:setString(tostring(cardMgr.GetBeastBabyBattlePoint(
			id,
			checkint(beastBabyData.energyLevel),
			checkint(beastBabyData.satietyLevel)
		)))
		self:RefreshLeftFeedAmount(
			checkint(unionMgr:getUnionData().leftFeedPetNumber),
			CommonUtils.getVipTotalLimitByField('unionFeedNum')
		)

		-- 刷新能量等级
		self:RefreshBeastBabyEnergyLevel(checkint(beastBabyData.energyLevel), checkint(beastBabyData.energy))
		-- 刷新饱食等级
		self:RefreshBeastBabySatietyLevel(checkint(beastBabyData.satietyLevel), checkint(beastBabyData.satiety))
		-- 刷新属性描述
		self:RefreshBeastBabyPropView(id)
		------------ 基本信息 ------------

		------------ 外貌信息 ------------
		-- 有神兽信息
		self:RefreshBeastBabySpineBySkinId(beastBabySkinId, checknumber(beastBabyFormConfig.scale or 1))
		------------ 外貌信息 ------------
	end

	local beastName = '???'
	local beastConfig = cardMgr.GetBeastConfig(checkint(beastBabyConfig.godBeastId))
	if nil ~= beastConfig then
		beastName = tostring(beastConfig.name)
	end

	-- 刷新获取途径文字
	self.viewData.getLabel:setString(string.format(__('击杀%s获得'), beastName))

	self.viewData.ShowBeastBabyDetail(nil ~= beastBabyData)
end
--[[
根据皮肤id刷新幼崽形象
@params skinId int 皮肤id
@params fixedScale int 修正后的缩放比
--]]
function UnionBeastBabyDevScene:RefreshBeastBabySpineBySkinId(skinId, fixedScale)
	if nil ~= self.viewData.beastBabySpine then
		self.viewData.beastBabySpine:removeFromParent()
		self.viewData.beastBabySpine = nil
	end

	local spineNode = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.5 * fixedScale})
	self.viewData.beastBabySpine = spineNode
	spineNode:setScaleX(-1)
	spineNode:update(0)
	spineNode:setToSetupPose()
	spineNode:setAnimation(0, 'idle', true)
	spineNode:setPosition(cc.p(
		self.viewData.innerbgpo.x,
		self.viewData.avatarShadow:getPositionY()
	))
	self.viewData.centerLayer:addChild(spineNode, 2)

	-- 修正阴影大小
	local shadowScale = 1
	if nil ~= spineNode:getBorderBox('viewBox') then
		shadowScale = 0.5 * (spineNode:getBorderBox('viewBox').width / self.viewData.avatarShadow:getContentSize().width)
	end
	self.viewData.avatarShadow:setScale(shadowScale)

	-- 顺便说句话
	self:BabySpeak(UnionPetVoiceType.ENTER)
end
--[[
根据皮肤id刷新幼崽阴影
@params skinId int 皮肤id
--]]
function UnionBeastBabyDevScene:RefreshBeastBabyShadowBySkinId(skinId)
	local skinConfig = CardUtils.GetCardSkinConfig(skinId)
	if nil ~= skinConfig then
		local drawPath = string.format('cards/beastbabyicon/guild_pet_ico_lock_%s.png', tostring(skinConfig.drawId))
		self.viewData.lockShadow:setTexture(_res(drawPath))

		display.commonUIParams(self.viewData.lockIcon, {po = utils.getLocalCenter(self.viewData.lockShadow)})
		-- 修正阴影大小
		self.viewData.avatarShadow:setScale(1)
	end
end
--[[
刷新一次左右箭头
--]]
function UnionBeastBabyDevScene:RefreshNextPrevBtn()
	local beastBabiesAmount = #self.beastBabiesConfig
	if 1 >= beastBabiesAmount then
		self.viewData.nextBtn:setVisible(false)
		self.viewData.prevBtn:setVisible(false)
	elseif 0 >= #self.beastBabiesData then
		self.viewData.nextBtn:setVisible(false)
		self.viewData.prevBtn:setVisible(false)
	else
		if 1 >= self.selectedBeastBabyIndex then
			self.viewData.nextBtn:setVisible(true)
			self.viewData.prevBtn:setVisible(false)
		elseif beastBabiesAmount <= self.selectedBeastBabyIndex then
			self.viewData.nextBtn:setVisible(false)
			self.viewData.prevBtn:setVisible(true)
		else
			self.viewData.nextBtn:setVisible(true)
			self.viewData.prevBtn:setVisible(true)
		end
	end
end
--[[
刷新喂养次数
@params leftAmount int 剩余数量
@params maxAmount int 最大数量
--]]
function UnionBeastBabyDevScene:RefreshLeftFeedAmount(leftAmount, maxAmount)
	self.viewData.feedAmountLabel:setString(string.format('%d/%d', leftAmount, maxAmount))
	self.viewData.feedLabel:setPositionX(
		self.viewData.feedAmountLabel:getPositionX() - display.getLabelContentSize(self.viewData.feedAmountLabel).width - 10
	)
end
--[[
根据能量等级 经验 刷新界面
@params level int 能量等级
@params exp int 能量经验
--]]
function UnionBeastBabyDevScene:RefreshBeastBabyEnergyLevel(level, exp)
	self.viewData.energyLevelLabel:setString(string.format(__('等级:%d'), checkint(level)))
	local nextLevel, curExp, curNeedExp = cardMgr.GetBeastBabyNextEnergyLevelInfo(level, exp)
	if -1 == curExp or -1 == curNeedExp then
		self.viewData.energyLabel:setString(__('max/max'))
		self.viewData.energyBar:setMaxValue(100)
		self.viewData.energyBar:setValue(100)
	else
		self.viewData.energyLabel:setString(string.format('%d/%d', curExp, curNeedExp))
		self.viewData.energyBar:setMaxValue(curNeedExp)
		self.viewData.energyBar:setValue(curExp)
	end
end
--[[
根据饱食等级 经验 刷新界面
@params level int 能量等级
@params exp int 能量经验
--]]
function UnionBeastBabyDevScene:RefreshBeastBabySatietyLevel(level, exp)
	self.viewData.satietyLevelLabel:setString(string.format(__('等级:%d'), checkint(level)))
	local nextLevel, curExp, curNeedExp = cardMgr.GetBeastBabyNextSatietyLevelInfo(level, exp)
	if -1 == curExp or -1 == curNeedExp then
		self.viewData.satietyLabel:setString(__('max/max'))
		self.viewData.satietyBar:setMaxValue(100)
		self.viewData.satietyBar:setValue(100)
	else
		self.viewData.satietyLabel:setString(string.format('%d/%d', curExp, curNeedExp))
		self.viewData.satietyBar:setMaxValue(curNeedExp)
		self.viewData.satietyBar:setValue(curExp)
	end

	self:RefreshBeastBabyPropView(self:GetSelectedBeastBabyId())
end
--[[
显示喂养界面
@params fixedFoodsData table 修正后的菜品数据
@params feedFavoriteFoodBonus number 喜爱暴击倍数
--]]
function UnionBeastBabyDevScene:ShowFeedView(fixedFoodsData, feedFavoriteFoodBonus)
	local view = require('Game.views.union.UnionBeastBabyFeedSatietyView').new({
		targetNode = self,
		foodsData = fixedFoodsData,
		leftFeedPetNumber = checkint(unionMgr:getUnionData().leftFeedPetNumber),
		feedFavoriteFoodBonus = feedFavoriteFoodBonus
	})
	display.commonUIParams(view, {ap = cc.p(0.5, 0.5), po = cc.p(
		self:getContentSize().width * 0.5,
		self:getContentSize().height * 0.5
	)})
	view:setTag(FeedSatietyViewTag)
	self:addChild(view, 100)
	self.feedView = view

	-- 隐藏一些ui
	self.viewData.devLogBtn:setVisible(false)
	self.viewData.nextBtn:setVisible(false)
	self.viewData.prevBtn:setVisible(false)
end
--[[
关闭喂养界面
--]]
function UnionBeastBabyDevScene:HideFeedView()
	local feedView = self:getChildByTag(FeedSatietyViewTag)
	if nil ~= feedView then
		feedView:HideSelf()
	end

	-- 显示一些ui
	self.viewData.devLogBtn:setVisible(true)
	self:RefreshNextPrevBtn()
end
--[[
显示属性页
@params index 选中的神兽幼崽序号
--]]
function UnionBeastBabyDevScene:ShowPropertyView(index)
	if nil == self.viewData.propertyView then
		self:InitPropertyView()
	else
		self.viewData.propertyView:setVisible(true)
	end

	local beastBabyConfig = self:GetBeastBabyConfig(index)
	local beastBabyId = checkint(beastBabyConfig.id)

	self:RefreshBeastBabyPropView(beastBabyId)
end
--[[
隐藏属性页
--]]
function UnionBeastBabyDevScene:HidePropertyView()
	if nil ~= self.viewData.propertyView then
		self.viewData.propertyView:setVisible(false)
	end
end
--[[
根据神兽幼崽id刷新神兽属性界面
@params beastBabyId int 神兽幼崽id
--]]
function UnionBeastBabyDevScene:RefreshBeastBabyPropView(id)
	if nil == self.viewData.propertyView then return end
	local beastBabyData = self:GetBeastBabyDataById(id)
	if nil == beastBabyData then
		-- 隐藏属性页
		self:HidePropertyView()
	end
	------------ 刷新属性 ------------
	local allFixedP = cardMgr.GetBeastBabyAllFixedP(id, checkint(beastBabyData.energyLevel), checkint(beastBabyData.satietyLevel))
	for i,v in ipairs(PropsInfo) do
		local nodes = self.viewData.propertyViewPNodes[i]
		if nil ~= nodes then
			nodes.valueLabel:setString(tostring(allFixedP[v.p]))
		end
	end
	------------ 刷新属性 ------------

	------------ 刷新技能 ------------
	self.viewData.skillListView:removeAllNodes()

	local listViewSize = self.viewData.skillListView:getContentSize()
	local skills = {}
	local beastBabyConfig = cardMgr.GetBeastBabyConfig(id)
	if nil ~= beastBabyConfig.skill then
		for i,v in ipairs(beastBabyConfig.skill) do
			table.insert(skills, {skillId = checkint(v)})
		end
	end

	for i,v in ipairs(skills) do
		local skillId = checkint(v.skillId)
		local skillConfig = CommonUtils.GetSkillConf(skillId)
		if nil ~= skillConfig then
			local cellBg = display.newImageView(_res('ui/union/beastbaby/guild_pet_bg_skill_list.png'), 0, 0)

			local cellBgSize = cellBg:getContentSize()
			local cellSize = cc.size(listViewSize.width, cellBgSize.height + 10)

			local cell = display.newLayer(0, 0, {size = cellSize})
			-- cell:setBackgroundColor(cc.c4b(0, math.random(255), math.random(255), math.random(255)))

			display.commonUIParams(cellBg, {po = cc.p(
				cellSize.width * 0.5,
				cellSize.height * 0.5
			)})
			cell:addChild(cellBg)

			local skillNameLabel = display.newLabel(0, 0, fontWithColor('3', {text = tostring(skillConfig.name)}))
			display.commonUIParams(skillNameLabel, {ap = cc.p(0, 0.5), po = cc.p(
				5,
				cellBgSize.height - 15
			)})
			cellBg:addChild(skillNameLabel)

			local activeSkillStr = __('主动')
			if ConfigSkillType.SKILL_HALO == checkint(skillConfig.property) then
				activeSkillStr = __('被动')
			end
			local activeSkillLabel = display.newLabel(0, 0, fontWithColor('4', {text = activeSkillStr, color = '#9c4d28'}))
			display.commonUIParams(activeSkillLabel, {ap = cc.p(1, 0.5), po = cc.p(
				cellBgSize.width - 10,
				skillNameLabel:getPositionY()
			)})
			cellBg:addChild(activeSkillLabel)

			local skillDescrLabel = display.newLabel(0, 0,
				fontWithColor('6', {text = cardMgr.GetSkillDescr(skillId, checkint(beastBabyData.satietyLevel)), w = cellBgSize.width - 20, h = cellBgSize.height - 35, hAlign = display.TAL}))
			display.commonUIParams(skillDescrLabel, {ap = cc.p(0.5, 1), po = cc.p(
				cellBgSize.width * 0.5,
				cellBgSize.height - 35
			)})
			cellBg:addChild(skillDescrLabel)

			self.viewData.skillListView:insertNodeAtLast(cell)

		end
	end
	self.viewData.skillListView:reloadData()
	------------ 刷新技能 ------------
end
--[[
喂食行为
@params petId int 神兽幼崽id
@params satietyLevel int 饱食度等级
@params satietyExp int 饱食度经验值
@params leftAmount int 剩余数量
@params maxAmount int 最大数量
@params rewards list 获得的奖励
@params fixedFoodsData table 修正后的菜品数据
--]]
function UnionBeastBabyDevScene:DoFeed(petId, satietyLevel, satietyExp, leftAmount, maxAmount, rewards, fixedFoodsData)
	-- 刷新饱食度
	self:RefreshBeastBabySatietyLevel(satietyLevel, satietyExp)

	-- 刷新剩余次数
	self:RefreshLeftFeedAmount(leftAmount, maxAmount)

	local feedView = self:getChildByTag(FeedSatietyViewTag)
	if nil ~= feedView then
		feedView:DoFeed(leftAmount, maxAmount, rewards, fixedFoodsData)
	end
end
--[[
显示神兽幼崽升级spine
--]]
function UnionBeastBabyDevScene:ShowSatietyUp()
	PlayAudioClip(AUDIOS.UI.ui_star.id)

	if self.viewData.beastBabySpine then
		local upSpine = sp.SkeletonAnimation:create(
			'effects/pet/shengxing.json',
			'effects/pet/shengxing.atlas',
			1
		)
		upSpine:update(0)
		upSpine:setPosition(
			self.viewData.beastBabySpine:getPositionX(),
			self.viewData.beastBabySpine:getPositionY() + self.viewData.beastBabySpine:getBorderBox('viewBox').height * 0.5
		)
		self.viewData.beastBabySpine:getParent():addChild(upSpine, self.viewData.beastBabySpine:getLocalZOrder())

		upSpine:setAnimation(0, 'play2', false)

		-- 顺便说句话
		self:BabySpeak(UnionPetVoiceType.AFTER_FEED)
	end
end
--[[
让神兽说话
@params voiceType UnionPetVoiceType
--]]
function UnionBeastBabyDevScene:BabySpeak(voiceType)
	if nil ~= self.viewData.beastBabySpine then
		local beastBabyPos = cc.p(
			self.viewData.beastBabySpine:getPositionX(),
			self.viewData.beastBabySpine:getPositionY()
		)
		local beastBabyViewHeight = 0
		local beastBabyViewBox = self.viewData.beastBabySpine:getBorderBox('viewBox')
		if nil ~= beastBabyViewBox then
			beastBabyViewHeight = beastBabyViewBox.height
		end
		local targetPosition = self.viewData.beastBabySpine:getParent():convertToWorldSpace(cc.p(
			beastBabyPos.x, beastBabyPos.y + beastBabyViewHeight
		))

		local voiceConfig = cardMgr.GetUnionBeastBabyVoiceConfigByVoiceType(self:GetSelectedBeastBabyId(), voiceType)
		uiMgr:ShowDialogueBubble({
			targetPosition = targetPosition,
			descr = tostring(voiceConfig.descr),
			parentNode = self,
			zorder = 999,
			alwaysOnCenter = true,
			alwaysOnTop = true,
			ignoreOutside = true
		})
	end
end
--[[
让神兽做动作
--]]
function UnionBeastBabyDevScene:BabyAction()
	if nil ~= self.viewData.beastBabySpine then
		local randomActionAmount = 2
		local actionName = 'play' .. tostring(math.random(randomActionAmount))

		self.viewData.beastBabySpine:setToSetupPose()
		self.viewData.beastBabySpine:setAnimation(0, actionName, false)
		self.viewData.beastBabySpine:addAnimation(0, 'idle', true)
	end
end
--[[
刷新选菜栏的菜品数量
@params foodsData table 菜品信息
--]]
function UnionBeastBabyDevScene:RefreshByFoodsData(foodsData)
	self.feedView:RefreshByFoodsData(foodsData)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
查看属性按钮回调
--]]
function UnionBeastBabyDevScene:AttrBtnClickHandler(sender)
	PlayAudioByClickNormal()
	
	self:ShowPropertyView(self.selectedBeastBabyIndex)
end
--[[
养育记录按钮回调
--]]
function UnionBeastBabyDevScene:DevLogBtnClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('SHOW_UNION_FEED_LOG')
end
--[[
获取能量按钮回调
--]]
function UnionBeastBabyDevScene:EnergyBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local beastBabyId = self:GetSelectedBeastBabyId()
	AppFacade.GetInstance():DispatchObservers('SHOW_UNION_HUNT_BY_BEAST_BABY', {beastBabyId = beastBabyId})
end
--[[
喂食按钮回调
--]]
function UnionBeastBabyDevScene:SatietyBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local beastBabyId = self:GetSelectedBeastBabyId()
	AppFacade.GetInstance():DispatchObservers('SHOW_UNION_FEED_SATIETY', {beastBabyId = beastBabyId})
end
--[[
未解锁按钮回调
--]]
function UnionBeastBabyDevScene:UnlockBtnClickHandler(sender)
	PlayAudioByClickNormal()
end
--[[
翻页按钮回调
--]]
function UnionBeastBabyDevScene:NextPrevBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if 3 == tag then
		-- 下一页
		local index = math.min(#self.beastBabiesConfig, self.selectedBeastBabyIndex + 1)
		self:RefreshUIByIndex(index)
	elseif 5 == tag then
		-- 上一页
		local index = math.max(1, self.selectedBeastBabyIndex - 1)
		self:RefreshUIByIndex(index)
	end
end
--[[
能量提示按钮回调
--]]
function UnionBeastBabyDevScene:EnergyHintBtnClickHandler(sender)
	PlayAudioByClickNormal()
	uiMgr:ShowInformationTipsBoard({targetNode = sender, title = __('能量'), descr = cardMgr.GetBeastBabyEnergyDescr(), type = 5})
end
--[[
饱食度提示按钮回调
--]]
function UnionBeastBabyDevScene:SatietyHintBtnClickHandler(sender)
	PlayAudioByClickNormal()
	uiMgr:ShowInformationTipsBoard({targetNode = sender, title = __('饱食度'), descr = cardMgr.GetBeastBabySatietyDescr(), type = 5})
end
--[[
战斗力按钮回调
--]]
function UnionBeastBabyDevScene:BattlePointBtnClickHandler(sender)
	PlayAudioByClickNormal()
	uiMgr:ShowInformationTipsBoard({targetNode = sender, title = __('战斗力'), descr = cardMgr.GetBeastBabyBattlePoineDescr(), type = 5})
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- signal begin --
---------------------------------------------------
--[[
信号
--]]
function UnionBeastBabyDevScene:RegistHandler()
	------------ 喂食行为 ------------
	AppFacade.GetInstance():RegistObserver('UNION_BEASTBABY_DO_FEED', mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:DoFeed(checkint(data.leftFeedAmount), checkint(data.maxFeedAmount))
	end, self))
	------------ 喂食行为 ------------
end
function UnionBeastBabyDevScene:UnregistHandler()

end
---------------------------------------------------
-- signal end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据序号获取神兽幼崽配置
@params index int 序号
@return _ 神兽配置
--]]
function UnionBeastBabyDevScene:GetBeastBabyConfig(index)
	return self.beastBabiesConfig[index]
end
--[[
根据id获取神兽幼崽信息
@params id int 神兽幼崽信息
@return _ table 神兽信息
--]]
function UnionBeastBabyDevScene:GetBeastBabyDataById(id)
	for i,v in ipairs(self.beastBabiesData) do
		if id == checkint(v.petId) then
			return v
		end
	end
	return nil
end
--[[
获取当前选中的神兽幼崽信id
@return id int 神兽幼崽id
--]]
function UnionBeastBabyDevScene:GetSelectedBeastBabyId()
	return checkint(self:GetBeastBabyConfig(self.selectedBeastBabyIndex).id)
end
--[[
是否可以触摸
--]]
function UnionBeastBabyDevScene:GetCanTouch()
	return not self.viewData.coverBtn:isVisible()
end
function UnionBeastBabyDevScene:SetCanTouch(can)
	self.viewData.coverBtn:setVisible(not can)
end
---------------------------------------------------
-- get set end --
---------------------------------------------------
function UnionBeastBabyDevScene:onCleanup()
	print('here >>>UnionBeastBabyDevScene<<< onCleanup')
	self:UnregistHandler()
end

return UnionBeastBabyDevScene
