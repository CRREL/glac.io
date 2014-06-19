var width = 400,
    height = 400,
    defaultScale = width / 2 - 10;

var projection = d3.geo.orthographic()
    .scale(defaultScale)
    .translate([width / 2, height / 2])
    .clipAngle(90);

var path = d3.geo.path()
    .projection(projection);

var graticule = d3.geo.graticule();

var svg = d3.select("#globe").append("svg")
    .attr("width", width)
    .attr("height", height);

var location_points;

queue()
    .defer(d3.json, "../data/world-110m.json")
    .defer(d3.json, "../data/locations.json")
    .await(ready);


function ready(error, world, locations) {
    d3.select("#locations").selectAll("li")
            .data(locations.features)
        .enter().append("li").append("a")
            .text(function(l) { return l.properties.name; })
            .attr("href", function(l) { return l.properties.slug + "/" })
            .on("mouseover", mouseoverLocation)
            .on("mouseout", mouseoutLocation);

    var land = topojson.feature(world, world.objects.land);

    svg.insert("path", ".graticule")
        .datum(land)
        .attr("class", "land")
        .attr("d", path);

    location_points = svg.selectAll(".location")
            .data(locations.features)
        .enter().append("path")
            .attr("class", "location");

    location_points
        .attr("d", locationPointPath);

    focusGlobe(locations.features[0]);
};


function mouseoverLocation() {
    var location_ = d3.select(this).datum();
    focusGlobe(location_);
    location_points
        .filter(function(d) { return d.properties.slug === location_.properties.slug; })
        .classed("focused", true);
}


function mouseoutLocation() {
    location_points
        .filter(function(d) { return d.properties.slug === d3.select(this).datum().properties.slug; })
        .classed("focused", false);
}


function focusGlobe(location_) {
    d3.transition()
        .duration(1000)
        .tween("rotate", function() {
            var p = location_.geometry.coordinates,
                r = d3.interpolate(projection.rotate(), [-p[0], -p[1]]);
            return function(t) {
                projection.rotate(r(t));
                svg.selectAll("path.land").attr("d", path);
                svg.selectAll("path.location").attr("d", locationPointPath);
            };
        });
};


function locationPointPath(location_) {
    var focused = location_points
        .filter(function(d) { return d.properties.slug === location_.properties.slug; })
        .classed("focused");
    var radius;
    if (focused)
    {
        radius = 10;
    }
    else
    {
        radius = 5;
    }
    return path.pointRadius(radius)
        (location_);
}
