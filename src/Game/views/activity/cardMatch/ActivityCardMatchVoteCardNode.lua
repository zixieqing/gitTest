--[[
飨灵投票初赛卡牌节点
--]]
local display = display
local VIEW_SIZE = display.size
---@class ActivityCardMatchVoteCardNode
local ActivityCardMatchVoteCardNode = class('ActivityCardMatchVoteCardNode', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'Game.views.activity.cardMatch.ActivityCardMatchVoteCardNode'
    node:enableNodeEvents()
    return node
end)

local CreateView     = nil
local CreateCell_  = nil
local CreateGoodNode = nil

local RES_DICT = {
    CARDMATCH_TOP1_BG   = _res('ui/home/activity/cardMatch/cardmatch_top1_bg.png'),
    CARDMATCH_TOP2_BG   = _res('ui/home/activity/cardMatch/cardmatch_top2_bg.png'),
    CARDMATCH_ICON_TOP1 = _res('ui/home/activity/cardMatch/cardmatch_icon_top1.png'),
    CARDMATCH_ICON_TOP2 = _res('ui/home/activity/cardMatch/cardmatch_icon_top2.png'),
    CARDMATCH_HEAD_BG   = _res('ui/home/activity/cardMatch/cardmatch_head_bg.png'),
    CARDMATCH_CARD_BG   = _res('ui/home/activity/cardMatch/cardmatch_card_bg.png'),
}

function ActivityCardMatchVoteCardNode:ctor( ... )
    self.args = unpack({...}) or {}

    self:InitUI()
end
--[[
init ui
--]]
function ActivityCardMatchVoteCardNode:InitUI()
    xTry(function ( )
        local size = self.args.size or cc.size(294, 144)
        self:setContentSize(size)

        self.viewData_ = CreateView(size)
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
    
end

function ActivityCardMatchVoteCardNode:RefreshUI(data, cardId)
    data = data or {}
    local viewData = self:GetViewData()
    local skinId = CardUtils.GetCardSkinId(cardId)
    local headPath = CardUtils.GetCardHeadPathBySkinId(skinId)
    viewData.cardHead:setTexture(headPath)

    local cardConf    = CardUtils.GetCardConfig(cardId) or {}
    display.commonLabelParams(viewData.cardNameLabel, {text = tostring(cardConf.name)})

    local rank = checkint(data.rank)
    local isShowRankIcon = rank == 1 or rank == 2
    local topIcon      = viewData.topIcon
    topIcon:setVisible(isShowRankIcon)
    if isShowRankIcon then
        topIcon:setTexture(RES_DICT['CARDMATCH_ICON_TOP' .. rank])
    end

    display.commonLabelParams(viewData.curTicketNum, {text = string.format('%s票', checkint(data.score))})
end

CreateView = function (size)
    local middleX, middleY = size.width * 0.5, size.height * 0.5
    local view = display.newLayer(middleX, middleY, {size = size, ap = display.CENTER})
    
    local bg = display.newNSprite(RES_DICT.CARDMATCH_CARD_BG, middleX, middleY)
    view:addChild(bg)

    local topIcon = display.newNSprite(RES_DICT.CARDMATCH_ICON_TOP2, 72, size.height - 16)
    view:addChild(topIcon, 1)
    topIcon:setVisible(false)

    local cardNameLabel = display.newLabel(210, size.height - 34, fontWithColor(16, {ap = display.CENTER}))
    view:addChild(cardNameLabel)

    local headBg = display.newNSprite(RES_DICT.CARDMATCH_HEAD_BG, 18, middleY, {ap = display.LEFT_CENTER})
    view:addChild(headBg)

    local headPath = CardUtils.GetCardHeadPathBySkinId(CardUtils.DEFAULT_HEAD_ID)
    local cardHead = display.newNSprite(headPath, 54, 54)
    cardHead:setScale(0.56)
    headBg:addChild(cardHead)

    local curTicketNum = display.newLabel(210, size.height * 0.5, {fontSize = 22, color = '#8b3b00'})
    view:addChild(curTicketNum)

    return {
        view          = view,
        bg            = bg,
        topIcon       = topIcon,
        cardNameLabel = cardNameLabel,
        headBg        = headBg,
        cardHead      = cardHead,
        curTicketNum  = curTicketNum,
    }
end

function ActivityCardMatchVoteCardNode:GetViewData()
    return self.viewData_
end

return ActivityCardMatchVoteCardNode