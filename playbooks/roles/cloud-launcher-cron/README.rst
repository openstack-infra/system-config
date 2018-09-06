Setup periodic runs of ``run_cloud_launcher.sh``, which runs the cloud setup
playbook against our clouds.

Note that this runs in an independent cron beacuse we don't need to run it
as frequently as our normal ansible runs and this ansible process needs
access to the all-clouds.yaml file which we don't run the normal ansible runs
with.

**Role Variables**

.. zuul:rolevar:: cloud_launcher_cron_interval

   .. zuul:rolevar:: minute
      :default: 0

   .. zuul:rolevar:: hour
      :default: */1

   .. zuul:rolevar:: day
      :default: *

   .. zuul:rolevar:: month
      :default: *

   .. zuul:rolevar:: weekday
      :default: *
