express    = require 'express'
{ Router } = require 'express'
Generator  = require './lib/girls'

generator = new Generator()

process.on 'uncaughtException', (err) ->
	console.error err

app = express()

router = new Router()

postHandler = (req, res, next) ->
	data = req.body
	generator.generate data, (err, result) ->
		if err?
			next err
		else
			res.status(200).json result

router.post '/', postHandler

apiBodyParser = require('body-parser').json()
app.use '/', apiBodyParser, router

errorHandler = (err, req, res, next) ->

	switch err.name
		when 'BadRequestError'
			status = err.status or 400
			response =
				message: err.message or 'BadRequest'
				name: err.name or 'BAD_REQUEST'
		else
			status = err.status or 500
			response =
				message: err.message or 'Internal Server Error'
				name: err.name or 'SERVER_ERROR'

	error =
		status: status
		name: err.name
		message: response.message

	res.error = error
	res.status(status).json(response)

app.use errorHandler

module.exports = app