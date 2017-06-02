pimatic-tradfri
=======================

> **alpha stadium !**

This plugin provides an tradfri interface for [pimatic](https://pimatic.org/).

You must have a tradfri ip gateway in your network.

####Features
* Discover devices
* Control lights

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
the tradfri smartphone app.

After the lights are paired with the gateway, go to the pimatic screen and
make an autodiscover.

Currently only dimming the light is possible.
Changing the colore will be the next implementation step.

### ToDoList
* implement color control
* implement observation of device changes from the tradfri remote

### ChangeLog
* 0.0.1 - alpha version
