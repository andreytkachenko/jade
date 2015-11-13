/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

var JisonLex = require('jison-lex');
var fs = require('fs');

var grammar = fs.readFileSync('./lib/lexer.l', 'utf8');
var test = fs.readFileSync('./test2.jade', 'utf8');

var lexerSource = JisonLex.generate(grammar);
var lexer = new JisonLex(grammar);

lexer.setInput(test + '\n');
data = [];
while ((t = lexer.lex()) !== 1) {
    console.log(t, ":", lexer.yytext)
}
