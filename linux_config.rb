#!/usr/bin/env ruby

counter = 60
fqdn    = ARGV[0]
role    = ARGV[1]
SSH_KEY	= '/genesys/global-automation.pem'

ssh     = "ssh -i #{SSH_KEY} -o StrictHostKeyChecking=no ec2-user@#{fqdn}"

until system "#{ssh} date"
	sleep 5
	exit 1 if counter == 0
	counter-=1 
end


system "scp -i #{SSH_KEY} -o StrictHostKeyChecking=no resize2fs.sh ec2-user@#{fqdn}:/home/ec2-user"

commands = [ 
  "sudo sed -i \'s/.*/#{fqdn}/g\' /etc/hostname",
  "sudo sed -i \'s/HOSTNAME=.*/HOSTNAME=#{fqdn}/g\' /etc/sysconfig/network",
  "sudo hostname #{fqdn}",
  "sudo /home/ec2-user/resize2fs.sh",
  "\"echo \'export LC_ALL=en_US.utf8\' | sudo tee /etc/profile.d/locale.sh\"",
  "sudo chmod +x /etc/profile.d/locale.sh",
  "sudo rm -rf /etc/yum.repos.d/Cent*",
  "sudo sed -i \'s/https/http/g\' /etc/yum.repos.d/epel.repo",
  "sudo yum clean all",
  "sudo shutdown -r now"
]

commands.each do |command|
  p "#{ssh} #{command}"
  system "#{ssh} #{command}"
end

