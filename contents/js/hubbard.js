var margin = {top: 10, right: 10, bottom: 100, left: 40},
    margin2 = {top: 430, right: 10, bottom: 20, left: 40},
    width = 960 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom,
    height2 = 500 - margin2.top - margin2.bottom,
    days = 24 * 60 * 60 * 1000;

var parseDate = d3.time.format("%Y-%m-%dT%H:%M:%S").parse;

var x = d3.time.scale().range([0, width]),
    x2 = d3.time.scale().range([0, width]),
    y = d3.scale.linear().range([height, 0]),
    y2 = d3.scale.linear().range([height2, 0]);

var xAxis = d3.svg.axis().scale(x).orient("bottom"),
    xAxis2 = d3.svg.axis().scale(x2).orient("bottom"),
    yAxis = d3.svg.axis().scale(y).orient("left");

var brush = d3.svg.brush()
    .x(x2)
    .on("brush", brushed);

var line = d3.svg.line()
    .defined(function(d) { return d.value; })
    .x(function(d) { return x(d.date_time); })
    .y(function(d) { return y(d.value); });

var line2 = d3.svg.line()
    .defined(function(d) { return d.value; })
    .x(function(d) { return x2(d.date_time); })
    .y(function(d) { return y2(d.value); });

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

d3.json("data/hubbard-avgrange-daily.json", function(error, data) {
    data = data.map(function(d) {
        return {
            "date_time": parseDate(d.date_time),
            "value": d.value
        }
    });
    x.domain(d3.extent(data.map(function(d) { return d.date_time; })));
    y.domain([320, d3.max(data.map(function(d) { return d.value; }))]);
    x2.domain(x.domain());
    y2.domain(y.domain());
    defaultExtent = d3.extent([new Date() - 60 * days, new Date()]);

    data = x.ticks(d3.time.day, 1).reduce(function(previous, current) {
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

    context.transition()
        .duration(500)
        .call(brush.extent(defaultExtent))
        .call(brush.event);
});

function brushed() {
    x.domain(brush.empty() ? x2.domain() : brush.extent());
    focus.select(".line").attr("d", line);
    focus.select(".x.axis").call(xAxis);
}
