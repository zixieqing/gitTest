--[[
 * author : liuzhipeng
 * descpt : 猫屋 好友邀请Mediator
--]]
local CatHouseBreedInviteMediator = class('CatHouseBreedInviteMediator', mvc.Mediator)
local NAME = 'catHouse.CatHouseBreedInviteMediator'

-------------------------------------------------
------------------ inheritance ------------------
--[[
@params map {
    catModel houseCatModel 猫咪组件
}
--]]
function CatHouseBreedInviteMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.checkboxSelected = {}
    self:SetCatModel(params.catModel)
end

function CatHouseBreedInviteMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.catHouse.CatHouseBreedInviteView').new()
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData

    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.inviteBtn:setOnClickScriptHandler(handler(self, self.InviteButtonCallback))
    viewData.checkAllBtn:setOnClickScriptHandler(handler(self, self.CheckAllButtonCallback))
    viewData.friendListView:setCellUpdateHandler(handler(self, self.OnUpdateListCellHandler))
    viewData.friendListView:setCellInitHandler(handler(self, self.OnInitListCellHandler))
end
    
function CatHouseBreedInviteMediator:InterestSignals()
    local signals = {
        POST.FRIEND_HOME.sglName,
        POST.HOUSE_CAT_MATING_INVITE.sglName,
    }
    return signals
end
function CatHouseBreedInviteMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.FRIEND_HOME.sglName then
        app.gameMgr:GetUserInfo().friendList = body.friendList
        self:SetFriendData(body.friendList)
        self:InitView()
    elseif name == POST.HOUSE_CAT_MATING_INVITE.sglName then
        local friendIds = json.decode(body.requestData.friendIds)
        local catModel = self:GetCatModel()
        for i, v in ipairs(friendIds) do
            catModel:addMatingInvite(v)
        end
        app:DispatchObservers(SGL.CAT_HOUSE_BREED_INVITE_SUCCESS)
        app:UnRegsitMediator(NAME)
    end
end

function CatHouseBreedInviteMediator:OnRegist()
    regPost(POST.FRIEND_HOME)
    regPost(POST.HOUSE_CAT_MATING_INVITE)
    self:EnterLayer()
end
function CatHouseBreedInviteMediator:OnUnRegist()
    unregPost(POST.FRIEND_HOME)
    unregPost(POST.HOUSE_CAT_MATING_INVITE)
end

function CatHouseBreedInviteMediator:CleanupView()
    -- 移除界面
    if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
        self:GetViewComponent():removeFromParent()
        self:SetViewComponent(nil)
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function CatHouseBreedInviteMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
--[[
邀请按钮点击回调
--]]
function CatHouseBreedInviteMediator:InviteButtonCallback( sender )
    PlayAudioByClickNormal()
    local checkboxSelected = self.checkboxSelected
    local friendIds = {}
    for k, v in pairs(checkboxSelected) do
        if v then
            table.insert(friendIds, k)
        end
    end
    if next(friendIds) == nil then
        app.uiMgr:ShowInformationTips(__('请选择好友'))
        return
    end
    friendIds = json.encode(friendIds)
    self:SendSignal(POST.HOUSE_CAT_MATING_INVITE.cmdName, {playerCatId = self:GetCatModel():getPlayerCatId(), friendIds = friendIds})
end
--[[
全选按钮点击回调
--]]
function CatHouseBreedInviteMediator:CheckAllButtonCallback( sender )
    PlayAudioByClickNormal()
    self:CheckBoxClickAction()
end
--[[
好友列表刷新
--]]
function CatHouseBreedInviteMediator:OnUpdateListCellHandler( cellIndex, cellViewData )
    cellViewData.checkbox:setTag(cellIndex)
    local friendData = self:GetFriendData()[cellIndex]
    local inviteData = self:GetCatModel():getMatingInviteMap()
    cellViewData.nameLabel:setString(friendData.name)
    cellViewData.levelLabel:setString(string.fmt(__('猫屋等级:_num_'), {['_num_'] = friendData.houseLevel}))
    cellViewData.headerButton.headerSprite:setWebURL(friendData.avatar)
    cellViewData.headerButton:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame(friendData.avatarFrame or '')))
    if inviteData[tostring(friendData.friendId)] then
        -- 已邀请
        cellViewData.checkbox:setVisible(false)
        cellViewData.invitedLabel:setVisible(true)
    else
        -- 未邀请
        cellViewData.checkbox:setVisible(true)
        cellViewData.invitedLabel:setVisible(false)
        cellViewData.checkbox:setChecked(self.checkboxSelected[checkint(friendData.friendId)])
    end
end
--[[
好友列表cell初始化
--]]
function CatHouseBreedInviteMediator:OnInitListCellHandler( cellViewData )
    cellViewData.checkbox:setOnClickScriptHandler(handler(self, self.ListCellCheckboxCallback))
end
--[[
cell复选框点击回调
--]]
function CatHouseBreedInviteMediator:ListCellCheckboxCallback( sender )
    PlayAudioByClickNormal()
    local index = sender:getTag()
    self:CheckBoxClickAction(index)
    
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function CatHouseBreedInviteMediator:InitView()
    local friendData = self:GetFriendData()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    viewData.friendListView:resetCellCount(#friendData)
    viewComponent:UpdateFriendAmountLabel(friendData)
end
--[[
进入页面
--]]
function CatHouseBreedInviteMediator:EnterLayer()
    self:SendSignal(POST.FRIEND_HOME.cmdName)
end
--[[
复选框点击事件
@params index 选中cell的index，如果为空则为选中全部
--]]
function CatHouseBreedInviteMediator:CheckBoxClickAction( index )
    local friendData = self:GetFriendData()
    local inviteData = self:GetCatModel():getMatingInviteMap()
    if index then
        local friendId = friendData[index].friendId
        if not inviteData[tostring(friendId)] then 
            self.checkboxSelected[checkint(friendId)] = not self.checkboxSelected[checkint(friendId)]
        end
        return 
    end
    -- 全选
    for i, v in ipairs(friendData) do
        if not inviteData[tostring(v.friendId)] then
            self.checkboxSelected[checkint(v.friendId)] = true
        end
        local viewData = self:GetViewComponent():GetViewData()
        local friendListView = viewData.friendListView
        if friendListView:cellAtIndex(i-1) then
            local checkbox = friendListView:cellAtIndex(i-1):getChildByName('checkbox')
            checkbox:setChecked(true)
        end
    end
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置friendData
--]]
function CatHouseBreedInviteMediator:SetFriendData( friendData )
    self.friendData = friendData
end
--[[
获取friendData
--]]
function CatHouseBreedInviteMediator:GetFriendData()
    return self.friendData
end
--[[
设置catModel
--]]
function CatHouseBreedInviteMediator:SetCatModel( catModel )
    self.catModel = catModel
end
--[[
获取邀请数据
--]]
function CatHouseBreedInviteMediator:GetCatModel()
    return self.catModel
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedInviteMediator