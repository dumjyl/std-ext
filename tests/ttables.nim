import
   std_ext/tables

var x = Table.init({"abc": "def", "foo": "bar"})
assert(x["abc"] == "def")
assert(x["foo"] == "bar")
