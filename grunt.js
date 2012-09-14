module.exports = function(grunt){

"use strict";

grunt.initConfig({

stylus: {
  compile: {
    options: {
      compress: true,
      paths: [
        require('nib').path
      ]
    },
    files: {
      'core/pik7.css': ['src/style/pik7.styl']
    }
  }
},


coffee: {
  compile: {
    options: {
      bare: true
    },
    files: (function(){
      var files = {};
      var path = 'src/**/*.coffee';
      var sources = grunt.file.expandFiles(path);
      sources.forEach(function(source){
        var destination = source.substring(0, source.length - 6) + 'js';
        files[destination] = source;
      });
      return files;
    })()
  }
},


server: {
  port: 1337,
  base: '.'
},


qunit: {
  all: (function(){
    var files = grunt.file.expandFiles('src/script/test/*.html');
    return files.map(function(file){
      return 'http://localhost:1337/' + file;
    });
  })()
},


requirejs: {
  compile: {
    options: {
      baseUrl: 'src/script',
      paths: {
        'jquery': 'lib/vendor/jquery-1.7.2.min',
        'prefixfree': 'lib/vendor/prefixfree.min'
      },
      name: 'pik7',
      out: 'core/pik7.js',
      optimize: (function(){
        if(grunt.cli.tasks[0] !== 'dev'){
          return 'uglify';
        }
        else {
          return 'none';
        }
      })()
    }
  }
},


clean: ['src/script/*.js', 'src/script/lib/*.js', 'src/script/test/*.js']


});


grunt.loadNpmTasks('grunt-contrib');


grunt.registerTask('dev',     'stylus coffee server qunit requirejs');
grunt.registerTask('default', 'stylus coffee server qunit requirejs clean');


};