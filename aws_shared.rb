module Shared

  def Shared.find_security_groups groups
    group_ids = []
    groups.each do |name|
      ec2 = AWS::EC2.new
      sec = ec2.security_groups.filter('group-name', name).first
      unless sec.nil?
        group_ids << sec.id
      end
    end
    group_ids
  end

  

end