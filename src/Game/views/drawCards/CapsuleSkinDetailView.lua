--[[
皮肤抽卡物品详情view
--]]
local CapsuleSkinDetailView = class('CapsuleSkinDetailView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsuleSkinDetailView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG               = _res('ui/home/capsuleNew/common/summon_skin_bg_animation.jpg'),
}
--[[
@params rewards map {
    goodsId int 道具id
    num     int 道具数量
}
@params showAnimation bool 是否显示动画
@params cb function 确定按钮点击回调
--]]
function CapsuleSkinDetailView:ctor( ... )
    local args = unpack({...}) or {}
    self.reward = args.reward or {}
    self.showAnimation = args.showAnimation or false
    self.cb = args.cb
    self:InitUI()
    self:RefreshUI()
end
--[[
init ui
--]]
function CapsuleSkinDetailView:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        local currentLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER})
        view:addChild(currentLayer, 5)
        local bg = display.newImageView(RES_DICT.BG, display.cx, display.cy)
        view:addChild(bg, 1)
        return {
            view             = view,
            currentLayer     = currentLayer,
        }
    end
    xTry(function ( )
        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
        eaterLayer:setContentSize(display.size)
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setPosition(utils.getLocalCenter(self))
        self:addChild(eaterLayer, -1)
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end
--[[
refresh ui
--]]
function CapsuleSkinDetailView:RefreshUI()
    local reward = self.reward
    local showAnimation = self.showAnimation
    
    local viewData = self.viewData
    local currentLayer = viewData.currentLayer
    local goodsId   = reward.goodsId
    local goodsType = CommonUtils.GetGoodTypeById(goodsId)
    local params = {
        reward = reward,
        cb = handler(self, self.ConfirmButtonCallback),
        showAnimation = showAnimation
    }
    if goodsType == GoodsType.TYPE_CARD_SKIN then
        local skinCell = require('Game.views.drawCards.CapsuleSkinSettlementSkinCell').new(params)
        skinCell:setPosition(display.center)
        currentLayer:addChild(skinCell)
        viewData.skinCell = skinCell   
    else
        local avatarCell = require('Game.views.drawCards.CapsuleSkinSettlementAvatarCell').new(params)
        avatarCell:setPosition(display.center)
        currentLayer:addChild(avatarCell)
        viewData.avatarCell = avatarCell
    end
end
--[[

--]]
function CapsuleSkinDetailView:ConfirmButtonCallback( sender )
    PlayAudioByClickNormal()
    if self.cb then
        self.cb()
    end
    self:runAction(cc.RemoveSelf:create())
end
return CapsuleSkinDetailView