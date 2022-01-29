--[[
 * author : liuzhipeng
 * descpt : 活动页面页签列表
--]]
local ActivityTabView = class('ActivityTabView', function()
	local node = CLayout:create()
    node.name = 'views.activity.ActivityTabView'
    node:enableNodeEvents()
	return node
end)

local COMBO_LIST_SIZE = cc.size(250, 640)
local CLASS_BTN_SIZE    = cc.size(250, 60)
local GRIDVIEW_CELL_SIZE = cc.size(212, 82)
local ActivityTabCell = require('home.ActivityTabCell')
local RES_DICT = {
    CLASS_BTN_BG 			      = _res('ui/home/activity/activity_btn_class.png'),
    CLASS_BTN_ANGLE               = _res('ui/home/activity/activity_btn_class_angle.png'),
    GRIDVIEW_BG                   = _res('ui/home/activity/activity_bg_list_new.png'),
    ZH_LIZI                       = _spn('ui/home/capsuleNew/zh_lizi'),
    REMIND_ICON                   = _res('ui/common/common_hint_circle_red_ico.png'),
}
--[[
@params map {
    activityId       int  活动id
    activityClassDataList list 列表数据
} 
--]]
function ActivityTabView:ctor( params )
    local params = checktable(params)
    self.activityClassDataList = {}
    self.classBtnList      = {}  -- 分类按钮list
    self.location          = {class = 1, index = 1}  -- 选中活动的位置
    self.gridViewMap       = nil -- 活动列表节点map
    self.classNum          = nil -- 分类数量
    self.isControllable_   = true

    self:setContentSize(COMBO_LIST_SIZE)
    self:InitView(params)
end

--[[
初始化页面
@params map {
    activityId       int  活动id
    activityClassDataList list 列表数据
} 
--]]
function ActivityTabView:InitView( params )
    if not params or next(params) == nil then return end
    self.activityClassDataList = params.activityClassDataList
    self.classNum = #checktable(self.activityClassDataList)

    -- 移除分类按钮
    self:RemoveClassBtn()
    -- 初始化分类按钮
    self:InitClassBtn(self.activityClassDataList)
    -- 初始化列表位置
    self:InitLocation(params.activityId)
    -- 初始化列表
    self:InitGridView()
    -- 刷新页面
    self:RefreshView()
end
--[[
刷新页面
--]]
function ActivityTabView:RefreshView()
    self:RefreshClassBtn()
    self:RefreshGridView()
    self:SendClickSignal()
end
--[[
初始化列表位置
--]]
function ActivityTabView:InitLocation( activityId )
    if activityId and self:GetLocationByActivityId(activityId) then
        self.location = self:GetLocationByActivityId(activityId) 
    end
end
--[[
初始化分类按钮
--]]
function ActivityTabView:InitClassBtn(params)
    self.classBtnList = {}
    for i, v in ipairs(params) do
        local btn = display.newButton(COMBO_LIST_SIZE.width / 2, COMBO_LIST_SIZE.height / 2, {n = RES_DICT.CLASS_BTN_BG, ap = cc.p(0.5, 0)})
        btn:setTag(i)
        btn:setOnClickScriptHandler(handler(self, self.ClassButtonCallback))
        self:addChild(btn, 3)
        local angle = display.newImageView(RES_DICT.CLASS_BTN_ANGLE, CLASS_BTN_SIZE.width - 35, CLASS_BTN_SIZE.height / 2)
        angle:setName('angle')
        btn:addChild(angle, 1)
        local titleLabel = display.newLabel(115, CLASS_BTN_SIZE.height / 2, {text = v.title, fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5e2e16', outlineSize = 2, reqW = 170})
        titleLabel:setName('title')
        btn:addChild(titleLabel, 1)
        -- 小红点
        local remindIcon = display.newImageView(RES_DICT.REMIND_ICON, CLASS_BTN_SIZE.width - 70, CLASS_BTN_SIZE.height / 2 + 10)
        remindIcon:setName('remindIcon')
        remindIcon:setVisible(false)
        btn:addChild(remindIcon)
        local particleSpine = sp.SkeletonAnimation:create(
            RES_DICT.ZH_LIZI.json,
            RES_DICT.ZH_LIZI.atlas,
            1)
        btn:addChild(particleSpine, 0.6)
        particleSpine:setAnimation(0, 'idle', true)
        particleSpine:update(0)
        particleSpine:setPosition(utils.getLocalCenter(btn))
        particleSpine:setToSetupPose()
        particleSpine:setVisible(false)
        particleSpine:setName('particleSpine')
        table.insert(self.classBtnList, btn)
    end
end
--[[
移除分类按钮
--]]
function ActivityTabView:RemoveClassBtn()
    for i, v in ipairs(self.classBtnList) do
        v:removeFromParent()
    end
end
--[[
刷新分类按钮
--]]
function ActivityTabView:RefreshClassBtn()
    for i, v in ipairs(self.classBtnList) do
        if i > self.location.class then
            -- 显示在底部
            v:setPositionY((self.classNum - i) * 60)
        else
            -- 显示在顶部
            v:setPositionY(COMBO_LIST_SIZE.height - i * 60)
        end
        -- 更改下拉角标状态
        local angle = v:getChildByName('angle')
        if i == self.location.class then
            angle:setRotation(0)
        else
            angle:setRotation(270)
        end
        -- 是否高亮
        local isHighlight = false
        for _, data in ipairs(self.activityClassDataList[i].activityData) do
            if data.highlight == 1 then
                isHighlight = true
                break
            end
        end
        local particleSpine = v:getChildByName('particleSpine')
        particleSpine:setVisible(isHighlight)
    end
    self:RefreshClassBtnRemindIcon()
end
--[[
刷新分类按钮红点
--]]
function ActivityTabView:RefreshClassBtnRemindIcon()
    for class, activityClassData in ipairs(self.activityClassDataList) do
        local showRemindIcon = false
        for index, value in ipairs(activityClassData.activityData) do
            if value.showRemindIcon == 1 or checkint(value.relatedRemindIcon) == 1 then
                showRemindIcon = true
                break
            end
        end
        if self.classBtnList[class] then
            self.classBtnList[class]:getChildByName('remindIcon'):setVisible(showRemindIcon)
        end
    end
end
--[[
初始化列表
--]]
function ActivityTabView:InitGridView()
    local gridViewSize = cc.size(GRIDVIEW_CELL_SIZE.width, COMBO_LIST_SIZE.height - self.classNum * 60)
    local gridViewBgSize = cc.size(246, COMBO_LIST_SIZE.height - self.classNum * 60 + 4)
    if self.gridViewMap then
        self.gridViewMap.gridViewBg:setContentSize(gridViewBgSize)
        self.gridViewMap.gridView:setContentSize(gridViewSize)
    else
        local gridViewBg = display.newImageView(RES_DICT.GRIDVIEW_BG, COMBO_LIST_SIZE.width / 2, 0, {ap = cc.p(0.5, 0), scale9 = true, capInsets = cc.rect(30, 30, 186, 404), size = gridViewBgSize})
        self:addChild(gridViewBg, 1)
        local gridView = CGridView:create(gridViewSize)
        gridView:setSizeOfCell(GRIDVIEW_CELL_SIZE)
        gridView:setColumns(1)
        gridView:setAnchorPoint(cc.p(0.5, 0))
        gridView:setPosition(cc.p(COMBO_LIST_SIZE.width / 2, 0))
        self:addChild(gridView, 2)
        gridView:setDataSourceAdapterScriptHandler(handler(self,self.ListDataSourceAction))
        self.gridViewMap = {
            gridViewBg = gridViewBg,
            gridView   = gridView,
        }
    end
end
--[[
 刷新列表
--]]
function ActivityTabView:RefreshGridView()
    local gridView = self.gridViewMap.gridView
    local gridViewBg = self.gridViewMap.gridViewBg
    gridViewBg:setPositionY((self.classNum - self.location.class) * 60 + 2)
    gridView:setPositionY((self.classNum - self.location.class) * 60 + 4)
    gridView:setCountOfCell(table.nums(checktable(self.activityClassDataList[self.location.class]).activityData or {}))
    gridView:reloadData()
end
--[[
gridView数据处理
--]]
function ActivityTabView:ListDataSourceAction( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = cellSize
    if pCell == nil then
        pCell = ActivityTabCell.new(GRIDVIEW_CELL_SIZE)
        pCell.bgBtn:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
    end
    xTry(function()
        local activityData = self.activityClassDataList[self.location.class].activityData[index]
        pCell.bgBtn:setTag(index)
		if index == self.location.index then
			pCell.bgBtn:setChecked(true)
		else
			pCell.bgBtn:setChecked(false)
        end
        --pCell.nameLabel:setString(activityData.title)
        display.commonLabelParams(pCell.nameLabel , {text =activityData.title  , w = 180 , reqH = 70 , hAlign = display.TAC })
        if checkint(activityData.showRemindIcon) == 1
        or checkint(activityData.relatedRemindIcon) == 1 then
			pCell.tipsIcon:setVisible(true)
		else
			pCell.tipsIcon:setVisible(false)
		end
		if checkint(activityData.isNew) == 1 then
			pCell.newIcon:setVisible(true)
		else
			pCell.newIcon:setVisible(false)
		end
    end,__G__TRACKBACK__)
    return pCell
end
--[[
分类按钮点击回调
--]]
function ActivityTabView:ClassButtonCallback( sender )
    if not self.isControllable_ then return end
    local tag = sender:getTag()
    if tag == self.location.class then return end
    PlayAudioByClickNormal()
    self.location.class = tag 
    self.location.index = 1
    self:RefreshView()
end
--[[
活动页签点击回调
--]]
function ActivityTabView:TabButtonCallback( sender )
    if not self.isControllable_ then return end
    local tag = sender:getTag()
    local gridView = self.gridViewMap.gridView
    if tag == self.location.index then 
        gridView:cellAtIndex(tag - 1).bgBtn:setChecked(true)
        return 
    end
    PlayAudioByClickNormal()
    if gridView:cellAtIndex(self.location.index - 1) then
        gridView:cellAtIndex(self.location.index - 1).bgBtn:setChecked(false)
    end
    gridView:cellAtIndex(tag - 1).bgBtn:setChecked(true)
    self.location.index = tag
    -- 发送点击信号
    self:SendClickSignal()
end
--[[
发送点击信号 
--]]
function ActivityTabView:SendClickSignal()
    AppFacade.GetInstance():DispatchObservers(ACTIVITY_TAB_CLICK, {activityId = self:GetActivityId(self.location)})
end
--[[
添加红点
@params activityId int 活动id
--]]
function ActivityTabView:AddRemindIcon( activityId )
    local activityData = self:GetActivityDataByActivityId(activityId) or {}
    activityData.showRemindIcon = 1
    local location = self:GetLocationByActivityId(activityId)
    if not location or location.class ~= self.location.class then return end
    if self.gridViewMap.gridView:cellAtIndex(location.index-1) then
        self.gridViewMap.gridView:cellAtIndex(location.index-1).tipsIcon:setVisible(true)
    end
    self:RefreshClassBtnRemindIcon()
end
--[[
清除红点
@params activityId int 活动id
--]]
function ActivityTabView:ClearRemindIcon( activityId )
    local activityData = self:GetActivityDataByActivityId(activityId) or {}
    if next(activityData) == nil then 
        local relatedActivityData = self:GetActivityDataByRelatedActivityId(activityId)
        if not relatedActivityData then return end
        relatedActivityData.relatedRemindIcon = 0
        if relatedActivityData.showRemindIcon == 0 then
            local location = self:GetLocationByActivityId(relatedActivityData.activityId)
            if not location or location.class ~= self.location.class then return end
            if self.gridViewMap.gridView:cellAtIndex(location.index-1) then
                self.gridViewMap.gridView:cellAtIndex(location.index-1).tipsIcon:setVisible(false)
            end
            self:RefreshClassBtnRemindIcon()
        else
            return 
        end
    end
    activityData.showRemindIcon = 0
    local location = self:GetLocationByActivityId(activityId)
    if not location or location.class ~= self.location.class then return end
    if self.gridViewMap.gridView:cellAtIndex(location.index-1) then
        self.gridViewMap.gridView:cellAtIndex(location.index-1).tipsIcon:setVisible(false)
    end
    self:RefreshClassBtnRemindIcon()
end
--[[
通过活动id获取activityData
@params activityId int 活动id
--]]
function ActivityTabView:GetActivityDataByActivityId( activityId )
    for class, activityClassData in ipairs(self.activityClassDataList) do
        for index, activityData in ipairs(activityClassData.activityData) do
            if checkint(activityData.activityId) == checkint(activityId) then
                return activityData
            end
        end
    end
end
--[[
通过关联活动id获取activityData
@params relatedActivityId int 活动id
--]]
function ActivityTabView:GetActivityDataByRelatedActivityId( relatedActivityId )
    for class, activityClassData in ipairs(self.activityClassDataList) do
        for index, activityData in ipairs(activityClassData.activityData) do
            if checkint(activityData.relatedActivityId) == checkint(relatedActivityId) then
                return activityData
            end
        end
    end
end
--[[
获取活动id
@params location map {
    class int 分类
    index int 序号
}
--]]
function ActivityTabView:GetActivityId( location )
    return checkint(checktable(checktable(checktable(self.activityClassDataList[location.class]).activityData)[location.index]).activityId)
end
--[[
通过活动id获取活动位置
@params activityId int 活动id
--]]
function ActivityTabView:GetLocationByActivityId( activityId )
    for class, activityClassData in ipairs(self.activityClassDataList) do
        for index, value in ipairs(activityClassData.activityData) do
            if checkint(value.activityId) == checkint(activityId) then
                return {class = class, index = index}
            end
        end
    end
end
--[[
设置控件是否可触摸
@params enabled bool 是否可触摸
--]]
function ActivityTabView:SetEnabled( enabled )
    self.isControllable_ = enabled
end
return ActivityTabView
  