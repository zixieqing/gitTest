--[[
 * author : panmeng
 * descpt : 猫屋 - 交互Trigger节点
]]
local CatHouseTriggerNode = class('CatHouseTriggerNode', function()
    return ui.layer({name = 'CatHouseTriggerNode', enableEvent = true})
end)

local CARD_NODE_SIZE = cc.size(80, 80)


function CatHouseTriggerNode:ctor(args)
    local initArgs = checktable(args)

    self:setAnchorPoint(ui.cc)
    self:setContentSize(CARD_NODE_SIZE)
    self:setPosition(initArgs.location or PointZero)

    -- create view
    self.clickView_ = ui.layer({size = CARD_NODE_SIZE, color = cc.r4b(0), enable = true})
    self:add(self.clickView_)

    -- add listen
    ui.bindClick(self.clickView_, handler(self, self.onClickCleanNodeHandler_))

    self:setTriggerType(initArgs.eventId)
    self:setTriggerUuid(initArgs.eventUuid)
end


-------------------------------------------------
-- get / set

function CatHouseTriggerNode:getViewData()
    return self.viewData_
end


-- triggerType
function CatHouseTriggerNode:getTriggerType()
    return checkint(self.triggerType_)
end
function CatHouseTriggerNode:setTriggerType(triggerType)
    self.triggerType_ = checkint(triggerType)
    self:udpateSpineNode_()
end


-- triggerEventUuid
function CatHouseTriggerNode:getTriggerUuid()
    return checkint(self.triggerEventUuid_)
end
function CatHouseTriggerNode:setTriggerUuid(eventUuid)
    self.triggerEventUuid_ = checkint(eventUuid)
end


-------------------------------------------------
-- public

function CatHouseTriggerNode:eraseFromParent()
    PlayAudioClip(AUDIOS.UI.ui_union_change.id)
    self.clickView_:setTouchEnabled(false)

    if not self.spineNode_ then
        self:runAction(cc.RemoveSelf:create())
        self.spineNode_ = nil
    else
        self.spineNode_:setAnimation(0, "play", false)
        self.spineNode_:registerSpineEventHandler(function()
            self:runAction(cc.RemoveSelf:create())
        end, sp.EventType.ANIMATION_COMPLETE)
    end
end


-------------------------------------------------
-- private

function CatHouseTriggerNode:udpateSpineNode_()
    self.spineNode_ = nil
    self.clickView_:removeAllChildren()
    
    local triggerTypeConf  = CONF.CAT_HOUSE.CAT_TRIGGER_EVENT:GetValue(self:getTriggerType())
    local triggerSpinePath = _spn("ui/catHouse/home/anim/" .. tostring(triggerTypeConf.pictureId))
    if app.gameResMgr:isExistent(triggerSpinePath.atlas) then
        self.spineNode_ = ui.spine({path = triggerSpinePath, init = "idle", cache = SpineCacheName.CAT_HOUSE})
        self.clickView_:addList(self.spineNode_):alignTo(nil, ui.cc)
    end
end


-------------------------------------------------
-- handler

function CatHouseTriggerNode:onClickCleanNodeHandler_(sender)
    PlayAudioByClickNormal()
    if app.catHouseMgr:getHouseOwnerId() ~= app.gameMgr:GetPlayerId() then
        return
    end

    local triggerTypeConf = CONF.CAT_HOUSE.CAT_TRIGGER_EVENT:GetValue(self:getTriggerType())
    app.uiMgr:AddCommonTipDialog({
        text     = string.fmt(__("是否清除[_name_]?"), {_name_ = tostring(triggerTypeConf.descr)}),
        callback = function()
            app:DispatchObservers(SGL.CAT_HOUSE_CLICK_TRIGGER_NODE, {eventUuid = self:getTriggerUuid()}) 
        end
    })
end


return CatHouseTriggerNode
