aws-tools
=========

1.  Create a CSV with deployment settings for each type of AWS service (example below)
2.  ./deploy.rb 



CSV
===
# security groups
type,action,name
sg,create,other-security-group
 
# s3 buckets
type,action,bucket
s3,create,coredumps-bucket
s3,create,dbbackup-bucket
 
# IAM user
type,action,user
iam,create,s3-user
 
# RDS
type,action,db_instance_identifier,db_name,allocated_storage,db_instance_class,engine,engine_version,master_username,master_user_password,vpc_security_group_ids,db_subnet_group_name
rds,create,db_instance_orcl,ORCL,100,db.m1.medium,oracle-se1,11.2.0.3.v1,admin,Password_100,"database,other-security-group",gcloud-db-subnet
rds,create,db_instance_pg,postgres,100,db.m1.medium,postgres,9.3.1,postgres,Password_100,"database,other-security-group",gcloud-db-subnet
 
# instances
type,action,name,ip,size,availability_zone,os,security_groups,keypair,block,hostname
 
instance,create,Voice VMP,192.168.7.100,m3.large,us-west-1b,centos,"voice,service-client-and-internet,open-to-the-world",automation-key,DeviceName /dev/sda volume_size:8 DeviceName /dev/sdb volume_size:20,vmp-100-001.yourdomain.com
 
instance,create,Voice VMB,192.168.7.101,m3.large,us-west-1b,centos,"voice,service-client-and-internet,open-to-the-world",automation-key,DeviceName /dev/sda volume_size:8 DeviceName /dev/sdb volume_size:20,vmb-100-001.yourdomain.com
 
instance,create,FWK1,192.168.7.102,m3.medium,us-west-1b,centos,"voice,service-client-and-internet,open-to-the-world",automation-key,DeviceName /dev/sda volume_size:8 DeviceName /dev/sdb volume_size:20,fwk-100-001.yourdomain.com
 
instance,create,FWK2,192.168.7.103,m3.medium,us-west-1b,centos,"voice,service-client-and-internet,open-to-the-world",automation-key,DeviceName /dev/sda volume_size:8 DeviceName /dev/sdb volume_size:20,fwk-100-002.yourdomain.com
 
instance,create,Frontend1,192.168.7.104,m3.xlarge,us-west-1b,centos,"linux-frontend,service-client-and-internet,open-to-the-world",automation-key,DeviceName /dev/sda volume_size:8 DeviceName /dev/sdb volume_size:100,web-100-001.yourdomain.com
 
instance,create,Frontend2,192.168.7.105,m3.xlarge,us-west-1b,centos,"linux-frontend,service-client-and-internet,open-to-the-world",automation-key,DeviceName /dev/sda volume_size:8 DeviceName /dev/sdb volume_size:100,web-100-002.yourdomain.com
 
instance,create,eS1,192.168.7.106,m3.large,us-west-1b,centos,"voice,service-client-and-internet,eservices,open-to-the-world",automation-key,DeviceName /dev/sda volume_size:8 DeviceName /dev/sdb volume_size:26,vap-100-005.yourdomain.com
 
instance,create,eS2,192.168.7.107,m3.large,us-west-1b,centos,"voice,service-client-and-internet,eservices,open-to-the-world",automation-key,DeviceName /dev/sda volume_size:8 DeviceName /dev/sdb volume_size:20,vap-100-005.yourdomain.com
 
instance,create,WFM1,192.168.7.108,r3.large,us-west-1b,windows,"wfm,service-client-and-internet,open-to-the-world",automation-key,DeviceName /dev/sda1 volume_size:100 DeviceName xvdb volume_size:4,vap-100-001.yourdomain.com
 
instance,create,WFM2,192.168.7.109,r3.large,us-west-1b,windows,"wfm,service-client-and-internet,open-to-the-world",automation-key,DeviceName /dev/sda1 volume_size:100 DeviceName xvdb volume_size:4,vap-100-002.yourdomain.com
 
instance,create,WinFE1,192.168.7.110,m3.medium,us-west-1b,windows,"windows-frontend,service-client-and-internet,open-to-the-world",automation-key,DeviceName /dev/sda1 volume_size:100 DeviceName xvdb volume_size:4,web-100-003.yourdomain.com
 
instance,create,WinFE2,192.168.7.111,m3.medium,us-west-1b,windows,"windows-frontend,service-client-and-internet,open-to-the-world",automation-key,DeviceName /dev/sda1 volume_size:100 DeviceName xvdb volume_size:4,web-100-004.yourdomain.com
