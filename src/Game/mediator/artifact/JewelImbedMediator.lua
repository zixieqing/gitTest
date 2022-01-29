--[[
	宝石镶嵌
--]]
local Mediator = mvc.Mediator

local JewelImbedMediator = class("JewelImbedMediator", Mediator)

local NAME = "artifact.JewelImbedMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
--local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
local artiMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
local parseConfig = artiMgr:GetConfigParse()

local BackpackCell = require('home.BackpackCell')

local JEWEL_TALENT_STATUS = {
	IMBEDED 		= 1,	-- 已解锁
	UNLOCK 			= 2,	-- 解锁成功 开始播放解锁动画
	PRE_LOCK		= 3,	-- 前置未解锁
	FRAGMENT_LACK	= 4,	-- 前置已解锁 材料不足
	AVAILABLE		= 5, 	-- 可解锁
}

local attrType = {
	['1'] = {descr = '攻击力', 	typeDescr = __('攻击力+_tarNum_%'), tag = '1'},
	['2'] = {descr = '防御力', 	typeDescr = __('防御力+_tarNum_%'), tag = '2'},
	['3'] = {descr = '生命值', 	typeDescr = __('生命值+_tarNum_%'), tag = '3'},
	['4'] = {descr = '暴击值', 	typeDescr = __('暴击值+_tarNum_%'), tag = '4'},
	['5'] = {descr = '暴伤值', 	typeDescr = __('暴伤值+_tarNum_%'), tag = '5'},
	['6'] = {descr = '攻速值', 	typeDescr = __('攻速值+_tarNum_%'), tag = '6'}
}

function JewelImbedMediator:ctor( param, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.jewelsData = {}
	self.status = JEWEL_TALENT_STATUS.PRE_LOCK
	self.preIndex = nil
	self.cardId = 200001
	self.talentId = 3
	self.cardData = {}
	self.jewel = nil
	self.playerCardId = 300
	self.currentMouse = 1
	if checktable(param) then
		self.cardData = param.cardData
		if param.cardData then
			self.cardId = param.cardData.cardId or 200001
			self.playerCardId = tostring(param.cardData.id) or 300
		end
		self.talentId = tostring(param.talentId) or 3
	end
	self.talent = artiMgr:GetTalentIdPointConfigByCardId(self.cardId)[tostring(self.talentId)]
end

function JewelImbedMediator:InterestSignals()
	local signals = {
		POST.ARTIFACT_TALENT_LEVEL.sglName ,
		POST.ARTIFACT_EQUIPGEM.sglName ,
	}

	return signals
end

function JewelImbedMediator:ProcessSignal(signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
	if name == POST.ARTIFACT_TALENT_LEVEL.sglName then
		self:UpdateUI( JEWEL_TALENT_STATUS.UNLOCK )
	elseif name == POST.ARTIFACT_EQUIPGEM.sglName then
		-- 1、卸下宝石 2、为装备上 3、替换
		if 2 == body.requestData.operation or 3 == body.requestData.operation then
			AppFacade.GetInstance():UnRegsitMediator(NAME)
			uiMgr:ShowInformationTips(__('镶嵌成功！'))
		elseif 1 == body.requestData.operation then
			local gridView = self.viewComponent.viewData_.gridView
			--更新按钮状态
			if self.preIndex then
				local cell = gridView:cellAtIndex(self.preIndex - 1)
				if cell then
					cell.selectImg:setVisible(false)
				end
			end
			self.jewelsData[self.preIndex].owner = nil
			self.preIndex = nil
			self:UpdateDescription()

		end
	end
end

function JewelImbedMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.artifact.JewelImbedView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	-- 获得宝石数据
	local function generateJewelData()
		local jewelsData = artiMgr:GetGemImbedStatusByColor(self.talent.gemstoneColor[1], true)
		table.sort(jewelsData, function ( a, b )
			if a.owner and b.owner then
				if a.owner.playerCardId == self.playerCardId and a.owner.talentId == self.talentId and b.owner.playerCardId == self.playerCardId and b.owner.talentId == self.talentId then
					return false
				end
			end
			if a.owner then
				if a.owner.playerCardId == self.playerCardId and a.owner.talentId == self.talentId then
					return true
				end
				if not b.owner then
					return false
				end
			end
			if b.owner then
				if b.owner.playerCardId == self.playerCardId and b.owner.talentId == self.talentId then
					return false
				end
				if not a.owner then
					return true
				end
			end
			if tonumber(a.grade) > tonumber(b.grade) then
				return true
			elseif tonumber(a.grade) < tonumber(b.grade) then
				return false
			else
				return tonumber(a.type) < tonumber(b.type)
			end
		end)
		return jewelsData
	end
	self.jewelsData = generateJewelData()
	
	local viewData = viewComponent.viewData_
	viewData.unlockBtn:setOnClickScriptHandler(handler(self,self.UnlockActions))
	viewData.imbedBtn:setOnClickScriptHandler(handler(self,self.ImbedActions))
	viewData.releaseBtn:setOnClickScriptHandler(handler(self,self.ReleaseActions))
	viewData.replaceBtn:setOnClickScriptHandler(handler(self,self.ReplaceActions))
	for key, value in pairs(viewData.mouseToggles) do
        value:setOnClickScriptHandler(handler(self, self.OnMouseToggleClickHandler))
    end

	viewData.goodsNode.callBack = function (sender)
		local unlockConf = artiMgr:GetUpgradeNeedArtifactFragmentConsume(self.cardData, self.talentId)
		uiMgr:AddDialog("common.GainPopup", {goodId = unlockConf.goodsId})
	end

	viewData.Bg_target:setTexture(_res("ui/artifact/card_weapon_gift_slot_L_" .. self.talent.gemstoneColor[1]))

	-- 获得天赋解锁状态
	local function getCurLockStatus(cardData, talentId)
		local status = artiMgr:CheckTalentIdAllowUpgradeId(cardData , talentId)
		if 0 == status then
			return JEWEL_TALENT_STATUS.PRE_LOCK
		elseif 1 == status then
			return JEWEL_TALENT_STATUS.FRAGMENT_LACK
		elseif 2 == status then
			return JEWEL_TALENT_STATUS.IMBEDED
		end
		return JEWEL_TALENT_STATUS.PRE_LOCK
	end
	self.status = getCurLockStatus(self.cardData, self.talentId)

	self:UpdateUI( self.status )
end

function JewelImbedMediator:OnMouseToggleClickHandler( sender )
    local tag = sender:getTag()
	local viewData = self.viewComponent.viewData_
    if self.currentMouse == tag then
        viewData.mouseToggles[tag]:setChecked(true)
        return
	end
	if self.currentMouse then
		viewData.mouseToggles[self.currentMouse]:setChecked(false)
	end
    viewData.mouseToggles[tag]:setChecked(true)
	self.currentMouse = tag

	local activeSkillIndex = nil
	local grade = 1
	if self.jewel then
		local gemstone = artiMgr:GetConfigDataByName(parseConfig.TYPE.GEM_STONE)
		for k, v in pairs(self.talent.gemstoneShape) do
			if v == gemstone[self.jewel.goodsId].type then
				activeSkillIndex = k
				break
			end
		end
		grade = gemstone[self.jewel.goodsId].grade
	end
	local gemstoneSkillGroup = artiMgr:GetConfigDataByName(parseConfig.TYPE.GEM_STONE_SKILL_GROUP)
	if activeSkillIndex == tag then
		viewData.Bg_skill:setTexture(_res('ui/artifact/core_put_bg_active_1.png'))
		viewData.activeImage:setVisible(true)
		viewData.unactiveImage:setVisible(false)
		viewData.skillDesrLabel:setColor(ccc3FromInt("c16f32"))
		local skillId = gemstoneSkillGroup[self.talent.getSkill[activeSkillIndex]][tostring(grade)]
		viewData.skillDesrLabel:setString(ArtifactUtils.GetArtifactGemSkillDescrBySkillId(checkint(skillId), false))
	else
		viewData.Bg_skill:setTexture(_res('ui/artifact/core_put_bg_unactive_1.png'))
		viewData.activeImage:setVisible(false)
		viewData.unactiveImage:setVisible(true)
		viewData.skillDesrLabel:setColor(ccc3FromInt("6b635d"))
		local skillId = gemstoneSkillGroup[self.talent.getSkill[tag]][tostring(grade)]
		viewData.skillDesrLabel:setString(ArtifactUtils.GetArtifactGemSkillDescrBySkillId(checkint(skillId), true))
	end
end

function JewelImbedMediator:UpdateUI( status )
	self.status = status
	--local viewData = self.viewComponent.viewData_
	--local lockBg = viewData.lockBg
	--local backpackView = viewData.backpackView
	local isLock = true
	if status == JEWEL_TALENT_STATUS.UNLOCK then
		isLock = false
		self:UpdateJewelDesr({showUnlock = true})
	elseif status == JEWEL_TALENT_STATUS.IMBEDED then
		isLock = false
		local jewel = nil
		for k, v in pairs(self.jewelsData) do
			if v.owner then
				if v.owner.playerCardId == self.playerCardId and v.owner.talentId == self.talentId then
					jewel = v
					break
				end
			end
		end
		self:UpdateJewelDesr({jewel = jewel})
	else
		self:UpdateJewelDesr({lock = true})
	end

	self:UpdateRight({status = status})
end

--[[
	左侧界面
	 @param table {
        jewel:table            	-- 宝石数据
        lock:bool           	-- 是否锁定
        showUnlock:bool       	-- 显示解锁动画
    }
--]]
function JewelImbedMediator:UpdateJewelDesr( ... )
	local args = unpack({ ... })
	local viewData = self.viewComponent.viewData_
	local jewel = nil
	local lock = false
	local showUnlock = false
	if args then
		jewel = args.jewel
		lock = args.lock
		showUnlock = args.showUnlock
	end
	viewData.lockImg:setVisible(lock or false)
	self:UpdateDescription(jewel)

	local color = self.talent.gemstoneColor[1]
	if lock then
		viewData.Bg_target:setPositionX(310)
		viewData.unselectedLabel:setVisible(false)
		viewData.Bg_target:setTexture(_res('ui/artifact/card_weapon_gift_slot_L_lock'))
		viewData.cageSpine:setAnimation(0, 'stop', true)
		viewData.cageSpine:update(0)
		viewData.cageSpine:setToSetupPose()
	elseif showUnlock then
		viewData.Bg_target:setTexture(_res('ui/artifact/card_weapon_gift_slot_L_' .. color))
		viewData.Bg_target:setPositionX(310)
		self.inAni = true
		viewData.unselectedLabel:setVisible(false)
		viewData.Bg_target:runAction(cc.Sequence:create(
			cc.MoveBy:create(0.5, cc.p(-170, 0)),
			cc.CallFunc:create(function (  )
				self.inAni = false
				viewData.unselectedLabel:setVisible(true)
				viewData.cageSpine:setAnimation(0, 'idle', true)
				viewData.cageSpine:update(0)
				viewData.cageSpine:setToSetupPose()
			end)
		))
	else
		viewData.Bg_target:setTexture(_res('ui/artifact/card_weapon_gift_slot_L_' .. color))
		viewData.Bg_target:setPositionX(140)
	end
end

--[[
	按钮显示 拥有者显示 宝石描述显示
--]]
function JewelImbedMediator:UpdateDescription( jewel )
	local viewData = self.viewComponent.viewData_
	local imbedBtn = viewData.imbedBtn
	local releaseBtn = viewData.releaseBtn
	local replaceBtn = viewData.replaceBtn
	local mouseSpine = viewData.mouseSpine
	local jewelImg = viewData.jewelImg
	
	self.jewel = jewel
	if jewel then
		viewData.cageSpine:setAnimation(0, artiMgr:GetCircleSpineByName(jewel.goodsId), true)
		viewData.cageSpine:update(0)
		viewData.cageSpine:setToSetupPose()
		mouseSpine:setVisible(true)
		mouseSpine:setAnimation(0, artiMgr:GetSpineNameById(jewel.goodsId), true)
		mouseSpine:update(0)
		mouseSpine:setToSetupPose()
		jewelImg:setVisible(true)
		jewelImg:setTexture(artiMgr:GetEquipGemIconByGemId(jewel.goodsId))

		local gemstone = artiMgr:GetConfigDataByName(parseConfig.TYPE.GEM_STONE)
		local jewelData = gemstone[jewel.goodsId]
		viewData.Bg_desr:setVisible(true)
		for k, v in pairs(viewData.desrLabels) do
			v:setVisible(true)
		end
		display.commonLabelParams(viewData.desrLabels[1] , {text =jewelData.name , reqW = 170  })
		local gemstoneAdditionDescr = artiMgr.GetGemstonePropertyAdditionDescr(checkint(jewel.goodsId))
		viewData.desrLabels[2]:setString(gemstoneAdditionDescr)
		viewData.ruleBtn:setVisible(true)
		viewData.unselectedLabel:setVisible(false)
		if not jewel.owner then
			imbedBtn:setVisible(true)
			imbedBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
			imbedBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
			releaseBtn:setVisible(false)
			replaceBtn:setVisible(false)
			viewData.ownerView:setVisible(false)
		else
			if jewel.owner.playerCardId == self.playerCardId and jewel.owner.talentId == self.talentId  then
				imbedBtn:setVisible(false)
				releaseBtn:setVisible(true)
				replaceBtn:setVisible(false)
			else
				imbedBtn:setVisible(false)
				releaseBtn:setVisible(false)
				replaceBtn:setVisible(true)
			end

			viewData.ownerView:setVisible(true)
			viewData.cardHeadNode:RefreshUI({
				id = jewel.owner.playerCardId,
				showBaseState = false, showActionState = false, showVigourState = false
			})
		end

		-- 没有 self.preIndex 表示默认选中该天赋已经镶嵌的宝石
		if not self.preIndex then
			self.preIndex = 1
			local gridView = viewData.gridView
			local cell = gridView:cellAtIndex(0)
			if cell then
				cell.selectImg:setVisible(true)
			end
		end

		self:UpdateSkillDesr(jewel)
	else
		viewData.cageSpine:setAnimation(0, 'idle', true)
		viewData.cageSpine:update(0)
		viewData.cageSpine:setToSetupPose()
		mouseSpine:setVisible(false)
		jewelImg:setVisible(false)

		if self.status == JEWEL_TALENT_STATUS.FRAGMENT_LACK then
			imbedBtn:setVisible(false)
		elseif self.status == JEWEL_TALENT_STATUS.PRE_LOCK then
			imbedBtn:setVisible(false)
		else
			imbedBtn:setVisible(true)
		end

		imbedBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		imbedBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
		releaseBtn:setVisible(false)
		replaceBtn:setVisible(false)
		viewData.Bg_desr:setVisible(false)
		for k, v in pairs(viewData.desrLabels) do
			v:setVisible(false)
		end
		viewData.ruleBtn:setVisible(false)
		viewData.ownerView:setVisible(false)
		viewData.unselectedLabel:setVisible(true)
		self:UpdateSkillDesr()
	end
end

--[[
	技能描述
--]]
function JewelImbedMediator:UpdateSkillDesr( jewel )
	local viewData = self.viewComponent.viewData_
	local grade = 1
	local skill = 1

	if jewel then
		local gemstone = artiMgr:GetConfigDataByName(parseConfig.TYPE.GEM_STONE)
		for k, v in pairs(self.talent.gemstoneShape) do
			if v == gemstone[jewel.goodsId].type then
				skill = k
				break
			end
		end
		grade = gemstone[jewel.goodsId].grade

		for i=1,3 do
			local type = self.talent.gemstoneShape[i]
			viewData.mouseImgs[i]:setTexture(_res('ui/artifact/core_ico_type_' .. tostring(type) .. '_disabled'))
		end
		viewData.mouseImgs[skill]:setTexture(_res('ui/artifact/core_ico_type_' .. tostring(skill) .. '_active'))
	else
		for i=1,3 do
			local type = self.talent.gemstoneShape[i]
			viewData.mouseImgs[i]:setTexture(_res('ui/artifact/core_ico_type_' .. tostring(type) .. '_disabled'))
		end
	end
	local gemstoneSkillGroup = artiMgr:GetConfigDataByName(parseConfig.TYPE.GEM_STONE_SKILL_GROUP)

	if jewel then
		local skillId = gemstoneSkillGroup[self.talent.getSkill[skill]][tostring(grade)]
		viewData.skillDesrLabel:setString(ArtifactUtils.GetArtifactGemSkillDescrBySkillId(checkint(skillId), false))
		viewData.Bg_skill:setTexture(_res('ui/artifact/core_put_bg_active_1.png'))
		viewData.activeImage:setVisible(true)
		viewData.unactiveImage:setVisible(false)
		viewData.skillDesrLabel:setColor(ccc3FromInt("c16f32"))
		self.currentMouse = skill
	else
		local skillId = gemstoneSkillGroup[self.talent.getSkill[self.currentMouse]][tostring(grade)]
		viewData.skillDesrLabel:setString(ArtifactUtils.GetArtifactGemSkillDescrBySkillId(checkint(skillId), true))
		viewData.Bg_skill:setTexture(_res('ui/artifact/core_put_bg_unactive_1.png'))
		viewData.activeImage:setVisible(false)
		viewData.unactiveImage:setVisible(true)
		viewData.skillDesrLabel:setColor(ccc3FromInt("6b635d"))
	end
	for i, v in ipairs(viewData.mouseToggles) do
		if jewel and i == skill then
			v:setSelectedImage(_res('ui/artifact/core_put_bg_active_2.png'))
			v:setChecked(true)
		else
			v:setSelectedImage(_res('ui/artifact/core_put_bg_unactive_2.png'))
			v:setChecked(false)
		end
	end
	if not jewel then
		viewData.mouseToggles[self.currentMouse]:setChecked(true)
	end
end

--[[
	右侧界面
	 @param table {
        status:JEWEL_TALENT_STATUS		-- 天赋解锁状态
    }
--]]
function JewelImbedMediator:UpdateRight( ... )
	local args = unpack({ ... })
	local isLock = false
	if args then
		if args.status == JEWEL_TALENT_STATUS.UNLOCK or args.status == JEWEL_TALENT_STATUS.IMBEDED then
			isLock = false
		else
			isLock = true
		end
	end
	local viewData = self.viewComponent.viewData_
	local lockBg = viewData.lockBg
	local backpackView = viewData.backpackView
	local kongBg = viewData.kongBg
	local gridView = viewData.gridView
	lockBg:setVisible(isLock)
	backpackView:setVisible(not isLock)
	if isLock then
		-- 获得解锁材料
		local function getUnlockConfig(cardData, talentId)
			return artiMgr:GetUpgradeNeedArtifactFragmentConsume(cardData, talentId)
		end
		local unlockConf = getUnlockConfig(self.cardData, self.talentId)
		viewData.goodsNode:RefreshSelf({goodsId = unlockConf.goodsId})
		viewData.goodsCountLabel:setString(unlockConf.num)
		viewData.ownLabel:setString(gameMgr:GetAmountByGoodId(unlockConf.goodsId))
		if gameMgr:GetAmountByGoodId(unlockConf.goodsId) < checkint(unlockConf.num) then
			viewData.ownLabel:setBMFontFilePath('font/small/common_num_unused.fnt')
		else
			if args.status == JEWEL_TALENT_STATUS.FRAGMENT_LACK then
				args.status = JEWEL_TALENT_STATUS.AVAILABLE
				self.status = JEWEL_TALENT_STATUS.AVAILABLE
			end
			viewData.ownLabel:setBMFontFilePath('font/small/common_text_num.fnt')
		end
		local totalWidth = viewData.ownLabel:getContentSize().width + viewData.virguleLabel:getContentSize().width + viewData.goodsCountLabel:getContentSize().width
		display.commonUIParams(viewData.goodsCountLabel, {ap = display.RIGHT_CENTER, po = cc.p(viewData.lockSize.width / 2 + totalWidth / 2, 155)})
		display.commonUIParams(viewData.ownLabel, {ap = display.LEFT_CENTER, po = cc.p(viewData.lockSize.width / 2 - totalWidth / 2, 155)})
		display.commonUIParams(viewData.virguleLabel, {ap = display.LEFT_CENTER, po = cc.p(viewData.lockSize.width / 2 - totalWidth / 2 + viewData.ownLabel:getContentSize().width, 155)})

		local unlockBtn = viewData.unlockBtn
		local requireLabel = viewData.requireLabel
		if args.status == JEWEL_TALENT_STATUS.PRE_LOCK or args.status == JEWEL_TALENT_STATUS.FRAGMENT_LACK then
			unlockBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
			unlockBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
		else
			requireLabel:setVisible(false)
			unlockBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
			unlockBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
		end
	end
	
	if not isLock then
		--绑定相关的事件
		kongBg:setVisible(0 == table.nums(self.jewelsData))
		gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
		gridView:setCountOfCell(table.nums(self.jewelsData))
		gridView:reloadData()
		gridView:setVisible(0 ~= table.nums(self.jewelsData))
	end

	if self.status == JEWEL_TALENT_STATUS.PRE_LOCK then
		viewData.requireLabel:setVisible(true)
	else
		viewData.requireLabel:setVisible(false)
	end
end

--[[
	镶嵌按钮
--]]
function JewelImbedMediator:ImbedActions( sender )
	PlayAudioByClickNormal()
	local viewData = self.viewComponent.viewData_
	local lockBg = viewData.lockBg
	if lockBg:isVisible() then
		uiMgr:ShowInformationTips(__('请先解锁核心天赋'))
	elseif not self.preIndex then
		uiMgr:ShowInformationTips(__('请选择塔可'))
	else
		self:SendSignal(POST.ARTIFACT_EQUIPGEM.cmdName ,{ talentId = self.talentId, playerCardId = self.cardData.id, operation = 2, gemstoneId = self.jewel.goodsId})
	end
end

--[[
	解锁按钮
--]]
function JewelImbedMediator:UnlockActions( sender )
	PlayAudioByClickNormal()
	if self.status == JEWEL_TALENT_STATUS.FRAGMENT_LACK then
		uiMgr:ShowInformationTips(__('解锁天赋需要的材料不足'))
	elseif self.status == JEWEL_TALENT_STATUS.PRE_LOCK then
		uiMgr:ShowInformationTips(__('需前置节点满级'))
	else
		self:SendSignal(POST.ARTIFACT_TALENT_LEVEL.cmdName ,{ talentId = self.talentId , playerCardId = self.cardData.id , level = 1})
	end
end

--[[
	移除按钮
--]]
function JewelImbedMediator:ReleaseActions( sender )
	PlayAudioByClickNormal()
	self:SendSignal(POST.ARTIFACT_EQUIPGEM.cmdName ,{ talentId = self.talentId, playerCardId = self.cardData.id, operation = 1, gemstoneId = self.jewel.goodsId})
end

--[[
	替换按钮
--]]
function JewelImbedMediator:ReplaceActions( sender )
	PlayAudioByClickNormal()
	local scene = uiMgr:GetCurrentScene()
	local temp_str =  __('该塔可已经携带在其他\n卡牌中，是否将其移至\n当前卡牌。')
	local CommonTip  = require( 'common.CommonTip' ).new({text = temp_str,isOnlyOK = false, callback = function ()
		self:SendSignal(POST.ARTIFACT_EQUIPGEM.cmdName ,{ talentId = self.talentId, playerCardId = self.cardData.id, operation = 3, gemstoneId = self.jewel.goodsId
			, ownerPlayerCardId = checkint(self.jewel.owner.playerCardId), ownerTalentId = checkint(self.jewel.owner.talentId)})
	end})
	CommonTip:setPosition(display.center)
	scene:AddDialog(CommonTip)
end

function JewelImbedMediator:OnDataSourceAction( p_convertview,idx )
	local pCell = p_convertview
    local index = idx + 1
	local sizee = cc.size(110, 115)
	if pCell == nil then
		pCell = BackpackCell.new(sizee)
		pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))
		pCell.selectImg:setLocalZOrder(2)
		pCell.selectImg:setScale(0.95)
		if index <= 20 then
			pCell.eventnode:setPositionY(sizee.height - 800)
			pCell.eventnode:runAction(
				cc.Sequence:create(cc.DelayTime:create(index * 0.02),
				cc.EaseOut:create(cc.MoveTo:create(0.4, cc.p(sizee.width* 0.5,sizee.height * 0.5)), 0.2))
			)
		else
			pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
		end
	else
         pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
	end
	xTry(function()
		local bgPath = string.format('ui/common/common_frame_goods_%d.png', checkint(self.jewelsData[index].quality or 1))
		pCell.toggleView:setNormalImage(_res(bgPath))
		pCell.toggleView:setSelectedImage(_res(bgPath))

		pCell.levelBg:setVisible(true)
		pCell.levelLabel:setString(self.jewelsData[index].grade)
		pCell.toggleView:setTag(index)
		pCell.numLabel:setString(tostring(self.jewelsData[index].amount))
		pCell.goodsImg:setVisible(true)
		local node = pCell.goodsImg
		local goodsId = self.jewelsData[index].goodsId
		local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
		node:setTexture(_res(iconPath))
		pCell.selectImg:setVisible(index == self.preIndex)
	end,__G__TRACKBACK__)
	return pCell
end

function JewelImbedMediator:CellButtonAction( sender )
	if self.inAni then
		return 
	end
	PlayAudioByClickNormal()
	local index = sender:getTag()
	local gridView = self.viewComponent.viewData_.gridView
	--更新按钮状态
	if self.preIndex then
		local cell = gridView:cellAtIndex(self.preIndex - 1)
		if cell then
			cell.selectImg:setVisible(false)
		end
	end
	local cell = gridView:cellAtIndex(index - 1)
    if cell then
        cell.selectImg:setVisible(true)
	end
	self.preIndex = index
	self:UpdateDescription(self.jewelsData[sender:getTag()])
end

function JewelImbedMediator:OnRegist(  )
    regPost(POST.ARTIFACT_EQUIPGEM)
end
function JewelImbedMediator:OnUnRegist(  )
	unregPost(POST.ARTIFACT_EQUIPGEM)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end


return JewelImbedMediator