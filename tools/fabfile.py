from fabric.api import env, task
from envassert import file, process, package, user, group, port, cron  # noqa
from envassert import detect, service  # noqa

env.use_ssh_config = True
env.user = 'root'

@task
def check():
    env.platform_family = detect.detect()

    assert package.installed("emacs23-nox")
    assert service.is_enabled("unbound")

