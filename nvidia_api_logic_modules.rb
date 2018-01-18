#!/usr/bin/ruby

# Must set env before running
# export DOCKER_HOST=192.168.0.113
# export DOCKER_IMAGE="gcr.io/tensorflow/tensorflow:latest"
# export NVIDIA_PORT=3476
# export DOCKER_URL=tcp://192.168.0.113:2375

require 'docker'
require 'socket'
require 'net/http'
require 'json'
require 'pp'
require 'uri'

# host = ENV["DOCKER_HOST"] || "34.215.39.65" #"192.168.0.113"
host = ENV["DOCKER_HOST"] || "192.168.0.113"
# host = ENV["DOCKER_HOST"] || "34.209.230.109"
image = ENV["DOCKER_IMAGE"] || "tensorflow/tensorflow:latest-gpu"

# == Important Ports Bindings
nvidia_port = ENV["NVIDIA_PORT"] || "3476"
docker_port = ENV["DOCKER_PORT"] || "2375"

# == Nvidia APi URL's
# = URL to gather nvidia volumes and devices.
nvidia_docker_url = "http://" + host + ":" + nvidia_port + "/v1.0/docker/cli/json"
# = URl to gather slot status
nvidia_gpu_status = "http://" + host + ":" + nvidia_port + "/v1.0/gpu/status/json"

#
# Returns Json of Volumes Devices
def get_nvidia_docker_info(url)
  resp = Net::HTTP.get_response(URI.parse(url))
  buffer = resp.body
  json_result = JSON.parse(buffer)
  return json_result
end

# Returns Json on GPU(s) status
def get_nvidia_status(url)
  resp = Net::HTTP.get_response(URI.parse(url))
  buffer = resp.body
  json_result = JSON.parse(buffer)
  return json_result
end

# Returns number of GPU's availiable.
def get_slots(json_result)
  return json_result['Devices'].length
end

# Returns Percentage of Nvidia Processing in use per slot.
def get_gpu_usage(json_result, slot)
  gpu_useage = json_result['Devices'][slot]['Utilization']['GPU']
  return gpu_useage
end

# Returns Percentage of Nvidia Memory in use per slot.
def get_gpu_memory_usage(json_result, slot)
  gpu_memory_useage = json_result['Devices'][slot]['Utilization']['Memory']
  return gpu_memory_useage
end

# Returns full directory string to the nvidia driver on host.
def get_gpu_driver_volume(json_result, slot)
  nvidia_volumes = json_result['Volumes'][slot].split(":")
  driver = nvidia_volumes[slot].gsub('nvidia_driver_', '')
  return '/var/lib/nvidia-docker/volumes/nvidia_driver/' + driver
end

#
## End api logic tests
###########################

#################
## Test Create
#
def create_nvidia_container(tag_name, image, volume_driver)
  puts "-- Creating Docker Container"
  container = Docker::Container.create(
   'name' => tag_name,
   'Image' => image,
   'ExposedPorts' => { '9999/tcp' => {} },
   'HostConfig' => {
     'PortBindings' => {
       '8888/tcp' => [{ 'HostPort' => '9999', 'HostIP' => '0.0.0.0'}]
     },
     'Devices' => [
       { 'PathOnHost' => '/dev/nvidiactl', 'PathInContainer' => '/dev/nvidiactl', 'CgroupPermissions' => 'rwm' },
       { 'PathOnHost' => '/dev/nvidia-uvm', 'PathInContainer' => '/dev/nvidia-uvm', 'CgroupPermissions' => 'rwm'},
       # { 'PathOnHost' => '/dev/nvidia-uvm-tools', 'PathInContainer' => '/dev/nvidia-uvm-tools', 'CgroupPermissions' => 'rwm' },
       { 'PathOnHost' => '/dev/nvidia0', 'PathInContainer' => '/dev/nvidia0', 'CgroupPermissions' => 'rwm' }
     ],
      'VolumeDriver' => 'nvidia-docker',
      'Mounts' => [
        { 'Target' => '/usr/local/nvidia',  'Source' => volume_driver, 'Type' => 'bind'}
      ]
     }
  )
  container.start
end

#############################
## MAIN Logic Tests
#
puts "-- Nvidia Host Details and Image to deploy "
puts %Q[ -- Host:  #{host}, Port:  #{nvidia_port}, Docker Image:  #{image} ]
puts "-- "

nvidia_port_is_open = Socket.tcp(host, nvidia_port, connect_timeout: 5) { true } rescue false
docker_port_is_open = Socket.tcp(host, docker_port, connect_timeout: 5) { true } rescue false

if docker_port_is_open
  if nvidia_port_is_open
    for i in 0..(get_slots(get_nvidia_status(nvidia_gpu_status)) - 1)
      gpu_volume = get_gpu_driver_volume(get_nvidia_docker_info(nvidia_docker_url), 0)
      gpu_mem = get_gpu_memory_usage(get_nvidia_status(nvidia_gpu_status), i)
      gpu_proc = get_gpu_usage(get_nvidia_status(nvidia_gpu_status), i)
      puts %Q[-- gpu_volume: #{gpu_volume}]
      puts %Q[-- DEVICE: #{i} Mounted Volume #{gpu_volume} , Using #{gpu_mem}% of memory and #{gpu_proc}% of processing power.]
    end # create_nvidia_container('mroach-gpu-tensorflow', image, gpu_volume)
  else
    puts "-- Nvidia Port Not Open "
    puts "-- Check /lib/systemd/system/nvidia-docker.service"
    puts "-- Update line to => ExecStart=/usr/bin/nvidia-docker-plugin -s $SOCK_DIR -l :3476"
  end
else
  puts "-- Docker Api Port Not Open."
  puts "-- Check /lib/systemd/system/docker.service "
  puts "-- Follow directions in https://github.com/3blades/app-backend/ "
end
