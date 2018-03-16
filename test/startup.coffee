# #Framework start up

assert = require 'cassert'
fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'
# Enable this for better stack traces:
# https://github.com/petkaantonov/bluebird/blob/master/API.md#promiselongstacktraces---void
#Promise.longStackTraces()

modulePath = '..'

# Setup the environment
env = { logger: require "#{modulePath}/node_modules/pimatic/lib/logger" }
env.api = require("#{modulePath}/node_modules/pimatic/lib/api")
env.users = require("#{modulePath}/node_modules/pimatic/lib/users") env
env.devices = require("#{modulePath}/node_modules/pimatic/lib/devices") env
env.matcher = require "#{modulePath}/node_modules/pimatic/lib/matcher"
env.variables = require("#{modulePath}/node_modules/pimatic/lib/variables") env
env.actions = require("#{modulePath}/node_modules/pimatic/lib/actions") env
env.predicates = require("#{modulePath}/node_modules/pimatic/lib/predicates") env
env.rules = require("#{modulePath}/node_modules/pimatic/lib/rules") env
env.plugins = require("#{modulePath}/node_modules/pimatic/lib/plugins") env
env.database = require("#{modulePath}/node_modules/pimatic/lib/database") env
env.groups = require("#{modulePath}/node_modules/pimatic/lib/groups") env
env.pages = require("#{modulePath}/node_modules/pimatic/lib/pages") env
env.require = (args...) -> module.require args...

startup = =>
  # set the config file to
  configFile = (
    # PIMATIC_CONFIG environment variable if it has been set up
    if process.env.PIMATIC_CONFIG? then process.env.PIMATIC_CONFIG
    # or get the configuration parent folder of node_modules
    else path.resolve __dirname, '../../config.json'
  )

  env.exit = exit = (code) ->
    env.logger.info "exiting..."
    if process.logStream?
      # close logstream first
      process.stdout.write = process.stdout.writeOut
      process.stderr.write = process.stderr.writeOut
      process.logStream.writer.on 'finish', ->
        process.exit(code)
      process.logStream.end()
    else
      process.exit(code)

  # This is to trace back uncaughtException from net socket
  (hijackSocketConnectToTraceUncaughtException = =>
    net = require('net')
    orgConnect = net.Socket.prototype.connect

    net.Socket.prototype.__defineGetter__('connect', () ->
      # capture stack
      this.__connectStack = new Error("From connect").stack
      # is already setup?
      if this.__emitModified?
        return orgConnect
      orgEmit = this.emit
      this.emit = (args...) ->
        if args.length >= 2 and args[0] is 'error'
          args[1].__trace = this.__connectStack
        return orgEmit.apply(this, args)
      this.__emitModified = true
      return orgConnect
    )
  )()

  initComplete = false
  uncaughtException = (err) ->
    unless err.silent
      trace = (if err.__trace? then err.__trace.toString().replace('Error: ', '\n') else '')
      env.logger.error(
        "A uncaught exception occured: #{err.stack}#{trace}\n
         This is most probably a bug in pimatic or in a module, please report it!"
      )
    if initComplete
      if process.env['PIMATIC_DAEMONIZED']
        env.logger.warn(
          "Keeping pimatic alive, but could be in an undefined state,
           please restart pimatic as soon as possible!"
        )
      else
        env.logger.warn("shutting pimatic down...")
        framework?.destroy().then( -> exit(1) )
    else
      exit(1)

  process.on('uncaughtException', uncaughtException)

  # Setup the framework
  env.framework = (require "#{modulePath}/node_modules/pimatic/lib/framework") env
  return Promise.try( =>
    framework = new env.framework.Framework configFile
    promise = framework.init().then( ->
      initComplete = true

      onKill = ->
        framework.destroy().then( -> exit(0) )

      process.on('SIGINT', onKill)
      process.on('SIGTERM', onKill)

    )

    return promise.then( => framework )
  ).catch( (err) =>
    unless err.silent
      env.logger.error "Startup error: #{err.stack}"
    exit(1)
  )

module.exports.startup = startup
module.exports.env = env

