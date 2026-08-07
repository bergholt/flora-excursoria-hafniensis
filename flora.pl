:- encoding(utf8).

% flora.pl — a reading of the index to 'Flora Excursoria Hafniensis' (1838).
%
% The index prints Latin and Danish names in one alphabetical sequence and
% gives no translations. The pairing is still partly recoverable, because a
% plant's Latin name and its Danish name were set on the same page: the page
% number is not only a locator but a join key.
%
% Two things follow, and only two. The join, which is defeasible and says so.
% And a statement of the alphabet the index was sorted by, which can be tested
% against the printed order and fails on eight entries out of 903, one of
% them by design.
%
%   swipl flora.pl
%   ?- census.
%   ?- forced(Latin, Danish, Page).
%   ?- misfiled(A, B).

:- ensure_loaded(index).

:- use_module(library(aggregate), [aggregate_all/3]).
:- use_module(library(apply),     [maplist/3]).
:- use_module(library(lists),     [member/2, memberchk/2, nextto/3, nth0/3]).
:- use_module(library(pairs),     [pairs_values/2]).

% ---------------------------------------------------------------- lookup

page(Name, Page)    :- entry(Name, Page, _).
on_page(Page, Name) :- entry(Name, Page, _).
latin(Name)         :- entry(Name, _, la).
danish(Name)        :- entry(Name, _, da).

other(la, da).
other(da, la).

count_on(Page, Lang, N) :-
    aggregate_all(count, entry(_, Page, Lang), N).

% -------------------------------------------------------------- the join

% Every Latin/Danish name sharing a page is a candidate translation.
pair(Latin, Danish, Page) :-
    entry(Latin,  Page, la),
    entry(Danish, Page, da).

% A page with exactly one name in each language forces its pair — but only
% if the index is complete, and it is not. A page can equally hold two
% survivors of two different pairs whose partners were never indexed:
%
%   p. 154  Andromeda / Brudelys     Brudelys is Butomus, absent from the
%                                    index; Andromeda's Danish name is absent
%   p.  64  Ruppia / Vandax          Vandax is Potamogeton, printed on p. 65
%   p. 282  Zannichellia/Vandstjerne Vandstjerne is Callitriche, on p. 281
%
% So forced/3 is a proposal to be checked against the book, not a result.
% Sixty pages qualify; at least three of the sixty are wrong.
forced(Latin, Danish, Page) :-
    pair(Latin, Danish, Page),
    count_on(Page, la, 1),
    count_on(Page, da, 1).

% --------------------------------------------------------- what is missing

% A page is balanced when it names as many plants in one language as in the
% other. 129 of 233 are. The rest are where the index loses something.
balance(Page, Diff) :-
    setof(P, N^L^entry(N, P, L), Pages),
    member(Page, Pages),
    count_on(Page, la, A),
    count_on(Page, da, B),
    Diff is A - B.

balanced(Page) :- balance(Page, 0).

% The minimum number of names on a page that cannot have a counterpart in the
% other language. Unlike unpaired/3, which returns every candidate on an
% unbalanced page, deficit/3 counts only what the page balance proves missing.
deficit(Page, la, N) :-
    balance(Page, Diff),
    Diff > 0,
    N is Diff.
deficit(Page, da, N) :-
    balance(Page, Diff),
    Diff < 0,
    N is -Diff.

minimum_unmatched(Lang, N) :-
    member(Lang, [la, da]),
    aggregate_all(sum(D), deficit(_, Lang, D), N).

% A name whose own language outnumbers the other on its page: somewhere on
% that page a counterpart is missing, and this name is a candidate for it.
unpaired(Name, Page, Lang) :-
    entry(Name, Page, Lang),
    other(Lang, Counterpart),
    count_on(Page, Lang, A),
    count_on(Page, Counterpart, B),
    A > B.

% The strong case: no name of the other language on the page at all.
orphan(Name, Page, Lang) :-
    entry(Name, Page, Lang),
    other(Lang, Counterpart),
    count_on(Page, Counterpart, 0).

% An unpaired Danish name one page from an unpaired Latin one. Danish names
% are the scarcer half, so anchoring here keeps the list short enough to act
% on. Either the two straddle a page break, or a digit is wrong. Both are
% reasons to open the book; neither is a correction.
stray(Danish, Page, Latin, Near) :-
    unpaired(Danish, Page, da),
    ( Near is Page - 1 ; Near is Page + 1 ),
    unpaired(Latin, Near, la).

% ---------------------------------------------------------- the alphabet
%
% Five rules, each of them historical rather than obvious:
%
%   1. word-initial J files under I     Jacobsurt, Impatiens, Jordbær, Iris
%   2. J after a vowel also             Majanthemum before Maiblomst
%   3. J after a consonant is its own letter, after I   Hippuris, Hjertelæbe
%   4. Æ in a Latin name is AE          Chærophyllum before Chamænerium
%   5. Æ in a Danish name is late, Ö later   Bynke, Bægerbrægne, Bög
%
% Rules 4 and 5 contradict each other and the index applies both, so
% Ægopodium files under A and Ært files after Z. Rule 2 rests on the single
% pair that requires it; the rest are supported many times over.
%
% There is no rule for Å, because the index contains none: 1838 spells the
% sound Aa, which files under A. The alphabet states nothing the printed
% order cannot test.

vowel(C) :- memberchk(C, [a,e,i,o,u,y,æ,ö,å]).

% downcase_atom/2 is locale-dependent outside ASCII — under the C locale it
% leaves Æ, Ö and Å as they are — so the three are spelt out.
lower('Æ', æ) :- !.
lower('Ö', ö) :- !.
lower('Å', å) :- !.
lower(C, L)  :- downcase_atom(C, L).

collate(j, _,  none, i)    :- !.
collate(j, _,  Prev, i)    :- vowel(Prev), !.
collate(j, _,  _,    'i~') :- !.
collate(æ, la, _,    ae)   :- !.
collate(æ, da, _,    '{')  :- !.
collate(ö, _,  _,    '|')  :- !.
collate(C, _,  _,    C).

% Danish æ and ö are keyed as '{' and '|', the two codepoints after z, so
% that they sort last. These facts are that encoding's one home; build.pl's
% section/2 maps first characters of keys back to section letters.
key_section('{', æ).
key_section('|', ö).

fold([],     _, _,    []).
fold([C|Cs], L, Prev, [K|Ks]) :-
    collate(C, L, Prev, K),
    fold(Cs, L, C, Ks).

sort_key(Name, Lang, Key) :-
    atom_chars(Name, Chars),
    maplist(lower, Chars, Lowered),
    fold(Lowered, Lang, none, Keys),
    atomic_list_concat(Keys, Key).

% Convenient for querying the transcription. sort_key/3 is the unambiguous
% form to use for names not already present in index.pl.
sort_key(Name, Key) :-
    entry(Name, _, Lang),
    sort_key(Name, Lang, Key).

printed(Names) :- findall(N, entry(N, _, _), Names).

alphabetical(Names) :-
    printed(Printed),
    findall(K-N, (member(N, Printed), sort_key(N, K)), Keyed),
    keysort(Keyed, Ordered),
    pairs_values(Ordered, Names).

% Two adjacent entries the alphabet above would have set the other way round.
% Eight. Four are plain transpositions of neighbours; Jacobsurt/Jacobæa is not
% an error at all but the one place where rules 4 and 5 meet, in the Danish
% and Latin names for the same plant, on the same page. Whether the remaining
% seven are the compositor's or the transcription's, the photographs decide.
misfiled(A, B) :-
    printed(Names),
    nextto(A, B, Names),
    sort_key(A, KA),
    sort_key(B, KB),
    KA @> KB.

% Every entry whose absolute position changes when the list is sorted. There
% are 17: the eight local disturbances below, plus nine neighbours that move
% only because an out-of-place entry passes them.
shifted(Name, Printed, Sorted) :-
    position(Name, Printed, Sorted),
    Printed =\= Sorted.

position(Name, Printed, Sorted) :-
    printed(P), alphabetical(S),
    nth0(Printed, P, Name),
    nth0(Sorted,  S, Name).

% One representative culprit for each adjacent inversion. Compare the two
% names in the inversion by absolute displacement and choose the larger one;
% on a tie choose the first printed. This is the eight-row table discussed in
% the README, rather than the 17 mechanically shifted positions above.
displaced(Name, Printed, Sorted) :-
    misfiled(A, B),
    position(A, PA, SA),
    position(B, PB, SB),
    DA is abs(SA - PA),
    DB is abs(SB - PB),
    (   DA >= DB
    ->  Name = A, Printed = PA, Sorted = SA
    ;   Name = B, Printed = PB, Sorted = SB
    ).

% -------------------------------------------------------------- census

census :-
    aggregate_all(count, entry(_,_,_),  Total),
    aggregate_all(count, entry(_,_,la), Lat),
    aggregate_all(count, entry(_,_,da), Dan),
    setof(P, N^L^entry(N,P,L), Pages),  length(Pages, NP),
    aggregate_all(count, balanced(_),       Bal),
    aggregate_all(count, forced(_,_,_),     Forced),
    aggregate_all(count, unpaired(_,_,la),  UL),
    aggregate_all(count, unpaired(_,_,da),  UD),
    minimum_unmatched(la, MinL),
    minimum_unmatched(da, MinD),
    aggregate_all(count, orphan(_,_,_),      Orph),
    aggregate_all(count, orphan(_,_,la),     OrphL),
    aggregate_all(count, orphan(_,_,da),     OrphD),
    aggregate_all(count, misfiled(_,_),      Mis),
    aggregate_all(count, shifted(_,_,_),     Shifted),
    aggregate_all(count, displaced(_,_,_),   Displaced),
    row("entries",                           Total),
    row("  Latin",                           Lat),
    row("  Danish",                          Dan),
    row("pages cited",                       NP),
    row("  balanced",                        Bal),
    row("  forcing a pair",                  Forced),
    row("candidate unpaired Latin names",    UL),
    row("candidate unpaired Danish names",   UD),
    row("minimum unmatched Latin names",     MinL),
    row("minimum unmatched Danish names",    MinD),
    row("wholly orphaned names",             Orph),
    row("  Latin",                           OrphL),
    row("  Danish",                          OrphD),
    row("adjacent inversions",               Mis),
    row("representative displaced entries", Displaced),
    row("all positions shifted",             Shifted).

row(Label, N) :- format("~s~t~42|~d~n", [Label, N]).

% Print the census when flora.pl is the file on the command line, and stay
% silent when another file loads it. Either way the toplevel is left open:
% initialization/1 runs after loading and does not halt, unlike the main
% variant, which would end the session the census was meant to open.
:- (   current_prolog_flag(associated_file, File),
       prolog_load_context(source, File)
   ->  initialization(census)
   ;   true
   ).
