/**
 * Created by tkachenko on 16.04.15.
 */
var parser = require("./dist/parser").parser;
parser.yy.$ = require("./lib/scope");

var fs = require("fs");

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
        var array = [],
            deps = [],
            data;
    
        for (var i = 0; i < node.nodes.length; i++) {
            data = walkNode(node.nodes[i]);
            array.push(data.value);
            deps = deps.concat(data.deps);
        }

        return {
            value: '[' + array.join(', ') + '].join("")',
            deps: deps
        };
    },
    
    walkIdentifier: function (node) {
        return {
            value: node.id,
            deps: [node.id]
        };
    },
    
    walkCallExpression: function (node) {

    },
    
    walkBinaryExpression: function (node) {
        var left = walkNode(node.left);
        var right = walkNode(node.right);

        return {
            value: left.value + ' ' + node.operator + ' ' + right.value,
            deps: left.deps.concat(right.deps)
        };
    },
    
    walkExpressionStatement: function (node) {
        var data = walkNode(node.expression);
        if (node.escape) {
            return {
                value: '__escape(' + data.value + ')',
                deps: ['__escape'].concat(data.deps)
            };
        } else {
            return data;
        }
    }
};


function walkBlockSubtree(tree) {
    
}

function walkMixinSubtree(tree) {
    
}

function walkFile(filename) {
    var source = fs.readFileSync(filename, 'utf8');
    return walk(parser.parse(source + '\n'));
}

//function walkTree(tree) {
//    var extend = null;
//    var blocks = [];
//    var mixins = [];
//    var nodes = [];
//    var includes = [];
//    
//    for (var i = 0; i < tree.length; i++) {
//        if (tree[i].type === 'Block') {
//            tree[i].block = walkSubTree(tree[i].block);
//            blocks.push(tree[i]);
//        } else if (tree[i].type === 'Mixin') {
//            tree[i].block = walkSubTree(tree[i].block);
//            mixins.push(tree[i]);
//        } else if (tree[i].type === 'Extend') {
//            if (extend !== null) throw new Error('Extend may be only one!');
//            extend = tree[i];
//        } else if (tree[i].type === 'Include') {
//            includes.push(tree[i].href);
//            nodes.push(tree[i]);
//        } else {
//            nodes.push(tree[i]);
//        }
//    }
//    
//    return {
//        nodes: walkSubTree(nodes), 
//        mixins: mixins, 
//        blocks: blocks, 
//        extend: extend, 
//        includes: includes
//    };
//}

function walkNode(node) {
    console.log('walk' + node.type)
    return generator['walk' + node.type](node);
}

function walk(nodes) {
    var value = [];
    var deps = [];
    var data;
    
    for (var i = 0; i < nodes.length; i++) {
        data = walkNode(nodes[i]);
        value.push(data.value);
        deps.concat(data.deps);
    }
    
    return {
        value: value.join(';'),
        deps: deps
    };
}

test = 'TTT';
a = 'AAA';
__escape = function (a) {
    return a.toLowerCase();
} 

d = JSON.stringify(walkFile('./test2.jade'), null, 4)
//d = JSON.stringify(parser.parse(fs.readFileSync('./test2.jade', 'utf8') + '\n'), null, 4)
console.log(d)


