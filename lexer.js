/**
 * Created by tkachenko on 16.04.15.
 */
var JadeLexer = require("./src/lexer.js");
var fs = require("fs");

var test = fs.readFileSync('./test.jade', 'utf8');
var token;

var lexer = JadeLexer(test);

do {
    token = lexer.lex();
    console.log(token, lexer.yytext||'');
} while (token !== 'EOF');
