%{
 var isArray = function (a) {
    return Object.prototype.toString.call(a) === '[object Array]';
 }
%}


%left       ','
%right      '=' '+=' '-=' '*=' '/=' '%=' '&=' '|=' '^=' '>>=' '<<=' '>>>=' '<<<='
%left       '&' '|' '^'
%left       '||' '&&'
%left       '==' '===' '!=' '!=='
%left       '<' '>' '<=' '>='
%left       '..'
%left       '+' '-'
%left       '*' '/' '%'
%left       ':' '.' INSTANCEOF
%right      '!' '~' PLUS MINUS TYPEOF DELETE NEW

%start program

%%

program
    : program-lines EOF
        { return $1; }
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
    | text-tag
    | text-expr
    | text-statement
    | filter
    | comment
    | mixin-call
    ;

block
    : INDENT lines DEDENT
        { $$ = $2; }
    ;

text-tag
    : TEXT_TAG text NEWLINE
        { $$ = $2; }
    ;

text-line
    : text NEWLINE
        { $$ = $1.addString($2); }
    ;

text-lines
    : text-line
        { $$ = $1; }
    | text-lines text-line
        { $$ = $1.addStringArray($2); }
    ;

text-block
    : INDENT text-lines DEDENT
        { $$ = $2; }
    ;

text-expr
    : EXPR_TAG expr-node NEWLINE
        { $$ = $2; }
    ;

text-statement
    : STATEMENT_TAG statement-node NEWLINE
        { $$ = $2; }
    ;

expr-node
    : expr
        { $$ = new yy.$.ExprNode($1); }
    ;

text
    : STRING
        { $$ = new yy.$.StringArrayNode($1); }

    | text STRING
        { $$ = $1.addString($2); }

    | INTERP_EXPR_BEGIN expr-node INTERP_EXPR_END
        { $$ = new yy.$.StringArrayNode($2); }

    | text INTERP_EXPR_BEGIN expr-node INTERP_EXPR_END
        { $$ = $1.addNode($3); }

    | INTERP_TAG_BEGIN tag-interp INTERP_TAG_END
        { $$ = new yy.$.StringArrayNode($2); }

    | text INTERP_TAG_BEGIN tag-interp INTERP_TAG_END
        { $$ = $1.addNode($3); }
    ;

include
    : INCLUDE HREF NEWLINE
    | INCLUDE FILTER_TAG ID HREF NEWLINE
    ;

extends
    : EXTENDS HREF NEWLINE
    ;

filter
    : FILTER_TAG ID NEWLINE text-block
    ;

comment
    : comment-line
    | comment-line comment-block
    ;

comment-line
    : COMMENT NEWLINE
    ;

comment-lines
    : comment-line
    | comment-lines comment-line
    ;

comment-block
    : INDENT comment-lines DEDENT
    ;

if
    : IF expr-node NEWLINE block
        { $$ = new yy.$.IfElseNode($2, $4); }
    | IF expr-node NEWLINE block ELSE NEWLINE block
        { $$ = new yy.$.IfElseNode($2, $4, $7); }
    | IF expr-node NEWLINE block ELSE if
        { $$ = new yy.$.IfElseNode($2, $4, $6); }
    | UNLESS expr-node NEWLINE block
        { $$ = new yy.$.IfElseNode(new yy.$.UnaryOpNode('!', $2), $4); }
    | UNLESS expr-node NEWLINE block ELSE NEWLINE block
        { $$ = new yy.$.IfElseNode(new yy.$.UnaryOpNode('!', $2), $4, $7); }
    | UNLESS expr-node NEWLINE block ELSE if
        { $$ = new yy.$.IfElseNode(new yy.$.UnaryOpNode('!', $2), $4, $6); }
    ;

for-in
    : EACH ID IN expr-node NEWLINE block
        { $$ = new yy.$.ForInNode($2, null, $4, $6); }
    | EACH ID ',' ID IN expr-node NEWLINE block
        { $$ = new yy.$.ForInNode($2, $4, $6, $8); }
    ;

when-block
    : WHEN expr-node NEWLINE
        { $$ = new yy.$.CaseWhenNode($2, null); }
    | WHEN expr-node NEWLINE block
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
    : CASE expr-node NEWLINE INDENT case-block DEDENT
        { $$ = new yy.$.CaseNode($2, $5); }
    ;

while
    : WHILE expr-node NEWLINE block
        { $$ = new yy.$.WhileNode($2, $4); }
    ;

extend-block
    : BLOCK ID NEWLINE block
    | BLOCK APPEND ID NEWLINE block
    | BLOCK PREPEND ID NEWLINE block
    | APPEND ID NEWLINE block
    | PREPEND ID NEWLINE block
    ;

mixin-line
    : line
    | YIELD NEWLINE
        { $$ = new yy.$.MixinYieldNode(); }
    | BLOCK NEWLINE
        { $$ = new yy.$.MixinBlockNode(); }
    ;

mixin-lines
    : mixin-line
        { $$ = [$1]; }
    | mixin-lines mixin-line
        { $$ = $1.concat([$2]); }
    ;

mixin-block
    : INDENT mixin-lines DEDENT
        { $$ = $2; }
    ;

mixin-args-list
    : ID
        { $$ = [$1]; }
    | mixin-args-list ',' ID
        { $$ = [$1]; }
    | mixin-args-list ',' '...' ID
        { $$ = [$1]; }
    ;

mixin-args
    : '(' ')'
        { $$ = []; }
    | '(' mixin-args-list ')'
        { $$ = $2; }
    ;

mixin
    : MIXIN ID NEWLINE mixin-block
        { $$ = new yy.$.MixinNode($2, [], $4); }
    | MIXIN ID mixin-args NEWLINE mixin-block
        { $$ = new yy.$.MixinNode($2, $3, $4); }
    ;

mixin-call-args
    : expr-node
    | mixin-call-args ',' expr-node
    ;

mixin-simple-call
    : '(' ')'
    | '(' mixin-call-args ')'
    ;

mixin-call
    : CALL ID mixin-simple-call tag-unnamed
    ;

tag-head-attr
    : TAG_CLASS
        { $$ = new yy.$.TagAttributeNode('class', $1, false); }
    | TAG_ID
        { $$ = new yy.$.TagAttributeNode('id', $1, false); }
    ;

tag-head
    : tag-head-attr
        { $$ = [$1] }
    | tag-head tag-head-attr
        { $$ = $1.concat([$2]); }
    ;

tag-attr
    : ATTR '=' expr-node
        { $$ = new yy.$.TagAttributeNode($1, $3, true); }
    | ATTR '!=' expr-node
        { $$ = new yy.$.TagAttributeNode($1, $3, false); }
    ;

tag-attrs
    : tag-attr
        { $$ = [$1] }
    | tag-attrs tag-attr
        { $$ = $1.concat([$2]); }
    | tag-attrs ',' tag-attr
        { $$ = $1.concat([$3]); }
    ;

tag-body-attr
    : '(' ')'
        { $$ = []; }
    | '(' tag-attrs ')'
        { $$ = $2; }
    | ATTRIBUTES '(' expr-node ')'
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
    : text
        { $$ = [$1]; }
    | EXPR_TAG expr-node
        { $$ = [$2]; }
    | TEXT_TAG text
        { $$ = [$2]; }
    | ':' tag-interp
        { $$ = [$2]; }
    | '/'
        { $$ = []; }
    ;

tag-tail
    : NEWLINE block
        { $$ = $2; }
    | text NEWLINE
        { $$ = [$1]; }
    | text NEWLINE block
        { $$ = [$1].concat($3); }
    | TEXT_TAG text NEWLINE
        { $$ = [$2]; }
    | TEXT_TAG text NEWLINE block
        { $$ = [$2].concat($4); }
    | EXPR_TAG expr-node NEWLINE
        { $$ = [$2]; }
    | EXPR_TAG expr-node NEWLINE block
        { $$ = [$2].concat($4); }
    | ':' tag
        { $$ = [$2]; }
    | '/' NEWLINE
        { $$ = []; }
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

tag
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
        { $$ = yy.$.TagNode($1, null, null); }
    | TAG tag-unnamed-interp
        { $$ = yy.$.TagNode($1, $2[0], $2[1]); }
    | tag-body NEWLINE
        { $$ = yy.$.TagNode(null, $1, null); }
    | tag-body tag-tail-interp
        { $$ = yy.$.TagNode(null, $1, $2); }
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

object-map
    : object-id ':' expr
        { var a = {}; a[$1] = $3; $$ = a; }
    | object-map ',' object-id ':' expr
        { $1[$3] = $5; $$ = $1; }
    ;

object-id
    : ID
    | STRING
    ;

args-list
    : expr
        { $$ = [$1] }
    | args-list ',' expr
        { $$ = $1.concat($3); }
    ;

index-expr
    : expr ':'
        { $$ = [$1, null]; }
    | ':' expr
        { $$ = [null, $2]; }
    | expr ':' expr
        { $$ = [$1, $3]; }
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

statement-node
    : statement
    | statement ';'
    ;

statement
    : expr
    | VAR ID
        { $$ = new yy.$.VariableNode($2); }
    | VAR ID '=' expr
        { $$ = new yy.$.VariableNode($2, $4); }
    | DELETE identifier
        { $$ = new yy.$.DeleteNode($2); }
    ;

sub-expr
    : ID
        { $$ = new yy.$.IdentifierNode($1); }
    | text
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
    | sub-expr '[' index-expr ']'
        { $$ = new yy.$.SliceOpNode($1, $3[0], $3[1]); }
    | array
    ;

expr
    : scalar
    | object
    | sub-expr
    | unary
    | assign
    | binary
    ;