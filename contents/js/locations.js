var width = 400,
    height = 400,
    defaultScale = width / 2 - 10;

var availableSensors = [
{
    "name": "climate",
    "src": "../img/climate32px.png",
    "description": "Climate station"
},
{
    "name": "timelapse",
    "src": "../img/timelapse32px.png",
    "description": "Satellite linked timelapse camera"
},
{
    "name": "lidar",
    "src": "../img/lidar32px.png",
    "description": "LiDAR data"
}
]

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

    focusGlobe(locations.features[0]);
};


function mouseoverLocation() {
    var location_ = d3.select(this).datum();
    focusGlobe(location_);
    selectPointBySlug(location_).classed("focused", true);

    var detail = "<h3>" + location_.properties.name + "</h3>"
                + "<dl>"
                    + "<dt>Coordinates</dt>"
                    + "<dd>" + prettyLatLong(location_.geometry.coordinates) + "</dd>";
    if (location_.properties.sensors)
        detail += "<dt>Sensors</dt><dd>" + sensorList(location_.properties.sensors) + "</dd>"

    detail += "</dl>";
    d3.select("#detail")
        .html(detail);
}


function mouseoutLocation() {
    selectPointBySlug(d3.select(this).datum()).classed("focused", false);
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


function prettyLatLong(coordinates) {
    return ddToDms(coordinates[1], "lat") + ", " + ddToDms(coordinates[0], "lon");
}


function sensorList(sensors) {
    var items = availableSensors.map(function(s) {
        if (sensors.indexOf(s.name) > -1)
            return "<li><img src=\"" + s.src + "\"> " + s.description + "</li>";
        else
            return "";
    });
    return "<ul class=\"list-unstyled\">" + items.join('') + "</ul>";
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
