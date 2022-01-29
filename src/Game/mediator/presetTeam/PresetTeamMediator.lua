--- 预设编队mediator
---@param data table {
---  @field selectIndex number 当前选择的下标
---  @field isEditMode boolean 是否是编辑模式
---  @field isSelectMode boolean 是否是选择模式
---  @field presetTeamTypes PRESET_TEAM_TYPE 预设编队类型列表
---}s
local Mediator = mvc.Mediator
---@class PresetTeamMediator
local PresetTeamMediator = class("PresetTeamMediator", mvc.Mediator)


------------ import ------------
------------ import ------------

------------ define ------------
local display = display
local POST = POST
local NAME = "presetTeam.PresetTeamMediator"
local EXIT_PRESET_TEAM_EDIT_TEAM_MEDIATOR = "EXIT_PRESET_TEAM_EDIT_TEAM_MEDIATOR"
---@type PRESET_TEAM_TYPE
local PRESET_TEAM_TYPE = PRESET_TEAM_TYPE
local PRESET_TEAM_CONF = PRESET_TEAM_DEFINES

local PRESET_TEAM_LOCAL_INFO = {
    ---  世界boss  本地自定义队伍id key                   本地自定义队伍key
    {"LOCAL_WB_TEAM_CUSTOM_ID_KEY",              "LOCAL_WB_TEAM_MEMBERS_KEY"}
}

------------ define ------------

--[[
constructor
--]]
function PresetTeamMediator:ctor(params, viewComponent)
	Mediator.ctor(self, NAME, viewComponent)
    
	self:InitData(params or {})
end

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function PresetTeamMediator:InterestSignals()
	local signals = {
        ------------ server ------------
        POST.PRESET_TEAM_GET_TEAM_CUSTOM_LIST.sglName, --- 获取自定义编队信息
        POST.PRESET_TEAM_SET_TEAM_CUSTOM.sglName, --- 设置自定义编队信息

        ------------ local ------------
        EXIT_PRESET_TEAM_EDIT_TEAM_MEDIATOR,
        SGL.PRESET_TEAM_SELECT_CARDS,
	}

	return signals
end

function PresetTeamMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local responseData = signal:GetBody()

    if name == POST.PRESET_TEAM_GET_TEAM_CUSTOM_LIST.sglName then
        local info = responseData.info or {}
        local datas = {}
        for i, v in ipairs(info) do
            local cellIndex = checkint(v.cellIndex)
            local type = checkint(v.type)
            datas[type] = datas[type] or {}
            datas[type][cellIndex] = v
        end

        self.datas = datas

        self:InitTableViewByType(self:GetCurPresetType())


    -------------------------------------------------
    elseif name == POST.PRESET_TEAM_SET_TEAM_CUSTOM.sglName then
        local requestData = responseData.requestData or {}
        local cellIndex = requestData.cellIndex

        local cardJson = requestData.cardJson
        local cardDatas = json.decode(cardJson) or {}
        local cardIds = {}
        for teamIndex, teamDataList in pairs(cardDatas) do
            cardIds[teamIndex] = cardIds[teamIndex] or {}
            for i, v in ipairs(teamDataList) do
                if v.id then
                    cardIds[teamIndex][i] = v.id
                end
            end
        end

        local serverType = self:GetDataIndexByPresetType()
        self.datas[serverType] = self.datas[serverType] or {}
        self.datas[serverType][cellIndex] = self.datas[serverType][cellIndex] or {}

        local presetTeamData = self.datas[serverType][cellIndex]
        local teamId = responseData.teamId
        presetTeamData.teamId  = teamId
        presetTeamData.valid   = 1
        presetTeamData.lock    = 0
        presetTeamData.name    = requestData.name
        presetTeamData.type    = requestData.type
        presetTeamData.cardIds = cardIds
        
        local presetTeamType = self:GetCurPresetType()
        local conf = PRESET_TEAM_CONF[presetTeamType]
        --- 更新本地数据
        local playerId = app.gameMgr:GetUserInfo().playerId
        local userDefault = cc.UserDefault:getInstance()
        for i, v in ipairs(PRESET_TEAM_LOCAL_INFO) do
            local realTeamIdKey = table.concat({tostring(playerId), v[1]})
            local teamCustomId = checkint(userDefault:getIntegerForKey(realTeamIdKey))
            if teamCustomId == checkint(teamId) then
                local realTeamDataKey = table.concat({tostring(playerId), v[2]})
                local cards = {}
                for teamIndex, cardIdList in pairs(cardIds) do
                    for i = 1, conf.cardCount do
                        local playerCardId = cardIdList[i]
                        if playerCardId then
                            table.insert(cards, {id = playerCardId})
                        else
                            table.insert(cards, {})
                        end
                    end
                end
                local str = json.encode(cards)
                userDefault:setStringForKey(realTeamDataKey, str)
                userDefault:flush()
            end
        end

        --- 刷新列表
        local tableView = self:GetViewComponent():GetCurTableView(presetTeamType)
        tableView:updateCellViewData(cellIndex)


    -------------------------------------------------
    elseif name == EXIT_PRESET_TEAM_EDIT_TEAM_MEDIATOR then
        self:GetViewComponent():setVisible(true)

    -------------------------------------------------
    elseif name == SGL.PRESET_TEAM_SELECT_CARDS then
        self:GetFacade():UnRegsitMediator(NAME)
    end
end

function PresetTeamMediator:Initial(key)
	self.super.Initial(self, key)
end

function PresetTeamMediator:OnRegist()
	-- 初始化界面
	self:InitView()

	-- 注册信号
    regPost(POST.PRESET_TEAM_GET_TEAM_CUSTOM_LIST)

    self:EnterLayer()
end

function PresetTeamMediator:OnUnRegist()
	
	-- 注销信号
    unregPost(POST.PRESET_TEAM_GET_TEAM_CUSTOM_LIST)

    self:ExitMediator()
end

function PresetTeamMediator:EnterLayer()
    self:SendSignal(POST.PRESET_TEAM_GET_TEAM_CUSTOM_LIST.cmdName)
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------

---InitData
---@param data table {
---  @field selectIndex number 当前选择的下标
---  @field isEditMode boolean 是否是编辑模式
---  @field isSelectMode boolean 是否是选择模式
---  @field presetTeamTypes PRESET_TEAM_TYPE 预设编队类型列表
---}
function PresetTeamMediator:InitData(data)
    self.selectIndex = data.selectIndex or 1
    self.isControllable_ = true
    self.isEditMode = data.isEditMode == true
    self.isSelectMode = data.isSelectMode == true
    self.presetTeamTypes = data.presetTeamTypes or {PRESET_TEAM_TYPE.FIVE_DEFAULT}

    table.sort(self.presetTeamTypes)

end

function PresetTeamMediator:InitView()

    ---@type PresetTeamView
    local viewComponent = require('Game.views.presetTeam.PresetTeamView').new({
        mediatorName = NAME, 
        isEditMode = self.isEditMode, 
        isSelectMode = self.isSelectMode,
        moduleTypes = self.presetTeamTypes
    })
    local viewData      = viewComponent:GetViewData()
    self.viewData_ = viewData
    self:SetViewComponent(viewComponent)
    self:InitOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:GetOwnerScene():AddDialog(viewComponent)

    -- display.commonUIParams(viewData.shadowsLayer, {cb = handler(self, self.OnClickShadowsAction), animate = false})
    display.commonUIParams(viewData.shadowsLayer, {cb = handler(self, self.OnClickShadowsAction), animate = false})

    local tipsBtn = viewData.tipsBtn
    if nil ~= viewData.tipsBtn then
        display.commonUIParams(viewData.tipsBtn, {cb = handler(self, self.OnClickTipsBtnAction), animate = false})
    end

    self:InitTabBtnCellsShowState(viewData)

    ---更新tab按钮显示状态
    viewComponent:UpdateTabBtnShowState(self.selectIndex)

end

function PresetTeamMediator:InitOwnerScene_()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
end

---InitTabBtnCellsShowState
---初始化标签按钮显示状态
---@param viewData table
function PresetTeamMediator:InitTabBtnCellsShowState(viewData)
    if self.isEditMode or self.isSelectMode then return end

    local tabBtnCells = viewData.tabBtnCells
    for i, tabBtnCellViewData in ipairs(tabBtnCells) do
        local tabBtn = tabBtnCellViewData.tabBtn
        display.commonUIParams(tabBtn, {cb = handler(self, self.OnClickTabBtnAction_), animate = false})
        tabBtn:setTag(i)
    end
end

---InitTableViewByType
---根据预设编队类型初始化 table view
---@param presetTeamType PRESET_TEAM_TYPE
function PresetTeamMediator:InitTableViewByType(presetTeamType)
    local tableView = self:GetViewComponent():CreateTableViewByType(presetTeamType, self.isEditMode, self.isSelectMode)
    if tableView == nil then return end

    tableView:setCellUpdateHandler(handler(self, self.OnUpdateCellHandler_))
    tableView:setCellInitHandler(function(cellViewData)
        local cell = cellViewData.cell
        if self.isSelectMode then
            display.commonUIParams(cell:GetViewData().selectTeamBtn, {cb = handler(self, self.OnClickSelectTeamBtnAction)})
            return
        end

        if self.isEditMode then return end

        display.commonUIParams(cell:GetViewData().clickArea, {cb = handler(self, self.OnClickCellAction)})
    end)
    tableView:resetCellCount(self:GetPresetTeamCount())
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
function PresetTeamMediator:ExitMediator()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function PresetTeamMediator:OnUpdateCellHandler_(cellIndex, cellViewData)
    if cellViewData == nil then return end

    local cell = cellViewData.cell
    -- update cell tag
    cell:setTag(cellIndex)
    cell:GetViewData().clickArea:setTag(cellIndex)

    local serverType = self:GetDataIndexByPresetType()
    local data = self.datas[serverType] or {}
    local teamData = data[cellIndex] or {}
    cell:RefreshUI(cellIndex, teamData)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
function PresetTeamMediator:GetViewData()
    return self.viewData_
end

function PresetTeamMediator:GetOwnerScene()
    return self.ownerScene_
end

function PresetTeamMediator:GetDataIndexByPresetType()
    local presetTeamType = self:GetCurPresetType()
    local conf = PRESET_TEAM_CONF[presetTeamType] or {}
    return conf.serverType or 1
end

function PresetTeamMediator:GetCurPresetType()
    return self.presetTeamTypes[self.selectIndex]
end

function PresetTeamMediator:GetPresetTeamCount()
    local presetTeamType = self:GetCurPresetType()
    local conf = PRESET_TEAM_CONF[presetTeamType] or {}
    return conf.saveCount or 1
end

function PresetTeamMediator:GetPresetTeamData(cellIndex)
    local serverType = self:GetDataIndexByPresetType()
    local datas = self.datas[serverType] or {}
    return datas[cellIndex]
end

---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
--- click handler begin --
---------------------------------------------------

---OnClickTabBtnAction
---点击tab btn 事件
---@param sender userdata
function PresetTeamMediator:OnClickTabBtnAction_(sender)
    local index = checkint(sender:getTag())
    PlayAudioByClickNormal()
    if not self.isControllable_ or self.selectIndex == index then return end

    --- 1. 隐藏旧的table view
    local viewComponent = self:GetViewComponent()
    local oldPresetTeamType = self:GetCurPresetType()
    local tableViews = self:GetViewData().tableViews
    local oldTableView = self:GetViewData().tableViews[oldPresetTeamType]
    if self:GetViewData().tableViews[oldPresetTeamType] then
        oldTableView:setVisible(false)
    end

    --- 2. 更新 当前选择的标签下标
    self.selectIndex = index

    --- 3. 显示新的table view
    local curPresetTeamType = self.presetTeamTypes[index]
    local tableView = self:InitTableViewByType(curPresetTeamType)
    if tableView == nil then
        tableViews[curPresetTeamType]:setVisible(true)
    end

    --- 4. 更新 当前选择的标签按钮
    viewComponent:UpdateTabBtnShowState(index)
end

function PresetTeamMediator:OnClickCellAction(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    if self.isSelectMode or self.isEditMode then return end

    local curPresetTeamType = self:GetCurPresetType()
    local cellIndex = checkint(sender:getTag())

    local data = self:GetPresetTeamData(cellIndex) or {}
    if checkint(data.lock) > 0 then
        app.uiMgr:ShowInformationTips(__("该编队已被使用暂无法修改"))
        return
    end

    -- hide team list view
    self:GetViewComponent():setVisible(false)

    -- show team edit view
    local conf = PRESET_TEAM_CONF[curPresetTeamType]
    local PresetTeamEditTeamMediator = require( 'Game.mediator.presetTeam.PresetTeamEditTeamMediator')
    local mediator = PresetTeamEditTeamMediator.new({
        selectIndex = cellIndex,
        conf        = conf,
        data        = data,
        tabType     = self.selectIndex,
    })
    self:GetFacade():RegistMediator(mediator)
end

---选择团队按钮点击事件
---@param sender userdata
function PresetTeamMediator:OnClickSelectTeamBtnAction(sender)
    local cellIndex = checkint(sender:getUserTag())
    local data = self:GetPresetTeamData(cellIndex)

    data = data or {}
    local cardIds = data.cardIds or {}
    local isOwnTeam = false
    for teamIndex, cardIdList in pairs(cardIds) do
        for i, v in pairs(cardIdList) do
            if checkint(v) > 0 then
                isOwnTeam = true
                break
            end
        end
    end

    if not isOwnTeam then
        app.uiMgr:ShowInformationTips(__('请前往飨灵列表界面编队'))
        return
    end

    local isValid = checkint(sender:getTag())
    if data and isValid <= 0 then
        app.uiMgr:ShowInformationTips(__('编队已失效，请重新编辑队伍'))
        return
    end
    
    app:DispatchObservers(SGL.PRESET_TEAM_SELECT_CARDS, { presetTeamData = data})
end


function PresetTeamMediator:OnClickTipsBtnAction()
    app.uiMgr:ShowIntroPopup({moduleId = '-61'})
end

function PresetTeamMediator:OnClickShadowsAction(sender)
    self:GetFacade():UnRegsitMediator(NAME)
end
---------------------------------------------------
--- click handler end --
---------------------------------------------------

return PresetTeamMediator
