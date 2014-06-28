# instance.deploy 1.0
# created by Phillip Mispagel
# phillip.mispagel@genesys.com
# 2/1/2014

class Instance

  def initialize args
    @ec2                  = AWS::EC2.new
    @args                 = args
    @ami                  = OS[args[:os]]
    @subnet               = get_subnet args[:ip]
    @subnet_id            = get_subnet_id
    @block                = get_block_devices args[:block_device_mappings] if args[:block_device_mappings]
    @security_groups      = Shared.find_security_groups args[:security_groups].split(',') if args[:security_groups]
  end

  def already_exists?
    @ec2.instances.each do |server|
      if server.private_ip_address == @args[:ip]
        server.tags.map {|tag| puts "#{tag[1]} (#{server.id}) already using #{@args[:ip]}. Aborting deploy." if tag[0] == "Name" }
        return true
      end
    end
    false
  end

  def get_block_devices block
    # input  = DeviceName /dev/sdb volume_size:100 volume_type:io1 iops:500 DeviceName /dev/sdc volume_size:150 volume_type:io1 iops:550
    # output = [{device_name: '/dev/sdb', ebs: {volume_size: 100, volume_type: 'io1', iops: 500 }}]

    devices = []
    blocks = block.split(/\s?DeviceName\s?/)
    # => ["", "/dev/sdb volume_size:100 volume_type:io1 iops:500", "/dev/sdc volume_size:150 volume_type:io1 iops:550"]

    blocks.shift
    # => ["/dev/sdb volume_size:100 volume_type:io1 iops:500", "/dev/sdc volume_size:150 volume_type:io1 iops:550"]

    blocks.each do |b|
      h = {}
      # h => {}

      t = b.split

      h[:device_name] = t.shift
      # h => {device_name: '/dev/sdb'}

      h[:ebs] = {}
      # h => {device_name: '/dev/sdb', ebs: {} }

      # t => [volume_size:100, volume_type:io1, iops:500]
      until t.empty?
        a = t.shift
        pair = a.split(':')
        pair[1] = pair[1].to_i if pair[1] !~ /[a-z]/
        h[:ebs][pair[0]] = pair[1]
      end
      devices.push h unless h.nil?
    end
    devices
  end

  def get_subnet ip
    subnet = ip.split('.')
    subnet[-1] = '0'
    subnet = subnet.join('.')
  end

  def get_subnet_id
    @ec2.subnets.each do |aws_subnet|
      if get_subnet(aws_subnet.cidr_block) == @subnet
        return aws_subnet.id
      end
    end
  end

  def delete
    # @ec2.instances.filter('private-ip-address', '10.52.10.52').first
  end

  def deploy
    unless already_exists?

      instance = @ec2.instances.create(
          :image_id               => @ami, 
          :subnet_id               => @subnet_id, 
          :private_ip_address     => @args[:ip],
          :instance_type           => @args[:size],
          :security_group_ids     => @security_groups,
          :key_name               => @args[:keypair],
          :availability_zone      => @args[:availability_zone],
          :block_device_mappings  => @block #hash #{ "device_name" => "/dev/sdc", "virtual_name" => "ephemeral0" }# @block #[{device_name: '/dev/sdb', ebs: {volume_size: 100, volume_type: 'io1', iops: 500 }}] #@block
          )

        instance.tags["Name"]   = @args[:name]
        instance.tags["Owner"]   = 'Sergey Belov'
        puts "instance #{@args[:name]} deployed to #{@args[:ip]}"
    end
  end
end
