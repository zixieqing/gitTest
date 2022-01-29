--[[
战斗全局定义 定义一些全局的常量 方法
--]]

---------------------------------------------------
-- data --
---------------------------------------------------

------------ define ------------
-- 战斗文件夹
BattleFolder = {
	BATTLE_NEW = 'battle_new',
	BATTLE_OLD = 'battle_old'
}

-- 真正使用的battle文件夹路径
local Battle_Folder = BattleFolder.BATTLE_NEW

-- 保存require过的类名
local Loaded_Class_Path = {}
------------ define ------------

--[[
获取使用的battle文件夹路劲
--]]
function GetBattleFolder()
	return Battle_Folder
end
function SetBattleFolder(folder)
	-- 释放一次package
	if folder ~= Battle_Folder then
		RecycleBattleRequire()
	end

	Battle_Folder = folder

	-- require一次定义全局常量的文件 刷一次老的全局常量
	__Require('battle.defines.BattleImportDefine')
end
--[[
释放一次package失效的文件
--]]
function RecycleBattleRequire()
	for classPath, valid in pairs(Loaded_Class_Path) do
		if true == valid then
			-- 回收失效的require
			package.loaded[classPath] = nil
			package.preload[classPath] = nil
		end
	end
	-- 清空一次loaded的文件
	Loaded_Class_Path = {}
end

--[[
添加一个require过的battle文件路径
@params classPath string 路径
--]]
function AddABattleClass(classPath)
	if nil == Loaded_Class_Path[classPath] then
		Loaded_Class_Path[classPath] = true
	end
end

---------------------------------------------------
-- constants --
---------------------------------------------------

---------------------------------------------------
-- functions --
---------------------------------------------------

--[[
根据传入的require类路径获取完整的文件路径
@params path string 源路径
@return _ string 全路径
--]]
function _GBC(path)
	-- 最终的前缀
	local fixedHeadPath = GetBattleFolder()
	-- 判定的前缀
	local headPath_ = 'battle'
	-- 最终的路径
	local fixedPath = nil

	local targetHeadPath = string.split(path, '.')[1]

	if headPath_ == targetHeadPath then
		fixedPath = fixedHeadPath .. '.' .. string.split(path, (headPath_ .. '.'))[2]
	else
		fixedPath = path
	end

	-- 记录一次文件
	AddABattleClass(fixedPath)

	return fixedPath
end

--[[
require一个战斗文件
@params path
@return table
--]]
function __Require(path)
	return require(_GBC(path))
end
