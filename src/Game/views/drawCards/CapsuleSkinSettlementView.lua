--[[
卡池结算页面view
@params table {
        rewards table 
        例：    {
                    {goodsId = 250123, num = 1},
                    {goodsId = 101002, num = 1},

                    {goodsId = 250093, num = 1, turnGoodsId = 890006, turnGoodsNum = 100},
                    {goodsId = 101011, num = 1, turnGoodsId = 890006, turnGoodsNum = 5},

                    {goodsId = 250103, num = 1},
                    {goodsId = 101013, num = 1},

                    {goodsId = 250153, num = 1},
                    {goodsId = 101026, num = 1},

                    {goodsId = 250283, num = 1},
                    {goodsId = 101037, num = 1},
                }
    }
--]]
local VIEW_SIZE = display.size
local CapsuleSkinSettlementView = class('CapsuleSkinSettlementView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'Game.views.drawCards.CapsuleSkinSettlementView'
    node:enableNodeEvents()
    return node
end)

local RES_DICT = {
    COMMON_BTN_ORANGE                = _res('ui/common/common_btn_orange.png'),
    DRAW_CARD_BG_TEXT_TIPS           = _res('ui/home/capsule/draw_card_bg_text_tips.png'),
    SUMMON_SKIN_BG_ANIMATION         =  _res('ui/home/capsuleNew/skinCapsule/summon_skin_bg_animation.jpg'),
}

local uiMgr = app.uiMgr
local CreateView = nil

function CapsuleSkinSettlementView:ctor( ... )
    local args = unpack({...}) or {}
    self.rewardIndex = 1
    self.rewards = args.rewards or {}
    self.maxRewardIndex = #self.rewards
    self:InitUI()
    self:RefreshUI()
end

function CapsuleSkinSettlementView:InitUI()
    xTry(function ( )
		self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)
        self:InitView()
	end, __G__TRACKBACK__)
end

function CapsuleSkinSettlementView:InitView()
    local viewData   = self:GetViewData()
    local confirmBtn = viewData.confirmBtn
    display.commonUIParams(confirmBtn, {cb = handler(self, self.OnClickConfirmBtnAction)})
end

function CapsuleSkinSettlementView:RefreshUI()
    local viewData       = self:GetViewData()
    local contentUILayer = viewData.contentUILayer

    local reward = self.rewards[self.rewardIndex] or {}
    self.rewardIndex = self.rewardIndex + 1

    local goodsId   = reward.goodsId
    local goodsType = CommonUtils.GetGoodTypeById(goodsId)

    local skinCell   = viewData.skinCell
    if skinCell then
        skinCell:setVisible(false)
    end

    local avatarCell = viewData.avatarCell
    if avatarCell then
        avatarCell:setVisible(false)
    end

    if goodsType == GoodsType.TYPE_CARD_SKIN then
        if skinCell == nil then
            skinCell = require('Game.views.drawCards.CapsuleSkinSettlementSkinCell').new(reward)
            skinCell:setPosition(display.center)
            contentUILayer:addChild(skinCell)

            viewData.skinCell = skinCell
        else
            skinCell:RefreshUI(reward)
            skinCell:setVisible(true)
        end
        
    elseif goodsType == GoodsType.TYPE_AVATAR then
        
        if avatarCell == nil then
            avatarCell = require('Game.views.drawCards.CapsuleSkinSettlementAvatarCell').new(reward)
            avatarCell:setPosition(display.center)
            contentUILayer:addChild(avatarCell)

            viewData.avatarCell = avatarCell
        else
            avatarCell:RefreshUI(reward)
            avatarCell:setVisible(true)
        end
    end

    self:UpdateGoodsGetTipLabel(viewData, reward)
end

function CapsuleSkinSettlementView:UpdateGoodsGetTipLabel(viewData, reward)
    local goodsGetTipBg     = viewData.goodsGetTipBg
    local turnGoodsId = checkint(reward.turnGoodsId)
    goodsGetTipBg:setVisible(turnGoodsId > 0)

    if turnGoodsId > 0 then
        local goodsId     = checkint(reward.goodsId)
        local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
        local turnGoodsConfig = CommonUtils.GetConfig('goods', 'goods', turnGoodsId) or {}
        display.commonLabelParams(viewData.goodsGetTipLabel, {text = string.fmt(__('_good_name_已获得，已经把_good_name_转变成_good_turn_name_*_num_'),
            {_good_name_ = tostring(goodsConfig.name), _good_turn_name_ = tostring(turnGoodsConfig.name), _num_ = checkint(reward.turnGoodsNum)})})
    end
    
end

CreateView = function(size)
    local view = display.newLayer()
    view:addChild(display.newLayer(0, 0, {size = size, enable = true, color = cc.c4b(0,0,0,0)}))
    
    view:addChild(display.newImageView(RES_DICT.SUMMON_SKIN_BG_ANIMATION, size.width / 2, size.height / 2, {ap = display.CENTER}))

    local contentUILayer = display.newLayer()
    view:addChild(contentUILayer)

    local goodsGetTipSize = cc.size(297, 106)
    local goodsGetTipBg = display.newNSprite(RES_DICT.DRAW_CARD_BG_TEXT_TIPS, display.SAFE_R - 10, size.height - 40, {ap = display.RIGHT_TOP, scale9 = true, size = goodsGetTipSize})
    contentUILayer:addChild(goodsGetTipBg)

    local goodsGetTipLabel = display.newLabel(20, goodsGetTipSize.height - 15, {ap = display.LEFT_TOP, fontSize = 20, color = '#faf0db', text = '', w = 260})
    goodsGetTipBg:addChild(goodsGetTipLabel)

    local confirmBtn = display.newButton(display.SAFE_R - 50, 40, {ap = display.RIGHT_BOTTOM, n = RES_DICT.COMMON_BTN_ORANGE})
    display.commonLabelParams(confirmBtn, fontWithColor('14', {text = __('确定')}))
    view:addChild(confirmBtn)

    return {
        view              = view,
        confirmBtn        = confirmBtn,
        contentUILayer    = contentUILayer,
        goodsGetTipBg     = goodsGetTipBg,
        goodsGetTipLabel  = goodsGetTipLabel,
    }
end

function CapsuleSkinSettlementView:OnClickConfirmBtnAction(sender)

    if self.rewardIndex > self.maxRewardIndex then
        self:setVisible(false)
        self:runAction(cc.RemoveSelf:create())
    else
        self:RefreshUI()
    end
end

function CapsuleSkinSettlementView:GetCellPathByGoodType()
    
end

function CapsuleSkinSettlementView:GetViewData()
    return self.viewData
end

return CapsuleSkinSettlementView
