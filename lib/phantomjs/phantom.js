var args, input, moment, page, result, system, timer, uuid, webpage;

webpage = require('webpage');

uuid = require('node-uuid');

moment = require('moment');

system = require('system');

timer = require('../timer');

args = system.args;

input = JSON.parse(args[1]);

console.error = function() {
  return system.stderr.write(Array.prototype.join.call(arguments, ' ') + '\n');
};

result = {
  url: input.url,
  pageErrors: [],
  screenshot: {}
};

page = webpage.create();

if (input.viewport != null) {
  page.viewportSize = input.viewport;
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
        if (input.screenshots.success) {
          result.screenshot.success = "screenshots/success-" + (uuid.v4()) + ".png";
          if (input.screenshots.args != null) {
            page.render(result.screenshot.success, input.screenshots.args);
          } else {
            page.render(result.screenshot.success);
          }
        }
        if (input.screenshots.error && result.pageErrors.length) {
          result.screenshot.error = "screenshots/error-" + (uuid.v4()) + ".png";
          if (input.screenshots.args != null) {
            page.render(result.screenshot.error, input.screenshots.args);
          } else {
            page.render(result.screenshot.error);
          }
        }
        console.log(JSON.stringify(result));
        return phantom.exit();
      }, 300);
    } else {
      console.log(JSON.stringify(result));
      return phantom.exit();
    }
  }
});
