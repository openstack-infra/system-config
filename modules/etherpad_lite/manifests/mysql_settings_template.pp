# Copy this file to etherpad_lite/manifests/mysql_settings.pp and update the
# variables below with your mysql specifics.

class etherpad_lite::mysql_settings (
  $rootuser   = 'root',
  $rootpasswd = 'secret',
  $ep_user    = $etherpad_lite::ep_user,
  $eppasswd   = 'secret',
  $host       = 'localhost',
  $database   = 'etherpad-lite'
) {
  include etherpad_lite
}
