# excursoria

A Prolog reading of the index to *Flora Excursoria Hafniensis*, Salomon Thomas
Nicolai Drejer, Kjøbenhavn 1838.

The index prints 903 names in a single alphabetical sequence:

> 501 Latin + 402 Danish = 903, on 233 of the book's pages

It prints no translations. Some of them are recoverable anyway, because a
plant's Latin name and its Danish name were set on the same page.

## About

The index is the one place in the book where the two languages stand in a
single line. Everywhere else they are kept apart: Latin holds the diagnoses,
Danish the vernacular. In the index they are interfiled and the difference is
suppressed — *Aakande* and *Nymphæa* are two entries, sorted by their first
letters, with nothing to say they are the same plant.

What survives of the relation is the page number. It looks like a locator and
works like a join key: *Nymphæa 189* and *Aakande 189* are the same plant said
twice. The index does not translate; it leaves the translation computable.

This repository does the computation and nothing else. `index.pl` is the
transcription, in printed order and printed orthography, uncorrected.
`flora.pl` is the reading. No fact is edited to make a rule come out.

## Why Prolog

Because the operation is a join, not a lookup, and a join is what Prolog is.

`pair/3` states the relation and lets the engine find its instances. Where a
page carries one name in each language the pairing is forced, and `forced/3`
returns it. Where a page carries three Latin names and two Danish ones, the
same clause returns six candidates and declines to choose — which is the
honest result, and one a table cannot express.

The alphabet gets the same treatment. `sort_key/2` is a hypothesis about how
the index was sorted, written as five rules. `misfiled/2` runs the hypothesis
against the printed sequence and returns everything the rules fail to place.
Eight entries fail. They are not corrected here; they are a list of pages to
open the book at.

## What forced/3 does not mean

Sixty pages carry exactly one name in each language. At least three of the
sixty pairs are false, because the index is incomplete and a page can hold two
survivors of two different pairs:

| page | forced pair | why it is wrong |
|---|---|---|
| 154 | *Andromeda* = Brudelys | Brudelys is *Butomus*, which the index never lists; *Andromeda*'s Danish name is missing too. The page sits exactly where Linnaeus's Enneandria falls between the Octandria of p. 153 and the Decandria of p. 155, so *Butomus* belongs there and *Andromeda* begins the next class. |
| 64 | *Ruppia* = Vandax | Vandax is *Potamogeton*, printed on p. 65, which carries no Danish name at all. |
| 282 | *Zannichellia* = Vandstjerne | Vandstjerne is *Callitriche*, printed on p. 281, which carries three Latin names to two Danish. |

Two of the three are visible from the data alone, because the neighbouring
page is unbalanced the other way. The first is not: p. 153 is balanced and
p. 154 looks like any other forced pair. `forced/3` is therefore a proposal,
and the code says so where it is defined rather than in a footnote.

## The alphabet

Five rules recover the printed sequence, all of them historical rather than
obvious:

1. Word-initial **J** files under **I** — *Jacobsurt, Impatiens, Jordbær, Iris*
2. **J** after a vowel likewise — *Majanthemum* before *Maiblomst*
3. **J** after a consonant is its own letter, after I — *Hippuris*, then *Hjertelæbe*
4. **Æ** in a Latin name is the ligature **AE** — *Chærophyllum* before *Chamænerium*
5. **Æ** in a Danish name is late, and **Ö** later — *Bynke, Bægerbrægne, Bög*

Rules 4 and 5 contradict each other, and the index applies both: *Ægopodium*
files under A, *Ært* files after Z. The compositor sorted Latin as Latin and
Danish as Danish, in one sequence, without saying so. Rule 2 rests on the
single pair that requires it; the other four are supported many times over.

They meet exactly once. *Jacobæa* and *Jacobsurt* are the Latin and Danish
names of the same plant, printed on the same page, adjacent in the index — and
they are the one place where the two alphabets give opposite answers. The only
pair the index sets side by side is the pair its own rules cannot order.

## The eight

`displaced/3` selects one representative culprit for each adjacent inversion,
using the larger absolute shift (and the first printed entry on a tie). Eight
are selected; none moves more than three places. `shifted/3` is the mechanical
counterpart: it returns all 17 entries whose absolute position changes, including
nine correctly filed neighbours displaced only because one of the eight passes
them.

| printed | should follow | shift |
|---|---|---|
| Arve 81 | Arundo | +2 |
| Carlina 258 | Carex | +2 |
| Corylus 304 | Corydalis | +2 |
| Corvisartia 268 | Cornus | −3 |
| Jacobsurt 266 | Jacobæa | +1 |
| Paris 153 | Parietaria | +1 |
| Pteris 318 | Psyllophora | +1 |
| Typha 284 | Tyltebær | +1 |

Jacobsurt/Jacobæa is not an error. Four of the remaining seven are plain
transpositions of neighbours, which is equally the signature of a compositor
and of a transcription: only the book distinguishes them.

A misprint can also hide inside a correct sort, and `misfiled/2` is
structurally blind to it. On p. 214 the index prints *Lathræa*, *Orobanche*,
Skjælrod and **Gyclqvæler**. Skjælrod is *Lathræa*, so Gyclqvæler is
*Orobanche*, whose Danish name is **Gyvelkvæler** — but as printed the entry
files legally, between Guulax and Gyldenriis, and no rule is violated.

## Where the index loses something

Of 233 pages, 129 name as many plants in one language as the other. On the
rest something is missing. Counting the excess language by language, **at
least 114** of the 501 Latin names cannot have a Danish counterpart anywhere
in the index, and at least 15 Danish names cannot have a Latin one. Those are
floors, not estimates: they are what the page balances force.

The looser figure is worth stating separately, because it is easy to misread.
`unpaired/3` returns 257 Latin names — every Latin name sitting on a page
where Latin outnumbers Danish. That is a list of candidates, not a count of
losses: on a page with three Latin names and two Danish, all three are
candidates and only one is certainly unpaired.

Twenty-nine names are wholly orphaned — no name of the other language anywhere
on their page. Twenty-five are Latin and four are Danish, and Danish is the
scarcer half, which makes those four the interesting ones:

- **Skræppe 110** — *Rumex* appears nowhere in the index
- **Engelsöd 314** — nor does *Polypodium*
- **Kogleax 19** — *Scirpus* is on 20
- **Valmue 168** — *Papaver* is on 188

Four more Danish names are unpaired on their page while the obvious Latin
counterpart is unpaired elsewhere, and in every case the two page numbers
differ by a single digit:

| Danish | Latin | reading |
|---|---|---|
| Steenurt **264** | *Sedum* **164** | Sedum's page fits Linnaeus's Decandria exactly; 264 is Compositae. The Danish entry carries the wrong hundreds digit. |
| Valmue **168** | *Papaver* **188** | 6 for 8 |
| Brandbæger **265** | *Senecio* **269** | 5 for 9 |
| Mælkurt **231** | *Polygala* **234** | 1 for 4 |

Single-digit substitutions are what an optical transcription produces. They
are recorded here as questions for the page, not as corrections to it.

## The weakest link

Every figure above that names a language rests on an editorial layer, and it
should be read as such.

The index does not mark its entries `la` or `da`. The book does not either.
The tagging in `index.pl` was made by an orthographic heuristic and corrected
by hand; it is a reading of the names, not a transcription of anything printed.
So *903 names on 233 pages* is a fact about the index, and *501 Latin, 402
Danish* is a claim about the names — and the join, the census and the balance
counts are all downstream of the second.

The entries most likely to be wrong are the Danish naturalisations of Latin,
where the two languages converge on nearly the same string:

*Kalaminthe* / Calamintha · *Kokleare* / Cochlearia · *Karline* / Carlina ·
*Kalmus* / Acorus · *Perikon* · *Sellerie* · *Dodder* · *Iris* · *Paris* ·
*Simmer* · *River* · *Avl* · *Norel* · *Busmekker* · *Mysike*

and *Anemone*, which is the same word in both languages and is currently
tagged `la` because something had to be chosen. An independent audit against a
botanical authority is the first thing this repository needs; it would move
some of the numbers above, and the point of stating them plainly is that it
would be obvious which.

One consequence of rule 4 is worth spelling out, since the census tables can
mislead. Of the 25 alphabetical sections, Æ and Ö hold Danish names only — but
Æ occurs word-initially in Latin too, in *Ægopodium* and *Æthusa*, which file
under A. The section is Danish-only; the letter is not.

## Usage

Interactive analysis and builds require SWI-Prolog. The complete developer check also uses Node.js, with no package dependencies.

```
swipl flora.pl
```

Prints a census, then leaves the toplevel open:

```
?- forced(Latin, Danish, Page).
?- misfiled(A, B).
?- displaced(Name, Printed, Sorted).
?- shifted(Name, Printed, Sorted).
?- minimum_unmatched(Language, Count).
?- orphan(Name, Page, da).
?- balance(Page, Diff).
?- stray(Danish, Page, Latin, Near).
```

| file | what it is |
|---|---|
| `index.pl` | 903 `entry(Name, Page, Lang).` facts. The transcription, uncorrected. |
| `flora.pl` | The reading: the join, the alphabet, the census. |
| `data/index.csv` | The same 903 rows as CSV, for reading without Prolog. Generated. |
| `index.html` | The searchable index as it runs on bergholt.net/flora. Self-contained, no dependencies, no requests. The 903 entries are served as markup, not as a data payload, so the block reads as an index with scripts disabled and is legible to anything that does not run them. |
| `build.pl` | Writes the CSV plus the generated summary and list inside `index.html`; also verifies that derived files are current. |
| `tests.pl` | Regression tests for the published counts, page analysis, collation and generated artefacts. |
| `tools/check-html.mjs` | Dependency-free structural check for the CSV, HTML and embedded JavaScript. |
| `Makefile` | `build`, `check` and `test` entry points. |
| `.github/workflows/test.yml` | Runs the Prolog and HTML regression checks on pushes and pull requests. |

`index.pl` is the only data source. The HTML summary and list are bounded by
explicit generated markers and are both rewritten by the build. Latin is set
in italic by botanical convention, so `<i>` marks the language and the script
reads it back off the typography; the section letter comes from the generated
headings. The letter rail is then created from those sections at runtime, so it
cannot drift away from the collation in `flora.pl`.

```
make build
make check
make test
```

The direct Prolog commands are equivalent:

```
swipl -q -g build -t halt build.pl
swipl -q -g check -t halt build.pl
swipl -q -s tests.pl -g run_tests -t halt
```

The build resolves paths from `build.pl`, not from the shell's working
directory. It assembles and validates both outputs before writing them, checks
entry structure and name uniqueness, escapes CSV and HTML text, and refuses to
produce a block that WordPress would break. The separate Node check parses the
embedded JavaScript and verifies that the CSV and HTML still mirror all 903
facts exactly; it has no package dependencies.

## The numbers

- **903** names — 501 Latin, 402 Danish, on the editorial tagging described above
- **233** distinct pages, the lowest 1 and the highest 320
- **26** initial letters, falling into **25** sections: no W, no Y, I and J
  interfiled, Æ and Ö at the end. C, U, X and Z open Latin names only; the
  Æ and Ö sections hold Danish only
- **129** balanced pages, **60** forcing a pair, at least **3** of those false
- **114** Latin names that cannot be paired, as a floor
- **29** wholly orphaned names — 25 Latin, 4 Danish
- **8** representative displaced entries across eight adjacent inversions; **17** positions change in a full re-sort

The counts follow from explicit predicates. `displaced/3` adds one stated
diagnostic convention — larger absolute shift, first printed on a tie — so the
eight-row table does not silently conflate the 17 positions changed by a full
re-sort. The language assignment remains the one layer here that is not the
book's.

There is no 72 in this data, and none has been arranged. The companion
repository [triptych](https://github.com/bergholt/triptych) has one, exactly,
because its 72 is constructed: three nouns, three verbs, four adverbs, two
orders. These numbers are ragged because they are found. The difference
between a system that generates its own inventory and an artefact that
survives with its inventory incomplete is the whole distance between the two
repositories.

## Further reading

[bergholt.net/flora](https://bergholt.net/flora) — the essay, and the index
made searchable. `index.html` here is the block that page runs.

Drejer, Salomon Thomas Nicolai. *Flora Excursoria Hafniensis*. Sumtibus
Librariæ Schubothianæ, Kjøbenhavn, 1838. LXV + 339 pp., with an unnumbered
errata leaf. Transcribed here from a first edition.

## License

MIT License. Feel free to use for your own projects.

***

Copenhagen, 2026
