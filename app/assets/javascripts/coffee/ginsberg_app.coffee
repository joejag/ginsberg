ginsbergApp = angular.module('ginsbergApp', [])

ginsbergApp.config ['$httpProvider', ($httpProvider) ->
  $httpProvider.defaults.headers.get = { 'Accept': 'application/json' }
]

ginsbergApp.controller "moodSleepController", ($scope, $http) ->

  $scope.startDate = $scope.startDate || "May 1 2013" 
  $scope.endDate = $scope.endDate || "March 1 2014" 


  # TO DO - move this logic out - perhaps into the proxy server 
  # so that app is served clean, ordered json without having to
  # crudely bash it into shape. Doing data manipulation on the server means
  # only one get request to the proxy is neccessary.
  $scope.changedDate = ->
    # start and end dates for REST call
    from = new Date($scope.startDate).toISOString().slice(0,10) #to YYYY-MM-DD
    to = new Date($scope.endDate).toISOString().slice(0,10) #to YYYY-MM-DD

    # call to sinatra proxy to access the REST API for sleep data
    $http.get("http://localhost:4567/sleep/"+from+"/"+to+"/").success (data) ->
      sleepData = []
      data.forEach (s) ->
        timestampDate = new Date(s.timestamp)
        hourless_date = dateToHourlessTime(timestampDate)
        sleepObj = {}
        sleepObj.date = hourless_date
        sleepObj.sleep = s.total_sleep
        sleepData.push sleepObj

      # call to sinatra proxy to access the REST API for mood data
      $http.get("http://localhost:4567/mood/"+from+"/"+to+"/").success (data) ->
        moodSleepData = []
        data = data.forEach (m) ->
          timestampDate = new Date(m.timestamp)
          hourless_date = dateToHourlessTime(timestampDate)
          
          # Attempt to merge data - results in an array of objects where both sleep data
          # and mood data were both available (hence sparce final data points) 
          # see note above about moving this to the proxy server

          # find first matching sleepData object - ignore any others with matching dates
          matchingSleepDate = _.findWhere sleepData, {date: hourless_date}
          obj = _.findWhere moodSleepData, {date: hourless_date}
          if matchingSleepDate and !obj
            moodSleepObj = {}
            moodSleepObj.sleep = matchingSleepDate.sleep
            moodSleepObj.mood = m.value
            moodSleepObj.date = hourless_date 
            moodSleepData.push moodSleepObj

        $scope.moodSleepData = moodSleepData

        $scope.averageSleep = getAverageSleep(moodSleepData)

        drawGraph(moodSleepData)

        # set mood scale
        # height of the mood scale = 350px divided by max mood score times avg mood
        height = ((350/250) * getAverageMood(moodSleepData))
        $scope.moodStyle = {
          top:  height+"px"
        }

  $scope.changedDate()

isValidDate = (d) ->
  if Object.prototype.toString.call(d) != "[object Date]"
    return false
  !isNaN(d.getTime())
        
dateToHourlessTime = (d) ->
  if isValidDate(d)
    target  = new Date(d.valueOf())
    target.setHours(0,0,0,0)
    target.getTime()
 

# graph partially based on http://bl.ocks.org/mbostock/3969722
margin =
  top: 20 
  right: 20
  bottom: 40
  left: 40

width = 800 - margin.left - margin.right
height = 450 - margin.top - margin.bottom


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
  y d.values.sleep
)


color = d3.scale.log()
  .range(["#B8D782", "#5CB6BE"])
  .interpolate(d3.interpolateHsl)
  .domain [1, 250]

drawGraph = (moodSleepData) ->
  d3.select(".graph svg").remove()
  svg = d3.select(".graph").append("svg").attr("width", width + margin.left + margin.right).attr("height", height + margin.top + margin.bottom).append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")")

  moodSleepData  = moodSleepData.sort (a, b) ->
    a.date - b.date

  moodSleepData = d3.nest()
    .key((d) ->
      new Date d.date 
    )
    .rollup( (leaves) ->
        sleep: d3.sum(leaves, (d) ->
          d.sleep/60
        )/leaves.length
        mood: d3.sum(leaves, (d) ->
          d.mood
        )/leaves.length
        
    )
    .entries(moodSleepData)

  data = moodSleepData

  x.domain d3.extent data, (d) ->
    new Date d.key
  y.domain d3.extent data, (d) ->
    d.values.sleep
 
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
      y( d.values.sleep )
    .style "fill", (d) ->
      color(d.values.mood)

  return

getAverageSleep = (moodSleepData) ->
  sleeps = []
  moodSleepData.forEach (d) ->
    sleeps.push d.sleep/60
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

