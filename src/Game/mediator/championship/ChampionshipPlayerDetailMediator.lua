--[[
 * author : kaishiqi
 * descpt : 武道会 - 玩家详情中介者
]]
local ChampionshipPlayerDetailView     = require('Game.views.championship.ChampionshipPlayerDetailView')
local ChampionshipPlayerDetailMediator = class('ChampionshipPlayerDetailMediator', mvc.Mediator)

local MAIN_PROXY_NAME     = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT   = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT
local DETAIL_PROXY_NAME   = FOOD.CHAMPIONSHIP.PLAYER_DETAIL.PROXY_NAME
local DETAIL_PROXY_STRUCT = FOOD.CHAMPIONSHIP.PLAYER_DETAIL.PROXY_STRUCT

function ChampionshipPlayerDetailMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipPlayerDetailMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function ChampionshipPlayerDetailMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    local detailType     = self.ctorArgs_.detailType
    local playerId       = self.ctorArgs_.playerId
    local matchId        = self.ctorArgs_.matchId
    self.isControllable_ = true

    -- init model
    self.mainProxy_   = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.detailProxy_ = regVoProxy(DETAIL_PROXY_NAME, DETAIL_PROXY_STRUCT)
    self.detailProxy_:set(DETAIL_PROXY_STRUCT.DETAIL_TYPE, detailType)
    self.detailProxy_:set(DETAIL_PROXY_STRUCT.PLAYER_ID, playerId)
    self.detailProxy_:set(DETAIL_PROXY_STRUCT.MATCH_ID, matchId)

    -- create view
    self.viewNode_ = ChampionshipPlayerDetailView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().guessVoteBtn, handler(self, self.onClickVoteButtonHandler_), false)
    for index, teamVD in ipairs(self:getViewData().teamVDList) do
        ui.bindClick(teamVD.clickArea, handler(self, self.onClickTeamClickAreaHandler_), false)
    end
end


function ChampionshipPlayerDetailMediator:CleanupView()
    unregVoProxy(DETAIL_PROXY_NAME)

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function ChampionshipPlayerDetailMediator:OnRegist()
    regPost(POST.CHAMPIONSHIP_GUESS)
    regPost(POST.CHAMPIONSHIP_PLAYER_DETAIL)

    local playerId    = self.detailProxy_:get(DETAIL_PROXY_STRUCT.PLAYER_ID)
    local SEND_STRUCT = DETAIL_PROXY_STRUCT.PLAYER_SEND
    self.detailProxy_:set(SEND_STRUCT.PLAYER_ID, playerId)
    self:SendSignal(POST.CHAMPIONSHIP_PLAYER_DETAIL.cmdName, self.detailProxy_:get(SEND_STRUCT):getData())
end


function ChampionshipPlayerDetailMediator:OnUnRegist()
    unregPost(POST.CHAMPIONSHIP_GUESS)
    unregPost(POST.CHAMPIONSHIP_PLAYER_DETAIL)
end


function ChampionshipPlayerDetailMediator:InterestSignals()
    return {
        POST.CHAMPIONSHIP_GUESS.sglName,
        POST.CHAMPIONSHIP_PLAYER_DETAIL.sglName,
    }
end
function ChampionshipPlayerDetailMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.CHAMPIONSHIP_PLAYER_DETAIL.sglName then
        local TAKE_STRUCT = DETAIL_PROXY_STRUCT.PLAYER_TAKE
        self.detailProxy_:set(TAKE_STRUCT, data)


    elseif name == POST.CHAMPIONSHIP_GUESS.sglName then
        local TAKE_STRUCT = DETAIL_PROXY_STRUCT.GUESS_TAKE
        self.detailProxy_:set(TAKE_STRUCT, data)

        -- update home.matches voteData
        local playerId        = self.detailProxy_:get(DETAIL_PROXY_STRUCT.PLAYER_ID)
        local matchId         = self.detailProxy_:get(DETAIL_PROXY_STRUCT.MATCH_ID)
        local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
        local matchProxy      = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(matchId))
        local attackerId      = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_ID)
        local defenderId      = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_ID)
        local attackerVote    = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_VOTE)
        local defenderVote    = matchProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_VOTE)
        if playerId == attackerId then
            matchProxy:set(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_VOTE, attackerVote + 1)
        elseif playerId == defenderId then
            matchProxy:set(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_VOTE, defenderVote + 1)
        end

        -- update home.gues data
        local useCurrencyNum = self.detailProxy_:get(TAKE_STRUCT.GUESS_NUM)
        local GUESS_STRUCT   = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.GUESS_DETAIL
        self.mainProxy_:set(GUESS_STRUCT.GUESS_DATA, {}, tostring(matchId))

        local guessProxy     = self.mainProxy_:get(GUESS_STRUCT.GUESS_DATA, tostring(matchId))
        guessProxy:set(GUESS_STRUCT.GUESS_DATA.PLAYER_ID, playerId)
        guessProxy:set(GUESS_STRUCT.GUESS_DATA.GUESS_NUM, useCurrencyNum)

        -- consume currency
        local CURRENCY_ID = FOOD.GOODS.DEFINE.CHAMPIONSHIP_CURRENCY_ID
        CommonUtils.DrawRewards({
            {goodsId = CURRENCY_ID, num = -useCurrencyNum}
        })

        -- show tips
        app.uiMgr:ShowInformationTips(__('投票成功，请耐心等待结算~'))

    end
end


-------------------------------------------------
-- get / set

function ChampionshipPlayerDetailMediator:getViewNode()
    return  self.viewNode_
end
function ChampionshipPlayerDetailMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function ChampionshipPlayerDetailMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- handler

function ChampionshipPlayerDetailMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function ChampionshipPlayerDetailMediator:onClickTeamClickAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local teamIndex      = checkint(sender:getTag())
    local TEAM_STRUCT    = DETAIL_PROXY_STRUCT.PLAYER_TAKE['TEAM' .. teamIndex]
    local PLAYERS_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_PLAYERS
    local playerId       = self.detailProxy_:get(DETAIL_PROXY_STRUCT.PLAYER_ID)
    local playerProxy    = self.mainProxy_:get(PLAYERS_STRUCT.PLAYER_DATA, tostring(playerId))
    local playerName     = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.NAME)
    local playerUnion    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.UNION)
    local playerAvatar   = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.AVATAR)
    local playerFrame    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.FRAME)
    local playerLevel    = playerProxy:get(PLAYERS_STRUCT.PLAYER_DATA.LEVEL)
    app.uiMgr:AddDialog('common.PreviewTeamDetailPopup', {
        playerId = playerId,
        name     = playerName,
        union    = playerUnion,
        avatar   = playerAvatar,
        frame    = playerFrame,
        level    = playerLevel,
        teamData = self.detailProxy_:get(TEAM_STRUCT):getData(),
    })
end


function ChampionshipPlayerDetailMediator:onClickVoteButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local CURRENCY_ID = FOOD.GOODS.DEFINE.CHAMPIONSHIP_CURRENCY_ID
    local goodsAmount = app.goodsMgr:getGoodsNum(CURRENCY_ID)
    if goodsAmount > 0 then
        app.uiMgr:AddNewCommonTipDialog({
            text     = __('确定此轮的投票给这一方么？'),
            extra    = __('每场比赛只能选择一方投票，\n若竞猜失败将不会返还货币。'),
            callback = function()
                local playerId    = self.detailProxy_:get(DETAIL_PROXY_STRUCT.PLAYER_ID)
                local mmatchId    = self.detailProxy_:get(DETAIL_PROXY_STRUCT.MATCH_ID)
                local SEND_STRUCT = DETAIL_PROXY_STRUCT.GUESS_SEND
                self.detailProxy_:set(SEND_STRUCT.MATCH_ID, mmatchId)
                self.detailProxy_:set(SEND_STRUCT.GUESS_ID, playerId)
                self:SendSignal(POST.CHAMPIONSHIP_GUESS.cmdName, self.detailProxy_:get(SEND_STRUCT):getData())
            end,
        })
    else
        local currencyName = GoodsUtils.GetGoodsNameById(CURRENCY_ID)
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {_name_ = currencyName}))
    end
end


return ChampionshipPlayerDetailMediator
