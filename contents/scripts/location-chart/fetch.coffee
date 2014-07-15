d3 = require("d3")
queue = require("queue-async")
xhr = require("xhr-browserify")
url = require("url")

config = require("../config")

parseDate = d3.time.format("%Y-%m-%dT%H:%M:%S").parse

findLocation = (locations, slug) ->
    for location in locations.features
        return location if location.properties.slug is slug


module.exports = (callback) ->
    queue()
        .defer(d3.json, config.baseUrl + "/data/locations.json")
        .await (error, locations) -> locationsReady error, locations, callback


locationsReady = (error, locations, callback) ->
    location = findLocation locations, config.slug
    timeseries = location.properties.timeseries

    # TODO parameterize
    q = queue(3)
    for t in timeseries
        do (t) ->
            q.defer (callback) ->
                getTimeseriesData t, callback

    q.awaitAll (error, results) ->
        for [t, d] in d3.zip(timeseries, results)
            do (t, d) ->
                t.data = processTimeseriesData d
        callback null, location


getTimeseriesData = (timeseries, callback) ->
    u = url.parse(
        if config.development then timeseries.developmentUrl else timeseries.url,
        true)
    options =
        jsonp: true
        callbackName: "jsonp"
    return xhr u, options, (error, results) ->
        callback error, results


processTimeseriesData = (data) ->
    timeScale = d3.time.scale()
        .domain(d3.extent data.map (d) -> parseDate(d.date_time))
            # TODO not all data will be coming in on the day
            .ticks(d3.time.day, 1)

    reducer = (p, c) ->
        value = if parseDate(data[0].date_time) <= c then data.shift().value else null
        d =
            date_time: c
            value: value
        p.concat(d)

    data = timeScale.reduce reducer, []
