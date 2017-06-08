module.exports = {
  title: "tradfri config options"
  type: "object"
  required: ["secID", "hubIP", "rampup"]
  properties:
    secID:
      description: "Security ID"
      type: "string"
      required: yes
    hubIP:
      description: "Hub IP"
      type: "string"
      required: yes
    rampup:
      description: "rampup delay"
      type: "integer"
      required: yes
    debug:
      description: "debug switch"
      type: "boolean"
      required: no
}
