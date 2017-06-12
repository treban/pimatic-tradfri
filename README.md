pimatic-tradfri
=======================

> **beta stadium !**
> Use it with care

This plugin provides an tradfri interface for [pimatic](https://pimatic.org/).


####Features
* Discover devices and groups
* Tradfri Hub as presence device available
* Control lights (also with temperature)
* Control groups
* observe changes
* autoreconnect on errors

###Installation

Just activate the plugin in your pimatic config. The plugin manager automatically installs the package with his dependencys.

###Software dependencies

This plugin depends on tradfri-coapdtls.

###Configuration

You can load the plugin by adding following in the config.json from your pimatic server:

    {
      "plugin": "tradfri",
      "secID": "GATEWAY KEY",
      "hubIP": "GATEWAY IP",
      "debug": true
    }

###Usages

Install the tradfri gateway in your network and make an normal initialization over
the tradfri smartphone app. If wanted with groups.

After the lights are paired with the gateway, go to the pimatic screen and
make an autodiscover.

###NOTES

Sometimes the Tradfri Gatway doesn't inform the observers about new devices states.
I think the stability off the gatway will be improved in newer firmware releases.

If you press the power button of the 5-button remote, the remote toggles the group.
So if the lights are not syncron, the lights will change the state not in same way.

### ToDoList
* implement color control over slider
* detection if lights are reachable and show it on the gui
* GUI Optimization
* soft change to new color
* some action providers for some devices
* controle the gateway

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
