--[[
 * descpt : 创建工会 中介者
]]
local NAME = 'UnionCreateMediator'
local UnionCreateMediator = class(NAME, mvc.Mediator)

local BTN_TAG = {
	TAG_HEAD       = 100,
	TAG_CREATE     = 101,
}

local uiMgr    = AppFacade.GetInstance():GetManager('UIManager')
local gameMgr  = AppFacade.GetInstance():GetManager("GameManager")
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")

local UNION_CREATE_DIAMOND = 200

function UnionCreateMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.defHeadId = self.ctorArgs_.defHeadId or '101'

end

-------------------------------------------------
-- inheritance method

function UnionCreateMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    -- create view
    local view = require('Game.views.UnionCreateView').new()
    self.viewData_ = view:getViewData()
    self:SetViewComponent(view)
    -- init view
    self:initView()
end

function UnionCreateMediator:initView()
    local actionButtons     = self:getViewData().actionButtons
    local commonEditView    = self:getViewData().commonEditView
    local head              = self:getViewData().head
    local unionNameBox      = self:getViewData().unionNameBox

    for tag,btn in pairs(actionButtons) do
       display.commonUIParams(btn, {cb = handler(self, self.onButtonAction), animate = false})
    end
    head:setTexture(CommonUtils.GetGoodsIconPathById(self.defHeadId))

    unionNameBox:registerScriptEditBoxHandler(handler(self, self.onEditNameAction))
end

function UnionCreateMediator:CleanupView()
    
end


function UnionCreateMediator:OnRegist()
    regPost(POST.UNION_CREATE)
end
function UnionCreateMediator:OnUnRegist()
    unregPost(POST.UNION_CREATE)
end


function UnionCreateMediator:InterestSignals()
    return {
        POST.UNION_CREATE.sglName,
        CHNAGE_UNION_HEAD_EVENT,

        FRIEND_REFRESH_EDITBOX,
    }
end

function UnionCreateMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()

    if name == POST.UNION_CREATE.sglName then
        
        CommonUtils.DrawRewards({{goodsId = DIAMOND_ID, num = -1 * UNION_CREATE_DIAMOND}})
        local unionId = body.unionId
        local gameMgr = self:GetFacade():GetManager('GameManager')
        gameMgr:setUnionId(unionId)
        -- 加入工会聊天室
        unionMgr:JoinUnionChatRoom()
        AppFacade.GetInstance():DispatchObservers(UNION_JOIN_SUCCESS)
       
    elseif name == CHNAGE_UNION_HEAD_EVENT then
        local iconId = tostring(body.iconId or '101')
        if iconId ~= self.defHeadId then
            self.defHeadId = iconId
            local head = self:getViewData().head
            head:setTexture(CommonUtils.GetGoodsIconPathById(iconId))
        end
    elseif name == FRIEND_REFRESH_EDITBOX then
        local unionNameBox      = self:getViewData().unionNameBox
        local isEnabled = body.isEnabled == nil and true or body.isEnabled
        unionNameBox:setVisible(isEnabled)
    end
end

-------------------------------------------------
-- get / set

function UnionCreateMediator:getViewData()
    return self.viewData_
end

function UnionCreateMediator:getIsControllable()
    return self.isControllable_
end
function UnionCreateMediator:setIsControllable(isControllable)
    self.isControllable_ = isControllable
end

-- get / set
-------------------------------------------------

-------------------------------------------------
-- handle

--==============================--
--desc: 处理按钮事件
--time:2018-01-04 04:19:31
--@sender:
--@return 
--==============================-- 
function UnionCreateMediator:onButtonAction(sender)
    if not self:getIsControllable() then return end
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    
    if tag == BTN_TAG.TAG_HEAD then
        print('onButtonAction TAG_HEAD')
        local data = {type = 4}
        local mediator = require('Game.mediator.ChangeUnionHeadOrHeadFrameMediator')
        local mediatorIns = mediator.new(data)
        self:GetFacade():RegistMediator(mediatorIns)

    elseif tag == BTN_TAG.TAG_CREATE then
        -- self:SendSignal(POST.UNION_CREATE.cmdName)
        local ownCurrencyCount = gameMgr:GetAmountByIdForce(DIAMOND_ID)
        if ownCurrencyCount < UNION_CREATE_DIAMOND then
            if GAME_MODULE_OPEN.NEW_STORE then
                app.uiMgr:showDiamonTips()
            else
                uiMgr:ShowInformationTips(__('当前幻晶石不足，无法创建。'))
            end
            return
        end

        local name = self:getViewData().unionNameBox:getText()
        if self:checkNameRightful(name) then
			uiMgr:ShowInformationTips(__('请输入工会名'))
			return
		end
        local avatar = self.defHeadId
        local unionSign = self:getViewData().commonEditView:getText()

        local data = {name = name, avatar = avatar, unionSign = unionSign}
        if not CommonUtils.CheckIsDisableInputDay() then
            self:SendSignal(POST.UNION_CREATE.cmdName, data)
        end
    end
end

--==============================--
--desc: 编辑工会名字 相关事件处理
--time:2018-01-04 04:18:44
--@eventType: 事件类型
--@sender: 
--@return 
--==============================-- 
function UnionCreateMediator:onEditNameAction(eventType, sender)
    if eventType == 'began' then  -- 输入开始
    end
end

-- handle
-------------------------------------------------

-------------------------------------------------
-- check

--==============================--
--desc:  检查公会名 合法状态
--time:2018-01-04 04:20:16
--@name:
--@return 
--==============================-- 
function UnionCreateMediator:checkNameRightful(name)
    return nil == name or string.len(string.gsub(name, " ", "")) <= 0
end

return UnionCreateMediator
