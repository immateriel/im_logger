require 'logger'
require 'benchmark'

module ImLogger
  class Log
    def self.parse_binding(bnd)
      tags=[]
      if bnd

        method=bnd.eval("__method__")
      method_s=method.to_s
      kaller=bnd.eval("self")
      if kaller.class==Class
        # singleton
        klass=kaller
        while (klass and !klass.singleton_methods(false).include?(method))
          klass=klass.superclass
        end
        method_s="self.#{method_s}"
        tags << klass.to_s
        tags << method_s
      else
        klass=kaller.class
        while (klass and !klass.instance_methods(false).include?(method))
          klass=klass.superclass
        end
        if klass.to_s==""
          klass=kaller.class
        end
        tags << klass.to_s
        if kaller.respond_to?('id')
          tags << kaller.id
        end

        tags << method_s
      end
      else
      end

      tags
    end

    def self.binding_string(bnd)
      cols=self.parse_binding(bnd)
      if cols.length > 0
        cols.join(".")+" "
      else
        ""
      end
    end

    @@logger=nil

    def self.set_logger(logger)
      @@logger=logger
      if @@logger.respond_to?(:formatter)
      @@logger.formatter=proc { |severity, datetime, progname, msg|
        "[#{severity}] [pid:#{Process.pid}] [#{datetime}] #{msg}\n"
      }
      end
      nil
    end

    def self.logger
      unless @@logger
        self.set_logger(Logger.new(STDOUT))
      end
      @@logger
    end

    def self.message(text)
      text=text.to_s.strip
      if text.split("\n").length > 1
        text.split("\n")
      else
        [text]
      end
    end

    def self.info(binding, text)
      self.message(text).each do |t|
        self.logger.info(binding_string(binding)+t)
      end
      nil
    end

    def self.debug(binding, text)
      self.message(text).each do |t|
        self.logger.debug(binding_string(binding)+t)
      end
      nil
    end

    def self.error(binding, text)
      self.message(text).each do |t|
        self.logger.error(binding_string(binding)+t)
      end
      nil
    end

    def self.warn(binding, text)
      self.message(text).each do |t|
        self.logger.warn(binding_string(binding)+t)
      end
      nil
    end

    def self.benchmark(bnd, msg)
      ms=Benchmark.ms { yield }
      self.info(bnd, "[benchmark] #{msg} : #{(ms * 10).to_i/10.0}ms")
    end

  end
end