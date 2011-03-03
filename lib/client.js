(function() {
  window.onload = function() {
    var $commandline, $cwd, $history, $status, socket;
    $status = document.getElementById('current-status');
    $commandline = document.getElementById('command-line');
    $history = document.getElementById('history');
    $cwd = document.getElementById('cwd');
    socket = new io.Socket(location.hostname, {
      transports: ['websocket']
    });
    socket.connect();
    socket.on('connect', function() {
      return $status.className = 'connected';
    });
    socket.on('close', function() {
      return $status.className = '';
    });
    socket.on('connect_failed', function() {
      return $status.className = 'error';
    });
    socket.on('disconnect', function() {
      return $status.className = '';
    });
    socket.on('message', function(message) {
      message = JSON.parse(message);
      if (message.output != null) {
        $history.innerHTML += message.output + '\n';
      }
      if (message.error != null) {
        $history.innerHTML += '<span class="error">' + message.error + '</span>\n';
      }
      if (message.history != null) {
        $commandline.value = message.history;
      }
      if (message.cwd != null) {
        $cwd.innerHTML = message.cwd;
      }
      if (message.output === '[H[2J') {
        $history.innerHTML = '';
      }
      return $history.scrollTop = $history.scrollHeight;
    });
    return $commandline.addEventListener('keyup', function(e) {
      switch (e.keyIdentifier) {
        case 'Enter':
          socket.send({
            'command': $commandline.value
          });
          $history.innerHTML += '<span class="command">' + $commandline.value + '</span>\n';
          $commandline.value = '';
          $history.scrollTop = $history.scrollHeight;
          break;
        case 'Up':
          socket.send({
            'up': 'up'
          });
          break;
        case 'Down':
          socket.send({
            'down': 'down'
          });
      }
      switch (e.keyCode) {
        case 67:
          if (e.ctrlKey) {
            $history.innerHTML += '<span class="command">' + $commandline.value + '^C</span>\n';
            return $commandline.value = '';
          }
      }
    });
  };
}).call(this);
