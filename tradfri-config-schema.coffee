module.exports = {
  title: "tradfri config options"
  type: "object"
  required: ["secID", "hubIP"]
  properties:
    secID:
      description: "Security ID"
      type: "string"
      required: yes
    hubIP:
      description: "Hub IP"
      type: "string"
      required: yes
    debug:
      description: "debug switch"
      type: "boolean"
      required: no
}
