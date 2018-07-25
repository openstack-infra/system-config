$services = [
  'germqtt',
  'lpmqtt',
  'mqtt_statsd'
]
service { $services:
  ensure => running
}
