var parser  = require("../dist/parser").parser;
var fs      = require("fs");

parser.yy.$ = require("./scope");

var Compiller = function (options) {
    this._buff = [];
    this.options = options;
};

Compiller.prototype = {
    _buff: [],

    write: function (str) {
        this._buff.push(str);
    },

    writeBuff: function (str) {
        this.write('__buff[__buff.length]="' + str.replace('"', '\\"') + '";');
    },

    parseFile: function (fileName) {
        return parser.parse(fs.readFileSync(fileName, 'utf8') + '\n');
    },

    compile: function (fileName) {
        this.write('(function(){');
        this.write('var __mixins={},__files={},__blocks={},__tags=[];');
        this.compileFile(fileName);
        this.write('return __tags;\n});');

        return this._buff.join('\n');
    },

    compileBinaryExpression: function (node) {
        return this.compileNode(node.left) + ' ' +  node.operator + ' ' + this.compileNode(node.right);
    },

    compileUnaryExpression: function (node) {
        return node.operator + ' ' + this.compileNode(node.right);
    },

    compileVariableStatement: function (node) {

    },



    compileBlock: function (nodes) {
        var node;
        for (var i = 0; i < nodes.length; i++) {
            node = nodes[i];
            if (this['compile' + node.type]) {
                this['compile' + node.type](node);
            }
        }
    },

    compileFile: function (fileName) {
        this.write('__files["'+fileName+'"]=function(){');
        this.compileBlock(this.parseFile(fileName));
        this.write('};');
    },

    compileTag: function (node) {
        this.write('__tags.push(function(_g, _scope, _vars){');
        this.write('with(_scope){');
        this.write('with(_vars){');
        this.write('_g.tag()');
        this.write('}');
        this.write('}');
        this.write('});');
    }
};

module.exports = function (fileName, options) {
    var c = new Compiller(options);
    return c.compile(fileName);
};





