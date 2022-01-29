--[[
服务器lua战斗的一些定义
--]]
------------ import ------------
-- lua的一些第三方库
require('lfs')
json = require('cocos.framework.json')-- require('cjson')

-- 客户端的一些工具类
require('battleEntryServer.ClientUtils')
------------ import ------------

------------ define ------------
------------ define ------------

--[[
添加一个lua的search path
@params path string
--]]
function AddLuaSearchPath(path)
	package.path = package.path .. ';' .. path
end

--[[
服务器模式输出一条log
@params str string log内容
--]]
function serveralog(str)
	print('\n>>>>>########################################\n' .. str .. '\n<<<<<########################################\n')
end