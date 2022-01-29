--[[
 * descpt : 卡牌阵容
 * params 
 *       captainFlag      int -1 队长在左侧  1 队长在右侧
 *       viewSize         table  视图大小
 *       cardDatas        table  卡牌数据列表
 *       cardNodeScale    int    卡牌节点缩放值
 *       disabledSelfData bool  禁用自身的最新卡牌数据
]]
local CommonCardLineupNode = class('CommonCardLineupNode', function ()
	local node = CLayout:create()
	node.name = 'common.CommonCardLineupNode'
	node:enableNodeEvents()
	return node
end)

local RES_DICT = {
    TEAM_ICO_CAPTAIN = _res('ui/home/teamformation/team_ico_captain.png')
}

function CommonCardLineupNode:ctor( ... )
    self.args       = unpack({...}) or {}

    self.cardLineup = {}
    self:InitData(self.args)
    self:InitialUI()
end

function CommonCardLineupNode:InitialUI()
    self:setContentSize(self.viewSize)
end

function CommonCardLineupNode:InitData(args)
    self.cardNodeScale    = args.cardNodeScale
    self.viewSize         = args.viewSize
    self.disabledSelfData = args.disabledSelfData
    -- self:InitValue(args)
    self:RefreshUI(args)
end

function CommonCardLineupNode:InitValue(args)
    self.captainFlag     = args.captainFlag or -1
    self.cardDatas       = args.cardDatas or {}
end

function CommonCardLineupNode:RefreshUI(args)
    self:InitValue(args)

    local cardDatas = self.cardDatas
    local cardLineup = self.cardLineup

    local increment = self.captainFlag * -1
    
    local selfPlayerId = checkint(app.gameMgr:GetUserInfo().playerId)
    local viewWidth = self.viewSize.width
    local cellWidth = viewWidth / (MAX_TEAM_MEMBER_AMOUNT)
    local cellHeight = self.viewSize.height * 0.5
    for i = 1, MAX_TEAM_MEMBER_AMOUNT, 1 do
        local cardData = cardDatas[i] or {}
        local selfCardId = cardData.id
        local confId     = cardData.cardId
        if selfCardId == nil and confId == nil then
            local cardNode = cardLineup[i]
            if cardNode then
                cardNode:setVisible(false) 
            end
        else
            local cardHeadNodeData
            if not self.disabledSelfData and selfPlayerId == checkint(cardData.playerId) then
                cardHeadNodeData = {
                    id = selfCardId,
                    showBaseState = true, showActionState = false, showVigourState = false
                }
            else
                cardHeadNodeData = {
                    cardData = {cardId = confId, level = checkint(cardData.level or cardData.cardLevel), breakLevel = checkint(cardData.breakLevel), skinId = checkint(cardData.defaultSkinId or cardData.cardSkinId), favorabilityLevel = cardData.favorabilityLevel},
                    showBaseState = true, showActionState = false, showVigourState = false
                }
            end
            
            local cardNode = cardLineup[i]
            if cardNode then
                cardNode:RefreshUI(cardHeadNodeData)
                cardNode:setVisible(true)
            else
                cardNode = require('common.CardHeadNode').new(cardHeadNodeData)
                cardNode:setScale(self.cardNodeScale)
                cardLineup[i] = cardNode
                local pos, ap
                if self.captainFlag ~= 1 then
                    pos = cc.p((i - 1) * cellWidth, cellHeight)
                    ap = display.LEFT_CENTER
                else
                    pos = cc.p(viewWidth - (i - 1) * cellWidth, cellHeight)
                    ap = display.RIGHT_CENTER
                end
                cardNode:setAnchorPoint(ap)
                cardNode:setPosition(pos)
                self:addChild(cardNode)

                if i == 1 then
                    local cardHeadNodeSize = cardNode:getContentSize()
                    local markOffsetX = cardHeadNodeSize.width * 0.5 * self.cardNodeScale * increment
                    local captainMark = display.newImageView(RES_DICT.TEAM_ICO_CAPTAIN, cardNode:getPositionX() + markOffsetX, cardHeadNodeSize.height * 0.5 * self.cardNodeScale - 10, {ap = display.CENTER_BOTTOM})
                    self:addChild(captainMark)
                end

            end
        end
    end
end

return CommonCardLineupNode