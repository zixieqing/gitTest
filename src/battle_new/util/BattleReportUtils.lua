--[[
战斗报告工具
--]]
BattleReportUtils = {}

local CONTENT_SEPARATOR = '|||'  -- 战报内容分隔符
local TAG_ARRAY_SEPARATOR = '&'
local TAG_VALUE_SEPARATOR = '='
local FIGHT_ARRAY_SEPARATOR = ';'
local FIGHT_VALUE_SEPARATOR = '#'
local SKILL_ARRAY_SEPARATOR = ';'
local SKILL_VALUE_SEPARATOR = '#'
local OBJP_ARRAY_SEPARATOR  = ';'
local OBJP_VALUE_SEPARATOR  = ','

--[[
/**
 * 1 attackType: 1:普攻 2:普攻暴击 3:施放卡牌技能 4:卡牌技能效果结束
 * 2 defenderId为空表示全体
 * 3 如果attackerId=defenderId，表示给自己放技能
 * 4 hp是增加/扣掉的血量，正数表示增加，负数表示扣掉
 * 5 放主角技的时候，attackerId为0
 *
 *
 * fightNo=cardId&fightNo=monsterId|||attackerId#defenderId,defenderId#actionType#skillId#attackerHp#defenderHp,defenderHp;...
 */
--]]

--[[
    生成战报
    @param battleDataObj : controller.BattleData
    @return reportStr : str
]]
function BattleReportUtils.encodeReport(battleDataObj)
    return 'TODO'
end


--[[
    解析战报
    @param reportStr : str
    @return report : table
]]
function BattleReportUtils.decodeReport(reportStr)
    local report = {
        tagMap = {},
        fights = {},
        skills = {},
        object = {},
    }

    if reportStr and reportStr ~= '' then
        local contentStrArray = string.split2(reportStr, CONTENT_SEPARATOR)

        -- parse tagInfo
        local tagStrArray = string.split2(contentStrArray[1], TAG_ARRAY_SEPARATOR)
        for _, tagStr in ipairs(tagStrArray) do
            local tagInfo = string.split2(tagStr, TAG_VALUE_SEPARATOR)
            local tagId   = tagInfo[1]
            local cardId  = tagInfo[2]
            report.tagMap[tagId] = cardId
        end

        -- parse fightStr
        local fightStrArray = string.split2(contentStrArray[2], FIGHT_ARRAY_SEPARATOR)
        for fightIdx, fightStr in ipairs(fightStrArray) do
            local fightInfo = string.split2(fightStr, FIGHT_VALUE_SEPARATOR)
            if #fightInfo > 0 then
                -- report.fights[fightIdx] = require('cocos.framework.json').encode({
                --     attackerTag    = fightInfo[1],
                --     defenderTag    = fightInfo[2],
                --     actionType     = fightInfo[3],  -- @see BDDamageType
                --     skillId        = fightInfo[4],
                --     attackerHp     = fightInfo[5],
                --     defenderHp     = fightInfo[6],
                --     frameIndex     = fightInfo[7],
                --     attackerEnergy = fightInfo[8],
                -- })
                local attackerTag    = checkint(fightInfo[1])
                local defenderTag    = checkint(fightInfo[2])
                local actionType     = checkint(fightInfo[3])
                local skillId        = checkint(fightInfo[4])
                local attackerHp     = checknumber(fightInfo[5])
                local defenderHp     = checknumber(fightInfo[6])
                local frameIndex     = checknumber(fightInfo[7])
                local attackerEnergy = checknumber(fightInfo[8])
                if fightInfo[8] == nil then
                    frameIndex     = checknumber(fightInfo[6])
                    defenderHp     = checknumber(fightInfo[7])
                    attackerEnergy = nil
                end

                local typeString = ''
                if actionType == 1 then
                    typeString = '------->'
                elseif actionType == 2 then
                    typeString = '>>>>>>>>'
                elseif actionType == 3 then
                    typeString = string.format('-%04d->', skillId)
                elseif actionType == 4 then  -- ?? 还没遇到
                    typeString = string.format('<-%04d-', skillId)
                else
                    typeString = '????????'
                end
                if attackerEnergy then
                    report.fights[fightIdx] = string.format('%5d) [%4d] %s [%4d] (%+0.2f) <%0.2f,%0.2f>', frameIndex, attackerTag, typeString, defenderTag, defenderHp, attackerHp, attackerEnergy)
                else
                    report.fights[fightIdx] = string.format('%5d) [%4d] %s [%4d] (%+0.2f) <%0.2f,--.-->', frameIndex, attackerTag, typeString, defenderTag, defenderHp, attackerHp)
                end
            end
        end

        -- parse aliveFriendObjPStr
        for contentIndex = 3, #contentStrArray - 1, #contentStrArray - 1 - 3 do
            local objStrArray = string.split2(contentStrArray[contentIndex], OBJP_ARRAY_SEPARATOR)
            local tagArrtMap  = {}
            for objIdx, objStr in ipairs(objStrArray) do
                local objInfo = string.split2(objStr, OBJP_VALUE_SEPARATOR)
                if #objInfo > 0 then
                    local tagId = objInfo[1] -- @see ObjP
                    tagArrtMap[tagId] = require('cocos.framework.json').encode({
                        ATK    = objInfo[2],  -- 攻击力
                        DEF    = objInfo[3],  -- 防御力
                        HP     = objInfo[4],  -- 血量
                        ATK_R  = objInfo[5],  -- 攻击速度
                        CRIT_R = objInfo[6],  -- 暴击率
                        CRIT_D = objInfo[7],  -- 暴击伤害
                    })
                end
            end
            if next(tagArrtMap) ~= nil then
                table.insert(report.object, tagArrtMap)
            end
        end

        -- parse skillInfo
        local skillStrArray = string.split2(contentStrArray[#contentStrArray], SKILL_ARRAY_SEPARATOR)
        for _, skillStr in ipairs(skillStrArray) do
            local skillInfo = string.split2(skillStr, SKILL_VALUE_SEPARATOR)
            if #skillInfo > 0 then
                local tagId = skillInfo[1]
                report.skills[tagId] = report.skills[tagId] or {}

                for skillIdx = 2, #skillInfo, 2 do
                    local skillId    = skillInfo[skillIdx]
                    local skillCount = skillInfo[skillIdx+1]
                    report.skills[tagId][skillId] = skillCount
                end
            end
        end
    end
    
    return report
end
