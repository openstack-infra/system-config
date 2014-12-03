# == Defined type for openstack_project::lists class
#
define openstack_project::add_mailing_list($admin, $description) {
  maillist { $name:
    admin       => $admin,
    password    => $listpassword,
    description => $description,
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }
}
