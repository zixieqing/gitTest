---
--- Created by xingweihao.
--- DateTime: 27/12/2017 1:56 PM
---
---@class UnionBuildView
local UnionBuildView = class('home.UnionBuildView',function ()
    local pageviewcell = CLayout:create(display.size)
    pageviewcell.name = 'home.UnionBuildView'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)
local BUILD_IMAGE_TABLE = {
    ["1"] = { image =  _res('ui/union/guild_build_ico_1') , name = __('低阶建造') }  ,
    ["2"] = { image =  _res('ui/union/guild_build_ico_2') , name = __('中阶建造') }  ,
    ["3"] = { image =  _res('ui/union/guild_build_ico_3') , name = __('高阶建造') }
}

local BUTTON_TAG = {
    ONE = 1 ,
    TWO = 2 ,
    THREE = 3 ,
    CLOSE_TAG = 1101,
    BUILD_LOG = 1102
}
function UnionBuildView:ctor(...)
    local cellSize = cc.size(397, 564)
    local closeLayer =  display.newLayer(display.width/2 , display.height/2,
             {ap = display.CENTER , size = display.size ,  color = cc.c4b(0,0,0,178) ,enable = true  })
    closeLayer:setTag(BUTTON_TAG.CLOSE_TAG)
    self:addChild(closeLayer)
    local topImage = display.newImageView(_res('ui/raid/room/raid_room_bg_up.png') )
    local topSize = topImage:getContentSize()
    topSize = cc.size(topSize.width + 100 , topSize.height)
    topImage:setPosition(cc.p(topSize.width/2 , topSize.height/2))
    local topLayer =  display.newLayer(display.width/2 , display.height, { ap = display.CENTER_TOP , size = topSize})
    self:addChild(topLayer)
    topLayer:addChild(topImage)
    -- 贡献值
    local contributionValue = display.newButton(topSize.width/2 , topSize.height/2  + 5,{ n = _res('ui/raid/room/raid_room_btn_title.png')  })
    topLayer:addChild(contributionValue)
    local topSwallowLayer = display.newLayer(topSize.width/2 , topSize.height/2 ,
         { ap = display.CENTER , color = cc.c4b(0,0,0,0), enable = true  } )
    topLayer:addChild(topSwallowLayer)

    local recordBtn  = display.newButton(topSize.width , topSize.height/2, {ap = display.RIGHT_CENTER,  n =_res('ui/home/teamformation/choosehero/team_btn_selection_unused.png')})
    display.commonLabelParams(recordBtn, fontWithColor('14' , {text = __('建造日志')}))
    topLayer:addChild(recordBtn)
    recordBtn:setTag(BUTTON_TAG.BUILD_LOG)

    local count = 3
    local centerSize = cc.size(cellSize.width * count  ,cellSize.height )
    local centerLayer = display.newLayer(display.cx , display.cy , { ap = display.CENTER , size = centerSize})
    self:addChild(centerLayer)
    ---- 吞噬点击
    local swallowLayer = display.newLayer(centerSize.width/2  , centerSize.height/2 , { ap = display.CENTER , size = centerSize , color = cc.c4b(0,0,0,0) , enable = true })
    centerLayer:addChild(swallowLayer)
    local cellImageSize = cc.size(397, 484)
    local cellTable = {}
    for i=1 , count do

        local cellLayout = display.newLayer(cellSize.width * (i - 0.5 ) , cellSize.height/2, { ap = display.CENTER  , size = cellSize})
        centerLayer:addChild(cellLayout)

        local cellImageLayout = display.newLayer(cellSize.width/2 , cellSize.height , {ap = display.CENTER_TOP , size = cellImageSize})
        local bgImage = display.newImageView(_res("ui/union/guild_bulid_bg_choice") ,cellImageSize.width/2 , cellImageSize.height/2)
        cellImageLayout:addChild(bgImage)
        cellLayout:addChild(cellImageLayout)
        cellImageLayout:setName("cellImageLayout")
        local icomImage = display.newImageView(BUILD_IMAGE_TABLE[tostring(i)].image ,cellImageSize.width/2 , cellImageSize.height/2 + 50)
        cellImageLayout:addChild(icomImage)


        local buildName = display.newRichLabel(cellImageSize.width/2 -10 , cellImageSize.height - 65 ,
            { ap = display.CENTER , r = true ,c= { fontWithColor('14' , {fontSize = 22, color = "#e77a41" ,text = BUILD_IMAGE_TABLE[tostring(i)].name }) }})

        cellImageLayout:addChild(buildName)

        local lineImage  = display.newImageView(_res("ui/union/guild_build_ico_line"), cellImageSize.width/2  , cellImageSize.height - 83)
        bgImage:addChild(lineImage,2)
        cellTable[#cellTable+1] = cellLayout

        local titleImage = display.newButton(cellImageSize.width/2  , cellImageSize.height - 280 ,
             { ap =display.CENTER_TOP, n  = _res('ui/common/common_title_3') ,enable = false })
        display.commonLabelParams(titleImage , fontWithColor('6' , { text = __('奖励')}))
        cellImageLayout:addChild(titleImage)

        local buildBtn  = display.newButton(cellSize.width/4*1 , 60 , { n = _res('ui/common/common_btn_white_default' ) ,
              s = _res('ui/common/common_btn_orange' ) , size = cc.size(160, 60) , scale9 = true  })
        cellLayout:addChild(buildBtn)
        buildBtn:setTag(i)
        buildBtn:setName("buildBtn")

        local buildBtnSize  = buildBtn:getContentSize()
        -- 更新的buildRichLabel
        local  buildRichLabel = display.newRichLabel(buildBtnSize.width/2 ,-10  ,{ c={ ap = display.CENTER_TOP, fontWithColor('12', {text =""})}})
        buildBtn:addChild(buildRichLabel)
        buildRichLabel:setName("buildRichLabel")

        local buildBtnTimes = display.newButton( cellSize.width/4* 3 , 60 , { n = _res('ui/common/common_btn_orange') ,size = cc.size(160, 60) , scale9 = true})
        cellLayout:addChild(buildBtnTimes)
        buildBtnTimes:setName("buildBtnTimes")
        buildBtnTimes:setTag(3 + i )

        -- 更新的buildRichLabel
        local  buildRichLabel = display.newRichLabel(buildBtnSize.width/2 ,-10  ,{ c={ ap = display.CENTER_TOP, fontWithColor('12', {text =""})}})
        buildBtnTimes:addChild(buildRichLabel)
        buildRichLabel:setName("buildRichLabel")



        local buildTimes = display.newLabel(cellSize.width/2 , 0 ,  fontWithColor('10' ,{color = "#ffffff" ,fontSize = 24 ,ap = display.CENTER_BOTTOM , text = "好好学习" , ap = display.CENTER_TOP })  )
        cellLayout:addChild(buildTimes)
        buildTimes:setName("buildTimes")


    end
    self.viewData = {
        cellTable         = cellTable,
        closeLayer = closeLayer ,
        contributionValue = contributionValue,
        cellImageSize     = cellImageSize,
        recordBtn         = recordBtn
    }
end
return UnionBuildView
