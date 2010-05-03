local json = require("json")
local system = system
local io = io
local os = os
local json = json
local pcall = pcall
local table = table
local type = type
local setmetatable = setmetatable
local ipairs = ipairs
local assert = assert

module("lime")

local dateTimeFormat = "%m/%d/%y %H:%M"

local function generateLevelKey(formatter, o)
  local key = {}
  for i, k in ipairs(formatter or {}) do
    if o[k] then
      table.insert(key, o[k])
    end
  end
  return table.concat(key, "-")
end

local Score = {}

function Score:new(score, o)
  local o = o or {}
  assert(score or o.score, "'score' is a required field")
  o.timestamp = os.time()
  o.score = o.score or score
  setmetatable(o, self)
  self.__index = self
  return o
end

local ScoresFile = {
  filename = system.pathForFile("scores.json", system.DocumentsDirectory),
  maxScores = 10,
  levelKeyFrom = {"level"},
  scores = {}
}

function ScoresFile:new(o)
  local o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function ScoresFile:save()
  local file = io.open(self.filename, "w+")
  file:write(json.encode(self.scores))
  io.close(file)
end

function ScoresFile:read()
  local file = io.open(self.filename, "r")
  if file then
    return pcall(function()
      local data = json.decode(file:read("*a"))
      assert(type(data), table)
      self.scores = data
      io.close(file)
    end)
  end
end

function ScoresFile:scoresFor(o)
  local o = o or {}
  local key = generateLevelKey(self.levelKeyFrom, o)
  if key == '' then
    return self.scores
  else
    return self.scores[key] or {}
  end
end

function ScoresFile:clearScoresFor(o)
  local key = generateLevelKey(self.levelKeyFrom, o)
  if key == '' then
    self.scores = {}
  else
    self.scores[key] = {}
  end
end

function ScoresFile:add(score, o)
  local key = generateLevelKey(self.levelKeyFrom, o)
  local score = Score:new(score, o)
  local scores = scores
  local newHighScore = false

  if #key == 0 then
    scores = self.scores
  else
    self.scores[key] = self.scores[key] or {}
    scores = self.scores[key]
  end

  table.insert(scores, score)

  table.sort(scores, function(a, b)
    return a.score > b.score
  end)

  if #scores > self.maxScores then
    table.remove(scores)
  end

  return scores[1] == score
end

local scoresFile = scoresFile

function setup(o)
  scoresFile = ScoresFile:new(o)
  scoresFile:read()
end

function localScores(o)
  return scoresFile:scoresFor(o)
end

function add(o)
  return scoresFile:add(o.score, o)
end

function save()
  scoresFile:save()
end

function clear(o)
  return scoresFile:clearScoresFor(o)
end

function formatTimestamp(t)
  return os.date(dateTimeFormat, t)
end