--[[
世界地图的mediator
--]]
local Mediator           = mvc.Mediator
---@class UnionBuildMediator:Mediator
local UnionBuildMediator = class("UnionBuildMediator", Mediator)
local NAME               = "UnionBuildMediator"
---@type UnionManager
local unionMgr           = AppFacade.GetInstance():GetManager("UnionManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
---@type UIManager
local uiMgr              = AppFacade.GetInstance():GetManager("UIManager")
local BUTTON_TAG         = {
    ONE = 1 ,
    TWO = 2 ,
    THREE = 3 ,
    CLOSE_TAG = 1101,
    BUILD_LOG = 1102
}
local buildConfig        = CommonUtils.GetConfigAllMess('build', 'union')
--[[
    这里面传输的home接口里面的


--]]

function UnionBuildMediator:ctor(param , viewComponent )
    self.super.ctor(self, 'UnionBuildMediator', viewComponent)
    self.data = unionMgr:getUnionData()
    self.data.leftBuildTimes = self.data.leftBuildTimes or {}
end

function UnionBuildMediator:InterestSignals()
    local signals = {
        POST.UNION_BUILD.sglName  ,
        POST.UNION_BUILDLOG.sglName,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT
    }
    return signals
end

function UnionBuildMediator:Initial( key )
    self.super.Initial(self,key)

    local  viewComponent = require("Game.views.UnionBuildView").new()
    ---@type UnionBuildView
    self.viewComponent = viewComponent
    uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:setPosition(display.center)
    self.viewComponent.viewData.closeLayer:setOnClickScriptHandler(handler(self, self.ButtonAction))
    self.viewComponent.viewData.recordBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    self:UpdateView()

end

function UnionBuildMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.UNION_BUILD.sglName then
        local requestData = body.requestData
        local buildId = requestData.buildId
        -- 获取贡献点的ID
        body.contributionPoint = checkint(body.contributionPoint)
        local num = CommonUtils.GetCacheProductNum(UNION_POINT_ID)
        self.data.unionPoint = body.unionPoint
        local contributionPointAdd =  checkint(body.contributionPoint)  -  checkint(self.data.playerContributionPoint)
        self.data.leftBuildTimes[tostring(requestData.buildId)] = checkint(body.leftBuildTimes)
        if gameMgr:hasUnion() then
            local newUnionData = {
                playerContributionPoint = checkint(contributionPointAdd)
            }
            unionMgr:updateUnionData(newUnionData)
        end
        local data =  {
            {goodsId = UNION_POINT_ID , num = self.data.unionPoint - num   } ,
            {goodsId = UNION_CONTRIBUTION_POINT_ID , num = contributionPointAdd   }
        }
        CommonUtils.DrawRewards(data)
        local contributionOneConfig = buildConfig[tostring(buildId)] or {}
        if checkint(contributionOneConfig.buildGoodsId)   > 0 then
            local comusmeData = {{goodsId = checkint(contributionOneConfig.buildGoodsId)  , num =  - checkint(requestData.times) * checkint(contributionOneConfig.buildGoodsNum)  }}
            CommonUtils.DrawRewards(comusmeData)
        end
        uiMgr:AddDialog("common.RewardPopup",{addBackpack  = false  ,
                                              rewards = data})
        local viewData = self.viewComponent.viewData
        local contributionValue = viewData.contributionValue
        self.data.playerContributionPoint = body.contributionPoint
        display.commonLabelParams(contributionValue ,
                fontWithColor('14' , {text = string.format(__('你的贡献值:%d' ), checkint(self.data.playerContributionPoint) )}))
        self:UpdateCellByBuildId(requestData.buildId)
    elseif name == POST.UNION_BUILDLOG.sglName then
        local buildLog = body.buildLog
        uiMgr:AddDialog("Game.views.UnionBuildLogView",buildLog)
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:UpdateView()
    end
end

--[[
    更新view
--]]
function UnionBuildMediator:UpdateView()
    local viewData = self.viewComponent.viewData
    local contributionValue = viewData.contributionValue
    display.commonLabelParams(contributionValue ,
        fontWithColor('14' , { text = string.format(__('你的贡献值:%d' ), checkint(self.data.playerContributionPoint) )}))
    local size =  contributionValue:getContentSize()
    contributionValue:getLabel():setPosition(cc.p(size.width/2 , size.height/2 +10))
    for i =1 , #viewData.cellTable do
        self:UpdateCellByBuildId(i)
    end
end
--[[
    更新所需要的cell
--]]
function UnionBuildMediator:UpdateCellByBuildId(buildId)
    local viewData        = self.viewComponent.viewData
    local contributionOneConfig = buildConfig[tostring(buildId)]
    local cellLayout      = viewData.cellTable[checkint(buildId)]
    local countTimes      = contributionOneConfig.dailyTimes
    local leftTimes       = checkint(self.data.leftBuildTimes[tostring(buildId)])
    local buildTimes      = cellLayout:getChildByName("buildTimes")
    local buildBtn        = cellLayout:getChildByName("buildBtn")
    local buildBtnTimes   = cellLayout:getChildByName("buildBtnTimes")
    local buildRichLabelTims = buildBtnTimes:getChildByName("buildRichLabel")
    local buildRichLabel  = buildBtn:getChildByName("buildRichLabel")
    local cellImageLayout = cellLayout:getChildByName("cellImageLayout")
    local cellImageSize   = viewData.cellImageSize
    if checkint(leftTimes)  > 0 then
        display.commonLabelParams(buildTimes,
          { text = string.format(__('今日剩余建造次数%d/%d') , leftTimes,countTimes    ) , reqW = 350 , hAlign = display.TAC })
    else
        --buildBtn:setEnabled(false)
        buildBtn:setNormalImage(_res('ui/common/common_btn_orange_disable' ))
        buildBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable' ))
        buildBtnTimes:setNormalImage(_res('ui/common/common_btn_orange_disable' ))
        buildBtnTimes:setSelectedImage(_res('ui/common/common_btn_orange_disable' ))
        display.commonLabelParams(buildTimes,
                  { text = string.format(__('今日次数已用完') , leftTimes,countTimes ) ,  reqW = 350 , w = 380 , hAlign = display.TAC , ap = display.CENTER_TOP})
    end

    local cData = {}
    local cTimesData = {}
    local times = self:GetCurrentBuildIdTimesByBuildId(buildId)
    if checkint(contributionOneConfig.buildGoodsId) > 0 then
        -- 剩余建造次数
        cTimesData[#cTimesData+1] = fontWithColor('14' , {text = contributionOneConfig.buildGoodsNum * times })
        cTimesData[#cTimesData+1] = {img = CommonUtils.GetGoodsIconPathById(contributionOneConfig.buildGoodsId) , scale = 0.2 }
        cData[#cData+1] = fontWithColor('14' , {text = contributionOneConfig.buildGoodsNum })
        cData[#cData+1] = {img = CommonUtils.GetGoodsIconPathById(contributionOneConfig.buildGoodsId) , scale = 0.2 }
    else
        cData[#cData+1] = fontWithColor('14' , {text = __('免费') })
    end
    display.commonLabelParams(buildBtn, fontWithColor('14',{reqW = 150 ,  text = __('建造1次')}))
    display.commonLabelParams(buildBtnTimes, fontWithColor('14',{reqW = 150 ,text = string.format(__('建造%s次'), times) }))

    display.commonUIParams(buildBtn ,{ cb =handler(self, self.ButtonAction) })
    display.commonUIParams(buildBtnTimes ,{ cb =handler(self, self.ButtonAction) })
    --buildBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    buildBtn:setTag(checkint(buildId))
    buildBtnTimes:setTag(checkint(buildId+3))
    display.reloadRichLabel(buildRichLabel , { c = cData})
    display.reloadRichLabel(buildRichLabelTims , {c = cTimesData })
    CommonUtils.AddRichLabelTraceEffect(buildRichLabel)
    local rewardLayout = cellImageLayout:getChildByName("rewardLayout")
    if not  rewardLayout then
        rewardLayout = self:GetRewardsLayoutByBuildId(buildId)
        cellImageLayout:addChild(rewardLayout)
        rewardLayout:setPosition(cc.p(cellImageSize.width/2 , 120 ))
    end
end

function UnionBuildMediator:GetCurrentBuildIdTimesByBuildId(buildId)
    local contributionOneConfig = buildConfig[tostring(buildId)]
    print("buildId " , buildId)
    local leftTimes        = checkint(self.data.leftBuildTimes[tostring(buildId)])
    local  goodsCount = CommonUtils.GetCacheProductNum( checkint(contributionOneConfig.buildGoodsId))
    local times  = checkint(goodsCount / checkint(contributionOneConfig.buildGoodsNum))
    if times >= leftTimes   then
        if leftTimes ~=0   then
            times = leftTimes
        else
            times = 10
        end

    else
        times = times > 1 and times or leftTimes
    end
    return times
end
--[[
    获取经验的layout
--]]
function UnionBuildMediator:GetRewardsLayoutByBuildId(buildId)
    local  contributionOneConfig = buildConfig[tostring(buildId)]
    local data = {}
    data[#data+1] = {goodsId = UNION_POINT_ID ,  num =  checkint(contributionOneConfig.unionPoint)  }
    data[#data+1] = {goodsId = UNION_CONTRIBUTION_POINT_ID,  num =  checkint(contributionOneConfig.contributionPoint)  }

    local goodsSize = cc.size(140,120)
    local rewardLayout = display.newLayer(0,0,
        { ap = display.CENTER , size = cc.size(goodsSize.width *2 , goodsSize.height )})
    for k , v in pairs(data) do -- 检测
        local goodNode = require("common.GoodNode").new({ id = v.goodsId , amount = v.num  ,
          showAmount = true,
          callBack = function (sender)
              uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
          end})
        goodNode:setScale(0.8)
        goodNode:setPosition(cc.p(goodsSize.width * (k - 0.5 ) , goodsSize.height/2))
        rewardLayout:addChild(goodNode)
    end
    rewardLayout:setName("rewardLayout")
    return rewardLayout
end
function UnionBuildMediator:ButtonAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    -- 三种捐献方式
    if tag >= BUTTON_TAG.ONE and   tag <= BUTTON_TAG.THREE * 2 then
        local times = tag > 3 and self:GetCurrentBuildIdTimesByBuildId(tag -3 ) or 1
        tag = tag > 3 and  (tag -3) or  tag
        print("times = =" , times)
        local isBuildTime = self:JudageBuildTimesEnoughByBuildId(tag,times)
        if isBuildTime then
            local isGoodsEnough = self:JudageBuildGoodsEnoughByBuildId(tag,times)
            if isGoodsEnough then
                local contributionOneConfig = buildConfig[tostring(tag)]
                if contributionOneConfig.buildGoodsId then
                    if checkint(contributionOneConfig.buildGoodsId) == DIAMOND_ID then
                        local iconPath = CommonUtils.GetGoodsIconPathById(contributionOneConfig.buildGoodsId)
                        local commonTip = require('common.CommonTip').new({
                                noWidthText = __('确定要进行工会建造?'),
                                descrRich = {
                                    fontWithColor(16, { text = string.format(__('消耗%d') , contributionOneConfig.buildGoodsNum * times)}),
                                    {img =  iconPath  , scale =  0.2  },
                                },
                                callback = function ()
                                    self:SendSignal(POST.UNION_BUILD.cmdName , {buildId = tag , times = times})
                                end
                            })
                        commonTip:setName('CommonTip')
                        commonTip:setPosition(display.center)
                        commonTip.descrTip:setPositionY(140)
                        uiMgr:GetCurrentScene():AddDialog(commonTip)
                    else
                        self:SendSignal(POST.UNION_BUILD.cmdName , {buildId = tag , times = times})
                    end
                end
            else
                local contributionOneConfig = buildConfig[tostring(tag)]
                local data   = CommonUtils.GetConfig('goods','goods' ,contributionOneConfig.buildGoodsId )
                if data then
                    uiMgr:ShowInformationTips(string.format(__('%s不足') ,data.name))
                    if checkint(contributionOneConfig.buildGoodsId)  == UNION_HIGH_ROLL_ID  then
                        PlayAudioByClickNormal()
                        uiMgr:AddDialog("common.GainPopup", { goodsId =  UNION_HIGH_ROLL_ID})
                        return
                    end
                end
                return
            end
        else
            uiMgr:ShowInformationTips(__('捐献次数不足'))
            return
        end
    elseif tag == BUTTON_TAG.CLOSE_TAG then
        self:GetFacade():UnRegsitMediator(NAME)
    elseif tag == BUTTON_TAG.BUILD_LOG then -- 查看日志
        self:SendSignal(POST.UNION_BUILDLOG.cmdName , {})
    end
end

--[[
    判断界面是否抽充足
--]]
function UnionBuildMediator:JudageBuildTimesEnoughByBuildId(buildId,times)
    local data = self.data.leftBuildTimes or {}
    local alreadyBuildTimes = checkint(data[tostring(buildId)])
    if alreadyBuildTimes >= checkint(times)  then
        return true
    end
    return false
end
--[[
    判断捐献的道具是否不足
--]]
function UnionBuildMediator:JudageBuildGoodsEnoughByBuildId(buildId ,times)
    local contributionOneConfig = buildConfig[tostring(buildId)]
    if checkint(contributionOneConfig.buildGoodsId) > 0 then  -- 判断捐献的物品是否充足
        local num = CommonUtils.GetCacheProductNum(contributionOneConfig.buildGoodsId)
        if num >= checkint(contributionOneConfig.buildGoodsNum )  * times then
            return true
        else
           return false
        end
    else
       return true
    end
end
function UnionBuildMediator:OnRegist()
    regPost(POST.UNION_BUILD)
    regPost(POST.UNION_BUILDLOG)
end

function UnionBuildMediator:OnUnRegist()
    unregPost(POST.UNION_BUILD)
    unregPost(POST.UNION_BUILDLOG)
    if self.viewComponent and (not tolua.isnull(self.viewComponent)  ) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return UnionBuildMediator
