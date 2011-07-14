
class openstack_admins_users {
  include sudoers
  
  group { 'corvus':
    ensure => 'present'
  }

  user { 'corvus':
    ensure => 'present',
    comment => 'James E. Blair',
    home => $operatingsystem ? {
      Darwin => '/Users/corvus',
      solaris => '/export/home/corvus',
      default => '/home/corvus',
    },
    shell => '/bin/bash',
    gid => 'corvus',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'corvushome':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus',
      solaris => '/export/home/corvus',
      default => '/home/corvus',
    },
    owner => 'corvus',
    group => 'corvus',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'corvussshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.ssh',
      solaris => '/export/home/corvus/.ssh',
      default => '/home/corvus/.ssh',
    },
    owner => 'corvus',
    group => 'corvus',
    mode => 600,
    ensure => 'directory',
    require => File['corvushome'],
  }

  file { 'corvuskeys':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.ssh/authorized_keys',
      solaris => '/export/home/corvus/.ssh/authorized_keys',
      default => '/home/corvus/.ssh/authorized_keys',
    },
    owner => 'corvus',
    group => 'corvus',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvKYcWK1T7e3PKSFiqb03EYktnoxVASpPoq2rJw2JvhsP0JfS+lKrPzpUQv7L4JCuQMsPNtZ8LnwVEft39k58Kh8XMebSfaqPYAZS5zCNvQUQIhP9myOevBZf4CDeG+gmssqRFcWEwIllfDuIzKBQGVbomR+Y5QuW0HczIbkoOYI6iyf2jB6xg+bmzR2HViofNrSa62CYmHS6dO04Z95J27w6jGWpEOTBjEQvnb9sdBc4EzaBVmxCpa2EilB1u0th7/DvuH0yP4T+X8G8UjW1gZCTOVw06fqlBCST4KjdWw1F/AuOCT7048klbf4H+mCTaEcPzzu3Fkv8ckMWtS/Z9Q== jeblair@operational-necessity\n",
    ensure => 'present',
    require => File['corvussshdir'],
  }

  file { 'corvusbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.bashrc',
      solaris => '/export/home/corvus/.bashrc',
      default => '/home/corvus/.bashrc',
    },
    owner => 'corvus',
    group => 'corvus',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'corvusbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.bash_logout',
      solaris => '/export/home/corvus/.bash_logout',
      default => '/home/corvus/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'corvus',
    group => 'corvus',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'corvusprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.profile',
      solaris => '/export/home/corvus/.profile',
      default => '/home/corvus/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'corvus',
    group => 'corvus',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }



  group { 'jaypipes':
    ensure => 'present'
  }

  user { 'jaypipes':
    ensure => 'present',
    comment => 'Jay Pipes',
    home => $operatingsystem ? {
      Darwin => '/Users/jaypipes',
      solaris => '/export/home/jaypipes',
      default => '/home/jaypipes',
    },
    shell => '/bin/bash',
    gid => 'jaypipes',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'jaypipeshome':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes',
      solaris => '/export/home/jaypipes',
      default => '/home/jaypipes',
    },
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'jaypipessshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.ssh',
      solaris => '/export/home/jaypipes/.ssh',
      default => '/home/jaypipes/.ssh',
    },
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 600,
    ensure => 'directory',
    require => File['jaypipeshome'],
  }

  file { 'jaypipeskeys':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.ssh/authorized_keys',
      solaris => '/export/home/jaypipes/.ssh/authorized_keys',
      default => '/home/jaypipes/.ssh/authorized_keys',
    },
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5d2DekN5POb+e04tVtC/pok7r0Lg/+90sbvhgLTDKSGM7uPI83ulH4sZrMKVU5NTK4GBh9G+RNK6UaKodNiBGKiHZ4QdaMqbkP3TIXd3uDEBUefEAzSqpCGydbjpmtxFZWtA5hcKXTSpMRbbx/vek3lYIRsQaU0Ezc7V0cczSmJBGA6VH22TIW/5wkVvZQozK2jdkIAnJhdL7CN5kKyGs94CfXN9ofNr1ssVb/tPJqSotx7FDcrwT9VmEWTn/nCuoWf42sVu0RIHVMSpr5sxFa+G33omeRLOSCCD+zYZoMCEHZTFNCXZhPWGebWhgGHsu0+bN6heRmoJ8lw01gHxWQ== jpipes@serialcoder\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAt2tCgmlHEj5huGLJTPM2pV+aj6ZObneGq92m30LsKOn2SMrC9y4PpqjlRDweduBDKK2cPSnHt3HL1jM5npLh5IGHN2FxAWo3spgwpWPhdkT1VbdyiTZPw4++y/qZhWdNvEWBpNcf3Zn2Qi0x7F1+5fCri/vwVA9RBG35wozaP0mkxaJuAS/LLR7ZJIF99Fqfdk6+Fp5mobXt0ggEqs/78MhCuE2AYaNZ/VWCoanL4w6+UJwZV1Ftd9Ksx6f+8NpaOC9WlNSxJmp2EDJsLBy8mpJh1OsAjC3hu1VvQYmYhSo47ADSfAw9h7aaLUcL6hb7w2n4f+9Ej2+L6+NzEm0Izw== jpipes@serialcoder",
    ensure => 'present',
    require => File['jaypipessshdir'],
  }

  file { 'jaypipesbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.bashrc',
      solaris => '/export/home/jaypipes/.bashrc',
      default => '/home/jaypipes/.bashrc',
    },
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'jaypipesbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.bash_logout',
      solaris => '/export/home/jaypipes/.bash_logout',
      default => '/home/jaypipes/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'jaypipesprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.profile',
      solaris => '/export/home/jaypipes/.profile',
      default => '/home/jaypipes/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }



  group { 'john-purrier':
    ensure => 'present'
  }

  user { 'john-purrier':
    ensure => 'present',
    comment => 'John Purrier',
    home => $operatingsystem ? {
      Darwin => '/Users/john-purrier',
      solaris => '/export/home/john-purrier',
      default => '/home/john-purrier',
    },
    shell => '/bin/bash',
    gid => 'john-purrier',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'john-purrierhome':
    name => $operatingsystem ? {
      Darwin => '/Users/john-purrier',
      solaris => '/export/home/john-purrier',
      default => '/home/john-purrier',
    },
    owner => 'john-purrier',
    group => 'john-purrier',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'john-purriersshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/john-purrier/.ssh',
      solaris => '/export/home/john-purrier/.ssh',
      default => '/home/john-purrier/.ssh',
    },
    owner => 'john-purrier',
    group => 'john-purrier',
    mode => 600,
    ensure => 'directory',
    require => File['john-purrierhome'],
  }

  file { 'john-purrierkeys':
    name => $operatingsystem ? {
      Darwin => '/Users/john-purrier/.ssh/authorized_keys',
      solaris => '/export/home/john-purrier/.ssh/authorized_keys',
      default => '/home/john-purrier/.ssh/authorized_keys',
    },
    owner => 'john-purrier',
    group => 'john-purrier',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAruUSC26oZvATKLklfJDpp8g/os1YYIypnQUw856znEgRc2mo2l9ASkwE9+zlPZWYpBT6kVtVfN85WyMJM5oq38T9VdPmMQ3ecgrqR7JdFPmmdAkAMzn2RlGPBZr9A//UxZnATFKxF/ZKwDEmIB2zfJ8dr6NSEDGaWC+IWdHNYSU= john@openstack.org",
    ensure => 'present',
    require => File['john-purriersshdir'],
  }

  file { 'john-purrierbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/john-purrier/.bashrc',
      solaris => '/export/home/john-purrier/.bashrc',
      default => '/home/john-purrier/.bashrc',
    },
    owner => 'john-purrier',
    group => 'john-purrier',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'john-purrierbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/john-purrier/.bash_logout',
      solaris => '/export/home/john-purrier/.bash_logout',
      default => '/home/john-purrier/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'john-purrier',
    group => 'john-purrier',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'john-purrierprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/john-purrier/.profile',
      solaris => '/export/home/john-purrier/.profile',
      default => '/home/john-purrier/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'john-purrier',
    group => 'john-purrier',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }



  group { 'mordred':
    ensure => 'present'
  }

  user { 'mordred':
    ensure => 'present',
    comment => 'Monty Taylor',
    home => $operatingsystem ? {
      Darwin => '/Users/mordred',
      solaris => '/export/home/mordred',
      default => '/home/mordred',
    },
    shell => '/bin/bash',
    gid => 'mordred',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'mordredhome':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred',
      solaris => '/export/home/mordred',
      default => '/home/mordred',
    },
    owner => 'mordred',
    group => 'mordred',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'mordredsshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.ssh',
      solaris => '/export/home/mordred/.ssh',
      default => '/home/mordred/.ssh',
    },
    owner => 'mordred',
    group => 'mordred',
    mode => 600,
    ensure => 'directory',
    require => File['mordredhome'],
  }

  file { 'mordredkeys':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.ssh/authorized_keys',
      solaris => '/export/home/mordred/.ssh/authorized_keys',
      default => '/home/mordred/.ssh/authorized_keys',
    },
    owner => 'mordred',
    group => 'mordred',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAr+HlnLCCMnAqP6bvAQmb6aMfNjwp425OuG9nlN6uXXEymP5G/WT/Ok2RWb+O1hsaRGsvwHrkCdhCvT0XrDIWRCK3vaQ/v0LogeRbX5HIdOrH6r5N++DV9SqVTFZ6+54CfOE/pyku6pkBdoM8WJ9EIQBQC82EE6mgtpS/UNdiymsoB+2I8yNwUROm/AROCjqN60PI/2j234qYYaUXoD/FM3ZE/cfUoTTi0NAbt5OM5pCHPfaWhWCYtQ4l2CnEXXhKU9TcoQVoTu54IBAmblgD2LeJnOsKQtVcd5rgGzl/OtkL1ZvWCq23LHMeOC2WANgWIyxp4x66m51uErbgnTwOkQ== monty@sanction\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwgRJ+iQMzive6pq8f/F4N0CN0+SptI5l+yj10Rx3i80Zh4a3ERratuIsEmuyyeBU/l+dmR074Jic/42rYnQJBEKT5bvGLhiftcSUu630NZgAFnP5e4TbpHlYJzXDxOOctAHyd8TH5iQftWeNi5NIYAwfYpO6a4/GE1InMcyqW+icyDxyt3rwDN0qzLHcVFdCgWPsbEuJuqweH/qsen78LNWPro+ynk6dnsSKhe8dWkhYjPhAEjbsL13VezksHNbk2aa/yvppCCgdLdvniaQDKr+F0/X5Xp1teL8L7Rr9Ei+I3l6Ge4I3KY0s8TM+6TpAp4GGvdKakOBeoSAP5wYjrw== root@camelot\n\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyxfIpVCvZyM8BIy7r7WOSIG6Scxq4afean1Pc/bej5ZWHXCu1QnhGbI7rW3sWciEhi375ILejfODl2TkBpfdJe/DL205lLkTxAa+FUqcZ5Ymwe+jBgCH5XayzyhRPFFLn07IfA/BDAjGPqFLvq6dCEHVNJIui6oEW7OUf6a3376YF55r9bw/8Ct00F9N7zrISeSSeZXbNR+dEqcsBEKBqvZGcLtM4jzDzNXw1ITPPMGaoEIIszLpkkJcy8u/13GIrbAwNrB2wjl6Mzj+N9nTsB4rFtxRXp31ZbytCH5G9CL/mFard7yi8NLVEJPZJvAifNVhooxGN06uAiTFE8EsuQ== mtaylor@qualinost\n\nssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIB6bmpw3QjDUMDhYGiSA1tlolTrGQGcSXgfGindWnDymGE5uglpgsGbYeRqL+4lrULCDYvMJ9IGSVJOQ40VcnRcGHO+ykyUp3VNTnfwpU0Ee3xapmKL0o7sPqXx8Vlr0X2b7RaQbUYT48jyI9D1h5RW8At2X4N4A4d1HibfURTzgQ== rsa-key-20100819\nssh-dsa AAAAB3NzaC1kc3MAAACBAKwcqWzaNSScs5Hu7cLUs/xdvw09zbphWzSdB0UNs9rQG3ctkWjbaK+WKsXOpd/gxyWPY4fti1uhK5xFyaaLMOIrf+EhFnnKtJ+Z3pCE/uwRROE/Y74bWHXRZRZ5hB150sFmEYet09ZHPD/lVjtBF9zJcvlWh5CIh7xUviHqp3b/AAAAFQDypk12Poey0L35PgngF6g042NAbwAAAIACd/P1epZQXmtIWXkkFWhp4rQTSqz6YV/FpWCHM8bk7qr+4owhHrFkwS1cSPQyyTnCfNM5lorqJ2chjk1AeGr8OMo9GoUxLNSe0CtcCHjT6b2mfkWnqkSi//KwUq3oNUhkl9xZJls7kT0w6F+CncpPEMYseOb8h5UpZ2xVmAgZmwAAAIBYoLiugqeo39qUZQ0a7vQ3ydlmJ/EJzv1rjWRJ79or01wfkpb+jgBeiTHPeuCw2WTEBpKYkU4U8x5tUHb+kdN6TrABcvbn/kfgsoMZeb1rPaiDDM+93prkSI7hS2FKYDv6TIBsT4StmY/BZHfhTwjQUcW+yYJv7vlM9LeIlA4IEw== monty@speedy\nssh-dsa AAAAB3NzaC1kc3MAAACBAN2I6q4yjydSwEnhf45GPBDvj/MUjPBlTj3Buf+xunUtfdXSIpTDvasTVibEKhNrNkr0zkIe8hE5uOM3pHeSLRx9Tj8Txjn5RN3xsKhkqhS/j/GCPiDWRQnpfHPWHK7NxEMwbMv7Rato8YubVmSq9UodXSWytcSXZCTtQVZJvDMjAAAAFQCA+aVTTD9XcC7A575rcu0j75f2HwAAAIA8tdrsQoNV1AMde6r0iE8T8wkw9T9cA9bwK8sbIR3S81FG805bMdVanBfDBwfOTM/rbuGQoH4F8oqURor7njwARh5BLTFrpqSqSw6vTm30TJnRDUS7qrDG0xrzqk+RF5AXHHJ4MJKbjpUc2C3MHOo+rybjE1rJh9OWr9xG3oRroAAAAIAyN2Btf9fCJh2MhqPrtVCfSUzcE7qz/7XludszUwrWElsTfqXtSfRqiQybXSImVPz9DE+ZufOHGLMGolEi+ALRgLp4L7JDBld+Gga64HnAbg/jmDKN97CyFrRbmVbln/oFQFmDhLchGnERhRKQWOWwXKdOrDgGvDwHORsCffUVLw== mtaylor@qualinost\n\nssh-dsa AAAAB3NzaC1kc3MAAACBAN2I6q4yjydSwEnhf45GPBDvj/MUjPBlTj3Buf+xunUtfdXSIpTDvasTVibEKhNrNkr0zkIe8hE5uOM3pHeSLRx9Tj8Txjn5RN3xsKhkqhS/j/GCPiDWRQnpfHPWHK7NxEMwbMv7Rato8YubVmSq9UodXSWytcSXZCTtQVZJvDMjAAAAFQCA+aVTTD9XcC7A575rcu0j75f2HwAAAIA8tdrsQoNV1AMde6r0iE8T8wkw9T9cA9bwK8sbIR3S81FG805bMdVanBfDBwfOTM/rbuGQoH4F8oqURor7njwARh5BLTFrpqSqSw6vTm30TJnRDUS7qrDG0xrzqk+RF5AXHHJ4MJKbjpUc2C3MHOo+rybjE1rJh9OWr9xG3oRroAAAAIAyN2Btf9fCJh2MhqPrtVCfSUzcE7qz/7XludszUwrWElsTfqXtSfRqiQybXSImVPz9DE+ZufOHGLMGolEi+ALRgLp4L7JDBld+Gga64HnAbg/jmDKN97CyFrRbmVbln/oFQFmDhLchGnERhRKQWOWwXKdOrDgGvDwHORsCffUVLw== mtaylor@qualinost\n",
    ensure => 'present',
    require => File['mordredsshdir'],
  }

  file { 'mordredbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.bashrc',
      solaris => '/export/home/mordred/.bashrc',
      default => '/home/mordred/.bashrc',
    },
    owner => 'mordred',
    group => 'mordred',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'mordredbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.bash_logout',
      solaris => '/export/home/mordred/.bash_logout',
      default => '/home/mordred/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'mordred',
    group => 'mordred',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'mordredprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.profile',
      solaris => '/export/home/mordred/.profile',
      default => '/home/mordred/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'mordred',
    group => 'mordred',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }



  group { 'dendrobates':
    ensure => 'present'
  }

  user { 'dendrobates':
    ensure => 'present',
    comment => 'Rick Clark',
    home => $operatingsystem ? {
      Darwin => '/Users/dendrobates',
      solaris => '/export/home/dendrobates',
      default => '/home/dendrobates',
    },
    shell => '/bin/bash',
    gid => 'dendrobates',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'dendrobateshome':
    name => $operatingsystem ? {
      Darwin => '/Users/dendrobates',
      solaris => '/export/home/dendrobates',
      default => '/home/dendrobates',
    },
    owner => 'dendrobates',
    group => 'dendrobates',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'dendrobatessshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/dendrobates/.ssh',
      solaris => '/export/home/dendrobates/.ssh',
      default => '/home/dendrobates/.ssh',
    },
    owner => 'dendrobates',
    group => 'dendrobates',
    mode => 600,
    ensure => 'directory',
    require => File['dendrobateshome'],
  }

  file { 'dendrobateskeys':
    name => $operatingsystem ? {
      Darwin => '/Users/dendrobates/.ssh/authorized_keys',
      solaris => '/export/home/dendrobates/.ssh/authorized_keys',
      default => '/home/dendrobates/.ssh/authorized_keys',
    },
    owner => 'dendrobates',
    group => 'dendrobates',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyPD6HkWT4pz20Ygfo72MxiMsCc4JmlVq/LO0GQRw1ZBG4f0rkjegYBDFLLzOR60RPfqpvb3OApJBHcx3HJG9IxtPc5yZN615sBwPOLK6SWO9kFMhBVq4w3uQFIvpONyR7KbRlWJFVn1W02pRkGGp//bN15h6Ry24kfzEgcjOMbq9vb57/dumj9tL6pZyBSWLgOjWj70KEo/n8Z9AFn7lZOZgq4fmqMuDD79ahsjnwGpKjh2v/SIALV2AjYWJOwY/0ou7l7ghVvfOB4ZOgSYDxhz2/ORqL4yUzncyChcLH1Xg5nscvc+yaOatMaXtVlkPAEPDUSzfho8DyAqt1tjRKw== rclark@blackcat\n",
    ensure => 'present',
    require => File['dendrobatessshdir'],
  }

  file { 'dendrobatesbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/dendrobates/.bashrc',
      solaris => '/export/home/dendrobates/.bashrc',
      default => '/home/dendrobates/.bashrc',
    },
    owner => 'dendrobates',
    group => 'dendrobates',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'dendrobatesbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/dendrobates/.bash_logout',
      solaris => '/export/home/dendrobates/.bash_logout',
      default => '/home/dendrobates/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'dendrobates',
    group => 'dendrobates',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'dendrobatesprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/dendrobates/.profile',
      solaris => '/export/home/dendrobates/.profile',
      default => '/home/dendrobates/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'dendrobates',
    group => 'dendrobates',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }



  group { 'soren':
    ensure => 'present'
  }

  user { 'soren':
    ensure => 'present',
    comment => 'Soren Hansen',
    home => $operatingsystem ? {
      Darwin => '/Users/soren',
      solaris => '/export/home/soren',
      default => '/home/soren',
    },
    shell => '/bin/bash',
    gid => 'soren',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'sorenhome':
    name => $operatingsystem ? {
      Darwin => '/Users/soren',
      solaris => '/export/home/soren',
      default => '/home/soren',
    },
    owner => 'soren',
    group => 'soren',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'sorensshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.ssh',
      solaris => '/export/home/soren/.ssh',
      default => '/home/soren/.ssh',
    },
    owner => 'soren',
    group => 'soren',
    mode => 600,
    ensure => 'directory',
    require => File['sorenhome'],
  }

  file { 'sorenkeys':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.ssh/authorized_keys',
      solaris => '/export/home/soren/.ssh/authorized_keys',
      default => '/home/soren/.ssh/authorized_keys',
    },
    owner => 'soren',
    group => 'soren',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA7bpJJzvwa4KKzxk9fyegkCUKKOA1gttDJdB+E2mllxcDkScYRYoFnwiq0kl1BwkNFRXj10pguhI/7O3escSvF3Di2Lw4haHR8my6yaz7jFlBbBw8+6j5RbIRnTORS5G4mH4LtAxToGomfJd9gxWpVMiqLa4V7Hg8K6CYRSSUOWzqs7Y/Hv13ASr8ZbaweB1ygVE8kbKuW2ILcqRrKYKaQDeh+aPqLsXDNhT2k2WLsTIqMTSKy70sHqyCjD2joRVBuTiqt1uaQqYCJWT8vuDvXsF0Lmi4tMjRF7GOuOKd0QsT5y8C8dLHWDfeBNQJv46dZE6UUHOfhucTM4w73zpXaw== soren@butch\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA8YfXbgi0uNZEpOxLvzPdGgo5dAAjqVUGf+kU1bvxcZf3y7a2veDXOOnez4VGl6OC1bgeENW/5O2hKi0wUG3XMWp8uLVSupI6A8o+cBCu7MYzChMdgullBEh7Bz4cbvoMmQiWOZPPsZLTTrl7E6SJJ5jTTn8IsSkCp21m2Sr4b5SWj+Nw43NVtGYFtBBG/OoixlxcNutiSn7YjOH6CAVOhKpTNddwqECKBfxCdS2kYrMzJw8/QhA9FwJHoFt3PevuC4I/9ARlyZCsbOY+ENc2NtFXNVnF5m6tE/eDZFTt652pNPlldWAaVBzKDZ4CUi4HS3WDxGcVqhtaNawIV6sR8w== soren@intel\n\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyAtAccJ8ndh6wzq3vY1izHTdPh3kAKtjBK6P390ClIRBA3CfjKS6KaKSeGs1xZ4WZhOk9oz4d/+Ep7iOXLpUnYYjHm5bLD8o6jKAhKohoABzCyj3ONPNxvxvsvdahSPLONC6H1PlbhvTbn9UwEtZ//migJTATdLQEjXHaNhNJ8UZz9XtCf1Qv4YiYmyRId6h5N+OPNU4OmqlCZyanBXKN5jK1Kubq6SseY++74Y54ZPXVccGmJDTOfNBfM1nR0+f2Mq2iHR0a3PuJcGXFx/P4mIA0Knyh98W6esB9fG7/JVID2bGpJ6c91+AkL9fmwOpfWrk7rr13+iGiH2RTcmd0w== soren@lenny\n\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCGTnV3tEMvry4UruD6I23TW3L616ML8p15kdj4TYlcBUZvUDzPoT+QjinNw7Pm1C4dJk3xJJtvxshKSXF08QF88kWgtF6jSpp1ZwmDXKNnPRLAIT5pewubFHd5iwMFf371P2/kxIm37iAo45puTO0CL39dAKkw6L/F7M3ycFUgsIkik6oN9bX1X3Yu3e/Lv2hJ1LGN7K2nnQmLd9aFulpruM7iPtFt8qJ82ofJq2LGH931QsP1QonvJxonajo9wrEAfXTFENDwcoOD0Py+KXOddqb/1SJxbLwclDmHMX5bKA5K+R6GzzpDUEsDZYa1xhJpmOmlaBTxFGoQg/wtHUNf cardno:000500000063",
    ensure => 'present',
    require => File['sorensshdir'],
  }

  file { 'sorenbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.bashrc',
      solaris => '/export/home/soren/.bashrc',
      default => '/home/soren/.bashrc',
    },
    owner => 'soren',
    group => 'soren',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'sorenbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.bash_logout',
      solaris => '/export/home/soren/.bash_logout',
      default => '/home/soren/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'soren',
    group => 'soren',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'sorenprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.profile',
      solaris => '/export/home/soren/.profile',
      default => '/home/soren/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'soren',
    group => 'soren',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }



  group { 'ttx':
    ensure => 'present'
  }

  user { 'ttx':
    ensure => 'present',
    comment => 'Thierry Carrez',
    home => $operatingsystem ? {
      Darwin => '/Users/ttx',
      solaris => '/export/home/ttx',
      default => '/home/ttx',
    },
    shell => '/bin/bash',
    gid => 'ttx',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'ttxhome':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx',
      solaris => '/export/home/ttx',
      default => '/home/ttx',
    },
    owner => 'ttx',
    group => 'ttx',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'ttxsshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.ssh',
      solaris => '/export/home/ttx/.ssh',
      default => '/home/ttx/.ssh',
    },
    owner => 'ttx',
    group => 'ttx',
    mode => 600,
    ensure => 'directory',
    require => File['ttxhome'],
  }

  file { 'ttxkeys':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.ssh/authorized_keys',
      solaris => '/export/home/ttx/.ssh/authorized_keys',
      default => '/home/ttx/.ssh/authorized_keys',
    },
    owner => 'ttx',
    group => 'ttx',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAz4Mu4IhAg3/AY4fCnAomOAJIkJS4YnTlTXiIikUIqS/R\n116Do8CxKJjwM8MPc0i/n7zpYKTgAEJ4qbgaWG/sGokUw8ZsJ+6WfcSLGszU/6qd7+s3BEqUyStTsPrV\nmK7gnBroub+WaLk0/BKfMR+Mx3MJY/wPisuqdHK8kViQR09/qSFuuPgSZsYw2GuLM1Ul4h3vC4BaAbQV\ne+1AKq7/Yz+ARK1IDr7ZqdK7T1f/G01Vi1J03Q0YCeB7JFvUFtwPm561yNOWXxQuJMQ9Z1CDunRpLiil\nRN8WrM97ETF9i+XKCavb54UxzDz1SEwyhSouTdSFRc1A3jZMloZrvr2hLQ== ttx@cassini\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIF2INBeJdT3nT3+3yac+DGRQVN7wPv/GTb/OPDocQhfGMeQP7JwSURiv1nrXGbbjzuip7l7vRJs4u4NqXkUi0GFj1aLBpUm2Z1NFFDn4cuZ5KCYX6rjVrDYIpj4OlOyzt9YGONvvH/dB2GHw8kYbN50OalFWQCS0TVzj9SQbO47B/TPdtLnh116yEP5AXZZUGgl+q533/x8+nxAxJKA9iAk3mSswl67gXc4pRo84pjwpx+R/52ha6RfmLkoNAEOqtr5MGx5gyW+WXsoLJBl2bjcfzYoQI7gPWRIn+rtCnDFi762TS54zstXxR1ww+ppmqHk04l2oprNoI0wr00Fsl ttx@stardust\n",
    ensure => 'present',
    require => File['ttxsshdir'],
  }

  file { 'ttxbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.bashrc',
      solaris => '/export/home/ttx/.bashrc',
      default => '/home/ttx/.bashrc',
    },
    owner => 'ttx',
    group => 'ttx',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'ttxbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.bash_logout',
      solaris => '/export/home/ttx/.bash_logout',
      default => '/home/ttx/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'ttx',
    group => 'ttx',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'ttxprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.profile',
      solaris => '/export/home/ttx/.profile',
      default => '/home/ttx/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'ttx',
    group => 'ttx',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }



  group { 'wreese':
    ensure => 'present'
  }

  user { 'wreese':
    ensure => 'present',
    comment => 'Will Reese',
    home => $operatingsystem ? {
      Darwin => '/Users/wreese',
      solaris => '/export/home/wreese',
      default => '/home/wreese',
    },
    shell => '/bin/bash',
    gid => 'wreese',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'wreesehome':
    name => $operatingsystem ? {
      Darwin => '/Users/wreese',
      solaris => '/export/home/wreese',
      default => '/home/wreese',
    },
    owner => 'wreese',
    group => 'wreese',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'wreesesshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/wreese/.ssh',
      solaris => '/export/home/wreese/.ssh',
      default => '/home/wreese/.ssh',
    },
    owner => 'wreese',
    group => 'wreese',
    mode => 600,
    ensure => 'directory',
    require => File['wreesehome'],
  }

  file { 'wreesekeys':
    name => $operatingsystem ? {
      Darwin => '/Users/wreese/.ssh/authorized_keys',
      solaris => '/export/home/wreese/.ssh/authorized_keys',
      default => '/home/wreese/.ssh/authorized_keys',
    },
    owner => 'wreese',
    group => 'wreese',
    mode => 640,
    content => "",
    ensure => 'present',
    require => File['wreesesshdir'],
  }

  file { 'wreesebashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/wreese/.bashrc',
      solaris => '/export/home/wreese/.bashrc',
      default => '/home/wreese/.bashrc',
    },
    owner => 'wreese',
    group => 'wreese',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'wreesebash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/wreese/.bash_logout',
      solaris => '/export/home/wreese/.bash_logout',
      default => '/home/wreese/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'wreese',
    group => 'wreese',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'wreeseprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/wreese/.profile',
      solaris => '/export/home/wreese/.profile',
      default => '/home/wreese/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'wreese',
    group => 'wreese',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }



}
  