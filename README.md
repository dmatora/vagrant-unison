# Vagrant Unison Plugin

This is a [Vagrant](http://www.vagrantup.com) 1.1+ plugin that syncs files over SSH from a local folder
to your Vagrant VM (local or on AWS).  Under the covers it uses [Unison](http://www.cis.upenn.edu/~bcpierce/unison/)

**NOTE:** This plugin requires Vagrant 1.1+,

## Features

* Unisoned folder support via `unison` over `ssh` -> will work with any vagrant provider, eg Virtualbox or AWS.

## Usage

1. You must already have [Unison](http://www.cis.upenn.edu/~bcpierce/unison/) installed and in your path.
     * On Mac you can install this with Homebrew:  `brew install unison` (on Yosemite you will have to use https://rudix-mountainlion.googlecode.com/files/unison-2.40.102-0.pkg)
     * On Unix (Ubuntu) install using `sudo apt-get install unison`
     * On Windows, download [2.40.102](http://alan.petitepomme.net/unison/assets/Unison-2.40.102.zip), unzip, rename `Unison-2.40.102 Text.exe` to `unison.exe` and copy to somewhere in your path.
1. Install using standard Vagrant 1.1+ plugin installation methods. 
```
$ vagrant plugin install vagrant-unison
```
1. After installing, edit your Vagrantfile and add a configuration directive similar to the below:
```
Vagrant.configure("2") do |config|
  config.vm.box = "dummy"

  config.unison.host_folder = "src/"  #relative to the folder your Vagrantfile is in
  config.unison.guest_folder = "src/" #relative to the vagrant home folder -> /home/vagrant
  config.unison.ignore = "Name {.DS_Store,.git,node_modules}"

end
```
1. Start up your starting your vagrant box as normal (eg: `vagrant up`)

## Start syncing Folders

Run `vagrant unison-sync-once` to run a single, non-interactive sync and then exit.

Run `vagrant unison-sync` to sync then start watching the local_folder for changes, and syncing these to your vagrang VM.

Under the covers this uses your system installation of [Unison](http://www.cis.upenn.edu/~bcpierce/unison/), 
which must be installed in your path.

## Start syncing Folders with polling (unison repeat mode)

Run `vagrant unison-sync-polling` to start in bidirect monitor (repeat) mode - every second unison checks for changes on either side and syncs them.

## Sync in interactive mode

Run `vagrant unison-sync-interactive` to start in interactive mode. The first time
it will ask what to do for every top-level file & directory, otherwise is asks
about changes. It allows solving conflicts in various ways. Press "?" in
interactive mode to see options for resolving.

This is a useful tool when the automatic sync sees a change in a file on both
sides and skips it.

## Cleanup unison database
When you get
```
Fatal error: Warning: inconsistent state.  
The archive file is missing on some hosts.
For safety, the remaining copies should be deleted.
  Archive arb126d8de1ef26a835b94cf51975c530f on host blablabla.local should be DELETED
  Archive arbc6a36f85b3d1473c55565dd220acf68 on host blablabla is MISSING
Please delete archive files as appropriate and try again
or invoke Unison with -ignorearchives flag.
```

Run `vagrant unison-cleanup` to clear Archive from ~/Library/Application Support/Unison/ and files from host folder.
Running Unison with -ignorearchives flag is a bad idea, since it will produce conflicts.

## Development

To work on the `vagrant-unison` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

```
$ bundle
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
that uses it, and uses bundler to execute Vagrant:

```
$ bundle exec vagrant up 
$ bundle exec vagrant unison-sync
```

Or, install the plugin from your local build to use with an existing project's
Vagrantfile on your machine.

Build the plugin with

```
rake build
```

Now you'll see the built gem in a pkg directory. Install it with

```
vagrant plugin install pkg/vagrant-unison-VERSION.gem
```
