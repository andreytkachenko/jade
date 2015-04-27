var Parser = require("jison").Parser;
var fs = require('fs');

module.exports = new Parser(fs.readFileSync('./lib/parser.y', 'utf-8'));