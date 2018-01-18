#!/usr/bin/ruby

require 'aws-sdk'
#
# = Environment Vars
# 
aws_zone = ENV['ZONE'] || "us-west-2"

rds = Aws::RDS::Resource.new(region: 'us-west-2')
      
rds.db_instances.each do |i|
  puts "Name (ID): #{i.id}"
  puts "Status   : #{i.db_instance_status}"
  puts "Endpoint : #{i.endpoint.address}"
  puts "Restorable Time: #{i.latest_restorable_time}"
  if i.read_replica_source_db_instance_identifier puts "Replica of : #{i.read_replica_source_db_instance_identifier}"
  puts
end
