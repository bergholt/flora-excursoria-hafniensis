:- encoding(utf8).

:- begin_tests(excursoria).

:- ensure_loaded(build).

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
    aggregate_all(count, orphan(_,_,la), OrphanLatin),
    aggregate_all(count, orphan(_,_,da), OrphanDanish),
    minimum_unmatched(la, MinimumLatin),
    minimum_unmatched(da, MinimumDanish),
    assertion(Balanced =:= 129),
    assertion(Forced =:= 60),
    assertion(OrphanLatin =:= 25),
    assertion(OrphanDanish =:= 4),
    assertion(MinimumLatin =:= 114),
    assertion(MinimumDanish =:= 15).

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

test(explicit_sort_key) :-
    sort_key('Ægopodium', la, LatinKey),
    sort_key('Ært', da, DanishKey),
    assertion(LatinKey == aegopodium),
    assertion(DanishKey == '{rt').

test(generated_artefacts_are_current) :-
    check.

:- end_tests(excursoria).
