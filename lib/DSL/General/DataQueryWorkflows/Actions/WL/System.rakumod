=begin comment
#==============================================================================
#
#   Data Query Workflows WL-System actions in Raku (Perl 6)
#   Copyright (C) 2020  Anton Antonov
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   Written by Anton Antonov,
#   ʇǝu˙oǝʇsod@ǝqnɔuouoʇuɐ,
#   Windermere, Florida, USA.
#
#==============================================================================
#
#   For more details about Raku (Perl6) see https://raku.org/ .
#
#==============================================================================
=end comment

use v6;
use DSL::General::DataQueryWorkflows::Grammar;
use DSL::Shared::Actions::WL::PredicateSpecification;
use DSL::Shared::Actions::English::WL::PipelineCommand;

unit module DSL::General::DataQueryWorkflows::Actions::WL::System;

class DSL::General::DataQueryWorkflows::Actions::WL::System
        is DSL::Shared::Actions::WL::PredicateSpecification
        is DSL::Shared::Actions::English::WL::PipelineCommand {

    has Str $.name = 'DSL-English-DataQueryWorkflows-WL-System';

    # Top
    method TOP($/) { make $/.values[0].made; }

    # workflow-command-list
    method workflow-commands-list($/) { make $/.values>>.made.join(";\n"); }

    # workflow-command
    method workflow-command($/) { make $/.values[0].made; }

    # General
    method variable-names-list($/) { make $<variable-name>>>.made; }
    method quoted-variable-names-list($/) { make $<quoted-variable-name>>>.made.join(', '); }
    method mixed-quoted-variable-names-list($/) { make $<mixed-quoted-variable-name>>>.made.join(', '); }

    # Column specs
    method column-specs-list($/) { make $<column-spec>>>.made.join(', '); }
    method column-spec($/) {  make $/.values[0].made; }
    method column-name-spec($/) { make '"' ~ $<mixed-quoted-variable-name>.made.subst(:g, '"', '') ~ '"'; }

    # Load data
    method data-load-command($/) { make $/.values[0].made; }
    method load-data-table($/) { make 'obj = ResourceFunction["ExampleDataset"][' ~ $<data-location-spec>.made ~ ']'; }
    method data-location-spec($/) {
        make $<regex-pattern-spec> ?? $<regex-pattern-spec>.made !! '\'' ~ $/.Str ~ '\'';
    }
    method use-data-table($/) { make 'obj = ' ~ $<variable-name>.made ; }

    # Distinct command
	method distinct-command($/) { make $/.values[0].made; }
	method distinct-simple-command($/) { make 'obj = DeleteDuplicates[obj]'; }

    # Missing treatment command
	method missing-treatment-command($/) { make $/.values[0].made; }
	method drop-incomplete-cases-command($/) { make 'obj = DeleteMissing[obj, 1, 2]'; }
	method replace-missing-command($/) { make 'obj = ReplaceAll[ obj, _Missing -> ' ~ $<replace-missing-rhs>.made ~ ' ]'; }
    method replace-missing-rhs($/) { make $/.values[0].made; }

    # Replace command
    method replace-command($/) { make 'obj = ReplaceAll[ obj, ' ~ $<lhs>.made ~ ' -> ' ~ $<rhs>.made ~ ' ]'; }

    # Select command
	method select-command($/) { make $/.values[0].made; }
    method select-columns-simple($/) {
      make 'obj = Map[ KeyTake[ #, {' ~ $/.values[0].made.join(', ') ~ '} ]&, obj]';
    }
    method select-columns-by-two-lists($/) {
        my @currentNames = $<current>.made.split(', ');
        my @newNames = $<new>.made.split(', ');

        if @currentNames.elems != @newNames.elems {
            note 'Same number of current and new column names are expected for column selection with renaming.';
            make 'obj';
        } else {
            my $pairs = do for @currentNames Z @newNames -> ($c, $n) { $n ~ ' -> #[' ~ $c ~ ']' };
            make 'obj = Map[ <|' ~ $pairs.join(', ') ~ '|>&, obj]' ;
        }
    }
    method select-columns-by-pairs($/) {
        my @pairs = $/.values[0].made;
		my $res = do for @pairs -> ( $lhs, $rhsName, $rhs ) { $lhs ~ ' -> ' ~ $rhs };
		make 'obj = Map[ <|' ~ $res.join(', ') ~ '|>&, obj]';
    }

    # Filter commands
    method filter-command($/) { make 'obj = Select[ obj, ' ~ $<filter-spec>.made ~ ' & ]'; }
    method filter-spec($/) { make $<predicates-list>.made; }

    # Mutate command
    method mutate-command($/) { make $/.values[0].made; }
    method mutate-by-two-lists($/) {
        my @currentNames = $<current>.made.split(', ');
        my @newNames = $<new>.made.split(', ');

        if @currentNames.elems != @newNames.elems {
            note 'Same number of current and new column names are expected for mutation with two lists.';
            make 'obj';
        } else {
            my $pairs = do for @currentNames Z @newNames -> ($c, $n) { $n ~ ' -> #[' ~ $c ~ ']' };
            make 'obj = Map[ Join[ #, <|' ~ $pairs.join(', ') ~ '|> ]&, obj]' ;
        }
    }
    method mutate-by-pairs($/) {
        my @pairs = $/.values[0].made;
		my $res = do for @pairs -> ( $lhs, $rhsName, $rhs ) { $lhs ~ ' -> ' ~ $rhs };
		make 'obj = Map[ Join[ #, <|' ~ $res.join(', ') ~ '|> ]&, obj]';
    }

    # Group command
    method group-command($/) { make $/.values[0].made; }
    method group-by-command($/) {
        my $obj = %.properties<IsGrouped>:exists ?? 'Join @@ obj' !! 'obj';
        %.properties<IsGrouped> = True;
        my @vars = map( { '#[' ~ $_ ~ ']' }, $/.values[0].made.split(', ') );
        my $vars = @vars.elems == 1 ?? @vars.join(', ') !! '{' ~ @vars.join(', ' ) ~ '}';
        make 'obj = GroupBy[ ' ~ $obj ~ ', ' ~ $vars ~ '& ]';
    }
    method group-map-command($/) { make 'obj = Map[ ' ~ $/.values[0].made ~ ', obj ]'; }

    # Ungroup command
    method ungroup-command($/) { make $/.values[0].made; }
    method ungroup-simple-command($/) {
        %.properties<IsGrouped>:delete;
        make 'obj = Join @@ Values[obj]';
    }

    # Arrange command
    method arrange-command($/) { make $/.values[0].made; }
    method arrange-simple-command($/) {
        make $<reverse-sort-phrase> || $<descending-phrase> ?? 'obj = ReverseSort[obj]' !! 'obj = Sort[obj]';
    }
    method arrange-by-spec($/) { make '{' ~ map( { '#["' ~ $_.subst(:g, '"', '') ~ '"]' }, $/.values[0].made.split(', ') ).join(', ') ~ '}'; }
    method arrange-by-command-ascending($/) {
        if %.properties<IsGrouped>:exists {
            make 'obj = SortBy[ #, ' ~ $<arrange-by-spec>.made ~ '& ]& /@ obj';
        } else {
            make 'obj = SortBy[ obj, ' ~ $<arrange-by-spec>.made ~ '& ]';
        }
    }
    method arrange-by-command-descending($/) {
        if %.properties<IsGrouped>:exists {
            make 'obj = ReverseSortBy[ #, ' ~ $<arrange-by-spec>.made ~ '& ]& /@ obj';
        } else {
            make 'obj = ReverseSortBy[ obj, ' ~ $<arrange-by-spec>.made ~ '& ]';
        }
    }

    # Rename columns command
    method rename-columns-command($/) { make $/.values[0].made; }
    method rename-columns-by-two-lists($/) {
        my @currentNames = $<current>.made.split(', ');
        my @newNames = $<new>.made.split(', ');

        if @currentNames.elems != @newNames.elems {
            note 'Same number of current and new column names are expected for column renaming.';
            make 'obj';
        } else {
            my $pairs = do for @currentNames Z @newNames -> ($c, $n) { $n ~ ' -> #[' ~ $c ~ ']' };
            my $current = @currentNames.join(', ');
            make 'obj = Map[ Join[ KeyDrop[ #, {' ~ $current ~ '} ], <| ' ~ $pairs.join(', ') ~ '|> ]&, obj]';
        }
    }
    method rename-columns-by-pairs($/) {
        my @pairs = $/.values[0].made;
		my $res = do for @pairs -> ( $lhs, $rhsName, $rhs ) { $lhs ~ ' -> ' ~ $rhs };
        my @toDrop = do for @pairs -> ( $lhs, $rhsName, $rhs ) { $rhsName };
		make  'obj = Map[ Join[ KeyDrop[ #, {' ~ @toDrop.join(', ')~ '} ], <|' ~ $res.join(', ') ~ '|> ]&, obj]';
    }

    # Drop columns command
    method drop-columns-command($/) { make $/.values[0].made; }
    method drop-columns-simple($/) {
        make 'obj = Map[ KeyDrop[ #, {' ~ $<todrop>.made ~ '} ]&, obj]';
    }

    # Statistics command
    method statistics-command($/) { make $/.values[0].made; }
    method data-dimensions-command($/) { make 'Echo[Dimensions[obj], "dimensions:"]'; }
    method count-command($/) {
        make %.properties<IsGrouped>:exists ?? 'obj = Map[ Length, obj]' !! 'obj = Length[obj]';
    }
    method echo-count-command($/) {
        make %.properties<IsGrouped>:exists ?? 'Echo[Map[ Length, obj], "counts:"]' !! 'Echo[Length[obj], "counts"]';
    }
    method data-summary-command($/) {
        make %.properties<IsGrouped>:exists ?? 'Echo[ResourceFunction["RecordsSummary"] /@ obj]' !! 'Echo[ResourceFunction["RecordsSummary"][obj], "summary:"]';
    }
    method glimpse-data($/) { make 'Echo[RandomSample[obj,UpTo[6]], "glimpse:"]'; }
    method summarize-all-command($/) {
        make %.properties<IsGrouped>:exists ?? 'Echo[Mean /@ obj, "summarize-all:"]' !! 'Echo[Mean[obj], "summarize-all:"]';
    }

    # Summarize command
    method summarize-command($/) { make $/.values[0].made; }
    method summarize-by-pairs($/) {
        my @pairs = $/.values[0].made;
		my $res = do for @pairs -> ( $lhs, $rhsName, $rhs ) { $lhs ~ ' -> ' ~ $rhs };
		make 'obj = Map[ <|' ~ $res.join(', ') ~ '|>&, obj]';
    }
	method summarize-at-command($/) {
		my $cols = '{' ~ map( { '"' ~ $_.subst(:g, '"', '') ~ '"' }, $<cols>.made.split(', ') ).join(', ') ~ '}';
        my $funcs = $<summarize-funcs-spec> ?? $<summarize-funcs-spec>.made !! '{Length, Min, Max, Mean, Median, Total}';
  
        if %.properties<IsGrouped>:exists {
            make 'obj = Dataset[obj][All, Association @ Flatten @ Outer[ToString[#1] <> "_" <> ToString[#2] -> Query[#2, #1] &,' ~ $cols ~ ', '  ~ $funcs ~ ']]';
        } else {
            make 'obj = Association @ Flatten @ Outer[ToString[#1] <> "_" <> ToString[#2] -> obj[Query[#2, #1]] &,' ~ $cols ~ ', '  ~ $funcs ~ ']';
        }
    }
	method summarize-funcs-spec($/) { make '{' ~ $<variable-name-or-wl-expr-list>.made.join(', ') ~ '}'; }

    # Join command
    method join-command($/) { make $/.values[0].made; }

    method join-by-spec($/) {
		if $<mixed-quoted-variable-names-list> {
			make '{' ~ map( { '"' ~ $_ ~ '"'}, $/.values[0].made.subst(:g, '"', '').split(', ') ).join(', ') ~ '}';
		} else {
			make $/.values[0].made;
		}
	}

    method full-join-spec($/)  {
        if $<join-by-spec> {
            make 'obj = JoinAcross[ obj, ' ~ $<dataset-name>.made ~ ', ' ~ $<join-by-spec>.made ~ ', "Outer"]';
        } else {
            make 'obj = JoinAcross[ obj, ' ~ $<dataset-name>.made ~ ', Intersection[Normal@Keys@obj[1], Normal@Keys@' ~ $<dataset-name>.made ~ '[1]], "Outer"]';
        }
    }

    method inner-join-spec($/)  {
        if $<join-by-spec> {
            make 'obj = JoinAcross[ obj, ' ~ $<dataset-name>.made ~ ', ' ~ $<join-by-spec>.made ~ ', "Inner"]';
        } else {
            make 'obj = JoinAcross[ obj, ' ~ $<dataset-name>.made ~ ', Intersection[Normal@Keys@obj[1], Normal@Keys@' ~ $<dataset-name>.made ~ '[1]], "Inner"]';
        }
    }

    method left-join-spec($/)  {
        if $<join-by-spec> {
            make 'obj = JoinAcross[ obj, ' ~ $<dataset-name>.made ~ ', ' ~ $<join-by-spec>.made ~ ', "Left"]';
        } else {
            make 'obj = JoinAcross[ obj, ' ~ $<dataset-name>.made ~ ', Intersection[Normal@Keys@obj[1], Normal@Keys@' ~ $<dataset-name>.made ~ '[1]], "Left"]';
        }
    }

    method right-join-spec($/)  {
        if $<join-by-spec> {
            make 'obj = JoinAcross[ obj, ' ~ $<dataset-name>.made ~ ', ' ~ $<join-by-spec>.made ~ ', "Right"]';
        } else {
            make 'obj = JoinAcross[ obj, ' ~ $<dataset-name>.made ~ ', Intersection[Normal@Keys@obj[1], Normal@Keys@' ~ $<dataset-name>.made ~ '[1]], "Right"]';
        }
    }

    method semi-join-spec($/)  {
        if $<join-by-spec> {
            make 'obj = JoinAcross[ obj, ' ~ $<dataset-name>.made ~ ', ' ~ $<join-by-spec>.made ~ ', "Right"][All, Normal@Keys@obj[1]]';
        } else {
            make 'obj = JoinAcross[ obj, ' ~ $<dataset-name>.made ~ ', Intersection[Normal@Keys@obj[1], Normal@Keys@' ~ $<dataset-name>.made ~ '[1]], "Right"][All, Normal@Keys@obj[1]]';
        }
    }

    # Cross tabulate command
    method cross-tabulation-command($/) { make $/.values[0].made; }
    method cross-tabulate-command($/) { $<cross-tabulation-formula>.made }
    method contingency-matrix-command($/) { $<cross-tabulation-formula>.made }
    method cross-tabulation-formula($/) { make $/.values[0].made; }
	method cross-tabulation-double-formula($/) {
        if $<values-variable-name> {
            #make 'obj = GroupBy[ obj, { #[' ~ $<rows-variable-name>.made ~ '], #[' ~ $<columns-variable-name>.made ~  '] }&, Total[ #[' ~ $<values-variable-name>.made ~ '] & /@ # ]& ]';
            make 'obj = ResourceFunction["CrossTabulate"][ { #[' ~ $<rows-variable-name>.made ~ '], #[' ~ $<columns-variable-name>.made ~  '], #[' ~ $<values-variable-name>.made ~ '] }& /@ obj ]';
        } else {
            #make 'obj = GroupBy[ obj, { #[' ~ $<rows-variable-name>.made ~ '], #[' ~ $<columns-variable-name>.made ~  '] }&, Length ]';
            make 'obj = ResourceFunction["CrossTabulate"][ { #[' ~ $<rows-variable-name>.made ~ '], #[' ~ $<columns-variable-name>.made ~  '] }& /@ obj ]';
        }
    }
    method cross-tabulation-single-formula($/) {
        if $<values-variable-name> {
            make 'obj = GroupBy[ obj, #[' ~ $<rows-variable-name>.made ~ ']&, Total[ #[' ~ $<values-variable-name>.made ~ '] & /@ # ]& ]';
        } else {
            make 'obj = GroupBy[ obj, #[' ~ $<rows-variable-name>.made ~ ']&, Length ]';
        }
    }
    method rows-variable-name($/) { make $/.values[0].made; }
    method columns-variable-name($/) { make $/.values[0].made; }
    method values-variable-name($/) { make $/.values[0].made; }

    # Reshape command
    method reshape-command($/) { make $/.values[0].made; }

    # Pivot longer command
    method pivot-longer-command($/) {
        if $<pivot-longer-arguments-list> {
            make 'obj = ToLongForm[ obj, ' ~ $<pivot-longer-arguments-list>.made ~ ' ]';
        } else {
            make 'obj = ToLongForm[ obj ]';
        }
    }
    method pivot-longer-arguments-list($/) { make $<pivot-longer-argument>>>.made.join(', '); }
    method pivot-longer-argument($/) { make $/.values[0].made; }

    method pivot-longer-id-columns-spec($/) { make '"IdentifierColumns" -> {' ~ $/.values[0].made ~ '}'; }

    method pivot-longer-columns-spec($/)    { make '"VariableColumns" -> {' ~ $/.values[0].made ~ '}'; }

    method pivot-longer-variable-column-name-spec($/) { make '"VariablesTo" -> ' ~ $/.values[0].made; }

    method pivot-longer-value-column-name-spec($/) { make '"ValuesTo" -> ' ~ $/.values[0].made; }

    # Pivot wider command
    method pivot-wider-command($/) { make 'obj = ToWideForm[ obj, ' ~ $<pivot-wider-arguments-list>.made ~ ' ]'; }
    method pivot-wider-arguments-list($/) { make $<pivot-wider-argument>>>.made.join(', '); }
    method pivot-wider-argument($/) { make $/.values[0].made; }

    method pivot-wider-id-columns-spec($/) { make ' "IdentifierColumns" -> {' ~ $/.values[0].made ~ '}'; }

    method pivot-wider-variable-column-spec($/) { make '"VariablesFrom" -> ' ~ $/.values[0].made; }

    method pivot-wider-value-column-spec($/) { make '"ValuesFrom" -> ' ~ $/.values[0].made; }

    # Separate string column command
	method separate-column-command($/) {
		my $intocols = map( { '"' ~ $_.subst(:g, '"', '') ~ '"' }, $<into>.made.split(', ') ).join(', ');
		if $<sep> {
			make 'obj = SeparateColumn[ obj, ' ~ $<col>.made ~ ', {' ~ $intocols ~ '}, "Separator" -> ' ~ $<sep>.made ~ ' ]';
		} else {
			make 'obj = SeparateColumn[ obj, ' ~ $<col>.made ~ ', {' ~ $intocols ~ '} ]';
		}
	}
    method separator-spec($/) { make $/.values[0].made; }

    # Make dictionary command
    method make-dictionary-command($/) { make 'obj = Association @ Normal @ Map[ #[' ~ $<keycol>.made ~'] -> #[' ~ $<valcol>.made ~ ']&, obj ]';}

    # Probably have to be in DSL::Shared::Actions .
    # Assign-pairs and as-pairs
	method assign-pairs-list($/) { make $<assign-pair>>>.made; }
	method as-pairs-list($/)     { make $<as-pair>>>.made; }
	method assign-pair($/) { make ( $<assign-pair-lhs>.made, |$<assign-pair-rhs>.made ); }
	method as-pair($/)     { make ( $<assign-pair-lhs>.made, |$<assign-pair-rhs>.made ); }
    method assign-pair-lhs($/) { make '"' ~ $/.values[0].made.subst(:g, '"', '') ~ '"'; }
    method assign-pair-rhs($/) {
        if $<mixed-quoted-variable-name> {
            my $v = '"' ~ $/.values[0].made.subst(:g, '"', '') ~ '"';
            make ( $v, '#[' ~ $v ~ ']' )
        } else {
            make ( $/.values[0].made, $/.values[0].made )
        }
    }

    # Correspondence pairs
    method key-pairs-list($/) { make $<key-pair>>>.made.join(', '); }
    method key-pair($/) { make $<key-pair-lhs>.made ~ ' -> ' ~ $<key-pair-rhs>.made; }
    method key-pair-lhs($/) { make '"' ~ $/.values[0].made.subst(:g, '"', '') ~ '"'; }
    method key-pair-rhs($/) { make '"' ~ $/.values[0].made.subst(:g, '"', '') ~ '"'; }

    # Pipeline command
    method pipeline-command($/) { make $/.values[0].made; }
    method take-pipeline-value($/) { make 'obj'; }
    method echo-pipeline-value($/) { make 'Echo[obj]'; }

    method echo-command($/) { make 'Echo[ ' ~ $<echo-message-spec>.made ~ ' ]'; }
    method echo-message-spec($/) { make $/.values[0].made; }
    method echo-words-list($/) { make '"' ~ $<variable-name>>>.made.join(' ') ~ '"'; }
    method echo-variable($/) { make $/.Str; }
    method echo-text($/) { make $/.Str; }

    ## Setup code
    method setup-code-command($/) {
        make 'SETUPCODE' => q:to/SETUPEND/
        Import["https://raw.githubusercontent.com/antononcube/MathematicaForPrediction/master/CrossTabulate.m"];
        Import["https://raw.githubusercontent.com/antononcube/MathematicaForPrediction/master/DataReshape.m"];
        SETUPEND
  }
}
