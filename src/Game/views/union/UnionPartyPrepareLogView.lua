---
--- Created by xingweihao.
--- DateTime: 21/09/2017 10:37 AM
---
--[[
背包系统UI
--]]
---@class UnionPartyPrepareLogView
local GameScene = require( "Frame.GameScene" )
-- 修改玩家的头像和头像框的类
local UnionPartyPrepareLogView = class('UnionPartyPrepareLogView', GameScene)

function UnionPartyPrepareLogView:ctor(param)
    --创建页面
    param = param or  {}
    self.datas = self:DealWithData(param)
    self.count = #self.datas

    local labelparser = require('Game.labelparser')
	-- local parsedtable = labelparser.parse(__('<yellow>playerName</yellow><div>筹备了</div><blue>num</blue>份<yellow>foodName</yellow>'))
    -- local result = {}
    -- for name, val in ipairs(parsedtable) do
    --     local labelname = val.labelname
    --     if labelname == 'yellow' then
    --         table.insert(result, fontWithColor('8', { fontSize = 22 , color = "#f25a17" , text = val.content, descr = val.labelname}))
    --     elseif labelname == 'blue' then
    --         table.insert(result, fontWithColor('8', { fontSize = 22 , color = "#2584f0" , text = val.content, descr = val.labelname}))
    --     else
    --         table.insert(result, fontWithColor('6', { fontSize = 22 , text = val.content, descr = val.labelname}))
    --     end
    -- end
    
    local result = {}
    local t = string.split(__('playerName_筹备了_num_份_foodName'), '_')
    for index, value in ipairs(t) do
        table.insert(result, {text = value, descr = value})
    end
    self.result = result

    ---@type TitlePanelBg
    local view = require("common.TitlePanelBg").new({ title = __('筹备日志') , type = 2 , offsetY = 3 ,offsetX = 0})
    display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    self:addChild(view)
    view.viewData.eaterLayer:setOnClickScriptHandler(
            function()
                PlayAudioByClickClose()
                self:runAction(cc.RemoveSelf:create())
            end
    )
    local function CreateTaskView( ... )
        local bgSize = view.viewData.view:getContentSize()
        -- 吞噬层
        local swallowLayer = display.newLayer(bgSize.width/2 , bgSize.height/2 , {ap = display.CENTER ,  size = bgSize , color = cc.c4b( 0, 0,0,0)})
        view.viewData.view:addChild(swallowLayer,9)
        view.viewData.closeBtn:setVisible(false)
        local size = cc.size(700, 586)
        local cview =  display.newLayer(bgSize.width/2  , 0 , { ap = display.CENTER_BOTTOM , size = size  })
        view.viewData.view:addChild(cview,9)


        local topSize = cc.size(687, 600)
        local gridView
        local taskListCellSize
        local topLayout = display.newLayer(size.width/2 , size.height , { ap = display.CENTER_TOP, size = topSize  })
        local taskListSize = cc.size(700 ,560 )
        cview:addChild(topLayout)
        if self.count == 0 then
            local tip = self:CreateNoBuildLog()
            topLayout:addChild(tip)
        else
            taskListCellSize = cc.size(700 , 75)
            gridView = CGridView:create(taskListSize)
            gridView:setSizeOfCell(taskListCellSize)
            gridView:setColumns(1)
            gridView:setAutoRelocate(true)
            topLayout:addChild(gridView)
            gridView:setAnchorPoint(cc.p(0.5, 1.0))
            gridView:setPosition(cc.p(topSize.width/2 ,topSize.height))
            gridView:setCountOfCell(self.count)
            gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
            gridView:reloadData()
        end
        return {
            bgView 			= cview,
            gridView 		= gridView,
            topLayout = topLayout

        }
    end
    xTry(function()
        self.viewData_ = CreateTaskView()
    end, __G__TRACKBACK__)
end

function UnionPartyPrepareLogView:CreateCell()
    local gridSize = cc.size(700, 75)
    local gridCell = CGridViewCell:new()
    gridCell:setContentSize(gridSize)

    local bgLayout = display.newLayer(gridSize.width/2 ,gridSize.height/2 , {
        ap = display.CENTER , size = gridSize
    })
    gridCell:addChild(bgLayout)

    local bgImage = display.newImageView(_res('ui/union/guild_establish_information_title') ,gridSize.width/2 ,gridSize.height/2 ,{size = cc.size(677 , 70) , scale9 = true } )
    bgLayout:addChild(bgImage)
    local richLabel = display.newRichLabel(20 , gridSize.height/2 , { w = 44 ,  ap = display.LEFT_CENTER , c = {
        fontWithColor('14' ,{text ="1212"})
    }})
    bgLayout:addChild(richLabel)
    local timeLabel = display.newLabel(gridSize.width - 20 , gridSize.height /2 , fontWithColor('8',{ ap = display.RIGHT_CENTER,text ="121212"}))
    bgLayout:addChild(timeLabel)
    gridCell.timeLabel = timeLabel
    gridCell.bgImage = bgImage
    gridCell.richLabel = richLabel
    return gridCell
end
--[[
    没有日志的时候 显示日志
--]]
function UnionPartyPrepareLogView:CreateNoBuildLog()
    local size = cc.size(1046,590)
    local kongBg = CLayout:create(cc.size(900,590))
    local dialogue_tips = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/common_bg_dialogue_tips.png')})
    display.commonUIParams(dialogue_tips, {ap = cc.p(0,0.5),po = cc.p(50,size.height * 0.5)})
    display.commonLabelParams(dialogue_tips,{text = __('暂无筹备日志'), fontSize = 24, color = '#4c4c4c'})
    kongBg:addChild(dialogue_tips, 6)
    -- 中间小人
    local loadingCardQ = AssetsUtils.GetCartoonNode(3, dialogue_tips:getContentSize().width + 230, size.height * 0.5)
    kongBg:addChild(loadingCardQ, 6)
    kongBg:setScale(0.8)
    kongBg:setVisible(true )
    kongBg:setPosition(cc.p(size.width/2 -200 , size.height/2))
    return kongBg
end
--[[
    处理数据
--]]
function UnionPartyPrepareLogView:DealWithData(data)
    data = data or {}
    local logList = {}
    local selfPlayerId = checkint(app.gameMgr:GetUserInfo().playerId)
    for k ,v in ipairs(data) do
        local playerId = checkint(v.playerId)
        table.insert(logList, v)

        local goodConf = CommonUtils.GetConfig('goods', 'goods', v.foodId) or {}
        logList[k].foodName = tostring(goodConf.name)

        if checkint(v.playerId) == selfPlayerId then
            logList[k].playerName = __('你')
            logList[k].isMe = true
        end
    end
    return logList
end
--[[
    刷新的事件
--]]
function UnionPartyPrepareLogView:OnDataSource(cell , idx )
    local pcell = cell
    local index = idx +1
    local data = self.datas[index]
    if index >= 1 and index <= self.count then
        if not  pcell then
            pcell = self:CreateCell()
        end
        local richData = {}
        local count = 0
        for index, value in ipairs(self.result) do
            local descr = value.descr
            if descr == 'playerName'  then
                table.insert(richData, fontWithColor('8', { fontSize = 22 , color = "#f25a17" , text = data.playerName}))
            elseif descr == 'foodName' then
                table.insert(richData, fontWithColor('8', { fontSize = 22 , color = "#f25a17" , text = data.foodName}))
            elseif descr == 'num'  then
                table.insert(richData, fontWithColor('8', { fontSize = 22 , color = "#2584f0" , text = data.foodNum}))
            else
                table.insert(richData, fontWithColor('6', { fontSize = 22 , text = value.text}))
            end
        end

        display.reloadRichLabel(pcell.richLabel , {c =  richData })

        local timeData =  string.formattedTime(os.time() -  data.createTime)
        local str = ""
        if checkint(timeData.h) > 0 then
            local day  = math.floor(timeData.h/24)
            local hours = timeData.h%24
            if day > 0 then
                str = string.format(__('%s天') ,day )
            end
            if hours > 0 then
                str = string.format(__('%s%s小时') ,str,hours )
            end
        elseif checkint(timeData.m) > 0  then
            str = string.format(__('%s分钟') ,timeData.m )
        elseif checkint(timeData.s) > 0  then
            str = string.format(__('%s秒') ,timeData. s)
        end
        display.commonLabelParams(pcell.timeLabel ,  fontWithColor('8' ,{ text = str}))

    end
    return pcell
end

return UnionPartyPrepareLogView
