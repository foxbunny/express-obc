#!/usr/bin/env lsc

require! 'shelljs/make'
require! child_process.spawn

SRCDIR = 'src/lib'
TESTSRCDIR = 'src/tests'
LIBDIR = 'lib'
TESTDIR = 'tests'

target.all = ->
  run "lsc -cbo #{LIBDIR} #{SRCDIR}"
  run "lsc -cbo #{TESTDIR} #{TESTSRCDIR}"

target.watch = ->
  run "lsc -cwbo #{LIBDIR} #{SRCDIR}"
  run "lsc -cwbo #{TESTDIR} #{TESTSRCDIR}"
  run "nodemon -w #{LIBDIR} -w #{TESTDIR} -x mocha #{TESTDIR}"

!function run cmd
  [c, ...r] = cmd.split ' '
  spawn c, r, stdio: \inherit

