local ExplorationVigourTipsView = class('ExplorationVigourTipsView', function ()
	return display.newLayer(display.cx, display.cy,{size = display.size, ap = cc.p(0.5, 0.5)})
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function ExplorationVigourTipsView:ctor( ... )
	self.args = unpack({...})
	self.pos = self.args.pos or display.center
	self.teamId = checkint(self.args.teamId)
	self.teamVigourCost = tonumber(self.args.teamVigourCost)
	self:InitView()
	self:ShowAction()
end

function ExplorationVigourTipsView:InitView()
	local function CreateView ()
		local bg = display.newImageView(_res('ui/common/common_bg_tips.png'), 0, 0, {scale9 = true, size = cc.size(400, 200), ap = cc.p(0.5, 0)})
		self:addChild(bg)
		local descr = display.newLabel(10, 183, fontWithColor(15, {ap  = cc.p(0, 1),  w = 380}))
		bg:addChild(descr)
		bg:setScale(0)
		return {
			bg    = bg,
			descr = descr
		}
	end
	xTry(function ( )
		self.viewData_ = CreateView( )
		self.viewData_.bg:setPosition(self.pos)
    	local cardNums = CommonUtils.GetTeamCardNums(self.teamId)
    	local descr = string.fmt(__('本次探索需消耗队伍总新鲜度的_num1_%\n队伍中现有_num2_个飨灵，每个飨灵消耗_num3_%的新鲜度'), {['_num1_'] = tostring(self.teamVigourCost*100), ['_num2_'] = tostring(cardNums), ['_num3_'] = tonumber(string.format('%.2f', tonumber(self.teamVigourCost)/cardNums*100))})
    	self.viewData_.descr:setString(descr)
	end, __G__TRACKBACK__)
	-- 重写触摸
	self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
end

function ExplorationVigourTipsView:ShowAction()
	self.viewData_.bg:runAction(
		cc.EaseBackOut:create(cc.ScaleTo:create(0.3, 1))
	)

end
function ExplorationVigourTipsView:onTouchBegan_(touch, event)
	return true
end
function ExplorationVigourTipsView:onTouchMoved_(touch, event)

end
function ExplorationVigourTipsView:onTouchEnded_(touch, event)
	self:RemoveSelf_()
end
--[[
移除自己
--]]
function ExplorationVigourTipsView:RemoveSelf_()
	self:setVisible(false)
	if self.touchListener_ then
		self:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end
	self:runAction(cc.RemoveSelf:create())

end
return ExplorationVigourTipsView
