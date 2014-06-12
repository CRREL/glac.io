module.exports = function(grunt) {

    grunt.initConfig({

        wintersmith: {
            "gh-pages": {
                options: {
                    config: "./config-gh-pages.json"
                }
            }
        },

        "gh-pages": {
            options: {
                base: "build"
            },
            src: ["**"]
        },

    });
        

    grunt.loadNpmTasks("grunt-wintersmith");
    grunt.loadNpmTasks('grunt-gh-pages');

    grunt.registerTask("deploy", ["wintersmith:gh-pages", "gh-pages"]);

}
