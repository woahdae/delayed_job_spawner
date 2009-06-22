require File.dirname(__FILE__) + '/spec_helper'
require 'ruby-debug'
describe "delayed_job_spawner" do
  before(:all) do
    @working_dir = File.expand_path(File.dirname(__FILE__))
    @rails_dir   = "#{@working_dir}/tmp_rails"
    commands = [
      "cd #{@working_dir}",
      "rails tmp_rails",
      "ln -s #{@working_dir}/../script/job_spawner #{@rails_dir}/script/job_spawner",
      "ln -s #{@working_dir}/../ #{@rails_dir}/vendor/plugins/delayed_job_spawner",
      "rm -rf #{@rails_dir}/app/models",
      "ln -s #{@working_dir}/models #{@rails_dir}/app/models"
    ]
    system commands.join("&&")
    require "#{@rails_dir}/config/environment"
    require "#{@working_dir}/delayed_job_schema"
  end
  
  after(:all) do
    system "rm -rf #{@rails_dir}"
  end
  
  it "should start instances of Delayed::Worker" do
    `ruby #{@rails_dir}/script/job_spawner start`.should == "DelayedJobSpawner started.\n"
    
    sleep 2
    
    `ps auwx | grep Delayed::Worker`.split("\n").size.should == 5 # one spawner, 2 workers, and 2 'ps' instances
    `ps auwx | grep 'Delayed::Worker Spawner'`.split("\n").size.should == 3
  end
  
  it "should run a job" do
    Greeting.send_later(:create, :message => "hello")
    
    sleep 6
    greeting = Greeting.first
    greeting.should_not be_nil
    greeting.message.should == "hello"
  end
  
  it "should stop instances of Delayed::Worker" do
    `ruby #{@rails_dir}/script/job_spawner stop`
    
    sleep 5
    
    `ps auwx | grep Delayed::Worker`.split("\n").size.should == 2
  end
end