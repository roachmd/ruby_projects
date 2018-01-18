#!/usr/bin/ruby

require 'aws-sdk'
#
# = Environment Vars
# 
aws_zone = ENV['ZONE'] || "us-west-2"

ecs = Aws::ECS::Client.new(region: 'us-west-2')

clusters = ecs.list_clusters( { } )

puts "Number Of Clusters: #{clusters.cluster_arns.length}"
     
for i in 0..(clusters.cluster_arns.length - 1)
  puts "Cluster: #{clusters.cluster_arns[i]} "
end
