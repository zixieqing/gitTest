--[[
preload 一些战斗需要的文件
--]]

-- 战斗的常量定义
__Require('battle.controller.BattleConstants')

-- 战斗基础数据结构
__Require('battle.battleStruct.BaseStruct')

-- 战斗物体数据结构
__Require('battle.battleStruct.ObjStruct')

-- 战斗公式定义
__Require('battle.controller.BattleExpression')

-- 战斗工具
__Require('battle.util.BattleUtils')

-- 战斗配表数据转换工具
__Require('battle.util.BattleStructConvertUtils')

-- 战斗配置工具
__Require('battle.util.BattleConfigUtils')

-- 战斗字符串工具
__Require('battle.util.BStringUtils')

-- 战斗资源工具
__Require('battle.util.BattleResUtils')