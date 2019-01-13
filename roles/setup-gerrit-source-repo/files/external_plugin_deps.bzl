load(":delete-project/external_plugin_deps.bzl", my_plugin="delete_project_plugin_deps")
load(":javamelody/external_plugin_deps.bzl", my_other_plugin="javamelody_plugin_deps")

def external_plugin_deps():
  delete_project_plugin_deps()
  javamelody_plugin_deps()
