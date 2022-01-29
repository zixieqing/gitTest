--[[
包厢主题预览view
--]]
local PrivateRoomThemePreviewView = class('PrivateRoomThemePreviewView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.PrivateRoomThemePreviewView'
    node:enableNodeEvents()
    return node
end)
function PrivateRoomThemePreviewView:ctor( ... )
    self.args = unpack({...})
    self.themeId = self.args.themeId or 330001
    self.wallData = self.args.wallData or {}
    self:InitUI()
end
--[[
init ui
--]]
function PrivateRoomThemePreviewView:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
		-- themeNode
		local themeNode = require('Game.views.privateRoom.PrivateRoomThemeNode').new()
		themeNode:setPosition(size.width / 2, size.height / 2)
		view:addChild(themeNode, 1)
        return {
            bgSize           = bgSize,
            view             = view,
            themeNode        = themeNode,
        }
    end
    xTry(function ( )
        -- eaterLayer
        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setPosition(cc.p(display.cx, display.cy))
        self:addChild(eaterLayer, -1)
        self.eaterLayer = eaterLayer
        self.eaterLayer:setOnClickScriptHandler(function () 
            self:runAction(cc.RemoveSelf:create())
        end)
        self.viewData = CreateView( )
        self:setContentSize(self.viewData.bgSize)
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self.viewData.themeNode:SetTheme(self.themeId)
        self.viewData.themeNode:RefreshWall(self.wallData)
        self.viewData.themeNode:SetWallEnabled(false)
    end, __G__TRACKBACK__)
end
return PrivateRoomThemePreviewView