---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator = mvc.Mediator
---@class MedalWallMediator :Mediator
local MedalWallMediator = class("MedalWallMediator", Mediator)
local NAME = "MedalWallMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local BUTTON_CLICK = {
    ADD_TROPHY_TAG = 1105 , -- 添加奖杯的Tag
    TROPHY_LAYOUT_TAG = 1106 , -- 奖杯内容弄的显示
    TROPHY_LAYOUT_BG = 1107
}
local CHANGE_TYPE = {
    CHANGE_THROPHY   = 1 ,  -- 更换奖杯
    CHANGE_HEAD = 2 ,  -- 更换头像
    CHANGE_HEAD_FRAME = 3  -- 更换外框

}
local TROPHY_MAX_NUM = 6
function MedalWallMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.datas  = param or  {}
    self.medalWall = self.datas.medalWall or {}
    self.preIndex = nil  -- 上一次点击
    self.exchangeNum = ""
end

function MedalWallMediator:InterestSignals()
    local signals = {
        POST.PERSON_CHANGE_TROPHY.sglName
    }
    return signals
end
function MedalWallMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type MedalWallView
    self.viewComponent = require('Game.views.MedalWallView').new()
    self:SetViewComponent(self.viewComponent)
    self.viewComponent:retain()
    local viewData = self.viewComponent.viewData
    if CommonUtils.JuageMySelfOperation(self.datas.playerId) then
        if CommonUtils.JuageMySelfOperation(self.datas.playerId) then
            for i =1 ,TROPHY_MAX_NUM do
                local node = viewData.contentLayout:getChildByTag(i)
                if node and (not tolua.isnull(node)) then
                    display.commonUIParams(node, { animate = true , cb = handler(self,self.ButtonAction)})
                end
            end
        end
        for i =1 , TROPHY_MAX_NUM do
            if checkint(self.medalWall[tostring(i)]) > 0   then
                self:AddTrophyImage(checkint(self.medalWall[tostring(i)]) , i )

            end
        end
        self:SetAllAddTrophyBtnIsVisible()
    else

        for i =1 , TROPHY_MAX_NUM do
            if checkint(self.medalWall[tostring(i)]) > 0   then
                self:AddTrophyImage(checkint(self.medalWall[tostring(i)]) , i)
            end
        end
        self:SetOtherStatus()
    end
end

function MedalWallMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.PERSON_CHANGE_TROPHY.sglName then
        local requestData = data.requestData
        if requestData then
            local trophyPosition = requestData.trophyPosition
            local trophyId = requestData.trophyId
            if checkint(trophyId) == 0 then
                self.medalWall[tostring(trophyPosition)] = nil
                self:RemoveTrophyImage(trophyPosition)
            else
                local position  = self:GetCardsCurrentPos(trophyId)
                if position ~= 0 then -- 说明该飨灵并没有在飨灵屋内
                    self.medalWall[tostring(position)] = nil
                    self:RemoveTrophyImage(position)
                end
                local currentPosId = self.medalWall[tostring(trophyPosition)]
                if checkint(currentPosId ) ~= 0 then -- 判断当前位置是否有飨灵
                    self:RemoveTrophyImage(trophyPosition)
                    self.medalWall[tostring(trophyPosition)] = nil
                end
                self.medalWall[tostring(trophyPosition)] = trophyId
                self:AddTrophyImage(trophyId ,trophyPosition )
            end
            self:SetAllAddTrophyBtnIsVisible()
        end
    end
end
-- 不是本人跳入的情况
function MedalWallMediator:SetOtherStatus()
    local viewData = self.viewComponent.viewData
    for i = 1, TROPHY_MAX_NUM do
        local index = i
        local  isVisible =   checkint(self.medalWall[tostring(i)]) > 0
        local node = viewData.contentLayout:getChildByTag(index)
        if node and (not tolua.isnull(node)) then
            local addTrophyBtn = node:getChildByTag(BUTTON_CLICK.TROPHY_LAYOUT_BG)
            if addTrophyBtn and (not tolua.isnull(addTrophyBtn)) then
                if not  isVisible then
                    addTrophyBtn:removeFromParent()
                end
            end
        end
    end
end
--[[
    设置所有奖杯添加按钮是否可见
--]]
function MedalWallMediator:SetAllAddTrophyBtnIsVisible()
    for i = 1, TROPHY_MAX_NUM do
        if  checkint(self.medalWall[tostring(i)]) > 0   then
            self:SetOneAddTrophyBtnIsVisible(k ,false )
        else
            self:SetOneAddTrophyBtnIsVisible(k ,true )
        end
    end
end
--[[
    设置具体奖杯添加按钮是否可见
--]]
function MedalWallMediator:SetOneAddTrophyBtnIsVisible(index, isVisible)
    local index = checkint(index)
    local viewData = self.viewComponent.viewData
    local node = viewData.contentLayout:getChildByTag(index)
    if node and (not tolua.isnull(node)) then
        local addTrophyBtn = node:getChildByTag(BUTTON_CLICK.TROPHY_LAYOUT_BG)
        if addTrophyBtn and (not tolua.isnull(addTrophyBtn)) then
            if not  isVisible then
                addTrophyBtn:removeFromParent()
            end
        end
    end
end
function MedalWallMediator:GetCardsCurrentPos(id)
    local pos = 0
    for i, v in pairs(self.medalWall) do
        if checkint(v) ~= 0 and checkint(id) == checkint(v) then
            pos = checkint(i)
            break
        end
    end
    return pos
end
--[[
    添加奖杯的位置
--]]
function MedalWallMediator:AddTrophyImage( id ,index)
    local index = checkint(index)
    local viewData = self.viewComponent.viewData
    local node = viewData.contentLayout:getChildByTag(index)
    if node and (not tolua.isnull(node)) then
        local textureStr = CommonUtils.GetGoodsIconPathById(id)
        local image = display.newImageView(textureStr)
        local nodeSize = node:getContentSize()
        image:setPosition(cc.p(nodeSize.width/2 , nodeSize.height/2-10))
        node:addChild(image)
        image:setTag(BUTTON_CLICK.TROPHY_LAYOUT_TAG)
        local spineAnimation = CommonUtils.GetAchieveRewardsGoodsSpineActionById(id)
        if spineAnimation then
            image:addChild(spineAnimation)
            spineAnimation:setPosition(cc.p(nodeSize.width /2 -10 ,nodeSize.height/2 -20))
        end
        -- 删除下面的添加按钮
        local trophyImage = node:getChildByTag(BUTTON_CLICK.TROPHY_LAYOUT_BG)
        if trophyImage and (not tolua.isnull(trophyImage)) then
            trophyImage:removeFromParent()
        end
    end
end

--function MedalWallMediator:AddSpineAction()
--    local spineAnimation = sp.SkeletonAnimation:create(
--            'effects/CJJB.json',
--            'effects/CJJB.atlas',
--            1
--    )
--   return spineAnimation
--end
--[[
    删除奖杯的位置
--]]
function MedalWallMediator:RemoveTrophyImage(index)
    local index = checkint(index)
    local viewData = self.viewComponent.viewData
    local node = viewData.contentLayout:getChildByTag(index)
    -- 删除奖杯添加添加按钮
    if node and (not tolua.isnull(node)) then
        local trophyImage = node:getChildByTag(BUTTON_CLICK.TROPHY_LAYOUT_TAG)
        if trophyImage and (not tolua.isnull(trophyImage)) then
            trophyImage:removeFromParent()
        end
    end
    local nodeSize = node:getContentSize()
    local TrophyBgImage = display.newImageView(_res('ui/home/infor/personal_information_btn_badge.png') ,nodeSize.width/2 , nodeSize.height /2  )
    node:addChild(TrophyBgImage)
    TrophyBgImage:setTag(BUTTON_CLICK.TROPHY_LAYOUT_BG)
    local TrophyBgImageSize = TrophyBgImage:getContentSize()
    local addTrophyBtn  = display.newButton(TrophyBgImageSize.width/2 , TrophyBgImageSize.height /2  , { n =_res('ui/home/infor/personal_information_ico_badge_add.png'),s =_res('ui/home/infor/personal_information_ico_badge_add.png')  })
    TrophyBgImage:addChild(addTrophyBtn)
    addTrophyBtn:setTag(BUTTON_CLICK.ADD_TROPHY_TAG)
end
function MedalWallMediator:ButtonAction(sender)
    PlayAudioByClickNormal()
    local pos = sender:getTag()
    local playerCardId = checkint(self.medalWall[tostring(pos)])
    local  tempData ={}
    if playerCardId > 0  then  -- 如果当前数据的像数大于零的时候
        tempData.id = playerCardId
        tempData.callback = handler(self, self.chooseHeroCallBack)
        tempData.clickHeroTag = pos
        tempData.teamId = pos
    else
        tempData.callback = handler(self, self.chooseHeroCallBack)
        tempData.clickHeroTag = pos
    end
    tempData.type = CHANGE_TYPE.CHANGE_THROPHY
    local changeHeadOrHeadFrameMediator = require("Game.mediator.ChangeHeadOrHeadFrameMediator")
    local medaitor = changeHeadOrHeadFrameMediator.new(tempData)
    self:GetFacade():RegistMediator(medaitor)

end
function MedalWallMediator:chooseHeroCallBack(data)
    if data then
        if data.id then
            local pos = self:GetCardsCurrentPos(data.id)
            if checkint(pos) == data.clickHeroTag then
                uiMgr:ShowInformationTips(__('飨灵屋没有发生任何改变'))
                return
            end
            self:SendSignal(POST.PERSON_CHANGE_TROPHY.cmdName , {trophyId = data.id ,trophyPosition  =  data.clickHeroTag})
        else
            self:SendSignal(POST.PERSON_CHANGE_TROPHY.cmdName , {trophyPosition  =  data.clickHeroTag})
        end
    end
end
function MedalWallMediator:OnRegist()
    regPost(POST.PERSON_CHANGE_TROPHY)
end

function MedalWallMediator:OnUnRegist()
    unregPost(POST.PERSON_CHANGE_TROPHY)
end
return MedalWallMediator



