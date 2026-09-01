-- METATABLES

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


-- OOPS (actually just tables and metatables)

EarphoneType = {
  InEar = 0,
  OverEar = 1
}

BassBoosted = {
  ON = 0,
  OFF = 1
}

Wireless = {
  ON = 0,
  OFF = 1
}

Earphones = {
  model = "",
  isWireless = Wireless.ON,
  isBassBoosted = BassBoosted.OFF,
  type = EarphoneType.InEar,
  player = function(self, isStart, isStop)
    if isStart == true then
      print("STARTING " .. self.model)
      print("BassBoosted = " .. (self.isBassBoosted and "ON" or "OFF"))
    elseif isStop == true then
      print("STOP " .. self.model)
    end
  end
}

-- initialize
-- : means new(self, ..args..)
-- difference inbet : and . is only the self insertion
-- even at the time of calling use the respective declaring operator
function Earphones:new(model, isWireless, isBassBoosted, type)
  local obj = {}

  setmetatable(obj, Earphones)

  -- if not this, lua won't search for the methods/fields in Earphones in new object
  Earphones.__index = Earphones

  -- this passes same table to new objectes
  -- setmetatable({}, Earphones)

  obj.model = model
  obj.isWireless = isWireless
  obj.isBassBoosted = isBassBoosted
  obj.type = type

  return obj
end

function Earphones:play()
  self:player(true, false)
  print("Type = " .. (self.type == EarphoneType.InEar and "InEar" or "OverEar"))
end

soundcore = Earphones:new("Anker", Wireless.ON, BassBoosted.OFF, EarphoneType.OverEar)

soundcore:play()


nothing = Earphones:new("2a", Wireless.ON, BassBoosted.OFF, EarphoneType.InEar)

nothing:play()

print(soundcore == nothing)
print(nothing == soundcore)
