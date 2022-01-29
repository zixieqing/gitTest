--[[
 * author : liuzhipeng
 * descpt : 好友 好友切磋 选择对手View
--]]
local FriendBattleChooseEnemyView = class('FriendBattleChooseEnemyView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.friend.FriendBattleChooseEnemyView'
	node:enableNodeEvents()
	return node
end)

local RES_DICT = {
    BG           = _res('ui/common/common_bg_4.png'),
    TITLE_BG     = _res('ui/common/common_title_5.png'), 
}
function FriendBattleChooseEnemyView:ctor( ... )
    self.cellAmount = 0
    self:InitUI()
end

function FriendBattleChooseEnemyView:InitUI()
    local function CreateView( )
        local size = cc.size(610, 700)
        local view = CLayout:create(size)
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2, {scale9 = true, size = size})
        view:addChild(bg, 1)
        -- mask
        local mask = display.newLayer(size.width / 2, size.height / 2, {color = cc.c4b(0, 0, 0, 0), enable = true, size = size})
        view:addChild(mask, -1)
        -- 标题
        local titleBg = display.newButton(size.width / 2, size.height - 30, {n = RES_DICT.TITLE_BG})
        display.commonLabelParams(titleBg, fontWithColor(4, {text = __('好友队伍')}))
        view:addChild(titleBg, 5)
        -- 列表
        local gridViewSize = cc.size(size.width, size.height - 60)
        local gridViewCellSize = cc.size(gridViewSize.width, 175)
        local gridView = CGridView:create(gridViewSize)
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setColumns(1)
		gridView:setAnchorPoint(cc.p(0.5, 0))
		gridView:setPosition(cc.p(size.width / 2, 5))
        view:addChild(gridView, 5)
        
        return {  
            view                  = view,
            gridViewCellSize      = gridViewCellSize,
            gridView              = gridView,
    	}
    end
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self.viewData.view:setPosition(display.center)
        self:addChild(self.viewData.view)
        self:EnterAnimation()
    end, __G__TRACKBACK__)
end
--[[
刷新列表
@params friendList list 列表数据
@params page       int  页数
--]]
function FriendBattleChooseEnemyView:RefreshGridView( friendList, page )
    local viewData = self:GetViewData()
    local offset = viewData.gridView:getContentOffset()
    viewData.gridView:setCountOfCell(#friendList)
    viewData.gridView:reloadData()
    if page ~= 1 then
        offset.y = math.min(offset.y + (#friendList - self.cellAmount) * viewData.gridViewCellSize.height, 0)
        viewData.gridView:setContentOffset(offset)
    end
    self.cellAmount = #friendList
end
--[[
获取列表cell尺寸
--]]
function FriendBattleChooseEnemyView:GetGridViewCellSize()
    local viewData = self:GetViewData()
    return viewData.gridViewCellSize
end
--[[
获取viewData
--]]
function FriendBattleChooseEnemyView:GetViewData()
    return self.viewData
end    
--[[
进入动画
--]]
function FriendBattleChooseEnemyView:EnterAnimation()
    local viewData = self:GetViewData()
	viewData.view:setScale(0.8)
	viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackOut:create(
				cc.ScaleTo:create(0.2, 1)
			)
		)
	)
end
--[[
关闭界面
--]]
function FriendBattleChooseEnemyView:Close()
    local viewData = self:GetViewData()
	viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackIn:create(
				cc.ScaleTo:create(0.2, 0.8)
            ),
            cc.CallFunc:create(function()
                app.uiMgr:GetCurrentScene():RemoveDialog(self)
            end)
		)
	)
end
return FriendBattleChooseEnemyView