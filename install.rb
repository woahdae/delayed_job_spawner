require 'rubygems'
require 'fileutils'
FileUtils.cp(File.dirname(__FILE__) + '/script/job_spawner', File.dirname(__FILE__) + "/../../../script/job_spawner")
FileUtils.chmod "+x", File.dirname(__FILE__) + "/../../../script/job_spawner"