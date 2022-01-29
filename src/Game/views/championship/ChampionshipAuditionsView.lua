--[[
 * author : kaishiqi
 * descpt : 武道会 - 海选赛视图
]]
local ChampionshipAuditionsView = class('ChampionshipAuditionsView', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipAuditionsView', enableEvent = true})
end)

local RES_DICT = {
    --             = top
    CEILING_FRAME  = _res('ui/championship/auditions/budo_bg_common_top_head.png'),
    COUNTDOWN_BAR  = _res('ui/championship/auditions/budo_pvp_bg_reward_number_2.png'),
    --             = center
    MATCH_TABLE    = _res('ui/championship/auditions/budo_bg_common_spine_table.png'),
    MATCH_VS       = _res('ui/championship/auditions/starplan_vs_icon_vs.png'),
    PLATE_BLUE     = _res('ui/championship/auditions/budo_sea_bg_base_blue.png'),
    PLATE_RED      = _res('ui/championship/auditions/budo_sea_bg_base_red.png'),
    EDIT_TEAM      = _res('ui/championship/auditions/budo_sea_btn_add_ren.png'),
    FUNCITON_FRAME = _res('ui/championship/auditions/budo_bg_common_list.png'),
    RANK_BTN       = _res('ui/championship/auditions/budo_ico_common_rank.png'),
    REWARD_BTN     = _res('ui/championship/auditions/budo_ico_common_reward.png'),
    SHOP_BTN       = _res('ui/championship/auditions/budo_ico_common_shop.png'),
    --             = bottom
    TEAM_FRAME     = _res('ui/championship/auditions/budo_sea_bg_bottom_ren.png'),
    TEXT_TIPS_BAR  = _res('ui/championship/auditions/common_bg_float_text.png'),
    BATTLE_FRAME   = _res('ui/championship/auditions/budo_sea_bg_bottom_right.png'),
    SCORE_FRAME    = _res('ui/championship/auditions/budo_sea_bg_bottom_left.png'),
    SCORE_TITLE    = _res('ui/championship/auditions/murder_main_btn_title_2.png'),
    COM_ADD_BTN    = _res('ui/common/common_btn_add.png'),
    --             = card cell
    CARD_CAPTAIN   = _res('ui/championship/auditions/team_ico_captain.png'),
    CARD_CELL_BG   = _res('ui/common/kapai_frame_bg_nocard.png'),
    CARD_CELL_FA   = _res('ui/common/kapai_frame_nocard.png'),
    CARD_CELL_EDIT = _res('ui/common/maps_fight_btn_pet_add.png'),
}

local ACTION_ENUM = {
    RELOAD_AUDITION_TEAM = 1,
}

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT


function ChampionshipAuditionsView:ctor(args)
    -- create view
    self.viewData_ = ChampionshipAuditionsView.CreateView()
    self:addChild(self.viewData_.view)

    -- bind model
    self.mainProxy_   = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.viewBindMap_ = {
        [MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN]              = self.onUpdateRefreshTime_,
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP]   = self.onUpdateScheduleStep_,
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TEAM]   = self.onUpdateAuditionsTeam_, -- clean all / update all
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_SCORE]  = self.onUpdateAuditionsScore_,
        [MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TICKET] = self.onUpdateAuditionsTicket_,
    }

    -- update view
    local handlerList = VoProxy.EventBind(MAIN_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
    self:updateAuditionsQuest_()
    self:updateSeasonTitle_()
end


function ChampionshipAuditionsView:onCleanup()
    VoProxy.EventUnbind(MAIN_PROXY_NAME, self.viewBindMap_, self)
end


function ChampionshipAuditionsView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- private

function ChampionshipAuditionsView:updateSeasonTitle_()
    local seasonId   = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SEASON_ID)
    local seasonText = string.fmt(__('第_num_届凌云争锋'), {_num_ = seasonId - (FOOD.CHAMPIONSHIP.IS_XIAOBO_FIX() and 1 or 0)})
    self:getViewData().seasonLabel:updateLabel({text = seasonText})
end


function ChampionshipAuditionsView:updateAuditionsQuest_()
    local auditionsQuestId   = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_QUEST_ID)
    local auditionsQuestConf = CONF.CHAMPIONSHIP.AUDITION_QUEST:GetValue(auditionsQuestId)
    local auditionsMonsterId = checkint(checktable(auditionsQuestConf.monsterInfo)[1])

    local monsterAvatar = ui.cardSpineNode({confId = auditionsMonsterId, scale = 0.6, init = 'idle', flipX = true})
    self:getViewData().opponentAvatarLayer:addAndClear(monsterAvatar):alignTo(nil, ui.cb)
end


function ChampionshipAuditionsView:updateBattleButton_()
    local teamSize  = self.mainProxy_:size(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TEAM)
    local ticketNum = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TICKET)
    self:getViewData().battleButton:setEnabled(teamSize > 0 and ticketNum > 0)
end


-------------------------------------------------
-- handler

function ChampionshipAuditionsView:onUpdateAuditionsTeam_(signal)
    if not self:getActionByTag(ACTION_ENUM.RELOAD_AUDITION_TEAM) then
        self:runAction(cc.CallFunc:create(function()

            local TEAM_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TEAM
            local teamProxy   = self.mainProxy_:get(TEAM_STRUCT)
            local leaderUuid  = 0
        
            -- update all cardCell
            for cardIndex, cardCellVD in ipairs(self:getViewData().cardCellVDList) do
                local cardUuid = teamProxy:get(TEAM_STRUCT.CARD_UUID, cardIndex)
                cardCellVD.headNode:setVisible(cardUuid > 0)
        
                if cardUuid > 0 then
                    leaderUuid = leaderUuid == 0 and cardUuid or leaderUuid
                    cardCellVD.headNode:RefreshUI({cardData = app.gameMgr:GetCardDataById(cardUuid)})
                end
            end
        
            -- update editTeamIcon
            local hasTeamLeader = leaderUuid > 0
            self:getViewData().editTeamIcon:setVisible(not hasTeamLeader)
        
            -- update leaderAvatar
            if hasTeamLeader then
                local leaderAvatar = ui.cardSpineNode({uuid = leaderUuid, scale = 0.6, init = 'idle'})
                self:getViewData().playerAvatarLayer:addAndClear(leaderAvatar):alignTo(nil, ui.cb)
            else
                self:getViewData().playerAvatarLayer:removeAllChildren()
            end
        
            -- update battleButton
            self:updateBattleButton_()

        end)):setTag(ACTION_ENUM.RELOAD_AUDITION_TEAM)
    end
end


function ChampionshipAuditionsView:onUpdateAuditionsTicket_(signal)
    local auditionsTicket = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TICKET)
    self:getViewData().ticketRLabel:reload({
        {fnt = FONT.D16, text = string.fmt(__('剩余次数：_num_'), {_num_ = auditionsTicket})},
        {img = RES_DICT.COM_ADD_BTN, scale = 0.8, ap = cc.p(0, 0.2)},
    })

    -- update battleButton
    self:updateBattleButton_()
end


function ChampionshipAuditionsView:onUpdateAuditionsScore_(signal)
    local auditionsScore = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_SCORE)
    self:getViewData().scoreLabel:updateLabel({text = tostring(auditionsScore)})
end


function ChampionshipAuditionsView:onUpdateScheduleStep_(signal)
    local scheduleStep  = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    local stepTitleFunc = FOOD.CHAMPIONSHIP.MATCH_TITLE[scheduleStep]
    self:getViewData().statusLabel:updateLabel({text = stepTitleFunc and stepTitleFunc() or '----'})
end


function ChampionshipAuditionsView:onUpdateRefreshTime_(signal)
    local leftSeconds = self.mainProxy_:get(MAIN_PROXY_STRUCT.REFRESH_COUNTDOWN)
    local refreshText = CommonUtils.getTimeFormatByType(leftSeconds, 3)
    self:getViewData().countdownLabel:updateLabel({text = string.fmt(__('剩余：_time_'), {_time_ = refreshText})})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipAuditionsView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- table / VS
    local decorateGroup = centerLayer:addList({
        ui.image({img = RES_DICT.MATCH_VS, mt = -80}),
        ui.image({img = RES_DICT.MATCH_TABLE, mt = -20}),
    })
    ui.flowLayout(cc.rep(cpos, 0, 5), decorateGroup, {type = ui.flowV, ap = ui.cb})
    

    -- left avatar
    local leaderAvatarSize = cc.size(200, 300)
    local leftAvatarGroup  = centerLayer:addList({
        ui.layer({size = leaderAvatarSize, mb = -15, zorder = 1, color = cc.r4b(0), enable = true}),
        ui.image({img = RES_DICT.PLATE_BLUE}),
    })
    ui.flowLayout(cc.rep(cpos, -255, -180), leftAvatarGroup, {type = ui.flowV, ap = ui.ct})

    -- editTeamIcon
    local editTeamIcon = ui.image({img = RES_DICT.EDIT_TEAM, ap = ui.cb})
    centerLayer:addList(editTeamIcon):alignTo(leftAvatarGroup[2], ui.ct, {offsetY = 50})
    editTeamIcon:runAction(cc.RepeatForever:create(cc.Sequence:create({
        cc.DelayTime:create(0.8),
        cc.ScaleTo:create(0.1, 1.1, 0.8),
        cc.ScaleTo:create(0.1, 1),
        cc.JumpBy:create(0.4, cc.p(0,0), 60, 1),
        cc.ScaleTo:create(0.1, 1.1, 0.8),
        cc.ScaleTo:create(0.1, 1)
    })))

    
    -- right avatar
    local rightAvatarGroup = centerLayer:addList({
        ui.layer({size = leaderAvatarSize, mb = -15, zorder = 1, color = cc.r4b(0), enable = true}),
        ui.image({img = RES_DICT.PLATE_RED}),
    })
    ui.flowLayout(cc.rep(cpos, 255, -180), rightAvatarGroup, {type = ui.flowV, ap = ui.ct})


    ------------------------------------------------- [left]
    local leftLayer = ui.layer()
    view:add(leftLayer)

    local leftFuncFrame = ui.image({img = RES_DICT.FUNCITON_FRAME, size = cc.size(200, 40 + 140), cut = cc.dir(30,30,30,30), ap = ui.cb})
    leftLayer:addList(leftFuncFrame):alignTo(nil, ui.lb, {offsetX = display.SAFE_L, offsetY = 165})
    
    -- leftFunc group
    local leftFuncGroup = leftLayer:addList({
        ui.button({n = RES_DICT.RANK_BTN}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('排行详情'), offset = cc.p(0,-50)}),
    })
    ui.flowLayout(cc.rep(leftFuncFrame, 0, 25), leftFuncGroup, {type = ui.flowV, ap = ui.ct})
    
    
    ------------------------------------------------- [right]
    local rightLayer = ui.layer()
    view:add(rightLayer)

    local rightFuncFrame = ui.image({img = RES_DICT.FUNCITON_FRAME, size = cc.size(200, 40 + 140*2), cut = cc.dir(30,30,30,30), ap = ui.ct})
    rightLayer:addList(rightFuncFrame):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L, offsetY = -60})
    
    -- rightFunc group
    local rightFuncGroup = rightLayer:addList({
        ui.button({n = RES_DICT.SHOP_BTN}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('印记商店'), offset = cc.p(0,-50)}),
        ui.button({n = RES_DICT.REWARD_BTN}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('奖励预览'), offset = cc.p(0,-50)}),
    })
    ui.flowLayout(cc.rep(rightFuncFrame, 0, -10), rightFuncGroup, {type = ui.flowV, ap = ui.cb})


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- ceilingFrame | countdownBar | seasonLabel | statusLabel | countdownLabel
    local ceilingGroup = topLayer:addList({
        ui.image({img = RES_DICT.CEILING_FRAME, enable = true}),
        ui.image({img = RES_DICT.COUNTDOWN_BAR, mt = 22}),
        ui.label({fnt = FONT.D19, fontSize = 22, mb = 52}),
        ui.label({fnt = FONT.D12, fontSize = 22, mb = 12}),
        ui.label({fnt = FONT.D16, fontSize = 22, mt = 22, color = '#540e0e'}),
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.ct), -5, -120), ceilingGroup, {type = ui.flowC, ap = ui.cc})
    

    ------------------------------------------------- [bottom]
    local bottomLayer = ui.layer()
    view:add(bottomLayer)


    -- teamEdit group
    local teamEditGroup = bottomLayer:addList({
        ui.title({img = RES_DICT.TEXT_TIPS_BAR}):updateLabel({fnt = FONT.D9, text = __('规定时间造成的伤害越高越好'), paddingW = 80}),
        ui.image({img = RES_DICT.TEAM_FRAME}),
    })
    ui.flowLayout(cc.p(cpos.x, 0), teamEditGroup, {type = ui.flowV, ap = ui.ct, gapH = 10})

    -- teamEditArea
    local teamEditArea = ui.layer({size = cc.size(650, 120), color = cc.r4b(0), enable = true})
    bottomLayer:addList(teamEditArea):alignTo(teamEditGroup[2], ui.cc, {offsetX = 45})
    
    -- team cardCell
    local cardCellNodes  = {}
    local cardCellVDList = {}
    for cardIndex = 1, MAX_TEAM_MEMBER_AMOUNT do
        local cardCellVD = ChampionshipAuditionsView.CreateCardCell(cardIndex == 1)
        cardCellNodes[cardIndex]  = cardCellVD.view
        cardCellVDList[cardIndex] = cardCellVD
    end
    teamEditArea:addList(cardCellNodes)
    ui.flowLayout(cc.sizep(teamEditArea, ui.cc), cardCellNodes, {type = ui.flowH, ap = ui.cc, gapW = 30})


    -- score group
    local scoreGroup = bottomLayer:addList({
        ui.image({img = RES_DICT.SCORE_FRAME, ml = -60}),
        ui.title({img = RES_DICT.SCORE_TITLE, ml = 10, mb = 100}):updateLabel({fnt = FONT.D19, fontSize = 24, text = __('最高得分'), paddingW = 50, safeW = 160}),
        ui.bmfLabel({path = FONT.BMF_FIGHT, text = '0', ml = 110, mb = 25})
    })
    ui.flowLayout(cc.p(display.SAFE_L, 0), scoreGroup, {type = ui.flowC, ap = ui.lb})
    

    -- battle group
    local battleGroup = bottomLayer:addList({
        ui.image({img = RES_DICT.BATTLE_FRAME, mr = -60}),
        ui.battleButton({mr = 52, mb = 60}),
        ui.rLabel({ap = ui.rb, mr = 12, mb = 20}),
    })
    ui.flowLayout(cc.p(display.SAFE_R, 0), battleGroup, {type = ui.flowC, ap = ui.rb})

    
    return {
        view                = view,
        --                  = center
        centerLayer         = centerLayer,
        editTeamIcon        = editTeamIcon,
        playerAvatarLayer   = leftAvatarGroup[1],
        opponentAvatarLayer = rightAvatarGroup[1],
        --                  = left
        leftLayer           = leftLayer,
        rankBtn             = leftFuncGroup[1],
        --                  = right
        rightLayer          = rightLayer,
        shopBtn             = rightFuncGroup[1],
        rewardBtn           = rightFuncGroup[2],
        --                  = top
        topLayer            = topLayer,
        scheduleFrame       = ceilingGroup[1],
        seasonLabel         = ceilingGroup[3],
        statusLabel         = ceilingGroup[4],
        countdownLabel      = ceilingGroup[5],
        --                  = bottom
        bottomLayer         = bottomLayer,
        teamEditArea        = teamEditArea,
        cardCellVDList      = cardCellVDList,
        scoreLabel          = scoreGroup[3],
        battleButton        = battleGroup[2],
        ticketRLabel        = battleGroup[3],
    }
end


function ChampionshipAuditionsView.CreateCardCell(isCaptain)
    local size = cc.size(100, 100)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    local frameGroup = view:addList({
        ui.image({img = RES_DICT.CARD_CELL_BG, scale = 0.6}),
        ui.image({img = RES_DICT.CARD_CELL_FA, scale = 0.6}),
        ui.image({img = RES_DICT.CARD_CELL_EDIT}),
        ui.cardHeadNode({scale = 0.6}),
    })
    ui.flowLayout(cpos, frameGroup, {type = ui.flowC, ap = ui.cc})

    if isCaptain then
        view:add(ui.image({p = cc.rep(cc.sizep(size, ui.ct), 0, 7), img = RES_DICT.CARD_CAPTAIN}))
    end

    return {
        view     = view,
        headNode = frameGroup[4],
    }
end


return ChampionshipAuditionsView
