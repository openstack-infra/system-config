# Definition: git::clone
# Creates a git clone of a specified origin into a top level directory
#
# Parameters:
#       $directory      -       path to clone the repository into.  Required.
#       $origin   -       Origin repository URL.
#       $branch   -       Branch you would like to check out.
#       $ensure   -       'absent', 'present', or 'latest'.  Defaults to 'present'.
#               'latest' will execute a git pull if there are any changes.
#               'absent' will ensure the directory is deleted.
#       $owner    -       owner of $directory, default: 'root'.  git commands will be run by this user.
#       $group    -       group owner of $directory, default: 'root',
#       $mode     -       permission mode of $directory, default: 0755
#       $ssh      -       SSH command/wrapper to use when checking out (optional)
#   
# Usage:
#       git::clone{ "my_clone_name": 
#         directory => "/path/to/clone/container", 
#         origin => "http://blabla.org/core.git", 
#         branch => "the_best_branch" 
#       }  # clones http://blabla.org/core.git branch 'the_best_branch' at /path/to/clone/container/core
define git::clone($directory, $origin, $branch="", $ssh="", $ensure='present', $owner="root", $group="root", $mode=0755) {

  require git::client
  
  case $ensure {
    "absent": {
      # make sure $directory does not exist
      file { $directory:
        ensure  => 'absent',
        recurse => true,
        force   => true,
      }
    }
    # otherwise clone the repository
    default: {
      # if branch was specified
      if $branch {
        $brancharg = "-b $branch "
      }
      # else don't checkout a non-default branch
      else {
        $brancharg = ""
      }
      if $ssh {
        $env = "GIT_SSH=$ssh"
      }

      # set PATH for following execs
      Exec { path => "/usr/bin:/bin" }
      # clone the repository
      exec { "git_clone_${title}":
        command     => "git clone ${brancharg}${origin} $directory",
        environment => $env,
        creates     => "$directory/.git/config",
        user  => $owner,
      }

      # pull if $ensure == latest and if there are changes to merge in.
      if $ensure == "latest" {
        exec { "git_pull_${title}":
          cwd     => $directory,
          command => "git pull --quiet",
          # git diff --quiet will exit 1 (return false) if there are differences
          unless  => "git fetch && git diff --quiet remotes/origin/HEAD",
          user    => $owner,
          require => Exec["git_clone_${title}"],
        }
      }
    }
  }
}
