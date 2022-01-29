--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 等级解锁弹窗
]]
local CommonDialog      = require('common.CommonDialog')
local TTGameUnlockPopup = class('TripleTriadGameStarUnlockPopup', CommonDialog)

local RES_DICT = {
    BG_FRAME          = _res('ui/common/common_bg_9.png'),
    COM_TITLE         = _res('ui/common/common_bg_title_2.png'),
    CARD_STAR_N       = _res('ui/ttgame/deck/cardgame_deck_ico_star.png'),
    RULE_NAME_FRAME   = _res('ui/ttgame/common/cardgame_rule_label_name.png'),
    RULE_CUTTING_LINE = _res('ui/ttgame/common/cardgame_common_line_1.png'),
}

local CreateView = nil


function TTGameUnlockPopup:InitialUI()
    -- init vars
    local deckLimitConfFile  = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.DECK_LIMIT)
    local starUnlockDataList = {}
    for i = 1, table.nums(deckLimitConfFile) do
        table.insert(starUnlockDataList, deckLimitConfFile[tostring(i)] or {})
    end
    
    -- create view
    self.viewData = CreateView()

    -- update view
    self:setStarUnlockDatas(starUnlockDataList)
end


CreateView = function()
    local size = cc.size(560, 640)
    local view = display.newLayer(0, 0, {size = size, bg = RES_DICT.BG_FRAME, scale9 = true})

    local titleBar = display.newButton(size.width/2, size.height - 20, {n = RES_DICT.COM_TITLE, enable = false})
    display.commonLabelParams(titleBar, fontWithColor(3, {text = __('等级说明'), offset = cc.p(0, -2)}))
    view:addChild(titleBar)

    local unlockListView = CListView:create(cc.size(size.width - 70, size.height - 55))
    unlockListView:setAnchorPoint(display.CENTER_BOTTOM)
    unlockListView:setPosition(size.width/2, 10)
    -- unlockListView:setBackgroundColor(cc.r4b(250))
    view:addChild(unlockListView)
    
    return {
        view           = view,
        unlockListView = unlockListView,
    }
end


function TTGameUnlockPopup:getViewData()
    return self.viewData
end


function TTGameUnlockPopup:getStarUnlockDatas()
    return self.starUnlockDatas_
end
function TTGameUnlockPopup:setStarUnlockDatas(datas)
    self.starUnlockDatas_ = datas or {}
    self:updateStarUnlockList_()
end


function TTGameUnlockPopup:updateStarUnlockList_()
    local unlockListView = self:getViewData().unlockListView
    unlockListView:removeAllNodes()

    local hasBattleCardNum = app.ttGameMgr:getHasBattleCardNum()
    for index, unlockData in ipairs(self:getStarUnlockDatas()) do

        local unlockCellSize = cc.size(unlockListView:getContentSize().width, 250)
        local unlockCellNode = display.newLayer(0, 0, {size = unlockCellSize, color1 = cc.r4b(80)})
        unlockListView:insertNodeAtLast(unlockCellNode)

        local titlePos  = cc.p(unlockCellSize.width/2, unlockCellSize.height - 40)
        local titleSize = cc.size(unlockCellSize.width, 32)
        local titleNode = display.newImageView(RES_DICT.RULE_NAME_FRAME, titlePos.x, titlePos.y, {size = titleSize, ap = display.CENTER, scale9 = true})
        unlockCellNode:addChild(titleNode)

        local cardStarImg = display.newImageView(RES_DICT.CARD_STAR_N, unlockCellSize.width/2 - titleSize.width/2 + 30, titlePos.y + 5)
        unlockCellNode:addChild(cardStarImg)

        
        local starLimit   = checkint(unlockData.starLimit)
        local starLabel   = display.newLabel(0, 0, fontWithColor(20, {fontSize = 26, outline = '#a7894c',  ap = display.CENTER,  text = TTGameUtils.GetCardLevelText(starLimit)}))
        starLabel:setPosition(cardStarImg:getPositionX(), cardStarImg:getPositionY())
        unlockCellNode:addChild(starLabel)

        -- cutting line
        unlockCellNode:addChild(display.newImageView(RES_DICT.RULE_CUTTING_LINE, unlockCellSize.width/2, cardStarImg:getPositionY() - 58, {size = cc.size(unlockCellSize.width - 10, 2), scale9 = true}))

        local collectNum  = checkint(unlockData.collectNum)
        local isUnlocked  = hasBattleCardNum >= collectNum
        local descrColor  = isUnlocked and '#56b507' or '#bababa'
        local unlockLabel = display.newLabel(0, 0, fontWithColor(5, {color = '#a2d672',  ap = display.RIGHT_CENTER, text = __('已解锁')}))
        local cardsLabel  = display.newLabel(0, 0, fontWithColor(4, {color = '#FFFFFF',  ap = display.RIGHT_CENTER, text = string.fmt('%1 / %2', hasBattleCardNum, collectNum)}))
        local tipsLabel   = display.newLabel(0, 0, fontWithColor(5, {color = '#c1824c',  ap = display.LEFT_CENTER,  text = string.fmt(__('收集_num_张战牌后解锁：'), {_num_ = collectNum})}))
        local descrLabel  = display.newLabel(0, 0, fontWithColor(4, {color = descrColor, ap = display.LEFT_TOP,     text = string.fmt(__('能带一张任意星级的战牌，其他战牌星级不可超过_limit_星级。'), {_limit_ = starLimit}), w = titleSize.width - 60}))
        unlockLabel:setPosition(unlockCellSize.width/2 + titleSize.width/2 - 25, titlePos.y)
        cardsLabel:setPosition(unlockCellSize.width/2 + titleSize.width/2 - 20, titlePos.y)
        tipsLabel:setPosition(starLabel:getPositionX(), titlePos.y - 35)
        descrLabel:setPosition(tipsLabel:getPositionX() + 10, tipsLabel:getPositionY() - 25)
        unlockCellNode:addChild(unlockLabel)
        unlockCellNode:addChild(cardsLabel)
        unlockCellNode:addChild(tipsLabel)
        unlockCellNode:addChild(descrLabel)
        unlockLabel:setVisible(isUnlocked)
        cardsLabel:setVisible(not isUnlocked)
    end
    unlockListView:reloadData()
end


return TTGameUnlockPopup
