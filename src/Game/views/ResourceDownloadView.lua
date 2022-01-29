--[[
	召回系统UI
--]]
local GameScene = require( "Frame.GameScene" )

local ResourceDownloadView = class('ResourceDownloadView', GameScene)

function ResourceDownloadView:ctor()
    --创建页面
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
end


return ResourceDownloadView