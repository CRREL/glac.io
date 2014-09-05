d3 = require("d3")
fetch = require("./fetch")
moment = require("moment")


translate = (x, y) -> "translate(" + x + "," + y + ")"

width = 100
height = 600
margin =
  top: 40
  bottom: 30
  right: 20
  left: 100
controlImageHeight = 20
controlImageWidth = 40

container = d3.select "[data-viewer='realtime-images']"
cameraUrl = container.attr("data-camera-url")
imageBaseUrl = container.attr("data-image-base-url")

viewer = container.select(".realtime-images-viewer")
viewer.append("p")
  .attr("class", "description")
viewer.append("img")
  .attr("class", "img-responsive")

controls = d3.select(".realtime-images-controls")
  .append("svg")
  .attr(
    height: height + margin.top + margin.bottom
    width: width + margin.left + margin.right
  )


timeFormat = d3.time.format.multi [
  ["%-I %p", (d) -> d.getHours()]
  ["%_d-%b-%Y", (d) -> true]
]
yscale = d3.time.scale()
  .range([height, 0])
yaxis = d3.svg.axis()
  .scale(yscale)
  .orient("left")
  .ticks(d3.time.hour, 6)
  .tickFormat(timeFormat)


build = (error, images) ->
  images = images.sort((a, b) -> b.datetime - a.datetime).slice(0, 20)
  yscale.domain(d3.extent(images, (d) -> d.datetime))
  interval = (yscale.domain()[1] - yscale.domain()[0]) / (1000 * 60 * 60 * 24)
  if interval > 50
    yaxis.ticks d3.time.year
  else if interval > 10
    yaxis.ticks d3.time.day
  images[0].active = true

  update = () ->
    activeImage = images.filter((d) -> d.active)[0]
    viewer.select(".description")
      .html("This picture was taken " + moment(activeImage.datetime).fromNow() +
        " on " + moment(activeImage.datetime).format("MMMM Do, YYYY [at] ha") +
        ".")
    viewer.select("img").datum(activeImage)
      .attr("src", (d) -> imageBaseUrl + d.path)
    controls.selectAll("rect")
      .classed("active", (d) -> d.active)

  getActiveIndex = () ->
    for i, image of images
      return Number(i) if image.active

  nextImage = () ->
    activate d3.max([getActiveIndex() - 1, 0])

  prevImage = () ->
    activate d3.min([getActiveIndex() + 1, images.length - 1])

  activate = (idx) ->
    images.forEach((d, i) ->
      d.active = (i == idx))
    update()

  controls.append("g")
    .attr("class", "axis")
    .attr("transform", translate(margin.left, margin.top))
    .call(yaxis)

  imageContainer = controls.append("g")
    .attr("class", "images")
    .attr("transform", translate(margin.left, margin.top))

  imageContainer.selectAll("image")
    .data(images)
    .enter()
    .append("image")
    .attr(
      x: 4
      height: controlImageHeight
      width: controlImageWidth)
    .attr("y", (d) -> yscale(d.datetime))
    .attr("xlink:href", (d) -> imageBaseUrl + d.path)
    .on("click", (d) ->
      images.forEach((i) -> i.active = i.path == d.path)
      update())

  imageContainer.selectAll("rect")
    .data(images)
    .enter()
    .append("rect")
    .attr(
      x: 4
      height: controlImageHeight
      width: controlImageWidth)
    .attr("y", (d) -> yscale(d.datetime))

  d3.select("body")
    .on("keydown", () ->
      d3.event.preventDefault()
      if d3.event.keyCode in [40, 39, 83, 68, 74, 76]
        prevImage()
      else if d3.event.keyCode in [38, 37, 87, 65, 75, 72]
        nextImage()
      )

  d3.select(".arrow.left")
    .on("click", prevImage)
  d3.select(".arrow.right")
    .on("click", nextImage)

  update()


fetch.images cameraUrl, build
