# RDS deployment
# by Phillip Mispagel
# phillip.mispagel@genesys.com
# 2/1/2014


# db_instance_identifier: tenant090
# static_attributes:
# :vpc_id: vpc-c48c85a6
# :allocated_storage: 100
# :availability_zone_name: us-west-1b
# :backup_retention_period: 30
# :character_set_name:
# :creation_date_time: 2014-06-18 20:45:42.000561000 Z
# :db_instance_class: db.m1.medium
# :db_name: postgres
# :endpoint_address: tenant090.cbqzbhbeezd5.us-west-1.rds.amazonaws.com
# :endpoint_port: 5432
# :engine: postgres
# :engine_version: 9.3.1
# :master_username: tenant090
# :multi_az: true
# :iops:
# :preferred_backup_window: 23:00-23:30
# :preferred_maintenance_window: thu:22:00-thu:22:30
# :read_replica_db_instance_identifiers: []
# :read_replica_source_db_instance_identifier:


class Rds
  # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/RDS/DBInstanceCollection.html

  def initialize args
    @rds                      = AWS::RDS.new
    @args                     = args
    @vpc_security_group_ids   = Shared.find_security_groups args[:vpc_security_group_ids].split(',') if args[:vpc_security_group_ids]
    
    case args[:engine]
      when 'postgres'
        @license_model = 'postgresql-license'
      when 'oracle-se1'
        @license_model = 'license-included'
    end

  end

  def already_exists?
    if @rds.db_instances[@args[:db_instance_identifier]].exists?
      puts "rds #{@args[:db_instance_identifier]} already exists, skipping."
      return true
    else
      puts "deploying rds #{@args[:db_instance_identifier]}"
      return false
    end
  end

  def deploy
    unless already_exists?
      @rds.db_instances.create(
        @args[:db_instance_identifier], 
        :db_name                          => @args[:db_name],
        :allocated_storage                => @args[:allocated_storage],
        :db_instance_class                => @args[:db_instance_class],
        :engine                           => @args[:engine],
        :master_username                  => @args[:master_username],
        :master_user_password             => @args[:master_user_password],
        :db_subnet_group_name             => @args[:db_subnet_group_name],
        :engine_version                   => @args[:engine_version],
        :vpc_security_group_ids           => @vpc_security_group_ids,
        :license_model                    => @license_model,
        :preferred_maintenance_window     => 'thu:22:00-thu:22:30',
        :backup_retention_period          => 30,
        :preferred_backup_window          => '23:00-23:30',
        :multi_az                         => true,
        :publicly_accessible              => false
      )
      get_endpoint
    end
  end

  def get_endpoint             
    until @rds.db_instances[@args[:db_instance_identifier]].endpoint_address
      sleep 5
    end
    
    endpoint = @rds.db_instances[@args[:db_instance_identifier]].endpoint_address

    $report[:rds][@args[:db_instance_identifier]] = endpoint
    puts "#{@args[:db_instance_identifier]} available at #{endpoint}" 
  end

  def self.delete args
    rds = AWS::RDS.new
    db  = rds.db_instances[args[:db_instance_identifier]]
    if db.exists?
      if db.status != 'deleting'
        puts "deleting rds #{db.db_instance_identifier}"
        db.delete(skip_final_snapshot: true)
      end
    end  
  end

end
