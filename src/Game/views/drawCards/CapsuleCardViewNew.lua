--[[
抽卡整卡界面（新）
--]]
local CapsuleCardViewNew = class('CapsuleCardViewNew', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.CapsuleCardViewNew'
    node:enableNodeEvents()
    node:setCascadeOpacityEnabled(true)
    node:setName('CapsuleCardViewNew')
	return node
end)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local RES_DICT = {
    BG            = _res('ui/home/capsule/draw_card_bg_new.jpg'),
    POPUP_SPINE   = _spn('effects/capsule/popup'),
    NAME_BG       = _res('ui/home/capsule/draw_card_bg_name.png'),
    NEW_ICON      = _res('ui/home/capsule/draw_card_ico_new.png'),
    BG_TEXT_TIPS  = _res('ui/home/capsule/draw_card_bg_text_tips.png'),
    DESCR_BG      = _res('ui/home/capsule/draw_card_bg_text.png'),
    BACK_BTN      = _res('ui/common/common_btn_back.png'),
    SKIP_BTN      = _res('arts/stage/ui/opera_btn_skip.png'),
}
local function CreateView( self )
	local career = {
		[1] = 'blue',
		[2] = 'red',
		[3] = 'purple',
		[4] = 'green',
	}
	-- 卡牌背景
	local bgImage = RES_DICT.BG
	local bg = display.newImageView(bgImage, display.cx, display.cy, {ap = cc.p(0.5, 0.5)})
	local bgSize = display.size
	local view = display.newLayer(display.cx, display.cy, {ap = cc.p(0.5, 0.5)})
	view:setContentSize(bgSize)
    view:setName('ContainerView')
	view:addChild(bg, -1)
	-- mask
	local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
	mask:setTouchEnabled(true)
	mask:setContentSize(display.size)
	mask:setAnchorPoint(cc.p(0.5, 0.5))
	mask:setPosition(display.center)
	self:addChild(mask, -10)
	-- 火焰背景
	local fireBg = sp.SkeletonAnimation:create(
            RES_DICT.POPUP_SPINE.json,
			RES_DICT.POPUP_SPINE.atlas,
			1)
		fireBg:update(0)
		fireBg:setToSetupPose()
		fireBg:setAnimation(0, 'popup', true)
		fireBg:setPosition(cc.p((display.width-1334)/2, 0))
	view:addChild(fireBg)

	local cardId = self.cardData.cardId or self.cardData.id
	
	-- ur角色替换背景
	local rareIcon = display.newImageView(CardUtils.GetCardQualityTextPathByCardId(cardId), 157 + display.SAFE_L, display.height - 130, {ap = cc.p(0.5, 0.5)})
	view:addChild(rareIcon, 2)
	-- 立绘
	local cardDrawNode = require('common.CardSkinDrawNode').new({confId = self.data.goodsId, coordinateType = COORDINATE_TYPE_CAPSULE})
	cardDrawNode:setScale(1.2)
	cardDrawNode:setAnchorPoint(cc.p(0.21, 0.5))
	cardDrawNode:setPosition(cc.p(bgSize.width * 0.47, bgSize.height / 2))
	cardDrawNode:setFilterName(filter.TYPES.GRAY, 0, 0, 0, 0)
	cardDrawNode:setCascadeColorEnabled(true)
	local winSize = cc.Director:getInstance():getWinSize()
    local renderTexture = cc.RenderTexture:create(bgSize.width, bgSize.height)
    renderTexture:begin()
    cardDrawNode:visit()
    renderTexture:endToLua()
    local cardCopy = display.newImageView(renderTexture:getSprite():getTexture(), 0 , 0,{ap = cc.p(0, 0)})
    cardCopy:setFlippedY(true)
	view:addChild(cardCopy)

	-- 卡牌名称背景
    local nameBg = display.newImageView(RES_DICT.NAME_BG, display.width - 654 - display.SAFE_L, display.height - 60, {ap = cc.p(0, 0.5)})
    nameBg:setCascadeOpacityEnabled(true)
	view:addChild(nameBg, 2)
    
    local imgNew = display.newImageView(RES_DICT.NEW_ICON, -85, 10, {ap = cc.p(0, 0.5)})
    nameBg:addChild(imgNew, 2)


	-- 卡牌名称
	local nameLabel = display.newLabel(display.width - 640 - display.SAFE_L, display.height - 63, {text = self.cardData.name, fontSize = 30, color = '#ffdf89', ap = cc.p(0, 0.5)})
	view:addChild(nameLabel,2)
	-- 适配
	local nameLabelW = display.getLabelContentSize(nameLabel).width
	if nameLabelW > 250 then
		nameLabel:setScale(250/nameLabel:getContentSize().width)
	end
	-- 卡牌定位Label
	local careerIcon = display.newButton( display.width -355 - display.SAFE_L, display.height - 135, {n = _res('ui/home/capsule/card_order_ico_' .. career[checkint(self.cardData.career)] .. '_l.png'), ap = cc.p(0, 0), enable = false})
	view:addChild(careerIcon, 2)
	-- 卡牌分解
	local decomposeBg = display.newImageView(RES_DICT.BG_TEXT_TIPS, display.width - 314 - display.SAFE_L, display.height - 241, {ap = cc.p(0, 0)})
	view:addChild(decomposeBg, 2)
	local decomposeLabel = display.newLabel(28, 73, {text = '', fontSize = 20, color = '#e9ba7c', w = 230, ap = cc.p(0, 1)})
	decomposeBg:addChild(decomposeLabel, 2)
	decomposeBg:setCascadeOpacityEnabled(true)
	decomposeLabel:setCascadeOpacityEnabled(true)
	-- 卡牌描述
	local descrBg = display.newImageView(RES_DICT.DESCR_BG, bgSize.width / 2, 10, {ap = cc.p(0.5, 0)})
	descrBg:setCascadeOpacityEnabled(true)
	view:addChild(descrBg,2)
	self.dialogue = CommonUtils.GetCurrentCvLinesByGroupType(self.data.goodsId, SoundType.TYPE_GET_CARD)
	local descrLabel = display.newLabel(60, 135, {text = self.dialogue, fontSize = 22, color = 'ffffff', ap = cc.p(0, 1), w = 600})
	descrBg:addChild(descrLabel)
    descrLabel:setCascadeOpacityEnabled(true)
	local cv = '???'
	if self.cardData.cv ~= '' then
		cv = CommonUtils.GetCurrentCvAuthorByCardId(cardId)
	end
	local cvLabel = display.newLabel(display.width - 500 - display.SAFE_L, display.height - 118, {text = cv , fontSize = 20, color = '#fca702', ap = cc.p(0, 0)})
	view:addChild(cvLabel,3)
	-- 分享
	local shareLayout = CLayout:create(cc.size(144, 120))
	shareLayout:setPosition(cc.p(74 + display.SAFE_L, 80))
	view:addChild(shareLayout, 10)
    local shareBtn = require('common.CommonShareButton').new({})
    display.commonUIParams(shareBtn, {po = cc.p(
        72, 65)})
	shareLayout:addChild(shareBtn, 10)
	-- 确认按钮
	local okBtn = display.newButton(30 + display.SAFE_L, display.height - 18, {n = RES_DICT.BACK_BTN, ap = cc.p(0, 1)})
	view:addChild(okBtn, 5)
    okBtn:setName('OKBTN')
    -- 跳过按钮
    local skipBtn = display.newButton(display.width - display.SAFE_L, 75, {n = RES_DICT.SKIP_BTN, ap = cc.p(1, 0.5), scale9 = ture, size = cc.size(186, 62), capInsets = cc.rect(131, 31, 30, 31)})
    view:addChild(skipBtn, 5)
    local skipLabel = display.newLabel(skipBtn:getContentSize().width - 50, skipBtn:getContentSize().height / 2, {text = __('跳过'), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#4e2e1e', outlineSize = 2})
    skipBtn:addChild(skipLabel, 1)
	return {
		view           = view,
		bgSize         = bgSize,
		rareIcon       = rareIcon,
		nameBg         = nameBg,
		nameLabel      = nameLabel,
		careerIcon     = careerIcon,
		decomposeBg    = decomposeBg,
		descrBg        = descrBg,
		descrLabel     = descrLabel,
		cvLabel        = cvLabel,
		shareLayout    = shareLayout,
		okBtn          = okBtn,
		cardCopy       = cardCopy,
		fireBg         = fireBg,
		bg             = bg,
		decomposeLabel = decomposeLabel,
		imgNew 		   = imgNew,
        shareBtn       = shareBtn,
        skipBtn        = skipBtn,
 	}
end
--[[
@params data table{
    goodsId int 物品id
    num     int 物品数量
}
@params skipAnimation  bool 是否跳过动画
@params hideNewIcon    bool 是否隐藏new图标
--]]
function CapsuleCardViewNew:ctor( ... )
	self.args = unpack({...}) or {}
	self.data = self.args.data
	self.changeFragment = self.args.hideNewIcon ~= nil and self.args.hideNewIcon or false
	self.dialogue = nil
	self.isSkip = false
    self.canBack = false
    self.skipAnimation = self.args.skipAnimation or false
	if tostring(CommonUtils.GetGoodTypeById(self.data.goodsId)) == GoodsType.TYPE_CARD_FRAGMENT then
		local fragmentData = CommonUtils.GetConfig('goods', 'goods', self.data.goodsId)
		self.changeFragment = true
		self.data.goodsId = fragmentData.cardId
	end
	self.cardData = CommonUtils.GetConfig('cards', 'card', self.data.goodsId)
	self.viewData_ = CreateView(self)
	self:addChild(self.viewData_.view,1)
	-- 注册监听事件
	self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
    -- 按钮绑定
    self.viewData_.okBtn:setOnClickScriptHandler(handler(self, self.OkButtonCallback))
    self.viewData_.shareBtn:setOnClickScriptHandler(handler(self, self.ShareButtonCallback))
    self.viewData_.skipBtn:setOnClickScriptHandler(handler(self, self.SkipButtonCallback))
    if self.skipAnimation then
        self.canBack = true
        self.viewData_.skipBtn:setVisible(false)
        self:SkipShowAnimation()
    else
        self:EnterAction(self.viewData_)
    end
end
--[[
展示动画
--]]
function CapsuleCardViewNew:EnterAction(viewdata)
    transition.execute(self.viewData_.view, nil, {delay = 0.5, complete = function()
        self.canBack = true
    end})
    -- 是否隐藏分解栏
	viewdata.rareIcon:setVisible(false)
	viewdata.nameBg:setOpacity(0)
	viewdata.imgNew:setOpacity(0)
	viewdata.nameLabel:setVisible(false)
	viewdata.careerIcon:setVisible(false)
	viewdata.decomposeBg:setOpacity(0)
	viewdata.decomposeLabel:setOpacity(0)
	viewdata.descrLabel:setVisible(false)
	viewdata.fireBg:setOpacity(0)
	viewdata.bg:setOpacity(0)
	viewdata.descrBg:setOpacity(0)
	viewdata.cvLabel:setOpacity(0)
	viewdata.shareLayout:setOpacity(0)
	viewdata.shareLayout:setVisible(false)
	viewdata.okBtn:setOpacity(0)
	viewdata.okBtn:setVisible(false)
	viewdata.cardCopy:setOpacity(0)
	local cardDrawNode = require('common.CardSkinDrawNode').new({confId = self.data.goodsId, coordinateType = COORDINATE_TYPE_CAPSULE})
	cardDrawNode:setScale(1.2)
	cardDrawNode:setAnchorPoint(cc.p(0.26, 0.5))
	cardDrawNode:setTag(1001)
	cardDrawNode:setPosition(cc.p(viewdata.bgSize.width * 0.52, viewdata.bgSize.height / 2))
	local function callback1 ()
		viewdata.cardCopy:removeFromParent()
		viewdata.view:addChild(cardDrawNode)
	end
	local function callback2 ()
		viewdata.rareIcon:setScale(7)
		viewdata.rareIcon:setVisible(true)
	end
	local function callback3 ()
		viewdata.careerIcon:setScale(2)
		viewdata.careerIcon:setVisible(true)
	end
	local function callback4 ()
		viewdata.nameLabel:setVisible(true)
	end
	local function callback5 ()
		-- 播放卡牌语音
		if self:PlayCardVoice() then
			viewdata.descrLabel:setVisible(true)
		end
	end
	local function callback6 ()
		PlayAudioClip(AUDIOS.UI.ui_card_slide.id)
		if tonumber(self.cardData.qualityId) == 3 then -- 卡牌为SR
			self:CreateCot(display.center, 'chouka_hou')
		elseif tonumber(self.cardData.qualityId) == 4 then -- 卡牌为UR
			self:CreateCot(display.center, 'chouka_qian')
			self:CreateCot(display.center, 'chouka_hou')
		end

		local cardShadowF = require('common.CardSkinDrawNode').new({confId = self.data.goodsId, coordinateType = COORDINATE_TYPE_CAPSULE})
		cardShadowF:setScale(1.2)
		cardShadowF:setAnchorPoint(cc.p(0.26, 0.5))
		cardShadowF:setTag(1002)
		cardShadowF:setPosition(cc.p(viewdata.bgSize.width * 0.55, viewdata.bgSize.height / 2))
		local cardShadowS = require('common.CardSkinDrawNode').new({confId = self.data.goodsId, coordinateType = COORDINATE_TYPE_CAPSULE})
		cardShadowS:setScale(1.2)
		cardShadowS:setAnchorPoint(cc.p(0.26, 0.5))
		cardShadowS:setTag(1003)
		cardShadowS:setPosition(cc.p(viewdata.bgSize.width * 0.55, viewdata.bgSize.height / 2))
		viewdata.view:addChild(cardShadowS)
		viewdata.view:addChild(cardShadowF)
		cardShadowF:runAction(
			cc.Spawn:create(
				cc.ScaleTo:create(0.3, 2.1),
				cc.FadeOut:create(0.3)
			)
		)
		cardShadowS:runAction(
			cc.Sequence:create(
				cc.DelayTime:create(0.1),
				cc.Spawn:create(
					cc.ScaleTo:create(0.3, 1.8),
					cc.FadeOut:create(0.3)
				)
			)
		)

	end
	local function callback7 ()
		if self.changeFragment == true then
			viewdata.decomposeLabel:setString(string.fmt(__('此卡已获得，自动转换为_num_个碎片放入背包'), {['_num_'] = self.data.num}))
			viewdata.decomposeBg:runAction(cc.FadeIn:create(0.3))
			viewdata.decomposeLabel:runAction(cc.FadeIn:create(0.3))
		end
	end
	self:runAction(cc.Sequence:create(
		cc.TargetedAction:create(viewdata.cardCopy, cc.FadeTo:create(1, 150)),
		cc.Spawn:create(
			cc.TargetedAction:create(viewdata.bg, cc.FadeIn:create(0.3)),
			cc.TargetedAction:create(viewdata.fireBg, cc.FadeIn:create(0.3))
		),
		cc.CallFunc:create(callback2),
		cc.TargetedAction:create(viewdata.rareIcon, cc.ScaleTo:create(0.1, 1)),
		cc.CallFunc:create(callback1),
		cc.CallFunc:create(callback6),
		cc.TargetedAction:create(cardDrawNode, cc.ScaleTo:create(0.2, 1)),
		cc.Spawn:create(
			cc.TargetedAction:create(viewdata.nameBg, cc.FadeIn:create(0.5)),
			cc.CallFunc:create(function ()
				if self.changeFragment == false then
					viewdata.imgNew:setOpacity(255)
				end
			end),
			cc.TargetedAction:create(viewdata.nameBg, cc.MoveBy:create(0.3, cc.p(300, 0))),
			cc.TargetedAction:create(viewdata.nameLabel, cc.Sequence:create(
				cc.MoveBy:create(0.5, cc.p(300, 0)),
				cc.Spawn:create(
					cc.Sequence:create(
						cc.DelayTime:create(0.15),
						cc.CallFunc:create(callback4)),
						cc.CallFunc:create(callback3),
						cc.TargetedAction:create(viewdata.careerIcon, cc.ScaleTo:create(0.1, 1)),
						cc.Spawn:create(
							cc.TargetedAction:create(viewdata.cvLabel, cc.FadeIn:create(0.2)),
							cc.TargetedAction:create(viewdata.cvLabel, cc.MoveBy:create(0.2, cc.p(200, 0)))
						)
					)
				)
			)
		),

		cc.Spawn:create(
			cc.Sequence:create(
				cc.TargetedAction:create(viewdata.descrBg, cc.FadeIn:create(0.3)),
				cc.Spawn:create(
					cc.Sequence:create(
						cc.DelayTime:create(0.2),
						cc.CallFunc:create(callback5)
					),
					cc.TargetedAction:create(viewdata.descrLabel, TypewriterAction:create(2))
				)
			)
        ),
        cc.CallFunc:create(function () 
            self.isSkip = true
        end),
		cc.Spawn:create(
            cc.TargetedAction:create(viewdata.shareLayout, cc.Show:create()),
			cc.TargetedAction:create(viewdata.okBtn, cc.Show:create()),
            cc.TargetedAction:create(viewdata.shareLayout, cc.FadeIn:create(0.3)),
			cc.TargetedAction:create(viewdata.okBtn, cc.FadeIn:create(0.3))
		),
		cc.CallFunc:create(callback7)
	)):setTag(123)
end

--[[
添加点击的响应动画
--]]
function CapsuleCardViewNew:CreateCot( position, type )

	local cotAnimation = sp.SkeletonAnimation:create(
   		'effects/capsule/capsule.json',
   		'effects/capsule/capsule.atlas',
   		1)
   	cotAnimation:setAnimation(0, type, false)
   	cotAnimation:setPosition(position)
   	self.viewData_.view:addChild(cotAnimation, 10)
   	-- 结束后移除
   	cotAnimation:registerSpineEventHandler(function (event)
   		cotAnimation:runAction(cc.RemoveSelf:create())
   	end, sp.EventType.ANIMATION_END)
end

function CapsuleCardViewNew:onTouchBegan_(touch, event)
	if self.changeFragment == true and not self.isSkip then -- 判断是否为新卡，如果不是可跳过动画
		return true
	end
end
function CapsuleCardViewNew:onTouchMoved_(touch, event)
end
function CapsuleCardViewNew:onTouchEnded_(touch, event)
    self:SkipShowAnimation()
end
function CapsuleCardViewNew:SkipShowAnimation()
    self.isSkip = true
    local viewdata = self.viewData_
	if self:getActionByTag(123) then
		self:stopActionByTag(123)
	end
	viewdata.view:setOpacity(255)
	viewdata.rareIcon:setVisible(true)
	viewdata.rareIcon:setScale(1)
	viewdata.fireBg:setOpacity(255)
	viewdata.nameBg:setOpacity(255)
	viewdata.nameBg:setPosition(cc.p(display.width - 354 - display.SAFE_L, display.height - 60))
	viewdata.nameLabel:setVisible(true)
	viewdata.nameLabel:setPosition(cc.p(display.width - 340 - display.SAFE_L, display.height - 63))
	viewdata.careerIcon:setVisible(true)
	viewdata.careerIcon:setScale(1)
	viewdata.descrLabel:setVisible(true)
	viewdata.descrLabel:setString(self.dialogue)
	viewdata.fireBg:setOpacity(255)
	viewdata.bg:setOpacity(255)
	viewdata.descrBg:setOpacity(255)
	viewdata.cvLabel:setOpacity(255)
	viewdata.cvLabel:setPosition(cc.p(display.width - 300 - display.SAFE_L, display.height - 118))
	viewdata.okBtn:setOpacity(255)
	viewdata.okBtn:setVisible(true)
	-- 没有这张卡不显示分享按钮
	local showShareLayout = true
	if self.skipAnimation then
		if not next(gameMgr:GetCardDataByCardId(self.cardData.id) or {}) then
			showShareLayout = false
		end
	end
	if showShareLayout then
		viewdata.shareLayout:setOpacity(255)
		viewdata.shareLayout:setVisible(true)
	else
		viewdata.shareLayout:setVisible(false)
	end
	if self.changeFragment == false then
		viewdata.imgNew:setOpacity(255)
		viewdata.decomposeBg:setVisible(false)
	else
		viewdata.imgNew:setOpacity(0)
		viewdata.decomposeBg:setVisible(true)
	end
	if not tolua.isnull(viewdata.cardCopy) then
		viewdata.cardCopy:runAction(cc.RemoveSelf:create())
	end
	if viewdata.view:getChildByTag(1001) then
		viewdata.view:getChildByTag(1001):runAction(cc.RemoveSelf:create())
	end
	if viewdata.view:getChildByTag(1002) then
		viewdata.view:getChildByTag(1002):runAction(cc.RemoveSelf:create())
	end
	if viewdata.view:getChildByTag(1003) then
		viewdata.view:getChildByTag(1003):runAction(cc.RemoveSelf:create())
	end

	viewdata.decomposeLabel:setString(string.fmt(__('此卡已获得，自动转换为_num_个碎片放入背包'), {['_num_'] = self.data.num}))
	-- viewdata.decomposeBg:runAction(cc.FadeIn:create(0.3))
	-- viewdata.decomposeLabel:runAction(cc.FadeIn:create(0.3))
	viewdata.decomposeBg:setOpacity(255)
	viewdata.decomposeLabel:setOpacity(255)

	local cardDrawNode = require('common.CardSkinDrawNode').new({confId = self.data.goodsId, coordinateType = COORDINATE_TYPE_CAPSULE})
	cardDrawNode:setScale(1)
	cardDrawNode:setAnchorPoint(cc.p(0.26, 0.5))
	cardDrawNode:setPosition(cc.p(viewdata.bgSize.width * 0.52, viewdata.bgSize.height / 2))
    viewdata.view:addChild(cardDrawNode)
end
function CapsuleCardViewNew:onEnter()
	self.viewData_.view:setOpacity(0)
	local action = cc.FadeIn:create(1)
    self.viewData_.view:runAction( action )

end
---------------------------------------
----------------点击回调----------------
--[[
分享按钮回调
--]]
function CapsuleCardViewNew:ShareButtonCallback( sender )
	PlayAudioByClickNormal()
	local shareLayer = require('Game.views.share.CapsuleShareLayer').new({
		cardId = self.data.goodsId, clickStr = '', rotate = ''
	})
	shareLayer:setAnchorPoint(cc.p(0.5, 0.5))
	shareLayer:setTag(5361)
	shareLayer:setPosition(cc.p(display.cx, display.cy))
	uiMgr:GetCurrentScene():AddDialog(shareLayer)
end
--[[
确定按钮点击回调
--]]
function CapsuleCardViewNew:OkButtonCallback( sender )
    if self.canBack then
        sender:setEnabled(false)
        self.viewData_.skipBtn:setEnabled(false)
        PlayAudioByClickNormal()
        -- 停止角色语音
        self:StopCardVoice()
		GuideUtils.DispatchStepEvent()
		self:BackAction()
        -- local action = cc.Sequence:create(cc.FadeOut:create(0.3), cc.CallFunc:create(handler(self, self.BackAction)))
        -- self:runAction( action )
    end
end
--[[
跳过按钮点击回调
--]]
function CapsuleCardViewNew:SkipButtonCallback( sender )
	AppFacade.GetInstance():DispatchObservers(CAPSULE_ANIMATION_SKIP)
	self:runAction(cc.RemoveSelf:create())
end
----------------点击回调----------------
---------------------------------------
--[[
停止当前卡牌语音
--]]
function CapsuleCardViewNew:PlayCardVoice()
	local isPlaying = false
	local voiceLine = CardUtils.GetVoiceLinesConfigByCardId(self.data.goodsId)
	if voiceLine then
		CommonUtils.PlayCardSoundByCardId(self.data.goodsId, SoundType.TYPE_GET_CARD)
		isPlaying = true
	end
	return isPlaying
end
--[[
停止当前卡牌语音
--]]
function CapsuleCardViewNew:StopCardVoice()
	local voiceLine = CardUtils.GetVoiceLinesConfigByCardId(self.data.goodsId)
	if voiceLine then
		app.audioMgr:StopAudioClip(voiceLine[SoundType.TYPE_GET_CARD].roleId)
	end
end
function CapsuleCardViewNew:BackAction()
    if not self.skipAnimation then
        AppFacade.GetInstance():DispatchObservers(CAPSULE_CARDVIEW_BACK)
    end
    app.uiMgr:GetCurrentScene():RemoveDialog(self)
end
function CapsuleCardViewNew:onCleanup()
	if not tolua.isnull(self.touchListener_) then
		local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
		eventDispatcher:removeEventListener(self.touchListener_)
	end
end
return CapsuleCardViewNew
