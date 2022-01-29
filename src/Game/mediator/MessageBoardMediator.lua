---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---

local Mediator = mvc.Mediator
---@class MessageBoardMediator :Mediator
local MessageBoardMediator = class("MessageBoardMediator", Mediator)
local NAME = "MessageBoardMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local  BUTTON_CLICK = {
    LEAEAL_WORDS = 1101  , -- 留言
    EDIT_MESSAGE = 1102  , -- 编辑留言
    DELETE_MESSAGE = 1103  , -- 删除留言
}
function MessageBoardMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.data = param or {}
    self.preIndex = nil  -- 上一次点击
    self.messageBoard = self.data.messageBoard
    self.messageStr = ""    -- 留言的内容
    self.isShowDelete =  checkint(gameMgr:GetUserInfo().playerId)  ==  checkint(self.data.playerId)  -- 是否显示删除留言按钮
end
-- 按照创建的时间由大到小排序
function MessageBoardMediator:SortMessageByCreateTime()

    if table.nums(self.messageBoard) > 0 then  -- 如果留言板的内容大于零
        table.sort(self.messageBoard , function (a, b )
            local isTrue = false
            a.createTime = a.createTime or ""
            b.createTime = b.createTime or ""
            if  a.createTime  >=  b.createTime   then
                isTrue = false
            else
                isTrue = true
            end
            return isTrue
        end)
    end
end

function MessageBoardMediator:InterestSignals()
    local signals = {
        POST.PERSON_DELETE_MESSAGE.sglName , -- 删除留言
        POST.PERSON_LEAVE_MESSAGE.sglName ,  -- 留言
        POST.PLAYER_PERSON_INFO_MESSAGE.sglName ,  -- 留言
        REFRESH_MESSAGE_BOARD_EVENT ,
        FRIEND_REFRESH_EDITBOX
    }
    return signals
end
function MessageBoardMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type MessageBoardView
    self.viewComponent = require('Game.views.MessageBoardView').new()
    self:SetViewComponent(self.viewComponent)
    local viewData = self.viewComponent.viewData
    self:SortMessageByCreateTime()
    for k ,v in pairs(self.messageBoard or {}) do
        v.messagePlayerAvatarFrame = CommonUtils.GetAvatarFrame(v.messagePlayerAvatarFrame)
    end
    viewData.sendMessage:setOnClickScriptHandler(handler(self ,self.ButtonAction))
    if table.nums(self.messageBoard) ~=  0 then
        if self.isShowDelete then
            viewData.gridView:setCountOfCell(table.nums(self.messageBoard)+1)
        else
            viewData.gridView:setCountOfCell(table.nums(self.messageBoard))
        end
        viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.onMakeDataSourceAction))
        viewData.gridView:reloadData()
        viewData.gridView:setContentOffsetToBottom()
    else
        -- 没有信息就显示richlabel
        local richLabel = self.viewComponent:CreateNoLeaveWords()
        viewData.bgLayout:addChild(richLabel)
        local bgSize =  viewData.bgLayout:getContentSize()
        richLabel:setPosition(cc.p(bgSize.width/2 , bgSize.height/2 + 100))
        richLabel:setName("richLabel")
    end
    viewData.editorMessageText:registerScriptEditBoxHandler(function(eventType,sender)
        if eventType == 'began' then  -- 输入开始
        elseif eventType == 'ended' then  -- 输入结束
             self:ButtonAction(sender)
        elseif eventType == 'changed' then  -- 内容变化
        elseif eventType == 'return' then  -- 从输入返回
            self:ButtonAction(sender)
        end
    end)
    --防止视图释放
    self.viewComponent:retain()
end

function MessageBoardMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.PERSON_LEAVE_MESSAGE.sglName then -- 留言的回调
        local requestData = data.requestData -- 请求的数据
        local message = requestData.message   --
        local data = {    -- 构造显示的数据
            messagePlayerId = gameMgr:GetUserInfo().playerId ,
            messagePlayerAvatar = gameMgr:GetUserInfo().avatar ,
            messagePlayerAvatarFrame  = gameMgr:GetUserInfo().avatarFrame ,
            messagePlayerName  = gameMgr:GetUserInfo().playerName ,
            message  = message ,
            id = data.messageId,
            createTime = data.createTime  or data.createTme
        }
        data.messagePlayerAvatarFrame = CommonUtils.GetAvatarFrame(data.messagePlayerAvatarFrame)
        table.insert(self.messageBoard , #self.messageBoard+1 , data)
        self:SortMessageByCreateTime()
        local viewData = self.viewComponent.viewData
        viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.onMakeDataSourceAction))
        if self.isShowDelete then
            viewData.gridView:setCountOfCell(table.nums(self.messageBoard)+1)
        else
            viewData.gridView:setCountOfCell(table.nums(self.messageBoard))
        end
        viewData.gridView:reloadData()
        viewData.gridView:setContentOffsetToBottom()
        local richLabel =   viewData.bgLayout:getChildByName("richLabel")
        if richLabel and ( not tolua.isnull(richLabel)) then
            richLabel:setVisible(false)
        end
    elseif name == POST.PLAYER_PERSON_INFO_MESSAGE.sglName then -- 重新拉取个人信息的数据
        self.messageBoard = data.messageBoard or {}
        self:SortMessageByCreateTime()
        local viewData = self.viewComponent.viewData
        viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.onMakeDataSourceAction))
        if table.nums(self.messageBoard) <=0  then
            local richLabel =   viewData.bgLayout:getChildByName("richLabel")
            if richLabel and ( not tolua.isnull(richLabel)) then
                richLabel:setVisible(true )
            else
                local richLabel = self.viewComponent:CreateNoLeaveWords()
                viewData.bgLayout:addChild(richLabel)
                local bgSize =  viewData.bgLayout:getContentSize()
                richLabel:setPosition(cc.p(bgSize.width/2 , bgSize.height/2 + 100))
                richLabel:setName("richLabel")
            end
        else
            local richLabel =   viewData.bgLayout:getChildByName("richLabel")
            if richLabel and ( not tolua.isnull(richLabel)) then
                richLabel:setVisible(false)
            end
        end
        if self.isShowDelete then
            if table.nums(self.messageBoard) > 0  then
                viewData.gridView:setCountOfCell(table.nums(self.messageBoard)+1)
            else
                viewData.gridView:setCountOfCell(table.nums(self.messageBoard))
            end
        else
            viewData.gridView:setCountOfCell(table.nums(self.messageBoard))
        end
        viewData.gridView:reloadData()
        viewData.gridView:setContentOffsetToBottom()
    elseif name == POST.PERSON_DELETE_MESSAGE.sglName then -- 删除留言
        local requestData = data.requestData -- 请求的数据
        local messageId = checkint(data.messageId)
        if messageId == 0  then
            self:SendSignal(POST.PLAYER_PERSON_INFO_MESSAGE.cmdName , {personalPlayerId = app.gameMgr:GetUserInfo().playerId})
        else
            local viewData = self.viewComponent.viewData
            local gridContentOffset = viewData.gridView:getContentOffset()
            for i, v in pairs(self.messageBoard) do
                if tostring(v.id)  == tostring(requestData.messageId)  then
                    table.remove(self.messageBoard , i)
                    if table.nums(self.messageBoard) > 0  then
                        viewData.gridView:setCountOfCell(table.nums(self.messageBoard)+1)
                    else
                        viewData.gridView:setCountOfCell(table.nums(self.messageBoard))
                    end
                    viewData.gridView:reloadData()
                    -- 找到了就直接退出
                    break
                end
            end
            if table.nums(self.messageBoard) <=0  then
                local richLabel =   viewData.bgLayout:getChildByName("richLabel")
                if richLabel and ( not tolua.isnull(richLabel)) then
                    richLabel:setVisible(true )
                else
                    local richLabel = self.viewComponent:CreateNoLeaveWords()
                    viewData.bgLayout:addChild(richLabel)
                    local bgSize =  viewData.bgLayout:getContentSize()
                    richLabel:setPosition(cc.p(bgSize.width/2 , bgSize.height/2 + 100))
                    richLabel:setName("richLabel")
                end
            end

            if gridContentOffset.y >= viewData.gridView:getMinOffset().y then
                viewData.gridView:setContentOffset(gridContentOffset)
            else
                gridContentOffset = viewData.gridView:getContentOffset()
                viewData.gridView:setContentOffsetToTop()
            end
        end

    elseif name == REFRESH_MESSAGE_BOARD_EVENT then
        if self.isShowDelete and table.nums(data) > 0  then
            data.messagePlayerAvatarFrame = CommonUtils.GetAvatarFrame(data.messagePlayerAvatarFrame)
            table.insert(self.messageBoard , #self.messageBoard+1 , data)
            self:SortMessageByCreateTime()
            local viewData = self.viewComponent.viewData
            viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.onMakeDataSourceAction))
            if table.nums(self.messageBoard) > 0   then
                viewData.gridView:setCountOfCell(table.nums(self.messageBoard)+1)
            else
                viewData.gridView:setCountOfCell(table.nums(self.messageBoard))
            end
            viewData.gridView:reloadData()
            viewData.gridView:setContentOffsetToBottom()
            local richLabel =   viewData.bgLayout:getChildByName("richLabel")
            if richLabel and ( not tolua.isnull(richLabel)) then
                richLabel:setVisible(false)
            end
        end
    elseif name == FRIEND_REFRESH_EDITBOX then
        if data.tag == DISABLE_EDITBOX_MEDIATOR.PERSON_DETAIL_TAG then
            local viewData = self.viewComponent.viewData
            if data.isEnabled then
                viewData.editorMessageText:setVisible(true)
            else
                viewData.editorMessageText:setVisible(false)
            end
        end
    end

end

function MessageBoardMediator:ButtonAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == BUTTON_CLICK.LEAEAL_WORDS then  -- 留言
        if self.messageStr and  self.messageStr ~= "" then
            if not CommonUtils.CheckIsDisableInputDay() then
                -- 留言
                self:SendSignal(POST.PERSON_LEAVE_MESSAGE.cmdName ,{ messagePlayerId =  self.data.playerId , message   = tostring(self.messageStr)})
                self.messageStr = ""
                self.viewComponent.viewData.editorMessageText:setText("")
            end
        else
            uiMgr:ShowInformationTips(__('请输入留言'))
        end
    elseif tag == BUTTON_CLICK.EDIT_MESSAGE then -- 编辑留言
        local str = sender:getText()
        str = utf8sub(str ,1, 40)
        sender:setText(str)
        self.messageStr = str
    elseif tag == BUTTON_CLICK.DELETE_MESSAGE then -- 删除留言
        local parentNode = sender:getParent() -- 获取到父节点定义父节点的顺序
        local index = parentNode:getTag()
        local data = self.messageBoard[index]
        if data and data.id then
            self:SendSignal(POST.PERSON_DELETE_MESSAGE.cmdName ,{ messageId = tostring(data.id) , messageTime = data.createTime})
        end
    end

end
-- 跳入到其他玩家的内部
function MessageBoardMediator:JumpToOtherPlayersInfor(sender)
    local index = sender:getTag()
    local playerId = self.messageBoard[index].messagePlayerId
    if checkint(gameMgr:GetUserInfo().playerId)  ==  checkint(playerId) then
        uiMgr:ShowInformationTips(__('这是您自己的留言'))
    else
        AppFacade.GetInstance():UnRegsitMediator("PersonInformationMediator")
        local mediator = require("Game.mediator.PersonInformationMediator").new({playerId = playerId  })
        AppFacade.GetInstance():RegistMediator(mediator)
    end
end

function MessageBoardMediator:onMakeDataSourceAction(p_convertview , idx )
    local pCell = p_convertview
    local index = checkint(idx)  + 1
    local sizee = cc.size(589, 98)
    if pCell == nil then
        -- 创建cell 的对象
        local callback = handler(self, self.JumpToOtherPlayersInfor)
        pCell = self.viewComponent:CreatGridCell( callback)
        pCell.deleteMessage:setOnClickScriptHandler(handler(self,self.ButtonAction))
        pCell.deleteMessage:setTag(BUTTON_CLICK.DELETE_MESSAGE)
        pCell.delAllButton:setOnClickScriptHandler(handler(self,self.DeleteAllMessage))
    else
        pCell.gridLayout:setPosition(cc.p(sizee.width * 0.5, sizee.height * 0.5))
    end
    xTry(function()
        if index > #self.messageBoard then
            pCell.gridLayout:setVisible(false)
            pCell.allDeletMessage:setVisible(true)
        else
            pCell.allDeletMessage:setVisible(false)
            pCell.gridLayout:setVisible(true)
            local mod = index % 2
            -- 交叉设置背景图片
            if mod == 0  then
                pCell.bgImage:setTexture(_res('ui/home/infor/personal_information_reply_bg_1.png'))
            else
                pCell.bgImage:setTexture(_res('ui/home/infor/personal_information_reply_bg_2.png'))
            end
            pCell.headerNode.headerSprite:setTexture(CommonUtils.GetGoodsIconPathById(self.messageBoard[index].messagePlayerAvatar))
            self.messageBoard[index].messagePlayerAvatarFrame = CommonUtils.GetAvatarFrame(self.messageBoard[index].messagePlayerAvatarFrame)
            pCell.headerNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(self.messageBoard[index].messagePlayerAvatarFrame ))
            pCell.headerNode.preBg:setTag(index)
            pCell.headerNode.bg:setTag(index)
            pCell.deleteMessage:setOnClickScriptHandler(handler(self,self.ButtonAction))
            pCell.gridLayout:setTag(index)
            pCell.playerName:setString(self.messageBoard[index].messagePlayerName)
            pCell.leaveWordsLabel:setVisible(true)
            self.messageBoard[index].message =  self.messageBoard[index].message or "  "
            display.reloadRichLabel(pCell.leaveWordsLabel , { c = CommonUtils.dealWithEmoji(fontWithColor('6') , self.messageBoard[index].message)})
            pCell.deleteMessage:setVisible(self.isShowDelete)
            -- 删除个人信息
            pCell:setTag(BUTTON_CLICK.DELETE_MESSAGE)
        end

    end, __G__TRACKBACK__)

    return pCell
end
-- 一键删除留言
function MessageBoardMediator:DeleteAllMessage()
    if table.nums(self.messageBoard) > 0   then
        local commonTip = require("common.CommonTip").new({text = __("是否确认一键清空当前所有留言内容？") , callback = function()
            local messageId = 0
            local messageTime = nil
            for i, v in pairs(self.messageBoard) do
                if not  messageTime then
                    messageTime = v.createTime
                else
                    messageTime = v.createTime < messageTime and v.createTime or messageTime
                end
            end
            self:SendSignal(POST.PERSON_DELETE_MESSAGE.cmdName , { messageId = messageId , messageTime = messageTime })
        end})
        commonTip:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(commonTip)
    else
        app.uiMgr:ShowInformationTips(__('暂无留言'))
    end
end
function MessageBoardMediator:OnRegist()
    regPost(POST.PERSON_LEAVE_MESSAGE)
    regPost(POST.PERSON_DELETE_MESSAGE)
    regPost(POST.PLAYER_PERSON_INFO_MESSAGE)
end

function MessageBoardMediator:OnUnRegist()
    unregPost(POST.PERSON_LEAVE_MESSAGE)
    unregPost(POST.PERSON_DELETE_MESSAGE)
    unregPost(POST.PLAYER_PERSON_INFO_MESSAGE)
end

return MessageBoardMediator



