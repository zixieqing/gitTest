--[[
 * author : kaishiqi
 * descpt : 猫模块 - 猫咪节点
]]

---@class CatSpineNode
local CatSpineNode = class('CatSpineNode', function()
    return ui.layer({name = 'CatSpineNode', enableEvent = true})
end)

local RES_DICT = {
    DIE_IMAGE = _res('ui/catModule/catInfo/grow_cat_main_pic_die.png'),
    DIE_SPINE = _spn('ui/catModule/catInfo/anim/death_ligth'),
}

local ACTION_ENUM = {
    SPINE_REFRESH = 1,
}

local DEFAULT_SKINS = {
    [CatHouseUtils.CAT_GENE_PART.HEAD]  = {'0head', '0ear'}, -- 头部
    [CatHouseUtils.CAT_GENE_PART.EYE]   = {'0eye'},          -- 眼睛
    [CatHouseUtils.CAT_GENE_PART.TAIL]  = {'0weiba'},        -- 尾巴
    [CatHouseUtils.CAT_GENE_PART.TRUNK] = {'0body'},         -- 身体
}

local ANIME_NAME_DEFINE = {
    IDLE   = 'idle',        -- 闲置
    RUN    = 'run',         -- 跑动
    WALK   = 'walk',        -- 走动
    SHOWER = 'bath',        -- 洗澡
    FEED   = 'eat',         -- 喂食
    PLAY   = 'play',        -- 玩耍
    SLEEP  = 'sleep',       -- 睡觉
    TOILET = 'toilet',      -- 上厕所
    FEFUSE = 'idle_refuse', -- 摇头拒绝
}

local TRICK_ANIME_RANGE  = {MIN = 2, MAX = 6-4}
local TRICK_ANIME_DEFINE = {
    {
        {name = 'set',   min = 3, max = 6},  -- 坐下
        {name = 'tired', min = 2, max = 2},  -- 坐下 + 打哈欠
        {name = 'set',   min = 3, max = 6},  -- 坐下
    },
    {
        {name = 'scratch', min = 1, max = 2},  -- 抓挠
    }
}


local TOUCH_ANIME_LIST = {
    'idle_angry',
    'idle_happy',
    'scratch',
    'tired',
    'set',
}


--[[
    用法1：自己的猫咪 { catUuid : int }
    用法2：别人的猫咪 { catData : {
        catId : int  猫咪种族
        age   : int  猫咪年龄（可选，默认值1）
        gene  : list 猫咪基因id列表（可选，默认初始皮
        isAlive: bool 猫咪是否存活
    } }
]]
function CatSpineNode:ctor(args)
    local initArgs    = checktable(args)
    local initSize    = cc.size(200, 230)
    self.idleName_    = ANIME_NAME_DEFINE.IDLE
    self.isFreeMode_  = initArgs.freeMode == true
    self.idleLoopNum_ = 0
    self:setInitAnim(initArgs.initAnime or self.idleName_)
    self:setContentSize(initSize)
    self:setAnchorPoint(ui.cb)
    self:setScale(initArgs.scale or 1)

    -- create view
    self.viewData_ = CatSpineNode.CreateView(initSize)
    self:add(self:getViewData().view)

    ui.bindClick(self:getViewData().clickArea, function(sender)
        if self:getClickCB() then self:getClickCB()(self) end
    end)
    
    -- update view
    self:refreshNode(args)
end


function CatSpineNode:setClickEnabled(enable)
    self:getViewData().clickArea:setTouchEnabled(enable)
end


function CatSpineNode:refreshNode(args)
    local initArgs   = checktable(args)
    self.idleName_   = ANIME_NAME_DEFINE.IDLE
    self:setInitAnim(initArgs.initAnime or self.idleName_)

    if initArgs.catUuid then
        self:setCatUuid(initArgs.catUuid)
        
    elseif initArgs.catData then
        local catData = checktable(initArgs.catData)
        self:setCatAge(catData.age)
        self:setCatRace(catData.catId)
        self:setCatGenes(catData.gene)
        if catData.isAlive ~= nil then
            self:setCatIsDie(not catData.isAlive)
        end
    end

    self:checkCatModelAlive_()
end


function CatSpineNode:getViewData()
    return self.viewData_
end


---@return number
function CatSpineNode:getCatUuid()
    return self.catUuid_
end
function CatSpineNode:setCatUuid(catUuid)
    self.catUuid_     = catUuid
    self.playerCatId_ = CatHouseUtils.GetPlayerCatId(catUuid)
    if CatHouseUtils.GetPlayerId(catUuid) == app.gameMgr:GetPlayerId() then
        ---@type HouseCatModel
        self.catModel_ = app.catHouseMgr:getCatModel(self:getCatUuid())
        self:setCatRace(self.catModel_:getRace())
        self:checkCatModelAlive_()
        self:checkCatModelValue_()
    end
end
function CatSpineNode:getPlayerCatId()
    return checkint(self.playerCatId_)
end


---@return number
function CatSpineNode:getCatRace()
    return checkint(self.catRace_)
end
function CatSpineNode:setCatRace(race)
    self.catRace_ = checkint(race)
    self:markRefreshSpine_()
end


---@return number
function CatSpineNode:getCatAge()
    return checkint(self.catAge_)
end
function CatSpineNode:setCatAge(age)
    self.catAge_ = math.max(checkint(age), 1)
    self:markRefreshSpine_()
end


---@return number[]
function CatSpineNode:getCatGenes()
    return checktable(self.genes_)
end
function CatSpineNode:setCatGenes(geneList)
    self.genes_ = checktable(geneList)
    self:markRefreshSpine_()
end


---@return boolean
function CatSpineNode:isCatDie()
    return checkbool(self.isDie_)
end
function CatSpineNode:setCatIsDie(isDie)
    self.isDie_ = checkbool(isDie)
end


function CatSpineNode:getClickCB()
    return self.clickCB_
end
function CatSpineNode:setClickCB(callback)
    self.clickCB_ = callback
end

function CatSpineNode:getInitAnim()
    return self.initAnime_
end
function CatSpineNode:setInitAnim(animName)
    self.initAnime_   = animName
    if self:getInitAnim() then
        self.isDoIdling_  = self.initAnime_ == self.idleName_
    end
end
-------------------------------------------------
-- public

function CatSpineNode:getCurrentAnimeName()
    if self.spineNode_ then
        return self.spineNode_:getCurrent()
    end
    return ''
end


function CatSpineNode:isIdlingAnime()
    return self.isDoIdling_
end


function CatSpineNode:doIdleAnime()
    if self.spineNode_ then
        self.isDoIdling_ = true
        self.spineNode_:setAnimation(0, self.idleName_, true)
    else
        self:setInitAnim(self.idleName_)
    end
end


function CatSpineNode:doRunAnime()
    if self.spineNode_ then
        self.isDoIdling_ = false
        self.spineNode_:setAnimation(0, ANIME_NAME_DEFINE.RUN, true)
    else
        self:setInitAnim(ANIME_NAME_DEFINE.RUN)
    end
end


function CatSpineNode:doWalkAnime()
    if self.spineNode_ then
        self.isDoIdling_ = false
        self.spineNode_:setAnimation(0, ANIME_NAME_DEFINE.WALK, true)
    else
        self:setInitAnim(ANIME_NAME_DEFINE.WALK)
    end
end


function CatSpineNode:doRefuseAnime()
    if self.spineNode_ then
        self.isDoIdling_ = false
        self.spineNode_:setAnimation(0, ANIME_NAME_DEFINE.FEFUSE, false)
    end
end


function CatSpineNode:doShowerAnime(finishCB)
    self.animeFinishByShowerCB_ = finishCB
    if self.spineNode_ then
        self.isDoIdling_ = false
        self.spineNode_:setAnimation(0, ANIME_NAME_DEFINE.SHOWER, false)
    else
        if self.animeFinishByShowerCB_ then
            self.animeFinishByShowerCB_()
        end
    end
end


function CatSpineNode:doFeedAnime(finishCB)
    self.animeFinishByFeedCB_ = finishCB
    if self.spineNode_ then
        self.isDoIdling_ = false
        self.spineNode_:setAnimation(0, ANIME_NAME_DEFINE.FEED, false)
    else
        if self.animeFinishByFeedCB_ then
            self.animeFinishByFeedCB_()
        end
    end
end


function CatSpineNode:doPlayAnime(finishCB)
    self.animeFinishByPlayCB_ = finishCB
    if self.spineNode_ then
        self.isDoIdling_ = false
        self.spineNode_:setAnimation(0, ANIME_NAME_DEFINE.PLAY, false)
    else
        if self.animeFinishByPlayCB_ then
            self.animeFinishByPlayCB_()
        end
    end
end


function CatSpineNode:doTouchdAnime()
    local animeName = TOUCH_ANIME_LIST[math.random(#TOUCH_ANIME_LIST)]
    if self.spineNode_ then
        self.spineNode_:setAnimation(0, animeName, false)
        self.spineNode_:addAnimation(0, self.idleName_, true)
    end
end


-------------------------------------------------
-- private

function CatSpineNode:checkCatModelValue_()
    -- update age
    self:setCatAge(self.catModel_:getAge())

    -- update genes
    if self.catModel_:isDisableFacade() then
        self:setCatGenes(nil)
    else
        self:setCatGenes(table.keys(self.catModel_:getGeneMap()))
    end
end


function CatSpineNode:checkCatModelAlive_()
    local isAlive = not self:isCatDie()
    if self.catModel_ then
        isAlive = self.catModel_:isAlive()
    end
    self:getViewData().catLayer:setVisible(isAlive)
    self:getViewData().dieLayer:setVisible(not isAlive)
end


function CatSpineNode:checkCatIdleState_()
    if self.isFreeMode_ then return end
    local oldIdleName = self.idleName_
    local newIdleName = ANIME_NAME_DEFINE.IDLE

    if self.catModel_ then
        -- check sleep
        if self.catModel_:getSleepTimestamp() > 0 then
            newIdleName = ANIME_NAME_DEFINE.SLEEP

        -- check toilet
        elseif self.catModel_:getToiletTimestamp() > 0 then
            newIdleName = ANIME_NAME_DEFINE.TOILET

        else
            -- check status
            local animeNamMap = {}
            local spineSpData = self.spineNode_ and self.spineNode_:getSpData() or {}
            for _, animeName in ipairs(spineSpData.animations or {}) do
                animeNamMap[tostring(animeName)] = true
            end
            for stateId, _ in pairs(self.catModel_:getPhysicalStatusMap() or {}) do
                local stateConf  = CONF.CAT_HOUSE.CAT_STATUS:GetValue(stateId)
                local actionName = checkstr(stateConf.effectAction)
                if string.len(actionName) > 0 and animeNamMap[actionName] then
                    newIdleName = actionName
                    break
                end
            end
        end
    end

    if oldIdleName ~= newIdleName then
        self.idleName_ = newIdleName
        if self:isIdlingAnime() then
            self:doIdleAnime()
        end
    end
end


function CatSpineNode:markRefreshSpine_()
    if not self:getActionByTag(ACTION_ENUM.SPINE_REFRESH) then
        self:runAction(cc.CallFunc:create(function()
            self:upateCatSpine_()
            self:checkCatIdleState_()
        end)):setTag(ACTION_ENUM.SPINE_REFRESH)
    end
end


function CatSpineNode:upateCatSpine_()
    local isBabyCat = self:getCatAge() == CatHouseUtils.CAT_YOUTH_AGE_NUM
    local raceConf  = CONF.CAT_HOUSE.CAT_RACE:GetValue(self:getCatRace())
    local spineName = tostring(raceConf.spineId) .. (isBabyCat and '_1' or '')
    local spinePath = 'arts/catHouse/catSpine/' .. spineName
    local geneIdMap = {}
    for _, geneId in ipairs(self:getCatGenes()) do
        geneIdMap[tostring(geneId)] = true
    end
    
    -------------------------------------------------
    -- check update spine
    if self.spineName_ ~= spineName then
        self.geneIdMap_ = nil
        self.spineName_ = spineName
        self:getViewData().testLabel:setString('')

        if self.spineNode_ then
            self.spineNode_:removeFromParent()
            self.spineNode_ = nil
        end
    
        if app.gameResMgr:verifySpine(spinePath) then
            self.spineNode_ = ui.spine({cache = SpineCacheName.CAT_HOUSE, path = spinePath, init = self:getInitAnim() or self.idleName_})
            self:setInitAnim()
            self.spineNode_:setEnableSpineEvents(true)
            self.spineNode_:setCompleteCB(handler(self, self.onSpineAnimeCompleteHandler_))
            self:getViewData().catLayer:add(self.spineNode_)
    
            if isBabyCat then
                self.spineNode_:setPositionX(self:getContentSize().width/2)
            else
                self.spineNode_:setPositionX(self:getContentSize().width/2 + 10)
            end
        else
            self:getViewData().testLabel:setString(string.fmt('ERROR\nid=%1\nsp=%2', self:getCatRace(), spineName))
        end
    end

    -------------------------------------------------
    -- check update gene
    if self.spineNode_ and not isBabyCat then
        local isChanged = false
        if self.geneIdMap_ and table.nums(self.geneIdMap_) == table.nums(geneIdMap) then
            for geneId, _ in pairs(self.geneIdMap_) do
                if not geneIdMap[geneId] then
                    isChanged = true
                    break
                end
            end
        else
            isChanged = true
        end

        if isChanged then
            local skinList = {}
            local skinsMap = clone(DEFAULT_SKINS)
            for geneId, _ in pairs(geneIdMap) do
                local geneConf = CONF.CAT_HOUSE.CAT_GENE:GetValue(geneId)
                local geneType = CatHouseUtils.GetCatGeneTypeByGeneId(geneId)
                if geneType ~= CatHouseUtils.CAT_GENE_TYPE.SUIT then
                    skinsMap[checkint(geneConf.part)] = geneConf.appearanceId
                else
                    skinList = geneConf.appearanceId
                    break
                end
            end
            if #skinList == 0 then
                for _, skins in pairs(skinsMap) do
                    table.insertto(skinList, skins)
                end
            end
            self.spineNode_:setSpMixedSkins(tostring(ID(self)), skinList)
            self.spineNode_:setToSetupPose()
        end

        self.geneIdMap_ = geneIdMap
    end
end


-------------------------------------------------
-- handler

function CatSpineNode:onEnter()
    if self.catModel_ then
        app:RegistObserver(SGL.CAT_MODEL_UPDATE_AGE, mvc.Observer.new(self.onCatModelValueUpdate_, self))
        app:RegistObserver(SGL.CAT_MODEL_UPDATE_GENE, mvc.Observer.new(self.onCatModelValueUpdate_, self))
        app:RegistObserver(SGL.CAT_MODEL_UPDATE_ALIVE, mvc.Observer.new(self.onCatModelAliveUpdate_, self))
        app:RegistObserver(SGL.CAT_MODEL_SWITCH_FACADE, mvc.Observer.new(self.onCatModelValueUpdate_, self))
        app:RegistObserver(SGL.CAT_MODEL_CLEAN_STATE, mvc.Observer.new(self.onCatIdleStateUpdate_, self))
        app:RegistObserver(SGL.CAT_MODEL_APPEND_STATE, mvc.Observer.new(self.onCatIdleStateUpdate_, self))
        app:RegistObserver(SGL.CAT_MODEL_REMOVE_STATE, mvc.Observer.new(self.onCatIdleStateUpdate_, self))
        app:RegistObserver(SGL.CAT_MODEL_UPDATE_SLEEP_ID, mvc.Observer.new(self.onCatIdleStateUpdate_, self))
        app:RegistObserver(SGL.CAT_MODEL_UPDATE_TOILET_ID, mvc.Observer.new(self.onCatIdleStateUpdate_, self))
    end
end


function CatSpineNode:onExit()
    if self.catModel_ then
        app:UnRegistObserver(SGL.CAT_MODEL_UPDATE_AGE, self)
        app:UnRegistObserver(SGL.CAT_MODEL_UPDATE_GENE, self)
        app:UnRegistObserver(SGL.CAT_MODEL_UPDATE_ALIVE, self)
        app:UnRegistObserver(SGL.CAT_MODEL_SWITCH_FACADE, self)
        app:UnRegistObserver(SGL.CAT_MODEL_CLEAN_STATE, self)
        app:UnRegistObserver(SGL.CAT_MODEL_APPEND_STATE, self)
        app:UnRegistObserver(SGL.CAT_MODEL_REMOVE_STATE, self)
        app:UnRegistObserver(SGL.CAT_MODEL_UPDATE_SLEEP_ID, self)
        app:UnRegistObserver(SGL.CAT_MODEL_UPDATE_TOILET_ID, self)
    end
end


function CatSpineNode:onCatModelValueUpdate_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if self.catModel_ and self.catModel_:getUuid() == data.catUuid then
        self:checkCatModelValue_()
    end
end


function CatSpineNode:onCatModelAliveUpdate_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if self.catModel_ and self.catModel_:getUuid() == data.catUuid then
        self:checkCatModelAlive_()
    end
end


function CatSpineNode:onCatIdleStateUpdate_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if self.catModel_ and self.catModel_:getUuid() == data.catUuid then
        self:checkCatIdleState_()
    end
end


function CatSpineNode:onSpineAnimeCompleteHandler_(event)
    local animeName = checkstr(event.animation)
    local animeLoop = checkint(event.loopCount)
    
    if animeName == ANIME_NAME_DEFINE.FEFUSE then
        self:doIdleAnime()

    elseif animeName == ANIME_NAME_DEFINE.SHOWER then
        if self.animeFinishByShowerCB_ then self.animeFinishByShowerCB_() end
        self:doIdleAnime()
        
    elseif animeName == ANIME_NAME_DEFINE.FEED then
        if self.animeFinishByFeedCB_ then self.animeFinishByFeedCB_() end
        self:doIdleAnime()
        
    elseif animeName == ANIME_NAME_DEFINE.PLAY then
        if self.animeFinishByPlayCB_ then self.animeFinishByPlayCB_() end
        self:doIdleAnime()
    end

    -- check trick animation
    if self.isFreeMode_ then
        if animeName == self.idleName_ and self.idleLoopNum_ > 0 then
            self.idleLoopNum_ = self.idleLoopNum_ - 1
            if self.idleLoopNum_ <= 0 then
                local trickIndex  = math.random(#TRICK_ANIME_DEFINE)
                for _, trickDefine in ipairs(TRICK_ANIME_DEFINE[trickIndex]) do
                    for loopCount = 1, math.random(trickDefine.min, trickDefine.max) do
                        self.spineNode_:addAnimation(0, trickDefine.name, false)
                    end
                end
                self.spineNode_:addAnimation(0, self.idleName_, true)
            end
        else
            self.idleLoopNum_ = math.random(TRICK_ANIME_RANGE.MIN, TRICK_ANIME_RANGE.MAX)
        end
    end
end


-------------------------------------------------------------------------------
-- view struct
-------------------------------------------------------------------------------

function CatSpineNode.CreateView(size)
    local view = ui.layer({size = size})

    local catLayer = ui.layer()
    view:add(catLayer)
    
    local dieLayer = ui.layer()
    view:add(dieLayer)

    local dieGroup = dieLayer:addList({
        ui.image({img = RES_DICT.DIE_IMAGE, scale = 0.85, ml = 90, mb = 135}),
        ui.spine({path = RES_DICT.DIE_SPINE, cache = SpineCacheName.CAT_HOUSE, init = ANIME_NAME_DEFINE.IDLE, scale = 0.85, ml = 70, mb = 70})
    })
    ui.flowLayout(cc.p(0,0), dieGroup, {type = ui.flowC, ap = ui.cc})

    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:add(clickArea)
    
    local testLabel = ui.label({fnt = FONT.D20})
    view:addList(testLabel):alignTo(nil, ui.cc, {offsetY = 35})

    return {
        view      = view,
        catLayer  = catLayer,
        dieLayer  = dieLayer,
        clickArea = clickArea,
        testLabel = testLabel,
    }
end


return CatSpineNode
