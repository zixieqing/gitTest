--[[
 * author : liuzhipeng
 * descpt : 活动 新手福利 礼包View
--]]
local NoviceWelfareGiftView = class('NoviceWelfareGiftView', function ()
    local node = CLayout:create(cc.size(1150, 600))
    node.name = 'NoviceWelfareGiftView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    GOODS_BG 	 =  _res('ui/common/common_bg_goods.png'),
}

function NoviceWelfareGiftView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function NoviceWelfareGiftView:InitUI()
    local function CreateView()
        local size = self:getContentSize()
        local view = CLayout:create(size)
        -- mask --
        local mask = display.newLayer(size.width / 2 ,size.height / 2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- mask --
        
        -- 背景
        local bg = display.newImageView(RES_DICT.GOODS_BG, size.width / 2 + 45, size.height / 2 - 3, {size = cc.size(1020, 565), scale9 = true})
        view:addChild(bg, 1)
        -- 礼包
        local giftNodeList = {}
        for i = 1, 7 do
            local giftNode = require('Game.views.activity.noviceWelfare.NoviceWelfareGiftNode').new()
            giftNode:setPosition(cc.p(100, 100))
            if i <= 3 then
                giftNode:setPosition(cc.p(386 + (i - 1) * 234, size.height / 2 + 135))
            else
                giftNode:setPosition(cc.p(264 + (i - 4) * 234, size.height / 2 - 135))
            end
            view:addChild(giftNode, 5)
            table.insert(giftNodeList, giftNode)
        end
        return {
            view                = view,
            giftNodeList        = giftNodeList
        }
    end

    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
    end, __G__TRACKBACK__)
end
--[[
刷新礼包节点
@params map {
    chests list 礼包数据
    today  int  当前日期
}
--]]
function NoviceWelfareGiftView:RefreshGiftNodes( params )
    local viewData = self:GetViewData()
    for i, node in ipairs(viewData.giftNodeList) do
        node:RefreshNode(i, params.chests[i], params.today, params.nextDayLeftSeconds, params.callback)
    end
end
--[[
更新节点剩余时间
--]]
function NoviceWelfareGiftView:RefreshGiftNodeTimeLabel( index, leftSeconds )
    local viewData = self:GetViewData()
    if not viewData.giftNodeList[index] then return end
    viewData.giftNodeList[index]:RefreshTimeLabel(leftSeconds)
end
--[[
获取viewData
--]]
function NoviceWelfareGiftView:GetViewData()
    return self.viewData
end
return NoviceWelfareGiftView