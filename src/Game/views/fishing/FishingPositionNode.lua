local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local uiMgr = shareFacade:GetManager("UIManager")
local cardMgr = shareFacade:GetManager("CardManager")
local fishingMgr = AppFacade.GetInstance():GetManager("FishingManager")
local fishConfigParser = require('Game.Datas.Parser.FishConfigParser')
local fishingSpineCache = SpineCache(SpineCacheName.FISHING)

local RES_DICT          = {
    P_IMG_FRIEND_PANEL  = _res('ui/home/fishing/fishing_main_bg_seat_friend'),
    P_IMG_SELF_PANEL    = _res('ui/home/fishing/fishing_main_bg_seat_self'),
    P_IMG_FRIEND_NAME   = _res('ui/home/fishing/fishing_main_label_seat_friend'),
    P_IMG_SELF_NAME     = _res('ui/home/fishing/fishing_main_label_seat_empty'),
    P_IMG_FRIEND_FLAG   = _res('ui/home/fishing/fishing_main_btn_seat_friend'),
    P_IMG_LOCK_NAME     = _res('ui/home/fishing/fishing_main_label_seat_lock'),
    P_IMG_LEAF_RED      = _res('ui/home/teamformation/newCell/team_img_leaf_red'),
    P_IMG_LEAF_GREEN    = _res('ui/home/teamformation/newCell/team_img_leaf_green'),
    P_IMG_LEAF_YELLOW   = _res('ui/home/teamformation/newCell/team_img_leaf_yellow'),
    P_IMG_LEAF_GREY     = _res('ui/home/teamformation/newCell/team_img_leaf_grey'),
    P_IMG_LEAF_FREE     = _res('ui/home/teamformation/newCell/team_img_leaf_free'),
    P_IMG_TIME          = _res('avatar/ui/recipeMess/restaurant_ico_selling_timer'),
    P_BTN_ADD_BAIT      = _res('ui/common/maps_fight_btn_pet_add'),
    P_IMG_FRIEND_TIME   = _res('ui/home/fishing/fishing_friend_label_time'),
    P_BTN_SEND_DISABLE  = _res('ui/common/common_btn_orange_disable'),
    P_BTN_ADD_FISHERMAN = _res('ui/tower/path/tower_btn_team_add'),
    P_IMG_LOCK          = _res('ui/common/common_ico_lock'),
    P_BTN_NORMAL        = _res('ui/common/common_btn_orange'),

    P_SPINE_BAIT_EMPTY  = _spn('effects/fishing/common_ico_expression_8'),
    P_SPINE_EXHAUSTED   = _spn('avatar/animate/common_ico_expression_6'),
    P_SPINE_REST        = _spn('arts/effects/xxd'),

    P_FONT_NUMBER       = 'font/small/common_text_num.fnt',
}

local function GetRodLightEffectName( baitId )
    if 321001 == checkint(baitId) then
        return 'effect_1'
    elseif 321002 == checkint(baitId) then
        return 'effect_1'
    elseif 321003 == checkint(baitId) then
        return 'effect_1'
    elseif 321004 == checkint(baitId) then
        return 'effect_2'
    elseif 321005 == checkint(baitId) then
        return 'effect_2'
    elseif 321006 == checkint(baitId) then
        return 'effect_2'
    elseif 321007 == checkint(baitId) then
        return 'effect_3'
    elseif 321008 == checkint(baitId) then
        return 'effect_3'
    elseif 321009 == checkint(baitId) then
        return 'effect_3'
    end
    return 'effect_3'
end

for i=1,9 do
    local baitId = tostring(321000+i)
    RES_DICT[baitId] = _spn('effects/fishing/' .. baitId)
    local effectName = GetRodLightEffectName(baitId)
    RES_DICT[effectName] = _spn('effects/fishing/' .. effectName)
end

local FishingPositionNode = class('FishingPositionNode', function()
    local layout = CLayout:create()
    layout.name = 'FishingPositionNode'
    layout:enableNodeEvents()
    return layout
end)
local seatSize = cc.size(200, 500)

function FishingPositionNode:ctor(...)
    local args = unpack({...}) or {}
    self.tag = args.tag or 0
    self.isFriend = (0 == args.tag)

    self:setContentSize(seatSize)
    local function CreateView()
        local panelImage = display.newImageView(self.isFriend and RES_DICT.P_IMG_FRIEND_PANEL or RES_DICT.P_IMG_SELF_PANEL,
            seatSize.width / 2, seatSize.height / 2 - 10, {ap = cc.p(0.5, 0.5)})
        self:addChild(panelImage, 5)

        local labelImage = display.newButton(seatSize.width / 2, seatSize.height / 2 - 36, 
            {n = self.isFriend and RES_DICT.P_IMG_FRIEND_NAME or RES_DICT.P_IMG_SELF_NAME, ap = cc.p(0.5, 1), enable = false, scale9 = true})
        self:addChild(labelImage)
        display.commonLabelParams(labelImage, {text = '', fontSize = 20, color = 'ffffff', w = 160, hAlign = display.TAC})

        local detailImage, detailLayout, addLayout, prepareLayout, sendBtn, friendImage,addBaitButton,baitImage
        if self.isFriend then
            detailImage = display.newImageView(RES_DICT.P_IMG_FRIEND_NAME, seatSize.width / 2, labelImage:getPositionY() - 35, {ap = cc.p(0.5, 1), 
                scale9 = true, size = cc.size(171, 109)})
            self:addChild(detailImage)
    
            friendImage = display.newImageView(RES_DICT.P_IMG_FRIEND_FLAG, 40, seatSize.height / 2 + 4, {ap = cc.p(0.5, 0.5)})
            self:addChild(friendImage, 10)
            friendImage:setVisible(false)

            local detailSize = detailImage:getContentSize()
            detailLayout = CLayout:create()
            detailLayout:setContentSize(detailSize)
            display.commonUIParams(detailLayout, {ap = cc.p(0.5, 1), po = cc.p(seatSize.width / 2, detailImage:getPositionY())})
            self:addChild(detailLayout)

            for i=1,3 do
                local propertyImage = display.newImageView(RES_DICT.P_IMG_LOCK_NAME, detailSize.width / 2, detailSize.height - 21 - (i-1) * 34)
                detailLayout:addChild(propertyImage)
            end

            local operaProgressBar = CProgressBar:create(RES_DICT.P_IMG_LEAF_GREEN)
            operaProgressBar:setBackgroundImage(RES_DICT.P_IMG_LEAF_GREY)
            operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
            operaProgressBar:setAnchorPoint(cc.p(0.5, 0.5))
            operaProgressBar:setMaxValue(100)
            operaProgressBar:setValue(48)
            operaProgressBar:setPosition(cc.p(detailSize.width / 2 - 16, detailSize.height - 21))
            detailLayout:addChild(operaProgressBar,1)
            detailLayout.operaProgressBar = operaProgressBar
            local vigourProgressBar =  display.newImageView(RES_DICT.P_IMG_LEAF_FREE,0,0,{as = false})
            vigourProgressBar:setAnchorPoint(cc.p(0.5,0.5))
            vigourProgressBar:setPosition(cc.p(detailSize.width / 2 - 16, detailSize.height - 21))
            detailLayout:addChild(vigourProgressBar)
            detailLayout.vigourProgressBar = operaProgressBar

            local vigourLabel = display.newLabel( operaProgressBar:getPositionX() + operaProgressBar:getContentSize().width * 0.5 + 36, operaProgressBar:getPositionY(),{
                ap = display.RIGHT_CENTER, fontSize = 22, color = 'ffffff', text = "48"
            })
            detailLayout:addChild(vigourLabel, 2)
            detailLayout.vigourLabel = vigourLabel

            local baitImage = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), 27, detailSize.height - 55)
            baitImage:setScale(0.25)
            detailLayout:addChild(baitImage)
            detailLayout.baitImage = baitImage

            local baitLabel = display.newLabel(detailSize.width - 8, detailSize.height - 55, {ap = display.RIGHT_CENTER, fontSize = 22, color = 'ffffff', text = '100'})
            detailLayout:addChild(baitLabel)
            detailLayout.baitLabel = baitLabel

            local timeImage = display.newImageView(RES_DICT.P_IMG_TIME, 24, detailSize.height - 89)
            detailLayout:addChild(timeImage)

            local timeLabel = display.newLabel(detailSize.width - 8, detailSize.height - 89, {ap = display.RIGHT_CENTER, fontSize = 22, color = 'ffffff', text = '00:00:00'})
            detailLayout:addChild(timeLabel)
            detailLayout.timeLabel = timeLabel

            addLayout = CLayout:create()
            addLayout:setContentSize(detailSize)
            display.commonUIParams(addLayout, {ap = cc.p(0.5, 1), po = cc.p(seatSize.width / 2, detailImage:getPositionY())})
            self:addChild(addLayout)

            addBaitButton = display.newButton(detailSize.width / 2, detailSize.height - 36, {n = RES_DICT.P_BTN_ADD_BAIT, enable = true})
            addLayout:addChild(addBaitButton)
            addBaitButton:setOnClickScriptHandler(function ( sender )
                PlayAudioByClickNormal()
                if not  app.fishingMgr:GetHomeDataByKey('isFishLimit') then
                    local mediator = require("Game.mediator.fishing.FishingAddBaitMediator").new({isFriend = true})
                    shareFacade:RegistMediator(mediator)
                else
                    app.uiMgr:ShowInformationTips(__('已达到钓场收获上限，请先收取钓场奖励'))
                end
            end)

            local numImage = display.newButton(detailSize.width / 2, detailSize.height - 89, 
                {n = RES_DICT.P_IMG_SELF_NAME, ap = cc.p(0.5, 0.5), enable = false})
            addLayout:addChild(numImage)
            display.commonLabelParams(numImage, {text = __('添加钓饵'), fontSize = 20, color = 'ffa804'})

            prepareLayout = CLayout:create()
            prepareLayout:setContentSize(cc.size(detailSize.width, detailSize.height + 100))
            display.commonUIParams(prepareLayout, {ap = cc.p(0.5, 1), po = cc.p(seatSize.width / 2, detailImage:getPositionY())})
            self:addChild(prepareLayout)

            local baitImage = display.newButton(detailSize.width / 2, prepareLayout:getContentSize().height - 40, {n = CommonUtils.GetGoodsIconPathById(GOLD_ID)})
            baitImage:setScale(0.45)
            prepareLayout:addChild(baitImage)
            prepareLayout.baitImage = baitImage
            baitImage:setOnClickScriptHandler(function ( sender )
                PlayAudioByClickNormal()
                if not  app.fishingMgr:GetHomeDataByKey('isFishLimit') then
                    local mediator = require("Game.mediator.fishing.FishingAddBaitMediator").new({isFriend = true})
                    shareFacade:RegistMediator(mediator)
                else
                    app.uiMgr:ShowInformationTips(__('已达到钓场收获上限，请先收取钓场奖励'))
                end
            end)

            local numImage = display.newButton(detailSize.width / 2, prepareLayout:getContentSize().height - 89, 
                {n = RES_DICT.P_IMG_LOCK_NAME, ap = cc.p(0.5, 0.5), enable = false})
            prepareLayout:addChild(numImage)

            local numLabel = cc.Label:createWithBMFont(RES_DICT.P_FONT_NUMBER, 20)
            numLabel:setBMFontSize(24)
            numLabel:setAnchorPoint(cc.p(0.5, 0.5))
            numLabel:setHorizontalAlignment(display.TAC)
            numLabel:setPosition(detailSize.width / 2, numImage:getPositionY())
            prepareLayout:addChild(numLabel)
            prepareLayout.numLabel = numLabel

            local timeBG = display.newImageView(RES_DICT.P_IMG_FRIEND_TIME, detailSize.width / 2, 18, {ap = cc.p(0.5, 0.5)})
            prepareLayout:addChild(timeBG)

            local timeImage = display.newImageView(RES_DICT.P_IMG_TIME, 34, 18)
            prepareLayout:addChild(timeImage)

            local timeLabel = display.newLabel(detailSize.width - 18, 18, {ap = display.RIGHT_CENTER, fontSize = 22, color = 'ffffff', text = '00:00:00'})
            prepareLayout:addChild(timeLabel)
            prepareLayout.timeLabel = timeLabel

            sendBtn = display.newButton(0, 0, {n = RES_DICT.P_BTN_SEND_DISABLE})
            display.commonUIParams(sendBtn, {po = cc.p(seatSize.width / 2, 30)})
            display.commonLabelParams(sendBtn, fontWithColor('14', {text = __('派遣')}))
            self:addChild(sendBtn)
            sendBtn:setVisible(false)
            sendBtn:setOnClickScriptHandler(function ( sender )
                PlayAudioByClickNormal()
                if not  app.fishingMgr:GetHomeDataByKey('isFishLimit')  then
                    shareFacade:DispatchObservers(FISHERMAN_SENT_TO_FRIEND_EVENT, {})
                else
                    app.uiMgr:ShowInformationTips(__('已达到钓场收获上限，请先收取钓场奖励'))
                end

            end)

            detailLayout:setVisible(false)
            addLayout:setVisible(false)
            prepareLayout:setVisible(false)
        end

        local addView = CColorView:create(cc.r4b(0))
        addView:setContentSize(cc.size(114, 130))
        addView:setTouchEnabled(true)
        self:addChild(addView, 20)
        display.commonUIParams(addView, {ap = cc.p(0.5, 0.5), po = cc.p(seatSize.width / 2, seatSize.height / 2 + 92), animate = true, cb = function (  )
            PlayAudioByClickNormal()
			shareFacade:DispatchObservers(FISHERMAN_SWITCH_EVENT, {tag = self.tag})
        end})

        local btnSize = addView:getContentSize()
		local addButton = FilteredSpriteWithOne:create()
		addButton:setTexture(RES_DICT.P_BTN_ADD_FISHERMAN)
		addButton:setPosition(cc.p(btnSize.width / 2, btnSize.height / 2))
        addView:addChild(addButton)
        
        local btnSize = addButton:getContentSize()
        local emptyImage = display.newImageView(self.isFriend and RES_DICT.P_IMG_FRIEND_FLAG or RES_DICT.P_BTN_ADD_BAIT, 
            btnSize.width / 2, btnSize.height / 2 + 8, {ap = cc.p(0.5, 0.5)})
        addButton:addChild(emptyImage)

        local lockImage
        if not self.isFriend then
            lockImage = display.newImageView(RES_DICT.P_IMG_LOCK, btnSize.width / 2, btnSize.height / 2 + 8, {ap = cc.p(0.5, 0.5)})
            addButton:addChild(lockImage)
            lockImage:setVisible(false)
        end
    
        local labelSize = labelImage:getContentSize()
        local operaProgressBar = CProgressBar:create(RES_DICT.P_IMG_LEAF_GREEN)
        operaProgressBar:setBackgroundImage(RES_DICT.P_IMG_LEAF_GREY)
        operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        operaProgressBar:setAnchorPoint(cc.p(0.5, 0.5))
        operaProgressBar:setMaxValue(100)
        operaProgressBar:setValue(48)
        operaProgressBar:setPosition(cc.p(labelSize.width / 2 - 16, labelSize.height / 2))
        labelImage:addChild(operaProgressBar,1)
        labelImage.operaProgressBar = operaProgressBar
        local vigourProgressBar =  display.newImageView(RES_DICT.P_IMG_LEAF_FREE,0,0,{as = false})
        vigourProgressBar:setAnchorPoint(cc.p(0.5,0.5))
        vigourProgressBar:setPosition(cc.p(labelSize.width / 2 - 16, labelSize.height / 2))
        labelImage:addChild(vigourProgressBar)
        labelImage.vigourProgressBar = vigourProgressBar
    
        local vigourLabel = display.newLabel( operaProgressBar:getPositionX() + operaProgressBar:getContentSize().width * 0.5 + 40, operaProgressBar:getPositionY(),{
            ap = display.RIGHT_CENTER, fontSize = 22, color = 'ffffff', text = ""
        })
        labelImage:addChild(vigourLabel, 2)
        labelImage.vigourLabel = vigourLabel

        local baitEmptySpinePath = tostring(RES_DICT.P_SPINE_BAIT_EMPTY)
        fishingSpineCache:addCacheData(baitEmptySpinePath, baitEmptySpinePath, 0.8)
        local baitEmptyImage = fishingSpineCache:createWithName(baitEmptySpinePath)
        baitEmptyImage:update(0)
        baitEmptyImage:setTag(1)
        baitEmptyImage:setAnimation(0, 'idle', true)
        baitEmptyImage:setPosition(cc.p(seatSize.width / 2 - 30, seatSize.height - 70))
        self:addChild(baitEmptyImage)
        baitEmptyImage:setVisible(false)

        local expressionAvatar = sp.SkeletonAnimation:create(RES_DICT.P_SPINE_EXHAUSTED.json, RES_DICT.P_SPINE_EXHAUSTED.atlas, 1)
        expressionAvatar:update(0)
        expressionAvatar:setTag(1)
        expressionAvatar:setAnimation(0, 'idle', true)
        expressionAvatar:setPosition(cc.p(seatSize.width / 2 - 30, seatSize.height - 70))
        expressionAvatar:setScale(0.8)
        self:addChild(expressionAvatar)
        expressionAvatar:setVisible(false)

        -- if not self.isFriend then
            local numLabel = cc.Label:createWithBMFont(RES_DICT.P_FONT_NUMBER, '')
            numLabel:setBMFontSize(40)
            numLabel:setAnchorPoint(cc.p(0.5, 0.5))
            numLabel:setPosition(seatSize.width / 2, seatSize.height / 2)
            self:addChild(numLabel, 100)
            self.numLabel = numLabel
        -- end

        local touchNode = CColorView:create(cc.r4b(0))
        self:addChild(touchNode, 10)
        touchNode:setTouchEnabled(true)
        local size = cc.size(130, 240)
        touchNode:setContentSize(size)
        touchNode:setPosition(cc.p(seatSize.width / 2, seatSize.height / 2 + 40))
        touchNode:setOnClickScriptHandler(function (  )
            PlayAudioByClickNormal()
			shareFacade:DispatchObservers(FISHERMAN_CLICK_EVENT, {friendFish = self.friendFish, card = self.card, tag = self.tag})
        end)

        return {
            panelImage          = panelImage,
            addView             = addView,
            addButton           = addButton,
            touchNode           = touchNode,
            labelImage          = labelImage,
            seatSize            = seatSize,
            detailImage         = detailImage,
            detailLayout        = detailLayout,
            addLayout           = addLayout,
            prepareLayout       = prepareLayout,
            lockImage           = lockImage,
            emptyImage          = emptyImage,
            sendBtn             = sendBtn,
            baitEmptyImage      = baitEmptyImage,
            expressionAvatar    = expressionAvatar,
            friendImage         = friendImage,
            addBaitButton       = addBaitButton,
            baitImage           = baitImage,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
    end, __G__TRACKBACK__)
end

function FishingPositionNode:RefreshNode( ... )
    if self.isFriend then
        self:RefreshFriendNode( ... )
        return
    end
    local args = unpack({...}) or {}
    local card = args.card or {}
    local isLock = args.isLock
    local inFriendGround = args.inFriendGround
    local cardData = card
    if not inFriendGround and next(card) then
        if card.cardId then
            cardData = gameMgr:GetCardDataByCardId(card.cardId)
        elseif card.playerCardId then
            cardData = gameMgr:GetCardDataById(card.playerCardId)
        end
    end
    self.card = card

    local viewData = self.viewData
    local labelImage = viewData.labelImage
    local addView = viewData.addView
    local addButton = viewData.addButton
    local touchNode = viewData.touchNode
    local seatSize = viewData.seatSize
    local lockImage = viewData.lockImage
    local emptyImage = viewData.emptyImage
    local baitEmptyImage = viewData.baitEmptyImage
    local expressionAvatar = viewData.expressionAvatar

    lockImage:setVisible(isLock)
    emptyImage:setVisible(not isLock)
    touchNode:setVisible(next(card) and true)

    local skinId = cardData.skinId and tostring(cardData.skinId) or tostring(cardData.defaultSkinId)
    if next(card) and not isLock then
        if self.roleNode then 
            if self.roleNode:getTag() ~= checkint(skinId) then
                self.roleNode:removeFromParent() 
                self.roleNode = nil
            end
        end
    else
        if self.roleNode then 
            self.roleNode:removeFromParent() 
            self.roleNode = nil
        end
    end
    local bait = card.baitId and true
    -- 在播放单次钓鱼结束时更新了钓手数据
    local keepFishingEndAni = false
    if bait and next(card) and not isLock then
        if self.rodSpine then
            if self.rodSpine:getTag() ~= checkint(card.baitId) then
                self.rodSpine:removeFromParent() 
                self.rodSpine = nil
                if self.rodLightSpine then
                    self.rodLightSpine:removeFromParent() 
                    self.rodLightSpine = nil
                end
            end
            if not args.start and self.fishingEndAni then
                keepFishingEndAni = true
            end
        else
            self.fishingEndAni = true
        end
    else
        if self.rodSpine then 
            self.rodSpine:removeFromParent() 
            self.rodSpine = nil
        end
        if self.rodLightSpine then
            self.rodLightSpine:removeFromParent() 
            self.rodLightSpine = nil
        end
    end

    -- 未解锁
    if isLock then
        self.card = nil
		addButton:setFilter(GrayFilter:create())
        addView:setVisible(true)
        touchNode:setVisible(false)
        labelImage:setNormalImage(RES_DICT.P_IMG_LOCK_NAME)
        self:SetNameLabelContent({labelImage = labelImage, labelParams = {text = __('暂未解锁'), fontSize = 20, color = 'ffffff'}})
        addView:setVisible(not inFriendGround)
        labelImage:setVisible(not inFriendGround)
        expressionAvatar:setVisible(false)
        baitEmptyImage:setVisible(false)
        return
    else
		addButton:clearFilter()
    end
    if next(card) then
        if not self.roleNode then
            local roleNode = AssetsUtils.GetCardSpineNode({skinId = skinId})
            roleNode:update(0)
            roleNode:setToSetupPose()
            roleNode:setAnimation(0, 'idle', true)
            roleNode:setScale(0.6)
            local pos = self:convertToWorldSpace(cc.p(seatSize.width / 2, seatSize.height / 2 - 80))
            display.commonUIParams(roleNode, {po = pos})
            self:getParent():addChild(roleNode, 3)
            if 5 == self.tag then
                roleNode:setScaleX(-0.6)
            end
            roleNode:setTag(checkint(skinId))
            self.roleNode = roleNode
        end
        if self.roleNode and not args.start then
            self.roleNode:setAnimation(0, 'idle', true)
        end

        if bait then
            if not self.rodSpine then
                local baitSpinePath = tostring(RES_DICT[tostring(card.baitId)])
                fishingSpineCache:addCacheData(baitSpinePath, baitSpinePath, 1)
                local rodSpine = fishingSpineCache:createWithName(baitSpinePath)
                rodSpine:update(0)
                rodSpine:setTag(1)
                rodSpine:setPosition(cc.p(seatSize.width / 2, seatSize.height / 2 - 23))
                rodSpine:setTag(checkint(card.baitId))
                rodSpine:setVisible(false)
                self:addChild(rodSpine, 5)
                if not self.rodLightSpine then
                    local spineName = tostring(RES_DICT[GetRodLightEffectName(card.baitId)])
                    fishingSpineCache:addCacheData(spineName, spineName, 1)
                    local rodLightSpine = fishingSpineCache:createWithName(spineName)
                    rodLightSpine:update(0)
                    rodLightSpine:setAnimation(0, 'idle', true)
                    rodLightSpine:setPosition(cc.p(seatSize.width / 2 + 76, seatSize.height / 2 - 220))
                    rodLightSpine:setVisible(false)
                    self:addChild(rodLightSpine, 6)
                    self.rodLightSpine = rodLightSpine
                end
                if 5 == self.tag then 
                    rodSpine:setScaleX(-1) 
                    self.rodLightSpine:setPositionX(seatSize.width / 2 + (-76))
                end
                self.rodSpine = rodSpine
                if self.fishingEndAni and args.start then
                    self:PlaySetBaitAni(card.baitId)
                else
                    rodSpine:setVisible(true)
                    rodSpine:setAnimation(0, 'idle', true)
                    self.rodLightSpine:setVisible(true)
                end
                self:RandomFlip()
            elseif self.fishingEndAni and args.start then
                self:PlaySetBaitAni(card.baitId)
                self:RandomFlip()
            end
        end

        labelImage:setNormalImage(RES_DICT.P_IMG_LOCK_NAME)
        local maxVigour = inFriendGround and cardData.maxVigour or checkint(app.restaurantMgr:getCardVigourLimit(cardData.id))
        self:SetNameLabelContent({labelImage = labelImage, vigour = checkint(cardData.vigour), maxVigour = maxVigour or checkint(cardData.vigour)})
        expressionAvatar:setVisible(0 >= checkint(cardData.vigour) and not bait)
        baitEmptyImage:setVisible(not bait and not expressionAvatar:isVisible() and not next(self.homeData.fishBaits or {}))
        addView:setVisible(false)
        labelImage:setVisible(true)
    else
        self.card = nil
        labelImage:setNormalImage(RES_DICT.P_IMG_SELF_NAME)
        self:SetNameLabelContent({labelImage = labelImage, labelParams = {text = __('添加钓手'), fontSize = 20, color = 'ffa804'}})
        expressionAvatar:setVisible(false)
        baitEmptyImage:setVisible(false)
        addView:setVisible(not inFriendGround)
        labelImage:setVisible(not inFriendGround)
    end
    self.fishingEndAni = keepFishingEndAni
end

function FishingPositionNode:RefreshFriendNode( ... )
    local args = unpack({...}) or {}
    local friendFish = args.friendFish or {}
    local operational = args.operational and (not friendFish.friendId)
    local bait = friendFish.baitId and true
    local card = friendFish.cardId and true
    self.friendFish = friendFish

    local viewData = self.viewData
    local panelImage = viewData.panelImage
    local labelImage = viewData.labelImage
    local addView = viewData.addView
    local touchNode = viewData.touchNode
    local seatSize = viewData.seatSize
    local detailLayout = viewData.detailLayout
    local addLayout = viewData.addLayout
    local prepareLayout = viewData.prepareLayout
    local detailImage = viewData.detailImage
    local emptyImage = viewData.emptyImage
    local sendBtn = viewData.sendBtn
    local expressionAvatar = viewData.expressionAvatar
    local friendImage = viewData.friendImage

    if card then
        if self.roleNode then 
            if self.roleNode:getTag() ~= checkint(friendFish.skinId) then
                self.roleNode:removeFromParent() 
                self.roleNode = nil
            end
        end
    else
        if self.roleNode then 
            self.roleNode:removeFromParent() 
            self.roleNode = nil
        end
    end
    if card and not operational then
        if self.rodSpine then
            if self.rodSpine:getTag() ~= checkint(friendFish.baitId) then
                self.rodSpine:removeFromParent() 
                self.rodSpine = nil
                if self.rodLightSpine then
                    self.rodLightSpine:removeFromParent() 
                    self.rodLightSpine = nil
                end
            end
        end
    else
        if self.rodSpine then 
            self.rodSpine:removeFromParent() 
            self.rodSpine = nil
        end
        if self.rodLightSpine then
            self.rodLightSpine:removeFromParent() 
            self.rodLightSpine = nil
        end
    end

    panelImage:setPositionX(seatSize.width / 2)
    addView:setVisible(not card)
    touchNode:setVisible(card and true)
    friendImage:setVisible(false)
    if card then
        if not self.roleNode then
            local roleNode = AssetsUtils.GetCardSpineNode({skinId = friendFish.skinId})
            roleNode:update(0)
            roleNode:setToSetupPose()
            roleNode:setAnimation(0, 'idle', true)
            roleNode:setScale(0.6)
            local pos = self:convertToWorldSpace(cc.p(seatSize.width / 2, seatSize.height / 2 - 80))
            display.commonUIParams(roleNode, {po = pos})
            self:getParent():addChild(roleNode, 3)
            roleNode:setTag(checkint(friendFish.skinId))
            self.roleNode = roleNode
        end
        expressionAvatar:setVisible(0 >= checkint(friendFish.vigour))
    else
        expressionAvatar:setVisible(false)
    end

    emptyImage:setTexture(operational and RES_DICT.P_BTN_ADD_BAIT or RES_DICT.P_IMG_FRIEND_FLAG)
    sendBtn:setVisible(operational and true)
    if operational then
        detailImage:setVisible(true)
        if not card then
            labelImage:setNormalImage(RES_DICT.P_IMG_SELF_NAME)
            self:SetNameLabelContent({labelImage = labelImage, labelParams = {text = __('添加钓手'), fontSize = 20, color = 'ffa804'}})
        else
            labelImage:setNormalImage(RES_DICT.P_IMG_LOCK_NAME)
            local maxVigour = friendFish.maxVigour or friendFish.vigour
            if tostring(friendFish.friendId) == tostring(gameMgr:GetUserInfo().playerId) then
                local cardData = gameMgr:GetCardDataByCardId(friendFish.cardId)
                maxVigour = app.restaurantMgr:getCardVigourLimit(cardData.id)
            end
            self:SetNameLabelContent({labelImage = labelImage, vigour = friendFish.vigour, maxVigour = maxVigour})
        end
        detailLayout:setVisible(false)
        addLayout:setVisible(not bait)
        prepareLayout:setVisible(bait and true)
        if bait then
            local baitImage = prepareLayout.baitImage
            local numLabel = prepareLayout.numLabel
            baitImage:setNormalImage(CommonUtils.GetGoodsIconPathById(friendFish.baitId))
            baitImage:setSelectedImage(CommonUtils.GetGoodsIconPathById(friendFish.baitId))
            numLabel:setString(friendFish.baitNum)
        end
        if bait and card then
            sendBtn:setNormalImage(RES_DICT.P_BTN_NORMAL)
            sendBtn:setSelectedImage(RES_DICT.P_BTN_NORMAL)
            local time = string.formattedTime(checkint(fishingMgr:GetFriendEstimatedTime(friendFish, self.homeData.buff or {})),'%02i:%02i:%02i')
            prepareLayout.timeLabel:setString(time)
            detailLayout.timeLabel:setString(time)
        else
            sendBtn:setNormalImage(RES_DICT.P_BTN_SEND_DISABLE)
            sendBtn:setSelectedImage(RES_DICT.P_BTN_SEND_DISABLE)
            prepareLayout.timeLabel:setString('00:00:00')
            detailLayout.timeLabel:setString('00:00:00')
        end
    else
        if card then
            if not self.rodSpine then
                local baitSpinePath = tostring(RES_DICT[tostring(friendFish.baitId)])
                fishingSpineCache:addCacheData(baitSpinePath, baitSpinePath, 1)
                local rodSpine = fishingSpineCache:createWithName(baitSpinePath)
                rodSpine:update(0)
                rodSpine:setTag(1)
                rodSpine:setAnimation(0, 'idle', true)
                rodSpine:setPosition(cc.p(seatSize.width / 2 + 30, seatSize.height / 2 - 23))
                rodSpine:setTag(checkint(friendFish.baitId))
                self:addChild(rodSpine, 5)
                self.rodSpine = rodSpine
            end
            if not self.rodLightSpine then
                local spineName = tostring(RES_DICT[GetRodLightEffectName(friendFish.baitId)])
                fishingSpineCache:addCacheData(spineName, spineName, 1)
                local rodLightSpine = fishingSpineCache:createWithName(spineName)
                rodLightSpine:update(0)
                rodLightSpine:setAnimation(0, 'idle', true)
                rodLightSpine:setPosition(cc.p(seatSize.width / 2 + 106, seatSize.height / 2 - 270))
                self:addChild(rodLightSpine, 6)
                self.rodLightSpine = rodLightSpine
            end
            if args.start then
                self.rodLightSpine:setVisible(false)
                self.rodSpine:setVisible(false)
                self:PlaySetBaitAni(friendFish.baitId)
            end
            panelImage:setPositionX(seatSize.width / 2 + 30)
            friendImage:setVisible(true)
            self:SetNameLabelContent({labelImage = labelImage, labelParams = {text = friendFish.name, fontSize = 20, color = 'ffffff'}})
        else
            self:SetNameLabelContent({labelImage = labelImage, labelParams = {text = __('好友钓手'), fontSize = 20, color = 'ffffff'}})
        end
        labelImage:setNormalImage(RES_DICT.P_IMG_FRIEND_NAME)
        addLayout:setVisible(false)
        prepareLayout:setVisible(false)
        detailImage:setVisible(card and true)
        detailLayout:setVisible(card and true)
        if card then
            local maxVigour = friendFish.maxVigour or friendFish.vigour
            if tostring(friendFish.friendId) == tostring(gameMgr:GetUserInfo().playerId) then
                local cardData = gameMgr:GetCardDataByCardId(friendFish.cardId)
                maxVigour = app.restaurantMgr:getCardVigourLimit(cardData.id)
            end
            self:SetVigourValue(maxVigour, friendFish.vigour, detailLayout.vigourLabel, detailLayout.operaProgressBar)
            detailLayout.baitImage:setTexture(CommonUtils.GetGoodsIconPathById(friendFish.baitId))
            detailLayout.baitLabel:setString(friendFish.baitNum)
            detailLayout.timeLabel:setString(string.formattedTime(checkint(fishingMgr:GetFriendEstimatedTime(friendFish, self.homeData.buff or {})),'%02i:%02i:%02i'))
        else
        end
    end
    detailImage:setPositionY(labelImage:getPositionY() - labelImage:getContentSize().height - 5)
    detailLayout:setPositionY(detailImage:getPositionY())
    addLayout:setPositionY(detailImage:getPositionY())
    prepareLayout:setPositionY(detailImage:getPositionY())
end

function FishingPositionNode:PlaySetBaitAni( baitId )
    local baitImage = display.newImageView(CommonUtils.GetGoodsIconPathById(baitId), seatSize.width / 2, seatSize.height / 2)
    baitImage:setScale(0.4)
    baitImage:setOpacity(127)
    self:addChild(baitImage, 20)
    local t = 0.3
    baitImage:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.MoveBy:create(t, cc.p(0, 40)),
            cc.ScaleTo:create(t, 0.8),
            cc.FadeIn:create(t)
        ),
        cc.Spawn:create(
            cc.MoveBy:create(t, cc.p(0, -40)),
            cc.ScaleTo:create(t, 0.6)
        ),
        cc.Spawn:create(
            cc.MoveBy:create(t, cc.p(0, 80)),
            cc.FadeOut:create(t),
            cc.CallFunc:create(function (  )
                if self.rodSpine then
                    PlayAudioClip(AUDIOS.UI.ui_fishing_pole.id)
                    self.rodSpine:setVisible(true)
                    self.rodSpine:setAnimation(0, 'play', false)
                    self.rodSpine:addAnimation(0, 'idle', true)
                    self.rodSpine:registerSpineEventHandler(function (event)
                        if event.animation == 'play' then
                            if self.rodLightSpine then
                                self.rodLightSpine:setOpacity(0)
                                self.rodLightSpine:runAction(cc.Sequence:create(
                                    cc.Show:create(),
                                    cc.FadeIn:create(0.2)
                                ))
                            end
                        end
                    end, sp.EventType.ANIMATION_END)
                end
            end)
        ),
        cc.RemoveSelf:create()
    ))
end

function FishingPositionNode:ShowCountDown( time )
    if DEBUG > 1 and cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_MAC then
        self.numLabel:setString(time)
    end
end

function FishingPositionNode:SingleFishingEnd( cb )
    if self.rodLightSpine then
        self.rodLightSpine:setVisible(false)
    end
    if self.rodSpine and not self.fishingEndAni then
        self.fishingEndAni = true
        self.rodSpine:setAnimation(0, 'play2', false)
        self.rodSpine:registerSpineEventHandler(function (event)
            if event.animation == 'play2' then
                if self.roleNode then
                    self.roleNode:setAnimation(0, 'win', false)
                    self.roleNode:addAnimation(0, 'idle', true)
                end
                self.rodSpine:setVisible(false)
                if cb then
                    cb()
                end
            end
        end, sp.EventType.ANIMATION_END)
    end
end

function FishingPositionNode:FriendSingleFishingEnd( cb, friendFish )
    if self.rodLightSpine then
        self.rodLightSpine:setVisible(false)
    end
    local seatSize = self.viewData.seatSize
    if self.rodSpine and not self.fishingEndAni then
        self.fishingEndAni = true
        self.rodSpine:setAnimation(0, 'play2', false)
        self.rodSpine:registerSpineEventHandler(function (event)
            if event.animation == 'play2' then
                self.fishingEndAni = false
                if self.roleNode then
                    self.roleNode:setAnimation(0, 'win', false)
                    self.roleNode:addAnimation(0, 'idle', true)
                    self.roleNode:registerSpineEventHandler(function ( event )
                        if event.animation == 'win' then
                            self.roleNode:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
                            uiMgr:GetCurrentScene():runAction(
                                cc.CallFunc:create(function (  )
                                    if cb then
                                        cb()
                                    end
                                end)
                            )
                        end
                    end, sp.EventType.ANIMATION_END)
                    self.rodSpine:setVisible(false)
                end
            end
        end, sp.EventType.ANIMATION_END)
    end
end

--[[
设置显示名字还是新鲜度
@params params table {
    labelImage node 父节点
    labelParams table 自定义 文本内容
    vigour int 新鲜度
    maxVigour int 最大新鲜度
}
--]]
function FishingPositionNode:SetNameLabelContent( ... )
    local args = unpack({...}) or {}
    local labelImage = args.labelImage
    local labelParams = args.labelParams
    local operaProgressBar = labelImage.operaProgressBar
    local vigourProgressBar = labelImage.vigourProgressBar
    local vigourLabel = labelImage.vigourLabel
    local nameLabel = labelImage:getLabel()

    operaProgressBar:setVisible(not labelParams)
    vigourProgressBar:setVisible(not labelParams)
    vigourLabel:setVisible(not labelParams)
    if labelParams then
        display.commonLabelParams(nameLabel, labelParams)
        local labelSize = display.getLabelContentSize(nameLabel)
        if 30 < labelSize.height then
            labelImage:setContentSize(cc.size(171, 54))
        else
            labelImage:setContentSize(cc.size(171, 30))
        end
        local initFontSize = labelParams.fontSize or 20
        while 46 < labelSize.height and 2 <= initFontSize do
            initFontSize = initFontSize - 2
            table.merge(labelParams, {fontSize = initFontSize})
            display.commonLabelParams(nameLabel, labelParams)
            labelSize = display.getLabelContentSize(nameLabel)
        end
    else
        labelImage:setContentSize(cc.size(171, 30))
        display.commonLabelParams(nameLabel, {text = ''})

        self:SetVigourValue(args.maxVigour, args.vigour, vigourLabel, operaProgressBar)
    end
end

function FishingPositionNode:SetVigourValue( maxVigour, vigour, vigourLabel, operaProgressBar )
    vigourLabel:setString(tostring(vigour))
    local ratio = (vigour / maxVigour) * 100
    operaProgressBar:setValue(rangeId(ratio, 100))
    if ratio <= 40 then
        operaProgressBar:setProgressImage(RES_DICT.P_IMG_LEAF_RED)
    elseif ratio <= 60 then
        operaProgressBar:setProgressImage(RES_DICT.P_IMG_LEAF_YELLOW)
    else
        operaProgressBar:setProgressImage(RES_DICT.P_IMG_LEAF_GREEN)
    end
end

function FishingPositionNode:AddVigourEffect( args )
    self:SetNameLabelContent({labelImage = self.viewData.labelImage, vigour = checkint(args.vigour), maxVigour = app.restaurantMgr:getCardVigourLimit(args.requestData.playerCardId)})

    local animateNode = self:getChildByName('AddVigourEffect')
    if animateNode then return end
    local animateNode = sp.SkeletonAnimation:create(RES_DICT.P_SPINE_REST.json, RES_DICT.P_SPINE_REST.atlas, 0.8)
    animateNode:setAnimation(0, 'idle', false)
    animateNode:setName("AddVigourEffect")
    local size = self:getContentSize()
    display.commonUIParams(animateNode, {ap = display.CENTER_BOTTOM,po = cc.p(size.width * 0.5, size.height / 2)})

    animateNode:registerSpineEventHandler(function (event)
        animateNode:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
        animateNode:runAction(cc.Spawn:create(cc.FadeOut:create(0.1),cc.RemoveSelf:create()))
    end,sp.EventType.ANIMATION_COMPLETE)
    self:addChild(animateNode,10)
end

function FishingPositionNode:RandomFlip( ... )
    if 5 ~= self.tag then
        local isFlip = (1 == math.random( 2 ))
        local rodSpine = self.rodSpine
        local roleNode = self.roleNode
        local rodLightSpine = self.rodLightSpine
        if rodSpine and roleNode then
            rodLightSpine:setPositionX(seatSize.width / 2 + (isFlip and -76 or 76))
            rodSpine:setScaleX(isFlip and -1 or 1)
            roleNode:setScaleX(isFlip and -0.6 or 0.6)
        end
    end
end

function FishingPositionNode:SetHomeData( datas )
    self.homeData = datas
end

return FishingPositionNode