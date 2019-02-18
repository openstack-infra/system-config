Setup periodic runs to renew openstack.org letsencrypt certificates

**Role Variables**

.. zuul:rolevar:: update_cron_interval

   .. zuul:rolevar:: minute
      :default: 0

   .. zuul:rolevar:: hour
      :default: 0

   .. zuul:rolevar:: day
      :default: *

   .. zuul:rolevar:: month
      :default: *

   .. zuul:rolevar:: weekday
      :default: *
