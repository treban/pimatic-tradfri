module.exports = (env) ->

  TradfriCoapdtls = require 'tradfri-coapdtls'
  assert = env.require 'cassert'
  cassert = env.require 'cassert'
  t = env.require('decl-api').types
  _ = env.require 'lodash'
  M = env.matcher
  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

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
      @framework.deviceManager.registerDeviceClass("TradfriDimmerTemp", {
        configDef: deviceConfigDef.TradfriDimmer,
        createCallback: (config, lastState) => new TradfriDimmerTemp(config, @, @framework, lastState)
      })
      @framework.deviceManager.registerDeviceClass("TradfriDimmerTempButton", {
        configDef: deviceConfigDef.TradfriDimmer,
        createCallback: (config, lastState) => new TradfriDimmerTempButton(config, @, @framework, lastState)
      })
      @framework.deviceManager.registerDeviceClass("TradfriGroup", {
        configDef: deviceConfigDef.TradfriGroup,
        createCallback: (config, lastState) => new TradfriGroup(config, @, @framework, lastState)
      })
      @framework.deviceManager.registerDeviceClass("TradfriGroupScene", {
        configDef: deviceConfigDef.TradfriScene,
        createCallback: (config, lastState) => new TradfriGroupScene(config, @, @framework, lastState)
      })
      #@framework.deviceManager.registerDeviceClass("TradfriMotion", {
      #  configDef: deviceConfigDef.TradfriGroup,
      #  createCallback: (config, lastState) => new TradfriGroup(config, @, @framework, lastState)
      #})
      @framework.ruleManager.addActionProvider(new TradfriDimmerTempActionProvider(@framework))

      @framework.on "after init", =>
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-tradfri/app/tradfri-template.coffee"
          mobileFrontend.registerAssetFile 'html', "pimatic-tradfri/app/tradfri-template.jade"
          mobileFrontend.registerAssetFile 'css', "pimatic-tradfri/app/tradfri-template.css"
        else
          env.logger.warn "pimatic tradfri could not find the mobile-frontend. No gui will be available"

      @framework.deviceManager.on 'discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-tradfri', "scanning for tradfri devices"
        if (tradfriReady)
          tradfriHub.getAllDevices().then( (devices)=>
            #env.logger.debug("Devices:")
            #env.logger.debug(devices)
            devices.forEach((device) =>
              @lclass = switch
                when device[3][1] == "TRADFRI bulb E27 WS opal 980lm" then "TradfriDimmerTemp"
                when device[3][1] == "TRADFRI bulb E14 WS opal 400lm" then "TradfriDimmerTemp"
                when device[3][1] == "TRADFRI bulb GU10 WS 400lm" then "TradfriDimmerTemp"
                when device[3][1] == "TRADFRI bulb E27 WS clear 950lm" then "TradfriDimmerTemp"
                when device[3][1] == "TRADFRI bulb E27 opal 1000lm" then "TradfriDimmer"
      #          when device[3][1] == "TTRADFRI motion sensor" then "TradfriMotion"
                else "TradfriDimmer"
              config = {
                    class: @lclass
              }
              config.name=device['9001']
              config.id="tradfri_#{device['9003']}"
              config.address=device['9003']
              #env.logger.debug(config)
              if (device[5750] == 2)
                @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "LIGHT: #{config.name} - #{device[3][1]}", config )
              )
              #if (device[5750] == 4)
              #  @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "Motion: #{config.name} - #{device[3][1]}", config )
              #)
          ).catch( (err) =>
            env.logger.error ("DeviceDiscover #{err}")
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
              #env.logger.debug(config)
              @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "GROUP: #{config.name}", config )

              config = {
                    class: "TradfriGroupScene"
              }
              config.name="Scenes #{group['9001']}"
              config.id="tradfri_scene_#{group['9003']}"
              config.address=group['9003']
              buttonsArray=[]

              tradfriHub.getAllScenes(config.address).then( (scenes)=>
                #env.logger.debug("Scenes:")
                scenes.forEach((scene) =>
                  buttonConfig =
                      id : "tradfri_#{group['9003']}_#{scene['9003']}"
                      text : "#{scene['9001']}"
                      address : "#{scene['9003']}"
                  buttonsArray.push(buttonConfig)
                  #@framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "GROUP: #{config.name}", config )
                )
                config.buttons=buttonsArray
                @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "Scenes: #{config.name}", config )
              ).catch( (err) =>
                  env.logger.error(err)
              )
            )
          ).catch( (err) =>
              env.logger.error(err)
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
# Tradfri Motion Sensor
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
      @_transtime=@config.transtime or 5
      @_presence=true
      @addAttribute  'presence',
          description: "online status",
          type: t.boolean

      super()
      if (tradfriReady)
        @makeObserver()
      else
        Tradfri_connection.on 'ready', =>
          @makeObserver()


    destroy: ->
      super()

    getTemplateName: -> "tradfridimmer-dimmer"

    makeObserver: ->
      tradfriHub.setObserver(@address,@observer).then (res) =>
        env.logger.debug ("Obeserving now the device #{@config.name}")
        #env.logger.debug (res)
      .catch( (error) =>
        env.logger.error ("Observe device error : #{error}")
      )
      tradfriHub.getDevicebyID(@address).then (res) =>
        if (!res['9019'])
          env.logger.debug ("Light #{@name} is offline")
          @_setPresence(false)
        else
          @_setPresence(true)
      .catch( (error) =>
        env.logger.error ("Observe device error : #{error}")
      )


    observer: (res) =>
      env.logger.debug ("New device values received for #{@name}")
      if (!res['9019'])
        env.logger.debug ("Light #{@name} is offline")
        @_setPresence(false)
      else
        @_setPresence(true)
        if ( isNaN(res['3311'][0]['5850']) or isNaN(res['3311'][0]['5851']) )
          env.logger.debug ("Light #{@name} is online")
        else
          env.logger.debug ("ON/OFF: " + res['3311'][0]['5850'] + ", brightness: " + res['3311'][0]['5851'])
          if ( ! res['3311'][0]['5850'] )
            @_setDimlevel(0)
          else
            @_setDimlevel(Math.round((res['3311'][0]['5851'])/(2.54)))

    _setPresence: (value) ->
      if @_presence is value then return
      @_presence = value
      @emit 'presence', value

    getPresence: -> Promise.resolve(@_presence)

    turnOn: ->
      @_setval(1,Math.round(@_lastdimlevel*(2.54)))
      @_setDimlevel(@_lastdimlevel)
      return Promise.resolve()

    turnOff: ->
      @_lastdimlevel = @_dimlevel
      @_setval(0,0)
      @_setDimlevel(0)
      return Promise.resolve()

    changeDimlevelTo: (level) ->
      #env.logger.debug ("changeDimlevelTo")
      #env.logger.debug (level)
      if @_dimlevel is level then return Promise.resolve true
      if level is 0
        state = 0
        bright = 1
      else
        state = 1
        bright=Math.round(level*(2.54))
      unless @_dimlevel is 0
        @_lastdimlevel = @_dimlevel
      @_setDimlevel(level)
      return Promise.resolve(@_setval(state,bright))


    _setval: (state,bright) ->
      if (tradfriReady)
        tradfriHub.setDevice(@address, {
          state: state,
          brightness: bright
        },@_transtime).then( (res) =>
          env.logger.debug ("New value send to device")
          env.logger.debug ({          state: state,          brightness: bright        })
          return Promise.resolve()
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
      @_transtime=@transtime? or 5
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
          brightness: "254"
        },@_transtime).then( (res) =>
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

  class TradfriDimmerTemp extends TradfriDimmer

    min = 24933
    max = 33137
    @_color = 0

    template: 'tradfridimmer-temp'

    constructor: (@config, @plugin, @framework, lastState) ->
      @addAttribute  'color',
          description: "color Temperature",
          type: t.number

      @actions.setColor =
        description: 'set light color'
        params:
          colorCode:
            type: t.number
      super(@config, @plugin, @framework, lastState)

    observer: (res) =>
      env.logger.debug ("New device values received for #{@name}")
      if (!res['9019'])
        env.logger.debug ("Light #{@name} is offline")
        @_setPresence(false)
      else
        @_setPresence(true)
        if ( isNaN(res['3311'][0]['5850']) or isNaN(res['3311'][0]['5851']) )
          env.logger.debug ("Light #{@name} is online")
        else
          env.logger.debug ("ON/OFF: " + res['3311'][0]['5850'] + ", brightness: " + res['3311'][0]['5851'])
          #env.logger.debug (res)
          ncol=res['3311']['0']['5709']
          ncol=(ncol-min)/(max-min)
          ncol=Math.min(Math.max(ncol, 0), 1)
          #env.logger.debug (ncol)
          @_setColor(Math.round(ncol*100))
          if ( ! res['3311'][0]['5850'] )
            @_setDimlevel(0)
          else
            @_setDimlevel(Math.round((res['3311'][0]['5851'])/(2.54)))

    getTemplateName: -> "tradfridimmer-temp"

    getColor: -> Promise.resolve(@_color)

    _setColor: (color) =>
      cassert(not isNaN(color))
      cassert color >= 0
      cassert color <= 100
      if @_color is color then return
      @_color = color
      @emit "color", color

    setColor: (color) =>
      @_color= Math.round (min + color / 100 * (max-min))
      @sendColor(@_color)
      @_setColor(color)
      return Promise.resolve()

    sendColor: (color) ->
      if (tradfriReady)
        tradfriHub.setColorXY(@address, color, @_transtime
        ).then( (res) =>
          env.logger.debug ("New Color send to device")
          #env.logger.debug (res)
        ).catch( (error) =>
          env.logger.error ("set device error: #{error}")
        )

    destroy: ->
      super()


##############################################################
# TradfriDimmer with temperatur buttons
##############################################################

  class TradfriDimmerTempButton extends TradfriDimmerTemp

    min = 24933
    max = 33137

    template: 'tradfridimmer-temp-buttons'

    constructor: (@config, @plugin, @framework, lastState) ->
      super(@config, @plugin, @framework, lastState)
      @actions.setColorFix =
        description: 'set light color fix value'
        params:
          colorCode:
            type: t.string
    getTemplateName: -> "tradfridimmer-temp-buttons"

    setColorFix: (color) =>
      @colorval = switch
        when color == "normal" then 64
        when color == "warm" then 100
        when color == "cold" then 0
      @_color= Math.round (min + @colorval / 100 * (max-min))
      @sendColor(@_color)
      @_setColor(@colorval)
      return Promise.resolve()

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
    #  env.logger.debug (res)
      if ( res['5850'] == 0 )
        @_setState(false)
      else
        @_setState(true)

    changeStateTo: (state) ->
      if (tradfriReady)
        tradfriHub.setGroup(@address, {
          state: if state then 1 else 0
        },@_transtime).then( (res) =>
          env.logger.debug ("New value send to group")
          @_setState(state)
          return Promise.resolve()
        ).catch( (error) =>
          env.logger.error ("set group error: #{error}")
          Tradfri_connection.emit 'error', (error)
        )

  class TradfriGroupScene extends env.devices.ButtonsDevice

    constructor: (@config, @plugin, @framework, lastState) ->
      @id = @config.id
      @name = @config.name
      @address = @config.address
      @buttons = @config.buttons
      super(@config)

    destroy: () ->
      super()

    buttonPressed: (buttonId) =>
      for b in @config.buttons
        if b.id is buttonId
          @_lastPressedButton = b.id
          @emit 'button', b.id
          if (tradfriReady)
            tradfriHub.setScene(@address, b.address
            ).then( (res) =>
              env.logger.debug ("New scene send to group")
              return Promise.resolve()
            ).catch( (error) =>
              env.logger.error ("set scene error: #{error}")
              Tradfri_connection.emit 'error', (error)
            )
          return @requestPromise

  class TradfriDimmerTempActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @device, @valueTokens) ->
      assert @device?
      assert @valueTokens?

    setup: ->
      @dependOnDevice(@device)
      super()

    _clampVal: (value) ->
      assert(not isNaN(value))
      return (switch
        when value > 100 then 100
        when value < 0 then 0
        else value
      )

    _doExecuteAction: (simulate, value) =>
      return (
        if simulate
          __("would dim %s to %s%%", @device.name, value)
        else
          @device.setColor(value).then( => __("dimmed %s to %s%%", @device.name, value) )
      )

    executeAction: (simulate) =>
      return @framework.variableManager.evaluateNumericExpression(@valueTokens).then( (value) =>
        value = @_clampVal value
        return @_doExecuteAction(simulate, value)
      )

    hasRestoreAction: -> yes

    executeRestoreAction: (simulate) => Promise.resolve(@_doExecuteAction(simulate, @lastValue))


  class TradfriDimmerTempActionProvider extends env.actions.ActionProvider
    constructor: (@framework) ->
      super()

    parseAction: (input, context) =>
      TradfriDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => _.includes [
          'TradfriDimmerTemp'
        ], device.config.class
      ).value()

      m = M(input, context).match(['set color '])

      device = null
      color = null
      match = null
      variable = null
      valueTokens = null

      m.matchDevice TradfriDevices, (m, d) ->
        if device? and device.id isnt d.id
          context?.addError(""""#{input.trim()}" is ambiguous.""")
          return

        device = d
        m.match(' to ')
            .matchNumericExpression( (next, ts) =>
              m = next.match('%', optional: yes)
              if device? and device.id isnt d.id
                context?.addError(""""#{input.trim()}" is ambiguous.""")
                return
              device = d
              valueTokens = ts
              match = m.getFullMatch()
              )

      if match?
        if valueTokens.length is 1 and not isNaN(valueTokens[0])
          value = valueTokens[0]
          assert(not isNaN(value))
          value = parseFloat(value)
          if value < 0.0
            context?.addError("Can't change to a negative dimlevel.")
            return
          if value > 100.0
            context?.addError("Can't change to greater than 100%.")
            return
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new TradfriDimmerTempActionHandler(@framework, device, valueTokens)
        }
      else
      return null

  return Tradfri_connection
