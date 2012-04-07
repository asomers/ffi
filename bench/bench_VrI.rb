require File.expand_path(File.join(File.dirname(__FILE__), "bench_helper"))

module LibTest
  extend FFI::Library
  ffi_lib LIBTEST_PATH
  attach_function :ffi_bench, :returnInt, [ ], :int, :save_errno => false
  def self.rb_bench; nil; end
end
unless RUBY_PLATFORM == "java" && JRUBY_VERSION < "1.3.0"
  require 'dl'
  require 'dl/import'
  module LibTest
    if RUBY_VERSION >= "1.9.0"
      extend DL::Importer
    else
      extend DL::Importable
    end
    dlload LIBTEST_PATH
    extern "int returnInt()"
  end
end

puts "Benchmark [ ], :int performance, #{ITER}x calls"
10.times {
  puts Benchmark.measure {
    i = 0
    while i < ITER
      LibTest.ffi_bench
      i += 1
    end
  }
}


unless RUBY_PLATFORM == "java" && JRUBY_VERSION < "1.3.0"
puts "Benchmark DL void bench() performance, #{ITER}x calls"
10.times {
  puts Benchmark.measure {
    i = 0
    while i < ITER
      LibTest.returnInt
      i += 1
    end
  }
}
end
puts "Benchmark Invoker.call [ ], :int performance, #{ITER}x calls"

invoker = FFI.create_invoker(LIBTEST_PATH, 'returnInt', [ ], :int)
10.times {
  puts Benchmark.measure {
    i = 0
    while i < ITER
      invoker.call
      i += 1
    end
  }
}

f = FFI::Function.new(:int, [ ], invoker, { :ignore_errno => true, :convention => :default })
puts "Benchmark [ ], :int no-errno performance, #{ITER}x calls"
module NoErrno ;end
f.attach(NoErrno, "ffi_bench")
10.times {
  puts Benchmark.measure {
    i = 0
    while i < ITER
      NoErrno.ffi_bench
      i += 1
    end
  }
}

puts "Benchmark ruby method(no arg)  performance, #{ITER}x calls"
10.times {
  puts Benchmark.measure {
    i = 0
    while i < ITER
      LibTest.rb_bench
      i += 1
    end
  }
}

