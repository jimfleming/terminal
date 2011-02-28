var exec, fs, http, io, path, respond_404, respond_500, server, socket, spawn, url;
http = require('http');
url = require('url');
fs = require('fs');
path = require('path');
io = require('socket.io');
spawn = require('child_process').spawn;
exec = require('child_process').exec;
process.title = 'terminal.js';
respond_404 = function(response) {
  response.writeHead(404, {
    'Content-Type': 'text/plain'
  });
  response.write('404 Not Found\n');
  response.end();
  return;
};
respond_500 = function(response, error) {
  response.writeHead(500, {
    'Content-Type': 'text/plain'
  });
  response.write(error + '\n');
  response.end();
  return;
};
server = http.createServer(function(request, response) {
  var filename, mapping, uri;
  mapping = {
    '/': 'index.html',
    '/client.js': 'client.js',
    '/styles.css': 'styles.css'
  };
  uri = url.parse(request.url).pathname;
  filename = 'lib/' + mapping[uri];
  if (filename) {
    path.exists(filename, function(exists) {
      if (!exists) {
        respond_500(response);
        return;
      }
      fs.readFile(filename, 'binary', function(error, file) {
        if (error != null) {
          respond_500(response);
          return;
        }
        response.writeHead(200);
        response.write(file, 'binary');
        return response.end();
      });
      return;
    });
  } else {
    respond_404(response);
    return;
  }
  return;
});
server.listen(8000);
socket = io.listen(server, {
  transports: ['websocket']
});
socket.on('connection', function(client) {
  var client_history, client_index;
  client_index = 0;
  client_history = [];
  client.on('message', function(data) {
    var child;
    if (data.kill != null) {
      client.send(JSON.stringify({
        'output': '^C'
      }));
      client_index = 0;
    }
    if ((data.up != null) && client_history.length > 0) {
      client_index--;
      if (client_index < 0) {
        client_index = client_history.length - 1;
      }
      client.send(JSON.stringify({
        'history': client_history[client_index]
      }));
    }
    if ((data.down != null) && client_history.length > 0) {
      client_index++;
      client_index %= client_history.length;
      client.send(JSON.stringify({
        'history': client_history[client_index]
      }));
    }
    if (data.command != null) {
      client_history.push(data.command);
      child = exec(data.command, function(error, stdout, stderr) {
        if (stdout != null) {
          client.send(JSON.stringify({
            'output': stdout.toString()
          }));
        }
        if (stderr != null) {
          client.send(JSON.stringify({
            'output': stderr.toString()
          }));
        }
        if (error != null) {
          return client.send(JSON.stringify({
            'output': error.toString()
          }));
        }
      });
      client_index = 0;
    }
    return;
  });
  return;
});