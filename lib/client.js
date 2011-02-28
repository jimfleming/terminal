window.onload = function() {
  var $commandline, $history, $status, socket;
  $status = document.getElementById('current-status');
  $commandline = document.getElementById('command-line');
  $history = document.getElementById('history');
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
    if (message.history != null) {
      $commandline.value = message.history;
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
        break;
      case 'Left':
        socket.send({
          'left': 'left'
        });
        break;
      case 'Right':
        socket.send({
          'right': 'right'
        });
    }
    switch (e.keyCode) {
      case 67:
        if (e.ctrlKey) {
          return socket.send({
            'kill': 'kill'
          });
        }
    }
  });
};