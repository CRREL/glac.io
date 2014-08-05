d3 = require("d3")
fetch = require("./fetch")


chart = d3.select("#chart")
controls = d3.select("#controls")

margin =
  top: 10
  right: 10
  bottom: 100
  left: 100
padding =
  top: 60
  right: 0
  bottom: 60
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
y2scale = d3.scale.linear().range([height2, 0])

xaxis = d3.svg.axis()
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

  contextLines = context.selectAll(".line").data(timeseries, tsName)
  contextLines.enter().call(addContextLine)
  contextLines.exit().remove()

  fetch.data timeseries, draw


draw = (error, timeseries) ->
  x2scale.domain(d3.extent(d3.merge(d3.extent(t.data, (u) -> u.date_time) for t in timeseries)))
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
    .append("path")
    .attr("class", "line")
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
  loading = panel
    .append("g")
    .attr("class", "loading")
  loading.append("text")
    .attr("text-anchor", "middle")
    .text("loading data")
  loading.append("circle")
    .attr(
      transform: translate(-16, 10)
      cx: 0
      cy: 16
      r: 0)
    .call(animateBubbles, 0)
  loading.append("circle")
    .attr(
      transform: translate(0, 10)
      cx: 0
      cy: 16
      r: 0)
    .call(animateBubbles, 0.3)
  loading.append("circle")
    .attr(
      transform: translate(16, 10)
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
      .attr("transform", translate(width / 2, 50))
      .attr("text-anchor", "middle")
      .text((e) -> e.name)

    if not d.hasData()
      d3.select(this).select(".loading")
        .attr("transform", translate(width / 2, 25 + heights[i] / 2))
      return
    else
      d3.select(this).select(".loading").remove()

    yscale = d3.scale.linear()
      .domain(d3.extent(d.data, (e) -> e.value))
      .range([heights[i] - padding.bottom, padding.top])
      .nice()

    yaxis = d3.svg.axis()
      .scale(yscale)
      .orient("left")
      .ticks(10 / heights.length)

    data = (e for e in d.data when xscale.domain()[0] <= e.date_time <= xscale.domain()[1])
    line = d3.svg.line()
      .x((e) -> xscale(e.date_time))
      .y((e) -> yscale(e.value))
      .defined((e) -> e.value)

    d3.select(this).select(".line")
      .datum(data)
      .attr("d", line)
      .style("stroke", d.color)

    d3.select(this).select(".x.axis")
      .attr("transform", translate(0, heights[i] - padding.bottom))
      .call(xaxis)
      
    d3.select(this).select(".y.axis")
      .call(yaxis)

    d3.select(this).select(".y.label")
      .attr("transform", translate(padding.left + 10, padding.top + 10))
      .text((e) -> e.units)


addContextLine = (sel) ->
  sel
    .append("path")
    .attr("class", "line")


drawContext = (sel) ->
  sel.selectAll(".line").each (d) ->
    yscale = d3.scale.linear()
      .domain(d3.extent(d.data, (e) -> e.value))
      .range([height2, 0])
      .nice()
    line = d3.svg.line()
      .x((e) -> x2scale(e.date_time))
      .y((e) -> yscale(e.value))
      .defined((e) -> e.value)
    d3.select(this).datum(d)
      .attr("d", (e) -> line e.data)
      .style("stroke", (e) -> e.color)

  sel.select(".x.axis")
    .attr("transform", translate(0, height2))
    .call(x2axis)

  sel
    .select(".x.brush")
    .call(brush)


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


fetch.timeseries initialBuild
