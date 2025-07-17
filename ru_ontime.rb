#!/usr/bin/env ruby

require 'net/ntp'
require 'rmodbus'

class NetTime
  attr_accessor :server
  def initialize(server)
    @server = server
    @response = nil
    @rtt = nil
  end

  def response
    @response ||= Net::NTP.get(@server)
  end

  def time
    response.time
  end

  def offset
    response.offset
  end

  def round_trip_time
    return @rtt if @rtt
    
    t1 = response.originate_timestamp.to_f
    t2 = response.receive_timestamp.to_f
    t3 = response.transmit_timestamp.to_f
    t4 = response.client_time_receive.to_f
    
    @rtt = (t4 - t1) -  (t3 - t2)
  end
end

class MeterStatus
  attr_reader :time

  def initialize(meter_ip, time_reg_range)
    @meter_ip = meter_ip
    @time_reg_range = time_reg_range
    @raw_regs = []
    @time = nil
    @samples = []
  end

  def query_time
    ModBus::TCPClient.connect(@meter_ip, 502) do |cl|
      cl.with_slave(1) do |slave|
        
        @raw_regs = slave.holding_registers[@time_reg_range]

        @time = Time.parse("#{@raw_regs[2]}-#{@raw_regs[0]}-#{@raw_regs[1]} #{@raw_regs[4]}:#{@raw_regs[5]}:#{@raw_regs[6]}.#{@raw_regs[7] * 10}")
      
      end
    end
  end

  def take_samples(n = 5)
    ModBus::TCPClient.connect(@meter_ip, 502) do |cl|
      cl.with_slave(1) do |slave|
        n.times do
          start = Time.now.to_f

          raw_regs = slave.holding_registers[@time_reg_range] 

          stop = Time.now.to_f
          
          # little calculations
          meter_time = Time.parse("#{raw_regs[2]}-#{raw_regs[0]}-#{raw_regs[1]} #{raw_regs[4]}:#{raw_regs[5]}:#{raw_regs[6]}.#{raw_regs[7] * 10}")

          rtt = stop - start

          midpoint = Time.at((start + stop) / 2.0)

          offset = midpoint - meter_time
          
          @samples << { meter_time:, midpoint:, rtt:, offset: }
        
        end
      end
    end
  end
  
  def average_offsets(trim_ratio = 0.3)

    n = (@samples.size * trim_ratio).ceil
    
    sorted = @samples.sort_by { |s| s[:rtt] }
    
    trimmed = sorted[0..(@samples.size - n)]
 
    trimmed.map { |s| s[:offset] }.sum / trimmed.size

  end
end
