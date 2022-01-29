---
--- Created by xingweihao.
--- DateTime: 21/09/2017 10:17 AM
---
local Mediator = mvc.Mediator
---@class FoodMaterialHandbookMediator:Mediator
local FoodMaterialHandbookMediator = class("FoodMaterialHandbookMediator", Mediator)

-- MaterialCompose_Callback = 'MaterialCompose_Callback'

local NAME = "FoodMaterialHandbookMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local BackpackCell = require('home.BackpackCell')
-- local GoodsSale = require('common.GoodsSale')
local FOODMATERIALKINDS = {
    ALLKINDS = 1004 , -- 全部食材
}
function FoodMaterialHandbookMediator:ctor( param ,viewComponent )
    self.super:ctor(NAME,viewComponent)
    param = param or {}
    self.backPackDatas = {}
    self.clickTag = param.clickTag or  FOODMATERIALKINDS.ALLKINDS
    self.datas = {}
    self.preIndex = 1
    self.goodsId = nil
    self.saleNum = 0
    self.saleId = ''

    self.useNum = 0
    self.useId = ''
    self.gridContentOffset = cc.p(0,0)
end

function FoodMaterialHandbookMediator:InterestSignals()
    local signals = {
        "REFRESH_NOT_CLOSE_GOODS_EVENT"
    }

    return signals
end
---@param signal Signal
function FoodMaterialHandbookMediator:ProcessSignal(signal )
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == "REFRESH_NOT_CLOSE_GOODS_EVENT" then
        self:GetMaterialFoodsIndex(self.goodsId)
        self:EnterLayer(self.clickTag)

    end
end
function FoodMaterialHandbookMediator:GetMaterialFoodsIndex(goodsId)
    local data = nil
    goodsId = checkint(goodsId)
    if self.goodsId then
        for i =1 , #self.datas do
            data = self.datas[i]
            if checkint(data.goodsId) ==  goodsId   then
                self.preIndex = i
                break
            end
        end
    end
end
function FoodMaterialHandbookMediator:Initial( key )
    self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
    local viewComponent  = require( 'Game.views.FoodMaterialHandbookView' ).new()
    self:SetViewComponent(viewComponent)
    ---@type FoodMaterialHandbookView
    self.viewComponent = viewComponent
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)

    --绑定相关的事件
    local viewData = viewComponent.viewData_
    for k, v in pairs( viewData.buttons ) do
        v:setOnClickScriptHandler(handler(self,self.ButtonActions))
    end
    local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
    viewData.saleBtn:setVisible(false)
    viewData.getBtn:setVisible(true)
    viewData.getBtn:setEnabled(true)
    viewData.getBtn:setOnClickScriptHandler(handler(self,self.ButtonCallback))

end

function FoodMaterialHandbookMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local viewData = self.viewComponent.viewData_
    local bg = viewData.gridView
    local sizee = cc.size(108, 115)

    if self.datas and index <= table.nums(self.datas) then
        local data = CommonUtils.GetConfig('goods', 'goods', self.datas[index].goodsId)
        if pCell == nil then
            pCell = BackpackCell.new(sizee)
            pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))

            if index <= 20 then
                pCell.eventnode:setPositionY(sizee.height - 800)
                pCell.eventnode:runAction(
                cc.Sequence:create(cc.DelayTime:create(index * 0.01),
                cc.EaseOut:create(cc.MoveTo:create(0.4, cc.p(sizee.width* 0.5,sizee.height * 0.5)), 0.2))
                )
            else
                pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
            end
        else
            pCell.selectImg:setVisible(false)
            pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
        end
        xTry(function()

            if self.datas[index].IsNew then
                if self.datas[index].IsNew == 1 then
                    pCell.newIcon:setVisible(true)
                else
                    pCell.newIcon:setVisible(false)
                end
            else
                pCell.newIcon:setVisible(false)
            end

            local quality = 1
            if data then
                if data.quality then
                    quality = data.quality
                end
            end

            local drawBgPath = _res('ui/common/common_frame_goods_'..tostring(quality)..'.png')
            local fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
            if not utils.isExistent(drawBgPath) then
                drawBgPath = _res('ui/common/common_frame_goods_'..tostring(1)..'.png')
                fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
            end
            pCell.fragmentImg:setTexture(fragmentPath)
            pCell.toggleView:setNormalImage(drawBgPath)
            pCell.toggleView:setSelectedImage(drawBgPath)
            pCell.toggleView:setTag(index)
            pCell.toggleView:setScale(0.92)
            pCell:setTag(index)

            if data then
                if tostring(data.type) == GoodsType.TYPE_CARD_FRAGMENT then
                    pCell.fragmentImg:setVisible(true)
                else
                    pCell.fragmentImg:setVisible(false)
                end
            else
                pCell.fragmentImg:setVisible(false)
            end
            if index == self.preIndex then
                pCell.selectImg:setVisible(true)
            else
                pCell.selectImg:setVisible(false)
            end

            pCell.numLabel:setString(tostring(self.datas[index].amount))

            local node = pCell.toggleView:getChildByTag(111)
            if node then node:removeFromParent() end
            local goodsId = self.datas[index].goodsId
            local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
            local sprite = display.newImageView(_res(iconPath),0,0,{as = false})
            sprite:setScale(0.55)
            if checkint(self.datas[index].amount)  == 0 then
                sprite:setColor(cc.c3b(80,80,80))
            else
                sprite:setColor(cc.c3b(255,255,255))
            end
            local lsize = pCell.toggleView:getContentSize()
            sprite:setPosition(cc.p(lsize.width * 0.5,lsize.height *0.5))
            sprite:setTag(111)
            pCell.toggleView:addChild(sprite)
        end,__G__TRACKBACK__)
        return pCell
    end
end
--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function FoodMaterialHandbookMediator:CellButtonAction( sender )
    -- sender:setChecked(true)
    local viewData = self.viewComponent.viewData_
    local gridView = viewData.gridView
    local index = sender:getTag()
    local cell = gridView:cellAtIndex(index- 1)
    if cell then
        cell.selectImg:setVisible(true)
        cell.newIcon:setVisible(false)
        gameMgr:UpdateBackpackNewStatuByGoodId(self.datas[index].goodsId)
        self.datas[index].IsNew = 0
    end

    if index == self.preIndex then return end
    if self.preIndex then
        PlayAudioByClickNormal()
    end
    --更新按钮状态
    local cell = gridView:cellAtIndex(self.preIndex - 1)
    if cell then
        cell.selectImg:setVisible(false)
    end
    self.preIndex = index
    self.goodsId = self.datas[self.preIndex].goodsId
    self.gridContentOffset = gridView:getContentOffset()
    self:updateDescription(self.preIndex)
end
--[[
主页面tab按钮的事件处理逻辑
@param sender button对象
--]]
function FoodMaterialHandbookMediator:ButtonActions( sender )
    local tag = 0
    local temp_data = {}
    if type(sender) == 'number' then
        tag = sender
    else
        PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
        tag = sender:getTag()
        if self.clickTag == tag then
            return
        else
            self.preIndex = 1
        end
    end

    local viewData = self.viewComponent.viewData_
    for k, v in pairs( viewData.buttons ) do
        local curTag = v:getTag()
        if tag == curTag then
            v:setChecked(true)
            v:setEnabled(false)
        else
            v:setChecked(false)
            v:setEnabled(true)
        end
    end
    local viewData = self.viewComponent.viewData_
    local gridView = viewData.gridView
    self.clickTag = tag
    if tag ==  FOODMATERIALKINDS.ALLKINDS  then
        self.foodMaterialDatas =  self:SortTableByFoodMaterial(self.foodMaterialDatas)
        self.datas = self.foodMaterialDatas
    end
    self.gridContentOffset = gridView:getContentOffset()
    if  self.datas  and table.nums( self.datas ) > 0 then

        gridView:setCountOfCell(table.nums(self.datas))

        self:updateDescription(self.preIndex)
        gridView:reloadData()
        viewData.kongBg:setVisible(false)
        viewData.bgView:setVisible(true)
    else
        self.datas = {}
        gridView:setCountOfCell(table.nums(self.datas))
        gridView:reloadData()
        viewData.bgView:setVisible(false)
        viewData.kongBg:setVisible(true)
    end
end
--[[
	第一个是移动的距离，容量大小，第三个是内容大小
--]]
function FoodMaterialHandbookMediator:returnsetContentOffset(point,contentSize,containerSize)
    if math.abs(point.y) + contentSize.height > containerSize.height then
        return cc.p(0,contentSize.height - containerSize.height)
    else
        return point
    end
end
--[[
主页面出售，获取按钮的事件处理
@param sender button对象
--]]
function FoodMaterialHandbookMediator:ButtonCallback( sender )
    local tag = sender:getTag()
    local scene = uiMgr:GetCurrentScene()
    if tag == 1 then 		-- 出售

    elseif tag == 2 then 	-- 获取
        uiMgr:AddDialog('common.GainPopup', {goodId = self.datas[self.preIndex].goodsId,isFrom = 'FoodMaterialHandbookMediator'})
    end
end
--[[
主页面详情描述页面
@param index int下标
--]]
function FoodMaterialHandbookMediator:updateDescription( index )
    if self.datas and table.nums(self.datas) > 0 then
        if not self.datas[index] then
            self.preIndex = self.preIndex - 1
            self:updateDescription( self.preIndex )
            local gridView = self.viewComponent.viewData_.gridView
            local pCell = gridView:cellAtIndex(table.nums(self.datas) - 1)
            if pCell then
                pCell.selectImg:setVisible(true)
            end

            gridView:setContentOffset(self.gridContentOffset)
            return
        end

        local data = CommonUtils.GetConfig('goods', 'goods', self.datas[index].goodsId)
        local viewData = self.viewComponent.viewData_

        local reward_rank 	=  viewData.reward_rank
        local reward_img 	=  viewData.reward_img
        local DesNameLabel 	=  viewData.DesNameLabel
        local DesNumLabel 	=  viewData.DesNumLabel
        local DesPriceLabel =  viewData.DesPriceLabel
        local DesLabel 		=  viewData.DesLabel
        local fragmentImg 	=  viewData.fragmentImg
        fragmentImg:setVisible(false)
        if data then
            --物品材料等级
            local quality = checkint(data.quality) % CARD_BREAK_MAX
            if quality <= 0 then
                quality = 1
            end
            local bgPath = string.format('ui/common/common_frame_goods_%d.png', checkint(data.quality or 1))
            reward_rank:setTexture(_res(bgPath))
            reward_rank:setTexture(_res(bgPath))

            local fragmentPath = string.format('ui/common/common_ico_fragment_%d.png', checkint(data.quality or 1))
            fragmentImg:setTexture(_res(fragmentPath))

            if data.type then
                if tostring(data.type) == GoodsType.TYPE_CARD_FRAGMENT then
                    fragmentImg:setVisible(true)
                end
            end
            --物品图片
            reward_img:setVisible(true)
            local goodsId = self.datas[index].goodsId
            local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)

            reward_img:setTexture(_res(iconPath))
            reward_img:setScale(0.55)
            --物品名称
            DesNameLabel:setString(data.name)
            --物品类型
            local temp_type_src = ''
            local ttype = CommonUtils.GetGoodTypeById(self.datas[index].goodsId)
            temp_type_src = CommonUtils.GetConfig('goods', 'type', ttype).type
            --物品数量
            DesNumLabel:setString(string.fmt(__('数量: _name_'), {_name_ = self.datas[index].amount}))
            DesLabel:setString(data.descr)
        else
            DesLabel:setString(__('物品不存在。'))
        end
    end
end
--[[
    排列的顺序首先是未拥有的滞后 然后才会按照id 去排序
--]]
function FoodMaterialHandbookMediator:SortTableByFoodMaterial(data)
    if (not  data)  then
        return  {}
    end
    local sortTable =  function (a, b )
        if checkint(a.amount)  > 0  and checkint( b.amount )> 0  then
            if checkint(a.goodsId) > checkint(b.goodsId) then
                return false 
            else 
                return true 
            end
        elseif checkint(a.amount)  ==  0  then
            if checkint(b.amount) == 0 then
                if checkint(a.goodsId) > checkint(b.goodsId) then
                    return false
                else
                    return true
                end
            end
        elseif  checkint(a.amount) ~= 0 then
            if checkint(b.amount) == 0 then
                return true
            end
        end

    end
    table.sort(data ,sortTable)
    return data
end

function FoodMaterialHandbookMediator:EnterLayer(tag )
    --local tag = FOODMATERIALKINDS.ALLKINDS
    self.clickTag = tag or  self.clickTag
    local viewData = self.viewComponent.viewData_
    for k, v in pairs( viewData.buttons ) do
        local curTag = v:getTag()
        if  self.clickTag == curTag then
            v:setChecked(true)
        else
            v:setChecked(false)
        end
    end
    self.collectionOwnerKinds = {}  -- 已经拥有的食物
    self.foodMaterialDatas = {} -- 食材收集
    local count = 0
    for k,v in pairs(gameMgr:GetUserInfo().backpack) do

        if checkint(CommonUtils.GetGoodTypeById(v.goodsId))  == checkint(GoodsType.TYPE_FOOD_MATERIAL)  then
            if checkint(v.goodsId ) >= 169001 and checkint(v.goodsId ) <= 169999 then

            else
                if v.amount > 0 then
                    count = count +1
                    self.foodMaterialDatas[count] = v
                    self.collectionOwnerKinds[tostring(v.goodsId)] = true
                end
            end

        end
    end
    local foodsMateralData = CommonUtils.GetConfigAllMess('foodMaterial', 'goods')
    --dump(self.foodMaterialDatas)
    for k ,v in pairs(foodsMateralData) do -- 插入没有拥有的食材道具
        if not  self.collectionOwnerKinds[tostring(v.id)] then
            if checkint(v.id ) >= 169001 and checkint(v.id ) <= 169999 then

            else
                local data = {}
                data.amount = 0
                data.goodsId = v.id
                self.foodMaterialDatas[#self.foodMaterialDatas+1] = data

            end
        end
    end
    self:ButtonActions(self.clickTag)
end
function FoodMaterialHandbookMediator:OnRegist(  )
    --self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")

    self:EnterLayer()
end
function FoodMaterialHandbookMediator:OnUnRegist(  )
    --称出命令
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveGameLayer(self.viewComponent)
    --self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")

end

return FoodMaterialHandbookMediator
