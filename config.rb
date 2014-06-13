require 'rubygems'
require 'fog'
require 'json'
require 'optparse'

#----------------------------------------------------
# Path to SSH key used to login to AWS instances
#----------------------------------------------------
SSH_KEY = '/home/saasops/global-automation.pem'
SSH_PUB = '/home/saasops/global-automation.pem.pub'

system "rm -f ~/.ssh/known_hosts"

#----------------------------------------------------
# Path to SSH key used to login to AWS instances
#----------------------------------------------------
AWS_KEY    = ENV["#{ENVIRONMENT}_KEY"]
AWS_SECRET = ENV["#{ENVIRONMENT}_SECRET"]

if AWS_KEY.nil? || AWS_SECRET.nil?
  puts "You must set #{ENVIRONMENT}_KEY and #{ENVIRONMENT}_SECRET environment variables."
  exit 1
end

AWS.config(
  :access_key_id => AWS_KEY,
  :secret_access_key => AWS_SECRET )

#----------------------------------------------------
# AMIs to use for each aws account and region
#----------------------------------------------------
OS = {}
case ENVIRONMENT
  when 'PRODUCTION'
    case REGION
      when 'eu-west-1' 
        OS['windows'] = 'ami-7745b700'
        OS['centos']  = 'ami-8b44b6fc'
      when 'ap-southeast-2'
        OS['centos']  = 'ami-0b3aa331'
      else
        puts "Must set AMIs for #{REGION} in config.rb."
        exit 1
    end

  when 'STAGING'
    case REGION
      when 'us-west-1'
        OS['ubuntu']  = 'ami-06320343'
        OS['windows'] = 'ami-7e4a793b'
        OS['centos']  = 'ami-d0ffc895'
      else
        puts "Must set AMIs for #{REGION} in config.rb."
        exit 1
    end

  when 'PREPROD'
    case REGION
      when 'us-west-1'
        OS['ubuntu']  = 'ami-06320343'
        OS['windows'] = 'ami-7e4a793b'
        OS['centos']  = 'ami-d0ffc895'
      else
        puts "Must set AMIs for #{REGION} in config.rb."
        exit 1
    end
end
