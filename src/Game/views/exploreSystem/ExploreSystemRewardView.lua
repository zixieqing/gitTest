--[[
* descpt : 探索奖励 界面
    teamData   table 阵容信息
    trophyData table 战斗奖励信息
]]

local ExploreSystemRewardView = class('ExploreSystemRewardView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.exploreSystem.ExploreSystemRewardView'
	node:enableNodeEvents()
	return node
end)


------------ import ------------
local appFacadeIns = AppFacade.GetInstance()
local gameMgr      = appFacadeIns:GetManager("GameManager")
local cardMgr      = appFacadeIns:GetManager("CardManager")
------------ import ------------

local RES_DIR = {
    
    
}

function ExploreSystemRewardView:ctor( ... )
    self.args = unpack({...}) or {}
    self:initData()
	self:initialUI()
	self:UpdateLocalData()
end

function ExploreSystemRewardView:initData()
	self.fps = 30

	self.teamData = self.args.teamData or {}
	self.trophyData = self.args.trophyData or {}
	self.baseRewards = self.args.baseRewards or {}

	-- 转换数据结构
	if not self.trophyData.cardExp then 
		self.trophyData.cardExp = {}
		for i,v in ipairs(self.teamData) do
			self.trophyData.cardExp[tostring(v.id)] = {
				exp = v.exp,
				level = v.level
			}
		end
	end

	-- 向外传参 延迟的升级奖励信息
	self.delayUpgradeLevelData = {}

	self.isControllable_ = true
end


function ExploreSystemRewardView:initialUI()
    xTry(function ( )
        
        local CreateView = function ()
            local view = display.newLayer()
            local size = view:getContentSize()
			local layerSize = cc.size(display.SAFE_RECT.width, display.SAFE_RECT.height)
			
			view:addChild(display.newLayer(0,0,{size = size,enable = true, color = cc.c4b(0, 0, 0, 0)}))

            -- -- 遮罩
            local bgMask = display.newImageView(_res('ui/common/common_bg_mask_2.png'), size.width / 2, size.height / 2,
                {animate = false, scale9 = true, size = display.size})
            view:addChild(bgMask)
        
            -- 通用层节点
            local commonLayer = display.newLayer(display.SAFE_L + layerSize.width * 0.5, layerSize.height * 0.5,
                {size = layerSize, ap = cc.p(0.5, 0.5)})
            view:addChild(commonLayer, 1)
        
            local commonCenterTopLayer = display.newLayer(display.SAFE_L + layerSize.width * 0.5, layerSize.height * 0.5,
                {size = layerSize, ap = cc.p(0.5, 0.5)})
            view:addChild(commonCenterTopLayer, 3)
        
            
			local leaderData = self.teamData[1] or {}
            local skinId = checkint(gameMgr:GetCardDataByCardId(checkint(leaderData.cardId)).defaultSkinId)
            if skinId > 0 then
                -- 立绘
                local drawNode = require('common.CardSkinDrawNode').new({
                    skinId = skinId,
                    coordinateType = COORDINATE_TYPE_CAPSULE
                })
                view:addChild(drawNode, 2)
        
                if cardMgr.GetFavorabilityMax(leaderData.favorLevel) then
                    local designSize = cc.size(1334, 750)
                    local winSize = display.size
                    local deltaHeight = (winSize.height - designSize.height) * 0.5
                    local particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly')
                    particleSpine:setPosition(cc.p(display.SAFE_L + 300,deltaHeight))
                    view:addChild(particleSpine, 2)
                    particleSpine:setAnimation(0, 'idle2', true)
                    particleSpine:update(0)
                    particleSpine:setToSetupPose()
                end
            end
            
        
            local rewardLayer = self:CreateRewardLayer()
            view:addChild(rewardLayer, 10)
            
        
            return {
                view                     = view,
                backBtn                  = rewardLayer.viewData.backBtn
            }
        end
        
        self.viewData_ = CreateView()
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function ExploreSystemRewardView:initView()
    local viewData = self:getViewData()
    
    if viewData.backBtn then
        display.commonUIParams(viewData.backBtn, {cb = handler(self, self.BackClickCallback)})
    end
    

    self:refreshUI(self.args)
end

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
  gridview data adapter
]]


function ExploreSystemRewardView:refreshUI(data)
end

---------------------------------------------------
-- view control end --
---------------------------------------------------

--[[
更新本地数据
--]]
function ExploreSystemRewardView:UpdateLocalData()
	------------ 刷新本地数据 ------------
	if self.trophyData then

		local newestUserData = {}

		-- 玩家体力
		if self.trophyData.hp then
			newestUserData.hp = self.trophyData.hp
		end

		-- 玩家经验
		if self.trophyData.mainExp then
			local newestExpData = {}
			newestExpData.mainExp = checkint(self.trophyData.mainExp)

			local level = gameMgr:GetUserInfo().level
			local expData = CommonUtils.GetConfig('player', 'level', level + 1)
			newestExpData.level = level

			while (nil ~= newestExpData and nil ~= expData) and (newestExpData.mainExp >= checkint(expData.totalExp)) do
				print('here log while when calc main exp')
				newestExpData.level = checkint(expData.level)
				expData = CommonUtils.GetConfig('player', 'level', newestExpData.level + 1)

				if nil == expData then
					break
				end
			end

			gameMgr:UpdatePlayer(newestExpData)

			self.delayUpgradeLevelData  =  {
				isLevel = gameMgr:GetUserInfo().level > level,
				newLevel = gameMgr:GetUserInfo().level,
				oldLevel = level,
				canJump = false,
				canJumpHint = __('战斗中无法跳转哦')
			}
		end

		-- 关卡数
		if self.trophyData.newestQuestId then
			-- 插入一个调出剧情的标识
			if checkint(self.trophyData.newestQuestId) == 2 and gameMgr:GetUserInfo().newestQuestId == 1 then
				gameMgr:GetUserInfo().isFirstGuide = true
			end

			newestUserData.newestQuestId = checkint(self.trophyData.newestQuestId)
		end
		if self.trophyData.newestHardQuestId then
			newestUserData.newestHardQuestId = checkint(self.trophyData.newestHardQuestId)
		end
		if self.trophyData.newestInsaneQuestId then
			newestUserData.newestInsaneQuestId = checkint(self.trophyData.newestInsaneQuestId)
		end

		-- 金币
		if self.trophyData.gold then
			newestUserData.gold = checkint(self.trophyData.gold)
		end

		-- 竞技场勋章
		if self.trophyData.medal then
			newestUserData.medal = checkint(self.trophyData.medal)
		end

		-- 刷新玩家信息
		gameMgr:UpdatePlayer(newestUserData)
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)

		-- 卡牌信息 等级 经验
		if self.trophyData.cardExp then
			for k,v in pairs(self.trophyData.cardExp) do
				if checkint(k) > 0 then
					gameMgr:UpdateCardDataById(k, v)
				end
			end
		end

		-- 卡牌信息 活力
		if self.trophyData.cardsVigour then
			for k,v in pairs(self.trophyData.cardsVigour) do
				if checkint(k) > 0 then
					local data = {vigour = checknumber(v)}
					gameMgr:UpdateCardDataById(k, data)
				end
			end
		end

		-- 卡牌信息 好感度等级
		if self.trophyData.favorabilityCards then
			for k,v in pairs(self.trophyData.favorabilityCards) do
				if checkint(k) > 0 then
					local data = {
						favorability = checkint(v.favorability),
						favorabilityLevel = checkint(v.favorabilityLevel)
					}
					gameMgr:UpdateCardDataById(k, data)
				end
			end
		end

		-- 剩余挑战次数
		if self.trophyData.challengeTime then

			-- 刷新重复挑战次数
			local stageId = self.trophyData.requestData.questId
			if nil ~= stageId then
				local stageConf = CommonUtils.GetQuestConf(stageId)

				if nil ~= stageConf and
					ValueConstants.V_NORMAL == checkint(stageConf.repeatChallenge) and
					ValueConstants.V_NONE < checkint(stageConf.challengeTime) then

					-- 满足 可以重复挑战 并且挑战次数大于0 刷新剩余挑战次数
					gameMgr:UpdateChallengeTimeByStageId(stageId, checkint(self.trophyData.challengeTime))

				end
			end

		end

		-- 道具信息
		if self.trophyData.rewards then
			CommonUtils.DrawRewards(checktable(self.trophyData.rewards))
		end

	end
	------------ 刷新本地数据 ------------
end

----------------------------------------
-- click handler begin --
----------------------------------------

----------------------------------------
-- click handler end --
----------------------------------------

function ExploreSystemRewardView:CreateRewardLayer()
    local layerSize = cc.size(display.SAFE_RECT.width, display.SAFE_RECT.height)
    
    local rewardLayer = display.newLayer(display.SAFE_L + layerSize.width * 0.5, layerSize.height * 0.5, {size = layerSize, ap = cc.p(0.5, 0.5)})

    local contentBgLayer = display.newLayer(0, 0, {bg = _res('ui/battle/battleresult/settlement_bg_reward.png'), ap = cc.p(0.5, 0.5)})
    local contentBgSize = contentBgLayer:getContentSize()
    display.commonUIParams(contentBgLayer, {po = cc.p(
		layerSize.width - contentBgSize.width * 0.5,
		layerSize.height * 0.5
    )})
	rewardLayer:addChild(contentBgLayer)
	
	-- contentBgLayer:addChild(display.newLayer(0,0,{size = contentBgSize, color = cc.c4b(0), enable = true, cb = function ()
	-- 	logInfo.add(5, 'rewardLayer22')
	-- end}))

    -- 标题
	local titleLabel = display.newImageView(_res('ui/battle/battleresult/settlement_ico_pass_reward.png'), 0, 0)
	display.commonUIParams(titleLabel, {po = cc.p(
		contentBgLayer:getPositionX() + 10,
		contentBgLayer:getPositionY() + contentBgLayer:getContentSize().height * 0.5 + titleLabel:getContentSize().height * 0.5 + 10
	)})
	rewardLayer:addChild(titleLabel)
    
    -- 第一级奖励
    local satairCurrencyLayer = self:CreateStairCurrencyLayer(cc.size(contentBgSize.width, 50))
    display.commonUIParams(satairCurrencyLayer, {po = cc.p(contentBgSize.width / 2, contentBgSize.height - 50), ap = display.CENTER})
    contentBgLayer:addChild(satairCurrencyLayer)

    ---------------- 卡牌模块  -----------------
    -- 
    
    local cardUpLayer = self:CreateCardUpLayer(contentBgLayer, contentBgSize)
    

    -- 文字
	local expLabel = display.newLabel(0, 0, fontWithColor('6', {text = __('卡牌提升'), color = '#c5c5c5'}))
	display.commonUIParams(expLabel, {ap = cc.p(0, 0), po = cc.p(
		cardUpLayer:getPositionX() - cardUpLayer:getContentSize().width * 0.5,
		cardUpLayer:getPositionY() + cardUpLayer:getContentSize().height * 0.5 + 5
	)})
    contentBgLayer:addChild(expLabel)
    
    -- 
    ---------------- 卡牌模块  -----------------

    -- 返回按钮
	local backBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
	display.commonUIParams(backBtn, {po = cc.p(
		contentBgLayer:getPositionX() + contentBgSize.width * 0.5 - backBtn:getContentSize().width * 0.5 - 35,
		contentBgLayer:getPositionY() - contentBgSize.height * 0.5 + 30
	)})
	display.commonLabelParams(backBtn, fontWithColor('14', {text = __('返回')}))
	rewardLayer:addChild(backBtn)

    rewardLayer.viewData = {
        backBtn = backBtn
    }

    return rewardLayer
end

function ExploreSystemRewardView:CreateStairCurrencyLayer(size)
    local stairCurrencyInfo = {
		{goodsId = EXP_ID, fieldName = 'mainExp', isFinalAmount = false},
		{goodsId = GOLD_ID, fieldName = 'gold', isFinalAmount = false},
    }
    
    local stairCurrencyLayer = display.newLayer(0, 0, {size = size})

    local goodsIconScale = 0.25
    local stairCurrencyInfoCount = #stairCurrencyInfo
    local goodParams = {goodNodeSize = cc.size(170, size.height), midPointX = size.width / 2, midPointY = size.height / 2, col = stairCurrencyInfoCount, maxCol = stairCurrencyInfoCount, scale = 1, goodGap = 0}
    for i, v in ipairs(stairCurrencyInfo) do
        goodParams.index = i

        local pos = CommonUtils.getGoodPos(goodParams)

        local goodsIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(v.goodsId)), pos.x, pos.y, {ap = display.RIGHT_CENTER})
        goodsIcon:setScale(goodsIconScale)
        stairCurrencyLayer:addChild(goodsIcon)
		
		local fieldName = v.fieldName
		local amount = self.baseRewards[fieldName] or (checkint(self.trophyData[fieldName]) - CommonUtils.GetCacheProductNum(v.goodsId))
        local goodsAmountLabel = display.newLabel(pos.x, pos.y, {text = amount, fontSize = 26, color = '#ffd146', ap = display.LEFT_CENTER})
        stairCurrencyLayer:addChild(goodsAmountLabel)
    end

    return stairCurrencyLayer
end

function ExploreSystemRewardView:CreateCardUpLayer(contentBgLayer, contentBgSize)
    local headIconBg = display.newImageView(_res('ui/battle/battleresult/settlement_bg_reward_white.png'), 0, 0)
	display.commonUIParams(headIconBg, {po = cc.p(
		contentBgSize.width * 0.5 + 20,
		contentBgSize.height * 0.675
    )})
    contentBgLayer:addChild(headIconBg)
    
    local maxCardAmount = 5
	local paddingX = 10
	local cellWidth = (headIconBg:getContentSize().width - paddingX * 2) / maxCardAmount
	local nextExpData, curExpData = nil, nil
    local addFavorNodes = {}
    local expBars = {}
    local levelLabels = {}
    local expLeft = {}
    for i,v in ipairs(self.teamData) do
        -- 头像
		local cardHeadNode = require('common.CardHeadNode').new({
			id = checkint(v.id),
			showBaseState = false,
			showActionState = false,
			showVigourState = false
        })
        cardHeadNode:setPosition(cc.p(
			paddingX + (i - 0.5) * cellWidth,
			headIconBg:getContentSize().height * 0.5
		))
        local cardHeadNodeScale = (cellWidth - 10) / cardHeadNode:getContentSize().width
		cardHeadNode:setScale(cardHeadNodeScale)
        headIconBg:addChild(cardHeadNode)
        
        -- 经验条
		nextExpData = CommonUtils.GetConfig('cards', 'level', checkint(v.level) + 1) or {}
		curExpData = CommonUtils.GetConfig('cards', 'level', checkint(v.level)) or {}

		local expBarBg = display.newNSprite(_res('ui/battle/battleresult/result_bar_bg.png'), 0, 0)
		display.commonUIParams(expBarBg, {po = cc.p(
			cardHeadNode:getPositionX(),
			cardHeadNode:getPositionY() - cardHeadNode:getContentSize().height * 0.5 * cardHeadNodeScale - expBarBg:getContentSize().height * 0.5
		)})
		headIconBg:addChild(expBarBg)

		local expBar = cc.ProgressTimer:create(cc.Sprite:create(_res('ui/battle/battleresult/result_bar_1.png')))
		expBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
		expBar:setMidpoint(cc.p(0, 0))
		expBar:setBarChangeRate(cc.p(1, 0))
		expBar:setPercentage((checkint(v.exp) - checkint(curExpData.totalExp)) / checkint(nextExpData.exp) * 100)
		expBar:setPosition(utils.getLocalCenter(expBarBg))
		expBarBg:addChild(expBar)

		-- 等级
		local levelLabel = display.newLabel(0, 0, fontWithColor('3', {text = string.format(__('%d级'), checkint(v.level))}))
		display.commonUIParams(levelLabel, {ap = cc.p(0.5, 1), po = cc.p(
			expBarBg:getPositionX(),
			expBarBg:getPositionY() - expBarBg:getContentSize().height * 0.5 - 2
		)})
        headIconBg:addChild(levelLabel)
        
        
		------------ 计算经验差值 ------------
		local deltaExp = 0
		if nil ~= self.trophyData.cardExp and nil ~= self.trophyData.cardExp[tostring(v.id)] then
			deltaExp = checkint(self.trophyData.cardExp[tostring(v.id)].exp) - gameMgr:GetCardDataById(v.id).exp
		end

		local addExpLabel = display.newLabel(0, 0, fontWithColor('3', {text = string.format(__('+%d经验'), deltaExp)}))
		display.commonUIParams(addExpLabel, {ap = cc.p(0.5, 0), po = cc.p(
			cardHeadNode:getPositionX(),
			cardHeadNode:getPositionY() + cardHeadNode:getContentSize().height * 0.5 * cardHeadNodeScale
		)})
		headIconBg:addChild(addExpLabel)
		------------ 计算经验差值 ------------

		expBars[tostring(v.id)] = expBar
		levelLabels[tostring(v.id)] = levelLabel
		expLeft[tostring(v.id)] = deltaExp

    end

    ---------------- 奖励模块  -----------------
    -- 

    -- 背景
	local rewardBg = display.newLayer(0, 0, {bg = _res('ui/battle/battleresult/settlement_bg_reward_white.png')})
	display.commonUIParams(rewardBg, {po = cc.p(
		headIconBg:getPositionX(),
		headIconBg:getPositionY() - rewardBg:getContentSize().height - 60
	), ap = display.CENTER})
	contentBgLayer:addChild(rewardBg)



    -- 未掉落奖励提示
    local norewardsLabel = display.newLabel(0, 0, fontWithColor('3', {text = __('未掉落道具')}))
    display.commonUIParams(norewardsLabel, {po = utils.getLocalCenter(rewardBg)})
    rewardBg:addChild(norewardsLabel)

    -- 文字
    local rewardLabel = display.newLabel(0, 0, fontWithColor('6', {text = __('获得奖励'), color = '#c5c5c5'}))
    display.commonUIParams(rewardLabel, {ap = cc.p(0, 0), po = cc.p(
        rewardBg:getPositionX() - rewardBg:getContentSize().width * 0.5,
        rewardBg:getPositionY() + rewardBg:getContentSize().height * 0.5 + 5
    )})
	contentBgLayer:addChild(rewardLabel)
	
	-- rewardBg:addChild(display.newLayer(0,0,{size = rewardBg:getContentSize(), color = cc.c4b(0), enable = true, cb = function ()
	-- 	logInfo.add(5, "rewardBgrewardBg222")
	-- end}))
	-- 添加奖励
	if self.trophyData and self.trophyData.rewards then
		norewardsLabel:setVisible(0 >= #self.trophyData.rewards)
		self:AddRewards(rewardBg, self.trophyData.rewards)
	end
    
    -- 
	---------------- 奖励模块  -----------------

    ------------ 初始化动画状态 ------------
	
    local animationConf = {
		titleMoveY = 65,
		titleMoveTime = 10,
		contentBgDelayTime = 2,
		contentBgMoveY = 75,
		contentBgMoveTime = 10 
	}
	-- titleLabel:setVisible(false)
	-- titleLabel:setOpacity(0)
	-- titleLabel:setPositionY(titleLabel:getPositionY() - animationConf.titleMoveY)

	contentBgLayer:setVisible(false)
	contentBgLayer:setOpacity(0)
	contentBgLayer:setPositionY(contentBgLayer:getPositionY() - animationConf.contentBgMoveY)
	------------ 初始化动画状态 ------------

	local ShowSelf = function ()
        
		local delayTime = 10 / self.fps
		local costFrame = 17

		------------ 标题动画 ------------
		-- local titleLabelActionSeq = cc.Sequence:create(
		-- 	cc.DelayTime:create(delayTime),
		-- 	cc.Show:create(),
		-- 	cc.Spawn:create(
		-- 		cc.MoveBy:create(animationConf.titleMoveTime / fps, cc.p(0, animationConf.titleMoveY)),
		-- 		cc.FadeTo:create(animationConf.titleMoveTime / fps, 255)))
		-- titleLabel:runAction(titleLabelActionSeq)
		------------ 标题动画 ------------
		self.isControllable_ = false
		------------ 主要层动画 ------------
		local contentBgActionSeq = cc.Sequence:create(
			cc.DelayTime:create(delayTime + animationConf.contentBgDelayTime / self.fps),
			cc.Show:create(),
			cc.Spawn:create(
				cc.MoveBy:create(animationConf.contentBgMoveTime / self.fps, cc.p(0, animationConf.contentBgMoveY)),
				cc.FadeTo:create(animationConf.contentBgMoveTime / self.fps, 255)
			),
			cc.CallFunc:create(function ()
				local addFavorNode = nil
				local favorData = nil
				for i,v in ipairs(self.teamData) do

					------------ 好感度动画 ------------
					addFavorNode = addFavorNodes[tostring(v.id)]
					if self.trophyData.favorabilityCards and addFavorNode then
						favorData = self.trophyData.favorabilityCards[tostring(v.id)]
						if nil ~= favorData then
							if checkint(favorData.favorabilityLevel) > checkint(v.favorLevel) then
								addFavorNode:setVisible(true)
								addFavorNode:setAnimation(0, 'play2', false)
							elseif checkint(favorData.favorability) > checkint(v.favorExp) then
								addFavorNode:setVisible(true)
								addFavorNode:setAnimation(0, 'play1', false)
							end

							-- 好感度音效
							PlayAudioClip(AUDIOS.UI.ui_levelup.id)
						end
					end
					------------ 好感度动画 ------------

					------------ 刷新经验条 ------------
					-- 经验提升时播放音效
					if 0 < checkint(expLeft[tostring(v.id)]) then
						PlayAudioClip(AUDIOS.UI.ui_levelup.id)
					end
					self:RefreshExp(checkint(v.id))
					------------ 刷新经验条 ------------
				end
				self.isControllable_ = true
			end))
		contentBgLayer:runAction(contentBgActionSeq)
		------------ 主要层动画 ------------

	end

    self.addFavorNodes = addFavorNodes
    self.expBars       = expBars
    self.levelLabels   = levelLabels
    self.expLeft       = expLeft

    ShowSelf()

    return headIconBg
end

function ExploreSystemRewardView:RefreshExp(id)
    if nil == self.expLeft[tostring(id)] or 0 >= self.expLeft[tostring(id)] then return end

	local cardInfo = nil
	local idx = 0
	for i,v in ipairs(self.teamData) do
		if checkint(v.id) == id then
			cardInfo = v
			idx = i
			break
		end
	end

	local expData = CommonUtils.GetConfig('cards', 'level', checkint(cardInfo.level) + 1)
	local expLeft = self.expLeft[tostring(id)]
	local cardData = gameMgr:GetCardDataById(id)

	------------ !!! 判断是否升级 !!! ------------
	-- 需要满足 当前经验加上获得经验满足升级条件
	-- 并且卡牌可以升到下一级 卡牌等级有锁级限制
	-- 此时获取的玩家等级是已经刷新过的玩家等级
	------------ !!! 判断是否升级 !!! ------------

	if (checkint(cardInfo.level) + 1) <= cardMgr.GetCardMaxLevelByCardId(checkint(cardInfo.cardId), gameMgr:GetUserInfo().level, cardData.breakLevel) and
		(cardInfo.exp + expLeft >= expData.totalExp) then

		-- 能升级
		local progressAction = cc.Sequence:create(
			cc.ProgressTo:create(0.75, 100),
			cc.CallFunc:create(function ()
				local expBar = self.expBars[tostring(id)]

				-- 出现升级了文字
				local p = cc.p(
					expBar:getParent():getPositionX(),
					expBar:getParent():getPositionY()
				)
				local levelUpLabel = display.newNSprite(_res('ui/battle/result_levelup.png'), p.x, p.y + 25)
				expBar:getParent():getParent():addChild(levelUpLabel, 99)

				levelUpLabel:setOpacity(0)
				local levelUpActionSeq = cc.Sequence:create(
					cc.Spawn:create(
						cc.MoveBy:create(20 / self.fps, cc.p(0, 50)),
						cc.Sequence:create(
							cc.FadeTo:create(5 / self.fps, 255),
							cc.DelayTime:create(10 / self.fps),
							cc.FadeTo:create(5 / self.fps, 0)
						)
					),
					cc.RemoveSelf:create()
				)
				levelUpLabel:runAction(levelUpActionSeq)

				self.expBars[tostring(id)]:setPercentage(0)
				self.levelLabels[tostring(id)]:setString(string.format(__('%d级'), self.teamData[idx].level))

				-- 递归刷新
				self:RefreshExp(id)
			end)
		)
		self.expBars[tostring(id)]:runAction(progressAction)
		self.expLeft[tostring(id)] = self.expLeft[tostring(id)] - (checkint(expData.totalExp) - checkint(cardInfo.exp))
		self.teamData[idx].exp = expData.totalExp
		self.teamData[idx].level = checkint(cardInfo.level) + 1

	else

		-- 升不了级
		local percent = (cardInfo.exp + expLeft - (expData.totalExp - expData.exp)) / expData.exp * 100
		local progressAction = cc.Sequence:create(
			cc.ProgressTo:create(0.75 * percent * 0.01, percent))
		self.expBars[tostring(id)]:runAction(progressAction)
		self.expLeft[tostring(id)] = nil
		self.teamData[idx].exp = cardInfo.exp + expLeft

	end


end

function ExploreSystemRewardView:AddRewards(parent, rewards)
	if nil == parent then return end
	local parentSize = parent:getContentSize()
	-- local data = {parent = parent, midPointX = parentSize.width / 2, midPointY = parentSize.height / 2, maxCol= 5, scale = 1, hideCustomizeLabel = true, rewards = rewards}
	-- CommonUtils.createPropList(data)
	local goodList = require('common.CommonGoodList').new({
		size = parentSize,
		col = 5,
		showAmount = true,
		rewards = rewards
	})
	parent:addChild(goodList)

end

function ExploreSystemRewardView:BackClickCallback(sender)
	if not self.isControllable_ then return end
    PlayAudioByClickClose()
    local appFacadeIns     = AppFacade.GetInstance()
    local uiMgr            = appFacadeIns:GetManager('UIManager')
    uiMgr:GetCurrentScene():RemoveDialog(self)
end

function ExploreSystemRewardView:getViewData()
	return self.viewData_
end

function ExploreSystemRewardView:onCleanup()
	AppFacade.GetInstance():DispatchObservers(
		SIGNALNAMES.PlayerLevelUpExchange,
		self.delayUpgradeLevelData
	)

	
end

return ExploreSystemRewardView