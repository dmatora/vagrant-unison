# 1.0.2 (Feb 2016)
* fix the cleanup command to delete contents of directory in Vagrant but not the directory itself, because deleteing the directory can mess up e.g. a docker container that has that directory mounted.

# 1.0.1
* Small bugfix release

# 1.0.0 (Jan 2016)

* Breaking commit on dcosson fork
* Renames all of the `vagrant ___` commands to start with `unison`, e.g. `vagrant-unison-sync`
* Adds a command to sync once and exit, `vagrant unison-sync-once`
* Fix bug where cleanup tried to delete `~/.unison` as root, which resolved to wrong thing (at least in Virtualbox) and failed silently bc what we want to delete is `/home/vagrant/.unison`
* Pin to newer syntax of the listen gem and stop using a method that had been renamed.

# 0.0.17 (Jan 2016)

* Fix bug in validation. Previously, you couldn't run vagrant on a Vagrantfile that didn't use vagrant-unison if you had the plugin installed, because all the config args were required.

# 0.1.0 (March 2013)

* Initial release.
