--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 规则弹窗
]]
local CommonDialog    = require('common.CommonDialog')
local TTGameRulePopup = class('TripleTriadGameCardRulePopup', CommonDialog)

local RES_DICT = {
    BG_FRAME          = _res('ui/common/common_bg_9.png'),
    COM_TITLE         = _res('ui/common/common_bg_title_2.png'),
    RULE_PVE_FRAME    = _res('ui/ttgame/common/cardgame_common_label_kingsrule.png'),
    RULE_NAME_FRAME   = _res('ui/ttgame/common/cardgame_rule_label_name.png'),
    RULE_CUTTING_LINE = _res('ui/ttgame/common/cardgame_common_line_1.png'),
}

local CreateView = nil


function TTGameRulePopup:InitialUI()
    -- create view
    self.viewData = CreateView(self.args.isPveRule)

    -- update view
    self.ruleDataList_ = self.args.ruleList or {}
    self:reloadRuleList()
end


CreateView = function(isPveRule)
    local size = cc.size(560, 640)
    local view = display.newLayer(0, 0, {size = size, bg = RES_DICT.BG_FRAME, scale9 = true})

    local titleBar = display.newButton(size.width/2, size.height - 20, {n = RES_DICT.COM_TITLE, enable = false})
    display.commonLabelParams(titleBar, fontWithColor(3, {text = isPveRule and __('牌王规则') or __('今日规则'), offset = cc.p(0, -2)}))
    view:addChild(titleBar)

    local pveRuleTipsSize  = cc.size(size.width - 70, 36)
    local pveRuleTipsLayer = display.newImageView(RES_DICT.RULE_PVE_FRAME, size.width/2, size.height - 55, {ap = display.CENTER_TOP, size = pveRuleTipsSize, scale9 = true})
    pveRuleTipsLayer:addChild(display.newLabel(pveRuleTipsSize.width/2, pveRuleTipsSize.height/2, fontWithColor(18, {text = __('牌王规则会替代今日规则')})))
    pveRuleTipsLayer:setVisible(isPveRule)
    view:addChild(pveRuleTipsLayer)

    local pveTipsRuleH = isPveRule and (pveRuleTipsSize.height + 10) or 0
    local ruleListView = CListView:create(cc.size(pveRuleTipsSize.width, size.height - 55 - pveTipsRuleH))
    ruleListView:setAnchorPoint(display.CENTER_BOTTOM)
    ruleListView:setPosition(size.width/2, 10)
    view:addChild(ruleListView)
    
    return {
        view         = view,
        ruleListView = ruleListView,
    }
end


function TTGameRulePopup:getViewData()
    return self.viewData
end


function TTGameRulePopup:reloadRuleList()
    local ruleListView = self:getViewData().ruleListView
    ruleListView:removeAllNodes()

    for index, ruleId in ipairs(self.ruleDataList_) do
        local ruleConfInfo   = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.RULE_DEFINE, ruleId)
        local ruleIconNode   = TTGameUtils.GetRuleIconNode(ruleId)
        local ruleNameLabel  = display.newLabel(0, 0, fontWithColor(3, {text = tostring(ruleConfInfo.name), ap = display.LEFT_CENTER}))
        local ruleDescrLabel = display.newLabel(0, 0, fontWithColor(16, {text = tostring(ruleConfInfo.descr), ap = display.LEFT_TOP, w = 365}))
        local ruleDescrSize  = display.getLabelContentSize(ruleDescrLabel)
        
        local ruleCellSize = cc.size(ruleListView:getContentSize().width, math.max(ruleDescrSize.height + 70, 125))
        local ruleCellNode = display.newLayer(0, 0, {size = ruleCellSize, color1 = cc.r4b(80)})
        ruleListView:insertNodeAtLast(ruleCellNode)
        -- nameBar
        local nameBarSize = cc.size(ruleCellSize.width, 32)
        local nameBarNode = display.newImageView(RES_DICT.RULE_NAME_FRAME, ruleCellSize.width/2, ruleCellSize.height - 12, {size = nameBarSize, ap = display.CENTER_TOP, scale9 = true})
        ruleCellNode:addChild(nameBarNode)

        -- name label
        ruleNameLabel:setPosition(nameBarNode:getPositionX() - nameBarSize.width/2 + 15, nameBarNode:getPositionY() - nameBarSize.height/2)
        ruleCellNode:addChild(ruleNameLabel)

        -- rule icon
        ruleIconNode:setAnchorPoint(display.LEFT_TOP)
        ruleIconNode:setPosition(ruleNameLabel:getPositionX() + 5, ruleNameLabel:getPositionY() - 25)
        ruleCellNode:addChild(ruleIconNode)

        -- descr label
        ruleDescrLabel:setPosition(ruleIconNode:getPositionX() + ruleIconNode:getContentSize().width + 23, ruleIconNode:getPositionY() - 5)
        ruleCellNode:addChild(ruleDescrLabel)

        -- cutting line
        ruleCellNode:addChild(display.newImageView(RES_DICT.RULE_CUTTING_LINE, ruleCellSize.width/2, 0, {size = cc.size(ruleCellSize.width - 10, 2), scale9 = true}))
    end
    ruleListView:reloadData()
end


return TTGameRulePopup
