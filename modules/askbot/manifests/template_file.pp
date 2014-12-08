# Define: askbot::template_file
#
# Define a setup_templates file, cloned from a template
# directory.
#
# Parameters:
#   - $template_path: root directory of setup_templates.
#   - $dest_dir: destination directory of target files.
#
define askbot::template_file (
  $template_path = undef,
  $dest_dir = undef,
) {
  file { "${dest_dir}/${name}":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => "${template_path}/${name}",
  }
}