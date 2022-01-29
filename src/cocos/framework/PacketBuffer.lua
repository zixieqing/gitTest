--[[--
PacketBuffer receive the byte stream and analyze them, then pack them into a message packet.
The method name, message metedata and message body will be splited, and return to invoker.
@see https://github.com/zrong/as3/blob/master/src/org/zengrong/net/PacketBuffer.as
--]]

local PacketBuffer = class('PacketBuffer')

local ByteArray = require('cocos.framework.ByteArray')

PacketBuffer.ENDIAN = ByteArray.ENDIAN_BIG

PacketBuffer.PRE_MASK = 0x86

--PacketBuffer.SUFIX_MASK = 0x59

PacketBuffer.RANDOM_MAX = 1000

PacketBuffer.PACKET_MAX_LEN = 2100000000


--[[--
packet bit structure 包结构
--]]

PacketBuffer.PRE_MASK_LEN = 1 -- 1字节
PacketBuffer.SUF_MASK_LEN = 1 -- 1字节
PacketBuffer.BODY_LEN = 4 -- 4字节
PacketBuffer.COMMAND_LEN = 2
PacketBuffer.VERSION_LEN = 1 -- 1 版本字节长度

function PacketBuffer.getBaseDATA()
    return ByteArray.new(PacketBuffer.ENDIAN)
end

function PacketBuffer.getRandom()
    return math.random(1,PacketBuffer.RANDOM_MAX)
end
--[[--
@param command
@param body only string
--]]
function PacketBuffer.createPacket(command, body)
    local _buffer = PacketBuffer.getBaseDATA()
    _buffer:writeByte(bit.band(PacketBuffer.getRandom(),PacketBuffer.PRE_MASK))
    --写入消息的长度
    if body then
        local _bodyBuffer = PacketBuffer.getBaseDATA():writeString(body)
        local _bodyLen = 0
        if _bodyBuffer then
            _bodyLen = _bodyBuffer:getLen()
        end
        _buffer:writeInt(PacketBuffer.COMMAND_LEN + _bodyLen)
        _buffer:writeShort(command)
        _buffer:writeBytes(_bodyBuffer)
        --	_buffer:writeByte(bit.band(PacketBuffer.getRandom(),PacketBuffer.SUFIX_MASK))
    else
        _buffer:writeInt(PacketBuffer.COMMAND_LEN)
        _buffer:writeShort(command)
    end
    return _buffer
end

function PacketBuffer:ctor()
    self:init()
end

function PacketBuffer:init()
    self._buf = PacketBuffer.getBaseDATA()
end
--- Get a byte stream and analyze it, return a splited table
-- Generally, the table include a message, but if it receive 2 packets meanwhile, then it includs 2 messages.
function PacketBuffer:parsePackets(_byteString)
    local _msgs = {}
    local _pos = 0
    self._buf:setPos(self._buf:getLen() + 1)
    self._buf:writeBuf(_byteString)
    self._buf:setPos(1)

    local __mask1 , __mask2 = nil, nil
    local _preLen = PacketBuffer.PRE_MASK_LEN + PacketBuffer.BODY_LEN
    -- self:log("start analyzing... buffer len: %u, available: %u", self._buf:getLen(), self._buf:getAvailable())
    while self._buf:getAvailable() >= _preLen do
        __mask1 = self._buf:readByte()
        -- if __mask1 == bit.band(__mask1,PacketBuffer.PRE_MASK) then
        if __mask1 == PacketBuffer.PRE_MASK then
            local _rawLen = self._buf:readInt()
            _pos = self._buf:getPos()
            --[[--
            如果没有将数据包的所有数据接受完全（即当前可用的长度小于当前位置＋消息主体长度＋尾部校验码长度）则等待下一次处理
            --]]
            --            if self._buf:getAvailable() < _rawLen + PacketBuffer.SUF_MASK_LEN then
            if self._buf:getAvailable() < _rawLen then
                self:log("received data is not enough, waiting... need %u, get %u", _rawLen, self._buf:getAvailable())
                -- self:log("buf: \n%s\n", self._buf:toString())
                self._buf:setPos(self._buf:getPos() - _preLen)
                break
            end
--            self._buf:setPos(_pos + _rawLen)
            --            __mask2 = self._buf:readByte()
            --            if bit.band(__mask2, PacketBuffer.SUFIX_MASK) == __mask2 then
            --长度允许解析数据
            if _rawLen <= PacketBuffer.PACKET_MAX_LEN then
--                self._buf:setPos(_pos)
                local command = self._buf:readShort()
                local msg = {
                    command = command,
                    body    = self._buf:readStringBytes(_rawLen - PacketBuffer.COMMAND_LEN),
                }
                if command ~= 1999 then
                    self:log('command %u \n\t%s\n', msg.command, json.encode(json.decode(msg.body)))
                end
                table.insert(_msgs, msg)
                -- self:log('after get body position: %u',self._buf:getPos())
                --移动写入位置指针跳过后缀码
--                self._buf:setPos(self._buf:getPos() + PacketBuffer.SUF_MASK_LEN)
            end
            --            else
            --                --回复位置
            --                self._buf:setPos(_pos)
            --            end
        end
    end
--    _pos = self._buf:getPos()

    --clear buffer
    if self._buf:getAvailable() <= 0 then
        self:init()
    else
        self:log("cache incomplete buff,len: %u, available: %u", self._buf:getLen(), self._buf:getAvailable())
        local __tmp = PacketBuffer.getBaseDATA()
        self._buf:readBytes(__tmp, 1, self._buf:getAvailable())
        self._buf = __tmp
        self:log("tmp len: %u, availabl: %u", __tmp:getLen(), __tmp:getAvailable())
        -- self:log("buf: \n%s\n", __tmp:toString())
    end
    return _msgs
end

function PacketBuffer:log(formatStr, ...)
    local prefix = string.format('[PacketBuffer] [%s] ', os.date("%Y-%m-%d %H-%M-%S"))
    cclog(string.format(prefix .. formatStr, ...))
end

return PacketBuffer
