--[[
卡牌头像框
@params table 参数集 {
	------------ pattern 1 ------------
	id 卡牌自增id 不是配表id 传id会读本地数据 依赖本地数据创建头像
	------------ pattern 1 ------------

	------------ pattern 2 ------------
	cardData table 卡牌信息 直接构造卡牌信息 但是不会显示互斥和疲劳信息 {
		cardId int 卡牌id
		level int 等级
		breakLevel int 突破等级
		skinId int 皮肤id(defaultSkinId)
		favorabilityLevel int 好感度等级 存在这个字段时 使用这个字段判断头像粒子特效显示 否则根据自己卡牌的好感度等级判断
	}
	------------ pattern 2 ------------

	------------ pattern 3 ------------
	specialType int 特殊版式 只需要这个参数 1 移除编队
	------------ pattern 3 ------------

	showBaseState bool 显示基础信息 -> 等级 职业 星级
	showActionState bool 显示该卡牌状态信息 -> 互斥相关的信息
	showVigourState bool 显示该卡牌活力状态 -> 疲劳警告
	showRecommendState bool 是否开启卡牌推荐状态
	ShowExploreState bool 显示探索状态
}
--]]
local plistMgr =  app.plistMgr
---@class CardHeadNode : CButton
local CardHeadNode = class('CardHeadNode', function ()
	local node = CButton:create()
	node.name = 'common.CardHeadNode'
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
constructor
--]]
function CardHeadNode:ctor( ... )
	local args = unpack({...})

	self.grayFilter = nil
	self:InitValue(args)
	self:InitUI()
	self:setScale(args.scale or 1)
	self:setCascadeColorEnabled(true)
	self:setCascadeOpacityEnabled(true)
end
--[[
初始化头像node需要的参数
@params args 外部参数
--]]
function CardHeadNode:InitValue(args)
	-- if not args or next(args) == nil then return end
	if checkint(self.specialType) ~= 0 then
		self.showBaseState = nil
		self.showActionState = nil
		self.showVigourState = nil

	else
		-- 构造一个假的卡牌信息
		self.cardId = 200001
		self.cardData = {}
		
	end
	self.isgrassColor = args.isgrassColor
	self.specialType = 0
	self.graynessColor = args.graynessColor
	self.showName = args.showName or false
	self.showNameOrFight = args.showNameOrFight or false --必须self.showName为true是生效 用来显示名字或者战斗力。true为战斗力，false为名字
	self.showRecommendState = args.showRecommendState or false

	self.skinId = 0 --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 重要参数 现在以皮肤id初始化头像
	------------ 初始化创建卡牌头像框需要的数据 ------------
	if checkint(args.specialType) ~= 0 then
		-- 刷新特殊版式
		self.specialType = args.specialType
		-- 构造一个假的卡牌信息
		self.cardId = 200001
		self.cardData = {}

		self.showBaseState = false
		self.showActionState = false
		self.showVigourState = false
	elseif args.id then
		-- 传入数据库id 直接读本地数据初始化头像
		self.id = checkint(args.id)
		self.cardData = gameMgr:GetCardDataById(self.id)
		self.cardId = self.cardData.cardId
		self.skinId = checkint(self.cardData.defaultSkinId)
		assert(table.nums(self.cardData) > 0, 'you give the card\'s database id, but cannot find the card data in local = ' .. self.id)

		
		if nil == self.showBaseState then
			self.showBaseState = true
		end
		if nil ~= args.showBaseState then
			self.showBaseState = args.showBaseState
		end

		if nil == self.showActionState then
			self.showActionState = true
		end
		if nil ~= args.showActionState then
			self.showActionState = args.showActionState
		end

		if nil == self.showVigourState then
			self.showVigourState = true
		end
		if nil ~= args.showVigourState then
			self.showVigourState = args.showVigourState
		end
		if nil ~= args.ShowExploreState then
			self.ShowExploreState = args.ShowExploreState
		end
	elseif args.cardData then
		-- 直接传入卡牌信息 不读本地数据 由卡牌信息创建头像
		self.cardId = checkint(args.cardData.cardId)
		self.cardData = args.cardData
		self.skinId = checkint(self.cardData.skinId or self.cardData.defaultSkinId)

		if 0 == self.skinId then
			-- 强制初始化一次默认皮肤id
			self.skinId = CardUtils.GetCardSkinId(self.cardId)
		end

		-- 不依赖本地数据 有些信息必定不显示
		self.showBaseState = false
		if nil ~= args.showBaseState then
			self.showBaseState = args.showBaseState
		end
		self.showActionState = false
        if nil ~= args.showActionState then
            self.showActionState = args.showActionState
        end
		self.showVigourState = false
		
	end
	------------ 初始化创建卡牌头像框需要的数据 ------------

end
--[[
init ui
--]]
function CardHeadNode:InitUI()

	local function CreateView()

		local cardConf = CardUtils.GetCardConfig(self.cardId) or {}


		------------ 卡牌基本框架 ------------
		-- bg
		local bg = display.newNSprite(plistMgr:GetSpriteNameByPath(_res('ui/cards/head/kapai_frame_bg.png')), 0, 0)
		local size = bg:getContentSize()

		local notBatchLayout = display.newLayer(size.width/2 , size.height/2, {ap = display.CENTER , size = size})
		self:addChild(notBatchLayout , 70)

		self:setContentSize(size)
		display.commonUIParams(bg, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(bg)
		if  self.isgrassColor then
			local grassImage = display.newImageView(plistMgr:GetSpriteNameByPath(_res('ui/common/kapai_frame_black.png')),size.width/2,size.height/2, { scale9 = true , size = size })
			self:addChild(grassImage , 40)
		end
		if self.graynessColor  then
			local grayNessLayout = CLayout:create(size)
			grayNessLayout:setPosition( cc.p(size.width * 0.5, size.height * 0.5))
			self:addChild(grayNessLayout,3)
			grayNessLayout:setBackGroundColor(cc.c3b(80,80,80))
		end
		local nameBtn = nil
		local nameLabel = nil
		if self.showName then
			self:setContentSize(cc.size(size.width,size.height + 42))
			nameBtn = display.newButton(0, 0, {n = plistMgr:GetSpriteNameByPath(_res('ui/home/teamformation/choosehero/team_kapai_bg_name.png')),enable = false})
			display.commonUIParams(nameBtn, {po = cc.p(size.width * 0.5 - 2, 10),ap = cc.p(0.5,1)})
			--display.commonLabelParams(nameBtn, fontWithColor(14,{text = cardConf.name or '',color = 'ffffff'}))
			nameBtn:setName("nameBtn")
			self:addChild(nameBtn)

			nameLabel = display.newLabel(size.width * 0.5 -2 , -10 , fontWithColor(14, {text = cardConf.name or ''}))
			notBatchLayout:addChild(nameLabel)

			nameBtn:getLabel():enableOutline(cc.c4b(0, 0, 0, 255), 1)
			self.nameLabelParams = fontWithColor(14,{outline = cc.c4b(0, 0, 0, 255),color = 'ffffff', fontSizeN = 24, colorN = 'ffffff'})
		end
		-- card frame
		local frame = FilteredSpriteWithOne:create()
		plistMgr:SetSpriteFrame(frame , basename(CardUtils.GetCardQualityHeadFramePathByCardId(self.cardId)))
		--frame:setSpriteFrame(basename(CardUtils.GetCardQualityHeadFramePathByCardId(self.cardId)))
		frame:setPosition(cc.p(size.width * 0.5, size.height * 0.5))
		self:addChild(frame, 20)
		frame:setCascadeOpacityEnabled(true)

		-- card head icon
		local headSkin = checkint(self.skinId) == 0 and CardUtils.DEFAULT_SKIN_ID or self.skinId
		local headPath = CardUtils.GetCardHeadPathBySkinId(headSkin)
		local cardIcon = FilteredSpriteWithOne:create()
		cardIcon:setTexture(headPath)
		cardIcon:setPosition(cc.p(size.width * 0.5, size.height * 0.5))
		self:addChild(cardIcon, 1)

		local function createParticleSpine()
			local particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly_tx')
			particleSpine:setPosition(cc.p(size.width / 2, size.height / 2))
			notBatchLayout:addChild(particleSpine, 1)
			particleSpine:setAnimation(0, 'idle3', true)
			particleSpine:update(0)
			particleSpine:setToSetupPose()
			return particleSpine
		end
		local particleSpine = nil
		if self.cardData.favorabilityLevel then
			if cardMgr.GetFavorabilityMax(self.cardData.favorabilityLevel) then
				particleSpine = createParticleSpine()
			end
		else
			local data = gameMgr:GetCardDataByCardId(self.cardId)
			if data and checkint(self.specialType) == 0 then
				if cardMgr.GetCouple(data.id) then
					particleSpine = createParticleSpine()
				end
			end
		end

		------------ 卡牌基本框架 ------------

		------------ 卡牌基本信息 ------------
		-- level and career
		local levelBg = FilteredSpriteWithOne:create()
		levelBg:setCascadeOpacityEnabled(true)
		levelBg:setSpriteFrame(basename(_res('ui/cards/head/kapai_zhiye_colour.png')))
		levelBg:setAnchorPoint(cc.p(0.5, 1))
		levelBg:setPosition(cc.p(size.width * 0.215, size.height - 1))
		frame:addChild(levelBg)
		levelBg:setVisible(self.showBaseState)


		local levelLabel = display.newLabel(40 , size.height - 10 , fontWithColor(9, {
			text = self.cardData.level and checkint(self.cardData.level) or '',
			ap = display.CENTER_TOP
		}))
		notBatchLayout:addChild(levelLabel)
		levelLabel:setVisible(self.showBaseState)
		-- career
		local careerBg = FilteredSpriteWithOne:create()
		plistMgr:SetSpriteFrame(careerBg , basename(CardUtils.GetCardCareerIconFramePathByCardId(self.cardId)))
		careerBg:setPosition(cc.p(utils.getLocalCenter(levelBg).x + 1, 7))
		levelBg:addChild(careerBg)
		careerBg:setVisible(self.showBaseState)
		careerBg:setCascadeOpacityEnabled(true)
		local careerIcon = FilteredSpriteWithOne:create()
		plistMgr:SetSpriteFrame(careerIcon ,  basename(CardUtils.GetCardCareerIconPathByCardId(self.cardId)))
		careerIcon:setScale(0.65)
		careerIcon:setPosition(cc.p(utils.getLocalCenter(careerBg).x, utils.getLocalCenter(careerBg).y + 2))
		careerBg:addChild(careerIcon)

		-- stars 几突几星
		local stars = {}
		local starAmount = cardMgr.GetCardStar(self.cardId, {breakLevel = self.cardData.breakLevel})
		local psStarAnchorPos = cc.p(19, 29)
		for i = 1, starAmount do
			local star = FilteredSpriteWithOne:create()
			star:setSpriteFrame(basename(_res('ui/cards/head/kapai_star_colour.png')))
			star:setScale(0.75 + 0.05 * i)
			star:setAnchorPoint(cc.p(psStarAnchorPos.x / star:getContentSize().width, (star:getContentSize().height - psStarAnchorPos.y) / star:getContentSize().height))
			star:setPosition(cc.p(15 + (i - 1) * 13, 3))
			frame:addChild(star, starAmount - i)
			star:setVisible(self.showBaseState)
			table.insert(stars, star)
		end


		------------ 卡牌基本信息 ------------

		------------ 卡牌行动信息 ------------

		--team_states_team1
		local teamStatesImg = display.newNSprite(plistMgr:GetSpriteNameByPath(_res('ui/home/teamformation/team_states_team1.png')), size.width + 8, size.height + 10)
		self:addChild(teamStatesImg, 30)
		teamStatesImg:setAnchorPoint(cc.p(1,1))
		teamStatesImg:setVisible(false)

		local teamIceStatesImg = display.newNSprite(plistMgr:GetSpriteNameByPath(_res('ui/home/teamformation/team_states_ice.png')), size.width + 6, 0)
		self:addChild(teamIceStatesImg, 30)
		teamIceStatesImg:setAnchorPoint(cc.p(1,0))
		teamIceStatesImg:setVisible(false)

		-- action state bg
		local actionStateBg = display.newNSprite(plistMgr:GetSpriteNameByPath(_res('ui/cards/head/kapai_state_biandui_zhuangtai.png')), size.width * 0.5 , size.height * 0.3 )
		self:addChild(actionStateBg, 10)
		actionStateBg:setVisible(false)
		local actionStateLabel = display.newLabel(size.width *0.5 ,size.height*0.3+1 ,fontWithColor(9, {
			text =""
		}) )
		notBatchLayout:addChild(actionStateLabel)

		------------ 卡牌行动信息 ------------

		------------ 卡牌疲劳警告 ------------
		-- 红色警告
		local vigourRedWarning = display.newNSprite('#kapai_frame_mengban_tired.png', size.width * 0.5, size.height * 0.5)
		self:addChild(vigourRedWarning, 5)
		vigourRedWarning:setVisible(false)

		-- 灰色警告
		local vigoutGreyWarning = display.newNSprite('#kapai_frame_mengban_dead.png', size.width * 0.5, size.height * 0.5)
		self:addChild(vigoutGreyWarning, 5)
		vigoutGreyWarning:setVisible(false)
		------------ 卡牌疲劳警告 ------------

		------------ 卡牌推荐 ------------
		local recommendImg = display.newImageView(plistMgr:GetSpriteNameByPath(_res('ui/common/summer_activity_mvpxiangling_icon_unlock.png')), size.width - 16 , size.height - 16)
		self:addChild(recommendImg, 20)
		recommendImg:setVisible(false)
		------------ 卡牌推荐 ------------

		return {
			bg = bg,
			frame = frame,
			notBatchLayout = notBatchLayout,
			cardIcon = cardIcon,
			particleSpine = particleSpine,
			levelBg = levelBg,
			levelLabel = levelLabel,
			careerBg = careerBg,
			careerIcon = careerIcon,
			stars = stars,
			actionStateBg = actionStateBg,
			actionStateLabel = actionStateLabel,

			teamStatesImg  = teamStatesImg,
			teamIceStatesImg = teamIceStatesImg,
			vigourRedWarning = vigourRedWarning,
			vigoutGreyWarning = vigoutGreyWarning,

			nameBtn = nameBtn,
			nameLabel = nameLabel ,
			recommendImg = recommendImg,
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	self:RefreshSpecialType()
	self:RefreshActionState()
	self:RefreshVigourWarning()

end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新整个头像
@params params table 参数集 {
	id int 卡牌数据库id
}
--]]
function CardHeadNode:RefreshUI(args)
	self:InitValue(args)

	self:RefreshCardUI()
end
--[[
根据卡牌信息刷新头像
--]]
function CardHeadNode:RefreshCardUI()
	self:RefreshSpecialType()
	self:RefreshAvatar()
	self:RefreshBaseState()
	self:RefreshActionState()
	self:RefreshVigourWarning()
	self:RefreshRecommendState()
end
--[[
刷新基本形象
--]]
function CardHeadNode:RefreshAvatar()
	-- 刷新卡牌基本信息
	plistMgr:SetSpriteFrame(self.viewData.frame ,basename(CardUtils.GetCardQualityHeadFramePathByCardId(self.cardId)) )
	local headSkin = checkint(self.skinId) == 0 and CardUtils.DEFAULT_SKIN_ID or self.skinId
	local headPath = CardUtils.GetCardHeadPathBySkinId(headSkin)
    self.viewData.cardIcon:setTexture(headPath)

	local function createParticleSpine()
		local size = self.viewData.bg:getContentSize()
		--local particleSpine = sp.SkeletonAnimation:create(
		--	'effects/marry/fly_tx.json',
		--	'effects/marry/fly_tx.atlas',
		--	1)
		---- particleSpine:setTimeScale(2.0 / 3.0)
		--particleSpine:setPosition(cc.p(size.width / 2, size.height / 2))
		--self.viewData.notBatchLayout:addChild(particleSpine, 1)
		--particleSpine:setAnimation(0, 'idle3', true)
		--particleSpine:update(0)
		--particleSpine:setToSetupPose()
		local particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly_tx')
		particleSpine:setPosition(cc.p(size.width / 2, size.height / 2))
		self.viewData.notBatchLayout:addChild(particleSpine, 1)
		particleSpine:setAnimation(0, 'idle3', true)
		particleSpine:update(0)
		particleSpine:setToSetupPose()
		return particleSpine
	end
	if self.cardData.favorabilityLevel then
		if cardMgr.GetFavorabilityMax(self.cardData.favorabilityLevel) and checkint(self.specialType) == 0 then
			if self.viewData.particleSpine then
				self.viewData.particleSpine:setVisible(true)
			else
				self.viewData.particleSpine = createParticleSpine()
			end
		else
			if self.viewData.particleSpine then
				self.viewData.particleSpine:setVisible(false)
			end
		end
	else
		local data = gameMgr:GetCardDataByCardId(self.cardId)
		if data then
			if cardMgr.GetCouple(data.id) and checkint(self.specialType) == 0 then
				if self.viewData.particleSpine then
					self.viewData.particleSpine:setVisible(true)
				else
					self.viewData.particleSpine = createParticleSpine()
				end
			else
				if self.viewData.particleSpine then
					self.viewData.particleSpine:setVisible(false)
				end
			end
		else
			if self.viewData.particleSpine then
				self.viewData.particleSpine:setVisible(false)
			end
		end
	end
end
--[[
刷新等级星级信息
--]]
function CardHeadNode:RefreshBaseState()
	self.viewData.careerBg:setVisible(self.showBaseState)
	self.viewData.levelBg:setVisible(self.showBaseState)
	self.viewData.levelLabel:setVisible(self.showBaseState)
	for i,v in ipairs(self.viewData.stars) do
		v:setVisible(self.showBaseState)
	end

	if not self.showBaseState then return end
	self.viewData.levelLabel:setString(tostring(self.cardData.level or ''))
	if self.showName then
		if self.viewData.nameBtn then
			if self.showNameOrFight == false then
				-- self.viewData.nameBtn:getLabel():setString(tostring(cardConf.name))

				CommonUtils.SetCardNameLabelStringById(self.viewData.nameLabel, self.id, self.nameLabelParams)
			else
				if self.id then
					local num1 = cardMgr.GetCardStaticBattlePointById(checkint(self.id))

					CommonUtils.SetCardNameLabelStringById(self.viewData.nameLabel, self.id, self.nameLabelParams, tostring(num1))
					-- self.viewData.nameBtn:getLabel():setString(tostring(num1))
				end
			end
		end
	else
		if self.viewData.nameBtn then
			self.viewData.nameBtn:setVisible(false)
			self.viewData.nameLabel:setVisible(false)
		end
	end
	plistMgr:SetSpriteFrame(self.viewData.careerBg , basename(CardUtils.GetCardCareerIconFramePathByCardId(self.cardId)) )
	plistMgr:SetSpriteFrame(self.viewData.careerIcon , basename(CardUtils.GetCardCareerIconPathByCardId(self.cardId)))
	for i,v in ipairs(self.viewData.stars) do
		v:removeFromParent()
	end
	self.viewData.stars = {}
	local starAmount = cardMgr.GetCardStar(self.cardId, {breakLevel = self.cardData.breakLevel})
	local psStarAnchorPos = cc.p(19, 29)
	for i = 1, starAmount do
		local star = FilteredSpriteWithOne:create()
		star:setSpriteFrame(basename(_res('ui/cards/head/kapai_star_colour.png')))
		star:setScale(0.75 + 0.05 * i)
		star:setAnchorPoint(cc.p(psStarAnchorPos.x / star:getContentSize().width, (star:getContentSize().height - psStarAnchorPos.y) / star:getContentSize().height))
		star:setPosition(cc.p(15 + (i - 1) * 13, 3))
		self.viewData.frame:addChild(star, starAmount - i)
		table.insert(self.viewData.stars, star)
	end
end
function CardHeadNode:SetCardNameLabel(id  , fontTable , battlePoint)
	CommonUtils.SetCardNameLabelStringById(
		self.viewData.nameLabel,
			id,
			fontTable,
			battlePoint
	)
end
--[[
刷新编队状态
--]]
function CardHeadNode:RefreshActionState()
	self.viewData.actionStateBg:setVisible(false)
	self.viewData.actionStateLabel:setVisible(false)
	self.viewData.teamStatesImg:setVisible(false)
	self.viewData.teamIceStatesImg:setVisible(false)
	if not self.showActionState then
		return
	end
	self:ShowActionStateFrame()
end
--[[
根据状态刷新action state
@params stateData table {
	stutas int 存在状态 0 为空闲 1 为编队，2为看板娘，3为冰箱，4为远征。。。
}
--]]
function CardHeadNode:ShowActionStateFrame()
    local places = {}
    if self.id then
        places = gameMgr:GetCardPlace({id = self.id})
    else
        places = gameMgr:GetCardPlace({cardId = self.cardId})
    end
    if places[tostring(CARDPLACE.PLACE_TAKEAWAY)] then 
        --外卖中
        self.viewData.actionStateBg:setVisible(true)
        self.viewData.actionStateLabel:setVisible(true)
        self.viewData.actionStateLabel:setString(__('配送外卖中'))
    elseif self.ShowExploreState and (places[tostring(CARDPLACE.PLACE_EXPLORATION)] or places[tostring(CARDPLACE.PLACE_EXPLORE_SYSTEM)]) then
        self.viewData.actionStateBg:setVisible(true)
		self.viewData.actionStateLabel:setVisible(true)
        self.viewData.actionStateLabel:setString(__('探索中'))
    else
        if places[tostring(CARDPLACE.PLACE_TEAM)] then
	        --编队中
	        local teamInfo = nil
	        if self.id then
	            teamInfo = gameMgr:GetTeamInfo({id = self.id},false)
	        else
	            teamInfo = gameMgr:GetTeamInfo({cardId = self.cardId},false)
	        end
	        local offset = 0.65
			self.viewData.teamStatesImg:setVisible(true)
	        if teamInfo then
	            -- self.viewData.subActionStateLabel:setString(string.format(__('No.%d'), checkint(teamInfo.teamId)))
	            self.viewData.teamStatesImg:setSpriteFrame(basename(_res(string.format('ui/home/teamformation/team_states_team%d.png', checkint(teamInfo.teamId)))))
	        else
	        	self.viewData.teamStatesImg:setVisible(false)
	        end
	        -- self.viewData.actionStateLabel:setString(__('编队中'))
	        -- self.viewData.actionStateLabel:setPosition(cc.p(
	        -- self.viewData.actionStateBg:getContentSize().width * offset,
	        -- utils.getLocalCenter(self.viewData.actionStateBg).y + 1))



	        if places[tostring(CARDPLACE.PLACE_ICE_ROOM)] then 
	        	self.viewData.teamIceStatesImg:setVisible(true)
	        else
	        	self.viewData.teamIceStatesImg:setVisible(false)
	    	end
	    else
			self.viewData.actionStateBg:setVisible(false)
			self.viewData.actionStateLabel:setVisible(false)
			self.viewData.teamStatesImg:setVisible(true)
			local keys = table.keys(places)
			local stateKey = keys[1]
			if checkint(stateKey) == CARDPLACE.PLACE_EXPLORE_SYSTEM then
				stateKey = keys[2]
			end
	        local name,state = gameMgr:GetModuleName(stateKey)
	        -- if name then
	        --     self.viewData.actionStateBg:setVisible(true)
	        --     self.viewData.actionStateLabel:setString(name)
	        -- else
	            -- self.viewData.actionStateBg:setVisible(false)
	        -- end
	        if state then
	        	if state ~= 'ice' then
		        	self.viewData.teamStatesImg:setSpriteFrame(basename(_res(string.format('ui/home/teamformation/team_states_%s.png',state))) )
		        else
		        	self.viewData.teamStatesImg:setVisible(false)
		        	self.viewData.teamIceStatesImg:setVisible(true)
		        end
	        else
	        	self.viewData.teamStatesImg:setVisible(false)
	        	self.viewData.teamIceStatesImg:setVisible(false)
	        end
	    end
	end
end
--[[
刷新疲劳警告
--]]
function CardHeadNode:RefreshVigourWarning()
	local vigour = self.cardData.vigour
	if (nil == vigour) or (not self.showVigourState) then
		self:ShowVigourRedWarning(false)
		self:ShowVigourGreyWarning(false)
	elseif 0 == checkint(vigour) then
		self:ShowVigourRedWarning(false)
		self:ShowVigourGreyWarning(true)
	elseif 40 >= checkint(vigour) then
		self:ShowVigourRedWarning(true)
		self:ShowVigourGreyWarning(false)
	else
		self:ShowVigourRedWarning(false)
		self:ShowVigourGreyWarning(false)
	end
end

function CardHeadNode:RefreshRecommendState(isOwnRecommend)
	local recommendImg = self.viewData.recommendImg
	if recommendImg == nil then return end

end

--[[
显示红色疲劳警告
@params visible bool 是否显示
--]]
function CardHeadNode:ShowVigourRedWarning(visible)
	if visible then
		if not self.viewData.vigourRedWarning:isVisible() then
			self.viewData.vigourRedWarning:setVisible(true)
			self.viewData.vigourRedWarning:setOpacity(0)
			local actionSeq = cc.Sequence:create(
				cc.DelayTime:create(math.random(100) * 0.01),
				cc.CallFunc:create(function ()
					local repeatAction = cc.RepeatForever:create(cc.Sequence:create(
						cc.FadeTo:create(1, 255),
						cc.DelayTime:create(0.25),
						cc.FadeTo:create(1, 0))
					)
					self.viewData.vigourRedWarning:runAction(repeatAction)
				end)
			)
			self.viewData.vigourRedWarning:runAction(actionSeq)
		end
	else
		self.viewData.vigourRedWarning:stopAllActions()
		self.viewData.vigourRedWarning:setVisible(false)
	end
end
--[[
显示灰色疲劳警告
@params visible bool 是否显示
--]]
function CardHeadNode:ShowVigourGreyWarning(visible)
	if visible then
		if nil == self.grayFilter then
			self.grayFilter = GrayFilter:create()
		end
		self.viewData.vigoutGreyWarning:setVisible(true)
		-- 逐个子节点设置灰化
		self:SetGray(true)
	else
		self.viewData.vigoutGreyWarning:setVisible(false)
		-- 逐个子节点清除灰化
		self:SetGray(false)
	end
end
function CardHeadNode:isVigoutGreyIsVisible()
	return self.viewData.vigoutGreyWarning:isVisible()
end
--[[
刷新选中状态
@params selected bool 是否被选中
--]]
function CardHeadNode:ShowSelected(selected)
	-- 处于特殊版式不显示选中状态
	if self.specialType ~= 0 then return end
	if nil == self.viewData.selectedNode then
		self.viewData.selectedNode = display.newNSprite(plistMgr:GetSpriteNameByPath(_res('ui/cards/head/kapai_frame_choosed.png')), self:getContentSize().width * 0.5, self:getContentSize().height * 0.5)
		self:addChild(self.viewData.selectedNode)
	end
	self.viewData.selectedNode:setVisible(selected)
end
--[[
刷新成特殊状态
1 移除编队
--]]
function CardHeadNode:RefreshSpecialType()
	if 0 == self.specialType then
		self.viewData.bg:setSpriteFrame(basename(_res('ui/cards/head/kapai_frame_bg.png')))
		if self.viewData.specialLabel then
			self.viewData.specialLabel:setVisible(false)
		end
		self.viewData.frame:setVisible(true)
		self.viewData.cardIcon:setVisible(true)
		if self.viewData.nameBtn then
			self.viewData.nameBtn:setVisible(true)
			self.viewData.nameLabel:setVisible(true)
		end
	elseif 1 == self.specialType then
		self.viewData.bg:setSpriteFrame(basename(_res('ui/cards/head/team_btn_move_team.png')))
		if not self.viewData.specialLabel then
			local size = self.viewData.bg:getContentSize()
			local specialLabel = display.newLabel(size.width/2 , size.height/2 , fontWithColor(9,
		{text = __('移除编队')}
			))
			self.viewData.specialLabel = specialLabel
			self.viewData.notBatchLayout:addChild(specialLabel)
		end
		if self.viewData.particleSpine then
			self.viewData.particleSpine:setVisible(false)
		end
		self.viewData.specialLabel:setVisible(true)
		self.viewData.frame:setVisible(false)
		self.viewData.cardIcon:setVisible(false)
		self.viewData.levelLabel:setVisible(false)
		if self.viewData.nameBtn then
			self.viewData.nameBtn:setVisible(false)
			self.viewData.nameLabel:setVisible(false)
		end
	end
end
--[[
灰化
@params isGray bool 是否灰化
--]]
function CardHeadNode:SetGray(isGray)
	if isGray then
		if nil == self.grayFilter then
			self.grayFilter = GrayFilter:create()
		end
		-- 逐个子节点设置灰化
		self.viewData.frame:setFilter(self.grayFilter)
		self.viewData.cardIcon:setFilter(self.grayFilter)
		self.viewData.levelBg:setFilter(self.grayFilter)
		self.viewData.careerBg:setFilter(self.grayFilter)
		self.viewData.careerIcon:setFilter(self.grayFilter)
		for i,v in ipairs(self.viewData.stars) do
			v:setFilter(self.grayFilter)
		end
	else
		-- 逐个子节点清除灰化
		self.viewData.frame:clearFilter()
		self.viewData.cardIcon:clearFilter()
		self.viewData.levelBg:clearFilter()
		self.viewData.careerBg:clearFilter()
		self.viewData.careerIcon:clearFilter()
		for i,v in ipairs(self.viewData.stars) do
			v:clearFilter()
		end
		self.grayFilter = nil 
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------

---------------------------------------------------
-- get set end --
---------------------------------------------------
return CardHeadNode
