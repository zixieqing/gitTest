--[[
冰箱人物解锁页面View
--]]
local IceRoomFoodView = class('IceRoomFoodView', function()
	local node = CLayout:create()
	node.name = 'Game.views.IceRoomFoodView'
	node:enableNodeEvents()
    return node
end)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local RES_DICT = {
	BG   = 'ui/iceroom/refresh_bg_foods.png',
    FOOD_PANEL_BG = "ui/iceroom/refresh_bg_goods.png",
}

local IceRoomFoodCell = require("Game.views.IceRoomFoodCell")

function IceRoomFoodView:ctor(...)
    local arg = unpack({...})
    self:setContentSize(display.size)
    self.isAction = true
    local sceneRoot = uiMgr:GetCurrentScene()
    local function CreateView()
        local contentView = CColorView:create(cc.c4b(100,100,100,0))
        contentView:setContentSize(display.size)
        contentView:setOnClickScriptHandler(function(sender)
            --执行关闭操作
            if self.isAction == false then
                sceneRoot:VigourUpdate(false)
                self:runAction(cc.RemoveSelf:create()) --移出操作
            end
        end)
        contentView:setTouchEnabled(true)
        display.commonUIParams(contentView, {po = display.center})
        self:addChild(contentView,1)

        local touchLayer = CColorView:create(cc.c4b(100,100,100,0))
        touchLayer:setContentSize(cc.size(display.width, 234))
        touchLayer:setTouchEnabled(true)
        display.commonUIParams(touchLayer, {po = cc.p(display.cx, 67)})
        self:addChild(touchLayer,2)

        local size = cc.size(824,134)
        --食物列表的展示逻辑
        local view = CLayout:create(size)
        --添加标题
        local bg = display.newImageView(_res(RES_DICT.BG), display.width * 0.5, -44)
        display.commonUIParams(bg, {ap = display.CENTER_BOTTOM, po = cc.p(size.width * 0.5, -44)})
        view:addChild(bg)

        --食物面板
        local bgImage = display.newSprite(_res(RES_DICT.FOOD_PANEL_BG))
        display.commonUIParams(bgImage, {po = cc.p(size.width * 0.5, 67)})
        view:addChild(bgImage,1)

        local titleLabel = display.newLabel(size.width * 0.5, size.height * 0.35, {
            fontSize = 20, color = "4c4c4c", text = __("给飨灵使用魔法食物恢复其新鲜度")
        })
        view:addChild(titleLabel, 2)

        local foodNodes = {}
        for k,v in pairs(VIGOUR_RECOVERY_GOODS_ID) do
            local cell = IceRoomFoodCell.new({id = v})
            display.commonUIParams(cell, {po = cc.p(220 + (k - 1) * 0.16 * size.width + 10, size.height * 0.9)})
            view:addChild(cell, 3)
            table.insert( foodNodes, cell )
        end
        return {
            view    = view,
            -- bottomImage = bg,
            titleLabel = titleLabel,
            foodNodes  = foodNodes,
        }
    end
    
    self.viewData = CreateView()
    display.commonUIParams(self.viewData.view, {ap = display.CENTER_BOTTOM, po = cc.p(display.cx, - 134)})
    self:addChild(self.viewData.view,10)
    sceneRoot:VigourUpdate(true)
    self:runAction(cc.Sequence:create(
        cc.TargetedAction:create(self.viewData.view, cc.MoveTo:create(0.2, cc.p(display.cx, 0))),
        cc.CallFunc:create(function()
            self.isAction = false
        end)
    ))
end
--[[
    更新各个有效道具的数量
--]]
function IceRoomFoodView:UpdateNumbers(  )
     if self.viewData.foodNodes then
        for k,v in pairs(self.viewData.foodNodes) do
            v:UpdateCount() --更新数量
        end
     end
end

return IceRoomFoodView
