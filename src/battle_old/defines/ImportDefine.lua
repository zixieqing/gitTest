--[[
需要import的文件
--]]

cc = {}
sp = {}

-- 常量定义
__Require('battle.defines.ConstantsDefine')

-- cocos2dx的一些定义
json = require('cocos.framework.json')
require('cocos.cocos2d.functions')
require('cocos.cocos2d.Cocos2d')
require('cocos.spine.SpineConstants')

-- 战斗定义相关
__Require('battle.controller.BattleConstants')
__Require('battle.battleStruct.BaseStruct')
__Require('battle.battleStruct.ObjStruct')

-- 一些重写函数定义
__Require('battle.defines.FunctionDefine')

-- 工具类
__Require('battle.defines.ConfigUtils')
require('Game.utils.CardUtils')
require('Game.utils.PetUtils')
