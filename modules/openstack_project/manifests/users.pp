# == Class: openstack_project::users
#
class openstack_project::users {
  # Make sure we have our UID/GID account minimums for dynamic users set higher
  # than we'll use for static assignments, so as to avoid future conflicts.
  include ::openstack_project::params
  file { '/etc/login.defs':
    ensure => present,
    group  => 'root',
    mode   => '0644',
    owner  => 'root',
    source => $::openstack_project::params::login_defs,
  }
  User::Virtual::Localuser {
    require => File['/etc/login.defs']
  }

  @user::virtual::localuser { 'mordred':
    realname => 'Monty Taylor',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDLsTZJ8hXTmzjKxYh/7V07mIy8xl2HL+9BaUlt6A6TMsL3LSvaVQNSgmXX5g0XfPWSCKmkZb1O28q49jQI2n7n7+sHkxn0dJDxj1N2oNrzNY7pDuPrdtCijczLFdievygXNhXNkQ2WIqHXDquN/jfLLJ9L0jxtxtsUMbiL2xxZEZcaf/K5MqyPhscpqiVNE1MjE4xgPbIbv8gCKtPpYIIrktOMb4JbV7rhOp5DcSP5gXtLhOF5fbBpZ+szqrTVUcBX0oTYr3iRfOje9WPsTZIk9vBfBtF416mCNxMSRc7KhSW727AnUu85hS0xiP0MRAf69KemG1OE1pW+LtDIAEYp',
    key_id   => 'mordred@camelot',
    uid      => 2000,
    gid      => 2000,
  }

  @user::virtual::localuser { 'corvus':
    realname => 'James E. Blair',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAvKYcWK1T7e3PKSFiqb03EYktnoxVASpPoq2rJw2JvhsP0JfS+lKrPzpUQv7L4JCuQMsPNtZ8LnwVEft39k58Kh8XMebSfaqPYAZS5zCNvQUQIhP9myOevBZf4CDeG+gmssqRFcWEwIllfDuIzKBQGVbomR+Y5QuW0HczIbkoOYI6iyf2jB6xg+bmzR2HViofNrSa62CYmHS6dO04Z95J27w6jGWpEOTBjEQvnb9sdBc4EzaBVmxCpa2EilB1u0th7/DvuH0yP4T+X8G8UjW1gZCTOVw06fqlBCST4KjdWw1F/AuOCT7048klbf4H+mCTaEcPzzu3Fkv8ckMWtS/Z9Q==',
    key_id   => 'jeblair@operational-necessity',
    uid      => 2001,
    gid      => 2001,
  }

  @user::virtual::localuser { 'smaffulli':
    realname => 'Stefano Maffulli',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDD/zAvXaOUXCAT6/B4sCMu/38d/PyOIg/tYsYFAMgfDUzuZwkjZWNGrTpp/HFrOAZISER5KmOg48DKPvm91AeZOHfAXHCP6x9/FcogP9rmc48ym1B5XyIc78QVQjgN6JMSlEZsl0GWzFhQsPDjXundflY07TZfSC1IhpG9UgzamEVFcRjmNztnBuvq2uYVGpdI+ghmqFw9kfvSXJvUbj/F7Pco5XyJBx2e+gofe+X/UNee75xgoU/FyE2a6dSSc4uP4oUBvxDNU3gIsUKrSCmV8NuVQvMB8C9gXYR+JqtcvUSS9DdUAA8StP65woVsvuU+lqb+HVAe71JotDfOBd6f',
    key_id   => 'stefano@mattone-E6420',
    uid      => 2002,
    gid      => 2002,
  }

  # NOTE(pabelanger): Inactive user
  @user::virtual::localuser { 'oubiwann':
    realname => 'Duncan McGreggor',
    sshkeys  => '',
    key_id   => 'oubiwann@rhosgobel',
    uid      => 2003,
    gid      => 2003,
  }

  # NOTE(pabelanger): Inactive user
  @user::virtual::localuser { 'rockstar':
    realname => 'Paul Hummer',
    sshkeys  => '',
    key_id   => 'rockstar@spackrace.local',
    uid      => 2004,
    gid      => 2004,
  }

  @user::virtual::localuser { 'clarkb':
    realname => 'Clark Boylan',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCnfoVhOTkrY7uoebL8PoHXb0Fg4jJqGCbwkxUdNUdheIdbnfyjuRG3iL8WZnzf7nzWnD+IGo6kkAo8BkNMK9L0P0Y+5IjI8NH49KU22tQ1umij4EIf5tzLh4gsqkJmy6QLrlbf10m6UF4rLFQhKzOd4b2H2K6KbP00CIymvbW3BwvNDODM4xRE2uao387qfvXZBUkB0PpRD+7fWPoN58gpFUm407Eba3WwX5PCD+1DD+RVBsG8maIDXerQ7lvFLoSuyMswv1TfkvCj0ZFhSFbfTd2ZysCu6eryFfeixR7NY9SNcp9YTqG6LrxGA7Ci6wz+hycFHXlDrlBgfFJDe5At',
    key_id   => 'clark@work',
    old_keys => [
      'boylandcl@boylancl1',
      ],
    uid      => 2005,
    gid      => 2005,
  }

  @user::virtual::localuser { 'rlane':
    realname => 'Ryan Lane',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCdtI7H+fsgSrjrdG8aGVcrN0GFW3XqLVsLG4n7JW4qH2W//hqgdL7A7cNVQNPoB9I1jAqvnO2Ct6wrVSh84QU89Uufw412M3qNSNeiGgv2c2KdxP2XBrnsLYAaJRbgOWJX7nty1jpO0xwF503ky2W3OMUsCXMAbYmYNSod6gAdzf5Xgo/3+eXRh7NbV1eKPrzwWoMOYh9T0Mvmokon/GXV5PiAA2bIaQvCy4BH/BzWiQwRM7KtiEt5lHahY172aEu+dcWxciuxHqkYqlKhbU+x1fwZJ+MpXSj5KBU+L0yf3iKySob7g6DZDST/Ylcm4MMjpOy8/9Cc6Xgpx77E/Pvd',
    key_id   => 'laner@Free-Public-Wifi.local',
    uid      => 2006,
    gid      => 2006,
  }

  @user::virtual::localuser { 'fungi':
    realname => 'Jeremy Stanley',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQD3KnRBTH5QPpKjf4RWu4akzYt2gwp796cMkFl5vu8e7G/cHuh4979FeNJXMVP6F3rvZB+yXDHLCU5LBVLq0K+1GbAZT/hH38hpMOIvniwKIquvI6C/drkVPHO6YmVlapw/NI530PGnT/TAqCOycHBO5eF1bYsaqV1yZqvs9v7UZc6J4LukoLZwpmyWZ5P3ltAiiy8+FGq3SLCKWDMmv/Bjz4zTsaNbSWThJi0BydINjC1/0ze5Tyc/XgW1sDuxmmXJxgQp4EvLpronqb2hT60iA52kj8lrmoCIryRpgnbaRA7BrxKF8zIr0ZALHijxEUeWHhFJDIVRGUf0Ef0nrmBv',
    key_id   => 'fungi-openstack-2015',
    old_keys => [
      'fungi-openstack-2012',
      'fungi-openstack-2013',
      'fungi-openstack-2014',
      ],
    uid      => 2007,
    gid      => 2007,
  }

  @user::virtual::localuser { 'ttx':
    realname => 'Thierry Carrez',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDCGpMtSehQNZL0/EJ7VUbklJygsxvii2Qi4HPSUFcLJUWAx4VltsmPkmx43D9ITwnRPRMPNtZrOvhY7v0myVlFuRnyTYAqZwigf5gxrktb+4PwCWb+2XobziUVnfJlbOTjneWSTYoZ+OjTaWd5AcVbUvgYAP2qbddycc5ACswpPDo5VrS6fQfCwE4z3BqLFNeOnqxbECHwHeFYIR6Kd6mnKAzDNZxZIkviWg9eIwwuFf5V5bUPiVkeFHVL3EJlCoYs2Em4bvYZBtrV7kUseN85X/+5Uail4uYBEcB3GLL32e6HeD1Qk4xIxLTI2bFPGUp0Oq7iPgrQQe4zCBsGi7Dx+JVy+U0JqLLAN94UPCn2fhsX7PdKfTPcxFPFKeX/PRutkb7qxdbS2ubCdOEhc6WN7OkQmbdK8lk6ms4v4dFc0ooMepWELqKC6thICsVdizpuij0+h8c4SRD3gtwGDPxrkJcodPoAimVVlW1p+RpMxsCFrK473TzgeNPVeAdSZVpqZ865VOwFqoFQB6WpmCDZQPFlkS2VDe9R54ePDHWKYLvVW6yvQqWTx3KrIrS1twSoydj+gADgBYsZaW5MNkWYHAWotEX67j6fMZ6ZSTS5yaTeLywB2Ykh0kjo4jpTFk5JNL7DINkfmCEZMLw60da29iN4QzAJr9cP1bwjf/QDqw==',
    key_id   => 'ttx@mercury',
    uid      => 2008,
    gid      => 2008,
  }

  @user::virtual::localuser { 'rbryant':
    realname => 'Russell Bryant',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDZVikFz5KoRg3gKdiSa3PQ0i2bN5+bUyc4lMMg6P+jEStVddwN+nAgpa3zJaokmNAOp+MjcGa7K1Zi4b9Fe2ufusTzSKdNVlRDiw0R4Lk0LwTIfkhLywKvgcAz8hkqWPUIgTMU4xIizh50KTL9Ttsu9ULop8t7urTpPE4TthHX4nz1Y9NwYLU0W8cWhzgRonBbqtGs/Lif0NC+TdWGkVyTaP3x1A48s0SMPcZKln1hDv7KbKdknG4XyS4jlr4qI+R+har7m2ED/PH93PSXi5QnT4U6laWRg03HTxpPKWq077u/tPW9wcbkgpBcYMmDKTo/NDPtoN+r/jkbdW7zKJHx',
    key_id   => 'russel@russelbryant.net',
    uid      => 2009,
    gid      => 2009,
  }

  @user::virtual::localuser { 'pabelanger':
    realname => 'Paul Belanger',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQCuP0CZE8AYnbm8gxecCxKeRw0wHRyryd+FKmNNsdr0d3UvfCbqNzLigrqEBZsKpofi3M4qCWNpKRyfhnjPynLTQjP1vnX9AbL9UGoiHxScfvh3skntTYMs9ezJRd0rMJJZO76FPo8bJLDlwxAQl8m/nuj3HfYiO5hYE7P+a3rhsJh4nEfBb7xh+Q5yM0PWObkkBl6IRiBYjlcsXNZHgTA5kNuihUk5bHqAw54sHh05DhpgOITpTw4LFbh4Ew2NKq49dEb2xbTuAyAr2DHNOGgIwKEZpwtKZEIGEuiLbb4DQRsfivrvyOjnK2NFjQzGyNOHfsOldWHRQwUKUs8nrxKdXvqcrfMnSVaibeYK2TRL+6jd9kc5SIhWI3XLm7HbX7uXMD7/JQrkL25Rcs6nndDCH72DJLz+ynA/T5umMbNBQ9tybL5z73IOpfShRGjQYego22CxDOy7e/5OEMHNoksbFb1S02viM9O2puS7LDqqfT9JIbbPqCrbRi/zOXo0f4EXo6xKUAmd8qlV+6f/p57/qFihzQDaRFVlFEH3k7qwsw7PYGUTwkPaThe6xyZN6D5jqxCZU3aSYu+FGb0oYo+M5IxOm0Cb4NNsvvkRPxWtwSayfFGu6+m/+/RyA3GBcAMev7AuyKN+K2vGMsLagHOx4i+5ZAcUwGzLeXAENNum3w==',
    key_id   => 'pabelanger@redhat.com',
    uid      => 2010,
    gid      => 2010,
  }

  @user::virtual::localuser { 'mkiss':
    realname => 'Marton Kiss',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCb5qdaiKaRqBRgLW8Df+zD3C4a+gO/GFZYEDEd5nvk+LDGPuzi6s639DLqdfx6yvJ1sxxNUOOYhE/T7raDeS8m8fjk0hdVzARXraYDbckt6AELl7B16ZM4aEzjAPoSByizmfwIVkO1zP6kghyumV1kr5Nqx0hTd5/thIzgwdaGBY4I+5iqcWncuLyBCs34oTh/S+QFzjmMgoT86PrdLSsBIINx/4rb2Br2Sb6pRHmzbU+3evnytdlDFwDUPfdzoCaQEdXtjISC0xBdmnjEvHJYgmSkWMZGgRgomrA06Al9M9+2PR7x+burLVVsZf9keRoC7RYLAcryRbGMExC17skL',
    key_id   => 'marton.kiss@gmail.com',
    uid      => 2011,
    gid      => 2011,
  }

  @user::virtual::localuser { 'smarcet':
    realname => 'Sebastian Marcet',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDP5ce0Ywtbgi3LGMZWA5Zlv/EQ07F/gWnZOMN6TRfiCiiBNyf8ARtKgmYSINS8W537HJYBt3qTfa5xkZmpBrtE6x8OTfR5y1L+x/PrLTUkQhVDY19EixD9wDIrQIIjo2ZVq+zErXBRQuGmJ3Hl+OGw+wtvGS8f768kMnwhKUgyITjWV2tKr/q88J8mBOep48XUcRhidDWsOjgIDJQeY2lbsx1bbZ7necrJS17PHqxhUbWntyR/VKKbBbrNmf2bhtTRUSYoJuqabyGDTZ0J25A88Qt2IKELy6jsVTxHj9Y5D8oH57uB7GaNsNiU+CaOcVfwOenES9mcWOr1t5zNOdrp',
    key_id   => 'smarcet@gmail.com',
    uid      => 2012,
    gid      => 2012,
  }

  @user::virtual::localuser { 'zaro':
    realname => 'Khai Do',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDJqB//ilMx7Y1tKzviAn/6yeXSRAi2VnaGN0/bfaa5Gciz+SWt8vAEAUE99fzuqeJ/ezjkuIXDFm/sjZr93y567a6sDT6CuhVUac1FZIhXRTs0J+pBOiENbwQ7RZxbkyNHQ0ndvtz3kBA1DF5D+MDkluBlIWb085Z31rFJmetsB2Zb8s1FKUjHVk/skyeKSj0qAK5KN3Wme6peWhYjwBiM0gUlxIsEZM6JLYdoPIbD5B8GYAktMN2FvJU9LgKGL93jLZ/vnMtoQIHHAG/85NdPURL1Zbi92Xlxbm4LkbcHnruBdmtPfSgaEupwJ+zFmK264OHD7QFt10ztPMbAFCFn',
    key_id   => 'khaido@khaido-HP-EliteBook-Folio-9470m',
    uid      => 2013,
    gid      => 2013,
  }

  @user::virtual::localuser { 'slukjanov':
    realname => 'Sergey Lukjanov',
    sshkeys  => '',
    uid      => 2014,
    gid      => 2014,
  }

  @user::virtual::localuser { 'elizabeth':
    realname => 'Elizabeth K. Joseph',
    sshkeys  => '',
    uid      => 2015,
    gid      => 2015,
  }

  @user::virtual::localuser { 'jhesketh':
    realname => 'Joshua Hesketh',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQC3onVLOZiiGpQWTCIV0QwHmc3Jvqyl7UaJxIu7D49OQcLHqVZsozI9pSiCdTnWyAaM+E+5wD9yVcSTqMWqn2AZmZSwQ+Fh6KnCgPZ/o63+iCZPGL0RNk20M1iNh5dvdStDnn+j2fpeV/JONF0tBn07QvNL2eF4BwtbTG9Zhl186QNsXjXDghrSO3Etl6DSfcUhxyvMoA2LnclWWD5hLmiRhcBm+PIxveVsr4B+o0k1HV5SUOvJMWtbEC37AH5I818O4fNOob6CnOFaCsbA9oUDzB5rqxutPZb9SmNJpNoLqYqDgyppM0yeql0Kn97tUt7H4j5xHrWoGnJ4IXfuDc0AMmmy4fpcLGkNf7zcBftKS6iz/3AlOXjlp5WZvKxngJj9HIir2SE/qV4Lxw9936BzvAcQyw5+bEsLQJwi+LPZxEqLC6oklkX9dg/+1yBFHsz6mulA0b4Eq7VF9omRzrhhN4iPpU5KQYPRNz7yRYckXDxYnp2lz6yHgSYh2/lqMc+UqmCL9EAWcDw3jsgvJ6kH/YUVUojiRHD9QLqlhOusu1wrTfojjwF05mqkXKmH+LH8f8AJAlMdYg0c2WLlrcxnwCkLLxzU5cYmKcZ41LuLtQR3ik+EKjYzBXXyCEzFm6qQEbR2akpXyxvONgrf7pijrgNOi0GeatUt0bUQcAONYw==',
    key_id   => 'jhesketh@infra',
    uid      => 2016,
    gid      => 2016,
  }

  @user::virtual::localuser { 'nibz':
    realname => 'Spencer Krum',
    sshkeys  => '',
    uid      => 2017,
    gid      => 2017,
  }

  @user::virtual::localuser { 'yolanda':
    realname => 'Yolanda Robla',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDSR2NmJC8PSanHUpKJuaMmohG80COO2IPkE3Mxhr7US8P1B3p1c6lOrT6M1txRzBY8FlbxfOinGtutP+ADCB2taXfpO8UiaG9eOqojAT/PeP2Y2ov72rVMSWupLozUv2uAR5yyFVFHOjKPYGAa01aJtfzfJujSak8dM0ifFeFwgp/8RBGEfC7atq+45TdrfAURRcEgcOLiF5Aq6fprCOwpllnrH6VoId9YS7u/5xF2/zBjr9PuOP7jEgCaL/+FNqu7jgj87aG5jiZPlweb7GTLJON9H6eFpyfpoJE0sZ1yR9Q+e9FAqQIA44Zi748qKBlFKbLxzoC4mc0SbNUAleEL',
    key_id   => 'yolanda@infra',
    uid      => 2018,
    gid      => 2018,
  }

  @user::virtual::localuser { 'rcarrillocruz':
    realname => 'Ricardo Carrillo Cruz',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQCz1CW5E87v8o7O8B5fe7j1uaPCToRdaBukjH2HzQZ+DSGTIPjirLpp5ZXPuyNnmtRMzwld6mlHYlevVEwuZTNyQwS7ut5o0LjyW6yoEcvPq0xMEZLxaso5dZAtzNgf3FzbtaUYBnkhSwX7c24lf8wPGAl7TC3yO0dePQh2lXVdaBiGB9ybVeQr+kwJIxleUE4puuQ+ONJE2D+hHjoQ/huUMpb996pb/YzkjkAxqHguMid0c1taelyW8n17nEDoWvlV9Qqbo8cerhgURo1OBt2zENLjQQ0kOkPxJx4qx3652e0kbkr11y50r9BMs418mnJdWselMxkSqQNZ+XotoH5Dwn+3K2a6Wv4OX3Dqb9SF/JTD7lA/tIkNfxgsRlzfEQ01rK1+g7Je10EnDCLEzHpFjvZ5q4EEMcYqY+osLFpHAOWGLMx+3eY4pz/xEzRP/x3sjGU09uNOZ3oCWUfSkE4xebnnWtxwWZKyFmv3GHtaqJn2UvpAbODPEYyYcOS3XV3zd233W3C09YYnFUyZbGLXpD05Yet5fZfGTnveMRn5/9LZai+dBPwoMWUJdX4yPnGXgOG8zk0u1nWfcNJfYg+xajSUDiMKjDhlkuFK/GXNYuINe42s1TxzL7pJ4X4UhqLiopeJvPg/U5xdCV5pxVKf1MVenrGe2pfwf1Yr2WMv5w==',
    key_id   => 'rcarrillocruz@infra',
    uid      => 2019,
    gid      => 2019,
  }

  @user::virtual::localuser { 'krotscheck':
    realname => 'Michael Krotscheck',
    sshkeys  => '',
    uid      => 2020,
    gid      => 2020,
  }

  @user::virtual::localuser { 'colleen':
    realname => 'Colleen Murphy',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDcHzySqYlH1TfAPx5PaVzqkuMbI3zksJ5E2aZBlsIN7wNSoyO0Dts6HegHZIgi5NGT05wRBAUMCNZwupqFoWDg41JBKzPKITkqvEe/FnNmJFxt591ltXigZZ+ZLoX8B12nww/eeA5nx9PT4hIsLQG50MxEm0iC4ApusaAXMXa7+gTDkzf6yyl4QwinyFFTYtyJwFw5XfQXXRQwL8Qv6mVGrhDz3Fj4VWawByQuxRHgt5G3Ux/PnZzatJ3tuSK66o1uXrvuOiGdUtDCuAFUx+kgcmUTpCC6vgMZdDbrfyw0CGxkmAUNfeEMOw0TWbdioJ2FwH5+4BEvMgiFgsCTjIwDqqyFV9eK8sd0mbJ+I82EyOXPlFPKGan6Ie6LD1qotdUW9vT3pfpR/44s/Id2un3FBnVg7GZkGJshikGO1UqjmZfhEpQ6Q+auLir+mBv2X/ril6qJ2NuQpwMRVzZmriPMxdJDs6xhzg2fGEYRvEvh0kzsqNf4OgKbSWiVOB3WALM30Cx3YdmnB6JonRGA+6CqD+LO4HQMbD7LBVcYzEIS1WtP8aPx/NiybemrF0LWmIgl34A0Tpcc+5MLzzUtgUt6lYFyWxltCP43u1N7ODH+FsFALzo6CO9DjyMxEd6Ay61hyx8Btfhn8NH/wEdCQj1WAMHU+d2ljk5ndAfp8c6LRQ==',
    key_id   => 'krinkle@gir',
    uid      => 2021,
    gid      => 2021,
  }

  @user::virtual::localuser { 'Zara':
    realname => 'Zara Zaimeche',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCt9wQvGgQIvLvifm7n5g+2sjgjGCQLt03D0v5Fb5xEMufJncIDkwBNDzGvsASwHGjP9YEAA8+f8Ya+Yc9EaDgqQl9r9YEO9CoEC6O1Euk41nQJYYRnzkgmMaxTSlUKNur8XSmzoElLut6ivlLW71fZmSKHAcg9O4lgd9weDDjCcWLD1C9WmRVdtEnw6NQJd5Mn/llHqdbmMlf3I5VL8QvzPndxZEyESdSBz0ywLO5ygtUxtPaCxaanHSTz1yNooT9t2vwDnfc1LB9oT4CaEnVG+FugCPGFnn204eJ2BVEQ945ZsabgFndyvfmEwxlzAeA6+YjQYrukMijb1Owxh1fv',
    key_id   => 'zara.zaimeche@codethink.co.uk',
    uid      => 2022,
    gid      => 2022,
  }

  @user::virtual::localuser { 'SotK':
    realname => 'Adam Coldrick',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDL2oe+2lRld58OiTjpdR3yUTobWcDWaYhWpU3bWz36rQAcbtYQmCBJRF8Ec2ZazvLNrmv075k/kb18eWjBLzItorBppIlNkIazG002LsrvlME6FDrZ3MoeDiswXG8a0P0IJyUyvfald7EBkjjiCVO3CwyMdFF2fXb+oqKxrSL9nKyPZtSXAzHmq01Eqm6Jok971+C+tvk47W4w7LXy+H/1GfMJdppwIWD6fQ5NmxQp9fHowh3ztNthhEk6Vn46qGrtMru4HImIw6nVU+0tHNRgxRjn9SRTPSsYPiBKJJ90rXl7WB5Ep42hGZySdz7l0LjxXAGxZgiHso/ANPYzRgpr',
    key_id   => 'adam@arreliam',
    old_keys => [
      'adam.coldrick@codethink.co.uk',
      ],
    uid      => 2023,
    gid      => 2023,
  }

  @user::virtual::localuser { 'maxwell':
    realname => 'JP Maxwell',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA2b5I7Yff9FCrtRmSjpILUePi54Vbc8zqJTbzrIAQZGFLBi3xd2MLlhV5QVgpDBC9H3lGjbdnc81D3aFd3HwHT4dvvvyedT12PR3VDEpftdW84vw3jzdtALcayOQznjbGnScwvX5SgnRhNxuX9Rkh8qNvOsjYPUafRr9azkQoomJFkdNVI4Vb5DbLhTpt18FPeOf0UuqDt/J2tHI4SjZ3kjzr7Nbwpg8xGgANPNE0+2pJbwCA8YDt4g3bzfzvVafQs5o9Gfc9tudkR9ugQG1M+EWCgu42CleOwMTd/rYEB2fgNNPsZAWqwQfdPajVuk70EBKUEQSyoA09eEZX+xJN9Q==',
    key_id   => 'jpmaxman@tipit.net',
    uid      => 2024,
    gid      => 2024,
  }

  @user::virtual::localuser { 'ianw':
    realname => 'Ian Wienand',
    key_type => 'ssh-ed25519',
    sshkeys  => 'AAAAC3NzaC1lZDI1NTE5AAAAILOjz+dkwRWTJcW9Gt3iGHSzRBsvVlTAK6G2oH3+0D41',
    key_id   => 'iwienand+osinfra@redhat.com',
    uid      => 2025,
    gid      => 2025,
  }

  @user::virtual::localuser { 'shrews':
    realname => 'David Shrewsbury',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCdzEzB2KpNLTTFJGLCNMY53sja37PXFzHHdjWEGaZtaTcuCn/ufV9ql5yhS5/414u9swoHM71H00+nT4uSWcXc2tTRXYWslaiwU47DOtQsD//CvGgIFBNO1EinWhYa5uTSfxI+Z/x4PBu7XFq5wi/JCfJ+iHIWsvXn8U44r1csURcZU0GMPAVG1MO+s3p1W7daVqF9RR7UuwCECb3hdPN1N/M4s6myBiuRXCeDND98dKLf8b342hw+pWvQ3g/OCLcVlYPWT4fy1YGQT8hT+jA2XPfwCtu/k7HKAGH3E8UcnBtY/RI9ibciIFe+Ro7q8t+tp5SgjGLq1NnE4Yp5rpsh',
    key_id   => 'david@koala',
    uid      => 2026,
    gid      => 2026,
  }

  @user::virtual::localuser { 'jbryce':
    realname => 'Jonathan Bryce',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAABIwAAAQEApFGM9q1gfiawBX5EnCQGxx2T1hwPDxrX2M64MfqcoBRpdrWRjxWm6Vhczfl+Ar2EQtGsuIm1QQiyiPL4zsJSQOfYXB0TqOQaAuFamSzZSNEm8coSa93E3zfXR9uln1lgCGutaWwH/KmGcSeAuuQCipKmKxc8QSAepGNP4Jx2L/EnXQh850xTQEIviJkJpA9oTRzXu12T7vzxsUCw041Q/KX16UvvGpt9IAoMAWFlQrMPzPFmqbUOIr7pRvv8TKcK9BNFS8S8jjT+wN0y/LY7cbTblgDfwSAl1P/naME5ugRVD5MZKixIE1F+x/j+M8+fpZ/EyR/6jSA3DYjEXOk2zQ==',
    key_id   => 'jbryce@jbryce-mbp-3.local',
    uid      => 2027,
    gid      => 2027,
  }

  @user::virtual::localuser { 'dmsimard':
    realname => 'David Moreau-Simard',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDDyXfFj44OTsJZnHbecbYrwA8zXuMiULb+o326maOh3wh5/6fk+MzivkUzJC2uZqAlKvBnNXsrb/07eV1gRjaIQBQJxaV9HQUwMNX7AkjkDzaMXVDjG/JOium90R23gVGMukzp9IamezUscAqAxVK+2C10k3tq8dZ/GeZfHl3NFGRHlIAXsJ/SIQoxJAEA0IQ/8Y50nR1Hp2mV2xsfxH9oZhLR/eiFdhJpNupdfw/oE9+vpCHS8SG88KGeLYbn+EhH6LSCD+6WNthF6oE7NANnScqn1Fl0ZpSd3RlRb+kDVKGqNxfB7EJTeimYvqaYmrTiTZTaTJua5Bj5yBTudqnBgdHCz3xMb2Nv2s2INNcJmP/CKpivYQ8AJs6cVlqRWnLJiNQQYCj+xAXBvY5T0Xq/qOhVifLiWZvZQOTHFWqFP9asZkrGa1mFWIaR9VPQY0FoYlUOT9t6J6TRbzktJIuP5AiOVoJLL6wjZuUMjghHfkYbqtyBqE4BbCY8YF3JSf8jx+9eWy+sD+dRwKXBCrGV0dNidioZR7ZJpBb6ye8wElebjPZizKhppsNpwtRxPfiAM52f55lXGD7IDpz9CZrOKUcV2uc3Rhl50u7T3psZfX7GysZvlnAH+Yr+UM+LPBAabXAfKlMnJp+SskLuOplTeQrvAwMluBmFnla8TnwnxQ==',
    key_id   => 'dmsimard@hostname',
    uid      => 2028,
    gid      => 2028,
  }

  @user::virtual::localuser { 'frickler':
    realname => 'Jens Harbott',
    key_type => 'ssh-ed25519',
    sshkeys  => 'AAAAC3NzaC1lZDI1NTE5AAAAIGmc5fbzMptjAb5D86zSH13ZYCbf3QuV1jk9hL0r1qHw',
    key_id   => 'frickler@os-infra-2017',
    uid      => 2029,
    gid      => 2029,
  }

  @user::virtual::localuser { 'andymccr':
    realname => 'Andy McCrae',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDG/3cDOPknMabZaO2amysoe+rU0Yc1iVE2ZUR+p4IRv98tVRL37rf9y2JCNFDwk3iNzih7XJn8MJOHSG8MJZ6OvsBGT437IkArEwLb7pZvaJhQSiQ4othd6jct6ZQ99OO9UFkxGE5wQO1bUxdGyxjfRWDs4TrxS6hj0nLTnl+Ee+HLNsqRtVoUEfazsfDQhHOX/tKCFgKi/1zwk0NGsXFGzvuE47dXnEehdYSiSqpMNVtElzopTnI7xcgV+ZX8g3+kFxIGrS1tUH7DE2pTLo0H0J7DfwOLP6TiWUEPXd4ri9knljfhd1r6rQyqDkU/3I5iiXAl/5fpcgKLTFoxiIe6Tf+uhQOcr4xr+QVMQozW6IDkC8VYbm0/r3h+YU6alouuRfI5DAtdzY0HUUzemCCr33cOAp0wIkW257C6ch2mXq8qxr2QLMu9MWNQs2/Dbr1hNsPw3C/apQCnyNPh7tjYIuysjmbFU8pkzlNIq9258GkfgST6wEQ9HsaPpi3GscQ1lo8j6fdI75lvo+vCD+mis2liCGZDil8f0HM6kLX6kKQmVDkhjxcfrfqhCrE1/Q+yAfF4zECZUqlPh/SY/lS1wvRZZGyeBpOVq5/M1qTGjC7uQc9gH3nibp0lzjUFKYoMxqIHwmSBSHlE9tnkHhCrLKvaD9MNPVUT7OelvhCvLQ',
    key_id   => 'andy@andy.mc.it',
    uid      => 2030,
    gid      => 2030,
  }

  @user::virtual::localuser { 'eumel8':
    realname => 'Frank Kloeker',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAv+XM4O3w/R8Pok1Kfm2RESduUmvSNils5KOXzWWb9kNitndxj1jWPWaMi1did+kEuClzKaiR1cHi6K3KeJd2LuEkqo0Ky4w7AbItTUFS8T0IWOODe9aQBMO4Y2ALNwtj5MObN0oJ/NaV8x2Kz2gc1MVCj8hgMiG19hqi1mz1ZDhA02kOYfME8AeW3YvwWijyjOvQF3lz0TVGhAqe/0UrJk5+HCYyHIUjRJqDM8XK1diC3IFdXgn/95YrVYmOLKEOWW6ZvYi6/gE2mHTvToBHuHUvMVqROwdUB+l7k5rpXjN9Wm/l16K0iyMdt/Emd43qz9gx1NRnOJdq4dMCik3k6w',
    key_id   => 'eumel@arcor.de',
    uid      => 2031,
    gid      => 2031,
  }
}
