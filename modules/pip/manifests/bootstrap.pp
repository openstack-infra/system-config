# Class: pip::bootstrap
#

define pip::bootstrap ( $pythonver = $title)
{
    include pip::params
    notify{"completed bootstrap for ${pythonver}":
            require => [
                    Exec["get_ez_setup for ${pythonver}"],
                    Exec["get_get_pip for ${pythonver}"],
                    ],
    }

    exec { "get_ez_setup for ${pythonver}":
      command => 'wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O /var/lib/ez_setup.py',
      path    => '/bin:/usr/bin',
      creates => '/var/lib/ez_setup.py',
      require => Package['wget'],
    }

    exec { "get_get_pip for ${pythonver}":
      command => 'wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py -O /var/lib/get-pip.py',
      path    => '/bin:/usr/bin',
      creates => '/var/lib/get-pip.py',
      require => Exec["get_ez_setup for ${pythonver}"],
    }

    # the pip2/3 provider requires json to be installed before it can function under puppet.
    # we use gem1.8 puppet if rubygems is setup so that puppet can get gem updates.
    exec { "gem 1.8 latest install json":
        command  => "/usr/bin/gem1.8 install json latest --no-rdoc --no-ri" ,
        path     => '/bin:/usr/bin',
        onlyif   => [
                    "test -f /usr/bin/gem1.8" ,
                    "bash -c '/usr/bin/gem1.8 list | awk -F\" \" \"{print \\\$1\\\":\\\"\\\$2}\" |grep \"^json:.*\" ; if [[ \$? -eq 0 ]]; then exit 1; else exit 0; fi'"
                    ],
    }

}
