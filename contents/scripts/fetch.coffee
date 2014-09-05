d3 = require("d3")
queue = require("queue-async")
uri = require("url")
xhr = require("xhr-browserify")
config = require("./config")
ts = require("./timeseries")

parseDate = d3.time.format("%Y-%m-%dT%H:%M:%S").parse

module.exports =
  timeseries: (callback) ->
    queue()
      .defer(d3.json, "data/timeseries.json")
      .await (error, data) ->
        callback error, data.map (d) ->
          d.development = config.development
          ts.makeTimeseries d

  data: (timeseries, callback) ->
    # TODO parameterize
    q = queue(3)
    for t in timeseries
      do (t) ->
        if not t.hasData()
          q.defer (callback) -> t.fetch callback
    q.awaitAll (error) -> callback error, timeseries

  images: (cameraUrl, callback) ->
    queue()
      .defer (cb) ->
        options =
          jsonp: true
          callbackName: "jsonp"
        url = uri.parse cameraUrl, true
        xhr url, options, (error, data) ->
          images = data.map (d) ->
            # TODO timezone considerations?
            d.datetime = new Date(d.datetime)
            d
          cb error, images
      .await callback
