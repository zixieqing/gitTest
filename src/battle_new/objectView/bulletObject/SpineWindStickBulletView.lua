--[[
回旋镖投掷物 渲染层模型
@params t table {
	tag int obj view tag 此tag与战斗物体逻辑层tag对应
	viewInfo BulletViewConstructorStruct 渲染层构造数据
}
--]]
local BaseSpineBulletView = __Require('battle.objectView.bulletObject.BaseSpineBulletView')
local SpineWindStickBulletView = class('SpineWindStickBulletView', BaseSpineBulletView)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

return SpineWindStickBulletView
