module.exports = (grunt) ->

  grunt.initConfig
    
    wintersmith:
      "lidar-io":
        options:
          config: "./config-lidar-io.json"
      "gh-pages":
        options:
          config: "./config-gh-pages.json"

    "gh-pages":
      "lidar-io":
        options:
          base: "build"
          repo: "pgadomski@lidar.io:glacierresearch.org.git"
        src: ["**"]
      "gh-pages":
        options:
          base: "build"
        src: ["**"]
    
    slack:
      options:
        token: "2DcBPYcz3AhAPtNbRDbabX9I"
        domain: "hobu"
        channel: "#glacio"
        username: "glacio-deploy"
        icon_url: "http://glac.io/img/rsgis110px.png"
      deploy:
        text: "<%= gitinfo.local.branch.current.currentUser %> updated the glac.io site " +
          "to <https://github.com/gadomski/glac.io/commit/<%= gitinfo.local.branch.current.SHA %>|<%= gitinfo.local.branch.current.shortSHA %>>"

    gitinfo: {}


  grunt.loadNpmTasks "grunt-wintersmith"
  grunt.loadNpmTasks "grunt-gh-pages"
  grunt.loadNpmTasks "grunt-gitinfo"
  grunt.loadNpmTasks "grunt-slack-hook"

  grunt.registerTask "deploy-dev", ["location-kml", "wintersmith:gh-pages", "gh-pages:gh-pages"]
  grunt.registerTask "deploy", ["location-kml", "wintersmith:lidar-io", "gh-pages:lidar-io", "gitinfo"]

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
