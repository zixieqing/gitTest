--[[
 * author : kaishiqi
 * descpt : 锦标赛设定 相关定义
]]
local CHAMPIONSHIP = {}

-------------------------------------------------------------------------------
-- 通用定义
-------------------------------------------------------------------------------

CHAMPIONSHIP.DEFINE = {
}


CHAMPIONSHIP.calculateVoteNum = function(haveCurrencyNum)
    local guessConf   = CONF.CHAMPIONSHIP.GUESSING_PARAMS:GetAll()
    local guessRate   = checknumber(guessConf.guessRate) -- 投票货币的比率
    local guessMax    = checkint(guessConf.guessMax)     -- 投票货币的上限
    local currencyNum = checkint(haveCurrencyNum)
    return math.min(math.ceil(currencyNum * guessRate), guessMax)
end


CHAMPIONSHIP.STEP = {
    UNKNOWN      = 0,  -- 未知
    AUDITIONS    = 1,  -- 海选赛
    PROMOTION    = 2,  -- 晋级赛报名
    VOTING_16    = 3,  -- 投票选16强
    RESULT_16_1  = 4,  -- 公布1/16强
    RESULT_16_2  = 5,  -- 公布2/16强
    RESULT_16_3  = 6,  -- 公布3/16强
    RESULT_16_4  = 7,  -- 公布4/16强
    RESULT_16_5  = 8,  -- 公布5/16强
    RESULT_16_6  = 9,  -- 公布6/16强
    RESULT_16_7  = 10, -- 公布7/16强
    RESULT_16_8  = 11, -- 公布8/16强
    RESULT_16_9  = 12, -- 公布9/16强
    RESULT_16_10 = 13, -- 公布10/16强
    RESULT_16_11 = 14, -- 公布11/16强
    RESULT_16_12 = 15, -- 公布12/16强
    RESULT_16_13 = 16, -- 公布13/16强
    RESULT_16_14 = 17, -- 公布14/16强
    RESULT_16_15 = 18, -- 公布15/16强
    RESULT_16_16 = 19, -- 公布16/16强
    VOTING_8     = 20, -- 投票选8强
    RESULT_8_1   = 21, -- 公布1/8强
    RESULT_8_2   = 22, -- 公布2/8强
    RESULT_8_3   = 23, -- 公布3/8强
    RESULT_8_4   = 24, -- 公布4/8强
    RESULT_8_5   = 25, -- 公布5/8强
    RESULT_8_6   = 26, -- 公布6/8强
    RESULT_8_7   = 27, -- 公布7/8强
    RESULT_8_8   = 28, -- 公布8/8强
    VOTING_4     = 29, -- 投票选4强
    RESULT_4_1   = 30, -- 公布1/4强
    RESULT_4_2   = 31, -- 公布2/4强
    RESULT_4_3   = 32, -- 公布3/4强
    RESULT_4_4   = 33, -- 公布4/4强
    VOTING_2     = 34, -- 投票选2强
    RESULT_2_1   = 35, -- 公布1/2强
    RESULT_2_2   = 36, -- 公布2/2强
    VOTING_1     = 37, -- 投票选冠军
    RESULT_1_1   = 38, -- 公布冠军
    OFF_SEASON   = 39, -- 休赛期
}


CHAMPIONSHIP.MATCH_TITLE = {
    [CHAMPIONSHIP.STEP.UNKNOWN]      = function() return __('未开赛') end,
    [CHAMPIONSHIP.STEP.AUDITIONS]    = function() return __('海选赛') end,
    [CHAMPIONSHIP.STEP.PROMOTION]    = function() return __('晋级赛报名') end,
    --                               = 
    [CHAMPIONSHIP.STEP.VOTING_16]    = function() return __('等待正赛开赛') end,
    [CHAMPIONSHIP.STEP.RESULT_16_1]  = function() return __('A组第1场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_2]  = function() return __('A组第2场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_3]  = function() return __('A组第3场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_4]  = function() return __('A组第4场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_5]  = function() return __('B组第1场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_6]  = function() return __('B组第2场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_7]  = function() return __('B组第3场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_8]  = function() return __('B组第4场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_9]  = function() return __('C组第1场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_10] = function() return __('C组第2场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_11] = function() return __('C组第3场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_12] = function() return __('C组第4场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_13] = function() return __('D组第1场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_14] = function() return __('D组第2场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_15] = function() return __('D组第3场（32进16）') end,
    [CHAMPIONSHIP.STEP.RESULT_16_16] = function() return __('D组第4场（32进16）') end,
    --                               = 
    [CHAMPIONSHIP.STEP.VOTING_8]     = function() return __('等待16进8开赛') end,
    [CHAMPIONSHIP.STEP.RESULT_8_1]   = function() return __('A组第5场（16进8）') end,
    [CHAMPIONSHIP.STEP.RESULT_8_2]   = function() return __('A组第6场（16进8）') end,
    [CHAMPIONSHIP.STEP.RESULT_8_3]   = function() return __('B组第5场（16进8）') end,
    [CHAMPIONSHIP.STEP.RESULT_8_4]   = function() return __('B组第6场（16进8）') end,
    [CHAMPIONSHIP.STEP.RESULT_8_5]   = function() return __('C组第5场（16进8）') end,
    [CHAMPIONSHIP.STEP.RESULT_8_6]   = function() return __('C组第6场（16进8）') end,
    [CHAMPIONSHIP.STEP.RESULT_8_7]   = function() return __('D组第5场（16进8）') end,
    [CHAMPIONSHIP.STEP.RESULT_8_8]   = function() return __('D组第6场（16进8）') end,
    --                               = 
    [CHAMPIONSHIP.STEP.VOTING_4]     = function() return __('等待小组决赛') end,
    [CHAMPIONSHIP.STEP.RESULT_4_1]   = function() return __('公布A组胜者') end,
    [CHAMPIONSHIP.STEP.RESULT_4_2]   = function() return __('公布B组胜者') end,
    [CHAMPIONSHIP.STEP.RESULT_4_3]   = function() return __('公布C组胜者') end,
    [CHAMPIONSHIP.STEP.RESULT_4_4]   = function() return __('公布D组胜者') end,
    --                               = 
    [CHAMPIONSHIP.STEP.VOTING_2]     = function() return __('等待半决赛') end,
    [CHAMPIONSHIP.STEP.RESULT_2_1]   = function() return __('公布上半场4强') end,
    [CHAMPIONSHIP.STEP.RESULT_2_2]   = function() return __('公布下半场4强') end,
    --
    [CHAMPIONSHIP.STEP.VOTING_1]     = function() return __('等待决赛') end,
    [CHAMPIONSHIP.STEP.RESULT_1_1]   = function() return __('公布冠军') end,
    [CHAMPIONSHIP.STEP.OFF_SEASON]   = function() return __('休赛期') end,
}


CHAMPIONSHIP.GUESS_TITLE = {
    [CHAMPIONSHIP.STEP.UNKNOWN]      = function() return __('未开赛') end,
    [CHAMPIONSHIP.STEP.AUDITIONS]    = function() return __('海选赛') end,
    [CHAMPIONSHIP.STEP.PROMOTION]    = function() return __('等待正赛') end,
    --                               = 
    [CHAMPIONSHIP.STEP.VOTING_16]    = function() return __('竞猜A组 第1场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_1]  = function() return __('竞猜A组 第2场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_2]  = function() return __('竞猜A组 第3场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_3]  = function() return __('竞猜A组 第4场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_4]  = function() return __('竞猜B组 第1场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_5]  = function() return __('竞猜B组 第2场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_6]  = function() return __('竞猜B组 第3场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_7]  = function() return __('竞猜B组 第4场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_8]  = function() return __('竞猜C组 第1场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_9]  = function() return __('竞猜C组 第2场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_10] = function() return __('竞猜C组 第3场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_11] = function() return __('竞猜C组 第4场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_12] = function() return __('竞猜D组 第1场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_13] = function() return __('竞猜D组 第2场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_14] = function() return __('竞猜D组 第3场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_15] = function() return __('竞猜D组 第4场') end,
    [CHAMPIONSHIP.STEP.RESULT_16_16] = function() return __('等待8强赛') end,
    --                               = 
    [CHAMPIONSHIP.STEP.VOTING_8]     = function() return __('竞猜A组 第5场') end,
    [CHAMPIONSHIP.STEP.RESULT_8_1]   = function() return __('竞猜A组 第6场') end,
    [CHAMPIONSHIP.STEP.RESULT_8_2]   = function() return __('竞猜B组 第5场') end,
    [CHAMPIONSHIP.STEP.RESULT_8_3]   = function() return __('竞猜B组 第6场') end,
    [CHAMPIONSHIP.STEP.RESULT_8_4]   = function() return __('竞猜C组 第5场') end,
    [CHAMPIONSHIP.STEP.RESULT_8_5]   = function() return __('竞猜C组 第6场') end,
    [CHAMPIONSHIP.STEP.RESULT_8_6]   = function() return __('竞猜D组 第5场') end,
    [CHAMPIONSHIP.STEP.RESULT_8_7]   = function() return __('竞猜D组 第6场') end,
    [CHAMPIONSHIP.STEP.RESULT_8_8]   = function() return __('等待小组决赛') end,
    --                               = 
    [CHAMPIONSHIP.STEP.VOTING_4]     = function() return __('竞猜A组胜者') end,
    [CHAMPIONSHIP.STEP.RESULT_4_1]   = function() return __('竞猜B组胜者') end,
    [CHAMPIONSHIP.STEP.RESULT_4_2]   = function() return __('竞猜C组胜者') end,
    [CHAMPIONSHIP.STEP.RESULT_4_3]   = function() return __('竞猜D组胜者') end,
    [CHAMPIONSHIP.STEP.RESULT_4_4]   = function() return __('等待半决赛') end,
    --                               = 
    [CHAMPIONSHIP.STEP.VOTING_2]     = function() return __('竞猜上半场4强') end,
    [CHAMPIONSHIP.STEP.RESULT_2_1]   = function() return __('竞猜下半场4强') end,
    [CHAMPIONSHIP.STEP.RESULT_2_2]   = function() return __('等待决赛') end,
    --
    [CHAMPIONSHIP.STEP.VOTING_1]     = function() return __('竞猜冠军') end,
    [CHAMPIONSHIP.STEP.RESULT_1_1]   = function() return __('等待结束') end,
    [CHAMPIONSHIP.STEP.OFF_SEASON]   = function() return __('休赛期') end,
}


CHAMPIONSHIP.ROUND_NUM = {
    {beganStep = CHAMPIONSHIP.STEP.VOTING_16, endedStep = CHAMPIONSHIP.STEP.RESULT_16_16, getTitle = function() return __('16强晋级赛') end},
    {beganStep = CHAMPIONSHIP.STEP.VOTING_8,  endedStep = CHAMPIONSHIP.STEP.RESULT_8_8,   getTitle = function() return __('8强晋级赛') end},
    {beganStep = CHAMPIONSHIP.STEP.VOTING_4,  endedStep = CHAMPIONSHIP.STEP.RESULT_4_4,   getTitle = function() return __('4强晋级赛') end},
    {beganStep = CHAMPIONSHIP.STEP.VOTING_2,  endedStep = CHAMPIONSHIP.STEP.RESULT_2_2,   getTitle = function() return __('半决赛') end},
    {beganStep = CHAMPIONSHIP.STEP.VOTING_1,  endedStep = CHAMPIONSHIP.STEP.RESULT_1_1,   getTitle = function() return __('冠军赛') end},
}


CHAMPIONSHIP.LAST_MATCH_ID = CHAMPIONSHIP.STEP.RESULT_16_1


CHAMPIONSHIP.MATCH_ID = {
    {
        -- A 组
        CHAMPIONSHIP.STEP.RESULT_16_1, CHAMPIONSHIP.STEP.RESULT_16_2,
        CHAMPIONSHIP.STEP.RESULT_16_3, CHAMPIONSHIP.STEP.RESULT_16_4,
        -- B 组
        CHAMPIONSHIP.STEP.RESULT_16_5, CHAMPIONSHIP.STEP.RESULT_16_6,
        CHAMPIONSHIP.STEP.RESULT_16_7, CHAMPIONSHIP.STEP.RESULT_16_8,
        -- C 组
        CHAMPIONSHIP.STEP.RESULT_16_9,  CHAMPIONSHIP.STEP.RESULT_16_10,
        CHAMPIONSHIP.STEP.RESULT_16_11, CHAMPIONSHIP.STEP.RESULT_16_12,
        -- D 组
        CHAMPIONSHIP.STEP.RESULT_16_13, CHAMPIONSHIP.STEP.RESULT_16_14,
        CHAMPIONSHIP.STEP.RESULT_16_15, CHAMPIONSHIP.STEP.RESULT_16_16,
    },
    {
        -- A 组
        CHAMPIONSHIP.STEP.RESULT_8_1, CHAMPIONSHIP.STEP.RESULT_8_2,
        -- B 组
        CHAMPIONSHIP.STEP.RESULT_8_3, CHAMPIONSHIP.STEP.RESULT_8_4,
        -- C 组
        CHAMPIONSHIP.STEP.RESULT_8_5, CHAMPIONSHIP.STEP.RESULT_8_6,
        -- D 组
        CHAMPIONSHIP.STEP.RESULT_8_7, CHAMPIONSHIP.STEP.RESULT_8_8,
    },
    {
        -- A 组
        CHAMPIONSHIP.STEP.RESULT_4_1,
        -- B 组
        CHAMPIONSHIP.STEP.RESULT_4_2,
        -- C 组
        CHAMPIONSHIP.STEP.RESULT_4_3,
        -- D 组
        CHAMPIONSHIP.STEP.RESULT_4_4,
    },
    {
        -- 半决赛
        CHAMPIONSHIP.STEP.RESULT_2_1, CHAMPIONSHIP.STEP.RESULT_2_2,
    },
    {
        -- 决赛
        CHAMPIONSHIP.STEP.RESULT_1_1,
    },
}


CHAMPIONSHIP.GROUP_MAP = {
    [CHAMPIONSHIP.STEP.UNKNOWN]      = 0,  -- 未知
    [CHAMPIONSHIP.STEP.AUDITIONS]    = 0,  -- 海选赛
    [CHAMPIONSHIP.STEP.PROMOTION]    = 1,  -- 晋级赛报名
    [CHAMPIONSHIP.STEP.VOTING_16]    = 1,  -- 投票选16强
    [CHAMPIONSHIP.STEP.RESULT_16_1]  = 1,  -- 公布1/16强
    [CHAMPIONSHIP.STEP.RESULT_16_2]  = 1,  -- 公布2/16强
    [CHAMPIONSHIP.STEP.RESULT_16_3]  = 1,  -- 公布3/16强
    [CHAMPIONSHIP.STEP.RESULT_16_4]  = 1,  -- 公布4/16强
    [CHAMPIONSHIP.STEP.RESULT_16_5]  = 2,  -- 公布5/16强
    [CHAMPIONSHIP.STEP.RESULT_16_6]  = 2,  -- 公布6/16强
    [CHAMPIONSHIP.STEP.RESULT_16_7]  = 2, -- 公布7/16强
    [CHAMPIONSHIP.STEP.RESULT_16_8]  = 2, -- 公布8/16强
    [CHAMPIONSHIP.STEP.RESULT_16_9]  = 3, -- 公布9/16强
    [CHAMPIONSHIP.STEP.RESULT_16_10] = 3, -- 公布10/16强
    [CHAMPIONSHIP.STEP.RESULT_16_11] = 3, -- 公布11/16强
    [CHAMPIONSHIP.STEP.RESULT_16_12] = 3, -- 公布12/16强
    [CHAMPIONSHIP.STEP.RESULT_16_13] = 4, -- 公布13/16强
    [CHAMPIONSHIP.STEP.RESULT_16_14] = 4, -- 公布14/16强
    [CHAMPIONSHIP.STEP.RESULT_16_15] = 4, -- 公布15/16强
    [CHAMPIONSHIP.STEP.RESULT_16_16] = 4, -- 公布16/16强
    [CHAMPIONSHIP.STEP.VOTING_8]     = 1, -- 投票选8强
    [CHAMPIONSHIP.STEP.RESULT_8_1]   = 1, -- 公布1/8强
    [CHAMPIONSHIP.STEP.RESULT_8_2]   = 1, -- 公布2/8强
    [CHAMPIONSHIP.STEP.RESULT_8_3]   = 2, -- 公布3/8强
    [CHAMPIONSHIP.STEP.RESULT_8_4]   = 2, -- 公布4/8强
    [CHAMPIONSHIP.STEP.RESULT_8_5]   = 3, -- 公布5/8强
    [CHAMPIONSHIP.STEP.RESULT_8_6]   = 3, -- 公布6/8强
    [CHAMPIONSHIP.STEP.RESULT_8_7]   = 4, -- 公布7/8强
    [CHAMPIONSHIP.STEP.RESULT_8_8]   = 4, -- 公布8/8强
    [CHAMPIONSHIP.STEP.VOTING_4]     = 1, -- 投票选4强
    [CHAMPIONSHIP.STEP.RESULT_4_1]   = 1, -- 公布1/4强
    [CHAMPIONSHIP.STEP.RESULT_4_2]   = 2, -- 公布2/4强
    [CHAMPIONSHIP.STEP.RESULT_4_3]   = 3, -- 公布3/4强
    [CHAMPIONSHIP.STEP.RESULT_4_4]   = 4, -- 公布4/4强
    [CHAMPIONSHIP.STEP.VOTING_2]     = 0, -- 投票选2强
    [CHAMPIONSHIP.STEP.RESULT_2_1]   = 0, -- 公布1/2强
    [CHAMPIONSHIP.STEP.RESULT_2_2]   = 0, -- 公布2/2强
    [CHAMPIONSHIP.STEP.VOTING_1]     = 0, -- 投票选冠军
    [CHAMPIONSHIP.STEP.RESULT_1_1]   = 0, -- 公布冠军
    [CHAMPIONSHIP.STEP.OFF_SEASON]   = 0, -- 休赛期
}


-- 帮笑博针对国服事件擦屁股
CHAMPIONSHIP.IS_XIAOBO_FIX = function()
    return isChinaSdk() and checkint(Platform.id) ~= PreIos or checkint(Platform.id) ~= PreAndroid
end


-------------------------------------------------------------------------------
-- 网络协议
-------------------------------------------------------------------------------
do
    CHAMPIONSHIP.NETWORK = {}


    ------------------------------------------------- [首页]

    -- 武道会首页
    CHAMPIONSHIP.NETWORK.MAIN = {
        POST = POST.CHAMPIONSHIP_MAIN,

        SEND = {},

        TAKE = { _map = 1, _key = 'MAIN_TAKE',
            SEASON_ID         = { _int = 1, _key = 'seasonId' },   -- 赛季id
            SCHEDULE_STEP     = { _int = 1, _key = 'status' },     -- 赛程阶段 @see CHAMPIONSHIP.STEP, CONF.CHAMPIONSHIP.TIMELINE
            STEP_RTIME        = { _int = 1, _key = 'leftSec' },    -- 阶段还剩多少秒
            OPEN_RTIME        = { _int = 1, _key = 'countDown' },  -- 开启还剩多少秒（闭馆时使用）
            AUDITION_TICKET   = { _int = 1, _key = 'ticket' },     -- 海选赛 挑战次数
            AUDITION_QUEST_ID = { _int = 1, _key = 'questId' },    -- 海选赛 关卡id
            AUDITION_SCORE    = { _int = 1, _key = 'myScore' },    -- 海选赛 我的成绩
            AUDITION_RANK     = { _int = 1, _key = 'myRank' },     -- 海选赛 我的排名（只给前32名）
            AUDITION_TEAM     = { _lst = 1, _key = 'auditionTeam', -- 海选赛 我的队伍
                CARD_UUID = { _int = 1, _key = '$cardUuid' },
            },
            PROMOTION_QUALIFIED = { _int = 1, _key = 'qualified' }, -- 晋级赛 是否获得资格（1：晋级正赛， 0：没晋级）
            PROMOTION_OVER      = { _int = 1, _key = 'over' },      -- 晋级赛 是否遭到淘汰（1：被淘汰，0：没淘汰）
            PROMOTION_RANK      = { _int = 1, _key = 'rank' },      -- 晋级赛 最终排名
            PROMOTION_TEAM1     = { _lst = 1, _key = 'team1',       -- 晋级赛 队伍1信息
                CARD_DETAIL = copyStruct(FOOD.COMMON.NETWORK.CARD_DETAIL, '$cardIndex'),
            },
            PROMOTION_TEAM2     = { _lst = 1, _key = 'team2',       -- 晋级赛 队伍2信息
                CARD_DETAIL = copyStruct(FOOD.COMMON.NETWORK.CARD_DETAIL, '$cardIndex'),
            },
            PROMOTION_TEAM3     = { _lst = 1, _key = 'team3',       -- 晋级赛 队伍3信息
                CARD_DETAIL = copyStruct(FOOD.COMMON.NETWORK.CARD_DETAIL, '$cardIndex'),
            },
            PROMOTION_PLAYERS   = { _map = 1, _key = 'playerInfo',  -- 晋级赛 32名玩家信息
                PLAYER_DATA = { _map = 1, _key = '$playerId',
                    NAME   = { _str = 1, _key = 'name' },        -- 玩家名称
                    AVATAR = { _int = 1, _key = 'avatar' },      -- 玩家头像
                    FRAME  = { _int = 1, _key = 'frame' },       -- 玩家头框
                    LEVEL  = { _int = 1, _key = 'level' },       -- 玩家等级
                    UNION  = { _str = 1, _key = 'union' },       -- 玩家工会
                    POWER1 = { _int = 1, _key = 'combatValue1'}, -- 队伍1战力
                    POWER2 = { _int = 1, _key = 'combatValue2'}, -- 队伍2战力
                    POWER3 = { _int = 1, _key = 'combatValue3'}, -- 队伍3战力
                },
            },
            PROMOTION_MATCHES   = { _map = 1, _key = 'myMatchIds',  -- 晋级赛 参加的场次
                MATCH_ID = { _int = 1, _key = '$matchId' },
            },
            PROMOTION_SCHEDULE = { _map = 1, _key = 'matches',      -- 晋级赛 赛程进度信息
                MATCH_DATA = { _map = 1, _key = '$matchId',
                    ATTACKER_ID   = { _int = 1,  _key = 'attackerId' },   -- 进攻方id（左边）
                    ATTACKER_VOTE = { _int = 1,  _key = 'attackerVote' }, -- 进攻方得票数
                    DEFENDER_ID   = { _int = 1,  _key = 'defenderId' },   -- 防守方id（右边）
                    DEFENDER_VOTE = { _int = 1,  _key = 'defenderVote' }, -- 防守方得票数
                    WINNER_ID     = { _int = 1,  _key = 'winnerId' },     -- 获胜方id，空就是还未公布
                },
            },
            GUESS_DETAIL = { _map = 1, _key = 'guess',              -- 我的竞猜信息
                GUESS_DATA = { _map = 1, _key = '$matchId',
                    PLAYER_ID = { _int = 1,  _key = 'id' },  -- 竞猜的玩家id
                    GUESS_NUM = { _int = 1,  _key = 'num' }, -- 下注的金额
                },
            },
        },
    }


    -- 历届冠军
    CHAMPIONSHIP.NETWORK.HISTORY = {
        POST = POST.CHAMPIONSHIP_MAIN,

        SEND = { _map = 1, _key = 'HISTORY_SEND',
            PAGE = { _int = 1, _key = 'page' },  -- 第几页
        },

        TAKE = { _map = 1, _key = 'HISTORY_TAKE',
            PAGE_SIZE = { _int = 1, _key = 'maxpage' }, -- 最大页数
            DATA_SIZE = { _int = 1, _key = 'range' }, -- 每页长度
            PAGE_DATA = { _lst = 1, _key = 'data', -- 每页数据
                CHAMPION_DATA = { _map = 1, _key = '$championData',
                    SEASON_ID     = { _int = 1, _key = 'seasonId' }, -- 赛季id
                    PLAYER_ID     = { _int = 1, _key = 'playerId' }, -- 玩家id
                    PLAYER_NAME   = { _str = 1, _key = 'name' },     -- 玩家名字
                    PLAYER_LEVEL  = { _int = 1, _key = 'level' },    -- 玩家等级
                    PLAYER_AVATAR = { _int = 1, _key = 'avatar' },   -- 玩家头像
                    PLAYER_FRAME  = { _int = 1, _key = 'frame' },    -- 玩家边框
                    PLAYER_UNION  = { _str = 1, _key = 'union' },    -- 玩家公会
                    TEAM1_CARDS   = { _str = 1, _key = 'cards1' },   -- 队伍1
                    TEAM2_CARDS   = { _str = 1, _key = 'cards2' },   -- 队伍2
                    TEAM3_CARDS   = { _str = 1, _key = 'cards3' },   -- 队伍3
                },
            },
        }
    }


    ------------------------------------------------- [海选赛]
    
    -- 海选赛 购买次数
    CHAMPIONSHIP.NETWORK.TICKET = {
        POST = POST.CHAMPIONSHIP_TICKET,

        SEND = { _map = 1, _key = 'TICKET_SEND',
            BUY_NUM = { _int = 1, _key = 'num' }, -- 购买数量
        },

        TAKE = { _map = 1, _key = 'TICKET_TAKE',
            TICKET_NUM  = { _int = 1, _key = 'ticket' },  -- 挑战次数
            CONSUME_ID  = { _int = 1, _key = 'goodsId' }, -- 消耗的物品id
            REFRESH_NUM = { _int = 1, _key = 'num' },     -- 物品最新数量
        },
    }


    -- 海选赛 提交编队
    CHAMPIONSHIP.NETWORK.AUDITION = {
        POST = POST.CHAMPIONSHIP_AUDITION,

        SEND = { _map = 1, _key = 'AUDITION_SEND',
            CARD_UUIDS = { _str = 1, _key = 'cardIds' }, -- 卡牌uuids，逗号分隔
        },

        TAKE = {},
    }


    -- 海选赛 排行榜
    CHAMPIONSHIP.NETWORK.RANK = {
        POST = POST.CHAMPIONSHIP_RANK,

        SEND = {},

        TAKE = { _map = 1, _key = 'RANK_TAKE',
            MY_RANK   = { _int = 1, _key = 'myRank' },  -- 海选赛 我的排名（只给前32名）
            MY_SCORE  = { _int = 1, _key = 'myScore' }, -- 海选赛 我的成绩
            RANK_LIST = { _lst = 1, _key = 'rank',      -- 海选赛 前32名
                RANK_DATA = { _map = 1, _key = '$rankData',
                    PLAYER_RANK    = { _int = 1, _key = 'rank' },              -- 排名
                    PLAYER_SCORE   = { _int = 1, _key = 'score' },             -- 得分
                    PLAYER_ID      = { _int = 1, _key = 'playerId' },          -- 玩家id
                    PLAYER_NAME    = { _str = 1, _key = 'playerName' },        -- 玩家名字
                    PLAYER_LEVEL   = { _int = 1, _key = 'playerLevel' },       -- 玩家等级
                    PLAYER_AVATAR  = { _int = 1, _key = 'playerAvatar' },      -- 玩家头像
                    PLAYER_AVATARF = { _int = 1, _key = 'playerAvatarFrame' }, -- 玩家头像框
                }
            }
        },
    }


    ------------------------------------------------- [晋级赛]

    -- 晋级赛报名
    CHAMPIONSHIP.NETWORK.PROMOTION_APPLY = {
        POST = POST.CHAMPIONSHIP_APPLY,

        SEND = { _map = 1, _key = 'APPLY_SEND',
            CARD_IDS_1  = { _str = 1, _key = 'cardIds1' },         -- 第1队卡牌id，逗号分隔
            CARD_IDS_2  = { _str = 1, _key = 'cardIds2' },         -- 第1队卡牌id，逗号分隔
            CARD_IDS_3  = { _str = 1, _key = 'cardIds3' },         -- 第1队卡牌id，逗号分隔
            CTOR_JSON_1 = { _str = 1, _key = 'constructor1' },     -- 第1队构造器，json
            CTOR_JSON_2 = { _str = 1, _key = 'constructor2' },     -- 第2队构造器，json
            CTOR_JSON_3 = { _str = 1, _key = 'constructor3' },     -- 第3队构造器，json
            LOAD_JSON_1 = { _str = 1, _key = 'loadedResources1' }, -- 第1队加载的资源表
            LOAD_JSON_2 = { _str = 1, _key = 'loadedResources2' }, -- 第2队加载的资源表
            LOAD_JSON_3 = { _str = 1, _key = 'loadedResources3' }, -- 第3队加载的资源表
        },

        TAKE = {},
    }


    -- 晋级赛对手详情
    CHAMPIONSHIP.NETWORK.PROMOTION_PLAYER = {
        POST = POST.CHAMPIONSHIP_OPPONENT_DETAIL,

        SEND = { _map = 1, _key = 'PLAYER_SEND',
            PLAYER_ID = { _int = 1, _key = 'targetId' },  -- 玩家id
        },

        TAKE = { _map = 1, _key = 'PLAYER_TAKE',
            TEAM1 = { _lst = 1, _key = 'team1', -- 队伍1信息
                CARD_DETAIL = copyStruct(FOOD.COMMON.NETWORK.CARD_DETAIL, '$cardIndex'),
            },
            TEAM2 = { _lst = 1, _key = 'team2', -- 队伍2信息
                CARD_DETAIL = copyStruct(FOOD.COMMON.NETWORK.CARD_DETAIL, '$cardIndex'),
            },
            TEAM3 = { _lst = 1, _key = 'team3', -- 队伍3信息
                CARD_DETAIL = copyStruct(FOOD.COMMON.NETWORK.CARD_DETAIL, '$cardIndex'),
            },
        },
    }


    -- 重播结果
    CHAMPIONSHIP.NETWORK.CHAMPIONSHIP_REPLAY_RESULT = {
        POST = POST.CHAMPIONSHIP_REPLAY_RESULT,

        SEND = { _map = 1, _key = 'REPLAY_RESULT_SEND',
            MATCH_ID = { _int = 1, _key = 'matchId' },
        },

        TAKE = { _map = 1, _key = 'REPLAY_RESULT_TAKE',
            RESULT = { _map = 1, _key = 'data',
                DATA = { _map = 1, _key = '$sequence',
                    ATTACKER_TEAM = { _lst = 1, _key = 'friendTeam', -- 进攻方队伍
                        CARD_DETAIL = copyStruct(FOOD.COMMON.NETWORK.CARD_DETAIL, '$cardIndex'),
                    }, 
                    DEFENDER_TEAM = { _lst = 1, _key = 'enemyTeam', -- 防守方队伍
                        CARD_DETAIL = copyStruct(FOOD.COMMON.NETWORK.CARD_DETAIL, '$cardIndex'),
                    },  
                    BATTLE_RESULT = { _int = 1, _key = 'result' },  -- 战斗结果
                }
            }
        },
    }


    -- 重播详情
    CHAMPIONSHIP.NETWORK.CHAMPIONSHIP_REPLAY_DETAIL = {
        POST = POST.CHAMPIONSHIP_REPLAY_DETAIL,

        SEND = { _map = 1, _key = 'REPLAY_DETAIL_SEND',
            MATCH_ID = { _int = 1, _key = 'matchId' },
            SEQUENCE = { _int = 1, _key = 'sequence' },
        },

        TAKE = { _map = 1, _key = 'REPLAY_DETAIL_TAKE',
            DATA = { _map = 1, _key = 'data',
                CTOR_JSON = { _str = 1, _key = 'constructor' },     -- 回放-构造json
                LOAD_JSON = { _str = 1, _key = 'loadedResources' }, -- 回放-资源json
                OPTE_JSON = { _str = 1, _key = 'playerOperate' },   -- 回放-操作json
            }
        },
    }
    

    ------------------------------------------------- [竞猜]

    -- 下注
    CHAMPIONSHIP.NETWORK.CHAMPIONSHIP_GUESS = {
        POST = POST.CHAMPIONSHIP_GUESS,

        SEND = { _map = 1, _key = 'GUESS_SEND',
            MATCH_ID = { _int = 1, _key = 'matchId' }, -- 比赛id
            GUESS_ID = { _int = 1, _key = 'guessId' }, -- 玩家id
        },

        TAKE = { _map = 1, _key = 'GUESS_TAKE',
            GUESS_NUM     = { _int = 1, _key = 'guessNum' }, -- 下注数量
            LEFT_CURRENCY = { _int = 1, _key = 'num' },      -- 剩余货币
        },
    }


    ------------------------------------------------- [商店]

    -- 商店主页
    CHAMPIONSHIP.NETWORK.SHOP_HOME = {
        POST = POST.CHAMPIONSHIP_SHOP_HOME,

        SEND = {},

        TAKE = { _map = 1, _key = 'SHOP_HOME_TAKE',
            REFRESH_DIAMOND      = { _int = 1, _key = 'refreshDiamond' },         -- 刷新钻石单价
            REFRESH_LEFT_TIEMS   = { _int = 1, _key = 'refreshLeftTimes' },       -- 刷新剩余次数
            REFRESH_LEFT_SECONDS = { _int = 1, _key = 'nextRefreshLeftSeconds' }, -- 刷新剩余秒数
            PRODUCTS             = { _lst = 1, _key = 'products',                 -- 商品列表
                PRODUCT_DATA = { _map = 1, _key = '$productData', -- 商品数据
                    PRODUCT_ID  = { _int = 1, _key = 'productId' }, -- 商品id
                    GOODS_ID    = { _int = 1, _key = 'goodsId' },   -- 道具id
                    GOODS_NUM   = { _int = 1, _key = 'goodsNum' },  -- 道具数量
                    CURRENCY_ID = { _int = 1, _key = 'currency' },  -- 货币id
                    PRICE_NUM   = { _int = 1, _key = 'price' },     -- 价格
                    PURCHASED   = { _int = 1, _key = 'purchased' }, -- 购买状态（0：未购，1：已购）
                    MULTI_SALE  = { _map = 1, _key = 'sale', -- 多售卖方式（key:货币，value:价格）
                        PRICE_NUM = { _int = 1, _key = '$price' },
                    },
                },
            },
        },
    }


    -- 商店刷新
    CHAMPIONSHIP.NETWORK.SHOP_REFRESH = {
        POST = POST.CHAMPIONSHIP_SHOP_REFRESH,

        SEND = {},

        TAKE = { _map = 1, _key = 'SHOP_REFRESH_TAKE',
            DIAMOND  = { _int = 1, _key = 'diamond' },            -- 玩家当前钻石
            PRODUCTS = CHAMPIONSHIP.NETWORK.SHOP_HOME.TAKE.PRODUCTS, -- 最新的商品列表
        },
    }


    -- 商店购买
    CHAMPIONSHIP.NETWORK.SHOP_BUY = {
        POST = POST.CHAMPIONSHIP_SHOP_BUY,

        SEND = { _map = 1, _key = 'SHOP_BUY_SEND',
            PRODUCT_ID  = { _str = 1, _key = 'productId' }, -- 商品ID
            PRODUCT_NUM = { _int = 1, _key = 'num' },       -- 商品数量
        },

        TAKE = { _map = 1, _key = 'SHOP_BUY_TAKE',
            REWARDS = { _lst = 1, _key = 'rewards', -- 奖励列表
                GOODS_DATA = { _map = 1, _key = '$goods', -- 物品数据
                    GOODS_ID  = { _int = 1, _key = 'goodsId'}, -- 物品ID
                    GOODS_NUM = { _int = 1, _key = 'num'},     -- 物品数量
                },
            },
        },
    }


    -- 商店批量购买
    CHAMPIONSHIP.NETWORK.SHOP_MULTI_BUY = {
        POST = POST.CHAMPIONSHIP_SHOP_MULTI_BUY,

        SEND = { _map = 1, _key = 'SHOP_MULTI_BUY_SEND',
            PRODUCT_IDS = { _str = 1, _key = 'products' },  -- 商品ID们（逗号分隔）
        },

        TAKE = { _map = 1, _key = 'SHOP_MULIT_BUY_TAKE',
            REWARDS = CHAMPIONSHIP.NETWORK.SHOP_BUY.TAKE.REWARDS, -- 奖励列表
        },
    }

end


-------------------------------------------------------------------------------
-- 主页相关
-------------------------------------------------------------------------------
do
    CHAMPIONSHIP.MAIN = {}

    CHAMPIONSHIP.MAIN.PROXY_NAME = 'CHAMPIONSHIP.MAIN.PROXY_NAME'

    CHAMPIONSHIP.MAIN.PROXY_STRUCT = { _map = 1, _key = CHAMPIONSHIP.MAIN.PROXY_NAME,
        MAIN_HOME_TAKE        = CHAMPIONSHIP.NETWORK.MAIN.TAKE,                                          -- 主界面 接收数据
        TICKET_BUY_SEND       = CHAMPIONSHIP.NETWORK.TICKET.SEND,                                        -- 海选赛-购买次数 发送数据
        TICKET_BUY_TAKE       = CHAMPIONSHIP.NETWORK.TICKET.TAKE,                                        -- 海选赛-购买次数 接收数据
        AUDITION_TEAM_SEND    = CHAMPIONSHIP.NETWORK.AUDITION.SEND,                                      -- 海选赛-设置编队 发送数据
        PROMOTION_APPLY_SEND  = CHAMPIONSHIP.NETWORK.PROMOTION_APPLY.SEND,                               -- 晋级赛-提交编队 发送数据
        PROMOTION_PLAYER_SEND = CHAMPIONSHIP.NETWORK.PROMOTION_PLAYER.SEND,                              -- 晋级赛-玩家详情 发送数据
        PROMOTION_PLAYER_TAKE = CHAMPIONSHIP.NETWORK.PROMOTION_PLAYER.TAKE,                              -- 晋级赛-玩家详情 接收数据
        CHAMPION_PLAYER_SEND  = copyStruct(CHAMPIONSHIP.NETWORK.PROMOTION_PLAYER.SEND, 'CHAMPION_SEND'), -- 晋级赛-冠军详情 发送数据
        CHAMPION_PLAYER_TAKE  = copyStruct(CHAMPIONSHIP.NETWORK.PROMOTION_PLAYER.TAKE, 'CHAMPION_TAKE'), -- 晋级赛-冠军详情 接收数据
        REFRESH_TIMESTAMP     = { _int = 1, _key = 'refreshTimestamp' },                                 -- 状态刷新的时间戳
        REFRESH_COUNTDOWN     = { _int = 1, _key = 'refreshCountdown' },                                 -- 状态刷新剩余时间
    }
end


-------------------------------------------------------------------------------
-- 海选赛排行榜
-------------------------------------------------------------------------------
do
    CHAMPIONSHIP.RANK = {}

    CHAMPIONSHIP.RANK.PROXY_NAME = 'CHAMPIONSHIP.RANK.PROXY_NAME'

    CHAMPIONSHIP.RANK.PROXY_STRUCT = { _map = 1, _key = CHAMPIONSHIP.RANK.PROXY_NAME,
        RANK_TAKE     = CHAMPIONSHIP.NETWORK.RANK.TAKE, -- 海选赛-排行榜 接收数据
    }
end


-------------------------------------------------------------------------------
-- 商店相关
-------------------------------------------------------------------------------
do
    CHAMPIONSHIP.SHOP = {}

    CHAMPIONSHIP.SHOP.PROXY_NAME = 'CHAMPIONSHIP.SHOP.PROXY_NAME'

    CHAMPIONSHIP.SHOP.PROXY_STRUCT = { _map = 1, _key = CHAMPIONSHIP.SHOP.PROXY_NAME,
        SHOP_HOME_TAKE      = CHAMPIONSHIP.NETWORK.SHOP_HOME.TAKE,      -- 商店-主页 接收数据
        SHOP_REFRESH_TAKE   = CHAMPIONSHIP.NETWORK.SHOP_REFRESH.TAKE,   -- 商店-刷新 接收数据
        SHOP_BUY_TAKE       = CHAMPIONSHIP.NETWORK.SHOP_BUY.TAKE,       -- 商店-购买 接收数据
        SHOP_BUY_SEND       = CHAMPIONSHIP.NETWORK.SHOP_BUY.SEND,       -- 商店-购买 发送数据
        SHOP_MULTI_BUY_TAKE = CHAMPIONSHIP.NETWORK.SHOP_MULTI_BUY.TAKE, -- 商店-批量买 接收数据
        SHOP_MULTI_BUY_SEND = CHAMPIONSHIP.NETWORK.SHOP_MULTI_BUY.SEND, -- 商店-批量买 发送数据
        REFRESH_TIMESTAMP   = { _int = 1, _key = 'refreshTimestamp' },  -- 商店刷新的时间戳
        SELECT_PRODUCT_MAP  = { _map = 1, _key = 'selectProductMap',    -- 选择的商品id表 [key:productId]
            SELECTED = { _bol = 1, _key = '$isSelected' }
        },
    }
end


-------------------------------------------------------------------------------
-- 历届冠军
-------------------------------------------------------------------------------
do
    CHAMPIONSHIP.HISTORY = {}

    CHAMPIONSHIP.HISTORY.PROXY_NAME = 'CHAMPIONSHIP.HISTORY.PROXY_NAME'

    CHAMPIONSHIP.HISTORY.PROXY_STRUCT = { _map = 1, _key = CHAMPIONSHIP.HISTORY.PROXY_NAME,
        HISTORY_TAKE    = CHAMPIONSHIP.NETWORK.HISTORY.TAKE,    -- 历届冠军 接收数据
        HISTORY_SEND    = CHAMPIONSHIP.NETWORK.HISTORY.SEND,    -- 历届冠军 发送数据
        LOADED_PAGE_NUM = { _int = 1, _key = 'loadedPageNum' }, -- 已加载的页数
        LOADED_DATA_NUM = { _int = 1, _key = 'loadedDataNum' }, -- 已加载的数量
    }
end


-------------------------------------------------------------------------------
-- 晋级赛战报
-------------------------------------------------------------------------------
do
    CHAMPIONSHIP.REPORT = {}

    CHAMPIONSHIP.REPORT.TYPE = {
        BATTLE = 'battle',  -- 战报
        GUESS  = 'guess',   -- 竞猜
    }

    CHAMPIONSHIP.REPORT.PROXY_NAME = 'CHAMPIONSHIP.REPORT.PROXY_NAME'

    CHAMPIONSHIP.REPORT.PROXY_STRUCT = { _map = 1, _key = CHAMPIONSHIP.REPORT.PROXY_NAME,
        REPORT_TYPE       = { _str = 1, _key = 'reportType' }, -- 报告类型
        PROMOTION_MATCHES = { _lst = 1, _key = 'matchIds',     -- 晋级赛 参加的场次
            MATCH_ID = { _int = 1, _key = '$matchId' },
        },
    }
end


-------------------------------------------------------------------------------
-- 晋级赛回看
-------------------------------------------------------------------------------
do
    CHAMPIONSHIP.REPLAY = {}

    CHAMPIONSHIP.REPLAY.PROXY_NAME = 'CHAMPIONSHIP.REPLAY.PROXY_NAME'

    CHAMPIONSHIP.REPLAY.PROXY_STRUCT = { _map = 1, _key = CHAMPIONSHIP.REPLAY.PROXY_NAME,
        REPLAY_RESULT_SEND = CHAMPIONSHIP.NETWORK.CHAMPIONSHIP_REPLAY_RESULT.SEND, -- 回放-结果 发送数据
        REPLAY_RESULT_TAKE = CHAMPIONSHIP.NETWORK.CHAMPIONSHIP_REPLAY_RESULT.TAKE, -- 回放-结果 接收数据
        REPLAY_DETAIL_SEND = CHAMPIONSHIP.NETWORK.CHAMPIONSHIP_REPLAY_DETAIL.SEND, -- 回放-详情 发送数据
        REPLAY_DETAIL_TAKE = CHAMPIONSHIP.NETWORK.CHAMPIONSHIP_REPLAY_DETAIL.TAKE, -- 回放-详情 接收数据
        REPLAY_MATCH_ID    = { _int = 1, _key = 'replayMatchId' },                 -- 回放的场次id
        ATTACKER_ID        = { _int = 1, _key = 'attackerId' },                    -- 进攻方id
        DEFENDER_ID        = { _int = 1, _key = 'defenderId' },                    -- 防守方id
    }
end


-------------------------------------------------------------------------------
-- 玩家详情
-------------------------------------------------------------------------------
do
    CHAMPIONSHIP.PLAYER_DETAIL = {}

    CHAMPIONSHIP.PLAYER_DETAIL.TYPE = {
        VIEW = 'view',  -- 查看
        VOTE = 'vote',  -- 投票
    }

    CHAMPIONSHIP.PLAYER_DETAIL.PROXY_NAME = 'CHAMPIONSHIP.PLAYER_DETAIL.PROXY_NAME'

    CHAMPIONSHIP.PLAYER_DETAIL.PROXY_STRUCT = { _map = 1, _key = CHAMPIONSHIP.PLAYER_DETAIL.PROXY_NAME,
        PLAYER_SEND = CHAMPIONSHIP.NETWORK.PROMOTION_PLAYER.SEND,   -- 玩家详情 发送数据
        PLAYER_TAKE = CHAMPIONSHIP.NETWORK.PROMOTION_PLAYER.TAKE,   -- 玩家详情 接收数据
        GUESS_SEND  = CHAMPIONSHIP.NETWORK.CHAMPIONSHIP_GUESS.SEND, -- 投票竞猜 发送数据
        GUESS_TAKE  = CHAMPIONSHIP.NETWORK.CHAMPIONSHIP_GUESS.TAKE, -- 投票竞猜 接收数据
        DETAIL_TYPE = { _str = 1, _key = 'detailType' },            -- 详情类型
        PLAYER_ID   = { _int = 1, _key = 'playerId' },              -- 玩家id
        MATCH_ID    = { _int = 1, _key = 'matchId' },               -- 比赛id
    }
end


return CHAMPIONSHIP
