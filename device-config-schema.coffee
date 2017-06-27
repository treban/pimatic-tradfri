module.exports = {
  title: "Tradfri Devices"
  TradfriDimmer: {
    title: "Tradfri Dimmer Device"
    type: "object"
    properties:
      address:
        description: "Tradfri address"
        type: "integer"
      transtime:
        description: "Tradfri transtime"
        type: "integer"
        default: 5
  },
  TradfriGroup: {
    title: "Tradfri Dimmer Group"
    type: "object"
    properties:
      address:
        description: "Tradfri group address"
        type: "integer"
      transtime:
        description: "Tradfri transtime"
        type: "integer"
        default: 5
  },
  TradfriHub: {
    title: "Tradfri Gateway Device"
    type: "object"
    properties:
      ntpserver:
        description: "Gateway ntp server"
        type: "string"
  },
  TradfriActor: {
    title: "Tradfri Remote/MotionSensor"
    type: "object"
    properties:
      address:
        description: "Tradfri address"
        type: "integer"
  },
  TradfriScene: {
    title: "Tradfri Scene Group"
    type: "object"
    properties:
      address:
        description: "Tradfri group address"
        type: "integer"
      buttons:
        description: "Scenes to display"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            id:
              type: "string"
            text:
              type: "string"
            address:
              description: "scene address"
              type: "integer"
  }
}
