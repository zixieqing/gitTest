local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local SpineCommand = Command:New()

SpineCommand.NAME = "SpineCommand"


local OTHER_SPINE_DEFINE = {
    capsule = {path = 'ui/home/capsuleNew/common/effect/capsule', po = cc.p(0,0), bg = _res('ui/home/capsule/capsule_bg.png'), bgPos = display.center}
}


function SpineCommand:New(type, spineanime, isClean)
    local this = {}
    setmetatable( this, {__index = SpineCommand} )
    this.type       = type
    this.spineanime = spineanime
    this.isClean    = isClean == true
    this.inAction   = true
    return this
end


function SpineCommand:Execute()
    local director = Director.GetInstance('Director')
    local stage = director:GetStage()

    --移除所有的角色人物
    director:ClearRoles()
    if stage:getChildByTag(Director.ZorderTAG.Z_ROLE_LAYER) then
        stage:removeChildByTag(Director.ZorderTAG.Z_ROLE_LAYER)
    end

    if self.spineanime then
        local spineDataList  = string.split2(self.spineanime, ',')
        local spineFileName  = tostring(spineDataList[1])
        local spineAnimeName = tostring(spineDataList[2])
        local spineIsReplay  = tostring(spineDataList[3]) == 'true'
        
        -- spine layer
        local spineLayer = stage:getChildByTag(Director.ZorderTAG.Z_SPINE_ANIME)
        if not spineLayer then
            spineLayer = CColorView:create(cc.c4b(0,0,0,0))
            spineLayer:setContentSize(display.size)
            spineLayer:setPosition(display.center)
            stage:addChild(spineLayer, Director.ZorderTAG.Z_SPINE_ANIME, Director.ZorderTAG.Z_SPINE_ANIME)
        end

        -------------------------------------------------
        if self.isClean then
            -- clean spine
            director:PopImage(spineFileName)

            if #spineLayer:getChildren() <= 0 then
                spineLayer:removeFromParent()
            end
            self:finishCommand()

        else
            local spnDefine = OTHER_SPINE_DEFINE[spineFileName]
            local spineNode = spineLayer:getChildByName(spineFileName)
            local spineData = spnDefine and _spn(spnDefine.path) or _spn(string.fmt('arts/stage/spine/%1', spineFileName))

            if not spineNode then
                -- create spine
                if FTUtils:isPathExistent(spineData.json) then
                    spineNode = sp.SkeletonAnimation:create(spineData.json, spineData.atlas, 1)
                    spineNode:setPosition(spnDefine and spnDefine.po or display.center)
                    spineNode:setName(spineFileName)
                    spineLayer:addChild(spineNode)
                    director:PushSpine(spineNode, spineFileName, spineAnimeName, spineIsReplay)

                    if spnDefine and spnDefine.bg then
                        local bgPos = spnDefine.bgPos or PointZero
                        spineNode:addChild(display.newImageView(spnDefine.bg, bgPos.x, bgPos.y), -1)
                    end
                end
            end

            if spineNode then
                if spineIsReplay then
                    self:finishCommand()
                else
                    spineNode:registerSpineEventHandler(function(event)
                        spineNode:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
                        self:finishCommand()
                    end, sp.EventType.ANIMATION_COMPLETE)
                end

                spineNode:setAnimation(0, spineAnimeName, spineIsReplay)
            end
        end
        
        self.relationNode = spineLayer
    end
end


function SpineCommand:CanMoveNext()
    return false
end


function SpineCommand:finishCommand()
    self.inAction = false
    --自动下移命令
    self:Dispatch("DirectorStory","next")
end


return SpineCommand