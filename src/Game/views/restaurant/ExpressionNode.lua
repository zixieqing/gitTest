local ExpressionNode = class('ExpressionNode', function()
    local node = CLayout:create()
    node:enableNodeEvents()
    node.name = 'ExpressionNode'
    return node
end)


function ExpressionNode:ctor(...)
    local args = unpack({...})
    local size = cc.size(76, 76)
    self:setContentSize(size)
    -- self:setBackgroundColor(cc.c4b(254,10,100,100))
    self.id = args.id
    self.cb = args.cb
    local prefix = string.format('avatar/animate/common_ico_expression_%d',checkint(self.id))
    --吃的东西的契合度
    if utils.isExistent(prefix .. '.json') then
        local animateNode = sp.SkeletonAnimation:create(string.format("%s.json", prefix),string.format("%s.atlas",prefix), 0.6)
        animateNode:setAnimation(0, 'idle', true)
        display.commonUIParams(animateNode, {ap = display.CENTER_BOTTOM,po = cc.p(size.width * 0.5 + 4 , - 4)})
        self:addChild(animateNode,10)
    end
    self:setName("EXPRESSION_TAG_NAME")

    local shareFacade = AppFacade.GetInstance()
    shareFacade:RegistObserver("EXPRESSION_OBSERVER", mvc.Observer.new(function(stage, signal)
        self.touchListener_:setEnabled(true)
    end, self))
end

function ExpressionNode:onTouchBegan(touch, event)
    if self.id == 5 then
        local parentNode = self:getParent()
        if parentNode then
            local touchEndPos = parentNode:convertToNodeSpace(touch:getLocation())
            local rect = self:getBoundingBox()
            if cc.rectContainsPoint(rect, touchEndPos) then
                return true
            else
                return false
            end
        else
            return false end else
        return false
    end
end
function ExpressionNode:onTouchEnded(touch, event)
    if self.id == 5 then
        --霸王餐
        local parentNode = self:getParent()
        if parentNode then
            local touchEndPos = parentNode:convertToNodeSpace(touch:getLocation())
            local rect = self:getBoundingBox()
            if cc.rectContainsPoint(rect, touchEndPos) then
                if self.cb then
                    self.touchListener_:setEnabled(false)
                    self.cb()
                end
            end
        end
    end
end


function ExpressionNode:onEnter()
    self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:setSwallowTouches(true)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithFixedPriority(self.touchListener_, 19)
end


function ExpressionNode:onExit()
    if self.touchListener_ then
        self:getEventDispatcher():removeEventListener(self.touchListener_)
    end
end

function ExpressionNode:onCleanup()
    local shareFacade = AppFacade.GetInstance()
    shareFacade:UnRegistObserver("EXPRESSION_OBSERVER",self)
end

return ExpressionNode


