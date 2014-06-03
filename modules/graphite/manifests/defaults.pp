# Default values for graphite against o.o

class graphite::defaults {

  graphite::storage { 'carbon':
    pattern    => '^carbon\.',
    retentions => '60:90d',
  }
  graphite::storage { 'stats':
    pattern    => '^stats.*',
    retentions => '10:2160,60:10080,600:262974',
  }
  graphite::storage { 'default':
    pattern    => '.*',
    retentions => '60:90',
  }
}
