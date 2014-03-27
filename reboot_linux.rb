#!/usr/bin/env ruby

require_relative 'config'

counter = 60
fqdn    = ARGV[0]
ssh     = "ssh -i #{@ssh_key} -o StrictHostKeyChecking=no ec2-user@#{fqdn}"

puts "Rebooting #{ARGV[0]}"
system "#{ssh} shutdown -r now"
system "sleep 60"

counter=60

until system "#{ssh} date"
	sleep 5
	exit 1 if counter == 0
	counter-=1
end

