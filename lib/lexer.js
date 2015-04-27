var JisonLex = require("jison-lex");
var fs = require("fs");

module.exports = function (input) {
    var lexer = JisonLex(fs.readFileSync('./lib/lexer.l', 'utf8'));
    lexer._tokens = [];
    lexer._lex = lexer.lex;
    lexer._setInput = lexer.setInput;

    lexer._nextToken = function () {
        if (this._tokens.length) {
            return this._tokens.shift();
        }
        var token = this._lex();
        if (Object.prototype.toString.call(token) === "[object Array]") {
            this._tokens = token.slice(1);
            return token[0];
        } else {
            return token;
        }
    };

    lexer.lex = function () {
        return this._nextToken();
    };

    lexer.setInput = function (input, yy) {
        return this._setInput(input + '\n', yy);
    };

    if (input) {
        lexer.setInput(input);
    }

    return lexer;
};