# Inspired/modeled after http://windhistory.com
# https://gist.github.com/NelsonMinar/3589712

d3 = require("d3")
fetch = require("./fetch")
ts = require("./timeseries")


container = d3.select "[data-viewer='windrose']"
windDirTsCode = container.attr "data-wind-dir-ts-code"
windSpeedTsCode = container.attr "data-wind-speed-ts-code"
interval = "daily"


width = 400
height = 400
r = 200
padding =
  inner: 34
  outer: 20
barWidth = 5

freqScale = d3.scale.linear()
  .range([padding.inner, r - padding.outer])
  .clamp(true)
freqTickText = (d) -> "#{(d * 100).toFixed(0)}%"
degreeLabels = d3.range(0, 360, 30)
degreeText = (d) -> d


freqArc = d3.svg.arc()
  .startAngle((d) -> (Number(d.key) * 10 - barWidth) * Math.PI / 180)
  .endAngle((d) -> (Number(d.key) * 10 + barWidth) * Math.PI / 180)
  .innerRadius(padding.inner)
  .outerRadius((d) -> freqScale(d.values.freq))

speedColor = d3.scale.linear()
  .range(["hsl(0, 70%, 99%)", "hsl(0, 70%, 40%)"])
  .interpolate(d3.interpolateHsl)

svg = container.append("svg")
  .attr
    width: width
    height: height


timeseries =
  dir: ts.makeTimeseries
    interval: interval
    ts_codes: windDirTsCode
    min: 0
    max: 360
    circular: true
  speed: ts.makeTimeseries
    interval: interval
    ts_codes: windSpeedTsCode
    min: 0

main = () ->
  tsArray = for k, v of timeseries
    v
  fetch.data tsArray, build


build = (error, _) ->
  data = process timeseries.dir.getData()[0], timeseries.speed.getData()[0]
  freqScale.domain([0, d3.max([d3.max(data, (d) -> d.values.freq), 0.15])])
  freqTicks = d3.range(0.025, freqScale.domain()[1], 0.025)
  freqTickLabels = d3.range(0.05, freqScale.domain()[1], 0.05)
  speedColor.domain([0, d3.max(data, (d) -> d.values.speed)])

  freqRose = svg.append("g")
    .attr("class", "frequency-rose")

  freqRose.append("g")
    .attr("class", "axes")
    .selectAll("circle")
    .data(freqTicks)
    .enter()
      .append("circle")
      .attr(
        cx: r
        cy: r
        r: freqScale)

  freqRose.append("g")
    .attr("class", "axes-labels")
    .selectAll("text")
    .data(freqTickLabels)
    .enter()
      .append("text")
      .text(freqTickText)
      .attr("dy", "-2px")
      .attr("transform", (d) -> "translate(#{r},#{r - freqScale(d)})")

  freqRose.append("g")
    .attr("class", "degree-labels")
    .selectAll("text")
    .data(degreeLabels)
    .enter()
      .append("text")
      .text(degreeText)
      .attr("dy", "-4px")
      .attr("transform", (d) -> "translate(#{r},#{padding.outer})" +
        "rotate(#{d},0,#{r - padding.outer})")

  tooltip = d3.select("body")
    .append("rect")
    .attr('class','tooltip')

  freqRose.append("g")
    .attr("class", "arcs")
    .selectAll("path")
    .data(data)
    .enter()
      .append("path")
      .attr("d", freqArc)
      .style("fill", (d) -> speedColor(d.values.speed))
      .attr("transform", "translate(#{r},#{r})")
      .on("mouseover", (d) -> tooltip.text(d3.round(d.values.freq*100,2) + '% - Avg Speed: ' + d3.round(d.values.speed,2)).style("visibility", "visible"))
      .on("mousemove", () -> tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px"))
      .on("mouseout", () -> tooltip.style("visibility", "hidden"))

process = (dir, speed) ->
  data = []
  dirIdx = 0
  for s in speed
    do (s) ->
      if s.value?
        ++dirIdx while dir[dirIdx].date_time < s.date_time
        d = dir[dirIdx]
        if d.date_time.getTime() == s.date_time.getTime() and d.value?
          data.push
            date_time: s.date_time
            year: s.date_time.getFullYear()
            month: s.date_time.getMonth()
            speed: s.value
            dir:  Math.floor(d.value / 10)
          ++dirIdx

  totalCount = 0
  nest = d3.nest()
    .key((d) -> d.dir)
    .rollup((d) ->
      totalCount += d.length
      return {
        count: d.length
        speed: d3.mean(d, (e) -> e.speed)
      })
    .entries(data)

  for n in nest
    do (n) ->
      n.values.freq = n.values.count / totalCount

  return nest


main()
