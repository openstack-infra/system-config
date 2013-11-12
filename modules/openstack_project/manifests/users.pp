# == Class: openstack_project::users
#
class openstack_project::users {
  @user::virtual::localuser { 'mordred':
    realname => 'Monty Taylor',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyxfIpVCvZyM8BIy7r7WOSIG6Scxq4afean1Pc/bej5ZWHXCu1QnhGbI7rW3sWciEhi375ILejfODl2TkBpfdJe/DL205lLkTxAa+FUqcZ5Ymwe+jBgCH5XayzyhRPFFLn07IfA/BDAjGPqFLvq6dCEHVNJIui6oEW7OUf6a3376YF55r9bw/8Ct00F9N7zrISeSSeZXbNR+dEqcsBEKBqvZGcLtM4jzDzNXw1ITPPMGaoEIIszLpkkJcy8u/13GIrbAwNrB2wjl6Mzj+N9nTsB4rFtxRXp31ZbytCH5G9CL/mFard7yi8NLVEJPZJvAifNVhooxGN06uAiTFE8EsuQ== mtaylor@qualinost\n",
  }

  @user::virtual::localuser { 'corvus':
    realname => 'James E. Blair',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvKYcWK1T7e3PKSFiqb03EYktnoxVASpPoq2rJw2JvhsP0JfS+lKrPzpUQv7L4JCuQMsPNtZ8LnwVEft39k58Kh8XMebSfaqPYAZS5zCNvQUQIhP9myOevBZf4CDeG+gmssqRFcWEwIllfDuIzKBQGVbomR+Y5QuW0HczIbkoOYI6iyf2jB6xg+bmzR2HViofNrSa62CYmHS6dO04Z95J27w6jGWpEOTBjEQvnb9sdBc4EzaBVmxCpa2EilB1u0th7/DvuH0yP4T+X8G8UjW1gZCTOVw06fqlBCST4KjdWw1F/AuOCT7048klbf4H+mCTaEcPzzu3Fkv8ckMWtS/Z9Q== jeblair@operational-necessity\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYjpUnQYcxEgWvhuZ7Ta5G6fUU3F4dpQ3VgoimBOPG+IVM4//nZtK76c3qt6Q7zLRcIQVM3LYaPiinGp5UlsA5o9kb5c0zXZWLm8odRN75zvqr2SpHxckowr0/D7WASmbGF5QCnUHV/zoYI6sjTMqw+OcBgOKuIbfNVCTBrQ2wDoOHt2YAtZnMTEOXEJqNxK0MlwgUwOA/yNsAWTfmIORHTjmxcg8L39yfdw9cM3eblD7KnfMeqzntrWKdxuZ/2oM2Y4+mSihEx8it1rVuFh6lTO3tFsdlcfnq7BrGtfiZwtRgrTUnIhzojMafOKunz3Uvu5e0BioSO77IgwbgYs/J chrome\n",
  }

  @user::virtual::localuser { 'soren':
    realname => 'Soren Hansen',
    sshkeys  => '',
  }

  @user::virtual::localuser { 'smaffulli':
    realname => 'Stefano Maffulli',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD/zAvXaOUXCAT6/B4sCMu/38d/PyOIg/tYsYFAMgfDUzuZwkjZWNGrTpp/HFrOAZISER5KmOg48DKPvm91AeZOHfAXHCP6x9/FcogP9rmc48ym1B5XyIc78QVQjgN6JMSlEZsl0GWzFhQsPDjXundflY07TZfSC1IhpG9UgzamEVFcRjmNztnBuvq2uYVGpdI+ghmqFw9kfvSXJvUbj/F7Pco5XyJBx2e+gofe+X/UNee75xgoU/FyE2a6dSSc4uP4oUBvxDNU3gIsUKrSCmV8NuVQvMB8C9gXYR+JqtcvUSS9DdUAA8StP65woVsvuU+lqb+HVAe71JotDfOBd6f stefano@mattone-E6420\n",
  }

  @user::virtual::localuser { 'linuxjedi':
    realname => 'Andrew Hutchings',
    sshkeys  => '',
  }

  @user::virtual::localuser { 'oubiwann':
    realname => 'Duncan McGreggor',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAttca0Lahzo1rskWcCGwYh71ADmUsn/6RNBd7H7WVsX+QTacq90fpNghFNTen4I7tC1p0IemwHcCOb1noeXkjxl7W5r7l0OhiqMHp/u2ao0F3dINryuNEww2IHRhY6GwwGJ+slv+i4/FviUgqHZVzopUon/9VY0mu1wfu3vTRw0qXsvqr09Jiavt/8gJ0Fa5PsYkf7l0edFk0scTmGp3G4HY/ZvnbChfZMg6L/xcGPtK/GbLYg6PGtLVVnubXMtxD9GZYhwrY0i9Z2egcRI2W7IznM4OGFzYgA9HZqylPoWt4+ghzC5azUlbO2u6+8HigJVblAGHRWcznEf/ZDR3erw== oubiwann@rhosgobel\n",
  }

  @user::virtual::localuser { 'rockstar':
    realname => 'Paul Hummer',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDd4dPOAooCImpPulKIH82LqahC2wtQAZS/bFjNRpEILaYQMPCEpSMpjQmhcjdq+OBtsHMbqkSR+ZEoDrkhsI3Y6NVyTlGeFfwCPNNt2VeuJlKqRHUxxecp0IPWGSNl+YI5rjO5hTIZEo9T+hngX2b4k7aPm/naGcBVETMdYDZt9yhX37w5irRFdMfNDdSa3VfrhqV3Jjge/sXA5Tv35s0O6R55Ww5KfZRTpAMesHWkH9ch6xaHgexLNyCtekZQKNRLR5FCk1SYdcV+BJNlmiyjH4Ed+Oy/dFlGWPNARGwNgEWbInROEqXdWvQf+ZAfuwo32umVmmPhFrBxDYrFR1Gp rockstar@spackrace.local\n",
  }

  @user::virtual::localuser { 'clarkb':
    realname => 'Clark Boylan',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDlH6SNieyGDWNl4b9TM+zUgk+XTXRtqxyYxNh1p5e00u/ZrZPVrc7buPhnTHzEde0ABX0vgnZI2rC5Hf9cYY0aRgLHDuikQ4CQHPucslgZ5linjtWx5AuURp+oaJRCj00UZubJsatUx5vz+D4MGRLYmL+MErftYdI4sBbolATfLVwjrmxsd6KF1BZ0+9eEv2Xrk+yXN1A5RGPKBiuE6viDMZxrOuy7IW8+TQZW1LrsbTCAD1b+J5Nx0z/Hn3Rz71zEibdwM9xgu5vROu3p9kdaxu+Ndg/SvCCWlzoLQSeIAmcfGUlWg9IjEc3sQexX9BmUAsKQtu3aZFgq2V7aqtDN boylancl@boylancl1\n",
  }

  @user::virtual::localuser { 'rlane':
    realname => 'Ryan Lane',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdtI7H+fsgSrjrdG8aGVcrN0GFW3XqLVsLG4n7JW4qH2W//hqgdL7A7cNVQNPoB9I1jAqvnO2Ct6wrVSh84QU89Uufw412M3qNSNeiGgv2c2KdxP2XBrnsLYAaJRbgOWJX7nty1jpO0xwF503ky2W3OMUsCXMAbYmYNSod6gAdzf5Xgo/3+eXRh7NbV1eKPrzwWoMOYh9T0Mvmokon/GXV5PiAA2bIaQvCy4BH/BzWiQwRM7KtiEt5lHahY172aEu+dcWxciuxHqkYqlKhbU+x1fwZJ+MpXSj5KBU+L0yf3iKySob7g6DZDST/Ylcm4MMjpOy8/9Cc6Xgpx77E/Pvd laner@Free-Public-Wifi.local\n",
  }

  @user::virtual::localuser { 'fungi':
    realname => 'Jeremy Stanley',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1uFP7IuJLWZD12BJEHhakphaLfwe/rkvRJVM/JfywKuCZSXJo2HpRLw1dM8HAOlXfyrYRZ+O374rluw9RoL2KVyxWPo2Lac6XTKR4yacIgV3Mnx/j04hdHuNDZsVmONG1FDq+11pXuObYx5Of+yHDDQK35/7wDGRDv93QYhEwh8nYaW3Dol3HtqF0e4pjkAgQhjhqUk6A/+A4CQHgomQV8XkAxEdf0O37OhHZRCgTxmdgDykEZT72t3YbCXdmtnEmqEP9FzFM/CXryQ8nf9IWcfaw70bFbSgWFs12u1EeV7a3mubdy6HfC2E/OfxQnRI59CoqWVMOY8jCuTv7FdsX fungi-openstack-2013\n",
  }

  @user::virtual::localuser { 'ttx':
    realname => 'Thierry Carrez',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIF2INBeJdT3nT3+3yac+DGRQVN7wPv/GTb/OPDocQhfGMeQP7JwSURiv1nrXGbbjzuip7l7vRJs4u4NqXkUi0GFj1aLBpUm2Z1NFFDn4cuZ5KCYX6rjVrDYIpj4OlOyzt9YGONvvH/dB2GHw8kYbN50OalFWQCS0TVzj9SQbO47B/TPdtLnh116yEP5AXZZUGgl+q533/x8+nxAxJKA9iAk3mSswl67gXc4pRo84pjwpx+R/52ha6RfmLkoNAEOqtr5MGx5gyW+WXsoLJBl2bjcfzYoQI7gPWRIn+rtCnDFi762TS54zstXxR1ww+ppmqHk04l2oprNoI0wr00Fsl ttx@stardust\n",
  }

  @user::virtual::localuser { 'rbryant':
    realname => 'Russell Bryant',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZVikFz5KoRg3gKdiSa3PQ0i2bN5+bUyc4lMMg6P+jEStVddwN+nAgpa3zJaokmNAOp+MjcGa7K1Zi4b9Fe2ufusTzSKdNVlRDiw0R4Lk0LwTIfkhLywKvgcAz8hkqWPUIgTMU4xIizh50KTL9Ttsu9ULop8t7urTpPE4TthHX4nz1Y9NwYLU0W8cWhzgRonBbqtGs/Lif0NC+TdWGkVyTaP3x1A48s0SMPcZKln1hDv7KbKdknG4XyS4jlr4qI+R+har7m2ED/PH93PSXi5QnT4U6laWRg03HTxpPKWq077u/tPW9wcbkgpBcYMmDKTo/NDPtoN+r/jkbdW7zKJHx russell@russellbryant.net\n",
  }

  @user::virtual::localuser { 'pabelanger':
    realname => 'Paul Belanger',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAv0YOn34s5fMC/VTw6tn2Js/7jXqWzee9Kbf4NNJ+WiBZ7rtV0F2Jhz9OjfRdja7d8X3M01NFoufPJm5hpMEAvguxSoL0/lm44dcZ7QKT9tfmreAXIbc/2yBEMb7F+ljDldjDmR8Y6+UvTReRoO4lhvYgppH8E2Yo6g+UtS3710u5wqUwl0B5CZmT0j4FbQCMJp4KuscI6zFbuipVw8I10kXv6G/xaIWt/ZdIJRpFo9NVsDreUEeZoi6aRg2YisdzGFcJawy3OKgRh9WyZ7R+lPdvtTAqOnX6m6CS2I4LM3+xuTegiOEPzMCYY7UGx8nKNPQXzBEtGAegfQMwMP+MUQ== paul.belanger@polybeacon.com\n",
  }

  @user::virtual::localuser { 'mkiss':
    realname => 'Marton Kiss',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCb5qdaiKaRqBRgLW8Df+zD3C4a+gO/GFZYEDEd5nvk+LDGPuzi6s639DLqdfx6yvJ1sxxNUOOYhE/T7raDeS8m8fjk0hdVzARXraYDbckt6AELl7B16ZM4aEzjAPoSByizmfwIVkO1zP6kghyumV1kr5Nqx0hTd5/thIzgwdaGBY4I+5iqcWncuLyBCs34oTh/S+QFzjmMgoT86PrdLSsBIINx/4rb2Br2Sb6pRHmzbU+3evnytdlDFwDUPfdzoCaQEdXtjISC0xBdmnjEvHJYgmSkWMZGgRgomrA06Al9M9+2PR7x+burLVVsZf9keRoC7RYLAcryRbGMExC17skL marton.kiss@gmail.com\n",
  }
}
