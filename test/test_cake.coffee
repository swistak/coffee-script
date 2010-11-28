# This tries to test Cke file functionality.
# Since this test file can be run from cake itself sometimes we need to make sure not to include
# tasks and/or options from that cake file.

executed_tests = []

check = (name, test) -> 
  executed_tests = []
  test()

# Test tasks definitions
task "cake_test", "Test case", (options) ->
  executed_tests.push "cake_test"

task "cake_test_second", "", (options) ->
  invoke "cake_test"
  invoke "cake_test"
  executed_tests.push "cake_test_second"

rule "/tmp/cake_rule.txt", ["/tmp/cake_rule1.txt", "/tmp/cake_rule2.txt"], ->
  file = new node.fs.File()
  file.open("/tmp/cake_rule.txt", "w+")
  file.write("hello world")
  file.close()

check "tasks are declared", ->
  ok tasks, "Tasks variable is not defined"

  tl = 0
  task_names = []
  for k,v of tasks when k.search("cake_") >= 0
    tl++
    task_names.push k

  eq tl, 2, "Task names: "+task_names.toString()
  eq "cake_test", task_names[0]
  eq "cake_test_second", task_names[1]
  #ok tasks["/tmp/cake_rule.txt"]

check "basic task declaration.", ->
  invoke "cake_test"
  eq executed_tests[0], "cake_test"

check "calling of other tasks", -> 
  invoke "cake_test_second"
  eq executed_tests.length, 3
  eq executed_tests[0], "cake_test"
  eq executed_tests[1], "cake_test"
  eq executed_tests[2], "cake_test_second"

check "option works", ->
  old_length = option().length
  switches = option("-o", "--output [DIR]", "directory for testing")
  eq 1, switches.length - old_length
  eq switches.pop()[0], "-o"

check "rules work", ->
  ok 1
