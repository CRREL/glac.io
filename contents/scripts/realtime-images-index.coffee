d3 = require "d3"
imagesloaded = require "imagesloaded"


container = d3.select ".realtime-images-index"

container.selectAll(".thumbnail")
  .classed("loading", true)

imgload = imagesloaded container.node()

imgload.on "progress", (instance, image) ->
  d3.select(image.img.parentNode)
    .classed("loading", false)
