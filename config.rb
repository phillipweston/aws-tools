require 'rubygems'
require 'aws-sdk'
require 'json'
require 'optparse'

if ARGV[0].nil?
  ENVIRONMENT = 'PREPROD' 
else
  ENVIRONMENT = ARGV[0].upcase
end

if ARGV[1].nil?
  LOCATION = 'usw1'
else
  LOCATION = ARGV[1].downcase
end

$report = {}

$report[:iam] = {}
$report[:s3]  = []
$report[:sg]  = {}
$report[:rds] = {}


#----------------------------------------------------
# REGION DEFENITIONS
#----------------------------------------------------
OS = {}

case ENVIRONMENT

  when 'PRODUCTION'

    case LOCATION

      when 'usw1' 

        VPC           = 'vpc-774c111e'
        REGION        = 'us-west-1'
        OS['windows']  = 'ami-827e42c7'
        OS['centos']   = 'ami-d0ffc895'
        OS['citrix']   = 'ami-9e7640db'
      
      when 'use1'

        VPC           = 'vpc-ea6d6788'
        REGION        = 'us-east-1'
        OS['centos']  = 'ami-cec833a6'

      when 'aps1'

        OS['centos']  = 'ami-0b3aa331'
      
      else
        puts "Must set AMIs for #{LOCATION} in config.rb."
        exit 1
    end

  when 'STAGING'

    case LOCATION

      when 'usw1'

        VPC           = 'vpc-c48c85a6'
        REGION        = 'us-west-1'
        OS['ubuntu']   = 'ami-06320343'
        OS['windows']  = 'ami-7e4a793b'
        OS['centos']   = 'ami-d0ffc895'
      
      else
        puts "Must set AMIs for #{LOCATION} in config.rb."
        exit 1
    end

  when 'PREPROD'

    case LOCATION

      when 'usw1'
        VPC           = 'vpc-c48c85a6'
        REGION        = 'us-west-1'
        OS['ubuntu']   = 'ami-06320343'
        OS['windows']  = 'ami-7e4a793b'
        OS['centos']   = 'ami-d0ffc895'

      else
        puts "Must set AMIs for #{LOCATION} in config.rb."
        exit 1
    end
end


#----------------------------------------------------
# Path to SSH key used to login to AWS instances
#----------------------------------------------------
SSH_KEY = '/home/saasops/global-automation.pem'
SSH_PUB = '/home/saasops/global-automation.pem.pub'

system "rm -f ~/.ssh/known_hosts"

#----------------------------------------------------
# AWS Credentials
#----------------------------------------------------
AWS_KEY    = ENV["#{ENVIRONMENT}_KEY"]
AWS_SECRET = ENV["#{ENVIRONMENT}_SECRET"]

if AWS_KEY.nil? || AWS_SECRET.nil?
  puts "You must set #{ENVIRONMENT}_KEY and #{ENVIRONMENT}_SECRET environment variables."
  exit 1
end

AWS.config(
  :access_key_id => AWS_KEY,
  :secret_access_key => AWS_SECRET,
  :region => REGION 
)
