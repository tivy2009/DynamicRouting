local function main()

  local key = "routing_asdb"

  local start_index, end_index, sub = string.find(key,"routing_")
  
  print("start_index: ",start_index == 1)
  
  print("start_index: ",start_index)
  print("end_index: ",end_index)
  print("sub: ",sub)


end

main()
