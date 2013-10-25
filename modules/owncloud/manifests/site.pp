# == Define: owncloud
#
define owncloud::site(

) {

  exec { 'restart apache' :
    command => 'sudo service apache2 restart',
    require => File('/etc/owncloud/config.php'),
  }  

}
