--[[
    卡牌预览入口节点
    @params table {
        confId int 卡牌配表id(和皮肤id二选一)
        skinId int 皮肤id(和卡牌配表id二选一)
        cardDrawChangeType  int 立绘切换类型 （1： 立绘只能切换为默认卡牌皮肤或突破后的皮肤 2: 所有卡牌皮肤都可切换 ）
    }
--]]
local VIEW_SIZE = cc.size(120, 120)
---@class CardPreviewEntranceNode
local CardPreviewEntranceNode = class('CardPreviewEntranceNode', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'common.CardPreviewEntranceNode'
	node:enableNodeEvents()
	return node
end)


local RES_DICT = {
    PREVIEW_CARD_BTN_FRAME = _res('ui/common/preview_card_btn_frame.png'),
    PREVIEW_CARD_BTN_UNDER = _res('ui/common/preview_card_btn_under.png'),
}

local CreateView     = nil
local CreateCardHead = nil

function CardPreviewEntranceNode:ctor(...)
    self.args = unpack({...}) or {}
    self.cb = self.args.cb
    self.cardDrawChangeType = self.args.cardDrawChangeType or 1
    self:InitUI()
    self:RefreshUI(self.args)
end

function CardPreviewEntranceNode:InitUI()
    xTry(function ( )
		self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)
        self:InitView()
	end, __G__TRACKBACK__)
end

function CardPreviewEntranceNode:InitView()
    self:InitAction()
end

function CardPreviewEntranceNode:InitAction()
    local viewData = self:GetViewData()
    display.commonUIParams(viewData.btn, {cb = handler(self, self.OnClickBtnAction)})
end

function CardPreviewEntranceNode:RefreshUI(args)
    self.args    = args
    local skinId = args.skinId
    local confId = args.confId
    local goodsId = args.goodsId
    local headImg = nil
    if goodsId then
        --- 传goodsId 默认转为 卡牌id
        local goodsData = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
        self.args.confId = goodsData.cardId or goodsData.id
        headImg = CardUtils.GetCardHeadPathByCardId(self.args.confId)
    elseif skinId then
        self.args.skinId = skinId
        headImg = CardUtils.GetCardHeadPathBySkinId(skinId)
    elseif confId then
        self.args.confId = confId
        headImg = CardUtils.GetCardHeadPathByCardId(confId)
    end
    self.cb = args.cb
    local viewData = self:GetViewData()
    if headImg then
        viewData.headNode:setTexture(headImg)
    end
end

CreateView = function (size)
    local view = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})
    local underBg = display.newImageView(RES_DICT.PREVIEW_CARD_BTN_UNDER, size.width / 2, size.height / 2, {ap = display.CENTER})
    view:addChild(underBg)
    local headClipNode = cc.ClippingNode:create()
    headClipNode:setCascadeOpacityEnabled(true)
    headClipNode:setPosition(cc.p(size.width / 2, size.height / 2))
    view:addChild(headClipNode)
    local stencilNode = display.newNSprite(_res('ui/battle/battle_game1_bg_role.png'), 0, 0)
    stencilNode:setScale(0.8)
    headClipNode:setAlphaThreshold(0.1)
    headClipNode:setStencil(stencilNode)
    local headNode = display.newImageView('headPath', 0, 0)
    headNode:setScale(0.6)
    headClipNode:addChild(headNode)

    local btn = display.newButton(size.width / 2, size.height / 2, {ap = display.CENTER, n = RES_DICT.PREVIEW_CARD_BTN_FRAME})
    view:addChild(btn, 1)
    return {
        view = view,
        headNode = headNode,
        btn = btn,
    }
end

function CardPreviewEntranceNode:OnClickBtnAction()
    PlayAudioByClickNormal()
    if self.cb then
        self.cb()
    else
        local layer = require('common.CardPreviewView').new(self.args)
        display.commonUIParams(layer, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
        app.uiMgr:GetCurrentScene():AddDialog(layer)
    end
end

function CardPreviewEntranceNode:ResetClickAction(cb)
    self.viewData.btn:setOnClickScriptHandler(cb)
end

function CardPreviewEntranceNode:GetViewData()
    return self.viewData
end


return CardPreviewEntranceNode
