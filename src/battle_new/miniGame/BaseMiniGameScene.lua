--[[
小游戏场景基类
@params args table {
	ownerTag int 场景拥有者的逻辑层tag
	sceneTag int 场景的tag
	startCB funtion 游戏开始时的回调
	overCB funtion 游戏结束时的回调
	dieCB function 场景移除前的回调
	callback function 游戏结束后的回调
}
--]]
local scheduler = require('cocos.framework.scheduler')

local BaseMiniGameScene = class('BaseMiniGameScene', function ()
	local node = CLayout:create()
	node.name = 'battle.miniGame.BaseMiniGameScene'
	node:enableNodeEvents()
	-- print(ID(node))
	return node
end)
--[[
constructor
--]]
function BaseMiniGameScene:ctor( ... )

	self.args = unpack({...}) or {}

	self.ownerTag = self.args.ownerTag
	self.sceneTag = self.args.tag

	--------------------------------------
	-- ui

	self.eaterLayer = nil
	self.touchItems = {}
	self.spineNodes = {}
	self.actionNodes = {}

	--------------------------------------
	-- data

	self.time = self.args.time or 0
	self.result = nil
	self.isPause = false

	self:init()

end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
function BaseMiniGameScene:init()
	self:initView()
end
function BaseMiniGameScene:initView()
	self:setContentSize(display.size)
	self:setAnchorPoint(cc.p(0, 0))

	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	self:addChild(eaterLayer)
	self.eaterLayer = eaterLayer

	-- debug --
	-- local debugLayer = CColorView:create(cc.c4b(255, 128, 64, 255 * 0.6))
	-- debugLayer:setContentSize(display.size)
	-- debugLayer:setAnchorPoint(cc.p(0.5, 0.5))
	-- debugLayer:setPosition(cc.p(display.cx, display.cy))
	-- self:addChild(debugLayer, 100)
	-- debug --
end
function BaseMiniGameScene:initTouch()
    self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:setSwallowTouches(true)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchCanceled_), cc.Handler.EVENT_TOUCH_CANCELLED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function BaseMiniGameScene:onTouchBegan_(touch, event)
	local isBattleTouchEnable = true
	if G_BattleRenderMgr then
		isBattleTouchEnable = G_BattleRenderMgr:IsBattleTouchEnable()
	end
	if self:isVisible() and isBattleTouchEnable then
		self:touchedItemHandler(self:touchCheck(touch))
		return true
	else
		return false
	end
end
function BaseMiniGameScene:onTouchMoved_(touch, event)

end
function BaseMiniGameScene:onTouchEnded_(touch, event)
	
end
function BaseMiniGameScene:onTouchCanceled_( touch, event )
	print('here touch canceled by some unknown reason')
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------

---------------------------------------------------
-- miniGame logic begin --
---------------------------------------------------
--[[
开始游戏
--]]
function BaseMiniGameScene:start()
	--###---------- 玩家手操记录 ----------###--
	-- 强制一倍速
	if G_BattleRenderMgr then
		G_BattleRenderMgr:ForceSetTimeScaleHandler(1)
	end
	--###---------- 玩家手操记录 ----------###--

	if self.args.startCB then
		xTry(function()
			self.args.startCB()
		end, __G__TRACKBACK__)
	end
end
--[[
游戏结束
--]]
function BaseMiniGameScene:over()
	self:setVisible(false)

	if self.args.overCB then
		xTry(function()
			self.args.overCB(self.result)
		end, __G__TRACKBACK__)
	end

	self:die()
end
--[[
添加touch item
@params ti {id = id, node = node}
--]]
function BaseMiniGameScene:addTouchItem(ti)
	local id = ti.id
	if not id then return end
	self.touchItems[tostring(id)] = ti
end
--[[
获取touch item 
@params id int touch item id
--]]
function BaseMiniGameScene:getTouchItem(id)
	return self.touchItems[tostring(id)]
end
--[[
移除touch item
@params ti
--]]
function BaseMiniGameScene:removeTouchItem(id)
	if not id then return end
	self.touchItems[tostring(id)] = nil
end
--[[
是否触摸到了touch item
@params touch 触摸
@return result 触摸结果 返回的是ti的key
--]]
function BaseMiniGameScene:touchCheck(touch)
	local p = touch:getLocation()
	local result = nil
	local boundingBox = nil
	for k,v in pairs(self.touchItems) do
		boundingBox = v.node:getBoundingBox()
		if cc.rectContainsPoint(boundingBox, p) then
			result = k
			break
		end
	end
	return result
end
--[[
触摸到了item 做出对应的处理
@params id int touch item id
--]]
function BaseMiniGameScene:touchedItemHandler(id)
	
end
--[[
强制移除
--]]
function BaseMiniGameScene:die()
	--###---------- 玩家手操记录 ----------###--
	-- 强制恢复原速度
	if G_BattleRenderMgr then
		G_BattleRenderMgr:ForceRecoverTimeScaleHandler()
	end
	--###---------- 玩家手操记录 ----------###--
	
	if self.args.dieCB then
		xTry(function()
			self.args.dieCB()
		end, __G__TRACKBACK__)
	end

	if self.touchListener_ then
		self:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end

	self:setVisible(false)
	self:stopAllActions()

	local dieActionSeq = cc.Sequence:create(
		cc.DelayTime:create(1 * cc.Director:getInstance():getAnimationInterval()),
		cc.CallFunc:create(function ()

		end),
		cc.RemoveSelf:create()
	)
	self:runAction(dieActionSeq)
end
--[[
update
--]]
function BaseMiniGameScene:update(dt)
	if self.isPause then return end
	self.time = self.time - dt
	if self.time <= 0 then
		self.result = false
		self:over()
	end
end
--[[
pause
--]]
function BaseMiniGameScene:pauseObj()
	self.isPause = true
	-- 暂停spine元素
	for i,v in ipairs(self.spineNodes) do
		v:setTimeScale(0)
	end
	-- 暂停所有运动中node
	for i,v in ipairs(self.actionNodes) do
		cc.Director:getInstance():getActionManager():pauseTarget(v)
	end
end
--[[
resume
--]]
function BaseMiniGameScene:resumeObj()
	self.isPause = false
	-- 恢复spine元素
	for i,v in ipairs(self.spineNodes) do
		v:setTimeScale(1)
	end
	-- 恢复所有运动中node
	for i,v in ipairs(self.actionNodes) do
		cc.Director:getInstance():getActionManager():resumeTarget(v)
	end
end
---------------------------------------------------
-- miniGame logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取场景pwnertag
--]]
function BaseMiniGameScene:GetOwnerTag()
	return self.ownerTag
end
--[[
获取场景tag
--]]
function BaseMiniGameScene:GetSceneTag()
	return self.sceneTag
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- handler logic begin --
---------------------------------------------------
--[[
cocos2dx event handler
--]]
function BaseMiniGameScene:onEnter()
	self:start()
end
function BaseMiniGameScene:onExit()
	
end
function BaseMiniGameScene:onCleanup()
	-- print('remove self -> ' .. ID(self))
end
---------------------------------------------------
-- handler logic end --
---------------------------------------------------

return BaseMiniGameScene
