assert = require "cassert"

describe "pimatic", ->

  config =
    settings:
      locale: "en"
      httpServer:
        enabled: true
        port: 8080
      httpsServer:
        enabled: false
      database:
        client: "sqlite3"
        connection: {
          filename: ':memory:'
        }
      debug: true
      logLevel: "debug"
    plugins: [
      {
        "plugin": "tradfri",
        "secID": "dummykey",
        "hubIP": "127.0.0.1",
        "active": true,
        "debug": true
      }
    ]
    devices: []
    rules: []
    users: [
      {
        username: "admin",
        password: "test",
        role: "admin"
      }
    ],
    roles: [
      {
        name: "admin",
        permissions: {
          pages: "write",
          rules: "write",
          variables: "write",
          messages: "write",
          events: "write",
          devices: "write",
          groups: "write",
          plugins: "write",
          updates: "write",
          database: "write",
          config: "write",
          controlDevices: true,
          restart: true
        }
      }
    ],
    variables: []

  fs = require 'fs'
  os = require 'os'
  configFile = "#{os.tmpdir()}/pimatic-test-config.json"

  before ->
    fs.writeFileSync configFile, JSON.stringify(config)
    process.env.PIMATIC_CONFIG = configFile

  after ->
    fs.unlinkSync configFile


  framework = null
  deviceConfig = null

  describe 'startup', ->

    it "should startup", (finish) ->
      startup = require('./startup')
      startup.startup().then( (fm)->
        framework = fm
        finish()
      ).catch(finish)
      return

    it "httpServer should run", (done)->
      http = require 'http'
      http.get("http://localhost:#{config.settings.httpServer.port}", (res) ->
        done()
      ).on "error", (e) ->
        throw e
      return

    it "httpServer should ask for password", (done)->
      http = require 'http'
      http.get("http://localhost:#{config.settings.httpServer.port}", (res) ->
        assert res.statusCode is 401 # is Unauthorized
        done()
      ).on "error", (e) ->
        throw e
      return

