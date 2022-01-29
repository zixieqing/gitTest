--[[
卡牌详情属性层
@params table {
	id int card id
	lv int card level
	breakLv int breakLv
	exp int card exp
}
--]]
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type PetManager
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
---@type ArtifactManager
local artifactMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
local CardDetailProperty = class('CardDetailProperty', function ()
	local node = CLayout:create()
	node.name = 'home.CardDetailProperty'
	node:enableNodeEvents()
	return node
end)

function CardDetailProperty:ctor( ... )
	self.args = unpack({...}) or {}
	-- dump(self.args)
	--------------------------------------
	-- ui

	self.showLevelUpAction = false

	--------------------------------------
	-- ui data
	self.propertyData = {
		{pName = ObjP.ATTACK, 		name = __('攻击力'), addLabel = nil, arrowImg = nil,	label = nil,path = 'ui/common/role_main_att_ico.png'},
		{pName = ObjP.DEFENCE, 		name = __('防御力'), addLabel = nil, arrowImg = nil,	label = nil,path = 'ui/common/role_main_def_ico.png'},
		{pName = ObjP.HP, 			name = __('生命值'), addLabel = nil, arrowImg = nil,	label = nil,path = 'ui/common/role_main_hp_ico.png'},
		{pName = ObjP.CRITRATE, 	name = __('暴击率'), addLabel = nil, arrowImg = nil,	label = nil,path = 'ui/common/role_main_baoji_ico.png'},
		{pName = ObjP.CRITDAMAGE, 	name = __('暴击伤害'), addLabel = nil, arrowImg = nil, label = nil,path = 'ui/common/role_main_baoshangi_ico.png'},
		{pName = ObjP.ATTACKRATE, 	name = __('攻击速度'), addLabel = nil, arrowImg = nil, label = nil,path = 'ui/common/role_main_speed_ico.png'}
	}
	self.tipMessage = {
		attack     = __('影响飨灵的攻击数值，攻击力越高，造成的伤害越大。'),
		defence    = __('可以减少敌方普通攻击造成的伤害。'),
		hp         = __('可以提高飨灵的生存能力。'),
		critRate   = __('可以增加普通攻击的暴击概率。'),
		critDamage = __('可以增加普通攻击暴击时所造成的伤害。'),
		attackRate = __('可以加快普通攻击的速度，有概率影响基础技的触发。')
	}
	--------------------------------------
	-- data
	self.cardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)

	self:initUI()
end
function CardDetailProperty:initUI()
	local bgSize = cc.size(515,display.size.height - 200)

	self:setContentSize(bgSize)
	-- self:setBackgroundColor(cc.c4b(100, 122, 122, 255))
	self:createLevelUpViewNew()
end


function CardDetailProperty:createLevelUpViewNew()
	-- body
	local bgSize = self:getContentSize()

	local upMessImg = display.newImageView(_res('ui/cards/propertyNew/card_attribute_bg_name.png'), 0, 0)
	display.commonUIParams(upMessImg, {ap = cc.p(0.5, 1), po = cc.p(bgSize.width * 0.5,bgSize.height - 20 )})
	self:addChild(upMessImg)
	upMessImg:setCascadeOpacityEnabled(true)
   --卡牌类型
    local bgJob = display.newImageView(_res('ui/home/teamformation/choosehero/card_order_ico_selected.png'), 30, upMessImg:getContentSize().height + 10,
            {ap = cc.p(0, 1)
        })
    bgJob:setScale(1.4)
    upMessImg:addChild(bgJob,6)
    -- bgJob:setCascadeOpacityEnabled(true)
    local jobImg = display.newImageView(_res('ui/home/teamformation/card_job_arrow.png'),utils.getLocalCenter(bgJob).x - 8,  utils.getLocalCenter(bgJob).y - 4 ,
            {ap = cc.p(0.5, 0.5)
        })
   	bgJob:addChild(jobImg)
   	self.bgJob = bgJob
   	self.jobImg = jobImg

	local fireSpine = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
	fireSpine:update(0)
	fireSpine:setAnimation(0, 'huo', true)--shengxing1 shengji
	upMessImg:addChild(fireSpine)
	fireSpine:setPosition(cc.p(upMessImg:getContentSize().width - 85,upMessImg:getContentSize().height - 18))



	local fightNum = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '')
	fightNum:setAnchorPoint(cc.p(0.5, 1))
	fightNum:setHorizontalAlignment(display.TAR)
	fightNum:setPosition(upMessImg:getContentSize().width - 85,upMessImg:getContentSize().height + 18)
	upMessImg:addChild(fightNum,1)
	fightNum:setScale(0.7)
	self.fightNum = fightNum

	self.unchangableNamePos = 100
	self.alterNamePos = 134
	local nameLabel = display.newLabel(0, 0, {text = ('名字'), fontSize = 32, color = '#ffcc60',ttf = true, font = TTF_GAME_FONT, ap = cc.p(0,0)})
	display.commonUIParams(nameLabel, {po = cc.p(self.alterNamePos, upMessImg:getContentSize().height - 20 )})
	nameLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	upMessImg:addChild(nameLabel,1)
	self.nameLabel = nameLabel
	self.nameLabelParams = {font = TTF_GAME_FONT, fontSize = 32, outline = cc.c4b(0, 0, 0, 255), color = '#ffcc60', fontSizeN = 32, colorN = '#ffcc60'}

	local nameLabelPos = self:convertToNodeSpace(upMessImg:convertToWorldSpace(cc.p(self.unchangableNamePos,nameLabel:getPositionY())))

    local alterNicknameBtn = display.newButton(nameLabelPos.x + 14, nameLabelPos.y - 17,
    	{n = _res('ui/home/infor/setup_btn_name_revise'), animate = true, cb = handler(self, self.AlterNicknameBtnCallback)})
	self:addChild(alterNicknameBtn,3)
	alterNicknameBtn:setVisible(false)
	alterNicknameBtn:setEnabled(false)
	self.alterNicknameBtn = alterNicknameBtn
	
	local cvLabel = display.newLabel(0, 0, {  text = ('cv:XXXX'), fontSize = 20, color = '#ffe5d7', ap = cc.p(0,1)})
	display.commonUIParams(cvLabel, {po = cc.p(140,
		upMessImg:getContentSize().height - 34)})
	upMessImg:addChild(cvLabel,1)
	self.cvLabel = cvLabel

	local bottomMessImg = display.newImageView(_res('ui/cards/propertyNew/card_attribute_bg.png'), 0, 0)
	display.commonUIParams(bottomMessImg, {ap = cc.p(0.5, 1), po = cc.p(bgSize.width * 0.5, upMessImg:getPositionY() - upMessImg:getContentSize().height - 6 )})
	self:addChild(bottomMessImg)
	bottomMessImg:setCascadeOpacityEnabled(true)
	local bottomMessImgSize = bottomMessImg:getContentSize()
	local bottomMessLayout = display.newLayer(bgSize.width * 0.5, upMessImg:getPositionY() - upMessImg:getContentSize().height - 6 , {ap  = display.CENTER_TOP , size = bottomMessImgSize })
	self:addChild(bottomMessLayout)
	-- local tempLabel = display.newLabel(0, 0, {text = __('飨灵属性'), fontSize = 20, color = '#ffffff', ap = cc.p(0.5, 1)})
	-- display.commonUIParams(tempLabel, {po = cc.p(bottomMessImg:getContentSize().width * 0.5 - 2,
	-- 	bottomMessImg:getContentSize().height - 40)})
	-- bottomMessImg:addChild(tempLabel,1)



	local pos = cc.p(40, bottomMessImg:getContentSize().height * 0.750)
	-- property 属性
	for i,v in ipairs(self.propertyData) do
		local pImg = display.newImageView(_res(v.path), 0, 0)
		display.commonUIParams(pImg, {ap = cc.p(0, 0.5), po = cc.p(pos.x ,--+ (i + 1) % 2 * bgSize.width * 0.45,
			pos.y - 70 - ((i - 1) * 44))})--math.ceil(i / 2)
		bottomMessLayout:addChild(pImg,1)
		pImg:setName(CardUtils.GetCardPCommonName(v.pName))
		pImg:setTouchEnabled(true)
		pImg:setOnClickScriptHandler(
		function (sender)
			local name  = sender:getName()
			local str = self.tipMessage[name] or ""
			uiMgr:ShowInformationTipsBoard({targetNode = sender, descr = str, type = 5})
		end)
		local pNameLabel = display.newLabel(0, 0, {text = v.name, fontSize = 20, color = '#e2c0b5', ap = cc.p(0, 0.5)})
		display.commonUIParams(pNameLabel, {po = cc.p(pImg:getPositionX() + 10 + pImg:getContentSize().width,
			pImg:getPositionY())})
		bottomMessImg:addChild(pNameLabel,1)

		local propertyLabel = display.newLabel(pos.x + bottomMessImg:getContentSize().width - 160, pNameLabel:getPositionY(),
			{text = tostring(0), fontSize = 20, color = '#e2c9bf', ap = cc.p(1, 0.5)})
		bottomMessImg:addChild(propertyLabel,1)
		v.label = propertyLabel

		local arrowImg = display.newImageView(_res(_res('ui/cards/propertyNew/card_ico_green_arrow.png')),pos.x + bottomMessImg:getContentSize().width - 140, pNameLabel:getPositionY())
		arrowImg:setAnchorPoint(cc.p(0.5,0.5))
		bottomMessImg:addChild(arrowImg,1)
		v.arrowImg = arrowImg
		arrowImg:setVisible(false)

		local a = cc.MoveBy:create(0.5,cc.p(-4,0))
		local b = a:reverse()
		local c = cc.Sequence:create(a,b)
		arrowImg:runAction(cc.RepeatForever:create(c))

		local addPropertyLabel = display.newLabel(pos.x + bottomMessImg:getContentSize().width - 120, pNameLabel:getPositionY(),
			{text = '+12', fontSize = 20, color = '#66b526', ap = cc.p(0, 0.5)})
		bottomMessImg:addChild(addPropertyLabel,1)
		addPropertyLabel:setVisible(false)
		v.addLabel = addPropertyLabel




		local lineImg = display.newImageView(_res(_res('ui/cards/propertyNew/card_ico_attribute_line.png')),pos.x, pNameLabel:getPositionY() - 20)
		lineImg:setAnchorPoint(cc.p(0,0.5))
		bottomMessImg:addChild(lineImg,1)

		if i%2 == 0 then
			local bg = display.newImageView(_res(_res('ui/common/card_bg_attribute_number.png')),pos.x, pNameLabel:getPositionY()+1,{scale9 = true,size = cc.size(390,45)})
			bg:setAnchorPoint(cc.p(0,0.5))
			bottomMessImg:addChild(bg)
		end

	end

	--卡牌升星
	local cardConf = CONF.CARD.CARD_INFO:GetValue(self.args.cardId)
	local num = CommonUtils.GetConfig('cards', 'cardBreak',cardConf.qualityId).breakConsume[self.args.breakLevel+1] or 0
	local goodsid = checkint(cardConf.fragmentId)
	local compeNum = gameMgr:GetAmountByGoodId(goodsid) - num

	local layout = CLayout:create()
	-- layout:setBackgroundColor((cc.c4b(0, 255, 128, 128)))
	layout:setAnchorPoint(cc.p(0.5, 1))
	layout:setPosition(bottomMessImg:getPosition())
	local size = bottomMessImg:getContentSize()
	layout:setContentSize(size)
	-- layout:setCascadeOpacityEnabled(true)

	self:addChild(layout,10)

	--卡牌碎片
	local goodIcon = require('common.GoodNode').new({id = goodsid, amount = num, showAmount = false})
	goodIcon:setScale(0.8)
	goodIcon:setAnchorPoint(cc.p(0, 1))
	goodIcon:setTouchEnabled(true)
	goodIcon:setPosition(cc.p(20,size.height - 35))
	layout:addChild(goodIcon,1)
	layout:setVisible(true)
	-- goodIcon:setOnClickScriptHandler(function (sender)
		-- if compeNum <= 0 then
			-- print('******* 跳转获取该货币页面 **********')
			-- uiMgr:AddDialog("common.GainPopup", {goodId = goodsid})
			-- uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsid, type = 1})
		-- end
	-- end)
	-- goodIcon:setState( compeNum )
	self.goodIcon = goodIcon
	--卡牌碎片m名称
	local fragmentNameLabel = display.newLabel(0, 0, {text = ('XXX碎片'), fontSize = 20, color = '#ebd6ba', ap = cc.p(0, 0.5)})
	display.commonUIParams(fragmentNameLabel, {po = cc.p(goodIcon:getPositionX() + goodIcon:getContentSize().width - 10 ,size.height - 40)})
	layout:addChild(fragmentNameLabel,1)
	self.fragmentNameLabel = fragmentNameLabel

	--拥有碎片进度
	local expBarBg = display.newImageView(_res('ui/cards/propertyNew/card_attribute_bg_star.png'))
	display.commonUIParams(expBarBg, {po = cc.p(goodIcon:getPositionX() + 210,size.height - 80)})
	layout:addChild(expBarBg, 5)
	-- expBarBg:setCascadeOpacityEnabled(true)

	local expBar = cc.ProgressTimer:create(cc.Sprite:create(_res('ui/cards/propertyNew/card_attribute_ico_loading_star.png')))
 	expBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
 	expBar:setMidpoint(cc.p(0, 0))
 	expBar:setBarChangeRate(cc.p(1, 0))
	expBar:setPosition(utils.getLocalCenter(expBarBg))
	expBar:setPercentage(50)
    expBarBg:addChild(expBar)
    self.expBar = expBar
    -- expBar:setCascadeOpacityEnabled(true)

    local upstarBtn = display.newButton(0, 0,
    	{n = _res('ui/common/common_btn_orange.png'), animate = true, cb = handler(self, self.breakBtnCallback)})
    display.commonUIParams(upstarBtn, {ap = cc.p(0,0.5),po = cc.p(expBarBg:getPositionX() + expBarBg:getContentSize().width * 0.5 - 4, size.height - 80)})
    display.commonLabelParams(upstarBtn, fontWithColor(14,{text = __('升星'), offset = cc.p(0, 10), reqW = 120}))
    layout:addChild(upstarBtn,6)
    self.upstarBtn = upstarBtn
    -- upstarBtn:setTag(4)

	local needFragmentNumLabel = display.newLabel(0, 0, {text = ('1000/1000'), fontSize = 20, color = '#ffffff', ap = cc.p(0.5, 0.5)})
	display.commonUIParams(needFragmentNumLabel, {po = cc.p(expBarBg:getContentSize().width * 0.5 ,expBarBg:getContentSize().height * 0.5)})
	expBarBg:addChild(needFragmentNumLabel,1)
	self.needFragmentNumLabel = needFragmentNumLabel



	local needGoldNumLabel = display.newLabel(0, 0, {text = ('1000'), fontSize = 20, color = '#ffffff', ap = cc.p(0.5, 0)})
	display.commonUIParams(needGoldNumLabel, {po = cc.p(upstarBtn:getContentSize().width * 0.5 - 10 ,6)})
	upstarBtn:addChild(needGoldNumLabel,1)
	self.needGoldNumLabel = needGoldNumLabel

	--拥有碎片进度
	local goldImg = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)))
	display.commonUIParams(goldImg, {po = cc.p(needGoldNumLabel:getPositionX() + needGoldNumLabel:getBoundingBox().width *0.5  + 2,6)})
	goldImg:setScale(0.15)
	goldImg:setAnchorPoint(cc.p(0,0))
	upstarBtn:addChild(goldImg, 5)
	self.goldImg = goldImg


	self:refreshUI(self.args)
end

--刷新页面
function CardDetailProperty:refreshUI(data)
	local oldLevel = 1
	if data then
		self.args = data
		self.cardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
	end
	self:refreshStarUI()
	-- dump(self.cardData)
	self.alterNicknameBtn:setVisible(cardMgr.GetCouple(data.id) and (not CardUtils.IsLinkCard( self.args.cardId)) )
	self.alterNicknameBtn:setEnabled(cardMgr.GetCouple(data.id)and (not CardUtils.IsLinkCard( self.args.cardId)))
	self.nameLabel:setPositionX((cardMgr.GetCouple(data.id) and  (not CardUtils.IsLinkCard( self.args.cardId)) ) and self.alterNamePos or self.unchangableNamePos)
	CommonUtils.SetCardNameLabelStringById(self.nameLabel, data.id, self.nameLabelParams)
	CommonUtils.SetNodeScale(self.nameLabel , {width = 300 })
    self.bgJob:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(self.args.cardId))
	self.jobImg:setTexture(CardUtils.GetCardCareerIconPathByCardId(self.args.cardId))
	self.cvLabel:setString( CommonUtils.GetCurrentCvAuthorByCardId(self.args.cardId))
	local fightNums = cardMgr.GetCardStaticBattlePointById(checkint(self.args.id))
	self.fightNum:setString(fightNums)


	local allAddP = app.cardMgr.GetCardAllFixedPById(self.args.id)

	for i,v in ipairs(self.propertyData) do
		v.addLabel:setVisible(false)
		v.arrowImg:setVisible(false)
		local num =  allAddP[v.pName]
		v.label:setString(tostring(num))
	end


	local cardConf  = CONF.CARD.CARD_INFO:GetValue(self.args.cardId)
	local goodsid   = checkint(cardConf.fragmentId)
	local goodsConf = CommonUtils.GetConfig('goods', 'goods', goodsid)
	self.goodIcon:RefreshSelf({goodsId = goodsid,amount = 10})
	self.goodIcon:setOnClickScriptHandler(function (sender)
        PlayAudioByClickNormal()
		uiMgr:AddDialog("common.GainPopup", {goodId = goodsid})
	end)
	--self.fragmentNameLabel:setString(goodsConf.name)
	display.commonLabelParams(self.fragmentNameLabel, {text = goodsConf.name , w= 220})
	--是否可以升星
	local canUpStar = false

	local  breakLevel = self.args.breakLevel
	if checkint(breakLevel)+1 >= table.nums(cardConf.breakLevel) then
		canUpStar = false
		self.upstarBtn:getLabel():setPositionY(self.upstarBtn:getContentSize().height * 0.5)
		self.expBar:setPercentage(100)
		self.needFragmentNumLabel:setString(__('已达到最高突破等级'))
		self.needGoldNumLabel:setVisible(false)
		self.goldImg:setVisible(false)
	else
		self.upstarBtn:getLabel():setPositionY(self.upstarBtn:getContentSize().height * 0.5 + 10)
		self.needGoldNumLabel:setVisible(true)
		self.goldImg:setVisible(true)
		local percent = 0
		local cardConf = CONF.CARD.CARD_INFO:GetValue(self.args.cardId)
		local num =CommonUtils.GetConfig('cards', 'cardBreak',cardConf.qualityId).breakConsume[self.args.breakLevel+1] or 0
		percent = gameMgr:GetAmountByGoodId(goodsid) / num * 100
		self.expBar:setPercentage(percent)


		self.needFragmentNumLabel:setString(string.format('%d/%d',gameMgr:GetAmountByGoodId(goodsid),num))
		local num1 = CommonUtils.GetConfig('cards', 'cardBreak',cardConf.qualityId).breakGoldConsume[self.args.breakLevel+1] or 0
		self.needGoldNumLabel:setString(num1)
		self.goldImg:setPositionX(self.needGoldNumLabel:getPositionX() + self.needGoldNumLabel:getBoundingBox().width *0.5 + 2)

		if checkint(gameMgr:GetAmountByGoodId(goodsid)) >= checkint(num) and checkint(gameMgr:GetUserInfo().gold) >= checkint(num1) then
			canUpStar = true
		else
			canUpStar = false
		end
	end
	display.commonLabelParams(self.needFragmentNumLabel ,{reqW = 210})
	if canUpStar == true then
		local bookData = app.cardMgr.GetBookDataByCardId(self.args.cardId)
		local equippedHouseCatGene = CatHouseUtils.GetEquippedCatGene()
		local tab = CardUtils.GetCardAllFixedP(
			self.args.cardId, self.args.level, self.args.breakLevel, self.args.favorLevel,
			self.args.pets, self.args.artifactTalent, bookData, equippedHouseCatGene
		)

		local tab1 = CardUtils.GetCardAllFixedP(
			self.args.cardId, self.args.level, self.args.breakLevel + 1, self.args.favorLevel,
			self.args.pets, self.args.artifactTalent, bookData, equippedHouseCatGene
		)

		for i,v in ipairs(self.propertyData) do
			v.addLabel:setString(tostring(tab1[v.pName] - tab[v.pName]))
			v.addLabel:setVisible(true)
			v.arrowImg:setVisible(true)
			if checkint(tab1[v.pName]) == checkint(tab[v.pName]) then
				v.addLabel:setVisible(false)
				v.arrowImg:setVisible(false)
			end
		end

	end
end

--刷新星级
function CardDetailProperty:refreshStarUI() --breakLevel
	if  self.args.BshowStarUpAction and self.args.BshowStarUpAction == true then
		self.args.BshowStarUpAction = false

		--战斗力呼吸效果
		local a = cc.ScaleTo:create(0.2,1.4)
		local b = cc.ScaleTo:create(0.2,0.7)
		local c = cc.Sequence:create(a,b)
		self.fightNum:runAction(c)

		local scene = uiMgr:GetCurrentScene()
		-- scene:RemoveViewForNoTouch()
		local sequenceAction = cc.Sequence:create(cc.CallFunc:create(function ()
				local btnSpine = sp.SkeletonAnimation:create('effects/shengxing/shengxing.json', 'effects/shengxing/shengxing.atlas', 1)
				btnSpine:update(0)
				btnSpine:setAnimation(0, 'shengxing1', false)--shengxing1 shengji
				self.upstarBtn:getParent():addChild(btnSpine,100)
				btnSpine:setPosition(cc.p(self.upstarBtn:getPositionX()-280,self.upstarBtn:getPositionY()))

				btnSpine:registerSpineEventHandler(function (event)
			        if event.animation == "shengxing1" then
			            print("====== hit end ====")
			            btnSpine:runAction(cc.RemoveSelf:create())
			        end
			    end, sp.EventType.ANIMATION_END)
			end),
			cc.DelayTime:create(1.3),
			cc.CallFunc:create(function ()
				local btnSpine = sp.SkeletonAnimation:create('effects/shengxing/shengxing.json', 'effects/shengxing/shengxing.atlas', 1)
				btnSpine:update(0)
				btnSpine:setAnimation(0, 'shengxing2', false)
				scene:addChild(btnSpine,100)
				btnSpine:setPosition(cc.p(0,0))

				btnSpine:registerSpineEventHandler(function (event)
					if event.animation == "shengxing2" then
						btnSpine:runAction(cc.RemoveSelf:create())
					end
				end,sp.EventType.ANIMATION_END)
			end),
			cc.DelayTime:create(0.4),
			cc.CallFunc:create(function ()
				local btnSpine = sp.SkeletonAnimation:create('effects/shengxing/shengxing.json', 'effects/shengxing/shengxing.atlas', 1)
				btnSpine:update(0)
				btnSpine:setAnimation(0, 'shengxing3', false)
				scene:addChild(btnSpine,100)
				btnSpine:setPosition(cc.p(display.SAFE_L + 52,display.size.height -192  - 45*(self.args.breakLevel-1)))

				btnSpine:registerSpineEventHandler(function (event)
					if event.animation == "shengxing3" then
						btnSpine:runAction(cc.RemoveSelf:create())
					end
				end,sp.EventType.ANIMATION_END)
			end),
			cc.CallFunc:create(function ()
				AppFacade.GetInstance():DispatchObservers(CardDetail_StarUp_callback)
			end),
			cc.DelayTime:create(0.5),
			cc.CallFunc:create(function ()
				AppFacade.GetInstance():DispatchObservers(CardDetail_ShowStar_callback)
			end),
			cc.CallFunc:create(function ()
				local scene = uiMgr:GetCurrentScene()
				scene:RemoveViewForNoTouch()
			end)
			)
		self:runAction(sequenceAction)
	end
end

--升级按钮回调
function CardDetailProperty:breakBtnCallback(pSender)
    PlayAudioByClickNormal()
	if CommonUtils.UnLockModule(RemindTag.CARDBREAKLVUP, true) then
		local cardConf = CONF.CARD.CARD_INFO:GetValue(self.args.cardId)

		if checkint(self.args.breakLevel)+1 >= table.nums(CommonUtils.GetConfig('cards', 'card',self.args.cardId).breakLevel) then
			uiMgr:ShowInformationTips(__('已达到最高突破等级'))
		else
			if checkint(gameMgr:GetAmountByGoodId(cardConf.fragmentId)) >= checkint(CommonUtils.GetConfig('cards', 'cardBreak',cardConf.qualityId).breakConsume[self.args.breakLevel+1]) and gameMgr:GetUserInfo().gold >= checkint(CommonUtils.GetConfig('cards', 'cardBreak',cardConf.qualityId).breakGoldConsume[self.args.breakLevel+1]) then
				local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
				httpManager:Post("card/cardBreakUp",SIGNALNAMES.Hero_Break_Callback,{ playerCardId = self.args.id})
			else
				if checkint(gameMgr:GetAmountByGoodId(cardConf.fragmentId)) < checkint(CommonUtils.GetConfig('cards', 'cardBreak',cardConf.qualityId).breakConsume[self.args.breakLevel+1]) then
					uiMgr:ShowInformationTips(__('所需材料不足'))
				else
					uiMgr:ShowInformationTips(__('所需金币不足'))
				end


			end
		end
	end
	--]]
end

function CardDetailProperty:AlterNicknameBtnCallback(pSender)
    PlayAudioByClickNormal()

	app.uiMgr:AddChangeNamePopup({
        renameCB  = function(newName)
            AppFacade.GetInstance():DispatchSignal(POST.ALTER_CARD_NICKNAME.cmdName , {cardName = newName, playerCardId = checkint(self.args.id)})
        end,
        title        = __("飨灵昵称"),
        preName      = CommonUtils.GetCardNameById(self.args.id),
    })
end

return CardDetailProperty
