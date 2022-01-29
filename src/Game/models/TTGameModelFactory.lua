--[[
 * author : kaishiqi
 * descpt : 打牌游戏 数据模型工厂
]]
local luasocket = require('socket')
local BaseModel = require('Game.models.BaseModel')

-------------------------------------------------
-- TTGamePlayerModel

local TTGamePlayerModel = class('TTGamePlayerModel', BaseModel)


function TTGamePlayerModel:ctor()
    self.super.ctor(self, 'TTGamePlayerModel')

    self:initProperties_({
        {name = 'PlayerId' , value = '' }, -- 玩家ID
        {name = 'Name'     , value = '' }, -- 玩家名字
        {name = 'Avatar'   , value = '' }, -- 玩家头像
        {name = 'Frame'    , value = '' }, -- 玩家头像框
        {name = 'DeckId'   , value = 0  }, -- 卡组id（自己才有）
        {name = 'Cards'    , value = {} }, -- 携带的卡牌id列表
        {name = 'Plays'    , value = {} }, -- 使用的卡牌位置列表
        {name = 'PlayOrder', value = nil}, -- 使用卡牌的位置顺序
    })
end


function TTGamePlayerModel:hasPlayOrder()
    return #checktable(self:getPlayOrder()) > 0
end


-------------------------------------------------
-- TTGameDeskElemModel

local TTGameDeskElemModel = class('TTGameDeskElemModel', BaseModel)


function TTGameDeskElemModel:ctor()
    self.super.ctor(self, 'TTGameDeskElemModel')

    self:initProperties_({
        {name = 'RowNum' , value = 0 }, -- 行数
        {name = 'ColNum' , value = 0 }, -- 列数
        {name = 'SiteId' , value = 0 }, -- 位置id
        {name = 'CardId' , value = 0 }, -- 卡牌id
        {name = 'OwnerId', value = ''}, -- 玩家id
    })
end


function TTGameDeskElemModel:isEmpty()
    return self:getCardId() == 0
end


-------------------------------------------------
-- TTGameBattleModel

local TTGameBattleModel = class('TTGameBattleModel', BaseModel)

function TTGameBattleModel:ctor(battleType, roomId)
    self.super.ctor(self, 'TTGameBattleModel')

    self:initProperties_({
        {name = 'BattleRoomId'   , value = 0, isReadOnly = true},
        {name = 'BattleType'     , value = TTGAME_DEFINE.BATTLE_TYPE.NONE, isReadOnly = true},
        {name = 'RoundSeconds'   , value = 0    , isReadOnly = true}, -- 当前回合秒数
        {name = 'RoundPlayerId'  , value = ''   }, -- 当前回合玩家
        {name = 'RoomNumber'     , value = 0    }, -- 房间号（好友对战才有）
        {name = 'DeskElemList'   , value = {}   }, -- 桌面元素列表
        {name = 'BattleRuleList' , value = {}   }, -- 战斗规则列表
        {name = 'OperatorModel'  , value = nil  }, -- 操作方玩家模型
        {name = 'OpponentModel'  , value = nil  }, -- 敌对方玩家模型
        {name = 'InitRuleEffects', value = {}   }, -- 初始规则效果
        {name = 'UsedPveRule'    , value = false}, -- 是否使用的PVE规则
    })

    for row = 1, TTGAME_DEFINE.DESK_ELEM_ROWS do
        for col = 1, TTGAME_DEFINE.DESK_ELEM_ROWS do
            local deskElemModel = TTGameDeskElemModel.new()
            deskElemModel:setRowNum(row)
            deskElemModel:setColNum(col)
            deskElemModel:setSiteId(#self:getDeskElemList() + 1)
            table.insert(self:getDeskElemList(), deskElemModel)
        end
    end

    self.BattleType_   = checkint(battleType)
    self.BattleRoomId_ = checkint(roomId)
end


function TTGameBattleModel:updateLeftRoundSeconds(leftSeconds)
    local passedTime = self.RoundSeconds_ - checkint(leftSeconds)
    self.roundTimestamp_ = luasocket.gettime() - passedTime
end
function TTGameBattleModel:updateRoundSeconds(roundSeconds)
    self.RoundSeconds_   = checkint(roundSeconds)
    self.roundTimestamp_ = luasocket.gettime()
end
function TTGameBattleModel:getLeftRoundSeconds()
    return checknumber(self.roundTimestamp_) + checkint(self.RoundSeconds_) - luasocket.gettime()
end


function TTGameBattleModel:getDeckElemModel(deckSiteId)
    return self:getDeskElemList()[checkint(deckSiteId)]
end


function TTGameBattleModel:isFilledDeskCard()
    local isFilledDeskCard = true
    for i, elemModel in ipairs(self:getDeskElemList()) do
        if checkint(elemModel:getCardId()) == 0 then
            isFilledDeskCard = false
            break
        end
    end
    return isFilledDeskCard
end


function TTGameBattleModel:getOperatorScore()
    local deckElemNum = 0
    local playerModel = self:getOperatorModel()
    local operatorId  = tostring(playerModel and playerModel:getPlayerId() or '')
    for index, elemModel in ipairs(self:getDeskElemList()) do
        if elemModel:getOwnerId() == operatorId then
            deckElemNum = deckElemNum + 1
        end
    end
    local leftHandCards = #playerModel:getCards() - #playerModel:getPlays()
    return deckElemNum + leftHandCards
end
function TTGameBattleModel:getOpponentScore()
    local deckElemNum = 0
    local playerModel = self:getOpponentModel()
    local opponentId  = tostring(playerModel and playerModel:getPlayerId() or '')
    for index, elemModel in ipairs(self:getDeskElemList()) do
        if elemModel:getOwnerId() == opponentId then
            deckElemNum = deckElemNum + 1
        end
    end
    local leftHandCards = #playerModel:getCards() - #playerModel:getPlays()
    return deckElemNum + leftHandCards
end


-------------------------------------------------
-- model factory

local TTGameBattleModelFactory = {}

TTGameBattleModelFactory.typeMap_ = {
    ['Battle']   = TTGameBattleModel,
    ['Player']   = TTGamePlayerModel,
    ['DeskElem'] = TTGameDeskElemModel,
}

TTGameBattleModelFactory.getModelType = function(type)
    return TTGameBattleModelFactory.typeMap_[type]
end

return TTGameBattleModelFactory
