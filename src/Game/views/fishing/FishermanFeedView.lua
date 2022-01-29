local GameScene = require( "Frame.GameScene" )
local FishermanFeedView = class("FishermanFeedView", GameScene)

local FishermanFeedFoodLayer = require('Game.views.fishing.FishermanFeedFoodLayer')
local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local cardMgr = shareFacade:GetManager("CardManager")
local socketMgr = shareFacade:GetManager('SocketManager')
local uiMgr = shareFacade:GetManager('UIManager')

local NAME = "FishermanFeedMediator"

local RES_DICT          = {
    F_BG_DETAIL         = _res('avatar/ui/restaurant_info_bg'),
    F_IMG_PANEL         = _res('avatar/ui/recovery_bg'),
    F_IMG_LEAF_RED      = _res('ui/home/teamformation/newCell/team_img_leaf_red'),
    F_IMG_LEAF_GREEN    = _res('ui/home/teamformation/newCell/team_img_leaf_green'),
    F_IMG_LEAF_YELLOW   = _res('ui/home/teamformation/newCell/team_img_leaf_yellow'),
    F_IMG_LEAF_GREY     = _res('ui/home/teamformation/newCell/team_img_leaf_grey'),
    F_IMG_LEAF_FREE     = _res('ui/home/teamformation/newCell/team_img_leaf_free'),
    F_BTN_KICK_OUT      = _res('ui/common/common_btn_orange'),
    F_BTN_FEED          = _res('avatar/ui/refresh_main_ico_eat_food'),
    F_IMG_NAME          = _res('avatar/ui/card_bar_bg'),
    F_BTN_ICE_ROOM      = _res('ui/home/nmain/restaurant_info_btn_go_to_rest'),
    F_IMG_WARNING       = _res('ui/common/common_btn_warning'),
}
function FishermanFeedView:ctor(...)
	self.super.ctor(self,'views.FishermanFeedView')
    local args = unpack({...})
    local touchView = CColorView:create(cc.r4b(0))
    touchView:setContentSize(display.size)
    touchView:setTouchEnabled(true)
    display.commonUIParams(touchView, { po = display.center})
    touchView:setOnClickScriptHandler(function(sender)
        shareFacade:UnRegsitMediator(NAME)
    end)
    self:addChild(touchView)

    -- dump(args)
    self.isRequesting = false -- 正在请求中的逻辑
    local operational = args.operational
    local friendFish = args.friendFish
    local tag = args.tag
    local card = args.card or {}
    self.friendFish = friendFish
    self.tag = tag
    self.card = card

    local bgImage = display.newImageView(RES_DICT.F_BG_DETAIL, -60, 0,{ap = display.LEFT_BOTTOM})
    self:addChild(bgImage,1)
    if bgImage:getContentSize().width < 60 + display.width then
        bgImage:setPositionX(display.width - bgImage:getContentSize().width)
    end

    --添加卡牌页面
    local cardInfo = friendFish or card
    local skinId = cardInfo.skinId
    -- 自家钓手
    if operational and 0 ~= tag then
        if card.cardId then
            cardInfo = gameMgr:GetCardDataByCardId(card.cardId)
        elseif card.playerCardId then
            cardInfo = gameMgr:GetCardDataById(card.playerCardId)
        end
        skinId = cardInfo.defaultSkinId
    end
    local role = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.5})
    role:setToSetupPose()
    role:setAnimation(0, 'idle', true)
    display.commonUIParams(role, {po = cc.p(display.SAFE_L + 122, 30)})
    self:addChild(role,11)

    local progressBG = display.newImageView(RES_DICT.F_IMG_PANEL, {
        scale9 = true, size = cc.size(168,32)
    })
    display.commonUIParams(progressBG, {po = cc.p(display.SAFE_L + 106, 24)})
    self:addChild(progressBG,12)

    local operaProgressBar = CProgressBar:create(RES_DICT.F_IMG_LEAF_RED)
    operaProgressBar:setBackgroundImage(RES_DICT.F_IMG_LEAF_GREY)
    operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    operaProgressBar:setAnchorPoint(cc.p(0, 0.5))
    operaProgressBar:setMaxValue(100)
    operaProgressBar:setValue(0)
    operaProgressBar:setPosition(cc.p(display.SAFE_L + 26, 24))
    self:addChild(operaProgressBar,15)

    local vigourProgressBar =  display.newImageView(RES_DICT.F_IMG_LEAF_FREE,0,0,{as = false})
    vigourProgressBar:setAnchorPoint(cc.p(0,0.5))
    vigourProgressBar:setPosition(cc.p(display.SAFE_L + 24,24))
    self:addChild(vigourProgressBar,14)

    local vigourNum = cardInfo.vigour
    local vigourLabel = display.newLabel(display.SAFE_L + 26 + operaProgressBar:getContentSize().width + 40, operaProgressBar:getPositionY(),{
        ap = display.RIGHT_CENTER, fontSize = 20, color = 'ffffff', text = tostring(vigourNum)
    })
    self:addChild(vigourLabel, 16)

    local cardId = cardInfo.cardId
    local nameLabel = display.newLabel(display.SAFE_L + 260, 78, fontWithColor(14, {text = CardUtils.GetCardConfig(checkint(cardId)).name, fontSize = 28, outline = '#583d3d'}))
    display.commonUIParams(nameLabel, {ap = display.LEFT_BOTTOM})
    self:addChild(nameLabel, 2)
    self.nameLabelParams = fontWithColor(14, {fontSize = 28, outline = '#583d3d'})
    if operational and 0 ~= tag then
        CommonUtils.SetCardNameLabelStringById(nameLabel, cardInfo.id, self.nameLabelParams)
    else
        local cardName = friendFish and friendFish.cardName or card.cardName
        if cardName then
            CommonUtils.SetCardNameLabelStringByIdUseSysFont(nameLabel, 0, self.nameLabelParams, cardName)
        else
            CommonUtils.SetCardNameLabelStringById(nameLabel, 0, self.nameLabelParams, CardUtils.GetCardConfig(checkint(cardId)).name)
        end
    end

    if friendFish then
        -- local text = string.fmt(__('_name_派来的钓手'), {_name_ = friendFish.name})
        local text = __('好友派来的钓手')
        local descrLabel = display.newLabel(display.SAFE_L + 260 + display.getLabelContentSize(nameLabel).width + 16, 78, fontWithColor(4,{w = 500 , text = text}))
        display.commonUIParams(descrLabel, {ap = display.LEFT_BOTTOM})
        self:addChild(descrLabel, 2)
    end

    -------------------------------------------------
    -- 好友相关
    local friendLayout = CLayout:create()
    friendLayout:setContentSize(display.size)
    display.commonUIParams(friendLayout, {ap = cc.p(0.5, 0), po = cc.p(display.cx, 0)})
    self:addChild(friendLayout, 10)

    if friendFish then
        local goodsIcon = require('common.GoodNode').new({
            id = friendFish.baitId,
            amount = friendFish.baitNum,
            showAmount = true,
            callBack = function (sender)
                uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = friendFish.baitId, type = 1})
            end
        })
        goodsIcon:setScale(0.8)
        display.commonUIParams(goodsIcon, {po = cc.p(display.SAFE_R - 420, 74)})
        friendLayout:addChild(goodsIcon, 99)
    
        local baitLabel = display.newLabel(goodsIcon:getPositionX(), 16, fontWithColor(4,{text = __('使用的钓饵'), fontSize = 22}))
        friendLayout:addChild(baitLabel, 99)
    end
    local kickoutBtn
    if operational and tag == 0 then
        kickoutBtn = display.newButton(0, 0, {n = RES_DICT.F_BTN_KICK_OUT})
        display.commonUIParams(kickoutBtn, {po = cc.p(
            display.SAFE_R - 110, 66
        )})
        display.commonLabelParams(kickoutBtn, fontWithColor('14', {text = __('遣返')}))
        friendLayout:addChild(kickoutBtn, 2)
    end

    local recallBtn
    if tag == 0 then
        recallBtn = display.newButton(0, 0, {n = RES_DICT.F_BTN_KICK_OUT})
        display.commonUIParams(recallBtn, {po = cc.p(
            display.SAFE_R - 110, 66
        )})
        display.commonLabelParams(recallBtn, fontWithColor('14', {text = __('召回')}))
        friendLayout:addChild(recallBtn, 2)
        recallBtn:setVisible(false)
    end

    -------------------------------------------------
    -- 自身相关
    local selfLayout = CLayout:create()
    selfLayout:setContentSize(display.size)
    display.commonUIParams(selfLayout, {ap = cc.p(0.5, 0), po = cc.p(display.cx, 0)})
    self:addChild(selfLayout, 10)

    local switchBtn
    if operational and tag ~= 0 then
        -- 喂食
        local feedButton = display.newButton(display.SAFE_R - 462, 60,{
            n = RES_DICT.F_BTN_FEED
        })
        selfLayout:addChild(feedButton,2)
        local textLabel = display.newButton(feedButton:getContentSize().width * 0.5, 16,{
            n = RES_DICT.F_IMG_NAME,enable = false
        })
        display.commonLabelParams(textLabel, fontWithColor(14,{text = __('喂食'),color = 'ffffff'}))
        feedButton:addChild(textLabel)
        feedButton:setOnClickScriptHandler(function(sender)
            --显示喂食页面
            PlayAudioByClickNormal()
            local node = self:getChildByTag(8888)
            if node then node:removeFromParent() end
            local foodView = FishermanFeedFoodLayer.new({id = cardInfo.id, tag = self.tag})
            display.commonUIParams(foodView, {ap = display.CENTER_BOTTOM, po = cc.p(feedButton:getPositionX(), 140)})
            foodView:setTag(8888)
            self:addChild(foodView, 20)
        end)
    
        -- 进入冰场
        local iceButton = display.newButton(display.SAFE_R - 304, 66,{
            n = RES_DICT.F_BTN_ICE_ROOM
        })
        selfLayout:addChild(iceButton,2)
        local textLabel = display.newButton(iceButton:getContentSize().width * 0.5, 16,{
            n = RES_DICT.F_IMG_NAME,enable = false
        })
        display.commonLabelParams(textLabel, fontWithColor(14,{text = __('进入冰场'),color = 'ffffff'}))
        iceButton:addChild(textLabel)
        iceButton:setOnClickScriptHandler(function(sender)
            --效果页面
            PlayAudioByClickNormal()
            if self.isRequesting then return end
            self.isRequesting = true
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function()
                self.isRequesting = false
            end)))
            if CommonUtils.UnLockModule(RemindTag.ICEROOM, true) then
                shareFacade:DispatchObservers(FISHERMAN_SENT_TO_ICEROOM_EVENT, {playerCardId = cardInfo.id, icePlaceId = 1, fishPlaceId = self.tag})
                shareFacade:UnRegsitMediator(NAME)
            end
        end)
    
        iceButton:setVisible(CommonUtils.GetModuleAvailable(MODULE_SWITCH.ICEROOM))
    
        -- 更换按钮
        switchBtn = display.newButton(0, 0, {n = RES_DICT.F_BTN_KICK_OUT})
        display.commonUIParams(switchBtn, {po = cc.p(
            display.SAFE_R - 110, 66
        )})
        display.commonLabelParams(switchBtn, fontWithColor('14', {text = __('更换')}))
        selfLayout:addChild(switchBtn, 2)

        local descrLabel = display.newLabel(display.SAFE_L + 260 + display.getLabelContentSize(nameLabel).width + 16, 78, fontWithColor(4,{w = 500 ,  text = __('钓手')}))
        display.commonUIParams(descrLabel, {ap = display.LEFT_BOTTOM})
        selfLayout:addChild(descrLabel, 2)
    end
    if operational then
        local warningImg = display.newImageView(RES_DICT.F_IMG_WARNING, display.SAFE_L + 276, 54)
        selfLayout:addChild(warningImg,1)
        
        local text = (tag ~= 0) and __('进入冰场或更换飨灵，已使用的钓饵不会返还。') or __('遣返好友飨灵时，已使用的钓饵不会返还。')
        local descrLabel = display.newLabel(display.SAFE_L + 300, 64, fontWithColor(6,{ w = 500 , hAlign = display.TAL,  text = text, fontSize = 20}))
        display.commonUIParams(descrLabel, {ap = display.LEFT_TOP})
        selfLayout:addChild(descrLabel, 2)
    end

    self.viewData = {
        operaProgressBar    = operaProgressBar,
        vigourLabel         = vigourLabel,
        switchBtn           = switchBtn,
        friendLayout        = friendLayout,
        selfLayout          = selfLayout,
        kickoutBtn          = kickoutBtn,
        recallBtn           = recallBtn,
    }
end

function FishermanFeedView:UpdateVigour(id, vigour)
    self.viewData.vigourLabel:setString(tostring(vigour))
    local maxVigour = app.restaurantMgr:getCardVigourLimit(id)
    self:UpdateFriendValue(maxVigour, vigour)
end

function FishermanFeedView:UpdateFriendValue(maxVigour, vigour)
    self.viewData.vigourLabel:setString(tostring(vigour))
    local ratio = (vigour / maxVigour) * 100
    local operaProgressBar = self.viewData.operaProgressBar
    operaProgressBar:setValue(rangeId(ratio, 100))
    if ratio <= 40 then
        operaProgressBar:setProgressImage(RES_DICT.F_IMG_LEAF_RED)
    elseif ratio <= 60 then
        operaProgressBar:setProgressImage(RES_DICT.F_IMG_LEAF_YELLOW)
    else
        operaProgressBar:setProgressImage(RES_DICT.F_IMG_LEAF_GREEN)
    end
end

return FishermanFeedView
