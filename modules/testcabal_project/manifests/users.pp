# == Class: testcabal_project::users
#
class testcabal_project::users {
  @user::virtual::localuser { 'robertc':
    realname => 'Robert Collins',
    sshkeys  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDg/kUthl0Em5IEKGQpRYq7Yp5n1aoelJDEi5KzAvvevhCUEzlmgZI/y6cfixSC5ZJpFydZ+FlSDMiFbUwXmzHCSuEteFDtiaFpF+8E5+g7lgvjl0lJ/kWGZEGe9R00lsD9Xj0G1SZXClijS/yFDdpm9Gb2JfCUiruzW2Tu7LkOAdmAwcHw2MrZPMfuPzLFnP/aex1FfokCz+35pgi4EK98znigN5l8XyMG7/wP07WeTUY82lW6ea7bR8X8G9VH+G7iqtwftxpzT+HQJ9+CIK+y1BucGsM6uYTB3aC9bVuUMKVmHpTuLXmKTaAt4rouvGFcHmOFtd6KGqUEFcFqyCij robertc@lifelesshp\n",
  }

}
