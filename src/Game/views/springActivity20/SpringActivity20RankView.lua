--[[
 * author : liuzhipeng
 * descpt : 活动 20春活 排行榜View
--]]
local SpringActivity20RankView = class('SpringActivity20RankView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.springActivity20.SpringActivity20RankView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    COMMON_BG_POINT        = app.springActivity20Mgr:GetResPath('ui/springActivity20/rank/common_bg_point.png'),
    ROLE_IMG               = app.springActivity20Mgr:GetResPath('ui/springActivity20/rank/murder_point_bg_bird_boss_card.png'),
    LIST_CELL_BG           = app.springActivity20Mgr:GetResPath('ui/springActivity20/rank/murder_point_bird_list_bg_default.png'),
    LIST_CELL_TEXT_BG      = app.springActivity20Mgr:GetResPath('ui/springActivity20/rank/murder_point_bird_list_label.png'),
    LIST_CELL_TEXT_BG_GRAY = app.springActivity20Mgr:GetResPath('ui/springActivity20/rank/murder_point_list_bird_label_grey.png'),
    LIST_CELL_LINE         = app.springActivity20Mgr:GetResPath('ui/springActivity20/rank/murder_point_bird_list_line.png'),
    PLAYER_RANK_BG         = app.springActivity20Mgr:GetResPath('ui/springActivity20/rank/murder_point_list_bird_bg_sp.png'),
    PLAYER_RANK_BG_GRAY    = app.springActivity20Mgr:GetResPath('ui/springActivity20/rank/murder_point_list_bird_bg_sp_grey.png'),
    REWARDS_PREVIEW        = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_btn_search.png'),
    
}
local CreateRankCell = nil

function SpringActivity20RankView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function SpringActivity20RankView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.COMMON_BG_POINT, 0, 0)
    	local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- mask --
        
        -- 角色
        local roleImg = display.newImageView(RES_DICT.ROLE_IMG, size.width / 2 + 84, 15, {ap = display.RIGHT_BOTTOM})
        view:addChild(roleImg, 1)
        -- 奖励预览
        local rewardsPreviewBtn = display.newButton(95, 45, {n = RES_DICT.REWARDS_PREVIEW})
        view:addChild(rewardsPreviewBtn, 1)
        display.commonLabelParams(rewardsPreviewBtn, {text = app.springActivity20Mgr:GetPoText(__('查看奖励')), fontSize = 20, color = '#FFFFFF', offset = cc.p(10, -2)})
        -- 排行榜列表
        local rankTableViewSize = cc.size(560, 485)
        local rankTableViewCellSize = cc.size(rankTableViewSize.width, 110)
        local rankTableView = display.newTableView(size.width - 46, size.height - 20, {size = rankTableViewSize, csize = rankTableViewCellSize, dir = display.SDIR_V, ap = display.RIGHT_TOP})
        rankTableView:setCellCreateHandler(CreateRankCell)
        view:addChild(rankTableView, 5)

        ----------------------
        -- playerRankLayout --
        local playerRankLayoutSize = cc.size(622, 142)
        local playerRankLayout = CLayout:create(playerRankLayoutSize)
        playerRankLayout:setAnchorPoint(display.RIGHT_BOTTOM)
        playerRankLayout:setPosition(cc.p(size.width - 44, 15))
        view:addChild(playerRankLayout, 1)
        -- 背景
        local playerRankBg = display.newImageView(RES_DICT.PLAYER_RANK_BG, playerRankLayoutSize.width / 2, playerRankLayoutSize.height / 2)
        playerRankLayout:addChild(playerRankBg, 1)
        -- 排名
        local playerRankLabel = display.newLabel(125, 105, {text = '', color = '#FFFFFF', fontSize = 20, ap = display.RIGHT_CENTER})
        playerRankLayout:addChild(playerRankLabel, 5)
        -- 名称
        local playerNameLabel = display.newLabel(135, 105, {text = '', color = '#FFFFFF', fontSize = 20, ttf = true, font = TTF_GAME_FONT, outline = '#382323', outlineSize = 1, ap = display.LEFT_CENTER})
        playerRankLayout:addChild(playerNameLabel, 5)
        -- 分割线
        local line = display.newImageView(RES_DICT.LIST_CELL_LINE, 30, 90, {ap = display.LEFT_CENTER})
        playerRankLayout:addChild(line, 5)
        -- 文字背景
        local textBg = display.newImageView(RES_DICT.LIST_CELL_TEXT_BG, 30, 55, {ap = display.LEFT_CENTER})
        playerRankLayout:addChild(textBg, 2)
        -- 捕捉次数
        local captureTimesLabel = display.newLabel(32, 72, {text = '', color = '#58201A', fontSize = 20, ap = display.LEFT_CENTER})
        playerRankLayout:addChild(captureTimesLabel, 5)
        -- 总耗时
        local totalTimes = display.newLabel(32, 42, {text = '', color = '#58201A', fontSize = 20, ap = display.LEFT_CENTER})
        playerRankLayout:addChild(totalTimes, 5)
        -- 奖励layer
        local rewardsLayerSize = cc.size(320, playerRankLayoutSize.height)
        local reawrdsLayer = display.newLayer(playerRankLayoutSize.width / 2 + 620, playerRankLayoutSize.height / 2 + 15,{ap = display.CENTER , size = rewardsLayerSize, enable = true})
        view:addChild(reawrdsLayer, 5)
        -- playerRankLayout --
        ----------------------
        return {
            view                = view,
            rankTableView       = rankTableView,
            playerRankLabel     = playerRankLabel,
            playerNameLabel     = playerNameLabel,
            captureTimesLabel   = captureTimesLabel,
            totalTimes          = totalTimes,
            reawrdsLayer        = reawrdsLayer,
            rewardsPreviewBtn   = rewardsPreviewBtn,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
创建列表cell
--]]
CreateRankCell = function( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    -- 背景
    local bg = display.newImageView(RES_DICT.LIST_CELL_BG, size.width / 2, size.height / 2)
    view:addChild(bg, 1)
    -- 排名
    local rankLabel = display.newLabel(52, 86, {text = '', color = '#FFFFFF', fontSize = 20, ap = display.CENTER})
    view:addChild(rankLabel, 5)
    -- 名称
    local nameLabel = display.newLabel(80, 86, {text = '', color = '#FFFFFF', fontSize = 20, ttf = true, font = TTF_GAME_FONT, outline = '#382323', outlineSize = 1, ap = display.LEFT_CENTER})
    view:addChild(nameLabel, 5)
    -- 分割线
    local line = display.newImageView(RES_DICT.LIST_CELL_LINE, 30, 75, {ap = display.LEFT_CENTER})
    view:addChild(line, 5)
    -- 文字背景
    local textBg = display.newImageView(RES_DICT.LIST_CELL_TEXT_BG, 30, 40, {ap = display.LEFT_CENTER})
    view:addChild(textBg, 2)
    -- 捕捉次数
    local captureTimesLabel = display.newLabel(32, 52, {text = '', color = '#58201A', fontSize = 20, ap = display.LEFT_CENTER})
    view:addChild(captureTimesLabel, 5)
    -- 总耗时
    local totalTimes = display.newLabel(32, 26, {text = '', color = '#58201A', fontSize = 20, ap = display.LEFT_CENTER})
    view:addChild(totalTimes, 5)
    -- 奖励layer
    local rewardsLayerSize = cc.size(320, size.height)
    local reawrdsLayer = display.newLayer(size.width / 2 + 110, size.height / 2 ,{ap = display.CENTER , size = rewardsLayerSize, enable = true})
    view:addChild(reawrdsLayer, 5)
    return {
        view              = view,
        rankLabel         = rankLabel,
        nameLabel         = nameLabel,
        captureTimesLabel = captureTimesLabel,
        totalTimes        = totalTimes,
        reawrdsLayer      = reawrdsLayer,
    }
end
--[[
进入动画
--]]
function SpringActivity20RankView:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
--[[
关闭动画
--]]
function SpringActivity20RankView:CloseAction()
    local viewData = self:GetViewData()
    viewData.view:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0.2),
            cc.CallFunc:create(function()
                local scene = app.uiMgr:GetCurrentScene()
                scene:RemoveDialog(self)
            end)
        )
        
    )
end
--[[
刷新玩家排行
@params myRank map {
    duration int 最短时间
    rank int 排行
    times int 最少次数
}
--]]
function SpringActivity20RankView:RefreshMyRank( myRank )
    local viewData = self:GetViewData()
    viewData.playerNameLabel:setString(app.gameMgr:GetUserInfo().playerName)
    if myRank.rank then
        viewData.playerRankLabel:setString(checkint(myRank.rank))
    else
        viewData.playerRankLabel:setString(app.springActivity20Mgr:GetPoText(__('未入榜')))
    end
    viewData.captureTimesLabel:setString(string.fmt(app.springActivity20Mgr:GetPoText(__('阻止次数：_num_次')), {['_num_'] = checkint(myRank.times)}))
    viewData.totalTimes:setString(string.fmt(app.springActivity20Mgr:GetPoText(__('总耗时：_num_秒')), {['_num_'] = checkint(myRank.duration)}))
    viewData.reawrdsLayer:removeAllChildren()
    local rankRewards = app.springActivity20Mgr:GetRankRewards(myRank.rank)
    if rankRewards then
        for i, v in ipairs(rankRewards) do
            local goodsNode = require('common.GoodNode').new({
                id = checkint(v.goodsId),
                amount = checkint(v.num),
                showAmount = true,
                callBack = function (sender)
                    app.uiMgr:ShowInformationTipsBoard({
                        targetNode = sender, iconId = checkint(v.goodsId), type = 1
                    })
                end
            })
            goodsNode:setPosition(cc.p(50 + (i - 1) * 100, viewData.reawrdsLayer:getContentSize().height / 2))
            goodsNode:setScale(0.8)
            viewData.reawrdsLayer:addChild(goodsNode, 1)
        end
    end
end 
--[[
获取viewData
--]]
function SpringActivity20RankView:GetViewData()
    return self.viewData
end
return SpringActivity20RankView