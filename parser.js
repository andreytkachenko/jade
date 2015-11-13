/**
 * Created by tkachenko on 16.04.15.
 */
var parser = require("./dist/parser").parser;
parser.yy.$ = require("./lib/scope");

var fs = require("fs");
console.log(JSON.stringify(parser.parse(fs.readFileSync('./test2.jade', 'utf8') + '\n'), null, 4));
