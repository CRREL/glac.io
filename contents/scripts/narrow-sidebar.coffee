d3 = require "d3"
path = require "path"

imageHeight = 1050

container = d3.select "[data-target='sidebar-images']"
baseUrl = container.attr "data-base-url"
imageListUrl = path.join baseUrl, container.attr "data-image-list"


d3.json imageListUrl, (error, images) ->
  container.selectAll("img").remove()
  rowHeight = Math.floor(
    d3.select(container.node().parentNode)
      .style("height").slice(0, -2))
  nImages = Math.ceil rowHeight / imageHeight
  for i in [1..nImages]
    idx = Math.floor Math.random() * images.length
    container.append("img")
      .attr("src", path.join baseUrl, images[idx])
