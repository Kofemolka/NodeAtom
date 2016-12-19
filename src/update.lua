local module = {}

local firmTopic = "firmware"
local appFile = "app.lua"

function module.subscribe(broker)
  broker:subscribe(firmTopic,0, nil)
end

function module.onEvent(topic, data)
  if topic == firmTopic then
    process(data)
    return true
  end

  return false
end

local function process(data)
  print("Updating...")
  f = file.open(appFile, "w")
  f:write(data)
  f:close()

  print("Compiling...")
  node.compile(appFile)
  file.remove(appFile)
  local countdown = 5
  tmr.alarm(2, 1000, 1,
    function()
      print("Restarting in " .. countdown)
      countdown = countdown - 1
      if countdown < 0 then
        node.restart()
      end
    end)
end

return module
