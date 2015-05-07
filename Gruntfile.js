module.exports = function (grunt) {
    grunt.initConfig({
        jison: {
            target : {
                files: {
                    'dist/parser.js': ['lib/parser.y', 'lib/lexer.l']
                }
            }
        }
    });

    grunt.loadNpmTasks('grunt-jison');

    grunt.registerTask('default', ['jison']);
};
