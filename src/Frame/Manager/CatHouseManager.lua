--[[
 * author : kaishiqi
 * descpt : 猫屋 管理器
]]
local CatHouseModelFactory = require('Game.models.CatHouseModelFactory')
local HouseCatModel        = CatHouseModelFactory.HouseCatModel
local BaseManager          = require('Frame.Manager.ManagerBase')
---@class CatHouseManager:CatHouseManager
local CatHouseManager      = class('CatHouseManager', BaseManager)


-------------------------------------------------
-- manager method

CatHouseManager.DEFAULT_NAME = 'CatHouseManager'
CatHouseManager.instances_   = {}


function CatHouseManager.GetInstance(instancesKey)
    instancesKey = instancesKey or CatHouseManager.DEFAULT_NAME

    if not CatHouseManager.instances_[instancesKey] then
        CatHouseManager.instances_[instancesKey] = CatHouseManager.new(instancesKey)
    end
    return CatHouseManager.instances_[instancesKey]
end


function CatHouseManager.Destroy(instancesKey)
    instancesKey = instancesKey or CatHouseManager.DEFAULT_NAME

    if CatHouseManager.instances_[instancesKey] then
        CatHouseManager.instances_[instancesKey]:release()
        CatHouseManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function CatHouseManager:ctor(instancesKey)
    self.super.ctor(self)

    if CatHouseManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function CatHouseManager:initial()
    self:GetFacade():RegistObserver(POST.HOUSE_FRIEND_VISIT.sglName, mvc.Observer.new(self.onFriendVisitHandler_, self))
    self:GetFacade():RegistObserver(POST.HOUSE_EVENT_FINISH.sglName, mvc.Observer.new(self.onFinishEventDataHandler_, self))
    self:GetFacade():RegistObserver(POST.HOUSE_CAT_MATING_ANSWER.sglName, mvc.Observer.new(self.onAnswerCatMatingHandler_, self))
    self:GetFacade():RegistObserver(POST.HOUSE_CAT_SYNC.sglName, mvc.Observer.new(self.onHouseCatDataSyncHandler_, self))
    self:GetFacade():RegistObserver(SGL.CAT_HOUSE_CAT_STATUS_NOTICE, mvc.Observer.new(self.onCatStatusNoticeHandler_, self))
    self:GetFacade():RegistObserver(SGL.CAT_HOUSE_ACCEPT_BREED_INVITE, mvc.Observer.new(self.onAcceptMatingHandler_, self))
    self:GetFacade():RegistObserver(SGL.CAT_HOUSE_CHECK_UNLOCKED, mvc.Observer.new(self.onCheckUnlockedCatHouseHandler_, self))
    self:GetFacade():RegistObserver(SGL.CAT_HOUSE_FAVORIBILITY_NOTICE, mvc.Observer.new(self.onGetFavoribilityNoticeHandler_, self))
    
    self.hosueLevel_  = 0  -- 小屋等级
    self.homeData_    = {} -- 小屋数据
    self.trophyMap_   = {} -- 奖杯map
    self.gcCatList_   = {} -- 猫咪回收列表
    self.catHomeData_ = {} -- 猫咪home数据
    self.studyIdsMap_ = {} -- 每个年龄段可学习的id列表 { [age] = { studyId, ...} }

    self:initCatConfData_()
end


function CatHouseManager:release()
    self:GetFacade():UnRegistObserver(POST.HOUSE_FRIEND_VISIT.sglName, self)
    self:GetFacade():UnRegistObserver(POST.HOUSE_EVENT_FINISH.sglName, self)
    self:GetFacade():UnRegistObserver(POST.HOUSE_CAT_MATING_ANSWER.sglName, self)
    self:GetFacade():UnRegistObserver(POST.HOUSE_CAT_SYNC.sglName, self)
    self:GetFacade():UnRegistObserver(SGL.CAT_HOUSE_CAT_STATUS_NOTICE, self)
    self:GetFacade():UnRegistObserver(SGL.CAT_HOUSE_CHECK_UNLOCKED, self)
    self:GetFacade():UnRegistObserver(SGL.CAT_HOUSE_FAVORIBILITY_NOTICE, self)
    self:onHomeLeave()
end


function CatHouseManager:onHomeEnter()
    if not self.eventRefreshClocker_ then
        self.eventRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onEventRefreshUpdateHandler_))
        self.eventRefreshClocker_:start()
    end
    if not self.catsRefreshClocker_ then
        self.catsRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onCatsRefreshUpdateHandler_))
        self.catsRefreshClocker_:start()
    end
end


function CatHouseManager:onHomeLeave()
    if self.eventRefreshClocker_ then
        self.eventRefreshClocker_:stop()
        self.eventRefreshClocker_ = nil
    end
    if self.catsRefreshClocker_ then
        self.catsRefreshClocker_:stop()
        self.catsRefreshClocker_ = nil
    end
    SpineCache(SpineCacheName.CAT_HOUSE):clearCache()
end


-- hosue level
function CatHouseManager:getHouseLevel()
    return checkint(self.hosueLevel_)
end
function CatHouseManager:setHouseLevel(newLevel)
    self.hosueLevel_ = checkint(newLevel)
end


-- has unlock house
function CatHouseManager:hasUnlockHouse()
    return CommonUtils.UnLockModule(checkint(JUMP_MODULE_DATA.CAT_HOUSE)) and self:getHouseLevel() > 0
end


-- house isDecoratingMode
function CatHouseManager:isDecoratingMode()
    return checkbool(self.isHouseDecoratingMode_)
end
function CatHouseManager:setDecoratingMode(isDecorating)
    self.isHouseDecoratingMode_ = checkbool(isDecorating)
end


-- house presetSuitId
function CatHouseManager:setHousePresetSuitId(suitId)
    self.housePresetSuitId_ = checkint(suitId)
    app:DispatchObservers(SGL.CAT_HOUSE_PREVIEW_SUIT)
end

function CatHouseManager:getHousePresetSuitId()
    return checkint(self.housePresetSuitId_)
end


-------------------------------------------------
-- chat control

function CatHouseManager:joinChatRoom(roomOwnerId)
    app.chatMgr:JoinChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_HOUSE, roomOwnerId)
end


function CatHouseManager:exitChatRoom(roomOwnerId)
    app.chatMgr:ExitChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_HOUSE, roomOwnerId)
end


-------------------------------------------------
-- home data

function CatHouseManager:getHomeData()
    return self.homeData_
end
function CatHouseManager:setHomeData(initData)
    self.homeData_ = initData or {}

    -- check default
    if self:getPlayerHouseBubbleId() == 0 then
        self:setPlayerHouseBubbleId(CatHouseUtils.HOUSE_PARAM_FUNCS.INIT_BUBBLE_ID())
    end
    if self:getPlayerHouseIdentityId() == 0 then
        self:setPlayerHouseIdentityId(CatHouseUtils.HOUSE_PARAM_FUNCS.INIT_IDENTITY_ID())
    end
    if self:getPlayerHouseHeadId() == 0 then
        self:setPlayerHouseHeadId(CatHouseUtils.AVATAR_DEFAULT_HEAD_ID)
    end

    -- check friendCatData
    for _, friendCatData in ipairs(self:getHomeData().friendCats or {}) do
        friendCatData.friendCatUuid = CatHouseUtils.BuildCatUuid(friendCatData.friendId, friendCatData.friendCatId)
    end

    -- init placeCats
    self:setPlaceCatIdList(self:getHomeData().cats)
end


-------------------------------------------------
-- style data

function CatHouseManager:getPlayerHouseBubbleId()
    return checkint(self:getHomeData().bubble)
end
function CatHouseManager:setPlayerHouseBubbleId(bubbleId)
    if checkint(bubbleId) > 0 then
        self:getHomeData().bubble = checkint(bubbleId)
    end
end


function CatHouseManager:getPlayerHouseIdentityId()
    return checkint(self:getHomeData().businessCard)
end
function CatHouseManager:setPlayerHouseIdentityId(identityId)
    if checkint(identityId) > 0 then
        self:getHomeData().businessCard = checkint(identityId)
    end
end


function CatHouseManager:getPlayerHouseHeadId()
    return checkint(self:getHomeData().head)
end
function CatHouseManager:setPlayerHouseHeadId(headId)
    if checkint(headId) > 0 then
        self:getHomeData().head = checkint(headId)
    end
end


-------------------------------------------------
-- event data

function CatHouseManager:getEventCount()
    return #self:getHomeData().events
end


function CatHouseManager:getEventList()
    return self:getHomeData().events
end


function CatHouseManager:getEventData(eventIndex)
    return self:getHomeData().events[eventIndex]
end


function CatHouseManager:addEventData(eventData)
    table.insert(self:getHomeData().events, eventData)

    if self:getEventCount() > CatHouseUtils.HOUSE_PARAM_FUNCS.EVENT_VISIT_MAX() then
        table.remove(self:getHomeData().events, 1)
    end

    app:DispatchObservers(SGL.CAT_HOUSE_ON_UPDATE_EVENT_DATA, {eventType = CatHouseUtils.HOUSE_EVENT_TYPE.INVITE, append = true})
end


function CatHouseManager:delEventData(eventId)
    local removeEventId  = checkint(eventId)
    local removeEventIdx = 0
    for eventIndex = #self:getHomeData().events, 1, -1 do
        local eventData = self:getHomeData().events[eventIndex]
        if checkint(eventData.eventId) == removeEventId then
            removeEventIdx = eventIndex
            break
        end
    end
    
    if removeEventIdx > 0 then
        table.remove(self:getHomeData().events, removeEventIdx)
        app:DispatchObservers(SGL.CAT_HOUSE_ON_UPDATE_EVENT_DATA, {eventType = CatHouseUtils.HOUSE_EVENT_TYPE.INVITE, remove = true})
    end
end


function CatHouseManager:removeEventDataByRefId(refId)
    local playerId = checkint(refId)
    local eventId  = 0
    for _, eventData in pairs(self:getHomeData().events or {}) do
        if checkint(eventData.refId) == playerId then
            eventId = eventData.eventId
            break
        end
    end
    self:removeEventDataByEventId(eventId)
end


function CatHouseManager:removeEventDataByEventId(eventId)
    if checkint(eventId) > 0 then
        app.httpMgr:Post(POST.HOUSE_EVENT_FINISH.postUrl, POST.HOUSE_EVENT_FINISH.sglName, {eventId = eventId})
    end
end


function CatHouseManager:onFinishEventDataHandler_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    self:delEventData(data.requestData.eventId)
end


-------------------------------------------------
-- friend data

--[[
    更具friendId 获取猫屋等级信息
--]]
function CatHouseManager:getHouseLevelByFriendId(friendId)
    if CommonUtils.JuageMySelfOperation(friendId) then
        return self:getHouseLevel()
    else
        local friendData = CommonUtils.GetFriendData(friendId) or {}
        return checkint(friendData.houseLevel)
    end
end


--[[
    当前小屋所属主人id
]]
function CatHouseManager:getHouseOwnerId()
    return checkint(self.houseOwnerId_)
end
function CatHouseManager:setHouseOwnerId(ownerId)
    self.houseOwnerId_ = checkint(ownerId)

    if self.houseOwnerId_> 0 then
        self:joinChatRoom(self.houseOwnerId_)
        app:DispatchObservers(SGL.CAT_HOUSE_FRIEND_UPDATE_OWNER)
    else
        self:exitChatRoom(app.gameMgr:GetPlayerId())
    end
end


--[[
    正在访问的 好友小屋数据
]]
function CatHouseManager:getVisitFriendHouseData()
    return self.visitFriendHouseData_
end
function CatHouseManager:setVisitFriendHouseData(initData)
    self.visitFriendHouseData_ = initData or {}

    app:DispatchObservers(SGL.CAT_HOUSE_GET_FRIEND_AVATAR_DATA)
end


function CatHouseManager:checkCanGoToFriendHouse(friendId, isTipsShow)
    local friendId  = checkint(friendId)
    local isCanGoto = true

    if friendId <= 0 then
        isCanGoto = false
        if isTipsShow ~= false then
            app.uiMgr:ShowInformationTips(__("该好友不存在"))
        end

    elseif self:getHouseOwnerId() == friendId then
        isCanGoto = false
        if isTipsShow ~= false then
            app.uiMgr:ShowInformationTips(__("您已身处该好友御屋"))
        end
        -- 检测是否存在 该好友的小屋邀请事件
        self:removeEventDataByRefId(friendId)
    end

    return isCanGoto
end


function CatHouseManager:goToFriendHouse(friendId)
    friendId = checkint(friendId)
    if friendId == app.catHouseMgr:getHouseOwnerId() then
        return
    end
    app.httpMgr:Post(POST.HOUSE_FRIEND_VISIT.postUrl, POST.HOUSE_FRIEND_VISIT.sglName, {friendId = friendId})
end


function CatHouseManager:onFriendVisitHandler_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -- update ownerId
    self:setHouseOwnerId(data.requestData.friendId)

    -- save houseData
    self:setVisitFriendHouseData(data)

    -- 移除对应的好友邀请事件
    self:removeEventDataByRefId(data.requestData.friendId)
end


-------------------------------------------------------------------------------
-- cat about
-------------------------------------------------------------------------------

-- inited CatModule
function CatHouseManager:isInitedCatModule()
    return checkint(self:getHomeData().initCat) == 1
end
function CatHouseManager:setInitedCatModule(isInited)
    self:getHomeData().initCat = isInited and 1 or 0
end


-- catWareHouse capacity
function CatHouseManager:getCatWarehouseCapacity()
    return checkint(self:getHomeData().catWarehouseCapacity)
end
function CatHouseManager:setCatWarehouseCapacity(capacity)
    self:getHomeData().catWarehouseCapacity = checkint(capacity)
end


-- place catIdList
function CatHouseManager:getPlaceCatIdList()
    return table.keys(self:getHomeData().placeCatsMap_)
end
function CatHouseManager:setPlaceCatIdList(catIdList)
    self:getHomeData().placeCatsMap_ = {}
    for _, playerCatId in ipairs(catIdList or {}) do
        local catUuid = CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), playerCatId)
        self:getHomeData().placeCatsMap_[tostring(catUuid)] = true
    end
end
function CatHouseManager:isPlaceCatInHouse(catUuid)
    return self:getHomeData().placeCatsMap_ and self:getHomeData().placeCatsMap_[tostring(catUuid)] == true
end


-------------------------------------------------
-- cat homeData

function CatHouseManager:getCatHomeData()
    return self.catHomeData_
end
function CatHouseManager:setCatHomeData(initData)
    self.catHomeData_ = initData or {}
    
    -- init cats data
    self.catHomeData_.catsDataMap = {}
    for _, catData in pairs(self:getCatHomeData().cats or {}) do
        self:setCatModel(catData.playerCatId, catData)
    end
    
    -- init cats unlockedGeneMap
    self.catHomeData_.unlockedGeneMap = {}
    self:addCatsUnlockedGeneList(self:getCatHomeData().genes)

    -- init friend breed data
    self.catHomeData_.friendBreedMap = {}
    for _, beInvitedData in ipairs(self:getCatHomeData().beInvited or {}) do
        self:addFriendBreedData(beInvitedData)
    end
    if not self:getCatHomeData().beInvited or #self:getCatHomeData().beInvited == 0 then
        app:DispatchObservers(SGL.CAT_HOUSE_ON_UPDATE_EVENT_DATA, {eventType = CatHouseUtils.HOUSE_EVENT_TYPE.BREED, clear = true})
    end
    
    -- clean repeat datas
    self:getCatHomeData().cats  = nil
    self:getCatHomeData().genes = nil
end


-------------------------------------------------
-- cats unlockedGeneMap

function CatHouseManager:getCatsUnlockedGeneMap()
    return checktable(self:getCatHomeData().unlockedGeneMap)
end


function CatHouseManager:isCatsUnlockedGeneId(geneId)
    return self:getCatsUnlockedGeneMap()[checkint(geneId)]
end


function CatHouseManager:addCatsUnlockedGeneList(geneIdList)
    for _, geneId in ipairs(geneIdList or {}) do
        self:getCatsUnlockedGeneMap()[checkint(geneId)] = true
    end
end


-------------------------------------------------
-- cats modelMap

---@return table<string, HouseCatModel>
function CatHouseManager:getCatsModelMap()
    return checktable(self:getCatHomeData().catsDataMap)
end


---@return HouseCatModel
function CatHouseManager:getCatModel(catUuid)
    return self:getCatsModelMap()[catUuid]
end


---@param catId   string
---@param catData HouseCatModel @nil is del
function CatHouseManager:setCatModel(catId, catData)
    if catData then
        local playerCatId = checkint(catId)
        local catModel = HouseCatModel.new(playerCatId)
        self:getCatsModelMap()[catModel:getUuid()] = catModel
        catModel:updateCatData(catData) -- 绝对不能加进map记录前就设置数据，因为更新数据会触发事件，而事件回调中可能立刻访问map中的值
    else
        local catUuid = catId
        if self.catsRefreshUpdating_ then
            table.insert(self.gcCatList_, catUuid)
        else
            self:getCatsModelMap()[catUuid] = nil
        end
    end
end


-------------------------------------------------
-- breed data

function CatHouseManager:addFriendBreedData(breedData)
    breedData.timestamp     = os.time() + checkint(breedData.leftSeconds)
    breedData.friendCatUuid = CatHouseUtils.BuildCatUuid(breedData.friendId, breedData.friendCatId)
    self:getCatHomeData().friendBreedMap[checkint(breedData.friendCatId)] = breedData
    app:DispatchObservers(SGL.CAT_HOUSE_ON_UPDATE_EVENT_DATA, {eventType = CatHouseUtils.HOUSE_EVENT_TYPE.BREED, append = true})
end


function CatHouseManager:delFriendBreedData(friendCatId)
    self:getCatHomeData().friendBreedMap[checkint(friendCatId)] = nil
    app:DispatchObservers(SGL.CAT_HOUSE_ON_UPDATE_EVENT_DATA, {eventType = CatHouseUtils.HOUSE_EVENT_TYPE.BREED, remove = true})
end


function CatHouseManager:getFriendBreedData(friendCatId)
    return self:getCatHomeData().friendBreedMap[checkint(friendCatId)]
end


function CatHouseManager:getValidBreedIdList()
    local breedIdList = table.keys(self:getCatHomeData().friendBreedMap or {})
    if #breedIdList > 1 then
        table.sort(breedIdList, function(aBreedId, bBreedId)
            local aBreedData = self:getFriendBreedData(aBreedId)
            local bBreedData = self:getFriendBreedData(bBreedId)
            return aBreedData.timestamp < bBreedData.timestamp
        end)
    end
    return breedIdList
end

function CatHouseManager:getMatingRewardTimes()
    return self:getCatHomeData().matingRewardTimes
end


function CatHouseManager:replyCatMatingRequest(friendCatId, playerCatId)
    local friendBreedData = self:getFriendBreedData(friendCatId)
    if friendBreedData then
        local result = checkint(playerCatId) > 0 and 1 or 0
        local params = {friendId = friendBreedData.friendId, friendCatId = friendCatId, result = result, playerCatId = playerCatId}
        app.httpMgr:Post(POST.HOUSE_CAT_MATING_ANSWER.postUrl, POST.HOUSE_CAT_MATING_ANSWER.sglName, params)
    end
end


function CatHouseManager:onAnswerCatMatingHandler_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    self:delFriendBreedData(data.requestData.friendCatId)
    app:DispatchObservers(SGL.CAT_MODULE_CAT_MATING_ANSWER, {data = data.requestData})
end
---[[
--- 猫咪生育完成数据更新
---@param playerCatId number 猫咪唯一id
---@param birthCdTime number 生育cd时间
---]]
function CatHouseManager:catMatingEnd(playerCatId, birthCdTime)
    local catUuid = CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), playerCatId)
    local catModel = self:getCatModel(catUuid)
    catModel:cleanMatingData()
    catModel:setMatingCDLeftSeconds(birthCdTime)
end


-------------------------------------------------
-- study data

function CatHouseManager:getStudyIdListByAgeId(ageId)
    return checktable(self.studyIdsMap_[checkint(ageId)])
end


function CatHouseManager:initCatConfData_()
    for _, studyConf in pairs(CONF.CAT_HOUSE.CAT_STUDY:GetAll()) do
        local studyId = checkint(studyConf.id)
        for _, ageId in ipairs(studyConf.ages) do
            if not self.studyIdsMap_[checkint(ageId)] then
                self.studyIdsMap_[checkint(ageId)] = {}
            end
            table.insert(self.studyIdsMap_[checkint(ageId)], studyId)
        end
    end
end


-------------------------------------------------
-- set in view cat uuid
function CatHouseManager:setHouseCatUuid(uid)
    self.houseCatUuid_ = tostring(uid)
    if self:getHouseCatUuid() ~= "" then
        app.catHouseMgr:checkSyncCatData(self:getHouseCatUuid())
    end
end
function CatHouseManager:getHouseCatUuid()
    return tostring(self.houseCatUuid_)
end

-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------

function CatHouseManager:onEventRefreshUpdateHandler_()
    local currentTimestamp  = os.time()
    for friendCatId, breedData in pairs(self:getCatHomeData().friendBreedMap or {}) do
        if breedData.timestamp <= currentTimestamp then
            self:delFriendBreedData(friendCatId)
        end
    end
end


function CatHouseManager:onHouseCatDataSyncHandler_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    
    local catModel = self:getCatModel(CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), data.playerCatId))
    if catModel then

        -- update cat model
        if data.catId              then catModel:setRace(data.catId) end
        if data.name               then catModel:setName(data.name) end
        if data.renamed            then catModel:setRenamed(checkint(data.renamed) == 1) end
        if data.gene               then catModel:addGeneList(data.gene) end
        if data.generation         then catModel:setGeneration(data.generation) end
        if data.age                then catModel:setAge(data.age) end
        if data.nextAgeLeftSeconds then catModel:setNextAgeLeftSeconds(data.nextAgeLeftSeconds) end
        if data.sex                then catModel:setSex(data.sex) end
        if data.ability            then catModel:resetAbilities(data.ability) end
        if data.attr               then catModel:syncAllAttrs(data.attr) end
        if data.rebirth            then catModel:setRebirth(checkint(data.rebirth) == 1) end
        if data.career             then catModel:updateCareers(data.career) end
        if data.status or data.death then catModel:resetPhysicalStatus(data.status, data.death) end
        if data.mating             then catModel:setMatingData(data.mating) end
        if data.matingHouseLeftSeconds then catModel:setHouseLeftSeconds(data.matingHouseLeftSeconds) end
        if data.favorabilityList   then catModel:addLikeRelationList(data.favorabilityList) end
        -- add unlock geneList
        self:addCatsUnlockedGeneList(data.gene)

        -- update sync tag
        catModel:setSyncTag()
    end
end


function CatHouseManager:onCatStatusNoticeHandler_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    for playerCatId, status in pairs(data.status or {}) do
        local catModel = self:getCatModel(CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), playerCatId))
        if catModel then
            for _, statuData in pairs(status) do
                catModel:addPhysicalState(statuData.statusId, statuData.leftSeconds, statuData.deathTimestamp)
            end
        end
    end
end

function CatHouseManager:onAcceptMatingHandler_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    local catUuid = CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), data.playerCatId)
    self:updateCatLogicByAcceptInvite(catUuid)
end


function CatHouseManager:onCheckUnlockedCatHouseHandler_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if CommonUtils.GetModuleOpenRestaurantLevel(MODULE_DATA[tostring(RemindTag.CAT_HOUSE)]) == checkint(data.restaurantLevel) then
        local rewardsAvatar  = {}
        for _, goodsData in pairs(CONF.CAT_HOUSE.AVATAR_INIT:GetAll()) do
            table.insert(rewardsAvatar, {goodsId = goodsData.goodsId, num = 1})
        end
        CommonUtils.DrawRewards(rewardsAvatar)
    end
end


function CatHouseManager:onGetFavoribilityNoticeHandler_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    for key, value in pairs(data.exp) do
        local arrKey      = string.split(key, "_")
        local playerId    = checkint(arrKey[1])
        local firendId    = checkint(arrKey[2])
        local selfCatId   = checkint(arrKey[3])
        local friendCatId = checkint(arrKey[4])

        local catUuid  = CatHouseUtils.BuildCatUuid(playerId, selfCatId)
        local catModel = self:getCatModel(catUuid)
        if catModel ~= nil then
            local friendCatUuid = CatHouseUtils.BuildCatUuid(firendId, friendCatId)
            if catModel:hasLikeFriendCatData(friendCatUuid) then
                catModel:addLikeFriendCatExp(friendCatUuid, value)
            else
                catModel:setSyncTag(9)
            end
        end
    end
end


function CatHouseManager:onCatsRefreshUpdateHandler_()
    -- mark updating
    self.catsRefreshUpdating_ = true

    -- update cats logic
    for catUuid, catModel in pairs(self:getCatsModelMap()) do
        self:updateCatLogic(catModel)
    end

    -- unmark updating
    self.catsRefreshUpdating_ = false

    -- gc catList
    for _, catUuid in ipairs(self.gcCatList_) do
        self:setCatModel(catUuid, nil)
    end
    self.gcCatList_ = {}

    -- send refresh event
    app:DispatchObservers(SGL.CAT_MODULE_CAT_REFRESH_UPDATE)
end


---@param catModel HouseCatModel
function CatHouseManager:updateCatLogic(catModel)
    if catModel:isAlive() then
        self:updateCatLogicByAge(catModel)
        self:updateCatLogicByOut(catModel)
        self:updateCatLogicByLife(catModel)
        self:updateCatLogicByMating(catModel)
        -- 工作中、学习中、外出中、交配中、开房中，锁属性锁状态不更新
        if catModel:isStudying() or catModel:isWorking() or catModel:isHousing() or catModel:isMating() or catModel:isOutGoing() then
        else
            self:updateCatLogicByAttrs(catModel)
            self:updateCatLogicByStatus(catModel)
        end
    end
end


---@param catModel HouseCatModel
function CatHouseManager:updateCatLogicByAge(catModel)
    -- age over
    if catModel:getAge() < CatHouseUtils.CAT_PARAM_FUNCS.AGE_MAX() then
        if catModel:getNextAgeLeftSeconds() < 0 then
            -- to sync data
            app.httpMgr:Post(POST.HOUSE_CAT_SYNC.postUrl, POST.HOUSE_CAT_SYNC.sglName, {playerCatId = catModel:getPlayerCatId(), from = 4})  -- 4 年龄增加
        end
    end
end


---@param catModel HouseCatModel
function CatHouseManager:updateCatLogicByOut(catModel)
    -- out over
    if catModel:getOutFriendId() > 0 and catModel:getOutLeftSeconds() < 0 then
        -- come back
        catModel:setOutFriendId(0)
        catModel:setOutLeftSeconds(0)
        -- 回来才算成功外出一次，才扣外出次数
        -- catModel:setOutCountLeft(catModel:getOutCountLeft() - 1)
        -- to sync data
        app.httpMgr:Post(POST.HOUSE_CAT_SYNC.postUrl, POST.HOUSE_CAT_SYNC.sglName, {playerCatId = catModel:getPlayerCatId(), from = 5})  -- 5 外出结束
    end
end


---@param catModel HouseCatModel
function CatHouseManager:updateCatLogicByLife(catModel)
    -- toilet over
    if catModel:getToiletTimestamp() > 0 and catModel:getToiletLeftSeconds() < 0 then
        catModel:setToiletLeftSeconds(0)
        -- to sync data
        app.httpMgr:Post(POST.HOUSE_CAT_SYNC.postUrl, POST.HOUSE_CAT_SYNC.sglName, {playerCatId = catModel:getPlayerCatId(), from = 3})  -- 3 厕所结束
    end
    -- sleep over
    if catModel:getSleepTimestamp() > 0 and catModel:getSleepLeftSeconds() < 0 then
        catModel:setSleepLeftSeconds(0)
        -- to sync data
        app.httpMgr:Post(POST.HOUSE_CAT_SYNC.postUrl, POST.HOUSE_CAT_SYNC.sglName, {playerCatId = catModel:getPlayerCatId(), from = 2})  -- 2 睡觉结束
    end
end


---@param catModel HouseCatModel
function CatHouseManager:updateCatLogicByMating(catModel)
    -- house over
    if catModel:getHouseLeftSeconds() < 0 and (not catModel:hasMatingData()) and catModel:isMatingInviteEmpty() == false then
        app:DispatchObservers(SGL.CAT_HOUSE_HOUSE_LEFT_SECONDS_ZERO, {playerCatId = catModel:getPlayerCatId()})
        catModel:cleanMatingInvite()
        -- to sync data
        app.httpMgr:Post(POST.HOUSE_CAT_SYNC.postUrl, POST.HOUSE_CAT_SYNC.sglName, {playerCatId = catModel:getPlayerCatId(), from = 7})  -- 7 交配未响应
    end
end


---@param catModel HouseCatModel
function CatHouseManager:updateCatLogicByStatus(catModel)
    for statusId, statusData in pairs(catModel:getPhysicalStatusMap()) do
        -- state deadly
        if catModel:isPhysicalStateDeadly(statusId) then
            catModel:setAlive(false)  -- 有一个状态致死了，就没必要更新剩下的状态了
            break
        end
        -- state over
        if catModel:getPhysicalStateLeftSeconds(statusId) < 0 then
            catModel:delPhysicalState(statusId)
        end
    end
end


---@param catModel HouseCatModel
function CatHouseManager:updateCatLogicByAttrs(catModel)
    -- attr reduce
    local currentTimestamp = os.time()
    for attrId, attrModel in pairs(catModel:getAllAttrModel()) do
        local updateTimestamp = attrModel:getUpdateTimestamp()
        local reduceSeconds   = attrModel:getReduceTime()
        local offsetSeconds   = currentTimestamp - updateTimestamp
        if attrModel:getAttrNum() > 0 then
            if reduceSeconds > 0 and offsetSeconds >= reduceSeconds and attrModel:isDisableReduce() == false then
                local reduceValue  = math.floor(offsetSeconds / reduceSeconds)
                local remainingNum = offsetSeconds - reduceValue * reduceSeconds
                local newTimestamp = currentTimestamp - remainingNum
                -- 属性掉光也不会立刻死亡，只会触产生有死亡倒计时的状态
                attrModel:setUpdateTimestamp(newTimestamp)
                catModel:setAttrNum(attrId, attrModel:getAttrNum() - reduceValue)
            end
        else
            attrModel:setUpdateTimestamp(os.time())
        end
    end
end


function CatHouseManager:checkSyncCatData(catUuid)
    local catModel = self:getCatModel(catUuid)
    if catModel then
        if catModel:getSyncTag() > 0 then
            app.httpMgr:Post(POST.HOUSE_CAT_SYNC.postUrl, POST.HOUSE_CAT_SYNC.sglName, {playerCatId = catModel:getPlayerCatId(), from = catModel:getSyncTag()})
        
        elseif catModel:getSnycAttrsTimestamp() > 0 and os.time() - catModel:getSnycAttrsTimestamp() > 300 then  -- 先暂定超过5分钟没同步过数据的话，则检测同步一次
            -- to sync data
            app.httpMgr:Post(POST.HOUSE_CAT_SYNC.postUrl, POST.HOUSE_CAT_SYNC.sglName, {playerCatId = catModel:getPlayerCatId(), from = 1})  -- 1 属性减少
        end
    end
end


function CatHouseManager:checkSyncCatDataByMatingEnded(catUuid)
    local catModel = self:getCatModel(catUuid)
    if catModel then
        -- to sync data
        app.httpMgr:Post(POST.HOUSE_CAT_SYNC.postUrl, POST.HOUSE_CAT_SYNC.sglName, {playerCatId = catModel:getPlayerCatId(), from = 6})  -- 6 交配结束
    end
end

function CatHouseManager:updateCatLogicByAcceptInvite(catUuid)
    local catModel = self:getCatModel(catUuid)
    if catModel then
        -- to sync data
        app.httpMgr:Post(POST.HOUSE_CAT_SYNC.postUrl, POST.HOUSE_CAT_SYNC.sglName, {playerCatId = catModel:getPlayerCatId(), from = 8}) -- 接受交配邀请
    end
    
end


-- 执行猫咪效果模型
---@param catModel HouseCatModel
---@param effectModel HouseCatEffectModel
---@param executeMode string | "'append'" | "'remove'"
function CatHouseManager:executeCatEffectModel(catModel, effectModel, executeMode)
    if catModel == nil or effectModel == nil then return end
    local isAppendMode     = executeMode == 'append'
    local isRemoveMode     = executeMode == 'remove'
    local catEffectDict    = catModel:getEffectValuesDict()
    local catEffectTypeMap = effectModel:getEffectTypeMap()
    
    for catEffectType, _ in pairs(catEffectTypeMap) do
        --------------------------------------------------------------------------------------------------
        -- _id_属性【衰减速度】增加/减少_num_%
        if catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.ATTR_REDUCE_RATE then
            local reduceRateAttrId  = checkint(effectModel:getTargetId())
            local reduceRateAttrNum = math.ceil(checknumber(effectModel:getTargetNum()) * 100)
            local effectAttrIdList  = reduceRateAttrId > 0 and { reduceRateAttrId } or table.keys(catModel:getAllAttrModel())
            for _, attrId in ipairs(effectAttrIdList) do
                local catAttrModel = catModel:getAllAttrModel()[checkint(attrId)]
                if catAttrModel then
                    if isAppendMode then
                        catAttrModel:setReduceRate(catAttrModel:getReduceRate() + reduceRateAttrNum)
                    elseif isRemoveMode then
                        catAttrModel:setReduceRate(catAttrModel:getReduceRate() - reduceRateAttrNum)
                    end
                end
            end

        --------------------------------------------------------------------------------------------------
        -- _id_属性【上限】增加/减少_num_点
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.ATTR_UPPER_LIMIT then
            local upperLimitAttrId  = checkint(effectModel:getTargetId())
            local upperLimitAttrNum = checkint(effectModel:getTargetNum())
            if isAppendMode then
                catModel:setAttrMaxEx(upperLimitAttrId, catModel:getAttrMaxEx(upperLimitAttrId) + upperLimitAttrNum)
            elseif isRemoveMode then
                catModel:setAttrMaxEx(upperLimitAttrId, catModel:getAttrMaxEx(upperLimitAttrId) - upperLimitAttrNum)
            end

        --------------------------------------------------------------------------------------------------
        -- 学习【支付花费】降低_num_%
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.STYDY_CONSUME_RATE then
            local stydyConsumeRate = math.ceil(checknumber(effectModel:getTargetNum()) * -100)
            if isAppendMode then
                catModel:setStydyConsumeRate(catModel:getStydyConsumeRate() + stydyConsumeRate)
            elseif isRemoveMode then
                catModel:setStydyConsumeRate(catModel:getStydyConsumeRate() - stydyConsumeRate)
            end

        --------------------------------------------------------------------------------------------------
        -- 好感度【每次操作后】额外增加_num_点
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.LIKE_EXTRA_NUM then
            local addLikeExtraExp = checkint(effectModel:getTargetNum())
            if isAppendMode then
                catModel:setLikeExpAdd(catModel:getLikeExpAdd() + addLikeExtraExp)
            elseif isRemoveMode then
                catModel:setLikeExpAdd(catModel:getLikeExpAdd() - addLikeExtraExp)
            end

        --------------------------------------------------------------------------------------------------
        -- 外出【每日最大次数】增加_num_
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.OUT_MAX_COUNT then
            local addOutCountMax = checkint(effectModel:getTargetNum())
            if isAppendMode then
                catModel:setOutCountMax(catModel:getOutCountMax() + addOutCountMax)
            elseif isRemoveMode then
                catModel:setOutCountMax(catModel:getOutCountMax() - addOutCountMax)
            end

        --------------------------------------------------------------------------------------------------
        -- _id_属性【不会减少】
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.ATTR_REDUCE_DISABLE then
            local attrId = checkint(effectModel:getTargetId())
            catEffectDict.attrReduceDisableMap = catEffectDict.attrReduceDisableMap or {}
            if isAppendMode then
                catEffectDict.attrReduceDisableMap[attrId] = checkint(catEffectDict.attrReduceDisableMap[attrId]) + 1
            elseif isRemoveMode then
                catEffectDict.attrReduceDisableMap[attrId] = checkint(catEffectDict.attrReduceDisableMap[attrId]) - 1
            end
            catModel:setDisableAttrReduceAt(attrId, checkint(catEffectDict.attrReduceDisableMap[attrId]) > 0)

        --------------------------------------------------------------------------------------------------
        -- 好感度【不增加】
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.LIKE_DISABLE then
            if isAppendMode then
                catEffectDict.likeUpdateDisableCount = checkint(catEffectDict.likeUpdateDisableCount) + 1
            elseif isRemoveMode then
                catEffectDict.likeUpdateDisableCount = checkint(catEffectDict.likeUpdateDisableCount) - 1
            end
            catModel:setDisableLikeUpdate(checkint(catEffectDict.likeUpdateDisableCount) > 0)

        --------------------------------------------------------------------------------------------------
        -- 只能吃【_id_品质及以上】的食物
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.FEED_GOODS_QUALITY then
            local goodsQuality = checkint(effectModel:getTargetId())
            if isAppendMode then
                catEffectDict.limitFeedQualityCount = checkint(catEffectDict.limitFeedQualityCount) + 1
            elseif isRemoveMode then
                catEffectDict.limitFeedQualityCount = checkint(catEffectDict.limitFeedQualityCount) - 1
            end
            if checkint(catEffectDict.limitFeedQualityCount) > 0 then
                catModel:setLimitFeedQuality(goodsQuality)
            else
                catModel:setLimitFeedQuality(0)
            end

        --------------------------------------------------------------------------------------------------
        -- 外表基因【失效】
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.GENE_FACADE_DISABLE then
            if isAppendMode then
                catEffectDict.facadeDisableCount = checkint(catEffectDict.facadeDisableCount) + 1
            elseif isRemoveMode then
                catEffectDict.facadeDisableCount = checkint(catEffectDict.facadeDisableCount) - 1
            end
            catModel:setDisableFacade(checkint(catEffectDict.facadeDisableCount) > 0)

        --------------------------------------------------------------------------------------------------
        -- 无法【上厕所】
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.TOILET_DISABLE then
            if isAppendMode then
                catEffectDict.toiletDisableCount = checkint(catEffectDict.toiletDisableCount) + 1
            elseif isRemoveMode then
                catEffectDict.toiletDisableCount = checkint(catEffectDict.toiletDisableCount) - 1
            end
            catModel:setDisableToilet(checkint(catEffectDict.toiletDisableCount) > 0)

        --------------------------------------------------------------------------------------------------
        -- 无法【进食】
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.FEED_DISABLE then
            if isAppendMode then
                catEffectDict.feedDisableCount = checkint(catEffectDict.feedDisableCount) + 1
            elseif isRemoveMode then
                catEffectDict.feedDisableCount = checkint(catEffectDict.feedDisableCount) - 1
            end
            catModel:setDisableFeed(checkint(catEffectDict.feedDisableCount) > 0)

        --------------------------------------------------------------------------------------------------
        -- 无法【入睡】
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.SLEEP_DISABLE then
            if isAppendMode then
                catEffectDict.sleepDisableCount = checkint(catEffectDict.sleepDisableCount) + 1
            elseif isRemoveMode then
                catEffectDict.sleepDisableCount = checkint(catEffectDict.sleepDisableCount) - 1
            end
            catModel:setDisableSleep(checkint(catEffectDict.sleepDisableCount) > 0)

        --------------------------------------------------------------------------------------------------
        -- 无法【进行任何操作】
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.ANYTHING_DISABLE then
            if isAppendMode then
                catEffectDict.anythingDisableCount = checkint(catEffectDict.anythingDisableCount) + 1
            elseif isRemoveMode then
                catEffectDict.anythingDisableCount = checkint(catEffectDict.anythingDisableCount) - 1
            end
            catModel:setDisableAnything(checkint(catEffectDict.anythingDisableCount) > 0)

        --------------------------------------------------------------------------------------------------
        -- 工作【可额外获得】_num_%经验
        elseif catEffectType == CatHouseUtils.CAT_EFFECT_TYPE_ENUM.WORK_EXTRA_EXP_RATE then
            local workIncomeRate = math.ceil(checknumber(effectModel:getTargetNum()) * 100)
            if isAppendMode then
                catModel:setWorkIncomeRate(catModel:getWorkIncomeRate() + workIncomeRate)
            elseif isRemoveMode then
                catModel:setWorkIncomeRate(catModel:getWorkIncomeRate() - workIncomeRate)
            end
        end
    end
end


function CatHouseManager:equipCat(catUuid)
    local catModel = app.catHouseMgr:getCatModel(catUuid)
    local equippedHouseCat = {
        geneOriginal       = catModel:getGeneOriginal(),
        age                = catModel:getAge(),
        id                 = catModel:getPlayerCatId(),
        name               = catModel:getName(),
        nextAgeLeftSeconds = math.max(catModel:getNextAgeLeftSeconds(), 0),
    }
    app.gameMgr:GetUserInfo().equippedHouseCat = equippedHouseCat
    app.gameMgr:GetUserInfo().equippedHouseCatTimeStamp = os.time()
end
return CatHouseManager
