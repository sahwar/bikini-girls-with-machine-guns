var Timer, args, err, error, input, page, result, system, timer, uuid, webpage;

webpage = require('webpage');

uuid = require('node-uuid');

system = require('system');

Timer = (function() {
  function Timer() {
    this.resources = [];
  }

  Timer.prototype.start = function() {
    return this.startTime = new Date();
  };

  Timer.prototype.stop = function() {
    return this.endTime = new Date();
  };

  Timer.prototype.request = function(resource) {
    return this.resources[resource.id] = {
      request: resource,
      startReply: null,
      endReply: null
    };
  };

  Timer.prototype.replyStart = function(resource) {
    var foundResource;
    foundResource = this.resources[resource.id];
    if (foundResource != null) {
      return foundResource.startReply = resource;
    }
  };

  Timer.prototype.replyEnd = function(resource) {
    var foundResource;
    foundResource = this.resources[resource.id];
    if (foundResource != null) {
      return foundResource.endReply = resource;
    }
  };

  Timer.prototype.createHAR = function(address, title) {
    var entries, result;
    entries = [];
    this.resources.forEach(function(resource) {
      var endReply, request, startReply;
      request = resource.request;
      startReply = resource.startReply;
      endReply = resource.endReply;
      if (!request || !startReply || !endReply) {
        return;
      }
      if (request.url.match(/(^data:image\/.*)/i)) {
        return;
      }
      return entries.push({
        startedDateTime: request.time.toISOString(),
        time: endReply.time - request.time,
        request: {
          method: request.method,
          url: request.url,
          httpVersion: "HTTP/1.1",
          cookies: [],
          headers: request.headers,
          queryString: [],
          headersSize: -1,
          bodySize: -1
        },
        response: {
          status: endReply.status,
          statusText: endReply.statusText,
          httpVersion: "HTTP/1.1",
          cookies: [],
          headers: endReply.headers,
          redirectURL: "",
          headersSize: -1,
          bodySize: startReply.bodySize,
          content: {
            size: startReply.bodySize,
            mimeType: endReply.contentType
          }
        },
        cache: {},
        timings: {
          blocked: 0,
          dns: -1,
          connect: -1,
          send: 0,
          wait: startReply.time - request.time,
          receive: endReply.time - startReply.time,
          ssl: -1
        },
        pageref: address
      });
    });
    return result = {
      log: {
        version: '1.2',
        creator: {
          name: 'BikiniGirlsWithMachineGuns',
          version: '0.0.1'
        },
        pages: [
          {
            startedDateTime: this.startTime.toISOString(),
            id: address,
            title: title,
            pageTimings: {
              onLoad: this.endTime - this.startTime
            }
          }
        ],
        entries: entries
      }
    };
  };

  return Timer;

})();

args = system.args;

console.error = function() {
  return system.stderr.write(Array.prototype.join.call(arguments, ' ') + '\n');
};

try {
  input = JSON.parse(args[1]);
} catch (_error) {
  error = _error;
  err = {
    message: error.message
  };
  console.error(JSON.stringify(err));
  phantom.exit();
}

result = {
  url: input.url,
  pageErrors: [],
  screenshot: {}
};

timer = new Timer();

page = webpage.create();

if (input.viewport != null) {
  page.viewportSize = input.viewport;
}

if (input.settings != null) {
  page.settings = input.settings;
}

page.onLoadStarted = function() {
  return timer.start();
};

page.onError = function(message, trace) {
  return result.pageErrors.push({
    message: message,
    trace: trace
  });
};

page.onResourceRequested = function(request) {
  return timer.request(request);
};

page.onResourceReceived = function(response) {
  if (response.stage === 'start') {
    timer.replyStart(response);
  }
  if (response.stage === 'end') {
    return timer.replyEnd(response);
  }
};

page.onNavigationRequested = function(url, type, willNavigate, main) {
  if (main && url !== input.url) {
    return result.redirect = {
      url: url,
      type: type,
      willNavigate: willNavigate,
      main: main
    };
  }
};

page.open(input.url, function(status) {
  result.status = status;
  if (status !== 'success') {
    console.error(JSON.stringify(result));
    return phantom.exit();
  } else {
    timer.stop();
    result.title = page.evaluate(function() {
      return document.title;
    });
    if (input.har) {
      result.har = timer.createHAR(input.url, result.title);
    }
    if (input.screenshots != null) {
      return setTimeout(function() {
        var extension;
        if (input.screenshots.success) {
          if (input.screenshots.args != null) {
            extension = input.screenshots.args.format;
            result.screenshot = "/tmp/screenshots/success-" + (uuid.v4()) + "." + extension;
            page.render(result.screenshot, input.screenshots.args);
          } else {
            result.screenshot = "/tmp/screenshots/success-" + (uuid.v4()) + ".png";
            page.render(result.screenshot);
          }
        }
        if (input.screenshots.error && result.pageErrors.length) {
          if (input.screenshots.args != null) {
            extension = input.screenshots.args.format;
            result.screenshot = "/tmp/screenshots/error-" + (uuid.v4()) + "." + extension;
            page.render(result.screenshot, input.screenshots.args);
          } else {
            result.screenshot = "/tmp/screenshots/error-" + (uuid.v4()) + ".png";
            page.render(result.screenshot);
          }
        }
        console.log(JSON.stringify(result));
        return phantom.exit();
      }, 10);
    } else {
      console.log(JSON.stringify(result));
      return phantom.exit();
    }
  }
});
