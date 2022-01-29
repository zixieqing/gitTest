---
--- Created by xingweihao.
--- DateTime: 26/09/2017 2:57 PM
---
--[[
新鲜度恢复界面的修改
--]]
---@class WorldClockView
local WorldClockView = class('WorldClockView', function()
    local node = CLayout:create(display.size)
    node.name = 'common.WorldClockView'
    node:enableNodeEvents()
    return node
end)
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local BTN_TAG = {
    CHANGE_TEAM = 1101 ,
    MOUDLE_GOTO = 1102 ,
    PRE_TEAM_BTN = 1103 ,  --向前切换队伍的按钮
    NEXT_TEAM_BTM = 1104 , -- 向后切换编队
    TIPS_BTN = 1105 , -- 弹出tips 的提示
}
function WorldClockView:ctor( ... )
    local bgSize =  cc.size(563, 315)
    local bgLayout = display.newLayer(display.cx , display.cy ,{ap = display.CENTER , size = bgSize  })
    self:addChild(bgLayout , 2)
    local bgSwallowLayer =  display.newLayer(bgSize.width /2 , bgSize.height /2 , {ap = display.CENTER ,  size = bgSize , color = cc.c4b(0,0,0,0) , enable = true})
    bgLayout:addChild(bgSwallowLayer)

    local bgImage =  display.newImageView(_res('ui/home/worldtime/time.png') , bgSize.width/2 , bgSize.height/2)
    bgLayout:addChild(bgImage)

    local titleImage = display.newButton(bgSize.width /2 , bgSize.height - 10  ,{ap = display.CENTER_TOP , scale9 = true , n = _res('ui/common/common_title_3.png')  })
    display.commonLabelParams(titleImage , fontWithColor('14', {text = __('世界时钟') , color = "#5b3c25" , outline = false , paddingW = 30 }))
    bgLayout:addChild(titleImage)

    local serverImage  = display.newImageView(_res('ui/home/worldtime/time_title.png') ,
        0 ,bgSize.height - 55 , {ap = display.LEFT_TOP} )
    bgLayout:addChild(serverImage)
    local serverSize = serverImage:getContentSize()
    local serverLabel = display.newLabel(25 , serverSize.height /2 , fontWithColor('10',{ap  = display.LEFT_CENTER , fontSize = 22 , color = '#ffffff' , text = "" }))
    serverImage:addChild(serverLabel)
    self.serverLabel = serverLabel
    local localTime = display.newLabel(360, bgSize.height - 90 , fontWithColor('10',{ color = '#5b3c25', fontSize  = 20 , ap = display.CENTER_BOTTOM ,  w = 90 , text = __('本地时间') ,hAlign = display.TAC}))
    bgLayout:addChild(localTime)

    local serverTime = display.newLabel(bgSize.width - 70 , bgSize.height - 90 ,{color = '#5b3c25', fontSize  = 20 , ap = display.CENTER_BOTTOM , text = __('服务器时间') , w = 100 , hAlign = display.TAC})
    bgLayout:addChild(serverTime)
    local listSize = cc.size(548 , 210)
    -- 滑动列表的layout
    local listLayout = display.newLayer(bgSize.width /2 -1, 7 , {ap = display.CENTER_BOTTOM  , size = listSize  })
    bgLayout:addChild(listLayout)

    local listBg = display.newImageView(_res('ui/common/common_bg_list') , listSize.width /2 , listSize.height/2 , {ap = display.CENTER , scale9 = true , size = listSize })
    listLayout:addChild(listBg)

    local listView = CListView:create(cc.size(listSize.width , listSize.height -20) )
    listView:setDirection(eScrollViewDirectionVertical)

    listView:setAnchorPoint(display.CENTER)
    listView:setPosition(listSize.width/2 , listSize.height/2)
    listLayout:addChild(listView, 10)

    local index = 0
    local cellSize = cc.size(listSize.width , 45 )

    local worldData = {}
    for i, v in pairs(PUSH_LOCAL_TIME_NOTICE.LOVE_FOOD_RECOVER_TYPE) do
        worldData[#worldData+1] = v
    end
    table.sort(worldData , function(a,b)
        if  a.startTime <   b.startTime then
            return true
        end
        return false
    end)
    local publishData = {}
    for i, v in pairs(PUSH_LOCAL_TIME_NOTICE.PUBLISH_ORDER_RECOVER_TYPE) do
        publishData[#publishData+1] = v
    end
    table.sort(publishData , function(a,b)
        if  a.time <   b.time then
            return true
        end
        return false
    end)
    for i, v in pairs(publishData) do
        worldData[#worldData+1] = v
    end
    local data = {}
    local wordBossList = gameMgr:GetUserInfo().worldBossMapData_ or {}
    for i, v in pairs(wordBossList ) do
        local utcDate = os.date("!*t" , v.startTime)
        local startTime = l10nHours(utcDate.hour , utcDate.min):fmt('%H')
        data.time = checkint(startTime)
        data.originalTime = string.format("%02d:%02d",utcDate.hour , utcDate.min)
        data.title =  __('灾祸')
        worldData[#worldData+1] = data
        break
    end
    for i, v in pairs(worldData) do
        index = index + 1
        local cell = display.newLayer(0 ,0, {size = cellSize  , color = cc.c4b(0,0,0,0)})
        local cellName = display.newLabel(30, cellSize.height/2 , fontWithColor('16', {text = v.title  , ap = display.LEFT_CENTER}))
        cell:addChild(cellName,2)
        local startTimeData = string.split(v.time, ':')
        local localTime = display.newLabel(330, cellSize.height/2 , fontWithColor('16', {ap = display.LEFT_CENTER , text = string.format("%02d:%02d" , checkint(startTimeData[1]) , checkint(startTimeData[2]))   , color = '#9f4210'}))
        cell:addChild(localTime,2)
        startTimeData = string.split(v.originalTime, ':')
        local severTime = display.newLabel(cellSize.width - 90 , cellSize.height/2 , fontWithColor('16', {ap = display.LEFT_CENTER , text = string.format("%02d:%02d" , checkint(startTimeData[1]) , checkint(startTimeData[2]))    , color = '#9f4210'}))
        cell:addChild(severTime,2)
        if index % 2 == 1 then
            local  bgSigImage = display.newImageView(_res('ui/common/common_bg_input_default.png') ,cellSize.width/2 , cellSize.height/2 ,{scale9 = true , size = cc.size(listSize.width  - 10, 44)  } )
            cell:addChild(bgSigImage)
        end
        listView:insertNodeAtLast(cell)
    end
    listView:reloadData()
    local closeLayer = display.newLayer(display.cx , display.cy , {ap  = display.CENTER , size = display.size , color = cc.c4b(0,0,0,175   ) , enable = true })
    self:addChild(closeLayer)
    self.isClose = false
    closeLayer:setOnClickScriptHandler(function(sender)
        if  not self.isClose  then
            self.isClose = true
            --self:stopAllActions()
            self:runAction(cc.RemoveSelf:create())
        end
    end)

end
function WorldClockView:UpdateUTCTime()
    local severTime = getServerTime()
    local timeTable = os.date("!*t",severTime )
    display.commonLabelParams(self.serverLabel , {text = string.format('%02d:%02d:%02d',checkint(timeTable.hour)  , checkint(timeTable.min),checkint(timeTable.sec) )})
end
return WorldClockView