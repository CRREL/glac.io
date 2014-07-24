d3 = require("d3")
queue = require("queue-async")
config = require("../config")
ts = require("../timeseries")

parseDate = d3.time.format("%Y-%m-%dT%H:%M:%S").parse

module.exports = (callback) ->
    queue()
        .defer(d3.json, "data/timeseries.json")
        .await (error, timeseries) -> locationsReady error, timeseries, callback


locationsReady = (error, data, callback) ->
    # TODO parameterize
    q = queue(3)
    timeseries = data.map (d) ->
        d.development = config.development
        ts.makeTimeseries d
    for t in timeseries
        do (t) -> q.defer (callback) -> t.fetch callback

    q.awaitAll (error, timeseries) -> callback error, timeseries
