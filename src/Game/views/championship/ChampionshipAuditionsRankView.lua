--[[
 * author : kaishiqi
 * descpt : 武道会 - 海选赛排行榜视图
]]
local ChampionshipAuditionsRankView = class('ChampionshipAuditionsRankView', function()
    return ui.layer({name = 'Game.views.championship.ChampionshipAuditionsRankView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME    = _res('ui/common/common_bg_4.png'),
    FRAME_HEAD    = _res('ui/championship/rank/budo_sea_bg_lisht_head.png'),
    TITLE_BAR     = _res('ui/championship/rank/budo_sea_bg_lisht_head_small.png'),
    MY_INFO_BAR_S = _res('ui/championship/rank/common_bg_list_lock.png'),
    MY_INFO_BAR_N = _res('ui/championship/rank/common_bg_list_unlock.png'),
    --            = rank cell
    CELL_FRAME    = _res('ui/championship/rank/common_bg_list.png'),
    CELL_SCORE    = _res('ui/championship/rank/budo_sea_bg_lisht_number.png'),
    RANK_ICON_1   = _res('ui/championship/rank/budo_sea_bg_lisht_1.png'),
    RANK_ICON_2   = _res('ui/championship/rank/budo_sea_ico_lisht_2.png'),
    RANK_ICON_3   = _res('ui/championship/rank/budo_sea_ico_lisht_3.png'),
}

local ACTION_ENUM = {
    RELOAD_RANK_LIST = 1,
}

local RANK_PROXY_NAME   = FOOD.CHAMPIONSHIP.RANK.PROXY_NAME
local RANK_PROXY_STRUCT = FOOD.CHAMPIONSHIP.RANK.PROXY_STRUCT


function ChampionshipAuditionsRankView:ctor(args)
    -- create view
    self.viewData_ = ChampionshipAuditionsRankView.CreateView()
    self:addChild(self.viewData_.view)

    -- init view
    self:getViewData().rankTableView:setCellUpdateHandler(handler(self, self.onUpdateRankTableCellHandler_))

    -- bind model
    self.rankProxy_   = app:RetrieveProxy(RANK_PROXY_NAME)
    self.viewBindMap_ = {
        [RANK_PROXY_STRUCT.RANK_TAKE.MY_RANK]             = self.onUpdateMyRank_,
        [RANK_PROXY_STRUCT.RANK_TAKE.MY_SCORE]            = self.onUpdateMyScore_,
        [RANK_PROXY_STRUCT.RANK_TAKE.RANK_LIST]           = self.onUpdateRankTableView_,   -- clean all / update all
        [RANK_PROXY_STRUCT.RANK_TAKE.RANK_LIST.RANK_DATA] = self.onUpdateRankTableView_,   -- add key / del key
    }

    -- update view
    local handlerList = VoProxy.EventBind(RANK_PROXY_NAME, self.viewBindMap_, self)
    table.each(handlerList, function(_, v) v(self) end)
    self:updateMyName_()
end


function ChampionshipAuditionsRankView:onCleanup()
    VoProxy.EventUnbind(RANK_PROXY_NAME, self.viewBindMap_, self)
end


function ChampionshipAuditionsRankView:getViewData()
    return self.viewData_
end


function ChampionshipAuditionsRankView:updateMyName_()
    local myName = app.gameMgr:GetUserInfo().playerName
    self:getViewData().myNameLabel:updateLabel({text = tostring(myName)})
end


function ChampionshipAuditionsRankView:onUpdateMyRank_(signal)
    local myRank = self.rankProxy_:get(RANK_PROXY_STRUCT.RANK_TAKE.MY_RANK)

    local isValidRank = myRank > 0
    self:getViewData().myScoreBar:setChecked(isValidRank)
    if isValidRank then
        self:getViewData().myScoreLabel:setColor(ccc3FromInt('#954F1c'))
        self:getViewData().myRankLabel:updateLabel({fnt = FONT.D14, fontSize = 22, text = tostring(myRank)})
    else
        self:getViewData().myScoreLabel:setColor(ccc3FromInt('#65635E'))
        self:getViewData().myRankLabel:updateLabel({fnt = FONT.D13, fontSize = 22, text = __('未入榜'), ttf = false})
    end
end


function ChampionshipAuditionsRankView:onUpdateMyScore_(signal)
    local myScore = self.rankProxy_:get(RANK_PROXY_STRUCT.RANK_TAKE.MY_SCORE)
    self:getViewData().myScoreLabel:updateLabel({text = string.fmt(__('得分：_num_'), {_num_ = myScore})})
end


function ChampionshipAuditionsRankView:onUpdateRankTableView_(signal)
    -- reload rankTableView （当同一时间填充多条数据时，会导致的连续触发刷新。所以action动作能保证在下一帧时直接刷新最终结果）
    if not self:getActionByTag(ACTION_ENUM.RELOAD_RANK_LIST) then
        self:runAction(cc.CallFunc:create(function()
            local rankLength = self.rankProxy_:size(RANK_PROXY_STRUCT.RANK_TAKE.RANK_LIST)
            self:getViewData().rankTableView:resetCellCount(rankLength)
        end)):setTag(ACTION_ENUM.RELOAD_RANK_LIST)
    end
end


-- update productCell （changedVoDefine = nil 表示刷新cell全部内容，否则表示刷新局部的内容）
function ChampionshipAuditionsRankView:onUpdateRankTableCellHandler_(cellIndex, cellViewData, changedVoDefine)
    if cellViewData == nil then return end

    -- get cell data
    local CELL_STRUCT = RANK_PROXY_STRUCT.RANK_TAKE.RANK_LIST.RANK_DATA
    local cellVoProxy = self.rankProxy_:get(CELL_STRUCT, cellIndex)
    
    -- update rank
    local playerRank = cellVoProxy:get(CELL_STRUCT.PLAYER_RANK)
    cellViewData.rankLabel:updateLabel({text = tostring(playerRank)})

    local iconPath = RES_DICT['RANK_ICON_' .. playerRank]
    cellViewData.iconLayer:setVisible(iconPath ~= nil)
    cellViewData.iconLayer:addAndClear(ui.image({img = iconPath}))

    -- update head
    local playerId      = cellVoProxy:get(CELL_STRUCT.PLAYER_ID)
    local playerLevel   = cellVoProxy:get(CELL_STRUCT.PLAYER_LEVEL)
    local playerAvatar  = cellVoProxy:get(CELL_STRUCT.PLAYER_AVATAR)
    local playerAvatarF = cellVoProxy:get(CELL_STRUCT.PLAYER_AVATARF)
    cellViewData.headNode:RefreshUI({
        playerId        = playerId,
        playerLevel     = playerLevel,
        avatar          = playerAvatar,
        avatarFrame     = playerAvatarF,
        defaultCallback = true,
    })
    
    -- update name
    local playerName = cellVoProxy:get(CELL_STRUCT.PLAYER_NAME)
    cellViewData.nameLable:updateLabel({text = tostring(playerName)})

    -- update score
    local playerScore = cellVoProxy:get(CELL_STRUCT.PLAYER_SCORE)
    cellViewData.scrollLabel:updateLabel({text = tostring(playerScore)})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipAuditionsRankView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameSize = cc.size(585, 650)
    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, size = viewFrameSize, scale9 = true, enable = true})
    centerLayer:add(viewFrameNode)

    viewFrameNode:addList(ui.image({img = RES_DICT.FRAME_HEAD})):alignTo(nil, ui.ct, {offsetY = -4})
    

    -- title group
    local titleGroup = viewFrameNode:addList({
        ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D14, text = string.fmt(__('前_num_名可进入正赛'), {_num_ = 32})}),
        ui.label({fnt = FONT.D16, text = __('排行榜每小时更新一次')}),
    })
    ui.flowLayout(cc.rep(cc.sizep(viewFrameSize, ui.ct), 0, -4), titleGroup, {type = ui.flowV, ap = ui.cb})
    

    -- rank tableView
    local rankTableView = ui.tableView({size = cc.resize(viewFrameSize, -10, -150), dir = display.SDIR_V, csizeH = 110})
    viewFrameNode:addList(rankTableView):alignTo(nil, ui.cb, {offsetY = 55})
    rankTableView:setCellCreateHandler(ChampionshipAuditionsRankView.CreateRankCell)


    -- my score
    local myScoreBar = ui.tButton({n = RES_DICT.MY_INFO_BAR_N, s = RES_DICT.MY_INFO_BAR_S, enable = false})
    viewFrameNode:addList(myScoreBar):alignTo(nil, ui.cb, {offsetY = 5})

    local myRankGroup = myScoreBar:addList({
        ui.label({fnt = FONT.D14, fontSize = 22}),
        ui.label({fnt = FONT.D13, fontSize = 22, ml = 50, ap = ui.lc}),
    })
    ui.flowLayout(cc.rep(cc.sizep(myScoreBar, ui.lc), 60-4, 0), myRankGroup)

    local myScoreGroup = myScoreBar:addList({
        ui.image({img = RES_DICT.CELL_SCORE, alpha = 0}),
        ui.label({fnt = FONT.D1, color = '#954F1c', fontSize = 20, ap = ui.rc, text = '----'}),
    })
    ui.flowLayout(cc.rep(cc.sizep(myScoreBar, ui.rc), -100+4, 0), myScoreGroup, {type = ui.flowC, ap = ui.cc})
    myScoreGroup[2]:alignTo(myScoreGroup[1], ui.rc, {inside = true, offsetX = -10})
    

    return {
        view          = view,
        blackLayer    = backGroundGroup[1],
        blockLayer    = backGroundGroup[2],
        rankTableView = rankTableView,
        myScoreBar    = myScoreBar,
        myRankLabel   = myRankGroup[1],
        myNameLabel   = myRankGroup[2],
        myScoreLabel  = myScoreGroup[2],
    }
end


function ChampionshipAuditionsRankView.CreateRankCell(cellParent)
    local view = cellParent
    local size = cellParent:getContentSize()
    local cpos = cc.sizep(size, ui.cc)
    view:add(ui.image({p = cpos, img = RES_DICT.CELL_FRAME}))


    local infoGroup = view:addList({
        ui.label({fnt = FONT.D14, fontSize = 24, zorder = 1}),
        ui.playerHeadNode({showLevel = true, scale = 0.5, ml = 50}),
        ui.label({fnt = FONT.D13, fontSize = 22, w = 180, ml = 15, ap = ui.lc}),
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.lc), 60, 0), infoGroup, {type = ui.flowH, ap = ui.lc})


    local iconLayer = ui.layer({size = cc.size(0,0)})
    view:addList(iconLayer):alignTo(infoGroup[1], ui.cc)
    

    local scoreGroup = view:addList({
        ui.image({img = RES_DICT.CELL_SCORE}),
        ui.label({fnt = FONT.D1, color = '#954F1c', fontSize = 22, mt = 15, text = '----'}),
        ui.label({fnt = FONT.D1, color = '#954F1c', fontSize = 22, mb = 15, text = __('得分')}),
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.rc), -100, 0), scoreGroup, {type = ui.flowC, ap = ui.cc})

    return {
        view        = view,
        iconLayer   = iconLayer,
        rankLabel   = infoGroup[1],
        headNode    = infoGroup[2],
        nameLable   = infoGroup[3],
        scrollLabel = scoreGroup[2],
    }
end


return ChampionshipAuditionsRankView
