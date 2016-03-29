fs         = require 'fs'
path       = require 'path'
async      = require 'async'
_          = require 'lodash'
request    = require 'request'
moment     = require 'moment'
Progress   = require 'progress'

class Motivatie

	constructor: (@options) ->
		@progress = new Progress('ETA: :etas Elapsed: :elapsed (:percent) :current/:total :bar', { total: @options.runs })
		@accounting = {}

	getUploadUrl: (cb) ->
		data =
			name: 'Benoit Shapiro'
			text: 'Ik loop mee omdat ik dan de release omgeving kan DoS-attacken'
			background: '4'
			extension: 'jpg'
		request
			pool: @options.requestPool
			url: @options.getUploadUrl
			method: 'POST'
			headers:
				'Accept': 'application/json'
				'User-Agent': 'Loadscript'
			json: data
		, (error, response, body) =>
			if error?
				cb error
			else
				@addAccounting 'getUploadUrl', response.statusCode
				if response.statusCode is 200
					cb error, body
				else
					cb "GetUploadUrl didn't return HTTP code 200!"

	uploadImage: (data, cb) ->
		if data.uploadUrl? and data.contentType?
			stat = fs.statSync(@options.image)
			requestStream = request.put
				pool: @options.requestPool
				url: data.uploadUrl
				headers:
					'Content-Type': data.contentType
					'Cache-Control': 'max-age=86400000'
					'Content-Length': stat.size
			requestStream.on 'response', (response) =>
				@addAccounting 'uploadImage', response.statusCode
				if response.statusCode is 200
					cb null, response
				else
					cb "UploadImage didn't return HTTP code 200!"
			requestStream.on 'error', (error) ->
				cb error
			fs.createReadStream(@options.image).pipe(requestStream)
		else
			cb 'Could not upload since previous call did not respond correctly!'

	pollImage: (data, cb) ->
		if data.uploadId?
			resp = {}
			b = ''
			async.doUntil(
				(callb) =>
					setTimeout =>
						qs =
							_: moment().valueOf()
						request.get
							pool: @options.requestPool
							url: "#{@options.getuigenisUrl}/#{data.uploadId}"
							qs: qs
						, (error, response, body) ->
							resp = response
							b = body
							callb error
					, @options.pollTimeout
				, ->
					!!b
				, (err) =>
					if err?
						cb err
					else
						@addAccounting 'pollImage', resp.statusCode
						if resp.statusCode is 200
							cb null, JSON.parse(b)
						else
							cb "PollImage didn't return HTTP code 200!"
			)
		else
			cb 'Could not poll since previous call did not respond correctly!'

	addAccounting: (stage, code) ->
		@accounting[stage] or= {}
		@accounting[stage][code] or= 0
		@accounting[stage][code]++

	run: (cb) ->
		async.mapLimit [0...@options.runs], @options.concurrency, (girl, callb) =>
			work = []
			work.push (callback) =>
				@getUploadUrl callback
			work.push (data, callback) =>
				@uploadImage data, (err, result) ->
					callback err, data
			work.push (data, callback) =>
				@pollImage data, callback
			async.waterfall work, (err, result) =>
				@progress.tick()
				callb err,
					result: result
		, (err, result) ->
			cb err, _.chain(result).flatten().compact().value()

count = 100

options =
	requestPool:
		maxSockets: count
	runs: count
	concurrency: count
	pollTimeout: 1000
	getUploadUrl: 'http://thepassion2015-release.smalltownheroes.be/getuploadurl'
	getuigenisUrl: 'http://thepassion2015-release.smalltownheroes.be/api/v1/storyline/getuigenissen_by_id'
	image: path.join(__dirname, './image.jpg')

motivatie = new Motivatie(options)
motivatie.run (err, result) ->
	console.error err if err?
	console.log JSON.stringify(result, null, '\t') if result?
	console.log JSON.stringify(motivatie.accounting, null, '\t')
