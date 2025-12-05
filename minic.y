%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* from flex */
int yylex(void);
void yyerror(const char *s);
extern int yylineno;

/* ---------- Symbol table ---------- */

#define MAX_SYMBOLS 200

typedef struct {
    char name[64];
    char type[16];      /* "int", "float", "char" */
    int  is_array;      /* 0 = scalar, 1 = array */
    int  size;          /* array size if is_array==1, else 0 */
    int  declared_line;
    int  initialized;
    int  used;
} Symbol;

Symbol symtab[MAX_SYMBOLS];
int sym_count = 0;

int  add_symbol(const char *name, const char *type,
                int is_array, int size, int line);
int  find_symbol(const char *name);
void mark_initialized(const char *name);
void mark_used(const char *name);
void print_unused_warnings(void);

/* for current declaration type */
char current_type[16] = "int";

%}

/* ---------- Bison declarations ---------- */

%union {
    char *str;
}

%token <str> ID
%token <str> NUM

%token INT FLOAT CHAR
%token IF ELSE WHILE FOR
%token RELOP AND OR

%type  <str> expr
%type  <str> expr_opt

%left OR
%left AND
%nonassoc RELOP
%left '+' '-'
%left '*' '/'
%right '!'          /* unary not */

%nonassoc IFX       /* for dangling else */
%nonassoc ELSE

%%

/* ---------- Grammar rules ---------- */

/* Whole program: just a list of statements (and declarations) */
program
    : stmt_list
      {
          printf("=== ANALYSIS COMPLETE ===\n");
          print_unused_warnings();
      }
    ;

/* A sequence of statements, possibly empty */
stmt_list
    : stmt_list stmt
    | /* empty */
    ;

/* A statement can be: declaration, assignment, block, if, while, for */
stmt
    : simple_stmt
    | compound_stmt
    | if_stmt
    | while_stmt
    | for_stmt
    | declaration
    ;

/* Declarations: int/float/char, with optional arrays */
declaration
    : type declarator_list ';'
    ;

type
    : INT   { strcpy(current_type, "int");   }
    | FLOAT { strcpy(current_type, "float"); }
    | CHAR  { strcpy(current_type, "char");  }
    ;

declarator_list
    : declarator
    | declarator_list ',' declarator
    ;

declarator
    : ID
      {
          add_symbol($1, current_type, 0, 0, yylineno);
      }
    | ID '[' NUM ']'
      {
          int size = atoi($3);
          add_symbol($1, current_type, 1, size, yylineno);
      }
    ;

/* Simple statement = assignment with ; */
simple_stmt
    : assignment ';'
    ;

/* Assignments: scalar or array element */
assignment
    : ID '=' expr
      {
          int idx = find_symbol($1);
          if (idx == -1) {
              printf("Error (line %d): variable '%s' used but not declared\n",
                     yylineno, $1);
          } else {
              mark_initialized($1);
              mark_used($1); /* treat assignment as a use of lhs name */
          }
      }
    | ID '[' expr ']' '=' expr
      {
          int idx = find_symbol($1);
          if (idx == -1) {
              printf("Error (line %d): array '%s' used but not declared\n",
                     yylineno, $1);
          } else {
              if (!symtab[idx].is_array) {
                  printf("Warning (line %d): '%s' used with index but not declared as array\n",
                         yylineno, $1);
              }
              mark_initialized($1);
              mark_used($1);
          }
      }
    ;

/* Compound statement = block { ... } */
compound_stmt
    : '{' stmt_list '}'
    ;

/* If / if-else */
if_stmt
    : IF '(' expr ')' stmt %prec IFX
    | IF '(' expr ')' stmt ELSE stmt
    ;

/* While loop */
while_stmt
    : WHILE '(' expr ')' stmt
    ;

/* For loop: for(initial ; condition ; update) stmt */
for_stmt
    : FOR '(' simple_assign_opt ';' expr_opt ';' simple_assign_opt ')' stmt
    ;

/* Optional simple assignment in for header */
simple_assign_opt
    : /* empty */
    | ID '=' expr
      {
          int idx = find_symbol($1);
          if (idx == -1) {
              printf("Error (line %d): variable '%s' used but not declared\n",
                     yylineno, $1);
          } else {
              mark_initialized($1);
              mark_used($1);
          }
      }
    ;

/* Optional expression in for header */
expr_opt
    : /* empty */    { $$ = NULL; }
    | expr           { $$ = $1;   }
    ;

/* Expressions (no types, just check variable usage) */
expr
    : expr '+' expr      { $$ = $1; }
    | expr '-' expr      { $$ = $1; }
    | expr '*' expr      { $$ = $1; }
    | expr '/' expr      { $$ = $1; }
    | expr RELOP expr    { $$ = $1; }
    | expr AND expr      { $$ = $1; }
    | expr OR  expr      { $$ = $1; }
    | '!' expr           { $$ = $2; }
    | '(' expr ')'       { $$ = $2; }
    | ID
      {
          int idx = find_symbol($1);
          if (idx == -1) {
              printf("Error (line %d): variable '%s' used but not declared\n",
                     yylineno, $1);
          } else {
              mark_used($1);
              if (!symtab[idx].initialized) {
                  printf("Warning (line %d): variable '%s' used before initialization\n",
                         yylineno, $1);
              }
          }
          $$ = $1;
      }
    | ID '[' expr ']'
      {
          int idx = find_symbol($1);
          if (idx == -1) {
              printf("Error (line %d): array '%s' used but not declared\n",
                     yylineno, $1);
          } else {
              if (!symtab[idx].is_array) {
                  printf("Warning (line %d): '%s' used with index but not declared as array\n",
                         yylineno, $1);
              }
              mark_used($1);
              if (!symtab[idx].initialized) {
                  printf("Warning (line %d): array '%s' used before any initialization\n",
                         yylineno, $1);
              }
          }
          $$ = $1;
      }
    | NUM
      {
          $$ = $1;
      }
    ;

%%

/* ---------- C code section: helpers ---------- */

int main(void)
{
    printf("Minic-Analyzer (static analysis only)\n");
    if (yyparse() == 0) {
        printf("Parsing finished.\n");
    }
    return 0;
}

void yyerror(const char *s)
{
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, s);
}

/* ----- symbol table functions ----- */

int find_symbol(const char *name)
{
    for (int i = 0; i < sym_count; i++) {
        if (strcmp(symtab[i].name, name) == 0)
            return i;
    }
    return -1;
}

int add_symbol(const char *name, const char *type,
               int is_array, int size, int line)
{
    int idx = find_symbol(name);
    if (idx != -1) {
        printf("Error (line %d): variable '%s' redeclared (first declared at line %d)\n",
               line, name, symtab[idx].declared_line);
        return -1;
    }
    if (sym_count >= MAX_SYMBOLS) {
        fprintf(stderr, "Symbol table full!\n");
        exit(1);
    }

    strcpy(symtab[sym_count].name, name);
    strcpy(symtab[sym_count].type, type);
    symtab[sym_count].is_array = is_array;
    symtab[sym_count].size = size;
    symtab[sym_count].declared_line = line;
    symtab[sym_count].initialized = 0;
    symtab[sym_count].used = 0;

    sym_count++;
    return 0;
}

void mark_initialized(const char *name)
{
    int idx = find_symbol(name);
    if (idx != -1) {
        symtab[idx].initialized = 1;
    }
}

void mark_used(const char *name)
{
    int idx = find_symbol(name);
    if (idx != -1) {
        symtab[idx].used = 1;
    }
}

void print_unused_warnings(void)
{
    for (int i = 0; i < sym_count; i++) {
        if (!symtab[i].used) {
            printf("Warning: variable '%s' declared at line %d but never used\n",
                   symtab[i].name, symtab[i].declared_line);
        }
    }
}
