# Class: solr
#
# This class installs and manages a mutli-core, single instance
# Apache Solr / Jetty.
#
# Parameters:
#   - The $solr_dist is the url where we download the solr distribution tgz.
#   - $solr_xml_path defines the solr configuration file
#
# Actions:
#   - Install Apache Solr
#
class solr (
  $solr_dist = '',
  $solr_xml_path = '/etc/solr/solr.xml',
) {

  if $solr_dist =~ /.*\/(.*)/ {
    $base_solr_dist = $1
  } else {
    $base_solr_dist = $solr_dist
  }

  $solr_tgz = '/srv/solr-releases/solr.tgz'

  package { 'openjdk-7-jre-headless':
    ensure => present,
  }

  package { 'curl':
    ensure => present,
  }

  # solr directory schema
  file { '/etc/solr':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/srv/solr':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/srv/solr-releases':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/srv/solr'],
  }

  file { '/srv/solr-data':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/srv/solr'],
  }

  # solr base configuration
  concat { $solr_xml_path:
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/solr'],
    notify  => Service['solr'],
  }

  concat::fragment { 'solrxml-header':
    target  => $solr_xml_path,
    content => template('solr/solr.xml.header.erb'),
    order   => '01',
  }

  concat::fragment { 'solrxml-footer':
    target  => $solr_xml_path,
    content => template('solr/solr.xml.footer.erb'),
    order   => '99',
  }

  # upstart script
  file { '/etc/init/solr.conf':
    ensure  => present,
    source  => 'puppet:///modules/solr/upstart.conf',
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/solr'],
  }

  # solr deployment from dist tarball
  # Download to tmp directory and move to final place when the download was ok
  # so we can avoid partial download that blocks retry of this exec.
  exec { "download:${base_solr_dist}":
    command   => "/usr/bin/curl --fail ${solr_dist} -o /tmp/${base_solr_dist}; mv /tmp/${base_solr_dist} /srv/solr-releases/${base_solr_dist}",
    creates   => "/srv/solr-releases/${base_solr_dist}",
    timeout   => 3600,
    logoutput => 'on_failure',
    require   => [ File['/srv/solr-releases'], Package['curl'] ],
  }

  file { $solr_tgz:
    ensure  => present,
    source  => "/srv/solr-releases/${base_solr_dist}",
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Exec["download:${base_solr_dist}"],
  }

  exec { 'solr-install':
    command     => "/bin/tar -xzf ${solr_tgz} --strip-components=1 --directory /srv/solr",
    subscribe   => File[$solr_tgz],
    unless      => '/usr/bin/test -f /srv/solr/bin/solr',
    logoutput   => true,
    require     => File['/srv/solr'],
  }

  # solr service
  service { 'solr':
    ensure     => running,
    name       => 'solr',
    enable     => true,
    hasrestart => true,
    subscribe  => Exec['solr-install'],
    require    => [ File['/etc/init/solr.conf'] ],
  }
}