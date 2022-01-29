--[[
卡牌技能属性层
@params table {
	id int card id
	lv int card level
	breakLv int breakLv
	exp int card exp
}
--]]
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local CardDetailSkillNew = class('CardDetailSkillNew', function ()
	local node = CLayout:create()
	-- node:setBackgroundColor(cc.c4b(0, 0, 0, 100))
	node.name = 'home.CardDetailSkillNew'
	node:enableNodeEvents()
	return node
end)
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")


local posData = {
    ['1'] = {cc.p(83,190),cc.p(380,190),cc.p(233,251),cc.p(233,85)}, -- 坦克
    ['2'] = {cc.p(102,220),cc.p(364,232),cc.p(238,118),cc.p(227,292)}, -- 近战dps
    ['3'] = {cc.p(130,265),cc.p(339,81),cc.p(289,233),cc.p(171,121)}, -- 远程dps
    ['4'] = {cc.p(146,103),cc.p(378,290),cc.p(151,247),cc.p(370,130)}, -- 治疗
    ['5'] = {cc.p(242,192),cc.p(99,108),cc.p(348,300),cc.p(366,110)} --餐厅技能
}

function CardDetailSkillNew:ctor( ... )
	self.args = unpack({...})
	-- dump(self.args)

	--------------------------------------
	-- ui
	--------------------------------------
	-- ui data
	self.isRefresh = false --是否升级刷新界面
	self.clickTag = 1-- 当前点击技能tag

	self.TskillLayout = {} -- 技能layout
	self.TskillNeedItems = {} -- 升级技能所需items
	self.TSkillDataTab = {}	--技能data


	self.TBusinessSkillDataTab = {}	--经营技能data

	-- self.showAction = false
	self.isEnough = true --是否满足升级条件
	self.clickModelTag = 1 --当前显示什么模块技能 1：战斗 2：餐厅
	--------------------------------------
	-- data

	self:initUI()

	AppFacade.GetInstance():RegistObserver(EVENT_GOODS_COUNT_UPDATE, mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:updateBottomViewNew(self.clickTag)
	end, self))
end
function CardDetailSkillNew:initUI()
	local bgSize = cc.size(515,display.size.height - 200)
	self:setContentSize(bgSize)
	-- self:setBackgroundColor(cc.c4b(0, 255, 128, 128))

    if not self.args.skill then
    	return
    end

	for i,v in pairs(self.args.skill) do
		local tablee = {}
		tablee.skillId = i
		tablee.skillLevel = v.level
		table.insert(self.TSkillDataTab,tablee)
	end

 	table.sort(self.TSkillDataTab, function(a, b)
        return checkint(a.skillId) < checkint(b.skillId)
    end)

	self:createSkillView()
end

--技能ui显示
function CardDetailSkillNew:createSkillView()
	local bgSize = self:getContentSize()

	--战斗技能
	local fightSkillButton = display.newCheckBox(0,0,
		{n = _res('ui/cards/skillNew/card_skill_btn_manage_unactive.png'),
		s = _res('ui/cards/skillNew/card_skill_btn_battle_selected.png')})
	display.commonUIParams(
		fightSkillButton,
		{
			ap = cc.p(0, 1),
			po = cc.p(32,bgSize.height + 22)
		})
	self:addChild(fightSkillButton, 10)
	fightSkillButton:setTag(1)
	fightSkillButton:setOnClickScriptHandler(handler(self, self.BtnCallback))

	local fightSkillLabel = display.newLabel(fightSkillButton:getContentSize().width * 0.5, fightSkillButton:getContentSize().height * 0.5 - 10,
		{text = __('战斗技能'), fontSize = 20, color = '#3c3c3c', ap = cc.p(0.5, 0.5) , w = 150 ,hAlign =display.TAC})
	fightSkillButton:addChild(fightSkillLabel)
	self.fightSkillButton = fightSkillButton
	self.fightSkillButton:setChecked(true)
	--餐厅技能
	local businessSkillButton = display.newCheckBox(0,0,
		{n = _res('ui/cards/skillNew/card_skill_btn_battle_unactive.png'),
		s = _res('ui/cards/skillNew/card_skill_btn_manage_selected.png')})
	display.commonUIParams(
		businessSkillButton,
		{
			ap = cc.p(1, 1),
			po = cc.p(bgSize.width - 24,bgSize.height + 26)
		})
	self:addChild(businessSkillButton, 10)
	businessSkillButton:setTag(2)
	businessSkillButton:setOnClickScriptHandler(handler(self, self.BtnCallback))
	self.businessSkillButton= businessSkillButton

	local businessSkillLabel = display.newLabel(businessSkillButton:getContentSize().width * 0.5, businessSkillButton:getContentSize().height * 0.5 - (isJapanSdk() and 14 or 10),
		{text = __('餐厅技能'), fontSize = 20, color = '#3c3c3c', w = 150,hAlign = display.TAC,  ap = cc.p(0.5, 0.5)})
	businessSkillButton:addChild(businessSkillLabel)

	--战斗技能layout
	local fightSkillLayout = CLayout:create()
	-- fightSkillLayout:setBackgroundColor(cc.c4b(100, 122, 122, 255))
	fightSkillLayout:setAnchorPoint(cc.p(0.5, 1))
	fightSkillLayout:setPosition(cc.p(bgSize.width * 0.5,bgSize.height - 62))
	fightSkillLayout:setContentSize(cc.size(480,370))
	self:addChild(fightSkillLayout,1)
	self.fightSkillLayout = fightSkillLayout
	local fightSkillSize = fightSkillLayout:getContentSize()


	--选择技能光圈
	local seclectSkillImg = display.newImageView(_res('ui/cards/skillNew/team_lead_skill_frame_light.png'), 0, 0)
	display.commonUIParams(seclectSkillImg, {ap = cc.p(0.5,0.5), po = cc.p(fightSkillSize.width * 0.5,fightSkillSize.height * 0.5)})
	fightSkillLayout:addChild(seclectSkillImg,1)
	seclectSkillImg:setVisible(false)
	seclectSkillImg:setScale(0.9)
	self.seclectSkillImg = seclectSkillImg

	--技能默认背景
	local bgImg = display.newImageView(_res('ui/cards/skillNew/card_skill_bg_function.png'), 0, 0)
	display.commonUIParams(bgImg, {ap = cc.p(0.5,0.5), po = cc.p(fightSkillSize.width * 0.5,fightSkillSize.height * 0.5 + 6)})
	fightSkillLayout:addChild(bgImg,-1)

	--对应卡牌类型技能背景
	local fightSkillBgImg = display.newImageView(_res('ui/cards/skillNew/card_skill_bg_1.png'), 0, 0)
	display.commonUIParams(fightSkillBgImg, {ap = cc.p(0.5,0.5), po = cc.p(fightSkillSize.width * 0.5,fightSkillSize.height * 0.5)})
	fightSkillLayout:addChild(fightSkillBgImg)
	self.fightSkillBgImg = fightSkillBgImg


	local tempSize = cc.size(110,120)
	for i=1,4 do
		local layout = CLayout:create()
		-- layout:setBackgroundColor(cc.c4b(100, 122, 122, 255))
		layout:setAnchorPoint(cc.p(0.5,0.5))
		layout:setPosition(cc.p(60+120*(i-1), fightSkillSize.height * 0.5 + 8))
		layout:setContentSize(tempSize)
		fightSkillLayout:addChild(layout,1)


		local skillBg = display.newImageView(_res('ui/cards/skillNew/card_skill_bg_skill.png'),tempSize.width * 0.5, tempSize.height * 0.5 )
		layout:addChild(skillBg,1)
		skillBg:setScale(0.8)
		skillBg:setTag(999)

		local skillImg = display.newImageView(_res(CommonUtils.GetSkillIconPath(9999)),tempSize.width * 0.5, tempSize.height * 0.5 )
		skillImg:setScale(0.55)
		layout:addChild(skillImg,2)
		skillImg:setTag(i)


		local lvLabel = display.newLabel(tempSize.width * 0.5, 16,
			{text = ' ', fontSize = 20, color = '#ffffff', ap = cc.p(0.5, 1),ttf = true,font = TTF_GAME_FONT})
		layout:addChild(lvLabel,3)
		lvLabel:enableOutline(cc.c4b(0, 0, 0, 200), 1)
		lvLabel:setTag(888)

		local cupLabel = display.newLabel(tempSize.width * 0.5, tempSize.height -10 ,
			{text = __('连携技'), fontSize = 20, color = '#ffffff', ap = cc.p(0.5, 0.5),ttf = true,font = TTF_GAME_FONT , w = 180 , hAlign = display.TAC})
		layout:addChild(cupLabel,3)
		cupLabel:enableOutline(cc.c4b(0, 0, 0, 200), 1)
		cupLabel:setTag(777)

		local lockFrameImg = display.newImageView(('ui/cards/skillNew/card_skill_bg_lock.png'),tempSize.width * 0.5, tempSize.height * 0.5 )
		-- lockImg:setScale(0.55)
		layout:addChild(lockFrameImg,4)
		lockFrameImg:setTag(666)


		local lockImg = display.newImageView(('ui/common/common_ico_lock.png'),lockFrameImg:getContentSize().width * 0.5, lockFrameImg:getContentSize().height * 0.5 )
		-- lockImg:setScale(0.55)
		lockFrameImg:addChild(lockImg,4)

		table.insert(self.TskillLayout,layout)
	end

	--底部消耗
	local bgImg = display.newImageView(_res('ui/cards/skillNew/card_skill_bg_battle.png'), 0, 0)
	display.commonUIParams(bgImg, {ap = cc.p(0.5, 1), po = cc.p(bgSize.width * 0.5,fightSkillLayout:getPositionY() + 20 )})
	self:addChild(bgImg,2)

	--
	local fightSkillBottomlayout = CLayout:create()
	-- layout:setBackgroundColor((cc.c4b(0, 255, 128, 128)))
	fightSkillBottomlayout:setAnchorPoint(cc.p(0.5, 1))
	fightSkillBottomlayout:setPosition(bgImg:getPosition())
	local size = bgImg:getContentSize()
	fightSkillBottomlayout:setContentSize(size)
	self:addChild(fightSkillBottomlayout,10)
	self.fightSkillBottomlayout = fightSkillBottomlayout

	------------ TODO 全面屏分辨率 ------------
	local costIconX = 40
	local costIconY = 14
	local costLabelY = 4
	local upskillX = 54
	local upskillY = 55

	-- print('XXXXXXXXXXXXXXXXXXXX')
	-- if (display.width / display.height) >= 2 then
	-- 	print('XXXXXXXXXXXXXXXXXXXX1')
	-- 	costIconX = 5
	-- 	costIconY = fightSkillBottomlayout:getContentSize().height - 90
	-- 	upskillX = 85
	-- 	upskillY = fightSkillBottomlayout:getContentSize().height - 35
	-- end
	------------ TODO 全面屏分辨率 ------------

	--消耗材料items
	for i=1,3 do
		local goodIcon = require('common.GoodNode').new({id = GOLD_ID, showAmount = false})
		goodIcon:setScale(0.80)
		goodIcon:setAnchorPoint(cc.p(0, 0))
		goodIcon:setTouchEnabled(true)
		goodIcon:setPosition(cc.p(costIconX + 94* (i-1), costIconY))
		fightSkillBottomlayout:addChild(goodIcon,1)

		local infoLabel = display.newLabel(0, 0,fontWithColor(14,{text = ('1000')}))--, color = 'ffffff' WithBMFont('font/small/common_text_num.fnt', '')
		display.commonUIParams(infoLabel, {ap = cc.p(1,0)})
		infoLabel:setPosition(cc.p(goodIcon:getContentSize().width - 4 , costLabelY))
		infoLabel:setString(' ')
		infoLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		infoLabel:setTag(123)
		-- infoLabel:setScale(0.8)
		goodIcon:addChild(infoLabel,10)

		table.insert(self.TskillNeedItems,goodIcon)
	end

	--箭头图标
	local tempImg = display.newImageView(_res('ui/cards/skillNew/card_skill_ico_sword.png'))
	display.commonUIParams(tempImg, {ap = cc.p(0, 0.5), po = cc.p(220,40)})
	fightSkillBottomlayout:addChild(tempImg,2)
	tempImg:setVisible(false)
	-- fightSkillBottomlayout:setBackgroundColor(cc.c4b(255, 0, 0,100))
	--升级按钮
   	local upskillBtn = display.newButton(0, 0,
    	{n = _res('ui/common/common_btn_orange.png'), animate = true, cb = handler(self, self.upgradeBtnCallback), scale9 = isJapanSdk(), size = isJapanSdk() and cc.size(153, 62) or nil})
	display.commonUIParams(upskillBtn, {ap = cc.p(0,0.5),po = cc.p(tempImg:getPositionX() + tempImg:getContentSize().width + upskillX , upskillY)})
	if isJapanSdk() then
		upskillBtn:setPositionX(tempImg:getPositionX() + tempImg:getContentSize().width + upskillX - 36)
	end
	display.commonLabelParams(upskillBtn, fontWithColor(14,{text = __('升级'), offset = cc.p(0,10)}))

    fightSkillBottomlayout:addChild(upskillBtn,1)

    self.upskillBtn = upskillBtn

    --需要金币
	local needGoldNumLabel = display.newLabel(0, 0, {text = ('1000'), fontSize = 20, color = '#ffffff', ap = cc.p(0.5, 0),ttf = true,font = TTF_GAME_FONT})
	display.commonUIParams(needGoldNumLabel, {po = cc.p(upskillBtn:getContentSize().width * 0.5 - 10 ,6)})
	upskillBtn:addChild(needGoldNumLabel,1)
	needGoldNumLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	self.needGoldNumLabel = needGoldNumLabel

	--金币图标
	local goldImg = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)))
	display.commonUIParams(goldImg, {po = cc.p(needGoldNumLabel:getPositionX() + needGoldNumLabel:getBoundingBox().width *0.5  + 2,6)})
	goldImg:setScale(0.15)
	goldImg:setAnchorPoint(cc.p(0,0))
	upskillBtn:addChild(goldImg, 5)
	self.goldImg = goldImg


	self:updateMessUpViewNew()
	self:updateBottomViewNew(self.clickTag)
	self:SetBusinessSkillButtonIsVisible()

end
function CardDetailSkillNew:SetBusinessSkillButtonIsVisible()
	local assistantConfig = CommonUtils.GetConfigAllMess('assistant' , 'business')
	local assistantData = assistantConfig[tostring(self.args.cardId)]
	local isVisible = true
	if  not  (assistantData and  assistantData.skill and  table.nums( assistantData.skill) > 0  )    then
		isVisible = false
	end
	self.businessSkillButton:setVisible(isVisible)
end

--刷新经营技能
function CardDetailSkillNew:updateBusinessMessUpViewNew()
	local CardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
	local career = checkint(CardData.career) or 1
	local path = _res(string.format('ui/cards/skillNew/card_skill_bg_%d.png', career))
	if not utils.isExistent(path) then
		path = _res('ui/cards/skillNew/card_skill_bg_1.png')
	end
	local t = {}
	--local tempTab = {}

	self.fightSkillBgImg:setTexture(_res('ui/cards/skillNew/card_skill_bg_5.png'))
	career = 5

	t = self.TSkillDataTab
 	table.sort(t, function(a, b)
        return checkint(a.skillId) < checkint(b.skillId)
    end)

	local CardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
	local index = 1
	local bool = false
	local isHaveUnlock = false      -- 检测是否有解锁的技能
	for i,v in ipairs(self.TskillLayout) do
		local bg = v:getChildByTag(999)
		local img = v:getChildByTag(i)
		local lvLabel = v:getChildByTag(888)
		local cupLabel = v:getChildByTag(777)
		local lockFrameImg = v:getChildByTag(666)
		lockFrameImg:setVisible(false)
		cupLabel:setVisible(false)
		v:setPosition(posData[tostring(career)][i])
		v:setVisible(false)
		local data = t[i]
		if data then
			if data.unlock == 1 then
				if self.isRefresh == false then
					self.clickTag = i
					bool = true
				end
				v:setVisible(true)
				img:setTexture(_res(CommonUtils.GetSkillIconPath(data.skillId)))
				img:setTouchEnabled(true)
				img:setTag(i)
				img:setOnClickScriptHandler(function (sender)
                    PlayAudioByClickNormal()
					-- print(sender:getTag())
					-- if self.clickTag ~= sender:getTag() then
					self.clickTag = sender:getTag()
					self.seclectSkillImg:setVisible(true)
					self.seclectSkillImg:setPosition(v:getPosition())
					self:updateBottomViewNew(sender:getTag())
					-- dump(data.skillId)
					AppFacade.GetInstance():RetrieveMediator('CardsListMediatorNew'):UpdataSkillUi_1( sender:getTag(), self.clickModelTag)
					-- end
				end)
				lvLabel:setString(string.fmt(__('等级：_lv_'),{_lv_ =  self.TSkillDataTab[i].skillLevel}))
				isHaveUnlock = true
			elseif data.unlock == 0 then
				v:setVisible(true)
				img:setTexture(_res(CommonUtils.GetSkillIconPath(data.skillId)))
				lockFrameImg:setVisible(true)
				img:setTouchEnabled(true)
				img:setOnClickScriptHandler(function (sender)
                    PlayAudioByClickNormal()
					uiMgr:ShowInformationTips(string.fmt(__('提升_card_星级到_num_星'),{_card_ = CardData.name,_num_ = data.openBreakLevel}))
				end)
				lvLabel:setString(__('未解锁'))
			end
		end

		-- if i == self.clickTag then
		if bool == true then
			bool = false
			self.seclectSkillImg:setVisible(true)
			self.seclectSkillImg:setPosition(v:getPosition())
		end
	end
	if not  isHaveUnlock  then
		self.seclectSkillImg:setVisible(false)
	end
end


--刷新技能items
function CardDetailSkillNew:updateMessUpViewNew()
	local CardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
	local career = checkint(CardData.career) or 1
	local path = _res(string.format('ui/cards/skillNew/card_skill_bg_%d.png', career))
	if not utils.isExistent(path) then
		path = _res('ui/cards/skillNew/card_skill_bg_1.png')
	end
	local t = {}
	local tempTab = {}
	self.fightSkillBgImg:setTexture(path)
    --local CardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
	for i,v in ipairs(self.TskillLayout) do
		local bg = v:getChildByTag(999)
		local img = v:getChildByTag(i)
		local lvLabel = v:getChildByTag(888)
		local cupLabel = v:getChildByTag(777)
		local lockFrameImg = v:getChildByTag(666)
		lockFrameImg:setVisible(false)
		cupLabel:setVisible(false)
		v:setPosition(posData[tostring(career)][i])
		v:setVisible(true)

		if i > table.nums(self.TSkillDataTab) then
			v:setVisible(false)
		else
			local skillData = nil
			skillData = CardUtils.GetSkillConfigBySkillId(self.TSkillDataTab[i].skillId)
			if skillData then
				-- dump(self.TSkillDataTab[i].skillId)
				-- dump(CommonUtils.GetSkillIconPath(self.TSkillDataTab[i].skillId))
				img:setTexture(_res(CommonUtils.GetSkillIconPath(self.TSkillDataTab[i].skillId)))
				img:setTouchEnabled(true)
				img:setTag(i)
				img:setOnClickScriptHandler(function (sender)
                    PlayAudioByClickNormal()
					-- print(sender:getTag())
					-- if self.clickTag ~= sender:getTag() then
						self.clickTag = sender:getTag()
						self.seclectSkillImg:setVisible(true)
						self.seclectSkillImg:setPosition(v:getPosition())
						self:updateBottomViewNew(sender:getTag())
						AppFacade.GetInstance():RetrieveMediator('CardsListMediatorNew'):UpdataSkillUi_1( sender:getTag(), self.clickModelTag)
					-- end
				end)
				lvLabel:setString(string.fmt(__('等级：_lv_'),{_lv_ =  self.TSkillDataTab[i].skillLevel}))
				if checkint(skillData.property) == 4 then
					cupLabel:setVisible(true)
					cupLabel:setString(__('连携技'))
					-- v:setScale(1)
				elseif checkint(skillData.property) == 2 then
					cupLabel:setVisible(true)
					cupLabel:setString(__('光环技'))
				else
					if checkint(skillData.property) == 1 then
						cupLabel:setVisible(true)
						cupLabel:setString(__('基础技'))
					elseif checkint(skillData.property) == 3 then
						cupLabel:setVisible(true)
						cupLabel:setString(__('能量技'))
					else
						cupLabel:setVisible(false)
					end

					-- v:setScale(0.8)
				end
			else
				v:setVisible(false)
			end
		end

		if i == self.clickTag then
			self.seclectSkillImg:setVisible(true)
			self.seclectSkillImg:setPosition(v:getPosition())
		end
	end
end

--刷新升级技能所需材料ui
function CardDetailSkillNew:updateBottomViewNew(index)
	if not self.TSkillDataTab[index] then
		return
	end
	self.isEnough = true
	-- dump(self.TSkillDataTab[index])
	-- dump(index)
	local skillId = self.TSkillDataTab[index].skillId
	local skillLevel = self.TSkillDataTab[index].skillLevel
	local maxLevel = self.TSkillDataTab[index].maxLevel
	local skillData = CardUtils.GetSkillConfigBySkillId(skillId)

	local tempData = {}
	local isSkillLevelMax = false
	if self.clickModelTag == 1 then
		local costConfig = CommonUtils.GetConfig('cards', 'skillLevel', skillLevel + 1)
		if nil ~= costConfig then
			if 4 == checkint(skillData.property) then
				tempData = costConfig.cpConsume
			else
				tempData = costConfig.consume
			end
		else
			isSkillLevelMax = true
		end
	else
		-- dump(skillId)
		-- dump(skillLevel)
		-- dump(maxLevel)
		if checkint(skillLevel) >= checkint(maxLevel) then
			self.fightSkillBottomlayout:setVisible(false)
		else
			self.fightSkillBottomlayout:setVisible(true)
			local consumeType = CommonUtils.GetConfig('business', 'assistantSkill', skillId).consumeType
			if not CommonUtils.GetConfig('business', 'assistantSkillLevel', consumeType)[tostring(skillLevel+1)] then
				self.fightSkillBottomlayout:setVisible(false)
			else
				tempData = CommonUtils.GetConfig('business', 'assistantSkillLevel', consumeType)[tostring(skillLevel+1)].consume
			end
		end
		-- dump(CommonUtils.GetConfigAllMess('assistantSkillLevel','business'))
		-- local consumeType = CommonUtils.GetConfig('business', 'assistantSkill', skillId).consumeType
		-- tempData = CommonUtils.GetConfig('business', 'assistantSkillLevel', consumeType)[tostring(skillLevel+1)].consume
	end
	-- dump(tempData)
	--所需金币和材料数据
	local itemsTempData = {}
	local goldTempData = {}
	for i,v in ipairs(tempData) do
		if v.goodsId == GOLD_ID then
			table.insert(goldTempData,v)
		else
			table.insert(itemsTempData,v)
		end
	end

	-- dump(goldTempData)
	for i,v in ipairs(goldTempData) do
		self.goldImg:setVisible(true)

		self.needGoldNumLabel:setString(tostring(v.num))
		self.goldImg:setPositionX(self.needGoldNumLabel:getPositionX() + self.needGoldNumLabel:getBoundingBox().width * 0.5 + 2)
		if v.num > gameMgr:GetUserInfo().gold then
			self.isEnough = false
		end
	end

	if isSkillLevelMax then
		self.needGoldNumLabel:setString('(max)')
		self.goldImg:setVisible(false)
	end

	-- dump(self.isEnough)

	for i,v in ipairs(self.TskillNeedItems) do
		if i <= table.nums(itemsTempData) and itemsTempData then
			local data = itemsTempData[i]
			local num   = data.num
			local numlabel = v:getChildByTag(123)
			v:setVisible(true)
			v:RefreshSelf({goodsId = data.goodsId})
			-- numlabel:setScale(0.8)
			numlabel:setString(string.format('%d/%d', gameMgr:GetAmountByGoodId(data.goodsId),num))
			v:setOnClickScriptHandler(function (sender)
				uiMgr:AddDialog("common.GainPopup", {goodId = data.goodsId})
				-- uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
			end)

			if num > gameMgr:GetAmountByGoodId(data.goodsId) then
				self.isEnough = false
			end
		else
			v:setVisible(false)
		end
	end
	-- dump(self.isEnough)
end




--战斗技能和餐厅技能 按钮回调
function CardDetailSkillNew:BtnCallback(pSender)
    PlayAudioByClickNormal()
	local tag = pSender:getTag()
	-- if self.clickModelTag == tag then
	-- 	return
	-- end
	self.businessSkillButton:setChecked(false)
	self.fightSkillButton:setChecked(false)
	pSender:setChecked(true)
	self.clickModelTag = tag

	-- self.index = 1
	if tag == 1 then
		if self.isRefresh == false then
			self.clickTag = 1
		end
	    self.TSkillDataTab = {}

        if not self.args.skill then
	    	return
	    end
		for i,v in pairs(self.args.skill) do
			local tablee = {}
			tablee.skillId = i
			tablee.skillLevel = v.level
			table.insert(self.TSkillDataTab,tablee)
		end

	 	table.sort(self.TSkillDataTab, function(a, b)
	        return checkint(a.skillId) < checkint(b.skillId)
	    end)
	 	self.fightSkillBottomlayout:setVisible(true)

		self:updateMessUpViewNew()

	elseif tag == 2 then
		local assistantConfig = CommonUtils.GetConfigAllMess('assistant' ,'business')
		local assistantData = assistantConfig[tostring(self.args.cardId)]
		if  assistantData and table.nums(assistantData.skill) > 0  then
			self.TSkillDataTab = {}
			local t = CommonUtils.GetBusinessSkillByCardId(self.args.cardId, {from = 3})
		 	table.sort(t, function(a, b)
		        return checkint(a.skillId) < checkint(b.skillId)
		    end)
		    for i,v in ipairs(t) do
				local tablee = {}
				tablee = v
				tablee.skillId = v.skillId
				tablee.skillLevel = v.level
				-- if self.args.businessSkill[v.skillId] then
				-- 	tablee.skillLevel = self.args.businessSkill[v.skillId].level
				-- end
				table.insert(self.TSkillDataTab,tablee)
		    end
		    self.fightSkillBottomlayout:setVisible(true)
		 	self:updateBusinessMessUpViewNew()
		else
			self.businessSkillButton:setChecked(true)
			self.fightSkillButton:setChecked(true)
			pSender:setChecked(false)
			self.fightSkillBottomlayout:setVisible(false)
			--uiMgr:ShowInformationTips(__('无餐厅技能'))
			return
		end
	end
	AppFacade.GetInstance():RetrieveMediator('CardsListMediatorNew'):UpdataSkillUi_1( self.clickTag, self.clickModelTag)
	self:updateBottomViewNew(self.clickTag)

end

--升级按钮回调
function CardDetailSkillNew:upgradeBtnCallback(pSender)
	if self.clickModelTag == 1 then
		if self.isEnough then
			local costConfig = CommonUtils.GetConfig('cards', 'skillLevel', self.TSkillDataTab[self.clickTag].skillLevel + 1)
			if nil == costConfig then
				uiMgr:ShowInformationTips(__('技能达到满级!!!'))
				return
			end
			local cardLevel = costConfig.cardLevel
			if checkint(self.args.level) >= checkint(cardLevel) then
				local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
				httpManager:Post("card/skillLevelUp",SIGNALNAMES.Hero_SkillUp_Callback,{ playerCardId = self.args.id,skillId = self.TSkillDataTab[self.clickTag].skillId,num = 1})
				self.showAction = true
			else
				-- uiMgr:ShowInformationTips(__('无法升级，当前卡牌等级未达到要求等级。'))
				local CardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
				uiMgr:ShowInformationTips(string.fmt(__('须提升_num1_飨灵等级到_num2_，才能升级该技能'),{_num1_ = CardData.name,_num2_ = cardLevel}))
			end
		else
			if checkint(self.needGoldNumLabel:getString()) > gameMgr:GetUserInfo().gold then
				uiMgr:ShowInformationTips(__('金币不足'))
			else
				uiMgr:ShowInformationTips(__('材料不足'))
			end
		end
	else
		if self.isEnough then
			local consumeType = CommonUtils.GetConfig('business', 'assistantSkill', self.TSkillDataTab[self.clickTag].skillId).consumeType
			local cardLevel = CommonUtils.GetConfig('business', 'assistantSkillLevel', consumeType)[tostring(self.TSkillDataTab[self.clickTag].skillLevel+1)].cardLevel
			if checkint(self.args.level) >= checkint(cardLevel) then
				local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
				httpManager:Post("card/businessSkillLevelUp",SIGNALNAMES.Hero_BusinessSkillUp_Callback,{ playerCardId = self.args.id,skillId = self.TSkillDataTab[self.clickTag].skillId,num = 1})
				self.showAction = true
			else
				-- uiMgr:ShowInformationTips(__('无法升级，当前卡牌等级未达到要求等级。'))
				local CardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
				uiMgr:ShowInformationTips(string.fmt(__('须提升_num1_飨灵等级到_num2_，才能升级该技能'),{_num1_ = CardData.name,_num2_ = cardLevel}))
			end


		else
			if checkint(self.needGoldNumLabel:getString()) > gameMgr:GetUserInfo().gold then
				uiMgr:ShowInformationTips(__('金币不足'))
			else
				uiMgr:ShowInformationTips(__('材料不足'))
			end
		end
	end
end
--切换卡牌刷新全部页面
function CardDetailSkillNew:refreshUI(data,model,allData)
	if data then
		self.args = data
	    self.TSkillDataTab = {}
		if model then
			self.clickModelTag = model
		end
		if self.clickModelTag == 1 then
	        if not data.skill then
		    	return
		    end
			for i,v in pairs(data.skill) do
				local tablee = {}
				tablee.skillId = i
				tablee.skillLevel = v.level
				table.insert(self.TSkillDataTab,tablee)
			end

		 	table.sort(self.TSkillDataTab, function(a, b)
		        return checkint(a.skillId) < checkint(b.skillId)
		    end)
		else
			if self.args.businessSkill then
				local t = CommonUtils.GetBusinessSkillByCardId(self.args.cardId, {from = 3})
			 	table.sort(t, function(a, b)
			        return checkint(a.skillId) < checkint(b.skillId)
			    end)
			    for i,v in ipairs(t) do
					local tablee = {}
					tablee = v
					tablee.skillId = v.skillId
					tablee.skillLevel = v.level
					-- if self.args.businessSkill[v.skillId] then
					-- 	tablee.skillLevel = self.args.businessSkill[v.skillId].level
					-- end
					table.insert(self.TSkillDataTab,tablee)
			    end
			end
		end
	end
	-- dump(self.TSkillDataTab)

	-- if not CommonUtils.GetConfigAllMess('assistant','business')[tostring(self.args.cardId)] then
	--if table.nums(CommonUtils.GetConfigAllMess('assistant', 'business' )[tostring(self.args.cardId)].skill) <= 0 then
	--	self.businessSkillButton:setVisible(false)
	--else
	--	self.businessSkillButton:setVisible(true)
	--end
	self:SetBusinessSkillButtonIsVisible()
	if allData then
		if allData.showSkillIndex then
			self.clickTag = allData.showSkillIndex
		end
	end
	self.isRefresh = true
	if self.clickModelTag == 1 then
		self:BtnCallback(self.fightSkillButton)
	else
		self:BtnCallback(self.businessSkillButton)
	end
	self.isRefresh = false
	-- self:updateMessUpViewNew()
	-- self:updateBottomViewNew(self.clickTag)
end

function CardDetailSkillNew:onExit()
	AppFacade.GetInstance():UnRegistObserver(EVENT_GOODS_COUNT_UPDATE, self)
	 -- self:getEventDispatcher():removeEventListener(self.touchListener_)
end

return CardDetailSkillNew
