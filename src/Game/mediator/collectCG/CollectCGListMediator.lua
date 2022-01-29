--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class CollectCGListMediator :Mediator
local CollectCGListMediator = class("CollectCGListMediator", Mediator)
local NAME = "CollectCGListMediator"
local CGCOnfig = CommonUtils.GetConfigAllMess('cg' ,'collection')
local CGFragmentConfig = CommonUtils.GetConfigAllMess('cg' ,'cgFragment')
local BUTTON_TAG = {
    LEFT_BUTTON    = 1001,
    RIGHT_BUTTON   = 1002,
    TAB_NAME_LABEL = 1003,
    SELECT_TAB     = 1004,
    ALL_KIND       = 1,
    COMMON_KIND    = 2,
    ACTIVITY_LIMIT = 3
}
function CollectCGListMediator:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.isComplete = true   --  收集是否完成
    self.backpackMap = self:ConvertBackpackArrayToMap()
    self.cgArray = self:GetCGArarayByTabIndex(BUTTON_TAG.ALL_KIND)
    self.count = table.nums(CGCOnfig)
    self.isAction = true
    self.selectIndex = 1  -- 选中的index
    self.index = 1 -- 当前选中的为1
end


function CollectCGListMediator:InterestSignals()
    local signals = {
    }
    return signals
end

function CollectCGListMediator:ProcessSignal( signal )

end

function CollectCGListMediator:Initial( key )
    self.super:Initial(key)
    ---@type CollectCGListView
    local viewComponent = require("Game.views.collectCG.CollectCGListView").new()
    self:SetViewComponent(viewComponent)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:setPosition(display.center)
    local viewData = viewComponent.viewData
    display.commonUIParams(viewData.backBtn , { cb = function()
        PlayAudioByClickClose()
        if   self.isAction then
            return
        end
        app:UnRegsitMediator(NAME)
    end})
    viewComponent:CreateCGCell(viewData.oneLayer)
    viewData.leftBotton:setOnClickScriptHandler(handler(self, self.ButtonClick))
    viewData.rightButton:setOnClickScriptHandler(handler(self, self.ButtonClick))
    viewData.checkbox:setOnClickScriptHandler(handler(self, self.ButtonClick))
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.ButtonClick))
    self:UpdateByIndex(BUTTON_TAG.ALL_KIND)
    self:EnterAction()
end
function CollectCGListMediator:EnterAction()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local view = viewData.view
    view:setOpacity(125)
    view:runAction(
        cc.Sequence:create(
            cc.Spawn:create(
                cc.JumpTo:create(     0.5 ,  display.center , 300, 1 ),
                cc.FadeIn:create(0.4)
            ),
            cc.CallFunc:create(
                function()
                    self.isAction = false
                end
            )
        )
    )
end
--[[
　　---@Description:根据tabIndex 获取到cgArray 的数值
　　---@param :tabIndex  分类的类型
　  ---@return : cgArray
　　---@author : xingweihao
　　---@date : 2018/9/19 2:08 PM
--]]
function CollectCGListMediator:GetCGArarayByTabIndex(tabIndex)
    local cgArray = {}
    local index = tabIndex - 1
    local count = table.nums(CGCOnfig)
    for i =1 , count do
            local cgData = CGCOnfig[tostring(i)]
            if checkint(cgData.tab) == index  or index == 0   then
                cgArray[#cgArray+1] = cgData
            end
    end
    return  cgArray
end
-- 将背包数据由array 转换为map 类型
function CollectCGListMediator:ConvertBackpackArrayToMap()
    local backpack = {}
    for index, goodsData in ipairs(app.gameMgr:GetUserInfo().backpack) do
        backpack[tostring(goodsData.goodsId)] = goodsData
    end
    return backpack
end
function CollectCGListMediator:GetCGfragementNumById(cgId)
    local cgOneConfig = CGCOnfig[tostring(cgId)]
    local fragments = cgOneConfig.fragments or {}
    local ownerNum = 0
    for i, v in pairs(fragments) do
        if self.backpackMap[tostring(v)]  and
        self.backpackMap[tostring(v)].amount > 0  then
            ownerNum = ownerNum +1
        end
    end
    return ownerNum
end

function CollectCGListMediator:ButtonClick(sender)
    PlayAudioByClickNormal()
    if   self.isAction then
        return
    end
    local tag = sender:getTag()
    if tag == BUTTON_TAG.LEFT_BUTTON then
        local index = self.index -1
        self:UpdateOneLayerAndTwoLayer(index)
    elseif tag == BUTTON_TAG.RIGHT_BUTTON then
        local index = self.index + 1
        self:UpdateOneLayerAndTwoLayer(index)
    elseif tag == BUTTON_TAG.TAB_NAME_LABEL then
        app.uiMgr:ShowIntroPopup({moduleId = JUMP_MODULE_DATA.CG_COLLECT })
    elseif tag == BUTTON_TAG.SELECT_TAB then
        sender:setEnabled(false)
        ---@type CollectCGListView
        local viewComponent = self:GetViewComponent()
        local borderLayer = viewComponent:getChildByName("borderLayer")
        if not  borderLayer then
            borderLayer = viewComponent:CreateTabView()
            local pos = cc.p(sender:getPosition())
            borderLayer:setPosition(pos.x , pos.y + 42 )
            borderLayer:setName("borderLayer")
            for i = 1  , 3 do
                local button  = borderLayer:getChildByTag(i)
                display.commonUIParams(button , {cb = handler(self, self.CheckTabClick) } )
            end
            viewComponent:addChild(borderLayer ,10)
        end
        self:UpdateTabLayout()
        borderLayer:setScaleY(0)
        borderLayer:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.3 , 1,1)))
    end
end
function CollectCGListMediator:CheckTabClick(sender)
    local tag = sender:getTag()
    self.selectIndex = tag
    self:UpdateTabLayout()
    self:UpdateByIndex(tag)
    ---@type CollectCGListView
    local viewComponent =self:GetViewComponent()
    local borderLayer =viewComponent:getChildByName("borderLayer")
    borderLayer:runAction(
         cc.Sequence:create(cc.ScaleTo:create(0.1, 1,0) ,
            cc.CallFunc:create(
                function()
                    viewComponent.viewData.checkbox:setEnabled(true)
                    viewComponent.viewData.checkbox:setChecked(false)
                end
            )
        )
    )
end
function CollectCGListMediator:UpdateTabLayout()
    local viewComponent = self:GetViewComponent()
    local borderLayer = viewComponent:getChildByName("borderLayer")
    for i = 1  , 3 do
        local button  = borderLayer:getChildByTag(i)
        local selectImage = button:getChildByName("selectImage")
        if self.selectIndex ==  i  then
            selectImage:setVisible(true )
        else
            selectImage:setVisible(false )
        end
    end
end
function CollectCGListMediator:UpdateByIndex(index)
    self.cgArray = self:GetCGArarayByTabIndex(index)
    self.count = #self.cgArray
    ---@type CollectCGListView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local SCREEN_TYPE = {
          __('全部'),
         __('通常'),
         __('活动限定')
    }
    display.commonLabelParams(viewData.kindName ,{ w = 170 ,hAlign = display.TAC ,  text =  SCREEN_TYPE[index]} )
    local isVisible = (self.count > 0 and  true) or false
    viewData.leftBotton:setVisible(isVisible)
    viewData.rightButton:setVisible(isVisible)
    self.index = 1

    local oneLayer = viewData.oneLayer
    local twoLayer = viewData.twoLayer
    oneLayer:setPositionX(0)
    oneLayer:setOpacity(255)
    twoLayer:setPositionX(1200)
    twoLayer:setOpacity(0)
    self:UpdateCGCellByIndexAndNode(self.index , oneLayer)
end
function CollectCGListMediator:UpdateCGCellByIndexAndNode(index , node)
    local cgCell = node:getChildByTag(1)
    if not  cgCell  then
        ---@type CollectCGListView
        local viewComponent = self:GetViewComponent()
        viewComponent:CreateCGCell(node)
    end
    for i =1 , 4 do
        local cgCell = node:getChildByTag(i)
        local cellIndex =  (index -1) * 4 + i
        if cellIndex  > self.count  then
            cgCell:setVisible(false)
        else
            cgCell:setVisible(true)
            cgCell:RefresshUI(self.cgArray[cellIndex].id , self:GetCGfragementNumById(self.cgArray[cellIndex].id ) ,self.cgArray[cellIndex].num  )
            -- 创建点击事件
            cgCell.viewData.cellLayout:setTag(checkint(self.cgArray[cellIndex].id))
            display.commonUIParams(cgCell.viewData.cellLayout  , {cb = function(sender)
                if   self.isAction then
                    return
                end
                local tag = sender:getTag()
                local mediator = require("Game.mediator.collectCG.CollectCGDetailMediator").new({ cgId   = tag})
                app:RegistMediator(mediator)
            end})
        end
    end
end
function CollectCGListMediator:UpdateOneLayerAndTwoLayer(index)
    ---@type CollectCGListView
    local viewComponent = self:GetViewComponent()
    local viewData      = viewComponent.viewData
    local oneLayer      = viewData.oneLayer
    local twoLayer      = viewData.twoLayer
    local onePos        = cc.p(oneLayer:getPosition())
    local twoPos        = cc.p(twoLayer:getPosition())
    local oneNode = nil
    local twoNode = nil
    -- 判断有限滑动的主题
    if onePos.x ==  0  then
        oneNode = oneLayer
        twoNode = twoLayer
    elseif twoPos.x ==  0   then
        oneNode = twoLayer
        twoNode = oneLayer
    end
    -- 判断滑动的方向  获取左边变化的系数
    local dirtection = 1
    if index > self.index  then
        dirtection = -1
    else
        dirtection = 1
    end
    if index > math.ceil(self.count / 4)  then
        index =  index -  math.ceil(self.count / 4)
    elseif index <= 0  then
        index = math.ceil(self.count/4)
    end
    self.index = index
    -- 跟随滑动的位置调整
    twoNode:setPositionX(1200 * -dirtection)
    twoNode:setOpacity(0)
    if table.nums(viewData.twoLayer:getChildren())  ==  0  then
        viewComponent:CreateCGCell(viewData.twoLayer)
    end
    self:UpdateCGCellByIndexAndNode(index , twoNode)
    viewComponent:stopAllActions()
    viewComponent:runAction(
        cc.Sequence:create(
            cc.CallFunc:create(function()
                self.isAction = true
            end)  ,
            cc.Spawn:create(
                cc.TargetedAction:create(
                    oneNode ,  cc.Spawn:create(
                        cc.MoveBy:create(0.5 , cc.p(1200 * dirtection , 0)),
                        cc.FadeOut:create(0.5)
                    )
                ),
                cc.TargetedAction:create(
                    twoNode, cc.Spawn:create(
                        cc.MoveBy:create(0.5, cc.p(1200 * dirtection, 0)),
                        cc.FadeIn:create(0.5)
                    )
                )
            ),
            cc.CallFunc:create(function()
                self.isAction = false
            end)
        )
    )
end

function CollectCGListMediator:OnRegist(  )

end


function CollectCGListMediator:OnUnRegist(  )
    local viewComponent = self:GetViewComponent()
    if viewComponent and ( not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return CollectCGListMediator
