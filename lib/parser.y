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
    | include
    | extend-block
    | text-line
    | text-expr
    | filter
    | comment
    | mixin-call
    ;

block
    : INDENT lines DEDENT
        { $$ = $2; }
    ;

text-line
    : TEXT_TAG text NEWLINE
        { $$ = $2; }
    ;

text-lines
    : text-line
    | text-lines text-line
    ;

text-block
    : INDENT text-lines DEDENT
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
    : expr
    | mixin-call-args ',' expr
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

tag-body-attr
    : '(' ')'
        { $$ = []; }
    | '(' tag-attrs ')'
        { $$ = $2; }
    | ATTRIBUTES '(' expr ')'
        { $$ = $3 }
    ;

tag-body-attrs
    : tag-body-attr
    | tag-body-attrs tag-body-attr
    ;

tag-body
    : tag-head
    | tag-body-attrs
    | tag-head tag-body-attrs
    ;

tag-tail-interp
    : text
    | EXPR_TAG expr
    | TEXT_TAG text
    | ':' tag-interp
    | '/'
    ;

tag-tail
    : NEWLINE block
    | text NEWLINE
    | text NEWLINE block
    | TEXT_TAG text NEWLINE
    | TEXT_TAG text NEWLINE block
    | EXPR_TAG expr NEWLINE
    | EXPR_TAG expr NEWLINE block
    | ':' tag
    | '/' NEWLINE
    | '.' NEWLINE text-block
    ;

tag-unnamed
    : tag-body NEWLINE
    | tag-tail
    | tag-body tag-tail
    ;

tag
    : TAG NEWLINE
    | TAG tag-unnamed
    | tag-body NEWLINE
    | tag-body tag-tail
    ;

tag-unnamed-interp
    : tag-body
    | tag-tail-interp
    | tag-body tag-tail-interp
    ;

tag-interp
    : TAG
    | TAG tag-unnamed-interp
    | tag-unnamed-interp
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