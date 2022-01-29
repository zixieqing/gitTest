--[[
玩家卡牌详情界面
@params table {
	cardData table 卡牌数据 {
		isArtifactUnlock int 是否真的显示神器 考虑到有些未解锁的情况 1 显示
	}
	petsData table 堕神数据(新结构)
	playerData table 玩家数据
	viewType int 0 显示连携技 不显示神器  1 显示神器 不显示连携技 
}
--]]
local GameScene = require('Frame.GameScene')
local PlayerCardDetailView = class('PlayerCardDetailView', GameScene)

------------ import ------------
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
---@type PetManager
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
------------ import ------------

------------ define ------------
local VIEW_TYPE = {
	SHOW_CONNECT_SKILL = 0,
	SHOW_ARTIFACT      = 1
}

------------ define ------------

--[[
constructor
--]]
function PlayerCardDetailView:ctor( ... )
	local args = unpack({...})
	self.cardData   = checktable(args.cardData)
	self.petsData   = checktable(args.petsData)
	self.playerData = checktable(args.playerData)
	self.viewType   = checkint(args.viewType)
	self.isArtifactUnlock = checkint(args.cardData.isArtifactUnlock)
	self:InitUI()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化ui
--]]
function PlayerCardDetailView:InitUI()

	local cardId = checkint(self.cardData.cardId)
	local cardConfig = CardUtils.GetCardConfig(cardId) or {}

	local petData = nil
	if nil ~= self.petsData then
		for k,v in pairs(self.petsData) do
			petData = v
			break
		end
	end

	local CreateView = function ()

		local size = self:getContentSize()

		-- 吃触摸
		-- local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.75))
		-- eaterLayer:setTouchEnabled(true)
		-- eaterLayer:setContentSize(display.size)
		-- eaterLayer:setAnchorPoint(cc.p(0.5, 0.5))
		-- eaterLayer:setPosition(cc.p(display.cx, display.cy))
		-- self:addChild(eaterLayer)

		-- 遮罩
		self:setBackgroundColor(cc.c4b(0, 0, 0, 255 * 0.75))

		local eaterBtn = display.newButton(0, 0, {size = size, cb = function (sender)
			PlayAudioByClickClose()
			self:runAction(cc.RemoveSelf:create())
		end})
		display.commonUIParams(eaterBtn, {ap = cc.p(0.5, 0.5), po = cc.p(
			size.width * 0.5,
			size.height * 0.5
		)})
		self:addChild(eaterBtn)

		-- 卡牌立绘
		local cardDrawNode = require('common.CardSkinDrawNode').new({
			skinId = checkint(self.cardData.skinId),
			coordinateType = COORDINATE_TYPE_HOME
		})
		cardDrawNode:setPositionX(display.SAFE_L)
		self:addChild(cardDrawNode)

		if cardMgr.GetFavorabilityMax(self.cardData.favorLevel) then
			local designSize = cc.size(1334, 750)
			local winSize = display.size
        	local deltaHeight = (winSize.height - designSize.height) * 0.5

			local particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly')
			-- particleSpine:setTimeScale(2.0 / 3.0)
			particleSpine:setPosition(cc.p(display.SAFE_L + 300,deltaHeight))
			self:addChild(particleSpine)
			particleSpine:setAnimation(0, 'idle2', true)
			particleSpine:update(0)
			particleSpine:setToSetupPose()
		end

		------------ 右侧卡牌信息 ------------
		-- 卡牌基本信息
		local cardTitleBg = display.newImageView(_res('ui/cards/propertyNew/card_attribute_bg_name.png'), 0, 0)
		display.commonUIParams(cardTitleBg, {po = cc.p(
			size.width * 0.75,
			size.height * 0.5 + 250
		)})
		self:addChild(cardTitleBg)

		local careerIconScale = 1.25
		local careerIconBg = display.newImageView(CardUtils.GetCardCareerIconFramePathByCardId(cardId), 0, 0)
		display.commonUIParams(careerIconBg, {po = cc.p(
			cardTitleBg:getPositionX() - cardTitleBg:getContentSize().width * 0.5 + 55,
			cardTitleBg:getPositionY() + 15
		)})
		self:addChild(careerIconBg)
		careerIconBg:setScale(careerIconScale)

		local careerIcon = display.newImageView(CardUtils.GetCardCareerIconPathByCardId(cardId), 0, 0)
		display.commonUIParams(careerIcon, {po = cc.p(
			utils.getLocalCenter(careerIcon).x,
			utils.getLocalCenter(careerIcon).y + 2
		)})
		careerIcon:setScale(0.65)
		careerIconBg:addChild(careerIcon)

		local cardNameLabel = display.newLabel(0, 0,
			{text = tostring(cardConfig.name), fontSize = 32, color = '#ffcc60', ttf = true, font = TTF_GAME_FONT, outline = '#4b2214', outlineSize = 2})
		display.commonUIParams(cardNameLabel, {ap = cc.p(0, 0), po = cc.p(
			cardTitleBg:getPositionX() - cardTitleBg:getContentSize().width * 0.5 + 100,
			cardTitleBg:getPositionY() + 15
		)})
		self:addChild(cardNameLabel)
		local nameLabelParams = {fontSize = 32, font = TTF_GAME_FONT, color = 'ffcc60', fontSizeN = 32, colorN = 'ffcc60', outline = '#4b2214', outlineSize = 2}
		if cardMgr.GetFavorabilityMax(self.cardData.favorLevel) then
			local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
			if checkint(self.playerData.playerId) == checkint(gameMgr:GetUserInfo().playerId) then
				CommonUtils.SetCardNameLabelStringById(cardNameLabel, gameMgr:GetCardDataByCardId(cardId).id, nameLabelParams)
			else
				if checkstr(self.cardData.nickname) ~= '' then
					CommonUtils.SetCardNameLabelStringByIdUseSysFont(cardNameLabel, cardId, nameLabelParams, self.cardData.nickname)
				else
					CommonUtils.SetCardNameLabelStringByIdUseSysFont(cardNameLabel, cardId, nameLabelParams, cardConfig.name)
				end
			end
		end

		local cardBattlePointLabelBg = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
		cardBattlePointLabelBg:update(0)
		cardBattlePointLabelBg:setAnimation(0, 'huo', true)
		cardBattlePointLabelBg:setPosition(cc.p(
			cardTitleBg:getPositionX() + cardTitleBg:getContentSize().width * 0.5 - 100,
			cardTitleBg:getPositionY() + 15
		))
		self:addChild(cardBattlePointLabelBg)
		local tmpCardData = {
			cardId = self.cardData.cardId,
            level = self.cardData.level,
            breakLevel = self.cardData.breakLevel,
            favorabilityLevel = self.cardData.favorLevel,
            pets = self.petsData ,
			artifactTalent = self.cardData.artifactTalent,
			bookLevel = self.cardData.bookLevel,
            equippedHouseCatGene = self.cardData.equippedHouseCatGene,
		}
		local battlePoint = cardMgr.GetCardStaticBattlePointByCardData(tmpCardData)
		local cardBattlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', tostring(battlePoint))
		cardBattlePointLabel:setAnchorPoint(0.5, 0.5)
		cardBattlePointLabel:setHorizontalAlignment(display.TAC)
		cardBattlePointLabel:setPosition(cc.p(
			cardBattlePointLabelBg:getPositionX(),
			cardBattlePointLabelBg:getPositionY() + 10
		))
		self:addChild(cardBattlePointLabel)
		cardBattlePointLabel:setScale(0.7)

		local cvLabel = display.newLabel(0, 0, {text = CommonUtils.GetCurrentCvAuthorByCardId(self.cardData.cardId), fontSize = 20, color = '#ffe5d7'})
		display.commonUIParams(cvLabel, {ap = cc.p(0, 0.5), po = cc.p(
			cardNameLabel:getPositionX(),
			cardTitleBg:getPositionY() - 15
		)})
		self:addChild(cvLabel)

		local levelLabel = display.newLabel(0, 0, {text = string.format(__('等级:%d'), checkint(self.cardData.level)), fontSize = 20, color = '#ffe5d7'})
		display.commonUIParams(levelLabel, {po = cc.p(
			cardBattlePointLabel:getPositionX(),
			cvLabel:getPositionY()
		)})
		self:addChild(levelLabel)

		-- 稀有度 星级
		local qualityLabel = display.newNSprite(CardUtils.GetCardQualityIconPathByCardId(cardId), 0, 0)
		display.commonUIParams(qualityLabel, {po = cc.p(
			cardNameLabel:getPositionX() + 10,
			cardTitleBg:getPositionY() - cardTitleBg:getContentSize().height * 0.5 - qualityLabel:getContentSize().height * 0.5
		)})
		self:addChild(qualityLabel)

		local splitLineUp = display.newNSprite(_res('ui/raid/room/raid_room_card_bg_ico_attribute_line.png'), 0, 0)
		display.commonUIParams(splitLineUp, {po = cc.p(
			qualityLabel:getPositionX() + splitLineUp:getContentSize().width * 0.5 - 20,
			qualityLabel:getPositionY() + 30
		)})
		self:addChild(splitLineUp)
		splitLineUp:setScaleX(1.2)

		local splitLineDown = display.newNSprite(_res('ui/raid/room/raid_room_card_bg_ico_attribute_line.png'), 0, 0)
		display.commonUIParams(splitLineDown, {po = cc.p(
			splitLineUp:getPositionX(),
			qualityLabel:getPositionY() - 27
		)})
		self:addChild(splitLineDown)
		splitLineDown:setScaleX(splitLineUp:getScaleX())

		-- 星级
		local starAmount = checkint(self.cardData.breakLevel)
		-- starAmount = 5
		for i = 1, starAmount do
			local star = display.newNSprite(_res('ui/common/common_star_l_ico.png'), 0, 0)
			display.commonUIParams(star, {po = cc.p(
				qualityLabel:getPositionX() + 85 + (i - 1) * 50,
				qualityLabel:getPositionY()
			)})
			self:addChild(star)
		end

		------------ 堕神信息 ------------
		local petInfoBg = display.newImageView(_res('ui/raid/room/raid_room_card_bg1.png'), 0, 0)
		display.commonUIParams(petInfoBg, {po = cc.p(
			cardTitleBg:getPositionX(),
			cardTitleBg:getPositionY() - cardTitleBg:getContentSize().height * 0.5 - petInfoBg:getContentSize().height * 0.5 - 80
		)})
		self:addChild(petInfoBg)

		local petTitleBg = display.newImageView(_res('ui/common/common_title_5.png'), 0, 0 , {scale9 = true })
		display.commonUIParams(petTitleBg, {po = cc.p(
			utils.getLocalCenter(petInfoBg).x,
			petInfoBg:getContentSize().height - petTitleBg:getContentSize().height * 0.5 - 5
		)})
		petInfoBg:addChild(petTitleBg)
		local petTitleBgSize = petTitleBg:getContentSize()


		local petTitleLabel = display.newLabel(0, 0, {text = __('装备的堕神'), fontSize = 20, color = '#5b3c25'})

		petTitleBg:addChild(petTitleLabel)
		local petTitleLabelSize = display.getLabelContentSize(petTitleLabel)
		petTitleBg:setContentSize(cc.size(petTitleLabelSize.width + 60 , petTitleBgSize.height ))
		display.commonUIParams(petTitleLabel, {po = utils.getLocalCenter(petTitleBg)})
		-- 空
		local emptyPetLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('未装备堕神')}))
		display.commonUIParams(emptyPetLabel, {po = utils.getLocalCenter(petInfoBg)})
		petInfoBg:addChild(emptyPetLabel)
		emptyPetLabel:setVisible((nil == petData or checkint(petData.petId) == 0))

		-- 初始化堕神信息
		if nil ~= petData and checkint(petData.petId) > 0 then
			local petId = checkint(petData.petId)
			local petConfig = petMgr.GetPetConfig(petId)

			local petHeadIconScale = 1
			local petHeadIcon = require('common.PetHeadNode').new({
				petData = {
					petId = checkint(petData.petId),
					level = checkint(petData.level),
					breakLevel = checkint(petData.breakLevel),
					character = checkint(petData.character)
				},
				showLockState = false
			})
			petHeadIcon:setScale(petHeadIconScale)
			display.commonUIParams(petHeadIcon, {po = cc.p(
				40 + petHeadIcon:getContentSize().width * 0.5 * petHeadIconScale,
				petInfoBg:getContentSize().height * 0.5
			)})
			petHeadIcon:RefreshUI({
				petData = {
					petId = checkint(petData.petId),
					level = checkint(petData.level),
					breakLevel = checkint(petData.breakLevel),
					character = checkint(petData.character)
				},
				showLockState = false
			})
			petInfoBg:addChild(petHeadIcon)

			-- 名字 强化等级
			local nameStr = ''
			if 0 < checkint(petData.breakLevel) then
				nameStr = string.format(__('%s +%d'), tostring(petConfig.name), checkint(petData.breakLevel))
			else
				nameStr = tostring(petConfig.name)
			end
			local nameLabel = display.newLabel(0, 0,
				fontWithColor('14', {text = nameStr}))
			display.commonUIParams(nameLabel, {ap = cc.p(0.5, 1), po = cc.p(
				petHeadIcon:getPositionX(),
				petHeadIcon:getPositionY() - petHeadIcon:getContentSize().width * 0.5 * petHeadIconScale - 5
			)})
			petInfoBg:addChild(nameLabel)

			-- 属性信息
			-- 检查是否激活本命
			local activeExclusive = false
			if nil ~= petConfig.exclusiveCard then
				for _, ecid in ipairs(petConfig.exclusiveCard) do
					if checkint(ecid) == cardId then
						activeExclusive = true
						break
					end
				end
			end
			local petpinfo = petMgr.ConvertPetPropertyDataByServerData(petData, activeExclusive)

			local petpcellHeight = 30
			for i = 1, #petpinfo do
				local pos = cc.p(
					petInfoBg:getContentSize().width * 0.6,
					petInfoBg:getContentSize().height - 50 - (i - 0.5) * petpcellHeight
				)
				-- 上边界线
				if 1 == i then
					local splitLineUp = display.newImageView(_res('ui/raid/room/raid_room_card_bg_ico_attribute_line.png'), 0, 0)
					display.commonUIParams(splitLineUp, {po = cc.p(
						pos.x,
						pos.y + petpcellHeight * 0.5
					)})
					petInfoBg:addChild(splitLineUp, 5)
				end

				-- 下边界线
				local splitLineDown = display.newImageView(_res('ui/raid/room/raid_room_card_bg_ico_attribute_line.png'), 0, 0)
				display.commonUIParams(splitLineDown, {po = cc.p(
					pos.x,
					pos.y - petpcellHeight * 0.5
				)})
				petInfoBg:addChild(splitLineDown, 5)

				-- 属性底图
				if i % 2 == 0 then
					local petpbg = display.newImageView(_res('ui/raid/room/raid_room_card_bg_attribute.png'), 0, 0)
					display.commonUIParams(petpbg, {po = pos})
					petInfoBg:addChild(petpbg)
				end

				-- 属性信息
				local pinfo = petpinfo[i]
				if not pinfo.unlock then
					-- 属性未解锁
					local lockLabel = display.newLabel(0, 0, {text = __('未解锁'), fontSize = 20, color = '#e2c9bf'})
					display.commonUIParams(lockLabel, {po = pos})
					petInfoBg:addChild(lockLabel)
				else
					-- 属性名
					local petpname = PetPConfig[pinfo.ptype].name
					local petpnameLabel = display.newLabel(0, 0, {text = petpname, fontSize = 20, color = '#e2c9bf'})
					display.commonUIParams(petpnameLabel, {ap = cc.p(0, 0.5), po = cc.p(
						pos.x - 110,
						pos.y
					)})
					petInfoBg:addChild(petpnameLabel)

					-- 属性值
					local petpvalueLabel = CLabelBMFont:create(
						string.format('+%d', pinfo.pvalue),
						petMgr.GetPetPropFontPath(pinfo.pquality)
					)
					petpvalueLabel:setBMFontSize(26)
					petpvalueLabel:setAnchorPoint(cc.p(1, 0.5))
					petpvalueLabel:setPosition(cc.p(
						pos.x + 110,
						pos.y
					))
					petInfoBg:addChild(petpvalueLabel)
				end
			end
		end
		
		if self.viewType == VIEW_TYPE.SHOW_ARTIFACT then
			-- 卡牌装备的神器
			if self.isArtifactUnlock == 1 then
				local viewData  = self:CreateArtifactIcon()
				local artifactLayer = viewData.artifactLayer
				local petInfoBgPos = cc.p(petInfoBg:getPosition())
				self:addChild(artifactLayer)
				artifactLayer:setPosition(petInfoBgPos.x , petInfoBgPos.y - 220 )
				viewData.smallArtifact:setTexture(CommonUtils.GetArtifiactPthByCardId(self.cardData.cardId))
				display.commonUIParams(artifactLayer , {cb = function()
					local mediator = require("Game.mediator.woodenDummy.WoodenDummyArtifactMediator").new({
						cardData = self.cardData
					})
					AppFacade.GetInstance():RegistMediator(mediator)
				end})
			end

		else
			-- 卡牌连携技信息
			local cardConnectSkillBg = display.newImageView(_res('ui/raid/room/raid_room_card_bg_lianxie.png'), 0, 0)
			display.commonUIParams(cardConnectSkillBg, {po = cc.p(
				petInfoBg:getPositionX(),
				petInfoBg:getPositionY() - petInfoBg:getContentSize().height * 0.5 - 15 - cardConnectSkillBg:getContentSize().height * 0.5
			)})
			self:addChild(cardConnectSkillBg)
	
			local skillTitleBg = display.newImageView(_res('ui/common/common_title_5.png'), 0, 0)
			display.commonUIParams(skillTitleBg, {po = cc.p(
				utils.getLocalCenter(cardConnectSkillBg).x,
				cardConnectSkillBg:getContentSize().height - skillTitleBg:getContentSize().height * 0.5 - 5
			)})
			cardConnectSkillBg:addChild(skillTitleBg)
	
			local skillTitleLabel = display.newLabel(0, 0, {text = __('连携技能'), fontSize = 20, color = '#5b3c25'})
			display.commonUIParams(skillTitleLabel, {po = utils.getLocalCenter(skillTitleBg)})
			skillTitleBg:addChild(skillTitleLabel)
	
			local connectSkillId = CardUtils.GetCardConnectSkillId(cardId)
			local noConnectSkillLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('该卡牌没有连携技')}))
			display.commonUIParams(noConnectSkillLabel, {po = utils.getLocalCenter(cardConnectSkillBg)})
			cardConnectSkillBg:addChild(noConnectSkillLabel)
			noConnectSkillLabel:setVisible(nil == connectSkillId)
	
			if nil ~= connectSkillId then
				-- 连携技信息
				local skillIconScale = 1
				local skillIcon = require('common.SkillNode').new({id = connectSkillId})
				display.commonUIParams(skillIcon, {po = cc.p(
					40 + skillIcon:getContentSize().width * 0.5 * skillIconScale,
					cardConnectSkillBg:getContentSize().height * 0.5
				)})
				cardConnectSkillBg:addChild(skillIcon)
	
				-- 连携技信息
				local skillConfig = CommonUtils.GetSkillConf(connectSkillId)
				local skillNameLabel = display.newLabel(0, 0, {text = tostring(skillConfig.name), fontSize = 22, color = '#ffdf6f'})
				display.commonUIParams(skillNameLabel, {ap = cc.p(0, 0), po = cc.p(
					cardConnectSkillBg:getContentSize().width * 0.5 - 55,
					cardConnectSkillBg:getContentSize().height * 0.5 + 20
				)})
				cardConnectSkillBg:addChild(skillNameLabel)
	
				local skillCardsStr = __('和')
				for i,v in ipairs(cardConfig.concertSkill) do
					local connectCardConfig = CardUtils.GetCardConfig(checkint(v))
					if nil == connectCardConfig then
						skillCardsStr = skillCardsStr .. __('???')
					else					
						skillCardsStr = skillCardsStr .. tostring(connectCardConfig.name)
					end
					if i ~= #cardConfig.concertSkill then
						skillCardsStr = skillCardsStr .. ','
					end
				end
				skillCardsStr = skillCardsStr .. __('一起进入战斗时激活该技能')
				local skillCardsDescr = display.newLabel(0, 0, {text = skillCardsStr, fontSize = 20, color = '#ffffff', w = 285, h = 60})
				display.commonUIParams(skillCardsDescr, {ap = cc.p(0, 1), po = cc.p(
					skillNameLabel:getPositionX(),
					skillNameLabel:getPositionY() - 15
				)})
				cardConnectSkillBg:addChild(skillCardsDescr)
	
				local splitLine = display.newImageView(_res('ui/raid/room/raid_room_card_bg_ico_attribute_line.png'), 0, 0)
				display.commonUIParams(splitLine, {po = cc.p(
					cardConnectSkillBg:getContentSize().width * 0.5,
					40
				)})
				cardConnectSkillBg:addChild(splitLine)
	
				local connectSkillHintLabel = display.newLabel(0, 0, {text = __('(组队副本中连携技将会自动释放)'), fontSize = 20, color = '#ff6a6a'})
				display.commonUIParams(connectSkillHintLabel, {po = cc.p(
					splitLine:getPositionX(),
					splitLine:getPositionY() - 20
				)})
				cardConnectSkillBg:addChild(connectSkillHintLabel)
			end
			
		end

		local cardConnectSkillBgPos = cc.p(
			petInfoBg:getPositionX(),
			petInfoBg:getPositionY() - petInfoBg:getContentSize().height * 0.5 - 15 - 195 * 0.5
		)
		-- 关闭信息
		local closeLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('点击空白处关闭')}))
		display.commonUIParams(closeLabel, {po = cc.p(
			cardConnectSkillBgPos.x,
			cardConnectSkillBgPos.y - 195 * 0.5 - 30
		)})
		self:addChild(closeLabel)

		-- 玩家信息
		if next(self.playerData) ~= nil then
			local playerInfoBg = display.newImageView(_res('ui/raid/room/raid_room_detail_label_owner.png'), 0, 0)
			local playerInfoBgSize = playerInfoBg:getContentSize()
			display.commonUIParams(playerInfoBg, {po = cc.p(
				display.SAFE_L + playerInfoBgSize.width * 0.5,
				20 + playerInfoBgSize.height * 0.5
			)})
			self:addChild(playerInfoBg)

			local playerHeadNodeScale = 0.6
			local playerHeadNode = require('common.PlayerHeadNode').new({
				playerId = checkint(self.playerData.playerId),
				avatar = checkint(self.playerData.playerAvatar),
				avatarFrame = checkint(self.playerData.playerAvatarFrame),
				playerLevel = checkint(self.playerData.playerLevel),
				showLevel = true
			})
			playerHeadNode:setScale(playerHeadNodeScale)
			display.commonUIParams(playerHeadNode, {po = cc.p(
				playerInfoBg:getPositionX() - playerInfoBgSize.width * 0.5 + 20 + playerHeadNode:getContentSize().width * 0.5 * playerHeadNodeScale,
				playerInfoBg:getPositionY()
			)})
			self:addChild(playerHeadNode)

			local playerHasLabel = display.newLabel(0, 0, {text = __('持有者'), fontSize = 20, color = '#ffffc7'})
			display.commonUIParams(playerHasLabel, {ap = cc.p(0, 0), po = cc.p(
				playerHeadNode:getPositionX() + playerHeadNode:getContentSize().width * 0.5 * playerHeadNodeScale + 15,
				playerHeadNode:getPositionY() + 5
			)})
			self:addChild(playerHasLabel)

			local playerNameLabel = display.newLabel(0, 0, {text = tostring(self.playerData.playerName), fontSize = 22, color = '#ffffff'})
			display.commonUIParams(playerNameLabel, {ap = cc.p(0, 1), po = cc.p(
				playerHasLabel:getPositionX(),
				playerHasLabel:getPositionY() - 5
			)})
			self:addChild(playerNameLabel)
		end

		return {

		}
	end

	xTry(function()
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

end

function PlayerCardDetailView:CreateArtifactIcon()
	local size = cc.size(120 , 140)
	local artifactLayer = display.newLayer(0,0 , {ap = display.CENTER,   size = size , color = cc.c4b(0,0,0,0) ,enable = true })
	local coreBtn = display.newImageView(_res('ui/artifact/core_btn_3'), size.width/2 , size.height - 45 , {ap = display.CENTER})
	artifactLayer:addChild(coreBtn)

	local smallArtifactPath = CommonUtils.GetArtifiactPthByCardId("200001")
	local smallArtifact =  FilteredSpriteWithOne:create(smallArtifactPath)
	smallArtifact:setPosition(cc.p(size.width/2 , size.height - 40 ))
	artifactLayer:addChild(smallArtifact)
	local viewData  = {
		artifactLayer = artifactLayer ,
		coreBtn = coreBtn ,
		smallArtifact = smallArtifact
	}
	return viewData
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------








return PlayerCardDetailView
