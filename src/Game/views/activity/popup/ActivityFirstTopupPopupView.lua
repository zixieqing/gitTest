--[[
活动弹出页 首充 view
--]]
local ActivityFirstTopupPopupView = class('ActivityFirstTopupPopupView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.ActivityFirstTopupPopupView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG_FRAME = _res('ui/common/common_rank_bg.png'),
    BACK_BTN = _res('ui/home/activity/activity_open_btn_quit.png')
}
function ActivityFirstTopupPopupView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function ActivityFirstTopupPopupView:InitUI()
    local function CreateView()
        local size = cc.size(1035, 637)
        local view = CLayout:create(size)
        -- 背景
        local bgFrame = display.newImageView(RES_DICT.BG_FRAME, size.width/2, size.height/2)
        view:addChild(bgFrame, 1) 
        local bg = display.newImageView(_res('ui/home/activity/activity_firstcharge_bg.png'), size.width/2, size.height/2)
        view:addChild(bg, 1)
        -- 卡牌立绘
        local cardId = 200050
        local newCardId = app.activityMgr:getFirstPaymentCard()
        if Platform.id == 4001 or Platform.id == 4002 then -- 台湾
            cardId = 200031
        end
        local cardNode = display.newImageView(_res(string.format('ui/home/activity/activity_firstcharge_draw_%d.png', cardId)), size.width/2, size.height/2)
    
        view:addChild(cardNode, 3)
        -- 切换按钮
        local switchBtn = display.newButton(73, 73, {n = _res('ui/home/activity/activity_firstcharge_btn_qban_default.png')})
        view:addChild(switchBtn, 10)
        local frame = display.newImageView(_res('ui/home/activity/activity_firstcharge_frame.png'), size.width/2, size.height/2)
        view:addChild(frame, 10)
        local title = display.newImageView(_res('ui/home/activity/activity_firstcharge_title.png'), 754, 554)
        view:addChild(title, 10)
        local descrLabel = display.newLabel(864, 487, {text = __('首次充值任意金额'), fontSize = 24, color = '#fdefcb', ttf = true, font = TTF_GAME_FONT, outline = '#8c3501', outlineSize = 1})
        view:addChild(descrLabel, 10)
        local giftIcon = display.newImageView(_res('ui/home/activity/activity_firstcharge_ico_give.png'), 570, 405)
        view:addChild(giftIcon, 10)
        local qualityIcon = display.newImageView(CardUtils.GetCardQualityTextPathByCardId(newCardId), 660, 390)
        qualityIcon:setScale(0.5)
        view:addChild(qualityIcon, 10)
        local nameLabel = display.newLabel(734, 390, {text = __('飨灵'), fontSize = 34, color = '#fff1cd', ttf = true, font = TTF_GAME_FONT, outline = '#573412', outlineSize = 2}) 
        view:addChild(nameLabel, 10)
        local nameIcon = display.newImageView(_res('ui/home/activity/activity_firstcharge_card_name.png'), 880, 398)
        view:addChild(nameIcon, 10)
        local light = display.newImageView(_res('ui/common/common_light.png'), 748, 266)
        light:setScale(0.5)
        view:addChild(light, 5)
        local goodsBg = display.newImageView(_res('ui/home/activity/activity_firstcharge_prop_bg.png'), 760, 264)
        view:addChild(goodsBg, 6)
        for i, v in ipairs(app.gameMgr:GetUserInfo().firstPayRewards) do
            local goodsIcon = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true, highlight = v.highlight})
            goodsIcon:setPosition(cc.p(603 + (i-1)*104, 264))
            goodsIcon:setScale(0.9)
            view:addChild(goodsIcon, 10)
            display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
                app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
            end})
        end
        local qAvatar = AssetsUtils.GetCardSpineNode({confId = newCardId})
        qAvatar:update(0)
        qAvatar:setToSetupPose()
        qAvatar:setAnimation(0, 'run', true)
        qAvatar:setPosition(cc.p(314, 140))
        view:addChild(qAvatar, 10)
        qAvatar:setScale(0.6)
        qAvatar:setVisible(false)
    
        local switchActionBtn = display.newButton(320, size.height/2 - 50, {n = ''})
        switchActionBtn:setContentSize(cc.size(300, 300))
        view:addChild(switchActionBtn, 10)
        switchActionBtn:setVisible(false)
    
        local jumpBtn = display.newButton(760, 102, {n = _res('ui/common/common_btn_big_orange.png')})
        display.commonLabelParams(jumpBtn, fontWithColor(14, {text = __('前往充值')}))
        view:addChild(jumpBtn, 10)
        local backBtn = display.newButton(size.width - 20, size.height - 20, {n = RES_DICT.BACK_BTN})
        view:addChild(backBtn, 10)
        -- 新的判断逻辑
        local bgPath = _res(string.format('ui/home/activity/activity_firstcharge_draw_%d.png', newCardId))
        if utils.isExistent(_res(bgPath)) then
            cardNode:setTexture(bgPath)
        end
        local namePath = _res(string.format('ui/home/activity/activity_firstcharge_card_name_%d.png', newCardId))
        if utils.isExistent(_res(namePath)) then
            nameIcon:setTexture(namePath)
        end
        local btnPath = _res(string.format('ui/home/activity/activity_firstcharge_btn_qban_default_%d.png', newCardId))
        if utils.isExistent(_res(btnPath)) then
            switchBtn:setSelectedImage(btnPath)
            switchBtn:setNormalImage(btnPath)
        end
        return {
            view 			 = view,
            switchBtn        = switchBtn,
            jumpBtn          = jumpBtn,
            qAvatar 	 	 = qAvatar,
            cardNode         = cardNode,
            switchActionBtn  = switchActionBtn,
            backBtn          = backBtn,
        }
    end
    xTry(function ( )
        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
        eaterLayer:setContentSize(display.size)
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setPosition(utils.getLocalCenter(self))
        self.eaterLayer = eaterLayer
        self:addChild(eaterLayer, -1)
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
获取viewData
--]]
function ActivityFirstTopupPopupView:GetViewData()
    return self.viewData
end
--[[
进入动画
--]]
function ActivityFirstTopupPopupView:EnterAction()
    local viewData = self:GetViewData()
	viewData.view:setScale(0.8)
	viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackOut:create(
				cc.ScaleTo:create(0.25, 1)
			)
		)
	)
end
return ActivityFirstTopupPopupView