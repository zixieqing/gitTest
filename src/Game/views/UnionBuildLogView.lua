---
--- Created by xingweihao.
--- DateTime: 21/09/2017 10:37 AM
---
--[[
背包系统UI
--]]
---@class UnionBuildLogView
local GameScene = require( "Frame.GameScene" )
-- 修改玩家的头像和头像框的类
local UnionBuildLogView = class('UnionBuildLogView', GameScene)
local jobConfig = CommonUtils.GetConfigAllMess('job','union')
local builConfig = CommonUtils.GetConfigAllMess('build','union')
function UnionBuildLogView:ctor(param)
    --创建页面
    param =param or  {}
    self.datas = self:DealWithData(param)
    self.count = table.nums(self.datas)
    ---@type TitlePanelBg
    local view = require("common.TitlePanelBg").new({ title = __('建造日志') , type = 2 , offsetY = 3 ,offsetX = 0})
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
            taskListCellSize = cc.size(700 , 120)
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

function UnionBuildLogView:CreateCell()
    local gridSize = cc.size(700, 120)
    local gridCell = CGridViewCell:new()
    gridCell:setContentSize(gridSize)

    local bgLayout = display.newLayer(gridSize.width/2 ,gridSize.height/2 , {
        ap = display.CENTER , size = gridSize
    })
    gridCell:addChild(bgLayout)

    local bgImage = display.newImageView(_res('ui/union/guild_establish_information_title') ,gridSize.width/2 ,gridSize.height/2 ,{ size = cc.size(677 , 115) , scale9 = true } )
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
function UnionBuildLogView:CreateNoBuildLog()
    local size = cc.size(1046,590)
    local kongBg = CLayout:create(cc.size(900,590))
    local dialogue_tips = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/common_bg_dialogue_tips.png')})
    display.commonUIParams(dialogue_tips, {ap = cc.p(0,0.5),po = cc.p(50,size.height * 0.5)})
    display.commonLabelParams(dialogue_tips,{text = __('暂无捐献日志'), fontSize = 24, color = '#4c4c4c'})
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
function UnionBuildLogView:DealWithData(data)
    data = data or {}
    local buildLogList = {}
    local memberListKey = {}
    ---@type UnionManager
    local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")
    ---@type GameManager
    local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
    local memberList =  unionMgr:getUnionData().member
    for k ,v in pairs(memberList) do
        memberListKey[tostring(v.playerId)] = { playerName = v.playerName , job = v.job}
    end
    for k ,v in pairs(data) do
        if memberListKey[tostring(v.playerId)] then
            table.merge(v ,  memberListKey[tostring(v.playerId)])
            buildLogList[#buildLogList+1] = v
            if checkint(v.playerId) == checkint(gameMgr:GetUserInfo().playerId ) then
                buildLogList[#buildLogList].isMe = true
            end
        end
    end
    return buildLogList
end
--[[
    刷新的事件
--]]
function UnionBuildLogView:OnDataSource(cell , idx )
    local pcell = cell
    local index = idx +1
    local data = self.datas[index]
    if index >= 1 and index <= self.count then
        if not  pcell then
            pcell = self:CreateCell()
        end
        if checkint(data.buildTimes) == 0 then data.buildTimes = 1 end
        local richData = {}
        local buildOneData = builConfig[tostring(data.buildId)]
        local count = 0
        if data.isMe then
            richData[#richData+1] = fontWithColor('8', { fontSize = 22 , color = "#f25a17" , text =__('你')})
        else
            richData[#richData+1] = fontWithColor('6', { fontSize = 22  , text = jobConfig[tostring(data.job)].name })
            richData[#richData+1] = fontWithColor('8', { fontSize = 22 , color = "#2584f0" , text = data.playerName })
        end
        if checkint(buildOneData.buildGoodsId) > 0 then
            local name  = CommonUtils.GetConfig('goods','goods',buildOneData.buildGoodsId).name
            richData[#richData+1] = fontWithColor('6', { fontSize = 22 , text =__('消耗')})
            richData[#richData+1] = fontWithColor('14', { fontSize = 22 , color= "#2584f0", text =string.format("%s",buildOneData.buildGoodsNum * checkint(data.buildTimes )) })
            --count = #richData
            richData[#richData+1] = fontWithColor('6', { fontSize = 22 , text = name .. "，\n"})
        else
            richData[#richData+1] = fontWithColor('6', {text  = __('免费捐献，\n')})
        end
        richData[#richData+1] = fontWithColor('6', { fontSize = 22 , text =string.format(__('为工会增加%s贡献值') , tostring(buildOneData.contributionPoint *checkint(data.buildTimes))  )  })
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

return UnionBuildLogView
