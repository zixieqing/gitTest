--[[
卡牌堕神层
--]]
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local petMgr = AppFacade.GetInstance():GetManager("PetManager")

local CardDetailPetNew = class('CardDetailPetNew', function ()
	local node = CLayout:create()
	node.name = 'home.CardDetailPetNew'
	node:enableNodeEvents()
	return node
end)
function CardDetailPetNew:ctor( ... )
	self.args = unpack({...})
	--------------------------------------
	-- ui
	 self.TotherLabel = {}
	 self.TBaseLabel = {}
	 self.TDataLayout = {}
	--------------------------------------
	-- ui data

	--------------------------------------
	-- data


	self.cardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
	self.petData = gameMgr:GetPetDataById(self.args.playerPetId) or nil
	self:initUI()
end
--初始化界面
function CardDetailPetNew:initUI()
	local bgSize = cc.size(515,display.size.height - 200)
	self:setContentSize(bgSize)
	-- self:setBackgroundColor(cc.c4b(0, 255, 128, 128))


	self:CreatePetMessViewNew()
end


function CardDetailPetNew:CreatePetMessViewNew()
	-- body
	local bgSize = self:getContentSize()
	local heroMessImg = display.newImageView(_res('ui/cards/propertyNew/card_attribute_bg_name.png'), 0, 0)
	display.commonUIParams(heroMessImg, {ap = cc.p(0.5, 1), po = cc.p(bgSize.width * 0.5,bgSize.height - 20 )})
	self:addChild(heroMessImg)
	heroMessImg:setCascadeOpacityEnabled(true)
   --卡牌类型
    local bgJob = display.newImageView(_res('ui/home/teamformation/choosehero/card_order_ico_selected.png'), 30, heroMessImg:getContentSize().height + 10,
            {ap = cc.p(0, 1)
        })
    bgJob:setScale(1.4)
    heroMessImg:addChild(bgJob,6)
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
	heroMessImg:addChild(fireSpine)
	fireSpine:setPosition(cc.p(heroMessImg:getContentSize().width - 85,heroMessImg:getContentSize().height - 18))


	local fightNum = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '')
	fightNum:setAnchorPoint(cc.p(0.5, 1))
	fightNum:setHorizontalAlignment(display.TAR)
	fightNum:setPosition(heroMessImg:getContentSize().width - 85,heroMessImg:getContentSize().height + 18)
	heroMessImg:addChild(fightNum,1)
	fightNum:setScale(0.7)
	self.fightNum = fightNum


	local nameLabel = display.newLabel(0, 0, {text = ('名字'), fontSize = 32, color = '#ffcc60',ttf = true, font = TTF_GAME_FONT, ap = cc.p(0,0)})
	display.commonUIParams(nameLabel, {po = cc.p(100,
		heroMessImg:getContentSize().height - 20 )})
	nameLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	heroMessImg:addChild(nameLabel,1)
	self.nameLabel = nameLabel

	local cvLabel = display.newLabel(0, 0, {text = ('cv:XXXX'), fontSize = 20, color = '#ffe5d7', ap = cc.p(0,1)})
	display.commonUIParams(cvLabel, {po = cc.p(100,
		heroMessImg:getContentSize().height - 34)})
	heroMessImg:addChild(cvLabel,1)
	self.cvLabel = cvLabel
	
	self.imgPet = AssetsUtils.GetCartoonNode(0, 0, 0, {ap = display.CENTER_BOTTOM})
	self.imgPet:setVisible(false)
	self:addChild(self.imgPet,1)
	
	local choosePetBtn = display.newButton(0, 0, {n = _res('ui/cards/petNew/card_pet_btn_pet_add.png'),enable = true})
	local petPos = cc.p( bgSize.width * 0.5,heroMessImg:getPositionY() - heroMessImg:getContentSize().height - choosePetBtn:getContentSize().height  )
 	display.commonUIParams(choosePetBtn, {animate = false, po = petPos, ap = display.CENTER_BOTTOM, cb = handler(self, self.choosePetBtnCallback)})
	choosePetBtn:setName('choosePetBtn')
	self:addChild(choosePetBtn,1)
	self.imgPet:setPosition(petPos)
 	self.addPet = choosePetBtn
 	-- self.clickLabel = choosePetBtn:getLabel()
 	-- self.clickLabel:setVisible(false)

	self.btnPosY = self.addPet:getPositionY()
 	self.qAvatar = nil
    local cardInfo = gameMgr:GetCardDataByCardId(self.args.cardId)
	local qAvatar  = AssetsUtils.GetCardSpineNode({skinId = cardInfo.defaultSkinId, scale = 0.5})
    qAvatar:update(0)
    qAvatar:setTag(1)
    qAvatar:setAnimation(0, 'idle', true)
    qAvatar:setPosition(cc.p(bgSize.width * 0.2, choosePetBtn:getPositionY()))
    self:addChild(qAvatar)
    self.qAvatar = qAvatar


    local desBtn = display.newButton(0, 0,
    	{n = _res('ui/cards/petNew/pet_info_bg_dialogue.png'),enabel = false, animate = false})--pet_info_ico_exclusive_pet_active
    display.commonUIParams(desBtn, {ap = cc.p(0.5,0),po = cc.p(bgSize.width * 0.6,self.btnPosY + 10)})
    display.commonLabelParams(desBtn, {text = __('快为我选择一个伙伴吧'), hAlign =display.TAC, w = 280,  ap = cc.p(0.5,0.5),fontSize = 22, color = '#5c5c5c',offset = cc.p(-40,0)})
    self:addChild(desBtn)
    self.desBtn = desBtn


    local petMessImg = display.newImageView(_res('ui/cards/petNew/card_attribute_bg.png'),0,  0 ,
            {ap = cc.p(0.5, 0.5)
        })

 	local petMessSize = petMessImg:getContentSize()
 	local petMessLayout = CLayout:create()
 	petMessLayout:setPosition(cc.p(bgSize.width * 0.5,  choosePetBtn:getPositionY()  + 50))
 	petMessLayout:setAnchorPoint(cc.p(0.5,1))
 	petMessLayout:setContentSize(petMessSize)
 	self:addChild(petMessLayout,1)
 	petMessLayout:addChild(petMessImg)
 	petMessImg:setPosition(utils.getLocalCenter(petMessLayout))
 	-- petMessLayout:setBackgroundColor(cc.c4b(0, 255, 128, 128))
	-- petMessLayout:setVisible(false)
	self.petMessLayout = petMessLayout

	local petLvBtn = display.newButton(0, 0, {n = _res('ui/cards/petNew/pet_info_bg_levelnum.png'),enable = false})
 	display.commonUIParams(petLvBtn, {po = cc.p( 130,petMessSize.height - 75 ),ap = cc.p(0.5,0.5)})
 	display.commonLabelParams(petLvBtn, {ttf = true,font = TTF_GAME_FONT,text = ('22'), fontSize = 24, color = '#ffffff'})
 	petMessLayout:addChild(petLvBtn,1)
 	self.petLvlabel = petLvBtn:getLabel()

	local petNamelabel = display.newLabel(petLvBtn:getPositionX()+petLvBtn:getContentSize().width*0.5 + 1,petLvBtn:getPositionY(),
		{text = '我是名字', fontSize = 20, color = '#ffffff',ttf = true,font = TTF_GAME_FONT, ap = cc.p(0, 0.5)})
	petMessLayout:addChild(petNamelabel,1)
	self.petNamelabel = petNamelabel


    for i=1,4 do
		local propLayout = CLayout:create()
		-- propLayout:setBackgroundColor((cc.c4b(0, 255, 128, 128)))
		propLayout:setAnchorPoint(cc.p(0.5, 0.5))
		propLayout:setPosition(cc.p( petMessSize.width * 0.5, petNamelabel:getPositionY() - 70 - 40*(i-1) ))
		petMessLayout:addChild(propLayout)

		local propBg = display.newImageView(_res('ui/common/card_bg_attribute_number.png'), 0, 0 ,
			{ap = cc.p(0.5, 0.5),scale9 = true,size = cc.size(420,40)})
		propBg:setTag(5)
		propLayout:addChild(propBg)
		propBg:setCascadeOpacityEnabled(true)
		local size = propBg:getContentSize()
		propLayout:setContentSize(size)
		propBg:setPosition(cc.p(size.width * 0.5,size.height * 0.5))


		local size = propBg:getContentSize()
    	local label = display.newLabel(50,size.height* 0.5,
			{text = __('攻击力：'), fontSize = 20, color = '#e2c0b5', ap = cc.p(0, 0.5)})
		propBg:addChild(label)
		label:setTag(6)

    	local label1 = display.newLabel(size.width - 50,size.height* 0.5,
			{text = ('+50'), fontSize = 20, color = '#e2c0b5', ap = cc.p(1, 0.5)})
		propBg:addChild(label1)
		label1:setTag(7)

    	local label3 = display.newLabel(size.width* 0.5,size.height* 0.5,fontWithColor(18,{text = ('达到多少等级解锁呢')}))
		propBg:addChild(label3)
		label3:setTag(8)
		label3:setVisible(false)


		local lineImg = display.newImageView(_res(_res('ui/cards/propertyNew/card_ico_attribute_line.png')),size.width * 0.5,size.height )
		lineImg:setAnchorPoint(cc.p(0.5,1))
		propLayout:addChild(lineImg,2)
		print(i%2)
		if i%2 == 0 then
			propBg:setOpacity(0)
		end

		table.insert(self.TDataLayout,propLayout)
	end

    local exclusiveBtn = display.newButton(0, 0,
    	{n = _res('ui/cards/petNew/pet_info_ico_exclusive_pet_normal.png'),enabel = true, animate = true})--pet_info_ico_exclusive_pet_active
    display.commonUIParams(exclusiveBtn, {ap = cc.p(0,1),po = cc.p(30, heroMessImg:getPositionY() - heroMessImg:getContentSize().height - 6)})
    display.commonLabelParams(exclusiveBtn, {text = __('专属堕神'), ap = cc.p(0.5,1),fontSize = 22, color = '#f8dc99',offset = cc.p(0,-25)})
    self:addChild(exclusiveBtn)
    self.exclusiveBtn = exclusiveBtn

	self:refreshUI(self.args)

end

--展示预览堕神
function CardDetailPetNew:showPetViewCallBack(data)
	self.showPetData = {}
	self.showPetData = data
	local cardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
	local petData = CommonUtils.GetConfig('goods', 'pet', data.petId)

	-- local localPetData = gameMgr:GetPetDataById(data.playerPetId)
	-- dump(self.petData)
	-- dump(petData)
	--堕神等级
	-- dump(data)
	self.petLvlabel:getParent():setVisible(true)
	self.petLvlabel:setString(tostring(data.level))
	self.petNamelabel:setString(string.fmt(('_name_ + _level_'),{_name_ = petData.name,_level_ = data.breakLevel}))


	if self.qAvatar then
		self.qAvatar:setVisible(false)
	end
	self.petMessLayout:setVisible(true)

	self.addPet:setPositionY(self.btnPosY)
	self.imgPet:setPositionY(self.btnPosY)
	self.desBtn:setVisible(false)
	display.commonLabelParams(self.addPet, {text = (' '), ap = cc.p(0.5,0.5),fontSize = 22, color = '#ffffff',offset = cc.p(0,70)})


	if data.petId then
		local petConf = CommonUtils.GetConfig('pet', 'pet', data.petId) or {}
		self.imgPet:setTexture(AssetsUtils.GetCartoonPath(petConf.drawId))
		if checkint(petConf.type) == 1 then
			self.imgPet:setScale(0.7)
  		else
			self.imgPet:setScale(0.5)
		end
		self.imgPet:setVisible(true)
		self.addPet:setOpacity(0)
	else
		self.imgPet:setVisible(false)
  		self.addPet:setOpacity(255)
	end

    local configData = petMgr.GetPetPInfo()
	for i,v in ipairs(self.TDataLayout ) do
		local propBg = v:getChildByTag(5)
		propBg:setVisible(false)
		local label = propBg:getChildByTag(6)
		local label1 = propBg:getChildByTag(7)
		local lockLabel = propBg:getChildByTag(8)

		if label1 then
			propBg:removeChild(label1)
		end

		if data then
			-- dump(self.petData)
			propBg:setVisible(true)
			-- if checkint(data.level) >= checkint(configData[i].unlockLevel) then
			local petMess = petMgr.GetPetAFixedProp(data.id, i)
			if petMess.unlock then
				local quailty = petMess.pquality or 1
				local extraAttrNum = petMess.pvalue  or 1
				local extraAttrType = petMess.ptype  or 1

				local size = propBg:getContentSize()
			    label1 = cc.Label:createWithBMFont(petMgr.GetPetPropFontPath(quailty), '')--
			    label1:setAnchorPoint(cc.p(1, 0.5))
			    label1:setHorizontalAlignment(display.TAR)
			    label1:setPosition(cc.p(size.width - 50,size.height* 0.5))
			    label1:setString('+'..extraAttrNum)
	    		propBg:addChild(label1)
				label1:setTag(7)

			    label:setString(PetPConfig[extraAttrType].name)
				label:setVisible(true)
				lockLabel:setVisible(false)
			else
				label:setVisible(false)
				lockLabel:setVisible(true)
				display.commonLabelParams(lockLabel ,{text =string.fmt(__('堕神等级达到_lv_级解锁'),{_lv_ = configData[i].unlockLevel  }) ,reqW = 420 })
			end
		end
	end
end


--选择堕神
function CardDetailPetNew:choosePetCallBack(data)
	-- print('eeheheheheeh')
	-- dump(data)
	-- dump(gameMgr:CanOperatePetById(self.args.id))
	local oldPlayerCardId = data.playerCardId
	if oldPlayerCardId and not gameMgr:CanOperatePetById(oldPlayerCardId) then
		local cardPlace = gameMgr:GetCardPlace({id = oldPlayerCardId})
		local name = gameMgr:GetModuleName(cardPlace) or __('当前飨灵正在进行其它任务')  ---'当前卡牌正在进行其他模块功能'
		uiMgr:ShowInformationTips(name)
		self:refreshUI(self.args, 1)
		return
	end

	if gameMgr:CanOperatePetById(self.args.id) then
		local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
		local temp = {}
		if data.operation == 1 then
			if oldPlayerCardId then--说明是从其他卡牌上拿下来给自己装备的 oldPlayerCardId 为该堕神之前所属卡牌id
				temp = { playerCardId = self.args.id,playerPetId = data.playerPetId,operation = data.operation,oldPlayerCardId = oldPlayerCardId}
			else
				temp = { playerCardId = self.args.id,playerPetId = data.playerPetId,operation = data.operation}
			end
		else
			temp = { playerCardId = self.args.id,playerPetId = data.playerPetId,operation = data.operation}
		end
		httpManager:Post("pet/mountPet",SIGNALNAMES.Hero_EquipPet_Callback,temp,true)

	else
		local cardPlace = gameMgr:GetCardPlace({id = self.args.id})
		local name = gameMgr:GetModuleName(cardPlace) or __('当前飨灵正在进行其它任务')  ---'当前卡牌正在进行其他模块功能'
		uiMgr:ShowInformationTips(name)
		self:refreshUI(self.args,1)
	end
end

function CardDetailPetNew:backListCallBack()
	self.showPetData =  nil
	self:refreshUI(self.args,1)
end

--选择打开堕神列表
function CardDetailPetNew:choosePetBtnCallback(pSender)
    PlayAudioByClickNormal()
	-- dump(self.args)
	-- print('ddd')
	 local isUnlock = CommonUtils.UnLockModule(JUMP_MODULE_DATA.PET , true )
	if not  isUnlock then
		return
	end
	local scene = uiMgr:GetCurrentScene()
	local tempData = self.args
	tempData.showCallback = handler(self, self.showPetViewCallBack)
	tempData.callback = handler(self, self.choosePetCallBack)
	tempData.backCallback = handler(self, self.backListCallBack)
	local viewComponent  = require( 'home.ChooesePetListView' ).new(tempData)
	viewComponent:setName('ChooesePetListView')
	viewComponent:setTag(111111)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent,3)
	GuideUtils.DispatchStepEvent()
end


--刷新界面
function CardDetailPetNew:refreshUI(data,colseListType)
	local bgSize = self:getContentSize()
	if data then
		self.args = data
	end
	self.cardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
	if self.args.playerPetId then
		-- dump(self.args)
		self.petData = gameMgr:GetPetDataById(self.args.playerPetId)
		-- dump(petData)

		if self.qAvatar then
			self.qAvatar:removeFromParent()
			self.qAvatar = nil
		end
		self.petMessLayout:setVisible(true)

		self.imgPet:setPositionY(self.btnPosY)
		self.addPet:setPositionY(self.btnPosY)
		self.desBtn:setVisible(false)
		display.commonLabelParams(self.addPet, {text = ' ', ap = cc.p(0.5,0.5),fontSize = 22, color = '#ffffff',offset = cc.p(0,70)})
	else
		self.petData = nil
		self.imgPet:setPositionY(self.btnPosY - 180)
		self.addPet:setPositionY(self.btnPosY - 180)
		display.commonLabelParams(self.addPet, {text = __('点击添加'), ap = cc.p(0.5,0.5),fontSize = 22, color = '#ffffff' })
		display.commonUIParams(self.addPet:getLabel() ,{ po = cc.p(105,0)})
		self.petMessLayout:setVisible(false)
		self.desBtn:setVisible(true)
		if self.qAvatar then
			self.qAvatar:removeFromParent()
			self.qAvatar = nil
		end
		if not self.qAvatar then
            local cardInfo = gameMgr:GetCardDataByCardId(self.args.cardId)
			local qAvatar = AssetsUtils.GetCardSpineNode({skinId = cardInfo.defaultSkinId, scale = 0.5})
		    qAvatar:update(0)
		    qAvatar:setTag(1)
		    qAvatar:setAnimation(0, 'idle', true)
		    qAvatar:setPosition(cc.p(bgSize.width * 0.2, self.addPet:getPositionY()))
		    self:addChild(qAvatar)
		    self.qAvatar = qAvatar
		end
	end

	--存在堕神列表界面说明属性有改动，需刷新列表ui
	if not colseListType and uiMgr:GetCurrentScene():GetDialogByTag(111111) then
		uiMgr:GetCurrentScene():GetDialogByTag(111111):UpdataUI()

		if self.showPetData then
			if self.qAvatar then
				self.qAvatar:removeFromParent()
				self.qAvatar = nil
			end
			self.petMessLayout:setVisible(true)

			self.imgPet:setPositionY(self.btnPosY)
			self.addPet:setPositionY(self.btnPosY)
			self.desBtn:setVisible(false)
			display.commonLabelParams(self.addPet, {text = (' '), ap = cc.p(0.5,0.5),fontSize = 22, color = '#ffffff',offset = cc.p(0,70)})
		end

	    local configData = petMgr.GetPetPInfo()
		for i,v in ipairs(self.TDataLayout ) do
			local propBg = v:getChildByTag(5)
			propBg:setVisible(false)
			local label = propBg:getChildByTag(6)
			local label1 = propBg:getChildByTag(7)
			local lockLabel = propBg:getChildByTag(8)

			if label1 then
				propBg:removeChild(label1)
			end

			if self.showPetData then
				-- dump(self.petData)
				propBg:setVisible(true)
				-- if checkint(data.level) >= checkint(configData[i].unlockLevel) then
				local petMess = petMgr.GetPetAFixedProp(self.showPetData.id, i)
				if petMess.unlock then
					local quailty = petMess.pquality or 1
					local extraAttrNum = petMess.pvalue  or 1
					local extraAttrType = petMess.ptype  or 1

					local size = propBg:getContentSize()
				    label1 = cc.Label:createWithBMFont(petMgr.GetPetPropFontPath(quailty), '')--
				    label1:setAnchorPoint(cc.p(1, 0.5))
				    label1:setHorizontalAlignment(display.TAR)
				    label1:setPosition(cc.p(size.width - 50,size.height* 0.5))
				    label1:setString('+'..extraAttrNum)
		    		propBg:addChild(label1)
					label1:setTag(7)

				    label:setString(PetPConfig[extraAttrType].name)
					label:setVisible(true)
					lockLabel:setVisible(false)
				else
					label:setVisible(false)
					lockLabel:setVisible(true)
					--lockLabel:setString(string.fmt(__('堕神等级达到_lv_级解锁'),{_lv_ = configData[i].unlockLevel}))
					display.commonLabelParams(lockLabel,{text = string.fmt(__('堕神等级达到_lv_级解锁'),{_lv_ = configData[i].unlockLevel  } ), reqW = 420})
				end
			end
		end
		return
	end
	-- dump(self.args)
	-- dump(self.petData)
	-- dump(self.cardData)

	--self.nameLabel:setString(self.cardData.name)
	--CommonUtils.SetNodeScale(self.nameLabel  , {width = 220 })
	self.nameLabel:setScale(tonumber(self.nameLabel.originalScale) or 1 )
	CommonUtils.SetCardNameLabelStringById(self.nameLabel, data.id, {font = TTF_GAME_FONT, fontSize = 32, outline = cc.c4b(0, 0, 0, 255), color = '#ffcc60', fontSizeN = 32, colorN = '#ffcc60'})
	CommonUtils.SetNodeScale(self.nameLabel , {width = 300 })
    self.bgJob:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(self.cardData.id))
	self.jobImg:setTexture(CardUtils.GetCardCareerIconPathByCardId(self.cardData.id))
	self.cvLabel:setString(CommonUtils.GetCurrentCvAuthorByCardId(self.cardData.id))


	local fightNums = cardMgr.GetCardStaticBattlePointById(checkint(self.args.id))
	-- local fightNums = cardMgr.GetCardStaticBattlePoint(self.args.cardId, self.args.level, self.args.breakLevel)
	self.fightNum:setString(fightNums)

	-- dump(self.petData)
	-- dump(petData)
	--堕神等级
	if self.petData then
		self.petLvlabel:getParent():setVisible(true)
		self.petLvlabel:setString(tostring(self.petData.level))

		local petConf = CommonUtils.GetConfig('pet', 'pet', self.petData.petId) or {}
		self.imgPet:setTexture(AssetsUtils.GetCartoonPath(petConf.drawId))
  		if checkint(petConf.type) == 1 then
  			self.imgPet:setScale(0.7)
  		else
  			self.imgPet:setScale(0.5)
		end
		self.imgPet:setVisible(true)
  		self.addPet:setOpacity(0)

  		local petData = CommonUtils.GetConfig('goods', 'pet', self.petData.petId)
  		self.petNamelabel:setString(string.fmt(('_name_ + _level_'),{_name_ = petData.name,_level_ = self.petData.breakLevel}))
	else
		self.petLvlabel:getParent():setVisible(false)
		self.petLvlabel:setString('')
		self.petNamelabel:setString('')
		self.imgPet:setVisible(false)
  		self.addPet:setOpacity(255)
	end

	local iconIds = {}
	local sss = string.split(self.cardData.exclusivePet, ';')
	for i,v in ipairs(sss) do
		local t = {}
		t.goodsId = v
		t.num = 1
		table.insert(iconIds,t)
	end

	-- dump(iconIds)
    self.exclusiveBtn:setOnClickScriptHandler(function( sender )
        PlayAudioByClickNormal()
        local descrStr = string.format(
        	__('本命堕神提供的属性额外增加%d%%，异化后可提升至%d%%。'),
        	math.floor(petMgr.GetExclusiveAddition() * 100),
        	math.floor(petMgr.GetExclusiveAddition(nil, 1) * 100)
        )
    	uiMgr:ShowInformationTipsBoard({targetNode = sender,title = __('专属堕神'),descr = descrStr, showAmount = false,iconIds = iconIds, type = 4})
    end)
	-- dump(self.petData)
	local isexclusivePet = app.petMgr:checkIsExclusivePet(self.args.id)

	if isexclusivePet then
		self.exclusiveBtn:setNormalImage(_res('ui/cards/petNew/pet_info_ico_exclusive_pet_active.png'))
		self.exclusiveBtn:setSelectedImage(_res('ui/cards/petNew/pet_info_ico_exclusive_pet_active.png'))
	else
		self.exclusiveBtn:setNormalImage(_res('ui/cards/petNew/pet_info_ico_exclusive_pet_normal.png'))
		self.exclusiveBtn:setSelectedImage(_res('ui/cards/petNew/pet_info_ico_exclusive_pet_normal.png'))
	end

    local configData = petMgr.GetPetPInfo()
	for i,v in ipairs(self.TDataLayout ) do
		local propBg = v:getChildByTag(5)
		propBg:setVisible(false)
		local label = propBg:getChildByTag(6)
		local label1 = propBg:getChildByTag(7)
		local lockLabel = propBg:getChildByTag(8)

		if label1 then
			propBg:removeChild(label1)
		end

		if self.petData then
			propBg:setVisible(true)

			local petMess = petMgr.GetPetAFixedProp(self.petData.id, i,isexclusivePet )
			if petMess.unlock then
				local quailty = petMess.pquality or 1
				local extraAttrNum = petMess.pvalue  or 1
				local extraAttrType = petMess.ptype  or 1

				local size = propBg:getContentSize()
			    label1 = cc.Label:createWithBMFont(petMgr.GetPetPropFontPath(quailty), '')--
			    label1:setAnchorPoint(cc.p(1, 0.5))
			    label1:setHorizontalAlignment(display.TAR)
			    label1:setPosition(cc.p(size.width - 50,size.height* 0.5))
			    label1:setString('+'..extraAttrNum)
	    		propBg:addChild(label1)
				label1:setTag(7)
			    label:setString(PetPConfig[extraAttrType].name)
				label:setVisible(true)
				lockLabel:setVisible(false)
			else
				label:setVisible(false)
				lockLabel:setVisible(true)
				display.commonLabelParams(lockLabel,{text = string.fmt(__('堕神等级达到_lv_级解锁'),{_lv_ = configData[i].unlockLevel  }), reqW =420})
			end
		end
	end


end

function CardDetailPetNew:onCleanup()
	
	local scene = uiMgr:GetCurrentScene()
	local view = scene:GetDialogByTag(111111)
	if view and not tolua.isnull(view) then
		scene:RemoveDialog(view)
	end

end

return CardDetailPetNew
