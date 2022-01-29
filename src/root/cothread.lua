-- cothread.lua
 
local co = coroutine
local error = error
local setmetatable = setmetatable
local unpack = unpack
local assert = assert
local type = type
local pairs = pairs
 
module "cothread"
 
resume = error
run = error
chan = error
sleep = error
select = error
 
local queue = error
local _active 
local timer_add = error
local timer_pop = error
local _thread_count = 0
 
do
	local _queue = {}
	local _queue_meta = { __index = _queue }
 
	function _queue:push(v)
		self[self.tail]=v
		self.tail = self.tail + 1
	end
 
	function _queue:pop()
		if self.tail == self.head then
			self.tail = 1
			self.head = 1
		else
			local ret = self[self.head]
			self[self.head] = nil
			self.head = self.head + 1
			return ret
		end
	end
 
	function _queue:move(q)
		for v in q.pop , q do
			self:push(v)
		end
	end
 
	function queue()
		return setmetatable( {head = 1, tail = 1} , _queue_meta )
	end
end
 
do
	_active = queue()
 
	local function _resume_active()
		for v in _active.pop , _active do
			assert(co.resume(v))
		end
	end
 
	function resume(ti)
		_resume_active()
		_active:move(timer_pop())
		return _thread_count
	end
end
 
function run(f,...)
	local c = co.create(
		function() 
			_thread_count = _thread_count + 1
			f(unpack(arg)) 
			_thread_count = _thread_count - 1
		end)
	_active:push(c)
end
 
function sleep(ti)
	if ti and ti > 0 then
		timer_add(co.running(), ti-1)
	else
		_active:push(co.running())
	end
	co.yield()
end
 
do 
	local _chan = {}
	local _chan_meta = { __index = _chan }
 
	function chan()
		local ret =  setmetatable(
			{ 
				_status = "empty",
				_read = queue(),
				_write = queue(),
				_closing = false,
				_value = nil
			} , _chan_meta)
		return ret
	end
 
	function _chan:read()
		if self._status == "empty" then
			if self._closing then
				return nil,true
			end
			self._read:push {co.running()}
			co.yield()
		end
		if self._status == "ready" then
			local ret = self._value
			self._value = nil
			self._status = self._closing and "closed" or "empty"
			local w = self._write:pop()
			if w then
				_active:push(w)
			end
			return ret
		end
		return nil, true
	end
 
	function _chan:write(v)
		if self._status == "ready" then
			if self._closing then
				return
			end
			self._write:push(co.running())
			co.yield()
		end
		if self._status == "empty" then
			self._value = v
			self._status = self._closing and "closed" or "ready"
			while true do
				local r = self._read:pop()
				if r then
					if r[1] then
						_active:push(r[1])
						r[1] = nil
						return true
					end
				else 
					return true
				end
			end
		end
	end
 
	function _chan:closed()
		return self._status == "closed"
	end
 
	function _chan:close()
		self._closing = true
	end
 
end
 
function select(t)
	if t.default then
		for ch,func in pairs(t) do
			if type(ch) == "table" then
				if ch._status == "ready" then
					local v = ch._value
					ch._value = nil
					ch._status = ch._closing and "closed" or "empty"
					local w = ch._write:pop()
					if w then
						_active:push(w)
					end
					func(v)
					return
				end
			end
		end
		t.default()
		_active:push(co.running())
	else
		local reader = { co.running() }
		for ch,func in pairs(t) do
			if ch._status == "ready" then
				reader[1] = nil
				local v = ch._value
				ch._value = nil
				ch._status = ch._closing and "closed" or "empty"
				local w = ch._write:pop()
				if w then
					_active:push(w)
				end
				func(v)
				return
			elseif ch._status == "empty" then
				if ch._closing then
					reader[1] = nil
					func(nil,true)
				else
					ch._read:push(reader)
				end
			end
		end
	end
	co.yield()
end
 
do
	local _timer = {}
	local _current = 1
	for i = 1,100 do
		_timer[i] = queue()
	end
 
	local _long_timer = queue()
 
	function timer_add(v , ti)
		if ti < 100 then
			local idx = _current + ti
			_timer[idx<=100 and idx or idx-100 ]:push(v)
		else
			_long_timer:push(ti + _current)
			_long_timer:push(v)
		end
	end
 
	function timer_pop()
		local ret = _timer[_current]
		_current = _current + 1
		if _current > 100 then
			_current = 1
			while true do
				local ti = _long_timer:pop()
				if ti == nil then
					break
				end
				local v = _long_timer:pop()
				timer_add(v, ti - 101)
			end
		end
 
		return ret
	end
end