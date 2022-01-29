--[[
 * author : kaishiqi
 * descpt : 武道会 - 海选赛中介者
]]
local ChampionshipAuditionsView     = require('Game.views.championship.ChampionshipAuditionsView')
local ChampionshipAuditionsMediator = class('ChampionshipAuditionsMediator', mvc.Mediator)

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT

function ChampionshipAuditionsMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipAuditionsMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function ChampionshipAuditionsMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.isControllable_ = true

    -- init model
    self.mainProxy_ = app:RetrieveProxy(MAIN_PROXY_NAME)

    -- create view
    if self.ownerNode_ then
        self.viewNode_ = ChampionshipAuditionsView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self:getViewNode())

        -- add listener
        ui.bindClick(self:getViewData().rankBtn, handler(self, self.onClickRankButtonHandler_))
        ui.bindClick(self:getViewData().shopBtn, handler(self, self.onClickShopButtonHandler_))
        ui.bindClick(self:getViewData().rewardBtn, handler(self, self.onClickRewardButtonHandler_))
        ui.bindClick(self:getViewData().battleButton, handler(self, self.onClickBattleButtonHandler_))
        ui.bindClick(self:getViewData().ticketRLabel, handler(self, self.onClickTicketButtonHandler_), false)
        ui.bindClick(self:getViewData().teamEditArea, handler(self, self.onClickTeamEditAreaHandler_), false)
        ui.bindClick(self:getViewData().scheduleFrame, handler(self, self.onClickScheduleFrameHandler_), false)
        ui.bindClick(self:getViewData().playerAvatarLayer, handler(self, self.onClickTeamEditAreaHandler_), false)
        ui.bindClick(self:getViewData().opponentAvatarLayer, handler(self, self.onClickQuestBossAreaHandler_), false)
    end
end


function ChampionshipAuditionsMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function ChampionshipAuditionsMediator:OnRegist()
    regPost(POST.CHAMPIONSHIP_TICKET)
    regPost(POST.CHAMPIONSHIP_AUDITION)
end


function ChampionshipAuditionsMediator:OnUnRegist()
    unregPost(POST.CHAMPIONSHIP_TICKET)
    unregPost(POST.CHAMPIONSHIP_AUDITION)
end


function ChampionshipAuditionsMediator:InterestSignals()
    return {
        POST.CHAMPIONSHIP_TICKET.sglName,
        POST.CHAMPIONSHIP_AUDITION.sglName,
    }
end
function ChampionshipAuditionsMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -------------------------------------------------
    -- buy ticket
    if name == POST.CHAMPIONSHIP_TICKET.sglName then
        -- update ticketNum
        local buyNumber = self.mainProxy_:get(MAIN_PROXY_STRUCT.TICKET_BUY_SEND.BUY_NUM)
        local ticketNum = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TICKET)
        self.mainProxy_:set(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TICKET, ticketNum + buyNumber)
        
        -- update consume
        local seasonId   = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SEASON_ID)
        local seasonConf = CONF.CHAMPIONSHIP.SCHEDULE:GetValue(seasonId)
        local consumeId  = checkint(seasonConf.consumeId)
        local consumeNum = checkint(seasonConf.consumeNum)
        CommonUtils.DrawRewards({ {goodsId = consumeId, num = -consumeNum * buyNumber} })

        -- tips succeed
        app.uiMgr:ShowInformationTips(__('成功追加挑战次数'))


    -------------------------------------------------
    -- audition team
    elseif name == POST.CHAMPIONSHIP_AUDITION.sglName then
        -- update team
        local cardUuids = self.mainProxy_:get(MAIN_PROXY_STRUCT.AUDITION_TEAM_SEND.CARD_UUIDS)
        self.mainProxy_:set(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TEAM, string.split2(cardUuids, ','))
        
        -- tips succeed
        app.uiMgr:ShowInformationTips(__('成功更新队伍配置'))
    
    end
end


-------------------------------------------------
-- get / set

function ChampionshipAuditionsMediator:getViewNode()
    return  self.viewNode_
end
function ChampionshipAuditionsMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function ChampionshipAuditionsMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- handler

function ChampionshipAuditionsMediator:onClickRankButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local storeMdt = require('Game.mediator.championship.ChampionshipAuditionsRankMediator').new()
    app:RegistMediator(storeMdt)
end


function ChampionshipAuditionsMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local storeMdt = require('Game.mediator.championship.ChampionshipShopMediator').new()
    app:RegistMediator(storeMdt)
end


function ChampionshipAuditionsMediator:onClickRewardButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    app.uiMgr:AddDialog('Game.views.championship.ChampionshipRewardPreviewPopup', {type = 1})
end


function ChampionshipAuditionsMediator:onClickBattleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    -- 关卡id
    local auditionsQuestId = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_QUEST_ID)

    -- 服务器参数
	local serverCommand = BattleNetworkCommandStruct.New(
        POST.CHAMPIONSHIP_QUEST_AT.cmdName,    {questId = auditionsQuestId}, POST.CHAMPIONSHIP_QUEST_AT.sglName,
        POST.CHAMPIONSHIP_QUEST_GRADE.cmdName, {questId = auditionsQuestId}, POST.CHAMPIONSHIP_QUEST_GRADE.sglName,
        nil, nil, nil  -- 买活
    )
    
    -- 跳转参数
    local fromToStruct = BattleMediatorsConnectStruct.New(
        'championship.ChampionshipHomeMediator', -- from mdt
        'championship.ChampionshipHomeMediator'  -- to mdt
    )

    -- 创建战斗构造器
    local battleConstructor = require('battleEntry.BattleConstructorEx').new()

    -- 友方阵容
    local AUDITION_TEAM_STRUCT    = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TEAM
    local auditionsFriendTeamData = {[1] = self.mainProxy_:get(AUDITION_TEAM_STRUCT):getData()}
    local formattedFriendTeamData = battleConstructor:GetFormattedTeamsDataByTeamsMyCardData(auditionsFriendTeamData)
    
    -- 敌方阵容
    local formattedEnemyTeamData = battleConstructor:GetCommonEnemyTeamDataByStageId(auditionsQuestId)

    -- 初始战斗结构体
    battleConstructor:InitByCommonData(
        auditionsQuestId,                       -- 关卡 id
        QuestBattleType.CHAMPIONSHIP_AUDITIONS, -- 战斗类型
        ConfigBattleResultType.NONE_DROP,       -- 结算类型
        ----
        formattedFriendTeamData,                -- 友方阵容
        formattedEnemyTeamData,                 -- 敌方阵容
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
        serverCommand,                          -- 与服务器交互的命令信息
        fromToStruct                            -- 跳转信息
    )
    battleConstructor:OpenBattle()
end


function ChampionshipAuditionsMediator:onClickTicketButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local seasonId   = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SEASON_ID)
    local seasonConf = CONF.CHAMPIONSHIP.SCHEDULE:GetValue(seasonId)
    local consumeId  = checkint(seasonConf.consumeId)
    local consumeNum = checkint(seasonConf.consumeNum)
    local buyNumber  = 1
    local tipStrings = string.split2(string.fmt(__('确定要追加|_num_|次挑战次数吗？'), {_num_ = buyNumber}), '|')
    
    app.uiMgr:AddCommonTipDialog({defaultRichPattern = true,
        costInfo = {goodsId = consumeId, num = consumeNum},
        textRich = {
            {text = tipStrings[1]},
            {text = tipStrings[2], color = '#ff0000'},
            {text = tipStrings[3]}
        },
        callback = function()
            if CommonUtils.GetCacheProductNum(consumeId) >= consumeNum * buyNumber then
                -- send post
                local SEND_STRUCT = MAIN_PROXY_STRUCT.TICKET_BUY_SEND
                self.mainProxy_:set(SEND_STRUCT.BUY_NUM, buyNumber)
                self:SendSignal(POST.CHAMPIONSHIP_TICKET.cmdName, self.mainProxy_:get(SEND_STRUCT):getData())

            else
                -- tips lack
				if GAME_MODULE_OPEN.NEW_STORE and consumeId == DIAMOND_ID then
					app.uiMgr:showDiamonTips()
                else
                    local consumeGoodsName = CommonUtils.GetCacheProductName(consumeId)
					app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {_name_ = consumeGoodsName}))
				end
			end
        end
    })
end


function ChampionshipAuditionsMediator:onClickTeamEditAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local TEAM_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_TEAM
    local teamProxy   = self.mainProxy_:get(TEAM_STRUCT)
    local editTeamMdt = require('Game.mediator.presetTeam.PresetTeamEditTeamMediator').new({
        editName = false,
        data = {
            name    = __('海选赛队伍'),
            cardIds = { teamProxy:getData() },
        },
        conf = {
            cardCount    = 5, -- 卡牌个数
            minCardCount = 5, -- 最小卡牌个数
            maxTeamCount = 1, -- 最大团队个数
        },
        saveCB = function(saveData)
            local SEND_STRUCT = MAIN_PROXY_STRUCT.AUDITION_TEAM_SEND
            local teamCards   = checktable(saveData.teamCards)[1] or {}
            local cardUuids   = {}
            for cardIndex, cardData in ipairs(teamCards) do
                cardUuids[cardIndex] = checkstr(cardData.id)
            end
            self.mainProxy_:set(SEND_STRUCT.CARD_UUIDS, table.concat(cardUuids, ','))
            self:SendSignal(POST.CHAMPIONSHIP_AUDITION.cmdName, self.mainProxy_:get(SEND_STRUCT):getData())
        end
    })
    app:RegistMediator(editTeamMdt)
end


function ChampionshipAuditionsMediator:onClickQuestBossAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local auditionsQuestId = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_QUEST_ID)
    app:RegistMediator(require('Game.mediator.BossDetailMediator').new({questId = auditionsQuestId}))
end


function ChampionshipAuditionsMediator:onClickScheduleFrameHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    app.uiMgr:AddDialog('Game.views.championship.ChampionshipTimelinePopup')
end


return ChampionshipAuditionsMediator
