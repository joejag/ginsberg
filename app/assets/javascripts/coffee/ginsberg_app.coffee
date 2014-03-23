ginsbergApp = angular.module('ginsbergApp', [])

ginsbergApp.config ['$httpProvider', ($httpProvider) ->
  $httpProvider.defaults.headers.get = { 'Accept': 'application/json' }
]

ginsbergApp.controller "moodSleepController", ($scope, $http) ->
  $http.get('http://localhost:4567/sleep/2010-11-20/2014-01-20/').success (data) ->
    sleepData = []
    moodSleepData = []
    data.forEach (s) ->
      if isValidDate(new Date(s.timestamp))
        obj = {}
        hourless_date = new Date(s.timestamp).setHours(0,0,0,0)
        obj.date = hourless_date
        obj.total_sleep = s.total_sleep
        sleepData.push obj
    $http.get('http://localhost:4567/mood/2010-11-20/2014-01-20/').success (data) ->
      data.forEach (m) ->
        if isValidDate(new Date(m.timestamp))
          hourless_date = new Date(m.timestamp).setHours(0,0,0,0)
          obj = _.findWhere sleepData, {date: hourless_date}
          if obj
            obj.mood = m.value
            moodSleepData.push obj

      $scope.moodSleepData = moodSleepData

      $scope.redraw = ->
        drawGraph(moodSleepData) 
        $scope.averageSleep = getAverageSleep(moodSleepData)
        height = ((400/250) * getAverageMood(moodSleepData))
        $scope.moodStyle = {
          top:  height+"px"
        }

isValidDate = (d) ->
  if Object.prototype.toString.call(d) != "[object Date]"
    return false
  !isNaN(d.getTime())
        
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


color = d3.scale.log()
  .range(["#DAF9A5", "#447B80"])
  .interpolate(d3.interpolateHsl)
  .domain [1, 250]

drawGraph = (moodSleepData) ->
  d3.select(".graph svg").remove()
  svg = d3.select(".graph").append("svg").attr("width", width + margin.left + margin.right).attr("height", height + margin.top + margin.bottom).append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")")

  moodSleepData.forEach (d) ->
    d.date = new Date d.date 
    d.sleep = d.total_sleep/60
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

getAverageSleep = (moodSleepData) ->
  sleeps = []
  moodSleepData.forEach (d) ->
    sleeps.push d.total_sleep/60
  sum = _.reduce(sleeps, (memo, num) ->
    memo + num
  ,0)
  average = sum/sleeps.length
  Math.round(average * 100) / 100 #round to 2 decimal places

getAverageMood = (moodSleepData) ->
  moods = []
  moodSleepData.forEach (d) ->
    moods.push d.mood
  sum = _.reduce(moods, (memo, num) ->
    memo + num
  ,0)
  average = sum/moods.length
  Math.round(average * 100) / 100 #round to 2 decimal places
