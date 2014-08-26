d3 = require("d3")
fetch = require("./fetch.coffee")


class Timelapse

  constructor: (selector, @camera) ->
    @el = d3.select selector
    @links = @el.select ".timelapse-links"
    @viewer = @el.select ".timelapse-viewer"
    @scrubber = @el.select ".timelapse-scrubber"
    @controls = @el.select ".timelapse-controls"
    @context = @el.select ".timelapse-context"
    @playing = false
    @fps = 30
    @timelapseMultiplier = 21600 # number of seconds of timelapse per second
    @forward = true
    @time = d3.time.day.offset(new Date(), -10)
    @width = 620

    @scale =
      scrubber: d3.time.scale()
      context: d3.time.scale()
      images: d3.scale.quantile()

    @viewer.selectAll("img")
      .data(@camera.images)
      .enter()
      .append("img")

    extent = d3.extent(@camera.images, (d) -> d.datetime)
    @scale.scrubber
      .domain([@time, extent[1]])
      .range([0, @width])
    @scale.context
      .domain(extent)
      .range([0, @width])
    @scale.images
      .domain(@camera.images.map (d) -> d.datetime)
      .range(@camera.images.map (d, i) -> i)

    @controls.select(".play-stop")
      .on("click", () => d3.event.preventDefault(); @togglePlayStop())
    @controls.select(".forward-backward")
      .on("click", () => d3.event.preventDefault(); @toggleForwardBackward())

    @loadImages()
    @draw()

  start: () ->
    @playing = true
    @tick()

  stop: () ->
    @playing = false

  getTimeoutDelay: () -> 1000 / @fps

  tick: () ->
    if not @playing then return
    @updateTime()
    @draw()
    setTimeout @tick, @getTimeoutDelay()

  updateTime: () ->
    dt = status.timelapseMultiplier * 1000 * (if status.forward then 1 else -1)
    status.time = new Date(+status.time + dt)
    [start, end] = xscale.domain()
    if status.time > end
      status.time = start
    if status.time < start
      status.time = end

  draw: () ->
    iscale = @scale.images
    @viewer.selectAll("img")
      .style("display", (d, i) ->
        if iscale(status.time) == i then "block" else "none"
      )

    @scrubber.style("width", @scale.scrubber(status.time) + "px")

  togglePlayStop: () ->
    if @playing then @stop() else @start()
    @controls.select(".play-stop")
      .classed("glyphicon-play", not @playing)
      .classed("glyphicon-stop", @playing)

  toggleForwardBackward: () ->
    @forward = not @forward
    @controls.select(".forward-backward")
      .classed("glyphicon-forward", @forward)
      .classed("glyphicon-backward", not @forward)

  loadImages: () ->
    domain = @scale.scrubber.domain
    imageBaseUrl = @camera.imageBaseUrl
    @viewer.selectAll("img")
      .each (d) ->
        if d3.select(this).attr("src")
          return
        else if domain()[0] <= d.datetime <= domain()[1]
          d3.select(this)
            .attr("src", imageBaseUrl + d.path)


fetch.images (error, cameras) ->
  tl = new Timelapse(".timelapse", cameras[0])
