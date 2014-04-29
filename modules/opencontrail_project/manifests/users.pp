# == Class: opencontrail_project::users
#
class opencontrail_project::users {
  @user::virtual::localuser { 'ci-puppetmaster.opencontrail.org':
    realname => 'Ananth Suryanarayana',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDA0UEW07Ir+zrGU8akjmuBu1nV/cQWKL3Yjq6Cfpu6511A4BzkcUVXvYz4KwwRynA1QYbNeIFOT0AL069/dgBMt5/2HqRiHGz5jZad8Qw51CKE5lt8jeSOdfhSJq2L/QhHSq+hZvo3sQpKAgBDHwB+CZAmTQGjrO/fF8fIlOm05WemjAmmcWegeKr0msxAzuwjbyQjk2Xx7AlqbjfJ69TsCwDzLwS7qoxU4nXz+NHWtY2H/9rxAE7RmvMTr+z18oaRSaJp0Fj0dzDjcBKjQpyYyjXWbaVHX0lBv1khWAIw2OofO6MO+UHef4Z/skHVlzVe8wuAZO1hnXketJaNdKo5\n",
  }
  @user::virtual::localuser { 'ubuntu':
    realname => 'Ananth Suryanarayana',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDA0UEW07Ir+zrGU8akjmuBu1nV/cQWKL3Yjq6Cfpu6511A4BzkcUVXvYz4KwwRynA1QYbNeIFOT0AL069/dgBMt5/2HqRiHGz5jZad8Qw51CKE5lt8jeSOdfhSJq2L/QhHSq+hZvo3sQpKAgBDHwB+CZAmTQGjrO/fF8fIlOm05WemjAmmcWegeKr0msxAzuwjbyQjk2Xx7AlqbjfJ69TsCwDzLwS7qoxU4nXz+NHWtY2H/9rxAE7RmvMTr+z18oaRSaJp0Fj0dzDjcBKjQpyYyjXWbaVHX0lBv1khWAIw2OofO6MO+UHef4Z/skHVlzVe8wuAZO1hnXketJaNdKo5\n",
  }
}
