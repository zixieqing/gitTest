--[[
 * author : kaishiqi
 * descpt : 猫屋 - 操作节点
]]
local CatHouseHandlerNode = class('CatHouseHandlerNode', function()
    return ui.layer({name = 'CatHouseHandlerNode', enableEvent = true})
end)

local RES_DICT = {
    HANDLE_BG        = _res('avatar/ui/decorate_bg_state.png'),
    HANDLE_DEL_BTN   = _res('avatar/ui/decorate_btn_delete.png'),
    HANDLE_RIGHT_BTN = _res('avatar/ui/decorate_btn_right.png'),
    HANDLE_BG_LEFT   = _res('avatar/ui/decorate_bg_state_left.png'),
}

local HANDLER_NODE_SIZE = cc.size(280, 120)


function CatHouseHandlerNode:ctor(args)
    self.isControllable_ = true
    self:setAnchorPoint(ui.cc)
    self:setContentSize(HANDLER_NODE_SIZE)
    self:setVisible(false)

    self.viewData_ = CatHouseHandlerNode.CreateView()
    self:add(self.viewData_.view)

    ui.bindClick(self:getViewData().delBtn, handler(self, self.onClickDelButtonHandler_))
    ui.bindClick(self:getViewData().rigthBtn, handler(self, self.onClickRightButtonHandler_))
end


-------------------------------------------------
-- get / set

function CatHouseHandlerNode:getViewData()
    return self.viewData_
end


--@see CatHouseUtils.HANDLER_TYPE
function CatHouseHandlerNode:getHandleType()
    return checkint(self.handlerType_)
end
function CatHouseHandlerNode:setHandleType(handlerType)
    local oldHandlerType = self:getHandleType()
    local newHandlerType = checkint(handlerType)
    self.handlerType_    = newHandlerType
    if oldHandlerType ~= newHandlerType then
        self:updateHandlerView_()
    end
end


-------------------------------------------------
-- public

function CatHouseHandlerNode:hideHandleView()
    if not self:isVisible() then return end
    self:setScale(1)
    self:setVisible(true)
    self.isControllable_ = false
    
    self:stopAllActions()
    self:runAction(cc.Sequence:create(
        cc.EaseCubicActionOut:create(cc.ScaleTo:create(0.15, 0)),
        cc.CallFunc:create(function()
            self:setVisible(false)
        end)
    ))
end


function CatHouseHandlerNode:showHandleView(alignNode)
    self:setScale(0)
    self:setVisible(true)
    self.isControllable_ = false
    if alignNode then
        self:alignTo(alignNode, ui.cc)
    end

    self:stopAllActions()
    self:runAction(cc.Sequence:create(
        cc.EaseBackOut:create(cc.ScaleTo:create(0.15, 1)),
        cc.CallFunc:create(function()
            self.isControllable_ = true
        end)
    ))
end


-------------------------------------------------
-- private

function CatHouseHandlerNode:updateHandlerView_()
    local ctrlBtnList = nil

    if self:getHandleType() == CatHouseUtils.HANDLER_TYPE.AVATAR then
        ctrlBtnList = {
            self:getViewData().rigthBtn,
            self:getViewData().delBtn,
        }
    end

    -- reset allBtns
    for _, button in ipairs(self:getViewData().allBtnList) do
        button:setVisible(false)
    end
    
    if ctrlBtnList then
        -- show ctrlBtns
        for _, button in ipairs(ctrlBtnList) do
            button:setVisible(true)
        end

        -- align ctrlBtns
        ui.flowLayout(self:getViewData().cpos, ctrlBtnList, {type = ui.flowH, ap = ui.cc, gapW = 50})
    end
end


-------------------------------------------------
-- handler

function CatHouseHandlerNode:onClickDelButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    if self:getHandleType() == CatHouseUtils.HANDLER_TYPE.AVATAR then
        app:DispatchObservers(SGL.CAT_HOUSE_CLICK_AVATAR_HANDLR, {cmdTag = CatHouseUtils.HOUSE_CMD_TAG.BY_REMOVE})
    else
        app.uiMgr:ShowInformationTips('unknow handler type')
    end
end


function CatHouseHandlerNode:onClickRightButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:getHandleType() == CatHouseUtils.HANDLER_TYPE.AVATAR then
        app:DispatchObservers(SGL.CAT_HOUSE_CLICK_AVATAR_HANDLR, {cmdTag = CatHouseUtils.HOUSE_CMD_TAG.BY_CONFIRM})
    else
        app.uiMgr:ShowInformationTips('unknow handler type')
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseHandlerNode.CreateView()
    local size = HANDLER_NODE_SIZE
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)
    
    local handleBg = ui.image({p = cpos, img = RES_DICT.HANDLE_BG})
    view:add(handleBg)

    local btnList = view:addList({
        ui.button({p = cpos, n = RES_DICT.HANDLE_DEL_BTN}),
        ui.button({p = cpos, n = RES_DICT.HANDLE_RIGHT_BTN})
    })
    
    return {
        view       = view,
        cpos       = cpos,
        handleBg   = handleBg,
        allBtnList = btnList,
        delBtn     = btnList[1],
        rigthBtn   = btnList[2],
    }
end


return CatHouseHandlerNode
