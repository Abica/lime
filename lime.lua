require "json"

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
local print = print
local unpack = unpack

--[[
  basic usage:

  -- setup

  -- the levelKeyFrom option takes a table of property names
  -- that are used to generate and group scores, based off of
  -- the optios table that you pass in at score creation
  --
  -- think of them as a method of creating dymanic lobbies
  lime.setup({
    maxPerLevel = 10,
    levelKeyFrom = {"difficulty", "level"}
  })

  -- add a score
  lime.add({
    score = player.score,
    level = 50,
    difficulty = "hard"
  })

  -- write scores to a file
  lime.save()
--]]

module("lime")

local dateTimeFormat = "%m/%d/%y %H:%M%p"

local function generateLevelKey(formatter, o)
  local key = {}
  for i, k in ipairs(formatter or {}) do
    if o[k] then
      table.insert(key, o[k])
    end
  end
  print(unpack(key))
  return table.concat(key, "-")
end

local Score = {}

function Score:new(score, o)
  local o = o or {}
  o.timestamp = os.time()
  o.submittedAt = os.date(dateTimeFormat, o.timestamp)
  o.score = o.score
  setmetatable(o, self)
  self.__index = self
  return o
end

local ScoresFile = {
  filename = system.pathForFile("scores.json", system.DocumentsDirectory),
  maxPerLevel = 10,
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
  local key = generateLevelKey(self.levelKeyFrom, o)
  if #key == 0 then
    return self.scores
  else
    return self.scores[key] or {}
  end
end

function ScoresFile:add(score, o)
  local key = generateLevelKey(self.levelKeyFrom, o)
  local score = Score:new(score, o)
  local scores = scores
  if #key == 0 then
  print("AAA")
    scores = self.scores
  else
  print("BBB", self.scores, key)
    self.scores[key] = self.scores[key] or {}
    scores = self.scores[key]
  end

  for i=#scores, 1, -1 do
    local s = scores[i]
    if s.score > score.score then
      table.insert(scores, i + 1, score)
      break
    end
  end

  if #scores == 0 then
    table.insert(scores, score)
  end

  if #scores > self.maxPerLevel then
    table.remove(scores)
  end
end

local scoresFile = scoresFile

function setup(o)
  scoresFile = ScoresFile:new(o)
  scoresFile:read()
end

function localScores(o)
  scoresFile:scoresFor(o)
end

function add(o)
  scoresFile:add(o.score, o)
end

function save()
  scoresFile:save()
end

function clearLevel(o)
end