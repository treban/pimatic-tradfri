# This is an plugin to send xmpp messages and recieve commands from the admin

module.exports = (env) ->

  TradfriCoapdtls = require 'tradfri-coapdtls'

  tradfriHub = null

  class TradfriPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      env.logger.info("pimatic-tradfri: Initialation plugin")
      secID = @config.secID
      hubIP = @config.hubIP

      env.logger.debug ("tradfri cfg: user= #{hubIP} #{secID}")

      deviceConfigDef = require("./device-config-schema.coffee")
      @framework.deviceManager.registerDeviceClass("TradfriDimmer", {
        configDef: deviceConfigDef.TradfriDimmer,
        createCallback: (config, lastState) => new TradfriDimmer(config, @, @framework, lastState)
      })

      tradfriHub = new TradfriCoapdtls ({
        securityId: secID,
        hubIpAddress: hubIP
      })

      @framework.deviceManager.on 'discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-tradfri', "scanning for tradfri devices"
        tradfriHub.getAllDeviceIDs().then( (ids)=>
          env.logger.debug (ids)
          ids.forEach((id) =>
            tradfriHub.getDevicebyID(id).then( (device) =>
              env.logger.debug (device)
              config = {
                    class: "TradfriDimmer"
              }
              config.name=device[9001]
              config.id="tradfri_#{device[9003]}"
              config.address=device[9003]
              env.logger.debug (config)
              if (device[5750] != 0)
                @framework.deviceManager.discoveredDevice( 'pimatic-tradfri: ', "#{config.name} - #{device[3][1]}", config )
            )
          )
        )
        @framework.deviceManager.discoverMessage 'pimatic-tradfri', "scanning for tradfri devices finished"

  Tradfri_connection = new TradfriPlugin

  class TradfriDimmer extends env.devices.DimmerActuator
    _lastdimlevel: null

    constructor: (@config, lastState, @board, @_pluginConfig) ->
      @id = @config.id
      @name = @config.name
      @address = @config.address
      @_dimlevel = lastState?.dimlevel?.value or 0
      @_lastdimlevel = lastState?.lastdimlevel?.value or 100
      @_state = lastState?.state?.value or off
      super()

    destroy: ->
      super()

    turnOn: -> @changeDimlevelTo(@_lastdimlevel)

    turnOff: -> @changeDimlevelTo(0)

# COLD f5faf6
# NORMAL f1e0b5
# WARM efd275

    changeDimlevelTo: (level) ->
      if @_dimlevel is level then return Promise.resolve true
      if level is 0
        state = off
      else
        state = on
      unless @_dimlevel is 0
        @_lastdimlevel = @_dimlevel
      bright=Math.round(level*(2.55))
      tradfriHub.setDevice(@address, {
        state: state,
        brightness: bright
      }).then(
        @_setDimlevel(level)
      ).catch (error) ->
        env.logger.debug ("ERROR3 : #{error}")

  return Tradfri_connection
