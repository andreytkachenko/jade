var Compiller = function (generator) {
    this.generator = generator;
    this._mixins = {};
};

Compiller.prototype = {
    _mixins: {},
    _blocks: {},
    _files: {},

    compile: function (nodes) {

    },

    compileFile: function (fileName) {

    },

    compileMixin: function (node) {
        this._mixins[node.id] = (function (_g, scope, vars) {
            return this.compile(node.block);
        }).bind(this);
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