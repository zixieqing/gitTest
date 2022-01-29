--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 战斗动画弹窗
]]
local TTGameBattleAnimatePopup = class('TripleTriadGameBattleAnimatePopup', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameBattleAnimatePopup'})
end)

local RES_DICT = {
    START_BG_FRAME = _res('ui/ttgame/battle/cardgame_battle_bg_start.png'),
}

local ANIMATE_TYPE = {
    START = 'start',
    RULE  = 'rule',
}

function TTGameBattleAnimatePopup:ctor(args)
    self:setPosition(display.center)
    self:setAnchorPoint(display.CENTER)
    app.uiMgr:GetCurrentScene():AddDialog(self)

    -- init vars
    self.animationType_  = args.aniType
    self.closeCallback_  = args.closeCB
    self.isControllable_ = true

    -- block layer
    self:addChild(display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,0), enable = true}))

    -- create view
    if ANIMATE_TYPE.START == self.animationType_ then
        self:initStartView()
    elseif ANIMATE_TYPE.RULE == self.animationType_ then
        self:initRuleView(args.ruleList)
    else
        self:close()
    end
end


-------------------------------------------------
-- start animate

function TTGameBattleAnimatePopup:initStartView()
    local view = display.newLayer()
    local size = view:getContentSize()
    self:addChild(view)

    local blackLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,100)})
    view:addChild(blackLayer)

    local startFrame = display.newImageView(RES_DICT.START_BG_FRAME, size.width/2, size.height/2)
    view:addChild(startFrame)

    local startLabel = display.newLabel(size.width/2, size.height/2, fontWithColor(7, {fontSize = 50, text = __('对局开始')}))
    view:addChild(startLabel)

    -- init animation
    startLabel:setScale(0)
    startLabel:setOpacity(0)
    startFrame:setScaleY(0)
    blackLayer:setOpacity(0)

    -- show animation
    local SHOW_TIME = 0.2
    local HIDE_TIME = 0.2
    self:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(blackLayer, cc.EaseCubicActionOut:create(cc.FadeTo:create(SHOW_TIME, 150))),
            cc.TargetedAction:create(startFrame, cc.EaseCubicActionOut:create(cc.ScaleTo:create(SHOW_TIME, 1, 1))),
            cc.TargetedAction:create(startLabel, cc.Sequence:create(
                cc.Spawn:create(
                    cc.EaseQuarticActionOut:create(cc.RotateTo:create(SHOW_TIME, -30)),
                    cc.EaseQuarticActionOut:create(cc.ScaleTo:create(SHOW_TIME, 2.5)),
                    cc.EaseQuarticActionOut:create(cc.FadeIn:create(SHOW_TIME))
                ),
                cc.Spawn:create(
                    cc.EaseBackOut:create(cc.RotateTo:create(0.2, 0)),
                    cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1))
                )
            ))
        ),
        cc.DelayTime:create(0.2),
        cc.Spawn:create(
            cc.TargetedAction:create(blackLayer, cc.EaseCubicActionIn:create(cc.FadeOut:create(HIDE_TIME))),
            cc.TargetedAction:create(startFrame, cc.EaseCubicActionIn:create(cc.ScaleTo:create(HIDE_TIME, 1, 0))),
            cc.TargetedAction:create(startLabel, cc.EaseCubicActionIn:create(cc.ScaleTo:create(HIDE_TIME, 0, 0)))
        ),
        cc.CallFunc:create(function()
            self:close()
        end)
    ))
end


-------------------------------------------------
-- start animate

function TTGameBattleAnimatePopup:initRuleView(ruleList)
    local ruleList = checktable(ruleList)

    local view  = display.newLayer()
    local size  = view:getContentSize()
    self:addChild(view)

    local ruleLayer = display.newLayer()
    view:addChild(ruleLayer)

    local SPACE_W   = 200
    local offsetX   = size.width/2 - ((#ruleList-1) * SPACE_W)/2
    local ruleDatas = {}
    for index, ruleId in ipairs(ruleList or {}) do
        local ruleNode = TTGameUtils.GetRuleIconNode(ruleId)
        ruleNode:setPositionX(offsetX + (index-1) * SPACE_W)
        ruleNode:setPositionY(size.height/2)
        ruleNode:setAnchorPoint(display.CENTER)
        ruleNode:setScale(2)
        ruleLayer:addChild(ruleNode)
        table.insert(ruleDatas,{
            node = ruleNode,
            spos = cc.p(ruleNode:getPosition()),
            hpos = cc.p(ruleNode:getPositionX() - size.width/2, ruleNode:getPositionY()),
            ipos = cc.p(ruleNode:getPositionX() + size.width/2, ruleNode:getPositionY()),
        })
    end

    -- init animation
    for _, ruleData in ipairs(ruleDatas) do
        ruleData.node:setPosition(ruleData.ipos)
    end

    -- show animation
    local ruleActs = {}
    for index, ruleData in ipairs(ruleDatas) do
        table.insert(ruleActs, cc.Sequence:create(
            cc.TargetedAction:create(ruleData.node, cc.DelayTime:create(0.05 * index)),
            cc.TargetedAction:create(ruleData.node, cc.MoveTo:create(0.2, ruleData.spos)),
            cc.TargetedAction:create(ruleData.node, cc.DelayTime:create(0.5)),
            cc.TargetedAction:create(ruleData.node, cc.MoveTo:create(0.2, ruleData.hpos))
        ))
    end
    self:runAction(cc.Sequence:create(
        cc.Spawn:create(ruleActs),
        cc.CallFunc:create(function()
            self:close()
        end)
    ))
end


-------------------------------------------------
-- public

function TTGameBattleAnimatePopup:close()
    if self.closeCallback_ then
        self.closeCallback_()
    end
    self:runAction(cc.RemoveSelf:create())
end


return TTGameBattleAnimatePopup
