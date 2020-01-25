package medic;

import medic.TestInfo;

class DefaultReporter implements Reporter {

  public function new() {}

  public function progress(info:TestInfo):Void {
    switch info.status {
      case Passed: print('.');
      case Failed(e): switch e {
        case Warning(_): print('W');
        case Assertion(_, _): print('F');
        case UnhandledException(_, _): print('E');
        case Multiple(_): print('E');
      }
    }
  }

  public function report(result:Result) {
    var errors:Array<TestInfo> = [];
    var total:Int = 0;
    var success:Int = 0;
    var failed:Int = 0;
    var buf = '';

    for (c in result.cases) {
      for (test in c.tests) {
        total++;
        switch test.status {
          case Passed: success++;
          case Failed(_):
            failed++;
            errors.push(test);
        }
      }
    }

    buf += '\n${failed == 0 ? 'OK' : 'FAILED'} ${total} tests, ${success} success, ${failed} failed';
    
    if (errors.length > 0) {
      buf += '\n';
      for (info in errors) { 
        var description = info.description.length > 0 ? ' "${info.description}"' : '';
        var out = '[${info.className}::${info.field}()${description}] ';
        function display(status:TestStatus) {
          switch (status) {
            case Passed:
            case Failed(e): switch e {
              case Warning(message): out += '(warning) ${message}';
              case Assertion(message, pos): out += '(failed) ${pos.fileName}:${pos.lineNumber} - ${message}';
              case UnhandledException(message, backtrace): out += '(unhandled exception) ${message} ${backtrace}';
              case Multiple(errors): for (e in errors) display(Failed(e)); 
            }
          }
        }
        display(info.status);
        buf += '${out}\n';
      }
    }

    print(buf);
    #if js
      js.Syntax.code('if (typeof process != "undefined" && process.exit) process.exit({0} == 0 ? 0 : 1)', failed);
    #else
      Sys.exit(failed == 0 ? 0 : 1);
    #end
  }

  function print(v:Dynamic) {
    #if js
      js.Syntax.code('
        var msg = {0};
        var safe = {1};
        var d;
        if (
          typeof document != "undefined"
          && (d = document.getElementById("medic-trace")) != null
        ) {
          d.innerHTML += safe; 
        } else if (
          typeof process != "undefined"
          && process.stdout != null
          && process.stdout.write != null
        ) {
          process.stdout.write(msg);
        } else if (typeof console != "undefined") {
          console.log(msg);
        }
      ', Std.string(v), StringTools.htmlEscape(v).split('/n').join('</br>'));
    #else 
      Sys.print(Std.string(v));
    #end
  }

}