Bgwmg = require '../..'

describe "Bikini Girls With Machine Guns - PhantomJS", ->

	@timeout 100000

	it 'load tests successfully on known url fetch', (done) ->
		input = require './data/example.json'
		generator = new Bgwmg()
		generator.generate input
		generator.on 'error', done
		generator.on 'finish', (results) ->
			expect(results).to.be.an('object').to.have.property('success').to.have.property('url').to.eql(input.url)
			expect(results.success).to.be.an('object').to.have.property('status').to.eql('success')
			expect(results.success).to.be.an('object').to.have.property('har')
			expect(results.success).to.be.an('object').to.have.property('pageErrors').to.be.an('array')
			expect(results.success).to.be.an('object').to.have.property('screenshot').to.be.a('string')
			done()

	it 'load tests successfully on known url fetch but has pageErrors', (done) ->
		input = require './data/page_errors.json'
		generator = new Bgwmg()
		generator.generate input
		generator.on 'error', done
		generator.on 'finish', (results) ->
			expect(results).to.be.an('object').to.have.property('success').to.have.property('url').to.eql(input.url)
			expect(results.success).to.be.an('object').to.have.property('status').to.eql('success')
			expect(results.success).to.be.an('object').to.not.have.property('har')
			expect(results.success).to.be.an('object').to.have.property('pageErrors').to.be.an('array').to.not.eql([])
			expect(results.success).to.be.an('object').to.have.property('screenshot').to.be.a('string')
			done()

	it 'fails on unknown url fetch', (done) ->
		input = require './data/fail.json'
		generator = new Bgwmg()
		generator.generate input
		generator.on 'error', done
		generator.on 'finish', (results) ->
			expect(results).to.be.an('object').to.have.property('error').to.have.property('url').to.eql(input.url)
			expect(results.error).to.be.an('object').to.have.property('status').to.eql('fail')
			done()
