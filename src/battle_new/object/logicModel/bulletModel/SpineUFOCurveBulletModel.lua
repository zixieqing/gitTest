--[[
spine直线投掷物子弹
@params {
	objinfo ObjectSendBulletData 子弹的构造数据
}
--]]
local SpineUFOBulletModel = __Require('battle.object.logicModel.bulletModel.SpineUFOBulletModel')
local SpineUFOCurveBulletModel = class('SpineUFOCurveBulletModel', SpineUFOBulletModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化特有属性
--]]
function SpineUFOCurveBulletModel:InitUnitProperty()
	SpineUFOBulletModel.InitUnitProperty(self)

	-- 初始化抛物线轨迹相关的数据
	local targetCBInBattleRoot = self:GetTargetStaticCollisionBoxInBattleRoot()
	local targetCenterPos = cc.p(
		targetCBInBattleRoot.x + targetCBInBattleRoot.width * 0.5,
		targetCBInBattleRoot.y + targetCBInBattleRoot.height * 0.5
	)
	local selfOriLocation = self:GetObjInfo().oriLocation

	self.curveData = {
		pointA = cc.p(selfOriLocation.x, selfOriLocation.y),
		pointB = cc.p(targetCenterPos.x, targetCenterPos.y),
		pointDelta = cc.pSub(targetCenterPos, selfOriLocation),
		pointCurveTop = nil,
		a = 0,
		b = 0,
		sin_convert = 0,
		cos_convert = 0,
		towardsSign = targetCenterPos.x >= selfOriLocation.x and 1 or -1
	}
	local pointOri = cc.p(0, 0)
	local disAtoB = cc.pGetDistance(self.curveData.pointA, self.curveData.pointB)
	local pointXCross = cc.p(self.curveData.towardsSign * disAtoB, 0)
	local pointTop = cc.p((pointOri.x + pointXCross.x) * 0.5, disAtoB * 0.25)

	self.curveData.pointCurveTop = pointTop
	self.curveData.sin_convert = -self.curveData.towardsSign * (self.curveData.pointDelta.y) / disAtoB
	self.curveData.cos_concert = self.curveData.towardsSign * (self.curveData.pointDelta.x) / disAtoB
	self.curveData.a = pointTop.y / (pointTop.x * (pointTop.x - pointXCross.x))
	self.curveData.b = -self.curveData.a * pointXCross.x

	self.moveData = {
		x = 0,
		speed = G_BattleLogicMgr:GetBConf().cellSize.width * 30,
		lerpA = 0.3,
	}
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- attack begin --
---------------------------------------------------
--[[
运动轨迹
@params dt number delta time
--]]
function SpineUFOCurveBulletModel:Move(dt)
	if self.curveData.towardsSign * self.moveData.x >= self.curveData.towardsSign * self.curveData.pointCurveTop.x * 1.9 then
		local targetCBInBattleRoot = self:GetTargetStaticCollisionBoxInBattleRoot()
		local targetCenterPos = cc.p(
			targetCBInBattleRoot.x + targetCBInBattleRoot.width * 0.5,
			targetCBInBattleRoot.y + targetCBInBattleRoot.height * 0.5
		)

		local alpha = math.min(1, self.moveData.lerpA * (math.abs(self.moveData.x) / self.moveData.speed * 6))-- * G_BattleLogicMgr:GetCurrentTimeScale())
		local deltaP = cc.pSub(targetCenterPos, self:GetLocation().po)
		if (deltaP.x * deltaP.x + deltaP.y * deltaP.y) <= G_BattleLogicMgr:GetBConf().cellSize.width then
			alpha = 1
		end

		local finalPos = cc.pLerp(self:GetLocation().po, targetCenterPos, alpha)

		self:ChangePosition(finalPos)

		--***---------- 刷新渲染层 ----------***--
		self:RefreshRenderViewPosition()
		--***---------- 刷新渲染层 ----------***--
	else
		self.moveData.x = self.moveData.x + dt * self.curveData.towardsSign * self.moveData.speed

		local finalPos = self:ConvertCurvePosToBattleArea(self:GetPAtCurve(self.moveData.x))

		self:ChangePosition(finalPos)

		--***---------- 刷新渲染层 ----------***--
		self:RefreshRenderViewPosition()
		--***---------- 刷新渲染层 ----------***--
	end
end
---------------------------------------------------
-- attack end --
---------------------------------------------------

---------------------------------------------------
-- transform begin --
---------------------------------------------------
--[[
修正旋转
@params oriPos cc.p 原始坐标
@params targetPos cc.p 目标坐标
--]]
function SpineUFOCurveBulletModel:FixRotate(oriPos, targetPos)
	-- 抛物线投掷物不处理旋转
end
---------------------------------------------------
-- transform end --
---------------------------------------------------

---------------------------------------------------
-- curve calc begin --
---------------------------------------------------
--[[
根据x坐标获取抛物线上的y坐标
@params number x 已知的x坐标
@return _ cc.p 目标点坐标
--]]
function SpineUFOCurveBulletModel:GetPAtCurve(x)
	local y = self.curveData.a * x * x + self.curveData.b * x
	return cc.p(x, y)
end
--[[
从抛物线坐标系转换到战场坐标
@params p cc.p 待转换坐标
@return result cc.p 战场坐标
--]]
function SpineUFOCurveBulletModel:ConvertCurvePosToBattleArea(p)
	local x_ = p.x * self.curveData.cos_concert + p.y * self.curveData.sin_convert
	local y_ = p.y * self.curveData.cos_concert - p.x * self.curveData.sin_convert
	local result = cc.p(x_, y_)
	-- 加上原点偏移向量
	result = cc.pAdd(result, self.curveData.pointA)
	return result
end
---------------------------------------------------
-- curve calc end --
---------------------------------------------------

return SpineUFOCurveBulletModel
