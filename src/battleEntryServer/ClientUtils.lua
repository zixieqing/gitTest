--[[
重写客户端的一些工具方法
--]]

-- cocos定义的一些lua方法
require('cocos.cocos2d.functions')
require('cocos.cocos2d.Cocos2d')

-- common utils的定义
CommonUtils = {}
require('battleEntryServer.ConfigUtils')
require('battleEntry.BattleCommonUtils')
RBQN = require('battleEntryServer.RBQNumber')

-- 一些debug配置
DEBUG_MEM = true

--[[
对表进行排序，是否是降序
@params t table 目标表
@params asc bool 是否是降序
--]]
function sortByKey(t, asc)
    local temp = {}
    for key,_ in pairs(t) do table.insert(temp,key) end
    if asc then
        table.sort(temp,function(a,b) return checkint(a) > checkint(b) end)
    else
        table.sort(temp,function(a,b) return checkint(a) < checkint(b) end)
    end
    return temp
end

---------------------------------------------------
-- 初始化logger begin --
---------------------------------------------------
Logger = {}
function funLog(level, message, traceback)
    print(message)
end
---------------------------------------------------
-- 初始化logger end --
---------------------------------------------------

---------------------------------------------------
-- 客户端常量的定义 --
---------------------------------------------------
-- spine的定义
sp = {}
sp.EventType =
{
    ANIMATION_START = 0, 
    ANIMATION_END = 1, 
    ANIMATION_COMPLETE = 2, 
    ANIMATION_EVENT = 3,
}

-- 卡牌语音类型
SoundType = {
    TYPE_GET_CARD         = 1,  --卡牌获得
    TYPE_HOME_CARD_CHANGE = 2,  --主界面更换人物时说话
    TYPE_TOUCH            = 3,  --主界面立绘、经营主管、图鉴鉴赏触摸台词
    TYPE_JIEHUN           = 4,  --结婚后添加至触摸类型3的台词库
    TYPE_ICEROOM_TOUCH    = 5,  --冰场中进行触摸互动时播放
    TYPE_SKILL2           = 6,  --技能2释放
    TYPE_UPGRADE_STAR     = 7,  --卡牌升星时
    TYPE_CAN_NOT_BATTLE   = 8,  --疲劳值不满足出战需求时
    TYPE_ICEROOM_RANDOM   = 9,  --被配置在冰场中的角色，不被触摸的情况下每8~15秒随机播放
    TYPE_TEAM             = 10, --配置到编队中
    TYPE_TEAM_CAPTAIN     = 11, --设置为队长时
    TYPE_BATTLE_DIE       = 12, --死亡时
    TYPE_QI_YUE           = 13, --缔结契约时
    TYPE_COOKED           = 14, -- 有菜品完成
    TYPE_KAN_BAN          = 15, --设置为功能看板娘时，在5秒~10秒无操作时，随机播放
    TYPE_HOME             = 16, --设置为主界面时，在10秒~15秒无操作时，随机播放
}

-- 音频定义
---@class AUDIOS2 : AUDIOS
AUDIOS = {
    -- BMG音乐
    BGM = { name = 'BGM', acb = 'music/BGM/BGM.acb', awb = 'music/BGM/BGM.awb',
        Food_Battle  = { id = 'food_battle',          descr = '普通战斗音乐' },
    },
}
---------------------------------------------------
-- 客户端常量的定义 --
---------------------------------------------------











