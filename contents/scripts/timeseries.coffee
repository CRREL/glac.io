d3 = require("d3")
uri = require("url")
xhr = require("xhr-browserify")

parseDate = d3.time.format("%Y-%m-%dT%H:%M:%S").parse
# http://coffeescriptcookbook.com/chapters/arrays/check-type-is-array
typeIsArray = Array.isArray || ( value ) -> return {}.toString.call(value) is "[object Array]"


module.exports =
  makeTimeseries: (options) ->
    klass = switch options.type
      when "cwms"
        CwmsTimeseries
      else
        throw "Unknown timeseries type"
    new klass options


class Timeseries

  constructor: (options) ->
    {@name, @visible, @color, @units, @development, @developmentUrl} = options
    @productionUrl = @buildProductionUrl()

  fetch: (callback) ->
    if @development and not @developmentUrl
      @setData []
      return callback null, this
    options =
      jsonp: true
      callbackName: "jsonp"
    return xhr @getUrl(), options, (error, results) =>
      @setData @processData results
      callback error, this

  getUrl: () ->
    s = if @development then @developmentUrl else @productionUrl
    uri.parse(s, true)

  setData: (@data) ->

  hasData: () -> @data?

  processData: (data) ->
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

    timeScale.reduce reducer, []

  buildProductionUrl: () -> throw "Not implemented"


class CwmsTimeseries extends Timeseries

  constructor: (options) ->
    {@ts_codes, @floor} = options
    if not typeIsArray @ts_codes
      @ts_codes = [@ts_codes]
    super options

  buildProductionUrl: () ->
    url = "http://nae-rrs2.usace.army.mil:7777/pls/cwmsweb/jsonapi.timeseriesdata?ts_codes=#{ @ts_codes.join(",") }"
    if @floor
      url += "&floor=#{ @floor }"
    # TODO handle summary interval changes
    url += "&summary_interval=daily"
    return url
