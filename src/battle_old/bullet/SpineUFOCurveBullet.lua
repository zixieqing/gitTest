--[[
抛物线飞行物
起点为原点 x轴交点做抛物线为终点 前半做抛物线 后半做直线插值
--]]
local SpineUFOBullet = __Require('battle.bullet.SpineUFOBullet')
local SpineUFOCurveBullet = class('SpineUFOCurveBullet', SpineUFOBullet)
--[[
@override
初始化抛物线参数
--]]
function SpineUFOCurveBullet:initValue()
	SpineUFOBullet.initValue(self)

	local targetCB = self.p.targetCollisionBox
	local targetCBCenter = cc.p(targetCB.x + targetCB.width * 0.5, targetCB.y + targetCB.height * 0.5)
	targetCBCenter = BMediator:GetBattleRoot():convertToNodeSpace(targetCBCenter)

	-- 计算抛物线顶点
	self.curveData = {
		pointA = self.args.oriLocation,
		pointB = targetCBCenter,
		pointDelta = cc.pSub(targetCBCenter, self.args.oriLocation),
		pointCurveTop = nil,
		a = 0,
		b = 0,
		sin_convert = 0,
		cos_concert = 0,
		towards = targetCBCenter.x >= self.args.oriLocation.x and 1 or -1,
	}
	local pointOri = cc.p(0, 0)
	local disAtoB = cc.pGetDistance(self.curveData.pointA, self.curveData.pointB)
	local pointXCross = cc.p(self.curveData.towards * disAtoB, 0)
	local pointTop = cc.p((pointOri.x + pointXCross.x) * 0.5, disAtoB * 0.25)

	self.curveData.pointCurveTop = pointTop
	self.curveData.sin_convert = -self.curveData.towards * (self.curveData.pointDelta.y) / disAtoB
	self.curveData.cos_concert = self.curveData.towards * (self.curveData.pointDelta.x) / disAtoB
	self.curveData.a = pointTop.y / (pointTop.x * (pointTop.x - pointXCross.x))
	self.curveData.b = -self.curveData.a * pointXCross.x

	self.moveData = {
		x = 0,
		speed = BMediator:GetBConf().cellSize.width * 30,
		lerpA = 0.3,
	}

	-- local pamount = 20
	-- for i = 1, pamount do
	-- 	local p = self:convertCurvePosToBattleArea(self:getPAtCurve(self.curveData.towards * i / pamount * disAtoB))
	-- 	local debugs = display.newNSprite(_res('ui/common/common_hint_circle_red_ico.png'),
	-- 		p.x,
	-- 		p.y)
	-- 	BMediator:GetBattleRoot():addChild(debugs, 99999)
	-- end
end
--[[
根据x坐标获取抛物线上的y坐标
@params number x 已知的x坐标
@return _ cc.p 目标点坐标
--]]
function SpineUFOCurveBullet:getPAtCurve(x)
	local y = self.curveData.a * x * x + self.curveData.b * x
	return cc.p(x, y)
end
--[[
从抛物线坐标系转换到战场坐标
@params p cc.p 待转换坐标
@return result cc.p 战场坐标
--]]
function SpineUFOCurveBullet:convertCurvePosToBattleArea(p)
	local x_ = p.x * self.curveData.cos_concert + p.y * self.curveData.sin_convert
	local y_ = p.y * self.curveData.cos_concert - p.x * self.curveData.sin_convert
	local result = cc.p(x_, y_)
	-- 加上原点偏移向量
	result = cc.pAdd(result, self.curveData.pointA)
	return result
end
--[[
@override
跑路行为
@params target obj 目标
@params dt number delta time
--]]
function SpineUFOCurveBullet:move(targetTag, dt)
	if self.curveData.towards * self.moveData.x >= self.curveData.towards * self.curveData.pointCurveTop.x * 1.9 then
		local targetCB = self.p.targetCollisionBox
		local targetCBCenter = cc.p(targetCB.x + targetCB.width * 0.5, targetCB.y + targetCB.height * 0.5)
		targetCBCenter = self.view.viewComponent:getParent():convertToNodeSpace(targetCBCenter)
		local alpha = math.min(1, self.moveData.lerpA * (math.abs(self.moveData.x) / self.moveData.speed * 6) * BMediator:GetTimeScale())
		local deltaP = cc.pSub(targetCBCenter, self:getLocation().po)
		if (deltaP.x * deltaP.x + deltaP.y * deltaP.y) <= BMediator:GetBConf().cellSize.width then
			alpha = 1
		end
		local p = cc.pLerp(self:getLocation().po, targetCBCenter, alpha)
		self.view.viewComponent:setPosition(p)
		self.moveData.x = self.moveData.x + (p.x - self:getLocation().po.x)
		self:updateLocation()
	else
		self.moveData.x = self.moveData.x + dt * self.curveData.towards * self.moveData.speed
		self.view.viewComponent:setPosition(self:convertCurvePosToBattleArea(self:getPAtCurve(self.moveData.x)))
		self:updateLocation()
	end

	-- debug --
	-- local targetCB = self.p.targetCollisionBox
	-- local targetCBCenter = cc.p(targetCB.x + targetCB.width * 0.5, targetCB.y + targetCB.height * 0.5)
	-- targetCBCenter = self.view.viewComponent:getParent():convertToNodeSpace(targetCBCenter)

	-- local selfcb = self:getCollisionBoxInWorldSpace()
	-- local p = self.view.viewComponent:getParent():convertToNodeSpace(cc.p(selfcb.x, selfcb.y))
	-- local debugl = display.newLayer(p.x, p.y,
	-- 	{size = cc.size(selfcb.width, selfcb.height), color = '#34ff90'})
	-- self.view.viewComponent:getParent():addChild(debugl, 9999)
	-- debugl:setOpacity(100)

	-- local debugs = display.newNSprite(_res('ui/common/common_hint_circle_red_ico.png'),
	-- 	-- targetCBCenter.x,
	-- 	-- targetCBCenter.y)
	-- 	self:getLocation().po.x,
	-- 	self:getLocation().po.y)
	-- 	-- self:convertCurvePosToBattleArea(self.curveData.pointCurveTop).x,
	-- 	-- self:convertCurvePosToBattleArea(self.curveData.pointCurveTop).y)
	-- self.view.viewComponent:getParent():addChild(debugs, 99999)

	-- local debugs = display.newNSprite(_res('ui/common/common_hint_circle_red_ico.png'),
	-- 	-- targetCBCenter.x,
	-- 	-- targetCBCenter.y)
	-- 	-- self:getLocation().po.x,
	-- 	-- self:getLocation().po.y)
	-- 	self.curveData.pointA.x,
	-- 	self.curveData.pointA.y)
	-- self.view.viewComponent:getParent():addChild(debugs, 99999)

	-- local debugs = display.newNSprite(_res('ui/common/common_hint_circle_red_ico.png'),
	-- 	-- targetCBCenter.x,
	-- 	-- targetCBCenter.y)
	-- 	-- self:getLocation().po.x,
	-- 	-- self:getLocation().po.y)
	-- 	self.curveData.pointB.x,
	-- 	self.curveData.pointB.y)
	-- self.view.viewComponent:getParent():addChild(debugs, 99999)
	-- debug --

end
--[[
抛物线类型不修正旋转
@params oriPos cc.p 原始坐标
@params targetPos cc.p 目标坐标
--]]
function SpineUFOCurveBullet:fixRotate(oriPos, targetPos)

end

return SpineUFOCurveBullet
