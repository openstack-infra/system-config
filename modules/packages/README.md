puppet-packages
===============

Module to handle package management via hiera

# Usage

in a manifest:
```
  include packages::manage
```
or
```
  class { 'packages::manage': }
```
in a hiera yaml: ( if loading through hiera_include('classes') )

---
```
classes:
  - packages::manage
```
## Configuration

This module exposes several configurable options.  While you can pass
these options through a manifest, this module works best when pulling
data out of hiera.

From a manifest:
```
class { 'packages::manage':
  install_packages => [''], # an array of packages which should have
                            # state => installed.
  latest_packages  => [''], # an array of packages which should have
                            # state => latest.
  remove_packages  => [''], # an array of packages which should have
                            # state => purged.
  install_version  => [''], # a hashed array of packages to manage,
                            # see hiera details
}
```
From hiera:

----------------------------

 Please note, when using layered yaml files, you will want to make
  sure that you have the deep_merge gem installed and configured.
```
gem install deep_merge
```
## in hiera.yaml
```
:merge_behavior:
  - deeper
```
----------------------------
```
packages::install:
  - 'nano'
  - 'curl'
  - 'unzip'

packages::latest:
  - 'puppet'
  - 'hiera'

packages::versioned:
  nethack-console:
    ensure: 'purged'
```
- note, when using 'packages::versioned', you may pass any standard
  packaging parameter to the entry. for example:
```
packages::versioned
  gear:
    ensure: 'latest'
    provider: 'pip'

packages::versioned:
  deep_merge:
    ensure: 'latest'
    provider: 'gem'
```
