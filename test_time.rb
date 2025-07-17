#!/usr/bin/env ruby

# test_time.rb queries ntp server and pxm6000 meter, gets offsets from sys clock, and compares against each other

require_relative 'ru_ontime'

# usage: ./test_time.rb ntp_server meter_ip time_reg_range

input_array = ARGV

ntp_server = input_array[0]
meter_ip = input_array[1]
time_regs_str = input_array[2]

# parse range

def unstr_range(range)
  if range.include?('..')
    return Range.new(*range.split('..').map(&:to_i))
  else
    puts "invalid range format. please use 'start..end'."
    exit
  end
end

time_regs = unstr_range(time_regs_str)

ntp = NetTime.new(ntp_server)
ntp_offset = ntp.offset

# sample meter times and report average offset
meter = MeterStatus.new(meter_ip, time_regs)
meter.take_samples
meter_offset = meter.average_offsets

meter_vs_ntp = meter_offset - ntp_offset

puts "Meter is #{meter_vs_ntp * 1000} ms off from #{ntp_server}"
