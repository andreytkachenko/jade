var template = (function (tpl) {
    var __files = {},
        __nodes = [],
        __root = [];

    var __get_nodes = function (list, ctx) {
        var _resp = [];

        if (!list) {
            return _resp;
        }

        for (var i = 0; i < list.length; i++) {
            _resp[_resp.length] = __get_node(i, ctx);
        }

        return _resp;
    };

    var __get_node = function (index, ctx) {
        return ctx.node(__nodes[index], __get_nodes);
    };

    __nodes.push({
        type: 'tag',
        name: 'div',
        attrs: {id: 'test'},
        children: [1,2]
    });
    __root.push(0);


    __nodes.push({
        type: 'tag',
        name: 'div',
        attrs: {id: 'inner1'},
        parent: 0
    });

    __nodes.push({
        type: 'tag',
        name: 'div',
        attrs: {id: 'inner2'},
        parent: 0
    });


    __files['test.jade'] = function (_g) {
        var nodes = [];
        for (var i = 0; i < __root.length; i++) {
            nodes[nodes.length] = __get_node(__root[i], _g);
        }

        return _g.list(nodes);
    };

    return __files[tpl];
});

console.log(template('test.jade')({
    list: function (list) {
        return list.join('\n');
    },
    node: function (node, getter) {
        if (node.type === 'text') {
            return node.value;
        } else if (node.type === 'tag') {
            return '<' + node.name + '>\n' + getter(node.children, this) + '\n</' + node.name + '>';
        }
    }
}));