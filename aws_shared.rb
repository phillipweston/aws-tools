module Shared

  def Shared.find_security_groups groups
    group_ids = []
    groups.each do |name|
      puts name
      sec = CONN.security_groups.get name
      puts sec
      group_ids << sec.group_id
    end
    group_ids
  end

  def Shared.find_subnet ip
    subnet = ip.split('.')
    subnet[-1] = '0'
    subnet.join('.')
  end

  def Shared.find_subnet_id
    CONN.subnets.each do |aws_subnet|
      return aws_subnet.subnet_id if self.find_subnet(aws_subnet.cidr_block) == self.subnet
    end
  end

end