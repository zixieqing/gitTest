--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local Sprite = cc.Sprite

function Sprite:playAnimationOnce(animation, args)
    local actions = {}

    local showDelay = args.showDelay or 0
    if showDelay then
        self:setVisible(false)
        actions[#actions + 1] = cc.DelayTime:create(showDelay)
        actions[#actions + 1] = cc.Show:create()
    end

    local delay = args.delay or 0
    if delay > 0 then
        actions[#actions + 1] = cc.DelayTime:create(delay)
    end

    actions[#actions + 1] = cc.Animate:create(animation)

    if args.removeSelf then
        actions[#actions + 1] = cc.RemoveSelf:create()
    end

    if args.onComplete then
        actions[#actions + 1] = cc.CallFunc:create(args.onComplete)
    end

    local action
    if #actions > 1 then
        action = cc.Sequence:create(actions)
    else
        action = actions[1]
    end
    self:runAction(action)
    return action
end

function Sprite:playAnimationForever(animation)
    local animate = cc.Animate:create(animation)
    local action = cc.RepeatForever:create(animate)
    self:runAction(action)
    return action
end

-- NOTE!!! The method is very slowly! Please use it in carefully.
-- The memory will leak if you don't release it manually.
-- @return A CCImage pointer.
function Sprite:getCCImage()
	-- Create a new Texture to get the pixel datas.
	local __size = self:getContentSize()
	local __rt = cc.RenderTexture:create(__size.width, __size.height)
	-- Hold the old anchor and position to restore it late on.
	local __oldAnchor = self:getAnchorPoint()
	local x,y = self:getPosition()
	-- Move the sprite to left bottom.
    self:setAnchorPoint(display.LEFT_BOTTOM)
    self:setPosition(cc.p(0,0))
	--print("getColor:", __point.x, __point.y, __size.width, __size.height)
	-- Render the sprite to get a new texture.
	__rt:begin()
	self:visit()
	__rt:endToLua()
	-- Restore the original anchor and position.
	self:setAnchorPoint(__oldAnchor)
	self:setPosition(cc.p(x,y))
	return __rt:newImage(false)
end

-- NOTE!!! The method is very slowly! Please use it in carefully.
-- @param __point A coordinate for color.
-- @param __convertToNodeSpace Optional, default is true, convert a coordinate to node space from world space.
-- @param __isFloat Optional, default is false, convert a coordinate to node space from world space.
function Sprite:getColor(__point, __convertToNodeSpace, __isFloat)
	if __convertToNodeSpace == nil then
		__convertToNodeSpace = true
	end
	if __convertToNodeSpace then
        __point = self:convertToNodeSpace(__point)
		-- __point = self:convertToWorldSpace(__point)
	end
	local __img = self:getCCImage()
	local __color = nil
	if __isFloat then
		__color = __img:getColor4F(__point.x, __point.y)
	else
		__color = __img:getColor4B(__point.x, __point.y)
	end
	__img:release()
	return __color
end

-- Only get a alpha value.
function Sprite:getColorAlpha(__point, __convertToNodeSpace, __isFloat)
	local color = self:getColor(__point, __convertToNodeSpace, __isFloat)
	return color.a
end
