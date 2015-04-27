%{
    var self = this;
    this._ctx = this._ctx || {
        _indent: [0],
        _stack: [],
        state: function () {
            return this._stack[this._stack.length - 1];
        },
        initial: function () {
            this._stack = []
            this.conditionStack = ['INITIAL'];
        },
        replace: function (name, less) {
            this.leave();
            this.enter(name, less);
        },
        enter: function (name, less) {
            //console.log('---->', name, yytext);
            this._stack.push({
                name: name,
                cbc: 0
            });

            if (less !== undefined) {
                self.less(less);
            }

            return self.begin(name);
        },
        leave: function (count, less) {
            var state = null;
            if (count === undefined) count = 1;
            while (count--) {
                self.popState()
                state = this._stack.pop();
                //console.log('<----', this.state().name);
            }

            if (less !== undefined) {
                self.less(less);
            }

            return state;
        }
    };

    function isExprNotEnd (token, number) {
        var result = true;
        var prevTok = self._ctx.prevTok;
        self._ctx.prevTok = token;

        self._ctx.cbrace = self._ctx.cbrace||0;
        self._ctx.bbrace = self._ctx.bbrace||0;
        self._ctx.tbrace = self._ctx.tbrace||0;

        var toks = ['ID', 'NUM', 'STRING', 'NULL', 'UNDEFINED'];
        var brace = [')', ']', '}'];

        if (token === '(') self._ctx.cbrace++;
        if (token === ')') self._ctx.cbrace--;
        if (token === '[') self._ctx.bbrace++;
        if (token === ']') self._ctx.bbrace--;
        if (token === '{') self._ctx.tbrace++;
        if (token === '}') self._ctx.tbrace--;

        if (token === ',' && !self._ctx.cbrace && !self._ctx.bbrace && !self._ctx.tbrace) {
            result = false;
        }

        if (self._ctx.cbrace < 0 || self._ctx.bbrace < 0 || self._ctx.tbrace < 0) {
            result = false;
        }

        if (self._ctx.cbrace === 0 && self._ctx.bbrace === 0 && self._ctx.tbrace === 0) {
            if (
                ~toks.indexOf(prevTok) && ~toks.indexOf(token) ||
                ~brace.indexOf(prevTok) && ~toks.indexOf(token) ||
                prevTok === '}' && token === '(' ||
                ~toks.indexOf(prevTok) && token === '{'
            ) {
                result = false;
            }
        }

        if (!result) {
            ctx.leave(number, 0);
        }

        return result;
    }

    function inBraces() {
        return self._ctx.cbrace || self._ctx.bbrace || self._ctx.tbrace;
    }

    function resetExpr() {
        self._ctx.prevTok = undefined;
        self._ctx.cbrace = 0;
        self._ctx.bbrace = 0;
        self._ctx.tbrace = 0;
    }

    var ctx = this._ctx;
%}

%options backtrack_lexer true

TAG                     [a-zA-Z][a-zA-Z0-9_:-]+[a-zA-Z0-9]|[a-zA-Z][a-zA-Z0-9]|[a-zA-Z]
CLASS                   [a-zA-Z_][a-zA-Z0-9_-]*
STRING                  \"|\'
NUM                     [0-9]
ID                      [$a-zA-Z_][$a-zA-Z0-9_]*
WS                      [ \t]
EQUAL                   \=\=\=|\=\=|\>\>\>|\<\<\<|\!\=\=|\=\=|\!\=|\>\=|\<\=|\>\>|\<\<
ASSIGN                  \>\>\>\=|\<\<\<\=|\|\=|&\=|\+\=|\-\=|\*\=|\/\=|%\=|\>\>\=|\<\<\=|\^\=|\=
OPERATORS               [!~\[\]\(\)\{\},>.<+/*&%:?^|-]
NL                      (?![a-zA-Z0-9_$])

%s number string string-body text-line text-block comment-line comment-block
%s interp tag-interp tag-interp-body
%s expr expr-body expr-return
%s tag tag-attrs tag-body tag-and-attrs
%s for-each if-while
%s mixin mixin-args mixin-call
%s block include include-filter filter

%%

\/\/\-|\/\/                 ctx.initial();ctx.enter('comment-block');

<interp>"#{"                ctx.enter('expr');yytext=true;return 'INTERP_EXPR_BEGIN';
<interp>"!{"                ctx.enter('expr');yytext=false;return 'INTERP_EXPR_BEGIN';
<interp>"}"                 ctx.leave();return 'INTERP_EXPR_END';
<interp>"#["                ctx.enter('tag-interp');return 'INTERP_TAG_BEGIN';
<interp>"]"                 ctx.leave();return 'INTERP_TAG_END';

<string>{STRING}            ctx._quote=yytext;ctx.enter('string-body');
<string-body>[^'"#!\n\]]*[^] {
                                var last = yytext.charAt(yyleng-1);
                                var preLast = yyleng > 0 ? yytext.charAt(yyleng-2) : ctx._quote;

                                switch (true) {
                                    default:
                                    case preLast === '\\':
                                        this.more();break;
                                    case last === '\n':
                                        ctx.leave(1, yyleng - 1);
                                        return 'STRING';
                                    case ctx._quote === last:
                                        if (ctx._quote === '"' || ctx._quote === "'") {
                                            yytext = yytext.substr(0, yyleng - 1);
                                        } else if (ctx._quote) {
                                            this.less(yyleng - 1);
                                        }
                                        ctx.leave(2);
                                        return 'STRING';
                                    case last === '#' || last === '!':
                                        var nextChar = this.input();
                                        this.unput(nextChar);

                                        if (nextChar === '{' || (last === '#' && nextChar === '[')) {
                                            this.unput(last);
                                            ctx.enter('interp');
                                            yytext = yytext.substr(0, yyleng-1);
                                            return 'STRING';
                                        } else {
                                            this.more();
                                        }
                                }
                            }

<number>{NUM}+\.{NUM}+      ctx.leave();return 'NUMBER';
<number>{NUM}+              ctx.leave();return 'NUMBER';

<expr>[^]                   resetExpr();ctx.replace('expr-body', 0);

<expr-body>var{NL}          if (isExprNotEnd('VAR')) return 'VAR';
<expr-body>delete{NL}       if (isExprNotEnd('DELETE')) return 'DELETE';
<expr-body>in{NL}           if (isExprNotEnd('IN')) return 'IN';
<expr-body>typeof{NL}       if (isExprNotEnd('TYPEOF')) return 'TYPEOF';
<expr-body>new{NL}          if (isExprNotEnd('NEW')) return 'NEW';
<expr-body>instanceof{NL}   if (isExprNotEnd('INSTANCEOF')) return 'INSTANCEOF';
<expr-body>null{NL}         if (isExprNotEnd('NULL')) return 'NULL';
<expr-body>true{NL}         if (isExprNotEnd('TRUE')) return 'TRUE';
<expr-body>false{NL}        if (isExprNotEnd('FALSE')) return 'FALSE';
<expr-body>undefined{NL}    if (isExprNotEnd('UNDEFINED')) return 'UNDEFINED';
<expr-body>{NUM}            if (isExprNotEnd('NUMBER')) ctx.enter('number', 0);
<expr-body>{STRING}         if (isExprNotEnd('STRING')) ctx.enter('string', 0);
<expr-body>{ID}             if (isExprNotEnd('ID')) return 'ID';
<expr-body>{EQUAL}          if (isExprNotEnd(yytext)) return yytext;
<expr-body>{ASSIGN}         if (isExprNotEnd(yytext)) return yytext;
<expr-body>\;               if (isExprNotEnd(yytext)) return yytext;
<expr-body>{OPERATORS}      if (isExprNotEnd(yytext)) return yytext;
<expr-body>\n               if (!inBraces()) ctx.leave(1, 0);

<text-block>\n{WS}*\n       this.unput('\n');
<text-block>\n{WS}*         {
                                var len = yyleng - 1,
                                    tokens = ['NEWLINE'];

                                if (len <= ctx._indent[0]) {
                                    ctx._block = undefined;
                                    ctx.leave(1, 0);
                                    ctx._noNewLine = true;
                                    tokens.push('DEDENT');
                                } else {
                                    ctx._quote = undefined;
                                    ctx.enter('string-body', (ctx._block||len) + 1);
                                    if (ctx._block === undefined) {
                                        ctx._block = len;
                                        tokens.push('INDENT');
                                    }
                                }

                                if (tokens.length) return tokens;
                            }
<text-block>[^]             ctx.enter('text-line', 0);

<comment-line>[^\n]+        ctx.leave(); return 'COMMENT';
<comment-block>\n{WS}*\n    this.unput('\n');
<comment-block>\n{WS}*      {
                                var len = yyleng - 1;
                                if (len <= ctx._indent[0]) {
                                    ctx.leave(1, 0);
                                } else {
                                    ctx.enter('comment-line', ctx._indent[0]);
                                }
                            }
<comment-block>[^]          ctx.enter('comment-line', 0);

<mixin>"mixin"              return 'MIXIN';
<mixin>{ID}                 return 'ID';
<mixin>"("                  ctx.enter('mixin-args', 0);
<mixin>\n                   ctx.leave(1, 0);
<mixin-args>"..."           return ELLIPSIS;
<mixin-args>"("             return '(';
<mixin-args>")"             ctx.leave(1); return ')';
<mixin-args>","             return ',';
<mixin-args>{ID}            return 'ID';

<mixin-call>{ID}            return 'ID';
<mixin-call>"("             ctx.enter('expr');return '(';
<mixin-call>")"             ctx.replace('tag-body');return ')';
<mixin-call>","             ctx.enter('expr');return ',';
<mixin-call>\n              ctx.leave();

<block>"block"              return 'BLOCK';
<block>"append"             return 'APPEND';
<block>"prepend"            return 'PREPEND';
<block>\n                   ctx.leave(1, 0);
<block>{ID}                 ctx.leave();return 'ID';

<for-each>"foreach"         return 'EACH';
<for-each>"for"             return 'EACH';
<for-each>"each"            return 'EACH';
<for-each>","               return ',';
<for-each>in{NL}            ctx.enter('expr');return 'IN';
<for-each>{ID}              return 'ID';
<for-each>\n                ctx.leave(1, 0);

<tag-attrs>\=|\!\=          ctx.enter('expr');return yytext;
<tag-attrs>"("              return '(';
<tag-attrs>")"              ctx.leave(); return ')';
<tag-attrs>","              return ',';
<tag-attrs>{TAG}            return 'ATTR';
<tag-attrs>\"{TAG}\"        return 'ATTR';
<tag-attrs>\'{TAG}\'        return 'ATTR';
<tag-attrs>{WS}+            /* ignore */
<tag-attrs>\n               /* ignore */

<tag-and-attrs>"("          ctx.enter('expr');return '(';
<tag-and-attrs>")"          ctx.leave();return ')';

<tag-interp-body,tag-body>\#{TAG}           yytext=yytext.substr(1);return 'TAG_ID';
<tag-interp-body,tag-body>\.{CLASS}         yytext=yytext.substr(1);return 'TAG_CLASS';
<tag-interp-body,tag-body>"("               ctx.enter('tag-attrs', 0);
<tag-interp-body,tag-body>"."               ctx.leave(2); ctx.enter('text-block'); return '.';
<tag-interp-body,tag-body>\=|\!\=           ctx.leave(2, 0);
<tag-interp-body,tag-body>\&attributes{NL}  ctx.enter('tag-and-attrs'); return 'ATTRIBUTES';
<tag-interp-body,tag-body>\:{NL}            ctx.leave(2); return ':';
<tag-interp-body,tag-body>\|                ctx._quote=null; ctx.enter('string-body');
<tag-interp-body,tag-body>\/                return '/';
<tag-body>\n                                ctx.leave(1, 0);
<tag-interp-body>[\]]                       ctx.leave(1, 0);
<tag-interp-body>[^\n]                      ctx._quote=']'; ctx.enter('string-body', 0);
<tag-body>[^]                               ctx._quote=null; ctx.enter('string-body', 0);

<tag>{TAG}                  ctx.enter('tag-body');return 'TAG';
<tag>\#{TAG}                ctx.enter('tag-body');yytext=yytext.substr(1);return 'TAG_ID';
<tag>\.{CLASS}              ctx.enter('tag-body');yytext=yytext.substr(1);return 'TAG_CLASS';
<tag-interp>{TAG}           ctx.enter('tag-interp-body');return 'TAG';
<tag-interp>\#{TAG}         ctx.enter('tag-interp-body');return 'TAG_ID';
<tag-interp>\.{CLASS}       ctx.enter('tag-interp-body');return 'TAG_CLASS';
<tag-interp>[\]]            ctx.leave(1, 0);
<tag>\n                     ctx.leave(1, 0);

<if-while>"if"              ctx.enter('expr');return 'IF';
<if-while>"unless"          ctx.enter('expr');return 'UNLESS';
<if-while>"when"            ctx.enter('expr');return 'WHEN';
<if-while>"case"            ctx.enter('expr');return 'CASE';
<if-while>"while"           ctx.enter('expr');return 'WHILE';
<if-while>else[ \t]*if      ctx.enter('expr');return ['ELSE', 'IF'];
<if-while>":"               ctx.leave(); return ':';
<if-while>\n                ctx.leave(1, 0);

<include>"include"          return 'INCLUDE';
<include>"extends"          return 'EXTENDS';
<include>":"                ctx.enter('include-filter');return 'FILTER_TAG';
<include>\n                 ctx.leave(1, 0);
<include>[^\n]+             return 'HREF';
<include-filter>{WS}+       /* ignore */
<include-filter>{ID}        ctx.leave();return 'ID';

<filter>{ID}                ctx.replace('text-block'); return 'ID';

<INITIAL>\n{WS}*\n          this.unput('\n');
<INITIAL>\n{WS}*            {
                                var indent = ctx._indent;
                                var tokens = ['NEWLINE'];

                                if (ctx._noNewLine) {
                                    tokens.pop();
                                    ctx._noNewLine = false;
                                }

                                yytext = '';
                                var len = yyleng - 1;

                                if (len > indent[0]) {
                                    indent.unshift(len);
                                    tokens.push("INDENT");
                                } else {
                                    while (len < indent[0]) {
                                        tokens.push("DEDENT");
                                        indent.shift();
                                    }
                                }

                                if (tokens.length) return tokens;
                            }

\+                          ctx.enter('mixin-call'); return 'CALL'
\|                          ctx.enter('text-line'); return 'TEXT_TAG'
\<                          ctx.enter('text-line', 0);
\-                          ctx.enter('expr'); return 'STATEMENT_TAG';
\=|\!\=                     ctx.enter('expr'); return 'EXPR_TAG';
\:                          ctx.enter('filter'); return 'FILTER_TAG';

mixin{NL}                   ctx.enter('mixin', 0);
block{NL}                   ctx.enter('block', 0);
(?:if|unless|while|else{WS}*if|when|case){NL}  ctx.enter("if-while", 0);
(?:foreach|for|each){NL}    ctx.enter("for-each", 0);
else{NL}                    return 'ELSE';
default{NL}                 return 'DEFAULT';
continue{NL}                return 'CONTINUE';
yield{NL}                   return 'YIELD';
break{NL}                   return 'BREAK';
(?:extends|include){NL}     ctx.enter('include', 0);

{TAG}                       ctx.enter("tag", 0);
\#{TAG}                     ctx.enter("tag", 0);
\.{CLASS}                   ctx.enter("tag", 0);

<*>[ \t]+                   /* ignore */
<<EOF>>                     return 'EOF';
%%
