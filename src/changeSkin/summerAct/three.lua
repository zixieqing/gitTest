local podTable = {
    po = {
        [__("Tips：每次击退了本章节的小丑后，章节内的关卡点都会刷新重置。")]             = __('每次击退了本章节的木灵后，章节内的关卡点都会刷新重置。'),
        [__("游乐园很有趣的哦！\n别担心，我会一直在你身边保护你，所以一起来玩吧！")]       = __('花神祭可是花木村这里的传统哦，快来看看吧！'),
        [__("每个章节小丑伤害排行榜前%s名可获得：")]                                  = __('每个章节木灵伤害排行榜前%s名可获得：'),
        [__("扭蛋机")]                                                           = __('炼丹炉'),
        [__("在游乐园中战斗可获得的点数。击退小丑时，根据造成的伤害可以获得更多的点数哦。")] = __('在花神祭中进行战斗可获得的点数。击退木灵时，根据造成的伤害可以获得更多的点数哦。'),
        [__("恐怖游乐园")]                                                        = __('花盈春归'),
        [__("马戏团")]                                                           = __('残破祭祀坛'),
        [__("拥有引路灯: %s")]                                                    = __('拥有花神灯: %s'),
        [__("乐园排行榜")]                                                        = __('花神祭排行榜'),
        [__("小丑伤害排行")]                                                      = __('木灵伤害排行'),
        [__("本关卡无三星过关条件")]                                               = __('本关卡无三星过关条件'),
        [__("普通扭蛋")]                                                         = __('日常炼丹'),
        [__("游乐园点数")]                                                       = __('花神祭点数'),
        [__("累计扭蛋奖励")]                                                      = __('累计炼丹次数奖励'),
        [__("扭10次")]                                                          = __('炼10次'),
        [__("扭1次")]                                                           = __('炼1次'),
        [__("您还没有参与游乐园的活动哦~")]                                         = __('您还没有参与花神祭的活动哦'),
        [__("今日蛋池")]                                                         = __('今日炼丹炉'),
        [__("扭蛋上新")]                                                         = __('丹炉上新'),
        [__("排行榜每小时更新一次排名")]                                           = __('排行榜每小时更新一次排名'),
        [__("特典扭蛋预告")]                                                     = __('特典预告'),
        [__("消耗1个引路灯直接找到小丑")]                                          = __('消耗1个花神灯直接找到木灵'),
        [__("剩余扭蛋")]                                                        = __('剩余炼丹次数'),
        [__("进入游乐园")]                                                       = __('进入花神祭'),
        [__("今日特典扭蛋")]                                                     = __('今日特典'),
        [__("乐园游玩奖励")]                                                     = __('花神祭游玩奖励'),
        [__("累计完成小丑关卡奖励")]                                              = __('累计完成木灵关卡奖励'),
        [__('完成小丑关卡%s次可获得')]                                            = __('完成木灵关卡%s次可获得'),
        [__("完成本关卡，根据所造成的伤害折算成游乐园点数，每1000点伤害为1点游乐园点数，不满1000不会计入。")] = __('完成本关卡，根据所造成的伤害折算成花神祭点数，每1000点伤害为1点花神祭点数，不满1000不会计入。'),
        [__("完成本关卡，可获得500点游乐园点数。")]                                 = __('完成本关卡，可获得500点花神祭点数。'),
        [__("剩余扭蛋不足")]                                                     = __('剩余炼丹次数不足'),
        [__("堕神诱饵")]                                                        = __('堕神诱饵'),
        [__("引出小丑")]                                                        = __('引出木灵'),
        [__("小丑出现了!")]                                                     = __('木灵出现了'),
        [__('镜子迷宫第1名')]                                                   = __('草药堂前10名'),
        [__('旋转茶杯第1名')]                                                   = __('民宿前10名'),
        [__('矿道飞车第1名')]                                                   = __('花朝节前10名'),
        [__('鬼屋第1名')]                                                      = __('祭祀坛前10名'),
        [__('马戏团第1名')]                                                     = __('残破祭祀坛前10名'),
        [__('在镜子迷宫内对小丑的单次伤害最高的玩家可以获得。')]                      = __('在草药堂内对木灵的单次伤害最高的玩家可以获得。'),
        [__('在旋转茶杯内对小丑的单次伤害最高的玩家可以获得。')]                      = __('在民宿内对木灵的单次伤害最高的玩家可以获得。'),
        [__('在矿道飞车内对小丑的单次伤害最高的玩家可以获得。')]                      = __('在花朝节内对木灵的单次伤害最高的玩家可以获得。'),
        [__('在鬼屋内对小丑的单次伤害最高的玩家可以获得。')]                         = __('在祭祀坛内对木灵的单次伤害最高的玩家可以获得。'),
        [__('在马戏团内对小丑的单次伤害最高的玩家可以获得。')]                       = __('在残破祭祀坛内对木灵的单次伤害最高的玩家可以获得。'),
        [__('第1名的额外奖励: ')]                                               = __('前10名的额外奖励: '),
    },
    firstMapNodePostions = {
        {
            location = {x = 1227, y = 562}
        },
        {
            location = {x = 913, y = 430}
        },
        {
            location = {x = 650, y = 622}
        },
        {
            location = {x = 387, y = 488}
        },
        {
            location = {x = 612, y = 312}
        },
    },
    firstMapLotteryNodePostions = cc.p(1168, 310),
    carnieThemeBasePath = 'carnieTheme/springAct_20',
    keepRepKey = {
        SUMMER_ACTIVITY_EGG_BG_BELOW         = true,
        SUMMER_ACTIVITY_EGG_BG_DRAW          = true,
        SUMMER_ACTIVITY_EGG_BG_EXTRA         = true,
        SUMMER_ACTIVITY_EGG_BG_NUM           = true,
        SUMMER_ACTIVITY_EGG_BG               = true,
        SUMMER_ACTIVITY_EGG_BTN_LIMITED      = true,
        SUMMER_ACTIVITY_EGG_BTN_ONE          = true,
        SUMMER_ACTIVITY_EGG_BTN_REWARDS      = true,
        SUMMER_ACTIVITY_EGG_BTN_TEN          = true,
        SUMMER_ACTIVITY_EGG_LABEL_DRAW       = true,
        SUMMER_ACTIVITY_EGG_LABEL_EXTRA      = true,
        SUMMER_ACTIVITY_EGG_LABEL_LIMITED    = true,
        SUMMER_ACTIVITY_EGGREWARDS_BG_CARD   = true,
        SPINE_ACTIVITY_NIUDANJI_PATH         = true,
        SUMMER_ACTIVITY_MAPS_ONE             = true,
        SUMMER_ACTIVITY_ICON_LAMP            = true,
        SPINE_ACTIVITY_DENGLONG_PATH         = true,
        SUMMER_ACTIVITY_ICO_POINT            = true,
        SPINE_ACTIVITY_JIQI_PATH             = true,
        SPINE_YLY_PATH                       = true,
        SPINE_ACTIVITY_YLY_PATH              = true,
        SUMMER_ACTIVITY_RANK_BG_QBOSS        = true,
        SUMMER_ACTIVITY_ENTRANCE_BG          = true,
        SUMMER_ACTIVITY_ENTRANCE_BTN_ENTER   = true,
        SUMMER_ACTIVITY_ENTRANCE_LABEL_TITLE = true,
        SUMMER_ACTIVITY_ENTRANCE_LIGHT       = true,
        SUMMER_ACTIVITY_RANK_BG_BOSS         = true,
        SUMMER_ACTIVITY_RANK_BG_CARD         = true,
        SUMMER_ACTIVITY_RANK_BG_CARD_2       = true,
        SPINE_WUYA_PATH                      = true,
        SUMMER_ACTIVITY_DAN_PATH             = true,
        SUMMER_ACTIVITY_QBAN                 = true,
        SPINE_SKELETON_PATH                  = true,
    },
    audioConf = {
        FIRST_MAP  = {sheetName = AUDIOS.WYS.name, cueName = AUDIOS.WYS.FOOD_WYS_GUILINGGAO_HAPPY.id},
        SECOND_MAP = {sheetName = AUDIOS.XNH.name, cueName = AUDIOS.XNH.FOOD_XNH_JIEDAO.id},
    },
    getSecondMapBgByChapterId = function(chapterId)
        return string.format("ui/home/activity/carnieTheme/springAct_20/map/bg/activity_summer_maps_100%s.jpg", chapterId or 1)
    end,
    getUnopenImg = function(chapterId)
        return string.format("ui/home/activity/carnieTheme/springAct_20/map/icon/summer_activity_maps_icon_%s.jpg", chapterId or 1)
    end,
    hideStoryPos = cc.p(954, 655),
}
return podTable