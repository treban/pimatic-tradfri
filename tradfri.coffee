
module.exports = (env) ->

  TradfriCoapdtls = require 'tradfri-coapdtls'
  assert = env.require 'cassert'
  t = env.require('decl-api').types

  tradfriHub = null
  tradfriReady = false

  class TradfriPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      env.logger.info("Plugin initialization...")
      @secID = @config.secID
      @hubIP = @config.hubIP
      framework = @framework
      first=true
      @newready=true

      env.logger.debug ("tradfri cfg: Gateway IP: #{@hubIP} KEY: #{@secID}")

      deviceConfigDef = require("./device-config-schema.coffee")
      @framework.deviceManager.registerDeviceClass("TradfriHub", {
        configDef: deviceConfigDef.TradfriHub,
        createCallback: (config, lastState) => new TradfriHub(config, lastState)
      })
      @framework.deviceManager.registerDeviceClass("TradfriDimmer", {
        configDef: deviceConfigDef.TradfriDimmer,
        createCallback: (config, lastState) => new TradfriDimmer(config, @, @framework, lastState)
      })
      @framework.deviceManager.registerDeviceClass("TradfriDimmerTempButton", {
        configDef: deviceConfigDef.TradfriDimmer,
        createCallback: (config, lastState) => new TradfriDimmerTempButton(config, @, @framework, lastState)
      })
      @framework.deviceManager.registerDeviceClass("TradfriGroup", {
        configDef: deviceConfigDef.TradfriGroup,
        createCallback: (config, lastState) => new TradfriGroup(config, @, @framework, lastState)
      })
      #@framework.deviceManager.registerDeviceClass("TradfriMotion", {
      #  configDef: deviceConfigDef.TradfriGroup,
      #  createCallback: (config, lastState) => new TradfriGroup(config, @, @framework, lastState)
      #})

      @framework.on "after init", =>
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-tradfri/app/tradfri-template.coffee"
          mobileFrontend.registerAssetFile 'html', "pimatic-tradfri/app/tradfri-template.jade"
          mobileFrontend.registerAssetFile 'css', "pimatic-tradfri/app/tradfri-template.css"
        else
          env.logger.warn "pimatic tradfric ould not find the mobile-frontend. No gui will be available"

      @framework.deviceManager.on 'discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-tradfri', "scanning for tradfri devices"
        if (tradfriReady)
          tradfriHub.getAllDevices().then( (devices)=>
            #env.logger.debug("Devices:")
            #env.logger.debug(devices)
            devices.forEach((device) =>
              @lclass = switch
                when device[3][1] == "TRADFRI bulb E27 WS opal 980lm" then "TradfriDimmerTempButton"
                when device[3][1] == "TRADFRI bulb E14 WS opal 400lm" then "TradfriDimmerTempButton"
                when device[3][1] == "TRADFRI bulb GU10 WS 400lm" then "TradfriDimmerTempButton"
                when device[3][1] == "TRADFRI bulb E27 WS clear 950lm" then "TradfriDimmerTempButton"
                when device[3][1] == "TRADFRI bulb E27 opal 1000lm" then "TradfriDimmer"
                when device[3][1] == "TTRADFRI motion sensor" then "TradfriMotion"
                else "TradfriDimmer"
              config = {
                    class: @lclass
              }
              config.name=device['9001']
              config.id="tradfri_#{device['9003']}"
              config.address=device['9003']
              env.logger.debug(config)
              if (device[5750] == 2)
                @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "LIGHT: #{config.name} - #{device[3][1]}", config )
              )
              #if (device[5750] == 4)
              #  @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "Motion: #{config.name} - #{device[3][1]}", config )
              #)
          ).catch( (err) =>
            env.logger.err ("DeviceDiscover #{err}")
          )

          tradfriHub.getAllGroups().then( (groups)=>
            #env.logger.debug("Groups:")
            #env.logger.debug(groups)
            groups.forEach((group) =>
              #env.logger.debug (group)
              config = {
                    class: "TradfriGroup"
              }
              config.name=group['9001']
              config.id="tradfri_#{group['9003']}"
              config.address=group['9003']
              env.logger.debug(config)
              @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "GROUP: #{config.name}", config )
            )
          ).catch( (err) =>
              env.logger.err(err)
          )

          tradfriHub.getGatewayInfo().then( (gw) =>
            config = {
                  class: "TradfriHub"
            }
            config.name= "TradfriHub"
            config.id= "tradfri_hub"
            config.ntpserver= gw['9023']
            #env.logger.debug(config)
            @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "GATEWAY: #{config.name} - #{@hubIP}", config )
          ).catch( (err) =>
            # env.logger.debug("error")
            env.logger.error(err)
          )
        else
          @framework.deviceManager.discoverMessage 'pimatic-tradfri', "gateway not reachable"
        @framework.deviceManager.discoverMessage 'pimatic-tradfri', "scanning for tradfri devices finished"

      reconnect = setInterval ( =>
        if (!tradfriReady)
          if (!first)
            env.logger.debug("...connection error!")
            tradfriHub.finish()
          first=false
          env.logger.debug("Try to connect to Tradfri")
          @connect()
        else
          if(@newready)
            tradfriHub.getGatewayInfo().then( (res) =>
              @newready=true
            ).catch( (err) =>
              @_setPresence(false)
              @emit 'error', (err)
            )
          else
            @emit 'error'
          @newready=false
      ),10000

      @.on 'error', (err) =>
        env.logger.error("Tradfri gateway is not reachable anymore!")
        tradfriHub.finish(true)
        tradfriReady=false
        @newready=true

    connect: =>
      tradfriHub = new TradfriCoapdtls({securityId: @secID,hubIpAddress: @hubIP}, (val) =>
        tradfriHub.getGatewayInfo().then( (res) =>
          env.logger.debug("Gateway online - Firmware: #{res['9029']}")
          env.logger.debug("Tradfri plugin ready")
          tradfriReady=true
          @newready=true
          @emit 'ready'
        ).catch( (error) =>
          env.logger.error ("Gateway is not reachable!")
          tradfriReady=false
        )
      )

    @toHex: (d) =>
      return ("0"+(Number(d).toString(16))).slice(-2).toUpperCase()


  Tradfri_connection = new TradfriPlugin


##############################################################
# Tradfri HUB
##############################################################

  class TradfriHub extends env.devices.Sensor

    constructor: (@config,lastState) ->
      @name = @config.name
      @id = @config.id
      @ntpserver = @config.ntpserver
      @_presence = lastState?.presence?.value or false
      super()

      Tradfri_connection.on 'ready', =>
        @_setPresence(true)

      Tradfri_connection.on 'error', =>
        @_setPresence(false)

    destroy: ->
      super()
      clearTimeout @intervalId

    attributes:
      presence:
        description: "gateway reachability"
        type: t.boolean
        labels: ['present', 'absent']

    _setPresence: (value) ->
      if @_presence is value then return
      @_presence = value
      @emit 'presence', value

    getPresence: -> Promise.resolve(@_presence)

    template: "presence"

##############################################################
# Tradfri HUB
##############################################################
#
#  class TradfriMotion extends env.devices.Sensor
#
#    constructor: (@config,lastState) ->
#      @name = @config.name
#      @id = @config.id
#      @_presence = lastState?.presence?.value or false
#      super()
#
#    destroy: ->
#      super()
#      clearTimeout @intervalId
#
#    attributes:
#      presence:
#        description: "motion"
#        type: t.boolean
#        labels: ['motion', 'nothing']
#
#    _setPresence: (value) ->
#      if @_presence is value then return
#      @_presence = value
#      @emit 'presence', value
#
#    getPresence: -> Promise.resolve(@_presence)
#
#    template: "presence"
#
##############################################################
# TradfriDimmer
##############################################################

  class TradfriDimmer extends env.devices.DimmerActuator

    _lastdimlevel: null

    template: 'tradfridimmer-dimmer'

    constructor: (@config, @plugin, @framework, lastState) ->
      @id = @config.id
      @name = @config.name
      @address = @config.address
      @_dimlevel = lastState?.dimlevel?.value or 0
      @_lastdimlevel = lastState?.lastdimlevel?.value or 100
      @_state = lastState?.state?.value or off
      super()
      if (tradfriReady)
        @makeObserver()
      else
        Tradfri_connection.on 'ready', =>
          @makeObserver()

    makeObserver: ->
      tradfriHub.setObserver(@address,@observer).then (res) =>
        env.logger.debug ("Obeserving now the device #{@config.name}")
        #env.logger.debug (res)
      .catch( (error) =>
        env.logger.error ("Observe device error : #{error}")
      )

    getTemplateName: -> "tradfridimmer-dimmer"

    turnOn: ->
      @changeDimlevelTo(@_lastdimlevel)

    turnOff: ->
      @changeDimlevelTo(0)

    observer: (res) =>
      env.logger.debug ("New device values received for #{@name}")
      if (!res['9019'])
        env.logger.debug ("Light #{@name} is offline")
      else if ( isNaN(res['3311'][0]['5850']) or isNaN(res['3311'][0]['5851']) )
        env.logger.debug ("Light #{@name} is online")
      else
        env.logger.debug ("ON/OFF: " + res['3311'][0]['5850'] + ", brightness: " + res['3311'][0]['5851'])
        if ( ! res['3311'][0]['5850'] )
          @_setDimlevel(0)
        else
          @_setDimlevel(Math.round((res['3311'][0]['5851'])/(2.55)))

    destroy: ->
      super()

    changeDimlevelTo: (level) ->
      #env.logger.debug ("changeDimlevelTo")
      #env.logger.debug (level)
      if @_dimlevel is level then return Promise.resolve true
      if level is 0
        state = off
      else
        state = on
      unless @_dimlevel is 0
        @_lastdimlevel = @_dimlevel
      bright=Math.round(level*(2.55))
      if (tradfriReady)
        tradfriHub.setDevice(@address, {
          state: state,
          brightness: bright
        }).then( (res) =>
          env.logger.debug ("New value send to device")
          env.logger.debug ({          state: state,          brightness: bright        })
          @_setDimlevel(level)
        ).catch( (error) =>
          env.logger.error ("set device error: #{error}")
          Tradfri_connection.emit 'error', (error)
        )

##############################################################
# TradfriSwitch
##############################################################

  class TradfriSwitch extends env.devices.SwitchActuator

    constructor: (@config, @plugin, @framework, lastState) ->
      @id = @config.id
      @name = @config.name
      @address = @config.address
      @_state = lastState?.state?.value or off
      super()
      if (tradfriReady)
        @makeObserver()
      else
        Tradfri_connection.on 'ready', =>
          @makeObserver()

    makeObserver: ->
      tradfriHub.setObserver(@address,@observer).then (res) =>
        env.logger.debug ("Obeserving now the device #{@config.name}")
        #env.logger.debug (res)
      .catch( (error) =>
        env.logger.error ("Observe device error : #{error}")
      )

    observer: (res) =>
      env.logger.debug ("New device values received for #{@name}")
      #env.logger.debug (res)
      if ( isNaN(res['3311'][0]['5850']) or isNaN(res['3311'][0]['5851']) )
        env.logger.debug ("Light is now online")
      else
        env.logger.debug ("DeON/OFF: " + res['3311'][0]['5850'] + ", brightness: " + res['3311'][0]['5851'])
        if ( ! res['3311'][0]['5850'] )
          @_setState(false)
        else
          @_setState(true)

    destroy: ->
      super()

    changeStateTo: (state) ->
      if (tradfriReady)
        tradfriHub.setDevice(@address, {
          state: state,
          brightness: "255"
        }).then( (res) =>
          env.logger.debug ("New value send to device")
          @_setState(state)
          return Promise.resolve()
        ).catch( (error) =>
          env.logger.error ("set device error: #{error}")
          Tradfri_connection.emit 'error', (error)
        )



##############################################################
# TradfriDimmerTempSliderItem
##############################################################

  class TradfriDimmerTempSlider extends TradfriDimmer

    _lastdimlevel: null

    template: 'tradfridimmer-color'

    constructor: (@config, @plugin, @framework, lastState) ->
      @addAttribute  'color',
          description: "Color Temperature",
          type: t.string,

      @actions.setColor =
        description: 'set light color'
        params:
          colorCode:
            type: t.string
      super(@config, @plugin, @framework, lastState)

    getTemplateName: -> "tradfridimmer-color"

    getColor: -> Promise.resolve(@_color)

    setColor: (color) ->
      #env.logger.debug ("SetColor")
      #env.logger.debug (color)
      rgb = ct.colorTemperature2rgb(color*1000)
      #env.logger.debug (rgb)
      @red = TradfriPlugin.toHex(rgb.red)
      @green = TradfriPlugin.toHex(rgb.green)
      @blue = TradfriPlugin.toHex(rgb.blue)

      @_color = color
      if (tradfriReady)
        tradfriHub.setColor(@address, @_color
        ).then( (res) =>
          env.logger.debug ("New Color send to device")
          #env.logger.debug (res)
        ).catch( (error) =>
          env.logger.error ("set device error: #{error}")
        )

    destroy: ->
      super()

##############################################################
# TradfriDimmerTempButton
##############################################################
  class TradfriDimmerTempButton extends TradfriDimmer

    template: 'tradfridimmer-temp-buttons'

    constructor: (@config, @plugin, @framework, lastState) ->
      @addAttribute  'color',
          description: "Color Temperature",
          type: t.string,

      @actions.setColor =
        description: 'set light color'
        params:
          colorCode:
            type: t.string
      super(@config, @plugin, @framework, lastState)

    getTemplateName: -> "tradfridimmer-temp-buttons"

    getColor: -> Promise.resolve(@_color)

    setColor: (color) ->
      @colorval = switch
        when color == "normal" then "f1e0b5"
        when color == "warm" then "efd275"
        when color == "cold" then "f5faf6"
      @_color = @colorval
      if (tradfriReady)
        tradfriHub.setColorHex(@address, @_color
        ).then( (res) =>
          env.logger.debug ("New Color send to device")
          #env.logger.debug (res)
        ).catch( (error) =>
          env.logger.error ("set device error: #{error}")
          Tradfri_connection.emit 'error', (error)
        )

    destroy: ->
      super()



##############################################################
# Tradfri Group
##############################################################
  class TradfriGroup extends TradfriSwitch

    constructor: (@config, @plugin, @framework, lastState) ->
      super(@config, @plugin, @framework, lastState)

    makeObserver: ->
      tradfriHub.setObserverGroup(@address,@observer).then (res) =>
        env.logger.debug ("Obeserving now the group #{@config.name}")
        #env.logger.debug (res)
      .catch( (error) =>
        env.logger.error ("Observe device error : #{error}")
        Tradfri_connection.emit 'error', (error)
      )

    destroy: ->
      super()

    observer: (res) =>
      env.logger.debug ("New group values received for #{@name}")
      env.logger.debug ("ON/OFF: " + res['5850'])
      if ( res['5850'] == 0 )
        @_setState(false)
      else
        @_setState(true)

    changeStateTo: (state) ->
      if (tradfriReady)
        tradfriHub.setGroup(@address, {
          state: if state then 1 else 0
        }).then( (res) =>
          env.logger.debug ("New value send to group")
          @_setState(state)
          return Promise.resolve()
        ).catch( (error) =>
          env.logger.error ("set group error: #{error}")
          Tradfri_connection.emit 'error', (error)
        )


  return Tradfri_connection
