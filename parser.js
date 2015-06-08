/**
 * Created by tkachenko on 16.04.15.
 */
var parser = require("./dist/parser").parser;
parser.yy.$ = require("./lib/scope");

var fs = require("fs");
var test = fs.readFileSync('./test.jade', 'utf8');

console.log(JSON.stringify(parser.parse(test + '\n'), null, 4));