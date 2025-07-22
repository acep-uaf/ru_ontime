#!/usr/bin/env ruby

# test_time.rb queries ntp server and pxm6000 meter, gets offsets from sys clock, and compares against each other

require_relative 'ru_ontime'
require 'yaml'
require 'colored'

# usage: ./test_time.rb ntp_server meter_ip time_reg_range

input_array = ARGV
cfg = {}

# use config.yml if ARGV is empty
if input_array.empty?
  if File.exist?('config.yml')
    puts "Loading config.yml".green
    cfg = YAML.load_file('config.yml')['poll_cfg']
  else
    puts "No config.yml file found - please use arguments:".red
    puts "./test_time ntp_server meter_ip time_register_range".yellow
    exit
  end
else
  cfg['ntp_server'] = input_array[0]
  cfg['meter_ip'] = input_array[1]
  cfg['time_regs_str'] = input_array[2]
end

# parse range

def unstr_range(range)
  if range.include?('..')
    return Range.new(*range.split('..').map(&:to_i))
  else
    puts "invalid range format. please use 'start..end'.".red
    exit
  end
end

time_regs = unstr_range(cfg['time_regs_str'])

ntp = NetTime.new(cfg['ntp_server'])
ntp_offset = ntp.offset

# sample meter times and report average offset
meter = MeterStatus.new(cfg['meter_ip'], time_regs)
meter.take_samples
meter_offset = meter.average_offsets

meter_vs_ntp = meter_offset - ntp_offset

puts "Meter is #{(meter_vs_ntp * 1000).round(3)} ms off from #{cfg['ntp_server']}"
