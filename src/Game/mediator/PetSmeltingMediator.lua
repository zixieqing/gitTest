--[[
公告系统Mediator
--]]
local Mediator = mvc.Mediator
---@class PetSmeltingMediator :Mediator
local PetSmeltingMediator = class("PetSmeltingMediator", Mediator)

local NAME = "PetSmeltingMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local petConfig = CommonUtils.GetConfigAllMess('petEgg','pet')
local funsionConfig = CommonUtils.GetConfigAllMess('fusion','pet')
local BUTTON_TAG = {
    CLEAN_PET_EGGS         = 1101,
    QUICK_CONSUME_PET_EGGS = 1102,
    SMELTING_EGGS          = 1103,
    BACK_PURGE             = 1104,
    BATCH_CONSUME_PET_EGGS = 1105,

}
local PetModuleType = {
    PURGE 			= 1,  -- 灵体净化
    DEVELOP 		= 2,  -- 堕神养成
    SMELTING 		= 3   -- 堕神熔炼
}

--[[
self.consumeEggsTable
格式如下
    {
        index = 1 ,  -- 消耗蛋的索引
        egg = { goodsId = eggid, amount =  }
    }
--]]
function PetSmeltingMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    -- 消耗的eggs 格式
    self.isRemove = false
    self.lidOpenStatus = false
    self.isBatched = false -- 是否批量填充
    self.isAction = true        --是否在运动中
    self.rewardsData = {}
    self.consumeEggsTable = {}
    self.goodsKeyIndex = {}       --消耗
    self.ownEggsTable = {}       --拥有的堕神蛋的表
    self.cloneOwnEggsTable = {}  --克隆堕神蛋的的数据
    self.batchData = {}          --批量删除的数据
end
function PetSmeltingMediator:InterestSignals()
    local signals = {
        POST.PET_FUSION.sglName
    }

    return signals
end
function PetSmeltingMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.PET_FUSION.sglName then
        local requestData =body.requestData
        if requestData.petEggs and type(requestData.petEggs) == "string" then
            requestData.petEggs = json.decode(requestData.petEggs)
        else
            requestData.petEggs = {}
        end
        local consumeData = {}
        for i, v in pairs(requestData.petEggs) do
            consumeData[#consumeData+1] = {
                goodsId = i ,
                num = -v
            }
        end
        CommonUtils.DrawRewards(consumeData)
        CommonUtils.DrawRewards(body.rewards)
        self.rewardsData = body.rewards

        self:UpdateOwnEggsTableByData(requestData.petEggs or {})
        self:UpdatePetDevelopMediatorPetEggsData(requestData.petEggs or {})
        self:CleanConsumeData()
        self:updateConsumeGridView()
        self:UpdatePetEggGridView()
        self:SmeltingSpineActionBefore()

    end
end
function PetSmeltingMediator:UpdatePetDevelopMediatorPetEggsData(data)
    local mediator = self:GetFacade():RetrieveMediator("PetDevelopMediator")
    if mediator then
        if mediator.petEggsData then
            for i, v in pairs(mediator.petEggsData) do
                local num = data[tostring(v.goodsId)]
                if num and  checkint(num) > 0   then
                    v.amount = checkint(v.amount) - num
                end
            end
            for i = table.nums(mediator.petEggsData) ,1, -1  do
                local v = mediator.petEggsData[i]
                if checkint(v.amount) <=  0   then
                    table.remove(mediator.petEggsData , i )
                end
            end
        end
    end
end
function PetSmeltingMediator:SortPetEggByFusionNums()
    local ownEggsTable =   gameMgr:GetAllGoodsDataByGoodsType(GoodsType.TYPE_PET_EGG)
    table.sort(ownEggsTable , function(a, b)
        local dataA = petConfig[tostring(a.goodsId)]
        local dataB = petConfig[tostring(b.goodsId)]
        if checkint(dataA.fusionUnit) >=   checkint(dataB.fusionUnit) then
            return false
        end
        return true
    end)
    return ownEggsTable
end

function PetSmeltingMediator:Initial( key )
    self.super.Initial(self,key)

    local viewComponent = require("Game.views.pet.PetSmeltingView").new({callbackSpine = handler(self, self.SpineAction)})
    viewComponent:setPosition(display.center)
    ---@type PetSmeltingView
    self.viewComponent = viewComponent
    --uiMgr:GetCurrentScene():AddDialog(viewComponent)
    --viewComponent:setPosition(display.center)
    local gridPetLine = display.isFullScreen and 5 or 4
    local viewData = self.viewComponent.viewData
    display.commonUIParams(viewData.quickBtn, {cb = handler(self, self.ButtonAction) })
    display.commonUIParams(viewData.batchBtn, {cb = handler(self, self.ButtonAction) })
    display.commonUIParams(viewData.cleanSmleterBtn, {cb = handler(self, self.ButtonAction) })
    display.commonUIParams(viewData.smeltingBtn, {cb = handler(self, self.ButtonAction) })
    self.ownEggsTable = self:SortPetEggByFusionNums()
    self.cloneOwnEggsTable = clone(self.ownEggsTable)
    -- 注册消耗堕神的事件
    viewData.petConsumeGridView:setDataSourceAdapterScriptHandler(handler(self, self.OnPetEggConsumeDataSource))
    local countCell =  #self.cloneOwnEggsTable > 0 and ( #self.cloneOwnEggsTable + gridPetLine) or  #self.cloneOwnEggsTable
    viewData.petEggdGridView:setCountOfCell(countCell )
    viewData.petEggdGridView:setDataSourceAdapterScriptHandler(handler(self, self.OnPetEggDataSource ))
    viewData.petEggdGridView:reloadData()
    local backPurgeBtn = viewData.backPurgeBtn
    backPurgeBtn:setOnClickScriptHandler(handler(self,self.ButtonAction))
end

function PetSmeltingMediator:SpineAction(event)
    if not self.viewComponent or tolua.isnull(self.viewComponent) then
        return
    end
    local leftBgImage =self.viewComponent.viewData.leftBgImage
    if event.animation == "idle2" then
        self.lidOpenStatus = true
        --leftBgImage:addAnimation(0,'play',false)
    elseif event.animation == "play" then
        self.lidOpenStatus = false
        self:SmeltingSpineActionComplete()
        leftBgImage:setToSetupPose()
        leftBgImage:setAnimation(0,'idle',true)
    elseif event.animation == "yidong1" then
        local viewData = self.viewComponent.viewData
        local detailLayout  = viewData.detailLayout
        local progressOne  = viewData.progressOne
        local cleanSmleterBtn  = viewData.cleanSmleterBtn
        local rightLayout  = viewData.rightLayout
        local leftBottomLayout  = viewData.leftBottomLayout
        progressOne:setVisible(true)
        detailLayout:setVisible(true)
        cleanSmleterBtn:setVisible(true)
        leftBottomLayout:setVisible(true)
        rightLayout:setVisible(true)

        rightLayout:setOpacity(0)
        leftBottomLayout:setOpacity(0)
        progressOne:setOpacity(0)
        detailLayout:setOpacity(0)
        cleanSmleterBtn:setOpacity(0)
        detailLayout:runAction(cc.Spawn:create(
                cc.FadeIn:create(0.2),
                cc.Sequence:create(
                    cc.ScaleTo:create(0.2, 1),
                    cc.CallFunc:create(function()

                         self.isAction = false
                    end)
                ),
                cc.TargetedAction:create(cleanSmleterBtn , cc.FadeIn:create(0.2)),
                cc.TargetedAction:create(progressOne , cc.FadeIn:create(0.2)),
                cc.TargetedAction:create(progressOne , cc.FadeIn:create(0.2)),
                cc.TargetedAction:create( rightLayout, cc.Sequence:create(cc.DelayTime:create(0.1), cc.FadeIn:create(0.1)) ),
                cc.TargetedAction:create( leftBottomLayout, cc.Sequence:create(cc.DelayTime:create(0.1), cc.FadeIn:create(0.1)) )
        ))
        leftBgImage:setToSetupPose()
        leftBgImage:setAnimation(0,'idle',true)
    elseif event.animation == "yidong2" then
        leftBgImage:setToSetupPose()
        leftBgImage:setVisible(false)
        local mediator = self:GetFacade():RetrieveMediator("PetDevelopMediator")
        if mediator then
            mediator.selectedModuleType = nil
            --self:GetFacade():UnRegsitMediator(NAME)
            mediator:RefreshMuduleByModuleType(PetModuleType.PURGE, true)
        end
    end
end
--[[
    spine 动画开始前
--]]
function PetSmeltingMediator:SmeltingSpineActionBefore()
    local viewData = self.viewComponent.viewData
    local cleanSmleterBtn =  viewData.cleanSmleterBtn
    local progressOne =  viewData.progressOne
    local leftBgImage = viewData.leftBgImage
    local detailLayout  = viewData.detailLayout
    detailLayout:runAction(cc.Spawn:create(
        cc.FadeOut:create(0.2),
        cc.Sequence:create(
            cc.ScaleTo:create(0.2,0.2),
                 cc.CallFunc:create(function()
                     leftBgImage:setToSetupPose()
                     leftBgImage:setAnimation(0,'play',false)

                 end
             )
        ),
        cc.TargetedAction:create(cleanSmleterBtn , cc.FadeOut:create(0.2)),
        cc.TargetedAction:create(progressOne , cc.FadeOut:create(0.2))
    ))
end
--[[
    spine 完成后
--]]
function PetSmeltingMediator:SmeltingSpineActionComplete()
    local viewData = self.viewComponent.viewData
    local cleanSmleterBtn =  viewData.cleanSmleterBtn
    local progressOne =  viewData.progressOne
    uiMgr:AddDialog("common.RewardPopup",
    { rewards =  self.rewardsData , addBackpack = false, closeCallback = function()
        local viewData = self.viewComponent.viewData
        local detailLayout  = viewData.detailLayout
        detailLayout:runAction(cc.Spawn:create(
            cc.FadeIn:create(0.2),
            cc.Sequence:create(
                cc.ScaleTo:create(0.2, 1),
                cc.CallFunc:create(function()
                    self.isAction = false
                end)
            ),
            cc.TargetedAction:create(cleanSmleterBtn , cc.FadeIn:create(0.2)),
            cc.TargetedAction:create(progressOne , cc.FadeIn:create(0.2))
        ))
    end })

end
function PetSmeltingMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if self.isAction then
        return
    end
    if tag == BUTTON_TAG.QUICK_CONSUME_PET_EGGS then
        self.isBatched = false
        self:CleanConsumeData()
        self:SwitchLidOpenSpineActcon()
        self:QuickConsumePetEgg()
    elseif tag == BUTTON_TAG.BATCH_CONSUME_PET_EGGS then
        self.isBatched = true
        self:CleanConsumeData()
        self:UpdatePetEggGridView()
        self:updateConsumeGridView()
    elseif tag == BUTTON_TAG.CLEAN_PET_EGGS then
        if #self.consumeEggsTable == 0 then
            uiMgr:ShowInformationTips(__('熔炉内没有灵体~'))
            return
        end
        self:SwitchLidCloseSpineActcon()
        self:CleanConsumeData()
        self:updateConsumeGridView()
        self:UpdatePetEggGridView()
    elseif tag == BUTTON_TAG.SMELTING_EGGS then
        self:SmeltingPetEggs()
    elseif tag == BUTTON_TAG.BACK_PURGE then
        local viewData = self.viewComponent.viewData
        local backPurgeBtn = viewData.backPurgeBtn
        backPurgeBtn:setEnabled(false)
        backPurgeBtn:setVisible(false)
        self:FadeOutLayerAction()
    end
end
--[[
    切换盖子打开的状态
--]]
function PetSmeltingMediator:SwitchLidOpenSpineActcon()
    local viewData =   self.viewComponent.viewData
    if not  self.lidOpenStatus then
        self.lidOpenStatus = true
        viewData.leftBgImage:setToSetupPose()
        viewData.leftBgImage:setAnimation(0,'idle2', false)
    end
end
--[[
    切换盖子关闭的状态
--]]
function PetSmeltingMediator:SwitchLidCloseSpineActcon()
    local viewData =   self.viewComponent.viewData
    if self.lidOpenStatus then
        self.lidOpenStatus = false
        viewData.leftBgImage:setToSetupPose()
        viewData.leftBgImage:setAnimation(0,'idle', true )
    end
end
--[[
    熔炼
--]]
function PetSmeltingMediator:SmeltingPetEggs()
    local gride =  self:GetFusionGrade()
    local needGrade = self:GetNeedFusionGrade()
    if gride >= needGrade then
        local data = {}
        for i, v in pairs(self.consumeEggsTable) do
            if v.egg then
                data[tostring(v.egg.goodsId)] = v.egg.amount
            end
        end
        local modGride = gride %100
        -- 如果大于五 去除无用的堕神
        local consumeTable = {}
        if modGride >= 5  then
            for goodsId, num  in pairs(data) do
                local petOneConfig = petConfig[tostring(goodsId)]
                local fusionUnit =  checkint(petOneConfig.fusionUnit)
                if modGride / fusionUnit  > num   then
                    consumeTable[tostring(goodsId)] = num
                    modGride = modGride -  num * fusionUnit
                else
                    consumeTable[tostring(goodsId)] = math.floor( modGride / fusionUnit)
                    break
                end
            end
            for goodsId, num  in pairs(consumeTable) do
                data[tostring(goodsId)] = data[tostring(goodsId)] - num
                if data[tostring(goodsId)] <= 0  then
                    data[tostring(goodsId)] = nil
                end
            end
        end
        self.isAction = true
        self:SendSignal(POST.PET_FUSION.cmdName ,{ petEggs = json.encode( data)  })
    else
        uiMgr:ShowInformationTips(__('灵司不足，不能熔炼'))
    end
end
--[[
    快速填充
--]]
function PetSmeltingMediator:QuickConsumePetEgg()
    local gride =  self:GetFusionGrade()
    local needGrade = self:GetNeedFusionGrade()
    if gride >= needGrade then
        uiMgr:ShowInformationTips(__('灵司已充足，不需要快速填充'))
        return
    end
    self:CleanConsumeData()
    local goodsId = nil
    local amount = nil
    local fusionGrade = nil
    local petOneConfig = nil
    -- 获取到需要的分数

    for i =1 , #self.cloneOwnEggsTable do
        goodsId = self.cloneOwnEggsTable[i].goodsId
        amount = self.cloneOwnEggsTable[i].amount
        petOneConfig= petConfig[tostring(goodsId)]
        if petOneConfig then
            fusionGrade = checkint(petOneConfig.fusionUnit)
            if checkint(fusionGrade) > 0   then
                local num =  math.ceil( needGrade /fusionGrade)
                if num <= amount  then
                    local data = {}
                    data.index = i
                    data.egg = { amount = num , goodsId = goodsId  }
                    self.consumeEggsTable[#self.consumeEggsTable+1]  = data
                    self.goodsKeyIndex[tostring(goodsId)] = #self.consumeEggsTable
                    self.cloneOwnEggsTable[i].amount = amount - num
                    break
                else
                    local data = {}
                    data.index = i
                    data.egg = { amount = amount , goodsId = goodsId  }
                    self.consumeEggsTable[#self.consumeEggsTable+1]  = data
                    self.goodsKeyIndex[tostring(goodsId)] = #self.consumeEggsTable
                    needGrade = needGrade -  checkint(fusionGrade) * amount
                    self.cloneOwnEggsTable[i].amount = 0
                end
            end
        end
    end
    self:UpdatePetEggGridView()
    self:updateConsumeGridView()

end

function PetSmeltingMediator:OnPetEggDataSource(cell, idx)
    local pcell = cell
    local index = idx +1
    local  petEggData = self.cloneOwnEggsTable[index]
    if not  pcell then
        local  petEggData = self.cloneOwnEggsTable[1]
        local petCellSize =self.viewComponent.viewData.petCellSize
        pcell = CGridViewCell:new()
        pcell:setContentSize(petCellSize)
        pcell:setCascadeOpacityEnabled(true)
        local cellLayout = display.newLayer(petCellSize.width/2 , petCellSize.height/2 ,
                                            { ap = display.CENTER , size = petCellSize,color1 = cc.c4b(0,0,0,0) , enable = true })
        pcell:addChild(cellLayout)
        cellLayout:setName("cellLayout")
        local goodNode =  require('common.GoodNode').new({
                                                             goodsId = petEggData.goodsId,
                                                             amount = petEggData.amount,
                                                             showAmount = true,
                                                         })
        goodNode:setScale((petCellSize.width - 10) / goodNode:getContentSize().width)
        goodNode:setAnchorPoint(display.CENTER)
        goodNode:setPosition(cc.p(petCellSize.width/2, petCellSize.height/2))
        cellLayout:addChild(goodNode)
        goodNode:setName("goodNode")
        local checkBtn = display.newCheckBox(petCellSize.width , petCellSize.height  , {ap = display.RIGHT_TOP,  n = _res('ui/common/common_btn_check_default') ,  s = _res('ui/common/common_btn_check_selected')})
        pcell:addChild(checkBtn,20 )

        goodNode:setCascadeOpacityEnabled(true)

        local selectImage = display.newImageView(_res('ui/common/common_bg_frame_goods_elected.png'),petCellSize.width/2, petCellSize.height/2)
        selectImage:setScale(petCellSize.width / selectImage:getContentSize().width)
        cellLayout:addChild(selectImage)
        selectImage:setName("selectImage")
        selectImage:setVisible(false)

        local clickLayout =   display.newLayer(petCellSize.width/2 , petCellSize.height/2 ,
                                               { ap = display.CENTER , size = petCellSize,color = cc.c4b(0,0,0,0) , enable = true })
        pcell:addChild(clickLayout)
        clickLayout:setName("clickLayout")

        local sorceImage = display.newImageView(_res('ui/pet/smelting/melting_lingsi_1'),10, petCellSize.height - 10,{ ap = display.LEFT_TOP} )
        local scoreSize = sorceImage:getContentSize()
        cellLayout:addChild(sorceImage,20)

        local soceLabel = display.newLabel(scoreSize.width/2 , scoreSize.height/2 , fontWithColor('14',{ ap = display.CENTER ,text = ''}))
        sorceImage:addChild(soceLabel)
        sorceImage:setCascadeOpacityEnabled(true)
        pcell.soceLabel = soceLabel
        pcell.clickLayout = clickLayout
        pcell.sorceImage = sorceImage
        pcell.checkBtn = checkBtn
    end
    xTry(function()
        if index >=1 and index <= #self.cloneOwnEggsTable  then
            pcell:setVisible(true)
            if self.isBatched then
                pcell.checkBtn:setVisible(true)
                if self.batchData[tostring(index)] then
                    pcell.checkBtn:setChecked(true)
                else
                    pcell.checkBtn:setChecked(false)
                end
                pcell.clickLayout:setVisible(false)
            else
                pcell.checkBtn:setVisible(false)
                pcell.checkBtn:setChecked(false)
                pcell.clickLayout:setVisible(true)
            end
            local cellLayout = pcell:getChildByName("cellLayout")
            if cellLayout and ( not tolua.isnull(cellLayout)) then
                local goodNode = cellLayout:getChildByName("goodNode")
                local goodsId = petEggData.goodsId
                local num = petEggData.amount
                goodNode:RefreshSelf({
                                         goodsId = goodsId,
                                         amount = num
                                     })
                local petConfigData = petConfig[tostring(goodsId)] or {}
                display.commonLabelParams(pcell.soceLabel , fontWithColor('14',{text = petConfigData.fusionUnit}))
                local sorce = checkint(petConfigData.fusionUnit) > 4 and 4 or  checkint(petConfigData.fusionUnit)
                pcell.sorceImage:setTexture(_res( string.format('ui/pet/smelting/melting_lingsi_%d' , sorce)))
                -- 如果存在 说明选中
                local selectImage = cellLayout:getChildByName("selectImage")
                if selectImage and (not tolua.isnull(selectImage)) then
                    if self.goodsKeyIndex[tostring(goodsId)] then
                        selectImage:setVisible(true)
                        if goodNode.icon and (not tolua.isnull(goodNode.icon)) then
                            if num > 0  then
                                goodNode.icon:setColor(cc.c3b(255,255,255) )
                            else
                                goodNode.icon:setColor(cc.c3b(80,80,80) )
                            end
                        end
                    else
                        if goodNode.icon and (not tolua.isnull(goodNode.icon)) then
                            goodNode.icon:setColor(cc.c3b(255,255,255) )
                        end
                        selectImage:setVisible(false)
                    end
                end
                local clickLayout = pcell:getChildByName("clickLayout")
                if clickLayout and ( not tolua.isnull(clickLayout)) then
                    clickLayout:setTag(index)
                    clickLayout:setOnClickScriptHandler(handler(self, self.AddPetEggsConsumeClick))
                end
                local checkBtn = pcell.checkBtn
                if checkBtn and ( not tolua.isnull(checkBtn)) then
                    checkBtn:setTag(index)
                    checkBtn:setOnClickScriptHandler(handler(self, self.AddPetBatchConsumeClick))
                end
            end
        elseif  index >  #self.cloneOwnEggsTable  then
            if pcell then
                pcell:setVisible(false)
            end
        end
        
    end,__G__TRACKBACK__)
    return pcell
end
--[[
    获取熔炼的分数
--]]
function PetSmeltingMediator:GetNeedFusionGrade()
    local needCount =100
    --for i, v in pairs(funsionConfig) do
    --    needCount = checkint(v.fusionUnit)
    --    break
    --end
    return needCount
end
function PetSmeltingMediator:AddPetBatchConsumeClick(sender)
    if self.isAction then
        return
    end
    local tag = sender:getTag()
    local isChecked = sender:isChecked()
    if isChecked then
        self.batchData[tostring(tag)] = tag
    else
        self.batchData[tostring(tag)] = nil
    end
    local goodsId = self.cloneOwnEggsTable[tag].goodsId
    local comsumeIndex = self.goodsKeyIndex[tostring(goodsId)]
    
    if isChecked then  -- 添加
        comsumeIndex = table.nums(self.consumeEggsTable) + 1
        if comsumeIndex == nil then return end
        self.consumeEggsTable[comsumeIndex] = {
            index = tag ,
            egg = {
                goodsId =  goodsId,
                amount = self.cloneOwnEggsTable[tag].amount,
            }
        }
        self.cloneOwnEggsTable[tag].amount = 0
        self.goodsKeyIndex[tostring(goodsId)] = comsumeIndex
        --self:updateConsumeGridView()

        self:updateConsumeGridView()
        self:UpdatePetEggsCellByIndex(tag)
        self:SemeltingCellAction(comsumeIndex , tag , true )
    else  -- 去除
        self.goodsKeyIndex[tostring(goodsId)] = nil
        if comsumeIndex == nil then return end
        for goodsId , index in pairs(self.goodsKeyIndex) do
            if checkint(index)  > comsumeIndex then
                self.goodsKeyIndex[tostring(goodsId)] = index - 1
            end
        end
        self.cloneOwnEggsTable[tag].amount =  self.consumeEggsTable[comsumeIndex].egg.amount
        table.remove(self.consumeEggsTable, comsumeIndex)
        self:SwitchLidCloseSpineActcon()
        self:UpdatePetEggsCellByIndex(tag)
        self:updateConsumeGridView()
    end

end
-- 增加堕神蛋消耗的事件
function PetSmeltingMediator:AddPetEggsConsumeClick(sender)
    if self.isAction then
        return
    end
    local count = self:GetFusionGrade()
    local needCount = self:GetNeedFusionGrade()
    if count >=  needCount then
        uiMgr:ShowInformationTips(__('已经达到熔炼要求'))
        return
    end
    local tag = sender:getTag()
    local amount = self.cloneOwnEggsTable[tag].amount
    if checkint(amount) > 0   then
        self:SwitchLidOpenSpineActcon()
        self.cloneOwnEggsTable[tag].amount =   amount  - 1
        self:UpdateAddConsumeTableByOwnIndex(tag)
        self:UpdatePetEggsCellByIndex(tag)
        self:RefreshComsumeCellByPetIndex(tag)
    else
        return
    end
end


function PetSmeltingMediator:GetEggIndexByGoodsId(id)
    for i, v in pairs(self.consumeEggsTable) do
        if checkint(v.egg.goodsId) == checkint(id) and checkint(id) ~=0   then
            return i
        end
    end
    return #self.consumeEggsTable + 1
end

function PetSmeltingMediator:RefreshComsumeCellByPetIndex(petIndex)
    local index = self:GetEggIndexByGoodsId(self.cloneOwnEggsTable[petIndex].goodsId)
    local viewData = self.viewComponent.viewData
    local petConsumeGridView = viewData.petConsumeGridView
    local cellCount = petConsumeGridView:getCountOfCell()
    if cellCount >= index  then
        self:SemeltingCellAction(index  , petIndex)
    else
        self:updateConsumeGridView()
        local cell = petConsumeGridView:cellAtIndex(index -1)
        if cell and (not tolua.isnull(cell)) then
            local cellLayout = cell:getChildByName("cellLayout")
            local goodNode = cellLayout:getChildByName("goodNode")
            if goodNode then
                local amount =  self.consumeEggsTable[index].egg.amount
                local goodsId =  self.consumeEggsTable[index].egg.goodsId
                goodNode:RefreshSelf({
                                         goodsId = goodsId,
                                         amount = amount
                                     })
                self:SemeltingCellAction(index  , petIndex)
            end
        else
            self:SemeltingCellAction(index  , petIndex)
        end
    end
end
function PetSmeltingMediator:SemeltingCellAction(consumeIndex , petIndex , isForce)
    local viewData = self.viewComponent.viewData
    local petEggdGridView = viewData.petEggdGridView
    local petConsumeGridView = viewData.petConsumeGridView
    local detailContent = viewData.detailContent
    local detailLayout = viewData.detailLayout
    local detailLabel = viewData.detailLabel
    local detailLayoutSize = detailLayout:getContentSize()
    local pos = cc.p(detailLayoutSize.width/2 , detailLayoutSize.height/2)

    local worldPos = detailLayout:convertToWorldSpace(pos)
    local cell =  petEggdGridView:cellAtIndex(petIndex-1)
    local cellPos = cc.p(cell:getPosition())

    detailContent:setVisible(true)
    detailLabel:setVisible(false)
    if cell and  ( not tolua.isnull(cell)) then
        local cellWorldPos =  cell:getParent():convertToWorldSpace(cellPos)
        local goodNode = require("common.GoodNode")
                .new({ goodsId = self.cloneOwnEggsTable[petIndex].goodsId , showAmount = false})
        self.viewComponent:addChild(goodNode , 100)
        goodNode:setPosition(cellWorldPos)
        goodNode:setEnabled(false)
        local spawn = {}
        local consumCell =  petConsumeGridView:cellAtIndex(consumeIndex -1)
        if consumCell and  ( not tolua.isnull(consumCell)) then
            local cellLayout = consumCell:getChildByName("cellLayout")
        spawn[#spawn+1] =  cc.TargetedAction:create(cellLayout,
                cc.Sequence:create(
                    cc.DelayTime:create(0.3) ,
                    cc.CallFunc:create(function()
                        self:UpdateConsumeCellByIndex(consumeIndex)
                    end),
                    cc.EaseSineIn:create(cc.Sequence:create(cc.ScaleTo:create(0.1,1.1), cc.ScaleTo:create(0.1, 1)) )
                )
            )
        else
            self:UpdateConsumeCellByIndex(consumeIndex)
        end
        spawn[#spawn+1] = cc.Sequence:create(
            cc.CallFunc:create(function()
                self:UpdatePrograss()
            end)    ,
            cc.Spawn:create(
                    cc.JumpTo:create(0.3, worldPos , 20 , 1),
                    cc.FadeOut:create(0.3),
                    cc.ScaleTo:create(0.3, 0.5 )
            ),
            cc.DelayTime:create(0.2),
            cc.RemoveSelf:create()
        )
        goodNode:runAction(cc.Spawn:create(spawn))
    else
        if not isForce then
            self:UpdateReduceConsumeTableByConsumeIndex(consumeIndex)
        end

    end

end

-- 减少堕神蛋消耗的事件
function PetSmeltingMediator:ReducesPetEggsConsumeClick(sender)
    local tag = sender:getTag()
    local amount = self.consumeEggsTable[tag].egg.amount
    if checkint(amount) > 0  then
        local index = self.consumeEggsTable[tag].index
        self:UpdateReduceConsumeTableByConsumeIndex(tag)
        self:updateConsumeGridView()
        self:UpdatePetEggsCellByIndex(index)
    else
        self:SwitchLidCloseSpineActcon()
        self:updateConsumeGridView()
    end
end
function PetSmeltingMediator:OnPetEggConsumeDataSource(cell, idx)
    local pcell = cell
    local index = idx +1
    local  petEggConsumeData = self.consumeEggsTable[index]
    if index >=1 and index <= #self.cloneOwnEggsTable then
        if not  pcell then
            local petConsumeCellSize =self.viewComponent.viewData.petConsumeCellSize
            pcell = CGridViewCell:new()
            pcell:setCascadeOpacityEnabled(true )
            pcell:setContentSize(petConsumeCellSize)

            local cellLayout = display.newLayer(petConsumeCellSize.width/2 , petConsumeCellSize.height/2 ,
                                                { ap = display.CENTER , size = petConsumeCellSize, enable = true })
            pcell:addChild(cellLayout)
            cellLayout:setName("cellLayout")

            local goodNode =  require('common.GoodNode').new({
                                                                 goodsId = petEggConsumeData.goodsId,
                                                                 amount = petEggConsumeData.amount,
                                                                 showAmount = true,
                                                             })
            goodNode:setScale((petConsumeCellSize.width - 10) / goodNode:getContentSize().width * 0.9 )
            goodNode:setPosition(cc.p(petConsumeCellSize.width/2, petConsumeCellSize.height/2))
            goodNode:setAnchorPoint(display.CENTER)
            cellLayout:addChild(goodNode)
            goodNode:setName("goodNode")
            local clickLayout =   display.newLayer(petConsumeCellSize.width/2 , petConsumeCellSize.height/2 ,
                                                   { ap = display.CENTER , size = petConsumeCellSize,color = cc.c4b(0,0,0,0) , enable = true })
            pcell:addChild(clickLayout)
            clickLayout:setName("clickLayout")

            local image = display.newImageView(_res('ui/union/beastbaby/guild_pet_ico_delete_food.png'),petConsumeCellSize.width,petConsumeCellSize.height+ 5  , {ap = display.RIGHT_TOP})
            goodNode:addChild(image , 100)
            local sorceImage = display.newImageView(_res('ui/pet/smelting/melting_lingsi_1'),15, petConsumeCellSize.height -15,{ ap = display.LEFT_TOP} )
            local scoreSize = sorceImage:getContentSize()
            cellLayout:addChild(sorceImage,20)

            local soceLabel = display.newLabel(scoreSize.width/2 , scoreSize.height/2 , fontWithColor('14',{ ap = display.CENTER ,text = ''}))
            sorceImage:addChild(soceLabel)
            sorceImage:setCascadeOpacityEnabled(true)
            pcell.soceLabel = soceLabel
            pcell.sorceImage = sorceImage

        end
    end
    xTry(function()
        local cellLayout = pcell:getChildByName("cellLayout")
        if cellLayout and ( not tolua.isnull(cellLayout)) then
            local goodNode = cellLayout:getChildByName("goodNode")
            local goodsId = petEggConsumeData.egg.goodsId
            local num = petEggConsumeData.egg.amount
            goodNode:RefreshSelf({
                                     goodsId = goodsId,
                                     amount = num
                                 })
            local petConfigData = petConfig[tostring(goodsId)] or {}
            display.commonLabelParams(pcell.soceLabel , fontWithColor('14',{text = petConfigData.fusionUnit}))
            local sorce  = checkint(petConfigData.fusionUnit) > 4 and 4 or  checkint(petConfigData.fusionUnit)
            pcell.sorceImage:setTexture(_res( string.format('ui/pet/smelting/melting_lingsi_%d' , sorce)))
            -- 如果存在 说明选中
            cellLayout:setTag(index)
            local clickLayout = pcell:getChildByName("clickLayout")
            if clickLayout and ( not tolua.isnull(clickLayout)) then
                clickLayout:setTag(index)
                clickLayout:setOnClickScriptHandler(handler(self, self.ReducesPetEggsConsumeClick))
            end
        end
    end,__G__TRACKBACK__)
    return pcell
end

function PetSmeltingMediator:UpdateConsumeCellByIndex(index)
    if self.viewComponent and (not tolua.isnull(self.viewComponent)) then
        local viewData = self.viewComponent.viewData
        local petEggdGridView =  viewData.petConsumeGridView
        local cell = petEggdGridView:cellAtIndex(index-1)
        if cell and (not tolua.isnull(cell)) then
            local cellLayout = cell:getChildByName("cellLayout")
            if cellLayout and ( not tolua.isnull(cellLayout)) then
                local goodNode = cellLayout:getChildByName("goodNode")
                local goodsId = self.consumeEggsTable[index].egg.goodsId
                local num = self.consumeEggsTable[index].egg.amount
                goodNode:RefreshSelf({
                                         goodsId = goodsId,
                                         amount = num
                                     })
            end
        end
    end
end
-- 更新堕神蛋的某一项数量
function PetSmeltingMediator:UpdatePetEggsCellByIndex(index)
    local viewData = self.viewComponent.viewData
    local petEggdGridView =  viewData.petEggdGridView
    local cell = petEggdGridView:cellAtIndex(index-1)
    if cell and (not tolua.isnull(cell)) then
        local cellLayout = cell:getChildByName("cellLayout")
        if cellLayout and ( not tolua.isnull(cellLayout)) then
            local goodNode = cellLayout:getChildByName("goodNode")
            local goodsId = self.cloneOwnEggsTable[index].goodsId
            local num = self.cloneOwnEggsTable[index].amount
            goodNode:RefreshSelf({
                                     goodsId = goodsId,
                                     amount = num
                                 })
            if self.isBatched then
                local checkBtn = cell.checkBtn
                if self.batchData[tostring(index)] then
                    checkBtn:setChecked(true)
                else
                    checkBtn:setChecked(false)
                end
            end
            -- 如果存在 说明选中
            local selectImage = cellLayout:getChildByName("selectImage")
            if selectImage and (not tolua.isnull(selectImage)) then
                if self.goodsKeyIndex[tostring(goodsId)] then
                    selectImage:setVisible(true)
                    if goodNode.icon and (not tolua.isnull(goodNode.icon)) then
                        if num > 0  then
                            goodNode.icon:setColor(cc.c3b(255,255,255) )
                        else
                            goodNode.icon:setColor(cc.c3b(80,80,80) )

                        end
                    end
                else
                    if goodNode.icon and (not tolua.isnull(goodNode.icon)) then
                        goodNode.icon:setColor(cc.c3b(255,255,255) )
                    end
                    selectImage:setVisible(false)
                end
            end

        end
    end
end

-- 更新要消耗的堕神蛋
function PetSmeltingMediator:updateConsumeGridView()
    local viewData = self.viewComponent.viewData
    local count = table.nums(self.consumeEggsTable)
    if count > 0    then
        viewData.detailContent:setVisible(true)
        viewData.detailLabel:setVisible(false)
        viewData.cleanSmleterBtn:setVisible(true)
    else
        viewData.detailContent:setVisible(false)
        viewData.detailLabel:setVisible(true)
    end
    viewData.petConsumeGridView:setCountOfCell(count)
    viewData.petConsumeGridView:reloadData()
    self:UpdatePrograss()
end

function PetSmeltingMediator:UpdatePetEggGridView()
    local viewData = self.viewComponent.viewData
    local petEggdGridView = viewData.petEggdGridView
    local grirdLine = display.isFullScreen and 5 or 4
    local count = #self.cloneOwnEggsTable > 1 and ( #self.cloneOwnEggsTable + grirdLine) or #self.cloneOwnEggsTable
    petEggdGridView:setCountOfCell(count )
    petEggdGridView:reloadData()

end

--[[
    更新进度条的显示
--]]
function PetSmeltingMediator:UpdatePrograss()
    local count = self:GetFusionGrade()
    local needCount = self:GetNeedFusionGrade()
    local viewData = self.viewComponent.viewData
    viewData.progressOne:setMaxValue(needCount)
    viewData.progressOne:setValue( checkint(count >= needCount and needCount or  count )  )
    display.commonLabelParams(viewData.progressOneLabel , {text = string.format(__('熔炉容量:%d/%d 灵司') ,count  , needCount ) })
    local smeltingBtn = viewData.smeltingBtn
    if count >= needCount   then
        smeltingBtn:setNormalImage(_res('ui/common/common_btn_orange'))
        smeltingBtn:setSelectedImage(_res('ui/common/common_btn_orange'))
        smeltingBtn:setDisabledImage(_res('ui/common/common_btn_orange'))
    else
        smeltingBtn:setNormalImage(_res('ui/common/common_btn_orange_disable'))
        smeltingBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable'))
        smeltingBtn:setDisabledImage(_res('ui/common/common_btn_orange_disable'))
    end
end
--[[
    获取到熔炼的分数
--]]
function PetSmeltingMediator:GetFusionGrade()
    local count = 0
    for i, v in pairs(self.consumeEggsTable) do
        if v.egg and checkint(v.egg.goodsId) > 0   then
            local petOneConfig = petConfig[tostring(v.egg.goodsId)]
            count = count + checkint(petOneConfig.fusionUnit) *  checkint(v.egg.amount)
        end
    end
    return count
end
--[[
    更新已经拥有的蛋的数据
--]]
function PetSmeltingMediator:UpdateOwnEggsTableByData(data)
    for i, v in pairs(self.ownEggsTable) do
        local num = data[tostring(v.goodsId)]
        if checkint(num) >  0     then
            v.amount = checkint(v.amount)  -  checkint(num)
        end
    end
    for i = #self.ownEggsTable,  1 , -1 do
        if checkint(self.ownEggsTable[i].amount ) <= 0  then
            table.remove(self.ownEggsTable, i )
        end
    end
end
--  清理消耗数据
function PetSmeltingMediator:CleanConsumeData()
    self.batchData = {}
    self.goodsKeyIndex = {}
    self.consumeEggsTable = {}
    self.cloneOwnEggsTable = clone(self.ownEggsTable)
end
-- 添加消耗petEgg
function PetSmeltingMediator:UpdateAddConsumeTableByOwnIndex(index)
    local goodsId = self.cloneOwnEggsTable[index].goodsId
    if checkint(goodsId) > 0  then
        local comsumeIndex = self.goodsKeyIndex[tostring(goodsId)]
        if comsumeIndex then
            self.consumeEggsTable[comsumeIndex].egg.amount = self.consumeEggsTable[comsumeIndex].egg.amount +1
        else
            local comsumeIndex = table.nums(self.consumeEggsTable) +1
            self.consumeEggsTable[comsumeIndex] = {
                index = index ,
                egg = {
                    goodsId =  goodsId,
                    amount = 1,
                }
            }
            self.goodsKeyIndex[tostring(goodsId)] = comsumeIndex
        end
    end
end

-- 减少消耗petEgg 根基消耗index 
function PetSmeltingMediator:UpdateReduceConsumeTableByConsumeIndex(index)
    self.consumeEggsTable[index].egg.amount = self.consumeEggsTable[index].egg.amount - 1
    local cloneIndex = self.consumeEggsTable[index].index
    self.cloneOwnEggsTable[cloneIndex].amount = self.cloneOwnEggsTable[cloneIndex].amount + 1
    if  self.consumeEggsTable[index].egg.amount <= 0  then
        table.remove(self.consumeEggsTable , index)
        self.goodsKeyIndex = {}
        self.batchData[tostring(cloneIndex)] = nil
        if table.nums(self.consumeEggsTable) > 0  then
            for i = 1, table.nums(self.consumeEggsTable) do
                local data = self.consumeEggsTable[i].egg or {}
                self.goodsKeyIndex[tostring(data.goodsId)] = i
            end
        end
    end
end
function PetSmeltingMediator:FadeOutLayerAction()
    local viewData = self.viewComponent.viewData
    local cleanSmleterBtn =  viewData.cleanSmleterBtn
    local progressOne =  viewData.progressOne
    local leftBgImage = viewData.leftBgImage
    local detailLayout  = viewData.detailLayout
    local leftBottomLayout  = viewData.leftBottomLayout
    local rightLayout  = viewData.rightLayout
    self.isAction = true

    detailLayout:runAction(cc.Spawn:create(
            cc.FadeOut:create(0.2),
            cc.Sequence:create(
                cc.ScaleTo:create(0.2,0.2),
                cc.CallFunc:create(function()
                    leftBgImage:setToSetupPose()
                    leftBgImage:setAnimation(0, "yidong2",false)
                end
                )
            ),
            cc.TargetedAction:create(cleanSmleterBtn , cc.FadeOut:create(0.2)),
            cc.TargetedAction:create(progressOne , cc.FadeOut:create(0.2)),
            cc.TargetedAction:create( leftBottomLayout, cc.FadeOut:create(0.2)),
            cc.TargetedAction:create( rightLayout, cc.Sequence:create(cc.DelayTime:create(0.1), cc.FadeOut:create(0.1)) )
    ))

end

function PetSmeltingMediator:OnRegist(  )
    regPost(POST.PET_FUSION)  -- 堕神熔炼
end
function PetSmeltingMediator:OnUnRegist()
    unregPost(POST.PET_FUSION)
    if self.viewComponent and (not tolua.isnull(self.viewComponent) )  then
        if self.isRemove  then
            return
        end
        self.isRemove = true
        self.viewComponent:stopAllActions()
        self.viewComponent:runAction(cc.Sequence:create (cc.DelayTime:create(0.1), cc.RemoveSelf:create()))
        self.viewComponent = nil
    end
end

return PetSmeltingMediator