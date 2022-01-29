--[[
选择大堂人员。主管，厨师。服务员
--]]
local Mediator = mvc.Mediator
---@class TastingTourSwitchAssistantMediator:Mediator
local TastingTourSwitchAssistantMediator = class("TastingTourSwitchAssistantMediator", Mediator)

local NAME = "TastingTourSwitchAssistantMediator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function TastingTourSwitchAssistantMediator:ctor(params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    params = params or {}
    if params.chooseCardId then
        if gameMgr:GetCardDataById(params.chooseCardId) then
             self.chooseCardId = gameMgr:GetCardDataById(params.chooseCardId).cardId
        end
    end
    self.cellClickTag = 1
    self.cellClickImg = nil
    self.skilCellClickTag = 0
    self.skillData = {}
end


function TastingTourSwitchAssistantMediator:InterestSignals()
    local signals = {
    }
    return signals
end

function TastingTourSwitchAssistantMediator:ProcessSignal(signal )
    local name = signal:GetName()
    local data = signal:GetBody()
end


function TastingTourSwitchAssistantMediator:Initial( key )
    self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
    local viewComponent  = require( 'Game.views.ChooseLobbyPeopleView' ).new({cb = function()
        self:GetFacade():UnRegsitMediator(NAME)
    end })
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)
    -- 如果view 存在
    local view =  self.viewComponent.viewData.view
    view.viewData.closeBtn:setOnClickScriptHandler(
    function ()
        self:GetFacade():UnRegsitMediator(NAME)
    end)
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    self.viewData = viewComponent.viewData

    local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

    viewData.chooseCardBtn:setOnClickScriptHandler(handler(self,self.ChooseCardButtonActions))
    for i,v in ipairs(viewData.buttons) do
        v:setOnClickScriptHandler(handler(self,self.SkillDetailBtnActions))
    end

    self.Tdata = {}
    local Tdata = {}
    local tempData = {}
    local McardsData = {}
    local RcardsData = {}
    for name,val in orderedPairs(gameMgr:GetUserInfo().cards) do
        local cardData = CommonUtils.GetConfig('cards', 'card', val.cardId)
        local qualityId = 1
        if cardData then
            qualityId = checkint(cardData.qualityId)
        end
        val.qualityId = qualityId

        if checkint(self.chooseCardId) == checkint(val.cardId) then
            tempData = val
        else
            if checkint(qualityId) == 1 then
                table.insert(McardsData,val)
            elseif checkint(qualityId) == 2 then
                table.insert(RcardsData,val)
            else
                table.insert(Tdata,val)
            end

        end
    end
    --排序规则： M卡>R卡有技能的>其他卡R卡>SR>UR
    self.Tdata = clone(Tdata)

    sortByMember(self.Tdata, "qualityId", true)

    --local v = CommonUtils.GetBusinessSkillByCardId(cardId, {from = 2 ,   moduleId = CARD_BUSINESS_SKILL_MODEL_COOKCHAPTER })

    for i,v in ipairs(RcardsData) do
        if next(CommonUtils.GetBusinessSkillByCardId(v.cardId, {from = 2 , moduleId = CARD_BUSINESS_SKILL_MODEL_COOKCHAPTER })) ~= nil then
            v.hasSkill = 2
        else
            v.hasSkill = 1
        end
    end
    sortByMember(RcardsData, "hasSkill", true)



    for i,v in ipairs(McardsData) do
        table.insert(self.Tdata,1,v)
    end
    for i,v in ipairs(RcardsData) do
        table.insert(self.Tdata,1,v)
    end

    --将当前装备的卡牌置为第一位
    if table.nums(tempData) > 0 then
        table.insert(self.Tdata,1,tempData)
    end

    gridView:setCountOfCell(table.nums(self.Tdata))
    gridView:reloadData()

    self:UpdataUI(self.Tdata[1])
end


function TastingTourSwitchAssistantMediator:UpdataUI(data)
    local clickCardNode = self.viewData.clickCardNode--选中头像
    local nameLabel = self.viewData.nameLabel--名字
    local operaProgressBar = self.viewData.operaProgressBar--新鲜度叶子
    local vigourLabel = self.viewData.vigourLabel--新鲜度数字
    local chooseCardBtn = self.viewData.chooseCardBtn--
    local dialogue_tips = self.viewData.dialogue_tips--

    if data then
        local cardId = checkint(data.cardId)
        local breakLevel = checkint(data.breakLevel)
        local level = checkint(data.level)
        local vigour = checkint(data.vigour)
        local cardConf = CommonUtils.GetConfig('cards', 'card', cardId) or {}
        nameLabel:setString(tostring(cardConf.name))
        vigourLabel:setString(vigour)
        local maxVigour = app.restaurantMgr:getCardVigourLimit(data.id)
        local ratio = (vigour / maxVigour) * 100
        operaProgressBar:setValue(ratio)
        if data.id then
            local x , y =  clickCardNode:getPosition()
            clickCardNode:removeFromParent()
            local clickCardNode = require('common.CardHeadNode').new({
                                                                         id = data.id ,showActionState = false })
            clickCardNode:setScale(0.73)
            clickCardNode:setPosition(cc.p(x , y ))
            self.viewData.clickCardNode = clickCardNode
            self.viewData.cview:addChild(clickCardNode)
            clickCardNode:setName('clickCardNode')
        else
            clickCardNode:RefreshUI({
                                        cardData = {cardId = cardId,level  = level,breakLevel = breakLevel}
                                    })
        end
        -- 筛选buff效果
        self.skillData = {}
        local tempSkill = CommonUtils.GetBusinessSkillByCardId(cardId, {from = 2 , moduleId  = CARD_BUSINESS_SKILL_MODEL_COOKCHAPTER } )
        if tempSkill then
            self.skillData = tempSkill
            dialogue_tips:setVisible(false)
            for i,v in ipairs(self.viewData.buttons) do
                local tabNameLabel = v:getChildByTag(5)
                local tabLvLabel = v:getChildByTag(6)
                local skillImg = v:getChildByTag(7)
                local unlockLabel = v:getChildByTag(8)
                if tempSkill[i] then
                    v:setVisible(true)
                    v:setEnabled(true)
                    tabNameLabel:setString(tempSkill[i].name)
                    tabLvLabel:setVisible(false)
                    if tempSkill[i].unlock == 0 then
                        v:setEnabled(false)
                        v:setChecked(true)
                        unlockLabel:setString(__('暂未解锁'))
                        local grayFilter = GrayFilter:create()
                        skillImg:setFilter(grayFilter)
                        v:setNormalImage(_res('ui/home/lobby/peopleManage/restaurant_recharge_btn_skill_disabled.png'))
                    else
                        unlockLabel:setString((' '))
                        skillImg:clearFilter()
                        v:setNormalImage(_res('ui/home/lobby/peopleManage/restaurant_recharge_btn_skill_default.png'))
                    end
                    skillImg:setTexture(_res(CommonUtils.GetSkillIconPath(tempSkill[i].skillId)))
                    for j=1,4 do
                        local typeImg = v:getChildByTag(j+10)
                        if tempSkill[i].employee[j] then
                            typeImg:setVisible(true)
                            typeImg:setTexture(_res('ui/home/lobby/peopleManage/restaurant_manage_ico_fight.png'))
                            --typeImg:setTexture(_res('ui/home/lobby/peopleManage/restaurant_manage_ico_'..t[checkint(tempSkill[i].employee[j])]..'.png'))
                        else
                            typeImg:setVisible(false)
                        end

                        if tempSkill[i].unlock == 0 then
                            local grayFilter = GrayFilter:create()
                            typeImg:setFilter(grayFilter)
                        else
                            typeImg:clearFilter()
                        end
                    end
                else
                    v:setVisible(false)
                end
            end
        else
            for i,v in ipairs(self.viewData.buttons) do
                v:setVisible(false)
            end
            dialogue_tips:setVisible(true)
        end
    end
end


function TastingTourSwitchAssistantMediator:HeadCallback(sender)
    PlayAudioByClickNormal()
    local tag = sender:getParent():getTag()
    if self.cellClickImg then
        self.cellClickImg:setVisible(false)
    end
    local selectImg = sender:getParent():getChildByTag(2346)
    selectImg:setVisible(true)
    self.cellClickTag = tag
    self.cellClickImg = selectImg
    self:UpdataUI(self.Tdata[tag])

    for i,v in ipairs(self.viewData.buttons) do
        v:setChecked(false)
    end

    local skillDesView = self.viewData.skillDesView
    skillDesView:setVisible(false)

    self.skilCellClickTag = 0
end
function TastingTourSwitchAssistantMediator:OnDataSourceAction(c, i)
    local cell = c
    local index = i + 1
    local cardHeadNode = nil
    local selectImg = nil
    local id = checkint(self.Tdata[index].id)
    xTry(function()
        if nil == cell then
            cell = CGridViewCell:new()
            cell:setContentSize(self.viewData.gridView:getSizeOfCell())

            cardHeadNode = require('common.CardHeadNode').new({id = checkint(id), showActionState = false})
            cardHeadNode:setScale(0.73)
            cardHeadNode:setPosition(utils.getLocalCenter(cell))
            cardHeadNode:setOnClickScriptHandler(handler(self,self.HeadCallback))
            cell:addChild(cardHeadNode)
            cardHeadNode:setTag(2345)
            cardHeadNode:setName('cardHeadNode_'..index)
            selectImg = display.newImageView(_res('ui/common/common_bg_frame_goods_elected.png'),0,0,{as = false})
            selectImg:setScale(1.2)
            selectImg:setPosition(utils.getLocalCenter(cell))
            cell:addChild(selectImg,1)
            selectImg:setVisible(false)
            selectImg:setTag(2346)
            -- clickImg
        else
            cardHeadNode = cell:getChildByTag(2345)
            cardHeadNode:setName('cardHeadNode_'..index)
            selectImg = cell:getChildByTag(2346)
            selectImg:setVisible(false)
            cardHeadNode:RefreshUI({id = checkint(id), showActionState = false})
        end
        if index == self.cellClickTag then
            selectImg:setVisible(true)
            self.cellClickImg = selectImg
        end

        cell:setTag(index)

    end,__G__TRACKBACK__)
    if cell == nil then
        cell = CGridViewCell:new()
    end
    return cell
end

--替换按钮
function TastingTourSwitchAssistantMediator:ChooseCardButtonActions( sender )
    PlayAudioByClickNormal()
    local id = self.Tdata[self.cellClickTag].id
    self:GetFacade():DispatchObservers(SGL.SWITCH_ASSIATANT_EVENT ,{assistantId = id})
    self:GetFacade():UnRegsitMediator(NAME)
end

--技能详情按钮
function TastingTourSwitchAssistantMediator:SkillDetailBtnActions( sender )
    PlayAudioByClickNormal()
    for i,v in ipairs(self.viewData.buttons) do
        v:setChecked(false)
    end
    local tag = sender:getTag()
    sender:setChecked(true)
    if self.skilCellClickTag == tag then
        return
    end
    local btn = self.viewData.buttons[tag]
    local skillDesView = self.viewData.skillDesView
    local desLabel = self.viewData.desLabel
    skillDesView:setVisible(true)
    skillDesView:setPosition(cc.p(btn:getPositionX()+175,btn:getPositionY()+40))
    desLabel:setString(self.skillData[tag].descr)
    self.skilCellClickTag = tag
end


function TastingTourSwitchAssistantMediator:OnRegist(  )
end

function TastingTourSwitchAssistantMediator:OnUnRegist(  )
    --称出命令
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveGameLayer(self.viewComponent)
end

return TastingTourSwitchAssistantMediator
