maillist { 'legal-discuss':
    ensure      => present,
    admin       => 'stefano@openstack.org, markmc@redhat.com',
    description => 'The place to discuss legal matter, like choice of licenses',
    mailserver  => 'lists.openstack.org',
    name        => 'legal-discuss',
    password    => '1234',
    webserver   => 'lists.openstack.org',
}
