--[[
 * author : kaishiqi
 * descpt : 关于 组队副本数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


local TEAM_HOST = '127.0.0.1'  -- 组队战地址
local TEAM_PORT = 3456         -- 组队战端口

-- require teamType conf
local teamTypeConf = table.values(virtualData.getConf('quest', 'teamType'))
sortByMember(teamTypeConf, "id", true)

-- require teamBoss conf
local teamBossConf = table.values(virtualData.getConf('quest', 'teamBoss'))
sortByMember(teamBossConf, "id", true)

-- init questTeam data
virtualData.questTeamData_ = {}


-- 组队boss主页
virtualData['QuestTeam/home'] = function(args)
    if not virtualData.questTeamData_.teamBosses then
        local teamBosses = {}
        for _,v in ipairs(teamTypeConf) do
            table.insert(teamBosses, {
                teamTypeId      = checkint(v.id),        -- Boss编号
                leftAttendTimes = _r(5),                 -- 剩余参加次数
                leftBuyTimes    = checkint(v.freeTimes), -- 剩余购买次数
            })
        end
        virtualData.questTeamData_.teamBosses = teamBosses
    end

    local data = { 
        teamBosses = virtualData.questTeamData_.teamBosses
    }
    return t2t(virtualData.questTeamData_.teamBosses)
end


-- 组队BOSS购买次数
virtualData['QuestTeam/buyAttendTimes'] = function(args)
    local hasTeamType = false
    for _,v in ipairs(virtualData.questTeamData_.teamBosses) do
        if checkint(v.teamTypeId) == checkint(args.teamTypeId) then
            v.leftAttendTimes = v.leftAttendTimes + 1
            v.leftBuyTimes    = v.leftBuyTimes - 1
            hasTeamType       = true
            break
        end
    end

    if hasTeamType then
        return t2t({})
    else
        return t2t({}, 1, '参数 teamTypeId 错误')
    end
end


-- 创建组队BOSS
virtualData['QuestTeam/create'] = function(args)
    local data = {
        questTeamId = _r(999),    -- 队伍编号
        ip          = TEAM_HOST,  -- 房间长连接IP
        port        = TEAM_PORT,  -- 房间长连接Port
    }
    virtualData.questTeamData_.questTeam = {
        questTeamId = data.questTeamId,
        teamTypeId  = args.teamTypeId,
        teamBossId  = args.teamBossId,
        password    = args.password,
    }
    return t2t(data)
end


-- 组队BOSS自动匹配
virtualData['QuestTeam/autoMatching'] = function(args)
    local data = {
        id   = _r(999),    -- 队伍编号
        ip   = TEAM_HOST,  -- 房间长连接IP
        port = TEAM_PORT,  -- 房间长连接Port
    }
    virtualData.questTeamData_.questTeam = {
        questTeamId = data.id,
        teamTypeId  = args.teamTypeId,
        teamBossId  = args.teamBossId,
    }
    return t2t(data)
end


-- 搜索组队BOSS
virtualData['QuestTeam/search'] = function(args)
    local data = { questTeams = {} }

    local createRBossId = function()
        local bossId = 0

        -- 1:组队BOSS
        if args.teamTypeId == 1 then
            local bossIdList = table.keys(virtualData.getConf('quest', 'teamBoss'))
            bossId = bossIdList[_r(1, #bossIdList)]
        end

        return bossId
    end

    local createName = virtualData.createName
    local createReault = function(aId)
        local maxNum = _r(1,5)
        return {
            id          = aId or _r(999),                     -- 队伍编号
            name        = createName(_r(10,20)),              -- 队伍名称
            teamBossId  = args.teamBossId or createRBossId(), -- BOSS编号
            attendNum   = _r(1, maxNum),                      -- 参与人数
            maxNum      = maxNum,                             -- 参与人数上限
            status      = _r(1,4),                            -- 3/4:正在战斗
            ip          = TEAM_HOST,                          -- 房间长连接IP
            port        = TEAM_PORT,                          -- 房间长连接Port
            hasPassword = _r(0,1),                            -- 1 有密码 0 无密码
            createTime  = 0,                                  -- 创建时间
        }
    end

    if args.keyword and string.len(args.keyword) > 0 then
        if _r(100) > 50 then
            table.insert(data.questTeams, createReault(args.keyword))
        end
    else
        for i = 1, _r(20,60) do
            table.insert(data.questTeams, createReault())
        end
    end
    return t2t(data)
end

