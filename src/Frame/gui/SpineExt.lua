--[[
 * author : kaishiqi
 * descpt : spine节点扩展
]]
---@class SpineExt : cc.Node
local SpineExt = sp.SkeletonAnimation


--[[
    存储原始的spine方法，以便后面的覆盖实现不会丢失原始调用。
    目的是在不修改c++的基础上，给原始方法加一层容错判断。
]]
if SpineExt.o_setAnimation == nil then
    SpineExt.o_setAnimation = SpineExt.setAnimation
end
if SpineExt.o_addAnimation == nil then
    SpineExt.o_addAnimation = SpineExt.addAnimation
end


--- 播放动画
---@param trackIndex number     播放轨道（0开始）
---@param animeName  string     动画名字
---@param isLoop     boolean    是否循环播放
function SpineExt:setAnimation(trackIndex, animeName, isLoop)
    if tolua.isnull(self) then
        error('[SpineExt:setAnimation] self is nil')
    else
        SpineExt.o_setAnimation(self, trackIndex, animeName, isLoop == true)
    end
end


--- 追加动画
---@param trackIndex number     播放轨道（0开始）
---@param animeName  string     动画名字
---@param isLoop     boolean    是否循环播放
---@param delay      number     延迟执行时间
function SpineExt:addAnimation(trackIndex, animeName, isLoop, delay)
    if tolua.isnull(self) then
        error('[SpineExt:addAnimation] self is nil')
    else
        SpineExt.o_addAnimation(self, trackIndex, animeName, isLoop == true, checkint(delay))
    end
end


function SpineExt:onCleanup()
    self:setEnableSpineEvents(false)
end


function SpineExt:isEnableSpineEvents()
    return self.isSpineEventEnabled_ == true
end
function SpineExt:setEnableSpineEvents(isEnable)
    self.isSpineEventEnabled_ = checkbool(isEnable)
    self:updateEnableSpineEvents_()
    return self
end
function SpineExt:updateEnableSpineEvents_()
    if self:isEnableSpineEvents() then
        self:enableNodeEvents()
        self:registerSpineEventHandler(function(event)
            self:onStart_(event)
        end, sp.EventType.ANIMATION_START)
        self:registerSpineEventHandler(function(event)
            self:onEnded_(event)
        end, sp.EventType.ANIMATION_END)
        self:registerSpineEventHandler(function(event)
            self:onComplete_(event)
        end, sp.EventType.ANIMATION_COMPLETE)
        self:registerSpineEventHandler(function(event)
            self:onEvent_(event)
        end, sp.EventType.ANIMATION_EVENT)
    else
        self:unregisterSpineEventHandler(sp.EventType.ANIMATION_START)
        self:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
        self:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
        self:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
    end
end


---@type fun(event : table) : void
function SpineExt:getStartCB()
    return self.startCallback_
end
function SpineExt:setStartCB(callback)
    self.startCallback_ = callback
end
function SpineExt:onStart_(event)
    if self:getStartCB() then
        self:getStartCB()(event, self)
    end
end


---@type fun(event : table) : void
function SpineExt:getEndedCB()
    return self.endedCallback_
end
function SpineExt:setEndedCB(callback)
    self.endedCallback_ = callback
end
function SpineExt:onEnded_(event)
    if self:getEndedCB() then
        self:getEndedCB()(event, self)
    end
end


---@type fun(event : table) : void
function SpineExt:getEventCB()
    return self.eventCallback_
end
function SpineExt:setEventCB(callback)
    self.eventCallback_ = callback
end
function SpineExt:onEvent_(event)
    if self:getEventCB() then
        self:getEventCB()(event, self)
    end
end


---@type fun(event : table) : void
function SpineExt:getCompleteCB()
    return self.completeCallback_
end
function SpineExt:setCompleteCB(callback)
    self.completeCallback_ = callback
end
function SpineExt:onComplete_(event)
    if self:getCompleteCB() then
        self:getCompleteCB()(event, self)
    end
end


--[[
    获取 全部动画信息
    e.g: return {
        animations = { 'xxx', ... },
        bones      = { 'xxx', ... },
        skins      = { 'xxx', ... },
        slots      = { 'xxx', ... },
        width      = xxx,
        height     = xxx,
        version    = 'xxx',
        hash       = 'xxx',
    }
]]
---@return table
function SpineExt:getSpData()
    if self.getSkeletonData then
        return self:getSkeletonData()
    end
    error('Spine.getSkeletonData not supported !!')
    return nil
end


--[[
    查找 骨头信息 通过 骨头名字
    e.g: return {
        name          = 'xxx',
        rotation      = xxx,
        scaleX        = xxx,
        scaleY        = xxx,
        worldX        = xxx,
        worldY        = xxx,
        x             = xxx,
        y             = xxx,
        childrenCount = xxx,
        children      = {
            { 'xxx', ... }
        }
    }
]]
---@return table
function SpineExt:findSpBone(boneName)
    if self.findBone then
        return self:findBone(boneName)
    end
    error('Spine.findBone not supported !!')
    return nil
end


--[[
    查找 插槽信息 通过 插槽名字
    e.g: return {
        index      = xxx,
        name       = 'xxx'
        bone       = 'xxx',
        attachment = 'xxx',
    }
]]
---@return table
function SpineExt:findSpSlot(slotName)
    if self.findSlot then
        return self:findSlot(slotName)
    end
    error('Spine.findSlot not supported !!')
    return nil
end


--[[
    查找 皮肤信息 通过 皮肤名字
    e.g: return {
        name        = 'xxxx',
        attachments = {
            ['xxx'] = {
                {
                    attachment = 'xxx',
                    name       = 'xxx',
                    slotName   = 'xxx',
                    slotIndex  = xxx,
                },
                ...
            },
            ...
        },
    }
]]
---@return table<string, table>
function SpineExt:findSpSKin(skinName)
    if self.findSkin then
        return self:findSkin(skinName)
    end
    error('Spine.findSkin not supported !!')
    return nil
end


--[[
    获取 附加物信息 通过 指定骨头
]]
---@param slotName string       @骨头名字
---@param attachment string     @附加物名字
---@return table                @附加物信息 { name : string, type : int }
function SpineExt:getSpAttachment(slotName, attachment)
    if self.getAttachment then
        return self:getAttachment(slotName, attachment)
    end
    error('Spine.getAttachment not supported !!')
    return nil
end


--[[
    设置 附加物 给 指定骨头
]]
---@param slotName string       @骨头名字
---@param attachment string     @附加物名字
---@return boolean              @是否设置成功
function SpineExt:setSpAttachment(slotName, attachment)
    if self.setAttachment then
        return self:setAttachment(slotName, attachment)
    end
    error('Spine.setAttachment not supported !!')
    return false
end


--[[
    设置/获取 默认动画的混合度，可以优化动画到动画之前切换时的过度效果。
]]
---@param mixValue number   @混合度（0.0 - 1.0）
function SpineExt:setSpDefaultMix(mixValue)
    if self.setDefaultMix then
        return self:setDefaultMix(mixValue)
    end
    error('Spine.setDefaultMix not supported !!')
end
function SpineExt:getSpDefaultMix()
    if self.getDefaultMix then
        return self:getDefaultMix()
    end
    error('Spine.getDefaultMix not supported !!')
    return 0
end


--[[
    设置 根据已有的皮肤集合 组合个新皮肤。
    e.g: setSpMixedSkins('newSkin', {
        'head_01', 'body_04', 'eye_07', ...
    })
]]
---@param newSkinName string    @新皮肤名字
---@param partList string[]     @部位皮肤名字集合
---@return boolean              @是否生成成功
function SpineExt:setSpMixedSkins(newSkinName, skinList)
    if self.setMixedSkins then
        return self:setMixedSkins(newSkinName, skinList)
    end
    error('Spine.setMixedSkins not supported !!')
    return false
end


--[[
    设置 根据每个部位描述 组合个新皮肤。
    e.g: setSpMixNewSkin('newSkin', {
        { skinName : string, slotIndex : int, entryName : string },
        ...
    })
]]
---@param newSkinName string    @新皮肤名字
---@param partList table[]      @部位定义集合
---@return boolean              @是否生成成功
function SpineExt:setSpMixNewSkin(newSkinName, partList)
    if self.setMixNewSkin then
        return self:setMixNewSkin(newSkinName, partList)
    end
    error('Spine.setMixNewSkin not supported !!')
    return false
end
