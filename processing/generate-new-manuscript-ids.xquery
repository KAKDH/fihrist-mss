xquery version "3.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare option saxon:output "indent=yes";
declare option saxon:output "method=text";

(: Set this variable to one of the institution listed below to update its list of allocated manuscript IDs :)
declare variable $institution as xs:string := '';

(: List of Fihrist member institutions. If adding new ones in the future, create a blank file in the identifiers folder with the same name, ending with .txt :)
declare variable $allinstitutions as xs:string* := (
    'arabic_commentaries_on_the_hippocratic_aphorisms_project',
    'british_library',
    'cambridge_university',
    'eton_college_windsor',
    'jesus_college_cambridge',
    'kings_college_cambridge',
    'new_college_oxford',
    'oxford_university_1',
    'oxford_university_2',
    'queens_college_cambridge',
    'royal_asiatic_society_of_great_britain_and_ireland',
    'school_of_oriental_and_african_studies',
    'st_antonys_college_oxford',
    'university_of_manchester',
    'trinity_college_cambridge',
    'trinity_college_dublin',
    'trinity_hall_cambridge',
    'university_of_birmingham',
    'university_of_st_andrews',
    'wadham_college_oxford',
    'wellcome_trust'
);

declare variable $newline as xs:string := '&#10;';
declare variable $maxallocation as xs:integer external := 1000;

(: Read all existing TEI records, extracting a list of manuscript IDs already used :)
declare variable $inuseids as xs:string* := collection('../collections/?select=*.xml;recurse=yes')/tei:TEI/@xml:id/string();
declare variable $inuseidnums as xs:integer* := for $id in $inuseids return replace($id, '\D', '') cast as xs:integer;

(: Read all the text files containing previously-allocated manuscript IDs for each member institution :)
declare variable $alreadyallocated := map:merge(
    for $inst in $allinstitutions
        let $lines as xs:string* := tokenize(unparsed-text(concat('../identifiers/', $inst, '.txt'), 'utf-8'), '\r*\n')
        let $idnums as xs:integer* := for $line in $lines[matches(., 'manuscript_\d+')] return tokenize($line, '\D+')[2] cast as xs:integer
        return map{$inst : $idnums}
);

(: Join together lists of all in-use and already-pre-allocated manuscript IDs :)
declare variable $alloldids as xs:integer* := ($inuseidnums, (for $inst in $allinstitutions return map:get($alreadyallocated, $inst)));

(: Extract the manuscript IDs already allocated to the institution this  :)

(: Calculate how many new IDs the institution this script is being run to allocate more needs :)
declare variable $preallocatedids as xs:integer* := map:get($alreadyallocated, $institution);
declare variable $unusedids as xs:integer* := for $id in $preallocatedids return if ($id = $inuseidnums) then () else $id;
declare variable $numneededids as xs:integer := $maxallocation - count($unusedids);

(: Create list of new free manuscript IDs :)
declare variable $freeids as xs:integer* := if ($numneededids gt 0) then (for $id in 1 to max($alloldids) + $numneededids return if ($id = $alloldids) then () else $id) else ();

(: Select the subset needed for this institution :)
declare variable $newids as xs:integer* := if ($numneededids gt 0) then (for $n in 1 to $numneededids return $freeids[$n]) else ();

(: Output new list of pre-allocated manuscript IDs to the institution's text file :)
<dummy>{ string-join(('DO NOT EDIT THIS FILE', for $id in ($unusedids, $newids) return concat('manuscript_', $id)), $newline) }{ $newline }</dummy>
