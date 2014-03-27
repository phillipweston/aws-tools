# instance.deploy 1.0
# created by Phillip Mispagel
# phillip.mispagel@genesys.com
# 2/1/2014

class Instance
	attr_accessor :name, :size, :os, :ip, :subnet, :vpc

	def initialize args
		@name 		   = args[:name]
		@ip 		     = args[:ip]
		@size 		   = args[:size]
		@subnet 	   = Shared.find_subnet @ip
		@subnet_id 	 = Shared.find_subnet_id
		@vpc 		     = CONN.vpcs.last.id
		@ami 		     = OS[args[:os]]
    @block       = args[:block]
		@sec_groups  = self.find_security_groups args[:security_groups]
		@keypair		 = args[:keypair]
	end

	def already_exists?
		CONN.servers.each do |server|
			if server.private_ip_address == @ip
				server.tags.map {|tag| puts "#{tag[1]} (#{server.id}) already using #{@ip}. Aborting deploy." if tag[0] == "Name" }
				return true
			end
		end
		false
	end

	def deploy
		unless already_exists?
				CONN.servers.create(
							:image_id => @ami, 
							:vcp_id => @vpc, 
							:subnet_id => @subnet_id, 
							:private_ip_address => @ip,
							:flavor_id => @size,
							:security_group_ids => @sec_groups,
							:tags => {'Name' => @name},
							:key_name => @keypair,
              :block_device_mapping => @block
							)
		else
      puts "Instance already exists at #{@ip}"
    end
	end
end


# Launch specified instances
#
# ==== Parameters
# * image_id<~String> - Id of machine image to load on instances
# * min_count<~Integer> - Minimum number of instances to launch. If this
#   exceeds the count of available instances, no instances will be
#   launched.  Must be between 1 and maximum allowed for your account
#   (by default the maximum for an account is 20)
# * max_count<~Integer> - Maximum number of instances to launch. If this
#   exceeds the number of available instances, the largest possible
#   number of instances above min_count will be launched instead. Must
#   be between 1 and maximum allowed for you account
#   (by default the maximum for an account is 20)
# * options<~Hash>:
#   * 'Placement.AvailabilityZone'<~String> - Placement constraint for instances
#   * 'Placement.GroupName'<~String> - Name of existing placement group to launch instance into
#   * 'Placement.Tenancy'<~String> - Tenancy option in ['dedicated', 'default'], defaults to 'default'
#   * 'BlockDeviceMapping'<~Array>: array of hashes
#     * 'DeviceName'<~String> - where the volume will be exposed to instance
#     * 'VirtualName'<~String> - volume virtual device name
#     * 'Ebs.SnapshotId'<~String> - id of snapshot to boot volume from
#     * 'Ebs.VolumeSize'<~String> - size of volume in GiBs required unless snapshot is specified
#     * 'Ebs.DeleteOnTermination'<~String> - specifies whether or not to delete the volume on instance termination
#     * 'Ebs.VolumeType'<~String> - Type of EBS volue. Valid options in ['standard', 'io1'] default is 'standard'.
#     * 'Ebs.Iops'<~String> - The number of I/O operations per second (IOPS) that the volume supports. Required when VolumeType is 'io1'
#   * 'NetworkInterfaces'<~Array>: array of hashes
#     * 'NetworkInterfaceId'<~String> - An existing interface to attach to a single instance
#     * 'DeviceIndex'<~String> - The device index. Applies both to attaching an existing network interface and creating a network interface
#     * 'SubnetId'<~String> - The subnet ID. Applies only when creating a network interface
#     * 'Description'<~String> - A description. Applies only when creating a network interface
#     * 'PrivateIpAddress'<~String> - The primary private IP address. Applies only when creating a network interface
#     * 'SecurityGroupId'<~String> - The ID of the security group. Applies only when creating a network interface.
#     * 'DeleteOnTermination'<~String> - Indicates whether to delete the network interface on instance termination.
#     * 'PrivateIpAddresses.PrivateIpAddress'<~String> - The private IP address. This parameter can be used multiple times to specify explicit private IP addresses for a network interface, but only one private IP address can be designated as primary.
#     * 'PrivateIpAddresses.Primary'<~Bool> - Indicates whether the private IP address is the primary private IP address.
#     * 'SecondaryPrivateIpAddressCount'<~Bool> - The number of private IP addresses to assign to the network interface.
#     * 'AssociatePublicIpAddress'<~String> - Indicates whether to assign a public IP address to an instance in a VPC. The public IP address is assigned to a specific network interface
#   * 'ClientToken'<~String> - unique case-sensitive token for ensuring idempotency
#   * 'DisableApiTermination'<~Boolean> - specifies whether or not to allow termination of the instance from the api
#   * 'SecurityGroup'<~Array> or <~String> - Name of security group(s) for instances (not supported for VPC)
#   * 'SecurityGroupId'<~Array> or <~String> - id's of security group(s) for instances, use this or SecurityGroup
#   * 'InstanceInitiatedShutdownBehaviour'<~String> - specifies whether volumes are stopped or terminated when instance is shutdown, in [stop, terminate]
#   * 'InstanceType'<~String> - Type of instance to boot. Valid options
#     in ['t1.micro', 'm1.small', 'm1.medium', 'm1.large', 'm1.xlarge', 'c1.medium', 'c1.xlarge', 'c3.large', 'c3.xlarge', 'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge', 'g2.2xlarge', 'hs1.8xlarge', 'm2.xlarge', 'm2.2xlarge', 'm2.4xlarge', 'cr1.8xlarge', 'm3.xlarge', 'm3.2xlarge', 'hi1.4xlarge', 'cc1.4xlarge', 'cc2.8xlarge', 'cg1.4xlarge', 'i2.xlarge', 'i2.2xlarge', 'i2.4xlarge', 'i2.8xlarge']
#     default is 'm1.small'
#   * 'KernelId'<~String> - Id of kernel with which to launch
#   * 'KeyName'<~String> - Name of a keypair to add to booting instances
#   * 'Monitoring.Enabled'<~Boolean> - Enables monitoring, defaults to
#     disabled
#   * 'PrivateIpAddress<~String> - VPC option to specify ip address within subnet
#   * 'RamdiskId'<~String> - Id of ramdisk with which to launch
#   * 'SubnetId'<~String> - VPC option to specify subnet to launch instance into
#   * 'UserData'<~String> -  Additional data to provide to booting instances
#   * 'EbsOptimized'<~Boolean> - Whether the instance is optimized for EBS I/O
#
# {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RunInstances.html]