_      = require 'lodash'
async  = require 'async'
moment = require 'moment'
fs     = require 'fs'
path   = require 'path'

class HarAnalysis

	constructor: (@options) ->
		@timeseries = []
		@loadseries = []

	run: (cb) ->
		work = []
		work.push (callb) =>
			@getHarFiles callb
		work.push (files, callb) =>
			@aggregateHarData files, callb
		async.waterfall work, cb

	getHarFiles: (cb) ->
		fs.readdir @options.directory, (err, files) ->
			if err?
				cb err
			else
				cb null, _.filter(files, (file) -> _.endsWith(file, '.har'))

	aggregateHarData: (files, cb) ->
		async.map files, (file, callb) =>
			har = JSON.parse(fs.readFileSync(path.join(@options.directory, file), "utf8"))
			if har.log?.pages?[0]?
				callb null,
					url: har.log.pages[0].id
					start: har.log.pages[0].startedDateTime
					load: har.log.pages[0].pageTimings?.onLoad
					resources: @sampleResources har.log.entries
			else
				callb 'HAR not as expected!'
		, (err, harResults) ->
			sortedHarResults = _.sortBy(harResults, 'start')
			cb err, sortedHarResults

	sampleResources: (entries) ->
		result = []
		async.map entries, (entry, callb) ->
			resource =
				url: entry.request?.url
				start: entry.startedDateTime
				load: entry.time
			callb null, resource
		, (err, entriesResults) ->
			result = entriesResults
		result

module.exports = HarAnalysis

# options =
# 	directory: path.join __dirname, '../report/output-2000'

# analysis = new HarAnalysis(options)

# reducer = (res, value, key) ->
# 	resource = _.find res, (res) -> res.url is value.url
# 	if resource?
# 		resource.timings.push
# 			start: value.start
# 			load: value.load
# 	else
# 		res.push
# 			url: value.url
# 			timings: [
# 				{
# 					start: value.start
# 					load: value.load
# 				}
# 			]
# 	res

# analysis.run (err, result) ->
	# rootTimings = _.chain(result)
	# 	.map((item) ->
	# 		ret =
	# 			url: item.url
	# 			start: item.start
	# 			load: item.load
	# 	)
	# 	.reduce(reducer, [])
	# 	.find(['url', 'http://thepassion2015-release.smalltownheroes.be/motivaties'])
	# 	.pick('timings')
	# 	.value()

	# startArr = _.chain(rootTimings.timings).map('start').value()
	# loadArr = _.chain(rootTimings.timings).map('load').value()
	# console.log '-------startArr-------->', startArr
	# console.log '--------loadArr------->', loadArr
	# console.log JSON.stringify(root, null, '\t')

	# resources = _.chain(result)
	# 	.map('resources')
	# 	.flatten()
	# 	.reduce(reducer, [])
	# 	# .find((resource) -> resource.url is 'http://thepassion2015-cdn.smalltownheroes.be/thepassion2015/release/img/spinner.gif')
	# 	.filter((resource) ->
	# 		averageResource = _.chain(resource.timings).map('load').reduce((a,m,i,p) ->
 #    			a + m/p.length;
	# 		, 0).value()
	# 		long = averageResource > 2000
	# 		if long and not (_.includes(resource.url, 'facebook.com')
	# 			or _.includes(resource.url, 'twitter.com') or _.includes(resource.url, 'google-analytics.com')
	# 			or _.includes(resource.url, 'pusher.com'))
	# 			console.log '--------------->', resource
	# 		long and not (_.includes(resource.url, 'facebook.com') or _.includes(resource.url, 'twitter.com')
	# 			or _.includes(resource.url, 'google-analytics.com') or _.includes(resource.url, 'pusher.com'))
	# 	)
	# 	.map((resource) ->
	# 		resource.url
	# 	)
	# 	.value()
	# console.log JSON.stringify(resources, null, '\t')

