
---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator = mvc.Mediator
---@class UnionWarsBattleMemberMediator :Mediator
local UnionWarsBattleMemberMediator = class("UnionWarsBattleMemberMediator", Mediator)
---@type UIManager
local uiMgr = app.uiMgr
local NAME = "UnionWarsBattleMemberMediator"
local UPVP_CHANGE_TEAM_MEMBER_SIGNAL = 'UPVP_CHANGE_TEAM_MEMBER_SIGNAL'
local LOCAL_UWB_TEAM_MEMBERS_KEY = 'LOCAL_UWB_TEAM_MEMBERS_KEY'
local gameMgr = app.gameMgr
--- 用于中转所谓的get方法
local WARS_SITE_MODEL = {
    BUILDINGID         = 'BuildingId',
    PLAYERID           = 'PlayerId',
    PLAYER_LEVEL       = 'PlayerLevel',
    PLAYER_NAME        = 'PlayerName',
    PLAYER_AVATAR      = 'PlayerAvatar',
    PLAYER_AVATARFRAME = 'PlayerAvatarFrame',
    PLAYER_CARDS       = 'PlayerCards',
    PLAYER_HP          = 'PlayerHP',
    DEFEND_STATE       = 'DefendState',
}

local UNION_WARS_MODEL = {
    WARS_BASE_TIME   = "WarsBaseTime",
    WARS_STEPID      = "WarsStepId",
    DEFEND_CARDS_MAP = "DefendCards",
    DEAD_CARDS_MAP   = "DeadCardsMap",
    LEFT_ATTACH_NUM  = "LeftAttachNum",
    TOTAL_ATTACH_NUM = "TotalAttachNum",
    UNION_MAP_MODEL  = "UnionMapModel",
    ENEMY_MAP_MODEL  = "EnemyMapModel",
}

local WARS_MAP_MODEL = {
    UNION_NAME           = "UnionName",
    UNION_AVATAR         = "UnionAvatar",
    UNION_LEVEL          = "UnionLevel",
    WARS_BOSS_R_QUESTID  = "WarsBossRQuestId",
    WARS_BOSS_SR_QUESTID = "WarsBossSRQuestId",
    MAP_SITE_MODEL_MAP   = "MapSiteModelMap",
}
---@type UnionManager
local unionMgr = app.unionMgr
function UnionWarsBattleMemberMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.buildingId = param.buildingId
end
function UnionWarsBattleMemberMediator:InterestSignals()
    local signals = {
        UPVP_CHANGE_TEAM_MEMBER_SIGNAL ,
        POST.UNION_WARS_WIN_BUILD_GET_CURRENCY.sglName
    }
    return signals
end
function UnionWarsBattleMemberMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local responseData = signal:GetBody()
    if name ==  UPVP_CHANGE_TEAM_MEMBER_SIGNAL then
        self:EditTeamMemberCallback(responseData)
    elseif name == POST.UNION_WARS_WIN_BUILD_GET_CURRENCY.sglName then
        local currency = checkint(responseData.currency)
        ---@type UnionWarsBattleMemberView
        local viewComponent = self:GetViewComponent()
        viewComponent:UpdateWinCurrency(currency)
    end

end
function UnionWarsBattleMemberMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type UnionWarsBattleMemberView
    local viewComponent = require('Game.views.unionWars.UnionWarsBattleMemberView').new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    self:SetTeamData(self:GetLocalWBTeamMembers())
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:UpdateBgImage()
    viewComponent:RefreshFriendFightTeam(self:GetTeamData())
    self:RefreshRivalDefenseInfo()
    self:BindingClick()
end
function UnionWarsBattleMemberMediator:RefreshRivalDefenseInfo()
    ---@type WarsSiteModel
    local warsSiteModel = self:GetWarsBuildingDataByBuildingId()
    if warsSiteModel == nil then return end
    ---@type UnionWarsBattleMemberView
    local viewComponent = self:GetViewComponent()

    viewComponent:RefreshRivalDefenseTeam(warsSiteModel.PlayerCards_)
    viewComponent:RefreshEmenyUI(warsSiteModel)

end
function UnionWarsBattleMemberMediator:BindingClick()
    ---@type UnionWarsBattleMemberView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    -- 战斗按钮
    display.commonUIParams(viewData.battleBtn , {cb = handler(self,self.ReadyEnterUnionWMemberBattle)})
    display.commonUIParams(viewData.backBtn , {cb = handler(self,self.UnRegsitMediator)})
    display.commonUIParams(viewData.rivalBuffTipBtn , {cb = handler(self,self.BuffTipClicK)})
    viewData.changeFriendFightTeamBtnLayer:setTouchEnabled(true)
    viewData.changeFriendFightTeamBtnBottomLayer:setTouchEnabled(true)
    display.commonUIParams(viewData.changeFriendFightTeamBtnLayer , {cb = handler(self,self.EditTeamClick)})
    display.commonUIParams(viewData.changeFriendFightTeamBtnBottomLayer , {cb = handler(self,self.EditTeamClick)})
end

function UnionWarsBattleMemberMediator:BuffTipClicK()
    PlayAudioByClickNormal()
    local buildingData = self:GetWarsBuildingDataByBuildingId()
    if buildingData == nil then return end
    ---@type UnionWarsBattleMemberView
    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateBuffLayout(buildingData)
end

function UnionWarsBattleMemberMediator:SetTeamData(data)
    self.teamData = data
end
--[[
获取编队数据
--]]
function UnionWarsBattleMemberMediator:GetTeamData()
    return self.teamData or {}
end

function UnionWarsBattleMemberMediator:GetWarsQuestId()
    return self.warsBossQuestId or 46001
end
---==============================--
---@Description: 获取防守的卡牌
--==============================--
function UnionWarsBattleMemberMediator:GetDefenceCards()
    local  defencesMapCardsStr =  self:GetUnionWarsModelValueByKey(UNION_WARS_MODEL.DEFEND_CARDS_MAP)
    local defencesListCards = table.split(defencesMapCardsStr ,",")
    local limitDefences = {}
    local cards = app.gameMgr:GetUserInfo().cards
    local cardId = nil
    for index , id  in pairs(defencesListCards) do
        if checkint(id) > 0  then
            if  cards[tostring(id)] then
                cardId = cards[tostring(id)].cardId
                limitDefences[tostring(cardId)] = cardId
            end
        end
    end
    return limitDefences
end
---==============================--
---@Description:根据buildingId 获取到
---@return WarsMapModel
--==============================--
function UnionWarsBattleMemberMediator:GetWarsBuildingDataByBuildingId()
    local mapSiteModelMap = self:GetWarsMapModelValueByKey(WARS_MAP_MODEL.MAP_SITE_MODEL_MAP)
    return mapSiteModelMap and mapSiteModelMap[tostring(self.buildingId)] or nil
end

---==============================--
---@Description: 获取到已经阵亡的卡牌
--==============================--
function UnionWarsBattleMemberMediator:GetDeadCards()
    local  deadMapCards =  self:GetUnionWarsModelValueByKey(UNION_WARS_MODEL.DEAD_CARDS_MAP)
    local deadListCards = {}
    local cards = app.gameMgr:GetUserInfo().cards
    local cardId = nil
    for id , v in pairs(deadMapCards) do
        cardId = cards[tostring(id)]
        deadListCards[tostring(cardId)] = cardId
    end
    return deadListCards
end
---==============================--
---@Description: 获取到公会战剩余的总次数
--==============================--
function UnionWarsBattleMemberMediator:GetLeftAttackNum()
    local leftAttackNum = self:GetUnionWarsModelValueByKey(UNION_WARS_MODEL.LEFT_ATTACH_NUM)
    return  leftAttackNum
end
---==============================--
---@Description: 获取到公会战挑战的总次数
--==============================--
function UnionWarsBattleMemberMediator:GetTotalAttackNum()
    local totalAttackNum = self:GetUnionWarsModelValueByKey(UNION_WARS_MODEL.TOTAL_ATTACH_NUM)
    return totalAttackNum
end

---==============================--
---@Description: 通过key 返回对应的 UnionWarsModel属性
--==============================--
function UnionWarsBattleMemberMediator:GetUnionWarsModelValueByKey(key)
    local unionWarsModel =   unionMgr:getUnionWarsModel()
    local values =  unionWarsModel["get" ..  key](unionWarsModel)
    return values
end

---==============================--
---@Description: 通过key 返回对应的 WarsMapModel 属性
--==============================--
function UnionWarsBattleMemberMediator:GetWarsMapModelValueByKey(key)
    local warsMapModel = self:GetUnionWarsModelValueByKey(UNION_WARS_MODEL.ENEMY_MAP_MODEL)
    local values = warsMapModel and warsMapModel["get" .. key]() or nil
    return values
end
---==============================--
---@Description: 通过key 返回对应的 WarsSiteModel 属性
---@param key string 对应的属性 
---@param buildingId number 建筑点WarsSiteModel
--==============================--
function UnionWarsBattleMemberMediator:GetWarsSiteModelValueByKey(key , buildingId )
    local mapSiteModelMap = self:GetWarsMapModelValueByKey(WARS_MAP_MODEL.MAP_SITE_MODEL_MAP)
    local mapSiteModel =  mapSiteModelMap and mapSiteModelMap[tostring(buildingId)] or nil
    if mapSiteModel then
        return  mapSiteModel['get' .. key]()
    end
    return nil
end


function UnionWarsBattleMemberMediator:EditTeamMemberCallback(data)
    ------------ data ------------
    self:SetTeamData(data.teamData)
    -- 保存一次本地缓存
    ------------ data ------------
    self:SetLocalWBTeamMembers(self:GetTeamData())
    ------------ view ------------
    -- 关闭阵容界面
    AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')

    self:GetViewComponent():RefreshFriendFightTeam(self:GetTeamData())
    ------------ view ------------
end
function UnionWarsBattleMemberMediator:SetLocalWBTeamMembers(data)
    local str = json.encode(data)
    cc.UserDefault:getInstance():setStringForKey(self:GetLocalTeamDataKey(), str)
    cc.UserDefault:getInstance():flush()
end
--[[
获取编队数据
--]]
function UnionWarsBattleMemberMediator:GetTeamData()
    return self.teamData or {}
end
--==============================--
---@Description: 编辑队伍
---@author : xingweihao
---@date : 2019/4/11 2:04 PM
--==============================--

function UnionWarsBattleMemberMediator:EditTeamClick()
    PlayAudioByClickNormal()
    local deadCards = self:GetDeadCards()
    --local defencesCards = app.unionMgr:getUnionWarsModel():isJoinMember() and self:GetDefenceCards() or {}
    local defencesCards = {}
    local limitCards = {}
    -- 收集限制的卡牌
    for i, cardId  in pairs(deadCards) do
        limitCards[tostring(cardId)] = cardId
    end
    for i, cardId  in pairs(defencesCards) do
        limitCards[tostring(cardId)] = cardId
    end

    local cards = app.gameMgr:GetUserInfo().cards
    local allCards = {}
    for id, cardData  in pairs(cards) do
        -- 排除掉收集限制的卡牌
        if not limitCards[tostring( cardData.cardId)]  then
            allCards[#allCards+1] = cardData.cardId
        end
    end
    local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
       teamDatas = {[1] = clone(self:GetTeamData())},
       title = __('编辑队伍'),
       teamTowards = 1,
       avatarTowards = 1,
       backCloseShow = false ,
       isDisableHomeTopSignal = true ,
       allCards = allCards ,
       teamChangeSingalName = UPVP_CHANGE_TEAM_MEMBER_SIGNAL,
       battleType = 1
    })
    layer:setAnchorPoint(display.CENTER)
    layer:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(layer)
end

function UnionWarsBattleMemberMediator:ReadyEnterUnionWMemberBattle(data)
    -- 检查阵容
    PlayAudioByClickNormal()
    local leftAttackNum = self:GetLeftAttackNum()
    if leftAttackNum <= 0 then
        uiMgr:ShowInformationTips(__('次数不足!!!'))
        return
    end
    local hasCard = false
    for i,v in ipairs(self:GetTeamData()) do
        if nil ~= v.id then
            local c_id = checkint(v.id)
            local cardData = gameMgr:GetCardDataById(c_id)
            if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
                hasCard = true
                break
            end
        end
    end
    if not hasCard then
        -- 没带卡
        uiMgr:ShowInformationTips(__('队伍不能为空!!!'))
        return
    end
    self:EnterUnionPVPBattle()
end

function UnionWarsBattleMemberMediator:UnRegsitMediator(sender)
    PlayAudioByClickClose()
    sender:setEnabled(false)
    app:UnRegsitMediator(NAME)
end
--[[
进入战斗
--]]
function UnionWarsBattleMemberMediator:EnterUnionPVPBattle()
    local teamDataStr = self:ConvertTeamData2Str(self:GetTeamData())
    local fixedTeamData = {}
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local cardInfo = self:GetTeamData()[i]
        if nil ~= cardInfo and nil ~= cardInfo.id then
            fixedTeamData[i] = checkint(cardInfo.id)
        end
    end
    local buildingData = self:GetWarsBuildingDataByBuildingId()
    if buildingData == nil then return end

    local rivalTeamData = buildingData:getPlayerCards()
    local defendDebuffId = buildingData:getDebuffId()
    -- 服务器参数
    local serverCommand = BattleNetworkCommandStruct.New(

            POST.UNION_WARS_ENEMY_QUEST_AT.cmdName ,
            {warsBuildingId = self.buildingId, cards = teamDataStr},
            POST.UNION_WARS_ENEMY_QUEST_AT.sglName,
            
            POST.UNION_WARS_ENEMY_QUEST_GRADE.cmdName ,
            {warsBuildingId = self.buildingId},
            POST.UNION_WARS_ENEMY_QUEST_GRADE.sglName ,
            
            nil,
            nil,
            nil
    )
    local defendDebuffIds =  {}
    if defendDebuffId and checkint(defendDebuffId) > 0  then
        defendDebuffIds[#defendDebuffIds+1] = defendDebuffId
    end
    local fromToStruct = BattleMediatorsConnectStruct.New(
            "unionWars.UnionWarsBattleMemberMediator",
            "unionWars.UnionWarsHomeMediator"
    )
    local  teamData = {}
    for k, v in pairs(self:GetTeamData()) do
        teamData[checkint(k)] = checkint(v.id)
    end

    -- 选择的主角技信息
    local playerSkillData = {
        0, 0

    }
    local rivalSkillData = {
        0,0
    }
    -- 创建战斗构造器
    local battleConstructor = require('battleEntry.BattleConstructor').new()
    battleConstructor:InitByCommonPVCSingleTeam(
            QuestBattleType.UNION_PVC,
            ConfigBattleResultType.ONLY_RESULT_AND_REWARDS,
            teamData,
            rivalTeamData,
            playerSkillData ,
            rivalSkillData,
            defendDebuffIds,
            nil ,
            serverCommand,
            fromToStruct
    )
    battleConstructor:OpenBattle()
    ------------ 初始化战斗构造器 -----------
end

--[[
本地保存的队伍信息
--]]
function UnionWarsBattleMemberMediator:GetLocalWBTeamMembers()
    local str = cc.UserDefault:getInstance():getStringForKey(self:GetLocalTeamDataKey(), '{}')
    local table = json.decode(str)
    return table
end

--[[
获取保存阵容的本地key
--]]
function UnionWarsBattleMemberMediator:GetLocalTeamDataKey()
    return tostring(app.gameMgr:GetUserInfo().playerId) .. LOCAL_UWB_TEAM_MEMBERS_KEY
end

--[[
获取转换后传给服务器的阵容数据
@params teamData table
@return str string 阵容数据
--]]
function UnionWarsBattleMemberMediator:ConvertTeamData2Str(teamData)
    local str = ''
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local cardInfo = teamData[i]
        if nil ~= cardInfo and nil ~= cardInfo.id and 0 ~= checkint(cardInfo.id) then
            str = str .. cardInfo.id
        end
        str = str .. ','
    end
    return str
end
function UnionWarsBattleMemberMediator:EnterLayer()
    self:SendSignal(POST.UNION_WARS_WIN_BUILD_GET_CURRENCY.cmdName , {buildingId = self.buildingId })
end
--[[
    注册的通知
--]]
function UnionWarsBattleMemberMediator:OnRegist()
    regPost(POST.UNION_WARS_WIN_BUILD_GET_CURRENCY)
    self:EnterLayer()
end

function UnionWarsBattleMemberMediator:OnUnRegist()
    unregPost(POST.UNION_WARS_WIN_BUILD_GET_CURRENCY)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return UnionWarsBattleMemberMediator

