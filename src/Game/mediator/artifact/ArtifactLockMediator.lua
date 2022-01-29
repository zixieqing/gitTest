--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class ArtifactLockMediator :Mediator
local ArtifactLockMediator = class("ArtifactLockMediator", Mediator)
local NAME = "ArtifactLockMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type ArtifactManager
local artifactMgr = AppFacade.GetInstance():GetManager("ArtifactManager")

local BUTTON_TAG = {
    BACK_BTN       = 1003, -- 返回按钮
    UNLOCK_BTN     = 1004, -- 解锁按钮
    TRAIL_BTN      = 1005, -- 试炼
    CLICK_ARTIFACT = 1006, -- 点击神器的时候
    TIPS_BUTTON    = 1007, -- tips提示
}
local ARTIFACT_SPINE = {
    UNLOCK_ONE = 'effects/artifact/jiesuo1',
    UNLOCK_TWO = 'effects/artifact/jiesuo2'
}

function ArtifactLockMediator:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)
    local  playerCardId = param.playerCardId
    self.cardTable  = artifactMgr:GetOnwerCards()
    self.index     = artifactMgr:GetListCardSelectCardIndex(self.cardTable , playerCardId) or 1
    self.cardId    = self.cardTable[self.index].cardId  -- 当前选择的cardId
    self.isAction = false
    self.isClear = true
end

function ArtifactLockMediator:InterestSignals()
    local signals = {
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT  ,
        POST.ARTIFACT_UNLOCK.sglName 
    }
    return signals
end

function ArtifactLockMediator:ProcessSignal( signal )
    local name = signal:GetName()
    if name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:UpdateUI()
    elseif name == POST.ARTIFACT_UNLOCK.sglName then
        local cardData = self.cardTable[self.index]
        cardData.isArtifactUnlock = 1
        gameMgr:UpdateCardDataById(cardData.id , cardData)
        local data = artifactMgr:GetArtifactConsumeByCardId(self.cardId)
        data.num = - checkint(data.num)
        CommonUtils.DrawRewards({data})
        local viewComponent = self.viewComponent
        viewComponent:setTag(1111)
        viewComponent:setLocalZOrder(1000)
        local layer = display.newLayer(display.cx , display.cy , {ap = display.CENTER , size = display.size,color = cc.c4b(0,0,0,0), enable = true })
        uiMgr:GetCurrentScene():AddDialog(layer)
        layer:setVisible(false)
        layer:setName("artifactLayer")
        self.isClear = false
        local mediator = require("Game.mediator.artifact.ArtifactTalentMediator").new({playerCardId = self.cardTable[self.index].id})
        self:GetFacade():RegistMediator(mediator)
        local viewData = self.viewComponent.viewData
        local unlockOne = viewData.unlockOne
        local unlockTwo = viewData.unlockTwo
        local markImage = viewData.markImage
        unlockOne:setAnimation(0, 'play',false)
        unlockTwo:setAnimation(0, 'play',false)
        markImage:setVisible(false)
    end
end

function ArtifactLockMediator:Initial( key )
    self.super.Initial(self,key)
    -- 首先加载spine 进入缓存
    SpineCache(SpineCacheName.ARTIFACT):addCacheData(ARTIFACT_SPINE.UNLOCK_ONE, ARTIFACT_SPINE.UNLOCK_ONE, 1)
    SpineCache(SpineCacheName.ARTIFACT):addCacheData(ARTIFACT_SPINE.UNLOCK_TWO, ARTIFACT_SPINE.UNLOCK_TWO, 1)
    ---@type ArtifactLockScene
    local viewComponent = require("Game.views.artifact.ArtifactLockScene").new()
    uiMgr:SwitchToScene(viewComponent)
    self.viewComponent = viewComponent
    self:EnterAnmaition()
    local viewData = self.viewComponent.viewData
    display.commonUIParams(viewData.backBtn , { cb = handler(self , self.ButtonAction)})
    display.commonUIParams(viewData.trainBtn , { cb = handler(self , self.ButtonAction)})
    display.commonUIParams(viewData.labelUnlock , { cb = handler(self , self.ButtonAction)})
    display.commonUIParams(viewData.artifactBigImage , { cb = handler(self , self.ButtonAction) , animate = false})
    display.commonUIParams(viewData.artifactBigImage , { cb = handler(self , self.ButtonAction) , animate = false})
    display.commonUIParams(viewData.tabNameLabel , { cb = handler(self , self.ButtonAction) })
    viewData.unlockOne:registerSpineEventHandler(handler(self, self.SpineAction), sp.EventType.ANIMATION_END)
    viewData.unlockTwo:registerSpineEventHandler(handler(self, self.SpineStartAction), sp.EventType.ANIMATION_START)
    self:UpdateUI()
end
function ArtifactLockMediator:SpineStartAction(event)
    if event and event.animation == "play" then
        -- TODO  播放解锁动画 切换到第二个界面
      self:SwitchLayer()
    end

end
function ArtifactLockMediator:SwitchLayer ()
    local viewData = self.viewComponent.viewData
    local artifactBigImage = viewData.artifactBigImage
    local artifactBigParent = artifactBigImage:getParent()
    local endPos =  artifactBigParent:convertToWorldSpace(cc.p(artifactBigImage:getPosition()))
    local layer = uiMgr:GetCurrentScene():GetDialogByName("artifactLayer")
    -- 设置要拷贝渲染屏幕的状态
    local viewComponent = self.viewComponent
    local artifactBigClone = display.newImageView( CommonUtils.GetArtifiactPthByCardId(self.cardId, true),endPos.x , endPos.y)
    layer:addChild(artifactBigClone,1 )
    artifactBigClone:setName("artifactBigClone")

    local bassLabelTips = viewData.bassLabelTips
    local mediator = self:GetFacade():RetrieveMediator("ArtifactTalentMediator")
    local viewData = mediator.viewComponent.viewData
    local artifactBigImage =  viewData.artifactBigImage
    bassLabelTips:setVisible(false)
    local artifactBigParent = artifactBigImage:getParent()
    local endPos =  artifactBigParent:convertToWorldSpace(cc.p(artifactBigImage:getPosition()))
    sceneWorld:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(0.7),
            cc.TargetedAction:create( layer , cc.Show:create()),
            cc.Spawn:create(
                cc.TargetedAction:create(artifactBigClone , cc.Sequence:create(
                    cc.ScaleTo:create(0.5,1.5),
                    cc.Spawn:create(
                        cc.ScaleTo:create(0.5,1),
                        cc.EaseSineIn:create(cc.MoveTo:create(0.5, endPos))
                    ),
                    cc.TargetedAction:create(artifactBigImage , cc.Show:create()),
                    cc.Hide:create()
                )   )
                , cc.TargetedAction:create(viewComponent ,
                    cc.Sequence:create(
                        cc.FadeOut:create(0.5),
                        cc.DelayTime:create(0.5),
                        cc.Hide:create() ,
                        cc.CallFunc:create(
                            function()
                                self:GetFacade():UnRegsitMediator(NAME)
                            end
                        )
                    )
                )
            ), cc.TargetedAction:create( layer , cc.RemoveSelf:create())
        )
    )
end
function ArtifactLockMediator:SpineAction(event)
    if event and event.animation == "play" then

    end
end

function ArtifactLockMediator:createSnapshot_(viewObj)
    -- create the second render texture for outScene
    local texture = cc.RenderTexture:create(display.width, display.height)
    texture:setPosition(display.cx, display.cy)
    texture:setAnchorPoint(display.CENTER)

    -- render outScene to its texturebuffer
    texture:clear(0, 0, 0, 0)
    texture:begin()
    viewObj:visit()
    texture:endToLua()

    local middle = cc.ProgressTimer:create(texture:getSprite())
    middle:setType(cc.PROGRESS_TIMER_TYPE_BAR)
     --Setup for a bar starting from the bottom since the midpoint is 0 for the y
    middle:setMidpoint(cc.p((display.SAFE_R-135) / display.width, (display.height-130) / display.height))
    middle:setMidpoint(display.CENTER)
     --Setup for a vertical bar since the bar change rate is 0 for x meaning no horizontal change
    middle:setBarChangeRate(cc.p(1, 1))
    middle:setPosition(display.cx, display.cy)
    return middle
end
--[[
    获取当前卡牌神器碎片的数量
--]]
function ArtifactLockMediator:GetArtifactFragmentNum()
    local artifactFragmentId = CommonUtils.GetArtifactFragmentsIdByCardId(self.cardId)
    local artifactFragmentNum = CommonUtils.GetCacheProductNum(artifactFragmentId)
    return  artifactFragmentNum
end
--[[
    获取解锁需要的卡牌神器碎片的数量
--]]
function ArtifactLockMediator:GetNeedLockArtifactFragmentNum()
    local needData = artifactMgr:GetArtifactConsumeByCardId(self.cardId)
    local needNum = 100
    if checkint(needData.num) > 0   then
        needNum = needData.num
    end
    return needNum
end
--[[
    获取当前卡牌的cardId
--]]
function ArtifactLockMediator:GetCurrentCardId()
    return  self.cardId
end
--[[
    获取神器的名称
--]]
function ArtifactLockMediator:GetArtifactName()
    return artifactMgr:GetArtifactName(self.cardId)
end

function ArtifactLockMediator:UpdateUI()
    local cardId = self:GetCurrentCardId()
    local cardData = self.cardTable
    local owerNum = self:GetArtifactFragmentNum()
    local needNum = self:GetNeedLockArtifactFragmentNum()
    local viewData = self.viewComponent.viewData
    local progassBar = viewData.progressBarOne
    local progressBarOneLabel = viewData.progressBarOneLabel
    local labelUnlock = viewData.labelUnlock

    local artifactSmallImage = viewData.artifactSmallImage
    local artifactBigImage = viewData.artifactBigImage
    local bassLabel = viewData.bassLabel
    local bassLabelTips = viewData.bassLabelTips
    local unlockTwo = viewData.unlockTwo
    local unlockOne = viewData.unlockOne

    local artBigPath  = CommonUtils.GetArtifiactPthByCardId(cardId , true)
    local artSmallPath = CommonUtils.GetArtifiactPthByCardId(cardId , false)
    local cardName  = CommonUtils.GetConfig('goods','goods', cardId).name or {}
    local artName = self:GetArtifactName()
    labelUnlock:setVisible(false)
    bassLabelTips:setVisible(false)

    unlockOne:setVisible(true)
    unlockTwo:setVisible(true)

    display.commonLabelParams(bassLabel , fontWithColor('14' , {text = artName}))
    if owerNum >= needNum  then
        labelUnlock:setVisible(true )
        display.commonLabelParams(labelUnlock , fontWithColor('10', {text = __('点击开启' ) ,color = "#ffffff" , fontSize = 30}))
        progassBar:setMaxValue(needNum)
        progassBar:setValue(needNum)
        if checkint(cardData.isArtifactUnlock) == 0  then
            unlockTwo:setAnimation(0, "idle2", true)
            unlockOne:setAnimation(0, "idle2", true)
        end
        progressBarOneLabel:setString(string.format("%s/%s" , owerNum , needNum))
    else
        if checkint(cardData.isArtifactUnlock) == 0  then
            unlockTwo:setAnimation(0, "idle", true)
            unlockOne:setAnimation(0, "idle", true)
        end
        bassLabelTips:setVisible(true)
        progassBar:setMaxValue(needNum)
        progassBar:setValue(owerNum)
        progressBarOneLabel:setString(string.format("%s/%s" , owerNum , needNum))
        display.commonLabelParams(bassLabelTips , fontWithColor('14' ,  {fontSize = 30, text = string.fmt(__('解除封印需要 _num_点 _name_ 的能量'), { _num_ = needNum -  owerNum ,_name_ = cardName}  ) , outline = false }))
    end
    artifactBigImage:setTexture(artBigPath)
    artifactSmallImage:setTexture(artSmallPath)

end
function ArtifactLockMediator:ButtonAction(sender)
    if  self.isAction then
        return
    end
    local tag = sender:getTag()
    if tag == BUTTON_TAG.BACK_BTN then
        self:BackClickHandler()
    elseif tag == BUTTON_TAG.TRAIL_BTN then
        self:TrailBtnClick()
    elseif tag == BUTTON_TAG.UNLOCK_BTN then
        self:UnLockArtifact()
    elseif tag == BUTTON_TAG.CLICK_ARTIFACT then
        self:ArtifactClickHandler()
    elseif tag == BUTTON_TAG.TIPS_BUTTON then
        app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.ARTIFACT_TAG)] })
    end
end

function ArtifactLockMediator:EnterAnmaition()
    local viewData = self.viewComponent.viewData
    local spineLayout = viewData.spineLayout
    local energyLayout = viewData.energyLayout
    local bassLayout = viewData.bassLayout
    local contentLayout = viewData.contentLayout
    local unlockOne = viewData.unlockOne
    local bassLabelTips = viewData.bassLabelTips
    local energyLayoutPos =  cc.p(energyLayout:getPosition())
    energyLayout:setPosition(cc.p(energyLayoutPos.x , energyLayoutPos.y - 100))
    bassLabelTips:setOpacity(0)
    bassLayout:setOpacity(0)
    energyLayout:setOpacity(0)
    spineLayout:setOpacity(0)
    local time = 0.7
    contentLayout:setVisible(true)
    unlockOne:setOpacity(0)
    energyLayout:runAction(
        cc.Spawn:create(
            cc.Sequence:create(
                cc.Spawn:create(
                    cc.Sequence:create(
                        cc.JumpTo:create(time - 0.3,energyLayoutPos , 50 ,1 ),
                        cc.DelayTime:create(0.3)
                    ),
                    cc.FadeIn:create(time)
                ),
                cc.DelayTime:create(0.2)
            ),
            cc.TargetedAction:create(spineLayout ,
                cc.Sequence:create(
                    cc.DelayTime:create(0.2),
                    cc.FadeIn:create(time)
                )
            ),
            cc.TargetedAction:create(unlockOne ,
                cc.Sequence:create(
                    cc.DelayTime:create(0.5),
                    cc.FadeIn:create(0.4)
                )
            ),
            cc.TargetedAction:create(bassLabelTips ,
                cc.Sequence:create(
                    cc.DelayTime:create(0.5),
                    cc.FadeIn:create(0.4)
                )
            ),
            cc.TargetedAction:create(bassLayout ,
                cc.Sequence:create(
                    cc.DelayTime:create(0.5),
                    cc.FadeIn:create(0.4)
                )
            )

        )
    )
end

--[[
    返回按钮的事件
--]]
function ArtifactLockMediator:BackClickHandler()
    self:EnterAnmaition()
    local viewData = self.viewComponent.viewData
    viewData.unlockTwo:registerSpineEventHandler(handler(self, self.SpineStartAction), sp.EventType.ANIMATION_START)
    self:GetFacade():RetrieveMediator("Router"):RegistBackMediators(true)
    --self:GetFacade():RetrieveMediator("Router"):Dispatch({} ,
    --                         { name = "CardsListMediatorNew" , sortIndex = 0 ,params = { selectPlayerCardId = self.cardTable[self.index].id , x = 1} } )
end
--[[
    解锁神器事件
--]]
function ArtifactLockMediator:UnLockArtifact()
    self.isAction = true
    local ownerNum = self:GetArtifactFragmentNum()
    local needNUm = self:GetNeedLockArtifactFragmentNum()
    if ownerNum >=  needNUm  then
        --TODO 发送解锁神器的请求
        self:SendSignal(POST.ARTIFACT_UNLOCK.cmdName, {playerCardId = self.cardTable[self.index].id})
    else
        uiMgr:ShowInformationTips(__('神器碎片不足'))
    end
end
function ArtifactLockMediator:ArtifactClickHandler()
    local owerNum = self:GetArtifactFragmentNum()
    local needNum = self:GetNeedLockArtifactFragmentNum()
    local viewData = self.viewComponent.viewData
    local labelUnlock = viewData.labelUnlock
    local bassLabelTips = viewData.bassLabelTips
    local bassLabelTipsPos = viewData.bassLabelTipsPos
    local artifactBigImage = viewData.artifactBigImage
    labelUnlock:setVisible(false)
    bassLabelTips:setVisible(true)
    if owerNum >= needNum then
        labelUnlock:setVisible(true)
    else
        bassLabelTips:stopAllActions()
        bassLabelTips:runAction(cc.Sequence:create(
           cc.CallFunc:create(function()
               bassLabelTips:setScale(0.2)
               bassLabelTips:setOpacity(0 )
               bassLabelTips:setPosition(bassLabelTipsPos)
            end),
           cc.Spawn:create(
               cc.ScaleTo:create(1,1),
               cc.FadeIn:create(1) ,
               cc.TargetedAction:create(artifactBigImage ,
                   cc.EaseBackOut:create(
                       cc.ScaleTo:create(1,1.05)
                   )
               )
           ),
           cc.DelayTime:create(0.5),
           cc.Spawn:create(
               cc.ScaleTo:create(1,0.2),
               cc.FadeOut:create(1),
               cc.TargetedAction:create(artifactBigImage ,
                    cc.Sequence:create(
                        cc.ScaleTo:create(1,1.0)
                    )
               )
           )
        ) )
    end
end
--[[
    试炼按钮的btn
--]]
function ArtifactLockMediator:TrailBtnClick()
    local artifactConfig  = CommonUtils.GetConfigAllMess('card' ,'cards')[tostring(self.cardId)] or ""
    local artifactQuestId =artifactConfig.artifactQuestId or "12001"
    artifactMgr:GoToBattleReadyView(artifactQuestId , "artifact.ArtifactLockMediator" , "artifact.ArtifactLockMediator" ,  self.cardTable[self.index].id )
end



function ArtifactLockMediator:OnRegist()
    regPost(POST.ARTIFACT_UNLOCK)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end
function ArtifactLockMediator:OnUnRegist()
    unregPost(POST.ARTIFACT_UNLOCK)
    if self.isClear then
        SpineCache(SpineCacheName.ARTIFACT):clearCache()
    end

    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return ArtifactLockMediator
