--[[
 * descpt : 3v3 防守队伍 view
 * params 
 *       teamMarkPosSign 1 队长在左侧  2 队长在右侧
]]
local TagMatchDefensiveTeamView = class('TagMatchDefensiveTeamView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.tagMatch.TagMatchDefensiveTeamView'
	node:enableNodeEvents()
	return node
end)

local CreateView     = nil
local CreateTeamNode = nil

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')

local RES_DIR = {
    RANK_BG                = _res('ui/tagMatch/3v3_ranks_bg'),
}

function TagMatchDefensiveTeamView:ctor( ... )
    self.args = unpack({...}) or {}

    self:initialUI()
end

function TagMatchDefensiveTeamView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(self.args.teamMarkPosSign or -1)
        self:addChild(self.viewData_.view)
        -- self:setBackgroundColor(cc.c4b(100, 200, 100, 128))

        self.viewSize = self.viewData_.view:getContentSize()
        self:setContentSize(self.viewSize)

        self:initData()
        self:initView()
	end, __G__TRACKBACK__)
end

function TagMatchDefensiveTeamView:initData()
    
end

function TagMatchDefensiveTeamView:initView()
    local teamId    = self.args.teamId or ''
    local teamDatas = self.args.teamDatas or {}
    local isOppoentTeam  = self.args.isOppoentTeam
    -- print('teamId = ', teamId)
    -- dump(teamDatas, 'teamDatasteamDatas')
    self.battlePoint = self:refreshTeam(teamId, teamDatas, isOppoentTeam)
end

function TagMatchDefensiveTeamView:onEnter()

end

function TagMatchDefensiveTeamView:refreshTeam(teamId, teamDatas, isOppoentTeam)
	teamDatas = teamDatas or {}
    local viewData       = self:getViewData()
    
    -- 更新队伍名字
    self:updateTeamName(teamId)
    
    local cardDatas = isOppoentTeam and teamDatas.cards or teamDatas
    
    local battlePoint = self:updateTeam(cardDatas, isOppoentTeam)

    battlePoint = isOppoentTeam and checkint(teamDatas.battlePoint) or battlePoint

    self:updateTeamManaLabel(battlePoint)

    return battlePoint
end

function TagMatchDefensiveTeamView:updateTeamName(teamId)
    local viewData       = self:getViewData()
    local teamName       = viewData.teamName
    
    display.commonLabelParams(teamName, {text = string.fmt(__('队伍_num_'), {['_num_'] = teamId})})
end

function TagMatchDefensiveTeamView:updateTeam(teamDatas, isOppoentTeam)
    local viewData       = self:getViewData()
    local view           = viewData.view
    local teamNodes      = viewData.teamNodes
    local teamEmptyNodes = viewData.teamEmptyNodes
    local battlePoint    = 0

    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local cardData = teamDatas[i] or {}
        local cid = isOppoentTeam and checkint(cardData.cardId) or checkint(cardData.id)
        -- logInfo.add(5, cid .. ' = cid')
        local teamEmptyNode = teamEmptyNodes[MAX_TEAM_MEMBER_AMOUNT-i+1]
        
        if cid ~= 0 then
            local cardHeadNodeData = nil
            if isOppoentTeam then
                cardHeadNodeData = {
                    cardData = {cardId = cid, level = checkint(cardData.level or cardData.cardLevel), breakLevel = checkint(cardData.breakLevel), skinId = checkint(cardData.defaultSkinId or cardData.cardSkinId), favorabilityLevel = cardData.favorabilityLevel},
                    showBaseState = true, showActionState = false, showVigourState = false
                }
            else
                cardHeadNodeData = {
                    id = cid,
                    showBaseState = true, showActionState = false, showVigourState = false
                }
            end

            local teamNode = teamNodes[i]
            if teamNode then
                teamNode:setVisible(true)
                local cardHeadNode = teamNode:getChildByName('cardHeadNode')
                
                cardHeadNode:RefreshUI(cardHeadNodeData)
            else
                teamNode = CreateTeamNode(cardHeadNodeData, i == 1, isOppoentTeam)
                teamNodes[i] = teamNode
                local x, y = teamEmptyNode:getPosition()
                display.commonUIParams(teamNode, {po = cc.p(x, y), ap = display.CENTER})
                view:addChild(teamNode)
            end
            teamEmptyNode:setVisible(false)
            if not isOppoentTeam then
                if teamDatas[i].cardId then
                    battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointByCardData(teamDatas[i])
                else
                    battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointById(cid)
                end
            end
        else
            local teamNode = teamNodes[i]
            if teamNode then
                teamNode:setVisible(false) 
            end
            teamEmptyNode:setVisible(true)
        end
    end

    return battlePoint
end

function TagMatchDefensiveTeamView:updateTeamManaLabel(battlePoint)
    local viewData       = self:getViewData()
    local teamMana       = viewData.teamMana
    display.commonLabelParams(teamMana, {text = string.fmt(__('灵力:_num_'), {['_num_'] = battlePoint})})

end

CreateView = function (teamMarkPosSign)
    local bg = display.newImageView(RES_DIR.RANK_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local size = bg:getContentSize()
    bg:setScaleX(teamMarkPosSign)
    
    display.commonUIParams(bg, {po = cc.p(teamMarkPosSign == -1 and size.width or 0, 0)})

    local view = display.newLayer(0, 0, {size = size})
    view:addChild(bg)

    local teamDescLayerSize = cc.size(305, 33)
    local teamDescLayer = display.newLayer(teamMarkPosSign == -1 and 210 or 0, size.height - 18, {size = teamDescLayerSize, ap = display.LEFT_CENTER})
    view:addChild(teamDescLayer)

    local teamName = display.newLabel(10, teamDescLayerSize.height / 2, fontWithColor(14, {ap = display.LEFT_CENTER, fontSize = 22}))
    teamDescLayer:addChild(teamName)

    local teamMana = display.newLabel(300, teamName:getPositionY(), fontWithColor(4, {ap = display.RIGHT_CENTER, color = '#FFD555', fontSize = 22}))
    teamDescLayer:addChild(teamMana)

    local teamEmptyNodes = {}
    -- 友方空阵容
    for i = 1, MAX_TEAM_MEMBER_AMOUNT, 1 do
        local defaultHead = display.newImageView(_res('ui/pvc/pvp_main_ico_nocard.png'), 0, 0)
        -- dump(defaultHead:getContentSize(), 'defaultHead')
        local params = {index = teamMarkPosSign == -1 and (MAX_TEAM_MEMBER_AMOUNT - i + 1) or i, goodNodeSize = defaultHead:getContentSize(), midPointX = size.width / 2 - teamMarkPosSign * 10, midPointY = size.height / 2 - 10, col = 5, maxCol = 5, scale = 1, goodGap = 8}
        local pos = CommonUtils.getGoodPos(params)
        display.commonUIParams(defaultHead, {po = pos})
        view:addChild(defaultHead)

        teamEmptyNodes[i] = defaultHead
    end
    
    return {
        view              = view,
        teamName          = teamName,
        teamMana          = teamMana,
        teamEmptyNodes    = teamEmptyNodes,
        teamNodes         = {},
    }
end

CreateTeamNode = function (cardHeadNodeData, isCaptain)
    local cardHeadLayerSize = cc.size(81, 81)
    local cardHeadLayer = display.newLayer(0, 0, {size = cardHeadLayerSize})

    local cardHeadNode = require('common.CardHeadNode').new(cardHeadNodeData)
    cardHeadNode:setScale(0.45)
    cardHeadNode:setPosition(cc.p(cardHeadLayerSize.width / 2, cardHeadLayerSize.height / 2))
    cardHeadLayer:addChild(cardHeadNode)
    cardHeadNode:setName('cardHeadNode')
    
    if isCaptain then
        -- 队长mark
        local captainMark = display.newImageView(_res('ui/home/teamformation/team_ico_captain.png'), cardHeadLayerSize.width / 2, cardHeadLayerSize.height / 2 - 5, {ap = display.CENTER_BOTTOM})
        cardHeadLayer:addChild(captainMark)
    end

    cardHeadLayer.viewData = {
        cardHeadNode = cardHeadNode
    }
    return cardHeadLayer
end

function TagMatchDefensiveTeamView:getViewData()
	return self.viewData_
end

function TagMatchDefensiveTeamView:getBattlePoint()
    return self.battlePoint
end

return TagMatchDefensiveTeamView