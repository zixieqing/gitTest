--[[
 * author : kaishiqi
 * descpt : 关于 宠物数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 宠物首页
virtualData['pet/home'] = function(args)
    local data = {
        freeTime = _r(9),
        petPonds = {}
    }
    for i=1,1 do
        data.petPonds[tostring(i)] = {
            poindId    = i,   -- 净化池Id
            nutrition  = 0,   -- 营养值
            cdTime     = 0,   -- 净化cd时间（时间段）
            petEggId   = nil, -- 灵体Id
            magicFoods = nil, -- 魔法菜品（逗号格式分隔）
        }
    end
    return t2t(data)
end


-- 进入净化
virtualData['pet/petEggIntoPond'] = function(args)
    local data = {
        cdTime = 10 + _r(99)
    }
    return t2t(data)
end


-- 加速净化
virtualData['pet/acceleratePetClean'] = function(args)
    local data = {
        diamond = virtualData.playerData.diamond
    }
    return t2t(data)
end


-- 净化领取
virtualData['pet/petClean'] = function(args)
    local petConfs  = virtualData.getConf('goods', 'pet')
    local petIdList = table.keys(petConfs)
    local petId     = checkint(petIdList[_r(#petIdList)])
    local petData   = virtualData.createPetData(petId)
    
    local data = {
        newPet = petData
    }
    return t2t(data)
end


-- 宠物升级
virtualData['pet/petLevelUp'] = function(args)
    local data = {
        level = 2,
        exp   = _r(99),
    }
    return t2t(data)
end


-- 宠物升级
virtualData['pet/petBreakUp'] = function(args)
    local data = {
        isBreak    = 1,
        breakLevel = 2,
    }
    return t2t(data)
end


-- 装备/卸载 宠物
virtualData['pet/mountPet'] = function(args)
    -- TODO
    local data = {
    }
    return t2t(data)
end


-- 灵体觉醒
virtualData['pet/petAwaken'] = function(args)
    local data = {
        isRouse = 0,
        newPet  = {}
    }
    return t2t(data)
end