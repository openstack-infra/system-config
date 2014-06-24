
testr list-tests tempest.api.network.test_networks tempest.api.network.test_security_groups tempest.api.network.test_floating_ips tempest.api.network.test_routers  tempest.api.network.test_ports | grep -v "ExtendedAttrs\|snat\|extra_route\|router_set_gateway\|router_unset_gateway" > tests.txt 

testr run --subunit --load-list tests.txt > subunit.log
/usr/local/bin/subunit2html subunit.log 

