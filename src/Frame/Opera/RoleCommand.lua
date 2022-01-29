local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local RoleCommand = Command:New()

local MoveCommand = require("Frame.Opera.MoveCommand")
local CardL2dNode = require('Frame.gui.CardL2dNode')

RoleCommand.NAME = "RoleCommand"
RoleCommand.DEFAULT_CARD = 200011


--[[--*
* 对一个角色进行透明度的逻辑处理
* @param roleId 执行动作的角色id
* @param image 图片文件路径
* @param align 左，右等
* @param faceId 对应的表情id
--]]
function RoleCommand:New(params)
    local this = {}
    -- roleId, align,iscard, image, faceId
    setmetatable( this, {__index = RoleCommand} )
    this.roleId = params.roleId
    this.replace = params.replace
    this.image = params.image
    this.iscard = params.iscard
    this.flip = params.flip --是否反转
    if this.iscard == nil then this.iscard = true end
    this.align = params.align
    this.scale = params.scale
    this.offset = params.offset
    this.faceId = (params.faceId or 1)
    this.isL2d_ = params.isL2d == true
    self.inAction = true
    self.mysteryMode = params.mysteryMode == true
    return this
end

function RoleCommand:AnimateEnter()
    self.enterAnimate = true
end

--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function RoleCommand:Execute( )
    --执行方法的虚方法
    -- local director = Director.GetInstance( )
    -- director:GetRole(self.roleId)
    -- if roleInfo and roleInfo.role then
    -- 	roleInfo.role:setPosition(self.pos)
    -- else
    local director = Director.GetInstance()
    local stage = director:GetStage()

    -- role layer
    local roleLayer = stage:getChildByTag(Director.ZorderTAG.Z_ROLE_LAYER)
    if not roleLayer then
        roleLayer = CLayout:create(display.size)
        display.commonUIParams(roleLayer, {po = display.center})
        stage:addChild(roleLayer, Director.ZorderTAG.Z_ROLE_LAYER, Director.ZorderTAG.Z_ROLE_LAYER)
    end

    -- [.replace]
    if self.replace and string.match(tostring(self.replace), '%w+') then
        --先移除一些不需要的角色
        local t = string.split(tostring(self.replace), ',')
        if type(t) == 'table' then
            for k,v in pairs(t) do
                director:PopRole(v)
            end
        end
    end

    -- create role
    local roleName, isCard = Director.GetRoleName(self.roleId)
    self.iscard    = isCard
    local cardId   = self.roleId
    local lwidth   = 200
    local roleNode = nil
    local roleView = nil
    local nameBar  = nil
    local isLive2d = self.isL2d_ == true
    
    -- check npc trigger conf
    if self.iscard and CONF.CARD.TRIGGER_NPC:IsValid() then
        if CommonUtils.GetGoodTypeById(cardId) == GoodsType.TYPE_CARD_SKIN then
            if CardUtils.IsMonsterSkin(cardId) == false then
                local drawName = CardUtils.GetCardDrawNameBySkinId(cardId)
                if next(CONF.CARD.TRIGGER_NPC:GetValue(drawName)) == nil then
                    cardId   = RoleCommand.DEFAULT_CARD
                    isLive2d = false
                end
            end
        else
            if CardUtils.IsMonsterCard(cardId) == false then
                if next(CONF.CARD.TRIGGER_NPC:GetValue(cardId)) == nil then
                    cardId   = RoleCommand.DEFAULT_CARD
                    isLive2d = false
                end
            end
        end
    end

    -------------------------------------------------
    -- create live2d node
    if isLive2d and GAME_MODULE_OPEN.CARD_LIVE2D then
        lwidth = display.width
        
        local oldRole = roleLayer:getChildByName(tostring(self.roleId))
        if oldRole then
            roleNode = oldRole
            roleView = roleNode:getChildByTag(888)
            roleView:setMotion(self.faceId)
        else
            roleNode = CLayout:create()
            roleNode:setName(tostring(self.roleId))
            roleLayer:addChild(roleNode, 4)
            
            roleView = CardL2dNode.new({roleId = cardId, faceId = self.faceId})
            roleView:setTag(888)
            roleView:setAnchorPoint(display.LEFT_BOTTOM)
            roleNode:addChild(roleView)
            roleNode:setContentSize(roleView:getContentSize())
        end
        
        if director:GetRole(self.roleId) then
            -- fixed align
            director:GetRole(self.roleId).pos = self.align
        else
            -- PushRole
            director:PushRole(self.roleId, roleNode, self.align)
        end
        
        roleView:setScaleX(checkbool(self.flip) == true and -1 or 1)
        roleView:setPosition(PointZero)


    -- create image node
    else
        roleNode = CLayout:create()
        roleLayer:addChild(roleNode, 4)
        roleNode.mysteryMode = self.mysteryMode

        roleView = CommonUtils.GetRoleNodeById(cardId, checkint(self.faceId), checkbool(self.flip))
        -- roleView:setBackgroundColor(cc.c4b(100,100,100,100))
        lwidth = roleView:getContentSize().width
        roleNode:setContentSize(cc.size(lwidth,display.height))
        -- roleNode:setBackgroundColor(cc.c4b(100,100,100,100))
        display.commonUIParams(roleView, {ap = display.CENTER_TOP, po = cc.p(lwidth * 0.5, display.height - 40)})
        roleView:setTag(888)
        roleNode:addChild(roleView)

        if self.mysteryMode then
            roleView:setColor(cc.c3b(0,0,0))
            roleView:setOpacity(200)
        end

        -- fixed init position
        if self.iscard then
            CommonUtils.FixAvatarLocation(roleView, cardId)
        else
            --是否有配置的坐标的逻辑
            local rInfo = app.gameMgr:GetRoleInfo(cardId)
            if rInfo and rInfo.takeaway and checkint(rInfo.takeaway.x) ~= 0 and checkint(rInfo.takeaway.y) ~= 0 then
                -- local offset = (display.height - 1002)
                -- roleView:setScale(checkint(rInfo.takeaway.scale) / 100)
                display.commonUIParams(roleView, {ap = display.CENTER, po = cc.p(lwidth * 0.5, display.height  - checkint(rInfo.takeaway.y))})
            end
        end
    
        -- PushRole
        director:PushRole(self.roleId, roleNode, self.align)
    
        -- 角色名称
        nameBar = display.newImageView(_res('arts/stage/ui/story_bg_name.png'), lwidth * 0.5, 44)
        nameBar:setTag(7654)
        roleNode:addChild(nameBar, 2)

        local nameLabel = display.newLabel(114, 28, {fontSize = 26, color = '6c6c6c', reqW = 200,  text = self.mysteryMode and '???' or roleName})
        nameBar:addChild(nameLabel)
    end

    -------------------------------------------------
    if roleNode then
        -- [.align]
        roleNode:setPosition(Director.GetAlignPoint(self.align))
    end

    if roleView then
        -- [.scale]
        if self.scale and string.match(self.scale, '^%d+') then
            roleView:setScale(checkint(self.scale)/100)
        end
        -- [.offset]
        if self.offset and self.offset.x and self.offset.y then
            local x,y = roleView:getPosition()
            roleView:setPosition(cc.p(x + checkint(self.offset.x), y + checkint(self.offset.y)))
        end
    end

    -------------------------------------------------
    -- enterAnimate
    if self.enterAnimate == true then
        if roleNode then
            if roleNode:getPositionX() > display.cx then
                if nameBar then nameBar:setVisible(false) end
                roleNode:setPosition(cc.p(display.width + lwidth + 100, display.cy))
            else
                if nameBar then nameBar:setVisible(false) end
                roleNode:setPosition(cc.p( -lwidth - 100, display.cy))
            end
        end
    end

    self:finishCommand()
end


function RoleCommand:GetRoleMoveCommand( )
    local pos = Director.GetAlignPoint(self.align)
    local cmd = MoveCommand:New(self.roleId, pos.x, pos.y, 0.7)
    return cmd
end


function RoleCommand:CanMoveNext()
    return false
end


function RoleCommand:finishCommand()
    self.inAction = false
    --自动下移命令
    self:Dispatch("DirectorStory","next")
end


return RoleCommand
