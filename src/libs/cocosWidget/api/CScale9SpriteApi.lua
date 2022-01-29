---@meta


---@class CScale9Sprite : cc.Node
local CScale9Sprite = {}


--- Creates a 9-slice sprite with a texture file.
--- The whole texture will be broken down into a 3x3 grid of equal blocks.
---@param file? string
---@param rect? cc.rect
---@param capInsets? cc.rect
---@return CScale9Sprite
---@overload fun(capInsets:cc.rect, file:string):CScale9Sprite
---@see CScale9Sprite#init
---@see CScale9Sprite#initWithFile
function CScale9Sprite:create(file, rect, capInsets)
end


---@return boolean
function CScale9Sprite:init()
end

--- Initializes a 9-slice sprite with a texture file, a delimitation zone and
--- with the specified cap insets.
--- Once the sprite is created, you can then call its "setContentSize:" method
--- to resize the sprite will all it's 9-slice goodness intract.
--- It respects the anchorPoint too.
---@param file       string  @ The name of the texture file.
---@param rect?      cc.rect @ The rectangle that describes the sub-part of the texture that is the whole image. If the shape is the whole texture, set this to the texture's full rect.
---@param capInsets? cc.rect @ The values to use for the cap insets.
---@return boolean
---@overload fun(capInsets:cc.rect, file:string):boolean
function CScale9Sprite:initWithFile(file, rect, capInsets)
end


---@param texture cc.Texture2D
---@param capInsets? cc.rect
function CScale9Sprite:initWithTexture(texture, capInsets)
end

--- Initializes a 9-slice sprite with an sprite frame and with the specified 
--- cap insets.
--- Once the sprite is created, you can then call its "setContentSize:" method
--- to resize the sprite will all it's 9-slice goodness intract.
--- It respects the anchorPoint too.
---@param spriteFrame cc.SpriteFrame @ The sprite frame object.
---@param capInsets?  cc.rect        @ The values to use for the cap insets.
---@return boolean
function CScale9Sprite:initWithSpriteFrame(spriteFrame, capInsets)
end


--- Initializes a 9-slice sprite with an sprite frame name and with the specified 
--- cap insets.
--- Once the sprite is created, you can then call its "setContentSize:" method
--- to resize the sprite will all it's 9-slice goodness intract.
--- It respects the anchorPoint too.
---@param spriteFrameName string  @ The sprite frame name.
---@param capInsets?      cc.rect @ The values to use for the cap insets.
---@return boolean
function CScale9Sprite:initWithSpriteFrameName(spriteFrameName, capInsets)
end


---@param batchnode cc.SpriteBatchNode
---@param rect cc.rect
---@param capInsets cc.rect
---@return boolean
---@overload fun(batchnode:cc.SpriteBatchNode, rect:cc.rect, isRotated:boolean, capInsets:cc.rect)
function CScale9Sprite:initWithBatchNode(batchnode, rect, capInsets)
end


---@param texture    cc.Texture2D
---@param capInsets? cc.rect
---@---@return CScale9Sprite
function CScale9Sprite:createWithTexture(texture, capInsets)
end


--- Creates a 9-slice sprite with an sprite frame name and the centre of its
--- zone.
--- Once the sprite is created, you can then call its "setContentSize:" method
--- to resize the sprite will all it's 9-slice goodness intract.
--- It respects the anchorPoint too.
---@param spriteFrameName string
---@param capInsets?      cc.rect
---@return CScale9Sprite
---@see CScale9Sprite#initWithSpriteFrameName
function CScale9Sprite:createWithSpriteFrameName(spriteFrameName, capInsets)
end


--- Creates a 9-slice sprite with an sprite frame and the centre of its zone.
--- Once the sprite is created, you can then call its "setContentSize:" method
--- to resize the sprite will all it's 9-slice goodness intract.
--- It respects the anchorPoint too.
---@param spriteFrame cc.SpriteFrame
---@param capInsets?  cc.rect
---@return CScale9Sprite
---@see CScale9Sprite#initWithSpriteFrame
function CScale9Sprite:createWithSpriteFrame(spriteFrame, capInsets)
end


---@param texture cc.Texture2D
function CScale9Sprite:setTexture(texture)
end


---@param spriteFrame cc.SpriteFrame
function CScale9Sprite:setSpriteFrame(spriteFrame)
end


---@param size cc.size
function CScale9Sprite:setContentSize(size)
end


--- Original sprite's size.
---@return cc.size
function CScale9Sprite:getOriginalSize()
end


--- Prefered sprite's size. By default the prefered size is the original size.
--- if the preferredSize component is given as -1, it is ignored
---@param preferredSize cc.size
function CScale9Sprite:setPreferredSize(preferredSize)
end


---@return cc.size
function CScale9Sprite:getPreferredSize()
end


--- The end-cap insets. 
--- On a non-resizeable sprite, this property is set to CGRectZero; the sprite 
--- does not use end caps and the entire sprite is subject to stretching. 
---@param capInsets cc.rect
function CScale9Sprite:setCapInsets(capInsets)
end


function CScale9Sprite:getCapInsets()
end


--- Sets the top side inset
---@param insetTop number
function CScale9Sprite:setInsetTop(insetTop)
end


---@return number
function CScale9Sprite:getInsetTop()
end


--- Sets the bottom side inset
---@param insetBottom number
function CScale9Sprite:setInsetBottom(insetBottom)
end


---@return number
function CScale9Sprite:getInsetBottom()
end


--- Sets the left side inset
---@param insetLeft number
function CScale9Sprite:setInsetLeft(insetLeft)
end


---@return number
function CScale9Sprite:getInsetLeft()
end


--- Sets the left right inset
---@param insetRight number
function CScale9Sprite:setInsetRight(insetRight)
end


---@return number
function CScale9Sprite:getInsetRight()
end


---@param color cc.c3b
function CScale9Sprite:setColor(color)
end


---@return cc.c3b
function CScale9Sprite:getColor()
end


---@param opacity integer @ value range 0~255
function CScale9Sprite:setOpacity(opacity)
end


---@return integer
function CScale9Sprite:getOpacity()
end


--- sets the premultipliedAlphaOpacity property.
--- If set to NO then opacity will be applied as: glColor(R,G,B,opacity);
--- If set to YES then oapcity will be applied as: glColor(opacity, opacity, opacity, opacity );
--- Textures with premultiplied alpha will have this property by default on YES. Otherwise the default value is NO
---@param isModify boolean
function CScale9Sprite:setOpacityModifyRGB(isModify)
end


---@return boolean @ returns whether or not the opacity will be applied using glColor(R,G,B,opacity) or glColor(opacity, opacity, opacity, opacity);
function CScale9Sprite:isOpacityModifyRGB()
end


--- Creates and returns a new sprite object with the specified cap insets.
--- You use this method to add cap insets to a sprite or to change the existing
--- cap insets of a sprite. In both cases, you get back a new image and the 
--- original sprite remains untouched.
---@param capInsets cc.rect @ The values to use for the cap insets.
---@return CScale9Sprite
function CScale9Sprite:resizableSpriteWithCapInsets(capInsets)
end


---@param batchnode cc.SpriteBatchNode
---@param rect      cc.rect
---@param isRotated boolean
---@param capInsets cc.rect
function CScale9Sprite:updateWithBatchNode(batchnode, rect, isRotated, capInsets)
end


---@param parentOpacity integer @ value range 0~255
function CScale9Sprite:updateDisplayedOpacity(parentOpacity)
end


---@param parentColor cc.c3b
function CScale9Sprite:updateDisplayedColor(parentColor)
end


---@param renderer cc.Renderer
---@param parentTransform cc.mat4
---@param parentFlags integer
function CScale9Sprite:visit(renderer, parentTransform, parentFlags)
end
