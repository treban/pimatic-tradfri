module.exports = {
  title: "Tradfri Devices"
  TradfriDimmer: {
    title: "Tradfri Dimmer Device"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      address:
        description: "Tradfri address"
        type: "integer"
  }
}
