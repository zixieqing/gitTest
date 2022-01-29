local GoodsVo = {}
local Vo = require('Game.Datas.Vo')
function GoodsVo:New( params, key )
	local this = {}
	setmetatable(GoodsVo, {__index = Vo})
	setmetatable(this, {__index = GoodsVo})
	this:Initail(params, key)
	return this 
end

return GoodsVo

------------------------------------
-- old
------------------------------------
-- local GoodsVo = {}

-- local properties = {goodsId = "goodsId",goodsName = "goodsName",goodsType = "type",goodsDescr = 'descr',num = "num",
-- 			quality = 'quality',stack = "stack",canSell = "canSell",sellPrice = "sellPrice",
-- 	effectNum = "effectNum",status = "status"}

-- function GoodsVo:New(params)
-- 	local this = {}
-- 	setmetatable( this, {__index = GoodsVo, __newindex = GoodsVo.validateProperty} )
-- 	this:Initail(params)
-- 	return this 
-- end

-- --[[
-- 初始化good的逻辑
-- --]]
-- function GoodsVo:Initail( params )
-- 	if next(params) ~= nil then
-- 	    for k, v in pairs( params ) do
-- 	        self[tostring( k)] = v
-- 	    end
-- 	end
-- end

-- --[[-
-- 添加字段
-- --]]
-- function GoodsVo:validateProperty(k, v)
-- 	--检查是否添加了不需要的字段
-- 	if not properties[k] then
-- 		--来了个新的字段
-- 		print( "[GoodsVo] incoming a new property has not containt " .. tostring( k ) )
-- 	else
-- 		rawset( self, properties[k], v)
-- 	end
-- end

-- function GoodsVo:GetId()
-- 	return 0
-- end

-- function GoodsVo:ToString( )
-- 	return tableToString(self)
-- end

-- return GoodsVo
------------------------------------
-- old
------------------------------------