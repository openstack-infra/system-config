# Class: pip::jsongem
#

class pip::jsongem {

    # the pip2/3 provider requires json to be installed before it can function under puppet.
    # we use pp_gem18 so we can get the gem properly installed for puppet under gem 1.8
    package { 'json':
      ensure   => present,
      provider => pp_gem18,
    }
}
