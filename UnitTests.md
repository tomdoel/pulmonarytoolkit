# Unit tests #

The PTK provides a simple framework for developing and running unit tests.
Unit tests are helpful for the development of new code, but are particularly useful for regression testing (detecting when code changes cause unanticipated consequences).

## Running tests ##

From the Matlab command window, run
```
PTKRunTests
```
This will run all tests and report whether each one passes or fails.

You can also run a specific test
```
PTKRunTests test_name
```
where test\_name is the name of the test class you want to run. You can run multiple tests by passing them as a cell array, e.g.
```
PTKRunTests({'first test name', 'second test name', 'third test name'})
```


### Note: if you are using the debugger ###

Some tests deliberately trigger a special type of exception (PTKTestException), in order to ensure errors are detected when they should be.

If you have your debugger set to stop on all exceptions, then this will trigger when the tests are run.

To stop this happening, set the following debugging option:

Editor tab > Breakpoints > Stop if errors/warnings for all files > Try/Catch errors > Never stop when an error is caught

Or configure your debugger to not stop on PTKTestExceptions


## Unit test files ##

Unit tests are stored in the \Test folder. Each file in this folder is a class of type PTKTest, which contains a number of tests. Normally, a single test class is used to test a single real class. The test filename generally corresponds to the real class or function being tested, e.g. the test class TestStack tests the real class PTKStack.


## Adding tests ##

A test is added by creating a new class in the \Test directory. This class must inherit from PTKTest. All code in the test must be invoked by the constructor, as the test will be executed by instantiating and then deleting an object of the test class. Tests can be put into methods, providing the methods are called by the constructor.

## Test coding standards ##

In general, one test class should be created for each corresponding class (or function file) being tested. Test classes should be called "TestFoo" corresponding to "PTKFoo" and are placed in \Test. Classes required as parameters  to the class being tested should in general be mocked (fake objects are OK where the interaction is not important). Mock and fake objects objects should be placed in \Library\Test, since these are not tests in themselves but helper classes.