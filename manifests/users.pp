class openstack_project::users {
  include user::virtual

  @user::virtual::localuser { 'mordred':
    realname => 'Monty Taylor',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyxfIpVCvZyM8BIy7r7WOSIG6Scxq4afean1Pc/bej5ZWHXCu1QnhGbI7rW3sWciEhi375ILejfODl2TkBpfdJe/DL205lLkTxAa+FUqcZ5Ymwe+jBgCH5XayzyhRPFFLn07IfA/BDAjGPqFLvq6dCEHVNJIui6oEW7OUf6a3376YF55r9bw/8Ct00F9N7zrISeSSeZXbNR+dEqcsBEKBqvZGcLtM4jzDzNXw1ITPPMGaoEIIszLpkkJcy8u/13GIrbAwNrB2wjl6Mzj+N9nTsB4rFtxRXp31ZbytCH5G9CL/mFard7yi8NLVEJPZJvAifNVhooxGN06uAiTFE8EsuQ== mtaylor@qualinost\n",
  }

  @user::virtual::localuser { 'corvus':
    realname => 'James E. Blair',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvKYcWK1T7e3PKSFiqb03EYktnoxVASpPoq2rJw2JvhsP0JfS+lKrPzpUQv7L4JCuQMsPNtZ8LnwVEft39k58Kh8XMebSfaqPYAZS5zCNvQUQIhP9myOevBZf4CDeG+gmssqRFcWEwIllfDuIzKBQGVbomR+Y5QuW0HczIbkoOYI6iyf2jB6xg+bmzR2HViofNrSa62CYmHS6dO04Z95J27w6jGWpEOTBjEQvnb9sdBc4EzaBVmxCpa2EilB1u0th7/DvuH0yP4T+X8G8UjW1gZCTOVw06fqlBCST4KjdWw1F/AuOCT7048klbf4H+mCTaEcPzzu3Fkv8ckMWtS/Z9Q== jeblair@operational-necessity\n",
  }

  @user::virtual::localuser { 'soren':
    realname => 'Soren Hansen',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA7bpJJzvwa4KKzxk9fyegkCUKKOA1gttDJdB+E2mllxcDkScYRYoFnwiq0kl1BwkNFRXj10pguhI/7O3escSvF3Di2Lw4haHR8my6yaz7jFlBbBw8+6j5RbIRnTORS5G4mH4LtAxToGomfJd9gxWpVMiqLa4V7Hg8K6CYRSSUOWzqs7Y/Hv13ASr8ZbaweB1ygVE8kbKuW2ILcqRrKYKaQDeh+aPqLsXDNhT2k2WLsTIqMTSKy70sHqyCjD2joRVBuTiqt1uaQqYCJWT8vuDvXsF0Lmi4tMjRF7GOuOKd0QsT5y8C8dLHWDfeBNQJv46dZE6UUHOfhucTM4w73zpXaw== soren@butch\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA8YfXbgi0uNZEpOxLvzPdGgo5dAAjqVUGf+kU1bvxcZf3y7a2veDXOOnez4VGl6OC1bgeENW/5O2hKi0wUG3XMWp8uLVSupI6A8o+cBCu7MYzChMdgullBEh7Bz4cbvoMmQiWOZPPsZLTTrl7E6SJJ5jTTn8IsSkCp21m2Sr4b5SWj+Nw43NVtGYFtBBG/OoixlxcNutiSn7YjOH6CAVOhKpTNddwqECKBfxCdS2kYrMzJw8/QhA9FwJHoFt3PevuC4I/9ARlyZCsbOY+ENc2NtFXNVnF5m6tE/eDZFTt652pNPlldWAaVBzKDZ4CUi4HS3WDxGcVqhtaNawIV6sR8w== soren@intel\n\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyAtAccJ8ndh6wzq3vY1izHTdPh3kAKtjBK6P390ClIRBA3CfjKS6KaKSeGs1xZ4WZhOk9oz4d/+Ep7iOXLpUnYYjHm5bLD8o6jKAhKohoABzCyj3ONPNxvxvsvdahSPLONC6H1PlbhvTbn9UwEtZ//migJTATdLQEjXHaNhNJ8UZz9XtCf1Qv4YiYmyRId6h5N+OPNU4OmqlCZyanBXKN5jK1Kubq6SseY++74Y54ZPXVccGmJDTOfNBfM1nR0+f2Mq2iHR0a3PuJcGXFx/P4mIA0Knyh98W6esB9fG7/JVID2bGpJ6c91+AkL9fmwOpfWrk7rr13+iGiH2RTcmd0w== soren@lenny\n\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCGTnV3tEMvry4UruD6I23TW3L616ML8p15kdj4TYlcBUZvUDzPoT+QjinNw7Pm1C4dJk3xJJtvxshKSXF08QF88kWgtF6jSpp1ZwmDXKNnPRLAIT5pewubFHd5iwMFf371P2/kxIm37iAo45puTO0CL39dAKkw6L/F7M3ycFUgsIkik6oN9bX1X3Yu3e/Lv2hJ1LGN7K2nnQmLd9aFulpruM7iPtFt8qJ82ofJq2LGH931QsP1QonvJxonajo9wrEAfXTFENDwcoOD0Py+KXOddqb/1SJxbLwclDmHMX5bKA5K+R6GzzpDUEsDZYa1xhJpmOmlaBTxFGoQg/wtHUNf cardno:000500000063",
  }

  @user::virtual::localuser { 'smaffulli':
    realname => 'Stefano Maffulli',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD/zAvXaOUXCAT6/B4sCMu/38d/PyOIg/tYsYFAMgfDUzuZwkjZWNGrTpp/HFrOAZISER5KmOg48DKPvm91AeZOHfAXHCP6x9/FcogP9rmc48ym1B5XyIc78QVQjgN6JMSlEZsl0GWzFhQsPDjXundflY07TZfSC1IhpG9UgzamEVFcRjmNztnBuvq2uYVGpdI+ghmqFw9kfvSXJvUbj/F7Pco5XyJBx2e+gofe+X/UNee75xgoU/FyE2a6dSSc4uP4oUBvxDNU3gIsUKrSCmV8NuVQvMB8C9gXYR+JqtcvUSS9DdUAA8StP65woVsvuU+lqb+HVAe71JotDfOBd6f stefano@mattone-E6420\n",
  }

  @user::virtual::localuser { 'linuxjedi':
    realname => 'Andrew Hutchings',
    sshkeys => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWd+45ODB7c9YbNtIc8iVYioT1sPY7Gob9bm/WiiBA0CWLdaD8TzX1htBMYJeszdvDkThhdwVt4EyJIFuSc7MEQUEfDB/VyYAOJKNOb2Q9uC+INgdigQ03gxL2sTV6loTkHXdOpCQN7CD642IctS94VGDxJhGVSrzoJvMuJJDqDuI7xl37aIRAS7Ehh+B71p4gbLKvwrXDPEZL2FnpmevFQmhnq11/U1wK0864r+FjyNiDekwDSBSqtI5Ic5VoNWuCDW74/mlKrfaylfvr5/tDp9iJYixzH2PP6X+EHU3qfWNrABBJC3RG+KcQzqD8a+r+iE5UTEG2ISqjA0j6LR6b linuxjedi@linuxjedi-laptop\n",
  }

  @user::virtual::localuser { 'jenkins':
    realname => 'OpenStack Jenkins',
    sshkeys => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtioTW2wh3mBRuj+R0Jyb/mLt5sjJ8dEvYyA8zfur1dnqEt5uQNLacW4fHBDFWJoLHfhdfbvray5wWMAcIuGEiAA2WEH23YzgIbyArCSI+z7gB3SET8zgff25ukXlN+1mBSrKWxIza+tB3NU62WbtO6hmelwvSkZ3d7SDfHxrc4zEpmHDuMhxALl8e1idqYzNA+1EhZpbcaf720mX+KD3oszmY2lqD1OkKMquRSD0USXPGlH3HK11MTeCArKRHMgTdIlVeqvYH0v0Wd1w/8mbXgHxfGzMYS1Ej0fzzJ0PC5z5rOqsMqY1X2aC1KlHIFLAeSf4Cx0JNlSpYSrlZ/RoiQ== hudson@hudson\n",
  }
}
