--[[
 * author : liuzhipeng
 * descpt : 图鉴 飨灵收集册 任务Mediator
--]]
local CardAlbumTaskMediator = class('CardAlbumTaskMediator', mvc.Mediator)
local NAME = 'collection.cardAlbum.CardAlbumTaskMediator'
function CardAlbumTaskMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    local args = checktable(params)
    self.unlockTask = args.unlockTask or {}
    self.cardIds = args.cardIds or {}
    self.bookId = checkint(args.id)
    self.drawTaskIdList = {}
    self.isGoto = false
end
-------------------------------------------------
------------------ inheritance ------------------
function CardAlbumTaskMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.collection.cardAlbum.CardAlbumTaskView').new()
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData

    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.closeBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawAllButtonCallback))
    viewData.taskGridView:setCellUpdateHandler(handler(self, self.OnUpdateGoodsListCellHandler))
    viewData.taskGridView:setCellInitHandler(handler(self, self.OnInitGoodsListCellHandler))
    self:ConvertHomeData()
    self:SortFunction()
    self:InitView()
end
    
function CardAlbumTaskMediator:InterestSignals()
    local signals = {
        POST.CARD_ALBUM_TASK_DRAW.sglName,
    }
    return signals
end
function CardAlbumTaskMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.CARD_ALBUM_TASK_DRAW.sglName then
        self:DrawTaskResponseHandler(body)
    end
end

function CardAlbumTaskMediator:OnRegist()
    regPost(POST.CARD_ALBUM_TASK_DRAW)
end
function CardAlbumTaskMediator:OnUnRegist()
    unregPost(POST.CARD_ALBUM_TASK_DRAW)
    -- 移除界面
    local viewComponent = self:GetViewComponent()
    viewComponent:CloseAction()
    
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function CardAlbumTaskMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    if next(self.drawTaskIdList) ~= nil then
        app:DispatchObservers('CARD_ALBUM_TASK_DRAW_SIGNAL', {taskIdList = self.drawTaskIdList, bookId = self.bookId})
    end
    app:UnRegsitMediator(NAME)
end
--[[
一键领取按钮点击回调
--]]
function CardAlbumTaskMediator:DrawAllButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self:GetHomeData()
    local idList = {}
    for i, v in ipairs(homeData) do
        if v.canDraw and not v.hasDrawn then
            table.insert(idList, v.id)
        end
    end
    if next(idList) ~= nil then
        local taskIds = table.concat(idList, ',', 1)
        self:SendSignal(POST.CARD_ALBUM_TASK_DRAW.cmdName, {bookId = self.bookId, taskIds = taskIds})
    else
        app.uiMgr:ShowInformationTips(__('已全部领取'))
    end
end
--[[
任务领取按钮回调
--]]
function CardAlbumTaskMediator:TasksDrawBtnCallback( sender )
    if self.isGoto then return end
	PlayAudioByClickNormal()
    local tag = sender:getTag()
    local homeData = self:GetHomeData()
    local taskData = homeData[tag]
    if checkint(taskData.progress) >= checkint(taskData.targetNum) then
        self:SendSignal(POST.CARD_ALBUM_TASK_DRAW.cmdName, {bookId = self.bookId, taskIds = tostring(taskData.id)})
    else
        app.uiMgr:ShowInformationTips(__('未完成'))
        -- 跳转先注释掉，因为策划又搞了一套新的任务类型和之前的不通用，不想给他再单独写一套跳转
        -- app:UnRegsitMediator(NAME)
        -- CommonUtils.JumpModuleByTaskData( taskData )
        -- sceneWorld:runAction(
        --     cc.Sequence:create(
        --         cc.CallFunc:create(function()
        --             self.isGoto = true
        --         end),
        --         cc.DelayTime:create(2) ,
        --         cc.CallFunc:create(function()
        --             self.isGoto = false
        --         end)
        --     )
        -- )
    end
end
--[[
列表刷新
--]]
function CardAlbumTaskMediator:OnUpdateGoodsListCellHandler( cellIndex, cellViewData )
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    local taskData = homeData[cellIndex]
    cellViewData.button:setTag(cellIndex)
    viewComponent:RefreshTaskState(cellViewData, taskData)
end
--[[
列表cell初始化
--]]
function CardAlbumTaskMediator:OnInitGoodsListCellHandler( cellViewData )
    cellViewData.button:setOnClickScriptHandler(handler(self, self.TasksDrawBtnCallback))
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function CardAlbumTaskMediator:InitView()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:GetViewData().taskGridView:resetCellCount(#homeData)
end
--[[
转化homeData
--]]
function CardAlbumTaskMediator:ConvertHomeData()
    local taskConf = CONF.CARD.CARD_COLL_TASK:GetAll()
    local homeData = {}
    for k, v in pairs(taskConf) do
        local data = clone(v)
        data.hasDrawn = false

        if self.unlockTask[checkint(v.id)] then
            data.hasDrawn = true
        end
        
        if data.hasDrawn then
            data.canDraw = true
        else
            data.canDraw, data.progress = app.cardMgr.IsCardAlbumTaskComplete(v, self.cardIds)
        end
        table.insert(homeData, data)
    end
    self:SetHomeData(homeData)
end
--[[
任务领取处理
--]]
function CardAlbumTaskMediator:DrawTaskResponseHandler(data)
    local requestData = data.requestData
    local taskIds = requestData.taskIds
    if taskIds == '' then return end
    local idList = string.split(taskIds, ',')
    local homeData = self:GetHomeData()
    for _, taskId in ipairs(idList) do
        for k, v in pairs(homeData) do
            if checkint(v.id) == checkint(taskId) then
                v.hasDrawn = true
                break
            end
        end
    end
    self:SortFunction()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    viewData.taskGridView:reloadData()
    app.uiMgr:ShowInformationTips(__('领取成功'))
    -- 记录领取过的任务
    table.insertto(self.drawTaskIdList, idList)

    AppFacade.GetInstance():DispatchObservers(SGL.CARD_COLL_GET_REWARD_HANDLER, {idList = idList, groupId = self.bookId})
end
--[[
任务排序
--]]
function CardAlbumTaskMediator:SortFunction()
    local homeData = self:GetHomeData()
    table.sort(homeData, function(aTaskData , bTaskData)
        local isTrue  = true
        if aTaskData.hasDrawn ==  bTaskData.hasDrawn then
            if aTaskData.hasDrawn  == true then
                if checkint(aTaskData.id) >= checkint(bTaskData.id)  then
                     isTrue = false
                else
                    isTrue = true
                end
            else
                local aReady = 0
                local bReady = 0
                if checkint(aTaskData.progress) >= checkint(aTaskData.targetNum) then
                    aReady = 1
                end
                if checkint(bTaskData.progress) >= checkint(bTaskData.targetNum) then
                    bReady = 1
                end
                if aReady == bReady  then
                    if checkint(aTaskData.id) >= checkint(bTaskData.id)  then
                        isTrue = false
                    else
                        isTrue = true
                    end
                else
                    isTrue = aReady > bReady and true or false
                end
            end
        else
            if aTaskData.hasDrawn  then
                isTrue = false
            else
                isTrue = true
            end
        end
        return isTrue
    end)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function CardAlbumTaskMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function CardAlbumTaskMediator:GetHomeData()
    return self.homeData
end
------------------- get / set -------------------
-------------------------------------------------
return CardAlbumTaskMediator