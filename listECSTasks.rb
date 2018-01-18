#!/usr/bin/ruby

require 'aws-sdk'
#
# = Environment Vars
# 
aws_zone = ENV['ZONE'] || "us-west-2"

ecs = Aws::ECS::Client.new(region: 'us-west-2')

clusters = ecs.list_task_definitions( { sort: "ASC" } )

puts "Number Of Services: #{clusters.task_definition_arns.length}"
     
for i in 0..(clusters.task_definition_arns.length - 1)
  puts "TASKS ARNS: #{clusters.task_definition_arns[i]} "
end
