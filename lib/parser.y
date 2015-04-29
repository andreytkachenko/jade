%{
 var isArray = function (a) {
    Object.prototype.toString.call(a) === '[object Array]';
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
%left       ':' '.' TYPEOF INSTANCEOF
%right      '!' '~' PLUS MINUS

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
    | text-line
    | text-expr
    | include
    | filter
    | extend-block
    | comment
    | comment comment-block
    ;

block
    : INDENT lines DEDENT
        { $$ = $2; }
    ;

text-line
    : TEXT_TAG text NEWLINE
        { $$ = $2; }
    ;

text-block
    : text NEWLINE
        { $$ = [$1]; }
    | text-block text NEWLINE
        { $$ = $1.concat([$2]); }
    ;

text-expr
    : EXPR_TAG expr NEWLINE
        { $$ = $2 }
    ;

text
    : STRING
        { $$ = [new yy.$.StringNode($1)]; }
    | text STRING
        { $$ = $1.concat([new yy.$.StringNode($2)]); }

    | INTERP_EXPR_BEGIN expr INTERP_EXPR_END
        { $$ = [$2]; }
    | text INTERP_EXPR_BEGIN expr INTERP_EXPR_END
        { $$ = $1.concat([$3]); }

    | INTERP_TAG_BEGIN tag-interp INTERP_TAG_END
        { $$ = [$2]; }

    | text INTERP_TAG_BEGIN tag-interp INTERP_TAG_END
        { $$ = $1.concat([$3]); }
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
    : COMMENT NEWLINE
    ;

comments
    : comment
    | comments comment
    ;

comment-block
    : INDENT comments DEDENT
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
    :
        { $$ = []; }
    | '(' ')'
        { $$ = []; }
    | '(' mixin-args-list ')'
        { $$ = $2; }
    ;

mixin
    : MIXIN ID mixin-args NEWLINE mixin-block
        { $$ = new yy.$.MixinNode($2, $3, $4); }
    | MIXIN ID mixin-args tag-body NEWLINE mixin-block
        { $$ = new yy.$.MixinNode($2, $3, $6, $4); }
    | MIXIN ID mixin-args tag-additional-attrs NEWLINE mixin-block
        { $$ = new yy.$.MixinNode($2, $3, $6, null, $4); }
    | MIXIN ID mixin-args tag-body tag-additional-attrs NEWLINE mixin-block
        { $$ = new yy.$.MixinNode($2, $3, $7, $4, $5); }
    ;

extend-block
    : BLOCK ID NEWLINE block
    | BLOCK APPEND ID NEWLINE block
    | BLOCK PREPEND ID NEWLINE block
    | APPEND ID NEWLINE block
    | PREPEND ID NEWLINE block
    ;

tag-head-attr
    : TAG_CLASS
        { $$ = new yy.$.TagAttributeNode('class', $1, false); }
    | TAG_ID
        { $$ = new yy.$.TagAttributeNode('id', $1, false); }
    ;

tag-head-attrs
    : tag-head-attr
        { $$ = [$1] }
    | tag-head-attrs tag-head-attr
        { $$ = $1.concat([$2]); }
    ;

tag-head
    : TAG
        { $$ = {tag: $1, attrs: []}}
    | TAG tag-head-attrs
        { $$ = {tag: $1, attrs: $2}}
    | tag-head-attrs
        { $$ = {tag: 'div', attrs: $1}}
    ;

tag-attr
    : ATTR '=' expr
        { $$ = new yy.$.TagAttributeNode($1, $3, true); }
    | ATTR '!=' expr
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

tag-body
    : '(' ')'
        { $$ = []; }
    | '(' tag-attrs ')'
        { $$ = $2; }
    ;

tag-additional-attrs
    : ATTRIBUTES '(' expr ')'
        { $$ = $3 }
    ;

tag-unclosed
    : tag-head
        { $$ = new yy.$.TagNode($1, []); }
    | tag-head tag-body
        { $$ = new yy.$.TagNode($1, $2); }
    | tag-head tag-additional-attrs
        { $$ = new yy.$.TagNode($1, [], $2); }
    | tag-head tag-body tag-additional-attrs
        { $$ = new yy.$.TagNode($1, $2, $3); }
    ;

tag-default
    : tag-unclosed NEWLINE
    | tag-unclosed text NEWLINE
        { $1.block = [$2]; $$ = $1; }
    | tag-unclosed EXPR_TAG expr NEWLINE
        { $1.block = [$3]; $$ = $1; }
    ;

tag
    : tag-unclosed '/' NEWLINE
    | tag-unclosed ':' tag
        { $1.block = [$3]; $$ = $1; }
    | tag-default
    | tag-default block
        { $1.block=$1.block||[]; $1.block = $1.block.concat($2); $$=$1; }
    | tag-unclosed '.' NEWLINE block
        { $1.block=$4; $$=$1; }
    | tag-unclosed '.' text NEWLINE text-block
        { $1.block=[$3].concat([$5]); $$=$1; }
    ;

tag-interp
    : tag-unclosed
    | tag-unclosed text
        { $1.block = [$2]; $$ = $1; }
    | tag-unclosed EXPR_TAG expr
        { $1.block = [$3]; $$ = $1; }
    | tag-unclosed '/'
    | tag-unclosed ':' tag-interp
        { $1.block = [$3]; $$ = $1; }
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
    | expr TYPEOF expr
        { $$ = new yy.$.BinaryOpNode('typeof', $1, $3); }
    | expr INSTANCEOF expr
        { $$ = new yy.$.BinaryOpNode('instanceof', $1, $3); }

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

sub-expr
    : ID
        { $$ = new yy.$.IdentifierNode($1); }
    | STRING
        { $$ = new yy.$.StringNode($1); }
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