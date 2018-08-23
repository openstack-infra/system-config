Setup periodic runs of ``run_all.sh``, which runs playbooks against
bridge.o.o and all hosts.

**Role Variables**

.. zuul:rolevar:: update_cron_interval

   .. zuul:rolevar:: minute
      :default: 15

   .. zuul:rolevar:: hour
      :default: *

   .. zuul:rolevar:: day
      :default: *

   .. zuul:rolevar:: month
      :default: *

   .. zuul:rolevar:: weekday
      :default: *
