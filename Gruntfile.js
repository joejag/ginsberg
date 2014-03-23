module.exports = function(grunt) {
  grunt.initConfig({
    slim: {
      all: {
        expand: true,
        cwd: 'app/slim',
        src: ['{,*/}*.slim'],
        dest: 'app',
        ext: '.html'
      }
    },
    coffee: {
      all: {
        expand: true,
        flatten: true,
        cwd: 'app/javascripts/coffee',
        src: ['*.coffee'],
        dest: 'app/javascripts',
        ext: '.js'
      }
    },
    sass: {
      all: {
        expand: true,
        cwd: 'app/stylesheets/sass',
        src: ['*.sass'],
        dest: 'app/stylesheets',
        ext: '.css'
      }
    },
    watch: {
      slim: {
        files: ['app/slim/*.slim'],
        tasks: ['slim'],
        options: {
          debounceDelay: 250,
        },
      },
      coffee: {
        files: ['app/javascripts/**/*.coffee'],
        tasks: ['coffee'],
        options: {
          debounceDelay: 250,
        },
      },
      sass: {
        files: ['app/stylesheets/**/*.sass'],
        tasks: ['sass'],
        options: {
          debounceDelay: 250,
        },
      }
    }
  });
  grunt.loadNpmTasks('grunt-slim');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-sass');
  grunt.loadNpmTasks('grunt-contrib-watch');

  grunt.registerTask('default', ['coffee', 'slim', 'sass']);
};
