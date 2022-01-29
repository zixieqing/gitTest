--[[
召唤物 view
--]]
local MonsterView = __Require('battle.objectView.MonsterView')
local BeckonView = class('BeckonView', MonsterView)
---------------------------------------------------
-- init view begin --
---------------------------------------------------
--[[
初始化视图
--]]
function BeckonView:initView()
	MonsterView.initView(self)
	
	self:initTouch()
end
--[[
@override
创建ui
--]]
function BeckonView:InitUI()
	-- 处理大小
	local bgSize = cc.size(0, 0)
	self:setContentSize(bgSize)
	self:setAnchorPoint(cc.p(0.5, 0))
	-- self:setBackgroundColor(cc.c4b(255, 0, 0, 255))

	-- 角色阴影
	local avatarShadow = display.newNSprite(_res('ui/battle/battle_role_shadow.png'), bgSize.width * 0.5, 0)
	self:addChild(avatarShadow, 1)
	avatarShadow:setScale(0.5 * (self:getAvatarStaticViewBox().width / avatarShadow:getContentSize().width))

	-- hp bar
	local hpBar = CProgressBar:create(_res('ui/battle/battle_monster_blood_bg_1.png'))
    hpBar:setBackgroundImage(_res('ui/battle/battle_monster_blood_bg_2.png'))
    hpBar:setDirection(eProgressBarDirectionLeftToRight)
    hpBar:setPosition(cc.p(bgSize.width * 0.5, self:getAvatarStaticViewBox().height + 15))
    self:addChild(hpBar, 10)

    -- energy bar
	local energyBar = CProgressBar:create(_res('ui/battle/battle_blood_bg_5.png'))
    energyBar:setDirection(eProgressBarDirectionLeftToRight)
    energyBar:setPosition(cc.p(hpBar:getPositionX(), hpBar:getPositionY()))
    self:addChild(energyBar, 11)
    energyBar:setVisible(false)

    local remindLabel = display.newLabel(0, 20,
		{text = __('戳我!'), fontSize = 34, color = fontWithColor('BC').color, ttf = true, font = TTF_GAME_FONT})
	remindLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	self:addChild(remindLabel, 20)
	remindLabel:setScale(0.9)

	local remindActionSeq = cc.RepeatForever:create(cc.Sequence:create(
		cc.ScaleTo:create(0.05, 1.1),
		cc.ScaleTo:create(0.05, 0.9)))
	remindLabel:runAction(remindActionSeq)

	self.viewData.hpBar = hpBar
	self.viewData.energyBar = energyBar
	self.viewData.avatarShadow = avatarShadow
	self.viewData.remindLabel = remindLabel
	self.viewData.clearTargetMark = nil
	self.viewData.clearTargetShadow = nil

	self.viewData.hpBar:setVisible(false)
end
function BeckonView:initTouch()
	self.touchedCallback = nil
	self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:setSwallowTouches(false)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchCanceled_), cc.Handler.EVENT_TOUCH_CANCELLED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
end
---------------------------------------------------
-- init view end --
---------------------------------------------------

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function BeckonView:onTouchBegan_(touch, event)
	if BMediator:IsBattleTouchEnable() and self:isTouchedSelf(touch:getLocation()) then
		if self.touchedCallback then
			self.touchedCallback()
		end
		return true
	else
		return false
	end
end
function BeckonView:onTouchMoved_(touch, event)

end
function BeckonView:onTouchEnded_(touch, event)

end
function BeckonView:onTouchCanceled_( touch, event )
	print('here touch canceled by some unknown reason')
end
--[[
是否触摸到qte物体
@params touchPos cc.p 触摸位置
@return result bool 
--]]
function BeckonView:isTouchedSelf(touchPos)
	local boundingBox = self:getAvatarStaticViewBox()
	local fixedPos = cc.CSceneManager:getInstance():getRunningScene():convertToNodeSpace(
		self:convertToWorldSpace(cc.p(boundingBox.x, boundingBox.y)))
	local rect = cc.rect(fixedPos.x, fixedPos.y, boundingBox.width, boundingBox.height)
	if cc.rectContainsPoint(rect, touchPos) then
		return true
	else
		return false
	end
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
设置触摸回调
@params cb function 触摸成功回调
--]]
function BeckonView:setTouchedSelfCallback(cb)
	self.touchedCallback = cb
end
---------------------------------------------------
-- logic end --
---------------------------------------------------
--[[
@override
杀死该单位 隐藏血条能量条阴影
--]]
function BeckonView:killSelf()
	MonsterView.killSelf(self)
	self.viewData.remindLabel:setVisible(false)
end
--[[
@override
view死亡
--]]
function BeckonView:dieEnd()
	if self.touchListener_ then
		self:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end
	MonsterView.dieEnd(self)
end
--[[
@override
销毁view
--]]
function BeckonView:destroy()
	if self.touchListener_ then
		self:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end
	MonsterView.destroy(self)
end


return BeckonView