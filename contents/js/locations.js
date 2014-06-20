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

queue()
    .defer(d3.json, "../data/world-110m.json")
    .defer(d3.json, "../data/locations.json")
    .await(ready);


function ready(error, world, locations) {
    d3.select("#locations").selectAll("a")
            .data(locations.features)
        .enter().append("a")
            .text(function(l) { return l.properties.name; })
            .attr("class", "list-group-item")
            .attr("href", function(l) { return l.properties.slug + "/" })
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

    d3.select("#detail")
        .html("<h3>"
                + location_.properties.name
                + "</h3><dl><dt>Coordinates</dt><dd>"
                + prettyLatLong(location_.geometry.coordinates)
                + "</dd></dl>");
}


function mouseoutLocation() {
    selectPointBySlug(d3.select(this).datum()).classed("focused", false);
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
    var radius;
    if (selectPointBySlug(location_).classed("focused"))
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


function selectPointBySlug(location_) {
    return svg.select(".location[data-slug=" + location_.properties.slug + "]");
}


function prettyLatLong(coordinates) {
    return coordinates[1] + "&deg;, " + coordinates[0] + "&deg;";
}
