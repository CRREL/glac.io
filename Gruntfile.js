module.exports = function(grunt) {

    grunt.initConfig({

        wintersmith: {
            build: {}
        },

        "gh-pages": {
            options: {
                base: "build"
            },
            src: ["**"]
        }

    });
        

    grunt.loadNpmTasks("grunt-wintersmith");
    grunt.loadNpmTasks('grunt-gh-pages');

}
