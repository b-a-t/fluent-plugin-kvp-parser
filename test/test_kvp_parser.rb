require 'fluent/test'
require 'fluent/parser'
require 'fluent/plugin/parser_kvp'

module ParserTest
  include Fluent

  class KVPParserTest < ::Test::Unit::TestCase
    include ParserTest

    def create_driver(conf)
      Fluent::Test::ParserTestDriver.new(Fluent::TextParser::KVPParser).configure(conf)
    end

    def test_basic
      d = create_driver({})
      d.instance.parse("k1=v1 k2=v2") {|_, v| assert_equal({"k1"=>"v1", "k2"=>"v2"}, v)}
      d.instance.parse("k.1=v1 k.2=v2") {|_, v| assert_equal({"k.1"=>"v1", "k.2"=>"v2"}, v)}
      d.instance.parse("k1=v1    k2=v2") {|_, v| assert_equal({"k1"=>"v1", "k2"=>"v2"}, v)}
      d.instance.parse("k2=v2 k1=v1") {|_, v| assert_equal({"k1"=>"v1", "k2"=>"v2"}, v)}
      d.instance.parse("k2=v2\tk1=v1") {|_, v| assert_equal({"k1"=>"v1", "k2"=>"v2"}, v)}
      d.instance.parse("k2=v2\t k1=v1") {|_, v| assert_equal({"k1"=>"v1", "k2"=>"v2"}, v)}
      d.instance.parse("k2=v2\t \t k1=v1") {|_, v| assert_equal({"k1"=>"v1", "k2"=>"v2"}, v)}
      d.instance.parse("k1=\"v 1\"") {|_, v| assert_equal({"k1"=>"v 1"}, v)}
      d.instance.parse("k1=\"v 1\" k2=\"v 2\"") {|_, v| assert_equal({"k1"=>"v 1", "k2"=>"v 2"}, v)}
      d.instance.parse("k1=\"v \\\"1\\\"\" k2=\"v \\\"2\\\"\"") {|_, v| assert_equal({"k1"=>"v \\\"1\\\"", "k2"=>"v \\\"2\\\""}, v)}
      d.instance.parse("aaa k.1=v1 k.2=v2") {|_, v| assert_equal({"k.1"=>"v1", "k.2"=>"v2"}, v)}
      d.instance.parse("k0=0 aaa k.1=v1 k.2=v2") {|_, v| assert_equal({"k0"=>"0", "k.1"=>"v1", "k.2"=>"v2"}, v)}
    end

    def test_with_types
      d = create_driver({"types" => "k1:integer"})
      d.instance.parse("k1=100") {|_, v| assert_equal(100, v["k1"])}
    end

    def test_with_time
      d = create_driver({"types" => "time:time"})
      d.instance.parse("k1=foo time=1970-01-01T01:00:00Z") {|time, v|
        assert_equal(3600, time)
        assert_equal("foo", v["k1"])
      }
    end

    def test_with_custom_time_key
      d = create_driver({"time_key" => "my_time", "types" => "my_time:time"})
      d.instance.parse("k1=foo my_time=1970-01-01T01:00:00Z") {|time, v|
        assert_equal(3600, time)
        assert_equal("foo", v["k1"])
      }
    end

    def test_custom_delimiter
      d = create_driver({"key_value_pair_delimiter" => "|"})
      d.instance.parse("k1=v1|k2=v2") {|_, v| assert_equal({"k1"=>"v1", "k2"=>"v2"}, v)}
      d.instance.parse("k1=v1||k2=v2") {|_, v| assert_equal({"k1"=>"v1", "k2"=>"v2"}, v)}

      d = create_driver({"key_value_pair_delimiter" => "@ "})
      d.instance.parse("k1=v1@k2=v2 k3=v3") {|_, v|
        assert_equal({"k1"=>"v1", "k2"=>"v2", "k3"=>"v3"}, v)
      }
    end

    def test_custom_kv_char
      d = create_driver({"key_value_delimiter" => "#"})
      d.instance.parse("k1#v1 k2#v2") {|_, v| assert_equal({"k1"=>"v1", "k2"=>"v2"}, v)}
    end

    def test_key_prefix
      d = create_driver({"key_prefix" => "parsed_"})
      d.instance.parse("k1=v1 k2=v2") {|_, v| assert_equal({"parsed_k1"=>"v1", "parsed_k2"=>"v2"}, v)}
    end

  end
end
