url = require("url")

config = JSON.parse document.getElementById("glacio-config").innerHTML

config.url = (s) -> url.parse(config.baseUrl + s).href

module.exports = config
