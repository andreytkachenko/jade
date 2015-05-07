var parser = require("./dist/parser");
parser.yy.$ = require("./lib/scope");

var Compiller = function (options) {
    this._buff = [];
};

Compiller.prototype = {
    _buff: [],

    initialize: function (parser, lexer) {

    },

    write: function (str) {
        this._buff.push(str);
    },

    writeBuff: function (str) {
        this.write('__buff[__buff.length]="' + str.replace('"', '\\"') + '";');
    },

    parseFile: function (fileName) {
        return parser.parse(fileName);
    },

    compile: function (fileName) {
        this.write('(function(){');
        this.write('var __mixins={},__files={},__blocks={},__buff=[];');
        this.compileFile(fileName);
        this.write('return __buff.join(";");});');
    },

    compileBlock: function (nodes) {
        for (var i = 0; i < nodes.length; i++) {

        }
    },

    compileFile: function (fileName) {
        this.write('__files["'+fileName+'"]=function(){');
        this.compileBlock(this.parseFile(fileName));
        this.write('};');
    },

    compileMixin: function (node) {

    },

    compileTag: function (node) {
        var attributes;
    },

    compileInclude: function (node) {
        return this.compileFile(node.href);
    }
};

module.exports = function (ast, options) {
    var c = new Compiler();
    return c.compile(ast);
};





