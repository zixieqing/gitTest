--[[
 * author : kaishiqi
 * descpt : 关于 餐厅数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

-- 菜谱开发首页
virtualData['Cooking/home'] = function(args)
    local data = {
        cookingStyles = {}  -- 烹饪专精
    }
    return t2t(data)
end


-- 烹饪专精解锁
virtualData['Cooking/cookingStyleUnlock'] = function(args)
    local cookingRecipeMap   = {}
    local cookingRecipeConfs = virtualData.getConf('cooking', 'recipe')
    for k, recipeConf in pairs(cookingRecipeConfs) do
        local cookingStyleId = checkint(recipeConf.cookingStyleId)
        cookingRecipeMap[tostring(cookingStyleId)] = cookingRecipeMap[tostring(cookingStyleId)] or {}
        table.insert(cookingRecipeMap[tostring(cookingStyleId)], recipeConf)
    end
    
    local cookingStyleId       = checkint(args.cookingStyleId)
    local cookingRecipeList    = cookingRecipeMap[tostring(cookingStyleId)] or {}
    local playerCookingRecipes = {}
    virtualData.playerData.cookingStyles[tostring(cookingStyleId)] = playerCookingRecipes
    for j=1,3 do
        local cookingRecipeConf = table.remove(cookingRecipeList, _r(#cookingRecipeList))
        if cookingRecipeConf then
            local playerRecipeData = {
                recipeId       = checkint(cookingRecipeConf.id),             -- 菜谱id
                cookingStyleId = checkint(cookingRecipeConf.cookingStyleId), -- 菜谱风格
                taste          = _r(checkint(cookingRecipeConf.taste)),      -- 口味
                museFeel       = _r(checkint(cookingRecipeConf.museFeel)),   -- 口感
                fragrance      = _r(checkint(cookingRecipeConf.fragrance)),  -- 香味
                exterior       = _r(checkint(cookingRecipeConf.exterior)),   -- 外观
                growthTotal    = 0,                                          -- 成长总值
                gradeId        = 1,                                          -- 成长评级id
                seasoning      = '',                                         -- 用过的调料，逗号分隔
            }
            table.insert(playerCookingRecipes, playerRecipeData)
        end
    end

    local data = {
        recipes = playerCookingRecipes
    }
    return t2t(data)
end


-- 菜谱制作
virtualData['Cooking/recipeMaking'] = function(args)
    local makingRecipeid     = checkint(args.recipeId)
    local cookingRecipeConfs = virtualData.getConf('cooking', 'recipe')
    local cookingRecipeConf  = cookingRecipeConfs[tostring(makingRecipeid)] or {}
    local recipeFoodData     = checktable(cookingRecipeConf.foods)[1] or {}

    local cookingStyleId   = checkint(cookingRecipeConf.cookingStyleId)
    local cookingStyleList = virtualData.playerData.cookingStyles[tostring(cookingStyleId)] or {}
    local playerRecipeData = {}
    for i, recipeData in ipairs(cookingStyleList) do
        if checkint(recipeData.recipeId) == makingRecipeid then
            playerRecipeData = recipeData
            break 
        end
    end

    local attrAddition = {
        taste     = {assistant = 0, seasoning = 0, base = _r(100)}, -- 口味
        museFeel  = {assistant = 0, seasoning = 0, base = _r(100)}, -- 口感
        fragrance = {assistant = 0, seasoning = 0, base = _r(100)}, -- 香味
        exterior  = {assistant = 0, seasoning = 0, base = _r(100)}, -- 外观
    }
    playerRecipeData.taste     = playerRecipeData.taste     + attrAddition.taste.base
    playerRecipeData.museFeel  = playerRecipeData.museFeel  + attrAddition.museFeel.base
    playerRecipeData.fragrance = playerRecipeData.fragrance + attrAddition.fragrance.base
    playerRecipeData.exterior  = playerRecipeData.exterior  + attrAddition.exterior.base

    virtualData.playerData.mainExp = virtualData.playerData.mainExp + 1
    local data = {
        rewards      = { {goodsId = recipeFoodData.goodsId, num = 1, type = 15} },
        mainExp      = virtualData.playerData.mainExp,
        attrAddition = attrAddition,
        attrFinal    = {
            taste     = playerRecipeData.taste,
            museFeel  = playerRecipeData.museFeel,
            fragrance = playerRecipeData.fragrance,
            exterior  = playerRecipeData.exterior,
        },
    }
    return t2t(data)
end


-- 菜谱升级
virtualData['Cooking/recipeGradeLevelUp'] = function(args)
    return t2t({})
end


-- 菜谱研发
virtualData['Cooking/recipeStudy'] = function(args)
    local data = {
        leftSeconds = _r(99)
    }
    return t2t(data)
end


-- 菜谱研发立刻完成
virtualData['Cooking/accelerateRecipeStudy'] = function(args)
    local data = {
        diamond = virtualData.playerData.diamond
    }
    return t2t(data)
end


-- 菜谱研发领取奖励
virtualData['Cooking/drawRecipeStudy'] = function(args)
    virtualData.playerData.mainExp = virtualData.playerData.mainExp + 1

    local cookingRecipeMap   = {} -- [styleid] = {......}
    local cookingRecipeConfs = virtualData.getConf('cooking', 'recipe')
    for k, recipeConf in pairs(cookingRecipeConfs) do
        local cookingStyleId = checkint(recipeConf.cookingStyleId)
        cookingRecipeMap[tostring(cookingStyleId)] = cookingRecipeMap[tostring(cookingStyleId)] or {}
        table.insert(cookingRecipeMap[tostring(cookingStyleId)], recipeConf)
    end
    
    local cookingRecipeConfList = cookingRecipeMap[tostring(args.cookingStyleId)]
    local cookingRecipeConf = cookingRecipeConfList[_r(#cookingRecipeConfList)]
    local data = {
        rewards   = virtualData.createGoodsList(_r(2,4)),
        mainExp   = virtualData.playerData.mainExp,
        recipeId  = cookingRecipeConf.id,
        taste     = {assistant = 0, seasoning = 0, base = _r(100)}, -- 口味
        museFeel  = {assistant = 0, seasoning = 0, base = _r(100)}, -- 口感
        fragrance = {assistant = 0, seasoning = 0, base = _r(100)}, -- 香味
        exterior  = {assistant = 0, seasoning = 0, base = _r(100)}, -- 外观
    }
    return t2t(data)
end


-- 菜谱标记 喜欢/不喜欢
virtualData['Cooking/recipeLike'] = function(args)
    local recipeIdList = string.split2(checkstr(args.recipeIds), ',')
    if #recipeIdList > 0 then
        -- flip like/unlike
        for _, recipeId in ipairs(recipeIdList) do
            for cookingStyleId, cookingStyleList in pairs(virtualData.playerData.cookingStyles) do
                for _, recipeData in ipairs(cookingStyleList) do
                    if checkint(recipeData.recipeId) == checkint(recipeId) then
                        recipeData.like = checkint(recipeData.like) == 1 and 0 or 1
                        break
                    end
                end
            end
        end

    else
        -- unlike all
        for cookingStyleId, cookingStyleList in pairs(virtualData.playerData.cookingStyles) do
            for _, recipeData in ipairs(cookingStyleList) do
                recipeData.like = 0
            end
        end
    end
    return t2t({})
end