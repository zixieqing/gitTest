--[[
 * author : kaishiqi
 * descpt : 关于 抽卡数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t



-- 进入基础抽卡
virtualData['Gambling/enter'] = function(args)
    local data = {
        diamond = {
            gold         = 987,    -- 赠送金币数量
            diamond      = 100,    -- 花费钻石数量
            oneLeftTimes = -1,     -- 单抽剩余次数，-1为不限
            goodsNum     = _r(10), -- 消耗抽卡券数量
        },
        diamondSix = {
            gold         = 987*6,  -- 赠送金币数量
            diamond      = 600,    -- 花费钻石数量
            oneLeftTimes = -1,     -- 六抽剩余次数，-1为不限
            goodsNum     = _r(10), -- 消耗抽卡券数量
        },
        base = {{
            one = {
                gold      = 12000,
                diamond   = 100,
                leftTimes = -1,
                goodsId   = 900001,
                -- goodsId   = 890002,
                num       = 100
            },
            six = {
                gold      = 72000,
                diamond   = 600,
                leftTimes = -1,
                goodsId   = 890002,
                -- goodsId   = 900001,
                num       = 9
            },
            rate = {},
            preview = {
                {}, -- 其他
                {}, -- 稀有
            },
            moneyIdMap = {
                ['890002'] = 890002,
                ['900001'] = 900001,
            }
        }},
        activity = {}
    }
    local gamblingData = data.base[1]
    local previeLen    = #gamblingData.preview
    local cardConfs    = virtualData.getConf('goods', 'card')
    for _, cardConf in pairs(cardConfs) do
        table.insert(gamblingData.rate, {
            descr = tostring(cardConf.name),
            rate  = _r(999)
        })
        table.insert(gamblingData.preview[_r(1, previeLen)], cardConf.id)
    end
    return t2t(data)
end


-- 开始基础抽卡
virtualData['Gambling/lucky'] = function(args)
    virtualData.playerData.diamond = virtualData.playerData.diamond
    local data = {
        gold    = virtualData.playerData.gold,
        diamond = virtualData.playerData.diamond,
        rewards = {}
    }

    local drawCardFunc = function(cardId)
        local cardConfs  = virtualData.getConf('card', 'card')
        local cardIdList = table.keys(cardConfs)
        local drawCardId = cardId and cardId or cardIdList[_r(#cardIdList)]
        local cardData   = virtualData.createCardData(drawCardId, virtualData.playerData.playerId)
        table.insert(data.rewards, { goodsId = drawCardId, playerCardId = cardData.id })
        virtualData.playerData.cards[tostring(cardData.id)] = cardData
    end

    if virtualData.playerData.level == 1 then
        -- 20017 冬荫功
        if not virtualData.findCardByConfId(200017) then
            drawCardFunc(200017)
            
        -- 20012 红茶
        elseif not virtualData.findCardByConfId(200012) then
            drawCardFunc(200012)
            
        else
            for i = 1, checkint(args.type) == 2 and 6 or 1 do
                drawCardFunc()
            end
        end
    else
        for i = 1, checkint(args.type) == 2 and 6 or 1 do
            drawCardFunc()
        end
    end
    return t2t(data)
end


-- 新抽卡入口
virtualData['Gambling/home'] = function(args)
    local data = {
        base   = virtualData['Gambling/enter']().data.base,
        newbie = {
            {
                poolName    = "萌芽之宴",
                leftSeconds = -186355,
            }
        },
        activity = {},
    }

    data.activity = json.decode([[{
        "data":[
            {
                "activityId": "784",
                "poolName": "10连！",
                "type": 39,
                "backgroundImage": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/4de237416360f267a545382989406e83.jpg",
                "sidebarImage": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/c3af246c26e2e8965ed0be8ac276c879.jpg",
                "rule": "十连活动345235645634",
                "isNew": 0,
                "image": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/4de237416360f267a545382989406e83.jpg",
                "title": "十连活动",
                "detail": "十连活动34523",
                "leftSeconds": 34099
            },
            {
                "activityId": "785",
                "poolName": "来迎之宴",
                "type": 40,
                "backgroundImage": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/7a0b7678e285b2dcfe549d222e4f0a1d.jpg",
                "sidebarImage": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/fe2ca2f22bde0730a06d24ccf9398e89.jpg",
                "rule": "超得345643564565886",
                "isNew": 0,
                "image": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/7a0b7678e285b2dcfe549d222e4f0a1d.jpg",
                "title": "超得",
                "detail": "超得3456435645",
                "leftSeconds": 34099
            },
            {
                "activityId": "786",
                "poolName": "九宫格",
                "type": 41,
                "backgroundImage": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/5e60a3365087336e8e41db41b14a4572.jpg",
                "sidebarImage": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/d61a833c5723a0ab727546f83fec8fb7.jpg",
                "rule": "九宫格87678465",
                "isNew": 0,
                "image": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/26172119721ecb3bfb0750bde0b53460.jpg",
                "title": "九宫格",
                "detail": "九宫格123234325",
                "leftSeconds": 34099
            },
            {
                "activityId": "787",
                "type": 41,
                "isNew": 0,
                "backgroundImage": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/5e60a3365087336e8e41db41b14a4572.jpg",
                "sidebarImage": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/d61a833c5723a0ab727546f83fec8fb7.jpg",
                "image": "http://fondant-activity.oss-cn-hangzhou.aliyuncs.com/activity/26172119721ecb3bfb0750bde0b53460.jpg",
                "rule": "2九宫格87678465",
                "title": "九宫格",
                "detail": "2九宫格123234325",
                "poolName": "九宫格",
                "leftSeconds": 34099
            }
        ]
    }]]).data
    for i, v in ipairs(data.activity) do
        v.leftSeconds = 50 + i*3
    end
    return t2t(data)
end


-- 进入新手抽卡
virtualData['Gambling/newbie'] = function(args)
    return j2t([[
        {
            "data": {
                "gamblingTimes": 0,
                "maxGamblingTimes": "100",
                "finalRewards": [
                    {
                        "goodsId": 200004,
                        "type": 20,
                        "num": 1,
                        "rewardId": 1
                    },
                    {
                        "goodsId": 200046,
                        "type": 20,
                        "num": 1,
                        "rewardId": 2
                    },
                    {
                        "goodsId": 200037,
                        "type": 20,
                        "num": 1,
                        "rewardId": 3
                    }
                ],
                "oneGamblingTimes": "0",
                "tenGamblingTimes": "0",
                "oneDiscountTimes": "10",
                "tenDiscountTimes": "1",
                "firstOneConsume": [
                    {
                        "goodsId": 900022,
                        "type": 90,
                        "num": 50
                    }
                ],
                "oneConsume": [
                    {
                        "goodsId": 900022,
                        "type": 90,
                        "num": 100
                    }
                ],
                "firstTenConsume": [
                    {
                        "goodsId": 900022,
                        "type": 90,
                        "num": 500
                    }
                ],
                "tenConsume": [
                    {
                        "goodsId": 900022,
                        "type": 90,
                        "num": 1000
                    }
                ],
                "preview": [
                    [
                        200006,
                        200021,
                        200026,
                        200070,
                        200001,
                        200003,
                        200005,
                        200007,
                        200010,
                        200016,
                        200017,
                        200022,
                        200029,
                        200032,
                        200034,
                        200038,
                        200044,
                        200051,
                        200054,
                        200059,
                        200061,
                        200065,
                        200066,
                        200023,
                        200049,
                        200015,
                        200025,
                        200031,
                        200033,
                        200039,
                        200040,
                        200041,
                        200043,
                        200050,
                        200056,
                        200062,
                        200067,
                        200069,
                        200008,
                        200027,
                        200058,
                        200087,
                        200084,
                        200093,
                        200042,
                        200083,
                        200072
                    ],
                    [
                        200004,
                        200024,
                        200037,
                        200046,
                        200048,
                        200002,
                        200020
                    ]
                ],
                "rate": {
                    "1": {
                        "descr": "UR飨灵",
                        "rate": "301"
                    },
                    "2": {
                        "descr": "SR飨灵",
                        "rate": "1661"
                    },
                    "3": {
                        "descr": "R飨灵",
                        "rate": "7853"
                    },
                    "4": {
                        "descr": "M飨灵",
                        "rate": "185"
                    }
                },
                "slaveView": "draw_probability_role"
            },
            "timestamp": 1540621560,
            "errcode": 0,
            "errmsg": "",
            "rand": "5bd404f8028b31540621560",
            "sign": "90e2cd822d0c840b56c5139db940c9b3"
        }
    ]])
end


-- 进入十连抽卡
virtualData['Gambling/tenTimes'] = function(args)
    return j2t([[
        {
            "data": {
                "step": [
                    {
                        "stepId": 1,
                        "targetNum": "3",
                        "progress": 0,
                        "rewards": [
                            {
                                "goodsId": 200041,
                                "type": 20,
                                "num": 1
                            }
                        ],
                        "highlight": "1",
                        "hasDrawn": 0
                    },
                    {
                        "stepId": 2,
                        "targetNum": "5",
                        "progress": 0,
                        "rewards": [
                            {
                                "goodsId": 880110,
                                "type": 88,
                                "num": 5
                            }
                        ],
                        "highlight": "0",
                        "hasDrawn": 0
                    },
                    {
                        "stepId": 3,
                        "targetNum": "7",
                        "progress": 0,
                        "rewards": [
                            {
                                "goodsId": 200057,
                                "type": 20,
                                "num": 1
                            }
                        ],
                        "highlight": "1",
                        "hasDrawn": 0
                    }
                ],
                "consume": [
                    {
                        "goodsId": 880111,
                        "type": 88,
                        "num": 10
                    },
                    {
                        "goodsId": 900001,
                        "type": 90,
                        "num": 1000
                    }
                ],
                "discountConsume": [
                    {
                        "goodsId": 900001,
                        "type": 90,
                        "num": 500
                    }
                ],
                "isDiscount": 1,
                "discountTimes": "1",
                "iconId": "1",
                "slaveView": "draw_probability_role_7",
                "rate": [
                    {
                        "descr": "UR飨灵",
                        "rate": "301"
                    },
                    {
                        "descr": "SR飨灵",
                        "rate": "1661"
                    },
                    {
                        "descr": "R飨灵",
                        "rate": "7853"
                    },
                    {
                        "descr": "M飨灵",
                        "rate": "185"
                    }
                ],
                "preview": [
                    [
                        200006,
                        200021,
                        200026,
                        200070,
                        200001,
                        200003,
                        200005,
                        200007,
                        200010,
                        200016,
                        200017,
                        200022,
                        200029,
                        200032,
                        200034,
                        200038,
                        200044,
                        200051,
                        200054,
                        200059,
                        200061,
                        200065,
                        200066,
                        200023,
                        200049,
                        200015,
                        200025,
                        200031,
                        200033,
                        200039,
                        200040,
                        200041,
                        200043,
                        200050,
                        200056,
                        200062,
                        200067,
                        200069,
                        200008,
                        200027,
                        200058,
                        200087,
                        200084,
                        200093,
                        200042,
                        200083,
                        200072
                    ],
                    [
                        200004,
                        200024,
                        200037,
                        200046,
                        200048,
                        200057,
                        200002,
                        200020
                    ]
                ],
                "moneyIdMap": {
                    "880111": 880111,
                    "900001": 900001
                }
            },
            "timestamp": 1540721931,
            "errcode": 0,
            "errmsg": "",
            "rand": "5bd58d0be2d701540721931",
            "sign": "1cd2501a4304eddb4959c065ace48150"
        }
    ]])
end


-- 进入超得抽卡
virtualData['Gambling/super'] = function(args)
    return j2t([[
        {
            "data": {
                "pool": [
                    {
                        "poolId": 1,
                        "consume": [
                            {
                                "goodsId": 880109,
                                "type": 88,
                                "num": 5
                            }
                        ],
                        "icon": [
                            {
                                "iconId": "3",
                                "iconTitle": "80"
                            },
                            {
                                "iconId": "4",
                                "iconTitle": "20"
                            }
                        ],
                        "slaveView": "draw_probability_role_1"
                    },
                    {
                        "poolId": 2,
                        "consume": [
                            {
                                "goodsId": 880109,
                                "type": 88,
                                "num": 10
                            }
                        ],
                        "icon": [
                            {
                                "iconId": "3",
                                "iconTitle": "50"
                            },
                            {
                                "iconId": "4",
                                "iconTitle": "50"
                            }
                        ],
                        "slaveView": "draw_probability_role_2"
                    },
                    {
                        "poolId": 3,
                        "consume": [
                            {
                                "goodsId": 880109,
                                "type": 88,
                                "num": 15
                            }
                        ],
                        "icon": [
                            {
                                "iconId": "4",
                                "iconTitle": "100"
                            }
                        ],
                        "slaveView": "draw_probability_role_3"
                    }
                ],
                "preview": [
                    [
                        200015,
                        200025,
                        200031,
                        200033,
                        200039,
                        200040,
                        200041,
                        200043,
                        200050,
                        200056,
                        200062,
                        200067,
                        200069,
                        200008,
                        200027,
                        200058,
                        200087,
                        200084,
                        200093,
                        200042,
                        200083,
                        200072
                    ],
                    [
                        200004,
                        200024,
                        200037,
                        200046,
                        200048,
                        200002,
                        200020
                    ]
                ],
                "moneyIdMap": {
                    "880109": 880109
                }
            },
            "timestamp": 1540721689,
            "errcode": 0,
            "errmsg": "",
            "rand": "5bd58c19eb1d81540721689",
            "sign": "e71962cc2b484a5d0f84bf8fcaa7f8f8"
        }
    ]])
end
virtualData['Gambling/superLucky'] = function(args)
    local data = {
        rewards = {}
    }

    local drawCardFunc = function(cardId)
        local cardConfs  = virtualData.getConf('card', 'card')
        local cardIdList = table.keys(cardConfs)
        local drawCardId = cardId and cardId or cardIdList[_r(#cardIdList)]
        table.insert(data.rewards, { goodsId = drawCardId })

        local cardData  = virtualData.createCardData(drawCardId, virtualData.playerData.playerId)
        virtualData.playerData.cards[tostring(cardData.id)] = cardData
    end

    drawCardFunc(200017)
    return t2t(data)
end


-- 进入九宫抽卡
virtualData['Gambling/squared'] = function(args)
    return j2t([[
        {
            "data": {
                "currentRound": 1,
                "totalRound": 11,
                "goods": [
                    {
                        "squaredId": 1,
                        "goodsId": "173001",
                        "num": "1",
                        "big": 0,
                        "hasDrawn": 0
                    },
                    {
                        "squaredId": 2,
                        "goodsId": "900005",
                        "num": "2000",
                        "big": 0,
                        "hasDrawn": 0
                    },
                    {
                        "squaredId": 3,
                        "goodsId": "890006",
                        "num": "5",
                        "big": 0,
                        "hasDrawn": 0
                    },
                    {
                        "squaredId": 4,
                        "goodsId": "890021",
                        "num": "1",
                        "big": 0,
                        "hasDrawn": 0
                    },
                    {
                        "squaredId": 5,
                        "goodsId": "900003",
                        "num": "120",
                        "big": 0,
                        "hasDrawn": 0
                    },
                    {
                        "squaredId": 6,
                        "goodsId": "180001",
                        "num": "3",
                        "big": 0,
                        "hasDrawn": 0
                    },
                    {
                        "squaredId": 7,
                        "goodsId": "890006",
                        "num": "10",
                        "big": 0,
                        "hasDrawn": 0
                    },
                    {
                        "squaredId": 8,
                        "goodsId": "890002",
                        "num": "50",
                        "big": 0,
                        "hasDrawn": 0
                    },
                    {
                        "squaredId": 9,
                        "goodsId": 890002,
                        "num": 150,
                        "big": 1,
                        "hasDrawn": 0
                    }
                ],
                "consume": [
                    {
                        "goodsId": 880110,
                        "type": 88,
                        "num": 1
                    },
                    {
                        "goodsId": 900001,
                        "type": 90,
                        "num": 50
                    }
                ],
                "preview": [
                    [
                        890002
                    ],
                    [
                        880111
                    ],
                    [
                        190408
                    ],
                    [
                        880111
                    ],
                    [
                        250073
                    ],
                    [
                        890004
                    ],
                    [
                        880111
                    ],
                    [
                        260004
                    ],
                    [
                        890009
                    ],
                    [
                        880111
                    ],
                    [
                        250563
                    ]
                ],
                "slaveView": "draw_probability_role_7",
                "moneyIdMap": {
                    "880110": 880110,
                    "900001": 900001
                }
            },
            "timestamp": 1540721748,
            "errcode": 0,
            "errmsg": "",
            "rand": "5bd58c5464cf51540721748",
            "sign": "9b32cad797aa976319057cfe12675172"
        }
    ]])
end
