local Parser = require( 'Game.Datas.Parser' )

local TaskConfigParser = class('TaskConfigParser', Parser)


TaskConfigParser.NAME = "TaskConfigParser"

function TaskConfigParser:ctor()
  self.super.ctor(self, {'dailyTask','task','taskClass','taskSmallClass','taskSort','achieveLevel'})
end

return TaskConfigParser
