--[[
debug用战斗构造器
--]]
local BattleConstructorEx = require('battleEntry.BattleConstructorEx')

------------ import ------------
require('battleEntry.BattleGlobalDefines')
-- 战斗字符串工具
__Require('battle.util.BStringUtils')
------------ import ------------

------------ define ------------
------------ define ------------

local BattleConstructorDebug = class('BattleConstructorDebug', BattleConstructorEx)

--[[
constructor
--]]
function BattleConstructorDebug:ctor( ... )
	BattleConstructorEx.ctor(self, ...)
end


---------------------------------------------------
-- debug calc begin --
---------------------------------------------------

--[[
客户端发起的一次战斗脚本计算
@param      @see BattleConstructorEx.InitByCommonData
@return     @see BattleChecker.CalcOneBattle
--]]
function BattleConstructorDebug:DebugOneCalculator(
        stageId, questBattleType, settlementType,
        formattedFriendTeamData, formattedEnemyTeamData,
        friendEquipedSkills, friendAllSkills, enemyEquipedSkills, enemyAllSkills,
        skills, abilityData,
        buyRevivalTime, buyRevivalTimeMax, isOpenRevival,
        randomseed, isReplay,
        serverCommand, fromtoData
    )

    local calcParams = self:PreInitCheckerData(stageId, questBattleType, settlementType, formattedFriendTeamData, formattedEnemyTeamData, friendEquipedSkills, friendAllSkills, enemyEquipedSkills, enemyAllSkills, skills, abilityData, buyRevivalTime, buyRevivalTimeMax, isOpenRevival, randomseed, isReplay, serverCommand, fromtoData)

    -- 计算战斗
	require('battleEntryServer.BattleEntry')
	local calcResult = json.decode(
        G_BattleChecker:CalcOneBattle(
            nil,
            calcParams.constructorJson,
            calcParams.friendTeamJson, calcParams.enemyTeamJson,
            calcParams.loadedResourcesJson
        )
    )
    
    -- 去除字符串中的转义
    calcResult.operateStr = string.gsub(calcResult.operateStr, '\\', '')

    dump(calcResult)
    
    return calcResult
end

--[[
初始化构造器 返回自动计算战斗需要的数据
@param @see BattleConstructorEx.InitByCommonData
@return calcEntryData table {
    constructorJson T2S 构造器数据
    friendTeamJson json 友方阵容json
    enemyTeamJson json 敌方阵容json
    loadedResourcesJson T2S 加载的资源表(合并后的值)
}
--]]
function BattleConstructorDebug:PreInitCheckerData(
        stageId, questBattleType, settlementType,
        formattedFriendTeamData, formattedEnemyTeamData,
        friendEquipedSkills, friendAllSkills, enemyEquipedSkills, enemyAllSkills,
        skills, abilityData,
        buyRevivalTime, buyRevivalTimeMax, isOpenRevival,
        randomseed, isReplay,
        serverCommand, fromtoData
    )

    BattleConstructorEx.InitByCommonData(self, 
        stageId, questBattleType, settlementType,
        formattedFriendTeamData, formattedEnemyTeamData,
        friendEquipedSkills, friendAllSkills, enemyEquipedSkills, enemyAllSkills,
        skills, abilityData,
        buyRevivalTime, buyRevivalTimeMax, isOpenRevival,
        randomseed, isReplay,
        serverCommand, fromtoData
    )

    local params = self:ConvertCalculatorParams()

    dump(params)

    return params
end

--[[
根据初始化后的构造器数据获取自动计算脚本需要的传参
@return result table {
    constructorJson T2S 构造器数据
    friendTeamJson json 友方阵容json
    enemyTeamJson json 敌方阵容json
    loadedResourcesJson T2S 加载的资源表(合并后的值)
}
--]]
function BattleConstructorDebug:ConvertCalculatorParams()
    local result = {}
    ------------ 构造器数据 T2S ------------
    local constructorJson = self:CalcRecordConstructData()
    ------------ 构造器数据 T2S ------------

    ------------ 队伍数据 json ------------
    local friendTeamJson = json.encode(
        self:GetTeamsData(false)
    )

    local enemyTeamJson = json.encode(
        self:GetTeamsData(true)
    )
    ------------ 队伍数据 json ------------

    ------------ 资源数据 T2S ------------
    local friendLoadResJson = self:CalcLoadSpineRes(false, true)
    local enemyLoadResJson = self:CalcLoadSpineRes(true, false)

    local maxTeamAmount = math.max(table.nums(friendLoadResJson), table.nums(enemyLoadResJson))
    local friendOneTeamResStr = nil
    local enemyOneTeamResStr = nil
    local loadedResourcesJson = {}

    for teamIndex = 1, maxTeamAmount do
        
        friendOneTeamResStr = friendLoadResJson[tostring(teamIndex)]
        enemyOneTeamResStr = enemyLoadResJson[tostring(teamIndex)]

        local loadedOneTeamResources = {}
        
        -- 友方数据
        if nil ~= friendOneTeamResStr then
            local friendOneTeamRes = String2TableNoMeta(friendOneTeamResStr)
            if next(friendOneTeamRes) then
                
                for aniCacheName, val in pairs(friendOneTeamRes) do
                    if true == val then
                        loadedOneTeamResources[aniCacheName] = val
                    end
                end
                
            end
        end

        -- 敌方数据
        if nil ~= enemyOneTeamResStr then
            local enemyOneTeamRes = String2TableNoMeta(enemyOneTeamResStr)
            if next(enemyOneTeamRes) then
                
                for aniCacheName, val in pairs(enemyOneTeamRes) do
                    if true == val then
                        loadedOneTeamResources[aniCacheName] = val
                    end
                end
                
            end
        end

        loadedResourcesJson[checkint(teamIndex)] = loadedOneTeamResources

    end
    ------------ 资源数据 T2S ------------

    result.constructorJson = constructorJson
    result.friendTeamJson = friendTeamJson
    result.enemyTeamJson = enemyTeamJson
    result.loadedResourcesJson = Table2StringNoMeta(loadedResourcesJson)

    return result
end

---------------------------------------------------
-- debug calc end --
---------------------------------------------------









return BattleConstructorDebug