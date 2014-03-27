#!/usr/bin/env ruby

require_relative 'config'

counter = 60
fqdn    = ARGV[0]
role    = ARGV[1]
ssh     = "ssh -i #{SSH_KEY} -o StrictHostKeyChecking=no ec2-user@#{fqdn}"

until system "#{ssh} date"
	sleep 5
	exit 1 if counter == 0
	counter-=1 
end

commands = %w(
  sudo sed -i \"s/.*/#{fqdn}/g\" /etc/hostname
  sudo hostname #{fqdn}
)

if role =~ /CassandraNode/
  system "scp -i #{SSH_KEY} -o StrictHostKeyChecking=no cassandrafs.sh ec2-user@#{fqdn}:/home/ec2-user"
  commands.push "sudo /home/ec2-user/cassandrafs.sh"
end
commands.each do |command|
  p "#{ssh} #{command}"
  system "#{ssh} #{command}"
end

