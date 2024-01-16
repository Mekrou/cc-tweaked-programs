local chat_box = peripheral.wrap("right")
rednet.open("top")

function returnActiveComputers()
  local computers = {rednet.lookup("debug")}
  return computers
end

function pollDebugMessages()
  for _, id in pairs(returnActiveComputers()) do
    rednet.send(id, 33, "debug")
  end
end

function printDebugMessages()
  local id, message = rednet.receive("debugMessage", 1)
  if message ~= nil then
    if type(message) == "string" then
      chat_box.sendMessage(message)
    else
      print(type(message))
      local full_msg = ""
      for _,v in pairs(message) do
        full_msg = full_msg.."\n"..v
      end
      local msg = {
        {
          text = full_msg,
          color = "red"
        }
      }
      
      local json = textutils.serializeJSON(msg)
      print(json)
      chat_box.sendFormattedMessageToPlayer(json, "veganryan101", "Debug", "[]", "&f")
    end
  end
end

-- BEGIN PRORGAM
while true do
  pollDebugMessages()
  printDebugMessages()
  sleep(0.1)
end
