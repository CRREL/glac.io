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

  images: (callback) ->
    queue()
      .defer(d3.json, "data/timelapse.json")
      .await (error, cameras) ->
        q = queue()
        for camera in cameras
          do (camera) ->
            q.defer (cb) ->
              options =
                jsonp: true
                callbackName: "jsonp"
              if config.development
                url = uri.parse "/data/development/hubbard-images.js?jsonp=cameraImageList", true
              else
                url = uri.parse camera.listUrl, true
              xhr url, options, (error, data) ->
                camera.images = data.map (d) ->
                  # TODO timezone considerations?
                  d.datetime = new Date(d.datetime)
                  d
                cb error, camera
        q.awaitAll callback
