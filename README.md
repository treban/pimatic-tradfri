pimatic-tradfri
=======================

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

set color temp <dev> to <colortemperature>   (0-100)  
set color rgb <dev> to <#0011ff>   (rgb value in hex with leading hash )  

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
* controle the gateway
* firmware updates
* more actionproviders


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

* 0.1.11:
  * Remote and motion sensor as presence device with battery observation
  * BUG FIX

* 0.1.12:
  * BUG FIX (#12) (#10)
  * RGB Support
  * Dimming slider for groups

* 0.1.13:
  * BUG FIX

* 0.1.14:
  * Support for gateway version 1.2.42

* 0.1.15:
  * BUG FIX (#18)
  * compatibility warning removed

* 0.1.16:
  * BUG FIX (#19)
  * Reboot and pairing mode buttons for hub device
  * Floalt Support added
  * auto discovery of the gateway at startup

* 0.1.17:
  * Hotfix dependency bug
