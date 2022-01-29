--[[
包厢纪念品详情popup
--]]
local PrivateRoomSouvenirDetailPopup = class('PrivateRoomSouvenirDetailPopup', function ()
    local node = CLayout:create(display.size)
    node.name = 'privateRoom.PrivateRoomSouvenirDetailPopup'
    node:enableNodeEvents()
    return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local RES_DICT = {
    BG = _res('ui/common/common_bg_14.png'),
    GOODS_BG = _res('ui/privateRoom/vip_wall_bg_goods_default.png'),
}
function PrivateRoomSouvenirDetailPopup:ctor( ... )
    self.args = unpack({...})
    self.goodsId = checkint(self.args.goodsId)
    self:InitUI()
    self:EnterAction()
end
--[[
init ui
--]]
function PrivateRoomSouvenirDetailPopup:InitUI()
    local goodsId = self.goodsId
    local giftConf = CommonUtils.GetConfig('privateRoom', 'guestGift', goodsId)
    local function CreateView()
        local size = cc.size(494, 530)
        local view = CLayout:create(size)
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2, {scale9 = true, size = size})
        view:addChild(bg, 1) 
        local goodsBg = display.newImageView(RES_DICT.GOODS_BG, 100, size.height - 100)
        view:addChild(goodsBg, 3)
        local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(goodsId), goodsBg:getContentSize().width / 2, goodsBg:getContentSize().height / 2)
        goodsIcon:setScale(0.55)
        goodsBg:addChild(goodsIcon)
        local goodsName = display.newLabel(size.width - 60, size.height - 100, {text = giftConf.name, ap = cc.p(1, 0.5), fontSize = 28, color = '#845229'})
        view:addChild(goodsName, 5)
        local descrNode = require('Game.views.privateRoom.PrivateRoomSouvenirDescrNode').new({goodsId = goodsId, size = cc.size(400, 310)})
        descrNode:setAnchorPoint(cc.p(0.5, 0))
        descrNode:setPosition(cc.p(size.width / 2, 60))
        view:addChild(descrNode, 5)
        
        return {
            view             = view,
        }
    end
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function (sender) 
        PlayAudioByClickClose()
        uiMgr:GetCurrentScene():RemoveDialog(self)
    end)
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view, 1)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
    end, __G__TRACKBACK__)
end
function PrivateRoomSouvenirDetailPopup:EnterAction()
	self.viewData.view:setScale(0.8)
	self.viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackOut:create(
				cc.ScaleTo:create(0.3, 1)
			)
		)
	)
end
return PrivateRoomSouvenirDetailPopup