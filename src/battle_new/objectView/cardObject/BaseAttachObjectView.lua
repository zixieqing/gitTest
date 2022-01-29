--[[
基础qte物体view
@params t table {
	@params ownerTag int 拥有者tag
	@params tag int qte obj tag
	@params skillId int 对应的技能id
	@params qteAttachObjectType QTEAttachObjectType qte层类型
}
--]]
local BaseAttachObjectView = class('BaseAttachObjectView', function ()
	local node = CLayout:create()
	node.name = 'battle.obiectView.BaseAttachObjectView'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseAttachObjectView:ctor( ... )
	local args = unpack({...})

	self.ownerTag = args.ownerTag
	self.tag = args.tag
	self.skillId = args.skillId
	self.qteAttachObjectType = args.qteAttachObjectType

	self:Init()
end

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化
--]]
function BaseAttachObjectView:Init()
	self:InitValue()
	self:InitView()
	self:InitTouch()
end
--[[
初始化数值
--]]
function BaseAttachObjectView:InitValue()
	-- 触摸事件回调
	self.touchListener_ = nil
end
--[[
初始化view
--]]
function BaseAttachObjectView:InitView()

	local function CreateView()

		local qteView = display.newNSprite(self:GetQTEViewPathByTouchPace(0), 0, 0)
		local bgSize = qteView:getContentSize()

		-- 处理自身大小
		self:setContentSize(bgSize)
		display.commonUIParams(self, {ap = cc.p(0.5, 0), po = cc.p(0, 0)})

		-- 处理qte view
		display.commonUIParams(qteView, {ap = cc.p(0.5, 0), po = cc.p(bgSize.width * 0.5, -25)})
		self:addChild(qteView)

		-- 提醒按钮
		local remindLabel = display.newLabel(bgSize.width * 0.5, bgSize.height * 0.6,{text = __('戳我!'), fontSize = 34, color = fontWithColor('BC').color,ttf = true, font = TTF_GAME_FONT})
		remindLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		self:addChild(remindLabel, 20)
		remindLabel:setScale(0.9)

		local remindActionSeq = cc.RepeatForever:create(cc.Sequence:create(
			cc.ScaleTo:create(0.05, 1.1),
			cc.ScaleTo:create(0.05, 0.9)))
		remindLabel:runAction(remindActionSeq)

		return {
			qteView = qteView,
			remindLabel = remindLabel
		}

	end

	xTry(function ()	
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

end
--[[
初始化触摸
--]]
function BaseAttachObjectView:InitTouch()
	if nil == self.touchListener_ then
		self.touchListener_ = cc.EventListenerTouchOneByOne:create()
		self.touchListener_:setSwallowTouches(false)
		self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
		self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
		self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
		self.touchListener_:registerScriptHandler(handler(self, self.onTouchCanceled_), cc.Handler.EVENT_TOUCH_CANCELLED)
		self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
	end
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据pace刷新qte物体状态
@params touchPace int 点击阶段
--]]
function BaseAttachObjectView:RefreshQTEViewByTouchPace(touchPace)
	self.viewData.qteView:setTexture(self:GetQTEViewPathByTouchPace(touchPace))
end
--[[
销毁qte view
--]]
function BaseAttachObjectView:Destroy()
	G_BattleRenderMgr:PlayBattleSoundEffect(AUDIOS.BATTLE.ty_beattack_binlie.id)
	self:setVisible(false)

	self:runAction(cc.Sequence:create(
		cc.DelayTime:create(0.05),
		cc.CallFunc:create(function ()
			if self.touchListener_ then
				self:getEventDispatcher():removeEventListener(self.touchListener_)
				self.touchListener_ = nil
			end
		end),
		cc.RemoveSelf:create()
	))
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- touch handler begin --
---------------------------------------------------
function BaseAttachObjectView:onTouchBegan_(touch, event)
	if G_BattleRenderMgr and G_BattleRenderMgr:IsBattleTouchEnable() and self:IsAlive() then
		return true
	else
		return false
	end
end
function BaseAttachObjectView:onTouchMoved_(touch, event)

end
function BaseAttachObjectView:onTouchEnded_(touch, event)
	if self:IsTouchedAttachObjectView(touch:getLocation()) then
		self:TouchedAttachObjectView()
	end
end
function BaseAttachObjectView:onTouchCanceled_(touch, event)
	print('here touch canceled by some unknown reason in ---***> BaseAttachObjectView:onTouchCanceled_')
end
--[[
是否触摸到qte物体
@params touchPos cc.p 触摸位置
@return _ bool 
--]]
function BaseAttachObjectView:IsTouchedAttachObjectView(touchPos)
	local qteBoundingBox = self:getBoundingBox()
	local fixedPos = cc.CSceneManager:getInstance():getRunningScene():convertToNodeSpace(
		self:getParent():convertToWorldSpace(cc.p(qteBoundingBox.x, qteBoundingBox.y)))
	local rect = cc.rect(fixedPos.x, fixedPos.y, qteBoundingBox.width, qteBoundingBox.height)
	if cc.rectContainsPoint(rect, touchPos) then
		return true
	else
		return false
	end
end
--[[
成功点击到了qte物体
--]]
function BaseAttachObjectView:TouchedAttachObjectView()
	--###---------- 玩家手操记录 ----------###--
	G_BattleRenderMgr:AddPlayerOperate(
		'G_BattleLogicMgr',
		'RenderQTEAttachObjectHandler',
		self.ownerTag, self.tag, self.skillId
	)
	--###---------- 玩家手操记录 ----------###--
end
---------------------------------------------------
-- touch handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
判断自身是否有效
@return _ bool 是否有效
--]]
function BaseAttachObjectView:IsAlive()
	return self:isVisible()
end
--[[
根据touch pace获取view的图片路径
@params touchPace int 触摸阶段
@return path string 图片路径
--]]
function BaseAttachObjectView:GetQTEViewPathByTouchPace(touchPace)
	local qtePathStr = 'battle/effect/bing%d.png'
	local path = string.format(qtePathStr, touchPace)
	return _res(path)
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseAttachObjectView
