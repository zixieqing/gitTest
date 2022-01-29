--[[
 * author : kaishiqi
 * descpt : 做菜 管理器
]]
local BaseManager    = require('Frame.Manager.ManagerBase')
---@class CookingManager
local CookingManager = class('CookingManager', BaseManager)


-------------------------------------------------
-- manager method

CookingManager.DEFAULT_NAME = 'CookingManager'
CookingManager.instances_   = {}


function CookingManager.GetInstance(instancesKey)
    instancesKey = instancesKey or CookingManager.DEFAULT_NAME

    if not CookingManager.instances_[instancesKey] then
        CookingManager.instances_[instancesKey] = CookingManager.new(instancesKey)
    end
    return CookingManager.instances_[instancesKey]
end


function CookingManager.Destroy(instancesKey)
    instancesKey = instancesKey or CookingManager.DEFAULT_NAME

    if CookingManager.instances_[instancesKey] then
        CookingManager.instances_[instancesKey]:release()
        CookingManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function CookingManager:ctor(instancesKey)
    self.super.ctor(self)

    if CookingManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function CookingManager:initial()
end


function CookingManager:release()
end


-------------------------------------------------
-- public method


function CookingManager:GetStyleTable()
    local styleData             = clone(CommonUtils.GetConfigAllMess('style', 'cooking'))  -- 解析配表
    styleData[ALL_RECIPE_STYLE] = {
        name                   = __("全部"),
        id                     = ALL_RECIPE_STYLE,
        studyRecipe            = 0,
        rewardsRecipe          = 120,
        initial                = 3,
        takeawayPrivateOrderId = 0
    }

    if app.activityMgr:isOpenLobbyFestivalActivity() then
        styleData[FESTIVAL_RECIPE_STYLE] = {
            name                   = __("节日菜谱"),
            id                     = FESTIVAL_RECIPE_STYLE,
            studyRecipe            = 0,
            rewardsRecipe          = 120,
            initial                = 3,
            takeawayPrivateOrderId = 0
        }
    end
    return styleData
end


--- 确定当前可以制作的菜谱系列
function CookingManager:getResearchStyleTable()
    local styleData        = self:GetStyleTable()
    --local recipeAllData = CommonUtils.GetConfigAllMess('recipe', 'cooking')
    local recipeStyleTable = {}
    for k, v in pairs(app.gameMgr:GetUserInfo().cookingStyles) do
        --不能遍历菜系的内容 因为菜系的元素可能为空
        styleData[k] = styleData[k] or {}
        if checkint(styleData[k].initial) ~= 2 then  -- 2 is MAGIC_FOOD_STYLE
            -- 排除掉魔法菜谱 求他的是可以制作的菜谱系列
            recipeStyleTable[tostring(k)] = true
        end
    end
    return recipeStyleTable
end


function CookingManager:getCookingGradeImg(gradeId)
    local path = _res('ui/home/kitchen/cooking_grade_ico_' .. gradeId .. '.png')
    if not utils.isExistent(path) then
        path = _res('ui/home/kitchen/cooking_grade_ico_1.png')
    end
    return path
end


--[[
根据recipeId 获取菜谱的属性值
--]]
function CookingManager:GetRecipeAttrDataByRecipeId(recipeId)
    local recipeAllData = CommonUtils.GetConfigAllMess('recipe', "cooking")
    local recipeOneData = recipeAllData[tostring(recipeId)]  or {}
    ---@type GameManager
    if recipeOneData then
        local cookingStyleId = recipeOneData.cookingStyleId
        local styleData = app.gameMgr:GetUserInfo().cookingStyles[tostring(cookingStyleId)]
        if styleData then
            for i, v in pairs(styleData) do
                if checkint(v.recipeId) == checkint(recipeId )  then
                    local recipeAttrData = v
                    return recipeAttrData or {}
                end
            end
        end
    end
    return {}
end


function CookingManager:SetRecipeAttrDataByData(data)
    local recipeId = data.recipeId
    if not  recipeId then
        return
    end
    local recipeAllData = CommonUtils.GetConfigAllMess('recipe', "cooking")
    local recipeOneData = recipeAllData[tostring(recipeId)]  or {}
    ---@type GameManager
    if recipeOneData then
        local cookingStyleId = recipeOneData.cookingStyleId
        local styleData =  app.gameMgr:GetUserInfo().cookingStyles[tostring(cookingStyleId)]
        if styleData then
            for i, v in pairs(styleData) do
                if checkint(v.recipeId) == checkint(recipeId )  then
                    table.merge(v, data)
                end
            end
        end
    end
end


--[[
判断选择的菜系 返回对应的菜谱
--]]
function CookingManager:GetStoryRecipeId(data)
    local styleData  = CommonUtils.GetConfigAllMess('style', 'cooking')
    local recipeData = CommonUtils.GetConfigAllMess('recipe', 'cooking')
    local targetData = {}

    for k, v in pairs(data) do
        local recipeOneData = recipeData[tostring(data[k])] or {}
        if recipeOneData then
            local cookingStyleId = recipeOneData.cookingStyleId
            if cookingStyleId then
                targetData[tostring(recipeOneData.cookingStyleId)] = v
            end
        end
    end
    local currentStyle = nil
    for k, v in pairs(app.gameMgr:GetUserInfo().cookingStyles) do
        local style = checkint(k)
        if style == RECIPE_STYLE.YIN_ZHI_DAO or
                style == RECIPE_STYLE.YAO_ZHI_ZHOU or
                style == RECIPE_STYLE.GE_RUI_LUO then
            -- 判断是否是研究的菜系
            local cookingNum   = table.nums(v)
            local styleOneData = styleData[tostring(style)] or {}
            local studyNum     = checkint(  styleOneData.studyRecipe)
            if cookingNum >= studyNum then

            else
                currentStyle = k
                for kk, vv in pairs(v ) do
                    -- 遍历当前的菜系 是否有和要求相同的菜系
                    if checkint(vv.recipeId) == checkint(targetData[tostring(k)]) then
                        return vv.recipeId
                    end
                end
            end
        end
    end
    for k, v in pairs(targetData) do
        if checkint(currentStyle) ~= checkint(k) then
            for kk, vv in pairs(app.gameMgr:GetUserInfo().cookingStyles[tostring(k)] or {}) do
                -- 如果最新菜系里面
                if checkint(vv.recipeId) == checkint(targetData[k]) then
                    return vv.recipeId
                end
            end
        end
    end
    return targetData[currentStyle]
end


--[[
根据recipeId 获取到foodId
--]]
function CookingManager:GetFoodIdByRecipeId(recipeId)
    recipeId   = recipeId or "220001"
    local type = CommonUtils.GetGoodTypeById(recipeId)
    if type == GoodsType.TYPE_RECIPE then
        local recipeData    = CommonUtils.GetConfigAllMess('recipe', 'cooking')
        local recipeOneData = recipeData[tostring(recipeId)]
        local foodData      = recipeOneData.foods or {}
        if table.nums(foodData) > 1 then
            local foodId = recipeOneData.foods[1].goodsId
            return foodId
        end
    else
        return recipeId
    end
end


--- 给菜谱排序
function CookingManager:SortRecipeByGradeThenOrder()
    local styleData = self:GetStyleTable()
    for k, v in pairs(app.gameMgr:GetUserInfo().cookingStyles) do
        if checkint(styleData[k].initial) ~= MAGIC_FOOD_STYLE then
            table.sort(v, function(a, b)
                local isFalse = false
                if a and b then
                    if app.gameMgr:GetUserInfo().recipeNewRed[tostring(a.recipeId)] and app.gameMgr:GetUserInfo().recipeNewRed[tostring(b.recipeId)] then
                        if checkint(a.recipeId) > checkint(b.recipeId) then
                            -- 然后按照菜品的recipeId 去排序
                            isFalse = true
                        else
                            isFalse = false
                        end
                    elseif app.gameMgr:GetUserInfo().recipeNewRed[tostring(a.recipeId)] then
                        isFalse = true
                    elseif app.gameMgr:GetUserInfo().recipeNewRed[tostring(b.recipeId)] then
                        isFalse = false
                    else
                        if checkint(a.gradeId) > checkint(b.gradeId) then
                            --先按照菜品的等级去排序
                            isFalse = true
                        elseif checkint(a.gradeId) == checkint(b.gradeId) then
                            if checkint(a.recipeId) > checkint(b.recipeId) then
                                -- 然后按照菜品的recipeId 去排序
                                isFalse = true
                            else
                                isFalse = false
                            end
                        else
                            return false
                        end
                    end
                    return isFalse
                end
            end)
        elseif checkint(styleData[k].initial) == MAGIC_FOOD_STYLE then
            table.sort(v, function(a, b)
                local isFalse = false
                if a and b then
                    if checkint(a.recipeId) > checkint(b.recipeId) then
                        isFalse = false
                    else
                        isFalse = true
                    end
                end
                return isFalse
            end)
        end
    end
end


--- 通过食物id 获取到菜谱的数据
function CookingManager:GetFoodIdByRecipeData(goodsId)
    if not goodsId then
        return {}
    end
    local foodData = CommonUtils.GetConfig('goods', 'goods', goodsId)
    if foodData.recipeId then
        local recipeConfigData    = CommonUtils.GetConfigAllMess('recipe', 'cooking')
        local recipeOneConfigData = recipeConfigData[tostring( foodData.recipeId)]
        local cookingStyleId      = recipeOneConfigData.cookingStyleId
        local styleData           = app.gameMgr:GetUserInfo().cookingStyles[tostring(cookingStyleId)]
        if styleData then
            local recipeOneData = {}
            for k, v in pairs(styleData) do
                if checkint(v.recipeId) == checkint(foodData.recipeId) then
                    recipeOneData = styleData[k] -- 获取玩家的菜谱的数据
                    break
                end
            end
            return recipeOneData
        end
    end
    return {}
end


--- 通过菜谱id 获取到菜谱的数据
function CookingManager:GetRecipeIdByRecipeData(recipeId)
    if not recipeId then
        return {}
    end
    local recipeId            = tostring(recipeId)
    local recipeConfigData    = CommonUtils.GetConfigAllMess('recipe', 'cooking')
    local recipeOneConfigData = recipeConfigData[tostring(recipeId)]
    local cookingStyleId      = recipeOneConfigData.cookingStyleId
    local styleData           = app.gameMgr:GetUserInfo().cookingStyles[tostring(cookingStyleId)]
    if styleData then
        local recipeOneData = {}
        for k, v in pairs(styleData) do
            if checkint(v.recipeId) == checkint(recipeId) then
                recipeOneData = styleData[k] -- 获取玩家的菜谱的数据
                break
            end
        end
        return recipeOneData
    end
    return {}
end


---根据菜谱 id 获取到额外的代的厨力点
function CookingManager:GetRecipeIdByRewardCookingNum(recipeId)
    if not recipeId then
        return 0
    end
    local recipeOneData       = self:GetRecipeIdByRecipeData(recipeId)
    local recipeId            = tostring(recipeOneData.recipeId)
    local recipeConfigData    = CommonUtils.GetConfigAllMess('recipe', 'cooking')
    local recipeOneConfigData = recipeConfigData[tostring(recipeId)]
    if recipeOneConfigData then
        local value = recipeOneConfigData.grade[tostring(recipeOneData.gradeId)].cookingPoint
        return checkint(value)
    end
    return 0
end


-- 根据菜品品质 获取菜品数量 state 1 未解锁菜系 2 未解锁菜谱 3 不满足菜谱等级 0 满足条件
function CookingManager:GetFoodNumByGrade(goodsId, grade)
    -- 解锁菜系 解锁菜谱 菜谱等级
    local unlockStyle, unlockRecipe, gradeId = self:GetFoodUnlockInfoByFoodId(goodsId)
    local num = 0
    local state = 0
    local unlockGrade = checkint(gradeId) >= checkint(grade)
    local isAppointLv = false -- 是否达到指定等级
    if not unlockStyle then
        state = 1
    elseif not unlockRecipe then
        state = 2
    elseif not unlockGrade then
        state = 3
    else
        isAppointLv = true
        num = CommonUtils.GetCacheProductNum(goodsId)
    end
    return num, isAppointLv, state
end


-- 获得单个菜价格
function CookingManager:GetPartyFoodPriceByFactor(goodsId, factor)
    local foodDatas = CommonUtils.GetConfigAllMess('food', 'goods')
    local foodData = foodDatas[tostring(goodsId)]
    local diamond = 0
    if foodDatas and foodData then
        local diamondValue = checkint(foodData.diamondValue)
        diamond = diamondValue * tonumber(factor)
    end
    return diamond
end


--- 菜谱某一个系列排序 首先是按照等级 然后才是按照Id
--- style 菜系的风格
--- isUseLike 是否使用喜欢排序
function CookingManager:SortRecipeKindsOfStyleByGradeThenOrder(style, isUseLike)
    if not style then
        return {}
    end
    style           = tostring(style)
    local styleData = self:GetStyleTable()
    local data      = app.gameMgr:GetUserInfo().cookingStyles[style] or {}
    if checkint(styleData[style].initial) ~= 2 then
        -- 是魔法菜谱
        table.sort(data, function(a, b)
            local isFalse = false
            if a and b then
                if app.gameMgr:GetUserInfo().recipeNewRed[tostring(a.recipeId)] and app.gameMgr:GetUserInfo().recipeNewRed[tostring(b.recipeId)] then
                    if checkint(a.recipeId) > checkint(b.recipeId) then
                        -- 然后按照菜品的recipeId 去排序
                        isFalse = true
                    else
                        isFalse = false
                    end
                elseif app.gameMgr:GetUserInfo().recipeNewRed[tostring(a.recipeId)] then
                    isFalse = true
                elseif app.gameMgr:GetUserInfo().recipeNewRed[tostring(b.recipeId)] then
                    isFalse = false
                else
                    if checkint(a.gradeId) > checkint(b.gradeId) then
                        --先按照菜品的等级去排序
                        isFalse = true
                    elseif checkint(a.gradeId) == checkint(b.gradeId) then
                        if checkint(a.recipeId) > checkint(b.recipeId) then
                            -- 然后按照菜品的recipeId 去排序
                            isFalse = true
                        else
                            isFalse = false
                        end
                    else
                        return false
                    end
                end

                return isFalse
            end
        end)
        -- like mode
        if isUseLike then
            local likeRecipeDataList = {}
            for i = #data, 1, -1 do
                local recipeData = data[i]
                if checkint(recipeData.like) > 0 then
                    local likeRecipeData = table.remove(data, i)
                    table.insert(likeRecipeDataList, likeRecipeData)
                end
            end
            for _, likeRecipeData in ipairs(likeRecipeDataList) do
                table.insert(data, 1, likeRecipeData)
            end
        end
    elseif checkint(styleData[style].initial) == 2 then
        -- 是魔法菜谱
        table.sort(data, function(a, b)
            local isFalse = false
            if a and b then
                if checkint(a.recipeId) > checkint(b.recipeId) then
                    isFalse = false
                else
                    isFalse = true
                end
            end
            return isFalse
        end)
    end
    return data
end


--[[
更新全部的菜系的结构
--]]
function CookingManager:UpdateRecipeAllStyle(data)
end


--- 接收菜谱研究的倒计时
function CookingManager:GetRecipeLeftSecodTime()
    local userInfo = app.gameMgr:GetUserInfo()
    return userInfo.clock[tostring(MODULE_DATA[tostring(RemindTag.RESEARCH)])] or -1
end
--- 设置热更新的数据
function CookingManager:SetRecipeLeftSecodTime(time)
    local userInfo = app.gameMgr:GetUserInfo()
    local time = CommonUtils.MakeSureNextRequestTime(time)
    userInfo.clock[tostring(MODULE_DATA[tostring(RemindTag.RESEARCH)])] = time
end
--- 更新菜谱接受的倒计时
function CookingManager:UpdateRecipeLeftSecondTime()
    local userInfo = app.gameMgr:GetUserInfo()
    if  userInfo.clock[tostring(MODULE_DATA[tostring(RemindTag.RESEARCH)])] > 0  then
        userInfo.clock[tostring(MODULE_DATA[tostring(RemindTag.RESEARCH)])] = userInfo.clock[tostring(MODULE_DATA[tostring(RemindTag.RESEARCH)])] -1
    end
end


-- 是否 未初始化菜系风格
function CookingManager:isUninitCookingStyle()
    local userInfo = app.gameMgr:GetUserInfo()
    -- local playerLevel   = checkint(self:GetUserInfo().level)
    local Num = 0
    local styleKindsTable = userInfo.cookingStyles or {}
    local styleDtata = self:GetStyleTable()
    for k, v in pairs(styleKindsTable) do
        styleDtata[k] = styleDtata[k] or {}
        if checkint(styleDtata[k].initial) == 1 then
            Num = Num + 1
        end
    end
    return Num == 0
end


--[[
初始化全部的数据
--]]
function CookingManager:InitialRecipeAllStyles()
    local userInfo = app.gameMgr:GetUserInfo()
    if userInfo.cookingStyles[ALL_RECIPE_STYLE] and table.nums(userInfo.cookingStyles[ALL_RECIPE_STYLE]) > 0  then
        return
    else
        userInfo.cookingStyles[ALL_RECIPE_STYLE] = {}
        if app.activityMgr:isOpenLobbyFestivalActivity() then
            userInfo.cookingStyles[FESTIVAL_RECIPE_STYLE] = {}
        end
    end

    for k , v in pairs(userInfo.cookingStyles) do
        if checkint(k) ~= 4 and  checkint(k) ~= checkint(ALL_RECIPE_STYLE) and checkint(k) ~= checkint(FESTIVAL_RECIPE_STYLE) then
            for kk , vv in pairs(v) do
                local count = table.nums(userInfo.cookingStyles[ALL_RECIPE_STYLE])
                userInfo.cookingStyles[ALL_RECIPE_STYLE][count+1] = vv
                local recipeId = tostring(vv.recipeId)
                if app.activityMgr:isOpenLobbyFestivalActivity() and app.activityMgr:checkIsFestivalRecipe(recipeId) then
                    table.insert(userInfo.cookingStyles[FESTIVAL_RECIPE_STYLE], vv)
                end
            end
        end
    end
end


--更新菜谱数据
function CookingManager:UpdateCookingStyleDataById(id)
    if not  id then -- 如果id 不存在 直接删除 容错
        return
    end
    local userInfo   = app.gameMgr:GetUserInfo()
    local recipeData = CommonUtils.GetConfigAllMess('recipe','cooking')[tostring(id) ]
    if recipeData then
        local cookingStyleId = recipeData.cookingStyleId
        if cookingStyleId then
            if userInfo.cookingStyles[tostring(cookingStyleId)] then
                for k ,v in pairs (userInfo.cookingStyles[tostring(cookingStyleId)]) do
                    if checkint(v.recipeId) == checkint(id) then -- 如果存在相同的菜谱 直接返回
                        return
                    end
                end
                local t = {}
                t.recipeId      = id
                t.taste         = 0
                t.museFeel      = 0
                t.fragrance     = 0
                t.exterior      = 0
                t.growthTotal   = 0
                t.gradeId       = 1
                t.seasoning     = ''
                t.cookingStyleId = cookingStyleId
                userInfo.cookingStyles[tostring(cookingStyleId)][#userInfo.cookingStyles[tostring(cookingStyleId)]+1] = t
                userInfo.cookingStyles[ALL_RECIPE_STYLE][#userInfo.cookingStyles[ALL_RECIPE_STYLE]+1] = t
                --
                if app.activityMgr:isOpenLobbyFestivalActivity() and app.activityMgr:getLobbyFestivalMenuData(id) ~= nil then
                    if not userInfo.cookingStyles[tostring(FESTIVAL_RECIPE_STYLE)] then
                        userInfo.cookingStyles[tostring(FESTIVAL_RECIPE_STYLE)] = {}
                    end
                    userInfo.cookingStyles[tostring(FESTIVAL_RECIPE_STYLE)][#userInfo.cookingStyles[tostring(FESTIVAL_RECIPE_STYLE)]+1] = t
                end
            else
                userInfo.cookingStyles[tostring(cookingStyleId)] = {}
                local t = {}
                t.recipeId      = id
                t.taste         = 0
                t.museFeel      = 0
                t.fragrance     = 0
                t.exterior      = 0
                t.growthTotal   = 0
                t.cookingStyleId= cookingStyleId
                t.gradeId       = 1
                t.seasoning     = ''
                userInfo.cookingStyles[tostring(cookingStyleId)][#userInfo.cookingStyles[tostring(cookingStyleId)]+1] = t
                userInfo.cookingStyles[ALL_RECIPE_STYLE][#userInfo.cookingStyles[ALL_RECIPE_STYLE]+1] = t
                if app.activityMgr:isOpenLobbyFestivalActivity() and app.activityMgr:getLobbyFestivalMenuData(id) ~= nil then
                    userInfo.cookingStyles[tostring(FESTIVAL_RECIPE_STYLE)][#userInfo.cookingStyles[tostring(FESTIVAL_RECIPE_STYLE)]+1] = t
                end
            end
        end

        -- 获得新的菜系的时候 红点添加
        app.badgeMgr:AddUpgradeRecipeLevelAndNewRed(id , cookingStyleId)
        app.badgeMgr:CheckClearResearchRecipeRed()
    end
end


--[[
根据菜品id判断是否解锁该菜系和菜谱
@params foodId int 菜品id
@return unlockStyle, unlockRecipe, gradeId bool, bool, int 解锁菜系 解锁菜谱 菜谱等级
--]]
function CookingManager:GetFoodUnlockInfoByFoodId(foodId)
    local unlockStyle = false
    local unlockRecipe = false
    local gradeId = 1
    local foodConfig = CommonUtils.GetConfig('goods', 'food', foodId)
    local userInfo   = app.gameMgr:GetUserInfo()
    if nil ~= foodConfig then
        local recipeId = checkint(foodConfig.recipeId)
        local recipeConfig = CommonUtils.GetConfigNoParser('cooking', 'recipe', recipeId)
        if nil ~= recipeConfig then
            unlockStyle = nil ~= userInfo.cookingStyles[tostring(recipeConfig.cookingStyleId)]
            if unlockStyle then
                for i,v in ipairs(userInfo.cookingStyles[tostring(recipeConfig.cookingStyleId)]) do
                    if recipeId == checkint(v.recipeId) then
                        unlockRecipe = true
                        gradeId = checkint(v.gradeId)
                        break
                    end
                end
            end
        end
    end
    return unlockStyle, unlockRecipe, gradeId
end


--[[
根据菜谱id获取菜谱信息
@params recipeId int 菜谱id
@return _ table 菜谱信息
--]]
function CookingManager:GetRecipeDataByRecipeId(recipeId)
    local userInfo     = app.gameMgr:GetUserInfo()
    local recipeConfig = CommonUtils.GetConfigNoParser('cooking', 'recipe', recipeId)
    if nil ~= recipeConfig then
        local cookingStyleId = checkint(recipeConfig.cookingStyleId)
        if nil ~= userInfo.cookingStyles[tostring(cookingStyleId)] then
            for _, recipeData_ in ipairs(userInfo.cookingStyles[tostring(cookingStyleId)]) do
                if checkint(recipeId) == checkint(recipeData_.recipeId) then
                    return recipeData_
                end
            end
            return nil
        else
            return nil
        end
    else
        return nil
    end
end


-------------------------------------------------
-- private method


return CookingManager
