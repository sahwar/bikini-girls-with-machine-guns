module.exports =
	test:
		options:
			reporter: if process.env.CIRCLECI then 'xunit' else 'spec'
			require: 'coffee-script/register'
			captureFile: if process.env.CIRCLECI then 'report/test/backend.xml' else 'report/test/backend.spec'
			quiet: false, # Optionally suppress output to standard out (defaults to false)
			timeout: 10000
			clearRequireCache: false # Optionally clear the require cache before running tests (defaults to false)
			colors: true
		src: ['test/**/*.coffee']
