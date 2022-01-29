--[[
包厢管理模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class PrivateRoomManager
local PrivateRoomManager = class('PrivateRoomManager',ManagerBase)

PrivateRoomManager.instances = {}
PrivateRoomManager.DEFAULT_NAME = 'PrivateRoomManager'

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function PrivateRoomManager:ctor( key )
    self.super.ctor(self)
    if PrivateRoomManager.instances[key] ~= nil then
        funLog(Logger.INFO,"注册相关的facade类型" )
        return
    end
    PrivateRoomManager.instances[key] = self

    self.privateRoomData = {} -- 包厢数据(home)
    self.guestListDatas  = {} -- 包厢贵宾数据
end

function PrivateRoomManager.GetInstance(key)
    key = key or PrivateRoomManager.DEFAULT_NAME
    if PrivateRoomManager.instances[key] == nil then
        PrivateRoomManager.instances[key] = PrivateRoomManager.new(key)
    end
    return PrivateRoomManager.instances[key]
end


function PrivateRoomManager.Destroy( key )
    key = key or PrivateRoomManager.DEFAULT_NAME
    if PrivateRoomManager.instances[key] == nil then
        return
    end
    --清除配表数据
    PrivateRoomManager.instances[key] = nil
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- utils begin --
---------------------------------------------------
--[[
初始化包厢数据(home)
@params homeData table 餐厅home数据
--]]
function PrivateRoomManager:InitPrivateRoomData( homeData )
    local data = homeData or {}
    if not data.themeId or checkint(data.themeId) == 0 then
        local init = self:GetDefaultThemeId()
        data.themeId = init -- 如果没有主题则使用默认主题
    end
    self.privateRoomData = data
    self:InitWallData(data.wall)
end
--[[
获取默认themeId
--]]
function PrivateRoomManager:GetDefaultThemeId()
    local themeId = CommonUtils.GetConfig('privateRoom', 'avatarThemeInit', 1).themeId
    return themeId
end
--[[
获取包厢数据(home)
--]]
function PrivateRoomManager:GetPrivateRoomData()
    return self.privateRoomData
end
--[[
初始化陈列墙数据
@params wallData map 陈列墙数据（key:陈列墙位置id， value:纪念品Id）
--]]
function PrivateRoomManager:InitWallData( wallData )
    local data = wallData or {}
    local parserConfig  = self:GetConfigParse()
    local giftPosConf = self:GetConfigDataByName(parserConfig.TYPE.GIFT_POSITION)
    local temp = {}
    for k, v in pairs(giftPosConf) do
        if data[k] then
            temp[k] = data[k]
        else
            temp[k] = ''
        end
    end
    self:SetWallData(temp)
end
--[[
初始化贵宾列表数据
@params themeId int 主题id
--]]
function PrivateRoomManager:InitGuestListDatas()
    local guestListDatas = {}
    local guestsDatas = self:GetGuests()
    local guestsDataMap = {}
    for i, v in ipairs(guestsDatas) do
        guestsDataMap[tostring(v.guestId)] = v
    end
    local guestConfs = CommonUtils.GetConfigAllMess('guest', 'privateRoom') or {}
    local restaurantLevel     = app.gameMgr:GetUserInfo().restaurantLevel
    local index = 1
    for i, guestConf in orderedPairs(guestConfs) do
        guestListDatas[index] = guestListDatas[index] or {}

        local openRestaurantLevel = checkint(guestConf.openRestaurantLevel)

        local id = guestConf.id
        table.insert(guestListDatas[index], {
            guestConf = guestConf,
            isUnlock  = restaurantLevel >= openRestaurantLevel,
            storyCount = table.nums(guestConf.story or {}),
            guestsData = guestsDataMap[tostring(id)] or {}
        })

        if (i % 2) == 0 then
            index = index + 1
        end
    end

    self.guestListDatas = guestListDatas
end
--[[
初始化剧情数据
--]]
function PrivateRoomManager:InitStoryDatas(storys, dialogues)
    if storys == nil or dialogues == nil then return end

    local storyDatas = {}
    for i, storyId in ipairs(storys) do
        table.insert(storyDatas, {
            dialogueConf = self:GetGuestDialogueConfByDialogueId(storyId),
            dialogue = dialogues[storyId],
        })        
    end
    return storyDatas
end
--[[
设置包厢信息
--]]
function PrivateRoomManager:SetPrivateRoomData( privateRoomData )
    local data = privateRoomData or {}
    table.merge(self.privateRoomData, data)
end
--[[
设置陈列墙数据
--]]
function PrivateRoomManager:SetWallData( wallData )
    self.privateRoomData.wallData = wallData
    -- 发送信号 更新陈列墙状态
	AppFacade.GetInstance():DispatchObservers(PRIVATEROOM_UPDATE_WALL)
end
--[[
获取陈列墙数据
@return 格式化后的陈列墙数据
--]]
function PrivateRoomManager:GetWallData()
    return self.privateRoomData.wallData
end
--[[
设置包厢主题
@params themeId int 包厢主题id
--]]
function PrivateRoomManager:SetThemeId( themeId )
    if not themeId then return end
    self.privateRoomData.themeId = themeId
end
--[[
获取当前包厢主题
@return themeId int 包厢主题id
--]]
function PrivateRoomManager:GetThemeId()
    return self.privateRoomData.themeId
end
--[[
获取客人列表
@return guests table 客人列表
--]]
function PrivateRoomManager:GetGuests()
    return checktable(self.privateRoomData.guests)
end
--[[
设置客人列表
@params guests table 客人列表
--]]
function PrivateRoomManager:SetGuests(guests)
    self.privateRoomData.guests = guests
end
--[[
通过顾客id获取客人信息
@params guestId int 顾客id
--]]
function PrivateRoomManager:GetGuestDataByGuestId( guestId )
    local guestsData = self:GetGuests()
    local data = {}
    for i, v in ipairs(guestsData) do
        if checkint(guestId) == checkint(v.guestId) then
            data = v
            break
        end
    end
    return data
end
--[[
设置客人数据
@return isUnlock bool 是否解锁剧情
--]]
function PrivateRoomManager:SetGuest()
    local guests          = self:GetGuests() or {}
    local assistantId     = self:GetWaiter()
    local guestId         = checkint(self:GetGuestId())
    local guestDialogueId = self:GetGuestDialogueId()
    local isUnlock        = false

    local guestIndex = 0
    for i, guestData in ipairs(guests) do
        --  相同的贵宾id则更新数据
        if checkint(guestData.guestId) == guestId then
            guestIndex = i
            guestData.serveTimes = guestData.serveTimes + 1
            guestData.grade = self:GetGuestGradeByServeTimes(guestData.serveTimes, guestData.grade)
            
            if guestData.dialogues[tostring(guestDialogueId)] == nil then
                guestData.dialogues[tostring(guestDialogueId)] = {assistantId = assistantId}
                isUnlock        = true
            end
        end
    end

    -- 如果是新贵宾则插入数据
    if guestIndex == 0 then
        table.insert(guests, {
            guestId = guestId,
            grade   = 1,
            serveTimes = 1,
            dialogues = {
                [tostring(guestDialogueId)] = {assistantId = assistantId}
            },
            hasDrawn = 0
        })
        isUnlock        = true
    end

    self:SetGuests(guests)
    return isUnlock
end
--[[
设置服务员
@params playerCardId int 卡牌自增id
--]]
function PrivateRoomManager:SetWaiter( playerCardId )
    if not playerCardId then return end
    self.privateRoomData.assistantId = playerCardId
end
--[[
获取当前服务员
@return playerCardId int 卡牌自增id
--]]
function PrivateRoomManager:GetWaiter()
    return self.privateRoomData.assistantId
end
--[[
获取客人Id
@return guestId int 客人id
--]]
function PrivateRoomManager:GetGuestId()
    return self.privateRoomData.guestId
end
--[[
获取对话Id
@return guestDialogueId int 本次订单对话id
--]]
function PrivateRoomManager:GetGuestDialogueId()
    return self.privateRoomData.guestDialogueId
end
--[[
获取基础服务次数
@return baseServeTimes int 基础服务次数上限
--]]
function PrivateRoomManager:GetBaseServeTimes()
    return checkint(self.privateRoomData.baseServeTimes)
end
--[[
获取剩余购买次数
@return leftBuyTimes int 剩余购买次数
--]]
function PrivateRoomManager:GetLeftBuyTimes()
    return checkint(self.privateRoomData.leftBuyTimes)
end
--[[
获取剩余服务次数
@return leftServeTimes int 剩余服务次数
--]]
function PrivateRoomManager:GetLeftServeTimes()
    return checkint(self.privateRoomData.leftServeTimes)
end
--[[
获取贵宾列表数据
@return guestListDatas table 贵宾列表数据
--]]
function PrivateRoomManager:GetGuestListDatas()
    return self.guestListDatas
end
--[[
获取菜单菜品
--]]
function PrivateRoomManager:GetFoods()
    local foodsData = {}
	for k, v in pairs(checktable(self.privateRoomData.foods)) do
		local temp = {}
		temp.goodsId = checkint(k)
		temp.num = checkint(v)
		table.insert(foodsData, temp)
	end
    return foodsData
end
--[[
获取第二个npc
@return guestId int 顾客id(没有则返回nil)
--]]
function PrivateRoomManager:GetSecondGuest()
    local dialogueId = self:GetGuestDialogueId()
    local dialogueConf = CommonUtils.GetConfig('privateRoom', 'guestDialogue', dialogueId)
    local guestId = nil 
    if dialogueConf and checkint(dialogueConf.type) == 3 then
        guestId = checkint(dialogueConf.npcId)
    end
    return guestId
end
--[[
获取全部纪念品数据
--]]
function PrivateRoomManager:GetGiftConf()
    -- if self.giftConf then
    --     return self.giftConf
    -- else
        local parserConfig  = self:GetConfigParse()
        local data = self:GetConfigDataByName(parserConfig.TYPE.GUEST_GIFT)
        data = table.values(data)
        table.sort(data, function (a, b)
            local hasA = app.gameMgr:GetAmountByGoodId(a.id) > 0
            local hasB = app.gameMgr:GetAmountByGoodId(b.id) > 0
            if hasA ~= hasB then
                return hasA == true
            else
                return checkint(a.id) < checkint(b.id)
            end
        end)
        self.giftConf = data
        return data
    -- end
end

--[[
获取avatarId 
@params themeId int 主题id
--]]
function PrivateRoomManager:GetTableAvatarId( themeId )
    local themeConf = CommonUtils.GetConfig('privateRoom', 'avatarTheme', themeId)
    local avatarId = nil 
    for i, v in ipairs(checktable(themeConf.avatars)) do
        local avatarPosConf = CommonUtils.GetConfig('privateRoom', 'avatarLocation', v)
        if checkint(avatarPosConf.type) == 1 then
            avatarId = v
            break 
        end
    end
    return avatarId 
end
--[[
获取当前主题座位位置
@params tableNode node 餐桌avatar
        avatarLayout layout avatarLayout
@return
--]]
function PrivateRoomManager:GetThemeAdditionsPos( tableNode, avatarLayout )
    if not tableNode or not avatarLayout then return end
    local themeId = self:GetThemeId()
    local avatarId = self:GetTableAvatarId(themeId)
    local avatarPosConf = CommonUtils.GetConfig('privateRoom', 'avatarLocation', avatarId)
    local pos = {}
    for i, v in ipairs(avatarPosConf.additions) do
        local tablePos = self:GetAvatarLocation(v.sitLocation)
        local worldPos = tableNode:convertToWorldSpace(tablePos)
        local nodePos = avatarLayout:convertToNodeSpace(worldPos)
        table.insert(pos, nodePos)
    end
    return pos
end
--[[
通过goodsId获取纪念品列表idx
--]]
function PrivateRoomManager:GetListSouvenirIdxByGoodsId( goodsId )
    if not goodsId then return end
    local giftConf = self:GetGiftConf()
    local idx = nil
    for i, v in ipairs(giftConf) do
        if checkint(goodsId) == checkint(v.id) then
            idx = i 
            break
        end
    end
    return idx
end
--[[
通过纪念品列表idx获取goodsId
--]]
function PrivateRoomManager:GetGoodsIdByListSouvenirIdx( idx )
    if not idx then return end
    local giftConf = self:GetGiftConf()
    return giftConf[idx].id
end
--[[
判断纪念品是否已获取
@params goodsId int 纪念品goodsId
--]]
function PrivateRoomManager:IsHasSouvenirByGoodsId( goodsId )
    if not goodsId then return false end
    return app.gameMgr:GetAmountByGoodId(goodsId) > 0 
end
--[[
通过纪念品id获取buff描述
--]]
function PrivateRoomManager:GetBuffDescrByGoodsId( goodsId )
    local giftConf = CommonUtils.GetConfig('privateRoom', 'guestGift', goodsId)
    local buffConf = CommonUtils.GetConfig('privateRoom', 'buff', giftConf.buffId)
    if not giftConf or not buffConf then return {} end
    local descr = buffConf.descr
    if  buffConf.type == '2' then
        local temp = string.format('%d', giftConf.buffEffect * 100) .. '%%'
        descr = string.gsub(descr, '_target_num_', temp)
    elseif buffConf.type == '4' then
        local temp = string.format('%d', giftConf.buffEffect * 100) .. '%%'
        descr = string.gsub(descr, '_target_num_', temp)
    else
        descr = string.gsub(descr, '_target_num_', giftConf.buffEffect)
    end
    return {
        buffDescr = descr,
        name = giftConf.name
    }
end
--[[
获取包厢avatar位置坐标
@params str string 坐标str 
--]]
function PrivateRoomManager:GetAvatarLocation( str )
    if type(str) ~= 'string' then return end
    local temp = string.split(str, ',')
    return cc.p(temp[1], temp[2])
end
--[[
获取服务员上菜位置
@params tableNode node 餐桌avatar
        avatarLayout layout avatarLayout
@return pos cc.p 餐桌第二个菜品位置
--]]
function PrivateRoomManager:GetWaiterServePos( tableNode, avatarLayout, themeId )
    if not tableNode or not avatarLayout then return end
    local themeId = themeId or self:GetThemeId()
    local putPos = self:GetDishPutPos(themeId)
    local pos = putPos[2] or cc.p(0, 0)
    local worldPos = tableNode:convertToWorldSpace(putPos[2])
    local nodePos = avatarLayout:convertToNodeSpace(worldPos)
    pos = cc.p(nodePos.x, 150)
    return pos
end
--[[
获取餐桌菜品摆放位置
@params themeId int 主题id
--]]
function PrivateRoomManager:GetDishPutPos( themeId )
    if not themeId then return end
    local themeConf = CommonUtils.GetConfig('privateRoom', 'avatarTheme', themeId)
    local put = {}
    for i, v in ipairs(themeConf.avatars) do
        local avatarPosConf = CommonUtils.GetConfig('privateRoom', 'avatarLocation', v)
        if checkint(avatarPosConf.type) == 1 then
            put = avatarPosConf.putThings 
            break
        end
    end
    return put 
end
--[[
是否为最后一个顾客
--]]
function PrivateRoomManager:IsLastGuest( guestId )
    local secGuest = self:GetSecondGuest()
    local isLast = false
    if secGuest then
        if checkint(guestId) == checkint(secGuest) then
            isLast = true
        end
    else
        if checkint(guestId) == checkint(self:GetGuestId()) then
            isLast = true
        end
    end
    return isLast
end
--[[
清除顾客信息
--]]
function PrivateRoomManager:ClearGuestData()
    self.privateRoomData.guestId = nil
    self.privateRoomData.guestDialogueId = nil
    self.privateRoomData.foods = nil
    self.privateRoomData.rewards = {}
    self.privateRoomData.gold = nil
    self.privateRoomData.popularity = nil
end

function PrivateRoomManager:GetSpeakerHeadPath(speaker, guestId, npcId, assistantId)
    speaker = checkint(speaker) 
    local headPath = nil
    if speaker == 1 then
        headPath = self:GetGuestHeadPath(checkint(guestId))
    elseif speaker == 2 then
        local cardData = app.gameMgr:GetCardDataById(assistantId)
        headPath = CardUtils.GetCardHeadPathBySkinId(cardData.defaultSkinId)
    elseif speaker == 3 then
        headPath = self:GetGuestHeadPath(checkint(npcId))
    end
    return headPath
end

--[[
获取主题
@params themeId int 主题id
--]]
function PrivateRoomManager:GetThemeWallpaperPath( themeId )
    return _res(string.format("avatar/privateRoom/wallpaper_%s.jpg", themeId or 330001))
end
--[[
获取主题
@params themeId int 主题id
--]]
function PrivateRoomManager:GetGuestHeadPath(guestHeadId)
    return _res(string.format("arts/privateRoom/head/vip_role_head_%s.png", guestHeadId or 1))
end
--[[
通过当前星级配置
@params curStar int 当前星级
--]]
function PrivateRoomManager:GetGuestGradeConf(grade)
    return CommonUtils.GetConfig('privateRoom', 'guestGrade', grade) or {}
end
--[[
通过dialogueId获得dialogue配置
@params dialogueId int 当前星级
--]]
function PrivateRoomManager:GetGuestDialogueConfByDialogueId(dialogueId)
    if not dialogueId then return end
    return CommonUtils.GetConfig('privateRoom', 'guestDialogue', tostring(dialogueId)) or {}
end
--[[
通过剧情id获得对话内容
@params themeId int 主题id
--]]
function PrivateRoomManager:GetGuestDialogueContentByStoryId( storyId )
    if not storyId then return end
    return CommonUtils.GetConfig('privateRoom', 'guestDialogueContent', tostring(storyId)) or {}
end
function PrivateRoomManager:GetGuestGiftConfByGoodsId(goodsId)
    if not goodsId then return end
    return CommonUtils.GetConfig('privateRoom', 'guestGift', goodsId) or {}
end
--[[
获取包厢buff加成(纪念品加成，主题加成)
@params params table {
    type int 类型(1:金币 2:知名度 3:道具)
    num  int 
}
@return addition table {
    souvenir table 纪念品加成
    theme    table 主题加成
}
--]]
function PrivateRoomManager:GetBuffAddition( type )
    type = checkint(type)
    local wallData = self:GetWallData()
    local themeId = self:GetThemeId()
    local addition = {}
    local addNum = 0
    local pctNum = 0
    local addType = nil
    local pctType = nil 
    if type == 1 then
        addType = '1'
        pctType = '2'
    elseif type == 2 then
        addType = '3'
        pctType = '4'
    elseif type == 3 then
        addType = '5'
    end
    for k, v in pairs(wallData) do
        if v ~= '' then
            local giftConf = CommonUtils.GetConfig('privateRoom', 'guestGift', v)
            local buffConf = CommonUtils.GetConfig('privateRoom', 'buff', giftConf.buffId)
            if buffConf then
                if buffConf.type == addType then
                    addNum = addNum + giftConf.buffEffect
                elseif buffConf.type == pctType then
                    pctNum = pctNum + giftConf.buffEffect
                end
            end
        end
    end
    addition.souvenir = {add = addNum, pct = pctNum}
    local themeConf = CommonUtils.GetConfig('privateRoom', 'avatarTheme', themeId)
    local buffConf = CommonUtils.GetConfig('privateRoom', 'buff', themeConf.buffId)
    local themeAddition = {add = 0, pct = 0}
    if buffConf then
        if buffConf.type == addType then
            themeAddition.add = themeConf.buffEffect
        elseif buffConf.type == pctType then
            themeAddition.pct = themeConf.buffEffect
        end
    end
    addition.theme = themeAddition
    return addition
end

--[[
通过服务次数获得服务员品质
@params serveTimes int 服务次数
@params grade int 服务员品质
@return newGrade int 新品质
--]]
function PrivateRoomManager:GetGuestGradeByServeTimes(serveTimes, grade)
    serveTimes = checkint(serveTimes)
    grade = checkint(grade)
    local newGrade = grade
    local nextGradeConf = self:GetGuestGradeConf(grade + 1)
    while next(nextGradeConf) ~= nil and serveTimes >= checkint(nextGradeConf.serveTimes) do
        newGrade = nextGradeConf.grade
        nextGradeConf = self:GetGuestGradeConf(newGrade + 1)
        if next(nextGradeConf) == nil then
            break
        end
    end

    return newGrade
end
---------------------------------------------------
-- utils end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------

function PrivateRoomManager:GetConfigParse()
    if not self.parseConfig then
        ---@type DataManager
        self.parseConfig = app.dataMgr:GetParserByName('PrivateRoom')
    end
    return self.parseConfig
end

function PrivateRoomManager:GetConfigDataByName(name)
    ---@type PrivateRoomConfigParser
    local parseConfig = self:GetConfigParse()
    local configData  = parseConfig:GetVoById(name)
    return configData
end

---------------------------------------------------
-- get set end --
---------------------------------------------------

return PrivateRoomManager