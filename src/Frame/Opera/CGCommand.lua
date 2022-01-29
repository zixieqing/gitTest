local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local CGCommand = Command:New()

CGCommand.NAME = "CGCommand"


--[[--*
* 对添加一个图片
* @param imageId 背景图片的id
* @param x
* @param y y
--]]
function CGCommand:New(type, imageId, pos)
    local this = {}
    setmetatable( this, {__index = CGCommand} )
    this.type = type
    this.imageId = imageId
    this.imageAnchor = cc.p(0.5,0.5)
    this.imagePos = (pos or display.center)
    this.filter = nil
    return this
end

--[[
如图片存不存在的时候进行背景色的设置
@param color 背景色
--]]
function CGCommand:SetBgColor( color )
    self.color = color
end

--[[
--设置过滤图片
--]]
function CGCommand:setFilter(imageId)
    self.filter = imageId
end

-- --[[
-- 如图片存不存在的时候进行背景色的设置
-- @param imagePath 设置新的背景图
-- --]]
-- function CGCommand:SetImageFile( imagePath )
--     self.imagePath = imagePath
-- end

function CGCommand:SetImagePosition( x, y)
    self.imagePos = cc.p(x,y)
end
--设置锚点
function CGCommand:SetAnchor( x,y )
    self.imageAnchor = cc.p(x, y)
end

--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function CGCommand:Execute( )
    --执行方法的虚方法
    local director = Director.GetInstance( "Director" )
    local stage = director:GetStage()
    if stage:getChildByTag(Director.ZorderTAG.Z_BG_LAYER) then
        stage:removeChildByTag(Director.ZorderTAG.Z_BG_LAYER)
    end
    director:ClearRoles()
    if stage:getChildByTag(Director.ZorderTAG.Z_ROLE_LAYER) then
        stage:removeChildByTag(Director.ZorderTAG.Z_ROLE_LAYER)
    end
    --移除所有的角色人物
    if self.imageId then
        Director.GetInstance('Director'):RemoveImageCache(self.imageId)
        --创建一个对象
        local path = _res(string.format( "arts/common/%s.jpg", self.imageId ))
        if FTUtils:isPathExistent(path) then
            local role = FilteredSpriteWithMulti:create(path)
            if role then
                role:setAnchorPoint(self.imageAnchor)
                role:setPosition(self.imagePos)
                role:clearFilter()
                fullScreenFixScale(role)
                --添加一个mask层
                if self.filter then
                    local pp = utils.getLocalCenter(role)
                    local maskLayer1 = display.newNSprite(_res(string.format('arts/stage/bg/%s_01',self.filter)),pp.x,pp.y)
                    maskLayer1:setAnchorPoint(cc.p(1.0,0.5))
                    role:addChild(maskLayer1)
                    fullScreenFixScale(maskLayer1)

                    maskLayer1:setBlendFunc({src = gl.DST_COLOR, dst = gl.ZERO})
                    local maskLayer2 = display.newNSprite(_res(string.format('arts/stage/bg/%s_02',self.filter)),pp.x,pp.y)
                    maskLayer2:setAnchorPoint(cc.p(0,0.5))
                    role:addChild(maskLayer2)
                    fullScreenFixScale(maskLayer2)
                    maskLayer2:setBlendFunc({src = gl.DST_COLOR, dst = gl.ZERO})
                end
                local stage = director:GetStage()
                stage:addChild(role, Director.ZorderTAG.Z_BG_LAYER,Director.ZorderTAG.Z_BG_LAYER)
                director:PushImage(self.imageId, role)

                role:runAction(cc.RepeatForever:create(cc.Sequence:create(
                    cc.ScaleTo:create(7, 1.05),
                    cc.ScaleTo:create(7, 1)
                )))
            end
        end
    end
    if self.color then
        --如果最下层还有背景色
        local bg = stage:getChildByTag(Director.ZorderTAG.Z_COLOR_BOTTOM)
        if not bg then
            bg = CColorView:create(self.color)
            bg:setContentSize(display.size)
            bg:setPosition(display.center)
            stage:addChild(bg, Director.ZorderTAG.Z_COLOR_BOTTOM,Director.ZorderTAG.Z_COLOR_BOTTOM) --图片层的逻辑
        else
            bg:setColor(self.color)
        end
    end
end

return CGCommand
