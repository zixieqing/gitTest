
---
--- Created by xingweihao.
--- DateTime: 25/10/2017 3:25 PM
---

local Mediator = mvc.Mediator
---@class ChangeHeadOrHeadFrameMediator :Mediator
local ChangeHeadOrHeadFrameMediator = class("ChangeHeadOrHeadFrameMediator", Mediator)
local NAME = "ChangeHeadOrHeadFrameMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local TITLE_NAME  = {
    __('更换奖杯') ,
    __('更换头像') ,
    __('更换头像框') ,
}
function ChangeHeadOrHeadFrameMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.data = param or {} -- 头像的数据
    self.type = self.data.type or 1
    self.callback = self.data.callback
    self.preIndex = nil
    self.needData = {} -- 需要的数据
end

function ChangeHeadOrHeadFrameMediator:InterestSignals()
    local signals = {
    }
    return signals
end
function ChangeHeadOrHeadFrameMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type ChangeHeadOrHeadFrameView
    self.viewComponent = require('Game.views.ChangeHeadOrHeadFrameView').new({callback = handler(self, self.CloseMeditor)  , title =  TITLE_NAME[self.type]})
    self:SetViewComponent(self.viewComponent)
    self.viewComponent:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(self.viewComponent)
    local  viewData_ = self.viewComponent.viewData_
    self.needData = self:GetNeedData()
    if self.data.id then
        for i =1 , #self.needData do
            if checkint(self.needData[i].id ) == checkint(self.data.id) then
                self.preIndex = i
                break
            end
        end
    end
    if self.type == CHANGE_TYPE.CHANGE_HEAD then
        viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataHeadSource))
    elseif  self.type == CHANGE_TYPE.CHANGE_HEAD_FRAME then
        viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataHeadFrameSource))
    elseif  self.type == CHANGE_TYPE.CHANGE_THROPHY then
        local topSize = cc.size(684, 500)
        viewData_.gridView:setContentSize(topSize)
        viewData_.gridView:setSizeOfCell( cc.size(topSize.width/4 , 245 ))
        viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataThrophySource))
        if self.preIndex then
            display.commonLabelParams(viewData_.changeBtn,{text = __('卸下')})
        end
    end
    viewData_.gridView:setCountOfCell(table.nums(self.needData))
    viewData_.changeBtn:setOnClickScriptHandler(handler(self, self.ChangeBtn))
    viewData_.gridView:reloadData()
end
-- 获取所需的数据 ， 按照顺序排列
function ChangeHeadOrHeadFrameMediator:GetNeedData()
    local needData = {}
    local achieveData = CommonUtils.GetConfigAllMess('achieveReward', 'goods')
    for k , v in pairs(achieveData) do
        if checkint(v.rewardType) ==  checkint(self.type) then -- 获取所拥有的道具类型
            needData[#needData+1] = clone(v)
            needData[#needData].isHave = false
            needData[#needData].sortIndex = 1
            local num = CommonUtils.GetCacheProductNum(v.id)

            if num > 0  then
                needData[#needData].isHave = true
                needData[#needData].sortIndex = 2
            end
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
function ChangeHeadOrHeadFrameMediator:ProcessSignal(signal)

end
-- 刷新头像资源的事件
function ChangeHeadOrHeadFrameMediator:OnDataHeadSource(cell , idx )
    local index = idx +1
    local pcell = cell
    xTry(
    function ()
        if index > 0 and index <= table.nums(self.needData)then  --获取到元素的个数
            local data = self.needData[index]
            if pcell == nil then
                local pcellSize= cc.size(164,175)
                pcell = CGridViewCell:new()
                pcell:setContentSize(pcellSize)
                -- 内容Layout

                local contentLayout = display.newLayer(pcellSize.width/2 , pcellSize.height/2 , { size = pcellSize , color = cc.r4b(0), ap = display.CENTER})
                pcell:addChild(contentLayout)
                -- 头像
                local headNode = require("root.CCHeaderNode").new({isSystemHead = true  ,url  = gameMgr:GetUserInfo().avatar, role_head =  data.id , pre =  self.data.avatarFrame , isPre = true , isSelf = true  })
                if gameMgr:GetUserInfo().avatarFrame  and gameMgr:GetUserInfo().avatarFrame  ~=  "" then
                    headNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(gameMgr:GetUserInfo().avatarFrame))
                else
                    headNode.preBg:setVisible(false)
                end

                headNode:setPosition(cc.p( pcellSize.width/2 , pcellSize.height /2 + 8 ) )
                headNode:setScale(0.9)
                contentLayout:addChild(headNode)
                headNode:setName("headNode")
                local headNodeSize = headNode:getContentSize()
                local bgCircle = display.newImageView(_res('ui/home/infor/create_roles_head_select') ,pcellSize.width/2 , pcellSize.height/2 + 8 ,
                        { scale9 = true , size = cc.size(headNodeSize.width + 10 , headNodeSize.height +10 )  } )
                contentLayout:addChild(bgCircle,-1)
                bgCircle:setName("bgCircle")
                contentLayout:setName("contentLayout")
                -- 头像姓名按钮
                local headName = display.newLabel(pcellSize.width/2 , 13 , fontWithColor('16' , { text = data.name }))
                headName:setName("headName")
                contentLayout:addChild(headName)
            end
            local contentLayout = pcell:getChildByName("contentLayout")
            local headNode = contentLayout:getChildByName("headNode")
            local headName = contentLayout:getChildByName("headName")
            local bgCircle = contentLayout:getChildByName("bgCircle")
            headNode.headerSprite:setTexture(CommonUtils.GetGoodsIconPathById(data.id))
            contentLayout:setTag(index)
            contentLayout:setOnClickScriptHandler(handler(self,self.SelectIndexImage))
            local name = data.name
            local isHave = data.isHave
            local color = isHave and fontWithColor('16').color or fontWithColor('6').color
            display.commonLabelParams(headName, { text = name , color = color , reqW = 150})
            headNode:SetGray(not isHave)
            headNode:setScale(0.7)
            local isVisible = false
            if self.preIndex == nil then
                isVisible =  self.data.id == data.id
                if isVisible then
                    self.preIndex = index 
                end
            else
                isVisible = index == self.preIndex
            end
            bgCircle:setVisible(isVisible)
            bgCircle:setScale(0.7)
            -- 设置选中的选线为不可以点击
            contentLayout:setTouchEnabled(not isVisible)
        end
    end  ,
    __G__TRACKBACK__)
    return pcell
end
-- 刷新头像框的事件
function ChangeHeadOrHeadFrameMediator:OnDataHeadFrameSource(cell , idx )
    local index = idx +1
    local pcell = cell
    xTry(
    function ()
        if index > 0 and index <= table.nums(self.needData)then  --获取到元素的个数
            local data = self.needData[index]
            if pcell == nil then
                local pcellSize= cc.size(164,175)
                pcell = CGridViewCell:new()
                pcell:setContentSize(pcellSize)
                -- 内容Layout

                local contentLayout = display.newLayer(pcellSize.width/2 , pcellSize.height/2 , { size = pcellSize , color = cc.c4b(0,0,0,0), ap = display.CENTER})
                pcell:addChild(contentLayout)

                -- 头像
                local headNode = require("root.CCHeaderNode").new({isSystemHead = true  ,url  = gameMgr:GetUserInfo().avatar, role_head =  data.id , pre =  self.data.avatarFrame , isPre = true , isSelf = true  })
                headNode:setPosition(cc.p( pcellSize.width/2 , pcellSize.height /2 + 8 ) )
                headNode:setScale(0.9)
                contentLayout:addChild(headNode)
                if  headNode.bg then
                    headNode.bg:setVisible(false)
                    headNode.bg:setOpacity(0)
                end

                headNode:setName("headNode")
                local headNodeSize = headNode:getContentSize()
                local bgCircle = display.newImageView(_res('ui/home/infor/create_roles_head_select') ,
                    pcellSize.width/2 , pcellSize.height/2 + 8 ,{ scale9 = true , size = cc.size(headNodeSize.width + 15 , headNodeSize.height +15) } )
                contentLayout:addChild(bgCircle,-1)
                bgCircle:setName("bgCircle")
                contentLayout:setName("contentLayout")
                -- 头像姓名按钮
                local headName = display.newLabel(pcellSize.width/2 , 5 + 8 , fontWithColor('16' , { text = data.name }))
                headName:setName("headName")
                contentLayout:addChild(headName)

            end
            local contentLayout = pcell:getChildByName("contentLayout")
            local headNode = contentLayout:getChildByName("headNode")
            local headName = contentLayout:getChildByName("headName")
            local bgCircle = contentLayout:getChildByName("bgCircle")
            contentLayout:setTag(index)
            contentLayout:setOnClickScriptHandler(handler(self,self.SelectIndexImage))
            local name = data.name
            local isHave = data.isHave

            headNode:SetGray(not isHave)
            headNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(data.id))
            local color = isHave and fontWithColor('16').color or fontWithColor('6').color
            display.commonLabelParams(headName, { text = name ,color = color , reqW =150    })
            local isVisible = false
            headNode:setScale(0.7)
            bgCircle:setScale(0.7)
            if self.preIndex == nil then
                isVisible =  self.data.id == data.id
                if isVisible then
                    self.preIndex = index
                end
            else
                isVisible = index == self.preIndex
            end
            bgCircle:setVisible(isVisible)
            -- 设置选中的选线为不可以点击
            contentLayout:setTouchEnabled(not isVisible)
        end
    end  ,
    __G__TRACKBACK__)
    return pcell
end
-- 刷新奖杯的事件
function ChangeHeadOrHeadFrameMediator:OnDataThrophySource(cell , idx )
    local index = idx +1
    local pcell = cell
    xTry(
    function ()
        if index > 0 and index <= table.nums(self.needData)then  --获取到元素的个数
            local data = self.needData[index]
            if pcell == nil then
                local pcellSize= cc.size(171,245)
                pcell = CGridViewCell:new()
                pcell:setContentSize(pcellSize)
                -- 内容Layout
                local bgImage = FilteredSpriteWithOne:create(_res('ui/home/infor/avator_trophy_bg'))
                local bgSize = bgImage:getContentSize()
                bgImage:setPosition(cc.p(bgSize.width/2 , bgSize.height/2))
                bgImage:setName("bgImage")
                -- 内容
                local contentLayout = display.newLayer(pcellSize.width/2 , pcellSize.height/2 , { size = bgSize , color = cc.c4b(0,0,0,0), ap = display.CENTER})
                pcell:addChild(contentLayout)
                contentLayout:addChild(bgImage)

                local bgCircle = display.newImageView(_res('ui/home/infor/avator_trophy_bg_select') ,bgSize.width/2 , bgSize.height/2 )
                contentLayout:addChild(bgCircle)
                bgCircle:setName("bgCircle")
                contentLayout:setName("contentLayout")
                -- 头像框
                local throphyImage = FilteredSpriteWithOne:create(CommonUtils.GetGoodsIconPathById(data.id))
                throphyImage:setScale(0.75 )
                throphyImage:setPosition(cc.p(bgSize.width/2 , bgSize.height  - 20 ))
                throphyImage:setAnchorPoint(display.CENTER_TOP)
                contentLayout:addChild(throphyImage)
                throphyImage:setName("throphyImage")
                -- 头像姓名按钮
                local headName = display.newLabel(bgSize.width/2 , 18 , fontWithColor('16' , { text = data.name }))
                headName:setName("headName")
                contentLayout:addChild(headName)
            end
            local contentLayout = pcell:getChildByName("contentLayout")
            local throphyImage = contentLayout:getChildByName("throphyImage")
            local headName = contentLayout:getChildByName("headName")
            local bgImage = contentLayout:getChildByName("bgImage")
            local bgCircle = contentLayout:getChildByName("bgCircle")
            contentLayout:setTag(index)
            contentLayout:setOnClickScriptHandler(handler(self,self.SelectIndexImage))
            local name = data.name
            local isHave = data.isHave
            local color = isHave and fontWithColor('16').color or fontWithColor('6').color
            display.commonLabelParams(headName, { text = name , color = color , reqW =  150})
            self:SetGray( (not isHave) ,bgImage)
            self:SetGray( (not isHave) ,throphyImage)
            local isVisible = false
            if self.preIndex == nil then
                isVisible =  self.data.id == data.id
                if isVisible then
                    self.preIndex = index
                end
            else
                isVisible = index == self.preIndex
            end
            bgCircle:setVisible(isVisible)
            -- 设置选中的选线为不可以点击
            contentLayout:setTouchEnabled(not isVisible)
            throphyImage:setTexture(CommonUtils.GetGoodsIconPathById(data.id))
        end
    end  ,
    __G__TRACKBACK__)
    return pcell
end
-- 设置图片是否获得的状态
function ChangeHeadOrHeadFrameMediator:SetGray( isGray , node )
    if isGray then
        node:setFilter(GrayFilter:create())
    else
        node:clearFilter()
    end
end
-- 选中项的操作
function ChangeHeadOrHeadFrameMediator:SelectIndexImage(sender)
    local index = sender:getTag()
    local data =  self.needData[index] or {}

    if not  data.isHave then -- 没有该道具的时候直接返回
        uiMgr:AddDialog("common.GainPopup", {goodId =data.id})
        return
    end

    sender:setTouchEnabled(false)
    local viewData_ = self.viewComponent.viewData_
    local bgCircle = sender:getChildByName('bgCircle')

    if self.preIndex then
        local cell = viewData_.gridView:cellAtIndex(self.preIndex -1)
        if cell and not  tolua.isnull(cell) then
            local contentLayout = cell:getChildByName('contentLayout')
            if contentLayout and not  tolua.isnull(contentLayout) then
                local bgCircle = contentLayout:getChildByName("bgCircle")
                bgCircle:setVisible(false)
                contentLayout:setTouchEnabled(true)
            end
        end
    end
    bgCircle:setVisible(true)

    if self.type == CHANGE_TYPE.CHANGE_HEAD then

    elseif self.type == CHANGE_TYPE.CHANGE_HEAD_FRAME then

    elseif self.type == CHANGE_TYPE.CHANGE_THROPHY then
        if checkint(self.data.id) == checkint(self.needData[index].id) then
            display.commonLabelParams(viewData_.changeBtn, {text = __('卸下')})
        else
            display.commonLabelParams(viewData_.changeBtn, {text = __('替换')})
        end
    end
    self.preIndex = index
end
function ChangeHeadOrHeadFrameMediator:ChangeBtn(sender)
    local chanegeName   = {
        __('奖杯') ,
        __('头像') ,
        __('头像框')
    }
    if self.preIndex then

        local data =  self.needData[self.preIndex] or {}
        if not  data.isHave then
            local text = nil
            if isKoreanSdk() then
                text = string.format(__('尚未获得该%s'), chanegeName[self.type])
            else
                text = __('尚未获得该') .. chanegeName[self.type]
            end
            uiMgr:ShowInformationTips(text)
            return
        end
        if self.type == CHANGE_TYPE.CHANGE_HEAD then
            if checkint(data.id) == checkint(self.data.id) then

            else
                self.data.id = data.id
            end
            uiMgr:ShowInformationTips(__('更换成功'))
        elseif self.type == CHANGE_TYPE.CHANGE_HEAD_FRAME then
            if checkint(data.id) == checkint(self.data.id) then
            else
                self.data.id = data.id
            end
            uiMgr:ShowInformationTips(__('更换成功'))
        elseif self.type == CHANGE_TYPE.CHANGE_THROPHY then
            if self.data.id then  -- 有奖杯的情况下
                if checkint( data.id) ==  checkint(self.data.id) then --这是奖杯的写下逻辑
                    self.data.id = nil
                else
                    self.data.id = data.id
                end
            else
                self.data.id = data.id
            end
        end

        if self.callback then
            self.callback(self.data)
            self:CloseMeditor()
        end
    else
        local text = nil
        if isKoreanSdk() then
            text = string.format(__('请选择%s'), chanegeName[self.type])
        else
            text = __('请选择') .. chanegeName[self.type]
        end
        uiMgr:ShowInformationTips(text)
    end
end
function ChangeHeadOrHeadFrameMediator:CloseMeditor()
    self:GetFacade():UnRegsitMediator(NAME)
end
function ChangeHeadOrHeadFrameMediator:OnRegist()
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = false ,tag = DISABLE_EDITBOX_MEDIATOR.PERSON_DETAIL_TAG})
end

function ChangeHeadOrHeadFrameMediator:OnUnRegist()
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = true ,tag = DISABLE_EDITBOX_MEDIATOR.PERSON_DETAIL_TAG})
    if self.viewComponent and (not tolua.isnull(self.viewComponent)) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return ChangeHeadOrHeadFrameMediator



