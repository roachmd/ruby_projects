#!/usr/bin/ruby

require 'aws-sdk'
#
# = Environment Vars
# 
aws_zone = ENV['ZONE'] || "us-west-2"

ecs = Aws::ECS::Client.new(region: 'us-west-2')

clusters = ecs.list_services( { } )

puts "Number Of Services: #{clusters.service_arns.length}"
     
for i in 0..(clusters.service_arns.length - 1)
  puts "Service ARNS: #{clusters.service_arns[i]} "
end
