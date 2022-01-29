--[[
战斗物体附加物qte基类
@params table {
	skillId int 技能id,
	ownerTag int 拥有者tag,
	casterTag int 施法者tag,
	maxTouch int 最高触摸次数
	qteBuffs table qte buff信息{
		qteTapTime int qte点击次数
	},
}
--]]
local BaseAttachObj = class('BaseAttachObj')
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
constructor
--]]
function BaseAttachObj:ctor( ... )
	self.args = unpack({...}) or {}

	self.skillId = self.args.skillId
	if not self.skillId then print('##### \n!!!waring!!! -> qte buff must have skillId \n #####') end
	self.qteBuffs = self.args.qteBuffs
	self.maxTouch = self.args.maxTouch
	self.touchPace = 0
	self.paceAmount = 3
	self.touchCounter = 0
	self.touchedAttachObj = false

	self:init()
end
--[[
init
--]]
function BaseAttachObj:init()
	self:initValue()
	self:initView()
	self:initTouch()
end
--[[
init value
--]]
function BaseAttachObj:initValue()
	
end
--[[
init view
--]]
function BaseAttachObj:initView()
	
	local function CreateView()

		local qteView = display.newNSprite(_res('battle/effect/bing0.png'), 0, 0)
		local bgSize = qteView:getContentSize()
		local view = display.newLayer(0, 0, {ap = cc.p(0.5, 0), size = bgSize})
		display.commonUIParams(qteView, {ap = cc.p(0.5, 0), po = cc.p(bgSize.width * 0.5, -25)})
		view:addChild(qteView)
		-- view:setBackgroundColor(cc.c4b(23, 67, 128, 128))

		local remindLabel = display.newLabel(bgSize.width * 0.5, bgSize.height * 0.6,{text = __('戳我!'), fontSize = 34, color = fontWithColor('BC').color,ttf = true, font = TTF_GAME_FONT})
		remindLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		view:addChild(remindLabel, 20)
		remindLabel:setScale(0.9)

		local remindActionSeq = cc.RepeatForever:create(cc.Sequence:create(
			cc.ScaleTo:create(0.05, 1.1),
			cc.ScaleTo:create(0.05, 0.9)))
		remindLabel:runAction(remindActionSeq)
		
		return {
			view = view,
			qteView = qteView,
		}
	end

	xTry(function ()	
		self.viewData = CreateView()
	end, __G__TRACKBACK__)
end
--[[
init touch
--]]
function BaseAttachObj:initTouch()
    self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:setSwallowTouches(false)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchCanceled_), cc.Handler.EVENT_TOUCH_CANCELLED)
    self:getViewComponent():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self:getViewComponent())
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
获取qte物体view node
--]]
function BaseAttachObj:getViewComponent()
	return self.viewData.view
end
--[[
获取对应的技能id
--]]
function BaseAttachObj:getSkillId()
	return self.skillId
end
--[[
刷新效果
@params qteBuffsInfo {
	skillId int 技能id,
	ownerTag int 拥有者tag,
	casterTag int 施法者tag,
	maxTouch int 最高触摸次数
	qteBuffs table qte buff信息{
		qteTapTime int qte点击次数
	},
}
--]]
function BaseAttachObj:refreshQTEBuffs(qteBuffsInfo)
	self.qteBuffs = qteBuffsInfo.qteBuffs
	-- 重置touch次数
	self.touchCounter = 0
	self.touchPace = 0
	self.viewData.qteView:setTexture(_res('battle/effect/bing' .. self.touchPace .. '.png'))
end
--[[
移除单个buff的qte效果
@params btype ConfigBuffType
--]]
function BaseAttachObj:removeQTEBuff(btype)
	local qteBuffInfo = nil
	local needDie = false
	for i = #self.qteBuffs, 1, -1 do
		qteBuffInfo = self.qteBuffs[i]
		if checkint(qteBuffInfo.btype) == checkint(btype) then
			-- 移除qte buff
			table.remove(self.qteBuffs, i)
			if 0 == #self.qteBuffs then
				needDie = true
			end
			break
		end
	end

	if needDie then
		self:die()
		-- 移除obj缓存的qte buff指针
		local owner = BMediator:IsObjAliveByTag(self.args.ownerTag)
		if owner then
			owner:removeQTE(self.skillId)
		end
	end
end
--[[
销毁此qte obj
--]]
function BaseAttachObj:die()
	self:getViewComponent():setVisible(false)
	
	self:destory()
end
--[[
摧毁此qte obj
--]]
function BaseAttachObj:destory()
	self:getViewComponent():performWithDelay(
		function ()
			-- 移除触摸监听
			if self.touchListener_ then
				self:getViewComponent():getEventDispatcher():removeEventListener(self.touchListener_)
				self.touchListener_ = nil
			end

			self:getViewComponent():removeFromParent()
		end,
		(2 * cc.Director:getInstance():getAnimationInterval())
	)
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function BaseAttachObj:onTouchBegan_(touch, event)
	if BMediator:IsBattleTouchEnable() and self:getViewComponent():isVisible() then		
		return true
	else
		return false
	end
end
function BaseAttachObj:onTouchMoved_(touch, event)

end
function BaseAttachObj:onTouchEnded_(touch, event)
	if self:isTouchedAttachObj(touch:getLocation()) then
		self.touchCounter = self.touchCounter + 1
		local shouldRemoveBuff = self:checkTouchCounter(self.touchCounter)
		if shouldRemoveBuff then
			-- 播放冰裂音效
			PlayBattleEffects(AUDIOS.BATTLE.ty_beattack_binlie.id)
			-- 移除obj 身上的缓存的buff指针
			local owner = BMediator:IsObjAliveByTag(self.args.ownerTag)
			if owner then
				local buff = owner:findBuff(self.skillId, shouldRemoveBuff)
				if buff then
					buff:OnRecoverEffectEnter()
				end
			end
		end
	end
end
function BaseAttachObj:onTouchCanceled_( touch, event )
	print('here touch canceled by some unknown reason')
end
--[[
检查触摸
@params touchCounter int 触摸模型成功的次数
@return btype ConfigBuffType 解除的qte buff key
--]]
function BaseAttachObj:checkTouchCounter( touchCounter )
	-- 检测pace 刷新qte view
	self:refreshQTEViewState(touchCounter)

	for i = #self.qteBuffs, 1, -1 do
		if touchCounter >= self.qteBuffs[i].qteTapTime then
			return self.qteBuffs[i].btype
		end
	end
	-- print('##### \n!!!waring!!! -> cannot find qteBuff \n #####')
	return nil
end
--[[
触摸反馈到qte展示
@params touchCounter int 触摸模型的触摸数
--]]
function BaseAttachObj:refreshQTEViewState(touchCounter)
	if touchCounter == math.ceil(self.maxTouch / self.paceAmount * (self.touchPace + 1)) then
		self.touchPace = math.min(self.touchPace + 1, self.paceAmount)
		self.viewData.qteView:setTexture(_res('battle/effect/bing' .. self.touchPace .. '.png'))
	end
end
--[[
是否触摸到qte物体
@params touchPos cc.p 触摸位置
@return result bool 
--]]
function BaseAttachObj:isTouchedAttachObj(touchPos)
	local qteBoundingBox = self.viewData.view:getBoundingBox()
	local fixedPos = cc.CSceneManager:getInstance():getRunningScene():convertToNodeSpace(
		self.viewData.view:getParent():convertToWorldSpace(cc.p(qteBoundingBox.x, qteBoundingBox.y)))
	local rect = cc.rect(fixedPos.x, fixedPos.y, qteBoundingBox.width, qteBoundingBox.height)
	if cc.rectContainsPoint(rect, touchPos) then
		return true
	else
		return false
	end
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------


return BaseAttachObj
