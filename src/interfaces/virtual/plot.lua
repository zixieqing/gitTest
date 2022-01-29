--[[
 * author : kaishiqi
 * descpt : 关于 剧情数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


local plotConfs   = virtualData.getConf('quest', 'questPlot')
local branchConfs = virtualData.getConf('quest', 'branch')

-- 主线支线 列表
virtualData['plotTask/home'] = function(args)
    if not virtualData.plot_ then
        local initPlotId = 1
        local plotConf   = plotConfs[tostring(initPlotId)] or {}
        local data       = {
            newestPlotTaskId = initPlotId,
            branchTask       = {},
            plotTask         = {
                [tostring(plotConf.id)] = {
                    taskId   = plotConf.id,
                    status   = 1,  -- 1 未接受 2 未完成 3已完成
                    hasDrawn = 0,  -- 1:已领取 0:未领取
                    progress = 0,  -- 任务进度
                }
            }
        }
        for _, branchConf in pairs(branchConfs) do
            -- if checkint(branchConf.id) == 75 then
                local branchId = checkint(branchConf.id)
                data.branchTask[tostring(branchId)] = {
                    taskId   = branchId,
                    status   = 1,--_r(3),
                    hasDrawn = 0,--_r(0,1),
                    progress = _r(100),
                }
            -- end
        end
        virtualData.plot_ = data
    end
    return t2t(virtualData.plot_)
end


-- 接受主线任务
virtualData['plotTask/acceptPlotTask'] = function(args)
    local plotTaskData  = virtualData.plot_.plotTask[tostring(args.plotTaskId)]
    plotTaskData.status = 2 -- 完成状态 (1 未接受 2 未完成 3 已完成)

    virtualData.playerData.newestPlotTask = plotTaskData
    return t2t({})
end


-- 提交主线任务
virtualData['plotTask/submitPlotTask'] = function(args)
    return t2t({})
end


-- 领取主线任务
virtualData['plotTask/drawPlotReward'] = function(args)
    local plotTaskData = virtualData.plot_.plotTask[tostring(args.plotTaskId)]
    plotTaskData.status   = 3
    plotTaskData.hasDrawn = 1

    local currentPlotTaskId = virtualData.plot_.newestPlotTaskId
    local newestPlotTaskId  = currentPlotTaskId + 1
    virtualData.plot_.newestPlotTaskId = newestPlotTaskId
    virtualData.plot_.plotTask[tostring(newestPlotTaskId)] = {
        taskId   = newestPlotTaskId,
        status   = 1,  -- 1 未接受 2 未完成 3已完成
        hasDrawn = 0,  -- 1:已领取 0:未领取
        progress = 0,  -- 任务进度
    }

    virtualData.playerData.mainExp = virtualData.playerData.mainExp + 5
    local currentPlotConf = plotConfs[tostring(currentPlotTaskId)] or {}
    local data = {
        rewards          = currentPlotConf.rewards,
        mainExp          = virtualData.playerData.mainExp,
        newestPlotTaskId = newestPlotTaskId,
        newestPlotTask   = virtualData.plot_.plotTask[tostring(newestPlotTaskId)],
    }
    return t2t(data)
end


-- 接受支线任务
virtualData['branch/acceptBranchTask'] = function(args)
    local data = {
        status = 1,
    }
    return t2t({})
end
