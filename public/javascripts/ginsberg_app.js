(function() {
  var ginsbergApp;

  ginsbergApp = angular.module('ginsbergApp', []);

  ginsbergApp.config([
    '$httpProvider', function($httpProvider) {
      return $httpProvider.defaults.headers.get = {
        'Accept': 'application/json'
      };
    }
  ]);

  ginsbergApp.controller("SleepDataController", function($scope, $http) {
    return $http.get('http://localhost:4567/sleep/2013-11-20/2014-01-20/').success(function(data) {
      return $scope.sleepData = data;
    });
  });

}).call(this);
