module.exports = {
  title: "tradfri config options"
  type: "object"
  required: ["secID"]
  properties:
    secID:
      description: "Security ID"
      type: "string"
      required: yes
    hubIP:
      description: "Hub IP"
      type: "string"
      default: ""
      required: no
    identity:
      description: "generated at first connect"
      type: "string"
      required: no
    psk:
      description: "generated at first connect"
      type: "string"
      required: no
    debug:
      description: "debug switch"
      type: "boolean"
      required: no
}
