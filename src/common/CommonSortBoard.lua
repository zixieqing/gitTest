--[[
通用升降排序板
@params table {
	targetNode cc.Node 需要对齐的节点
	autoRemove bool 是否自动移除
	sortRules list 排序规则 {
		{sortType = 排序类型, sortDescr = 排序描述, callbackSignal = 按钮回调信号, defaultSort = 默认升降序类型}
	}
}
--]]
local CommonSortBoard = class('CommonSortBoard', function ()
	return display.newLayer()
end)

------------ import ------------
------------ import ------------

------------ define ------------
SortOrder = {
	ASC 			= 1, -- 升序
	DESC 			= 2  -- 降序
}
------------ define ------------

--[[
constructor
--]]
function CommonSortBoard:ctor( ... )
	local args = unpack({...})

	self.targetNode = args.targetNode
	self.autoRemove = args.autoRemove
	self.sortRules = args.sortRules

	self:InitUI()
	self:InitTouch()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化ui
--]]
function CommonSortBoard:InitUI()
	-- 初始化尺寸
	local cellSize = cc.size(150, 75)
	local padding = cc.p(2, 2)

	local sortRulesAmount = #self.sortRules

	local size = cc.size(
		cellSize.width + 2 * padding.x,
		cellSize.height * sortRulesAmount + 2 * padding.y
	)

	self:setContentSize(size)
	-- self:setBackgroundColor(cc.c4b(64, 128, 255, 100))

	-- bg
	local bg = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_frame_1.png'), 0, 0,
		{scale9 = true, size = size})
	display.commonUIParams(bg, {po = cc.p(size.width * 0.5, size.height * 0.5)})
	self:addChild(bg)

	-- arrow
	-- local arrow = display.newNSprite(_res('ui/common/common_bg_tips_horn.png'), 0, 0)
	-- display.commonUIParams(arrow, {po = cc.p(
	-- 	size.width * 0.5,
	-- 	size.height - padding.x
	-- )})
	-- bg:addChild(arrow)

	-- 创建排序按钮组
	local centerY = 0

	local sortNodes = {}
	--[[
	{
		{sortMark = nil},
		{sortMark = nil},
		{sortMark = nil},
		...
	}
	--]]
	for i,v in ipairs(self.sortRules) do
		centerY = size.height - padding.x - (i - 0.5) * cellSize.height

		-- 创建按钮
		local sortBtn = display.newButton(0, 0, {size = cellSize, cb = handler(self, self.SortClickHandler)})
		display.commonUIParams(sortBtn, {po = cc.p(
			size.width * 0.5,
			centerY
		)})
		self:addChild(sortBtn, 5)
		sortBtn:setTag(i)

		-- 按钮说明
		local sortDescrLabel = display.newLabel(0, 0, fontWithColor('16', {text = v.sortDescr , ap =display.LEFT_CENTER , reqW = 80 }))
		display.commonUIParams(sortDescrLabel, {po = cc.p(
			cellSize.width * 0.5 -20 ,
			cellSize.height * 0.5
		)})
		sortBtn:addChild(sortDescrLabel)

		-- 升降序标识
		local sortMark = display.newNSprite(_res('ui/home/cardslistNew/tujian_selection_select_ico_filter_direction.png'), 0, 0)
		display.commonUIParams(sortMark, {po = cc.p(
			cellSize.width * 0.15,
			cellSize.height * 0.5
		)})
		sortBtn:addChild(sortMark)
		sortMark:setTag(v.defaultSort)

		if SortOrder.ASC == v.defaultSort then
			sortMark:setFlippedY(true)
		end

		if i ~= sortRulesAmount then
			-- 创建分隔线
			local splitLine = display.newNSprite(_res('ui/common/tujian_selection_line.png'), 0, 0)
			display.commonUIParams(splitLine, {po = cc.p(
				size.width * 0.5,
				centerY - cellSize.height * 0.5
			)})
			splitLine:setScaleX(cellSize.width / splitLine:getContentSize().width)
			self:addChild(splitLine, 5)
		end

		sortNodes[i] = {sortMark = sortMark}
	end


	self.sortNodes = sortNodes

end
--[[
初始化触摸
--]]
function CommonSortBoard:InitTouch()
	self.touchListener_ = cc.EventListenerTouchOneByOne:create()
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
-- view control begin --
---------------------------------------------------
--[[
是否触摸到了自己
@params touchPos cc.p 触摸位置
@return _ bool 
--]]
function CommonSortBoard:TouchedSelf(touchPos)
	local boundingBox = self:getBoundingBox()
	local fixedP = cc.CSceneManager:getInstance():getRunningScene():convertToNodeSpace(
		self:getParent():convertToWorldSpace(cc.p(boundingBox.x, boundingBox.y)))
	if cc.rectContainsPoint(cc.rect(fixedP.x, fixedP.y, boundingBox.width, boundingBox.height), touchPos) then
		return true
	end
	return false
end
--[[
移除自己
--]]
function CommonSortBoard:RemoveSelf_()
	self:setVisible(false)
	if self.autoRemove then
		-- 真移除自己
		if self.touchListener_ then
			self:getEventDispatcher():removeEventListener(self.touchListener_)
			self.touchListener_ = nil
		end
		self:runAction(cc.RemoveSelf:create())
	end
end
--[[
获取下一个排序规则
@params sortOrder SortOrder 升降序
@return _ SortOrder 升降序
--]]
function CommonSortBoard:GetNextSortOrder(sortOrder)
	return 3 - sortOrder
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
排序按钮回调
--]]
function CommonSortBoard:SortClickHandler(sender)
	local index = sender:getTag()
	local sortRule = self.sortRules[index]
	local sortNode = self.sortNodes[index]
	local sortOrder = sortNode.sortMark:getTag()

	AppFacade.GetInstance():DispatchObservers(sortRule.callbackSignal, {
		sortType = sortRule.sortType,
		sortOrder = sortOrder
	})

	-- 改变一次排序规则
	local nextSortOrder = self:GetNextSortOrder(sortOrder)
	self.sortNodes[index].sortMark:setTag(nextSortOrder)
	self.sortNodes[index].sortMark:setFlippedY(SortOrder.ASC == nextSortOrder)

end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function CommonSortBoard:onTouchBegan_(touch, event)
	-- 判断是否触摸到自己以外的地方
	if self:TouchedSelf(touch:getLocation()) then
		return true
	else
		self:RemoveSelf_()
		return false
	end
end
function CommonSortBoard:onTouchMoved_(touch, event)

end
function CommonSortBoard:onTouchEnded_(touch, event)
	self:RemoveSelf_()
end
function CommonSortBoard:onTouchCanceled_( touch, event )
	print('here touch canceled by some unknown reason')
end

function CommonSortBoard:onEnter()

end
function CommonSortBoard:onExit()
	
end
function CommonSortBoard:onCleanup()
	self:setVisible(false)
	if self.touchListener_ then
		self:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------



















return CommonSortBoard
