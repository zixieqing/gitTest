---@class ArtifactRoadQuestSweepView
local ArtifactRoadQuestSweepView = class('ArtifactRoadQuestSweepView',function ()
    local node = display.newLayer(0, 0, { ap = display.CENTER , size = display.size})
    node.name = 'ArtifactRoadQuestSweepView'
    node:enableNodeEvents()
    return node
end)

---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local BUTTON_TAG = {
    ONETIME = 1 , -- 一次
    MUTI_TIMES = 2 -- 多次
}
local BATTLE_TYPE = {
    COMMON_TYPE = 1 ,  	-- 普通模式
    PAID_TYPE 	= 2 	-- 付费模式
}
function ArtifactRoadQuestSweepView:ctor(param)
    self.isAction = false
    param = param or {}
    self.questId = param.questId
    self.questType = param.questType
    self.activityId = param.activityId
    self.maxTimes = 5
    self.multiTimes = 5
    self.star = param.star
    self:initUI()
    self:UpdateUI()
end

function ArtifactRoadQuestSweepView:initUI()
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

    local oneConsumeLabel = display.newRichLabel(bgSize.width /2 - 85 ,70 , {r = true , c = {
        fontWithColor('10', {text = "111111"})
    }, ap = display.RIGHT_CENTER
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
    local mutliConsumeLabel = display.newRichLabel(bgSize.width /2 + 90 ,70 , { r = true ,
                                                                                   c = {
                                                                                       fontWithColor('10', {text = "111111"})
                                                                                   }, ap = display.RIGHT_CENTER
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

function ArtifactRoadQuestSweepView:UpdateUI()
    local viewData = self.viewData
    local oneConsumeLabel = viewData.oneConsumeLabel
    local mutiTimesBtn          = viewData.mutiTimesBtn
    local oneTimesBtn           = viewData.oneTimesBtn
    local oneNode               = viewData.oneNode
    local mutliConsumeLabel     = viewData.mutliConsumeLabel
    local mutliNode             = viewData.mutliNode
    local questId               = self.questId
    local questType             = self.questType
    local artifacOneQuest       = CommonUtils.GetQuestConf(checkint(self.questId))
    local num =  0
    local goodsId = 0
    if questType == BATTLE_TYPE.PAID_TYPE then
        goodsId = checkint(artifacOneQuest.consumeGoodsId)
        num = checkint(artifacOneQuest.consumeGoodsNum)
    else
        num =  checkint(artifacOneQuest.consumeHp)
        goodsId = HP_ID
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
    CommonUtils.SetNodeScale(oneConsumeLabel  , {width = 100})
    oneNode:RefreshSelf({goodsId = goodsId })
    display.reloadRichLabel(mutliConsumeLabel , { c= {
        fontWithColor('8', {text = __('消耗')}),
        fontWithColor('10', {text = tostring(num * self.multiTimes)})
    }})
    CommonUtils.SetNodeScale(mutliConsumeLabel  , {width = 100})
    mutliNode:RefreshSelf({goodsId = goodsId })

    local callfunc = function(sender)
        local sweepType   = sender:getTag()
        local times = sweepType == BUTTON_TAG.ONETIME and 1 or self.multiTimes
        local ownNum = CommonUtils.GetCacheProductNum(goodsId)
        local star = self.star
        if star == 3 then
            if ownNum  >= ( times *  num) then
                -- 前往战斗界面
                AppFacade.GetInstance():DispatchSignal(POST.ACTIVITY_ARTIFACT_ROAD_SWEEP.cmdName , {questId = questId ,consumeType = questType , times =  times, activityId = self.activityId  } )
            else
                if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsId) == DIAMOND_ID then
                    app.uiMgr:showDiamonTips()
                else
                    local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId)
                    uiMgr:ShowInformationTips(string.format( __("%s不足"),  goodsConfig.name))
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

return ArtifactRoadQuestSweepView
