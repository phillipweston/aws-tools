#!/usr/bin/env ruby

class SecurityGroup

  def initialize args
    @args = args
    @ec2 = AWS::EC2.new
    @security_groups = @ec2.security_groups
    @filename       = "#{@LOCATION}_security_groups.json"
    @master_hash    = {}
  end

  # def copy(source dest filter)
  #   # source = region to pull from
  #   # dest = region to copy to
  #   # filter = any string you want to search by


  # end

  def get filter
    properties = [:name, :description, :ip_permissions_list, :ip_permissions_list_egress]

    @security_groups.each do |group|
      if group.name =~ /ROLE/
        sg = {}
        properties.each { |property| sg[property] = group.send(property) }
        @master_hash[group.name] = sg
      end
    end
  end

  def load_security_groups filename
    JSON.parse(IO.read(filename), :symbolize_names => true)
  end

  def add

  end

  def create security_group
    vpc = AWS.memoize { VPC }

      # if security_group == "all"

      # load all security groups from json
      security_groups = self.load_security_groups

      # for each security group
      security_groups.each do |sg|
        # create new security group if it doesn't exist in AWS
        unless @security_groups.filter('group-name', "#{sg[1][:name]}").first.instance_of? AWS::EC2::SecurityGroup
          sg_add = @security_groups.create(sg[1][:name], {:vpc => vpc })
          puts "Creating security group: #{sg[1][:name]} => #{sg_add.id}"
        end    
      end

      @security_groups = AWS.memoize { @ec2.security_groups }

      security_groups.each do |sg|
       self.update sg[1][:name]
     end
   end

  end

   def delete security_group
    @security_groups = @ec2.security_groups
    vpc = @ec2.vpcs.first
    if security_group == "all"
      security_groups = self.load_security_groups

      security_groups.each do |sg|
       self.update sg[1][:name]
     end

     security_groups.each do |sg|
      if @security_groups.filter('group-name', "#{sg[1][:name]}").first.instance_of? AWS::EC2::SecurityGroup
        if sg[1][:name] != "default"
         puts "deleting #{sg[1][:name]}"
         @security_groups.filter('group-name', "#{sg[1][:name]}").first.delete
       end
     end    
   end
 end
end


def write
  self.get_all

  @master_hash.each do |sg|
    sg[1][:ip_permissions_list].each do |t| 
      unless t[:groups].empty?
        group_name = @ec2.security_groups.filter('group-id', "#{t[:groups][0][:group_id]}").first.name
        t[:groups][0] = {:group_name => group_name}
      end
    end
  end

  @master_hash.each do |sg|
    sg[1][:ip_permissions_list_egress].each do |t| 
      unless t[:groups].empty?
        group_name = @ec2.security_groups.filter('group-id', "#{t[:groups][0][:group_id]}").first.name
        t[:groups][0] = {:group_name => group_name}
      end
    end
  end

  @afile = File.new(@filename, "w")
  @afile.syswrite(JSON.pretty_generate @master_hash)
end

def get_security_group(rule)
  case
  when rule[:group_id]
    return @security_groups.filter('group-id', "#{rule[:group_id]}").first

  when rule[:group_name]
    return @security_groups.filter('group-name', "#{rule[:group_name]}").first 

  when rule[:cidr_ip]
    return rule[:cidr_ip]
  end    
end

def ingress_authorize(live, rule)
  return if rule[2].empty?
  sleep(1.0/2)
  puts "#{live.name}: authorize_ingress => \"#{rule[0]}\", \"#{rule[1]}\", \"#{rule[2]}\""
  live.authorize_ingress(rule[0].to_sym, rule[1], get_security_group(rule[2]))
end

def ingress_revoke(live, rule)
  sleep (1.0/2)
  puts "#{live.name}: revoke_ingress => \"#{rule[0]}\", \"#{rule[1]}\", \"#{rule[2]}\""
  live.revoke_ingress(rule[0].to_sym, rule[1], get_security_group(rule[2]))
end

def egress_authorize(live, rule)
  sleep (1.0/2)
  return if rule[2].empty?
  puts "#{live.name}: authorize_egress => #{rule[2]}"
  live.authorize_egress(get_security_group(rule[2]), {:protocol => rule[0].to_sym, :ports => rule[1]})
end

def egress_revoke(live, rule)
  sleep (1.0/2)
  group = get_security_group(rule[2])
  live.revoke_egress group
  puts "#{live.name}: revoke_egress => #{group}"
  group = (group.is_a? String) ? group : group.name
end

def update(security_group)
  @security_groups = AWS.memoize { @ec2.security_groups }
  sg    = self.load_security_groups
  live  = @security_groups.filter('group-name', security_group).first
  file  = sg[security_group.to_sym]
  types = [:ip_permissions_list, :ip_permissions_list_egress]

  in_auth = []
  in_rev  = []
  e_auth  = []
  e_rev   = []


  puts security_group
  types.each do |type|

    file[type].each_with_index do |rule, index|

      live_permissions = live.ip_permissions_list[index] if type == :ip_permissions_list
      live_permissions = live.ip_permissions_list_egress[index] if type == :ip_permissions_list_egress


      unless live_permissions == nil
        unless live_permissions[:groups].empty?
          group_name = @security_groups.filter('group-id', "#{live_permissions[:groups][0][:group_id]}").first.name
          live_permissions[:groups][0] = {:group_name => group_name}
        end
      end

      if rule != live_permissions

        file_cidr = []
        live_cidr = []


        unless rule[:ip_ranges].empty?
          rule[:ip_ranges].each { |ip| file_cidr << ip }
        end

        unless live_permissions == nil
          unless live_permissions[:ip_ranges].empty?
            live_permissions[:ip_ranges].each { |ip| live_cidr << ip }
          end
        end

        unless rule[:groups].empty?
          rule[:groups].each { |group| file_cidr << group }
        end

        unless live_permissions == nil
          unless live_permissions[:groups].empty?
            live_permissions[:groups].each { |group| live_cidr << group }
          end
        end


        add = file_cidr - live_cidr
        sub = live_cidr - file_cidr

        range = (rule[:to_port].to_i == 0) ? '0..0' : rule[:from_port]..rule[:to_port]
        prot = rule[:ip_protocol]


        if type == :ip_permissions_list
          add.each { |ip| in_auth << [prot, range, ip]}
          sub.each { |ip| in_rev << [prot, range, ip]}
        else
          add.each { |ip| e_auth << [prot, range, ip]}
          sub.each { |ip| e_rev << [prot, range, ip]}
        end

      end
    end
  end

  in_rev.each {|r| ingress_revoke(live, r) }
  in_auth.each {|r| ingress_authorize(live, r) }

  e_rev.each {|r| egress_revoke(live, r) }
  e_auth.each {|r| egress_authorize(live, r) }
        # sleep 1
end
# end
    # end


    security_groups = SecurityGroup.new


    if ARGV[0] == "get"
      security_groups = SecurityGroup.new
      security_groups.write
    elsif ARGV[0] == "update"
      security_groups.update ARGV[1]
    elsif ARGV[0] == "create"
      security_groups.create ARGV[1]
    elsif ARGV[0] == "delete"
      security_groups.delete ARGV[1]
    end

