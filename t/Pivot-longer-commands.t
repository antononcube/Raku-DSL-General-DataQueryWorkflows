use v6;
use lib 'lib';
use DSL::General::DataQueryWorkflows::Grammar;
use Test;

plan 10;

# Shortcut
my $pCOMMAND = DSL::General::DataQueryWorkflows::Grammar;

#-----------------------------------------------------------
# Pivot longer commands
#-----------------------------------------------------------

ok $pCOMMAND.parse('convert to narrow form'),
        'convert to narrow form';

ok $pCOMMAND.parse('convert to long format'),
        'convert to long format';

ok $pCOMMAND.parse('to longer form'),
        'to longer form';

ok $pCOMMAND.parse('to long form'),
        'to long form';

ok $pCOMMAND.parse('pivot to long form'),
        'pivot to long form';

ok $pCOMMAND.parse('pivot to long form with variable columns V1 and V2'),
        'pivot to long form with variable columns V1 and V2';

ok $pCOMMAND.parse('pivot to long form with columns V1, V2, and VAR5'),
        'pivot to long form with columns V1, V2, and VAR5';

ok $pCOMMAND.parse('pivot to long form with id columns ID1, ID2 with variable columns V1 and V2'),
        'pivot to long form with id columns ID1, ID2 with variable columns V1 and V2';

ok $pCOMMAND.parse('convert to long form using the id columns ID1, ID2 and with variable columns V1 and V2'),
        'convert to long form using the id columns ID1, ID2 and with variable columns V1 and V2';

# This is parsed but the result is not correct: the identifier columns list is {"ID1", "ID2", "variable"}.
ok $pCOMMAND.parse('pivot to long form with id columns ID1, ID2 and variable columns V1 and V2'),
        'pivot to long form with id columns ID1, ID2 and variable columns V1 and V2';


done-testing;