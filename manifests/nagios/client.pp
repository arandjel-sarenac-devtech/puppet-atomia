class atomia::nagios::client(
    $username           = "nagios",
    $password           = "nagios",
    $public_ip          = $ipaddress_eth0,
    $nagios_ip,          
	$atomiadns_user		= "atomiadns",
	$atomiadns_password = hiera("atomia::atomiadns::agent_password"),
) {

	# Deploy on Windows.
	if $operatingsystem == 'windows' {
	

		class { 'nsclient':
  			allowed_hosts => [$nagios_ip],
		}	

    	@@nagios_host { "${fqdn}-host" :
        	use                 => "generic-host",
        	host_name           => $fqdn,
        	alias               => "${fqdn}",
        	address             => $public_ip ,
        	target              => "/etc/nagios3/conf.d/${hostname}_host.cfg",
        	hostgroups          => "windows-all"

    	}

	} else {
	# Deploy on other OS (Linux)
    package { [
        'nagios-nrpe-server',
		'libconfig-json-perl',
		'libdatetime-format-iso8601-perl'
    ]:
        ensure => installed,
    }
   

    if ! defined(Package['libwww-mechanize-perl']) {
        package { 'libwww-mechanize-perl':
            ensure => installed,
        }
    } 

    # Define hostgroups based on custom fact
    case $atomia_role {
        'apache_agent':         { $hostgroup = 'linux-customer-webservers,linux-all'}
        'atomiadns_master':     { $hostgroup = 'linux-dns,linux-all'}
        'awstats':              { $hostgroup = 'linux-atomia-agents,linux-all'}
        'cronagent':            { $hostgroup = 'linux-atomia-agents,linux-all'}
        'daggre':               { $hostgroup = 'linux-atomia-agents,linux-all'}
        'domainreg':            { $hostgroup = 'linux-atomia-agents,linux-all'}
        'fsagent':              { $hostgroup = 'linux-atomia-agents,linux-all'}
        'nameserver':           { $hostgroup = 'linux-dns,linux-all'}
        'pureftpd':             { $hostgroup = 'linux-ftp-servers,linux-all'}
        
    }
        

    service { 'nagios-nrpe-server':
        ensure => running,
        require => Package["nagios-nrpe-server"],
    }
    
    # Configuration files
    file { '/etc/nagios/nrpe.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('atomia/nagios/nrpe.cfg.erb'),
        require => Package["nagios-nrpe-server"],
        notify  => Service["nagios-nrpe-server"]
    }  
    
    @@nagios_host { "${fqdn}-host" :
        use                 => "generic-host",
        host_name           => $fqdn,
		alias			    => "${$atomia_role} - ${fqdn}",
        address             => $public_ip ,
        target              => "/etc/nagios3/conf.d/${hostname}_host.cfg",
        hostgroups          => $hostgroup
     
    }

	if ($atomia_role == "daggre") {
		@@nagios_service { "${fqdn}-daggre":
			host_name				=> $fqdn,
			service_description		=> "Daggre disk space parser",
			check_command			=> "check_nrpe_1arg!check_daggre_ftp",
			use						=> "generic-service",
			target              	=> "/etc/nagios3/conf.d/${hostname}_services.cfg",
		}

        @@nagios_service { "${fqdn}-daggre-weblog":
            host_name               => $fqdn,
            service_description     => "Daggre weblog parser",
            check_command           => "check_nrpe_1arg!check_daggre_weblog",
            use                     => "generic-service",
            target                  => "/etc/nagios3/conf.d/${hostname}_services.cfg",
        }

	}

	if ($atomia_role == "atomiadns_master") {

        @@nagios_service { "${fqdn}-atomiadns":
            host_name               => $fqdn,
            service_description     => "AtomiaDNS API",
            check_command           => "check_nrpe!check_atomiadns!atomia-nagios-test.net!$atomiadns_user!$atomiadns_password",
            use                     => "generic-service",
            target                  => "/etc/nagios3/conf.d/${hostname}_services.cfg",
        }
	}
    
    if ($atomia_role == "domainreg") {

        @@nagios_service { "${fqdn}-domainreg":
            host_name               => $fqdn,
            service_description     => "Domainreg API .com",
            check_command           => "check_nrpe!check_domainreg!foo.com",
            use                     => "generic-service",
            target                  => "/etc/nagios3/conf.d/${hostname}_services.cfg",
        }
    }

	if !defined(File["/usr/lib/nagios/plugins/atomia"]){	
    	file { "/usr/lib/nagios/plugins/atomia":
			source 				=> "puppet:///modules/atomia/nagios/plugins",
			recurse				=> true,
			require             => Package["nagios-nrpe-server"]
		}
	}
    
	}
}
