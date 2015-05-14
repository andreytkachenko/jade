/**
 * Created by tkachenko on 25.04.15.
 */

var extend = require('extend');

var Node = function () {

};

Node.prototype = {
    hasBlock: false,
    initialize: function (hasBlock) {
        this.hasBlock = hasBlock;
    }
};

Node.extend = function (obj) {
    var child = function child () {
        extend(this, obj);
        if (this.initialize) {
            this.initialize.apply(this, arguments);
        }
    };

    child.prototype = this;
    return child;
};

module.exports.Node = Node;

module.exports.UnaryOpNode = Node.extend({
    type: 'UnaryExpression',
    operator: null,
    right: null,
    initialize: function (op, expr) {
        this.operator = op;
        this.right = expr;
    }
});

module.exports.BinaryOpNode = Node.extend({
    type: 'BinaryExpression',
    operator: null,
    left: null,
    right: null,
    initialize: function (op, left, right) {
        this.operator = op;
        this.left = left;
        this.right = right;
    }
});

module.exports.TernaryOpNode = Node.extend({
    type: 'ConditionOp',
    cond: null,
    onTrue: null,
    onFalse: null,
    initialize: function (cond, onTrue, onFalse) {
        this.cond = cond;
        this.onTrue = onTrue;
        this.onFalse = onFalse;
    }
});

module.exports.IdentifierNode = Node.extend({
    type: 'Identifier',
    id: null,
    initialize: function (name) {
        this.id = name;
    }
});

module.exports.PropertyOpNode = Node.extend({
    type: 'PropertyOp',
    property: null,
    object: null,
    initialize: function (obj, name) {
        this.property = name;
        this.object = obj;
    }
});

module.exports.ScalarNode = Node.extend({
    type: 'Literal',
    value: null,
    kind: null,
    initialize: function (value, kind) {
        this.value = value;
        this.kind = kind;
    }
});

module.exports.AssignOpNode = Node.extend({
    type: 'AssignmentExpression',
    operator: null,
    left: null,
    right: null,
    initialize: function (op, left, right) {
        this.operator = op;
        this.left = left;
        this.right = right;
    }
});

module.exports.FunctionCallOpNode = Node.extend({
    type: 'CallExpression',
    callee: null,
    arguments: null,
    initialize: function (expr, args) {
        this.callee = expr;
        this.arguments = args;
    }
});

module.exports.IndexOpNode = Node.extend({
    type: 'IndexOp',
    index: null,
    expr: null,
    initialize: function (left, index) {
        this.expr = left;
        this.index = index;
    }
});

module.exports.SliceOpNode = Node.extend({
    type: 'SliceOp',
    expr: null,
    from: null,
    to: null,
    initialize: function (expr, indexFrom, indexTo) {
        this.from = indexFrom;
        this.expr = expr;
        this.to = indexTo;
    }
});

module.exports.NewOpNode = Node.extend({
    type: 'NewExpression',
    expr: null,
    initialize: function (expr) {
        this.expr = expr;
    }
});

module.exports.DeleteOpNode = Node.extend({
    expr: null,
    initialize: function (expr) {
        this.expr = expr;
    }
});

module.exports.VarDeclarationNode = Node.extend({
    type: 'VariableDeclaration',
    declarations: null,
    kind: null,
    initialize: function (declarations, kind) {
        this.declarations = declarations;
        this.kind = kind;
    }
});
module.exports.VarDeclaratorNode = Node.extend({
    type: 'VariableDeclarator',
    id: null,
    init: null,
    initialize: function (name, expr) {
        this.id = name;
        this.init = expr;
    }
});

module.exports.ArrayNode = Node.extend({
    type: 'ArrayExpression',
    elements: null,
    initialize: function (items) {
        this.elements = items;
    }
});

module.exports.ObjectNode = Node.extend({
    type: 'ObjectExpression',
    properties: null,
    initialize: function (map) {
        this.properties = map;
    }
});

var StringNode =
module.exports.StringNode = Node.extend({
    type: 'String',
    value: null,
    initialize: function (value) {
        this.value = value;
    }
});

module.exports.StringArrayNode = Node.extend({
    type: 'StringArray',
    nodes: null,
    initialize: function (value) {
        this.nodes = [];

        if (typeof value === 'string') {
            this.addString(value);
        } else {
            this.addNode(value);
        }
    },
    addNode: function (node) {
        this.nodes.push(node);

        return this;
    },
    addString: function (string) {
        this.nodes.push(new StringNode(string));

        return this;
    },
    addStringArray: function (array) {
        for (var i =0; i < array.nodes.length; i++) {
            this.nodes.push(array.nodes[i]);
        }

        return this;
    }
});

module.exports.ExprNode = Node.extend({
    type: 'ExpressionStatement',
    expression: null,
    initialize: function (expr) {
        this.expression = expr;
    }
});

module.exports.StatementNode = Node.extend({
    type: 'Statement',
    expr: null,
    initialize: function (expr) {
        this.expr = expr;
    }
});

module.exports.IfElseNode = Node.extend({
    type: 'IfElse',
    cond: null,
    onTrue: null,
    onFalse: null,
    initialize: function (cond, onIf, onElse) {
        this.cond = cond;
        this.onTrue = onIf;
        this.onFalse = onElse;
    }
});

module.exports.WhileNode = Node.extend({
    type: 'While',
    expr: null,
    block: null,
    initialize: function (expr, block) {
        this.expr = expr;
        this.block = block;
    }
});

module.exports.ForInNode = Node.extend({
    type: 'ForIn',
    value: null,
    key: null,
    expr: null,
    block: null,
    initialize: function (value, key, expr, block) {
        this.key = key;
        this.value = value;
        this.expr = expr;
        this.block = block;
    }
});

module.exports.CaseNode = Node.extend({
    type: 'Case',
    expr: null,
    cases: null,
    initialize: function (expr, cases) {
        this.expr = expr;
        this.cases = cases;
    }
});

module.exports.CaseWhenNode = Node.extend({
    type: 'CaseWhen',
    when: null,
    block: null,
    initialize: function (cond, block) {
        this.when = cond;
        this.block = block;
    }
});

module.exports.CaseDefaultNode = Node.extend({
    type: 'CaseDefault',
    block: null,
    initialize: function (block) {
        this.block = block;
    }
});

module.exports.TagNode = Node.extend({
    type: 'Tag',
    tag: null,
    attrs: null,
    block: null,
    selfClosing: false,
    initialize: function (tagName, attrs, block) {
        this.tag = tagName;
        this.attrs = attrs || [];
        this.block = block;
    }
});

module.exports.TagAttributeNode = Node.extend({
    type: 'TagAttribute',
    attr: null,
    value: null,
    escape: false,
    initialize: function (attr, value, escape) {
        this.attr = attr;
        this.value = value;
        this.escape = escape;
    }
});

module.exports.CommentNode = Node.extend({
    output: false,
    initialize: function (output) {
        this.output = output;
    }
});

module.exports.TextNode = Node.extend({
    type: 'Text',
    escaped: false,
    text: null,
    initialize: function (text, escape) {
        this.text = text;
        this.escape = escape;
    }
});

module.exports.IncludeNode = Node.extend({
    type: 'Include',
    href: null,
    filter: null,
    initialize: function (href, filter) {
        this.href = href;
        this.filter = filter;
    }
});

module.exports.ExtendsNode = Node.extend({
    type: 'Extends',
    href: null,
    initialize: function (href) {
        this.href = href;
    }
});

module.exports.FilterNode = Node.extend({
    type: 'Filter',
    id: null,
    block: null,
    initialize: function (id, block) {
        this.id = id;
        this.block = block;
    }
});


module.exports.BlockNode = Node.extend({
    type: 'Block',
    id: null,
    embed: null,
    block: null,
    initialize: function (name, embed, block) {
        this.id = name;
        this.embed = embed;
        this.block = block;
    }
});

module.exports.MixinArgumentNode = Node.extend({
    type: 'MixinArgument',
    id: null,
    ellipsis: null,
    initialize: function (id, ellipsis) {
        this.id = id;
        this.ellipsis = ellipsis;
    }
});

module.exports.MixinNode = Node.extend({
    type: 'Mixin',
    id: null,
    args: null,
    block: null,
    initialize: function (id, args, block) {
        this.id = id;
        this.args = args;
        var counter = 0;

        for (var i = 0; i < args.length; i++) {
            if (args[i].ellipsis) {
                counter ++;
            }
        }

        if (counter > 1) {
            throw new Error('Mixin Argument List Error: Unexpected second ellipsis!');
        }

        this.block = block;
    }
});

module.exports.MixinYieldNode = Node.extend({
    type: 'Yield'
});

module.exports.MixinBlockNode = Node.extend({
    type: 'MixinBlock'
});

module.exports.MixinCallNode = Node.extend({
    type: 'MixinCall',
    id: null,
    args: null,
    attrs: null,
    block: null,
    initialize: function (name, args, attrs, block) {
        this.id = name;
        this.args = args;
        this.attrs = attrs;
        this.block = block;
    }
});