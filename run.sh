#!/bin/sh

source app.config
cd app

shotgun --port 8080 server.rb

