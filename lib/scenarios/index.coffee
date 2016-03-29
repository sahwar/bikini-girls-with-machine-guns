async    = require 'async'
Scenario = require './scenario'

class Scenarios

	constructor: (@options) ->

	run: (cb) ->
		if @options.type is 'parallel'
			async.map @options.scenarios, (option, callb) ->
				scenario = new Scenario(option)
				scenario.run callb
			, (err, scenarioResult) ->
				cb err, scenarioResult
		else if @options.type is 'serial'
			async.mapSeries @options.scenarios, (option, callb) ->
				scenario = new Scenario(option)
				scenario.run callb
			, (err, scenarioResult) ->
				cb err, scenarioResult

module.exports = Scenarios