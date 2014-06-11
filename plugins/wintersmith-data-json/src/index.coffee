fs = require 'fs'

module.exports = (env, callback) ->
  class JsonDataPlugin extends env.ContentPlugin

    constructor: (@filepath, src) ->
      @src = src

    getFilename: ->
      @filepath.relative

    getView: -> (env, locals, contents, templates, callback) ->
      callback null, new Buffer(JSON.stringify(@src))

  JsonDataPlugin.fromFile = (filepath, callback) ->
    env.utils.readJSON filepath.full, (error, result) ->
      if not error?
        plugin = new JsonDataPlugin filepath, result
      callback error, plugin

  env.registerContentPlugin 'json', 'data/**.json', JsonDataPlugin

  # tell plugin manager we are done
  callback()
