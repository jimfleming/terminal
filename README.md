[Terminal](https://github.com/ikarosdaedalos/terminal)
========

Simple web-based terminal front-end using node.js and socket.io for a school assignment.


Requirements
------------

* git
* [node.js](http://nodejs.org/)
* [socket.io](http://socket.io/)
* websockets-enabled browser (Chrome, Chromium, maybe Firefox 4 or IE9)

This has only been tested on Ubuntu+Chromium and OSX+Chrome. It may work under other operating systems (Windows, etc.) or in other browsers (Firefox, Safari, etc.)
It definitely will not work in IE6 - IE8 (it may work in IE9).


Installation
------------

### install git ###
  1. `sudo apt-get -y install git-core gitosis`
  
### install [node.js](http://nodejs.org/#download) ###
  1. `git clone git://github.com/joyent/node.git`
  2. `cd node # or whatever the folder is called that was downloaded`
  3. `./configure`
  4. `make`
  5. `make install`

### install [npm](http://npmjs.org/ "node package manager") ([instructions on github](https://github.com/isaacs/npm)) ###
  1. `curl http://npmjs.org/install.sh | sh`

### install [socket.io](http://socket.io/)
  1. `npm install socket.io`

### run ###
  1. `node lib/server.js # from within terminal folder`