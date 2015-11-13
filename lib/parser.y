%left       ',' SLICE
%right      '=' '+=' '-=' '*=' '/=' '%=' '&=' '|=' '^=' '>>=' '<<=' '>>>=' '<<<='
%left       '?' ':'
%left       '&' '|' '^'
%left       '||' '&&'
%left       '==' '===' '!=' '!==' '<' '>' '<=' '>='
%left       '..'
%left       '+' '-'
%left       '*' '/' '%'
%left       '.' INSTANCEOF
%left       POST_PLUS POST_MINUS
%right      '--' '++' '!' '~' PLUS MINUS TYPEOF DELETE NEW

%start program

%%

program
    : program-lines EOF
        { return $1; }
    | NEWLINE EOF
        { return []; }
    ;

program-lines
    : program-line
        { $$ = [$1]; }
    | program-lines program-line
        { $$ = $1.concat([$2]); }
    ;

program-line
    : line
    | extends
    | mixin
    ;

lines
    : line
        { $$ = [$1]; }
    | lines line
        { $$ = $1.concat([$2]); }
    ;

line
    : tag
    | if
    | while
    | for-in
    | case
    | include
    | extend-block
    | text
    | expr-statement
    | filter
    | comment
    | mixin-call
    | YIELD NEWLINE
        { $$ = new yy.$.MixinYieldNode(); }
    | BLOCK NEWLINE
        { $$ = new yy.$.MixinBlockNode(); }
    | SUPERBLOCK NEWLINE
        { $$ = new yy.$.SuperBlockNode(); }
    ;

block
    : INDENT lines DEDENT
        { $$ = $2; }
    ;

text-expr
    : EXPR_TAG expr
        { $$ = new yy.$.ExprNode($2, $1); }
    ;

text-interp
    : INTERP_TAG_BEGIN tag-interp INTERP_TAG_END
        { $$ = $2; }

    | INTERP_EXPR_BEGIN expr INTERP_EXPR_END
        { $$ = new yy.$.ExprNode($2, $1); }
    ;

text-pure
    : STRING
    ;

text-string
    : text-pure
        { $$ = new yy.$.StringArrayNode($1); }
    | text-string text-pure
        { $1.addString($2); $$ = $1 }
    | text-interp
        { $$ = new yy.$.StringArrayNode($1); }
    | text-string text-interp
        { $1.addNode($2); $$ = $1 }
    ;

text-line
    : text-string NEWLINE
        { $1.addString('\n'); $$ = $1 }
    ;

text
    : text-line
        { $$ = new yy.$.TextNode($1); }
    | TEXT_TAG text-line
        { $$ = new yy.$.TextNode($2); }
    | text-expr NEWLINE
        { $$ = new yy.$.TextNode($1); }
    ;

text-lines
    : text-line
        { $$ = [$1]; }
    | text-lines text-line
        { $1.push($2); $$ = $1; }
    ;

text-block
    : INDENT text-lines DEDENT
        { $$ = $2; }
    ;

include
    : INCLUDE expr NEWLINE
        { $$ = new yy.$.IncludeNode($2); }
    | INCLUDE FILTER_TAG ID expr NEWLINE
        { $$ = new yy.$.IncludeNode($4, $3); }
    ;

extends
    : EXTENDS expr NEWLINE
        { $$ = new yy.$.ExtendsNode($2); }
    ;

filter
    : FILTER_TAG ID NEWLINE text-block
        { $$ = new yy.$.FilterNode($2, $4); }
    ;

comment
    : COMMENT-TAG comment-line
        { $$ = new yy.$.CommentNode([$2], $1); }
    | COMMENT-TAG comment-line comment-block
        { $3.unshift($2); $$ = new yy.$.CommentNode($3, $1); }
    ;

comment-line
    : COMMENT-LINE NEWLINE
        { $$ = new yy.$.CommentLineNode($1); }
    ;

comment-lines
    : comment-line
        { $$ = [$1] }
    | comment-lines comment-line
        { $1.push($2); $$ = $1 }
    ;

comment-block
    : INDENT comment-lines DEDENT
        { $$ = $2 }
    ;

if
    : IF expr NEWLINE block
        { $$ = new yy.$.IfElseNode($2, $4); }
    | IF expr NEWLINE block ELSE NEWLINE block
        { $$ = new yy.$.IfElseNode($2, $4, $7); }
    | IF expr NEWLINE block ELSE if
        { $$ = new yy.$.IfElseNode($2, $4, $6); }
    | UNLESS expr NEWLINE block
        { $$ = new yy.$.IfElseNode(new yy.$.UnaryOpNode('!', $2), $4); }
    | UNLESS expr NEWLINE block ELSE NEWLINE block
        { $$ = new yy.$.IfElseNode(new yy.$.UnaryOpNode('!', $2), $4, $7); }
    | UNLESS expr NEWLINE block ELSE if
        { $$ = new yy.$.IfElseNode(new yy.$.UnaryOpNode('!', $2), $4, $6); }
    ;

for-in
    : EACH ID IN expr NEWLINE block
        { $$ = new yy.$.ForInNode($2, null, $4, $6); }
    | EACH ID ',' ID IN expr NEWLINE block
        { $$ = new yy.$.ForInNode($2, $4, $6, $8); }
    ;

when-block
    : WHEN expr NEWLINE
        { $$ = new yy.$.CaseWhenNode($2, null); }
    | WHEN expr NEWLINE block
        { $$ = new yy.$.CaseWhenNode($2, $4); }
    | DEFAULT NEWLINE
        { $$ = new yy.$.CaseDefaultNode(); }
    | DEFAULT NEWLINE block
        { $$ = new yy.$.CaseDefaultNode($3); }
    ;

case-block
    : when-block
        { $$ = [$1]; }
    | case-block when-block
        { $$ = $1.concat($2); }
    ;

case
    : CASE expr NEWLINE INDENT case-block DEDENT
        { $$ = new yy.$.CaseNode($2, $5); }
    ;

while
    : WHILE expr NEWLINE block
        { $$ = new yy.$.WhileNode($2, $4); }
    ;

extend-block
    : BLOCK ID NEWLINE
        { $$ = new yy.$.BlockNode($2, null, null); }
    | BLOCK ID NEWLINE block
        { $$ = new yy.$.BlockNode($2, null, $4); }
    | BLOCK APPEND ID NEWLINE block
        { $$ = new yy.$.BlockNode($3, 'APPEND', $5); }
    | BLOCK PREPEND ID NEWLINE block
        { $$ = new yy.$.BlockNode($3, 'PREPEND', $5); }
    | APPEND ID NEWLINE block
        { $$ = new yy.$.BlockNode($2, 'APPEND', $4); }
    | PREPEND ID NEWLINE block
        { $$ = new yy.$.BlockNode($2, 'PREPEND', $4); }
    ;

mixin-args-list
    : ID
        { $$ = [ new yy.$.MixinArgumentNode($1) ]; }
    | mixin-args-list ',' ID
        { $$ = $1.concat([new yy.$.MixinArgumentNode($3)]); }
    | mixin-args-list ',' ELLIPSIS ID
        { $$ = $1.concat([new yy.$.MixinArgumentNode($4, true)]); }
    ;

mixin-args
    : '(' ')'
        { $$ = []; }
    | '(' mixin-args-list ')'
        { $$ = $2; }
    ;

mixin
    : MIXIN ID NEWLINE block
        { $$ = new yy.$.MixinNode($2, [], $4); }
    | MIXIN ID mixin-args NEWLINE block
        { $$ = new yy.$.MixinNode($2, $3, $5); }
    ;

mixin-call-args
    : expr
        { $$ = [$1]; }
    | mixin-call-args ',' expr
        { $$ = $1.concat([$3]); }
    ;

mixin-simple-call
    : '(' ')'
        { $$ = []; }
    | '(' mixin-call-args ')'
        { $$ = $2; }
    ;

mixin-call
    : CALL ID mixin-simple-call tag-unnamed
        { $$ = new yy.$.MixinCallNode($2, $3, $4[0], $4[1]); }
    ;

tag-head-attr
    : TAG_CLASS
        { $$ = new yy.$.TagAttributeNode('class', new yy.$.StringNode($1)); }
    | TAG_ID
        { $$ = new yy.$.TagAttributeNode('id', new yy.$.StringNode($1)); }
    ;

tag-head
    : tag-head-attr
        { $$ = [$1] }
    | tag-head tag-head-attr
        { $$ = $1.concat([$2]); }
    ;

tag-attr
    : ATTR text-expr
        { $$ = new yy.$.TagAttributeNode($1, $2); }
    ;

tag-attrs
    : tag-attr
        { $$ = [$1] }
    | tag-attrs tag-attr
        { $$ = $1.concat([$2]); }
    | tag-attrs ',' tag-attr
        { $$ = $1.concat([$3]); }
    ;

tag-and-attr
    : ATTRIBUTES '(' expr ')'
        { $$ = $3 }
    ;

tag-and-attrs
    : tag-and-attr
        { $$ = [$1] }
    | tag-and-attrs tag-and-attr
        { $1.push($2); $$ = $1 }
    ;

tag-body-attr
    : '(' ')'
        { $$ = []; }
    | '(' tag-attrs ')'
        { $$ = $2; }
    |  ATTRIBUTES '(' expr ')'
        { $$ = [$3] }
    ;

tag-body-attrs
    : tag-body-attr
        { $$ = $1 }
    | tag-body-attrs tag-body-attr
        { $$ = $1.concat($2); }
    ;

tag-body
    : tag-head
        { $$ = $1 }
    | tag-body-attrs
        { $$ = $1; }
    | tag-head tag-body-attrs
        { $$ = $1.concat($2); }
    ;

tag-tail-interp
    : text-string
        { $$ = [$1]; }
    | EXPR_TAG expr
        { $$ = [$2]; }
    | TEXT_TAG text-string
        { $$ = [$2]; }
    | ':' tag-interp
        { $$ = [$2]; }
    | '/'
        { $$ = null; }
    ;

tag-tail
    : NEWLINE block
        { $$ = $2; }
    | text
        { $$ = [$1]; }
    | text block
        { $$ = [$1].concat($2); }
    | ':' tag
        { $$ = [$2]; }
    | '/' NEWLINE
        { $$ = null; }
    | '.' NEWLINE text-block
        { $$ = $3; }
    ;

tag-unnamed
    : tag-body NEWLINE
        { $$ = [$1, null]; }
    | tag-tail
        { $$ = [null, $1] }
    | tag-body tag-tail
        { $$ = [$1, $2] }
    ;

tag-undecorated
    : TAG NEWLINE
        { $$ = new yy.$.TagNode($1, null, null); }
    | TAG tag-unnamed
        { $$ = new yy.$.TagNode($1, $2[0], $2[1]); }
    | tag-body NEWLINE
        { $$ = new yy.$.TagNode(null, $1, null); }
    | tag-body tag-tail
        { $$ = new yy.$.TagNode(null, $1, $2); }
    ;

tag-unnamed-interp
    : tag-body
        { $$ = [$1, null]; }
    | tag-tail-interp
        { $$ = [null, $1]; }
    | tag-body tag-tail-interp
        { $$ = [$1, $2]; }
    ;

tag-interp
    : TAG
        { $$ = new yy.$.TagNode($1, null, null); }
    | TAG tag-unnamed-interp
        { $$ = new yy.$.TagNode($1, $2[0], $2[1]); }
    | tag-body NEWLINE
        { $$ = new yy.$.TagNode(null, $1, null); }
    | tag-body tag-tail-interp
        { $$ = new yy.$.TagNode(null, $1, $2); }
    ;

decorator-args
    : expr
        { $$ = [new yy.$.DecoratorArgumentNode($1)]; }
    | decorator-args ',' expr
        { $1.push(new yy.$.DecoratorArgumentNode($3)); $$ = $1; }
    ;

decorator
    : DECORATOR_NAME NEWLINE
        { $$ = new yy.$.DecoratorNode($1); }
    | DECORATOR_NAME '(' ')' NEWLINE
        { $$ = new yy.$.DecoratorNode($1); }
    | DECORATOR_NAME '(' decorator-args ')' NEWLINE
        { $$ = new yy.$.DecoratorNode($1, $3); }
    ;

decorators
    : decorator
        { $$ = [$1] }
    | decorators decorator
        { $1.push($2); $$ = $1 }
    ;

tag
    : tag-undecorated
        { $$ = $1 }
    | decorators tag-undecorated
        { $2.setDecorators($1); $$ = $2 }
    ;

unary
    : '+' expr %prec PLUS
        { $$ = new yy.$.UnaryOpNode('+', $2); }
    | '-' expr %prec MINUS
        { $$ = new yy.$.UnaryOpNode('-', $2); }
    | '!' expr
        { $$ = new yy.$.UnaryOpNode('!', $2); }
    | '~' expr
        { $$ = new yy.$.UnaryOpNode('~', $2); }
    | TYPEOF expr
        { $$ = new yy.$.UnaryOpNode('typeof', $2); }
    | NEW expr
        { $$ = new yy.$.UnaryOpNode('new', $2); }
    | expr '--' %prec POST_MINUS
        { $$ = new yy.$.UnaryOpNode('--', undefined, $1); }
    | expr '++' %prec POST_PLUS
        { $$ = new yy.$.UnaryOpNode('++', undefined, $1); }
    | '--' expr
        { $$ = new yy.$.UnaryOpNode('--', $2); }
    | '++' expr
        { $$ = new yy.$.UnaryOpNode('++', $2); }
    ;

binary
    : expr '+' expr
        { $$ = new yy.$.BinaryOpNode('+', $1, $3); }
    | expr '-' expr
        { $$ = new yy.$.BinaryOpNode('-', $1, $3); }
    | expr '*' expr
        { $$ = new yy.$.BinaryOpNode('*', $1, $3); }
    | expr '/' expr
        { $$ = new yy.$.BinaryOpNode('/', $1, $3); }
    | expr '%' expr
        { $$ = new yy.$.BinaryOpNode('%', $1, $3); }
    | expr '..' expr
        { $$ = new yy.$.BinaryOpNode('..', $1, $3); }

    | expr '|' expr
        { $$ = new yy.$.BinaryOpNode('|', $1, $3); }
    | expr '&' expr
        { $$ = new yy.$.BinaryOpNode('&', $1, $3); }
    | expr '^' expr
        { $$ = new yy.$.BinaryOpNode('^', $1, $3); }

    | expr '>' expr
        { $$ = new yy.$.BinaryOpNode('>', $1, $3); }
    | expr '<' expr
        { $$ = new yy.$.BinaryOpNode('<', $1, $3); }

    | expr '>=' expr
        { $$ = new yy.$.BinaryOpNode('>=', $1, $3); }
    | expr '<=' expr
        { $$ = new yy.$.BinaryOpNode('<=', $1, $3); }

    | expr '===' expr
        { $$ = new yy.$.BinaryOpNode('===', $1, $3); }
    | expr '!==' expr
        { $$ = new yy.$.BinaryOpNode('!==', $1, $3); }
    | expr '==' expr
        { $$ = new yy.$.BinaryOpNode('==', $1, $3); }
    | expr '!=' expr
        { $$ = new yy.$.BinaryOpNode('!=', $1, $3); }
    | expr INSTANCEOF expr
        { $$ = new yy.$.BinaryOpNode('instanceof', $1, $3); }
    ;

ternary
    : expr '?' expr ':' expr
        { $$ = new yy.$.TernaryOpNode($1, $3, $5); }
    ;

assign
    : expr '=' expr
        { $$ = new yy.$.AssignOpNode('=', $1, $3); }
    | expr '+=' expr
        { $$ = new yy.$.AssignOpNode('+=', $1, $3); }
    | expr '-=' expr
        { $$ = new yy.$.AssignOpNode('-=', $1, $3); }
    | expr '*=' expr
        { $$ = new yy.$.AssignOpNode('*=', $1, $3); }
    | expr '/=' expr
        { $$ = new yy.$.AssignOpNode('/=', $1, $3); }
    | expr '%=' expr
        { $$ = new yy.$.AssignOpNode('%=', $1, $3); }
    | expr '&=' expr
        { $$ = new yy.$.AssignOpNode('&=', $1, $3); }
    | expr '|=' expr
        { $$ = new yy.$.AssignOpNode('|=', $1, $3); }
    | expr '^=' expr
        { $$ = new yy.$.AssignOpNode('^=', $1, $3); }
    | expr '>>=' expr
        { $$ = new yy.$.AssignOpNode('>>=', $1, $3); }
    | expr '<<=' expr
        { $$ = new yy.$.AssignOpNode('<<=', $1, $3); }
    | expr '>>>=' expr
        { $$ = new yy.$.AssignOpNode('>>>=', $1, $3); }
    | expr '<<<=' expr
        { $$ = new yy.$.AssignOpNode('<<<=', $1, $3); }
    ;

array
    : '[' ']'
        { $$ = new yy.$.ArrayNode([]); }
    | '[' array-list ']'
        { $$ = new yy.$.ArrayNode($2); }
    ;

array-list
    : expr
        { $$ = [$1] }
    | array-list ',' expr
        { $$ = $1.concat($3); }
    ;

object
    : '{' '}'
        { $$ = new yy.$.ObjectNode({}); }
    | '{' object-map '}'
        { $$ = new yy.$.ObjectNode($2); }
    ;

object-property
    : object-id ':' expr
        { $$ = new yy.$.ObjectProperyNode($1, $3); }
    ;

object-map
    : object-property
        { $$ = [$1] }
    | object-map ',' object-property
        { $1.push($3); $$ = $1; }
    ;

object-id
    : ID
    | STRING
    ;

scalar
    : NUMBER
        { $$ = new yy.$.ScalarNode($1, 'number'); }
    | TRUE
        { $$ = new yy.$.ScalarNode(true, 'boolean'); }
    | FALSE
        { $$ = new yy.$.ScalarNode(false, 'boolean'); }
    | NULL
        { $$ = new yy.$.ScalarNode(null, 'null'); }
    ;

identifier
    : ID
        { $$ = new yy.$.IdentifierNode($1); }
    | identifier '.' ID
        { $$ = new yy.$.PropertyOpNode($1, $3); }
    | identifier '[' expr ']'
        { $$ = new yy.$.IndexOpNode($1, $3); }
    | '(' expr ')'
        { $$ = $2; }
    ;

expr-statement
    : STATEMENT_TAG statement-node NEWLINE
        { $$ = $2; }
    ;

statement-node
    : statement
        { $$ = new yy.$.StatementNode($1); }
    | statement ';'
        { $$ = new yy.$.StatementNode($1); }
    ;

var-declarator-list
    : var-declarator
        { $$ = [$1]; }
    | var-declarator-list ',' var-declarator
        { $$ = $1.concat($3); }
    ;

var-declarator
    : ID
        { $$ = new yy.$.VarDeclarationNode($1); }
    | ID '=' expr
        { $$ = new yy.$.VarDeclarationNode($1, $3); }
    ;

statement
    : expr
    | VAR var-declarator-list
        { $$ = new yy.$.VarStatementNode($2, 'var'); }
    | LET var-declarator-list
        { $$ = new yy.$.VarStatementNode($2, 'let'); }
    ;

args-list
    : expr
        { $$ = [$1] }
    | args-list ',' expr
        { $$ = $1.concat($3); }
    ;


slice-expr
    : expr ':' %prec SLICE
        { $$ = [$1, null]; }
    | ':' expr  %prec SLICE
        { $$ = [null, $2]; }
    | expr ':' expr  %prec SLICE
        { $$ = [$1, $3]; }
    ;

sub-expr
    : ID
        { $$ = new yy.$.IdentifierNode($1); }
    | text-string
        { $$ = $1; }
    | '(' expr ')'
        { $$ = $2; }
    | sub-expr '(' ')'
        { $$ = new yy.$.FunctionCallOpNode($1, []); }
    | sub-expr '(' args-list ')'
        { $$ = new yy.$.FunctionCallOpNode($1, $3); }
    | sub-expr '.' ID
        { $$ = new yy.$.PropertyOpNode($1, $3); }
    | sub-expr '[' expr ']'
        { $$ = new yy.$.IndexOpNode($1, $3); }
    | sub-expr '[' slice-expr ']'
        { $$ = new yy.$.SliceOpNode($1, $3[0], $3[1]); }
    | array
    | object
    ;

expr
    : scalar
    | sub-expr
    | unary
    | assign
    | binary
    | ternary
    ;