(function() {
  var command_cwd, command_history, command_history_index, cwd, exec, fs, http, io, path, respond_404, respond_500, server, socket, sys, url;
  http = require('http');
  url = require('url');
  fs = require('fs');
  sys = require('sys');
  path = require('path');
  io = require('socket.io');
  exec = require('child_process').exec;
  process.title = 'terminal.js';
  cwd = process.cwd();
  respond_404 = function(response) {
    response.writeHead(404, {
      'Content-Type': 'text/plain'
    });
    response.write('404 Not Found\n');
    response.end();
  };
  respond_500 = function(response, error) {
    response.writeHead(500, {
      'Content-Type': 'text/plain'
    });
    response.write(error + '\n');
    response.end();
  };
  server = http.createServer(function(request, response) {
    var filename, mapping, uri;
    if (process.cwd() !== cwd) {
      process.chdir(cwd);
    }
    mapping = {
      '/': 'index.html',
      '/client.js': 'client.js',
      '/styles.css': 'styles.css',
      '/font.css': 'font.css',
      '/DroidSansMono.ttf': 'DroidSansMono.ttf'
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
      });
    } else {
      respond_404(response);
      return;
    }
  });
  server.listen(8000);
  socket = io.listen(server, {
    transports: ['websocket']
  });
  command_history = [];
  command_history_index = 0;
  command_cwd = cwd;
  socket.on('connection', function(client) {
    client.send(JSON.stringify({
      'cwd': command_cwd
    }));
    client.on('message', function(data) {
      var pieces;
      if ((data.up != null) && command_history.length > 0) {
        command_history_index--;
        if (command_history_index < 0) {
          command_history_index = command_history.length - 1;
        }
        client.send(JSON.stringify({
          'history': command_history[command_history_index]
        }));
      }
      if ((data.down != null) && command_history.length > 0) {
        command_history_index++;
        command_history_index %= command_history.length;
        client.send(JSON.stringify({
          'history': command_history[command_history_index]
        }));
      }
      if (data.command != null) {
        pieces = data.command.split(' ');
        if (pieces[0] === 'exit' || pieces[0] === 'quit') {
          process.exit();
        }
        if (pieces[0] === 'cd') {
          try {
            process.chdir(command_cwd);
            command_cwd = fs.realpathSync(pieces[1]);
            client.send(JSON.stringify({
              'cwd': command_cwd
            }));
          } catch (error) {
            client.send(JSON.stringify({
              'error': error.toString(),
              'cwd': command_cwd
            }));
          }
          return;
        }
        command_history.push(data.command);
        exec(data.command, {
          cwd: command_cwd
        }, function(error, stdout, stderr) {
          if (stdout != null) {
            client.send(JSON.stringify({
              'output': stdout.toString(),
              'cwd': command_cwd
            }));
          }
          if (stderr != null) {
            client.send(JSON.stringify({
              'error': stderr.toString(),
              'cwd': command_cwd
            }));
          }
          if (error) {
            return sys.debug(error.toString());
          }
        });
        command_history_index = 0;
      }
    });
  });
}).call(this);
