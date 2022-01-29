---@class ArtifactQuestSweepView
local ArtifactQuestSweepView = class('home.ArtifactQuestSweepView',function ()
    local node = display.newLayer(0, 0, { ap = display.CENTER , size = display.size})
    node.name = 'Game.views.ArtifactQuestSweepView'
    node:enableNodeEvents()
    return node
end)
---@type ArtifactManager
local artifactMgr = AppFacade.GetInstance():GetManager("ArtifactManager")

---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local BUTTON_TAG = {
    ONETIME = 1 , -- 一次
    MUTI_TIMES = 2 -- 多次
}
local BATTLE_TYPE = {
    COMMON_TYPE = 1 ,  -- 普通模式
    UNIVERSAL_TYPE = 2 -- 万能门票道具消耗
}
function ArtifactQuestSweepView:ctor(param)
    self.isAction = false
    param = param or {}
    self.questId = param.questId
    self.questType = param.questType
    self.maxTimes = 5
    self.multiTimes = 5
    self.star = param.star
    self:initUI()
    self:UpdateUI()
end

function ArtifactQuestSweepView:initUI()
    local closeLayer = display.newLayer(display.cx, display.cy ,{ ap =  display.CENTER , size = display.size , color = cc.c4b(0,0,0,100 ) , enable  = true ,cb = function ()
        self:removeFromParent()
    end})
    self:addChild(closeLayer)
    local bgSize = cc.size(435 ,308)
    local bgLayout  = display.newLayer(display.cx, display.cy ,{ ap =  display.CENTER , size = bgSize})
    self:addChild(bgLayout)
    -- 吞噬层
    local swallowLayer = display.newLayer(bgSize.width/2 , bgSize.height/2 ,{ ap =  display.CENTER , size = bgSize , color =  cc.c4b(0,0,0,0 ), enable  = true })
    bgLayout:addChild(swallowLayer)
    -- 背景的图片
    local bgImage =  display.newImageView(_res("ui/common/common_bg_8.png"),bgSize.width/2 , bgSize.height/2)
    bgLayout:addChild(bgImage)
    closeLayer:setPosition(display.center)


    local  oneTimesBtn = display.newButton(bgSize.width/ 2 - 90 , bgSize.height/2 ,
            {n = _res('ui/common/common_btn_big_orange')}
    )
    bgLayout:addChild(oneTimesBtn)
    oneTimesBtn:setScale(0.8)
    oneTimesBtn:setTag(BUTTON_TAG.ONETIME)


    local oneNode = require("common.GoodNode").new({id = DIAMOND_ID})
    bgLayout:addChild(oneNode)
    oneNode:setPosition(bgSize.width /2 - 55 ,70 )
    oneNode:setScale(0.5)

    local oneConsumeLabel = display.newRichLabel(bgSize.width /2 - 90,70 , {  r = true , ap = display.RIGHT_CENTER ,c = {
        fontWithColor('10', {text = "111111"})
    }
    })
    bgLayout:addChild(oneConsumeLabel)

    -- 普通挑战
    local  mutiTimesBtn = display.newButton(bgSize.width/ 2 + 90 , bgSize.height/2  ,
            {n = _res('ui/common/common_btn_big_orange')}
    )
    mutiTimesBtn:setScale(0.8)
    bgLayout:addChild(mutiTimesBtn)
    mutiTimesBtn:setTag(BUTTON_TAG.MUTI_TIMES)

    local mutliNode = require("common.GoodNode").new({id = DIAMOND_ID})
    bgLayout:addChild(mutliNode)
    mutliNode:setPosition(bgSize.width /2 + 120 , 70)
    mutliNode:setScale(0.5)
    local mutliConsumeLabel = display.newRichLabel(bgSize.width /2 + 90 ,70 , { r = true ,ap = display.RIGHT_CENTER ,
                                                                                   c = {
                                                                                       fontWithColor('10', {text = "111111"})
                                                                                   }
    })
    bgLayout:addChild(mutliConsumeLabel)
    self.viewData = {
        oneConsumeLabel   = oneConsumeLabel,
        mutliConsumeLabel = mutliConsumeLabel,
        oneNode           = oneNode,
        mutiTimesBtn      = mutiTimesBtn,
        oneTimesBtn       = oneTimesBtn,
        mutliNode         = mutliNode
    }
end

function ArtifactQuestSweepView:UpdateUI()
    local viewData = self.viewData
    local oneConsumeLabel = viewData.oneConsumeLabel
    local mutiTimesBtn          = viewData.mutiTimesBtn
    local oneTimesBtn           = viewData.oneTimesBtn
    local oneNode         = viewData.oneNode
    local mutliConsumeLabel    = viewData.mutliConsumeLabel
    local mutliNode            = viewData.mutliNode
    local questId = self.questId
    local questType = self.questType
    local parserConfig = artifactMgr:GetConfigParse()
    local artifactQuestConfig = artifactMgr:GetConfigDataByName(parserConfig.TYPE.QUEST)
    local artifactOneQuest = artifactQuestConfig[tostring(questId)]
    local num =  0
    local goodsId = 0
    if questType == BATTLE_TYPE.UNIVERSAL_TYPE then
        goodsId = artifactOneQuest.consumeTicket
        num = artifactOneQuest.consumeTicketNum
    else
        local consumeData = artifactOneQuest.consumeGoods
        num =  consumeData[1].num
        goodsId = consumeData[1].goodsId
    end
    local owner = CommonUtils.GetCacheProductNum(goodsId)
    if math.floor(owner / num) > 1  then
        self.multiTimes = self.multiTimes > self.maxTimes and self.maxTimes or self.multiTimes
    else
        self.multiTimes = self.maxTimes
    end
    display.commonLabelParams(oneTimesBtn , fontWithColor('14' , {text = string.format(__('打%d次'), 1 )}))
    display.commonLabelParams(mutiTimesBtn , fontWithColor('14' , {text = string.format(__('打%d次'), self.multiTimes )}))

    display.reloadRichLabel(oneConsumeLabel , { c= {
        fontWithColor('8', {text = __('消耗')}),
        fontWithColor('10', {text = tostring(num)})
    }})
    CommonUtils.SetNodeScale(oneConsumeLabel , {width = 90 })
    oneNode:RefreshSelf({goodsId = goodsId })
    display.reloadRichLabel(mutliConsumeLabel , { c= {
        fontWithColor('8', {text = __('消耗')}),
        fontWithColor('10', {text = tostring(num * self.multiTimes)})
    }})
    CommonUtils.SetNodeScale(mutliConsumeLabel , {width = 90 })
    mutliNode:RefreshSelf({goodsId = goodsId })

    local callfunc = function(sender)
        local sweepType   = sender:getTag()
        local times = sweepType == BUTTON_TAG.ONETIME and 1 or self.multiTimes
        local ownNum = CommonUtils.GetCacheProductNum(goodsId)
        local star = self.star
        if star == 3 then
            if ownNum  >= ( times *  num) then
                -- 前往战斗界面
                AppFacade.GetInstance():DispatchSignal(POST.ARTIFACT_SWEEP.cmdName , {questId = questId ,questType = questType , times =  times  } )
            else
                if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsId) == DIAMOND_ID then
                    app.uiMgr:showDiamonTips()
                else
                    uiMgr:ShowInformationTips(__("道具不足"))
                end
                return
            end
        else
            uiMgr:ShowInformationTips(__('达成本关三星才能扫荡'))
        end

    end
    oneTimesBtn:setOnClickScriptHandler(callfunc)
    mutiTimesBtn:setOnClickScriptHandler(callfunc)
end

function ArtifactQuestSweepView:RefreshSweepTimesUI()
    self:UpdateUI()
end
function ArtifactQuestSweepView:SweepCallBack(signal)
    local responseData = signal:GetBody()
    local requestData = responseData.requestData
    local questType = requestData.questType
    local questId = requestData.questId
    local delayList = {}
    local data = {}
    if responseData.sweep then
        for k,v in pairs(responseData.sweep) do
            for ii, vv  in pairs(v.rewards) do
                data[#data+1] = vv
            end
        end
    end
    local isHave = false
    if checkint(responseData.totalMainExp) > 0  then
        isHave = true
        data[#data+1] = {goodsId = EXP_ID, num = (checkint(responseData.totalMainExp) - gameMgr:GetUserInfo().mainExp)}
    end
    local consumeQuest  = artifactMgr:GetConsumedByQuestId(questId , checkint( requestData.times) , questType)
    for i, v in pairs(consumeQuest) do
        data[#data+1] = v
    end
    delayList = CommonUtils.DrawRewards(data, true)
    local tag = 2005
    if checkint(requestData.times ) == 1 then
        --responseData.sweep['1'].rewards[#responseData.sweep['1'].rewards+1] = {goodsId = EXP_ID, num = responseData.sweep['1'].mainExp}
        uiMgr:AddDialog('common.RewardPopup', {rewards = responseData.sweep['1'].rewards,mainExp = responseData.sweep['1'].mainExp ,addBackpack = false,delayFuncList_ = delayList})
    else
        local layer = require('Game.views.SweepRewardPopup').new({tag = tag, rewardsData = responseData , executeAction = true , delayFuncList_ = delayList})
        display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
        uiMgr:GetCurrentScene():AddDialog(layer)
        layer:setTag(tag)
    end
end
function ArtifactQuestSweepView:onEnter()
    regPost(POST.ARTIFACT_SWEEP)
    AppFacade.GetInstance():RegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, mvc.Observer.new(self.RefreshSweepTimesUI , self) )
    AppFacade.GetInstance():RegistObserver(POST.ARTIFACT_SWEEP.sglName, mvc.Observer.new(self.SweepCallBack , self) )
end

function ArtifactQuestSweepView:UnregistSignal()
    AppFacade.GetInstance():UnRegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT , self)
    AppFacade.GetInstance():UnRegistObserver(POST.ARTIFACT_SWEEP.sglName , self)
    unregPost(POST.ARTIFACT_SWEEP)
end

function ArtifactQuestSweepView:onCleanup()
    self:UnregistSignal()
end




return ArtifactQuestSweepView
