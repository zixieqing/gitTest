--[[
 * descpt : 创建工会 home 界面
]]
local VIEW_SIZE = cc.size(1035, 637)
local TagMatchView = class('TagMatchView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.tagMatch.TagMatchView'
	node:enableNodeEvents()
	return node
end)

local cardMgr  = AppFacade.GetInstance():GetManager('CardManager')

local CreateView         = nil
local CreateTeamCell     = nil
local CreateCardHead     = nil

local RES_DIR = {
    BG                    = _res("ui/home/activity/tagMatch/activity_3v3_bg.jpg"),
    TITLE                 = _res("ui/home/activity/tagMatch/activity_3v3_title.png"),
    TITLE2                = _res("ui/home/activity/tagMatch/activity_3v3_title_2.png"),
    TEAM_BG               = _res("ui/home/activity/tagMatch/activity_team_bg.png"),
    FIGHTING_HEAD_BG      = _res("ui/home/activity/tagMatch/activity_3v3_fighting_head_bg.png"),
    ADD_ICON              = _res("ui/common/maps_fight_btn_pet_add.png"),
    MANA_BG               = _res("ui/home/activity/tagMatch/activity_3v3_bg_lingli.png"),
    BTN2                  = _res("ui/home/activity/tagMatch/activity_3v3_btn_2.png"),
    -- WAIT_BTN              = _res("ui/home/activity/tagMatch/activity_3v3_btn_waitting.png"),
    WAIT_BTN              = _res("ui/home/activity/tagMatch/activity_3v3_btn_waitting1.png"),
    ORANGE_BTN            = _res('ui/common/common_btn_orange.png'),
    WHITE_BTN             = _res('ui/common/common_btn_white_default.png'),
    TIP_BTN               = _res('ui/common/common_btn_tips.png'),
    PRESET_TEAM_ICON      = _res('ui/home/cardslistNew/card_preview_btn_team.png'),
}

local BUTTON_TAG = {
    RULE        = 100,
    FIGHT       = 101,
    SIGH_UP     = 102,
    LOOK_REWARD = 103,
    RANK        = 104,
}

function TagMatchView:ctor( ... )
    self.args = unpack({...})
    self:initData()
    self:initialUI()
end

function TagMatchView:initData()
    
end

function TagMatchView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        display.commonUIParams(self:getViewData().view, {po = cc.p(0, 0), ap = display.LEFT_BOTTOM})
        self:addChild(self:getViewData().view)
        
	end, __G__TRACKBACK__)
end

function TagMatchView:refreshUi(data, levelStageConf, viewState)
    local viewData       = self:getViewData()
    local titleNameLabel = viewData.titleNameLabel
    local lvSection      = viewData.lvSection

    titleNameLabel:setString(tostring(levelStageConf.name))
    display.commonLabelParams(lvSection, {text = string.format(__('(%s级-%s级)'), levelStageConf.lowerLimit, levelStageConf.upperLimit)})
    if display.getLabelContentSize(titleNameLabel).height > 60  then
        print("levelStageConf.name = " , levelStageConf.name)
        display.commonLabelParams(titleNameLabel, {fontSize = 22 ,  reqH = 80 ,text = levelStageConf.name })
    end

    local section = data.section
    local leftSeconds = checkint(data.leftSeconds)

    -- 根据阶段刷新Ui
    self:updateUiBySection(section, leftSeconds)

    -- 更新按钮状态
    self:updateBtnState(section, data.isApply)

    -- 更新团队cell
    local teamDatas = data.teamDatas or {}
    self:updateTeamCell(teamDatas)

end

--[[
  根据阶段刷新Ui (0-未开始,1-报名中,2-进行中)
  @params section      阶段
  @params leftSeconds  剩余时间
]]
function TagMatchView:updateUiBySection(section, leftSeconds)
    local viewData          = self:getViewData()
    local baseLayer         = viewData.baseLayer
    local baseLayerViewData = baseLayer:getViewData()
    local timeLabel         = baseLayerViewData.timeLabel
    local timeTitleLabel    = baseLayerViewData.timeTitleLabel
    local timeTipLabel      = baseLayerViewData.timeTipLabel
    timeLabel:setVisible(true)
    timeTitleLabel:setVisible(true)
    timeTipLabel:setVisible(false) 

    if section == MATCH_BATTLE_3V3_TYPE.UNOPEN then
        self:updateCountDown(leftSeconds, __('下次报名'))
    elseif section == MATCH_BATTLE_3V3_TYPE.APPLY then
        self:updateCountDown(leftSeconds, __('报名中'))
    elseif section == MATCH_BATTLE_3V3_TYPE.READY then
        self:updateCountDown(leftSeconds, __('备战中'))
    elseif section == MATCH_BATTLE_3V3_TYPE.BATTLE then
        self:updateCountDown(leftSeconds, __('开战中'))
    end
end

--[[
  更新按钮状态 
  @params section      阶段     (0-未开始,1-报名中, 2-备战中, 3-进行中)
  @params isApply      是否完成
]]
function TagMatchView:updateBtnState(section, isApply)
    local viewData = self:getViewData()
    local signUpBtn      = viewData.signUpBtn
    local signUpTip      = viewData.signUpTip
    local isSignUpSuccess = checkint(isApply) > 0
    signUpTip:setVisible(isSignUpSuccess)
    signUpBtn:setVisible(not isSignUpSuccess)

    local isShowFightBtn    = section == MATCH_BATTLE_3V3_TYPE.BATTLE  and isSignUpSuccess
    local waitImg           = viewData.waitImg
    local fightBtn          = viewData.fightBtn
    waitImg:setVisible(not isShowFightBtn)
    fightBtn:setVisible(isShowFightBtn)

    local presetTeamBtn = viewData.presetTeamBtn
    if presetTeamBtn then
        presetTeamBtn:setVisible(not isSignUpSuccess)
    end
end

--[[
  更新团队cell 
  @params teamDatas    团队数据
]]
function TagMatchView:updateTeamCell(teamDatas)
    -- if next(teamDatas) == nil then return end

    local viewData = self:getViewData()
    local teamCells = viewData.teamCells
    for i, teamCell in ipairs(teamCells) do
        local teamData = teamDatas[tostring(i)] or {}
        self:updateTeamBattlePoint(teamData, teamCell)
        if teamData then  
            self:updateCardHead(teamData, teamCell)
        end
    end
end

--[[
  更新倒计时 
  @params leftSeconds    剩余时间
]]
function TagMatchView:updateCountDown(leftSeconds, timeDesc)
    local viewData          = self:getViewData()
    local baseLayer         = viewData.baseLayer
    if timeDesc then
        baseLayer:setTimeTitleLabel(timeDesc)
    end
    if leftSeconds then
        baseLayer:setTimeLabel(checkint(leftSeconds))
    end
end

--[[
  更新团队战力 
  @params teamData    团队数据
  @params teamCell    团队 cell
]]
function TagMatchView:updateTeamBattlePoint(teamData, teamCell)
    teamData = teamData or {}

    local teamCellViewData = teamCell.viewData
    local manaLabel = teamCellViewData.manaLabel
    
    local battlePoint = 0
    for i, v in ipairs(teamData) do
        local id = v.id
        if checkint(id) > 0 then
            battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointById(v.id)
        end
    end
    -- logInfo.add(5, "updateTeamBattlePoint222")
    display.commonLabelParams(manaLabel, {reqW= 140 ,text = string.format(__('灵力: %s'), battlePoint)})
end

--[[
  更新卡牌头像 
  @params teamData    团队数据
  @params teamCell    团队 cell
]]
function TagMatchView:updateCardHead(teamData, teamCell)
    local cardData = {}

    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local cData = teamData[i] or {}
        if next(cData) ~= nil then
            cardData = cData
            break
        end
    end
    
    local cardId = cardData.id
    local cardHeadNode = teamCell.viewData.cardHeadNode
    if cardId then
        if cardHeadNode then
            cardHeadNode:setVisible(true)
            if cardHeadNode.id ~= cardId then
                cardHeadNode:RefreshUI({id = cardId})
            end
        else
            local teamCellSize = teamCell:getContentSize()
            local cardHeadNode = CreateCardHead(cardId)
            cardHeadNode:setPosition(cc.p(teamCellSize.width / 2 - 3, teamCellSize.height / 2))
            teamCell:addChild(cardHeadNode)
            -- cardHeadNode:set
            teamCell.viewData.cardHeadNode = cardHeadNode
        end
    else
        if cardHeadNode then
            cardHeadNode:setVisible(false)
        end
    end
end

--[[
  更新规则
  @params rule    规则
]]
function TagMatchView:updateRule(rule)
    local baseLayer = self:getBaseLayer()
    baseLayer:setRule(rule)
end

CreateView = function ()
    local view = CLayout:create(VIEW_SIZE)
    -- local size = view:getContentSize()
    local actionBtns = {}

    local baseLayer = require("common.CommonBaseActivityView").new({bg = RES_DIR.BG})
    display.commonUIParams(baseLayer, {po = cc.p(0, 0), ap = display.LEFT_BOTTOM})
    view:addChild(baseLayer)
    -------------------------------------
    -- top
    local title = display.newImageView(RES_DIR.TITLE, 180, VIEW_SIZE.height - 90, {ap = display.CENTER_BOTTOM})
	view:addChild(title)
    CommonUtils.SetNodeScale(title , {width = 300 })

    local titleNameLabel = display.newLabel(430, title:getPositionY(), {w = 170, ap = display.CENTER_BOTTOM, fontSize = 30, color = '#fff5d0', font = TTF_GAME_FONT, ttf = true, outline = '#482810', outlineSize = 1})
    view:addChild(titleNameLabel)

    local lvSection = display.newLabel(580, title:getPositionY() + 5, fontWithColor(16, {ap = display.CENTER_BOTTOM, w = 22 * 5.6}))
    view:addChild(lvSection)

    -- rule
    local ruleBtn = display.newButton(lvSection:getPositionX() + 80, lvSection:getPositionY() + 13, {n = RES_DIR.TIP_BTN, ap = display.CENTER})
    actionBtns[tostring(BUTTON_TAG.RULE)] = ruleBtn
    view:addChild(ruleBtn)
    
    -------------------------------------
    -- content
    local title2 = display.newImageView(RES_DIR.TITLE2, 25, VIEW_SIZE.height - 140, {ap = display.LEFT_CENTER})
    local title2Size = title2:getContentSize()
    view:addChild(title2)
    
    local title2Label = display.newLabel(5, title2Size.height / 2, fontWithColor(19, {ap = display.LEFT_CENTER, text = __('报名！ 编辑防守队伍')}))
    title2:addChild(title2Label)

    local presetTeamIcon = display.newImageView(RES_DIR.PRESET_TEAM_ICON, title2:getPositionX() + 520, title2:getPositionY() - 50)
    view:addChild(presetTeamIcon,1)
    presetTeamIcon:setVisible(false)
    

    local teamBg = display.newLayer(25, VIEW_SIZE.height / 2 + 40, {ap = display.LEFT_CENTER, bg = RES_DIR.TEAM_BG})
    local teamBgSize = teamBg:getContentSize()
    view:addChild(teamBg)
    local teamCells = {}
    for i = 1, 3 do
        local cell = CreateTeamCell(i)
        display.commonUIParams(cell, {po = cc.p(170 * (i - 1), teamBgSize.height / 2), ap = display.LEFT_CENTER})
        teamBg:addChild(cell)
        table.insert(teamCells, cell)
    end

    local signUpBtn = display.newButton(0, 0, {n = RES_DIR.ORANGE_BTN ,scale9 = true })
    display.commonUIParams(signUpBtn, {po = cc.p(460 - 180, 210)})
    display.commonLabelParams(signUpBtn, {text = __('报名参赛'), paddingW = 20,  fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
    view:addChild(signUpBtn)
    actionBtns[tostring(BUTTON_TAG.SIGH_UP)] = signUpBtn

    local signUpTip = display.newButton( 460 - 180, 210, {n = RES_DIR.BTN2 ,  ap = display.CENTER ,scale9 = true  , enable = false} )
    display.commonLabelParams(signUpTip , {ap = display.CENTER, text = __('报名成功'),paddingW = 20 , fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true})
    view:addChild(signUpTip)
    signUpTip:setVisible(false)

    local presetTeamBtn = nil
    if GAME_MODULE_OPEN.PRESET_TEAM and CommonUtils.UnLockModule(JUMP_MODULE_DATA.PRESET_TEAM_TAGMATCH) then
        -- 预设队伍按钮
        presetTeamBtn = require("Game.views.presetTeam.PresetTeamEntranceButton").new({isSelectMode = true, presetTeamType = PRESET_TEAM_TYPE.TAG_MATCH})
        display.commonUIParams(presetTeamBtn, {po = cc.p(
            signUpBtn:getPositionX() + signUpBtn:getContentSize().width/2 + 120,
            signUpBtn:getPositionY()
        )})
        display.commonLabelParams(presetTeamBtn, fontWithColor('14', {text = __('预设队伍')}))
        view:addChild(presetTeamBtn)
    end

    -- rank
    local rankBtn = display.newButton(0, 0, {n = RES_DIR.WHITE_BTN, scale9 = true , size = cc.size(150, 60 )})
    display.commonUIParams(rankBtn, {po = cc.p(VIEW_SIZE.width - 10 - 182, VIEW_SIZE.height - 94), ap = display.RIGHT_CENTER})
    display.commonLabelParams(rankBtn, fontWithColor(14, {reqW = 130 ,text = __('排行榜') }))
    view:addChild(rankBtn)
    actionBtns[tostring(BUTTON_TAG.RANK)] = rankBtn

    -- look reward
    local lookRewardBtn = display.newButton(0, 0, {n = RES_DIR.ORANGE_BTN,  scale9 = true , size = cc.size(150, 60 )})
    display.commonUIParams(lookRewardBtn, {po = cc.p(VIEW_SIZE.width - 30, VIEW_SIZE.height - 94),ap = display.RIGHT_CENTER})
    display.commonLabelParams(lookRewardBtn, fontWithColor(14, {reqW = 130 , text = __('查看奖励')}))
    view:addChild(lookRewardBtn)
    actionBtns[tostring(BUTTON_TAG.LOOK_REWARD)] = lookRewardBtn

    -------------------------------------
    -- bottom
    
    -- local waitImg = display.newImageView(RES_DIR.WAIT_BTN, VIEW_SIZE.width - 110, 110, {ap = display.CENTER})
    -- view:addChild(waitImg)
    local waitImg = ui.title({n = RES_DIR.WAIT_BTN}):updateLabel({fnt = FONT.D20, outline = "#6e2b0a", fontSize = 60, text = __("备战中"), reqW = 180})
    waitImg:setScale(0.8)
    view:addList(waitImg):alignTo(nil, ui.rb, {offsetX = -20, offsetY = 100})

    local fightBtn = require('common.CommonBattleButton').new()
    fightBtn:setPosition(VIEW_SIZE.width - 110, 110)
    view:addChild(fightBtn)
    fightBtn:setVisible(false)
    actionBtns[tostring(BUTTON_TAG.FIGHT)] = fightBtn

    return {
        view           = view,
        baseLayer      = baseLayer,
        titleNameLabel = titleNameLabel,
        lvSection      = lvSection,
        actionBtns     = actionBtns,
        teamCells      = teamCells,
        signUpBtn      = signUpBtn,
        signUpTip      = signUpTip,
        waitImg        = waitImg,
        fightBtn       = fightBtn,
        presetTeamBtn  = presetTeamBtn,
        presetTeamIcon = presetTeamIcon,
    }
end

CreateTeamCell = function (index)
    local size = cc.size(176, 200)
    local teamLayer = display.newLayer(0, 0, {size = size})

    teamLayer:addChild(display.newLabel(30, size.height - 30, fontWithColor(16, { reqW = 144 , ap = display.LEFT_CENTER, text = string.format(__('防守队伍%s'),  index)})))

    local fightHeadBg = display.newButton(30, size.height / 2, {n = RES_DIR.FIGHTING_HEAD_BG, ap = display.LEFT_CENTER})
    local fightHeadBgSize = fightHeadBg:getContentSize()
    teamLayer:addChild(fightHeadBg)

    fightHeadBg:addChild(display.newImageView(RES_DIR.ADD_ICON, fightHeadBgSize.width / 2, fightHeadBgSize.height / 2, {ap = display.CENTER}))

    local manaBg = display.newImageView(RES_DIR.MANA_BG, 30, 25, {ap = display.LEFT_CENTER})
    local manaBgSize = manaBg:getContentSize()
    teamLayer:addChild(manaBg)

    -- 灵力
    local manaLabel = display.newLabel(5, manaBgSize.height / 2, fontWithColor(18, {ap = display.LEFT_CENTER, text = string.format(__('灵力: %s'), 0)}))
    manaBg:addChild(manaLabel)

    teamLayer.viewData = {
        fightHeadBg = fightHeadBg,
        manaLabel = manaLabel,
    }

    return teamLayer
end

CreateCardHead = function (cardId)
    local cardHeadNode = require('common.CardHeadNode').new({
        id = cardId,
        showBaseState = true, showActionState = false, showVigourState = false
    })
    cardHeadNode:setScale(0.45)
    cardHeadNode:setTouchEnabled(false)
    -- cardHeadNode:setPosition(cc.p(teamCellSize.width / 2, teamCellSize.height / 2))
    return cardHeadNode
end

function TagMatchView:getViewData()
	return self.viewData_
end

function TagMatchView:getBaseLayer()
    return self:getViewData().baseLayer
end

return TagMatchView