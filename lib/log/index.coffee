bunyan = require 'bunyan'

module.exports = log = bunyan.createLogger
	src: process.env.NODE_ENV isnt 'production'
	level: if process.env.NODE_ENV is 'production' then 'info' else 'debug'
	name: 'bikiniGirlsWithMachineGuns'
