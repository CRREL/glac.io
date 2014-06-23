var urlbase = "http://nae-rrs2.usace.army.mil:7777/pls/cwmsweb/jsonapi.timeseriesdata?"

// TODO development vs. production switch?
var timeseries = [
{
    "name": "Terminus range",
//    "url": urlbase + "ts_codes=18844021,18845021,18846021,18847021,18848021,18849021,18850021,18851021,18852021,18853021,18854021,18855021,18856021,18857021,18858021,18859021,18860021,18861021,18862021,18863021,18864021,18865021,18866021,18867021,18868021,18869021,18870021,18871021,18872021,18873021&summary_interval=daily&floor=320&jsonp={callback}"
    "url": "../../data/hubbard-avgrange-daily.js?callback=d3.jsonp.ntsfvAwWtPjZJKz"
},
{
    "name": "Air temperature",
    // "url": urlbase + "ts_codes=13260021&jsonp={callback}"
    "url": "../../data/hubbard-avgtemp-daily.js?callback=d3.jsonp.temperature"
}
];

var loadedData = [];

var margin = {top: 10, right: 10, bottom: 100, left: 40},
    margin2 = {top: 430, right: 10, bottom: 20, left: 40},
    width = 945 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom,
    height2 = 500 - margin2.top - margin2.bottom;

var parseDate = d3.time.format("%Y-%m-%dT%H:%M:%S").parse;

var xscale = d3.time.scale().range([0, width]),
    x2scale = d3.time.scale().range([0, width]);

var xAxis = d3.svg.axis().scale(xscale).orient("bottom"),
    xAxis2 = d3.svg.axis().scale(x2scale).orient("bottom"),
    yAxis = d3.svg.axis().orient("left");

var brush = d3.svg.brush()
    .x(x2scale);

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


function draw() {
    var defaultExtent = [d3.time.month.offset(new Date(), -2), new Date()];
    
    updateXscale();
    yAxis.scale(visibleData()[0].yscale);

    focus.selectAll("path")
            .data(visibleData())
        .enter()
            .append("path")
            .attr("class", "line")
            .attr("d", function(d) { return d.line(d.data); });

    focus.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis);

    focus.append("g")
        .attr("class", "y axis")
        .call(yAxis);

    
};


timeseries.forEach(function(ts) {
    d3.jsonp(ts.url, function(data) {
        var yscale = d3.scale.linear()
            .range([0, height])
            .domain(d3.extent(data.map(dataValue)).reverse())
            .nice();
        var yscale2 = d3.scale.linear()
            .range([0, height2])
            .domain(d3.extent(data.map(dataValue)).reverse())
            .nice();
        var line = d3.svg.line()
            .defined(function(d) { return d.value; })
            .x(function(d) { return xscale(d.date_time); })
            .y(function(d) { return yscale(d.value); });
        var line2 = d3.svg.line()
            .defined(function(d) { return d.value; })
            .x(function(d) { return xscale2(d.date_time); })
            .y(function(d) { return yscale2(d.value); });
        var localXscale = d3.time.scale()
            .domain(d3.extent(data.map(function(d) {
                return parseDate(d.date_time);
            })));
        data = localXscale.ticks(d3.time.day, 1).reduce(function(previous, current) {
            var d = {"date_time": current};
            if (parseDate(data[0].date_time) <= current)
                d.value = data.shift().value;
            else
                d.value = null;
            return previous.concat(d);
        }, []);
        loadedData.push({
            "name": ts.name,
            "slug": ts.slug,
            "data": data,
            "color": ts.color,  // TODO allow color generation
            "yscale": yscale,
            "line": line,
            "line2": line2,
            "visible": true     // TODO allow per-ts customization
        });
        // TODO sort loaded data by something?
        if (loadedData.length == timeseries.length)
            draw();
    });
});


function updateXscale() {
    xscale.domain(d3.extent(d3.merge(visibleData().map(function(a) { return d3.extent(a.data, dataDateTime); }))));
    x2scale.domain(xscale.domain());
}


function updatePoints(points) {
    points.enter()
        .append("circle")
        .attr("class", "datapoint")
        .attr("r", "2px")
        .attr("r", function(d) { return d.value ? "2px": "0px"; });

    points.attr("cx", function(d) { return xscale(d.date_time); })
        .attr("cy", function(d) { return yscale(d.value); });

    points.exit().remove();
}


function visibleData() {
    return loadedData.filter(function(d) { return d.visible; });
}


function dataValue(d) {
    return d.value;
}


function dataDateTime(d) {
    return d.date_time;
}
