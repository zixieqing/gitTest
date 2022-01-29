local BugNode = class('BugNode', function()
    return display.newLayer(0, 0, {ap = display.CENTER, color = cc.c4b(0,0,0,0), enable = true, name = 'BugNode'})
end)


function BugNode:ctor(areaId, friendData)
    local areaIndex   = checkint(areaId)
    local BUG_SIZE    = cc.size(100,100)
    local AREA_ROWS   = 2
    local AREA_COLS   = 3
    local AREA_WIDTH  = 370
    local AREA_HEIGHT = 200
    local areaRow     = math.ceil(areaIndex / AREA_COLS)
    local areaCol     = (areaIndex - 1) % AREA_COLS + 1
    local areaCenterX = DRAG_AREA_RECT.x + DRAG_AREA_RECT.width / AREA_COLS * (areaCol - 0.5)
    local areaCenterY = DRAG_AREA_RECT.y + DRAG_AREA_RECT.height/ AREA_ROWS * (AREA_ROWS - areaRow + 0.5)
    
    -- create bug node
    local bugNode    = self
    local bugRadiusW = AREA_WIDTH/2 - BUG_SIZE.width/2
    local bugRadiusH = AREA_HEIGHT/2 - BUG_SIZE.height/2
    bugNode:setPositionX(areaCenterX + math.random(-bugRadiusW, bugRadiusW))
    bugNode:setPositionY(areaCenterY + math.random(-bugRadiusH, bugRadiusH))
    bugNode:setContentSize(BUG_SIZE)
    bugNode:setTag(areaIndex)

    local bugSpinePath    = 'avatar/ui/spine/cangying'
    local shareSpineCache = SpineCache(SpineCacheName.GLOBAL)
    if not shareSpineCache:hasSpineCacheData(bugSpinePath) then
        shareSpineCache:addCacheData(bugSpinePath, bugSpinePath, 1)
    end
    local bugSpine = shareSpineCache:createWithName(bugSpinePath)
    bugSpine:setPosition(cc.p(BUG_SIZE.width/2, 0))
    bugSpine:setScaleX(math.random(100) > 50 and 0.3 or -0.3)
    bugSpine:setScaleY(0.3)
    bugSpine:setAnimation(0, 'run2', true)
    bugSpine:setTag(101)
    bugNode:addChild(bugSpine)

    display.commonUIParams(bugNode, {cb = function(sender)
        local AvatarFeedMdt = require('Game.mediator.AvatarFeedMediator')
        local bugAreaId     = sender:getTag()
        local delegate      = AvatarFeedMdt.new({id = bugAreaId, type = 4, friendData = friendData})
        AppFacade.GetInstance():RegistMediator(delegate)
    end})

    self.bugSpine = bugSpine
end


function BugNode:clean()
    local bugNode  = self
    local bugSpine = self.bugSpine
    bugSpine:setToSetupPose()
    bugSpine:setAnimation(0, 'die', true)

    local actTime = 0.5
    bugNode:setTouchEnabled(false)
    bugNode:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.RotateBy:create(actTime, 180),
            cc.ScaleTo:create(actTime, 0)
        }),
        cc.RemoveSelf:create()
    }))
end


return BugNode
