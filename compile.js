/**
 * Created by tkachenko on 30.04.15.
 */

var parser = require("./lib/parser");
var nodes = require("./lib/nodes");
parser.lexer = require("./lib/lexer")();
compile = require("./lib/compiler");
parser.yy.$ = nodes;

var fs = require("fs");
var test = fs.readFileSync('./test.jade', 'utf8');

console.log(compile(parser.parse(test)));