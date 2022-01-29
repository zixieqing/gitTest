--[[
 * author : kaishiqi
 * descpt : 关于 活动数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 活动首页
virtualData['Activity/home'] = function(args)
    if not virtualData.activityHome_ then
        virtualData.activityHome_ = {}
        for _, activityType in pairs(ACTIVITY_TYPE) do
            -- 复数type为本地常驻活动
            if checkint(activityType) > 0 then
                local activityData = {
                    activityId      = virtualData.generateUuid(),
                    type            = tostring(activityType),
                    leftSeconds     = _r(9999),
                    fromTime        = os.time() - virtualData.createSecond('d:30:?,h:24:?'),
                    toTime          = os.time() + virtualData.createSecond('d:30:?,h:24:?'),
                    title           = {
                        [i18n.getLang()] = virtualData.createName(_r(8,16))
                    },
                    rule           = {
                        [i18n.getLang()] = virtualData.createName(_r(20,80))
                    },
                    detail          = {
                        [i18n.getLang()] = virtualData.createName(_r(20,120))
                    },
                    image           = {
                        [i18n.getLang()] = 'http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/f236291a3a155643c436b0580de8e83a.jpg'
                    },
                    backgroundImage = {
                        [i18n.getLang()] = 'http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/8b0e2ad654489104ea06c98f79d5af1f.jpg'
                    },
                    sidebarImage = {
                        [i18n.getLang()] = 'http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/c3af246c26e2e8965ed0be8ac276c879.jpg'
                    }
                }
                table.insert(virtualData.activityHome_, activityData)
            end
        end
    end

    local data = {
        activity = virtualData.activityHome_
    }
    return t2t(data)
end


-- 主界面活动icon
virtualData['Activity/homeIcon'] = function(args)
    if not virtualData.activityHome_ then
        virtualData['Activity/home']()
    end

    local openMap = {
        [ACTIVITY_TYPE.SEASONG_LIVE] = {icon = 'main_btn_ac_spring',  iconTitle = {[i18n.getLang()] = '季活'}},
        [ACTIVITY_TYPE.CV_SHARE]     = {icon = 'main_btn_ac_cvshare', iconTitle = {[i18n.getLang()] = 'CV分享'}},
    }
    local data = {
        activity = {}
    }
    for _, activityData in ipairs(virtualData.activityHome_) do
        local homeIconData = openMap[tostring(activityData.type)]
        if homeIconData then
            table.insert(data.activity, {
                type        = activityData.type,
                activityId  = activityData.activityId,
                leftSeconds = activityData.leftSeconds,
                iconTitle   = homeIconData.iconTitle,
                icon        = homeIconData.icon,
            })
        end
    end
    return t2t(data)
end


-- 等级礼包
virtualData['Activity/levelChest'] = function(args)
    local data = {}
    return t2t(data)
end


-------------------------------------------------
-- 领取首冲奖励
virtualData['Activity/drawFirstPay'] = function(args)
    local data = {
        rewards = virtualData.createGoodsList(_r(2,5))
    }
    return t2t(data)
end


-------------------------------------------------
-- 领取安心便当
virtualData['Activity/receiveLoveBento'] = function(args)
    local data = {
        hp = virtualData.playerData.hp
    }
    return t2t(data)
end


-------------------------------------------------
-- 永久累充
virtualData['Activity/persistencePayRewards'] = function(args)
    if not virtualData.persistencePay_ then
        virtualData.persistencePay_ = {
            moneyPoints      = _r(99),
            accumulativeList = {},
        }
        for i = 1, 5 do
            virtualData.persistencePay_.accumulativeList[i] = {
                id          = i,
                moneyPoints = _r(99),
                hasDrawn    = _r(0,1),
                baseRewards = virtualData.createGoodsList(_r(2,4)),
                rewards     = virtualData.createGoodsList(_r(2,4)),
            }
        end
    end
    return t2t(virtualData.persistencePay_)
end
virtualData['Activity/drawPersistencePayReward'] = function(args)
    local accumulativeData = virtualData.persistencePay_.accumulativeList[args.accumulativeId] or {}
    local data = {
        rewards = accumulativeData.rewards
    }
    return t2t(data)
end


-------------------------------------------------
-- 3v3竞赛场
virtualData['Activity/kofArena'] = function(args)
    return virtualData['kofArena/_activity_']()
end


-------------------------------------------------
-- 新手活动首页
virtualData['Activity/newbieTask'] = function(args)
    if not virtualData.newbieTask_ then
        local cardConfs  = virtualData.getConf('card', 'card')
        local cardIdList = table.keys(cardConfs)
        local data = {
            newbieTasks                = {},
            endLeftSeconds             = virtualData.createSecond('s:60:?'),
            newbieTasksDoneReward      = {
                { goodsId = cardIdList[_r(#cardIdList)], num = 1, type = 20 }
            },
            newbieTasksDoneRewardDrawn = 0,
        }

        local days = 7
        for i = 1, days do
            local newbieTasks = {}
            for j = 1,9 do
                local index = days * (i-1) + j
                local taskData = {
                    id          = index,                                -- 活动任务ID
                    name        = virtualData.createName(_r(6,12)),     -- 活动任务名称
                    descr       = virtualData.createName(_r(12,24)),    -- 活动任务描述
                    rewards     = virtualData.createGoodsList(_r(2,4)), -- 活动任务奖励
                    openDay     = j,                                    -- 活动任务开放时间
                    mainExp     = _r(0,3)*10,                           -- 活动任务奖励主角经验
                    activePoint = _r(10),                               -- 活动任务活跃度
                    taskType    = index - 1,                            -- 活动任务类型
                    targetNum   = _r(9),                                -- 活动任务目标数量
                    hasDrawn    = _r(0,1),                              -- 活动任务领取状态
                    progress    = _r(10),                               -- 活动任务进度
                }
                table.insert(newbieTasks, taskData)
            end
            data.newbieTasks[tostring(i)] = newbieTasks
        end
        virtualData.newbieTask_ = data
    end
    return t2t(virtualData.newbieTask_)
end
-- 新手活动领取所有奖励
virtualData['Activity/drawNewbieTask'] = function(args)
    local data = {
        rewards = virtualData.newbieTask_.newbieTasksDoneReward
    }
    return t2t(data)
end
-- 新手活动领取所有奖励
virtualData['Activity/drawNewbieTaskBaseReward'] = function(args)
    local data = {
        mainExp = 0,
        rewards = {}
    }
    local isFindTask = false
    local drawTaskId = checkint(args.taskId)
    for _, newbieTasks in pairs(virtualData.newbieTask_.newbieTasks) do
        for i, taskData in ipairs(newbieTasks) do
            if taskData.id == drawTaskId then
                data.rewards = taskData.rewards
                isFindTask   = true
                break
            end
        end
        if isFindTask then
            break
        end
    end
    return t2t(data)
end


-------------------------------------------------
-- 签到首页
virtualData['Activity/monthlyLoginReward'] = function(args)
    if not virtualData.monthlyLoginReward_ then
        local cardConfs  = virtualData.getConf('card', 'card')
        local cardIdList = table.keys(cardConfs)
        local data = {
            today_        = _r(30),
            content       = {},
            activity      = {},
            starCardId    = cardIdList[_r(#cardIdList)],
            hasTodayDrawn = 0,  -- 今天是否已领取
        }
        for i=1,30 do
            local contentData = {
                day       = i,
                rewards   = virtualData.createGoodsList(1),
                highlight = _r(0,1),                        -- 是否高亮.0:否 1:是
                hasDrawn  = i < data.today_ and 1 or 0,     -- 是否领取.0:否 1:是
            }
            table.insert(data.content, contentData)
        end
        virtualData.monthlyLoginReward_ = data
    end
    return t2t(virtualData.monthlyLoginReward_)
end
-- 领取签到
virtualData['Activity/drawMonthlyLoginReward'] = function(args)
    virtualData.monthlyLoginReward_.hasTodayDrawn = 1
    local todayNum  = virtualData.monthlyLoginReward_.today_
    local todayData = virtualData.monthlyLoginReward_.content[todayNum]
    local data = {
        rewards = todayData.rewards,
    }
    return t2t(data)
end


-------------------------------------------------
-- 新手15日
virtualData['Activity/newbie15DayReward'] = function(args)
    if not virtualData.newbie15DayReward_ then
        local data = {
            content        = {},
            today          = _r(15),
            hasTodayDrawn  = 0,
            endLeftSeconds = _r(999),
        }
        for i=1,15 do
            local contentData = {
                day       = i,
                rewards   = virtualData.createGoodsList(_r(4)),
                highlight = _r(0,1),
            }
            table.insert(data.content, contentData)
        end
        virtualData.newbie15DayReward_ = data
    end
    return t2t(virtualData.newbie15DayReward_)
end
-- 领取15日奖励
virtualData['Activity/drawNewbie15DayReward'] = function(args)
    local today = virtualData.newbie15DayReward_.today
    local data = {
        today   = today,
        rewards = virtualData.newbie15DayReward_.content[today].rewards
    }
    return t2t(data)
end


-------------------------------------------------
-- pass卡
virtualData['Activity/passTicket'] = function(args)
    return t2t({})
end


-------------------------------------------------
-- 付费签到


-------------------------------------------------
-- 限时升级活动
virtualData['Activity/timeLimitLvUpgradeHome'] = function(args)
    local data = {
        time = _r(9,99999)
    }
    return t2t(data)
end



-------------------------------------------------------------------------------
-- 活动副本
-------------------------------------------------------------------------------

virtualData['ActivityQuest/storyQuest'] = function(args)
    local coordinateConfs = virtualData.getConf('activityQuest', 'coordinate')
    local coordinateKeys  = table.keys(coordinateConfs)
    local data = {
        pointId = coordinateKeys[_r(#coordinateKeys)], -- 剧情点Id
        point   = _r(99),                              -- 获取的剧情点
    }
    return t2t(data)
end




-------------------------------------------------------------------------------
-- 新飨灵比拼
-------------------------------------------------------------------------------

-- 活动首页
virtualData['FoodCompare/home'] = function(args)
    if virtualData.foodCompare_ == nil then
        local groupList  = CONF.FOOD_VOTE.PARMS:GetIdList()
        local groupId    = 1--groupList[_r(#groupList)]
        local parmConf   = CONF.FOOD_VOTE.PARMS:GetValue(groupId)
        local selectConf = CONF.FOOD_VOTE.SELECT:GetValue(groupId)

        virtualData.foodCompare_ = {
            myChoice     = 0,                -- 我选定的cardId, 0:未选
            poolId       = 0,                -- 刮刮乐卡池Id 0:未选
            countDown    = _r(99999),        -- 活动结束倒计时
            groupId      = groupId,          -- 活动组Id
            cards        = parmConf.cards,   -- 候选名单
            finalRewards = parmConf.rewards, -- 最终奖励
            lotteryCards = {},               -- key为刮刮乐卡池ID，值为卡池图片
            tasks        = {},               -- 任务
        }

        for index, value in ipairs(selectConf.cards) do
            virtualData.foodCompare_.lotteryCards[tostring(index)] = value
        end

        for id, taskConf in pairs(CONF.FOOD_VOTE.TASK:GetAll()) do
            -- if _r(100) > 50 then
                virtualData.foodCompare_.tasks[tostring(id)] = {
                    progress  = _r(0, checkint(taskConf.targetNum) * 3), -- 完成进度
                    status    = _r(0,1),                                 -- 是否领取 1:是 0:否
                    descr     = taskConf.descr,                          -- 描述
                    targetNum = taskConf.targetNum,                      -- 目标
                    taskType  = taskConf.targetType,                     -- 任务类型
                    targetId  = taskConf.id,                             -- 任务Id
                    rewards   = taskConf.rewards,                        -- 奖励
                }
            -- end
        end

        -- 初始选中
        virtualData['FoodCompare/vote']({cardId = virtualData.foodCompare_.cards[1]})
        virtualData['FoodCompare/selectPool']({poolId = "1"})
    end
    return t2t(virtualData.foodCompare_)
end

-- 投票
virtualData['FoodCompare/vote'] = function(args)
    virtualData.foodCompare_.myChoice = args.cardId
    local groupId  = virtualData.foodCompare_.groupId
    local parmConf = CONF.FOOD_VOTE.PARMS:GetValue(groupId)
    local data = {
        rewards   = parmConf.rewards, -- 奖励
        times     = _r(9),            -- 今日投票次数
        prizeAble = 0,                -- 可否领奖
    }
    return t2t(data)
end

-- 对决信息
virtualData['FoodCompare/compareInfo'] = function(args)
    local cards = virtualData.foodCompare_.cards
    local tasks = virtualData.foodCompare_.tasks
    local data = {
        cardId1       = cards[1], -- cardId
        cardId2       = cards[2],
        support1      = _r(999),  -- 支持人数
        support2      = _r(999),
        lotteryPlay1  = _r(999),  -- 刮刮乐次数
        lotteryPlay2  = _r(999),
        myLotteryPlay = _r(999),  -- 我的刮刮乐次数
        info1         = {},       -- 任务进度
        info2         = {},
        myTask        = {},       -- 我的任务进度
    }
    for taskId, _ in pairs(tasks) do
        if _r(100) > 50 then data.info1[tostring(taskId)]  = _r(999) end
        if _r(100) > 50 then data.info2[tostring(taskId)]  = _r(999) end
        if _r(100) > 50 then data.myTask[tostring(taskId)] = _r(999) end
    end
    return t2t(data)
end

-- 领取任务
virtualData['FoodCompare/drawTaskReward'] = function(args)
    local taskData = virtualData.foodCompare_.tasks[tostring(args.taskId)]
    taskData.status = 1
    
    local data = {
        rewards = taskData.rewards
    }
    return t2t(data)
end

-- 选择卡池
virtualData['FoodCompare/selectPool'] = function(args)
    virtualData.foodCompare_.poolId = args.poolId
    local groupId  = virtualData.foodCompare_.groupId
    local parmConf = CONF.FOOD_VOTE.PARMS:GetValue(groupId)
    local poolConf = CONF.FOOD_VOTE.LOTTERY_POOL:GetValue(args.poolId)
    local data = {
        stampTarget1  = parmConf.stampTarget1,    -- 集邮任务1周目门槛
        stampTarget2  = parmConf.stampTarget2,    -- 集邮任务2周目门槛
        stampRewards1 = parmConf.stampRewards1,   -- 集邮任务1周目奖励
        stampRewards2 = parmConf.stampRewards2,   -- 集邮任务2周目奖励
        ticketGoodsId = parmConf.ticketGoodsId,   -- 投票物品Id
        lotteryPool   = poolConf,                 -- 目前所使用的卡池
        playTimes     = _r(table.nums(poolConf)), -- 我玩刮刮乐多少次
    }
    return t2t(data)
end

-- 选择卡池
virtualData['FoodCompare/lotteryHome'] = function(args)
    local groupId  = virtualData.foodCompare_.groupId
    local poolId   = virtualData.foodCompare_.poolId
    local parmConf = CONF.FOOD_VOTE.PARMS:GetValue(groupId)
    local poolConf = CONF.FOOD_VOTE.LOTTERY_POOL:GetValue(poolId)
    virtualData.lottery_ = virtualData.lottery_ or {}
    virtualData.lottery_[tostring(poolId)] = virtualData.lottery_[tostring(poolId)] or {collected = {} }

    local data = {
        stampTarget1  = parmConf.stampTarget1,                            -- 集邮任务1周目门槛
        stampTarget2  = parmConf.stampTarget2,                            -- 集邮任务2周目门槛
        stampRewards1 = parmConf.stampRewards1,                           -- 集邮任务1周目奖励
        stampRewards2 = parmConf.stampRewards2,                           -- 集邮任务2周目奖励
        ticketGoodsId = parmConf.ticketGoodsId,                           -- 投票物品Id
        lotteryPool   = poolConf,                                         -- 目前所使用的卡池
        playTimes     = _r(table.nums(poolConf)),                         -- 我玩刮刮乐多少次
        hasRare       = _r(0,1),                                          -- 是否还有稀有道具 0:否，1:是
        collected     = virtualData.lottery_[tostring(poolId)].collected, -- 已经获得的奖励 key为位置Id 从1开始，值为奖励
    }
    return t2t(data)
end

-- 重置卡池
virtualData['FoodCompare/resetPool'] = function(args)
    virtualData.lottery_ = {}
    return t2t({})
end

-- 卡池抽奖
virtualData['FoodCompare/lottery'] = function(args)
    local ALL_POS   = 4 * 7
    local poolId    = virtualData.foodCompare_.poolId
    local collected = virtualData.lottery_[tostring(poolId)].collected
    local posList   = {}
    for i = 1, ALL_POS do
        if collected[tostring(i)] == nil then
            table.insert(posList, i)
        end
    end
    
    local poolConf  = CONF.FOOD_VOTE.LOTTERY_POOL:GetValue(poolId)
    local stampConf = CONF.FOOD_VOTE.LOTTERY_STAMP:GetValue(poolId)
    local poolKeys  = table.keys(poolConf)
    local stampKeys = table.keys(stampConf)
    local data = {
        rewards      = {}, -- 合并的奖励
        rewardsPos   = {}, -- 单个的奖励 key为位置Id 从1开始，值为奖励
        stamp        = {}, -- 本次抽中的邮票
        stampRewards = {}, -- 集邮奖励
    }
    for i = 1, args.times do
        if #posList > 0 then
            local posIndex = table.remove(posList, _r(#posList))
            local poolKey  = checkint(poolKeys[_r(#poolKeys)])
            local posConf  = poolConf[tostring(poolKey)]
            collected[tostring(posIndex)] = posConf.rewards
            data.rewardsPos[tostring(posIndex)] = posConf.rewards
            table.insert(data.rewards, posConf.rewards)

            if _r(100) > 80 then
                table.insert(data.stamp, stampKeys[_r(stampKeys)])
            end
        end
    end
    table.insert(data.rewards, {goodsId = 880346, num = 123} )

    return t2t(data)
end

-- 卡池稀有抽光
virtualData['FoodCompare/hasRareAck'] = function(args)
    return t2t({})
end

-- 有票首页
virtualData['FoodCompare/stampHome'] = function(args)
    local poolId    = virtualData.foodCompare_.poolId
    local groupId   = virtualData.foodCompare_.groupId
    local parmConf  = CONF.FOOD_VOTE.PARMS:GetValue(groupId)
    local collected = virtualData.lottery_[tostring(poolId)].collected
    local data = {
        collected = collected, -- 已领取的奖励id
        stamp     = {}, -- 邮票id
    }
    for index, value in ipairs(parmConf.stamp) do
        if _r(100) > 50 then
            table.insert(data.stamp, value)
        end
    end
    return t2t(data)
end

-- 比拼结果
virtualData['Activity/foodCompareResult'] = function(args)
    local groupList  = CONF.FOOD_VOTE.PARMS:GetIdList()
    local groupId    = 1--groupList[_r(#groupList)]
    local parmConf   = CONF.FOOD_VOTE.PARMS:GetValue(groupId)
    local selectConf = CONF.FOOD_VOTE.SELECT:GetValue(groupId)

    local data = {
        myChoice      = parmConf.cards[_r(1,2)], -- 我选定的cardId, 0:未选
        winnerId      = parmConf.cards[_r(1,2)], -- 获胜卡牌id
        cardId1       = parmConf.cards[1],
        cardId2       = parmConf.cards[2],
        info1         = {},                      -- 任务进度
        info2         = {},
        myTask        = {},                      -- 我的任务进度
        support1      = _r(999),                 -- 支持人数
        support2      = _r(999),
        lotteryPlay1  = _r(999),                 -- 刮刮乐次数
        lotteryPlay2  = _r(999),
        myLotteryPlay = _r(999),                 -- 我的刮刮乐次数
        groupId       = groupId,
    }

    for taskId, _ in pairs(CONF.FOOD_VOTE.TASK:GetAll()) do
        if _r(100) > 50 then data.info1[tostring(taskId)]  = _r(999) end
        if _r(100) > 50 then data.info2[tostring(taskId)]  = _r(999) end
        if _r(100) > 50 then data.myTask[tostring(taskId)] = _r(999) end
    end
    return t2t(data)
end

-- 比拼结果告知
virtualData['Activity/foodCompareResultAck'] = function(args)
    return t2t({})
end
