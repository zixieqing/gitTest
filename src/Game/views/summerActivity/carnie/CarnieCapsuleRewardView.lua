--[[
游乐园（夏活）领奖 view
--]]
local CarnieCapsuleRewardView = class('CarnieCapsuleRewardView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CarnieCapsuleRewardView'
    node:enableNodeEvents()
    return node
end)

function CarnieCapsuleRewardView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function CarnieCapsuleRewardView:InitUI()
    local function CreateView()
        local bgSize = display.size
        local view = CLayout:create(bgSize)
        return {
            view             = view,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        
    end)
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end
return CarnieCapsuleRewardView