var width = 400,
    height = 400,
    defaultScale = width / 2 - 10;

var projection = d3.geo.orthographic()
    .scale(defaultScale)
    .translate([width / 2, height / 2])
    .clipAngle(90);

var path = d3.geo.path().projection(projection);

var svg = d3.select("#globe").append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("class", "center-block");

var features = svg.append("g");

var detail = d3.select("#detail"),
    locationList = d3.select("#locations"),
    sensorInfo = detail.append("div").attr("id", "#sensorInfo");

var sphere = features.append("path")
    .datum({type: "Sphere"})
    .attr("id", "sphere")
    .attr("d", path);

queue()
    .defer(d3.json, "../data/sensors.json")
    .defer(d3.json, "../data/world-110m.json")
    .defer(d3.json, "../data/locations.json")
    .await(ready);


function dataSlug(d) {
    return d.properties.slug;
}

function locationPointPath(l) {
    return path.pointRadius(selectPointBySlug(l).classed("focused") ? 10 : 5)(l);
}

function selectPointBySlug(location_) {
    return features.select(".location[data-slug=" + location_.properties.slug + "]");
}

function selectDetailBySlug(location_) {
    return detail.select("[data-slug=" + location_.properties.slug + "]");
}

function prettyLatLong(coordinates) {
    return ddToDms(coordinates[1], "lat") + ", " + ddToDms(coordinates[0], "lon");
}

function mouseoverLocation() {
    var l = d3.select(this).datum();
    focusGlobe(l);
    selectPointBySlug(l).classed("focused", true);
    selectDetailBySlug(l).style("display", "block");
    sensorInfo.style("display", "none");
}

function mouseoutLocation() {
    selectPointBySlug(d3.select(this).datum()).classed("focused", false);
    selectDetailBySlug(d3.select(this).datum()).style("display", "none");
    sensorInfo.style("display", "block");
}

function focusGlobe(l) {
    d3.transition()
        .duration(1500)
        .tween("rotate", function() {
            var p = l.geometry.coordinates,
                r = d3.interpolate(projection.rotate(), [-p[0], -p[1]]),
                z0 = projection.scale(),
                z1 = l.properties.scale;
            return function(t) {
                projection.rotate(r(t));
                projection.scale((1 - t) * z0 + t * z1);
                features.selectAll("path.land").attr("d", path);
                features.selectAll("path.location").attr("d", locationPointPath);
                sphere.attr("d", path);
            };
        });
};

function appendSensorList(selection, sensors) {
    selection.enter().append("li")
            .attr("class", "media");
    selection.append("a")
        .attr("class", "pull-left")
        .append("img")
        .attr("class", "media-object")
        .attr("src", function(d) { return "../img/sensor-icons/" + sensors[d].filename; });
    var mediaBody = selection.append("div")
        .attr("class", "media-body");
    mediaBody.append("h4")
        .text(function(d) { return sensors[d].name; });
    mediaBody.append("p")
        .text(function(d) { return sensors[d].description; });
}

function ready(error, sensors, world, locations) {
    var land = topojson.feature(world, world.objects.land);

    locationList.selectAll("a").data(locations.features)
        .enter().append("a")
            .text(function(l) { return l.properties.name + (l.properties.disabled ? " (disabled)" : ""); })
            .attr("class", "list-group-item")
            .attr("href", function(l) { return l.properties.disabled ? "#" : l.properties.slug + "/" })
            .on("mouseover", mouseoverLocation)
            .on("mouseout", mouseoutLocation);

    features.insert("path")
        .datum(land)
        .attr("class", "land")
        .attr("d", path);

    features.selectAll(".location").data(locations.features)
        .enter().append("path")
            .attr("class", "location")
            .attr("data-slug", dataSlug)
            .attr("d", locationPointPath);

    var locationDetail = detail.selectAll(".location-detail")
            .data(locations.features)
        .enter().append("div")
            .attr("class", "location-detail")
            .style("display", "none")
            .attr("data-slug", function(d) { return d.properties.slug; });

    locationDetail.append("h3").text(function(d) { return d.properties.name; });
    locationDetail.append("h4").text("Coordinates");
    locationDetail.append("div").html(function(d) { return prettyLatLong(d.geometry.coordinates); });
    locationDetail.append("h4").text("Sensors");
    locationDetail.append("ul")
        .attr("class", "media-list")
        .selectAll(".media")
                .data(function(d) { return d.properties.sensors || []; })
            .call(appendSensorList, sensors);

    sensorInfo.append("h3").text("Sensor types");
    sensorInfo.append("ul")
        .attr("class", "media-list")
        .selectAll(".media").data(Object.keys(sensors))
        .call(appendSensorList, sensors);

    projection.rotate([120, 0]);
    features.selectAll("path.land").attr("d", path);
    features.selectAll("path.location").attr("d", path);
};


function ddToDms(dd, latOrLon) {
    var format = d3.format(".3f");
    var dd_positive = Math.abs(dd);
    var d = Math.floor(dd_positive);
    var m = Math.floor((dd_positive % 1) * 60);
    var s = (((dd_positive % 1) * 60) % 1) * 60;
    var suffix;
    if (latOrLon === "lat") 
        suffix = dd_positive === dd ? "N" : "S";
    else
        suffix = dd_positive === dd ? "E" : "W";
    return d + "&deg;" +  m + "'" + format(s) + "\"" + suffix;
}


