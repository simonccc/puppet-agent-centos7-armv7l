# puppet-agent-centos7-armv7l
puppetlabs puppet-agent compiled / hacked together for centos on armv7 ( eg raspberry pi ) 

The puppet-agent build process is _complex_ to say the least; so I built this - now you don't have to. 

Sorry there is no RPM - I gave up on that. 

I'm using this with raspbian w/docker and the official centos image on a rp4. 

Tested against puppetserver 5.x - puppet reports itself as Puppet v6.7.0

clone the repo and copy puppet labs to /opt in your container or whatever

depending on your setup you may need to add a puppet entry to /etc/hosts

You can find the source here https://github.com/puppetlabs/puppet-agent 


