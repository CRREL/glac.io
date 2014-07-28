module.exports = function(grunt) {

    grunt.initConfig({

        wintersmith: {
            "lidar-io": {
                options: {
                    config: "./config-lidar-io.json"
                }
            }
        },

        "gh-pages": {
            options: {
                base: "build",
                repo: "pgadomski@lidar.io:glacierresearch.org.git"
            },
            src: ["**"]
        }

    });
        

    grunt.loadNpmTasks("grunt-wintersmith");
    grunt.loadNpmTasks('grunt-gh-pages');

    grunt.registerTask("deploy", ["wintersmith:lidar-io", "gh-pages"]);

}
