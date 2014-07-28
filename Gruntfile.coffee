module.exports = (grunt) ->

    grunt.initConfig
        
        wintersmith:
            "lidar-io":
                options:
                    config: "./config-lidar-io.json"

        "gh-pages":
            options:
                base: "build"
                repo: "pgadomski@lidar.io:glacierresearch.org.git"
            src: ["**"]

    grunt.loadNpmTasks "grunt-wintersmith"
    grunt.loadNpmTasks "grunt-gh-pages"

    grunt.registerTask "deploy", ["location-kml", "wintersmith:lidar-io", "gh-pages"]

    grunt.registerTask "location-kml", "Write a kml file for each location", () ->
        locations = grunt.file.readJSON "contents/data/locations.json"
        for location in locations.features
            do (location) ->
                kml = buildKMLLocation location
                slug = location.properties.slug
                filename = "contents/locations/#{ slug }/#{ slug }.kml"
                grunt.file.write filename, kml


# TODO possibly refactor into Location object?
buildKMLLocation = (location) ->
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <kml xmlns="http://www.opengis.net/kml/2.2">
        <Placemark>
            <name>#{ location.properties.name }</name>
            <Point>
                <coordinates>#{ location.geometry.coordinates }</coordinates>
            </Point>
        </Placemark>
    </kml>
    """
