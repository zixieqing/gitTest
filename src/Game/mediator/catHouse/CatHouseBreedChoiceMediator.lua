--[[
 * author : liuzhipeng
 * descpt : 猫屋 繁殖选择Mediator
--]]
local CatHouseBreedChoiceMediator = class('CatHouseBreedChoiceMediator', mvc.Mediator)
local NAME = 'catHouse.CatHouseBreedChoiceMediator'
function CatHouseBreedChoiceMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    local args = checktable(params)
    self.catUuid = args.catUuid
    self:SetCatData(checktable(args.breedData))
end
-------------------------------------------------
------------------ inheritance ------------------
function CatHouseBreedChoiceMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.catHouse.CatHouseBreedChoiceView').new()
    viewComponent:setPosition(display.center) 
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData

    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewComponent.viewData.femaleBtn:setOnClickScriptHandler(handler(self, self.ChoiceButtonCallback))
    viewComponent.viewData.maleBtn:setOnClickScriptHandler(handler(self, self.ChoiceButtonCallback))
    viewComponent.viewData.femaleCancelBtn:setOnClickScriptHandler(handler(self, self.CancelButtonCallback))
    viewComponent.viewData.maleCancelBtn:setOnClickScriptHandler(handler(self, self.CancelButtonCallback))
    viewComponent.viewData.femaleAcceptBtn:setOnClickScriptHandler(handler(self, self.AcceptButtonCallback))
    viewComponent.viewData.maleAcceptBtn:setOnClickScriptHandler(handler(self, self.AcceptButtonCallback))

    self:RefreshView()
    self:PreLoadCat(self.catUuid)
end
    
function CatHouseBreedChoiceMediator:InterestSignals()
    local signals = {
        SGL.CAT_HOUSE_BREED_INVITE_SUCCESS,
        SGL.CAT_HOUSE_BREED_REFRESH_CHOICE_VIEW,
        SGL.CAT_MODULE_CAT_REFRESH_UPDATE,
        SGL.CAT_HOUSE_BREED_LIST_INVITEE_SELECTED,
        SGL.CAT_MODULE_CAT_MATING_ANSWER,
    }
    return signals
end
function CatHouseBreedChoiceMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == SGL.CAT_HOUSE_BREED_INVITE_SUCCESS then
        self:AddInvitee()
    elseif name == SGL.CAT_HOUSE_BREED_REFRESH_CHOICE_VIEW then
        self:AddInviter(body)
    elseif name == SGL.CAT_MODULE_CAT_REFRESH_UPDATE then
        self:RefershUpdate()
    elseif name == SGL.CAT_HOUSE_BREED_LIST_INVITEE_SELECTED then
        self:SelectedInvitee(body)
    elseif name == SGL.CAT_MODULE_CAT_MATING_ANSWER then
        self:MatingAnswer(body.data)
    end
end

function CatHouseBreedChoiceMediator:OnRegist()
end

function CatHouseBreedChoiceMediator:OnUnRegist()
end

function CatHouseBreedChoiceMediator:CleanupView()
    -- 移除界面
    if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
        self:GetViewComponent():removeFromParent()
        self:SetViewComponent(nil)
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function CatHouseBreedChoiceMediator:BackButtonCallback( sender )
    PlayAudioByClickNormal()
    app:UnRegistMediator(NAME)
end
--[[
选择按钮点击回调
--]]
function CatHouseBreedChoiceMediator:ChoiceButtonCallback( sender )
    local catData = self:GetCatData()
    local sex = sender:getTag()
    if catData.state == CatHouseUtils.CAT_BREED_STATE.INVITED then
        if sex == checkint(catData.inviterData.sex) then
            -- 邀请者，不可点击
        else
            PlayAudioByClickNormal()
            local mediator = require("Game.mediator.catHouse.CatHouseBreedListMediator").new({sex = sex, inviterData = catData.inviterData})
            app:RegistMediator(mediator)
        end
        return 
    end
    if catData.catModel and catData.catModel:hasMatingData() then
        -- 生育中
        return
    end
    if catData.catModel and catData.catModel:isHousing() then
        if catData.catModel:getSex() == sex then
            -- 进入选中状态，不可更改
        else
            -- 邀请好友
            PlayAudioByClickNormal()
            local inviteMediator = require('Game.mediator.catHouse.CatHouseBreedInviteMediator').new({catModel = catData.catModel})
            app:RegistMediator(inviteMediator)
        end
        return
    end
    PlayAudioByClickNormal()
    local mediator = require("Game.mediator.catHouse.CatHouseBreedListMediator").new({sex = sex, inviterData = catData.inviterData})
	app:RegistMediator(mediator)
end
--[[
取消配对按钮点击回调
--]]
function CatHouseBreedChoiceMediator:CancelButtonCallback( sender )
    local catData = self:GetCatData()
    local sex = sender:getTag()
    PlayAudioByClickNormal()
    local CommonTip  = require( 'common.CommonTip' ).new({text = __('是否确认取消？'), descr = __('取消后将撤回好友申请'),
    isOnlyOK = false, callback = function ()
        app:DispatchObservers(SGL.CAT_HOUSE_BREED_PAIRING_CANCEL, {catModel = catData.catModel})
        app:UnRegistMediator(NAME)
    end})
    CommonTip:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
end
--[[
接受按钮点击回调
--]]
function CatHouseBreedChoiceMediator:AcceptButtonCallback( sender )
    local catData = self:GetCatData()
    local inviteeData = self:GetInviteeData()
    local sex = sender:getTag()
    PlayAudioByClickNormal()
    app.catHouseMgr:replyCatMatingRequest(inviteeData.inviterData.friendCatId, inviteeData.catModel:getPlayerCatId())
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function CatHouseBreedChoiceMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshView(self:GetCatData())
end
--[[
定时刷新
--]]
function CatHouseBreedChoiceMediator:RefershUpdate()
    local catData = self:GetCatData()
    if catData.state == CatHouseUtils.CAT_BREED_STATE.INVITED then
        self:GetViewComponent():UpdateInviteCountdown(catData.inviterData.sex, catData.inviterData.timestamp - os.time())
        if catData.inviterData.timestamp - os.time() <= 0 then
            app.uiMgr:ShowInformationTips(__('邀请已过期'))
            self:Close()
        end
    elseif catData.state == CatHouseUtils.CAT_BREED_STATE.BREEDING then
        if catData.catModel then
            if catData.catModel:getMatingLeftSeconds() > 0 then
                self:GetViewComponent():UpdateBreedCountdown(catData.catModel:getMatingLeftSeconds())
            else
                app:UnRegistMediator(NAME)
            end
        end
    end
end
--[[
添加邀请人
@params catData map
{
    state int 状态
    catModel HouseCatModel 猫咪模块
}
--]]
function CatHouseBreedChoiceMediator:AddInviter( catData )
    self:SetCatData(catData)
    self:RefreshView()
end
--[[
添加被邀请人
--]]
function CatHouseBreedChoiceMediator:AddInvitee()
    self:RefreshView()
end
--[[
选择受邀者
--]]
function CatHouseBreedChoiceMediator:SelectedInvitee( params )
    local catData = self:GetCatData()
    self:SetInviteeData(params)

    if checkint(catData.inviterData.friendCatId) == checkint(params.inviterData.friendCatId) then
        self:GetViewComponent():RefreshInvitee(params)
    end
end
--[[
交配邀请应答
--]]
function CatHouseBreedChoiceMediator:MatingAnswer( params )
    local eventData = self:GetInviteeData().inviterData
    if params.result == 1 and params.friendCatId == eventData.friendCatId then
        -- 交配成功，更新猫咪数据模型
        local birthConf  = CONF.CAT_HOUSE.CAT_BIRTH:GetValue(eventData.generation)
        local matingTime = checkint(birthConf.birthTime)
        ---@type HouseCatModel
        local catModel   = self:GetInviteeData().catModel
        catModel:setMatingData({
            friendId    = checkint(eventData.friendId),    -- 好友id
            friendCatId = checkint(eventData.friendCatId), -- 好友猫咪唯一id
            catId       = checkint(eventData.catId),       -- 猫咪种族
            name        = tostring(eventData.name),        -- 猫咪名字
            gene        = clone(eventData.gene),           -- 猫咪基因
            generation  = checkint(eventData.generation),  -- 猫咪代数
            age         = checkint(eventData.age),         -- 猫咪年龄
            sex         = checkint(eventData.sex),         -- 猫咪性别
            ability     = clone(eventData.ability),        -- 猫咪能力
            attr        = clone(eventData.attr),           -- 猫咪属性
            rebirth     = checkint(eventData.rebirth),     -- 是否回归
            leftSeconds = matingTime,                      -- 剩余时间
            isInvite    = 0,                               -- 是否邀请人
        })
        app.catHouseMgr:updateCatLogicByAcceptInvite(catModel:getUuid())
        -- tips
        app.uiMgr:ShowInformationTips(__('成功接受好友的交配邀请'))
        app:UnRegistMediator(NAME)
    end
end
--[[
预载一只猫咪
--]]
function CatHouseBreedChoiceMediator:PreLoadCat( catUuid )
    if not catUuid then return end
    local breedData = self:GetCatData()
    if breedData.state ~= 1 then return end

    local catModel = app.catHouseMgr:getCatModel(catUuid)
    if catModel:checkMatingToFriend(nil, true) then
        local mediator = require("Game.mediator.catHouse.CatHouseBreedCostMediator").new({catModel = catModel})
        app:RegistMediator(mediator)
        app:UnRegsitMediator(NAME)
    end
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- public ---------------------
--[[
关闭页面
--]]
function CatHouseBreedChoiceMediator:Close( playerCatId )
    if playerCatId then
        local catData = self:GetCatData()
        local currentPlayerCatId = catData.catModel():getPlayerCatId()
        if currentPlayerCatId ~= playerCatId then
            return
        end
    end
    if app:RetrieveMediator('catHouse.CatHouseBreedListMediator') then
        app:UnRegistMediator('catHouse.CatHouseBreedListMediator')
    end
    if app:RetrieveMediator('catHouse.CatHouseBreedInviteMediator') then
        app:UnRegistMediator('catHouse.CatHouseBreedInviteMediator')
    end
    app:UnRegistMediator(NAME)
end
-------------------- public ---------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置catData
--]]
function CatHouseBreedChoiceMediator:SetCatData( catData )
    self.catData = catData
end
--[[
获取catData
--]]
function CatHouseBreedChoiceMediator:GetCatData()
    return self.catData
end
--[[
设置受邀者数据
--]]
function CatHouseBreedChoiceMediator:SetInviteeData( inviteeData )
    self.inviteeData = inviteeData
end
--[[
获取受邀者数据
--]]
function CatHouseBreedChoiceMediator:GetInviteeData()
    return self.inviteeData
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedChoiceMediator