--[[
 * descpt : 创建工会 home 界面
]]

local TagMatchChangeTeamView = class('TagMatchChangeTeamView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.tagMatch.TagMatchChangeTeamView'
	node:enableNodeEvents()
	return node
end)

local CreateView = nil
local CreateOpponentLayer = nil
local CreatePlayerTeamHeadBg = nil
local CreateTeamNode = nil
local CreateDragAreaLayer = nil

-- 点击选择团队 
local LOCAL_SWITCH_TEAM           = 'LOCAL_SWITCH_TEAM'
-- 拖动改变团队
local LOCAL_DRAG_CHANGE_TEAM      = 'LOCAL_DRAG_CHANGE_TEAM'         

-- 偏移标识
local MIN_OFFSET_FLAG = 10

local RES_DIR = {
    BG                    = _res("ui/tagMatch/3v3_bg.png"),
    BACK                  = _res("ui/common/common_btn_back"),
    LOOK_OPPONENT_BG      = _res("ui/tagMatch/3v3_edit_bg_look_opponent.png"),
    ORDER_TEAM_BG         = _res("ui/tagMatch/3v3_order_bg_team.png"),
    NOCARD_BG             = _res('ui/common/kapai_frame_bg_nocard.png'),

    ATTACKTEAM_TITLE      = _res('ui/common/common_title_5.png'),
    ATTACKTEAM_BG_TEAM    = _res("ui/tagMatch/team_frame_touxiangkuang.png"),
    ATTACKTEAM_BG_TEAM_S  = _res("ui/tagMatch/team_img_touxiangkuang_xuanzhong.png"),
    ATTACKTEAM_MEMBER_BG  = _res("ui/tagMatch/3v3_attackteam_member_bg.png"),
    
    ATTACKTEAM_NUM        = _res("ui/tagMatch/3v3_attackteam_num.png"),
    ATTACKTEAM_LINE       = _res("ui/tagMatch/3v3_attackteam_line.png"),
    
--     team_frame_touxiangkuang.png
-- team_img_touxiangkuang_xuanzhong.png

}

function TagMatchChangeTeamView:ctor( ... )
    self:setName('Game.views.tagMatch.TagMatchChangeTeamView')
    self.args = unpack({...}) or {}
    self:initData()
    self:initialUI()
    self:registerSignal()
end

function TagMatchChangeTeamView:initData()
    self.battleTypeData   = self.args.battleTypeData or {}
    self.isShowOppentTeam = self.battleTypeData.isShowOppentTeam
    self.oppoentTeamDatas = self.battleTypeData.oppoentTeamDatas or {}
    self.teamDatas        = self.args.teamDatas
    self.teamId           = self.args.teamId
end

function TagMatchChangeTeamView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(self.isShowOppentTeam)
        self:addChild(self:getViewData().view)

        self:initView()

        self:initTouchAction()
	end, __G__TRACKBACK__)
end

function TagMatchChangeTeamView:initView()
    local viewData = self:getViewData()
    local playerTeamHeadBgs = viewData.playerTeamHeadBgs
    local dragAreaLayers = viewData.dragAreaLayers
    
    for i, playerTeamHeadBg in ipairs(playerTeamHeadBgs) do

        -- 初始化头像背景
        local playerTeamHeadBgViewData = playerTeamHeadBg.viewData
        local clickLayer = playerTeamHeadBgViewData.clickLayer
        display.commonUIParams(clickLayer, {cb = handler(self, self.onClickPlayerTeamHeadBg)})
        clickLayer:setTag(i)

        -- 更新选中框
        self:updatePlayerHeadSelectState(i)
        -- 更新团队头像节点
        self:updateTeamHeadNode(i, i == checkint(self.teamId))

    end

    self:updateLookOpponentBgLayer()
end

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function TagMatchChangeTeamView:initTouchAction()
    self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:setSwallowTouches(true)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
end

function TagMatchChangeTeamView:onTouchBegan_(touch, event)
    -- logInfo.add(5, 'onTouchBegan_')
    -- local target = event:getCurrentTarget()
    -- logInfo.add(5, target:getName())
    local touchId = touch:getId()
    if self.beganTouchId_  and self.beganTouchId_  ~= touchId then
        if self.curDragNode and self.curDragNodeStartPos_ then
            self.curDragNode:setPosition(self.curDragNodeStartPos_)
        end
        self.beganTouchId_ = nil
        self.curDragNodeStartPos_ = nil
        self.curDragTeamIndex   = 0
        self.curDragNode        = nil
        self.isBeganDragTeam_   = false
        return false
    else
        self.beganTouchId_ = touchId
    end

    self.beganTouchPos_     = touch:getLocation()
    self.curDragNodeStartPos_ = nil
    self.curDragTeamIndex   = 0
    self.curDragNode        = nil
    self.isBeganDragTeam_   = false

    local viewData       = self:getViewData()
    local dragAreaLayers = viewData.dragAreaLayers
    
    for i, dragAreaLayer in ipairs(dragAreaLayers) do
        if self:checkTouch(dragAreaLayer, self.beganTouchPos_) then
            if not self:checkIsCanDrag(i) then
                break
            else
                self.curDragTeamIndex = i
                self.curDragNode   = dragAreaLayer
                self.curDragNodeStartPos_ = cc.p(dragAreaLayer:getPositionX(), dragAreaLayer:getPositionY())
                
                dragAreaLayer:setLocalZOrder(10)
                return true
            end
        end
    end

    return false
end
function TagMatchChangeTeamView:onTouchMoved_(touch, event)
    -- logInfo.add(5, 'onTouchMoved_')
    local touchPos = touch:getLocation()
    if self.isBeganDragTeam_ == false then
        self.isBeganDragTeam_ = (math.abs(self.beganTouchPos_.x - touchPos.x) >= MIN_OFFSET_FLAG or 
        math.abs(self.beganTouchPos_.y - touchPos.y) >= MIN_OFFSET_FLAG)
    end

    if self.isBeganDragTeam_ and self.curDragNode then
        local viewData       = self:getViewData()
        -- local dragAreaLayers = viewData.dragAreaLayers
        -- local dragAreaLayer  = dragAreaLayers[self.curDragTeamIndex]
        display.commonUIParams(self.curDragNode, {po = cc.p(self.curDragNodeStartPos_.x - self.beganTouchPos_.x + touchPos.x, self.curDragNodeStartPos_.y - self.beganTouchPos_.y + touchPos.y)})
       
    end
end
function TagMatchChangeTeamView:onTouchEnded_(touch, event)
    -- logInfo.add(5, 'onTouchEnded_')
    
    local viewData = self:getViewData()
    local dragAreaLayers = viewData.dragAreaLayers
    self.curDragNode:setLocalZOrder(2)

    local endTouchPos = touch:getLocation()

    local isOffsetSuccess = false
    local newIndex = 0
    for i, dragAreaLayer in ipairs(dragAreaLayers) do
        if self.curDragTeamIndex ~= i and self:checkTouch(dragAreaLayer, endTouchPos) then
            isOffsetSuccess = true
            self.curDragNode:setPosition(cc.p(dragAreaLayer:getPositionX(), dragAreaLayer:getPositionY()))
            dragAreaLayer:setPosition(self.curDragNodeStartPos_)
            
            newIndex = i
            
            break
        end
    end

    if not isOffsetSuccess then
        self.curDragNode:setPosition(self.curDragNodeStartPos_)
    else
        -- 交换节点
        local newNode = dragAreaLayers[newIndex]
        dragAreaLayers[self.curDragTeamIndex] = dragAreaLayers[newIndex]
        dragAreaLayers[newIndex] = self.curDragNode

        AppFacade.GetInstance():DispatchObservers(LOCAL_DRAG_CHANGE_TEAM, {oldTeamId = tostring(self.curDragTeamIndex), newTeamId = tostring(newIndex), isAttack = self.battleTypeData.isAttack})
    end

    self.beganTouchId_ = nil
    self.curDragNodeStartPos_ = nil
    self.curDragTeamIndex   = 0
    self.curDragNode        = nil
    self.isBeganDragTeam_   = false
end

function TagMatchChangeTeamView:checkTouch(node, touchPos)
    local size = node:getContentSize()
    local rect  = cc.rect(0, 0, size.width,size.height)
    local tPos = cc.p(node:convertToNodeSpace(touchPos))
    return cc.rectContainsPoint(rect, tPos)
end

---------------------------------------------------
-- touch logic end --
---------------------------------------------------

--[[
   更新玩家头像选中状态
   @params teamId 团队id
]]
function TagMatchChangeTeamView:updatePlayerHeadSelectState(teamId)
    if checkint(teamId) <= 0 then
        return
    end
    local viewData = self:getViewData()
    local playerTeamHeadBgs = viewData.playerTeamHeadBgs
    local playerTeamHeadBg = playerTeamHeadBgs[checkint(teamId)]
    local playerTeamHeadBgViewData = playerTeamHeadBg.viewData
    local selectBg = playerTeamHeadBgViewData.selectBg

    local isSelect = checkint(teamId) == checkint(self.teamId)
    selectBg:setVisible(isSelect)
end

--[[
   更新团队头像
   @params index 下标
]]
function TagMatchChangeTeamView:updateTeamHeadNode(index)
    local viewData = self:getViewData()

    local dragAreaLayers = viewData.dragAreaLayers
    local dragAreaLayer  = dragAreaLayers[index]

    -- local realTeamId = dragAreaLayer:getTag()

    -- logInfo.add(5, 'index = ' .. index)
    -- logInfo.add(5, 'realTeamId = ' .. realTeamId)
    local teamData = self.teamDatas[tostring(index)] or {}
    local memberCount = 0
    local id = 0
    for i, v in ipairs(teamData) do
        if v and v.id then
            if id == 0 then
                id = checkint(v.id)
            end
            memberCount = memberCount + 1
        end
    end
    -- logInfo.add(5, 'memberCount  = ' .. memberCount)
    -- logInfo.add(5, 'updateTeamHeadNode id = ' .. id)
    -- 创建 或 更新 团队头像
    local dragAreaLayerViewData = dragAreaLayer.viewData
    if id > 0 then
        local cardHeadNodeData = {
            id = id,
            showBaseState = false, showActionState = false, showVigourState = false
        }
        local teamHeadNode = dragAreaLayerViewData.teamHeadNode
        if teamHeadNode then
            teamHeadNode:setVisible(true)
            local cardHeadNode = teamHeadNode.viewData.cardHeadNode
            cardHeadNode:RefreshUI(
                cardHeadNodeData
            )
        else
            local dragAreaLayerSize = dragAreaLayer:getContentSize()
            dragAreaLayerViewData.teamHeadNode = CreateTeamNode(cardHeadNodeData, false, cc.size(dragAreaLayerSize.width, dragAreaLayerSize.height))
            display.commonUIParams(dragAreaLayerViewData.teamHeadNode, {ap = display.CENTER, po = cc.p(dragAreaLayerSize.width / 2, dragAreaLayerSize.height / 2)})
            dragAreaLayer:addChild(dragAreaLayerViewData.teamHeadNode)
        end
    else
        local teamHeadNode = dragAreaLayerViewData.teamHeadNode
        if teamHeadNode then
            teamHeadNode:setVisible(false)
        end
    end

    -- 更新团队数量
    local memberLabel = dragAreaLayerViewData.memberLabel
    local labelColor = memberCount >= MAX_TEAM_MEMBER_AMOUNT and '#000000' or '#d23d3d'
    display.commonLabelParams(memberLabel, {text = string.format('%s/%s', memberCount, MAX_TEAM_MEMBER_AMOUNT), color = labelColor})
   
end

--[[
   更新团队头像
   @params index 下标
]]
function TagMatchChangeTeamView:updateTeamHeadByIds(teamIds)
    local viewData = self:getViewData()
    local dragAreaLayers = viewData.dragAreaLayers
    -- todo 处理 更新 团队队长头像
    for i, teamId in ipairs(teamIds) do
        -- logInfo.add(5, "---------------sssssssssssssss" .. teamId)
        -- logInfo.add(5, tableToString(self.teamDatas[tostring(teamId)] or {}))
        -- logInfo.add(5, dragAreaLayers[checkint(teamId)]:getPositionY())
        self:updateTeamHeadNode(checkint(teamId))
    end
    
end

function TagMatchChangeTeamView:updateLookOpponentBgLayer()
    if not self.isShowOppentTeam then return end

    local viewData = self:getViewData()
    local lookOpponentBgLayer = viewData.lookOpponentBgLayer
    local lookOpponentBgLayerViewData = lookOpponentBgLayer.viewData

    local oppoentTeamData = self.oppoentTeamDatas[tostring(self.teamId)]
    local cards       = oppoentTeamData.cards or {}
    self:updateOpponentTeam(viewData, cards)

    local battlePoint = checkint(oppoentTeamData.battlePoint)
    local manaLabel = lookOpponentBgLayerViewData.manaLabel
    manaLabel:setString(battlePoint)
end


function TagMatchChangeTeamView:updateOpponentTeam(viewData, teamDatas)
    local lookOpponentBgLayer         = viewData.lookOpponentBgLayer
    local lookOpponentBgLayerViewData = lookOpponentBgLayer.viewData
    local teamNodes                   = lookOpponentBgLayerViewData.teamNodes
    local teamEmptyNodes              = lookOpponentBgLayerViewData.teamEmptyNodes

    -- logInfo.add(5, 'teamDatasteamDatas222')
    -- logInfo.add(5, tableToString(teamDatas))

    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local cardData = teamDatas[i] or {}

        local cid = checkint(cardData.cardId)
        local teamEmptyNode = teamEmptyNodes[i]
        
        if cid ~= 0 then
            local data = {cardId = cid, level = checkint(cardData.level), breakLevel = checkint(cardData.breakLevel), skinId = checkint(cardData.defaultSkinId)}
            
            local teamNode = teamNodes[i]
            if teamNode then
                teamNode:setVisible(true)
                -- local cardHeadNode = teamNode:getChildByName('cardHeadNode')
                local cardHeadNode = teamNode.viewData.cardHeadNode
                if cardHeadNode then
                    cardHeadNode:RefreshUI({cardData = data})
                end
            else
                local cardHeadNodeData = {
                    cardData = data,
                    showBaseState = true, showActionState = false, showVigourState = false
                }
                teamNode = CreateTeamNode(cardHeadNodeData, i == 1, cc.size(teamEmptyNode:getContentSize().width * 0.45, teamEmptyNode:getContentSize().height * 0.45))
                teamNodes[i] = teamNode
                local x, y = teamEmptyNode:getPosition()
                display.commonUIParams(teamNode, {po = cc.p(x, y), ap = display.CENTER})
                lookOpponentBgLayer:addChild(teamNode)
            end
            teamEmptyNode:setVisible(false)
        else
            local teamNode = teamNodes[i]
            if teamNode then
                teamNode:setVisible(false)
            end
            teamEmptyNode:setVisible(true)
        end
    end

end

function TagMatchChangeTeamView:onClickPlayerTeamHeadBg(sender)
    
    local tag = tostring(sender:getTag())
    if self.teamId == tag then return end
    
    AppFacade.GetInstance():DispatchObservers(LOCAL_SWITCH_TEAM, {oldTeamId = self.teamId, isAttack = self.battleTypeData.isAttack, newTeamId = tag})

    self:setTeamId(tag)
    
end

function TagMatchChangeTeamView:checkIsCanDrag(teamId)
    local teamData = self.teamDatas[tostring(teamId)] or {}
    
    if next(teamData) == nil then
        return false
    else
        for i, v in ipairs(teamData) do
            if v.id then
                return true
            end
        end
    end
    return false
end

function TagMatchChangeTeamView:setTeamId(teamId)
    local preTeamId = self.teamId
    self.teamId = teamId

    self:updatePlayerHeadSelectState(preTeamId)
    self:updatePlayerHeadSelectState(teamId)

    self:updateLookOpponentBgLayer()
end

CreateView = function (isShowOppentTeam)
    local view = display.newLayer()
    local size = view:getContentSize()
    
    -------------------------------------
    -- top
    local topUILayer = display.newLayer()
    view:addChild(topUILayer)

    local lookOpponentBgLayer = nil
    if isShowOppentTeam then
        lookOpponentBgLayer = CreateOpponentLayer()
        topUILayer:addChild(lookOpponentBgLayer)
    end
    -------------------------------------
    -- right
    local rightUILayer = display.newLayer()
    view:addChild(rightUILayer)

    local orederTeamBgLayer = display.newLayer(display.SAFE_R - 10, size.height * 0.443, {ap = display.RIGHT_BOTTOM, bg = RES_DIR.ORDER_TEAM_BG})
    local orederTeamBgLayerSize = orederTeamBgLayer:getContentSize()
    rightUILayer:addChild(orederTeamBgLayer)

    local attackteamTitle = display.newButton(0, 0, {n = RES_DIR.ATTACKTEAM_TITLE, animation = false})
    display.commonUIParams(attackteamTitle, {po = cc.p(orederTeamBgLayerSize.width / 2 + 5, orederTeamBgLayerSize.height - 20)})
    display.commonLabelParams(attackteamTitle, fontWithColor(5, {text = __('出战顺序')}))
    orederTeamBgLayer:addChild(attackteamTitle)

    local playerTeamHeadBgLayerSize = cc.size(orederTeamBgLayerSize.width - 22, orederTeamBgLayerSize.height - 44)
    local playerTeamHeadBgLayer = display.newLayer(orederTeamBgLayerSize.width / 2, orederTeamBgLayerSize.height - 42, {ap = display.CENTER_TOP, size = playerTeamHeadBgLayerSize})
    orederTeamBgLayer:addChild(playerTeamHeadBgLayer)

    local playerTeamHeadBgs = {}
    local dragAreaLayers    = {}
    for i = 1, 3 do
        local offsetY = (i - 1) * 123
        local playerTeamHeadBg = CreatePlayerTeamHeadBg(i)
        display.commonUIParams(playerTeamHeadBg, {po = cc.p(0, playerTeamHeadBgLayerSize.height - offsetY), ap = display.LEFT_TOP})
        playerTeamHeadBgLayer:addChild(playerTeamHeadBg)
        table.insert(playerTeamHeadBgs, playerTeamHeadBg)

        local dragAreaLayer = CreateDragAreaLayer()
        display.commonUIParams(dragAreaLayer, {po = cc.p(108, playerTeamHeadBgLayerSize.height - 52 - offsetY), ap = display.CENTER})
        playerTeamHeadBgLayer:addChild(dragAreaLayer, 2)
        dragAreaLayer:setTag(i)
        table.insert(dragAreaLayers, dragAreaLayer)
    end

    return {
        view          = view,
        lookOpponentBgLayer = lookOpponentBgLayer,
        playerTeamHeadBgs = playerTeamHeadBgs,
        dragAreaLayers    = dragAreaLayers,
    }
end

CreateOpponentLayer = function ()
    local lookOpponentBgLayer = display.newLayer(display.cx - 50, display.height - 1, {bg = RES_DIR.LOOK_OPPONENT_BG, ap = display.CENTER_TOP})
    local lookOpponentBgLayerSize = lookOpponentBgLayer:getContentSize()
    
    lookOpponentBgLayer:addChild(display.newLabel(120, lookOpponentBgLayerSize.height / 2 + 10, fontWithColor(5, {ap = display.CENTER, w = 22 * 4 + 2, text = __('对手队伍')})))

    local teamEmptyNodes = {}
    local goodScale = 0.45
    
    for i = 1, 5, 1 do
        local defaultHead = display.newImageView(RES_DIR.NOCARD_BG, 0, 0)
        local goodNodeSize = defaultHead:getContentSize()
        local params = {index = i, goodNodeSize = cc.size(goodNodeSize.width * goodScale, goodNodeSize.height * goodScale), midPointX = lookOpponentBgLayerSize.width / 2 - 10, midPointY = lookOpponentBgLayerSize.height / 2 + 10, col = 5, maxCol = 5, scale = 1, goodGap = 5}
        local pos = CommonUtils.getGoodPos(params)
        display.commonUIParams(defaultHead, {po = pos})
        defaultHead:setScale(goodScale)
        lookOpponentBgLayer:addChild(defaultHead)

        teamEmptyNodes[i] = defaultHead
    end

    lookOpponentBgLayer:addChild(display.newLabel(lookOpponentBgLayerSize.width - 133, lookOpponentBgLayerSize.height / 2 + 22, fontWithColor(5, {ap = display.CENTER, color = "#5b3c25", text = __('灵力')})))

    local manaLabel = cc.Label:createWithBMFont('font/small/common_text_num_5.fnt', 1)
    display.commonUIParams(manaLabel, {po = cc.p(lookOpponentBgLayerSize.width - 133, lookOpponentBgLayerSize.height / 2 - 5), ap = display.CENTER})
    manaLabel:setHorizontalAlignment(display.TAR)
    -- manaLabel:setString('1000')
    lookOpponentBgLayer:addChild(manaLabel)

    lookOpponentBgLayer.viewData = {
        teamEmptyNodes = teamEmptyNodes,
        teamNodes      = {},
        manaLabel = manaLabel,

    }
    return lookOpponentBgLayer
end

CreatePlayerTeamHeadBg = function (index)
    local teamHeadLayerSize = cc.size(189, 138)
    local layer = display.newLayer(0, 0, {size = teamHeadLayerSize})

    local attackTeamNum = display.newImageView(RES_DIR.ATTACKTEAM_NUM, 0, teamHeadLayerSize.height - 8, {ap = display.LEFT_TOP})
    local attackTeamNumSize = attackTeamNum:getContentSize()
    layer:addChild(attackTeamNum)

    local infoLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	display.commonUIParams(infoLabel, {ap = display.LEFT_CENTER, po = cc.p(5, attackTeamNumSize.height / 2)})
	infoLabel:setString(string.format("%s.", index))
	attackTeamNum:addChild(infoLabel)
    
    -- 默认背景
    local teamBg = display.newImageView(RES_DIR.ATTACKTEAM_BG_TEAM, 0, 0, {ap = display.CENTER})
    local teamBgSize = teamBg:getContentSize()
    -- logInfo.add(5, tableToString(teamBgSize))
    local teamBgLayer = display.newLayer(attackTeamNumSize.width + 5, teamHeadLayerSize.height, {ap = display.LEFT_TOP, size = teamBgSize})
    display.commonUIParams(teamBg, {po = cc.p(teamBgSize.width / 2, teamBgSize.height / 2)})
    teamBgLayer:addChild(teamBg)
    layer:addChild(teamBgLayer, 1)

    -- 选中背景
    local selectBg = display.newImageView(RES_DIR.ATTACKTEAM_BG_TEAM_S, teamBgSize.width / 2, teamBgSize.height / 2, {ap = display.CENTER})
    teamBgLayer:addChild(selectBg)
    selectBg:setVisible(false)

    -- 分割线
    if index ~= 3 then
        local teamLine = display.newImageView(RES_DIR.ATTACKTEAM_LINE, teamBgLayer:getPositionX() + teamBgSize.width / 2, teamBgLayer:getPositionY() - teamBgSize.height - 3, {ap = display.CENTER_TOP})
        layer:addChild(teamLine)
    end

    local clickLayer = display.newLayer(teamBgSize.width / 2, teamBgSize.height / 2, {ap = display.CENTER, size = teamBgSize, color = cc.c4b(0,0,0,0), enable = true})
    teamBgLayer:addChild(clickLayer)

    -- local dragAreaLayer = display.newLayer(teamBgSize.width / 2, teamBgSize.height / 2, {ap = display.CENTER, size = teamBgSize, color = cc.c4b(0, 0, 0, 0)})
    -- teamBgLayer:addChild(dragAreaLayer)

    -- local memberBg = display.newImageView(RES_DIR.ATTACKTEAM_MEMBER_BG, teamBgSize.width / 2, 0, {ap = display.CENTER_BOTTOM})
    -- local memberBgSize = memberBg:getContentSize()
    -- dragAreaLayer:addChild(memberBg, 1)

    -- local memberLabel = display.newLabel(memberBgSize.width / 2, memberBgSize.height / 2 - 2, {ap = display.CENTER, fontSize = 20, text = '1/1', color = '#000000'})
    -- memberBg:addChild(memberLabel)

    layer.viewData = {
        clickLayer = clickLayer,
        teamBg     = teamBg,
        selectBg   = selectBg,
        -- dragAreaLayer = dragAreaLayer,
        -- memberLabel = memberLabel,
    }
    return layer
end

CreateDragAreaLayer = function ()
    local size = cc.size(103, 104)
    local dragAreaLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size, color = cc.c4b(0, 0, 0, 0)})

    local memberBg = display.newImageView(RES_DIR.ATTACKTEAM_MEMBER_BG, size.width / 2, 0, {ap = display.CENTER_BOTTOM})
    local memberBgSize = memberBg:getContentSize()
    dragAreaLayer:addChild(memberBg, 1)

    local memberLabel = display.newLabel(memberBgSize.width / 2, memberBgSize.height / 2 - 2, {ap = display.CENTER, fontSize = 20, text = '1/1', color = '#000000'})
    memberBg:addChild(memberLabel)

    dragAreaLayer.viewData = {
        memberLabel = memberLabel
    }

    return dragAreaLayer
end

CreateTeamNode = function (cardHeadNodeData, isCaptain, teamEmptyNodeSize)
    local cardHeadLayerSize = cc.size(81, 81)
    local cardHeadLayer = display.newLayer(0, 0, {size = cardHeadLayerSize})

    local cardHeadNode = require('common.CardHeadNode').new(cardHeadNodeData)
    cardHeadNode:setScale(teamEmptyNodeSize.width / cardHeadNode:getContentSize().width)
    cardHeadNode:setPosition(cc.p(cardHeadLayerSize.width / 2, cardHeadLayerSize.height / 2))
    cardHeadLayer:addChild(cardHeadNode)
    cardHeadNode:setName('cardHeadNode')
    
    -- if isCaptain then
    --     -- 队长mark
    --     local cardHeadNode = cardHeadNode:getContentSize()
    --     local captainMark = display.newImageView(_res('ui/home/teamformation/team_ico_captain.png'), cardHeadLayerSize.width / 2, cardHeadLayerSize.height / 2 - 5, {ap = display.CENTER_BOTTOM})
    --     cardHeadLayer:addChild(captainMark)
    -- end

    cardHeadLayer.viewData = {
        cardHeadNode = cardHeadNode
    }
    return cardHeadLayer
end

-----------------------------------------------
---  get/set
function TagMatchChangeTeamView:getViewData()
	return self.viewData_
end

---  get/set
-----------------------------------------------
function TagMatchChangeTeamView:registerSignal()

	------------ 更新玩家团队队长 ------------
	AppFacade.GetInstance():RegistObserver('UPDATE_TEAM_HEAD', mvc.Observer.new(function (_, signal)
        local data = signal:GetBody() or {}
        local teamIds = data.teamIds or {}
		self:updateTeamHeadByIds(teamIds)
	end, self))
	------------ 更新玩家团队队长 ------------
	
end

function TagMatchChangeTeamView:unRegistSignal()
    AppFacade.GetInstance():UnRegistObserver('UPDATE_TEAM_HEAD', self)
end

function TagMatchChangeTeamView:onCleanup()
	-- 注销信号
    self:unRegistSignal()
    
    -- self:getEventDispatcher():removeAllEventListeners()
end

return TagMatchChangeTeamView