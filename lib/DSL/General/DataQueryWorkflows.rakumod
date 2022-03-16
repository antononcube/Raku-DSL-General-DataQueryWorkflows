=begin pod

=head1 DSL::General::DataQueryWorkflows

C<DSL::General::DataQueryWorkflows> package has grammar and action classes for the parsing
and interpretation of natural language commands that specify data queries in the style of
Standard Query Language (SQL) or RStudio's library tidyverse.

=head1 Synopsis

    use DSL::General::DataQueryWorkflows;
    my $rcode = ToDataQueryWorkflowCode("select height & mass; arrange by height descending");

=end pod

unit module DSL::General::DataQueryWorkflows;

use DSL::Shared::Utilities::MetaSpecsProcessing;
use DSL::Shared::Utilities::CommandProcessing;

use DSL::General::DataQueryWorkflows::Grammar;

use DSL::General::DataQueryWorkflows::Actions::Julia::DataFrames;
use DSL::General::DataQueryWorkflows::Actions::Python::pandas;
use DSL::General::DataQueryWorkflows::Actions::R::base;
use DSL::General::DataQueryWorkflows::Actions::R::tidyverse;
use DSL::General::DataQueryWorkflows::Actions::Raku::Reshapers;
use DSL::General::DataQueryWorkflows::Actions::SQL::Standard;
use DSL::General::DataQueryWorkflows::Actions::WL::System;

use DSL::General::DataQueryWorkflows::Actions::Bulgarian::Standard;
use DSL::General::DataQueryWorkflows::Actions::English::Standard;
use DSL::General::DataQueryWorkflows::Actions::Korean::Standard;
use DSL::General::DataQueryWorkflows::Actions::Russian::Standard;
use DSL::General::DataQueryWorkflows::Actions::Spanish::Standard;

#-----------------------------------------------------------

my %targetToAction{Str} =
    "Bulgarian"         => DSL::General::DataQueryWorkflows::Actions::Bulgarian::Standard,
    "English"           => DSL::General::DataQueryWorkflows::Actions::English::Standard,
    "Julia"             => DSL::General::DataQueryWorkflows::Actions::Julia::DataFrames,
    "Julia-DataFrames"  => DSL::General::DataQueryWorkflows::Actions::Julia::DataFrames,
    "Korean"            => DSL::General::DataQueryWorkflows::Actions::Korean::Standard,
    "Mathematica"       => DSL::General::DataQueryWorkflows::Actions::WL::System,
    "Python-pandas"     => DSL::General::DataQueryWorkflows::Actions::Python::pandas,
    "R"                 => DSL::General::DataQueryWorkflows::Actions::R::base,
    "R-base"            => DSL::General::DataQueryWorkflows::Actions::R::base,
    "R-tidyverse"       => DSL::General::DataQueryWorkflows::Actions::R::tidyverse,
    "Raku"              => DSL::General::DataQueryWorkflows::Actions::Raku::Reshapers,
    "Raku-Reshapers"    => DSL::General::DataQueryWorkflows::Actions::Raku::Reshapers,
    "Russian"           => DSL::General::DataQueryWorkflows::Actions::Russian::Standard,
    "SQL"               => DSL::General::DataQueryWorkflows::Actions::SQL::Standard,
    "Spanish"           => DSL::General::DataQueryWorkflows::Actions::Spanish::Standard,
    "WL"                => DSL::General::DataQueryWorkflows::Actions::WL::System,
    "WL-System"         => DSL::General::DataQueryWorkflows::Actions::WL::System,
    "pandas"            => DSL::General::DataQueryWorkflows::Actions::Python::pandas,
    "tidyverse"         => DSL::General::DataQueryWorkflows::Actions::R::tidyverse;

my %targetToAction2{Str} = %targetToAction.grep({ $_.key.contains('-') }).map({ $_.key.subst('-', '::') => $_.value }).Hash;
%targetToAction = |%targetToAction , |%targetToAction2;


my Str %targetToSeparator{Str} =
    "Bulgarian"         => "\n",
    "English"           => "\n",
    "Julia"             => "\n",
    "Julia-DataFrames"  => "\n",
    "Korean"            => "\n",
    "Mathematica"       => "\n",
    "Python-pandas"     => "\n",
    "R"                 => " ;\n",
    "R-base"            => " ;\n",
    "R-tidyverse"       => " %>%\n",
    "Raku"              => " ;\n",
    "Raku-Reshapers"    => " ;\n",
    "Russian"           => "\n",
    "SQL"               => ";\n",
    "Spanish"           => "\n",
    "WL"                => ";\n",
    "WL-System"         => ";\n",
    "pandas"            => ".\n",
    "tidyverse"         => " %>%\n";

my Str %targetToSeparator2{Str} = %targetToSeparator.grep({ $_.key.contains('-') }).map({ $_.key.subst('-', '::') => $_.value }).Hash;
%targetToSeparator = |%targetToSeparator , |%targetToSeparator2;


#-----------------------------------------------------------
proto ToDataQueryWorkflowCode(Str $command, Str $target = 'tidyverse', | ) is export {*}

multi ToDataQueryWorkflowCode( Str $command, Str $target = 'tidyverse', *%args ) {

    my $lang = %args<lang>:exists ?? %args<lang> !! 'General';

    my Grammar $grammar = ::("DSL::{$lang}::DataQueryWorkflows::Grammar");

    %args = %args.pairs.grep({ $_.key ne 'lang' }).Hash;

    DSL::Shared::Utilities::CommandProcessing::ToWorkflowCode( $command,
                                                               :$grammar,
                                                               :%targetToAction,
                                                               :%targetToSeparator,
                                                               :$target,
                                                               |%args )
}
