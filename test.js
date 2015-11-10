tpl = (function (ctx) {
    return [
        {
            type: 'tag',
            name: 'ul',
            children: [
                {
                    type: 'tag',
                    name: 'li',
                    attrs: {
                        class: 'first'
                    },
                    dynAttrs: null,
                    selfClosing: false,
                    decorators: [],
                    value: '',
                    children: [
                        { 
                            type: 'text',
                            value: 'Page 1'
                        }
                    ]
                }
            ]
        }
    ]
});



driver = {
    'tag': function () {
        
    }
}
