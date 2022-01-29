--[[
 * author : kaishiqi
 * descpt : 预览队伍详情弹窗
]]
local PreviewTeamDetailPopup = class('PreviewTeamDetailPopup', function()
    return ui.layer({name = 'common.PreviewTeamDetailPopup', enableEvent = true, ap = ui.cc})
end)

local RES_DICT = {
    BACK_BTN     = _res('ui/common/common_btn_back.png'),
    NAME_BAR     = _res('ui/raid/room/raid_room_detail_label_owner.png'),
    TEAM_BG      = _res('ui/worldboss/manual/boosstrategy_ranks_bg.png'),
    FIRE_SPN     = _spn('effects/fire/skeleton'),
    --           = card cell
    LEADER_PLATE = _res('ui/common/tower_bg_team_base_cap.png'),
    MEMBER_PLATE = _res('ui/common/tower_bg_team_base.png'),
    LIGHT_PLATE  = _res('ui/common/tower_prepare_bg_light.png'),
    LEADER_ICON  = _res('ui/home/teamformation/team_ico_captain.png'),
    CSKILL_FRAME = _res('ui/home/teamformation/team_ico_skill_circle.png'),
}


function PreviewTeamDetailPopup:ctor(args)
    local initArgs = checktable(args)
    self.playerId_ = checkstr(initArgs.playerId)
    self.name_     = checkstr(initArgs.name)
    self.union_    = checkstr(initArgs.union)
    self.avatar_   = checkint(initArgs.avatar)
    self.frame_    = checkint(initArgs.frame)
    self.level_    = checkint(initArgs.level)
    self.teamData_ = checktable(initArgs.teamData)
    
    -- create view
    self.viewData_ = PreviewTeamDetailPopup.CreateView()
    self:addChild(self.viewData_.view)

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    for cardIndex, cardVD in ipairs(self:getViewData().cardVDList) do
        ui.bindClick(cardVD.clickArea, handler(self, self.onClickCardCellHandler_))
    end

    -- update views
    self:updatePlayerInfo_()
    self:updateTeamInfo_()
end


function PreviewTeamDetailPopup:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- public

function PreviewTeamDetailPopup:close()
    self:runAction(cc.RemoveSelf:create())
end


-------------------------------------------------
-- private

function PreviewTeamDetailPopup:updatePlayerInfo_()
    local unionText = string.len(self.union_) > 0 and string.fmt(__('工会：_name_'), {_name_ = self.union_}) or ''
    self:getViewData().unionLabel:updateLabel({text = unionText})
    self:getViewData().nameLabel:updateLabel({text = self.name_})
    self:getViewData().headNode:RefreshUI({
        avatar      = self.avatar_,
        avatarFrame = self.frame_,
        playerLevel = self.level_,
    })
end


function PreviewTeamDetailPopup:updateTeamInfo_()
    local teamPower = 0
    for cardIndex, cardVD in ipairs(self:getViewData().cardVDList) do
        local cardData = self.teamData_[cardIndex] or {}
        local cardId   = checkint(cardData.cardId)
        local skinId   = checkint(cardData.defaultSkinId) > 0 and checkint(cardData.defaultSkinId) or CardUtils.GetCardSkinId(cardId)
        local isEmpty  = next(cardData) == nil
        local cskillId = CardUtils.GetCardConnectSkillId(cardId)
        cardVD.lightImg:setVisible(isEmpty)
        
        if not isEmpty then
            cardVD.avatarLayer:addAndClear(ui.cardSpineNode({skinId = skinId, init = 'idle', scale = 0.45}))

            if cskillId then
                local skillNode = ui.image({img = RES_DICT.CSKILL_FRAME})
                local skillIcon = ui.image({img = CommonUtils.GetSkillIconPath(cskillId)})
                local isEnable  = CardUtils.IsConnectSkillEnable(cardId, self.teamData_)
                skillIcon:setScale((skillNode:getContentSize().width - 10) / skillIcon:getContentSize().width)
                skillIcon:setColor(isEnable and cc.c3b(255,255,255) or cc.c3b(100,100,100))
                skillNode:addList(skillIcon):alignTo(nil, ui.cc)
                cardVD.cskillLayer:addAndClear(skillNode)
            end

            teamPower = teamPower + CardUtils.GetCardStaticBattlePointByCardData(cardData)
        end
    end
    self:getViewData().powerLabel:updateLabel({text = tostring(teamPower)})
end


-------------------------------------------------
-- handler

function PreviewTeamDetailPopup:onCleanup()
    app.uiMgr:GetCurrentScene():RemoveDialogByName('Game.views.raid.PlayerCardDetailView')
end


function PreviewTeamDetailPopup:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()

    self:close()
end


function PreviewTeamDetailPopup:onClickCardCellHandler_(sender)
    PlayAudioByClickNormal()

    local cardIndex = checkint(sender:getTag())
    local cardData  = checktable(self.teamData_[cardIndex])
    app.uiMgr:AddDialog('Game.views.raid.PlayerCardDetailView', {
        cardData = {
            cardId        = checkint(cardData.cardId),
            skinId        = checkint(cardData.defaultSkinId) > 0 and checkint(cardData.defaultSkinId) or CardUtils.GetCardSkinId(cardId),
            level         = checkint(cardData.level),
            breakLevel    = checkint(cardData.breakLevel),
            favorLevel    = checkint(cardData.favorabilityLevel),
            artifacTalent = checktable(cardData.artifactTalent),
            nickname      = nil,
            bookLevel     = cardData.bookLevel,
            equippedHouseCatGene = cardData.equippedHouseCatGene,
        },
        petsData   = checktable(cardData.pets),
        playerData = {
            playerId          = self.playerId_,
            playerAvatar      = self.avatar_,
            playerAvatarFrame = self.frame_,
            playerLevel       = self.level_,
            playerName        = self.name_,
        },
    })
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function PreviewTeamDetailPopup.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })

    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    local backBtn = ui.button({n = RES_DICT.BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 30, offsetY = -15})


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)


    ------------------------------------------------- [center.team]
    local teamLayer = ui.layer()
    centerLayer:add(teamLayer)

    local teamSize  = cc.size(900, 270)
    local teamGroup = teamLayer:addList({
        ui.image({img = RES_DICT.TEAM_BG}),
        ui.layer({size = teamSize, color1 = cc.r4b(100)}),
    })
    ui.flowLayout(cc.rep(cpos, 0, -60), teamGroup, {type = ui.flowC, ap = ui.cc})

    local cardNodes  = {}
    local cardVDList = {}
    local cardsLayer = teamGroup[2]
    for cardIndex = 1, MAX_TEAM_MEMBER_AMOUNT do
        cardVDList[cardIndex] = PreviewTeamDetailPopup.CreateCardCell(cardIndex)
        cardNodes[cardIndex] = cardVDList[cardIndex].view
    end
    cardsLayer:addList(cardNodes)
    ui.flowLayout(cc.sizep(cardsLayer, ui.cc), cardNodes, {type = ui.flowH, ap = ui.cc, gapW = 30})

    local tipsLabel = ui.label({fnt = FONT.D18, text = __('点击飨灵查看详细信息')})
    teamLayer:addList(tipsLabel):alignTo(teamGroup[2], ui.cb, {offsetY = -20})

    local teamIntro = ui.label({fnt = FONT.D18, color = '#e0c5a5', text = __('他(她)的阵容')})
    teamLayer:addList(teamIntro):alignTo(teamGroup[2], ui.lt, {inside = true, offsetY = 40})
    
    local fireSpine = ui.spine({path = RES_DICT.FIRE_SPN, init = 'huo'})
    teamLayer:addList(fireSpine):alignTo(teamGroup[2], ui.rt, {inside = true, offsetX = -70})

    local powerLabel = ui.bmfLabel({path = FONT.BMF_FIGHT, text = '0000', scale = 0.65})
    teamLayer:addList(powerLabel):alignTo(fireSpine, ui.cc, {offsetX = -6, offsetY = 16})


    ------------------------------------------------- [center.player]
    local playerLayer = ui.layer()
    centerLayer:add(playerLayer)

    local playerGroup = playerLayer:addList({
        ui.image({img = RES_DICT.NAME_BAR, scale9 = true, size = cc.size(360, 78), ml = 180}),
        ui.label({fnt = FONT.D12, color = '#FFFFCC', ap = ui.lb, ml = 60, mb = 3}),
        ui.label({fnt = FONT.D18, color = '#FFFFFF', ap = ui.lt, ml = 60, mt = 5}),
        ui.playerHeadNode({showLevel = true, scale = 0.7}),
    })
    ui.flowLayout(cc.rep(teamIntro, 0, 120), playerGroup, {type = ui.flowC, ap = ui.cc})


    return {
        view       = view,
        backBtn    = backBtn,
        unionLabel = playerGroup[2],
        nameLabel  = playerGroup[3],
        headNode   = playerGroup[4],
        powerLabel = powerLabel,
        cardVDList = cardVDList,
    }
end


function PreviewTeamDetailPopup.CreateCardCell(cardIndex)
    local size = cc.size(150, 240)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    local isLeader = cardIndex == 1
    local plateImg = ui.image({img = isLeader and RES_DICT.LEADER_PLATE or RES_DICT.MEMBER_PLATE})
    view:addList(plateImg):alignTo(nil, ui.cb)

    local lightImg = ui.image({img = RES_DICT.LIGHT_PLATE})
    view:addList(lightImg):alignTo(plateImg, ui.ct, {offsetY = -15})

    if isLeader then
        local leaderIcon = ui.image({img = RES_DICT.LEADER_ICON})
        view:addList(leaderIcon):alignTo(plateImg, ui.lc, {offsetX = 35, offsetY = -5})
    end

    local avatarLayer = ui.layer({size = SizeZero})
    view:addList(avatarLayer):alignTo(plateImg, ui.ct, {offsetY = -12})

    local cskillLayer = ui.layer({size = SizeZero})
    view:addList(cskillLayer):alignTo(avatarLayer)
    
    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    clickArea:setTag(cardIndex)
    view:add(clickArea)
    
    return {
        view        = view,
        clickArea   = clickArea,
        lightImg    = lightImg,
        avatarLayer = avatarLayer,
        cskillLayer = cskillLayer,
    }
end


return PreviewTeamDetailPopup
