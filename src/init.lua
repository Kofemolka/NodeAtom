if gpio.read(3) == gpio.HIGH then
  dofile("boot.lc")
else
  print("Hardware stop! Reboot when ready")
end
