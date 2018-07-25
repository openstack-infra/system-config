$services = [
  'germqtt',
  'lpmqtt',
  'statsd_mqtt'
]
service { $services:
  ensure => running
}
