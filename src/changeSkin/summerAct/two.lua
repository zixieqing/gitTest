
local podTable = {
    po = {
        [__("Tips：每次击退了本章节的小丑后，章节内的关卡点都会刷新重置。")]                    = __("Tips：每次击退了本章节的年兽后，章节内的关卡点都会刷新重置。"),
        [__("游乐园很有趣的哦！\n别担心，我会一直在你身边保护你，所以一起来玩吧！")]                 = __("御侍，你可替我看好了葱花，别让它乱跑。\n嗯，我希望你能和大家一起开开心心地迎接新的一年！"),
        [__("每个章节小丑伤害排行榜前%s名可获得：")]                                 = __("每个章节年兽伤害排行榜前%s名可获得："),
        [__("扭蛋机")]                                                 = __("压岁金猪"),
        [__("在游乐园中战斗可获得的点数。击退小丑时，根据造成的伤害可以获得更多的点数哦。")]              = __("在庙会中战斗可获得的点数。击退年兽时，根据造成的伤害可以获得更多的点数哦。"),
        [__("恐怖游乐园")]                                               = __("迎新庙会"),
        [__("马戏团")]                                                 = __("船港"),
        [__("拥有引路灯: %s")]                                           = __("拥有新年鞭炮: %s "),
        [__("乐园排行榜")]                                               = __("庙会排行榜"),
        [__("小丑伤害排行")]                                              = __("年兽伤害排行"),
        [__("本关卡无三星过关条件")]                                          = __("本关卡无三星过关条件"),
        [__("普通扭蛋")]                                                = __("普通奖励"),
        [__("游乐园点数")]                                               = __("迎新点数"),
        [__("累计扭蛋奖励")]                                              = __("累计兑换奖励"),
        [__("扭10次")]                                                = __("兑换10次"),
        [__("扭1次")]                                                 = __("兑换1次"),
        [__("您还没有参与游乐园的活动哦~")]                                      = __("您还没有参与迎新庙会的活动哦~"),
        [__("今日蛋池")]                                                = __("今日奖励"),
        [__("扭蛋上新")]                                                = __("奖励上新"),
        [__("排行榜每小时更新一次排名")]                                        = __("排行榜每小时更新一次排名"),
        [__("特典扭蛋预告")]                                              = __("特典奖励预告"),
        [__("消耗1个引路灯直接找到小丑")]                                       = __("消耗1个新年鞭炮直接找到年兽"),
        [__("剩余扭蛋")]                                                = __("剩余奖励"),
        [__("进入游乐园")]                                               = __("进入庙会"),
        [__("今日特典扭蛋")]                                              = __("今日特典奖励"),
        [__("乐园游玩奖励")]                                              = __("庙会迎新奖励"),
        [__("累计完成小丑关卡奖励")]                                          = __("累计完成年兽关卡奖励"),
        [__('完成小丑关卡%s次可获得')]                                        = __('完成年兽关卡%s次可获得'),
        [__("完成本关卡，根据所造成的伤害折算成游乐园点数，每1000点伤害为1点游乐园点数，不满1000不会计入。")] = __("完成本关卡，根据所造成的伤害折算成迎新点数，每1000点伤害为1点迎新点数，不满1000不会计入。"),
        [__("完成本关卡，可获得500点游乐园点数。")]                                 = __("完成本关卡，可获得500点迎新点数。"),
        [__("剩余扭蛋不足")]                                              = __("剩余奖励不足"),
        [__("堕神诱饵")]                                                = __("堕神诱饵"),
        [__("引出小丑")]                                                = __("引出年兽"),
        [__("小丑出现了!")]                                              = __("年兽出现了!"),
        [__('镜子迷宫第1名')]                                             = __("临门春前10名"),
        [__('旋转茶杯第1名')]                                             = __("舞狮曲前10名"),
        [__('矿道飞车第1名')]                                             = __("海神祭前10名"),
        [__('鬼屋第1名')]                                               = __("花灯会前10名"),
        [__('马戏团第1名')]                                              = __("景安码头前10名"),
        [__('在镜子迷宫内对小丑的单次伤害最高的玩家可以获得。')]                            = __("在临门春内对年兽的单次伤害排名前十的玩家可以获得。"),
        [__('在旋转茶杯内对小丑的单次伤害最高的玩家可以获得。')]                            = __("在舞狮曲内对年兽的单次伤害排名前十的玩家可以获得。"),
        [__('在矿道飞车内对小丑的单次伤害最高的玩家可以获得。')]                            = __("在海神祭内对年兽的单次伤害排名前十的玩家可以获得。"),
        [__('在鬼屋内对小丑的单次伤害最高的玩家可以获得。')]                              = __("在花灯会内对年兽的单次伤害排名前十的玩家可以获得。"),
        [__('在马戏团内对小丑的单次伤害最高的玩家可以获得。')]                             = __("在景安码头内对年兽的单次伤害排名前十的玩家可以获得。"),
    },
    firstMapNodePostions = {
        {
            location = {x = 1225, y = 620}
        },
        {
            location = {x = 900, y = 480}
        },
        {
            location = {x = 465, y = 324}
        },
        {
            location = {x = 430, y = 570}
        },
        {
            location = {x = 800, y = 740}
        },
    },
    firstMapLotteryNodePostions = cc.p(1160, 370),
    carnieThemeBasePath = 'carnieTheme/springAct_19',
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
        SPINE_SKELETON_PATH                  = true,
        SUMMER_ACTIVITY_DAN_PATH             = true,
    },
    audioConf = {
        FIRST_MAP  = {sheetName = AUDIOS.WYS.name, cueName = AUDIOS.WYS.FOOD_WYS_GUILINGGAO_HAPPY.id},
        SECOND_MAP = {sheetName = AUDIOS.XNH.name, cueName = AUDIOS.XNH.FOOD_XNH_JIEDAO.id},
    },
    getSecondMapBgByChapterId = function(chapterId)
        return string.format("ui/home/activity/carnieTheme/springAct_19/map/bg/activity_summer_maps_100%s.jpg", chapterId or 1)
    end,
    getUnopenImg = function(chapterId)
        return string.format("ui/home/activity/carnieTheme/springAct_19/map/icon/summer_activity_maps_icon_%s.jpg", chapterId or 1)
    end,
    hideStoryPos = cc.p(0,0),
}
return podTable