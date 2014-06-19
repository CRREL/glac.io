var width = 720,
    height = 720;

var projection = d3.geo.orthographic()
    .scale(width / 2 - 10)
    .translate([width / 2, height / 2])
    .clipAngle(90)
    .precision(1.0);

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
    var globe = {type: "Sphere"},
        land = topojson.feature(world, world.objects.land);

    svg.append("defs").append("path")
        .datum(globe)
        .attr("id", "sphere")
        .attr("d", path);

    svg.append("use")
        .attr("class", "stroke")
        .attr("xlink:href", "#sphere");

    svg.append("use")
        .attr("class", "fill")
        .attr("xlink:href", "#sphere");

    svg.append("path")
        .datum(graticule)
        .attr("class", "graticule")
        .attr("d", path);

    svg.insert("path", ".graticule")
        .datum(land)
        .attr("class", "land")
        .attr("d", path);

    var i = -1;
    (function transition() {
        d3.transition()
            .duration(1250)
            .each("start", function() {
                i = (i + 1) % locations.length;
            })
            .tween("rotate", function() {
                var p = locations[i].latlon,
                    r = d3.interpolate(projection.rotate(), [-p[1], -p[0]]);
                return function(t) {
                    projection.rotate(r(t));
                    svg.selectAll("path.land").attr("d", path);
                };
            });
    })();
};
