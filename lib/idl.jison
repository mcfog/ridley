
%lex

%%

(?:\#|\/\/)([^\n]+)          return 'COMMENT';

"service"       return 'T_SERVICE';
"struct"        return 'T_STRUCT';
"function"      return 'T_FUNCTION';
"enum"          return 'T_ENUM';

"int"          return 'T_INT';
"bool"         return 'T_BOOL';
"float"        return 'T_FLOAT';
"string"       return 'T_STRING';
"void"         return 'T_VOID';

"[]" return "[]";
'{' return "{";
'}' return "}";
'(' return "(";
')' return ")";
'?' return "?";



','                     /* ignore ; */
';'                     /* ignore ; */
\s+                     /* skip whitespace */
[a-zA-Z][a-zA-Z0-9_]*   return 'IDENT';
[1-9][0-9]*             return 'INT';
<<EOF>>                 return 'EOF';

/lex


%%

IdlFile
  : SourceElements EOF {return $$;}
  ;

SourceElements
  : Definition { $$ = [$1]; }
  | SourceElements Definition { $1.push($2); $$ = $1; }
  ;


Definition
  : RawDefinition
  | Comments RawDefinition { $$ = appendComment($1, $2); }
  ;

RawDefinition
  : StructDefinition { $$ = $1; } 
  | EnumDefinition { $$ = $1; }
  | ServiceDefinition { $$ = $1; }
  ;

Comments
  : COMMENT { $$ = [$1.replace(/^(#|\/\/)/, '')]; }
  | Comments COMMENT { $1.push($2.replace(/^(#|\/\/)/, '')); $$ = $1; }
  ;

StructDefinition
  : T_STRUCT IDENT "{" FieldDeclarations "}" { 
      $$ = {
        define: 'struct',
        id: $2,
        fields:$4
      }; 
    }
  ;

FieldDeclarations
  : FieldDeclaration { $$ = [$1] }
  | FieldDeclarations FieldDeclaration { $1.push($2); $$ = $1; }
  ;

FieldDeclaration
  : RawFieldDeclaration
  | Comments RawFieldDeclaration { $$ = appendComment($1, $2); }
  ;

RawFieldDeclaration
  : TypeDeclaration IDENT { $$ = {id: $2, type: $1}; }
  | TypeDeclaration IDENT "?" { $$ = {id: $2, type: $1, optional: true}; }
  ;

TypeDeclaration
  : IDENT { $$ = {ref: $1} }
  | BuiltinType
  | TypeArrayDeclaration { $$ = $1; }
  ;

BuiltinType
  : T_INT { $$ = 'int'; }
  | T_BOOL { $$ = 'bool'; }
  | T_FLOAT { $$ = 'float'; }
  | T_STRING { $$ = 'string'; }
  ;

TypeArrayDeclaration
  : TypeDeclaration "[]" { $$ = {arrayOf: $1}; }
  ;

EnumDefinition
  : T_ENUM IDENT "{" EnumValues "}" { 
      $$ = normalizeEnum($2, $4);
    }
  ;

EnumValues
  : EnumValue { 
    if(!$1.value) {
      $$ = {
        arr: [$1]
      };
    } else {
      $$ = {
        map: {
        },
        reverse: {
        }
      };

      $$.map[$1.value] = $1.id;
      $$.reverse[$1.id] = $1;
    }
  }
  | EnumValues EnumValue {
    if(!$2.value) {
      if(!$1.arr) {
        throw new Error('bad enum declaration');
      }

      $1.arr.push($2);
      $$ = $1;
    } else {
      if(!$1.map) {
        throw new Error('bad enum declaration');
      }

      if($1.reverse[$2.id]) {
        throw new Error('duplicate enum: ' + $2.id);
      }

      if($1.map[$2.value]) {
        throw new Error('duplicate enum value: ' + $2.value);
      }

      $1.map[$2.value] = $2.id;
      $1.reverse[$2.id] = $2;

      $$ = $1;
    }
  }
  ;

EnumValue
  : RawEnumValue
  | Comments RawEnumValue { $$ = appendComment($1, $2); }
  ;

RawEnumValue
  : IDENT INT { $$ = {id: $1, value: parseInt($2)}; }
  | IDENT { $$ = {id: $1}; }
  ;

ServiceDefinition
  : T_SERVICE IDENT "{" MethodDeclarations "}" { 
      $$ = {
        define: 'service',
        id: $2,
        methods:$4
      }; 
    }
  ;

MethodDeclarations
  : MethodDeclaration { $$ = [$1]; }
  | MethodDeclarations MethodDeclaration { $1.push($2); $$ = $1; }
  ;

MethodDeclaration
  : RawMethodDeclaration
  | Comments RawMethodDeclaration { $$ = appendComment($1, $2); }
  ;

RawMethodDeclaration
  : RetTypeDeclaration IDENT "(" ")" { $$ = {id: $2, ret: $1, params: []}; }
  | RetTypeDeclaration IDENT "(" FieldDeclarations ")" { $$ = {id: $2, ret: $1, params: $4}; }
  ;

RetTypeDeclaration
  : TypeDeclaration
  | T_VOID
  ;

%%

function normalizeEnum(id, def) {
  if(def.arr) {
    var obj = {map: {}, reverse: {}};
    def.arr.forEach(function(v, k) {
      v.value = ++k;
      obj.map[k] = v.id;
      obj.reverse[v.id] = v;
    })
    def = obj;
  };

  return {
    define: 'enum',
    id: id,
    map: def.map,
    reverse: def.reverse
  };  
}

function appendComment(comment, obj) {
  obj.comment = comment;
  return obj;
}
