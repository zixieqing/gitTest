--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 转盘View
--]]
local AssemblyActivityWheelView = class('AssemblyActivityWheelView', function ()
    local node = CLayout:create(display.size)
    node.name = 'activity.assemblyActivity.AssemblyActivityWheelView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {

}

function AssemblyActivityWheelView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function AssemblyActivityWheelView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.COMMON_BG_POINT, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- mask --
    
        return {
            view                = view,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
进入动画
--]]
function AssemblyActivityWheelView:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
--[[
关闭动画
--]]
function AssemblyActivityWheelView:CloseAction()
    local viewData = self:GetViewData()
    viewData.view:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0.2),
            cc.CallFunc:create(function()
                local scene = app.uiMgr:GetCurrentScene()
                scene:RemoveDialog(self)
            end)
        )
    )
end
--[[
获取viewData
--]]
function AssemblyActivityWheelView:GetViewData()
    return self.viewData
end
return AssemblyActivityWheelView