--[[
 * descpt : 3v3 防守队伍 view
]]
local VIEW_SIZE = display.size
local TagMatchDefensiveLineupView = class('TagMatchDefensiveLineupView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.tagMatch.TagMatchDefensiveLineupView'
	node:enableNodeEvents()
	return node
end)

local CreateView = nil
local CreateCell = nil

local convertTeamDataFromString2StrList = nil

local uiMgr    = AppFacade.GetInstance():GetManager('UIManager')

local RES_DIR = {
    BG                     = _res('ui/common/common_bg_2.png'),
    TITLE                  = _res('ui/common/common_bg_title_2.png'),
    RANK_BG                = _res('ui/tagMatch/3v3_ranks_bg'),
    DEFEND_BG              = _res('ui/tagMatch/3v3_defend_bg'),
}

function TagMatchDefensiveLineupView:ctor( ... )
    self.args = unpack({...}) or {}
    
    self:initialUI()
end

function TagMatchDefensiveLineupView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
        
        self:initData()
        self:initView()
	end, __G__TRACKBACK__)
end

function TagMatchDefensiveLineupView:initData()
    -- local defenseTeams = self.args.defenseTeams or {}
    -- local cardsDatas = {}
    -- for i, teamData in pairs(defenseTeams) do
    --     cardsDatas[i] = cardsDatas[i] or {}
    --     for ii, cardData in ipairs(teamData) do
    --         table.insert(cardsDatas[i], cardData.id)
    --     end
    -- end
    self.defendCards = self.args.defenseTeams or {}
    -- logInfo.add(5, tableToString(self.defendCards))
end

function TagMatchDefensiveLineupView:initView()
    local viewData = self:getViewData()
    local shallowLayer = viewData.shallowLayer
    display.commonUIParams(shallowLayer, {cb = handler(self, self.onClickShallowAction)})

    self:updateTeamViews()
end

function TagMatchDefensiveLineupView:updateTeamViews()
    local viewData = self:getViewData()
    local fight_num = viewData.fight_num

    local contentLayer = viewData.contentLayer
    local contentLayerSize = contentLayer:getContentSize()
    local teams = {}
    local totalBattlePoint = 0
    for teamId, cardDatas in pairs(self.defendCards) do
        -- local teamCards = convertTeamDataFromString2StrList(cardDatas)
        local team = self:CreateTeamView(teamId, cardDatas)
        display.commonUIParams(team, {po = cc.p(contentLayerSize.width / 2, contentLayerSize.height - 142 - (checkint(teamId) - 1) * 164) , ap = display.CENTER})
        contentLayer:addChild(team)
        table.insert(teams, team)
        local teamView = team:getChildByName('teamView')
        totalBattlePoint = totalBattlePoint + teamView:getBattlePoint()
    end

    viewData.teams = teams

    fight_num:setString(totalBattlePoint)
end

function TagMatchDefensiveLineupView:onClickShallowAction(sender)
    if not  self.isClose then
        self.isClose = true
        uiMgr:GetCurrentScene():RemoveDialog(self)
    end
end

function TagMatchDefensiveLineupView:onEnter()

end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local shallowLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(shallowLayer)

    local bgLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, bg = RES_DIR.BG})
	local bgSize = bgLayer:getContentSize()
    view:addChild(bgLayer)

    local touchLayer = display.newLayer(bgSize.width / 2, bgSize.height / 2, {color = cc.c4b(0, 0, 0, 0), enable = true, size = bgSize, ap = display.CENTER})
    bgLayer:addChild(touchLayer)

    local titleBg = display.newButton(0, 0, {n = RES_DIR.TITLE, animation = false})
    display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
    display.commonLabelParams(titleBg,
        {text = __('防守队伍'),
        fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
        offset = cc.p(0, -2)})
    bgLayer:addChild(titleBg)

    local contentLayerSize = cc.size(bgSize.width - 46, bgSize.height - 50)
    local contentLayer = display.newLayer(bgSize.width / 2, bgSize.height - 43, {size = contentLayerSize, ap = display.CENTER_TOP})
    bgLayer:addChild(contentLayer)

    contentLayer:addChild(display.newLabel(contentLayerSize.width - 140, contentLayerSize.height - 50, fontWithColor(14, {ap = display.RIGHT_CENTER, text = __('总灵力: ')})))

    local fireSpine = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
	fireSpine:update(0)
    fireSpine:setAnimation(0, 'huo', true)
    fireSpine:setPosition(cc.p(contentLayerSize.width - 75, contentLayerSize.height - 60))
	contentLayer:addChild(fireSpine)

	local fight_num = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '')
    display.commonUIParams(fight_num, {ap = cc.p(0.5, 0.5), po = cc.p(contentLayerSize.width - 75, contentLayerSize.height - 50)})
	fight_num:setHorizontalAlignment(display.TAR)
    fight_num:setScale(0.7)
    fight_num:setString(10)
	contentLayer:addChild(fight_num, 1)

    return {
        view              = view,
        shallowLayer      = shallowLayer,
        contentLayer      = contentLayer,
        fight_num         = fight_num
    }
end

function TagMatchDefensiveLineupView:CreateTeamView(teamId, teamCards)
    logInfo.add(5, 'teamId = ' .. teamId)
    local layer = display.newLayer(0, 0, {bg = RES_DIR.DEFEND_BG})
    local layerSize = layer:getContentSize()
    local teamView = require("Game.views.tagMatch.TagMatchDefensiveTeamView").new({size = layerSize, teamId = teamId, teamDatas = teamCards, teamMarkPosSign = 1})
    display.commonUIParams(teamView, {po = cc.p(layerSize.width / 2, layerSize.height / 2), ap = display.CENTER})
    layer:addChild(teamView)
    teamView:setName('teamView')
    return layer
end

convertTeamDataFromString2StrList = function (cardDatas)
    
end

function TagMatchDefensiveLineupView:getViewData()
	return self.viewData_
end

return TagMatchDefensiveLineupView