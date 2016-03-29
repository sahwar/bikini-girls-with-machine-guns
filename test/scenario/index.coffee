Scenarios = require '../../lib/scenarios'
config    = require './scenarios'

describe.skip "Bikini Girls With Machine Guns - Scenarios", ->

	@timeout 100000

	it 'executes the scenarios', (done) ->
		scenarios = new Scenarios(config)
		scenarios.run (err, result) ->
			# console.log JSON.stringify(result, null, '\t')
			done()
