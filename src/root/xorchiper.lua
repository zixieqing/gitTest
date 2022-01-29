local apisalt = FTUtils:generateKey(SIGN_KEY)
apisalt = string.sub(apisalt, 1, 8)
local bmap = {}
for ch in apisalt:gmatch(".") do
    table.insert(bmap, string.byte(ch))
end

local bit32 = require("root.bit32")
--Returns the XOR of two binary numbers
function xor(a,b)
  local r = 0
  local f = math.floor
  for i = 0, 31 do
    local x = a / 2 + b / 2
    if x ~= f(x) then
      r = r + 2^i
    end
    a = f(a / 2)
    b = f(b / 2)
  end
  return r
end

--Changes a decimal to a binary number
function toBits(num)
    local t={}
    while num>0 do
        rest=math.fmod(num,2)
        t[#t+1]=rest
        num=(num-rest)/2
    end
	--[[ t gives the binary number in reverse. To fix this
		the bits table will give the correct value
		by reversing the values in t.
		The result will be left paddied with zeros to eight digits
	]]
	local bits = {}
	local lpad = 8 - #t
	if lpad > 0 then
		for c = 1,lpad do table.insert(bits,0) end
	end
	-- Reverse the values in t
	for i = #t,1,-1 do table.insert(bits,t[i]) end

    return table.concat(bits)
end

--Encryption and Decryption Algorithm for XOR Block cipher
function E(str)
	local block = {}
	for ch in str:gmatch(".") do
		local c = string.byte(ch)
		table.insert(block,c)
	end

	--for each binary number perform xor transformation
	for i = 1,#block do
		local bit = block[i]
        local t = 0
        -- for i=1,8,1 do
        local keyIndx = i % 8
        if keyIndx == 0 then keyIndx = 8 end
            t = bit32.bxor(bmap[keyIndx], bit)
        -- end
        block[i] = string.char(t)
	end
	return table.concat(block)
end
