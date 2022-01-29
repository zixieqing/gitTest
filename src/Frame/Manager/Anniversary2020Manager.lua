--[[
 * author : kaishiqi
 * descpt : 2020周年庆 管理器
]]
local BaseManager            = require('Frame.Manager.ManagerBase')
---@class Anniversary2020Manager:Anniversary2020Manager
local Anniversary2020Manager = class('Anniversary2020Manager', BaseManager)


-------------------------------------------------
-- manager method

Anniversary2020Manager.DEFAULT_NAME = 'Anniversary2020Manager'
Anniversary2020Manager.instances_   = {}


function Anniversary2020Manager.GetInstance(instancesKey)
    instancesKey = instancesKey or Anniversary2020Manager.DEFAULT_NAME

    if not Anniversary2020Manager.instances_[instancesKey] then
        Anniversary2020Manager.instances_[instancesKey] = Anniversary2020Manager.new(instancesKey)
    end
    return Anniversary2020Manager.instances_[instancesKey]
end


function Anniversary2020Manager.Destroy(instancesKey)
    instancesKey = instancesKey or Anniversary2020Manager.DEFAULT_NAME

    if Anniversary2020Manager.instances_[instancesKey] then
        Anniversary2020Manager.instances_[instancesKey]:release()
        Anniversary2020Manager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function Anniversary2020Manager:ctor(instancesKey)
    self.super.ctor(self)

    if Anniversary2020Manager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function Anniversary2020Manager:initial()
    self:GetFacade():RegistObserver(SGL.ANNIV2020_SHOP_UPGRADE, mvc.Observer.new(self.onShopUpgradeHandler_, self))
    self:GetFacade():RegistObserver(POST.ANNIV2020_STORY_UNLOCK.sglName, mvc.Observer.new(self.onUnlockStoryHandler_, self))

    self.homeData_        = {}
    self.puzzlesData_     = {}
    self.hangingData_     = {}
    self.exploreingId_    = 0
    self.exploreMainData_ = {}
    self.exploreHomeData_ = {}
    self.exploreTeamData_ ={}
    self.storyUnlockMap_  = {}
    self:initSweepConfigs_()
    self:initHangConfigs_()
end


function Anniversary2020Manager:release()
    self:GetFacade():UnRegistObserver(SGL.ANNIV2020_SHOP_UPGRADE, self)
    self:GetFacade():UnRegistObserver(POST.ANNIV2020_STORY_UNLOCK.sglName, self)
end


function Anniversary2020Manager:cleanAllSpineCache()
    SpineCache(SpineCacheName.ANNIVERSARY_2020):clearCache()
end


-------------------------------------------------
-- conf define

function Anniversary2020Manager:getHpGoodsId()
    return checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('hpGoodsId'))
end

function Anniversary2020Manager:getShopCurrencyId()
    return checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('mallCurrency'))
end

function Anniversary2020Manager:getShopExpId()
    return checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('mallExpGoodsId'))
end

function Anniversary2020Manager:getPuzzleGoodsId()
    return checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('puzzleGoodsId'))
end

function Anniversary2020Manager:getPuzzleRewards()
    return checktable(CONF.ANNIV2020.BASE_PARMS:GetValue('puzzleRewards'))
end

function Anniversary2020Manager:getHangCountdownTime()
    return checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('hangTime'))
end
-------------------------------------------------
-- home data

function Anniversary2020Manager:getHomeData()
    return self.homeData_
end
function Anniversary2020Manager:setHomeData(initData)
    self.homeData_ = initData or {}

    -- 初始化 解锁故事
    self:initStoryUnlockMap()

    -- 初始化 探索体力
    self:initExploreHp()

    -- 检测 商店等级
    self:checkShopLevel()

    -- 初始 挂机剩余时间
    self:setHangingLeftSeconds(self:getHomeData().hangLeftSeconds)

    -- 初始 拼图进度
    self:setPuzzlesProgress(self:getHomeData().progress)
end


function Anniversary2020Manager:isClosed()
    return checkint(self:getHomeData().isEnd) == 1
end


function Anniversary2020Manager:initExploreHp()
    local hpRecoverNum     = checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('hpRecoverNum'))
    local hpRecoverSeconds = checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('hpRecoverSeconds'))
    local homeData = self:getHomeData()
    local hpData   = {
        hpGoodsId             = self:getHpGoodsId(),                        -- 体力道具id
        hpUpperLimit          = -1,                                         -- 体力上限
        hpRestoreTime         = 0,                                          -- 每点体力恢复时间
        hpNextRestoreTime     = checkint(homeData.jumpGridDrawLeftSeconds), -- 下点体力恢复时间
        hp                    = checkint(homeData.jumpGridHp),              -- 当前体力值
        hpPurchaseCmd         = POST.ANNIV2020_EXPLORE_DRAW_HP,             -- 购买命令
        hpBuyOnceNum          = hpRecoverNum,                               -- 购买恢复体力数
        hpMaxPurchaseTimes    = -1,                                         -- 最大购买次数
        calcNextRestoreTimeCb = function()
            return hpRecoverSeconds
        end
    }
    app.activityHpMgr:InitHpData(hpData)

    -- update moneyNode
    app:DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {hpGoodsId = self:getHpGoodsId()})
end


--[[
是否打开过 周年庆主界面打脸
]]
function Anniversary2020Manager:IsOpenedHomePoster()
    return LOCAL.ANNIV2020.IS_OPENED_HOME_POSTER():Load()
end
function Anniversary2020Manager:SetOpenedHomePoster(isOpened)
    LOCAL.ANNIV2020.IS_OPENED_HOME_POSTER():Save(isOpened == true)
end


--[[
显示 周年庆回顾动画 弹窗
]]
function Anniversary2020Manager:ShowReviewAnimationDialog()
    local reviewAnimationView = require('Game.views.anniversary20.Anniversary20ReviewAnimationView').new()
    app.uiMgr:GetCurrentScene():AddDialog(reviewAnimationView)
end


--[[
打开 外部浏览器看周年庆h5
]]
function Anniversary2020Manager:OpenReviewBrowserUrl()
    local urlParams = {
        string.fmt('host=%1',     tostring(Platform.serverHost)),
        string.fmt('playerId=%1', tostring(app.gameMgr:GetUserInfo().playerId)),
        string.fmt('serverId=%1', tostring(app.gameMgr:GetUserInfo().serverId)),
    }
    local targetUrl = string.fmt('http://notice-%1/anniversary2020/index.html?%2', Platform.serverHost, table.concat(urlParams, '&'))
    -- FTUtils:openUrl(targetUrl)

    local webBlockLayer = ui.layer({color = '#666666FF', enable = true})
    app.uiMgr:GetCurrentScene():AddDialog(webBlockLayer)

    local shareNodeLayer = ui.image({img = _res('ui/anniversary20/sahre_annive_img.jpg'), p = display.center})
	webBlockLayer:addChild(shareNodeLayer)
    shareNodeLayer:setVisible(false)
    
    local codeImgLayer = ui.layer({p = cc.p(135, 124)})
    shareNodeLayer:addChild(codeImgLayer)

    local innerWebView = ccexp.WebView:create()
    innerWebView:setAnchorPoint(ui.cc)
    innerWebView:setPosition(display.center)
    innerWebView:setContentSize(display.size)
    innerWebView:setScalesPageToFit(true)
    webBlockLayer:addChild(innerWebView)

    innerWebView:setOnShouldStartLoading(function(webView, url)
        local scheme = 'liuzhipeng'
        local urlInfo = string.split(url, '://')
        if 2 == table.nums(urlInfo) then
            if urlInfo[1] == scheme then
                local urlParams = string.split(urlInfo[2], '&')
                local params = {}
                for k,v in pairs(urlParams) do
                    local param = string.split(v, '=')
                    -- 构造表单做get请求 所以结尾多一个？
                    -- params[param[1]] = string.split(param[2], '?')[1]
                    -- 构造表单做get请求（win上面的ie浏览器结尾多一个/，其他浏览器或其他平台尾多一个？，mac模拟器又啥都没有，所以不能用上面的）
                    local lastChar = string.sub(param[2], string.len(param[2]))
                    if lastChar == '/' or lastChar == '?' then
                        params[param[1]] = string.sub(param[2], 0, string.len(param[2]) - 1)
                    else
                        params[param[1]] = param[2]
                    end
                end

                if params.action then
                    if 'close' == params.action then
                        innerWebView:runAction(cc.RemoveSelf:create())
                        webBlockLayer:runAction(cc.RemoveSelf:create())

                    elseif 'reload' == params.action then
                        innerWebView:reload()

                    elseif 'share' == params.action then
                        local qrcode64 = string.urldecode(checkstr(params.code64))
                        if string.len(qrcode64) > 0 then
                            codeImgLayer:addAndClear(cc.utils:createSpriteFromBase64(qrcode64))
                        end
                        
                        local platformType = checkint(params.platformType)
                        shareNodeLayer:setVisible(true)
                        cc.utils:captureNode(function(isOk, path)
                            shareNodeLayer:setVisible(false)
                            if device.platform == 'ios' or device.platform == 'android' then
                                local AppSDK = require('root.AppSDK')
                                local errMsg = AppSDK.GetInstance():InvokeShare(platformType, {
                                    image = path, 
                                    title = '飨识三秋，只因有你#食之契约#和你的3周年点滴回忆', 
                                    text  = '#食之契约#三周年庆典盛大开幕！联动火热进行中，周年庆典舞会即将开启，一起加入吧！送您一份周年礼物，赶快打开看看吧~', 
                                    myurl = string.fmt('http://notice-%1/anniversary2020/index.html?share=%2', Platform.serverHost, params.shareCode),
                                    type  = CONTENT_TYPE.C2DXContentTypeImage
                                })
                                if errMsg then
                                    innerWebView:evaluateJS('alert(\"' .. errMsg .. '\")')
                                end
                            else
                                AppFacade.GetInstance():DispatchObservers('SHARE_REQUEST_RESPONSE')
                            end
                        end, 'shareAnniv2020.jpg', shareNodeLayer, 1)

                    else
                        return true
                    end
                end
                return false
            end
        end
        return true
    end)
    innerWebView:loadURL(targetUrl)
end


-------------------------------------------------------------------------------
-- shop about
-------------------------------------------------------------------------------

-- show currency
function Anniversary2020Manager:getShopCurrency()
    return app.goodsMgr:getGoodsNum(self:getShopCurrencyId())
end


-- shop exp
function Anniversary2020Manager:getShopExp()
    return app.goodsMgr:getGoodsNum(self:getShopExpId())
end


-- shop level
function Anniversary2020Manager:getShopLevel()
    return checkint(self.shopLevel_)
end


function Anniversary2020Manager:isShopMaxLevel()
    local MALL_MAX_LEVEL = CONF.ANNIV2020.MALL_LEVEL:GetLength()
    return self:getShopLevel() >= MALL_MAX_LEVEL
end


function Anniversary2020Manager:checkShopLevel()
    if self:isShopMaxLevel() then
        return
    end

    local oldLevel = self:getShopLevel()
    local newLevel = oldLevel
    for _, expId in ipairs(CONF.ANNIV2020.MALL_LEVEL:GetIdListDown()) do
        local levelConf = CONF.ANNIV2020.MALL_LEVEL:GetValue(expId)
        if self:getShopExp() >= checkint(levelConf.totalExp) then
            newLevel = checkint(levelConf.level)
            break
        end
    end

    if oldLevel ~= newLevel then
        self.shopLevel_ = newLevel
    end
end


function Anniversary2020Manager:onShopUpgradeHandler_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if data.isUpgrade then
        local tipsText = string.fmt(__('恭喜商店升到_num_级'), {_num_ = data.newLevel})
        app.uiMgr:ShowInformationTips(tipsText)
    end
end


-------------------------------------------------------------------------------
-- story about
-------------------------------------------------------------------------------

function Anniversary2020Manager:initStoryUnlockMap()
    self.storyUnlockMap_ = {}
    for _, storyId in ipairs(self:getHomeData().unlockStoryList or {}) do
        self.storyUnlockMap_[tostring(storyId)] = true
    end
end


function Anniversary2020Manager:getStoryUnlockMap()
    return checktable(self.storyUnlockMap_)
end


function Anniversary2020Manager:isStoryUnlocked(storyId)
    return self:getStoryUnlockMap()[tostring(storyId)] == true
end


function Anniversary2020Manager:toUnlockStory(storyId, endedCb)
    self.unlockedStoryCb_ = endedCb
    app.httpMgr:Post(POST.ANNIV2020_STORY_UNLOCK.postUrl, POST.ANNIV2020_STORY_UNLOCK.sglName, {storyId = storyId})
end


function Anniversary2020Manager:onUnlockStoryHandler_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    local storyId = checkint(data.requestData.storyId)
    self:getStoryUnlockMap()[tostring(storyId)] = true

    if self.unlockedStoryCb_ then
        self.unlockedStoryCb_(storyId)
    end
end


-- check playStory
function Anniversary2020Manager:checkPlayStory(storyId, endedCb)
    if self:isStoryUnlocked(storyId) then
        if endedCb then endedCb() end
    else
        self.checkPlayStoryEndedCb_ = endedCb
        self:toUnlockStory(storyId, function(unlockedStoryId)
            self:playStory(unlockedStoryId, self.checkPlayStoryEndedCb_)
        end)
    end
end


-- play story
function Anniversary2020Manager:playStory(storyId, endedCb)
    local confPath   = CONF.ANNIV2020.STORY_CONTENT:GetFilePath()
    local operaStage = require( "Frame.Opera.OperaStage" ).new({id = storyId, path = confPath, guide = false, isHideBackBtn = true, cb = function()
        if endedCb then endedCb() end
    end})
    sceneWorld:addChild(operaStage, GameSceneTag.Dialog_GameSceneTag)
end


-- puzzle story
function Anniversary2020Manager:checkPlayPuzzleStory(endedCb)
    local storyId = checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('story4'))
    self:checkPlayStory(storyId, endedCb)
end


function Anniversary2020Manager:checkPlayPuzzleCompletedStory(endedCb)
    local storyId = checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('story3'))
    self:checkPlayStory(storyId, endedCb)
end


-- hang story
function Anniversary2020Manager:checkPlayHangOpenStory(endedCb)
    local storyId = checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('story2'))
    self:checkPlayStory(storyId, endedCb)
end


-- explore story
function Anniversary2020Manager:checkPlayExploreOpenStory(endedCb)
    local storyId = checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('story1'))
    self:checkPlayStory(storyId, endedCb)
end


-------------------------------------------------------------------------------
-- puzzle game
-------------------------------------------------------------------------------

-- puzzles goodsNum
function Anniversary2020Manager:getPuzzlesGoodsNum()
    return app.goodsMgr:getGoodsNum(self:getPuzzleGoodsId())
end
function Anniversary2020Manager:consumePuzzlesGoodsNum(consumeNum)
    CommonUtils.DrawRewards({
        {goodsId = self:getPuzzleGoodsId(), num = -consumeNum}
    })
end


-- puzzle progress
function Anniversary2020Manager:getPuzzlesProgress()
    return checkint(self.puzzlesData_.puzzleProgress)
end
function Anniversary2020Manager:setPuzzlesProgress(puzzleProgress)
    self.puzzlesData_.puzzleProgress = checkint(puzzleProgress)

    -- update unlockNum
    self.puzzlesData_.puzzleUnlockNum = 0
    for _, puzzleId in ipairs(CONF.ANNIV2020.PUZZLE_GAME:GetIdListDown()) do
        local puzzleConf = CONF.ANNIV2020.PUZZLE_GAME:GetValue(puzzleId)
        if self:getPuzzlesProgress() >= checkint(puzzleConf.num) then
            self.puzzlesData_.puzzleUnlockNum = puzzleId
            break
        end
    end

    -- update skillId
    for _, unlockId in ipairs(CONF.ANNIV2020.PUZZLE_SKILL_UNLOCK:GetIdListDown()) do
        local unlockConf = CONF.ANNIV2020.PUZZLE_SKILL_UNLOCK:GetValue(unlockId)
        if self:getPuzzlesUnlockNum() >= checkint(unlockConf.unlockNeedNum) then
            self:setPuzzleSkillIndex(unlockConf.id)
            break
        end
    end
end


-- puzzle unlockNum
function Anniversary2020Manager:getPuzzlesUnlockNum()
    return checkint(self.puzzlesData_.puzzleUnlockNum)
end


-- puzzle skillIndex
function Anniversary2020Manager:getPuzzleSkillIndex()
    return checkint(self.puzzlesData_.puzzleSkillIndex)
end
function Anniversary2020Manager:setPuzzleSkillIndex(skillIndex)
    self.puzzlesData_.puzzleSkillIndex = checkint(skillIndex)
end


-- puzzle skillConf
function Anniversary2020Manager:getPuzzleSkillConf(skillIndex)
    local skillIdx  = checkint(skillIndex)
    local skillConf = CONF.ANNIV2020.PUZZLE_SKILL_UNLOCK:GetValue(skillIdx)
    local buffId    = checkint(checktable(skillConf.activeSkills)[1])
    local buffConf  = CommonUtils.GetConfig('common', 'payBuff', buffId)
    return buffConf or {}
end


-------------------------------------------------------------------------------
-- hang game
-------------------------------------------------------------------------------

-- init hangConfigs
function Anniversary2020Manager:initHangConfigs_()
    self.materialsConfigsMap_ = {}
    for _, materialConf in pairs(CONF.ANNIV2020.HANG_MATERIAL_TYPE:GetAll()) do
        local materialType = checkint(materialConf.type)
        if not self.materialsConfigsMap_[materialType] then
            self.materialsConfigsMap_[materialType] = {}
        end
        table.insert(self.materialsConfigsMap_[materialType], materialConf)
    end
end


-- get hangConfig by type
function Anniversary2020Manager:getMaterialsConfigByType(materialType)
    return checktable(self.materialsConfigsMap_[materialType])
end


-- hang homeData
function Anniversary2020Manager:updateHangHomeData(hangHomeData)
    self.hangingData_     = {}
    local newHangHomeData = checktable(hangHomeData)

    -- update hangingLeftSeconds
    self:setHangingLeftSeconds(newHangHomeData.hangLeftSeconds)

    -- update hangingMaterials
    self:setHangingMaterials(newHangHomeData.hangingMaterials)

    -- update unlockFormulaMap
    self.hangingData_.unlockFormulaNum = 0
    self.hangingData_.unlockFormulaMap = {}
    for _, formulaId in ipairs(newHangHomeData.unlockedFormulas) do
        self:addHangUnlockFormulaId(formulaId)
    end

    -- update drawnCollectMap
    self.hangingData_.drawnCollectMap = {}
    for _, collectId in ipairs(newHangHomeData.drawnHangRewards) do
        self:addHangDrawnCollectId(collectId)
    end
end


-- hang hangingTime
function Anniversary2020Manager:setHangingLeftSeconds(leftSeconds)
    self.hangingData_.hangingLeftSeconds = checkint(leftSeconds)
    self.hangingData_.hangingTimestamp   = os.time() + checkint(leftSeconds)
end
function Anniversary2020Manager:getHangingTimestamp()
    return checkint(self.hangingData_.hangingTimestamp)
end


-- hang hangingMaterials
function Anniversary2020Manager:getHangingMaterials()
    return self.hangingData_.hangingMaterials
end
function Anniversary2020Manager:setHangingMaterials(materials)
    self.hangingData_.hangingMaterials = materials
end


-- hang unlockFormulaId
function Anniversary2020Manager:hasHangUnlockFormulaId(formulaId)
    return self.hangingData_.unlockFormulaMap[checkint(formulaId)] ~= nil
end
function Anniversary2020Manager:addHangUnlockFormulaId(formulaId)
    if not self.hangingData_.unlockFormulaMap[checkint(formulaId)] then
        self.hangingData_.unlockFormulaNum = self.hangingData_.unlockFormulaNum + 1
    end
    self.hangingData_.unlockFormulaMap[checkint(formulaId)] = true
end


-- hang unlockFormulaNum
function Anniversary2020Manager:getHangUnlockFormulaIdNum()
    return checkint(self.hangingData_.unlockFormulaNum)
end


-- hang drawnCollectId
function Anniversary2020Manager:hasHangDrawnCollectId(collectId)
    return self.hangingData_.drawnCollectMap[checkint(collectId)] ~= nil
end
function Anniversary2020Manager:addHangDrawnCollectId(collectId)
    self.hangingData_.drawnCollectMap[checkint(collectId)] = true
end


-------------------------------------------------------------------------------
-- explore game : main
-------------------------------------------------------------------------------

-- explore sweepConf conf
function Anniversary2020Manager:initSweepConfigs_()
    self._sweepConfsMap = {}
    local allSweepConfs = CONF.ANNIV2020.EXPLORE_SWEEP:GetAll()
    for _, sweepConf in pairs(allSweepConfs) do
        local exploreModuleId = checkint(sweepConf.exploreModuleId)
        self._sweepConfsMap[exploreModuleId] = self._sweepConfsMap[exploreModuleId] or {}
        table.insert(self._sweepConfsMap[exploreModuleId], sweepConf)
    end

    for _, sweepConfs in ipairs(self._sweepConfsMap) do
        table.sort(sweepConfs, function(a, b)
            return checkint(a.floorMin) < checkint(b.floorMin)
        end)
    end
end


function Anniversary2020Manager:getExploreSweepConfsAt(exploreModuleId)
    return checktable(self._sweepConfsMap[exploreModuleId])
end


-- explore mainData
function Anniversary2020Manager:updateExploreMainData(exploreMainData)
    self.exploreMainData_ = checktable(exploreMainData)
    self:setExploringId(0)

    for _, entranceData in ipairs(self:getExploreEntranceDatas()) do
        if checkint(entranceData.exploring) == 1 then
            self:setExploringId(entranceData.exploreModuleId)
            break
        end
    end
end


-- explore entranceDatas
--[[
    return {
        {
            exploreModuleId : int 探索id
            exploring       : int 是否正在探索中（1：是，0：否）
            maxFloor        : int 最高层数
            currentFloor    : int 当前层数
        },
        ...
    }
]]
function Anniversary2020Manager:getExploreEntranceDatas()
    return checktable(self.exploreMainData_.explore)
end
--[[
获取队伍信息
@return _ list {
	[1] = {
		{id = nil},
		{id = nil},
		{id = nil},
		...
	},
	...
}
--]]

function Anniversary2020Manager:GetTeamData()
    local teamState  = self:getExploreTeamStateMap()
    for i, teamData in pairs(self.exploreTeamData_) do
        for i = #teamData , -1 do
            local cardData = teamData[i]
            local cardValues =  teamState[cardData.id]
            if cardValues then
                if tonumber(cardValues.hp) <= 0 then
                    table.remove(teamData ,i)
                end
            end
        end
    end
    return self.exploreTeamData_
end
--[[
获取队伍信息
@return _ list {
	[1] = {
		{id = nil},
		{id = nil},
		{id = nil},
		...
	},
	...
}
--]]
function Anniversary2020Manager:SetTeamData(teamData)
    self.exploreTeamData_ = clone(teamData)
end

-- explore teamStateMap
--[[
    return { key: 卡牌自增ID = {
            hp     : float 损失血量百分比
            energy : float 增加能量百分比
        }
    }
]]
function Anniversary2020Manager:getExploreTeamStateMap()
    return checktable(self.exploreMainData_.teamState)
end
--[[
    设置卡牌的能量技
    data {
        energy   : float 卡牌主角技能量百分比
        hp       : float 卡牌血量
    }
--]]
function Anniversary2020Manager:setExploreTeamCardStateByPlayCardId(playerCardId , data)
    local teamState = self:getExploreTeamStateMap()
    if not teamState[tostring(playerCardId)] then
        teamState[tostring(playerCardId)] = {}
    end
    teamState[tostring(playerCardId)].energy = 1 - data.energy
    teamState[tostring(playerCardId)].hp = 1 - data.hp
end

--[[
    设置卡牌的能量技
--]]
function Anniversary2020Manager:setExploreTeamCardStateByCardId(cardId , data)
    local cardData = app.gameMgr:GetCardDataByCardId(cardId)
    self:setExploreTeamCardStateByPlayCardId(cardData.id , data)
end
function Anniversary2020Manager:setExploreCardsDataHpAndEnergyByTeamState()
    local hp =  FOOD.ANNIV2020.TEAM_STATE.HP
    local energy =  FOOD.ANNIV2020.TEAM_STATE.ENERGY
    local allCards = app.gameMgr:GetUserInfo().cards
    local teamState = self:getExploreTeamStateMap()
    for playerCardId, cardData in pairs(allCards) do
        if teamState[tostring(playerCardId)] then
            cardData[hp] = 1 - tonumber(teamState[tostring(playerCardId)].hp)
            cardData[energy] = 1 - tonumber(teamState[tostring(playerCardId)].energy)
        else
            cardData[hp] = 1.00
            cardData[energy] = 0.00
        end
    end
end



-- explore exploreingId
function Anniversary2020Manager:getExploringId()
    return checkint(self.exploreingId_)
end
function Anniversary2020Manager:setExploringId(exploreModuleId)
    self.exploreingId_ = checkint(exploreModuleId)
end


-------------------------------------------------------------------------------
-- explore game : home
-------------------------------------------------------------------------------

-- explore homeData
function Anniversary2020Manager:updateExploreHomeData(exploreHomeData)
    self.exploreHomeData_ = checktable(exploreHomeData)
end

-- explore homeData
function Anniversary2020Manager:getExploreHomeData()
    return self.exploreHomeData_
end

-- explore exploreingFloor
function Anniversary2020Manager:getExploreingFloor()
    return checkint(self.exploreHomeData_.floor)
end
function Anniversary2020Manager:setExploreingFloor(floorNum)
    self.exploreHomeData_.floor = checkint(floorNum)
end


function Anniversary2020Manager:isExploreingBossFloor()
    return self:getExploreingFloor() > 0 and self:getExploreingFloor() % FOOD.ANNIV2020.DEFINE.EXPLORE_FLOOR_BOSS == 0
end


function Anniversary2020Manager:isExploreingLastFloor()
    return self:getExploreingFloor() >= FOOD.ANNIV2020.DEFINE.EXPLORE_FLOOR_MAX
end


-- exploreing rewards
function Anniversary2020Manager:getExploreingRewards()
    if not self.exploreHomeData_.stashRewards then
        self:resetExploreingRewards()
    end
    return self.exploreHomeData_.stashRewards
end
function Anniversary2020Manager:resetExploreingRewards()
    self.exploreHomeData_.stashRewards = {}
end
function Anniversary2020Manager:mergerExploreingRewards(newRewards)
    local addGoodsData = {}
    for i, v in pairs(newRewards) do
        local goodsId = checkint(v.goodsId)
        local isHave = false
        for index, stashReward in pairs(self.exploreHomeData_.stashRewards) do
            if checkint(stashReward.goodsId) == goodsId then
                isHave = true
                stashReward.num = v.num +  stashReward.num
                break 
            end
        end
        if not isHave then
            addGoodsData[#addGoodsData+1] = clone(v)
        end
    end
    if #addGoodsData > 0  then
        table.insertto(self.exploreHomeData_.stashRewards ,addGoodsData )
    end
end



-- exploreing buffs
function Anniversary2020Manager:getExploreingBuffs()
    return checktable(self.exploreHomeData_.buffs)
end

function Anniversary2020Manager:resetExploreingBuffs()
    self.exploreHomeData_.buffs = {}
end
--[[
    进入下一层生效buff
--]]
function Anniversary2020Manager:nextFloorTakeEffectBuff()
    local exploreBuffConf = CONF.ANNIV2020.EXPLORE_BUFF:GetAll()
    local buffs = self:getExploreingBuffs()
    -- type 为2的buff 为仅在当前层有用要删除 只有战斗技能在本次探索生效
    for i = #buffs , 1, -1 do
        local id = buffs[i]
        if checkint(exploreBuffConf[tostring(id)].type) == 2 then
            table.remove(buffs , i )
        end
    end
end

function Anniversary2020Manager:ExploreBattleComplete()
    local exploreBuffConf = CONF.ANNIV2020.EXPLORE_BUFF:GetAll()
    local buffs = self:getExploreingBuffs()
    -- type 为2的buff 为仅在当前层有用要删除 只有战斗技能在本次探索生效
    for i = #buffs , 1, -1 do
        local id = buffs[i]
        if checkint(exploreBuffConf[tostring(id)].type) == 1 then
            table.remove(buffs , i )
        end
    end
end
---@param buffId number
---@deprecated 添加新获取的技能
function Anniversary2020Manager:addExploreingBuff(buffId)
    buffId = checkint(buffId)
    local exploreBuffConf = CONF.ANNIV2020.EXPLORE_BUFF:GetAll()
    local buffs = self:getExploreingBuffs()
    if #buffs == 0 then
        buffs[#buffs+1] = buffId
    else
        -- type 为1是战斗buff  战斗buff不可以共同存在的
        if checkint(exploreBuffConf[tostring(buffId)].type) == 1 then
            for i = #buffs , 1, -1 do
                local id = buffs[i]
                if checkint(exploreBuffConf[tostring(id)].type) == 1 then
                    table.remove(buffs , i )
                end
            end
        end
        buffs[#buffs+1] = buffId
    end
end

---@deprecated 获取探索过程中可以使用测战斗技能
function Anniversary2020Manager:GetExploreBattleSkillData()
    local battleSkillData = {}
    local exploreBuffConf = CONF.ANNIV2020.EXPLORE_BUFF:GetAll()
    -- 1. 先探索技能中的战斗buff
    local buffs = app.anniv2020Mgr:getExploreingBuffs()
    for i = #buffs , 1, -1 do
        local id = buffs[i]
        if checkint(exploreBuffConf[tostring(id)].type) == 1  then
            local skillData = GlobalEffectConstructStruct.New(
                    buffs[i],
                    exploreBuffConf[tostring(id)].skillId,
                    1
            )
            battleSkillData[#battleSkillData+1] = skillData
            break
        end
    end
    -- 2. 取出拼图技能中的战斗buff
    local pluzzleSkillIndex = self:getPuzzleSkillIndex()
    if pluzzleSkillIndex > 0 then
        local puzzleSkillConf = self:getPuzzleSkillConf(pluzzleSkillIndex)
        local puzzleBuffId  = checkint(puzzleSkillConf.id)
        local puzzleSkillId = checkint(puzzleSkillConf.skillId)
        if puzzleBuffId > 0 and puzzleSkillId > 0 then
            local skillData = GlobalEffectConstructStruct.New(
                puzzleBuffId,
                puzzleSkillId,
                1
            )
            battleSkillData[#battleSkillData+1] = skillData
        end
    end
    return battleSkillData
end

-- explore exploreingMaps
function Anniversary2020Manager:getExploreingMapDatas()
    return checktable(self.exploreHomeData_.map)
end
function Anniversary2020Manager:setExploreingMapData(mapId , isPassed)
    self.exploreHomeData_.map[tostring(mapId)].isPassed = isPassed
end

function Anniversary2020Manager:setExploreingMapDatas(mapDatas)
    self.exploreHomeData_.map = checktable(mapDatas)
end


-- exploreMap data
function Anniversary2020Manager:getExploreingMapDataAt(mapGridId)
    return checktable(self:getExploreingMapDatas()[tostring(mapGridId)])
end


-- exploreMap type
--@see FOOD.ANNIV2020.EXPLORE_TYPE
function Anniversary2020Manager:getExploreingMapTypeAt(mapGridId)
    return checkint(self:getExploreingMapDataAt(mapGridId).type)
end


-- exploreMap refId
--@see FOOD.ANNIV2020.EXPLORE_TYPE_CONF
function Anniversary2020Manager:getExploreingMapRefIdAt(mapGridId)
    return checkint(self:getExploreingMapDataAt(mapGridId).refId)
end

function Anniversary2020Manager:getMapGridPath(mapGridId)
    local mapGridType = self:getExploreingMapTypeAt(mapGridId)
    local EXPLORE_TYPE = FOOD.ANNIV2020.EXPLORE_TYPE
    if mapGridType == EXPLORE_TYPE.EMPTY then
        return _res(string.format('ui/anniversary20/explore/grid/air_%d' , self:getExploringId()) )
    elseif mapGridType == EXPLORE_TYPE.MONSTER_NORMAL then
        local refId = self:getExploreingMapRefIdAt(mapGridId)
        local exploreMonsterConf = FOOD.ANNIV2020.EXPLORE_TYPE_CONF[mapGridType]:GetValue(refId)
        local picture = exploreMonsterConf.picture
        return _res(string.format('ui/anniversary20/explore/grid/%s' , picture))
    elseif mapGridType == EXPLORE_TYPE.MONSTER_ELITE then
        return _res('ui/anniversary20/explore/grid/cream')
    elseif mapGridType == EXPLORE_TYPE.MONSTER_BOSS then
        return _res(string.format('ui/anniversary20/explore/grid/boss_%d' , self:getExploringId()))
    elseif mapGridType == EXPLORE_TYPE.OPTION then
        return _res('ui/anniversary20/explore/grid/ques')
    elseif mapGridType == EXPLORE_TYPE.CHEST then
        return _res(string.format('ui/anniversary20/explore/grid/box_%d' , self:getExploringId()))
    elseif mapGridType == EXPLORE_TYPE.BUFF then
        return _res('ui/anniversary20/explore/grid/buff')
    end
end


-- exploreMap passed
function Anniversary2020Manager:isExploreingPassedAt(mapGridId)
    return checkint(self:getExploreingMapDataAt(mapGridId).isPassed) == 1
end
function Anniversary2020Manager:setExploreingPassedAt(mapGridId, isPassed)
    self:getExploreingMapDataAt(mapGridId).isPassed = isPassed and 1 or 0
end
-- 获取 通关的要求
function Anniversary2020Manager:getExploreingFloorPassData(exploreModuleId ,floorId)
    local exploreRateConf = CONF.ANNIV2020.EXPLORE_RATE:GetAll()
    exploreModuleId = checkint(exploreModuleId)
    floorId = checkint(floorId)
    for id , exploreData in pairs(exploreRateConf) do
        if checkint(exploreData.exploreModuleId) == exploreModuleId then
            if checkint(exploreData.floorMin) <= floorId and floorId <= checkint(exploreData.floorMax) then
                return exploreData
            end
        end
    end
end

function Anniversary2020Manager:isExploreingFloorPassed()
    local isPassed = true
    -- 1. 先检测是否获取到通关buff
    local buffs = self:getExploreingBuffs()
    local completeBuff = FOOD.ANNIV2020.EXPLORE_BUFF_TYPE.COMPLETE_TASK
    local isHaveCompleteBuff = false
    for index, buffId in pairs(buffs) do
        if checkint(buffId) == completeBuff then
            isHaveCompleteBuff = true
            break 
        end
    end
    if isHaveCompleteBuff then
        return isPassed
    end
    local exploreModuleId  = self:getExploringId()
    local floorId = self:getExploreingFloor()
    local mapDatas = self:getExploreingMapDatas()
    -- 2. 检测是否符合通关条件
    local exploreData = self:getExploreingFloorPassData(exploreModuleId , floorId)
    for i, v in pairs(exploreData) do
        local affirmGridTypes = exploreData.affirmGridTypes
        for index, mapGridType in pairs(affirmGridTypes) do
            mapGridType = checkint(mapGridType)
            local num = 0
            for mapId, mapData in pairs(mapDatas) do
                if checkint(mapData.type) == mapGridType then
                    if checkint(mapData.isPassed) == 1 then
                        num = num + 1
                    end
                end
            end
            if checkint(exploreData.affirmGridNum[index]) > num then
                isPassed = false
                break
            end
        end
    end
    return isPassed
end

function Anniversary2020Manager:GetExploreProgressStr()
    local exploreModuleId  = self:getExploringId()
    local floorId = self:getExploreingFloor()
    local mapDatas = self:getExploreingMapDatas()
    local exploreData = self:getExploreingFloorPassData(exploreModuleId , floorId)
    for i, v in pairs(exploreData) do
        local affirmGridTypes = exploreData.affirmGridTypes
        for index, mapGridType in pairs(affirmGridTypes) do
            mapGridType = checkint(mapGridType)
            local num = 0
            for mapId, mapData in pairs(mapDatas) do
                if checkint(mapData.type) == mapGridType then
                    if checkint(mapData.isPassed) == 1 then
                        num = num + 1
                    end
                end
            end
            return table.concat({num ,exploreData.affirmGridNum[index] } , "/")
        end
    end
    return ""
end
---ExploreResult
---@param signal Signal
function Anniversary2020Manager:ExploreResult(signal)
    local data = signal:GetBody()
    local mapGridId = data.mapGridId
    local isPassed = checkint(self:getExploreingMapDataAt(mapGridId).isPassed)
    -- 已经通过这一关就不在处理
    if isPassed == 1 then return end
    -- 是指本关卡已经通过
    local mapGridType = app.anniv2020Mgr:getExploreingMapTypeAt(mapGridId)
    local refId = checkint(app.anniv2020Mgr:getExploreingMapRefIdAt(mapGridId))
    local ANNIV2020 = FOOD.ANNIV2020
    self:setExploreingMapData(mapGridId  , 1)
    if checkint(data.isPassed) == 1 then
        if mapGridType == ANNIV2020.EXPLORE_TYPE.BUFF then
            -- 处理buff 数据
            if refId == ANNIV2020.EXPLORE_BUFF_TYPE.WEAK_OF_DEAD then
                if checkint(data.playerCardId) > 0  then
                    local cardData =  app.gameMgr:GetCardDataById(data.playerCardId)
                    local HP = ANNIV2020.TEAM_STATE.HP
                    if (cardData[HP] and tonumber(cardData[HP] > 0 )) or (not cardData[HP])  then
                        local ENERGY = ANNIV2020.TEAM_STATE.ENERGY
                        local energy = cardData[ENERGY] and tonumber(cardData[ENERGY]) or 0
                        self:setExploreTeamCardStateByPlayCardId(
                            data.playerCardId ,
                            { hp = 1 , energy =energy}
                        )
                    else
                        self:setExploreTeamCardStateByPlayCardId(
                                data.playerCardId ,
                                { hp = 1 , energy = 0.0}
                        )
                    end

                end
            else
                app.anniv2020Mgr:addExploreingBuff(refId)
            end

        elseif mapGridType ~= ANNIV2020.EXPLORE_TYPE.EMPTY then
            -- 增加奖励显示
            local optionOneConf =  ANNIV2020.EXPLORE_TYPE_CONF[mapGridType]:GetValue(refId)
            local rewards = optionOneConf.rewards
            self:mergerExploreingRewards(rewards)
        end
    end
    -- 如果是战斗 战斗完成需要去除战斗buff
    if mapGridType == ANNIV2020.EXPLORE_TYPE.MONSTER_BOSS or
            mapGridType == ANNIV2020.EXPLORE_TYPE.MONSTER_ELITE or
            mapGridType == ANNIV2020.EXPLORE_TYPE.MONSTER_NORMAL then
        self:ExploreBattleComplete()
    end
end

function Anniversary2020Manager:AddObserver()
    if not self.isObserver then
        AppFacade.GetInstance():RegistObserver(ANNIVERSARY20_EXPLORE_RESULT_EVENT , mvc.Observer.new(self.ExploreResult, self) )
        self.isObserver = true
    end
end

return Anniversary2020Manager
