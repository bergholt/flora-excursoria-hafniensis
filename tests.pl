:- encoding(utf8).

% tests.pl — regression tests for the documented figures: the counts, the
% false forced pairs, the five collation rules, the sections, the escaping,
% and the generated artefacts.
%
%   make test
%   swipl -q -s tests.pl -g run_tests -t halt

:- ensure_loaded(build).

:- begin_tests(excursoria).

expected_displaced([
    'Arve'-2,
    'Carlina'-2,
    'Corylus'-2,
    'Corvisartia'-(-3),
    'Jacobsurt'-1,
    'Paris'-1,
    'Pteris'-1,
    'Typha'-1
]).

test(source_counts) :-
    aggregate_all(count, entry(_,_,_), Total),
    aggregate_all(count, entry(_,_,la), Latin),
    aggregate_all(count, entry(_,_,da), Danish),
    setof(Page, Name^Lang^entry(Name, Page, Lang), Pages),
    length(Pages, PageCount),
    assertion(Total =:= 903),
    assertion(Latin =:= 501),
    assertion(Danish =:= 402),
    assertion(PageCount =:= 233).

test(page_analysis) :-
    aggregate_all(count, balanced(_), Balanced),
    aggregate_all(count, forced(_,_,_), Forced),
    aggregate_all(count, unpaired(_,_,la), UnpairedLatin),
    aggregate_all(count, unpaired(_,_,da), UnpairedDanish),
    aggregate_all(count, orphan(_,_,la), OrphanLatin),
    aggregate_all(count, orphan(_,_,da), OrphanDanish),
    minimum_unmatched(la, MinimumLatin),
    minimum_unmatched(da, MinimumDanish),
    assertion(Balanced =:= 129),
    assertion(Forced =:= 60),
    assertion(UnpairedLatin =:= 257),
    assertion(UnpairedDanish =:= 32),
    assertion(OrphanLatin =:= 25),
    assertion(OrphanDanish =:= 4),
    assertion(MinimumLatin =:= 114),
    assertion(MinimumDanish =:= 15),
    assertion(stray('Kogleax', 19, 'Scirpus', 20)).

% The three pages the README shows forcing a false pair, and why only two
% are visible from the data: p. 153 is balanced, pp. 65 and 281 are not.
test(forced_is_fallible) :-
    assertion(forced('Andromeda', 'Brudelys', 154)),
    assertion(forced('Ruppia', 'Vandax', 64)),
    assertion(forced('Zannichellia', 'Vandstjerne', 282)),
    assertion(balance(153, 0)),
    assertion(balance(65, 1)),
    assertion(balance(281, 1)).

test(alphabet_analysis) :-
    aggregate_all(count, misfiled(_,_), Inversions),
    aggregate_all(count, shifted(_,_,_), Shifted),
    findall(Name-Shift,
            ( displaced(Name, Printed, Sorted), Shift is Sorted - Printed ),
            Displaced),
    expected_displaced(Expected),
    assertion(Inversions =:= 8),
    assertion(Shifted =:= 17),
    assertion(Displaced == Expected).

% One example per collation rule, as explicit sort keys.
test(collation_rules) :-
    sort_key('Jordbær', da, R1),       % 1. word-initial J files under I
    sort_key('Majanthemum', la, R2a),  % 2. J after a vowel likewise
    sort_key('Maiblomst', da, R2b),
    sort_key('Hippuris', la, R3a),     % 3. J after a consonant: own letter, after I
    sort_key('Hjertelæbe', da, R3b),
    sort_key('Ægopodium', la, R4),     % 4. Æ in a Latin name is AE
    sort_key('Ært', da, R5),           % 5. Æ in a Danish name is late
    assertion(R1 == 'iordb{r'),
    assertion(R2a == maianthemum),
    assertion(R2a @< R2b),
    assertion(R3b == 'hi~ertel{be'),
    assertion(R3a @< R3b),
    assertion(R4 == aegopodium),
    assertion(R5 == '{rt').

% Sections are read off the keys, and the '{' '|' encoding has one home.
test(sections) :-
    assertion(section('Ægopodium', a)),
    assertion(section('Ært', æ)),
    assertion(section('Jordbær', i)),
    assertion(key_section('{', æ)),
    assertion(key_section('|', ö)).

% The escaping the artefacts never exercise: no name in the index contains
% a comma, a quote or an angle bracket, so these paths are pinned here.
test(escaping) :-
    csv_field('Vand,ax', Comma),
    csv_field('Vand"ax', Quote),
    csv_field('Arundo', Plain),
    html_text('A&B<C>', Html),
    assertion(Comma == "\"Vand,ax\""),
    assertion(Quote == "\"Vand\"\"ax\""),
    assertion(Plain == "Arundo"),
    assertion(Html == "A&amp;B&lt;C&gt;").

% The marked spellings file legally as printed. A correction that moved one
% would surface in the inversion counts above before it surfaced here.
test(marked_misprints_file_legally) :-
    forall(member(Name, ['Gyclqvæler', 'Phragimtes', 'Epigogium']),
           assertion(\+ (misfiled(A, B), (A == Name ; B == Name)))).

test(generated_artefacts_are_current) :-
    check.

:- end_tests(excursoria).
