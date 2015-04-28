/**
 * Created by tkachenko on 16.04.15.
 */
var parser = require("./lib/parser");
var nodes = require("./lib/nodes");
parser.lexer = require("./lib/lexer")();
parser.yy.$ = nodes;

var fs = require("fs");
var test = fs.readFileSync('./test.jade', 'utf8');
console.log('generated');
console.log(JSON.stringify(parser.parse(test), null, 4));