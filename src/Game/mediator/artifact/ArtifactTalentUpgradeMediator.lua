--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class ArtifactTalentUpgradeMediator :Mediator
local ArtifactTalentUpgradeMediator = class("ArtifactTalentUpgradeMediator", Mediator)
local NAME = "ArtifactTalentUpgradeMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type ArtifactManager
local artifactMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function ArtifactTalentUpgradeMediator:ctor(param ,  viewComponent )
    self.isClose = false
    self.super:ctor(NAME,viewComponent)
    self.isFull = param.isFull
    self.touchNode = param.touchNode
    self.talentId = param.talentId
    self.level = checkint(param.level)
    self.cardData = param.cardData
    self.cardId = self.cardData.cardId
    self.isAction = true
end

function ArtifactTalentUpgradeMediator:InterestSignals()
    local signals = {
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT ,
        POST.ARTIFACT_TALENT_LEVEL.sglName
    }
    return signals
end

function ArtifactTalentUpgradeMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        local viewComponent = self:GetViewComponent()
        if viewComponent and (not tolua.isnull(viewComponent)) then
            local talentOnePoint = artifactMgr:GetTalentIdPointConfigByCardId(self.cardId)
            local cardData = gameMgr:GetCardDataById(self.cardData.id)
            self.cardData = cardData
            local talentData =  talentOnePoint[tostring(self.talentId)]

            if cardData.artifactTalent[tostring(self.talentId)] and  checkint(talentData.level) <= checkint(cardData.artifactTalent[tostring(self.talentId)].level)  then
                local viewData = self.viewComponent.viewData
                viewData.closeLayer:setEnabled(false)
                viewData.closeLayer:setLocalZOrder(100)
                self:GetFacade():UnRegsitMediator(NAME)
                return
            end
            if self.cardData["artifactTalent"] and self.cardData["artifactTalent"][tostring(self.talentId)]  then
                self.level = self.cardData["artifactTalent"][tostring(self.talentId)].level
                self:UpdateNotTalentLevelView()
            end
        end
    end
end

function ArtifactTalentUpgradeMediator:Initial( key )
    self.super.Initial(self, key)
    ---@type ArtifactLockScene
    local viewComponent = require("Game.views.artifact.ArtifactTalentUpgradeView").new({isFull = self.isFull})
    uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:setPosition(display.center)
    self.viewComponent = viewComponent
    local viewData = self.viewComponent.viewData
    display.commonUIParams(viewData.closeLayer , { animate = false,  cb = function()
        if not self.isAction then
            viewData.closeLayer:setLocalZOrder(100)
            if not self.isClose then
                self.isClose = true
                viewData.closeLayer:setEnabled(false)

                self:GetFacade():UnRegsitMediator(NAME)
            end
        end
    end})
    local worldPos = self:GetTouchNodeWorldPoint()
    self:AddHornTip(worldPos)
    if  self.isFull  then
        self:UpdateFullTalentLevelView()
    else
        self:UpdateNotTalentLevelView()
    end
end
--[[
    更新已经满级的显示
--]]
function ArtifactTalentUpgradeMediator:UpdateFullTalentLevelView()
    local viewData = self.viewComponent.viewData
    local effectName = viewData.effectName
    local effectNumber = viewData.effectNumber
    local effectLabel = viewData.effectLabel
    display.commonLabelParams(effectName , fontWithColor('10' , {text = __('效果') ,color = "#ffffff",  fontSize = 24}))
    local talentOnePoint = artifactMgr:GetTalentIdPointConfigByCardId(self.cardId)
    local talentData = talentOnePoint[tostring(self.talentId)]
    local fullLevel  = checkint(talentData.level)
    local level = 0
    local talents = self.cardData.artifactTalent or {}
    if talents[tostring(self.talentId)] then
        level = checkint(talents[tostring(self.talentId)].level)
    else
        level = 0
    end
    local effectStr = artifactMgr:GetArtifactTalentSkillDescr(self.cardId , self.talentId  ,self.level)
    display.commonLabelParams(effectLabel ,  {text = effectStr , color = "#f9edcc"} )
    effectNumber:setString(string.format("%d/%d" ,level , fullLevel ))
end

--[[
    更新未经满级的显示
--]]
function ArtifactTalentUpgradeMediator:UpdateNotTalentLevelView()
    local viewData = self.viewComponent.viewData
    local effectName = viewData.effectName
    local effectNumber = viewData.effectNumber
    local effectLabel = viewData.effectLabel
    local goodNode = viewData.goodNode
    local goodsLabel = viewData.goodsLabel
    local upgradeBtn = viewData.upgradeBtn
    local talentOnePoint = artifactMgr:GetTalentIdPointConfigByCardId(self.cardId)
    local talentData = talentOnePoint[tostring(self.talentId)]
    local fullLevel  = checkint(talentData.level)
    local level = 0
    local talents = self.cardData.artifactTalent or {}
    if talents[tostring(self.talentId)] then
        level = checkint(talents[tostring(self.talentId)].level)
    else
        level = 0
    end
    effectNumber:setString(string.format("%d/%d" ,level , fullLevel ))
    display.commonLabelParams(effectName , fontWithColor('10' , {text = __('效果') ,color  = "#ffffff", fontSize = 24}))
    local artifactFragmentId = CommonUtils.GetArtifactFragmentsIdByCardId(self.cardId)
    local artifactFragmentNum = CommonUtils.GetCacheProductNum(artifactFragmentId)
    local consumeData = artifactMgr:GetUpgradeNeedArtifactFragmentConsume(self.cardData , self.talentId)
    goodNode:RefreshSelf(consumeData)
    goodNode:setTag(checkint(consumeData.goodsId))
    display.commonUIParams(goodNode , { animate = false ,  cb = function(sender)
        local goodsId = sender:getTag()
        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsId, type = 1 })
    end })
    display.commonLabelParams(upgradeBtn , fontWithColor('14' , {text = level > 0  and __('升级') or __('解锁') }))
    if artifactFragmentNum >=  checkint(consumeData.num ) then
        upgradeBtn:setNormalImage(_res('ui/common/common_btn_orange'))
        upgradeBtn:setSelectedImage(_res('ui/common/common_btn_orange'))
        display.reloadRichLabel( goodsLabel , { c = {
            fontWithColor('14' , { color = "#ffffff" , text = string.format("%d/%d" , checkint(artifactFragmentNum) , checkint(consumeData.num)) })
        }})
        display.commonUIParams(upgradeBtn , {animate = false ,   cb = function()
            if not  self.isAction  then
                self:SendSignal(POST.ARTIFACT_TALENT_LEVEL.cmdName ,{ talentId = self.talentId , playerCardId = self.cardData.id , level = self.level})
            end
        end})
    else
        upgradeBtn:setNormalImage(_res('ui/common/common_btn_orange_disable'))
        upgradeBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable'))
        display.reloadRichLabel( goodsLabel , { c = {
            fontWithColor('14' , { color = "#d23d3d" , text = artifactFragmentNum  }) ,
            fontWithColor('14' , { color = "#ffffff" , text = "/" ..  consumeData.num  }) ,
        }}  )
        display.commonUIParams(upgradeBtn , { animate = false , cb = function()
            uiMgr:ShowInformationTips(__('神器碎片不足'))
        end})
    end
    local effectStr = artifactMgr:GetArtifactTalentSkillDescr(self.cardId , self.talentId  ,self.level)
    display.commonLabelParams(effectLabel, {text = effectStr})
    CommonUtils.AddRichLabelTraceEffect(goodsLabel)
end

--[[
    添加小tips 箭头
--]]
function ArtifactTalentUpgradeMediator:AddHornTip(worldPos )
    local viewData = self.viewComponent.viewData
    local bgLayout =  viewData.bgLayout
    local bgSize   = bgLayout:getContentSize()
    local scaleY = 1
    local pos = cc.p(0,0)
    local hornImage = display.newImageView(_res('ui/common/common_bg_tips_horn'))
    if worldPos.y  > display.cy  then
        scaleY = 1
        bgLayout:setAnchorPoint(display.CENTER_TOP)
        pos = cc.p(bgSize.width/2 ,bgSize.height-2)
        hornImage:setPosition(pos)
    else
        scaleY = -1
        bgLayout:setAnchorPoint(display.CENTER_BOTTOM)
        pos = cc.p(bgSize.width/2 ,3)
        hornImage:setPosition(pos)
    end
    hornImage:setScaleY(scaleY)
    bgLayout:setPosition(worldPos)
    bgLayout:addChild(hornImage)
    self:RunAnimation()
end

function ArtifactTalentUpgradeMediator:RunAnimation()
    local viewData = self.viewComponent.viewData
    local bgLayout =  viewData.bgLayout
    bgLayout:setScaleY(0)
    bgLayout:runAction(
            cc.Sequence:create(
                cc.EaseBackOut:create(cc.ScaleTo:create(0.4, 1, 1)),
                cc.CallFunc:create(function()
                     self.isAction = false
                end)
            )

    )
end


--[[
    得到触摸点的世界坐标系
--]]
function ArtifactTalentUpgradeMediator:GetTouchNodeWorldPoint()
    local pos = cc.p(self.touchNode:getPosition())
    local parentNode = self.touchNode:getParent()
    local worldPos = parentNode:convertToWorldSpace(pos)
    return  worldPos
end
function ArtifactTalentUpgradeMediator:OnRegist()

end
function ArtifactTalentUpgradeMediator:OnUnRegist()
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return ArtifactTalentUpgradeMediator
