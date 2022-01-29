local Mediator = mvc.Mediator
local NAME = "TastingTourChooseRecipeStyleMediator"
---@class TastingTourChooseRecipeStyleMediator :Mediator
local TastingTourChooseRecipeStyleMediator = class(NAME, Mediator)
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local BUTTON_CLICK = {
    BACK_BTN = 1101,
    REWARD_BTN = RemindTag.TASTINGTOUR_ZONE_REWARD,
    TIP_BUTTON = 1103,

}
---@type TastingTourManager
local tastingTourMgr = AppFacade.GetInstance():GetManager("TastingTourManager")
function TastingTourChooseRecipeStyleMediator:ctor(params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.preIndex = nil
    self.stageId = 1
end

function TastingTourChooseRecipeStyleMediator:InterestSignals()
    local signals = {
       POST.CUISINE_HOME.sglName ,
       SGL.TASTING_TOUR_ZONE_REWARD_LAYER_EVENT
    }

    return signals
end

function TastingTourChooseRecipeStyleMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    --- 拉取home 接口
    if name == POST.CUISINE_HOME.sglName then
        tastingTourMgr:SetStyleHomeData(body)
        self:AnimationView()
        self:CheckTastingTourZoneRed()
    elseif name == SGL.TASTING_TOUR_ZONE_REWARD_LAYER_EVENT then
        self:CheckTastingTourZoneRed()
    end
end

function TastingTourChooseRecipeStyleMediator:Initial(key)
    self.super.Initial(self, key)
    local viewComponent =  uiMgr:SwitchToTargetScene('Game.views.tastingTour.TastingTourChooseRecipeStyleView')
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = cc.p(display.width * 0.5, display.height * 0.5)})
    self:SetViewComponent(viewComponent)
end

function TastingTourChooseRecipeStyleMediator:CheckTastingTourZoneRed()
    local redTable = app.badgeMgr:CheckTastingTourZoneRed()
    local stageConfig = tastingTourMgr:GetConfigDataByName(tastingTourMgr:GetConfigParse().TYPE.STAGE)
    local zoneId = stageConfig[tostring(self.stageId)].zoneId
    ---@type DataManager
    local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
    if checkint(redTable[tostring(zoneId)])  > 0 then
        dataMgr:AddRedDotNofication(tostring(RemindTag.TASTINGTOUR_ZONE_REWARD) ,RemindTag.TASTINGTOUR_ZONE_REWARD, "[料理副本区域奖励]app.badgeMgr:CheckTastingTourZoneRed")
    else
        dataMgr:ClearRedDotNofication(tostring(RemindTag.TASTINGTOUR_ZONE_REWARD) ,RemindTag.TASTINGTOUR_ZONE_REWARD, "[料理副本区域奖励]app.badgeMgr:CheckTastingTourZoneRed")
    end
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0  , tag  = RemindTag.TASTINGTOUR_ZONE_REWARD  })
end

--[[
    页面的动画
--]]
function TastingTourChooseRecipeStyleMediator:AnimationView()
    local viewData = self.viewComponent.viewData
    local topPos = cc.p( viewData.toplayout:getPosition())
    local parentNode = viewData.toplayout:getParent()
    -- 转化顶部
    local topWorldPos = parentNode:convertToWorldSpace(topPos)
    local topHeigt = display.height
    local topStartPos = cc.p(topPos.x , topPos.y + topHeigt -  topWorldPos.y )
    local time = 0.3
    self.viewComponent:runAction(
            cc.Sequence:create(
                cc.CallFunc:create(
                    function ()
                        viewData.toplayout:setPosition(topStartPos)
                        viewData.toplayout:setOpacity(0)
                        viewData.centerLayout:setOpacity(0)
                        viewData.centerLayout:setVisible(true)
                        viewData.toplayout:setVisible(true)
                        viewData.tipButton:setVisible(true)
                        viewData.titleImage:setVisible(true)
                        viewData.tipButton:setOpacity(0)
                        viewData.titleImage:setOpacity(0)
                    end),
                cc.Spawn:create(
                    cc.TargetedAction:create(viewData.toplayout, cc.Sequence:create( cc.Spawn:create(cc.FadeIn:create(time)  , cc.JumpTo:create(time , topPos , -10,1) ))  ),
                    cc.TargetedAction:create(viewData.centerLayout, cc.FadeIn:create(time)),
                    cc.TargetedAction:create(viewData.titleImage, cc.FadeIn:create(time)),
                    cc.TargetedAction:create(viewData.tipButton, cc.FadeIn:create(time))
                ),
                cc.CallFunc:create(
                    function ()
                        local styleData =  tastingTourMgr:GetAllRecipeStyleAndStatus()
                        self.styleData = styleData
                        table.sort(self.styleData, function(a, b )
                            if checkint(a.cookId ) <  checkint(b.cookId)  then
                                return true
                            elseif checkint(a.id ) > checkint(b.id) then
                                return false
                            end
                            return true
                        end)
                        ---@type TastingTourChooseRecipeStyleView
                        local viewComponent  = self:GetViewComponent()
                        local viewData = viewComponent.viewData
                        viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))
                        viewData.gridView:setCountOfCell(#styleData)
                        viewData.gridView:reloadData()
                        viewData.backBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
                        viewData.rewardStarBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
                        viewData.tipButton:setOnClickScriptHandler(handler(self, self.ButtonAction))
                        self:UpdateTopPrograss()
                    end
                )
            )
    )
end
function TastingTourChooseRecipeStyleMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_CLICK.BACK_BTN then
        AppFacade.GetInstance():BackHomeMediator()
    elseif tag == BUTTON_CLICK.REWARD_BTN then
        local stageConfig = tastingTourMgr:GetConfigDataByName(tastingTourMgr:GetConfigParse().TYPE.STAGE)
        local zoneId = stageConfig[tostring(self.stageId)].zoneId
        local mediator = require("Game.mediator.tastingTour.TastingTourZoneRewardMediator").new({zoneId = zoneId})
        self:GetFacade():RegistMediator(mediator)
    elseif tag == BUTTON_CLICK.TIP_BUTTON then
        uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.TASTINGTOUR)]})
    end
end


function TastingTourChooseRecipeStyleMediator:onDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    local data = self.styleData[index]
    if index >=1 and index <= #self.styleData then
        if pCell == nil then
            pCell = self.viewComponent:CreateTableViewCell()
            if index <= 4  then
                pCell.prograssLayout:runAction(cc.Sequence:create(
                    cc.DelayTime:create(0.04* (index - 1)),
                    cc.CallFunc:create(
                        function ()
                            local pos = cc.p(  pCell.prograssLayout:getPosition())
                            pos = cc.p(pos.x , pos.y - 400 )
                            pCell.prograssLayout:setPosition(pos)
                            pCell.prograssLayout:setOpacity(0)
                            pCell.prograssLayout:setVisible(true)
                        end
                    ),
                    cc.Spawn:create(
                            cc.FadeIn:create(0.2) ,
                            cc.JumpBy:create(0.2 , cc.p(0, 400) , 10 , 1)
                    )
                ))
            else
                pCell.prograssLayout:setVisible(true)
            end
        end
        xTry(function()
            local isSelect = checkint(index ) == checkint(self.preIndex)
            self.viewComponent:UpdateCell(pCell , self.styleData[index] , isSelect)
            pCell.bgImage:setOnClickScriptHandler(handler(self, self.SetOnCellClick))
            pCell.bgImage:setTouchEnabled(true)
            if data.isUnlock == 0 then

                pCell.bgImage:setOnClickScriptHandler(function(sender)
                    uiMgr:ShowInformationTips(__("菜谱未获得，无法挑战"))
                end)
            end
            pCell.enterBtn:setOnClickScriptHandler(handler(self, self.SetStageClick))
            pCell.bgImage:setTag( checkint(index))
            pCell.enterBtn:setTag( checkint(data.id))
        end,__G__TRACKBACK__)
    end
    return pCell
end

function TastingTourChooseRecipeStyleMediator:SetStageClick(sender)
    local tag = sender:getTag()
    local stageConfig = tastingTourMgr:GetConfigDataByName(tastingTourMgr:GetConfigParse().TYPE.STAGE)
    local zoneId = stageConfig[tostring(tag)].zoneId
    --- 进入其他界面的接口
    AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "tastingTour.TastingTourChooseRecipeStyleMediator"},
                                                                {name = "tastingTour.TastingTourLobbyMediator" , params = {stageId = tag ,zoneId = zoneId }})

end
function TastingTourChooseRecipeStyleMediator:SetOnCellClick(sender)
    local tag = sender:getTag()
    -- 获取章节的配置
    if tag == self.preIndex then
        return
    end
    local stageConfig = tastingTourMgr:GetConfigDataByName(tastingTourMgr:GetConfigParse().TYPE.STAGE)
    local stageOnConfig =  stageConfig[tostring(tag)]
    if stageOnConfig  then
        local stageData = self.styleData[tag]
        local stageId = stageData.id
        local cell =  sender:getParent():getParent()
        for k ,v in pairs(self.styleData) do
            if checkint(v.id)  == checkint(stageId) then
                self.viewComponent:UpdateCell(cell, self.styleData[k], true )
                break
            end
        end
        --local data = {
        --    {fontSize = 24 , color = '#d2bca7', text = __('每一题达到三星获得')}
        --}
        --local rewardData = stageOnConfig.rewards
        --for i, v in pairs(rewardData) do
        --    local  num = v.num
        --    data[#data+1] =  fontWithColor( '14',{text = " " ..  num})
        --    data[#data+1] = { img = CommonUtils.GetGoodsIconPathById(v.goodsId) , scale = 0.2 , ap = cc.p(-0.25, 0.05) }
        --end
        --local data = {
        --    {fontSize = 24 , color = '#d2bca7', text = stageData.descr}
        --}

        local viewData = self.viewComponent.viewData
        viewData.rewardTitile:setVisible(true)
        display.commonLabelParams(viewData.rewardTitile, {fontSize = 24 , color = '#d2bca7', text = stageData.descr,paddingW = 30  })
        --display.reloadRichLabel(viewData.richLabel , {c = data })
        --CommonUtils.AddRichLabelTraceEffect(viewData.richLabel , nil , nil , {2})
        self.stageId = stageData.id
    end
    if self.preIndex then
        local cell = self.viewComponent.viewData.gridView:cellAtIndex(self.preIndex -1)
        self.viewComponent:UpdateCell(cell, self.styleData[self.preIndex], false )
    end
    self.preIndex = tag
    self:GetFacade():DispatchObservers(SGL.TASTING_TOUR_ZONE_REWARD_LAYER_EVENT, {})
end
--[[
    更新顶部的星级显示
--]]
function TastingTourChooseRecipeStyleMediator:UpdateTopPrograss()

    local configParser = tastingTourMgr:GetConfigParse()
    local stageConfig  = tastingTourMgr:GetConfigDataByName(configParser.TYPE.STAGE)
    local zoneId = 1
    if stageConfig[tostring(self.stageId)] then
        zoneId = stageConfig[tostring(self.stageId)].zoneId
    end
    local questGroupConfig = tastingTourMgr:GetConfigDataByName(configParser.TYPE.QUEST_GROUP)
    local zoneQuestGroup = questGroupConfig[tostring(zoneId)] or {}
    local count = 0
    for i, v in pairs(zoneQuestGroup) do
        count = tastingTourMgr:GetStageCountStarById(i) + count
    end
    local viewData = self.viewComponent.viewData
    local alreadStraNum = tastingTourMgr:GetZoneAlreadyStarNumByZoneId(zoneId)

    viewData.progressBarOne:setMaxValue(count)
    viewData.progressBarOne:setValue(alreadStraNum)
    viewData.prograssLabel:setString(string.format("%s/%s", tostring(alreadStraNum), tostring(count)))
end


function TastingTourChooseRecipeStyleMediator:EnterLayer()
    self:SendSignal(POST.CUISINE_HOME.cmdName,{})
end

-----------------------------------
-- regist/unRegist
function TastingTourChooseRecipeStyleMediator:OnRegist()
    regPost(POST.CUISINE_HOME)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    self:EnterLayer()
end

function TastingTourChooseRecipeStyleMediator:OnUnRegist()
    ---@type GameManager
    app.badgeMgr:CheckTastingTourRed()
    unregPost(POST.CUISINE_HOME)
end
return TastingTourChooseRecipeStyleMediator