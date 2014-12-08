# Define: solr
#
# This define represents a single core (a separate index) of Apache Solr
# instance.
#
# Parameters:
#   - $schema_conf_template defines the schema.xml template.
#   - $solr_conf_template represents the solrconfig.xml configuration.
#   - $protwords_template: template file for protwords.txt
#   - $stopwords_template: template file for stopwords.txt
#   - $stopwords_en_template: template file for stopwords_en.txt
#   - $synonyms_template: template file for synonyms.txt
#
define solr::core (
  $schema_conf_template = 'solr/core.schema.xml.erb',
  $solr_conf_template = 'solr/core.solrconfig.xml.erb',
  $protwords_template = 'solr/protwords.txt.erb',
  $stopwords_template = 'solr/stopwords.txt.erb',
  $stopwords_en_template = 'solr/stopwords_en.txt.erb',
  $synonyms_template = 'solr/synonyms.txt.erb',
) {
  file { "/etc/solr/${name}":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { "/etc/solr/${name}/conf":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["/etc/solr/${name}"],
  }

  file { "/srv/solr-data/${name}":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/srv/solr-data'],
  }

  if ($schema_conf_template != '') {
    file { "/etc/solr/${name}/conf/schema.xml":
      ensure  => present,
      content => template($schema_conf_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File["/etc/solr/${name}/conf"],
      notify  => Service['solr'],
    }
  }

  if ($solr_conf_template != '') {
    file { "/etc/solr/${name}/conf/solrconfig.xml":
      ensure  => present,
      content => template($solr_conf_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File["/etc/solr/${name}/conf"],
      notify  => Service['solr'],
    }
  }

  if ($protwords_template != '') {
    file { "/etc/solr/${name}/conf/protwords.txt":
      ensure  => present,
      content => template($protwords_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File["/etc/solr/${name}/conf"],
      notify  => Service['solr'],
    }
  }

  if ($stopwords_template != '') {
    file { "/etc/solr/${name}/conf/stopwords.txt":
      ensure  => present,
      content => template($stopwords_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File["/etc/solr/${name}/conf"],
      notify  => Service['solr'],
    }
  }

  if ($stopwords_en_template != '') {
    file { "/etc/solr/${name}/conf/stopwords_en.txt":
      ensure  => present,
      content => template($stopwords_en_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File["/etc/solr/${name}/conf"],
      notify  => Service['solr'],
    }
  }

  if ($synonyms_template != '') {
    file { "/etc/solr/${name}/conf/synonyms.txt":
      ensure  => present,
      content => template($synonyms_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File["/etc/solr/${name}/conf"],
      notify  => Service['solr'],
    }
  }

  concat::fragment { "solrxml-core-fragment-${name}":
    target  => '/etc/solr/solr.xml',
    content => "<core name=\"${name}\" instanceDir=\"${name}\"><property name=\"dataDir\" value=\"/srv/solr-data/${name}\" /></core>\n",
    order   => '10',
  }
}