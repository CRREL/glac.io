var width = 400,
    height = 400,
    defaultScale = width / 2 - 10;

var availableSensors = {
    "climate": {
        "src": "../img/sensor-icons/climate64px.png",
        "name": "Climate station",
        "description": "Permanent climate station with real time data transmitted via satellite link."
    },
    "timelapse": {
        "src": "../img/sensor-icons/camera64px.png",
        "name": "Satellite linked time lapse camera",
        "description": "Permanement time lapse camera with real time transmission of images via satellite link."
    },
    "lidar": {
        "src": "../img/sensor-icons/lidar64px.png",
        "name": "LiDAR data",
        "description": "High resolution point cloud data."
    }
}

var projection = d3.geo.orthographic()
    .scale(defaultScale)
    .translate([width / 2, height / 2])
    .clipAngle(90);

var path = d3.geo.path()
    .projection(projection);

var svg = d3.select("#globe").append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("class", "center-block");

var detail = d3.select("#detail");

svg.append("path")
    .datum({type: "Sphere"})
    .attr("id", "sphere")
    .attr("d", path);

queue()
    .defer(d3.json, "../data/world-110m.json")
    .defer(d3.json, "../data/locations.json")
    .await(ready);


function ready(error, world, locations) {
    d3.select("#locations").selectAll("a")
            .data(locations.features)
        .enter().append("a")
            .text(function(l) { return l.properties.name + (l.properties.disabled ? " (disabled)" : ""); })
            .attr("class", "list-group-item")
            .attr("href", function(l) { return l.properties.disabled ? "#" : l.properties.slug + "/" })
            .on("mouseover", mouseoverLocation)
            .on("mouseout", mouseoutLocation);

    var land = topojson.feature(world, world.objects.land);

    svg.insert("path", ".graticule")
        .datum(land)
        .attr("class", "land")
        .attr("d", path);

    svg.selectAll(".location")
            .data(locations.features)
        .enter().append("path")
            .attr("class", "location")
            .attr("data-slug", function(l) { return l.properties.slug; })
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
    var media = locationDetail.append("ul")
        .attr("class", "media-list")
        .selectAll(".media")
                .data(function(d) { return d.properties.sensors || []; })
            .enter().append("li")
            .attr("class", "media");
    media.append("a")
        .attr("href", "#")
        .attr("class", "pull-left")
        .append("img")
        .attr("class", "media-object")
        .attr("src", function(d) { return availableSensors[d].src; });
    var mediaBody = media.append("div")
        .attr("class", "media-body");
    mediaBody.append("h4")
        .text(function(d) { return availableSensors[d].name; });
    mediaBody.append("p")
        .text(function(d) { return availableSensors[d].description; });

    focusGlobe(locations.features[0]);
};


function mouseoverLocation() {
    var location_ = d3.select(this).datum();
    focusGlobe(location_);
    selectPointBySlug(location_).classed("focused", true);
    selectDetailBySlug(location_)
        .style("display", "block");
}


function mouseoutLocation() {
    selectPointBySlug(d3.select(this).datum()).classed("focused", false);
    selectDetailBySlug(d3.select(this).datum())
        .style("display", "none");
}


function focusGlobe(location_) {
    d3.transition()
        .duration(1000)
        .tween("rotate", function() {
            var scale = d3.scale.linear().domain([-90, 90]).range([30, -30]);
            var p = location_.geometry.coordinates,
                r = d3.interpolate(projection.rotate(), [-p[0], scale(p[1])]);
            return function(t) {
                projection.rotate(r(t));
                svg.selectAll("path.land").attr("d", path);
                svg.selectAll("path.location").attr("d", locationPointPath);
            };
        });
};


function locationPointPath(location_) {
    var radius;
    if (selectPointBySlug(location_).classed("focused"))
    {
        radius = 10;
    }
    else
    {
        radius = 5;
    }
    return path.pointRadius(radius)(location_);
}


function selectPointBySlug(location_) {
    return svg.select(".location[data-slug=" + location_.properties.slug + "]");
}

function selectDetailBySlug(location_) {
    return detail.select("[data-slug=" + location_.properties.slug + "]");
}

function prettyLatLong(coordinates) {
    return ddToDms(coordinates[1], "lat") + ", " + ddToDms(coordinates[0], "lon");
}

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
