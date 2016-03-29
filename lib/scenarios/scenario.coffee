async = require 'async'
_     = require 'lodash'
Step  = require './step'

class Scenario

	constructor: (@options) ->
		console.log '-----init-scenario--------->', @options.name
		@requestPool =
			maxSockets: @options.config.pool

	run: (cb) ->
		async.mapLimit [0...@options.config.runs], @options.config.concurrency, (run, callb) =>
			context = {}
			context[run] = {}
			async.mapSeries @options.steps, (stepOption, callback) =>
				step = new Step(stepOption, context[run], @requestPool)
				step.run (err, stepResult) ->
					if not err
						_.merge context[run], stepResult
					callback err
			, (err) ->
				callb err,
					run: run
					context: context[run]

		, (err, runsResult) ->
			cb err, runsResult

module.exports = Scenario