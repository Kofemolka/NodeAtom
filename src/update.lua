local module = {}

local firmTopic = "firmware"
local appFile = "app.lua"

local function update(data)
  print("Updating...")
  file.open(appFile, "w")
  file.write(data)
  file.close()

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

function module.subscribe(broker)
  broker:subscribe(firmTopic,0, nil)
end

function module.onEvent(topic, data)
  if topic == firmTopic then
    update(data)
    return true
  end

  return false
end

return module
