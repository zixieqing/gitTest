--[[
通用spine对话冒泡节点
@params table {
	------------ pattern 1 ------------
	targetNode cc.Node 目标节点
	------------ pattern 1 ------------

	------------ pattern 2 ------------
	targetPosition cc.p 目标位置(世界坐标) -> !!! 请传入正确的世界坐标 !!!
	------------ pattern 2 ------------

	descr string 描述文字
	parentNode cc.node 父节点 为空时默认为 sceneWorld
	zorder int zorder
	alwaysOnCenter bool 总是在中间 -> 只针对pattern 1 并且node为spine节点
	alwaysOnTop bool 总是在顶部
	ignoreOutside bool 无视超出边界
	paddingX int 气泡框的x偏移 总是正数
	paddingY int 气泡框的y偏移 总是正数
	touchRemove bool 触摸是否会立即移除气泡
	autoRemove bool 自动移除气泡
}
--]]
local CommonDialogueBubbleNode = class('CommonDialogueBubbleNode', function ()
	return display.newLayer()
end)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

------------ define ------------
local oriSize = cc.size(248, 75)
local descrPaddingX = 5
local descrPaddingY = 5
------------ define ------------

--[[
constructor
--]]
function CommonDialogueBubbleNode:ctor( ... )
	local args = unpack({...})

	self.vaild = false

	self:InitValue(args)
	self:InitUI()
	if self.touchRemove then
		self:InitTouchHandler()
	end

end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化数据
@params args table 参数集
--]]
function CommonDialogueBubbleNode:InitValue(args)
	self.targetNode = args.targetNode
	self.targetPosition = args.targetPosition
	self.parentNode = args.parentNode or sceneWorld
	self.zorder = checkint(args.zorder or 9999)
	self.alwaysOnCenter = nil ~= args.alwaysOnCenter and args.alwaysOnCenter or false
	self.alwaysOnTop = nil ~= args.alwaysOnTop and args.alwaysOnTop or false
	self.ignoreOutside = nil ~= args.ignoreOutside and args.ignoreOutside or false
	self.paddingX = args.paddingX or 0
	self.paddingY = args.paddingY or 0
	self.touchRemove = nil ~= args.touchRemove and args.touchRemove or false

	self.autoRemove = true
	if nil ~= args.autoRemove then
		self.autoRemove = args.autoRemove
	end

	self.descr = args.descr
end
--[[
创建基本ui元素
--]]
function CommonDialogueBubbleNode:InitUI()

	local function CreateView()

		-- bg
		local bg = display.newImageView(_res('ui/common/chat_bg_npc.png'), 0, 0,
			{scale9 = true, size = oriSize})
		self:addChild(bg, 1)

		local arrow = display.newNSprite(_res('ui/common/chat_ico_npc_horn.png'), 0, 0)
		bg:addChild(arrow, 2)

		-- content text
		local descrLabel = display.newLabel(0, 0,
			fontWithColor('6', {text = tostring(self.descr), w = oriSize.width - descrPaddingX * 2, hAlign = display.TAL}))
		self:addChild(descrLabel, 5)

		return {
			bg = bg,
			arrow = arrow,
			descrLabel = descrLabel
		}

	end

	xTry(function ( )
		self.parentNode:addChild(self, self.zorder)

		self.viewData = CreateView()
		self:FixBubbleSize()
		self:FixBubblePosition()

		self:setVisible(false)
		self:setOpacity(0)
		self.viewData.arrow:setOpacity(0)
		self:ShowBubble()

	end, __G__TRACKBACK__)
end
--[[
初始化触摸事件
--]]
function CommonDialogueBubbleNode:InitTouchHandler()
	self.touchListener_ = cc.EventListenerTouchOneByOne:create()
	self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchCanceled_), cc.Handler.EVENT_TOUCH_CANCELLED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
修正对话框大小 超框时纵向自适应
--]]
function CommonDialogueBubbleNode:FixBubbleSize()
	local descrLabelSize = display.getLabelContentSize(self.viewData.descrLabel)

	local fixedSize = oriSize

	if oriSize.height - descrPaddingY * 2 < descrLabelSize.height then

		-- 如果纵向超框 自适应
		local fixedHeight = descrLabelSize.height + descrPaddingY * 2
		fixedSize.height = fixedHeight

	end

	-- 修正自身大小
	self:setContentSize(fixedSize)
	self.viewData.bg:setContentSize(fixedSize)
	-- 修正子节点位置
	display.commonUIParams(self.viewData.bg, {po = cc.p(
		fixedSize.width * 0.5,
		fixedSize.height * 0.5
	)})
	display.commonUIParams(self.viewData.descrLabel, {ap = cc.p(0, 1), po = cc.p(
		descrPaddingX,
		fixedSize.height - descrPaddingY
	)})
end
--[[
修正对话框位置 修正箭头位置
--]]
function CommonDialogueBubbleNode:FixBubblePosition()
	if nil ~= self.targetNode then
		-- 根据目标节点刷新位置
		self:FixBubblePosByTargetNode(self.targetNode)
	elseif nil ~= self.targetPosition then
		-- 根据目标位置刷新位置
		self:FixBubblePosByTargetPosition(self.targetPosition)
	end
end
--[[
根据目标节点刷新位置
@params targetNode cc.node 目标节点
--]]
function CommonDialogueBubbleNode:FixBubblePosByTargetNode(targetNode)
	local toluatype = tolua.type(targetNode)
	if 'sp.SkeletonAnimation' == toluatype then
		-- 如果是spine节点 认为是spine小人的真实碰撞节点
		self:FixBubblePosBySpineNode(targetNode)
	else
		-- 其他 认为是普通node
		self:FixBubblePosByCommonNode(targetNode)
	end
	-- print('here check fuck cc type<<<<<<<', tolua.type(targetNode))
	-- dump(targetNode)
end
--[[
根据目标spine小人节点刷新位置
@params targetNode sp.SkeletonAnimation 目标节点
--]]
function CommonDialogueBubbleNode:FixBubblePosBySpineNode(targetNode)
	-- 容错 如果没有边界框 认为是普通节点
	if nil == targetNode.getBorderBox and nil == targetNode:getBorderBox('viewBox') then
		self:FixBubblePosByCommonNode(targetNode)
		return
	end

	if self.alwaysOnCenter then
		self:FixBubblePosBySpineNodeOnCenter(targetNode)
		return
	end

	local borderBox = targetNode:getBorderBox('viewBox')
	local spineTowards = targetNode:getScaleX() > 0 and 1 or -1	
	local spineNodeWorldPos = targetNode:getParent():convertToWorldSpace(cc.p(targetNode:getPositionX(), targetNode:getPositionY()))
	local targetPosition = cc.p(spineNodeWorldPos.x, 0)

	local bgSize = self.viewData.bg:getContentSize()
	local anchorPoint = cc.p(0.5, 0.5)

	local x, y = 0, 0

	------------ 计算x修正坐标 ------------
	-- 默认显示在人物朝向的方向
	if spineTowards > 0 then
		-- 朝向x正方向
		if display.SAFE_R < targetPosition.x + bgSize.width then
			-- 右边超出右边界 将气泡置左
			if self.ignoreOutside then
				x = targetPosition.x - bgSize.width * (1 - anchorPoint.x)
			else
				x = math.max(display.SAFE_L, targetPosition.x - bgSize.width * (1 - anchorPoint.x))
			end
			x = x - self.paddingX
		else
			if self.ignoreOutside then
				x = targetPosition.x + bgSize.width * anchorPoint.x
			else
				x = math.min(display.SAFE_R, targetPosition.x + bgSize.width * anchorPoint.x)
			end
			x = x + self.paddingX
		end
	elseif spineTowards < 0 then
		-- 朝向x负方向
		if display.SAFE_L > targetPosition.x - bgSize.width then
			-- 左边超出左边界 将气泡置右
			if self.ignoreOutside then
				x = targetPosition.x + bgSize.width * anchorPoint.x
			else
				x = math.min(display.SAFE_R, targetPosition.x + bgSize.width * anchorPoint.x)
			end
			x = x + self.paddingX
		else
			if self.ignoreOutside then
				x = targetPosition.x - bgSize.width * (1 - anchorPoint.x)
			else
				x = math.max(display.SAFE_L, targetPosition.x - bgSize.width * (1 - anchorPoint.x))
			end
			x = x - self.paddingX
		end
	end
	------------ 计算x修正坐标 ------------

	local arrow = self.viewData.arrow
	local arrowSize = arrow:getContentSize()

	------------ 计算y修正坐标 默认上显示 ------------
	-- 气泡上显示时默认设置在spine viewBox边界框的中上部
	local spineBorderTopY = spineNodeWorldPos.y + borderBox.y + borderBox.height * 0.8
	local spineBoderBottomY = spineNodeWorldPos.y + borderBox.y

	if display.height < (spineBorderTopY + bgSize.height) and not self.alwaysOnTop then
		-- 顶边超过上边界 气泡框下显示
		targetPosition.y = spineBoderBottomY

		if self.ignoreOutside then
			y = targetPosition.y - bgSize.height * (1 - anchorPoint.y)
		else
			y = math.max(0 + bgSize.height * anchorPoint.y, targetPosition.y - bgSize.height * (1 - anchorPoint.y))
		end
		y = y - self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		-- 修正箭头位置
		arrow:setFlippedY(true)
		if x < targetPosition.x then
			display.commonUIParams(arrow, {po = cc.p(
				bgSize.width * 0.8,
				bgSize.height + arrowSize.height * 0.5 - 2
			)})
		else
			display.commonUIParams(arrow, {po = cc.p(
				bgSize.width * 0.2,
				bgSize.height + arrowSize.height * 0.5 - 2
			)})
		end
	elseif 0 > (spineBoderBottomY - bgSize.height) then
		-- 底边超过下边界 气泡框上显示
		targetPosition.y = spineBorderTopY

		if self.ignoreOutside then
			y = targetPosition.y + bgSize.height * anchorPoint.y
		else
			y = math.min(display.height - bgSize.height * (1 - anchorPoint.y), targetPosition.y + bgSize.height * anchorPoint.y)
		end
		y = y + self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		-- 修正箭头位置
		arrow:setFlippedY(false)
		if x < targetPosition.x then
			display.commonUIParams(arrow, {po = cc.p(
				bgSize.width * 0.8,
				-arrowSize.height * 0.5 + 3
			)})
		else
			display.commonUIParams(arrow, {po = cc.p(
				bgSize.width * 0.2,
				-arrowSize.height * 0.5 + 3
			)})
		end
	else
		-- 默认上显示
		targetPosition.y = spineBorderTopY

		if self.ignoreOutside then
			y = targetPosition.y + bgSize.height * anchorPoint.y
		else
			y = math.min(display.height - bgSize.height * (1 - anchorPoint.y), targetPosition.y + bgSize.height * anchorPoint.y)
		end
		y = y + self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		-- 修正箭头位置
		arrow:setFlippedY(false)
		if x < targetPosition.x then
			display.commonUIParams(arrow, {po = cc.p(
				bgSize.width * 0.8,
				-arrowSize.height * 0.5 + 3
			)})
		else
			display.commonUIParams(arrow, {po = cc.p(
				bgSize.width * 0.2,
				-arrowSize.height * 0.5 + 3
			)})
		end
	end
	------------ 计算y修正坐标 默认上显示 ------------
end
--[[
根据目标spine小人节点刷新位置 始终在中间的头顶
@params targetNode sp.SkeletonAnimation 目标节点
--]]
function CommonDialogueBubbleNode:FixBubblePosBySpineNodeOnCenter(targetNode)
	-- 容错 如果没有边界框 认为是普通节点
	if nil == targetNode.getBorderBox and nil == targetNode:getBorderBox('viewBox') then
		self:FixBubblePosByCommonNode(targetNode)
		return
	end

	local borderBox = targetNode:getBorderBox('viewBox')
	local spineNodeWorldPos = targetNode:getParent():convertToWorldSpace(cc.p(targetNode:getPositionX(), targetNode:getPositionY()))
	local targetPosition = cc.p(spineNodeWorldPos.x, 0)

	local bgSize = self.viewData.bg:getContentSize()
	local anchorPoint = cc.p(0.5, 0.5)

	local x, y = 0, 0

	------------ 计算x修正坐标 ------------
	if self.ignoreOutside then
		x = targetPosition.x - bgSize.height * (0.5 - anchorPoint.x)
	else
		x = math.min(
				display.SAFE_R - bgSize.width * (1 - anchorPoint.x),
				math.max(display.SAFE_L + bgSize.width * anchorPoint.x, targetPosition.x + bgSize.width * (0.5 - anchorPoint.x))
			)
	end
	------------ 计算x修正坐标 ------------

	local arrow = self.viewData.arrow
	local arrowSize = arrow:getContentSize()

	------------ 计算y修正坐标 默认上显示 ------------
	local spineBorderTopY = spineNodeWorldPos.y + borderBox.y + borderBox.height
	local spineBoderBottomY = spineNodeWorldPos.y + borderBox.y

	if display.height < (spineBorderTopY + bgSize.height) and not self.alwaysOnTop then
		-- 顶边超过上边界 气泡框下显示
		targetPosition.y = spineBoderBottomY

		if self.ignoreOutside then
			y = targetPosition.y - bgSize.height * (1 - anchorPoint.y)
		else
			y = math.max(0 + bgSize.height * anchorPoint.y, targetPosition.y - bgSize.height * (1 - anchorPoint.y))
		end
		y = y - self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		-- 修正箭头位置
		arrow:setFlippedY(true)
		display.commonUIParams(arrow, {po = cc.p(
			math.max(arrowSize.width * 0.5 + descrPaddingX, math.min(bgSize.width - arrowSize.width * 0.5 - descrPaddingX, (arrow:getParent():convertToNodeSpace(targetPosition).x))),
			bgSize.height + arrowSize.height * 0.5 - 2
		)})
	elseif 0 > (spineBoderBottomY - bgSize.height) then
		-- 底边超过下边界 气泡框上显示
		targetPosition.y = spineBorderTopY

		if self.ignoreOutside then
			y = targetPosition.y + bgSize.height * anchorPoint.y
		else
			y = math.min(display.height - bgSize.height * (1 - anchorPoint.y), targetPosition.y + bgSize.height * anchorPoint.y)
		end
		y = y + self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		arrow:setFlippedY(false)
		display.commonUIParams(arrow, {po = cc.p(
			math.max(arrowSize.width * 0.5 + descrPaddingX, math.min(bgSize.width - arrowSize.width * 0.5 - descrPaddingX, (arrow:getParent():convertToNodeSpace(targetPosition).x))),
			-arrowSize.height * 0.5 + 3
		)})
	else
		-- 默认上显示
		targetPosition.y = spineBorderTopY

		if self.ignoreOutside then
			y = targetPosition.y + bgSize.height * anchorPoint.y
		else
			y = math.min(display.height - bgSize.height * (1 - anchorPoint.y), targetPosition.y + bgSize.height * anchorPoint.y)
		end
		y = y + self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		arrow:setFlippedY(false)
		display.commonUIParams(arrow, {po = cc.p(
			math.max(arrowSize.width * 0.5 + descrPaddingX, math.min(bgSize.width - arrowSize.width * 0.5 - descrPaddingX, (arrow:getParent():convertToNodeSpace(targetPosition).x))),
			-arrowSize.height * 0.5 + 3
		)})
	end
	------------ 计算y修正坐标 默认上显示 ------------

end
--[[
根据目标普通节点刷新位置
@params targetNode cc.node 目标节点
--]]
function CommonDialogueBubbleNode:FixBubblePosByCommonNode(targetNode)
	local bgSize = self.viewData.bg:getContentSize()
	local anchorPoint = cc.p(0.5, 0.5)

	local targetBoundingBox = targetNode:getBoundingBox() or cc.rect(0, 0, 0, 0)
	local boundingBoxWorldPos = targetNode:getParent():convertToWorldSpace(cc.p(targetBoundingBox.x, targetBoundingBox.y))
	local targetPosition = cc.p(boundingBoxWorldPos.x + targetBoundingBox.width * 0.5, 0)

	local x, y = 0, 0

	------------ 计算x修正坐标 ------------
	if self.ignoreOutside then
		x = targetPosition.x
	else
		x = math.min(
			display.SAFE_R - bgSize.width * (1 - anchorPoint.x),
			math.max(display.SAFE_L + bgSize.width * anchorPoint.x, targetPosition.x + bgSize.width * (anchorPoint.x - 0.5))
		)
	end
	------------ 计算x修正坐标 ------------

	local arrow = self.viewData.arrow
	local arrowSize = arrow:getContentSize()

	------------ 计算y修正坐标 默认上显示 ------------
	local borderTopY = boundingBoxWorldPos.y + targetBoundingBox.height
	local borderBottomY = boundingBoxWorldPos.y

	if display.height < (borderTopY + bgSize.height * anchorPoint.y) and not self.alwaysOnTop then
		-- 顶边超过上边界气泡框下显示
		targetPosition.y = borderBottomY

		if self.ignoreOutside then
			y = targetPosition.y - bgSize.height * (1 - anchorPoint.y)
		else
			y = math.max(0 + bgSize.height * anchorPoint.y, targetPosition.y - bgSize.height * (1 - anchorPoint.y))
		end
		y = y - self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		-- 修正箭头位置
		arrow:setFlippedY(true)
		display.commonUIParams(arrow, {po = cc.p(
			math.max(arrowSize.width * 0.5 + descrPaddingX, math.min(bgSize.width - arrowSize.width * 0.5 - descrPaddingX, (arrow:getParent():convertToNodeSpace(targetPosition).x))),
			bgSize.height + self.viewData.arrow:getContentSize().height * 0.5 - 2
		)})
	elseif 0 > (borderBottomY - bgSize.height * (1 - anchorPoint.y)) then
		-- 底边超过下边界 气泡框上显示
		targetPosition.y = borderTopY

		if self.ignoreOutside then
			y = targetPosition.y + bgSize.height * anchorPoint.y
		else
			y = math.min(display.height - bgSize.height * (1 - anchorPoint.y), targetPosition.y + bgSize.height * anchorPoint.y)
		end
		y = y + self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		-- 修正箭头位置
		arrow:setFlippedY(false)
		display.commonUIParams(arrow, {po = cc.p(
			math.max(arrowSize.width * 0.5 + descrPaddingX, math.min(bgSize.width - arrowSize.width * 0.5 - descrPaddingX, (arrow:getParent():convertToNodeSpace(targetPosition).x))),
			-self.viewData.arrow:getContentSize().height * 0.5 + 3
		)})
	else
		-- 默认上显示
		targetPosition.y = borderTopY

		if self.ignoreOutside then
			y = targetPosition.y + bgSize.height * anchorPoint.y
		else
			y = math.min(display.height - bgSize.height * (1 - anchorPoint.y), targetPosition.y + bgSize.height * anchorPoint.y)
		end
		y = y + self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		-- 修正箭头位置
		arrow:setFlippedY(false)
		display.commonUIParams(arrow, {po = cc.p(
			math.max(arrowSize.width * 0.5 + descrPaddingX, math.min(bgSize.width - arrowSize.width * 0.5 - descrPaddingX, (arrow:getParent():convertToNodeSpace(targetPosition).x))),
			-self.viewData.arrow:getContentSize().height * 0.5 + 3
		)})
	end
	------------ 计算y修正坐标 默认上显示 ------------
end
--[[
根据目标位置刷新位置
@params targetPosition cc.p 目标位置
--]]
function CommonDialogueBubbleNode:FixBubblePosByTargetPosition(targetPosition)
	local bgSize = self.viewData.bg:getContentSize()
	local anchorPoint = cc.p(0.5, 0.5)

	local x, y = targetPosition.x, targetPosition.y

	------------ 计算x修正坐标 ------------
	if self.ignoreOutside then
		x = targetPosition.x + bgSize.width * (anchorPoint.x - 0.5)
	else
		x = math.min(display.SAFE_R - bgSize.width * (1 - anchorPoint.x), math.max(display.SAFE_L + bgSize.width * anchorPoint.x, targetPosition.x + bgSize.width * (anchorPoint.x - 0.5)))		
	end
	x = x + self.paddingX
	------------ 计算x修正坐标 ------------

	------------ 计算y修正坐标 默认上显示 ------------
	local arrow = self.viewData.arrow
	local arrowSize = arrow:getContentSize()

	if display.height < (targetPosition.y + bgSize.height) and not self.alwaysOnTop then
		-- 顶边超过上边界 气泡框下显示
		if self.ignoreOutside then
			y = targetPosition.y - bgSize.height * (1 - anchorPoint.y)
		else
			y = math.max(0 + bgSize.height * anchorPoint.y, targetPosition.y - bgSize.height * (1 - anchorPoint.y))
		end
		y = y - self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		-- 修正箭头位置
		arrow:setFlippedY(true)
		display.commonUIParams(arrow, {po = cc.p(
			math.max(arrowSize.width * 0.5 + descrPaddingX, math.min(bgSize.width - arrowSize.width * 0.5 - descrPaddingX, (arrow:getParent():convertToNodeSpace(targetPosition).x))),
			bgSize.height + self.viewData.arrow:getContentSize().height * 0.5 - 2
		)})
	elseif 0 > (targetPosition.y - bgSize.height) then
		-- 底边超过下边界 气泡框上显示
		if self.ignoreOutside then
			y = targetPosition.y + bgSize.height * anchorPoint.y
		else
			y = math.min(display.height - bgSize.height * (1 - anchorPoint.y), targetPosition.y + bgSize.height * anchorPoint.y)
		end
		y = y + self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		-- 修正箭头位置
		arrow:setFlippedY(false)
		display.commonUIParams(arrow, {po = cc.p(
			math.max(arrowSize.width * 0.5 + descrPaddingX, math.min(bgSize.width - arrowSize.width * 0.5 - descrPaddingX, (arrow:getParent():convertToNodeSpace(targetPosition).x))),
			-self.viewData.arrow:getContentSize().height * 0.5 + 3
		)})
	else
		-- 都不超边界 默认上显示
		if self.ignoreOutside then
			y = targetPosition.y + bgSize.height * anchorPoint.y
		else
			y = math.min(display.height - bgSize.height * (1 - anchorPoint.y), targetPosition.y + bgSize.height * anchorPoint.y)
		end
		y = y + self.paddingY

		local parentNodeFixedPos = self.parentNode:convertToNodeSpace(cc.p(x, y))
		display.commonUIParams(self, {ap = anchorPoint, po = parentNodeFixedPos})

		-- 修正箭头位置
		arrow:setFlippedY(false)
		display.commonUIParams(arrow, {po = cc.p(
			math.max(arrowSize.width * 0.5 + descrPaddingX, math.min(bgSize.width - arrowSize.width * 0.5 - descrPaddingX, (arrow:getParent():convertToNodeSpace(targetPosition).x))),
			-self.viewData.arrow:getContentSize().height * 0.5 + 3
		)})
	end
	------------ 计算y修正坐标 默认上显示 ------------
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
移除自己
--]]
function CommonDialogueBubbleNode:RemoveBubble()
	self.vaild = false

	if self.touchListener_ then
		self:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end

	self:stopAllActions()
	self:setVisible(false)
	self:runAction(cc.RemoveSelf:create())
end
--[[
显示
--]]
function CommonDialogueBubbleNode:ShowBubble()
	local actionSeq = cc.Sequence:create(
		cc.Show:create(),
		cc.FadeTo:create(0.25, 255),
		cc.CallFunc:create(function ()
			self.vaild = true
			if self.autoRemove then
				self:AutoRemove()
			end
		end)
	)
	self:runAction(actionSeq)

	local arrowActionSeq = cc.Sequence:create(
		cc.FadeTo:create(0.25, 255)
	)
	self.viewData.arrow:runAction(arrowActionSeq)
end
--[[
自动移除
--]]
function CommonDialogueBubbleNode:AutoRemove()
	local delayTime = math.max(1, math.min(3.5, 0.1 * string.len(self.descr)))
	local actionSeq = cc.Sequence:create(
		cc.DelayTime:create(delayTime),
		cc.CallFunc:create(function ()
			self:DoRemoveBubble()
		end)
	)
	self:runAction(actionSeq)
end
--[[
移除
--]]
function CommonDialogueBubbleNode:DoRemoveBubble()
	local actionSeq = cc.Sequence:create(
		cc.FadeTo:create(0.25, 0),
		cc.Hide:create(),
		cc.CallFunc:create(function ()
			self:RemoveBubble()
		end)
	)
	self:runAction(actionSeq)

	local arrowActionSeq = cc.Sequence:create(
		cc.FadeTo:create(0.25, 0)
	)
	self.viewData.arrow:runAction(arrowActionSeq)
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function CommonDialogueBubbleNode:onTouchBegan_(touch, event)
	if not self.vaild then return false end
	if self:TouchedSelf(touch:getLocation()) then
		self:RemoveBubble()
		return false
	else
		return true
	end
end
function CommonDialogueBubbleNode:onTouchMoved_(touch, event)

end
function CommonDialogueBubbleNode:onTouchEnded_(touch, event)

end
function CommonDialogueBubbleNode:onTouchCanceled_( touch, event )
	print('here touch canceled by some unknown reason')
end
--[[
是否触摸到了提示板
@params touchPos cc.p 触摸位置
@return _ bool 
--]]
function CommonDialogueBubbleNode:TouchedSelf(touchPos)
	local boundingBox = self:getBoundingBox()
	local fixedP = cc.CSceneManager:getInstance():getRunningScene():convertToNodeSpace(
		self:getParent():convertToWorldSpace(cc.p(boundingBox.x, boundingBox.y))
	)
	if cc.rectContainsPoint(cc.rect(fixedP.x, fixedP.y, boundingBox.width, boundingBox.height), touchPos) then
		return true
	end
	return false
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------
function CommonDialogueBubbleNode:onEnter()

end
function CommonDialogueBubbleNode:onExit()

end
function CommonDialogueBubbleNode:onCleanup()

end


return CommonDialogueBubbleNode
