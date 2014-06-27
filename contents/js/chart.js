// TODO data source objects?
// TODO development vs. production switch?
var urlbase = "http://nae-rrs2.usace.army.mil:7777/pls/cwmsweb/jsonapi.timeseriesdata?"
var loc;

var defaultExtent = [d3.time.month.offset(new Date(), -2), new Date()];

var margin = {top: 10, right: 10, bottom: 100, left: 40},
    margin2 = {top: 500, right: 10, bottom: 20, left: 40},
    padding = {top: 10, right: 0, bottom: 60, left: 0},
    width = 945 - margin.left - margin.right,
    height = 600 - margin.top - margin.bottom,
    height2 = 600 - margin2.top - margin2.bottom;

var parseDate = d3.time.format("%Y-%m-%dT%H:%M:%S").parse;


function ready(slug) {
    queue()
        .defer(d3.json, "../../data/locations.json")
        .await(function(e, l) { return locationsReady(e, l, slug); });
}

function locationsReady(error, locations, slug) {
    locations.features.some(function(l) {
        return l.properties.slug === slug ? (loc = l, true) : false;
    });
    // TODO parameterize
    var q = queue(1);
    loc.properties.timeseries.forEach(function(ts) {
        // TODO swich
        q.defer(function(callback) {
            var url = development ? ts.developmentUrl : ts.url;
            return d3.jsonp(url, function(results) {
                return callback(null, d3.time.scale()
                    .domain(d3.extent(results.map(function(d) { return parseDate(d.date_time); })))
                    .ticks(d3.time.day, 1)
                    .reduce(function(previous, current) {
                        var d = {"date_time": current};
                        d.value = parseDate(results[0].date_time) <= current ? results.shift().value : null;
                        return previous.concat(d);
                    }, []));
            });
        });
    });
    q.awaitAll(function(error, results) {
        d3.zip(loc.properties.timeseries, results).forEach(function(d) {
            d[0].data = d[1];
            d[0].minX = d3.min(d[1], function(d) { return d.date_time; });
            d[0].minY = d3.min(d[1], function(d) { return d.value; });
            d[0].maxX = d3.max(d[1], function(d) { return d.date_time; });
            d[0].maxY = d3.max(d[1], function(d) { return d.value; });
        });

        var control = controls.selectAll(".control").data(loc.properties.timeseries);
        control.enter()
            .append("a")
            .attr("href", "#")
            .attr("class", "list-group-item control")
            .on("click", toggleTimeseries);
        control
            .append("span")
            .attr("class", "glyphicon")
        control
            .append("span")
            .text(function(d) { return " " + d.name; });
        control.exit().remove();

        // Set up axis, etc
        // TODO split out the stuff we need for the brushing so we can just set that up
        draw();
        brush.extent(defaultExtent);
        context.select(".x.brush")
            .call(brush)
            .call(brush.event);
        draw();
    });
}

// TODO make utility library
function slugify(s) {
    return s.toLowerCase().replace(/ /g, "-").replace(/[^\w-]+/g, "");
}

function dataValue(d) {
    return d.value;
}

function dataDateTime(d) {
    return d.date_time;
}

function tsName(d) {
    return d.name;
}

function intersectExtents(e0, e1) {
    var e = [d3.max([e0[0], e1[0]]), d3.min([e0[1], e1[1]])];
    return e[0] >= e[1] ? null : e;
}


function toggleTimeseries(d) {
    d.visible = !d.visible;
    var oldBrushExtent = brush.extent();
    var visibleTimeseries = getVisibleTimeseries();
    updateXScales(visibleTimeseries);
    var newBrushExtent = intersectExtents(oldBrushExtent, x2scale.domain());
    if (newBrushExtent === null)
        brush.clear();
    else
        brush.extent(newBrushExtent);
    context.select(".brush")
        .call(brush)
        .call(brush.event);
}

var xscale = d3.time.scale().range([0, width]),
    x2scale = d3.time.scale().range([0, width]),
    yscale2 = d3.scale.linear().range([height2, 0]);

var controls = d3.select("#controls");

var svg = d3.select("#chart").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom);

var focus = svg.append("g")
    .attr("class", "focus")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

var context = svg.append("g")
    .attr("class", "context")
    .attr("transform", "translate(" + margin2.left + "," + margin2.top + ")");

var brush = d3.svg.brush()
    .x(x2scale)
    .on("brush", draw);

context.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height2 + ")");

context.append("g")
    .attr("class", "x brush")
    .call(brush)
    .selectAll("rect")
        .attr("y", -6)
        .attr("height", height2 + 7);

function getVisibleTimeseries() {
    return loc.properties.timeseries.filter(function(d) { return d.visible; })
}

function updateXScales(timeseries) {
    var minX = d3.min(timeseries, function(d) { return d.minX; });
    var maxX = d3.max(timeseries, function(d) { return d.maxX; });
    if (brush.empty())
        xscale.domain([minX, maxX]);
    else
        xscale.domain(brush.extent());
    x2scale.domain([minX, maxX]);
}


function draw() {
    var timeseries = loc.properties.timeseries;
    var minX, maxX;
    var visibleTimeseries = getVisibleTimeseries();
    updateXScales(visibleTimeseries);

    var dHeight = height / visibleTimeseries.length;

    controls.selectAll(".control")
        .classed("active", function(d) { return d.visible; })
        .select(".glyphicon")
        .attr("class", function(d) {
            return "glyphicon " + (d.visible ? "glyphicon-eye-open" : "glyphicon-eye-close")
        });


    var ts = focus.selectAll(".timeseries").data(visibleTimeseries, tsName);
    var tsEnter = ts.enter().append("g").attr("class", "timeseries")
    tsEnter
        .append("path")
        .attr("class", "line");
    tsEnter
        .append("text", ".line")
        .attr("class", "chart-title")
        .attr("x", width / 2)
        .attr("y", -4)
        .attr("dy", 0.75)
        .style("text-anchor", "middle")
        .text(tsName);
    ts
        .attr("transform", function(d, i) { return "translate(0," + (dHeight * i + padding.top) + ")"; })
        .each(function(d) {
            // TODO this can be cached on load
            d.yscale = d3.scale.linear()
                .domain([d3.min(d.data, dataValue), d3.max(d.data, dataValue)])
                .range([dHeight - padding.bottom - padding.top, 0])
                .nice();
            var data = d.data.filter(function(e) {
                return xscale.domain()[0] <= e.date_time && e.date_time <= xscale.domain()[1];
            });
            var line = d3.select(this).select(".line");
            line.attr("d", d3.svg.line()
                .x(function(e) { return xscale(dataDateTime(e)); })
                .y(function(e) { return d.yscale(e.value); })
                .defined(function(e) { return e.value; })
                (data));
            line.style("stroke", function(d) { return d.color; });
        })
    ts.exit().remove();

    var xAxis = focus.selectAll(".x.axis").data(visibleTimeseries, tsName);
    xAxis.enter().append("g")
        .attr("class", "x axis");
    // TODO global xAxis?
    xAxis
        .attr("transform", function(d, i) { return "translate(0," + ((dHeight * (i + 1)) - padding.bottom - padding.top) + ")"; })
        .call(d3.svg.axis().scale(xscale).orient("bottom"));
    xAxis.exit().remove();

    var yAxis = focus.selectAll(".y.axis").data(visibleTimeseries, tsName);
    yAxis.enter().append("g")
        .attr("class", "y axis")
        .append("text")
        .attr("y", 0)
        .attr("x", 6)
        .attr("dy", "0.71em")
        .style("text-anchor", "start")
        .text(function(d) { return d.units; });
    yAxis.attr("transform", function(d, i) { return "translate(0," + (dHeight * i) + ")"; })
        .each(function(d) {
            // TODO global yAxis, just update the scale?
            d3.svg.axis().scale(d.yscale).orient("left")(d3.select(this));
        });
    yAxis.exit().remove();

    var ts2 = context.selectAll(".timeseries").data(visibleTimeseries, tsName);
    ts2.enter().append("g")
        .attr("class", "timeseries")
        .append("path")
        .attr("class", "line");
    ts2.select(".line")
        .attr("d", function(d) {
            d.y2scale = d.yscale.copy()
                .range([height2, 0])
                .nice();
            return d3.svg.line()
                .x(function(e) { return x2scale(dataDateTime(e)); })
                .y(function(e) { return d.y2scale(e.value); })
                .defined(function(e) { return e.value; })
                (d.data);
        })
        .style("stroke", function(d) { return d.color; });
    ts2.exit().remove();

    var x2Axis = context.select(".x.axis");
    x2Axis
        .attr("transform", "translate(0," + height2 + ")")
        .call(d3.svg.axis().scale(x2scale).orient("bottom"));
};
