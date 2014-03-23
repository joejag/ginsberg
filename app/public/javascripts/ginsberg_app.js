(function() {
  var color, dateToHourlessTime, drawGraph, getAverageMood, getAverageSleep, ginsbergApp, height, isValidDate, line, margin, width, x, xAxis, y, yAxis;

  ginsbergApp = angular.module('ginsbergApp', []);

  ginsbergApp.config([
    '$httpProvider', function($httpProvider) {
      return $httpProvider.defaults.headers.get = {
        'Accept': 'application/json'
      };
    }
  ]);

  ginsbergApp.controller("moodSleepController", function($scope, $http) {
    $scope.startDate = $scope.startDate || "May 1 2013";
    $scope.endDate = $scope.endDate || "March 1 2014";
    $scope.changedDate = function() {
      var from, to;
      from = new Date($scope.startDate).toISOString().slice(0, 10);
      to = new Date($scope.endDate).toISOString().slice(0, 10);
      return $http.get("http://localhost:4567/sleep/" + from + "/" + to + "/").success(function(data) {
        var sleepData;
        sleepData = [];
        data.forEach(function(s) {
          var hourless_date, sleepObj, timestampDate;
          timestampDate = new Date(s.timestamp);
          hourless_date = dateToHourlessTime(timestampDate);
          sleepObj = {};
          sleepObj.date = hourless_date;
          sleepObj.sleep = s.total_sleep;
          return sleepData.push(sleepObj);
        });
        return $http.get("http://localhost:4567/mood/" + from + "/" + to + "/").success(function(data) {
          var height, moodSleepData;
          moodSleepData = [];
          data = data.forEach(function(m) {
            var hourless_date, matchingSleepDate, moodSleepObj, obj, timestampDate;
            timestampDate = new Date(m.timestamp);
            hourless_date = dateToHourlessTime(timestampDate);
            matchingSleepDate = _.findWhere(sleepData, {
              date: hourless_date
            });
            obj = _.findWhere(moodSleepData, {
              date: hourless_date
            });
            if (matchingSleepDate && !obj) {
              moodSleepObj = {};
              moodSleepObj.sleep = matchingSleepDate.sleep;
              moodSleepObj.mood = m.value;
              moodSleepObj.date = hourless_date;
              return moodSleepData.push(moodSleepObj);
            }
          });
          $scope.moodSleepData = moodSleepData;
          $scope.averageSleep = getAverageSleep(moodSleepData);
          drawGraph(moodSleepData);
          height = (350 / 250) * getAverageMood(moodSleepData);
          return $scope.moodStyle = {
            top: height + "px"
          };
        });
      });
    };
    return $scope.changedDate();
  });

  isValidDate = function(d) {
    if (Object.prototype.toString.call(d) !== "[object Date]") {
      return false;
    }
    return !isNaN(d.getTime());
  };

  dateToHourlessTime = function(d) {
    var target;
    if (isValidDate(d)) {
      target = new Date(d.valueOf());
      target.setHours(0, 0, 0, 0);
      return target.getTime();
    }
  };

  margin = {
    top: 20,
    right: 20,
    bottom: 40,
    left: 40
  };

  width = 800 - margin.left - margin.right;

  height = 450 - margin.top - margin.bottom;

  x = d3.time.scale().range([0, width]);

  y = d3.scale.linear().range([height, 0]);

  xAxis = d3.svg.axis().scale(x).orient("bottom");

  yAxis = d3.svg.axis().scale(y).orient("left");

  line = d3.svg.line().interpolate("linear").x(function(d) {
    return x(new Date(d.key));
  }).y(function(d) {
    return y(d.values.sleep);
  });

  color = d3.scale.log().range(["#B8D782", "#5CB6BE"]).interpolate(d3.interpolateHsl).domain([1, 250]);

  drawGraph = function(moodSleepData) {
    var data, svg;
    d3.select(".graph svg").remove();
    svg = d3.select(".graph").append("svg").attr("width", width + margin.left + margin.right).attr("height", height + margin.top + margin.bottom).append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");
    moodSleepData = moodSleepData.sort(function(a, b) {
      return a.date - b.date;
    });
    moodSleepData = d3.nest().key(function(d) {
      return new Date(d.date);
    }).rollup(function(leaves) {
      return {
        sleep: d3.sum(leaves, function(d) {
          return d.sleep / 60;
        }) / leaves.length,
        mood: d3.sum(leaves, function(d) {
          return d.mood;
        }) / leaves.length
      };
    }).entries(moodSleepData);
    data = moodSleepData;
    x.domain(d3.extent(data, function(d) {
      return new Date(d.key);
    }));
    y.domain(d3.extent(data, function(d) {
      return d.values.sleep;
    }));
    svg.append("linearGradient").attr("id", "sleep-gradient").attr("gradientUnits", "userSpaceOnUse").attr("x1", 0).attr("y1", y(4)).attr("x2", 0).attr("y2", y(8)).selectAll("stop").data([
      {
        offset: "0%",
        color: "#000"
      }, {
        offset: "50%",
        color: "#999"
      }, {
        offset: "100%",
        color: "#DDD"
      }
    ]).enter().append("stop").attr("offset", function(d) {
      return d.offset;
    }).attr("stop-color", function(d) {
      return d.color;
    });
    svg.append("g").attr("class", "x axis").attr("transform", "translate(0," + height + ")").call(xAxis);
    svg.append("g").attr("class", "y axis").call(yAxis).append("text").attr("transform", "rotate(-90)").attr("y", 6).attr("dy", ".71em").style("text-anchor", "end").text("Sleep (hours)");
    svg.append("path").datum(data).attr("class", "line").attr("d", line);
    svg.selectAll(".dot").data(data).enter().append("circle").attr("class", "dot").attr("r", 8).attr("cx", function(d) {
      return x(new Date(d.key));
    }).attr("cy", function(d) {
      return y(d.values.sleep);
    }).style("fill", function(d) {
      return color(d.values.mood);
    });
  };

  getAverageSleep = function(moodSleepData) {
    var average, sleeps, sum;
    sleeps = [];
    moodSleepData.forEach(function(d) {
      return sleeps.push(d.sleep / 60);
    });
    sum = _.reduce(sleeps, function(memo, num) {
      return memo + num;
    }, 0);
    average = sum / sleeps.length;
    return Math.round(average * 100) / 100;
  };

  getAverageMood = function(moodSleepData) {
    var average, moods, sum;
    moods = [];
    moodSleepData.forEach(function(d) {
      return moods.push(d.mood);
    });
    sum = _.reduce(moods, function(memo, num) {
      return memo + num;
    }, 0);
    average = sum / moods.length;
    return Math.round(average * 100) / 100;
  };

}).call(this);
