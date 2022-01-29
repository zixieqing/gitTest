--[[
 * author : liuzhipeng
 * descpt : 好友 好友切磋 选择对手Mediator
--]]
local Mediator = mvc.Mediator

local FriendbattleChooseEnemyMediator = class("FriendbattleChooseEnemyMediator", Mediator)

local NAME = "FriendbattleChooseEnemyMediator"
local FriendBattleChooseEnemyCell = require('Game.views.friend.FriendBattleChooseEnemyCell')

function FriendbattleChooseEnemyMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    
    self.requestLock = false
    self.gridViewData = {}
end
-------------------------------------------------
------------------ inheritance ------------------
function FriendbattleChooseEnemyMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.friend.FriendBattleChooseEnemyView' ).new()
    viewComponent:setPosition(display.center)
    self:SetViewComponent(viewComponent)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)

    viewComponent:GetViewData().gridView:setDataSourceAdapterScriptHandler(handler(self,self.GridViewDataSource))
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.EaterLayerCallback))
    
    -- 初始化页面
    self:InitView()
end

function FriendbattleChooseEnemyMediator:InterestSignals()
	local signals = { 
        POST.FRIEND_BATTLE_LIST.sglName,
	}
	return signals
end

function FriendbattleChooseEnemyMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	print(name)
    if name == POST.FRIEND_BATTLE_LIST.sglName then
        self:UpdateGridViewData(body)
        self:RefreshGridView()
	end
end

function FriendbattleChooseEnemyMediator:OnRegist(  )
    regPost(POST.FRIEND_BATTLE_LIST)
        
    self:EnterLayer()
end

function FriendbattleChooseEnemyMediator:OnUnRegist(  )
    print( "OnUnRegist" )
    unregPost(POST.FRIEND_BATTLE_LIST)
    self:Close()
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
列表数据处理
--]]
function FriendbattleChooseEnemyMediator:GridViewDataSource( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local viewComponent = self:GetViewComponent()
    local cSize = viewComponent:GetGridViewCellSize()
    if not pCell then
        pCell = FriendBattleChooseEnemyCell.new(cSize)
        pCell.bgBtn:setOnClickScriptHandler(handler(self, self.CellBgButtonCallback))
    end
    xTry(function()
        local gridViewData = self:GetGridViewData()
        local listData = gridViewData.friendList[index]
        pCell.avatarIcon:RefreshSelf({avatar = listData.avatar, avatarFrame = listData.avatarFrame})
        pCell.levelLabel:setString(string.fmt(__('等级:_num_'), {['_num_'] = listData.level}))
        pCell.nameLabel:setString(listData.name)
        pCell.cardLayout:removeAllChildren()
        local battlePoint = 0
        for i, v in ipairs(listData.team or {}) do
            if v.cardId then
                local cardHeadNode = require('common.CardHeadNode').new({
			    	cardData = {
			    		cardId = v.cardId,
			    		level = v.level,
			    		breakLevel = v.breakLevel,
			    		skinId = v.skinId
			    	},
			    	showBaseState = true,
			    	showActionState = false,
			    	showVigourState = false
                })
                cardHeadNode:setScale(0.44)
                cardHeadNode:setEnabled(false)
                cardHeadNode:setPosition(cc.p(45 + (i - 1) * 86, pCell.cardLayout:getContentSize().height / 2))
                pCell.cardLayout:addChild(cardHeadNode, 1)
                v.playerPetId = nil 
                battlePoint = battlePoint + app.cardMgr.GetCardStaticBattlePointByCardData(v)
            end
        end
        if pCell.emptyTipsLabel and not tolua.isnull(pCell.emptyTipsLabel) then
            pCell.emptyTipsLabel:setVisible(next(listData.team or {}) == nil)
        end
        pCell.battlePointLabel:setString(battlePoint)
        pCell.bgBtn:setTag(index)
        if index == #gridViewData.friendList then
            self:RequestNextPageData()
        end
    end,__G__TRACKBACK__)
    return pCell
end
--[[
列表cell背景点击回调
--]]
function FriendbattleChooseEnemyMediator:CellBgButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local gridViewData = self:GetGridViewData()
    if next(checktable(checktable(checktable(gridViewData.friendList)[tag]).team)) ~= nil then
        app:DispatchObservers(FRIEND_BATTLE_CHOOSE_ENEMY, gridViewData.friendList[tag]) 
        app:UnRegsitMediator('FriendbattleChooseEnemyMediator')
    else
        app.uiMgr:ShowInformationTips(__('请选择其他御侍切磋'))
    end
end
--[[
吞噬层点击回调
--]]
function FriendbattleChooseEnemyMediator:EaterLayerCallback( sender )
    PlayAudioByClickNormal()
    app:UnRegsitMediator('FriendbattleChooseEnemyMediator')
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化页面
--]]
function FriendbattleChooseEnemyMediator:InitView()
    self:InitGridViewData()
end
--[[
初始化列表数据
--]]
function FriendbattleChooseEnemyMediator:InitGridViewData()
    local gridViewData = {
        friendList     = {},  -- 列表数据
        page           = 0,   -- 当前页数
        totalPageCount = 1,   -- 总页数
    }
    self:SetGridViewData(gridViewData)
end
--[[
进入页面
--]]
function FriendbattleChooseEnemyMediator:EnterLayer()
    self:RequestNextPageData()
end
--[[
刷新列表
--]]
function FriendbattleChooseEnemyMediator:RefreshGridView()
    local gridViewData = self:GetGridViewData()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshGridView(gridViewData.friendList, gridViewData.page)
end
--[[
请求列表下一页数据
--]]
function FriendbattleChooseEnemyMediator:RequestNextPageData()
    if self:GetRequestLock() then return end
    local gridViewData = self:GetGridViewData()
    -- 判断是否有下一页数据
    if gridViewData.page < gridViewData.totalPageCount then
        self:SetRequestLock(true)
        self:SendSignal(POST.FRIEND_BATTLE_LIST.cmdName, {page = gridViewData.page + 1})
    end
end
--[[
@params params map {
    friendList  list 当前页的好友数据
    pageNum     int  总页数
    requestData map  请求数据
}
--]]
function FriendbattleChooseEnemyMediator:UpdateGridViewData( params )
    local gridViewData = self:GetGridViewData()
    if (gridViewData.page + 1) ~= params.requestData.page then return end
    table.insertto(gridViewData.friendList, params.friendList)
    gridViewData.page = checkint(params.requestData.page)
    gridViewData.totalPageCount = checkint(params.pageNum)
    self:SetRequestLock(false)
end
--[[
关闭页面
--]]
function FriendbattleChooseEnemyMediator:Close()
    self:GetViewComponent():Close()
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置列表数据
@params gridViewData map {
    friendList     list 列表数据
    page           int  当前页数
    totalPageCount int  总页数
}
--]]
function FriendbattleChooseEnemyMediator:SetGridViewData( gridViewData )
    self.gridViewData = checktable(gridViewData)
end
--[[
获取列表数据
--]]
function FriendbattleChooseEnemyMediator:GetGridViewData()
    return self.gridViewData or {}
end
--[[
设置请求锁定
isLocked 是否锁定
--]]
function FriendbattleChooseEnemyMediator:SetRequestLock( isLocked )
    self.requestLock = isLocked
end
--[[
获取请求锁定
--]]
function FriendbattleChooseEnemyMediator:GetRequestLock()
    return self.requestLock
end
------------------- get / set -------------------
-------------------------------------------------
return FriendbattleChooseEnemyMediator
