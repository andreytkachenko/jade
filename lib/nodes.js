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
        this.initialize.apply(this, arguments);
    };

    child.prototype = this;
    return child;
};

module.exports.Node = Node;

module.exports.UnaryOpNode = Node.extend({
    type: 'UnaryOp',
    operator: null,
    right: null,
    initialize: function (op, expr) {
        this.operator = op;
        this.right = expr;
    }
});

module.exports.BinaryOpNode = Node.extend({
    type: 'BinaryOp',
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
    type: 'Scalar',
    value: null,
    initialize: function (value) {
        this.value = value;
    }
});

module.exports.AssignOpNode = Node.extend({
    type: 'AssignOp',
    left: null,
    right: null,
    initialize: function (left, right) {
        this.left = left;
        this.right = right;
    }
});

module.exports.FunctionCallOpNode = Node.extend({
    type: 'FunctionCallOp',
    expr: null,
    args: null,
    initialize: function (expr, args) {
        this.expr = expr;
        this.args = args;
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

module.exports.VarNode = Node.extend({
    name: null,
    initialize: function (name) {
        this.name = name;
    }
});

module.exports.ArrayNode = Node.extend({
    type: 'Array',
    items: null,
    initialize: function (items) {
        this.items = items;
    }
});

module.exports.ObjectNode = Node.extend({
    type: 'Object',
    map: null,
    initialize: function (map) {
        this.map = map;
    }
});

module.exports.StringNode = Node.extend({
    type: 'String',
    value: null,
    initialize: function (value) {
        this.value = value;
    }
});

module.exports.StringArrayNode = Node.extend({
    type: 'StringArray',
    list: [],
    initialize: function (item) {
        this.list.push(item);
    },
    addNode: function (item) {
        this.list.push(item);

        return this;
    },
    addString: function (string) {
        var last = this.list[this.list.length - 1];

        if (last && last.type === 'String') {
            last.value += string;
        } else {
            this.list.push(new module.exports.StringArrayNode(string));
        }

        return this;
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
    cases: [],
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
    attrs: [],
    andAttrs: null,
    selfClosing: false,
    initialize: function (head, body, andAttrs) {
        this.tag = head.tag;
        if (head.attrs) {
            this.attrs = this.attrs.concat(head.attrs);
        }
        if (body) {
            this.attrs = body.concat(head.attrs);
        }
        if (andAttrs) {
            this.andAttrs = andAttrs;
        }
    },
    toString: function () {
        return this.name;
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
    href: null,
    as: null,
    initialize: function (href, as) {
        this.href = href;
        this.as = as;
    }
});

module.exports.ExtendNode = Node.extend({
    href: null,
    initialize: function (href) {
        this.href = href;
    }
});

module.exports.BlockNode = Node.extend({
    name: null,
    initialize: function (name) {
        this.name = name;
    }
});

module.exports.MixinNode = Node.extend({
    name: null,
    args: null,
    initialize: function (name, args) {
        this.name = name;
        this.args = args;
    }
});

module.exports.MixinYieldNode = Node.extend({});
module.exports.MixinBlockNode = Node.extend();
module.exports.MixinCallNode = Node.extend({
    name: null,
    args: null,
    initialize: function (name, args) {
        this.name = name;
        this.args = args;
    }
});