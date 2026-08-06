# excursoria — Flora Excursoria Hafniensis (1838) index, transcribed and analysed in Prolog
 
Full transcription of the *Index Nominum* to **Salomon Thomas Nicolai Drejer,
*Flora Excursoria Hafniensis*, Kjøbenhavn 1838**, with a Prolog analysis of it.
 
The index lists 903 plant names — 501 Latin, 402 Danish — interfiled in one
alphabetical sequence across 233 pages. It prints no translations. Because a
plant's Latin and its Danish name were set on the same page, the page number
works as a join key, and part of the Latin–Danish pairing is recoverable by
computation.
 
**Searchable index:** [bergholt.net/flora](https://bergholt.net/flora)
 
## Figures
 
| | |
|---|---|
| Entries | 903 |
| Latin | 501 |
| Danish | 402 |
| Pages cited | 233 (lowest 1, highest 320) |
| Initial letters / sections | 26 / 25 |
| Balanced pages | 129 |
| Pages forcing a pair | 60, at least 3 of them false |
| Latin names certainly unpaired (floor) | 114 |
| Danish names certainly unpaired (floor) | 15 |
| Wholly orphaned names | 29 — 25 Latin, 4 Danish |
| Collation failures | 8 inversions, 17 positions changed in a full re-sort |
 
The 25 sections: no W, no Y, I and J interfiled, Æ and Ö at the end. C, U, X
and Z open Latin names only; the Æ and Ö sections hold Danish only.
 
## Files
 
| file | contents |
|---|---|
| `index.pl` | 903 `entry(Name, Page, Lang).` facts. The transcription, in printed order and printed orthography, uncorrected. The only data source. |
| `flora.pl` | The analysis: the join, the collation, the census. |
| `data/index.csv` | The same 903 rows as CSV. Generated. |
| `index.html` | Self-contained searchable index; the block used on bergholt.net/flora. No dependencies, no network requests. Entries are served as markup, so the list is readable without JavaScript. |
| `build.pl` | Writes the CSV and the generated regions of `index.html`; verifies derived files are current. |
| `tests.pl` | Regression tests for the counts, page analysis, collation and generated artefacts. |
| `tools/check-html.mjs` | Dependency-free structural check of the CSV, HTML and embedded JavaScript. |
| `Makefile` | `build`, `check`, `test`. |
| `.github/workflows/test.yml` | Runs the checks on push and pull request. |
 
Latin is set in italic by botanical convention, so `<i>` carries the language
in `index.html` and the script reads it back off the typography. Section
letters come from the generated headings, and the letter rail is built from
those sections at runtime, so it cannot drift from the collation in `flora.pl`.
 
## Usage
 
Requires SWI-Prolog. The full developer check also uses Node.js (no packages).
 
```
swipl flora.pl
```
 
Prints a census, then leaves the toplevel open:
 
```prolog
?- forced(Latin, Danish, Page).      % pages carrying exactly one name of each
?- pair(Latin, Danish, Page).        % all candidate pairings
?- unpaired(Name, Page, Lang).       % candidates for a missing counterpart
?- minimum_unmatched(Lang, Count).   % the floor the page balances force
?- orphan(Name, Page, da).           % no name of the other language on the page
?- balance(Page, Diff).              % Latin count minus Danish count
?- stray(Danish, Page, Latin, Near).
?- misfiled(A, B).                   % adjacent pair the collation orders the other way
?- displaced(Name, Printed, Sorted). % one representative per inversion
?- shifted(Name, Printed, Sorted).   % every position that changes in a re-sort
```
 
Build and test:
 
```
make build
make check
make test
```
 
Equivalent direct commands:
 
```
swipl -q -g build -t halt build.pl
swipl -q -g check -t halt build.pl
swipl -q -s tests.pl -g run_tests -t halt
```
 
The build resolves paths from `build.pl`, not the shell's working directory.
It assembles and validates both outputs before writing, checks entry structure
and name uniqueness, escapes CSV and HTML text, and refuses to emit a block
that WordPress would break. The Node check parses the embedded JavaScript and
confirms the CSV and HTML still mirror all 903 facts.
 
## The join
 
`pair/3` returns every Latin/Danish name sharing a page. Where a page carries
one name in each language, `forced/3` returns the pairing.
 
`forced/3` is a proposal, not a result. The index is incomplete, so a page can
hold two survivors of two different pairs. Sixty pages qualify; at least three
are wrong:
 
| page | forced pair | why it fails |
|---|---|---|
| 154 | *Andromeda* = Brudelys | Brudelys is *Butomus*, absent from the index; *Andromeda*'s Danish name is also absent. The page falls where Linnaeus's Enneandria sits, between the Octandria of p. 153 and the Decandria of p. 155, so *Butomus* belongs there and *Andromeda* begins the next class. |
| 64 | *Ruppia* = Vandax | Vandax is *Potamogeton*, printed on p. 65, which carries no Danish name. |
| 282 | *Zannichellia* = Vandstjerne | Vandstjerne is *Callitriche*, printed on p. 281, which carries three Latin names to two Danish. |
 
Two are visible from the data, because the neighbouring page is unbalanced the
other way. The first is not: p. 153 is balanced and p. 154 looks like any other
forced pair.
 
## The collation
 
Five rules recover the printed sequence:
 
1. Word-initial **J** files under **I** — *Jacobsurt, Impatiens, Jordbær, Iris*
2. **J** after a vowel likewise — *Majanthemum* before *Maiblomst*
3. **J** after a consonant is its own letter, after I — *Hippuris*, then *Hjertelæbe*
4. **Æ** in a Latin name is the ligature **AE** — *Chærophyllum* before *Chamænerium*
5. **Æ** in a Danish name is late, **Ö** later — *Bynke, Bægerbrægne, Bög*
Rules 4 and 5 conflict and the index applies both: *Ægopodium* files under A,
*Ært* after Z. Latin was sorted as Latin and Danish as Danish, in one sequence,
without notice. Rule 2 rests on the single pair that requires it; the other
four are supported repeatedly.
 
The two alphabets meet once. *Jacobæa* and *Jacobsurt* are the Latin and Danish
names of one plant, on one page, adjacent in the index, and are the only place
where the rules give opposite answers.
 
### Collation failures
 
`displaced/3` returns one representative entry per adjacent inversion, chosen
by larger absolute shift, first printed on a tie. Eight are returned; none
moves more than three places. `shifted/3` is the mechanical counterpart and
returns all 17 entries whose position changes, including nine correctly filed
neighbours passed by one of the eight.
 
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
 
Jacobsurt/Jacobæa is not an error but rules 4 and 5 meeting. Four of the
remaining seven are transpositions of neighbours, which is equally the
signature of a compositor and of a transcription; only the book distinguishes
them.
 
A misprint can also hide inside a correct sort. On p. 214 the index prints
*Lathræa*, *Orobanche*, Skjælrod and **Gyclqvæler**. Skjælrod is *Lathræa*, so
Gyclqvæler is *Orobanche*, whose Danish name is **Gyvelkvæler** — but as
printed it files legally between Guulax and Gyldenriis, and `misfiled/2` cannot
see it.
 
## Missing counterparts
 
Of 233 pages, 129 name as many plants in one language as the other. Counting
the excess language by language, at least 114 of the 501 Latin names can have
no Danish counterpart anywhere in the index, and at least 15 Danish names can
have no Latin one. These are floors forced by the page balances, not estimates.
 
`unpaired/3` returns 257 Latin names — every Latin name on a page where Latin
outnumbers Danish. That is a candidate list, not a count of losses: on a page
with three Latin names and two Danish, all three are candidates and only one is
certainly unpaired.
 
Twenty-nine names are wholly orphaned, with no name of the other language
anywhere on their page. Twenty-five are Latin, four Danish:
 
- **Skræppe 110** — *Rumex* appears nowhere in the index
- **Engelsöd 314** — nor does *Polypodium*
- **Kogleax 19** — *Scirpus* is on 20
- **Valmue 168** — *Papaver* is on 188
Four further Danish names are unpaired on their page while the obvious Latin
counterpart is unpaired elsewhere, the two page numbers differing by one digit:
 
| Danish | Latin | reading |
|---|---|---|
| Steenurt **264** | *Sedum* **164** | Sedum's page fits Linnaeus's Decandria; 264 is Compositae. Wrong hundreds digit. |
| Valmue **168** | *Papaver* **188** | 6 for 8 |
| Brandbæger **265** | *Senecio* **269** | 5 for 9 |
| Mælkurt **231** | *Polygala* **234** | 1 for 4 |
 
Single-digit substitutions are what optical transcription produces. They are
recorded as questions for the page, not corrections to it.
 
## Limitations
 
Every figure that names a language depends on an editorial layer. The index
does not tag its entries `la` or `da`, and neither does the book. The tagging
in `index.pl` was produced by an orthographic heuristic and corrected by hand.
It is a reading of the names, not a transcription of anything printed.
 
So *903 names on 233 pages* is a fact about the index; *501 Latin, 402 Danish*
is a claim about the names. The join, the census and the balance counts are all
downstream of the second.
 
The entries most likely to be mistagged are Danish naturalisations of Latin,
where the two languages converge on nearly the same string:
 
*Kalaminthe* / Calamintha · *Kokleare* / Cochlearia · *Karline* / Carlina ·
*Kalmus* / Acorus · *Perikon* · *Sellerie* · *Dodder* · *Iris* · *Paris* ·
*Simmer* · *River* · *Avl* · *Norel* · *Busmekker* · *Mysike*
 
and *Anemone*, identical in both languages and currently tagged `la` because a
choice was required. An independent audit against a botanical authority is the
first thing this repository needs.
 
One consequence of rule 4: of the 25 sections, Æ and Ö hold Danish names only,
but Æ occurs word-initially in Latin too, in *Ægopodium* and *Æthusa*, which
file under A. The section is Danish-only; the letter is not.
 
## Citation
 
See `CITATION.cff`.
 
Drejer, Salomon Thomas Nicolai. *Flora Excursoria Hafniensis*. Sumtibus
Librariæ Schubothianæ, Kjøbenhavn, 1838. LXV + 339 pp., with an unnumbered
errata leaf. Transcribed here from a first edition.
 
## Related
 
- [bergholt.net/flora](https://bergholt.net/flora) — the essay, and the index made searchable
- [triptych](https://github.com/bergholt/triptych) — companion repository

## License
 
MIT.
 
***
 
Kasper Bergholt, Copenhagen, 2026
