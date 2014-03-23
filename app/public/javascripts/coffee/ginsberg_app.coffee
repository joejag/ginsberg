ginsbergApp = angular.module('ginsbergApp', [])

ginsbergApp.config ['$httpProvider', ($httpProvider) ->
  $httpProvider.defaults.headers.get = { 'Accept': 'application/json' }
]

ginsbergApp.controller "SleepDataController", ($scope, $http) ->
  $http.get('http://localhost:4567/sleep/2013-11-20/2014-01-20/').success (data) ->
    $scope.sleepData = data
