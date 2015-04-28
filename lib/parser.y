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
    : lines EOF                { return $1; }
    ;

lines
    : line                      { $$ = [$1]; }
    | lines line                { $$ = $1.concat([$2]); }
    ;

line
    : tag
    | if
    | while
    | for-in
    | case
    | text-line
    ;

block
    : INDENT lines DEDENT
        { $$ = $2; }
    ;

text-line
    : text NEWLINE
    | TEXT_TAG text NEWLINE
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
    | tag-unclosed '.' text NEWLINE block
        { $1.block=[$3].concat($5); $$=$1; }
    ;

text
    : STRING
        { $$ = new yy.$.ScalarNode($1); }
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