--[[
包厢纪念品mediator    
--]]
local Mediator = mvc.Mediator
local PrivateRoomSouvenirMediator = class("PrivateRoomSouvenirMediator", Mediator)
local NAME = "privateRoom.PrivateRoomSouvenirMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local PrivateRoomSouvenirCell = require('Game.views.privateRoom.PrivateRoomSouvenirCell')
function PrivateRoomSouvenirMediator:ctor( params, viewComponent )
    local data = params or {}
    self.super:ctor(NAME, viewComponent)
    self.giftData = CommonUtils.GetConfigAllMess('guestGift', 'privateRoom')
    self.newWallData = {} -- 当前陈列墙状态
    self.selectedSouvenir = nil -- 已选中的陈列品
    self.selectedCellIdx = nil -- 已选中的列表cell
end

function PrivateRoomSouvenirMediator:InterestSignals()
	local signals = {
        POST.PRIVATE_ROOM_DECORATION_SWITCH.sglName,
	}
	return signals
end

function PrivateRoomSouvenirMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	local data = checktable(signal:GetBody())
    if name == POST.PRIVATE_ROOM_DECORATION_SWITCH.sglName then -- 更换纪念品
        app.privateRoomMgr:SetWallData(self.newWallData)
        uiMgr:ShowInformationTips(__('纪念品更改成功'))
        self:BackAction()
	end
end

function PrivateRoomSouvenirMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建CarnieCapsulePoolView
	local viewComponent = require( 'Game.views.privateRoom.PrivateRoomSouvenirView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(viewComponent)
    viewComponent.viewData.wallView:SetSouvenirNodeOnClick(handler(self, self.SouvenirCallback))
    viewComponent.viewData.buffBtn:setOnClickScriptHandler(handler(self, self.BuffButtonCallback))
    viewComponent.viewData.okBtn:setOnClickScriptHandler(handler(self, self.OKButtonCallback))
    viewComponent.viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackBtnCallback))
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackBtnCallback))
    viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataSource))
    self:InitView()
end
--[[
初始化页面
--]]
function PrivateRoomSouvenirMediator:InitView()
    local viewData = self:GetViewComponent().viewData
    local wallData = app.privateRoomMgr:GetWallData()
    local giftConf = app.privateRoomMgr:GetGiftConf()
    self.giftConf = giftConf
    -- 初始化当前陈列墙的状态
    self.newWallData = clone(wallData)
    self.selectedSouvenir = self.GetDefaultSouvenirSelected()
    self:GetViewComponent():RefreshWall(wallData) 
    if self.selectedSouvenir then
        self:SelectedSouvenirNode(self.selectedSouvenir)
    end
    -- 初始化详情页面
    self:GetViewComponent():SetGridViewCellCount(#giftConf)
    local count = self:GetSouvenirShowCount()
    self:GetViewComponent():SetSouvenirShowCount(count)
end
--[[
纪念品点击回调
--]]
function PrivateRoomSouvenirMediator:SouvenirCallback( sender )
    local tag = sender:getTag()
    if tag == self.selectedSouvenir then return end
	PlayAudioByClickNormal()
    self:SelectedSouvenirNode(tag)
    self.selectedSouvenir = tag
end
--[[
查看buff按钮点击回调
--]]
function PrivateRoomSouvenirMediator:BuffButtonCallback( sender )
    PlayAudioByClickNormal()
    uiMgr:AddDialog("Game.views.privateRoom.PrivateRoomSouvenirBuffPopup", {wallData = self.newWallData})
end
--[[
确认按钮点击回调
--]]
function PrivateRoomSouvenirMediator:OKButtonCallback( sender )
    PlayAudioByClickNormal()
    if self:IsSouvenirChanged() then
        self:SendSignal(POST.PRIVATE_ROOM_DECORATION_SWITCH.cmdName, {decorations = json.encode(self.newWallData)})
    else
        self:BackAction()
    end
end
--[[
纪念品列表处理
--]]
function PrivateRoomSouvenirMediator:GridViewDataSource( p_convertview, idx ) 
	local pCell = p_convertview
    local index = idx + 1
	local cSize = self:GetViewComponent():GetGridViewCellSize()

    if pCell == nil then
        pCell = PrivateRoomSouvenirCell.new(cSize)
        pCell.goodsBg:setOnClickScriptHandler(handler(self, self.GridViewCellCallback))
    end
    xTry(function()	
        local giftConf = self.giftConf[index]
        pCell:RefreshCell({isSelected = index == self.selectedCellIdx, goodsId = giftConf.id, isShow = self:IsSouvenirShow(giftConf.id), tag = index})
	end,__G__TRACKBACK__)
	return pCell
end
--[[
纪念品列表cell点击回调
--]]
function PrivateRoomSouvenirMediator:GridViewCellCallback( sender )
    local tag = sender:getTag()
    self.selectedCellIdx = tag
    local viewComponent = self:GetViewComponent()
    local goodsId = app.privateRoomMgr:GetGoodsIdByListSouvenirIdx(tag)
    if app.privateRoomMgr:IsHasSouvenirByGoodsId(goodsId) then -- 判断纪念品是否拥有
        if self:IsSouvenirShow(goodsId) then -- 纪念品是否显示
            self:DropSouvenir(goodsId)
        else
            self:ShowSouvenir(goodsId, self.selectedSouvenir)
            self:JumpToEmptyNode()
        end
        viewComponent:RefreshWall(self.newWallData)
    end
    viewComponent:SetSouvenirShowCount(self:GetSouvenirShowCount())
    viewComponent:RefreshView(goodsId)
    viewComponent:ReloadGridView()
end
--[[
判断当前纪念品是否被展示
@params goodsId int 纪念品id
--]]
function PrivateRoomSouvenirMediator:IsSouvenirShow( goodsId )
    local isShow = false
    for k, v in pairs(self.newWallData) do
        if checkint(v) == checkint(goodsId) then
            isShow = true 
            break 
        end
    end
    return isShow
end
--[[
获取默认状态下被选中的纪念品位置
@return id int 纪念品位置id
--]]
function PrivateRoomSouvenirMediator:GetDefaultSouvenirSelected()
    local wallData = app.privateRoomMgr:GetWallData()
    local id = nil
    for i = 1, 10 do
        if wallData[tostring(i)] == '' then
            id = i 
            break
        end
    end
    if id == nil then 
        id = 1
    end
    return id
end
--[[
陈列墙souvenirNode选中
@params id int 纪念品位置id
--]]
function PrivateRoomSouvenirMediator:SelectedSouvenirNode( id )
    local viewComponent = self:GetViewComponent()
    viewComponent:SelectedSouvenirNode(id)
    if self.newWallData[tostring(id)] ~= '' then
        local goodsId = self.newWallData[tostring(id)]
        self.selectedCellIdx = app.privateRoomMgr:GetListSouvenirIdxByGoodsId(goodsId)
        viewComponent:RefreshView(goodsId)
        viewComponent:ReloadGridView()
    end
    self.selectedSouvenir = id
end
--[[
展示纪念品
@params goodsId int 纪念品goodsId
id int 纪念品位置id
--]]
function PrivateRoomSouvenirMediator:ShowSouvenir( goodsId, id )
    self.newWallData[tostring(id)] = goodsId
end
--[[
卸下纪念品
@params goodsId int 纪念品goodsId
--]]
function PrivateRoomSouvenirMediator:DropSouvenir( goodsId )
    for k, v in pairs(self.newWallData) do
        if checkint(v) == checkint(goodsId) then
            self.newWallData[k] = ''
            self:SelectedSouvenirNode(k)
            break
        end
    end
end
--[[
获取显示的纪念品数量
--]]
function PrivateRoomSouvenirMediator:GetSouvenirShowCount()
    local count = 0
    for k, v in pairs(self.newWallData) do
        if v ~= '' then
            count = count + 1
        end
    end
    return count
end
--[[
判断纪念品是否变动
--]]
function PrivateRoomSouvenirMediator:IsSouvenirChanged()
    local wallData = app.privateRoomMgr:GetWallData()
    local isChanged = false 
    for i, v in pairs(wallData) do
        if v ~= self.newWallData[tostring(i)] then
            isChanged = true
        end
    end
    return isChanged
end
--[[
跳转至空位
--]]
function PrivateRoomSouvenirMediator:JumpToEmptyNode()
    local emptyKey = nil 
    for i = 1, 10 do 
        if self.newWallData[tostring(i)] == '' then
            emptyKey = i
            break
        end
    end
    if emptyKey then
        self:SelectedSouvenirNode(emptyKey)
        self.selectedCellIdx = nil
    end
end
--[[
返回按钮回调
--]]
function PrivateRoomSouvenirMediator:BackBtnCallback()
    if self:IsSouvenirChanged() then
		local commonTip = require('common.NewCommonTip').new({
			text = __('是否离开纪念品界面，您做出的改变不会保存。'),
			callback = function ()
				self:BackAction()
			end
		})
		commonTip:setPosition(display.center)
		uiMgr:GetCurrentScene():AddDialog(commonTip)
    else
        self:BackAction()
    end
end
function PrivateRoomSouvenirMediator:BackAction()
	PlayAudioByClickClose()
	AppFacade.GetInstance():UnRegsitMediator("privateRoom.PrivateRoomSouvenirMediator")
end
function PrivateRoomSouvenirMediator:EnterAction()
	local viewComponent = self:GetViewComponent()
	viewComponent.viewData.view:setScale(0.8)
	viewComponent.viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackOut:create(
				cc.ScaleTo:create(0.3, 1)
			)
		)
	)
end
function PrivateRoomSouvenirMediator:OnRegist(  )
    regPost(POST.PRIVATE_ROOM_DECORATION_SWITCH)
    self:EnterAction()
end

function PrivateRoomSouvenirMediator:OnUnRegist(  )
    unregPost(POST.PRIVATE_ROOM_DECORATION_SWITCH)
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self:GetViewComponent())
end
return PrivateRoomSouvenirMediator