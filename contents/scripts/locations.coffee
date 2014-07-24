d3 = require("d3")
queue = require("queue-async")
topojson = require("topojson")
config = require("./config")

width = 400
height = 400
defaultScale = width / 2 - 10
initialRotation = [120, 0]
transitionDuration = 1000
unfocusedPointSize = 5
unfocusedPointColor = "steelblue"
focusedPointSize = 10
focusedPointColor = "red"

projection = d3.geo.orthographic()
    .scale(defaultScale)
    .translate([width / 2, height / 2])
    .clipAngle(90)

path = d3.geo.path()
    .projection(projection)

svg = d3.select("#globe").append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("class", "center-block")

features = svg.append("g")

sphere = features.append("path")
    .datum(type: "Sphere")
    .attr("id", "sphere")
    .attr("d", path)

ddToDms = (dd, latOrLon) ->
    format = d3.format ".3f"
    ddp = Math.abs dd
    d = Math.floor ddp
    m = Math.floor (ddp % 1) * 60
    s = (((ddp % 1) * 60) % 1) * 60
    if latOrLon == "lat"
        suffix = if dd > 0 then "N" else "S"
    else
        suffix = if dd > 0 then "E" else "W"
    return "#{ d }&deg;#{ m }'#{ format(s) }\"#{ suffix }"

formatLatLong = (p) -> "#{ ddToDms(p[1], "lat") }, #{ ddToDms(p[0], "lon") }"

updateLocationDetail = () ->
    sel = d3.select("#location-detail").selectAll(".location-detail")
    locations = sel.data()
    d3.select("#sensors").style("display", if locations.some((d) -> d.focused) then "none" else "block")
    sel.style("display", (d) -> if d.focused then "block" else "none")


ready = (error, sensors, world, locations) ->
    land = topojson.feature(world, world.objects.land)

    appendSensorList = (d) ->
        d.enter()
            .append("li")
            .attr("class", "media")
            .each((e) ->
                d3.select(this)
                    .append("a")
                    .attr("class", "pull-left")
                    .append("img")
                    .attr("class", "media-object")
                    .attr("src", (f) -> config.url("/img/sensor-icons/") + sensors[e].filename)
                d3.select(this)
                    .append("div")
                    .attr("class", "media-body")
                    .each((f) ->
                        d3.select(this)
                            .append("h4")
                            .attr("class", "media-heading")
                            .text((g) -> sensors[g].name)
                        d3.select(this)
                            .append("p")
                            .text((g) -> sensors[g].description)
                    )
            )


    d3.select("#locations").selectAll("a")
        .data(locations.features).enter()
        .append("a")
        .attr("class", "list-group-item")
        .attr("href", (d) ->
            if d.properties.disabled? then "#" else d.properties.slug + "/")
        .text((d) ->
            d.properties.name +
            (if d.properties.disabled? then " (disabled)" else ""))
        .on("mouseover", (d) -> focus(d))
        .on("mouseout", (d) -> unfocus(d))

    d3.select("#sensors")
        .append("ul")
        .attr("class", "media-list")
        .selectAll(".media")
        .data(Object.keys(sensors))
        .call(appendSensorList)

    d3.select("#location-detail").selectAll(".location-detail")
        .data(locations.features).enter()
        .append("div")
        .attr("class", "location-detail")
        .style("display", "none")
        .each((d) ->
            e = d3.select(this)
            e.append("h3")
                .text(d.properties.name)
            e.append("h4")
                .text("Coordinates")
            e.append("div")
                .html formatLatLong d.geometry.coordinates
            if d.properties.sensors
                e.append("h4")
                    .text("Sensors")
                e.append("ul")
                    .attr("class", "media-list")
                    .selectAll(".media")
                    .data((d) -> d.properties.sensors)
                    .call(appendSensorList)
        )

    features.insert("path")
        .datum(land)
        .attr("class", "land")
        .attr("d", path)

    features.selectAll(".location")
        .data(locations.features).enter()
        .append("path")
        .attr("class", "location")
        .attr("fill", unfocusedPointColor)
        .attr("d", (d) -> path.pointRadius(unfocusedPointSize)(d))

    projection.rotate initialRotation
    features.selectAll(".land").attr("d", path)
    features.selectAll(".location").attr("d", path)


focus = (location) ->
    location.focused = true

    updateLocationDetail()
    d3.transition()
        .duration(transitionDuration)
        .tween("rotate", () ->
            p = location.geometry.coordinates
            r = d3.interpolate projection.rotate(), [-p[0], -p[1]]
            z = d3.interpolate(projection.scale(), location.properties.scale)
            s = d3.interpolate(unfocusedPointSize, focusedPointSize)
            c = d3.interpolate(unfocusedPointColor, focusedPointColor)
            return (t) ->
                projection.rotate r t
                projection.scale z t
                features.selectAll(".land").attr("d", path)
                features.selectAll(".location")
                    .style("fill", (d) ->
                        if d.focused then c(t) else unfocusedPointColor)
                    .attr("d", (d) ->
                        if d.focused
                            path.pointRadius(s(t))(d)
                        else
                            path.pointRadius(unfocusedPointSize)(d)
                    )
                sphere.attr("d", path)
        )

unfocus = (location) ->
    location.focused = false
    updateLocationDetail()


queue()
    .defer(d3.json, config.url("/data/sensors.json"))
    .defer(d3.json, config.url("/data/world-110m.json"))
    .defer(d3.json, config.url("data/locations.json"))
    .await ready
