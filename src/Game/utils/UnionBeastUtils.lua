--[[
工会神兽工具类
--]]
UnionBeastUtils = {}

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

-------------------------------------------------
-- union pet config --
-------------------------------------------------

--[[
根据id获取工会神兽的配置信息
@params unionPetId int 工会神兽id
@return _ table 配表信息
--]]
function UnionBeastUtils:GetUnionPetConfig(unionPetId)
	return CommonUtils.GetConfig('union', 'godBeastAttr', unionPetId)
end
