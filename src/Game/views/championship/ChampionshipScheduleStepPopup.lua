--[[
 * author : kaishiqi
 * descpt : 武道会 - 投票竞猜视图
]]
local ChampionshipScheduleStepPopup = class('ChampionshipScheduleStepPopup', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipScheduleStepPopup', enableEvent = true, ap = ui.cc})
end)

local RES_DICT = {
    CHAMPION_OVER_LIGHT    = _res('ui/championship/home/budo_pvp_light.png'),
    PROMOTION_RESULT_SPINE = _spn('ui/championship/home/budo_common_ending'),
    PROMOTION_PAPER_SPINE  = _spn('ui/championship/home/budo_common_paper'),
    AUDITIONS_OPEN_SPINE   = _spn('ui/championship/home/budo_common_stick'),
    AUDITIONS_FLAG_BLUE    = _res('ui/championship/closed/budo_bg_common_spine_bule.png'),
    AUDITIONS_FLAG_RED     = _res('ui/championship/closed/budo_bg_common_spine_red.png'),
    AUDITIONS_NPC_IMAGE    = _res('ui/championship/closed/budo_bg_common_spine_npc.png'),
    DIALOGUE_FRAME         = _res('arts/stage/ui/dialogue_bg_2.png'),
}

local POPUP_VIEW_DEFINE = {
    'updatePromotionInView_',   -- 1：晋级赛-入选
    'updatePromotionOutView_',  -- 2：晋级赛-落选
    'updateChampionTakeView_',  -- 3：武道会-胜利
    'updateChampionOverView_',  -- 4：武道会-结束
    'updateAuditionsOpenView_', -- 5：海选赛-开始
}

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT


function ChampionshipScheduleStepPopup:ctor(args)
    local initArgs       = checktable(args)
    self.popupType_      = checkint(initArgs.type)
    self.isControllable_ = true
    
    -- bind model
    self.mainProxy_ = app:RetrieveProxy(MAIN_PROXY_NAME)

    -- create view
    self.viewData_ = ChampionshipScheduleStepPopup.CreateView()
    self:addChild(self.viewData_.view)

    local contentFunc = POPUP_VIEW_DEFINE[self.popupType_]
    if self[contentFunc] then
        self[contentFunc](self, self:getViewData().contentLayer)
    end

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBlockLayerHandler_))
end


function ChampionshipScheduleStepPopup:onCleanup()
end


function ChampionshipScheduleStepPopup:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- public

function ChampionshipScheduleStepPopup:close()
    self:runAction(cc.RemoveSelf:create())
end


-------------------------------------------------
-- private

function ChampionshipScheduleStepPopup:updatePromotionInView_(ownerNode)
    local resultSpine = ui.spine({path = RES_DICT.PROMOTION_RESULT_SPINE, init = 'anni_draw_cutin', loop = false})
    ownerNode:addList(resultSpine):alignTo(nil, ui.cc)
    
    local textLayer = ui.layer({ap = ui.cc})
    ownerNode:addList(textLayer):alignTo(nil, ui.cc, {offsetX = 320})
    
    local overText  = __('恭喜入选')
    local textGroup = textLayer:addList({
        ui.label({fnt = FONT.D1, fontSize = 100, color = '#F58829', text = overText, ml = 5, mt = 5}),
        ui.label({fnt = FONT.D20, fontSize = 100, color = '#FFD879', outline = '#B13B16', text = overText}),
    })
    ui.flowLayout(cc.sizep(textLayer, ui.cc), textGroup, {type = ui.flowC, ap = ui.cc})

    -- init action
    textLayer:setScaleY(0)
    self:getViewData().blackLayer:setOpacity(0)

    -- run action
    self.isControllable_ = false
    ownerNode:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(textLayer, cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.2, 1, 1))),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeTo:create(0.2, 150))
        ),
        cc.DelayTime:create(0.6),
        cc.Spawn:create(
            cc.TargetedAction:create(textLayer, cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.4, 1, 0))),
            cc.TargetedAction:create(textLayer, cc.EaseQuarticActionIn:create(cc.FadeOut:create(0.4))),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeOut:create(0.4))
        ),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            self:close()
        end)
    ))
end


function ChampionshipScheduleStepPopup:updatePromotionOutView_(ownerNode)
    local resultSpine = ui.spine({path = RES_DICT.PROMOTION_RESULT_SPINE, init = 'anni_draw_cutin2', loop = false})
    ownerNode:addList(resultSpine):alignTo(nil, ui.cc)
    
    local textLayer = ui.layer({ap = ui.cc})
    ownerNode:addList(textLayer):alignTo(nil, ui.cc, {offsetX = 320})
    
    local overText  = __('遗憾落选')
    local textGroup = textLayer:addList({
        ui.label({fnt = FONT.D1, fontSize = 100, color = '#91888D', text = overText, ml = 5, mt = 5}),
        ui.label({fnt = FONT.D20, fontSize = 100, color = '#A7A5A3', outline = '#353434', text = overText}),
    })
    ui.flowLayout(cc.sizep(textLayer, ui.cc), textGroup, {type = ui.flowC, ap = ui.cc})

    -- init action
    textLayer:setScaleY(0)
    self:getViewData().blackLayer:setOpacity(0)

    -- run action
    self.isControllable_ = false
    ownerNode:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(textLayer, cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.2, 1, 1))),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeTo:create(0.2, 150))
        ),
        cc.DelayTime:create(0.6),
        cc.Spawn:create(
            cc.TargetedAction:create(textLayer, cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.4, 1, 0))),
            cc.TargetedAction:create(textLayer, cc.EaseQuarticActionIn:create(cc.FadeOut:create(0.4))),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeOut:create(0.4))
        ),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            self:close()
        end)
    ))
end


function ChampionshipScheduleStepPopup:updateChampionTakeView_(ownerNode)
    local resultSpine = ui.spine({path = RES_DICT.PROMOTION_RESULT_SPINE, init = 'anni_draw_cutin', loop = false})
    ownerNode:addList(resultSpine):alignTo(nil, ui.cc)
    
    local textLayer = ui.layer({ap = ui.cc})
    ownerNode:addList(textLayer):alignTo(nil, ui.cc, {offsetX = 320})
    
    local overText  = __('恭喜夺冠')
    local textGroup = textLayer:addList({
        ui.label({fnt = FONT.D1, fontSize = 100, color = '#F58829', text = overText, ml = 5, mt = 5}),
        ui.label({fnt = FONT.D20, fontSize = 100, color = '#FFD879', outline = '#B13B16', text = overText}),
    })
    ui.flowLayout(cc.sizep(textLayer, ui.cc), textGroup, {type = ui.flowC, ap = ui.cc})
    
    local paperSpine = ui.spine({path = RES_DICT.PROMOTION_PAPER_SPINE, init = 'idle'})
    ownerNode:addList(paperSpine):alignTo(nil, ui.cc)

    -- init action
    textLayer:setScaleY(0)
    self:getViewData().blackLayer:setOpacity(0)

    -- run action
    self.isControllable_ = false
    ownerNode:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(textLayer, cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.2, 1, 1))),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeTo:create(0.2, 150))
        ),
        cc.DelayTime:create(0.6),
        cc.Spawn:create(
            cc.TargetedAction:create(textLayer, cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.4, 1, 0))),
            cc.TargetedAction:create(textLayer, cc.EaseQuarticActionIn:create(cc.FadeOut:create(0.4))),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeOut:create(0.4))
        ),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            self:close()
        end)
    ))
end


function ChampionshipScheduleStepPopup:updateChampionOverView_(ownerNode)
    local lightImg = ui.image({img = RES_DICT.CHAMPION_OVER_LIGHT})
    ownerNode:addList(lightImg):alignTo(nil, ui.cc)
    lightImg:runAction(cc.RepeatForever:create(
        cc.RotateBy:create(10, 180)
    ))
    
    local textLayer = ui.layer({ap = ui.cc})
    ownerNode:addList(textLayer):alignTo(nil, ui.cc)
    
    local overText  = __('凌云争锋比赛已结束')
    local textGroup = textLayer:addList({
        ui.label({fnt = FONT.D1, fontSize = 50, color = '#7E452A', text = overText, ml = 5, mt = 5}),
        ui.label({fnt = FONT.D20, fontSize = 50, color = '#FDDA7D', text = overText}),
    })
    ui.flowLayout(cc.sizep(textLayer, ui.cc), textGroup, {type = ui.flowC, ap = ui.cc})

    -- init action
    lightImg:setScale(0)
    textLayer:setScale(0)
    self:getViewData().blackLayer:setOpacity(0)

    -- run action
    self.isControllable_ = false
    ownerNode:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(lightImg, cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.2, 1))),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeTo:create(0.2, 150))
        ),
        cc.TargetedAction:create(textLayer, cc.Sequence:create(
            cc.ScaleTo:create(0.1, -0.5, 0.5),
            cc.ScaleTo:create(0.1, 0, 0.8),
            cc.ScaleTo:create(0.2, 1, 1)
        )),
        cc.DelayTime:create(1.2),
        cc.Spawn:create(
            cc.TargetedAction:create(textLayer, cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.4, 1, 0))),
            cc.TargetedAction:create(lightImg, cc.EaseQuarticActionIn:create(cc.FadeOut:create(0.4))),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeOut:create(0.4))
        ),
        cc.CallFunc:create(function()
            self:close()
        end)
    ))
end


function ChampionshipScheduleStepPopup:updateAuditionsOpenView_(ownerNode)
    local leftFlagImg  = ui.image({p = cc.rep(cc.sizep(ownerNode, ui.lc), display.SAFE_L - 60, 60), img = RES_DICT.AUDITIONS_FLAG_BLUE, ap = ui.lb})
    local rightFlagImg = ui.image({p = cc.rep(cc.sizep(ownerNode, ui.rc), -display.SAFE_L + 60, 60), img = RES_DICT.AUDITIONS_FLAG_RED, ap = ui.rb})
    ownerNode:add(leftFlagImg)
    ownerNode:add(rightFlagImg)

    local openSpine = ui.spine({path = RES_DICT.AUDITIONS_OPEN_SPINE})
    ownerNode:addList(openSpine):alignTo(nil, ui.cc)

    local npcGroup = ownerNode:addList({
        ui.image({img = RES_DICT.AUDITIONS_NPC_IMAGE}),
        ui.image({img = RES_DICT.DIALOGUE_FRAME, ml = 380, mt = 100}),
        ui.label({fnt = FONT.D3, color = '#540E0E', ml = 380, mt = 100, w = 320}),
    })
    ui.flowLayout(cc.rep(cc.sizep(ownerNode, ui.cc), -330, -130), npcGroup, {type = ui.flowC, ap = ui.cc})
    
    -- init action
    local seasonId         = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SEASON_ID)
    local seasonText       = string.fmt(__('欢迎参加第_num_届凌云争锋'), {_num_ = seasonId - (FOOD.CHAMPIONSHIP.IS_XIAOBO_FIX() and 1 or 0)})
    local npcImage         = npcGroup[1]
    local dialogueFrame    = npcGroup[2]
    local dialogueLabel    = npcGroup[3]
    local npcImageShowPos  = cc.p(npcImage:getPositionX(), npcImage:getPositionY())
    local npcImageHidePos  = cc.p(npcImage:getPositionX(), npcImage:getPositionY() - display.height)
    local openSpineShowPos = cc.p(openSpine:getPositionX(), openSpine:getPositionY())
    local openSpineHidePos = cc.p(openSpine:getPositionX(), openSpine:getPositionY() + display.height)
    self:getViewData().blackLayer:setOpacity(0)
    openSpine:setPosition(openSpineHidePos)
    npcImage:setPosition(npcImageHidePos)
    dialogueLabel:updateLabel({text = seasonText})
    dialogueLabel:setOpacity(0)
    dialogueFrame:setScaleY(0)
    rightFlagImg:setScaleX(0)
    leftFlagImg:setScaleX(0)

    -- run action
    self.isControllable_ = false
    ownerNode:runAction(cc.Sequence:create(
        cc.DelayTime:create(app:RetrieveMediator('ChampionshipOffSeasonMediator') and 1.2 or 0.01),
        cc.Spawn:create(
            cc.TargetedAction:create(openSpine, cc.EaseQuarticActionOut:create(cc.MoveTo:create(0.4, openSpineShowPos))),
            cc.TargetedAction:create(npcImage, cc.EaseQuarticActionOut:create(cc.MoveTo:create(0.4, npcImageShowPos))),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeTo:create(0.4, 150))
        ),
        cc.Spawn:create(
            cc.TargetedAction:create(leftFlagImg, cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1, 1))),
            cc.TargetedAction:create(rightFlagImg, cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1, 1)))
        ),
        cc.TargetedAction:create(dialogueFrame, cc.EaseQuarticActionOut:create(cc.ScaleTo:create(0.2, 1, 1))),
        cc.TargetedAction:create(dialogueLabel, cc.EaseQuarticActionOut:create(cc.FadeIn:create(0.2))),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            openSpine:setAnimation(0, 'budo_common_stick', false)

            local shakeOffset  = 12
            local shakeActList = {}
            for i = 1, 10 do
                local shakeOffsetX = math.random(-shakeOffset, shakeOffset)
                local shakeOffsetY = math.random(-shakeOffset, shakeOffset)
                shakeActList[i] = cc.MoveTo:create(0.02, cc.rep(openSpineShowPos, shakeOffsetX, shakeOffsetY))
            end
            table.insert(shakeActList, cc.MoveTo:create(0.02, openSpineShowPos))
            openSpine:runAction(cc.Sequence:create(
                cc.DelayTime:create(0.7),
                cc.Sequence:create(shakeActList)
            ))
        end),
        cc.DelayTime:create(0.9),
        cc.CallFunc:create(function()
            dialogueLabel:updateLabel({text = __('<海选赛>现在开始！！')})
        end),
        cc.DelayTime:create(0.4),
        cc.Spawn:create(
            cc.TargetedAction:create(dialogueLabel, cc.EaseQuarticActionIn:create(cc.FadeOut:create(0.2))),
            cc.TargetedAction:create(dialogueFrame, cc.EaseQuarticActionIn:create(cc.ScaleTo:create(0.2, 1, 0))),
            cc.TargetedAction:create(leftFlagImg, cc.EaseBackIn:create(cc.ScaleTo:create(0.2, 0, 1))),
            cc.TargetedAction:create(rightFlagImg, cc.EaseBackIn:create(cc.ScaleTo:create(0.2, 0, 1))),
            cc.TargetedAction:create(openSpine, cc.EaseQuarticActionIn:create(cc.MoveTo:create(0.3, openSpineHidePos))),
            cc.TargetedAction:create(npcImage, cc.EaseQuarticActionIn:create(cc.MoveTo:create(0.3, npcImageHidePos))),
            cc.TargetedAction:create(self:getViewData().blackLayer, cc.FadeOut:create(0.4))
        ),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            self:close()
        end)
    ))
end


-------------------------------------------------
-- handler

function ChampionshipScheduleStepPopup:onClickBlockLayerHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipScheduleStepPopup.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- bg [black | block]
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- content layer
    local contentLayer = ui.layer()
    centerLayer:add(contentLayer)


    return {
        view         = view,
        blackLayer   = backGroundGroup[1],
        blockLayer   = backGroundGroup[2],
        --           = center
        contentLayer = contentLayer,
    }
end


return ChampionshipScheduleStepPopup
