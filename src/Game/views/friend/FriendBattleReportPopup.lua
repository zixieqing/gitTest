--[[
 * author : liuzhipeng
 * descpt : 好友 好友切磋 战报Popup
--]]
local FriendBattleReportPopup = class('FriendBattleReportPopup', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.friend.FriendBattleReportPopup'
	node:enableNodeEvents()
	return node
end)
local FriendBattleReportCell = require('Game.views.friend.FriendBattleReportCell')
local RES_DICT = {
    BG           = _res('ui/common/common_bg_3.png'),
    TITLE_BG     = _res('ui/common/common_bg_title_2.png'), 
}
function FriendBattleReportPopup:ctor( ... )
    local args = unpack({...})
    table.sort(args.reportList, function (a, b) 
        return checkint(a.createTime) > checkint(b.createTime) 
    end)
    self.reportList = checktable(args.reportList)
    self:InitUI()
end

function FriendBattleReportPopup:InitUI()
    local function CreateView( )
        local view = CLayout:create()
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        view:setContentSize(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask
        local mask = display.newLayer(size.width / 2, size.height / 2, {color = cc.c4b(0, 0, 0, 0), enable = true, size = size})
        view:addChild(mask, -1)
        -- 标题
        local titleBg = display.newButton(size.width / 2, size.height - 20, {n = RES_DICT.TITLE_BG})
        display.commonLabelParams(titleBg, fontWithColor(4, {text = __('战报'), color = '#ffffff'}))
        view:addChild(titleBg, 5)
        -- 列表
        local gridViewSize = cc.size(size.width - 40, size.height - 58)
        local gridViewCellSize = cc.size(gridViewSize.width, 135)
        local gridView = CGridView:create(gridViewSize)
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setColumns(1)
		gridView:setAnchorPoint(cc.p(0.5, 0))
        gridView:setPosition(cc.p(size.width / 2, 10))
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
    eaterLayer:setOnClickScriptHandler(function ( sender )
        PlayAudioByClickClose()
        self:Close()
    end)
    self:addChild(eaterLayer, -1)
    xTry(function ( )
        self.viewData = CreateView( )
        self.viewData.view:setPosition(display.center)
        self:addChild(self.viewData.view)
        self.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self,self.GridViewDataSource))
        self.viewData.gridView:setCountOfCell(#self.reportList)
        self.viewData.gridView:reloadData()
        self:EnterAnimation()
    end, __G__TRACKBACK__)
end

--[[
列表数据处理
--]]
function FriendBattleReportPopup:GridViewDataSource( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local viewData = self:GetViewData()
    local cSize = self:GetViewData().gridViewCellSize
    if not pCell then
        pCell = FriendBattleReportCell.new(cSize)
        -- pCell.replayBtn:setOnClickScriptHandler(handler(self, self.ReplayButtonCallback))
        pCell.attackerAvatarIcon:setOnClickScriptHandler(handler(self, self.AttackerAvatarCallback))
        pCell.defenderAvatarIcon:setOnClickScriptHandler(handler(self, self.DefenderAvatarCallback))
    end
    xTry(function()
        local reportData = self.reportList[index]
        -- 进攻方
        pCell.attackerAvatarIcon:RefreshSelf({avatar = reportData.attackerAvatar, avatarFrame = reportData.attackerAvatarFrame})
        pCell.attackerNameLabel:setString(reportData.attackerName)
        -- 防守方
        pCell.defenderAvatarIcon:RefreshSelf({avatar = reportData.defenderAvatar, avatarFrame = reportData.defenderAvatarFrame})
        pCell.defenderNameLabel:setString(reportData.defenderName)
        -- 结果
        if checkint(reportData.isPassed) == (checkint(reportData.attackerId) == app.gameMgr:GetPlayerId() and 1 or 0) then
            -- 胜利
            display.commonLabelParams(pCell.resultLabel, {text = __('胜利'), fontSize = 20, color = '#5b91f3'})
        else
            -- 失败
            display.commonLabelParams(pCell.resultLabel, {text = __('失败'), fontSize = 20, color = '#d65540'})
        end
        pCell.replayTimeLabel:setString(self:GetBattleTimeText(reportData.createTime))
        -- pCell.replayBtn:setTag(index)
        pCell.attackerAvatarIcon:setTag(index)
        pCell.defenderAvatarIcon:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end
--[[
回放按钮点击回调
--]]
function FriendBattleReportPopup:ReplayButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local reportData = self.reportList[tag]
    if not reportData then return end
    -- 判断敌人我方阵容
    local friendTeamJson = nil
    local enemyTeamJson = nil
    if checkint(reportData.attackerId) == app.gameMgr:GetPlayerId() then
        friendTeamJson = json.encode({reportData.attackerTeam})
        enemyTeamJson = json.encode({reportData.defenderTeam})
    else
        friendTeamJson = json.encode({reportData.defenderTeam})
        enemyTeamJson = json.encode({reportData.attackerTeam})
    end
    local fromToStruct = BattleMediatorsConnectStruct.New(
		"FriendBattleMediator",
		"HomeMediator"
	)
    local battleConstructor = require('battleEntry.BattleConstructor').new()
    battleConstructor:OpenReplay(
        nil,
        reportData.constructorJson,
        friendTeamJson,
        enemyTeamJson,
        reportData.loadedResourcesJson,
        reportData.playerOperateJson,
        fromToStruct
    )
    app.uiMgr:GetCurrentScene():RemoveDialog(self)
end
--[[
进攻方头像点击回调
--]]
function FriendBattleReportPopup:AttackerAvatarCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local reportData = self.reportList[tag]
    if not reportData then return end
    app.uiMgr:ShowInformationTipsBoard({targetNode = sender, cardList = reportData.attackerTeam, type = 19})

end
--[[
防守方头像点击回调
--]]
function FriendBattleReportPopup:DefenderAvatarCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local reportData = self.reportList[tag]
    if not reportData then return end
    app.uiMgr:ShowInformationTipsBoard({targetNode = sender, cardList = reportData.defenderTeam, type = 19})
    
end
--[[
进入动画
--]]
function FriendBattleReportPopup:EnterAnimation()
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
function FriendBattleReportPopup:Close()
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
--[[
获取战斗时间
@params createTime int 战斗创建时间
--]]
function FriendBattleReportPopup:GetBattleTimeText( createTime )
	local seconds = getServerTime() - checkint(createTime)
	if seconds < 60 then
		str = string.fmt(__('_num_秒前'), {['_num_'] = seconds})
	elseif seconds < 3600 then
		str = string.fmt(__('_num_分钟前'), {['_num_'] = math.ceil(seconds/60)})
	elseif seconds < 86400 then
		str = string.fmt(__('_num_小时前'), {['_num_'] = math.ceil(seconds/3600)})
	else
		str = string.fmt(__('_num_天前'), {['_num_'] = math.ceil(seconds/86400)})
	end
	return str
end
--[[
获取viewData
--]]
function FriendBattleReportPopup:GetViewData()
    return self.viewData
end  
return FriendBattleReportPopup