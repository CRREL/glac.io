d3 = require("d3")
fetch = require("./fetch")


container = d3.select "[data-viewer='timeseries-chart']"
timeseriesUrl = container.attr "data-timeseries-url"

chart = container.select ".timeseries-chart-chart"
controls = container.select ".timeseries-chart-controls"

margin =
  top: 10
  right: 10
  bottom: 100
  left: 100
padding =
  top: 20
  right: 0
  bottom: 40
  left: 0
margin2 =
  top: 500
  right: 10
  bottom: 20
  left: 100
width = 945 - margin.left - margin.right
height = 600 - margin.top - margin.bottom
height2 = 600 - margin2.top - margin2.bottom

defaultBrushExtent = [
  d3.time.month.offset(new Date(), -2)
  new Date()
]
translate = (x, y) -> "translate(#{x},#{y})"
emptyAxis = () -> d3.svg.axis().tickValues([]).outerTickSize(0)
tsName = (t) -> t.name

visibleTimeseries = () ->
  (c for c in controls.selectAll(".control").data() when c.visible)


xscale = d3.time.scale().range([0, width])
x2scale = d3.time.scale().range([0, width])

xaxis = d3.svg.axis()
  .scale(xscale)
  .orient("bottom")
xgrid = d3.svg.axis()
  .scale(xscale)
  .orient("bottom")
x2axis = d3.svg.axis()
  .scale(x2scale)
  .orient("bottom")

svg = chart.append("svg")
  .attr("width", width + margin.left + margin.right)
  .attr("height", height + margin.top + margin.bottom)

focus = svg.append("g")
  .attr("class", "focus")
  .attr("transform", translate(margin.left, margin.top))

context = svg.append("g")
  .attr("class", "context")
  .attr("transform", translate(margin2.left, margin2.top))

context
  .append("defs")
  .append("pattern")
  .attr("id", "dimples")
  .attr("x", 1)
  .attr("y", 1)
  .attr("width", 3)
  .attr("height", 3)
  .attr("patternUnits", "userSpaceOnUse")
  .append("circle")
  .attr("cx", 1)
  .attr("cy", 1)
  .attr("r", 1)

brush = d3.svg.brush()
  .x(x2scale)
  .on("brush", (d) ->
    if brush.empty()
      brush.extent x2scale.domain()
      context.select(".brush")
        .call(brush)
        .call(brush.event)
    else
      xscale.domain brush.extent()
      focus.call(drawFocus)
      context.call(drawContext)
  )


initialBuild = (error, timeseries) ->
  diagramLink = controls.append("a")
    .attr("class", "climate-station-diagram-link")
    .attr("href", "climate-station-diagram.html")
  diagramLink.append("span")
    .attr("class", "glyphicon glyphicon-info-sign")
  diagramLink.append("span")
    .text(" Climate Station Diagram")
  control = controls.selectAll(".control").data(timeseries)
  control
    .enter()
    .append("a")
    .attr("href", "#")
    .attr("class", "list-group-item control")
    .on("click", toggleControl)
  control
    .append("span")
    .attr("class", "glyphicon")
  control
    .append("span")
    .text((d) -> " #{ d.name }")
  controls
    .call(drawControls)

  chart
    .append("p")
    .attr("class", "text-center")
    .append("span")
    .attr("class", "daterange")

  context
    .append("g")
    .attr("class", "x axis bottom")
  context
    .append("g")
    .attr("class", "x brush")
    .call(brush)
    .selectAll("rect")
    .attr("height", height2)
    .attr("rx", 10)
    .attr("ry", 10)
  context
    .select(".x.brush")
    .selectAll(".resize")
    .append("rect")
    .attr("height", height2)
    .attr("width", 20)
    .attr("rx", 10)
    .attr("ry", 10)
    .attr("transform", (d, i) -> if i == 0 then "translate(-20,0)" else "")

  brush.extent defaultBrushExtent

  update()


update = () ->
  timeseries = visibleTimeseries()

  panels = focus.selectAll(".panel").data(timeseries, tsName)
  panels.enter().call(addPanel)
  panels.exit().remove()
  focus.call(drawFocus)

  contextLines = context.selectAll(".lineset").data(timeseries, tsName)
  contextLines.enter().call(addContextLineset)
  contextLines.exit().remove()

  fetch.data timeseries, draw


draw = (error, timeseries) ->
  x2scale.domain(
    d3.extent(
      d3.merge(d3.merge(t.getData() for t in timeseries)),
      (d) -> d.date_time))
  oldBrushExtent = brush.extent()
  brush.extent [
    d3.max([oldBrushExtent[0], x2scale.domain()[0]]),
    d3.min([oldBrushExtent[1], x2scale.domain()[1]])
  ]
  context
    .select(".x.brush")
    .call(brush)
    .call(brush.event)


toggleControl = (d) ->
  # TODO don't let the user turn off the last graph
  d3.event.preventDefault()
  d.visible = not d.visible
  controls.call(drawControls)
  update()


drawControls = (sel) ->
  sel.selectAll(".control")
    .classed("active", (d) -> d.visible)
    .select(".glyphicon")
    .attr("class", (d) ->
      "glyphicon #{
        if d.visible then "glyphicon-eye-open" else "glyphicon-eye-close"
      }")


addPanel = (sel) ->
  panel = sel
    .append("g")
    .attr("class", "panel")
  panel
    .append("rect")
    .attr("class", "fill")
    .style("fill", "rgb(236, 236, 236)")
  panel
    .append("g")
    .attr("class", "x grid")
  panel
    .append("g")
    .attr("class", "y grid")
  panel
    .append("g")
    .attr("class", "x axis")
  panel
    .append("g")
    .attr("class", "y axis")
  panel
    .append("text")
    .attr("class", "title")
  panel
    .append("text")
    .attr("class", "y label")
  panel
    .append("text")
    .attr("class", "series label")
  loading = panel
    .append("g")
    .attr("class", "loading")
  loading.append("text")
    .attr("text-anchor", "middle")
    .text("loading data")
  loading.append("circle")
    .attr(
      transform: translate(-16, 6)
      cx: 0
      cy: 16
      r: 0)
    .call(animateBubbles, 0)
  loading.append("circle")
    .attr(
      transform: translate(0, 6)
      cx: 0
      cy: 16
      r: 0)
    .call(animateBubbles, 0.3)
  loading.append("circle")
    .attr(
      transform: translate(16, 6)
      cx: 0
      cy: 16
      r: 0)
    .call(animateBubbles, 0.6)


drawFocus = (sel, heights) ->
  if not heights?
    visible = visibleTimeseries()
    heights = (height / visible.length for t in visible)
  dy = (i) -> if i is 0 then 0 else d3.sum(heights[0..i-1])

  sel.selectAll(".panel").each (d, i) ->
    d3.select(this)
      .attr("transform", translate(0, dy(i)))

    d3.select(this).select(".title")
      .attr("transform", translate(width / 2, 10))
      .attr("text-anchor", "middle")
      .text((e) -> e.name)

    d3.select(this).select(".fill")
      .attr(
        width: width
        height: heights[i] - padding.bottom - padding.top
        x: 0
        y: padding.top)
    if not d.hasData()
      d3.select(this).select(".loading")
        .attr("transform", translate(width / 2, heights[i] / 2))
      return
    else
      d3.select(this).select(".loading").remove()

    yscale = d3.scale.linear()
      .domain(getYExtent(d))
      .range([heights[i] - padding.bottom, padding.top])
      .clamp(true)

    yaxis = d3.svg.axis()
      .scale(yscale)
      .orient("left")
      .ticks(10 / heights.length)

    [minTime, maxTime] = xscale.domain()
    series = d.getSeries(minTime, maxTime)

    line = d3.svg.line()
      .x((e) -> xscale(e.date_time))
      .y((e) -> yscale(e.value))
      .defined((e) -> e.value)

    lines = d3.select(this).selectAll(".line")
      .data(series)
    lines.enter()
      .append("path")
      .attr("class", "line")
    lines
      .attr("d", (e) -> line e.data)
      .style("stroke", (e) -> e.color)
    lines.exit().remove()

    d3.select(this).select(".x.axis")
      .attr("transform", translate(0, heights[i] - padding.bottom))
      .call(xaxis)

    d3.select(this).select(".x.grid")
      .attr("transform", translate(0, heights[i] - padding.bottom))
      .call(xgrid
        .tickSize(-heights[i] + padding.bottom + padding.top, 0)
        .tickFormat(""))

    d3.select(this).select(".y.axis")
      .call(yaxis)

    d3.select(this).select(".y.grid")
      .call(yaxis
        .tickSize(-width, 0)
        .tickFormat(""))

    d3.select(this).select(".y.label")
      .attr("transform", translate(padding.left + 10, padding.top - 6))
      .text((e) -> e.units)

    if series.length > 1
      labels = d3.select(this).select(".series.label")
        .attr("transform", translate(width - padding.right, padding.top - 6))
        .selectAll("tspan")
        .data(series)
      labels.enter()
        .append("tspan")
      labels
        .style("fill", (s) -> s.color)
        .each((l, i) ->
          text = l.name
          if i < series.length - 1
            text += ", "
          d3.select(this).text text)
      labels.exit().remove()


addContextLineset = (sel) ->
  sel
    .append("g")
    .attr("class", "lineset")


parseDate = (predate) ->
  [dow, date..., time, timezone, timezone2] = predate.split(" ")
  return (date[1] + " " + date[0] + " " + date[2])

drawContext = (sel) ->
  sel.selectAll(".lineset").each (d) ->
    yscale = d3.scale.linear()
      .domain(getYExtent(d))
      .range([height2, 0])
      .nice()
      .clamp(true)

    line = d3.svg.line()
      .x((e) -> x2scale(e.date_time))
      .y((e) -> yscale(e.value))
      .defined((e) -> e.value)

    lines = d3.select(this).selectAll(".line")
      .data(d.getSeries())

    lines.enter()
      .append("path")
      .attr("class", "line")

    lines
      .attr("d", (e) -> line e.data)
      .style("stroke", (e) -> e.color)

    lines.exit().remove()

  sel.select(".x.axis")
    .attr("transform", translate(0, height2))
    .call(x2axis)

  sel
    .select(".x.brush")
    .call(brush)

  minDate = parseDate(xscale.domain()[0].toString(), )
  maxDate = parseDate(xscale.domain()[1].toString())

  chart
    .select(".daterange")
    .text("Date Range: " + minDate + " - " + maxDate)

animateBubbles = (circle, begin) ->
  circle.append("animate")
    .attr(
      attributeName: "r"
      values: "0; 4; 0; 0"
      dur: "1.2s"
      repeatCount: "indefinite"
      begin: begin
      keytimes: "0;0.2;0.7;1"
      keySplines: "0.2 0.2 0.4 0.8;0.2 0.6 0.4 0.8;0.2 0.6 0.4 0.8"
      calcMode: "spline"
    )


getYExtent = (timeseries) ->
  extent = d3.extent(d3.merge(timeseries.getData()), (e) -> e.value)
  if timeseries.min?
    extent[0] = d3.max([extent[0], timeseries.min])
  if timeseries.max?
    extent[1] = d3.min([extent[1], timeseries.max])
  return extent


fetch.timeseries timeseriesUrl, initialBuild
