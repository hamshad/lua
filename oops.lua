-- METATABLES
print("-- Metatables")

vec3 = {
  { x = 0, y = 0, z = 0 },
  { x = 2, y = 4, z = 5 },
  { x = 3, y = 2, z = 3 },
}


setmetatable(vec3, {
  __add = function(table1, table2)
    for i = 1, #table1 do
      print("table1: " .. table1[i].x .. table1[i].y .. table1[i].z)
      print("table2: " .. table2[i].x .. table2[i].y .. table2[i].z)
    end
    return table1
  end
})

vec3old = vec3 + vec3


-- nums (kinda)
SpeakerIDS = {
  "Soundcore153",
  "nothing526"
}

BassBoosted = {
  ON = 0,
  OFF = 1
}

Wireless = {
  ON = 0,
  OFF = 1
}

EarphoneType = {
  InEar = 0,
  OverEar = 1
}

EngineType = {
  none = 0,
  V6 = 2500,
  V8 = 4000,
  V10 = 5200,
  V12 = 6000
}


-- OOPS (actually just tables and metatables)
print("-- OOPS")
Speaker = {
  speakerID = "",
  isWireless = Wireless.ON,
  isBassBoosted = BassBoosted.OFF,
  player = function(self, isStart, isStop)
    if isStart == true then
      print("STARTING " .. self.speakerID)
      print("BassBoosted = " .. (self.isBassBoosted == BassBoosted.ON and "ON" or "OFF"))
    elseif isStop == true then
      print("STOP " .. self.speakerID)
    end
  end
}

-- initialize
-- : means new(self, ..args..)
-- difference inbet : and . is only the self insertion
-- even at the time of calling use the respective declaring operator
function Speaker:new(model, isWireless, isBassBoosted)
  -- #COMMENT1
  local obj = {}

  setmetatable(obj, Speaker)

  -- if not this, lua won't search for the methods/fields in Earphones in new object
  Speaker.__index = Speaker

  -- this passes same table to new objectes
  -- setmetatable({}, Earphones)

  obj.model = model
  obj.isWireless = isWireless
  obj.isBassBoosted = isBassBoosted

  return obj
end

function Speaker:play()
  self:player(true, false)
end

soundcore = Speaker:new(SpeakerIDS[1], Wireless.ON, BassBoosted.ON)
soundcore:play()


nothing = Speaker:new(SpeakerIDS[2], Wireless.ON, BassBoosted.OFF)
nothing:play()

print("ref #COMMENT1 (nothing == soundcore) is " .. (nothing == soundcore and "same" or "diff"))


-- Inheritence
print("-- Inheritence")
Earphone = Speaker:new()

function Earphone:new(speakerID, isWireless, isBassBoosted, earphoneType)
  -- #COMMENT2
  setmetatable({}, Earphone)

  self.speakerID = speakerID
  self.isWireless = isWireless
  self.isBassBoosted = isBassBoosted
  self.earphoneType = earphoneType

  return self
end

soundcoreAnkerQ1 = Earphone:new(SpeakerIDS[1], Wireless.ON, BassBoosted.ON, EarphoneType.OverEar)
soundcoreAnkerQ1:play()

nothing2a = Earphone:new(SpeakerIDS[2], Wireless.ON, BassBoosted.ON, EarphoneType.InEar)
nothing2a:play()


print("ref #COMMENT2 (nothing == soundcore) is " .. (nothing2a == soundcoreAnkerQ1 and "same" or "diff"))

-- Composition
print("-- Composition")

Engine = {
  type = EngineType.none,
  start = function(self)
    print("Engine Started")
    print("HorsePower = " .. self.type .. "CC")
  end,
  stop = function(self)
    print("Engine Stopped")
  end
}

function Engine:new(type)
  local obj = {}
  setmetatable(obj, Engine)

  Engine.__index = Engine

  obj.type = type

  return obj
end

Car = {
  name = "",
  engine = Engine:new(EngineType.none), -- if Engine:new() then the param defaults to nil
  accelerate = function(self)
    self.engine:start()
    print("Accelerating " .. self.name)
  end,
  brake = function(self)
    self.engine:stop()
    print("Braking " .. self.name)
  end
}

function Car:new(name, engine)
  local obj = {}
  setmetatable(obj, Car)
  Car.__index = Car

  obj.name = name
  obj.engine = engine

  return obj
end

mercedes = Car:new("Mercedes", Engine:new(EngineType.V10))
mercedes:accelerate()

-- sleep 2 seconds
for i = 0.2, 1, 0.1 do
  io.flush()
  os.execute("sleep " .. i)
  io.write(".")
end
print()

mercedes:brake()
