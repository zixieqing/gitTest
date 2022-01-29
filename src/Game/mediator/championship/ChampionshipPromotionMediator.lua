--[[
 * author : kaishiqi
 * descpt : 武道会 - 晋级赛中介者
]]
local ChampionshipPromotionView     = require('Game.views.championship.ChampionshipPromotionView')
local ChampionshipPromotionMediator = class('ChampionshipPromotionMediator', mvc.Mediator)

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT

function ChampionshipPromotionMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipPromotionMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function ChampionshipPromotionMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.isControllable_ = true

    -- init model
    self.mainProxy_ = app:RetrieveProxy(MAIN_PROXY_NAME)

    -- create view
    if self.ownerNode_ then
        self.viewNode_ = ChampionshipPromotionView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self:getViewNode())

        -- add listener
        ui.bindClick(self:getViewData().shopBtn, handler(self, self.onClickShopButtonHandler_))
        ui.bindClick(self:getViewData().rewardBtn, handler(self, self.onClickRewardButtonHandler_))
        ui.bindClick(self:getViewData().scheduleBtn, handler(self, self.onClickScheduleButtonHandler_))
        ui.bindClick(self:getViewData().applyBtn, handler(self, self.onClickTeamEditAreaHandler_))
        ui.bindClick(self:getViewData().outReportBtn, handler(self, self.onClickReportButtonHandler_))
        ui.bindClick(self:getViewData().winReportBtn, handler(self, self.onClickReportButtonHandler_))
        ui.bindClick(self:getViewData().scheduleFrame, handler(self, self.onClickScheduleFrameHandler_), false)
        ui.bindClick(self:getViewData().playerAvatarLayer, handler(self, self.onClickTeamEditAreaHandler_), false)
        ui.bindClick(self:getViewData().opponetPlayerLayer, handler(self, self.onClickOpponentHeadAreaHandler_), false)
        ui.bindClick(self:getOpponentVD().blockLayer, handler(self, self.onClickOpponentTeamBlockLayerHandler_), false)
        for index, teamVD in ipairs(self:getOpponentVD().teamVDList) do
            ui.bindClick(teamVD.clickArea, handler(self, self.onClickOpponentTeamClickAreaHandler_), false)
        end
        self:getViewNode().hideOpponentTeamCB = function()
            app.uiMgr:GetCurrentScene():RemoveDialogByName('common.PreviewTeamDetailPopup')
        end
    end
end


function ChampionshipPromotionMediator:CleanupView()
    app.uiMgr:GetCurrentScene():RemoveDialogByName('common.PreviewTeamDetailPopup')
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function ChampionshipPromotionMediator:OnRegist()
    regPost(POST.CHAMPIONSHIP_APPLY)
    regPost(POST.CHAMPIONSHIP_OPPONENT_DETAIL)
end


function ChampionshipPromotionMediator:OnUnRegist()
    unregPost(POST.CHAMPIONSHIP_APPLY)
    unregPost(POST.CHAMPIONSHIP_OPPONENT_DETAIL)
end


function ChampionshipPromotionMediator:InterestSignals()
    return {
        POST.CHAMPIONSHIP_APPLY.sglName,
        POST.CHAMPIONSHIP_OPPONENT_DETAIL.sglName,
    }
end
function ChampionshipPromotionMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.CHAMPIONSHIP_APPLY.sglName then
        local SEND_STRUCT = MAIN_PROXY_STRUCT.PROMOTION_APPLY_SEND
        local team1Cards  = string.split2(self.mainProxy_:get(SEND_STRUCT.CARD_IDS_1), ',')
        local team2Cards  = string.split2(self.mainProxy_:get(SEND_STRUCT.CARD_IDS_2), ',')
        local team3Cards  = string.split2(self.mainProxy_:get(SEND_STRUCT.CARD_IDS_3), ',')
        local team1Datas  = app.gameMgr:GetCardDataListByIdList(team1Cards)
        local team2Datas  = app.gameMgr:GetCardDataListByIdList(team2Cards)
        local team3Datas  = app.gameMgr:GetCardDataListByIdList(team3Cards)
        self.mainProxy_:set(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_TEAM1, team1Datas)
        self.mainProxy_:set(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_TEAM2, team2Datas)
        self.mainProxy_:set(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_TEAM3, team3Datas)


    elseif name == POST.CHAMPIONSHIP_OPPONENT_DETAIL.sglName then
        local TAKE_STRUCT = MAIN_PROXY_STRUCT.PROMOTION_PLAYER_TAKE
        self.mainProxy_:set(TAKE_STRUCT, data)
        self:getViewNode():showOpponentTeam()
    
    end
end


-------------------------------------------------
-- get / set

function ChampionshipPromotionMediator:getViewNode()
    return  self.viewNode_
end
function ChampionshipPromotionMediator:getViewData()
    return self:getViewNode():getViewData()
end
function ChampionshipPromotionMediator:getOpponentVD()
    return self:getViewNode():getOpponentVD()
end


-------------------------------------------------
-- public

function ChampionshipPromotionMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private


-------------------------------------------------
-- handler

function ChampionshipPromotionMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local storeMdt = require('Game.mediator.championship.ChampionshipShopMediator').new()
    app:RegistMediator(storeMdt)
end


function ChampionshipPromotionMediator:onClickRewardButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    app.uiMgr:AddDialog('Game.views.championship.ChampionshipRewardPreviewPopup', {type = 2})
end


function ChampionshipPromotionMediator:onClickScheduleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local scheduleMdt = require('Game.mediator.championship.ChampionshipScheduleMediator').new()
    app:RegistMediator(scheduleMdt)
end


function ChampionshipPromotionMediator:onClickReportButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local reportMdt = require('Game.mediator.championship.ChampionshipReportMediator').new({type = FOOD.CHAMPIONSHIP.REPORT.TYPE.BATTLE})
    app:RegistMediator(reportMdt)
end


function ChampionshipPromotionMediator:onClickTeamEditAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- 非晋级赛报名阶段，不允许报名
    local scheduleStep = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
    if scheduleStep ~= FOOD.CHAMPIONSHIP.STEP.PROMOTION then
        return
    end

    -- 已有参赛队伍，则不允许再次修改
    local hasPromotionTeam = self.mainProxy_:size(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_TEAM1) > 0
    if hasPromotionTeam then
        return
    end

    -- 晋级赛提交编队界面
    local editTeamMdt = require('Game.mediator.presetTeam.PresetTeamEditTeamMediator').new({
        editName = false,
        data = {
            name = __('晋级赛队伍'),
        },
        conf = {
            cardCount    = 5,  -- 卡牌个数
            minCardCount = 15, -- 最小卡牌个数
            maxTeamCount = 3,  -- 最大团队个数
        },
        saveTIps = {
            text  = __('是否确认参赛队伍？'),
            extra = __('确认报名后，本届晋级赛中不能再次编辑队伍'),
        },
        saveCB = function(saveData)
            local teamList = {}
            local ctorList = {}
            local loadList = {}
            
            for teamIndex, teamCards in ipairs(saveData.teamCards or {}) do
                local cardList = {}
                for cardIndex, cardData in ipairs(teamCards) do
                    cardList[cardIndex] = {id = cardData.id, cardId = cardData.cardId}
                end

                local battleConstructor = require('battleEntry.BattleConstructorEx').new()
                battleConstructor:InitByCommonData(
                    0,                                      -- 关卡 id
                    QuestBattleType.CHAMPIONSHIP_PROMOTION, -- 战斗类型
                    ConfigBattleResultType.ONLY_RESULT,     -- 结算类型
                    ----
                    {},                                     -- 友方阵容
                    {},                                     -- 敌方阵容
                    ----
                    nil,                                    -- 友方携带的主角技
                    nil,                                    -- 友方所有主角技
                    nil,                                    -- 敌方携带的主角技
                    nil,                                    -- 敌方所有主角技
                    ----
                    nil,                                    -- 全局buff
                    nil,                                    -- 卡牌能力增强信息
                    ----
                    nil,                                    -- 已买活次数
                    nil,                                    -- 最大买活次数
                    false,                                  -- 是否开启买活
                    ----
                    nil,                                    -- 随机种子
                    false,                                  -- 是否是战斗回放
                    ----
                    nil,                                    -- 与服务器交互的命令信息
                    nil                                     -- 跳转信息
                )
                
                local teamConstructor = battleConstructor:CalcRecordConstructData()
                local loadedResources = battleConstructor:CalcLoadSpineResOneTeam(
                    0,                                      -- 关卡id
                    QuestBattleType.CHAMPIONSHIP_PROMOTION, -- 战斗类型
                    cardList,                               -- 队伍数据
                    true                                    -- 检查连携
                )
                ctorList[teamIndex] = teamConstructor
                loadList[teamIndex] = loadedResources
                teamList[teamIndex] = cardList
            end

            local SEND_STRUCT = MAIN_PROXY_STRUCT.PROMOTION_APPLY_SEND
            self.mainProxy_:set(SEND_STRUCT.CARD_IDS_1, table.concat(table.valuesAt(teamList[1], 'id'), ','))
            self.mainProxy_:set(SEND_STRUCT.CARD_IDS_2, table.concat(table.valuesAt(teamList[2], 'id'), ','))
            self.mainProxy_:set(SEND_STRUCT.CARD_IDS_3, table.concat(table.valuesAt(teamList[3], 'id'), ','))
            self.mainProxy_:set(SEND_STRUCT.CTOR_JSON_1, ctorList[1])
            self.mainProxy_:set(SEND_STRUCT.CTOR_JSON_2, ctorList[2])
            self.mainProxy_:set(SEND_STRUCT.CTOR_JSON_3, ctorList[3])
            self.mainProxy_:set(SEND_STRUCT.LOAD_JSON_1, loadList[1])
            self.mainProxy_:set(SEND_STRUCT.LOAD_JSON_2, loadList[2])
            self.mainProxy_:set(SEND_STRUCT.LOAD_JSON_3, loadList[3])
            self:SendSignal(POST.CHAMPIONSHIP_APPLY.cmdName, self.mainProxy_:get(SEND_STRUCT):getData())
        end,
    })
    app:RegistMediator(editTeamMdt)
end


function ChampionshipPromotionMediator:onClickOpponentHeadAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local opponetId   = checkint(sender:getUserTag())
    local SEND_STRUCT = MAIN_PROXY_STRUCT.PROMOTION_PLAYER_SEND
    self.mainProxy_:set(SEND_STRUCT.PLAYER_ID, opponetId)
    if opponetId > 0 then
        self:SendSignal(POST.CHAMPIONSHIP_OPPONENT_DETAIL.cmdName, self.mainProxy_:get(SEND_STRUCT):getData())
    else
        app.uiMgr:ShowInformationTips(__('你的对手放弃了比赛'))
    end
end


function ChampionshipPromotionMediator:onClickOpponentTeamBlockLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():hideOpponentTeam()
end


function ChampionshipPromotionMediator:onClickOpponentTeamClickAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local teamIndex      = checkint(sender:getTag())
    local TEAM_STRUCT    = MAIN_PROXY_STRUCT.PROMOTION_PLAYER_TAKE['TEAM' .. teamIndex]
    local PLAYERS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local opponetId      = self.mainProxy_:get(MAIN_PROXY_STRUCT.PROMOTION_PLAYER_SEND.PLAYER_ID)
    local opponetProxy   = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(opponetId))
    local opponetName    = opponetProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
    local opponetUnion   = opponetProxy:get(PLAYERS_STRUCT.PLAYER_DATA.UNION)
    local opponetAvatar  = opponetProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR)
    local opponetFrame   = opponetProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME)
    local opponetLevel   = opponetProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL)
    app.uiMgr:AddDialog('common.PreviewTeamDetailPopup', {
        playerId = opponetId,
        name     = opponetName,
        union    = opponetUnion,
        avatar   = opponetAvatar,
        frame    = opponetFrame,
        level    = opponetLevel,
        teamData = self.mainProxy_:get(TEAM_STRUCT):getData(),
    })
end


function ChampionshipPromotionMediator:onClickScheduleFrameHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    app.uiMgr:AddDialog('Game.views.championship.ChampionshipTimelinePopup')
end


return ChampionshipPromotionMediator
