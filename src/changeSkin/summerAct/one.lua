local podTable = {
    po = {},
    firstMapNodePostions = {
        {
            location = {x = 377, y = 352}
        },
        {
            location = {x = 1303, y = 482}
        },
        {
            location = {x = 323, y = 570}
        },
        {
            location = {x = 1107, y = 660}
        },
        {
            location = {x = 808, y = 592}
        },
    },
    firstMapLotteryNodePostions = cc.p(1105, 286),
    carnieThemeBasePath = nil,  -- 18夏活无视，则会使用默认值
    keepRepKey = nil,   -- 18夏活无视，则会使用默认值
    audioConf = {
        FIRST_MAP  = {sheetName = AUDIOS.YLY.name, cueName = AUDIOS.YLY.FOOD_YLY_STRANGE.id},
        SECOND_MAP = {sheetName = AUDIOS.YLY.name, cueName = AUDIOS.YLY.FOOD_YLY_MUSICBOX.id},
    },
    getSecondMapBgByChapterId = function(chapterId)
        return string.format('ui/home/activity/summerActivity/map/bg/activity_summer_maps_100%s.jpg', chapterId or 1)
    end,
    getUnopenImg = function(chapterId)
        return string.format('ui/home/activity/summerActivity/map/icon/aaaactivity_maps_icon_%s.png', chapterId or 1)
    end,
    hideStoryPos = cc.p(0,0),
}
return podTable