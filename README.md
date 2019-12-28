pimatic-tradfri
=======================


[![build status](https://img.shields.io/travis/treban/pimatic-tradfri.svg?branch=master?style=flat-square)](https://travis-ci.org/treban/pimatic-tradfri)
[![version](https://img.shields.io/npm/v/pimatic-tradfri.svg?branch=master?style=flat-square)](https://www.npmjs.com/package/pimatic-tradfri)
[![downloads](https://img.shields.io/npm/dm/pimatic-tradfri.svg?branch=master?style=flat-square)](https://www.npmjs.com/package/pimatic-tradfri)
[![license](https://img.shields.io/github/license/treban/pimatic-tradfri.svg)](https://github.com/treban/pimatic-tradfri)

This plugin provides a tradfri interface for [pimatic](https://pimatic.org/).

IMPORTANT:
This plugin needs at least gateway version 1.2.42 !

#### Features
* Discover devices, groups, and scenes
* Tradfri Hub as presence device available
* Control lights
* Control groups
* Observe changes
* Scenes/moods per Group
* Action providers for all features
* All bulbs are supported (RGB / color temperature)

### Installation

Just activate the plugin in your pimatic config. The plugin manager automatically installs the package with his dependencies.

### Software dependencies

This plugin depends on tradfri-coapdtls.

### Configuration

You can load the plugin by adding following in the "plugins" section in config.json from your pimatic server:

You only need the security id which is backside of the gateway (i.e. Security Code) and the gateway's IP address. At startup the plugin discovers the gateway.

    {
      "plugin": "tradfri",
      "secID": "GATEWAY KEY",
      "hubIP": "GATEWAY IP"
    }

Configuration after discovery.

    {
      "plugin": "tradfri",
      "secID": "GATEWAY KEY",
      "hubIP": "GATEWAY IP",
      "identity": "",
      "psk": "",
      "debug": true
    }

### Usages

Install the tradfri gateway in your network and make an normal initialization over
the trafri smartphone app. If wanted with groups.

After the lights are paired with the gateway, go to the pimatic screen and
make an autodiscover.

### Actions

set color temp \<dev> to \<colortemperature>   (0-100)  
set color rgb \<dev> to \<#0011ff>   (rgb value in hex with leading hash )  

Note that you can also use the standard pimatic actions for dimmers, sensors and switches.  
See https://pimatic.org/guide/usage/rules/ for examples.

Example:
dim \<dev> to \<dimpercentage>

### NOTES

The first connection to the gateway creates a session key.
This key with a uniq identifier is automatically stored in the configuration file.
If you have problems with your connection,
remove the psk from the config.

Sometimes the Tradfri Gatway doesn't inform the observers about new devices states.
I think that the stability of the gateway in newer firmware versions is improved.

If you press the power button of the 5-button remote, the remote toggles the group.
So if the lights are not syncron, the lights will change the state not in same way.

### ToDoList
* firmware updates

### ChangeLog

[-> see CHANGELOG](https://github.com/treban/pimatic-tradfri/blob/master/CHANGELOG.md)
----------------------------
#### Credits

* [cklam2](https://github.com/cklam2)
* [sverrevh](https://github.com/sverrevh)
* [sweebee](https://github.com/sweebee)
* [thexperiments](https://github.com/thexperiments)
