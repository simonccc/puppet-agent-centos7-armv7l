# puppet-centos7-armv7l
puppetlabs compiled / hacked together puppet-agent for centos on armv7 ( raspberry pi ) 

Tested against puppetserver 5.x

The puppet-agent build process is complex to say the least; so I built this so you don't have to.

I'm using this with raspbian and docker with the official centos image on a rp4 - ymmv

clone the repo and copy puppet labs to /opt in your container or whatever

depending on your setup you may need to add a puppet entry to /etc/hosts

You can find the source here https://github.com/puppetlabs/puppet-agent 


