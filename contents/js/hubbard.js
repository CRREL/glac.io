var margin = {top: 10, right: 10, bottom: 100, left: 40},
    margin2 = {top: 430, right: 10, bottom: 20, left: 40},
    width = 960 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom,
    height2 = 500 - margin2.top - margin2.bottom,
    days = 24 * 60 * 60 * 1000;

var parseDate = d3.time.format("%Y-%m-%dT%H:%M:%S").parse;

var xscale = d3.time.scale().range([0, width]),
    x2scale = d3.time.scale().range([0, width]),
    yscale = d3.scale.linear().range([height, 0]),
    y2scale = d3.scale.linear().range([height2, 0]);

var xAxis = d3.svg.axis().scale(xscale).orient("bottom"),
    xAxis2 = d3.svg.axis().scale(x2scale).orient("bottom"),
    yAxis = d3.svg.axis().scale(yscale).orient("left");

var brush = d3.svg.brush()
    .x(x2scale)
    .on("brush", brushed);

var line = d3.svg.line()
    .defined(function(d) { return d.value; })
    .x(function(d) { return xscale(d.date_time); })
    .y(function(d) { return yscale(d.value); });

var line2 = d3.svg.line()
    .defined(function(d) { return d.value; })
    .x(function(d) { return x2scale(d.date_time); })
    .y(function(d) { return y2scale(d.value); });

var svg = d3.select("#chart").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom);

svg.append("defs").append("clipPath")
    .attr("id", "clip")
  .append("rect")
    .attr("width", width)
    .attr("height", height);

var focus = svg.append("g")
    .attr("class", "focus")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

var context = svg.append("g")
    .attr("class", "context")
    .attr("transform", "translate(" + margin2.left + "," + margin2.top + ")");

var data = null;

d3.json("data/hubbard-avgrange-daily.json", function(error, d) {
    data = d.map(function(d) {
        return {
            "date_time": parseDate(d.date_time),
            "value": d.value
        }
    });
    xscale.domain(d3.extent(data.map(function(d) { return d.date_time; })));
    yscale.domain([320, d3.max(data.map(function(d) { return d.value; }))]);
    x2scale.domain(xscale.domain());
    y2scale.domain(yscale.domain());
    defaultExtent = d3.extent([new Date() - 60 * days, new Date()]);

    data = xscale.ticks(d3.time.day, 1).reduce(function(previous, current) {
        d = {date_time: current};
        if (data[0].date_time <= current)
            d.value = data.shift().value;
        else
            d.value = null;
        return previous.concat(d);
    }, []);

    focus.append("path")
        .datum(data)
        .attr("class", "line")
        .attr("d", line);

    focus.selectAll("circle.datapoint").data(data, date_time)
        .enter()
            .append("circle")
            .attr("class", "datapoint")
            .attr("r", "2px");
    update_points(data);

    focus.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis);

    focus.append("g")
        .attr("class", "y axis")
        .call(yAxis);

    context.append("path")
        .datum(data)
        .attr("class", "line")
        .attr("d", line2);

    context.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height2 + ")")
        .call(xAxis2);

    context.append("g")
        .attr("class", "x brush")
        .call(brush)
        .selectAll("rect")
        .attr("y", -6)
        .attr("height", height2 + 7);

});

function brushed() {
    xscale.domain(brush.empty() ? x2scale.domain() : brush.extent());
    focus.select(".line")
        .attr("d", line);
    focus.select(".x.axis")
        .call(xAxis);
    update_points(data.filter(function(d) {
        return xscale(d.date_time) > 0;
    }));
}


function update_points(p) {
    var points = focus.selectAll("circle.datapoint").data(p, date_time);
    points.enter()
        .append("circle")
        .attr("class", "datapoint")
        .attr("r", "2px");

    points.attr("cx", function(d) { return xscale(d.date_time); })
        .attr("cy", function(d) { return yscale(d.value); });

    points.exit().remove();
}


function date_time(d) {
    return d.date_time.toString();
}
