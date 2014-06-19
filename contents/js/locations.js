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

// TODO make it relative somehow
queue()
    .defer(d3.json, "/data/world-110m.json")
    .defer(d3.json, "/data/locations.json")
    .await(ready);


function ready(error, world, locations) {
    d3.select("#locations").selectAll("li")
            .data(locations)
        .enter().append("li").append("a")
            .text(function(l) { return l.name; })
            .attr("href", function(l) { return l.slug + "/" })
            .on("mouseover", function(l) {
                focusGlobe(l);
            });

    var land = topojson.feature(world, world.objects.land);

    svg.insert("path", ".graticule")
        .datum(land)
        .attr("class", "land")
        .attr("d", path);

    focusGlobe(locations[0]);
};


function focusGlobe(location_) {
    d3.transition()
        .duration(1000)
        .tween("rotate", function() {
            var p = location_.latlon,
                r = d3.interpolate(projection.rotate(), [-p[1], -p[0]]);
            return function(t) {
                projection.rotate(r(t));
                svg.selectAll("path.land").attr("d", path);
            };
        });
};
