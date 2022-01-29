-- 字符串工具类

---------------------------------------------------
-- lua table -> string
---------------------------------------------------
-- 数据类型
local ValueType = {
	VT_NIL 			= 0,
	VT_NUMBER 		= 1,
	VT_BOOL 		= 2,
	VT_STRING 		= 3,
	VT_TABLE 		= 4,
	VT_FUNC 		= 5,
	VT_USERDATA 	= 6,
	VT_UNKNOWN 		= -1
}

local NIL_MARK = 'nil'

--[[
获取数据的lua type
@params v value
@return _ ValueType 数据类型
--]]
function gettype_(v)
	if nil == v then return ValueType.VT_NIL end

	local type_ = type(v)

	if 'number' == type_ then
		return ValueType.VT_NUMBER
	elseif 'boolean' == type_ then
		return ValueType.VT_BOOL
	elseif 'string' == type_ then
		return ValueType.VT_STRING
	elseif 'table' == type_ then
		return ValueType.VT_TABLE
	elseif 'function' == type_ then
		return ValueType.VT_FUNC
	elseif 'userdata' == type_ then
		return ValueType.VT_USERDATA
	else
		return ValueType.VT_UNKNOWN
	end
end

--[[
根据基础类型获取字符串
@params v value
@params vt ValueType
@return s string
--]]
function getstr_(v, vt)
	vt = vt or gettype_(v)

	if ValueType.VT_NIL == vt then
		return NIL_MARK

	elseif ValueType.VT_NUMBER == vt then
		return tostring(v)

	elseif ValueType.VT_BOOL == vt then
		return tostring(v)

	elseif ValueType.VT_STRING == vt then
		return '"' .. v .. '"'

	elseif ValueType.VT_TABLE == vt then
		return analysisTable(v)

	elseif ValueType.VT_FUNC == vt then
		return '|func_error|'

	elseif ValueType.VT_USERDATA == vt then
		return '|userdata|'

	elseif ValueType.VT_UNKNOWN == vt then
		return '|unknwon|'

	end

end

--[[
分析table内容 转换成string
@params t_ table
@return s_ string
--]]
function analysisTable(t_)
	local vt = gettype_(t_)

	if ValueType.VT_NIL == vt then

		return NIL_MARK

	elseif ValueType.VT_TABLE == vt then

		local s_ = '{'
		local itor = 0

		for k,v in pairs(t_) do

			itor = itor + 1
			if 1 < itor then
				s_ = s_ .. ','
			end
			s_ = s_ .. '[' .. getstr_(k) .. ']=' .. getstr_(v)

		end

		s_ = s_ .. '}'

		return s_

	else

		return getstr_(t_)

	end

end

--[[
将table转换成string --> 不考虑元表数据
@params t table lua table
@return s string
--]]
function Table2StringNoMeta(t)

	return analysisTable(t)

end

---------------------------------------------------
-- lua string -> table
---------------------------------------------------

--[[
将string转换成table --> 不考虑元表数据
@params s string
@return t table lua table
--]]
function String2TableNoMeta(s)

	return analysisString(s)

end

--[[
分析string内容 转换成table
@params s_ string
@return t_ table
--]]
function analysisString(s_)
	if nil == s_ then return nil end
	if NIL_MARK == s_ then return nil end

	local funcStr = [[
		local tbl = 
	]] .. s_ .. [[
		return tbl
	]]

	local func = loadstring(funcStr)
	local t_ = func()
	return t_
end
