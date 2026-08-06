:- encoding(utf8).

% build.pl — regenerates and verifies the derived artefacts from index.pl.
%
%   swipl -q -g build -t halt build.pl
%   swipl -q -g check -t halt build.pl
%
% index.pl is the only data source. The build writes:
%
%   data/index.csv    the transcription as CSV
%   index.html        the generated summary and index list, in place
%
% Both generated regions in index.html are bounded by explicit markers. The
% complete outputs are assembled and validated before either file is written.

:- ensure_loaded(flora).

:- use_module(library(aggregate), [aggregate_all/3]).
:- use_module(library(apply),     [foldl/4]).
:- use_module(library(filesex),   [make_directory_path/1]).
:- use_module(library(lists),     [member/2, memberchk/2]).

:- dynamic project_directory/1.
:- prolog_load_context(directory, Directory),
   asserta(project_directory(Directory)).

project_path(Relative, Path) :-
    project_directory(Directory),
    directory_file_path(Directory, Relative, Path).

% ------------------------------------------------------------------ rows

section(Name, Sec) :-
    sort_key(Name, Key),
    sub_atom(Key, 0, 1, _, First),
    ( First == '{' -> Sec = 'æ'
    ; First == '|' -> Sec = 'ö'
    ; Sec = First ).

% ------------------------------------------------------------------- csv

csv_text(Text) :-
    with_output_to(string(Text),
        ( format("name,page,language~n", []),
          forall(entry(Name, Page, Lang),
                 write_csv_row(Name, Page, Lang)) )).

write_csv_row(Name, Page, Lang) :-
    csv_field(Name, NameField),
    csv_field(Lang, LangField),
    format("~s,~d,~s~n", [NameField, Page, LangField]).

csv_field(Atom, Field) :-
    atom_string(Atom, String),
    replace_char(String, "\"", "\"\"", Escaped),
    (   csv_needs_quotes(String)
    ->  format(string(Field), "\"~s\"", [Escaped])
    ;   Field = Escaped
    ).

csv_needs_quotes(String) :-
    memberchk(Char, [",", "\"", "\n", "\r"]),
    sub_string(String, _, _, _, Char), !.

replace_char(Source, Character, Replacement, Result) :-
    (   sub_string(Source, Before, Length, After, Character)
    ->  sub_string(Source, 0, Before, _, Head),
        Start is Before + Length,
        sub_string(Source, Start, After, 0, Tail),
        replace_char(Tail, Character, Replacement, ReplacedTail),
        string_concat(Head, Replacement, Prefix),
        string_concat(Prefix, ReplacedTail, Result)
    ;   Result = Source
    ).

% --------------------------------------------------------------- markup

label(i, "I&thinsp;J") :- !.
label(æ, "Æ") :- !.
label(ö, "Ö") :- !.
label(Sec, Label) :-
    upcase_atom(Sec, Upper),
    atom_string(Upper, Label).

html_text(Atom, Escaped) :-
    atom_string(Atom, String),
    replace_char(String, "&", "&amp;", A),
    replace_char(A,      "<", "&lt;",  B),
    replace_char(B,      ">", "&gt;",  Escaped).

entry_markup(Name, Page, la, Markup) :- !,
    html_text(Name, Safe),
    format(string(Markup),
           "<li lang=\"la\"><i>~s</i> <b>~d</b></li>", [Safe, Page]).
entry_markup(Name, Page, da, Markup) :-
    html_text(Name, Safe),
    format(string(Markup),
           "<li lang=\"da\">~s <b>~d</b></li>", [Safe, Page]).

section_markup(Sec, Markup) :-
    label(Sec, Label),
    format(string(Markup),
           "<h3 class=\"fx-sec\" id=\"fx-s-~w\">~s</h3>~n<ul class=\"fx-l\">",
           [Sec, Label]).

index_markup(Text) :-
    findall(Sec-Name-Page-Lang,
            ( entry(Name, Page, Lang), section(Name, Sec) ), Rows),
    foldl(emit_row, Rows, none-[], _-Reverse),
    reverse(["</ul>"|Reverse], Parts),
    atomics_to_string(Parts, "\n", Text).

emit_row(Sec-Name-Page-Lang, Previous-Acc, Sec-[Entry|Acc1]) :-
    entry_markup(Name, Page, Lang, Entry),
    (   Sec == Previous
    ->  Acc1 = Acc
    ;   section_markup(Sec, Heading),
        ( Previous == none
        -> Acc1 = [Heading|Acc]
        ;  Acc1 = [Heading,"</ul>"|Acc]
        )
    ).

summary_markup(Markup) :-
    aggregate_all(count, entry(_,_,_),  Total),
    aggregate_all(count, entry(_,_,la), Latin),
    aggregate_all(count, entry(_,_,da), Danish),
    setof(Page, Name^Lang^entry(Name, Page, Lang), Pages),
    length(Pages, PageCount),
    format(string(Markup),
           "<h2 class=\"fx-h\">Index &middot; <b>~d</b> names &middot; <b>~d</b> Latin &middot;~n  <b>~d</b> Danish &middot; <b>~d</b> pages</h2>",
           [Total, Latin, Danish, PageCount]).

% --------------------------------------------------------- generated HTML

marker(Name, Begin, End) :-
    format(string(Begin), "<!-- BEGIN GENERATED ~s -->~n", [Name]),
    format(string(End),   "~n<!-- END GENERATED ~s -->",   [Name]).

replace_generated(Source, Name, Replacement, Result) :-
    marker(Name, Begin, End),
    (   sub_string(Source, Before, BeginLength, _, Begin)
    ->  ContentStart is Before + BeginLength,
        sub_string(Source, ContentStart, _, 0, Rest),
        (   sub_string(Rest, RelativeEnd, _, _, End)
        ->  TailStart is ContentStart + RelativeEnd,
            sub_string(Source, 0, ContentStart, _, Head),
            sub_string(Source, TailStart, _, 0, Tail),
            string_concat(Head, Replacement, Partial),
            string_concat(Partial, Tail, Result)
        ;   format(user_error, "Missing end marker for generated ~s region.~n", [Name]),
            fail
        )
    ;   format(user_error, "Missing begin marker for generated ~s region.~n", [Name]),
        fail
    ).

generated(Csv, Html) :-
    validate_data,
    csv_text(Csv),
    project_path('index.html', HtmlPath),
    read_file_to_string(HtmlPath, Source, [encoding(utf8)]),
    summary_markup(Summary),
    index_markup(Index),
    replace_generated(Source, "SUMMARY", Summary, WithSummary),
    replace_generated(WithSummary, "INDEX", Index, Html),
    wordpress_safe(Html).

% ---------------------------------------------------------------- checks

valid_entry(Name, Page, Lang) :-
    atom(Name), Name \== '',
    integer(Page), Page > 0,
    memberchk(Lang, [la, da]).

validate_data :-
    (   once((entry(Name, Page, Lang), \+ valid_entry(Name, Page, Lang)))
    ->  format(user_error, "Invalid entry: ~q.~n", [entry(Name, Page, Lang)]),
        fail
    ;   true
    ),
    findall(Name, entry(Name, _, _), Names),
    sort(Names, Unique),
    length(Names, Count),
    length(Unique, UniqueCount),
    (   Count =:= UniqueCount
    ->  true
    ;   format(user_error, "Entry names must be unique; found ~d rows and ~d unique names.~n",
               [Count, UniqueCount]),
        fail
    ).

wordpress_hazard(Line) :-
    sub_string(Line, Before, 1, _, "<"),
    sub_string(Line, AndAt, 2, _, "&&"),
    AndAt > Before.

wordpress_safe(Html) :-
    split_string(Html, "\n", "", Lines),
    findall(Line, (member(Line, Lines), wordpress_hazard(Line)), Bad),
    (   Bad == []
    ->  true
    ;   format(user_error,
               "~nWORDPRESS HAZARD - angle bracket before logical and, will be mangled:~n", []),
        forall(member(Line, Bad), format(user_error, "  ~s~n", [Line])),
        fail
    ).

file_matches(Relative, Expected) :-
    project_path(Relative, Path),
    read_file_to_string(Path, Actual, [encoding(utf8)]),
    (   Actual == Expected
    ->  true
    ;   format(user_error, "Generated file is stale: ~w~n", [Relative]),
        fail
    ).

write_text(Relative, Text) :-
    project_path(Relative, Path),
    file_directory_name(Path, Directory),
    make_directory_path(Directory),
    setup_call_cleanup(
        open(Path, write, Stream, [encoding(utf8)]),
        format(Stream, "~s", [Text]),
        close(Stream)).

% ---------------------------------------------------------------- commands

build :-
    generated(Csv, Html),
    write_text('data/index.csv', Csv),
    write_text('index.html', Html),
    aggregate_all(count, entry(_,_,_), Count),
    format("wrote data/index.csv and index.html: ~d rows~n", [Count]).

check :-
    generated(Csv, Html),
    file_matches('data/index.csv', Csv),
    file_matches('index.html', Html),
    aggregate_all(count, entry(_,_,_), Count),
    format("generated artefacts are current: ~d rows~n", [Count]).
