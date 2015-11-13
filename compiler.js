/**
 * Created by tkachenko on 16.04.15.
 */
var parser = require("./dist/parser").parser;
parser.yy.$ = require("./lib/scope");

var fs = require("fs");
var util = require("util");
var extend = require("extend");

function walkSubTree(subtree) {
    var decorators = null;
    var nodes = [];
    
    for (var i = 0; i < subtree.length; i++) {
        if (subtree[i].type === 'Block' || 
            subtree[i].type === 'Mixin' ||
            subtree[i].type === 'Extend') {
        
            throw new Error(subtree[i].type + ' appeared in internal nodes!');
        }
        
        if (subtree[i].type === 'Decorator') {
            decorators = decorators || [];
            decorators.push(subtree[i]);
            continue;
        }
        
        if (decorators) {
            subtree[i].decorators = decorators;
            decorators = null;
        }
        
        if (subtree[i].block) {
            subtree[i].block = walkSubTree(subtree[i].block)
        }
        
        nodes.push(subtree[i]);
    }
    
    if (decorators) {
        throw new Error('Decorator Error: no node to bind decorator!')
    }
    
    return nodes;
}

var generator = {
    walkString: function(node){
        return {
            value: '"' + node.value.replace('\n', '\\n') + '"',
            deps: []
        };
    },
    
    walkStringArray: function (node) {
        var nodes = walkList(node.nodes);
        
        return {
            value: '[' + nodes.values.join(', ') + '].join("")',
            deps: nodes.deps
        };
    },
    
    walkIdentifier: function (node) {
        return {
            value: node.id,
            deps: [node.id]
        };
    },
    
    walkLiteral: function (node) {
        return {
            value: node.value,
            deps: []
        };
    },
    
    walkPropertyOp: function (node) {
        var object = walkNode(node.object);
        return {
            value: object.value + '.' + node.property,
            deps: object.deps
        };
    },
    
    walkIndexOp: function (node) {
        var index = walkNode(node.index);
        var expr = walkNode(node.expr);
        
        return {
            value: '(' + expr.value + ')[' + index.value + ']',
            deps: index.deps.concat(expr.deps)
        };
    },
    
    walkSliceOp: function (node) {
        var vals = walkList([node.expr, node.from, node.to]);
        
        return {
            value: '(' + vals.values[0] + ').slice(' + vals.values[1] + ', ' + vals.values[2] + ')',
            deps: vals.deps
        };
    },
    
    walkConditionOp: function (node) {
        var cond = walkNode(node.cond);
        var onTrue = walkNode(node.onTrue);
        var onFalse = walkNode(node.onFalse);
        
        return {
            value: cond.value + ' ? ' + onTrue.value + ' : ' + onFalse.value,
            deps: cond.deps.concat(onTrue.deps).concat(onFalse.deps)
        };
    },
    
    walkCallExpression: function (node) {
        var callee = walkNode(node.callee);
        var args = walkList(node.args);
        
        return {
            value: callee.value + '(' + args.values.join(', ') + ')',
            deps: callee.deps.concat(args.deps)
        };
    },
    
    walkUnaryExpression: function (node) {
        var right = walkNode(node.right);
        var space = node.operator === 'new' ? ' ' : '';
        
        return {
            value: node.operator + space + right.value,
            deps: right.deps
        };
    },
    
    walkBinaryExpression: function (node) {
        var left = walkNode(node.left);
        var right = walkNode(node.right);
        var value = left.value + ' ' + node.operator + ' ' + right.value;
        
        if (node.operator === '..') {
            value = '__range(' + left.value + ', ' + right.value + ')';
        }

        return {
            value: value,
            deps: left.deps.concat(right.deps)
        };
    },
    
    walkArrayExpression: function (node) {
        var elems = walkList(node.elements);
        
        return {
            value: '[' + elems.values.join(', ') + ']',
            deps: elems.deps
        };
    },
    
    walkObjectExpression: function (node) {
        var elems = walkList(node.properties);
        
        return {
            value: '{' + elems.values.join(', ') + '}',
            deps: elems.deps
        };
    },
    
    walkObjectProperty: function (node) {
        var expr = walkNode(node.expr);
        
        return {
            value: node.id + ': ' + expr.value,
            deps: expr.deps
        };
    },
    
    walkAssignmentExpression: function (node) {
        var left = walkNode(node.left);
        var right = walkNode(node.right);
        
        return {
            value: left.value + ' ' + node.operator + ' ' + right.value,
            deps: left.deps.concat(right.deps)
        };
    },
    
    walkStatement: function (node) {
        return walkNode(node.expr);
    },
    
    
    walkVariableStatement: function (node) {
        var declarations = walkList(node.declarations);
        
        return {
            value: 'var ' + declarations.values.join(', '),
            deps: declarations.deps
        };
    },
    
    walkVariableDeclaration: function (node) {
        var init = node.init ? walkNode(node.init) : null;
        
        return {
            value: node.id + (init ? ' = ' + init.value : ''),
            deps: init ? init.deps : []
        };
    },
    
    //
    
    walkExpressionStatement: function (node) {
        var data = walkNode(node.expr);
        if (node.escape) {
            return {
                value: '__escape(' + data.value + ')',
                deps: data.deps
            };
        } else {
            return data;
        }
    },
    
    walkWhile: function (node) {
        
    },
    
    walkCase: function (node) {
        
    },

    walkCaseWhen: function (node) {
        
    },

    walkCaseDefault: function (node) {
        
    },
    
    walkForIn: function (node, parent_id) {
        var id = __gen_id();
        var key = node.key;
        var value = node.value;
        var expr = walkNode(node.expr);
        var block = walkTags(node.block, id);
        var expr_js = expr.value;
        
        if (expr.deps.length) {
            expr_js = __wrap(expr.value);
        }
        
        var parent_js = __wrap_f('n_' + parent_id);
        var block_js = __wrap_children(block);
        
        return [id, util.format('var n_%d=driver.forin(s,%s,%s,%s,"%s","%s");\n',id,parent_js,block_js,expr_js,value,key)];
    },
    
    walkIfElse: function (node, parent_id) {
        var id = __gen_id();
        var cond = walkNode(node.cond);
        var onTrue = walkTags(node.onTrue, id);
        var onFalse = node.onFalse ? walkTags(node.onFalse, id) : null;
        var cond_js = cond.value;
        
        if (cond.deps.length) {
            cond_js = __wrap(cond.value);
        }
        
        var parent_js = __wrap_f('n_' + parent_id);
        var onTrue_js = __wrap_children(onTrue);
        
        var children = [onTrue_js];
        
        if (onFalse) {
            var onFalse_js = __wrap_children(onFalse);
            children.push(onFalse_js);
        }
        
        var children_js = '['+children.join(',')+']';
        
        return [id, util.format('var n_%d=driver.ifelse(s,%s,%s,%s);\n',id,parent_js,children_js,cond_js)];
    },
    
    walkComment: function () {
        
    },
    
    walkCommentLine: function () {
        
    },
    
    walkInclude: function () {
        
    },
    
    walkExtends: function () {
        
    },
    
    walkText: function (node, parentId) {
        var id = __gen_id();
        var value = walkNode(node.text);
        var value_js = value.value;
        if (value.deps.length) {
            value_js = __wrap(value.value);
        }
        var parent_js = __wrap_f('n_'+parentId);
        
        return [id, util.format('var n_%d=driver.text(s,%s,%s);\n',id,parent_js,value_js)];
    },
    
    walkTag: function (node, parentId) {
        var id = __gen_id();
        var tags = node.block ? walkTags(node.block, id) : null;
        var attrs_items = [];
        var attrs_objects = [];
        var attrs_deps = [];
        for (var i = 0; i < node.attrs.length; i++) {
            var attr = walkNode(node.attrs[i]);
            attrs_deps = attrs_deps.concat(attr.deps);
            
            if (node.attrs[i].type === 'TagAttribute') {
                attrs_items.push(attr.value);
            } else {
                attrs_objects.push(attr.value);
            }
        }
        if (node.attrs.length) {
            if (attrs_objects.length) {
                var attrs_js = util.format('__extend({%s},%s)', attrs_items.join(','), attrs_objects.join(', '));
            } else {
                var attrs_js = util.format('{%s}', attrs_items.join(','));
            }
        } else {
            var attrs_js = 'null';
        }
        
        if (attrs_deps.length) {
            attrs_js = __wrap(attrs_js);
        }
        
        var children_js = __wrap_children(tags);
        var parent_js = __wrap_f('n_'+parentId);
        
        return [id, util.format('var n_%d=driver.tag(s,%s,%s,"%s",%s);\n',id,parent_js,children_js,node.tag,attrs_js)];
    },
    
    walkTagAttribute : function (node) {
        var value = walkNode(node.value);
        var js = value.value;
        
        if (node.attr === 'style') js = '__pp_style(' + js + ')';
        if (node.attr === 'class') js = '__pp_class(' + js + ')';
       
        return {
            value: '"' + node.attr + '": ' + js,
            deps: value.deps
        };
    }
};

function walkFile(filename) {
    var source = fs.readFileSync(filename, 'utf8');
    return walkTags(parser.parse(source + '\n'), 0);
}

function walkNode(node) {
    if (!generator['walk' + node.type]) {
        console.dir(node);
        throw new Error('Unknown ' + node.type);
    }
    return generator['walk' + node.type].apply(generator, arguments);
}

function walkTags(nodes, parent) {
    var value = [];
    var deps = [];
    var data;
    
    for (var i = 0; i < nodes.length; i++) {
        data = walkNode(nodes[i], parent);
        value.push(data);
        deps.concat(data.deps);
    }
    
    return {
        values: value,
        deps: deps
    };
}

function walkList(nodes) {
    var value = [];
    var deps = [];
    var data;
    
    for (var i = 0; i < nodes.length; i++) {
        data = walkNode(nodes[i]);
        value.push(data.value);
        deps = deps.concat(data.deps);
    }
    
    return {
        values: value,
        deps: deps
    };
}

function __wrap(value) {
    return 'function(scope){with(scope){return '+value+';}}';
}

function __wrap_f(value) {
    return 'function(){return '+value+';}';
}

function __wrap_children(tags) {
    var children_ids = [];
    var js = [];
    
    if (tags) {
        for (var i = 0; i < tags.values.length; i++) {
            children_ids.push('n_' + tags.values[i][0]);
            js.push(tags.values[i][1]);
        }
    }

    return 'function(__s){s=__s||s;\n'+js.join('')+'return ['+children_ids.join(',')+'];\n}';
}

function __gen_id() {
    arguments.callee.idx = arguments.callee.idx || 0;
    return arguments.callee.idx += 1;
}

function __extend() {
    var args = Array.prototype.concat([{}], arguments);
    return extend.apply(undefined, args);
}

function __pp_class (_class) {
    if (_class instanceof Array) {
        return _class.join(' ');
    } 
    return _class;
}

function __pp_style (_style) {
    var res = [];
    if (typeof _style === 'object') {
        for (var i in _style) {
            if (_style.hasOwnProperty(i)) {
                res.push(i + ':' + _style[i]);
            }
        }
        return res.join(';');
    } 
    return _style;
}

function __escape (a) {
    return a.toLowerCase();
}

function __range (from, to) {
    var res = [];
    for (var i = from; i <= to; i++) {
        res.push(i);
    }

    return res;
}

function generate (filename) {
    var val = walkFile(filename);
    var items = [];
    var ids = [];
    for (var i = 0; i < val.values.length; i++) {
        items.push(val.values[i][1]);
        ids.push(val.values[i][0]);
    }
    
    var src = util.format('(function(s,driver){var __mixins=[];var __blocks=[];%s;return {nodes:[n_%s],mixins:__mixins,blocks:__blocks};})', items.join(''), ids.join(',n_'));
//    console.log(src);
    
    return eval(src);
}

var __unwrap = function (scope, value) {
    return typeof(value) === 'function' ? value.call(this, scope) : value;
};

var driver = {
    __fork: function (parent) {
        function c() {}
        c.prototype = parent;
        var child = new c();
        child.$$parent = parent;

        return child;   
    },
    tag: function(scope, parent, children, name, attrs, deps) {
        var tmp = [];
        if (attrs) {
            attrs = __unwrap(scope, attrs);
            for (var i in attrs) {
                if (attrs.hasOwnProperty(i)) {
                    var attr = __unwrap(scope, attrs[i]);
                    tmp.push(i + '="' + attr +'"');
                }
            }
        }

        var attrs_html = tmp.length ? ' ' + tmp.join(' ') : '';
        return '<'+name+attrs_html+'>\n' + children().join('\n') + '\n</'+name+'>'
    },

    text: function(scope, parent, text, deps) {
        return __unwrap(scope, text);
    },
    
    ifelse: function (scope, parent, children, cond) {
        var cond_val = __unwrap(scope, cond);
        
        return cond_val ? children[0]().join('\n') : (children[1]?children[1]().join('\n'):undefined);
    },
    
    forin: function (scope, parent, children, expr, value, key) {
        var expr_val = __unwrap(scope, expr);
        var values = [];
        var subscope;
        
        if (expr_val instanceof Array) {
            for (var i = 0; i < expr_val.length; i++) {
                subscope = this.__fork(scope);
                if (key) subscope[key] = i;
                subscope[value] = expr_val[i];
                values = values.concat(children(subscope));
            }
        } else {
            for (var i in expr_val) {
                if (expr_val.hasOwnProperty(i)) {
                    subscope = this.__fork(scope);
                    if (key) subscope[key] = i;
                    subscope[value] = expr_val[i];
                    values = values.concat(children(subscope));
                }
            }
        }
        
        return values.join('\n');
    }
};

var ctx = {
    color: 'silver',
    c: 3,
    test: {
        key: 'One',
        value: 'Two'
    },
    a: function () {
        return 'Andrey';
    }
};

var test2 = generate('./test2.jade');

console.log(test2(ctx, driver).nodes[0]);


