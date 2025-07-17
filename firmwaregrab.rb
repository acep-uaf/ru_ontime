#!/usr/bin/env ruby

# grabs firmware version of PXM meter
# usage: ./firmwaregrab.rb meter_ip firmware_reg

require 'rmodbus'

input_arg = ARGV
meter_ip = input_arg[0]
firmware_reg = input_arg[1].to_i

def grab_firmware(meter_ip, firmware_reg)
  ModBus::TCPClient.connect("#{meter_ip}", 502) do |cl|
    cl.with_slave(1) do |slave|
      regs = slave.holding_registers
      firmware_v = regs[firmware_reg]
      puts firmware_v
    end
  end
end

grab_firmware(meter_ip, firmware_reg)
