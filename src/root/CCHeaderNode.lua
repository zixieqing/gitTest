---@class CCHeaderNode
local CCHeaderNode = class('CCHeaderNode',function()
    local tips = CLayout:create()
    tips.name = 'CCHeaderNode'
    tips:enableNodeEvents()
    -- tips:setBackgroundColor(cc.c4b(100,100,100,100))
    return tips
end)

local WebSprite = lrequire('root.WebSprite')

function CCHeaderNode:ctor(...)
    local arg = unpack({...})
    local headSpriteSize = cc.size(0,0)
    self.isSelf = arg.isSelf
    if arg then
        self.callback = arg.callback
        if arg.bg and arg.bg ~= "" then
            self.bgImage = FilteredSpriteWithOne:create(arg.bg)
            local preSize =  self.bgImage:getContentSize()
            self.bgImage:setPosition(cc.p(preSize.width/2 , preSize.height/2))
            self.bg = display.newLayer(preSize.width/2 , preSize.height/2 ,
            {  ap = display.CENTER, size = preSize , color= cc.c4b(0,0,0,0) , enable = true , cb = handler(self,self.buttonAction) }  )
            self.bg:addChild(self.bgImage)
            self:setContentSize(self.bg:getContentSize())
        end

        if arg.pre  or arg.isPre   then

            arg.pre = CommonUtils.GetAvatarFrame(arg.pre)
            local str = ""
            if tonumber(arg.pre) then
                str = CommonUtils.GetGoodsIconPathById(arg.pre or "500077")
            else
                str = arg.pre
            end
            self.preBgImage = FilteredSpriteWithOne:create(str)
            local preSize =  self.preBgImage:getContentSize()
            self.preBgImage:setPosition(cc.p(preSize.width/2 , preSize.height/2))
            self.preBg = display.newLayer(preSize.width/2 , preSize.height/2 ,
                { ap = display.CENTER, size = preSize , color= cc.c4b(0,0,0,0) , enable = true , cb = handler(self,self.buttonAction) }  )
            self.preBg:addChild(self.preBgImage)
            self:addChild(self.preBg,2)
            self.preBg:setName("preBg")
            self:AddSpineAction(arg.pre or "500077")
            self.preBgImage:setName("preBgImage")
            if not  self.bg then
                self:setContentSize(self.preBg:getContentSize())
            end
        end
        -- 底贝
        local sizee = self:getContentSize()
        local  bottomImage =  FilteredSpriteWithOne:create(_res('ui/common/create_roles_head_down_default'))
        bottomImage:setAnchorPoint(display.CENTER)
        bottomImage:setPosition(cc.p(sizee.width/2 , sizee.height/2))
        self:addChild(bottomImage)
        self.bottomImage = bottomImage
        if arg.url then
            self.url = arg.url
        end
        if arg.isSystem ~= nil and arg.isSystem == true and arg.role_head ~= nil then
            self.isSystemHead = true
            self.roleHead = arg.role_head
        else
            self.isSystemHead = false
        end
    end

    self.size = self:getContentSize()
    local relativeScale =  1 -- 相对缩减
    if self.bg then
        local bgSize =  self.bg:getContentSize()
        if bgSize.width > 150 then
            relativeScale = 1
        else
            relativeScale = 0.8

        end

    end
    if arg.tsize then
        if arg.tsize then
            self.size = arg.tsize
            self:setContentSize(self.size)
        end
        headSpriteSize = cc.size(arg.tsize.width - 8 , arg.tsize.height - 8 )
        self.size = self:getContentSize()
        local bottomScale = (arg.tsize.width - 8)/ 170
        local bgScale = (arg.tsize.width - 8)/ 144
        if self.preBg then
            self.preBg:setScale(bottomScale)
        end
        if self.bg then
            self.bg:setScale(bgScale)
        end
        if self.bottomImage then
            self.bottomImage:setScale(bottomScale)
        end
    elseif self.bg then
        headSpriteSize = cc.size(self.size.width - 8 , self.size.height - 8 )
        if self.preBg then
            self.preBg:setScale( relativeScale)
        end
        if self.bg then
            self.bg:setScale(1)
        end
        if self.bottomImage then
            self.bottomImage:setScale(relativeScale)
        end
    else
        if self.preBg then
            self.preBg:setScale(1)
        end
        if self.bg then
            self.bg:setScale(0)
            self.bg:setVisible(false)
        end
        if self.bottomImage then
            self.bottomImage:setScale(1)
        end
        headSpriteSize = cc.size(self.size.width - 40 , self.size.height - 40 )
    end
    self:setContentSize(self.size)
    local pp = utils.getLocalCenter(self)
    if self.bottomImage then
        display.commonUIParams(self.bottomImage,{po = pp})
    end
    if self.bg then
        display.commonUIParams(self.bg,{po = pp})
        self:addChild(self.bg)
    end
    if self.preBg then
        display.commonUIParams(self.preBg,{po = pp})

    end

    if self.isSystemHead == true then
        local  sprite = cc.Sprite:create(_res(string.format('arts/roles/%s',self.roleHead)))
        local wsize = sprite:getContentSize()

        self.headerSprite = WebSprite.new({hpath = _res(string.format('arts/roles/%s',self.roleHead)),tsize =  headSpriteSize, size = self.size})
    else
        local gameMgr  = AppFacade.GetInstance():GetManager('GameManager')
        if not self.url then self.url = gameMgr:GetUserInfo().avatar end
        self.headerSprite = WebSprite.new({url = self.url, hpath = _res('ui/home/nmain/common_role_female'),tsize = headSpriteSize, size = self.size})
    end
    local ww = self.size.width - 8
    self.headerSprite:setTargetContentSize(cc.size(ww, ww))
    if arg.clip then
        local clippingNode = cc.ClippingNode:create()
        clippingNode:setInverted(false)
        clippingNode:setPosition(utils.getLocalCenter(self))
        self:addChild(clippingNode,1)
        clippingNode:addChild(self.headerSprite)

        -- draw circle
        self.drawnode = cc.DrawNode:create()
        -- drawNodeRoundRect(self.drawnode, cc.rect(0,0, self.size.width, self.size.height),4, 10, cc.c4b(255,255,255,255) )
        -- self.drawnode:setPosition(display.center)
        -- self:addChild(self.drawnode,2)
        -- stencil
        local radius = self.size.width * 0.5 + 4
        self.drawnode:drawSolidCircle(cc.p(0,0),radius - 10,0,220,1.0,1.0,cc.c4f(0,0,0,1))
        --    self.drawnode:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.ScaleBy:create(0.05,0.95),cc.ScaleTo:create(0.125,1.0))))
        clippingNode:setStencil(self.drawnode)
    else
        self.headerSprite:setPosition(utils.getLocalCenter(self))
        self:addChild(self.headerSprite,1)
    end

    if arg.gray then
        if arg.gray == true then
            local grayFilter = GrayFilter:create()
            self.headerSprite:setFilter(grayFilter)
        else
            self.headerSprite:clearFilter()
        end
    end
end
function CCHeaderNode:SetGray( isGray )
    if isGray then
        -- 如果没有获取到这个头像
        self.headerSprite:setFilter(GrayFilter:create())
        local preBg = self:getChildByName("preBg")
        local preBgImage = nil
        if preBg and not  tolua.isnull(preBg) then
            preBgImage = preBg:getChildByName("preBgImage")
        end
        if preBg then
            local  spineAnimation = preBg:getChildByName("spineAnimation")
            if spineAnimation then
                spineAnimation:removeFromParent()
                spineAnimation = nil
            end
        end
        if preBgImage and  not  tolua.isnull( preBgImage) then
            preBgImage:setFilter(GrayFilter:create())


        end
        if self.bgImage and  not  tolua.isnull( self.bgImage) then
            self.bgImage:setFilter(GrayFilter:create())

        end
        if self.bottomImage and  not  tolua.isnull( self.bottomImage) then
            self.bottomImage:setFilter(GrayFilter:create())
        end
    else
        if self.id then
            self:AddSpineAction(self.id )

        end
        local preBg = self:getChildByName("preBg")
        local preBgImage = nil
        if preBg and not  tolua.isnull(preBg) then
            preBgImage = preBg:getChildByName("preBgImage")
        end
        if self.bottomImage and  not  tolua.isnull( self.bottomImage) then
            self.bottomImage:clearFilter()

        end
        if preBgImage and  not  tolua.isnull( preBgImage) then
            preBgImage:clearFilter()

        end
        if self.bgImage and  not  tolua.isnull( self.bgImage) then
            self.bgImage:clearFilter()

        end
        self.headerSprite:clearFilter()
    end
end
-- 设置头像框的纹理
function CCHeaderNode:SetPreImageTexture(str)
    local x,y = string.find(str, "%d+")
    local id = nil
    if x and y then
        id  = string.sub(str, x , y )
        self.id = id
    else
        self.id = nil
    end
    local preBg = self:getChildByName("preBg")
    local preBgImage = nil
    if preBg and not  tolua.isnull(preBg) then
        preBgImage = preBg:getChildByName("preBgImage")
    end

    if preBg and not  tolua.isnull(preBg) then

        if self.bg and not  tolua.isnull(self.bg) then
            self.bg:setVisible(false)
        end
        preBg:setVisible(true)
        preBgImage:setTexture(str)
    end
    if id then
        self:AddSpineAction(id)
    end
end
function CCHeaderNode:buttonAction(sender)
    if self.callback then self.callback(sender) end
end
-- 是按钮是否可以点击
function CCHeaderNode:SetTouchEnabled(isEnabled)
    if self.bg and not   tolua.isnull(self.bg) then
        self.bg:setTouchEnabled(false)
    end
    local preBg = self:getChildByName("preBg")
    if preBg and not tolua.isnull(preBg) then
        preBg:setTouchEnabled(false)
    end

end
function CCHeaderNode:AddSpineAction(id)
    local preBg = self:getChildByName("preBg")
    if preBg then
        local  spineAnimation = preBg:getChildByName("spineAnimation")
        if spineAnimation then
            spineAnimation:removeFromParent()
            spineAnimation = nil
        end
        local num = CommonUtils.GetCacheProductNum(id)
        if  (self.isSelf and  num > 0)  or ( not  self.isSelf) then
            spineAnimation = CommonUtils.GetAchieveRewardsGoodsSpineActionById(id)
            if spineAnimation then
                local size = preBg:getContentSize()
                preBg:addChild(spineAnimation,10)
                spineAnimation:setPosition(cc.p(size.width/2 , size.height/2))
            end
        end
    end
end


function CCHeaderNode:setClickCallback( callback )
    if callback then
        self.callback = callback
    end
end

function CCHeaderNode:onEnter()
end

function CCHeaderNode:onExit()
end

function CCHeaderNode:onCleanup()
end
return CCHeaderNode
