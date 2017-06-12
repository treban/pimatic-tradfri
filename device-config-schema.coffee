module.exports = {
  title: "Tradfri Devices"
  TradfriDimmer: {
    title: "Tradfri Dimmer Device"
    type: "object"
    properties:
      address:
        description: "Tradfri address"
        type: "integer"
  },
  TradfriGroup: {
    title: "Tradfri Dimmer Device"
    type: "object"
    properties:
      address:
        description: "Tradfri group address"
        type: "integer"
  },
  TradfriHub: {
    title: "Tradfri Gateway Device"
    type: "object"
    properties:
      ntpserver:
        description: "Gateway ntp server"
        type: "string"
  }
  TradfriMotion: {
    title: "Tradfri Motion Device"
    type: "object"
    properties:
      address:
        description: "Tradfri address"
        type: "integer"
  }
}
