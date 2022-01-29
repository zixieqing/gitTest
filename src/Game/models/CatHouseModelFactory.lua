--[[
 * author : kaishiqi
 * descpt : 猫屋 数据模型工厂
]]
local BaseModel = require('Game.models.BaseModel')


-------------------------------------------------
-- HouseCatEffectModel

---@class HouseCatEffectModel
local HouseCatEffectModel = class('HouseCatEffectModel', BaseModel)


function HouseCatEffectModel:ctor(sourceType, sourceRefId, effectId)
    self.super.ctor(self, 'HouseCatEffectModel')

    -- init data
    self.sourceType_      = checkint(sourceType)
    self.sourceRefId_     = checkint(sourceRefId)
    self.effectId_        = checkint(effectId)
    self.effectConf_      = CONF.CAT_HOUSE.CAT_EFFECT:GetValue(self.effectId_)
    self.isOverlay_       = checkint(self.effectConf_.overlay) == 1
    self.targetId_        = checkint(self.effectConf_.targetId)
    self.targetNum_       = checknumber(self.effectConf_.targetNum)
    self.effectTypeMap_   = {}

    local effectTypeList  = string.split(tostring(self.effectConf_.type), ";")
    for _, effectType in ipairs(effectTypeList) do
        self.effectTypeMap_[checkint(effectType)] = true
    end
end


function HouseCatEffectModel:getSourceType()
    return self.sourceType_
end


function HouseCatEffectModel:getSourceRefId()
    return self.sourceRefId_
end


function HouseCatEffectModel:getEffectId()
    return self.effectId_
end


function HouseCatEffectModel:getEffectTypeMap()
    return self.effectTypeMap_
end


function HouseCatEffectModel:isOverlay()
    return self.isOverlay_
end


function HouseCatEffectModel:getTargetId()
    return self.targetId_
end


function HouseCatEffectModel:getTargetNum()
    return self.targetNum_
end


-------------------------------------------------
-- HouseCatAttrModel

---@class HouseCatAttrModel
local HouseCatAttrModel = class('HouseCatAttrModel', BaseModel)


function HouseCatAttrModel:ctor(attrId)
    self.super.ctor(self, 'HouseCatAttrModel')

    -- init data
    self.attrId_   = checkint(attrId)
    local attrConf = CONF.CAT_HOUSE.CAT_ATTR:GetValue(self:getAttrId())
    self:setReduceBase(checkint(attrConf.reduceSeconds))
end


function HouseCatAttrModel:getAttrId()
    return self.attrId_
end


function HouseCatAttrModel:getReduceBase()
    return self.reduceBase_
end
function HouseCatAttrModel:setReduceBase(time)
    self.reduceBase_ = checkint(time)
    self:updateReduceTime()
end


-- 衰减速度变化率（-100 - 100）
function HouseCatAttrModel:getReduceRate()
    return checkint(self.reduceRate_)
end
function HouseCatAttrModel:setReduceRate(rate)
    self.reduceRate_ = checkint(rate)
    self:updateReduceTime()
end


function HouseCatAttrModel:getReduceTime()
    return self.reduceTime_
end
function HouseCatAttrModel:updateReduceTime()
    self.reduceTime_ = math.ceil(self:getReduceBase() * (1 + self:getReduceRate() / 100))
end


function HouseCatAttrModel:getAttrNum()
    return checkint(self.attrNum_)
end
function HouseCatAttrModel:setAttrNum(num)
    self.attrNum_ = math.max(0, checkint(num))
end


function HouseCatAttrModel:getAttrMax()
    return checkint(self.attrMax_) + self:getAttrMaxEx()
end
function HouseCatAttrModel:setAttrBaseMax(max)
    self.attrMax_ = checkint(max)
end
function HouseCatAttrModel:getAttrBaseMax()
    return checkint(self.attrMax_)
end


function HouseCatAttrModel:getAttrMaxEx()
    return checkint(self.attrMaxEx_)
end
function HouseCatAttrModel:setAttrMaxEx(max)
    self.attrMaxEx_ = checkint(max)
end


function HouseCatAttrModel:getUpdateTimestamp()
    return checkint(self.updateTimestamp_)
end
function HouseCatAttrModel:setUpdateTimestamp(timestamp)
    self.updateTimestamp_ = checkint(timestamp)
end


function HouseCatAttrModel:isDisableReduce()
    return checkbool(self.isDisableReduce_)
end
function HouseCatAttrModel:setDisableReduce(isDisable)
    self.isDisableReduce_ = isDisable == true
end


-------------------------------------------------
-- HouseCatModel

---@class HouseCatModel
local HouseCatModel = class('HouseCatModel', BaseModel)


function HouseCatModel:ctor(playerCatId, catData)
    self.super.ctor(self, 'HouseCatModel')

    -- init data
    local playerId    = app.gameMgr:GetPlayerId()
    self.playerCatId_ = checkint(playerCatId)
    self.catUuid_     = CatHouseUtils.BuildCatUuid(playerId, self:getPlayerCatId())
    ---@type table<number, boolean>                @基因map [ geneId : isHave ]
    self.geneMap_    = {}
    ---@type table<number, HouseCatAttrModel>      @属性map [ attrId : attrModel ]
    self.attrMap_    = {}
    ---@type table<number, number>                 @能力map [ abilityId : abilityValue ]
    self.abilityMap_ = {}
    ---@type table<number, table>                  @职业map [ careerId : CareerData ]
    self.careerMap_  = {}
    ---@type table<number, table>                  @状态map [ stateId : StateData ]
    self.statusMap_  = {}
    ---@type table<number, boolean>                @生病map [ stateId : isSicked ]
    self.sickIdMap_  = {}
    ---@type table[]                               @日记list [ JournalData, ... ]
    self.journals_   = {}
    ---@type table<number, boolean>                @邀请map [ friendId : isInvited ]
    self.inviteMap_  = {}
    ---@type table<number, table>                  @好感猫咪map [ friendCatUuid : friendCatData ]
    self.likeCatMap_ = {}
    ---@type table<number, table>                  @好友猫咪map [ friendId : friendCatUuidList ]
    self.friendsMap_ = {}
    ---@type table<number, HouseCatEffectModel[]>  @效果列表map [ effectId : [ HouseCatEffectModel, ... ] ]
    self.effectsMap_ = {}
    ---@type table<string, number>                 @效果数据map [ valueKey : evalueNum ]
    self.effectDict_ = {}

    -- update data
    self:checkAttrsMax()
    self:setOutCountMax(CatHouseUtils.CAT_PARAM_FUNCS.OUT_MAX())
    self:setLikeExpAdd(CatHouseUtils.CAT_PARAM_FUNCS.LIKE_ADD_EXP())
    self:updateCatData(catData)
end


function HouseCatModel:updateCatData(catData)
    local newCatData = catData or {}
    if newCatData.catId              then self:setRace(newCatData.catId) end
    if newCatData.age                then self:setAge(newCatData.age) end
    if newCatData.sex                then self:setSex(newCatData.sex) end
    if newCatData.generation         then self:setGeneration(newCatData.generation) end
    if newCatData.name               then self:setName(newCatData.name) end
    if newCatData.renamed            then self:setRenamed(checkint(newCatData.renamed) == 1) end
    if newCatData.rebirth            then self:setRebirth(checkint(newCatData.rebirth) == 1) end
    if newCatData.createTime         then self:setCreateTime(newCatData.createTime) end
    if newCatData.gene               then self:addGeneList(newCatData.gene) end
    if newCatData.attr               then self:syncAllAttrs(newCatData.attr) end
    if newCatData.ability            then self:resetAbilities(newCatData.ability) end
    if newCatData.career             then self:updateCareers(newCatData.career) end
    if newCatData.status or newCatData.death then self:resetPhysicalStatus(newCatData.status, newCatData.death) end
    if newCatData.nextAgeLeftSeconds then self:setNextAgeLeftSeconds(newCatData.nextAgeLeftSeconds) end
    if newCatData.outLeftTimes       then self:setOutCountLeft(newCatData.outLeftTimes) end
    if newCatData.outFriendId        then self:setOutFriendId(newCatData.outFriendId) end
    if newCatData.outLeftSeconds     then self:setOutLeftSeconds(newCatData.outLeftSeconds) end
    if newCatData.achievementId      then self:setAchievementId(newCatData.achievementId) end
    if newCatData.achievementDrawn   then self:setAchievementDrawn(checkint(newCatData.achievementDrawn) == 1) end
    if newCatData.journal            then self:addJournalList(newCatData.journal) end
    if newCatData.studyId            then self:setStudyingId(newCatData.studyId) end
    if newCatData.studyLeftSeconds   then self:setStudyLeftSeconds(newCatData.studyLeftSeconds) end
    if newCatData.workId             then self:setWorkingId(newCatData.workId) end
    if newCatData.workLeftSeconds    then self:setWorkLeftSeconds(newCatData.workLeftSeconds) end
    if newCatData.leftActionTimes    then self:setLeftActionTimes(newCatData.leftActionTimes) end
    if newCatData.sleepLeftSeconds   then self:setSleepLeftSeconds(newCatData.sleepLeftSeconds) end
    if newCatData.toiletLeftSeconds  then self:setToiletLeftSeconds(newCatData.toiletLeftSeconds) end
    if newCatData.matingHouseLeftSeconds   then self:setHouseLeftSeconds(newCatData.matingHouseLeftSeconds) end
    if newCatData.matingLeftSeconds  then self:setMatingCDLeftSeconds(newCatData.matingLeftSeconds) end
    if newCatData.mating             then self:setMatingData(newCatData.mating) end
    if newCatData.invite             then self:addMatingInviteList(newCatData.invite) end
    if newCatData.favorabilityList   then self:addLikeRelationList(newCatData.favorabilityList) end
    if newCatData.geneOriginal       then self:setGeneOriginal(newCatData.geneOriginal) end
end


--[[
    猫咪 唯一id
]]
function HouseCatModel:getUuid()
    return self.catUuid_
end


--[[
    猫咪 玩家拥有的自增id
]]
function HouseCatModel:getPlayerCatId()
    return checkint(self.playerCatId_)
end


--[[
    猫咪 种族
    @see CONF.CAT_HOUSE.CAT_RACE
]]
function HouseCatModel:getRace()
    return checkint(self.race_)
end
function HouseCatModel:setRace(race)
    self.race_ = checkint(race)
end


--[[
    猫咪 代数
]]
function HouseCatModel:getGeneration()
    return checkint(self.generation_)
end
function HouseCatModel:setGeneration(generation)
    self.generation_ = checkint(generation)
end


--[[
    猫咪 年龄
    @see CONF.CAT_HOUSE.CAT_AGE
]]
function HouseCatModel:getAge()
    return checkint(self.age_)
end
function HouseCatModel:setAge(age)
    self.age_ = checkint(age)
    self:toEvent_(SGL.CAT_MODEL_UPDATE_AGE)
end


--[[
    猫咪 成长到下一年龄剩余秒数
]]
function HouseCatModel:getNextAgeTimestamp()
    return checkint(self.nextAgeTimestamp_)
end
function HouseCatModel:getNextAgeLeftSeconds()
    return self:getNextAgeTimestamp() - os.time()
end
function HouseCatModel:setNextAgeLeftSeconds(leftSeconds)
    self.nextAgeLeftSeconds_ = checkint(leftSeconds)
    self.nextAgeTimestamp_   = os.time() + self.nextAgeLeftSeconds_
    self:toEvent_(SGL.CAT_MODEL_UPDATE_AGE)
end


--[[
    猫咪 性别
    @see CatHouseUtils.CAT_SEX_ENUM
]]
function HouseCatModel:getSex()
    return checkint(self.sex_)
end
function HouseCatModel:setSex(sex)
    self.sex_ = checkint(sex)
end


--[[
    猫咪 名字
]]
function HouseCatModel:getName()
    return tostring(self.name_)
end
function HouseCatModel:setName(name)
    self.name_ = tostring(name)
end


--[[
    猫咪 是否改过名
]]
function HouseCatModel:isRenamed()
    return checkbool(self.isRenamed_)
end
function HouseCatModel:setRenamed(isRenamed)
    self.isRenamed_ = checkbool(isRenamed)
end


--[[
    猫咪 是否回归
]]
function HouseCatModel:isRebirth()
    return checkbool(self.isRebirth_)
end
function HouseCatModel:setRebirth(isRebirth)
    self.isRebirth_ = checkbool(isRebirth)
    self:checkAttrsMax()
end


--[[
    猫咪 创建时间
]]
function HouseCatModel:getCreateTime()
    return checkint(self.createTime_)
end
function HouseCatModel:setCreateTime(createTime)
    self.createTime_ = checkint(createTime) - getServerTimezone() + getClientTimezone()
end


-------------------------------------------------------------------------------
-- 外出
-------------------------------------------------------------------------------

--[[
    猫咪 最大外出次数
]]
function HouseCatModel:getOutCountMax()
    return checkint(self.outCountMax_)
end
function HouseCatModel:setOutCountMax(count)
    self.outCountMax_ = checkint(count)
end


--[[
    猫咪 剩余外出次数
]]
function HouseCatModel:getOutCountLeft()
    return checkint(self.outCountLeft_)
end
function HouseCatModel:setOutCountLeft(count)
    self.outCountLeft_ = checkint(count)
    self:toEvent_(SGL.CAT_MODEL_UPDATE_OUT_COUNT_NUM)
end


--[[
    猫咪 外出的好友id
]]
function HouseCatModel:getOutFriendId()
    return checkint(self.outFriendId_)
end
function HouseCatModel:setOutFriendId(friendId)
    self.outFriendId_ = checkint(friendId)
end


--[[
    猫咪 外出的剩余秒数
]]
function HouseCatModel:getOutTimestamp()
    return checkint(self.outTimestamp_)
end
function HouseCatModel:getOutLeftSeconds()
    return self:getOutTimestamp() - os.time()
end
function HouseCatModel:setOutLeftSeconds(leftSeconds)
    self.outLeftSeconds_ = checkint(leftSeconds)
    self.outTimestamp_   = os.time() + self.outLeftSeconds_
    self:toEvent_(SGL.CAT_MODEL_UPDATE_OUT_TIMESTAMP, {outFriendId = self:getOutFriendId()})
end
function HouseCatModel:isOutGoing()
    return self:getOutLeftSeconds() > 0
end


--[[
    猫咪 能否外出
]]
function HouseCatModel:isOutEnable()
    return self:checkOutEnable()
end


--[[
    猫咪 检测能否外出
]]
function HouseCatModel:checkOutEnable(isShowTips)
    -- 有外出次数 && 活着 && 空闲中 && 外出属性要求
    local becauseDescr = ''
    local isOutEnable  = true
    if not self:isAlive() then
        becauseDescr = __('猫咪已经死亡')
        isOutEnable  = false
    elseif self:isSicked() then
        becauseDescr = __('您的猫病了,无法完成您的要求')
        isOutEnable  = false
    elseif not self:isDoNothing() then
        becauseDescr = __('猫咪正在忙碌中')
        isOutEnable  = false
    elseif self:getOutCountLeft() <= 0 then
        becauseDescr = __('猫咪外出次数用完')
        isOutEnable  = false
    else
        local attrDescrList = {}
        for attrId, attrValue in pairs (CatHouseUtils.CAT_PARAM_FUNCS.OUT_NEED_ATTR()) do
            local attrConf  = CONF.CAT_HOUSE.CAT_ATTR:GetValue(attrId)
            local currValue = self:getAttrNum(attrId)
            local needValue = checkint(attrValue)
            if currValue < needValue then
                table.insert(attrDescrList, string.fmt(__('_name_不足_num_'), {_name_ = tostring(attrConf.name), _num_ = needValue}))
            end
        end
        if #attrDescrList > 0 then
            becauseDescr = table.concat(attrDescrList, '，')
            isOutEnable  = false
        end
    end
    if isShowTips and not isOutEnable then
        app.uiMgr:ShowInformationTips(string.fmt(__('_because_，不能外出'), {_because_ = becauseDescr}))
    end
    return isOutEnable
end


-------------------------------------------------------------------------------
-- 基因
-------------------------------------------------------------------------------

--[[
    猫咪 基因
    @see CONF.CAT_HOUSE.CAT_GENE
]]
function HouseCatModel:getGeneMap()
    return self.geneMap_
end
function HouseCatModel:addGeneId(geneId)
    local isGeneAlreadyEffect = checkbool(self.geneMap_[checkint(geneId)])
    self.geneMap_[checkint(geneId)] = CatHouseUtils.IsGeneEffect(self:getAge())
    if not isGeneAlreadyEffect and self.geneMap_[checkint(geneId)] == true then
        self:toEvent_(SGL.CAT_MODEL_UPDATE_GENE)
        self:appendEffectModel_(CatHouseUtils.CAT_EFFECT_SOURCE_ENUM.GENE, geneId)
    end
end
function HouseCatModel:hasGeneId(geneId)
    return self.geneMap_[checkint(geneId)] ~= nil
end
function HouseCatModel:addGeneList(geneList)
    for _, geneId in pairs(geneList or {}) do
        self:addGeneId(geneId)
    end
end

function HouseCatModel:setGeneOriginal(geneOriginal)
    self.geneOriginal_ = geneOriginal
end

function HouseCatModel:getGeneOriginal()
    return self.geneOriginal_
end

-------------------------------------------------------------------------------
-- 能力
-------------------------------------------------------------------------------

--[[
    猫咪 能力
    @see CONF.CAT_HOUSE.CAT_ABILITY
]]
function HouseCatModel:getAbility(abilityId)
    return checkint(self.abilityMap_[checkint(abilityId)])
end
function HouseCatModel:setAbility(abilityId, abilityValue)
    self.abilityMap_[checkint(abilityId)] = checkint(abilityValue)
    -- update attrModel ReduceTime
    local abilityConf  = CONF.CAT_HOUSE.CAT_ABILITY:GetValue(abilityId)
    local effectAttrId = checkint(abilityConf.effectAttr)
    if effectAttrId > 0 then
        local attrModel  = self:checkAttrModel(effectAttrId)
        local reduceTime = CatHouseUtils.GetCatAbilityToAttrReduceTime(abilityId, abilityValue)
        attrModel:setReduceBase(reduceTime)
    end
    self:toEvent_(SGL.CAT_MODEL_UPDATE_ABILITY_NUM, {abilityId = abilityId})
end
function HouseCatModel:addAbility(abilityId, changeValue)
    self:setAbility(abilityId, self:getAbility(abilityId) + checkint(changeValue))
end
function HouseCatModel:updateAbilities(abilityMap)
    for abilityId, abilityValue in pairs(abilityMap or {}) do
        self:setAbility(abilityId, abilityValue)
    end
end
function HouseCatModel:resetAbilities(abilityMap)
    self.abilityMap_ = {}
    self:updateAbilities(abilityMap)
end


-------------------------------------------------------------------------------
-- 属性
-------------------------------------------------------------------------------

--[[
    猫咪 属性
    @see CONF.CAT_HOUSE.CAT_ATTR
]]

---@return table<number, HouseCatAttrModel>
function HouseCatModel:getAllAttrModel()
    return self.attrMap_
end


---@return HouseCatAttrModel
function HouseCatModel:checkAttrModel(attrId)
    if not self.attrMap_[checkint(attrId)] then
        self.attrMap_[checkint(attrId)] = HouseCatAttrModel.new(attrId)
    end
    return self.attrMap_[checkint(attrId)]
end


function HouseCatModel:getAttrNum(attrId)
    local attrModel = self:checkAttrModel(attrId)
    return attrModel:getAttrNum()
end
function HouseCatModel:setAttrNum(attrId, attrValue)
    local attrModel = self:checkAttrModel(attrId)
    attrModel:setAttrNum(attrValue)
    self:toEvent_(SGL.CAT_MODEL_UPDATE_ATTR_NUM, {attrId = attrId})
end
function HouseCatModel:addAttrNum(attrId, changeValue)
    self:setAttrNum(attrId, self:getAttrNum(attrId) + checkint(changeValue))
end
function HouseCatModel:updateAttrs(attrMap)
    for attrId, attrValue in pairs(attrMap or {}) do
        self:setAttrNum(attrId, attrValue)
    end
end


function HouseCatModel:getSnycAttrsTimestamp()
    return checkint(self.snycAttrsTimestamp_)
end
function HouseCatModel:syncAllAttrs(attrMap)
    self:updateAttrs(attrMap)
    -- update snyc timestamp
    local currentTimestamp = os.time()
    for _, attrModel in pairs(self.attrMap_) do
        attrModel:setUpdateTimestamp(currentTimestamp)
    end
    self.snycAttrsTimestamp_ = currentTimestamp
end


function HouseCatModel:getAttrMaxEx(attrId)
    local attrModel = self:checkAttrModel(attrId)
    return attrModel:getAttrMaxEx()
end
function HouseCatModel:setAttrMaxEx(attrId, attrValue)
    local attrModel = self:checkAttrModel(attrId)
    attrModel:setAttrMaxEx(attrValue)
    self:toEvent_(SGL.CAT_MODEL_UPDATE_ATTR_NUM, {attrId = attrId})
end


function HouseCatModel:getAttrMax(attrId)
    local attrModel = self:checkAttrModel(attrId)
    return attrModel:getAttrMax()
end
function HouseCatModel:setAttrBaseMax(attrId, attrValue)
    local attrModel = self:checkAttrModel(attrId)
    attrModel:setAttrBaseMax(attrValue)
    self:toEvent_(SGL.CAT_MODEL_UPDATE_ATTR_NUM, {attrId = attrId})
end
function HouseCatModel:getAttrBaseMax(attrId)
    local attrModel = self:checkAttrModel(attrId)
    return attrModel:getAttrBaseMax(attrId)
end
function HouseCatModel:checkAttrsMax()
    for attrId, attrConf in pairs(CONF.CAT_HOUSE.CAT_ATTR:GetAll()) do
        local maxValue  = self:isRebirth() and checkint(attrConf.rebirthMax) or checkint(attrConf.max)
        local attrModel = self:checkAttrModel(attrId)
        if attrModel:getAttrBaseMax(attrId) ~= maxValue then
            attrModel:setAttrBaseMax(maxValue)
        end
    end
end


-------------------------------------------------------------------------------
-- 职业
-------------------------------------------------------------------------------

--[[
    猫咪 职业
    @see CONF.CAT_HOUSE.CAT_CAREER_INFO
    @see CONF.CAT_HOUSE.CAT_CAREER_LEVEL
]]
function HouseCatModel:getCareerExp(careerId)
    return checkint(checktable(self.careerMap_[checkint(careerId)]).exp)
end
function HouseCatModel:getCareerLevel(careerId)
    return math.max(checkint(checktable(self.careerMap_[checkint(careerId)]).level), 1)
end
function HouseCatModel:setCareerExp(careerId, careerExp)
    self.careerMap_[checkint(careerId)]     = self.careerMap_[checkint(careerId)] or {}
    self.careerMap_[checkint(careerId)].exp = checkint(careerExp)
end
function HouseCatModel:setCareerLevel(careerId, careerLevel)
    self.careerMap_[checkint(careerId)]       = self.careerMap_[checkint(careerId)] or {}
    self.careerMap_[checkint(careerId)].level = checkint(careerLevel)
end
function HouseCatModel:addCareerExp(careerId, changeExp)
    self:setCareerExp(careerId, self:getCareerExp(careerId) + checkint(changeExp))
end
function HouseCatModel:addCareerLevel(careerId, changeLevel)
    self:setCareerLevel(careerId, self:getCareerLevel(careerId) + checkint(changeLevel))
end
function HouseCatModel:updateCareers(careerMap)
    for careerId, careerData in pairs(careerMap or {}) do
        self:setCareerExp(careerId, careerData.exp)
        self:setCareerLevel(careerId, careerData.level)
    end
end


-------------------------------------------------------------------------------
-- 状态
-------------------------------------------------------------------------------

--[[
    猫咪 身体状态
    @see CONF.CAT_HOUSE.CAT_STATUS
]]
function HouseCatModel:getPhysicalStatusMap()
    return self.statusMap_
end


function HouseCatModel:addPhysicalState(stateId, leftSeconds, deathTimestamp)
    if checkint(deathTimestamp) > 0 and not self:checkStateIsUsefulByDeathTimeStamp(deathTimestamp) then
        return
    end
    local isAppendEffect = self.statusMap_[checkint(stateId)] == nil
    self.statusMap_[checkint(stateId)] = self.statusMap_[checkint(stateId)] or {}
    self.statusMap_[checkint(stateId)].leftSeconds    = checkint(leftSeconds)
    self.statusMap_[checkint(stateId)].deathTimestamp = checkint(deathTimestamp)
    self.statusMap_[checkint(stateId)].timestamp      = math.max(os.time() + checkint(leftSeconds), checkint(deathTimestamp))  
    if CatHouseUtils.IsCatStateCanDoSick(stateId) then
        self.sickIdMap_[checkint(stateId)] = true
    end
    self:checkSicked_()
    if isAppendEffect then
        self:appendEffectModel_(CatHouseUtils.CAT_EFFECT_SOURCE_ENUM.STATE, stateId)
        self:toEvent_(SGL.CAT_MODEL_APPEND_STATE, {stateId = stateId})
    end
end
function HouseCatModel:delPhysicalState(stateId)
    local isRemoveEffect = self.statusMap_[checkint(stateId)] ~= nil
    self.statusMap_[checkint(stateId)] = nil
    self.sickIdMap_[checkint(stateId)] = nil
    self:checkSicked_()
    if isRemoveEffect then
        self:removeEffectModel_(CatHouseUtils.CAT_EFFECT_SOURCE_ENUM.STATE, stateId)
        self:toEvent_(SGL.CAT_MODEL_REMOVE_STATE, {stateId = stateId})
    end
end
function HouseCatModel:hasPhysicalState(stateId)
    return self:getStateTimestamp(stateId) > 0
end


function HouseCatModel:getPhysicalStateTimestamp(stateId)
    local stateData = checktable(self.statusMap_[checkint(stateId)])
    return checkint(stateData.timestamp)
end
function HouseCatModel:getPhysicalStateLeftSeconds(stateId)
    return self:getPhysicalStateTimestamp(stateId) - os.time()
end


function HouseCatModel:haPhysicalStateDeathTimestamp(stateId)
    return self:getPhysicalStateDeathTimestamp(stateId) > 0
end
function HouseCatModel:getPhysicalStateDeathTimestamp(stateId)
    local stateData = checktable(self.statusMap_[checkint(stateId)])
    return checkint(stateData.deathTimestamp)
end
function HouseCatModel:getPhysicalStateDeathLeftSeconds(stateId)
    return self:getPhysicalStateDeathTimestamp(stateId) - os.time()
end
function HouseCatModel:isPhysicalStateDeadly(stateId)
    return self:haPhysicalStateDeathTimestamp(stateId) and self:getPhysicalStateDeathLeftSeconds(stateId) < 0
end


function HouseCatModel:resetPhysicalStatus(statusData, deathsData)
    -- reset status
    for statuId, _ in pairs(self:getPhysicalStatusMap()) do
        self:removeEffectModel_(CatHouseUtils.CAT_EFFECT_SOURCE_ENUM.STATE, statuId)
    end
    self.statusMap_ = {}
    self.sickIdMap_ = {}
    self:checkSicked_()
    self:toEvent_(SGL.CAT_MODEL_CLEAN_STATE)

    -- convert to map
    local statusDataMap = {}
    for _, statuData in pairs(statusData or {}) do
        statusDataMap[checkint(statuData.statusId)] = {leftSeconds = statuData.leftSeconds}
    end
    for _, deathData in pairs(deathsData or {}) do
        if statusDataMap[checkint(deathData.statusId)] then
            statusDataMap[checkint(deathData.statusId)].deathTimestamp = deathData.deathTimestamp
        else
            statusDataMap[checkint(deathData.statusId)] = {deathTimestamp = deathData.deathTimestamp}
        end
    end

    -- add new status
    for statuId, stateData in pairs(statusDataMap) do
        self:addPhysicalState(statuId, stateData.leftSeconds, stateData.deathTimestamp)
    end
    self:checkAlive()
end


--[[
    猫咪 是否生病
]]
function HouseCatModel:isSicked()
    return checkbool(self.isSkicked_)
end
function HouseCatModel:checkSicked_()
    self.isSkicked_ = table.nums(self.sickIdMap_) > 0
end
function HouseCatModel:getSickIdMap()
    return checktable(self.sickIdMap_)
end


--[[
    猫咪 是否活着
]]
function HouseCatModel:isAlive()
    -- 默认值是true
    if self.isAlive_ == nil then
        return true
    end
    return checkbool(self.isAlive_)
end
function HouseCatModel:setAlive(isAlive)
    self.isAlive_ = checkbool(isAlive)
    self:toEvent_(SGL.CAT_MODEL_UPDATE_ALIVE)
end
function HouseCatModel:checkAlive()
    local isAlive = true
    for statusId, statusData in pairs(self:getPhysicalStatusMap()) do
        -- state deadly
        if self:isPhysicalStateDeadly(statusId) then
            isAlive = false -- 有一个状态致死了，就没必要更新剩下的状态了
            break
        end
    end
    if self:isAlive() ~= isAlive then
        self:setAlive(isAlive)
    end
end


function HouseCatModel:isDie()
    return not self:isAlive()
end


-------------------------------------------------------------------------------
-- 日记
-------------------------------------------------------------------------------

function HouseCatModel:getJournalList()
    return self.journals_
end
function HouseCatModel:addJournalData(journalData)
    if next(journalData or {}) == nil then return end
    table.insert(self.journals_, {
        journalId = checkint(journalData.journalId),
        timestamp = checkint(journalData.createTime)  - getServerTimezone() + getClientTimezone(),
    })
end
function HouseCatModel:addJournalList(journalList)
    for _, journalData in ipairs(journalList or {}) do
        self:addJournalData(journalData)
    end
end


-------------------------------------------------------------------------------
-- 成就
-------------------------------------------------------------------------------

--[[
    猫咪 成就id
    @see CONF.CAT_HOUSE.CAT_ACHV
]]
function HouseCatModel:getAchievementId()
    return checkint(self.achievementId_)
end
function HouseCatModel:setAchievementId(achievementId)
    self.achievementId_ = checkint(achievementId)
end


--[[
    猫咪 是否领取成就
]]
function HouseCatModel:isAchievementDrawn()
    return checkbool(self.isAchievementDrawn_)
end
function HouseCatModel:setAchievementDrawn(isDrawn)
    self.isAchievementDrawn_ = checkbool(isDrawn)
end


-------------------------------------------------------------------------------
-- 做事
-------------------------------------------------------------------------------

--[[
    猫咪 学习相关
]]
function HouseCatModel:getStudyingId()
    return checkint(self.studyingId_)
end
function HouseCatModel:setStudyingId(studyId)
    self.studyingId_ = checkint(studyId)
    self:toEvent_(SGL.CAT_MODEL_UPDATE_STUDY_ID)
end


function HouseCatModel:getStudyTimestamp()
    return checkint(self.studyTimestamp_)
end
function HouseCatModel:getStudyLeftSeconds()
    return self:getStudyTimestamp() - os.time()
end
function HouseCatModel:setStudyLeftSeconds(leftSeconds)
    self.studyTimestamp_ = os.time() + checkint(leftSeconds)
end
function HouseCatModel:isStudying()
    return self:getStudyLeftSeconds() >= 0 or self:getStudyingId() > 0
end


-- 学习花费变化率（-100 - 100）
function HouseCatModel:getStydyConsumeRate()
    return checkint(self.stydyConsumeRate_)
end
function HouseCatModel:setStydyConsumeRate(count)
    self.stydyConsumeRate_ = checkint(count)
end


-- 工作所得变化率（-100 - 100）
function HouseCatModel:getWorkIncomeRate()
    return checkint(self.workIncomeRate_)
end
function HouseCatModel:setWorkIncomeRate(count)
    self.workIncomeRate_ = checkint(count)
end



--[[
    猫咪 工作相关
]]
function HouseCatModel:getWorkingId()
    return checkint(self.workingId_)
end
function HouseCatModel:setWorkingId(workId)
    self.workingId_ = checkint(workId)
    self:toEvent_(SGL.CAT_MODEL_UPDATE_WORK_ID)
end


function HouseCatModel:getWorkTimestamp()
    return checkint(self.workTimestamp_)
end
function HouseCatModel:getWorkLeftSeconds()
    return self:getWorkTimestamp() - os.time()
end
function HouseCatModel:setWorkLeftSeconds(leftSeconds)
    self.workTimestamp_ = os.time() + checkint(leftSeconds)
end
function HouseCatModel:isWorking()
    return self:getWorkLeftSeconds() >= 0 or self:getWorkingId() > 0
end


--[[
    猫咪 工作/学习剩余次数
]]
function HouseCatModel:setLeftActionTimes(leftActionTimes)
    self.leftActionTimes = checkint(leftActionTimes)
end
function HouseCatModel:getLeftActionTimes()
    return checkint(self.leftActionTimes)
end


--[[
    猫咪 睡觉相关
]]
function HouseCatModel:getSleepTimestamp()
    return checkint(self.sleepTimestamp_)
end
function HouseCatModel:getSleepLeftSeconds()
    return self:getSleepTimestamp() - os.time()
end
function HouseCatModel:setSleepLeftSeconds(leftSeconds)
    local sleepLeftSeconds = checkint(leftSeconds)
    self.sleepTimestamp_   = sleepLeftSeconds > 0 and os.time() + sleepLeftSeconds or sleepLeftSeconds
    self:toEvent_(SGL.CAT_MODEL_UPDATE_SLEEP_ID)
end
function HouseCatModel:isSleeping()
    return self:getSleepTimestamp() > 0
end


--[[
    猫咪 厕所相关
]]
function HouseCatModel:getToiletTimestamp()
    return checkint(self.toiletTimestamp_)
end
function HouseCatModel:getToiletLeftSeconds()
    return self:getToiletTimestamp() - os.time()
end
function HouseCatModel:setToiletLeftSeconds(leftSeconds)
    local toiletLeftSeconds = checkint(leftSeconds)
    self.toiletTimestamp_ = toiletLeftSeconds > 0 and os.time() + toiletLeftSeconds or toiletLeftSeconds
    self:toEvent_(SGL.CAT_MODEL_UPDATE_TOILET_ID)
end
function HouseCatModel:isToileting()
    return self:getToiletTimestamp() > 0
end


-------------------------------------------------------------------------------
-- 交配
-------------------------------------------------------------------------------

--[[
    猫咪 交配屋时间
]]
function HouseCatModel:getHouseTimestamp()
    return checkint(self.houseTimestamp_)
end
function HouseCatModel:getHouseLeftSeconds()
    return self:getHouseTimestamp() - os.time()
end
function HouseCatModel:setHouseLeftSeconds(leftSeconds)
    self.houseTimestamp_ = os.time() + checkint(leftSeconds)
end
function HouseCatModel:isHousing()
    return self:getHouseLeftSeconds() > 0
end


--[[
    猫咪 交配冷却时间
]]
function HouseCatModel:getMatingCDTimestamp()
    return checkint(self.matingCDTimestamp_)
end
function HouseCatModel:getMatingCDLeftSeconds()
    return self:getMatingCDTimestamp() - os.time()
end
function HouseCatModel:setMatingCDLeftSeconds(leftSeconds)
    self.matingCDTimestamp_ = os.time() + checkint(leftSeconds)
end
function HouseCatModel:isMatingCD()
    return self:getMatingCDLeftSeconds() > 0
end


--[[
    猫咪 交配数据
]]
function HouseCatModel:getMatingData()
    return self.matingData_
end
function HouseCatModel:setMatingData(matingData)
    self.matingData_ = (matingData and next(matingData) ~= nil) and matingData or nil
    if self.matingData_ then
        self:setMatingLeftSeconds(self.matingData_.leftSeconds)
    else
        self.matingLeftTimestamp_ = 0
    end
end
function HouseCatModel:cleanMatingData()
    self.matingData_ = nil
end
function HouseCatModel:hasMatingData()
    return self:getMatingData() and next(self:getMatingData()) ~= nil 
end

function HouseCatModel:IsMatingInviter()
    if not self:hasMatingData() then return end
    return checkint(self:getMatingData().isInvite) == 1
end

function HouseCatModel:getMatingTimestamp()
    return checkint(self.matingTimestamp_)
end
function HouseCatModel:getMatingLeftSeconds()
    return self:getMatingTimestamp() - os.time()
end
function HouseCatModel:setMatingLeftSeconds( leftSeconds )
    self.matingLeftTimestamp_ = checkint(leftSeconds)
    self.matingTimestamp_   = os.time() + self.matingLeftTimestamp_
end
function HouseCatModel:isMating()
    return self:getMatingLeftSeconds() > 0 or self:getMatingData() ~= nil
end


--[[
    猫咪 交配邀请
]]
function HouseCatModel:isMatingInviteEmpty()
    return next(self:getMatingInviteMap()) == nil
end
function HouseCatModel:getMatingInviteMap()
    return checktable(self.inviteMap_)
end
function HouseCatModel:hasMatingInvite(friendId)
    return checkbool(self.inviteMap_[tostring(friendId)])
end
function HouseCatModel:addMatingInvite(friendId)
    self.inviteMap_[tostring(friendId)] = true
end
function HouseCatModel:addMatingInviteList(inviteList)
    for _, friendId in ipairs(inviteList or {}) do
        self:addMatingInvite(friendId)
    end
end
function HouseCatModel:cleanMatingInvite()
    self.inviteMap_ = {}
end


--[[
    猫咪 能否接受好友的交配
]]
function HouseCatModel:isMatingToFriend(beInvitedData, isShowTips)
    return self:checkMatingToFriend(beInvitedData, isShowTips)
end


--[[
    猫咪 能否与好友交配
]]
function HouseCatModel:checkMatingToFriend(beInvitedData, isShowTips)
    local becauseDescr   = ''
    local isMatingEnable = true
    if not self:isAlive() then
        becauseDescr   = __('猫咪已经死亡')
        isMatingEnable = false
    elseif self:isMatingCD() then
        becauseDescr   = __('猫咪刚结束交配，正在调养生息中')
        isMatingEnable = false
    elseif not self:isDoNothing() then
        becauseDescr   = __('猫咪正在忙碌中')
        isMatingEnable = false
    elseif self:isSicked() then
        becauseDescr = __('猫咪生病了')
        isMatingEnable = false
    elseif self:isDisableAnything() then
        becauseDescr   = __('猫咪处于异常状态,无法进行生育行为')
        isMatingEnable = false
    elseif not self:isUnlockMaking() then
        becauseDescr   = __('猫咪未解锁生育能力')
        isMatingEnable = false
    elseif beInvitedData then
        local catLikeLevel  = self:getLikeFriendCatLevel(beInvitedData.friendCatUuid)
        local catBirthConf  = CONF.CAT_HOUSE.CAT_BIRTH:GetValue(beInvitedData.generation)
        local needLikeLevel = checkint(catBirthConf.favorabilityLevel)
        if checkint(beInvitedData.sex) == self:getSex() then
            becauseDescr   = __('猫咪性别一样')
            isMatingEnable = false
        elseif needLikeLevel > catLikeLevel then
            becauseDescr   = string.fmt(__('与对方猫咪好感度未达到_num_级'), {_num_ = needLikeLevel})
            isMatingEnable = false
        end
    end
    if isShowTips and not isMatingEnable then
        app.uiMgr:ShowInformationTips(string.fmt(__('_because_，不能交配'), {_because_ = becauseDescr}))
    end
    return isMatingEnable
end


-------------------------------------------------------------------------------
-- 好感
-------------------------------------------------------------------------------

--[[
    猫咪 好感相关
]]
function HouseCatModel:getLikeFriendList()
    return table.keys(self.friendsMap_)
end
function HouseCatModel:getLikeFriendCatsList(friendId)
    return table.keys(self.friendsMap_[checkint(friendId)] or {})
end


function HouseCatModel:hasLikeFriendCatData(friendCatUuid)
    return self:getLikeFriendCatData(friendCatUuid) ~= nil
end
function HouseCatModel:getLikeFriendCatData(friendCatUuid)
    return self.likeCatMap_[friendCatUuid]
end


function HouseCatModel:getLikeFriendCatLevel(friendCatUuid)
    local likeCatData = self:getLikeFriendCatData(friendCatUuid) or {}
    return checkint(likeCatData.favorabilityLevel)
end
function HouseCatModel:getLikeFriendCatExp(friendCatUuid)
    local likeCatData = self:getLikeFriendCatData(friendCatUuid) or {}
    return checkint(likeCatData.favorabilityExp)
end
function HouseCatModel:setLikeFriendCatExp(friendCatUuid, likeExp)
    local likeCatData = self:getLikeFriendCatData(friendCatUuid)
    likeCatData.favorabilityExp   = checkint(likeExp)
    likeCatData.favorabilityLevel = CatHouseUtils.GetCatLikeLevel(likeCatData.favorabilityExp)
end
function HouseCatModel:addLikeFriendCatExp(friendCatUuid, changeExp)
    self:setLikeFriendCatExp(friendCatUuid, self:getLikeFriendCatExp(friendCatUuid) + checkint(changeExp))
end


function HouseCatModel:addLikeRelationData(likeData)
    local friendId = checkint(likeData.friendId)
    local catUuid  = CatHouseUtils.BuildCatUuid(likeData.friendId, likeData.friendCatId)
    likeData.friendCatUuid     = catUuid
    self.likeCatMap_[catUuid]  = checktable(likeData)
    self.friendsMap_[friendId] = self.friendsMap_[friendId] or {}
    self.friendsMap_[friendId][catUuid] = true
    self:setLikeFriendCatExp(catUuid, self:getLikeFriendCatExp(catUuid))
end
function HouseCatModel:addLikeRelationList(likeList)
    for _, likeData in ipairs(likeList) do
        self:addLikeRelationData(likeData)
    end
end


--[[
    猫咪 好感度经验增加量
]]
function HouseCatModel:getLikeExpAdd()
    return checkint(self.LikeExpAdd_)
end
function HouseCatModel:setLikeExpAdd(count)
    self.LikeExpAdd_ = checkint(count)
end


--[[
    猫屋 获取复活时间戳
]]
function HouseCatModel:getRebornTimeStamp()
    return checkint(self.rebornTimeStamp_)
end
function HouseCatModel:initRebornTimeStamp()
    self.rebornTimeStamp_ = os.time()
end


function HouseCatModel:checkStateIsUsefulByDeathTimeStamp(timeStamp)
    return self:getRebornTimeStamp() <= 0 or self:getRebornTimeStamp() - timeStamp < 0
end


-------------------------------------------------------------------------------
-- 通用
-------------------------------------------------------------------------------

--[[
    猫咪 是否无事可做
]]
function HouseCatModel:isDoNothing()
    if self:isStudying() or 
        self:isWorking() or 
        self:isSleeping() or 
        self:isToileting() or 
        self:isHousing() or 
        self:isMating() or 
        self:isOutGoing() then
        return false
    else
        return true
    end
end


--[[
    猫咪 是否解锁 基因功能
]]
function HouseCatModel:isUnlockGene()
    local ageConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(self:getAge())
    return checkint(ageConf.gene) > 0
end


--[[
    猫咪 是否解锁 交配功能
]]
function HouseCatModel:isUnlockMaking()
    local ageConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(self:getAge())
    return checkint(ageConf.birth) > 0
end


--[[
    猫咪 是否解锁 学习功能
]]
function HouseCatModel:isUnlockStudy()
    local ageConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(self:getAge())
    return checkint(ageConf.study) > 0
end


--[[
    猫咪 是否解锁 工作功能
]]
function HouseCatModel:isUnlockWork()
    local ageConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(self:getAge())
    return checkint(ageConf.work) > 0
end


--[[
    猫咪 是否解锁 成就功能
]]
function HouseCatModel:isUnlockAchievement()
    local ageConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(self:getAge())
    return checkint(ageConf.achievement) > 0
end


--[[
    猫咪 能否被放置设置
]]
function HouseCatModel:isPlaceableToSet()
    -- 无条件
    return true
end


--[[
    猫咪 能否被放置显示
]]
function HouseCatModel:isPlaceableToShow()
    -- 非外出中就能显示
    return not self:isOutGoing()
end


--[[
    猫咪 禁用做任何事（包括行为动作有 睡觉、上厕所、喂食、玩耍、洗澡、学习、工作、交配 还有放生、回归）
]]
function HouseCatModel:isDisableAnything()
    return checkbool(self.isDisableAnything_)
end
function HouseCatModel:setDisableAnything(isDisable)
    self.isDisableAnything_ = isDisable == true
end


--[[
    猫咪 禁用上厕所
]]
function HouseCatModel:isDisableToilet()
    return self:isDisableAnything() or checkbool(self.isDisableToilet_)
end
function HouseCatModel:setDisableToilet(isDisable)
    self.isDisableToilet_ = isDisable == true
end


--[[
    猫咪 禁用吃东西
]]
function HouseCatModel:isDisableFeed()
    return self:isDisableAnything() or checkbool(self.isDisableFeed_)
end
function HouseCatModel:setDisableFeed(isDisable)
    self.isDisableFeed_ = isDisable == true
end


--[[
    猫咪 禁用睡觉
]]
function HouseCatModel:isDisableSleep()
    return self:isDisableAnything() or checkbool(self.isDisableSleep_)
end
function HouseCatModel:setDisableSleep(isDisable)
    self.isDisableSleep_ = isDisable == true
end


--[[
    猫咪 禁用外观
]]
function HouseCatModel:isDisableFacade()
    return checkbool(self.isDisableFacade_)
end
function HouseCatModel:setDisableFacade(isDisable)
    self.isDisableFacade_ = isDisable == true
    self:toEvent_(SGL.CAT_MODEL_SWITCH_FACADE)
end


--[[
    猫咪 禁用好感度更新
]]
function HouseCatModel:isDisableLikeUpdate()
    return checkbool(self.isDisableLikeUpdate_)
end
function HouseCatModel:setDisableLikeUpdate(isDisable)
    self.isDisableLikeUpdate_ = isDisable == true
end


--[[
    猫咪 禁用xx属性衰减
]]
function HouseCatModel:isDisableAttrReduceAt(attrId)
    local attrModel = self:getAllAttrModel()[checkint(attrId)]
    if attrModel then
        return attrModel:isDisableReduce()
    end
    return false
end
function HouseCatModel:setDisableAttrReduceAt(attrId, isDisable)
    local attrModel = self:getAllAttrModel()[checkint(attrId)]
    if attrModel then
        attrModel:setDisableReduce(isDisable)
    end
end


--[[
    猫咪 限制食物品质(xx品质及以上，0为不限制)
]]
function HouseCatModel:getLimitFeedQuality()
    return checkint(self.limitFeedQuality_)
end
function HouseCatModel:setLimitFeedQuality(quality)
    self.limitFeedQuality_ = checkint(quality)
end


--[[
    猫咪 添加效果模型
]]
function HouseCatModel:appendEffectModel_(type, refId)
    local effectIdList = CatHouseUtils.GetCatEffectIdListBySource(type, refId)
    for _, effectId in ipairs(effectIdList) do
        self.effectsMap_[checkint(effectId)] = self.effectsMap_[checkint(effectId)] or {}
        ---@type HouseCatEffectModel
        local effectModel = HouseCatEffectModel.new(type, refId, effectId)
        local modelList   = checktable(self.effectsMap_[checkint(effectId)])
        if #modelList == 0 or effectModel:isOverlay() then
            app.catHouseMgr:executeCatEffectModel(self, effectModel, 'append')
        end
        table.insert(modelList, effectModel)
    end
end


--[[
    猫咪 移除效果模型
]]
function HouseCatModel:removeEffectModel_(type, refId)
    local effectIdList = CatHouseUtils.GetCatEffectIdListBySource(type, refId)
    for _, effectId in ipairs(effectIdList) do
        local modelList = checktable(self.effectsMap_[checkint(effectId)])
        for modelIndex = #modelList, 1, -1 do
            ---@type HouseCatEffectModel
            local effectModel = modelList[modelIndex]
            if effectModel:getSourceType() == type and effectModel:getSourceRefId() == checkint(refId) then
                if #modelList == 1 or effectModel:isOverlay() then
                    app.catHouseMgr:executeCatEffectModel(self, effectModel, 'remove')
                end
                table.remove(modelList, modelIndex)
                break
            end
        end
    end
end


--[[
    猫咪 效果值定义
]]
function HouseCatModel:getEffectValuesDict()
    return self.effectDict_
end


--[[
    发送事件
]]
function HouseCatModel:toEvent_(eventName, eventData)
    local sendEventData    = eventData or {}
    sendEventData.catUuid  = self:getUuid()
    sendEventData.catModel = self
    self:dispatchEvent_(eventName, sendEventData)
end


--[[
    同步的tag值
]]
---@ alias tag integer
---| '1' #属性减少
---| '2' #睡觉结束
---| '3' #如厕结束
---| '4' #年龄增加
---| '5' #外出结束
---| '6' #交配结束
---| '7' #交配等待未响应
---| '8' #接受交配邀请
---| '9' #好感度变化同步
function HouseCatModel:setSyncTag(tag)
    self.syncTag_ = checkint(tag)
    if self:getSyncTag() > 0 then
        if not self:hasSynced() and app.catHouseMgr:getHouseCatUuid() == self:getUuid() then
            app.catHouseMgr:checkSyncCatData(self:getUuid())
            self:setIsSynced(true)
        end
    else
        self:setIsSynced(false)
    end
end
function HouseCatModel:getSyncTag()
    return checkint(self.syncTag_)

end


--[[
    是否同步
]]
function HouseCatModel:hasSynced()
    return checkbool(self.hasSync_)
end
function HouseCatModel:setIsSynced(isSync)
    self.hasSync_ = checkbool(isSync)
end


-------------------------------------------------
-- model factory

local CatHouseModelFactory = {
    HouseCatModel       = HouseCatModel,
    HouseCatAttrModel   = HouseCatAttrModel,
    HouseCatEffectModel = HouseCatEffectModel,
}

return CatHouseModelFactory
