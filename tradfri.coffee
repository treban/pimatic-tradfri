
'use strict';

module.exports = (env) ->

  TradfriCoapdtls = require 'tradfri-coapdtls'
  assert = env.require 'cassert'
  cassert = env.require 'cassert'
  t = env.require('decl-api').types
  _ = env.require 'lodash'
  M = env.matcher
  Promise = env.require 'bluebird'

  tradfriHub = null
  tradfriReady = false

  Color = require('./color')(env)

  class TradfriPlugin extends env.plugins.Plugin

    @cfg = null

    init: (app, @framework, @config) =>
      env.logger.info("Plugin initialization...")
      @secID = @config.secID
      @hubIP = @config.hubIP
      @psk = @config.psk
      @identity = @config.identity
      @cfg=@config
      framework = @framework
      first=true

      @newready=false

      env.logger.debug ("tradfri cfg: Gateway IP: #{@hubIP}")

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
      @framework.deviceManager.registerDeviceClass("TradfriActor", {
       configDef: deviceConfigDef.TradfriActor,
       createCallback: (config, lastState) => new TradfriActor(config, @, @framework, lastState)
      })
      @framework.deviceManager.registerDeviceClass("TradfriRGB", {
       configDef: deviceConfigDef.TradfriDimmer,
       createCallback: (config, lastState) => new TradfriRGB(config, @, @framework, lastState)
      })

      @framework.ruleManager.addActionProvider(new TradfriDimmerTempActionProvider(@framework))
      @framework.ruleManager.addActionProvider(new TradfriDimmerRGBActionProvider(@framework))

      #@framework.on('destroy', (context) =>
      #)
      @framework.on "after init", =>
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-tradfri/app/tradfri-template.coffee"
          mobileFrontend.registerAssetFile 'html', "pimatic-tradfri/app/tradfri-template.jade"
          mobileFrontend.registerAssetFile 'css', "pimatic-tradfri/app/tradfri-template.css"
          mobileFrontend.registerAssetFile 'js', "pimatic-tradfri/app/spectrum.js"
          mobileFrontend.registerAssetFile 'css', "pimatic-tradfri/app/spectrum.css"
        else
          env.logger.warn "pimatic tradfri could not find the mobile-frontend. No gui will be available"

      @framework.deviceManager.on 'discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-tradfri', "scanning for tradfri devices"
        if (tradfriReady)
          tradfriHub.getAllDevices().then( (devices)=>
            devices.forEach((device) =>
              @lclass = switch
                when device[3][1] == "TRADFRI bulb E27 WS opal 980lm" then "TradfriDimmerTemp"
                when device[3][1] == "TRADFRI bulb E14 WS opal 400lm" then "TradfriDimmerTemp"
                when device[3][1] == "TRADFRI bulb GU10 WS 400lm" then "TradfriDimmerTemp"
                when device[3][1] == "TRADFRI bulb E27 WS clear 950lm" then "TradfriDimmerTemp"
                when device[3][1] == "TRADFRI bulb E27 opal 1000lm" then "TradfriDimmer"
                when device[3][1] == "TRADFRI bulb E27 CWS opal 600lm" then "TradfriRGB"
                when device[3][1] == "TRADFRI remote control" then "TradfriActor"
                when device[3][1] == "TRADFRI motion sensor" then "TradfriActor"
                when device[3][1] == "TRADFRI wireless dimmer" then "TradfriActor"
                else "TradfriDimmer"
              config = {
                    class: @lclass,
                    name: device['9001'],
                    id: "tradfri_#{device['9003']}",
                    address: device['9003']
              }
              if (device[5750] == 2)
                @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "LIGHT: #{config.name} - #{device[3][1]}", config )
              if (device[5750] == 0)
                @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "RemoteControl: #{config.name} - #{device[3][1]}", config )
              if (device[5750] == 4)
                @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "MotionSensor: #{config.name} - #{device[3][1]}", config )
            )
          ).catch( (err) =>
            env.logger.error ("DeviceDiscover #{err}")
          )
          tradfriHub.getAllGroups().then( (groups)=>
            groups.forEach((group) =>
              config = {
                    class: "TradfriGroup",
                    name: group['9001'],
                    id: "tradfri_#{group['9003']}",
                    address: group['9003']
              }
              @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "GROUP: #{config.name}", config )
              config = {
                    class: "TradfriGroupScene",
                    name: "Scenes #{group['9001']}",
                    id: "tradfri_scene_#{group['9003']}",
                    address: group['9003']
              }
              buttonsArray=[]
              tradfriHub.getAllScenes(config.address).then( (scenes)=>
                scenes.forEach((scene) =>
                  buttonConfig =
                      id : "tradfri_#{group['9003']}_#{scene['9003']}"
                      text : "#{scene['9001']}"
                      address : "#{scene['9003']}"
                  buttonsArray.push(buttonConfig)
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
                  class: "TradfriHub",
                  name: "TradfriHub",
                  id: "tradfri_hub",
                  ntpserver: gw['9023']
            }
            @framework.deviceManager.discoveredDevice( 'pimatic-tradfri ', "GATEWAY: #{config.name} - #{@hubIP}", config )
          ).catch( (err) =>
            env.logger.error(err)
          )
        else
          @framework.deviceManager.discoverMessage 'pimatic-tradfri', "gateway not reachable"
        @framework.deviceManager.discoverMessage 'pimatic-tradfri', "scanning for tradfri devices finished"

      @connect()
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

    uniqueId: (length=8) =>
      id = ""
      id += Math.random().toString(36).substr(2) while id.length < length
      id.substr 0, length

    connect: () =>
      if (@psk == undefined or @psk == "" or @psk == null)
        env.logger.debug("PSK Handshake...")
        @identity=@uniqueId(12)
        @cfg.identity=@identity
        tradfriHub = new TradfriCoapdtls({securityId: @secID,hubIpAddress: @hubIP, clientId: "Client_identity"})
        tradfriHub.connect().then( (val)=>
          tradfriHub.initPSK(@identity).then( (res) =>
            env.logger.debug("Gateway online - PSK Handshake successful: #{res['9091']}")
            env.logger.debug("Establish secure connection... ")
            @psk=res['9091']
            @cfg.psk=@psk
            @framework.pluginManager.updatePluginConfig 'tradfri', @cfg
            env.logger.debug("PSK saved to config")
            @connect()
          ).catch( (error) =>
            env.logger.error ("Gateway is not reachable!")
            env.logger.error (error)
          )
        )
      else
        tradfriHub = new TradfriCoapdtls({securityId: @psk,hubIpAddress: @hubIP,clientId: @identity})
        tradfriHub.connect().then( (val)=>
          tradfriHub.getGatewayInfo().then( (res) =>
            env.logger.debug("Gateway online - Firmware: #{res['9029']}")
            env.logger.debug("Tradfri plugin ready")
            tradfriReady=true
            @newready=true
            @emit 'ready'
          ).catch( (error) =>
            env.logger.error ("Gateway is not reachable!")
            env.logger.error (error)
            tradfriReady=false
          )
        )

  Tradfri_connection = new TradfriPlugin

##############################################################
# Tradfri HUB Presence Device
##############################################################

  class TradfriHub extends env.devices.Sensor

    template: "presence"
    _presence: undefined

    constructor: (@config,lastState) ->
      @name = @config.name
      @id = @config.id
      @ntpserver = @config.ntpserver
      @_presence = lastState?.presence?.value or false
      @_psk = lastState?.psk?.value or false
      super()

      Tradfri_connection.on 'ready', =>
        @_setPresence(true)

      Tradfri_connection.on 'error', =>
        @_setPresence(false)

    destroy: ->
      super()

    attributes:
      presence:
        description: "gateway reachability"
        type: t.boolean
        labels: ['present', 'absent']

    actions:
      getPresence:
        description: "Returns the current presence state"
        returns:
          presence:
            type: t.boolean
      changePresenceTo:
        params:
          presence:
            type: "boolean"

    _setPresence: (value) ->
      if @_presence is value then return
      @_presence = value
      @emit 'presence', value

    changePresenceTo: (presence) ->
      @_setPresence(presence)
      return Promise.resolve()

    getPresence: -> Promise.resolve(@_presence)

##############################################################
# Tradfri Actor Devices
##############################################################

  class TradfriActor extends env.devices.Sensor

    template: "presence"

    constructor: (@config,lastState) ->
      @id = @config.id
      @name = @config.name
      @address = @config.address
      @_presence = lastState?.presence?.value or false
      @_battery= lastState?.battery?.value or 0
      super()
      @checker = setInterval ( =>
        @checkDev()
      ), 300000
      if (tradfriReady)
        @checkDev()
      Tradfri_connection.on 'ready', =>
        @checkDev()

    checkDev: =>
      if (tradfriReady)
        tradfriHub.getDevicebyID(@address).then( (res) =>
          if (res['9019'])
            @_setPresence(true)
          else
            @_setPresence(false)
          if (!isNaN(res['3']['9']))
            @_setBattery(res['3']['9'])
        ).catch( (error) =>
          if (error == '4.04')
            env.logger.error ("Error getting status from device #{@name}: tradfri hub doesn't have configured this device")
            @_setPresence(false)
          else
            env.logger.error ("Error getting status from device: #{error}")
            Tradfri_connection.emit 'error', (error)
        )

    destroy: ->
      super()

    attributes:
      presence:
        description: "online reachability"
        type: t.boolean
        labels: ['present', 'absent']
      battery:
        description: "Battery status"
        type: t.number

    _setBattery: (value) ->
      if @_battery is value then return
      @_battery = value
      @emit 'battery', value

    _setPresence: (value) ->
      if @_presence is value then return
      @_presence = value
      @emit 'presence', value

    getPresence: -> Promise.resolve(@_presence)

    getBattery: -> Promise.resolve(@_battery)


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
      Tradfri_connection.on 'ready', =>
        @makeObserver()

    destroy: ->
      super()

    getTemplateName: -> "tradfridimmer-dimmer"

    makeObserver: ->
      env.logger.debug ("TRY Obeserving now the device #{@config.name}")
      tradfriHub.setObserver(@address,@observer).then( (res) =>
        env.logger.debug ("Obeserving now the device #{@config.name}")
        tradfriHub.getDevicebyID(@address).then (res) =>
          if (res['9019'])
            @_setPresence(true)
          else
            env.logger.debug ("Light #{@name} is offline")
            @_setPresence(false)
        .catch( (error) =>
          env.logger.error ("Observe device error : #{error}")
        )
      ).catch( (error) =>
        if (error is '4.04')
          env.logger.error ("Observe device #{@name} error: tradfri hub doesn't have configured this device")
          @_setPresence(false)
        else
          env.logger.error ("Observe device #{@name} error : #{error}")
          Tradfri_connection.emit 'error', (error)
      )

    observer: (res) =>
      if (!res['9019'])
        env.logger.debug ("Light #{@name} is offline")
        @_setPresence(false)
      else
        if (!@getPresence())
          env.logger.debug ("Light #{@name} is online")
        @_setPresence(true)
        if (typeof res['3311'] != "undefined" && res['3311'] != null)
          if ( isNaN(res['3311'][0]['5850']) or isNaN(res['3311'][0]['5851']) )
          else
            env.logger.debug ("New device values received for #{@name}")
            env.logger.debug ("ON/OFF: " + res['3311'][0]['5850'] + ", brightness: " + res['3311'][0]['5851'])
            if ( ! res['3311'][0]['5850'] )
              @_setDimlevel(0)
            else
              @val = Math.round((res['3311'][0]['5851'])/(2.54))
              if @val is 0
                @val = 1
              @_setDimlevel(@val)

    _setPresence: (value) ->
      if @_presence is value then return
      @_presence = value
      @emit 'presence', value

    getPresence: -> Promise.resolve(@_presence)

    turnOn: ->
      @_setDimlevel(@_lastdimlevel)
      return Promise.resolve(@_setval(1,Math.round(@_lastdimlevel*(2.54))))

    turnOff: ->
      @_lastdimlevel = @_dimlevel
      @_setDimlevel(0)
      return Promise.resolve(@_setval(0,0))

    changeDimlevelTo: (level) ->
      if @_dimlevel is level then return Promise.resolve true
      if level is 0
        state = 0
        bright = 0
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
          if (error == "4.05")
            env.logger.error ("set device #{@name} error: tradfri hub doesn't have configured this device")
          else
            env.logger.error ("set device #{@name} error: gateway not reachable")
            Tradfri_connection.emit 'error', (error)
          return Promise.reject()
        )
      else
        return Promise.reject()

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
      Tradfri_connection.on 'ready', =>
        @makeObserver()

    makeObserver: ->
      tradfriHub.setObserver(@address,@observer).then ((res) =>
        env.logger.debug ("Obeserving now the device #{@config.name}")
        #env.logger.debug (res)
      ).catch( (error) =>
        if (error == '4.04')
          env.logger.error ("Observe device #{@name} error: tradfri hub doesn't have configured this device")
        else
          env.logger.error ("Observe device #{@name} error : #{error}")
          Tradfri_connection.emit 'error', (error)
      )

    observer: (res) =>
      env.logger.debug ("New device values received for #{@name}")
      #env.logger.debug (res)
      if (typeof res['3311'] != "undefined" && res['3311'] != null)
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
          if (error == "4.05")
            env.logger.error ("set device #{@name} error: tradfri hub doesn't have configured this device")
          else
            env.logger.error ("set device #{@name} error: gateway not reachable")
            Tradfri_connection.emit 'error', (error)
          return Promise.reject()
        )
      else
        return Promise.reject()



##############################################################
# TradfriDimmerTempSliderItem
##############################################################

  class TradfriDimmerTemp extends TradfriDimmer

    cmin = 24933
    cmax = 33137
    min = 2000
    max = 4700

    @_color = 0
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
      if (!res['9019'])
        env.logger.debug ("Light #{@name} is offline")
        @_setPresence(false)
      else
        if (!@getPresence())
          env.logger.debug ("Light #{@name} is online")
        @_setPresence(true)
        if (typeof res['3311'] != "undefined" && res['3311'] != null)
          if ( isNaN(res['3311'][0]['5850']) or isNaN(res['3311'][0]['5851']) or isNaN(res['3311'][0]['5709']) )
          else
            env.logger.debug ("New device values received for #{@name}")
            ncol=res['3311']['0']['5709']
            ncol=(ncol-cmin)/(cmax-cmin)
            ncol=Math.min(Math.max(ncol, 0), 1)
            @_setColor(Math.round(ncol*100))
            env.logger.debug ("ON/OFF: " + res['3311'][0]['5850'] + ", brightness: " + res['3311'][0]['5851'] + ", color: " + @_color)
            if ( ! res['3311'][0]['5850'] )
              @_setDimlevel(0)
            else
              @val = Math.round((res['3311'][0]['5851'])/(2.54))
              if @val is 0
                @val = 1
              @_setDimlevel(@val)

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
      if @_color is color then return Promise.resolve true
      ncolor=Math.round (min + Math.abs(color-100) / 100 * (max-min))
      tcolor=Color.kelvin_to_xy(ncolor)
      ncolor=Math.round (cmin + color / 100 * (cmax-cmin))
      @_setColor(color)
      return Promise.resolve(@sendColor(tcolor,ncolor))

    sendColor: (color,xcol) ->
      if (tradfriReady)
        tradfriHub.setColorXY(@address, parseInt(xcol), parseInt(color[1]), @_transtime
        #tradfriHub.setColorTemp(@address, color, @_transtime
        ).then( (res) =>
          env.logger.debug ("New Color send to device")
          return Promise.resolve()
        ).catch( (error) =>
          if (error == "4.05")
            env.logger.error ("set device #{@name} error: tradfri hub doesn't have configured this device")
          else
            env.logger.error ("set device #{@name} error: gateway not reachable")
            Tradfri_connection.emit 'error', (error)
          return Promise.reject()
        )
      else
        return Promise.reject()

    destroy: ->
      super()

##############################################################
# TradfriDimmerTempSliderItem
##############################################################

  class TradfriRGB extends TradfriDimmerTemp

    cmin = 24933
    cmax = 33137
    min = 2000
    max = 4700

    @_color = 0
    @_hue = 0
    @_sat = 0
    template: 'tradfridimmer-rgb'

    constructor: (@config, @plugin, @framework, lastState) ->
      @addAttribute  'color',
          description: "color Temperature",
          type: t.number
      @addAttribute  'hue',
          description: "color Temperature",
          type: t.number
      @addAttribute  'sat',
          description: "color Temperature",
          type: t.number

      @actions.setColor =
        description: 'set light color'
        params:
          colorCode:
            type: t.number
      @actions.setHuesat =
        description: 'set light color'
        params:
          hue:
            type: t.number
          sat:
            type: t.number
          val:
            type: t.number
      @actions.setRGB =
        description: 'set light color'
        params:
          r:
            type: t.number
          g:
            type: t.number
          b:
            type: t.number
      @actions.setHue =
        description: 'set light color'
        params:
          hue:
            type: t.number
      @actions.setSat =
        description: 'set light color'
        params:
          sat:
            type: t.number
      super(@config, @plugin, @framework, lastState)

    observer: (res) =>
      if (!res['9019'])
        env.logger.debug ("Light #{@name} is offline")
        @_setPresence(false)
      else
        if (!@getPresence())
          env.logger.debug ("Light #{@name} is online")
        @_setPresence(true)
        if (typeof res['3311'] != "undefined" && res['3311'] != null)
          if ( isNaN(res['3311'][0]['5850']) or isNaN(res['3311'][0]['5851']) or isNaN(res['3311'][0]['5709']) )
          else
            env.logger.debug ("New device values received for #{@name}")
            ncol=res['3311']['0']['5709']
            ncol=(ncol-cmin)/(cmax-cmin)
            ncol=Math.min(Math.max(ncol, 0), 1)
            @_setColor(Math.round(ncol*100))
            env.logger.debug ("ON/OFF: " + res['3311'][0]['5850'] + ", brightness: " + res['3311'][0]['5851'] + ", color: " + @_color)
            if ( ! res['3311'][0]['5850'] )
              @_setDimlevel(0)
            else
              @val = Math.round((res['3311'][0]['5851'])/(2.54))
              if @val is 0
                @val = 1
              @_setDimlevel(@val)

    getTemplateName: -> "tradfridimmer-rgb"

    _setHue: (hueVal) ->
      hueVal = parseFloat(hueVal)
      assert not isNaN(hueVal)
      assert 0 <= hueVal <= 100
      unless @_hue is hueVal
        @_hue = hueVal
        @emit "hue", hueVal

    _setSat: (satVal) ->
      satVal = parseFloat(satVal)
      assert not isNaN(satVal)
      assert 0 <= satVal <= 100
      unless @_sat is satVal
        @_sat = satVal
        @emit "sat", satVal

    getHue: -> Promise.resolve(@_hue)

    getSat: -> Promise.resolve(@_sat)


    # h=0-360,s=0-1,l=0-1
    setHuesat: (h,s,l=0.75) ->
      rgb=Color.hslToRgb(h,s,l)
      xy=Color.rgb_to_xyY(rgb[0],rgb[1],rgb[2])
      if (tradfriReady)
        tradfriHub.setColorXY(@address, parseInt(xy[0]), parseInt(xy[1]), @_transtime
        ).then( (res) =>
          env.logger.debug ("New Color send to device")
          return Promise.resolve()
        )
      else
        return Promise.reject()

    setColorHex: (hex) ->
      if (tradfriReady)
        tradfriHub.setColorHex(@address, hex, @_transtime
        ).then( (res) =>
          env.logger.debug ("New Color send to device")
          return Promise.resolve()
        )
      else
        return Promise.reject()

    setRGB: (r,g,b) ->
      xy=Color.rgb_to_xyY(r,g,b)
      if (tradfriReady)
        tradfriHub.setColorXY(@address, parseInt(xy[0]), parseInt(xy[1]), @_transtime
        ).then( (res) =>
          env.logger.debug ("New Color send to device")
          return Promise.resolve()
        )
      else
        return Promise.reject()

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
      @_setColor(@colorval)
      @sendColor(@_color)

    destroy: ->
      super()

##############################################################
# Tradfri Group
##############################################################
  class TradfriGroup extends TradfriDimmer

    constructor: (@config, @plugin, @framework, lastState) ->
      super(@config, @plugin, @framework, lastState)

    makeObserver: ->
      tradfriHub.setObserverGroup(@address,@observer).then( (res) =>
        env.logger.debug ("Obeserving now the group #{@config.name}")
        #env.logger.debug (res)
      ).catch( (error) =>
        if (error == '4.04')
          env.logger.error ("Observe group #{@name} error: tradfri hub doesn't have configured this device")
        else
          env.logger.error ("Observe group #{@name} error : #{error}")
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

    _setval: (state,bright) ->
      if (tradfriReady)
        tradfriHub.setGroup(@address, {
          state: state,
          brightness: bright
        },@_transtime).then( (res) =>
          env.logger.debug ("New value send to device")
          env.logger.debug ({          state: state,          brightness: bright        })
          return Promise.resolve()
        ).catch( (error) =>
          if (error == "4.05")
            env.logger.error ("set device #{@name} error: tradfri hub doesn't have configured this device")
          else
            env.logger.error ("set device #{@name} error: gateway not reachable")
            Tradfri_connection.emit 'error', (error)
          return Promise.reject()
        )
      else
        return Promise.reject()

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
            ).catch( (error) =>
              if (error == "4.05")
                env.logger.error ("set device #{@name} error: tradfri hub doesn't have configured this scene")
              else
                env.logger.error ("set device #{@name} error: gateway not reachable")
                Tradfri_connection.emit 'error', (error)
            )
          else
            return Promise.reject()
          return Promise.resolve()
      throw new Error("No button with the id #{buttonId} found")

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

      m = M(input, context).match(['set color temp '])

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

  class TradfriDimmerRGBActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @device, @hex) ->
      assert @device?
      assert @hex?
      @result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(@hex)
      @r = parseInt(@result[1], 16)
      @g = parseInt(@result[2], 16)
      @b = parseInt(@result[3], 16)

    setup: ->
      @dependOnDevice(@device)
      super()

    _doExecuteAction: (simulate) =>
      return (
        if simulate
          __("would set color %s to %s%", @device.name)
        else
          @device.setRGB(@r,@g,@b).then( => __("set color %s to %s", @device.name, @hex) )
      )

    executeAction: (simulate) =>
        return @_doExecuteAction(simulate)

    hasRestoreAction: -> yes

    executeRestoreAction: (simulate) => Promise.resolve(@_doExecuteAction(simulate, @lastValue))


  class TradfriDimmerRGBActionProvider extends env.actions.ActionProvider
    constructor: (@framework) ->
      super()

    parseAction: (input, context) =>
      TradfriDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => _.includes [
          'TradfriRGB'
        ], device.config.class
      ).value()

      m = M(input, context).match(['set color rgb '])

      device = null
      hex = null
      match = null
      r = null
      g = null
      b = null

      m.matchDevice TradfriDevices, (m, d) ->
        if device? and device.id isnt d.id
          context?.addError(""""#{input.trim()}" is ambiguous.""")
          return
        device = d
        m.match [' to '], (m) ->
          m.or [
            (m) -> m.match [/(#[a-fA-F\d]{6})(.*)/], (m, s) ->
              hex = s.trim()
              match = m.getFullMatch()
          ]
      if match?
        assert hex?
        return {
          token : match
          nextInput: input.substring(match.length)
          actionHandler: new TradfriDimmerRGBActionHandler(@framework, device, hex)
        }
      else
      return null

  return Tradfri_connection

