--[[
通用提示板
@params table {
	tag int 弹窗tag
	params table {
		targetNode cc.Node 目标节点
		iconId int 目标icon id
		iconIds table 道具id集合

		type int 1 道具、 2 技能、3 无图标、4 全图标版式、5 功能说明、
				 6 未知、7 堕神显示本命飨灵、 8 契约、9 自定义道具、10 天城演武 对手所有团队信息、
				 11 飨灵收集奖励、12 天城演武 单个团队信息、13 ？？？、14 好友钓场天气、15 包厢buff加成、
				 16 无图标技能说明、17 仙境梦游Boss升级说明、18 打牌游戏 卡牌阵容、19 好友切磋阵容展示、20buff效果（20春活）
				 21 猫屋的猫咪基因

		showHoldAmount bool 是否显示拥有数量
		title 功能标题
		descr string 说明文字
	}
	closeCB 关闭回调
}
--]]
local CommonTipBoard = class('CommonTipBoard', function ()
	return display.newLayer()
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local oriSize = cc.size(365, 194)

local HP_TYPE = 900003

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
constructor
--]]
function CommonTipBoard:ctor( ... )
	self:setName('common.CommonTipBoard')
	print(debug.traceback())
	self.args = unpack({...})


	self.targetNode = self.args.params.targetNode
	self.iconId = checkint(self.args.params.iconId)
	self.iconIds = checktable(self.args.params.iconIds)
	self.type = self.args.params.type or 3
	self.isRich = self.args.params.isRich
	self.richTextW = self.args.params.richTextW
	self.showHoldAmount = self.args.params.showHoldAmount
	self.title = self.args.params.title
	self.descr = self.args.params.descr
	self.goodAddHeight = self.args.params.goodAddHeight
	self.showAmount = self.args.params.showAmount
	self.unlockDes = self.args.params.unlockDes
	self.storyLockDes  = self.args.params.storyLockDes  or ''
	self.buffDes = self.args.params.buffDes or ''
	self.sub = self.args.params.sub
	self.mainIconConf = self.args.params.mainIconConf
	self.cpGroupReward = self.args.params.cpGroupReward
	self.viewTypeData      = self.args.params.viewTypeData
	self.buff = self.args.params.buff
	self.privateRoomBuff = self.args.params.privateRoomBuff
	self.originNum = checkint(self.args.params.originNum)
	self.hideName = self.args.params.hideName
	self.isOnlyDescr = self.args.params.isOnlyDescr
	self.battleCardList_ = self.args.params.battleCards
	self.isDardMode_ = self.type == 18
	self.cardList = self.args.params.cardList
	self.closeCB  = self.args.params.closeCB

	-- self.isShowHpTips = (self.args.params.isShowHpTips == nil) and -1 or self.args.params.isShowHpTips
	-- self.isShowGoodRestoreTip = self.isShowHpTips == 1
	
	local hpGoodsTipCB  = checktable(app.activityHpMgr:GetHpDefineMap(self.iconId)).tipCallback
	self.hpGoodsDefine_ = hpGoodsTipCB and hpGoodsTipCB() or nil
	self.isDualDiamond_ = self.iconId == DIAMOND_ID and checktable(GAME_MODULE_OPEN).DUAL_DIAMOND

	local bgSize = self.args.params.bgSize

	if self.type == 6 then
		oriSize = cc.size(494,242)
	elseif self.type == 7  then
		oriSize = cc.size(450,194)
	elseif self.hpGoodsDefine_ then
		oriSize = cc.size(365, 216 + self.hpGoodsDefine_.tipInfoCount * 25)
	elseif self.isDualDiamond_ then
		oriSize = cc.size(365, 291)
	elseif self.privateRoomBuff then
		if self.type == 15 then
			oriSize = cc.size(365, 150)
		else
			oriSize = cc.size(365, 344)
		end
	elseif self.type == 16 then
		oriSize = cc.size(420, 220)
	elseif self.type == 19 then
		oriSize = cc.size(400, 146)
	elseif bgSize ~= nil then
		oriSize = bgSize
	else
		oriSize = cc.size(365, 194)
		if self.type == 1 then
			local goodsConf = CommonUtils.GetConfig('goods', 'goods', self.iconId) or {}
			local goodsType = CommonUtils.GetGoodTypeById(self.iconId)
			if GoodsType.TYPE_OTHER == goodsType and checkint(goodsConf.effectType) == 8 then
				self.isReality_ = true
				oriSize = cc.size(365, 494)
			end
		end
	end
	self:Init()
end
--[[
init
--]]
function CommonTipBoard:Init()
	self:InitValue()
	self:InitView()
end
--[[
init value
--]]
function CommonTipBoard:InitValue()
end
--[[
init view
--]]
function CommonTipBoard:InitView()

	local function CreateView()

		display.commonUIParams(self, {size = display.size, ap = cc.p(0, 0), po = cc.p(0, 0)})

		local bgSize = cc.size(oriSize.width, oriSize.height)

		local boardImg = self.isDardMode_ and 'ui/ttgame/common/cardgame_common_bg_talk.png' or 'ui/common/common_bg_tips_common.png'
		local boardCut = self.isDardMode_ and cc.rect(15,15,260,50) or cc.dir(10, 10, 10, 10)
		local boardBg  = ui.image({img = _res(boardImg), scale9 = true, ap = ui.lb, size = bgSize, cut = boardCut})
		self:addChild(boardBg, 1)
		-- local bgSize = boardBg:getContentSize()

		-- 好友钓场天气
		local weatherLayout
		if 14 == self.type then
			weatherLayout = CLayout:create(bgSize)
			display.commonUIParams(weatherLayout, { ap = display.LEFT_BOTTOM, po = cc.p(0, 0)})
			boardBg:addChild(weatherLayout,10)

			local weatherTitleLabel = display.newLabel(15, 167, fontWithColor(6, {text = __('天气效果:'), ap = cc.p(0, 0.5)}))
			weatherLayout:addChild(weatherTitleLabel)
			weatherLayout.weatherTitleLabel = weatherTitleLabel

			local weatherLabel = display.newLabel(weatherTitleLabel:getPositionX() + display.getLabelContentSize(weatherTitleLabel).width + 6, 167,
				fontWithColor(6, {text = '', color = 'ee6f6f', ap = cc.p(0, 0.5)}))
			weatherLayout:addChild(weatherLabel)
			weatherLayout.weatherLabel = weatherLabel

			local cutlineImage = display.newImageView(_res('avatar/ui/recipeMess/restaurant_ico_selling_line2'), 183, 150, {scale9 = true, size = cc.size(330, 1)})
			weatherLayout:addChild(cutlineImage)

			local weatherDesrLabel = display.newLabel(15, 142, fontWithColor(15, {text = '', ap = cc.p(0, 1), w = 335, hAlign = display.TAL}))
			weatherLayout:addChild(weatherDesrLabel)
			weatherLayout.weatherDesrLabel = weatherDesrLabel

			local durationLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '00:00:00')
			durationLabel:setAnchorPoint(cc.p(1, 0.5))
			durationLabel:setPosition(cc.p(350, 25))
			weatherLayout:addChild(durationLabel)
			weatherLayout.durationLabel = durationLabel

			local durationTitleLabel = display.newLabel(durationLabel:getPositionX() - durationLabel:getContentSize().width - 6, 25, fontWithColor(6, {text = __('持续时间:'), ap = cc.p(1, 0.5)}))
			weatherLayout:addChild(durationTitleLabel)
		end

		local arrowImg = self.isDardMode_ and 'ui/ttgame/common/cardgame_common_bg_talk_horn.png' or 'ui/common/common_bg_tips_horn.png'
		local boardArrow = display.newImageView(_res(arrowImg), 0, 0)
		boardBg:addChild(boardArrow)
		local titleLabel = nil
		if self.type == 6 then
			titleLabel = display.newLabel(0, 0, fontWithColor('2',{text = 'title',color = '5b3c25'}))
		else
			titleLabel = display.newLabel(0, 0, fontWithColor('8',{text = 'title',}))
		end

		display.commonUIParams(titleLabel, {po = cc.p(bgSize.width * 0.5, bgSize.height - 25)})
		boardBg:addChild(titleLabel)
		titleLabel:setVisible(false)

		local nameFrame = nil
		if self.isReality_ then
			nameFrame = ui.image({img = _res('ui/common/common_bg_tips_s.png'), scale9 = true})
			boardBg:addChild(nameFrame)
		end

		local nameLabel = display.newLabel(105, bgSize.height - 13,fontWithColor('11',{
			text = '',ap = cc.p(0, 1), hAlign = display.TAL
		}))
		boardBg:addChild(nameLabel)

		local amountLabel = display.newLabel(nameLabel:getPositionX(), nameLabel:getPositionY() - 30,fontWithColor('6',
			{text = '', ap = cc.p(0, 1), hAlign = display.TAL}))
		boardBg:addChild(amountLabel)

        local offY = bgSize.height - 10
        if i18n.getLang() ~= 'zh-tw' then
            offY = offY - 50
        end
		local subLabel = display.newLabel(bgSize.width - 10, offY,
			{text = '', fontSize = 20, color = '#c38975', ap = cc.p(1, 1), hAlign = display.TAR})
		boardBg:addChild(subLabel)

		local descrFrame = nil
		if self.isReality_ then
			descrFrame = ui.image({img = _res('ui/common/commcon_bg_text.png'), scale9 = true})
			boardBg:addChild(descrFrame)
		end

		local paddingX = 16
		local descrLabel = display.newLabel(paddingX, bgSize.height * 0.5,fontWithColor('6',
		{text = '',ap = cc.p(0, 1), hAlign = display.TAL, w = bgSize.width - paddingX * 2}))
		boardBg:addChild(descrLabel)

		local descrRichLabel = display.newRichLabel(paddingX, bgSize.height * 0.5,{  w = 30 ,c = {fontWithColor(14 ,  {text = ""} )} })
		boardBg:addChild(descrRichLabel)
		descrRichLabel:setVisible(false)

		local leftImg = display.newImageView(_res('ui/manual/mapoverview/pokedex_maps_ico_cha.png'), 16, 8,
			{ap = cc.p(0, 0)})
		leftImg:setVisible(false)
		boardBg:addChild(leftImg)


		local rightImg = display.newImageView(_res('ui/manual/mapoverview/pokedex_maps_ico_dao.png'), bgSize.width - 20, 8,
			{ap = cc.p(0, 0)})
		rightImg:setVisible(false)
		boardBg:addChild(rightImg)


		local listSize = cc.size(boardBg:getContentSize().width - 10,boardBg:getContentSize().height - 60)

        local scrollView = CScrollView:create(listSize)
        scrollView:setDirection(eScrollViewDirectionVertical)
        scrollView:setAnchorPoint(cc.p(0, 0))
        scrollView:setPosition(cc.p(boardBg:getPositionX(),boardBg:getPositionY()+10))
        self:addChild(scrollView,3)
        -- scrollView:getContainer():setBackgroundColor(cc.c4b(100,100,100,100))
        scrollView:setVisible(false)

        local desLabel = display.newLabel(listSize.width*0.5,listSize.height - 5, fontWithColor(6,{w = listSize.width*0.86,text = ('')}))
        desLabel:setAnchorPoint(cc.p(0.5,1))
        scrollView:getContainer():addChild(desLabel,5)
        scrollView:setContainerSize(cc.size(listSize.width, desLabel:getBoundingBox().height+20))
        desLabel:setPositionY(scrollView:getContainerSize().height - 5)
        scrollView:setContentOffsetToTop()

		local bottomLayer = display.newLayer(0, 0, {size = cc.size(bgSize.width, bgSize.height * 0.35)})
		bottomLayer:setVisible(false)
		boardBg:addChild(bottomLayer)
		
		local restoreTipLabels = {}
		local rightLabels = {}

		if self.hpGoodsDefine_ or self.isDualDiamond_ then
			local dualDiamondDefines = {
				{descr = __('有偿幻晶石:'), value = 0},
				{descr = __('无偿幻晶石:'), value = 0},
				{descr = __('幻晶石总计:'), value = 0},
			}

			-- 分割线 avatar/ui/restaurant_ico_selling_line.png
			local allInfoCount = self.isDualDiamond_ and #dualDiamondDefines or self.hpGoodsDefine_.tipInfoCount
			local sellingLineY = allInfoCount * 25
			local sellingLine  = display.newImageView(_res('avatar/ui/restaurant_ico_selling_line.png'), bgSize.width / 2, sellingLineY + 20)
			bottomLayer:addChild(sellingLine)
			
			for index = 1, allInfoCount do
				local dddef = self.isDualDiamond_ and dualDiamondDefines[index] or nil
				local descr = dddef and dddef.descr or tostring(self.hpGoodsDefine_.getTipDescr(index, self.iconId))
				local value = dddef and dddef.value or tostring(self.hpGoodsDefine_.getTipValue(index, self.iconId))
				local infoY = sellingLineY - (index - 1) * 25

				local descrLabel = display.newLabel(0, 0, fontWithColor(6,{text = descr, ap = display.LEFT_CENTER}))
				descrLabel:setPosition(cc.p(bgSize.width * 0.06, infoY))
				bottomLayer:addChild(descrLabel)
				table.insert(restoreTipLabels, descrLabel)

				local valueLabel = display.newLabel(0, 0, fontWithColor(6,{text = value, color = '#BA5C5C', ap = display.RIGHT_CENTER}))
				valueLabel:setPosition(cc.p(bgSize.width * 0.94, infoY))
				bottomLayer:addChild(valueLabel)
				table.insert(rightLabels, valueLabel)
			end
		end

		return {
			boardBg = boardBg,
			boardArrow = boardArrow,
			titleLabel = titleLabel,
			mainIcon = nil,
			nameFrame = nameFrame,
			nameLabel = nameLabel,
			amountLabel = amountLabel,
			subLabel = subLabel,
			descrRichLabel = descrRichLabel ,
			descrFrame = descrFrame,
			descrLabel = descrLabel,
			scrollView = scrollView,
			desLabel = desLabel,
			leftImg = leftImg,
			rightImg = rightImg,
			bottomLayer = bottomLayer,
			rightLabels = rightLabels,
			restoreTipLabels = restoreTipLabels,
			weatherLayout = weatherLayout,
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	-- 重写触摸
	self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    -- self.touchListener_:setSwallowTouches(true)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchCanceled_), cc.Handler.EVENT_TOUCH_CANCELLED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)

	self:RefreshTipBoardContent()
	self:RefreshTipBoardPos()
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------


---------------------------------------------------
-- refreash logic begin --
---------------------------------------------------
--[[
刷新内容
--]]
function CommonTipBoard:RefreshTipBoardContent()
	if 1 == self.type then
		self:RefreshTipBoardContentGoods()
	elseif 2 == self.type then
		self:RefreshTipBoardContentSkill()
	elseif 3 == self.type then
		self:RefreshTipBoardContentNoIcon()
	elseif 4 == self.type then
		self:RefreshTipBoardContentAllIcon()
	elseif 5 == self.type then
		self:RefreshTipBoardFunctionDescr()
	elseif 6 == self.type then
		self:RefreshTipBoardFunctionScorllviewDescr()
	elseif 7 == self.type then
		self:RefreshTipBoardContentPetAndExclusiveCard()
	elseif 8 == self.type then
		self:RefreshTipBoardContentContract()--契约
	elseif 9 == self.type then
		self:RefreshTipBoardContentCustomGood()-- 自定义道具
	elseif 10 == self.type then
		self:RefreshTipBoardContentTagMatchTeamInfo()  -- 团队信息
	elseif 11 == self.type then
		self:RefreshTipBoardContentCardGatherReward()--飨灵收集奖励
	elseif 12 == self.type then
		self:RefreshTipBoardContentTagMatchSingleTeamInfo()  -- 单个团队信息
	elseif 13 == self.type then
		self:RefreshTipBoardContentGoodRestore()
	elseif 14 == self.type then
		self:RefreshTipBoardContentFriendWeather()	-- 好友钓场天气
	elseif 15 == self.type then
		self:RefteshTipBoardContentPrivateRoomBuff() -- 包厢buff
	elseif 16 == self.type then
		self:RefreshTipBoardContentNoIconSkillDescr() -- 无图标技能说明
	elseif 17 == self.type then
		self:RefreshTipBoardContentAnniversary19BossUpgradeDescr() -- 仙境梦游Boss升级说明
	elseif 18 == self.type then
		self:RefreshTipBoardContentTTgameCardList() -- 打牌游戏卡牌阵容
	elseif 19 == self.type then
		self:RefreshTipBoardContentTeamList() -- 好友切磋阵容
	elseif 20 == self.type then
		self:RefreshTipBoardContentBuffEffect() -- buff效果（20春活）
	elseif 21 == self.type then
		self:RefreshTipBoardCatGeneDescr() -- 猫咪基因描述
	end
	self:RefreshTipBoardSize()
end
--[[
刷新技能版式
--]]
function CommonTipBoard:RefreshTipBoardContentSkill()
	if self.viewData.mainIcon then
		self.viewData.mainIcon:removeFromParent()
	end
	self.viewData.mainIcon = require('common.SkillNode').new({id = self.iconId})
	self.viewData.boardBg:addChild(self.viewData.mainIcon)
	display.commonUIParams(self.viewData.mainIcon, {po = cc.p(5, self.viewData.boardBg:getContentSize().height - 5), ap = cc.p(0, 1)})
	self.viewData.mainIcon:setScale(0.75)

	local skillConf = CardUtils.GetSkillConfigBySkillId(self.iconId)
	if not skillConf then
		self.viewData.descrLabel:setString(string.fmt('配表中未找到该技能>>>%1', tostring(self.iconId)))
		return
	end
	if table.nums(skillConf) == 0 then
		skillConf = CommonUtils.GetConfig('player', 'skill', self.iconId)
	end

	if table.nums(skillConf) > 0 then
		self.viewData.nameLabel:setString(skillConf.name)
		self.viewData.amountLabel:setString(string.format(__('等级：%d'), 1))
		-- self.viewData.subLabel:setString(CommonUtils.GetConfig('goods', 'type', CommonUtils.GetGoodTypeById(self.iconId)).type)
		self.viewData.descrLabel:setString(skillConf.descr)
	end
end
--[[
刷新道具版式
--]]
function CommonTipBoard:RefreshTipBoardContentGoods()
	if self.viewData.mainIcon then
		self.viewData.mainIcon:removeFromParent()
	end

	
	local goodsType = CommonUtils.GetGoodTypeById(self.iconId)
	if GoodsType.TYPE_TTGAME_CARD == goodsType then
		local cardNode = TTGameUtils.GetBattleCardNode({cardId = self.iconId, zoomModel = 's'})
		cardNode:setAnchorPoint(display.LEFT_BOTTOM)
		cardNode:setPosition(cc.p(15,25))
		cardNode:setScale(0.8)
		local goodsNode = display.newButton(0, 0, {n = _res('ui/common/story_tranparent_bg.png'), scale9 = true, size = cardNode:getContentSize()})
		goodsNode:setCascadeOpacityEnabled(true)
		goodsNode:addChild(cardNode)
		self.viewData.mainIcon = goodsNode
	else
		if self.isReality_ then
			local iconLayer = ui.layer({bg = _res('ui/common/personal_reward_box_bg_icon_big.png')})
			iconLayer:addList(ui.goodsImg({goodsId = self.iconId, isBig = true})):alignTo(nil, ui.cc)
			self.viewData.mainIcon = iconLayer
		else
			self.viewData.mainIcon = require('common.GoodNode').new({id = self.iconId})
		end
	end

	if #self.viewData.restoreTipLabels > 0 then
		local maxWidth = 0
		for i, restoreTipLabel in ipairs(self.viewData.restoreTipLabels) do
			maxWidth = math.max(maxWidth, display.getLabelContentSize(restoreTipLabel).width)
		end
		if maxWidth > 235 then
			local parentNodeSize = self.viewData.boardBg:getContentSize()
			parentNodeSize.width = parentNodeSize.width + maxWidth - 235 + 80
			self.viewData.boardBg:setContentSize(parentNodeSize)
			for i,v in ipairs(self.viewData.rightLabels) do
				v:setPositionX(parentNodeSize.width * 0.96)
			end
			self.viewData.subLabel:setPositionX(parentNodeSize.width - 10)
			display.commonLabelParams(self.viewData.descrLabel, fontWithColor('6',
				{text = '',ap = cc.p(0, 1), hAlign = display.TAL, w = parentNodeSize.width - 32}))
		end
	end

	-- update icon
	self.viewData.boardBg:addChild(self.viewData.mainIcon)
	if self.isReality_ then
		display.commonUIParams(self.viewData.mainIcon, {po = cc.p(self.viewData.boardBg:getContentSize().width/2, self.viewData.boardBg:getContentSize().height - 10), ap = cc.p(0.5, 1)})
	else
		display.commonUIParams(self.viewData.mainIcon, {po = cc.p(10, self.viewData.boardBg:getContentSize().height - 10), ap = cc.p(0, 1)})
		self.viewData.mainIcon:setScale(0.7)
	end

	-- update name
	local goodsName  = ''
	local goodsDescr = ''
	local goodsConf  = CommonUtils.GetConfig('goods', 'goods', self.iconId) or {}
	if next(goodsConf) == nil then
		if self.iconId == EXP_ID then
			goodsName  = __('经验值')
			goodsDescr = __('玩家经验')
		elseif self.iconId == UNION_CONTRIBUTION_POINT_ID then
			goodsName  = __('工会贡献值')
			goodsDescr = __('玩家进行工会相关活动获得的贡献值可为工会增加相等的贡献值，当贡献值达到一定数量后可提升工会等级')
		elseif self.iconId == CARD_EXP_ID then
			goodsName  = __('飨灵经验')
			goodsDescr = __('用于提升飨灵的等级')
		else
			goodsName  = tostring(self.iconId)
			goodsDescr = string.fmt('配表中未找到该道具>>>%1', tostring(self.iconId))
		end
	end
	self.viewData.nameLabel:setString(goodsConf.name or goodsName)
	if self.isReality_ then
		self.viewData.nameLabel:setWidth(0)
		self.viewData.nameLabel:setAnchorPoint(ui.cc)
		display.commonLabelParams(self.viewData.nameLabel, fontWithColor(14))
		self.viewData.nameLabel:alignTo(self.viewData.mainIcon, ui.cb, {offsetY = -10})
		if self.viewData.nameFrame then
			self.viewData.nameFrame:setContentSize(cc.size(self.viewData.boardBg:getContentSize().width - 100, 40))
			self.viewData.nameFrame:setAnchorPoint(ui.cc)
			self.viewData.nameFrame:setOpacity(200)
			self.viewData.nameFrame:setPositionX(self.viewData.nameLabel:getPositionX())
			self.viewData.nameFrame:setPositionY(self.viewData.nameLabel:getPositionY())
		end
	end

	-- update type
	local typeId = CommonUtils.GetGoodTypeById(self.iconId)
	local str = ""
	if checkint(typeId) == checkint(GoodsType.TYPE_ARCHIVE_REWARD)  then
		local goodsData = CommonUtils.GetConfigAllMess('achieveReward','goods')
		local goodOneData = goodsData[tostring(self.iconId)]
		if goodOneData then
			local rewardType = checkint(goodOneData.rewardType)
			if rewardType == 1 then
				str = __('奖杯')
			elseif rewardType == 2 then
				str = __('头像')
			elseif rewardType == 3 then
				str = __('头像框')
			end
		end
	else
		local typeData =  CommonUtils.GetConfig('goods', 'type', typeId) or {}
		if self.isReality_ then
			str = __('周边')
		else
			str = tostring(typeData.type)
		end
	end
	display.commonLabelParams(self.viewData.subLabel , {text = str , reqW = 250 })
	if self.isReality_ then
		self.viewData.subLabel:setAnchorPoint(ui.cc)
		self.viewData.subLabel:alignTo(self.viewData.nameLabel, ui.cb, {offsetY = -10})
	end

	-- update descr
    if checkint(self.iconId) == TIPPING_ID then
        --餐厅厨力点描述特殊处理
        local resLevel = gameMgr:GetUserInfo().restaurantLevel
        local levelConf = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', resLevel)
        if levelConf and goodsConf.descr then
            local descr = string.fmt(goodsConf.descr, {_target_id_ = resLevel, _target_num_ = levelConf.tipLimit})
			self.viewData.descrLabel:setString(descr)
		else
			self.viewData.descrLabel:setString(goodsDescr)
        end
    else
        self.viewData.descrLabel:setString(goodsConf.descr or goodsDescr)
	end
	if self.isReality_ then
		display.commonLabelParams(self.viewData.descrLabel, {w = self.viewData.boardBg:getContentSize().width - 45})
		self.viewData.descrLabel:setPositionX(30)
		self.viewData.descrLabel:setPositionY(self.viewData.subLabel:getPositionY() - 30)
		if self.viewData.descrFrame then
			self.viewData.descrFrame:setContentSize(cc.size(self.viewData.boardBg:getContentSize().width - 45, 100))
			self.viewData.descrFrame:setAnchorPoint(ui.lt)
			self.viewData.descrFrame:setPositionX(self.viewData.descrLabel:getPositionX() - 8)
			self.viewData.descrFrame:setPositionY(self.viewData.descrLabel:getPositionY() + 8)
		end
	end

	-- update amount
	if self.showHoldAmount then
		self.viewData.amountLabel:setString(string.format(__('数量：%d'), gameMgr:GetAmountByGoodId(self.iconId)))
	end

	if self.hpGoodsDefine_ then
		self.viewData.bottomLayer:setVisible(true)
		self.viewData.descrLabel:setPositionY(oriSize.height - 95)

		local countdownKey = CommonUtils.getCurrencyRestoreKeyByGoodsId(self.iconId)
		gameMgr:removeDownCountUi(countdownKey)
		gameMgr:downCountUi(countdownKey, function(field1, field2)
			if not (self.viewData and self.viewData.rightLabels[1]) then
                return
			end
			
			for index = 1, self.hpGoodsDefine_.tipInfoCount do
				local value = tostring(self.hpGoodsDefine_.getTipValue(index, self.iconId))
				self.viewData.rightLabels[index]:setString(value)
			end
		end)
	
	elseif self.isDualDiamond_ then
		self.viewData.bottomLayer:setVisible(true)
		self.viewData.descrLabel:setPositionY(oriSize.height / 2 + 50)
		local userInfo = gameMgr:GetUserInfo()
		if userInfo.paidDiamond > userInfo.diamond then
			userInfo.paidDiamond = userInfo.diamond
		end
		self.viewData.rightLabels[1]:setString(userInfo.paidDiamond)
		self.viewData.rightLabels[2]:setString(userInfo.diamond - userInfo.paidDiamond)
		self.viewData.rightLabels[3]:setString(userInfo.diamond)

	else
		self.viewData.bottomLayer:setVisible(false)
	end

	if self.privateRoomBuff then
		self.viewData.descrLabel:setPositionY(self.viewData.descrLabel:getPositionY() + 75)
		local layoutSize = cc.size(oriSize.width, 150)
		local layout = CLayout:create(layoutSize)
		display.commonUIParams(layout, {po = cc.p(0, 0), ap = cc.p(0, 0)})
		self.viewData.boardBg:addChild(layout, 10)
		local title = display.newLabel(layoutSize.width / 2, layoutSize.height - 33, fontWithColor(6, {text = __('资源加成')}))
		layout:addChild(title)
		for i = 1, 2 do
			local line = display.newImageView(_res("ui/home/takeaway/takeout_line.png"), layoutSize.width / 2, layoutSize.height - 60 - (i - 1) * 40, {scale9 = true, size = cc.size(330, 2)})
			layout:addChild(line)
			local icon = display.newImageView(CommonUtils.GetGoodsIconPathById(self.iconId), 315, layoutSize.height - 80 - (i - 1) * 40)
			icon:setScale(0.2)
			layout:addChild(icon)
		end
		local souvenirLabel = display.newLabel(176, 70, fontWithColor(16, {text = __('纪念品加成'), ap = cc.p(1, 0.5)}))
		layout:addChild(souvenirLabel)
		local souvenirAddition = self.privateRoomBuff.souvenir.add
		local souvenirNum = display.newLabel(290, 70, fontWithColor(10, {text = '+' .. tostring(souvenirAddition), ap = cc.p(1, 0.5)}))
		layout:addChild(souvenirNum)
		local themeLabel = display.newLabel(176, 30, fontWithColor(16, {text = __('主题加成'), ap = cc.p(1, 0.5)}))
		layout:addChild(themeLabel)
		local themeAddition = self.privateRoomBuff.theme.add
		local themeNum = display.newLabel(290, 30, fontWithColor(10, {text = '+' .. tostring(themeAddition), ap = cc.p(1, 0.5)}))
		layout:addChild(themeNum)
	end
end
--[[
刷新无图标版式
--]]
function CommonTipBoard:RefreshTipBoardContentNoIcon()

end
--[[
刷新全图标板式
--]]
function CommonTipBoard:RefreshTipBoardContentAllIcon()
	-- dump(self.iconIds)
	-- local nameLabel = display.newLabel(self.viewData.boardBg:getContentSize().width * 0.5,self.viewData.boardBg:getContentSize().height * 0.9,
	-- 	fontWithColor('6',{text = __('奖励预览'), fontSize = 24, ap = cc.p(0.5, 1), hAlign = display.TAL}))
	-- self.viewData.boardBg:addChild(nameLabel)

	self.type4Icons = {}

	self.viewData.titleLabel:setVisible(true)
	display.commonLabelParams(self.viewData.titleLabel , { text = self.title or __('奖励预览') , w =365,hAlign = display.TAC })
	--self.viewData.titleLabel:setString(self.title or __('奖励预览'))
	local showAmount = true
	if self.showAmount == false then
		showAmount = false
	end
	for i,v in pairs(self.iconIds) do
		local goodsNode = nil
		local goodsType = CommonUtils.GetGoodTypeById(v.goodsId)
		if GoodsType.TYPE_TTGAME_CARD == goodsType then
			local cardNode = TTGameUtils.GetBattleCardNode({cardId = v.goodsId, zoomModel = 's'})
			cardNode:setAnchorPoint(display.LEFT_BOTTOM)
			goodsNode = display.newButton(0, 0, {n = _res('ui/common/story_tranparent_bg.png'), scale9 = true, size = cardNode:getContentSize()})
			goodsNode:setCascadeOpacityEnabled(true)
			goodsNode:addChild(cardNode)
			cardNode:setScale(0.95)
		else
			goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = showAmount, showName = not self.hideName})
		end
		self.viewData.boardBg:addChild(goodsNode)
		display.commonUIParams(goodsNode, {po = cc.p(30 + 110*(i-1), self.viewData.boardBg:getContentSize().height * 0.5+ checkint(self.goodAddHeight) ), ap = cc.p(0, 0.5)})
		goodsNode:setScale(0.8)

		table.insert(self.type4Icons, goodsNode)
	end

	if table.nums(self.iconIds) > 3 then
		self.viewData.boardBg:setContentSize(cc.size(122*table.nums(self.iconIds), 200))
	else
		self.viewData.boardBg:setContentSize(cc.size(self.viewData.boardBg:getContentSize().width + 20, 200) )
	end

	if nil ~= self.descr and  not self.isRich then
		display.commonUIParams(self.viewData.descrLabel, {ap = cc.p(0.5, 1), po = cc.p(self.viewData.boardBg:getContentSize().width * 0.5, self.viewData.boardBg:getContentSize().height - 40)})
		self.viewData.descrLabel:setString(self.descr)
	else
	end
end
--[[
刷新功能说明
--]]
function CommonTipBoard:RefreshTipBoardFunctionDescr()
	if nil ~= self.title then
		self.viewData.titleLabel:setVisible(true)
		self.viewData.titleLabel:setString(self.title)
	end
	if nil ~= self.descr and  not self.isRich then
		display.commonUIParams(self.viewData.descrLabel, {ap = cc.p(0.5, 1), po = cc.p(self.viewData.boardBg:getContentSize().width * 0.5, self.viewData.boardBg:getContentSize().height - 40)})
		self.viewData.descrLabel:setString(self.descr)
	else
		if  self.descr and table.nums(self.descr  ) > 0 then
			if self.richTextW then
				self.viewData.descrRichLabel:setMaxLineLength(checkint(self.richTextW))
			end
			display.commonUIParams(self.viewData.descrRichLabel, {ap = cc.p(0.5, 1), po = cc.p(self.viewData.boardBg:getContentSize().width * 0.5, self.viewData.boardBg:getContentSize().height - 40)})
			display.reloadRichLabel(self.viewData.descrRichLabel, { c = self.descr or {}})
			self.viewData.descrRichLabel:setVisible(true)
		end

	end
	if self.isOnlyDescr then
		local labelSize = display.getLabelContentSize(self.viewData.descrLabel)
		self.viewData.boardBg:setContentSize(cc.size(labelSize.width + 20, labelSize.height + 20))
		self.viewData.descrLabel:setHorizontalAlignment(labelSize.height < 30 and display.TAC or display.TAL)
		display.commonUIParams(self.viewData.descrLabel, {ap = cc.p(0.5, 1), po = cc.p(self.viewData.boardBg:getContentSize().width * 0.5, self.viewData.boardBg:getContentSize().height - 10)})
	end
end

--[[
带滑动层描述
--]]
function CommonTipBoard:RefreshTipBoardFunctionScorllviewDescr()
	if nil ~= self.title then
		self.viewData.titleLabel:setVisible(true)
		self.viewData.titleLabel:setString(self.title)
	end
	if nil ~= self.descr then
		self.viewData.leftImg:setVisible(true)
		self.viewData.rightImg:setVisible(true)

		self.viewData.scrollView:setVisible(true)
		self.viewData.desLabel:setString(self.descr)

		self.viewData.scrollView:setContainerSize(cc.size(self.viewData.scrollView:getContentSize().width, self.viewData.desLabel:getBoundingBox().height+20))
		self.viewData.desLabel:setPositionY(self.viewData.scrollView:getContainerSize().height - 5)
		self.viewData.scrollView:setContentOffsetToTop()
	end
end
--[[
刷新堕神说明 附带本命飨灵
--]]
function CommonTipBoard:RefreshTipBoardContentPetAndExclusiveCard()
	self:RefreshTipBoardContentGoods()

	local descrLabelContentSize = display.getLabelContentSize(self.viewData.descrLabel)
	local petConfig = CommonUtils.GetConfig('pet', 'pet', self.iconId)

	local petExclusiveCardExtraHeight = 0

	if nil ~= petConfig.exclusiveCard and 0 < #petConfig.exclusiveCard then

		-- 本命文字
		local exclusiveCardLabel = display.newLabel(0, 0, fontWithColor('11', {text = __('本命飨灵'), ap = cc.p(0, 0.5)}))
		local exclusiveCardLabelSize = display.getLabelContentSize(exclusiveCardLabel)
		display.commonUIParams(exclusiveCardLabel, {po = cc.p(
			self.viewData.descrLabel:getPositionX(),
			self.viewData.descrLabel:getPositionY() - descrLabelContentSize.height - 5 - exclusiveCardLabelSize.height * 0.5
		)})
		self.viewData.boardBg:addChild(exclusiveCardLabel)
		self.viewData.exclusiveCardLabel = exclusiveCardLabel

		-- 本命头像
		self.viewData.exclusiveCardHeadNode = {}
		local cardId = nil
		local headNodePerLine = 7
		local fixedWidth = self.viewData.boardBg:getContentSize().width - (exclusiveCardLabel:getPositionX() * 2)
		local cellSize = cc.size(
			fixedWidth / headNodePerLine,
			fixedWidth / headNodePerLine)
		local itor = 0
        local maxLen = 0 --这里计算不为空的卡牌数量
		--之前存在bug，配的宠物卡牌却在卡牌配表里查找不到

        for _,v in ipairs(petConfig.exclusiveCard) do
			if isChinaSdk() then
				local cardConfig = CommonUtils.GetConfigAllMess('onlineResourceTrigger' , 'card')[tostring(v)]
				if nil ~= cardConfig then maxLen = maxLen + 1 end
			else
				local cardConfig = CardUtils.GetCardConfig(v)
				if nil ~= cardConfig then maxLen = maxLen + 1 end
			end

        end
		for i,v in ipairs(petConfig.exclusiveCard) do
			cardId = checkint(v)
			local cardConfig = CardUtils.GetCardConfig(cardId)
			if nil ~= cardConfig then
				itor = itor + 1
				local cardHeadNode = require('common.CardHeadNode').new({
					cardData = {
						cardId = cardId,
						level = 1,
						breakLevel = 0,
						skinId = CardUtils.GetCardSkinId(cardId)
					},
					showBaseState = false
				})
				cardHeadNode:setScale((cellSize.width - 5) / cardHeadNode:getContentSize().width)
				cardHeadNode:setPosition(cc.p(
					exclusiveCardLabel:getPositionX() + cellSize.width * ((itor - 1) % headNodePerLine + 0.5),
					exclusiveCardLabel:getPositionY() - exclusiveCardLabelSize.height * 0.5 - cellSize.height * (math.ceil(itor / headNodePerLine) - 0.5)
				))
				self.viewData.boardBg:addChild(cardHeadNode)

				table.insert(self.viewData.exclusiveCardHeadNode, cardHeadNode)

			end
		end
		petExclusiveCardExtraHeight = math.ceil( maxLen / headNodePerLine ) * cellSize.height + descrLabelContentSize.height + 5

	end

	self.petExclusiveCardExtraHeight = petExclusiveCardExtraHeight

end

--[[
刷新契约说明
--]]
function CommonTipBoard:RefreshTipBoardContentContract()
    local titleBtn = display.newButton(0,0,{
        n = _res('ui/common/common_title_3.png'),-- common_click_back
    })
    titleBtn:setEnabled(false)
	local parentNode =self.viewData.titleLabel:getParent()
	local parentNodeSize = parentNode:getContentSize()
	local buffLabel = display.newLabel(0, 0, fontWithColor(6,{text = self.buffDes  or ''}))
	local buffLabelSize = display.getLabelContentSize(buffLabel)
	local height = 0
	if buffLabelSize.height > 60  then
		height = buffLabelSize.height - 60
	end
	parentNodeSize = cc.size(parentNodeSize.width , parentNodeSize.height + height + 30 )
	self.viewData.boardBg:setContentSize(parentNodeSize)
	self.viewData.titleLabel:setPosition(cc.p(parentNodeSize.width/2  , parentNodeSize.height- 25 ))
    display.commonLabelParams(titleBtn, fontWithColor(4,{text = self.title}))

    titleBtn:setPosition(self.viewData.titleLabel:getPosition())
    self.viewData.titleLabel:getParent():addChild(titleBtn)


	local contractLockLabel = display.newLabel(0, 0, fontWithColor(6,{text = self.unlockDes and __('解锁条件：好感度达到') or ''}))
	contractLockLabel:setPosition(cc.p(self.viewData.titleLabel:getPositionX() - 36,self.viewData.titleLabel:getPositionY() - 50))
	self.viewData.titleLabel:getParent():addChild(contractLockLabel)

	if self.unlockDes then
		local loveLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', self.unlockDes)
		loveLabel:setAnchorPoint(cc.p(0, 0.5))
		loveLabel:setPosition(cc.p(contractLockLabel:getPositionX() + display.getLabelContentSize(contractLockLabel).width / 2,contractLockLabel:getPositionY()))
		self.viewData.titleLabel:getParent():addChild(loveLabel)
	end

	local lineImg = display.newImageView(_res('ui/common/kitchen_tool_split_line.png'), 0, 0,
	{ap = cc.p(0.5, 0.5)})
	lineImg:setPosition(cc.p(contractLockLabel:getPositionX() + 36,contractLockLabel:getPositionY() - 30))
	self.viewData.titleLabel:getParent():addChild(lineImg)
	lineImg:setScaleX(0.58)


	local storyLockLabel = display.newLabel(0, 0, fontWithColor(6,{text = self.storyLockDes or '', ap = cc.p(0, 0.5)}))
	storyLockLabel:setPosition(cc.p(30,lineImg:getPositionY() - 30))
	self.viewData.titleLabel:getParent():addChild(storyLockLabel)

	buffLabel:setAnchorPoint(display.LEFT_TOP)
	buffLabel:setPosition(cc.p(30,lineImg:getPositionY() - 44))

	self.viewData.titleLabel:getParent():addChild(buffLabel)
end

--[[
飨灵收集奖励
--]]
function CommonTipBoard:RefreshTipBoardContentCardGatherReward()
	local parentNode = self.viewData.titleLabel:getParent()
	local parentNodeSize = parentNode:getContentSize()
	self.viewData.titleLabel:setString(__('奖励要求'))
	self.viewData.titleLabel:setVisible(true)

	local cutline = display.newImageView(_res('ui/prize/collect_prize_area_ico_line.png')
		, parentNodeSize.width / 2, parentNodeSize.height - 96, {scale = 0.7})
	parentNode:addChild(cutline)

	if self.rewardGoods and next(self.rewardGoods) then
		for k, v in pairs(self.rewardGoods) do
			v:removeFromParent()
		end
	end
	self.rewardGoods = {}
	for k, v in pairs(self.cpGroupReward.rewards) do
		local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true})
		goodsNode:setTag(tonumber(v.goodsId))
		self:addChild(goodsNode,3)
		table.insert(self.rewardGoods, goodsNode)
	end

	-- 星级总数
	local starCountLabel = display.newRichLabel(parentNodeSize.width / 2 - 5,parentNodeSize.height - 52,
		{ ap = cc.p(0.5, 0.5) })
	parentNode:addChild(starCountLabel)
	starCountLabel:insertElement(cc.Label:createWithBMFont(tonumber(self.cpGroupReward.starCount) >= tonumber(self.cpGroupReward.require.star)
		and 'font/small/common_text_num.fnt' or 'font/small/common_text_num_5.fnt', tostring(self.cpGroupReward.starCount)))
	starCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '/'))
	starCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', tostring(self.cpGroupReward.require.star)))
	starCountLabel:reloadData()
	local starImage = display.newImageView(_res('ui/common/common_star_l_ico.png')
		, starCountLabel:getContentSize().width / 2 + parentNodeSize.width / 2 + 12, starCountLabel:getPositionY(), {scale = 0.6})
	parentNode:addChild(starImage)

	-- 契约等级
	local contractLevelCountLabel = display.newRichLabel(parentNodeSize.width / 2 - 5,parentNodeSize.height - 78,
		{ ap = cc.p(0.5, 0.5) })
	parentNode:addChild(contractLevelCountLabel)
	contractLevelCountLabel:insertElement(cc.Label:createWithBMFont(tonumber(self.cpGroupReward.contractCount) >= tonumber(self.cpGroupReward.require.love)
		and 'font/small/common_text_num.fnt' or 'font/small/common_text_num_5.fnt', tostring(self.cpGroupReward.contractCount)))
	contractLevelCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '/'))
	contractLevelCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', tostring(self.cpGroupReward.require.love)))
	contractLevelCountLabel:reloadData()
	local heartImage = display.newImageView(_res('ui/prize/collect_prize_contract_ico.png')
		, starCountLabel:getContentSize().width / 2 + parentNodeSize.width / 2 + 12, contractLevelCountLabel:getPositionY() + 1, {scale = 0.6})
	parentNode:addChild(heartImage)
end

--[[
自定义道具
]]
function CommonTipBoard:RefreshTipBoardContentCustomGood()
	-- print(self.title, self.descr)
	if self.viewData.mainIcon then
		self.viewData.mainIcon:removeFromParent()
	end

	if self.mainIconConf then
		local bgPath = self.mainIconConf.bg
		local imgPath = self.mainIconConf.img

		self.viewData.mainIcon = display.newImageView(bgPath, 10, self.viewData.boardBg:getContentSize().height - 10, {ap = display.LEFT_TOP})
		local nodeSize = self.viewData.mainIcon:getContentSize()
		local img = display.newImageView(imgPath, nodeSize.width / 2, nodeSize.height / 2, {ap = display.CENTER})
		img:setScale(0.55)
		self.viewData.mainIcon:addChild(img)

		self.viewData.boardBg:addChild(self.viewData.mainIcon)
		self.viewData.mainIcon:setScale(0.7)
	end

	if self.title then
		self.viewData.nameLabel:setString(tostring(self.title))
	end

	if self.descr then
		self.viewData.descrLabel:setString(tostring(self.descr))
	end

	if self.sub then
		self.viewData.subLabel:setString(tostring(self.sub))
	end

	self.viewData.bottomLayer:setVisible(false)
end

--[[
所有团队信息
--]]
function CommonTipBoard:RefreshTipBoardContentTagMatchTeamInfo()
	local boardBg = self.viewData.boardBg
	local boardSize = boardBg:getContentSize()

	local totalManaLabel = display.newLabel(boardSize.width / 2 + 50, boardSize.height - 30, {ap = display.RIGHT_TOP, fontSize = 30, color = '#ffffee',font = TTF_GAME_FONT, ttf = true, outline = '#ad6028', outlineSize = 1})
	display.commonLabelParams(totalManaLabel, {text = tostring(self.title)})
	boardBg:addChild(totalManaLabel)
	local totalManaLabelSize = display.getLabelContentSize(totalManaLabel)

	local fireSpine = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
	fireSpine:update(0)
    fireSpine:setAnimation(0, 'huo', true)
    fireSpine:setPosition(cc.p(totalManaLabel:getPositionX() + 70, totalManaLabel:getPositionY() - totalManaLabelSize.height))
	boardBg:addChild(fireSpine)

	local fight_num = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '')
    display.commonUIParams(fight_num, {ap = cc.p(0.5, 0.5), po = cc.p(fireSpine:getPositionX(), fireSpine:getPositionY() + 10)})
	fight_num:setHorizontalAlignment(display.TAR)
    fight_num:setScale(0.7)
	boardBg:addChild(fight_num, 1)

	local teamInfo = self.viewTypeData.teamInfo or {}
	-- logInfo.add(5, tableToString(teamInfo))
	local totalBattlePoint = 0
	for teamId, teamDatas in pairs(teamInfo) do
		local teamBg = display.newImageView(_res('ui/tagMatch/rob_record_bg_team_list.png'), 0, 0)
		local teamBgSize = teamBg:getContentSize()
		display.commonUIParams(teamBg, {po = cc.p(boardSize.width / 2, boardSize.height - 80 - (teamBgSize.height + 5) * (checkint(teamId) - 1) ), ap = display.CENTER_TOP})
		boardBg:addChild(teamBg)

		local singleCardW = teamBgSize.width / MAX_TEAM_MEMBER_AMOUNT - 5

		local battlePoint = checkint(teamDatas.battlePoint)
		totalBattlePoint = totalBattlePoint + battlePoint

		teamBg:addChild(display.newLabel(teamBgSize.width - 15, teamBgSize.height - 20, fontWithColor(9, {ap = display.RIGHT_CENTER, text = string.format(__('灵力  %s'), battlePoint)})))

		local cards = teamDatas.cards or teamDatas
		for i = 1, MAX_TEAM_MEMBER_AMOUNT do
			local teamData = cards[i]

			if teamData and next(teamData) ~= nil then
				local cardData = {cardId = teamData.cardId, level = checkint(teamData.level), breakLevel = checkint(teamData.breakLevel), skinId = checkint(teamData.defaultSkinId), favorabilityLevel = teamData.favorabilityLevel}
				local cardHeadNode = require('common.CardHeadNode').new({cardData = teamData, showBaseState = true, showActionState = false, showVigourState = false})
				local cardNodeW = cardHeadNode:getContentSize().width
				local cardScale = singleCardW / cardNodeW
				cardHeadNode:setScale(cardScale)
				cardHeadNode:setPosition(cc.p(10 + (i-1) * singleCardW + 2, 50))
				cardHeadNode:setAnchorPoint(display.LEFT_CENTER)
				teamBg:addChild(cardHeadNode)

			end
		end
	end

	fight_num:setString(totalBattlePoint)

end

--[[
单个团队信息
--]]
function CommonTipBoard:RefreshTipBoardContentTagMatchSingleTeamInfo()
	local boardBg   = self.viewData.boardBg
	local boardSize = boardBg:getContentSize()
	local teamData  = self.viewTypeData.teamData or {}

	local viewTypeData = self.viewTypeData
	local teamMarkPosSign = viewTypeData.teamMarkPosSign

	local teamView = require("Game.views.tagMatch.TagMatchDefensiveTeamView").new({teamId = viewTypeData.teamId or 1, teamDatas = viewTypeData.teamData or {}, teamMarkPosSign = teamMarkPosSign})
	display.commonUIParams(teamView, {po = cc.p(boardSize.width / 2, boardSize.height / 2), ap = display.CENTER})
	boardBg:addChild(teamView)

end

--[[
道具倒计时恢复内容
--]]
function CommonTipBoard:RefreshTipBoardContentGoodRestore()

end

--[[
好友钓场天气
--]]
function CommonTipBoard:RefreshTipBoardContentFriendWeather( ... )
	local buff = self.buff or {}
	local weatherLayout = self.viewData.weatherLayout
	local weatherTitleLabel = weatherLayout.weatherTitleLabel
	local weatherLabel = weatherLayout.weatherLabel
	local weatherDesrLabel = weatherLayout.weatherDesrLabel
	local durationLabel = weatherLayout.durationLabel

    if next(buff) then
		local fishConfigParser = require('Game.Datas.Parser.FishConfigParser')
        local weatherConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PRAY , 'fish')[tostring(buff.buffId)]
        weatherLabel:setString(weatherConfig.name)
		weatherDesrLabel:setString(weatherConfig.descr)
		durationLabel:setString(string.formattedTime(checkint(buff.leftSeconds),'%02i:%02i:%02i'))
    else
		weatherTitleLabel:setString(__('当前没有天气效果'))
		weatherLabel:setString('')
		weatherDesrLabel:setString('')
		durationLabel:setString('00:00:00')
    end
end

--[[
包厢加成buff
--]]
function CommonTipBoard:RefteshTipBoardContentPrivateRoomBuff()
	local layout = CLayout:create(oriSize)
	display.commonUIParams(layout, {po = cc.p(0, 0), ap = cc.p(0, 0)})
	self.viewData.boardBg:addChild(layout, 10)
	local title = display.newLabel(oriSize.width / 2, oriSize.height - 33, fontWithColor(6, {text = __('资源加成')}))
	layout:addChild(title)
	for i = 1, 2 do
		local line = display.newImageView(_res("ui/home/takeaway/takeout_line.png"), oriSize.width / 2, oriSize.height - 60 - (i - 1) * 40, {scale9 = true, size = cc.size(330, 2)})
		layout:addChild(line)
		local icon = display.newImageView(CommonUtils.GetGoodsIconPathById(self.iconId), 315, oriSize.height - 80 - (i - 1) * 40)
		icon:setScale(0.2)
		layout:addChild(icon)
	end
	local souvenirLabel = display.newLabel(176, 70, fontWithColor(16, {text = __('纪念品加成'), ap = cc.p(1, 0.5)}))
	layout:addChild(souvenirLabel)
	local souvenirAddition = self.privateRoomBuff.souvenir.add + self.originNum * self.privateRoomBuff.souvenir.pct
	local souvenirNum = display.newLabel(290, 70, fontWithColor(10, {text = '+' .. tostring(souvenirAddition), ap = cc.p(1, 0.5)}))
	layout:addChild(souvenirNum)
	local themeLabel = display.newLabel(176, 30, fontWithColor(16, {text = __('主题加成'), ap = cc.p(1, 0.5)}))
	layout:addChild(themeLabel)
	local themeAddition = self.privateRoomBuff.theme.add + self.originNum * self.privateRoomBuff.theme.pct
	local themeNum = display.newLabel(290, 30, fontWithColor(10, {text = '+' .. tostring(themeAddition), ap = cc.p(1, 0.5)}))
	layout:addChild(themeNum)
end

--[[
无图标技能说明
--]]
function CommonTipBoard:RefreshTipBoardContentNoIconSkillDescr()
	local viewData = self.viewData
	local boardBg  = viewData.boardBg
	local boardSize = boardBg:getContentSize()

	if nil ~= self.title then
		local titleLabel = viewData.titleLabel
		titleLabel:setVisible(true)
		display.commonLabelParams(titleLabel, {ap = display.LEFT_TOP, text = self.title, fontSize = 24, color = '#5b3c25', w = boardSize.width - 30})
		display.commonUIParams(titleLabel, {po = cc.p(15, boardSize.height - 10)})
	end

	if nil ~= self.sub then
		local subLabel = viewData.subLabel
		subLabel:setVisible(true)
		display.commonLabelParams(subLabel, {text = self.sub, ap = display.LEFT_TOP, fontSize = 20, color = '#b4573B', w = boardSize.width - 30, hAlign = display.TAL})
		display.commonUIParams(subLabel, {po = cc.p(15, boardSize.height - 42)})
	end

	if nil ~= self.descr then
		local descrLabel = viewData.descrLabel
		descrLabel:setVisible(true)
		display.commonLabelParams(descrLabel, {text = self.descr, ap = display.LEFT_TOP, fontSize = 22, color = '#858585', w = boardSize.width - 30, hAlign = display.TAL})
		display.commonUIParams(descrLabel, {po = cc.p(15, boardSize.height - 68)})
	end

	if nil ~= self.viewTypeData then
		local nameLabel = viewData.nameLabel
		display.commonLabelParams(nameLabel, {text = self.viewTypeData, ap = display.LEFT_BOTTOM, fontSize = 20, color = '#b4573B', w = boardSize.width - 30, hAlign = display.TAL})
		display.commonUIParams(nameLabel, {po = cc.p(15, 10)})
	end

end

--[[
仙境梦游Boss升级说明
--]]
function CommonTipBoard:RefreshTipBoardContentAnniversary19BossUpgradeDescr()
	local boardSize = oriSize
	local layout = display.newLayer(0, 0, {size = boardSize})
	self.viewData.boardBg:addChild(layout, 10)

	local curLevelLabel = display.newLabel(11, boardSize.height - 10, 
		{ap = display.LEFT_TOP, text = self.title, fontSize = 22, color = '#723d1d', w = boardSize.width - 22})
	layout:addChild(curLevelLabel)

	local levelDesc = display.newLabel(11, boardSize.height - 38, 
		{text = self.descr, ap = display.LEFT_TOP, fontSize = 22, color = '#9a7965', w = boardSize.width - 22})
	layout:addChild(levelDesc)

	local line = display.newImageView(_res('ui/anniversary19/exploreMain/wonderland_explore_main_bosstip_line.png'), boardSize.width / 2, 80)
	layout:addChild(line)

	local viewTypeData = self.viewTypeData or {}
	local isFullLevel = viewTypeData.isFullLevel
	if isFullLevel then
		local levelDesc = display.newLabel(boardSize.width * 0.5, 40, 
			{text = __('已达到最高等级'), ap = display.CENTER, fontSize = 22, color = '#9a7965', w = boardSize.width - 12, hAlign = display.TAC})
		layout:addChild(levelDesc)
	else
		local upgradeTipLabel = display.newLabel(boardSize.width * 0.5, 60, 
			{text = __('距离下次升级'), ap = display.CENTER, fontSize = 22, color = '#9a7965', w = boardSize.width - 12, hAlign = display.TAC})
		layout:addChild(upgradeTipLabel)

		local maxVal = viewTypeData.maxVal or 100
		local curVal = viewTypeData.curVal or 0
		local progressBar = CProgressBar:create(_res('ui/anniversary19/exploreMain/wonderland_explore_main_bosstip_bar_active.png'))
		progressBar:setBackgroundImage( _res('ui/anniversary19/exploreMain/wonderland_explore_main_bosstip_bar_grey.png'))
		progressBar:setDirection(eProgressBarDirectionLeftToRight)
		progressBar:setMaxValue(maxVal)
		progressBar:setValue(curVal)
		progressBar:setShowValueLabel(true)
		progressBar:setPosition(cc.p(boardSize.width * 0.5, 26))
		progressBar:setAnchorPoint(display.CENTER)
		layout:addChild(progressBar)
		display.commonLabelParams(progressBar:getLabel(),fontWithColor('9', {text = string.format('%s/%s', curVal, maxVal)}))
	end
end

--[[
打牌游戏卡牌阵容
]]
function CommonTipBoard:RefreshTipBoardContentTTgameCardList()
	local viewData   = self.viewData
	local boardBg    = viewData.boardBg
	local cardIdList = checktable(self.battleCardList_)
	local CARD_SIZE  = cc.size(140, 200)
	local BORDER_W   = 40
	local BOARD_SIZE = cc.size(CARD_SIZE.width * #cardIdList + BORDER_W*2, CARD_SIZE.height)
	for index, battleCardId in ipairs(cardIdList) do
		local cardNode = TTGameUtils.GetBattleCardNode({zoomModel = 's', cardId = battleCardId})
		cardNode:setPositionX(BORDER_W + (index-0.5) * CARD_SIZE.width)
		cardNode:setPositionY(BOARD_SIZE.height/2)
		viewData.boardBg:addChild(cardNode)
	end
	viewData.boardBg:setContentSize(BOARD_SIZE)
end

--[[
编队阵容（好友切磋）
--]]
function CommonTipBoard:RefreshTipBoardContentTeamList()
	local viewData   = self.viewData
	local boardBg    = viewData.boardBg
	local cardList = checktable(self.cardList)

	local BOARD_SIZE = cc.size(400, 146)
	local titleLabel = display.newButton(oriSize.width / 2, oriSize.height - 28, {n = _res('ui/home/takeaway/common_title_3.png')})
	titleLabel:setEnabled(false)
	display.commonLabelParams(titleLabel, {fontSize = 22, color = '4c4c4c', text = __('阵容')})
	viewData.boardBg:addChild(titleLabel)
	for i, cardData in ipairs(cardList) do
		if cardData.cardId and checkint(cardData.cardId) > 0 then
			local cardHeadNode = require('common.CardHeadNode').new({
				cardData = {
					cardId = cardData.cardId,
					level = cardData.level,
					breakLevel = cardData.breakLevel,
					skinId = cardData.skinId
				},
				showBaseState = true,
				showActionState = false,
				showVigourState = false
			})
			cardHeadNode:setPosition(cc.p(-28 + 76 * i, oriSize.height / 2 - 15))
			cardHeadNode:setEnabled(false)
			cardHeadNode:setScale(0.38)
			viewData.boardBg:addChild(cardHeadNode)
		end
	end
end
--[[
buff效果（20春活）
--]]
function CommonTipBoard:RefreshTipBoardContentBuffEffect()
	local viewData   = self.viewData
	local boardBg    = viewData.boardBg
	local effect = self.args.params.effect
	local progress = self.args.params.progress

	local effectLabel = display.newLabel(50, oriSize.height - 30, {text = effect, fontSize = 20, color = '#613814', ap = display.CENTER_TOP, w = 340})
	local effectLabelSize =  display.getLabelContentSize(effectLabel)

	local progress = display.newLabel(50, oriSize.height - 90, {text = progress, fontSize = 20, color = '#613814', ap = display.CENTER_TOP, w = 340})
	local progressSize  = display.getLabelContentSize(progress)
	local effectLayoutSize = cc.size(oriSize.width , effectLabelSize.height + progressSize.height + 10)
	local effectLayout = display.newLayer(0,0, {size = cc.size(oriSize.width , effectLabelSize.height + progressSize.height + 10)})
	effectLayout:addChild(progress)
	effectLabel:setPosition(cc.p(effectLayoutSize.width/2 +10, effectLayoutSize.height))
	effectLayout:addChild(effectLabel)
	progress:setPosition(cc.p(effectLabelSize.width/2+10 ,  effectLayoutSize.height - effectLabelSize.height -10))
	local  gainListSize = oriSize
	local gainListView = CListView:create(gainListSize)
	gainListView:setDirection(eScrollViewDirectionVertical)
	gainListView:setBounceable(true)
	gainListView:setPosition(boardBg:getPosition())
	gainListView:setAnchorPoint(boardBg:getAnchorPoint())
	self:addChild(gainListView,20)
	gainListView:insertNodeAtLast(effectLayout)
	gainListView:reloadData()
	viewData.gainListView = gainListView
end
--[[
基因描述 (猫屋)
--]]
function CommonTipBoard:RefreshTipBoardCatGeneDescr()
	local viewData   = self.viewData
	local descrLabel = viewData.descrLabel

	local geneConf = CONF.CAT_HOUSE.CAT_GENE:GetValue(self.iconId)
	descrLabel:setString(tostring(geneConf.descr))
end
--[[
基因描述 (猫屋)
--]]
function CommonTipBoard:RefreshTipBoardCatGeneDescr()
	local viewData   = self.viewData
	local descrLabel = viewData.descrLabel

	local geneConf = CONF.CAT_HOUSE.CAT_GENE:GetValue(self.iconId)
	descrLabel:setString(tostring(geneConf.descr))
end
---------------------------------------------------
-- refreash logic end --
---------------------------------------------------


---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
刷新ui
@params data table 数据
--]]
function CommonTipBoard:RefreshUI(data)
	self.targetNode = data.targetNode
	self.iconId = checkint(data.iconId)
	self.type = data.type or 3
	self.showHoldAmount = data.showHoldAmount
	self.viewTypeData = data.viewTypeData
	self.bgSize = data.bgSize
	self.buff = data.buff
	self:RefreshTipBoardPos()
	self:RefreshTipBoardContent()
end
--[[
刷新提示框大小
--]]
function CommonTipBoard:RefreshTipBoardSize()
	-- if 5 == self.type then return end
	local size = cc.size(oriSize.width, oriSize.height)

	-- 计算描述文字高度
	local descrLabelHeight = display.getLabelContentSize(self.viewData.descrLabel).height

	if 7 == self.type and self.petExclusiveCardExtraHeight and 0 < self.petExclusiveCardExtraHeight then
		size.height = oriSize.height + (descrLabelHeight - oriSize.height * 0.5) + 10 + self.petExclusiveCardExtraHeight

		-- 显示本命 放大背景框
		self.viewData.boardBg:setContentSize(size)

		-- 修正位置
		local deltaY = size.height - oriSize.height

		local fixPositionNodes = {
			self.viewData.titleLabel,
			self.viewData.mainIcon,
			self.viewData.nameLabel,
			self.viewData.amountLabel,
			self.viewData.subLabel,
			self.viewData.descrLabel,
			self.viewData.exclusiveCardLabel
		}

		for i,v in ipairs(fixPositionNodes) do
			if v then
				v:setPositionY(v:getPositionY() + deltaY)
			end
		end

		for i,v in ipairs(self.viewData.exclusiveCardHeadNode) do
			v:setPositionY(v:getPositionY() + deltaY)
		end


	elseif 5 == self.type and not self.isRich then

		-- 纯文本类型
		if size.height - 55 < descrLabelHeight then
			size.height = descrLabelHeight + 55
			self.viewData.boardBg:setContentSize(size)

			-- 修正位置
			local deltaY = size.height - oriSize.height

			local fixPositionNodes = {
				self.viewData.titleLabel,
				self.viewData.descrLabel
			}

			for i,v in ipairs(fixPositionNodes) do
				if v then
					v:setPositionY(v:getPositionY() + deltaY)
				end
			end
		end

	elseif 4 == self.type and nil ~= self.type4Icons and 0 < #self.type4Icons then

		-- 为描述做一次底板大小自适应
		if nil ~= self.descr and not self.isRich and 0 < string.len(string.gsub(self.descr, ' ', '')) then
			local descrLabelContentSize = display.getLabelContentSize(self.viewData.descrLabel)

			local type4Icon = self.type4Icons[1]
			local descrH = self.viewData.boardBg:getContentSize().height - 40
			local type4IconH = type4Icon:getPositionY() + type4Icon:getContentSize().height * 0.5 * type4Icon:getScaleY()
			local height = descrH - type4IconH
			if descrLabelContentSize.height > height then
				local fixedHeight = type4IconH + descrLabelContentSize.height + 40 + 20
				size.height = fixedHeight
				self.viewData.boardBg:setContentSize(size)

				-- 修正位置
				local deltaY = size.height - oriSize.height

				local fixPositionNodes = {
					self.viewData.titleLabel,
					self.viewData.descrLabel
				}

				for i,v in ipairs(fixPositionNodes) do
					if v then
						v:setPositionY(v:getPositionY() + deltaY)
					end
				end

				for i,v in ipairs(self.type4Icons) do
					if v then
						v:setPositionY(
							self.viewData.descrLabel:getPositionY() - descrLabelContentSize.height - 10 - v:getContentSize().height * 0.5 * v:getScaleY()
						)
					end
				end
			end
		end

	elseif self.type == 16 and descrLabelHeight > oriSize.height * 0.3 then
		local fixPositionNodes = {
			self.viewData.titleLabel,
			self.viewData.subLabel,
			self.viewData.descrLabel,
			self.viewData.nameLabel,
		}
		local h = 0
		for i, label in ipairs(fixPositionNodes) do
			if label then
				local nodeSize = display.getLabelContentSize(label)
				h = nodeSize.height + h
			end
		end
		size.height = h + 50
		self.viewData.boardBg:setContentSize(size)
		local addH= 0
		if display.getLabelContentSize(self.viewData.titleLabel).height > 40   then
			addH = 25
		end
		local fixPosition = {
			size.height - 10 ,
			size.height - 42-addH,
			size.height - 68 - addH,
		}
		for i, v in ipairs(fixPosition) do
			local node = fixPositionNodes[i]
			if node then
				node:setPositionY(v)
			end
		end

	elseif self.type == 21 then
		-- 纯文本类型
		local size = cc.resize(display.getLabelContentSize(self.viewData.descrLabel), 20, 20)
		self.viewData.boardBg:setContentSize(size)

		self.viewData.descrLabel:alignTo(nil, ui.cc)

	elseif descrLabelHeight > oriSize.height * 0.5 then
		local py = self.viewData.boardArrow:getPositionY()
		size.height = oriSize.height + (descrLabelHeight - oriSize.height * 0.5)+20
		local deltaY = size.height - oriSize.height
        if py > oriSize.height then deltaY = deltaY - 22 end
		-- 超出范围 将背景框放大
		self.viewData.boardBg:setContentSize(size)

		local fixPositionNodes = {
			self.viewData.titleLabel,
			self.viewData.mainIcon,
			self.viewData.nameLabel,
			self.viewData.amountLabel,
			self.viewData.subLabel,
			self.viewData.descrLabel
		}

		for i,v in ipairs(fixPositionNodes) do
			if v then
				v:setPositionY(v:getPositionY() + deltaY)
			end
		end

		-- -- 修正内容位置
		-- local deltaY = size.height - oriSize.height
		-- self.viewData.titleLabel:setPositionY(self.viewData.titleLabel:getPositionY() + deltaY)
		-- if self.viewData.mainIcon then
		-- 	self.viewData.mainIcon:setPositionY(self.viewData.mainIcon:getPositionY() + deltaY)
		-- end
		-- self.viewData.nameLabel:setPositionY(self.viewData.nameLabel:getPositionY() + deltaY)
		-- self.viewData.amountLabel:setPositionY(self.viewData.amountLabel:getPositionY() + deltaY)
		-- self.viewData.subLabel:setPositionY(self.viewData.subLabel:getPositionY() + deltaY)
		-- self.viewData.descrLabel:setPositionY(self.viewData.descrLabel:getPositionY() + deltaY)

	end
end
--[[
刷新位置
--]]
function CommonTipBoard:RefreshTipBoardPos()
	local targetBoundingBox = self.targetNode and self.targetNode:getBoundingBox() or cc.rect(0, 0, display.width, display.height)
	local worldPos = self.targetNode and self.targetNode:getParent():convertToWorldSpace(cc.p(targetBoundingBox.x, targetBoundingBox.y)) or cc.p(0,display.cy)
	local nodePos = self:convertToNodeSpace(worldPos)

	local boardBgSize = self.viewData.boardBg:getContentSize()
	-- 计算x坐标 不超屏
	local x = math.min(display.SAFE_R - boardBgSize.width, math.max(display.SAFE_L, nodePos.x + targetBoundingBox.width * 0.5 - boardBgSize.width * 0.5))

	-- 底边超过下边界 提示板按上显示
	local onTargetTopFunc = function()
		display.commonUIParams(self.viewData.boardBg, {po = cc.p(x, nodePos.y + targetBoundingBox.height)})
		self.viewData.boardArrow:setFlippedY(true)

		local arrowX = self.viewData.boardBg:convertToNodeSpace(worldPos).x + targetBoundingBox.width * 0.5
		arrowX = math.min(arrowX, self.viewData.boardBg:getContentSize().width - self.viewData.boardArrow:getContentSize().width / 2 - 10)
		display.commonUIParams(self.viewData.boardArrow, {po = cc.p(arrowX, self.isDardMode_ and -1 or 2)})
	end

	-- 定边超过上边界 提示板下显示
	local onTargetBottomFunc = function()
		display.commonUIParams(self.viewData.boardBg, {po = cc.p(x, nodePos.y - boardBgSize.height)})
		self.viewData.boardArrow:setFlippedY(false)

		local arrowX = self.viewData.boardBg:convertToNodeSpace(worldPos).x + targetBoundingBox.width * 0.5
		arrowX = math.min(arrowX, self.viewData.boardBg:getContentSize().width - self.viewData.boardArrow:getContentSize().width / 2 - 10)
		display.commonUIParams(self.viewData.boardArrow, {po = cc.p(arrowX , boardBgSize.height - (self.isDardMode_ and -2 or 2))})
	end
	
	if nodePos.y - boardBgSize.height < 0 then
		onTargetTopFunc()
	elseif nodePos.y + targetBoundingBox.height + boardBgSize.height > display.height then
		onTargetBottomFunc()
	else
		if self.type == 18 then
			onTargetBottomFunc()
		else
			onTargetTopFunc()
		end
	end
	if self.viewData.gainListView then
		self.viewData.gainListView:setPosition(self.viewData.boardBg:getPositionX() ,  self.viewData.boardBg:getPositionY() -5)
		self.viewData.gainListView:setAnchorPoint(self.viewData.boardBg:getAnchorPoint())
	end

	if self.type == 6 then
		self.viewData.scrollView:setPosition(cc.p(self.viewData.boardBg:getPositionX() + 6,self.viewData.boardBg:getPositionY()+10))
	elseif self.type == 10 then
		local targetNodeWorldPos = self.targetNode:convertToWorldSpaceAR(cc.p(0, 0))
		local targetNodeSize = self.targetNode:getContentSize()
		local yy = (targetNodeWorldPos.y - boardBgSize.height + targetNodeSize.height)
		local dyy = 0

		if (targetNodeWorldPos.y + boardBgSize.height) > display.height then
			dyy = ((targetNodeWorldPos.y + boardBgSize.height) - display.height) * -1
		end

		local realY = targetNodeWorldPos.y + dyy - targetNodeSize.height
		local arrowDY = 0
		if targetNodeWorldPos.y + dyy - targetNodeSize.height < 0 then
			realY = 10
			arrowDY = 35
		end

		display.commonUIParams(self.viewData.boardBg, {po = cc.p(nodePos.x + targetNodeSize.width - 15, realY)})
		display.commonUIParams(self.viewData.boardArrow, {po = cc.p(self.viewData.boardBg:convertToNodeSpace(worldPos).x + targetNodeSize.width - 10, self.viewData.boardBg:convertToNodeSpace(worldPos).y + targetNodeSize.height / 2 + arrowDY)})
		self.viewData.boardArrow:setFlippedY(false)
		self.viewData.boardArrow:setRotation(-90)

	elseif self.type == 11 then
		if self.rewardGoods and next(self.rewardGoods) then
			local rewardsNum = table.nums(self.rewardGoods)
			local boardSize = self.viewData.boardBg:getContentSize()
			local offsetX = (boardSize.width - 10) / (2 * rewardsNum)
			for i = 1, rewardsNum do
				display.commonUIParams(self.rewardGoods[i], {po = cc.p(offsetX * (2 * i - 1) + self.viewData.boardBg:getPositionX() + 5,
					20 + self.viewData.boardBg:getPositionY() + 50), ap = cc.p(0.5, 0.5)})
				self.rewardGoods[i]:setTouchEnabled(true)
				self.rewardGoods[i]:setOnClickScriptHandler(function (sender)
					if uiMgr:IsCommonInformationTipsExist() then
						uiMgr:RemoveInformationTips()
					else
						uiMgr:ShowInformationTipsBoard({targetNode = self.rewardGoods[i], iconId = self.rewardGoods[i]:getTag(), type = 1})
					end
				end)
				if offsetX < 97.5 then
					self.rewardGoods[i]:setScale(offsetX / 62)
				end
			end
		end
	end
end
--[[
移除自己
--]]
function CommonTipBoard:RemoveSelf_()
	self:setVisible(false)
	if self.touchListener_ then
		self:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end

	local countdownKey = CommonUtils.getCurrencyRestoreKeyByGoodsId(self.iconId)
	if countdownKey and gameMgr:downCountUi(countdownKey) then gameMgr:removeDownCountUi(countdownKey) end
	self:runAction(cc.RemoveSelf:create())

	if self.closeCB then
		self.closeCB()
	end
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------


---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function CommonTipBoard:onTouchBegan_(touch, event)
	if self:TouchedSelf(touch:getLocation()) then
		return true
	else
		-- 存在奖励要求提示框时 点击非奖励要求提示框外部时不移除自身
		if uiMgr:IsRewardInformationTipsExist() and self.type ~= 11 then
			return true
		else
			-- 如果点击了奖励要求提示框外部 其他的提示框页关闭
			if 11 == self.type then
				uiMgr:RemoveInformationTips()
			end
			self:RemoveSelf_()
			return false
		end
	end
end
function CommonTipBoard:onTouchMoved_(touch, event)

end
function CommonTipBoard:onTouchEnded_(touch, event)
	--点击了奖励要求提示框内部 松开时其他的提示框页关闭 奖励要求提示框不关闭
	if self.type ~= 6 and self.type ~= 11 then
		self:RemoveSelf_()
	end
end
function CommonTipBoard:onTouchCanceled_( touch, event )
	print('here touch canceled by some unknown reason')
end
--[[
是否触摸到了提示板
@params touchPos cc.p 触摸位置
@return _ bool
--]]
function CommonTipBoard:TouchedSelf(touchPos)
	local boundingBox = self.viewData.boardBg:getBoundingBox()
	local fixedP = cc.CSceneManager:getInstance():getRunningScene():convertToNodeSpace(
		self.viewData.boardBg:getParent():convertToWorldSpace(cc.p(boundingBox.x, boundingBox.y)))
	if cc.rectContainsPoint(cc.rect(fixedP.x, fixedP.y, boundingBox.width, boundingBox.height), touchPos) then
		return true
	end
	return false
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------


return CommonTipBoard


