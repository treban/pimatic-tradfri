pimatic-tradfri
=======================

> **beta stadium !**
> Use it with care

This plugin provides an tradfri interface for [pimatic](https://pimatic.org/).


#### Features
* Discover devices, groups, and scenes
* Tradfri Hub as presence device available
* Control lights (also with temperature stepless)
* Control groups
* observe changes
* scenes/moods per Group
* action providers for all features

### Installation

Just activate the plugin in your pimatic config. The plugin manager automatically installs the package with his dependencys.

### Software dependencies

This plugin depends on tradfri-coapdtls.

### Configuration

You can load the plugin by adding following in the config.json from your pimatic server:

    {
      "plugin": "tradfri",
      "secID": "GATEWAY KEY",
      "hubIP": "GATEWAY IP",
      "debug": true
    }

### Usages

Install the tradfri gateway in your network and make an normal initialization over
the trafri smartphone app. If wanted with groups.

After the lights are paired with the gateway, go to the pimatic screen and
make an autodiscover.

### NOTES

Sometimes the Tradfri Gatway doesn't inform the observers about new devices states.
I think the stability off the gatway will be improved in newer firmware releases.

If you press the power button of the 5-button remote, the remote toggles the group.
So if the lights are not syncron, the lights will change the state not in same way.

### ToDoList
* controle the gateway
* check the status of remotes and motion sensors, with battery check

### ChangeLog
* 0.1.6 - first public alpha version

* 0.1.7 - New functions:
  * Control light temperature
  * Observing changes
  * Goup function
  * Gateway check
  * Support for more lights
  * code refactoring
  * bugfixes

* 0.1.8:
  * code refactoring
  * autoreconnect
  * bugfixes

* 0.1.9:
  * Scenes/Moods
  * Stepless light temperature change
  * New device option: transition time for smooth changes
  * Action provider for all features

* 0.1.10:
  * BUG FIX
