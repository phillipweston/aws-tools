# instance.deploy 1.0
# created by Phillip Mispagel
# phillip.mispagel@genesys.com
# 2/1/2014


@rds_options = {}
OptionParser.new do |opts|

  opts.on("-t", "--type string", String, "type") do |type|
    @rds_options[:type] = type
  end

  opts.on("-i", "--id string", String, "tenant_id") do |i|
    @rds_options[:id] = i
  end

  opts.on("-g", "--security_groups first,second,third", Array, "security groups") do |sg|
    @options[:security_groups] = sg
  end
end.parse!


class Rds

  def initialize args
    @instance    = "tenant#{args[:id]}"
    @id          = args[:ip]
    @vpc         = CONN.vpcs.last.id
    @ami         = OS[args[:os]]
    @sec_groups  = self.find_security_groups args[:security_groups]
    @keypair     = args[:keypair]
  end

  def create
    rds = AWS::RDS.create(
      :db_instance_identifier => @instance,
      :allocated_storage      => 100,
      :db_instance_class      => 'db.m1.medium',
      :engine                 => 'postgres',
      :master_username        => @instance,
      :master_user_password   => 'NewS3cr3t32u3er!',
      
  end

end

