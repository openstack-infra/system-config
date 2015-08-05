define openstack_project::infracloud::rabbitmq_user(
  $password,
) {
  rabbitmq_user { $name:
    admin    => false,
    password => $password,
  }
  rabbitmq_user_permissions { "${name}@/":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }
}
