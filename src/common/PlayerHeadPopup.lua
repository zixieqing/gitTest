--[[
玩家头像点击弹窗
--]]

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
---@type UnionManager
local unionMgr = AppFacade.GetInstance():GetManager('UnionManager')

local PlayerHeadPopup = class('PlayerHeadPopup', function ()
    local clb = CLayout:create(display.size)
    clb.name = 'common.PlayerHeadPopup'
    clb:enableNodeEvents()
    return clb
end)

local ButtonType = {
    ZONE                   = '1',  -- 去空间
    RESTAURANT             = '2',  -- 进餐厅
    DELETE_FRIEND          = '3',  -- 删除好友
    ADD_BLACKLIST          = '4',  -- 加入黑名单
    SEND_MESSAGE           = '5',  -- 发送消息
    ADD_FRIEND             = '6',  -- 添加好友
    REMOVE_BLACKLIST       = '7',  -- 从黑名单中移除
    REPORT                 = '8',  -- 举报
    DELETE_UNION_MEMBER    = '9',  -- 删除工会成员
    PEOMOTION_UNION_MEMBER = '10', -- 升值
    DOWN_UNION_MEMBER      = '11', -- 降职
    TURN_OVER_PRESIDENT    = '12', -- 移交会长
    HOME_LAND              = '13', -- 移交会长
    REMARK                 = '14', -- 设置备注
    BATTLE                 = '15', -- 好友切磋
    CAT_HOUSE              = '16', -- 进入小屋
    REMOVE_CAT_HOUSE       = '17', -- 踢出好友小屋
    SET_TOP                = '18', -- 置顶
    SET_TOP_CANCEL         = '19', -- 取消置顶
}

local ButtonDatas = {
    [ButtonType.ZONE]                   = { name = __('去空间'), tag = 1 },
    [ButtonType.RESTAURANT]             = { name = __('进餐厅'), tag = 2 },
    [ButtonType.DELETE_FRIEND]          = { name = __('删除好友'), tag = 3 },
    [ButtonType.ADD_BLACKLIST]          = { name = __('加入黑名单'), tag = 4 },
    [ButtonType.SEND_MESSAGE]           = { name = __('发送消息'), tag = 5 },
    [ButtonType.ADD_FRIEND]             = { name = __('添加好友'), tag = 6 },
    [ButtonType.REMOVE_BLACKLIST]       = { name = __('移除黑名单'), tag = 7 },
    [ButtonType.REPORT]                 = { name = __('举报'), tag = 8 },
    [ButtonType.DELETE_UNION_MEMBER]    = { name = __('踢出工会'), tag = 9 },
    [ButtonType.PEOMOTION_UNION_MEMBER] = { name = __('升职'), tag = 10 },
    [ButtonType.DOWN_UNION_MEMBER]      = { name = __('降职'), tag = 11 },
    [ButtonType.TURN_OVER_PRESIDENT]    = { name = __('移交会长'), tag = 12 },
    [ButtonType.HOME_LAND]              = { name = __('去家园'), tag = 13 },
    [ButtonType.REMARK]                 = { name = __('备注'), tag = 14 },
    [ButtonType.BATTLE]                 = { name = __('切磋'), tag = 15 },
    [ButtonType.CAT_HOUSE]              = { name = __('去御屋'), tag = 16},
    [ButtonType.REMOVE_CAT_HOUSE]       = { name = __('踢出御屋'), tag = 17},
    [ButtonType.SET_TOP]                = { name = __('置顶'), tag = 18},
    [ButtonType.SET_TOP_CANCEL]         = { name = __('取消置顶'), tag = 19},
}

local IncludeButtons = {
    --ButtonType.RESTAURANT,ButtonType.HOME_LAND
    [HeadPopupType.FRIEND]                    = {ButtonType.SEND_MESSAGE, ButtonType.ZONE, ButtonType.DELETE_FRIEND, ButtonType.ADD_BLACKLIST},
    [HeadPopupType.STRANGER]                  = {ButtonType.ADD_FRIEND, ButtonType.ZONE, ButtonType.ADD_BLACKLIST},
    [HeadPopupType.RECENT_CONTACTS]           = {ButtonType.ADD_FRIEND, ButtonType.ZONE, ButtonType.ADD_BLACKLIST},
    [HeadPopupType.BLACKLIST]                 = {ButtonType.REMOVE_BLACKLIST},
    [HeadPopupType.RESTAURANT_FRIEND]         = {ButtonType.ZONE, ButtonType.RESTAURANT},
    [HeadPopupType.STRANGER_WORLD]            = {ButtonType.ADD_FRIEND, ButtonType.ZONE, ButtonType.ADD_BLACKLIST, ButtonType.REPORT},
    [HeadPopupType.UNION_PRESIDENT]           = {ButtonType.SEND_MESSAGE,ButtonType.ZONE, ButtonType.ADD_FRIEND , ButtonType.ADD_BLACKLIST, ButtonType.PEOMOTION_UNION_MEMBER ,ButtonType.DOWN_UNION_MEMBER, ButtonType.DELETE_UNION_MEMBER ,ButtonType.TURN_OVER_PRESIDENT },
    [HeadPopupType.UNION_VICE_PRESIDENT]      = {ButtonType.SEND_MESSAGE,ButtonType.ZONE, ButtonType.ADD_FRIEND , ButtonType.ADD_BLACKLIST, ButtonType.DELETE_UNION_MEMBER },
    [HeadPopupType.UNION_MEMBER]              = {ButtonType.SEND_MESSAGE,ButtonType.ZONE, ButtonType.ADD_FRIEND },
    [HeadPopupType.CAT_HOUSE_MINE]            = {ButtonType.CAT_HOUSE, ButtonType.REMOVE_CAT_HOUSE, ButtonType.ZONE},
    [HeadPopupType.CAT_HOUSE_FRIEND_FRIEND]   = {ButtonType.CAT_HOUSE, ButtonType.ZONE},
    [HeadPopupType.CAT_HOUSE_FRIEND_STRANGER] = {ButtonType.ADD_FRIEND, ButtonType.ZONE, ButtonType.ADD_BLACKLIST},
}

local FRIEND_TYPE_DEFAULT_BTN_NUM = #IncludeButtons[HeadPopupType.FRIEND] -- 好友类型默认的按钮数量

function PlayerHeadPopup:ctor(...)
    -- 屏蔽好友界面输入框
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = false})
    self.args = unpack({...})
    if self.args.playerId == gameMgr:GetUserInfo().playerId then self:RemoveSelf_() return end
    self.showButtons = {} -- 显示的按钮
    self.HeadPopupType = self.args.type or HeadPopupType.STRANGER
    self.isOwnFriend = self:CheckIsOwnFriend(self.args)

    local contCell = table.nums(IncludeButtons[self.HeadPopupType])
    local mediator = AppFacade.GetInstance():RetrieveMediator("AppMediator")
    mediator:SendSignal(COMMANDS.COMMAND_Chat_GetPlayInfo, {playerIdList = tostring(self.args.playerId), type = PlayerInfoType.HEADPOPUP})
    local function CreateView()
        local bg = nil
        local lineHeight = 0
        local listSize
        if contCell > 6  then
            lineHeight = 80
            listSize  = cc.size(308, 280)
            bg = display.newImageView(_res('avatar/ui/profile_bg.png'), 0, 0, {size = cc.size(340,470) , capInsets = cc.rect(168, 216 ,2,2  )  ,scale9 = true })
        else
            listSize = cc.size(308, 240)
            bg = display.newImageView(_res('avatar/ui/profile_bg.png'))
        end

        local bgSize = bg:getContentSize()
        local view = CLayout:create(bgSize)
        view:addChild(bg)
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        mask:setAnchorPoint(cc.p(0.5, 0.5))
        mask:setTouchEnabled(true)
        mask:setContentSize(bgSize)
        view:addChild(mask, -1)
        bg:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        local nameBg = display.newImageView(_res('avatar/ui/friends_tips_bg_name.png'), 116, 370 +lineHeight, {ap = cc.p(0, 1)})
        view:addChild(nameBg, 5)
        local nameLabel = display.newLabel(128, 354 +lineHeight, fontWithColor(11, {text = '', ap = cc.p(0, 0.5)}))
        view:addChild(nameLabel, 10) 
        -- 头像
        local headIcon = require('common.FriendHeadNode').new({
            enable = false, scale = 0.7, showLevel = true
        })
        headIcon:setVisible(false)
        headIcon:setPosition(cc.p(70, 322 +lineHeight))
        view:addChild(headIcon, 10)
        -- 离线
        local offLineLabel = display.newLabel(290, 354 +lineHeight, fontWithColor(11, {text = __('离线') , reqW = 75}))
        view:addChild(offLineLabel, 10)
        offLineLabel:setVisible(false)
        -- 备注
        local remarkLabel = display.newLabel(128, 320 +lineHeight, {text = '', fontSize = 24, color = '#cb5600', ap = cc.p(0, 0.5)})
        view:addChild(remarkLabel, 10)
        -- 餐厅等级
        local restaurantLevel = display.newLabel(128, 285 +lineHeight, fontWithColor(5, {text = '', ap = cc.p(0, 0.5)}))
        view:addChild(restaurantLevel, 10)
        -- 亲密度
        local intimacy = display.newLabel(128, 284 +lineHeight, fontWithColor(5, {text = '', ap = cc.p(0, 0.5)}))
        view:addChild(intimacy, 10)
        intimacy:setVisible(false)
        -- 置顶图标
        local setTopIcon = display.newImageView(_res('ui/home/friend/friends_bg_list_top2.png'), 300, 300 + lineHeight)
        view:addChild(setTopIcon, 10)
        setTopIcon:setVisible(false)
        -- 列表

        local gridView = CGridView:create(cc.size(listSize.width, listSize.height))
        if contCell > 6 then
            gridView:setSizeOfCell(cc.size(listSize.width/2, listSize.height/4))
        else
            gridView:setSizeOfCell(cc.size(listSize.width/2, 70))
        end
        gridView:setColumns(2)
        gridView:setAutoRelocate(true)
        view:addChild(gridView)
        gridView:setPosition(cc.p(170, 130 + lineHeight/2))
        gridView:setBounceable(false)
        gridView:setDataSourceAdapterScriptHandler(handler(self,self.ListDataSourceAction))

        return { 
            view      = view,
            headIcon  = headIcon,
            gridView  = gridView,
            nameLabel = nameLabel,
            offLineLabel = offLineLabel,
            restaurantLevel = restaurantLevel,
            intimacy = intimacy,
            remarkLabel = remarkLabel, 
            setTopIcon = setTopIcon
        }
    end
    local function closeCallback()
        PlayAudioByClickClose()
        self:RemoveSelf_()
    end
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(utils.getLocalCenter(self))
    eaterLayer:setOnClickScriptHandler(closeCallback)
    self:addChild(eaterLayer)
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)
    display.commonUIParams(self.viewData_.view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    
end
--[[
初始化数据
--]]
function PlayerHeadPopup:InitData( datas )
    self.playerDatas     = checktable(datas.playerList[1])
    self.playerId        = checkint(self.playerDatas.friendId)
    self.playerLevel     = checkint(self.playerDatas.level)
    self.playerName      = self.playerDatas.name or ''
    self.avatar          = self.playerDatas.avatar or ''
    self.avatarFrame     = self.playerDatas.avatarFrame or ''
    self.isOnline        = checkint(self.playerDatas.isOnline)
    self.intimacy        = self.playerDatas.intimacy
    self.restaurantLevel = self.playerDatas.restaurantLevel
    self.noteName        = self.playerDatas.noteName or ''
    self.houseLevel      = checkint(self.playerDatas.houseLevel)
    self.topTime         = self.playerDatas.topTime

    if  tostring(self.HeadPopupType)  == HeadPopupType.FRIEND then
        local btnNum = table.nums(IncludeButtons[HeadPopupType.FRIEND])
        if btnNum > FRIEND_TYPE_DEFAULT_BTN_NUM then
            for i = 1, btnNum - FRIEND_TYPE_DEFAULT_BTN_NUM do
                table.remove(IncludeButtons[HeadPopupType.FRIEND])
            end
        end
        -- 好友备注开关
        if GAME_MODULE_OPEN.FRIEND_REMARK then
            table.insert(IncludeButtons[HeadPopupType.FRIEND] ,ButtonType.REMARK)
        end
        -- 好友切磋开关
        if GAME_MODULE_OPEN.FRIEND_BATTLE then
            table.insert(IncludeButtons[HeadPopupType.FRIEND] ,ButtonType.BATTLE)
        end
        -- 好友置顶
        if checkint(self.topTime) == 0 then
            table.insert(IncludeButtons[HeadPopupType.FRIEND], ButtonType.SET_TOP)
        else
            table.insert(IncludeButtons[HeadPopupType.FRIEND], ButtonType.SET_TOP_CANCEL)
        end
        local openlevel =   CommonUtils.GetModuleOpenLevel(JUMP_MODULE_DATA.HOME_LAND)
        local openRestaurantLevel =   CommonUtils.GetModuleOpenRestaurantLevel(JUMP_MODULE_DATA.HOME_LAND)
        if checkint(self.playerLevel) >= checkint(openlevel) and
        checkint(self.restaurantLevel) >=  checkint(openRestaurantLevel) and   CommonUtils.UnLockModule(JUMP_MODULE_DATA.HOME_LAND) then
            table.insert(IncludeButtons[HeadPopupType.FRIEND] ,ButtonType.HOME_LAND )
        else
            table.insert(IncludeButtons[HeadPopupType.FRIEND] ,ButtonType.RESTAURANT )
        end
    end
    self:UpdateUi()
end

function PlayerHeadPopup:CheckIsOwnFriend(datas)
    local isOwnFriend = false
    local friendId = checkint(datas.friendId)
    if friendId > 0 then
        for index, value in ipairs(gameMgr:GetUserInfo().friendList) do
            if checkint(value.friendId) == friendId then
                isOwnFriend = true
                break
            end
        end
    end

    return isOwnFriend
end

--[[
更新Ui
--]]
function PlayerHeadPopup:UpdateUi()
    local viewData = self.viewData_
    viewData.headIcon:RefreshSelf({avatar = self.avatar, level = self.playerLevel, avatarFrame = self.avatarFrame})
    viewData.headIcon:setVisible(true)
    viewData.nameLabel:setString(self.playerName)
    if self.noteName and self.noteName ~= '' then
        viewData.remarkLabel:setString(string.format('(%s)', self.noteName))
    end
    if self.isOnline == 1 then
        viewData.offLineLabel:setVisible(false)
    else
        viewData.offLineLabel:setVisible(true)
    end

    local isInCatHouse = (self.HeadPopupType == HeadPopupType.CAT_HOUSE_MINE) or (self.HeadPopupType == HeadPopupType.CAT_HOUSE_FRIEND_FRIEND) or (self.HeadPopupType == HeadPopupType.CAT_HOUSE_FRIEND_STRANGER)
    if self.intimacy then
        viewData.intimacy:setVisible(true)
        viewData.restaurantLevel:setString(string.fmt(__('亲密度:_num_'), {['_num_'] = self.intimacy}))
    elseif isInCatHouse then
        viewData.intimacy:setVisible(false)
        viewData.restaurantLevel:setString(string.fmt(__('御屋等级:_num_'), {['_num_'] = self.houseLevel}))
    else
        viewData.restaurantLevel:setString(string.fmt(__('餐厅等级:_num_'), {['_num_'] = self.restaurantLevel}))
        viewData.intimacy:setVisible(false)
    end

    viewData.setTopIcon:setVisible(checkint(self.topTime) ~= 0)

    self:UpdateButtonList()
end
--[[
更新列表
--]]
function PlayerHeadPopup:UpdateButtonList()
    local datas = IncludeButtons[self.HeadPopupType]
    for i,v in ipairs(datas) do
        local data = ButtonDatas[v]
        -- tag == 6 表示添加好友
        if data.tag == 6 then
            -- 没有该好友才显示 添加好友按钮
            if not self.isOwnFriend then
                table.insert(self.showButtons, data)
            end
        else
            table.insert(self.showButtons, data)
        end
    end

    self.viewData_.gridView:setCountOfCell(#self.showButtons)
    self.viewData_.gridView:reloadData()
end
--[[
列表处理
--]]
function PlayerHeadPopup:ListDataSourceAction( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(154, 74)
    if pCell == nil then
        pCell = CGridViewCell:new()
        pCell:setContentSize(cSize)
        local btn = display.newButton(cSize.width/2, cSize.height/2, {n = _res('ui/common/common_btn_orange.png') , size =  cc.size(135 , 70) , scale9 = true })
        btn:setName('button')  
        pCell:addChild(btn)      
        btn:setOnClickScriptHandler(handler(self, self.ListButtonCallback))
    end
    xTry(function()
        local datas = self.showButtons[index]
        local btn = pCell:getChildByName('button')
        if datas.tag == ButtonDatas[ButtonType.SET_TOP_CANCEL].tag then
            btn:setNormalImage(_res('ui/common/common_btn_white_default.png'))
        end
        display.commonLabelParams(btn, fontWithColor(14, {text = datas.name}))
        btn:setTag(datas.tag)
    end,__G__TRACKBACK__)
    return pCell
end
--[[
按钮回调
--]]
function PlayerHeadPopup:ListButtonCallback( sender )
    PlayAudioByClickNormal()
    
    local tag = tostring(sender:getTag())
    if tag == ButtonType.ZONE then 
        local mediator = require("Game.mediator.PersonInformationMediator").new({playerId = self.playerId})
        AppFacade.GetInstance():RegistMediator(mediator)
        self:runAction(cc.RemoveSelf:create())
    elseif tag == ButtonType.RESTAURANT then 

        local friendId = self.playerId
        local friendAvatarMdt = AppFacade.GetInstance():RetrieveMediator('FriendAvatarMediator')
        if friendAvatarMdt then
            if friendAvatarMdt:getCurrentFriendId() ~= checkint(friendId) then
                friendAvatarMdt:setCurrentFriendId(friendId)
                AppFacade.GetInstance():DispatchObservers(UPDATE_LOBBY_FRIEND_LIST_SELECT_STATE, {friendId = friendId})
                self:RemoveSelf_()
            end
        else
            friendAvatarMdt = require('Game.mediator.FriendAvatarMediator').new({friendId = friendId})
            AppFacade.GetInstance():RegistMediator(friendAvatarMdt)
            AppFacade.GetInstance():DispatchObservers(UPDATE_LOBBY_FRIEND_LIST_SELECT_STATE, {friendId = friendId})
            self:RemoveSelf_()
        end

        -- 更新好友列表 选中状态
    elseif tag == ButtonType.DELETE_FRIEND then 
        local commonTip = require('common.NewCommonTip').new({text =__('是否删除该好友？'), callback = function ()
            AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_Friend_DelFriend, {friendId = self.playerId})
            self:RemoveSelf_()
        end})
        commonTip:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(commonTip)
    elseif tag == ButtonType.HOME_LAND  then
        --local mediator = require("Game.mediator.HomelandMediator").new({playerId = self.playerId })
        --AppFacade.GetInstance():RegistMediator(mediator)
        app:RetrieveMediator("Router"):Dispatch({name =  'HomeMediator'} , {name =  "HomelandMediator" , params = { playerId = self.playerId}})
        self:RemoveSelf_()
    elseif tag == ButtonType.ADD_BLACKLIST then 
        local commonTip = require('common.NewCommonTip').new({text =__('是否将其加入黑名单？'), callback = function ()
            AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_Friend_AddBlacklist, {blacklistId = self.playerId})
            self:RemoveSelf_()
        end})
        commonTip:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(commonTip)
    elseif tag == ButtonType.SEND_MESSAGE then 
        if CommonUtils.IsInBlacklist(self.playerId) then
            uiMgr:ShowInformationTips(__('对方在您的黑名单中'))
        else
            local mediator = AppFacade.GetInstance():RetrieveMediator('FriendMediator')
            if not mediator then
                mediator = require( 'Game.mediator.FriendMediator' ).new({friendListType = FriendListViewType.RECENT_CONTACTS, strangerDatas = self.playerDatas})
                AppFacade.GetInstance():RegistMediator(mediator)
            else
                mediator:RightButtonActions(FriendTabType.FRIENDLIST)
                local friendListMediator = AppFacade.GetInstance():RetrieveMediator('FriendListMediator')
                if friendListMediator then
                    friendListMediator:SwitchChatView(self.playerDatas)
                end
            end
            AppFacade.GetInstance():DispatchObservers('REMOVE_CHAT_VIEW')
            self:RemoveSelf_()
            
        end
    elseif tag == ButtonType.ADD_FRIEND then 
        AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_Friend_PopupAddFriend, {friendId = self.playerId})
        self:RemoveSelf_()
    elseif tag == ButtonType.REMOVE_BLACKLIST then 
        AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_Friend_DelBlacklist, {blacklistId = self.playerId})
        self:RemoveSelf_()
    elseif tag == ButtonType.REPORT then
        AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_Chat_Report, {reportedId = self.playerId, content = self.args.message, speakTime = os.date('%Y-%m-%d %H:%M:%S', checkint(self.args.sendTime))})
        self:RemoveSelf_()
    elseif tag == ButtonType.DELETE_UNION_MEMBER then
        local myselfJobType = unionMgr:GetMyselfInUnionJob()
        local jobType = unionMgr:GetUnionMemberJobByPlayerId(self.playerId)
        if checkint(myselfJobType)  <    jobType then
            local playerName = unionMgr:GetUnionMemberNamePlayerId(self.playerId)
            local text =  string.format(__('是否将%s踢出工会？') ,playerName )
            local callback = function ()
                AppFacade.GetInstance():DispatchSignal(POST.UNION_KICKOUT.cmdName,{memberId  = self.playerId})
                self:RemoveSelf_()
            end
            local title  = __('踢人')
            app.uiMgr:AddCommonTipDialog({
                                           descr =  text ,
                                           callback = callback ,
                                           text = title ,
                                       })
        else
            local playerName = unionMgr:GetUnionMemberNamePlayerId(self.playerId)
            uiMgr:ShowInformationTips(string.format(__('您没有踢出%s的权限') ,playerName) )
        end
    elseif tag == ButtonType.PEOMOTION_UNION_MEMBER then
        local myselfJobType = unionMgr:GetMyselfInUnionJob()
        if myselfJobType == UNION_JOB_TYPE.PRESIDENT then
            if checkint(self.playerId)  == checkint(gameMgr:GetUserInfo().playerId) then
                uiMgr:ShowInformationTips(__('您已经是会长了，不能给自己升值'))
                return
            end
            local jobType = unionMgr:GetUnionMemberJobByPlayerId(self.playerId)
            local isAdd = unionMgr:JuageUnionAppointVicePresident()
            if not isAdd then
                local unionLevel = unionMgr:getUnionData().level
                local unionLevelConfig = CommonUtils.GetConfigAllMess('level' , 'union')
                local unionLevelOneConfig = unionLevelConfig[tostring(unionLevel)]
                local vicePresidentNum = unionLevelOneConfig['job'][tostring(UNION_JOB_TYPE.VICE_PRESIDENT)]
                uiMgr:ShowInformationTips(string.format(__('您当前工会等级为%d，最多可以有%d名副会长') ,unionLevel ,vicePresidentNum  ) )
                return
            end
            if checkint(jobType)  ==  UNION_JOB_TYPE.COMMON  then
                local playerName = unionMgr:GetUnionMemberNamePlayerId(self.playerId)
                local text =  string.format(__('您目前是工会的会长,确定将%s升职为副会长？') ,playerName )
                local callback = function ()
                    AppFacade.GetInstance():DispatchSignal(POST.UNION_ASSIGNJOB.cmdName,{memberId  = self.playerId , job = UNION_JOB_TYPE.VICE_PRESIDENT })
                    self:RemoveSelf_()
                end
                local title = __('升职')
                app.uiMgr:AddCommonTipDialog({
                                               descr =  text ,
                                               callback = callback ,
                                               text = title ,
                                           })

            else
                local jobConfig = CommonUtils.GetConfigAllMess('job','union')
                uiMgr:ShowInformationTips(string.format( __('该成员已经是%s') , jobConfig[tostring(jobType)].name ) )
            end
        end
    elseif tag == ButtonType.DOWN_UNION_MEMBER then
        local myselfJobType = unionMgr:GetMyselfInUnionJob()
        if myselfJobType == UNION_JOB_TYPE.PRESIDENT then
            local jobType = unionMgr:GetUnionMemberJobByPlayerId(self.playerId)

            if checkint(jobType)  ==  UNION_JOB_TYPE.VICE_PRESIDENT  then
                if checkint(self.playerId)  == checkint(gameMgr:GetUserInfo().playerId) then
                    uiMgr:ShowInformationTips(__('您已经是会长了，不能给自己降职'))
                    return
                end
                local playerName = unionMgr:GetUnionMemberNamePlayerId(self.playerId) or ""
                local text =  string.format(__('您目前是工会的会长,确定%s由副会长降职为普通成员？') ,playerName )
                local title = __('降职')
                local callback = function ()
                    AppFacade.GetInstance():DispatchSignal(POST.UNION_ASSIGNJOB.cmdName,{memberId  = self.playerId , job = UNION_JOB_TYPE.COMMON })
                    self:RemoveSelf_()
                end
                app.uiMgr:AddCommonTipDialog({
                                               descr =  text ,
                                               callback = callback ,
                                               text = title ,
                                           })
            else
                uiMgr:ShowInformationTips(__('该工会成员不能再降级'))
            end
        end

    elseif tag == ButtonType.TURN_OVER_PRESIDENT then
        local myselfJobType = unionMgr:GetMyselfInUnionJob()

        if myselfJobType == UNION_JOB_TYPE.PRESIDENT then
            if checkint(self.playerId)  == checkint(gameMgr:GetUserInfo().playerId) then
                uiMgr:ShowInformationTips(__('您已经是会长了'))
                return
            end
            local playerName = unionMgr:GetUnionMemberNamePlayerId(self.playerId)
            local text =  string.format(__('您目前是工会的会长,确定将会长移交给%s？') ,playerName )
            local title = __('移交会长')
            local callback = function ()
                AppFacade.GetInstance():DispatchSignal(POST.UNION_ASSIGNJOB.cmdName,{memberId  = self.playerId , job = UNION_JOB_TYPE.PRESIDENT })
                self:RemoveSelf_()
            end
            app.uiMgr:AddCommonTipDialog({
               descr =  text ,
               callback = callback ,
               text = title ,
           })
        else
            uiMgr:ShowInformationTips(__('能不是工会的会长没有权利移交职位'))
        end
    elseif tag == ButtonType.REMARK then
        uiMgr:AddDialog('common.FriendRemarkPopup', {friendId = self.playerId})
        self:RemoveSelf_()
    elseif tag == ButtonType.BATTLE then
        local friendBattleMediator = require( 'Game.mediator.friend.FriendBattleMediator' )
        local mediator = friendBattleMediator.new({enemyPlayerId = self.playerId})
        app:RegistMediator(mediator)
        self:RemoveSelf_()
    elseif tag == ButtonType.CAT_HOUSE then
        if app.catHouseMgr:checkCanGoToFriendHouse(self.playerId) then
            app.catHouseMgr:goToFriendHouse(self.playerId)
        end
        self:RemoveSelf_()
    elseif tag == ButtonType.REMOVE_CAT_HOUSE then
        local callback = function ()
            AppFacade.GetInstance():DispatchSignal(POST.HOUSE_KICKOUT.cmdName, {memberId  = self.playerId})
            self:RemoveSelf_()
        end
        local tipsText = string.fmt(__('是否将_name_踢出御屋？'), {_name_ = self.playerName})
        app.uiMgr:AddCommonTipDialog({text = tipsText,callback = callback})
    elseif tag == ButtonType.SET_TOP then
        AppFacade.GetInstance():DispatchSignal(POST.FRIEND_SET_TOP.cmdName, {friendId  = self.playerId})
        self:RemoveSelf_()
    elseif tag == ButtonType.SET_TOP_CANCEL then
        AppFacade.GetInstance():DispatchSignal(POST.FRIEND_SET_TOP_CANCEL.cmdName, {friendId  = self.playerId})
        self:RemoveSelf_()
    end
end
--[[
移除自己
--]]
function PlayerHeadPopup:GoogleBack()
    self:RemoveSelf_()
    return true
end
--[[
移除自己
--]]
function PlayerHeadPopup:RemoveSelf_()
    self:setVisible(false)
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = true})
    self:runAction(cc.RemoveSelf:create())
end
function PlayerHeadPopup:onCleanup()
    AppFacade.GetInstance():DispatchObservers(CLOSE_PLAYER_HEAD_POPUP_EVENT ,{})
end
return PlayerHeadPopup