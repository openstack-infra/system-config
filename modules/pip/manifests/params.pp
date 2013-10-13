# Class: pip::params
#
# This class holds parameters that need to be
# accessed by other classes.
class pip::params {
  case $::osfamily {
    'RedHat': {
      $python_devel_package       = 'python-devel'
      $python_pip_package         = 'python-pip'
      $python_setuptools_package  = 'python-setuptools'
      $python3_devel_package      = 'python3-devel'
      $python3_pip_package        = 'python3-pip'
      $python3_setuptools_package = 'python3-setuptools'
      $pip_executable             = '/usr/bin/pip'
      $pip3_executable            = '/usr/bin/pip3'
      $setuptools_pth             = '/usr/local/lib/python2.7/dist-packages/setuptools.pth'
      $setuptools3_pth            = '/usr/lib/python2.7/site-packages/setuptools.pth'
    }
    'Debian': {
      $python_devel_package       = 'python-all-dev'
      $python_pip_package         = 'python-pip'
      $python_setuptools_package  = 'python-setuptools'
      $python3_devel_package      = 'python3-all-dev'
      $python3_pip_package        = 'python3-pip'
      $python3_setuptools_package = 'python3-setuptools'
      $pip_executable             = '/usr/local/bin/pip'
      $pip3_executable            = '/usr/local/bin/pip3'
      $setuptools_pth             = '/usr/local/lib/python2.7/dist-packages/setuptools.pth'
      $setuptools3_pth            = '/usr/lib/python3.3/site-packages/setuptools.pth'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'pip' module only supports osfamily Debian or RedHat.")
    }
  }
}
