url = require("url")

config = JSON.parse document.getElementById("glacio-config").innerHTML

config.url = (s) -> url.resolve(config.baseUrl, s)

module.exports = config
