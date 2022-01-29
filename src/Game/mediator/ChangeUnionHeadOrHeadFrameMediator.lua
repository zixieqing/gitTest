
---
--- Created by xingweihao.
--- DateTime: 25/10/2017 3:25 PM
---

local Mediator = mvc.Mediator
---@class ChangeUnionHeadOrHeadFrameMediator :Mediator
local ChangeUnionHeadOrHeadFrameMediator = class("ChangeUnionHeadOrHeadFrameMediator", Mediator)
local NAME = "ChangeUnionHeadOrHeadFrameMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local TITLE_NAME  = {
   [tostring(CHANGE_TYPE.CHANGE_UNION_HEAD)]  = __('更换工会图标') ,
}
--[[
    更换工会头像框
    {
        type = 4, -- 更换工会头像
        unionLevel = , -- 工会的等级
        id   = , -- 工会的头像ID

    }
--]]
function ChangeUnionHeadOrHeadFrameMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.data  = param or {} -- 头像的数据
    self.type  = self.data.type or 1
    self.unionLevel = self.data.unionLevel or 1
    self.preIndex = nil
    self.needData = {} -- 需要的数据
end

function ChangeUnionHeadOrHeadFrameMediator:InterestSignals()
    local signals = {
    }
    return signals
end
function ChangeUnionHeadOrHeadFrameMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type ChangeHeadOrHeadFrameView
    self.viewComponent = require('Game.views.ChangeHeadOrHeadFrameView').new(
            {callback = handler(self, self.CloseMeditor)  , title =  TITLE_NAME[tostring(self.type)]})
    self:SetViewComponent(self.viewComponent)
    self.viewComponent:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(self.viewComponent)
    local  viewData_ = self.viewComponent.viewData_
    self.needData = self:GetNeedData()
    if self.data.id then
        for i =1 , #self.needData do
            if checkint(self.needData[i].iconId ) == checkint(self.data.id) then
                self.preIndex = i
                break
            end
        end
    end
    if self.type == CHANGE_TYPE.CHANGE_UNION_HEAD then
        viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataHeadSource))
    end
    viewData_.gridView:setCountOfCell(table.nums(self.needData))
    viewData_.changeBtn:setOnClickScriptHandler(handler(self, self.ChangeBtn))
    viewData_.gridView:reloadData()
end
-- 获取所需的数据 ， 按照顺序排列
function ChangeUnionHeadOrHeadFrameMediator:GetNeedData()
    local needData = {}
    local unionData = CommonUtils.GetConfigAllMess('avatar', 'union')
    for k , v in pairs(unionData) do
        needData[#needData+1] = clone(v)
        needData[#needData].isHave = false
        needData[#needData].sortIndex = 1
        if checkint(self.unionLevel)  >= checkint(v.openLevel)   then  --如果获取了
            needData[#needData].isHave = true
            needData[#needData].sortIndex = 2
        end
    end
    -- 给需要的道具排序
    table.sort( needData , function (a, b )
        local istrue = true
        if a.sortIndex and b.sortIndex  then
            if checkint(a.id) >   checkint(b.id) then
                istrue =  false
            end
        else
            istrue = a.sortIndex > b.sortIndex
        end
        return istrue
    end)
    return needData
end
function ChangeUnionHeadOrHeadFrameMediator:ProcessSignal(signal)

end
-- 刷新头像资源的事件
function ChangeUnionHeadOrHeadFrameMediator:OnDataHeadSource(cell , idx )
    local index = idx +1
    local pcell = cell
    xTry(
        function ()
            if index > 0 and index <= table.nums(self.needData)then  --获取到元素的个数

                local data = self.needData[index]
                local name = data.name
                local isHave = data.isHave
                local id = data.iconId
                local iconPath = CommonUtils.GetGoodsIconPathById(id)
                if pcell == nil then
                    local pcellSize= cc.size(164,190)
                    pcell = CGridViewCell:new()
                    pcell:setContentSize(pcellSize)
                    local pcellLayout = display.newLayer(pcellSize.width/2 ,pcellSize.height/2 ,
                             { ap = display.CENTER, size = pcellSize , color = cc.c4b(0,0,0,0) , enable = true  })
                    pcell:addChild(pcellLayout)
                    pcellLayout:setName("pcellLayout")
                    -- 内容Layout
                    local headBg = display.newImageView( _res('ui/union/guild_head_frame_default') )
                    local headBgSize = headBg:getContentSize()
                    local headBgLayout = display.newLayer(pcellSize.width/2 , pcellSize.height - 5 , { ap = display.CENTER_TOP , size = headBgSize})
                    pcellLayout:addChild(headBgLayout)
                    headBgLayout:setName("headBgLayout")
                    headBg:setPosition(cc.p(headBgSize.width/2 , headBgSize.height/2))
                    headBgLayout:addChild(headBg,2)
                    -- 头像图片
                    local headImage =  FilteredSpriteWithOne:create( _res('ui/union/guild_head_frame_default'))
                    headBgLayout:addChild(headImage)
                    headImage:setPosition(cc.p(headBgSize.width/2 , headBgSize.height/2))
                    headImage:setName("headImage")
                    -- 选中
                    local headSelect =  display.newImageView( _res('ui/union/guild_head_select') , headBgSize.width/2 ,headBgSize.height/2)
                    headBgLayout:addChild(headSelect ,-1)
                    headSelect:setName("headSelect")
                    -- 工会头像名称
                    local headName  = display.newLabel(headBgSize.width/2 , 0 , fontWithColor('6' ,{  ap = display.CENTER_TOP ,  text = name}) )
                    headBgLayout:addChild(headName)
                    headName:setName("headName")
                end
                local pcellLayout = pcell:getChildByName("pcellLayout")
                if pcellLayout then
                    local headBgLayout = pcellLayout:getChildByName("headBgLayout")
                    local headImage  = headBgLayout:getChildByName("headImage")
                    local headSelect = headBgLayout:getChildByName("headSelect")
                    local headName   = headBgLayout:getChildByName("headName")
                    headImage:setTexture(iconPath)
                    self:SetGray( (not isHave) ,headImage )
                    if self.preIndex == index then
                        headSelect:setVisible(true)
                        headSelect:setTouchEnabled(false)
                    else
                        headSelect:setVisible(false)
                        headSelect:setTouchEnabled(true)
                    end
                    headImage:setTexture(CommonUtils.GetGoodsIconPathById(id))
                    display.commonLabelParams(headName, fontWithColor('6' , {fontSize = 20 , text = name ,w = 160, hAlign = display.TAC} ))

                    pcellLayout:setOnClickScriptHandler(handler(self, self.SelectIndexImage))
                    pcellLayout:setTag(index)
                end
            end
        end  ,
    __G__TRACKBACK__)
    return pcell
end


-- 设置图片是否获得的状态
function ChangeUnionHeadOrHeadFrameMediator:SetGray( isGray , node )
    print("isHave = " ,isGray)
  print(type (node))
    if isGray then
        node:setFilter(GrayFilter:create())
    else
        node:clearFilter()
    end
end
-- 选中项的操作
function ChangeUnionHeadOrHeadFrameMediator:SelectIndexImage(sender)
    local index = sender:getTag()
    local data =  self.needData[index] or {}
    if not  data.isHave then -- 没有该道具的时候直接返回
        uiMgr:ShowInformationTips(string.format(__('该图标需工会达到%d级解锁') , checkint(data.openLevel)))
        return
    end
    --
    sender:setTouchEnabled(false)
    local viewData_ = self.viewComponent.viewData_
    local headBgLayout =  sender:getChildByName('headBgLayout')
    local headSelect = headBgLayout:getChildByName('headSelect')
    if self.preIndex then
        local cell = viewData_.gridView:cellAtIndex(self.preIndex -1)
        if cell and not  tolua.isnull(cell) then
            local pcellLayout = cell:getChildByName('pcellLayout')
            local headBgLayout = pcellLayout:getChildByName('headBgLayout')
            if headBgLayout and not  tolua.isnull(headBgLayout) then
                local headSelect = headBgLayout:getChildByName('headSelect')
                headSelect:setVisible(false)
                pcellLayout:setTouchEnabled(true)
            end
        end
    end
    headSelect:setVisible(true)

    --if self.type == CHANGE_TYPE.CHANGE_UNION_HEAD then
    --
    --
    --end
    self.preIndex = index
end
function ChangeUnionHeadOrHeadFrameMediator:ChangeBtn(sender)
    if self.preIndex then
        local data =  self.needData[self.preIndex] or {}
        if not  data.isHave then
            uiMgr:ShowInformationTips( self.needData[self.preIndex].desrc )
            return
        end
        if self.type == CHANGE_TYPE.CHANGE_UNION_HEAD then
            if checkint(data.id) == checkint(self.data.id) then
                uiMgr:ShowInformationTips(__('更换头像成功'))
            else
                self.data.id = data.id
            end
        end
        print("CHNAGE_UNION_HEAD_EVENT" ,  data.iconId)
        self:GetFacade():DispatchObservers(CHNAGE_UNION_HEAD_EVENT, {iconId = data.iconId})
        self:CloseMeditor()
    end
end
function ChangeUnionHeadOrHeadFrameMediator:CloseMeditor()
    self:GetFacade():UnRegsitMediator(NAME)
end
function ChangeUnionHeadOrHeadFrameMediator:OnRegist()
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = false})
end

function ChangeUnionHeadOrHeadFrameMediator:OnUnRegist()
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = true })
    if self.viewComponent and (not tolua.isnull(self.viewComponent)) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return ChangeUnionHeadOrHeadFrameMediator



