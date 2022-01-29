
---
--- Created by xingweihao.
--- DateTime: 27/09/2017 2:35 PM
--- 交易和探索的修改

local Mediator = mvc.Mediator
---@class UnionInforDetailMediator :Mediator
local UnionInforDetailMediator = class("UnionInforDetailMediator", Mediator)
local NAME = "UnionInforDetailMediator"
---@type UnionManager
local unionMgr = AppFacade.GetInstance():GetManager('UnionManager')
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local CHANGE_UNION_NAME_NEED_DIAMON =  500
local BUTTON_CLICK = {
    CHANGE_DECR_TEXT    = 1102, -- 修改工会的签名
    CHANGE_UNION_NAME   = 1103, -- 修改工会名字
    CHANGE_UNION_HEADER = 1104, -- 修改工会的头像
    CHANGE_DECR         = 1105,
    CHANGE_HEAD         = 1109, -- 修改头像
    UNION_TIPS          = 1110, -- 工会的提示按钮
    UNION_QUIT          = 1111, -- 退出工会
    SWITCH_BTN          = 1112,
    UNION_RANKING       = 1113,
}

local SORT_INDEX = {
    ONLINE_PRESIDENT          = 1,
    ONLINE_VICE_PRESIDENT     = 2,
    ONLINE_COMMON             = 3,
    NOT_ONLINE_PRESIDENT      = 4,
    NOT_ONLINE_VICE_PRESIDENT = 5,
    NOT_ONLINE_COMMON         = 6,
}
local JobTitleDataConfig = CommonUtils.GetConfigAllMess('jobTitle', 'union')
local JobConfig = CommonUtils.GetConfigAllMess('job', 'union')
local UnionUpgradeData = CommonUtils.GetConfigAllMess('level' , 'union')
function UnionInforDetailMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.switchText = {
        __('贡献值'),
        __('职称')
    }
    self.cellShowType  = 2  -- 显示的方式 1. 是贡献值 2 。 是 职位
    self.datas = params or {}
    self.collectMediator = {} -- 用于收集和管理mediator
    self.gradeCellCount = 0
    self.preIndex = nil  -- 上一次点击
    self.memberList  = {}
end

function UnionInforDetailMediator:InterestSignals()
    local signals = {
        POST.UNION_QUIT.sglName ,
        POST.UNION_CHANGEINFO.sglName ,
        POST.UNION_MEMBER.sglName ,
        POST.UNION_ASSIGNJOB.sglName ,
        CHNAGE_UNION_HEAD_EVENT ,
        CLOSE_PLAYER_HEAD_POPUP_EVENT ,
        FRIEND_REFRESH_EDITBOX ,
        POST.UNION_KICKOUT.sglName

    }
    return signals
end

function UnionInforDetailMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.UNION_QUIT.sglName then   -- 退出工会
        local unionId = checkint(gameMgr:GetUserInfo().unionId)
        gameMgr:GetUserInfo().unionId = nil
        -- 退出工会刷新小红点
        app.badgeMgr:CheckUnionRed()
        -- 退出工会聊天室
        unionMgr:ExitUnionChatRoom()
        -- 删除本地工会神兽幼崽信息
        gameMgr:ClearUnionPetsByUnionId(unionId)

        self:GetFacade():BackHomeMediator()
    elseif name == POST.UNION_CHANGEINFO.sglName then -- 修改工会的信息
        local requestData = data.requestData
        if checkint(data.errcode) == 0   then
            if requestData.name  then
                self:ChangeUnionName(requestData.name)
            elseif requestData.avatar  then
                self:ChangeUnionAvatar(requestData.avatar)
            elseif requestData.unionSign  then
                self:ChangeUnionSign(requestData.unionSign)
            end
        else
            if requestData.name  then
            elseif requestData.unionSign  then
                self.viewData.changeLabelContent:setVisible(true)
                self.viewData.changeLabelContent:setTouchEnabled(true)
                self.viewData.decLabel:setVisible(true)
            end
        end
    elseif name == POST.UNION_MEMBER.sglName then -- 拉取好友的列表
        local member =  data.member
        local unionHomeData = unionMgr:getUnionData()
        unionHomeData.member = self:SortData(member)
        unionHomeData.contributionPoint = checkint(data.contributionPoint)
        self.memberList = unionHomeData.member
        self.gradeCellCount = #unionHomeData.member
        local onLine  = self:GetOnlineMemberNum(unionHomeData.member)
        self:UpdateRightView(onLine)
        self:UpdateLeftView()
    elseif name == POST.UNION_ASSIGNJOB.sglName then
        local requestData = data.requestData
        local jobType = checkint(requestData.job)
        local playerId = requestData.memberId
        unionMgr:TurnOverUnionJobTypeByPlayerId(playerId ,jobType )
        self:SortData(unionMgr:getUnionData().member)
        local unionHomeData = unionMgr:getUnionData()
        unionHomeData.member  =  self:SortData(unionHomeData.member)
        self.memberList = unionHomeData.member
        self:ReloadDataGrideView()
        local playerName = ""
        local jonType = UNION_JOB_TYPE.COMMON
        if checkint(gameMgr:GetUserInfo().playerId) == checkint(playerId)  then
            playerName = __('你')
            jonType = unionMgr:GetMyselfInUnionJob()
        else
            local data = unionMgr:GetUnionMemberDataPlayerId(playerId)
            playerName = data.playerName or ""
            jonType = data.job or jonType
        end
        uiMgr:ShowInformationTips(string.format(__('%s的职位变更为%s') ,playerName , JobConfig[tostring(jonType)].name ) )
        -- 获取到自己的职位类型 变更权限
        local jobType = unionMgr:GetMyselfInUnionJob()
        self:UpdateViewByUnionType(jobType)
    elseif name == POST.UNION_KICKOUT.sglName then
        local requestData = data.requestData
        local playerId = requestData.memberId
        local playerName = unionMgr:GetUnionMemberNamePlayerId(playerId)
        uiMgr:ShowInformationTips(string.format(__('%s被踢出工会') ,playerName ) )
        unionMgr:DeleteUnionMemberByPlayerId(playerId  )
        local unionHomeData = unionMgr:getUnionData()
        local onLine  = self:GetOnlineMemberNum(unionHomeData.member)
        self:UpdateLeftView()
        self:UpdateRightView(onLine)
    elseif name == CHNAGE_UNION_HEAD_EVENT then
        local iconId = data.iconId or 101
        self.viewData.headImage:setTexture(CommonUtils.GetGoodsIconPathById(iconId))
        self:SendSignal(POST.UNION_CHANGEINFO.cmdName , { avatar = iconId })
    elseif name == FRIEND_REFRESH_EDITBOX then
        if not  self.viewData.changeLabelContent:isVisible() then
            local isEnabled = data.isEnabled
            self.viewData.descrName:setVisible(isEnabled)
        end
    elseif name == CLOSE_PLAYER_HEAD_POPUP_EVENT then
        self:UpdateSelectCell()
    end
end

function UnionInforDetailMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type UnionInforDetailView
    self.viewComponent = require("Game.views.UnionInforDetailView").new()
    self:SetViewComponent(self.viewComponent)
    self.viewComponent:setPosition(display.center)
    self.viewData =  self.viewComponent.viewData
    local viewData = self.viewData
    viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
    viewData.descrName:registerScriptEditBoxHandler(function(eventType,sender)
        if eventType == 'began' then  -- 输入开始
        elseif eventType == 'ended' then  -- 输入结束
            self:ButtonAction(sender)
        elseif eventType == 'changed' then  -- 内容变化
        elseif eventType == 'return' then  -- 从输入返回
            self:ButtonAction(sender)
        end
    end)
    display.commonLabelParams(viewData.switchLabel, fontWithColor('16' , { text =self.switchText[self.cellShowType]  }))
    display.commonUIParams(viewData.unionExit ,{ cb = handler(self, self.ButtonAction) , animate = true  })
    display.commonUIParams(viewData.unionRanking ,{ cb = handler(self, self.ButtonAction) , animate = true  })
    display.commonUIParams(viewData.tipBtn ,{ cb = handler(self, self.ButtonAction) , animate = true  })
    self:UpdateLeftView()
    local jobType = unionMgr:GetMyselfInUnionJob()
    self:UpdateViewByUnionType(jobType)
end
--[[
    根据工会成员类型刷新type 页面
--]]
function UnionInforDetailMediator:UpdateViewByUnionType(jobType)
    self.viewData =  self.viewComponent.viewData
    local viewData = self.viewData
    if checkint(jobType) == UNION_JOB_TYPE.PRESIDENT then
        viewData.changeHeadLabel:setVisible(true)
        viewData.changeNameBtn:setVisible(true)
        viewData.changeNameLayout:setTouchEnabled(true)
        viewData.changeLabelContent:setTouchEnabled(true)
        viewData.changeLabel:setVisible(true)
        display.commonUIParams(viewData.changeNameLayout ,{ cb = handler(self, self.ButtonAction) , animate = true  })
        display.commonUIParams(viewData.changeLabelContent ,{ cb = handler(self, self.ButtonAction) , animate = true  })
        display.commonUIParams(viewData.headLayout ,{ cb = handler(self, self.ButtonAction) , animate = true  })
    else
        viewData.descrName:setVisible(false)
        viewData.changeHeadLabel:setVisible(false)
        viewData.changeNameBtn:setVisible(false)
        viewData.changeNameLayout:setTouchEnabled(false)
        viewData.changeLabelContent:setTouchEnabled(false)
        viewData.changeLabel:setVisible(false)
    end
end
-- 点击事件
function  UnionInforDetailMediator:ButtonAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == BUTTON_CLICK.CHANGE_DECR_TEXT then
        local viewData = self.viewData
        local jobType = unionMgr:GetMyselfInUnionJob()
        if checkint(jobType)  ~=  UNION_JOB_TYPE.PRESIDENT then
            uiMgr:ShowInformationTips(__('只有会长才可以修改签名'))
            return
        end
        if viewData.changeLabelContent:isVisible() then
            return
        end
        if CommonUtils.CheckIsDisableInputDay() then
            return
        end
        local str = sender:getText()
        if str ~=  '' then
            if unionMgr:getUnionData().unionSign == str then
                self.viewData.changeLabelContent:setVisible(true)
                self.viewData.changeLabelContent:setTouchEnabled(true)
                self.viewData.decLabel:setVisible(true)
                sender:setVisible(false)
                uiMgr:ShowInformationTips(__('签名没有发生任何改变'))
                return
            end
            self:SendSignal(POST.UNION_CHANGEINFO.cmdName ,{unionSign = str})
        else
            self.viewData.changeLabelContent:setVisible(true)
            self.viewData.changeLabelContent:setTouchEnabled(true)
            self.viewData.decLabel:setVisible(true)
        end
        sender:setText("")
        sender:setVisible(false)
    elseif tag == BUTTON_CLICK.CHANGE_DECR then
        local viewData = self.viewData
        sender:setVisible(false)
        sender:setTouchEnabled(false)
        sender:runAction(cc.Sequence:create(
                cc.DelayTime:create(0.2),
                cc.CallFunc:create(
                    function ()
                        viewData.descrName:setVisible(true)
                        viewData.descrName:setText(unionMgr:getUnionData().unionSign)
                    end
                )
        ))
    elseif tag ==  BUTTON_CLICK.CHANGE_HEAD then
        --TODO 修改头像的事件
        local jobType = unionMgr:GetMyselfInUnionJob()
        if checkint(jobType)  ~=  UNION_JOB_TYPE.PRESIDENT then
            uiMgr:ShowInformationTips(__('只有会长才可以修改工会头像'))
            return
        end
        local mediator = require("Game.mediator.ChangeUnionHeadOrHeadFrameMediator").new(
                { type = CHANGE_TYPE.CHANGE_UNION_HEAD , id = unionMgr:getUnionData().avatar , unionLevel = unionMgr:getUnionData().level  })
        self:GetFacade():RegistMediator(mediator)
    elseif tag ==  BUTTON_CLICK.CHANGE_UNION_NAME then
        local jobType = unionMgr:GetMyselfInUnionJob()
        if checkint(jobType)  ~=  UNION_JOB_TYPE.PRESIDENT then
            uiMgr:ShowInformationTips(__('只有会长才可以修改工会昵称'))
            return
        end
        app.uiMgr:AddChangeNamePopup({
            renameCB      = function(newName)
                self:SendSignal(POST.UNION_CHANGEINFO.cmdName, {name = newName})
            end,
            renameConsume = {goodsId = DIAMOND_ID, num = CHANGE_UNION_NAME_NEED_DIAMON},
            title         = __("工会名称"),
            preName       = app.unionMgr:getUnionData().name,
        })
    elseif tag == BUTTON_CLICK.SWITCH_BTN then
        local viewData = self.viewData
        if self.cellShowType ==1 then
            self.cellShowType =2
        else
            self.cellShowType =1
        end
        display.commonLabelParams(viewData.switchLabel,  fontWithColor('16' , { text = self.switchText[self.cellShowType] }))
        self:ReloadDataGrideView()
    elseif tag ==  BUTTON_CLICK.UNION_QUIT then
        local myselfJobType = unionMgr:GetMyselfInUnionJob()
        if checkint(myselfJobType)  == UNION_JOB_TYPE.PRESIDENT then
            if self.gradeCellCount > 1 then
                local  text = __('您目前还是本工会的会长，请将会长职位转交给他人后，再退出本工会。')
                local title = __('是否退出工会么？')
                app.uiMgr:AddCommonTipDialog({descr = text, isOnlyOK = true, text = title})
            else
                local  text = __('退出后工会解散，24小时内您无法申请工会并清除个人贡献值，是否退出？')
                local title = __('是否退出工会么？')
                local callback = function ()
                    self:SendSignal(POST.UNION_QUIT.cmdName , {})
                end
                local commonTip = app.uiMgr:AddCommonTipDialog({descr = text, callback = callback, text = title})
                local tip =   commonTip.tip
                if tip then
                    local pos =  cc.p( tip:getPositionX(), tip:getPositionY() + 20)
                    tip:setPosition(pos)
                end
            end
        else
            local title = __('是否退出工会么？')
            local  text = __('退出本工会后，将有24小时无法申请进入其它工会并清除个人贡献值，是否确认退出？')
            local callback = function ()
                self:SendSignal(POST.UNION_QUIT.cmdName , {})
            end
            app.uiMgr:AddCommonTipDialog({descr = text, callback = callback, text = title} )
        end
    elseif tag == BUTTON_CLICK.UNION_RANKING then

        -- TODO 添加工会的内部排行版
        local mediator = require("Game.mediator.UnionRankMediator").new()
        self:GetFacade():RegistMediator(mediator)
    elseif tag == BUTTON_CLICK.UNION_TIPS then
        uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.UNION)]})
    end
end
--[[
    刷新GrideView
--]]
function UnionInforDetailMediator:ReloadDataGrideView()
    self.preIndex = nil
    local viewData = self.viewComponent.viewData
    self.gradeCellCount = #unionMgr:getUnionData().member
    viewData.gridView:setCountOfCell(self.gradeCellCount)
    viewData.gridView:reloadData()
end
--[[
    获取在线的人数
--]]
function UnionInforDetailMediator:GetOnlineMemberNum(member)
    local count =  0
    for k , v in pairs(member) do
        v.contributionPoint = checkint(v.contributionPoint)
        if checkint(v.isOnline) == 1 then
            count = count +1
        end
    end
    return count
end
--[[
    排序的方式 首先是按照
--]]
function UnionInforDetailMediator:SortData(member)
    local jobData      = CommonUtils.GetConfigAllMess('job', 'union')
    local currentTime = getServerTime()
    for k , v in pairs(member) do
        v.contributionPoint = checkint(v.contributionPoint)
        v.sortIndex = SORT_INDEX.NOT_ONLINE_COMMON
        if checkint(v.isOnline) == 1 then
            if checkint(v.job) == UNION_JOB_TYPE.PRESIDENT then
                v.sortIndex = SORT_INDEX.ONLINE_PRESIDENT
            elseif  checkint(v.job) == UNION_JOB_TYPE.VICE_PRESIDENT then
                v.sortIndex = SORT_INDEX.ONLINE_VICE_PRESIDENT
            elseif  checkint(v.job) == UNION_JOB_TYPE.COMMON then
                v.sortIndex = SORT_INDEX.ONLINE_COMMON
            end
            v.lineName =  __('在线')
        else
            if checkint(v.job) == UNION_JOB_TYPE.PRESIDENT then
                v.sortIndex = SORT_INDEX.NOT_ONLINE_PRESIDENT
            elseif  checkint(v.job) == UNION_JOB_TYPE.VICE_PRESIDENT then
                v.sortIndex = SORT_INDEX.NOT_ONLINE_VICE_PRESIDENT
            elseif  checkint(v.job) == UNION_JOB_TYPE.COMMON then
                v.sortIndex = SORT_INDEX.NOT_ONLINE_COMMON
            end
            v.lineName =  CommonUtils.GetSeverIntervalTextByTime(currentTime ,currentTime -  v.lastExitTime)
        end
        v.job = v.job or UNION_JOB_TYPE.COMMON
        v.jobName = jobData[tostring(v.job)].name
    end
     table.sort(member , function (a , b )
         if a.sortIndex >  b.sortIndex then
             return false
         elseif a.sortIndex == b.sortIndex then
             if a.contributionPoint <=  b.contributionPoint then
                return false
             end
         end
         return true
    end)
    return member
end
--[[
    获取头像的名称
--]]
function UnionInforDetailMediator:GetTitleName(contributionPoint)
    local name = ""
    local countNum = table.nums(JobTitleDataConfig)
    for i =1, countNum do
        name =  JobTitleDataConfig[tostring(i)].name
        if contributionPoint <   checkint( JobTitleDataConfig[tostring(i)].contributionPoint)  then
            name  =  JobTitleDataConfig[tostring(i-1)].name
            break
        elseif i == countNum then
            name  =  JobTitleDataConfig[tostring(i)].name
        end
    end
    return name
end
--[[
    更新cell 的状态
--]]
function UnionInforDetailMediator:UpdateSelectCell()
    local index = self.preIndex
    self.preIndex = nil
    if index then
        local cell = self.viewData.gridView:cellAtIndex( index  -1)
        if cell and ( not tolua.isnull(cell)) then
            local data = self.memberList[index]
            if checkint(data.playerId) == checkint( gameMgr:GetUserInfo().playerId) then
                cell.bgImage:setTexture(_res('ui/union/guild_member_me_bg'))
            else
                cell.bgImage:setTexture(_res('ui/union/guild_member_bg'))
            end
        end

    end
end
function UnionInforDetailMediator:OnDataSource(cell , idx)
    local pcell  = cell
    local index  = idx  +1

    if index >=1 and index <= self.gradeCellCount then
        local data = self.memberList[index]
        if not pcell then
            pcell = self.viewComponent:CreateGridCell()
        end
        pcell.bgLayout:setTag(index)
        pcell.bgLayout:setOnClickScriptHandler(handler(self, self.CellButtonClick))
        data.playerAvatarFrame = CommonUtils.GetAvatarFrame(data.playerAvatarFrame)
        pcell.headerNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(data.playerAvatarFrame))
        pcell.headerNode.headerSprite:setTexture(CommonUtils.GetGoodsIconPathById(data.playerAvatar or '500058'))
        display.commonLabelParams(pcell.playerName, { text = data.playerName or "" })
        display.commonLabelParams(pcell.playerLevel, { text =  string.format(__('%d级' ) , checkint(data.playerLevel) ) })
        display.commonLabelParams(pcell.isOnlineLable, { text = data.lineName or "" } )
        display.commonLabelParams(pcell.playerJob, { text = data.jobName or "" } )
        if checkint(data.playerId) == checkint( gameMgr:GetUserInfo().playerId) then
            pcell.bgImage:setTexture(_res('ui/union/guild_member_me_bg'))
        elseif self.preIndex ==  index then
            pcell.bgImage:setTexture(_res('ui/union/guild_member_bg_select'))
        else
            pcell.bgImage:setTexture(_res('ui/union/guild_member_bg'))
        end
        if self.cellShowType == 1 then
            display.commonLabelParams(pcell.contributionTitle, { text =  data.contributionPoint or ""} )
        elseif  self.cellShowType == 2 then
            if not   data.titleName then
                data.titleName = self:GetTitleName( checkint(data.contributionPoint))
            end
            display.commonLabelParams(pcell.contributionTitle, { text = data.titleName or ""} )
        end
    end
    return pcell
end
--[[
    执行cell 的事件
--]]
function UnionInforDetailMediator:CellButtonClick(sender)
    PlayAudioByClickNormal()
    local tag  = sender:getTag()
    self.preIndex = tag
    local index = self.preIndex
    if self.memberList[tag] then
        local playerId = self.memberList[tag].playerId
        if checkint(playerId ) == checkint( gameMgr:GetUserInfo().playerId) then
            uiMgr:ShowInformationTips(__('这个工会成员是您自己'))
            return
        end
        local jobType = unionMgr:GetMyselfInUnionJob()
        local popType = HeadPopupType.UNION_MEMBER
        if  jobType == UNION_JOB_TYPE.PRESIDENT then
            popType = HeadPopupType.UNION_PRESIDENT
        elseif jobType == UNION_JOB_TYPE.VICE_PRESIDENT then
            popType = HeadPopupType.UNION_VICE_PRESIDENT
        elseif jobType == UNION_JOB_TYPE.COMMON then
            popType = HeadPopupType.UNION_MEMBER
        end
        local cell = self.viewData.gridView:cellAtIndex( index  -1)
        if cell and ( not tolua.isnull(cell)) then

            local data = self.memberList[index]
            if checkint(data.playerId) == checkint( gameMgr:GetUserInfo().playerId) then
                cell.bgImage:setTexture(_res('ui/union/guild_member_me_bg'))
            else
                cell.bgImage:setTexture(_res('ui/union/guild_member_bg_select'))
            end
        end
        if playerId then
            uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = playerId, type = popType, friendId = playerId})
        end
    end
end

--[[
    获取成员的上限
--]]
function UnionInforDetailMediator:GetUnionMemberLimit()
    local unionUpgradeData = CommonUtils.GetConfigAllMess('level' , 'union')
    local count = 0
    local data = unionUpgradeData[tostring(unionMgr:getUnionData().level)]
    for k ,v in pairs(data.job or {}) do
        count =count + checkint(v)
    end
    return count
end
--[[
    获取到下一个等级的工会积分
--]]
function UnionInforDetailMediator:GetNextLevelContributionPoint()
    local nowLevel =  unionMgr:getUnionData().level
    local nextLevel = nowLevel + 1
    local unionUpgradeOneData = UnionUpgradeData[tostring(nextLevel)]
    if unionUpgradeOneData then
        return checkint(unionUpgradeOneData.contributionPoint)
    else
        unionUpgradeOneData = UnionUpgradeData[tostring(nowLevel)]
        if unionUpgradeOneData then
            return checkint(unionUpgradeOneData.contributionPoint)
        end
    end
    return 0
end
function UnionInforDetailMediator:UpdateLeftView()
    local data =  unionMgr:getUnionData() or {}
    local name = data.name or ""
    local level = data.level or 1
    local sign = data.unionSign or ""
    local avatar = data.avatar or ""
    -- TODO  这脸面的接收值会修改
    local exp = unionMgr:GetCurrentLevelExp(level ,data.contributionPoint )  or ""

    local expTwo = self:GetNextLevelContributionPoint()
    local contributionPoint = data.contributionPoint or ""

    local ownerNum = table.nums(data.member)
    --local limitCount = self:GetUnionMemberLimit()
    display.reloadRichLabel(self.viewData.unionLevel,
         {
             c = {
               fontWithColor('8', {text = __('工会等级:'), color = "#a74700"}) ,
               fontWithColor('8', {text = string.format(__('%d级') , checkint(level)) }) ,
               fontWithColor('10', {text = string.format('(%d/%d)' , checkint(exp) , checkint(expTwo) ) }) ,
             }
         }
    )
    display.reloadRichLabel(self.viewData.unionContriBution,
                         {
                             c = {
                                 fontWithColor('8', {text = __('工会贡献:') , color = "#a74700"}) ,
                                 fontWithColor('8',  {text = contributionPoint }) ,
                             }
                         }
    )
    display.reloadRichLabel(self.viewData.unionNum,
                         {
                             c = {
                                 fontWithColor('8', {text = __('工会人数:' ) , color = "#a74700"} ) ,
                                 fontWithColor('8',  {text = string.format("%d/%d" ,ownerNum ,  unionMgr:GetUnionMemberLimitNumByLevel(data.level)) })
                             }
                         }
    )
    display.reloadRichLabel(self.viewData.unionNameLabel ,
                                 { c= {
                                     fontWithColor('10' , {text = name  or ""  ,fontSize = 24 , color = "#a74700"})
                                 } })
    display.reloadRichLabel(self.viewData.decLabel, { c = CommonUtils.dealWithEmoji(fontWithColor('6' ),sign or "") })
    display.commonLabelParams(self.viewData.unionIdLabel ,
        {text = string.format(__('工会ID:%d') , checkint(gameMgr:GetUserInfo().unionId))})
    self.viewData.headImage:setTexture(CommonUtils.GetGoodsIconPathById(avatar))
end
--[[
    更新右边的视图
--]]
function UnionInforDetailMediator:UpdateRightView(onlineNum)
    self:ReloadDataGrideView()
    display.commonUIParams(self.viewData.switchBtn ,{ cb = handler(self, self.ButtonAction) , animate = true  })
    display.commonLabelParams(self.viewData.onLineNum, {text = string.format("(%d/%d)" ,
         checkint(onlineNum) , self.gradeCellCount)} )
end

--[[
    修改工会名字
--]]
function UnionInforDetailMediator:ChangeUnionName(name)
    CommonUtils.DrawRewards({{goodsId =  DIAMOND_ID , num =  - CHANGE_UNION_NAME_NEED_DIAMON  } } )
    unionMgr:getUnionData().name = name
    display.reloadRichLabel(self.viewData.unionNameLabel , { c = {  fontWithColor('10' ,{text = name   or "" ,color = "#a74700"} )}} )
    uiMgr:ShowInformationTips(__('工会昵称修改成功'))
end
--[[
    修改工会签名
--]]
function UnionInforDetailMediator:ChangeUnionSign(name)
    unionMgr:getUnionData().unionSign = name
    display.reloadRichLabel(self.viewData.decLabel, { c = CommonUtils.dealWithEmoji({ color = "#5c5c5c" } ,  name )})
    self.viewData.changeLabelContent:setVisible(true)
    self.viewData.changeLabelContent:setTouchEnabled(true)
    self.viewData.decLabel:setVisible(true)
    uiMgr:ShowInformationTips(__('工会宣言修改成功'))
end
--[[
    修改工会头像
--]]
function UnionInforDetailMediator:ChangeUnionAvatar(avatar)
    unionMgr:getUnionData().avatar =  avatar
    local iconPath = CommonUtils.GetGoodsIconPathById(avatar)
    self.viewData.headImage:setTexture(iconPath)
    uiMgr:ShowInformationTips(__('工会图标修改成功'))
end


function UnionInforDetailMediator:EnterLayer()
    self:SendSignal(POST.UNION_MEMBER.cmdName,{})
end
function UnionInforDetailMediator:OnRegist()
    regPost(POST.UNION_MEMBER)
    regPost(POST.UNION_CHANGEINFO , true )
    regPost(POST.UNION_QUIT)
    regPost(POST.UNION_ASSIGNJOB)
    regPost(POST.UNION_KICKOUT)

    self:EnterLayer()
end

function UnionInforDetailMediator:OnUnRegist()
    unregPost(POST.UNION_MEMBER)
    unregPost(POST.UNION_CHANGEINFO)
    unregPost(POST.UNION_QUIT)
    unregPost(POST.UNION_ASSIGNJOB)
    unregPost(POST.UNION_KICKOUT)
    if self.viewComponent and ( not tolua.isnull(self.viewComponent)) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return UnionInforDetailMediator



