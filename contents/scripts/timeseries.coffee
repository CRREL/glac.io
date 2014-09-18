d3 = require("d3")
queue = require("queue-async")
uri = require("url")
xhr = require("xhr-browserify")


DEFAULT_INTERVAL = "daily"

parseDate = d3.time.format("%Y-%m-%dT%H:%M:%S").parse
# http://coffeescriptcookbook.com/chapters/arrays/check-type-is-array
typeIsArray = Array.isArray || ( value ) ->
  return {}.toString.call(value) is "[object Array]"


module.exports =
  makeTimeseries: (options) ->
    new Timeseries options


class Timeseries

  constructor: (options) ->
    {@name, @visible, @units, @min, @max, @floor} = options
    @interval = options.interval ? DEFAULT_INTERVAL
    if options.ts_codes?
      if options.series?
        throw new Error("Cannot specify ts_codes and series")

      @series = [
        name: @name
        ts_codes: options.ts_codes
        color: options.color
      ]
    else if options.series
      @series = options.series
    else
      throw new Error("Must specify either ts_codes or series")

    for ts in @series
      do (ts) ->
        if not typeIsArray(ts.ts_codes)
          ts.ts_codes = [ts.ts_codes]
        ts.data = {}

    @_loaded = {}

  fetch: (callback) ->
    options =
      jsonp: true
      callbackName: "jsonp"
    q = queue()
    for ts in @series
      do (ts) =>
        q.defer (cb) =>
          xhr @getUrl(ts), options, (error, results) =>
            ts.data[@interval] = @processData results.map (d) ->
              d.date_time = parseDate d.date_time
              d
            cb error
    q.awaitAll (error) =>
      @_loaded[@interval] = true
      callback error, @

  getUrl: (ts) ->
    url = "http://nae-rrs2.usace.army.mil:7777/" +
      "pls/cwmsweb/jsonapi.timeseriesdata?ts_codes=#{ ts.ts_codes.join(",") }"
    if @floor
      url += "&floor=#{ @floor }"
    # TODO handle summary interval changes
    url += "&summary_interval=" + @interval
    uri.parse(url, true)

  hasData: () -> @_loaded[@interval]

  getData: (minTime, maxTime) ->
    @getSeries(minTime, maxTime).map (d) -> d.data

  getSeries: (minTime, maxTime) ->
    if not minTime?
      minTime = new Date(0)
    if not maxTime?
      maxTime = d3.time.year.offset(new Date(), 1)
    return @series.map (ts) =>
      series =
        data:
          (e for e in ts.data[@interval] when minTime <= e.date_time <= maxTime)
        color: ts.color
        name: ts.name
      return series

  processData: (data) ->
    d3interval = switch @interval
      when "daily" then d3.time.day
      when "hourly" then d3.time.hour
      else throw Error("Invalid interval: " + @interval)

    timeScale = d3.time.scale()
      .domain(d3.extent data.map (d) -> d.date_time)
        .ticks(d3interval, 1)

    reducer = (p, c) ->
      value = if data[0].date_time <= c
        data.shift().value
      else
        null
      d =
        date_time: c
        value: value
      p.concat(d)

    timeScale.reduce reducer, []
