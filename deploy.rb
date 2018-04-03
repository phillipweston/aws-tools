#!/usr/bin/env ruby

# Tenant deployment automation 
# Genesys 2014
# Phillip Mispagel
# v0.1

USAGE = <<-eos
usage: ./deploy.rb [environment] [location] [tenant_id] [csv]
              
              environments: production preprod 
              locations:    usw1 euw1 aps1 ap2 use1
              tenant_id:    070 080 100 
              csv           tenant.csv (saved as csv from excel)
eos

require 'csv'

if ARGV[0].nil? || ARGV[1].nil? || ARGV[2].nil? || ARGV[3].nil?
  puts USAGE
  exit 1
end

TENANT_ID        = ARGV[2]
csv_file         = ARGV[3]

require_relative 'config'
require_relative 'resources/aws_shared'
require_relative 'resources/aws_instance'
require_relative 'resources/aws_rds'
require_relative 'resources/aws_sg'


CSV.foreach(csv_file) do |row|
  # variables passed in from spreadhseet, by index
  
  # 0 :type
  # 1 :action

  type   = row[0]
  action = row[1]

  case type
    
    #-------------------------------------------------------------------------------------------
    # security groups
    #
    # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/EC2/SecurityGroupCollection.html
    #-------------------------------------------------------------------------------------------
    when 'sg'

      # 2 :name                 ex: redhat bucket

      args = {}
      args[:name]                 = row[2]

      ec2 = AWS::EC2.new

      begin
        ec2.security_groups.create(args[:name], :vpc => VPC)
        puts "creating sg #{args[:name]}"

      rescue AWS::EC2::Errors::InvalidGroup::Duplicate
        puts "sg #{args[:name]} already exists, skipping."
      end


    #-------------------------------------------------------------------------------------------
    # s3 buckets
    #
    # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/S3/Bucket.html
    #-------------------------------------------------------------------------------------------
    when 's3'

      # 2 :name                 ex: redhat bucket

      args = {}
      args[:name]                 = row[2]


      s3 = AWS::S3.new

      unless s3.buckets[args[:name]].exists?
        puts "creating s3 bucket #{args[:name]}"
        bucket = s3.buckets.create(args[:name])
      else
        puts "s3 bucket #{args[:name]} already exists, skipping."

      end

      $report[:s3].push(args[:name])


    #-------------------------------------------------------------------------------------------
    # iam users and policies for s3 buckets
    #
    # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/IAM.html
    #-------------------------------------------------------------------------------------------
    when 'iam'

      # 2 :name                 ex: tenant100

      args = {}
      args[:name] = row[2]

      iam    = AWS::IAM.new
      user   = iam.users[args[:name]] 

      unless user.exists?
        user = iam.users.create(args[:name])
      end

      # clear all old access keys
      user.access_keys.clear

      # create new access key pair and report add to report variable
      access_key  = user.access_keys.create

      $report[:iam][:username] = user.name
      $report[:iam][:key]      = access_key.credentials[:access_key_id]
      $report[:iam][:secret]   = access_key.credentials[:secret_access_key]

      
      # add user to the deny policies
      groups = %w(s3-deny-delete-policy S3PolicyDisallowWriteFromOutsideNAT)

      groups.each do |name|
        group = iam.groups.find(name).first
        group.users.add(user)
      end

      # create a new policy for each s3 bucket and apply to this user
      $report[:s3].each do |bucket|

        policy_tpl = "{\"Statement\": [ { \"Action\": [ \"s3:ListAllMyBuckets\" ], \"Effect\": \"Allow\", \"Resource\": [ \"*\" ]}, { \"Action\": [ \"s3:Get*\", \"s3:List*\", \"s3:PutObject\", \"s3:AbortMultipartUpload\" ], \"Effect\": \"Allow\", \"Resource\": [\"arn:aws:s3:::#{bucket}\", \"arn:aws:s3:::#{bucket}/*\"] }]}"
        
        policy = AWS::IAM::Policy.from_json(policy_tpl)

        user.policies[bucket] = policy
      end


    #-------------------------------------------------------------------------------------------
    # instances
    #
    # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/EC2/InstanceCollection.html
    #-------------------------------------------------------------------------------------------
    when 'instance'

      # 2 :name                 ex: GCloud Pro Voice VM 001
      # 3 :ip                   ex: 10.51.58.15
      # 4 :size                 ex: m3.large
      # 5 :availability_zone    ex: us-west-1a
      # 6 :os                   ex: centos
      # 7 :security_groups      ex: ROLE-voice,TENANT-Redhat
      # 8 :keypair              ex: global-automation
      # 9 :block                ex: DeviceName /dev/sdb volume_size:100 volume_type:io1 iops:500 DeviceName /dev/sdc volume_size:150 volume_type:io1 iops:550

      args = {}
      args[:name]                  = row[2]
      args[:ip]                    = row[3]
      args[:size]                  = row[4]
      args[:availability_zone]     = row[5]
      args[:os]                    = row[6]
      args[:security_groups]       = row[7]
      args[:keypair]               = row[8]
      args[:block_device_mappings] = row[9]


      aws = AWS::EC2.new
      instance = aws.instances.filter('private-ip-address', args[:ip]).first
      case action
	
        when 'create'
          if instance
            puts "instance #{args[:name]} already exists, skipping."
          else
            instance = Instance.new(args)
            instance.deploy
	    #sleep 30
          end

        when 'delete'
          unless instance.nil?
            if instance.status !~ /ermina/
              puts "terminating instance #{args[:name]}"
              instance.terminate
            end
          end

      end   


    #-------------------------------------------------------------------------------------------
    # rds
    #
    # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/RDS/DBInstanceCollection.html
    #-------------------------------------------------------------------------------------------
    when 'rds'

      # 2 :db_instance_identifier     ex: tenant090 
      # 3 :db_name                    ex: ORCL
      # 4 :allocated_storage          ex: 100
      # 5 :db_instance_class          ex: db.m1.medium
      # 6 :engine                     ex: oracle-se1
      # 7 :engine_version             ex: 11.2.0.3.v1
      # 8 :master_username            ex: tenant090
      # 9 :master_user_password       ex: Napoleon1812_90
      # 10 :vpc_security_group_ids    ex: ROLE-database,Tenant-Phillip
      # 11 :db_subnet_group_name      ex: gcloud-db-subnet

      args = {}
      args[:db_instance_identifier] = row[2]
      args[:db_name]                = row[3]
      args[:allocated_storage]      = row[4].to_i
      args[:db_instance_class]      = row[5]
      args[:engine]                 = row[6]
      args[:engine_version]         = row[7]
      args[:master_username]        = row[8]
      args[:master_user_password]   = row[9]
      args[:vpc_security_group_ids] = row[10]
      args[:db_subnet_group_name]   = row[11]


      case action
        when 'create'        
          Rds.new(args).deploy
            
        when 'delete'
          Rds.delete args 
      end

    end
end


require 'erb'


class Template
  attr_accessor :tenant_id, :location, :customer_name, :db_password, :db_user, :s3_key, :s3_secret, :region
  def template_binding
    binding
  end
end


#databag  = File.open("tenant_#{TENANT_ID}.json", "w+")
#template = File.read("tenant.json.erb")

rendered = Template.new

rendered.tenant_id        = TENANT_ID
rendered.location         = LOCATION
rendered.region           = REGION
rendered.customer_name    = 'Genesys'
rendered.db_password      = "Password"
rendered.db_user          = "tenant#{TENANT_ID}"
rendered.s3_key           = $report[:iam][:key]
rendered.s3_secret        = $report[:iam][:secret]

#databag << ERB.new(template).result(rendered.template_binding)
#databag.close

puts "s3_user: #{$report[:iam][:username]}"
puts "s3_key: #{$report[:iam][:key]}"
puts "s3_secret: #{$report[:iam][:secret]}"


