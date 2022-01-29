--[[
 * author : kaishiqi
 * descpt : 通用设定 相关定义
]]
local COMMON = {}

-------------------------------------------------------------------------------
-- 网络协议
-------------------------------------------------------------------------------
do
    COMMON.NETWORK = {}

    ------------------------------------------------- [卡牌详情]
    COMMON.NETWORK.CARD_DETAIL = { _map = 1, _key = 'COMMON_CARD_DETAIL',
        UUID            = { _int = 1, _key = 'id' },                -- 数据id
        PLAYER_ID       = { _int = 1, _key = 'playerId' },          -- 玩家id
        CARD_ID         = { _int = 1, _key = 'cardId' },            -- 卡牌id
        CARD_LEVEL      = { _int = 1, _key = 'level' },             -- 卡牌等级
        DEFAULT_SKIN_ID = { _int = 1, _key = 'defaultSkinId' },     -- 默认皮肤id
        CARD_BREAK_LV   = { _int = 1, _key = 'breakLevel' },        -- 卡牌突破等级
        PLAYER_PET_ID   = { _int = 1, _key = 'playerPetId' },       -- 玩家自身的宠物
        FAVOR_LEVEL     = { _int = 1, _key = 'favorabilityLevel' }, -- 好感度等级
        FAVOR_POINT     = { _int = 1, _key = 'favorability' },      -- 卡牌好感度
        EXP             = { _int = 1, _key = 'exp' },               -- 卡牌经验
        VIGOUR          = { _int = 1, _key = 'vigour' },            -- 卡牌新鲜度
        ARTIFACT_UNLOCK = { _int = 1, _key = 'isArtifactUnlock' },  -- 卡牌神器是否解锁
        ATTACK          = { _int = 1, _key = 'attack' },            --
        DEFENCE         = { _int = 1, _key = 'defence' },           --
        HP              = { _int = 1, _key = 'hp' },                --
        CRIT_RATE       = { _int = 1, _key = 'critRate' },          --
        CRIT_DAMAGE     = { _int = 1, _key = 'critDamage' },        --
        ATTACK_RATE     = { _int = 1, _key = 'attackRate' },        --
        SKILL           = { _map = 1, _key = 'skill',               -- 卡牌技能
            SKILL_DATA = { _map = 1, _key = '$skillId', -- 技能id
                SKILL_LEVEL = { _int = 1, _key = 'level' }, -- 技能等级
            }
        },
        PET_MAP         = { _map = 1, _key = 'pets',                -- 装备的宠物
            PET_DATA = { _map = 1, _key = '$slot',
                PET_UUID      = { _int = 1, _key = 'playerPetId' }, -- 数据id
                PET_ID        = { _int = 1, _key = 'petId' },       -- 宠物id
                PET_LEVEL     = { _int = 1, _key = 'level' },       -- 宠物等级
                PET_BREAK_LV  = { _int = 1, _key = 'breakLevel' },  -- 宠物突破等级
                PET_CHARACTER = { _int = 1, _key = 'character' },   -- 宠物品质
                IS_EVOLUTION  = { _int = 1, _key = 'isEvolution' }, -- 是否进化（1：是，0：否）
                PET_ATTR_LIST = { _lst = 1, _key = 'attr',          -- 宠物属性列表
                    ARRT_DATA = { _map = 1, _key = '$petIndex',
                        ARRT_TYPE    = { _int = 1, _key = 'type' },    -- 属性类型
                        ARRT_NUM     = { _int = 1, _key = 'num' },     -- 属性数值
                        ARRT_QUALITY = { _int = 1, _key = 'quality' }, -- 属性质量
                    }
                }
            }
        },
        ARTIFACT_MAP = { _map = 1, _key = 'artifactTalent',         -- 神器天赋
            ARTIFACT_DATA = { _map = 1, _key = '$talentIdx',
                TALENT_UUID  = { _int = 1, _key = 'id' },           -- 天赋uuid
                TALENT_ID    = { _int = 1, _key = 'talentId' },     -- 天赋id
                TALENT_TYPE  = { _int = 1, _key = 'type' },         -- 天赋类型
                TALENT_LEVEL = { _int = 1, _key = 'level' },        -- 天赋等级
                GEMSTONE_ID  = { _int = 1, _key = 'gemstoneId' },   -- 宝石id
                PLAYER_ID    = { _int = 1, _key = 'playerId' },     -- 所属玩家
                CARD_ID      = { _int = 1, _key = 'playerCardId' }, -- 所属卡牌
                FRAGMENT_NUM = { _int = 1, _key = 'fragmentNum' },  -- 碎片数量
            }
        },
        BOOK_MAP = { _map = 1, _key = 'bookLevel',                  -- 卡牌收集册加成
            BOOK_LEVEL = { _int = 1, _key = '$level' },             -- 技能等级
        }
    }

end

return COMMON
