_       = require 'lodash'
async   = require 'async'
request = require 'request'
milk    = require 'milk'
path    = require 'path'
fs      = require 'fs'
uuid    = require 'node-uuid'

class Step

	constructor: (@options, @context, @pool) ->

	run: (cb) ->
		if @options.file?
			work = []
			work.push (callb) =>
				@fetchFile @options.file, (err, filename) =>
					@context.file = {}
					_.merge @context.file, fs.statSync(filename)
					callb err, filename
			work.push (filename, callb) =>
				@request filename, callb
			async.waterfall work, cb
		else
			@request null, cb

	request: (file, cb) ->
		requestOptions =
			pool: @pool
			method: @options.method
			url: @evaluate @options.url
			qs: @evaluate @options.qs
			headers: @evaluate @options.headers
			json: @evaluate @options.body
			form: @evaluate @options.form
		if file?
			req = request requestOptions
			req.on 'response', (response) =>
				console.log JSON.stringify(response, null, '\t')
				if response.statusCode is @options.expect
					cb null, @capture(response)
				else
					cb
						name: 'ExpectationFailure'
			req.on 'error', (error) ->
				cb error
			fs.createReadStream(file).pipe(req)
		else
			request requestOptions, (error, response, body) =>
				if error?
					cb error
				else
					if response.statusCode is @options.expect
						cb null, @capture(body)
					else
						cb
							name: 'ExpectationFailure'

	capture: (body) ->
		captured = {}
		if @options.captures?
			for cap in @options.captures
				if cap.at is '.'
					captured[cap.as] = body
				else
					captured[cap.as] = _.chain(body).at(cap.at).first().value()
		captured

	evaluate: (opt) ->
		if _.isString opt
			milk.render(opt, @context)
		else if _.isObject opt
			_.mapValues opt, (o) =>
				if _.isString(o)
					milk.render(o, @context)
				else
					o
		else
			opt

	fetchFile: (url, cb) ->
		filename = "/tmp/#{uuid.v4()}#{path.extname(url)}"
		file = fs.createWriteStream filename

		download = request(
			url: url
			method: 'GET'
		).pipe(file)

		download.on 'error', (err) ->
			cb err
		download.on 'finish', ->
			cb null, filename


module.exports = Step