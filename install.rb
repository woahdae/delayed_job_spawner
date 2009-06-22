require 'file_utils'
FileUtils.mv(File.dirname(__FILE__) + '/script/job_spawner', "#{RAILS_ROOT}/script/job_spawner")