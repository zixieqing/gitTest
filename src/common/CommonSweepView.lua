---@class CommonSweepView
local CommonSweepView = class('CommonSweepView',function ()
    local node = display.newLayer(0, 0, { ap = display.CENTER , size = display.size})
    node.name = 'CommonSweepView'
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
--[[
通用的扫荡界面
@params params table {
    consumeData                 -- 消耗的数据
    isGoodNode                  -- 是否显示GoodNode
    battleSweepSingalName       -- 扫荡信号 外部接受
    consumeType                 --消耗方式
    star                        -- 当前关卡的星级
    isStarSweep                 -- 是否需要星级扫荡 0  、 不需要星级 1、需要星级
}
--]]

function CommonSweepView:ctor(param)
    self.isAction = false
    param = param or {}
    self.questId = param.questId
    self.consumeType = param.consumeType
    if  param.isGoodNode == nil  then
        self.isGoodNode = false
    else
        self.isGoodNode =  param.isGoodNode
    end
    self.isGoodNode =  param.isGoodNode
    self.consumeData = param.consumeData
    self.battleSweepSingalName = param.battleSweepSingalName
    self.maxTimes = 5
    self.multiTimes = 5
    self.isStarSweep = param.isStarSweep
    self.star  = checkint(param.star)
    self:initUI()
    self:UpdateUI()
end

function CommonSweepView:initUI()
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

function CommonSweepView:UpdateUI()
    local viewData = self.viewData
    local oneConsumeLabel = viewData.oneConsumeLabel
    local mutiTimesBtn          = viewData.mutiTimesBtn
    local oneTimesBtn           = viewData.oneTimesBtn
    local mutliConsumeLabel     = viewData.mutliConsumeLabel
    local mutliNode             = viewData.mutliNode
    local oneNode             = viewData.oneNode
    local questId               = self.questId
    local num =  self.consumeData[1].num
    local goodsId = self.consumeData[1].goodsId
    local owner = CommonUtils.GetCacheProductNum(goodsId)
    if math.floor(owner / num) > 1  then
        self.multiTimes = self.multiTimes > self.maxTimes and self.maxTimes or self.multiTimes
    else
        self.multiTimes = self.maxTimes
    end
    display.commonLabelParams(oneTimesBtn , fontWithColor('14' , {text = string.format(__('打%d次'), 1 )}))
    display.commonLabelParams(mutiTimesBtn , fontWithColor('14' , {text = string.format(__('打%d次'), self.multiTimes )}))

    if self.isGoodNode  then
        oneNode:RefreshSelf({goodsId = goodsId })
        mutliNode:RefreshSelf({goodsId = goodsId })
        display.reloadRichLabel(oneConsumeLabel , { c= {
            fontWithColor('8', {text = __('消耗')}),
            fontWithColor('10', {text = tostring(num)})
        }})
        display.reloadRichLabel(mutliConsumeLabel , { c= {
            fontWithColor('8', {text = __('消耗')}),
            fontWithColor('10', {text = tostring(num * self.multiTimes)})
        }})
    else
        display.reloadRichLabel(oneConsumeLabel , { c= {
            fontWithColor('8', {text = __('消耗')}),
            fontWithColor('10', {text = tostring(num)}),
            { img = CommonUtils.GetGoodsIconPathById(goodsId) , scale = 0.2  }
        }})
        display.reloadRichLabel(mutliConsumeLabel , { c= {
            fontWithColor('8', {text = __('消耗')}),
            fontWithColor('10', {text = tostring(num * self.multiTimes)}),
            { img = CommonUtils.GetGoodsIconPathById(goodsId) , scale = 0.2  }
        }})
        mutliNode:setVisible(false)
        oneNode:setVisible(false)
    end
    CommonUtils.SetNodeScale(oneConsumeLabel , {width = 95 })
    CommonUtils.SetNodeScale(mutliConsumeLabel , {width = 95 })

    local callfunc = function(sender)
        local sweepType   = sender:getTag()
        local times = sweepType == BUTTON_TAG.ONETIME and 1 or self.multiTimes
        local ownNum = CommonUtils.GetCacheProductNum(goodsId)
        local star = self.star
        if self.isStarSweep then
            if star < 3 then
                uiMgr:ShowInformationTips(__('达成本关三星才能扫荡'))
                return
            end
        end
        if ownNum  >= ( times *  num) then
            -- 前往战斗界面
            app:DispatchSignal( self.battleSweepSingalName , {consumeGoodId = goodsId ,consumeOneNums = num   ,  questId = questId  , consumeType = self.consumeType , times = times })
        else
            if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsId) == DIAMOND_ID then
                app.uiMgr:showDiamonTips()
            else
                local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId)
                uiMgr:ShowInformationTips(string.format( __("%s不足"),  goodsConfig.name))
            end
        end

    end
    oneTimesBtn:setOnClickScriptHandler(callfunc)
    mutiTimesBtn:setOnClickScriptHandler(callfunc)
end

return CommonSweepView
