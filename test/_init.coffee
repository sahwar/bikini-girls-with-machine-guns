global.assert = require('chai').assert
global.expect = require('chai').expect

log           = require '../lib/log'

log.trace = ->
log.debug = ->
log.info = ->
log.warn = ->
log.error = ->

global.initialize = (done) ->
	done()

before initialize
after initialize
