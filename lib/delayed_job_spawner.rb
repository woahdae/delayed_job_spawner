require File.dirname(__FILE__) + "/../vendor/daemon-spawn/lib/daemon-spawn"

class DelayedJobSpawner < DaemonSpawn::Base
  DEFAULT_SPAWN_NUM = 2
  MONITOR_INTERVAL  = 15 # seconds
  
  attr_accessor :spawns, :desired_number_of_spawns
  
  #### Starting methods ####
  
  def start(args)
    load_environment
    $0 = "Delayed::Worker Spawner" # set program name
    self.spawns = []
    self.desired_number_of_spawns = args.first ? args.first.to_i : DEFAULT_SPAWN_NUM
    
    spawn_pool_of(desired_number_of_spawns)
    start_monitor_loop
  end
 
  def load_environment
    GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)
    require "#{self.working_dir}/config/environment"
    unless defined?(Spawn)
      require File.dirname(__FILE__) + "/../vendor/spawn/lib/spawn"
      require File.dirname(__FILE__) + "/../vendor/spawn/lib/patches"
    end
    self.class.send(:include, Spawn)
    DelayedJobSpawner.prefork
  end
    
  def spawn_pool_of(num)
    (0...num).each do
      self.spawns << spawn do
        DelayedJobSpawner.each_spawn
        $0 = "Delayed::Worker"
        worker = Delayed::Worker.new.start
      end
      sleep 0.25 # otherwise doesn't do multiple forks well
    end
  end
  
  def start_monitor_loop
    loop do
      break if $exit
      spawn_pool_of(need_to_spawn) if need_to_spawn.size > 0
      sleep(MONITOR_INTERVAL)
    end
  end

  def need_to_spawn
    ensure_live_spawns
    return desired_number_of_spawns - spawns.size
  end
  
  def ensure_live_spawns
    spawns.each do |spwn|
      alive = begin
        Process.kill(0, spwn.handle)
        true
      rescue Errno::ESRCH, ::Exception
        false
      end
      spawns.delete(spwn) if !alive
    end
    
    spawns
  end
  
  #### Stopping methods ####
  
  def stop
    $exit = true
    kill_spawns
    Process.wait rescue nil # let spawns clean up before exiting
  end
  
  def kill_spawns
    self.spawns.each do |spwn|
      Process.kill('TERM', spwn.handle) rescue nil
    end
  end
  
  #### Class Callbacks ####
  
  def self.each_spawn(&block)
    if block
      @each_spawn = block
    elsif @each_spawn
      @each_spawn.call
    end
  end

  def self.prefork(&block)
    if block
      @prefork = block
    elsif @prefork
      @prefork.call
    end
  end
end
