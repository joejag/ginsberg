module.exports = function(grunt) {
  grunt.initConfig({
    slim: {
      all: {
        expand: true,
        cwd: 'app/views',
        src: ['{,*/}*.slim'],
        dest: 'app',
        ext: '.html'
      }
    },
    coffee: {
      all: {
        expand: true,
        flatten: true,
        cwd: 'app/assets/javascripts/coffee',
        src: ['*.coffee'],
        dest: 'app/public/javascripts',
        ext: '.js'
      }
    },
    sass: {
      all: {
        expand: true,
        cwd: 'app/assets/stylesheets/sass',
        src: ['*.sass'],
        dest: 'app/public/stylesheets',
        ext: '.css'
      }
    },
    watch: {
      slim: {
        files: ['app/views/*.slim'],
        tasks: ['slim'],
        options: {
          debounceDelay: 250,
        },
      },
      coffee: {
        files: ['app/assets/**/*.coffee'],
        tasks: ['coffee'],
        options: {
          debounceDelay: 250,
        },
      },
      sass: {
        files: ['app/assets/**/*.sass'],
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
