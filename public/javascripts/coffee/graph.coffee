moodSleepData = [ 
  {
    date: "2013-11-07"
    sleep: 464
    mood: 149
  },
  {
    date: "2013-10-07"
    sleep: 442
    mood: 125
  },
  {
    date: "2013-09-07"
    sleep: 366
    mood: 96
  },
  {
    date: "2013-08-07"
    sleep: 390
    mood: 200
  },
  {
    date: "2013-08-06"
    sleep: 373
    mood: 158
  },
  {
    date: "2013-06-07"
    sleep: 509
    mood: 159
  },
  {
    date: "2013-06-06"
    sleep: 368
    mood: 50
  },
  {
    date: "2013-05-07"
    sleep: 290
    mood: 103
  },
  {
    date: "2013-03-07"
    sleep: 414
    mood: 65
  },
  {
    date: "2013-01-07"
    sleep: 397
    mood: 80
  },
  {
    date: "2013-10-06"
    sleep: 360
    mood: 6
  },
  {
    date: "2013-08-06"
    sleep: 435
    mood: 218
  },
  {
    date: "2013-07-05"
    sleep: 443
    mood: 112
  },
  {
    date: "2013-06-06"
    sleep: 397
    mood: 34
  },
  {
    date: "2013-04-06"
    sleep: 376
    mood: 132
  },
  {
    date: "2013-03-06"
    sleep: 393
    mood: 153
  },
  {
    date: "2013-02-06"
    sleep: 446
    mood: 123
  },
  {
    date: "2013-12-05"
    sleep: 939
    mood: 248
  },
  {
    date: "2013-12-05"
    sleep: 526
    mood: 123
  },
  {
    date: "2013-10-05"
    sleep: 471
    mood: 130
  },
  {
    date: "2013-08-05"
    sleep: 367
    mood: 62
  },
  {
    date: "2013-07-05"
    sleep: 540
    mood: 196
  },
  {
    date: "2013-06-05"
    sleep: 467
    mood: 229
  },
  {
    date: "2013-06-04"
    sleep: 398
    mood: 113
  },
  {
    date: "2013-04-04"
    sleep: 460
    mood: 2
  },
  {
    date: "2013-03-05"
    sleep: 315
    mood: 129
  },
  {
    date: "2013-01-05"
    sleep: 348
    mood: 187
  },
  {
    date: "2013-10-04"
    sleep: 502
    mood: 207
  },
  {
    date: "2013-09-04"
    sleep: 555
    mood: 75
  },
  {
    date: "2013-08-04"
    sleep: 512
    mood: 194
  },
  {
    date: "2013-07-04"
    sleep: 450
    mood: 19
  },
  {
    date: "2013-04-04"
    sleep: 185
    mood: 189
  }
]

moodSleepData.forEach (d) ->
  d.date = new Date d.date 
  d.sleep = d.sleep/60
moodSleepData  = moodSleepData.sort (a, b) ->
  a.date - b.date
moodSleepData = d3.nest()
  .key((d) ->
    new Date d.date 
  )
  .rollup( (leaves) ->
      total_sleep: d3.sum(leaves, (d) ->
        d.sleep
      )/leaves.length
      total_mood: d3.sum(leaves, (d) ->
        d.mood
      )/leaves.length
      
  )
  .entries(moodSleepData)

# based partially on http://bl.ocks.org/mbostock/3969722

margin =
  top: 80
  right: 20
  bottom: 30
  left: 80

width = 800 - margin.left - margin.right
height = 500 - margin.top - margin.bottom


x = d3.time.scale().range([
  0
  width
])
y = d3.scale.linear().range([
  height
  0
])

xAxis = d3.svg.axis().scale(x).orient("bottom")
yAxis = d3.svg.axis().scale(y).orient("left")

line = d3.svg.line().interpolate("linear").x((d) ->
  x new Date d.key
).y((d) ->
  y d.values.total_sleep
)

svg = d3.select(".graph").append("svg").attr("width", width + margin.left + margin.right).attr("height", height + margin.top + margin.bottom).append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")")

color = d3.scale.log()
  .range(["#DAF9A5", "#447B80"])
  .interpolate(d3.interpolateHsl)
  .domain [1, 250]

drawGraph = ->
  data = moodSleepData

  x.domain d3.extent data, (d) ->
    new Date d.key
  y.domain d3.extent data, (d) ->
    d.values.total_sleep
 
  svg.append("linearGradient")
    .attr("id", "sleep-gradient")
    .attr("gradientUnits", "userSpaceOnUse")
    .attr("x1", 0)
    .attr("y1", y(4))
    .attr("x2", 0)
    .attr("y2", y(8))
      .selectAll("stop")
        .data([
          {
            offset: "0%"
            color: "#000"
          }
          {
            offset: "50%"
            color: "#999"
          }
          {
            offset: "100%"
            color: "#DDD"
          }
        ])
      .enter()
        .append("stop")
          .attr("offset", (d) ->
            d.offset
          ).attr "stop-color", (d) ->
            d.color

  svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis)
  
  svg.append("g")
    .attr("class", "y axis")
    .call(yAxis)
    .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("Sleep (hours)")

  svg.append("path")
    .datum(data)
    .attr("class", "line")
    .attr("d", line)

  svg.selectAll(".dot")
    .data(data)
  .enter().append("circle")
    .attr("class", "dot")
    .attr("r", 8)
    .attr "cx", (d) ->
      x( new Date d.key )
    .attr "cy", (d) ->
      y( d.values.total_sleep )
    .style "fill", (d) ->
      color(d.values.total_mood)

  return

drawGraph()


isValidDate = (d) ->
  if Object.prototype.toString.call(d) != "[object Date]"
    return false
  !isNaN(d.getTime())

