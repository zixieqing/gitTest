--[[
滚动数字功能节点
--]]
local ScrollNumNode = class('ScrollNumNode', function ()
	local node = CLayout:create()
	node.name = 'Game.views.activity.ScrollNumNode'
	node:enableNodeEvents()
	return node
end)


function ScrollNumNode:ctor( ... )
	local args = unpack({...})
	self.curNo = 0
    self.resultNumber = 0
	local size = cc.size(90, 150)
	self:setContentSize(size)
	local curNoNode = display.newImageView(_res("ui/home/activity/luckycat/activity_fortunecat_bg_rumber_0.png"),45, 75)
	self:addChild(curNoNode,1)
	local tempNode = display.newImageView( _res("ui/home/activity/luckycat/activity_fortunecat_bg_rumber_1.png"),45, -75)
	self:addChild(tempNode,1)
	self.curNoNode = curNoNode
	self.tempNode = tempNode
    self.isStart = true
end

function ScrollNumNode:ScrollNumber( targetNo, isJump )
    self.resultNumber = targetNo
	-- self:stopAllActions()
    local tag = self:getTag()
    local startTime = os.time()
    local duration = tag * 0.8
	if not isJump then
		self:runAction(cc.RepeatForever:create(
			cc.Sequence:create(
				cc.CallFunc:create(function (  )
                    local curTime = os.time()
                    if self.isStart then
                        local span = curTime - startTime
                        if span >= duration then
                            self:StartScroll(targetNo, true)
                        else
                            self:StartScroll(9, isJump)
                        end
                    end
			end))
			)
		)
	else
		self:StartScroll(targetNo, isJump)
	end
end

function ScrollNumNode:StartScroll( targetNo, isJump )
	local x, y = self:getPosition()
	if self.curNo == targetNo then
		-- self:stopAllActions()
    	self.curNoNode:setTexture(_res(string.format("ui/home/activity/luckycat/activity_fortunecat_bg_rumber_%d.png", self.curNo)))
		self:setPosition(cc.p(x, 68))
        if isJump then
            self.isStart = true
            self:stopAllActions()
        else
            self.curNo = 0
        end
        return
    end

    local end_callback = cc.CallFunc:create(function()
    	self.curNoNode:setTexture(_res(string.format("ui/home/activity/luckycat/activity_fortunecat_bg_rumber_%d.png", self.curNo)))
    	self:setPosition(cc.p(x, 68))
        self.isStart = true
    end)

    --刷新数字
    if isJump then
        self.curNo = targetNo
        self.tempNode:setTexture(_res(string.format("ui/home/activity/luckycat/activity_fortunecat_bg_rumber_%d.png", targetNo)))
    else
    	self.curNo = (self.curNo + 1) % 10
    	self.tempNode:setTexture(_res(string.format("ui/home/activity/luckycat/activity_fortunecat_bg_rumber_%d.png", self.curNo)))
    end
    self.isStart = false
    self:runAction(cc.Sequence:create(cc.MoveTo:create(0.05, cc.p(x, y + 150)), end_callback))
end

return ScrollNumNode
