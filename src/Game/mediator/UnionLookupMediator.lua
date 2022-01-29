--[[
 * descpt : 工会查找 中介者
]]
local NAME = 'UnionLookupMediator'
local UnionLookupMediator = class(NAME, mvc.Mediator)

local BTN_TAG = {
	BTN_SHAKE     = 100,
	BTN_SEARCH    = 101,
	BTN_APPLY     = 102,
}

-- local unionAvatar = CommonUtils.GetConfigAllMess('avatar','union')
local uiMgr    = AppFacade.GetInstance():GetManager('UIManager')
local unionMgr = AppFacade.GetInstance():GetManager('UnionManager')

function UnionLookupMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)

    self.unions = {}
    self.curSelectIndex = self.ctorArgs_.selectIndex or 1

    -- dump(CommonUtils.GetConfig('union', 'avatar', 1), 'UnionLookupMediator222')
end

-------------------------------------------------
-- inheritance method

function UnionLookupMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true

    -- create view
    local view = require('Game.views.UnionLookupView').new()
    self.viewData_ = view:getViewData()
    self:SetViewComponent(view)
    -- init view
    self:initView()
end

function UnionLookupMediator:initView()
    local listViewData = self:getViewData().listViewData
    local gridView     = listViewData.gridView
    local shakeBtn     = listViewData.shakeBtn
    local searchBtn    = listViewData.searchBtn

    local infoViewData = self:getViewData().infoViewData
    local applyBtn = infoViewData.applyBtn

    gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))

    display.commonUIParams(shakeBtn,  {cb = handler(self, self.onButtonAction)})
    display.commonUIParams(searchBtn, {cb = handler(self, self.onButtonAction)})
    display.commonUIParams(applyBtn,  {cb = handler(self, self.onButtonAction)})
    -- local headBg = infoViewData.headBg
    -- local unionNameLabel = infoViewData.unionNameLabel
    -- local labels = infoViewData.labels
    -- local unionDescLabel = infoViewData.unionDescLabel

end


function UnionLookupMediator:OnRegist()
    regPost(POST.UNION_SEARCH)
    regPost(POST.UNION_APPLY)

    self:enterLayer()
end
function UnionLookupMediator:OnUnRegist()
    unregPost(POST.UNION_APPLY)
    unregPost(POST.UNION_SEARCH)
end

function UnionLookupMediator:InterestSignals()
    return {
        POST.UNION_SEARCH.sglName,
        POST.UNION_APPLY.sglName,
    }
end

function UnionLookupMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = checktable(signal:GetBody())

    if name == POST.UNION_SEARCH.sglName then

        local requestData = body.requestData
        -- dump(body)
        local unions = body.unions ~= nil and body.unions or {}

        if next(unions) == nil then
            local tipText = nil
            if requestData then
                tipText = __('未找到该工会')
            else
                tipText = __('当前尚无工会成立。')
                -- self:updateApplyBtnState(false)
                self:updateUnionInfoShowState(true)
            end
            uiMgr:ShowInformationTips(tipText)
            return
        end

        self.unions = unions

        self.curSelectIndex = 1
        self:updateUnionInfo()
        self:updateList()
    elseif name == POST.UNION_APPLY.sglName then
        self.unions[self.curSelectIndex].hasApplied = 1
        -- todo  更新 申请加入状态
        uiMgr:ShowInformationTips(__('申请成功'))

        self:updateApplyBtnState()

    end

end

function UnionLookupMediator:enterLayer(data)
    self:SendSignal(POST.UNION_SEARCH.cmdName, data)
    -- self:GetFacade():DispatchObservers(POST.UNION_SEARCH.sglName, data)
end

-------------------------------------------------
-- action
function UnionLookupMediator:onButtonAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()

    if tag == BTN_TAG.BTN_SHAKE then
        self:enterLayer()
    elseif tag == BTN_TAG.BTN_SEARCH then
        local listViewData = self:getViewData().listViewData
        local searchBox = listViewData.searchBox

        local text = searchBox:getText()
        if text == '' then
            uiMgr:ShowInformationTips(__('未输入工会名或工会ID'))
            return
        end

        self:enterLayer({keyword = text})
    elseif tag == BTN_TAG.BTN_APPLY then
        local data = self.unions[self.curSelectIndex]
        if data == nil then
            return
        end

        local isHasApplied = checkint(data.hasApplied) == 1
        if isHasApplied then
            uiMgr:ShowInformationTips(__('您已申请过该工会，请勿重复申请。'))
            return
        end

        local level = checkint(data.level) or 1
        local memberNumber = checkint(data.memberNumber)
        local unionNum = checkint(unionMgr:GetUnionMemberLimitNumByLevel(level))
        if memberNumber >= unionNum then
            uiMgr:ShowInformationTips(__('您已申请的工会，人数已满。'))
            return
        end

        local unionId = data.unionId
        self:SendSignal(POST.UNION_APPLY.cmdName, {unionId = unionId})
    end
end

function UnionLookupMediator:onClickCellAction(sender)
    local cell = sender:getParent()
    local index = cell:getTag()
    if index == self.curSelectIndex then return end

    self:updateCellSelectState(cell, self.curSelectIndex)
    self.curSelectIndex = index

    self:updateUnionInfo()
end

function UnionLookupMediator:onDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateCell()

        display.commonUIParams(pCell.viewData.touchLayer, {cb = handler(self, self.onClickCellAction)})
    end

    xTry(function()
        local viewData        = pCell.viewData

        local unionInfoLabels = viewData.unionInfoLabels

        local data = self.unions[index]

        local unionLv = string.format("%s/%s", data.memberNumber, unionMgr:GetUnionMemberLimitNumByLevel(data.level))
        local cellData = {data.unionId, data.name, data.level, unionLv}

        local isSelect = index == self.curSelectIndex
        self:updateSelectState(pCell, isSelect)
        for i,label in ipairs(unionInfoLabels) do
            display.commonLabelParams(label, {text = cellData[i]})
        end

        pCell:setTag(index)
	end,__G__TRACKBACK__)

    return pCell
end
-- action
-------------------------------------------------

function UnionLookupMediator:updateList()
    local listViewData = self:getViewData().listViewData
    local gridView     = listViewData.gridView
    gridView:setCountOfCell(#self.unions)
    gridView:reloadData()
end

function UnionLookupMediator:updateCellSelectState(newCell, oldIndex)
    if newCell == nil then return end

    local listViewData = self:getViewData().listViewData
    local gridView     = listViewData.gridView
    if oldIndex ~= nil and oldIndex > 0 then
        local oldCell = gridView:cellAtIndex(oldIndex - 1)
        if oldCell then
            self:updateSelectState(oldCell, false)
        end
    end

    self:updateSelectState(newCell, true)
end

function UnionLookupMediator:updateSelectState(cell, isSelect)
    if cell == nil then
        return
    end
    local viewData        = cell.viewData
    local frame           = viewData.frame
    local defaultBg       = viewData.defaultBg
    local selectBg        = viewData.selectBg

    frame:setVisible(isSelect)
    selectBg:setVisible(isSelect)
    defaultBg:setVisible(not isSelect)
end

function UnionLookupMediator:updateUnionInfoShowState(isShowTip)
    local infoViewData = self:getViewData().infoViewData

    local unionInfoTipLayer    = infoViewData.unionInfoTipLayer
    local unionInfoLayer       = infoViewData.unionInfoLayer

    unionInfoTipLayer:setVisible(isShowTip)
    unionInfoLayer:setVisible(not isShowTip)
end

--==============================--
--desc: 更新工会信息
--time:2018-01-04 04:21:50
--@return
--==============================--
function UnionLookupMediator:updateUnionInfo()
    local infoViewData = self:getViewData().infoViewData

    self:updateUnionInfoShowState(false)

    local headBg         = infoViewData.headBg
    local head           = infoViewData.head
    local unionNameLabel = infoViewData.unionNameLabel
    local labels         = infoViewData.labels
    local commonEditView = infoViewData.commonEditView

    local data = self.unions[self.curSelectIndex] or {}
    local avatar       = tostring(data.avatar) or '101'
    local name         = tostring(data.name)
    local unionSign    = tostring(data.unionSign)
    local chairmanName = tostring(data.chairmanName)
    local level        = tostring(data.level)
    local memberNumber = tostring(data.memberNumber)


    local labelConf = {tostring(data.chairmanName), tostring(data.level), tostring(data.memberNumber)}
    -- CommonUtils.GetConfig('union', 'avatar', level)
    head:setTexture(CommonUtils.GetGoodsIconPathById(avatar))
    display.commonLabelParams(unionNameLabel, {text = name})
    -- display.commonLabelParams(commonEditView, {text = unionSign})
    -- display.reloadRichLabel(commonEditView, {c = {fontWithColor(6, {text = unionSign})}})
    commonEditView:setText(unionSign)
    for i,label in ipairs(labels) do
        display.commonLabelParams(label, {text = labelConf[i]})
    end

    self:updateApplyBtnState()

end

function UnionLookupMediator:updateApplyBtnState(isEnable)
    local infoViewData   = self:getViewData().infoViewData
    local applyBtn       = infoViewData.applyBtn
    local data           = self.unions[self.curSelectIndex] or {}
    local isNotHasApplied   = data.hasApplied == 0

    local img = isNotHasApplied and _res('ui/common/common_btn_orange.png') or _res('ui/common/common_btn_orange_disable.png')
    applyBtn:setNormalImage(img)
    applyBtn:setSelectedImage(img)

    local isEnable = isEnable == nil and true or isEnable
    applyBtn:setEnabled(isEnable)
end

-------------------------------------------------
-- get / set
function UnionLookupMediator:getViewData()
    return self.viewData_
end

function UnionLookupMediator:getAppRouter()
    return AppFacade.GetInstance():RetrieveMediator('Router')
end

return UnionLookupMediator
