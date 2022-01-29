--[[
lua战斗入口
--]]

------------ import ------------
-- 引用一些客户端环境的文件
require('battleEntryServer.ServerHeadImport')
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- search path handle begin --
---------------------------------------------------
-- 将当前目录加入search path
local currentPath = lfs.currentdir()
print('here check current file dir<<<<<<', currentPath)
AddLuaSearchPath(currentPath)


---------------------------------------------------
-- search path handle end --
---------------------------------------------------



---------------------------------------------------
-- global import begin --
---------------------------------------------------
-- 战斗全局定义
require('battleEntry.BattleGlobalDefines')


---------------------------------------------------
-- global import end --
---------------------------------------------------



---------------------------------------------------
-- check begin --
---------------------------------------------------
G_BattleChecker = require('battleEntryServer.BattleChecker').new()
-- G_BattleChecker:DebugBattle()
---------------------------------------------------
-- check end --
---------------------------------------------------










print('战斗运行完毕')