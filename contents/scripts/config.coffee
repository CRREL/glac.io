config = JSON.parse document.getElementById("glacio-config").innerHTML

config.url = (s) ->
  url = config.baseUrl + s
  if url.indexOf("//") == 0 then url[1..] else url

module.exports = config
