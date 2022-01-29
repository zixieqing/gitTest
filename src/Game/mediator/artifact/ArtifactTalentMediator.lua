--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class ArtifactTalentMediator :Mediator
local ArtifactTalentMediator = class("ArtifactTalentMediator", Mediator)
local NAME = "ArtifactTalentMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type ArtifactManager
local artifactMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
local BUTTON_TAG = {
    BACK_BTN      = 1003, -- 返回按钮
    LOOK_DETAIL   = 1004, --查看详情
    TRAIL_BTN     = 1005, --试炼
    RESET_CIRCUIT = 1006, -- 重置回路
    GEM_CALL      = 1007, -- 宝石召唤
    GEM_BACKPACK  = 1008, -- 宝石仓库
    NEXT_ARTIFACT = 1009, -- 下一个神器
    LAST_ARTIFACT = 1010, -- 上一个神器
    TIPS_TAG      = 1011
}
local TALENT_TYPE = {
    SMALL =1 , 
    BIG = 2 ,
}
---宝石颜色（0无1蓝2红3绿4黄5橙6紫）
local GEM_COLOR = {
    BLUE =2 ,
    RED = 3 ,
    GREEN = 6 ,
    YELLOW = 4 ,
    ORAGIN = 1,
    PURPLE = 5

}
local GEM_PATH_TABLE = {
    [tostring(GEM_COLOR.BLUE)]   = { bottomPath = _res(string.format('ui/artifact/card_weapon_gift_slot_L_%s.png', GEM_COLOR.BLUE)),   lockPtah = _res(string.format('ui/artifact/card_weapon_gift_slot_inner_lock_%s.png', GEM_COLOR.BLUE)) },
    [tostring(GEM_COLOR.RED)]    = { bottomPath = _res(string.format('ui/artifact/card_weapon_gift_slot_L_%s.png', GEM_COLOR.RED)),    lockPtah = _res(string.format('ui/artifact/card_weapon_gift_slot_inner_lock_%s.png', GEM_COLOR.RED)) },
    [tostring(GEM_COLOR.GREEN)]  = { bottomPath = _res(string.format('ui/artifact/card_weapon_gift_slot_L_%s.png', GEM_COLOR.GREEN)),  lockPtah = _res(string.format('ui/artifact/card_weapon_gift_slot_inner_lock_%s.png', GEM_COLOR.GREEN)) },
    [tostring(GEM_COLOR.YELLOW)] = { bottomPath = _res(string.format('ui/artifact/card_weapon_gift_slot_L_%s.png', GEM_COLOR.YELLOW)), lockPtah = _res(string.format('ui/artifact/card_weapon_gift_slot_inner_lock_%s.png', GEM_COLOR.YELLOW)) },
    [tostring(GEM_COLOR.ORAGIN)] = { bottomPath = _res(string.format('ui/artifact/card_weapon_gift_slot_L_%s.png', GEM_COLOR.ORAGIN)), lockPtah = _res(string.format('ui/artifact/card_weapon_gift_slot_inner_lock_%s.png', GEM_COLOR.ORAGIN)) },
    [tostring(GEM_COLOR.PURPLE)] = { bottomPath = _res(string.format('ui/artifact/card_weapon_gift_slot_L_%s.png', GEM_COLOR.PURPLE)), lockPtah = _res(string.format('ui/artifact/card_weapon_gift_slot_inner_lock_%s.png', GEM_COLOR.PURPLE)) }

}

local screenType = {
    {bgIcon = 'ui/artifact/card_weapon_bg_shield.png'},
    {bgIcon = 'ui/artifact/card_weapon_bg_power.png'},
    {bgIcon = 'ui/artifact/card_weapon_bg_agility.png'},
    {bgIcon = 'ui/artifact/card_weapon_bg_assist.png'},
}
local ARTIFACT_SPINE = {
    MOUSE  = 'effects/artifact/xiaocangshu',
    ROTATE = 'effects/artifact/anime_cage1',
    FIRE   = 'effects/artifact/anime_cage2',
    ARTIFACT_SPINE_B ='effects/artifact/circle1',
    ARTIFACT_SPINE_F ='effects/artifact/circle2'
}
local GEM_STAGE = {
    LOWER     = 1, -- 低阶
    MIDDLE    = 2, -- 中阶
    HIGH      = 3, -- 高阶
    VERY_HIGH = 4  -- 极高阶

}
function ArtifactTalentMediator:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent )
    param = param or {}
    local  playerCardId = param.playerCardId
    self.iconTable = {}   -- 用于添加的icon的table
    self.preIndex  = nil  -- 前一个选中的按钮
    self.cardTable =  artifactMgr:GetOwnerArtifactCards()
    self.index     = artifactMgr:GetListCardSelectCardIndex(self.cardTable , playerCardId) or 1
    self.cardId    = self.cardTable[self.index].cardId  -- 当前选择的cardId
    self.cardCount = table.nums(self.cardTable)   -- 计算卡牌的总数量
    self.idleAction = nil   -- 神器的动画
end

function ArtifactTalentMediator:InterestSignals()
    local signals = {
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT ,
        POST.ARTIFACT_RESET_TALENT.sglName ,
        POST.ARTIFACT_TALENT_LEVEL.sglName ,
        POST.ARTIFACT_EQUIPGEM.sglName 
    }
    return signals
end

function ArtifactTalentMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body  = signal:GetBody()
    if name == POST.ARTIFACT_TALENT_LEVEL.sglName then
        local requestData = body.requestData
        local talentId = requestData.talentId
        local playerCardId = requestData.playerCardId
        local artifactTalent  = self:GetTalentData()
        local level = checkint(body.level)
        -- 天赋如果存在的话 就直接更新就可以了
        artifactTalent[tostring(talentId)] = artifactTalent[tostring(talentId)] or {}
        artifactTalent[tostring(talentId)].level = checkint(body.level)

        local artifactFragmentId =  CommonUtils.GetArtifactFragmentsIdByCardId(self.cardId)
        local fragmentConsumeNum = checkint(body.fragmentConsumeNum)
        local data = {
            { goodsId =  artifactFragmentId , num =  -fragmentConsumeNum }
        }
        artifactMgr:UpdateTalentLevel(playerCardId , talentId ,level )
        local talentOnePint = artifactMgr:GetTalentIdPointConfigByCardId(self.cardId)
        local talentOneData =talentOnePint[tostring(talentId)]
        local cardConfig = CommonUtils.GetConfigAllMess('card','card')[tostring(self.cardId)]
        local career = 1
        if cardConfig then
            career = checkint(cardConfig.career)
        end
        local talentTreeConfig = artifactMgr:GetTalentPosConfigByCareer(career)
        if talentOneData  then
            local fullLevel  = checkint(talentOneData.level)
            if level >= fullLevel and level > 0  then
                local startPos = talentTreeConfig[tostring(talentId)].location
                self:RefreshTelentIconById(talentId)
                for i, v in pairs(talentOneData.afterTalentId) do
                    if talentTreeConfig[tostring(v)]  then
                        local endPos = talentTreeConfig[tostring(v)].location
                        if endPos and startPos then
                            self:CreateUnlockPrograssTimer(startPos , endPos)
                            -- 更新显示
                            self:RefreshTelentIconById(v)
                        end
                    end
                end
            else
                self:RefreshTelentIconById(talentId)
            end
        end
        CommonUtils.DrawRewards(data)
        
		--刷新图鉴
		self:GetFacade():DispatchObservers(SGL.CARD_COLL_RED_DATA_UPDATE, {cardId = self.cardId, taskType = CardUtils.CARD_COLL_TASK_TYPE.ARTIFACT_OPEN_NUM, addNum = 1})

    elseif name == POST.ARTIFACT_RESET_TALENT.sglName then
        -- 刷新界面道具的显示
        local lastNum = CommonUtils.GetCacheProductNum(DIAMOND_ID)
        local nowNum = body.diamond
        local data = {
            { goodsId =  DIAMOND_ID , num = nowNum - lastNum } ,
        }
        for i, v in pairs(body.backRewards) do
            data[#data+1] = v
        end
        CommonUtils.DrawRewards(data)
        local cardData = self.cardTable[self.index]
        local artifactTalent = clone(self:GetTalentData())
        artifactMgr:ResetArtifactTalent(cardData.id ,  artifactTalent)
        cardData = gameMgr:GetCardDataById(cardData.id)
        self.cardTable[self.index] = cardData
        -- 更新重置后的显示
        self:UpdateTalentTree()
    elseif name == POST.ARTIFACT_EQUIPGEM.sglName then
        local requestData = body.requestData
        local talentId = requestData.talentId
        local playerCardId = checkint(requestData.playerCardId)
        local ownerPlayerCardId = checkint(requestData.ownerPlayerCardId)
        local ownerTalentId = checkint(requestData.ownerTalentId)
        artifactMgr:UpdateGemStoneId(requestData)
        self.cardTable[self.index] = gameMgr:GetCardDataById(self.cardTable[self.index].id)
        -- 如果装备的宝石是同一个神器
        if checkint(ownerPlayerCardId) ==  checkint(playerCardId)  then
            self:RefreshTelentIconById(talentId)
            self:RefreshTelentIconById(ownerTalentId)
        elseif checkint(ownerPlayerCardId) ~=  checkint(playerCardId)  then
            self:RefreshTelentIconById(talentId)
        end
        self:UpdateArtifactSpine()
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        -- 整个界面只更新碎片的显示
        self:UpdateArtifactFragmentNum()
    end
end

function ArtifactTalentMediator:Initial( key )
    self.super.Initial(self,key)
    SpineCache(SpineCacheName.ARTIFACT):addCacheData(ARTIFACT_SPINE.MOUSE, ARTIFACT_SPINE.MOUSE, 1)
    SpineCache(SpineCacheName.ARTIFACT):addCacheData(ARTIFACT_SPINE.FIRE, ARTIFACT_SPINE.FIRE, 1)
    SpineCache(SpineCacheName.ARTIFACT):addCacheData(ARTIFACT_SPINE.ROTATE, ARTIFACT_SPINE.ROTATE, 1)
    SpineCache(SpineCacheName.ARTIFACT):addCacheData(ARTIFACT_SPINE.ARTIFACT_SPINE_B, ARTIFACT_SPINE.ARTIFACT_SPINE_B, 1)
    SpineCache(SpineCacheName.ARTIFACT):addCacheData(ARTIFACT_SPINE.ARTIFACT_SPINE_F, ARTIFACT_SPINE.ARTIFACT_SPINE_F, 1)
    display.removeUnusedSpriteFrames()
    ---@type ArtifactTalentScene
    local viewComponent = require("Game.views.artifact.ArtifactTalentScene").new()
    uiMgr:SwitchToScene(viewComponent)
    self.viewComponent = viewComponent

    local viewData = self.viewComponent.viewData
    display.commonUIParams(viewData.trailBtn , {cb = handler(self, self.ButtonAction) , animate = true })
    display.commonUIParams(viewData.backBtn , {cb = handler(self, self.ButtonAction) , animate = true })
    display.commonUIParams(viewData.leftBtn , {cb = handler(self, self.ButtonAction) , animate = true })
    display.commonUIParams(viewData.nextBtn , {cb = handler(self, self.ButtonAction) , animate = true })
    display.commonUIParams(viewData.resetBtn , {cb = handler(self, self.ButtonAction) , animate = true })
    display.commonUIParams(viewData.lookDetailBtn , {cb = handler(self, self.ButtonAction) , animate = true })
    display.commonUIParams(viewData.gemBackpackBtn , {cb = handler(self, self.ButtonAction) , animate = true })
    display.commonUIParams(viewData.gemCallBtn , {cb = handler(self, self.ButtonAction) , animate = true })
    display.commonUIParams(viewData.artifactBigImage , {cb = handler(self, self.ButtonAction) , animate = true })
    display.commonUIParams(viewData.tabNameLabel , {cb = handler(self, self.ButtonAction) , animate = true })
    self:UpdateUI()
    self:EnterAnimation()
end
--[[
    更新UI 显示的界面
--]]
function ArtifactTalentMediator:UpdateUI()
    self:UpdateTalentTree()
    self:UpdateUIElement()
    self:UpdateArtifactFragmentNum()
    self:UpdateArtifactSpine()
end
--[[
    更新UI 的显示元素
--]]
function ArtifactTalentMediator:UpdateUIElement()
    local cardData = self.cardTable[self.index]
    local cardId = cardData.cardId
    local bigArtifactPath = CommonUtils.GetArtifiactPthByCardId(cardId ,true )
    local smallArtifactPath = CommonUtils.GetArtifiactPthByCardId(cardId ,false )
    local cardName = ""
    local cardConfig = CommonUtils.GetConfigAllMess('card','card')[tostring(cardId)]
    local career = 1
    if cardConfig then
        cardName = cardConfig.name
        career = checkint(cardConfig.career)
    end
    local artifactName = artifactMgr:GetArtifactName(cardId)
    local viewData           = self.viewComponent.viewData
    local cardNameLabel      = viewData.cardName
    local artifactNameLabel  = viewData.artifactName
    local artifactBigImage   = viewData.artifactBigImage
    local artifactSmallImage = viewData.artifactSmallImage
    local leftBtn            = viewData.leftBtn
    local nextBtn            = viewData.nextBtn

    local attackBgImage      = viewData.attackBgImage
    local attackImage        = viewData.attackImage
    local jobImage           = viewData.jobImage
    local circleOneImageSize = viewData.circleOneImageSize
    display.commonLabelParams(artifactNameLabel , { text = artifactName })
    artifactNameLabel:setScale(1.1)
    CommonUtils.SetCardNameLabelStringById(cardNameLabel:getLabel(), cardData.id, viewData.nameLabelParams)
    -- display.commonLabelParams(cardNameLabel , {text = cardName , color = "#f9edcc"})
    artifactBigImage:setTexture(bigArtifactPath)
    print("bigArtifactPath = " ,bigArtifactPath)
    artifactSmallImage:setTexture(smallArtifactPath)
    jobImage:setTexture(screenType[career].bgIcon)
    if career == 2 or career == 3 then
        jobImage:setPosition(circleOneImageSize.width/2+100  ,circleOneImageSize.height/2 -39  )
    elseif career == 1  then
        jobImage:setPosition(circleOneImageSize.width/2+110  ,circleOneImageSize.height/2 -65 )
    elseif career == 4 then
        jobImage:setPosition(circleOneImageSize.width/2+110  ,circleOneImageSize.height/2 -65 )
    end
    attackBgImage:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(cardId))
    attackImage:setTexture(CardUtils.GetCardCareerIconPathByCardId(cardId))
    nextBtn:setVisible(true)
    leftBtn:setVisible(true)
    if self.index == self.cardCount then
        nextBtn:setVisible(false)
    end
    if self.index == 1 then
        leftBtn:setVisible(false)
    end
end
function ArtifactTalentMediator:UpdateArtifactSpine()
    local cardData = self.cardTable[self.index]
    local viewData =self.viewComponent.viewData
    local artifactForeSpine  = viewData.artifactForeSpine
    local artifactBottomSpine  = viewData.artifactBottomSpine
    local idleAction = artifactMgr:CheckGemTalentIsEquipByPlayerCardId(cardData.id) and "max" or 'idle'
    if self.idleAction ~= idleAction then
        self.idleAction = idleAction
        artifactBottomSpine:setToSetupPose()
        artifactForeSpine:setToSetupPose()
        if idleAction ~= "idle"  then
            artifactForeSpine:setOpacity(255)
            artifactForeSpine:setVisible(true )
            artifactForeSpine:setAnimation(0,idleAction , true)
        else
            artifactForeSpine:runAction(cc.Sequence:create(
                cc.FadeOut:create(0.2),
                cc.CallFunc:create(function()
                    artifactForeSpine:setVisible(false )
                end
                )
            ) )

        end
        artifactBottomSpine:setAnimation(0,idleAction , true)
    end
end
--[[
    更新神器碎片的显示
--]]
function ArtifactTalentMediator:UpdateArtifactFragmentNum()

    local smallArtifactId = CommonUtils.GetArtifactFragmentsIdByCardId(self.cardId)
    local smallArtifactNum = CommonUtils.GetCacheProductNum(smallArtifactId)
    local viewData = self.viewComponent.viewData
    local artifactNum = viewData.artifactNum
    artifactNum:setString(tostring(smallArtifactNum) )

end
function ArtifactTalentMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if self.isAction and tag ~= BUTTON_TAG.BACK_BTN then
        return
    end
    if tag == BUTTON_TAG.NEXT_ARTIFACT then

        self.preIndex = self.index
        if self.cardCount > self.index  then
            self.index = self.index +1
        else
            self.index = 1
        end
        self.cardId = self.cardTable[self.index].cardId
        self:SwithArtifactAnimation()
    elseif tag == BUTTON_TAG.LAST_ARTIFACT then

        self.preIndex = self.index
        if self.index  > 1 then
            self.index = self.index - 1
        else
            self.index =  self.cardCount
        end
        self.cardId = self.cardTable[self.index].cardId
        self:SwithArtifactAnimation()
    elseif tag == BUTTON_TAG.LOOK_DETAIL then
        local artifactDetailView = require("Game.views.artifact.ArtifactDetailView").new({playerCardId = self.cardTable[self.index].id})
        artifactDetailView:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(artifactDetailView)
    elseif tag == BUTTON_TAG.RESET_CIRCUIT then
        self:ResetTalentTree()
    elseif tag == BUTTON_TAG.BACK_BTN then
        self:GetFacade():RetrieveMediator("Router"):RegistBackMediators({ selectPlayerCardId = self.cardTable[self.index].id })
        --self:GetFacade():RetrieveMediator("Router"):Dispatch({} , { name = "CardsListMediatorNew" , sortIndex = 0 ,params = { selectPlayerCardId = self.cardTable[self.index].id , x = 1} } )
    elseif tag == BUTTON_TAG.TRAIL_BTN then
        self:TrailBtnClick()
    elseif tag == BUTTON_TAG.GEM_BACKPACK then
        local mediator = require("Game.mediator.artifact.JewelEvolutionMediator").new()
        self:GetFacade():RegistMediator(mediator)
    elseif tag == BUTTON_TAG.GEM_CALL then
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({} , { name ="artifact.JewelCatcherPoolMediator" })
    elseif tag == BUTTON_TAG.TIPS_TAG then
        uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.ARTIFACT_TAG)] })
    end
end
function ArtifactTalentMediator:SwithArtifactAnimation()
    local viewData = self.viewComponent.viewData
    local artifactBigImagePos = viewData.artifactBigImagePos
    local artifactBigImage = viewData.artifactBigImage
    local unlockPathLayer = viewData.unlockPathLayer
    local iconLayer = viewData.iconLayer
    local lockPathLayer = viewData.lockPathLayer
    local jobImage = viewData.jobImage

    local moveBy  = self.index > self.preIndex and  1 or -1
    local distanceX = 60
    local pos = cc.p(-distanceX*moveBy , 0 )
    local time = 0.4
    artifactBigImage:stopAllActions()
    self.isAction = true
    artifactBigImage:runAction(
        cc.Sequence:create(
            cc.EaseSineIn:create(
                cc.Spawn:create(
                    cc.MoveBy:create(time, pos),
                    cc.FadeOut:create(time),
                    cc.TargetedAction:create(unlockPathLayer , cc.FadeOut:create(time)),
                    cc.TargetedAction:create(iconLayer , cc.FadeOut:create(time)),
                    cc.TargetedAction:create(lockPathLayer , cc.FadeOut:create(time)),
                    cc.TargetedAction:create(jobImage , cc.FadeOut:create(time))
                )
            ),
            cc.CallFunc:create(function()
                local nowPos = cc.p(  artifactBigImage:getPosition())
                local pos = cc.p(0,0 )
                if nowPos.x > artifactBigImagePos.x then
                    pos = cc.p( artifactBigImagePos.x - distanceX , nowPos.y)
                else
                    pos = cc.p( artifactBigImagePos.x + distanceX , nowPos.y )
                end
                local bigArtifactPath = CommonUtils.GetArtifiactPthByCardId(self.cardId ,true )
                artifactBigImage:setPosition(pos)
                artifactBigImage:setTexture(bigArtifactPath)
            end),
            cc.DelayTime:create(0.1),
            cc.CallFunc:create(function()
                self:UpdateUI()
            end),
            cc.EaseSineIn:create(
                cc.Spawn:create(
                    cc.MoveTo:create(time, artifactBigImagePos),
                    cc.FadeIn:create(time),
                    cc.TargetedAction:create(unlockPathLayer , cc.FadeIn:create(time)),
                    cc.TargetedAction:create(iconLayer , cc.FadeIn:create(time)),
                    cc.TargetedAction:create(lockPathLayer , cc.FadeIn:create(time)),
                    cc.TargetedAction:create(jobImage , cc.FadeIn:create(time))
                )
            ),
            cc.CallFunc:create(function()
                self.isAction = false
            end
            )
        )
    )
end


function ArtifactTalentMediator:ResetTalentTree()
    -- print('重置按钮')
    local layer = require('Game.views.TalentResetView').new({mediatorName = NAME, tag = 8010  ,params = {
        freeText = __('免费重置') ,
        titleText = __('重置核心') ,
        cosetText = __('幻晶石重置') ,
    }})
    display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
    uiMgr:GetCurrentScene():AddDialog(layer)
    layer:setTag(8010)
    local artifactFragmentNum = tostring(artifactMgr:GetTalentAllConsume(self.cardTable[self.index]))
    local strs = string.split(string.fmt(__('当前在|<_type_>|神器中\n已投入|_num_|神器能量。|要用哪种方式重置呢?'),
                 {['_type_'] = artifactMgr:GetArtifactName(self.cardId),
                  ['_num_'] = artifactFragmentNum}), '|')
    display.reloadRichLabel(layer.viewData.descrLabel, {c =
        {
            {text = strs[1], fontSize = 24, color = '#5c5c5c'},
            {text = strs[2], fontSize = 24, color = '#c24242'},
            {text = strs[3], fontSize = 24, color = '#5c5c5c'},
            {text = strs[4], fontSize = 24, color = '#c24242'},
            {text = strs[5], fontSize = 24, color = '#5c5c5c'},
            {text = strs[6], fontSize = 24, color = '#5c5c5c'}
        }
    })

    local strs2 = string.split(string.fmt(__('损失|_num1_|神器能量\n|回收|_num2_|神器能量'),
                                          {['_num1_'] = artifactFragmentNum - math.floor(artifactFragmentNum* 0.8) , ['_num2_'] =  math.floor(artifactFragmentNum* 0.8)})  , '|')
    display.reloadRichLabel(layer.viewData.freeDescrLabel, {c =
        {
            {text = strs2[1], fontSize = 24, color = '#5c5c5c'},
            {text = strs2[2], fontSize = 24, color = '#c24242'},
            {text = strs2[3], fontSize = 24, color = '#5c5c5c'},
            {text = strs2[4], fontSize = 24, color = '#5c5c5c'},
            {text = strs2[5], fontSize = 24, color = '#c24242'},
            {text = strs2[6], fontSize = 24, color = '#5c5c5c'}
        }
    })
    CommonUtils.SetNodeScale(layer.viewData.freeDescrLabel , {width = 260})
    local strs3 = string.split(string.fmt(__('消耗|_num1_|幻晶石\n|回收全部神器能量'),{['_num1_'] = math.ceil(artifactFragmentNum/10) }), '|')
    display.reloadRichLabel(layer.viewData.diamondDescrLabel,
    {c =
       {
           {text = strs3[1], fontSize = 24, color = '#5c5c5c'},
           {text = strs3[2], fontSize = 24, color = '#c24242'},
           {text = strs3[3], fontSize = 24, color = '#5c5c5c'},
           {text = strs3[4], fontSize = 24, color = '#5c5c5c'}
       }
    })
    CommonUtils.SetNodeScale(layer.viewData.diamondDescrLabel , {width = 260})
    layer.viewData.freeResetBtn:setOnClickScriptHandler(handler(self, self.ResetButtonActions))
    layer.viewData.diamondResetBtn:setOnClickScriptHandler(handler(self, self.ResetButtonActions))
end
function ArtifactTalentMediator:ResetButtonActions(sender)
    local tag = sender:getTag()
    PlayAudioByClickNormal()
    local consumeAllPoint = artifactMgr:GetTalentAllConsume(self.cardTable[self.index])
    local data = {}
    local resetType = 1
    if tag == 8101  then
        local strs = string.split(string.fmt(__('Tips:将损失|_num1_|神器能量，仅回收|_num2_|神器能量'),{['_num1_'] =  math.ceil(consumeAllPoint * 0.2) , ['_num2_'] =  math.floor(consumeAllPoint * 0.8)}), '|')
        data = {
            extra =  {
                {text = strs[1], fontSize = 20, color = '#5c5c5c'},
                {text = strs[2], fontSize = 20, color = '#c24242'},
                {text = strs[3], fontSize = 20, color = '#5c5c5c'},
                {text = strs[4], fontSize = 20, color = '#c24242'},
                {text = strs[5], fontSize = 20, color = '#5c5c5c'}
            }
        }
        data.text =  __('确定要使用免费重置吗?')
        resetType = 2
    elseif tag == 8102 then
        local strs = string.split(string.fmt(__('Tips:将损失|_num1_|幻晶石，回收|_num2_|神器能量'),{['_num1_'] = tostring(math.ceil(consumeAllPoint/10)), ['_num2_'] = consumeAllPoint}), '|')
        data = {
            extra = {
                {text = strs[1], fontSize = 20, color = '#5c5c5c'},
                {text = strs[2], fontSize = 20, color = '#c24242'},
                {text = strs[3], fontSize = 20, color = '#5c5c5c'},
                {text = strs[4], fontSize = 20, color = '#c24242'},
                {text = strs[5], fontSize = 20, color = '#5c5c5c'}
            }
        }
        resetType = 1
        data.text =  __('确定要使用幻晶石重置吗?')
    end

    data.isOnlyOK = false
    local callback = function()
        if consumeAllPoint > 0 then
            if resetType == 1 then
                local diamondNum = CommonUtils.GetCacheProductNum(DIAMOND_ID)
                local count = math.ceil(consumeAllPoint/100)
                if diamondNum < count   then
                    if GAME_MODULE_OPEN.NEW_STORE then
                        app.uiMgr:showDiamonTips()
                    else
                        uiMgr:ShowInformationTips(__('重置神器天赋所需幻晶石不足'))
                    end
                    return
                end
            end
        else
            uiMgr:ShowInformationTips(__('该神器核心并未激活任何节点，不需要重置'))
            return
        end

        self:SendSignal(POST.ARTIFACT_RESET_TALENT.cmdName, { playerCardId = checkint(self.cardTable[self.index].id)  ,  resetType = resetType})
        uiMgr:GetCurrentScene():RemoveDialogByTag(8010)
    end
    data.callback = callback
    local CommonTip  = require( 'common.NewCommonTip' ).new(data)
    CommonTip:setPosition(display.center)
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(CommonTip)

end
--[[
    转化为游戏坐标系
--]]
function ArtifactTalentMediator:ConvertToGemPos(pos)
    return cc.p(checkint(pos.x) ,  (1004 - pos.y))
end
--[[
    更新天赋树
--]]
function ArtifactTalentMediator:UpdateTalentTree()
    if self.preIndex == self.index then
        self:ResetUnLockPathLayer()
        self:RefreshTalentAllIcon()
    else
        --- 重置所有的定位元素
        self:ResetIconLayer()
        self:ResetUnLockPathLayer()
        self:ResetLockPathLayer()
        self.iconTable = {}
        self:AddTalentTree()
        self:RefreshTalentAllIcon()
    end
end
function ArtifactTalentMediator:RefreshTalentAllIcon()
   local talentOnePointConfig = artifactMgr:GetTalentIdPointConfigByCardId(self.cardId)
    for i, v in pairs(talentOnePointConfig) do
        self:RefreshTelentIconById(v.talentId)
    end
    
end
--[[
    清空背景树
--]]
function ArtifactTalentMediator:ResetLockPathLayer()
    local viewData = self.viewComponent.viewData
    local lockPathLayer = viewData.lockPathLayer
    lockPathLayer:removeAllChildren()
end
--[[
    清空背景树
--]]
function ArtifactTalentMediator:ResetUnLockPathLayer()
    local viewData = self.viewComponent.viewData
    local unlockPathLayer = viewData.unlockPathLayer
    unlockPathLayer:removeAllChildren()
end
--[[
    重置icon 图
--]]
function ArtifactTalentMediator:ResetIconLayer()
    local viewData = self.viewComponent.viewData
    local iconLayer = viewData.iconLayer
    iconLayer:removeAllChildren()
end



--[[
    -- 添加已经解锁天赋的路径
    --@ param  starPos 起始位置
    --@ param  endPos  结束位置
--]]
function ArtifactTalentMediator:GetPathImage(starPos , endPos ,path )
    local height = 40
    local middlePoint , angle , distance  =  self:GetRotate(starPos, endPos)
    local image = display.newImageView(path ,  middlePoint.x , middlePoint.y ,{ap = display.CENTER , scale9 = true , size = cc.size(distance , height )})
    image:setRotation(angle)
    return image
end
--[[
    添加锁定的图片
--]]
function ArtifactTalentMediator:AddLockPathImage()
    local viewData = self.viewComponent.viewData
    local lockPathLayer = viewData.lockPathLayer
    local talentOnePoint = artifactMgr:GetTalentIdPointConfigByCardId(self.cardId)
    local cardConfig = CommonUtils.GetConfigAllMess('card','card')[tostring(self.cardId)]
    local career = 1
    if cardConfig then
        career = checkint(cardConfig.career)
    end
    local talentTreeConfig = artifactMgr:GetTalentPosConfigByCareer(career)
    local startPos = nil
    local endPos = nil
    for i, v in pairs(talentOnePoint) do
        startPos =  talentTreeConfig[tostring(v.talentId)].location
        for ii, vv  in pairs(v.afterTalentId) do
            if checkint(vv) > 0    then
                endPos = talentTreeConfig[tostring(vv)].location
                local image =  self:GetPathImage(startPos ,  endPos ,_res('ui/artifact/card_weapon_path_slot') )
                lockPathLayer:addChild(image)
            end
        end
    end
end

function ArtifactTalentMediator:AddTalentIcon()
    local talentOnePoint = artifactMgr:GetTalentIdPointConfigByCardId(self.cardId)
    local viewData = self.viewComponent.viewData
    local iconLayer = viewData.iconLayer
    local cardConfig = CommonUtils.GetConfigAllMess('card','card')[tostring(self.cardId)]
    local career = 1
    if cardConfig then
        career = checkint(cardConfig.career)
    end
    local talentTreeConfig = artifactMgr:GetTalentPosConfigByCareer(career)
    for i, v in pairs(talentOnePoint) do
        local pos = self:ConvertToGemPos(talentTreeConfig[tostring(v.talentId)].location)
        local icon = self:CreateTalentBgStyleAndColor(v.style , v.gemstoneColor[1])
        iconLayer:addChild(icon)
        icon:setPosition(pos)
        self.iconTable[tostring(v.talentId)] =icon
        local clickNode = icon:getChildByName("image")
        clickNode:setTouchEnabled(true)
        display.commonUIParams(clickNode , { cb = handler(self , self.TalentClick ), tag = checkint(v.talentId) , animate = true })
    end
end
function ArtifactTalentMediator:TrailBtnClick()
    local artifactConfig  = CommonUtils.GetConfigAllMess('card' ,'cards')[tostring(self.cardId)] or ""
    local artifactQuestId =artifactConfig.artifactQuestId or "12001"
    artifactMgr:GoToBattleReadyView(artifactQuestId , "artifact.ArtifactTalentMediator" , "artifact.ArtifactTalentMediator" , self.cardTable[self.index].id )
end
function ArtifactTalentMediator:TalentClick(sender)
    -- 获取到天赋的数据
    local talentId = sender:getTag()
    local cardData = self.cardTable[self.index]
    local talentDatas = self:GetTalentData()
    local level = 0
    if talentDatas and  talentDatas[tostring(talentId)] then
        level  =  talentDatas[tostring(talentId)].level
    end
    local status = artifactMgr:CheckTalentIdAllowUpgradeId(cardData ,talentId )
    local talentOnePointConfig = artifactMgr:GetTalentIdPointConfigByCardId(cardData.cardId)
    if status == 0   then
        if talentOnePointConfig[tostring(talentId)]  then
            if  checkint(talentOnePointConfig[tostring(talentId)].style) == TALENT_TYPE.BIG then
                local mediator = require("Game.mediator.artifact.JewelImbedMediator").new(
                        { cardData = cardData, talentId = talentId }
                )
                self:GetFacade():RegistMediator(mediator)
            elseif  checkint(talentOnePointConfig[tostring(talentId)].style) == TALENT_TYPE.SMALL then
                uiMgr:ShowInformationTips(__('请先解锁前置节点'))
            end
        end

    elseif status == 1 then
        if talentOnePointConfig[tostring(talentId)]  then

            if  checkint(talentOnePointConfig[tostring(talentId)].style) == TALENT_TYPE.BIG then
                local mediator = require("Game.mediator.artifact.JewelImbedMediator").new(
                        { cardData = cardData, talentId = talentId }
                )
                self:GetFacade():RegistMediator(mediator)
            elseif  checkint(talentOnePointConfig[tostring(talentId)].style) == TALENT_TYPE.SMALL then
                local mediator = require("Game.mediator.artifact.ArtifactTalentUpgradeMediator").new(
                        { touchNode = sender , talentId = talentId ,isFull = false , cardData = cardData ,level = level , status = status  }
                )
                self:GetFacade():RegistMediator(mediator)
            end
        end
        --end
    elseif status == 2 then
        if talentOnePointConfig[tostring(talentId)]  then
            if  checkint(talentOnePointConfig[tostring(talentId)].style) == TALENT_TYPE.BIG then
                --TODO 调起宝石解锁的界面
                local mediator = require("Game.mediator.artifact.JewelImbedMediator").new(
                        { cardData = cardData, talentId = talentId }
                )
                self:GetFacade():RegistMediator(mediator)
            elseif  checkint(talentOnePointConfig[tostring(talentId)].style) == TALENT_TYPE.SMALL then
                local mediator = require("Game.mediator.artifact.ArtifactTalentUpgradeMediator").new(
                        { touchNode = sender , talentId = talentId ,isFull = true  , cardData = cardData ,level = level  }
                )
                self:GetFacade():RegistMediator(mediator)
                --TODO 调起解锁小天赋
            end
        end
    end
end

--[[
    添加icon 图标
--]]

function ArtifactTalentMediator:AddTalentTree()
    self:AddLockPathImage()
    self:AddTalentIcon()
    self:AddUnlockImage()
end
--[[
    创建已经有的更新节点
--]]
function ArtifactTalentMediator:AddUnlockImage()
    local unlockPathLayer = self.viewComponent.viewData.unlockPathLayer
    local artifactTalent = self:GetTalentData()
    local talentOnePoint = artifactMgr:GetTalentIdPointConfigByCardId(self.cardId)
    local cardConfig = CommonUtils.GetConfigAllMess('card','card')[tostring(self.cardId)]
    local career = 1
    if cardConfig then
        career = checkint(cardConfig.career)
    end
    local talentTreeConfig = artifactMgr:GetTalentPosConfigByCareer(career)
    for i, v in pairs(talentOnePoint) do
        if artifactTalent[tostring(v.talentId)]  and  checkint(artifactTalent[tostring(v.talentId)].level)   > 0  then
            local  startPos = talentTreeConfig[tostring(v.talentId)].location
            for ii, vv  in pairs(v.afterTalentId) do
                local onePoint =talentTreeConfig[tostring(vv)]
                if onePoint then
                    local  endPos = onePoint.location
                    local image =  self:GetPathImage( startPos ,endPos , _res('ui/artifact/card_weapon_path_light'))
                    unlockPathLayer:addChild(image)
                end
            end
        end
    end
end

function ArtifactTalentMediator:CreateUnlockPrograssTimer(startPos, endPos)
    local middlePoint , angle , distance ,isLeftToright   = self:GetRotate(startPos ,endPos)
    local prograssTimer = cc.ProgressTimer:create(cc.Sprite:create( _res('ui/artifact/card_weapon_path_light')))
    prograssTimer:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    if isLeftToright == 0  then
        prograssTimer:setMidpoint(cc.p(1, 0))
    else
        prograssTimer:setMidpoint(cc.p(0, 0))
    end
    local expBarSize = prograssTimer:getContentSize()
    prograssTimer:setScaleX(distance/ expBarSize.width )
    prograssTimer:setBarChangeRate(cc.p(1, 0))
    prograssTimer:setPercentage(0)
    prograssTimer:setRotation(angle)
    prograssTimer:setPosition(middlePoint.x , middlePoint.y )
    local unlockPathLayer = self.viewComponent.viewData.unlockPathLayer
    unlockPathLayer:addChild(prograssTimer)
    local prograssTo = cc.ProgressTo:create(2,100)
    prograssTimer:runAction( prograssTo )
end

function ArtifactTalentMediator:GetTalentData()
    local cardData = self.cardTable[self.index] or {}
    local artifactTalent = cardData.artifactTalent
    if not  artifactTalent  then
        cardData.artifactTalent = {}
        artifactTalent = {}
    end
    return artifactTalent
end


--[[
    创建icon 根据
--]]
function ArtifactTalentMediator:CreateTalentBgStyleAndColor(style , color )
    local node = nil
    if TALENT_TYPE.SMALL == checkint(style) then
        local image = display.newImageView(_res('ui/artifact/card_weapon_gift_slot_s'))
        local imageSize = image:getContentSize()
        node = display.newLayer(0,0,{ap = display.CENTER , size = imageSize  ,color1 = cc.c4b(0,0,0,0), enable = true  })
        node:addChild(image)
        image:setPosition(cc.p(imageSize.width/2 , imageSize.height/2))
        image:setName("image")
        local levelLabel = display.newButton(imageSize.width/2 , -5 , { n = _res('ui/home/talent/talent_bg_skill_number.png') , enable = false })
        levelLabel:setVisible(false)
        levelLabel:setName("levelLabel")
        node:addChild(levelLabel)
        --node:setCascadeOpacityEnabled(true)
    else
        local image = display.newImageView(_res('ui/artifact/card_weapon_gift_slot_L_lock'))
        local imageSize = image:getContentSize()
        node = display.newLayer(0,0,{ap = display.CENTER , size = imageSize , color1 =cc.r4b()  , enable = true  })
        node:addChild(image , 1)
        image:setPosition(cc.p(imageSize.width/2 , imageSize.height/2))
        image:setName("image")

        local levelLabel = display.newButton(imageSize.width/2 , -5 , { n = _res('ui/home/talent/talent_bg_skill_number.png') , enable = false })
        levelLabel:setVisible(false)
        levelLabel:setName("levelLabel")
        node:addChild(levelLabel,12)
        -- 核心的图片
        local coreImage = display.newImageView(GEM_PATH_TABLE[tostring(color )].lockPtah , imageSize.width/2 , imageSize.height/2)
        node:addChild(coreImage)
        local gemImage = display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID) ,imageSize.width/2 , imageSize.height/2)
        node:addChild(gemImage , 2)
        gemImage:setName('gemImage')
        gemImage:setVisible(false)

        local  rotateSpine  = SpineCache(SpineCacheName.ARTIFACT):createWithName(ARTIFACT_SPINE.ROTATE)
        rotateSpine:setName("rotateSpine")
        rotateSpine:setPosition(cc.p(imageSize.width/2 , imageSize.height/2 ))
        node:addChild(rotateSpine,11)
        local gemEquipIcon = display.newImageView(_res('arts/artifact/equipicon/diamond_icon_01_02'),imageSize.width/2 , imageSize.height/2 )
        node:addChild(gemEquipIcon , 11)
        gemEquipIcon:setName("gemEquipIcon")
        gemEquipIcon:setScale(0.8)
        gemEquipIcon:setVisible(false)
    end

    return node 
end


--[[
    根据 id  返回图标的路径
--]]
function ArtifactTalentMediator:RefreshTelentIconById(id)
    -- 获取一个卡牌的坐标系
    local  artifactTalent = self:GetTalentData()
    local talentOnePoint = artifactMgr:GetTalentIdPointConfigByCardId(self.cardId)
    local talentOneData = {}
    if not  artifactTalent[tostring(id)]  then
        artifactTalent[tostring(id)] = {}
    end
    talentOneData = artifactTalent[tostring(id)]
    local talentOne = talentOnePoint[tostring(id)] or {}
    local gemStyle = talentOne.style       -- 1 、 不可以镶嵌宝石 2、可以镶嵌宝石
    local level =  checkint(talentOneData  and checkint(talentOneData.level) )
    -- 天赋的等级
    local fullLevel = checkint(talentOne.level)        -- 天赋的满级等级
    local isFull =  (level ~= 0 and level >= fullLevel)       -- 是否满级
    local node = self.iconTable[tostring(id)]
    -- 是否可以升级
    local status = artifactMgr:CheckTalentIdAllowUpgradeId(self.cardTable[self.index] , id)
    if checkint(gemStyle)  == TALENT_TYPE.SMALL  then
        local levelLabel = node:getChildByName("levelLabel")
        local image = node:getChildByName("image")
        local nodeSize = node:getContentSize()
        image:setVisible(true)
        local spineNode  = node:getChildByName("spineNode")
        if spineNode  then
            spineNode:setVisible(false)
            spineNode:setToSetupPose()
        end
        if isFull then
            image:setTexture(_res('ui/artifact/card_weapon_gift_slot_s_light'))
            levelLabel:setVisible(false)
        elseif level > 0  or status == 1 then
            image:setTexture(_res('ui/artifact/card_weapon_gift_slot_s'))
            levelLabel:setVisible(true)
            display.commonLabelParams(levelLabel, fontWithColor('10', {color= "#ffffff" ,fontSize = 24 , text = string.format('%s/%s' , level ,fullLevel)  }))
            -- 判断spine动画是否存在
            local spineNode  = node:getChildByName("spineNode")
            if spineNode  then
                spineNode:setVisible(true)
                spineNode:setAnimation(0, 'idle', true)
            else
                spineNode = SpineCache(SpineCacheName.ARTIFACT):createWithName(ARTIFACT_SPINE.FIRE)
                spineNode:setName("spineNode")
                spineNode:setPosition(cc.p(nodeSize.width/2 , nodeSize.height/2 ))
                node:addChild(spineNode,2)
                spineNode:setAnimation(0, 'idle', true)
                --TODO 创建spine动画
            end
        elseif level == 0  then
            image:setTexture(_res('ui/artifact/card_weapon_gift_slot_s'))
            levelLabel:setVisible(false)
        end
    elseif checkint(gemStyle) == TALENT_TYPE.BIG then
        local isHaveGem = checkint(talentOneData.gemstoneId) > 0   and true or false   -- 是否有宝石
        local gemGoodsId = checkint(talentOneData.gemstoneId)       -- 镶嵌宝石的等级
        local gemColor = checkint(talentOne.gemstoneColor[1])   -- 宝石的技能的颜色
        local status = artifactMgr:CheckTalentIdAllowUpgradeId(self.cardTable[self.index] , id)
        local mouseSpine = node:getChildByName("mouseSpine")
        local nodeSize = node:getContentSize()
        local rotateSpine = node:getChildByName("rotateSpine")
        local fireSpine = node:getChildByName("fireSpine")
        local gemImage = node:getChildByName("gemImage")
        local image = node:getChildByName("image")
        local gemEquipIcon = node:getChildByName("gemEquipIcon")
        local levelLabel = node:getChildByName("levelLabel")
        levelLabel:setVisible(false)
        gemImage:setVisible(true)
        gemEquipIcon:setVisible(false)
        gemImage:setTexture(GEM_PATH_TABLE[tostring(gemColor)].lockPtah)
        if mouseSpine then
            mouseSpine:setVisible(false)
            mouseSpine:setToSetupPose()
        end
        if fireSpine then
            fireSpine:setVisible(false)
            fireSpine:setToSetupPose()
        end
        local action = artifactMgr:GetCircleSpineNameByPlayerCardId(self.cardTable[self.index].id , id)
        rotateSpine:setToSetupPose()
        rotateSpine:setAnimation( 0, action , true )
        if status == 0  then
            gemEquipIcon:stopAllActions()
            if image  then
                image:setTexture(_res('ui/artifact/card_weapon_gift_slot_L_lock'))
            end
        elseif  status == 1 then
            gemEquipIcon:stopAllActions()
            if image  then
                image:setTexture(_res('ui/artifact/card_weapon_gift_slot_L_lock'))
            end
            levelLabel:setVisible(true)
            display.commonLabelParams(levelLabel , fontWithColor('10', { color = "#ffffff", fontSize = 24,text =  level .. '/'..fullLevel ,paddingW = 20}))
        elseif  status == 2  then
            image:setTexture(GEM_PATH_TABLE[tostring(gemColor)].bottomPath)
            if isHaveGem then
                levelLabel:setVisible(false)
                local mouseAction = artifactMgr:GetSpineNameById(gemGoodsId)
                local gemData = artifactMgr:GetGemConfig(gemGoodsId)
                local stageLevel = artifactMgr:GetGemStageByLevel(checkint(gemData.grade))
                if mouseSpine then
                    mouseSpine:setVisible(true)
                else
                    mouseSpine  = SpineCache(SpineCacheName.ARTIFACT):createWithName(ARTIFACT_SPINE.MOUSE)
                    mouseSpine:setName("mouseSpine")
                    mouseSpine:setPosition(cc.p(nodeSize.width/2 , nodeSize.height/2 - 30))
                    node:addChild(mouseSpine,12)
                end
                if stageLevel  == GEM_STAGE.VERY_HIGH  then
                    if not  fireSpine then
                        fireSpine = SpineCache(SpineCacheName.ARTIFACT):createWithName(ARTIFACT_SPINE.FIRE)
                        fireSpine:setName("fireSpine")
                        fireSpine:setPosition(cc.p(nodeSize.width/2 , nodeSize.height/2))
                        node:addChild(fireSpine,-1)
                    else
                        fireSpine:setVisible(true)
                    end
                    fireSpine:setAnimation(0 , 'play4' , true )
                else
                    if  fireSpine then
                        fireSpine:setVisible(false)
                        fireSpine:setToSetupPose()
                    end
                end
                mouseSpine:setAnimation(0 , mouseAction , true )
                gemEquipIcon:setPosition(cc.p(nodeSize.width/2 , nodeSize.height/2 ))
                gemEquipIcon:setVisible(true)
                gemEquipIcon:stopAllActions()
                local distanceX = 8
                gemEquipIcon:runAction(
                    cc.RepeatForever:create(
                        cc.Sequence:create(
                            cc.MoveBy:create(2, cc.p(0, distanceX )),
                            cc.MoveBy:create(2, cc.p(0, -distanceX ))
                        )
                    )
                )
                gemEquipIcon:setTexture(artifactMgr:GetEquipGemIconByGemId(gemGoodsId))
            else
                levelLabel:setVisible(true)
                display.commonLabelParams(levelLabel , fontWithColor('10', { color = "#ffffff",text = __('请镶嵌塔可'),paddingW = 20}))
            end
        end
    end
end
--[[
    获取中点、 旋转角度接、距离
    --@param startPos 起点
    --@param endPos 终点
--]]
function ArtifactTalentMediator:GetRotate(startPos , endPos )
     startPos =  self:ConvertToGemPos(startPos)
     endPos =  self:ConvertToGemPos(endPos )
     local distanceX = (endPos.x -startPos.x)
     local distanceY =  (endPos.y -startPos.y)
     local distance =  math.sqrt(  distanceX *distanceX +  distanceY *distanceY)
     local middlePoint ={
         x = (endPos.x +startPos.x)/2 ,
         y =  (endPos.y +startPos.y)/2
     }
     -- x 周旋转的方向大于零 说明旋转不是90
     local angle = 0
     if math.abs(distanceX)  > 0  then
         angle =math.deg( -math.atan(distanceY/ distanceX)  )
     else
         angle = 90
     end
     local isLeftToright = 0  -- 0 为是由右向左 1、由做向右
     if  checkint(startPos.x)  > checkint(endPos.x)  then
         isLeftToright =  0
     elseif    checkint(startPos.x)  < checkint(endPos.x)    then
         isLeftToright =  1
     elseif   checkint(startPos.x)   ==  checkint(endPos.x)   then
         if  startPos.y > endPos.y then
             isLeftToright =  0
         else
             isLeftToright =  1
         end
     end
     return middlePoint , angle , distance ,isLeftToright
end
function ArtifactTalentMediator:EnterAnimation()
    local scene = uiMgr:GetCurrentScene()
    local artifactLayer = scene:GetDialogByName("artifactLayer")
    if not  artifactLayer then
        self:EnterAnimationOne()
    end
end


function ArtifactTalentMediator:EnterAnimationOne()
    local viewData = self.viewComponent.viewData
    local artifactLayout =  viewData.artifactLayout
    local artifactBigImage =  viewData.artifactBigImage
    local artifactLayoutPos = cc.p(artifactLayout:getPosition())
    local artifactLayoutMovePos = cc.p(artifactLayoutPos.x - 80 ,artifactLayoutPos.y  )
    artifactBigImage:setVisible(true)
    artifactLayout:setOpacity(0)
    artifactLayout:setPosition(artifactLayoutMovePos)
    local fadeInEelemt = {
        viewData.jobImage ,
        self.iconTable,
        viewData.lockPathLayer,
        viewData.unlockPathLayer
    }
    local talentOnePointConfig = artifactMgr:GetTalentIdPointConfigByCardId(self.cardId)
    local spawnTable = {}
    local tatalTime = 1.5
    local distanTime = 0.2
    local fadetime = 0.6

    for i, v in pairs(fadeInEelemt) do
        if i == 2  then
            for index, icon  in pairs( v ) do
                if checkint(talentOnePointConfig[tostring(index)].style)  == TALENT_TYPE.SMALL then
                    icon:setOpacity(0)
                    spawnTable[#spawnTable+1]  = cc.TargetedAction:create( icon ,
                        cc.Sequence:create(
                            cc.DelayTime:create((i-1)*distanTime ),
                            cc.FadeIn:create(fadetime),
                            cc.DelayTime:create(tatalTime -  (i-1)*distanTime - fadetime )
                        )
                    )
                else
                    icon:setOpacity(0)
                    icon:setScale(1.5)
                    spawnTable[#spawnTable+1]  = cc.TargetedAction:create( icon ,
                        cc.Sequence:create(
                            cc.DelayTime:create((i-1)*distanTime ),
                            cc.Spawn:create(
                                cc.FadeIn:create(fadetime),
                                cc.EaseBackOut:create(cc.ScaleTo:create(fadetime,1) )
                            ),
                            cc.DelayTime:create(tatalTime -  (i-1)*distanTime - fadetime )
                        )
                    )
                end
            end
        else
            v:setOpacity(0)
            spawnTable[#spawnTable+1]  = cc.TargetedAction:create( v ,
                cc.Sequence:create(
                    cc.DelayTime:create((i-1)*distanTime ),
                    cc.FadeIn:create(fadetime),
                    cc.DelayTime:create(tatalTime -  (i-1)*distanTime - fadetime )
                )
            )
        end
    end
    spawnTable[#spawnTable+1] = cc.TargetedAction:create(artifactLayout ,
        cc.Sequence:create(
            cc.DelayTime:create(0.7),
            cc.Spawn:create(
               cc.EaseBackOut:create(cc.MoveTo:create(tatalTime - 0.8 , artifactLayoutPos)),
               cc.FadeIn:create(tatalTime -0.7)
            )
        )
    )
    self.viewComponent:runAction(
        cc.Sequence:create(
             cc.CallFunc:create(function()
                     self.isAction = true
             end) ,
            cc.Spawn:create(spawnTable),
            cc.CallFunc:create(function()
                    self.isAction = false
            end)
        )
    )
end
function ArtifactTalentMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    regPost(POST.ARTIFACT_RESET_TALENT)
    regPost(POST.ARTIFACT_TALENT_LEVEL)
    regPost(POST.ARTIFACT_EQUIPGEM)
end
function ArtifactTalentMediator:OnUnRegist()
    -- 升级分为小技能和大技能升级 因此升级统一在本页面进行处理
    unregPost(POST.ARTIFACT_TALENT_LEVEL)
    unregPost(POST.ARTIFACT_RESET_TALENT)
    unregPost(POST.ARTIFACT_EQUIPGEM)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        SpineCache(SpineCacheName.ARTIFACT):clearCache()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return ArtifactTalentMediator
